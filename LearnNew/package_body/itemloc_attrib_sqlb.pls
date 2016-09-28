CREATE OR REPLACE PACKAGE BODY ITEMLOC_ATTRIB_SQL AS
-----------------------------------------------------------------------------------------------------
--Mod By:      Murali Krishnan
--Mod Date:    29-Oct-2008
--Mod Ref:     Back Port Oracle fix(6907185)
--Mod Details: Back ported the oracle fix for Bug 6907185.Modified the functions GET_DETAILS,GET_AVERAGE_WEIGHT.
-----------------------------------------------------------------------------------------------------

--------------------------------------------------------------------
-- This is an internal function and should not be called from
-- outside of the package.
----------------------------------------------------------------------
----------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 06-Jan-2009
-- Def Ref    : PrfNBS010460 and NBS00010460
-- Def Details: Code has modified for performance related issues in RIB.
------------------------------------------------------------------------
FUNCTION GET_DETAILS(
       O_error_message                IN OUT VARCHAR2,
       I_item                         IN     ITEM_LOC.ITEM%TYPE,
       I_loc                          IN     ITEM_LOC.LOC%TYPE,
       I_loc_type                     IN     ITEM_LOC.LOC_TYPE%TYPE,
       I_cost_ind                     IN     VARCHAR2,
       I_retail_ind                   IN     VARCHAR2,
       I_stock_ind                    IN     VARCHAR2,
       I_nonsellable_pack_retail_ind  IN     VARCHAR2,
       O_av_cost                      IN OUT ITEM_LOC_SOH.AV_COST%TYPE,
       O_unit_cost                    IN OUT ITEM_LOC_SOH.UNIT_COST%TYPE,
       O_unit_retail                  IN OUT ITEM_LOC.UNIT_RETAIL%TYPE,
       O_selling_unit_retail          IN OUT ITEM_LOC.UNIT_RETAIL%TYPE,
       O_selling_uom                  IN OUT ITEM_LOC.SELLING_UOM%TYPE,
       O_stock_on_hand                IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
       O_pack_comp_soh                IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
RETURN BOOLEAN IS

   L_program             VARCHAR2(255) := 'ITEMLOC_ATTRIB_SQL.GET_DETAILS';
   L_pack_ind            ITEM_MASTER.PACK_IND%TYPE              := NULL;
   L_sellable            ITEM_MASTER.SELLABLE_IND%TYPE          := NULL;
   L_orderable           ITEM_MASTER.ORDERABLE_IND%TYPE         := NULL;
   L_pack_type           ITEM_MASTER.PACK_TYPE%TYPE             := NULL;
   L_level               ITEM_MASTER.ITEM_LEVEL%TYPE            := NULL;
   L_tran_level          ITEM_MASTER.TRAN_LEVEL%TYPE            := NULL;
   L_unit_retail_zone    ITEM_LOC.UNIT_RETAIL%TYPE              := NULL;
   L_zone_id             ITEM_ZONE_PRICE.ZONE_ID%TYPE           := NULL;
   L_zone_group_id       ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE     := NULL;
   L_std_uom             ITEM_ZONE_PRICE.SELLING_UOM%TYPE       := NULL;
   L_selling_unit_retail ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE       := NULL;
   L_multi_retail        ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE       := NULL;
   L_multi_units         ITEM_ZONE_PRICE.MULTI_UNITS%TYPE       := NULL;
   L_multi_uom           ITEM_ZONE_PRICE.MULTI_SELLING_UOM%TYPE := NULL;
   L_item_rec            ITEM_MASTER%ROWTYPE                    := NULL;
   -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
   L_supplier            ITEM_SUPPLIER.SUPPLIER%TYPE            := NULL;
   -- 29-Oct-2008 TESCO HSC/Murali 6907185 End

   cursor C_ITEM_LOC_ALL is
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
      select nvl(ils.av_cost,0),
             nvl(ils.unit_cost,0),
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 End
             il.unit_retail,
             il.selling_unit_retail,
             il.selling_uom,
             ils.stock_on_hand,
             ils.pack_comp_soh
        from item_loc il,
             item_loc_soh ils
       where il.item = I_item
         and il.loc = I_loc
         and il.item = ils.item
         and il.loc = ils.loc;

   cursor C_IL_COST is
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
      select nvl(unit_cost,0)
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 End
        from item_master im,
             item_loc_soh ils
       where ils.item = im.item
         and ils.loc  = I_loc
         and ((im.item_parent       = I_item
               and im.tran_level    = im.item_level)
             or
              (im.item_grandparent  = I_item
               and im.tran_level    = im.item_level));

   cursor C_TR_COST is
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
      select nvl(av_cost,0)
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 End
        from item_loc_soh
       where item = I_item
         and loc = I_loc;

   cursor C_AV_COST is
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
      select nvl(sum(ils.av_cost * decode(sign(ils.stock_on_hand),
                                     -1,0, 0,0, ils.stock_on_hand)),0) /
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 End
             decode(sum(decode(sign(ils.stock_on_hand),
                                    -1,0, 0,0, ils.stock_on_hand)),
                    0,1,
                    sum(decode(sign(ils.stock_on_hand),
                               -1,0, 0,0, ils.stock_on_hand)))
        from item_master im,
             item_loc_soh ils
       where ils.item = im.item
         and ils.loc  = I_loc
         and ((im.item_parent       = I_item
               and im.tran_level    = im.item_level)
             or
              (im.item_grandparent  = I_item
               and im.tran_level    = im.item_level));

   cursor C_IL_SOH is
      select stock_on_hand
        from item_loc_soh
       where item = I_item
         and loc = I_loc;

   cursor C_PACK_COST is
      select nvl(sum(ils.unit_cost * v.qty),0),
             nvl(sum(ils.av_cost * v.qty),0)
        from item_loc_soh ils,
             v_packsku_qty v
       where v.pack_no = I_item
         and v.item = ils.item
         and ils.loc = I_loc;

BEGIN
   if not ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                     L_level,
                                     L_tran_level,
                                     I_item) then
      return FALSE;
   end if;

   if not ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                          L_item_rec,
                                          I_item) then
     return FALSE;
   end if;

   L_pack_ind := L_item_rec.pack_ind;
   L_sellable := L_item_rec.sellable_ind;
   L_orderable := L_item_rec.orderable_ind;
   L_pack_type := L_item_rec.pack_type;

   if ((L_pack_ind = 'N') and (L_tran_level = L_level)) then

      if L_sellable = 'N' and L_item_rec.item_xform_ind = 'Y' then

	     SQL_LIB.SET_MARK('OPEN','C_TR_COST','ITEM_LOC_SOH',
                          'Item: '||I_item||'I_loc: '||to_char(I_loc));
         open  C_TR_COST;
         SQL_LIB.SET_MARK('FETCH','C_TR_COST','ITEM_LOC_SOH',
                          'Item: '||I_item||'I_loc: '||to_char(I_loc));
         fetch C_TR_COST into O_av_cost;
         SQL_LIB.SET_MARK('CLOSE','C_TR_COST','ITEM_LOC_SOH',
                          'Item: '||I_item||'I_loc: '||to_char(I_loc));
         if C_TR_COST%NOTFOUND then
            close C_TR_COST;
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
            --Following RIB error message has modified as the part of Performance issue.
            /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                                 NULL, NULL);*/
            --RIB error message enhancement start
            O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                                  I_item,
                                                  I_Loc,
                                                  NULL);
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
            return FALSE;
         end if;
         close C_TR_COST;

         if ITEM_XFORM_SQL.CALCULATE_RETAIL(O_error_message,
                                            I_item,
                                            I_loc,
                                            O_unit_retail) = FALSE then
            return FALSE;
         end if;
      else
         SQL_LIB.SET_MARK('OPEN','C_ITEM_LOC_ALL','ITEM_LOC, ITEM_LOC_SOH',
                       ' Item: '||I_item||'Loc: '||to_char(I_Loc));
         open C_ITEM_LOC_ALL;
         SQL_LIB.SET_MARK('FETCH','C_ITEM_LOC_ALL','ITEM_LOC, ITEM_LOC_SOH',
                          ' Item: '||I_item||'Loc: '||to_char(I_Loc));
         fetch C_ITEM_LOC_ALL into O_av_cost,
                                   O_unit_cost,
                                   O_unit_retail,
                                   O_selling_unit_retail,
                                   O_selling_uom,
                                   O_stock_on_hand,
                                   O_pack_comp_soh;
         SQL_LIB.SET_MARK('CLOSE','C_ITEM_LOC_ALL','ITEM_LOC, ITEM_LOC_SOH',
                          ' Item: '||I_item||'Loc: '||to_char(I_Loc));
         if C_ITEM_LOC_ALL%NOTFOUND then
            close C_ITEM_LOC_ALL;
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
            --Following RIB error message has modified as the part of Performance issue.
            /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                                 NULL, NULL);*/
            --RIB error message enhancement start
            O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                                  I_item,
                                                  I_Loc,
                                                  NULL);
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
            return FALSE;
         end if;
         close C_ITEM_LOC_ALL;

      end if;

   elsif (L_pack_ind = 'N') and (L_tran_level > L_level) then
      -- NOTE: soh is not populated for items above the transaction level
      -- This path through the code for a parent item is probably never executed.

      if I_cost_ind = 'Y' then

         O_unit_cost := 0;
         SQL_LIB.SET_MARK('OPEN','C_IL_COST','ITEM_LOC_SOH',
                          'Item: '||I_item||'I_loc: '||to_char(I_loc));
         open  C_IL_COST;
         SQL_LIB.SET_MARK('FETCH','C_IL_COST','ITEM_LOC_SOH',
                          'Item: '||I_item||'I_loc: '||to_char(I_loc));
         fetch C_IL_COST into O_unit_cost;
         SQL_LIB.SET_MARK('CLOSE','C_IL_COST','ITEM_LOC_SOH',
                          'Item: '||I_item||'I_loc: '||to_char(I_loc));
         if C_IL_COST%NOTFOUND then
            close C_IL_COST;
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
            --Following RIB error message has modified as the part of Performance issue.
            /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                                 NULL, NULL);*/
            --RIB error message enhancement start
            O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                                  I_item,
                                                  I_Loc,
                                                  NULL);
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
            return FALSE;
         end if;
         close C_IL_COST;
         O_av_cost := 0;
         SQL_LIB.SET_MARK('OPEN','C_AV_COST','ITEM_MASTER, ITEM_LOC, ITEM_LOC_SOH',
                          'Item: '||I_item||'I_loc: '||to_char(I_loc));
         open  C_AV_COST;
         SQL_LIB.SET_MARK('FETCH','C_AV_COST','ITEM_MASTER, ITEM_LOC, ITEM_LOC_SOH',
                          'Item: '||I_item||'I_loc: '||to_char(I_loc));
         fetch C_AV_COST into O_av_cost;
         SQL_LIB.SET_MARK('CLOSE','C_AV_COST','ITEM_MASTER, ITEM_LOC, ITEM_LOC_SOH',
                          'Item: '||I_item||'I_loc: '||to_char(I_loc));
         if C_AV_COST%NOTFOUND then
            close C_AV_COST;
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
            --Following RIB error message has modified as the part of Performance issue.
            /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                                 NULL, NULL);*/
            --RIB error message enhancement start
            O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                                  I_item,
                                                  I_Loc,
                                                  NULL);
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
            return FALSE;
         end if;
         close C_AV_COST;
         if O_av_cost = 0 then
            O_av_cost := O_unit_cost;
         end if;

      end if; -- cost ind

      if I_retail_ind = 'Y' then

         O_unit_retail := 0;
         O_selling_unit_retail := 0;
         O_selling_uom := NULL;

         if PRICING_ATTRIB_SQL.GET_RETAIL(O_error_message,
                                          O_unit_retail,
                                          L_std_uom,
                                          O_selling_unit_retail,
                                          O_selling_uom,
                                          L_multi_units,
                                          L_multi_retail,
                                          L_multi_uom,
                                          I_item,
                                          I_loc_type,
                                          I_loc) = FALSE then
            return FALSE;
         end if;

      end if;-- retail ind

   elsif L_pack_ind = 'Y' then

      if I_stock_ind = 'Y' then

         SQL_LIB.SET_MARK('OPEN','C_IL_SOH','ITEM_LOC_SOH',
                          'Item: '||I_item||' Loc: '||I_loc);
         open C_IL_SOH;
         SQL_LIB.SET_MARK('FETCH','C_IL_SOH','ITEM_LOC_SOH',
                          'Item: '||I_item||' Loc: '||I_loc);
         fetch C_IL_SOH into O_stock_on_hand;
         SQL_LIB.SET_MARK('CLOSE','C_IL_SOH','ITEM_LOC_SOH',
                          'Item: '||I_item||' Loc: '||I_loc);
         if C_IL_SOH%NOTFOUND then
            close C_IL_SOH;
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
            --Following RIB error message has modified as the part of Performance issue.
            /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                                 NULL, NULL);*/
            --RIB error message enhancement start
            O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                                  I_item,
                                                  I_Loc,
                                                  NULL);
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
            return FALSE;
         end if;
         close C_IL_SOH;

      end if;

      if I_cost_ind = 'Y' then
         -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
         ---
         SQL_LIB.SET_MARK('OPEN','C_PACK_COST','ITEM_LOC_SOH',
                          'Item: '||I_item||' Loc: '||to_char(I_Loc));
         open C_PACK_COST;
         SQL_LIB.SET_MARK('FETCH','C_PACK_COST','ITEM_LOC_SOH',
                          'Item: '||I_item||' Loc: '||to_char(I_Loc));
         fetch C_PACK_COST into O_unit_cost,
                                O_av_cost;
         SQL_LIB.SET_MARK('CLOSE','C_PACK_COST','ITEM_LOC_SOH',
                          'Item: '||I_item||' Loc: '||to_char(I_Loc));
         if C_PACK_COST%NOTFOUND then
            close C_PACK_COST;
            O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                                 NULL, NULL);
            return FALSE;
         end if;
         close C_PACK_COST;
         ---
         if L_orderable = 'Y' and L_pack_type = 'V' then
            ---get primary supplier cost
               if SUPP_ITEM_SQL.GET_PRI_SUP_COST(O_error_message,
                                     L_supplier,
                                     O_unit_cost,
                                     I_item,
                                     I_loc) = FALSE then
                  return FALSE;
               end if;
         end if;
         ---
         -- 29-Oct-2008 TESCO HSC/Murali 6907185 End
      end if;

      if I_retail_ind = 'Y' then
         O_unit_retail := NULL;
         O_selling_unit_retail := NULL;
         O_selling_uom := NULL;

         if L_sellable = 'Y' then

            if PRICING_ATTRIB_SQL.GET_RETAIL(O_error_message,
                                             O_unit_retail,
                                             L_std_uom,
                                             O_selling_unit_retail,
                                             O_selling_uom,
                                             L_multi_units,
                                             L_multi_retail,
                                             L_multi_uom,
                                             I_item,
                                             I_loc_type,
                                             I_loc) = FALSE then
               return FALSE;
            end if;
         elsif L_sellable = 'N' and I_nonsellable_pack_retail_ind = 'Y' then
            if not PRICING_ATTRIB_SQL.BUILD_PACK_RETAIL(O_error_message,
                                                        O_unit_retail,
                                                        I_item,
                                                        I_loc_type,
                                                        I_loc) then
               return FALSE;
            end if;
         end if; /* end sellable */
      end if; /* retail ind */
   end if; /* end item type */

   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              to_char(SQLCODE));
        return FALSE;
