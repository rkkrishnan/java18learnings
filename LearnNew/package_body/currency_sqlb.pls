CREATE OR REPLACE PACKAGE BODY CURRENCY_SQL AS

--------------------------------------------------------------------------------
--                            PRIVATE GLOBALS                                 --
--------------------------------------------------------------------------------

type CURRENCY_RATE_RECORD is record
(
exchange_rate   CURRENCY_RATES.EXCHANGE_RATE%TYPE
);

type CURRENCY_RATE_TABLE is table of CURRENCY_RATE_RECORD
index by CURRENCY_RATES.EXCHANGE_TYPE%TYPE;

type CURRENCY_RECORD is record
(
currency_desc       CURRENCIES.CURRENCY_DESC%TYPE,
currency_cost_fmt   CURRENCIES.CURRENCY_COST_FMT%TYPE,
currency_rtl_fmt    CURRENCIES.CURRENCY_RTL_FMT%TYPE,
currency_cost_dec   CURRENCIES.CURRENCY_COST_DEC%TYPE,
currency_rtl_dec    CURRENCIES.CURRENCY_RTL_DEC%TYPE,
euro_ex_rate        EURO_EXCHANGE_RATE.EXCHANGE_RATE%TYPE,
--
rate_tbl            CURRENCY_RATE_TABLE
);

type CURRENCY_TABLE is table of CURRENCY_RECORD
index by CURRENCIES.CURRENCY_CODE%TYPE;

LP_vdate_currency_cache_date   DATE := null;
LP_vdate_currency_cache        CURRENCY_TABLE;
LP_currency_cache_date         DATE := null;
LP_currency_cache              CURRENCY_TABLE;

LP_prim_eur_ind      VARCHAR2(1);
LP_consolidation_ind system_options.consolidation_ind%TYPE;
LP_primary_currency  system_options.currency_code%TYPE;

LP_order_no               ordhead.order_no%TYPE;
LP_order_curr_code        system_options.currency_code%TYPE;

LP_wh_no                  wh.wh%TYPE;
LP_wh_curr_code           system_options.currency_code%TYPE;

LP_store_no               store.store%TYPE;
LP_store_curr_code        system_options.currency_code%TYPE;

LP_external_finisher      v_external_finisher.finisher_id%TYPE;
LP_ext_fin_curr_code      v_external_finisher.currency_code%TYPE;

LP_supplier               sups.supplier%TYPE;
LP_supplier_curr_code     system_options.currency_code%TYPE;

LP_zone_group_id          price_zone.zone_group_id%TYPE;
LP_zone_id                price_zone.zone_id%TYPE;
LP_zone_curr_code         system_options.currency_code%TYPE;


--------------------------------------------------------------------------------
--                          PRIVATE PROTOTYPES                                --
--------------------------------------------------------------------------------

FUNCTION GET_EURO_CURR_EXCHG_RATE(O_error_message IN OUT VARCHAR2,
                                  I_currency_code IN     CURRENCIES.CURRENCY_CODE%TYPE,
                                  O_exchange_rate    OUT CURRENCY_RATES.EXCHANGE_RATE%TYPE)
RETURN BOOLEAN;

FUNCTION GET_CURR_EXCHG_RATE(O_error_message  IN OUT VARCHAR2,
                             I_currency_code  IN     CURRENCIES.CURRENCY_CODE%TYPE,
                             I_effective_date IN     DATE,
                             I_exchange_type  IN     CURRENCY_RATES.EXCHANGE_TYPE%TYPE,
                             O_exchange_rate     OUT CURRENCY_RATES.EXCHANGE_RATE%TYPE)
RETURN BOOLEAN;

FUNCTION GET_CURR_INFO(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       I_effective_date IN     DATE)
RETURN BOOLEAN;


--------------------------------------------------------------------------------
--                          PUBLIC PROCEDURES                                 --
--------------------------------------------------------------------------------

FUNCTION CONVERT_PERM(O_error_message        IN OUT  VARCHAR2,
                      I_currency_value       IN      NUMBER,
                      I_currency             IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                      I_currency_out         IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                      O_currency_value       IN OUT  NUMBER,
                      I_cost_retail_ind      IN      VARCHAR2,
                      I_effective_date       IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE,
                      I_exchange_type        IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE,
                      I_in_exchange_rate     IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE,
                      I_out_exchange_rate    IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE)

        return BOOLEAN IS
   L_program              VARCHAR2(64)  := 'CURRENCY_SQL.CONVERT_PERM';
   L_in_exchange_rate     currency_rates.exchange_rate%TYPE := I_in_exchange_rate;
   L_out_exchange_rate    currency_rates.exchange_rate%TYPE := I_out_exchange_rate;

BEGIN
   if (L_in_exchange_rate is NULL
   or L_in_exchange_rate = 0)
   then
      if (I_currency = LP_primary_currency and LP_prim_eur_ind = 'N')
       or (I_currency = 'EUR' and LP_prim_eur_ind = 'Y') then
         L_in_exchange_rate := 1;
      else
         if not CURRENCY_SQL.GET_RATE(O_error_message,
                                   L_in_exchange_rate,
                                   I_currency,
                                   I_exchange_type,
                                   I_effective_date) then
            return FALSE;
         end if;
      end if;
      ---
   end if;
   ---
   if (L_out_exchange_rate is NULL
   or L_out_exchange_rate = 0)
   then
      if (I_currency_out = LP_primary_currency and LP_prim_eur_ind = 'N')
       or (I_currency_out = 'EUR' and LP_prim_eur_ind = 'Y') then
         L_out_exchange_rate := 1;
      else
         if not CURRENCY_SQL.GET_RATE(O_error_message,
                                      L_out_exchange_rate,
                                      I_currency_out,
                                      I_exchange_type,
                                      I_effective_date) then
            return FALSE;
         end if;
      end if;
      ---
   end if;
   ---
   /* Convert the currency value to the new currency */

   O_currency_value := NVL(I_currency_value,0) * (NVL(L_out_exchange_rate,0)/
                                          NVL(L_in_exchange_rate,1));


   /* Round the currency amount to the appropriate number of decimal places */
   if ROUND_CURRENCY(O_error_message,
                     O_currency_value,
                     I_currency_out,
                     I_cost_retail_ind) = FALSE then
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
END CONVERT_PERM;
-------------------------------------------------------------------------------------------
FUNCTION CONVERT_TEMP(O_error_message        IN OUT  VARCHAR2,
                      I_currency_value       IN      NUMBER,
                      I_currency             IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                      I_currency_out         IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                      O_currency_value       IN OUT  NUMBER,
                      I_cost_retail_ind      IN      VARCHAR2,
                      I_effective_date       IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE,
                      I_exchange_type        IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE,
                      I_in_exchange_rate     IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE,
                      I_out_exchange_rate    IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE)

        return BOOLEAN IS

   L_program              VARCHAR2(64)  := 'CURRENCY_SQL.CONVERT_TEMP';
   L_in_exchange_rate     currency_rates.exchange_rate%TYPE := I_in_exchange_rate;
   L_out_exchange_rate    currency_rates.exchange_rate%TYPE := I_out_exchange_rate;

