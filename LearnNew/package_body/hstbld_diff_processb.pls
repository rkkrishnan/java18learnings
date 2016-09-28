CREATE OR REPLACE PACKAGE BODY HSTBLD_DIFF_PROCESS AS
--------------------------------------------------------------------------
FUNCTION DIFF_PROCESS(O_return_code   IN OUT   VARCHAR2,
                      O_error_msg     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      I_vdate         IN       ITEM_LOC_HIST.EOW_DATE%TYPE,
                      I_mode          IN       VARCHAR2)
RETURN BOOLEAN IS

   L_program     VARCHAR2(50) := 'HSTBLD_DIFF_PROCESS.DIFF_PROCESS';
   L_table       VARCHAR2(50) := 'ITEM_DIFF_LOC_HIST';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);

   cursor C_ITEM_DIFF_LOC_HIST_MTH is
      select 'x'
        from item_diff_loc_hist_mth idlh,
             (select im.item_parent,
                     nvl(im.diff_1, ' ') as diff_1,
                     nvl(im.diff_2, ' ') as diff_2,
                     ilh.loc,
                     to_char(ilh.eom_date, 'YYYYMMDD') as eom_date,
                     ilh.month_454,
                     ilh.year_454,
                     ilh.sales_type
                from item_loc_hist_mth ilh,
                     item_loc il,
                     item_master im
               where im.item_parent is not NULL
                 and (im.diff_1 is not NULL
                  or im.diff_2 is not NULL)
                 and ilh.item = im.item
                 and ilh.item = il.item
                 and ilh.loc = il.loc
                 and ilh.sales_type in ('P', 'R')
                 and ilh.eom_date = I_vdate) s
       where idlh.item = s.item_parent
         and (idlh.diff_id = s.diff_1
          or idlh.diff_id = s.diff_2)
         and idlh.location = s.loc
         and idlh.eom_date = to_date(s.eom_date, 'YYYYMMDD')
         and idlh.sales_type = s.sales_type
         for update nowait;

   cursor C_ITEM_PARENTLOC_HIST_MTH is
      select  'x'
        from item_parentloc_hist_mth iplh,
             (select im.item_parent,
                     ilh.loc,
                     to_char(ilh.eom_date, 'YYYYMMDD') as eom_date,
                     ilh.month_454,
                     ilh.year_454,
                     ilh.sales_type
                from item_loc_hist_mth ilh,
                     item_loc il,
                     item_master im
               where im.item_parent is not NULL
                 and ilh.item = im.item
                 and ilh.item = il.item
                 and ilh.loc = il.loc
                 and ilh.sales_type in ('P', 'R')
                 and ilh.eom_date = I_vdate) s
       where iplh.item = s.item_parent
         and iplh.location = s.loc
         and iplh.eom_date = to_date(s.eom_date, 'YYYYMMDD')
         and iplh.sales_type = s.sales_type
         for update nowait;

