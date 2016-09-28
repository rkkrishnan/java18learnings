CREATE OR REPLACE PACKAGE BODY ITEM_SUPP_COUNTRY_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Ramasamy
--Mod Date:    28-Jun-2007
--Mod Ref:     Mod number. 365b
--Mod Details: Amended script to explodes the base varient item information.
------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------
-- Mod By     : Wipro Enabler/Dhuraison Prince                         --
-- Mod Date   : 30-Jan-2008                                            --
-- Mod Ref    : Mod N114                                               --
-- Mod Details: Amended script to get the packing method of the pack.  --
-------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--Mod By:      Vinod Kumar,vinod.patalappa@in.tesco.com
--Mod Date:    30-Oct-2008
--Mod Ref:     Back Port Oracle fix(6339674)
--Mod Details: Back ported the oracle fix for Bug 6339674.Modified the function CONVERT_COST
---------------------------------------------------------------------------------------------
--Mod By:      Chandru, Chandrashekaran.natarajan@in.tesco.com
--Mod Date:    10-May-2010
--Mod Ref:     DefNBS017335 (NBS00017367)
--Mod Details: Fixed the NBS00017367 - origin country cascading issue
--------------------------------------------------------------------------------------------
--Mod By:      JK, jayakumar.gopal@in.tesco.com
--Mod Date:    15-Jul-2010
--Mod Ref:     DefNBS018190
--Mod Details: TSL_INS_COUNTRY_TO_VARIANTS function modifed to cascade the Item supplier Origin
--             country information to Variant's TPND.
--------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--Mod By:      Vivek Sharma, Vivek.Sharma@in.tesco.com
--Mod Date:    12-Oct-2010
--Mod Ref:     CR 339
--Mod Details: New method, TSL_GET_COST_UOM, to retrieve Cost_UOM based on Item and supplier
---------------------------------------------------------------------------------------------
-- 06-Dec-2010,MrgNBS020019, Vinutha Raju, Vinutha.raju@in.tesco.com, Begin
---------------------------------------------------------------------------------------------
--Mod By     : Yashavantharaja M.T , yashavantharaja.thimmesh@in.tesco.com
--Mod Date   : 24-Nov-2010
--Mod Ref    : MrgNBS019839
--Mod Details: Merge the latest version of file in MrgNBS019839 branch with the latest in MrgNBS019839.src2 branch.
-------------------------------------------------------------------------------------
--Mod By:      Raghuveer P R
--Mod Date:    12-Dec-2010
--Mod Ref:     CR 335
--Mod Details: New TSL_GET_PRIM_UNIT_COST added
---------------------------------------------------------------------------------------------
-- 06-Dec-2010,MrgNBS020019, Vinutha Raju, Vinutha.raju@in.tesco.com, Begin
---------------------------------------------------------------------------------------------
-- Mod By      : Veena.Nanjundaiah@in.tesco.com, Accenture
-- Mod Date    : 27-Dec-2010
-- Mod Ref     : CR362
-- Mod Details : Cascading Cost and Supllier details
---------------------------------------------------------------------------------------------
-- Mod By     : Ankush,Ankush.khanna@in.tesco.com
-- Mod Date   : 08-Feb-2011
-- Mod Ref    : CR382a
-- Mod Details: Modified the function INSERT_ITEM_SUPP_COUNTRY to insert new field tsl_buying_qty.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Ankush,Ankush.khanna@in.tesco.com
-- Mod Date   : 23-June-2011
-- Mod Ref    : DefNBS023046(NBS00023046)
-- Mod Details: Record lock exception added in INSERT_COUNTRY_IND_TO_CHILDREN().
-------------------------------------------------------------------------------------------------------------
--Mod By:      Usha Patil
--Mod Date:    15-May-2014
--Mod Ref:     CR518
--Mod Details: Added a function TSL_ITEM_SUPP_DUTYPAID to get the duty paid indicator for the
--item and supplier passed
---------------------------------------------------------------------------------------------
--Mod By:      Ramya Shetty K
--Mod Date:    25-July-2015
--Mod Ref:     PM038041
--Mod Details: Modified the cursor to pick cascade item supplier country details to ratio packs as well
------------------------------------------------------------------------------------------------

-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------------------------------
-- Function Name: LOCK_ITEM_SUPP_COUNTRY
-- Purpose      : This function will lock the ITEM_SUPP_COUNTRY table for update or delete.
-------------------------------------------------------------------------------------------------------
FUNCTION LOCK_ITEM_SUPP_COUNTRY(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_item          IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                I_supplier      IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                I_country       IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   RETURN BOOLEAN;
----------------------------------------------------------------------------------------------------
FUNCTION GET_PRIMARY_COUNTRY(O_error_message     IN OUT VARCHAR2,
                             O_exists            IN OUT BOOLEAN,
                             O_origin_country_id IN OUT ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                             I_item              IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                             I_supplier          IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE)
   return BOOLEAN IS


   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.GET_PRIMARY_COUNTRY';


   cursor C_GET_PRIMARY is
      select origin_country_id
        from item_supp_country
       where item = I_item
         and supplier = I_supplier
         and primary_country_ind = 'Y';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_PRIMARY','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier));
   open C_GET_PRIMARY;
   SQL_LIB.SET_MARK('FETCH','C_GET_PRIMARY','ITEM_SUPP_COUNTRY','ITEM: '||I_item||
                    ' Supplier: '||to_char(I_supplier));
   fetch C_GET_PRIMARY into O_origin_country_id;
      if C_GET_PRIMARY%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
   SQL_LIB.SET_MARK('CLOSE','C_GET_PRIMARY','ITEM_SUPP_COUNTRY','ITEM: '||I_item||
                    ' Supplier: '||to_char(I_supplier));
   close C_GET_PRIMARY;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_PRIMARY_COUNTRY;