BEGIN
   if I_currency = 'EUR' then
      L_in_exchange_rate := 1;
   else
      if GET_EURO_CURR_EXCHG_RATE(O_error_message,
                                  I_currency,
                                  L_in_exchange_rate) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if I_currency_out = 'EUR' then
      L_out_exchange_rate := 1;
   else
      if GET_EURO_CURR_EXCHG_RATE(O_error_message,
                                  I_currency_out,
                                  L_out_exchange_rate) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   /* Convert the currency value to the new currency */
   O_currency_value := NVL(I_currency_value,0) * (NVL(L_out_exchange_rate,0)/
                                          NVL(L_in_exchange_rate,1));

   /* Round the currency amount to the appropriate number of decimal places */
   if ROUND_CURRENCY(O_error_message,
                     O_currency_value,
                     I_currency_out,
                     I_cost_retail_ind) = FALSE then
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
END CONVERT_TEMP;
-------------------------------------------------------------------------------------------
FUNCTION CONVERT_EURO(O_error_message        IN OUT  VARCHAR2,
                      I_currency_value       IN      NUMBER,
                      I_currency             IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                      I_currency_out         IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                      O_currency_value       IN OUT  NUMBER,
                      I_cost_retail_ind      IN      VARCHAR2,
                      I_effective_date       IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE,
                      I_exchange_type        IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE,
                      I_in_exchange_rate     IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE,
                      I_out_exchange_rate    IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE,
                      I_in_curr_emu_ind      IN      BOOLEAN,
                      I_out_curr_emu_ind     IN      BOOLEAN)
   RETURN BOOLEAN IS

   L_program                   VARCHAR2(64)  := 'CURRENCY_SQL.CONVERT_EURO';
   L_temp_currency_value       NUMBER;
   L_temp_prim_currency_value  NUMBER;
   L_temp_currency_value2      NUMBER;

