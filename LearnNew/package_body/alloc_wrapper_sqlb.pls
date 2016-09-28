CREATE OR REPLACE PACKAGE BODY ALLOC_WRAPPER_SQL IS
----------------------------------------------------------------------
FUNCTION DELETE_CHRGS(O_error_message IN OUT VARCHAR2,
                      I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                      I_to_loc        IN     ITEM_LOC.LOC%TYPE)
RETURN NUMBER IS
BEGIN
  if ALLOC_CHARGE_SQL.DELETE_CHRGS(O_error_message,
                                   I_alloc_no,
                                   I_to_loc) = FALSE THEN
    return 0;
  else
    return 1;
  end if;

EXCEPTION
  when OTHERS then
     O_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.DELETE_CHRGS.';
     return 0;
END DELETE_CHRGS;
----------------------------------------------------------------------
FUNCTION DEFAULT_CHRGS(O_error_message IN OUT VARCHAR2,
                       I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                       I_from_loc      IN     STORE.STORE%TYPE,
                       I_to_loc        IN     STORE.STORE%TYPE,
                       I_to_loc_type   IN     ITEM_LOC.LOC_TYPE%TYPE,
                       I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN NUMBER IS
BEGIN
  if ALLOC_CHARGE_SQL.DEFAULT_CHRGS(O_error_message,
                                    I_alloc_no,
                                    I_from_loc,
                                    I_to_loc,
                                    I_to_loc_type,
                                    I_item) = FALSE THEN
    return 0;
  else
    return 1;
  end if;

EXCEPTION
  when OTHERS then
     O_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.DEFAULT_CHRGS.'||O_error_message;
     return 0;
END DEFAULT_CHRGS;
----------------------------------------------------------------------
FUNCTION DEFAULT_CHRGS_BATCH(O_error_message IN OUT VARCHAR2
                       )
RETURN NUMBER IS
   L_ins_count      NUMBER   := 0;
BEGIN
  FOR crec IN (SELECT * FROM ALC_DEFAULT_CHRGS_TEMP) LOOP
	  if ALLOC_CHARGE_SQL.DEFAULT_CHRGS(O_error_message,
                                    crec.alloc_no,
                                    crec.from_loc,
                                    crec.to_loc,
                                    crec.to_loc_type,
                                    crec.item) = FALSE THEN
      return 0;
    else
       L_ins_count := L_ins_count + 1 ;
    end if;
  END LOOP ;
  return L_ins_count ;
EXCEPTION
  when OTHERS then
     O_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.DEFAULT_CHRGS.'||O_error_message;
     return 0;
END DEFAULT_CHRGS_BATCH;
----------------------------------------------------------------------
FUNCTION UPD_ALLOC_RESV_EXP(O_error_message   IN OUT  VARCHAR2,
                            I_alloc_no        IN      ALLOC_HEADER.ALLOC_NO%TYPE,
                            I_add_delete_ind  IN      VARCHAR2)
RETURN NUMBER IS
BEGIN
  if ALLOC_ATTRIB_SQL.UPD_ALLOC_RESV_EXP(O_error_message,
                                         I_alloc_no,
                                         I_add_delete_ind) = FALSE THEN
    return 0;
  else
    return 1;
  end if;

EXCEPTION
  when OTHERS then
     O_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.UPD_ALLOC_RESV_EXP.';
     return 0;
END UPD_ALLOC_RESV_EXP;
----------------------------------------------------------------------
FUNCTION GET_WH_CURRENT_AVAIL(I_item   IN item_master.item%TYPE,
                              I_color  IN item_master.item%TYPE,
                              I_wh     IN item_loc.LOC%TYPE) RETURN item_loc_soh.STOCK_ON_HAND%TYPE IS

   ABORTING               EXCEPTION;
   L_available      NUMBER(20,4)   := 0;
   L_error_message  VARCHAR2(255)  := NULL;


BEGIN
   if I_wh is NOT NULL and I_item is NOT NULL then
      if not ITEMLOC_QUANTITY_SQL.GET_LOC_CURRENT_AVAIL(L_error_message,
                                                        L_available,
                                                        I_item,
                                                        I_wh,
                                                        'W') then
        L_available := -99999999.9999;
      end if;
   end if;

   return L_available;

   EXCEPTION
  when ABORTING then
      return -99999999.9999;
  when OTHERS then
     L_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.GET_WH_CURRENT_AVAIL.'||L_error_message;
     return -99999999.9999;
END GET_WH_CURRENT_AVAIL;
--------------------------------------------------------------------
FUNCTION GET_WH_TOTAL_DIST_QTY(I_item  IN item_master.item%TYPE,
                               I_wh    IN item_loc.LOC%TYPE,
                               I_date  IN DATE) RETURN item_loc_soh.STOCK_ON_HAND%TYPE IS

   ABORTING               EXCEPTION;
   L_available      NUMBER(20,4)   := 0;
   L_error_message  VARCHAR2(255)  := NULL;


BEGIN
   if I_wh is NOT NULL and I_item is NOT NULL then
      if not ITEMLOC_QUANTITY_SQL.GET_TOTAL_DIST_QTY(L_error_message,
                                                     L_available,
                                                     I_item,
                                                     I_wh,
                                                     'W',
                                                     I_date) then
        L_available := -99999999.9999;
      end if;
   end if;

   return L_available;

   EXCEPTION
  when ABORTING then
      return -99999999.9999;
  when OTHERS then
     L_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.GET_WH_CURRENT_AVAIL.';
     return -99999999.9999;
END GET_WH_TOTAL_DIST_QTY;
--------------------------------------------------------------------
FUNCTION INSERT_NEW_ITEM_LOC(O_error_message    IN OUT VARCHAR2,
                             I_item             IN item_loc.item%TYPE,
                             I_location         IN item_loc.loc%TYPE,
                             I_loc_type     IN item_loc.loc_type%TYPE) RETURN NUMBER IS

   ABORTING               EXCEPTION;
   L_available      NUMBER(20,4)   := 1;

BEGIN

   if I_item is NOT NULL then
      if not NEW_ITEM_LOC(O_error_message,
                          I_item,
                          I_location,
                          null,
                          null,
                          I_loc_type,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          TRUE) then
           L_available := 0;
      end if;
   end if;

   return L_available;

   EXCEPTION
   when ABORTING then
      return 0;
  when OTHERS then
     O_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.INSERT_NEW_ITEM_LOC.';
     return 0;

END INSERT_NEW_ITEM_LOC;
--------------------------------------------------------------------
FUNCTION GET_LOC_FUTURE_AVAIL(I_item           IN     item_loc.item%TYPE,
                              I_loc            IN     item_loc.loc%TYPE,
                              I_loc_type       IN     item_loc.loc_type%TYPE,
                              I_date           IN     DATE,
                              I_all_orders     IN     VARCHAR2) RETURN item_loc_soh.STOCK_ON_HAND%TYPE IS

   ABORTING               EXCEPTION;
   L_available      NUMBER(20,4)   := 0;
   L_error_message  VARCHAR2(255)  := NULL;


BEGIN
   if I_loc_type is NOT NULL and I_loc is NOT NULL and I_item is NOT NULL then
      if not ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL(L_error_message,
                                                       L_available,
                                                       I_item,
                                                       I_loc,
                                                       I_loc_type,
                                                       I_date,
                                                       I_all_orders) then
        L_available := -99999999.9999;
      end if;
   end if;

   return L_available;

   EXCEPTION
  when ABORTING then
      return -99999999.9999;
  when OTHERS then
     L_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.GET_LOC_FUTURE_AVAIL.'||L_error_message;
     return -99999999.9999;
END GET_LOC_FUTURE_AVAIL;

--------------------------------------------------------------------
FUNCTION GET_EXCHANGE_RATE (O_error_message  IN OUT  VARCHAR2,
                            I_currency_code  IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                            I_exchange_type  IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE,
                            I_effective_date IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE) RETURN NUMBER IS

   ABORTING         EXCEPTION;
   L_exchange_rate  CURRENCY_RATES.EXCHANGE_RATE%TYPE;

BEGIN

   if CURRENCY_SQL.GET_RATE(O_error_message,
                            L_exchange_rate,
                            I_currency_code,
                            I_exchange_type,
                            I_effective_date) = FALSE then
      L_exchange_rate :=-99999999.9999;
   end if;

   return L_exchange_rate;

EXCEPTION
  when ABORTING then
      return -99999999.9999;
  when OTHERS then
     O_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.GET_EXCHANGE_RATE. ';
     return -99999999.9999;
END GET_EXCHANGE_RATE;
--------------------------------------------------------------------
FUNCTION VALIDATE_ORD_LOC  (O_error_message IN OUT VARCHAR2,
                            I_item          IN     ITEM_MASTER.ITEM%TYPE,
                            I_loc           IN     STORE.STORE%TYPE) RETURN NUMBER IS

   ABORTING         EXCEPTION;
   L_cost_zone_id        COST_ZONE.ZONE_ID%TYPE;
   L_cost_zone_group_id  COST_ZONE.ZONE_GROUP_ID%TYPE;

BEGIN
   --get cost_zone_group_id for the item
   if ITEM_ATTRIB_SQL.GET_COST_ZONE_GROUP(O_error_message,
                                          L_cost_zone_group_id,
                                          I_item) = FALSE then
      return -1;
   end if;

   --verify that cost zone info for the item/location is valid
   if ITEM_ATTRIB_SQL.GET_COST_ZONE(O_error_message,
                                    L_cost_zone_id,
                                    I_item,
                                    L_cost_zone_group_id,
                                    I_loc) = FALSE then
      return -2;
   end if;

   -- if no cost_zone_id is found, then the item/location is invalid
   if L_cost_zone_id < 0 then
      return -3;
   end if;

   return 1;

EXCEPTION
  when ABORTING then
      return -4;
  when OTHERS then
     O_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.VALIDATE_ORD_LOC. '||O_error_message;
     return -5;
END VALIDATE_ORD_LOC;
--------------------------------------------------------------------

-----------------------------------------------------------------
FUNCTION CONVERT_UOM (O_error_message IN OUT VARCHAR2,
                      O_to_value IN OUT NUMBER,
					  I_to_uom         IN     UOM_CONVERSION.TO_UOM%TYPE,
					  I_from_value     IN     NUMBER,
                      I_from_uom       IN     UOM_CONVERSION.FROM_UOM%TYPE,
                       I_item           IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                      I_supplier       IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                     I_origin_country IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
		RETURN NUMBER
IS
BEGIN

   if UOM_SQL.CONVERT(O_error_message,
                      O_to_value,
                 	  I_to_uom,
                 	  I_from_value,
                 	  I_from_uom,
                 	  I_item,
                 	  I_supplier,
                 	  I_origin_country) = FALSE then
      return -1;
   end if;


   return 0;

EXCEPTION
  when OTHERS then
     O_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.CONVERT_UOM. '||O_error_message;
	 return -1;
END CONVERT_UOM;

----------------------------------------------------------------------------------

FUNCTION CONVERT_CURRENCY (O_error_message        IN OUT  VARCHAR2,
                  I_currency_value       IN      NUMBER,
                  I_currency             IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                  I_currency_out         IN      CURRENCY_RATES.CURRENCY_CODE%TYPE,
                  O_currency_value       IN OUT  NUMBER,
                  I_cost_retail_ind      IN      VARCHAR2,
                  I_effective_date       IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE,
                  I_exchange_type        IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE,
                  I_in_exchange_rate     IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE,
                  I_out_exchange_rate    IN      CURRENCY_RATES.EXCHANGE_RATE%TYPE)
	RETURN NUMBER
IS
BEGIN
    if CURRENCY_SQL.CONVERT(O_error_message,
	                   I_currency_value,
					   I_currency,
                       I_currency_out,
                  	   O_currency_value,
					   I_cost_retail_ind,
                       I_effective_date,
                       I_exchange_type,
                       I_in_exchange_rate,
                       I_out_exchange_rate) = FALSE then
      return -1;
   end if;


   return 0;

EXCEPTION
  when OTHERS then
     O_error_message := SQLERRM ||' from ALLOC_WRAPPER_SQL.CONVERT_CURRENCY '||O_error_message;
	 return -1;

END CONVERT_CURRENCY;
--------------------------------------------------------------------

FUNCTION GET_PACK_CURRENT_UNIT_RETAIL (I_location      IN     ITEM_LOC.LOC%TYPE,
                                       I_loc_type      IN     ITEM_LOC.LOC_TYPE%TYPE,
                                       I_item          IN     ITEM_MASTER.ITEM%TYPE) RETURN ITEM_LOC.UNIT_RETAIL%TYPE IS

   ABORTING         EXCEPTION;
   L_error_message  VARCHAR2(200);
   L_unit_retail    ITEM_LOC.UNIT_RETAIL%TYPE;

BEGIN

   if PRICING_ATTRIB_SQL.BUILD_PACK_RETAIL (L_error_message,
                                            L_unit_retail,
                                            I_item,
                                            I_loc_type,
                                            I_location) = FALSE then
      return -1;
   end if;

   return L_unit_retail;

EXCEPTION
  when ABORTING then
      return -1;
  when OTHERS then
     L_error_message := SQLERRM || ' from ALLOC_WRAPPER_SQL.GET_PACK_CURRENT_UNIT_RETAIL. '||L_error_message;
     return -2;
END GET_PACK_CURRENT_UNIT_RETAIL;
--------------------------------------------------------------------

END ALLOC_WRAPPER_SQL;
/

