CREATE OR REPLACE PACKAGE BODY ITEM_SUPP_COUNTRY_LOC_SQL AS
----------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Ramasamy
--Mod Date:    04-Jun-2007
--Mod Ref:     Mod number. 365b
--Mod Details: Amended script to explodes the base varient item information.
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--Mod By:      Neeraj
--Mod Date:    29-05-2009
--Mod Ref:     Retrofit Patch for SR7406689.994
--Mod Details: Applied new code from Oracle for the SR
------------------------------------------------------------------------------------------------
--Mod By:      Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com
--Mod Date:    02-12-2010
--Mod Ref:     DefNBS0019964
--Mod Details: Modified in DEFAULT_LOCATION_TO_CHILDREN function.
------------------------------------------------------------------------------------------------
--Mod By:      Gary Sandler
--Mod Date:    21-11-2011
--Mod Ref:     PrfNBS023626b
--Mod Details: Modified C_GET_MIN_ISC_LOC  cursor to replace MIN with rownum =1 as there is no
--             meaning in the store number. This will improve performance of ASN Out processing.
------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
   LP_multichannel_ind   SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE := NULL;

   TYPE ROWID_TBL IS TABLE OF ROWID;

-------------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------------------------------
-- Function Name: LOCK_ITEM_SUPP_COUNTRY_LOC
-- Purpose      : This function will lock the ITEM_SUPP_COUNTRY table for update or delete.
-------------------------------------------------------------------------------------------------------
FUNCTION LOCK_ITEM_SUPP_COUNTRY_LOC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item          IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                                    I_supplier      IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                                    I_country       IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                                    I_loc           IN     ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
   RETURN BOOLEAN;
