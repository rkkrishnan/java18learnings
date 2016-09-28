CREATE OR REPLACE PACKAGE BODY ITEM_SUPP_COUNTRY_DIM_SQL AS
----------------------------------------------------------------------------------------------------
-- Mod By     : Wipro Enabler/Dhuraison Prince                                                    --
-- Mod Date   : 06-Feb-2008                                                                       --
-- Mod Ref    : Mod N114                                                                          --
-- Mod Details: Amended script to get the gross weight of the pack as well as items in the pack.  --
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Mod By     : Wipro Enabler/Karthik Dhanapal                                                    --
-- Mod Date   : 12-Jun-2008                                                                       --
-- Mod Ref    : Defect NBS00007117                                                                --
-- Mod Details: Added New Functions TSL_INSERT_UPDATE_CA_DIM and TSL_DELETE_CA_DIM.               --
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--Function Name: GET_ROW
--Purpose      : This function retrieves item dimensions information required
--               in the calculation of Cost Per UOM.
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Mod By       : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
-- Mod Date     : 06-March-2009
-- Mod Ref      : NBS00011236
-- Mod Details  : Added new function TSL_GET_DEFAULT_WEIGHT_UOM
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Mod By       : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date     : 16-Dec-2009
-- Mod Ref      : CR236a
-- Mod Details  : Added new function TSL_GET_EACH_WT
----------------------------------------------------------------------------------------------------
-- Mod By       : Sourabh Sharva
-- Mod Date     : 21-Dec-2010
-- Mod Ref      : Def20038
-- Mod Details  : Modified method GET_NOMINAL_WEIGHT() to publish the proper item id
----------------------------------------------------------------------------------------------------
FUNCTION GET_ROW(O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                 O_exists                  IN OUT   BOOLEAN,
                 O_item_supp_country_dim   IN OUT   ITEM_SUPP_COUNTRY_DIM%ROWTYPE,
                 I_item                    IN       ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                 I_supplier                IN       ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                 I_origin_country          IN       ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                 I_dim_object              IN       ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE)

   RETURN BOOLEAN IS

   L_program   VARCHAR2(62) := 'ITEM_SUPP_COUNTRY_DIM_SQL.GET_ROW';

   cursor C_GET_ROW is
   select *
     from item_supp_country_dim
    where item           = I_item
      and supplier       = I_supplier
      and origin_country = I_origin_country
      and dim_object     = I_dim_object;


