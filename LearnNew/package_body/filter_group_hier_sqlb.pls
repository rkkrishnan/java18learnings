CREATE OR REPLACE PACKAGE BODY FILTER_GROUP_HIER_SQL as
--------------------------------------------------------------------------
--Mod By       : Nitin Gour, nitin.gour@in.tesco.com
--Mod Date     : 09-Jul-2008
--Mod Ref      : N147
--Mod Details  : Added Two New Functions TSL_CHECK_DUP_GROUP_NON_MERCH and TSL_SET_DISPLAY_MERCH_IND,
--               Modificatio in LOCK_FILTER_GROUP_RECORD function
------------------------------------------------------------------------------------------------------
--Mod By       : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date     : 11-Dec-2009
--Mod Ref      : CR236a
--Mod Details  : Added TSL_FILTER_COUNTRY function
------------------------------------------------------------------------------------------------------
--Mod By       : Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
--Mod Date     : 31-Aug-2010
--Mod Ref      : CR354 - 18915
--Mod Details  : Modified TSL_USER_COUNTRY function
------------------------------------------------------------------------------------------------------
-- CHECK_DUP_GROUP_MERCH( )
--------------------------------------------------------------------------------
FUNCTION CHECK_DUP_GROUP_MERCH(O_error_message            IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               O_dup_exists               IN OUT  BOOLEAN,
                               I_sec_group_id             IN      FILTER_GROUP_MERCH.SEC_GROUP_ID%TYPE,
                               I_filter_merch_level       IN      FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE,
                               I_filter_merch_id          IN      FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE,
                               I_filter_merch_id_class    IN      FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE,
                               I_filter_merch_id_subclass IN      FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_GROUP_HIER_SQL.CHECK_DUP_GROUP_MERCH';

   L_dummy                VARCHAR2(1);
   L_filter_merch_level   FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE;
   L_code_desc            CODE_DETAIL.CODE_DESC%TYPE;
   L_exists               BOOLEAN;
   L_inv_parm             VARCHAR2(30)   := NULL;

   cursor C_CHECK_MERCH is
      select 'X'
        from filter_group_merch
       where sec_group_id = I_sec_group_id
         and filter_merch_id = I_filter_merch_id
         and filter_merch_level = I_filter_merch_level
         and nvl(filter_merch_id_class, -1) = nvl(I_filter_merch_id_class, -1)
         and nvl(filter_merch_id_subclass, -1) = nvl(I_filter_merch_id_subclass, -1);

   cursor C_GET_CODE_DESC is
      select code_desc
        from code_detail
       where code_type = 'FLTM'
         and code = I_filter_merch_level;

   cursor C_CHECK_DIV_HIER is
      select filter_merch_level
        from filter_group_merch fm
       where sec_group_id = I_sec_group_id
         and ((filter_merch_level = 'G'
               and exists (select 'X'
                             from groups gp
                            where gp.group_no = fm.filter_merch_id
                              and gp.division = I_filter_merch_id))
           or (filter_merch_level in ('P','C','S')
               and exists (select 'X'
                             from deps dp
                            where dp.dept = fm.filter_merch_id
                              and exists (select 'X'
                                            from groups gps
                                           where gps.group_no = dp.group_no
                                             and gps.division = I_filter_merch_id))));

   cursor C_CHECK_GRP_HIER is
      select filter_merch_level
        from filter_group_merch fm
       where sec_group_id = I_sec_group_id
         and ((filter_merch_level = 'D'
               and exists (select 'X'
                             from groups gp
                            where gp.division = fm.filter_merch_id
                              and gp.group_no = I_filter_merch_id))
           or (filter_merch_level in ('P','C','S')
               and exists (select 'X'
                             from deps dp
                            where dp.dept = fm.filter_merch_id
                              and dp.group_no = I_filter_merch_id)));

   cursor C_CHECK_DEPT_HIER is
      select filter_merch_level
        from filter_group_merch fm
       where sec_group_id = I_sec_group_id
         and ((filter_merch_level = 'D'
               and exists (select 'X'
                             from groups gp
                            where gp.division = fm.filter_merch_id
                              and exists (select 'X'
                                            from deps dp
                                           where dp.group_no = gp.group_no
                                             and dp.dept = I_filter_merch_id)))
           or (filter_merch_level = 'G'
               and exists (select 'X'
                             from deps dps
                            where dps.group_no = fm.filter_merch_id
                              and dps.dept = I_filter_merch_id))
           or (filter_merch_level in ('C','S')
               and fm.filter_merch_id = I_filter_merch_id));

   cursor C_CHECK_CLASS_HIER is
      select filter_merch_level
        from filter_group_merch fm
       where sec_group_id = I_sec_group_id
         and ((filter_merch_level = 'D'
               and exists (select 'X'
                             from groups gp,
                                  deps dp
                            where gp.division = fm.filter_merch_id
                              and gp.group_no = dp.group_no
                              and dp.dept = I_filter_merch_id))
           or (filter_merch_level = 'G'
               and exists (select 'X'
                             from deps dps
                            where dps.group_no = fm.filter_merch_id
                              and dps.dept = I_filter_merch_id))
           or (filter_merch_level = 'P'
               and fm.filter_merch_id = I_filter_merch_id)
           or (filter_merch_level = 'S'
               and fm.filter_merch_id = I_filter_merch_id
               and fm.filter_merch_id_class = I_filter_merch_id_class));

   cursor C_CHECK_SUBCLASS_HIER is
      select filter_merch_level
        from filter_group_merch fm
       where sec_group_id = I_sec_group_id
         and ((filter_merch_level = 'D'
               and exists (select 'X'
                             from groups gp,
                                  deps dp
                            where gp.division = fm.filter_merch_id
                              and gp.group_no = dp.group_no
                              and dp.dept = I_filter_merch_id))
          or (filter_merch_level = 'G'
              and exists (select 'X'
                            from deps dps
                           where dps.group_no = fm.filter_merch_id
                             and dps.dept = I_filter_merch_id))
          or (filter_merch_level = 'P'
              and fm.filter_merch_id = I_filter_merch_id)
          or (filter_merch_level = 'C'
              and fm.filter_merch_id = I_filter_merch_id
              and fm.filter_merch_id_class = I_filter_merch_id_class));


BEGIN
   if I_sec_group_id is NULL then
      L_inv_parm := 'I_sec_group_id';
   elsif I_filter_merch_level is NULL then
      L_inv_parm := 'I_filter_merch_level';
   elsif I_filter_merch_id is NULL then
      L_inv_parm := 'I_filter_merch_id';
   end if;

   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_parm,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   open C_GET_CODE_DESC;
   fetch C_GET_CODE_DESC into L_code_desc;
   close C_GET_CODE_DESC;
   if L_code_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_MERCH_LEVEL', NULL, NULL, NULL);
      return FALSE;
   else
      open C_CHECK_MERCH;
      fetch C_CHECK_MERCH into L_dummy;
      close C_CHECK_MERCH;

      if L_dummy is NULL then
         O_dup_exists := FALSE;

         if I_filter_merch_level = 'D' then
            open C_CHECK_DIV_HIER;
            fetch C_CHECK_DIV_HIER into L_filter_merch_level;
            close C_CHECK_DIV_HIER;
            if L_filter_merch_level is NULL then
               L_exists := FALSE;
            else
               L_exists := TRUE;
            end if;
         elsif I_filter_merch_level = 'G' then
            open C_CHECK_GRP_HIER;
            fetch C_CHECK_GRP_HIER into L_filter_merch_level;
            close C_CHECK_GRP_HIER;
            if L_filter_merch_level is NULL then
               L_exists := FALSE;
            else
               L_exists := TRUE;
            end if;
         elsif I_filter_merch_level = 'P' then
            open C_CHECK_DEPT_HIER;
            fetch C_CHECK_DEPT_HIER into L_filter_merch_level;
            close C_CHECK_DEPT_HIER;
            if L_filter_merch_level is NULL then
               L_exists := FALSE;
            else
               L_exists := TRUE;
            end if;
         elsif I_filter_merch_level = 'C' then
            open C_CHECK_CLASS_HIER;
            fetch C_CHECK_CLASS_HIER into L_filter_merch_level;
            close C_CHECK_CLASS_HIER;
            if L_filter_merch_level is NULL then
               L_exists := FALSE;
            else
               L_exists := TRUE;
            end if;
         elsif I_filter_merch_level = 'S' then
            open C_CHECK_SUBCLASS_HIER;
            fetch C_CHECK_SUBCLASS_HIER into L_filter_merch_level;
            close C_CHECK_SUBCLASS_HIER;
            if L_filter_merch_level is NULL then
               L_exists := FALSE;
            else
               L_exists := TRUE;
            end if;
         end if;

         if L_exists = TRUE then
            if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                          'FLTM',
                                          L_filter_merch_level,
                                          L_code_desc) = FALSE then
               return FALSE;
             end if;
             O_error_message := SQL_LIB.CREATE_MSG('GRP_HIER_EXISTS', I_sec_group_id, L_code_desc, NULL);
             O_dup_exists := TRUE;
         end if;
      else
         if I_filter_merch_level = 'C' then
            if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                          'FLTM',
                                          'P',
                                          L_code_desc) = FALSE then
               return FALSE;
            end if;
            O_error_message := SQL_LIB.CREATE_MSG('DUP_HIER', I_sec_group_id, L_code_desc, I_filter_merch_id_class);
         elsif I_filter_merch_level = 'S' then
            if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                          'FLTM',
                                          'C',
                                          L_code_desc) = FALSE then
               return FALSE;
            end if;
            O_error_message := SQL_LIB.CREATE_MSG('DUP_HIER', I_sec_group_id, L_code_desc, I_filter_merch_id_subclass);
         else
            if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                          'FLTM',
                                          I_filter_merch_level,
                                          L_code_desc) = FALSE then
               return FALSE;
            end if;
            O_error_message := SQL_LIB.CREATE_MSG('DUP_HIER', I_sec_group_id, L_code_desc, I_filter_merch_id);
         end if;
         --
         O_dup_exists := TRUE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CHECK_DUP_GROUP_MERCH;

