CREATE OR REPLACE PACKAGE BODY ALC_SQL AS
---------------------------------------------------------------------------------------------
FUNCTION CALC_PERCENT_VARIANCE(O_error_message      IN OUT   VARCHAR2,
                               O_percent_variance   IN OUT   ALC_HEAD.ALC_QTY%TYPE,
                               I_base_value         IN       ALC_COMP_LOC.ACT_VALUE%TYPE,
                               I_compare_value      IN       ALC_COMP_LOC.ACT_VALUE%TYPE)
   return BOOLEAN is
      L_program   VARCHAR2(64)   := 'ALC_SQL.CALC_PERCENT_VARIANCE';
BEGIN
   if I_base_value is NULL or I_compare_value is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_base_value = 0 then
      if I_compare_value = 0 then
         O_percent_variance := 0;
         return TRUE;
      else
         O_percent_variance := 100;
         return TRUE;
      end if;
   end if;

   O_percent_variance := ABS(100*((I_base_value - I_compare_value)/I_base_value));
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END CALC_PERCENT_VARIANCE;
---------------------------------------------------------------------------------------------
FUNCTION LOC_EXISTS  (O_error_message   IN OUT   VARCHAR2,
                      O_exists          IN OUT   BOOLEAN,
                      I_order_no        IN       ORDHEAD.ORDER_NO%TYPE,
                      I_seq_no          IN       ALC_HEAD.SEQ_NO%TYPE,
                      I_comp_id         IN       ELC_COMP.COMP_ID%TYPE,
                      I_location        IN       ALC_COMP_LOC.LOCATION%TYPE)

   RETURN BOOLEAN IS

      L_exists    VARCHAR(1)     := NULL;
      L_program   VARCHAR2(64)   := 'ALC_SQL.LOC_EXISTS';

      cursor C_LOC_EXISTS is
         select 'X'
           from alc_comp_loc
          where order_no = I_order_no
            and seq_no   = I_seq_no
            and comp_id  = I_comp_id
            and location = I_location;

      cursor C_ANY_LOCS_EXIST is
         select 'X'
           from alc_comp_loc
          where order_no = I_order_no
            and seq_no   = I_seq_no
            and comp_id  = I_comp_id;
BEGIN
--- I_order_no, I_seq_no, I_comp_id must be passed into this function.
--- If checking for existence of any locations then I_loc_type and I_location
--- must be NULL.  If checking for the existence of a specific location then
--- I_loc_type and I_location must be not NULL.

   O_exists := FALSE;
   ---
   if I_location is not NULL then
      SQL_LIB.SET_MARK('OPEN','C_LOC_EXISTS','ALC_COMP_LOC, ALC_HEAD',NULL);
      open C_LOC_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_LOC_EXISTS','ALC_COMP_LOC, ALC_HEAD',NULL);
      fetch C_LOC_EXISTS into L_exists;
      ---
      if C_LOC_EXISTS%FOUND then
         O_exists := TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_LOC_EXISTS','ALC_COMP_LOC, ALC_HEAD',NULL);
      close C_LOC_EXISTS;
   else
      SQL_LIB.SET_MARK('OPEN','C_ANY_LOCS_EXIST','ALC_COMP_LOC, ALC_HEAD',NULL);
      open C_ANY_LOCS_EXIST;
      SQL_LIB.SET_MARK('FETCH','C_ANY_LOCS_EXIST','ALC_COMP_LOC, ALC_HEAD',NULL);
      fetch C_ANY_LOCS_EXIST into L_exists;
      ---
      if C_ANY_LOCS_EXIST%FOUND then
         O_exists := TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_ANY_LOCS_EXIST','ALC_COMP_LOC, ALC_HEAD',NULL);
      close C_ANY_LOCS_EXIST;
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
END LOC_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION GET_LOC_TOTALS(O_error_message              IN OUT   VARCHAR2,
                        O_unit_est_loc_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                        O_unit_act_loc_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                        O_percent_variance           IN OUT   NUMBER,
                        I_order_no                   IN       ALC_COMP_LOC.ORDER_NO%TYPE,
                        I_item                       IN       ITEM_MASTER.ITEM%TYPE,
                        I_pack_item                  IN       ITEM_MASTER.ITEM%TYPE,
                        I_seq_no                     IN       ALC_HEAD.SEQ_NO%TYPE,
                        I_comp_id                    IN       ALC_COMP_LOC.COMP_ID%TYPE,
                        I_location                   IN       ALC_COMP_LOC.LOCATION%TYPE)
   return BOOLEAN is
      L_program                   VARCHAR2(30)                       := 'ALC_SQL.GET_LOC_TOTALS';
      L_nom_flag_4                ORDLOC_EXP.NOM_FLAG_4%TYPE;
      L_nom_flag_2                ORDLOC_EXP.NOM_FLAG_2%TYPE;
      L_unit_est_exp_loc_value    ORDLOC_EXP.EST_EXP_VALUE%TYPE      := 0;
      L_unit_est_assess_loc_value ORDLOC_EXP.EST_EXP_VALUE%TYPE      := 0;
      L_comp_type                 ELC_COMP.COMP_TYPE%TYPE;
      L_expense_comp_currency     CURRENCIES.CURRENCY_CODE%TYPE;
      L_assess_comp_currency      CURRENCIES.CURRENCY_CODE%TYPE;
      L_exchange_rate             CURRENCY_RATES.EXCHANGE_RATE%TYPE  := 0;
      L_import_country_id         ORDHEAD.IMPORT_COUNTRY_ID%TYPE;

      cursor C_COMP_TYPE is
         select comp_type
           from elc_comp
          where comp_id = I_comp_id;

      cursor C_GET_UNIT_EST is
         select est_exp_value,
                comp_currency,
                exchange_rate,
                nom_flag_4
           from ordloc_exp
          where order_no   = I_order_no
            and item       = I_item
            and (pack_item = I_pack_item
                 or (pack_item is NULL and I_pack_item is NULL))
            and location   = I_location
            and comp_id    = I_comp_id;

      cursor C_SUM_ASSESS is
         select a.est_assess_value,
                a.nom_flag_2,
                e.comp_currency
           from ordsku_hts_assess a,
                ordsku_hts        h,
                elc_comp          e
          where e.comp_id           = a.comp_id
            and h.order_no          = a.order_no
            and h.order_no          = I_order_no
            and h.seq_no            = a.seq_no
            and h.item              = I_item
            and (h.pack_item = I_pack_item
                 or (h.pack_item is NULL and I_pack_item is NULL))
            and h.import_country_id = L_import_country_id
            and a.comp_id           = I_comp_id;

      cursor C_GET_UNIT_ACT is
         select act_value
           from alc_comp_loc l
          where order_no = I_order_no
            and seq_no   = I_seq_no
            and comp_id  = I_comp_id
            and location = I_location;

BEGIN
   ---
   -- I_order_no, I_item, I_seq_no, I_comp_id, and I_location must be passed into this function.
   ---
   if I_order_no        is NULL or
      I_item            is NULL or
      I_seq_no          is NULL or
      I_comp_id         is NULL or
      I_location        is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;
   --Retrieve component type to determine if assessment or expense componenet.
   SQL_LIB.SET_MARK('OPEN','C_COMP_TYPE','ELC_COMP', 'Component: '||I_comp_id);
   open C_COMP_TYPE;
   SQL_LIB.SET_MARK('FETCH','C_COMP_TYPE','ELC_COMP', 'Component: '||I_comp_id);
   fetch C_COMP_TYPE into L_comp_type;
   SQL_LIB.SET_MARK('CLOSE','C_COMP_TYPE','ELC_COMP', 'Component: '||I_comp_id);
   close C_COMP_TYPE;
   ---
   if L_comp_type = 'E' then   /*Expenses - Get estimated expense value off of ordloc_exp table*/
      SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_EST','ORDLOC_EXP', NULL);
      open C_GET_UNIT_EST;
      SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_EST','ORDLOC_EXP', NULL);
      fetch C_GET_UNIT_EST into L_unit_est_exp_loc_value,
                                L_expense_comp_currency,
                                L_exchange_rate,
                                L_nom_flag_4;
      if C_GET_UNIT_EST%NOTFOUND then
         O_unit_est_loc_value_prim := 0;
      else
         --Assign value to estimated expense based on nom flag value
         if L_nom_flag_4 = '+' then
            O_unit_est_loc_value_prim := L_unit_est_exp_loc_value;
         elsif L_nom_flag_4 = '-' then
            O_unit_est_loc_value_prim := (0 - L_unit_est_exp_loc_value);
         elsif L_nom_flag_4 = 'N' then
            O_unit_est_loc_value_prim := 0;
         end if;

         --Convert to primary currency
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 O_unit_est_loc_value_prim,
                                 L_expense_comp_currency,
                                 NULL,
                                 O_unit_est_loc_value_prim,
                                 'N',
                                 NULL,
                                 NULL,
                                 L_exchange_rate,
                                 NULL) = FALSE then
            return FALSE;
         end if;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_EST','ORDLOC_EXP', NULL);
      close C_GET_UNIT_EST;
   else  /*Assessment - retrieve assessment off of order_hts_assess table*/
      if ORDER_ATTRIB_SQL.GET_IMPORT_COUNTRY(O_error_message,
                                             L_import_country_id,
                                             I_order_no) = FALSE then
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS','ORDSKU_HTS, ORDSKU_HTS_ASSESS',
                       'Order_no:'||to_char(I_order_no)||' Item:'||I_item);
      open C_SUM_ASSESS;
      SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS','ORDSKU_HTS, ORDSKU_HTS_ASSESS',
                       'Order_no:'||to_char(I_order_no)||' Item:'||I_item);
      fetch C_SUM_ASSESS into L_unit_est_assess_loc_value,
                              L_nom_flag_2,
                              L_assess_comp_currency;
      if C_SUM_ASSESS%NOTFOUND then
         O_unit_est_loc_value_prim := 0;
      else
         --Assign value to estimated assessment based on nom flag value.
         if L_nom_flag_2 = '+' then
            O_unit_est_loc_value_prim := L_unit_est_assess_loc_value;
         elsif L_nom_flag_2 = '-' then
            O_unit_est_loc_value_prim := (0 - L_unit_est_assess_loc_value);
         elsif L_nom_flag_2 = 'N' then
            O_unit_est_loc_value_prim := 0;
         end if;

         --Convert to primary currency
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 O_unit_est_loc_value_prim,
                                 L_assess_comp_currency,
                                 NULL,
                                 O_unit_est_loc_value_prim,
                                 'N',
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL) = FALSE then
             return FALSE;
         end if;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS','ORDSKU_HTS, ORDSKU_HTS_ASSESS',
                       'Order_no:'||to_char(I_order_no)||' Item:'||I_item);
      close C_SUM_ASSESS;
   end if;


    --Get actual expense value off of alc_comp_loc.
   SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_ACT','ALC_COMP_LOC', NULL);
   open C_GET_UNIT_ACT;
   SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_ACT','ALC_COMP_LOC', NULL);
   fetch C_GET_UNIT_ACT into O_unit_act_loc_value_prim;
   SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_ACT','ALC_COMP_LOC', NULL);
   close C_GET_UNIT_ACT;

   --Get percent variance.
   if ALC_SQL.CALC_PERCENT_VARIANCE(O_error_message,
                                    O_percent_variance,
                                    O_unit_act_loc_value_prim,
                                    O_unit_est_loc_value_prim) = FALSE then
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
END GET_LOC_TOTALS;
---------------------------------------------------------------------------------------------
FUNCTION GET_SHIP_LOC_TOTALS(O_error_message              IN OUT   VARCHAR2,
                             O_unit_est_loc_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                             O_unit_act_loc_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                             O_percent_variance           IN OUT   NUMBER,
                             I_order_no                   IN       ALC_COMP_LOC.ORDER_NO%TYPE,
                             I_item                       IN       ITEM_MASTER.ITEM%TYPE,
                             I_pack_item                  IN       ITEM_MASTER.ITEM%TYPE,
                             I_vessel_id                  IN       TRANSPORTATION.VESSEL_ID%TYPE,
                             I_voyage_flt_id              IN       TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                             I_estimated_depart_date      IN       TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                             I_comp_id                    IN       ALC_COMP_LOC.COMP_ID%TYPE,
                             I_location                   IN       ALC_COMP_LOC.LOCATION%TYPE)
   return BOOLEAN is
      L_program                   VARCHAR2(30)                       := 'ALC_SQL.GET_SHIP_LOC_TOTALS';
      L_nom_flag_4                ORDLOC_EXP.NOM_FLAG_4%TYPE;
      L_nom_flag_2                ORDLOC_EXP.NOM_FLAG_2%TYPE;
      L_unit_est_exp_loc_value    ORDLOC_EXP.EST_EXP_VALUE%TYPE      := 0;
      L_unit_est_assess_loc_value ORDLOC_EXP.EST_EXP_VALUE%TYPE      := 0;
      L_comp_type                 ELC_COMP.COMP_TYPE%TYPE;
      L_expense_comp_currency     CURRENCIES.CURRENCY_CODE%TYPE;
      L_assess_comp_currency      CURRENCIES.CURRENCY_CODE%TYPE;
      L_exchange_rate             CURRENCY_RATES.EXCHANGE_RATE%TYPE  := 0;
      L_import_country_id         ORDHEAD.IMPORT_COUNTRY_ID%TYPE;

      cursor C_COMP_TYPE is
         select comp_type
           from elc_comp
          where comp_id = I_comp_id;

      cursor C_GET_UNIT_EST is
         select est_exp_value,
                comp_currency,
                exchange_rate,
                nom_flag_4
           from ordloc_exp
          where order_no = I_order_no
            and item     = I_item
            and (pack_item = I_pack_item
                 or (pack_item is NULL and I_pack_item is NULL))
            and location = I_location
            and comp_id  = I_comp_id;

      cursor C_SUM_ASSESS is
         select a.est_assess_value,
                a.nom_flag_2,
                e.comp_currency
           from ordsku_hts_assess a,
                ordsku_hts        h,
                elc_comp          e
          where e.comp_id           = a.comp_id
            and h.order_no          = a.order_no
            and h.order_no          = I_order_no
            and h.seq_no            = a.seq_no
            and h.item              = I_item
            and (h.pack_item = I_pack_item
                 or (h.pack_item is NULL and I_pack_item is NULL))
            and h.import_country_id = L_import_country_id
            and a.comp_id           = I_comp_id;

      cursor C_GET_UNIT_ACT is
         select act_value
           from v_alc_ship_comp_loc
          where order_no              = I_order_no
            and item                  = I_item
            and (pack_item = I_pack_item or (pack_item is NULL and I_pack_item is NULL))
            and vessel_id             = I_vessel_id
            and voyage_flt_id         = I_voyage_flt_id
            and estimated_depart_date = I_estimated_depart_date
            and comp_id               = I_comp_id
            and location              = I_location;