BEGIN

   O_item_supp_country_dim := NULL;

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      O_exists := FALSE;
      return TRUE;
   end if;

   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_supplier',
                                             L_program,
                                             NULL);
      O_exists := FALSE;
      return TRUE;
   end if;

   if I_origin_country is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_origin_country',
                                             L_program,
                                             NULL);
      O_exists := FALSE;
      return TRUE;
   end if;

   if I_dim_object is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_dim_object',
                                             L_program,
                                             NULL);
      O_exists := FALSE;
      return TRUE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ROW',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'Item: '||I_item ||'Supplier: '||to_char(I_supplier)||'Origin_country: '||I_origin_country||
                    'Dim_object: '||I_dim_object);
   open C_GET_ROW;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ROW',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'Item: '||I_item ||'Supplier: '||to_char(I_supplier)||'Origin_country: '||I_origin_country||
                    'Dim_object: '||I_dim_object);
   fetch C_GET_ROW into O_item_supp_country_dim;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ROW',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'Item: '||I_item ||'Supplier: '||to_char(I_supplier)||'Origin_country: '||I_origin_country||
                    'Dim_object: '||I_dim_object);
   close C_GET_ROW;

   O_exists := (O_item_supp_country_dim.item is NOT NULL);

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_ROW;
-------------------------------------------------------------------------------
FUNCTION GET_NOMINAL_WEIGHT(O_error_message IN OUT VARCHAR2,
                            O_weight_cuom   IN OUT item_supp_country_dim.net_weight%TYPE,
                            I_item          IN     item_master.item%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_DIM_SQL.GET_NOMINAL_WEIGHT';

   L_net_weight        item_supp_country_dim.net_weight%TYPE := NULL;
   L_weight_uom        item_supp_country_dim.weight_uom%TYPE := NULL;
   L_supp_pack_size    item_supp_country.supp_pack_size%TYPE := NULL;
   L_nominal_weight    item_supp_country_dim.net_weight%TYPE := NULL;
   L_cuom              item_supp_country.cost_uom%TYPE;

   cursor C_WEIGHT is
      select iscd.net_weight,
             iscd.weight_uom,
             isc.supp_pack_size
        from item_supp_country_dim iscd,
             item_supp_country isc
       where isc.item = iscd.item
         and isc.supplier = iscd.supplier
         and isc.origin_country_id = iscd.origin_country
         and iscd.dim_object = 'CA'  -- case
         and iscd.item = I_item
         and primary_supp_ind = 'Y'
         and primary_country_ind = 'Y';

BEGIN
   ---
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           --Def20038 by Sourabh Sharva, start
                                           I_item,
                                           --Def20038 by Sourabh Sharva, End
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   ---
   open C_WEIGHT;
   fetch C_WEIGHT into L_net_weight, L_weight_uom, L_supp_pack_size;
   close C_WEIGHT;
   ---
   if L_net_weight is NULL or L_weight_uom is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('NOMINAL_WGT_NOT_FOUND',
                                           --Def20038 by Sourabh Sharva, start
                                           I_item,
                                           --Def20038 by Sourabh Sharva, end
                                           NULL,
                                           NULL);
      return FALSE;
   end if;
   ---
   -- ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT is for case; nominal weight is for eaches.
   L_nominal_weight := L_net_weight/L_supp_pack_size;
   ---
   if not CATCH_WEIGHT_SQL.CONVERT_WEIGHT(O_error_message,
                                          O_weight_cuom,
                                          L_cuom,
                                          I_item,
                                          L_nominal_weight,
                                          L_weight_uom) then
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
END GET_NOMINAL_WEIGHT;
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , Begin
-----------------------------------------------------------------------------------------------------------
FUNCTION TSL_ITEM_WEIGHT_CONV(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item	             IN       ITEM_MASTER.ITEM%TYPE,
                              I_weight             IN       ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                              O_item_new_gross_wgt    OUT   ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE)
RETURN BOOLEAN IS

   L_weight_uom          ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
   L_supplier            ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE;
   L_origin_country      ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE;
   L_default_weight_uom  SYSTEM_OPTIONS.DEFAULT_WEIGHT_UOM%TYPE;
   L_new_gross_weight    ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;


   L_program      VARCHAR(64)                       := 'ITEM_SUPP_COUNTRY_DIM_SQL.TSL_ITEM_WEIGHT_CONV';

   CURSOR C_GET_NEW_GROSS_WEIGHT(L_item IN ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE) is
   select weight_uom,
          supplier,
          origin_country
     from item_supp_country_dim i
    where i.item = L_item
      and (item,supplier,origin_country) in (select item,supplier,origin_country_id
                                               from item_supp_country
                                              where primary_supp_ind = 'Y'
                                                and primary_country_ind =  'Y'
                                                and item  = L_item)
      and i.dim_object ='EA';
BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   ---
   if SYSTEM_OPTIONS_SQL.TSL_GET_DEFAULT_WEIGHT_UOM(O_error_message,
                                                    L_default_weight_uom) = FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_NEW_GROSS_WEIGHT',
                    'item_supp_country_dim',
                    'item= ' || (I_item));
   open C_GET_NEW_GROSS_WEIGHT(I_item);

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_NEW_GROSS_WEIGHT',
                    'item_supp_country_dim',
                    'item= ' || (I_item));
   fetch C_GET_NEW_GROSS_WEIGHT into L_weight_uom,
                                     L_supplier,
                                     L_origin_country;

   IF C_GET_NEW_GROSS_WEIGHT%NOTFOUND THEN
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_NEW_GROSS_WEIGHT',
                       'item_supp_country_dim',
                       'item= ' || (I_item));
      close C_GET_NEW_GROSS_WEIGHT;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      ---
      O_item_new_gross_wgt := 0;
      ---
      return TRUE;
   END IF;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_NEW_GROSS_WEIGHT',
                    'item_supp_country_dim',
                    'item= ' || (I_item));
   close C_GET_NEW_GROSS_WEIGHT;

   if  L_default_weight_uom <> L_weight_uom  then
      if UOM_SQL.CONVERT(O_error_message,
                         L_new_gross_weight,
                         L_default_weight_uom,
                         I_weight,
                         L_weight_uom,
                         I_item,
                         L_supplier,
                         L_origin_country) = FALSE then
         return FALSE;
      end if;
      O_item_new_gross_wgt := L_new_gross_weight;
   elsif L_default_weight_uom = L_weight_uom  then
      O_item_new_gross_wgt := I_weight;
   end if;
   ---
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_GET_NEW_GROSS_WEIGHT%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_NEW_GROSS_WEIGHT',
                          'item_supp_country_dim',
                          'item= ' || (I_item));
         close C_GET_NEW_GROSS_WEIGHT;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_ITEM_WEIGHT_CONV;