--------------------------------------------------------------------------------
-- CHECK_DUP_GROUP_ORG( )
--------------------------------------------------------------------------------
FUNCTION CHECK_DUP_GROUP_ORG(O_error_message    IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                             O_dup_exists       IN OUT  BOOLEAN,
                             I_sec_group_id     IN      FILTER_GROUP_ORG.SEC_GROUP_ID%TYPE,
                             I_filter_org_level IN      FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                             I_filter_org_id    IN      FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_GROUP_HIER_SQL.CHECK_DUP_GROUP_ORG';

   L_dummy              VARCHAR2(1);
   L_filter_org_level   FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE;
   L_code_desc          CODE_DETAIL.CODE_DESC%TYPE;
   L_exists             BOOLEAN;
   L_inv_parm           VARCHAR2(30)   := NULL;

   cursor C_CHECK_ORG is
      select 'X'
        from filter_group_org
       where sec_group_id = I_sec_group_id
         and filter_org_id = I_filter_org_id
         and filter_org_level = I_filter_org_level;

   cursor C_GET_CODE_DESC is
      select code_desc
        from code_detail
       where code_type = 'FLOW'
         and code = I_filter_org_level;

   cursor C_CHECK_CHAIN_HIER is
      select filter_org_level
        from filter_group_org fo
       where sec_group_id = I_sec_group_id
         and ((filter_org_level = 'A'
               and exists (select 'X'
                             from area a
                            where a.area = fo.filter_org_id
                              and a.chain = I_filter_org_id))
           or (filter_org_level = 'R'
               and exists (select 'X'
                             from region r
                            where r.region = fo.filter_org_id
                              and exists (select 'X'
                                            from area ar
                                           where ar.area = r.area
                                             and ar.chain = I_filter_org_id)))
           or (filter_org_level = 'D'
               and exists (select 'X'
                             from district d
                            where d.district = fo.filter_org_id
                              and exists (select 'X'
                                            from region r
                                           where r.region = d.region
                                             and exists (select 'X'
                                                           from area ar
                                                          where ar.area = r.area
                                                            and ar.chain = I_filter_org_id)))));

   cursor C_CHECK_AREA_HIER is
      select filter_org_level
        from filter_group_org fo
       where sec_group_id = I_sec_group_id
         and ((filter_org_level = 'C'
               and exists (select 'X'
                             from area a
                            where a.chain = fo.filter_org_id
                              and a.area = I_filter_org_id))
           or (filter_org_level = 'R'
               and exists (select 'X'
                             from region r
                            where r.region = fo.filter_org_id
                              and r.area = I_filter_org_id))
           or (filter_org_level = 'D'
               and exists (select 'X'
                             from district d
                            where d.district = fo.filter_org_id
                              and exists (select 'X'
                                            from region r
                                           where r.region = d.region
                                             and r.area = I_filter_org_id))));

   cursor C_CHECK_REGION_HIER is
      select filter_org_level
        from filter_group_org fo
       where sec_group_id = I_sec_group_id
         and ((filter_org_level = 'C'
               and exists (select 'X'
                             from area a
                            where a.chain = fo.filter_org_id
                              and exists (select 'X'
                                            from region r
                                           where r.area = a.area
                                             and r.region = I_filter_org_id)))
           or (filter_org_level = 'A'
               and exists (select 'X'
                             from region r
                            where r.area = fo.filter_org_id
                              and r.region = I_filter_org_id))
           or (filter_org_level = 'D'
               and exists (select 'X'
                             from district d
                            where d.district = fo.filter_org_id
                              and d.region = I_filter_org_id)));

   cursor C_CHECK_DISTRICT_HIER is
      select filter_org_level
        from filter_group_org fo
       where sec_group_id = I_sec_group_id
         and ((filter_org_level = 'C'
               and exists (select 'X'
                             from area a
                            where a.chain = fo.filter_org_id
                              and exists (select 'X'
                                            from region r
                                           where r.area = a.area
                                             and exists (select 'X'
                                                           from district d
                                                          where d.region = r.region
                                                            and d.district = I_filter_org_id))))
           or (filter_org_level = 'A'
               and exists (select 'X'
                             from region r
                            where r.area = fo.filter_org_id
                              and exists (select 'X'
                                            from district d
                                           where d.region = r.region
                                             and d.district = I_filter_org_id)))
           or (filter_org_level = 'R'
               and exists (select 'X'
                             from district d
                            where d.region = fo.filter_org_id
                              and d.district = I_filter_org_id)));


BEGIN
   if I_sec_group_id is NULL then
      L_inv_parm := 'I_sec_group_id';
   elsif I_filter_org_level is NULL then
      L_inv_parm := 'I_filter_org_level';
   elsif I_filter_org_id is NULL then
      L_inv_parm := 'I_filter_org_id';
   end if;

   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_parm,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   open C_GET_CODE_DESC;
   fetch C_GET_CODE_DESC into L_code_desc;
   if C_GET_CODE_DESC%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_LEVEL', NULL, NULL, NULL);
      return FALSE;
   else
      close C_GET_CODE_DESC;
      open C_CHECK_ORG;
      fetch C_CHECK_ORG into L_dummy;
      if C_CHECK_ORG%NOTFOUND then
         O_dup_exists := FALSE;

         if I_filter_org_level = 'C' then
            open C_CHECK_CHAIN_HIER;
            fetch C_CHECK_CHAIN_HIER into L_filter_org_level;
            if C_CHECK_CHAIN_HIER%NOTFOUND then
               L_exists := FALSE;
            else
               L_exists := TRUE;
            end if;
            close C_CHECK_CHAIN_HIER;
         elsif I_filter_org_level = 'A' then
            open C_CHECK_AREA_HIER;
            fetch C_CHECK_AREA_HIER into L_filter_org_level;
            if C_CHECK_AREA_HIER%NOTFOUND then
               L_exists := FALSE;
            else
               L_exists := TRUE;
            end if;
            close C_CHECK_AREA_HIER;
         elsif I_filter_org_level = 'R' then
            open C_CHECK_REGION_HIER;
            fetch C_CHECK_REGION_HIER into L_filter_org_level;
            if C_CHECK_REGION_HIER%NOTFOUND then
               L_exists := FALSE;
            else
               L_exists := TRUE;
            end if;
            close C_CHECK_REGION_HIER;
         elsif I_filter_org_level = 'D' then
            open C_CHECK_DISTRICT_HIER;
            fetch C_CHECK_DISTRICT_HIER into L_filter_org_level;
            if C_CHECK_DISTRICT_HIER%NOTFOUND then
               L_exists := FALSE;
            else
               L_exists := TRUE;
            end if;
            close C_CHECK_DISTRICT_HIER;
        end if;

         if L_exists = TRUE then
            if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                          'FLOW',
                                          L_filter_org_level,
                                          L_code_desc) = FALSE then
               return FALSE;
            end if;
            O_error_message := SQL_LIB.CREATE_MSG('GRP_HIER_EXISTS', I_sec_group_id, L_code_desc, NULL);
            O_dup_exists := TRUE;
         end if;
      else
         if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                       'FLOW',
                                       I_filter_org_level,
                                       L_code_desc) = FALSE then
            return FALSE;
         end if;
         O_dup_exists := TRUE;
         O_error_message := SQL_LIB.CREATE_MSG('DUP_HIER', I_sec_group_id, L_code_desc, I_filter_org_id);
      end if;
   end if;

   close C_CHECK_ORG;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END CHECK_DUP_GROUP_ORG;

