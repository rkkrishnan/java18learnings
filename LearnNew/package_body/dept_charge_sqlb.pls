CREATE OR REPLACE PACKAGE BODY DEPT_CHARGE_SQL AS
-------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 25-Mar-2010
-- Mod Ref    : CR275
-- Mod Details: Modified package to handle Up charges for IC transfers at dept level.
-------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_EXTERNAL_FINISHER V_INTERNAL_FINISHER V_STORE V_WH
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION INSERT_TEMP(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_dept            IN     DEPS.DEPT%TYPE,
                     I_from_group_type IN     CODE_DETAIL.CODE%TYPE,
                     I_from_group      IN     STORE.STORE%TYPE,
                     I_to_group_type   IN     CODE_DETAIL.CODE%TYPE,
                     I_to_group        IN     STORE.STORE%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DEPT_CHARGE_SQL.INSERT_TEMP';

BEGIN
   if I_from_group_type in ('A','R','D','AS') then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select store,
                                'S'
                           from v_store
                          where stockholding_ind    = 'Y'
                            and ((I_from_group_type   = 'A'
                                  and area          = I_from_group)
                                or (I_from_group_type = 'R'
                                    and region      = I_from_group)
                                or (I_from_group_type = 'D'
                                    and district    = I_from_group)
                                or (I_from_group_type = 'AS'))
                            and exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = store);
   elsif I_from_group_type = 'AW' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select wh,
                                'W'
                           from v_wh
                          where stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = wh);
   elsif I_from_group_type = 'AI' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select finisher_id,
                                'W'
                           from v_internal_finisher
                          where exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept = I_dept
                                           and i.from_loc = finisher_id);
   elsif I_from_group_type = 'AE' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select finisher_id,
                                'E'
                           from v_external_finisher
                          where exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept = I_dept
                                           and i.from_loc = finisher_id);
   elsif I_from_group_type = 'PW' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select wh,
                                'W'
                           from v_wh
                          where stockholding_ind = 'Y'
                            and physical_wh      = I_from_group
                            and exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = wh)
                          union all
                         select finisher_id,
                                'W'
                           from v_internal_finisher
                          where physical_wh      = I_from_group
                            and exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = finisher_id);
   elsif I_from_group_type = 'LL' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select d.location,
                                'S'
                           from loc_list_detail d,
                                v_store s
                          where s.store = d.location
                            and d.loc_list = I_from_group
                            and d.loc_type = 'S'
                            and exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = d.location);
      ---
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select w.wh,
                                'W'
                           from loc_list_detail d,
                                v_wh w
                          where d.loc_list         = I_from_group
                            and d.loc_type         = 'W'
                            and d.location         = w.wh
                            and w.stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = w.wh);
      ---
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select w.wh,
                                'W'
                           from loc_list_detail d,
                                v_wh w
                          where d.loc_list         = I_from_group
                            and d.loc_type         = 'W'
                            and d.location         = w.physical_wh
                            and w.stockholding_ind = 'Y'
                            and not exists (select 'x'
                                              from from_loc_temp t
                                              where t.from_loc = w.wh)
                            and exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = w.wh);
   elsif I_from_group_type = 'AL' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select store,
                                'S'
                           from v_store
                          where stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = store)
                          union
                         select wh,
                                'W'
                           from v_wh
                          where stockholding_ind = 'Y'
                            and exists (select 'x'
                                          from dept_chrg_head i
                                          where i.dept     = I_dept
                                            and i.from_loc = wh)
                          union
                         select finisher_id,
                                 'W'
                           from v_internal_finisher
                          where exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept = I_dept
                                           and i.from_loc = finisher_id)
                          union
                         select finisher_id,
                                'E'
                           from v_external_finisher
                          where exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept = I_dept
                                           and i.from_loc = finisher_id);
   elsif I_from_group_type = 'T' then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select store,
                                'S'
                           from v_store
                          where stockholding_ind  = 'Y'
                            and transfer_zone     = I_from_group
                            and exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = store);
   elsif I_from_group_type in ('S','W','I','E') then
      insert into from_loc_temp(from_loc,
                                from_loc_type)
                         select I_from_group,
                                DECODE(I_from_group_type, 'I', 'W', I_from_group_type)
                           from dual
                          where exists (select 'x'
                                          from dept_chrg_head i
                                         where i.dept     = I_dept
                                           and i.from_loc = I_from_group);
   end if;
   ---
   if I_to_group_type in ('A','R','D','AS') then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select store,
                              'S'
                         from v_store
                        where stockholding_ind  = 'Y'
                          and ((I_to_group_type   = 'A'
                                and area        = I_to_group)
                              or (I_to_group_type = 'R'
                                  and region    = I_to_group)
                              or (I_to_group_type = 'D'
                                  and district  = I_to_group)
                              or (I_to_group_type = 'AS'))
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
                                         and i.to_loc = store);
   elsif I_to_group_type = 'AW' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select wh,
                              'W'
                         from v_wh
                        where stockholding_ind  = 'Y'
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
                                         and i.to_loc = wh);

   elsif I_to_group_type = 'AI' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                      select finisher_id,
                             'W'
                        from v_internal_finisher
                       where exists (select 'x'
                                       from dept_chrg_head i
                                      where i.dept = I_dept
                                        and i.to_loc = finisher_id);
   elsif I_to_group_type = 'AE' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                      select finisher_id,
                             'E'
                        from v_external_finisher
                       where exists (select 'x'
                                       from dept_chrg_head i
                                      where i.dept = I_dept
                                        and i.to_loc = finisher_id);
   elsif I_to_group_type = 'PW' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select wh,
                              'W'
                         from v_wh
                        where stockholding_ind = 'Y'
                          and physical_wh      = I_to_group
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
                                         and i.to_loc = wh)
                        union all
                       select finisher_id,
                              'W'
                         from v_internal_finisher
                        where physical_wh      = I_to_group
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept     = I_dept
                                         and i.to_loc = finisher_id);
   elsif I_to_group_type = 'LL' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select d.location,
                              'S'
                         from loc_list_detail d,
                              v_store s
                        where s.store = d.location
                          and d.loc_list = I_to_group
                          and d.loc_type = 'S'
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
                                         and i.to_loc = d.location);
      ---
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select w.wh,
                              'W'
                         from loc_list_detail d,
                              v_wh w
                        where d.loc_list         = I_to_group
                          and d.loc_type         = 'W'
                          and d.location         = w.wh
                          and w.stockholding_ind = 'Y'
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
                                         and i.to_loc = w.wh);
      ---
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select w.wh,
                              'W'
                         from loc_list_detail d,
                              v_wh w
                        where d.loc_list         = I_to_group
                          and d.loc_type         = 'W'
                          and d.location         = w.physical_wh
                          and w.stockholding_ind = 'Y'
                          and not exists (select 'x'
                                            from to_loc_temp t
                                           where t.to_loc = w.wh)
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
                                         and i.to_loc = w.wh);
   elsif I_to_group_type = 'AL' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select store,
                              'S'
                         from v_store
                        where stockholding_ind  = 'Y'
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
                                         and i.to_loc = store)
                        union
                       select wh,
                              'W'
                         from v_wh
                        where stockholding_ind  = 'Y'
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
                                         and i.to_loc = wh)
                        union
                       select finisher_id,
                              'W'
                         from v_internal_finisher
                        where exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept = I_dept
                                         and i.to_loc = finisher_id)
                        union
                       select finisher_id,
                              'E'
                         from v_external_finisher
                        where exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept = I_dept
                                         and i.to_loc = finisher_id);
   elsif I_to_group_type = 'T' then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select store,
                              'S'
                         from v_store
                        where stockholding_ind  = 'Y'
                          and transfer_zone     = I_to_group
                          and exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
                                         and i.to_loc = store);
   elsif I_to_group_type in ('S','W','I','E') then
      insert into to_loc_temp(to_loc,
                              to_loc_type)
                       select I_to_group,
                              DECODE(I_to_group_type, 'I', 'W', I_to_group_type)
                         from dual
                        where exists (select 'x'
                                        from dept_chrg_head i
                                       where i.dept   = I_dept
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
--------------------------------------------------------------------------------------
FUNCTION DELETE_TEMP(O_error_message IN OUT VARCHAR2)

RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DEPT_CHARGE_SQL.DELETE_TEMP';
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
--    V_EXTERNAL_FINISHER V_INTERNAL_FINISHER V_STORE V_WH
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION APPLY_CHARGES(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       I_dept              IN     DEPS.DEPT%TYPE,
                       I_from_group_type   IN     CODE_DETAIL.CODE%TYPE,
                       I_from_group        IN     STORE.STORE%TYPE,
                       I_to_group_type     IN     CODE_DETAIL.CODE%TYPE,
                       I_to_group          IN     STORE.STORE%TYPE,
                       I_comp_id           IN     ELC_COMP.COMP_ID%TYPE,
                       I_up_chrg_group     IN     ITEM_CHRG_DETAIL.UP_CHRG_GROUP%TYPE,
                       I_comp_rate         IN     ELC_COMP.COMP_RATE%TYPE,
                       I_per_count         IN     ELC_COMP.PER_COUNT%TYPE,
                       I_per_count_uom     IN     ELC_COMP.PER_COUNT_UOM%TYPE,
                       I_comp_currency     IN     ELC_COMP.COMP_CURRENCY%TYPE,
                       I_insert_update_del IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DEPT_CHARGE_SQL.APPLY_CHARGES';
   L_table        VARCHAR2(30);
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_DEPT_CHRG_DETAIL_1 is
      select 'x'
        from dept_chrg_detail
       where dept          = I_dept
         and from_loc      = I_from_group
         and to_loc        = I_to_group
         and comp_id       = I_comp_id
         for update nowait;

   cursor C_LOCK_DEPT_CHRG_DETAIL_2 is
      select 'x'
        from dept_chrg_detail
       where dept          = I_dept
         and from_loc     in (select from_loc
                                from from_loc_temp)
         and to_loc       in (select to_loc
                                from to_loc_temp)
         and comp_id       = I_comp_id
         for update nowait;

BEGIN

   if I_insert_update_del = 'I' then

      --25-Mar-2010 Tesco HSC/Usha Patil                    Mod: CR275 Begin
      --Included 'X' in the list
      if I_from_group_type in ('S','W','I','E','X') and I_to_group_type in ('S','W','I','E','X') then
      --25-Mar-2010 Tesco HSC/Usha Patil                    Mod: CR275 End
         insert into dept_chrg_head(dept,
                                    from_loc,
                                    to_loc,
                                    from_loc_type,
                                    to_loc_type)
                             select I_dept,
                                    I_from_group,
                                    I_to_group,
                                    DECODE(I_from_group_type, 'I','W', I_from_group_type),
                                    DECODE(I_to_group_type, 'I', 'W', I_to_group_type)
                               from dual
                              where not exists (select 'x'
                                                  from dept_chrg_head
                                                 where dept     = I_dept
                                                   and from_loc = I_from_group
                                                   and to_loc   = I_to_group)
                                and I_from_group != I_to_group;
         ---
         insert into dept_chrg_detail(dept,
                                      from_loc,
                                      to_loc,
                                      from_loc_type,
                                      to_loc_type,
                                      comp_id,
                                      comp_rate,
                                      per_count,
                                      per_count_uom,
                                      up_chrg_group,
                                      comp_currency)
                               select I_dept,
                                      I_from_group,
                                      I_to_group,
                                      DECODE(I_from_group_type, 'I','W', I_from_group_type),
                                      DECODE(I_to_group_type, 'I', 'W', I_to_group_type),
                                      I_comp_id,
                                      I_comp_rate,
                                      I_per_count,
                                      I_per_count_uom,
                                      I_up_chrg_group,
                                      I_comp_currency
                                 from dual
                                where not exists (select 'x'
                                                    from dept_chrg_detail
                                                   where dept     = I_dept
                                                     and from_loc = I_from_group
                                                     and to_loc   = I_to_group
                                                     and comp_id  = I_comp_id)
                                  and I_from_group != I_to_group;

      else
         if I_from_group_type in ('A','R','D','AS') then
            insert into from_loc_temp(from_loc,
                                      from_loc_type)
                               select store,
                                      'S'
                                 from v_store
                                where stockholding_ind    = 'Y'
                                  and ((I_from_group_type   = 'A'
                                        and area          = I_from_group)
                                      or (I_from_group_type = 'R'
                                          and region      = I_from_group)
                                      or (I_from_group_type = 'D'
                                          and district    = I_from_group)
                                      or (I_from_group_type = 'AS'));
         elsif I_from_group_type = 'AW' then
            insert into from_loc_temp(from_loc,
                                      from_loc_type)
                               select wh,
                                      'W'
                                 from v_wh
                                where stockholding_ind = 'Y';
         elsif I_from_group_type = 'AI' then
            insert into from_loc_temp(from_loc,
                                      from_loc_type)
                               select finisher_id,
                                      'W'
                                 from v_internal_finisher;
         elsif I_from_group_type = 'AE' then
            insert into from_loc_temp(from_loc,
                                      from_loc_type)
                               select finisher_id,
                                      'E'
                                 from v_external_finisher;
         elsif I_from_group_type = 'PW' then
            insert into from_loc_temp(from_loc,
                                      from_loc_type)
                               select wh,
                                      'W'
                                 from v_wh
                                where stockholding_ind = 'Y'
                                  and physical_wh      = I_from_group
                                union all
                               select finisher_id,
                                      'W'
                                 from v_internal_finisher
                                where physical_wh = I_from_group;
         elsif I_from_group_type = 'LL' then
            insert into from_loc_temp(from_loc,
                                      from_loc_type)
                               select d.location,
                                      'S'
                                 from loc_list_detail d,
                                      v_store s
                                where d.loc_list = I_from_group
                                  and d.loc_type = 'S'
                                  and s.store = d.location;
            ---
            insert into from_loc_temp(from_loc,
                                      from_loc_type)
                               select w.wh,
                                      'W'
                                 from loc_list_detail d,
                                      v_wh w
                                where d.loc_list         = I_from_group
                                  and d.loc_type         = 'W'
                                  and d.location         = w.wh
                                  and w.stockholding_ind = 'Y';
            ---
            insert into from_loc_temp(from_loc,
                                      from_loc_type)
                               select w.wh,
                                      'W'
                                 from loc_list_detail d,
                                      v_wh w
                                where d.loc_list         = I_from_group
                                  and d.loc_type         = 'W'
                                  and d.location         = w.physical_wh
                                  and w.stockholding_ind = 'Y'
                                  and not exists (select 'x'
                                                    from from_loc_temp t
                                                   where t.from_loc = w.wh);
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
         elsif I_from_group_type = 'T' then
            insert into from_loc_temp(from_loc,
                                      from_loc_type)
                               select store,
                                      'S'
                                 from v_store
                                where stockholding_ind = 'Y'
                                  and transfer_zone = I_from_group;
         elsif I_from_group_type in ('S','W','I','E') then
            insert into from_loc_temp values(I_from_group,
                                             DECODE(I_from_group_type, 'I', 'W', I_from_group_type));
         end if;
         ---
         if I_to_group_type in ('A','R','D','AS') then
            insert into to_loc_temp(to_loc,
                                    to_loc_type)
                             select store,
                                    'S'
                               from v_store
                              where stockholding_ind  = 'Y'
                                and ((I_to_group_type   = 'A'
                                      and area        = I_to_group)
                                    or (I_to_group_type = 'R'
                                        and region    = I_to_group)
                                    or (I_to_group_type = 'D'
                                        and district  = I_to_group)
                                    or (I_to_group_type = 'AS'));
         elsif I_to_group_type = 'AW' then
            insert into to_loc_temp(to_loc,
                                    to_loc_type)
                             select wh,
                                    'W'
                               from v_wh
                              where stockholding_ind = 'Y';
         elsif I_to_group_type = 'AI' then
            insert into to_loc_temp(to_loc,
                                    to_loc_type)
                             select finisher_id,
                                    'W'
                               from v_internal_finisher;
         elsif I_to_group_type = 'AE' then
            insert into to_loc_temp(to_loc,
                                    to_loc_type)
                             select finisher_id,
                                    'E'
                               from v_external_finisher;
         elsif I_to_group_type = 'PW' then
            insert into to_loc_temp(to_loc,
                                    to_loc_type)
                             select wh,
                                    'W'
                               from v_wh
                              where stockholding_ind = 'Y'
                                and physical_wh      = I_to_group
                              union all
                             select finisher_id,
                                    'W'
                               from v_internal_finisher
                              where physical_wh = I_to_group;
         elsif I_to_group_type = 'LL' then
            insert into to_loc_temp(to_loc,
                                    to_loc_type)
                             select d.location,
                                    'S'
                               from loc_list_detail d,
                                    v_store s
                              where d.loc_list = I_to_group
                                and d.loc_type = 'S'
                                and s.store = d.location;
            ---
            insert into to_loc_temp(to_loc,
                                    to_loc_type)
                             select w.wh,
                                    'W'
                               from loc_list_detail d,
                                    v_wh w
                              where d.loc_list         = I_to_group
                                and d.loc_type         = 'W'
                                and d.location         = w.wh
                                and w.stockholding_ind = 'Y';
            ---
            insert into to_loc_temp(to_loc,
                                    to_loc_type)
                             select w.wh,
                                    'W'
                               from loc_list_detail d,
                                    v_wh w
                              where d.loc_list         = I_to_group
                                and d.loc_type         = 'W'
                                and d.location         = w.physical_wh
                                and w.stockholding_ind = 'Y'
                                and not exists (select 'x'
                                                  from to_loc_temp t
                                                 where t.to_loc = w.wh);
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
         elsif I_to_group_type = 'T' then
            insert into to_loc_temp(to_loc,
                                    to_loc_type)
                             select store,
                                    'S'
                               from v_store
                              where stockholding_ind = 'Y'
                                and transfer_zone = I_to_group;
         elsif I_to_group_type in ('S','W','I','E') then
            insert into to_loc_temp values(I_to_group,
                                           DECODE(I_to_group_type, 'I', 'W', I_to_group_type));
         end if;
         ---
         insert into dept_chrg_head(dept,
                                    from_loc,
                                    to_loc,
                                    from_loc_type,
                                    to_loc_type)
                             select I_dept,
                                    f.from_loc,
                                    t.to_loc,
                                    f.from_loc_type,
                                    t.to_loc_type
                               from from_loc_temp f,
                                    to_loc_temp t
                              where not exists (select 'x'
                                                  from dept_chrg_head
                                                 where dept     = I_dept
                                                   and from_loc = f.from_loc
                                                   and to_loc   = t.to_loc)
                                and f.from_loc != t.to_loc;
         ---
         insert into dept_chrg_detail(dept,
                                      from_loc,
                                      to_loc,
                                      comp_id,
                                      from_loc_type,
                                      to_loc_type,
                                      comp_rate,
                                      per_count,
                                      per_count_uom,
                                      up_chrg_group,
                                      comp_currency)
                               select I_dept,
                                      f.from_loc,
                                      t.to_loc,
                                      I_comp_id,
                                      f.from_loc_type,
                                      t.to_loc_type,
                                      I_comp_rate,
                                      I_per_count,
                                      I_per_count_uom,
                                      I_up_chrg_group,
                                      I_comp_currency
                                 from from_loc_temp f,
                                      to_loc_temp t
                                where not exists (select 'x'
                                                    from dept_chrg_detail
                                                   where dept     = I_dept
                                                     and from_loc = f.from_loc
                                                     and to_loc   = t.to_loc
                                                     and comp_id  = I_comp_id)
                                  and f.from_loc != t.to_loc;
      end if;
   elsif I_insert_update_del = 'U' then  -- I_insert_update_del = 'U' for Update
      --25-Mar-2010 Tesco HSC/Usha Patil                    Mod: CR275 Begin
      if I_from_group_type in ('S','W','I','E','X') and I_to_group_type in ('S','W','I','E','X') then
      --25-Mar-2010 Tesco HSC/Usha Patil                    Mod: CR275 End
         L_table := 'DEPT_CHRG_DETAIL';
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_DEPT_CHRG_DETAIL_1','DEPT_CHRG_DETAIL',NULL);
         open C_LOCK_DEPT_CHRG_DETAIL_1;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEPT_CHRG_DETAIL_1','DEPT_CHRG_DETAIL',NULL);
         close C_LOCK_DEPT_CHRG_DETAIL_1;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'DEPT_CHRG_DETAIL',NULL);
         update dept_chrg_detail
            set comp_rate     = I_comp_rate,
                per_count     = I_per_count,
                per_count_uom = I_per_count_uom,
                up_chrg_group = I_up_chrg_group,
                comp_currency = I_comp_currency
          where dept          = I_dept
            and from_loc      = I_from_group
            and to_loc        = I_to_group
            and comp_id       = I_comp_id;
      else
         if INSERT_TEMP(O_error_message,
                        I_dept,
                        I_from_group_type,
                        I_from_group,
                        I_to_group_type,
                        I_to_group) = FALSE then
            return FALSE;
         end if;
         ---
         L_table := 'DEPT_CHRG_DETAIL';
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_DEPT_CHRG_DETAIL_2','DEPT_CHRG_DETAIL',NULL);
         open C_LOCK_DEPT_CHRG_DETAIL_2;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEPT_CHRG_DETAIL_2','DEPT_CHRG_DETAIL',NULL);
         close C_LOCK_DEPT_CHRG_DETAIL_2;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'DEPT_CHRG_DETAIL',NULL);
         update dept_chrg_detail
            set comp_rate     = I_comp_rate,
                per_count     = I_per_count,
                per_count_uom = I_per_count_uom,
                up_chrg_group = I_up_chrg_group,
                comp_currency = I_comp_currency
          where dept          = I_dept
            and from_loc     in (select from_loc
                                   from from_loc_temp)
            and to_loc       in (select to_loc
                                   from to_loc_temp)
            and comp_id       = I_comp_id;
      end if;
   else  -- I_insert_update_del = 'D' for Delete Comp
      --25-Mar-2010 Tesco HSC/Usha Patil                    Mod: CR275 Begin
      if I_from_group_type in ('S','W','I','E','X') and I_to_group_type in ('S','W','I','E','X') then
      --25-Mar-2010 Tesco HSC/Usha Patil                    Mod: CR275 End
         L_table := 'DEPT_CHRG_DETAIL';
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_DEPT_CHRG_DETAIL_1','DEPT_CHRG_DETAIL',NULL);
         open C_LOCK_DEPT_CHRG_DETAIL_1;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEPT_CHRG_DETAIL_1','DEPT_CHRG_DETAIL',NULL);
         close C_LOCK_DEPT_CHRG_DETAIL_1;
         ---
         SQL_LIB.SET_MARK('DELETE',NULL,'DEPT_CHRG_DETAIL',NULL);
         delete from dept_chrg_detail
               where dept     = I_dept
                 and from_loc = I_from_group
                 and to_loc   = I_to_group
                 and comp_id  = I_comp_id;
      else
         if INSERT_TEMP(O_error_message,
                        I_dept,
                        I_from_group_type,
                        I_from_group,
                        I_to_group_type,
                        I_to_group) = FALSE then
            return FALSE;
         end if;
         ---
         L_table := 'DEPT_CHRG_DETAIL';
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_DEPT_CHRG_DETAIL_2','DEPT_CHRG_DETAIL',NULL);
         open C_LOCK_DEPT_CHRG_DETAIL_2;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEPT_CHRG_DETAIL_2','DEPT_CHRG_DETAIL',NULL);
         close C_LOCK_DEPT_CHRG_DETAIL_2;
         ---
         SQL_LIB.SET_MARK('DELETE',NULL,'DEPT_CHRG_DETAIL',NULL);
         delete from dept_chrg_detail
          where dept      = I_dept
            and from_loc in (select from_loc
                               from from_loc_temp)
            and to_loc   in (select to_loc
                               from to_loc_temp)
            and comp_id   = I_comp_id;
      end if;
      ---
      -- Since deleted comps, need to delete any header records that
      -- no longer have component detail records
      ---
      if DELETE_HEADER(O_error_message,
                       I_dept) = FALSE then
         return FALSE;
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
                                             to_char(I_dept),
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
                     I_dept            IN     DEPS.DEPT%TYPE,
                     I_from_group_type IN     CODE_DETAIL.CODE%TYPE,
                     I_from_group      IN     STORE.STORE%TYPE,
                     I_to_group_type   IN     CODE_DETAIL.CODE%TYPE,
                     I_to_group        IN     STORE.STORE%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DEPT_CHARGE_SQL.DELETE_LOCS';
   L_table        VARCHAR2(30);
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_DEPT_CHRG_DETAIL_1 is
      select 'x'
        from dept_chrg_detail
       where dept     = I_dept
         and from_loc = I_from_group
         and to_loc   = I_to_group
         for update nowait;

   cursor C_LOCK_DEPT_CHRG_HEAD_1 is
      select 'x'
        from dept_chrg_head
       where dept     = I_dept
         and from_loc = I_from_group
         and to_loc   = I_to_group
         for update nowait;

   cursor C_LOCK_DEPT_CHRG_DETAIL_2 is
      select 'x'
        from dept_chrg_detail
       where dept      = I_dept
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc   in (select to_loc
                            from to_loc_temp)
         for update nowait;

   cursor C_LOCK_DEPT_CHRG_HEAD_2 is
      select 'x'
        from dept_chrg_head
       where dept      = I_dept
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc   in (select to_loc
                            from to_loc_temp)
         for update nowait;