-----------------------------------------------------------------------------------------------------------
---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , End
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - Begin
FUNCTION TSL_GET_WEIGHT_PACK(O_error_message        IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_pack_no	            IN       PACKITEM.PACK_NO%TYPE,
                             I_item	           			IN       ITEM_MASTER.ITEM%TYPE,
                             O_sum_item_gross_wgt      OUT	 ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                             O_pack_gross_wgt          OUT   ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR(64)                       := ' ITEM_SUPP_COUNTRY_DIM_SQL.TSL_GET_WEIGHT_PACK';
   L_item               PACKITEM.ITEM%TYPE;
   L_pack_qty           PACKITEM.PACK_QTY%TYPE;
   L_tot_weight         ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   L_sum_tot_weight     ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   L_weight             ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   L_exit               BOOLEAN                           := FALSE;
   ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , Begin
   L_weight1            ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   L_new_gross_weight   ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   L_weight2            ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   L_pack_gross_wgt     ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   L_new_pack_gross_wgt ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , End

   CURSOR C_GET_PACK_DTLS is
   select p.item,
          p.pack_qty
     from packitem p
    where p.pack_no = I_pack_no;

   CURSOR C_GET_GROSS_WEIGHT(L_item IN ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE) is
   select i.weight
     from item_supp_country_dim i
    where i.item = L_item
      and (i.item, i.supplier, i.origin_country) in (select isc.item, isc.supplier, isc.origin_country_id
                                                       from item_supp_country isc
                                                      where isc.primary_supp_ind = 'Y'
                                                        and isc.primary_country_ind = 'Y'
                                                        and isc.item  = L_item)
      and i.dim_object ='EA';

BEGIN
   if I_pack_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_pack_no',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   FOR C_rec in C_GET_PACK_DTLS
   LOOP
      --- NBS006253, John Alister Anand, 16-Apr-2007, Begin
      if C_rec.Item <> I_item then
      --- NBS006253, John Alister Anand, 16-Apr-2007, End
		      if C_rec.item is NULL then
		         -- closing the second cursor if its open due to previous run before terminating function
		         if C_GET_GROSS_WEIGHT%ISOPEN then
		            close C_GET_GROSS_WEIGHT;
		         end if;
		         -- function terminates if no items found
		         O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
		                                               NULL,
		                                               NULL,
		                                               NULL);
		         return FALSE;
		      end if;
		      -- item fetched from first cursor passed to second cursor
		      SQL_LIB.SET_MARK('OPEN',
		                       'C_GET_GROSS_WEIGHT',
		                       'item_supp_country_dim',
		                       'item= ' || (C_rec.item));
		      open C_GET_GROSS_WEIGHT(C_rec.item);
		      ---
		      -- fetching weight of the item
		      SQL_LIB.SET_MARK('FETCH',
		                       'C_GET_GROSS_WEIGHT',
		                       'item_supp_country_dim',
		                       'item= ' || (C_rec.item));
		      fetch C_GET_GROSS_WEIGHT into L_weight;
		      ---
		      -- closing the second cursor if no data found
		      if C_GET_GROSS_WEIGHT%NOTFOUND then
		         SQL_LIB.SET_MARK('CLOSE',
		                          'C_GET_GROSS_WEIGHT',
		                          'item_supp_country_dim',
		                          'item= ' || (C_rec.item));
		         close C_GET_GROSS_WEIGHT;
		         EXIT;
		      end if;
		      ---
		      ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , Begin
		      if L_weight is not NULL then
		         L_weight1 := L_weight;
		         if TSL_ITEM_WEIGHT_CONV(O_error_message,
                                     C_rec.item,
                                     L_weight1,
                                     L_new_gross_weight) = FALSE then
                return FALSE;
             end if;
             L_weight  :=  L_new_gross_weight;
          end if;
          ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , End

		      -- calculate total weight of items
		      L_tot_weight := NVL(L_weight,0) * C_rec.pack_qty;
		      L_sum_tot_weight := L_sum_tot_weight + L_tot_weight;
		      ---
		      SQL_LIB.SET_MARK('CLOSE',
		                       'C_GET_GROSS_WEIGHT',
		                       'item_supp_country_dim',
		                       'pack= ' || (I_pack_no));
		      close C_GET_GROSS_WEIGHT;
      --- NBS006253, John Alister Anand, 16-Apr-2007, Begin
      end if;
      --- NBS006253, John Alister Anand, 16-Apr-2007, End
   END LOOP;
   ---
   if C_GET_GROSS_WEIGHT%ISOPEN then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_GROSS_WEIGHT',
                       'item_supp_country_dim',
                       'pack= ' || (I_pack_no));
      close C_GET_GROSS_WEIGHT;
   end if;
   ---
   O_sum_item_gross_wgt := L_sum_tot_weight;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_GROSS_WEIGHT',
                    'item_supp_country_dim',
                    'pack= ' || (I_pack_no));
   open C_GET_GROSS_WEIGHT(I_pack_no);
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_GROSS_WEIGHT',
                    'item_supp_country_dim',
                    'pack= ' || (I_pack_no));
   fetch C_GET_GROSS_WEIGHT into L_pack_gross_wgt;
   ---
   IF C_GET_GROSS_WEIGHT%NOTFOUND THEN
      O_pack_gross_wgt := 0;
      return TRUE;
   END IF;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_GROSS_WEIGHT',
                    'item_supp_country_dim',
                    'pack= ' || (I_pack_no));
   close C_GET_GROSS_WEIGHT;
   ---
   ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , Begin
   IF L_pack_gross_wgt is not NULL THEN
      L_weight2   :=  L_pack_gross_wgt;
      if TSL_ITEM_WEIGHT_CONV(O_error_message,
                              I_pack_no,
                              L_weight2,
                              L_new_pack_gross_wgt) = FALSE then
         return FALSE;
      end if;
      L_pack_gross_wgt :=  L_new_pack_gross_wgt;
   END IF;
   ---
   O_pack_gross_wgt := NVL(L_pack_gross_wgt,0);
   ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , End
   ---
   return TRUE;
   ---
