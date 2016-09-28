CREATE OR REPLACE PACKAGE BODY ITEM_LOC_HIST_SQL IS
----------------------------------------------------------------------
FUNCTION EOW_SALES_ISSUES(O_error_message       IN OUT VARCHAR2,
                          O_eow_sales_issues1   IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues2   IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues3   IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues4   IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues5   IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues6   IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues7   IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues8   IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues9   IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues10  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues11  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues12  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues13  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues14  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues15  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues16  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues17  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues18  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues19  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues20  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues21  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues22  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues23  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues24  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues25  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues26  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues27  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues28  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues29  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues30  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues31  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues32  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues33  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues34  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues35  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues36  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues37  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues38  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues39  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues40  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues41  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues42  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues43  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues44  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues45  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues46  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues47  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues48  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues49  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues50  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues51  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues52  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues53  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_eow_sales_issues54  IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          O_sum_sales_issues    IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                          I_item                IN     ITEM_LOC_HIST.ITEM%TYPE,
                          I_loc                 IN     ITEM_LOC_HIST.LOC%TYPE,
                          I_loc_type            IN     ITEM_LOC_HIST.LOC_TYPE%TYPE,
                          I_from_date           IN     ITEM_LOC_HIST.EOW_DATE%TYPE,
                          I_back_to_date        IN     ITEM_LOC_HIST.EOW_DATE%TYPE,
                          I_sales_type          IN     ITEM_LOC_HIST.SALES_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program     VARCHAR2(255) := 'ITEM_LOC_HIST_SQL.EOW_SALES_ISSUES';
   L_no_weeks    NUMBER;
   L_loop_date   DATE;
   L_counter     NUMBER;

   cursor C_EOW_SALES_ISSUES is
   select ilh.eow_date eow_date, sum(sales_issues) sales_issues
     from item_loc_hist ilh
    where ilh.loc_type  = I_loc_type /* Stores or Warehouses */
      and ilh.loc       = I_loc
      and ilh.item in (select im.item
                         from item_master im
                        where (   im.item             = I_item
                               or im.item_parent      = I_item
                               or im.item_grandparent = I_item)
                          and im.item_level = im.tran_level
                          and im.status     = 'A' )
      and ilh.eow_date  <= I_from_date
      and ilh.eow_date  >= I_back_to_date
      and ilh.sales_type = nvl(I_sales_type, ilh.sales_type)
    group by ilh.eow_date
    order by eow_date DESC;


BEGIN
   O_eow_sales_issues1   := 0;
   O_eow_sales_issues2   := 0;
   O_eow_sales_issues3   := 0;
   O_eow_sales_issues4   := 0;
   O_eow_sales_issues5   := 0;
   O_eow_sales_issues6   := 0;
   O_eow_sales_issues7   := 0;
   O_eow_sales_issues8   := 0;
   O_eow_sales_issues9   := 0;
   O_eow_sales_issues10  := 0;
   O_eow_sales_issues11  := 0;
   O_eow_sales_issues12  := 0;
   O_eow_sales_issues13  := 0;
   O_eow_sales_issues14  := 0;
   O_eow_sales_issues15  := 0;
   O_eow_sales_issues16  := 0;
   O_eow_sales_issues17  := 0;
   O_eow_sales_issues18  := 0;
   O_eow_sales_issues19  := 0;
   O_eow_sales_issues20  := 0;
   O_eow_sales_issues21  := 0;
   O_eow_sales_issues22  := 0;
   O_eow_sales_issues23  := 0;
   O_eow_sales_issues24  := 0;
   O_eow_sales_issues25  := 0;
   O_eow_sales_issues26  := 0;
   O_eow_sales_issues27  := 0;
   O_eow_sales_issues28  := 0;
   O_eow_sales_issues29  := 0;
   O_eow_sales_issues30  := 0;
   O_eow_sales_issues31  := 0;
   O_eow_sales_issues32  := 0;
   O_eow_sales_issues33  := 0;
   O_eow_sales_issues34  := 0;
   O_eow_sales_issues35  := 0;
   O_eow_sales_issues36  := 0;
   O_eow_sales_issues37  := 0;
   O_eow_sales_issues38  := 0;
   O_eow_sales_issues39  := 0;
   O_eow_sales_issues40  := 0;
   O_eow_sales_issues41  := 0;
   O_eow_sales_issues42  := 0;
   O_eow_sales_issues43  := 0;
   O_eow_sales_issues44  := 0;
   O_eow_sales_issues45  := 0;
   O_eow_sales_issues46  := 0;
   O_eow_sales_issues47  := 0;
   O_eow_sales_issues48  := 0;
   O_eow_sales_issues49  := 0;
   O_eow_sales_issues50  := 0;
   O_eow_sales_issues51  := 0;
   O_eow_sales_issues52  := 0;
   O_eow_sales_issues53  := 0;
   O_eow_sales_issues54  := 0;
   O_sum_sales_issues    := 0;

   L_no_weeks := (I_from_date - I_back_to_date)/7 +1;
   ---
   if L_no_weeks > 54 then
      O_error_message := sql_lib.create_msg('DATE_MAX_DATE_RANGE',
                                            'I_from_date',
                                            'I_back_to_date');
      return FALSE;
   end if;
   ---
   L_loop_date := I_from_date;
   L_counter   := 1;
   ---
   SQL_LIB.SET_MARK('OPEN','C_EOW_SALES_ISSUES','ITEM_LOC_HIST',NULL);
   for c_rec in C_EOW_SALES_ISSUES LOOP
      while L_counter <= L_no_weeks LOOP
         if L_loop_date = C_rec.eow_date then
            ---
            if L_counter = 1 then
               O_eow_sales_issues1 := c_rec.sales_issues;
            elsif L_counter = 2 then
               O_eow_sales_issues2 := c_rec.sales_issues;
            elsif L_counter = 3 then
               O_eow_sales_issues3 := c_rec.sales_issues;
            elsif L_counter = 4 then
               O_eow_sales_issues4 := c_rec.sales_issues;
            elsif L_counter = 5 then
               O_eow_sales_issues5 := c_rec.sales_issues;
            elsif L_counter = 6 then
               O_eow_sales_issues6 := c_rec.sales_issues;
            elsif L_counter = 7 then
               O_eow_sales_issues7 := c_rec.sales_issues;
            elsif L_counter = 8 then
               O_eow_sales_issues8 := c_rec.sales_issues;
            elsif L_counter = 9 then
               O_eow_sales_issues9 := c_rec.sales_issues;
            elsif L_counter = 10 then
               O_eow_sales_issues10 := c_rec.sales_issues;
            elsif L_counter = 11 then
               O_eow_sales_issues11 := c_rec.sales_issues;
            elsif L_counter = 12 then
               O_eow_sales_issues12 := c_rec.sales_issues;
            elsif L_counter = 13 then
               O_eow_sales_issues13 := c_rec.sales_issues;
            elsif L_counter = 14 then
               O_eow_sales_issues14 := c_rec.sales_issues;
            elsif L_counter = 15 then
               O_eow_sales_issues15 := c_rec.sales_issues;
            elsif L_counter = 16 then
               O_eow_sales_issues16 := c_rec.sales_issues;
            elsif L_counter = 17 then
               O_eow_sales_issues17 := c_rec.sales_issues;
            elsif L_counter = 18 then
               O_eow_sales_issues18 := c_rec.sales_issues;
            elsif L_counter = 19 then
               O_eow_sales_issues19 := c_rec.sales_issues;
            elsif L_counter = 20 then
               O_eow_sales_issues20 := c_rec.sales_issues;
            elsif L_counter = 21 then
               O_eow_sales_issues21 := c_rec.sales_issues;
            elsif L_counter = 22 then
               O_eow_sales_issues22 := c_rec.sales_issues;
            elsif L_counter = 23 then
               O_eow_sales_issues23 := c_rec.sales_issues;
            elsif L_counter = 24 then
               O_eow_sales_issues24 := c_rec.sales_issues;
            elsif L_counter = 25 then
               O_eow_sales_issues25 := c_rec.sales_issues;
            elsif L_counter = 26 then
               O_eow_sales_issues26 := c_rec.sales_issues;
            elsif L_counter = 27 then
               O_eow_sales_issues27 := c_rec.sales_issues;
            elsif L_counter = 28 then
               O_eow_sales_issues28 := c_rec.sales_issues;
            elsif L_counter = 29 then
               O_eow_sales_issues29 := c_rec.sales_issues;
            elsif L_counter = 30 then
               O_eow_sales_issues30 := c_rec.sales_issues;
            elsif L_counter = 31 then
               O_eow_sales_issues31 := c_rec.sales_issues;
            elsif L_counter = 32 then
               O_eow_sales_issues32 := c_rec.sales_issues;
            elsif L_counter = 33 then
               O_eow_sales_issues33 := c_rec.sales_issues;
            elsif L_counter = 34 then
               O_eow_sales_issues34 := c_rec.sales_issues;
            elsif L_counter = 35 then
               O_eow_sales_issues35 := c_rec.sales_issues;
            elsif L_counter = 36 then
               O_eow_sales_issues36 := c_rec.sales_issues;
            elsif L_counter = 37 then
               O_eow_sales_issues37 := c_rec.sales_issues;
            elsif L_counter = 38 then
               O_eow_sales_issues38 := c_rec.sales_issues;
            elsif L_counter = 39 then
               O_eow_sales_issues39 := c_rec.sales_issues;
            elsif L_counter = 40 then
               O_eow_sales_issues40 := c_rec.sales_issues;
            elsif L_counter = 41 then
               O_eow_sales_issues41 := c_rec.sales_issues;
            elsif L_counter = 42 then
               O_eow_sales_issues42 := c_rec.sales_issues;
            elsif L_counter = 43 then
               O_eow_sales_issues43 := c_rec.sales_issues;
            elsif L_counter = 44 then
               O_eow_sales_issues44 := c_rec.sales_issues;
            elsif L_counter = 45 then
               O_eow_sales_issues45 := c_rec.sales_issues;
            elsif L_counter = 46 then
               O_eow_sales_issues46 := c_rec.sales_issues;
            elsif L_counter = 47 then
               O_eow_sales_issues47 := c_rec.sales_issues;
            elsif L_counter = 48 then
               O_eow_sales_issues48 := c_rec.sales_issues;
            elsif L_counter = 49 then
               O_eow_sales_issues49 := c_rec.sales_issues;
            elsif L_counter = 50 then
               O_eow_sales_issues50 := c_rec.sales_issues;
            elsif L_counter = 51 then
               O_eow_sales_issues51 := c_rec.sales_issues;
            elsif L_counter = 52 then
               O_eow_sales_issues52 := c_rec.sales_issues;
            elsif L_counter = 53 then
               O_eow_sales_issues53 := c_rec.sales_issues;
            elsif L_counter = 54 then
               O_eow_sales_issues54 := c_rec.sales_issues;
            end if;
            O_sum_sales_issues := O_sum_sales_issues + c_rec.sales_issues;
            L_counter          := L_counter   + 1;
            L_loop_date        := L_loop_date - 7;
            EXIT;
         end if;
         L_counter          := L_counter   + 1;
         L_loop_date        := L_loop_date - 7;
      end LOOP;
   end LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;

END EOW_SALES_ISSUES;
------------------------------------------------------------------------------------------------------------------------
FUNCTION WTD_HTD_SALES_ISSUES(O_error_message       IN OUT VARCHAR2,
                              O_wtd_sales_issues    IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                              O_htd_sales_issues    IN OUT ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                              I_item                IN     ITEM_LOC_HIST.ITEM%TYPE,
                              I_loc                 IN     ITEM_LOC_HIST.LOC%TYPE)
   RETURN BOOLEAN IS

   L_program     VARCHAR2(255) := 'ITEM_LOC_HIST_SQL.WTD_HTD_SALES_ISSUES';

   cursor C_WTD_SALES_ISSUES is
   select  /*+ INDEX(ILH,ITEM_LOC_HIST_I1) */
     nvl(sum(nvl(sales_issues, 0)), 0)
     from item_loc_hist ilh,
          system_variables sv
    where ilh.loc      = nvl(I_loc, ilh.loc)
      and ilh.eow_date = trim(sv.next_eow_date_unit)
      and ilh.item in (select item
                         from item_master im
                        where (   im.item             = I_item
                               or im.item_parent      = I_item
                               or im.item_grandparent = I_item)
                          and im.item_level        = im.tran_level
                          and im.status            = 'A');



   cursor C_HTD_SALES_ISSUES is
   select /*+ INDEX(ILH,ITEM_LOC_HIST_I1) */
          nvl(sum(nvl(sales_issues, 0)), 0)
     from item_loc_hist ilh,
          system_variables sv
    where ilh.loc       = nvl(I_loc, ilh.loc)
      and ilh.eow_date <= Ltrim(sv.next_eow_date_unit)
      and ilh.eow_date >= sv.last_eom_start_half
      and ilh.item in (select item
                         from item_master im
                        where (   im.item             = I_item
                               or im.item_parent      = I_item
                               or im.item_grandparent = I_item)
                          and im.item_level           = im.tran_level
                          and im.status               = 'A');


BEGIN
   SQL_LIB.SET_MARK('OPEN','C_WTD_SALES_ISSUES','ITEM_LOC_HIST',NULL);
   open C_WTD_SALES_ISSUES;
   SQL_LIB.SET_MARK('FETCH','C_WTD_SALES_ISSUES','ITEM_LOC_HIST',NULL);
   fetch C_WTD_SALES_ISSUES into O_wtd_sales_issues;
   SQL_LIB.SET_MARK('CLOSE','C_WTD_SALES_ISSUES','ITEM_LOC_HIST',NULL);
   close C_WTD_SALES_ISSUES;
   ---
   SQL_LIB.SET_MARK('OPEN','C_HTD_SALES_ISSUES','ITEM_LOC_HIST',NULL);
   open C_HTD_SALES_ISSUES;
   SQL_LIB.SET_MARK('FETCH','C_HTD_SALES_ISSUES','ITEM_LOC_HIST',NULL);
   fetch C_HTD_SALES_ISSUES into O_htd_sales_issues;
   SQL_LIB.SET_MARK('CLOSE','C_HTD_SALES_ISSUES','ITEM_LOC_HIST',NULL);
   close C_HTD_SALES_ISSUES;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;
END WTD_HTD_SALES_ISSUES;
------------------------------------------------------------------------------------------------------------
FUNCTION WTD_HTD_SALES_ISSUES_CORP(O_error_message   IN OUT   VARCHAR2,
                                   O_wtd_issues      IN OUT   ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                                   O_htd_issues      IN OUT   ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                                   O_wtd_sales       IN OUT   ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                                   O_htd_sales       IN OUT   ITEM_LOC_HIST.SALES_ISSUES%TYPE,
                                   I_item            IN       ITEM_LOC_HIST.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(255) := 'ITEM_LOC_HIST_SQL.WTD_HTD_SALES_ISSUES_CORP';

   cursor C_WTD_ISSUES is
    select nvl( sum( nvl(sum_sales_issues, 0)), 0) from
      (select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
           nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date = trim(sv.next_eow_date_unit)
          and ilh.sales_type = 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item = I_item
          and im.status = 'A'
       UNION
       select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
              nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date = trim(sv.next_eow_date_unit)
          and ilh.sales_type = 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item_parent = I_item
          and im.status = 'A'
       UNION
       select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
               nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date = trim(sv.next_eow_date_unit)
          and ilh.sales_type = 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item_grandparent = I_item
          and im.status = 'A');



   cursor C_HTD_ISSUES is
           select nvl( sum( nvl(sum_sales_issues, 0)), 0) from
           (select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
             nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date <= Ltrim(sv.next_eow_date_unit)
          and ilh.eow_date >= sv.last_eom_start_half
          and ilh.sales_type = 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item = I_item
          and im.status = 'A'
       UNION
       select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
             nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date <= Ltrim(sv.next_eow_date_unit)
          and ilh.eow_date >= sv.last_eom_start_half
          and ilh.sales_type = 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item_parent = I_item
          and im.status = 'A'
       UNION
       select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
            nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date <= Ltrim(sv.next_eow_date_unit)
          and ilh.eow_date >= sv.last_eom_start_half
          and ilh.sales_type = 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item_grandparent = I_item
          and im.status = 'A');


   cursor C_WTD_SALES is
           select nvl( sum( nvl(sum_sales_issues, 0)), 0) from
      (select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
             nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date = trim(sv.next_eow_date_unit)
          and ilh.sales_type != 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item = I_item
          and im.status = 'A'
       UNION
       select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
         nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date = trim(sv.next_eow_date_unit)
          and ilh.sales_type != 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item_parent = I_item
          and im.status = 'A'
     UNION
       select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
          nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date = trim(sv.next_eow_date_unit)
          and ilh.sales_type != 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item_grandparent = I_item
          and im.status = 'A');



   cursor C_HTD_SALES is
            select nvl( sum( nvl(sum_sales_issues, 0)), 0) from
      (select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
         nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date <= Ltrim(sv.next_eow_date_unit)
          and ilh.eow_date >= sv.last_eom_start_half
          and ilh.sales_type != 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item = I_item
          and im.status = 'A'
       UNION
       select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
         nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date <= Ltrim(sv.next_eow_date_unit)
          and ilh.eow_date >= sv.last_eom_start_half
          and ilh.sales_type != 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item_parent = I_item
          and im.status = 'A'
       UNION
       select /*+ ORDERED INDEX(ILH,ITEM_LOC_HIST_I1) */
          nvl( sum( nvl( sales_issues,  0)), 0) sum_sales_issues
         from item_master im, system_variables sv, item_loc_hist ilh
        where ilh.eow_date <= Ltrim(sv.next_eow_date_unit)
          and ilh.eow_date >= sv.last_eom_start_half
          and ilh.sales_type != 'I'
          and im.item = ilh.item
          and im.item_level = im.tran_level
          and im.item_grandparent = I_item
          and im.status = 'A');



BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_WTD_ISSUES',
                    'ITEM_LOC_HIST',
                    NULL);
   open C_WTD_ISSUES;
   SQL_LIB.SET_MARK('FETCH',
                    'C_WTD_ISSUES',
                    'ITEM_LOC_HIST',
                    NULL);
   fetch C_WTD_ISSUES into O_wtd_issues;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_WTD_ISSUES',
                    'ITEM_LOC_HIST',
                    NULL);
   close C_WTD_ISSUES;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_HTD_ISSUES',
                    'ITEM_LOC_HIST',
                    NULL);
   open C_HTD_ISSUES;
   SQL_LIB.SET_MARK('FETCH',
                    'C_HTD_ISSUES',
                    'ITEM_LOC_HIST',
                    NULL);
   fetch C_HTD_ISSUES into O_htd_issues;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_HTD_ISSUES',
                    'ITEM_LOC_HIST',
                    NULL);
   close C_HTD_ISSUES;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_WTD_SALES',
                    'ITEM_LOC_HIST',
                    NULL);
   open C_WTD_SALES;
   SQL_LIB.SET_MARK('FETCH',
                    'C_WTD_SALES',
                    'ITEM_LOC_HIST',
                    NULL);
   fetch C_WTD_SALES into O_wtd_sales;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_WTD_SALES',
                    'ITEM_LOC_HIST',
                    NULL);
   close C_WTD_SALES;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_HTD_SALES',
                    'ITEM_LOC_HIST',
                    NULL);
   open C_HTD_SALES;
   SQL_LIB.SET_MARK('FETCH',
                    'C_HTD_SALES',
                    'ITEM_LOC_HIST',
                    NULL);
   fetch C_HTD_SALES into O_htd_sales;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_HTD_SALES',
                    'ITEM_LOC_HIST',
                    NULL);
   close C_HTD_SALES;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END WTD_HTD_SALES_ISSUES_CORP;
------------------------------------------------------------------------------------------------------------
END ITEM_LOC_HIST_SQL;
/