-----------------------------------------------------------------------------------------------------------
FUNCTION ALL_PACK_COMPONENTS_EXIST(O_error_message     IN OUT VARCHAR2,
                                   O_exists            IN OUT BOOLEAN,
                                   I_item              IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                   I_supplier          IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                   I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   return BOOLEAN IS


   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.ALL_PACK_COMPONENTS_EXIST';
   L_pack_item             ITEM_MASTER.ITEM%TYPE;
   L_exists                VARCHAR2(1);


    cursor C_PACK_ITEMS_EXIST is
      select 'x'
        from v_packsku_qty vpq
       where vpq.pack_no = I_item
         and not exists( select 'x'
                           from item_supp_country isc
                          where isc.item              = vpq.item
                            and isc.supplier          = I_supplier
                            and isc.origin_country_id = I_origin_country_id
                            and rownum =1 );


BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_PACK_ITEMS_EXIST','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
   open C_PACK_ITEMS_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_PACK_ITEMS_EXIST','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
   fetch C_PACK_ITEMS_EXIST into L_exists;
      if C_PACK_ITEMS_EXIST%FOUND then
         O_exists := FALSE;
      else
         O_exists := TRUE;
      end if;
   SQL_LIB.SET_MARK('CLOSE','C_PACK_ITEMS_EXIST','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
   close C_PACK_ITEMS_EXIST;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ALL_PACK_COMPONENTS_EXIST;
--------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_CONST_DIMENSIONS(O_error_message     IN OUT VARCHAR2,
                                 I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                 I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                 I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                                 I_dim_object        IN     ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE,
                                 I_default_children  IN     VARCHAR2)
   return BOOLEAN IS


   L_program                     VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.UPDATE_CONST_DIMENSIONS';
   L_table                       VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY_DIM';
   L_dim_supplier                ITEM_SUPP_COUNTRY.SUPPLIER%TYPE;
   L_dim_origin_country_id       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
   L_presentation_method         ITEM_SUPP_COUNTRY_DIM.PRESENTATION_METHOD%TYPE;
   L_length                      ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
   L_width                       ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
   L_height                      ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
   L_lwh_uom                     ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE;
   L_weight                      ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
   L_net_weight                  ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE;
   L_weight_uom                  ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
   L_liquid_volume               ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
   L_liquid_volume_uom           ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE;
   L_stat_cube                   ITEM_SUPP_COUNTRY_DIM.STAT_CUBE%TYPE;
   L_tare_weight                 ITEM_SUPP_COUNTRY_DIM.TARE_WEIGHT%TYPE;
   L_tare_type                   ITEM_SUPP_COUNTRY_DIM.TARE_TYPE%TYPE;
   L_child_item                  ITEM_MASTER.ITEM%TYPE;

   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_GET_DIMENSIONS is
      select isd.presentation_method,
             isd.length,
             isd.width,
             isd.height,
             isd.lwh_uom,
             isd.weight,
             isd.net_weight,
             isd.weight_uom,
             isd.liquid_volume,
             isd.liquid_volume_uom,
             isd.stat_cube,
             isd.tare_weight,
             isd.tare_type
        from item_supp_country_dim isd
       where isd.item = I_item
         and isd.supplier = I_supplier
         and isd.origin_country = I_origin_country_id
         and isd.dim_object = I_dim_object;

   cursor C_LOCK_DIMENSIONS is
      select 'x'
        from item_supp_country_dim isd
       where isd.item = I_item
         and (isd.supplier != I_supplier
              or isd.origin_country != I_origin_country_id)
         and isd.dim_object = I_dim_object
         for update nowait;

   cursor C_LOCK_CHILD_DIMENSIONS is
      select 'x'
        from item_supp_country_dim isd
       where isd.item = L_child_item
         and isd.supplier = L_dim_supplier
         and isd.origin_country = L_dim_origin_country_id
         for update nowait;

   cursor C_GET_SUPP_COUNTRIES_INSERT is
      select supplier,
             origin_country_id
        from item_supp_country isc
       where isc.item = I_item
         and (isc.supplier != I_supplier
              or isc.origin_country_id != I_origin_country_id);

    cursor C_GET_CHILD_ITEMS is
      select im.item
        from item_master im
       where (im.item_parent = I_item
              or im.item_grandparent = I_item)
         and im.item_level <= im.tran_level
         and exists (select 'x'
                       from item_supp_country isc
                       where isc.item = im.item
                         and isc.supplier = L_dim_supplier
                         and isc.origin_country_id = L_dim_origin_country_id)
         and exists (select 'x'
                       from item_supp_country_dim isd
                      where isd.item = I_item
                        and isd.supplier = L_dim_supplier
                        and isd.origin_country = L_dim_origin_country_id);

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                             'NULL',
                                             'NOT NULL');
      return FALSE;
   end if;
   ---
      if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   open C_GET_DIMENSIONS;
   SQL_LIB.SET_MARK('FETCH','C_GET_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   fetch C_GET_DIMENSIONS into L_presentation_method,
                               L_length,
                               L_width,
                               L_height,
                               L_lwh_uom,
                               L_weight,
                               L_net_weight,
                               L_weight_uom,
                               L_liquid_volume,
                               L_liquid_volume_uom,
                               L_stat_cube,
                               L_tare_weight,
                               L_tare_type;
   SQL_LIB.SET_MARK('CLOSE','C_GET_DIMENSIONS ','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   close C_GET_DIMENSIONS;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   open C_LOCK_DIMENSIONS;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   close C_LOCK_DIMENSIONS;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   update item_supp_country_dim isd
      set isd.presentation_method = NVL(L_presentation_method, presentation_method),
          isd.length = NVL(L_length, length),
          isd.width = NVL(L_width, width),
          isd.height = NVL(L_height, height),
          isd.lwh_uom = NVL(L_lwh_uom, lwh_uom),
          isd.weight = NVL(L_weight, weight),
          isd.net_weight = NVL(L_net_weight, net_weight),
          isd.weight_uom = NVL(L_weight_uom, weight_uom),
          isd.liquid_volume =  NVL(L_liquid_volume, liquid_volume),
          isd.liquid_volume_uom = NVL(L_liquid_volume_uom, liquid_volume_uom),
          isd.stat_cube =  NVL(L_stat_cube, stat_cube),
          isd.tare_weight =  NVL(L_tare_weight, tare_weight),
          isd.tare_type =  NVL(L_tare_type, tare_type),
          isd.last_update_datetime = sysdate,
          isd.last_update_id = user
    where isd.item = I_item
      and (isd.supplier != I_supplier
           or isd.origin_country != I_origin_country_id)
      and isd.dim_object = I_dim_object
      and exists (select 'x'
                    from item_supp_country_dim isd2
                   where isd.item = I_item
                     and (isd.supplier != I_supplier
                          or isd.origin_country != I_origin_country_id)
                     and isd.dim_object = I_dim_object);
   ---
   for c_rec in C_GET_SUPP_COUNTRIES_INSERT LOOP
      L_dim_supplier := c_rec.supplier;
      L_dim_origin_country_id := c_rec.origin_country_id;
      ---
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      insert into item_supp_country_dim(item,
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
                                 select I_item,
                                        L_dim_supplier,
                                        L_dim_origin_country_id,
                                        I_dim_object,
                                        isd.presentation_method,
                                        isd.length,
                                        isd.width,
                                        isd.height,
                                        isd.lwh_uom,
                                        isd.weight,
                                        isd.net_weight,
                                        isd.weight_uom,
                                        isd.liquid_volume,
                                        isd.liquid_volume_uom,
                                        isd.stat_cube,
                                        isd.tare_weight,
                                        isd.tare_type,
                                        sysdate,
                                        sysdate,
                                        user
                                      from item_supp_country_dim isd
                                     where isd.item = I_item
                                       and isd.supplier = I_supplier
                                       and isd.origin_country = I_origin_country_id
                                       and isd.dim_object = I_dim_object
                                       and not exists (select 'x'
                                                         from item_supp_country_dim isd2
                                                        where isd2.item = isd.item
                                                          and isd2.supplier = L_dim_supplier
                                                          and isd2.origin_country = L_dim_origin_country_id
                                                          and isd2.dim_object = isd.dim_object);
      if I_default_children = 'Y' then
         for c_rec in C_GET_CHILD_ITEMS LOOP
            L_child_item := c_rec.item;
            ---
            SQL_LIB.SET_MARK('OPEN','C_LOCK_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                             ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
            open C_LOCK_DIMENSIONS;
            SQL_LIB.SET_MARK('CLOSE','C_LOCK_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                             ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
            close C_LOCK_DIMENSIONS;
            ---
            SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                             ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
            update item_supp_country_dim isd
               set isd.presentation_method = NVL(L_presentation_method, presentation_method),
                   isd.length = NVL(L_length, length),
                   isd.width = NVL(L_width, width),
                   isd.height = NVL(L_height, height),
                   isd.lwh_uom = NVL(L_lwh_uom, lwh_uom),
                   isd.weight = NVL(L_weight, weight),
                   isd.net_weight = NVL(L_net_weight, net_weight),
                   isd.weight_uom = NVL(L_weight_uom, weight_uom),
                   isd.liquid_volume =  NVL(L_liquid_volume, liquid_volume),
                   isd.liquid_volume_uom = NVL(L_liquid_volume_uom, liquid_volume_uom),
                   isd.stat_cube =  NVL(L_stat_cube, stat_cube),
                   isd.tare_weight =  NVL(L_tare_weight, tare_weight),
                   isd.tare_type =  NVL(L_tare_type, tare_type),
                   isd.last_update_datetime = sysdate,
                   isd.last_update_id = user
            where isd.item = L_child_item
              and isd.supplier = L_dim_supplier
              and isd.origin_country = L_dim_origin_country_id
              and isd.dim_object = I_dim_object
              and exists (select 'x'
                            from item_supp_country_dim isd2
                           where isd.item = I_item
                             and (isd.supplier = L_dim_supplier
                                  or isd.origin_country = L_dim_origin_country_id)
                             and isd.dim_object = I_dim_object);
            ---
            SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                             ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
            insert into item_supp_country_dim(item,
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
                                       select L_child_item,
                                              L_dim_supplier,
                                              L_dim_origin_country_id,
                                              I_dim_object,
                                              isd.presentation_method,
                                              isd.length,
                                              isd.width,
                                              isd.height,
                                              isd.lwh_uom,
                                              isd.weight,
                                              isd.net_weight,
                                              isd.weight_uom,
                                              isd.liquid_volume,
                                              isd.liquid_volume_uom,
                                              isd.stat_cube,
                                              isd.tare_weight,
                                              isd.tare_type,
                                              sysdate,
                                              sysdate,
                                              user
                                         from item_supp_country_dim isd
                                        where isd.item = I_item
                                          and isd.supplier = I_supplier
                                          and isd.origin_country = I_origin_country_id
                                          and isd.dim_object = I_dim_object
                                          and not exists (select 'x'
                                                           from item_supp_country_dim isd2
                                                          where isd2.item = L_child_item
                                                            and isd2.supplier = L_dim_supplier
                                                            and isd2.origin_country = L_dim_origin_country_id
                                                            and isd2.dim_object = isd.dim_object);
         end LOOP; -- retrieve child items.
      end if;
   end LOOP; -- retrieve non-primary suppliers and countries.
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             'I_item',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END UPDATE_CONST_DIMENSIONS;
----------------------------------------------------------------------------------------------------------
FUNCTION INSERT_CONST_DIMENSIONS(O_error_message     IN OUT VARCHAR2,
                                 I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                 I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                 I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE)
   return BOOLEAN IS


   L_program                     VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.INSERT_CONST_DIMENSIONS';
   L_primary_supplier            ITEM_SUPP_COUNTRY.SUPPLIER%TYPE;
   L_primary_origin_country_id   ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
   L_dim_object                  ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE;


   cursor C_GET_PRIMARY_INFO is
      select supplier,
             origin_country_id
        from item_supp_country
       where item = I_item
         and primary_supp_ind = 'Y'
         and primary_country_ind = 'Y';

   cursor C_GET_DIMENSIONS is
      select isd.dim_object
        from item_supp_country_dim isd
       where isd.item = I_item
         and isd.supplier = L_primary_supplier
         and isd.origin_country = L_primary_origin_country_id;


BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_PRIMARY_INFO','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   open C_GET_PRIMARY_INFO;
   SQL_LIB.SET_MARK('OPEN','C_GET_PRIMARY_INFO','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   fetch C_GET_PRIMARY_INFO into L_primary_supplier,
                                 L_primary_origin_country_id;
   SQL_LIB.SET_MARK('OPEN','C_GET_PRIMARY_INFO','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   close C_GET_PRIMARY_INFO;
   ---
   for c_rec in C_GET_DIMENSIONS LOOP
      L_dim_object := c_rec.dim_object;
      ---
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      insert into item_supp_country_dim(item,
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
                                 select I_item,
                                        I_supplier,
                                        I_origin_country_id,
                                        L_dim_object,
                                        isd.presentation_method,
                                        isd.length,
                                        isd.width,
                                        isd.height,
                                        isd.lwh_uom,
                                        isd.weight,
                                        isd.net_weight,
                                        isd.weight_uom,
                                        isd.liquid_volume,
                                        isd.liquid_volume_uom,
                                        isd.stat_cube,
                                        isd.tare_weight,
                                        isd.tare_type,
                                        sysdate,
                                        sysdate,
                                        user
                                   from item_supp_country_dim isd
                                  where isd.item = I_item
                                    and isd.supplier = L_primary_supplier
                                    and isd.origin_country = L_primary_origin_country_id
                                    and isd.dim_object = L_dim_object
                                    and not exists (select 'x'
                                                      from item_supp_country_dim isd2
                                                     where isd2.item = isd.item
                                                       and isd2.supplier = I_supplier
                                                       and isd2.origin_country = I_origin_country_id
                                                       and isd2.dim_object = L_dim_object);
   end LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_CONST_DIMENSIONS;
----------------------------------------------------------------------------------------------------------
FUNCTION INSERT_DIMENSION_TO_CHILDREN(O_error_message     IN OUT VARCHAR2,
                                      I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                      I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                      I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                                      I_dim_object        IN     ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE)
   return BOOLEAN IS


   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.INSERT_DIMENSION_TO_CHILDREN';
   L_child_item            ITEM_MASTER.ITEM%TYPE;

   cursor C_GET_CHILD_ITEMS is
      select im.item
        from item_master im
       where (im.item_parent = I_item
              or im.item_grandparent = I_item)
         and im.item_level <= im.tran_level
         and exists (select 'x'
                       from item_supp_country isc
                       where isc.item = im.item
                         and isc.supplier = I_supplier
                         and isc.origin_country_id = I_origin_country_id)
         and exists (select 'x'
                       from item_supp_country_dim isd
                      where isd.item = I_item
                        and isd.supplier = I_supplier
                        and isd.origin_country = I_origin_country_id);
 BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   for c_rec in C_GET_CHILD_ITEMS LOOP
      L_child_item := c_rec.item;
      ---
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      insert into item_supp_country_dim(item,
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
                                 select L_child_item,
                                        I_supplier,
                                        I_origin_country_id,
                                        NVL(I_dim_object, dim_object),
                                        isd.presentation_method,
                                        isd.length,
                                        isd.width,
                                        isd.height,
                                        isd.lwh_uom,
                                        isd.weight,
                                        isd.net_weight,
                                        isd.weight_uom,
                                        isd.liquid_volume,
                                        isd.liquid_volume_uom,
                                        isd.stat_cube,
                                        isd.tare_weight,
                                        isd.tare_type,
                                        sysdate,
                                        sysdate,
                                        user
                                   from item_supp_country_dim isd
                                  where isd.item = I_item
                                    and isd.supplier = I_supplier
                                    and isd.origin_country = I_origin_country_id
                                    and isd.dim_object = NVL(I_dim_object, dim_object)
                                    and not exists (select 'x'
                                                      from item_supp_country_dim isd
                                                     where isd.item = L_child_item
                                                       and isd.supplier = I_supplier
                                                       and isd.origin_country = I_origin_country_id
                                                       and isd.dim_object = NVL(I_dim_object, dim_object));
   end LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_DIMENSION_TO_CHILDREN;
-----------------------------------------------------------------------------------------------------------
FUNCTION DELETE_DIMENSION_TO_CHILDREN(O_error_message     IN OUT VARCHAR2,
                                      I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                      I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                      I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                                      I_dim_object        IN     ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE)
   return BOOLEAN IS

   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.INSERT_DIMENSION_TO_CHILDREN';
   L_table                 VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY_DIM';
   L_exists                BOOLEAN;
   L_child_item            ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE;

   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

   cursor C_GET_CHILD_DIM is
       select im.item
        from item_master im
       where (im.item_parent = I_item
              or im.item_grandparent = I_item)
         and im.item_level <= im.tran_level
         and exists (select 'x'
                      from item_supp_country_dim isd
                     where isd.item = im.item
                       and isd.supplier = I_supplier
                       and isd.origin_country = I_origin_country_id
                       and isd.dim_object = I_dim_object);

   cursor C_LOCK_DIMENSIONS is
      select 'x'
        from item_supp_country_dim
       where supplier = I_supplier
         and origin_country = I_origin_country_id
         and dim_object = I_dim_object
         and item = L_child_item;


BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_dim_object is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_dim_object',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   for c_dim_rec in C_GET_CHILD_DIM LOOP
      L_child_item := c_dim_rec.item;
      ---
      if I_dim_object = 'CA' then
         if CHECK_CASE_DIMENSION(O_error_message,
                                 L_exists,
                                 L_child_item,
                                 I_supplier,
                                 I_origin_country_id) = FALSE then
             return FALSE;
          end if;
          ---
          if L_exists = TRUE then
             O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_DIM_CHILD',
                                                   NULL,
                                                   NULL,
                                                   NULL);
             return FALSE;
          end if;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      open C_LOCK_DIMENSIONS;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      close C_LOCK_DIMENSIONS;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      delete from item_supp_country_dim
         where supplier = I_supplier
           and origin_country = I_origin_country_id
           and dim_object = I_dim_object
           and item = L_child_item;
   end LOOP;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                            'I_item',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_DIMENSION_TO_CHILDREN;
----------------------------------------------------------------------------------------
FUNCTION INSERT_COUNTRY_TO_CHILDREN(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item                IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                    I_supplier            IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                    I_origin_country_id   IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                                    I_primary_country_ind IN     VARCHAR2,
                                    I_replace_ind     IN     VARCHAR2 DEFAULT 'N')
   return BOOLEAN IS


   L_program                VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_TO_CHILDREN';
   L_child_item             ITEM_MASTER.ITEM%TYPE;
   L_bracket_ind            VARCHAR2(1)    := NULL;
   L_inv_mgmt_level         VARCHAR2(6)    := NULL;

   -- Retrieving the child items for which there is no entry in the item_supp_country for that item/supplier/country combination.

   cursor C_GET_CHILD_ITEMS is
       select im.item
         from item_master im
        where (im.item_parent = I_item
               or im.item_grandparent = I_item
               --NBS00017367 10-May-2010 Chandru Begin
               or im.item in (select pack_no
                                from packitem
                               where (item = I_item
                                  or  item in (select item
                                                 from item_master
                                                where item_parent = I_item))))
               --NBS00017367 10-May-2010 Chandru End
          and im.item_level <= im.tran_level
          and exists (select 'x'
                        from item_supplier its
                       where its.item = im.item
                         and its.supplier = I_supplier)
          and not exists (select 'x'
                           from item_supp_country isc
                          where isc.item = im.item
                            and isc.supplier = I_supplier
                            and isc.origin_country_id = I_origin_country_id);

   -- Retrieving the child items for which there is no entry in the item_supp_country for that item/supplier combination.

   cursor C_GET_CHILD_ITEMS_1 is
       select im.item
         from item_master im
        where (im.item_parent = I_item
               or im.item_grandparent = I_item
               --NBS00017367 10-May-2010 Chandru Begin
               or im.item in (select pack_no
                                from packitem
                               where (item = I_item
                                  or  item in (select item
                                                 from item_master
                                                where item_parent = I_item))))
               --NBS00017367 10-May-2010 Chandru End

          and im.item_level <= im.tran_level
          and exists (select 'x'
                        from item_supplier its
                       where its.item = im.item
                         and its.supplier = I_supplier)
          and not exists (select 'x'
                            from item_supp_country isc
                           where isc.item = im.item
                             and isc.supplier = I_supplier);

   -- Retrieving the child items for which different origin countries exist but there is no entry for parent's
   -- primary origin country.

   cursor C_GET_CHILD_ITEMS_2 is
       select im.item
         from item_master im
        where (im.item_parent = I_item
               or im.item_grandparent = I_item
               --NBS00017367 10-May-2010 Chandru Begin
               or im.item in (select pack_no
                                from packitem
                               where (item = I_item
                                  or  item in (select item
                                                 from item_master
                                                where item_parent = I_item))))
               --NBS00017367 10-May-2010 Chandru End
          and im.item_level <= im.tran_level
          and exists (select 'x'
                        from item_supplier its
                       where its.item = im.item
                         and its.supplier = I_supplier)
          and exists (select 'x'
                        from item_supp_country isc
                       where isc.item = im.item
                         and isc.supplier = I_supplier)
       MINUS
       select im.item
         from item_master im
        where (im.item_parent = I_item
               or im.item_grandparent = I_item
               --NBS00017367 10-May-2010 Chandru Begin
               or im.item in (select pack_no
                                from packitem
                               where (item = I_item
                                  or  item in (select item
                                                 from item_master
                                                where item_parent = I_item))))
               --NBS00017367 10-May-2010 Chandru End
          and im.item_level <= im.tran_level
          and exists (select 'x'
                        from item_supplier its
                       where its.item = im.item
                         and its.supplier = I_supplier)
          and exists (select 'x'
                        from item_supp_country isc
                       where isc.item = im.item
                         and isc.supplier = I_supplier
                         and isc.origin_country_id = I_origin_country_id);

   -- Retrieving the child items for which there exist an entry in the item_supp_country corresponding to
   -- parent's primary origin country.

   cursor C_GET_CHILD_ITEMS_3 is
       select im.item
         from item_master im
        where (im.item_parent = I_item
               or im.item_grandparent = I_item
               --NBS00017367 10-May-2010 Chandru Begin
               or im.item in (select pack_no
                                from packitem
                               where (item = I_item
                                  or  item in (select item
                                                 from item_master
                                                where item_parent = I_item))))
               --NBS00017367 10-May-2010 Chandru End
          and im.item_level <= im.tran_level
          and exists (select 'x'
                        from item_supplier its
                       where its.item = im.item
                         and its.supplier = I_supplier)
          and exists (select 'x'
                        from item_supp_country isc
                       where isc.item = im.item
                         and isc.supplier = I_supplier
                         and isc.origin_country_id = I_origin_country_id
                         and isc.primary_country_ind = 'N');

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_primary_country_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_primary_country_ind',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   -- get info so that we can check (in for loop) to see if its bracket costing
   if SUPP_ATTRIB_SQL.GET_BRACKET_COSTING_IND(O_error_message,
                                              L_bracket_ind,
                                              I_supplier) = FALSE then
      return FALSE;
   end if;
   if L_bracket_ind = 'Y' then
      if SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                             L_inv_mgmt_level,
                                             I_supplier) = FALSE then
         return FALSE;
      end if;
   end if;
   --
   if I_primary_country_ind = 'N' then
      for c_rec in C_GET_CHILD_ITEMS LOOP
         L_child_item := c_rec.item;
                  if INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message,
                                           I_item,
                                           L_child_item,
                                           I_supplier,
                                           I_origin_country_id,
                                           'N',
                                           'N',
                                           'Y',
                                           L_bracket_ind,
                                           L_inv_mgmt_level) = FALSE then
            return FALSE;
         end if;
      end LOOP;
      ---
   else
      if I_replace_ind = 'N' then
         for c_rec in C_GET_CHILD_ITEMS_1 LOOP
            L_child_item := c_rec.item;
            if INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message,
                                              I_item,
                                              L_child_item,
                                              I_supplier,
                                              I_origin_country_id,
                                              'Y',
                                              'N',
                                              'Y',
                                              L_bracket_ind,
                                              L_inv_mgmt_level) = FALSE then
               return FALSE;
            end if;
         end LOOP;
         ---
         for c_rec in C_GET_CHILD_ITEMS_2 LOOP
            L_child_item := c_rec.item;
            if INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message,
                                              I_item,
                                              L_child_item,
                                              I_supplier,
                                              I_origin_country_id,
                                              'N',
                                              'N',
                                              'Y',
                                              L_bracket_ind,
                                              L_inv_mgmt_level) = FALSE then
               return FALSE;
            end if;
         end LOOP;
         ---
      else
         for c_rec in C_GET_CHILD_ITEMS_1 LOOP
            L_child_item := c_rec.item;
            if INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message,
                                              I_item,
                                              L_child_item,
                                              I_supplier,
                                              I_origin_country_id,
                                              'Y',
                                              'N',
                                              'Y',
                                              L_bracket_ind,
                                              L_inv_mgmt_level) = FALSE then
               return FALSE;
            end if;
         end LOOP;
         ---
         for c_rec in C_GET_CHILD_ITEMS_2 LOOP
            L_child_item := c_rec.item;
            if INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message,
                                              I_item,
                                              L_child_item,
                                              I_supplier,
                                              I_origin_country_id,
                                              'Y',
                                              'Y',
                                              'Y',
                                              L_bracket_ind,
                                              L_inv_mgmt_level) = FALSE then
               return FALSE;
            end if;
         end LOOP;
         ---
         for c_rec in C_GET_CHILD_ITEMS_3 LOOP
            L_child_item := c_rec.item;
            if INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message,
                                              I_item,
                                              L_child_item,
                                              I_supplier,
                                              I_origin_country_id,
                                              'Y',
                                              'Y',
                                              'N',
                                              L_bracket_ind,
                                              L_inv_mgmt_level) = FALSE then
               return FALSE;
            end if;
         end LOOP;
         ---
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

END INSERT_COUNTRY_TO_CHILDREN;
-------------------------------------------------------------------------------------------------------------
FUNCTION INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                        I_item                IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                        I_child_item          IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                        I_supplier            IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                        I_origin_country_id   IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                                        I_primary_country_ind IN     VARCHAR2,
                                        I_update_ind          IN     VARCHAR2,
                                        I_insert_ind          IN     VARCHAR2,
                                        I_bracket_ind         IN     VARCHAR2,
                                        I_inv_mgmt_level      IN     VARCHAR2)
   return BOOLEAN IS

   L_program                VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_IND_TO_CHILDREN';
   L_child_prim_supp_ind    ITEM_SUPP_COUNTRY.PRIMARY_SUPP_IND%TYPE;
   L_exists                 BOOLEAN;
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, Begin
   L_child_pack_qty         PACKITEM.PACK_QTY%TYPE;
   L_sys_option_row         SYSTEM_OPTIONS%ROWTYPE;
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, End

   -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, Begin
   L_pack_buying_qty        ITEM_SUPP_COUNTRY.TSL_BUYING_QTY%TYPE := 0;
   -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, End

   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,Begin
   L_table                       VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY';
   RECORD_LOCKED                 EXCEPTION;
   PRAGMA                        EXCEPTION_INIT(RECORD_LOCKED, -54);
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End
  --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com Begin
  L_rp_item VARCHAR2(1) := 'N';
   --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com End

   cursor C_LOCK_COUNTRY_Y is
      select 'x'
        from item_supp_country
       where primary_country_ind = 'Y'
         and origin_country_id   != I_origin_country_id
         and supplier            = I_supplier
         and item                = I_child_item
         for update nowait;

   cursor C_LOCK_COUNTRY_N is
      select 'x'
        from item_supp_country
       where primary_country_ind = 'N'
         and origin_country_id   = I_origin_country_id
         and supplier            = I_supplier
         and item                = I_child_item
         for update nowait;

   cursor C_PRIMARY_SUPPLIER is
      select primary_supp_ind
        from item_supp_country
       where item = I_child_item
         and supplier = I_supplier;

   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, Begin
   CURSOR C_CHILD_PACK_QTY (Cp_item ITEM_MASTER.ITEM%TYPE) is
   select pack_qty
     from packitem
    where pack_no = Cp_item;
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, End

   -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, Begin
   CURSOR C_GET_BUYING_QTY is
   select tsl_buying_qty
     from item_supp_country
    where item = I_child_item
      and primary_supp_ind = 'Y';
   -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, End

      --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com Begin
     CURSOR C_GET_PACK_TYPE IS
     select 'Y'
       from item_master im
      where im.item = I_child_item
         and im.pack_ind = 'Y'
         and im.simple_pack_ind = 'N'
         and im.item_level = im.tran_level;

   --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com End

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_child_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_child_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_primary_country_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_primary_country_ind',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_update_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_update_ind',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_insert_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_insert_ind',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_bracket_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_bracket_ind',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_sys_option_row) = FALSE then
      raise PROGRAM_ERROR;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHILD_PACK_QTY',
                    'ITEM_SUPP_COUNTRY',
                    'Item: '||I_child_item||' Supplier: '||to_char(I_supplier));
   open C_CHILD_PACK_QTY (I_child_item);
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHILD_PACK_QTY',
                    'ITEM_SUPP_COUNTRY',
                    'Item: '||I_child_item||' Supplier: '||to_char(I_supplier));
   fetch C_CHILD_PACK_QTY into L_child_pack_qty;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHILD_PACK_QTY',
                    'ITEM_SUPP_COUNTRY',
                    'Item: '||I_child_item||' Supplier: '||to_char(I_supplier));
   close C_CHILD_PACK_QTY;

   if L_child_pack_qty is null or L_child_pack_qty = 0 or L_sys_option_row.tsl_supp_cre_casc_ind <> 'Y' then
      L_child_pack_qty := 1;
   end if;
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, End

   if I_insert_ind = 'Y' then
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_PRIMARY_SUPPLIER','ITEM_SUPP_COUNTRY','Item: '||I_child_item||
                       ' Supplier: '||to_char(I_supplier));
      open C_PRIMARY_SUPPLIER;
      SQL_LIB.SET_MARK('FETCH', 'C_PRIMARY_SUPPLIER','ITEM_SUPP_COUNTRY','Item: '||I_child_item||
                       ' Supplier: '||to_char(I_supplier));
      fetch C_PRIMARY_SUPPLIER into L_child_prim_supp_ind;
      SQL_LIB.SET_MARK('CLOSE', 'C_PRIMARY_SUPPLIER','ITEM_SUPP_COUNTRY','Item: '||I_child_item||
                       ' Supplier: '||to_char(I_supplier));
      close C_PRIMARY_SUPPLIER;
      ---

      -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, Begin
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_BUYING_QTY',
                       'ITEM_SUPP_COUNTRY',
                       'Item: '||I_child_item||' Supplier: '||to_char(I_supplier));
      open C_GET_BUYING_QTY;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_BUYING_QTY',
                       'ITEM_SUPP_COUNTRY',
                       'Item: '||I_child_item||' Supplier: '||to_char(I_supplier));
      fetch C_GET_BUYING_QTY into L_pack_buying_qty;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_BUYING_QTY',
                       'ITEM_SUPP_COUNTRY',
                       'Item: '||I_child_item||' Supplier: '||to_char(I_supplier));
      close C_GET_BUYING_QTY;
      -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, End
      --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com Begin
       SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_TYPE',
                       'ITEM_MASTER',
                       'Item: '||I_child_item||' Supplier: '||to_char(I_supplier));
      open C_GET_PACK_TYPE;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PACK_TYPE',
                       'ITEM_MASTER',
                       'Item: '||I_child_item||' Supplier: '||to_char(I_supplier));
      fetch C_GET_PACK_TYPE into L_rp_item;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK_TYPE',
                       'ITEM_MASTER',
                       'Item: '||I_child_item||' Supplier: '||to_char(I_supplier));
      close C_GET_PACK_TYPE;
      --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com End

      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY','Item: '||I_child_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
      insert into item_supp_country(item,
                                    supplier,
                                    origin_country_id,
                                    unit_cost,
                                    lead_time,
                                    supp_pack_size,
                                    inner_pack_size,
                                    round_lvl,
                                    round_to_inner_pct,
                                    round_to_case_pct,
                                    round_to_layer_pct,
                                    round_to_pallet_pct,
                                    min_order_qty,
                                    max_order_qty,
                                    packing_method,
                                    primary_supp_ind,
                                    primary_country_ind,
                                    default_uop,
                                    ti,
                                    hi,
                                    supp_hier_type_1,
                                    supp_hier_lvl_1,
                                    supp_hier_type_2,
                                    supp_hier_lvl_2,
                                    supp_hier_type_3,
                                    supp_hier_lvl_3,
                                    pickup_lead_time,
                                    create_datetime,
                                    last_update_datetime,
                                    last_update_id,
                                    cost_uom,
                                    -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, Begin
                                    tsl_buying_qty)
                                    -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, End
                             select I_child_item,
                                    I_supplier,
                                    I_origin_country_id,
                                    -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, Begin
                                    isc.unit_cost * L_child_pack_qty,
                                    -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, End
                                    isc.lead_time,
                                    isc.supp_pack_size,
                                    isc.inner_pack_size,
                                    isc.round_lvl,
                                    isc.round_to_inner_pct,
                                    isc.round_to_case_pct,
                                    isc.round_to_layer_pct,
                                    isc.round_to_pallet_pct,
                                    isc.min_order_qty,
                                    isc.max_order_qty,
                                    isc.packing_method,
                                    nvl(L_child_prim_supp_ind, isc.primary_supp_ind),
                                   --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com Begin
                                    decode(L_rp_item,'Y','Y',I_primary_country_ind),
                                    --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com End
                                    isc.default_uop,
                                    isc.ti,
                                    isc.hi,
                                    isc.supp_hier_type_1,
                                    isc.supp_hier_lvl_1,
                                    isc.supp_hier_type_2,
                                    isc.supp_hier_lvl_2,
                                    isc.supp_hier_type_3,
                                    isc.supp_hier_lvl_3,
                                    isc.pickup_lead_time,
                                    sysdate,
                                    sysdate,
                                    user,
                                    isc.cost_uom,
                                    -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, Begin
                                    NVL(L_pack_buying_qty,0)
                                    -- DefNBS021838, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, End
                               from item_supp_country isc
                              where isc.item = I_item
                                and isc.supplier = I_supplier
                                and isc.origin_country_id = I_origin_country_id;

      --- check to see if brackets exist for this child already
      if ITEM_BRACKET_COST_SQL.BRACKETS_EXIST(O_error_message,
                                              L_exists,
                                              I_child_item,
                                              I_supplier,
                                              I_origin_country_id,
                                              NULL) = FALSE then
         return FALSE;
      end if;
      --- create country level bracket cost records for children
      if (I_bracket_ind = 'Y') and
         (L_exists = FALSE) and
         (I_inv_mgmt_level = 'S' or I_inv_mgmt_level = 'D') then
         if ITEM_BRACKET_COST_SQL.CREATE_BRACKET(O_error_message,
                                                 I_child_item,
                                                 I_supplier,
                                                 I_origin_country_id,
                                                 NULL,
                                                 NULL) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;
   --
      if I_update_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_COUNTRY_Y','ITEM_SUPP_COUNTRY','Item: '||I_child_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
      open C_LOCK_COUNTRY_Y;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_COUNTRY_Y','ITEM_SUPP_COUNTRY','Item: '||I_child_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
      close C_LOCK_COUNTRY_Y;
      ---
      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY',
                       'Country: '|| I_origin_country_id);
      update item_supp_country isc1
         set isc1.primary_country_ind  = 'N',
             isc1.last_update_id       = user,
             isc1.last_update_datetime = sysdate
       where isc1.primary_country_ind  = 'Y'
         and isc1.origin_country_id   != I_origin_country_id
         and isc1.supplier             = I_supplier
         and isc1.item                 = I_child_item;
      ---
   end if;
   ---
   if I_insert_ind = 'N' and I_update_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_COUNTRY_N','ITEM_SUPP_COUNTRY','Item: '||I_child_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
      open C_LOCK_COUNTRY_N;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_COUNTRY_N','ITEM_SUPP_COUNTRY','Item: '||I_child_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
      close C_LOCK_COUNTRY_N;
      ---
      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY',
                       'Country: '|| I_origin_country_id);
      update item_supp_country isc1
         set isc1.primary_country_ind  = 'Y',
             isc1.last_update_id       = user,
             isc1.last_update_datetime = sysdate
       where isc1.primary_country_ind  = 'N'
         and isc1.origin_country_id    = I_origin_country_id
         and isc1.supplier             = I_supplier
         and isc1.item                 = I_child_item;
      ---
   end if;
   return TRUE;