BEGIN
   ---
   if LP_prim_eur_ind = 'Y' then
         ---
         if CURRENCY_SQL.CONVERT_PERM(O_error_message,
                                      I_currency_value,
                                      I_currency,
                                      'EUR',
                                      L_temp_currency_value,
                                      NULL,
                                      I_effective_date,
                                      I_exchange_type,
                                      I_in_exchange_rate,
                                      NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if CURRENCY_SQL.CONVERT_PERM(O_error_message,
                                      L_temp_currency_value,
                                      'EUR',
                                      I_currency_out,
                                      O_currency_value,
                                      I_cost_retail_ind,
                                      I_effective_date,
                                      I_exchange_type,
                                      NULL,
                                      I_out_exchange_rate) = FALSE then
            return FALSE;
         end if;
         ---
   else
      ---
      if (I_in_curr_emu_ind = TRUE AND I_out_curr_emu_ind = FALSE) then
         ---
         if CURRENCY_SQL.CONVERT_TEMP(O_error_message,
                                      I_currency_value,
                                      I_currency,
                                      'EUR',
                                      L_temp_currency_value,
                                      NULL,
                                      I_effective_date,
                                      I_exchange_type,
                                      NULL,
                                      NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if CURRENCY_SQL.CONVERT_PERM(O_error_message,
                                      L_temp_currency_value,
                                      'EUR',
                                      I_currency_out,
                                      O_currency_value,
                                      I_cost_retail_ind,
                                      I_effective_date,
                                      I_exchange_type,
                                      I_in_exchange_rate,
                                      I_out_exchange_rate) = FALSE then
            return FALSE;
         end if;
         ---
      elsif (I_in_curr_emu_ind = FALSE AND I_out_curr_emu_ind = TRUE) then
         ---
         if CURRENCY_SQL.CONVERT_PERM(O_error_message,
                                      I_currency_value,
                                      I_currency,
                                      'EUR',
                                      L_temp_currency_value,
                                      NULL,
                                      I_effective_date,
                                      I_exchange_type,
                                      I_in_exchange_rate,
                                      I_out_exchange_rate) = FALSE then
            return FALSE;
         end if;
         ---
         if CURRENCY_SQL.CONVERT_TEMP(O_error_message,
                                      L_temp_currency_value,
                                      'EUR',
                                      I_currency_out,
                                      O_currency_value,
                                      I_cost_retail_ind,
                                      I_effective_date,
                                      I_exchange_type,
                                      NULL,
                                      NULL) = FALSE then
            return FALSE;
         end if;
         ---
      elsif I_in_exchange_rate is NOT NULL or I_out_exchange_rate is NOT NULL then
         ---
         if CURRENCY_SQL.CONVERT_TEMP(O_error_message,
                                      I_currency_value,
                                      I_currency,
                                      'EUR',
                                      L_temp_currency_value,
                                      NULL,
                                      I_effective_date,
                                      I_exchange_type,
                                      NULL,
                                      NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if CURRENCY_SQL.CONVERT_PERM(O_error_message,
                                      L_temp_currency_value,
                                      'EUR',
                                      LP_primary_currency,
                                      L_temp_prim_currency_value,
                                      NULL,
                                      I_effective_date,
                                      I_exchange_type,
                                      I_in_exchange_rate,
                                      NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if CURRENCY_SQL.CONVERT_PERM(O_error_message,
                                      L_temp_prim_currency_value,
                                      LP_primary_currency,
                                      'EUR',
                                      L_temp_currency_value2,
                                      NULL,
                                      I_effective_date,
                                      I_exchange_type,
                                      NULL,
                                      I_out_exchange_rate) = FALSE then
            return FALSE;
         end if;
         ---
         if CURRENCY_SQL.CONVERT_TEMP(O_error_message,
                                      L_temp_currency_value2,
                                      'EUR',
                                      I_currency_out,
                                      O_currency_value,
                                      I_cost_retail_ind,
                                      I_effective_date,
                                      I_exchange_type,
                                      NULL,
                                      NULL) = FALSE then
            return FALSE;
         end if;
         ---
      else
         ---
         if CURRENCY_SQL.CONVERT_TEMP(O_error_message,
                                      I_currency_value,
                                      I_currency,
                                      'EUR',
                                      L_temp_currency_value,
                                      NULL,
                                      I_effective_date,
                                      I_exchange_type,
                                      NULL,
                                      NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if CURRENCY_SQL.CONVERT_TEMP(O_error_message,
                                      L_temp_currency_value,
                                      'EUR',
                                      I_currency_out,
                                      O_currency_value,
                                      I_cost_retail_ind,
                                      I_effective_date,
                                      I_exchange_type,
                                      NULL,
                                      NULL) = FALSE then
            return FALSE;
         end if;
         ---
      end if;
      ---
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
END CONVERT_EURO;
-------------------------------------------------------------------------------------------
FUNCTION GET_NAME (O_error_message      IN OUT  VARCHAR2,
                       I_currency_code  IN      CURRENCIES.CURRENCY_CODE%TYPE,
                       O_currency_desc  IN OUT  CURRENCIES.CURRENCY_DESC%TYPE)
        return BOOLEAN IS

   L_program            VARCHAR2(64) := 'CURRENCY_SQL.GET_NAME';
   L_currency_desc      currencies.currency_desc%TYPE := NULL;
   L_vdate              DATE := GET_VDATE;

BEGIN

   if GET_CURR_INFO(O_error_message,
                    L_vdate) = FALSE then
      return FALSE;
   end if;

   --

   if LP_vdate_currency_cache.exists(I_currency_code) then
      L_currency_desc := LP_vdate_currency_cache(I_currency_code).currency_desc;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_CURRENCY',
                                            NULL, NULL, NULL);
      return FALSE;
   end if;

   if LANGUAGE_SQL.TRANSLATE(L_currency_desc,
                             O_currency_desc,
                             O_error_message) = FALSE then
      O_error_message := O_error_message;
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
END GET_NAME;
-----------------------------------------------------------------------------------
FUNCTION GET_RATE (O_error_message      IN OUT  VARCHAR2,
                       O_exchange_rate  IN OUT  CURRENCY_RATES.EXCHANGE_RATE%TYPE,
                   I_currency_code      IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                       I_exchange_type  IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE,
                   I_effective_date IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE)

        return BOOLEAN IS

   L_program              VARCHAR2(64)                          := 'CURRENCY_SQL.GET_RATE';
   L_exchange_type        CURRENCY_RATES.EXCHANGE_TYPE%TYPE;
   L_effective_date       CURRENCY_RATES.EFFECTIVE_DATE%TYPE;
   L_participating        BOOLEAN                               := NULL;
   L_currency_code        CURRENCY_RATES.CURRENCY_CODE%TYPE     := I_currency_code;
   L_prim_participating   BOOLEAN                               := NULL;

BEGIN
   if LP_consolidation_ind is NULL then
      if SYSTEM_OPTIONS_SQL.CONSOLIDATION_IND (O_error_message,
                                             LP_consolidation_ind) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if I_exchange_type is NULL then
      ---
      if LP_consolidation_ind = 'Y' then
         L_exchange_type := 'C';
      else
         L_exchange_type := 'O';
      end if;
      ---
   else
      L_exchange_type := I_exchange_type;
   end if;
   ---
   if I_effective_date is NULL then
      L_effective_date := GET_VDATE;
   else
      L_effective_date := I_effective_date;
   end if;
   ---
   if LP_primary_currency is NULL then
      if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                          LP_primary_currency) = FALSE then
         return FALSE;
      end if;
         ---
   end if;

   if LP_prim_eur_ind is NULL then
      ---
      if CURRENCY_SQL.CHECK_EMU_COUNTRIES(O_error_message,
                                          L_prim_participating,
                                          LP_primary_currency) = FALSE then
         return FALSE;
      end if;
      ---
      if (LP_primary_currency = 'EUR' or L_prim_participating = TRUE) then
         LP_prim_eur_ind := 'Y';
      else
         LP_prim_eur_ind := 'N';
      end if;
      ---
   end if;
   ---
   if CURRENCY_SQL.CHECK_EMU_COUNTRIES(O_error_message,
                                       L_participating,
                                       L_currency_code) = FALSE then
      return FALSE;
   end if;
   ---
   if (L_participating = TRUE and LP_prim_eur_ind = 'N') then
      L_currency_code := 'EUR';
   end if;
   ---
   if GET_CURR_EXCHG_RATE(O_error_message,
                          L_currency_code,
                          L_effective_date,
                          L_exchange_type,
                          O_exchange_rate) = FALSE then
      return FALSE;
   end if;
   ---
   if O_exchange_rate is NULL then
      -- If the exchange_rate is not found, and the exchange_type is either
      -- consolidation or operational, raise an error.
      if L_exchange_type in ('C','O') then
         O_error_message := SQL_LIB.CREATE_MSG('EXCHANGE_RATE_NOT_EXIST',
                                               NULL, NULL, NULL);
         return FALSE;
      else
      -- If the exchange_rate is not found, and the exchange_type is neither
      -- consolidation nor operational, then retrieve the consolidation or
      -- operational exchange_rate.
         if  LP_consolidation_ind = 'Y' then
            L_exchange_type := 'C';
         else
            L_exchange_type := 'O';
         end if;
         ---
         if GET_CURR_EXCHG_RATE(O_error_message,
                                L_currency_code,
                                L_effective_date,
                                L_exchange_type,
                                O_exchange_rate) = FALSE then
            return FALSE;
         end if;
         ---
         if O_exchange_rate is NULL then
            O_error_message := SQL_LIB.CREATE_MSG('EXCHANGE_RATE_NOT_EXIST',
                                                   NULL, NULL, NULL);
            return FALSE;
         end if;
         ---
      end if;
      ---
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_RATE;
------------------------------------------------------------------------------------
FUNCTION GET_FORMAT (O_error_message       IN OUT VARCHAR2,
                     I_currency_code       IN     CURRENCIES.CURRENCY_CODE%TYPE,
                     O_currency_rtl_fmt    IN OUT CURRENCIES.CURRENCY_RTL_FMT%TYPE,
                     O_currency_rtl_dec    IN OUT CURRENCIES.CURRENCY_RTL_DEC%TYPE,
                     O_currency_cost_fmt   IN OUT CURRENCIES.CURRENCY_COST_FMT%TYPE,
                     O_currency_cost_dec   IN OUT CURRENCIES.CURRENCY_COST_DEC%TYPE)
     return BOOLEAN IS

   L_program  VARCHAR2(64) := 'CURRENCY_SQL.GET_FORMAT';
   L_vdate    DATE := GET_VDATE;

BEGIN

   if GET_CURR_INFO(O_error_message,
                    L_vdate) = FALSE then
      return FALSE;
   end if;

   --

   if LP_vdate_currency_cache.exists(I_currency_code) then
      O_currency_rtl_fmt := LP_vdate_currency_cache(I_currency_code).currency_rtl_fmt;
      O_currency_rtl_dec := LP_vdate_currency_cache(I_currency_code).currency_rtl_dec;
      O_currency_cost_fmt := LP_vdate_currency_cache(I_currency_code).currency_cost_fmt;
      O_currency_cost_dec := LP_vdate_currency_cache(I_currency_code).currency_cost_dec;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_FORMAT;
------------------------------------------------------------------------
FUNCTION CONVERT_BY_LOCATION (O_error_message        IN OUT  VARCHAR2,
                              I_location_in          IN      VARCHAR2,
                              I_location_type_in     IN      VARCHAR2,
                              I_zone_group_id_in     IN      PRICE_ZONE.ZONE_GROUP_ID%TYPE,
                              I_location_out         IN      VARCHAR2,
                              I_location_type_out    IN      VARCHAR2,
                              I_zone_group_id_out    IN      PRICE_ZONE.ZONE_GROUP_ID%TYPE,
                              I_currency_value       IN      NUMBER,
                              O_currency_value       IN OUT  NUMBER,
                              I_cost_retail_ind      IN      VARCHAR2,
                              I_effective_date       IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE,
                              I_exchange_type        IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE)

        return BOOLEAN IS

   L_program                VARCHAR2(64)  := 'CURRENCY_SQL.CONVERT_BY_LOCATION';
   L_currency_in            CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_out           CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_in       ORDHEAD.EXCHANGE_RATE%TYPE;
   L_exchange_rate_out      ORDHEAD.EXCHANGE_RATE%TYPE;

BEGIN

   if (I_location_in is NULL and I_location_out is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                       NULL, NULL, NULL);
      return FALSE;
   end if;

   ---
   if I_location_in is not NULL then
      ---
      if I_location_type_in = 'O' then
         ---
         if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                               L_currency_in,
                                               L_exchange_rate_in,
                                               I_location_in) = FALSE then
            return FALSE;
         end if;
         ---
      elsif I_location_type_in = 'I' then
         ---
         if INVC_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                              L_currency_in,
                                              L_exchange_rate_in,
                                              I_location_in) = FALSE then
            return FALSE;
         end if;
         ---
      else
         ---
         if CURRENCY_SQL.GET_CURR_LOC(O_error_message,
                                      I_location_in,
                                      I_location_type_in,
                                      I_zone_group_id_in,
                                      L_currency_in) = FALSE then
            return FALSE;
         end if;
         ---
      end if;
      ---
   end if;
   ---
   if I_location_out is not NULL then
      ---
      if I_location_type_out = 'O' then
         ---
         if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                               L_currency_out,
                                               L_exchange_rate_out,
                                               I_location_out) = FALSE then
            return FALSE;
         end if;
         ---
      elsif I_location_type_out = 'I' then
         ---
         if INVC_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                              L_currency_out,
                                              L_exchange_rate_out,
                                              I_location_out) = FALSE then
            return FALSE;
         end if;
         ---
      else
         ---
         if CURRENCY_SQL.GET_CURR_LOC(O_error_message,
                                      I_location_out,
                                      I_location_type_out,
                                      I_zone_group_id_out,
                                      L_currency_out) = FALSE then
            return FALSE;
         end if;
         ---
      end if;
      ---
   end if;
   ---
   if CURRENCY_SQL.CONVERT(O_error_message,
                           I_currency_value,
                           L_currency_in,
                           L_currency_out,
                           O_currency_value,
                           I_cost_retail_ind,
                           I_effective_date,
                           I_exchange_type,
                           L_exchange_rate_in,
                           L_exchange_rate_out) = FALSE then
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
END CONVERT_BY_LOCATION;
-------------------------------------------------------------------------------------------
FUNCTION CONVERT (
            O_error_message        IN OUT  VARCHAR2,
            I_currency_value       IN      NUMBER,
            I_currency             IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
            I_currency_out         IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
            O_currency_value       IN OUT  NUMBER,
            I_cost_retail_ind      IN      VARCHAR2,
            I_effective_date       IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE,
            I_exchange_type        IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE,
            I_in_exchange_rate     IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE,
            I_out_exchange_rate    IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE)

        return BOOLEAN IS

   L_program           VARCHAR2(64)  := 'CURRENCY_SQL.CONVERT';
   L_in_currency_code  currencies.currency_code%TYPE := I_currency;
   L_out_currency_code currencies.currency_code%TYPE := I_currency_out;
   L_in_exchange_rate  currency_rates.exchange_rate%TYPE := I_in_exchange_rate;
   L_out_exchange_rate currency_rates.exchange_rate%TYPE := I_out_exchange_rate;
   L_prim_curr_emu_ind BOOLEAN;
   L_in_curr_emu_ind   BOOLEAN;
   L_out_curr_emu_ind  BOOLEAN;