BEGIN
   --I_order_no, I_item, I_vessel_id, I_voyage_flt_id, I_estimated_depart_date,
   --I_comp_id, and I_location must be passed into this function.
   --I_order_no, I_item, I_seq_no, I_qty must be passed into this function.
   if I_order_no              is NULL or
      I_item                  is NULL or
      I_vessel_id             is NULL or
      I_voyage_flt_id         is NULL or
      I_estimated_depart_date is NULL or
      I_comp_id               is NULL or
      I_location              is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;

   --Retrieve component type to determine if assessment or expense componenet.
   SQL_LIB.SET_MARK('OPEN','C_COMP_TYPE','ELC_COMP', 'Component: '||I_comp_id);
   open C_COMP_TYPE;
   SQL_LIB.SET_MARK('FETCH','C_COMP_TYPE','ELC_COMP', 'Component: '||I_comp_id);
   fetch C_COMP_TYPE into L_comp_type;
   SQL_LIB.SET_MARK('CLOSE','C_COMP_TYPE','ELC_COMP', 'Component: '||I_comp_id);
   close C_COMP_TYPE;
   ---
   if L_comp_type = 'E' then   /*Expenses - Get estimated expense value off of ordloc_exp table*/
      SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_EST','ORDLOC_EXP', NULL);
      open C_GET_UNIT_EST;
      SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_EST','ORDLOC_EXP', NULL);
      fetch C_GET_UNIT_EST into L_unit_est_exp_loc_value,
                                L_expense_comp_currency,
                                L_exchange_rate,
                                L_nom_flag_4;
      if C_GET_UNIT_EST%NOTFOUND then
         O_unit_est_loc_value_prim := 0;
      else
         --Assign value to estimated expense based on nom flag value
         if L_nom_flag_4 = '+' then
            O_unit_est_loc_value_prim := L_unit_est_exp_loc_value;
         elsif L_nom_flag_4 = '-' then
            O_unit_est_loc_value_prim := (0 - L_unit_est_exp_loc_value);
         elsif L_nom_flag_4 = 'N' then
            O_unit_est_loc_value_prim := 0;
         end if;

         --Convert to primary currency
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 O_unit_est_loc_value_prim,
                                 L_expense_comp_currency,
                                 NULL,
                                 O_unit_est_loc_value_prim,
                                 'N',
                                 NULL,
                                 NULL,
                                 L_exchange_rate,
                                 NULL) = FALSE then
            return FALSE;
         end if;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_EST','ORDLOC_EXP', NULL);
      close C_GET_UNIT_EST;
   else  /*Assessment - retrieve assessment off of order_hts_assess table*/
      if ORDER_ATTRIB_SQL.GET_IMPORT_COUNTRY(O_error_message,
                                             L_import_country_id,
                                             I_order_no) = FALSE then
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS','ORDSKU_HTS, ORDSKU_HTS_ASSESS',
                       'Order_no:'||to_char(I_order_no)||' Item:'||I_item);
      open C_SUM_ASSESS;
      SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS','ORDSKU_HTS, ORDSKU_HTS_ASSESS',
                       'Order_no:'||to_char(I_order_no)||' Item:'||I_item);
      fetch C_SUM_ASSESS into L_unit_est_assess_loc_value,
                              L_nom_flag_2,
                              L_assess_comp_currency;
      if C_SUM_ASSESS%NOTFOUND then
         O_unit_est_loc_value_prim := 0;
      else
         --Assign value to estimated assessment based on nom flag value.
         if L_nom_flag_2 = '+' then
            O_unit_est_loc_value_prim := L_unit_est_assess_loc_value;
         elsif L_nom_flag_2 = '-' then
            O_unit_est_loc_value_prim := (0 - L_unit_est_assess_loc_value);
         elsif L_nom_flag_2 = 'N' then
            O_unit_est_loc_value_prim := 0;
         end if;

         --Convert to primary currency
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 O_unit_est_loc_value_prim,
                                 L_assess_comp_currency,
                                 NULL,
                                 O_unit_est_loc_value_prim,
                                 'N',
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL) = FALSE then
             return FALSE;
         end if;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS','ORDSKU_HTS, ORDSKU_HTS_ASSESS',
                       'Order_no:'||to_char(I_order_no)||' Item:'||I_item);
      close C_SUM_ASSESS;
   end if;

    --Get actual expense value off of alc_comp_loc.
   SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_ACT','V_ALC_SHIP_COMP_LOC', NULL);
   open C_GET_UNIT_ACT;
   SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_ACT','V_ALC_SHIP_COMP_LOC', NULL);
   fetch C_GET_UNIT_ACT into O_unit_act_loc_value_prim;
   SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_ACT','V_ALC_SHIP_COMP_LOC', NULL);
   close C_GET_UNIT_ACT;


   --Get percent variance.
   if ALC_SQL.CALC_PERCENT_VARIANCE(O_error_message,
                                    O_percent_variance,
                                    O_unit_act_loc_value_prim,
                                    O_unit_est_loc_value_prim) = FALSE then
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
END GET_SHIP_LOC_TOTALS;
---------------------------------------------------------------------------------------------
FUNCTION GET_COMP_TOTALS(O_error_message              IN OUT   VARCHAR2,
                         O_unit_est_comp_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                         O_unit_act_comp_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                         O_percent_variance           IN OUT   NUMBER,
                         I_order_no                   IN       ALC_COMP_LOC.ORDER_NO%TYPE,
                         I_item                       IN       ITEM_MASTER.ITEM%TYPE,
                         I_pack_item                  IN       ITEM_MASTER.ITEM%TYPE,
                         I_seq_no                     IN       ALC_HEAD.SEQ_NO%TYPE,
                         I_comp_id                    IN       ALC_COMP_LOC.COMP_ID%TYPE)

   return BOOLEAN is
      L_program                   VARCHAR2(64)   := 'ALC_SQL.GET_COMP_TOTALS';
      L_unit_est_comp_value_prim  ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_unit_act_comp_value_prim  ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_unit_est_loc_value_prim   ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_unit_act_loc_value_prim   ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_percent_variance          NUMBER(20)                  := 0;
      L_location                  ALC_COMP_LOC.LOCATION%TYPE  := 0;
      L_total_est                 ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_total_act                 ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_count                     NUMBER(2)                   := 0;

      cursor C_GET_LOCS is
         select location
           from alc_comp_loc
          where order_no = I_order_no
            and seq_no   = I_seq_no
            and comp_id  = I_comp_id;

      cursor C_GET_ACT_VALUE is
         select act_value
           from v_alc_comp
          where order_no = I_order_no
            and seq_no   = I_seq_no
            and comp_id  = I_comp_id;
BEGIN

   --I_order_no, I_item, I_seq_no, I_comp_id  must be passed into this function.
   if I_order_no       is NULL or
      I_item           is NULL or
      I_seq_no         is NULL or
      I_comp_id        is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;

   --Get straight average of estimated values for all locations for passed-in component
   FOR C_rec in C_GET_LOCS LOOP
      L_location := C_rec.location;
      if ALC_SQL.GET_LOC_TOTALS(O_error_message,
                                L_unit_est_loc_value_prim,
                                L_unit_act_loc_value_prim,
                                L_percent_variance,
                                I_order_no,
                                I_item,
                                I_pack_item,
                                I_seq_no,
                                I_comp_id,
                                L_location) = FALSE then
         return FALSE;
      end if;
      L_total_est :=  L_total_est + L_unit_est_loc_value_prim;
      L_count     :=  L_count + 1;
   END LOOP;
   ---
   if L_count <> 0 then
      O_unit_est_comp_value_prim := L_total_est / L_count;
   else
      O_unit_est_comp_value_prim := 0;
   end if;
   ---

   --Get actual value off of V_ALC_COMP to calculate variance.
   SQL_LIB.SET_MARK('OPEN','C_GET_ACT_VALUE','V_ALC_COMP',NULL);
   open C_GET_ACT_VALUE;
   SQL_LIB.SET_MARK('FETCH','C_GET_ACT_VALUE','V_ALC_COMP',NULL);
   fetch C_GET_ACT_VALUE into O_unit_act_comp_value_prim;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ACT_VALUE','V_ALC_COMP',NULL);
   close C_GET_ACT_VALUE;

   --Calculate variance
   if ALC_SQL.CALC_PERCENT_VARIANCE(O_error_message,
                                    O_percent_variance,
                                    O_unit_act_comp_value_prim,
                                    O_unit_est_comp_value_prim) = FALSE then
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
END GET_COMP_TOTALS;
---------------------------------------------------------------------------------------------
FUNCTION GET_SHIP_COMP_TOTALS(O_error_message              IN OUT   VARCHAR2,
                              O_unit_est_comp_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                              O_unit_act_comp_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                              O_percent_variance           IN OUT   NUMBER,
                              I_order_no                   IN       ALC_COMP_LOC.ORDER_NO%TYPE,
                              I_item                       IN       ITEM_MASTER.ITEM%TYPE,
                              I_pack_item                  IN       ITEM_MASTER.ITEM%TYPE,
                              I_vessel_id                  IN       TRANSPORTATION.VESSEL_ID%TYPE,
                              I_voyage_flt_id              IN       TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                              I_estimated_depart_date      IN       TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                              I_comp_id                    IN       ALC_COMP_LOC.COMP_ID%TYPE)

   return BOOLEAN is
      L_program                   VARCHAR2(64)   := 'ALC_SQL.GET_SHIP_COMP_TOTALS';
      L_unit_est_comp_value_prim  ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_unit_act_comp_value_prim  ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_unit_est_loc_value_prim   ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_unit_act_loc_value_prim   ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_percent_variance          NUMBER(20)                  := 0;
      L_location                  ALC_COMP_LOC.LOCATION%TYPE  := 0;
      L_total_est                 ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_total_act                 ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_count                     NUMBER(2)                   := 0;

      cursor C_GET_LOCS is
         select location
           from v_alc_ship_comp_loc
          where order_no            = I_order_no
            and item                = I_item
            and (pack_item = I_pack_item or (pack_item is NULL and I_pack_item is NULL))
            and vessel_id             = I_vessel_id
            and voyage_flt_id         = I_voyage_flt_id
            and estimated_depart_date = I_estimated_depart_date
            and comp_id               = I_comp_id;

      cursor C_GET_ACT_VALUE is
         select act_value
           from v_alc_ship_comp
          where order_no              = I_order_no
            and item                  = I_item
            and (pack_item = I_pack_item or (pack_item is NULL and I_pack_item is NULL))
            and vessel_id             = I_vessel_id
            and voyage_flt_id         = I_voyage_flt_id
            and estimated_depart_date = I_estimated_depart_date
            and comp_id               = I_comp_id;
BEGIN

   --I_order_no, I_item, I_vessel_id, I_voyage_flt_id, I_estimated_depart_date, I_comp_id
   --must be passed into this function.
   if I_order_no              is NULL or
      I_item                  is NULL or
      I_vessel_id             is NULL or
      I_voyage_flt_id         is NULL or
      I_estimated_depart_date is NULL or
      I_comp_id               is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;

   --Get straight average of estimated values for all locations for passed-in component
   FOR C_rec in C_GET_LOCS LOOP
      L_location := C_rec.location;
      if ALC_SQL.GET_SHIP_LOC_TOTALS(O_error_message,
                                     L_unit_est_loc_value_prim,
                                     L_unit_act_loc_value_prim,
                                     L_percent_variance,
                                     I_order_no,
                                     I_item,
                                     I_pack_item,
                                     I_vessel_id,
                                     I_voyage_flt_id,
                                     I_estimated_depart_date,
                                     I_comp_id,
                                     L_location) = FALSE then
         return FALSE;
      end if;
      L_total_est :=  L_total_est + L_unit_est_loc_value_prim;
      L_count     :=  L_count + 1;
   END LOOP;
   ---
   if L_count <> 0 then
      O_unit_est_comp_value_prim := L_total_est / L_count;
   else
      O_unit_est_comp_value_prim := 0;
   end if;
   ---

   --Get actual value off of V_ALC_SHIP_COMP to calculate variance.
   SQL_LIB.SET_MARK('OPEN','C_GET_ACT_VALUE','V_ALC_SHIP_COMP',NULL);
   open C_GET_ACT_VALUE;
   SQL_LIB.SET_MARK('FETCH','C_GET_ACT_VALUE','V_ALC_SHIP_COMP',NULL);
   fetch C_GET_ACT_VALUE into O_unit_act_comp_value_prim;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ACT_VALUE','V_ALC_SHIP_COMP',NULL);
   close C_GET_ACT_VALUE;

   --Calculate variance
   if ALC_SQL.CALC_PERCENT_VARIANCE(O_error_message,
                                    O_percent_variance,
                                    O_unit_act_comp_value_prim,
                                    O_unit_est_comp_value_prim) = FALSE then
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
END GET_SHIP_COMP_TOTALS;
---------------------------------------------------------------------------------------------
FUNCTION GET_OBLIGATION_TOTALS(O_error_message              IN OUT   VARCHAR2,
                               O_unit_est_obl_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                               O_unit_act_obl_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                               O_total_est_obl_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                               O_total_act_obl_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                               O_percent_variance           IN OUT   NUMBER,
                               I_order_no                   IN       ALC_COMP_LOC.ORDER_NO%TYPE,
                               I_item                       IN       ITEM_MASTER.ITEM%TYPE,
                               I_pack_item                  IN       ITEM_MASTER.ITEM%TYPE,
                               I_seq_no                     IN       ALC_HEAD.SEQ_NO%TYPE,
                               I_qty                        IN       ALC_HEAD.ALC_QTY%TYPE)
   return BOOLEAN is
      L_program                   VARCHAR2(64)                := 'ALC_SQL.GET_OBLIGATION_TOTALS';
      L_unit_est_comp_value_prim  ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_unit_act_comp_value_prim  ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_total_est                 ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_total_act                 ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
      L_percent_variance          NUMBER;
      L_comp_id                   ALC_COMP_LOC.COMP_ID%TYPE;

   cursor C_GET_COMP is
      select comp_id
        from v_alc_comp v, alc_head h
       where v.seq_no    = h.seq_no
         and v.order_no  = h.order_no
         and h.order_no  = I_order_no
         and h.item      = I_item
         and ((h.pack_item is NULL and I_pack_item is NULL)
               or (h.pack_item = I_pack_item and I_pack_item is not NULL))
         and v.seq_no   = I_seq_no;