EXCEPTION
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_child_item,
                                            NULL);
      return FALSE;
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END INSERT_COUNTRY_IND_TO_CHILDREN;
-------------------------------------------------------------------------------------------------------------
FUNCTION CHECK_PRIMARY_TO_CHILDREN(O_error_message            IN OUT VARCHAR2,
                                   O_child_primary_exists_ind IN OUT VARCHAR2,
                                   I_item                     IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                   I_supplier                 IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                   I_origin_country_id        IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   return BOOLEAN IS


   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.CHECK_PRIMARY_TO_CHILDREN';
   L_exists                ITEM_MASTER.ITEM%TYPE;

   cursor C_PRIMARY_EXISTS is
      select im.item
        from item_master im
       where (im.item_parent = I_item
              or im.item_grandparent = I_item)
         and im.item_level <= im.tran_level
         and exists (select 'x'
                           from item_supp_country isc
                          where isc.item = im.item
                            and isc.supplier = I_supplier
                            and isc.origin_country_id != I_origin_country_id
                            and isc.primary_country_ind = 'Y');

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_PRIMARY_EXISTS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
   open C_PRIMARY_EXISTS;
   SQL_LIB.SET_MARK('OPEN','C_PRIMARY_EXISTS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
   fetch C_PRIMARY_EXISTS into L_exists;
      if C_PRIMARY_EXISTS%FOUND then
         O_child_primary_exists_ind := 'Y';
      else
         O_child_primary_exists_ind := 'N';
      end if;
   SQL_LIB.SET_MARK('OPEN','C_PRIMARY_EXISTS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                   ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
   close C_PRIMARY_EXISTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CHECK_PRIMARY_TO_CHILDREN;
--------------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_DIMENSION_TO_CHILDREN(O_error_message     IN OUT VARCHAR2,
                                      I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                      I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                      I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                                      I_dim_object        IN     ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE,
                                      I_insert            IN     VARCHAR2)
   return BOOLEAN IS


   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.UPDATE_DIMENSION_TO_CHILDREN';
   L_table                 VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY_DIM';
   L_child_item            ITEM_MASTER.ITEM%TYPE := NULL;
   L_presentation_method   ITEM_SUPP_COUNTRY_DIM.PRESENTATION_METHOD%TYPE;
   L_length                ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
   L_width                 ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
   L_height                ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
   L_lwh_uom               ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE;
   L_weight                ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
   L_net_weight            ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE;
   L_weight_uom            ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
   L_liquid_volume         ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
   L_liquid_volume_uom     ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE;
   L_stat_cube             ITEM_SUPP_COUNTRY_DIM.STAT_CUBE%TYPE;
   L_tare_weight           ITEM_SUPP_COUNTRY_DIM.TARE_WEIGHT%TYPE;
   L_tare_type             ITEM_SUPP_COUNTRY_DIM.TARE_TYPE%TYPE;
   ---
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);



   cursor C_GET_CHILD_ITEMS is
      select im.item
        from item_master im
       where (im.item_parent = I_item
              or im.item_grandparent = I_item)
         and im.item_level <= im.tran_level
         and exists (select 'x'
                       from item_supp_country_dim isd
                      where isd.item = im.item
                        and isd.supplier = I_supplier
                        and isd.origin_country = I_origin_country_id);

   cursor C_GET_CHILD_ITEMS_INSERT is
      select im.item
        from item_master im
       where (im.item_parent = I_item
              or im.item_grandparent = I_item)
         and im.item_level <= im.tran_level
         and exists (select 'x'
                       from item_supp_country isc
                       where isc.item = im.item
                         and isc.supplier = I_supplier
                         and isc.origin_country_id = I_origin_country_id)
         and exists (select 'x'
                       from item_supp_country_dim isd
                      where isd.item = I_item
                        and isd.supplier = I_supplier
                        and isd.origin_country = I_origin_country_id);

   cursor C_GET_DIMENSIONS is
      select isd.presentation_method,
             isd.length,
             isd.width,
             isd.height,
             isd.lwh_uom,
             isd.weight,
             isd.net_weight,
             isd.weight_uom,
             isd.liquid_volume,
             isd.liquid_volume_uom,
             isd.stat_cube,
             isd.tare_weight,
             isd.tare_type
        from item_supp_country_dim isd
       where isd.item = I_item
         and isd.supplier = I_supplier
         and isd.origin_country = I_origin_country_id
         and isd.dim_object = I_dim_object;


   cursor C_LOCK_DIMENSIONS is
      select 'x'
        from item_supp_country_dim isd
       where isd.item = L_child_item
         and isd.supplier = I_supplier
         and isd.origin_country = I_origin_country_id
         and isd.dim_object = I_dim_object;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_dim_object is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_dim_object',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_insert = 'N' then
      SQL_LIB.SET_MARK('OPEN','C_GET_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      open C_GET_DIMENSIONS;
      SQL_LIB.SET_MARK('FETCH','C_GET_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      fetch C_GET_DIMENSIONS into L_presentation_method,
                                  L_length,
                                  L_width,
                                  L_height,
                                  L_lwh_uom,
                                  L_weight,
                                  L_net_weight,
                                  L_weight_uom,
                                  L_liquid_volume,
                                  L_liquid_volume_uom,
                                  L_stat_cube,
                                  L_tare_weight,
                                  L_tare_type;
      SQL_LIB.SET_MARK('CLOSE','C_GET_DIMENSIONS ','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      close C_GET_DIMENSIONS;
      ---
      for c_rec in C_GET_CHILD_ITEMS LOOP
         L_child_item := c_rec.item;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                          ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
         update item_supp_country_dim isd
            set isd.presentation_method = NVL(L_presentation_method, presentation_method),
                isd.length = NVL(L_length, length),
                isd.width = NVL(L_width, width),
                isd.height = NVL(L_height, height),
                isd.lwh_uom = NVL(L_lwh_uom, lwh_uom),
                isd.weight = NVL(L_weight, weight),
                isd.net_weight = NVL(L_net_weight, net_weight),
                isd.weight_uom = NVL(L_weight_uom, weight_uom),
                isd.liquid_volume =  NVL(L_liquid_volume, liquid_volume),
                isd.liquid_volume_uom = NVL(L_liquid_volume_uom, liquid_volume_uom),
                isd.stat_cube =  NVL(L_stat_cube, stat_cube),
                isd.tare_weight =  NVL(L_tare_weight, tare_weight),
                isd.tare_type =  NVL(L_tare_type, tare_type),
                isd.last_update_datetime = sysdate,
                isd.last_update_id = user
          where isd.item = L_child_item
            and isd.supplier = I_supplier
            and isd.origin_country = I_origin_country_id
            and isd.dim_object = I_dim_object;
      end LOOP;
      ---
      for c_rec in C_GET_CHILD_ITEMS_INSERT LOOP
         L_child_item := c_rec.item;
         ---
         SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                          ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
         insert into item_supp_country_dim(item,
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
                                    select L_child_item,
                                           I_supplier,
                                           I_origin_country_id,
                                           I_dim_object,
                                           isd.presentation_method,
                                           isd.length,
                                           isd.width,
                                           isd.height,
                                           isd.lwh_uom,
                                           isd.weight,
                                           isd.net_weight,
                                           isd.weight_uom,
                                           isd.liquid_volume,
                                           isd.liquid_volume_uom,
                                           isd.stat_cube,
                                           isd.tare_weight,
                                           isd.tare_type,
                                           sysdate,
                                           sysdate,
                                           user
                                      from item_supp_country_dim isd
                                     where isd.item = I_item
                                       and isd.supplier = I_supplier
                                       and isd.origin_country = I_origin_country_id
                                       and isd.dim_object = I_dim_object
                                       and not exists (select 'x'
                                                         from item_supp_country_dim isd
                                                        where isd.item = L_child_item
                                                          and isd.supplier = I_supplier
                                                          and isd.origin_country = I_origin_country_id
                                                          and isd.dim_object = I_dim_object);
      end LOOP;
   else
      for c_rec in C_GET_CHILD_ITEMS_INSERT LOOP
         L_child_item := c_rec.item;
         ---
         SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                          ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
         insert into item_supp_country_dim(item,
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
                                    select L_child_item,
                                           I_supplier,
                                           I_origin_country_id,
                                           I_dim_object,
                                           isd.presentation_method,
                                           isd.length,
                                           isd.width,
                                           isd.height,
                                           isd.lwh_uom,
                                           isd.weight,
                                           isd.net_weight,
                                           isd.weight_uom,
                                           isd.liquid_volume,
                                           isd.liquid_volume_uom,
                                           isd.stat_cube,
                                           isd.tare_weight,
                                           isd.tare_type,
                                           sysdate,
                                           sysdate,
                                           user
                                      from item_supp_country_dim isd
                                     where isd.item = I_item
                                       and isd.supplier = I_supplier
                                       and isd.origin_country = I_origin_country_id
                                       and isd.dim_object = I_dim_object
                                       and not exists (select 'x'
                                                         from item_supp_country_dim isd
                                                        where isd.item = L_child_item
                                                          and isd.supplier = I_supplier
                                                          and isd.origin_country = I_origin_country_id
                                                          and isd.dim_object = I_dim_object);
      end LOOP;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                            'I_item',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_DIMENSION_TO_CHILDREN;
-----------------------------------------------------------------------------------------------------------
FUNCTION FIRST_SUPPLIER(O_error_message      IN OUT VARCHAR2,
                        I_item               IN     item_supp_country.item%TYPE,
                        I_supplier           IN     item_supp_country.supplier%TYPE,
                        I_origin_country_id  IN     item_supp_country.origin_country_id%TYPE,
                        I_unit_cost          IN     item_supp_country.unit_cost%TYPE,
                        I_ti                 IN     item_supp_country.ti%TYPE,
                        I_hi                 IN     item_supp_country.hi%TYPE)
return BOOLEAN IS

   L_program            VARCHAR2(64) := 'xxx.FIRST_SUPPLIER';
   L_table              VARCHAR2(64) := NULL;
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);

   L_elc_ind            system_options.elc_ind%TYPE := NULL;
   L_supp_currency      store.currency_code%TYPE := NULL;

   L_loc                item_loc.loc%TYPE := NULL;
   L_loc_type           item_loc.loc_type%TYPE := NULL;
   L_local_currency     store.currency_code%TYPE := NULL;

   L_local_cost         item_loc_soh.unit_cost%TYPE := NULL;
   L_elc_cost           item_loc_soh.unit_cost%TYPE := NULL;

   L_pack_ind           item_master.pack_ind%TYPE := NULL;
   L_sellable           item_master.sellable_ind%TYPE := NULL;
   L_orderable          item_master.orderable_ind%TYPE := NULL;
   L_pack_type          item_master.pack_type%TYPE := NULL;

   /* not used, place holders for package call */
   L_total_exp          item_supp_country.unit_cost%TYPE := NULL;
   L_exp_currency       currencies.currency_code%TYPE := NULL;
   L_exchange_rate_exp  currency_rates.exchange_rate%TYPE := NULL;
   L_total_duty         item_supp_country.unit_cost%TYPE := NULL;
   L_dty_currency       currencies.currency_code%TYPE := NULL;

   cursor C_CHECK_ITEM_LOC is
       select il.loc,
              il.loc_type,
              st.currency_code
         from item_loc il,
              store st
        where il.item = I_item
          and il.loc = st.store
    union all
       select il.loc,
              il.loc_type,
              w.currency_code
         from item_loc il,
              wh w
        where il.item = I_item
          and il.loc = w.wh;

   cursor C_LOCK_ITEM_LOC is
       select 'x'
         from item_loc
        where item = I_item
          and loc = L_loc
          for update nowait;

   cursor C_LOCK_ITEM_LOC_SOH is
       select 'x'
         from item_loc_soh
        where item = I_item
          and loc = L_loc
          for update nowait;
BEGIN

   /* make sure required parameters are populated */
   if I_item is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_supplier',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;
   if I_origin_country_id is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_origin_country_id',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;
   if I_unit_cost is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_unit_cost',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if not SYSTEM_OPTIONS_SQL.GET_ELC_IND(O_error_message,
                                         L_elc_ind) then
      return FALSE;
   end if;

   if not SUPP_ATTRIB_SQL.GET_CURRENCY_CODE(O_error_message,
                                            L_supp_currency,
                                            I_supplier) then
      return FALSE;
   end if;

   FOR c_rec in C_CHECK_ITEM_LOC LOOP

      L_loc := c_rec.loc;
      L_loc_type := c_rec.loc_type;
      L_local_currency := c_rec.currency_code;

      if L_elc_ind = 'Y' then
         if not ELC_CALC_SQL.CALC_TOTALS(O_error_message,
                                         L_elc_cost,
                                         L_total_exp,
                                         L_exp_currency,
                                         L_exchange_rate_exp,
                                         L_total_duty,
                                         L_dty_currency,
                                         NULL,                 --order_no
                                         I_item,
                                         NULL,                 --comp_sku
                                         NULL,                 --zone_id
                                         NULL,                 --location
                                         I_supplier,
                                         I_origin_country_id,
                                         NULL,                 --import_country_id
                                         I_unit_cost) then
            return FALSE;
         end if;

         /* convert the elc cost back to the location's currency */
         if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                             NULL,
                                             NULL,
                                             NULL,
                                             L_loc,
                                             L_loc_type,
                                             NULL,
                                             L_elc_cost,
                                             L_local_cost,
                                             'C',
                                             NULL,
                                             NULL) = FALSE then
             return FALSE;
         end if;

      else /* elc is not being used */

         if L_local_currency != L_supp_currency then
            if not CURRENCY_SQL.CONVERT(O_error_message,
                                        I_unit_cost,
                                        L_supp_currency,
                                        L_local_currency,
                                        L_local_cost,
                                        'C',
                                        NULL,
                                        NULL) then
               return FALSE;
            end if;
         else
            L_local_cost := I_unit_cost;
         end if;

      end if;

      /* if item is a pack item (vendor or buyer), then unit cost won't be updated on item_loc */
      if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                       L_pack_ind,
                                       L_sellable,
                                       L_orderable,
                                       L_pack_type,
                                       I_item) = FALSE then
         return FALSE;
      end if;
      ---
      if L_pack_ind = 'Y' then
         L_local_cost := NULL;
      end if;
      ---
      L_table := 'ITEM_LOC';
      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_LOC', 'Item: '||I_item || ' Loc: ' ||L_loc);
      open C_LOCK_ITEM_LOC;
      close C_LOCK_ITEM_LOC;
      update item_loc
         set primary_supp = I_supplier,
             primary_cntry = I_origin_country_id,
             ti = NVL(ti, I_ti),
             hi = NVL(hi, I_hi),
             last_update_datetime = sysdate,
             last_update_id = user
       where item = I_item
         and loc = L_loc;
      ---
      L_table := 'ITEM_LOC_SOH';
      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_LOC_SOH', 'Item: '||I_item || ' Loc: ' ||L_loc);
      open C_LOCK_ITEM_LOC_SOH;
      close C_LOCK_ITEM_LOC_SOH;
      update item_loc_soh
         set unit_cost = L_local_cost,
             av_cost = L_local_cost,
             last_update_datetime = sysdate,
             last_update_id = user
       where item = I_item
         and loc = L_loc;
      ---
   end LOOP;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                               L_table,
                                                               I_item,
                                                               L_loc);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END FIRST_SUPPLIER;
---------------------------------------------------------------------------------------------------
FUNCTION GET_TI_HI(O_error_message OUT VARCHAR2,
                   O_ti            OUT item_supp_country.ti%TYPE,
                   O_hi            OUT item_supp_country.hi%TYPE,
                   I_item          IN item_master.item%TYPE)
return BOOLEAN IS

L_program VARCHAR2(62):= 'ITEM_SUPP_COUNTRY_SQL.GET_TI_HI';

cursor C_GET_PRIM_TI_HI is
   select ti,
          hi
     from item_supp_country
    where primary_supp_ind = 'Y'
      and primary_country_ind = 'Y'
      and item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   open C_GET_PRIM_TI_HI;
   fetch C_GET_PRIM_TI_HI into O_ti,
                               O_hi;
   close C_GET_PRIM_TI_HI;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TI_HI;
---------------------------------------------------------------------------------------------------
FUNCTION GET_TI_HI(O_error_message OUT VARCHAR2,
                   O_ti            OUT item_supp_country.ti%TYPE,
                   O_hi            OUT item_supp_country.hi%TYPE,
                   I_item          IN  item_master.item%TYPE,
                   I_supplier      IN  sups.supplier%TYPE)
return BOOLEAN IS

L_program VARCHAR2(62):= 'ITEM_SUPP_COUNTRY_SQL.GET_TI_HI';

cursor C_GET_PRIM_TI_HI is
   select ti,
          hi
     from item_supp_country
    where supplier = I_supplier
      and primary_country_ind = 'Y'
      and item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   open C_GET_PRIM_TI_HI;
   fetch C_GET_PRIM_TI_HI into O_ti,
                               O_hi;
   close C_GET_PRIM_TI_HI;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TI_HI;
---------------------------------------------------------------------------------------------------
FUNCTION GET_TI_HI(O_error_message OUT VARCHAR2,
                   O_ti            OUT item_supp_country.ti%TYPE,
                   O_hi            OUT item_supp_country.hi%TYPE,
                   I_item          IN  item_master.item%TYPE,
                   I_supplier      IN  sups.supplier%TYPE,
                   I_country       IN  country.country_id%TYPE)
return BOOLEAN IS

L_program VARCHAR2(62):= 'ITEM_SUPP_COUNTRY_SQL.GET_TI_HI';

cursor C_GET_PRIM_TI_HI is
   select ti,
          hi
     from item_supp_country
    where supplier = I_supplier
      and origin_country_id = I_country
      and item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_country is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_country',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   open C_GET_PRIM_TI_HI;
   fetch C_GET_PRIM_TI_HI into O_ti,
                               O_hi;
   close C_GET_PRIM_TI_HI;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TI_HI;
---------------------------------------------------------------------------------------------------
FUNCTION EXPENSES_EXIST(O_error_message      IN OUT VARCHAR2,
                        O_exists             IN OUT BOOLEAN,
                        I_item               IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                        I_supplier           IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                        I_origin_country_id  IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
 return BOOLEAN IS

 L_program          VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.EXPENSES_EXIST';
 L_expense          VARCHAR2(1);

 cursor C_ITEM_EXP is
     select 'x'
       from item_exp_head ieh
      where ieh.supplier = I_supplier
        and ieh.item     = I_item
        and ieh.origin_country_id = I_origin_country_id;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ITEM_EXP','ITEM_EXP_HEAD','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
   open C_ITEM_EXP;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_EXP','ITEM_EXP_HEAD','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
   fetch C_ITEM_EXP into L_expense;
      if C_ITEM_EXP%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_EXP','ITEM_EXP_HEAD','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_origin_country_id);
   close C_ITEM_EXP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END EXPENSES_EXIST;
-------------------------------------------------------------------------------------------------------------
FUNCTION GET_PRIM_SUPP_CNTRY(O_error_message OUT VARCHAR2,
                             O_prim_supp     OUT sups.supplier%TYPE,
                             O_prim_cntry    OUT country.country_id%TYPE,
                             I_item          IN  item_master.item%TYPE)
  return BOOLEAN is

L_program VARCHAR2(62):= 'ITEM_SUPP_COUNTRY_SQL.GET_PRIM_SUPP_CNTRY';

cursor C_GET_PRIM_SUPP_CNTRY is
   select supplier,
          origin_country_id
     from item_supp_country
    where item = I_item
      and primary_supp_ind = 'Y'
      and primary_country_ind = 'Y';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   open C_GET_PRIM_SUPP_CNTRY;
   fetch C_GET_PRIM_SUPP_CNTRY into O_prim_supp,
                                    O_prim_cntry;
   close C_GET_PRIM_SUPP_CNTRY;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_PRIM_SUPP_CNTRY;
---------------------------------------------------------------------------------------------------
FUNCTION DEFAULT_PRIM_CASE_SIZE(O_error_message      IN OUT VARCHAR2,
                                O_supp_pack_size     IN OUT ITEM_SUPP_COUNTRY.supp_pack_size%TYPE,
                                O_inner_pack_size    IN OUT ITEM_SUPP_COUNTRY.inner_pack_size%TYPE,
                                I_item               IN     ITEM_SUPP_COUNTRY.item%TYPE)

return BOOLEAN is

L_program VARCHAR2(62):= 'ITEM_SUPP_COUNTRY_SQL.DEFAULT_PRIM_CASE_SIZE';

cursor C_GET_PRIM_CASE_SIZE is
   select supp_pack_size,
          inner_pack_size
     from item_supp_country
    where item = I_item
      and primary_supp_ind = 'Y'
      and primary_country_ind = 'Y';


BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
    ---
   SQL_LIB.SET_MARK('OPEN','C_GET_PRIM_CASE_SIZE','ITEM_SUPP_COUNTRY','Item: '||I_item);
   open C_GET_PRIM_CASE_SIZE;
   SQL_LIB.SET_MARK('FETCH','C_GET_PRIM_CASE_SIZE','ITEM_SUPP_COUNTRY','Item: '||I_item);
   fetch C_GET_PRIM_CASE_SIZE into O_supp_pack_size,
                                   O_inner_pack_size;
   SQL_LIB.SET_MARK('CLOSE','C_GET_PRIM_CASE_SIZE','ITEM_SUPP_COUNTRY','Item: '||I_item);
   close C_GET_PRIM_CASE_SIZE;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEFAULT_PRIM_CASE_SIZE;
---------------------------------------------------------------------------------------------------
FUNCTION DEFAULT_PRIM_CASE_DIMENSIONS(O_error_message       IN OUT VARCHAR2,
                                      I_item                IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                      I_supplier            IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                      I_origin_country_id   IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                                      O_exists              IN OUT BOOLEAN,
                                      O_dim_object          IN OUT ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE,
                                      O_presentation_method IN OUT ITEM_SUPP_COUNTRY_DIM.PRESENTATION_METHOD%TYPE,
                                      O_length              IN OUT ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE,
                                      O_width               IN OUT ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE,
                                      O_height              IN OUT ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE,
                                      O_lwh_uom             IN OUT ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE,
                                      O_weight              IN OUT ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                                      O_net_weight          IN OUT ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE,
                                      O_weight_uom          IN OUT ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE,
                                      O_liquid_volume       IN OUT ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE,
                                      O_liquid_volume_uom   IN OUT ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE,
                                      O_stat_cube           IN OUT ITEM_SUPP_COUNTRY_DIM.STAT_CUBE%TYPE,
                                      O_tare_weight         IN OUT ITEM_SUPP_COUNTRY_DIM.TARE_WEIGHT%TYPE,
                                      O_tare_type           IN OUT ITEM_SUPP_COUNTRY_DIM.TARE_TYPE%TYPE)

return BOOLEAN is

L_program VARCHAR2(62):= 'ITEM_SUPP_COUNTRY_SQL.DEFAULT_PRIM_CASE_DIMENSIONS';

L_supplier             ITEM_SUPP_COUNTRY.SUPPLIER%TYPE;
L_origin_country_id    ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;

cursor C_GET_PRIMARY is
   select origin_country_id,
          supplier
     from item_supp_country isc
    where isc.item = I_item
      and isc.primary_supp_ind = 'Y'
      and isc.primary_country_ind = 'Y';

cursor C_GET_PRIM_CASE_DIMENSIONS is
   select dim_object,
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
          tare_type
     from item_supp_country_dim isd
    where isd.item = I_item
      and isd.supplier = L_supplier
      and isd.origin_country = L_origin_country_id
      and isd.dim_object = 'CA';

BEGIN
    if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
     ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   for c_rec in C_GET_PRIMARY LOOP
      L_supplier := c_rec.supplier;
      L_origin_country_id := c_rec.origin_country_id;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_PRIM_CASE_DIMENSIONS','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item);
      open C_GET_PRIM_CASE_DIMENSIONS;
      SQL_LIB.SET_MARK('FETCH','C_GET_PRIM_CASE_DIMENSIONS','ITEM_SUPP_COUNTRY','Item: '||I_item);
      fetch C_GET_PRIM_CASE_DIMENSIONS into O_dim_object,
                                         O_presentation_method,
                                         O_length,
                                         O_width,
                                         O_height,
                                         O_lwh_uom,
                                         O_weight,
                                         O_net_weight,
                                         O_weight_uom,
                                         O_liquid_volume,
                                         O_liquid_volume_uom,
                                         O_stat_cube,
                                         O_tare_weight,
                                         O_tare_type;
         if C_GET_PRIM_CASE_DIMENSIONS%FOUND then
            O_exists := TRUE;
         else
            O_exists := FALSE;
         end if;
      SQL_LIB.SET_MARK('CLOSE','C_GET_PRIM_CASE_DIMENSIONS','ITEM_SUPP_COUNTRY','Item: '||I_item);
      close C_GET_PRIM_CASE_DIMENSIONS;
   end LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEFAULT_PRIM_CASE_DIMENSIONS;
---------------------------------------------------------------------------------------------------
FUNCTION CHECK_CASE_DIMENSION(O_error_message      IN OUT VARCHAR2,
                              O_exists             IN OUT BOOLEAN,
                              I_item               IN     ITEM_SUPPLIER.ITEM%TYPE,
                              I_supplier           IN     ITEM_SUPPLIER.SUPPLIER%TYPE,
                              I_origin_country_id  IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)

return BOOLEAN IS

   L_program         VARCHAR2(64)  := 'SUPP_ITEM_SQL.CHECK_CHECK_CASE_DIMENSION';
   L_country_exists  BOOLEAN;
   L_exists          VARCHAR2(1);


   cursor CHECK_STANDARD_UOM is
      select 'x'
        from item_master im
       where im.item = I_item
         and exists( select 'x'
                       from uom_class uc1
                      where uc1.uom = im.standard_uom
                        and uc1.uom_class = 'QTY' );
   cursor CHECK_PRIMARY is
      select 'x'
        from item_supp_country isc
       where isc.item                 = I_item
         and isc.supplier             = I_supplier
         and isc.origin_country_id    = I_origin_country_id
         and isc.primary_country_ind  = 'Y'
         and isc.primary_supp_ind     = 'Y';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_SUPPLIER',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'CHECK_PRIMARY',
                    'ITEM_SUPP_COUNTRY',
                    'Item: '||I_item||', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id);
   open CHECK_PRIMARY;
   SQL_LIB.SET_MARK('FETCH',
                    'CHECK_PRIMARY',
                    'ITEM_SUPP_COUNTRY',
                    'Item: '||I_item||', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id);
   fetch CHECK_PRIMARY into L_exists;
      if CHECK_PRIMARY%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'CHECK_PRIMARY',
                          'ITEM_SUPP_COUNTRY',
                          'Item: '||I_item||', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id);
         close CHECK_PRIMARY;
         O_exists := FALSE;
         return TRUE;
      else
         SQL_LIB.SET_MARK('CLOSE',
                          'CHECK_PRIMARY',
                          'ITEM_SUPP_COUNTRY',
                          'Item: '||I_item||', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id);
         close CHECK_PRIMARY;
      end if;

   --- Determine if there is a need to check for the CASE dimension.
   SQL_LIB.SET_MARK('OPEN',
                    'CHECK_STANDARD_UOM',
                    'ITEM_MASTER, UOM_CLASS',
                    'Item: '||I_item);
   open CHECK_STANDARD_UOM;
   SQL_LIB.SET_MARK('FETCH',
                    'CHECK_STANDARD_UOM',
                    'ITEM_MASTER, UOM_CLASS',
                    'Item: '||I_item);
   fetch CHECK_STANDARD_UOM into L_exists;
   if CHECK_STANDARD_UOM%FOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'CHECK_STANDARD_UOM',
                       'ITEM_MASTER, UOM_CLASS',
                       'Item: '||I_item);
      close CHECK_STANDARD_UOM;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_CASE_DIM',
                                             NULL,
                                             NULL,
                                             NULL);
      ---
      O_exists := TRUE;
      return TRUE;
   else
      O_exists := FALSE;
      SQL_LIB.SET_MARK('CLOSE',
                       'CHECK_STANDARD_UOM',
                       'ITEM_MASTER, UOM_CLASS',
                       'Item: '||I_item);
      close CHECK_STANDARD_UOM;
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
END CHECK_CASE_DIMENSION;
-----------------------------------------------------------------------------------------
FUNCTION GET_COUNTRY_PARAMETERS(O_error_message     IN OUT VARCHAR2,
                                O_primary_ind       IN OUT ITEM_SUPP_COUNTRY.PRIMARY_COUNTRY_IND%TYPE,
                                O_supp_pack_size    IN OUT ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE,
                                I_item              IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                I_supplier          IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   return BOOLEAN IS


   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.GET_COUNTRY_PARAMETERS';


   cursor C_GET_PRIMARY_IND is
      select primary_country_ind,
             supp_pack_size
        from item_supp_country
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_origin_country_id;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_PRIMARY_IND','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier));
   open C_GET_PRIMARY_IND;
   SQL_LIB.SET_MARK('FETCH','C_GET_PRIMARY_IND','ITEM_SUPP_COUNTRY','ITEM: '||I_item||
                    ' Supplier: '||to_char(I_supplier));
   fetch C_GET_PRIMARY_IND into O_primary_ind,
                                O_supp_pack_size;
   SQL_LIB.SET_MARK('CLOSE','C_GET_PRIMARY_IND','ITEM_SUPP_COUNTRY','ITEM: '||I_item||
                    ' Supplier: '||to_char(I_supplier));
   close C_GET_PRIMARY_IND;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_COUNTRY_PARAMETERS;