END GET_DETAILS;
--------------------------------------------------------------------
FUNCTION GET_AV_COST(O_error_message IN OUT VARCHAR2,
                     I_item          IN     item_master.item%TYPE,
                     I_loc           IN     item_loc.loc%TYPE,
                     I_loc_type      IN     item_loc.loc_type%TYPE,
                     O_av_cost       IN OUT item_loc_soh.av_cost%TYPE)
RETURN BOOLEAN IS

   L_program               VARCHAR2(64) := 'ITEMLOC_ATTRIB_SQL.GET_AV_COST';
   L_unit_cost             item_loc_soh.unit_cost%TYPE := NULL;
   L_unit_retail           item_loc.unit_retail%TYPE := NULL;
   L_selling_unit_retail   item_loc.selling_unit_retail%TYPE := NULL;
   L_selling_uom           item_loc.selling_uom%TYPE := NULL;
   L_stock_on_hand         item_loc_soh.stock_on_hand%TYPE := NULL;
   L_pack_comp_soh         item_loc_soh.pack_comp_soh%TYPE := NULL;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if GET_DETAILS(O_error_message,
                  I_item,
                  I_loc,
                  I_loc_type,
                  'Y',                    /* cost ind */
                  'N',                    /* retail ind */
                  'N',                    /* stock ind */
                  'N',                    /* nonsellable_pack_retail_ind */
                  O_av_cost,
                  L_unit_cost,
                  L_unit_retail,
                  L_selling_unit_retail,
                  L_selling_uom,
                  L_stock_on_hand,
                  L_pack_comp_soh) = FALSE then
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
END GET_AV_COST;
--------------------------------------------------------------------
FUNCTION GET_COSTS_AND_RETAILS(O_error_message         IN OUT VARCHAR2,
                               I_item                  IN     item_loc.item%TYPE,
                               I_loc                   IN     item_loc.loc%TYPE,
                               I_loc_type              IN     item_loc.loc_type%TYPE,
                               O_av_cost               IN OUT item_loc_soh.av_cost%TYPE,
                               O_unit_cost             IN OUT item_loc_soh.unit_cost%TYPE,
                               O_unit_retail           IN OUT item_loc.unit_retail%TYPE,
                               O_selling_unit_retail   IN OUT item_loc.selling_unit_retail%TYPE,
                               O_selling_uom           IN OUT item_loc.selling_uom%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS';
   L_stock_on_hand        item_loc_soh.stock_on_hand%TYPE := NULL;
   L_pack_comp_soh        item_loc_soh.pack_comp_soh%TYPE := NULL;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if GET_DETAILS(O_error_message,
                  I_item,
                  I_loc,
                  I_loc_type,
                  'Y',                    /* cost ind */
                  'Y',                    /* retail ind */
                  'N',                    /* stock ind */
                  'N',                    /* nonsellable_pack_retail_ind */
                  O_av_cost,
                  O_unit_cost,
                  O_unit_retail,
                  O_selling_unit_retail,
                  O_selling_uom,
                  L_stock_on_hand,
                  L_pack_comp_soh) = FALSE then
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
END GET_COSTS_AND_RETAILS;
--------------------------------------------------------------------
FUNCTION GET_COSTS_AND_RETAILS(O_error_message                IN OUT VARCHAR2,
                               I_item                         IN     item_loc.item%TYPE,
                               I_loc                          IN     item_loc.loc%TYPE,
                               I_loc_type                     IN     item_loc.loc_type%TYPE,
                               I_nonsellable_pack_retail_ind  IN     VARCHAR2,
                               O_av_cost                      IN OUT item_loc_soh.av_cost%TYPE,
                               O_unit_cost                    IN OUT item_loc_soh.unit_cost%TYPE,
                               O_unit_retail                  IN OUT item_loc.unit_retail%TYPE,
                               O_selling_unit_retail          IN OUT item_loc.selling_unit_retail%TYPE,
                               O_selling_uom                  IN OUT item_loc.selling_uom%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS';
   L_stock_on_hand        item_loc_soh.stock_on_hand%TYPE := NULL;
   L_pack_comp_soh        item_loc_soh.pack_comp_soh%TYPE := NULL;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if GET_DETAILS(O_error_message,
                  I_item,
                  I_loc,
                  I_loc_type,
                  'Y',                           /* cost ind */
                  'Y',                           /* retail ind */
                  'N',                           /* stock ind */
                  I_nonsellable_pack_retail_ind, /* nonsellable_pack_retail_ind */
                  O_av_cost,
                  O_unit_cost,
                  O_unit_retail,
                  O_selling_unit_retail,
                  O_selling_uom,
                  L_stock_on_hand,
                  L_pack_comp_soh) = FALSE then
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
END GET_COSTS_AND_RETAILS;
--------------------------------------------------------------------
FUNCTION GET_AV_COST_SOH (O_error_message IN OUT  VARCHAR2,
                          I_item          IN      item_loc.item%TYPE,
                          I_loc           IN      item_loc.loc%TYPE,
                          I_loc_type      IN      item_loc.loc_type%TYPE,
                          O_av_cost       IN OUT  item_loc_soh.av_cost%TYPE,
                          O_stock_on_hand IN OUT  item_loc_soh.stock_on_hand%TYPE,
                          O_pack_comp_soh IN OUT  item_loc_soh.pack_comp_soh%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEMLOC_ATTRIB_SQL.GET_AV_COST_SOH';
   L_unit_cost             item_loc_soh.unit_cost%TYPE := NULL;
   L_unit_retail           item_loc.unit_retail%TYPE := NULL;
   L_selling_unit_retail   item_loc.selling_unit_retail%TYPE := NULL;
   L_selling_uom           item_loc.selling_uom%TYPE := NULL;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if GET_DETAILS(O_error_message,
                  I_item,
                  I_loc,
                  I_loc_type,
                  'Y',                    /* cost ind */
                  'N',                    /* retail ind */
                  'Y',                    /* stock ind */
                  'N',                    /* nonsellable_pack_retail_ind */
                  O_av_cost,
                  L_unit_cost,
                  L_unit_retail,
                  L_selling_unit_retail,
                  L_selling_uom,
                  O_stock_on_hand,
                  O_pack_comp_soh) = FALSE then
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
END GET_AV_COST_SOH;
--------------------------------------------------------------------
FUNCTION LOCATIONS_EXIST (O_error_message IN OUT  VARCHAR2,
                          I_item          IN      item_loc.item%TYPE,
                          I_loc_type      IN      item_loc.loc_type%TYPE,
                          O_exist         IN OUT  BOOLEAN)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'ITEMLOC_ATTRIB_SQL.LOCATIONS_EXIST';
   L_loc_ind    VARCHAR2(1);

   cursor C_ITEM_LOC is
      select 'x'
        from item_loc
       where item = I_item
         and (I_loc_type is NULL or
              loc_type = I_loc_type);

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   O_exist := FALSE;

   SQL_LIB.SET_MARK('OPEN', 'C_ITEM_LOC', 'ITEM_LOC', 'Item: ' ||I_item);
   open C_ITEM_LOC;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM_LOC', 'ITEM_LOC', 'Item: ' ||I_item);
   fetch C_ITEM_LOC into L_loc_ind;
   if C_ITEM_LOC%FOUND then
      O_exist := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_LOC', 'ITEM_LOC', 'Item: ' ||I_item);
   close C_ITEM_LOC;

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   RETURN FALSE;
END LOCATIONS_EXIST;
-----------------------------------------------------------------------------------------
FUNCTION ITEM_LOC_EXIST(O_error_message IN OUT VARCHAR2,
                        I_item          IN     item_loc.item%TYPE,
                        I_loc           IN     item_loc.loc%TYPE,
                        O_exists        IN OUT BOOLEAN)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST';
   L_loc_ind    VARCHAR2(1) := NULL;

   cursor C_ITEM_LOC is
      select 'x'
        from item_loc
       where item = I_item
         and loc = I_loc;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM_LOC', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   open C_ITEM_LOC;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM_LOC', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   fetch C_ITEM_LOC into L_loc_ind;
   if C_ITEM_LOC%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_LOC', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   close C_ITEM_LOC;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_LOC_EXIST;
-----------------------------------------------------------------------------------------
FUNCTION ITEM_STATUS(O_error_message IN OUT VARCHAR2,
                     I_item          IN     item_loc.item%TYPE,
                     I_loc           IN     item_loc.loc%TYPE,
                     O_status        IN OUT item_loc.status%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'ITEMLOC_ATTRIB_SQL.ITEM_STATUS';

   cursor C_STATUS is
      select status
        from item_loc
       where loc = I_loc
         and item = I_item;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   open C_STATUS;
   SQL_LIB.SET_MARK('FETCH', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   fetch C_STATUS into O_status;
   SQL_LIB.SET_MARK('CLOSE', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   if C_STATUS%NOTFOUND then
      close C_STATUS;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                        NULL, NULL);*/
      --RIB error message enhancement start
      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                            I_item,
                                            I_Loc,
                                            NULL);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      return FALSE;
   end if;
   close C_STATUS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_STATUS;
-----------------------------------------------------------------------------------------
FUNCTION ITEM_IN_ACTIVE_PACK(O_error_message  IN OUT VARCHAR2,
                             I_item           IN     item_loc.item%type,
                             I_loc            IN     item_loc.loc%type,
                             O_active         IN OUT BOOLEAN)
RETURN BOOLEAN IS

   L_program VARCHAR2(255) := 'ITEMLOC_ATTRIB_SQL.ITEM_IN_ACTIVE_PACK';
   L_exist   VARCHAR2(1)   := NULL;

   cursor C_PACK is
      select 'x'
        from v_packsku_qty vpq,
             item_loc il
       where il.loc  = I_loc
         and il.item = vpq.pack_no
         and vpq.item = I_item
         and il.status  = 'A';

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   O_active   := FALSE;

   SQL_LIB.SET_MARK('OPEN', 'C_PACK', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   open C_PACK;
   SQL_LIB.SET_MARK('FETCH', 'C_PACK', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   fetch C_PACK into L_exist;
   if C_PACK%FOUND then
      O_active := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_PACK', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   close C_PACK;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_IN_ACTIVE_PACK;
----------------------------------------------------------------------------------------
FUNCTION STOCK_EXISTS(O_error_message      IN OUT VARCHAR2,
                      O_exists             IN OUT BOOLEAN,
                      I_item               IN     item_loc.item%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(255) := 'ITEMLOC_ATTRIB_SQL.STOCK_EXISTS';
   L_exists    VARCHAR2(1)   := NULL;

   cursor C_STOCK is
      select 'x'
        from item_loc_soh
       where (stock_on_hand != 0
              or pack_comp_soh != 0
              or in_transit_qty != 0
              or pack_comp_intran != 0
              or tsf_reserved_qty != 0
              or pack_comp_resv != 0
              or tsf_expected_qty != 0
              or pack_comp_exp != 0
              or rtv_qty != 0)
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   O_exists := FALSE;

   SQL_LIB.SET_MARK('OPEN', 'C_STOCK', 'ITEM_LOC', 'Item: ' ||I_item);
   open C_STOCK;
   SQL_LIB.SET_MARK('FETCH', 'C_STOCK', 'ITEM_LOC', 'Item: ' ||I_item);
   fetch C_STOCK into L_exists;
   if C_STOCK%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_STOCK', 'ITEM_LOC', 'Item: ' ||I_item);
   close C_STOCK;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                     SQLERRM,
                     L_program,
                     to_char(SQLCODE));
      return FALSE;
END STOCK_EXISTS;
-------------------------------------------------------------------------------
FUNCTION GET_SUPPLIER_CNTRY(O_error_message      IN OUT VARCHAR2,
                            O_supplier           IN OUT item_loc.primary_supp%TYPE,
                            O_origin_country_id  IN OUT item_loc.primary_cntry%TYPE,
                            I_item               IN     item_loc.item%TYPE,
                            I_loc                IN     item_loc.loc%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR(64) := 'ITEMLOC_ATTRIB_SQL.GET_SUPPLIER_CNTRY';

   cursor C_ITEM_LOC is
      select primary_supp,
             primary_cntry
        from item_loc
       where item = I_item
         and loc = I_loc;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_ITEM_LOC', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   open C_ITEM_LOC;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM_LOC', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   fetch C_ITEM_LOC into O_supplier,
                         O_origin_country_id;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_LOC', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   if C_ITEM_LOC%NOTFOUND then
      close C_ITEM_LOC;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                        NULL, NULL);*/
      --RIB error message enhancement start
      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                            I_item,
                                            I_Loc,
                                            NULL);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      return FALSE;
   end if;
   close C_ITEM_LOC;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_SUPPLIER_CNTRY;
-------------------------------------------------------------------------------
FUNCTION GET_DAILY_WASTE_PCT(O_error_message   IN OUT VARCHAR2,
                             O_daily_waste_pct IN OUT item_loc.daily_waste_pct%TYPE,
                             I_item            IN     item_loc.item%TYPE,
                             I_loc             IN     item_loc.loc%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR(64) := 'ITEMLOC_ATTRIB_SQL.GET_DAILY_WASTE_PCT';

   cursor C_WASTE_PCT is
      select NVL(il.daily_waste_pct, NVL(im.default_waste_pct, 0))
        from item_loc il,
             item_master im
       where il.item = I_item
         and il.loc = I_loc
         and il.item = im.item;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_WASTE_PCT', 'ITEM_LOC, ITEM_MASTER', 'Item: ' ||I_item||' Loc: '||I_loc);
   open C_WASTE_PCT;
   SQL_LIB.SET_MARK('FETCH', 'C_WASTE_PCT', 'ITEM_LOC, ITEM_MASTER', 'Item: ' ||I_item||' Loc: '||I_loc);
   fetch C_WASTE_PCT into O_daily_waste_pct;
   SQL_LIB.SET_MARK('CLOSE', 'C_WASTE_PCT', 'ITEM_LOC, ITEM_MASTER', 'Item: ' ||I_item||' Loc: '||I_loc);
   if C_WASTE_PCT%NOTFOUND then
      close C_WASTE_PCT;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                        NULL, NULL);*/
      --RIB error message enhancement start
      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                            I_item,
                                            I_Loc,
                                            NULL);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      return FALSE;
   end if;
   close C_WASTE_PCT;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_DAILY_WASTE_PCT;
--------------------------------------------------------------------------------
FUNCTION GET_STATUS_TAXABLE(O_error_message   IN OUT VARCHAR2,
                            O_status          IN OUT item_loc.status%TYPE,
                            O_taxable_ind     IN OUT item_loc.taxable_ind%TYPE,
                            I_item            IN     item_loc.item%TYPE,
                            I_loc             IN     item_loc.loc%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR(64) := 'ITEMLOC_ATTRIB_SQL.GET_STATUS_TAXABLE';

   cursor C_STATUS is
      select status,
             taxable_ind
        from item_loc
       where loc = I_loc
         and item = I_item;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   open C_STATUS;
   SQL_LIB.SET_MARK('FETCH', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   fetch C_STATUS into O_status,
                       O_taxable_ind;
   SQL_LIB.SET_MARK('CLOSE', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
   if C_STATUS%NOTFOUND then
      close C_STATUS;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                        NULL, NULL);*/
      --RIB error message enhancement start
      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                            I_item,
                                            I_Loc,
                                            NULL);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      return FALSE;
   end if;
   close C_STATUS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_STATUS_TAXABLE;
---------------------------------------------------------------------------------
FUNCTION ITEMLOC_STATUS(O_error_message IN OUT VARCHAR2,
                        O_status        IN OUT item_loc.status%TYPE,
                        I_item          IN     item_loc.item%TYPE,
                        I_loc           IN     item_loc.loc%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'ITEMLOC_ATTRIB_SQL.ITEMLOC_STATUS';
   L_mc_ind     SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;
   L_flag       BOOLEAN;
   L_dummy      VARCHAR2(1);

   cursor C_STATUS is
      select status
        from item_loc
       where loc  = I_loc
         and item = I_item;

   cursor C_PWH_STATUS is
      select 'x'
        from item_loc il,
             wh
       where wh.physical_wh = I_loc
         and il.loc         = wh.wh
         and il.item        = I_item
         and status        != 'A';

BEGIN
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if not SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                  L_mc_ind) then
      return FALSE;
   end if;
   if L_mc_ind = 'Y' then
      if not WH_ATTRIB_SQL.CHECK_PWH(O_error_message,
                                     L_flag,
                                     I_loc) then
         return FALSE;
      end if;
      if L_flag = TRUE then
         SQL_LIB.SET_MARK('OPEN', 'C_PWH_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
         open C_PWH_STATUS;
         SQL_LIB.SET_MARK('FETCH', 'C_PWH_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
         fetch C_PWH_STATUS into L_dummy;
         if C_PWH_STATUS%FOUND then
            O_status := NULL;
         else
            O_status := 'A';
         end if;
         SQL_LIB.SET_MARK('CLOSE', 'C_PWH_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
         close C_PWH_STATUS;
      else
         SQL_LIB.SET_MARK('OPEN', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
         open C_STATUS;
         SQL_LIB.SET_MARK('FETCH', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
         fetch C_STATUS into O_status;
         SQL_LIB.SET_MARK('CLOSE', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
         if C_STATUS%NOTFOUND then
            close C_STATUS;
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
            --Following RIB error message has modified as the part of Performance issue.
            /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                              NULL, NULL);*/
            --RIB error message enhancement start
            O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                                  I_item,
                                                  I_Loc,
                                                  NULL);
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
            return FALSE;
         end if;
         close C_STATUS;
      end if;
   else
      SQL_LIB.SET_MARK('OPEN', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
      open C_STATUS;
      SQL_LIB.SET_MARK('FETCH', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
      fetch C_STATUS into O_status;
      SQL_LIB.SET_MARK('CLOSE', 'C_STATUS', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||I_loc);
      if C_STATUS%NOTFOUND then
         close C_STATUS;
         -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
         --Following RIB error message has modified as the part of Performance issue.
         /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', NULL,
                                           NULL, NULL);*/
         --RIB error message enhancement start
         O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                               I_item,
                                               I_Loc,
                                               NULL);
         -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
         return FALSE;
      end if;
      close C_STATUS;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEMLOC_STATUS;
-----------------------------------------------------------------------------------------
FUNCTION GET_AV_UNIT_COST(O_error_message   IN OUT VARCHAR2,
                          O_av_cost         IN OUT item_loc_soh.av_cost%TYPE,
                          O_unit_cost       IN OUT item_loc_soh.unit_cost%TYPE,
                          I_item            IN     item_loc_soh.item%TYPE,
                          I_loc             IN     item_loc_soh.loc%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR(64) := 'ITEMLOC_ATTRIB_SQL.GET_AV_UNIT_COST';

   cursor C_COST is
      select av_cost,
             unit_cost
        from item_loc_soh
       where loc = I_loc
         and item = I_item;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item', 'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc', 'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_COST', 'ITEM_LOC_SOH', 'Item: ' ||I_item||' Loc: '||I_loc);
   open C_COST;
   SQL_LIB.SET_MARK('FETCH', 'C_COST', 'ITEM_LOC_SOH', 'Item: ' ||I_item||' Loc: '||I_loc);
   fetch C_COST into O_av_cost,O_unit_cost;
   SQL_LIB.SET_MARK('CLOSE', 'C_COST', 'ITEM_LOC_SOH', 'Item: ' ||I_item||' Loc: '||I_loc);
   close C_COST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_AV_UNIT_COST;
---------------------------------------------------------------------------------
FUNCTION GET_RECEIVE_AS_TYPE(O_error_message   IN OUT VARCHAR2,
                             O_receive_as_type IN OUT item_loc.receive_as_type%TYPE,
                             I_item            IN     item_loc.item%TYPE,
                             I_loc             IN     item_loc.loc%TYPE)
RETURN BOOLEAN is

   L_program VARCHAR2(50) := 'ITEMLOC_ATTRIB_SQL.GET_RECEIVE_AS_TYPE';
   L_loc_type    VARCHAR2(2);
   L_flag        BOOLEAN;
   L_name        WH.WH_NAME%TYPE;

   cursor C_GET_RECEIVE_AS_TYPE is
      select NVL(receive_as_type, 'P')
        from item_loc
       where item = I_item
         and loc  = I_loc;

BEGIN
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM',
                                           'I_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM',
                                           'I_loc',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;
   ---
   if (LOCATION_ATTRIB_SQL.GET_TYPE(O_error_message,
                                    L_loc_type,
                                    I_loc) = FALSE ) then
      return( FALSE );
   end if;
   ---
   if L_loc_type = 'W' then
      if (WH_ATTRIB_SQL.CHECK_FINISHER(O_error_message,
                         L_flag,
                         L_name,
                         I_loc) = FALSE ) then
         return FALSE;
      end if;
      if L_flag then
         L_loc_type := 'I';
      end if;
   end if;
   ---
   if L_loc_type = 'W' then
      SQL_LIB.SET_MARK('OPEN', 'C_GET_RECEIVE_AS_TYPE', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      open C_GET_RECEIVE_AS_TYPE;
      SQL_LIB.SET_MARK('FETCH', 'C_GET_RECEIVE_AS_TYPE', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      fetch C_GET_RECEIVE_AS_TYPE into O_receive_as_type;
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_RECEIVE_AS_TYPE', 'ITEM_LOC', 'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      close C_GET_RECEIVE_AS_TYPE;
   else
   -- If the location is an Internal Finisher, External Finisher or Store always receive the pack as Eaches
      O_receive_as_type := 'E';
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
END GET_RECEIVE_AS_TYPE;
-----------------------------------------------------------------------------------
FUNCTION NON_ACTIVE_STORES_EXIST(O_error_message   IN OUT   VARCHAR2,
                                 O_exist           IN OUT   BOOLEAN,
                                 I_item            IN       ITEM_LOC.ITEM%TYPE,
                                 I_type            IN       CODE_DETAIL.CODE%TYPE,
                                 I_value           IN       VARCHAR2)
RETURN BOOLEAN IS
   L_program   VARCHAR2(50)   := 'ITEMLOC_ATTRIB_SQL.NON_ACTIVE_STORES_EXIST';
   L_dummy     VARCHAR2(1)    := 'N';

   cursor C_CHECK_ALL_STORE is
      select 'Y'
        from item_loc
       where item = I_item
         and loc_type = 'S'
         and status in ('I','C','D');     -- check for inactive, discontinued or deleted

   cursor C_CHECK_STORE is
      select 'Y'
        from item_loc
       where item = I_item
         and loc_type = 'S'
         and status in ('I','C','D')
         and loc = I_value;

   cursor C_CHECK_STORE_CLASS is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'S'
         and il.status in ('I','C','D')
         and exists
             (select 'x'
                from store s
               where s.store_class = I_value
                 and il.loc = s.store);

   cursor C_CHECK_DISTRICT is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'S'
         and il.status in ('I','C','D')
         and exists
             (select 'x'
                from store_hierarchy sh
               where sh.district = I_value
                 and sh.store = il.loc);

   cursor C_CHECK_REGION is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'S'
         and il.status in ('I','C','D')
         and exists
             (select 'x'
                from store_hierarchy sh
               where sh.region = I_value
                 and sh.store = il.loc);

   cursor C_CHECK_TRANSFER_ZONE is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'S'
         and il.status in ('I','C','D')
         and exists
             (select 'x'
                from store s
               where s.transfer_zone = I_value
                 and s.store = il.loc);

   cursor C_CHECK_LOC_TRAIT is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'S'
         and il.status in ('I','C','D')
         and exists
             (select 'x'
                from loc_traits_matrix l
               where l.loc_trait = I_value
                 and l.store = il.loc);

   cursor C_CHECK_LOC_LIST is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'S'
         and il.status in ('I','C','D')
         and exists
             (select 'x'
                from loc_list_detail lld
               where il.loc = lld.location
                 and lld.loc_list = I_value
                 and lld.loc_type = 'S');

   cursor C_CHECK_AREA is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'S'
         and il.status in ('I','C','D')
         and exists
             (select 'x'
                from store_hierarchy sh
               where sh.area = I_value
                 and sh.store = il.loc);

BEGIN
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM_IN_FUNC',
                                           'I_item',
                                           'NULL',
                                           L_program);
      return FALSE;
   end if;
   O_exist := FALSE;
   if I_type = 'S' then
      open C_CHECK_STORE;
      fetch C_CHECK_STORE into L_dummy;
      if C_CHECK_STORE%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_STORE;

   elsif I_type = 'C' then
      open C_CHECK_STORE_CLASS;
      fetch C_CHECK_STORE_CLASS into L_dummy;
      if C_CHECK_STORE_CLASS%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_STORE_CLASS;

   elsif I_type = 'D' then
      open C_CHECK_DISTRICT;
      fetch C_CHECK_DISTRICT into L_dummy;
      if C_CHECK_DISTRICT%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_DISTRICT;

   elsif I_type = 'R' then
      open C_CHECK_REGION;
      fetch C_CHECK_REGION into L_dummy;
      if C_CHECK_REGION%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_REGION;


   elsif I_type = 'T' then
      open C_CHECK_TRANSFER_ZONE;
      fetch C_CHECK_TRANSFER_ZONE into L_dummy;
      if C_CHECK_TRANSFER_ZONE%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_TRANSFER_ZONE;

   elsif I_type = 'L' then
      open C_CHECK_LOC_TRAIT;
      fetch C_CHECK_LOC_TRAIT into L_dummy;
      if C_CHECK_LOC_TRAIT%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_LOC_TRAIT;

   elsif I_type = 'AS' then
      open C_CHECK_ALL_STORE;
      fetch C_CHECK_ALL_STORE into L_dummy;
      if C_CHECK_ALL_STORE%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_ALL_STORE;

   elsif I_type = 'LLS' then
      open C_CHECK_LOC_LIST;
      fetch C_CHECK_LOC_LIST into L_dummy;
      if C_CHECK_LOC_LIST%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_LOC_LIST;

   elsif I_type = 'A' then
      SQL_LIB.SET_MARK ('OPEN',
                        'C_CHECK_AREA',
                        'AREA',
                        I_value);
      open C_CHECK_AREA;

      SQL_LIB.SET_MARK ('FETCH',
                        'C_CHECK_AREA',
                        'AREA',
                        I_value);
      fetch C_CHECK_AREA into L_dummy;
      if C_CHECK_AREA%FOUND then
         O_exist := TRUE;
      end if;

      SQL_LIB.SET_MARK ('OPEN',
                        'C_CHECK_AREA',
                        'AREA',
                        I_value);
      close C_CHECK_AREA;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END NON_ACTIVE_STORES_EXIST;
---------------------------------------------------------------------------------
FUNCTION NON_ACTIVE_WH_EXIST(O_error_message IN OUT VARCHAR2,
                             O_exist         IN OUT BOOLEAN,
                             I_item          IN     ITEM_LOC.ITEM%TYPE,
                             I_type          IN     CODE_DETAIL.CODE%TYPE,
                             I_value         IN     VARCHAR2)
RETURN BOOLEAN IS
   L_program VARCHAR2(50) := 'ITEMLOC_ATTRIB_SQL.NON_ACTIVE_STORES_EXIST';
   L_dummy   VARCHAR2(1)  := 'N';

   cursor C_CHECK_WH is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'W'
         and il.status in ('I','C','D')
         and il.loc = I_value;

   cursor C_CHECK_ALL_WH is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'W'
         and il.status in ('I','C','D');

   cursor C_CHECK_LOCLIST_WH is
      select 'Y'
        from item_loc il
       where il.item = I_item
         and il.loc_type = 'W'
         and il.status in ('I','C','D')
         and exists (select 'x'
                       from loc_list_detail lld
                      where il.loc = lld.location
                        and lld.loc_list = I_value
                        and lld.loc_type = 'W');

BEGIN
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM_IN_FUNC',
                                           'I_item',
                                           'NULL',
                                           L_program);
      return FALSE;
   end if;

   O_exist := FALSE;

   if I_type = 'W' or I_type = 'DW' then
      open C_CHECK_WH;
      fetch C_CHECK_WH into L_dummy;
      if C_CHECK_WH%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_WH;

   elsif I_type = 'AW' then
      open C_CHECK_ALL_WH;
      fetch C_CHECK_ALL_WH into L_dummy;
      if C_CHECK_ALL_WH%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_ALL_WH;

   elsif I_type = 'LLW' then
      open C_CHECK_LOCLIST_WH;
      fetch C_CHECK_LOCLIST_WH into L_dummy;
      if C_CHECK_LOCLIST_WH%FOUND then
         O_exist := TRUE;
      end if;
      close C_CHECK_LOCLIST_WH;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END NON_ACTIVE_WH_EXIST;
---------------------------------------------------------------------------------
FUNCTION INT_FINISHER_EXIST(O_error_message IN OUT VARCHAR2,
                            O_exist         IN OUT BOOLEAN,
                            I_item          IN     ITEM_LOC.ITEM%TYPE,
                            I_location      IN     ITEM_LOC.LOC%TYPE,
                            I_value         IN     CODE_DETAIL.CODE%TYPE DEFAULT 'W')
RETURN BOOLEAN IS

   L_program            VARCHAR2(50) := 'ITEMLOC_ATTRIB_SQL.INT_FINISHER_EXIST';
   L_exist              VARCHAR2(1) := 'N';

   cursor C_finisher_exist is
      select 'Y'
        from item_loc il,
             wh
       where il.loc = wh.wh
         and wh.finisher_ind = 'Y'
         and il.item = I_item
         and il.loc = I_location;
   cursor C_finisher_exist_aw is
      select 'Y'
        from item_loc il,
             wh
       where il.loc = wh.wh
         and wh.finisher_ind = 'Y'
         and il.item = I_item;
   cursor C_finisher_exist_llw is
        select 'Y'
          from item_loc il,
               wh
         where il.loc = wh.wh
           and wh.finisher_ind = 'Y'
           and il.item = I_item
         and il.loc in (select location
                          from loc_list_detail lld
                         where il.loc = lld.location
                           and lld.loc_list = I_location
                           and lld.loc_type = 'W');
BEGIN
   ---
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_item',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   ---
   if I_value in ('W', 'DW') then
      open C_finisher_exist;
      fetch C_finisher_exist into L_exist;
      close C_finisher_exist;
   elsif I_value = 'AW' then
       open C_finisher_exist_aw;
      fetch C_finisher_exist_aw into L_exist;
      close C_finisher_exist_aw;
   elsif I_value = 'LLW' then
       open C_finisher_exist_llw;
      fetch C_finisher_exist_llw into L_exist;
      close C_finisher_exist_llw;
   end if;
   ---
   if L_exist = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
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
END INT_FINISHER_EXIST;
--------------------------------------------------------------------------------
FUNCTION GET_ITEMLOC_INFO(O_error_message IN OUT VARCHAR2,
                          O_itemloc       IN OUT ITEM_LOC%ROWTYPE,
                          I_item          IN     ITEM_LOC.ITEM%TYPE,
                          I_loc           IN     ITEM_LOC.LOC%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(50) := 'ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO';

   cursor C_GET_ITEMLOC is
      select *
        from item_loc
       where item = I_item
         and loc = I_loc;
BEGIN
   ---
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_item',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   ---
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_loc',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   ---
   open C_GET_ITEMLOC;
   fetch C_GET_ITEMLOC into O_itemloc;
   ---
   if C_GET_ITEMLOC%NOTFOUND then
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC',
                                           NULL,
                                           NULL,
                                           NULL);*/
      --RIB error message enhancement start
      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                            I_item,
                                            I_Loc,
                                            NULL);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      close C_GET_ITEMLOC;
      return FALSE;
   end if;
   ---
   close C_GET_ITEMLOC;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_ITEMLOC_INFO;
----------------------------------------------------------------------------------
FUNCTION COMP_UNIT_REATIL_EXIST(O_error_message IN OUT VARCHAR2,
                                O_exist         IN OUT BOOLEAN,
                                I_pack_no       IN     ITEM_LOC.ITEM%TYPE,
                                I_loc           IN     ITEM_LOC.LOC%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(50) := 'ITEMLOC_ATTRIB_SQL.COMP_UNIT_REATIL_EXIST';
   L_exist              VARCHAR2(1) := 'N';

   cursor C_comp_unit_retail is
      select 'Y'
        from v_packsku_qty v
       where v.pack_no = I_pack_no
         and exists (select 'x'
                       from item_loc il
                      where il.item = v.item
                        and il.loc = I_loc
                        and nvl(il.unit_retail,0) = 0);
BEGIN
   ---
   if I_pack_no is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_pack_no',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   ---
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_loc',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   ---
   open C_comp_unit_retail;
   fetch C_comp_unit_retail into L_exist;
   close C_comp_unit_retail;
   ---
   if L_exist = 'Y' then
      O_exist := FALSE;
   else
      O_exist := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END COMP_UNIT_REATIL_EXIST;
----------------------------------------------------------------------------------
FUNCTION GET_RETAIL_COST(O_error_message        IN OUT rtk_errors.rtk_text%TYPE,
                         O_retail_cost  IN OUT item_loc_soh.unit_cost%TYPE,
                         I_item           IN     item_loc.item%TYPE,
                         I_dept           IN     deps.dept%TYPE,
                         I_class          IN     class.class%TYPE,
                         I_subclass       IN     subclass.subclass%TYPE,
                         I_loc            IN     item_loc.loc%TYPE,
                         I_loc_type     IN     item_loc.loc_type%TYPE,
                         I_tran_date      IN     DATE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEMLOC_ATTRIB_SQL.GET_RETAIL_COST';

   L_unit_retail        ITEM_LOC.UNIT_RETAIL%TYPE;
   L_cum_markon_pct     WEEK_DATA.CUM_MARKON_PCT%TYPE;

   -- dummy
   L_av_cost                    ITEM_LOC_SOH.AV_COST%TYPE;
   L_unit_cost                  ITEM_LOC_SOH.UNIT_COST%TYPE;
   L_selling_unit_retail        ITEM_LOC.SELLING_UNIT_RETAIL%TYPE;
   L_selling_uom                ITEM_LOC.SELLING_UOM%TYPE;
   L_stock_on_hand            ITEM_LOC_SOH.STOCK_ON_HAND%TYPE;
   L_pack_comp_soh              ITEM_LOC_SOH.PACK_COMP_SOH%TYPE;

BEGIN
   -- This function will return the unit cost of an item/loc if retail accounting is used.

   -- for a non-sellable pack, base the unit retail on component unit retail
   if GET_DETAILS(O_error_message,
                  I_item,
                  I_loc,
                  I_loc_type,
                  'N',                    /* cost ind */
                  'Y',                    /* retail ind */
                  'N',                    /* stock ind */
                  'Y',                    /* nonsellable_pack_retail_ind */
                  L_av_cost,
                  L_unit_cost,
                  L_unit_retail,
                  L_selling_unit_retail,
                  L_selling_uom,
                  L_stock_on_hand,
                  L_pack_comp_soh) = FALSE then
      return FALSE;
   end if;

   -- get cumulative mark-on% from week_data and month_data
   if not STKLEDGR_QUERY_SQL.GET_CUM_MARKON_PCT(O_error_message,
                                                L_cum_markon_pct,
                                                I_dept,
                                                I_class,
                                                I_subclass,
                                                I_loc,
                                                I_loc_type,
                                                I_tran_date) then
      return FALSE;
   end if;

   if L_cum_markon_pct is not NULL then
      O_retail_cost := L_unit_retail * (1-L_cum_markon_pct/100);
   else
      -- cum_markon_pct does not exist yet (new dept/class/subclass).  Use actual cost since it's
      -- more accurate.
      O_retail_cost := NULL;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_RETAIL_COST;
----------------------------------------------------------------------------------
FUNCTION GET_WAC(O_error_message         IN OUT rtk_errors.rtk_text%TYPE,
                 O_wac                   IN OUT item_loc_soh.unit_cost%TYPE,
                 I_item                  IN     item_loc.item%TYPE,
                 I_dept                  IN     item_master.dept%TYPE,
                 I_class                 IN     item_master.class%TYPE,
                 I_subclass              IN     item_master.subclass%TYPE,
                 I_loc                   IN     item_loc.loc%TYPE,
                 I_loc_type              IN     item_loc.loc_type%TYPE,
                 I_tran_date             IN     DATE,
                 I_alt_loc               IN     item_loc.loc%TYPE default NULL,
                 I_alt_loc_type          IN     item_loc.loc_type%TYPE default NULL)
RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEMLOC_ATTRIB_SQL.GET_WAC';

   L_profit_type        deps.profit_calc_type%TYPE;
   L_markup_type        deps.markup_calc_type%TYPE;

   L_loc          item_loc.loc%TYPE;
   L_loc_type     item_loc.loc_type%TYPE;
   L_std_av_ind   system_options.std_av_ind%TYPE;
   L_av_cost    ITEM_LOC_SOH.AV_COST%TYPE;
   L_unit_cost    ITEM_LOC_SOH.UNIT_COST%TYPE;

   -- dummy
   L_unit_retail            ITEM_LOC.UNIT_RETAIL%TYPE;
   L_selling_unit_retail    ITEM_LOC.SELLING_UNIT_RETAIL%TYPE;
   L_selling_uom            ITEM_LOC.SELLING_UOM%TYPE;
   L_stock_on_hand          ITEM_LOC_SOH.STOCK_ON_HAND%TYPE;
   L_pack_comp_soh          ITEM_LOC_SOH.PACK_COMP_SOH%TYPE;

BEGIN
   -- This function returns the WAC for I_item/I_loc based on accounting methods.
   -- Since unit_retail is not defined at External Finishers (loc type of 'E'),
   -- when retail accounting is used, the unit_retail at the alternative location
   -- (I_alt_loc) is used. This is for the scenario of a 2-legged transfer where
   -- the second leg is from an External Finisher to a store or a wh.

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_item',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_loc',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   if I_loc_type is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_loc_type',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   if I_dept is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_dept',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   if I_class is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_class',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   if I_subclass is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_subclass',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   if not DEPT_ATTRIB_SQL.GET_ACCTNG_METHODS(O_error_message,
                                             I_dept,
                                             L_profit_type,
                                             L_markup_type) then
      return FALSE;
   end if;

   if I_loc_type = 'E' and L_profit_type = 2 then
      if I_alt_loc is NULL then
         O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                              'I_alt_loc',
                                              L_program,
                                              NULL);
         return FALSE;
      end if;

      if I_alt_loc_type is NULL then
         O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                              'I_alt_loc_type',
                                              L_program,
                                              NULL);
         return FALSE;
      end if;

      if I_alt_loc_type not in ('S', 'W') then
         O_error_message:= SQL_LIB.CREATE_MSG('INV_LOC_TYPE',
                                              NULL,
                                              NULL,
                                              NULL);
         return FALSE;
      end if;

      -- for External finisher and retail accounting, use alternative location
      L_loc := I_alt_loc;
      L_loc_type := I_alt_loc_type;
   else
      L_loc := I_loc;
      L_loc_type := I_loc_type;
   end if;

   if L_profit_type = 2 then
      -- retail accounting
      -- WAC should be the unit_retail on ITEM_LOC * (1-cumulative mark-on%)
      if not GET_RETAIL_COST(O_error_message,
                             O_wac,
                             I_item,
                             I_dept,
                             I_class,
                             I_subclass,
                             L_loc,
                             L_loc_type,
                             I_tran_date) then
         return FALSE;
      end if;
   end if;

   -- O_wac is null when cum_markon_pct does not exist yet (new dept/class/subclass).
   -- Use actual cost since it's more accurate.

   if L_profit_type = 1 or O_wac is NULL then
      -- cost accounting
      if GET_DETAILS(O_error_message,
                     I_item,
                     L_loc,
                     L_loc_type,
                     'Y',                    /* cost ind */
                     'N',                    /* retail ind */
                     'N',                    /* stock ind */
                     'N',                    /* nonsellable_pack_retail_ind */
                     L_av_cost,
                     L_unit_cost,
                     L_unit_retail,          -- dummy
                     L_selling_unit_retail,  -- dummy
                     L_selling_uom,          -- dummy
                     L_stock_on_hand,        -- dummy
                     L_pack_comp_soh) = FALSE then   -- dummy
         return FALSE;
      end if;

      if not SYSTEM_OPTIONS_SQL.STD_AV_IND(O_error_message,
                                           L_std_av_ind) then
         return FALSE;
      end if;

      if L_std_av_ind = 'A' then
         -- average cost accounting
         -- WAC should be the av_cost on ITEM_LOC_SOH
         O_wac := L_av_cost;
      else  -- 'S'
         -- standard cost accounting
         -- WAC should be the unit_cost on ITEM_LOC_SOH
         O_wac := L_unit_cost;
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
END GET_WAC;
----------------------------------------------------------------------------------
FUNCTION GET_AVERAGE_WEIGHT(O_error_message         IN OUT rtk_errors.rtk_text%TYPE,
                            O_average_weight        IN OUT item_loc_soh.unit_cost%TYPE,
                            I_item                  IN     item_loc.item%TYPE,
                            I_loc                   IN     item_loc.loc%TYPE,
                            I_loc_type              IN     item_loc.loc_type%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEMLOC_ATTRIB_SQL.GET_AVERAGE_WEIGHT';
   -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
   L_catch_weight_ind      ITEM_MASTER.CATCH_WEIGHT_IND%TYPE := NULL;
   L_standard_uom          ITEM_MASTER.STANDARD_UOM%TYPE;
   -- 29-Oct-2008 TESCO HSC/Murali 6907185 End

   cursor C_avg_weight is
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
      select ils.average_weight,
             im.catch_weight_ind,
             im.standard_uom
        from item_loc_soh ils,item_master im
       where ils.item = im.item
         and ils.item = I_item
         and loc = I_loc;
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 End

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_item',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   ---
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_loc',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   ---
   -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
   -- 29-Oct-2008 TESCO HSC/Murali 6907185 End

   open C_avg_weight;
   -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
   fetch C_avg_weight into O_average_weight,L_catch_weight_ind,L_standard_uom;
   -- 29-Oct-2008 TESCO HSC/Murali 6907185 End
   close C_avg_weight;

   if O_average_weight is NULL then
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
      if L_catch_weight_ind = 'Y' and L_standard_uom = 'EA' then
         if not ITEM_SUPP_COUNTRY_DIM_SQL.GET_NOMINAL_WEIGHT(O_error_message,
                                                       O_average_weight,
                                                       I_item) then
            return FALSE;
         end if;
      else
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 End
         O_error_message:= SQL_LIB.CREATE_MSG('AVG_WEIGHT_NOT_FOUND',
                                              I_item,
                                              I_loc,
                                              NULL);
         return FALSE;
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 Begin
      end if;
      -- 29-Oct-2008 TESCO HSC/Murali 6907185 End
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_AVERAGE_WEIGHT;
----------------------------------------------------------------------------------
FUNCTION VALID_DEAL_ITEM(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid           IN OUT BOOLEAN,
                         I_item            IN     ITEM_LOC.ITEM%TYPE,
                         I_loc             IN     ITEM_LOC.LOC%TYPE,
                         I_loc_type        IN     ITEM_LOC.LOC_TYPE%TYPE,
                         I_merch_lvl       IN     CODE_DETAIL.CODE%TYPE,
                         I_diff            IN     ITEM_MASTER.DIFF_1%TYPE)
RETURN BOOLEAN IS

   L_program           VARCHAR2(50) := 'ITEMLOC_ATTRIB_SQL.VALID_DEAL_ITEM';
   L_itemloc_exists    BOOLEAN;
   L_status            VARCHAR2(1);
   L_multichannel_ind  SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;

   cursor C_GET_CHILD is
      select item
        from item_master
       where item_parent = I_item;

   cursor C_GET_VWH is
      select wh
        from wh
       where physical_wh = I_loc
         and physical_wh != wh;

   cursor C_GET_ITEMDIFF is
      select item
        from item_master
       where item_parent = I_item
         and ((diff_1 = I_diff and I_merch_lvl = '8')
          or  (diff_2 = I_diff and I_merch_lvl = '9')
          or  (diff_3 = I_diff and I_merch_lvl = '10')
          or  (diff_4 = I_diff and I_merch_lvl = '11'));

   cursor C_GET_MULTICHANNEL_IND is
      select multichannel_ind
	    from system_options;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_loc',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_loc_type',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_merch_lvl is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_merch_lvl',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_MULTICHANNEL_IND','SYSTEM_OPTIONS', 'Item: ' ||I_item||' Loc: '||to_char(I_loc));
   open C_GET_MULTICHANNEL_IND;
   SQL_LIB.SET_MARK('FETCH','C_GET_MULTICHANNEL_IND','SYSTEM_OPTIONS', 'Item: ' ||I_item||' Loc: '||to_char(I_loc));
   fetch C_GET_MULTICHANNEL_IND into L_multichannel_ind;
   SQL_LIB.SET_MARK('CLOSE','C_GET_MULTICHANNEL_IND','SYSTEM_OPTIONS', 'Item: ' ||I_item||' Loc: '||to_char(I_loc));
   close C_GET_MULTICHANNEL_IND;

   O_valid := FALSE;

   if I_merch_lvl = '12' then -- validate item
      if I_loc_type = 'S' then
         if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(O_error_message,
                                              I_item,
                                              I_loc,
                                              L_itemloc_exists) = FALSE then
            return FALSE;
         end if;
         ---
         if L_itemloc_exists then
            if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(O_error_message,
                                              I_item,
                                              I_loc,
                                              L_status) = FALSE then
               return FALSE;
            end if;
            ---
            if L_status != 'I' then
               O_valid := TRUE;
            end if;
         end if;
      elsif I_loc_type = 'W' then
         if L_multichannel_ind = 'N' then
		    if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(O_error_message,
                                                 I_item,
                                                 I_loc,
                                                 L_itemloc_exists) = FALSE then
               return FALSE;
            end if;
            ---
            if L_itemloc_exists then
               if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(O_error_message,
                                                 I_item,
                                                 I_loc,
                                                 L_status) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_status != 'I' then
                  O_valid := TRUE;
               end if;
            end if;
		 else
		    FOR rec IN C_GET_VWH LOOP
               if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(O_error_message,
                                                    I_item,
                                                    rec.wh,
                                                    L_itemloc_exists) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_itemloc_exists then
                  if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(O_error_message,
                                                    I_item,
                                                    rec.wh,
                                                    L_status) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if L_status != 'I' then
                     O_valid := TRUE;
                     exit;
                  end if;
               end if;
            END LOOP;
		 end if;
      end if;
   elsif I_merch_lvl = '7' then -- validate item parent
      if I_loc_type = 'S' then
         FOR rec IN C_GET_CHILD LOOP
            if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(O_error_message,
                                                 rec.item,
                                                 I_loc,
                                                 L_itemloc_exists) = FALSE then
               return FALSE;
            end if;
            ---
            if L_itemloc_exists then
               if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(O_error_message,
                                                 rec.item,
                                                 I_loc,
                                                 L_status) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_status != 'I' then
                  O_valid := TRUE;
                  exit;
               end if;
            end if;
         END LOOP;
      elsif I_loc_type = 'W' then
         FOR rec_item IN C_GET_CHILD LOOP
            if L_multichannel_ind = 'N' then
		       if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(O_error_message,
                                                    I_item,
                                                    I_loc,
                                                    L_itemloc_exists) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_itemloc_exists then
                  if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(O_error_message,
                                                    I_item,
                                                    I_loc,
                                                    L_status) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if L_status != 'I' then
                     O_valid := TRUE;
                  end if;
               end if;
		    else
			   FOR rec_vwh IN C_GET_VWH LOOP
                  if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(O_error_message,
                                                       rec_item.item,
                                                       rec_vwh.wh,
                                                       L_itemloc_exists) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if L_itemloc_exists then
                     if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(O_error_message,
                                                       rec_item.item,
                                                       rec_vwh.wh,
                                                       L_status) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if L_status != 'I' then
                        O_valid := TRUE;
                        exit;
                     end if;
                  end if;
               END LOOP;
			end if;
         END LOOP;
      end if;
   elsif I_merch_lvl in ('8','9','10','11') then
      if I_diff is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                               'I_diff',
                                               L_program,
                                               NULL);
         return FALSE;
      end if;
      ---
      if I_loc_type = 'S' then
         FOR rec IN C_GET_ITEMDIFF LOOP
            if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(O_error_message,
                                                 rec.item,
                                                 I_loc,
                                                 L_itemloc_exists) = FALSE then
               return FALSE;
            end if;
            ---
            if L_itemloc_exists then
               if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(O_error_message,
                                                 rec.item,
                                                 I_loc,
                                                 L_status) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_status != 'I' then
                  O_valid := TRUE;
                  exit;
               end if;
               ---
            end if;
         END LOOP;
      elsif I_loc_type = 'W' then
         FOR rec_item IN C_GET_ITEMDIFF LOOP
            if L_multichannel_ind = 'N' then
		       if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(O_error_message,
                                                    I_item,
                                                    I_loc,
                                                    L_itemloc_exists) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_itemloc_exists then
                  if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(O_error_message,
                                                    I_item,
                                                    I_loc,
                                                    L_status) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if L_status != 'I' then
                     O_valid := TRUE;
                  end if;
               end if;
		    else
			   FOR rec_vwh IN C_GET_VWH LOOP
                  if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(O_error_message,
                                                       rec_item.item,
                                                       rec_vwh.wh,
                                                       L_itemloc_exists) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if L_itemloc_exists then
                     if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(O_error_message,
                                                       rec_item.item,
                                                       rec_vwh.wh,
                                                       L_status) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if L_status != 'I' then
                        O_valid := TRUE;
                        exit;
                     end if;
                     ---
                  end if;
               END LOOP;
			end if;
         END LOOP;
      end if;
   end if;
   ---
   if NOT L_itemloc_exists then
      O_error_message := SQL_LIB.CREATE_MSG('SKU_LOC_NOT_EXIST',
                                            NULL,
                                            NULL,
                                            NULL);
   elsif L_status = 'I' then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEMLOC_STAT',
                                            NULL,
                                            NULL,
                                            NULL);
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALID_DEAL_ITEM;
----------------------------------------------------------------------------------
END ITEMLOC_ATTRIB_SQL;
/

