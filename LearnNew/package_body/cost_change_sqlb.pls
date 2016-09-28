CREATE OR REPLACE PACKAGE BODY COST_CHANGE_SQL AS
-------------------------------------------------------------------------------------
-- Modified by : WiproEnabler/Sundara Rajan, sundara.rajan@wipro.com
-- Date        : 07-Mar-2008
-- Mod Ref     : For Mod N53.
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Modified by : WiproEnabler/Bahubali Dongare, Bahubali.Dongare@in.tesco.com
-- Date        : 08-May-2008
-- Mod Ref     : Mod N111.
-- Mod Details : Modified the functions POP_FOR_ITEMLIST,POP_TEMP_DETAIL,POP_TEMP_DETAIL_SEC and POP_TEMP_DETAIL_LOC_SEC.
-------------------------------------------------------------------------------------
-- Mod By        : Satish B.N satish.narasimmhaiah@in.tesco.com
-- Mod Date      : 26-Aug-2008
-- Mod Details   : Added a new parameter to TSL_APPLY_REAL_TIME_COST function call as part of DefNBS007325
----------------------------------------------------------------------------------------------------------
-- Modified by : WiproEnabler/Bahubali Dongare, Bahubali.Dongare@in.tesco.com
-- Date        : 08-Sep-2008
-- Mod Ref     : Mod N111 general change and Defect NBS00009006
-- Mod Details : Changed the reference of channel id from item_supplier table to tsl_common_sups_matrix table
--               for the functions POP_FOR_ITEMLIST,POP_TEMP_DETAIL,POP_TEMP_DETAIL_SEC and POP_TEMP_DETAIL_LOC_SEC.
-------------------------------------------------------------------------------------
--Mod By:      Murali Krishnan
--Mod Date:    21-Oct-2008
--Mod Ref:     Back Port Oracle fix(6616812,6316705)
--Mod Details: Back ported the oracle fix for Bug 6616812,6316705.Modified the functions
--             POP_TEMP_DETAIL,POP_TEMP_DETAIL_SEC.
-----------------------------------------------------------------------------------------------------
--Mod By:      Nitin Kumar
--Mod Date:    29-Apr-2009
--Mod Ref:     NBS00012501/503
--Mod Details: Modified the functions POP_TEMP_DETAIL,POP_TEMP_DETAIL_SEC,POP_FOR_ITEMLIST and
--             POP_TEMP_DETAIL_LOC_SEC to include the cost changes only for simple pack.Complex
--             packs cant go under the cost change as Mod N53 restricts the user to do the cost
--             change for Complex Packs.
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Mod By       : Merlyn Mathew, Merlyn.Mathew@in.tesco.com
-- Mod Date     : 01-Nov-2010
-- Mod Ref      : CR332
-- Mod Details  : Added a new function TSL_POP_FOR_STYLE_REF_CODE which will populate the
--                cost_change_temp table with items that have the input Style Ref Code
------------------------------------------------------------------------------------------
FUNCTION LOCK_COST_CHANGE (O_error_message IN OUT VARCHAR2,
                           I_cost_change   IN     COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS

   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_COST_CHANGE is
      select 'x'
        from COST_SUSP_SUP_HEAD
       where COST_CHANGE = I_cost_change
         for update nowait;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_LOCK_COST_CHANGE','COST_SUSP_SUP_HEAD', 'cost_change: '||to_char(I_cost_change));
   open C_LOCK_COST_CHANGE;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_COST_CHANGE','COST_SUSP_SUP_HEAD', 'cost_change: '||to_char(I_cost_change));
   close C_LOCK_COST_CHANGE;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('COST_CHANGE',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'LOCK_COST_CHANGE',
                                             to_char(SQLCODE));
      return FALSE;

END LOCK_COST_CHANGE;
-------------------------------------------------------------------------------------
--Mod By:      Nitin Kumar
--Mod Date:    29-Apr-2009
--Mod Ref:     NBS00012501/503
--Mod Details: Modified the functions POP_TEMP_DETAIL to include the cost changes only for simple pack.
--             Complex packs cant go under the cost change as Mod N53 restricts the user to do the cost
--             change for Complex Packs.
-----------------------------------------------------------------------------------------------------
FUNCTION POP_TEMP_DETAIL (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          O_exists         IN OUT BOOLEAN,
                          I_mode           IN     VARCHAR2,
                          I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE,
                          I_supplier       IN     SUPS.SUPPLIER%TYPE,
                          I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE,
                          I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   TYPE supplier_tbl              is TABLE OF NUMBER(10)   INDEX BY BINARY_INTEGER;
   TYPE country_tbl               is TABLE OF VARCHAR2(3)  INDEX BY BINARY_INTEGER;
   TYPE item_tbl                  is TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
   TYPE unit_cost_tbl             is TABLE OF NUMBER(20,4) INDEX BY BINARY_INTEGER;
   TYPE cost_uom_tbl              is TABLE OF VARCHAR2(4)  INDEX BY BINARY_INTEGER;
   TYPE dept_tbl                  is TABLE OF NUMBER(4)    INDEX BY BINARY_INTEGER;
   TYPE ref_item_tbl              is TABLE OF VARCHAR2(25)  INDEX BY BINARY_INTEGER;
   TYPE vpn_tbl                   is TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
   TYPE converted_cost_tbl        is TABLE OF NUMBER(20,4) INDEX BY BINARY_INTEGER;
   TYPE bracket_value1_tbl        is TABLE OF NUMBER(12,4) INDEX BY BINARY_INTEGER;
   TYPE bracket_value2_tbl        is TABLE OF NUMBER(12,4) INDEX BY BINARY_INTEGER;
   TYPE default_bracket_ind_tbl   is TABLE OF VARCHAR2(1)  INDEX BY BINARY_INTEGER;

   L_supplier_tbl                 SUPPLIER_TBL;
   L_country_tbl                  COUNTRY_TBL;
   L_item_tbl                     ITEM_TBL;
   L_unit_cost_tbl                UNIT_COST_TBL;
   L_cost_uom_tbl                 COST_UOM_TBL;
   L_dept_tbl                     DEPT_TBL;
   L_ref_item_tbl                 REF_ITEM_TBL;
   L_vpn_tbl                      VPN_TBL;
   L_converted_cost_tbl           CONVERTED_COST_TBL;
   L_bracket_value1_tbl           BRACKET_VALUE1_TBL;
   L_bracket_value2_tbl           BRACKET_VALUE2_TBL;
   L_default_bracket_ind_tbl      DEFAULT_BRACKET_IND_TBL;

   L_converted_cost1              NUMBER(20,4);
   L_converted_cost2              NUMBER(20,4);

   L_program                      VARCHAR2(60)   := 'COST_CHANGE_SQL.POP_TEMP_DETAIL';
   L_inserted                     VARCHAR2(1) := 'N';
   L_old_unit_cost                COST_CHANGE_TEMP.UNIT_COST_OLD%TYPE;


   ---
   INVALID_MODE                   EXCEPTION;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
   L_apply_rp_link                SYSTEM_OPTIONS.TSL_APPLY_RP_LINK%TYPE := NULL;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
   -- 08-May-08 Bahubali D Mod N111 Begin
   L_system_options_row           SYSTEM_OPTIONS%ROWTYPE;
   L_apply_common_prd             SYSTEM_OPTIONS.TSL_COMMON_PRODUCT_IND%TYPE;
   L_origin_country               SYSTEM_OPTIONS.TSL_ORIGIN_COUNTRY%TYPE;
   -- 08-May-08 Bahubali D Mod N111 End
   /* Old cursor is modified to include ITEM_SUPP_COUNRY.cost_uom, ITEM_SUPPLIER.vpn and ITEM_MASTER.primary_ref_item_ind*/


   cursor C_COST_MAINT_SUPP is
      select cssd.item,
             cssd.supplier,
             cssd.origin_country_id,
             cssd.bracket_value1,
             cssd.bracket_uom1,
             cssd.bracket_value2,
             cssd.default_bracket_ind,
             cssd.unit_cost,
             cssd.recalc_ord_ind,
             cssd.dept,
             cssd.sup_dept_seq_no,
             ref_item.ref_item,
             isc.cost_uom,
             isp.vpn
        from cost_susp_sup_detail cssd,
             item_master im,
             item_supp_country isc,
             item_supplier isp,
	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
       where cssd.cost_change = I_cost_change
         and cssd.item = im.item
         and cssd.item = isc.item
         and cssd.item = isp.item
         and cssd.supplier = isc.supplier
         and cssd.supplier = isp.supplier
         and cssd.origin_country_id = isc.origin_country_id
         and cssd.item = ref_item.item(+);

   cursor C_NO_BRACKET_COST is
      select isc.supplier,
             isc.origin_country_id,
             isc.item,
             isc.unit_cost,
             isc.cost_uom,
             im.dept,
             ref_item.ref_item,
             isp.vpn
        from item_supp_country isc,
             sups s,
             item_master im,
             item_supplier isp,
	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
        where s.supplier = NVL(I_supplier, s.supplier)
           and isc.supplier = s.supplier
           and isc.supplier = isp.supplier
           and im.item = NVL(I_item, im.item)
           and im.item = isc.item
           and isc.item = isp.item
           and s.bracket_costing_ind = 'N'
           and im.item_level        <= im.tran_level
           -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
           -- and (im.pack_ind          = 'N'
           -- or  (im.pack_ind          = 'Y' and im.pack_type = 'V'))
           and (im.simple_pack_ind      = 'Y' and im.pack_type = 'V')
           -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End
           and im.status             = 'A'
           and isc.origin_country_id = NVL(I_origin_country, isc.origin_country_id)
           and isc.item              = ref_item.item(+)
           -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
           and NOT (im.pack_ind                   = 'Y'
                    and im.pack_type              = 'V'
                    and im.orderable_ind          = 'Y'
                    and im.tsl_mu_ind             = 'N'
                    and im.simple_pack_ind        = 'N'
                    and NVL(L_apply_rp_link, 'N') = 'Y')
           -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
           -- 08-May-08 Bahubali D Mod N111 Begin
           and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                     where im.tsl_common_ind        = 'Y'
                                       and im.tsl_primary_country  != L_origin_country
                                       and im.tsl_primary_country is NOT NULL
                                       and tcsm.channel_id in ('1Y','2Y','3Y')
                                       and L_apply_common_prd = 'Y'
                                       and im.item = tcsm.item
                                       and isp.supplier = tcsm.target_supplier);
          -- 08-May-08 Bahubali D Mod N111 End

   cursor C_SUPP_DEPT_LEVEL_BRACKETS is
      select iscbc.supplier,
             iscbc.origin_country_id,
             iscbc.item,
             iscbc.bracket_value1,
             iscbc.bracket_value2,
             iscbc.default_bracket_ind,
             iscbc.unit_cost,
             im.dept,
             ref_item.ref_item,
             isc.cost_uom,
             isp.vpn
        from sups s,
             item_supp_country_bracket_cost iscbc,
             item_master im,
             item_supp_country isc,
             item_supplier isp,
   	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
       where s.supplier               = iscbc.supplier
         and iscbc.supplier           = NVL(I_supplier, iscbc.supplier)
         and iscbc.supplier           = isc.supplier
         and iscbc.supplier           = isp.supplier
         and iscbc.item               = im.item
         and iscbc.item               = isc.item
         and iscbc.item               = isp.item
         and iscbc.item               = NVL(I_item, iscbc.item)
         and s.bracket_costing_ind    = 'Y'
         and s.inv_mgmt_lvl           in ('S', 'D')
         and iscbc.location           is NULL
         and im.item_level           <= im.tran_level
         -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
         -- and (im.pack_ind          = 'N'
         -- or  (im.pack_ind          = 'Y' and im.pack_type = 'V'))
         and (im.simple_pack_ind      = 'Y' and im.pack_type = 'V')
         -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End
         and im.status                = 'A'
         and iscbc.origin_country_id  = NVL(I_origin_country, iscbc.origin_country_id)
         and iscbc.item               = ref_item.item(+)
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
         and NOT (im.pack_ind                   = 'Y'
                  and im.pack_type              = 'V'
                  and im.orderable_ind          = 'Y'
                  and im.tsl_mu_ind             = 'N'
                  and im.simple_pack_ind        = 'N'
                  and NVL(L_apply_rp_link, 'N') = 'Y')
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
         -- 08-May-08 Bahubali D Mod N111 Begin
         and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                   where im.tsl_common_ind        = 'Y'
                                     and im.tsl_primary_country  != L_origin_country
                                     and im.tsl_primary_country is NOT NULL
                                     and tcsm.channel_id in ('1Y','2Y','3Y')
                                     and L_apply_common_prd = 'Y'
                                     and im.item = tcsm.item
                                     and isp.supplier = tcsm.target_supplier);
          -- 08-May-08 Bahubali D Mod N111 End

   cursor C_WITH_BRACKET_LOCATIONS is
     select distinct iscbc.supplier,
            iscbc.origin_country_id,
            iscbc.item,
            im.dept,
            ref_item.ref_item,
            isc.cost_uom,
            isp.vpn
       from item_supp_country_bracket_cost iscbc,
            sups s,
            item_master im,
            item_supplier isp,
            item_supp_country isc,
   	    (select item_parent item, item ref_item
               from item_master
              where primary_ref_item_ind = 'Y'
                and item_parent IS NOT NULL) ref_item
      where s.supplier               = iscbc.supplier
        and iscbc.supplier           = NVL(I_supplier, iscbc.supplier)
        and iscbc.supplier           = isc.supplier
        and iscbc.supplier           = isp.supplier
        and iscbc.item               = im.item
        and iscbc.item               = NVL(I_item, iscbc.item)
        and iscbc.item               = isc.item
        and iscbc.item               = isp.item
        and s.bracket_costing_ind    = 'Y'
        and s.inv_mgmt_lvl           in ('L', 'A')
        and im.item_level           <= im.tran_level
        -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
        -- and (im.pack_ind          = 'N'
        -- or  (im.pack_ind          = 'Y' and im.pack_type = 'V'))
        and (im.simple_pack_ind      = 'Y' and im.pack_type = 'V')
        -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End
        and im.status                = 'A'
        and iscbc.origin_country_id  = NVL(I_origin_country, iscbc.origin_country_id)
        and iscbc.item               = ref_item.item(+)
        -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
        and NOT (im.pack_ind                   = 'Y'
                 and im.pack_type              = 'V'
                 and im.orderable_ind          = 'Y'
                 and im.tsl_mu_ind             = 'N'
                 and im.simple_pack_ind        = 'N'
                 and NVL(L_apply_rp_link, 'N') = 'Y')
        -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
        -- 08-May-08 Bahubali D Mod N111 Begin
        and NOT exists  (select 'x' from tsl_common_sups_matrix tcsm
                                   where im.tsl_common_ind           = 'Y'
                                     and im.tsl_primary_country  != L_origin_country
                                     and im.tsl_primary_country is NOT NULL
                                     and tcsm.channel_id in ('1Y','2Y','3Y')
                                     and L_apply_common_prd = 'Y'
                                     and im.item = tcsm.item
                                     and isp.supplier = tcsm.target_supplier);
        -- 08-May-08 Bahubali D Mod N111 End