-----------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_COUNTRY_TO_CHILDREN(O_error_message       IN OUT VARCHAR2,
                                    I_item                IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                    I_supplier            IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                    I_origin_country_id   IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                                    I_edit_cost           IN     VARCHAR2)
   return BOOLEAN IS


   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.UPDATE_COUNTRY_TO_CHILDREN';
   L_table                 VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY';
   L_child_item            ITEM_MASTER.ITEM%TYPE;
   L_parent_cost           ITEM_SUPP_COUNTRY.UNIT_COST%TYPE := NULL;
   L_child_cost            ITEM_SUPP_COUNTRY.UNIT_COST%TYPE := NULL;
   L_lead_time             ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE;
   L_pickup_lead_time      ITEM_SUPP_COUNTRY.PICKUP_LEAD_TIME%TYPE;
   L_supp_pack_size        ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE;
   L_inner_pack_size       ITEM_SUPP_COUNTRY.INNER_PACK_SIZE%TYPE;
   L_min_order_qty         ITEM_SUPP_COUNTRY.MIN_ORDER_QTY%TYPE;
   L_max_order_qty         ITEM_SUPP_COUNTRY.MAX_ORDER_QTY%TYPE;
   L_packing_method        ITEM_SUPP_COUNTRY.PACKING_METHOD%TYPE;
   L_default_uop           ITEM_SUPP_COUNTRY.DEFAULT_UOP%TYPE;
   L_ti                    ITEM_SUPP_COUNTRY.TI%TYPE;
   L_hi                    ITEM_SUPP_COUNTRY.HI%TYPE;
   L_supp_hier_lvl_1       ITEM_SUPP_COUNTRY.SUPP_HIER_LVL_1%TYPE;
   L_supp_hier_type_1      ITEM_SUPP_COUNTRY.SUPP_HIER_TYPE_1%TYPE;
   L_supp_hier_lvl_2       ITEM_SUPP_COUNTRY.SUPP_HIER_LVL_2%TYPE;
   L_supp_hier_type_2      ITEM_SUPP_COUNTRY.SUPP_HIER_TYPE_2%TYPE;
   L_supp_hier_lvl_3       ITEM_SUPP_COUNTRY.SUPP_HIER_LVL_3%TYPE;
   L_supp_hier_type_3      ITEM_SUPP_COUNTRY.SUPP_HIER_TYPE_3%TYPE;
   L_round_level           ITEM_SUPP_COUNTRY.ROUND_LVL%TYPE;
   L_to_inner_pct          ITEM_SUPP_COUNTRY.ROUND_TO_INNER_PCT%TYPE;
   L_to_case_pct           ITEM_SUPP_COUNTRY.ROUND_TO_CASE_PCT%TYPE;
   L_to_layer_pct          ITEM_SUPP_COUNTRY.ROUND_TO_LAYER_PCT%TYPE;
   L_to_pallet_pct         ITEM_SUPP_COUNTRY.ROUND_TO_PALLET_PCT%TYPE;
   ---
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);



   cursor C_GET_CHILD_ITEMS is
      select im.item
        from item_master im
       where (im.item_parent = I_item
              or im.item_grandparent = I_item)
         and im.item_level <= im.tran_level
         and exists (select 'x'
                       from item_supp_country isc
                      where isc.item = im.item
                        and isc.supplier = I_supplier
                        and isc.origin_country_id = I_origin_country_id);

   cursor C_GET_COUNTRY_DETAILS is
      select isc.lead_time,
             isc.pickup_lead_time,
             isc.supp_pack_size,
             isc.inner_pack_size,
             isc.round_lvl,
             isc.round_to_inner_pct,
             isc.round_to_case_pct,
             isc.round_to_layer_pct,
             isc.round_to_pallet_pct,
             isc.min_order_qty,
             isc.max_order_qty,
             isc.packing_method,
             isc.default_uop,
             isc.ti,
             isc.hi,
             isc.supp_hier_lvl_1,
             isc.supp_hier_type_1,
             isc.supp_hier_lvl_2,
             isc.supp_hier_type_2,
             isc.supp_hier_lvl_3,
             isc.supp_hier_type_3
        from item_supp_country isc
       where isc.item = I_item
         and isc.supplier = I_supplier
         and isc.origin_country_id = I_origin_country_id;

   cursor C_GET_PARENT_COST is
      select isc.unit_cost
        from item_supp_country isc
       where isc.item = I_item
         and isc.supplier = I_supplier
         and isc.origin_country_id = I_origin_country_id;

   cursor C_GET_CHILD_COST is
      select isc.unit_cost
        from item_supp_country isc
       where isc.item = L_child_item
         and isc.supplier = I_supplier
         and isc.origin_country_id = I_origin_country_id;

   cursor C_LOCK_COUNTRY_DETAILS is
      select 'x'
        from item_supp_country isc
       where isc.item = L_child_item
         and isc.supplier = I_supplier
         and isc.origin_country_id = I_origin_country_id;


BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_COUNTRY_DETAILS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   open C_GET_COUNTRY_DETAILS;
   SQL_LIB.SET_MARK('FETCH','C_GET_COUNTRY_DETAILS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   fetch C_GET_COUNTRY_DETAILS into L_lead_time,
                                    L_pickup_lead_time,
                                    L_supp_pack_size,
                                    L_inner_pack_size,
                                    L_round_level,
                                    L_to_inner_pct,
                                    L_to_case_pct,
                                    L_to_layer_pct,
                                    L_to_pallet_pct,
                                    L_min_order_qty,
                                    L_max_order_qty,
                                    L_packing_method,
                                    L_default_uop,
                                    L_ti,
                                    L_hi,
                                    L_supp_hier_lvl_1,
                                    L_supp_hier_type_1,
                                    L_supp_hier_lvl_2,
                                    L_supp_hier_type_2,
                                    L_supp_hier_lvl_3,
                                    L_supp_hier_type_3;
   SQL_LIB.SET_MARK('CLOSE','C_GET_COUNTRY_DETAILS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   close C_GET_COUNTRY_DETAILS;
   ---
   for c_rec in C_GET_CHILD_ITEMS LOOP
      L_child_item := c_rec.item;
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_COUNTRY_DETAILS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      open C_LOCK_COUNTRY_DETAILS;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_COUNTRY_DETAILS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      close C_LOCK_COUNTRY_DETAILS;
      ---
      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
      update item_supp_country isc
         set isc.lead_time = L_lead_time,
             isc.pickup_lead_time = L_pickup_lead_time,
             isc.supp_pack_size = L_supp_pack_size,
             isc.inner_pack_size = L_inner_pack_size,
             isc.round_lvl = L_round_level,
             isc.round_to_inner_pct = L_to_inner_pct,
             isc.round_to_case_pct = L_to_case_pct,
             isc.round_to_layer_pct = L_to_layer_pct,
             isc.round_to_pallet_pct = L_to_pallet_pct,
             isc.min_order_qty = L_min_order_qty,
             isc.max_order_qty = L_max_order_qty,
             isc.packing_method = L_packing_method,
             isc.default_uop = L_default_uop,
             isc.ti = L_ti,
             isc.hi = L_hi,
             isc.supp_hier_lvl_1 = L_supp_hier_lvl_1,
             isc.supp_hier_type_1 = L_supp_hier_type_1,
             isc.supp_hier_lvl_2 = L_supp_hier_lvl_2,
             isc.supp_hier_type_2 = L_supp_hier_type_2,
             isc.supp_hier_lvl_3 = L_supp_hier_lvl_3,
             isc.supp_hier_type_3 = L_supp_hier_type_3,
             isc.last_update_datetime = sysdate,
             isc.last_update_id = user
       where isc.item = L_child_item
         and isc.supplier = I_supplier
         and isc.origin_country_id = I_origin_country_id;
      ---
      if I_edit_cost = 'Y' then
         SQL_LIB.SET_MARK('OPEN','C_GET_PARENT_COST','ITEM_SUPP_COUNTRY','Item: '||I_item||
                          ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
         open C_GET_PARENT_COST;
         SQL_LIB.SET_MARK('FETCH','C_GET_PARENT_COST','ITEM_SUPP_COUNTRY','Item: '||I_item||
                          ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
         fetch C_GET_PARENT_COST into L_parent_cost;
         SQL_LIB.SET_MARK('CLOSE','C_GET_PARENT_COST', 'ITEM_SUPP_COUNTRY','Item: '||I_item||
                          ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
         close C_GET_PARENT_COST;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
         ---
         update item_supp_country isc
            set isc.unit_cost = L_parent_cost
          where isc.item = L_child_item
            and isc.supplier = I_supplier
            and isc.origin_country_id = I_origin_country_id;
      end if;
   end LOOP;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                            'I_item',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_COUNTRY_TO_CHILDREN;
-----------------------------------------------------------------------------------------------------------
FUNCTION GET_UNIT_COST(O_error_message       OUT VARCHAR2,
                       O_unit_cost           OUT item_supp_country.unit_cost%TYPE,
                       I_item                IN  item_master.item%TYPE,
                       I_supplier            IN  sups.supplier%TYPE,
                       I_origin_country_id   IN  country.country_id%TYPE)
return BOOLEAN IS

L_program VARCHAR2(62):= 'ITEM_SUPP_COUNTRY_SQL.GET_UNIT_COST';

cursor C_GET_UNIT_COST is
   select unit_cost
     from item_supp_country
    where supplier = I_supplier
      and origin_country_id = I_origin_country_id
      and item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   open C_GET_UNIT_COST;
   SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   fetch C_GET_UNIT_COST into O_unit_cost;
   SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   close C_GET_UNIT_COST;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_UNIT_COST;
---------------------------------------------------------------------------------------------------
FUNCTION DELETE_CONST_DIMENSIONS(O_error_message       OUT VARCHAR2,
                                 I_item                IN  item_master.item%TYPE,
                                 I_supplier            IN  sups.supplier%TYPE,
                                 I_origin_country_id   IN  country.country_id%TYPE,
                                 I_dim_object          IN  item_supp_country_dim.dim_object%TYPE,
                                 I_delete_children     IN  VARCHAR2)
   return BOOLEAN IS

   L_program               VARCHAR2(62):= 'ITEM_SUPP_COUNTRY_SQL.DELETE_CONST_DIMENSIONS';
   L_table                 VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY_DIM';
   L_child_item            ITEM_MASTER.ITEM%TYPE;
   ---
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);



   cursor C_LOCK_DIM_OBJECT is
      select 'x'
        from item_supp_country_dim
       where item = I_item
         and supplier != I_supplier
         and origin_country != I_origin_country_id
         and dim_object = NVL(I_dim_object, dim_object);

   cursor C_GET_CHILD_ITEMS is
         select im.item
           from item_master im
          where (im.item_parent = I_item
                 or im.item_grandparent = I_item)
            and im.item_level <= im.tran_level
            and exists (select 'x'
                          from item_supp_country_dim isd
                         where isd.item = im.item
                           and supplier != I_supplier
                           and origin_country != I_origin_country_id);

   cursor C_LOCK_CHILD_DIM_OBJECT is
      select 'x'
        from item_supp_country_dim
       where item = L_child_item
         and supplier != I_supplier
         and origin_country != I_origin_country_id
         and dim_object = NVL(I_dim_object, dim_object);


BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DIM_OBJECT','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   open C_LOCK_DIM_OBJECT;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DIM_OBJECT','ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
   close C_LOCK_DIM_OBJECT;
   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id||
                    ' Dim_Object: '|| I_dim_object);
   delete from item_supp_country_dim
      where item = I_item
        and (supplier != I_supplier
             or origin_country != I_origin_country_id)
        and dim_object = NVL(I_dim_object, dim_object);
   ---
   if I_delete_children = 'Y' then
      for c_rec in C_GET_CHILD_ITEMS LOOP
         ---
         L_child_item := c_rec.item;
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_DIM_OBJECT','ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                          ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
         open C_LOCK_DIM_OBJECT;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_DIM_OBJECT','ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                          ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id);
         close C_LOCK_DIM_OBJECT;
         ---
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_DIM','Item: '||L_child_item||
                          ' Supplier: '||to_char(I_supplier)||' Origin_Country: '|| I_origin_country_id||
                          ' Dim_Object: '|| I_dim_object);
        delete from item_supp_country_dim
           where item = L_child_item
             and (supplier != I_supplier
                 or origin_country != I_origin_country_id)
             and dim_object = NVL(I_dim_object, dim_object);
      end LOOP;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                            'I_item',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_CONST_DIMENSIONS;
-------------------------------------------------------------------------------------------------------------
FUNCTION CHECK_CHILD_PRIMARY_EXISTS(O_error_message            IN OUT VARCHAR2,
                                    O_exists                   IN OUT VARCHAR2,
                                    I_item                     IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                    I_supplier                 IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE)
   return BOOLEAN IS


   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.CHECK_CHILD_PRIMARY_EXISTS';
   L_exists                ITEM_MASTER.ITEM%TYPE;

   cursor C_PRIMARY_EXISTS is
      select im.item
        from item_master im
       where (im.item_parent = I_item
              or im.item_grandparent = I_item)
         and im.item_level <= im.tran_level
         and exists (select 'x'
                           from item_supp_country isc
                          where isc.item = im.item
                            and isc.supplier = I_supplier
                            and isc.primary_country_ind = 'Y');

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_PRIMARY_EXISTS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier));
   open C_PRIMARY_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_PRIMARY_EXISTS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier));
   fetch C_PRIMARY_EXISTS into L_exists;
      if C_PRIMARY_EXISTS%FOUND then
         O_exists := 'Y';
      else
         O_exists := 'N';
      end if;
   SQL_LIB.SET_MARK('CLOSE','C_PRIMARY_EXISTS','ITEM_SUPP_COUNTRY','Item: '||I_item||
                   ' Supplier: '||to_char(I_supplier));
   close C_PRIMARY_EXISTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CHECK_CHILD_PRIMARY_EXISTS;
--------------------------------------------------------------------------------------------------------------
FUNCTION GET_DFLT_RND_LVL_ITEM (O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                O_round_level     IN OUT  SUP_INV_MGMT.ROUND_LVL%TYPE,
                                O_to_inner_pct    IN OUT  SUP_INV_MGMT.ROUND_TO_INNER_PCT%TYPE,
                                O_to_case_pct     IN OUT  SUP_INV_MGMT.ROUND_TO_CASE_PCT%TYPE,
                                O_to_layer_pct    IN OUT  SUP_INV_MGMT.ROUND_TO_LAYER_PCT%TYPE,
                                O_to_pallet_pct   IN OUT  SUP_INV_MGMT.ROUND_TO_PALLET_PCT%TYPE,
                                I_item            IN      ITEM_MASTER.ITEM%TYPE,
                                I_supplier        IN      SUP_INV_MGMT.SUPPLIER%TYPE,
                                I_dept            IN      SUP_INV_MGMT.DEPT%TYPE,
                                I_origin_country  IN      ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                                I_location        IN      ITEM_LOC.LOC%TYPE)
RETURN BOOLEAN IS
   L_im_lvl  SUPS.INV_MGMT_LVL%TYPE;
   L_dept    ITEM_MASTER.DEPT%TYPE      := I_dept;

   CURSOR C_get_im_lvl is
      select inv_mgmt_lvl
        from sups
       where supplier = I_supplier;

   CURSOR C_get_dept is
      select dept
        from item_master
       where item = I_item;

   CURSOR C_get_info_sys is
      select round_lvl, round_to_inner_pct, round_to_case_pct,
             round_to_layer_pct, round_to_pallet_pct
        from system_options;

   CURSOR C_get_info_sup is
      select round_lvl, round_to_inner_pct, round_to_case_pct,
             round_to_layer_pct, round_to_pallet_pct
        from sup_inv_mgmt
       where supplier = I_supplier
         and dept is NULL
         and location is NULL;

   CURSOR C_get_info_sup_dep is
      select round_lvl, round_to_inner_pct, round_to_case_pct,
             round_to_layer_pct, round_to_pallet_pct
        from sup_inv_mgmt
       where supplier = I_supplier
         and dept = L_dept
         and location is NULL;

   CURSOR C_get_info_sup_dep_loc is
      select sim.round_lvl, sim.round_to_inner_pct, sim.round_to_case_pct,
             sim.round_to_layer_pct, sim.round_to_pallet_pct
        from sup_inv_mgmt sim, wh w, system_options so
       where (   (    so.multichannel_ind = 'Y'
                  and w.wh = I_location
                  and w.physical_wh = sim.location)
              or (    so.multichannel_ind = 'N'
                  and w.wh = I_location
                  and sim.location = I_location))
         and sim.supplier = I_supplier
         and (   (L_im_lvl = 'A' and sim.dept = L_dept)
              or  L_im_lvl = 'L');

   CURSOR C_get_info_isc is
      select round_lvl, round_to_inner_pct, round_to_case_pct,
             round_to_layer_pct, round_to_pallet_pct
        from item_supp_country
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_origin_country;


BEGIN
   O_round_level := 'ZIP';  -- flag value to determine whether records are found
   ---
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            'ITEM_SUPP_COUNTRY_SQL.GET_DFLT_RND_LVL_ITEM',
                                            NULL);
      return FALSE;
   end if;
   ---
   /*Determine Supp. Inv. Mgmt. Level
     For Passed-in Supplier         */
    open C_get_im_lvl;
   fetch C_get_im_lvl into L_im_lvl;
      ---
      if C_get_im_lvl%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_SUPP_SUPP',
                                               to_char(I_supplier),
                                               NULL,
                                               NULL);
         close C_get_im_lvl;
         return FALSE;
      end if;
      ---
   close C_get_im_lvl;
   ---
   /* Fetch Rounding Info.,
      Defaulting As Necessary */
   if I_location is NULL then
      if L_im_lvl in ('D','A') then
         if I_dept is NULL then
            /*Determine Department
              For Passed-in Item */
             open C_get_dept;
            fetch C_get_dept into L_dept;
            ---
            if C_get_dept%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INVALID_ITEM',
                                                     I_item,
                                                     NULL,
                                                     NULL);
               close C_get_dept;
               return FALSE;
            end if;
            ---
            close C_get_dept;
         end if;
         ---
          open C_get_info_sup_dep;
         fetch C_get_info_sup_dep into O_round_level, O_to_inner_pct, O_to_case_pct,
                                       O_to_layer_pct, O_to_pallet_pct;
         close C_get_info_sup_dep;
      end if;
      ---
      if O_round_level = 'ZIP' then -- either SIM Level is 'S'/'L' or Dept.-level info. wasn't found
          open C_get_info_sup;
         fetch C_get_info_sup into O_round_level, O_to_inner_pct, O_to_case_pct,
                                   O_to_layer_pct, O_to_pallet_pct;
         close C_get_info_sup;
      end if;
      ---
      if O_round_level = 'ZIP' then -- Supplier-level info. wasn't found, so default from System Options
          open C_get_info_sys;
         fetch C_get_info_sys into O_round_level, O_to_inner_pct, O_to_case_pct,
                                   O_to_layer_pct, O_to_pallet_pct;
         close C_get_info_sys;
      end if;
   else
      if L_im_lvl in ('L','A') then
         if I_dept is NULL and L_im_lvl = 'A' then
            /*Determine Department
              For Passed-in Item */
             open C_get_dept;
            fetch C_get_dept into L_dept;
            ---
            if C_get_dept%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INVALID_ITEM',
                                                     I_item,
                                                     NULL,
                                                     NULL);
               close C_get_dept;
               return FALSE;
            end if;
            ---
            close C_get_dept;
         end if;
         ---
          open C_get_info_sup_dep_loc;
         fetch C_get_info_sup_dep_loc into O_round_level, O_to_inner_pct, O_to_case_pct,
                                           O_to_layer_pct, O_to_pallet_pct;
         close C_get_info_sup_dep_loc;
      end if;
      ---
      if O_round_level = 'ZIP' then  -- either Loc. is a Store, or SIM Level is 'S'/'D'
          open C_get_info_isc;
         fetch C_get_info_isc into O_round_level, O_to_inner_pct, O_to_case_pct,
                                   O_to_layer_pct, O_to_pallet_pct;
         close C_get_info_isc;
      end if;
   end if;
   ---
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_SUPP_COUNTRY_SQL.GET_DFLT_RND_LVL_ITEM',
                                            to_char(SQLCODE));
      return FALSE;
