CREATE OR REPLACE PACKAGE BODY FORECASTS_SQL AS

---------------------------------------------------------------------------------------------
FUNCTION GET_ITEM_FORECAST_IND(O_error_message IN OUT VARCHAR2,
                               I_item          IN     ITEM_MASTER.ITEM%TYPE,
                               O_forecast_ind  IN OUT VARCHAR2) RETURN BOOLEAN IS


   cursor C_CHECK_ITEM is
      select forecast_ind
        from item_master
       where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_ITEM',
                    'ITEM_MASTER',
                    I_item);
   open C_CHECK_ITEM;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_ITEM',
                    'ITEM_MASTER',
                    I_item);
   fetch C_CHECK_ITEM into O_forecast_ind;
   if C_CHECK_ITEM%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('SKU_NO_EXIST',
                                             I_item,
                                             NULL,
                                             NULL);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_ITEM',
                       'ITEM_MASTER',
                       I_item);
      close C_CHECK_ITEM;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_ITEM',
                    'ITEM_MASTER',
                    I_item);
   close C_CHECK_ITEM;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'FORECASTS_SQL.GET_ITEM_FORECAST_IND',
                                             to_char(SQLCODE));
   return FALSE;
END GET_ITEM_FORECAST_IND;
----------------------------------------------------------------------------
FUNCTION GET_SYSTEM_FORECAST_IND (O_error_message IN OUT VARCHAR2,
                               O_forecast_ind  IN OUT SYSTEM_OPTIONS.FORECAST_IND%TYPE) RETURN BOOLEAN IS


   cursor C_FORECAST_IND is
      select forecast_ind
        from system_options;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_FORECAST_IND',
                    'SYSTEM_OPTIONS',
                    NULL);
   open C_FORECAST_IND;
   SQL_LIB.SET_MARK('FETCH',
                    'C_FORECAST_IND',
                    'SYSTEM_OPTIONS',
                    NULL);
   fetch C_FORECAST_IND into O_forecast_ind;
   if C_FORECAST_IND%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('ERROR_FORECAST_IND',
                                             NULL,
                                             NULL,
                                             NULL);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_FORECAST_IND',
                       'SYSTEM_OPTIONS',
                       NULL);
      close C_FORECAST_IND;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_FORECAST_IND',
                    'SYSTEM_OPTIONS',
                    NULL);
   close C_FORECAST_IND;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                            SQLERRM,
                               'FORECASTS_SQL.GET_SYSTEM_FORECAST_IND',
                            to_char(SQLCODE));
   RETURN FALSE;
END GET_SYSTEM_FORECAST_IND;
-------------------------------------------------------------------------------------

FUNCTION GET_FORECAST_MIN_MAX_DATES (O_error_message      IN OUT VARCHAR2,
                                     O_forecast_min_date  IN OUT DATE,
                                     O_forecast_max_date  IN OUT DATE) RETURN BOOLEAN IS

   L_min       ITEM_FORECAST.EOW_DATE%TYPE    := NULL;
   L_max       ITEM_FORECAST.EOW_DATE%TYPE    := NULL;
   L_program   VARCHAR2(60) := 'FORECAST_SQL.GET_MIN_MAX_DATES';
   ---
   cursor C_MIN_MAX is
      select MIN(i.eow_date),
             MAX(i.eow_date)
        from item_forecast i,
             store s
       where s.store = i.loc
         and i.forecast_sales is not NULL;
   ---
BEGIN
   --
   -- Get minimum and maximum dates of available sales (i.e. store)
   -- forecasts from the item forecast table.
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_MIN_MAX',
                    'ITEM_FORECAST, STORE',
                    NULL);
   open C_MIN_MAX;

   SQL_LIB.SET_MARK('FETCH',
                    'C_MIN_MAX',
                    'ITEM_FORECAST, STORE',
                    NULL);
   fetch C_MIN_MAX into L_min,
                        L_max;

   if C_MIN_MAX%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('ERROR_FETCHING_C_MIN_MAX',
                                            L_program,
                                            SQLERRM,
                                            NULL);

      SQL_LIB.SET_MARK('CLOSE',
                       'C_MIN_MAX',
                       'ITEM_FORECAST, STORE',
                       NULL);
      close C_MIN_MAX;

      return FALSE;

   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_MIN_MAX',
                    'ITEM_FORECAST, STORE',
                    NULL);
   close C_MIN_MAX;

   O_forecast_min_date := L_min;

   O_forecast_max_date := L_max;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   RETURN FALSE;