BEGIN
   ---
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
   -- The below function call the removed by Mod N111
   --if SYSTEM_OPTIONS_SQL.TSL_GET_APPLY_RP_LINK(O_error_message,
   --                                            L_apply_rp_link) = FALSE then
   --   return FALSE;
   --end if;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
   ---
   -- 08-May-08 Bahubali D Mod N111 Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS (O_error_message,
                                             L_system_options_row) = FALSE then
      return FALSE;
   end if;
   ---
   L_apply_rp_link    := L_system_options_row.tsl_apply_rp_link;
   L_apply_common_prd := L_system_options_row.tsl_common_product_ind;
   L_origin_country   := L_system_options_row.tsl_origin_country;
   ---
   -- 08-May-08 Bahubali D Mod N111 End

   if I_mode = 'NEW' then

     SQL_LIB.SET_MARK('OPEN',
                      'C_NO_BRACKET_COST',
                      'COST_CHANGE_TEMP',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
     open C_NO_BRACKET_COST;

     SQL_LIB.SET_MARK('FETCH',
                      'C_NO_BRACKET_COST',
                      'COST_CHANGE_TEMP',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
     fetch C_NO_BRACKET_COST BULK COLLECT into L_supplier_tbl,
                                                L_country_tbl,
                                                L_item_tbl,
                                                L_unit_cost_tbl,
                                                L_cost_uom_tbl,
                                                L_dept_tbl,
                                                L_ref_item_tbl,
                                                L_vpn_tbl;
     SQL_LIB.SET_MARK('CLOSE',
                      'C_NO_BRACKET_COST',
                      'COST_CHANGE_TEMP',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
     close C_NO_BRACKET_COST;

     if L_item_tbl.first is NOT NULL then
        for i in L_item_tbl.first..L_item_tbl.last loop
          if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                L_unit_cost_tbl(i),
                                                L_item_tbl(i),
                                                L_supplier_tbl(i),
                                                L_country_tbl(i),
                                                'S',
                                                NULL) = FALSE then
             return FALSE;
          end if;
          L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
       end loop;

      SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      --- insert for suppliers who do not bracket cost.
      ---
      forall i in L_item_tbl.first..L_item_tbl.last

         insert into cost_change_temp (cost_change,
                                       supplier,
                                       origin_country_id,
                                       item,
                                       bracket_value1,
                                       bracket_uom,
                                       bracket_value2,
                                       default_bracket_ind,
                                       unit_cost_old,
                                       unit_cost_new,
                                       recalc_ord_ind,
                                       loc_level_ind,
                                       dept,
                                       cost_uom,
                                       unit_cost_cuom_new,
                                       unit_cost_cuom_old,
                                       vpn,
                                       ref_item)

                             /* select statement modified to pass the values from the bulk collect*/


                                values (I_cost_change,
                                       L_supplier_tbl(i),
                                       L_country_tbl(i),
                                       L_item_tbl(i),
                                       NULL,
                                       NULL,
                                       NULL,
                                       'N',
                                       L_unit_cost_tbl(i),
                                       NULL,
                                       'N',
                                       'N',
                                       L_dept_tbl(i),
                                       L_cost_uom_tbl(i),
                                       NULL,
                                       L_converted_cost_tbl(i),
                                       L_vpn_tbl(i),
                                       L_ref_item_tbl(i));

         if SQL%FOUND then
            L_inserted := 'Y';
         end if;

     end if;

     SQL_LIB.SET_MARK('OPEN',
                      'C_SUPP_DEPT_LEVEL_BRACKETS',
                      'COST_CHANGE_TEMP',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
     open C_SUPP_DEPT_LEVEL_BRACKETS;

     SQL_LIB.SET_MARK('FETCH',
                      'C_SUPP_DEPT_LEVEL_BRACKETS',
                      'COST_CHANGE_TEMP',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
     fetch C_SUPP_DEPT_LEVEL_BRACKETS BULK COLLECT into L_supplier_tbl,
                                                        L_country_tbl,
                                                        L_item_tbl,
                                                        L_bracket_value1_tbl,
                                                        L_bracket_value2_tbl,
                                                        L_default_bracket_ind_tbl,
                                                        L_unit_cost_tbl,
                                                        L_dept_tbl,
                                                        L_ref_item_tbl,
                                                        L_cost_uom_tbl,
                                                        L_vpn_tbl;

     SQL_LIB.SET_MARK('CLOSE',
                      'C_SUPP_DEPT_LEVEL_BRACKETS',
                      'COST_CHANGE_TEMP',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
     close C_SUPP_DEPT_LEVEL_BRACKETS;

     if L_item_tbl.first is NOT NULL then

        for i in L_item_tbl.first..L_item_tbl.last loop
           if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                L_unit_cost_tbl(i),
                                                L_item_tbl(i),
                                                L_supplier_tbl(i),
                                                L_country_tbl(i),
                                               'S',
                                                NULL) = FALSE then
              return FALSE;
           end if;
           L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
        end loop;

      ---
      SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      --- insert for supplier or dept level brackets
      ---

      forall i in L_item_tbl.first..L_item_tbl.last

         insert into cost_change_temp (cost_change,
                                       supplier,
                                       origin_country_id,
                                       item,
                                       bracket_value1,
                                       bracket_uom,
                                       bracket_value2,
                                       default_bracket_ind,
                                       unit_cost_old,
                                       unit_cost_new,
                                       recalc_ord_ind,
                                       loc_level_ind,
                                       dept,
                                       cost_uom,
                                       unit_cost_cuom_new,
                                       unit_cost_cuom_old,
                                       vpn,
                                       ref_item)
                             /* select statement modified to pass the values from the bulk collect*/


                               values (I_cost_change,
                                       L_supplier_tbl(i),
                                       L_country_tbl(i),
                                       L_item_tbl(i),
                                       L_bracket_value1_tbl(i),
                                       NULL,
                                       L_bracket_value2_tbl(i),
                                       L_default_bracket_ind_tbl(i),
                                       L_unit_cost_tbl(i),
                                       NULL,
                                       'N',
                                       'N',
                                       L_dept_tbl(i),
                                       L_cost_uom_tbl(i),
                                       NULL,
                                       L_converted_cost_tbl(i),
                                       L_vpn_tbl(i),
                                       L_ref_item_tbl(i));
      if SQL%FOUND then
         L_inserted := 'Y';
      end if;

     end if;
      ---
     SQL_LIB.SET_MARK('OPEN',
                      'C_WITH_BRACKET_LOCATIONS',
                      'COST_CHANGE_TEMP',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
     open C_WITH_BRACKET_LOCATIONS;

     SQL_LIB.SET_MARK('FETCH',
                      'C_WITH_BRACKET_LOCATIONS',
                      'COST_CHANGE_TEMP',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
     fetch C_WITH_BRACKET_LOCATIONS BULK COLLECT into L_supplier_tbl,
                                                      L_country_tbl,
                                                      L_item_tbl,
                                                      L_dept_tbl,
                                                      L_ref_item_tbl,
                                                      L_cost_uom_tbl,
                                                      L_vpn_tbl;
     SQL_LIB.SET_MARK('CLOSE',
                      'C_WITH_BRACKET_LOCATIONS',
                      'COST_CHANGE_TEMP',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
     close C_WITH_BRACKET_LOCATIONS;
      SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      --- insert for suppliers that have bracket locations.


   if L_item_tbl.first is NOT NULL then
      forall i in L_item_tbl.first..L_item_tbl.last

         insert into cost_change_temp (cost_change,
                                       supplier,
                                       origin_country_id,
                                       item,
                                       bracket_value1,
                                       bracket_uom,
                                       bracket_value2,
                                       default_bracket_ind,
                                       unit_cost_old,
                                       unit_cost_new,
                                       recalc_ord_ind,
                                       loc_level_ind,
                                       dept,
                                       cost_uom,
                                       unit_cost_cuom_new,
                                       unit_cost_cuom_old,
                                       vpn,
                                       ref_item)

                             /* select statement modified to pass the values from the bulk collect*/


                                values (I_cost_change,
                                       L_supplier_tbl(i),
                                       L_country_tbl(i),
                                       L_item_tbl(i),
                                       NULL,
                                       NULL,
                                       NULL,
                                       'N',
                                       NULL,
                                       NULL,
                                       'N',
                                       'Y',
                                       L_dept_tbl(i),
                                       L_cost_uom_tbl(i),
                                       NULL,
                                       NULL,
                                       L_vpn_tbl(i),
                                       L_ref_item_tbl(i));

      if SQL%FOUND then
         L_inserted := 'Y';
      end if;

   end if;

   elsif I_mode in ('EDIT','VIEW') then
      ---
      SQL_LIB.SET_MARK('OPEN','C_COST_MAINT_SUPP',
                       'COST_SUSP_SUP_DETAIL',
                       'Cost Change: '||to_char(I_cost_change));
      FOR current_rec in C_COST_MAINT_SUPP LOOP
         if current_rec.bracket_value1 is NOT NULL then
            if COST_CHANGE_SQL.BC_UNIT_COST (O_error_message,
                                             L_old_unit_cost,
                                             current_rec.supplier,
                                             current_rec.origin_country_id,
                                             current_rec.item,
                                             current_rec.bracket_value1,
                                             NULL) = FALSE then
               return FALSE;
            end if;
         end if;
         if L_old_unit_cost is null or current_rec.bracket_value1 is NULL then
            if SUPP_ITEM_SQL.GET_COST(O_error_message,
                                      L_old_unit_cost,
                                      current_rec.item,
                                      current_rec.supplier,
                                      current_rec.origin_country_id,
                                      NULL) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
        -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
        L_converted_cost1 := L_old_unit_cost;
        -- 21-Oct-2008 TESCO HSC/Murali 6616812 End
        if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                              -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
                                              L_converted_cost1,
                                              -- 21-Oct-2008 TESCO HSC/Murali 6616812 End
                                              current_rec.item,
                                              current_rec.supplier,
                                              current_rec.origin_country_id,
                                              'S',
                                              NULL) = FALSE then
            return FALSE;
         end if;
         -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
         L_converted_cost2:= current_rec.unit_cost;
         -- 21-Oct-2008 TESCO HSC/Murali 6616812 End

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
                                               L_converted_cost2,
                                               -- 21-Oct-2008 TESCO HSC/Murali 6616812 End
                                               current_rec.item,
                                               current_rec.supplier,
                                               current_rec.origin_country_id,
                                               'S',
                                               NULL) = FALSE then
             return FALSE;
          end if;
          -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
          -- 21-Oct-2008 TESCO HSC/Murali 6616812 End

         SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(current_rec.supplier)||
                          ' Origin Country: '||current_rec.origin_country_id||
                          ' Item: '||current_rec.item);
         ---
         insert into cost_change_temp (cost_change,
                                       supplier,
                                       origin_country_id,
                                       item,
                                       bracket_value1,
                                       bracket_uom,
                                       bracket_value2,
                                       default_bracket_ind,
                                       unit_cost_old,
                                       unit_cost_new,
                                       recalc_ord_ind,
                                       loc_level_ind,
                                       dept,
                                       sup_dept_seq_no,
                                       cost_uom,
                                       unit_cost_cuom_new,
                                       unit_cost_cuom_old,
                                       vpn,
                                       ref_item)
                               values (I_cost_change,
                                      current_rec.supplier,
                                      current_rec.origin_country_id,
                                      current_rec.item,
                                      current_rec.bracket_value1,
                                      current_rec.bracket_uom1,
                                      current_rec.bracket_value2,
                                      current_rec.default_bracket_ind,
                                      L_old_unit_cost,
                                      current_rec.unit_cost,
                                      current_rec.recalc_ord_ind,
                                      'N',
                                      current_rec.dept,
                                      current_rec.sup_dept_seq_no,
                                      current_rec.cost_uom,
                                      L_converted_cost2,
                                      L_converted_cost1,
                                      current_rec.vpn,
                                      current_rec.ref_item);
         ---
         L_inserted := 'Y';
      END LOOP;
      ---
      SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      --- create a item header level record for location level records.
      ---
      insert into cost_change_temp (cost_change,
                                    supplier,
                                    origin_country_id,
                                    item,
                                    bracket_value1,
                                    bracket_uom,
                                    bracket_value2,
                                    default_bracket_ind,
                                    unit_cost_old,
                                    unit_cost_new,
                                    recalc_ord_ind,
                                    loc_level_ind,
                                    dept,
                                    cost_uom,
                                    unit_cost_cuom_new,
                                    unit_cost_cuom_old,
                                    vpn,
                                    ref_item)

                             /* select statement is modified to include ITEM_SUPP_COUNRY.cost_uom, ITEM_SUPPLIER.vpn and ITEM_MASTER.primary_ref_item_ind*/


                             select distinct I_cost_change,
                                    cssdl.supplier,
                                    cssdl.origin_country_id,
                                    cssdl.item,
                                    NULL,
                                    NULL,
                                    NULL,
                                    'N',
                                    NULL,
                                    NULL,
                                    'N',
                                    'Y',
                                    cssdl.dept,
                                    isc.cost_uom,
                                    NULL,
                                    NULL,
                                    isp.vpn,
                                    ref_item.ref_item
                               from cost_susp_sup_detail_loc cssdl,
                                    item_master im,
                                    item_supp_country isc,
                                    item_supplier isp,
                                    (select item_parent item, item ref_item
                                       from item_master
                                      where primary_ref_item_ind = 'Y'
                                        and item_parent IS NOT NULL) ref_item
                              where cssdl.cost_change = I_cost_change
                                and cssdl.item = im.item
                                and cssdl.item = isc.item
                                and cssdl.item = isp.item
                                and cssdl.supplier = isc.supplier
                                and cssdl.supplier = isp.supplier
                                and cssdl.origin_country_id = isc.origin_country_id
                                and cssdl.item = ref_item.item(+);

      if SQL%FOUND then
         L_inserted := 'Y';
      end if;

   else raise INVALID_MODE;
   end if;

   if L_inserted = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when INVALID_MODE then
      O_error_message := SQL_LIB.CREATE_MSG('INV_MODE', NULL, NULL, NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END POP_TEMP_DETAIL;
------------------------------------------------------------------------------------------
FUNCTION POP_TEMP_DETAIL_LOC (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exists         IN OUT BOOLEAN,
                              I_mode           IN     VARCHAR2,
                              I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE,
                              I_supplier       IN     SUPS.SUPPLIER%TYPE,
                              I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE,
                              I_item           IN     ITEM_MASTER.ITEM%TYPE,
                              I_reason         IN     COST_SUSP_SUP_HEAD.REASON%TYPE)
   RETURN BOOLEAN IS

   TYPE supplier_tbl              is TABLE OF NUMBER(10)   INDEX BY BINARY_INTEGER;
   TYPE country_tbl               is TABLE OF VARCHAR2(3)  INDEX BY BINARY_INTEGER;
   TYPE item_tbl                  is TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
   TYPE unit_cost_tbl             is TABLE OF NUMBER(20,4) INDEX BY BINARY_INTEGER;
   TYPE cost_uom_tbl              is TABLE OF VARCHAR2(4)  INDEX BY BINARY_INTEGER;
   TYPE dept_tbl                  is TABLE OF NUMBER(4)    INDEX BY BINARY_INTEGER;
   TYPE ref_item_tbl              is TABLE OF VARCHAR2(25)  INDEX BY BINARY_INTEGER;
   TYPE vpn_tbl                   is TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
   TYPE converted_cost_tbl        is TABLE OF NUMBER(20,4) INDEX BY BINARY_INTEGER;
   TYPE bracket_value1_tbl        is TABLE OF NUMBER(12,4) INDEX BY BINARY_INTEGER;
   TYPE bracket_value2_tbl        is TABLE OF NUMBER(12,4) INDEX BY BINARY_INTEGER;
   TYPE default_bracket_ind_tbl   is TABLE OF VARCHAR2(1)  INDEX BY BINARY_INTEGER;
   TYPE loc_tbl                   is TABLE OF NUMBER(10)   INDEX BY BINARY_INTEGER;
   TYPE loc_type_tbl              is TABLE OF VARCHAR2(1)  INDEX BY BINARY_INTEGER;
   TYPE physical_wh_tbl           is TABLE OF NUMBER(10)   INDEX BY BINARY_INTEGER;
   TYPE sup_dept_seq_no_tbl       is TABLE OF NUMBER(10)   INDEX BY BINARY_INTEGER;

   L_supplier_tbl               SUPPLIER_TBL;
   L_country_tbl                COUNTRY_TBL;
   L_item_tbl                   ITEM_TBL;
   L_unit_cost_tbl              UNIT_COST_TBL;
   L_cost_uom_tbl               COST_UOM_TBL;
   L_dept_tbl                   DEPT_TBL;
   L_ref_item_tbl               REF_ITEM_TBL;
   L_vpn_tbl                    VPN_TBL;
   L_converted_cost_tbl         CONVERTED_COST_TBL;
   L_bracket_value1_tbl         BRACKET_VALUE1_TBL;
   L_bracket_value2_tbl         BRACKET_VALUE2_TBL;
   L_default_bracket_ind_tbl    DEFAULT_BRACKET_IND_TBL;
   L_loc_tbl                    LOC_TBL;
   L_loc_type_tbl               LOC_TYPE_TBL;
   L_physical_wh_tbl            PHYSICAL_WH_TBL;
   L_sup_dept_seq_no_tbl        SUP_DEPT_SEQ_NO_TBL;

   L_converted_cost1 NUMBER(20,4);
   L_converted_cost2 NUMBER(20,4);

   L_program   VARCHAR2(60)   := 'COST_CHANGE_SQL.POP_TEMP_DETAIL_LOC';

   L_inserted        VARCHAR2(1) := 'N';
   L_locs_exist      BOOLEAN := FALSE;
   L_old_unit_cost   COST_CHANGE_TEMP.UNIT_COST_OLD%TYPE;


   ---
   INVALID_MODE      EXCEPTION;
   ---

   /* Old cursor is modified to include ITEM_SUPP_COUNRY.cost_uom, ITEM_SUPPLIER.vpn and ITEM_MASTER.primary_ref_item_ind*/


   cursor C_COST_CHANGE_STORE is
      select cssdl.supplier,
             cssdl.origin_country_id,
             cssdl.item,
             cssdl.loc_type,
             cssdl.loc,
             cssdl.bracket_value1,
             cssdl.bracket_uom1,
             cssdl.default_bracket_ind,
             cssdl.unit_cost,
             cssdl.recalc_ord_ind,
             cssdl.dept,
             cssdl.sup_dept_seq_no,
             ref_item.ref_item,
             isc.cost_uom,
             isp.vpn
        from cost_susp_sup_detail_loc cssdl,
             item_master im,
             item_supp_country isc,
             item_supplier isp,
   	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
       where cssdl.loc_type          = 'S'
         and cssdl.cost_change       = I_cost_change
         and cssdl.item              = I_item
         and cssdl.supplier          = I_supplier
         and cssdl.origin_country_id = I_origin_country
         and cssdl.item              = im.item
         and cssdl.item              = isc.item
         and cssdl.item              = isp.item
         and cssdl.supplier          = isc.supplier
         and cssdl.supplier          = isp.supplier
         and cssdl.origin_country_id = isc.origin_country_id
         and cssdl.item              = ref_item.item(+);

   ---
   /* Old cursor is modified to include ITEM_SUPP_COUNRY.cost_uom, ITEM_SUPPLIER.vpn and ITEM_MASTER.primary_ref_item_ind*/


   cursor C_COST_CHANGE_WH is
      select distinct cssdl.supplier,
                      cssdl.origin_country_id,
                      cssdl.item,
                      cssdl.loc_type,
                      w.physical_wh,
                      cssdl.bracket_value1,
                      cssdl.bracket_uom1,
                      cssdl.bracket_value2,
                      cssdl.default_bracket_ind,
                      cssdl.unit_cost,
                      cssdl.recalc_ord_ind,
                      cssdl.dept,
                      cssdl.sup_dept_seq_no,
                      ref_item.ref_item,
                      isc.cost_uom,
                      isp.vpn
                 from cost_susp_sup_detail_loc cssdl,
                      wh w,
                      item_master im,
                      item_supp_country isc,
                      item_supplier isp,
        	      (select item_parent item, item ref_item
                         from item_master
                        where primary_ref_item_ind = 'Y'
                          and item_parent IS NOT NULL) ref_item
                where cssdl.loc_type          = 'W'
                  and w.wh                    = cssdl.loc
                  and cssdl.cost_change       = I_cost_change
                  and cssdl.item              = I_item
                  and cssdl.supplier          = I_supplier
                  and cssdl.origin_country_id = I_origin_country
                  and cssdl.item              = im.item
                  and cssdl.item              = isc.item
                  and cssdl.item              = isp.item
                  and cssdl.supplier          = isc.supplier
                  and cssdl.supplier          = isp.supplier
                  and cssdl.origin_country_id = isc.origin_country_id
                  and cssdl.item              = ref_item.item(+);

   cursor C_FIRST_INSERT is
      select iscl.supplier,
             iscl.origin_country_id,
             iscl.item,
             iscl.loc_type,
             iscl.loc,
             iscl.unit_cost,
             im.dept,
             ref_item.ref_item,
             isc.cost_uom,
             isp.vpn
        from item_supp_country_loc iscl,
             item_master im,
             item_supplier isp,
             item_supp_country isc,
             (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
       where iscl.loc_type          = 'S'
         and iscl.origin_country_id = I_origin_country
         and iscl.supplier          = I_supplier
         and iscl.item              = I_item
         and iscl.item              = im.item
         and im.status              = 'A'
         and iscl.supplier          = isp.supplier
         and iscl.supplier          = isc.supplier
         and iscl.item              = isp.item
         and iscl.item              = isc.item
         and iscl.origin_country_id = isc.origin_country_id
         and iscl.item              = ref_item.item(+);

   cursor C_SECOND_INSERT is
      select distinct iscl.supplier,
                      iscl.origin_country_id,
                      iscl.item,
                      iscl.loc_type,
                      w.physical_wh,
                      iscl.unit_cost,
                      im.dept,
                      ref_item.ref_item,
                      isc.cost_uom,
                      isp.vpn
                 from wh w,
                      item_supp_country_loc iscl,
                      sups s,
                      item_master im,
                      item_supplier isp,
                      item_supp_country isc,
                      (select item_parent item, item ref_item
                         from item_master
                        where primary_ref_item_ind = 'Y'
                          and item_parent IS NOT NULL) ref_item
                where s.supplier             = iscl.supplier
                  and s.bracket_costing_ind  = 'N'
                  and iscl.loc               = w.wh
                  and iscl.origin_country_id = I_origin_country
                  and iscl.supplier          = I_supplier
                  and iscl.item              = I_item
                  and iscl.item              = im.item
                  and im.status              = 'A'
                  and iscl.supplier          = isp.supplier
                  and iscl.supplier          = isc.supplier
                  and iscl.item              = isp.item
                  and iscl.item              = isc.item
                  and iscl.origin_country_id = isc.origin_country_id
                  and iscl.item              = ref_item.item(+);

   cursor C_THIRD_INSERT is
      select distinct iscbc.supplier,
                      iscbc.origin_country_id,
                      iscbc.item,
                      iscbc.loc_type,
                      w.physical_wh,
                      iscbc.bracket_value1,
                      iscbc.bracket_value2,
                      iscbc.default_bracket_ind,
                      iscbc.unit_cost,
                      im.dept,
                      ref_item.ref_item,
                      isc.cost_uom,
                      isp.vpn
                 from wh w,
                      item_supp_country_bracket_cost iscbc,
                      item_master im,
                      item_supplier isp,
                      item_supp_country isc,
                      (select item_parent item, item ref_item
                         from item_master
                        where primary_ref_item_ind = 'Y'
                          and item_parent IS NOT NULL) ref_item
                where iscbc.location          = w.wh
                  and iscbc.origin_country_id = I_origin_country
                  and iscbc.supplier          = I_supplier
                  and iscbc.item              = I_item
                  and iscbc.item              = im.item
                  and im.status               = 'A'
                  and iscbc.supplier          = isp.supplier
                  and iscbc.supplier          = isc.supplier
                  and iscbc.item              = isp.item
                  and iscbc.item              = isc.item
                  and iscbc.origin_country_id = isc.origin_country_id
                  and iscbc.item              = ref_item.item(+);

   cursor C_FOURTH_INSERT is
      select distinct cssd.supplier,
                      cssd.origin_country_id,
                      cssd.item,
                      iscl.loc_type,
                      w.physical_wh,
                      cssd.bracket_value1,
                      cssd.bracket_value2,
                      cssd.default_bracket_ind,
                      cssd.unit_cost,
                      cssd.dept,
                      cssd.sup_dept_seq_no,
                      ref_item.ref_item,
                      isc.cost_uom,
                      isp.vpn
                 from wh w,
                      item_supp_country_loc iscl,
                      cost_susp_sup_detail cssd,
                      item_master im,
                      item_supplier isp,
                      item_supp_country isc,
                      (select item_parent item, item ref_item
                         from item_master
                        where primary_ref_item_ind = 'Y'
                          and item_parent IS NOT NULL) ref_item
                where iscl.loc                = w.wh
                  and cssd.origin_country_id  = iscl.origin_country_id
                  and cssd.origin_country_id  = I_origin_country
                  and cssd.supplier           = I_supplier
                  and cssd.item               = I_item
                  and iscl.supplier           = cssd.supplier
                  and iscl.item               = cssd.item
                  and cssd.cost_change        = nvl(I_cost_change,cssd.cost_change)
                  and iscl.supplier           = isp.supplier
                  and iscl.supplier           = isc.supplier
                  and iscl.item               = im.item
                  and iscl.item               = isp.item
                  and iscl.item               = isc.item
                  and iscl.origin_country_id  = isc.origin_country_id
                  and iscl.item               = ref_item.item(+);

BEGIN
   ---
   if I_mode = 'NEW' then
       ---
       if I_reason not in (1,2,3) then

          SQL_LIB.SET_MARK('OPEN',
                      'C_FIRST_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          open C_FIRST_INSERT;

          SQL_LIB.SET_MARK('FETCH',
                      'C_FIRST_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          fetch C_FIRST_INSERT BULK COLLECT into L_supplier_tbl,
                                                 L_country_tbl,
                                                 L_item_tbl,
                                                 L_loc_type_tbl,
                                                 L_loc_tbl,
                                                 L_unit_cost_tbl,
                                                 L_dept_tbl,
                                                 L_ref_item_tbl,
                                                 L_cost_uom_tbl,
                                                 L_vpn_tbl;

          SQL_LIB.SET_MARK('CLOSE',
                      'C_FIRST_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          close C_FIRST_INSERT;

          if L_item_tbl.first is NOT NULL then

             for i in L_item_tbl.first..L_item_tbl.last loop
               if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                     L_unit_cost_tbl(i),
                                                     L_item_tbl(i),
                                                     L_supplier_tbl(i),
                                                     L_country_tbl(i),
                                                     'S',
                                                     NULL) = FALSE then
                  return FALSE;
               end if;
               L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
             end loop;

             ---
             SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP',
                              'Cost Change: '||to_char(I_cost_change)||
                              ' Supplier: '||to_char(I_supplier)||
                              ' Origin Country: '||I_origin_country||
                              ' Item: '||I_item);

             forall i in L_item_tbl.first..L_item_tbl.last

                insert into cost_change_loc_temp (cost_change,
                                                  supplier,
                                                  origin_country_id,
                                                  item,
                                                  loc_type,
                                                  location,
                                                  bracket_value1,
                                                  bracket_uom,
                                                  bracket_value2,
                                                  default_bracket_ind,
                                                  unit_cost_old,
                                                  unit_cost_new,
                                                  recalc_ord_ind,
                                                  dept,
                                                  cost_uom,
                                                  unit_cost_cuom_new,
                                                  unit_cost_cuom_old,
                                                  vpn,
                                                  ref_item)

                                     /* select statement modified to pass the values from the bulk collect*/


                                          values (I_cost_change,
                                                  L_supplier_tbl(i),
                                                  L_country_tbl(i),
                                                  L_item_tbl(i),
                                                  L_loc_type_tbl(i),
                                                  L_loc_tbl(i),
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  'N',
                                                  L_unit_cost_tbl(i),
                                                  NULL,
                                                  'N',
                                                  L_dept_tbl(i),
                                                  L_cost_uom_tbl(i),
                                                  NULL,
                                                  L_converted_cost_tbl(i),
                                                  L_vpn_tbl(i),
                                                  L_ref_item_tbl(i));


                if SQL%FOUND then
                   L_inserted := 'Y';
                end if;
                ---

          end if;

          SQL_LIB.SET_MARK('OPEN',
                      'C_SECOND_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          open C_SECOND_INSERT;

          SQL_LIB.SET_MARK('FETCH',
                      'C_SECOND_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          fetch C_SECOND_INSERT BULK COLLECT into L_supplier_tbl,
                                                  L_country_tbl,
                                                  L_item_tbl,
                                                  L_loc_type_tbl,
                                                  L_physical_wh_tbl,
                                                  L_unit_cost_tbl,
                                                  L_dept_tbl,
                                                  L_ref_item_tbl,
                                                  L_cost_uom_tbl,
                                                  L_vpn_tbl;

          SQL_LIB.SET_MARK('CLOSE',
                      'C_SECOND_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          close C_SECOND_INSERT;

          if L_item_tbl.first is NOT NULL then
             for i in L_item_tbl.first..L_item_tbl.last loop
               if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                     L_unit_cost_tbl(i),
                                                     L_item_tbl(i),
                                                     L_supplier_tbl(i),
                                                     L_country_tbl(i),
                                                     'S',
                                                     NULL) = FALSE then
                  return FALSE;
               end if;
               L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
            end loop;

            SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP',
                             'Cost Change: '||to_char(I_cost_change)||
                             ' Supplier: '||to_char(I_supplier)||
                             ' Origin Country: '||I_origin_country||
                             ' Item: '||I_item);

             forall i in L_item_tbl.first..L_item_tbl.last

                insert into cost_change_loc_temp (cost_change,
                                                  supplier,
                                                  origin_country_id,
                                                  item,
                                                  loc_type,
                                                  location,
                                                  bracket_value1,
                                                  bracket_uom,
                                                  bracket_value2,
                                                  default_bracket_ind,
                                                  unit_cost_old,
                                                  unit_cost_new,
                                                  recalc_ord_ind,
                                                  dept,
                                                  cost_uom,
                                                  unit_cost_cuom_new,
                                                  unit_cost_cuom_old,
                                                  vpn,
                                                  ref_item)

                                    /* select statement modified to pass the values from the bulk collect*/


                                          values (I_cost_change,
                                                  L_supplier_tbl(i),
                                                  L_country_tbl(i),
                                                  L_item_tbl(i),
                                                  L_loc_type_tbl(i),
                                                  L_physical_wh_tbl(i),
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  'N',
                                                  L_unit_cost_tbl(i),
                                                  NULL,
                                                  'N',
                                                  L_dept_tbl(i),
                                                  L_cost_uom_tbl(i),
                                                  NULL,
                                                  L_converted_cost_tbl(i),
                                                  L_vpn_tbl(i),
                                                  L_ref_item_tbl(i));

                if SQL%FOUND then
                   L_inserted := 'Y';
                end if;
                ---

          end if;

          SQL_LIB.SET_MARK('OPEN',
                      'C_THIRD_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          open C_THIRD_INSERT;

          SQL_LIB.SET_MARK('FETCH',
                      'C_THIRD_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          fetch C_THIRD_INSERT BULK COLLECT into L_supplier_tbl,
                                                 L_country_tbl,
                                                 L_item_tbl,
                                                 L_loc_type_tbl,
                                                 L_physical_wh_tbl,
                                                 L_bracket_value1_tbl,
                                                 L_bracket_value2_tbl,
                                                 L_default_bracket_ind_tbl,
                                                 L_unit_cost_tbl,
                                                 L_dept_tbl,
                                                 L_ref_item_tbl,
                                                 L_cost_uom_tbl,
                                                 L_vpn_tbl;

          SQL_LIB.SET_MARK('CLOSE',
                      'C_THIRD_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          close C_THIRD_INSERT;

          if L_item_tbl.first is NOT NULL then

             for i in L_item_tbl.first..L_item_tbl.last loop
               if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                     L_unit_cost_tbl(i),
                                                     L_item_tbl(i),
                                                     L_supplier_tbl(i),
                                                     L_country_tbl(i),
                                                     'S',
                                                     NULL) = FALSE then
  return FALSE;
               end if;

               L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
             end loop;

             SQL_LIB.SET_MARK('INSERT', NULL,  'COST_CHANGE_LOC_TEMP',
                              'Cost Change: '||to_char(I_cost_change)||
                              ' Supplier: '||to_char(I_supplier)||
                              ' Origin Country: '||I_origin_country||
                              ' Item: '||I_item);

             forall i in L_item_tbl.first..L_item_tbl.last

                insert into cost_change_loc_temp (cost_change,
                                                  supplier,
                                                  origin_country_id,
                                                  item,
                                                  loc_type,
                                                  location,
                                                  bracket_value1,
                                                  bracket_uom,
                                                  bracket_value2,
                                                  default_bracket_ind,
                                                  unit_cost_old,
                                                  unit_cost_new,
                                                  recalc_ord_ind,
                                                  dept,
                                                  cost_uom,
                                                  unit_cost_cuom_new,
                                                  unit_cost_cuom_old,
                                                  vpn,
                                                  ref_item)

                                    /* select statement modified to pass the values from the bulk collect*/


                                          values (I_cost_change,
                                                  L_supplier_tbl(i),
                                                  L_country_tbl(i),
                                                  L_item_tbl(i),
                                                  L_loc_type_tbl(i),
                                                  L_physical_wh_tbl(i),
                                                  L_bracket_value1_tbl(i),
                                                  NULL,
                                                  L_bracket_value2_tbl(i),
                                                  L_default_bracket_ind_tbl(i),
                                                  L_unit_cost_tbl(i),
                                                  NULL,
                                                  'N',
                                                  L_dept_tbl(i),
                                                  L_cost_uom_tbl(i),
                                                  NULL,
                                                  L_converted_cost_tbl(i),
                                                  L_vpn_tbl(i),
                                                  L_ref_item_tbl(i));
                if SQL%FOUND then
                   L_inserted := 'Y';
                end if;

          end if;

       else

          SQL_LIB.SET_MARK('OPEN',
                      'C_FOURTH_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          open C_FOURTH_INSERT;

          SQL_LIB.SET_MARK('FETCH',
                      'C_FOURTH_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          fetch C_FOURTH_INSERT BULK COLLECT into L_supplier_tbl,
                                                  L_country_tbl,
                                                  L_item_tbl,
                                                  L_loc_type_tbl,
                                                  L_physical_wh_tbl,
                                                  L_bracket_value1_tbl,
                                                  L_bracket_value2_tbl,
                                                  L_default_bracket_ind_tbl,
                                                  L_unit_cost_tbl,
                                                  L_dept_tbl,
                                                  L_sup_dept_seq_no_tbl,
                                                  L_ref_item_tbl,
                                                  L_cost_uom_tbl,
                                                  L_vpn_tbl;

          SQL_LIB.SET_MARK('CLOSE',
                      'C_FOURTH_INSERT',
                      'COST_CHANGE_TEMP_LOC',
                      'Cost Change: '||to_char(I_cost_change)||
                      ' Supplier: '||to_char(I_supplier)||
                      ' Origin Country: '||I_origin_country||
                      ' Item: '||I_item);
          close C_FOURTH_INSERT;

          if L_item_tbl.first is NOT NULL then
             for i in L_item_tbl.first..L_item_tbl.last loop
               if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                     L_unit_cost_tbl(i),
                                                     L_item_tbl(i),
                                                     L_supplier_tbl(i),
                                                     L_country_tbl(i),
                                                     'S',
                                                     NULL) = FALSE then
                  return FALSE;
               end if;
               L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
            end loop;
            SQL_LIB.SET_MARK('INSERT', NULL,  'COST_CHANGE_LOC_TEMP',
                             'Cost Change: '||to_char(I_cost_change)||
                             ' Supplier: '||to_char(I_supplier)||
                             ' Origin Country: '||I_origin_country||
                             ' Item: '||I_item);

             forall i in L_item_tbl.first..L_item_tbl.last

                insert into cost_change_loc_temp (cost_change,
                                                  supplier,
                                                  origin_country_id,
                                                  item,
                                                  loc_type,
                                                  location,
                                                  bracket_value1,
                                                  bracket_uom,
                                                  bracket_value2,
                                                  default_bracket_ind,
                                                  unit_cost_old,
                                                  unit_cost_new,
                                                  recalc_ord_ind,
                                                  dept,
                                                  sup_dept_seq_no,
                                                  cost_uom,
                                                  unit_cost_cuom_new,
                                                  unit_cost_cuom_old,
                                                  vpn,
                                                  ref_item)

                                    /* select statement modified to pass the values from the bulk collect*/


                                          values (I_cost_change,
                                                  L_supplier_tbl(i),
                                                  L_country_tbl(i),
                                                  L_item_tbl(i),
                                                  L_loc_type_tbl(i),
                                                  L_physical_wh_tbl(i),
                                                  L_bracket_value1_tbl(i),
                                                  NULL,
                                                  L_bracket_value2_tbl(i),
                                                  L_default_bracket_ind_tbl(i),
                                                  L_unit_cost_tbl(i),
                                                  0,
                                                  'N',
                                                  L_dept_tbl(i),
                                                  L_sup_dept_seq_no_tbl(i),
                                                  L_cost_uom_tbl(i),
                                                  NULL,
                                                  L_converted_cost_tbl(i),
                                                  L_vpn_tbl(i),
                                                  L_ref_item_tbl(i));
                if SQL%FOUND then
                   L_inserted := 'Y';
                end if;
                ---
          end if;
       end if;
       ---
   elsif I_mode in ('EDIT','VIEW') then
      ---
      SQL_LIB.SET_MARK('OPEN','C_COST_CHANGE_STORE',
                       'COST_SUSP_SUP_DETAIL_LOC',
                       'Cost Change: '||to_char(I_cost_change));
      FOR current_rec in C_COST_CHANGE_STORE LOOP
         if NOT SUPP_ITEM_SQL.GET_COST(O_error_message,
                                       L_old_unit_cost,
                                       current_rec.item,
                                       current_rec.supplier,
                                       current_rec.origin_country_id,
                                       current_rec.loc)  then
            return FALSE;
         end if;
         ---

        if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                              L_old_unit_cost,
                                              current_rec.item,
                                              current_rec.supplier,
                                              current_rec.origin_country_id,
                                              'S',
                                              NULL) = FALSE then
            return FALSE;
         end if;
         L_converted_cost1 := L_old_unit_cost;

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               current_rec.unit_cost,
                                               current_rec.item,
                                               current_rec.supplier,
                                               current_rec.origin_country_id,
                                               'S',
                                               NULL) = FALSE then
             return FALSE;
          end if;
         L_converted_cost2:= current_rec.unit_cost;

         SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         ---
         insert into cost_change_loc_temp (cost_change,
                                           supplier,
                                           origin_country_id,
                                           item,
                                           loc_type,
                                           location,
                                           bracket_value1,
                                           bracket_uom,
                                           default_bracket_ind,
                                           unit_cost_old,
                                           unit_cost_new,
                                           recalc_ord_ind,
                                           dept,
                                           cost_uom,
                                           unit_cost_cuom_new,
                                           unit_cost_cuom_old,
                                           vpn,
                                           ref_item)
                                   values (I_cost_change,
                                           current_rec.supplier,
                                           current_rec.origin_country_id,
                                           current_rec.item,
                                           current_rec.loc_type,
                                           current_rec.loc,
                                           current_rec.bracket_value1,
                                           current_rec.bracket_uom1,
                                           current_rec.default_bracket_ind,
                                           L_old_unit_cost,
                                           current_rec.unit_cost,
                                           current_rec.recalc_ord_ind,
                                           current_rec.dept,
                                           current_rec.cost_uom,
                                           L_converted_cost2,
                                           L_converted_cost1,
                                           current_rec.vpn,
                                           current_rec.ref_item);
         ---
         if SQL%FOUND then
            L_inserted := 'Y';
         end if;
      END LOOP;
      SQL_LIB.SET_MARK('CLOSE','C_COST_CHANGE_STORE',
                       'COST_SUSP_SUP_DETAIL_LOC',
                       'Cost Change: '||to_char(I_cost_change));
      ---
      SQL_LIB.SET_MARK('OPEN','C_COST_CHANGE_WH',
                       'COST_SUSP_SUP_DETAIL_LOC',
                       'Cost Change: '||to_char(I_cost_change));
      FOR current_rec in C_COST_CHANGE_WH LOOP
         ---
         if current_rec.bracket_value1 is NOT NULL then
            if COST_CHANGE_SQL.BC_UNIT_COST (O_error_message,
                                             L_old_unit_cost,
                                             current_rec.supplier,
                                             current_rec.origin_country_id,
                                             current_rec.item,
                                             current_rec.bracket_value1,
                                             current_rec.physical_wh) = FALSE then
               return FALSE;
            end if;
         end if;
         if L_old_unit_cost is null or current_rec.bracket_value1 is NULL then
            if SUPP_ITEM_SQL.GET_COST(O_error_message,
                                      L_old_unit_cost,
                                      current_rec.item,
                                      current_rec.supplier,
                                      current_rec.origin_country_id,
                                      current_rec.physical_wh) = FALSE then
               return FALSE;
            end if;
         end if;
         ---

        if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                              L_old_unit_cost,
                                              current_rec.item,
                                              current_rec.supplier,
                                              current_rec.origin_country_id,
                                              'S',
                                              NULL) = FALSE then
            return FALSE;
         end if;
         L_converted_cost1 := L_old_unit_cost;

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               current_rec.unit_cost,
                                               current_rec.item,
                                               current_rec.supplier,
                                               current_rec.origin_country_id,
                                               'S',
                                               NULL) = FALSE then
             return FALSE;
          end if;
         L_converted_cost2:= current_rec.unit_cost;

         SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         ---
         insert into cost_change_loc_temp (cost_change,
                                           supplier,
                                           origin_country_id,
                                           item,
                                           loc_type,
                                           location,
                                           bracket_value1,
                                           bracket_uom,
                                           bracket_value2,
                                           default_bracket_ind,
                                           unit_cost_old,
                                           unit_cost_new,
                                           recalc_ord_ind,
                                           dept,
                                           sup_dept_seq_no,
                                           cost_uom,
                                           unit_cost_cuom_new,
                                           unit_cost_cuom_old,
                                           vpn,
                                           ref_item)
                                   values (I_cost_change,
                                           current_rec.supplier,
                                           current_rec.origin_country_id,
                                           current_rec.item,
                                           current_rec.loc_type,
                                           current_rec.physical_wh,
                                           current_rec.bracket_value1,
                                           current_rec.bracket_uom1,
                                           current_rec.bracket_value2,
                                           current_rec.default_bracket_ind,
                                           L_old_unit_cost,
                                           current_rec.unit_cost,
                                           current_rec.recalc_ord_ind,
                                           current_rec.dept,
                                           current_rec.sup_dept_seq_no,
                                           current_rec.cost_uom,
                                           L_converted_cost2,
                                           L_converted_cost1,
                                           current_rec.vpn,
                                           current_rec.ref_item);
         ---
         if SQL%FOUND then
            L_inserted := 'Y';
         end if;
      END LOOP;
      SQL_LIB.SET_MARK('CLOSE','C_COST_CHANGE_WH',
                       'COST_SUSP_SUP_DETAIL_LOC',
                       'Cost Change: '||to_char(I_cost_change));
      --- Check if Locations are inserted
      if L_inserted = 'N' then
      --- Call procedure again in new mode for cost changes maintained at the country level
         if NOT COST_CHANGE_SQL.POP_TEMP_DETAIL_LOC(O_error_message,
                                                    L_locs_exist,
                                                    'NEW',
                                                     I_cost_change,
                                                    I_supplier,
                                                    I_origin_country,
                                                    I_item,
                                                    I_reason ) then
            return FALSE;
         end if;
         ---
         if L_locs_exist then
            L_inserted := 'Y';
         end if;
      end if;
   else raise INVALID_MODE;
   end if; -- I_mode NEW/EDIT,VIEW

   if L_inserted = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when INVALID_MODE then
      O_error_message := SQL_LIB.CREATE_MSG('INV_MODE', NULL, NULL, NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END POP_TEMP_DETAIL_LOC;
------------------------------------------------------------------------------------------
FUNCTION APPLY_CHANGE (O_error_message   IN OUT   VARCHAR2,
                       I_change_type     IN       VARCHAR2,
                       I_change_amount   IN       NUMBER)
   RETURN BOOLEAN IS
   ---

   L_null_parameter_name VARCHAR2(30);
   ---
   NULL_PARAMETER        EXCEPTION;
   ---
   NEGATIVE_AMOUNT       EXCEPTION;
   ---

   L_supplier             COST_CHANGE_TEMP.SUPPLIER%TYPE;
   L_origin_country_id    COST_CHANGE_TEMP.ORIGIN_COUNTRY_ID%TYPE;
   L_item                 COST_CHANGE_TEMP.ITEM%TYPE;
   L_bracket_value1       COST_CHANGE_TEMP.BRACKET_VALUE1%TYPE;
   ---
   L_unit_cost_new        COST_CHANGE_TEMP.UNIT_COST_NEW%TYPE;
   L_unit_cost_old        COST_CHANGE_TEMP.UNIT_COST_OLD%TYPE;
   L_unit_cost_cuom_new   COST_CHANGE_TEMP.UNIT_COST_CUOM_NEW%TYPE;
   L_unit_cost_cuom_old   COST_CHANGE_TEMP.UNIT_COST_CUOM_OLD%TYPE;
   ---
   L_table                VARCHAR2(30);
   RECORD_LOCKED          EXCEPTION;

   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);
   ---



   cursor C_PROCESS_COST_CHANGE_TEMP is
      select supplier,
             origin_country_id,
             item,
             unit_cost_old,
             unit_cost_cuom_old,
             bracket_value1
        from cost_change_temp;

   ---
   cursor C_LOCK_COST_CHANGE_TEMP is
      select 'x'
        from cost_change_temp
       where supplier              = L_supplier
         and origin_country_id     = L_origin_country_id
         and item                  = L_item
         and NVL(bracket_value1,0) = L_bracket_value1
         for update nowait;
    ---

BEGIN
   if I_change_type  is NULL then
      L_null_parameter_name := 'change_type';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_change_amount is NULL then
      L_null_parameter_name := 'change_amount';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_change_type = 'P' and I_change_amount < -100 then
      raise NEGATIVE_AMOUNT;
   end if;
   ---
   If I_change_type = 'F' and I_change_amount < 0 then
      raise NEGATIVE_AMOUNT;
   end if;
   ---

   -- Update the rows in the COST_CHANGE_TEMP
   -- per supplier/origin_country/item combination.

   FOR rec in C_PROCESS_COST_CHANGE_TEMP LOOP
      L_supplier           := rec.supplier;
      L_origin_country_id  := rec.origin_country_id;
      L_item               := rec.item;
      L_bracket_value1     := NVL(rec.bracket_value1,0);

      L_unit_cost_old      := rec.unit_cost_old;
      L_unit_cost_cuom_old := rec.unit_cost_cuom_old;

      if I_change_type = 'P' then
         L_unit_cost_cuom_new := L_unit_cost_cuom_old * (1 + I_change_amount/100);

      elsif I_change_type = 'A' then
         L_unit_cost_cuom_new  := L_unit_cost_cuom_old + I_change_amount;

      elsif I_change_type = 'F' then
         L_unit_cost_cuom_new  := I_change_amount;

      end if;

      if (L_unit_cost_cuom_new < 0) then
         raise NEGATIVE_AMOUNT;
      end if;

      L_unit_cost_new      := L_unit_cost_cuom_new;

      if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                            L_unit_cost_new,
                                            L_item,
                                            L_supplier,
                                            L_origin_country_id,
                                            'C') = FALSE then
          return FALSE;
      end if;

      L_table := 'COST_CHANGE_TEMP';

      SQL_LIB.SET_MARK('OPEN',
                        NULL,
                       'COST_CHANGE_TEMP',
                       'unit_cost_cuom_new');
      open C_LOCK_COST_CHANGE_TEMP;

      SQL_LIB.SET_MARK('CLOSE',
                        NULL,
                       'COST_CHANGE_TEMP',
                       'unit_cost_cuom_new');
      close C_LOCK_COST_CHANGE_TEMP;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'COST_CHANGE_TEMP',
                       'Item:'||L_item||'Supplier:'||L_supplier||'Origin_country_id:'||L_origin_country_id||'Bracket Value:'||L_bracket_value1);




      update cost_change_temp
         set unit_cost_cuom_new    = L_unit_cost_cuom_new,
             unit_cost_new         = L_unit_cost_new,
             cost_change_type      = I_change_type,
             cost_change_value     = I_change_amount
       where supplier              = L_supplier
         and origin_country_id     = L_origin_country_id
         and item                  = L_item
         and NVL(bracket_value1,0) = L_bracket_value1;

   end LOOP;

   return TRUE;

EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             'APPLY_CHANGE',
                                             NULL);
      return FALSE;
   when NEGATIVE_AMOUNT then
      O_error_message := SQL_LIB.CREATE_MSG('U/P_COST_NOT_NEG',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(L_supplier) || ', ' || L_origin_country_id,
                                            L_item);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'APPLY_CHANGE',
                                             to_char(SQLCODE));
      return FALSE;
END APPLY_CHANGE;
------------------------------------------------------------------------------------------
FUNCTION APPLY_CHANGE_LOC (O_error_message    IN OUT VARCHAR2,
                           I_supplier         IN     COST_CHANGE_LOC_TEMP.SUPPLIER%TYPE,
                           I_country          IN     COST_CHANGE_LOC_TEMP.ORIGIN_COUNTRY_ID%TYPE,
                           I_item             IN     COST_CHANGE_LOC_TEMP.ITEM%TYPE,
                           I_loc_type         IN     COST_CHANGE_LOC_TEMP.LOC_TYPE%TYPE,
                           I_location         IN     VARCHAR2,
                           I_bracket_value    IN     COST_CHANGE_LOC_TEMP.BRACKET_VALUE1%TYPE,
                           I_change_type      IN     VARCHAR2,
                           I_change_amount    IN     NUMBER)
   RETURN BOOLEAN IS
   ---
   L_new_unit_cost       COST_CHANGE_LOC_TEMP.UNIT_COST_NEW%TYPE;
   L_null_parameter_name VARCHAR2(30);
   ---
   NULL_PARAMETER        EXCEPTION;
   ---
   NEGATIVE_AMOUNT       EXCEPTION;
   ---

   L_unit_cost_new        COST_CHANGE_TEMP.UNIT_COST_NEW%TYPE;
   L_unit_cost_old        COST_CHANGE_TEMP.UNIT_COST_OLD%TYPE;
   L_unit_cost_cuom_new   COST_CHANGE_TEMP.UNIT_COST_CUOM_NEW%TYPE;
   L_unit_cost_cuom_old   COST_CHANGE_TEMP.UNIT_COST_CUOM_OLD%TYPE;
   L_loc_type             VARCHAR(5);
   L_loc_type_SW          VARCHAR2(1);
   L_table                VARCHAR2(50) := 'COST_CHANGE_LOC_TEMP';

   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);



   cursor C_PROCESS_COST_CHANGE_LOC_AL is
      select location,
             loc_type,
             unit_cost_old,
             unit_cost_cuom_old
        from cost_change_loc_temp
       where item              = I_item
         and origin_country_id = I_country
         and supplier          = I_supplier;


   cursor C_LOCK_COST_CHANGE_LOC_AL is
      select 'x'
        from cost_change_loc_temp
       where item              = I_item
         and origin_country_id = I_country
         and supplier          = I_supplier;



   cursor C_PROCESS_COST_CHANGE_LOC_ASAW is
      select location,
             unit_cost_old,
             unit_cost_cuom_old
        from cost_change_loc_temp
       where loc_type          = L_loc_type_SW
         and item              = I_item
         and origin_country_id = I_country
         and supplier          = I_supplier;


   cursor C_LOCK_COST_CHANGE_LOC_ASAW is
      select 'x'
        from cost_change_loc_temp
       where loc_type          = L_loc_type_SW
         and item              = I_item
         and origin_country_id = I_country
         and supplier          = I_supplier;



   cursor C_PROCESS_COST_CHANGE_LOC_SW is
      select unit_cost_old,
             unit_cost_cuom_old
        from cost_change_loc_temp
       where loc_type          = L_loc_type_SW
         and location          = TO_NUMBER(I_location)
         and item              = I_item
         and origin_country_id = I_country
         and supplier          = I_supplier;


   cursor C_LOCK_COST_CHANGE_LOC_SW is
      select 'x'
        from cost_change_loc_temp
       where loc_type          = L_loc_type_SW
         and location          = TO_NUMBER(I_location)
         and item              = I_item
         and origin_country_id = I_country
         and supplier          = I_supplier;



   cursor C_PROCESS_COST_CHANGE_LOC is
      select location,
             unit_cost_old,
             unit_cost_cuom_old
        from cost_change_loc_temp
       where location in (select store
                            from store
                           where store_class        = I_location
                             and L_loc_type         = 'C'
                           UNION
                          select store
                            from store
                           where district           = TO_NUMBER(I_location)
                             and L_loc_type         = 'D'
                           UNION
                          select s.store
                            from store    s,
                                 district d,
                                 region   r
                           where d.district         = s.district
                             and r.region           = d.region
                             and r.area             = TO_NUMBER(I_location)
                             and L_loc_type         = 'A'
                           UNION
                          select s.store
                            from store    s,
                                 district d
                           where d.district         = s.district
                             and d.region           = TO_NUMBER(I_location)
                             and L_loc_type         = 'R'
                           UNION
                          select location
                            from loc_list_detail
                           where loc_list           = TO_NUMBER(I_location)
                             and L_loc_type         = 'LLS'
                           UNION
                          select s.store
                            from store s,
                                 loc_traits_matrix ltm
                           where ltm.store          = s.store
                             and ltm.loc_trait      = TO_NUMBER(I_location)
                             and L_loc_type         = 'L'
                           UNION
                          select distinct wh.physical_wh
                            from wh,
                                 loc_list_detail l
                           where (l.location        = wh.wh
                                  or wh.physical_wh = l.location)
                             and loc_list           = TO_NUMBER(I_location)
                             and L_loc_type         = 'LLW')
         and item              = I_item
         and origin_country_id = I_country
         and supplier          = I_supplier
         and loc_type          = L_loc_type_SW;

   cursor C_LOCK_COST_CHANGE_LOC is
      select 'x'
        from cost_change_loc_temp
       where location in (select store
                            from store
                           where store_class   = I_location
                             and L_loc_type    = 'C'
                           UNION
                          select store
                            from store
                           where district      = TO_NUMBER(I_location)
                             and L_loc_type    = 'D'
                           UNION
                          select s.store
                            from store    s,
                                 district d,
                                 region   r
                           where d.district    = s.district
                             and r.region      = d.region
                             and r.area        = TO_NUMBER(I_location)
                             and L_loc_type    = 'A'
                           UNION
                          select s.store
                            from store    s,
                                 district d
                           where d.district    = s.district
                             and d.region      = TO_NUMBER(I_location)
                             and L_loc_type    = 'R'
                           UNION
                          select location
                            from loc_list_detail
                           where loc_list      = TO_NUMBER(I_location)
                             and L_loc_type    = 'LLS'
                           UNION
                          select s.store
                            from store s,
                                 loc_traits_matrix ltm
                           where ltm.store     = s.store
                             and ltm.loc_trait = TO_NUMBER(I_location)
                             and L_loc_type    = 'L'
                           UNION
                          select distinct wh.physical_wh
                            from wh,
                                 loc_list_detail l
                           where (l.location        = wh.wh
                                  or wh.physical_wh = l.location)
                             and loc_list           = TO_NUMBER(I_location)
                             and L_loc_type    = 'LLW')
         and item              = I_item
         and origin_country_id = I_country
         and supplier          = I_supplier
         and loc_type          = L_loc_type_SW;

BEGIN
   if I_supplier  is NULL then
      L_null_parameter_name := 'supplier';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_country  is NULL then
      L_null_parameter_name := 'Origin_Country';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_item  is NULL then
      L_null_parameter_name := 'Item';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_change_type  is NULL then
      L_null_parameter_name := 'change_type';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_change_amount is NULL then
      L_null_parameter_name := 'change_amount';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_loc_type is NULL then
      L_null_parameter_name := 'loc_type';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_location is NULL and
      I_loc_type NOT IN ('AL','AS','AW') then
         L_null_parameter_name := 'Location';
         raise NULL_PARAMETER;
   end if;
   ---


   if I_loc_type = 'AL' then
      NULL;
   elsif I_loc_type in ('AS','S') then
      L_loc_type_SW := 'S';
   elsif I_loc_type in ('AW','W','LLW') then
      L_loc_type    := I_loc_type;
      L_loc_type_SW := 'W';
   elsif I_loc_type in ('C','D','A','R','LLS','L') then
      L_loc_type    := I_loc_type;
      L_loc_type_SW := 'S';
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_LOC_TYPE',NULL,NULL,NULL);
         return FALSE;
   end if;
   ---
   if I_change_type = 'P' and I_change_amount < -100 then
      raise NEGATIVE_AMOUNT;
   end if;
   ---
   If I_change_type = 'F' and I_change_amount < 0 then
      raise NEGATIVE_AMOUNT;
   end if;
   ---

   if I_loc_type = 'AL' then                     -- for ALL locations
      FOR rec in C_PROCESS_COST_CHANGE_LOC_AL LOOP
         L_unit_cost_old       := rec.unit_cost_old;
         L_unit_cost_cuom_old  := rec.unit_cost_cuom_old;

         if I_change_type = 'P' then
            L_unit_cost_cuom_new := L_unit_cost_cuom_old * (1 + I_change_amount/100);
         elsif I_change_type = 'A' then
            L_unit_cost_cuom_new := L_unit_cost_cuom_old + I_change_amount;
         elsif I_change_type = 'F' then
            L_unit_cost_cuom_new := I_change_amount;
         end if;

         if (L_unit_cost_cuom_new < 0) then
            raise NEGATIVE_AMOUNT;
         end if;

         L_unit_cost_new  := L_unit_cost_cuom_new;

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               L_unit_cost_new,
                                               I_item,
                                               I_supplier,
                                               I_country,
                                               'C') = FALSE then
             return FALSE;
         end if;

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_COST_CHANGE_LOC_AL',
                          L_table,
                          'unit_cost_cuom_new');
         open  C_LOCK_COST_CHANGE_LOC_AL;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_COST_CHANGE_LOC_AL',
                          L_table,
                          'unit_cost_cuom_new');
         close C_LOCK_COST_CHANGE_LOC_AL;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          L_table,
                          'Item:'||I_item||'Supplier:'||I_supplier||'Location:'||rec.location||'Loc_type:'||rec.loc_type);



         update cost_change_loc_temp
            set unit_cost_new      = L_unit_cost_new,
                unit_cost_cuom_new = L_unit_cost_cuom_new,
                cost_change_type   = I_change_type,
                cost_change_value  = I_change_amount
          where item               = I_item
            and origin_country_id  = I_country
            and supplier           = I_supplier
            and location           = rec.location
            and loc_type           = rec.loc_type;

      end LOOP;
   elsif I_loc_type in ('AS','AW') then              -- ALL STORES or ALL WAREHOUSE
      FOR rec in C_PROCESS_COST_CHANGE_LOC_ASAW LOOP
         L_unit_cost_old       := rec.unit_cost_old;
         L_unit_cost_cuom_old  := rec.unit_cost_cuom_old;

         if I_change_type    = 'P' then
            L_unit_cost_cuom_new := L_unit_cost_cuom_old * (1 + I_change_amount/100);
         elsif I_change_type = 'A' then
            L_unit_cost_cuom_new := L_unit_cost_cuom_old + I_change_amount;
         elsif I_change_type = 'F' then
            L_unit_cost_cuom_new := I_change_amount;
         end if;

         if (L_unit_cost_cuom_new < 0) then
            raise NEGATIVE_AMOUNT;
         end if;

         L_unit_cost_new  := L_unit_cost_cuom_new;

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               L_unit_cost_new,
                                               I_item,
                                               I_supplier,
                                               I_country,
                                               'C') = FALSE then
             return FALSE;
         end if;

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_COST_CHANGE_LOC_ASAW',
                          L_table,
                          'unit_cost_cuom_new');
         open  C_LOCK_COST_CHANGE_LOC_ASAW;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_COST_CHANGE_LOC_ASAW',
                          L_table,
                          'unit_cost_cuom_new');
         close C_LOCK_COST_CHANGE_LOC_ASAW;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          L_table,
                          'Item:'||I_item||'Supplier:'||I_supplier||'Location:'||rec.location||'Loc_type:'||L_loc_type_SW);



         update cost_change_loc_temp
            set unit_cost_new      = L_unit_cost_new,
                unit_cost_cuom_new = L_unit_cost_cuom_new,
                cost_change_type   = I_change_type,
                cost_change_value  = I_change_amount
          where item               = I_item
            and origin_country_id  = I_country
            and supplier           = I_supplier
            and location           = rec.location
            and loc_type           = L_loc_type_SW;

      end LOOP;
   elsif I_loc_type in ('S','W') then                    -- STORE or WAREHOUSE
      ---
      FOR rec in C_PROCESS_COST_CHANGE_LOC_SW LOOP
         L_unit_cost_old       := rec.unit_cost_old;
         L_unit_cost_cuom_old  := rec.unit_cost_cuom_old;

         if I_change_type    = 'P' then
            L_unit_cost_cuom_new := L_unit_cost_cuom_old * (1 + I_change_amount/100);
         elsif I_change_type = 'A' then
            L_unit_cost_cuom_new := L_unit_cost_cuom_old + I_change_amount;
         elsif I_change_type = 'F' then
            L_unit_cost_cuom_new := I_change_amount;
         end if;

         if (L_unit_cost_cuom_new < 0) then
            raise NEGATIVE_AMOUNT;
         end if;

         L_unit_cost_new  := L_unit_cost_cuom_new;

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               L_unit_cost_new,
                                               I_item,
                                               I_supplier,
                                               I_country,
                                               'C') = FALSE then
             return FALSE;
         end if;

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_COST_CHANGE_LOC_SW',
                          L_table,
                          'unit_cost_cuom_new');
         open  C_LOCK_COST_CHANGE_LOC_SW;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_COST_CHANGE_LOC_SW',
                          L_table,
                          'unit_cost_cuom_new');
         close C_LOCK_COST_CHANGE_LOC_SW;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          L_table,
                          'Item:'||I_item||'Supplier:'||I_supplier||'Location:'||I_location||'Loc_type:'||L_loc_type_SW);



         update cost_change_loc_temp
            set unit_cost_new      = L_unit_cost_new,
                unit_cost_cuom_new = L_unit_cost_cuom_new,
                cost_change_type   = I_change_type,
                cost_change_value  = I_change_amount
          where item               = I_item
            and origin_country_id  = I_country
            and supplier           = I_supplier
            and location           = TO_NUMBER(I_location)
            and loc_type           = L_loc_type_SW;

      end LOOP;
      ---
   elsif I_loc_type in ('C','D','A','R','LLS','LLW','L') then
      ---
      FOR rec in C_PROCESS_COST_CHANGE_LOC LOOP
         L_unit_cost_old       := rec.unit_cost_old;
         L_unit_cost_cuom_old  := rec.unit_cost_cuom_old;

         if I_change_type    = 'P' then
            L_unit_cost_cuom_new := L_unit_cost_cuom_old * (1 + I_change_amount/100);
         elsif I_change_type = 'A' then
            L_unit_cost_cuom_new := L_unit_cost_cuom_old + I_change_amount;
         elsif I_change_type = 'F' then
            L_unit_cost_cuom_new := I_change_amount;
         end if;

         if (L_unit_cost_cuom_new < 0) then
            raise NEGATIVE_AMOUNT;
         end if;

         L_unit_cost_new  := L_unit_cost_cuom_new;

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               L_unit_cost_new,
                                               I_item,
                                               I_supplier,
                                               I_country,
                                               'C') = FALSE then
             return FALSE;
         end if;

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_COST_CHANGE_LOC',
                          L_table,
                          'unit_cost_cuom_new');
         open  C_LOCK_COST_CHANGE_LOC;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_COST_CHANGE_LOC',
                          L_table,
                          'unit_cost_cuom_new');
         close C_LOCK_COST_CHANGE_LOC;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          L_table,
                          'Item:'||I_item||'Supplier:'||I_supplier||'Location:'||rec.location||'Loc_type:'||L_loc_type_SW);



         update cost_change_loc_temp
            set unit_cost_new      = L_unit_cost_new,
                unit_cost_cuom_new = L_unit_cost_cuom_new,
                cost_change_type   = I_change_type,
                cost_change_value  = I_change_amount
          where item               = I_item
            and origin_country_id  = I_country
            and supplier           = I_supplier
            and location           = rec.location
            and loc_type           = L_loc_type_SW;

      end LOOP;
      ---
   end if;

   ---
   return TRUE;
   ---
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             'APPLY_CHANGE_LOC',
                                             NULL);
      return FALSE;

   when NEGATIVE_AMOUNT then
      O_error_message := SQL_LIB.CREATE_MSG('U/P_COST_NOT_NEG',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_supplier) || ', ' || I_country,
                                            I_item);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'APPLY_CHANGE_LOC',
                                             to_char(SQLCODE));
      return FALSE;