END GET_DFLT_RND_LVL_ITEM;
--------------------------------------------------------------------------------------------------------------
FUNCTION INSERT_COUNTRY_TO_COMP_ITEM(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     I_pack_no           IN     ITEM_MASTER.ITEM%TYPE,
                                     I_supplier          IN     SUPS.SUPPLIER%TYPE,
                                     I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                                     I_pack_cost         IN     ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                                     I_ti                IN     ITEM_SUPP_COUNTRY.TI%TYPE,
                                     I_hi                IN     ITEM_SUPP_COUNTRY.HI%TYPE,
                                     I_uom               IN     ITEM_SUPP_COUNTRY.COST_UOM%TYPE)
   return BOOLEAN is

   L_item          ITEM_MASTER.ITEM%TYPE;
   L_qty           V_PACKSKU_QTY.QTY%TYPE;
   L_exists        BOOLEAN;
   L_prim_country  ITEM_SUPP_COUNTRY.PRIMARY_COUNTRY_IND%TYPE;
   L_prim_supp     ITEM_SUPP_COUNTRY.PRIMARY_COUNTRY_IND%TYPE;
   L_const_dim_ind ITEM_MASTER.CONST_DIMEN_IND%TYPE;
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, Begin
   L_sys_option_row SYSTEM_OPTIONS%ROWTYPE;
   L_pack_ind       ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_item_pack_ind  ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_pack_cost      ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, End
   cursor C_ITEM is
      select vpq.item,
             vpq.qty,
             isp.primary_supp_ind,
             im.const_dimen_ind
        from v_packsku_qty vpq,
             item_supplier isp,
             item_master im
       where vpq.pack_no = I_pack_no
         and im.item = vpq.item
         and im.item = isp.item
         and isp.supplier = I_supplier;

   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, Begin
   CURSOR C_ITEM_CASCADE is
   select vpq.item item,
          vpq.pack_qty qty,
          isp.primary_supp_ind,
          im.const_dimen_ind
     from packitem vpq,
          item_supplier isp,
          item_master im
    where vpq.pack_no = I_pack_no
      and im.item = vpq.item
      and im.item = isp.item
      and isp.supplier = I_supplier
    union
   select im.item_parent item,
          vpq.pack_qty qty,
          isp.primary_supp_ind,
          im.const_dimen_ind
     from packitem vpq,
          item_supplier isp,
          item_master im
    where vpq.pack_no = I_pack_no
      and im.item = vpq.item
      and im.item = isp.item
      and isp.supplier = I_supplier
    union
   select im.item_parent item,
          vpq.pack_qty qty,
          isp.primary_supp_ind,
          im.const_dimen_ind
     from packitem vpq,
          item_supplier isp,
          item_master im
    where im.item = I_pack_no
      and im.item = vpq.item
      and im.item = isp.item
      and isp.supplier = I_supplier
     --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com Begin
      union
   select vpq.pack_no item,
          vpq.pack_qty qty,
          isp.primary_supp_ind,
          im.const_dimen_ind
     from packitem vpq,
          item_supplier isp,
          item_master im
    where im.item = I_pack_no
      and im.item = vpq.item
      and im.item = isp.item
      and isp.supplier = I_supplier
       and  exists(select 'X' from item_supplier isp1
                   where isp1.item=vpq.pack_no
                   and isp1.supplier=I_supplier);
    --PM038041 25-July-2015,Ramya.K.Shetty@in.tesco.com End

   CURSOR C_ITEM_PACK_IND (Cp_item_pack ITEM_MASTER.ITEM%TYPE) is
   select im.simple_pack_ind
     from item_master im
    where im.item = Cp_item_pack;
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, End
BEGIN
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_sys_option_row) = FALSE then
      raise PROGRAM_ERROR;
   end if;

   if L_sys_option_row.tsl_supp_cre_casc_ind = 'Y' then

      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_PACK_IND',
                       'ITEM_MASTER',
                       'Item: '||I_pack_no);
      open C_ITEM_PACK_IND (I_pack_no) ;
      SQL_LIB.SET_MARK('FETCH',
                       'C_ITEM_PACK_IND',
                       'ITEM_MASTER',
                       'Item: '||I_pack_no);
      fetch C_ITEM_PACK_IND into L_item_pack_ind;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_PACK_IND',
                       'ITEM_MASTER',
                       'Item: '||I_pack_no);
      close C_ITEM_PACK_IND;

      FOR L_rec in C_ITEM_CASCADE
      LOOP
         if L_rec.item is NOT NULL then
            if NOT SUPP_ITEM_SQL.COUNTRY_EXISTS(O_error_message,
                                                L_exists,
                                                L_rec.item,
                                                I_supplier) then
               return FALSE;
            end if;

            SQL_LIB.SET_MARK('OPEN',
                             'C_ITEM_PACK_IND',
                             'ITEM_MASTER',
                             'Item: '||I_pack_no);
            open C_ITEM_PACK_IND (L_rec.item) ;
            SQL_LIB.SET_MARK('FETCH',
                             'C_ITEM_PACK_IND',
                             'ITEM_MASTER',
                             'Item: '||I_pack_no);
            fetch C_ITEM_PACK_IND into L_pack_ind;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_ITEM_PACK_IND',
                             'ITEM_MASTER',
                             'Item: '||I_pack_no);
            close C_ITEM_PACK_IND;

            if L_item_pack_ind = 'N' then
               if L_pack_ind = 'Y' then
                  L_pack_cost := I_pack_cost * L_rec.qty;
               else
                  L_pack_cost := I_pack_cost;
               end if;
            else
               if L_pack_ind = 'Y' then
                  L_pack_cost := I_pack_cost;
               else
                  L_pack_cost := I_pack_cost / L_rec.qty;
               end if;
            end if;

            if L_exists then
               L_prim_country := 'N';
            else
               L_prim_country := 'Y';
            end if;

            BEGIN
               insert into item_supp_country(item,
                                             supplier,
                                             origin_country_id,
                                             unit_cost,
                                             lead_time,
                                             pickup_lead_time,
                                             supp_pack_size,
                                             inner_pack_size,
                                             round_lvl,
                                             round_to_inner_pct,
                                             round_to_pallet_pct,
                                             round_to_layer_pct,
                                             round_to_case_pct,
                                             min_order_qty,
                                             max_order_qty,
                                             packing_method,
                                             primary_supp_ind,
                                             primary_country_ind,
                                             default_uop,
                                             ti,
                                             hi,
                                             supp_hier_type_1,
                                             supp_hier_lvl_1,
                                             supp_hier_type_2,
                                             supp_hier_lvl_2,
                                             supp_hier_type_3,
                                             supp_hier_lvl_3,
                                             create_datetime,
                                             last_update_datetime,
                                             last_update_id,
                                             cost_uom)
                                      select L_rec.item,
                                             I_supplier,
                                             I_origin_country_id,
                                             L_pack_cost,
                                             lead_time,
                                             pickup_lead_time,
                                             L_rec.qty,
                                             1,
                                             round_lvl,
                                             round_to_inner_pct,
                                             round_to_pallet_pct,
                                             round_to_layer_pct,
                                             round_to_case_pct,
                                             min_order_qty,
                                             max_order_qty,
                                             packing_method,
                                             L_rec.primary_supp_ind,
                                             L_prim_country,
                                             default_uop,
                                             I_ti,
                                             I_hi,
                                             supp_hier_type_1,
                                             supp_hier_lvl_1,
                                             supp_hier_type_2,
                                             supp_hier_lvl_2,
                                             supp_hier_type_3,
                                             supp_hier_lvl_3,
                                             sysdate,
                                             sysdate,
                                             user,
                                             I_uom
                                        from item_supp_country
                                       where supplier = I_supplier
                                         and origin_country_id = I_origin_country_id
                                         and item = I_pack_no;

            EXCEPTION
               when DUP_VAL_ON_INDEX then
                  return TRUE;
            END;

            if ITEM_SUPP_COUNTRY_LOC_SQL.CREATE_LOCATION(O_error_message,
                                                         L_rec.item,
                                                         I_supplier,
                                                         I_origin_country_id,
                                                         NULL) = FALSE then
               return FALSE;
            end if;

            if L_prim_country = 'Y' then
               if L_prim_supp = 'Y' then
                  if ITEM_SUPP_COUNTRY_SQL.FIRST_SUPPLIER(O_error_message,
                                                          L_rec.item,
                                                          I_supplier,
                                                          I_origin_country_id,
                                                          I_pack_cost,
                                                          I_ti,
                                                          I_hi) = FALSE then
                     return FALSE;
                  end if;
               end if;
            end if;
            ---
            if L_rec.const_dimen_ind = 'Y' then
               if L_prim_supp = 'N' or
                  (L_prim_supp = 'Y' and
                  L_prim_country = 'N') then
                  -- Insert default dimensions.
                  if ITEM_SUPP_COUNTRY_SQL.INSERT_CONST_DIMENSIONS(O_error_message,
                                                                   L_rec.item,
                                                                   I_supplier,
                                                                   I_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
               end if;
            end if;
         end if;
      END LOOP;
   else
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, End

      open C_ITEM;
      fetch C_ITEM into L_item, L_qty, L_prim_supp, L_const_dim_ind;
      close C_ITEM;


      if L_item is NOT NULL then
         if NOT SUPP_ITEM_SQL.COUNTRY_EXISTS(O_error_message,
                                             L_exists,
                                             L_item,
                                             I_supplier) then
            return FALSE;
         end if;

         if L_exists then
            L_prim_country := 'N';
         else
            L_prim_country := 'Y';
         end if;

         BEGIN
            insert into item_supp_country(item,
                                          supplier,
                                          origin_country_id,
                                          unit_cost,
                                          lead_time,
                                          pickup_lead_time,
                                          supp_pack_size,
                                          inner_pack_size,
                                          round_lvl,
                                          round_to_inner_pct,
                                          round_to_pallet_pct,
                                          round_to_layer_pct,
                                          round_to_case_pct,
                                          min_order_qty,
                                          max_order_qty,
                                          packing_method,
                                          primary_supp_ind,
                                          primary_country_ind,
                                          default_uop,
                                          ti,
                                          hi,
                                          supp_hier_type_1,
                                          supp_hier_lvl_1,
                                          supp_hier_type_2,
                                          supp_hier_lvl_2,
                                          supp_hier_type_3,
                                          supp_hier_lvl_3,
                                          create_datetime,
                                          last_update_datetime,
                                          last_update_id,
                                          cost_uom)
                                   select L_item,
                                          I_supplier,
                                          I_origin_country_id,
                                          I_pack_cost / L_qty,
                                          lead_time,
                                          pickup_lead_time,
                                          L_qty,
                                          1,
                                          round_lvl,
                                          round_to_inner_pct,
                                          round_to_pallet_pct,
                                          round_to_layer_pct,
                                          round_to_case_pct,
                                          min_order_qty,
                                          max_order_qty,
                                          packing_method,
                                          L_prim_supp,
                                          L_prim_country,
                                          default_uop,
                                          I_ti,
                                          I_hi,
                                          supp_hier_type_1,
                                          supp_hier_lvl_1,
                                          supp_hier_type_2,
                                          supp_hier_lvl_2,
                                          supp_hier_type_3,
                                          supp_hier_lvl_3,
                                          sysdate,
                                          sysdate,
                                          user,
                                          I_uom
                                     from item_supp_country
                                    where supplier = I_supplier
                                      and origin_country_id = I_origin_country_id
                                      and item = I_pack_no;

         EXCEPTION
            when DUP_VAL_ON_INDEX then
               return TRUE;
         END;

         if ITEM_SUPP_COUNTRY_LOC_SQL.CREATE_LOCATION(O_error_message,
                                                      L_item,
                                                      I_supplier,
                                                      I_origin_country_id,
                                                      NULL) = FALSE then
            return FALSE;
         end if;

         if L_prim_country = 'Y' then
            if L_prim_supp = 'Y' then
               if ITEM_SUPP_COUNTRY_SQL.FIRST_SUPPLIER(O_error_message,
                                                       L_item,
                                                       I_supplier,
                                                       I_origin_country_id,
                                                       I_pack_cost,
                                                       I_ti,
                                                       I_hi) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
         ---
         if L_const_dim_ind = 'Y' then
            if L_prim_supp = 'N' or
               (L_prim_supp = 'Y' and
               L_prim_country = 'N') then
               -- Insert default dimensions.
               if ITEM_SUPP_COUNTRY_SQL.INSERT_CONST_DIMENSIONS(O_error_message,
                                                                L_item,
                                                                I_supplier,
                                                                I_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
      end if;
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, Begin
   end if;
   -- CR362, 27-Dec-2010, Accenture/Veena Nanjundaiah, Veena.Nanjundaiah@in.tesco.com, End
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_TO_COMP_ITEM',
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_COUNTRY_TO_COMP_ITEM;
--------------------------------------------------------------------------------
FUNCTION INSERT_EXP_TO_COMP_ITEM(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_pack_no           IN     ITEM_MASTER.ITEM%TYPE,
                                 I_supplier          IN     SUPS.SUPPLIER%TYPE,
                                 I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   return BOOLEAN is

   L_item          ITEM_MASTER.ITEM%TYPE;
   L_prim_country  ITEM_SUPP_COUNTRY.PRIMARY_COUNTRY_IND%TYPE;

   cursor C_ITEM is
      select vpq.item, isc.primary_country_ind
        from v_packsku_qty vpq, item_supp_country isc
       where vpq.pack_no = I_pack_no
         and vpq.item = isc.item
         and isc.supplier = I_supplier
         and isc.origin_country_id = I_origin_country_id;

BEGIN

   open C_ITEM;
   fetch C_ITEM into L_item, L_prim_country;
   close C_ITEM;

   if L_item is NOT NULL then
      if L_prim_country = 'Y' then
         if ITEM_EXPENSE_SQL.DEFAULT_EXPENSES(O_error_message,
                                              L_item,
                                              I_supplier,
                                              NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if ITEM_EXPENSE_SQL.DEFAULT_GROUP_EXP(O_error_message,
                                               L_item,
                                               I_supplier,
                                               NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if ITEM_EXPENSE_SQL.DEFAULT_EXPENSES(O_error_message,
                                              L_item,
                                              I_supplier,
                                              I_origin_country_id) = FALSE then
            return FALSE;
         end if;
         ---
         if ITEM_EXPENSE_SQL.DEFAULT_GROUP_EXP(O_error_message,
                                               L_item,
                                               I_supplier,
                                               I_origin_country_id) = FALSE then
            return FALSE;
         end if;
         ---
      else
         if ITEM_EXPENSE_SQL.DEFAULT_EXPENSES(O_error_message,
                                              L_item,
                                              I_supplier,
                                              I_origin_country_id) = FALSE then
            return FALSE;
         end if;
         ---
         if ITEM_EXPENSE_SQL.DEFAULT_GROUP_EXP(O_error_message,
                                               L_item,
                                               I_supplier,
                                               I_origin_country_id) = FALSE then
            return FALSE;
         end if;
      end if; -- Primary country
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_SUPP_COUNTRY_SQL.INSERT_EXP_TO_COMP_ITEM',
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_EXP_TO_COMP_ITEM;
--------------------------------------------------------------------------------
FUNCTION GET_DEFAULT_UOP(O_error_message     IN OUT VARCHAR2,
                         O_default_uop       IN OUT ITEM_SUPP_COUNTRY.DEFAULT_UOP%TYPE,
                         I_item              IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                         I_supplier          IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                         I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   return BOOLEAN is

   cursor C_GET_DEFAULT_UOP is
      select default_uop
        from item_supp_country
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_GET_DEFAULT_UOP', 'ITEM_SUPP_COUNTRY', 'item = '||I_item||
                                                                      ', supplier = '||to_char(I_supplier)||
                                                                      ', origin_country_id = '||I_origin_country_id);
   open C_GET_DEFAULT_UOP;
   SQL_LIB.SET_MARK('FETCH', 'C_GET_DEFAULT_UOP', 'ITEM_SUPP_COUNTRY', 'item = '||I_item||
                                                                      ', supplier = '||to_char(I_supplier)||
                                                                      ', origin_country_id = '||I_origin_country_id);
   fetch C_GET_DEFAULT_UOP into O_default_uop;
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_DEFAULT_UOP', 'ITEM_SUPP_COUNTRY', 'item = '||I_item||
                                                                      ', supplier = '||to_char(I_supplier)||
                                                                      ', origin_country_id = '||I_origin_country_id);
   close C_GET_DEFAULT_UOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_SUPP_COUNTRY_SQL.GET_DEFAULT_UOP',
                                            to_char(SQLCODE));

END GET_DEFAULT_UOP;
---------------------------------------------------------------------
FUNCTION INSERT_ITEM_SUPP_COUNTRY(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_isc_rec       IN ITEM_SUPP_COUNTRY%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.INSERT_ITEM_SUPP_COUNTRY';

BEGIN
   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_SUPP_COUNTRY','item: '||I_isc_rec.item||
                                                    ' supplier: '||I_isc_rec.supplier||
                                                    ' country: '||I_isc_rec.origin_country_id);

  insert into ITEM_SUPP_COUNTRY( item,
                                 supplier,
                                 origin_country_id,
                                 unit_cost,
                                 lead_time,
                                 pickup_lead_time,
                                 supp_pack_size,
                                 inner_pack_size,
                                 round_lvl,
                                 round_to_inner_pct,
                                 round_to_case_pct,
                                 round_to_layer_pct,
                                 round_to_pallet_pct,
                                 min_order_qty,
                                 max_order_qty,
                                 packing_method,
                                 primary_supp_ind,
                                 primary_country_ind,
                                 default_uop,
                                 ti,
                                 hi,
                                 supp_hier_type_1,
                                 supp_hier_lvl_1,
                                 supp_hier_type_2,
                                 supp_hier_lvl_2,
                                 supp_hier_type_3,
                                 supp_hier_lvl_3,
                                 create_datetime,
                                 last_update_datetime,
                                 last_update_id,
                                 cost_uom,
                                 tolerance_type,
                                 max_tolerance,
                                 min_tolerance,
                                 --08-Feb-2011 Tesco HSC/Ankush            Mod:CR382a Begin
                                 tsl_buying_qty
                                 --08-Feb-2011 Tesco HSC/Ankush            Mod:CR382a End
                                 )
                         values( I_isc_rec.item,
                                 I_isc_rec.supplier,
                                 I_isc_rec.origin_country_id,
                                 I_isc_rec.unit_cost,
                                 I_isc_rec.lead_time,
                                 I_isc_rec.pickup_lead_time,
                                 I_isc_rec.supp_pack_size,
                                 I_isc_rec.inner_pack_size,
                                 I_isc_rec.round_lvl,
                                 I_isc_rec.round_to_inner_pct,
                                 I_isc_rec.round_to_case_pct,
                                 I_isc_rec.round_to_layer_pct,
                                 I_isc_rec.round_to_pallet_pct,
                                 I_isc_rec.min_order_qty,
                                 I_isc_rec.max_order_qty,
                                 I_isc_rec.packing_method,
                                 I_isc_rec.primary_supp_ind,
                                 I_isc_rec.primary_country_ind,
                                 I_isc_rec.default_uop,
                                 I_isc_rec.ti,
                                 I_isc_rec.hi,
                                 I_isc_rec.supp_hier_type_1,
                                 I_isc_rec.supp_hier_lvl_1,
                                 I_isc_rec.supp_hier_type_2,
                                 I_isc_rec.supp_hier_lvl_2,
                                 I_isc_rec.supp_hier_type_3,
                                 I_isc_rec.supp_hier_lvl_3,
                                 I_isc_rec.create_datetime,
                                 sysdate,
                                 I_isc_rec.last_update_id,
                                 I_isc_rec.cost_uom,
                                 I_isc_rec.tolerance_type,
                                 I_isc_rec.max_tolerance,
                                 I_isc_rec.min_tolerance,
                                 --08-Feb-2011 Tesco HSC/Ankush            Mod:CR382a Begin
                                 I_isc_rec.tsl_buying_qty
                                 --08-Feb-2011 Tesco HSC/Ankush            Mod:CR382a End
                                 );

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END INSERT_ITEM_SUPP_COUNTRY;
-------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_YES_PRIM_IND(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_isc_rec       IN ITEM_SUPP_COUNTRY%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.UPDATE_YES_PRIM_IND';

--- NOTE:  only used for XITEM subscription API after UPDATE_PRIMARY_INDICATORS is called
---
BEGIN
   if not LOCK_ITEM_SUPP_COUNTRY(O_error_message,
                                 I_isc_rec.item,
                                 I_isc_rec.supplier,
                                 I_isc_rec.origin_country_id) then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_SUPP_COUNTRY','item: '||I_isc_rec.item||
                                                    ' supplier: '||I_isc_rec.supplier||
                                                    ' country: '||I_isc_rec.origin_country_id);

   update ITEM_SUPP_COUNTRY
      set  primary_country_ind = 'Y',
           last_update_datetime = sysdate,
           last_update_id = I_isc_rec.last_update_id
    where item = I_isc_rec.item
      and supplier = I_isc_rec.supplier
      and origin_country_id = I_isc_rec.origin_country_id;
   ---
   if SQL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('COULD_NOT_UPDATE_REC');
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

END UPDATE_YES_PRIM_IND;
-------------------------------------------------------------------------------------------------------
FUNCTION DELETE_ITEM_SUPP_COUNTRY(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_item          IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                  I_supplier      IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                  I_country       IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.DELETE_ITEM_SUPP_COUNTRY';

BEGIN
   if not LOCK_ITEM_SUPP_COUNTRY(O_error_message,
                                 I_item,
                                 I_supplier,
                                 I_country) then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_SUPP_COUNTRY','item: '||I_item||
                                                    ' supplier: '||I_supplier||
                                                    ' country: '||I_country);
   delete from ITEM_SUPP_COUNTRY
    where item = I_item
      and supplier = I_supplier
      and origin_country_id = I_country;
   ---
   if SQL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('NO_RECORDS');
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

END DELETE_ITEM_SUPP_COUNTRY;
-------------------------------------------------------------------------------------------------------
FUNCTION LOCK_ITEM_SUPP_COUNTRY(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_item          IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                I_supplier      IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                I_country       IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.LOCK_ITEM_SUPP_COUNTRY';
   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);

   CURSOR C_LOCK_ITEM_SUPP_COUNTRY IS
      select 'x'
        from ITEM_SUPP_COUNTRY
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_country
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPP_COUNTRY','item: '||I_item||
                                                    ' supplier: '||I_supplier||
                                                    ' country: '||I_country);
   open C_LOCK_ITEM_SUPP_COUNTRY;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPP_COUNTRY','item: '||I_item||
                                                    ' supplier: '||I_supplier||
                                                    ' country: '||I_country);
   close C_LOCK_ITEM_SUPP_COUNTRY;
   ---
   return TRUE;
EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_SUPP_COUNTRY',
                                             NULL,
                                             NULL);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END LOCK_ITEM_SUPP_COUNTRY;