BEGIN
   ---
   if (I_currency is NULL AND I_currency_out is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                    NULL, NULL, NULL);
      return FALSE;
   end if;
   ---
   if LP_primary_currency is NULL then
      if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                          LP_primary_currency) = FALSE then
         return FALSE;
      end if;
      ---
   end if;
   ---
   if CHECK_EMU_COUNTRIES(O_error_message,
                          L_prim_curr_emu_ind,
                          LP_primary_currency) = FALSE then
      return FALSE;
   end if;
   ---
   if (L_prim_curr_emu_ind = TRUE OR LP_primary_currency = 'EUR') then
      LP_prim_eur_ind := 'Y';
   else
      LP_prim_eur_ind := 'N';
   end if;
   ---
   if I_currency is NULL then
      if L_prim_curr_emu_ind = FALSE then
         if L_in_exchange_rate is NULL then
            L_in_exchange_rate  := 1;
         end if;
      end if;
      L_in_currency_code  := LP_primary_currency;
   elsif I_currency_out is NULL then
      if L_prim_curr_emu_ind = FALSE then
         if L_out_exchange_rate is NULL then
            L_out_exchange_rate := 1;
         end if;
      end if;
      L_out_currency_code := LP_primary_currency;
   end if;
   ---
   if CURRENCY_SQL.CHECK_EMU_COUNTRIES(O_error_message,
                                       L_in_curr_emu_ind,
                                       L_in_currency_code) = FALSE then
      return FALSE;
   end if;
   ---
   if CURRENCY_SQL.CHECK_EMU_COUNTRIES(O_error_message,
                                       L_out_curr_emu_ind,
                                       L_out_currency_code) = FALSE then
      return FALSE;
   end if;
   ---
   if (L_in_currency_code = L_out_currency_code)
    and I_in_exchange_rate is NULL
    and I_out_exchange_rate is NULL then
      O_currency_value := I_currency_value;
      ---


      ---
      O_currency_value := ROUND(O_currency_value, 4);
      return TRUE;
   end if;
   ---
   if ((L_in_curr_emu_ind = FALSE AND L_out_curr_emu_ind = FALSE)
   OR (L_in_currency_code = 'EUR' AND L_out_curr_emu_ind = FALSE)
   OR (L_in_curr_emu_ind = FALSE  AND L_out_currency_code = 'EUR')) then
      ---

      if CURRENCY_SQL.CONVERT_PERM(O_error_message,
                                   I_currency_value,
                                   L_in_currency_code,
                                   L_out_currency_code,
                                   O_currency_value,
                                   I_cost_retail_ind,
                                   I_effective_date,
                                   I_exchange_type,
                                   L_in_exchange_rate,
                                   L_out_exchange_rate) = FALSE then
         return FALSE;
      end if;
      ---
   else
      ---
      if CURRENCY_SQL.CONVERT_EURO(O_error_message,
                                   I_currency_value,
                                   L_in_currency_code,
                                   L_out_currency_code,
                                   O_currency_value,
                                   I_cost_retail_ind,
                                   I_effective_date,
                                   I_exchange_type,
                                   L_in_exchange_rate,
                                   L_out_exchange_rate,
                                   L_in_curr_emu_ind,
                                   L_out_curr_emu_ind) = FALSE then
         return FALSE;
      end if;
      ---
   end if;
   ---

   O_currency_value := ROUND(O_currency_value, 4);
   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
        return FALSE;
END CONVERT;
-------------------------------------------------------------------------------------------
FUNCTION CONVERT (
           O_error_message        IN OUT  VARCHAR2,
           I_currency_value       IN      NUMBER,
           I_currency             IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
           I_currency_out         IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
           O_currency_value       IN OUT  NUMBER,
           I_cost_retail_ind      IN      VARCHAR2,
           I_effective_date       IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE,
           I_exchange_type        IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE)

   return BOOLEAN is

   L_program       VARCHAR2(64)  := 'CURRENCY_SQL.CONVERT';