BEGIN
   --I_order_no, I_item, I_seq_no, I_qty must be passed into this function.
   if I_order_no is NULL or
      I_item     is NULL or
      I_seq_no   is NULL or
      I_qty      is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;

   --Loop through components for obligation and sum component values.
   FOR C_rec in C_GET_COMP LOOP
      L_comp_id := C_rec.comp_id;
      if ALC_SQL.GET_COMP_TOTALS(O_error_message,
                                 L_unit_est_comp_value_prim,
                                 L_unit_act_comp_value_prim,
                                 L_percent_variance,
                                 I_order_no,
                                 I_item,
                                 I_pack_item,
                                 I_seq_no,
                                 L_comp_id) = FALSE then
         return FALSE;
      end if;
      L_total_est  := L_total_est + L_unit_est_comp_value_prim;
      L_total_act  := L_total_act + L_unit_act_comp_value_prim;
   END LOOP;

   O_unit_est_obl_value_prim  := L_total_est;
   O_unit_act_obl_value_prim  := L_total_act;
   O_total_est_obl_value_prim := L_total_est * I_qty;
   O_total_act_obl_value_prim := L_total_act * I_qty;

   --Get percent variance
   if ALC_SQL.CALC_PERCENT_VARIANCE(O_error_message,
                                   O_percent_variance,
                                   O_unit_act_obl_value_prim,
                                   O_unit_est_obl_value_prim) = FALSE then
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
END GET_OBLIGATION_TOTALS;
---------------------------------------------------------------------------------------------
FUNCTION GET_ORDER_ITEM_TOTALS(O_error_message          IN OUT   VARCHAR2,
                               O_unit_elc_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                               O_unit_alc_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                               O_total_elc_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                               O_total_alc_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                               O_percent_variance       IN OUT   NUMBER,
                               I_order_no               IN       ORDHEAD.ORDER_NO%TYPE,
                               I_item                   IN       ITEM_MASTER.ITEM%TYPE,
                               I_pack_item              IN       ITEM_MASTER.ITEM%TYPE)

   return BOOLEAN is
      L_program                   VARCHAR2(64)                            := 'ALC_SQL.GET_ORDER_ITEM_TOTALS';
      L_import_country_id         ORDHEAD.IMPORT_COUNTRY_ID%TYPE          := 0;
      L_count                     NUMBER(3)                               := 0;
      L_sum_act_value             ALC_COMP_LOC.ACT_VALUE%TYPE             := 0;
      L_act_comp_value            ALC_COMP_LOC.ACT_VALUE%TYPE             := 0;
      L_est_comp_value            ORDLOC_EXP.EST_EXP_VALUE%TYPE           := 0;
      L_total_act_comp_value      ALC_COMP_LOC.ACT_VALUE%TYPE             := 0;
      L_avg_act_comp_value        ALC_COMP_LOC.ACT_VALUE%TYPE             := 0;
      L_total_est_comp_value      ORDLOC_EXP.EST_EXP_VALUE%TYPE           := 0;
      L_unit_cost                 ORDLOC.UNIT_COST%TYPE                   := 0;
      L_zone_total                ORDLOC_EXP.EST_EXP_VALUE%TYPE           := 0;
      L_total_est_expense         ORDLOC_EXP.EST_EXP_VALUE%TYPE           := 0;
      L_total_est_assess          ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE := 0;
      L_est_assess                ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE := 0;
      L_exchange_rate             CURRENCY_RATES.EXCHANGE_RATE%TYPE       := 0;
      L_order_exchange_rate       CURRENCY_RATES.EXCHANGE_RATE%TYPE       := 0;
      L_exists                    BOOLEAN;
      L_qty_received              ORDLOC.QTY_RECEIVED%TYPE;
      L_qty_ordered               ORDLOC.QTY_ORDERED%TYPE;
      L_qty_shipped               SHIPSKU.QTY_EXPECTED%TYPE;
      L_packsku_qty               V_PACKSKU_QTY.QTY%TYPE;
      L_base_qty                  ORDLOC.QTY_ORDERED%TYPE;
      L_zone_group_id             COST_ZONE_GROUP_LOC.ZONE_GROUP_ID%TYPE;
      L_comp_id                   ELC_COMP.COMP_ID%TYPE;
      L_nom_flag_2                ELC_COMP.NOM_FLAG_2%TYPE;
      L_nom_flag_4                ELC_COMP.NOM_FLAG_4%TYPE;
      L_expense_comp_currency     CURRENCIES.CURRENCY_CODE%TYPE;
      L_assess_comp_currency      CURRENCIES.CURRENCY_CODE%TYPE;
      L_order_currency            CURRENCIES.CURRENCY_CODE%TYPE;
      L_location                  ITEM_LOC.LOC%TYPE                       := NULL;


   cursor C_GET_QTY(L_item ITEM_MASTER.ITEM%TYPE) is
         select NVL(SUM(qty_ordered),0),
               NVL(SUM(qty_received),0)
          from ordloc
         where order_no = I_order_no
           and item     = L_item;

   cursor C_GET_QTY_SHIPPED(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(SUM(k.qty_expected),0)
        from shipment s,
             shipsku k
       where s.shipment = k.shipment
         and s.order_no = I_order_no
         and k.item     = L_item;

   cursor C_GET_PACKSKU_QTY is
        select qty
          from v_packsku_qty
         where pack_no  = I_pack_item
           and item     = I_item;

      cursor C_DISTINCT_COMPS is
         select distinct comp_id
           from v_alc_comp v, alc_head h
          where v.order_no    = h.order_no
            and v.seq_no      = h.seq_no
            and v.order_no    = I_order_no
            and h.item        = I_item
            and (h.pack_item  = I_pack_item
                or (h.pack_item is NULL and I_pack_item is NULL));

      cursor C_ASSESS_COMPS is
         select distinct v.comp_id
           from v_alc_comp v, alc_head h, elc_comp e
          where v.order_no    = h.order_no
            and v.seq_no      = h.seq_no
            and e.comp_id     = v.comp_id
            and e.comp_type   = 'A'
            and v.order_no    = I_order_no
            and h.item        = I_item
            and (h.pack_item  = I_pack_item
                or (h.pack_item is NULL and I_pack_item is NULL));

      cursor C_SUM_ACT_VALUE is
         select NVL(SUM(act_value * qty),0)
           from v_alc_comp v, alc_head h
          where v.order_no = h.order_no
            and v.seq_no   = h.seq_no
            and v.comp_id  = L_comp_id
            and v.order_no = I_order_no
            and h.item     = I_item
            and (h.pack_item = I_pack_item
                or (h.pack_item is NULL and I_pack_item is NULL));

      cursor C_ASSESS is
         select a.est_assess_value,
                a.nom_flag_2,
                comp_currency
           from ordsku_hts_assess a,
                ordsku_hts        h,
                elc_comp          e
          where e.comp_id           = a.comp_id
            and h.order_no          = a.order_no
            and h.order_no          = I_order_no
            and h.seq_no            = a.seq_no
            and h.item              = I_item
            and (h.pack_item = I_pack_item
                or (h.pack_item is NULL and I_pack_item is NULL))
            and h.import_country_id = L_import_country_id
            and a.comp_id           = L_comp_id;

      cursor C_DISTINCT_LOCATIONS is
         select distinct location
           from cost_zone_group_loc
          where zone_group_id = L_zone_group_id
            and exists (select 'x'
                          from alc_comp_loc l, alc_head h
                         where l.seq_no      = h.seq_no
                           and l.order_no    = h.order_no
                           and l.order_no    = I_order_no
                           and h.item        = I_item
                           and (h.pack_item = I_pack_item
                               or (h.pack_item is NULL and I_pack_item is NULL))
                           and l.location = cost_zone_group_loc.location);

      cursor C_DISTINCT_ZONE_COMP is
         select distinct l.comp_id
           from alc_head h, alc_comp_loc l, elc_comp e
          where h.seq_no     = l.seq_no
            and h.order_no   = l.order_no
            and l.comp_id    = e.comp_id
            and l.order_no   = I_order_no
            and e.comp_type  = 'E'
            and h.item       = I_item
            and (h.pack_item = I_pack_item
                or (h.pack_item is NULL and I_pack_item is NULL))
            and l.location = L_location;

      cursor  C_EST_EXP is
         select est_exp_value,
                comp_currency,
                exchange_rate,
                nom_flag_4
           from ordloc_exp o
          where order_no    = I_order_no
            and item        = I_item
            and (pack_item = I_pack_item
                 or (pack_item is NULL
                     and I_pack_item is NULL))
            and o.comp_id     = L_comp_id
            and o.location    = L_location;

BEGIN

   /*I_order_no, I_item must be passed into this function.*/

   --Get qty ordered, received, shipped
   if I_pack_item is not NULL then
      SQL_LIB.SET_MARK('OPEN','C_GET_QTY','ORDLOC','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      open C_GET_QTY(I_pack_item);
      SQL_LIB.SET_MARK('FETCH','C_GET_QTY','ORDLOC','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      fetch C_GET_QTY into L_qty_ordered,
                           L_qty_received;
      SQL_LIB.SET_MARK('CLOSE','C_GET_QTY','ORDLOC','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      close C_GET_QTY;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_QTY_SHIPPED','SHIPMENT,SHIPSKU','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      open C_GET_QTY_SHIPPED(I_pack_item);
      SQL_LIB.SET_MARK('FETCH','C_GET_QTY_SHIPPED','SHIPMENT,SHIPSKU','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      fetch C_GET_QTY_SHIPPED into L_qty_shipped;
      SQL_LIB.SET_MARK('CLOSE','C_GET_QTY_SHIPPED','SHIPMENT,SHIPSKU','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      close C_GET_QTY_SHIPPED;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_PACKSKU_QTY','V_PACKSKU_QTY','pack: '||I_pack_item||', item: '||I_item);
      open C_GET_PACKSKU_QTY;
      SQL_LIB.SET_MARK('FETCH','C_GET_PACKSKU_QTY','V_PACKSKU_QTY','pack: '||I_pack_item||', item: '||I_item);
      fetch C_GET_PACKSKU_QTY into L_packsku_qty;
      SQL_LIB.SET_MARK('CLOSE','C_GET_PACKSKU_QTY','V_PACKSKU_QTY','pack: '||I_pack_item||', item: '||I_item);
      close C_GET_PACKSKU_QTY;
      ---
      L_qty_received := L_qty_received * L_packsku_qty;
      L_qty_ordered  := L_qty_ordered  * L_packsku_qty;
      L_qty_shipped  := L_qty_shipped  * L_packsku_qty;
   else
      SQL_LIB.SET_MARK('OPEN','C_GET_QTY','ORDLOC','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      open C_GET_QTY(I_item);
      SQL_LIB.SET_MARK('FETCH','C_GET_QTY','ORDLOC','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      fetch C_GET_QTY into L_qty_ordered,
                           L_qty_received;
      SQL_LIB.SET_MARK('CLOSE','C_GET_QTY','ORDLOC','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      close C_GET_QTY;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_QTY_SHIPPED','SHIPMENT,SHIPSKU','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      open C_GET_QTY_SHIPPED(I_item);
      SQL_LIB.SET_MARK('FETCH','C_GET_QTY_SHIPPED','SHIPMENT,SHIPSKU','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      fetch C_GET_QTY_SHIPPED into L_qty_shipped;
      SQL_LIB.SET_MARK('CLOSE','C_GET_QTY_SHIPPED','SHIPMENT,SHIPSKU','order no: '||to_char(I_order_no)||', item: '||I_pack_item);
      close C_GET_QTY_SHIPPED;
   end if;
   if L_qty_received >= L_qty_ordered then
      L_base_qty := L_qty_received;
   elsif L_qty_shipped > 0 then
      L_base_qty := L_qty_shipped;
   else
      L_base_qty := L_qty_ordered;
   end if;
   ---
   if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                          L_exists,
                                          L_unit_cost,
                                          I_order_no,
                                          I_item,
                                          I_pack_item,
                                          L_location) = FALSE then
      return FALSE;
   end if;
   if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                         L_order_currency,
                                         L_order_exchange_rate,
                                         I_order_no) = FALSE then
      return FALSE;
   end if;
   if CURRENCY_SQL.CONVERT(O_error_message,
                           L_unit_cost,
                           L_order_currency,
                           NULL,
                           L_unit_cost,
                           'N',
                           NULL,
                           NULL,
                           L_order_exchange_rate,
                           NULL) = FALSE then
      return FALSE;
   end if;
   if ITEM_ATTRIB_SQL.GET_COST_ZONE_GROUP(O_error_message,
                                          L_zone_group_id,
                                          I_item) = FALSE then
      return FALSE;
   end if;
   if ORDER_ATTRIB_SQL.GET_IMPORT_COUNTRY(O_error_message,
                                          L_import_country_id,
                                          I_order_no) = FALSE then
      return FALSE;
   end if;
   ---
   --Get actual unit value by averaging sum of component actual values multiplied by qty.
   FOR C_rec in C_DISTINCT_COMPS LOOP
      L_comp_id := C_rec.comp_id;
      SQL_LIB.SET_MARK('OPEN','C_SUM_ACT_VALUE','V_ALC_COMP, ALC_HEAD',NULL);
      open C_SUM_ACT_VALUE;
      SQL_LIB.SET_MARK('FETCH','C_SUM_ACT_VALUE','V_ALC_COMP, ALC_HEAD',NULL);
      fetch C_SUM_ACT_VALUE into L_sum_act_value;
      SQL_LIB.SET_MARK('CLOSE','C_SUM_ACT_VALUE','V_ALC_COMP, ALC_HEAD',NULL);
      close C_SUM_ACT_VALUE;
      ---
      L_total_act_comp_value := L_total_act_comp_value + L_sum_act_value;
   END LOOP;
   ---
   if L_base_qty <> 0 then
      L_avg_act_comp_value := (L_total_act_comp_value / L_base_qty);
   else
      L_avg_act_comp_value := 0;
   end if;
   ---
   O_unit_alc_value_prim := L_avg_act_comp_value + L_unit_cost;


/*Get estimated unit value by summing expenses and assessments*/

  --Expenses- Loop through distinct locations then sum estimated expense
  --values for all distinct component.
   FOR C_rec1 in C_DISTINCT_LOCATIONS LOOP
      L_location             := C_rec1.location;
      L_est_comp_value       := 0;
      L_total_est_comp_value := 0;
      FOR C_rec2 in C_DISTINCT_ZONE_COMP LOOP
         L_comp_id := C_rec2.comp_id;
         SQL_LIB.SET_MARK('OPEN','C_EST_EXP','ORDLOC_EXP, ELC_COMP','Order No.: '||to_char(I_order_no));
         open C_EST_EXP;
         SQL_LIB.SET_MARK('FETCH','C_EST_EXP','ORDLOC_EXP, ELC_COMP','Order No.: '||to_char(I_order_no));
         fetch C_EST_EXP into L_est_comp_value,
                              L_expense_comp_currency,
                              L_exchange_rate,
                              L_nom_flag_4;
         if C_EST_EXP%NOTFOUND then
            L_est_comp_value := 0;
         else
            --Convert to primary currency.
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_est_comp_value,
                                    L_expense_comp_currency,
                                    NULL,
                                    L_est_comp_value,
                                    'N',
                                    NULL,
                                    NULL,
                                    L_exchange_rate,
                                    NULL) = FALSE then
               return FALSE;
            end if;

            if L_nom_flag_4 = '-' then
               L_est_comp_value := (0 - L_est_comp_value);
            elsif L_nom_flag_4 = '+' then
               L_est_comp_value := L_est_comp_value;
            elsif L_nom_flag_4 = 'N' then
               L_est_comp_value := 0;
            end if;
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_EST_EXP','ORDLOC_EXP, ELC_COMP','Order No.: '||to_char(I_order_no));
         close C_EST_EXP;
         L_total_est_comp_value := L_total_est_comp_value + L_est_comp_value;
      END LOOP;  -- distinct components
      L_count      := L_count + 1;
      L_zone_total := L_zone_total + L_total_est_comp_value;
   END LOOP;  --distinct zones
   --Average of estimated expenses for all locations.
   if L_count <> 0 then
      L_total_est_expense := L_zone_total / L_count;
   else
      L_total_est_expense := 0;
   end if;
   ---

   --Assessments  - Sum distinct component values and based on nomination flag.
   FOR C_rec in C_ASSESS_COMPS LOOP
      L_comp_id := C_rec.comp_id;
      SQL_LIB.SET_MARK('OPEN','C_ASSESS','ORDSKU_HTS_ASSESS,ORDSKU_HTS,ELC_COMP','Order No.: '||to_char(I_order_no));
      open C_ASSESS;
      SQL_LIB.SET_MARK('FETCH','C_ASSESS','ORDSKU_HTS_ASSESS,ORDSKU_HTS,ELC_COMP','Order No.: '||to_char(I_order_no));
      fetch C_ASSESS into L_est_assess,
                          L_nom_flag_2,
                          L_assess_comp_currency;
      if C_ASSESS%NOTFOUND then
         L_est_assess := 0;
      else
         --Convert to primary currency.
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_est_assess,
                                 L_assess_comp_currency,
                                 NULL,
                                 L_est_assess,
                                 'N',
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL) = FALSE then
             return FALSE;
         end if;
         --Assign value to estimated assessment based on nom flag value.
         if L_nom_flag_2 = '+' then
            L_est_assess   := L_est_assess;
         elsif L_nom_flag_2 = '-' then
            L_est_assess   := (0 - L_est_assess);
         elsif L_nom_flag_2 = 'N' then
            L_est_assess   := 0;
         end if;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_ASSESS','ORDSKU_HTS_ASSESS,ORDSKU_HTS,ELC_COMP','Order No.: '||to_char(I_order_no));
      close C_ASSESS;
      L_total_est_assess := L_total_est_assess + L_est_assess;
   END LOOP;   -- Loop through distinct comp_id's


  --Total Unit ELC
   O_unit_elc_value_prim := L_total_est_assess
                          + L_total_est_expense
                          + L_unit_cost;

   --Total ELC/ALC
   O_total_elc_value_prim := O_unit_elc_value_prim * L_base_qty;
   O_total_alc_value_prim := O_unit_alc_value_prim * L_base_qty;

   --Percent variance
   if ALC_SQL.CALC_PERCENT_VARIANCE(O_error_message,
                                    O_percent_variance,
                                    O_total_alc_value_prim,
                                    O_total_elc_value_prim) = FALSE then
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
END GET_ORDER_ITEM_TOTALS;
---------------------------------------------------------------------------------------------
FUNCTION GET_SHIP_TOTALS(O_error_message           IN OUT   VARCHAR2,
                         O_unit_elc_value_prim     IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                         O_unit_alc_value_prim     IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                         O_total_elc_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                         O_total_alc_value_prim    IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                         O_percent_variance        IN OUT   NUMBER,
                         I_order_no                IN       ALC_COMP_LOC.ORDER_NO%TYPE,
                         I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                         I_pack_item               IN       ITEM_MASTER.ITEM%TYPE,
                         I_vessel_id               IN       TRANSPORTATION.VESSEL_ID%TYPE,
                         I_voyage_flt_id           IN       TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                         I_estimated_depart_date   IN       TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE)

   RETURN BOOLEAN IS
      L_program                   VARCHAR2(64)                            := 'ALC_SQL.GET_SHIP_TOTALS';
      L_import_country_id         ORDHEAD.IMPORT_COUNTRY_ID%TYPE          := 0;
      L_count                     NUMBER(3)                               := 0;
      L_sum_act_value             ALC_COMP_LOC.ACT_VALUE%TYPE             := 0;
      L_act_comp_value            ALC_COMP_LOC.ACT_VALUE%TYPE             := 0;
      L_est_comp_value            ORDLOC_EXP.EST_EXP_VALUE%TYPE           := 0;
      L_total_act_comp_value      ALC_COMP_LOC.ACT_VALUE%TYPE             := 0;
      L_avg_act_comp_value        ALC_COMP_LOC.ACT_VALUE%TYPE             := 0;
      L_total_est_comp_value      ORDLOC_EXP.EST_EXP_VALUE%TYPE           := 0;
      L_unit_cost                 ORDLOC.UNIT_COST%TYPE                   := 0;
      L_zone_total                ORDLOC_EXP.EST_EXP_VALUE%TYPE           := 0;
      L_total_est_expense         ORDLOC_EXP.EST_EXP_VALUE%TYPE           := 0;
      L_total_est_assess          ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE := 0;
      L_est_assess                ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE := 0;
      L_exchange_rate             CURRENCY_RATES.EXCHANGE_RATE%TYPE       := 0;
      L_order_exchange_rate       CURRENCY_RATES.EXCHANGE_RATE%TYPE       := 0;
      L_exists                    BOOLEAN;
      L_base_qty                  ORDLOC.QTY_ORDERED%TYPE;
      L_packsku_qty               ORDLOC.QTY_ORDERED%TYPE;
      L_zone_group_id             COST_ZONE_GROUP_LOC.ZONE_GROUP_ID%TYPE;
      L_zone_id                   COST_ZONE_GROUP_LOC.ZONE_ID%TYPE;
      L_comp_id                   ELC_COMP.COMP_ID%TYPE;
      L_nom_flag_2                ELC_COMP.NOM_FLAG_2%TYPE;
      L_nom_flag_4                ELC_COMP.NOM_FLAG_4%TYPE;
      L_expense_comp_currency     CURRENCIES.CURRENCY_CODE%TYPE;
      L_assess_comp_currency      CURRENCIES.CURRENCY_CODE%TYPE;
      L_order_currency            CURRENCIES.CURRENCY_CODE%TYPE;
      L_item                      ITEM_MASTER.ITEM%TYPE;
      L_standard_uom              UOM_CLASS.UOM%TYPE;
      L_standard_class            UOM_CLASS.UOM_CLASS%TYPE;
      L_conv_factor               UOM_CONVERSION.FACTOR%TYPE;
      L_supplier                  ITEM_SUPP_COUNTRY.SUPPLIER%TYPE;
      L_origin_country_id         ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
      L_location                  ITEM_LOC.LOC%TYPE;

   cursor C_GET_PACKSKU_QTY is
    select qty
          from v_packsku_qty
         where pack_no  = I_pack_item
           and item     = I_item;

      cursor C_ASSESS_COMPS is
         select distinct v.comp_id
           from v_alc_comp v, alc_head h, elc_comp e
          where v.order_no    = h.order_no
            and v.seq_no      = h.seq_no
            and e.comp_id     = v.comp_id
            and e.comp_type   = 'A'
            and v.order_no    = I_order_no
            and h.item        = I_item
            and (h.pack_item  = I_pack_item
                or (h.pack_item is NULL and I_pack_item is NULL))
            and h.vessel_id             = I_vessel_id
            and h.voyage_flt_id         = I_voyage_flt_id
            and h.estimated_depart_date = I_estimated_depart_date;

      cursor C_SUM_ACT_VALUE is
         select NVL(SUM(act_value * qty),0)
           from v_alc_ship_comp
          where order_no              = I_order_no
            and vessel_id             = I_vessel_id
            and voyage_flt_id         = I_voyage_flt_id
            and estimated_depart_date = I_estimated_depart_date
            and item                  = I_item
            and (pack_item            = I_pack_item
                or (pack_item is NULL and I_pack_item is NULL));

      cursor C_ASSESS is
         select a.est_assess_value,
                a.nom_flag_2,
                comp_currency
           from ordsku_hts_assess a,
                ordsku_hts        h,
                elc_comp          e
          where e.comp_id           = a.comp_id
            and h.order_no          = a.order_no
            and h.order_no          = I_order_no
            and h.seq_no            = a.seq_no
            and h.item              = I_item
            and (h.pack_item = I_pack_item
                or (h.pack_item is NULL and I_pack_item is NULL))
            and h.import_country_id = L_import_country_id
            and a.comp_id           = L_comp_id;

      cursor C_DISTINCT_LOCATIONS is
         select distinct location
           from cost_zone_group_loc
          where zone_group_id = L_zone_group_id
            and exists (select 'x'
                          from alc_comp_loc l, alc_head h
                         where l.seq_no      = h.seq_no
                           and l.order_no    = h.order_no
                           and l.order_no    = I_order_no
                           and h.item        = I_item
                           and (h.pack_item = I_pack_item
                               or (h.pack_item is NULL and I_pack_item is NULL))
                           and h.vessel_id             = I_vessel_id
                           and h.voyage_flt_id         = I_voyage_flt_id
                           and h.estimated_depart_date = I_estimated_depart_date
                           and l.location = cost_zone_group_loc.location);

      cursor C_DISTINCT_ZONE_COMP is
         select distinct l.comp_id
           from alc_head h, alc_comp_loc l, elc_comp e
          where h.seq_no              = l.seq_no
            and h.order_no            = l.order_no
            and l.comp_id             = e.comp_id
            and l.order_no            = I_order_no
            and e.comp_type           = 'E'
            and h.item                = I_item
            and (h.pack_item = I_pack_item
                or (h.pack_item is NULL and I_pack_item is NULL))
            and vessel_id             = I_vessel_id
            and voyage_flt_id         = I_voyage_flt_id
            and estimated_depart_date = I_estimated_depart_date
            and l.location = L_location;

      cursor  C_EST_EXP is
         select est_exp_value,
                comp_currency,
                exchange_rate,
                nom_flag_4
           from ordloc_exp o
          where order_no      = I_order_no
            and item          = I_item
            and (pack_item = I_pack_item
                 or (pack_item is NULL
                     and I_pack_item is NULL))
            and o.comp_id     = L_comp_id
            and o.location    = L_location;

BEGIN
   --- I_order_no, I_item must be passed into this function. All three
   --- parameters of the V/V/E combination must be either NULL or not NULL.

   -- Get total qty's off of transportation table by looping through each unique
   -- transportation record (based on VVE/PO/ITEM) and totaling sums.

   if I_pack_item is NULL then
      L_item := I_item;
   else
      L_item := I_pack_item;
   end if;
   ---Get Standard UOM
   if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                       L_standard_uom,
                                       L_standard_class,
                                       L_conv_factor,
                                       L_item,
                                       'N') = FALSE then
      return FALSE;
   end if;
   ---Get Supplier and Origin Country
   if SUPP_ITEM_ATTRIB_SQL.GET_PRIMARY_SUPP_COUNTRY(O_error_message,
                                                    L_supplier,
                                                    L_origin_country_id,
                                                    L_item) = FALSE then
      return FALSE;
   end if;
   ---
   if TRANSPORTATION_SQL.GET_SHIP_QTY(O_error_message,
                                      L_base_qty,
                                      L_supplier,
                                      L_origin_country_id,
                                      L_standard_uom,
                                      I_vessel_id,
                                      I_voyage_flt_id,
                                      I_estimated_depart_date,
                                      I_order_no,
                                      I_item,
                                      I_pack_item) = FALSE then
      return FALSE;
   end if;
   ---
   if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                          L_exists,
                                          L_unit_cost,
                                          I_order_no,
                                          I_item,
                                          I_pack_item,
                                          NULL) = FALSE then
      return FALSE;
   end if;
   ---
   if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                         L_order_currency,
                                         L_order_exchange_rate,
                                         I_order_no) = FALSE then
      return FALSE;
   end if;
   ---
   if CURRENCY_SQL.CONVERT(O_error_message,
                           L_unit_cost,
                           L_order_currency,
                           NULL,
                           L_unit_cost,
                           'N',
                           NULL,
                           NULL,
                           L_order_exchange_rate,
                           NULL) = FALSE then
      return FALSE;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_COST_ZONE_GROUP(O_error_message,
                                          L_zone_group_id,
                                          I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if ORDER_ATTRIB_SQL.GET_IMPORT_COUNTRY(O_error_message,
                                          L_import_country_id,
                                          I_order_no) = FALSE then
      return FALSE;
   end if;
   ---
   --Get actual unit value by averaging sum of component actual values off of v_alc_ship_comp.
   SQL_LIB.SET_MARK('OPEN','C_SUM_ACT_VALUE','V_ALC_SHIP_COMP, ALC_HEAD',NULL);
   open C_SUM_ACT_VALUE;
   SQL_LIB.SET_MARK('FETCH','C_SUM_ACT_VALUE','V_ALC_SHIP_COMP, ALC_HEAD',NULL);
   fetch C_SUM_ACT_VALUE into L_sum_act_value;
   SQL_LIB.SET_MARK('CLOSE','C_SUM_ACT_VALUE','V_ALC_SHIP_COMP, ALC_HEAD',NULL);
   close C_SUM_ACT_VALUE;
   ---
   if L_base_qty <> 0 then
      L_avg_act_comp_value := (L_sum_act_value / L_base_qty);
   else
      L_avg_act_comp_value := 0;
   end if;
   ---
   O_unit_alc_value_prim := L_avg_act_comp_value + L_unit_cost;
   ---
   -- Get estimated unit value by summing expenses and assessments
   ---
   -- Expenses- Loop through distinct locations then sum estimated expense
   -- values for all distinct component.
   ---
   FOR C_rec1 in C_DISTINCT_LOCATIONS LOOP
      L_location             := C_rec1.location;
      L_est_comp_value       := 0;
      L_total_est_comp_value := 0;
      FOR C_rec2 in C_DISTINCT_ZONE_COMP LOOP
         L_comp_id := C_rec2.comp_id;
         SQL_LIB.SET_MARK('OPEN','C_EST_EXP','ORDLOC_EXP, ELC_COMP','Order No.: '||to_char(I_order_no));
         open C_EST_EXP;
         SQL_LIB.SET_MARK('FETCH','C_EST_EXP','ORDLOC_EXP, ELC_COMP','Order No.: '||to_char(I_order_no));
         fetch C_EST_EXP into L_est_comp_value,
                              L_expense_comp_currency,
                              L_exchange_rate,
                              L_nom_flag_4;
         if C_EST_EXP%NOTFOUND then
            L_est_comp_value := 0;
         else
            --Convert to primary currency.
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_est_comp_value,
                                    L_expense_comp_currency,
                                    NULL,
                                    L_est_comp_value,
                                    'N',
                                    NULL,
                                    NULL,
                                    L_exchange_rate,
                                    NULL) = FALSE then
               return FALSE;
            end if;
            ---
            if L_nom_flag_4 = '-' then
               L_est_comp_value := (0 - L_est_comp_value);
            elsif L_nom_flag_4 = '+' then
               L_est_comp_value := L_est_comp_value;
            elsif L_nom_flag_4 = 'N' then
               L_est_comp_value := 0;
            end if;
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_EST_EXP','ORDLOC_EXP, ELC_COMP','Order No.: '||to_char(I_order_no));
         close C_EST_EXP;
         ---
         L_total_est_comp_value := L_total_est_comp_value + L_est_comp_value;
      END LOOP;  -- distinct components
      L_count      := L_count + 1;
      L_zone_total := L_zone_total + L_total_est_comp_value;
   END LOOP;  --distinct locations
   --Average of estimated expenses for all locations.
   if L_count <> 0 then
      L_total_est_expense := L_zone_total / L_count;
   else
      L_total_est_expense := 0;
   end if;
   ---

   --Assessments  - Sum distinct component values and based on nomination flag.
   FOR C_rec in C_ASSESS_COMPS LOOP
      L_comp_id := C_rec.comp_id;
      SQL_LIB.SET_MARK('OPEN','C_ASSESS','ORDSKU_HTS_ASSESS,ORDSKU_HTS,ELC_COMP','Order No.: '||to_char(I_order_no));
      open C_ASSESS;
      SQL_LIB.SET_MARK('FETCH','C_ASSESS','ORDSKU_HTS_ASSESS,ORDSKU_HTS,ELC_COMP','Order No.: '||to_char(I_order_no));
      fetch C_ASSESS into L_est_assess,
                          L_nom_flag_2,
                          L_assess_comp_currency;
      if C_ASSESS%NOTFOUND then
         L_est_assess := 0;
      else
         --Convert to primary currency.
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_est_assess,
                                 L_assess_comp_currency,
                                 NULL,
                                 L_est_assess,
                                 'N',
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL) = FALSE then
             return FALSE;
         end if;
         --Assign value to estimated assessment based on nom flag value.
         if L_nom_flag_2 = '+' then
            L_est_assess   := L_est_assess;
         elsif L_nom_flag_2 = '-' then
            L_est_assess   := (0 - L_est_assess);
         elsif L_nom_flag_2 = 'N' then
            L_est_assess   := 0;
         end if;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_ASSESS','ORDSKU_HTS_ASSESS,ORDSKU_HTS,ELC_COMP','Order No.: '||to_char(I_order_no));
      close C_ASSESS;
      L_total_est_assess := L_total_est_assess + L_est_assess;
   END LOOP;   -- Loop through distinct comp_id's


   --Total Unit ELC
   O_unit_elc_value_prim := L_total_est_assess
                          + L_total_est_expense
                          + L_unit_cost;

   --Total ELC/ALC
   O_total_elc_value_prim := O_unit_elc_value_prim * L_base_qty;
   O_total_alc_value_prim := O_unit_alc_value_prim * L_base_qty;

   if O_total_elc_value_prim = 0 then
      O_unit_elc_value_prim := 0;
   end if;
   ---
   if O_total_alc_value_prim = 0 then
      O_unit_alc_value_prim := 0;
   end if;

   --Percent variance
   if ALC_SQL.CALC_PERCENT_VARIANCE(O_error_message,
                                    O_percent_variance,
                                    O_total_alc_value_prim,
                                    O_total_elc_value_prim) = FALSE then
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
END GET_SHIP_TOTALS;
---------------------------------------------------------------------------------------------
---This function can pick up all alc_records or just pending records (I_get_all_alc)
FUNCTION CALC_ORD_ITEM_LOC_ALC_INT(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_alc_prim         IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                                   I_order_no         IN       ORDHEAD.ORDER_NO%TYPE,
                                   I_item             IN       ITEM_MASTER.ITEM%TYPE,
                                   I_pack_item        IN       ITEM_MASTER.ITEM%TYPE,
                                   I_location         IN       ORDLOC.LOCATION%TYPE,
                                   I_unit_cost_prim   IN       ORDLOC.UNIT_COST%TYPE,
                                   I_qty_received     IN       ORDLOC.QTY_RECEIVED%TYPE,
                                   I_get_all_alc      IN       VARCHAR2)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)                  := 'ALC_SQL.CALC_ORD_ITEM_LOC_ALC_INT';
   L_comp_value_prim    ALC_COMP_LOC.ACT_VALUE%TYPE   := 0;
   L_act_value_prim     ALC_COMP_LOC.ACT_VALUE%TYPE   := 0;

   cursor C_GET_COMP_VALUE is
      select SUM(act_value * qty)
        from alc_head h,
             alc_comp_loc l
       where h.order_no         = I_order_no
         and h.order_no         = l.order_no
         and h.seq_no           = l.seq_no
         and h.item             = I_item
         and ((h.pack_item      = I_pack_item
               and h.pack_item is NOT NULL
               and I_pack_item is NOT NULL)
           or (h.pack_item     is NULL
               and I_pack_item is NULL))
         and l.location         = I_location
         and (I_get_all_alc = 'Y' or h.status != 'P');

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_COMP_VALUE','ALC_COMP_LOC',NULL);
   open C_GET_COMP_VALUE;
   SQL_LIB.SET_MARK('FETCH','C_GET_COMP_VALUE','ALC_COMP_LOC',NULL);
   fetch C_GET_COMP_VALUE into L_comp_value_prim;
   SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_VALUE','ALC_COMP_LOC',NULL);
   close C_GET_COMP_VALUE;
   ---
   if I_qty_received != 0 then
      L_act_value_prim := (L_comp_value_prim / I_qty_received);
   else
      L_act_value_prim := 0;
   end if;
   ---
   O_alc_prim := L_act_value_prim + I_unit_cost_prim;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END CALC_ORD_ITEM_LOC_ALC_INT;