---------------------------------------------------------------------------------------------
FUNCTION CONVERT_COST(O_error_message       IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      IO_unit_cost          IN OUT   ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                      I_item                IN       ITEM_SUPP_COUNTRY.ITEM%TYPE,
                      I_supplier            IN       ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                      I_origin_country_id   IN       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                      I_cost_type           IN       VARCHAR2,
                      I_from_uom            IN        UOM_CONVERSION.FROM_UOM%TYPE DEFAULT NULL)
   RETURN BOOLEAN IS

   L_program  VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.CONVERT_COST';

   L_isc_row          ITEM_SUPP_COUNTRY%ROWTYPE;
   L_exists_isc       BOOLEAN  := FALSE;

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

   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_origin_country_id',
                                            L_program,
                                            NULL);

      return FALSE;
   end if;

   if I_cost_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_cost_type',
                                            L_program,
                                            NULL);

      return FALSE;
   end if;

   --retrieve the row from ITEM_SUPP_COUNTRY and ITEM_SUPP_COUNTRY_DIM tables
   if ITEM_SUPP_COUNTRY_SQL.GET_ROW(O_error_message,
                                    L_exists_isc,
                                    L_isc_row,
                                    I_item,
                                    I_supplier,
                                    I_origin_country_id) = FALSE then
      return FALSE;
   end if;

   if L_exists_isc then
      if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                            IO_unit_cost,
                                            I_item,
                                            I_supplier,
                                            I_origin_country_id,
                                            I_cost_type,
                                            I_from_uom,
                                            L_isc_row.cost_uom,
                                            L_isc_row.supp_pack_size) = FALSE then
         return FALSE;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('NO_REC',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;
END CONVERT_COST;
----------------------------------------------------------------------------------------------
FUNCTION GET_ROW(O_error_message       IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                 O_exists              IN OUT   BOOLEAN,
                 O_item_supp_country   IN OUT   ITEM_SUPP_COUNTRY%ROWTYPE,
                 I_item                IN       ITEM_SUPP_COUNTRY.ITEM%TYPE,
                 I_supplier            IN       ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                 I_origin_country_id   IN       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.GET_ROW';

   cursor C_GET_ROW is
   select *
     from item_supp_country
    where item              = I_item
      and supplier          = I_supplier
      and origin_country_id = I_origin_country_id;

BEGIN

   O_item_supp_country := NULL;

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

   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_origin_country_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ROW',
                    'ITEM_SUPP_COUNTRY',
                    'Item: '||I_item || ' Supplier:'||to_char(I_supplier)||' Origin_country_id: '||I_origin_country_id);
   open C_GET_ROW;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ROW',
                    'ITEM_SUPP_COUNTRY',
                    'Item: '||I_item || ' Supplier:'||to_char(I_supplier)||' Origin_country_id: '||I_origin_country_id);
   fetch C_GET_ROW into O_item_supp_country;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ROW',
                    'ITEM_SUPP_COUNTRY',
                    'Item: '||I_item || ' Supplier:'||to_char(I_supplier)||' Origin_country_id: '||I_origin_country_id);
   close C_GET_ROW;

   O_exists := (O_item_supp_country.item is NOT NULL);

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_ROW;
----------------------------------------------------------------------------------------------
FUNCTION GET_PRIMARY_LOC_ROW(O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists                  IN OUT   BOOLEAN,
                             O_item_supp_country_dim   IN OUT   ITEM_SUPP_COUNTRY_DIM%ROWTYPE,
                             I_item                    IN       ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                             I_loc                     IN       ITEM_LOC.LOC%TYPE,
                             I_dim_object              IN       ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.GET_PRIMARY_LOC_ROW';

   cursor C_GET_ROW is
   select iscd.*
     from item_supp_country_dim iscd,
          item_loc il
    where iscd.item           = I_item
      and iscd.dim_object     = I_dim_object
      and il.loc              = I_loc
      and iscd.item           = il.item
      and iscd.supplier       = il.primary_supp
      and iscd.origin_country = il.primary_cntry;

BEGIN

   O_item_supp_country_dim := NULL;

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_loc',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_dim_object is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_dim_object',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ROW',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'Item: '||I_item||' Dim_object: '||I_dim_object||'Loc: '||to_char(I_loc));
   open C_GET_ROW;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ROW',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'Item: '||I_item||' Dim_object: '||I_dim_object||'Loc: '||to_char(I_loc));

   fetch C_GET_ROW into O_item_supp_country_dim;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ROW',
                    'ITEM_SUPP_COUNTRY_DIM',
                    'Item: '||I_item||' Dim_object: '||I_dim_object||'Loc: '||to_char(I_loc));

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

END GET_PRIMARY_LOC_ROW;
---------------------------------------------------------------------
FUNCTION CONVERT_COST(I_unit_cost           IN   ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                      I_item                IN   ITEM_SUPP_COUNTRY.ITEM%TYPE,
                      I_supplier            IN   ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                      I_origin_country_id   IN   ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                      I_cost_type           IN   VARCHAR2)
   RETURN NUMBER IS

   L_error_message    RTK_ERRORS.RTK_TEXT%TYPE;
   L_converted_cost   ITEM_SUPP_COUNTRY.UNIT_COST%TYPE := I_unit_cost;
   I_from_uom         UOM_CONVERSION.FROM_UOM%TYPE := NULL;

BEGIN

   if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(L_error_message,
                                         L_converted_cost,
                                         I_item,
                                         I_supplier,
                                         I_origin_country_id,
                                         I_cost_type,
                                         I_from_uom
                                         ) = FALSE then
      raise_application_error(-20000, L_error_message);
   end if;

   return L_converted_cost;


EXCEPTION
   when OTHERS then
      raise;

END CONVERT_COST;
---------------------------------------------------------------------------------------------
FUNCTION GET_COST_UOM(O_error_message IN OUT VARCHAR2,
                      O_cuom          IN OUT ITEM_SUPP_COUNTRY.COST_UOM%TYPE,
                      I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.GET_COST_UOM';

   cursor C_COST_UOM is
      select cost_uom
        from item_supp_country
       where primary_supp_ind = 'Y'
         and primary_country_ind = 'Y'
         and item = I_item;
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
   open C_COST_UOM;
   fetch C_COST_UOM into O_cuom;
   close C_COST_UOM;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_COST_UOM;
---------------------------------------------------------------------------------------------
FUNCTION CONVERT_COST(O_error_message       IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      -- 28-Oct-2008 TESCO HSC/Vinod Kumar 6339674 Begin
                      IO_unit_cost          IN OUT   ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                      --IO_unit_cost          IN OUT   NUMBER,
                      -- 28-Oct-2008 TESCO HSC/Vinod Kumar 6339674 End
                      I_item                IN       ITEM_SUPP_COUNTRY.ITEM%TYPE,
                      I_supplier            IN       ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                      I_origin_country_id   IN       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                      I_cost_type           IN       VARCHAR2,
                      I_from_uom            IN       UOM_CONVERSION.FROM_UOM%TYPE DEFAULT NULL,
                      I_cost_uom            IN       ITEM_SUPP_COUNTRY.COST_UOM%TYPE,
                      I_supp_pack_size      IN       ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE)
   RETURN BOOLEAN IS

   L_program          VARCHAR2(60) := 'ITEM_SUPP_COUNTRY_SQL.CONVERT_COST';

   L_dimension_uom     ITEM_SUPP_COUNTRY.COST_UOM%TYPE;
   L_std_in_cost_uom   NUMBER;
   L_std_dimensions    NUMBER;
   L_dim_object        ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE := 'CA';
   L_std_uom           ITEM_MASTER.STANDARD_UOM%TYPE;
   L_cost_uom_class    UOM_CLASS.UOM_CLASS%TYPE;
   L_std_uom_class     UOM_CLASS.UOM_CLASS%TYPE;
   L_isc_dim_row       ITEM_SUPP_COUNTRY_DIM%ROWTYPE;
   L_exists_iscd       BOOLEAN;
   L_convert           BOOLEAN;

   cursor C_GET_STD_UOM is
      select standard_uom
        from item_master
       where item = I_item;

   cursor C_GET_UOM_CLASS is
      select uom_class
        from uom_class
       where uom = I_cost_uom;

   cursor C_GET_STD_UOM_CLASS is
       select uom_class
         from uom_class
        where uom = L_std_uom;

BEGIN

   --validate required input parameters
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

   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_origin_country_id',
                                            L_program,
                                            NULL);

      return FALSE;
   end if;

   if I_cost_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_cost_type',
                                            L_program,
                                            NULL);

      return FALSE;
   end if;

   if I_cost_uom is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_cost_uom',
                                            L_program,
                                            NULL);
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_STD_UOM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_GET_STD_UOM;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_STD_UOM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_GET_STD_UOM into L_std_uom;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_STD_UOM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_GET_STD_UOM;

   --if standard UOM is equal to the
   --cost UOM, no need to convert

   if L_std_uom = I_cost_uom then
      return TRUE;
   end if;

   --retrieve the standard UOM's class
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_UOM_CLASS',
                    'UOM_CLASS',
                    'UOM: '||I_cost_uom);
   open C_GET_UOM_CLASS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_UOM_CLASS',
                    'UOM_CLASS',
                    'UOM: '||I_cost_uom);
   fetch C_GET_UOM_CLASS into L_cost_uom_class;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_UOM_CLASS',
                    'UOM_CLASS',
                    'UOM: '||I_cost_uom );
   close C_GET_UOM_CLASS;

   --retrieve the cost UOM's class
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_STD_UOM_CLASS',
                    'UOM_CLASS',
                    'uom: '||L_std_uom);
   open C_GET_STD_UOM_CLASS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_STD_UOM_CLASS',
                    'UOM_CLASS',
                    'uom: '||L_std_uom);
   fetch C_GET_STD_UOM_CLASS into L_std_uom_class;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_STD_UOM_CLASS',
                    'UOM_CLASS',
                    'uom: '||L_std_uom);
   close C_GET_STD_UOM_CLASS;

   --if the standard and cost UOM belong to
   --the same class, utilize UOM_SQL.WITHIN_CLASS
   --to retrieve the conversion factor

   if L_cost_uom_class = L_std_uom_class then

      --call UOM_SQL.WITHIN_CLASS
      If UOM_SQL.WITHIN_CLASS(O_error_message,
                              L_std_in_cost_uom,
                              I_cost_uom,
                              1,
                              L_std_uom,
                              L_cost_uom_class ) = FALSE then --since both costs belong to the same class, both the standard and cost's class is valid
         return FALSE;
      end if;

   else --use the dimension values in retrieving the conversion factor


      if I_supp_pack_size is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                               'I_supp_pack_size',
                                               L_program,
                                               NULL);
      end if;

      --retrieve the dimension values of the item-supplier

      if ITEM_SUPP_COUNTRY_DIM_SQL.GET_ROW(O_error_message,
                                           L_exists_iscd,
                                           L_isc_dim_row,
                                           I_item,
                                           I_supplier,
                                           I_origin_country_id,
                                           L_dim_object) = FALSE then
         return FALSE;
      end if;

      --verify if dimension values already exist for the item-supplier
      if L_exists_iscd = FALSE then
         O_error_message := SQL_LIB.CREATE_MSG('UOM_CLASS_DIFF_MISS_DIM',
                                                NULL,
                                                NULL,
                                                NULL);
         return FALSE;
      else

         if UOM_SQL.VALIDATE_CONVERSION(O_error_message,
                                        L_convert,
                                        L_cost_uom_class,
                                        L_cost_uom_class,
                                        L_isc_dim_row.lwh_uom,
                                        L_isc_dim_row.weight_uom,
                                        L_isc_dim_row.liquid_volume_uom) = FALSE or
            L_convert = FALSE then
            O_error_message := SQL_LIB.CREATE_MSG('UOM_CLASS_DIFF_MISS_DIM',
                                                NULL,
                                                NULL,
                                                NULL);
            return FALSE;
         else

            --calculate standard UOM dimensions
            --this portion converts the standard UOM to
            --the pack size and then to the dimension UOM

            if L_cost_uom_class = 'MASS' then
               L_dimension_uom  := L_isc_dim_row.weight_uom;
               L_std_dimensions := L_isc_dim_row.net_weight/I_supp_pack_size;
            elsif L_cost_uom_class = 'LVOL' then
               L_dimension_uom  := L_isc_dim_row.liquid_volume_uom;
               L_std_dimensions := L_isc_dim_row.liquid_volume/I_supp_pack_size;
            elsif L_cost_uom_class = 'DIMEN' then
               L_dimension_uom  := L_isc_dim_row.lwh_uom;
               L_std_dimensions := L_isc_dim_row.length/I_supp_pack_size;
            elsif L_cost_uom_class = 'VOL' then
               L_dimension_uom  := L_isc_dim_row.lwh_uom || '3';
               L_std_dimensions := (L_isc_dim_row.length * L_isc_dim_row.width * L_isc_dim_row.height)/I_supp_pack_size;
            end if;

            --if the cost UOM is different from the
            --dimensin UOM, convert from the dimension
            --UOM to the cost UOM to get the
            --conversion factor

            if I_cost_uom != L_dimension_uom then

               If UOM_SQL.WITHIN_CLASS(O_error_message,
                                       L_std_in_cost_uom,
                                       I_cost_uom,
                                       L_std_dimensions,
                                       L_dimension_uom,
                                       L_cost_uom_class) = FALSE then --since both cost belong to the same class, both the standard and cost's class is valid
                  return FALSE;
               end if;

            else

            --otherwise, use the calculated dimension
            --as the conversion factor
               L_std_in_cost_uom := L_std_dimensions;
            end if;

         end if;

      end if;

   end if;

   --now that the conversion factor has
   --been retrieved, do the actual conversion here
   --based on the cost type

   if I_cost_type = 'S' then
      IO_unit_cost := IO_unit_cost / L_std_in_cost_uom;
   else
      IO_unit_cost := IO_unit_cost * L_std_in_cost_uom;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CONVERT_COST;