END GET_FORECAST_MIN_MAX_DATES;
---------------------------------------------------------------------------------------------

FUNCTION DOMAIN_EXISTS(O_error_message  IN OUT VARCHAR2,
                       I_dept           IN     DEPS.DEPT%TYPE,
                       I_class          IN     CLASS.CLASS%TYPE,
                       I_subclass       IN     SUBCLASS.SUBCLASS%TYPE,
                       O_domain_exists  IN OUT BOOLEAN) RETURN BOOLEAN IS

   L_domain_level_ind    system_options.domain_level%TYPE := NULL;
   L_domain_level_exists VARCHAR2(1)                      := NULL;
   L_error_message       VARCHAR2(255);
   L_program             VARCHAR2(60)                     := 'FORECAST_SQL.DOMAIN_EXISTS';

   cursor C_DOMAIN_DEPT_EXISTS is
      select 'X'
        from domain_dept dd
       where dd.dept = NVL(I_dept, -1);

   cursor C_DOMAIN_CLASS_EXISTS is
      select 'X'
        from domain_class dc
       where dc.class = NVL(I_class, -1)
         and dc.dept  = NVL(I_dept, -1);

   cursor C_DOMAIN_SUBCLASS_EXISTS is
      select 'X'
        from domain_subclass sc
       where sc.subclass = nvl(I_subclass, -1)
         and sc.class    = NVL(I_class, -1)
         and sc.dept     = NVL(I_dept, -1);

BEGIN
   if not FORECASTS_SQL.GET_DOMAIN_LEVEL(L_error_message,
                                         L_domain_level_ind) then
      O_error_message := L_error_message;
      return FALSE;
   end if;

   if L_domain_level_ind = 'D' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_DOMAIN_DEPT_EXISTS',
                       'DOMAIN_DEPT',
                       NULL);
      open C_DOMAIN_DEPT_EXISTS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_DOMAIN_DEPT_EXISTS',
                       'DOMAIN_DEPT',
                       NULL);
      fetch C_DOMAIN_DEPT_EXISTS into L_domain_level_exists;

      if C_DOMAIN_DEPT_EXISTS%FOUND then
         O_domain_exists := TRUE;
      else
         O_domain_exists := FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_DOMAIN_DEPT_EXISTS',
                       'DOMAIN_DEPT',
                       NULL);
      close C_DOMAIN_DEPT_EXISTS;

   elsif L_domain_level_ind = 'C' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_DOMAIN_CLASS_EXISTS',
                       'DOMAIN_CLASS',
                       NULL);
      open C_DOMAIN_CLASS_EXISTS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_DOMAIN_CLASS_EXISTS',
                       'DOMAIN_CLASS',
                       NULL);
      fetch C_DOMAIN_CLASS_EXISTS into L_domain_level_exists;

      if C_DOMAIN_CLASS_EXISTS%FOUND then
         O_domain_exists := TRUE;
      else
         O_domain_exists := FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_DOMAIN_CLASS_EXISTS',
                       'DOMAIN_CLASS',
                       NULL);
      close C_DOMAIN_CLASS_EXISTS;

   elsif L_domain_level_ind = 'S' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_DOMAIN_SUBCLASS_EXISTS',
                       'DOMAIN_SUBCLASS',
                       NULL);
      open C_DOMAIN_SUBCLASS_EXISTS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_DOMAIN_SUBCLASS_EXISTS',
                       'DOMAIN_SUBCLASS',
                       NULL);
      fetch C_DOMAIN_SUBCLASS_EXISTS into L_domain_level_exists;

      if C_DOMAIN_SUBCLASS_EXISTS%FOUND then
         O_domain_exists := TRUE;
      else
         O_domain_exists := FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_DOMAIN_SUBCLASS',
                       'DOMAIN_SUBCLASS',
                       NULL);
      close C_DOMAIN_SUBCLASS_EXISTS;

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;