-----------------------------------------------------------------------------------------------
FUNCTION LOC_EXISTS(O_error_message     IN OUT VARCHAR2,
                    O_exists            IN OUT BOOLEAN,
                    I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                    I_supplier          IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                    I_origin_country_id IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                    I_loc               IN     ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(62) := 'ITEM_SUPP_COUNTRY_LOC_SQL.LOC_EXISTS';
   L_exists    VARCHAR2(1)  := 'N';

   cursor C_EXISTS is
      select 'Y'
        from item_supp_country_loc
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country_id
         and loc               = I_loc
         and rownum = 1;
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
   if I_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_loc',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_EXISTS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id
                    ||' Location: '|| I_Loc);
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_EXISTS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id
                    ||' Location: '|| I_Loc);
   fetch C_EXISTS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_EXISTS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id
                    ||' Location: '|| I_Loc);
   close C_EXISTS;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
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
-----------------------------------------------------------------------------------------------
FUNCTION CREATE_LOCATION(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                         I_supplier          IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                         I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                         I_loc               IN     ITEM_LOC.LOC%TYPE,
                         I_like_store        IN     ITEM_LOC.LOC%TYPE,
                         I_loc_type          IN     ITEM_LOC.LOC_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_LOC_SQL.CREATE_LOC';
   L_table         VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY_LOC';
   L_min_loc       ITEM_SUPP_COUNTRY_LOC.LOC%TYPE;
   L_buyer_pack    VARCHAR2(1)    := 'N';
   L_update        VARCHAR2(1)    := NULL;
   L_all_locs      VARCHAR2(1);
   L_dept          ITEM_MASTER.DEPT%TYPE;
   L_exists        BOOLEAN;
   L_bc_ind        SYSTEM_OPTIONS.BRACKET_COSTING_IND%TYPE;
   L_pack_type     ITEM_MASTER.PACK_TYPE%TYPE;

-- 29-May-2009:Neeraj:Retrofit for SR7406689.994 :BEGIN
   TAB_rowids      ROWID_TBL; --- Type declared at package level
-- 29-May-2009:Neeraj:Retrofit for SR7406689.994 :END

   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_GET_DEPT is
      select dept
        from item_master
       where item = I_item;

-- 21-Nov-2011: Gary Sandler PrfDef02323626
   cursor C_GET_MIN_ISC_LOC is
      select isl.loc
        from item_supp_country_loc isl
       where isl.item = I_item
         and rownum = 1;

-- 29-May-2009:Neeraj:Retrofit for SR7406689.994 :BEGIN
cursor C_GET_PRIM_ISC_LOC is
      select 'N'
        from item_supp_country_loc iscl
       where iscl.item              = I_item
         and iscl.supplier          = NVL(I_supplier, iscl.supplier)
         and iscl.origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and primary_loc_ind        = 'Y'
         and rownum = 1;
-- 29-May-2009:Neeraj:Retrofit for SR7406689.994 :END

   cursor C_UPDATE_PRIM_LOC_IND is
      select rowid
        from item_supp_country_loc isl
       where isl.loc               = L_min_loc
         and isl.item              = I_item
         and isl.supplier          = NVL(I_supplier, supplier)
         and isl.origin_country_id = NVL(I_origin_country_id, origin_country_id)
         -- 29-May-2009:Neeraj:Retrofit for SR7406689.994 :BEGIN

        -- and not exists (select 'x'
         --                  from item_supp_country_loc isl3
          --                where isl3.loc              != L_min_loc
          --                  and isl3.item              = isl.item
          --                  and isl3.supplier          = NVL(I_supplier, supplier)
          --                  and isl3.origin_country_id = NVL(I_origin_country_id, ------ origin_country_id)
          --                  and isl3.primary_loc_ind   = 'Y')

          -- 29-May-2009:Neeraj:Retrofit for SR7406689.994 :END

          for update nowait;

   cursor C_ITEM_PACK_TYPE is
      select nvl(pack_type,'N')
        from item_master
       where item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if not SYSTEM_OPTIONS_SQL.GET_BRACKET_COST_IND(O_error_message,
                                                  L_bc_ind) then
      return FALSE;
   end if;
   ---
   if I_like_store IS NULL then
      SQL_LIB.SET_MARK('OPEN','C_GET_DEPT','ITEM_MASTER','Item: '||I_item);
      open C_GET_DEPT;
      SQL_LIB.SET_MARK('FETCH','C_GET_DEPT','ITEM_MASTER','Item: '||I_item);
      fetch C_GET_DEPT into L_dept;
      SQL_LIB.SET_MARK('CLOSE','C_GET_DEPT','ITEM_MASTER','Item: '||I_item);
      close C_GET_DEPT;
      ---
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);

	  if I_loc_type = 'S' then
	     insert into item_supp_country_loc(item,
                                           supplier,
                                           origin_country_id,
                                           loc,
                                           loc_type,
                                           primary_loc_ind,
                                           unit_cost,
                                           round_lvl,
                                           round_to_inner_pct,
                                           round_to_case_pct,
                                           round_to_layer_pct,
                                           round_to_pallet_pct,
                                           supp_hier_type_1,
                                           supp_hier_lvl_1,
                                           supp_hier_type_2,
                                           supp_hier_lvl_2,
                                           supp_hier_type_3,
                                           supp_hier_lvl_3,
                                           pickup_lead_time,
                                           create_datetime,
                                           last_update_datetime,
                                           last_update_id)
								    select I_item,
                                           isc.supplier,
                                           isc.origin_country_id,
                                           I_loc,
                                           I_loc_type,
                                           'N',
                                           isc.unit_cost,
                                           isc.round_lvl,
                                           isc.round_to_inner_pct,
                                           isc.round_to_case_pct,
                                           isc.round_to_layer_pct,
                                           isc.round_to_pallet_pct,
                                           isc.supp_hier_type_1,
                                           isc.supp_hier_lvl_1,
                                           isc.supp_hier_type_2,
                                           isc.supp_hier_lvl_2,
                                           isc.supp_hier_type_3,
                                           isc.supp_hier_lvl_3,
                                           isc.pickup_lead_time,
                                           sysdate,
                                           sysdate,
                                           user
                                      from sups s,
									       item_supp_country isc
                                     where isc.item = I_item
                                       and isc.supplier = NVL(I_supplier, isc.supplier)
                                       and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id)
                                       and s.supplier = isc.supplier
                                       and (I_loc_type = 'S' or s.inv_mgmt_lvl in ('S', 'D'))
                                       and not exists(select 'x'
                                                        from item_supp_country_loc isl
                                                       where isl.item              = I_item
                                                         and isl.loc               = I_loc
                                                         and isl.supplier          = isc.supplier
                                                         and isl.origin_country_id = isc.origin_country_id
														 and rownum = 1);
	  else

	     insert into item_supp_country_loc(item,
                                           supplier,
                                           origin_country_id,
                                           loc,
                                           loc_type,
                                           primary_loc_ind,
                                           unit_cost,
                                           round_lvl,
                                           round_to_inner_pct,
                                           round_to_case_pct,
                                           round_to_layer_pct,
                                           round_to_pallet_pct,
                                           supp_hier_type_1,
                                           supp_hier_lvl_1,
                                           supp_hier_type_2,
                                           supp_hier_lvl_2,
                                           supp_hier_type_3,
                                           supp_hier_lvl_3,
                                           pickup_lead_time,
                                           create_datetime,
                                           last_update_datetime,
                                           last_update_id)
                                    select I_item,
                                           isc.supplier,
                                           isc.origin_country_id,
                                           I_loc,
                                           'W',
                                           'N',
                                           isc.unit_cost,
                                           sim.round_lvl,
                                           sim.round_to_inner_pct,
                                           sim.round_to_case_pct,
                                           sim.round_to_layer_pct,
                                           sim.round_to_pallet_pct,
                                           isc.supp_hier_type_1,
                                           isc.supp_hier_lvl_1,
                                           isc.supp_hier_type_2,
                                           isc.supp_hier_lvl_2,
                                           isc.supp_hier_type_3,
                                           isc.supp_hier_lvl_3,
                                           isc.pickup_lead_time,
                                           sysdate,
                                           sysdate,
                                           user
                                      from item_supp_country isc,
                                           sups s,
                                           sup_inv_mgmt sim,
                                           wh w
                                     where isc.item = I_item
                                       and isc.supplier = NVL(I_supplier, isc.supplier)
                                       and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id)
                                       and s.supplier = isc.supplier
                                       and s.inv_mgmt_lvl = 'A'
                                       and w.wh = I_loc
                                       and sim.supplier = isc.supplier
                                       and sim.dept     = L_dept
                                       and sim.location = w.physical_wh
                                       and not exists(select 'x'
                                                        from item_supp_country_loc isl
                                                       where isl.item              = I_item
                                                         and isl.loc               = I_loc
                                                         and isl.supplier          = isc.supplier
                                                         and isl.origin_country_id = isc.origin_country_id
														 and rownum = 1)
                                    UNION ALL
                                    select I_item,
                                           isc.supplier,
                                           isc.origin_country_id,
                                           I_loc,
                                           'W',
                                           'N',
                                           isc.unit_cost,
                                           sim.round_lvl,
                                           sim.round_to_inner_pct,
                                           sim.round_to_case_pct,
                                           sim.round_to_layer_pct,
                                           sim.round_to_pallet_pct,
                                           isc.supp_hier_type_1,
                                           isc.supp_hier_lvl_1,
                                           isc.supp_hier_type_2,
                                           isc.supp_hier_lvl_2,
                                           isc.supp_hier_type_3,
                                           isc.supp_hier_lvl_3,
                                           isc.pickup_lead_time,
                                           sysdate,
                                           sysdate,
                                           user
                                      from item_supp_country isc,
                                           sups s,
                                           sup_inv_mgmt sim,
                                           wh w
                                     where isc.item = I_item
                                       and isc.supplier = NVL(I_supplier, isc.supplier)
                                       and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id)
                                       and s.supplier = isc.supplier
                                       and s.inv_mgmt_lvl = 'L'
                                       and w.wh = I_loc
                                       and sim.supplier = isc.supplier
                                       and sim.dept is NULL
                                       and sim.location = w.physical_wh
                                       and not exists(select 'x'
                                                        from item_supp_country_loc isl
                                                       where isl.item              = I_item
                                                         and isl.loc               = I_loc
                                                         and isl.supplier          = isc.supplier
                                                         and isl.origin_country_id = isc.origin_country_id
														 and rownum = 1)
                                    UNION ALL
                                    select I_item,
                                           isc.supplier,
                                           isc.origin_country_id,
                                           I_loc,
                                           'W',
                                           'N',
                                           isc.unit_cost,
                                           isc.round_lvl,
                                           isc.round_to_inner_pct,
                                           isc.round_to_case_pct,
                                           isc.round_to_layer_pct,
                                           isc.round_to_pallet_pct,
                                           isc.supp_hier_type_1,
                                           isc.supp_hier_lvl_1,
                                           isc.supp_hier_type_2,
                                           isc.supp_hier_lvl_2,
                                           isc.supp_hier_type_3,
                                           isc.supp_hier_lvl_3,
                                           isc.pickup_lead_time,
                                           sysdate,
                                           sysdate,
                                           user
                                      from item_supp_country isc,
                                           wh w,
                                           sups s
                                     where isc.item = I_item
                                       and w.wh = I_loc
                                       and isc.supplier = NVL(I_supplier, isc.supplier)
                                       and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id)
                                       and s.supplier = isc.supplier
                                       and (  (I_loc_type = 'W' and s.inv_mgmt_lvl = 'A'
                                               and not exists(select 'x'
                                                                from sup_inv_mgmt sim2
                                                                where sim2.supplier = isc.supplier
                                                                 and sim2.dept     = L_dept
                                                                 and sim2.location = w.physical_wh
													     		 and rownum = 1))
                                           or (I_loc_type = 'W' and s.inv_mgmt_lvl = 'L'
                                               and not exists(select 'x'
                                                                from sup_inv_mgmt sim2
                                                               where sim2.supplier = isc.supplier
                                                                 and sim2.location = w.physical_wh
															     and rownum = 1)))
                                       and not exists(select 'x'
                                                        from item_supp_country_loc isl
                                                       where isl.item              = I_item
                                                         and isl.loc               = I_loc
                                                         and isl.supplier          = isc.supplier
                                                         and isl.origin_country_id = isc.origin_country_id
														 and rownum = 1)
                                    UNION ALL
                                    select I_item,
                                           isc.supplier,
                                           isc.origin_country_id,
                                           I_loc,
                                           I_loc_type,
                                           'N',
                                           isc.unit_cost,
                                           isc.round_lvl,
                                           isc.round_to_inner_pct,
                                           isc.round_to_case_pct,
                                           isc.round_to_layer_pct,
                                           isc.round_to_pallet_pct,
                                           isc.supp_hier_type_1,
                                           isc.supp_hier_lvl_1,
                                           isc.supp_hier_type_2,
                                           isc.supp_hier_lvl_2,
                                           isc.supp_hier_type_3,
                                           isc.supp_hier_lvl_3,
                                           isc.pickup_lead_time,
                                           sysdate,
                                           sysdate,
                                           user
                                      from item_supp_country isc,
                                           sups s
                                     where isc.item = I_item
                                       and isc.supplier = NVL(I_supplier, isc.supplier)
                                       and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id)
                                       and s.supplier = isc.supplier
                                       and (s.inv_mgmt_lvl in ('S', 'D'))
                                       and not exists(select 'x'
                                                        from item_supp_country_loc isl
                                                       where isl.item              = I_item
                                                         and isl.loc               = I_loc
                                                         and isl.supplier          = isc.supplier
                                                         and isl.origin_country_id = isc.origin_country_id);
	  end if;

      ---
      -- The minimum lowest location number will be selected to be the primary location on mass inserts.
      ---
      L_update := 'Y';
          ---


     SQL_LIB.SET_MARK('OPEN','C_GET_MIN_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: ----'||I_item);
     open C_GET_MIN_ISC_LOC;
      SQL_LIB.SET_MARK('FETCH','C_GET_MIN_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
     fetch C_GET_MIN_ISC_LOC into L_min_loc;

     if C_GET_MIN_ISC_LOC%NOTFOUND then
     L_update := 'N';
     end if;

    SQL_LIB.SET_MARK('CLOSE','C_GET_MIN_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
     close C_GET_MIN_ISC_LOC;

        --  29-May-2009:Neeraj:Retrofit for SR7406689.994 :BEGIN

       -- SQL_LIB.SET_MARK('OPEN','C_GET_PRIM_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      --open C_GET_PRIM_ISC_LOC;
      --SQL_LIB.SET_MARK('FETCH','C_GET_PRIM_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      --fetch C_GET_PRIM_ISC_LOC into L_update;
      ---
      --SQL_LIB.SET_MARK('CLOSE','C_GET_PRIM_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
     -- close C_GET_PRIM_ISC_LOC;

      SQL_LIB.SET_MARK('OPEN','C_GET_PRIM_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      open C_GET_PRIM_ISC_LOC;
      SQL_LIB.SET_MARK('FETCH','C_GET_PRIM_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      fetch C_GET_PRIM_ISC_LOC into L_update;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_GET_PRIM_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      close C_GET_PRIM_ISC_LOC;


     if L_update = 'Y' then

   SQL_LIB.SET_MARK('OPEN','C_GET_MIN_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
         open C_GET_MIN_ISC_LOC;
         SQL_LIB.SET_MARK('FETCH','C_GET_MIN_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
         fetch C_GET_MIN_ISC_LOC into L_min_loc;
         ---
         if C_GET_MIN_ISC_LOC%NOTFOUND then
            L_min_loc := -1;
         end if;
         ---
         SQL_LIB.SET_MARK('CLOSE','C_GET_MIN_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
         close C_GET_MIN_ISC_LOC;

         if L_min_loc > 0 then
            SQL_LIB.SET_MARK('OPEN','C_UPDATE_PRIM_LOC_IND','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
            open C_UPDATE_PRIM_LOC_IND;

            SQL_LIB.SET_MARK('FETCH','C_UPDATE_PRIM_LOC_IND','item',null);
            fetch C_UPDATE_PRIM_LOC_IND BULK COLLECT into TAB_rowids;

            SQL_LIB.SET_MARK('CLOSE','C_UPDATE_PRIM_LOC_IND','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
            close C_UPDATE_PRIM_LOC_IND;
            ---
            SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);

            if TAB_rowids is NOT NULL and TAB_rowids.COUNT > 0 then
               FORALL i in TAB_rowids.FIRST..TAB_rowids.LAST
                  update item_supp_country_loc isl
                     set primary_loc_ind      = 'Y',
                         last_update_datetime = sysdate,
                         last_update_id       = user
                   where rowid = TAB_rowids(i);
               TAB_rowids.delete;
            end if;
         end if; -- if L_min_loc > 0
      end if; -- if L_update = 'Y'
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_ITEM_PACK_TYPE','ITEM_MASTER','Item: '||I_item);
      open C_ITEM_PACK_TYPE;
      SQL_LIB.SET_MARK('FETCH', 'C_ITEM_PACK_TYPE','ITEM_MASTER','Item: '||I_item);
      fetch C_ITEM_PACK_TYPE into L_pack_type;
      SQL_LIB.SET_MARK('CLOSE','C_ITEM_PACK_TYPE','ITEM_MASTER','Item: '||I_item);
      close C_ITEM_PACK_TYPE;
      ---
      if L_pack_type = 'B' then
         SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC','ITEM: '||I_item);
         update item_supp_country_loc isc1
            set isc1.unit_cost            = ( select NVL(sum(isc2.unit_cost * vpq.qty), isc1.unit_cost)
                                                from item_supp_country_loc isc2,
                                                     v_packsku_qty vpq
                                               where vpq.pack_no            = I_item
                                                 and isc2.item              = vpq.item
                                                 and isc2.supplier          = isc1.supplier
                                                 and isc2.origin_country_id = isc1.origin_country_id
                                                 and isc2.loc               = isc1.loc ),
                isc1.last_update_id       = user,
                isc1.last_update_datetime = sysdate
          where isc1.item = I_item
            and exists (select 'x'
                          from item_supp_country_loc isc3,
                               v_packsku_qty vpq
                         where vpq.pack_no            = I_item
                           and isc3.item              = vpq.item
                           and isc3.supplier          = isc1.supplier
                           and isc3.origin_country_id = isc1.origin_country_id
                           and isc3.loc               = isc1.loc );
      end if;

--29-May-2009:Neeraj:Retrofit for SR7406689.994 :END

      if I_loc is NOT NULL then
         L_all_locs := 'N';
      else
         L_all_locs := 'Y';
      end if;
      ---
      if L_bc_ind = 'Y' then
		 if ITEM_BRACKET_COST_SQL.CREATE_BRACKET(O_error_message,
	                                             I_item,
	                                             I_supplier,
	                                             I_origin_country_id,
	                                             I_loc,
	                                             L_all_locs) = FALSE then
	        return FALSE;
	     end if;
	  end if;
	  ---
   else  -- I_like_store IS NOT NULL --
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      insert into item_supp_country_loc(item,
                                        supplier,
                                        origin_country_id,
                                        loc,
                                        loc_type,
                                        primary_loc_ind,
                                        unit_cost,
                                        round_lvl,
                                        round_to_inner_pct,
                                        round_to_case_pct,
                                        round_to_layer_pct,
                                        round_to_pallet_pct,
                                        supp_hier_type_1,
                                        supp_hier_lvl_1,
                                        supp_hier_type_2,
                                        supp_hier_lvl_2,
                                        supp_hier_type_3,
                                        supp_hier_lvl_3,
                                        pickup_lead_time,
                                        create_datetime,
                                        last_update_datetime,
                                        last_update_id)
                                 select I_item,
                                        iscl.supplier,
                                        iscl.origin_country_id,
                                        I_loc,
                                        iscl.loc_type,
                                        'N',
                                        iscl.unit_cost,
                                        iscl.round_lvl,
                                        iscl.round_to_inner_pct,
                                        iscl.round_to_case_pct,
                                        iscl.round_to_layer_pct,
                                        iscl.round_to_pallet_pct,
                                        iscl.supp_hier_type_1,
                                        iscl.supp_hier_lvl_1,
                                        iscl.supp_hier_type_2,
                                        iscl.supp_hier_lvl_2,
                                        iscl.supp_hier_type_3,
                                        iscl.supp_hier_lvl_3,
                                        iscl.pickup_lead_time,
                                        sysdate,
                                        sysdate,
                                        user
                                   from item_supp_country_loc iscl
                                  where iscl.origin_country_id = NVL(I_origin_country_id, iscl.origin_country_id)
                                    and iscl.item = I_item
                                    and iscl.loc = I_like_store
                                    and iscl.supplier = NVL(I_supplier, iscl.supplier)
                                    and iscl.loc in(select iscl2.loc
                                                      from item_supp_country_loc iscl2
                                                     where iscl2.origin_country_id = iscl.origin_country_id
                                                       and iscl2.item = iscl.item
                                                       and iscl2.supplier = iscl.supplier
                                                       and iscl2.loc != I_loc);
	  ---
      if L_bc_ind = 'Y' then
		 if ITEM_BRACKET_COST_SQL.CREATE_BRACKET(O_error_message,
	                                             I_item,
	                                             I_supplier,
	                                             I_origin_country_id,
	                                             I_loc,
	                                             'N') = FALSE then
	        return FALSE;
	     end if;
      end if;
	  ---
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      -- if the record is locked skip the update because the item_supp_country_loc.primary_loc_ind
      -- is being updated by another thread for the same item/minimum location
      return TRUE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CREATE_LOCATION;
-----------------------------------------------------------------------------------------------
FUNCTION GET_PRIMARY_LOC(O_error_message     IN OUT VARCHAR2,
                         O_exists            IN OUT BOOLEAN,
                         O_loc               IN OUT ITEM_SUPP_COUNTRY_LOC.LOC%TYPE,
                         I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                         I_supplier          IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                         I_origin_country_id IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program  VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_LOC_SQL.GET_PRIMARY_LOC';

   cursor C_EXISTS is
      select loc
        from item_supp_country_loc
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country_id
         and primary_loc_ind   = 'Y';
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
   O_loc := NULL;
   ---
   SQL_LIB.SET_MARK('OPEN','C_EXISTS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   open C_EXISTS;
   SQL_LIB.SET_MARK('OPEN','C_EXISTS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   fetch C_EXISTS into O_loc;
   ---
   if C_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_EXISTS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   close C_EXISTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_PRIMARY_LOC;
-----------------------------------------------------------------------------------------------
FUNCTION ALL_PACK_COMPONENTS_EXIST(O_error_message     IN OUT VARCHAR2,
                                   O_exists            IN OUT BOOLEAN,
                                   I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                                   I_supplier          IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                                   I_origin_country_id IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                                   I_loc               IN     ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
   RETURN BOOLEAN IS

   L_program    VARCHAR2(62) := 'ITEM_SUPP_COUNTRY_LOC_SQL.ALL_PACK_COMPONENTS_EXIST';
   L_exists     VARCHAR2(1);

   cursor C_PACK_ITEMS_EXIST is
      select 'x'
        from v_packsku_qty v
       where v.pack_no = I_item
         and not exists(select 'x'
                          from item_supp_country_loc
                         where item              = v.item
                           and supplier          = I_supplier
                           and origin_country_id = I_origin_country_id
                           and loc               = I_loc
                           and rownum = 1)
         and rownum = 1;
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
   if I_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_loc',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_PACK_ITEMS_EXIST','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id
                      ||' Location: '|| I_Loc);
   open C_PACK_ITEMS_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_PACK_ITEMS_EXIST','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id
                      ||' Location: '|| I_Loc);
   fetch C_PACK_ITEMS_EXIST into L_exists;
   ---
   if C_PACK_ITEMS_EXIST%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_PACK_ITEMS_EXIST','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id
                      ||' Location: '|| I_Loc);
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
-----------------------------------------------------------------------------------------------
FUNCTION CREATE_LOCATION(O_error_message     IN OUT VARCHAR2,
                         I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                         I_supplier          IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                         I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                         I_loc               IN     Item_Loc.LOC%TYPE)
   RETURN BOOLEAN IS
BEGIN
   if(CREATE_LOCATION(O_error_message,
                      I_item,
                      I_supplier,
                      I_origin_country_id,
                      I_loc,
                      NULL) = FALSE) then
      return FALSE;
   end if;

   return TRUE;
END CREATE_LOCATION;
-----------------------------------------------------------------------------------------------
FUNCTION CREATE_LOCATION(O_error_message     IN OUT VARCHAR2,
                         I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                         I_supplier          IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                         I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                         I_loc               IN     ITEM_LOC.LOC%TYPE,
                         I_like_store        IN     ITEM_LOC.LOC%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_LOC_SQL.CREATE_LOCATION';
   L_table         VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY_LOC';
   L_min_loc       ITEM_SUPP_COUNTRY_LOC.LOC%TYPE;
   L_buyer_pack    VARCHAR2(1)    := 'N';
   L_update        VARCHAR2(1)    := NULL;
   L_all_locs      VARCHAR2(1);
   L_dept          ITEM_MASTER.DEPT%TYPE;
   L_exists        BOOLEAN;
   L_bc_ind        SYSTEM_OPTIONS.BRACKET_COSTING_IND%TYPE;

   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_GET_DEPT is
      select dept
        from item_master
       where item = I_item;

   cursor C_GET_MIN_ISC_LOC is
      select isl.loc
        from item_supp_country_loc isl
       where isl.item = I_item
         and rownum = 1;

   cursor C_UPDATE_PRIM_LOC_IND is
      select 'x'
        from item_supp_country_loc isl
       where isl.loc               = L_min_loc
         and isl.item              = I_item
         and isl.supplier          = NVL(I_supplier, supplier)
         and isl.origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and not exists (select 'x'
                           from item_supp_country_loc isl3
                          where isl3.loc              != L_min_loc
                            and isl3.item              = isl.item
                            and isl3.supplier          = NVL(I_supplier, supplier)
                            and isl3.origin_country_id = NVL(I_origin_country_id, origin_country_id)
                            and isl3.primary_loc_ind   = 'Y'
                            and rownum = 1)
          for update nowait;
BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if not SYSTEM_OPTIONS_SQL.GET_BRACKET_COST_IND(O_error_message,
                                                  L_bc_ind) then
      return FALSE;
   end if;
   ---
   if I_like_store IS NULL then
      SQL_LIB.SET_MARK('OPEN','C_GET_DEPT','ITEM_MASTER','Item: '||I_item);
      open C_GET_DEPT;
      SQL_LIB.SET_MARK('FETCH','C_GET_DEPT','ITEM_MASTER','Item: '||I_item);
      fetch C_GET_DEPT into L_dept;
      SQL_LIB.SET_MARK('CLOSE','C_GET_DEPT','ITEM_MASTER','Item: '||I_item);
      close C_GET_DEPT;
      ---
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      insert into item_supp_country_loc(item,
                                        supplier,
                                        origin_country_id,
                                        loc,
                                        loc_type,
                                        primary_loc_ind,
                                        unit_cost,
                                        round_lvl,
                                        round_to_inner_pct,
                                        round_to_case_pct,
                                        round_to_layer_pct,
                                        round_to_pallet_pct,
                                        supp_hier_type_1,
                                        supp_hier_lvl_1,
                                        supp_hier_type_2,
                                        supp_hier_lvl_2,
                                        supp_hier_type_3,
                                        supp_hier_lvl_3,
                                        pickup_lead_time,
                                        create_datetime,
                                        last_update_datetime,
                                        last_update_id)
                                 select I_item,
                                        isc.supplier,
                                        isc.origin_country_id,
                                        il.loc,
                                        'W',
                                        'N',
                                        isc.unit_cost,
                                        sim.round_lvl,
                                        sim.round_to_inner_pct,
                                        sim.round_to_case_pct,
                                        sim.round_to_layer_pct,
                                        sim.round_to_pallet_pct,
                                        isc.supp_hier_type_1,
                                        isc.supp_hier_lvl_1,
                                        isc.supp_hier_type_2,
                                        isc.supp_hier_lvl_2,
                                        isc.supp_hier_type_3,
                                        isc.supp_hier_lvl_3,
                                        isc.pickup_lead_time,
                                        sysdate,
                                        sysdate,
                                        user
                                   from item_loc il,
                                        item_supp_country isc,
                                        sups s,
                                        sup_inv_mgmt sim,
                                        wh w
                                  where il.item = I_item
                                    and il.loc = NVL(I_loc, il.loc)
                                    and il.loc_type = 'W'
                                    and isc.item = il.item
                                    and isc.supplier = NVL(I_supplier, isc.supplier)
                                    and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id)
                                    and s.supplier = isc.supplier
                                    and s.inv_mgmt_lvl = 'A'
                                    and w.wh = il.loc
                                    and w.finisher_ind = 'N'
                                    and sim.supplier = isc.supplier
                                    and sim.dept     = L_dept
                                    and sim.location = w.physical_wh
                                    and not exists(select 'x'
                                                     from item_supp_country_loc isl
                                                    where isl.item              = il.item
                                                      and isl.loc               = il.loc
                                                      and isl.supplier          = isc.supplier
                                                      and isl.origin_country_id = isc.origin_country_id
                                                      and rownum = 1)
                                 UNION ALL
                                 select I_item,
                                        isc.supplier,
                                        isc.origin_country_id,
                                        il.loc,
                                        'W',
                                        'N',
                                        isc.unit_cost,
                                        sim.round_lvl,
                                        sim.round_to_inner_pct,
                                        sim.round_to_case_pct,
                                        sim.round_to_layer_pct,
                                        sim.round_to_pallet_pct,
                                        isc.supp_hier_type_1,
                                        isc.supp_hier_lvl_1,
                                        isc.supp_hier_type_2,
                                        isc.supp_hier_lvl_2,
                                        isc.supp_hier_type_3,
                                        isc.supp_hier_lvl_3,
                                        isc.pickup_lead_time,
                                        sysdate,
                                        sysdate,
                                        user
                                   from item_loc il,
                                        item_supp_country isc,
                                        sups s,
                                        sup_inv_mgmt sim,
                                        wh w
                                  where il.item = I_item
                                    and il.loc = NVL(I_loc, il.loc)
                                    and il.loc_type = 'W'
                                    and isc.item = il.item
                                    and isc.supplier = NVL(I_supplier, isc.supplier)
                                    and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id)
                                    and s.supplier = isc.supplier
                                    and s.inv_mgmt_lvl = 'L'
                                    and w.wh = il.loc
                                    and w.finisher_ind = 'N'
                                    and sim.supplier = isc.supplier
                                    and sim.dept is NULL
                                    and sim.location = w.physical_wh
                                    and not exists(select 'x'
                                                     from item_supp_country_loc isl
                                                    where isl.item              = il.item
                                                      and isl.loc               = il.loc
                                                      and isl.supplier          = isc.supplier
                                                      and isl.origin_country_id = isc.origin_country_id
                                                      and rownum = 1)
                                 UNION ALL
                                 select I_item,
                                        isc.supplier,
                                        isc.origin_country_id,
                                        il.loc,
                                        il.loc_type,
                                        'N',
                                        isc.unit_cost,
                                        isc.round_lvl,
                                        isc.round_to_inner_pct,
                                        isc.round_to_case_pct,
                                        isc.round_to_layer_pct,
                                        isc.round_to_pallet_pct,
                                        isc.supp_hier_type_1,
                                        isc.supp_hier_lvl_1,
                                        isc.supp_hier_type_2,
                                        isc.supp_hier_lvl_2,
                                        isc.supp_hier_type_3,
                                        isc.supp_hier_lvl_3,
                                        isc.pickup_lead_time,
                                        sysdate,
                                        sysdate,
                                        user
                                   from item_loc il,
                                        item_supp_country isc,
                                        wh w,
                                        sups s
                                  where il.item = I_item
                                    and w.wh = il.loc
                                    and w.finisher_ind = 'N'
                                    and il.loc = NVL(I_loc, il.loc)
                                    and isc.item = il.item
                                    and isc.supplier = NVL(I_supplier, isc.supplier)
                                    and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id)
                                    and s.supplier = isc.supplier
                                    and (  (il.loc_type = 'W' and s.inv_mgmt_lvl = 'A'
                                             and not exists(select 'x'
                                                                   from sup_inv_mgmt sim2
                                                                  where sim2.supplier = isc.supplier
                                                                    and sim2.dept     = L_dept
                                                                    and sim2.location = w.physical_wh
                                                                    and rownum = 1))
                                        or (il.loc_type = 'W' and s.inv_mgmt_lvl = 'L'
                                             and not exists(select 'x'
                                                              from sup_inv_mgmt sim2
                                                             where sim2.supplier = isc.supplier
                                                               and sim2.location = w.physical_wh
                                                               and rownum = 1)))
                                    and not exists(select 'x'
                                                     from item_supp_country_loc isl
                                                    where isl.item              = il.item
                                                      and isl.loc               = il.loc
                                                      and isl.supplier          = isc.supplier
                                                      and isl.origin_country_id = isc.origin_country_id
                                                      and rownum = 1)
                                 UNION ALL
                                 select I_item,
                                        isc.supplier,
                                        isc.origin_country_id,
                                        il.loc,
                                        il.loc_type,
                                        'N',
                                        isc.unit_cost,
                                        isc.round_lvl,
                                        isc.round_to_inner_pct,
                                        isc.round_to_case_pct,
                                        isc.round_to_layer_pct,
                                        isc.round_to_pallet_pct,
                                        isc.supp_hier_type_1,
                                        isc.supp_hier_lvl_1,
                                        isc.supp_hier_type_2,
                                        isc.supp_hier_lvl_2,
                                        isc.supp_hier_type_3,
                                        isc.supp_hier_lvl_3,
                                        isc.pickup_lead_time,
                                        sysdate,
                                        sysdate,
                                        user
                                   from item_loc il,
                                        item_supp_country isc,
                                        sups s
                                  where il.item = I_item
                                    and il.loc_type <> 'E'
                                    and il.loc = NVL(I_loc, il.loc)
                                    and isc.item = il.item
                                    and isc.supplier = NVL(I_supplier, isc.supplier)
                                    and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id)
                                    and s.supplier = isc.supplier
                                    and (il.loc_type = 'S' or s.inv_mgmt_lvl in ('S', 'D'))
                                    and not exists(select 'x'
                                                     from item_supp_country_loc isl
                                                    where isl.item              = il.item
                                                      and isl.loc               = il.loc
                                                      and isl.supplier          = isc.supplier
                                                      and isl.origin_country_id = isc.origin_country_id
                                                      and rownum = 1);
      ---
      -- The minimum lowest location number will be selected to be the primary location on mass inserts.
      ---
      L_update := 'Y';
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_MIN_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      open C_GET_MIN_ISC_LOC;
      SQL_LIB.SET_MARK('FETCH','C_GET_MIN_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      fetch C_GET_MIN_ISC_LOC into L_min_loc;
      ---
      if C_GET_MIN_ISC_LOC%NOTFOUND then
         L_update := 'N';
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_GET_MIN_ISC_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      close C_GET_MIN_ISC_LOC;
      ---
      if L_update = 'Y' then
         SQL_LIB.SET_MARK('OPEN','C_UPDATE_PRIM_LOC_IND','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
         open C_UPDATE_PRIM_LOC_IND;
         SQL_LIB.SET_MARK('CLOSE','C_UPDATE_PRIM_LOC_IND','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
         close C_UPDATE_PRIM_LOC_IND;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
         update item_supp_country_loc isl
            set primary_loc_ind      = 'Y',
                last_update_datetime = sysdate,
                last_update_id       = user
          where isl.item              = I_item
            and isl.loc               = L_min_loc
            and isl.supplier          = NVL(I_supplier, supplier)
            and isl.origin_country_id = NVL(I_origin_country_id, origin_country_id)
            and not exists (select 'x'
                              from item_supp_country_loc isl3
                             where isl3.item              = isl.item
                               and isl3.loc              != isl.loc
                               and isl3.supplier          = NVL(I_supplier, supplier)
                               and isl3.origin_country_id = NVL(I_origin_country_id, origin_country_id)
                               and isl3.primary_loc_ind   = 'Y'
                               and rownum = 1);
      end if;
      ---
      if I_loc is NOT NULL then
         L_all_locs := 'N';
      else
         L_all_locs := 'Y';
      end if;
      ---
	  if L_bc_ind = 'Y' then
         if ITEM_BRACKET_COST_SQL.CREATE_BRACKET(O_error_message,
	                                             I_item,
	                                             I_supplier,
	                                             I_origin_country_id,
	                                             I_loc,
	                                             L_all_locs) = FALSE then
	        return FALSE;
	     end if;
	  end if;
   else  -- I_like_store IS NOT NULL --
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_LOC','Item: '||I_item);
      insert into item_supp_country_loc(item,
                                        supplier,
                                        origin_country_id,
                                        loc,
                                        loc_type,
                                        primary_loc_ind,
                                        unit_cost,
                                        round_lvl,
                                        round_to_inner_pct,
                                        round_to_case_pct,
                                        round_to_layer_pct,
                                        round_to_pallet_pct,
                                        supp_hier_type_1,
                                        supp_hier_lvl_1,
                                        supp_hier_type_2,
                                        supp_hier_lvl_2,
                                        supp_hier_type_3,
                                        supp_hier_lvl_3,
                                        pickup_lead_time,
                                        create_datetime,
                                        last_update_datetime,
                                        last_update_id)
                                 select I_item,
                                        iscl.supplier,
                                        iscl.origin_country_id,
                                        I_loc,
                                        iscl.loc_type,
                                        'N',
                                        iscl.unit_cost,
                                        iscl.round_lvl,
                                        iscl.round_to_inner_pct,
                                        iscl.round_to_case_pct,
                                        iscl.round_to_layer_pct,
                                        iscl.round_to_pallet_pct,
                                        iscl.supp_hier_type_1,
                                        iscl.supp_hier_lvl_1,
                                        iscl.supp_hier_type_2,
                                        iscl.supp_hier_lvl_2,
                                        iscl.supp_hier_type_3,
                                        iscl.supp_hier_lvl_3,
                                        iscl.pickup_lead_time,
                                        sysdate,
                                        sysdate,
                                        user
                                   from item_supp_country_loc iscl
                                  where iscl.origin_country_id = NVL(I_origin_country_id, iscl.origin_country_id)
                                    and iscl.item = I_item
                                    and iscl.loc = I_like_store
                                    and iscl.supplier = NVL(I_supplier, iscl.supplier)
                                    and iscl.loc in(select iscl2.loc
                                                      from item_supp_country_loc iscl2
                                                     where iscl2.origin_country_id = iscl.origin_country_id
                                                       and iscl2.item = iscl.item
                                                       and iscl2.supplier = iscl.supplier
                                                       and iscl2.loc != I_loc);
      if L_bc_ind = 'Y' then
	     if ITEM_BRACKET_COST_SQL.CREATE_BRACKET(O_error_message,
	                                             I_item,
	                                             I_supplier,
	                                             I_origin_country_id,
	                                             I_loc,
	                                             'N') = FALSE then

	     return FALSE;
	     end if;
	  end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      -- if the record is locked skip the update because the
      -- item_supp_country_loc.primary_loc_ind is being updated by another
      -- thread for the same item/minimum location
      return TRUE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CREATE_LOCATION;
-----------------------------------------------------------------------------------------------
FUNCTION UPDATE_LOCATION(O_error_message     IN OUT VARCHAR2,
                         I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                         I_supplier          IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                         I_origin_country_id IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                         I_edit_cost         IN     VARCHAR2,
                         I_update_all_locs   IN     VARCHAR2)
   RETURN BOOLEAN IS

   L_program             VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_LOC_SQL.UPDATE_LOCATION';
   L_table               VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY_LOC';
   L_primary_loc_ind     VARCHAR2(20)   := NULL;
   L_round_lvl           ITEM_SUPP_COUNTRY_LOC.ROUND_LVL%TYPE;
   L_round_to_inner_pct  ITEM_SUPP_COUNTRY_LOC.ROUND_TO_INNER_PCT%TYPE;
   L_round_to_case_pct   ITEM_SUPP_COUNTRY_LOC.ROUND_TO_CASE_PCT%TYPE;
   L_round_to_layer_pct  ITEM_SUPP_COUNTRY_LOC.ROUND_TO_LAYER_PCT%TYPE;
   L_round_to_pallet_pct ITEM_SUPP_COUNTRY_LOC.ROUND_TO_PALLET_PCT%TYPE;
   L_supp_hier_lvl_1     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_1%TYPE;
   L_supp_hier_type_1    ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_1%TYPE;
   L_supp_hier_lvl_2     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_2%TYPE;
   L_supp_hier_type_2    ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_2%TYPE;
   L_supp_hier_lvl_3     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_3%TYPE;
   L_supp_hier_type_3    ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_3%TYPE;
   L_pickup_lead_time    ITEM_SUPP_COUNTRY_LOC.PICKUP_LEAD_TIME%TYPE;
   L_physical_wh         WH.PHYSICAL_WH%TYPE := NULL;
   RECORD_LOCKED         EXCEPTION;
   PRAGMA                EXCEPTION_INIT(Record_Locked, -54);

   cursor C_PRIM_LOC_VIRTUAL is
      select wh.physical_wh
        from item_supp_country_loc iscl,
             wh
       where iscl.item              = I_item
         and iscl.supplier          = I_supplier
         and iscl.origin_country_id = I_origin_country_id
         and iscl.primary_loc_ind   = 'Y'
         and iscl.loc               = wh.wh
         and wh.stockholding_ind    = 'Y';

   cursor C_UPDATE_LOCATIONS is
      select round_lvl,
             round_to_inner_pct,
             round_to_case_pct,
             round_to_layer_pct,
             round_to_pallet_pct,
             supp_hier_lvl_1,
             supp_hier_type_1,
             supp_hier_lvl_2,
             supp_hier_type_2,
             supp_hier_lvl_3,
             supp_hier_type_3,
             pickup_lead_time
        from item_supp_country
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country_id;

   cursor C_LOCK_ALL_LOCS is
      select 'x'
        from item_supp_country_loc
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country_id
         for update nowait;

   cursor C_LOCK_PRIM_LOC is
      select 'x'
        from item_supp_country_loc
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country_id
         and primary_loc_ind   = 'Y'
         for update nowait;

   cursor C_LOCK_PRIM_VIRTUALS is
      select 'x'
        from item_supp_country_loc iscl, wh w
       where iscl.item              = I_item
         and iscl.supplier          = I_supplier
         and iscl.origin_country_id = I_origin_country_id
         and iscl.loc                 = w.wh
         and w.physical_wh            = L_physical_wh
      for update of item nowait;

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
   SQL_LIB.SET_MARK('OPEN','C_UPDATE_LOCATIONS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
   open C_UPDATE_LOCATIONS;
   SQL_LIB.SET_MARK('FETCH','C_UPDATE_LOCATIONS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
   fetch C_UPDATE_LOCATIONS into L_round_lvl,
                                 L_round_to_inner_pct,
                                 L_round_to_case_pct,
                                 L_round_to_layer_pct,
                                 L_round_to_pallet_pct,
                                 L_supp_hier_lvl_1,
                                 L_supp_hier_type_1,
                                 L_supp_hier_lvl_2,
                                 L_supp_hier_type_2,
                                 L_supp_hier_lvl_3,
                                 L_supp_hier_type_3,
                                 L_pickup_lead_time;
   SQL_LIB.SET_MARK('CLOSE','C_UPDATE_LOCATIONS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
   close C_UPDATE_LOCATIONS;
   ---
   if I_update_all_locs = 'Y' then
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_LOCS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
      open C_LOCK_ALL_LOCS;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_LOCS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
      close C_LOCK_ALL_LOCS;
      ---
      update item_supp_country_loc
         set round_lvl            = nvl(L_round_lvl, round_lvl),
             round_to_inner_pct   = nvl(L_round_to_inner_pct, round_to_inner_pct),
             round_to_case_pct    = nvl(L_round_to_case_pct, round_to_case_pct),
             round_to_layer_pct   = nvl(L_round_to_layer_pct, round_to_layer_pct),
             round_to_pallet_pct  = nvl(L_round_to_pallet_pct, round_to_pallet_pct),
             supp_hier_lvl_1      = nvl(L_supp_hier_lvl_1, supp_hier_lvl_1),
             supp_hier_type_1     = nvl(L_supp_hier_type_1, supp_hier_type_1),
             supp_hier_lvl_2      = nvl(L_supp_hier_lvl_2, supp_hier_lvl_2),
             supp_hier_type_2     = nvl(L_supp_hier_type_2, supp_hier_type_2),
             supp_hier_lvl_3      = nvl(L_supp_hier_lvl_3, supp_hier_lvl_3),
             supp_hier_type_3     = nvl(L_supp_hier_type_3, supp_hier_type_3),
             pickup_lead_time     = nvl(L_pickup_lead_time, pickup_lead_time),
             last_update_datetime = SYSDATE,
             last_update_id       = USER
       where item                 = I_item
         and supplier             = I_supplier
         and origin_country_id    = I_origin_country_id;
      ---
   else  /* I_update_all_locs = 'N' */
      ---
      SQL_LIB.SET_MARK('OPEN','C_PRIM_LOC_VIRTUAL','ITEM_SUPP_COUNTRY_LOC, WH','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
      open C_PRIM_LOC_VIRTUAL;
      SQL_LIB.SET_MARK('FETCH','C_PRIM_LOC_VIRTUAL','ITEM_SUPP_COUNTRY_LOC, WH','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
      fetch C_PRIM_LOC_VIRTUAL into L_physical_wh;
      ---
      if C_PRIM_LOC_VIRTUAL%NOTFOUND then
         ---
         SQL_LIB.SET_MARK('CLOSE','C_PRIM_LOC_VIRTUAL','ITEM_SUPP_COUNTRY_LOC, WH','Item: '||I_item||
                          ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
         close C_PRIM_LOC_VIRTUAL;
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_PRIM_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                          ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
         open C_LOCK_PRIM_LOC;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_PRIM_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                          ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
         close C_LOCK_PRIM_LOC;
         ---
         update item_supp_country_loc
            set round_lvl            = nvl(L_round_lvl, round_lvl),
                round_to_inner_pct   = nvl(L_round_to_inner_pct, round_to_inner_pct),
                round_to_case_pct    = nvl(L_round_to_case_pct, round_to_case_pct),
                round_to_layer_pct   = nvl(L_round_to_layer_pct, round_to_layer_pct),
                round_to_pallet_pct  = nvl(L_round_to_pallet_pct, round_to_pallet_pct),
                supp_hier_lvl_1      = nvl(L_supp_hier_lvl_1, supp_hier_lvl_1),
                supp_hier_type_1     = nvl(L_supp_hier_type_1, supp_hier_type_1),
                supp_hier_lvl_2      = nvl(L_supp_hier_lvl_2, supp_hier_lvl_2),
                supp_hier_type_2     = nvl(L_supp_hier_type_2, supp_hier_type_2),
                supp_hier_lvl_3      = nvl(L_supp_hier_lvl_3, supp_hier_lvl_3),
                supp_hier_type_3     = nvl(L_supp_hier_type_3, supp_hier_type_3),
                pickup_lead_time     = nvl(L_pickup_lead_time, pickup_lead_time),
                last_update_datetime = SYSDATE,
                last_update_id       = USER
          where item                 = I_item
            and supplier             = I_supplier
            and origin_country_id    = I_origin_country_id
            and primary_loc_ind      = 'Y';
         ---
      else  /* C_PRIM_LOC_VIRTUAL%FOUND */
         ---
         SQL_LIB.SET_MARK('CLOSE','C_PRIM_LOC_VIRTUAL','ITEM_SUPP_COUNTRY_LOC, WH','Item: '||I_item||
                          ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
         close C_PRIM_LOC_VIRTUAL;
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_PRIM_VIRTUALS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                          ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
         open C_LOCK_PRIM_VIRTUALS;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_PRIM_VIRTUALS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                          ' Supplier: '||to_char(I_supplier)||' Country: '||I_origin_country_id);
         close C_LOCK_PRIM_VIRTUALS;
         ---
         update item_supp_country_loc iscl
            set round_lvl            = nvl(L_round_lvl, round_lvl),
                round_to_inner_pct   = nvl(L_round_to_inner_pct, round_to_inner_pct),
                round_to_case_pct    = nvl(L_round_to_case_pct, round_to_case_pct),
                round_to_layer_pct   = nvl(L_round_to_layer_pct, round_to_layer_pct),
                round_to_pallet_pct  = nvl(L_round_to_pallet_pct, round_to_pallet_pct),
                supp_hier_lvl_1      = nvl(L_supp_hier_lvl_1, supp_hier_lvl_1),
                supp_hier_type_1     = nvl(L_supp_hier_type_1, supp_hier_type_1),
                supp_hier_lvl_2      = nvl(L_supp_hier_lvl_2, supp_hier_lvl_2),
                supp_hier_type_2     = nvl(L_supp_hier_type_2, supp_hier_type_2),
                supp_hier_lvl_3      = nvl(L_supp_hier_lvl_3, supp_hier_lvl_3),
                supp_hier_type_3     = nvl(L_supp_hier_type_3, supp_hier_type_3),
                pickup_lead_time     = nvl(L_pickup_lead_time, pickup_lead_time),
                last_update_datetime = SYSDATE,
                last_update_id       = USER
          where item                 = I_item
            and supplier             = I_supplier
            and origin_country_id    = I_origin_country_id
            and exists                (select 'x'
                                         from wh
                                        where iscl.loc = wh.wh
                                          and wh.physical_wh = L_physical_wh);
         ---
      end if;
      ---
   end if;
   ---
   if I_edit_cost = 'Y' then
      if UPDATE_BASE_COST.CHANGE_ISC_COST(O_error_message,
                                          I_item,
                                          I_supplier,
                                          I_origin_country_id,
                                          I_update_all_locs) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             I_item,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_LOCATION;
-----------------------------------------------------------------------------------------------
FUNCTION CHECK_LOCATION(O_error_message     IN OUT VARCHAR2,
                        O_exists            IN OUT BOOLEAN,
                        I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                        I_supplier          IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                        I_origin_country_id IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_LOC_SQL.CHECK_LOCATION';
   L_exists    VARCHAR2(1)    := 'N';

   cursor C_CHECK_COUNTRY_LOC is
      select 'Y'
        from item_supp_country_loc i
       where i.item              = I_item
         and i.supplier          = I_supplier
         and i.origin_country_id = I_origin_country_id
         and exists (select 'x'
                       from item_supp_country_loc i2
                      where i2.item                 = I_item
                        and i2.supplier             = I_supplier
                        and i2.origin_country_id    = I_origin_country_id
                        and (i2.unit_cost          != i.unit_cost
                         or i2.supp_hier_lvl_1     != NVL(i.supp_hier_lvl_1,     supp_hier_lvl_1)
                         or i2.supp_hier_lvl_2     != NVL(i.supp_hier_lvl_2,     supp_hier_lvl_2)
                         or i2.supp_hier_lvl_3     != NVL(i.supp_hier_lvl_3,     supp_hier_lvl_3)
                         or i2.pickup_lead_time    != NVL(i.pickup_lead_time,    pickup_lead_time)
                         or i2.round_lvl           != NVL(i.round_lvl,           round_lvl)
                         or i2.round_to_case_pct   != NVL(i.round_to_case_pct,   round_to_case_pct)
                         or i2.round_to_layer_pct  != NVL(i.round_to_layer_pct,  round_to_layer_pct)
                         or i2.round_to_pallet_pct != NVL(i.round_to_pallet_pct, round_to_pallet_pct)));

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
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_COUNTRY_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   open C_CHECK_COUNTRY_LOC;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_COUNTRY_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   fetch C_CHECK_COUNTRY_LOC into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_COUNTRY_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   close C_CHECK_COUNTRY_LOC;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
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
END CHECK_LOCATION;
-----------------------------------------------------------------------------------------------
FUNCTION DEFAULT_LOCATION_TO_CHILDREN(O_error_message       IN OUT VARCHAR2,
                                      I_item                IN     ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                      I_supplier            IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                      I_origin_country_id   IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                                      I_edit_cost           IN     VARCHAR2,
                                      I_update_all_locs     IN     VARCHAR2)
   RETURN BOOLEAN IS

   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_SQL.DEFAULT_LOCATION_TO_CHILDREN';
   L_child_item            ITEM_MASTER.ITEM%TYPE;
   L_insert_update_locs    VARCHAR2(1)    := 'N';

   cursor C_GET_CHILD_ITEMS is
      select item
        from item_master i
       where (i.item_parent = I_item or
         -- DefNBS019964 , 02-Dec-2010 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
         i.item_grandparent = I_item
         or i.item in (select pack_no
                          from packitem
                         where (item = I_item
                            or  item in (select item
                                           from item_master
                                          where item_parent = I_item)))
         or i.item_parent in (select pack_no
                                 from packitem
                                where (item = I_item
                                   or  item in (select item
                                                  from item_master
                                                 where item_parent = I_item))))
         -- DefNBS019964 , 02-Dec-2010 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
         and i.item_level          <= i.tran_level
         and exists (select 'x'
                       from item_supp_country isc
                      where isc.item              = i.item
                        and isc.supplier          = I_supplier
                        and isc.origin_country_id = I_origin_country_id);

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
   -- If I_update_all_locs is passed in as NULL, then both update and create logic will be performed. --
   ---
   if I_update_all_locs is NULL then
      L_insert_update_locs := 'Y';
   end if;
   ---
   for C_rec in C_GET_CHILD_ITEMS loop
      L_child_item := C_rec.item;
      ---
      if L_insert_update_locs = 'Y' then
         if ITEM_SUPP_COUNTRY_LOC_SQL.UPDATE_LOCATION(O_error_message,
                                                      L_child_item,
                                                      I_supplier,
                                                      I_origin_country_id,
                                                      I_edit_cost,
                                                      I_update_all_locs) = FALSE then
            return FALSE;
         end if;
         ---
         if ITEM_SUPP_COUNTRY_LOC_SQL.CREATE_LOCATION(O_error_message,
                                                      L_child_item,
                                                      I_supplier,
                                                      I_origin_country_id,
                                                      NULL) = FALSE then
            return FALSE;
         end if;
      else
          if ITEM_SUPP_COUNTRY_LOC_SQL.UPDATE_LOCATION(O_error_message,
                                                       L_child_item,
                                                       I_supplier,
                                                       I_origin_country_id,
                                                       I_edit_cost,
                                                       I_update_all_locs) = FALSE then
            return FALSE;
         end if;
      end if;
   end loop;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEFAULT_LOCATION_TO_CHILDREN;
------------------------------------------------------------------------------------------------------------
FUNCTION MASS_UPDATE(O_error_message       IN OUT VARCHAR2,
                     I_group_type          IN     VARCHAR2,
                     I_group_value         IN     VARCHAR2,
                     I_unit_cost           IN     ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE,
                     I_change_rnd_lvl_ind  IN     VARCHAR2,
                     I_round_lvl           IN     ITEM_SUPP_COUNTRY_LOC.ROUND_LVL%TYPE,
                     I_change_inner_ind    IN     VARCHAR2,
                     I_round_to_inner_pct  IN     ITEM_SUPP_COUNTRY_LOC.ROUND_TO_INNER_PCT%TYPE,
                     I_change_case_ind     IN     VARCHAR2,
                     I_round_to_case_pct   IN     ITEM_SUPP_COUNTRY_LOC.ROUND_TO_CASE_PCT%TYPE,
                     I_change_layer_ind    IN     VARCHAR2,
                     I_round_to_layer_pct  IN     ITEM_SUPP_COUNTRY_LOC.ROUND_TO_LAYER_PCT%TYPE,
                     I_change_pallet_ind   IN     VARCHAR2,
                     I_round_to_pallet_pct IN     ITEM_SUPP_COUNTRY_LOC.ROUND_TO_PALLET_PCT%TYPE,
                     I_change_lvl_1        IN     VARCHAR2,
                     I_supp_hier_lvl_1     IN     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_1%TYPE,
                     I_change_lvl_2        IN     VARCHAR2,
                     I_supp_hier_lvl_2     IN     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_2%TYPE,
                     I_change_lvl_3        IN     VARCHAR2,
                     I_supp_hier_lvl_3     IN     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_3%TYPE,
                     I_change_pickup_ind   IN     VARCHAR2,
                     I_pickup_lead_time    IN     ITEM_SUPP_COUNTRY_LOC.PICKUP_LEAD_TIME%TYPE,
                     I_item                IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                     I_supplier            IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                     I_origin_country_id   IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                     I_process_children    IN     VARCHAR2)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(62) := 'ITEM_SUPP_COUNTRY_LOC_SQL.MASS_UPDATE';
   L_supp_hier_type_1   ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_1%TYPE := NULL;
   L_supp_hier_type_2   ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_2%TYPE := NULL;
   L_supp_hier_type_3   ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_3%TYPE := NULL;
   L_loc                ITEM_SUPP_COUNTRY_LOC.LOC%TYPE;
   L_unit_cost          ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE;
   L_primary_loc_ind    ITEM_SUPP_COUNTRY_LOC.PRIMARY_LOC_IND%TYPE;
   L_zone_group_id      PRICE_ZONE.ZONE_GROUP_ID%TYPE;
   L_where_clause       VARCHAR2(2000);
   L_no_update          VARCHAR2(100);
   L_first_time         BOOLEAN := TRUE;
   L_group_label        CODE_DETAIL.CODE_DESC%TYPE;
   ---
   sql_stmt             VARCHAR2(2000);
   lock_stmt            VARCHAR2(2000);
   TYPE LOC_CURSOR is REF CURSOR;
   C_LOC                LOC_CURSOR;
   ---
   L_table              VARCHAR2(30) := 'ITEM_SUPP_COUNTRY_LOC';
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(RECORD_LOCKED, -54);

BEGIN
   if I_item is NULL or I_supplier is NULL
    or I_origin_country_id is NULL or I_group_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item' || ', I_supplier' || ', I_origin_country_id'
                                            || ', I_group_type',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if LP_multichannel_ind is NULL then
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                LP_multichannel_ind) = FALSE then
         return FALSE;
      end if;
   end if;
   ----
   --- SET DYNAMIC WHERE CLAUSE
   ----
   if LP_multichannel_ind = 'Y'
      and I_group_type in ('LLW','W') then
      ---
      if LOCATION_ATTRIB_SQL.BUILD_GROUP_TYPE_VIRTUAL_WHERE(O_error_message,
                                                            L_where_clause,
                                                            'loc',
                                                            I_group_type,
                                                            I_group_value) = FALSE then
         return FALSE;
      end if;
      ---
   else
      ---
      if LOCATION_ATTRIB_SQL.BUILD_GROUP_TYPE_WHERE_CLAUSE(O_error_message,
                                                           L_where_clause,
                                                           I_group_type,
                                                           I_group_value,
                                                           'loc') = FALSE then
         return FALSE;
      end if;
      ---
   end if;
   ---
   if I_group_type != 'AL' then
      L_where_clause := LPAD(L_where_clause, LENGTH(L_where_clause) + 5, ' and ');
   end if;
   ---
   if I_supp_hier_lvl_1 is not NULL then
      L_supp_hier_type_1 := 'S1';
   end if;
   ---
   if I_supp_hier_lvl_2 is not NULL then
      L_supp_hier_type_2 := 'S2';
   end if;
   ---
   if I_supp_hier_lvl_3 is not NULL then
      L_supp_hier_type_3 := 'S3';
   end if;
   ---
   -- LOCK RECORDS FOR UPDATE
   ---
   SQL_LIB.SET_MARK('UPDATE', NULL,'ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   ---
   L_no_update := ' for update nowait';
   ---
   lock_stmt := 'select loc,
                        primary_loc_ind,
                        unit_cost
                   from item_supp_country_loc
                  where item              = :I_item
                    and supplier          = :I_supplier
                    and origin_country_id = :I_origin_country_id
                    and (loc in (select store from store)
                         or loc in (select wh from wh))' || L_where_clause;
   EXECUTE IMMEDIATE lock_stmt || L_no_update USING I_item, I_supplier, I_origin_country_id;
   ---
   -- UPDATE RECORDS ON ITEM_SUPP_COUNRY_LOC
   ---
   sql_stmt := 'update item_supp_country_loc
         set unit_cost            = NVL(:I_unit_cost, unit_cost),
             round_lvl            = DECODE(:I_change_rnd_lvl_ind, ''Y'', :I_round_lvl,           round_lvl),
             round_to_inner_pct   = DECODE(:I_change_inner_ind,   ''Y'', :I_round_to_inner_pct,  round_to_inner_pct),
             round_to_case_pct    = DECODE(:I_change_case_ind,    ''Y'', :I_round_to_case_pct,   round_to_case_pct),
             round_to_layer_pct   = DECODE(:I_change_layer_ind,   ''Y'', :I_round_to_layer_pct,  round_to_layer_pct),
             round_to_pallet_pct  = DECODE(:I_change_pallet_ind,  ''Y'', :I_round_to_pallet_pct, round_to_pallet_pct),
             supp_hier_type_1     = DECODE(:I_change_lvl_1,       ''Y'', :L_supp_hier_type_1,    supp_hier_type_1),
             supp_hier_lvl_1      = DECODE(:I_change_lvl_1,       ''Y'', :I_supp_hier_lvl_1,     supp_hier_lvl_1),
             supp_hier_type_2     = DECODE(:I_change_lvl_2,       ''Y'', :L_supp_hier_type_2,    supp_hier_type_2),
             supp_hier_lvl_2      = DECODE(:I_change_lvl_2,       ''Y'', :I_supp_hier_lvl_2,     supp_hier_lvl_2),
             supp_hier_type_3     = DECODE(:I_change_lvl_3,       ''Y'', :L_supp_hier_type_3,    supp_hier_type_3),
             supp_hier_lvl_3      = DECODE(:I_change_lvl_3,       ''Y'', :I_supp_hier_lvl_3,     supp_hier_lvl_3),
             pickup_lead_time     = DECODE(:I_change_pickup_ind,  ''Y'', :I_pickup_lead_time,    pickup_lead_time),
             last_update_datetime = :s,
             last_update_id       = :u
       where item = :I_item
         and supplier = :I_supplier
         and origin_country_id = :I_origin_country_id
         and (loc in (select store from store)
             or loc in (select wh from wh))' || L_where_clause;

   EXECUTE IMMEDIATE sql_stmt USING I_unit_cost, I_change_rnd_lvl_ind, I_round_lvl,
                                    I_change_inner_ind,  I_round_to_inner_pct,
                                    I_change_case_ind,   I_round_to_case_pct,
                                    I_change_layer_ind,  I_round_to_layer_pct,
                                    I_change_pallet_ind, I_round_to_pallet_pct,
                                    I_change_lvl_1, L_supp_hier_type_1, I_change_lvl_1,
                                    I_supp_hier_lvl_1, I_change_lvl_2, L_supp_hier_type_2,
                                    I_change_lvl_2, I_supp_hier_lvl_2, I_change_lvl_3,
                                    L_supp_hier_type_3, I_change_lvl_3, I_supp_hier_lvl_3,
                                    I_change_pickup_ind, I_pickup_lead_time,
                                    sysdate, user, I_item, I_supplier, I_origin_country_id;
   ---
   -- loop THROUGH EACH UPDATED LOCATION AND UPDATE ITEM_LOC AND/OR ITEM_SUPP_COUNTRY
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   open C_LOC for lock_stmt USING I_item, I_supplier, I_origin_country_id;
   loop
      SQL_LIB.SET_MARK('FETCH','C_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id ||
                       ' Location: '||to_char(L_loc));
      fetch C_LOC into L_loc,
                       L_primary_loc_ind,
                       L_unit_cost;
      ---
      EXIT WHEN C_LOC%NOTFOUND;
      ---
      L_first_time := FALSE;
      if I_unit_cost is not NULL then
         if UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                         I_item,
                                         I_supplier,
                                         I_origin_country_id,
                                         L_loc,
                                         I_process_children,
                                         'Y',
                                         NULL /* Cost Change Number */ ) = FALSE then   -- update unit cost indicator
            return FALSE;
         end if;
      end if;
      ---
      if I_process_children = 'Y' then
         if UPDATE_CHILD_LOCATION(O_error_message,
                                  I_change_rnd_lvl_ind,
                                  I_round_lvl,
                                  I_change_inner_ind,
                                  I_round_to_inner_pct,
                                  I_change_case_ind,
                                  I_round_to_case_pct,
                                  I_change_layer_ind,
                                  I_round_to_layer_pct,
                                  I_change_pallet_ind,
                                  I_round_to_pallet_pct,
                                  I_change_lvl_1,
                                  L_supp_hier_type_1,
                                  I_supp_hier_lvl_1,
                                  I_change_lvl_2,
                                  L_supp_hier_type_2,
                                  I_supp_hier_lvl_2,
                                  I_change_lvl_3,
                                  L_supp_hier_type_3,
                                  I_supp_hier_lvl_3,
                                  I_change_pickup_ind,
                                  I_pickup_lead_time,
                                  I_item,
                                  I_supplier,
                                  I_origin_country_id,
                                  L_loc) = FALSE then
             return FALSE;
          end if;
       end if;
   end loop;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   close C_LOC;
   ---
   if L_first_time then
      if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                    'GRTV',
                                    I_group_type,
                                    L_group_label) = FALSE then
         return FALSE;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_SUPP_CNT_LOC_LIST',
                                            L_group_label,
                                            I_group_value,
                                            NULL);
      return FALSE;
   end if;
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            to_char(I_supplier));
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END MASS_UPDATE;
----------------------------------------------------------------------------------------------
FUNCTION UPDATE_CHILD_LOCATION(O_error_message       IN OUT VARCHAR2,
                               I_change_rnd_lvl_ind  IN     VARCHAR2,
                               I_round_lvl           IN     ITEM_SUPP_COUNTRY_LOC.ROUND_LVL%TYPE,
                               I_change_inner_ind    IN     VARCHAR2,
                               I_round_to_inner_pct  IN     ITEM_SUPP_COUNTRY_LOC.ROUND_TO_INNER_PCT%TYPE,
                               I_change_case_ind     IN     VARCHAR2,
                               I_round_to_case_pct   IN     ITEM_SUPP_COUNTRY_LOC.ROUND_TO_CASE_PCT%TYPE,
                               I_change_layer_ind    IN     VARCHAR2,
                               I_round_to_layer_pct  IN     ITEM_SUPP_COUNTRY_LOC.ROUND_TO_LAYER_PCT%TYPE,
                               I_change_pallet_ind   IN     VARCHAR2,
                               I_round_to_pallet_pct IN     ITEM_SUPP_COUNTRY_LOC.ROUND_TO_PALLET_PCT%TYPE,
                               I_change_lvl_1        IN     VARCHAR2,
                               I_supp_hier_type_1    IN     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_1%TYPE,
                               I_supp_hier_lvl_1     IN     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_1%TYPE,
                               I_change_lvl_2        IN     VARCHAR2,
                               I_supp_hier_type_2    IN     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_2%TYPE,
                               I_supp_hier_lvl_2     IN     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_2%TYPE,
                               I_change_lvl_3        IN     VARCHAR2,
                               I_supp_hier_type_3    IN     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_3%TYPE,
                               I_supp_hier_lvl_3     IN     ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_3%TYPE,
                               I_change_pickup_ind   IN     VARCHAR2,
                               I_pickup_lead_time    IN     ITEM_SUPP_COUNTRY_LOC.PICKUP_LEAD_TIME%TYPE,
                               I_item                IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                               I_supplier            IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                               I_origin_country_id   IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                               I_location            IN     ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
   RETURN BOOLEAN IS

   L_program               VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_LOC_SQL.UPDATE_CHILD_LOCATION';
   L_table                 VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY_LOC';
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_LOCS is
      select 'x'
        from item_supp_country_loc iscl,
             item_master im
       where (im.item_parent         = I_item
              or im.item_grandparent = I_item)
         and im.item_level          <= im.tran_level
         and iscl.item               = im.item
         and iscl.supplier           = I_supplier
         and iscl.origin_country_id  = I_origin_country_id
         and iscl.loc                = I_location
         for update nowait;
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
   SQL_LIB.SET_MARK('OPEN','C_LOCK_LOCS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   open C_LOCK_LOCS;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_LOCS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
   close C_LOCK_LOCS;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);

   update item_supp_country_loc
      set round_lvl            = DECODE(I_change_rnd_lvl_ind, 'Y', I_round_lvl,           round_lvl),
          round_to_inner_pct   = DECODE(I_change_inner_ind,   'Y', I_round_to_inner_pct,  round_to_inner_pct),
          round_to_case_pct    = DECODE(I_change_case_ind,    'Y', I_round_to_case_pct,   round_to_case_pct),
          round_to_layer_pct   = DECODE(I_change_layer_ind,   'Y', I_round_to_layer_pct,  round_to_layer_pct),
          round_to_pallet_pct  = DECODE(I_change_pallet_ind,  'Y', I_round_to_pallet_pct, round_to_pallet_pct),
          supp_hier_lvl_1      = DECODE(I_change_lvl_1,       'Y', I_supp_hier_lvl_1,     supp_hier_lvl_1),
          supp_hier_type_1     = DECODE(I_change_lvl_1,       'Y', I_supp_hier_type_1,    supp_hier_type_1),
          supp_hier_lvl_2      = DECODE(I_change_lvl_2,       'Y', I_supp_hier_lvl_2,     supp_hier_lvl_2),
          supp_hier_type_2     = DECODE(I_change_lvl_2,       'Y', I_supp_hier_type_2,    supp_hier_type_2),
          supp_hier_lvl_3      = DECODE(I_change_lvl_3,       'Y', I_supp_hier_lvl_3,     supp_hier_lvl_3),
          supp_hier_type_3     = DECODE(I_change_lvl_3,       'Y', I_supp_hier_type_3,    supp_hier_type_3),
          pickup_lead_time     = DECODE(I_change_pickup_ind,  'Y', I_pickup_lead_time,    pickup_lead_time),
          last_update_datetime = sysdate,
          last_update_id       = user
    where supplier          = I_supplier
      and origin_country_id = I_origin_country_id
      and loc               = I_location
      and item in (select im.item
                     from item_supp_country_loc iscl,
                          item_master im
                    where (im.item_parent         = I_item
                           or im.item_grandparent = I_item)
                      and im.item_level          <= im.tran_level
                      and iscl.item               = im.item
                      and iscl.supplier           = I_supplier
                      and iscl.origin_country_id  = I_origin_country_id
                      and iscl.loc                = I_location);
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             I_item,
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_CHILD_LOCATION;
----------------------------------------------------------------------------------------------
FUNCTION GET_COST(O_error_message     IN OUT VARCHAR2,
                  O_unit_cost         IN OUT ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE,
                  I_item              IN     ITEM_MASTER.ITEM%TYPE,
                  I_supplier          IN     SUPS.SUPPLIER%TYPE,
                  I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                  I_loc               IN     ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(62) := 'ITEM_SUPP_COUNTRY_LOC_SQL.GET_COST';

   cursor C_GET_COST is
      select unit_cost
        from item_supp_country_loc
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country_id
         and loc               = I_loc;

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
   if I_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_loc',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_COST','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id ||
                    ' Location: '||to_char(I_loc));

   open C_GET_COST;
   SQL_LIB.SET_MARK('FETCH','C_GET_COST','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id||
                    ' Location: '||to_char(I_loc));
   fetch C_GET_COST into O_unit_cost;
   SQL_LIB.SET_MARK('CLOSE','C_GET_COST','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id ||
                    ' Location: '||to_char(I_loc));
   close C_GET_COST;
   ----
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_COST;
----------------------------------------------------------------------------------------------
FUNCTION CHECK_LOCATION_FOR_CHILDREN(O_error_message     IN OUT VARCHAR2,
                                     O_exists            IN OUT BOOLEAN,
                                     I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                                     I_supplier          IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                                     I_origin_country_id IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(62)   := 'ITEM_SUPP_COUNTRY_LOC_SQL.CHECK_LOCATION_FOR_CHILDREN';
   L_record       VARCHAR2(1)    := NULL;
   L_child_item   ITEM_MASTER.ITEM%TYPE;

  cursor C_GET_CHILD_ITEMS is
     select im.item
       from item_master im
      where (im.item_parent          = I_item
              or im.item_grandparent = I_item)
        and im.item_level           <= im.tran_level
        and exists (select 'x'
                      from item_supp_country isc
                     where isc.item              = im.item
                       and isc.supplier          = I_supplier
                       and isc.origin_country_id = I_origin_country_id);

   cursor C_CHECK_COUNTRY_LOC is
      select 'x'
       from item_supp_country_loc isl
      where isl.item              = I_item
        and isl.supplier          = I_supplier
        and isl.origin_country_id = I_origin_country_id
        and exists (select 'x'
                      from item_supp_country_loc isl2
                     where isl2.item                 = L_child_item
                       and isl2.supplier             = isl.supplier
                       and isl2.origin_country_id    = isl.origin_country_id
                       and (isl2.unit_cost           != isl.unit_cost
                            or isl2.supp_hier_lvl_1  != NVL(isl.supp_hier_lvl_1,  supp_hier_lvl_1)
                            or isl2.supp_hier_lvl_2  != NVL(isl.supp_hier_lvl_2,  supp_hier_lvl_2)
                            or isl2.supp_hier_lvl_3  != NVL(isl.supp_hier_lvl_3,  supp_hier_lvl_3)
                            or isl2.pickup_lead_time != NVL(isl.pickup_lead_time, pickup_lead_time)));
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
   for C_rec in C_GET_CHILD_ITEMS loop
      L_child_item := C_rec.item;

      SQL_LIB.SET_MARK('OPEN','C_CHECK_COUNTRY_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||L_child_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
      open C_CHECK_COUNTRY_LOC;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_COUNTRY_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||L_child_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
      fetch C_CHECK_COUNTRY_LOC into L_record;
      ---
      if C_CHECK_COUNTRY_LOC%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_COUNTRY_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||L_child_item||
                       ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id);
      close C_CHECK_COUNTRY_LOC;
   end loop;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_LOCATION_FOR_CHILDREN;
-----------------------------------------------------------------------------------------------
FUNCTION GET_LEAD_TIMES(O_error_message       IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        O_total_lead_time     IN OUT   NUMBER,
                        O_lead_time           IN OUT   ITEM_SUPP_COUNTRY_LOC.PICKUP_LEAD_TIME%TYPE,
                        O_pickup_lead_time    IN OUT   ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE,
                        I_item                IN       ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                        I_supplier            IN       ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                        I_origin_country_id   IN       ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                        I_location            IN       ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
   return BOOLEAN is

   L_program   VARCHAR2(62) := 'ITEM_SUPP_COUNTRY_LOC_SQL.GET_LEAD_TIMES';

   cursor C_GET_LEAD_TIME is
      select NVL(lead_time, 0)
        from item_supp_country
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_origin_country_id;

   cursor C_GET_PICKUP_LEAD_TIME is
      select NVL(pickup_lead_time, 0)
        from item_supp_country_loc
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_origin_country_id
         and loc = I_location;

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
   if I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_location',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_LEAD_TIME','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id);
   open C_GET_LEAD_TIME;

   SQL_LIB.SET_MARK('FETCH','C_GET_LEAD_TIME','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id);
   fetch C_GET_LEAD_TIME into O_lead_time;

   SQL_LIB.SET_MARK('CLOSE','C_GET_LEAD_TIME','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id);
   close C_GET_LEAD_TIME;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_PICKUP_LEAD_TIME','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id||
                      ', Location: '||to_char(I_location));
   open C_GET_PICKUP_LEAD_TIME;

   SQL_LIB.SET_MARK('FETCH','C_GET_PICKUP_LEAD_TIME','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id||
                      ', Location: '||to_char(I_location));
   fetch C_GET_PICKUP_LEAD_TIME into O_pickup_lead_time;

   SQL_LIB.SET_MARK('FETCH','C_GET_PICKUP_LEAD_TIME','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id||
                      ', Location: '||to_char(I_location));
   close C_GET_PICKUP_LEAD_TIME;
   ---
   O_total_lead_time := O_lead_time + O_pickup_lead_time;

   return TRUE;


EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_SUPP_COUNTRY_LOC_SQL.GET_LEAD_TIMES',
                                            to_char(SQLCODE));
      return FALSE;
END GET_LEAD_TIMES;
-----------------------------------------------------------------------------------------------
FUNCTION SINGLE_UPDATE(O_error_message       IN OUT  VARCHAR2,
                       I_item                IN      ITEM_MASTER.ITEM%TYPE,
                       I_supplier            IN      SUPS.SUPPLIER%TYPE,
                       I_country             IN      COUNTRY.COUNTRY_ID%TYPE,
                       I_location            IN      ITEM_LOC.LOC%TYPE,
                       I_loc_type            IN      ITEM_LOC.LOC_TYPE%TYPE,
                       I_item_status         IN      ITEM_MASTER.STATUS%TYPE,
                       I_edit_unit_cost      IN      VARCHAR2,
                       I_unit_cost           IN      ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE,
                       I_edit_lvl_1          IN      VARCHAR2,
                       I_supp_hier_lvl_1     IN      ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_1%TYPE,
                       I_edit_lvl_2          IN      VARCHAR2,
                       I_supp_hier_lvl_2     IN      ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_2%TYPE,
                       I_edit_lvl_3          IN      VARCHAR2,
                       I_supp_hier_lvl_3     IN      ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_3%TYPE,
                       I_edit_pickup_ind     IN      VARCHAR2,
                       I_pickup_lead_time    IN      ITEM_SUPP_COUNTRY_LOC.PICKUP_LEAD_TIME%TYPE,
                       I_edit_round_lvl      IN      VARCHAR2,
                       I_round_lvl           IN      ITEM_SUPP_COUNTRY_LOC.ROUND_LVL%TYPE,
                       I_edit_inner_pct      IN      VARCHAR2,
                       I_round_to_inner_pct  IN      ITEM_SUPP_COUNTRY_LOC.ROUND_TO_INNER_PCT%TYPE,
                       I_edit_case_pct       IN      VARCHAR2,
                       I_round_to_case_pct   IN      ITEM_SUPP_COUNTRY_LOC.ROUND_TO_CASE_PCT%TYPE,
                       I_edit_layer_pct      IN      VARCHAR2,
                       I_round_to_layer_pct  IN      ITEM_SUPP_COUNTRY_LOC.ROUND_TO_LAYER_PCT%TYPE,
                       I_edit_pallet_pct     IN      VARCHAR2,
                       I_round_to_pallet_pct IN      ITEM_SUPP_COUNTRY_LOC.ROUND_TO_PALLET_PCT%TYPE,
                       I_default_down_ind    IN      VARCHAR2,
                       I_primary_loc_ind     IN      VARCHAR2)
   return BOOLEAN IS

   L_program   VARCHAR2(62) := 'ITEM_SUPP_COUNTRY_LOC_SQL.SINGLE_UPDATE';
   ---
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   cursor C_ITEM_SUPP_COUNTRY_LOC is
      select unit_cost,
             supp_hier_type_1,
             supp_hier_lvl_1,
             supp_hier_type_2,
             supp_hier_lvl_2,
             supp_hier_type_3,
             supp_hier_lvl_3,
             pickup_lead_time,
             round_lvl,
             round_to_inner_pct,
             round_to_case_pct,
             round_to_layer_pct,
             round_to_pallet_pct,
             primary_loc_ind
        from item_supp_country_loc
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_country
         and loc = I_location
         for update nowait;

   iscl_rec                C_ITEM_SUPP_COUNTRY_LOC%ROWTYPE;
   L_last_update_datetime  DATE := SYSDATE;
   L_last_update_id        USER_ATTRIB.USER_ID%TYPE := USER;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_ITEM_SUPP_COUNTRY_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                                                     ' Supplier: '||to_char(I_supplier)||
                                                     ' Origin Country: '||I_country||
                                                     ' Location: '||to_char(I_location));
   open C_ITEM_SUPP_COUNTRY_LOC;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_SUPP_COUNTRY_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                                                      ' Supplier: '||to_char(I_supplier)||
                                                      ' Origin Country: '||I_country||
                                                      ' Location: '||to_char(I_location));
   fetch C_ITEM_SUPP_COUNTRY_LOC into iscl_rec;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_SUPP_COUNTRY_LOC','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                                                      ' Supplier: '||to_char(I_supplier)||
                                                      ' Origin Country: '||I_country||
                                                      ' Location: '||to_char(I_location));
   close C_ITEM_SUPP_COUNTRY_LOC;
   ---
   if I_supp_hier_lvl_1 is NOT NULL then
      iscl_rec.supp_hier_type_1 := 'S1';
   else
      iscl_rec.supp_hier_type_1 := NULL;
   end if;
   ---
   if I_supp_hier_lvl_2 is NOT NULL then
      iscl_rec.supp_hier_type_2 := 'S2';
   else
      iscl_rec.supp_hier_type_2 := NULL;
   end if;
   ---
   if I_supp_hier_lvl_3 is NOT NULL then
      iscl_rec.supp_hier_type_3 := 'S3';
   else
      iscl_rec.supp_hier_type_3 := NULL;
   end if;
   ---
   if I_edit_unit_cost = 'Y' then
      iscl_rec.unit_cost := I_unit_cost;
   end if;
   ---
   if I_edit_lvl_1 = 'Y' then
      iscl_rec.supp_hier_lvl_1 := I_supp_hier_lvl_1;
   end if;
   ---
   if I_edit_lvl_2 = 'Y' then
      iscl_rec.supp_hier_lvl_2 := I_supp_hier_lvl_2;
   end if;
   ---
   if I_edit_lvl_3 = 'Y' then
      iscl_rec.supp_hier_lvl_3 := I_supp_hier_lvl_3;
   end if;
   ---
   if I_edit_pickup_ind = 'Y' then
      iscl_rec.pickup_lead_time := I_pickup_lead_time;
   end if;
   ---
   if I_edit_round_lvl = 'Y' then
      iscl_rec.round_lvl := I_round_lvl;
   end if;
   ---
   if I_edit_inner_pct = 'Y' then
      iscl_rec.round_to_inner_pct := I_round_to_inner_pct;
   end if;
   ---
   if I_edit_case_pct = 'Y' then
      iscl_rec.round_to_case_pct := I_round_to_case_pct;
   end if;
   ---
   if I_edit_layer_pct = 'Y' then
      iscl_rec.round_to_layer_pct := I_round_to_layer_pct;
   end if;
   ---
   if I_edit_pallet_pct = 'Y' then
      iscl_rec.round_to_pallet_pct := I_round_to_pallet_pct;
   end if;
   ---
   if I_primary_loc_ind = 'Y' then
      iscl_rec.primary_loc_ind := I_primary_loc_ind;
   end if;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                                                          ' Supplier: '||to_char(I_supplier)||
                                                          ' Origin Country: '||I_country||
                                                          ' Location: '||to_char(I_location));
   UPDATE item_supp_country_loc
      SET unit_cost = iscl_rec.unit_cost,
          round_lvl = iscl_rec.round_lvl,
          round_to_inner_pct = iscl_rec.round_to_inner_pct,
          round_to_case_pct = iscl_rec.round_to_case_pct,
          round_to_layer_pct = iscl_rec.round_to_layer_pct,
          round_to_pallet_pct = iscl_rec.round_to_pallet_pct,
          supp_hier_type_1 = iscl_rec.supp_hier_type_1,
          supp_hier_lvl_1 = iscl_rec.supp_hier_lvl_1,
          supp_hier_type_2 = iscl_rec.supp_hier_type_2,
          supp_hier_lvl_2 = iscl_rec.supp_hier_lvl_2,
          supp_hier_type_3 = iscl_rec.supp_hier_type_3,
          supp_hier_lvl_3 = iscl_rec.supp_hier_lvl_3,
          pickup_lead_time = iscl_rec.pickup_lead_time,
          primary_loc_ind = iscl_rec.primary_loc_ind,
          last_update_datetime = L_last_update_datetime,
          last_update_id = L_last_update_id
    WHERE item = I_item
      AND supplier = I_supplier
      AND origin_country_id = I_country
      AND loc = I_location;
   ---
   if I_default_down_ind = 'Y' then
      if ITEM_SUPP_COUNTRY_LOC_SQL.UPDATE_CHILD_LOCATION(O_error_message,
                                                         I_edit_round_lvl,
                                                         I_round_lvl,
                                                         I_edit_inner_pct,
                                                         I_round_to_inner_pct,
                                                         I_edit_case_pct,
                                                         I_round_to_case_pct,
                                                         I_edit_layer_pct,
                                                         I_round_to_layer_pct,
                                                         I_edit_pallet_pct,
                                                         I_round_to_pallet_pct,
                                                         I_edit_lvl_1,
                                                         iscl_rec.supp_hier_type_1,
                                                         I_supp_hier_lvl_1,
                                                         I_edit_lvl_2,
                                                         iscl_rec.supp_hier_type_2,
                                                         I_supp_hier_lvl_2,
                                                         I_edit_lvl_3,
                                                         iscl_rec.supp_hier_type_3,
                                                         I_supp_hier_lvl_3,
                                                         I_edit_pickup_ind,
                                                         I_pickup_lead_time,
                                                         I_item,
                                                         I_supplier,
                                                         I_country,
                                                         I_location) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if I_primary_loc_ind = 'Y' then
      if SUPP_ITEM_SQL.UPDATE_PRIMARY_INDICATORS(O_error_message,
                                                 I_item,
                                                 I_supplier,
                                                 I_country,
                                                 I_location,
                                                 I_default_down_ind) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   --- Change loc needs cost changes first.
   if I_item_status != 'A' and (I_edit_unit_cost = 'Y' or I_primary_loc_ind = 'Y') then
      if UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                      I_item,
                                      I_supplier,
                                      I_country,
                                      I_location,
                                      I_default_down_ind,
                                      I_edit_unit_cost,
                                      NULL) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   --- Change loc writes price_hist records after primary locations change.
   if I_primary_loc_ind = 'Y' then
      if UPDATE_BASE_COST.CHANGE_LOC(O_error_message,
                                     I_item,
                                     I_supplier,
                                     I_country,
                                     I_location,
                                     I_default_down_ind) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             'ITEM_SUPP_COUNTRY_LOC',
                                             NULL,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_SUPP_COUNTRY_LOC_SQL.SINGLE_UPDATE',
                                            to_char(SQLCODE));
      return FALSE;
END SINGLE_UPDATE;
-----------------------------------------------------------------------------------------------
FUNCTION GET_ISCL(O_error_message       IN OUT VARCHAR2,
                  O_currency_code       IN OUT STORE.CURRENCY_CODE%TYPE,
                  O_case_cost           IN OUT NUMBER,
                  O_unit_cost           IN OUT ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE,
                  O_round_lvl           IN OUT ITEM_SUPP_COUNTRY_LOC.ROUND_LVL%TYPE,
                  O_round_to_inner_pct  IN OUT ITEM_SUPP_COUNTRY_LOC.ROUND_TO_INNER_PCT%TYPE,
                  O_round_to_case_pct   IN OUT ITEM_SUPP_COUNTRY_LOC.ROUND_TO_CASE_PCT%TYPE,
                  O_round_to_layer_pct  IN OUT ITEM_SUPP_COUNTRY_LOC.ROUND_TO_LAYER_PCT%TYPE,
                  O_round_to_pallet_pct IN OUT ITEM_SUPP_COUNTRY_LOC.ROUND_TO_PALLET_PCT%TYPE,
                  O_supp_hier_type_1    IN OUT ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_1%TYPE,
                  O_supp_hier_type_2    IN OUT ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_2%TYPE,
                  O_supp_hier_type_3    IN OUT ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_TYPE_3%TYPE,
                  O_supp_hier_lvl_1     IN OUT ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_1%TYPE,
                  O_supp_hier_lvl_2     IN OUT ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_2%TYPE,
                  O_supp_hier_lvl_3     IN OUT ITEM_SUPP_COUNTRY_LOC.SUPP_HIER_LVL_3%TYPE,
                  O_pickup_lead_time    IN OUT ITEM_SUPP_COUNTRY_LOC.PICKUP_LEAD_TIME%TYPE,
                  I_item              IN     ITEM_MASTER.ITEM%TYPE,
                  I_supplier          IN     SUPS.SUPPLIER%TYPE,
                  I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                  I_loc               IN     ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(62) := 'ITEM_SUPP_COUNTRY_LOC_SQL.GET_ISCL';

   cursor C_GET_ISCL is
      select decode(w.currency_code, NULL, s.currency_code, w.currency_code) curr_code,
             isc.supp_pack_size * iscl.unit_cost case_cost,
             iscl.unit_cost,
             iscl.round_lvl,
             iscl.round_to_inner_pct,
             iscl.round_to_case_pct,
             iscl.round_to_layer_pct,
             iscl.round_to_pallet_pct,
             iscl.supp_hier_type_1,
             iscl.supp_hier_type_2,
             iscl.supp_hier_type_3,
             iscl.supp_hier_lvl_1,
             iscl.supp_hier_lvl_2,
             iscl.supp_hier_lvl_3,
             iscl.pickup_lead_time
        from item_supp_country_loc iscl,
             store s,
             wh w,
             item_supp_country isc
       where iscl.item         = I_item
         and iscl.supplier          = I_supplier
         and iscl.origin_country_id = I_origin_country_id
         and iscl.loc          = I_loc
         and iscl.loc          = w.wh(+)
         and iscl.loc          = s.store(+)
         and isc.item          = iscl.item
         and isc.supplier      = iscl.supplier;


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
   if I_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_loc',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_ISCL','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id ||
                    ' Location: '||to_char(I_loc));

   open C_GET_ISCL;
   SQL_LIB.SET_MARK('FETCH','C_GET_ISCL','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id||
                    ' Location: '||to_char(I_loc));
   fetch C_GET_ISCL into O_currency_code,
                         O_case_cost,
                         O_unit_cost,
                         O_round_lvl,
                         O_round_to_inner_pct,
                         O_round_to_case_pct,
                         O_round_to_layer_pct,
                         O_round_to_pallet_pct,
                         O_supp_hier_type_1,
                         O_supp_hier_type_2,
                         O_supp_hier_type_3,
                         O_supp_hier_lvl_1,
                         O_supp_hier_lvl_2,
                         O_supp_hier_lvl_3,
                         O_pickup_lead_time;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ISCL','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Country: '|| I_origin_country_id ||
                    ' Location: '||to_char(I_loc));
   close C_GET_ISCL;
   ----
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ISCL;
------------------------------------------------------------------------------------
FUNCTION BULK_INSERT(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     I_locs            IN       LOC_TBL,
                     I_iscl_def        IN       ITEM_SUPP_COUNTRY_LOC%ROWTYPE)

   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_LOC.BULK_INSERT';

BEGIN

   FORALL i in I_locs.FIRST..I_locs.LAST
      insert into item_supp_country_loc(item,
                                        supplier,
                                        origin_country_id,
                                        loc,
                                        loc_type,
                                        primary_loc_ind,
                                        unit_cost,
                                        round_lvl,
                                        round_to_inner_pct,
                                        round_to_case_pct,
                                        round_to_layer_pct,
                                        round_to_pallet_pct,
                                        supp_hier_type_1,
                                        supp_hier_lvl_1,
                                        supp_hier_type_2,
                                        supp_hier_lvl_2,
                                        supp_hier_type_3,
                                        supp_hier_lvl_3,
                                        pickup_lead_time,
                                        create_datetime,
                                        last_update_datetime,
                                        last_update_id)
                                values( I_iscl_def.item,
                                        I_iscl_def.supplier,
                                        I_iscl_def.origin_country_id,
                                        I_locs(i),
                                        I_iscl_def.loc_type,
                                        I_iscl_def.primary_loc_ind,
                                        I_iscl_def.unit_cost,
                                        I_iscl_def.round_lvl,
                                        I_iscl_def.round_to_inner_pct,
                                        I_iscl_def.round_to_case_pct,
                                        I_iscl_def.round_to_layer_pct,
                                        I_iscl_def.round_to_pallet_pct,
                                        I_iscl_def.supp_hier_type_1,
                                        I_iscl_def.supp_hier_lvl_1,
                                        I_iscl_def.supp_hier_type_2,
                                        I_iscl_def.supp_hier_lvl_2,
                                        I_iscl_def.supp_hier_type_3,
                                        I_iscl_def.supp_hier_lvl_3,
                                        I_iscl_def.pickup_lead_time,
                                        I_iscl_def.create_datetime,
                                        sysdate,
                                        I_iscl_def.last_update_id);

   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END BULK_INSERT;
------------------------------------------------------------------------------------
FUNCTION BULK_DELETE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     I_locs            IN       LOC_TBL,
                     I_supplier        IN       ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                     I_country         IN       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                     I_item            IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'UPDATE_BASE_COST.BULK_ISCL';
   L_user            USER_ATTRIB.USER_ID%TYPE := user;
   TAB_rowids        ROWID_TBL; --- Type declared at package level
   L_rowid           rowid;
   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ISCL is
      select rowid
        from item_supp_country_loc
       where loc in (select *
                       from TABLE(cast(I_locs as LOC_TBL)))
         and supplier = I_supplier
         and origin_country_id = I_country
         and item = I_item
         for update nowait;

   cursor C_LOCK_ISCL_SINGLE is   -- Single item
      select rowid
        from item_supp_country_loc
       where loc  = I_locs(1)
         and supplier = I_supplier
         and origin_country_id = I_country
         and item = I_item
         for update nowait;

BEGIN

   if I_locs.COUNT > 1 then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ISCL','item',null);
      open  C_LOCK_ISCL;

      SQL_LIB.SET_MARK('FETCH','C_LOCK_ISCL','item',null);
      fetch  C_LOCK_ISCL BULK COLLECT into TAB_rowids;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISCL','item',null);
      close C_LOCK_ISCL;

      if TAB_rowids is NOT NULL and TAB_rowids.COUNT > 0 then
         FORALL i in TAB_rowids.FIRST..TAB_rowids.LAST
            delete from item_supp_country_loc
             where rowid = TAB_rowids(i);
         ---
         if SQL%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('COULD_NOT_DELETE_REC', NULL, NULL, NULL);
            return FALSE;
         end if;
      end if;


   elsif I_locs.COUNT = 1 then

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ISCL_SINGLE','item',null);
      open  C_LOCK_ISCL_SINGLE;

      SQL_LIB.SET_MARK('FETCH','C_LOCK_ISCL_SINGLE','item',null);
      fetch  C_LOCK_ISCL_SINGLE into L_rowid;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISCL_SINGLE','item',null);
      close C_LOCK_ISCL_SINGLE;

      if L_rowid is NOT NULL then
         delete from item_supp_country_loc
          where rowid = L_rowid;
         ---
         if SQL%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('COULD_NOT_DELETE_REC', NULL, NULL, NULL);
            return FALSE;
         end if;
      end if;

   end if;

   ---


   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_SUPP_COUNTRY_LOC',
                                             NULL,
                                             NULL);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END BULK_DELETE;
-------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_YES_PRIM_IND(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_iscl_rec      IN ITEM_SUPP_COUNTRY_LOC%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_LOC_SQL.UPDATE_YES_PRIM_IND';

--- NOTE:  only used for XITEM subscription API after UPDATE_PRIMARY_INDICATORS is called
---
BEGIN
   if not LOCK_ITEM_SUPP_COUNTRY_LOC(O_error_message,
                                     I_iscl_rec.item,
                                     I_iscl_rec.supplier,
                                     I_iscl_rec.origin_country_id,
                                     I_iscl_rec.loc) then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_SUPP_COUNTRY_LOC','item: '||I_iscl_rec.item||
                                                    ' supplier: '||I_iscl_rec.supplier||
                                                    ' country: '||I_iscl_rec.origin_country_id||
                                                    ' loc: '||I_iscl_rec.loc);

   update ITEM_SUPP_COUNTRY_LOC
      set  primary_loc_ind = 'Y',
           last_update_datetime = sysdate,
           last_update_id = I_iscl_rec.last_update_id
    where item = I_iscl_rec.item
      and supplier = I_iscl_rec.supplier
      and origin_country_id = I_iscl_rec.origin_country_id
      and loc = I_iscl_rec.loc;
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
------------------------------------------------------------------------------------
FUNCTION SINGLE_INSERT(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_iscl_def        IN       ITEM_SUPP_COUNTRY_LOC%ROWTYPE)

   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_LOC.SINGLE_INSERT';

BEGIN

   insert into item_supp_country_loc(item,
                                     supplier,
                                     origin_country_id,
                                     loc,
                                     loc_type,
                                     primary_loc_ind,
                                     unit_cost,
                                     round_lvl,
                                     round_to_inner_pct,
                                     round_to_case_pct,
                                     round_to_layer_pct,
                                     round_to_pallet_pct,
                                     supp_hier_type_1,
                                     supp_hier_lvl_1,
                                     supp_hier_type_2,
                                     supp_hier_lvl_2,
                                     supp_hier_type_3,
                                     supp_hier_lvl_3,
                                     pickup_lead_time,
                                     create_datetime,
                                     last_update_datetime,
                                     last_update_id)
                             values( I_iscl_def.item,
                                     I_iscl_def.supplier,
                                     I_iscl_def.origin_country_id,
                                     I_iscl_def.loc,
                                     I_iscl_def.loc_type,
                                     I_iscl_def.primary_loc_ind,
                                     I_iscl_def.unit_cost,
                                     I_iscl_def.round_lvl,
                                     I_iscl_def.round_to_inner_pct,
                                     I_iscl_def.round_to_case_pct,
                                     I_iscl_def.round_to_layer_pct,
                                     I_iscl_def.round_to_pallet_pct,
                                     I_iscl_def.supp_hier_type_1,
                                     I_iscl_def.supp_hier_lvl_1,
                                     I_iscl_def.supp_hier_type_2,
                                     I_iscl_def.supp_hier_lvl_2,
                                     I_iscl_def.supp_hier_type_3,
                                     I_iscl_def.supp_hier_lvl_3,
                                     I_iscl_def.pickup_lead_time,
                                     I_iscl_def.create_datetime,
                                     sysdate,
                                     I_iscl_def.last_update_id);
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END SINGLE_INSERT;
-------------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
FUNCTION LOCK_ITEM_SUPP_COUNTRY_LOC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item          IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                                    I_supplier      IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                                    I_country       IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                                    I_loc           IN     ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_SQL.LOCK_ITEM_SUPP_COUNTRY_LOC';
   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);

   CURSOR C_LOCK_ISCL IS
      select 'x'
        from ITEM_SUPP_COUNTRY_LOC
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_country
         and loc = I_loc
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCL', 'ITEM_SUPP_COUNTRY_LOC','item: '||I_item||
                                                    ' supplier: '||I_supplier||
                                                    ' country: '||I_country||
                                                    ' loc: '||I_loc);

   open C_LOCK_ISCL;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCL', 'ITEM_SUPP_COUNTRY_LOC','item: '||I_item||
                                                    ' supplier: '||I_supplier||
                                                    ' country: '||I_country||
                                                    ' loc: '||I_loc);

   close C_LOCK_ISCL;
   ---
   return TRUE;
EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_SUPP_COUNTRY_LOC',
                                             NULL,
                                             NULL);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END LOCK_ITEM_SUPP_COUNTRY_LOC;
-----------------------------------------------------------------------------------------------
FUNCTION GET_ROW(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                 O_exists          IN OUT   BOOLEAN,
                 O_iscl_rec        IN OUT   ITEM_SUPP_COUNTRY_LOC%ROWTYPE,
                 I_item            IN       ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                 I_supplier        IN       ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                 I_country         IN       ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                 I_location        IN       ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
   RETURN BOOLEAN IS
   L_program   VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_LOC_SQL.GET_ROW';
   cursor C_GET_ISCL_REC is
      select *
        from item_supp_country_loc
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_country
         and loc               = I_location;
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

   if I_country is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_country',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   if I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_location',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   O_exists := NULL;
   SQL_LIB.SET_MARK('OPEN','C_GET_ISCL_REC','ITEM_SUPP_COUNTRY_LOC',NULL);
   open C_GET_ISCL_REC;
   SQL_LIB.SET_MARK('FETCH','C_GET_ISCL_REC','ITEM_SUPP_COUNTRY_LOC',NULL);
   fetch C_GET_ISCL_REC INTO O_iscl_rec;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ISCL_REC','ITEM_SUPP_COUNTRY_LOC',NULL);
   close C_GET_ISCL_REC;
   ---

   O_exists := (O_iscl_rec.item is NOT NULL);

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

FUNCTION GET_LAST_RECEIPT_COST(O_error_message       IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               O_last_receipt_cost   IN OUT  SHIPSKU.UNIT_COST%TYPE,
                               I_item                IN      SHIPSKU.ITEM%TYPE,
                               I_supplier            IN      ORDHEAD.SUPPLIER%TYPE,
                               I_location            IN      SHIPMENT.TO_LOC%TYPE)
   RETURN BOOLEAN IS
   L_program   VARCHAR2(50) := 'ITEM_SUPP_COUNTRY_LOC_SQL.GET_LAST_RECEIPT_COST';
   cursor C_GET_LAST_RECEIPT_COST is
      select sk.unit_cost
        from shipment sh,
             shipsku  sk,
             ordhead  oh
       where oh.order_no       = sh.order_no
         and oh.supplier       = I_supplier
         and sh.shipment       = sk.shipment
         and sh.to_loc         = I_location
         and sk.item           = I_item
         and sh.receive_date   = ( select max(sh1.receive_date)
                                     from shipment sh1,
                                          shipsku  sk1,
                                          ordhead  oh1
                                    where oh1.order_no       = sh1.order_no
                                      and oh1.supplier       = I_supplier
                                      and sh1.shipment       = sk1.shipment
                                      and sh1.to_loc         = I_location
                                      and sk1.item           = I_item);
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
   if I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_location',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_LAST_RECEIPT_COST',
                    'ORDHEAD,SHIPMENT,SHIPSKU',
                    'Item '||I_item||' Supplier '||I_supplier||' Location '||I_location);
   open C_GET_LAST_RECEIPT_COST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_LAST_RECEIPT_COST',
                    'ORDHEAD,SHIPMENT,SHIPSKU',
                    'Item '||I_item||' Supplier '||I_supplier||' Location '||I_location);
   fetch C_GET_LAST_RECEIPT_COST INTO O_last_receipt_cost;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_LAST_RECEIPT_COST',
                    'ORDHEAD,SHIPMENT,SHIPSKU',
                    'Item '||I_item||' Supplier '||I_supplier||' Location '||I_location);
   close C_GET_LAST_RECEIPT_COST;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_LAST_RECEIPT_COST;
-------------------------------------------------------------------------------------------------------
--04-Jul-2007 WiproEnabler/Ramasamy - MOD 365b   Begin
   ---------------------------------------------------------------------------------------------------------------
   --TSL_DEFAULT_LOC_TO_VARIANTS   Insert locations for variant items from item_supp_country when locations exist on
   -- item_loc, but the corresponding item_supp_country_loc records do not yet exist.  Furthermore, this function will
   -- update all variant items on item_supp_country_loc when changes are made to the location default information of
   -- the base item on item_supp_country and the user wishes to default those changes down.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_DEFAULT_LOC_TO_VARIANTS(O_error_message     IN OUT VARCHAR2,
                                        I_item              IN     ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                                        I_supplier          IN     ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                                        I_origin_country_id IN     ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                                        I_edit_cost         IN     VARCHAR2,
                                        I_update_all_locs   IN     VARCHAR2)
      return BOOLEAN is

      L_program            VARCHAR2(64) := 'ITEM_SUPP_COUNTRY_LOC_SQL.TSL_DEFAULT_LOC_TO_VARIANTS';
      L_insert_update_locs VARCHAR2(1)  := 'N';
      --This cursor all the Variant Items associated to the passed Base Item, that have the passed
      --Supplier/Origin Country/Location associated
      cursor C_GET_VARIANT_ITEMS is
         select im.item
           from item_master       im,
                item_supp_country isc
          where im.tsl_base_item      = I_item
            and im.tsl_base_item      != im.item
            and im.item_level         = im.tran_level
            and im.item_level         = 2
            and im.item               = isc.item
            and isc.supplier          = I_supplier
            and isc.origin_country_Id = I_origin_country_id;

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
      if I_update_all_locs is NULL then
         L_insert_update_locs := 'Y';
      end if;
      --
      --Opening the cursor C_GET_VARIANT_ITEMS
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_VARIANT_ITEMS',
                       'ITEM_MASTER, ITEM_SUPP_COUNTRY',
                       'ITEM: ' || I_item);
      FOR C_rec in C_GET_VARIANT_ITEMS
      LOOP
         --Executing the package function
         if NOT
             ITEM_SUPP_COUNTRY_LOC_SQL.UPDATE_LOCATION(O_error_message     => O_error_message,
                                                       I_item              => C_rec.item,
                                                       I_supplier          => I_supplier,
                                                       I_origin_country_id => I_origin_country_id,
                                                       I_edit_cost         => I_edit_cost,
                                                       I_update_all_locs   => I_update_all_locs) then
            return FALSE;
         end if;
         --
         if L_insert_update_locs = 'Y' then
            --
            --Executing the package function
            if NOT ITEM_SUPP_COUNTRY_LOC_SQL.CREATE_LOCATION(O_error_message     => O_error_message,
                                                             I_item              => C_rec.item ,
                                                             I_supplier          => I_supplier ,
                                                             I_origin_country_id => I_origin_country_id ,
                                                             I_loc               => NULL) then
               return FALSE;
            end if;
         end if;
         --
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
   END TSL_DEFAULT_LOC_TO_VARIANTS;
   ---------------------------------------------------------------------------------------------------------------
--04-Jul-2007 WiproEnabler/Ramasamy - MOD 365b   End
END ITEM_SUPP_COUNTRY_LOC_SQL;
/