---------------------------------------------------------------------------------------------
--28-Jun-2007 WiproEnabler/Ramasamy - MOD 365b   Begin
   ---------------------------------------------------------------------------------------------------------------
   --TSL_INS_COUNTRY_TO_VARIANTS   Default the input origin country to all Variants items for the input base
   --                              item-supplier-origin country combination that do not already have the dimension object.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_INS_COUNTRY_TO_VARIANTS(O_error_message       IN OUT VARCHAR2,
                                        I_item                IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                        I_supplier            IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                        I_origin_country      IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                                        I_primary_country_ind IN     VARCHAR2,
                                        I_replace_ind         IN     VARCHAR2 DEFAULT 'N')
      return BOOLEAN is

      L_program        VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_INS_COUNTRY_TO_VARIANTS';
      L_bracket_ind    VARCHAR2(1)  := NULL;
      L_inv_mgmt_level VARCHAR2(6)  := NULL;
      --This cursor retrieves the variant Items for which there is no entry in the
      --item_supp_country for that item/supplier/country combination.
      cursor C_GET_VARIANT_ITEMS is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supplier isp
                         where isp.item     = im.item
                           and isp.supplier = I_supplier)
            and not exists (select 'x'
                              from item_supp_country isc
                             where im.item               = isc.item
                               and isc.supplier          = I_supplier
                               and isc.origin_country_Id = I_origin_country);
      --This cursor retrieves the variant Items for which there is no entry in the
      --item_supp_country for that item/supplier combination..
      cursor C_GET_VARIANT_ITEMS_1 is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supplier isp
                         where isp.item     = im.item
                           and isp.supplier = I_supplier)
            and not exists (select 'x'
                              from item_supp_country isc
                             where im.item      = isc.item
                               and isc.supplier = I_supplier);
      --This cursor retrieves the variant Items for which different origin countries
      --exist but there is no entry for base item?s primary origin country.
      cursor C_GET_VARIANT_ITEMS_2 is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supplier isp
                         where isp.item     = im.item
                           and isp.supplier = I_supplier)
            and exists (select 'x'
                          from item_supp_country isc
                         where im.item      = isc.item
                           and isc.supplier = I_supplier)
         minus
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supplier isp
                         where isp.item     = im.item
                           and isp.supplier = I_supplier)
            and exists (select 'x'
                          from item_supp_country isc
                         where im.item               = isc.item
                           and isc.supplier          = I_supplier
                           and isc.origin_country_id = I_origin_country);
      --This cursor retrieves the variant Items for which there exist an entry in the
      --item_supp_country corresponding to base item's primary origin country.
      cursor C_GET_VARIANT_ITEMS_3 is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supplier isp
                         where isp.item     = im.item
                           and isp.supplier = I_supplier)
            and exists (select 'x'
                          from item_supp_country isc
                         where im.item                 = isc.item
                           and isc.supplier            = I_supplier
                           and isc.origin_country_id   = I_origin_country
                           and isc.primary_country_ind = 'N');
      --15-Jul-10   JK  DefNBS018190    Begin
      cursor C_GET_VARIANT_TPND_OCC is
         select im2.item
           from item_master   im1,
                item_master   im2,
                packitem      pi,
                item_supplier isp
          where im1.tsl_base_item = I_item
            and im1.tsl_base_item != im1.item
            and im1.item_level    = im1.tran_level
            and im1.item_level    = 2
            and im1.tran_level    = 2
            and isp.item          = im1.tsl_base_item
            and isp.supplier      = I_supplier
            and pi.item           = im1.item
            and (im2.item         = pi.pack_no
             or  im2.item_parent  = pi.pack_no)
            -- DefNBS021830, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, Begin
            and im2.item_level    != 2
            -- DefNBS021830, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 09-Mar-2011, End
            and NOT exists (select 'x'
                              from item_supp_country its
                             where its.item = im2.item
                               and its.supplier = I_supplier
                               and its.origin_country_id = I_origin_country)
            -- DefNBS021863, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 10-Mar-2011, Begin
            and exists (select 'x'
                          from item_supplier isp
                         where isp.item     = im2.item
                           and isp.supplier = I_supplier);
            -- DefNBS021863, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 10-Mar-2011, End
      --15-Jul-10   JK  DefNBS018190    End
   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_supplier is null
      if I_supplier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_supplier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_origin_country_id is null
      if I_origin_country is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_origin_country',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_primary_country_ind is null
      if I_primary_country_ind is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_primary_country_ind',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Executing package functions
      if NOT
          SUPP_ATTRIB_SQL.GET_BRACKET_COSTING_IND(O_error_message => O_error_message,
                                                  O_bracket_ind   => L_bracket_ind,
                                                  I_supplier      => I_supplier) then
         return FALSE;
      end if;
      --
      if L_bracket_ind = 'Y' then
         --
         if NOT
             SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message => O_error_message,
                                                 O_inv_mgmt_lvl  => L_inv_mgmt_level,
                                                 I_supplier      => I_supplier) then
            return FALSE;
         end if;
         --
      end if;
      --
      --
      if I_primary_country_ind = 'N' then
         --Opening the cursor C_GET_VARIANT_ITEMS
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS',
                          'ITEM_MASTER, ITEM_SUPP_COUNTRY, ITEM_SUPPLIER',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS
         LOOP
            --
            if NOT
                ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message       => O_error_message,
                                                                     I_item                => I_item,
                                                                     I_child_item          => C_rec.Item,
                                                                     I_supplier            => I_supplier,
                                                                     I_origin_country_id   => I_origin_country,
                                                                     I_primary_country_ind => 'N',
                                                                     I_update_ind          => 'N',
                                                                     I_insert_ind          => 'Y',
                                                                     I_bracket_ind         => L_bracket_ind,
                                                                     I_inv_mgmt_level      => L_inv_mgmt_level) then
               return FALSE;
            end if;
            --
         END LOOP;
      end if;
      --
      --
      if I_replace_ind = 'N' then
         --
         --Opening the cursor C_GET_VARIANT_ITEMS_1
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS_1',
                          'ITEM_MASTER, ITEM_SUPP_COUNTRY, ITEM_SUPPLIER',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS_1
         LOOP
            --
            if NOT
                ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message       => O_error_message,
                                                                     I_item                => I_item,
                                                                     I_child_item          => C_rec.Item,
                                                                     I_supplier            => I_supplier,
                                                                     I_origin_country_id   => I_origin_country,
                                                                     I_primary_country_ind => 'Y',
                                                                     I_update_ind          => 'N',
                                                                     I_insert_ind          => 'Y',
                                                                     I_bracket_ind         => L_bracket_ind,
                                                                     I_inv_mgmt_level      => L_inv_mgmt_level) then
               return FALSE;
            end if;
            --
         END LOOP;
         --
         --
         --Opening the cursor C_GET_VARIANT_ITEMS_2
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS_2',
                          'ITEM_MASTER, ITEM_SUPP_COUNTRY, ITEM_SUPPLIER',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS_2
         LOOP
            --
            if NOT
                ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message       => O_error_message,
                                                                     I_item                => I_item,
                                                                     I_child_item          => C_rec.Item,
                                                                     I_supplier            => I_supplier,
                                                                     I_origin_country_id   => I_origin_country,
                                                                     I_primary_country_ind => 'N',
                                                                     I_update_ind          => 'N',
                                                                     I_insert_ind          => 'Y',
                                                                     I_bracket_ind         => L_bracket_ind,
                                                                     I_inv_mgmt_level      => L_inv_mgmt_level) then
               return FALSE;
            end if;
            --
         END LOOP;
         --
      else
         --
         --Opening the cursor C_GET_VARIANT_ITEMS_1
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS_1',
                          'ITEM_MASTER, ITEM_SUPP_COUNTRY, ITEM_SUPPLIER',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS_1
         LOOP
            --
            if NOT
                ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message       => O_error_message,
                                                                     I_item                => I_item,
                                                                     I_child_item          => C_rec.Item,
                                                                     I_supplier            => I_supplier,
                                                                     I_origin_country_id   => I_origin_country,
                                                                     I_primary_country_ind => 'Y',
                                                                     I_update_ind          => 'N',
                                                                     I_insert_ind          => 'Y',
                                                                     I_bracket_ind         => L_bracket_ind,
                                                                     I_inv_mgmt_level      => L_inv_mgmt_level) then
               return FALSE;
            end if;
            --
         END LOOP;
         --
         --
         --Opening the cursor C_GET_VARIANT_ITEMS_2
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS_2',
                          'ITEM_MASTER, ITEM_SUPP_COUNTRY, ITEM_SUPPLIER',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS_2
         LOOP
            --
            if NOT
                ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message       => O_error_message,
                                                                     I_item                => I_item,
                                                                     I_child_item          => C_rec.Item,
                                                                     I_supplier            => I_supplier,
                                                                     I_origin_country_id   => I_origin_country,
                                                                     I_primary_country_ind => 'Y',
                                                                     I_update_ind          => 'Y',
                                                                     I_insert_ind          => 'Y',
                                                                     I_bracket_ind         => L_bracket_ind,
                                                                     I_inv_mgmt_level      => L_inv_mgmt_level) then
               return FALSE;
            end if;
            --
         END LOOP;
         --
         --
         --Opening the cursor C_GET_VARIANT_ITEMS_3
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS_3',
                          'ITEM_MASTER, ITEM_SUPP_COUNTRY, ITEM_SUPPLIER',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS_3
         LOOP
            --
            if NOT
                ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message       => O_error_message,
                                                                     I_item                => I_item,
                                                                     I_child_item          => C_rec.Item,
                                                                     I_supplier            => I_supplier,
                                                                     I_origin_country_id   => I_origin_country,
                                                                     I_primary_country_ind => 'Y',
                                                                     I_update_ind          => 'Y',
                                                                     I_insert_ind          => 'N',
                                                                     I_bracket_ind         => L_bracket_ind,
                                                                     I_inv_mgmt_level      => L_inv_mgmt_level) then
               return FALSE;
            end if;
            --
         END LOOP;
         --
      end if;
      --
      --15-Jul-10   JK  DefNBS018190    Begin
      --Opening the cursor C_GET_VARIANT_TPND_OCC
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_VARIANT_TPND_OCC',
                       'ITEM_MASTER, ITEM_SUPP_COUNTRY, ITEM_SUPPLIER',
                       'ITEM: ' || I_item);
      FOR C_rec in C_GET_VARIANT_TPND_OCC
      LOOP
         --
         if NOT
             ITEM_SUPP_COUNTRY_SQL.INSERT_COUNTRY_IND_TO_CHILDREN(O_error_message       => O_error_message,
                                                                  I_item                => I_item,
                                                                  I_child_item          => C_rec.Item,
                                                                  I_supplier            => I_supplier,
                                                                  I_origin_country_id   => I_origin_country,
                                                                  I_primary_country_ind => I_primary_country_ind,
                                                                  I_update_ind          => 'N',
                                                                  I_insert_ind          => 'Y',
                                                                  I_bracket_ind         => L_bracket_ind,
                                                                  I_inv_mgmt_level      => L_inv_mgmt_level) then
            return FALSE;
         end if;
         --
      END LOOP;
      --
      --15-Jul-10   JK  DefNBS018190    End
      ---
      return TRUE;
      ---
   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_INS_COUNTRY_TO_VARIANTS;
   ---------------------------------------------------------------------------------------------------------------
   --TSL_INS_DIMENSION_TO_VARIANTS Default the input dimension to all variant items for the input base
   --                              item-supplier-origin country combination that do not already have the dimension object.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_INS_DIMENSION_TO_VARIANTS(O_error_message     IN OUT VARCHAR2,
                                          I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                          I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                          I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                                          I_dim_object        IN     ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE)
      return BOOLEAN is

      L_program VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_INS_DIMENSION_TO_VARIANTS';
      --This cursor retrieves the variant Items for which there is no entry in the
      --item_supp_country for that item/supplier/country/dimension combination.
      cursor C_GET_VARIANT_ITEMS is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supp_country_dim isp
                         where isp.item           = I_item
                           and isp.supplier       = I_supplier
                           and isp.origin_country = I_origin_country_id)
            and exists (select 'x'
                          from item_supp_country isc
                         where im.item               = isc.item
                           and isc.supplier          = I_supplier
                           and isc.origin_country_id = I_origin_country_id);

   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_supplier is null
      if I_supplier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_supplier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_origin_country_id is null
      if I_origin_country_id is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_origin_country_id',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Opening the cursor C_GET_VARIANT_ITEMS
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_VARIANT_ITEMS',
                       'ITEM_MASTER, ITEM_SUPP_COUNTRY',
                       'ITEM: ' || I_item);
      FOR C_rec in C_GET_VARIANT_ITEMS
      LOOP
         --
         --Insert records in the ITEM_SUPP_COUNTRY_DIM table
         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         insert into item_supp_country_dim
            (item,
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
            (select C_rec.item,
                    I_supplier,
                    I_origin_country_id,
                    NVL(I_dim_object,
                        isd.dim_object),
                    isd.presentation_method,
                    isd.length,
                    isd.width,
                    isd.height,
                    isd.lwh_uom,
                    isd.weight,
                    isd.net_weight,
                    isd.weight_uom,
                    isd.liquid_volume,
                    isd.liquid_volume_uom,
                    isd.stat_cube,
                    isd.tare_weight,
                    isd.tare_type,
                    SYSDATE,
                    SYSDATE,
                    USER
               from item_supp_country_dim isd
              where isd.item           = I_item
                and isd.supplier       = I_supplier
                and isd.origin_country = I_origin_country_id
                and isd.dim_object     = NVL(I_dim_object,
                                         isd.dim_object)
                and not exists (select 'X'
                                  from item_supp_country_dim
                                 where isd.item           = C_rec.Item
                                   and isd.supplier       = I_supplier
                                   and isd.origin_country = I_origin_country_id
                                   and isd.dim_object     = NVL(I_dim_object,isd.dim_object)));
         --
      END LOOP;
      ---
      return TRUE;
      ---
   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_INS_DIMENSION_TO_VARIANTS;
   ---------------------------------------------------------------------------------------------------------------
   --TSL_UPD_DIMENSION_TO_VARIANTS  Default the input origin country to all variant items for the input base
   --                               item-supplier-origin country combination that already have the dimension object.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_UPD_DIMENSION_TO_VARIANTS(O_error_message     IN OUT VARCHAR2,
                                          I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                          I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                          I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                                          I_dim_object        IN     ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE,
                                          I_insert             IN     VARCHAR2)
      return BOOLEAN is

      L_program             VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_UPD_DIMENSION_TO_VARIANTS';
      L_item                ITEM_MASTER.ITEM%TYPE := NULL;
      L_table               VARCHAR2(30) := 'ITEM_SUPP_COUNTRY_DIM';
      L_presentation_method ITEM_SUPP_COUNTRY_DIM.PRESENTATION_METHOD%TYPE;
      L_length              ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
      L_width               ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
      L_height              ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
      L_lwh_uom             ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE;
      L_weight              ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
      L_net_weight          ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE;
      L_weight_uom          ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
      L_liquid_volume       ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
      L_liquid_volume_uom   ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE;
      L_stat_cube           ITEM_SUPP_COUNTRY_DIM.STAT_CUBE%TYPE;
      L_tare_weight         ITEM_SUPP_COUNTRY_DIM.TARE_WEIGHT%TYPE;
      L_tare_type           ITEM_SUPP_COUNTRY_DIM.TARE_TYPE%TYPE;
      ---
      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED,
                            -54);

      --This cursor will lock the variant information on the table ITEM_SUPP_COUNTRY_DIM
      cursor C_LOCK_DIMENSIONS is
         select 'X'
           from item_supp_country_dim isp
          where isp.item           = L_item
            and isp.supplier       = I_supplier
            and isp.origin_country = I_origin_country_id
            and isp.dim_object     = I_dim_object
            for update of isp.supplier nowait;
      --This cursor retrieves the variant Items for which there is an entry in the
      --item_supp_country_dim for that item/supplier/country/dimension combination.
      cursor C_GET_VARIANT_ITEMS is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supp_country_dim isp
                         where isp.item           = im.item
                           and isp.supplier       = I_supplier
                           and isp.origin_country = I_origin_country_id
                           and isp.dim_object     = I_dim_object);
      --This cursor retrieves the variant Items for which there is an entry in the
      --item_supp_country_dim for that item/supplier/country combination.
      cursor C_GET_VARIANT_ITEMS_INSERT is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supp_country_dim isp
                         where isp.item           = im.item
                           and isp.supplier       = I_supplier
                           and isp.origin_country = I_origin_country_id)
            and exists (select 'x'
                          from item_supp_country isc
                         where im.item               = isc.item
                           and isc.supplier          = I_supplier
                           and isc.origin_country_id = I_origin_country_id);
      --This cursor retrieves the information on the item_supp_country_dim table for the
      --base item/supplier/country/dimension combination.
      cursor C_GET_DIMENSIONS is
         select isd.presentation_method,
                isd.length,
                isd.width,
                isd.height,
                isd.lwh_uom,
                isd.weight,
                isd.net_weight,
                isd.weight_uom,
                isd.liquid_volume,
                isd.liquid_volume_uom,
                isd.stat_cube,
                isd.tare_weight,
                isd.tare_type
           from item_supp_country_dim isd
          where isd.item           = I_item
            and isd.supplier       = I_supplier
            and isd.origin_country = I_origin_country_id
            and isd.dim_object     = I_dim_object;
   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_supplier is null
      if I_supplier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_supplier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_origin_country_id is null
      if I_origin_country_id is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_origin_country_id',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_dim_object is null
      if I_dim_object is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_dim_object',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --
      if I_insert = 'N' then
         --
         --Opening the cursor C_GET_DIMENSIONS
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_DIMENSIONS',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         open C_GET_DIMENSIONS;
         --Fetch the cursor C_GET_DIMENSIONS
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_DIMENSIONS',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         fetch C_GET_DIMENSIONS
            into L_presentation_method,
                 L_length,
                 L_width,
                 L_height,
                 L_lwh_uom,
                 L_weight,
                 L_net_weight,
                 L_weight_uom,
                 L_liquid_volume,
                 L_liquid_volume_uom,
                 L_stat_cube,
                 L_tare_weight,
                 L_tare_type;
         --Closing the cursor C_GET_DIMENSIONS
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_DIMENSIONS',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         close C_GET_DIMENSIONS;
         --
         --Opening the cursor C_GET_VARIANT_ITEMS
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS',
                          'ITEM_MASTER, ITEM_SUPP_COUNTRY',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS
         LOOP
            L_item := C_rec.item;
            --
            --Opening the cursor C_LOCK_DIMENSIONS
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_DIMENSIONS',
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            open C_LOCK_DIMENSIONS;
            --Closing the cursor C_LOCK_DIMENSIONS
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_DIMENSIONS',
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            close C_LOCK_DIMENSIONS;
            --
            --Update records on the ITEM_SUPP_COUNTRY_DIM table
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            update item_supp_country_dim isd
               set presentation_method  = L_presentation_method,
                   length               = L_length,
                   width                = L_width,
                   height               = L_height,
                   lwh_uom              = L_lwh_uom,
                   weight               = L_weight,
                   net_weight           = L_net_weight,
                   weight_uom           = L_weight_uom,
                   liquid_volume        = L_liquid_volume,
                   liquid_volume_uom    = L_liquid_volume_uom,
                   stat_cube            = L_stat_cube,
                   tare_weight          = L_tare_weight,
                   tare_type            = L_tare_type,
                   last_update_datetime = SYSDATE,
                   last_update_id       = USER
             where isd.item           = L_item
               and isd.supplier       = I_supplier
               and isd.origin_country = I_origin_country_id
               and isd.dim_object     = I_dim_object;
            --
         END LOOP;
         --
         --Opening the cursor C_GET_VARIANT_ITEMS_INSERT
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS_INSERT',
                          'ITEM_MASTER',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS_INSERT
         LOOP
            --
            --Insert records in the ITEM_SUPP_COUNTRY_DIM table
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            insert into item_supp_country_dim
               (item,
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
               (select C_rec.item,
                       I_supplier,
                       I_origin_country_id,
                       I_dim_object,
                       isd.presentation_method,
                       isd.length,
                       isd.width,
                       isd.height,
                       isd.lwh_uom,
                       isd.weight,
                       isd.net_weight,
                       isd.weight_uom,
                       isd.liquid_volume,
                       isd.liquid_volume_uom,
                       isd.stat_cube,
                       isd.tare_weight,
                       isd.tare_type,
                       SYSDATE,
                       SYSDATE,
                       USER
                  from item_supp_country_dim isd
                 where isd.item           = L_item
                   and isd.supplier       = I_supplier
                   and isd.origin_country = I_origin_country_id
                   and isd.dim_object     = I_dim_object
                   and not exists (select 'X'
                                     from item_supp_country_dim isc
                                    where isc.item           = C_rec.Item
                                      and isc.supplier       = I_supplier
                                      and isc.origin_country = I_origin_country_id
                                      and isc.dim_object     = I_dim_object));
            --
         END LOOP;
         --
      else
         --
         --Opening the cursor C_GET_VARIANT_ITEMS_INSERT
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS_INSERT',
                          'ITEM_MASTER',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS_INSERT
         LOOP
            --
            --Insert records in the ITEM_SUPP_COUNTRY_DIM table
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            insert into item_supp_country_dim
               (item,
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
               (select C_rec.item,
                       I_supplier,
                       I_origin_country_id,
                       I_dim_object,
                       isd.presentation_method,
                       isd.length,
                       isd.width,
                       isd.height,
                       isd.lwh_uom,
                       isd.weight,
                       isd.net_weight,
                       isd.weight_uom,
                       isd.liquid_volume,
                       isd.liquid_volume_uom,
                       isd.stat_cube,
                       isd.tare_weight,
                       isd.tare_type,
                       SYSDATE,
                       SYSDATE,
                       USER
                  from item_supp_country_dim isd
                 where isd.item           = L_item
                   and isd.supplier       = I_supplier
                   and isd.origin_country = I_origin_country_id
                   and isd.dim_object     = I_dim_object
                   and not exists (select 'X'
                                     from item_supp_country_dim isc
                                    where isc.item           = C_rec.Item
                                      and isc.supplier       = I_supplier
                                      and isc.origin_country = I_origin_country_id
                                      and isc.dim_object     = I_dim_object));
            --
         END LOOP;
         --
      end if;
      --
      ---
      return TRUE;
      ---
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               TO_CHAR(I_supplier));
         return FALSE;
      when OTHERS THEN
         --
         --To check whether the cursor is closed or not
         if C_GET_DIMENSIONS%ISOPEN then
            --Closing the cursor C_GET_DIMENSIONS
            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_DIMENSIONS',
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            close C_GET_DIMENSIONS;
         end if;
         --
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_UPD_DIMENSION_TO_VARIANTS;
   ---------------------------------------------------------------------------------------------------------------
   --TSL_UPD_CONST_DIM_TO_VARIANTS   Lock and update all of the item-supplier dimension records for the Variant Items
   --based on the input variables, to all the variant items for the passed base item. This function will update for
   --only a specific dimension if the supplier, origin country, dimension object and action indicator variables have
   --input values. The dimension object, origin country and action will be known when changing dimensions for the
   --primary supplier in the item-supplier-origin country form.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_UPD_CONST_DIM_TO_VARIANTS(O_error_message     IN OUT VARCHAR2,
                                          I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                          I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                          I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                                          I_dim_object        IN     ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE)
      return BOOLEAN is

      L_program               VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_UPD_CONST_DIM_TO_VARIANTS ';
      L_table                 VARCHAR2(30) := 'ITEM_SUPP_COUNTRY_DIM';
      L_item                  ITEM_SUPP_COUNTRY.ITEM%TYPE;
      L_dim_supplier          ITEM_SUPP_COUNTRY.SUPPLIER%TYPE;
      L_dim_origin_country_id ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
      L_presentation_method   ITEM_SUPP_COUNTRY_DIM.PRESENTATION_METHOD%TYPE;
      L_length                ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
      L_width                 ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
      L_height                ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
      L_lwh_uom               ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE;
      L_weight                ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
      L_net_weight            ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE;
      L_weight_uom            ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
      L_liquid_volume         ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
      L_liquid_volume_uom     ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE;
      L_stat_cube             ITEM_SUPP_COUNTRY_DIM.STAT_CUBE%TYPE;
      L_tare_weight           ITEM_SUPP_COUNTRY_DIM.TARE_WEIGHT%TYPE;
      L_tare_type             ITEM_SUPP_COUNTRY_DIM.TARE_TYPE%TYPE;

      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED,
                            -54);

      --This cursor will lock the variant information on the table ITEM_SUPP_COUNTRY_DIM
      cursor C_LOCK_DIMENSIONS is
         select 'X'
           from item_supp_country_dim isp
          where isp.item           = L_item
            and isp.supplier       = L_dim_supplier
            and isp.origin_country = L_dim_origin_country_id
            for update of isp.supplier nowait;
      --This cursor retrieves the variant Items for which there is an entry in the
      --item_supp_country_dim for a base item/supplier/country combination
      cursor C_GET_VARIANT_ITEMS is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supp_country_dim isp
                         where isp.item           = I_item
                           and isp.supplier       = L_dim_supplier
                           and isp.origin_country = L_dim_origin_country_id)
            and exists (select 'x'
                          from item_supp_country_dim isc
                         where isc.item           = im.item
                           and isc.supplier       = L_dim_supplier
                           and isc.origin_country = L_dim_origin_country_id);
      --This cursor retrieves the information on the item_supp_country_dim table
      --for the base item/supplier/country/dimension combination.
      cursor C_GET_DIMENSIONS is
         select isd.presentation_method,
                isd.length,
                isd.width,
                isd.height,
                isd.lwh_uom,
                isd.weight,
                isd.net_weight,
                isd.weight_uom,
                isd.liquid_volume,
                isd.liquid_volume_uom,
                isd.stat_cube,
                isd.tare_weight,
                isd.tare_type
           from item_supp_country_dim isd
          where isd.item           = I_item
            and isd.supplier       = I_supplier
            and isd.origin_country = I_origin_country_id
            and isd.dim_object     = I_dim_object;
      --This cursor will retrieve all the combination supplier/origin country for the passed base item,
      --with supplier different from the passed I_supplier or origin country different from the passed I_origin_country_id
      cursor C_GET_SUPP_COUNTRY_INSERT is
         select isc.supplier,
                isc.origin_country_id
           from item_supp_country isc
          where isc.item              = I_item
            and (isc.supplier         = I_supplier or
                isc.origin_country_id = I_origin_country_id);

   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_supplier is null
      if I_supplier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_supplier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_origin_country_id is null
      if I_origin_country_id is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_origin_country_id',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --
      --Opening the cursor C_GET_DIMENSIONS
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_DIMENSIONS',
                       'ITEM_SUPP_COUNTRY_DIM',
                       'ITEM: ' || I_item);
      open C_GET_DIMENSIONS;
      --Fetch the cursor C_GET_DIMENSIONS
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_DIMENSIONS',
                       'ITEM_SUPP_COUNTRY_DIM',
                       'ITEM: ' || I_item);
      fetch C_GET_DIMENSIONS
         into L_presentation_method,
              L_length,
              L_width,
              L_height,
              L_lwh_uom,
              L_weight,
              L_net_weight,
              L_weight_uom,
              L_liquid_volume,
              L_liquid_volume_uom,
              L_stat_cube,
              L_tare_weight,
              L_tare_type;
      --Closing the cursor C_GET_DIMENSIONS
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_DIMENSIONS',
                       'ITEM_SUPP_COUNTRY_DIM',
                       'ITEM: ' || I_item);
      close C_GET_DIMENSIONS;
      --
      --Opening the cursor C_GET_SUPP_COUNTRY_INSERT
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_SUPP_COUNTRY_INSERT',
                       'ITEM_SUPP_COUNTRY_DIM',
                       'ITEM: ' || I_item);
      FOR C_rec in C_GET_SUPP_COUNTRY_INSERT
      LOOP
         --
         L_dim_supplier          := C_rec.supplier;
         L_dim_origin_country_id := C_rec.Origin_Country_Id;
         --
         --Opening the cursor C_GET_VARIANT_ITEMS
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VARIANT_ITEMS',
                          'ITEM_MASTER',
                          'ITEM: ' || I_item);
         FOR C_rec in C_GET_VARIANT_ITEMS
         LOOP
            --
            L_item := C_rec.Item;
            --Opening the cursor C_LOCK_DIMENSIONS
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_DIMENSIONS',
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            open C_LOCK_DIMENSIONS;
            --Closing the cursor C_LOCK_DIMENSIONS
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_DIMENSIONS',
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            close C_LOCK_DIMENSIONS;
            --
            --Update records on the ITEM_SUPP_COUNTRY_DIM table
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            update item_supp_country_dim isd
               set presentation_method  = L_presentation_method,
                   length               = L_length,
                   width                = L_width,
                   height               = L_height,
                   lwh_uom              = L_lwh_uom,
                   weight               = L_weight,
                   net_weight           = L_net_weight,
                   weight_uom           = L_weight_uom,
                   liquid_volume        = L_liquid_volume,
                   liquid_volume_uom    = L_liquid_volume_uom,
                   stat_cube            = L_stat_cube,
                   tare_weight          = L_tare_weight,
                   tare_type            = L_tare_type,
                   last_update_datetime = SYSDATE,
                   last_update_id       = USER
             where isd.item           = L_item
               and isd.supplier       = L_dim_supplier
               and isd.origin_country = L_dim_origin_country_id
               and isd.dim_object     = I_dim_object
               and exists (select 'X'
                             from item_supp_country_dim isp
                            where isp.item           = I_item
                              and (isp.supplier      = L_dim_supplier or
                                  isp.origin_country = L_dim_origin_country_id)
                              and isp.dim_object     = I_dim_object);
            --

            --
            --Insert records in the ITEM_SUPP_COUNTRY_DIM table
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_SUPP_COUNTRY_DIM',
                             'ITEM: ' || I_item);
            insert into item_supp_country_dim
               (item,
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
               (select L_item,
                       L_dim_supplier,
                       L_dim_origin_country_id,
                       I_dim_object,
                       isd.presentation_method,
                       isd.length,
                       isd.width,
                       isd.height,
                       isd.lwh_uom,
                       isd.weight,
                       isd.net_weight,
                       isd.weight_uom,
                       isd.liquid_volume,
                       isd.liquid_volume_uom,
                       isd.stat_cube,
                       isd.tare_weight,
                       isd.tare_type,
                       SYSDATE,
                       SYSDATE,
                       USER
                  from item_supp_country_dim isd
                 where isd.item           = I_item
                   and isd.supplier       = I_supplier
                   and isd.origin_country = I_origin_country_id
                   and isd.dim_object     = I_dim_object
                   and not exists (select 'X'
                                     from item_supp_country_dim isd2
                                    where isd2.item           = L_Item
                                      and isd2.supplier       = L_dim_supplier
                                      and isd2.origin_country = L_dim_origin_country_id
                                      and isd2.dim_object     = isd.dim_object));
            --
         --
         END LOOP;
         --
      END LOOP;
      ---
      return TRUE;
      ---
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               TO_CHAR(I_supplier));
         return FALSE;
      when OTHERS THEN
         --To check whether the cursor is closed or not
         if C_GET_DIMENSIONS%ISOPEN then
            SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_DIMENSIONS',
                       'ITEM_SUPP_COUNTRY_DIM',
                       'ITEM: ' || I_item);
            close C_GET_DIMENSIONS;
         end if;
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_UPD_CONST_DIM_TO_VARIANTS;
   ---------------------------------------------------------------------------------------------------------------
   --TSL_DEL_DIMENSION_TO_VARIANTS    Default the input dimension deletion to all variant items for the input base
   --                                 item-supplier-origin country combination that for the dimension object.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_DEL_DIMENSION_TO_VARIANTS(O_error_message     IN OUT VARCHAR2,
                                          I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                          I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                          I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                                          I_dim_object        IN     ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE)
      return BOOLEAN is

      L_program VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_DEL_DIMENSION_TO_VARIANTS';
      L_table   VARCHAR2(65) := 'ITEM_SUPP_COUNTRY_DIM';
      L_item    ITEM_MASTER.ITEM%TYPE := NULL;
      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED,
                            -54);
      --This cursor will lock the variant information on the table ITEM_SUPP_COUNTRY_DIM
      cursor C_LOCK_DIMENSIONS is
         select 'x'
           from item_supp_country_dim isp
          where isp.item           = L_item
            and isp.supplier       = I_supplier
            and isp.origin_country = I_origin_country_id
            and isp.dim_object     = I_dim_object
            for update nowait;

      --This cursor retrieves the variant Items for which there is no entry in the
      --item_supp_country for that item/supplier/country/dimension combination.
      cursor C_GET_VARIANT_DIM is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'x'
                          from item_supp_country_dim isp
                         where im.item            = isp.item
                           and isp.supplier       = I_supplier
                           and isp.origin_country = I_origin_country_id
                           and isp.dim_object     = I_dim_object);

   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_supplier is null
      if I_supplier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_supplier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_origin_country_id is null
      if I_origin_country_id is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_origin_country_id',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_dim_object is null
      if I_dim_object is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_dim_object',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Opening the cursor C_GET_VARIANT_DIM
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_VARIANT_DIM',
                       'ITEM_MASTER, ITEM_SUPP_COUNTRY_DIM',
                       'ITEM: ' || I_item);
      FOR C_rec in C_GET_VARIANT_DIM
      LOOP
         --
         --Opening the cursor C_LOCK_DIMENSIONS
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_DIMENSIONS',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         open C_LOCK_DIMENSIONS;
         --Closing the cursor C_LOCK_DIMENSIONS
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_DIMENSIONS',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         close C_LOCK_DIMENSIONS;
         --
         L_item := C_rec.Item;
         --
         --Delete records from the ITEM_SUPP_COUNTRY_DIM table
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         delete from item_supp_country_dim
          where supplier       = I_supplier
            and origin_country = I_origin_country_id
            and dim_object     = I_dim_object
            and item           = L_item;
      --
      END LOOP;
      ---
      return TRUE;
      ---
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               TO_CHAR(I_supplier));
         return FALSE;
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_DEL_DIMENSION_TO_VARIANTS;
   ---------------------------------------------------------------------------------------------------------------
   --TSL_DEL_CONST_DIM_TO_VARIANTS  Delete dimensions for non-primary origin countries and/or suppliers if the constant
   --                               dimension indicator is turned on for variant items for the passed base item.
   --                               The dimension object will be passed in as NULL if the user is changing primary
   --                               countries and thus may need to delete all former constant dimensions.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_DEL_CONST_DIM_TO_VARIANTS(O_error_message     IN OUT VARCHAR2,
                                          I_item              IN     ITEM_SUPP_COUNTRY_DIM.ITEM%TYPE,
                                          I_supplier          IN     ITEM_SUPP_COUNTRY_DIM.SUPPLIER%TYPE,
                                          I_origin_country_id IN     ITEM_SUPP_COUNTRY_DIM.ORIGIN_COUNTRY%TYPE,
                                          I_dim_object        IN     ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE)
      return BOOLEAN is

      L_program VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_DEL_CONST_DIM_TO_VARIANTS';
      L_table   VARCHAR2(65) := 'ITEM_SUPP_COUNTRY_DIM';
      L_item    ITEM_MASTER.ITEM%TYPE := NULL;
      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED,
                            -54);
      --This cursor will lock the variant information on the table ITEM_SUPP_COUNTRY_DIM
      cursor C_LOCK_DIM_OBJECT is
         select 'x'
           from item_supp_country_dim isp
          where isp.item           = L_item
            and isp.supplier       = I_supplier
            and isp.origin_country = I_origin_country_id
            and isp.dim_object     = NVL(I_dim_object, isp.dim_object)
            for update nowait;
      --This cursor retrieves the variant Items for which there is a entry in the
      --item_supp_country for that item/supplier/country combination, different from the one passed.
      cursor C_GET_VARIANT_ITEMS is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'X'
                          from item_supp_country_dim isp
                         where isp.item           = im.item
                           and isp.supplier       = I_supplier
                           and isp.origin_country = I_origin_country_id);

   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_supplier is null
      if I_supplier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_supplier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_origin_country_id is null
      if I_origin_country_id is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_origin_country_id',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Opening the cursor C_GET_VARIANT_ITEMS
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_VARIANT_ITEMS',
                       'ITEM_MASTER, ITEM_SUPP_COUNTRY',
                       'ITEM: ' || I_item);
      FOR C_rec in C_GET_VARIANT_ITEMS
      LOOP
         --
         --Opening the cursor C_LOCK_DIM_OBJECT
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_DIM_OBJECT',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         open C_LOCK_DIM_OBJECT;
         --Closing the cursor C_LOCK_DIM_OBJECT
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_DIM_OBJECT',
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         close C_LOCK_DIM_OBJECT;
         --
         L_item := C_rec.Item;
         --
         --Delete records from the ITEM_SUPP_COUNTRY_DIM table
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'ITEM_SUPP_COUNTRY_DIM',
                          'ITEM: ' || I_item);
         delete from item_supp_country_dim
          where item       = L_item
            and (supplier != I_supplier or
                origin_country != I_origin_country_id)
            and dim_object = NVL(I_dim_object,
                                 dim_object);
         --
      END LOOP;
      ---
      return TRUE;
      ---
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               TO_CHAR(I_supplier));
         return FALSE;
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_DEL_CONST_DIM_TO_VARIANTS;
   ---------------------------------------------------------------------------------------------------------------
   --TSL_UPD_COUNTRY_TO_VARIANTS  Update variant items records when origin country detail records are updated.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_UPD_COUNTRY_TO_VARIANTS(O_error_message     IN OUT VARCHAR2,
                                        I_item              IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                        I_supplier          IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                        I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
      return BOOLEAN is

      L_program          VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_UPD_COUNTRY_TO_VARIANTS ';
      L_table            VARCHAR2(30) := 'ITEM_SUPP_COUNTRY';
      L_item             ITEM_MASTER.ITEM%TYPE;
      L_lead_time        ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE;
      L_pickup_lead_time ITEM_SUPP_COUNTRY.PICKUP_LEAD_TIME%TYPE;
      L_supp_pack_size   ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE;
      L_inner_pack_size  ITEM_SUPP_COUNTRY.INNER_PACK_SIZE%TYPE;
      L_min_order_qty    ITEM_SUPP_COUNTRY.MIN_ORDER_QTY%TYPE;
      L_max_order_qty    ITEM_SUPP_COUNTRY.MAX_ORDER_QTY%TYPE;
      L_packing_method   ITEM_SUPP_COUNTRY.PACKING_METHOD%TYPE;
      L_default_uop      ITEM_SUPP_COUNTRY.DEFAULT_UOP%TYPE;
      L_ti               ITEM_SUPP_COUNTRY.TI%TYPE;
      L_hi               ITEM_SUPP_COUNTRY.HI%TYPE;
      L_supp_hier_lvl_1  ITEM_SUPP_COUNTRY.SUPP_HIER_LVL_1%TYPE;
      L_supp_hier_type_1 ITEM_SUPP_COUNTRY.SUPP_HIER_TYPE_1%TYPE;
      L_supp_hier_lvl_2  ITEM_SUPP_COUNTRY.SUPP_HIER_LVL_2%TYPE;
      L_supp_hier_type_2 ITEM_SUPP_COUNTRY.SUPP_HIER_TYPE_2%TYPE;
      L_supp_hier_lvl_3  ITEM_SUPP_COUNTRY.SUPP_HIER_LVL_3%TYPE;
      L_supp_hier_type_3 ITEM_SUPP_COUNTRY.SUPP_HIER_TYPE_3%TYPE;
      L_round_level      ITEM_SUPP_COUNTRY.ROUND_LVL%TYPE;
      L_to_inner_pct     ITEM_SUPP_COUNTRY.ROUND_TO_INNER_PCT%TYPE;
      L_to_case_pct      ITEM_SUPP_COUNTRY.ROUND_TO_CASE_PCT%TYPE;
      L_to_layer_pct     ITEM_SUPP_COUNTRY.ROUND_TO_LAYER_PCT%TYPE;
      L_to_pallet_pct    ITEM_SUPP_COUNTRY.ROUND_TO_PALLET_PCT%TYPE;
      ---
      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED,
                            -54);

      --This cursor will return the information for the passed Item/Supplier/Origin Country
      cursor C_GET_COUNTRY_DETAILS is
         select isc.lead_time           lead_time,
                isc.pickup_lead_time    pickup_lead_time,
                isc.supp_pack_size      supp_pack_size,
                isc.inner_pack_size     inner_pack_size,
                isc.round_lvl           round_lvl,
                isc.round_to_inner_pct  round_to_inner_pct,
                isc.round_to_case_pct   round_to_case_pct,
                isc.round_to_layer_pct  round_to_layer_pct,
                isc.round_to_pallet_pct round_to_pallet_pct,
                isc.min_order_qty       min_order_qty,
                isc.max_order_qty       max_order_qty,
                isc.packing_method      packing_method,
                isc.default_uop         default_uop,
                isc.ti                  ti,
                isc.hi                  hi,
                isc.supp_hier_lvl_1     supp_hier_lvl_1,
                isc.supp_hier_type_1    supp_hier_type_1,
                isc.supp_hier_lvl_2     supp_hier_lvl_2,
                isc.supp_hier_type_2    supp_hier_type_2,
                isc.supp_hier_lvl_3     supp_hier_lvl_3,
                isc.supp_hier_type_3    supp_hier_type_3
           from item_supp_country isc
          where isc.item              = I_item
            and isc.supplier          = I_supplier
            and isc.origin_country_id = I_origin_country_id;
      --This cursor will lock the variant information on the table ITEM_SUPP_COUNTRY
      cursor C_LOCK_COUNTRY_DETAILS is
         select 'x'
           from item_supp_country isc
          where isc.item              = L_item
            and isc.supplier          = I_supplier
            and isc.origin_country_id = I_origin_country_id
            for update nowait;
      --This cursor retrieves the variant Items for which there is a entry in the
      --item_supp_country for that item/supplier/country combination, different from the one passed.
      cursor C_GET_VARIANT_ITEMS is
         select im.item
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and exists (select 'X'
                          from item_supp_country isc
                         where im.item               = isc.item
                           and isc.supplier          = I_supplier
                           and isc.origin_country_id = I_origin_country_id);

   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_supplier is null
      if I_supplier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_supplier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_origin_country_id is null
      if I_origin_country_id is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_origin_country_id',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Opening the cursor C_GET_COUNTRY_DETAILS
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_COUNTRY_DETAILS',
                       'ITEM_SUPP_COUNTRY',
                       'ITEM: ' || I_item);
      open C_GET_COUNTRY_DETAILS;
      --Fetch the cursor
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_COUNTRY_DETAILS',
                       'ITEM_SUPP_COUNTRY',
                       'ITEM: ' || I_item);
      fetch C_GET_COUNTRY_DETAILS
         into L_lead_time,
              L_pickup_lead_time,
              L_supp_pack_size,
              L_inner_pack_size,
              L_round_level,
              L_to_inner_pct,
              L_to_case_pct,
              L_to_layer_pct,
              L_to_pallet_pct,
              L_min_order_qty,
              L_max_order_qty,
              L_packing_method,
              L_default_uop,
              L_ti,
              L_hi,
              L_supp_hier_lvl_1,
              L_supp_hier_type_1,
              L_supp_hier_lvl_2,
              L_supp_hier_type_2,
              L_supp_hier_lvl_3,
              L_supp_hier_type_3;
      --Closing the cursor C_GET_COUNTRY_DETAILS
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_COUNTRY_DETAILS',
                       'ITEM_SUPP_COUNTRY',
                       'ITEM: ' || I_item);
      close C_GET_COUNTRY_DETAILS;
      --Opening the cursor C_GET_VARIANT_ITEMS
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_VARIANT_ITEMS',
                       'ITEM_MASTER, ITEM_SUPP_COUNTRY',
                       'ITEM: ' || I_item);
      FOR C_rec in C_GET_VARIANT_ITEMS
      LOOP
         --
         L_item := C_rec.item;
         --Opening the cursor C_LOCK_COUNTRY_DETAILS
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_COUNTRY_DETAILS',
                          'ITEM_SUPP_COUNTRY',
                          'ITEM: ' || I_item);
         open C_LOCK_COUNTRY_DETAILS;
         --Closing the cursor C_LOCK_COUNTRY_DETAILS
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_COUNTRY_DETAILS',
                          'ITEM_SUPP_COUNTRY',
                          'ITEM: ' || I_item);
         close C_LOCK_COUNTRY_DETAILS;
         --
         --Update records on the ITEM_SUPP_COUNTRY  table
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_SUPP_COUNTRY ',
                          'ITEM: ' || I_item);
         update item_supp_country isc
            set lead_time            = L_lead_time,
                pickup_lead_time     = L_pickup_lead_time,
                supp_pack_size       = L_supp_pack_size,
                inner_pack_size      = L_inner_pack_size,
                round_lvl            = L_round_level,
                round_to_inner_pct   = L_to_inner_pct,
                round_to_case_pct    = L_to_case_pct,
                round_to_layer_pct   = L_to_layer_pct,
                round_to_pallet_pct  = L_to_pallet_pct,
                min_order_qty        = L_min_order_qty,
                max_order_qty        = L_max_order_qty,
                packing_method       = L_packing_method,
                default_uop          = L_default_uop,
                ti                   = L_ti,
                hi                   = L_hi,
                supp_hier_lvl_1      = L_supp_hier_lvl_1,
                supp_hier_type_1     = L_supp_hier_type_1,
                supp_hier_lvl_2      = L_supp_hier_lvl_2,
                supp_hier_type_2     = L_supp_hier_type_2,
                supp_hier_lvl_3      = L_supp_hier_lvl_3,
                supp_hier_type_3     = L_supp_hier_type_3,
                last_update_datetime = SYSDATE,
                last_update_id       = USER
          where isc.item              = L_item
            and isc.supplier          = I_supplier
            and isc.origin_country_id = I_origin_country_id;
         --
      END LOOP;
      ---
      return TRUE;
      ---
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               TO_CHAR(I_supplier));
         return FALSE;
      when OTHERS THEN
         --To check whether the cursor is closed or not
         if C_GET_COUNTRY_DETAILS%ISOPEN then
            SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_COUNTRY_DETAILS',
                          'ITEM_SUPP_COUNTRY',
                          'ITEM: ' || I_item);
            close C_GET_COUNTRY_DETAILS;
         end if;
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_UPD_COUNTRY_TO_VARIANTS;
---------------------------------------------------------------------------------------------------------------
--28-Jun-2007 WiproEnabler/Ramasamy - MOD 365b   End
-------------------------------------------------------------------------------------------------
-- 30-Jan-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - Begin
FUNCTION TSL_GET_PACKING_METHOD (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_packing_method     OUT   ITEM_SUPP_COUNTRY.PACKING_METHOD%TYPE,
                                 I_item            IN       ITEM_SUPP_COUNTRY.ITEM%TYPE)