END DOMAIN_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION GET_DOMAIN (O_error_message  IN OUT VARCHAR2,
                     I_dept           IN     DEPS.DEPT%TYPE,
                     I_class          IN     CLASS.CLASS%TYPE,
                     I_subclass       IN     SUBCLASS.SUBCLASS%TYPE,
                     O_domain_id      IN OUT NUMBER) RETURN BOOLEAN IS

   L_domain_level  system_options.domain_level%TYPE  := NULL;
   L_error_message VARCHAR2(255)                     := NULL;

   cursor C_DEPT_DOMAIN is
      select dd.domain_id
        from domain_dept dd
       where dd.dept = I_dept;

   cursor C_CLASS_DOMAIN is
      select dc.domain_id
        from domain_class dc
       where dc.class = I_class
         and dc.dept = I_dept;

   cursor C_SUBCLASS_DOMAIN is
      select dsc.domain_id
        from domain_subclass dsc
       where dsc.subclass = I_subclass
         and dsc.class    = I_class
         and dsc.dept     = I_dept;

BEGIN
   --
   -- Fetch the current domain level.
   --
   if FORECASTS_SQL.GET_DOMAIN_LEVEL( L_error_message,
                                      L_domain_level) = FALSE then
      O_error_message := L_error_message;
      return FALSE;
   end if;

   if L_domain_level = 'D' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_DEPT_DOMAIN',
                       'DOMAIN_DEPT',
                       'DEPT: ' || to_char(I_dept));
      open C_DEPT_DOMAIN;
      SQL_LIB.SET_MARK('FETCH',
                       'C_DEPT_DOMAIN',
                       'DOMAIN_DEPT',
                       'DEPT: ' || to_char(I_dept));
      fetch C_DEPT_DOMAIN into O_domain_id;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_DEPT_DOMAIN',
                       'DOMAIN_DEPT',
                       'DEPT: ' || to_char(I_dept));
      close C_DEPT_DOMAIN;
   elsif L_domain_level = 'C' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_CLASS_DOMAIN',
                       'DOMAIN_CLASS',
                       'DEPT: ' || to_char(I_dept) ||
                       ' CLASS: ' || to_char(I_class));
      open C_CLASS_DOMAIN;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CLASS_DOMAIN',
                       'DOMAIN_CLASS',
                       'DEPT: ' || to_char(I_dept) ||
                       ' CLASS: ' || to_char(I_class));
      fetch C_CLASS_DOMAIN into O_domain_id;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CLASS_DOMAIN',
                       'DOMAIN_CLASS',
                       'DEPT: ' || to_char(I_dept) ||
                       ' CLASS: ' || to_char(I_class));
      close C_CLASS_DOMAIN;
   elsif L_domain_level = 'S' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_SUBCLASS_DOMAIN',
                       'DOMAIN_SUBCLASS',
                       'DEPT: ' || to_char(I_dept) ||
                       ' CLASS: ' || to_char(I_class) ||
                       ' SUBCLASS: ' || to_char(I_subclass));
      open C_SUBCLASS_DOMAIN;
      SQL_LIB.SET_MARK('FETCH',
                       'C_SUBCLASS_DOMAIN',
                       'DOMAIN_SUBCLASS',
                       'DEPT: ' || to_char(I_dept) ||
                       ' CLASS: ' || to_char(I_class) ||
                       ' SUBCLASS: ' || to_char(I_subclass));
      fetch C_SUBCLASS_DOMAIN into O_domain_id;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SUBCLASS_DOMAIN',
                       'DOMAIN_SUBCLASS',
                       'DEPT: ' || to_char(I_dept) ||
                       ' CLASS: ' || to_char(I_class) ||
                       ' SUBCLASS: ' || to_char(I_subclass));
      close C_SUBCLASS_DOMAIN;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'FORECASTS_SQL.GET_DOMAIN',
                                            to_char(SQLCODE));
      return FALSE;