BEGIN
  if CURRENCY_SQL.CONVERT(O_error_message,
                          I_currency_value,
                          I_currency,
                          I_currency_out,
                          O_currency_value,
                          I_cost_retail_ind,
                          I_effective_date,
                          I_exchange_type,
                          NULL,
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

END CONVERT;
-------------------------------------------------------------------------------------------
FUNCTION ROUND_CURRENCY (O_error_message       IN OUT VARCHAR2,
                         O_currency_value      IN OUT NUMBER,
                         I_currency_out        IN     VARCHAR2,
                         I_cost_retail_ind     IN     VARCHAR2)
        return BOOLEAN IS

   L_program       VARCHAR2(64) := 'CURRENCY_SQL.ROUND_CURRENCY';
   L_round_digits  NUMBER(1);

   L_vdate                DATE := GET_VDATE;
   L_currency_cost_dec    CURRENCIES.CURRENCY_COST_DEC%TYPE;
   L_currency_rtl_dec     CURRENCIES.CURRENCY_RTL_DEC%TYPE;

BEGIN

   if GET_CURR_INFO(O_error_message,
                    L_vdate) = FALSE then
      return FALSE;
   end if;

   --

   if LP_vdate_currency_cache.exists(I_currency_out) then
      L_currency_cost_dec := LP_vdate_currency_cache(I_currency_out).currency_cost_dec;
      L_currency_rtl_dec := LP_vdate_currency_cache(I_currency_out).currency_rtl_dec;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_ROUND_DIGIT',
                                            I_currency_out, NULL, NULL);
      return FALSE;
   end if;

   --

   if I_cost_retail_ind = 'C' then
      L_round_digits := L_currency_cost_dec;
   elsif I_cost_retail_ind in ('R','P') then
      L_round_digits := L_currency_rtl_dec;
   else
      L_round_digits :=  4;
   end if;

   O_currency_value := ROUND(O_currency_value, L_round_digits);

   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
        return FALSE;
END ROUND_CURRENCY;
--------------------------------------------------------------------
FUNCTION GET_CURR_LOC (O_error_message  IN OUT  VARCHAR2,
                       I_location       IN      PARTNER.PARTNER_ID%TYPE,
                       I_location_type  IN      ITEM_LOC.LOC_TYPE%TYPE,
                       I_zone_group_id  IN      PRICE_ZONE.ZONE_GROUP_ID%TYPE,
                       O_currency_code  IN OUT  CURRENCIES.CURRENCY_CODE%TYPE)
        return BOOLEAN IS

   L_program       VARCHAR2(64)  := 'CURRENCY_SQL.GET_CURR_LOC';
   L_cursor        VARCHAR2(20)  := NULL;
   L_error_message VARCHAR2(255) := NULL;
   L_exchange_rate         invc_head.exchange_rate%TYPE;

   cursor C_PARTNER is
      select currency_code
        from partner
       where partner_id = I_location
         and partner_type = I_location_type;

   cursor C_CODE_DECODE is
      select 'x'
        from code_detail
       where code = I_location_type
         and code_type = 'PTAL';

   cursor C_WAREHOUSE is
      select wh.currency_code
        from wh
       where wh.wh = I_location;

   cursor C_STORE is
      select store.currency_code
        from store
       where store.store = I_location;

   cursor C_PRICE_ZONE is
      select price_zone.currency_code
        from price_zone
       where price_zone.zone_id = I_location
         and price_zone.zone_group_id = I_zone_group_id;

   cursor C_SUPPLIER is
      select sups.currency_code
        from sups
       where sups.supplier = I_location;

   cursor C_ORDER is
      select ordhead.currency_code
        from ordhead
       where ordhead.order_no = I_location;

   cursor C_CONTRACT is
      select contract_header.currency_code
        from contract_header
       where contract_header.contract_no = I_location;

   cursor C_COST_ZONE is
      select cost_zone.currency_code
        from cost_zone
       where cost_zone.zone_id       = I_location
         and cost_zone.zone_group_id = I_zone_group_id;

   cursor C_DEAL is
      select currency_code
        from deal_head
       where deal_id = I_location;