EXCEPTION
   when others then
      if C_GET_GROSS_WEIGHT%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_GROSS_WEIGHT',
                          'item_supp_country_dim',
                          'pack= ' || (I_pack_no));
         close C_GET_GROSS_WEIGHT;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_WEIGHT_PACK;
-----------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_WEIGHT_NEW_ITEM (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_item	           IN       ITEM_MASTER.ITEM%TYPE,
                                  I_item_qty         IN    	  PACKITEM.PACK_QTY%TYPE,
                                  O_item_gross_wgt      OUT   ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE)
RETURN BOOLEAN IS

   L_gross_weight      ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , Begin
   L_weight            ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   L_new_gross_weight  ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE := 0;
   ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , End
   L_program      VARCHAR(64)                       := 'ITEM_SUPP_COUNTRY_DIM_SQL.TSL_GET_WEIGHT_NEW_ITEM';

   CURSOR C_GET_GROSS_WEIGHT(L_item IN ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE) is
   select weight
     from item_supp_country_dim i
    where i.item = L_item
      and (item,supplier,origin_country) in (select item,supplier,origin_country_id
                                               from item_supp_country
                                              where primary_supp_ind = 'Y'
                                                and primary_country_ind =  'Y'
                                                and item  = L_item)
      and i.dim_object ='EA';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_item_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_qty',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_GROSS_WEIGHT',
                    'item_supp_country_dim',
                    'item= ' || (I_item));
   open C_GET_GROSS_WEIGHT(I_item);
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_GROSS_WEIGHT',
                    'item_supp_country_dim',
                    'item= ' || (I_item));
   fetch C_GET_GROSS_WEIGHT into L_gross_weight;
   ---
   IF C_GET_GROSS_WEIGHT%NOTFOUND THEN
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_GROSS_WEIGHT',
                       'item_supp_country_dim',
                       'item= ' || (I_item));
      close C_GET_GROSS_WEIGHT;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      ---
      O_item_gross_wgt := 0;
      ---
      return TRUE;
   END IF;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_GROSS_WEIGHT',
                    'item_supp_country_dim',
                    'item= ' || (I_item));
   close C_GET_GROSS_WEIGHT;
   ---
   ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , Begin
   IF L_gross_weight is not NULL THEN
   ---
      L_weight :=  L_gross_weight;
   ---
      IF TSL_ITEM_WEIGHT_CONV(O_error_message,
                              I_item,
                              L_weight,
                              L_new_gross_weight) = FALSE then
         return FALSE;
      END IF;
   ---
      L_gross_weight := L_new_gross_weight;
   ---
   END IF;
   ---NBS00011236 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 06-March-2009 , End
   ---
   L_gross_weight   := nvl(L_gross_weight, 0) * I_item_qty;
   O_item_gross_wgt := L_gross_weight;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_GROSS_WEIGHT%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_GROSS_WEIGHT',
                          'item_supp_country_dim',
                          'item= ' || (I_item));
         close C_GET_GROSS_WEIGHT;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
    return FALSE;