END APPLY_CHANGE_LOC;
------------------------------------------------------------------------------------------
FUNCTION WH_BRACKET_EXISTS
         (O_error_message  IN OUT VARCHAR2,
          O_exists         IN OUT BOOLEAN,
          I_item           IN     COST_SUSP_SUP_DETAIL_LOC.ITEM%TYPE,
          I_supplier       IN     COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE,
          I_origin_country IN     COST_SUSP_SUP_DETAIL_LOC.ORIGIN_COUNTRY_ID%TYPE,
          I_warehouse      IN     COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE,
          I_bracket_value  IN     COST_SUSP_SUP_DETAIL_LOC.BRACKET_VALUE1%TYPE)
   RETURN BOOLEAN IS
   ---
   L_null_parameter_name  VARCHAR2(30);
   L_exists               VARCHAR2(1) := 'N';
   ---
   NULL_PARAMETER         EXCEPTION;
   ---
   cursor C_WH_BRACKET_EXISTS is
      select 'Y'
        from cost_change_loc_temp
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country
         and location          = I_warehouse
         and bracket_value1    = I_bracket_value;
   ---
BEGIN
   if I_item is NULL then
      L_null_parameter_name := 'Item';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_supplier is NULL then
      L_null_parameter_name := 'Supplier';
      raise NULL_PARAMETER;
   end if;
   if I_origin_country is NULL then
      L_null_parameter_name := 'Origin Country';
      raise NULL_PARAMETER;
   end if;
   if I_warehouse is NULL then
      L_null_parameter_name := 'Warehouse';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_bracket_value is NULL then
      L_null_parameter_name := 'Bracket Value';
      raise NULL_PARAMETER;
   end if;
   ---

   SQL_LIB.SET_MARK('OPEN','C_WH_BRACKET_EXISTS','SUP_BRACKET_COST',
                    'Warehouse: '||to_char(I_warehouse)||
                    '  Bracket Value: '|| to_char(I_bracket_value));
   ---
   open C_WH_BRACKET_EXISTS;
   ---
   SQL_LIB.SET_MARK('FETCH','C_WH_BRACKET_EXISTS','SUP_BRACKET_COST',
                    'Warehouse: '||to_char(I_warehouse)||
                    '  Bracket Value: '|| to_char(I_bracket_value));
   fetch C_WH_BRACKET_EXISTS into L_exists;
   ---
   if C_WH_BRACKET_EXISTS%NOTFOUND then
      L_exists := 'N';
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_WH_BRACKET_EXISTS','SUP_BRACKET_COST',
                    'Warehouse: '||to_char(I_warehouse)||
                    '  Bracket Value: '|| to_char(I_bracket_value));
   close C_WH_BRACKET_EXISTS;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             'WH_BRACKET_EXISTS',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'WH_BRACKET_EXISTS',
                                             to_char(SQLCODE));
      return FALSE;