BEGIN
   --25-Mar-2010 Tesco HSC/Usha Patil                    Mod: CR275 Begin
   if I_from_group_type in ('S','W','X') and I_to_group_type in ('S','W','X') then
   --25-Mar-2010 Tesco HSC/Usha Patil                    Mod: CR275 End
      L_table := 'DEPT_CHRG_DETAIL';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_DEPT_CHRG_DETAIL_1','DEPT_CHRG_DETAIL',NULL);
      open C_LOCK_DEPT_CHRG_DETAIL_1;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEPT_CHRG_DETAIL_1','DEPT_CHRG_DETAIL',NULL);
      close C_LOCK_DEPT_CHRG_DETAIL_1;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'DEPT_CHRG_DETAIL',NULL);
      delete from dept_chrg_detail
       where dept     = I_dept
         and from_loc = I_from_group
         and to_loc   = I_to_group;
      ---
      L_table := 'DEPT_CHRG_HEAD';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_DEPT_CHRG_HEAD_1','DEPT_CHRG_HEAD',NULL);
      open C_LOCK_DEPT_CHRG_HEAD_1;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEPT_CHRG_HEAD_1','DEPT_CHRG_HEAD',NULL);
      close C_LOCK_DEPT_CHRG_HEAD_1;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'DEPT_CHRG_HEAD',NULL);
      delete from dept_chrg_head
       where dept     = I_dept
         and from_loc = I_from_group
         and to_loc   = I_to_group;
   else
      if INSERT_TEMP(O_error_message,
                     I_dept,
                     I_from_group_type,
                     I_from_group,
                     I_to_group_type,
                     I_to_group) = FALSE then
         return FALSE;
      end if;
      ---
      L_table := 'DEPT_CHRG_DETAIL';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_DEPT_CHRG_DETAIL_2','DEPT_CHRG_DETAIL',NULL);
      open C_LOCK_DEPT_CHRG_DETAIL_2;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEPT_CHRG_DETAIL_2','DEPT_CHRG_DETAIL',NULL);
      close C_LOCK_DEPT_CHRG_DETAIL_2;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'DEPT_CHRG_DETAIL',NULL);
      delete from dept_chrg_detail
       where dept      = I_dept
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc   in (select to_loc
                            from to_loc_temp);
      ---
      L_table := 'DEPT_CHRG_HEAD';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_DEPT_CHRG_HEAD_2','DEPT_CHRG_HEAD',NULL);
      open C_LOCK_DEPT_CHRG_HEAD_2;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEPT_CHRG_HEAD_2','DEPT_CHRG_HEAD',NULL);
      close C_LOCK_DEPT_CHRG_HEAD_2;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'DEPT_CHRG_HEAD',NULL);
      delete from dept_chrg_head
       where dept      = I_dept
         and from_loc in (select from_loc
                            from from_loc_temp)
         and to_loc   in (select to_loc
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
                                             'I_dept',
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
FUNCTION CHARGES_EXIST(O_error_message IN OUT VARCHAR2,
                       O_exists        IN OUT BOOLEAN,
                       I_dept          IN     DEPS.DEPT%TYPE,
                       I_from_loc      IN     ORDLOC.LOCATION%TYPE,
                       I_to_loc        IN     ORDLOC.LOCATION%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60)  := 'DEPT_CHARGES_SQL.CHARGES_EXIST';
   L_exists    VARCHAR2(1)   := 'N';

   cursor C_CHARGES_EXIST is
      select 'Y'
        from dept_chrg_detail
       where dept     = I_dept
         and from_loc = NVL(I_from_loc, from_loc)
         and to_loc   = NVL(I_to_loc,   to_loc);

BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHARGES_EXIST','DEPT_CHRG_DETAIL','Item: '||I_dept);
   open C_CHARGES_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_CHARGES_EXIST','DEPT_CHRG_DETAIL','Item: '||I_dept);
   fetch C_CHARGES_EXIST into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHARGES_EXIST','DEPT_CHRG_DETAIL','Item: '||I_dept);
   close C_CHARGES_EXIST;
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
END CHARGES_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION CHARGES_EXIST(O_error_message IN OUT VARCHAR2,
                       O_exists        IN OUT BOOLEAN,
                       I_dept          IN     DEPS.DEPT%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60)  := 'DEPT_CHARGES_SQL.CHARGES_EXIST';

BEGIN
   if CHARGES_EXIST(O_error_message,
                    O_exists,
                    I_dept,
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
FUNCTION CHECK_HEADER_NO_DETAILS(O_error_message IN OUT  VARCHAR2,
                                 O_exists        IN OUT  BOOLEAN,
                                 I_dept          IN      DEPS.DEPT%TYPE)
RETURN BOOLEAN IS

   L_exists      VARCHAR2(1) := 'N';

   cursor C_CHECK_FOR_DETAILS is
      select 'Y'
        from dept_chrg_head h
       where h.dept = I_dept
         and not exists (select 'x'
                           from dept_chrg_detail d
                          where d.dept     = h.dept
                            and d.from_loc = h.from_loc
                            and d.to_loc   = h.to_loc);

BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_FOR_DETAILS','DEPT_CHRG_HEAD, DEPT_CHRG_DETAIL',NULL);
   open C_CHECK_FOR_DETAILS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_FOR_DETAILS','DEPT_CHRG_HEAD, DEPT_CHRG_DETAIL',NULL);
   fetch C_CHECK_FOR_DETAILS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_FOR_DETAILS','DEPT_CHRG_HEAD, DEPT_CHRG_DETAIL',NULL);
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
                                            'DEPT_CHARGE_SQL.CHECK_HEADER_NO_DETAILS',
                                             to_char(SQLCODE));
   return FALSE;
END CHECK_HEADER_NO_DETAILS;
---------------------------------------------------------------------------------------------
FUNCTION DELETE_HEADER(O_error_message IN OUT  VARCHAR2,
                       I_dept          IN      DEPS.DEPT%TYPE)
RETURN BOOLEAN IS

   L_table        VARCHAR2(30) := 'DEPT_CHRG_HEAD';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_DEPT_HEAD is
      select 'x'
        from dept_chrg_head h
       where h.dept = I_dept
         and not exists (select 'x'
                           from dept_chrg_detail d
                          where d.dept     = h.dept
                            and d.from_loc = h.from_loc
                            and d.to_loc   = h.to_loc)
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEPT_HEAD','DEPT_CHRG_HEAD',NULL);
   open C_LOCK_DEPT_HEAD;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEPT_HEAD','DEPT_CHRG_HEAD',NULL);
   close C_LOCK_DEPT_HEAD;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEPT_CHRG_HEAD', NULL);
   delete from dept_chrg_head h
         where h.dept = I_dept
           and not exists (select 'x'
                             from dept_chrg_detail d
                            where d.dept     = h.dept
                              and d.from_loc = h.from_loc
                              and d.to_loc   = h.to_loc);
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             to_char(I_dept),
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEPT_CHARGE_SQL.DELETE_HEADER',
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_HEADER;
-----------------------------------------------------------------------------------------
END DEPT_CHARGE_SQL;
/