END TSL_GET_WEIGHT_NEW_ITEM;
-- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - End
-----------------------------------------------------------------------------------------------------------
--12-Jun-2008   WiproEnabler/Karthik   DefNBS00007117  Begin
FUNCTION TSL_INSERT_UPDATE_CA_DIM (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_pack_no	        IN       ITEM_MASTER.ITEM%TYPE,
                                   I_supplier         IN       ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                   I_origin_country   IN       ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE)
return BOOLEAN is

   L_program                 VARCHAR(64)  := 'ITEM_SUPP_COUNTRY_DIM_SQL.TSL_INSERT_UPDATE_CA_DIM';
   L_exists                  VARCHAR2(1)  := NULL;
   L_exist                   BOOLEAN;
   L_item_supp_country_dim   ITEM_SUPP_COUNTRY_DIM%ROWTYPE;

   RECORD_LOCKED            EXCEPTION;
   PRAGMA                   EXCEPTION_INIT(RECORD_LOCKED, -54);

   --The cursor checks if the 'CA' dimension record already exists.
   cursor C_GET_CA_DIM_RECORD is
      select 'x'
        from item_supp_country_dim isd
       where isd.item           = I_pack_no
         and isd.supplier       = I_supplier
         and isd.origin_country = I_origin_country
         and isd.dim_object     = 'CA' ;

   cursor C_LOCK_CA_DIM_RECORD is
      select 'x'
        from item_supp_country_dim isd
       where isd.item           = I_pack_no
         and isd.supplier       = I_supplier
         and isd.origin_country = I_origin_country
         and isd.dim_object     = 'CA'
         for update nowait;

