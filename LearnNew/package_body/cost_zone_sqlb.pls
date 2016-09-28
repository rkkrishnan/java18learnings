CREATE OR REPLACE PACKAGE BODY COST_ZONE_SQL AS
---------------------------------------------------------------------------------------------
--Mod By     : Vivek Sharma, Vivek.Sharma@in.tesco.com
--Mod Date   : 07-Oct-10
--Mod Ref    : CR 339
--Mod Details: A new function which will be used to fetch the Currency code for
--                a Zone Id from table COST_ZONE.
---------------------------------------------------------------------------------------------
FUNCTION INSERT_COST_ZONE_FOR_VWH(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_zone_group     IN      COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                                  I_zone           IN      COST_ZONE.ZONE_ID%TYPE,
                                  I_pwh            IN      WH.PHYSICAL_WH%TYPE)
   return BOOLEAN IS

   L_program_name   VARCHAR2(50) := 'COST_ZONE_SQL.INSERT_COST_ZONE_FOR_VWH';
   L_cost_level     COST_ZONE_GROUP.COST_LEVEL%TYPE;

BEGIN

   if COST_ZONE_ATTRIB_SQL.GET_COST_LEVEL(I_zone_group,
                                          L_cost_level,
                                          O_error_message)= FALSE then
      return FALSE;
   end if;
   ---
   if L_cost_level = 'L' then
      insert into cost_zone_group_loc(zone_group_id,
                                      zone_id,
                                      loc_type,
                                      location)
                               select I_zone_group,
                                      I_pwh,
                                      'W',
                                      wh.wh
                                 from wh
                                where physical_wh      = I_pwh
                                  and stockholding_ind = 'Y'
                                  and not exists(select 'x'
                                                   from cost_zone_group_loc
                                                  where location      = wh.wh
                                                    and zone_id       = nvl(I_zone,I_pwh)
                                                    and zone_group_id = I_zone_group);

   elsif L_cost_level = 'Z' then
      insert into cost_zone_group_loc(zone_group_id,
                                      zone_id,
                                      loc_type,
                                      location)
                               select I_zone_group,
                                      I_zone,
                                      'W',
                                      wh.wh
                                 from wh
                                where physical_wh      = I_pwh
                                  and stockholding_ind = 'Y'
                                  and not exists(select 'x'
                                                   from cost_zone_group_loc
                                                  where location      = wh.wh
                                                    and zone_id       = I_zone
                                                    and zone_group_id = I_zone_group);
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END INSERT_COST_ZONE_FOR_VWH;
--------------------------------------------------------------------------------
FUNCTION DELETE_COST_ZONE_FOR_VWH(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_records_deleted IN OUT  BOOLEAN,
                                  I_zone_group      IN      COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                                  I_zone            IN      COST_ZONE.ZONE_ID%TYPE,
                                  I_pwh             IN      WH.PHYSICAL_WH%TYPE)
   return BOOLEAN IS

   L_program_name   VARCHAR2(50) := 'COST_ZONE_SQL.DELETE_COST_ZONE_FOR_VWH';
   L_cost_level     COST_ZONE_GROUP.COST_LEVEL%TYPE;

   cursor C_LOCK_ZONE_ID is
      select 'x'
        from cost_zone_group_loc cz
       where loc_type = 'W'
         and(zone_id    = I_pwh
             or zone_id = I_zone)
         and zone_group_id = I_zone_group
         and exists (select wh
                       from wh
                      where wh.wh            = cz.location
                        and wh.physical_wh   = nvl(I_pwh, physical_wh)
                        and stockholding_ind = 'Y')
         for UPDATE NOWAIT;

