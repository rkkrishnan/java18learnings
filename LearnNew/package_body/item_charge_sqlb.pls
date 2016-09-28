CREATE OR REPLACE PACKAGE BODY ITEM_CHARGE_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    27-Jun-2007
--Mod Ref:     Mod number. 365b1
--Mod Details: Cascading the base item charges to its variants.
--             Appeneded TSL_DEFAULT_BASE_CHRGS new function.
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--Mod By     : Usha Patil, usha.patil@in.tesco.com
--Mod Date   : 26-Mar-2010
--Mod Ref    : CR275
--Mod Details: Modified DEFAULT_CHARGES to restrict the insertion of item_chrg_head and details
--             for IC transfers.
------------------------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_EXTERNAL_FINISHER V_INTERNAL_FINISHER V_LOC_LIST_HEAD V_STORE V_WH
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION INSERT_TEMP(O_error_message   IN OUT VARCHAR2,
                     I_item            IN     ITEM_MASTER.ITEM%TYPE,
                     I_zone_group_id   IN     COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                     I_from_group_type IN     CODE_DETAIL.CODE%TYPE,
                     I_from_group      IN     STORE.STORE%TYPE,
                     I_to_group_type   IN     CODE_DETAIL.CODE%TYPE,
                     I_to_group        IN     STORE.STORE%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_CHARGE_SQL.INSERT_TEMP';

BEGIN
   if I_from_group_type in ('A','R','D','AS') then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select s.store,
                                'S'
                           from v_store s
                          where s.stockholding_ind = 'Y'
                            and ((I_from_group_type = 'A'
                                  and s.area = I_from_group)
                                or (I_from_group_type = 'R'
                                    and s.region = I_from_group)
                                or (I_from_group_type = 'D'
                                    and s.district = I_from_group)
                                or (I_from_group_type = 'AS'))
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = s.store);
   elsif I_from_group_type = 'AW' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select wh,
                                'W'
                           from v_wh
                          where stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = wh);
   elsif I_from_group_type = 'PW' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select wh,
                                'W'
                           from v_wh
                          where stockholding_ind = 'Y'
                            and physical_wh = I_from_group
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = wh);
   elsif I_from_group_type = 'LL' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select d.location,
                                'S'
                           from v_loc_list_head vllh,
                                v_store vs,
                                loc_list_detail d
                          where vllh.loc_list = I_from_group
                            and vllh.loc_list = d.loc_list
                            and vs.store = d.location
                            and vs.stockholding_ind = 'Y'
                            and d.loc_type = 'S'
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = d.location);
      ---
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select w.wh,
                                'W'
                           from v_loc_list_head vllh,
                                loc_list_detail d,
                                v_wh w
                          where vllh.loc_list = I_from_group
                            and vllh.loc_list = d.loc_list
                            and d.loc_type = 'W'
                            and d.location = w.wh
                            and w.stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = w.wh);
      ---
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select w.wh,
                                'W'
                           from v_loc_list_head vllh,
                                loc_list_detail d,
                                v_wh w
                          where vllh.loc_list = I_from_group
                            and vllh.loc_list = d.loc_list
                            and d.loc_type = 'W'
                            and d.location = w.physical_wh
                            and w.stockholding_ind = 'Y'
                            and not exists (select 'x'
                                              from from_loc_temp t
                                             where t.from_loc = w.wh)
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = w.wh);
   elsif I_from_group_type = 'AL' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select store,
                                'S'
                           from v_store
                          where stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = store)
                          UNION
                         select wh,
                                'W'
                           from v_wh
                          where stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from item_chrg_head i
                                          where i.item = I_item
                                            and i.from_loc = wh)
                          union
                         select finisher_id,
                                'W'
                           from v_internal_finisher
                          where exists (select 'x'
                                          from item_chrg_head i
                                         where i.item     = I_item
                                           and i.from_loc = finisher_id)
                          union
                         select finisher_id,
                                'E'
                           from v_external_finisher
                          where exists (select 'x'
                                          from item_chrg_head i
                                         where i.item     = I_item
                                           and i.from_loc = finisher_id);
   elsif I_from_group_type = 'AI' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select finisher_id,
                                'W'
                           from v_internal_finisher
                          where exists (select 'x'
                                          from item_chrg_head i
                                         where i.item     = I_item
                                           and i.from_loc = finisher_id);
   elsif I_from_group_type = 'AE' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select finisher_id,
                                'E'
                           from v_external_finisher
                          where exists (select 'x'
                                          from item_chrg_head i
                                         where i.item     = I_item
                                           and i.from_loc = finisher_id);

   elsif I_from_group_type = 'CZ' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select c.location,
                                c.loc_type
                           from cost_zone_group_loc c,
                                v_store s
                          where s.store = c.location
                            and c.loc_type = 'S'
                            and s.stockholding_ind = 'Y'
                            and c.zone_group_id = I_zone_group_id
                            and c.zone_id = I_from_group
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = c.location)
                          UNION
                         select c.location,
                                c.loc_type
                           from cost_zone_group_loc c,
                                v_wh w
                          where w.wh = c.location
                            and c.loc_type = 'W'
                            and w.stockholding_ind = 'Y'
                            and c.zone_group_id = I_zone_group_id
                            and c.zone_id = I_from_group
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = c.location);
   elsif I_from_group_type = 'T' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select store,
                                'S'
                           from v_store
                          where stockholding_ind = 'Y'
                            and transfer_zone = I_from_group
                            and exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = store);
   elsif I_from_group_type in ('S','W','I','E') then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select I_from_group,
                                DECODE(I_from_group_type, 'I', 'W', I_from_group_type)
                           from dual
                          where exists (select 'x'
                                          from item_chrg_head i
                                         where i.item = I_item
                                           and i.from_loc = I_from_group);
   end if;
   ---
   if I_to_group_type in ('A','R','D','AS') then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select s.store,
                              'S'
                         from v_store s
                        where s.stockholding_ind = 'Y'
                          and ((I_to_group_type = 'A'
                                and s.area = I_to_group)
                              or (I_to_group_type = 'R'
                                  and s.region = I_to_group)
                              or (I_to_group_type = 'D'
                                  and s.district = I_to_group)
                              or (I_to_group_type = 'AS'))
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = s.store);
   elsif I_to_group_type = 'AW' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select wh,
                              'W'
                         from v_wh
                        where stockholding_ind = 'Y'
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = wh);
   elsif I_to_group_type = 'PW' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select wh,
                              'W'
                         from v_wh
                        where stockholding_ind = 'Y'
                          and physical_wh = I_to_group
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = wh);
   elsif I_to_group_type = 'LL' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select d.location,
                              'S'
                         from v_loc_list_head vllh,
                              v_store vs,
                              loc_list_detail d
                        where vllh.loc_list = I_to_group
                          and vllh.loc_list = d.loc_list
                          and vs.store = d.location
                          and vs.stockholding_ind = 'Y'
                          and d.loc_type = 'S'
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = d.location);
      ---
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select w.wh,
                              'W'
                         from v_loc_list_head vllh,
                              loc_list_detail d,
                              v_wh w
                        where vllh.loc_list = I_to_group
                          and vllh.loc_list = d.loc_list
                          and d.loc_type = 'W'
                          and d.location = w.wh
                          and w.stockholding_ind = 'Y'
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = w.wh);
      ---
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select w.wh,
                              'W'
                         from v_loc_list_head vllh,
                              loc_list_detail d,
                              v_wh w
                        where vllh.loc_list = I_to_group
                          and vllh.loc_list = d.loc_list
                          and d.loc_type = 'W'
                          and d.location = w.physical_wh
                          and w.stockholding_ind = 'Y'
                          and not exists (select 'x'
                                            from to_loc_temp t
                                           where t.to_loc = w.wh)
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = w.wh);
   elsif I_to_group_type = 'AL' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select store,
                              'S'
                         from v_store
                        where stockholding_ind = 'Y'
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = store)
                        UNION
                       select wh,
                              'W'
                         from v_wh
                        where stockholding_ind = 'Y'
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = wh)
                       union
                      select finisher_id,
                             'W'
                        from v_internal_finisher
                       where exists (select 'x'
                                       from item_chrg_head i
                                      where i.item     = I_item
                                        and i.to_loc = finisher_id)
                       union
                      select finisher_id,
                             'E'
                        from v_external_finisher
                       where exists (select 'x'
                                       from item_chrg_head i
                                      where i.item     = I_item
                                        and i.to_loc = finisher_id);

   elsif I_to_group_type = 'AI' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select finisher_id,
                             'W'
                        from v_internal_finisher
                       where exists (select 'x'
                                       from item_chrg_head i
                                      where i.item     = I_item
                                        and i.to_loc = finisher_id);

   elsif I_to_group_type = 'AE' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                      select finisher_id,
                             'E'
                        from v_external_finisher
                       where exists (select 'x'
                                       from item_chrg_head i
                                      where i.item     = I_item
                                        and i.to_loc = finisher_id);


   elsif I_to_group_type = 'CZ' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select c.location,
                              c.loc_type
                         from cost_zone_group_loc c,
                              v_store s
                        where s.store = c.location
                          and c.loc_type = 'S'
                          and s.stockholding_ind = 'Y'
                          and c.zone_group_id = I_zone_group_id
                          and c.zone_id = I_to_group
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = c.location)
                        UNION
                       select c.location,
                              c.loc_type
                         from cost_zone_group_loc c,
                              v_wh w
                        where w.wh = c.location
                          and c.loc_type = 'W'
                          and w.stockholding_ind = 'Y'
                          and c.zone_group_id = I_zone_group_id
                          and c.zone_id = I_to_group
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = c.location);
   elsif I_to_group_type = 'T' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select store,
                              'S'
                         from v_store
                        where stockholding_ind = 'Y'
                          and transfer_zone = I_to_group
                          and exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = store);
   elsif I_to_group_type in ('S','W','I','E') then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select I_to_group,
                              DECODE(I_to_group_type, 'I', 'W', I_to_group_type)
                         from dual
                        where exists (select 'x'
                                        from item_chrg_head i
                                       where i.item = I_item
                                         and i.to_loc = I_to_group);
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
END INSERT_TEMP;