END WH_BRACKET_EXISTS;
------------------------------------------------------------------------------------------
FUNCTION UPDATE_CC_DETAIL_TEMP (O_error_message  IN OUT VARCHAR2,
                                I_item           IN     ITEM_MASTER.ITEM%TYPE,
                                I_supplier       IN     SUPS.SUPPLIER%TYPE,
                                I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS
   L_null_parameter_name  VARCHAR2(30);
   L_exists               VARCHAR2(1) := 'N';
   ---
   NULL_PARAMETER         EXCEPTION;
   ---
   cursor C_COST_CHANGE_LOC_TEMP_EXISTS is
      select 'Y'
      from cost_change_loc_temp
      where unit_cost_new is not NULL
        and origin_country_id = I_origin_country
        and supplier          = I_supplier
        and item              = I_item;
   ---
BEGIN
   if I_item is NULL then
      L_null_parameter_name := 'Item';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_supplier is NULL then
      L_null_parameter_name := 'Supplier';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_origin_country is NULL then
      L_null_parameter_name := 'Origin_country_Id';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_COST_CHANGE_LOC_TEMP_EXISTS',
                    'COST_CHANGE_LOC_TEMP',
                    'Item: '||I_Item||
                    '  Supplier: '|| to_char(I_supplier)||
                    '  Origin Country: '||I_origin_country);
   ---
   open C_COST_CHANGE_LOC_TEMP_EXISTS;
   --
   SQL_LIB.SET_MARK('OPEN','C_COST_CHANGE_LOC_TEMP_EXISTS',
                    'COST_CHANGE_LOC_TEMP',
                    'Item: '||I_Item||
                    '  Supplier: '|| to_char(I_supplier)||
                    '  Origin Country: '||I_origin_country);
   ---
   fetch C_COST_CHANGE_LOC_TEMP_EXISTS into L_exists;
   ---
   if C_COST_CHANGE_LOC_TEMP_EXISTS%NOTFOUND then
      L_exists := 'N';
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_COST_CHANGE_LOC_TEMP_EXISTS', 'COST_CHANGE_LOC_TEMP',
                    'Item: '||I_Item||' Supplier: '|| to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country);
   ---
   close C_COST_CHANGE_LOC_TEMP_EXISTS;
   ---
   SQL_LIB.SET_MARK('UPDATE', 'COST_CHANGE_TEMP', 'UPDATE_CC_DETAIL_TEMP',
                    'Item: '||I_Item||' Supplier: '|| to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country);
   ---
   update cost_change_temp
      set unit_cost_new      = decode(L_exists, 'Y', NULL, unit_cost_new),
          unit_cost_cuom_new = decode(L_exists, 'Y', NULL, unit_cost_cuom_new),
          loc_level_ind = L_exists
      where origin_country_id = I_origin_country
        and supplier          = I_supplier
        and item              = I_item;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             'UPDATE_CC_DETAIL_TEMP',
                                             NULL);
      return FALSE;
  when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'POP_TEMP_DETAIL_LOC',
                                             to_char(SQLCODE));
      return FALSE;
END UPDATE_CC_DETAIL_TEMP;
------------------------------------------------------------------------------------------
FUNCTION INSERT_UPDATE_COST_CHANGE
       (O_error_message  IN OUT VARCHAR2,
        I_cost_change    IN     COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;

   cursor C_LOCS_EXIST is
      select distinct
             c.item,
             c.supplier,
             c.origin_country_id
        from cost_change_temp c
       where c.cost_change = I_cost_change
         and exists (select 'X'
                       from cost_change_loc_temp l
                      where l.origin_country_id = c.origin_country_id
                        and l.supplier          = c.supplier
                        and l.item              = c.item
                        and l.cost_change       = c.cost_change);

BEGIN
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCS_EXIST',
                    'COST_CHANGE_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   --- Only delete from permanent table, cost_susp_sup_detail_loc, records
   --- for an item/supplier/country that are also in the temporary location table
   --- updated in suppsku.
   FOR current_rec IN C_LOCS_EXIST LOOP
       SQL_LIB.SET_MARK('DELETE', NULL, 'COST_SUSP_SUP_DETAIL_LOC',
                        'Cost Change: '||to_char(I_cost_change));
       delete cost_susp_sup_detail_loc cl
        where cl.item              = current_rec.item
          and cl.supplier          = current_rec.supplier
          and cl.origin_country_id = current_rec.origin_country_id
          and cost_change          = I_cost_change;
   END LOOP;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_LOCS_EXIST',
                    'COST_CHANGE_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   SQL_LIB.SET_MARK('DELETE', NULL, 'COST_SUSP_SUP_DETAIL',
                    'Cost Change: '||to_char(I_cost_change));
   ---
   delete cost_susp_sup_detail
    where cost_change = I_cost_change;
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'COST_SUSP_SUP_DETAIL', NULL);
   ---
   insert into cost_susp_sup_detail (cost_change,
                                     supplier,
                                     origin_country_id,
                                     item,
                                     bracket_value1,
                                     bracket_uom1,
                                     bracket_value2,
                                     unit_cost,
                                     cost_change_type,
                                     cost_change_value,
                                     default_bracket_ind,
                                     recalc_ord_ind,
                                     dept,
                                     sup_dept_seq_no)
   select distinct cost_change,
                   supplier,
                   origin_country_id,
                   item,
                   bracket_value1,
                   bracket_uom,
                   bracket_value2,
                   unit_cost_new,
                   cost_change_type,
                   cost_change_value,
                   NVL(default_bracket_ind,'N'),
                   recalc_ord_ind,
                   dept,
                   sup_dept_seq_no
              from cost_change_temp
             where unit_cost_new is NOT NULL
               and cost_change = I_cost_change;
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP', NULL);
   ---
   --- For warehouses
   insert into cost_susp_sup_detail_loc (cost_change,
                                         supplier,
                                         origin_country_id,
                                         item,
                                         loc_type,
                                         loc,
                                         bracket_value1,
                                         bracket_uom1,
                                         bracket_value2,
                                         unit_cost,
                                         cost_change_type,
                                         cost_change_value,
                                         default_bracket_ind,
                                         recalc_ord_ind,
                                         dept,
                                         sup_dept_seq_no)
                         select distinct cc.cost_change,
                                         cc.supplier,
                                         cc.origin_country_id,
                                         cc.item,
                                         cc.loc_type,
                                         iscl.loc,
                                         cc.bracket_value1,
                                         cc.bracket_uom,
                                         cc.bracket_value2,
                                         cc.unit_cost_new,
                                         cost_change_type,
                                         cost_change_value,
                                         NVL(cc.default_bracket_ind,'N'),
                                         cc.recalc_ord_ind,
                                         cc.dept,
                                         cc.sup_dept_seq_no
                                    from cost_change_loc_temp cc,
                                         item_supp_country_loc iscl,
                                         wh
                                   where cc.item              = iscl.item
                                     and cc.supplier          = iscl.supplier
                                     and cc.origin_country_id = iscl.origin_country_id
                                     and cc.location        = wh.physical_wh
                                     and iscl.loc             = wh.wh
                                     and cc.loc_type = 'W'
                                     and cc.unit_cost_new is NOT NULL
                                     and cc.cost_change       = I_cost_change;
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP', NULL);
   ---
   -- for stores
   insert into cost_susp_sup_detail_loc (cost_change,
                                        supplier,
                                        origin_country_id,
                                        item,
                                        loc_type,
                                        loc,
                                        bracket_value1,
                                        bracket_uom1,
                                        unit_cost,
                                        cost_change_type,
                                        cost_change_value,
                                        default_bracket_ind,
                                        recalc_ord_ind,
                                        dept )
                        select distinct cost_change,
                                        supplier,
                                        origin_country_id,
                                        item,
                                        loc_type,
                                        location,
                                        bracket_value1,
                                        bracket_uom,
                                        unit_cost_new,
                                        cost_change_type,
                                        cost_change_value,
                                        NVL(default_bracket_ind,'N'),
                                        recalc_ord_ind,
                                        dept
                                   from cost_change_loc_temp cc
                                  where cc.loc_type = 'S'
                                    and cc.unit_cost_new is NOT NULL
                                    and cc.cost_change       = I_cost_change;


   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             'INSERT_UPDATE_COST_CHANGE',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INSERT_UPDATE_COST_CHANGE',
                                             to_char(SQLCODE));
      return FALSE;
END INSERT_UPDATE_COST_CHANGE;
------------------------------------------------------------------------------------------
FUNCTION DELETE_COST_CHANGE_TEMP
       (O_error_message  IN OUT VARCHAR2,
        I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
BEGIN
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL, 'COST_CHANGE_TEMP',
                    'Cost Change: '||to_char(I_cost_change));
   ---
   delete cost_change_temp
    where cost_change = I_cost_change;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             'DELETE_COST_CHANGE_TEMP',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'DELETE_COST_CHANGE_TEMP',
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_COST_CHANGE_TEMP;
------------------------------------------------------------------------------------------
FUNCTION DELETE_COST_CHANGE_LOC_TEMP
                  (O_error_message  IN OUT VARCHAR2,
                   I_cost_change    IN     COST_CHANGE_LOC_TEMP.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
BEGIN
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL, 'COST_CHANGE_LOC_TEMP',
                    'Cost Change: '||to_char(I_cost_change));
   ---
   delete cost_change_loc_temp
    where cost_change       = I_cost_change;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             'DELETE_COST_CHANGE_LOC_TEMP',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'DELETE_COST_CHANGE_LOC_TEMP',
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_COST_CHANGE_LOC_TEMP;
--------------------------------------------------------------------------------------
FUNCTION CHECK_COST_CONFLICTS (O_error_message  IN OUT VARCHAR2,
                               O_conflicts      IN OUT BOOLEAN,
                               I_cost_change    IN     COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                               I_active_date    IN     COST_SUSP_SUP_HEAD.ACTIVE_DATE%TYPE)
   RETURN BOOLEAN IS
   L_item                 COST_SUSP_SUP_DETAIL.ITEM%TYPE;
   L_supplier             COST_SUSP_SUP_DETAIL.SUPPLIER%TYPE;
   L_loc                  COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE;
   L_origin_country_id    COST_SUSP_SUP_DETAIL.ORIGIN_COUNTRY_ID%TYPE;
   L_dummy                VARCHAR2(1) := 'N';
   L_null_parameter_name  VARCHAR2(30);
   NULL_PARAMETER         EXCEPTION;
   ---

   cursor C_GET_CURRENT_COST is
      select item,
             supplier,
             to_number(NULL) loc,
             origin_country_id
        from cost_susp_sup_detail
       where cost_change = I_cost_change
       UNION
      select item,
             supplier,
             loc,
             origin_country_id
        from cost_susp_sup_detail_loc
       where cost_change = I_cost_change;

-- The cursor C_COST_CONFLICTS is checking the following 4 scenarios:
-- 1) A cost_susp_sup_detail record exists and a duplicate detail
-- record is being created. 2) A cost_susp_sup_detail_loc record exists and
-- a duplicate location record is being created. 3) A detail record exists
-- (detail records are for all locations) and a location record being created.
-- 4) A location record exists and a detail record is being created.

-- Reason codes 1-3 are reserved for cost changes created due to changes
-- to the bracket structure when bracket costing is used.  These should
-- not cause the conflict checking to fail.

   cursor C_COST_CONFLICTS is
      select
         'Y'
        from item_master im,
             cost_susp_sup_detail cd,
             cost_susp_sup_head ch
       where ch.cost_change = cd.cost_change
         and (im.item = L_item and cd.item = im.item)
         and ch.active_date = I_active_date
         and cd.supplier    = L_supplier
         and cd.origin_country_id = L_origin_country_id
         and ch.status in ('S','A','E')
         and ch.cost_change != I_cost_change
         and ch.reason > 3
         and rownum = 1
      UNION ALL
      select
        'Y'
        from item_master im,
             cost_susp_sup_detail cd,
             cost_susp_sup_head ch
       where ch.cost_change = cd.cost_change
         and (( cd.item = im.item_parent or
                 cd.item = im.item_grandparent )
             and im.item = L_item )
         and ch.active_date = I_active_date
         and cd.supplier    = L_supplier
         and cd.origin_country_id = L_origin_country_id
         and ch.status in ('S','A','E')
         and ch.cost_change != I_cost_change
         and ch.reason > 3
         and rownum = 1
      UNION ALL
      select
         'Y'
        from item_master im,
             cost_susp_sup_detail cd,
             cost_susp_sup_head ch
       where ch.cost_change = cd.cost_change
         and ((im.item_parent = L_item or
               im.item_grandparent = L_item )
              and cd.item = im.item )
         and ch.active_date = I_active_date
         and cd.supplier    = L_supplier
         and cd.origin_country_id = L_origin_country_id
         and ch.status in ('S','A','E')
         and ch.cost_change != I_cost_change
         and ch.reason > 3
         and rownum = 1
      UNION ALL
      select
          'Y'
        from item_master im,
             cost_susp_sup_detail_loc cdl,
             cost_susp_sup_head ch
       where ch.cost_change = cdl.cost_change
         and (im.item = L_item and cdl.item = im.item)
         and ch.active_date = I_active_date
         and cdl.supplier   = L_supplier
         and cdl.origin_country_id = L_origin_country_id
         and ch.status in ('S','A','E')
         and ch.cost_change != I_cost_change
         and ch.reason > 3
         and (cdl.loc = L_loc
              or L_loc is NULL)
         and rownum = 1
      UNION ALL
      select
          'Y'
        from item_master im,
             cost_susp_sup_detail_loc cdl,
             cost_susp_sup_head ch
       where ch.cost_change = cdl.cost_change
         and (( cdl.item = im.item_parent or
                cdl.item = im.item_grandparent )
              and  im.item = L_item)
         and ch.active_date = I_active_date
         and cdl.supplier   = L_supplier
         and cdl.origin_country_id = L_origin_country_id
         and ch.status in ('S','A','E')
         and ch.cost_change != I_cost_change
         and ch.reason > 3
         and (cdl.loc = L_loc
              or L_loc is NULL)
         and rownum = 1
      UNION ALL
      select
          'Y'
        from item_master im,
             cost_susp_sup_detail_loc cdl,
             cost_susp_sup_head ch
       where ch.cost_change = cdl.cost_change
         and ((im.item_parent = L_item or
               im.item_grandparent = L_item )
              and   cdl.item = im.item)
         and ch.active_date = I_active_date
         and cdl.supplier   = L_supplier
         and cdl.origin_country_id = L_origin_country_id
         and ch.status in ('S','A','E')
         and ch.cost_change != I_cost_change
         and ch.reason > 3
         and (cdl.loc = L_loc
              or L_loc is NULL)
         and rownum = 1;

BEGIN
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   elsif I_active_date is NULL then
      L_null_parameter_name := 'active_date';
      raise NULL_PARAMETER;
   end if;

   --Check for cost change conflicts
   FOR rec_current_cost IN C_GET_CURRENT_COST LOOP
      L_item     := rec_current_cost.item;
      L_supplier := rec_current_cost.supplier;
      L_loc      := rec_current_cost.loc;
      L_origin_country_id := rec_current_cost.origin_country_id;

      SQL_LIB.SET_MARK('OPEN',
                       'C_COST_CONFLICTS',
                       'COST_SUSP_SUP_DETAIL',
                       'COST_CHANGE:  '|| TO_CHAR(I_cost_change)||
                       ',ACTIVE_DATE: '|| TO_CHAR(I_active_date));
      open C_COST_CONFLICTS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_COST_CONFLICTS',
                       'COST_SUSP_SUP_DETAIL',
                       'COST_CHANGE:  '|| TO_CHAR(I_cost_change)||
                       ',ACTIVE_DATE: '|| TO_CHAR(I_active_date));
      fetch C_COST_CONFLICTS into L_dummy;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_COST_CONFLICTS',
                       'COST_SUSP_SUP_DETAIL',
                       'COST_CHANGE:  '|| TO_CHAR(I_cost_change)||
                       ',ACTIVE_DATE: '|| TO_CHAR(I_active_date));
      close C_COST_CONFLICTS;
      ---
      O_conflicts := (L_dummy = 'Y');

      if O_conflicts then
          return TRUE;
      end if;

   END LOOP;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                            'COST_CHANGE_SQL.CHECK_COST_CONFLICTS',
                                             NULL);

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                             SQLERRM,
                                            'COST_CHANGE_SQL.CHECK_COST_CONFLICTS',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_COST_CONFLICTS;
--------------------------------------------------------------------------------------
FUNCTION VALIDATE_COSTS(O_error_message  IN OUT VARCHAR2,
                        O_valid          IN OUT BOOLEAN,
                        I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE,
                        I_level          IN     VARCHAR2)
   RETURN BOOLEAN IS
   ---
   L_program              VARCHAR2(60) := 'COST_CHANGE_SQL.VALIDATE_COSTS';
   L_dummy                VARCHAR2(1) := 'N';
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
   ---
   cursor C_COUNTRY_COSTS is
      select 'Y'
        from cost_change_temp
       where unit_cost_new <= 0
         and cost_change    = I_cost_change;

   cursor C_LOC_COSTS is
      select 'Y'
        from cost_change_loc_temp
       where unit_cost_new <= 0
         and cost_change    = I_cost_change;

BEGIN
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_level = 'C' then
      SQL_LIB.SET_MARK('OPEN','C_COUNTRY_COSTS',
                       'COST_CHANGE_TEMP', 'Cost Change: '|| to_char(I_cost_change));
      open C_COUNTRY_COSTS;
      SQL_LIB.SET_MARK('FETCH','C_COUNTRY_COSTS',
                       'COST_CHANGE_TEMP', 'Cost Change: '|| to_char(I_cost_change));
      fetch C_COUNTRY_COSTS into L_dummy;
      if C_COUNTRY_COSTS%FOUND then
         O_valid := FALSE;
      else
         O_valid := TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_COUNTRY_COSTS',
                       'COST_CHANGE_TEMP', 'Cost Change: '|| to_char(I_cost_change));
      close C_COUNTRY_COSTS;
   elsif I_level = 'L' then
      SQL_LIB.SET_MARK('OPEN','C_LOC_COSTS',
                       'COST_CHANGE_LOC_TEMP', 'Cost Change: '|| to_char(I_cost_change));
      open C_LOC_COSTS;
      SQL_LIB.SET_MARK('FETCH','C_LOC_COSTS',
                       'COST_CHANGE_LOC_TEMP', 'Cost Change: '|| to_char(I_cost_change));
      fetch C_LOC_COSTS into L_dummy;
      if C_LOC_COSTS%FOUND then
         O_valid := FALSE;
      else
         O_valid := TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_LOC_COSTS',
                       'COST_CHANGE_LOC_TEMP', 'Cost Change: '|| to_char(I_cost_change));
      close C_LOC_COSTS;
   end if;
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             L_program,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALIDATE_COSTS;
--------------------------------------------------------------------------------------
--Mod By:      Nitin Kumar
--Mod Date:    29-Apr-2009
--Mod Ref:     NBS00012501/503
--Mod Details: Modified the functions POP_FOR_ITEMLIST to include the cost changes only for simple
--             pack.Complex packs cant go under the cost change as Mod N53 restricts the user to do
--             the cost change for Complex Packs.
-----------------------------------------------------------------------------------------------------
FUNCTION POP_FOR_ITEMLIST(O_error_message  IN OUT VARCHAR2,
                          O_exists         IN OUT BOOLEAN,
                          I_mode           IN     VARCHAR2,
                          I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE,
                          I_supplier       IN     SUPS.SUPPLIER%TYPE,
                          I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE,
                          I_itemlist       IN     SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN IS

   L_program        VARCHAR2(60) := 'COST_CHANGE_SQL.POP_FOR_ITEMLIST';
   L_exists         BOOLEAN;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
   L_apply_rp_link  SYSTEM_OPTIONS.TSL_APPLY_RP_LINK%TYPE := NULL;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
   -- 08-May-08 Bahubali D Mod N111 Begin
   L_system_options_row  SYSTEM_OPTIONS%ROWTYPE;
   L_apply_common_prd    SYSTEM_OPTIONS.TSL_COMMON_PRODUCT_IND%TYPE;
   L_origin_country      SYSTEM_OPTIONS.TSL_ORIGIN_COUNTRY%TYPE;
   -- 08-May-08 Bahubali D Mod N111 End

   cursor C_EXPLODE_ITEMLIST is
       select sd.item
         from skulist_detail sd,
              item_master im,
              item_supp_country isc,
              -- 08-May-08 Bahubali D Mod N111 Begin
              item_supplier isp
              -- 08-May-08 Bahubali D Mod N111 End
        where sd.skulist            = I_itemlist
          and sd.item               = im.item
          and im.item               = isc.item
          and isc.supplier          = I_supplier
          and isc.origin_country_id = NVL(I_origin_country, isc.origin_country_id)
          and im.status             = 'A'
          -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
          -- and (im.pack_ind          = 'N'
          -- or  (im.pack_ind          = 'Y' and im.pack_type = 'V'))
          and (im.simple_pack_ind      = 'Y' and im.pack_type = 'V')
          -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End
          -- 08-May-08 Bahubali D Mod N111 Begin
          and im.item               = isp.item
          and isp.supplier          = isc.supplier
          and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                    where im.tsl_common_ind        = 'Y'
                                      and im.tsl_primary_country  != L_origin_country
                                      and im.tsl_primary_country is NOT NULL
                                      and tcsm.channel_id in ('1Y','2Y','3Y')
                                      and L_apply_common_prd = 'Y'
                                      and im.item = tcsm.item
                                      and isp.supplier = tcsm.target_supplier)
          -- 08-May-08 Bahubali D Mod N111 End
          -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
          and NOT (im.pack_ind                   = 'Y'
                   and im.pack_type              = 'V'
                   and im.orderable_ind          = 'Y'
                   and im.tsl_mu_ind             = 'N'
                   and im.simple_pack_ind        = 'N'
                   and NVL(L_apply_rp_link, 'N') = 'Y')
          -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
     order by sd.item_level;

BEGIN
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
   -- The below function call the removed by Mod N111
   --if SYSTEM_OPTIONS_SQL.TSL_GET_APPLY_RP_LINK(O_error_message,
   --                                            L_apply_rp_link) = FALSE then
   --   return FALSE;
   --end if;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End

   -- 08-May-08 Bahubali D Mod N111 Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS (O_error_message,
                                             L_system_options_row) = FALSE then
      return FALSE;
   end if;
   ---
   L_apply_rp_link    := L_system_options_row.tsl_apply_rp_link;
   L_apply_common_prd := L_system_options_row.tsl_common_product_ind;
   L_origin_country   := L_system_options_row.tsl_origin_country;
   ---

   -- 08-May-08 Bahubali D Mod N111 End
   FOR itemlist in C_EXPLODE_ITEMLIST LOOP
      if not POP_TEMP_DETAIL(O_error_message,
                             L_exists,
                             I_mode,
                             I_cost_change,
                             I_supplier,
                             I_origin_country,
                             itemlist.item) then
         return FALSE;
      end if;
      if L_exists = FALSE then
         O_exists := FALSE;
      else
         O_exists := TRUE;
      end if;
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
END POP_FOR_ITEMLIST;
-------------------------------------------------------------------------------------
FUNCTION CC_TEMP_LOCS_EXIST (O_error_message  IN OUT VARCHAR2,
                             O_exist          IN OUT BOOLEAN,
                             I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE,
                             I_item           IN     ITEM_MASTER.ITEM%TYPE,
                             I_supplier       IN     SUPS.SUPPLIER%TYPE,
                             I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE)

   RETURN BOOLEAN IS
   ---
   L_program              VARCHAR2(61) := 'COST_CHANGE_SQL.CC_TEMP_LOCS_EXIST';
   L_locs_exist           VARCHAR2(1) := 'N';
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
   ---

   cursor C_LOCS_EXIST is
      select 'Y'
        from cost_change_loc_temp
       where origin_country_id = NVL(I_origin_country, origin_country_id)
         and supplier          = NVL(I_supplier,supplier)
         and item              = NVL(I_item,item)
         and cost_change       = I_cost_change;