---------------------------------------------------------------------------------------------
FUNCTION CALC_ORD_ITEM_LOC_ALC(O_error_message    IN OUT   VARCHAR2,
                               O_alc_prim         IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                               I_order_no         IN       ORDHEAD.ORDER_NO%TYPE,
                               I_item             IN       ITEM_MASTER.ITEM%TYPE,
                               I_pack_item        IN       ITEM_MASTER.ITEM%TYPE,
                               I_location         IN       ORDLOC.LOCATION%TYPE,
                               I_unit_cost_prim   IN       ORDLOC.UNIT_COST%TYPE,
                               I_qty_received     IN       ORDLOC.QTY_RECEIVED%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)                  := 'ALC_SQL.CALC_ORD_ITEM_LOC_ALC';
   BEGIN
   ---
   if CALC_ORD_ITEM_LOC_ALC_INT(O_error_message,
                                O_alc_prim,
                                I_order_no,
                                I_item,
                                I_pack_item,
                                I_location,
                                I_unit_cost_prim,
                                I_qty_received,
                                'Y') = FALSE then
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
END CALC_ORD_ITEM_LOC_ALC;
---------------------------------------------------------------------------------------------
FUNCTION UPDATE_STKLEDGR(O_error_message     IN OUT   VARCHAR2,
                         I_order_no          IN       ORDHEAD.ORDER_NO%TYPE,
                         I_item              IN       ITEM_MASTER.ITEM%TYPE,
                         I_pack_item         IN       ITEM_MASTER.ITEM%TYPE,
                         I_supplier          IN       SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(64)                  := 'ALC_SQL.UPDATE_STKLEDGR';
   L_tran_date            DATE                          := GET_VDATE;
   L_qty_received         ORDLOC.QTY_RECEIVED%TYPE      := 0;
   L_unit_cost_ord        ORDLOC.UNIT_COST%TYPE         := 0;
   L_pack_cost_sup        ORDLOC.UNIT_COST%TYPE         := 0;
   L_unit_elc_prim        ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_unit_alc_prim        ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_unit_elc_temp        ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_unit_alc_temp        ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_alc_estimated        ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_alc_finalized        ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_elc_estimated        ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_elc_finalized        ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_unit_elc_loc         ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_unit_alc_loc         ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_diff_prim            ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_diff_loc             ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_packsku_qty          ORDLOC.QTY_RECEIVED%TYPE      := 0;
   L_total_exp            ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_tran_code            TRAN_DATA.TRAN_CODE%TYPE      := 20;
   L_item                 ITEM_MASTER.ITEM%TYPE;
   L_comp_item            ITEM_MASTER.ITEM%TYPE;
   L_pack_no              ITEM_MASTER.ITEM%TYPE;
   L_dept                 DEPS.DEPT%TYPE;
   L_class                CLASS.CLASS%TYPE;
   L_subclass             SUBCLASS.SUBCLASS%TYPE;
   L_origin_country_id    COUNTRY.COUNTRY_ID%TYPE;
   L_import_country_id    COUNTRY.COUNTRY_ID%TYPE;
   L_exchange_rate        CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_order_currency       CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_exp         CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_exp    CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_total_dty            ORDLOC_EXP.EST_EXP_VALUE%TYPE;
   L_currency_dty         CURRENCIES.CURRENCY_CODE%TYPE;
   L_otb                  VARCHAR2(1);
   L_exists               VARCHAR2(1);
   L_pack_ind             ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind         ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind        ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type            ITEM_MASTER.PACK_TYPE%TYPE;
   L_item_level           ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level           ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_loc_type             ITEM_LOC.LOC_TYPE%TYPE;
   L_loc                  ITEM_LOC.LOC%TYPE;
   L_item_desc            ITEM_MASTER.ITEM_DESC%TYPE;
   L_status               ITEM_MASTER.STATUS%TYPE;
   L_dept_name            DEPS.DEPT_NAME%TYPE;
   L_class_name           CLASS.CLASS_NAME%TYPE;
   L_subclass_name        SUBCLASS.SUB_NAME%TYPE;
   L_retail_zone_group_id ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE;
   L_simple_pack_ind      ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_waste_type           ITEM_MASTER.WASTE_TYPE%TYPE;
   L_item_parent          ITEM_MASTER.ITEM_PARENT%TYPE;
   L_item_grandparent     ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_short_desc           ITEM_MASTER.SHORT_DESC%TYPE;
   L_waste_pct            ITEM_MASTER.WASTE_PCT%TYPE;
   L_default_waste_pct    ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE;

   ---
   cursor C_GET_ORD_INFO is
      select s.origin_country_id,
             o.import_country_id,
             o.currency_code,
             o.exchange_rate
        from ordhead o,
             ordsku s
       where o.order_no = I_order_no
         and o.order_no = s.order_no
         and s.item     = NVL(I_pack_item, I_item);

   cursor C_GET_LOCS is
      select distinct l.location,
             l.loc_type,
             o.qty_received
        from ordloc o,
             alc_head a,
             alc_comp_loc l
       where a.order_no         = I_order_no
         and a.order_no         = o.order_no
         and a.order_no         = l.order_no
         and a.seq_no           = l.seq_no
         and o.location         = l.location
         and a.item             = I_item
         and ((a.pack_item      = I_pack_item
               and o.item       = a.pack_item
               and a.pack_item is not NULL
               and I_pack_item is not NULL)
           or (a.pack_item     is NULL
               and I_pack_item is NULL
               and o.item = a.item));

   cursor C_PACK_COST is
      select SUM(iscl.unit_cost * v.qty)
        from v_packsku_qty v,
             item_supp_country_loc iscl
       where v.pack_no              = I_item
         and v.item                 = iscl.item
         and iscl.supplier          = I_supplier
         and iscl.origin_country_id = L_origin_country_id
         and iscl.loc               = L_loc
         and iscl.loc_type          = L_loc_type;

   cursor C_ITEMS_IN_PACK is
      select vpq.item,
             vpq.qty,
             it.unit_cost,
             im.dept,
             im.class,
             im.subclass
        from v_packsku_qty vpq,
             item_supp_country it,
             item_master im
       where vpq.pack_no          = I_item
         and vpq.item             = it.item
         and im.item              = vpq.item
         and it.supplier          = I_supplier
         and it.origin_country_id = L_origin_country_id;

   cursor C_OTB(L_dept_param DEPS.DEPT%TYPE) is
     select otb_calc_type
       from deps
      where dept = L_dept_param;

   cursor C_PACKSKU_QTY is
      select qty
        from v_packsku_qty
       where pack_no           = I_pack_item
         and item              = I_item;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_GET_ORD_INFO','ORDHEAD,ORDSKU',NULL);
   open C_GET_ORD_INFO;
   SQL_LIB.SET_MARK('FETCH','C_GET_ORD_INFO','ORDHEAD,ORDSKU',NULL);
   fetch C_GET_ORD_INFO into L_origin_country_id,
                             L_import_country_id,
                             L_order_currency,
                             L_exchange_rate;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ORD_INFO','ORDHEAD,ORDSKU',NULL);
   close C_GET_ORD_INFO;
   ---
   if I_pack_item is not NULL then
      L_item      := I_item;
      L_comp_item := I_item;
      L_pack_no   := I_pack_item;
      ---
      SQL_LIB.SET_MARK('OPEN','C_PACKSKU_QTY','V_PACKSKU_QTY','Pack: '||I_pack_item||' Item: '||I_item);
      open C_PACKSKU_QTY;
      SQL_LIB.SET_MARK('FETCH','C_PACKSKU_QTY','V_PACKSKU_QTY','Pack: '||I_pack_item||' Item: '||I_item);
      fetch C_PACKSKU_QTY into L_packsku_qty;
      SQL_LIB.SET_MARK('CLOSE','C_PACKSKU_QTY','V_PACKSKU_QTY','Pack: '||I_pack_item||' Item: '||I_item);
      close C_PACKSKU_QTY;
   else
      L_item := I_item;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_INFO(O_error_message,
                               L_item_desc,
                               L_item_level,
                               L_tran_level,
                               L_status,
                               L_pack_ind,
                               L_dept,
                               L_dept_name,
                               L_class,
                               L_class_name,
                               L_subclass,
                               L_subclass_name,
                               L_retail_zone_group_id,
                               L_sellable_ind,
                               L_orderable_ind,
                               L_pack_type,
                               L_simple_pack_ind,
                               L_waste_type,
                               L_item_parent,
                               L_item_grandparent,
                               L_short_desc,
                               L_waste_pct,
                               L_default_waste_pct,
                               I_item) = FALSE then
      return FALSE;
   end if;
   ---
   FOR C_rec in C_GET_LOCS LOOP
      ---
      L_loc_type := C_rec.loc_type;
      L_loc := C_rec.location;
      L_qty_received := C_rec.qty_received;
      ---
      if ALC_SQL.EXT_ALC_LOC_TOTALS(O_error_message,
                                    L_alc_estimated,
                                    L_unit_alc_prim, -- pending ALC
                                    L_alc_finalized,
                                    I_order_no,
                                    L_item,
                                    L_pack_no,
                                    L_loc,
                                    L_loc_type) = FALSE then
         return FALSE;
      end if;
      -- Convert extended ALC to Unit ALC
      L_unit_alc_prim := L_unit_alc_prim / L_qty_received;

      if ALC_SQL.UNIT_ELC_LOC_TOTALS(O_error_message,
                                     L_elc_estimated,
                                     L_unit_elc_prim, -- pending ELC
                                     L_elc_finalized,
                                     I_order_no,
                                     L_item,
                                     L_pack_no,
                                     L_loc,
                                     L_import_country_id) = FALSE then
         return FALSE;
      end if;
      ---
      if (I_pack_item is NULL and L_pack_ind = 'Y') then
         SQL_LIB.SET_MARK('OPEN','C_PACK_COST','V_PACKSKU_QTY,ITEM_SUPP_COUNTRY',NULL);
         open C_PACK_COST;
         SQL_LIB.SET_MARK('FETCH','C_PACK_COST','V_PACKSKU_QTY,ITEM_SUPP_COUNTRY',NULL);
         fetch C_PACK_COST into L_pack_cost_sup;
         SQL_LIB.SET_MARK('CLOSE','C_PACK_COST','V_PACKSKU_QTY,ITEM_SUPP_COUNTRY',NULL);
         close C_PACK_COST;
         ---
         L_unit_alc_temp := L_unit_alc_prim;
         L_unit_elc_temp := L_unit_elc_prim;
         ---
         FOR L_rec in C_ITEMS_IN_PACK LOOP
         -- For vendor pack components, the landed costs must be prorated before calling this UPDATE_STKLEDGR_LOC.
         -- Prorated cost = Cost * (Component Unit Cost / Total Pack Unit Cost).
              L_unit_alc_prim := (L_unit_alc_temp * (L_rec.unit_cost / L_pack_cost_sup));
              L_unit_elc_prim := (L_unit_elc_temp * (L_rec.unit_cost / L_pack_cost_sup));

            if ALC_SQL.UPDATE_STKLEDGR_LOC(O_error_message,
                                           I_order_no,
                                           L_rec.item,
                                           L_loc,
                                           L_loc_type,
                                           L_rec.dept,
                                           L_rec.class,
                                           L_rec.subclass,
                                           L_rec.qty * L_qty_received,
                                           L_unit_alc_prim,
                                           L_unit_elc_prim,
                                           I_item) = FALSE then
               return FALSE;
             end if;
         END LOOP;
      else
         if ALC_SQL.UPDATE_STKLEDGR_LOC(O_error_message,
                                I_order_no,
                                I_item,
                                L_loc,
                                L_loc_type,
                                L_dept,
                                L_class,
                                L_subclass,
                                L_qty_received,
                                L_unit_alc_prim,
                                L_unit_elc_prim,
                                I_pack_item) = FALSE then
             return FALSE;
         end if;
      end if;   -- if (I_pack_item is NULL and pack_ind = 'Y')
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
END UPDATE_STKLEDGR;
---------------------------------------------------------------------------------------------
--- Returns 'PR' if alc has been finalized, 'P' otherwise
--- This is to support the calling code, which is checking for values 'P', 'PR'
--- Called by oblmain.fmb
---------------------------------------------------------------------------------------------
FUNCTION GET_STATUS (O_error_message    IN OUT   VARCHAR2,
                     O_exists           IN OUT   BOOLEAN,
                     O_status           IN OUT   OBLIGATION.STATUS%TYPE,
                     I_obligation_key   IN       OBLIGATION.OBLIGATION_KEY%TYPE)
   return BOOLEAN is

      L_program  VARCHAR2(40) := 'ALC_SQL.GET_STATUS';
      L_exists   VARCHAR2(1)  := NULL;

      cursor C_STATUS is
         select max(decode(status, 'P', 'P', 'PR'))
           from alc_head
          where obligation_key = I_obligation_key;
BEGIN
   O_exists := TRUE;
   if I_obligation_key is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_STATUS','ALC_HEAD',
                    'OBLIGATION KEY: '||to_char(I_obligation_key));
   open C_STATUS;
   SQL_LIB.SET_MARK('FETCH','C_STATUS','ALC_HEAD',
                    'OBLIGATION KEY: '||to_char(I_obligation_key));
   fetch C_STATUS into O_status;
   if C_STATUS%NOTFOUND then
      O_exists        := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_ALC_FOR_OBL',to_char(I_obligation_key),NULL,NULL);
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_STATUS','ALC_HEAD',
                    'OBLIGATION KEY: '||to_char(I_obligation_key));
   close C_STATUS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;