BEGIN
   if I_location = '0' or I_location is null then
      if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(L_error_message,
                                          O_currency_code) = FALSE then
         O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                NULL, NULL, NULL);
         return FALSE;
      end if;
   else
      if I_location_type = 'W' then
         if I_location = LP_wh_no then
            O_currency_code := LP_wh_curr_code;
         else
            SQL_LIB.SET_MARK('OPEN', 'C_WAREHOUSE', 'WH', NULL);
            open C_WAREHOUSE;
            SQL_LIB.SET_MARK('FETCH', 'C_WAREHOUSE', 'WH', NULL);
            fetch C_WAREHOUSE into O_currency_code;
            if C_WAREHOUSE%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                      NULL, NULL, NULL);
               SQL_LIB.SET_MARK('CLOSE', 'C_WAREHOUSE', 'WH', NULL);
               close C_WAREHOUSE;
               return FALSE;
            end if;
            SQL_LIB.SET_MARK('CLOSE', 'C_WAREHOUSE', 'WH', NULL);
            close C_WAREHOUSE;

            LP_wh_no := I_location;
            LP_wh_curr_code := O_currency_code;

         end if;
      --External Finishers
      elsif I_location_type = 'E' then
         if I_location = LP_external_finisher then
            O_currency_code := LP_ext_fin_curr_code;
         else
            SQL_LIB.SET_MARK('OPEN', 'C_partner', 'EXTERNAL FINISHER', NULL);
            open C_PARTNER;
            SQL_LIB.SET_MARK('FETCH', 'C_partner', 'EXTERNAL FINISHER', NULL);
            fetch C_PARTNER into O_currency_code;
            if C_PARTNER%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                      NULL, NULL, NULL);
               SQL_LIB.SET_MARK('CLOSE', 'C_PARTNER', 'EXTERNAL FINISHER', NULL);
               close C_PARTNER;
               return FALSE;
            end if;
            SQL_LIB.SET_MARK('CLOSE', 'C_PARTNER', 'EXTERNAL FINISHER', NULL);
            close C_PARTNER;

            LP_external_finisher := I_location;
            LP_ext_fin_curr_code := O_currency_code;
         end if;
      elsif I_location_type = 'S' then
         if I_location = LP_store_no then
            O_currency_code := LP_store_curr_code;
         else
            SQL_LIB.SET_MARK('OPEN', 'C_store', 'STORE', NULL);
            open C_STORE;
            SQL_LIB.SET_MARK('FETCH', 'C_store', 'STORE', NULL);
            fetch C_STORE into O_currency_code;
            if C_STORE%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                      NULL, NULL, NULL);
               SQL_LIB.SET_MARK('CLOSE', 'C_STORE', 'STORE', NULL);
               close C_STORE;
               return FALSE;
            end if;
            SQL_LIB.SET_MARK('CLOSE', 'C_STORE', 'STORE', NULL);
            close C_STORE;

            LP_store_no := I_location;
            LP_store_curr_code := O_currency_code;

         end if;
      elsif I_location_type = 'Z' then

         if I_location = LP_zone_id AND I_zone_group_id = LP_zone_group_id then
            O_currency_code := LP_zone_curr_code;
         else
            SQL_LIB.SET_MARK('OPEN', 'C_PRICE_ZONE', 'PRICE_ZONE', NULL);
            open C_PRICE_ZONE;
            SQL_LIB.SET_MARK('FETCH', 'C_PRICE_ZONE', 'PRICE_ZONE', NULL);
            fetch C_PRICE_ZONE into O_currency_code;
            if C_PRICE_ZONE%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                      NULL, NULL, NULL);
               SQL_LIB.SET_MARK('CLOSE', 'C_PRICE_ZONE', 'PRICE_ZONE', NULL);
               close C_PRICE_ZONE;
               return FALSE;
            end if;
            SQL_LIB.SET_MARK('CLOSE', 'C_PRICE_ZONE', 'PRICE_ZONE', NULL);
            close C_PRICE_ZONE;

            LP_zone_group_id := I_zone_group_id;
            LP_zone_id  := I_location;
            LP_zone_curr_code := O_currency_code;

         end if;
      elsif I_location_type = 'V' then
         if I_location = LP_supplier then
            O_currency_code := LP_supplier_curr_code;
         else
            SQL_LIB.SET_MARK('OPEN', 'C_SUPPLIER', 'SUPS', NULL);
            open C_SUPPLIER;
            SQL_LIB.SET_MARK('FETCH', 'C_SUPPLIER', 'SUPS', NULL);
            fetch C_SUPPLIER into O_currency_code;
            if C_SUPPLIER%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                       NULL, NULL, NULL);
               SQL_LIB.SET_MARK('CLOSE', 'C_SUPPLIER', 'SUPS', NULL);
               close C_SUPPLIER;
               return FALSE;
            end if;
            SQL_LIB.SET_MARK('CLOSE', 'C_SUPPLIER', 'SUPS', NULL);
            close C_SUPPLIER;

            LP_supplier  := I_location;
            LP_supplier_curr_code := O_currency_code;

         end if;
      elsif I_location_type = 'O' then
         if I_location = LP_order_no then
            O_currency_code := LP_order_curr_code;
         else
            SQL_LIB.SET_MARK('OPEN', 'C_ORDER', 'ORDHEAD', NULL);
            open C_ORDER;
            SQL_LIB.SET_MARK('FETCH', 'C_ORDER', 'ORDHEAD', NULL);
            fetch C_ORDER into O_currency_code;
            if C_ORDER%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                      NULL, NULL, NULL);
               SQL_LIB.SET_MARK('CLOSE', 'C_ORDER', 'ORDHEAD', NULL);
               close C_ORDER;
               return FALSE;
            end if;
            SQL_LIB.SET_MARK('CLOSE', 'C_ORDER', 'ORDHEAD', NULL);
            close C_ORDER;

            LP_order_no := I_location;
            LP_order_curr_code := O_currency_code;

         end if;

      elsif I_location_type = 'I' then
         ---
         if INVC_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                              O_currency_code,
                                              L_exchange_rate,
                                              I_location) = FALSE then
            return FALSE;
         end if;
         ---
      elsif I_location_type = 'C' then
         SQL_LIB.SET_MARK('OPEN', 'C_CONTRACT', 'CONTRACT_HEADER', NULL);
         open C_CONTRACT;
         SQL_LIB.SET_MARK('FETCH', 'C_CONTRACT', 'CONTRACT_HEADER', NULL);
         fetch C_CONTRACT into O_currency_code;
         if C_CONTRACT%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                  NULL, NULL, NULL);
            SQL_LIB.SET_MARK('CLOSE', 'C_CONTRACT', 'CONTRACT_HEADER', NULL);
            close C_CONTRACT;
            return FALSE;
         end if;
         SQL_LIB.SET_MARK('CLOSE', 'C_CONTRACT', 'CONTRACT_HEADER', NULL);
         close C_CONTRACT;
      elsif I_location_type = 'L' then
         SQL_LIB.SET_MARK('OPEN', 'C_COST_ZONE', 'COST_ZONE', NULL);
         open C_COST_ZONE;
         SQL_LIB.SET_MARK('FETCH', 'C_COST_ZONE', 'COST_ZONE', NULL);
         fetch C_COST_ZONE into O_currency_code;
         if C_COST_ZONE%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                   NULL, NULL, NULL);
            SQL_LIB.SET_MARK('CLOSE','C_COST_ZONE', 'COST_ZONE' , NULL);
            close C_COST_ZONE;
            return FALSE;
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_COST_ZONE', 'COST_ZONE' , NULL);
         close C_COST_ZONE;
      elsif I_location_type = 'D' then
         SQL_LIB.SET_MARK('OPEN', 'C_DEAL', 'DEAL_HEAD', 'DEAL: '||I_location);
         open C_DEAL;
         SQL_LIB.SET_MARK('FETCH', 'C_DEAL', 'DEAL_HEAD', 'DEAL: '||I_location);
         fetch C_DEAL into O_currency_code;
         ---
         if C_DEAL%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                   NULL, NULL, NULL);
            SQL_LIB.SET_MARK('CLOSE', 'C_DEAL', 'DEAL_HEAD', 'DEAL: '||I_location);
            close C_DEAL;
            return FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_DEAL', 'DEAL_HEAD', 'DEAL: '||I_location);
         close C_DEAL;
      else
         SQL_LIB.SET_MARK('OPEN', 'C_CODE_DECODE', 'CODE_DETAIL', NULL);
         open C_CODE_DECODE;
         SQL_LIB.SET_MARK('FETCH', 'C_CODE_DECODE', 'CODE_DETAIL', NULL);
         fetch C_CODE_DECODE into O_currency_code;
         if C_CODE_DECODE%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('ERROR_CURR_LOCATION',
                                                   NULL, NULL, NULL);
            SQL_LIB.SET_MARK('CLOSE', 'C_CODE_DECODE', 'CODE_DETAIL', NULL);
            close C_CODE_DECODE;
            return FALSE;
         end if;
         SQL_LIB.SET_MARK('CLOSE', 'C_CODE_DECODE', 'CODE_DETAIL', NULL);
         close C_CODE_DECODE;

         SQL_LIB.SET_MARK('OPEN', 'C_PARTNER', 'PARTNER', NULL);
         open C_PARTNER;
         SQL_LIB.SET_MARK('FETCH', 'C_PARTNER', 'PARTNER', NULL);
         fetch C_PARTNER into O_currency_code;
         if C_PARTNER%NOTFOUND then
            SQL_LIB.SET_MARK('CLOSE', 'C_PARTNER', 'PARTNER', NULL);
            close C_PARTNER;
            O_error_message := SQL_LIB.CREATE_MSG('INV_CURRENCY',
                                                   NULL, NULL, NULL);
            return FALSE;
         end if;
         SQL_LIB.SET_MARK('CLOSE', 'C_PARTNER', 'PARTNER', NULL);
         close C_PARTNER;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
        return FALSE;
END GET_CURR_LOC;
-------------------------------------------------------------------
FUNCTION EXIST(O_error_message   IN OUT      VARCHAR2,
                 I_currency_code IN          CURRENCIES.CURRENCY_CODE%TYPE,
               O_exists          IN OUT      BOOLEAN)
        return BOOLEAN IS

   L_program            VARCHAR2(64)  := 'CURRENCY_SQL.EXIST';
   L_vdate              DATE := GET_VDATE;