--------------------------------------------------------------------------------
-- CHECK_GROUP_MERCH( )
--------------------------------------------------------------------------------
FUNCTION CHECK_GROUP_MERCH  (O_error_message IN OUT VARCHAR2,
                             O_exist         IN OUT BOOLEAN,
                             I_group_id      IN     sec_group.group_id%TYPE)
return BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_GROUP_HIER_SQL.CHECK_GROUP_MERCH';
   L_exist               VARCHAR2(1) := 'N';

   cursor C_MERCH_EXIST is
     select 'Y'
     from   filter_group_merch
     where  sec_group_id = I_group_id
     group by 'Y';
BEGIN
   if I_group_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_group_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   o_exist := FALSE;

   open C_MERCH_EXIST;
   fetch C_MERCH_EXIST into L_exist;
   close C_MERCH_EXIST;
   ---
   if L_exist = 'Y' then
      O_exist := TRUE;
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

END CHECK_GROUP_MERCH;

--------------------------------------------------------------------------------
-- CHECK_GROUP_ORG( )
--------------------------------------------------------------------------------
FUNCTION CHECK_GROUP_ORG  (O_error_message IN OUT VARCHAR2,
                           O_exist         IN OUT BOOLEAN,
                           I_group_id      IN     sec_group.group_id%TYPE)
return BOOLEAN IS

   L_program   VARCHAR2(64)  := 'FILTER_GROUP_HIER_SQL.CHECK_GROUP_ORG';
   L_exist     VARCHAR2(1)   := 'N';

   cursor C_ORG_EXIST is
     select 'Y'
     from   filter_group_org
     where  sec_group_id = I_group_id
     group by 'Y';
BEGIN
   if I_group_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_group_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   o_exist := FALSE;

   open C_ORG_EXIST;
   fetch C_ORG_EXIST into L_exist;
   close C_ORG_EXIST;
   ---
   if L_exist = 'Y' then
      O_exist := TRUE;
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

END CHECK_GROUP_ORG;

--------------------------------------------------------------------------------
-- DELETE_GROUP_MERCH( )
--------------------------------------------------------------------------------
FUNCTION DELETE_GROUP_MERCH(O_error_message            IN OUT VARCHAR2,
                            I_filter_merch_level       IN     FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE,
                            I_filter_merch_id          IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE,
                            I_filter_merch_id_class    IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE,
                            I_filter_merch_id_subclass IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE)
return BOOLEAN IS

   L_program             VARCHAR2(64)   := 'FILTER_GROUP_HIER_SQL.DELETE_GROUP_MERCH';
   L_inv_parm            VARCHAR2(30)   := NULL;

BEGIN
   if I_filter_merch_level is NULL then
      L_inv_parm := 'I_filter_merch_level';
   elsif I_filter_merch_id is NULL then
      L_inv_parm := 'I_filter_merch_id';
   elsif I_filter_merch_level = 'C' then
      if I_filter_merch_id_class is NULL then
         L_inv_parm := 'I_filter_merch_id_class';
      end if;
   elsif I_filter_merch_level = 'S' then
      if I_filter_merch_id_class is NULL then
         L_inv_parm := 'I_filter_merch_id_class';
      elsif I_filter_merch_id_subclass is NULL then
         L_inv_parm := 'I_filter_merch_id_subclass';
      end if;
   end if;

   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_parm,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   delete from filter_group_merch
    where filter_merch_level = I_filter_merch_level
      and filter_merch_id = I_filter_merch_id
      and nvl(filter_merch_id_class,-1) = nvl(I_filter_merch_id_class,-1)
      and nvl(filter_merch_id_subclass,-1) = nvl(I_filter_merch_id_subclass,-1);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				                    SQLERRM,
	  			                    L_program,
				                    to_char(SQLCODE));
      return FALSE;