BEGIN
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCS_EXIST',
                    'COST_CHANGE_LOC_TEMP',
                    'Item: '||I_Item||
                    '  Supplier: '|| to_char(I_supplier)||
                    '  Cost Change: '|| to_char(I_cost_change));
   ---
   open C_LOCS_EXIST;
   --
   SQL_LIB.SET_MARK('FETCH','C_LOCS_EXIST',
                    'COST_CHANGE_LOC_TEMP',
                    'Item: '||I_Item||
                    '  Supplier: '|| to_char(I_supplier)||
                    '  Cost Change: '|| to_char(I_cost_change));
   ---
   fetch C_LOCS_EXIST into L_locs_exist ;
   if C_LOCS_EXIST%FOUND then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if ;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_LOCS_EXIST', 'COST_CHANGE_LOC_TEMP',
                    'Item: '||I_Item||' Supplier: '|| to_char(I_supplier)||
                    '  Cost Change: '|| to_char(I_cost_change));
   ---
   close C_LOCS_EXIST;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             L_program,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CC_TEMP_LOCS_EXIST;
-------------------------------------------------------------------------------------
FUNCTION CC_SUPPLIER (O_error_message  IN OUT VARCHAR2,
                      O_supplier       IN OUT SUPS.SUPPLIER%TYPE,
                      I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE)

   RETURN BOOLEAN IS
   ---
   L_program              VARCHAR2(61) := 'COST_CHANGE_SQL.CC_SUPPLIER';
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
   ---
   cursor C_SUPPLIER is
      select supplier
        from cost_susp_sup_detail
       where cost_susp_sup_detail.cost_change = I_cost_change
       union
      select supplier
        from cost_susp_sup_detail_loc
       where cost_susp_sup_detail_loc.cost_change = I_cost_change;
BEGIN
   ---
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_SUPPLIER',
                    'COST_CHANGE_TEMP,COST_CHANGE_LOC_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   open C_SUPPLIER;
   --
   SQL_LIB.SET_MARK('FETCH','C_SUPPLIER',
                    'COST_CHANGE_TEMP,COST_CHANGE_LOC_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   fetch C_SUPPLIER into O_supplier ;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_SUPPLIER',
                    'COST_CHANGE_TEMP,COST_CHANGE_LOC_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   close C_SUPPLIER;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             L_program,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CC_SUPPLIER;
-------------------------------------------------------------------------------------
FUNCTION CC_ITEM (O_error_message  IN OUT VARCHAR2,
                  O_item           IN OUT ITEM_MASTER.ITEM%TYPE,
                  I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE)

   RETURN BOOLEAN IS
   ---
   L_program              VARCHAR2(61) := 'COST_CHANGE_SQL.CC_ITEM';
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
   ---
   cursor C_ITEM is
      select item
        from cost_susp_sup_detail c
       where c.cost_change = I_cost_change
       union
      select item
        from cost_susp_sup_detail_loc cl
       where cl.cost_change = I_cost_change;

BEGIN
   ---
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ITEM',
                    'COST_CHANGE_TEMP,COST_CHANGE_LOC_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   open C_ITEM;
   --
   SQL_LIB.SET_MARK('FETCH','C_ITEM',
                    'COST_CHANGE_TEMP,COST_CHANGE_LOC_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   fetch C_ITEM into O_item ;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_ITEM',
                    'COST_CHANGE_TEMP,COST_CHANGE_LOC_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   close C_ITEM;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             L_program,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CC_ITEM;
-------------------------------------------------------------------------------------
FUNCTION BC_UNIT_COST (O_error_message  IN OUT VARCHAR2,
                       O_unit_cost      IN OUT ITEM_LOC_SOH.UNIT_COST%TYPE,
                       I_supplier       IN     SUPS.SUPPLIER%TYPE,
                       I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE,
                       I_item           IN     ITEM_MASTER.ITEM%TYPE,
                       I_bracket        IN     ITEM_SUPP_COUNTRY_BRACKET_COST.BRACKET_VALUE1%TYPE,
                       I_location       IN     WH.PHYSICAL_WH%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program              VARCHAR2(61) := 'COST_CHANGE_SQL.BC_UNIT_COST';
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
   ---
   cursor C_UNIT_COST_NO_LOC is
      select unit_cost
        from item_supp_country_bracket_cost
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_origin_country
         and bracket_value1 = I_bracket
         and location is NULL;
   ---
   cursor C_UNIT_COST_LOC is
      select unit_cost
        from item_supp_country_bracket_cost iscbc,
             wh
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_origin_country
         and bracket_value1 = I_bracket
         and location = wh.wh
         and wh.physical_wh = I_location;
BEGIN
   ---
   if I_item is NULL then
      L_null_parameter_name := 'item';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_supplier is NULL then
      L_null_parameter_name := 'supplier';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_origin_country is NULL then
      L_null_parameter_name := 'country';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_bracket is NULL then
      L_null_parameter_name := 'bracket';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_location is NULL then
      SQL_LIB.SET_MARK('OPEN','C_UNIT_COST_NO_LOC ',
                       'COST_SUSP_SUP_DETAIL',
                       'Item: '||I_Item||
                       '  Supplier: '|| to_char(I_supplier)||
                       '  Bracket: '|| to_char(I_bracket));
      ---
      open C_UNIT_COST_NO_LOC ;
      ---
      SQL_LIB.SET_MARK('FETCH','C_UNIT_COST_NO_LOC ',
                       'COST_SUSP_SUP_DETAIL',
                       'Item: '||I_Item||
                       '  Supplier: '|| to_char(I_supplier)||
                       '  Bracket: '|| to_char(I_bracket));
      ---
      fetch C_UNIT_COST_NO_LOC into O_unit_cost ;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_UNIT_COST_NO_LOC ',
                       'COST_SUSP_SUP_DETAIL',
                       'Item: '||I_Item||
                       '  Supplier: '|| to_char(I_supplier)||
                       '  Bracket: '|| to_char(I_bracket));
      ---
      close C_UNIT_COST_NO_LOC ;
   else
      SQL_LIB.SET_MARK('OPEN','C_UNIT_COST_LOC ',
                       'COST_SUSP_SUP_DETAIL',
                       'Item: '||I_Item||
                       '  Supplier: '|| to_char(I_supplier)||
                       '  Bracket: '|| to_char(I_bracket));
      ---
      open C_UNIT_COST_LOC ;
      ---
      SQL_LIB.SET_MARK('FETCH','C_UNIT_COST_LOC ',
                       'COST_SUSP_SUP_DETAIL',
                       'Item: '||I_Item||
                       '  Supplier: '|| to_char(I_supplier)||
                       '  Bracket: '|| to_char(I_bracket));
      ---
      fetch C_UNIT_COST_LOC into O_unit_cost ;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_UNIT_COST_LOC ',
                       'COST_SUSP_SUP_DETAIL',
                       'Item: '||I_Item||
                       '  Supplier: '|| to_char(I_supplier)||
                       '  Bracket: '|| to_char(I_bracket));
      ---
      close C_UNIT_COST_LOC ;
   end if;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             L_program,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END BC_UNIT_COST;
-------------------------------------------------------------------------------------
FUNCTION COST_CHANGE_TEMP_EXISTS (O_error_message  IN OUT VARCHAR2,
                                  O_exist          IN OUT BOOLEAN,
                                  I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program              VARCHAR2(61) := 'COST_CHANGE_SQL.COST_CHANGE_TEMP_EXISTS';
   L_rec_exists           VARCHAR2(1) := 'N';
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
   ---
   cursor C_NEW_COST is
      select 'Y'
      from cost_change_temp
      where unit_cost_new is NOT NULL
        and cost_change = I_cost_change
      union all
      select 'Y'
      from cost_change_loc_temp
      where unit_cost_new is NOT NULL
        and cost_change = I_cost_change;
BEGIN
   ---
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_NEW_COST ',
                    'COST_CHANGE_TEMP,COST_CHANGE_LOC_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   open C_NEW_COST;
   --
   SQL_LIB.SET_MARK('FETCH','C_NEW_COST',
                    'COST_CHANGE_TEMP,COST_CHANGE_LOC_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   fetch C_NEW_COST into L_rec_exists;
   if C_NEW_COST%FOUND then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_NEW_COST',
                    'COST_CHANGE_TEMP,COST_CHANGE_LOC_TEMP',
                    'Cost Change: '|| to_char(I_cost_change));
   ---
   close C_NEW_COST;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             L_program,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END COST_CHANGE_TEMP_EXISTS;
------------------------------------------------------------------------------------------
FUNCTION DELETE_ALL_TEMP(O_error_message  IN OUT VARCHAR2,
                         I_cost_change    IN     COST_CHANGE_LOC_TEMP.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program              VARCHAR2(61) := 'COST_CHANGE_SQL.DELETE_ALL_TEMP';
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
BEGIN
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   if NOT COST_CHANGE_SQL.DELETE_COST_CHANGE_TEMP(O_error_message,
                                                  I_cost_change) then
      return FALSE;
   end if;
   ---
   if NOT COST_CHANGE_SQL.DELETE_COST_CHANGE_LOC_TEMP(O_error_message,
                                                      I_cost_change) then
      return FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             L_program,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_ALL_TEMP;
--------------------------------------------------------------------------------------
FUNCTION COST_CHANGE_LOCATIONS_EXISTS (O_error_message  IN OUT VARCHAR2,
                                       O_exist          IN OUT BOOLEAN,
                                       I_item           IN     ITEM_MASTER.ITEM%TYPE,
                                       I_supplier       IN     SUPS.SUPPLIER%TYPE,
                                       I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE,
                                       I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program              VARCHAR2(61) := 'COST_CHANGE_SQL.COST_CHANGE_LOCATIONS_EXISTS';
   L_rec_exists           VARCHAR2(1) := 'N';
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
   ---
   cursor C_EXIST is
      select 'Y'
        from cost_susp_sup_detail_loc
       where cost_change       = I_cost_change
         and item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country
      union all
      select 'Y'
        from cost_change_loc_temp
       where cost_change       = I_cost_change
         and item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country;
BEGIN
   ---
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_item is NULL then
      L_null_parameter_name := 'Item';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_supplier is NULL then
      L_null_parameter_name := 'Supplier';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_origin_country is NULL then
      L_null_parameter_name := 'Origin_country_Id';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_EXIST',
                    'COST_SUSP_SUP_DETAIL_LOC',
                    'Cost Change: '||to_char(I_cost_change)||
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item);
   ---
   open C_EXIST;
   --
   SQL_LIB.SET_MARK('FETCH','C_EXIST',
                    'COST_SUSP_SUP_DETAIL_LOC',
                    'Cost Change: '||to_char(I_cost_change)||
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item);

   ---
   fetch C_EXIST into L_rec_exists;
   if C_EXIST%FOUND then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_EXIST',
                    'COST_SUSP_SUP_DETAIL_LOC',
                    'Cost Change: '||to_char(I_cost_change)||
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item);
   ---
   close C_EXIST;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             L_program,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END COST_CHANGE_LOCATIONS_EXISTS;
------------------------------------------------------------------------------------------
FUNCTION UPDATE_RECALC_ORD_IND_AT_LOC(O_error_message  IN OUT VARCHAR2,
                                      I_item           IN     ITEM_MASTER.ITEM%TYPE,
                                      I_supplier       IN     SUPS.SUPPLIER%TYPE,
                                      I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE,
                                      I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE,
                                      I_recalc_ord_ind IN     COST_CHANGE_TEMP.RECALC_ORD_IND%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program              VARCHAR2(61) := 'COST_CHANGE_SQL.UPDATE_RECALC_ORD_IND_AT_LOC';
   L_rec_exists           VARCHAR2(1) := 'N';
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;
   ---
   cursor C_EXIST is
      select 'Y'
        from cost_susp_sup_detail_loc
       where cost_change       = I_cost_change
         and item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country;
BEGIN
   ---
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_item is NULL then
      L_null_parameter_name := 'Item';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_supplier is NULL then
      L_null_parameter_name := 'Supplier';
      raise NULL_PARAMETER;
   end if;
   ---
   if I_origin_country is NULL then
      L_null_parameter_name := 'Origin_country_Id';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('UPDATE','COST_CHANGE_LOC_TEMP',
                    'UPDATE_RECALC_ORD_IND_AT_LOC',
                    'Cost Change: '||to_char(I_cost_change)||
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item);
   update cost_change_loc_temp
      set recalc_ord_ind    = I_recalc_ord_ind
    where item              = I_item
      and supplier          = I_supplier
      and origin_country_id = I_origin_country
      and cost_change       = I_cost_change;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             L_program,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END UPDATE_RECALC_ORD_IND_AT_LOC;
------------------------------------------------------------------------------------------
FUNCTION DELETE_DETAIL_LOC
                  (O_error_message  IN OUT VARCHAR2,
                   I_cost_change    IN     COST_CHANGE_LOC_TEMP.COST_CHANGE%TYPE,
                   I_item           IN     ITEM_MASTER.ITEM%TYPE,
                   I_supplier       IN     SUPS.SUPPLIER%TYPE,
                   I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS
   ---
   L_null_parameter_name  VARCHAR2(30);
   ---
   NULL_PARAMETER         EXCEPTION;

BEGIN
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   end if;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL, 'COST_CHANGE_LOC_TEMP',
                    'Cost Change: '||to_char(I_cost_change));
   ---
   delete cost_change_loc_temp
    where cost_change       = I_cost_change
      and item              = I_item
      and supplier          = I_supplier
      and origin_country_id = I_origin_country;
   ---
   delete cost_susp_sup_detail_loc
    where cost_change       = I_cost_change
      and item              = I_item
      and supplier          = I_supplier
      and origin_country_id = I_origin_country;
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                             'DELETE_DETAIL_LOC',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'DELETE_DETAIL_LOC',
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_DETAIL_LOC;
------------------------------------------------------------------------------------------
FUNCTION CHECK_BUYER_PACK_CONFLICTS (O_error_message   IN OUT   VARCHAR2,
                                     O_conflicts       IN OUT   BOOLEAN,
                                     I_cost_change     IN       COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                                     I_active_date     IN       COST_SUSP_SUP_HEAD.ACTIVE_DATE%TYPE)
   RETURN BOOLEAN IS
   L_item                 COST_SUSP_SUP_DETAIL.ITEM%TYPE;
   L_supplier             COST_SUSP_SUP_DETAIL.SUPPLIER%TYPE;
   L_origin_country_id    COST_SUSP_SUP_DETAIL.ORIGIN_COUNTRY_ID%TYPE;
   L_loc                  COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE;
   L_pack_no        PACKITEM.PACK_NO%TYPE;
   L_dummy                VARCHAR2(1) := 'N';
   L_null_parameter_name  VARCHAR2(30);
   NULL_PARAMETER         EXCEPTION;
   ---

   cursor C_GET_CURRENT_COST is
      select cd.item,
             cd.supplier,
             cd.origin_country_id,
             to_number(NULL) loc,
             pi.pack_no
        from cost_susp_sup_detail cd,
             item_master im,
             packitem pi
       where cd.cost_change = I_cost_change
         and im.pack_type = 'B'
         and im.item = pi.pack_no
         and pi.item = cd.item
       UNION
      select cd.item,
             cd.supplier,
             cd.origin_country_id,
             to_number(NULL) loc,
             pi.pack_no
        from cost_susp_sup_detail cd,
             item_master im,
             packitem pi
       where cd.cost_change = I_cost_change
         and im.pack_type = 'B'
         and im.item = pi.pack_no
         and pi.item in (select item
                           from item_master
                          where (item_parent = cd.item or
                                 item_grandparent = cd.item)
                          and item_level <= tran_level)
       UNION
      select cdl.item,
             cdl.supplier,
             cdl.origin_country_id,
             cdl.loc,
             pi.pack_no
        from cost_susp_sup_detail_loc cdl,
             item_master im,
             packitem pi
       where cost_change = I_cost_change
         and im.pack_type = 'B'
         and im.item = pi.pack_no
         and pi.item = cdl.item
       UNION
      select cdl.item,
             cdl.supplier,
             cdl.origin_country_id,
             to_number(NULL) loc,
             pi.pack_no
        from cost_susp_sup_detail_loc cdl,
             item_master im,
             packitem pi
       where cdl.cost_change = I_cost_change
         and im.pack_type = 'B'
         and im.item = pi.pack_no
         and pi.item in (select item
                  from item_master
                 where (item_parent = cdl.item or
                        item_grandparent = cdl.item)
                   and item_level <= tran_level);


   cursor C_BUYER_PACK_COST_CONFLICTS is
      select 'Y'
        from cost_susp_sup_detail cd,
             cost_susp_sup_head ch
       where ch.cost_change = cd.cost_change
         and cd.item in (select item
                           from packitem
                          where pack_no = L_pack_no)
         and ch.active_date = I_active_date
         and cd.supplier    = L_supplier
         and cd.origin_country_id = L_origin_country_id
         and ch.status in ('S','A','E')
         and ch.cost_change != I_cost_change
         and ch.reason > 3
      UNION
      select 'Y'
        from cost_susp_sup_detail_loc cdl,
             cost_susp_sup_head ch
       where ch.cost_change = cdl.cost_change
         and cdl.item in (select  item
                           from packitem
                          where pack_no = L_pack_no)
         and ch.active_date = I_active_date
         and cdl.supplier   = L_supplier
         and cdl.origin_country_id = L_origin_country_id
         and ch.status in ('S','A','E')
         and ch.cost_change != I_cost_change
         and ch.reason > 3
         and (cdl.loc = L_loc
              or L_loc is NULL);

BEGIN
   if I_cost_change is NULL then
      L_null_parameter_name := 'cost_change';
      raise NULL_PARAMETER;
   elsif I_active_date is NULL then
      L_null_parameter_name := 'active_date';
      raise NULL_PARAMETER;
   end if;
   --Check for cost change conflicts
   FOR rec_current_cost IN C_GET_CURRENT_COST LOOP
      L_item     := rec_current_cost.item;
      L_supplier := rec_current_cost.supplier;
      L_origin_country_id := rec_current_cost.origin_country_id;
      L_loc      := rec_current_cost.loc;
      L_pack_no  := rec_current_cost.pack_no;

      SQL_LIB.SET_MARK('OPEN',
                       'C_BUYER_PACK_COST_CONFLICTS',
                       'COST_SUSP_SUP_DETAIL',
                       'COST_CHANGE:  '|| TO_CHAR(I_cost_change)||
                       ',ACTIVE_DATE: '|| TO_CHAR(I_active_date));
      open C_BUYER_PACK_COST_CONFLICTS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_BUYER_PACK_COST_CONFLICTS',
                       'COST_SUSP_SUP_DETAIL',
                       'COST_CHANGE:  '|| TO_CHAR(I_cost_change)||
                       ',ACTIVE_DATE: '|| TO_CHAR(I_active_date));
      fetch C_BUYER_PACK_COST_CONFLICTS into L_dummy;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_BUYER_PACK_COST_CONFLICTS',
                       'COST_SUSP_SUP_DETAIL',
                       'COST_CHANGE:  '|| TO_CHAR(I_cost_change)||
                       ',ACTIVE_DATE: '|| TO_CHAR(I_active_date));
      close C_BUYER_PACK_COST_CONFLICTS;
      ---
      O_conflicts := (L_dummy = 'Y');

   END LOOP;
   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                            'COST_CHANGE_SQL.CHECK_BUYER_PACK_CONFLICTS',
                                             NULL);

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                             SQLERRM,
                                            'COST_CHANGE_SQL.CHECK_BUYER_PACK_CONFLICTS',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_BUYER_PACK_CONFLICTS;
--------------------------------------------------------------------------------------
FUNCTION CREATE_RCA_COST_CHG (O_error_message        IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_cost_change_no       IN       COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                              I_reason               IN       COST_SUSP_SUP_HEAD.REASON%TYPE,
                              I_active_date          IN       COST_SUSP_SUP_HEAD.ACTIVE_DATE%TYPE,
                              I_status               IN       COST_SUSP_SUP_HEAD.STATUS%TYPE,
                              I_cost_change_origin   IN       COST_SUSP_SUP_HEAD.COST_CHANGE_ORIGIN%TYPE,
                              I_create_date          IN       COST_SUSP_SUP_HEAD.CREATE_DATE%TYPE,
                              I_create_id            IN       COST_SUSP_SUP_HEAD.CREATE_ID%TYPE,
                              I_approval_date        IN       COST_SUSP_SUP_HEAD.APPROVAL_DATE%TYPE,
                              I_approval_id          IN       COST_SUSP_SUP_HEAD.APPROVAL_ID%TYPE)

   RETURN BOOLEAN IS

   L_reason               COST_SUSP_SUP_HEAD.REASON%TYPE              := I_reason;
   L_active_date          COST_SUSP_SUP_HEAD.ACTIVE_DATE%TYPE         := NVL(I_active_date,(GET_VDATE + 1));
   L_status               COST_SUSP_SUP_HEAD.STATUS%TYPE              := NVL(I_status,'A');
   L_cost_change_origin   COST_SUSP_SUP_HEAD.COST_CHANGE_ORIGIN%TYPE  := NVL(I_cost_change_origin,'SKU');
   L_create_date          COST_SUSP_SUP_HEAD.CREATE_DATE%TYPE         := NVL(I_create_date, SYSDATE);
   L_create_id            COST_SUSP_SUP_HEAD.CREATE_ID%TYPE           := NVL(I_create_id, USER);
   L_approval_date        COST_SUSP_SUP_HEAD.APPROVAL_DATE%TYPE       := NVL(I_approval_date, SYSDATE);
   L_approval_id          COST_SUSP_SUP_HEAD.APPROVAL_ID%TYPE         := NVL(I_approval_id, USER);
   L_cost_change_desc     COST_SUSP_SUP_HEAD.COST_CHANGE_DESC%TYPE;
   L_null_parameter_name  VARCHAR2(30);
   NULL_PARAMETER         EXCEPTION;
   ---

BEGIN

   --Validate input parameters
   if I_cost_change_no is NULL then
      L_null_parameter_name := 'cost_change_no';
      raise NULL_PARAMETER;
   end if;

   if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                 'RCAD',
                                 'RCAA',
                                  L_cost_change_desc) = FALSE then
      return FALSE;
   end if;


   --insert records
   SQL_LIB.SET_MARK('INSERT',
                    NULL,
                    'COST_SUSP_SUP_HEAD',
                    'COST_CHANGE:  '|| TO_CHAR(I_cost_change_no));
   insert into cost_susp_sup_head (cost_change,
                                   cost_change_desc,
                                   reason,
                                   active_date,
                                   status,
                                   cost_change_origin,
                                   create_date,
                                   create_id,
                                   approval_date,
                                   approval_id)
                           values (I_cost_change_no,
                                   L_cost_change_desc,
                                   I_reason,
                                   L_active_date,
                                   L_status,
                                   L_cost_change_origin,
                                   L_create_date,
                                   L_create_id,
                                   L_approval_date,
                                   L_approval_id);

   ---
   return TRUE;
EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                            'COST_CHANGE_SQL.CREATE_RCA_COST_CHG',
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'COST_CHANGE_SQL.CREATE_RCA_COST_CHG',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CREATE_RCA_COST_CHG;
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
FUNCTION COST_CHANGE_EXISTS(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            O_exists           IN OUT   BOOLEAN,
                            I_supplier         IN       COST_SUSP_SUP_DETAIL.SUPPLIER%TYPE,
                            I_item             IN       COST_SUSP_SUP_DETAIL.ITEM%TYPE,
                            I_location         IN       COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE,
                            I_effective_date   IN       COST_SUSP_SUP_HEAD.ACTIVE_DATE%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60)   := 'COST_CHANGE_SQL.COST_CHANGE_EXISTS';
   L_exists    VARCHAR2(1)    := NULL;

   cursor C_CHECK_DETAIL_LOC is
      select 'x'
        from cost_susp_sup_detail_loc l,
             cost_susp_sup_head h
       where l.supplier    = I_supplier
         and l.item        = I_item
         and l.loc         = I_location
         and l.cost_change = h.cost_change
         and h.active_date = I_effective_date
         and rownum = 1
   union
   select 'x'
           from cost_susp_sup_detail_loc l,
                cost_susp_sup_head h
          where l.supplier    = I_supplier
            and l.item        = I_item
            and l.cost_change = h.cost_change
            and h.active_date = I_effective_date
            and l.loc in (select wh
                        from wh
                       where physical_wh = I_location
                     and stockholding_ind = 'Y')
         and rownum = 1;

   cursor C_CHECK_DETAIL is
      select 'x'
        from cost_susp_sup_detail d,
             cost_susp_sup_head h
       where d.supplier    = I_supplier
         and d.item        = I_item
         and d.cost_change = h.cost_change
         and h.active_date = I_effective_date
         and rownum = 1;

BEGIN

   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'Supplier',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'Item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'Location',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_effective_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'Effective date',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_DETAIL_LOC',
                    'COST_SUSP_SUP_DETAIL_LOC,
                     COST_SUSP_SUP_HEAD',
                     NULL);
   open C_CHECK_DETAIL_LOC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_DETAIL_LOC',
                    'COST_SUSP_SUP_DETAIL_LOC,
                     COST_SUSP_SUP_HEAD',
                     NULL);
   fetch C_CHECK_DETAIL_LOC into L_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_DETAIL_LOC',
                    'COST_SUSP_SUP_DETAIL_LOC,
                     COST_SUSP_SUP_HEAD',
                     NULL);
   close C_CHECK_DETAIL_LOC;

   if L_exists is NOT NULL then
      O_exists := TRUE;
   else
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_DETAIL',
                       'COST_SUSP_SUP_DETAIL,
                        COST_SUSP_SUP_HEAD',
                        NULL);
      open C_CHECK_DETAIL;

      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_DETAIL',
                       'COST_SUSP_SUP_DETAIL,
                        COST_SUSP_SUP_HEAD',
                        NULL);
      fetch C_CHECK_DETAIL into L_exists;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_DETAIL',
                       'COST_SUSP_SUP_DETAIL,
                        COST_SUSP_SUP_HEAD',
                        NULL);
      close C_CHECK_DETAIL;

      if L_exists is NOT NULL then
         O_exists := TRUE;
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

END COST_CHANGE_EXISTS;
------------------------------------------------------------------------------------------
FUNCTION APPLY_TO_ALL_LOCS (O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                            I_order_no        IN      ORDHEAD.ORDER_NO%TYPE,
                            I_item        IN      ORDLOC.ITEM%TYPE,
                            I_bracket_value   IN      SUP_BRACKET_COST.BRACKET_VALUE1%TYPE,
                            I_change_amt      IN      COST_CHANGE_LOC_TEMP.UNIT_COST_NEW%TYPE,
                            I_change_no       IN      COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60)   := 'COST_CHANGE_SQL.APPLY_TO_ALL_LOCS';

   cursor C_ORDLOC is
     select   distinct oh.supplier,
                       os.origin_country_id,
                       decode( ol.loc_type, 'S', ol.location, 'W', wh.physical_wh),
                       ol.loc_type
                 from  ordhead oh,
                       ordsku os,
                       ordloc ol,
                   wh
                where  os.item = I_item
                  and  os.item = ol.item
                  and  oh.order_no = I_order_no
                  and  oh.order_no = os.order_no
                  and  oh.order_no = ol.order_no
         and  ol.location = wh.wh(+);

   TYPE supplier_table is table of ordhead.supplier%TYPE  INDEX BY BINARY_INTEGER;
   TYPE origin_country_table is table of ordsku.origin_country_id%TYPE  INDEX BY BINARY_INTEGER;
   TYPE location_table is table of ordloc.location%TYPE  INDEX BY BINARY_INTEGER;
   TYPE loc_type_table is table of ordloc.loc_type%TYPE  INDEX BY BINARY_INTEGER;

   L_supplier_table         supplier_table;
   L_origin_country_table   origin_country_table;
   L_location_table         location_table;
   L_loc_type_table         loc_type_table;
   L_first                  NUMBER;
   L_last                   NUMBER;
   L_exists                 BOOLEAN;
   L_effective_date         DATE := get_vdate + 1;