BEGIN

   if GET_CURR_INFO(O_error_message,
                    L_vdate) = FALSE then
      return FALSE;
   end if;

   --

   if LP_vdate_currency_cache.exists(I_currency_code) then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
        return FALSE;
END EXIST;
-------------------------------------------------------------------------------------------
FUNCTION CHECK_EMU_COUNTRIES(O_error_message       IN OUT VARCHAR2,
                             O_participating_ind   IN OUT BOOLEAN,
                             I_currency            IN     system_options.currency_code%TYPE)
    RETURN BOOLEAN IS

   L_vdate                DATE := GET_VDATE;
   L_euro_exchange_rate   EURO_EXCHANGE_RATE.EXCHANGE_RATE%TYPE;

BEGIN

   if GET_CURR_INFO(O_error_message,
                    L_vdate) = FALSE then
      return FALSE;
   end if;

   --

   if LP_vdate_currency_cache.exists(I_currency) then
      L_euro_exchange_rate := LP_vdate_currency_cache(I_currency).euro_ex_rate;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_CURR_CURR', I_currency, null, null);
      return FALSE;
   end if;

   --

   if L_euro_exchange_rate is null then
      O_participating_ind := FALSE;
   else
      O_participating_ind := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               'CURRENCY_SQL.CHECK_EMU_COUNTRIES',
                                               to_char(SQLCODE));
        return FALSE;
END CHECK_EMU_COUNTRIES;
----------------------------------------------------------------------------------
FUNCTION CHECK_EMU_COUNTRIES(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_participating_ind   IN OUT BOOLEAN,
                             I_currency            IN     system_options.currency_code%TYPE,
                             I_effective_date      IN     DATE)
    RETURN BOOLEAN IS

L_program               VARCHAR2(100) := 'CURRENCY_SQL.CHECK_EMU_COUNTRIES';
L_vdate                 DATE := GET_VDATE;
L_get_vdate_curr_info   BOOLEAN := FALSE;
L_get_curr_info         BOOLEAN := FALSE;
L_euro_exchange_rate   EURO_EXCHANGE_RATE.EXCHANGE_RATE%TYPE;

cursor C_CURRENCY(I_date DATE) is
select /*+ INDEX(c,PK_CURRENCIES) INDEX(cr, PK_CURRENCY_RATES) INDEX(eer,PK_EURO_EXCHANGE_RATE) */  distinct c.currency_code,
       c.currency_desc,
       c.currency_cost_fmt,
       c.currency_rtl_fmt,
       c.currency_cost_dec,
       c.currency_rtl_dec,
       --
       first_value(cr.exchange_rate) over
       (partition by c.currency_code, cr.exchange_type order by cr.effective_date desc) exchange_rate,
       cr.exchange_type,
       --
       eer.exchange_rate euro_ex_rate
  from currencies c,
       currency_rates cr,
       euro_exchange_rate eer
 where eer.currency_code (+) = c.currency_code
   --
   and cr.effective_date (+) <= I_date
   and cr.currency_code (+) = c.currency_code;

BEGIN

   if LP_vdate_currency_cache_date is null then
      L_get_vdate_curr_info := TRUE;
   else
      if LP_vdate_currency_cache_date = L_vdate then
         L_get_vdate_curr_info := TRUE;
      end if;
   end if;

   if LP_currency_cache_date is null then
      if I_effective_date != L_vdate then
         L_get_curr_info := TRUE;
      end if;
   else
      if LP_currency_cache_date = I_effective_date then
         L_get_curr_info := TRUE;
      end if;
   end if;

   if L_get_vdate_curr_info then
      LP_vdate_currency_cache.delete;
      for rec in C_CURRENCY(L_vdate) loop
         if not LP_vdate_currency_cache.exists(rec.currency_code) then
            LP_vdate_currency_cache(rec.currency_code).currency_desc := rec.currency_desc;
            LP_vdate_currency_cache(rec.currency_code).currency_cost_fmt := rec.currency_cost_fmt;
            LP_vdate_currency_cache(rec.currency_code).currency_rtl_fmt := rec.currency_rtl_fmt;
            LP_vdate_currency_cache(rec.currency_code).currency_cost_dec := rec.currency_cost_dec;
            LP_vdate_currency_cache(rec.currency_code).currency_rtl_dec := rec.currency_rtl_dec;
            LP_vdate_currency_cache(rec.currency_code).euro_ex_rate := rec.euro_ex_rate;
         end if;
         --
         if rec.exchange_type is not null then
            LP_vdate_currency_cache(rec.currency_code).rate_tbl(rec.exchange_type).exchange_rate := rec.exchange_rate;
         end if;
      end loop;
      LP_vdate_currency_cache_date := L_vdate;
   end if;

   if L_get_curr_info then
      LP_currency_cache.delete;
      for rec in C_CURRENCY(I_effective_date) loop
         if not LP_currency_cache.exists(rec.currency_code) then
            LP_currency_cache(rec.currency_code).currency_desc := rec.currency_desc;
            LP_currency_cache(rec.currency_code).currency_cost_fmt := rec.currency_cost_fmt;
            LP_currency_cache(rec.currency_code).currency_rtl_fmt := rec.currency_rtl_fmt;
            LP_currency_cache(rec.currency_code).currency_cost_dec := rec.currency_cost_dec;
            LP_currency_cache(rec.currency_code).currency_rtl_dec := rec.currency_rtl_dec;
            LP_currency_cache(rec.currency_code).euro_ex_rate := rec.euro_ex_rate;
         end if;
         --
         if rec.exchange_type is not null then
            LP_currency_cache(rec.currency_code).rate_tbl(rec.exchange_type).exchange_rate := rec.exchange_rate;
         end if;
      end loop;
      LP_currency_cache_date := I_effective_date;
   end if;

   --

   if LP_vdate_currency_cache.exists(I_currency) then
      L_euro_exchange_rate := LP_vdate_currency_cache(I_currency).euro_ex_rate;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_CURR_CURR', I_currency, null, null);
      return FALSE;
   end if;

   --

   if L_euro_exchange_rate is null then
      O_participating_ind := FALSE;
   else
      O_participating_ind := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               'CURRENCY_SQL.CHECK_EMU_COUNTRIES',
                                               to_char(SQLCODE));
        return FALSE;
END CHECK_EMU_COUNTRIES;
----------------------------------------------------------------------------------
FUNCTION CONVERT_VALUE(I_cost_retail_ind IN      VARCHAR2,
                       I_currency_out    IN      CURRENCIES.CURRENCY_CODE%TYPE,
                       I_currency_in     IN      CURRENCIES.CURRENCY_CODE%TYPE,
                       I_currency_value  IN      NUMBER)
   RETURN NUMBER IS

   L_error_message     RTK_ERRORS.RTK_TEXT%TYPE;
   L_currency_out      NUMBER;

BEGIN

   if CURRENCY_SQL.CONVERT(L_error_message,
                           I_currency_value,
                           I_currency_in,
                           I_currency_out,
                           L_currency_out,
                           I_cost_retail_ind,
                           NULL,    -- Effective date
                           NULL) = FALSE then
      raise_application_error(-20000, 'Currency conversion error');
   end if;

   return L_currency_out;

EXCEPTION
   when OTHERS then
      raise;