END GET_DOMAIN;
----------------------------------------------------------------------------
FUNCTION GET_DOMAIN_LEVEL (O_error_message  IN OUT VARCHAR2,
                           O_domain_level   IN OUT SYSTEM_OPTIONS.DOMAIN_LEVEL%TYPE) return BOOLEAN is

   cursor C_DOMAIN_LEVEL is
      select domain_level
        from system_options;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_DOMAIN_LEVEL',
                    'SYSTEM_OPTIONS',
                    NULL);
   open C_DOMAIN_LEVEL;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DOMAIN_LEVEL',
                    'SYSTEM_OPTIONS',
                    NULL);
   fetch C_DOMAIN_LEVEL into O_domain_level;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DOMAIN_LEVEL',
                    'SYSTEM_OPTIONS',
                    NULL);
   close C_DOMAIN_LEVEL;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'FORECASTS_SQL.GET_DOMAIN_LEVEL',
                                            to_char(SQLCODE));
      return FALSE;

END GET_DOMAIN_LEVEL;
----------------------------------------------------------------------------
FUNCTION FORECAST_SUB_ITEMS  (O_error_message      IN OUT VARCHAR2,
                              I_item               IN     ITEM_MASTER.ITEM%TYPE,
                              O_forecast_sub_items IN OUT BOOLEAN) return BOOLEAN is

   L_forecast_sub_items VARCHAR2(1);

   cursor C_FORECAST_SUB is
      select 'x'
        from sub_items_head sih
       where sih.item = I_item
         and sih.use_forecast_sales_ind = 'Y';

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_FORECAST_SUB',
                    'SUB_ITEMS_HEAD',
                    I_item);
   open C_FORECAST_SUB;

   SQL_LIB.SET_MARK('FETCH',
                    'C_FORECAST_SUB',
                    'SUB_ITEMS_HEAD',
                    I_item);
   fetch C_FORECAST_SUB into L_forecast_sub_items;

   if C_FORECAST_SUB%NOTFOUND then
      O_forecast_sub_items := FALSE;
   else
      O_forecast_sub_items := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_FORECAST_SUB',
                    'SUB_ITEMS_HEAD',
                    I_item);
   close C_FORECAST_SUB;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'FORECASTS_SQL.FORECAST_SUB_ITEMS',
                                             to_char(SQLCODE));
      return FALSE;
END FORECAST_SUB_ITEMS;
----------------------------------------------------------------------------
FUNCTION FORECAST_MAIN_ITEMS(O_error_message       IN OUT VARCHAR2,
                             I_item                IN     ITEM_MASTER.ITEM%TYPE,
                             O_forecast_main_items IN OUT BOOLEAN) return BOOLEAN is

   L_forecast_main_items VARCHAR2(1);

   cursor C_FORECAST_MAIN is
      select 'X'
        from sub_items_head sih,
             sub_items_detail sid
       where sid.sub_item = I_item
         and sid.item = sih.item
         and sih.use_forecast_sales_ind = 'Y';

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_FORECAST_MAIN',
                    'SUB_ITEMS_HEAD',
                    I_item);
   open C_FORECAST_MAIN;

   SQL_LIB.SET_MARK('FETCH',
                    'C_FORECAST_MAIN',
                    'SUB_ITEMS_HEAD',
                    I_item);
   fetch C_FORECAST_MAIN into L_forecast_main_items;

   if C_FORECAST_MAIN%NOTFOUND then
      O_forecast_main_items := FALSE;
   else
      O_forecast_main_items := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_FORECAST_MAIN',
                    'SUB_ITEMS_HEAD',
                    I_item);
   close C_FORECAST_MAIN;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'FORECASTS_SQL.FORECAST_MAIN_ITEMS',
                                             to_char(SQLCODE));
      return FALSE;