BEGIN

   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'Order No',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'Item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_change_amt is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'Change Amt',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_change_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'Change No',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_ORDLOC',
                    NULL,
                    NULL);
   open C_ORDLOC;


   SQL_LIB.SET_MARK('OPEN',
                    'C_ORDLOC',
                    NULL,
                    NULL);
   fetch C_ORDLOC BULK COLLECT INTO L_supplier_table,
                                    L_origin_country_table,
                                    L_location_table,
                                    L_loc_type_table;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ORDLOC',
                    NULL,
                    NULL);
   close C_ORDLOC;


   L_first := L_supplier_table.FIRST;
   L_last  := L_supplier_table.LAST;

   for i in L_first..L_last loop
      if COST_CHANGE_SQL.COST_CHANGE_EXISTS (O_error_message,
                                             L_exists,
                                             L_supplier_table(i),
                                             I_item,
                                             L_location_table(i),
                                             L_effective_date) = FALSE then

         return FALSE;
      end if;

      if L_exists = TRUE then
         O_error_message := SQL_LIB.CREATE_MSG('COST_CHANGE_EXISTS',
                                                NULL,
                                                NULL,
                                                NULL);
            return FALSE;
      end if;
      if L_exists = FALSE then
         if COST_CHANGE_SQL.POP_TEMP_DETAIL_LOC(O_error_message,
                                                L_exists,
                                                'NEW',
                                                I_change_no,
                                                L_supplier_table(i),
                                                L_origin_country_table(i),
                                                I_item,
                                                99 ) = FALSE then
            return FALSE;
         end if;

         if COST_CHANGE_SQL.APPLY_CHANGE_LOC(O_error_message,
                                             L_supplier_table(i),
                                             L_origin_country_table(i),
                                             I_item,
                                             L_loc_type_table(i),
                                             L_location_table(i),
                                             NULL,
                                             'F',
                                             I_change_amt) = FALSE then
            return FALSE;
         end if;

         if COST_CHANGE_SQL.INSERT_UPDATE_COST_CHANGE(O_error_message,
                                                      I_change_no) = FALSE then

            return FALSE;
         end if;

         if COST_CHANGE_SQL.DELETE_COST_CHANGE_LOC_TEMP(O_error_message,
                                                        I_change_no) = FALSE then
            return FALSE;
         end if;

      end if;

   end loop;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END APPLY_TO_ALL_LOCS;
------------------------------------------------------------------------------------------
--Mod By:      Nitin Kumar
--Mod Date:    29-Apr-2009
--Mod Ref:     NBS00012501/503
--Mod Details: Modified the functions POP_TEMP_DETAIL_SEC to include the cost changes only for
--             simple pack.Complex packs cant go under the cost change as Mod N53 restricts the
--             user to do the cost change for Complex Packs.
-----------------------------------------------------------------------------------------------------

FUNCTION POP_TEMP_DETAIL_SEC (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exists           IN OUT   BOOLEAN,
                              I_mode             IN       VARCHAR2,
                              I_cost_change      IN       COST_CHANGE_TEMP.COST_CHANGE%TYPE,
                              I_supplier         IN       SUPS.SUPPLIER%TYPE,
                              I_origin_country   IN       COUNTRY.COUNTRY_ID%TYPE,
                              I_item             IN       ITEM_MASTER.ITEM%TYPE,
                              -- 21-Oct-2008 TESCO HSC/Murali 6316705 Begin
                              I_expand_parent    IN       VARCHAR2)
                              -- 21-Oct-2008 TESCO HSC/Murali 6316705 End
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60)   := 'COST_CHANGE_SQL.POP_TEMP_DETAIL_SEC';

   TYPE supplier_tbl              is TABLE OF NUMBER(10)     INDEX BY BINARY_INTEGER;
   TYPE country_tbl               is TABLE OF VARCHAR2(3)    INDEX BY BINARY_INTEGER;
   TYPE item_tbl                  is TABLE OF VARCHAR2(25)   INDEX BY BINARY_INTEGER;
   TYPE unit_cost_tbl             is TABLE OF NUMBER(20,4)   INDEX BY BINARY_INTEGER;
   TYPE cost_uom_tbl              is TABLE OF VARCHAR2(4)    INDEX BY BINARY_INTEGER;
   TYPE dept_tbl                  is TABLE OF NUMBER(4)      INDEX BY BINARY_INTEGER;
   TYPE ref_item_tbl              is TABLE OF VARCHAR2(25)   INDEX BY BINARY_INTEGER;
   TYPE vpn_tbl                   is TABLE OF VARCHAR2(30)   INDEX BY BINARY_INTEGER;
   TYPE converted_cost_tbl        is TABLE OF NUMBER(20,4)   INDEX BY BINARY_INTEGER;
   TYPE bracket_value1_tbl        is TABLE OF NUMBER(12,4)   INDEX BY BINARY_INTEGER;
   TYPE bracket_value2_tbl        is TABLE OF NUMBER(12,4)   INDEX BY BINARY_INTEGER;
   TYPE default_bracket_ind_tbl   is TABLE OF VARCHAR2(1)    INDEX BY BINARY_INTEGER;

   L_supplier_tbl               SUPPLIER_TBL;
   L_country_tbl                COUNTRY_TBL;
   L_item_tbl                   ITEM_TBL;
   L_unit_cost_tbl              UNIT_COST_TBL;
   L_cost_uom_tbl               COST_UOM_TBL;
   L_dept_tbl                   DEPT_TBL;
   L_ref_item_tbl               REF_ITEM_TBL;
   L_vpn_tbl                    VPN_TBL;
   L_converted_cost_tbl         CONVERTED_COST_TBL;
   L_bracket_value1_tbl         BRACKET_VALUE1_TBL;
   L_bracket_value2_tbl         BRACKET_VALUE2_TBL;
   L_default_bracket_ind_tbl    DEFAULT_BRACKET_IND_TBL;

   L_converted_cost1   NUMBER(20,4);
   L_converted_cost2   NUMBER(20,4);
   L_inserted          VARCHAR2(1)   := 'N';
   L_old_unit_cost     COST_CHANGE_TEMP.UNIT_COST_OLD%TYPE;

   L_no_vis_items      BOOLEAN;
   ---
   INVALID_MODE        EXCEPTION;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
   L_apply_rp_link     SYSTEM_OPTIONS.TSL_APPLY_RP_LINK%TYPE := NULL;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
   -- 08-May-08 Bahubali D Mod N111 Begin
   L_system_options_row  SYSTEM_OPTIONS%ROWTYPE;
   L_apply_common_prd    SYSTEM_OPTIONS.TSL_COMMON_PRODUCT_IND%TYPE;
   L_origin_country      SYSTEM_OPTIONS.TSL_ORIGIN_COUNTRY%TYPE;
   -- 08-May-08 Bahubali D Mod N111 End
   cursor C_COST_MAINT_SUPP_V is
      select 'X'
        from cost_susp_sup_detail cssd,
             v_item_master im
       where cssd.cost_change = I_cost_change
         and cssd.item        = im.item
         and rownum           = 1;

   cursor C_COST_MAINT_SUPP is
      select cssd.item,
             cssd.supplier,
             cssd.origin_country_id,
             cssd.bracket_value1,
             cssd.bracket_uom1,
             cssd.bracket_value2,
             cssd.default_bracket_ind,
             cssd.unit_cost,
             cssd.cost_change_type,
             cssd.cost_change_value,
             cssd.recalc_ord_ind,
             cssd.dept,
             cssd.sup_dept_seq_no,
             ref_item.ref_item,
             isc.cost_uom,
             isp.vpn
        from cost_susp_sup_detail cssd,
             v_item_master im,
             item_supp_country isc,
             item_supplier isp,
   	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
       where cssd.cost_change       = I_cost_change
         and cssd.item              = im.item
         and cssd.item              = isc.item
         and cssd.item              = isp.item
         and cssd.supplier          = isc.supplier
         and cssd.supplier          = isp.supplier
         and cssd.origin_country_id = isc.origin_country_id
         and cssd.item              = ref_item.item(+);

   cursor C_NO_BRACKET_COST is
      select isc.supplier,
             isc.origin_country_id,
             isc.item,
             isc.unit_cost,
             isc.cost_uom,
             im.dept,
             ref_item.ref_item,
             isp.vpn
        from item_supp_country isc,
             sups s,
             v_item_master im,
             item_supplier isp,
    	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
        where s.supplier = NVL(I_supplier, s.supplier)
           and isc.supplier = s.supplier
           and isc.supplier = isp.supplier
           -- 21-Oct-2008 TESCO HSC/Murali 6306705 Begin
           and DECODE(I_expand_parent,'N',im.item,im.item_parent) = NVL(I_item, im.item)
           -- 21-Oct-2008 TESCO HSC/Murali 6616812 End
           -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
           and im.item = isc.item
           and isc.item = isp.item
           and s.bracket_costing_ind = 'N'
           and im.item_level        <= im.tran_level
           -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
           -- and (im.pack_ind          = 'N'
           -- or  (im.pack_ind          = 'Y' and im.pack_type = 'V'))
           and (im.simple_pack_ind      = 'Y' and im.pack_type = 'V')
           -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End
           and im.status             = 'A'
           and isc.origin_country_id = NVL(I_origin_country, isc.origin_country_id)
           and isc.item              = ref_item.item(+)
           -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
           and NOT (im.pack_ind                   = 'Y'
                    and im.pack_type              = 'V'
                    and im.orderable_ind          = 'Y'
                    and im.tsl_mu_ind             = 'N'
                    and im.simple_pack_ind        = 'N'
                    and NVL(L_apply_rp_link, 'N') = 'Y')
           -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
           -- 08-May-08 Bahubali D Mod N111 Begin
           and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                where im.tsl_common_ind        = 'Y'
                                  and im.tsl_primary_country  != L_origin_country
                                  and im.tsl_primary_country is NOT NULL
                                  and tcsm.channel_id in ('1Y','2Y','3Y')
                                  and L_apply_common_prd = 'Y'
                                  and im.item = tcsm.item
                                  and isp.supplier = tcsm.target_supplier);
           -- 08-May-08 Bahubali D Mod N111 End
   cursor C_SUPP_DEPT_LEVEL_BRACKETS is
      select iscbc.supplier,
             iscbc.origin_country_id,
             iscbc.item,
             iscbc.bracket_value1,
             iscbc.bracket_value2,
             iscbc.default_bracket_ind,
             iscbc.unit_cost,
             im.dept,
             ref_item.ref_item,
             isc.cost_uom,
             isp.vpn
        from sups s,
             item_supp_country_bracket_cost iscbc,
             v_item_master im,
             item_supp_country isc,
             item_supplier isp,
   	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
       where s.supplier               = iscbc.supplier
         and iscbc.supplier           = NVL(I_supplier, iscbc.supplier)
         and iscbc.supplier           = isc.supplier
         and iscbc.supplier           = isp.supplier
         and iscbc.item               = im.item
         and iscbc.item               = isc.item
         and iscbc.item               = isp.item
         -- 21-Oct-2008 TESCO HSC/Murali 6306705 Begin
         and DECODE(I_expand_parent,'N',im.item,im.item_parent) = NVL(I_item, im.item)
         -- 21-Oct-2008 TESCO HSC/Murali 6306705 End
         and s.bracket_costing_ind    = 'Y'
         and s.inv_mgmt_lvl           in ('S', 'D')
         and iscbc.location           is NULL
         and im.item_level           <= im.tran_level
         -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
         -- and (im.pack_ind          = 'N'
         -- or  (im.pack_ind          = 'Y' and im.pack_type = 'V'))
         and (im.simple_pack_ind      = 'Y' and im.pack_type = 'V')
         -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End
         and im.status                = 'A'
         and iscbc.origin_country_id  = NVL(I_origin_country, iscbc.origin_country_id)
         and iscbc.item               = ref_item.item(+)
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
         and NOT (im.pack_ind                   = 'Y'
                  and im.pack_type              = 'V'
                  and im.orderable_ind          = 'Y'
                  and im.tsl_mu_ind             = 'N'
                  and im.simple_pack_ind        = 'N'
                  and NVL(L_apply_rp_link, 'N') = 'Y')
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
         -- 08-May-08 Bahubali D Mod N111 Begin
           and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                     where im.tsl_common_ind        = 'Y'
                                       and im.tsl_primary_country  != L_origin_country
                                       and im.tsl_primary_country is NOT NULL
                                       and tcsm.channel_id in ('1Y','2Y','3Y')
                                       and L_apply_common_prd = 'Y'
                                       and im.item = tcsm.item
                                       and isp.supplier = tcsm.target_supplier);
           -- 08-May-08 Bahubali D Mod N111 End
   cursor C_WITH_BRACKET_LOCATIONS is
      select distinct iscbc.supplier,
             iscbc.origin_country_id,
             iscbc.item,
             im.dept,
             ref_item.ref_item,
             isc.cost_uom,
             isp.vpn
        from item_supp_country_bracket_cost iscbc,
             sups s,
             v_item_master im,
             item_supplier isp,
             item_supp_country isc,
   	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
       where s.supplier               = iscbc.supplier
         and iscbc.supplier           = NVL(I_supplier, iscbc.supplier)
         and iscbc.supplier           = isc.supplier
         and iscbc.supplier           = isp.supplier
         and iscbc.item               = im.item
         -- 21-Oct-2008 TESCO HSC/Murali 6306705 Begin
         and DECODE(I_expand_parent,'N',im.item,im.item_parent) = NVL(I_item, im.item)
         -- 21-Oct-2008 TESCO HSC/Murali 6306705 End
         and iscbc.item               = isc.item
         and iscbc.item               = isp.item
         and s.bracket_costing_ind    = 'Y'
         and s.inv_mgmt_lvl           in ('L', 'A')
         and im.item_level           <= im.tran_level
         -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
         -- and (im.pack_ind          = 'N'
         -- or  (im.pack_ind          = 'Y' and im.pack_type = 'V'))
         and (im.simple_pack_ind          = 'Y' and im.pack_type = 'V')
         -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End
         and im.status                = 'A'
         and iscbc.origin_country_id  = NVL(I_origin_country, iscbc.origin_country_id)
         and iscbc.item               = ref_item.item(+)
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
         and NOT (im.pack_ind                   = 'Y'
                  and im.pack_type              = 'V'
                  and im.orderable_ind          = 'Y'
                  and im.tsl_mu_ind             = 'N'
                  and im.simple_pack_ind        = 'N'
                  and NVL(L_apply_rp_link, 'N') = 'Y')
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
         -- 08-May-08 Bahubali D Mod N111 Begin
           and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                     where im.tsl_common_ind        = 'Y'
                                       and im.tsl_primary_country  != L_origin_country
                                       and im.tsl_primary_country is NOT NULL
                                       and tcsm.channel_id in ('1Y','2Y','3Y')
                                       and L_apply_common_prd = 'Y'
                                       and im.item = tcsm.item
                                       and isp.supplier = tcsm.target_supplier);
           -- 08-May-08 Bahubali D Mod N111 End
