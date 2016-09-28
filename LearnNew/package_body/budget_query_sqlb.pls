CREATE OR REPLACE PACKAGE BODY BUDGET_QUERY_SQL AS
--------------------------------------------------------------------------------

FUNCTION FETCH_BUDGET_INFO(i_budget_variable IN     VARCHAR2,
                           i_dept            IN     NUMBER,
                           i_month           IN     NUMBER,
                           i_half            IN     NUMBER,
                           i_loc_type        IN     VARCHAR2,
                           i_location        IN     NUMBER,
                           io_ret            IN OUT NUMBER,
                           error_message     IN OUT VARCHAR2) RETURN BOOLEAN IS

   L_select        VARCHAR2(1000) := 'select '||i_budget_variable||
                                     ' from month_data_budget'||
                                     ' where dept = '||to_char(i_dept)||
                                     ' and month_no = '||to_char(i_month)||
                                     ' and half_no = '||to_char(i_half)||
                                     ' and location = '||to_char(i_location);
   L_cursor        INTEGER;
   ret             INTEGER;


BEGIN
   if i_loc_type is not NULL then
      L_select := L_select || ' and loc_type = '''|| i_loc_type || '''';
   end if;
   L_cursor := dbms_sql.open_cursor;
   dbms_sql.parse(L_cursor, L_select, dbms_sql.v7);
   dbms_sql.define_column(L_cursor, 1, io_ret);
   ret := dbms_sql.execute(L_cursor);

   if dbms_sql.fetch_rows(L_cursor)> 0 then
      dbms_sql.column_value(L_cursor, 1, io_ret);
   end if;

   dbms_sql.close_cursor(L_cursor);

   return TRUE;

EXCEPTION
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'FETCH_BUDGET_INFO',SQLCODE);
      return FALSE;
END FETCH_BUDGET_INFO;
--------------------------------------------------------------------------------
END;
/