BEGIN
   if I_pack_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_pack_no',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_supplier',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   if I_origin_country is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_origin_country',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   --Opening the cursor C_GET_CA_DIM_RECORD
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CA_DIM_RECORD',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'ITEM: ' || I_pack_no);
   open C_GET_CA_DIM_RECORD;

   --Fetch the data
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_CA_DIM_RECORD',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'ITEM: ' || I_pack_no);
   fetch C_GET_CA_DIM_RECORD
      into L_exists;

   --Check the cursor result
   if C_GET_CA_DIM_RECORD%FOUND then
      L_exists := 'Y';
   else
      L_exists := 'N';
   end if;
   ---
   --Close the cursor
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CA_DIM_RECORD',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'ITEM: ' || I_pack_no);
   close C_GET_CA_DIM_RECORD;

   --If the 'CA' dimension record is already not there then do the insert.
   if L_exists = 'N' then
      --Insert record into the ITEM_SUPP_COUNTRY_DIM table
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'ITEM_SUPP_COUNTRY_DIM',
                       'ITEM: ' || I_pack_no);
      insert into item_supp_country_dim (item,
                                         supplier,
                                         origin_country,
                                         dim_object,
                                         presentation_method,
                                         length,
                                         width,
                                         height,
                                         lwh_uom,
                                         weight,
                                         net_weight,
                                         weight_uom,
                                         liquid_volume,
                                         liquid_volume_uom,
                                         stat_cube,
                                         tare_weight,
                                         tare_type,
                                         create_datetime,
                                         last_update_datetime,
                                         last_update_id)
                                  select item,
                                         supplier,
                                         origin_country,
                                         'CA',
                                         presentation_method,
                                         length,
                                         width,
                                         height,
                                         lwh_uom,
                                         weight,
                                         net_weight,
                                         weight_uom,
                                         liquid_volume,
                                         liquid_volume_uom,
                                         stat_cube,
                                         tare_weight,
                                         tare_type,
                                         SYSDATE,
                                         SYSDATE,
                                         USER
                                    from item_supp_country_dim isd
                                   where isd.item           = I_pack_no
                                     and isd.supplier       = I_supplier
                                     and isd.origin_country = I_origin_country
                                     and isd.dim_object     = 'EA';

   --If the 'CA' dimension record is already there then update it.
   elsif L_exists = 'Y' then
      ---Get the 'EA' dimension record to update the 'CA' record.
      if NOT GET_ROW(O_error_message,
                     L_exist,
                     L_item_supp_country_dim,
                     I_pack_no,
                     I_supplier,
                     I_origin_country,
                     'EA') then
         return FALSE;
      end if;

      -- if 'EA' dimension record exists then update the 'CA' record.
      if L_exist then
         --Opening the cursor C_LOCK_CA_DIM_RECORD
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_CA_DIM_RECORD',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_pack_no);
         open C_LOCK_CA_DIM_RECORD;
         --Closing the cursor C_LOCK_CA_DIM_RECORD
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_CA_DIM_RECORD',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_pack_no);
         close C_LOCK_CA_DIM_RECORD;

         --Update item_supp_country_dim for the 'CA' record.
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_pack_no);
         update item_supp_country_dim isd
            set presentation_method  = L_item_supp_country_dim.presentation_method,
                length               = L_item_supp_country_dim.length,
                width                = L_item_supp_country_dim.width,
                height               = L_item_supp_country_dim.height,
                lwh_uom              = L_item_supp_country_dim.lwh_uom,
                weight               = L_item_supp_country_dim.weight,
                net_weight           = L_item_supp_country_dim.net_weight,
                weight_uom           = L_item_supp_country_dim.weight_uom,
                liquid_volume        = L_item_supp_country_dim.liquid_volume,
                liquid_volume_uom    = L_item_supp_country_dim.liquid_volume_uom,
                stat_cube            = L_item_supp_country_dim.stat_cube,
                tare_weight          = L_item_supp_country_dim.tare_weight,
                tare_type            = L_item_supp_country_dim.tare_type,
                last_update_datetime = SYSDATE,
                last_update_id       = USER
          where isd.item           = I_pack_no
            and isd.supplier       = I_supplier
            and isd.origin_country = I_origin_country
            and isd.dim_object     = 'CA';
      end if;
   end if;

   ---
   return TRUE;
   ---
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_SUPP_COUNTRY_DIM',
                                            L_program,
                                            NULL);
      return FALSE;
   when OTHERS then
      --If C_GET_CA_DIM_RECORD is not closed, then close it.
      if C_GET_CA_DIM_RECORD%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CA_DIM_RECORD',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_pack_no);
         close C_GET_CA_DIM_RECORD;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
       return FALSE;