---------------------------------------------------------------------------------
-- Function Name: INSERT_MC_TEMP
-- Purpose:       This function is used for the item list column
--                of the MC_CHRG_HEAD and the MC_CHRG_DETAIL tables.
--                This function retrieves data from V_EXTERNAL_FINISHER,
--                V_INTERNAL_FINISHER, V_LOC_LIST_HEAD, V_STORE and V_WH which
--                only returns data that the user has permission to access.
----------------------------------------------------------------------------------
FUNCTION INSERT_MC_TEMP(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        I_item_list         IN       MC_CHRG_HEAD.ITEM_LIST%TYPE,
                        I_zone_group_id     IN       COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                        I_from_group_type   IN       CODE_DETAIL.CODE%TYPE,
                        I_from_group        IN       STORE.STORE%TYPE,
                        I_to_group_type     IN       CODE_DETAIL.CODE%TYPE,
                        I_to_group          IN       STORE.STORE%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_CHARGE_SQL.INSERT_MC_TEMP';

BEGIN
   if I_from_group_type in ('A','R','D','AS') then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select s.store,
                                'S'
                           from v_store s
                          where s.stockholding_ind    = 'Y'
                            and ((I_from_group_type   = 'A'
                                    and s.area        = I_from_group)
                                or (I_from_group_type = 'R'
                                    and s.region      = I_from_group)
                                or (I_from_group_type = 'D'
                                    and s.district    = I_from_group)
                                or (I_from_group_type = 'AS'))
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = s.store);

   elsif I_from_group_type = 'AW' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select wh,
                                'W'
                           from v_wh
                          where stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = wh);

   elsif I_from_group_type = 'PW' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select wh,
                                'W'
                           from v_wh
                          where stockholding_ind = 'Y'
                            and physical_wh      = I_from_group
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = wh);

   elsif I_from_group_type = 'LL' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select d.location,
                                'S'
                           from v_loc_list_head vllh,
                                v_store vs,
                                loc_list_detail d
                          where vllh.loc_list       = I_from_group
                            and vllh.loc_list       = d.loc_list
                            and vs.store            = d.location
                            and vs.stockholding_ind = 'Y'
                            and d.loc_type          = 'S'
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = d.location);
      ---
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select w.wh,
                                'W'
                           from v_loc_list_head vllh,
                                loc_list_detail d,
                                v_wh w
                          where vllh.loc_list      = I_from_group
                            and vllh.loc_list      = d.loc_list
                            and d.loc_type         = 'W'
                            and d.location         = w.wh
                            and w.stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = w.wh);
      ---
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select w.wh,
                                'W'
                           from v_loc_list_head vllh,
                                loc_list_detail d,
                                v_wh w
                          where vllh.loc_list      = I_from_group
                            and vllh.loc_list      = d.loc_list
                            and d.loc_type         = 'W'
                            and d.location         = w.physical_wh
                            and w.stockholding_ind = 'Y'
                            and not exists (select 'x'
                                              from from_loc_temp t
                                             where t.from_loc = w.wh)
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = w.wh);

   elsif I_from_group_type = 'AL' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select store,
                                'S'
                           from v_store
                          where stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = store)
                          UNION
                         select wh,
                                'W'
                           from v_wh
                          where stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                          where mc.item_list = I_item_list
                                            and mc.from_loc  = wh)
                          union
                         select finisher_id,
                                'W'
                           from v_internal_finisher
                          where exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = finisher_id)
                          union
                         select finisher_id,
                                'E'
                           from v_external_finisher
                          where exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = finisher_id);

   elsif I_from_group_type = 'AI' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select finisher_id,
                                'W'
                           from v_internal_finisher
                          where exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = finisher_id);

   elsif I_from_group_type = 'AE' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select finisher_id,
                                'E'
                           from v_external_finisher
                          where exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = finisher_id);

   elsif I_from_group_type = 'CZ' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select c.location,
                                c.loc_type
                           from cost_zone_group_loc c,
                                v_store s
                          where s.store            = c.location
                            and c.loc_type         = 'S'
                            and s.stockholding_ind = 'Y'
                            and c.zone_group_id    = I_zone_group_id
                            and c.zone_id          = I_from_group
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = c.location)
                          UNION
                         select c.location,
                                c.loc_type
                           from cost_zone_group_loc c,
                                v_wh w
                          where w.wh = c.location
                            and c.loc_type         = 'W'
                            and w.stockholding_ind = 'Y'
                            and c.zone_group_id    = I_zone_group_id
                            and c.zone_id          = I_from_group
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = c.location);

   elsif I_from_group_type = 'T' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select store,
                                'S'
                           from v_store
                          where stockholding_ind = 'Y'
                            and transfer_zone    = I_from_group
                            and exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = store);

   elsif I_from_group_type in ('S','W','I','E') then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select I_from_group,
                                DECODE(I_from_group_type, 'I', 'W', I_from_group_type)
                           from dual
                          where exists (select 'x'
                                          from mc_chrg_head mc
                                         where mc.item_list = I_item_list
                                           and mc.from_loc  = I_from_group);
   end if;
   ---
   if I_to_group_type in ('A','R','D','AS') then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select s.store,
                              'S'
                         from v_store s
                        where s.stockholding_ind  = 'Y'
                          and ((I_to_group_type   = 'A'
                                and s.area        = I_to_group)
                              or (I_to_group_type = 'R'
                                  and s.region    = I_to_group)
                              or (I_to_group_type = 'D'
                                  and s.district  = I_to_group)
                              or (I_to_group_type = 'AS'))
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list = I_item_list
                                         and mc.to_loc    = s.store);

   elsif I_to_group_type = 'AW' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select wh,
                              'W'
                         from v_wh
                        where stockholding_ind = 'Y'
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list = I_item_list
                                         and mc.to_loc    = wh);

   elsif I_to_group_type = 'PW' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select wh,
                              'W'
                         from v_wh
                        where stockholding_ind = 'Y'
                          and physical_wh      = I_to_group
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list = I_item_list
                                         and mc.to_loc    = wh);

   elsif I_to_group_type = 'LL' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select d.location,
                              'S'
                         from v_loc_list_head vllh,
                              v_store vs,
                              loc_list_detail d
                        where vllh.loc_list       = I_to_group
                          and vllh.loc_list       = d.loc_list
                          and vs.store            = d.location
                          and vs.stockholding_ind = 'Y'
                          and d.loc_type          = 'S'
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list = I_item_list
                                         and mc.to_loc    = d.location);
      ---
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select w.wh,
                              'W'
                         from v_loc_list_head vllh,
                              loc_list_detail d,
                              v_wh w
                        where vllh.loc_list      = I_to_group
                          and vllh.loc_list      = d.loc_list
                          and d.loc_type         = 'W'
                          and d.location         = w.wh
                          and w.stockholding_ind = 'Y'
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list = I_item_list
                                         and mc.to_loc    = w.wh);
      ---
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select w.wh,
                              'W'
                         from v_loc_list_head vllh,
                              loc_list_detail d,
                              v_wh w
                        where vllh.loc_list      = I_to_group
                          and vllh.loc_list      = d.loc_list
                          and d.loc_type         = 'W'
                          and d.location         = w.physical_wh
                          and w.stockholding_ind = 'Y'
                          and not exists (select 'x'
                                            from to_loc_temp t
                                           where t.to_loc = w.wh)
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list = I_item_list
                                         and mc.to_loc    = w.wh);

   elsif I_to_group_type = 'AL' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select store,
                              'S'
                         from v_store
                        where stockholding_ind = 'Y'
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list = I_item_list
                                         and mc.to_loc    = store)
                        UNION
                       select wh,
                              'W'
                         from v_wh
                        where stockholding_ind = 'Y'
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list   = I_item_list
                                         and mc.to_loc      = wh)
                       union
                      select finisher_id,
                             'W'
                        from v_internal_finisher
                       where exists (select 'x'
                                       from mc_chrg_head mc
                                      where mc.item_list = I_item_list
                                        and mc.to_loc    = finisher_id)
                       union
                      select finisher_id,
                             'E'
                        from v_external_finisher
                       where exists (select 'x'
                                       from mc_chrg_head mc
                                      where mc.item_list   = I_item_list
                                        and mc.to_loc      = finisher_id);

   elsif I_to_group_type = 'AI' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select finisher_id,
                             'W'
                        from v_internal_finisher
                       where exists (select 'x'
                                       from mc_chrg_head mc
                                      where mc.item_list   = I_item_list
                                        and mc.to_loc      = finisher_id);

   elsif I_to_group_type = 'AE' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                      select finisher_id,
                             'E'
                        from v_external_finisher
                       where exists (select 'x'
                                       from mc_chrg_head mc
                                      where mc.item_list   = I_item_list
                                        and mc.to_loc      = finisher_id);

   elsif I_to_group_type = 'CZ' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select c.location,
                              c.loc_type
                         from cost_zone_group_loc c,
                              v_store s
                        where s.store            = c.location
                          and c.loc_type         = 'S'
                          and s.stockholding_ind = 'Y'
                          and c.zone_group_id    = I_zone_group_id
                          and c.zone_id          = I_to_group
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list   = I_item_list
                                         and mc.to_loc      = c.location)
                        UNION
                       select c.location,
                              c.loc_type
                         from cost_zone_group_loc c,
                              v_wh w
                        where w.wh               = c.location
                          and c.loc_type         = 'W'
                          and w.stockholding_ind = 'Y'
                          and c.zone_group_id    = I_zone_group_id
                          and c.zone_id          = I_to_group
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list   = I_item_list
                                         and mc.to_loc      = c.location);

   elsif I_to_group_type = 'T' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select store,
                              'S'
                         from v_store
                        where stockholding_ind = 'Y'
                          and transfer_zone    = I_to_group
                          and exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list   = I_item_list
                                         and mc.to_loc      = store);

   elsif I_to_group_type in ('S','W','I','E') then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select I_to_group,
                              DECODE(I_to_group_type, 'I', 'W', I_to_group_type)
                         from dual
                        where exists (select 'x'
                                        from mc_chrg_head mc
                                       where mc.item_list   = I_item_list
                                         and mc.to_loc      = I_to_group);
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
END INSERT_MC_TEMP;

--------------------------------------------------------------------------------------
FUNCTION DELETE_TEMP(O_error_message IN OUT VARCHAR2)

RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_CHARGE_SQL.DELETE_TEMP';
   L_table        VARCHAR2(30);
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_FROM_LOC_TEMP is
      select 'x'
        from from_loc_temp
         for update nowait;

   cursor C_LOCK_TO_LOC_TEMP is
      select 'x'
        from to_loc_temp
         for update nowait;
BEGIN
   L_table := 'FROM_LOC_TEMP';
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_FROM_LOC_TEMP','FROM_LOC_TEMP',NULL);
   open C_LOCK_FROM_LOC_TEMP;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_FROM_LOC_TEMP','FROM_LOC_TEMP',NULL);
   close C_LOCK_FROM_LOC_TEMP;
   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'FROM_LOC_TEMP',NULL);
   delete from from_loc_temp;
   ---
   L_table := 'TO_LOC_TEMP';
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_TO_LOC_TEMP','TO_LOC_TEMP',NULL);
   open C_LOCK_TO_LOC_TEMP;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_TO_LOC_TEMP','TO_LOC_TEMP',NULL);
   close C_LOCK_TO_LOC_TEMP;
   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'TO_LOC_TEMP',NULL);
   delete from to_loc_temp;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            NULL,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_TEMP;
--------------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_EXTERNAL_FINISHER V_INTERNAL_FINISHER V_LOC_LIST_HEAD V_STORE V_WH
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION APPLY_CHARGES(O_error_message       IN OUT   VARCHAR2,
                       I_item                IN       ITEM_MASTER.ITEM%TYPE,
                       I_item_list           IN       MC_CHRG_HEAD.ITEM_LIST%TYPE,
                       I_zone_group_id       IN       COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                       I_from_group_type     IN       CODE_DETAIL.CODE%TYPE,
                       I_from_group          IN       STORE.STORE%TYPE,
                       I_to_group_type       IN       CODE_DETAIL.CODE%TYPE,
                       I_to_group            IN       STORE.STORE%TYPE,
                       I_comp_id             IN       ELC_COMP.COMP_ID%TYPE,
                       I_up_chrg_group       IN       ITEM_CHRG_DETAIL.UP_CHRG_GROUP%TYPE,
                       I_comp_rate           IN       ELC_COMP.COMP_RATE%TYPE,
                       I_per_count           IN       ELC_COMP.PER_COUNT%TYPE,
                       I_per_count_uom       IN       ELC_COMP.PER_COUNT_UOM%TYPE,
                       I_comp_currency       IN       ELC_COMP.COMP_CURRENCY%TYPE,
                       I_display_order       IN       ELC_COMP.DISPLAY_ORDER%TYPE,
                       I_insert_update_del   IN       VARCHAR2,
                       I_maintenance_type    IN       MC_CHRG_DETAIL.MAINTENANCE_TYPE%TYPE)

RETURN BOOLEAN IS

   L_program        VARCHAR2(50) := 'ITEM_CHARGE_SQL.APPLY_CHARGES';
   L_table          VARCHAR2(30);
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);
   L_rows_inserted  BOOLEAN := FALSE;
   L_var_name       VARCHAR2(50);

   cursor C_LOCK_ITEM_CHRG_DETAIL_1 is
      select 'x'
        from item_chrg_detail
       where item     = I_item
         and from_loc = I_from_group
         and to_loc   = I_to_group
         and comp_id  = I_comp_id
         for update nowait;

   cursor C_LOCK_ITEM_CHRG_DETAIL_2 is
      select 'x'
        from item_chrg_detail
       where item    = I_item
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc   in (select to_loc
                            from to_loc_temp)
         and comp_id = I_comp_id
         for update nowait;

   cursor C_LOCK_MC_CHRG_DETAIL_1 is
      select 'x'
        from mc_chrg_detail
       where item_list = I_item_list
         and from_loc  = I_from_group
         and to_loc    = I_to_group
         and comp_id   = I_comp_id
         for update nowait;

   cursor C_LOCK_MC_CHRG_DETAIL_2 is
      select 'x'
        from mc_chrg_detail
       where item_list = I_item_list
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc   in (select to_loc
                            from to_loc_temp)
         and comp_id   = I_comp_id
         for update nowait;

   cursor C_LOCK_MC_CHRG_HEAD is
      select 'x'
        from mc_chrg_head h
       where h.item_list = I_item_list
         and not exists (select 'x'
                           from mc_chrg_detail d
                          where d.item_list = h.item_list
                            and d.from_loc  = h.from_loc
                            and d.to_loc    = h.to_loc)
         for update nowait;

