CREATE OR REPLACE PACKAGE BODY BUDGET_VALIDATE_SQL AS
--------------------------------------------------------------------------------
FUNCTION DEPT_EXISTS(i_dept        IN     NUMBER,
                     o_dept_name   IN OUT VARCHAR2,
                     o_exists      IN OUT BOOLEAN,
                     error_message IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_EXISTS is
      select deps.dept_name
        from deps
       where deps.dept = i_dept
         and exists (select 'x'
                       from month_data_budget
                      where month_data_budget.dept = i_dept);

BEGIN
   o_exists := TRUE;

   open C_EXISTS;
   fetch C_EXISTS into o_dept_name;
   if C_EXISTS%NOTFOUND then
      error_message := 'NO_DEPT_EXIST';
      o_exists := FALSE;
   end if;
   close C_EXISTS;

   if LANGUAGE_SQL.TRANSLATE(O_dept_name,
                             O_dept_name,
                             error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'VALIDATE_DEPT',to_char(SQLCODE));
      return FALSE;
END DEPT_EXISTS;
--------------------------------------------------------------------------------
FUNCTION HALF_EXISTS(i_dept        IN     NUMBER,
                     i_half        IN     NUMBER,
                     i_half_name   IN OUT VARCHAR2,
                     o_exists      IN OUT BOOLEAN,
                     error_message IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_EXISTS is
      select half.half_name
        from half,
             month_data_budget
       where month_data_budget.half_no = half.half_no
         and month_data_budget.half_no = i_half
         and month_data_budget.dept = i_dept;

BEGIN
   o_exists := TRUE;

   open C_EXISTS;
   fetch C_EXISTS into i_half_name;
   if C_EXISTS%NOTFOUND then
      error_message := 'NO_HALF_EXIST';
      o_exists := FALSE;
   end if;
   close C_EXISTS;

   if LANGUAGE_SQL.TRANSLATE(i_half_name,
                             i_half_name,
                             error_message) = FALSE then
      return FALSE;
   end if;


   return TRUE;

EXCEPTION
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'VALIDATE_HALF',SQLCODE);
      return FALSE;
END HALF_EXISTS;
--------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_STORE V_WH
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION STORE_EXISTS(i_dept        IN     NUMBER,
                      i_half        IN     NUMBER,
                      i_location    IN     NUMBER,
                      i_loc_type    IN     VARCHAR2,
                      i_store_name  IN OUT VARCHAR2,
                      o_exists      IN OUT BOOLEAN,
                      error_message IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_STORE_EXISTS is
      select v_store.store_name
        from v_store,
             month_data_budget
       where month_data_budget.location = v_store.store
         and month_data_budget.location = i_location
         and month_data_budget.loc_type = i_loc_type
         and month_data_budget.dept = i_dept
         and month_data_budget.half_no = i_half
         and rownum = 1;

BEGIN
   o_exists := TRUE;

   open C_STORE_EXISTS;
   fetch C_STORE_EXISTS into i_store_name;
   if C_STORE_EXISTS%NOTFOUND then
      error_message := 'NO_MONTHLY_DATA_AVAIL';
      o_exists := FALSE;
   end if;
   close C_STORE_EXISTS;

   if LANGUAGE_SQL.TRANSLATE(i_store_name,
                             i_store_name,
                             error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'VALIDATE_STORE',SQLCODE);
      return FALSE;
END STORE_EXISTS;
--------------------------------------------------------------------------------
FUNCTION WH_EXISTS(i_dept        IN     NUMBER,
                   i_half        IN     NUMBER,
                   i_location    IN     NUMBER,
                   i_loc_type    IN     VARCHAR2,
                   i_wh_name     IN OUT VARCHAR2,
                   o_exists      IN OUT BOOLEAN,
                   error_message IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_WH_EXISTS is
      select v_wh.wh_name
        from v_wh,
             month_data_budget
       where month_data_budget.location = v_wh.wh
         and month_data_budget.location = i_location
         and month_data_budget.loc_type = i_loc_type
         and month_data_budget.dept = i_dept
         and month_data_budget.half_no = i_half
         and rownum = 1;

BEGIN
   o_exists := TRUE;

   open C_WH_EXISTS;
   fetch C_WH_EXISTS into i_wh_name;
   if C_WH_EXISTS%NOTFOUND then
      error_message := 'NO_MONTHLY_DATA_AVAIL';
      o_exists := FALSE;
   end if;
   close C_WH_EXISTS;

   if LANGUAGE_SQL.TRANSLATE(i_wh_name,
                             i_wh_name,
                             error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'VALIDATE_WH', SQLCODE);
      return FALSE;
END WH_EXISTS;
--------------------------------------------------------------------------------
FUNCTION HALF_DATA_BUDGET_EXISTS(i_dept        IN     NUMBER,
                                 i_half        IN     NUMBER,
                                 i_half_name   IN OUT VARCHAR2,
                                 o_exists      IN OUT BOOLEAN,
                                 error_message IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_EXISTS is
      select half.half_name
        from half, half_data_budget
       where half_data_budget.half_no = half.half_no
         and half_data_budget.half_no = i_half
         and half_data_budget.dept = i_dept;

BEGIN
   o_exists := TRUE;

   open C_EXISTS;
   fetch C_EXISTS into i_half_name;
   if C_EXISTS%NOTFOUND then
      error_message := 'NO_HALF_DATA_BUDGET_EXIST';
      o_exists := FALSE;
   end if;
   close C_EXISTS;

   if LANGUAGE_SQL.TRANSLATE(i_half_name,
                             i_half_name,
                             error_message) = FALSE then
      return FALSE;
   end if;


   return TRUE;

EXCEPTION
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'VALIDATE_HALF',SQLCODE);
      return FALSE;
END HALF_DATA_BUDGET_EXISTS;
--------------------------------------------------------------------------------
FUNCTION GET_SHRINKAGE_DTLS(i_dept          IN     HALF_DATA_BUDGET.DEPT%TYPE,
                            i_half          IN     HALF_DATA_BUDGET.HALF_NO%TYPE,
                            i_loc_type      IN     HALF_DATA_BUDGET.LOC_TYPE%TYPE,
                            i_location      IN     HALF_DATA_BUDGET.LOCATION%TYPE,
                            o_shrink_pct    IN OUT HALF_DATA_BUDGET.SHRINKAGE_PCT%TYPE,
                            O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE) RETURN BOOLEAN IS

   cursor C_HALF_DATA IS
      select NVL(shrinkage_pct,0) / 100
        from half_data_budget
       where dept    = i_dept
         and half_no = i_half
         and loc_type= i_loc_type
         and location= i_location;

BEGIN
---
  SQL_LIB.SET_MARK('OPEN','C_HALF_DATA','HALF_DATA_BUDGET',NULL);
  open C_HALF_DATA;
  SQL_LIB.SET_MARK('FETCH','C_HALF_DATA','HALF_DATA_BUDGET',NULL);
  fetch C_HALF_DATA into o_shrink_pct;
  SQL_LIB.SET_MARK('CLOSE','C_HALF_DATA','HALF_DATA_BUDGET',NULL);
  close C_HALF_DATA;

  return TRUE;
---
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'BUDGET_VALIDATE_SQL.GET_SHRINKAGE_DTLS',SQLCODE);
      return FALSE;
END GET_SHRINKAGE_DTLS;
--------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_EXTERNAL_FINISHER
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION EXT_FIN_EXISTS(i_dept         IN     NUMBER,
                        i_half         IN     NUMBER,
                        i_location     IN     NUMBER,
                        i_loc_type     IN     VARCHAR2,
                        i_ext_fin_name IN OUT VARCHAR2,
                        o_exists       IN OUT BOOLEAN,
                        error_message  IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_EXT_FIN_EXISTS is
      select v_external_finisher.finisher_desc
        from v_external_finisher,
             month_data_budget
       where month_data_budget.location = v_external_finisher.finisher_id
         and month_data_budget.location = i_location
         and month_data_budget.loc_type = i_loc_type
         and month_data_budget.dept = i_dept
         and month_data_budget.half_no = i_half
         and rownum = 1;

BEGIN
   o_exists := TRUE;

   open C_EXT_FIN_EXISTS;
   fetch C_EXT_FIN_EXISTS into i_ext_fin_name;
   if C_EXT_FIN_EXISTS%NOTFOUND then
      error_message := 'NO_MONTHLY_DATA_AVAIL';
      o_exists := FALSE;
   end if;
   close C_EXT_FIN_EXISTS;

   if LANGUAGE_SQL.TRANSLATE(i_ext_fin_name,
                             i_ext_fin_name,
                             error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'VALIDATE_EXT_FIN', SQLCODE);
      return FALSE;
END EXT_FIN_EXISTS;
--------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_INTERNAL_FINISHER
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION INT_FIN_EXISTS(i_dept         IN     NUMBER,
                        i_half         IN     NUMBER,
                        i_location     IN     NUMBER,
                        i_loc_type     IN     VARCHAR2,
                        i_ext_fin_name IN OUT VARCHAR2,
                        o_exists       IN OUT BOOLEAN,
                        error_message  IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_INT_FIN_EXISTS is
      select v_internal_finisher.finisher_desc
        from v_internal_finisher,
             month_data_budget
       where month_data_budget.location = v_internal_finisher.finisher_id
         and month_data_budget.location = i_location
         and month_data_budget.loc_type = i_loc_type
         and month_data_budget.dept = i_dept
         and month_data_budget.half_no = i_half
         and rownum = 1;

BEGIN
   o_exists := TRUE;

   open C_INT_FIN_EXISTS;
   fetch C_INT_FIN_EXISTS into i_ext_fin_name;
   if C_INT_FIN_EXISTS%NOTFOUND then
      error_message := 'NO_MONTHLY_DATA_AVAIL';
      o_exists := FALSE;
   end if;
   close C_INT_FIN_EXISTS;

   if LANGUAGE_SQL.TRANSLATE(i_ext_fin_name,
                             i_ext_fin_name,
                             error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'VALIDATE_INT_FIN', SQLCODE);
      return FALSE;
END INT_FIN_EXISTS;

END;
/