BEGIN
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
   -- The below function call the removed by Mod N111
   --if SYSTEM_OPTIONS_SQL.TSL_GET_APPLY_RP_LINK(O_error_message,
   --                                            L_apply_rp_link) = FALSE then
   --   return FALSE;
   --end if;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
   ---
   -- 08-May-08 Bahubali D Mod N111 Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS (O_error_message,
                                             L_system_options_row) = FALSE then
      return FALSE;
   end if;
   ---
   L_apply_rp_link    := L_system_options_row.tsl_apply_rp_link;
   L_apply_common_prd := L_system_options_row.tsl_common_product_ind;
   L_origin_country   := L_system_options_row.tsl_origin_country;
   ---
   -- 08-May-08 Bahubali D Mod N111 End
   if I_mode = 'NEW' then

      SQL_LIB.SET_MARK('OPEN',
                       'C_NO_BRACKET_COST',
                       'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      open C_NO_BRACKET_COST;
      SQL_LIB.SET_MARK('FETCH',
                       'C_NO_BRACKET_COST',
                       'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      fetch C_NO_BRACKET_COST BULK COLLECT into L_supplier_tbl,
                                                L_country_tbl,
                                                L_item_tbl,
                                                L_unit_cost_tbl,
                                                L_cost_uom_tbl,
                                                L_dept_tbl,
                                                L_ref_item_tbl,
                                                L_vpn_tbl;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_NO_BRACKET_COST',
                       'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      close C_NO_BRACKET_COST;
      if L_item_tbl.first is NOT NULL then
         FOR i in L_item_tbl.first..L_item_tbl.last LOOP
            if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                  L_unit_cost_tbl(i),
                                                  L_item_tbl(i),
                                                  L_supplier_tbl(i),
                                                  L_country_tbl(i),
                                                  'S',
                                                  NULL) = FALSE then
               return FALSE;
            end if;
            L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
         END LOOP;

         SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         --- insert for suppliers who do NOT bracket cost.
         ---
         FORALL i in L_item_tbl.first..L_item_tbl.last
            insert into cost_change_temp (cost_change,
                                          supplier,
                                          origin_country_id,
                                          item,
                                          bracket_value1,
                                          bracket_uom,
                                          bracket_value2,
                                          default_bracket_ind,
                                          unit_cost_old,
                                          unit_cost_new,
                                          recalc_ord_ind,
                                          loc_level_ind,
                                          dept,
                                          cost_uom,
                                          unit_cost_cuom_new,
                                          unit_cost_cuom_old,
                                          vpn,
                                          ref_item)
                                   values (I_cost_change,
                                          L_supplier_tbl(i),
                                          L_country_tbl(i),
                                          L_item_tbl(i),
                                          NULL,
                                          NULL,
                                          NULL,
                                          'N',
                                          L_unit_cost_tbl(i),
                                          NULL,
                                          'N',
                                          'N',
                                          L_dept_tbl(i),
                                          L_cost_uom_tbl(i),
                                          NULL,
                                          L_converted_cost_tbl(i),
                                          L_vpn_tbl(i),
                                          L_ref_item_tbl(i));

         if SQL%FOUND then
            L_inserted := 'Y';
         end if;

      end if;

      SQL_LIB.SET_MARK('OPEN',
                       'C_SUPP_DEPT_LEVEL_BRACKETS',
                       'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      open C_SUPP_DEPT_LEVEL_BRACKETS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_SUPP_DEPT_LEVEL_BRACKETS',
                       'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      fetch C_SUPP_DEPT_LEVEL_BRACKETS BULK COLLECT into L_supplier_tbl,
                                                         L_country_tbl,
                                                         L_item_tbl,
                                                         L_bracket_value1_tbl,
                                                         L_bracket_value2_tbl,
                                                         L_default_bracket_ind_tbl,
                                                         L_unit_cost_tbl,
                                                         L_dept_tbl,
                                                         L_ref_item_tbl,
                                                         L_cost_uom_tbl,
                                                         L_vpn_tbl;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SUPP_DEPT_LEVEL_BRACKETS',
                       'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      close C_SUPP_DEPT_LEVEL_BRACKETS;
      if L_item_tbl.first is NOT NULL then
         FOR i in L_item_tbl.first..L_item_tbl.last LOOP
            if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                  L_unit_cost_tbl(i),
                                                  L_item_tbl(i),
                                                  L_supplier_tbl(i),
                                                  L_country_tbl(i),
                                                  'S',
                                                  NULL) = FALSE then
               return FALSE;
            end if;
            L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
         END LOOP;

      ---
      SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      --- insert for supplier or dept level brackets
      ---

      FORALL i in L_item_tbl.first..L_item_tbl.last
         insert into cost_change_temp (cost_change,
                                       supplier,
                                       origin_country_id,
                                       item,
                                       bracket_value1,
                                       bracket_uom,
                                       bracket_value2,
                                       default_bracket_ind,
                                       unit_cost_old,
                                       unit_cost_new,
                                       recalc_ord_ind,
                                       loc_level_ind,
                                       dept,
                                       cost_uom,
                                       unit_cost_cuom_new,
                                       unit_cost_cuom_old,
                                       vpn,
                                       ref_item)
                               values (I_cost_change,
                                       L_supplier_tbl(i),
                                       L_country_tbl(i),
                                       L_item_tbl(i),
                                       L_bracket_value1_tbl(i),
                                       NULL,
                                       L_bracket_value2_tbl(i),
                                       L_default_bracket_ind_tbl(i),
                                       L_unit_cost_tbl(i),
                                       NULL,
                                       'N',
                                       'N',
                                       L_dept_tbl(i),
                                       L_cost_uom_tbl(i),
                                       NULL,
                                       L_converted_cost_tbl(i),
                                       L_vpn_tbl(i),
                                       L_ref_item_tbl(i));

      if SQL%FOUND then
         L_inserted := 'Y';
      end if;

   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_WITH_BRACKET_LOCATIONS',
                    'COST_CHANGE_TEMP',
                    'Cost Change: '||to_char(I_cost_change)||
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item);
   open C_WITH_BRACKET_LOCATIONS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_WITH_BRACKET_LOCATIONS',
                    'COST_CHANGE_TEMP',
                    'Cost Change: '||to_char(I_cost_change)||
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item);
   fetch C_WITH_BRACKET_LOCATIONS BULK COLLECT into L_supplier_tbl,
                                                    L_country_tbl,
                                                    L_item_tbl,
                                                    L_dept_tbl,
                                                    L_ref_item_tbl,
                                                    L_cost_uom_tbl,
                                                    L_vpn_tbl;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_WITH_BRACKET_LOCATIONS',
                    'COST_CHANGE_TEMP',
                    'Cost Change: '||to_char(I_cost_change)||
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item);
   close C_WITH_BRACKET_LOCATIONS;
   SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                    'Cost Change: '||to_char(I_cost_change)||
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item);
   --- insert for suppliers that have bracket locations.

   if L_item_tbl.first is NOT NULL then
      FORALL i in L_item_tbl.first..L_item_tbl.last
         insert into cost_change_temp (cost_change,
                                       supplier,
                                       origin_country_id,
                                       item,
                                       bracket_value1,
                                       bracket_uom,
                                       bracket_value2,
                                       default_bracket_ind,
                                       unit_cost_old,
                                       unit_cost_new,
                                       recalc_ord_ind,
                                       loc_level_ind,
                                       dept,
                                       cost_uom,
                                       unit_cost_cuom_new,
                                       unit_cost_cuom_old,
                                       vpn,
                                       ref_item)
                                values (I_cost_change,
                                       L_supplier_tbl(i),
                                       L_country_tbl(i),
                                       L_item_tbl(i),
                                       NULL,
                                       NULL,
                                       NULL,
                                       'N',
                                       NULL,
                                       NULL,
                                       'N',
                                       'Y',
                                       L_dept_tbl(i),
                                       L_cost_uom_tbl(i),
                                       NULL,
                                       NULL,
                                       L_vpn_tbl(i),
                                       L_ref_item_tbl(i));

      if SQL%FOUND then
         L_inserted := 'Y';
      end if;

   end if;

   elsif I_mode in ('EDIT','VIEW') then
      ---
      SQL_LIB.SET_MARK('OPEN','C_COST_MAINT_SUPP',
                       'COST_SUSP_SUP_DETAIL',
                       'Cost Change: '||to_char(I_cost_change));
      FOR current_rec in C_COST_MAINT_SUPP LOOP
         if current_rec.bracket_value1 is NOT NULL then
            if COST_CHANGE_SQL.BC_UNIT_COST (O_error_message,
                                             L_old_unit_cost,
                                             current_rec.supplier,
                                             current_rec.origin_country_id,
                                             current_rec.item,
                                             current_rec.bracket_value1,
                                             NULL) = FALSE then
               return FALSE;
            end if;
         end if;
         if L_old_unit_cost is null or current_rec.bracket_value1 is NULL then
            if SUPP_ITEM_SQL.GET_COST(O_error_message,
                                      L_old_unit_cost,
                                      current_rec.item,
                                      current_rec.supplier,
                                      current_rec.origin_country_id,
                                      NULL) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
         L_converted_cost1 := L_old_unit_cost;
         -- 21-Oct-2008 TESCO HSC/Murali 6616812 End
         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
                                               L_converted_cost1,
                                               -- 21-Oct-2008 TESCO HSC/Murali 6616812 End
                                               current_rec.item,
                                               current_rec.supplier,
                                               current_rec.origin_country_id,
                                               'S',
                                               NULL) = FALSE then
            return FALSE;
         end if;
         -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
         L_converted_cost2:= current_rec.unit_cost;
         -- 21-Oct-2008 TESCO HSC/Murali 6616812 End

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
                                               L_converted_cost2,
                                               -- 21-Oct-2008 TESCO HSC/Murali 6616812 End
                                               current_rec.item,
                                               current_rec.supplier,
                                               current_rec.origin_country_id,
                                               'S',
                                               NULL) = FALSE then
            return FALSE;
         end if;
         -- 21-Oct-2008 TESCO HSC/Murali 6616812 Begin
         -- 21-Oct-2008 TESCO HSC/Murali 6616812 End

         SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(current_rec.supplier)||
                          ' Origin Country: '||current_rec.origin_country_id||
                          ' Item: '||current_rec.item);
         ---
         insert into cost_change_temp (cost_change,
                                       supplier,
                                       origin_country_id,
                                       item,
                                       bracket_value1,
                                       bracket_uom,
                                       bracket_value2,
                                       default_bracket_ind,
                                       unit_cost_old,
                                       unit_cost_new,
                                       cost_change_type,
                                       cost_change_value,
                                       recalc_ord_ind,
                                       loc_level_ind,
                                       dept,
                                       sup_dept_seq_no,
                                       cost_uom,
                                       unit_cost_cuom_new,
                                       unit_cost_cuom_old,
                                       vpn,
                                       ref_item)
                               values (I_cost_change,
                                      current_rec.supplier,
                                      current_rec.origin_country_id,
                                      current_rec.item,
                                      current_rec.bracket_value1,
                                      current_rec.bracket_uom1,
                                      current_rec.bracket_value2,
                                      current_rec.default_bracket_ind,
                                      L_old_unit_cost,
                                      current_rec.unit_cost,
                                      current_rec.cost_change_type,
                                      current_rec.cost_change_value,
                                      current_rec.recalc_ord_ind,
                                      'N',
                                      current_rec.dept,
                                      current_rec.sup_dept_seq_no,
                                      current_rec.cost_uom,
                                      L_converted_cost2,
                                      L_converted_cost1,
                                      current_rec.vpn,
                                      current_rec.ref_item);
         ---
         L_inserted := 'Y';
      END LOOP;
      ---
      SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_TEMP',
                       'Cost Change: '||to_char(I_cost_change)||
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item);
      --- create a item header level record for location level records.
      ---
      insert into cost_change_temp (cost_change,
                                    supplier,
                                    origin_country_id,
                                    item,
                                    bracket_value1,
                                    bracket_uom,
                                    bracket_value2,
                                    default_bracket_ind,
                                    unit_cost_old,
                                    unit_cost_new,
                                    recalc_ord_ind,
                                    loc_level_ind,
                                    dept,
                                    cost_uom,
                                    unit_cost_cuom_new,
                                    unit_cost_cuom_old,
                                    vpn,
                                    ref_item)
                             select distinct I_cost_change,
                                    cssdl.supplier,
                                    cssdl.origin_country_id,
                                    cssdl.item,
                                    NULL,
                                    NULL,
                                    NULL,
                                    'N',
                                    NULL,
                                    NULL,
                                    'N',
                                    'Y',
                                    cssdl.dept,
                                    isc.cost_uom,
                                    NULL,
                                    NULL,
                                    isp.vpn,
                                    ref_item.ref_item
                               from cost_susp_sup_detail_loc cssdl,
                                    item_master im,
                                    item_supp_country isc,
                                    item_supplier isp,
   	                            (select item_parent item, item ref_item
                                       from item_master
                                      where primary_ref_item_ind = 'Y'
                                        and item_parent IS NOT NULL) ref_item
                              where cssdl.cost_change = I_cost_change
                                and cssdl.item = im.item
                                and cssdl.item = isc.item
                                and cssdl.item = isp.item
                                and cssdl.supplier = isc.supplier
                                and cssdl.supplier = isp.supplier
                                and cssdl.origin_country_id = isc.origin_country_id
                                and cssdl.item = ref_item.item(+);

      if SQL%FOUND then
         L_inserted := 'Y';
      end if;

   else raise INVALID_MODE;
   end if;

   if L_inserted = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when INVALID_MODE then
      O_error_message := SQL_LIB.CREATE_MSG('INV_MODE', NULL, NULL, NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END POP_TEMP_DETAIL_SEC;
------------------------------------------------------------------------------------------
--Mod By:      Nitin Kumar
--Mod Date:    29-Apr-2009
--Mod Ref:     NBS00012501/503
--Mod Details: Modified the functions POP_TEMP_DETAIL_LOC_SEC to include the cost changes only
--             for simple pack.Complex packs cant go under the cost change as Mod N53 restricts
--             the user to do the cost change for Complex Packs.
-----------------------------------------------------------------------------------------------------

FUNCTION POP_TEMP_DETAIL_LOC_SEC (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_exists           IN OUT   BOOLEAN,
                                  O_v_locs_exist     IN OUT   VARCHAR2,
                                  I_mode             IN       VARCHAR2,
                                  I_cost_change      IN       COST_CHANGE_TEMP.COST_CHANGE%TYPE,
                                  I_supplier         IN       SUPS.SUPPLIER%TYPE,
                                  I_origin_country   IN       COUNTRY.COUNTRY_ID%TYPE,
                                  I_item             IN       ITEM_MASTER.ITEM%TYPE,
                                  I_reason           IN       COST_SUSP_SUP_HEAD.REASON%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60)   := 'COST_CHANGE_SQL.POP_TEMP_DETAIL_LOC_SEC';

   TYPE supplier_tbl              is TABLE OF NUMBER(10)     INDEX BY BINARY_INTEGER;
   TYPE country_tbl               is TABLE OF VARCHAR2(3)    INDEX BY BINARY_INTEGER;
   TYPE item_tbl                  is TABLE OF VARCHAR2(25)   INDEX BY BINARY_INTEGER;
   TYPE unit_cost_tbl             is TABLE OF NUMBER(20,4)   INDEX BY BINARY_INTEGER;
   TYPE cost_uom_tbl              is TABLE OF VARCHAR2(4)    INDEX BY BINARY_INTEGER;
   TYPE dept_tbl                  is TABLE OF NUMBER(4)      INDEX BY BINARY_INTEGER;
   TYPE ref_item_tbl              is TABLE OF VARCHAR2(25)   INDEX BY BINARY_INTEGER;
   TYPE vpn_tbl                   is TABLE OF VARCHAR2(30)   INDEX BY BINARY_INTEGER;
   TYPE converted_cost_tbl        is TABLE OF NUMBER(20,4)   INDEX BY BINARY_INTEGER;
   TYPE bracket_value1_tbl        is TABLE OF NUMBER(12,4)   INDEX BY BINARY_INTEGER;
   TYPE bracket_value2_tbl        is TABLE OF NUMBER(12,4)   INDEX BY BINARY_INTEGER;
   TYPE default_bracket_ind_tbl   is TABLE OF VARCHAR2(1)    INDEX BY BINARY_INTEGER;
   TYPE loc_tbl                   is TABLE OF NUMBER(10)     INDEX BY BINARY_INTEGER;
   TYPE loc_type_tbl              is TABLE OF VARCHAR2(1)    INDEX BY BINARY_INTEGER;
   TYPE physical_wh_tbl           is TABLE OF NUMBER(10)     INDEX BY BINARY_INTEGER;
   TYPE sup_dept_seq_no_tbl       is TABLE OF NUMBER(10)     INDEX BY BINARY_INTEGER;

   L_supplier_tbl               SUPPLIER_TBL;
   L_country_tbl                COUNTRY_TBL;
   L_item_tbl                   ITEM_TBL;
   L_unit_cost_tbl              UNIT_COST_TBL;
   L_cost_uom_tbl               COST_UOM_TBL;
   L_dept_tbl                   DEPT_TBL;
   L_ref_item_tbl               REF_ITEM_TBL;
   L_vpn_tbl                    VPN_TBL;
   L_converted_cost_tbl         CONVERTED_COST_TBL;
   L_bracket_value1_tbl         BRACKET_VALUE1_TBL;
   L_bracket_value2_tbl         BRACKET_VALUE2_TBL;
   L_default_bracket_ind_tbl    DEFAULT_BRACKET_IND_TBL;
   L_loc_tbl                    LOC_TBL;
   L_loc_type_tbl               LOC_TYPE_TBL;
   L_physical_wh_tbl            PHYSICAL_WH_TBL;
   L_sup_dept_seq_no_tbl        SUP_DEPT_SEQ_NO_TBL;

   L_converted_cost1   NUMBER(20,4);
   L_converted_cost2   NUMBER(20,4);
   L_inserted          VARCHAR2(1)   := 'N';
   L_locs_exist        BOOLEAN       := FALSE;
   L_old_unit_cost     COST_CHANGE_TEMP.UNIT_COST_OLD%TYPE;

   L_vis_detail_locs   VARCHAR2(1)   := 'N';
   ---
   INVALID_MODE        EXCEPTION;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
   L_apply_rp_link     SYSTEM_OPTIONS.TSL_APPLY_RP_LINK%TYPE := NULL;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
   -- 08-May-08 Bahubali D Mod N111 Begin
   L_system_options_row  SYSTEM_OPTIONS%ROWTYPE;
   L_apply_common_prd    SYSTEM_OPTIONS.TSL_COMMON_PRODUCT_IND%TYPE;
   L_origin_country      SYSTEM_OPTIONS.TSL_ORIGIN_COUNTRY%TYPE;
   -- 08-May-08 Bahubali D Mod N111 End
   ---
   cursor C_ITEM_LOC_V is
      select 'X'
        from item_loc il
       where item = I_item
         and (il.loc in (select wh
                           from v_wh
                          where il.loc = wh
                            and il.loc_type = 'W')
          or il.loc in (select store
                          from v_store
                         where il.loc = store
                           and il.loc_type = 'S'));

   cursor C_COST_SUSP_SUP_DETAIL_LOC_V is
      select 'X'
        from cost_susp_sup_detail_loc cssdl,
             v_item_master im
       where cssdl.cost_change       = NVL(I_cost_change,cssdl.cost_change)
         and cssdl.item              = NVL(I_item,cssdl.item)
         and cssdl.supplier          = NVL(I_supplier,cssdl.supplier)
         and cssdl.origin_country_id = NVL(I_origin_country,cssdl.origin_country_id)
         and cssdl.item              = im.item
         and rownum                  = 1
         and (cssdl.loc in (select wh
                              from v_wh
                             where cssdl.loc = wh
                               and cssdl.loc_type = 'W')
          or cssdl.loc in (select store
                             from v_store
                            where cssdl.loc = store
                              and cssdl.loc_type = 'S'));

   cursor C_COST_CHANGE_STORE is
      select cssdl.supplier,
             cssdl.origin_country_id,
             cssdl.item,
             cssdl.loc_type,
             cssdl.loc,
             cssdl.bracket_value1,
             cssdl.bracket_uom1,
             cssdl.default_bracket_ind,
             cssdl.unit_cost,
             cssdl.cost_change_type,
             cssdl.cost_change_value,
             cssdl.recalc_ord_ind,
             cssdl.dept,
             cssdl.sup_dept_seq_no,
             ref_item.ref_item,
             isc.cost_uom,
             isp.vpn
        from cost_susp_sup_detail_loc cssdl,
             v_item_master im,
             item_supp_country isc,
             item_supplier isp,
   	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
       where cssdl.loc_type          = 'S'
         and cssdl.cost_change       = NVL(I_cost_change,cssdl.cost_change)
         and cssdl.item              = NVL(I_item,cssdl.item)
         and cssdl.supplier          = NVL(I_supplier,cssdl.supplier)
         and cssdl.origin_country_id = NVL(I_origin_country,cssdl.origin_country_id)
         and cssdl.item              = im.item
         and cssdl.item              = isc.item
         and cssdl.item              = isp.item
         and cssdl.supplier          = isc.supplier
         and cssdl.supplier          = isp.supplier
         and cssdl.origin_country_id = isc.origin_country_id
         and cssdl.item              = ref_item.item(+)
         and cssdl.loc in (select store
                             from v_store
                            where cssdl.loc = store);
   ---
   cursor C_COST_CHANGE_WH is
      select distinct cssdl.supplier,
                      cssdl.origin_country_id,
                      cssdl.item,
                      cssdl.loc_type,
                      w.physical_wh,
                      cssdl.bracket_value1,
                      cssdl.bracket_uom1,
                      cssdl.bracket_value2,
                      cssdl.default_bracket_ind,
                      cssdl.unit_cost,
                      cssdl.cost_change_type,
                      cssdl.cost_change_value,
                      cssdl.recalc_ord_ind,
                      cssdl.dept,
                      cssdl.sup_dept_seq_no,
                      ref_item.ref_item,
                      isc.cost_uom,
                      isp.vpn
                 from cost_susp_sup_detail_loc cssdl,
                      v_wh w,
                      v_item_master im,
                      item_supp_country isc,
                      item_supplier isp,
           	      (select item_parent item, item ref_item
                         from item_master
                        where primary_ref_item_ind = 'Y'
                          and item_parent IS NOT NULL) ref_item
                where cssdl.loc_type          = 'W'
                  and w.wh                    = cssdl.loc
                  and cssdl.cost_change       = NVL(I_cost_change,cssdl.cost_change)
                  and cssdl.item              = NVL(I_item,cssdl.item)
                  and cssdl.supplier          = NVL(I_supplier,cssdl.supplier)
                  and cssdl.origin_country_id = NVL(I_origin_country,cssdl.origin_country_id)
                  and cssdl.item              = im.item
                  and cssdl.item              = isc.item
                  and cssdl.item              = isp.item
                  and cssdl.supplier          = isc.supplier
                  and cssdl.supplier          = isp.supplier
                  and cssdl.origin_country_id = isc.origin_country_id
                  and cssdl.item              = ref_item.item(+);

   cursor C_COST_CHANGE_LOC_TEMP_V is
      select 'X'
        from item_supp_country_loc iscl,
             v_item_master im,
             item_supplier isp,
             item_supp_country isc
       where iscl.origin_country_id = NVL(I_origin_country,iscl.origin_country_id)
         and iscl.supplier          = NVL(I_supplier,iscl.supplier)
         and iscl.item              = NVL(I_item,iscl.item)
         and iscl.item              = im.item
         and im.status              = 'A'
         and iscl.supplier          = isp.supplier
         and iscl.supplier          = isc.supplier
         and iscl.item              = isp.item
         and iscl.item              = isc.item
         and iscl.origin_country_id = isc.origin_country_id
         and rownum                 = 1
         and (iscl.loc in (select wh
                              from v_wh
                             where iscl.loc = wh
                               and iscl.loc_type = 'W')
          or iscl.loc in (select store
                             from v_store
                            where iscl.loc = store
                              and iscl.loc_type = 'S'))
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
         and NOT (im.pack_ind                   = 'Y'
                  and im.pack_type              = 'V'
                  and im.orderable_ind          = 'Y'
                  and im.tsl_mu_ind             = 'N'
                  and im.simple_pack_ind        = 'N'
                  and NVL(L_apply_rp_link, 'N') = 'Y')
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
         -- 08-May-08 Bahubali D Mod N111 Begin
          and NOT exists ( select 'x' from tsl_common_sups_matrix tcsm
                                     where im.tsl_common_ind        = 'Y'
                                       and im.tsl_primary_country  != L_origin_country
                                       and im.tsl_primary_country is NOT NULL
                                       and tcsm.channel_id in ('1Y','2Y','3Y')
                                       and L_apply_common_prd = 'Y'
                                       and im.item = tcsm.item
                                       and isp.supplier = tcsm.target_supplier)
          -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
          and (im.simple_pack_ind          = 'Y' and im.pack_type = 'V');
          -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End;
          -- 08-May-08 Bahubali D Mod N111 End
   cursor C_FIRST_INSERT is
      select iscl.supplier,
             iscl.origin_country_id,
             iscl.item,
             iscl.loc_type,
             iscl.loc,
             iscl.unit_cost,
             im.dept,
             ref_item.ref_item,
             isc.cost_uom,
             isp.vpn
        from item_supp_country_loc iscl,
             v_item_master im,
             item_supplier isp,
             item_supp_country isc,
   	     (select item_parent item, item ref_item
                from item_master
               where primary_ref_item_ind = 'Y'
                 and item_parent IS NOT NULL) ref_item
       where iscl.loc_type          = 'S'
         and iscl.origin_country_id = NVL(I_origin_country,iscl.origin_country_id)
         and iscl.supplier          = NVL(I_supplier,iscl.supplier)
         and im.item                = NVL(I_item,im.item)
         and iscl.item              = im.item
         and im.status              = 'A'
         and iscl.supplier          = isp.supplier
         and iscl.supplier          = isc.supplier
         and iscl.item              = isp.item
         and iscl.item              = isc.item
         and iscl.origin_country_id = isc.origin_country_id
         and iscl.item              = ref_item.item(+)
         and iscl.loc in (select store
                             from v_store
                            where iscl.loc = store)
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
         and NOT (im.pack_ind                   = 'Y'
                  and im.pack_type              = 'V'
                  and im.orderable_ind          = 'Y'
                  and im.tsl_mu_ind             = 'N'
                  and im.simple_pack_ind        = 'N'
                  and NVL(L_apply_rp_link, 'N') = 'Y')
         -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
         -- 08-May-08 Bahubali D Mod N111 Begin
         and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                   where im.tsl_common_ind        = 'Y'
                                     and im.tsl_primary_country  != L_origin_country
                                     and im.tsl_primary_country is NOT NULL
                                     and tcsm.channel_id in ('1Y','2Y','3Y')
                                     and L_apply_common_prd = 'Y'
                                     and im.item = tcsm.item
                                     and isp.supplier = tcsm.target_supplier)
          -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
          and (im.simple_pack_ind          = 'Y' and im.pack_type = 'V');
          -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End;
          -- 08-May-08 Bahubali D Mod N111 End
   cursor C_SECOND_INSERT is
      select distinct iscl.supplier,
                      iscl.origin_country_id,
                      iscl.item,
                      iscl.loc_type,
                      w.physical_wh,
                      iscl.unit_cost,
                      im.dept,
                      ref_item.ref_item,
                      isc.cost_uom,
                      isp.vpn
                 from v_wh w,
                      item_supp_country_loc iscl,
                      sups s,
                      v_item_master im,
                      item_supplier isp,
                      item_supp_country isc,
         	      (select item_parent item, item ref_item
                         from item_master
                        where primary_ref_item_ind = 'Y'
                          and item_parent IS NOT NULL) ref_item
                 where s.supplier = NVL(I_supplier,s.supplier)
                    and s.supplier = iscl.supplier
                    and s.bracket_costing_ind = 'N'
                    and iscl.loc = w.wh
                    and iscl.loc_type = 'W'
                    and iscl.origin_country_id = NVL(I_origin_country,iscl.origin_country_id)
                    and iscl.item = im.item
                    and im.item = NVL(I_item,im.item)
                    and im.status = 'A'
                    and iscl.supplier = isp.supplier
                    and iscl.supplier = isc.supplier
                    and iscl.item = isp.item
                    and iscl.item = isc.item
                    and iscl.origin_country_id = isc.origin_country_id
                    and iscl.item = ref_item.item(+)
                    -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
                    and NOT (im.pack_ind                   = 'Y'
                             and im.pack_type              = 'V'
                             and im.orderable_ind          = 'Y'
                             and im.tsl_mu_ind             = 'N'
                             and im.simple_pack_ind        = 'N'
                             and NVL(L_apply_rp_link, 'N') = 'Y')
                   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
                   -- 08-May-08 Bahubali D Mod N111 Begin
                   and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                             where im.tsl_common_ind        = 'Y'
                                               and im.tsl_primary_country  != L_origin_country
                                               and im.tsl_primary_country is NOT NULL
                                               and tcsm.channel_id in ('1Y','2Y','3Y')
                                               and L_apply_common_prd = 'Y'
                                               and im.item = tcsm.item
                                               and isp.supplier = tcsm.target_supplier)
                   -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
                   and (im.simple_pack_ind          = 'Y' and im.pack_type = 'V');
                   -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End
                   -- 08-May-08 Bahubali D Mod N111 End
   cursor C_THIRD_INSERT is
      select distinct iscbc.supplier,
                      iscbc.origin_country_id,
                      iscbc.item,
                      iscbc.loc_type,
                      w.physical_wh,
                      iscbc.bracket_value1,
                      iscbc.bracket_value2,
                      iscbc.default_bracket_ind,
                      iscbc.unit_cost,
                      im.dept,
                      ref_item.ref_item,
                      isc.cost_uom,
                      isp.vpn
                 from v_wh w,
                      item_supp_country_bracket_cost iscbc,
                      v_item_master im,
                      item_supplier isp,
                      item_supp_country isc,
   	              (select item_parent item, item ref_item
                         from item_master
                        where primary_ref_item_ind = 'Y'
                          and item_parent IS NOT NULL) ref_item
                where iscbc.location          = w.wh
                  and iscbc.loc_type          = 'W'
                  and iscbc.origin_country_id = NVL(I_origin_country,iscbc.origin_country_id)
                  and iscbc.supplier          = NVL(I_supplier,iscbc.supplier)
                  and iscbc.item              = NVL(I_item,iscbc.item)
                  and iscbc.item              = im.item
                  and im.status               = 'A'
                  and iscbc.supplier          = isp.supplier
                  and iscbc.supplier          = isc.supplier
                  and iscbc.item              = isp.item
                  and iscbc.item              = isc.item
                  and iscbc.origin_country_id = isc.origin_country_id
                  and iscbc.item              = ref_item.item(+)
                  -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
                  and NOT (im.pack_ind                   = 'Y'
                           and im.pack_type              = 'V'
                           and im.orderable_ind          = 'Y'
                           and im.tsl_mu_ind             = 'N'
                           and im.simple_pack_ind        = 'N'
                           and NVL(L_apply_rp_link, 'N') = 'Y')
                  -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
                  -- 08-May-08 Bahubali D Mod N111 Begin
                  and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                            where im.tsl_common_ind        = 'Y'
                                              and im.tsl_primary_country  != L_origin_country
                                              and im.tsl_primary_country is NOT NULL
                                              and tcsm.channel_id in ('1Y','2Y','3Y')
                                              and L_apply_common_prd = 'Y'
                                              and im.item = tcsm.item
                                              and isp.supplier = tcsm.target_supplier)
                  -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
                  and (im.simple_pack_ind          = 'Y' and im.pack_type = 'V');
                  -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End
                  -- 08-May-08 Bahubali D Mod N111 End
   cursor C_FOURTH_INSERT is
      select distinct cssd.supplier,
                      cssd.origin_country_id,
                      cssd.item,
                      iscl.loc_type,
                      w.physical_wh,
                      cssd.bracket_value1,
                      cssd.bracket_value2,
                      cssd.default_bracket_ind,
                      cssd.unit_cost,
                      cssd.dept,
                      cssd.sup_dept_seq_no,
                      ref_item.ref_item,
                      isc.cost_uom,
                      isp.vpn
                 from v_wh w,
                      item_supp_country_loc iscl,
                      cost_susp_sup_detail cssd,
                      v_item_master im,
                      item_supplier isp,
                      item_supp_country isc,
     	              (select item_parent item, item ref_item
                         from item_master
                        where primary_ref_item_ind = 'Y'
                          and item_parent IS NOT NULL) ref_item
                where iscl.loc                = w.wh
                  and iscl.loc_type          = 'W'
                  and cssd.origin_country_id  = iscl.origin_country_id
                  and cssd.origin_country_id  = NVL(I_origin_country,cssd.origin_country_id)
                  and cssd.supplier           = NVL(I_supplier,cssd.supplier)
                  and cssd.item               = NVL(I_item,cssd.item)
                  and iscl.supplier           = cssd.supplier
                  and iscl.item               = cssd.item
                  and cssd.cost_change        = NVL(I_cost_change,cssd.cost_change)
                  and iscl.supplier           = isp.supplier
                  and iscl.supplier           = isc.supplier
                  and iscl.item               = im.item
                  and iscl.item               = isp.item
                  and iscl.item               = isc.item
                  and iscl.origin_country_id  = isc.origin_country_id
                  and iscl.item               = ref_item.item(+)
                  -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
                  and NOT (im.pack_ind                   = 'Y'
                           and im.pack_type              = 'V'
                           and im.orderable_ind          = 'Y'
                           and im.tsl_mu_ind             = 'N'
                           and im.simple_pack_ind        = 'N'
                           and NVL(L_apply_rp_link, 'N') = 'Y')
                  -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
                  -- 08-May-08 Bahubali D Mod N111 Begin
                  and NOT exists (select 'x' from tsl_common_sups_matrix tcsm
                                            where im.tsl_common_ind        = 'Y'
                                              and im.tsl_primary_country  != L_origin_country
                                              and im.tsl_primary_country is NOT NULL
                                              and tcsm.channel_id in ('1Y','2Y','3Y')
                                              and L_apply_common_prd = 'Y'
                                              and im.item = tcsm.item
                                              and isp.supplier = tcsm.target_supplier)
                  -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, Begin
                  and (im.simple_pack_ind          = 'Y' and im.pack_type = 'V');
                  -- ST defect NBS00012501/503, Nitin Kumar, nitin.kumar@in.tesco.com, 29-Apr-2009, End;
                  -- 08-May-08 Bahubali D Mod N111 End