END FORECAST_MAIN_ITEMS;
----------------------------------------------------------------------------
FUNCTION CLEAR_ITEM_LAST_EXPRT_DATE(O_error_message         IN OUT   VARCHAR2,
                                    I_item                  IN       ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_last_hist_export_date   ITEM_LOC_SOH.LAST_HIST_EXPORT_DATE%TYPE := NULL;
   L_user                    ITEM_LOC_SOH.LAST_UPDATE_ID%TYPE;
   L_last_update_datetime    DATE := SYSDATE;
   RECORD_LOCKED             EXCEPTION;
   PRAGMA                    EXCEPTION_INIT(Record_Locked, -54);

   cursor C_CHECK_EXPRT_DATE is
      select last_hist_export_date,
             user
        from item_loc_soh
       where item = I_item
         and last_hist_export_date is NOT NULL;

   cursor C_LOCK_ITEM_LOC_SOH is
      select 'x'
        from item_loc_soh
       where item = I_item
          or item_parent = I_item
          or item_grandparent = I_item
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_EXPRT_DATE', 'ITEM_LOC_SOH', I_item);
   open C_CHECK_EXPRT_DATE;

   SQL_LIB.SET_MARK('FETCH', 'C_CHECK_EXPRT_DATE', 'ITEM_LOC_SOH', I_item);
   fetch C_CHECK_EXPRT_DATE into L_last_hist_export_date,
                                 L_user;
   if C_CHECK_EXPRT_DATE%FOUND then
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_LOC_SOH', 'ITEM_LOC_SOH', I_item);
      open C_LOCK_ITEM_LOC_SOH;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_LOC_SOH', 'ITEM_LOC_SOH', I_item);
      close C_LOCK_ITEM_LOC_SOH;

      SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_LOC_SOH', I_item);
      update item_loc_soh
         set last_hist_export_date = NULL,
             last_update_datetime = L_last_update_datetime,
             last_update_id = L_user
       where item = I_item
          or item_parent = I_item
          or item_grandparent = I_item;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_EXPRT_DATE', 'ITEM_LOC_SOH', I_item);
   close C_CHECK_EXPRT_DATE;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      if C_CHECK_EXPRT_DATE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_EXPRT_DATE', 'ITEM_LOC_SOH', I_item);
         close C_CHECK_EXPRT_DATE;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_LOC',
                                            I_item,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'FORECASTS_SQL.CLEAR_ITEM_LAST_EXPRT_DATE',
                                             to_char(SQLCODE));
      return FALSE;
END CLEAR_ITEM_LAST_EXPRT_DATE;
----------------------------------------------------------------------------
FUNCTION GET_DOMAIN_DESC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         I_domain_id     IN     DOMAIN.DOMAIN_ID%TYPE,
                         O_domain_desc   IN OUT DOMAIN.DOMAIN_DESC%TYPE,
                         O_valid         IN OUT BOOLEAN)
return BOOLEAN is

   L_program     VARCHAR2(64) := 'FORECASTS_SQL.GET_DOMAIN_DESC';

   cursor C_GET_DOMAIN_DESC is
      select domain_desc
        from domain
       where domain_id = I_domain_id;

BEGIN

   if I_domain_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_domain_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_DOMAIN_DESC',
                    'DOMAIN',
                    to_char(I_domain_id));
   open C_GET_DOMAIN_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_DOMAIN_DESC',
                    'DOMAIN',
                    to_char(I_domain_id));
   fetch C_GET_DOMAIN_DESC into O_domain_desc;

   if C_GET_DOMAIN_DESC%NOTFOUND then
      O_valid       := FALSE;
      O_domain_desc := NULL;
   else
      O_valid       := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_DOMAIN_DESC',
                    'DOMAIN',
                    to_char(I_domain_id));
   close C_GET_DOMAIN_DESC;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_DOMAIN_DESC;
----------------------------------------------------------------------------
END;
/

