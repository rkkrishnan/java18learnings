CREATE OR REPLACE PACKAGE BODY CATCH_WEIGHT_SQL AS
-----------------------------------------------------------------------------------------------------
--Mod By:      Murali Krishnan
--Mod Date:    23-Oct-2008
--Mod Ref:     Back Port Oracle fix(6732427,6907185)
--Mod Details: Back ported the oracle fix for Bug 6732427,6907185.Modified the functions PRORATE_WEIGHT,
--             CALC_TOTAL_COST.Added functions CALC_TOTAL_RETAIL,POST_WEIGHT_VARIANCE
---------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 06-Jan-2009
-- Def Ref    : PrfNBS010460 and NBS00010460
-- Def Details: Code has modified for performance related issues in RIB.
---------------------------------------------------------------------------------------------
-- Sir          : SirNBS6160979T
-- Sir Fit By   : Barney Clough
-- Sir Fit Date : 29-May-2008
-- Type         : Retro-fit Sir for NBS from V1205 to V1202T
-- Function     : Modify CONVERT_WEIGHT
-- Purpose      : Refer to defect documentation.
---------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 21-Jan-2009
-- Def Ref    : MrgNBS010972
-- Def Details: 3.3a to 3.3b merge
---------------------------------------------------------------------------------------------
FUNCTION CALC_AV_COST_CATCH_WEIGHT(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_new_av_cost     IN OUT  ITEM_LOC_SOH.AV_COST%TYPE,
                                   I_soh_curr        IN      ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                                   I_av_cost_curr    IN      ITEM_LOC_SOH.AV_COST%TYPE,
                                   I_qty             IN      ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                                   I_total_cost      IN      ORDLOC.UNIT_COST%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'CATCH_WEIGHT_SQL.CALC_AV_COST_CATCH_WEIGHT';

BEGIN
   ---
   if I_soh_curr is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_soh_curr', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_qty', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_av_cost_curr is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_av_cost_curr', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_total_cost is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_total_cost', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_soh_curr + I_qty <= 0 then
      -- do not change av_cost if negatively adjusted qty results in stock on hand of 0
      O_new_av_cost := I_av_cost_curr;
   else
      O_new_av_cost := ((I_soh_curr*I_av_cost_curr) + I_total_cost)/(I_soh_curr + I_qty);
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CALC_AV_COST_CATCH_WEIGHT;
---------------------------------------------------------------------------------------------
-- Sir      : SirNBS6160979T
--            Modification to Function code retro-fitted from V1205 to V1202T
-- Function : CONVERT_WEIGHT
---------------------------------------------------------------------------------------------
FUNCTION CONVERT_WEIGHT(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                        O_weight_cuom     IN OUT  ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                        O_cuom            IN OUT  ITEM_SUPP_COUNTRY.COST_UOM%TYPE,
                        I_item            IN      ITEM_MASTER.ITEM%TYPE,
                        I_weight          IN      ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                        I_weight_uom      IN      UOM_CLASS.UOM%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'CATCH_WEIGHT_SQL.CONVERT_WEIGHT';

   L_uom_class     UOM_CLASS.UOM_CLASS%TYPE;
   /* START SirNBS6160979T */
   L_order_type    ITEM_MASTER.ORDER_TYPE%TYPE;
   /* END SirNBS6160979T */

BEGIN

   -- This function converts I_weight from I_weight_uom to item's cost uom as defined on
   -- ITEM_SUPP_COUNTRY table for the item's primary supplier and primary country.

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_item', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_weight is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_weight', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_weight_uom is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_weight_uom', L_program, NULL);
      return FALSE;
   end if;
   ---
   if not ITEM_SUPP_COUNTRY_SQL.GET_COST_UOM(O_error_message,
                                             O_cuom,
                                             I_item) then
      return FALSE;
   end if;
   ---
   if O_cuom = I_weight_uom then
      O_weight_cuom := I_weight;
      return TRUE;
   else
      /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin*/
      /* START SirNBS6160979T */
      -- For a simple pack catch weight item having order type as Fixed, cost uom must be a MASS uom.
      /* END SirNBS6160979T */
      /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End*/
      if not UOM_SQL.GET_CLASS(O_error_message,
                               L_uom_class,
                               O_cuom) then
         return FALSE;
      end if;
      ---
      /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin*/
      /* START SirNBS6160979T */
      if not ITEM_ATTRIB_SQL.GET_ORDER_TYPE(O_error_message,
                                            L_order_type,
                                            I_item) then
         return FALSE;
      end if;
      ---
      if L_uom_class != 'MASS' and L_order_type != 'F' then
      /* END SirNBS6160979T */
      /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End*/
         O_error_message := SQL_LIB.CREATE_MSG('INV_CUOM_CLASS',
                                               O_cuom,
                                               I_item,
                                               NULL);
         return FALSE;
      end if;
      ---
      if not UOM_SQL.CONVERT(O_error_message,
                             O_weight_cuom,
                             O_cuom,
                             I_weight,
                             I_weight_uom,
                             I_item,
                             NULL,
                             NULL) then
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CONVERT_WEIGHT;
--------------------------------------------------------------------------------
FUNCTION CALC_AVERAGE_WEIGHT(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                             O_avg_weight_new  IN OUT  ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                             I_item            IN      ITEM_LOC_SOH.ITEM%TYPE,
                             -- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
                             I_loc IN ITEM_LOC_SOH.LOC%TYPE,
                             I_loc_type IN ITEM_LOC_SOH.LOC_TYPE%TYPE,
                             -- 23-Oct-2008 TESCO HSC/Murali 6907185 End
                             I_soh_curr        IN      ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                             I_avg_weight_curr IN      ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                             I_qty    	     IN      ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                             I_weight 	     IN      ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                             I_weight_uom      IN      UOM_CLASS.UOM%TYPE,
                             -- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
                             I_recalc_ind IN BOOLEAN default NULL)
                             -- 23-Oct-2008 TESCO HSC/Murali 6907185 End
RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'CATCH_WEIGHT_SQL.CALC_AVERAGE_WEIGHT';

   L_weight_cuom     ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_cuom            ITEM_SUPP_COUNTRY.COST_UOM%TYPE;

   -- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
   L_av_weight         ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE := I_avg_weight_curr;
   L_standard_uom      UOM_CLASS.UOM%TYPE;
   L_standard_class    UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor       ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_get_class_ind     VARCHAR2(1) := 'Y';
   L_tran_weight       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_av_new_weight     ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_post_variance     varchar2(1) := 'N';
   L_old_total_weight  ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_units             ITEM_LOC_SOH.STOCK_ON_HAND%TYPE;
   -- 23-Oct-2008 TESCO HSC/Murali 6907185 End

BEGIN

   -- This function calculates the new average weight for an item based on the
   -- current stock on hand and current average weight (in cost uom) and the weight
   -- (in I_weight_uom) of the additional quantity. If I_weight_uom is NULL,
   -- I_weight is in item's cost uom. I_soh_curr and I_qty are both in item's standard uom.
   -- I_avg_weight_curr and the new average weight are both in item's cost uom.

   -- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
   -- Modified the whole function as whle logic was changed in 12.0.8
   if I_weight is NULL then
      -- No change, return the current average weight
      O_avg_weight_new := I_avg_weight_curr;
      return TRUE;
   end if;

   if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                       L_standard_uom,
                                       L_standard_class,
                                       L_conv_factor,
                                       I_item,
                                       L_get_class_ind) = FALSE then
      return FALSE;
   end if;

   if L_standard_class != 'QTY' then
      -- No change, return the current average weight
      O_avg_weight_new := I_avg_weight_curr;
      return TRUE;
   end if;

   if I_soh_curr is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_soh_curr', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_qty', L_program, NULL);
      return FALSE;
   end if;
   ---

   if L_av_weight is NULL then
      ---
      if I_loc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_loc', L_program, NULL);
         return FALSE;
      end if;
      if not ITEMLOC_ATTRIB_SQL.GET_AVERAGE_WEIGHT(O_error_message,
                                                   L_av_weight,
                                                   I_item,
                                                   I_loc,
                                                   I_loc_type) then
         return FALSE;
      end if;
   end if;
   ---


   -- if I_weight_uom is null, assume item's cost uom.
   if I_weight_uom is NULL then
      L_weight_cuom := I_weight;
   else
      ---
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_item', L_program, NULL);
         return FALSE;
      end if;
      ---
      if not CONVERT_WEIGHT(O_error_message,
                            L_weight_cuom,
                            L_cuom,
                            I_item,
                            I_weight,
                            I_weight_uom) then
         return FALSE;
      end if;
   end if;
   ---
   ---note : the av_weight holds old average weight
   ---l_weight_cuom holds transaction weight
   if I_qty > 0 then
      if I_soh_curr >= 0 then
         L_av_new_weight := ((I_soh_curr * L_av_weight)+L_weight_cuom)/(I_soh_curr + I_qty);
      else
         -- reset new weight to receipt weight
         L_av_new_weight := L_weight_cuom/I_qty;
         L_post_variance := 'Y';
      end if;
   else
     -- set new weight = old weight
     if (I_soh_curr + I_qty) <= 0 or I_recalc_ind = FALSE then
        L_av_new_weight := L_av_weight;
        L_post_variance := 'Y';

     else -- New soh > 0 and and I_recalc_ind = TRUE
        if (L_av_weight * I_soh_curr + L_weight_cuom) > 0 then
           L_av_new_weight := ((I_soh_curr * L_av_weight)+L_weight_cuom)/(I_soh_curr + I_qty);
        else
           L_av_new_weight := L_av_weight;
           L_post_variance := 'Y';
        end if;
     end if;
   end if;


   if L_post_variance = 'Y' then
      if I_qty > 0 then
         L_old_total_weight := L_av_weight * I_soh_curr;
         L_units := I_soh_curr;
      else
         L_old_total_weight := L_weight_cuom;
         L_units  := I_qty;
      end if;

      if not POST_WEIGHT_VARIANCE(O_error_message,
                                  I_item         ,
                                  I_loc          ,
                                  I_loc_type     ,
                                  L_units        ,
                                  NULL           ,
                                  NULL           ,
                                  L_old_total_weight   ,
                                  L_av_new_weight * L_units,
                                  NULL,
                                  NULL) then
         return FALSE;
       end if;
   end if;

   O_avg_weight_new := L_av_new_weight;
   -- 23-Oct-2008 TESCO HSC/Murali 6907185 End

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CALC_AVERAGE_WEIGHT;
---------------------------------------------------------------------------------------------
FUNCTION CALC_TOTAL_COST(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         O_total_cost      IN OUT  ITEM_LOC_SOH.UNIT_COST%TYPE,
                         I_pack_item       IN      ITEM_LOC_SOH.ITEM%TYPE,
                         I_loc             IN      ITEM_LOC_SOH.LOC%TYPE,
                         I_loc_type        IN      ITEM_LOC_SOH.LOC_TYPE%TYPE,
                         I_pack_unit_cost  IN      ITEM_LOC_SOH.AV_COST%TYPE,
                         I_qty             IN      ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                         I_weight 	       IN      ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                         I_weight_uom      IN      UOM_CLASS.UOM%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'CATCH_WEIGHT_SQL.CALC_TOTAL_COST';

   L_weight_cuom     ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_nom_weight 	   ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_av_weight       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_cuom            ITEM_SUPP_COUNTRY.COST_UOM%TYPE;
   --Following declarations are added as part of RIB performance issue.
   -- 06-Jan-2009    TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
   L_key1            VARCHAR2(100);
   L_key2            VARCHAR2(100);
   L_key3            VARCHAR2(100);
   L_key4            VARCHAR2(100);
   L_key5            VARCHAR2(100);
   L_key6            VARCHAR2(100);
   DIVIDE_BY_ZERO    EXCEPTION;
   PRAGMA            EXCEPTION_INIT(DIVIDE_BY_ZERO, -1476);
   -- 06-Jan-2009    TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End

BEGIN

   -- This function will calculate the total cost of a simple pack catch weight item.
   -- I_qty is the number of packs. I_weight is the weight of I_qty.
   -- If I_weight_uom is NULL, I_weight is in the pack item's cost unit of measure.
   -- If I_weight and I_weight_uom are both NULL, the average weight of the pack item
   -- at the location will be used.

   if I_pack_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_pack_item', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_pack_unit_cost is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_pack_unit_cost', L_program, NULL);
      return FALSE;
   end if;
   ---
   if not ITEM_SUPP_COUNTRY_DIM_SQL.GET_NOMINAL_WEIGHT(O_error_message,
                                                       L_nom_weight,
                                                       I_pack_item) then
      return FALSE;
   end if;
   ---
   if I_weight is NOT NULL then
      -- weight is passed in
      if I_weight_uom is NOT NULL then
         if not CONVERT_WEIGHT(O_error_message,
                               L_weight_cuom,
                               L_cuom,
                               I_pack_item,
                               I_weight,
                               I_weight_uom) then
            return FALSE;
         end if;
      else
         -- weight uom is not defined, I_weight is in cuom.
         L_weight_cuom := I_weight;
      end if;
      ---
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      L_key1 := to_char(I_pack_item);
      L_key2 := 'I_pack_unit_cost=' || to_char(I_pack_unit_cost);
      L_key3 := 'L_nom_weight=' || to_char(L_nom_weight);
      L_key4 := 'L_weight_cuom=' || to_char(L_weight_cuom);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      -- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
      if L_cuom  = 'EA' then
         O_total_cost := I_pack_unit_cost * I_qty;
      else
         O_total_cost := I_pack_unit_cost/L_nom_weight*L_weight_cuom;
      end if;
      -- 23-Oct-2008 TESCO HSC/Murali 6907185 End

   else
      -- weight is not passed in, use average weight
      -- average weight is always in item's cuom.
      if I_loc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_loc', L_program, NULL);
         return FALSE;
      end if;
      ---
      -- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
      -- Removed the check for I_loc_type being NULL
      -- 23-Oct-2008 TESCO HSC/Murali 6907185 End
      if I_qty is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_qty', L_program, NULL);
         return FALSE;
      end if;
      ---
      if not ITEMLOC_ATTRIB_SQL.GET_AVERAGE_WEIGHT(O_error_message,
                                                   L_av_weight,
                                                   I_pack_item,
                                                   I_loc,
                                                   I_loc_type) then
         return FALSE;
      end if;
      ---
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      -- RIB error message enhancement start
      L_key1 := to_char(I_pack_item);
      L_key2 := 'I_pack_unit_cost=' || to_char(I_pack_unit_cost);
      L_key3 := 'L_nom_weight=' || to_char(L_nom_weight);
      L_key4 := NULL;
      L_key5 := 'L_av_weight=' || to_char(L_av_weight);
      L_key6 := 'I_qty=' || to_char(I_qty);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      O_total_cost := I_pack_unit_cost/L_nom_weight*(L_av_weight*I_qty);
   end if;

   return TRUE;

