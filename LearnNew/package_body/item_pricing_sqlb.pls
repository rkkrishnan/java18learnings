CREATE OR REPLACE PACKAGE BODY ITEM_PRICING_SQL AS
-------------------------------------------------------------------------
FUNCTION GET_BASE_RETAIL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_base_retail     IN OUT   item_zone_price.unit_retail%TYPE,
                         I_item            IN       item_zone_price.item%TYPE)
RETURN BOOLEAN IS

   L_program             VARCHAR2(64) := 'ITEM_PRICING_SQL.GET_BASE_RETAIL';
   L_zone_group_id       ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE;
   L_zone_id             ITEM_ZONE_PRICE.ZONE_ID%TYPE;
   L_unit_retail_prim    ITEM_LOC.UNIT_RETAIL%TYPE;
   L_stand_uom           ITEM_LOC.SELLING_UOM%TYPE;
   L_multi_units         ITEM_LOC.MULTI_UNITS%TYPE;
   L_multi_unit_retail   ITEM_LOC.MULTI_UNIT_RETAIL%TYPE;
   L_multi_selling_uom   ITEM_LOC.MULTI_SELLING_UOM%TYPE;
   L_selling_unit_retail ITEM_LOC.SELLING_UNIT_RETAIL%TYPE;
   L_selling_uom         ITEM_LOC.SELLING_UOM%TYPE;
BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_id',
                                            'NULL',
                                            'ID');
      return FALSE;
   end if;

   if PRICING_ATTRIB_SQL.GET_BASE_ZONE_RETAIL(O_error_message,
                                              L_zone_group_id,
                                              L_zone_id,
                                              O_base_retail, -- O_unit_retail_zone
                                              L_stand_uom,
                                              L_selling_unit_retail,
                                              L_selling_uom,
                                              L_multi_units,
                                              L_multi_unit_retail,
                                              L_multi_selling_uom,
                                              I_item) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END GET_BASE_RETAIL;
-------------------------------------------------------------------------
END ITEM_PRICING_SQL;
/