BEGIN
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   Begin
   -- The below function call the removed by Mod N111
   --if SYSTEM_OPTIONS_SQL.TSL_GET_APPLY_RP_LINK(O_error_message,
   --                                            L_apply_rp_link) = FALSE then
   --   return FALSE;
   --end if;
   -- 07-Mar-2008    Wipro/Enabler Sundara Rajan   Mod N53   End
   -- 08-May-08 Bahubali D Mod N111 Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS (O_error_message,
                                             L_system_options_row) = FALSE then
      return FALSE;
   end if;
   ---
   L_apply_rp_link    := L_system_options_row.tsl_apply_rp_link;
   L_apply_common_prd := L_system_options_row.tsl_common_product_ind;
   L_origin_country   := L_system_options_row.tsl_origin_country;
   ---
   -- 08-May-08 Bahubali D Mod N111 End
   --- check in security views if existing
   SQL_LIB.SET_MARK('OPEN','C_ITEM_LOC_V',
                    'ITEM_LOCS',
                    ' Item: '||I_item);
   open C_ITEM_LOC_V;

   SQL_LIB.SET_MARK('OPEN','C_ITEM_LOC_V',
                    'ITEM_LOCS',
                    ' Item: '||I_item);
   fetch C_ITEM_LOC_V into O_v_locs_exist;

   SQL_LIB.SET_MARK('OPEN','C_ITEM_LOC_V',
                    'ITEM_LOCS',
                    ' Item: '||I_item);
   close C_ITEM_LOC_V;

   if O_v_locs_exist = 'N' then
      O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                            'all locations of Cost Change',
                                            I_cost_change,
                                            NULL);
      return FALSE;
   end if;

   ---
   if I_mode = 'NEW' then
      ---
      if I_reason NOT in (1,2,3) then

         SQL_LIB.SET_MARK('OPEN',
                          'C_FIRST_INSERT',
                          'COST_CHANGE_TEMP_LOC',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         open C_FIRST_INSERT;

         SQL_LIB.SET_MARK('FETCH',
                          'C_FIRST_INSERT',
                          'COST_CHANGE_TEMP_LOC',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         fetch C_FIRST_INSERT BULK COLLECT into L_supplier_tbl,
                                                L_country_tbl,
                                                L_item_tbl,
                                                L_loc_type_tbl,
                                                L_loc_tbl,
                                                L_unit_cost_tbl,
                                                L_dept_tbl,
                                                L_ref_item_tbl,
                                                L_cost_uom_tbl,
                                                L_vpn_tbl;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_FIRST_INSERT',
                          'COST_CHANGE_TEMP_LOC',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         close C_FIRST_INSERT;

         if L_item_tbl.first is NOT NULL then

            FOR i in L_item_tbl.first..L_item_tbl.last LOOP
               if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                     L_unit_cost_tbl(i),
                                                     I_item,
                                                     I_supplier,
                                                     I_origin_country,
                                                     'S',
                                                     NULL) = FALSE then
                  return FALSE;
               end if;
               L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
            END LOOP;
            ---
            SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP',
                             'Cost Change: '||to_char(I_cost_change)||
                             ' Supplier: '||to_char(I_supplier)||
                             ' Origin Country: '||I_origin_country||
                             ' Item: '||I_item);

            FORALL i in L_item_tbl.first..L_item_tbl.last
               insert into cost_change_loc_temp (cost_change,
                                                 supplier,
                                                 origin_country_id,
                                                 item,
                                                 loc_type,
                                                 location,
                                                 bracket_value1,
                                                 bracket_uom,
                                                 bracket_value2,
                                                 default_bracket_ind,
                                                 unit_cost_old,
                                                 unit_cost_new,
                                                 recalc_ord_ind,
                                                 dept,
                                                 cost_uom,
                                                 unit_cost_cuom_new,
                                                 unit_cost_cuom_old,
                                                 vpn,
                                                 ref_item)
                                         values (I_cost_change,
                                                 L_supplier_tbl(i),
                                                 L_country_tbl(i),
                                                 L_item_tbl(i),
                                                 L_loc_type_tbl(i),
                                                 L_loc_tbl(i),
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 'N',
                                                 L_unit_cost_tbl(i),
                                                 NULL,
                                                 'N',
                                                 L_dept_tbl(i),
                                                 L_cost_uom_tbl(i),
                                                 NULL,
                                                 L_converted_cost_tbl(i),
                                                 L_vpn_tbl(i),
                                                 L_ref_item_tbl(i));

            if SQL%FOUND then
               L_inserted := 'Y';
            end if;
            ---
         end if;

         SQL_LIB.SET_MARK('OPEN',
                          'C_SECOND_INSERT',
                          'COST_CHANGE_TEMP_LOC',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         open C_SECOND_INSERT;

         SQL_LIB.SET_MARK('FETCH',
                          'C_SECOND_INSERT',
                          'COST_CHANGE_TEMP_LOC',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         fetch C_SECOND_INSERT BULK COLLECT into L_supplier_tbl,
                                                 L_country_tbl,
                                                 L_item_tbl,
                                                 L_loc_type_tbl,
                                                 L_physical_wh_tbl,
                                                 L_unit_cost_tbl,
                                                 L_dept_tbl,
                                                 L_ref_item_tbl,
                                                 L_cost_uom_tbl,
                                                 L_vpn_tbl;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_SECOND_INSERT',
                          'COST_CHANGE_TEMP_LOC',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         close C_SECOND_INSERT;

         if L_item_tbl.first is NOT NULL then
            FOR i in L_item_tbl.first..L_item_tbl.last LOOP
               if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                     L_unit_cost_tbl(i),
                                                     I_item,
                                                     I_supplier,
                                                     I_origin_country,
                                                     'S',
                                                     NULL) = FALSE then
                  return FALSE;
               end if;
               L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
            END LOOP;

            SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP',
                             'Cost Change: '||to_char(I_cost_change)||
                             ' Supplier: '||to_char(I_supplier)||
                             ' Origin Country: '||I_origin_country||
                             ' Item: '||I_item);
            FORALL i in L_item_tbl.first..L_item_tbl.last

            insert into cost_change_loc_temp (cost_change,
                                              supplier,
                                              origin_country_id,
                                              item,
                                              loc_type,
                                              location,
                                              bracket_value1,
                                              bracket_uom,
                                              bracket_value2,
                                              default_bracket_ind,
                                              unit_cost_old,
                                              unit_cost_new,
                                              recalc_ord_ind,
                                              dept,
                                              cost_uom,
                                              unit_cost_cuom_new,
                                              unit_cost_cuom_old,
                                              vpn,
                                              ref_item)
                                      values (I_cost_change,
                                              L_supplier_tbl(i),
                                              L_country_tbl(i),
                                              L_item_tbl(i),
                                              L_loc_type_tbl(i),
                                              L_physical_wh_tbl(i),
                                              NULL,
                                              NULL,
                                              NULL,
                                              'N',
                                              L_unit_cost_tbl(i),
                                              NULL,
                                              'N',
                                              L_dept_tbl(i),
                                              L_cost_uom_tbl(i),
                                              NULL,
                                              L_converted_cost_tbl(i),
                                              L_vpn_tbl(i),
                                              L_ref_item_tbl(i));

            if SQL%FOUND then
               L_inserted := 'Y';
            end if;
            ---
         end if;

         SQL_LIB.SET_MARK('OPEN',
                          'C_THIRD_INSERT',
                          'COST_CHANGE_TEMP_LOC',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         open C_THIRD_INSERT;

         SQL_LIB.SET_MARK('FETCH',
                          'C_THIRD_INSERT',
                          'COST_CHANGE_TEMP_LOC',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         fetch C_THIRD_INSERT BULK COLLECT into L_supplier_tbl,
                                                L_country_tbl,
                                                L_item_tbl,
                                                L_loc_type_tbl,
                                                L_physical_wh_tbl,
                                                L_bracket_value1_tbl,
                                                L_bracket_value2_tbl,
                                                L_default_bracket_ind_tbl,
                                                L_unit_cost_tbl,
                                                L_dept_tbl,
                                                L_ref_item_tbl,
                                                L_cost_uom_tbl,
                                                L_vpn_tbl;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_THIRD_INSERT',
                          'COST_CHANGE_TEMP_LOC',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         close C_THIRD_INSERT;

         if L_item_tbl.first is NOT NULL then

            FOR i in L_item_tbl.first..L_item_tbl.last LOOP
               if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                     L_unit_cost_tbl(i),
                                                     L_item_tbl(i),
                                                     L_supplier_tbl(i),
                                                     L_country_tbl(i),
                                                     'S',
                                                     NULL) = FALSE then
                  return FALSE;
               end if;

               L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
            END LOOP;

            SQL_LIB.SET_MARK('INSERT', NULL,  'COST_CHANGE_LOC_TEMP',
                             'Cost Change: '||to_char(I_cost_change)||
                             ' Supplier: '||to_char(I_supplier)||
                             ' Origin Country: '||I_origin_country||
                             ' Item: '||I_item);

            FORALL i in L_item_tbl.first..L_item_tbl.last

            insert into cost_change_loc_temp (cost_change,
                                              supplier,
                                              origin_country_id,
                                              item,
                                              loc_type,
                                              location,
                                              bracket_value1,
                                              bracket_uom,
                                              bracket_value2,
                                              default_bracket_ind,
                                              unit_cost_old,
                                              unit_cost_new,
                                              recalc_ord_ind,
                                              dept,
                                              cost_uom,
                                              unit_cost_cuom_new,
                                              unit_cost_cuom_old,
                                              vpn,
                                              ref_item)
                                      values (I_cost_change,
                                              L_supplier_tbl(i),
                                              L_country_tbl(i),
                                              L_item_tbl(i),
                                              L_loc_type_tbl(i),
                                              L_physical_wh_tbl(i),
                                              L_bracket_value1_tbl(i),
                                              NULL,
                                              L_bracket_value2_tbl(i),
                                              L_default_bracket_ind_tbl(i),
                                              L_unit_cost_tbl(i),
                                              NULL,
                                              'N',
                                              L_dept_tbl(i),
                                              L_cost_uom_tbl(i),
                                              NULL,
                                              L_converted_cost_tbl(i),
                                              L_vpn_tbl(i),
                                              L_ref_item_tbl(i));
            if SQL%FOUND then
               L_inserted := 'Y';
            end if;

         end if;

      else

         SQL_LIB.SET_MARK('OPEN',
                     'C_FOURTH_INSERT',
                     'COST_CHANGE_TEMP_LOC',
                     'Cost Change: '||to_char(I_cost_change)||
                     ' Supplier: '||to_char(I_supplier)||
                     ' Origin Country: '||I_origin_country||
                     ' Item: '||I_item);
         open C_FOURTH_INSERT;

         SQL_LIB.SET_MARK('FETCH',
                     'C_FOURTH_INSERT',
                     'COST_CHANGE_TEMP_LOC',
                     'Cost Change: '||to_char(I_cost_change)||
                     ' Supplier: '||to_char(I_supplier)||
                     ' Origin Country: '||I_origin_country||
                     ' Item: '||I_item);
         fetch C_FOURTH_INSERT BULK COLLECT into L_supplier_tbl,
                                                 L_country_tbl,
                                                 L_item_tbl,
                                                 L_loc_type_tbl,
                                                 L_physical_wh_tbl,
                                                 L_bracket_value1_tbl,
                                                 L_bracket_value2_tbl,
                                                 L_default_bracket_ind_tbl,
                                                 L_unit_cost_tbl,
                                                 L_dept_tbl,
                                                 L_sup_dept_seq_no_tbl,
                                                 L_ref_item_tbl,
                                                 L_cost_uom_tbl,
                                                 L_vpn_tbl;

         SQL_LIB.SET_MARK('CLOSE',
                     'C_FOURTH_INSERT',
                     'COST_CHANGE_TEMP_LOC',
                     'Cost Change: '||to_char(I_cost_change)||
                     ' Supplier: '||to_char(I_supplier)||
                     ' Origin Country: '||I_origin_country||
                     ' Item: '||I_item);
         close C_FOURTH_INSERT;

         if L_item_tbl.first is NOT NULL then
            FOR i in L_item_tbl.first..L_item_tbl.last LOOP
              if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                    L_unit_cost_tbl(i),
                                                    L_item_tbl(i),
                                                    L_supplier_tbl(i),
                                                    L_country_tbl(i),
                                                    'S',
                                                    NULL) = FALSE then
                 return FALSE;
              end if;
              L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
           END LOOP;
           SQL_LIB.SET_MARK('INSERT', NULL,  'COST_CHANGE_LOC_TEMP',
                            'Cost Change: '||to_char(I_cost_change)||
                            ' Supplier: '||to_char(I_supplier)||
                            ' Origin Country: '||I_origin_country||
                            ' Item: '||I_item);

            FORALL i in L_item_tbl.first..L_item_tbl.last

               insert into cost_change_loc_temp (cost_change,
                                                 supplier,
                                                 origin_country_id,
                                                 item,
                                                 loc_type,
                                                 location,
                                                 bracket_value1,
                                                 bracket_uom,
                                                 bracket_value2,
                                                 default_bracket_ind,
                                                 unit_cost_old,
                                                 unit_cost_new,
                                                 recalc_ord_ind,
                                                 dept,
                                                 sup_dept_seq_no,
                                                 cost_uom,
                                                 unit_cost_cuom_new,
                                                 unit_cost_cuom_old,
                                                 vpn,
                                                 ref_item)
                                         values (I_cost_change,
                                                 L_supplier_tbl(i),
                                                 L_country_tbl(i),
                                                 L_item_tbl(i),
                                                 L_loc_type_tbl(i),
                                                 L_physical_wh_tbl(i),
                                                 L_bracket_value1_tbl(i),
                                                 NULL,
                                                 L_bracket_value2_tbl(i),
                                                 L_default_bracket_ind_tbl(i),
                                                 L_unit_cost_tbl(i),
                                                 0,
                                                 'N',
                                                 L_dept_tbl(i),
                                                 L_sup_dept_seq_no_tbl(i),
                                                 L_cost_uom_tbl(i),
                                                 NULL,
                                                 L_converted_cost_tbl(i),
                                                 L_vpn_tbl(i),
                                                 L_ref_item_tbl(i));
               if SQL%FOUND then
                  L_inserted := 'Y';
               end if;
               ---
         end if;
      end if;
      ---
   elsif I_mode in ('EDIT','VIEW') then
      ---
      SQL_LIB.SET_MARK('OPEN','C_COST_CHANGE_STORE',
                       'COST_SUSP_SUP_DETAIL_LOC',
                       'Cost Change: '||to_char(I_cost_change));
      FOR current_rec in C_COST_CHANGE_STORE LOOP
         if NOT SUPP_ITEM_SQL.GET_COST(O_error_message,
                                       L_old_unit_cost,
                                       current_rec.item,
                                       current_rec.supplier,
                                       current_rec.origin_country_id,
                                       current_rec.loc)  then
            return FALSE;
         end if;
         ---

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               L_old_unit_cost,
                                               current_rec.item,
                                               current_rec.supplier,
                                               current_rec.origin_country_id,
                                               'S',
                                               NULL) = FALSE then
            return FALSE;
         end if;
         L_converted_cost1 := L_old_unit_cost;

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               current_rec.unit_cost,
                                               current_rec.item,
                                               current_rec.supplier,
                                               current_rec.origin_country_id,
                                               'S',
                                               NULL) = FALSE then
            return FALSE;
         end if;
         L_converted_cost2:= current_rec.unit_cost;

         SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         ---
         insert into cost_change_loc_temp (cost_change,
                                           supplier,
                                           origin_country_id,
                                           item,
                                           loc_type,
                                           location,
                                           bracket_value1,
                                           bracket_uom,
                                           default_bracket_ind,
                                           unit_cost_old,
                                           unit_cost_new,
                                           cost_change_type,
                                           cost_change_value,
                                           recalc_ord_ind,
                                           dept,
                                           cost_uom,
                                           unit_cost_cuom_new,
                                           unit_cost_cuom_old,
                                           vpn,
                                           ref_item)
                                   values (I_cost_change,
                                           current_rec.supplier,
                                           current_rec.origin_country_id,
                                           current_rec.item,
                                           current_rec.loc_type,
                                           current_rec.loc,
                                           current_rec.bracket_value1,
                                           current_rec.bracket_uom1,
                                           current_rec.default_bracket_ind,
                                           L_old_unit_cost,
                                           current_rec.unit_cost,
                                           current_rec.cost_change_type,
                                           current_rec.cost_change_value,
                                           current_rec.recalc_ord_ind,
                                           current_rec.dept,
                                           current_rec.cost_uom,
                                           L_converted_cost2,
                                           L_converted_cost1,
                                           current_rec.vpn,
                                           current_rec.ref_item);
         ---
         if SQL%FOUND then
            L_inserted := 'Y';
         end if;
      END LOOP;
      SQL_LIB.SET_MARK('CLOSE','C_COST_CHANGE_STORE',
                       'COST_SUSP_SUP_DETAIL_LOC',
                       'Cost Change: '||to_char(I_cost_change));
      ---
      SQL_LIB.SET_MARK('OPEN','C_COST_CHANGE_WH',
                       'COST_SUSP_SUP_DETAIL_LOC',
                       'Cost Change: '||to_char(I_cost_change));
      FOR current_rec in C_COST_CHANGE_WH LOOP
         ---
         if current_rec.bracket_value1 is NOT NULL then
            if COST_CHANGE_SQL.BC_UNIT_COST (O_error_message,
                                             L_old_unit_cost,
                                             current_rec.supplier,
                                             current_rec.origin_country_id,
                                             current_rec.item,
                                             current_rec.bracket_value1,
                                             current_rec.physical_wh) = FALSE then
               return FALSE;
            end if;
         end if;
         if L_old_unit_cost is null or current_rec.bracket_value1 is NULL then
            if SUPP_ITEM_SQL.GET_COST(O_error_message,
                                          L_old_unit_cost,
                                          current_rec.item,
                                          current_rec.supplier,
                                          current_rec.origin_country_id,
                                          current_rec.physical_wh) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               L_old_unit_cost,
                                               current_rec.item,
                                               current_rec.supplier,
                                               current_rec.origin_country_id,
                                               'S',
                                               NULL) = FALSE then
            return FALSE;
         end if;
         L_converted_cost1 := L_old_unit_cost;

         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               current_rec.unit_cost,
                                               current_rec.item,
                                               current_rec.supplier,
                                               current_rec.origin_country_id,
                                               'S',
                                               NULL) = FALSE then
            return FALSE;
         end if;
         L_converted_cost2:= current_rec.unit_cost;

         SQL_LIB.SET_MARK('INSERT', NULL, 'COST_CHANGE_LOC_TEMP',
                          'Cost Change: '||to_char(I_cost_change)||
                          ' Supplier: '||to_char(I_supplier)||
                          ' Origin Country: '||I_origin_country||
                          ' Item: '||I_item);
         ---
         insert into cost_change_loc_temp (cost_change,
                                           supplier,
                                           origin_country_id,
                                           item,
                                           loc_type,
                                           location,
                                           bracket_value1,
                                           bracket_uom,
                                           bracket_value2,
                                           default_bracket_ind,
                                           unit_cost_old,
                                           unit_cost_new,
                                           cost_change_type,
                                           cost_change_value,
                                           recalc_ord_ind,
                                           dept,
                                           sup_dept_seq_no,
                                           cost_uom,
                                           unit_cost_cuom_new,
                                           unit_cost_cuom_old,
                                           vpn,
                                           ref_item)
                                   values (I_cost_change,
                                           current_rec.supplier,
                                           current_rec.origin_country_id,
                                           current_rec.item,
                                           current_rec.loc_type,
                                           current_rec.physical_wh,
                                           current_rec.bracket_value1,
                                           current_rec.bracket_uom1,
                                           current_rec.bracket_value2,
                                           current_rec.default_bracket_ind,
                                           L_old_unit_cost,
                                           current_rec.unit_cost,
                                           current_rec.cost_change_type,
                                           current_rec.cost_change_value,
                                           current_rec.recalc_ord_ind,
                                           current_rec.dept,
                                           current_rec.sup_dept_seq_no,
                                           current_rec.cost_uom,
                                           L_converted_cost2,
                                           L_converted_cost1,
                                           current_rec.vpn,
                                           current_rec.ref_item);
         ---
         if SQL%FOUND then
            L_inserted := 'Y';
         end if;
      END LOOP;
      SQL_LIB.SET_MARK('CLOSE','C_COST_CHANGE_WH',
                       'COST_SUSP_SUP_DETAIL_LOC',
                       'Cost Change: '||to_char(I_cost_change));
      --- Check if Locations are inserted
      if L_inserted = 'N' then
      --- Call procedure again in new mode for cost changes maintained at the country level
         if NOT COST_CHANGE_SQL.POP_TEMP_DETAIL_LOC_SEC(O_error_message,
                                                        L_locs_exist,
                                                        O_v_locs_exist,
                                                        'NEW',
                                                        I_cost_change,
                                                        I_supplier,
                                                        I_origin_country,
                                                        I_item,
                                                        I_reason ) then
            return FALSE;
         end if;
         ---
         if L_locs_exist then
            L_inserted := 'Y';
         end if;
      end if;
   else raise INVALID_MODE;
   end if; -- I_mode NEW/EDIT,VIEW

   if L_inserted = 'Y' then

      DECLARE
         cursor C_CCT
             is
         select *
           from cost_change_temp      cct
          where cct.cost_change       = I_cost_change
            and cct.supplier          = I_supplier
            and cct.origin_country_id = I_origin_country
            and cct.item              = I_item;
      BEGIN
         for c_cct_row in C_CCT loop
            -- no need to lock, because the rows to be updated have been inserted but not committed
            update cost_change_loc_temp    cclt
               set cclt.unit_cost_new      = Nvl(c_cct_row.unit_cost_new     ,cclt.unit_cost_new),
                   cclt.unit_cost_cuom_new = Nvl(c_cct_row.unit_cost_cuom_new,cclt.unit_cost_cuom_new)
             where cclt.cost_change        = c_cct_row.cost_change
               and cclt.supplier           = c_cct_row.supplier
               and cclt.origin_country_id  = c_cct_row.origin_country_id
               and cclt.item               = c_cct_row.item;
         end loop;
      END;

      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when INVALID_MODE then
      O_error_message := SQL_LIB.CREATE_MSG('INV_MODE', NULL, NULL, NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END POP_TEMP_DETAIL_LOC_SEC;
------------------------------------------------------------------------------------------

FUNCTION CHECK_COST_CHANGE_ORIGIN (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_update_to_sup    IN OUT   BOOLEAN,
                                   I_cost_change_no   IN       COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS

   L_item_count   NUMBER(10) := 0;
   L_loc_count    NUMBER(10) := 0;

   cursor C_CHECK_DISTINCT_ITEMS is
      select (select count(distinct(item))
                from cost_change_temp ct
               where ct.cost_change = ch.cost_change) item_count,
             (select count(distinct(item))
                from cost_change_loc_temp cl
               where cl.cost_change = ch.cost_change) loc_count
        from cost_susp_sup_head ch
       where ch.cost_change = I_cost_change_no
         and ch.cost_change_origin = 'SKU';

BEGIN
   if I_cost_change_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_cost_change_no',
                                            'COST_CHANGE_SQL.CHECK_COST_CHANGE_ORIGIN',
                                             NULL);
      return FALSE;
   end if;
   O_update_to_sup := FALSE;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_DISTINCT_ITEMS',
                    'COST_SUSP_SUP_HEAD',
                    'cost_change: '||I_cost_change_no);
   open C_CHECK_DISTINCT_ITEMS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_DISTINCT_ITEMS',
                    'COST_SUSP_SUP_HEAD',
                    'cost_change: '||I_cost_change_no);
   fetch C_CHECK_DISTINCT_ITEMS into L_item_count,
                                     L_loc_count;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_DISTINCT_ITEMS',
                    'COST_SUSP_SUP_HEAD',
                    'cost_change: '||I_cost_change_no);
   close C_CHECK_DISTINCT_ITEMS;

   if (L_item_count + L_loc_count) > 1 then
      O_update_to_sup := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'COST_CHANGE_SQL.CHECK_COST_CHANGE_ORIGIN',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_COST_CHANGE_ORIGIN;
--------------------------------------------------------------------------------------
FUNCTION RECALC_ORD_IND_STATUS (O_error_message 	IN OUT 	VARCHAR2,
 				O_recalc_ord_ind_status OUT 	COST_SUSP_SUP_DETAIL_LOC.RECALC_ORD_IND%TYPE,
                          	I_cost_change   	IN     	COST_SUSP_SUP_DETAIL_LOC.COST_CHANGE%TYPE)
   RETURN BOOLEAN IS

   L_recalc_ord_ind_status      COST_SUSP_SUP_DETAIL_LOC.RECALC_ORD_IND%TYPE := 'N';

   cursor C_RECALC_ORD_IND_STATUS is
      select RECALC_ORD_IND
        from COST_SUSP_SUP_DETAIL_LOC
       where COST_CHANGE = I_cost_change
         for update nowait;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_RECALC_ORD_IND_STATUS','COST_SUSP_SUP_DETAIL_LOC', 'cost_change: '||to_char(I_cost_change));
   open C_RECALC_ORD_IND_STATUS;

   SQL_LIB.SET_MARK('FETCH','C_RECALC_ORD_IND_STATUS','COST_SUSP_SUP_DETAIL_LOC', 'cost_change: '||to_char(I_cost_change));
   fetch C_RECALC_ORD_IND_STATUS into L_recalc_ord_ind_status;

   SQL_LIB.SET_MARK('CLOSE','C_RECALC_ORD_IND_STATUS','COST_SUSP_SUP_DETAIL_LOC', 'cost_change: '||to_char(I_cost_change));
   close C_RECALC_ORD_IND_STATUS;

   O_recalc_ord_ind_status := L_recalc_ord_ind_status;
   ---
   return TRUE;

EXCEPTION
    when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                             SQLERRM,
                                            'COST_CHANGE_SQL.RECALC_ORD_IND_STATUS',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END RECALC_ORD_IND_STATUS;
--------------------------------------------------------------------------------------
-- 26.02.2008, ORMS 364.2,Richard Addison(BEGIN)
--------------------------------------------------------------------------------------------
--Function:  TSL_APPLY_REAL_TIME_COSTCHG
--Purpose:   When cost changes are approved or moved out of approved status, the cost change
--           form will make a call to this function which will loop through all detail records
--           of the cost change and update TSL_FUTURE_COST for the components of any
--           primary pack/supplier./country combinations.
--------------------------------------------------------------------------------------------
FUNCTION TSL_APPLY_REAL_TIME_COSTCHG (O_error_message IN OUT VARCHAR2,
                                      I_cost_change   IN     COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE)

   RETURN BOOLEAN IS

   L_item      ITEM_MASTER.ITEM%TYPE;

   cursor C_COST_SUSP_SUP_DETAIL is
      SELECT item,
             supplier,
             origin_country_id
        FROM cost_susp_sup_detail
       WHERE cost_change = I_cost_change;
BEGIN
  --
  for rec in C_COST_SUSP_SUP_DETAIL LOOP
      if TSL_MARGIN_SQL.CHECK_PRIMARY_PACK_SUPP_CNTRY( O_error_message,
                                                       L_item,
                                                       rec.item,
                                                       rec.supplier,
                                                       rec.origin_country_id) = FALSE then
         return FALSE;
      end if;
      if L_item IS NOT NULL then
         --
         -- We have a primary pack / supplier / country.
         -- Update the pack's component costs.
         --
         O_error_message := ' ';
         if (TSL_APPLY_REAL_TIME_COST(O_error_message,
                                      L_item,
                                      'Y',
   -- 26-Aug-2008 Tesco HSC/Satish B.N DefNBS007325 Begin
                                      'O') != 0) then
   -- 26-Aug-2008 Tesco HSC/Satish B.N DefNBS007325 End
            return FALSE;
         end if;
      end if;
   end loop;
   ---
   return TRUE;

EXCEPTION
    when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                             SQLERRM,
                                            'COST_CHANGE_SQL.TSL_APPLY_REAL_TIME_COST',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END TSL_APPLY_REAL_TIME_COSTCHG;
-- 26.02.2008, ORMS 364.2, Richard Addison (END)
---------------------------------------------------------------------------------------------------
-- CR332 01-Nov-2010 Accenture/Merlyn Mathew Merlyn.Mathew@in.tesco.com Begin
---------------------------------------------------------------------------------------------------
--Function:  TSL_POP_FOR_STYLE_REF_CODE
--Purpose:   To populate cost_change_temp table with packs that have the
--           input style reference code
---------------------------------------------------------------------------------------------------
FUNCTION TSL_POP_FOR_STYLE_REF_CODE(O_error_message  IN OUT VARCHAR2,
                                    O_exists         IN OUT BOOLEAN,
                                    I_mode           IN     VARCHAR2,
                                    I_cost_change    IN     COST_CHANGE_TEMP.COST_CHANGE%TYPE,
                                    I_supplier       IN     SUPS.SUPPLIER%TYPE,
                                    I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE,
                                    I_style_ref_code IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
   RETURN BOOLEAN IS

   L_program        VARCHAR2(50) := 'COST_CHANGE_SQL.TSL_POP_FOR_STYLE_REF_CODE';
   L_exists         BOOLEAN;

    cursor C_EXPLODE_STYLE_REF_CODE is
    select im.item
      from item_master im,
           item_supplier isp
      where im.item_desc_secondary= I_style_ref_code
        and im.status = 'A'
        and (im.simple_pack_ind = 'Y'
             and im.pack_type   = 'V')
        and item_level = 1
        and tran_level = 1
        and im.item = isp.item
        and NOT (im.pack_ind                   = 'Y'
                 and im.pack_type              = 'V'
                 and im.orderable_ind          = 'Y'
                 and im.tsl_mu_ind             = 'N'
                 and im.simple_pack_ind        = 'N')
                 and EXISTS(select 'X'
                            from item_supp_country isc
                           where isc.supplier = I_supplier
                             and isc.origin_country_id = NVL(I_origin_country, isc.origin_country_id)
                             and isc.SUPPLIER = isp.supplier
                             and isc.item = im.item)
        order by im.item;

BEGIN

   FOR itemlist in C_EXPLODE_STYLE_REF_CODE
   LOOP
      if not POP_TEMP_DETAIL(O_error_message,
                             L_exists,
                             I_mode,
                             I_cost_change,
                             I_supplier,
                             I_origin_country,
                             itemlist.item) then
         return FALSE;
      end if;
      if L_exists = FALSE then
         O_exists := FALSE;
      else
         O_exists := TRUE;
      end if;
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
END TSL_POP_FOR_STYLE_REF_CODE;
---------------------------------------------------------------------------------------------------
-- CR332 01-Nov-2010 Accenture/Merlyn Mathew Merlyn.Mathew@in.tesco.com End
---------------------------------------------------------------------------------------------------
END COST_CHANGE_SQL;
/