END DELETE_GROUP_MERCH;

--------------------------------------------------------------------------------
-- DELETE_GROUP_ORG( )
--------------------------------------------------------------------------------
FUNCTION DELETE_GROUP_ORG(O_error_message    IN OUT VARCHAR2,
                          I_filter_org_level IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                          I_filter_org_id    IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE)
return BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_GROUP_HIER_SQL.DELETE_GROUP_ORG';
   L_inv_parm  VARCHAR2(30)   := NULL;

BEGIN
   if I_filter_org_level is NULL then
      L_inv_parm := 'I_filter_org_level';
   elsif I_filter_org_id is NULL then
      L_inv_parm := 'I_filter_org_id';
   end if;

   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_parm,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   delete from filter_group_org
         where filter_org_level = I_filter_org_level
           and filter_org_id = I_filter_org_id;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				                    SQLERRM,
	  			                    L_program,
				                    to_char(SQLCODE));
      return FALSE;

END DELETE_GROUP_ORG;

--------------------------------------------------------------------------------
-- VALIDATE_GROUP_ORG( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_GROUP_ORG(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_exist               IN OUT BOOLEAN,
                            I_filter_org_level    IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                            I_filter_org_id       IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_GROUP_ORG';
   L_code_desc  CODE_DETAIL.CODE_DESC%TYPE;
   L_inv_parm   VARCHAR2(30)   := NULL;

   cursor C_GET_ORG_CODE is
      select code_desc
        from code_detail
       where code_type = 'FLTO'
         and code = I_filter_org_level;

BEGIN
   if I_filter_org_level is NULL then
      L_inv_parm := 'I_filter_org_level';
   elsif I_filter_org_id is NULL then
      L_inv_parm := 'I_filter_org_id';
   end if;

   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_parm,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   open C_GET_ORG_CODE;
   fetch C_GET_ORG_CODE into L_code_desc;
   close C_GET_ORG_CODE;
   if L_code_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_LEVEL', NULL, NULL, NULL);
      return FALSE;
   end if;

   if VALIDATE_DIFF_GROUP_HEAD(O_error_message,
                               O_exist,
                               NULL,
                               NULL,
                               I_filter_org_level,
                               I_filter_org_id,
                               NULL,
                               NULL) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_DIFF_GROUP', L_code_desc, I_filter_org_id, NULL);
      return TRUE;
   end if;

   if VALIDATE_LOC_LIST_HEAD(O_error_message,
                             O_exist,
                             I_filter_org_level,
                             I_filter_org_id) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_LOC_LIST', L_code_desc, I_filter_org_id, NULL);
      return TRUE;
   end if;

   if VALIDATE_LOC_TRAITS(O_error_message,
                          O_exist,
                          I_filter_org_level,
                          I_filter_org_id) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_LOC_TRAIT', L_code_desc, I_filter_org_id, NULL);
      return TRUE;
   end if;

   if VALIDATE_SKULIST_HEAD(O_error_message,
                            O_exist,
                            I_filter_org_level,
                            I_filter_org_id) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_ITEM_LIST', L_code_desc, I_filter_org_id, NULL);
      return TRUE;
   end if;

   if VALIDATE_SEASONS(O_error_message,
                       O_exist,
                       NULL,
                       NULL,
                       I_filter_org_level,
                       I_filter_org_id,
                       NULL,
                       NULL) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_SEASON', L_code_desc, I_filter_org_id, NULL);
      return TRUE;
   end if;

   if VALIDATE_TICKET_TYPE_HEAD(O_error_message,
                                O_exist,
                                NULL,
                                NULL,
                                I_filter_org_level,
                                I_filter_org_id,
                                NULL,
                                NULL) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_TICKET', L_code_desc, I_filter_org_id, NULL);
      return TRUE;
   end if;

   if VALIDATE_UDA(O_error_message,
                   O_exist,
                   NULL,
                   NULL,
                   I_filter_org_level,
                   I_filter_org_id,
                   NULL,
                   NULL) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_UDA', L_code_desc, I_filter_org_id, NULL);
      return TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END VALIDATE_GROUP_ORG;

--------------------------------------------------------------------------------
-- VALIDATE_GROUP_MERCH( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_GROUP_MERCH(O_error_message            IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exist                    IN OUT BOOLEAN,
                              I_filter_merch_level       IN     FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE,
                              I_filter_merch_id          IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE,
                              I_filter_merch_id_class    IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE,
                              I_filter_merch_id_subclass IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_GROUP_MERCH';
   L_code_desc  CODE_DETAIL.CODE_DESC%TYPE;
   L_inv_parm   VARCHAR2(30)   := NULL;
   L_merch_id   FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE;

   cursor C_GET_ORG_CODE is
      select code_desc
        from code_detail
       where code_type = 'FLTM'
         and code = I_filter_merch_level;

BEGIN
   if I_filter_merch_level is NULL then
      L_inv_parm := 'I_filter_merch_level';
   elsif I_filter_merch_id is NULL then
      L_inv_parm := 'I_filter_merch_id';
   end if;

   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_parm,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   open C_GET_ORG_CODE;
   fetch C_GET_ORG_CODE into L_code_desc;
   close C_GET_ORG_CODE;
   if L_code_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_MERCH_LEVEL', NULL, NULL, NULL);
      return FALSE;
   end if;

   if I_filter_merch_level in ('D','G','P') then
      L_merch_id := I_filter_merch_id;
   elsif I_filter_merch_level = 'C' then
      L_merch_id := I_filter_merch_id_class;
   elsif I_filter_merch_level = 'S' then
      L_merch_id := I_filter_merch_id_subclass;
   end if;

   if VALIDATE_DIFF_GROUP_HEAD(O_error_message,
                               O_exist,
                               I_filter_merch_level,
                               I_filter_merch_id,
                               NULL,
                               NULL,
                               I_filter_merch_id_class,
                               I_filter_merch_id_subclass) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_DIFF_GROUP', L_code_desc, L_merch_id, NULL);
      return TRUE;
   end if;

   if VALIDATE_SEASONS(O_error_message,
                       O_exist,
                       I_filter_merch_level,
                       I_filter_merch_id,
                       NULL,
                       NULL,
                       I_filter_merch_id_class,
                       I_filter_merch_id_subclass) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_SEASON', L_code_desc, L_merch_id, NULL);
      return TRUE;
   end if;

   if VALIDATE_TICKET_TYPE_HEAD(O_error_message,
                                O_exist,
                                I_filter_merch_level,
                                I_filter_merch_id,
                                NULL,
                                NULL,
                                I_filter_merch_id_class,
                                I_filter_merch_id_subclass) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_TICKET', L_code_desc, L_merch_id, NULL);
      return TRUE;
   end if;

   if VALIDATE_UDA(O_error_message,
                   O_exist,
                   I_filter_merch_level,
                   I_filter_merch_id,
                   NULL,
                   NULL,
                   I_filter_merch_id_class,
                   I_filter_merch_id_subclass) = FALSE then
      return FALSE;
   end if;
   if O_exist then
      O_error_message := SQL_LIB.CREATE_MSG('HIER_EXISTS_UDA', L_code_desc, L_merch_id, NULL);
      return TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END VALIDATE_GROUP_MERCH;

--------------------------------------------------------------------------------
-- VALIDATE_GROUP_MERCH( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_GROUP_MERCH(O_error_message       IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exist               IN OUT  BOOLEAN,
                              I_filter_merch_level  IN      FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE,
                              I_filter_merch_id     IN      FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE,
                              I_user_id             IN      SEC_USER_GROUP.USER_ID%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_GROUP_MERCH';
   L_dummy      VARCHAR2(1)    := NULL;
   L_inv_parm   VARCHAR2(30)   := NULL;

   cursor C_CHECK_FILTER_GROUP is
      select 'x'
        from filter_group_merch fgm,
             sec_user_group     sug
       where fgm.filter_merch_id    = I_filter_merch_id
         and fgm.filter_merch_level = I_filter_merch_level
         and fgm.sec_group_id       = sug.group_id
         and sug.user_id            = I_user_id
       group by 'x';

BEGIN
   O_exist := FALSE;
   O_error_message := NULL;

   if I_filter_merch_level is NULL then
      L_inv_parm := 'I_filter_merch_level';
   elsif I_filter_merch_id is NULL then
      L_inv_parm := 'I_filter_merch_id';
   elsif I_user_id is NULL then
      L_inv_parm := 'I_user_id';
   end if;

   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_parm,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_FILTER_GROUP', 'FILTER_GROUP_MERCH', NULL );
   open C_CHECK_FILTER_GROUP;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_FILTER_GROUP',
                    'FILTER_GROUP_MERCH',
                    'user_id: '||I_user_id||', filter_merch_level: '||I_filter_merch_level||', filter_merch_id: '||I_filter_merch_id);
   fetch C_CHECK_FILTER_GROUP into L_dummy;

   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_FILTER_GROUP', 'FILTER_GROUP_MERCH', NULL );
   close C_CHECK_FILTER_GROUP;

   if L_dummy = 'x' then
      O_exist := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,L_program,to_char(SQLCODE));
      return FALSE;

END VALIDATE_GROUP_MERCH;


--------------------------------------------------------------------------------
-- VALIDATE_DIFF_GROUP_HEAD( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_DIFF_GROUP_HEAD(O_error_message            IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_exist                    IN OUT BOOLEAN,
                                  I_filter_merch_level       IN     FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE,
                                  I_filter_merch_id          IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE,
                                  I_filter_org_level         IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                                  I_filter_org_id            IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE,
                                  I_filter_merch_id_class    IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE,
                                  I_filter_merch_id_subclass IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_DIFF_GROUP_HEAD';
   L_dummy          VARCHAR2(1);

   cursor C_CHECK_EXISTS is
      select 'X'
        from diff_group_head d, system_options s
       where d.filter_merch_id = nvl(I_filter_merch_id, -1)
         and s.diff_group_merch_level_code = nvl(I_filter_merch_level, '?')
         and nvl(d.filter_merch_id_class, -1) = nvl(I_filter_merch_id_class, -1)
         and nvl(d.filter_merch_id_subclass, -1) = nvl(I_filter_merch_id_subclass, -1)
       union
      select 'X'
        from diff_group_head , system_options s
       where filter_org_id = nvl(I_filter_org_id, -1)
         and s.diff_group_org_level_code = nvl(I_filter_org_level, '?');

BEGIN
   O_exist := TRUE;
   open C_CHECK_EXISTS;
   fetch C_CHECK_EXISTS into L_dummy;
   close C_CHECK_EXISTS;
   if L_dummy is NULL then
      O_exist := FALSE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END VALIDATE_DIFF_GROUP_HEAD;

--------------------------------------------------------------------------------
-- VALIDATE_LOC_LIST_HEAD( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_LOC_LIST_HEAD(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_exist             IN OUT BOOLEAN,
                                I_filter_org_level  IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                                I_filter_org_id     IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_LOC_LIST_HEAD';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_EXISTS is
      select 'X'
        from loc_list_head , system_options s
       where filter_org_id = nvl(I_filter_org_id, -1)
         and s.loc_list_org_level_code = nvl(I_filter_org_level, '?');

BEGIN
   O_exist := TRUE;
   open C_CHECK_EXISTS;
   fetch C_CHECK_EXISTS into L_dummy;
   if C_CHECK_EXISTS%NOTFOUND then
      O_exist := FALSE;
   end if;
   close C_CHECK_EXISTS;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END VALIDATE_LOC_LIST_HEAD;

--------------------------------------------------------------------------------
-- VALIDATE_LOC_TRAITS( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_LOC_TRAITS(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exist             IN OUT BOOLEAN,
                             I_filter_org_level  IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                             I_filter_org_id     IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_LOC_TRAITS';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_EXISTS is
      select 'X'
        from loc_traits , system_options s
       where filter_org_id = nvl(I_filter_org_id, -1)
         and s.loc_trait_org_level_code = nvl(I_filter_org_level, '?');

BEGIN
   O_exist := TRUE;
   open C_CHECK_EXISTS;
   fetch C_CHECK_EXISTS into L_dummy;
   if C_CHECK_EXISTS%NOTFOUND then
      O_exist := FALSE;
   end if;
   close C_CHECK_EXISTS;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END VALIDATE_LOC_TRAITS;

--------------------------------------------------------------------------------
-- VALIDATE_SKULIST_HEAD( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_SKULIST_HEAD(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_exist               IN OUT BOOLEAN,
                               I_filter_org_level    IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                               I_filter_org_id       IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_SKULIST_HEAD';
   L_dummy          VARCHAR2(1);

   cursor C_CHECK_EXISTS is
      select 'X'
        from skulist_head , system_options s
       where filter_org_id = nvl(I_filter_org_id, -1)
         and s.skulist_org_level_code = nvl(I_filter_org_level, '?');

BEGIN
   O_exist := TRUE;
   open C_CHECK_EXISTS;
   fetch C_CHECK_EXISTS into L_dummy;
   if C_CHECK_EXISTS%NOTFOUND then
      O_exist := FALSE;
   end if;
   close C_CHECK_EXISTS;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END VALIDATE_SKULIST_HEAD;

--------------------------------------------------------------------------------
-- VALIDATE_SEASONS( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_SEASONS(O_error_message            IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          O_exist                    IN OUT BOOLEAN,
                          I_filter_merch_level       IN     FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE,
                          I_filter_merch_id          IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE,
                          I_filter_org_level         IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                          I_filter_org_id            IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE,
                          I_filter_merch_id_class    IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE,
                          I_filter_merch_id_subclass IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_SEASONS';
   L_dummy          VARCHAR2(1);

   cursor C_CHECK_EXISTS is
      select 'X'
        from seasons e, system_options s
       where e.filter_merch_id = nvl(I_filter_merch_id, -1)
         and s.season_merch_level_code = nvl(I_filter_merch_level, '?')
         and nvl(e.filter_merch_id_class, -1) = nvl(I_filter_merch_id_class, -1)
         and nvl(e.filter_merch_id_subclass, -1) = nvl(I_filter_merch_id_subclass, -1)
       union
      select 'X'
        from seasons , system_options s
       where filter_org_id = nvl(I_filter_org_id, -1)
         and s.season_org_level_code = nvl(I_filter_org_level, '?');

BEGIN
   O_exist := TRUE;
   open C_CHECK_EXISTS;
   fetch C_CHECK_EXISTS into L_dummy;
   close C_CHECK_EXISTS;
   if L_dummy is NULL then
      O_exist := FALSE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END VALIDATE_SEASONS;

--------------------------------------------------------------------------------
-- VALIDATE_TICKET_TYPE_HEAD( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_TICKET_TYPE_HEAD(O_error_message            IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_exist                    IN OUT BOOLEAN,
                                   I_filter_merch_level       IN     FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE,
                                   I_filter_merch_id          IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE,
                                   I_filter_org_level         IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                                   I_filter_org_id            IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE,
                                   I_filter_merch_id_class    IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE,
                                   I_filter_merch_id_subclass IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_TICKET_TYPE_HEAD';
   L_dummy          VARCHAR2(1);

   cursor C_CHECK_EXISTS is
      select 'X'
        from ticket_type_head t, system_options s
       where t.filter_merch_id = nvl(I_filter_merch_id, -1)
         and s.ticket_type_merch_level_code = nvl(I_filter_merch_level, '?')
         and nvl(t.filter_merch_id_class, -1) = nvl(I_filter_merch_id_class, -1)
         and nvl(t.filter_merch_id_subclass, -1) = nvl(I_filter_merch_id_subclass, -1)
       union
      select 'X'
        from ticket_type_head , system_options s
       where filter_org_id = nvl(I_filter_org_id, -1)
         and s.ticket_type_org_level_code = nvl(I_filter_org_level, '?');

BEGIN
   O_exist := TRUE;
   open C_CHECK_EXISTS;
   fetch C_CHECK_EXISTS into L_dummy;
   close C_CHECK_EXISTS;
   if L_dummy is NULL then
      O_exist := FALSE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END VALIDATE_TICKET_TYPE_HEAD;

--------------------------------------------------------------------------------
-- VALIDATE_UDA( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_UDA(O_error_message            IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                      O_exist                    IN OUT BOOLEAN,
                      I_filter_merch_level       IN     FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE,
                      I_filter_merch_id          IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE,
                      I_filter_org_level         IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                      I_filter_org_id            IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE,
                      I_filter_merch_id_class    IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE,
                      I_filter_merch_id_subclass IN     FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(64)   := 'VALIDATE_GROUP_HIER_SQL.VALIDATE_TICKET_TYPE_HEAD';
   L_dummy          VARCHAR2(1);

   cursor C_CHECK_EXISTS is
      select 'X'
        from uda u, system_options s
       where u.filter_merch_id = nvl(I_filter_merch_id, -1)
         and s.uda_merch_level_code = nvl(I_filter_merch_level, '?')
         and nvl(u.filter_merch_id_class, -1) = nvl(I_filter_merch_id_class, -1)
         and nvl(u.filter_merch_id_subclass, -1) = nvl(I_filter_merch_id_subclass, -1)
       union
      select 'X'
        from uda , system_options s
       where filter_org_id = nvl(I_filter_org_id, -1)
         and s.uda_org_level_code = nvl(I_filter_org_level, '?');

BEGIN
   O_exist := TRUE;
   open C_CHECK_EXISTS;
   fetch C_CHECK_EXISTS into L_dummy;
   close C_CHECK_EXISTS;
   if L_dummy is NULL then
      O_exist := FALSE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;

END VALIDATE_UDA;
--------------------------------------------------------------------------------
FUNCTION LOCK_FILTER_GROUP_RECORD(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_locked_ind     IN OUT  BOOLEAN,
                                  I_merch_org      IN      VARCHAR2,
                                  I_sec_group_id   IN      FILTER_GROUP_MERCH.SEC_GROUP_ID%TYPE,
                                  I_filter_level   IN      FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                                  I_filter_id      IN      NUMBER,
                                  I_class          IN      FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE,
                                  I_subclass       IN      FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(61) := 'FILTER_GROUP_HIER_SQL.LOCK_FILTER_GROUP_RECORD';
   L_inv_param      VARCHAR2(30);
   L_table          VARCHAR2(30);
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_MERCH is
      select 'x'
        from filter_group_merch
       where sec_group_id              = I_sec_group_id
         and filter_merch_level        = I_filter_level
         and filter_merch_id           = I_filter_id
         and nvl(filter_merch_id_class, -1) = nvl(I_class, -1)
         and nvl(filter_merch_id_subclass, -1) = nvl(I_subclass, -1)
         for update nowait;

   cursor C_LOCK_ORG is
      select 'x'
        from filter_group_org
       where sec_group_id     = I_sec_group_id
         and filter_org_level = I_filter_level
         and filter_org_id    = I_filter_id
         for update nowait;
   -- Mod N147, 9-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   cursor C_LOCK_NON_MERCH is
   select 'X'
     from tsl_filter_group_non_merch
    where sec_group_id   = I_sec_group_id
      and non_merch_code = I_filter_id
      for update nowait;
   -- Mod N147, 9-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
BEGIN

   if I_merch_org is NULL then
      L_inv_param := 'I_merch_org';
   elsif I_sec_group_id is NULL then
      L_inv_param := 'I_sec_group_id';
   -- Mod N147, 9-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   elsif I_filter_level is NULL and I_merch_org <> 'NON_MERCH' then
   -- Mod N147, 9-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
      L_inv_param := 'I_filter_level';
   elsif I_filter_id is NULL then
      L_inv_param := 'I_filter_id';
   end if;

   if L_inv_param is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_param,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   L_table := 'FILTER_GROUP_'||I_merch_org;

   if I_merch_org = 'MERCH' then
      open  C_LOCK_MERCH;
      close C_LOCK_MERCH;
   -- Mod N147, 9-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   elsif I_merch_org = 'NON_MERCH' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_NON_MERCH',
                       'TSL_FILTER_GROUP_NON_MERCH',
                       'Security Group ID = ' ||I_sec_group_id|| ', Non Merch Code = ' ||I_filter_id);
      open  C_LOCK_NON_MERCH;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_NON_MERCH',
                       'TSL_FILTER_GROUP_NON_MERCH',
                       'Security Group ID: '||I_sec_group_id||', Non Merch Code: '||I_filter_id);
      close C_LOCK_NON_MERCH;
   -- Mod N147, 9-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
   else  -- I_merch_org = 'ORG'
      open  C_LOCK_ORG;
      close C_LOCK_ORG;
   end if;

   O_locked_ind := TRUE;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_locked_ind := FALSE;
      return TRUE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				            SQLERRM,
	  			            L_program,
				            to_char(SQLCODE));
      return FALSE;
END LOCK_FILTER_GROUP_RECORD;
--------------------------------------------------------------------------------
-- Mod N147, 9-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
--------------------------------------------------------------------------------
-- Name   : TSL_CHECK_DUP_GROUP_NON_MERCH
-- Purpose: To Check the Group id/ non-merch code keyed-in is available in
--          TSL_FILTER_GROUP_NON_MERCH table
--------------------------------------------------------------------------------
   FUNCTION TSL_CHECK_DUP_GROUP_NON_MERCH (O_error_message  IN OUT NOCOPY  RTK_ERRORS.RTK_TEXT%TYPE,
                                           O_dup_exists     IN OUT NOCOPY  BOOLEAN,
                                           I_sec_group_id   IN             TSL_FILTER_GROUP_NON_MERCH.SEC_GROUP_ID%TYPE,
                                           I_non_merch_code IN             TSL_FILTER_GROUP_NON_MERCH.NON_MERCH_CODE%TYPE)
      RETURN BOOLEAN IS

      L_program           VARCHAR2(61) := 'FILTER_GROUP_HIER_SQL.TSL_CHECK_DUP_GROUP_NON_MERCH';
      L_table             VARCHAR2(50) := 'TSL_FILTER_GROUP_NON_MERCH';
      L_test_value        VARCHAR2(1);
      --
      cursor C_CHECK_NON_MERCH is
      select 'X'
        from tsl_filter_group_non_merch
       where sec_group_id   = I_sec_group_id
         and non_merch_code = I_non_merch_code;

   BEGIN
      ---
      if I_sec_group_id is NULL then
          O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                                'I_sec_group_id',
                                                'NULL',
                                                'NOT NULL');
          return FALSE;
      end if;
      --
      if I_non_merch_code is NULL then
          O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                                'I_non_merch_code',
                                                'NULL',
                                                'NOT NULL');
          return FALSE;
      end if;
      --
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_NON_MERCH',
                       L_table,
                       'Security Group ID: ' || I_sec_group_id || ', NON MERCH CODE: ' || I_non_merch_code);
      open C_CHECK_NON_MERCH;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_NON_MERCH',
                       L_table,
                       'Security Group ID: ' || I_sec_group_id || ', NON MERCH CODE: ' || I_non_merch_code);
      fetch C_CHECK_NON_MERCH into L_test_value;
      --
      if C_CHECK_NON_MERCH%FOUND then
         O_dup_exists := TRUE;
      else
         O_dup_exists := FALSE;
      end if;
      --
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_NON_MERCH',
                       L_table,
                       'Security Group ID: ' || I_sec_group_id || ', NON MERCH CODE: ' || I_non_merch_code);
      close C_CHECK_NON_MERCH;
      ---

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
		   		                                     SQLERRM,
	     			                                   L_program,
		   		                                     TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_CHECK_DUP_GROUP_NON_MERCH;
--------------------------------------------------------------------------------
-- Name   : TSL_SET_DISPLAY_MERCH_IND
-- Purpose: This functions updates the value in the table MULTIVIEW_DEFAULT_45 accordingly,
--          based on which the column MERCH_IND is displayed or hidden in fixed deal form.
--------------------------------------------------------------------------------
FUNCTION TSL_SET_DISPLAY_MERCH_IND(O_error_message    IN OUT NOCOPY  RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_org_field_status IN OUT NOCOPY  MULTIVIEW_DEFAULT_45.FIELD_STATUS%TYPE,
                                   O_update_status    IN OUT NOCOPY  VARCHAR2,
                                   I_field_status     IN             MULTIVIEW_DEFAULT_45.FIELD_STATUS%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(50) := 'FILTER_GROUP_HIER_SQL.TSL_SET_DISPLAY_MERCH_IND';
   L_table           VARCHAR2(50) := 'MULTIVIEW_DEFAULT_45';
   --
   E_record_locked   EXCEPTION;

   PRAGMA EXCEPTION_INIT(E_record_locked, -54);
   PRAGMA AUTONOMOUS_TRANSACTION;
   --
   CURSOR C_LOCK_MULTIVIEW_DFLT is
   select field_status
     from multiview_default_45
    where fm_name  = 'FM_FIXEDDEAL'
      and col_name = 'B_FIXED_DEAL.MERCH_IND'
      for update nowait;

BEGIN
   ---
   O_update_status := 'N';
   --
   if I_field_status is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_field_status',
                                            L_program,
                                            'NULL');
      return FALSE;
   end if;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_MULTIVIEW_DFLT',
                    L_table,
                    'Form Name: FM_FIXEDDEAL, Column Name: B_FIXED_DEAL.MERCH_IND');
   open C_LOCK_MULTIVIEW_DFLT;
   SQL_LIB.SET_MARK('FETCH',
                    'C_LOCK_MULTIVIEW_DFLT',
                    L_table,
                    'Form Name: FM_FIXEDDEAL, Column Name: B_FIXED_DEAL.MERCH_IND');
   fetch C_LOCK_MULTIVIEW_DFLT into O_org_field_status;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_MULTIVIEW_DFLT',
                    L_table,
                    'Form Name: FM_FIXEDDEAL, Column Name: B_FIXED_DEAL.MERCH_IND');
   close C_LOCK_MULTIVIEW_DFLT;
   --
   if I_field_status <> O_org_field_status then
      --
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       L_table,
                       'Form Name: FM_FIXEDDEAL, Column Name: B_FIXED_DEAL.MERCH_IND');
      update multiview_default_45
         set field_status = I_field_status
       where fm_name      = 'FM_FIXEDDEAL'
         and col_name     = 'B_FIXED_DEAL.MERCH_IND';
      --
      O_update_status := 'Y';
      --
   end if;
   --
   COMMIT;

   return TRUE;

EXCEPTION
   --
   when E_record_locked then
     O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                           L_table,
                                           'Form Name: FM_FIXEDDEAL, Column Name: B_FIXED_DEAL.MERCH_IND',
                                           NULL);
     return FALSE;
   --
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
   		                                    SQLERRM,
    			                                  L_program,
   		                                    TO_CHAR(SQLCODE));
      return FALSE;
   --
END TSL_SET_DISPLAY_MERCH_IND;
--------------------------------------------------------------------------------
-- Mod N147, 9-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
---------------------------------------------------------------------------------------
-- CR236a, 11-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
---------------------------------------------------------------------------------------
FUNCTION TSL_FILTER_COUNTRY (O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_uk_ind           IN OUT VARCHAR2,
                             O_roi_ind          IN OUT VARCHAR2)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(50) := 'FILTER_GROUP_HIER_SQL.TSL_FILTER_COUNTRY';
   L_chain           AREA.CHAIN%TYPE;

   CURSOR C_SEC_GROUP is
     select group_id
       from sec_user_group
      where user_id = USER;

   CURSOR C_FLTR_ORG (I_group_id VARCHAR2) is
     select filter_org_level,
            filter_org_id
       from filter_group_org
      where sec_group_id = I_group_id;

   CURSOR C_AREA (I_org_id NUMBER) is
     select chain
       from area
      where area = I_org_id;

   CURSOR C_REGION (I_region NUMBER) is
     select a.chain
       from area a,
            region r
      where r.region = I_region
        and a.area = r.area;

   CURSOR C_DISTRICT (I_district NUMBER) is
     select a.chain
       from area a,
            region r,
            district d
      where d.district = I_district
        and r.region = d.region
        and a.area = r.area;

   CURSOR C_WH (I_wh NUMBER) is
     select tsf_entity_id
       from wh
      where wh = I_wh;

   CURSOR C_EXTERNAL (I_partner NUMBER) is
     select tsf_entity_id
       from partner
      where partner_id = I_partner;

   L_group_id        NUMBER(4);

BEGIN
   ---
   O_uk_ind := 'N';
   O_roi_ind := 'N';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_SEC_GROUP',
                    'SEC_USER_GROUP',
                    'USER_ID : '||USER);
   open C_SEC_GROUP;
   SQL_LIB.SET_MARK('FETCH',
                    'C_SEC_GROUP',
                    'SEC_USER_GROUP',
                    'USER_ID : '||USER);
   fetch C_SEC_GROUP into L_group_id;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_SEC_GROUP',
                    'SEC_USER_GROUP',
                    'USER_ID : '||USER);
   close C_SEC_GROUP;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_FLTR_ORG',
                    'FILTER_GROUP_ORG',
                    NULL);
   FOR C_rec in C_FLTR_ORG(L_group_id)
   LOOP
      if C_rec.filter_org_level = 'C' then
         L_chain := C_rec.filter_org_id;
      elsif C_rec.filter_org_level = 'A' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_AREA',
                          'AREA',
                          'AREA : '||C_rec.filter_org_id);
         open C_AREA(C_rec.filter_org_id);
         SQL_LIB.SET_MARK('FETCH',
                          'C_AREA',
                          'AREA',
                          'AREA : '||C_rec.filter_org_id);
         fetch C_AREA into L_chain;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_AREA',
                          'AREA',
                          'AREA : '||C_rec.filter_org_id);
         close C_AREA;
      elsif C_rec.filter_org_level = 'R' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_REGION',
                          'AREA, REGION',
                          'REGION : '||C_rec.filter_org_id);
         open C_REGION(C_rec.filter_org_id);
         SQL_LIB.SET_MARK('FETCH',
                          'C_REGION',
                          'AREA, REGION',
                          'REGION : '||C_rec.filter_org_id);
         fetch C_REGION into L_chain;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_REGION',
                          'AREA, REGION',
                          'REGION : '||C_rec.filter_org_id);
         close C_REGION;
      elsif C_rec.filter_org_level = 'D' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_DISTRICT',
                          'AREA, REGION, DISTRICT',
                          'DISTRICT : '||C_rec.filter_org_id);
         open C_DISTRICT(C_rec.filter_org_id);
         SQL_LIB.SET_MARK('FETCH',
                          'C_DISTRICT',
                          'AREA, REGION, DISTRICT',
                          'DISTRICT : '||C_rec.filter_org_id);
         fetch C_DISTRICT into L_chain;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_DISTRICT',
                          'AREA, REGION, DISTRICT',
                          'DISTRICT : '||C_rec.filter_org_id);
         close C_DISTRICT;
      elsif C_rec.filter_org_level in ('W','I') then
         SQL_LIB.SET_MARK('OPEN',
                          'C_WH',
                          'WH',
                          'WH : '||C_rec.filter_org_id);
         open C_WH(C_rec.filter_org_id);
         SQL_LIB.SET_MARK('FETCH',
                          'C_WH',
                          'WH',
                          'WH : '||C_rec.filter_org_id);
         fetch C_WH into L_chain;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_WH',
                          'WH',
                          'WH : '||C_rec.filter_org_id);
         close C_WH;
      elsif C_rec.filter_org_level = 'E' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_EXTERNAL',
                          'PARTNER',
                          'PARTNER : '||C_rec.filter_org_id);
         open C_EXTERNAL(C_rec.filter_org_id);
         SQL_LIB.SET_MARK('FETCH',
                          'C_EXTERNAL',
                          'PARTNER',
                          'PARTNER : '||C_rec.filter_org_id);
         fetch C_EXTERNAL into L_chain;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EXTERNAL',
                          'PARTNER',
                          'PARTNER : '||C_rec.filter_org_id);
         close C_EXTERNAL;
      elsif C_rec.filter_org_level = 'T' then
         L_chain := C_rec.filter_org_id;
      end if;
      ---
      if L_chain = 1 then
         O_uk_ind := 'Y';
         if O_roi_ind != 'Y' then
            O_roi_ind := 'N';
         end if;
      else
         O_roi_ind := 'Y';
         if O_uk_ind != 'Y' then
            O_uk_ind := 'N';
         end if;
      end if;
      ---
   END LOOP;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_AREA%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_AREA',
                          'AREA',
                          'AREA : '||L_group_id);
         close C_AREA;
      end if;
      ---
      if C_REGION%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_REGION',
                          'AREA, REGION',
                          'REGION : '||L_group_id);
         close C_REGION;
      end if;
      ---
      if C_DISTRICT%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_DISTRICT',
                          'AREA, REGION, DISTRICT',
                          'DISTRICT : '||L_group_id);
         close C_DISTRICT;
      end if;
      ---
      if C_WH%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_WH',
                          'WH',
                          'WH : '||L_group_id);
         close C_WH;
      end if;
      ---
      if C_EXTERNAL%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EXTERNAL',
                          'PARTNER',
                          'PARTNER : '||L_group_id);
         close C_EXTERNAL;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
   		                                      SQLERRM,
    			                                  L_program,
   		                                      TO_CHAR(SQLCODE));
      return FALSE;
   --