BEGIN

   if I_item is NOT NULL then

      if I_insert_update_del = 'I' then
         if I_from_group_type in ('S','W','I','E') and I_to_group_type in ('S','W','I','E') then
            insert into item_chrg_head(item,
                                       from_loc,
                                       to_loc,
                                       from_loc_type,
                                       to_loc_type)
                                select I_item,
                                       I_from_group,
                                       I_to_group,
                                       DECODE(I_from_group_type, 'I', 'W', I_from_group_type),
                                       DECODE(I_to_group_type, 'I', 'W', I_to_group_type)
                                  from dual
                                 where not exists (select 'x'
                                                     from item_chrg_head
                                                    where item     = I_item
                                                      and from_loc = I_from_group
                                                      and to_loc   = I_to_group);
            ---
            insert into item_chrg_detail(item,
                                         from_loc,
                                         to_loc,
                                         from_loc_type,
                                         to_loc_type,
                                         comp_id,
                                         comp_rate,
                                         per_count,
                                         per_count_uom,
                                         up_chrg_group,
                                         comp_currency,
                                         display_order)
                                  select I_item,
                                         I_from_group,
                                         I_to_group,
                                         DECODE(I_from_group_type, 'I', 'W', I_from_group_type),
                                         DECODE(I_to_group_type, 'I', 'W', I_to_group_type),
                                         I_comp_id,
                                         I_comp_rate,
                                         I_per_count,
                                         I_per_count_uom,
                                         I_up_chrg_group,
                                         I_comp_currency,
                                         I_display_order
                                    from dual
                                   where not exists (select 'x'
                                                       from item_chrg_detail
                                                      where item     = I_item
                                                        and from_loc = I_from_group
                                                        and to_loc   = I_to_group
                                                        and comp_id  = I_comp_id);

         else
            if I_from_group_type in ('A','R','D','AS') then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select s.store,
                                         'S'
                                    from v_store s
                                   where s.stockholding_ind    = 'Y'
                                     and ((I_from_group_type   = 'A'
                                           and s.area          = I_from_group)
                                         or (I_from_group_type = 'R'
                                             and s.region      = I_from_group)
                                         or (I_from_group_type = 'D'
                                             and s.district    = I_from_group)
                                         or (I_from_group_type = 'AS'));

               if(SQL%NOTFOUND) then
                  if(I_from_group_type = 'A') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in area',
                                                            I_from_group,
                                                            NULL);
                     return FALSE;
                  elsif(I_from_group_type = 'R') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in region',
                                                            I_from_group,
                                                            NULL);
                     return FALSE;
                  elsif(I_from_group_type = 'D') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in district',
                                                            I_from_group,
                                                            NULL);
                     return FALSE;
                  else
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding',
                                                           'store',
                                                            NULL);
                     return FALSE;
                  end if;
               end if;
            elsif I_from_group_type = 'AW' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select wh,
                                         'W'
                                    from v_wh
                                   where stockholding_ind = 'Y';

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'warehouse',
                                                         NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'PW' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select wh,
                                         'W'
                                    from v_wh
                                   where stockholding_ind = 'Y'
                                     and physical_wh = I_from_group;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding virtual warehouse within physical warehouse',
                                                         I_from_group,
                                                         NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'LL' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select d.location,
                                         'S'
                                    from v_loc_list_head vllh,
                                         v_store vs,
                                         loc_list_detail d
                                   where vllh.loc_list       = I_from_group
                                     and vllh.loc_list       = d.loc_list
                                     and vs.store            = d.location
                                     and vs.stockholding_ind = 'Y'
                                     and d.loc_type          = 'S';

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select w.wh,
                                         'W'
                                    from v_loc_list_head vllh,
                                         loc_list_detail d,
                                         v_wh w
                                   where vllh.loc_list      = I_from_group
                                     and vllh.loc_list      = d.loc_list
                                     and d.loc_type         = 'W'
                                     and d.location         = w.wh
                                     and w.stockholding_ind = 'Y';

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select w.wh,
                                         'W'
                                    from v_loc_list_head vllh,
                                         loc_list_detail d,
                                         v_wh w
                                   where vllh.loc_list      = I_from_group
                                     and vllh.loc_list      = d.loc_list
                                     and d.loc_type         = 'W'
                                     and d.location         = w.physical_wh
                                     and w.stockholding_ind = 'Y'
                                     and not exists (select 'x'
                                                       from from_loc_temp t
                                                      where t.from_loc = w.wh);

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;

               if(L_rows_inserted = FALSE) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding location within location list',
                                                        I_from_group,
                                                        NULL);
                  return FALSE;
               else
                  L_rows_inserted := FALSE;
               end if;

            elsif I_from_group_type = 'AL' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select store,
                                         'S'
                                    from v_store
                                   where stockholding_ind = 'Y'
                                   union
                                  select wh,
                                         'W'
                                    from v_wh
                                   where stockholding_ind = 'Y'
                                   union
                                  select finisher_id,
                                         'W'
                                    from v_internal_finisher
                                   union
                                  select finisher_id,
                                         'E'
                                    from v_external_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'location',
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'AI' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select finisher_id,
                                         'W'
                                    from v_internal_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'internal finisher',
                                                         NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'AE' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select finisher_id,
                                         'E'
                                    from v_external_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'external finisher',
                                                         NULL);
                  return FALSE;
               end if;

            elsif I_from_group_type = 'CZ' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select c.location,
                                         c.loc_type
                                    from cost_zone_group_loc c,
                                         v_store s
                                   where s.store            = c.location
                                     and c.loc_type         = 'S'
                                     and s.stockholding_ind = 'Y'
                                     and c.zone_group_id    = I_zone_group_id
                                     and c.zone_id          = I_from_group
                                   UNION
                                  select c.location,
                                         c.loc_type
                                    from cost_zone_group_loc c,
                                         v_wh w
                                   where w.wh               = c.location
                                     and c.loc_type         = 'W'
                                     and w.stockholding_ind = 'Y'
                                     and c.zone_group_id    = I_zone_group_id
                                     and c.zone_id          = I_from_group;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding location within cost zone group ' ||
                                                         to_char(I_zone_group_id) || ', cost zone',
                                                         I_from_group,
                                                         NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'T' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select store,
                                         'S'
                                    from v_store
                                   where stockholding_ind = 'Y'
                                     and transfer_zone = I_from_group;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding store within transfer zone',
                                                         I_from_group,
                                                         NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type in ('S','W','I','E') then
               insert into from_loc_temp values(I_from_group,
                                                DECODE(I_from_group_type,'I','W',I_from_group_type));
            end if;
            ---
            if I_to_group_type in ('A','R','D','AS') then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select s.store,
                                       'S'
                                  from v_store s
                                 where s.stockholding_ind  = 'Y'
                                   and ((I_to_group_type   = 'A'
                                         and s.area        = I_to_group)
                                       or (I_to_group_type = 'R'
                                           and s.region    = I_to_group)
                                       or (I_to_group_type = 'D'
                                           and s.district  = I_to_group)
                                       or (I_to_group_type = 'AS'));
               if(SQL%NOTFOUND) then
                  if(I_to_group_type = 'A') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in area',
                                                            I_to_group,
                                                            NULL);
                     return FALSE;
                  elsif(I_to_group_type = 'R') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in region',
                                                            I_to_group,
                                                            NULL);
                     return FALSE;
                  elsif(I_to_group_type = 'D') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in district',
                                                            I_to_group,
                                                            NULL);
                     return FALSE;
                  else
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding',
                                                           'store',
                                                            NULL);
                     return FALSE;
                  end if;
               end if;
            elsif I_to_group_type = 'AW' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select wh,
                                       'W'
                                  from v_wh
                                 where stockholding_ind = 'Y';

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'warehouse',
                                                         NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type = 'PW' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select wh,
                                       'W'
                                  from v_wh
                                 where stockholding_ind = 'Y'
                                   and physical_wh      = I_to_group;


               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding virtual warehouse within physical warehouse',
                                                        I_from_group,
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type = 'LL' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select d.location,
                                       'S'
                                  from v_loc_list_head vllh,
                                       v_store vs,
                                       loc_list_detail d
                                 where vllh.loc_list       = I_to_group
                                   and vllh.loc_list       = d.loc_list
                                   and vs.store            = d.location
                                   and vs.stockholding_ind = 'Y'
                                   and d.loc_type          = 'S';

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select w.wh,
                                       'W'
                                  from v_loc_list_head vllh,
                                       loc_list_detail d,
                                       v_wh w
                                 where vllh.loc_list      = I_to_group
                                   and vllh.loc_list      = d.loc_list
                                   and d.loc_type         = 'W'
                                   and d.location         = w.wh
                                   and w.stockholding_ind = 'Y';

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select w.wh,
                                       'W'
                                  from v_loc_list_head vllh,
                                       loc_list_detail d,
                                       v_wh w
                                 where vllh.loc_list      = I_to_group
                                   and vllh.loc_list      = d.loc_list
                                   and d.loc_type         = 'W'
                                   and d.location         = w.physical_wh
                                   and w.stockholding_ind = 'Y'
                                   and not exists (select 'x'
                                                     from to_loc_temp t
                                                    where t.to_loc = w.wh);

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               if(L_rows_inserted = FALSE) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding location within location list',
                                                         I_to_group,
                                                         NULL);
                  return FALSE;
               else
                  L_rows_inserted := FALSE;
               end if;

            elsif I_to_group_type = 'AL' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select store,
                                       'S'
                                  from v_store
                                 where stockholding_ind = 'Y'
                                 union
                                select wh,
                                       'W'
                                  from v_wh
                                 where stockholding_ind = 'Y'
                                 union
                                select finisher_id,
                                       'W'
                                  from v_internal_finisher
                                 union
                                select finisher_id,
                                       'E'
                                  from v_external_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'location',
                                                         NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type = 'AI' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select finisher_id,
                                       'W'
                                  from v_internal_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'internal finisher',
                                                         NULL);
                  return FALSE;
               end if;

            elsif I_to_group_type = 'AE' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select finisher_id,
                                       'E'
                                  from v_external_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'external finisher',
                                                         NULL);
                  return FALSE;
               end if;

            elsif I_to_group_type = 'CZ' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select c.location,
                                       c.loc_type
                                  from cost_zone_group_loc c,
                                       v_store s
                                 where s.store            = c.location
                                   and c.loc_type         = 'S'
                                   and s.stockholding_ind = 'Y'
                                   and c.zone_group_id    = I_zone_group_id
                                   and c.zone_id          = I_to_group
                                 UNION
                                select c.location,
                                       c.loc_type
                                  from cost_zone_group_loc c,
                                       v_wh w
                                 where w.wh               = c.location
                                   and c.loc_type         = 'W'
                                   and w.stockholding_ind = 'Y'
                                   and c.zone_group_id    = I_zone_group_id
                                   and c.zone_id          = I_to_group;
               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding location within cost zone group ' ||
                                                         to_char(I_zone_group_id) || ', cost zone',
                                                         I_to_group,
                                                         NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type = 'T' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select store,
                                       'S'
                                  from v_store
                                 where stockholding_ind = 'Y'
                                   and transfer_zone    = I_to_group;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding store within transfer zone',
                                                         I_to_group,
                                                         NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type in ('S','W','I','E') then
               insert into to_loc_temp values(I_to_group,
                                              DECODE(I_to_group_type,'I','W',I_to_group_type));
            end if;
            ---
            insert into item_chrg_head(item,
                                       from_loc,
                                       to_loc,
                                       from_loc_type,
                                       to_loc_type)
                       select distinct I_item,
                                       f.from_loc,
                                       t.to_loc,
                                       f.from_loc_type,
                                       t.to_loc_type
                                  from from_loc_temp f,
                                       to_loc_temp t
                                 where not exists (select 'x'
                                                     from item_chrg_head
                                                    where item     = I_item
                                                      and from_loc = f.from_loc
                                                      and to_loc   = t.to_loc)
                                   and f.from_loc != t.to_loc;
            ---
            insert into item_chrg_detail(item,
                                         from_loc,
                                         to_loc,
                                         comp_id,
                                         from_loc_type,
                                         to_loc_type,
                                         comp_rate,
                                         per_count,
                                         per_count_uom,
                                         up_chrg_group,
                                         comp_currency,
                                         display_order)
                         select distinct I_item,
                                         f.from_loc,
                                         t.to_loc,
                                         I_comp_id,
                                         f.from_loc_type,
                                         t.to_loc_type,
                                         I_comp_rate,
                                         I_per_count,
                                         I_per_count_uom,
                                         I_up_chrg_group,
                                         I_comp_currency,
                                         I_display_order
                                    from from_loc_temp f,
                                         to_loc_temp t
                                   where not exists (select 'x'
                                                       from item_chrg_detail
                                                      where item     = I_item
                                                        and from_loc = f.from_loc
                                                        and to_loc   = t.to_loc
                                                        and comp_id  = I_comp_id)
                                     and f.from_loc != t.to_loc;
         end if;
      elsif I_insert_update_del = 'U' then  -- I_insert_update_del = 'U' for Update
         L_var_name := 'I_item = ' || I_item;
         if I_from_group_type in ('S','W','I','E') and I_to_group_type in ('S','W','I','E') then
            L_table := 'ITEM_CHRG_DETAIL';
            ---
            SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_CHRG_DETAIL_1','ITEM_CHRG_DETAIL',NULL);
            open C_LOCK_ITEM_CHRG_DETAIL_1;
            SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_CHRG_DETAIL_1','ITEM_CHRG_DETAIL',NULL);
            close C_LOCK_ITEM_CHRG_DETAIL_1;
            ---
            SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_CHRG_DETAIL',NULL);
            update item_chrg_detail
               set comp_rate     = I_comp_rate,
                   per_count     = I_per_count,
                   per_count_uom = I_per_count_uom,
                   up_chrg_group = I_up_chrg_group,
                   comp_currency = I_comp_currency
             where item     = I_item
               and from_loc = I_from_group
               and to_loc   = I_to_group
               and comp_id  = I_comp_id;
         else
            if INSERT_TEMP(O_error_message,
                           I_item,
                           I_zone_group_id,
                           I_from_group_type,
                           I_from_group,
                           I_to_group_type,
                           I_to_group) = FALSE then
               return FALSE;
            end if;
            ---
            L_table := 'ITEM_CHRG_DETAIL';
            ---
            SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_CHRG_DETAIL_2','ITEM_CHRG_DETAIL',NULL);
            open C_LOCK_ITEM_CHRG_DETAIL_2;
            SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_CHRG_DETAIL_2','ITEM_CHRG_DETAIL',NULL);
            close C_LOCK_ITEM_CHRG_DETAIL_2;
            ---
            SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_CHRG_DETAIL',NULL);
            update item_chrg_detail
               set comp_rate     = I_comp_rate,
                   per_count     = I_per_count,
                   per_count_uom = I_per_count_uom,
                   up_chrg_group = I_up_chrg_group,
                   comp_currency = I_comp_currency
             where item    = I_item
               and from_loc in (select from_loc
                                  from from_loc_temp)
               and to_loc in (select to_loc
                                from to_loc_temp)
               and comp_id = I_comp_id;
         end if;
      else     -- I_insert_update_del = 'D' for 'Delete Comps'
         L_var_name := 'I_item = ' || I_item;
         if I_from_group_type in ('S','W','I','E') and I_to_group_type in ('S','W','I','E') then
            L_table := 'ITEM_CHRG_DETAIL';
            ---
            SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_CHRG_DETAIL_1','ITEM_CHRG_DETAIL',NULL);
            open C_LOCK_ITEM_CHRG_DETAIL_1;
            SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_CHRG_DETAIL_1','ITEM_CHRG_DETAIL',NULL);
            close C_LOCK_ITEM_CHRG_DETAIL_1;
            ---
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_DETAIL',NULL);
            delete from item_chrg_detail
                  where item     = I_item
                    and from_loc = I_from_group
                    and to_loc   = I_to_group
                    and comp_id  = I_comp_id;
         else
            if INSERT_TEMP(O_error_message,
                           I_item,
                           I_zone_group_id,
                           I_from_group_type,
                           I_from_group,
                           I_to_group_type,
                           I_to_group) = FALSE then
               return FALSE;
            end if;
            ---
            L_table := 'ITEM_CHRG_DETAIL';
            ---
            SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_CHRG_DETAIL_2','ITEM_CHRG_DETAIL',NULL);
            open C_LOCK_ITEM_CHRG_DETAIL_2;
            SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_CHRG_DETAIL_2','ITEM_CHRG_DETAIL',NULL);
            close C_LOCK_ITEM_CHRG_DETAIL_2;
            ---
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_DETAIL',NULL);
            delete from item_chrg_detail
                  where item    = I_item
                    and from_loc in (select from_loc
                                       from from_loc_temp)
                    and to_loc in (select to_loc
                                     from to_loc_temp)
                    and comp_id = I_comp_id;
         end if;
         ---
         -- Since deleted comps, need to delete any header records that
         -- no longer have component detail records
         ---
         if DELETE_HEADER(O_error_message,
                          I_item) = FALSE then
            return FALSE;
         end if;
      end if;

   elsif I_item_list is NOT NULL then

      if I_insert_update_del = 'I' then

         if I_maintenance_type is NULL then
            O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                  'I_maintenance_type',
                                                   L_program,
                                                   NULL);
            return FALSE;
         elsif I_maintenance_type NOT in ('A', 'D') then
            O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                                  'I_maintenance_type',
                                                   NULL,
                                                   NULL);
            return FALSE;
         end if;

         if I_from_group_type in ('S','W','I','E') and I_to_group_type in ('S','W','I','E') then
            insert into mc_chrg_head(item_list,
                                     from_loc,
                                     to_loc,
                                     from_loc_type,
                                     to_loc_type)
                              select I_item_list,
                                     I_from_group,
                                     I_to_group,
                                     DECODE(I_from_group_type, 'I', 'W', I_from_group_type),
                                     DECODE(I_to_group_type, 'I', 'W', I_to_group_type)
                                from dual
                               where not exists (select 'x'
                                                   from mc_chrg_head
                                                  where item_list = I_item_list
                                                    and from_loc  = I_from_group
                                                    and to_loc    = I_to_group);
            ---
            insert into mc_chrg_detail(item_list,
                                       from_loc,
                                       to_loc,
                                       from_loc_type,
                                       to_loc_type,
                                       comp_id,
                                       comp_rate,
                                       per_count,
                                       per_count_uom,
                                       up_chrg_group,
                                       comp_currency,
                                       display_order,
                                       maintenance_type)
                                select I_item_list,
                                       I_from_group,
                                       I_to_group,
                                       DECODE(I_from_group_type, 'I', 'W', I_from_group_type),
                                       DECODE(I_to_group_type, 'I', 'W', I_to_group_type),
                                       I_comp_id,
                                       I_comp_rate,
                                       I_per_count,
                                       I_per_count_uom,
                                       I_up_chrg_group,
                                       I_comp_currency,
                                       I_display_order,
                                       I_maintenance_type
                                  from dual
                                 where not exists (select 'x'
                                                     from mc_chrg_detail
                                                    where item_list = I_item_list
                                                      and from_loc  = I_from_group
                                                      and to_loc    = I_to_group
                                                      and comp_id   = I_comp_id);

         else
            if I_from_group_type in ('A','R','D','AS') then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select s.store,
                                         'S'
                                    from v_store s
                                   where s.stockholding_ind    = 'Y'
                                     and ((I_from_group_type   = 'A'
                                           and s.area          = I_from_group)
                                         or (I_from_group_type = 'R'
                                             and s.region      = I_from_group)
                                         or (I_from_group_type = 'D'
                                             and s.district    = I_from_group)
                                         or (I_from_group_type = 'AS'));

               if(SQL%NOTFOUND) then
                  if(I_from_group_type = 'A') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in area',
                                                           I_from_group,
                                                           NULL);
                     return FALSE;
                  elsif(I_from_group_type = 'R') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in region',
                                                           I_from_group,
                                                           NULL);
                     return FALSE;
                  elsif(I_from_group_type = 'D') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in district',
                                                           I_from_group,
                                                           NULL);
                     return FALSE;
                  else
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding',
                                                           'store',
                                                           NULL);
                     return FALSE;
                  end if;
               end if;
            elsif I_from_group_type = 'AW' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select wh,
                                         'W'
                                    from v_wh
                                   where stockholding_ind = 'Y';

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'warehouse',
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'PW' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select wh,
                                         'W'
                                    from v_wh
                                   where stockholding_ind = 'Y'
                                     and physical_wh = I_from_group;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding virtual warehouse within physical warehouse',
                                                        I_from_group,
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'LL' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select d.location,
                                         'S'
                                    from v_loc_list_head vllh,
                                         v_store vs,
                                         loc_list_detail d
                                   where vllh.loc_list       = I_from_group
                                     and vllh.loc_list       = d.loc_list
                                     and vs.store            = d.location
                                     and vs.stockholding_ind = 'Y'
                                     and d.loc_type          = 'S';

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select w.wh,
                                         'W'
                                    from v_loc_list_head vllh,
                                         loc_list_detail d,
                                         v_wh w
                                   where vllh.loc_list      = I_from_group
                                     and vllh.loc_list      = d.loc_list
                                     and d.loc_type         = 'W'
                                     and d.location         = w.wh
                                     and w.stockholding_ind = 'Y';

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select w.wh,
                                         'W'
                                    from v_loc_list_head vllh,
                                         loc_list_detail d,
                                         v_wh w
                                   where vllh.loc_list      = I_from_group
                                     and vllh.loc_list      = d.loc_list
                                     and d.loc_type         = 'W'
                                     and d.location         = w.physical_wh
                                     and w.stockholding_ind = 'Y'
                                     and not exists (select 'x'
                                                       from from_loc_temp t
                                                      where t.from_loc = w.wh);

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;

               if(L_rows_inserted = FALSE) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding location within location list',
                                                        I_from_group,
                                                        NULL);
                  return FALSE;
               else
                  L_rows_inserted := FALSE;
               end if;

            elsif I_from_group_type = 'AL' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select store,
                                         'S'
                                    from v_store
                                   where stockholding_ind = 'Y'
                                   union
                                  select wh,
                                         'W'
                                    from v_wh
                                   where stockholding_ind = 'Y'
                                   union
                                  select finisher_id,
                                         'W'
                                    from v_internal_finisher
                                   union
                                  select finisher_id,
                                         'E'
                                    from v_external_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'location',
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'AI' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select finisher_id,
                                         'W'
                                    from v_internal_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'internal finisher',
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'AE' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select finisher_id,
                                         'E'
                                    from v_external_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'external finisher',
                                                        NULL);
                  return FALSE;
               end if;

            elsif I_from_group_type = 'CZ' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select c.location,
                                         c.loc_type
                                    from cost_zone_group_loc c,
                                         v_store s
                                   where s.store            = c.location
                                     and c.loc_type         = 'S'
                                     and s.stockholding_ind = 'Y'
                                     and c.zone_group_id    = I_zone_group_id
                                     and c.zone_id          = I_from_group
                                   UNION
                                  select c.location,
                                         c.loc_type
                                    from cost_zone_group_loc c,
                                         v_wh w
                                   where w.wh               = c.location
                                     and c.loc_type         = 'W'
                                     and w.stockholding_ind = 'Y'
                                     and c.zone_group_id    = I_zone_group_id
                                     and c.zone_id          = I_from_group;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding location within cost zone group ' ||
                                                         to_char(I_zone_group_id) || ', cost zone',
                                                        I_from_group,
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type = 'T' then
               insert into from_loc_temp(from_loc,
                                         from_loc_type)
                                  select store,
                                         'S'
                                    from v_store
                                   where stockholding_ind = 'Y'
                                     and transfer_zone = I_from_group;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding store within transfer zone',
                                                        I_from_group,
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_from_group_type in ('S','W','I','E') then
               insert into from_loc_temp values(I_from_group,
                                                DECODE(I_from_group_type,'I','W',I_from_group_type));
            end if;
            ---
            if I_to_group_type in ('A','R','D','AS') then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select s.store,
                                       'S'
                                  from v_store s
                                 where s.stockholding_ind  = 'Y'
                                   and ((I_to_group_type   = 'A'
                                         and s.area        = I_to_group)
                                       or (I_to_group_type = 'R'
                                           and s.region    = I_to_group)
                                       or (I_to_group_type = 'D'
                                           and s.district  = I_to_group)
                                       or (I_to_group_type = 'AS'));
               if(SQL%NOTFOUND) then
                  if(I_to_group_type = 'A') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in area',
                                                           I_to_group,
                                                           NULL);
                     return FALSE;
                  elsif(I_to_group_type = 'R') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in region',
                                                           I_to_group,
                                                           NULL);
                     return FALSE;
                  elsif(I_to_group_type = 'D') then
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding store in district',
                                                           I_to_group,
                                                           NULL);
                     return FALSE;
                  else
                     O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                           'any stockholding',
                                                           'store',
                                                           NULL);
                     return FALSE;
                  end if;
               end if;
            elsif I_to_group_type = 'AW' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select wh,
                                       'W'
                                  from v_wh
                                 where stockholding_ind = 'Y';

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'warehouse',
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type = 'PW' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select wh,
                                       'W'
                                  from v_wh
                                 where stockholding_ind = 'Y'
                                   and physical_wh      = I_to_group;


               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding virtual warehouse within physical warehouse',
                                                        I_from_group,
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type = 'LL' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select d.location,
                                       'S'
                                  from v_loc_list_head vllh,
                                       v_store vs,
                                       loc_list_detail d
                                 where vllh.loc_list       = I_to_group
                                   and vllh.loc_list       = d.loc_list
                                   and vs.store            = d.location
                                   and vs.stockholding_ind = 'Y'
                                   and d.loc_type          = 'S';

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select w.wh,
                                       'W'
                                  from v_loc_list_head vllh,
                                       loc_list_detail d,
                                       v_wh w
                                 where vllh.loc_list      = I_to_group
                                   and vllh.loc_list      = d.loc_list
                                   and d.loc_type         = 'W'
                                   and d.location         = w.wh
                                   and w.stockholding_ind = 'Y';

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select w.wh,
                                       'W'
                                  from v_loc_list_head vllh,
                                       loc_list_detail d,
                                       v_wh w
                                 where vllh.loc_list = I_to_group
                                   and vllh.loc_list = d.loc_list
                                   and d.loc_type    = 'W'
                                   and d.location    = w.physical_wh
                                   and w.stockholding_ind = 'Y'
                                   and not exists (select 'x'
                                                     from to_loc_temp t
                                                    where t.to_loc = w.wh);

               if(SQL%FOUND) then
                  L_rows_inserted := TRUE;
               end if;
               ---
               if(L_rows_inserted = FALSE) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding location within location list',
                                                        I_to_group,
                                                        NULL);
                  return FALSE;
               else
                  L_rows_inserted := FALSE;
               end if;

            elsif I_to_group_type = 'AL' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select store,
                                       'S'
                                  from v_store
                                 where stockholding_ind = 'Y'
                                 union
                                select wh,
                                       'W'
                                  from v_wh
                                 where stockholding_ind = 'Y'
                                 union
                                select finisher_id,
                                       'W'
                                  from v_internal_finisher
                                 union
                                select finisher_id,
                                       'E'
                                  from v_external_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'location',
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type = 'AI' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select finisher_id,
                                       'W'
                                  from v_internal_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'internal finisher',
                                                        NULL);
                  return FALSE;
               end if;

            elsif I_to_group_type = 'AE' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select finisher_id,
                                       'E'
                                  from v_external_finisher;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding',
                                                        'external finisher',
                                                        NULL);
                  return FALSE;
               end if;

            elsif I_to_group_type = 'CZ' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select c.location,
                                       c.loc_type
                                  from cost_zone_group_loc c,
                                       v_store s
                                 where s.store            = c.location
                                   and c.loc_type         = 'S'
                                   and s.stockholding_ind = 'Y'
                                   and c.zone_group_id    = I_zone_group_id
                                   and c.zone_id          = I_to_group
                                 UNION
                                select c.location,
                                       c.loc_type
                                  from cost_zone_group_loc c,
                                       v_wh w
                                 where w.wh               = c.location
                                   and c.loc_type         = 'W'
                                   and w.stockholding_ind = 'Y'
                                   and c.zone_group_id    = I_zone_group_id
                                   and c.zone_id          = I_to_group;
               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding location within cost zone group ' ||
                                                         to_char(I_zone_group_id) || ', cost zone',
                                                        I_to_group,
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type = 'T' then
               insert into to_loc_temp(to_loc,
                                       to_loc_type)
                                select store,
                                       'S'
                                  from v_store
                                 where stockholding_ind = 'Y'
                                   and transfer_zone    = I_to_group;

               if(SQL%NOTFOUND) then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY',
                                                        'any stockholding store within transfer zone',
                                                        I_to_group,
                                                        NULL);
                  return FALSE;
               end if;
            elsif I_to_group_type in ('S','W','I','E') then
               insert into to_loc_temp values(I_to_group,
                                              DECODE(I_to_group_type,'I','W',I_to_group_type));
            end if;
            ---
            insert into mc_chrg_head(item_list,
                                     from_loc,
                                     to_loc,
                                     from_loc_type,
                                     to_loc_type)
                     select distinct I_item_list,
                                     f.from_loc,
                                     t.to_loc,
                                     f.from_loc_type,
                                     t.to_loc_type
                                from from_loc_temp f,
                                     to_loc_temp t
                               where not exists (select 'x'
                                                   from mc_chrg_head
                                                  where item_list = I_item_list
                                                    and from_loc  = f.from_loc
                                                    and to_loc    = t.to_loc);
            ---
            insert into mc_chrg_detail(item_list,
                                       from_loc,
                                       to_loc,
                                       comp_id,
                                       from_loc_type,
                                       to_loc_type,
                                       comp_rate,
                                       per_count,
                                       per_count_uom,
                                       up_chrg_group,
                                       comp_currency,
                                       display_order,
                                       maintenance_type)
                       select distinct I_item_list,
                                       f.from_loc,
                                       t.to_loc,
                                       I_comp_id,
                                       f.from_loc_type,
                                       t.to_loc_type,
                                       I_comp_rate,
                                       I_per_count,
                                       I_per_count_uom,
                                       I_up_chrg_group,
                                       I_comp_currency,
                                       I_display_order,
                                       I_maintenance_type
                                  from from_loc_temp f,
                                       to_loc_temp t
                                 where not exists (select 'x'
                                                     from mc_chrg_detail
                                                    where item_list = I_item_list
                                                      and from_loc  = f.from_loc
                                                      and to_loc    = t.to_loc
                                                      and comp_id   = I_comp_id);
         end if;
      elsif I_insert_update_del = 'U' then  -- I_insert_update_del = 'U' for Update
         L_var_name := 'I_item_list = ' || I_item_list;
         if I_from_group_type in ('S','W','I','E') and I_to_group_type in ('S','W','I','E') then
            L_table := 'MC_CHRG_DETAIL';
            ---
            SQL_LIB.SET_MARK('OPEN','C_LOCK_MC_CHRG_DETAIL_1','MC_CHRG_DETAIL',NULL);
            open C_LOCK_MC_CHRG_DETAIL_1;
            SQL_LIB.SET_MARK('CLOSE','C_LOCK_MC_CHRG_DETAIL_1','MC_CHRG_DETAIL',NULL);
            close C_LOCK_MC_CHRG_DETAIL_1;
            ---
            SQL_LIB.SET_MARK('UPDATE',NULL,'MC_CHRG_DETAIL',NULL);
            update mc_chrg_detail
               set comp_rate        = I_comp_rate,
                   per_count        = I_per_count,
                   per_count_uom    = I_per_count_uom,
                   up_chrg_group    = I_up_chrg_group,
                   comp_currency    = I_comp_currency,
                   maintenance_type = I_maintenance_type
             where item_list        = I_item_list
               and from_loc         = I_from_group
               and to_loc           = I_to_group
               and comp_id          = I_comp_id;
         else
            if INSERT_MC_TEMP(O_error_message,
                              I_item_list,
                              I_zone_group_id,
                              I_from_group_type,
                              I_from_group,
                              I_to_group_type,
                              I_to_group) = FALSE then
               return FALSE;
            end if;
            ---
            L_table := 'MC_CHRG_DETAIL';
            ---
            SQL_LIB.SET_MARK('OPEN','C_LOCK_MC_CHRG_DETAIL_2','MC_CHRG_DETAIL',NULL);
            open C_LOCK_MC_CHRG_DETAIL_2;
            SQL_LIB.SET_MARK('CLOSE','C_LOCK_MC_CHRG_DETAIL_2','MC_CHRG_DETAIL',NULL);
            close C_LOCK_MC_CHRG_DETAIL_2;
            ---
            SQL_LIB.SET_MARK('UPDATE',NULL,'MC_CHRG_DETAIL',NULL);
            update mc_chrg_detail
               set comp_rate        = I_comp_rate,
                   per_count        = I_per_count,
                   per_count_uom    = I_per_count_uom,
                   up_chrg_group    = I_up_chrg_group,
                   comp_currency    = I_comp_currency,
                   maintenance_type = I_maintenance_type
             where item_list        = I_item_list
               and from_loc         in (select from_loc
                                          from from_loc_temp)
               and to_loc           in (select to_loc
                                          from to_loc_temp)
               and comp_id           = I_comp_id;
         end if;
      else     -- I_insert_update_del = 'D' for 'Delete Comps'
         L_var_name := 'I_item_list = ' || I_item_list;
         if I_from_group_type in ('S','W','I','E') and I_to_group_type in ('S','W','I','E') then
            L_table := 'MC_CHRG_DETAIL';
            ---
            SQL_LIB.SET_MARK('OPEN','C_LOCK_MC_CHRG_DETAIL_1','MC_CHRG_DETAIL',NULL);
            open C_LOCK_MC_CHRG_DETAIL_1;
            SQL_LIB.SET_MARK('CLOSE','C_LOCK_MC_CHRG_DETAIL_1','MC_CHRG_DETAIL',NULL);
            close C_LOCK_MC_CHRG_DETAIL_1;
            ---
            SQL_LIB.SET_MARK('DELETE',NULL,'MC_CHRG_DETAIL',NULL);
            delete from mc_chrg_detail
                  where item_list = I_item_list
                    and from_loc  = I_from_group
                    and to_loc    = I_to_group
                    and comp_id   = I_comp_id;
         else
            if INSERT_MC_TEMP(O_error_message,
                              I_item_list,
                              I_zone_group_id,
                              I_from_group_type,
                              I_from_group,
                              I_to_group_type,
                              I_to_group) = FALSE then
               return FALSE;
            end if;
            ---
            L_table := 'MC_CHRG_DETAIL';
            ---
            SQL_LIB.SET_MARK('OPEN','C_LOCK_MC_CHRG_DETAIL_2','MC_CHRG_DETAIL',NULL);
            open C_LOCK_MC_CHRG_DETAIL_2;
            SQL_LIB.SET_MARK('CLOSE','C_LOCK_MC_CHRG_DETAIL_2','MC_CHRG_DETAIL',NULL);
            close C_LOCK_MC_CHRG_DETAIL_2;
            ---
            SQL_LIB.SET_MARK('DELETE',NULL,'MC_CHRG_DETAIL',NULL);
            delete from mc_chrg_detail
                  where item_list = I_item_list
                    and from_loc  in (select from_loc
                                       from from_loc_temp)
                    and to_loc    in (select to_loc
                                     from to_loc_temp)
                    and comp_id   = I_comp_id;
         end if;

         SQL_LIB.SET_MARK('OPEN', 'C_LOCK_MC_CHRG_HEAD', 'MC_CHRG_HEAD', NULL);
         OPEN C_LOCK_MC_CHRG_HEAD;
         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_MC_CHRG_HEAD', 'MC_CHRG_HEAD', NULL);
         CLOSE C_LOCK_MC_CHRG_HEAD;

         delete from mc_chrg_head h
               where h.item_list = I_item_list
                 and not exists (select 'x'
                                   from mc_chrg_detail d
                                  where d.item_list = h.item_list
                                    and d.from_loc  = h.from_loc
                                    and d.to_loc    = h.to_loc);

      end if;

   end if;
   ---
   if DELETE_TEMP(O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_var_name,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END APPLY_CHARGES;
-------------------------------------------------------------------------------
FUNCTION DELETE_LOCS(O_error_message   IN OUT VARCHAR2,
                     I_item            IN     ITEM_MASTER.ITEM%TYPE,
                     I_zone_group_id   IN     COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                     I_from_group_type IN     CODE_DETAIL.CODE%TYPE,
                     I_from_group      IN     STORE.STORE%TYPE,
                     I_to_group_type   IN     CODE_DETAIL.CODE%TYPE,
                     I_to_group        IN     STORE.STORE%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_CHARGE_SQL.DELETE_LOCS';
   L_table        VARCHAR2(30);
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_ITEM_CHRG_DETAIL_1 is
      select 'x'
        from item_chrg_detail
       where item = I_item
         and from_loc = I_from_group
         and to_loc = I_to_group
         for update nowait;

   cursor C_LOCK_ITEM_CHRG_HEAD_1 is
      select 'x'
        from item_chrg_head
       where item = I_item
         and from_loc = I_from_group
         and to_loc = I_to_group
         for update nowait;

   cursor C_LOCK_ITEM_CHRG_DETAIL_2 is
      select 'x'
        from item_chrg_detail
       where item = I_item
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc in (select to_loc
                          from to_loc_temp)
         for update nowait;

   cursor C_LOCK_ITEM_CHRG_HEAD_2 is
      select 'x'
        from item_chrg_head
       where item = I_item
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc in (select to_loc
                          from to_loc_temp)
         for update nowait;

BEGIN
   if I_from_group_type in ('S','W','I','E') and I_to_group_type in ('S','W','I','E') then
      L_table := 'ITEM_CHRG_DETAIL';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_CHRG_DETAIL_1','ITEM_CHRG_DETAIL',NULL);
      open C_LOCK_ITEM_CHRG_DETAIL_1;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_CHRG_DETAIL_1','ITEM_CHRG_DETAIL',NULL);
      close C_LOCK_ITEM_CHRG_DETAIL_1;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_DETAIL',NULL);
      delete from item_chrg_detail
       where item = I_item
         and from_loc = I_from_group
         and to_loc = I_to_group;
      ---
      L_table := 'ITEM_CHRG_HEAD';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_CHRG_HEAD_1','ITEM_CHRG_HEAD',NULL);
      open C_LOCK_ITEM_CHRG_HEAD_1;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_CHRG_HEAD_1','ITEM_CHRG_HEAD',NULL);
      close C_LOCK_ITEM_CHRG_HEAD_1;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_HEAD',NULL);
      delete from item_chrg_head
       where item = I_item
         and from_loc = I_from_group
         and to_loc = I_to_group;
   else
      if INSERT_TEMP(O_error_message,
                     I_item,
                     I_zone_group_id,
                     I_from_group_type,
                     I_from_group,
                     I_to_group_type,
                     I_to_group) = FALSE then
         return FALSE;
      end if;
      ---
      L_table := 'ITEM_CHRG_DETAIL';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_CHRG_DETAIL_2','ITEM_CHRG_DETAIL',NULL);
      open C_LOCK_ITEM_CHRG_DETAIL_2;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_CHRG_DETAIL_2','ITEM_CHRG_DETAIL',NULL);
      close C_LOCK_ITEM_CHRG_DETAIL_2;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_DETAIL',NULL);
      delete from item_chrg_detail
       where item = I_item
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc in (select to_loc
                          from to_loc_temp);
      ---
      L_table := 'ITEM_CHRG_HEAD';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_CHRG_HEAD_2','ITEM_CHRG_HEAD',NULL);
      open C_LOCK_ITEM_CHRG_HEAD_2;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_CHRG_HEAD_2','ITEM_CHRG_HEAD',NULL);
      close C_LOCK_ITEM_CHRG_HEAD_2;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_HEAD',NULL);
      delete from item_chrg_head
       where item = I_item
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc in (select to_loc
                          from to_loc_temp);
   end if;
   ---
   if DELETE_TEMP(O_error_message) = FALSE then
      return FALSE;
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
END DELETE_LOCS;
---------------------------------------------------------------------------------------------
FUNCTION DELETE_MC_LOCS(O_error_message   IN OUT VARCHAR2,
                        I_item_list       IN     MC_CHRG_HEAD.ITEM_LIST%TYPE,
                        I_zone_group_id   IN     COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                        I_from_group_type IN     CODE_DETAIL.CODE%TYPE,
                        I_from_group      IN     STORE.STORE%TYPE,
                        I_to_group_type   IN     CODE_DETAIL.CODE%TYPE,
                        I_to_group        IN     STORE.STORE%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_CHARGE_SQL.DELETE_MC_LOCS';
   L_table        VARCHAR2(30);
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_MC_CHRG_DETAIL_1 is
      select 'x'
        from mc_chrg_detail
       where item_list = I_item_list
         and from_loc = I_from_group
         and to_loc = I_to_group
         for update nowait;

   cursor C_LOCK_MC_CHRG_HEAD_1 is
      select 'x'
        from mc_chrg_head
       where item_list = I_item_list
         and from_loc = I_from_group
         and to_loc = I_to_group
         for update nowait;

   cursor C_LOCK_MC_CHRG_DETAIL_2 is
      select 'x'
        from mc_chrg_detail
       where item_list = I_item_list
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc in (select to_loc
                          from to_loc_temp)
         for update nowait;

   cursor C_LOCK_MC_CHRG_HEAD_2 is
      select 'x'
        from mc_chrg_head
       where item_list = I_item_list
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc in (select to_loc
                          from to_loc_temp)
         for update nowait;

BEGIN
   if I_from_group_type in ('S','W','I','E') and I_to_group_type in ('S','W','I','E') then
      L_table := 'MC_CHRG_DETAIL';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_MC_CHRG_DETAIL_1','MC_CHRG_DETAIL',NULL);
      open C_LOCK_MC_CHRG_DETAIL_1;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_MC_CHRG_DETAIL_1','MC_CHRG_DETAIL',NULL);
      close C_LOCK_MC_CHRG_DETAIL_1;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'MC_CHRG_DETAIL',NULL);
      delete from mc_chrg_detail
       where item_list = I_item_list
         and from_loc = I_from_group
         and to_loc = I_to_group;
      ---
      L_table := 'MC_CHRG_HEAD';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_MC_CHRG_HEAD_1','MC_CHRG_HEAD',NULL);
      open C_LOCK_MC_CHRG_HEAD_1;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_MC_CHRG_HEAD_1','MC_CHRG_HEAD',NULL);
      close C_LOCK_MC_CHRG_HEAD_1;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'MC_CHRG_HEAD',NULL);
      delete from mc_chrg_head
       where item_list = I_item_list
         and from_loc = I_from_group
         and to_loc = I_to_group;
   else
      if INSERT_MC_TEMP(O_error_message,
                        I_item_list,
                        I_zone_group_id,
                        I_from_group_type,
                        I_from_group,
                        I_to_group_type,
                        I_to_group) = FALSE then
         return FALSE;
      end if;
      ---
      L_table := 'MC_CHRG_DETAIL';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_MC_CHRG_DETAIL_2','MC_CHRG_DETAIL',NULL);
      open C_LOCK_MC_CHRG_DETAIL_2;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_MC_CHRG_DETAIL_2','MC_CHRG_DETAIL',NULL);
      close C_LOCK_MC_CHRG_DETAIL_2;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'MC_CHRG_DETAIL',NULL);
      delete from mc_chrg_detail
       where item_list = I_item_list
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc in (select to_loc
                          from to_loc_temp);
      ---
      L_table := 'MC_CHRG_HEAD';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_MC_CHRG_HEAD_2','MC_CHRG_HEAD',NULL);
      open C_LOCK_MC_CHRG_HEAD_2;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_MC_CHRG_HEAD_2','MC_CHRG_HEAD',NULL);
      close C_LOCK_MC_CHRG_HEAD_2;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'MC_CHRG_HEAD',NULL);
      delete from mc_chrg_head
       where item_list = I_item_list
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc in (select to_loc
                          from to_loc_temp);
   end if;
   ---
   if DELETE_TEMP(O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item_list,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_MC_LOCS;
---------------------------------------------------------------------------------------------
FUNCTION CHARGES_EXIST(O_error_message IN OUT VARCHAR2,
                       O_exists        IN OUT BOOLEAN,
                       I_item          IN     ITEM_MASTER.ITEM%TYPE,
                       I_from_loc      IN     ORDLOC.LOCATION%TYPE,
                       I_to_loc        IN     ORDLOC.LOCATION%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(60)  := 'ITEM_CHARGES_SQL.CHARGES_EXIST';
   L_exists        VARCHAR2(1)   := 'N';
   L_pack_ind      ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind  ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type     ITEM_MASTER.PACK_TYPE%TYPE;

   cursor C_GET_PACK_ITEMS is
      select item
        from v_packsku_qty
       where pack_no = I_item;

   cursor C_CHARGES_EXIST(L_item ITEM_MASTER.ITEM%TYPE) is
      select 'Y'
        from item_chrg_detail
       where item = L_item
         and from_loc = NVL(I_from_loc, from_loc)
         and to_loc = NVL(I_to_loc,   to_loc)
	 and ROWNUM = 1;

BEGIN
   O_exists := FALSE;
   ---
   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_pack_ind = 'Y' and L_pack_type = 'B' then
      for C_rec in C_GET_PACK_ITEMS loop
         SQL_LIB.SET_MARK('OPEN','C_CHARGES_EXIST','ITEM_CHRG_DETAIL','Item: '||I_item);
         open C_CHARGES_EXIST(C_rec.item);
         SQL_LIB.SET_MARK('FETCH','C_CHARGES_EXIST','ITEM_CHRG_DETAIL','Item: '||I_item);
         fetch C_CHARGES_EXIST into L_exists;
         SQL_LIB.SET_MARK('CLOSE','C_CHARGES_EXIST','ITEM_CHRG_DETAIL','Item: '||I_item);
         close C_CHARGES_EXIST;
         ---
         if L_exists = 'Y' then
            O_exists := TRUE;
            return TRUE;
         end if;
      end loop;
   else
      SQL_LIB.SET_MARK('OPEN','C_CHARGES_EXIST','ITEM_CHRG_DETAIL','Item: '||I_item);
      open C_CHARGES_EXIST(I_item);
      SQL_LIB.SET_MARK('FETCH','C_CHARGES_EXIST','ITEM_CHRG_DETAIL','Item: '||I_item);
      fetch C_CHARGES_EXIST into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_CHARGES_EXIST','ITEM_CHRG_DETAIL','Item: '||I_item);
      close C_CHARGES_EXIST;
      ---
      if L_exists = 'Y' then
         O_exists := TRUE;
      end if;
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
END CHARGES_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION CHARGES_EXIST(O_error_message IN OUT VARCHAR2,
                       O_exists        IN OUT BOOLEAN,
                       I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(60)  := 'ITEM_CHARGES_SQL.CHARGES_EXIST';

BEGIN
   if CHARGES_EXIST(O_error_message,
                    O_exists,
                    I_item,
                    NULL,
                    NULL) = FALSE then
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
END CHARGES_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION DEFAULT_PARENT_CHRGS(O_error_message IN OUT VARCHAR2,
                              I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(65) := 'ITEM_CHARGE_SQL.DEFAULT_PARENT_CHRGS';
   L_table         VARCHAR2(65);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_CHRG_DETAIL is
      select 'x'
        from item_chrg_detail
       where item in (select item
                        from item_master
                       where item_parent = I_item
                          or item_grandparent = I_item)
         for update nowait;

   cursor C_LOCK_ITEM_CHRG_HEAD is
      select 'x'
        from item_chrg_head
       where item in (select item
                        from item_master
                       where item_parent = I_item
                          or item_grandparent = I_item)
         for update nowait;

BEGIN
   L_table := 'ITEM_CHRG_DETAIL';
   ---
   open  C_LOCK_ITEM_CHRG_DETAIL;
   close C_LOCK_ITEM_CHRG_DETAIL;
   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_DETAIL','Item Parent: '||I_item);
   ---
   delete item_chrg_detail
    where item in (select item
                     from item_master
                    where item_parent = I_item
                       or item_grandparent = I_item);
   ---
   L_table := 'ITEM_CHRG_HEAD';
   ---
   open  C_LOCK_ITEM_CHRG_HEAD;
   close C_LOCK_ITEM_CHRG_HEAD;
   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_HEAD','Item Parent: '||I_item);
   ---
   delete item_chrg_head
    where item in (select item
                     from item_master
                    where item_parent = I_item
                       or item_grandparent = I_item);
   ---
   SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_CHRG_HEAD','Item Parent: '||I_item);
   insert into item_chrg_head(item,
                              from_loc,
                              to_loc,
                              from_loc_type,
                              to_loc_type)
              select distinct i.item,
                              h.from_loc,
                              h.to_loc,
                              h.from_loc_type,
                              h.to_loc_type
                         from item_chrg_head h,
                              item_master i
                        where (i.item_parent = I_item
                               and i.item_parent = h.item)
                           or (i.item_grandparent = I_item
                               and i.item_grandparent = h.item);
   ---
   SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_CHRG_DETAIL','ITEM: '||I_item);
   insert into item_chrg_detail(item,
                                from_loc,
                                to_loc,
                                comp_id,
                                from_loc_type,
                                to_loc_type,
                                comp_rate,
                                per_count,
                                per_count_uom,
                                up_chrg_group,
                                comp_currency,
                                display_order)
                select distinct i.item,
                                d.from_loc,
                                d.to_loc,
                                d.comp_id,
                                d.from_loc_type,
                                d.to_loc_type,
                                d.comp_rate,
                                d.per_count,
                                d.per_count_uom,
                                d.up_chrg_group,
                                d.comp_currency,
                                d.display_order
                           from item_chrg_detail d,
                                item_master i
                          where (i.item_parent = I_item
                                 and i.item_parent = d.item)
                             or (i.item_grandparent = I_item
                                 and i.item_grandparent = d.item);
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('TABLE_LOCKED',
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
END DEFAULT_PARENT_CHRGS;
---------------------------------------------------------------------------------------------
FUNCTION CHECK_HEADER_NO_DETAILS(O_error_message IN OUT  VARCHAR2,
                                 O_exists        IN OUT  BOOLEAN,
                                 I_item          IN      ITEM_MASTER.ITEM%TYPE,
                                 I_item_list     IN      SKULIST_HEAD.SKULIST%TYPE)

RETURN BOOLEAN IS

   FUNCTION_NAME CONSTANT VARCHAR2(61) := 'ITEM_CHARGE_SQL.CHECK_HEADER_NO_DETAILS';

   cursor C_SKD
       is
   select skd.item
     from v_item_master  viem,
          skulist_detail skd
    where skd.skulist    = I_item_list
      and skd.item       = viem.item;

BEGIN

   if ((I_item is     NULL and I_item_list is     NULL)
   or  (I_item is not NULL and I_item_list is not NULL)) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_COMBINATION_GENERIC',
                                            'I_item',
                                            'I_item_list');
      return FALSE;
   end if;

   if I_item is NULL then

      for c_skd_row in C_SKD loop

         if ITEM_CHARGE_SQL.CHECK_HEADER_NO_DETAILS(O_error_message,
                                                    O_exists,
                                                    c_skd_row.item) = FALSE then
            return FALSE;
         end if;

         if O_exists then
            exit;
         end if;

      end loop;

   else

      if ITEM_CHARGE_SQL.CHECK_HEADER_NO_DETAILS(O_error_message,
                                                 O_exists,
                                                 I_item) = FALSE then
         return FALSE;
      end if;

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            FUNCTION_NAME,
                                            To_Char(SQLCODE));
   return FALSE;
END CHECK_HEADER_NO_DETAILS;
---------------------------------------------------------------------------------------------
FUNCTION CHECK_HEADER_NO_DETAILS(O_error_message IN OUT  VARCHAR2,
                                 O_exists        IN OUT  BOOLEAN,
                                 I_item          IN      ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_exists      VARCHAR2(1) := 'N';

   cursor C_CHECK_FOR_DETAILS is
      select 'Y'
        from item_chrg_head h
       where h.item = I_item
         and not exists (select 'x'
                           from item_chrg_detail d
                          where d.item = h.item
                            and d.from_loc = h.from_loc
                            and d.to_loc = h.to_loc);

BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_FOR_DETAILS','ITEM_CHRG_HEAD, ITEM_CHRG_DETAIL',NULL);
   open C_CHECK_FOR_DETAILS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_FOR_DETAILS','ITEM_CHRG_HEAD, ITEM_CHRG_DETAIL',NULL);
   fetch C_CHECK_FOR_DETAILS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_FOR_DETAILS','ITEM_CHRG_HEAD, ITEM_CHRG_DETAIL',NULL);
   close C_CHECK_FOR_DETAILS;
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
                                            'ITEM_CHARGE_SQL.CHECK_HEADER_NO_DETAILS',
                                             to_char(SQLCODE));
   return FALSE;
END CHECK_HEADER_NO_DETAILS;
---------------------------------------------------------------------------------------------
FUNCTION DELETE_HEADER(O_error_message IN OUT  VARCHAR2,
                       I_item          IN      ITEM_MASTER.ITEM%TYPE,
                       I_item_list     IN      SKULIST_HEAD.SKULIST%TYPE)

RETURN BOOLEAN IS

   FUNCTION_NAME CONSTANT VARCHAR2(61) := 'ITEM_CHARGE_SQL.DELETE_HEADER';

   cursor C_SKD
       is
   select skd.item
     from v_item_master  viem,
          skulist_detail skd
    where skd.skulist    = I_item_list
      and skd.item       = viem.item;

BEGIN

   if ((I_item is     NULL and I_item_list is     NULL)
   or  (I_item is not NULL and I_item_list is not NULL)) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_COMBINATION_GENERIC',
                                            'I_item',
                                            'I_item_list');
      return FALSE;
   end if;

   if I_item is NULL then

      for c_skd_row in C_SKD loop

         if ITEM_CHARGE_SQL.DELETE_HEADER(O_error_message,
                                          c_skd_row.item) = FALSE then
            return FALSE;
         end if;

      end loop;

   else

      if ITEM_CHARGE_SQL.DELETE_HEADER(O_error_message,
                                       I_item) = FALSE then
         return FALSE;
      end if;

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            FUNCTION_NAME,
                                            To_Char(SQLCODE));
   return FALSE;
END DELETE_HEADER;
---------------------------------------------------------------------------------------------
FUNCTION DELETE_HEADER(O_error_message IN OUT  VARCHAR2,
                       I_item          IN      ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_table        VARCHAR2(30) := 'ITEM_CHRG_HEAD';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_HEAD is
      select 'x'
        from item_chrg_head h
       where h.item = I_item
         and not exists (select 'x'
                           from item_chrg_detail d
                          where d.item = h.item
                            and d.from_loc = h.from_loc
                            and d.to_loc = h.to_loc)
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_HEAD','ITEM_CHRG_HEAD',NULL);
   open C_LOCK_ITEM_HEAD;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_HEAD','ITEM_CHRG_HEAD',NULL);
   close C_LOCK_ITEM_HEAD;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'ITEM_CHRG_HEAD', NULL);
   delete from item_chrg_head h
         where h.item = I_item
           and not exists (select 'x'
                             from item_chrg_detail d
                            where d.item = h.item
                              and d.from_loc = h.from_loc
                              and d.to_loc = h.to_loc);
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
                                            'ITEM_CHARGE_SQL.DELETE_HEADER',
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_HEADER;
--------------------------------------------------------------------------------
FUNCTION DEFAULT_CHRGS(O_error_message IN OUT VARCHAR2,
                       I_item          IN     ITEM_MASTER.ITEM%TYPE,
                       I_item_level    IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                       I_tran_level    IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                       I_pack_ind      IN     ITEM_MASTER.PACK_IND%TYPE,
                       I_pack_type     IN     ITEM_MASTER.PACK_TYPE%TYPE,
                       I_dept          IN     DEPS.DEPT%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(65) := 'ITEM_CHARGE_SQL.DEFAULT_CHRGS';

BEGIN
   ---
   -- Up Charges cannot be associated with items that are below the
   -- transaction level or items that are Buyer Packs.
   ---
   if I_tran_level < I_item_level or (I_pack_ind = 'Y' and I_pack_type = 'B') then
      return TRUE;
   end if;
   ---
   insert into item_chrg_head(item,
                              from_loc,
                              to_loc,
                              from_loc_type,
                              to_loc_type)
              select distinct I_item,
                              d.from_loc,
                              d.to_loc,
                              d.from_loc_type,
                              d.to_loc_type
                         from dept_chrg_head d
                        where d.dept = I_dept
                        --26-Mar-2010 Tesco HSC/Usha Patil       Mod: CR275 Begin
                          and d.from_loc_type != 'X'
                          and d.to_loc_type != 'X'
                        --26-Mar-2010 Tesco HSC/Usha Patil       Mod: CR275 End
                          and not exists (select 'x'
                                            from item_chrg_head
                                           where item = I_item
                                             and from_loc = d.from_loc
                                             and to_loc = d.to_loc);
   ---
   insert into item_chrg_detail(item,
                                from_loc,
                                to_loc,
                                comp_id,
                                from_loc_type,
                                to_loc_type,
                                comp_rate,
                                per_count,
                                per_count_uom,
                                up_chrg_group,
                                comp_currency,
                                display_order)
                select distinct I_item,
                                d.from_loc,
                                d.to_loc,
                                d.comp_id,
                                d.from_loc_type,
                                d.to_loc_type,
                                d.comp_rate,
                                d.per_count,
                                d.per_count_uom,
                                d.up_chrg_group,
                                d.comp_currency,
                                e.display_order
                           from dept_chrg_detail d,
                                elc_comp e
                          where d.dept = I_dept
                            and d.comp_id = e.comp_id
                            --26-Mar-2010 Tesco HSC/Usha Patil       Mod: CR275 Begin
                            and d.from_loc_type != 'X'
                            and d.to_loc_type != 'X'
                           --26-Mar-2010 Tesco HSC/Usha Patil       Mod: CR275 End
                            and not exists (select 'x'
                                              from item_chrg_detail i
                                             where i.item = I_item
                                               and i.from_loc = d.from_loc
                                               and i.to_loc = d.to_loc
                                               and i.comp_id = d.comp_id);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEFAULT_CHRGS;
------------------------------------------------------------------------------------
FUNCTION DELETE_CHRGS(O_error_message IN OUT  VARCHAR2,
                      I_item          IN      ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_table        VARCHAR2(30) := 'ITEM_CHRG_DETAIL';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_DETAIL is
      select 'x'
        from item_chrg_detail
       where item = I_item
         for update nowait;

   cursor C_LOCK_ITEM_HEAD is
      select 'x'
        from item_chrg_head
       where item = I_item
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_DETAIL','ITEM_CHRG_DETAIL',NULL);
   open C_LOCK_ITEM_DETAIL;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_DETAIL','ITEM_CHRG_DETAIL',NULL);
   close C_LOCK_ITEM_DETAIL;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'ITEM_CHRG_DETAIL', NULL);
   delete from item_chrg_detail
         where item = I_item;
   ---
   L_table := 'ITEM_CHRG_HEAD';
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_HEAD','ITEM_CHRG_HEAD',NULL);
   open C_LOCK_ITEM_HEAD;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_HEAD','ITEM_CHRG_HEAD',NULL);
   close C_LOCK_ITEM_HEAD;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'ITEM_CHRG_HEAD', NULL);
   delete from item_chrg_head
         where item = I_item;
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
                                            'ITEM_CHARGE_SQL.DELETE_CHRGS',
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_CHRGS;
--------------------------------------------------------------------------------
FUNCTION DEFAULT_CHRGS(O_error_message IN OUT VARCHAR2,
                       I_items          IN      ITEM_TBL,
                       I_depts          IN      DEPT_TBL)

   RETURN BOOLEAN IS

   L_program        VARCHAR2(65) := 'ITEM_CHARGE_SQL.DEFAULT_CHRGS';
   L_error_message  rtk_errors.rtk_text%TYPE;
   L_item_tbl       ITEM_TBL := I_ITEMS;
   L_dept_tbl       DEPT_TBL := I_DEPTS;

BEGIN
   ---
   ---    SQL_LIB.SET_MARK('INSERT',NULL,'item_chrg_head',NULL);
   ---

   if L_item_tbl is NOT NULL and L_item_tbl.COUNT > 0 then

      FORALL i in L_item_tbl.FIRST..L_item_tbl.LAST

         insert into item_chrg_head(item,
                                    from_loc,
                                    to_loc,
                                    from_loc_type,
                                    to_loc_type)
                    select distinct L_item_tbl(i),
                                    d.from_loc,
                                    d.to_loc,
                                    d.from_loc_type,
                                    d.to_loc_type
                               from dept_chrg_head d
                              where d.dept = L_dept_tbl(i)
                                and not exists (select 'x'
                                                  from item_chrg_head
                                                 where item = L_item_tbl(i)
                                                   and from_loc = d.from_loc
                                                   and to_loc = d.to_loc);

   ---   SQL_LIB.SET_MARK('INSERT',NULL,'item_chrg_detail',NULL);

      FORALL i in L_item_tbl.FIRST..L_item_tbl.LAST

         insert into item_chrg_detail(item,
                                      from_loc,
                                      to_loc,
                                      comp_id,
                                      from_loc_type,
                                      to_loc_type,
                                      comp_rate,
                                      per_count,
                                      per_count_uom,
                                      up_chrg_group,
                                      comp_currency,
                                      display_order)
                      select distinct L_item_tbl(i),
                                      d.from_loc,
                                      d.to_loc,
                                      d.comp_id,
                                      d.from_loc_type,
                                      d.to_loc_type,
                                      d.comp_rate,
                                      d.per_count,
                                      d.per_count_uom,
                                      d.up_chrg_group,
                                      d.comp_currency,
                                      e.display_order
                                 from dept_chrg_detail d,
                                      elc_comp e
                                where d.dept = L_dept_tbl(i)
                                  and d.comp_id = e.comp_id
                                  and not exists (select 'x'
                                                    from item_chrg_detail i
                                                   where i.item = L_item_tbl(i)
                                                     and i.from_loc = d.from_loc
                                                     and i.to_loc = d.to_loc
                                                     and i.comp_id = d.comp_id);

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
END DEFAULT_CHRGS;
-------------------------------------------------------------------------------------------------------
-- 27-Jun-2007 Govindarajan - MOD 365b1 Begin
-------------------------------------------------------------------------------------------------------
-- Function Name  : TSL_DEFAULT_BASE_CHRGS
-- Purpose        : To default UP Charges information from a Base Item to it?s
--                  Variant Items. Varian Item?s UP Charges will first be deleted,
--                  before the defaulting occurs.
------------------------------------------------------------------------------------
FUNCTION TSL_DEFAULT_BASE_CHRGS (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_table          VARCHAR2(65);
   L_program        VARCHAR2(300) := 'ITEM_CHARGE_SQL.TSL_DEFAULT_BASE_CHRGS';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);

   -- This cursor will lock the variant and its children information
   -- on the table ITEM_CHRG_DETAIL
   cursor C_LOCK_ITEM_CHRG_DETAIL is
      select 'x'
        from item_chrg_detail d
       where d.item in (select im2.item
                          from item_master im1,
                               item_master im2
                         where im1.tsl_base_item  = I_item
                           and im1.tsl_base_item != im1.item
                           and im1.item_level     = im1.tran_level
                           and im1.item_level     = 2
                           and (im1.item          = im2.item_parent
                            or im1.item           = im2.item))
         for update nowait;

   -- This cursor will lock the variant and its children information
   -- on the table ITEM_CHRG_HEAD
   cursor C_LOCK_ITEM_CHRG_HEAD is
      select 'x'
        from item_chrg_head h
       where h.item in (select im2.item
                          from item_master im1,
                               item_master im2
                         where im1.tsl_base_item  = I_item
                           and im1.tsl_base_item != im1.item
                           and im1.item_level     = im1.tran_level
                           and im1.item_level     = 2
                           and (im1.item          = im2.item_parent
                            or im1.item           = im2.item))
         for update nowait;

   -- This cursor will return the Variant and its children Items number associated
   -- to the Base Item information.
   cursor C_INSERT_ITEM_CHRG_HEAD is
      select distinct im2.item item,
             h.from_loc,
             h.to_loc,
             h.from_loc_type,
             h.to_loc_type
        from item_chrg_head h,
             item_master im1,
             item_master im2
       where h.item              = I_item
         and im1.tsl_base_item   = h.item
         and im1.tsl_base_item  != im1.item
         and (im1.item           = im2.item_parent
          or im1.item = im2.item)
         and im1.item_level      = im1.tran_level
         and im1.item_level      = 2;

   -- This cursor will return the Variant and its children Items number associated
   -- to the Base Item information.
   cursor C_INSERT_ITEM_CHRG_DETAIL is
      select distinct im2.item item,
             d.from_loc,
             d.to_loc,
             d.comp_id,
             d.from_loc_type,
             d.to_loc_type,
             d.comp_rate,
             d.per_count,
             d.per_count_uom,
             d.up_chrg_group,
             d.comp_currency,
             d.display_order
        from item_chrg_detail d,
             item_master im1,
             item_master im2
       where d.item              = I_item
         and im1.tsl_base_item   = d.item
         and im1.tsl_base_item  != im1.item
         and (im1.item           = im2.item_parent
          or im1.item = im2.item)
         and im1.item_level      = im1.tran_level
         and im1.item_level      = 2;

BEGIN
      if I_item is NULL then                                       -- L1 begin
          -- If input item is null then throws an error
          O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                I_item,
                                                L_program,
                                                NULL);
          return FALSE;
      else                                                        -- L1 else

          L_table := 'ITEM_CHRG_DETAIL';
          -- Opening and closing the C_LOCK_ITEM_CHRG_DETAIL cursor
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_ITEM_CHRG_DETAIL',
                           L_table,
                           'ITEM: ' ||I_item);
          open C_LOCK_ITEM_CHRG_DETAIL;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_ITEM_CHRG_DETAIL',
                           L_table,
                           'ITEM: ' ||I_item);
          close C_LOCK_ITEM_CHRG_DETAIL;

          -- Deleting the records from ITEM_HTS_ASSESS table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           L_table,
                           'ITEM: ' ||I_item);

          delete from item_chrg_detail
           where item in (select im2.item
                            from item_master im1,
                                 item_master im2
                           where im1.tsl_base_item  = I_item
                             and im1.tsl_base_item != im1.item
                             and im1.item_level     = im1.tran_level
                             and im1.item_level     = 2
                             and (im1.item          = im2.item_parent
                              or im1.item = im2.item));

          L_table := 'ITEM_CHRG_HEAD';
          -- Opening and closing the C_LOCK_ITEM_CHRG_HEAD cursor
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_ITEM_CHRG_HEAD',
                           L_table,
                           'ITEM: ' ||I_item);
          open C_LOCK_ITEM_CHRG_HEAD;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_ITEM_CHRG_HEAD',
                           L_table,
                           'ITEM: ' ||I_item);
          close C_LOCK_ITEM_CHRG_HEAD;

          -- Deleting the records from ITEM_HTS table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           L_table,
                           'ITEM: ' ||I_item);

          delete from item_chrg_head
           where item in (select im2.item
                            from item_master im1,
                                 item_master im2
                           where im1.tsl_base_item  = I_item
                             and im1.tsl_base_item != im1.item
                             and im1.item_level     = im1.tran_level
                             and im1.item_level     = 2
                             and (im1.item          = im2.item_parent
                              or im1.item = im2.item));

          -- Cursor for ITEM_CHRG_HEAD table
          -- Opening the cursor C_INSERT_ITEM_CHRG_HEAD
          SQL_LIB.SET_MARK('OPEN',
                           'C_INSERT_ITEM_CHRG_HEAD',
                           L_table,
                           'ITEM: ' ||I_item);
          FOR C_insert_head_rec in C_INSERT_ITEM_CHRG_HEAD
          LOOP                                            -- L2 begin
              -- Inserting records into ITEM_HTS table
              SQL_LIB.SET_MARK('INSERT',
                               NULL,
                               L_table,
                               'ITEM: ' ||I_item);

              insert into item_chrg_head
                          (item,
                           from_loc,
                           to_loc,
                           from_loc_type,
                           to_loc_type)
                   values (C_insert_head_rec.item,
                           C_insert_head_rec.from_loc,
                           C_insert_head_rec.to_loc,
                           C_insert_head_rec.from_loc_type,
                           C_insert_head_rec.to_loc_type);
          END LOOP;         -- L2 end

          -- Opening the cursor C_INSERT_ITEM_CHRG_DETAIL
          SQL_LIB.SET_MARK('OPEN',
                           'C_INSERT_ITEM_CHRG_DETAIL',
                           L_table,
                           'ITEM: ' ||I_item);
          FOR C_insert_detail_rec in C_INSERT_ITEM_CHRG_DETAIL
          LOOP                                                            -- L3 begin
              -- Inserting records into ITEM_CHRG_DETAIL table
              SQL_LIB.SET_MARK('INSERT',
                               NULL,
                               L_table,
                               'ITEM: ' ||I_item);

              insert into item_chrg_detail
                          (item,
                           from_loc,
                           to_loc,
                           comp_id,
                           from_loc_type,
                           to_loc_type,
                           comp_rate,
                           per_count,
                           per_count_uom,
                           up_chrg_group,
                           comp_currency,
                           display_order)
                   values (C_insert_detail_rec.item,
                           C_insert_detail_rec.from_loc,
                           C_insert_detail_rec.to_loc,
                           C_insert_detail_rec.comp_id,
                           C_insert_detail_rec.from_loc_type,
                           C_insert_detail_rec.to_loc_type,
                           C_insert_detail_rec.comp_rate,
                           C_insert_detail_rec.per_count,
                           C_insert_detail_rec.per_count_uom,
                           C_insert_detail_rec.up_chrg_group,
                           C_insert_detail_rec.comp_currency,
                           C_insert_detail_rec.display_order);
          END LOOP;                 -- L3 end

          return TRUE;
      end if;                                              -- L1 end
EXCEPTION
   -- Raising an exception for record lock error
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_program,
                                            'ITEM: ' ||I_item);
      return FALSE;

   -- Raising an exception for others
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END TSL_DEFAULT_BASE_CHRGS;
-------------------------------------------------------------------------------------------------------
-- 27-Jun-2007 Govindarajan - MOD 365b1 End
-------------------------------------------------------------------------------------------------------
END ITEM_CHARGE_SQL;
/