END GET_STATUS;
---------------------------------------------------------------------------------------------
--- Returns 'PR' if alc has been finalized, 'P' otherwise
--- This is to support the calling code, which is checking for status='PR'
--- Called by recctadj.fmb
---------------------------------------------------------------------------------------------
FUNCTION GET_STATUS (O_error_message   IN OUT   VARCHAR2,
                     O_status          IN OUT   ALC_HEAD.STATUS%TYPE,
                     I_order_no        IN       ORDHEAD.ORDER_NO%TYPE,
                     I_item            IN       ORDSKU.ITEM%TYPE)
   return BOOLEAN is

   L_program       VARCHAR2(40)                   := 'ALC_SQL.GET_STATUS';
   L_pack_type     ITEM_MASTER.PACK_TYPE%TYPE     := NULL;
   L_pack_ind      ITEM_MASTER.PACK_IND%TYPE      := NULL;
   L_sellable_ind  ITEM_MASTER.SELLABLE_IND%TYPE  := NULL;
   L_orderable_ind ITEM_MASTER.ORDERABLE_IND%TYPE := NULL;

   cursor C_GET_ALC_STATUS is
      select max(decode(status, 'P', 'P', 'PR'))
        from alc_head
       where order_no = I_order_no
         and ((L_pack_type = 'B'
                 and pack_item = I_item)
          or ((L_pack_type != 'B' or L_pack_type is NULL)
                 and item = I_item));