END TSL_FILTER_COUNTRY;
---------------------------------------------------------------------------------------
-- CR236a, 11-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
---------------------------------------------------------------------------------------
-- 17-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 Begin
---------------------------------------------------------------------------------------
FUNCTION TSL_USER_COUNTRY(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          O_uk_ind           IN OUT VARCHAR2,
                          O_roi_ind          IN OUT VARCHAR2)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(50) := 'FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY';
   L_chain           AREA.CHAIN%TYPE;
   L_user_cntry      VARCHAR2(1);

   -- 01-Sep-2010, DefNBS018961, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   -- Changed the from user_role_privs to dba_role_privs and added grantee condition
   CURSOR C_USER_COUNTRY is
   select granted_role
     from dba_role_privs
    where granted_role in ('TSLF_UK_RW','TSLF_ROI_RW')
      and grantee = USER;
   -- 01-Sep-2010, DefNBS018961, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
BEGIN
   ---
   O_uk_ind := 'N';
   O_roi_ind := 'N';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_USER_COUNTRY',
                    'USER_ROLE_PRIVS',
                    NULL);

   for rec1 in C_USER_COUNTRY
   LOOP
     if rec1.granted_role = 'TSLF_UK_RW' then
        O_uk_ind := 'Y';
     elsif rec1.granted_role = 'TSLF_ROI_RW' then
        O_roi_ind := 'Y';
     end if;
   END LOOP;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_USER_COUNTRY',
                    'USER_ROLE_PRIVS',
                    NULL);
   -- 31-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com 18915 Begin
   --Removed the code below
   -- 31-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com 18915 End

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
   --
END TSL_USER_COUNTRY;
---------------------------------------------------------------------------------------
-- 17-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 End
---------------------------------------------------------------------------------------
END FILTER_GROUP_HIER_SQL;
/