RETURN BOOLEAN IS

   L_program VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_GET_PACKING_METHOD';

   CURSOR C_GET_PACK_METHOD is
   select i.packing_method
     from item_supp_country i
    where i.item = I_item
      and i.primary_supp_ind = 'Y'
      and i.primary_country_ind = 'Y';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_PACK_METHOD',
                    'item_supp_country',
                    'item: '||TO_CHAR(I_item));
   open C_GET_PACK_METHOD;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_PACK_METHOD',
                    'item_supp_country',
                    'item: '||TO_CHAR(I_item));
   fetch C_GET_PACK_METHOD into O_packing_method;
   ---
   if C_GET_PACK_METHOD%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_PACK_METHOD',
                    'item_supp_country',
                    'item: '||TO_CHAR(I_item));
      close C_GET_PACK_METHOD;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_PACK_METHOD',
                    'item_supp_country',
                    'item: '||TO_CHAR(I_item));
   close C_GET_PACK_METHOD;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_PACK_METHOD%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_PACK_METHOD',
                          'item_supp_country',
                          'item: '||TO_CHAR(I_item));
         close C_GET_PACK_METHOD;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_PACKING_METHOD;
-- 30-Jan-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - End

-- Cr 339 , 08-Oct-2010, Vivek Sharma, Vivek.Sharma@in.tesco.com -- Begin
------------------------------------------------------------------------------------------
--Function Name : TSL_GET_COST_UOM
-- Mod Ref      : CR 339
-- Date         : 08-Oct-10
--Purpose       : Retrieves the cost unit of measure (cuom) from item_supp_country
--               for the given Item and Supplier. Used by TSL_Item_EXP_Detail screen
----------------------------------------------------------------------------------

FUNCTION TSL_GET_COST_UOM(O_error_message IN OUT VARCHAR2,
                      O_cuom          IN OUT ITEM_SUPP_COUNTRY.COST_UOM%TYPE,
                      I_item          IN     ITEM_MASTER.ITEM%TYPE,
                      I_supplier      IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.TSL_GET_COST_UOM';

   cursor C_TSL_COST_UOM is
      select cost_uom
        from item_supp_country
       where item = I_item
         and supplier = I_supplier;
BEGIN
   ---
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_item',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_supplier',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_TSL_COST_UOM', 'item_supp_country','item: '||TO_CHAR(I_item));
   open C_TSL_COST_UOM;

   SQL_LIB.SET_MARK('FETCH','C_GET_PACK_METHOD', 'item_supp_country', 'item: '||TO_CHAR(I_item));
   fetch C_TSL_COST_UOM into O_cuom;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_PACK_METHOD','item_supp_country','item: '||TO_CHAR(I_item));
   close C_TSL_COST_UOM;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END TSL_GET_COST_UOM;
-- Cr 339 , 08-Oct-2010, Vivek Sharma, Vivek.Sharma@in.tesco.com -- End
-------------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_PRIM_UNIT_COST                                                       --
-- Purpose:     : This function will get the Unit cost for a TPNA's primary supplier           --
-------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_PRIM_UNIT_COST (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_unit_cost          OUT   ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                                 I_item            IN       ITEM_SUPP_COUNTRY.ITEM%TYPE)

RETURN BOOLEAN IS

   L_program VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_GET_PRIM_UNIT_COST';

   cursor C_GET_PRIM_UNIT_COST is
      select isc.unit_cost
        from item_supp_country isc,
             item_master im
       where im.item = I_item
         and im.item_parent = isc.item
         and isc.primary_supp_ind = 'Y';

BEGIN
   open C_GET_PRIM_UNIT_COST;
   fetch C_GET_PRIM_UNIT_COST into O_unit_cost;
   close C_GET_PRIM_UNIT_COST;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
         return FALSE;
END TSL_GET_PRIM_UNIT_COST;
-------------------------------------------------------------------------------------------------
--CR518, 15-May-2014, Usha Patil, BEGIN
-------------------------------------------------------------------------------------------------
-- Function Name: TSL_ITEM_SUPP_DUTYPAID                                                       --
-- Purpose:     : This function to get the duty paid indicator for the item and supplier passed--
-------------------------------------------------------------------------------------------------
FUNCTION TSL_ITEM_SUPP_DUTYPAID (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_duty_amount     IN OUT   ITEM_SUPPLIER.TSL_DUTY_AMT%TYPE,
                                 O_duty_paid       IN OUT   ITEM_SUPPLIER.TSL_DUTYPAID%TYPE,
                                 I_item            IN       ITEM_SUPPLIER.ITEM%TYPE,
                                 I_supplier        IN       ITEM_SUPPLIER.SUPPLIER%TYPE)

RETURN BOOLEAN IS
   L_program VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_SQL.TSL_ITEM_SUPP_DUTYPAID';

   cursor C_GET_ITEM_SUPP is
   select tsl_dutypaid,
          tsl_duty_amt
     from item_supplier
    where item = I_item
      and supplier = I_supplier;

BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_GET_ITEM_SUPP', 'item_supplier','item: '||I_item);
   open C_GET_ITEM_SUPP;

   SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_SUPP', 'item_supplier', 'item: '||I_item);
   fetch C_GET_ITEM_SUPP into O_duty_paid, O_duty_amount;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_ITEM_SUPP','item_supplier','item: '||I_item);
   close C_GET_ITEM_SUPP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
         return FALSE;
END TSL_ITEM_SUPP_DUTYPAID;
-------------------------------------------------------------------------------------------------
--CR518, 15-May-2014, Usha Patil, END
-------------------------------------------------------------------------------------------------
END ITEM_SUPP_COUNTRY_SQL;
/