END TSL_INSERT_UPDATE_CA_DIM;
-----------------------------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_CA_DIM (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            I_pack_no	         IN       ITEM_MASTER.ITEM%TYPE,
                            I_supplier	       IN       ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                            I_origin_country   IN       ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE)
return BOOLEAN is

   L_program                 VARCHAR(64)  := 'ITEM_SUPP_COUNTRY_DIM_SQL.TSL_DELETE_CA_DIM';
   RECORD_LOCKED            EXCEPTION;
   PRAGMA                   EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_CA_RECORD is
      select 'x'
        from item_supp_country_dim isd
       where isd.item           = I_pack_no
         and isd.supplier       = I_supplier
         and isd.origin_country = I_origin_country
         and isd.dim_object     = 'CA'
         for update nowait;

BEGIN
   if I_pack_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_pack_no',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_supplier',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   if I_origin_country is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_origin_country',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   --Opening the cursor C_LOCK_CA_RECORD
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_CA_RECORD',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'ITEM: ' || I_pack_no);
   open C_LOCK_CA_RECORD;
   --Closing the cursor C_LOCK_CA_RECORD
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_CA_RECORD',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'ITEM: ' || I_pack_no);
   close C_LOCK_CA_RECORD;

   --Delete item_supp_country_dim for the 'CA' record.
   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'ITEM_SUPP_COUNTRY_DIM',
                    'ITEM: ' || I_pack_no);

   delete from item_supp_country_dim isd
    where isd.item           = I_pack_no
      and isd.dim_object     = 'CA'
      and isd.supplier       = I_supplier
      and isd.origin_country = I_origin_country;

   ---
   return TRUE;
   ---
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_SUPP_COUNTRY_DIM',
                                            L_program,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
       return FALSE;
END TSL_DELETE_CA_DIM;
----------------------------------------------------------------------------------------------------
--12-Jun-2008   WiproEnabler/Karthik   DefNBS00007117  End
----------------------------------------------------------------------------------------------------
-- CR236a, 16-Dec-2009, Satish BN, satish.narasimhaiah@in.tesco.com, Begin
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EACH_WT(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_exists              OUT   BOOLEAN,
                         I_item	            IN        ITEM_MASTER.ITEM%TYPE,
                         I_supplier         IN        SUPS.SUPPLIER%TYPE,
                         I_country          IN       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
return BOOLEAN is

   L_program                 VARCHAR(64)  := 'ITEM_SUPP_COUNTRY_DIM_SQL.TSL_GET_EACH_WT';
   L_dummy                   VARCHAR(1);

   CURSOR C_GET_EACH_WT is
      select 'x'
        from item_supp_country_dim isd
       where isd.item           = I_item
         and isd.supplier       = I_supplier
         and isd.origin_country = I_country
         and isd.dim_object     = 'EA'
         and isd.weight is NOT NULL;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_supplier',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   --Opening the cursor C_GET_EACH_WT
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_EACH_WT',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'ITEM: ' || I_item);
   open C_GET_EACH_WT;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_EACH_WT',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'ITEM: ' || I_item);
   fetch C_GET_EACH_WT into L_dummy;
   if C_GET_EACH_WT%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   --Closing the cursor C_GET_EACH_WT
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_EACH_WT',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'ITEM: ' || I_item);
   close C_GET_EACH_WT;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_EACH_WT%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_EACH_WT',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         close C_GET_EACH_WT;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
       return FALSE;
END TSL_GET_EACH_WT;
-- CR236a, 16-Dec-2009, Satish BN, satish.narasimhaiah@in.tesco.com, End
----------------------------------------------------------------------------------------------------
END ITEM_SUPP_COUNTRY_DIM_SQL;
/