EXCEPTION
   -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
   -- RIB error message enhancement start
   when DIVIDE_BY_ZERO then
      if L_key4 is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('DIVIDE_BY_ZERO_COST',
                                               L_key1,
                                               L_key2 || ',' || L_key3 || ',' || L_key5 || ',' || L_key6,
                                               NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('DIVIDE_BY_ZERO_COST',
                                               L_key1,
                                               L_key2 || ', ' || L_key3 || ', ' || L_key4,
                                               NULL);
      end if;
      return FALSE;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CALC_TOTAL_COST;
--------------------------------------------------------------------------------
FUNCTION CALC_TOTAL_COST(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         O_total_cost      IN OUT  ITEM_LOC_SOH.UNIT_COST%TYPE,
                         I_pack_item       IN      ITEM_LOC_SOH.ITEM%TYPE,
                         I_comp_unit_cost  IN      ITEM_LOC_SOH.AV_COST%TYPE,
                         I_weight_cuom     IN      ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                         -- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
                         I_receipt_qty IN ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
                         -- 23-Oct-2008 TESCO HSC/Murali 6907185 End
RETURN BOOLEAN IS

   L_program           VARCHAR2(50) := 'CATCH_WEIGHT_SQL.CALC_TOTAL_COST';

   L_nom_weight        item_loc_soh.average_weight%TYPE;
   L_packsku_qty       v_packsku_qty.qty%TYPE := NULL;

   L_exists            BOOLEAN;
   L_item              ITEM_MASTER.ITEM%TYPE;
   L_qty               PACKITEM.PACK_QTY%TYPE;
   L_standard_uom      UOM_CLASS.UOM%TYPE;
   L_standard_class    UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor       ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_get_class_ind     VARCHAR2(1) := 'Y';

   -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
   L_key1           VARCHAR2(100);
   L_key2           VARCHAR2(100);
   L_key3           VARCHAR2(100);
   L_key4           VARCHAR2(100);
   L_key5           VARCHAR2(100);
   DIVIDE_BY_ZERO   EXCEPTION;
   PRAGMA           EXCEPTION_INIT(DIVIDE_BY_ZERO, -1476);
   -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End

   cursor C_qty is
      select qty
        from v_packsku_qty
       where pack_no = I_pack_item;

BEGIN

   -- This function will calculate the total cost of a simple pack catch weight item.
   -- I_weight_cuom is the weight of the pack item in cuom.
   -- I_comp_unit_cost is the component item's unit cost.
   -- Pack's nominal weight will be used to calculate the total cost.

   if I_pack_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_pack_item', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_comp_unit_cost is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_comp_unit_cost', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_weight_cuom is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_weight_cuom', L_program, NULL);
      return FALSE;
   end if;
   ---
   if PACKITEM_ATTRIB_SQL.GET_ITEM_AND_QTY(O_error_message,
                                           L_exists,
                                           L_item,
                                           L_qty,
                                           I_pack_item) = FALSE then
      return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                       L_standard_uom,
                                       L_standard_class,
                                       L_conv_factor,
                                       L_item,
                                       L_get_class_ind) = FALSE then
      return FALSE;
   end if;

   if not ITEM_SUPP_COUNTRY_DIM_SQL.GET_NOMINAL_WEIGHT(O_error_message,
                                                       L_nom_weight,
                                                       I_pack_item) then
      return FALSE;
   end if;
   ---
   open C_qty;
   fetch C_qty into L_packsku_qty;
   close C_qty;

   if L_packsku_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('PACK_ITEM_QTY_REQ', NULL, NULL, NULL);
      return FALSE;
   end if;

   if L_standard_uom = 'EA' then
      -- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
      O_total_cost := I_comp_unit_cost*I_receipt_qty;
      -- 23-Oct-2008 TESCO HSC/Murali 6907185 End
   else
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      -- RIB error message enhancement start
      L_key1 := to_char(I_pack_item);
      L_key2 := 'I_comp_unit_cost=' || to_char(I_comp_unit_cost);
      L_key3 := 'L_packsku_qty=' || to_char(L_packsku_qty);
      L_key4 := 'L_nom_weight =' || to_char(L_nom_weight);
      L_key5 := 'I_weight_cuom=' || to_char(I_weight_cuom);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      O_total_cost := (I_comp_unit_cost*L_packsku_qty)/L_nom_weight*I_weight_cuom;
   end if;

   return TRUE;

EXCEPTION
   -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
   when DIVIDE_BY_ZERO then
      O_error_message := SQL_LIB.CREATE_MSG('DIVIDE_BY_ZERO_COST',
                                            L_key1,
                                            L_key2 || ', ' || L_key3 || ', ' || L_key4 || ', ' || L_key5,
                                            NULL);
      return FALSE;
   -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CALC_TOTAL_COST;
--------------------------------------------------------------------------------
FUNCTION PRORATE_WEIGHT(O_error_message      IN OUT rtk_errors.rtk_text%TYPE,
                        O_weight_cuom        IN OUT item_loc_soh.average_weight%TYPE,
                        O_cuom               IN OUT item_supp_country.cost_uom%TYPE,
                        I_pack_no            IN     item_master.item%TYPE,
                        I_loc                IN     item_loc_soh.loc%TYPE,
                        I_loc_type           IN     item_loc_soh.loc_type%TYPE,
                        I_total_weight       IN     item_loc_soh.average_weight%TYPE,
                        I_total_weight_uom   IN     uom_class.uom%TYPE,
                        I_total_qty          IN     item_loc_soh.stock_on_hand%TYPE,
                        I_qty                IN     item_loc_soh.stock_on_hand%TYPE)
RETURN BOOLEAN IS

   L_program	VARCHAR2(60) := 'CATCH_WEIGHT_SQL.PRORATE_WEIGHT';

   L_average_weight      ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_total_weight_cuom   ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;

BEGIN
   -- This function will return the weight in cuom corresponds to I_qty.
   -- I_total_weight is the weight of I_total_qty in I_total_weight_uom.
   -- If I_total_weight_uom is NULL, use the pack's average weight to derive weight.

   if I_pack_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_pack_no', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_qty', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_total_weight is NOT NULL and I_total_weight_uom is NOT NULL then
      ---
      if I_total_qty is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_total_qty', L_program, NULL);
         return FALSE;
      end if;
      -- convert to cuom
      if not CATCH_WEIGHT_SQL.CONVERT_WEIGHT(O_error_message,
                                             L_total_weight_cuom,
                                             O_cuom,
                                             I_pack_no,
                                             I_total_weight,
                                             I_total_weight_uom) then
         return FALSE;
      end if;
      -- 23-Oct-2008 TESCO HSC/Murali 6732427 Begin
      --- In case of catchweight item , only weight adjustment done in RWMS.
      if I_qty = 0 then
         O_weight_cuom := L_total_weight_cuom;
      else
      -- 23-Oct-2008 TESCO HSC/Murali 6732427 End
         O_weight_cuom := L_total_weight_cuom/I_total_qty * I_qty;
      -- 23-Oct-2008 TESCO HSC/Murali 6732427 Begin
      end if;
      -- 23-Oct-2008 TESCO HSC/Murali 6732427 End
   else
      ---
      if I_loc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_loc', L_program, NULL);
         return FALSE;
      end if;
      ---
      -- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
      -- Removed the check for I_loc_type being NULL
      -- 23-Oct-2008 TESCO HSC/Murali 6907185 End
      if not ITEMLOC_ATTRIB_SQL.GET_AVERAGE_WEIGHT(O_error_message,
                                                   L_average_weight,
                                                   I_pack_no,
                                                   I_loc,
                                                   I_loc_type) then
         return FALSE;
      end if;
      O_weight_cuom := L_average_weight * I_qty;

      if not ITEM_SUPP_COUNTRY_SQL.GET_COST_UOM(O_error_message,
                                                O_cuom,
                                                I_pack_no) then
         return FALSE;
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
END PRORATE_WEIGHT;
--------------------------------------------------------------------------------
FUNCTION CALC_COMP_UPDATE_QTY(O_error_message   IN OUT rtk_errors.rtk_text%TYPE,
                              O_upd_qty         IN OUT item_loc_soh.stock_on_hand%TYPE,
                              I_comp_item       IN     item_master.item%TYPE,
                              I_unit_qty        IN     v_packsku_qty.qty%TYPE,
                              I_weight          IN     item_loc_soh.average_weight%TYPE,
                              I_weight_uom      IN     uom_class.uom%TYPE)
RETURN BOOLEAN IS

   L_program	VARCHAR2(60) := 'CATCH_WEIGHT_SQL.CALC_COMP_UPDATE_QTY';

   L_standard_uom      UOM_CLASS.UOM%TYPE;
   L_standard_class    UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor       ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_get_class_ind     VARCHAR2(1) := 'Y';

BEGIN

   if I_comp_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_comp_item', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_unit_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_unit_qty', L_program, NULL);
      return FALSE;
   end if;

   if I_weight is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_weight', L_program, NULL);
      return FALSE;
   end if;

   if I_weight_uom is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_weight_uom', L_program, NULL);
      return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                       L_standard_uom,
                                       L_standard_class,
                                       L_conv_factor,
                                       I_comp_item,
                                       L_get_class_ind) = FALSE then
      return FALSE;
   end if;

   if L_standard_class = 'MASS' then
      -- component suom is MASS
      -- component stock buckets will be updated by weight in component's standard uom
      if not UOM_SQL.CONVERT(O_error_message,
                             O_upd_qty,  -- weight of qty returned
                             L_standard_uom,
                             I_weight,
                             I_weight_uom,
                             I_comp_item,
                             NULL,
                             NULL) then
         return FALSE;
      end if;
   elsif L_standard_uom = 'EA' then
      -- component suom is Eaches
      -- component stock buckets will be updated with unit qty
      O_upd_qty := I_unit_qty;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_SUOM_CATCH_WGT', L_standard_class, NULL, NULL);
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
END CALC_COMP_UPDATE_QTY;
--------------------------------------------------------------------------------
FUNCTION CALC_COMP_UPDATE_QTY(O_error_message   IN OUT rtk_errors.rtk_text%TYPE,
                              O_upd_qty         IN OUT item_loc_soh.stock_on_hand%TYPE,
                              I_comp_item       IN     item_master.item%TYPE,
                              I_comp_unit_qty   IN     v_packsku_qty.qty%TYPE,
                              I_weight          IN     item_loc_soh.average_weight%TYPE,
                              I_weight_uom      IN     uom_class.uom%TYPE,
                              I_pack_no         IN     v_packsku_qty.pack_no%TYPE,
                              I_location        IN     item_loc_soh.loc%TYPE,
                              I_loc_type        IN     item_loc_soh.loc_type%TYPE,
                              I_pack_unit_qty   IN     item_loc_soh.stock_on_hand%TYPE)