BEGIN
   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN','C_GET_ALC_STATUS','ALC_HEAD',NULL);
   open C_GET_ALC_STATUS;
   SQL_LIB.SET_MARK('FETCH','C_GET_ALC_STATUS','ALC_HEAD',NULL);
   fetch C_GET_ALC_STATUS into O_status;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ALC_STATUS','ALC_HEAD',NULL);
   close C_GET_ALC_STATUS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;
END GET_STATUS;
---------------------------------------------------------------------------------------------
FUNCTION DELETE_ERRORS (O_error_message    IN OUT   VARCHAR2,
                        I_order_no         IN       ORDHEAD.ORDER_NO%TYPE,
                        I_obligation_key   IN       OBLIGATION.OBLIGATION_KEY%TYPE,
                        I_entry_no         IN       CE_HEAD.ENTRY_NO%TYPE)
   RETURN BOOLEAN IS
      L_program       VARCHAR2(40) := 'ALC_SQL.DELETE_ERRORS';
      L_unit_of_work  VARCHAR2(255);
      ---
      L_table         VARCHAR2(30);
      RECORD_LOCKED   EXCEPTION;
      PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

      cursor C_LOCK_ERRORS is
         select 'x'
           from if_errors
          where unit_of_work like L_unit_of_work
            for update nowait;