BEGIN
   if I_mode is NULL then
      O_error_msg:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                       'I_mode',
                                       L_program,
                                       NULL);
      return FALSE;
   end if;
   if I_mode != 'M' then
      /* Weekly Update */
      merge into item_diff_loc_hist idlh
         using (select im.item_parent,
                       nvl(im.diff_1, ' ') as diff_id,
                       ilh.loc,
                       to_char(ilh.eow_date, 'YYYYMMDD') as eow_date,
                       ilh.week_454,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type,
                       sum(nvl(ilh.value, 0)) as value,
                       sum(nvl(ilh.stock, 0)) as stock,
                       sum(nvl(ilh.sales_issues, 0)) as sales
                  from item_loc_hist ilh,
                       item_loc il,
                       item_master im
                 where im.item_parent is not NULL
                   and im.diff_1 is not NULL
                   and ilh.item = im.item
                   and ilh.item = il.item
                   and ilh.loc = il.loc
                   and ilh.sales_type in ('P', 'R', 'C')
                   and ilh.eow_date = I_vdate
              group by im.item_parent,
                       im.diff_1,
                       ilh.loc,
                       ilh.eow_date,
                       ilh.week_454,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type
         union
                select im.item_parent,
                       nvl(im.diff_2, ' ') as diff_id,
                       ilh.loc,
                       to_char(ilh.eow_date, 'YYYYMMDD') as eow_date,
                       ilh.week_454,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type,
                       sum(nvl(ilh.value, 0)) as value,
                       sum(nvl(ilh.stock, 0)) as stock,
                       sum(nvl(ilh.sales_issues, 0)) as sales
                  from item_loc_hist ilh,
                       item_loc il,
                       item_master im
                 where im.item_parent is not NULL
                   and im.diff_2 is not NULL
                   and ilh.item = im.item
                   and ilh.item = il.item
                   and ilh.loc = il.loc
                   and ilh.sales_type in ('P', 'R', 'C')
                   and ilh.eow_date = I_vdate
              group by im.item_parent,
                       im.diff_2,
                       ilh.loc,
                       ilh.eow_date,
                       ilh.week_454,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type) s
            on (idlh.item = s.item_parent
           and idlh.diff_id = s.diff_id
           and idlh.location = s.loc
           and idlh.eow_date = to_date(s.eow_date, 'YYYYMMDD')
           and idlh.sales_type = s.sales_type)
      when matched then update set idlh.value = nvl(idlh.value, 0) + s.value,
                                   idlh.stock = nvl(idlh.stock, 0) + s.stock,
                                   idlh.sales = nvl(idlh.sales, 0) + s.sales
      when not matched then insert (item,
                                    diff_id,
                                    location,
                                    loc_type,
                                    eow_date,
                                    week_454,
                                    month_454,
                                    year_454,
                                    sales_type,
                                    value,
                                    stock,
                                    sales)
                            VALUES (s.item_parent,
                                    s.diff_id,
                                    s.loc,
                                    'S',
                                    to_date(s.eow_date, 'YYYYMMDD'),
                                    s.week_454,
                                    s.month_454,
                                    s.year_454,
                                    s.sales_type,
                                    s.value,
                                    s.stock,
                                    s.sales);
      merge into item_parent_loc_hist iplh
         using (select im.item_parent,
                       ilh.loc,
                       to_char(ilh.eow_date, 'YYYYMMDD') as eow_date,
                       ilh.week_454,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type,
                       sum(nvl(ilh.value, 0)) as value,
                       sum(nvl(ilh.stock, 0)) as stock,
                       sum(nvl(ilh.sales_issues, 0)) as sales
                  from item_loc_hist ilh,
                       item_loc il,
                       item_master im
                 where im.item_parent is not NULL
                   and ilh.item = im.item
                   and ilh.item = il.item
                   and ilh.loc = il.loc
                   and ilh.sales_type in ('P', 'R', 'C')
                   and ilh.eow_date = I_vdate
              group by im.item_parent,
                       ilh.loc,
                       ilh.eow_date,
                       ilh.week_454,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type) s
            on (iplh.item = s.item_parent
           and iplh.location = s.loc
           and iplh.eow_date = to_date(s.eow_date, 'YYYYMMDD')
           and iplh.sales_type = s.sales_type)
      when matched then update set iplh.value = nvl(iplh.value, 0) + s.value,
                                   iplh.stock = nvl(iplh.stock, 0) + s.stock,
                                   iplh.sales = nvl(iplh.sales, 0) + s.sales
      when not matched then insert (item,
                                    location,
                                    loc_type,
                                    eow_date,
                                    week_454,
                                    month_454,
                                    year_454,
                                    sales_type,
                                    value,
                                    stock,
                                    sales)
                            values (s.item_parent,
                                    s.loc,
                                    'S',
                                    to_date(s.eow_date, 'YYYYMMDD'),
                                    s.week_454,
                                    s.month_454,
                                    s.year_454,
                                    s.sales_type,
                                    s.value,
                                    s.stock,
                                    s.sales);
   elsif I_mode = 'M' then

      L_table := 'ITEM_DIFF_LOC_HIST_MTH';

      open C_ITEM_DIFF_LOC_HIST_MTH;
      close C_ITEM_DIFF_LOC_HIST_MTH;

      /* Monthly Update */
      merge into item_diff_loc_hist_mth idlh
         using (select im.item_parent,
                       nvl(im.diff_1, ' ') as diff_id,
                       ilh.loc,
                       to_char(ilh.eom_date, 'YYYYMMDD') as eom_date,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type,
                       sum(nvl(ilh.value, 0)) as value,
                       sum(nvl(ilh.stock, 0)) as stock
                  from item_loc_hist_mth ilh,
                       item_loc il,
                       item_master im
                 where im.item_parent is not NULL
                   and im.diff_1 is not NULL
                   and ilh.item = im.item
                   and ilh.item = il.item
                   and ilh.loc = il.loc
                   and ilh.sales_type in ('P', 'R')
                   and ilh.eom_date = I_vdate
              group by im.item_parent,
                       im.diff_1,
                       ilh.loc,
                       ilh.eom_date,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type
         union
                select im.item_parent,
                       nvl(im.diff_2, ' ') as diff_id,
                       ilh.loc,
                       to_char(ilh.eom_date, 'YYYYMMDD') as eom_date,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type,
                       sum(nvl(ilh.value, 0)) as value,
                       sum(nvl(ilh.stock, 0)) as stock
                  from item_loc_hist_mth ilh,
                       item_loc il,
                       item_master im
                 where im.item_parent is not NULL
                   and im.diff_2 is not NULL
                   and ilh.item = im.item
                   and ilh.item = il.item
                   and ilh.loc = il.loc
                   and ilh.sales_type in ('P', 'R')
                   and ilh.eom_date = I_vdate
              group by im.item_parent,
                       im.diff_2,
                       ilh.loc,
                       ilh.eom_date,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type) s
            on (idlh.item = s.item_parent
           and idlh.diff_id = s.diff_id
           and idlh.location = s.loc
           and idlh.eom_date = to_date(s.eom_date, 'YYYYMMDD')
           and idlh.sales_type = s.sales_type)
      when matched then update set idlh.value = nvl(idlh.value, 0) + s.value,
                                   idlh.stock = nvl(idlh.stock, 0) + s.stock
      when not matched then insert (item,
                                  diff_id,
                                  location,
                                  loc_type,
                                  eom_date,
                                  month_454,
                                  year_454,
                                  sales_type,
                                  value,
                                  stock)
                          values (s.item_parent,
                                  s.diff_id,
                                  s.loc,
                                  'S',
                                  to_date(s.eom_date, 'YYYYMMDD'),
                                  s.month_454,
                                  s.year_454,
                                  s.sales_type,
                                  s.value,
                                  s.stock);

    L_table := 'ITEM_PARENT_LOC_HIST_MTH';

    open C_ITEM_PARENTLOC_HIST_MTH;
    close C_ITEM_PARENTLOC_HIST_MTH;

    merge into item_parentloc_hist_mth iplh
         using (select im.item_parent,
                       ilh.loc,
                       to_char(ilh.eom_date, 'YYYYMMDD') as eom_date,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type,
                       sum(nvl(ilh.value, 0)) as value,
                       sum(nvl(ilh.stock, 0)) as stock
                  from item_loc_hist_mth ilh,
                       item_loc il,
                       item_master im
                 where im.item_parent is not NULL
                   and ilh.item = im.item
                   and ilh.item = il.item
                   and ilh.loc = il.loc
                   and ilh.sales_type in ('P', 'R')
                   and ilh.eom_date = I_vdate
              group by im.item_parent,
                       ilh.loc,
                       ilh.eom_date,
                       ilh.month_454,
                       ilh.year_454,
                       ilh.sales_type) s
            ON (iplh.item = s.item_parent
           AND iplh.location = s.loc
           AND iplh.eom_date = to_date(s.eom_date, 'YYYYMMDD')
           AND iplh.sales_type = s.sales_type)
    when matched then update set iplh.value = nvl(iplh.value, 0) + s.value,
                                 iplh.stock = nvl(iplh.stock, 0) + s.stock
    when not matched then insert (item,
                                  location,
                                  loc_type,
                                  eom_date,
                                  month_454,
                                  year_454,
                                  sales_type,
                                  value,
                                  stock)
                           values (s.item_parent,
                                  s.loc,
                                  'S',
                                  to_date(s.eom_date, 'YYYYMMDD'),
                                  s.month_454,
                                  s.year_454,
                                  s.sales_type,
                                  s.value,
                                  s.stock);
   end if;

         return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_msg := SQL_LIB.CREATE_MSG('RECORD_LOCKED',
                                        L_table ,
                                        TO_CHAR(I_vdate),
                                        'NULL');
      return FALSE;

   when OTHERS then
      O_error_msg := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                        SQLERRM,
                                        L_program,
                                        TO_CHAR(SQLCODE));
      return FALSE;


END DIFF_PROCESS;
--------------------------------------------------------------------------
END HSTBLD_DIFF_PROCESS;
/