RETURN BOOLEAN IS

   L_program	VARCHAR2(60) := 'CATCH_WEIGHT_SQL.CALC_COMP_UPDATE_QTY';

   L_average_weight    ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_cuom              ITEM_SUPP_COUNTRY.COST_UOM%TYPE;

BEGIN

   -- This is an overloaded function for calculating the update qty for a
   -- simple pack catch weight component item. If weight and weight_uom are
   -- not passed in, it uses the pack item's average weight to derive weight.

   if I_weight is NOT NULL and I_weight_uom is NOT NULL then
      -- weight is defined, convert weight into item's SUOM
      if CATCH_WEIGHT_SQL.CALC_COMP_UPDATE_QTY(O_error_message,
                                               O_upd_qty,
                                               I_comp_item,
                                               I_comp_unit_qty,
                                               I_weight,
                                               I_weight_uom) = FALSE then
         return FALSE;
      end if;
   else
      -- weight is NOT defined, use pack's average weight (in cuom) to derive weight
      if ITEMLOC_ATTRIB_SQL.GET_AVERAGE_WEIGHT(O_error_message,
                                               L_average_weight,
                                               I_pack_no,
                                               I_location,
                                               I_loc_type) = FALSE then
         return FALSE;
      end if;

      if ITEM_SUPP_COUNTRY_SQL.GET_COST_UOM(O_error_message,
                                            L_cuom,
                                            I_pack_no) = FALSE then
         return FALSE;
      end if;

      -- convert into item's SUOM
      if CATCH_WEIGHT_SQL.CALC_COMP_UPDATE_QTY(O_error_message,
                                               O_upd_qty,
                                               I_comp_item,
                                               I_comp_unit_qty,
                                               L_average_weight*I_pack_unit_qty,
                                               L_cuom) = FALSE then
         return FALSE;
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
END CALC_COMP_UPDATE_QTY;
--------------------------------------------------------------------------------
-- 23-Oct-2008 TESCO HSC/Murali 6907185 Begin
FUNCTION CALC_TOTAL_RETAIL(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                           I_comp_item       IN      ITEM_MASTER.ITEM%TYPE,
                           I_qty             IN      ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                           I_unit_retail     IN      ITEM_LOC.UNIT_RETAIL%TYPE,
                           I_location        IN      ITEM_LOC_SOH.LOC%TYPE,
                           I_loc_type        IN      ITEM_LOC_SOH.LOC_TYPE%TYPE,
                           I_weight          IN      ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                           I_weight_uom      IN      UOM_CLASS.UOM%TYPE,
                           O_total_retail    OUT     ORDLOC.UNIT_RETAIL%TYPE
                           )
