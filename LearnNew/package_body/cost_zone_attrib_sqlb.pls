CREATE OR REPLACE PACKAGE BODY COST_ZONE_ATTRIB_SQL AS
--------------------------------------------------------------------------------------------
FUNCTION GET_ZONE_GROUP_DESC( I_cost_zone_group       IN NUMBER,
                              O_cost_zone_group_desc  IN OUT VARCHAR2,
                              O_error_message         IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_COST_ZONE is
      select czg.description
        from cost_zone_group czg
       where czg.zone_group_id = I_cost_zone_group;

BEGIN
   sql_lib.set_mark('OPEN', 'C_COST_ZONE', 'cost_zone_group', 'I_cost_zone_group' );
   open C_COST_ZONE;
   sql_lib.set_mark('FETCH', 'C_COST_ZONE', 'cost_zone_group', 'I_cost_zone_group' );
   fetch C_COST_ZONE into O_cost_zone_group_desc;
   if C_COST_ZONE%NOTFOUND then
      O_error_message := 'INV_COST_ZONE';
      sql_lib.set_mark('CLOSE', 'C_COST_ZONE', 'cost_zone_group', 'I_cost_zone_group' );
      close C_COST_ZONE;
      Return FALSE;
   end if;
   sql_lib.set_mark('CLOSE', 'C_COST_ZONE', 'cost_zone_group', 'I_cost_zone_group' );
   close C_COST_ZONE;

   if LANGUAGE_SQL.TRANSLATE(O_cost_zone_group_desc,
			     O_cost_zone_group_desc,
			     O_error_message) = FALSE then
      return FALSE;
   end if;

   Return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message :=
       sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,'COST_ZONE_ATTRIB_SQL.GET_ZONE_GROUP_DESC',NULL);
      Return FALSE;
END GET_ZONE_GROUP_DESC;
--------------------------------------------------------------------------------------------
FUNCTION GET_ZONE_DESC( I_cost_zone_group  IN NUMBER,
                        I_cost_zone_id     IN NUMBER,
                        O_cost_zone_desc   IN OUT VARCHAR2,
                        O_error_message    IN OUT VARCHAR2) RETURN BOOLEAN IS
   cursor C_ZONE is
      select cz.description
        from cost_zone cz
       where cz.zone_group_id = I_cost_zone_group
         and cz.zone_id       = I_cost_zone_id;
BEGIN
   sql_lib.set_mark('OPEN', 'C_ZONE', 'cost_zone', 'I_cost_zone_group, I_cost_zone_id' );
   open C_ZONE;
   sql_lib.set_mark('FETCH', 'C_ZONE', 'cost_zone', 'I_cost_zone_group, I_cost_zone_id' );
   fetch C_ZONE into O_cost_zone_desc;
   if C_ZONE%NOTFOUND then
      O_error_message := 'INVALID_COST_ZONE';
         sql_lib.set_mark('CLOSE', 'C_ZONE', 'cost_zone', 'I_cost_zone_group, I_cost_zone_id' );
         close C_ZONE;
         Return FALSE;
   end if;
   sql_lib.set_mark('CLOSE', 'C_ZONE', 'cost_zone', 'I_cost_zone_group, I_cost_zone_id' );
   close C_ZONE;

   if LANGUAGE_SQL.TRANSLATE(	O_cost_zone_desc,
			        O_cost_zone_desc,
				O_error_message) = FALSE then
      return FALSE;
   end if;

   Return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message :=
         sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,'COST_ZONE_ATTRIB_SQL.GET_ZONE_DESC',NULL);
      Return FALSE;
END GET_ZONE_DESC;
--------------------------------------------------------------------------------------------
  FUNCTION GET_COST_LEVEL(I_cost_zone_group  IN     cost_zone.zone_group_id%TYPE,
                           O_cost_level       IN OUT cost_zone_group.cost_level%TYPE,
                           O_error_message    IN OUT VARCHAR2) RETURN BOOLEAN is

   cursor C_GET_COST_LEVEL is
      select cz.cost_level
        from cost_zone_group cz
       where cz.zone_group_id = I_cost_zone_group;

BEGIN
    sql_lib.set_mark('OPEN', 'C_GET_COST_LEVEL', 'cost_zone_group', 'I_cost_zone_group' );
    open C_GET_COST_LEVEL;
    sql_lib.set_mark('FETCH', 'C_GET_COST_LEVEL', 'cost_zone_group', 'I_cost_zone_group' );
    fetch C_GET_COST_LEVEL into O_cost_level;
    if C_GET_COST_LEVEL%NOTFOUND then
       sql_lib.set_mark('CLOSE', 'C_GET_COST_LEVEL', 'cost_zone_group', 'I_cost_zone_group' );
       close C_GET_COST_LEVEL;
       return FALSE;
    end if;

    sql_lib.set_mark('CLOSE', 'C_GET_COST_LEVEL', 'cost_zone_group', 'I_cost_zone_group' );
    close C_GET_COST_LEVEL;
    return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message :=
         sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,'COST_ZONE_ATTRIB_SQL.GET_COST_LEVEL',NULL);
      Return FALSE;

END GET_COST_LEVEL;
--------------------------------------------------------------------------------------------
END COST_ZONE_ATTRIB_SQL;
/