BEGIN
   O_records_deleted := FALSE;
   ---
   if COST_ZONE_ATTRIB_SQL.GET_COST_LEVEL(I_zone_group,
                                          L_cost_level,
                                          O_error_message)= FALSE then
      return FALSE;
   end if;
   ---
   if L_cost_level = 'L' then
      open C_LOCK_ZONE_ID;
      close C_LOCK_ZONE_ID;
      ---
      delete
        from cost_zone_group_loc cz
       where loc_type = 'W'
         and zone_id  = I_pwh
         and zone_group_id = I_zone_group
         and exists (select wh
                       from wh
                      where wh.wh            = cz.location
                        and wh.physical_wh   = I_pwh
                        and stockholding_ind = 'Y');
      if SQL%FOUND then
         O_records_deleted := TRUE;
      end if;
   ---
   elsif L_cost_level = 'Z' then
      open C_LOCK_ZONE_ID;
      close C_LOCK_ZONE_ID;
      ---
      delete
        from cost_zone_group_loc cz
       where loc_type = 'W'
         and zone_id  = I_zone
         and zone_group_id = I_zone_group
         and exists (select wh
                       from wh
                      where wh.wh            = cz.location
                        and wh.physical_wh   = nvl(I_pwh, physical_wh)
                        and stockholding_ind = 'Y');
      if SQL%FOUND then
         O_records_deleted := TRUE;
      end if;
   ---
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_COST_ZONE_FOR_VWH;
---------------------------------------------------------------------------------------------
FUNCTION COST_ZONE_EXIST(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         O_exists         IN OUT  BOOLEAN,
                         I_zone_group     IN      COST_ZONE_GROUP_LOC.ZONE_GROUP_ID%TYPE,
                         I_zone_id        IN      COST_ZONE_GROUP_LOC.ZONE_ID%TYPE,
                         I_location       IN      COST_ZONE_GROUP_LOC.LOCATION%TYPE)

   return BOOLEAN IS

   L_program_name   VARCHAR2(50) := 'COST_ZONE_SQL.COST_ZONE_EXIST';
   L_dummy          VARCHAR2(1)  := 'N';
   ---
   cursor C_LOC_EXIST is
      select 'Y'
        from cost_zone_group_loc
       where zone_group_id = I_zone_group
         and zone_id = I_zone_id
         and location = I_location;
BEGIN
   open  C_LOC_EXIST;
   fetch C_LOC_EXIST into L_dummy;
   close C_LOC_EXIST;
   ---
   O_exists := FALSE;
   ---
   if L_dummy = 'Y' then
      O_exists := TRUE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END COST_ZONE_EXIST;
---------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_CURRENCY_CODE
-- Mod Ref      : CR 339
-- Mod By       : Vivek Sharma, Vivek.Sharma@in.tesco.com
-- Date         : 07-Oct-10
-- Purpose      : This is a new function which will be used to fetch the Currency code for
--                a Zone Id from table COST_ZONE.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_CURRENCY_CODE (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_curr           IN OUT COST_ZONE.CURRENCY_CODE%TYPE,
                                I_zone_id        IN     COST_ZONE.ZONE_ID%TYPE)

   return BOOLEAN IS

   L_program_name   VARCHAR2(50) := 'COST_ZONE_SQL.TSL_GET_CURRENCY_CODE';
   L_dummy          VARCHAR2(1)  := 'N';
   ---
   cursor C_TSL_CURRENCY_CODE is
      select currency_code
        from cost_zone
       where zone_id = I_zone_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_TSL_CURRENCY_CODE', 'COST_ZONE', NULL);
   open  C_TSL_CURRENCY_CODE;

   SQL_LIB.SET_MARK('FETCH', 'C_TSL_CURRENCY_CODE', 'COST_ZONE', NULL);
   fetch C_TSL_CURRENCY_CODE into O_curr;

   SQL_LIB.SET_MARK('CLOSE',  'C_TSL_CURRENCY_CODE', 'COST_ZONE', NULL);
   close C_TSL_CURRENCY_CODE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END TSL_GET_CURRENCY_CODE;
---------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_COST_ZONE_ID
-- Mod Ref      : CR 339
-- Mod By       : Vivek Sharma, Vivek.Sharma@in.tesco.com
-- Date         : 07-Oct-10
-- Purpose      : This is a new function which will be used to fetch the Zone Id for Currency
--                code from table COST_ZONE.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_COST_ZONE_ID (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_curr          IN     COST_ZONE.CURRENCY_CODE%TYPE,
                               O_zone_id       IN OUT COST_ZONE.ZONE_ID%TYPE)

   return BOOLEAN IS

   L_program_name   VARCHAR2(50) := 'COST_ZONE_SQL.C_TSL_COST_ZONE_ID';
   L_dummy          VARCHAR2(1)  := 'N';
   ---
   cursor C_TSL_COST_ZONE_ID is
   select zone_id
     from cost_zone
    where currency_code = I_curr;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_TSL_COST_ZONE_ID', 'COST_ZONE', NULL);
   open  C_TSL_COST_ZONE_ID;

   SQL_LIB.SET_MARK('FETCH', 'C_TSL_COST_ZONE_ID', 'COST_ZONE', NULL);
   fetch C_TSL_COST_ZONE_ID into O_zone_id;

   SQL_LIB.SET_MARK('CLOSE',  'C_TSL_COST_ZONE_ID', 'COST_ZONE', NULL);
   close C_TSL_COST_ZONE_ID;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END TSL_GET_COST_ZONE_ID;
---------------------------------------------------------------------------------------------
END COST_ZONE_SQL;
/