RETURN BOOLEAN IS
     L_program          VARCHAR2(60) := 'CATCH_WEIGHT_SQL.CALC_TOTAL_RETAIL';
     L_catchweight_ind  ITEM_MASTER.CATCH_WEIGHT_IND%TYPE;
     L_standard_uom     UOM_CLASS.UOM%TYPE;
     L_standard_class   UOM_CLASS.UOM_CLASS%TYPE;
     L_conv_factor      ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
     L_get_class_ind    VARCHAR2(1) := 'Y';
     L_comp_av_cost     ITEM_LOC_SOH.AV_COST%TYPE;
     L_unit_retail      item_loc.unit_retail%TYPE;
     L_unit_cost        item_loc_soh.unit_cost%TYPE;
     L_selling_retail   item_loc.selling_unit_retail%TYPE;
     L_selling_uom      item_loc.selling_uom%TYPE;
     L_average_weight   ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
     L_total_weight     ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
     L_nom_weight       item_loc_soh.average_weight%TYPE;
     L_weight_cuom      ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
     L_cuom             ITEM_SUPP_COUNTRY.COST_UOM%TYPE;


     cursor C_ITEM_MASTER is
      select
             catch_weight_ind
        from item_master
       where item = I_comp_item;

BEGIN
   open C_ITEM_MASTER;
   fetch C_ITEM_MASTER into L_catchweight_ind;
   close C_ITEM_MASTER;

   --- Get standard uom
   if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                       L_standard_uom,
                                       L_standard_class,
                                       L_conv_factor,
                                       I_comp_item,
                                       L_get_class_ind) = FALSE then
      return FALSE;
   end if;

    --- Get unit_cost and unit_retail and selling uom from item_loc in local currency.
   if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message,
                                               I_comp_item,
                                               I_location,
                                               I_loc_type,
                                               L_comp_av_cost,
                                               L_unit_cost,    -- local currency
                                               L_unit_retail,  -- local currency
                                               L_selling_retail,
                                               L_selling_uom) = FALSE then
      return FALSE;
   end if;
   if I_unit_retail is not null then
      L_unit_retail := I_unit_retail;
   end if;

   if L_catchweight_ind = 'N' or  L_standard_uom != 'EA' or L_selling_uom = 'EA' then
      O_total_retail := I_qty * L_unit_retail;
   else
      -- look up nominal weight

      if I_weight is null then
         -- get average weight
         if not ITEMLOC_ATTRIB_SQL.GET_AVERAGE_WEIGHT(O_error_message,
                                                      L_average_weight,
                                                      I_comp_item,
                                                      I_location,
                                                      I_loc_type) then
            return FALSE;
         end if;
         ---
         L_total_weight :=  L_average_weight * I_qty;
      else
         -- I_weight is not null
         -- convert to get the weight
         -- weight is passed in
         if I_weight_uom is NOT NULL then
            if not CONVERT_WEIGHT(O_error_message,
                                  L_weight_cuom,
                                  L_cuom,
                                  I_comp_item,
                                  I_weight,
                                  I_weight_uom) then
               return FALSE;
            end if;
         else
            -- weight uom is not defined, I_weight is in cuom.
            L_weight_cuom := I_weight;
         end if;

         L_total_weight := L_weight_cuom;
      end if;

      if not ITEM_SUPP_COUNTRY_DIM_SQL.GET_NOMINAL_WEIGHT(O_error_message,
                                                          L_nom_weight,
                                                          I_comp_item) then
         return FALSE;
      end if;

      --
      O_total_retail :=  L_unit_retail * L_total_weight / L_nom_weight;
   end if;
   return TRUE;


EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
        return FALSE;
END CALC_TOTAL_RETAIL;

--------------------------------------------------------------------------
FUNCTION POST_WEIGHT_VARIANCE(O_error_message       IN OUT VARCHAR2,
                              I_item                IN     item_master.item%TYPE,
                              I_location            IN     item_loc.loc%TYPE,
                              I_loc_type            IN     item_loc.loc_type%TYPE,
                              I_units               IN     tran_data.units%TYPE,
                              I_ref_no_1            IN     tran_data.ref_no_1%TYPE,
                              I_ref_no_2            IN     tran_data.ref_no_2%TYPE,
                              I_total_weight_old    IN     ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                              I_total_weight_new    IN     ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                              I_unit_retail         IN     ITEM_LOC.UNIT_RETAIL%TYPE,
                              I_tran_date           IN     period.vdate%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(60) := 'CATCH_WEIGHT_SQL.POST_WEIGHT_VARIANCE';

   L_tran_code          tran_data.tran_code%TYPE := 15;
   L_total_variance     tran_data.total_retail%TYPE;
   L_total_cost         tran_data.total_cost%TYPE := NULL;
   L_unit_retail        item_loc.unit_retail%TYPE := I_unit_retail;
   L_nom_weight         item_loc_soh.average_weight%TYPE;
   L_item_rec           item_master%ROWTYPE;
   L_comp_av_cost       ITEM_LOC_SOH.AV_COST%TYPE;
   L_unit_cost          item_loc_soh.unit_cost%TYPE;
   L_selling_retail     item_loc.selling_unit_retail%TYPE;
   L_selling_uom        item_loc.selling_uom%TYPE;
   L_old_unit_retail    item_loc.unit_retail%TYPE;
   L_new_unit_retail    item_loc.unit_retail%TYPE;

BEGIN

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_rec,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   if L_item_rec.pack_ind = 'Y' then
      return TRUE;
   end if;
   if L_unit_retail is null then
      if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message,
                                                  I_item,
                                                  I_location,
                                                  I_loc_type,
                                                  L_comp_av_cost,
                                                  L_unit_cost,    -- local currency
                                                  L_unit_retail,  -- local currency
                                                  L_selling_retail,
                                                  L_selling_uom) = FALSE then
         return FALSE;
      end if;
   end if;
   if not ITEM_SUPP_COUNTRY_DIM_SQL.GET_NOMINAL_WEIGHT(O_error_message,
                                                       L_nom_weight,
                                                       I_item) then
      return FALSE;
   end if;



   -- retail variance is weight variance * selling price
   L_total_variance  := (I_total_weight_old - I_total_weight_new) * (L_unit_retail / L_nom_weight);
   if I_units = 0 then
      L_old_unit_retail := 0;
      L_new_unit_retail := 0;
   else
      -- average unit retail is average weight * selling price
      L_old_unit_retail := (I_total_weight_old / I_units) * (L_unit_retail / L_nom_weight);
      L_new_unit_retail := (I_total_weight_new / I_units) * (L_unit_retail / L_nom_weight);
   end if;

   if STKLEDGR_SQL.BUILD_TRAN_DATA_INSERT(O_error_message,
                                          I_item,
                                          L_item_rec.dept,
                                          L_item_rec.class,
                                          L_item_rec.subclass,
                                          I_location,
                                          I_loc_type,
                                          nvl(I_tran_date, GET_VDATE),
                                          L_tran_code,
                                          NULL,
                                          I_units,
                                          L_total_cost,   -- total cost
                                          L_total_variance,
                                          I_ref_no_1,
                                          I_ref_no_2,
                                          NULL,
                                          NULL,
                                          L_old_unit_retail,
                                          L_new_unit_retail,
                                          NULL,
                                          NULL,
                                          NULL,
                                          L_program,
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
END POST_WEIGHT_VARIANCE;
-- 23-Oct-2008 TESCO HSC/Murali 6907185 End
--------------------------------------------------------------------------

END CATCH_WEIGHT_SQL;
/