END CONVERT_VALUE;

--------------------------------------------------------------------------------
--                          PRIVATE PROCEDURES                                --
--------------------------------------------------------------------------------

FUNCTION GET_EURO_CURR_EXCHG_RATE(O_error_message  IN OUT VARCHAR2,
                                  I_currency_code  IN     CURRENCIES.CURRENCY_CODE%TYPE,
                                  O_exchange_rate     OUT CURRENCY_RATES.EXCHANGE_RATE%TYPE)
RETURN BOOLEAN IS

L_program   VARCHAR2(100) := 'CURRENCY_SQL.GET_EURO_CURR_EXCHG_RATE';
L_vdate     DATE := GET_VDATE;

BEGIN

   if GET_CURR_INFO(O_error_message,
                    L_vdate) = FALSE then
      return FALSE;
   end if;

   --

   if LP_vdate_currency_cache.exists(I_currency_code) then
      if LP_vdate_currency_cache(I_currency_code).euro_ex_rate is null then
         O_error_message := SQL_LIB.CREATE_MSG('INV_CURR_CURR', I_currency_code, null, null);
         return FALSE;
      end if;
      O_exchange_rate := LP_vdate_currency_cache(I_currency_code).euro_ex_rate;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_CURR_CURR', I_currency_code, null, null);
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

END GET_EURO_CURR_EXCHG_RATE;
--------------------------------------------------------------------------------

FUNCTION GET_CURR_EXCHG_RATE(O_error_message  IN OUT VARCHAR2,
                             I_currency_code  IN     CURRENCIES.CURRENCY_CODE%TYPE,
                             I_effective_date IN     DATE,
                             I_exchange_type  IN     CURRENCY_RATES.EXCHANGE_TYPE%TYPE,
                             O_exchange_rate     OUT CURRENCY_RATES.EXCHANGE_RATE%TYPE)
RETURN BOOLEAN IS

L_program   VARCHAR2(100) := 'CURRENCY_SQL.GET_CURR_EXCHG_RATE';

BEGIN

   if GET_CURR_INFO(O_error_message,
                    I_effective_date) = FALSE then
      return FALSE;
   end if;

   --

   O_exchange_rate := null;

   if I_effective_date = LP_vdate_currency_cache_date then
      if LP_vdate_currency_cache.exists(I_currency_code) then
         if LP_vdate_currency_cache(I_currency_code).rate_tbl.exists(I_exchange_type) then
            O_exchange_rate := LP_vdate_currency_cache(I_currency_code).rate_tbl(I_exchange_type).exchange_rate;
         end if;
      end if;
   elsif I_effective_date = LP_currency_cache_date then
      if LP_currency_cache.exists(I_currency_code) then
         if LP_currency_cache(I_currency_code).rate_tbl.exists(I_exchange_type) then
            O_exchange_rate := LP_currency_cache(I_currency_code).rate_tbl(I_exchange_type).exchange_rate;
         end if;
      end if;
   end if;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_CURR_EXCHG_RATE;
--------------------------------------------------------------------------------

FUNCTION GET_CURR_INFO(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       I_effective_date IN     DATE)
RETURN BOOLEAN IS

L_program               VARCHAR2(100) := 'CURRENCY_SQL.GET_CURR_INFO';
L_vdate                 DATE := GET_VDATE;
L_get_vdate_curr_info   BOOLEAN := FALSE;
L_get_curr_info         BOOLEAN := FALSE;

cursor C_CURRENCY(I_date DATE) is
select /*+ INDEX(c,PK_CURRENCIES) INDEX(cr, PK_CURRENCY_RATES) INDEX(eer,PK_EURO_EXCHANGE_RATE) */  distinct c.currency_code,
       c.currency_desc,
       c.currency_cost_fmt,
       c.currency_rtl_fmt,
       c.currency_cost_dec,
       c.currency_rtl_dec,
       --
       first_value(cr.exchange_rate) over
       (partition by c.currency_code, cr.exchange_type order by cr.effective_date desc) exchange_rate,
       cr.exchange_type,
       --
       eer.exchange_rate euro_ex_rate
  from currencies c,
       currency_rates cr,
       euro_exchange_rate eer
 where eer.currency_code (+) = c.currency_code
   --
   and cr.effective_date (+) <= I_date
   and cr.currency_code (+) = c.currency_code;

BEGIN

   --Applied change for SR 5916118.992 back port, Gareth Jones, as requested by performance test.
   if LP_vdate_currency_cache_date is null then
      L_get_vdate_curr_info := TRUE;
   else
      if LP_vdate_currency_cache_date != L_vdate then
         L_get_vdate_curr_info := TRUE;
      end if;
   end if;

   if LP_currency_cache_date is null then
      if I_effective_date != L_vdate then
         L_get_curr_info := TRUE;
      end if;
   else
      if LP_currency_cache_date != I_effective_date then
         L_get_curr_info := TRUE;
      end if;
   end if;

   if L_get_vdate_curr_info then
      LP_vdate_currency_cache.delete;
      for rec in C_CURRENCY(L_vdate) loop
         if not LP_vdate_currency_cache.exists(rec.currency_code) then
            LP_vdate_currency_cache(rec.currency_code).currency_desc := rec.currency_desc;
            LP_vdate_currency_cache(rec.currency_code).currency_cost_fmt := rec.currency_cost_fmt;
            LP_vdate_currency_cache(rec.currency_code).currency_rtl_fmt := rec.currency_rtl_fmt;
            LP_vdate_currency_cache(rec.currency_code).currency_cost_dec := rec.currency_cost_dec;
            LP_vdate_currency_cache(rec.currency_code).currency_rtl_dec := rec.currency_rtl_dec;
            LP_vdate_currency_cache(rec.currency_code).euro_ex_rate := rec.euro_ex_rate;
         end if;
         --
         if rec.exchange_type is not null then
            LP_vdate_currency_cache(rec.currency_code).rate_tbl(rec.exchange_type).exchange_rate := rec.exchange_rate;
         end if;
      end loop;
      LP_vdate_currency_cache_date := L_vdate;
   end if;

   if L_get_curr_info then
      LP_currency_cache.delete;
      for rec in C_CURRENCY(I_effective_date) loop
         if not LP_currency_cache.exists(rec.currency_code) then
            LP_currency_cache(rec.currency_code).currency_desc := rec.currency_desc;
            LP_currency_cache(rec.currency_code).currency_cost_fmt := rec.currency_cost_fmt;
            LP_currency_cache(rec.currency_code).currency_rtl_fmt := rec.currency_rtl_fmt;
            LP_currency_cache(rec.currency_code).currency_cost_dec := rec.currency_cost_dec;
            LP_currency_cache(rec.currency_code).currency_rtl_dec := rec.currency_rtl_dec;
            LP_currency_cache(rec.currency_code).euro_ex_rate := rec.euro_ex_rate;
         end if;
         --
         if rec.exchange_type is not null then
            LP_currency_cache(rec.currency_code).rate_tbl(rec.exchange_type).exchange_rate := rec.exchange_rate;
         end if;
      end loop;
      LP_currency_cache_date := I_effective_date;
   end if;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_CURR_INFO;
--------------------------------------------------------------------------------

END CURRENCY_SQL;
/