BEGIN
   if (I_obligation_key is NULL and I_entry_no is NULL) or
      (I_obligation_key is not NULL and I_entry_no is not NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;

   if I_obligation_key is not NULL then
      L_unit_of_work := 'Order No. '||to_char(I_order_no)||'%'||
                        ', Obligation '||to_char(I_obligation_key)||'%';
   else
      L_unit_of_work := '%'||'Entry No. '||I_entry_no||'%';
   end if;

   L_table := 'IF_ERRORS';
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ERRORS','IF_ERRORS',L_unit_of_work);
   open C_LOCK_ERRORS;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ERRORS','IF_ERRORS',L_unit_of_work);
   close C_LOCK_ERRORS;

   SQL_LIB.SET_MARK('DELETE',NULL,'IF_ERRORS',L_unit_of_work);
   delete from if_errors
    where unit_of_work like L_unit_of_work;

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_unit_of_work,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_ERRORS;
-------------------------------------------------------------------------------
FUNCTION CHECK_ALC_ERRORS(O_error_message   IN OUT   VARCHAR2,
                          O_exists          IN OUT   BOOLEAN,
                          I_order_no        IN       ORDHEAD.ORDER_NO%TYPE,
                          I_item            IN       ITEM_MASTER.ITEM%TYPE,
                          I_pack_item       IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is
      L_exists      VARCHAR(1)     := NULL;
      L_program     VARCHAR2(64)   := 'ALC_SQL.CHECK_ALC_ERRORS';

   cursor C_CHECK_ERRORS is
      select 'X'
        from alc_head
       where order_no  = I_order_no
         and ((item    = I_item and I_pack_item is NULL)
          or (item     = I_item and pack_item = I_pack_item
         and I_pack_item is not NULL))
         and error_ind = 'Y';
BEGIN
   if I_order_no is NULL or I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',
                                            L_program,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_ERRORS','ALC_HEAD',NULL);
   open C_CHECK_ERRORS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ERRORS','ALC_HEAD',NULL);
   fetch C_CHECK_ERRORS into L_exists;
   ---
   if C_CHECK_ERRORS%FOUND then
      O_error_message :=SQL_LIB.CREATE_MSG('CANNOT_FINALIZE',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
      O_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ERRORS','ALC_HEAD',NULL);
   close C_CHECK_ERRORS;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
      return FALSE;
END CHECK_ALC_ERRORS;
--------------------------------------------------------------------------------
FUNCTION UPDATE_STATUS(O_error_message   IN OUT   VARCHAR2,
                       I_order_no        IN       ORDHEAD.ORDER_NO%TYPE,
                       I_item            IN       ITEM_MASTER.ITEM%TYPE,
                       I_pack_item       IN       ITEM_MASTER.ITEM%TYPE,
                       I_status          IN       ALC_HEAD.STATUS%TYPE)
   RETURN BOOLEAN IS

   L_program  VARCHAR2(40)      := 'ALC_SQL.UPDATE_STATUS';
   L_table         VARCHAR2(30) := 'ALC_HEAD';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from alc_head
       where order_no = I_order_no
         and item     = I_item
         and pack_item is NULL
         for update nowait;

   cursor C_LOCK_ALC_HEAD_PACK is
      select 'x'
        from alc_head
       where order_no  = I_order_no
         and item      = I_item
         and pack_item = I_pack_item
         for update nowait;

BEGIN
   if I_pack_item is NULL then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ALC_HEAD','ALC_HEAD','Order: '||to_char(I_order_no)||' Item: '||I_item);
      open C_LOCK_ALC_HEAD;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALC_HEAD','ALC_HEAD','Order: '||to_char(I_order_no)||' Item: '||I_item);
      close C_LOCK_ALC_HEAD;
      ---
      SQL_LIB.SET_MARK('UPDATE',NULL,'ALC_HEAD','Order: '||to_char(I_order_no)||' Item: '||I_item);
      update alc_head
         set status     = I_status
       where order_no   = I_order_no
         and item       = I_item
         and pack_item is NULL;
   else
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ALC_HEAD_PACK','ALC_HEAD','Order: '||to_char(I_order_no)||
                                                                ' Item: '||I_item||
                                                                ' Pack: '||I_pack_item);
      open C_LOCK_ALC_HEAD_PACK;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALC_HEAD_PACK','ALC_HEAD','Order: '||to_char(I_order_no)||
                                                                 ' Item: '||I_item||
                                                                 ' Pack: '||I_pack_item);
      close C_LOCK_ALC_HEAD_PACK;
      ---
      SQL_LIB.SET_MARK('UPDATE',NULL,'ALC_HEAD','Order: '||to_char(I_order_no)||
                                                ' Item: '||I_item||
                                                ' Pack: '||I_pack_item);
      update alc_head
         set status    = I_status
       where order_no  = I_order_no
         and item      = I_item
         and pack_item = I_pack_item;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_order_no),
                                            I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;
END UPDATE_STATUS;
---------------------------------------------------------------------------------------------
FUNCTION GET_ORDER_TOTALS (O_error_message          IN OUT   VARCHAR2,
                           O_total_elc_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                           O_total_alc_value_prim   IN OUT   ALC_COMP_LOC.ACT_VALUE%TYPE,
                           O_percent_variance       IN OUT   NUMBER,
                           I_order_no               IN       ORDHEAD.ORDER_NO%TYPE)

RETURN BOOLEAN is

      L_program              VARCHAR2(64)                 := 'ALC_SQL.GET_ORDER_TOTALS ';
      L_unit_elc_value_prim  ALC_COMP_LOC.ACT_VALUE%TYPE  := 0;
      L_unit_alc_value_prim  ALC_COMP_LOC.ACT_VALUE%TYPE  := 0;
      L_total_elc_value_prim ALC_COMP_LOC.ACT_VALUE%TYPE  := 0;
      L_total_alc_value_prim ALC_COMP_LOC.ACT_VALUE%TYPE  := 0;
      L_percent_variance     NUMBER(20)                   := 0;
      L_item                 ITEM_MASTER.ITEM%TYPE;
      L_pack_item            ITEM_MASTER.ITEM%TYPE;

      cursor C_ALC_ITEM is
      select distinct item,
             pack_item
        from alc_head
       where order_no = I_order_no;

BEGIN

if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
else
   for C_rec in C_ALC_ITEM loop
      L_item      := C_rec.item;
      L_pack_item := C_rec.pack_item;
      if ALC_SQL.GET_ORDER_ITEM_TOTALS(O_error_message,
                                       L_unit_elc_value_prim,
                                       L_unit_alc_value_prim,
                                       L_total_elc_value_prim,
                                       L_total_alc_value_prim,
                                       L_percent_variance,
                                       I_order_no,
                                       L_item,
                                       L_pack_item) = FALSE then
         return FALSE;
      end if;
      O_total_elc_value_prim := NVL(O_total_elc_value_prim,0) + L_total_elc_value_prim;
      O_total_alc_value_prim := NVL(O_total_alc_value_prim,0) + L_total_alc_value_prim;
   end loop;

   if ALC_SQL.CALC_PERCENT_VARIANCE(O_error_message,
                                    O_percent_variance,
                                    O_total_alc_value_prim,
                                    O_total_elc_value_prim) = FALSE then
      return FALSE;
   end if;
end if;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
      return FALSE;
END GET_ORDER_TOTALS;
--------------------------------------------------------------------------------
FUNCTION DEL_ALC_HEAD (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_order_no        IN       ORDHEAD.ORDER_NO%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(64) := 'ALC_SQL.DEL_ALC_HEAD';
   L_exists VARCHAR2(1) := NULL;

   cursor C_ALC_COMP_LOC is
      select 'x'
        from alc_comp_loc
       where order_no = I_order_no
         and rownum   = 1;

   cursor C_ALC_HEAD is
      select 'x'
        from alc_head
       where order_no = I_order_no
         and rownum   = 1;

BEGIN

   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_program,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_ALC_COMP_LOC',
                    'ALC_COMP_LOC',
                    'Order_no: '||I_order_no);
   open C_ALC_COMP_LOC;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ALC_COMP_LOC',
                    'ALC_COMP_LOC',
                    'Order_no: '||I_order_no);
   fetch C_ALC_COMP_LOC into L_exists;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ALC_COMP_LOC',
                    'ALC_COMP_LOC',
                    'Order_no: '||I_order_no);
   close C_ALC_COMP_LOC;

   if L_exists = 'x' then
      delete from alc_comp_loc
       where order_no = I_order_no;
   end if;
   ---
   L_exists := NULL;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_ALC_HEAD',
                    'ALC_HEAD',
                    'Order_no: '||I_order_no);
   open C_ALC_HEAD;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ALC_HEAD',
                    'ALC_HEAD',
                    'Order_no: '||I_order_no);
   fetch C_ALC_HEAD into L_exists;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ALC_HEAD',
                    'ALC_HEAD',
                    'Order_no: '||I_order_no);
   close C_ALC_HEAD;

   if L_exists = 'x' then
      delete from alc_head
       where order_no = I_order_no;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
      return FALSE;
END DEL_ALC_HEAD;
---------------------------------------------------------------------------------------------
FUNCTION GET_ALC_COMP_STATUS(O_error_message    IN OUT VARCHAR2,
                             O_status           IN OUT ALC_HEAD.STATUS%TYPE,
                             I_order_no         IN     ORDHEAD.ORDER_NO%TYPE,
                             I_item             IN     ITEM_MASTER.ITEM%TYPE,
                             I_pack_item        IN     ITEM_MASTER.ITEM%TYPE,
                             I_comp_id          IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN is

      L_program              VARCHAR2(64)                 := 'ALC_SQL.GET_ALC_COMP_STATUS';
      L_count                NUMBER(2)                    := 0;

   cursor C_STATUS is
      select distinct DECODE(h.status, 'P', 'P', 'F') ALC_STATUS
        from alc_comp_loc l, alc_head h
       where l.order_no    = h.order_no
         and l.seq_no      = h.seq_no
         and l.order_no    = I_order_no
         and h.item        = I_item
         and (h.pack_item  = I_pack_item
             or (h.pack_item is NULL and I_pack_item is NULL))
         and (h.obligation_key is not NULL or h.ce_id is not NULL)
         and l.comp_id     = I_comp_id
      order by 1;

BEGIN

   O_status := 'E';

   for C_rec in C_STATUS loop
      L_count := L_count + 1;
      if L_count = 1 then
         O_status := C_rec.alc_status;
      else
         O_status := 'M';
      end if;
   end loop;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
      return FALSE;
END GET_ALC_COMP_STATUS;
---------------------------------------------------------------------------------------------
FUNCTION GET_ALC_ITEM_STATUS(O_error_message    IN OUT VARCHAR2,
                             O_status           IN OUT ALC_HEAD.STATUS%TYPE,
                             I_order_no         IN     ORDHEAD.ORDER_NO%TYPE,
                             I_item             IN     ITEM_MASTER.ITEM%TYPE,
                             I_pack_item        IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is

      L_program              VARCHAR2(64)                 := 'ALC_SQL.GET_ALC_ITEM_STATUS';
      L_count                NUMBER(2)                    := 0;

   cursor C_STATUS is
      select distinct DECODE(h.status, 'P', 'P', 'F') ALC_ITEM_STATUS
        from alc_comp_loc l, alc_head h
       where l.order_no    = h.order_no
         and l.seq_no      = h.seq_no
         and l.order_no    = I_order_no
         and h.item        = I_item
         and (h.pack_item  = I_pack_item
             or (h.pack_item is NULL and I_pack_item is NULL))
         and (h.obligation_key is not NULL or h.ce_id is not NULL)
      order by 1;

BEGIN

   O_status := 'E';

   for C_rec in C_STATUS loop
      L_count := L_count + 1;
      if L_count = 1 then
         O_status := C_rec.alc_item_status;
      else
         O_status := 'M';
      end if;
   end loop;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
      return FALSE;
END GET_ALC_ITEM_STATUS;
---------------------------------------------------------------------------------------------
FUNCTION UNIT_ELC_LOC_TOTALS(O_error_message         IN OUT VARCHAR2,
                             O_unit_elc_estimated    IN OUT ALC_COMP_LOC.ACT_VALUE%TYPE,
                             O_unit_elc_pending      IN OUT ALC_COMP_LOC.ACT_VALUE%TYPE,
                             O_unit_elc_finalized    IN OUT ALC_COMP_LOC.ACT_VALUE%TYPE,
                             I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                             I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                             I_pack_item             IN     ITEM_MASTER.ITEM%TYPE,
                             I_loc                   IN     ORDLOC.LOCATION%TYPE,
                             I_import_country_id     IN     COUNTRY.COUNTRY_ID%TYPE)
RETURN BOOLEAN is

      L_program              VARCHAR2(64)                    := 'ALC_SQL.UNIT_ELC_LOC_TOTALS';
      L_comp_id              ELC_COMP.COMP_ID%TYPE;
      L_status               ALC_HEAD.STATUS%TYPE;
      L_estimated_value      ALC_COMP_LOC.ACT_VALUE%TYPE     := 0;
      L_expense_value        ALC_COMP_LOC.ACT_VALUE%TYPE     := 0;
      L_assess_value         ALC_COMP_LOC.ACT_VALUE%TYPE     := 0;
      L_comp_currency        ELC_COMP.COMP_CURRENCY%TYPE;
      L_exchange_rate        ORDLOC_EXP.EXCHANGE_RATE%TYPE   := 0;
      L_flag                 VARCHAR2(1)                     := 'N';  -- flag used to compute ELC

   cursor C_ORDSKU_HTS is
      select DECODE(a.nom_flag_2, '-', -1, '+', 1, 0) * a.est_assess_value ASSESS_VALUE,
             DECODE(a.nom_flag_4, '-', -1, '+', 1, 0) * a.est_assess_value EXPENSE_VALUE,
             a.comp_id,
             e.comp_currency
        from ordsku_hts_assess a,
             ordsku_hts        h,
             elc_comp          e
       where h.order_no          = a.order_no
         and h.order_no          = I_order_no
         and h.seq_no            = a.seq_no
         and h.item              = I_item
         and (h.pack_item = I_pack_item
             or (h.pack_item is NULL and I_pack_item is NULL))
         and h.import_country_id = I_import_country_id
         and (a.nom_flag_2 in ('+', '-') or a.nom_flag_4 in ('+', '-'))
         and a.comp_id           = e.comp_id
       order by e.comp_level;

   cursor C_ORDLOC_EXP is
      select DECODE(o.nom_flag_2, '-', -1, '+', 1, 0) * o.est_exp_value ASSESS_VALUE,
             DECODE(o.nom_flag_4, '-', -1, '+', 1, 0) * o.est_exp_value EXPENSE_VALUE,
             o.comp_id,
             o.comp_currency,
             o.exchange_rate
        from ordloc_exp o,
             elc_comp e
       where o.order_no    = I_order_no
         and o.item        = I_item
         and (o.pack_item  = I_pack_item
              or (o.pack_item is NULL and I_pack_item is NULL))
         and o.location    = I_loc
         and (o.nom_flag_2 in ('+', '-') or o.nom_flag_4 in ('+', '-'))
         and o.comp_id     = e.comp_id
       order by e.comp_level;
BEGIN

   O_unit_elc_estimated  := 0;
   O_unit_elc_pending    := 0;
   O_unit_elc_finalized  := 0;
   L_flag                := 'N';

   for C_rec in C_ORDSKU_HTS loop
      L_comp_id          := C_rec.comp_id;
      L_status           := NULL;
      L_expense_value    := C_rec.expense_value;
      L_assess_value     := C_rec.assess_value;
      L_comp_currency    := C_rec.comp_currency;
      L_estimated_value  := 0;

      if L_comp_id = 'TDTY'||I_import_country_id then
      	 L_flag := 'Y';
      end if;

      if L_flag = 'Y' then
      	 L_estimated_value := L_expense_value;
      else
      	 L_estimated_value := L_expense_value + L_assess_value;
      end if;

      if ALC_SQL.GET_ALC_COMP_STATUS(O_error_message,
		                     L_status,
		                     I_order_no,
		                     I_item,
		                     I_pack_item,
		                     L_comp_id) = FALSE then
         return FALSE;
      end if;

      --Convert L_estimated_value to primary currency
      if CURRENCY_SQL.CONVERT(O_error_message,
	                      L_estimated_value,
	                      L_comp_currency,
	                      NULL,
	                      L_estimated_value,
	                      'N',
	                      NULL,
	                      'P',
	                      NULL, --L_exchange_rate,
	                      NULL) = FALSE then
	     return FALSE;
	    end if;
        /* Add the converted estimated value to the appropriate total depending */
        /* on the component status ('F'inalized and 'M'ultiple should both be   */
        /* added to the finalized total.                                        */
       if L_status = 'P' then
          O_unit_elc_pending   :=   O_unit_elc_pending + L_estimated_value;
       elsif L_status = 'F' or L_status = 'M'  then
          O_unit_elc_finalized := O_unit_elc_finalized + L_estimated_value;
       elsif L_status = 'E' then
          O_unit_elc_estimated := O_unit_elc_estimated + L_estimated_value;
       else
       	  O_error_message := SQL_LIB.CREATE_MSG('INV_STATUS',
       	                                        NULL,
       	                                        NULL);
          return FALSE;
       end if;
   end loop;

   L_flag := 'N'; -- reset flag;

   for C_rec in C_ORDLOC_EXP loop
      L_comp_id          := C_rec.comp_id;
      L_status           := NULL;
      L_expense_value    := C_rec.expense_value;
      L_assess_value     := C_rec.assess_value;
      L_comp_currency    := C_rec.comp_currency;
      L_exchange_rate    := C_rec.exchange_rate;
      L_estimated_value  := 0;

      if L_comp_id = 'TEXP' then
      	 L_flag := 'Y';
      end if;

      if L_flag = 'Y' then
      	 L_estimated_value := L_assess_value;
      else
      	 L_estimated_value := L_expense_value + L_assess_value;
      end if;

      if ALC_SQL.GET_ALC_COMP_STATUS(O_error_message,
		                     L_status,
		                     I_order_no,
		                     I_item,
		                     I_pack_item,
		                     L_comp_id) = FALSE then
         return FALSE;
      end if;
      --Convert L_estimated_value to primary currency
      if CURRENCY_SQL.CONVERT(O_error_message,
	                      L_estimated_value,
	                      L_comp_currency,
	                      NULL,
	                      L_estimated_value,
	                      'N',
	                      NULL,
	                      'P',
	                      L_exchange_rate,
	                      NULL) = FALSE then
	     return FALSE;
	    end if;

        /* Add the converted estimated value to the appropriate total depending */
        /* on the component status ('F'inalized and 'M'ultiple should both be   */
        /* added to the finalized total.                                        */
       if L_status = 'P' then
          O_unit_elc_pending   := O_unit_elc_pending + L_estimated_value;
       elsif L_status = 'F' or L_status = 'M'  then
          O_unit_elc_finalized := O_unit_elc_finalized + L_estimated_value;
       elsif L_status = 'E' then
          O_unit_elc_estimated := O_unit_elc_estimated + L_estimated_value;
       else
       	  O_error_message := SQL_LIB.CREATE_MSG('INV_STATUS',
       	                                        NULL,
       	                                        NULL);
          return FALSE;
       end if;
   end loop;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
      return FALSE;
END UNIT_ELC_LOC_TOTALS;
---------------------------------------------------------------------------------------------
FUNCTION EXT_ALC_LOC_TOTALS(O_error_message         IN OUT VARCHAR2,
                            O_ext_alc_estimated     IN OUT ALC_COMP_LOC.ACT_VALUE%TYPE,
                            O_ext_alc_pending       IN OUT ALC_COMP_LOC.ACT_VALUE%TYPE,
                            O_ext_alc_finalized     IN OUT ALC_COMP_LOC.ACT_VALUE%TYPE,
                            I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                            I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                            I_pack_item             IN     ITEM_MASTER.ITEM%TYPE,
                            I_loc                   IN     ORDLOC.LOCATION%TYPE,
                            I_loc_type              IN     ORDLOC.LOC_TYPE%TYPE)
RETURN BOOLEAN is

   L_program              VARCHAR2(64)                    := 'ALC_SQL.EXT_ALC_LOC_TOTALS';

   cursor C_SUM_ALC is
      select NVL(SUM(DECODE(h.status, 'P', act_value * qty, 0)), 0) PENDING_VALUE,
             NVL(SUM(DECODE(h.status, 'P', 0, act_value * qty)), 0) FINALIZED_VALUE
        from alc_comp_loc l, alc_head h
       where l.order_no = h.order_no
         and l.seq_no   = h.seq_no
         and l.location = I_loc
         and l.order_no = I_order_no
         and h.item     = I_item
         and (h.pack_item = I_pack_item
             or (h.pack_item is NULL and I_pack_item is NULL))
         and (h.obligation_key is not NULL or h.ce_id is not NULL);

   cursor C_SUM_EST is
      select NVL(SUM(act_value * qty), 0) ESTIMATED_VALUE
        from alc_comp_loc l, alc_head h
       where l.order_no = h.order_no
         and l.seq_no   = h.seq_no
         and l.location = I_loc
         and l.order_no = I_order_no
         and h.item     = I_item
         and (h.pack_item = I_pack_item
             or (h.pack_item is NULL and I_pack_item is NULL))
         and h.obligation_key is NULL
         and h.ce_id is NULL;

BEGIN
   SQL_LIB.SET_MARK('OPEN','EXT_ALC_LOC_TOTALS','ALC_HEAD',NULL);
   open C_SUM_ALC;
   SQL_LIB.SET_MARK('FETCH','EXT_ALC_LOC_TOTALS','ALC_HEAD',NULL);
   fetch C_SUM_ALC into O_ext_alc_pending, O_ext_alc_finalized;
   SQL_LIB.SET_MARK('CLOSE','EXT_ALC_LOC_TOTALS','ALC_HEAD',NULL);
   close C_SUM_ALC;

   SQL_LIB.SET_MARK('OPEN','EXT_ALC_LOC_TOTALS','ALC_HEAD',NULL);
   open C_SUM_EST;
   SQL_LIB.SET_MARK('FETCH','EXT_ALC_LOC_TOTALS','ALC_HEAD',NULL);
   fetch C_SUM_EST into O_ext_alc_estimated;
   SQL_LIB.SET_MARK('CLOSE','EXT_ALC_LOC_TOTALS','ALC_HEAD',NULL);
   close C_SUM_EST;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
      return FALSE;
END EXT_ALC_LOC_TOTALS;
---------------------------------------------------------------------------------------------
FUNCTION UPDATE_STKLEDGR_LOC(O_error_message       IN OUT VARCHAR2,
                             I_order_no            IN     ORDHEAD.ORDER_NO%TYPE,
                             I_item                IN     ITEM_MASTER.ITEM%TYPE,
                             I_loc                 IN     ORDLOC.LOCATION%TYPE,
                             I_loc_type            IN     ORDLOC.LOC_TYPE%TYPE,
                             I_dept                IN     DEPS.DEPT%TYPE,
                             I_class               IN     CLASS.CLASS%TYPE,
                             I_subclass            IN     SUBCLASS.SUBCLASS%TYPE,
                             I_qty_received        IN     ORDLOC.QTY_RECEIVED%TYPE,
                             I_unit_lc_new         IN     ALC_COMP_LOC.ACT_VALUE%TYPE,
                             I_unit_lc_old         IN     ALC_COMP_LOC.ACT_VALUE%TYPE,
                             I_pack_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is

   L_program              VARCHAR2(64)                    := 'ALC_SQL.UPDATE_STKLEDGR_LOC';
   L_tran_date            DATE                            := GET_VDATE;
   L_tran_code            TRAN_DATA.TRAN_CODE%TYPE        := 20;
   L_qty_received         ORDLOC.QTY_RECEIVED%TYPE        := 0;
   L_otb                  VARCHAR2(1);
   L_diff_prim            ORDLOC_EXP.EST_EXP_VALUE%TYPE   := 0;
   L_diff_loc             ORDLOC_EXP.EST_EXP_VALUE%TYPE   := 0;
   L_ext_diff_loc         ORDLOC_EXP.EST_EXP_VALUE%TYPE   := 0;
   L_item_level           ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level           ITEM_MASTER.TRAN_LEVEL%TYPE;
   I_unit_lc_new_loc      ALC_COMP_LOC.ACT_VALUE%TYPE;
   I_unit_lc_old_loc      ALC_COMP_LOC.ACT_VALUE%TYPE;

   cursor C_OTB is
     select otb_calc_type
       from deps
      where dept = I_dept;

BEGIN

   if I_unit_lc_new != I_unit_lc_old then
       ---
       --- Update OTB
       ---
       SQL_LIB.SET_MARK('OPEN','C_OTB','DEPS','DEPT: '|| to_char(I_dept));
       open C_OTB;
       SQL_LIB.SET_MARK('FETCH','C_OTB','DEPS','DEPT: '|| to_char(I_dept));
       fetch C_OTB into L_otb;
       SQL_LIB.SET_MARK('CLOSE','C_OTB','DEPS','DEPT: '|| to_char(I_dept));
       close C_OTB;
       ---
       L_qty_received := I_qty_received;
       ---
       L_diff_prim := I_unit_lc_new - I_unit_lc_old;
       ---
       if L_otb = 'C' then
          ---
          if OTB_SQL.ORD_RECEIVE(O_error_message,
	                             0,
	                             L_diff_prim,
	                             I_order_no,
	                             I_dept,
	                             I_class,
	                             I_subclass,
	                             I_qty_received,
	                             0) = FALSE then
	     return FALSE;
	   end if;
	end if;

      ---
      -- For WAC, we need the unit costs converted to the location currency.
      ---
      if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                          NULL,
                                          NULL,
                                          NULL,
                                          I_loc,
                                          I_loc_type,
                                          NULL,
                                          I_unit_lc_new,
                                          I_unit_lc_new_loc,
                                          'C',
                                          NULL,
                                          NULL) = FALSE then
            return FALSE;
      end if;
      if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                          NULL,
                                          NULL,
                                          NULL,
                                          I_loc,
                                          I_loc_type,
                                          NULL,
                                          I_unit_lc_old,
                                          I_unit_lc_old_loc,
                                          'C',
                                          NULL,
                                          NULL) = FALSE then
            return FALSE;
      end if;
      if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                          NULL,
                                          NULL,
                                          NULL,
                                          I_loc,
                                          I_loc_type,
                                          NULL,
                                          L_diff_prim,
                                          L_diff_loc,
                                          'C',
                                          NULL,
                                          NULL) = FALSE then
            return FALSE;
      end if;
      ---
      -- Update the appropriate average cost.
      ---
      if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                    L_item_level,
                                    L_tran_level,
                                    I_item) = FALSE then
         return FALSE;
      end if;
      ---

      if ITEMLOC_UPDATE_SQL.UPD_AV_COST_CHANGE_COST(O_error_message,
                                                    I_item,
                                                    I_loc,
                                                    I_loc_type,
                                                    I_unit_lc_new_loc,
                                                    I_unit_lc_old_loc,
                                                    I_qty_received,
                                                    NULL,     -- new wac
                                                    NULL,     -- neg_soh_wac_adj_amt
                                                    'Y',
                                                     I_order_no,
                                                      NULL,
                                                     I_pack_item,
                                                    'ALC_SQL.UPDATE_STKLEDGR_LOC',
                                                    'A') = FALSE then
         return FALSE;
      end if;
      ---
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
      return FALSE;
END UPDATE_STKLEDGR_LOC;
---------------------------------------------------------------------------------------------
FUNCTION DETERMINE_STATUS(I_estimated_ind    IN     VARCHAR2,
                          I_no_finalize_ind  IN     VARCHAR2,
                          I_pending_ind      IN     VARCHAR2,
                          I_processed_ind    IN     VARCHAR2)
  RETURN ALC_HEAD.STATUS%TYPE IS
BEGIN
   if I_no_finalize_ind is not null then
      return 'N';
   elsif I_pending_ind is not null and I_processed_ind is not null then
      return 'M';
   elsif I_pending_ind is not null then
      return 'P';
   elsif I_processed_ind is not null then
      return 'F';
   else
      return 'E';
   end if;

EXCEPTION
   when OTHERS then
      return NULL;
END DETERMINE_STATUS;
---------------------------------------------------------------------------------------------
END ALC_SQL;
/

