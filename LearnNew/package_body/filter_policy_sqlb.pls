CREATE OR REPLACE PACKAGE BODY FILTER_POLICY_SQL AS
-----------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Bahubali Dongare, Bahubali.Dongare@in.tesco.com
--Mod Date:    10-Apr-2008
--Defect Ref:  NBS00006112
--Mod Details: Changed the size of the L_predicate from VARCHAR2(3000) to VARCHAR2(15000) in the function
-- V_TICKET_TYPE_HEAD_S as the function ASSEMBLY has the return value with VARCHAR2(15000)
-----------------------------------------------------------------------------------------------------
--Mod By     : Yashavantharaja M.T , yashavantharaja.thimmesh@in.tesco.com
--Mod Date   : 24-Nov-2010
--Mod Ref    : MrgNBS019839
--Mod Details: Merge the latest version of file in MrgNBS019839 branch with the latest in MrgNBS019839.src2 branch.
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- SET_USER_FILTER()
--------------------------------------------------------------------------------
FUNCTION SET_USER_FILTER(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

   L_data_level_security_ind   SYSTEM_OPTIONS.DATA_LEVEL_SECURITY_IND%TYPE;

   CURSOR C_GET_SYSTEM_LEVELS IS
      SELECT data_level_security_ind,
             diff_group_org_level_code,
             loc_list_org_level_code,
             loc_trait_org_level_code,
             season_org_level_code,
             skulist_org_level_code,
             ticket_type_org_level_code,
             uda_org_level_code,
             diff_group_merch_level_code,
             season_merch_level_code,
             ticket_type_merch_level_code,
             uda_merch_level_code,
             -- 10-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 Begin
             tsl_loc_sec_ind
             -- 10-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 End
        FROM SYSTEM_OPTIONS;

   -- The C_FIND_GROUP cursor is used to catch the scenario where a user is not
   -- associated to any group.  If this is the case, they are not a super-user,
   -- and security must be applied, even though the user will not have visibilty
   -- to any data.
   CURSOR C_FIND_GROUP IS
      SELECT 'Y'
        FROM SEC_USER_GROUP sug
       WHERE sug.user_id = SYS_CONTEXT('USERENV', 'SESSION_USER')
         AND ROWNUM = 1;

   -- When a user is associated to a group that is not associated to any
   -- hierarchy, the C_FILTER_USER_ORG cursor returns no rows.  This cursor
   -- also returns no rows if the user is not associated to any group, however
   -- if the C_FIND_GROUP cursor is fetched before this cursor, we can ensure
   -- that the C_FILTER_USER_ORG cursor is never executed in this second scenario.
   -- That being said, if the C_FILTER_USER_ORG cursor returns no rows (indicating
   -- the first scenario mentioned in this comment), then the user is associated
   -- to a group that is not associated to a hierarchy, and is therefore a super-
   -- user.
   CURSOR C_FILTER_USER_ORG IS
      SELECT 'Y'
        FROM SEC_USER_GROUP sug
       WHERE sug.user_id = SYS_CONTEXT('USERENV', 'SESSION_USER')
         AND (EXISTS(SELECT 'x'
                       FROM FILTER_GROUP_ORG fgo
                      WHERE fgo.sec_group_id = sug.group_id
                        AND ROWNUM = 1)
              OR EXISTS(SELECT 'x'
                          FROM SEC_GROUP_LOC_MATRIX sglm
                         WHERE sglm.group_id = sug.group_id
                           AND ROWNUM = 1))
         AND ROWNUM = 1;

   -- When a user is associated to a group that is not associated to any
   -- hierarchy, the C_FILTER_USER_MERCH cursor returns no rows.  This cursor
   -- also returns no rows if the user is not associated to any group, however
   -- if the C_FIND_GROUP cursor is fetched before this cursor, we can ensure
   -- that the C_FILTER_USER_MERCH cursor is never executed in this second scenario.
   -- That being said, if the C_FILTER_USER_MERCH cursor returns no rows (indicating
   -- the first scenario mentioned in this comment), then the user is associated
   -- to a group that is not associated to a hierarchy, and is therefore a super-
   -- user.
   CURSOR C_FILTER_USER_MERCH IS
     SELECT 'Y'
       FROM SEC_USER_GROUP sug
      WHERE sug.user_id = SYS_CONTEXT('USERENV', 'SESSION_USER')
        AND EXISTS(SELECT 'x'
                     FROM FILTER_GROUP_MERCH fgm
                    WHERE fgm.sec_group_id = sug.group_id
                      AND ROWNUM = 1)
        AND ROWNUM = 1;

BEGIN

   OPEN C_GET_SYSTEM_LEVELS;
   FETCH C_GET_SYSTEM_LEVELS INTO L_data_level_security_ind,
                                  GP_diff_group_org_level,
                                  GP_loc_list_org_level,
                                  GP_loc_trait_org_level,
                                  GP_seasons_org_level,
                                  GP_skulist_org_level,
                                  GP_ticket_type_org_level,
                                  GP_uda_org_level,
                                  GP_diff_group_merch_level,
                                  GP_seasons_merch_level,
                                  GP_ticket_type_merch_level,
                                  GP_uda_merch_level,
                                  -- 10-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 Begin
                                  GP_tsl_loc_sec_ind;
                                  -- 10-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 End;

   IF C_GET_SYSTEM_LEVELS%NOTFOUND THEN
      GP_filter_set := FALSE;
      O_error_message := 'System Options not found.';
      RETURN FALSE;
   END IF;

   CLOSE C_GET_SYSTEM_LEVELS;
   -- 10-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 Begin
   GP_data_sec_ind := L_data_level_security_ind;
   -- 10-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 End
   IF L_data_level_security_ind = 'N' THEN
      GP_filter_org   := 'N';
      GP_filter_merch := 'N';
   ELSE
      ---
      OPEN C_FIND_GROUP;
      FETCH C_FIND_GROUP INTO GP_group_association;
      CLOSE C_FIND_GROUP;

      -- if the user is not associated to any group, they must have filtering applied.
      IF GP_group_association = 'N' THEN
         GP_filter_org := 'Y';
         GP_filter_merch := 'Y';
      ELSE
         ---
         OPEN C_FILTER_USER_ORG;
         FETCH C_FILTER_USER_ORG INTO GP_filter_org;

         IF C_FILTER_USER_ORG%NOTFOUND THEN
            GP_filter_org := 'N';
         END IF;

         CLOSE C_FILTER_USER_ORG;
         ---
         OPEN C_FILTER_USER_MERCH;
         FETCH C_FILTER_USER_MERCH INTO GP_filter_merch;

         IF C_FILTER_USER_MERCH%NOTFOUND THEN
            GP_filter_merch := 'N';
         END IF;

         CLOSE C_FILTER_USER_MERCH;
      END IF;
   END IF;
   ---

   GP_filter_set := TRUE;

   RETURN TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := Sql_Lib.CREATE_MSG('PACKAGE_ERROR',
                                            'FILTER_POLICY_SQL.SET_USER_FILTER',
                                            SQLERRM,
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;

END SET_USER_FILTER;

----------------------------------------------------------------------------------
FUNCTION V_Mrt_Item_S(d1 IN  VARCHAR2,
                                                    d2 IN VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         return NULL;
      END IF;
   END IF;

   if ( GP_filter_merch = 'N' ) then
      return NULL;
   else

      L_predicate := 'exists (select ''X'' ' ||
                                  '  from v_item_master vi ' ||
                                  ' where vi.item = v_mrt_item.item ' ||
                                 ' and rownum = 1)';
   end if;

   return L_predicate;

END V_Mrt_Item_S;

--------------------------------------------------------------------------------

FUNCTION V_Mrt_Item_Loc_S(d1 IN VARCHAR2,
                                                              d2 IN VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         return NULL;
      END IF;
   END IF;

   if ( GP_filter_org = 'N' ) then
      return NULL;
   else
	   L_predicate := 'exists (select ''X'' ' ||
                                   '  from v_wh vw ' ||
                                   ' where vw.wh = v_mrt_item_loc.location ' ||
                                   ' and v_mrt_item_loc.loc_type = ''W'' ' ||
                                   ' and rownum = 1)' ||
                                   'or exists (select ''X'' ' ||
                                   '  from v_store vs ' ||
                                   ' where vs.store = v_mrt_item_loc.location ' ||
                                   ' and v_mrt_item_loc.loc_type = ''S'' ' ||
                                   ' and rownum = 1)';
   end if;

   return L_predicate;

END V_Mrt_Item_Loc_S;

--------------------------------------------------------------------------------
-- ASSEMBLY()
--------------------------------------------------------------------------------
FUNCTION ASSEMBLY(I_org_null IN VARCHAR2,
                  I_org_exists IN VARCHAR2,
                  I_merch_null IN VARCHAR2,
                  I_merch_exists IN VARCHAR2)
RETURN STRING IS

   L_product VARCHAR2(15000);

BEGIN

   IF(GP_filter_org = 'Y' AND GP_filter_merch = 'N' ) THEN
      L_product := '(' || I_org_null || ' or ' || I_org_exists || ')';
   ELSIF(GP_filter_org = 'N' AND GP_filter_merch = 'Y' ) THEN
      L_product := '(' || I_merch_null || ' or ' || I_merch_exists ||')';
   ELSE
      L_product := '((' || I_org_null || ' and ' || I_merch_null || ') ' ||
                   'or (' || I_org_exists || ' and ' || I_merch_null || ') '||
                   'or (' || I_merch_exists || ' and ' || I_org_null || ') '||
                   'or (' || I_org_exists || ' and ' || I_merch_exists || '))';
   END IF;
   ---
   RETURN L_product;

END ASSEMBLY;

--------------------------------------------------------------------------------
-- V_AREA_S()
--------------------------------------------------------------------------------
FUNCTION V_AREA_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_org = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     'from v_district vd ' ||
                     'where vd.area = v_area.area ' ||
                     'and rownum = 1)';
   END IF;
   ---
   RETURN L_predicate;
END V_AREA_S;

--------------------------------------------------------------------------------
-- V_CHAIN_S()
--------------------------------------------------------------------------------
FUNCTION V_CHAIN_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_org = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                             '  from v_district vd ' ||
                             ' where vd.chain = v_chain.chain ' ||
                             '   and rownum = 1)';
   END IF;
   ---
   RETURN L_predicate;

END V_CHAIN_S;

--------------------------------------------------------------------------------
-- V_DEPS_S()
--------------------------------------------------------------------------------
FUNCTION V_DEPS_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_merch = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select /*+ ordered index(sug, sec_user_group_i1 ) */ ''X'' ' ||
                     '          from sec_user_group sug, filter_group_merch fgm, class c, subclass s ' ||
                     '         where sug.user_id = SYS_CONTEXT(''USERENV'',''SESSION_USER'') ' ||
                     '           and sug.group_id = fgm.sec_group_id ' ||
                     '           and v_deps.division = DECODE(fgm.filter_merch_level, ''D'', fgm.filter_merch_id, v_deps.division) ' ||
                     '           and v_deps.group_no = DECODE(fgm.filter_merch_level, ''G'', fgm.filter_merch_id, v_deps.group_no) ' ||
                     '           and v_deps.dept     = DECODE(fgm.filter_merch_level, ''P'', fgm.filter_merch_id, v_deps.dept) ' ||
                     '           and c.class         = DECODE(fgm.filter_merch_level, ''C'', fgm.filter_merch_id_class, c.class) ' ||
                     '           and c.dept          = DECODE(fgm.filter_merch_level, ''C'', fgm.filter_merch_id, c.dept) ' ||
                     '           and s.subclass      = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_subclass, s.subclass) ' ||
                     '           and s.class         = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_class, s.class) ' ||
                     '           and s.dept          = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id, s.dept) ' ||
                     '           and s.dept  = c.dept ' ||
                     '           and s.class = c.class ' ||
                     '           and c.dept  = v_deps.dept ' ||
                     '           and rownum  = 1)';
   END IF;
   ---
   RETURN L_predicate;

END V_DEPS_S;

--------------------------------------------------------------------------------
-- V_CLASS_S()
--------------------------------------------------------------------------------
FUNCTION V_CLASS_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_merch = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     '          from filter_group_merch fgm, sec_user_group sug, v_deps vdp, subclass s ' ||
                     '         where sug.user_id = SYS_CONTEXT(''USERENV'',''SESSION_USER'') ' ||
                     '           and sug.group_id  = fgm.sec_group_id ' ||
                     '           and vdp.division  = DECODE(fgm.filter_merch_level, ''D'', fgm.filter_merch_id, vdp.division) ' ||
                     '           and vdp.group_no  = DECODE(fgm.filter_merch_level, ''G'', fgm.filter_merch_id, vdp.group_no) ' ||
                     '           and vdp.dept      = DECODE(fgm.filter_merch_level, ''P'', fgm.filter_merch_id, vdp.dept) ' ||
                     '           and v_class.class = DECODE(fgm.filter_merch_level, ''C'', fgm.filter_merch_id_class, v_class.class) ' ||
                     '           and v_class.dept  = DECODE(fgm.filter_merch_level, ''C'', fgm.filter_merch_id, v_class.dept) ' ||
                     '           and s.subclass    = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_subclass, s.subclass) ' ||
                     '           and s.class       = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_class, s.class) ' ||
                     '           and s.dept        = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id, s.dept) ' ||
                     '           and vdp.dept = v_class.dept ' ||
                     '           and s.dept   = v_class.dept ' ||
                     '           and s.class  = v_class.class ' ||
                     '           and rownum   = 1)';

   END IF;
   ---
   RETURN L_predicate;

END V_CLASS_S;

--------------------------------------------------------------------------------
-- V_SUBCLASS_S()
--------------------------------------------------------------------------------
FUNCTION V_SUBCLASS_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_merch = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     '          from filter_group_merch fgm, sec_user_group sug, v_deps vdp, class c ' ||
                     '         where sug.user_id = SYS_CONTEXT(''USERENV'',''SESSION_USER'') ' ||
                     '           and sug.group_id = fgm.sec_group_id ' ||
                     '           and vdp.division     = DECODE(fgm.filter_merch_level, ''D'', fgm.filter_merch_id, vdp.division) ' ||
                     '           and vdp.group_no     = DECODE(fgm.filter_merch_level, ''G'', fgm.filter_merch_id, vdp.group_no) ' ||
                     '           and vdp.dept         = DECODE(fgm.filter_merch_level, ''P'', fgm.filter_merch_id, vdp.dept) ' ||
                     '           and c.class          = DECODE(fgm.filter_merch_level, ''C'', fgm.filter_merch_id_class, c.class) ' ||
                     '           and c.dept           = DECODE(fgm.filter_merch_level, ''C'', fgm.filter_merch_id, c.dept) ' ||
                     '           and v_subclass.subclass = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_subclass, v_subclass.subclass) ' ||
                     '           and v_subclass.class    = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_class, v_subclass.class) ' ||
                     '           and v_subclass.dept     = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id, v_subclass.dept) ' ||
                     '           and vdp.dept = c.dept ' ||
                     '           and c.class  = v_subclass.class ' ||
                     '           and c.dept   = v_subclass.dept ' ||
                     '           and rownum   = 1)';
   END IF;
   ---
   RETURN L_predicate;

END V_SUBCLASS_S;

--------------------------------------------------------------------------------
-- V_DIFF_GROUP_HEAD_S()
--------------------------------------------------------------------------------
FUNCTION V_DIFF_GROUP_HEAD_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(15000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

   L_org_null           VARCHAR2(50);
   L_merch_null         VARCHAR2(50);
   L_org_exists         VARCHAR2(1000);
   L_merch_exists       VARCHAR2(1500);

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF(GP_filter_org = 'N' AND GP_filter_merch = 'N') THEN
      RETURN NULL;
   END IF;

   L_org_null := 'v_diff_group_head.filter_org_id is NULL';

   L_merch_null := 'v_diff_group_head.filter_merch_id is NULL';

   L_org_exists := 'exists (select ''X'' ' ||
                   '          from sec_user_group sug, filter_group_org fgo, area ara, region reg, district dis ' ||
                   '         where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                   '           and sug.group_id = fgo.sec_group_id ' ||
                   '           and ara.area = reg.area ' ||
                   '           and reg.region = dis.region ' ||
                   '           and fgo.filter_org_level in (''C'', ''A'', ''R'', ''D'') ' ||
                   '           and ara.chain    = decode(fgo.filter_org_level, ''C'', fgo.filter_org_id, ara.chain) ' ||
                   '           and ara.area     = decode(fgo.filter_org_level, ''A'', fgo.filter_org_id, ara.area) ' ||
                   '           and reg.region   = decode(fgo.filter_org_level, ''R'', fgo.filter_org_id, reg.region) ' ||
                   '           and dis.district = decode(fgo.filter_org_level, ''D'', fgo.filter_org_id, dis.district) ';

   IF(GP_diff_group_org_level = 'C') THEN
      L_org_exists := L_org_exists || 'and ara.chain = v_diff_group_head.filter_org_id ';
   ELSIF(GP_diff_group_org_level = 'A') THEN
      L_org_exists := L_org_exists || 'and ara.area = v_diff_group_head.filter_org_id ';
   ELSIF(GP_diff_group_org_level = 'R') THEN
      L_org_exists := L_org_exists || 'and reg.region = v_diff_group_head.filter_org_id ';
   ELSIF(GP_diff_group_org_level = 'D') THEN
      L_org_exists := L_org_exists || 'and dis.district = v_diff_group_head.filter_org_id ';
   END IF;
   ---
   L_org_exists := L_org_exists || 'and rownum = 1)';
   ---

   L_merch_exists := 'exists (select ''X'' ' ||
                     '          from sec_user_group sug, filter_group_merch fgm, groups gps, deps dps, class cls, subclass sub ' ||
                     '         where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     '           and sug.group_id = fgm.sec_group_id ' ||
                     '           and gps.group_no = dps.group_no ' ||
                     '           and dps.dept     = cls.dept ' ||
                     '           and dps.dept     = sub.dept ' ||
                     '           and cls.class    = sub.class '||
                     '           and gps.division = decode(fgm.filter_merch_level, ''D'', fgm.filter_merch_id, gps.division) ' ||
                     '           and gps.group_no = decode(fgm.filter_merch_level, ''G'', fgm.filter_merch_id, gps.group_no) ' ||
                     '           and dps.dept     = decode(fgm.filter_merch_level, ''P'', fgm.filter_merch_id, dps.dept) ' ||
                     '           and cls.class    = decode(fgm.filter_merch_level, ''C'', fgm.filter_merch_id_class, cls.class) ' ||
                     '           and cls.dept     = decode(fgm.filter_merch_level, ''C'', fgm.filter_merch_id, cls.dept) ' ||
                     '           and sub.subclass = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_subclass, sub.subclass) ' ||
                     '           and sub.class    = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_class, sub.class) ' ||
                     '           and sub.dept     = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id, sub.dept) ';

   IF(GP_diff_group_merch_level = 'D') THEN
      L_merch_exists := L_merch_exists || 'and gps.division = v_diff_group_head.filter_merch_id ';
   ELSIF(GP_diff_group_merch_level = 'G') THEN
      L_merch_exists := L_merch_exists || 'and gps.group_no = v_diff_group_head.filter_merch_id ';
   ELSIF(GP_diff_group_merch_level = 'P') THEN
      L_merch_exists := L_merch_exists || 'and dps.dept = v_diff_group_head.filter_merch_id ';
   ELSIF(GP_diff_group_merch_level = 'C') THEN
      L_merch_exists := L_merch_exists || 'and cls.class = v_diff_group_head.filter_merch_id_class ' ||
                                          'and cls.dept  = v_diff_group_head.filter_merch_id ';
   ELSIF(GP_diff_group_merch_level = 'S') THEN
      L_merch_exists := L_merch_exists || 'and sub.subclass = v_diff_group_head.filter_merch_id_subclass ' ||
                                          'and sub.class    = v_diff_group_head.filter_merch_id_class ' ||
                                          'and sub.dept     = v_diff_group_head.filter_merch_id ';
   END IF;
   ---
   L_merch_exists := L_merch_exists || 'and rownum = 1)';
   ---

   L_predicate := ASSEMBLY(L_org_null, L_org_exists, L_merch_null, L_merch_exists);
   RETURN L_predicate;

END V_DIFF_GROUP_HEAD_S;

--------------------------------------------------------------------------------
-- V_DISTRICT_S()
--------------------------------------------------------------------------------
FUNCTION V_DISTRICT_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_org = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     'from filter_group_org fgo, sec_user_group sug ' ||
                     'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     'and sug.group_id = fgo.sec_group_id ' ||
                     'and fgo.filter_org_level in (''C'', ''A'', ''R'', ''D'') ' ||
                     'and v_district.chain    = DECODE(fgo.filter_org_level, ''C'', fgo.filter_org_id, v_district.chain) ' ||
                     'and v_district.area     = DECODE(fgo.filter_org_level, ''A'', fgo.filter_org_id, v_district.area) ' ||
                     'and v_district.region   = DECODE(fgo.filter_org_level, ''R'', fgo.filter_org_id, v_district.region) ' ||
                     'and v_district.district = DECODE(fgo.filter_org_level, ''D'', fgo.filter_org_id, v_district.district) ' ||
                     'and rownum = 1)';
   END IF;
   ---
   RETURN L_predicate;

END V_DISTRICT_S;

--------------------------------------------------------------------------------
-- V_DIVISION_S()
--------------------------------------------------------------------------------
FUNCTION V_DIVISION_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_merch = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                             '  from v_deps vd ' ||
                             ' where vd.division = v_division.division ' ||
                             ' and rownum = 1)';
   END IF;
   ---
   RETURN L_predicate;

END V_DIVISION_S;

--------------------------------------------------------------------------------
-- V_EXTERNAL_FINISHER_S()
--------------------------------------------------------------------------------

FUNCTION V_EXTERNAL_FINISHER_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_org = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     'from filter_group_org fgo, sec_user_group sug ' ||
                     'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     'and sug.group_id = fgo.sec_group_id ' ||
                     'and fgo.filter_org_level = ''E'' ' ||
                     'and fgo.filter_org_id = v_external_finisher.finisher_id ' ||
                     'and rownum = 1)';
   END IF;

   ---
   RETURN L_predicate;

END V_EXTERNAL_FINISHER_S;

--------------------------------------------------------------------------------
-- V_INTERNAL_FINISHER_S()
--------------------------------------------------------------------------------

FUNCTION V_INTERNAL_FINISHER_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_org = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     'from filter_group_org fgo, sec_user_group sug ' ||
                     'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     'and sug.group_id = fgo.sec_group_id ' ||
                     'and fgo.filter_org_level = ''I'' ' ||
                     'and fgo.filter_org_id = v_internal_finisher.finisher_id ' ||
                     'and rownum = 1)';
   END IF;

   ---
   RETURN L_predicate;

END V_INTERNAL_FINISHER_S;

--------------------------------------------------------------------------------
-- V_GROUPS_S()
--------------------------------------------------------------------------------

FUNCTION V_GROUPS_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_merch = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                             '  from  v_deps vd ' ||
                             ' where vd.group_no = v_groups.group_no ' ||
                             '   and rownum = 1)';
   END IF;

   ---
   RETURN L_predicate;

END V_GROUPS_S;

--------------------------------------------------------------------------------
-- V_ITEM_MASTER_S()
--------------------------------------------------------------------------------
FUNCTION V_ITEM_MASTER_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_merch = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate :=
         'exists (select /*+ ordered index(sug, sec_user_group_i1 ) */ ''X'' ' ||
         'from sec_user_group sug, filter_group_merch fgm ' ||
         'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
         'and sug.group_id = fgm.sec_group_id ' ||
         'and v_item_master.division = DECODE(fgm.filter_merch_level, ''D'', fgm.filter_merch_id, v_item_master.division) ' ||
         'and v_item_master.group_no = DECODE(fgm.filter_merch_level, ''G'', fgm.filter_merch_id, v_item_master.group_no) ' ||
         'and v_item_master.dept     = DECODE(fgm.filter_merch_level, ''P'', fgm.filter_merch_id, v_item_master.dept) ' ||
         'and v_item_master.class    = DECODE(fgm.filter_merch_level, ''C'', fgm.filter_merch_id_class, v_item_master.class) ' ||
         'and v_item_master.dept     = DECODE(fgm.filter_merch_level, ''C'', fgm.filter_merch_id, v_item_master.dept) ' ||
         'and v_item_master.subclass = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_subclass, v_item_master.subclass) ' ||
         'and v_item_master.class    = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_class, v_item_master.class) ' ||
         'and v_item_master.dept     = DECODE(fgm.filter_merch_level, ''S'', fgm.filter_merch_id, v_item_master.dept) ' ||
         'and rownum = 1)';
   END IF;
   ---
   RETURN L_predicate;

END V_ITEM_MASTER_S;

--------------------------------------------------------------------------------
-- V_LOC_LIST_HEAD_S()
--------------------------------------------------------------------------------
FUNCTION V_LOC_LIST_HEAD_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

   L_org_null           VARCHAR2(50);
   L_org_exists         VARCHAR2(1000);

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   L_org_null := 'v_loc_list_head.filter_org_id is NULL';

   L_org_exists := 'exists (select ''X'' ' ||
                   'from sec_user_group sug, filter_group_org fgo, area ara, region reg, district dis ' ||
                   'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                   'and sug.group_id = fgo.sec_group_id ' ||
                   'and ara.area = reg.area ' ||
                   'and reg.region = dis.region ' ||
                   'and fgo.filter_org_level in (''C'', ''A'', ''R'', ''D'') ' ||
                   'and ara.chain    = decode(fgo.filter_org_level, ''C'', fgo.filter_org_id, ara.chain) ' ||
                   'and ara.area     = decode(fgo.filter_org_level, ''A'', fgo.filter_org_id, ara.area) ' ||
                   'and reg.region   = decode(fgo.filter_org_level, ''R'', fgo.filter_org_id, reg.region) ' ||
                   'and dis.district = decode(fgo.filter_org_level, ''D'', fgo.filter_org_id, dis.district) ';

   IF(GP_loc_list_org_level = 'C') THEN
      L_org_exists := L_org_exists || 'and ara.chain = v_loc_list_head.filter_org_id ';
   ELSIF(GP_loc_list_org_level = 'A') THEN
      L_org_exists := L_org_exists || 'and ara.area = v_loc_list_head.filter_org_id ';
   ELSIF(GP_loc_list_org_level = 'R') THEN
      L_org_exists := L_org_exists || 'and reg.region = v_loc_list_head.filter_org_id ';
   ELSIF(GP_loc_list_org_level = 'D') THEN
      L_org_exists := L_org_exists || 'and dis.district = v_loc_list_head.filter_org_id ';
   END IF;
   ---
   L_org_exists := L_org_exists || 'and rownum = 1)';
   ---

   IF(GP_filter_org = 'N') THEN
      RETURN NULL;
   ELSE
      L_predicate := '(' || L_org_null || ' or ' || L_org_exists || ')';
   END IF;
   ---
   RETURN L_predicate;

END V_LOC_LIST_HEAD_S;

--------------------------------------------------------------------------------
-- V_LOC_TRAITS_S()
--------------------------------------------------------------------------------
FUNCTION V_LOC_TRAITS_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

   L_org_null           VARCHAR2(50);
   L_org_exists         VARCHAR2(1000);

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   L_org_null := 'v_loc_traits.filter_org_id is NULL';

   L_org_exists := 'exists (select ''X'' ' ||
                   'from sec_user_group sug, filter_group_org fgo, area ara, region reg, district dis ' ||
                   'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                   'and sug.group_id = fgo.sec_group_id ' ||
                   'and ara.area = reg.area ' ||
                   'and reg.region = dis.region ' ||
                   'and fgo.filter_org_level in (''C'', ''A'', ''R'', ''D'') ' ||
                   'and ara.chain    = decode(fgo.filter_org_level, ''C'', fgo.filter_org_id, ara.chain) ' ||
                   'and ara.area     = decode(fgo.filter_org_level, ''A'', fgo.filter_org_id, ara.area) ' ||
                   'and reg.region   = decode(fgo.filter_org_level, ''R'', fgo.filter_org_id, reg.region) ' ||
                   'and dis.district = decode(fgo.filter_org_level, ''D'', fgo.filter_org_id, dis.district) ';

   IF(GP_loc_trait_org_level = 'C') THEN
      L_org_exists := L_org_exists || 'and ara.chain = v_loc_traits.filter_org_id ';
   ELSIF(GP_loc_trait_org_level = 'A') THEN
      L_org_exists := L_org_exists || 'and ara.area = v_loc_traits.filter_org_id ';
   ELSIF(GP_loc_trait_org_level = 'R') THEN
      L_org_exists := L_org_exists || 'and reg.region = v_loc_traits.filter_org_id ';
   ELSIF(GP_loc_trait_org_level = 'D') THEN
      L_org_exists := L_org_exists || 'and dis.district = v_loc_traits.filter_org_id ';
   END IF;
   ---
   L_org_exists := L_org_exists || 'and rownum = 1)';
   ---

   IF(GP_filter_org = 'N') THEN
      RETURN NULL;
   ELSE
      L_predicate := '(' || L_org_null || ' or ' || L_org_exists || ')';
   END IF;
   ---
   RETURN L_predicate;

END V_LOC_TRAITS_S;

--------------------------------------------------------------------------------
-- V_REGION_S()
--------------------------------------------------------------------------------
FUNCTION V_REGION_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_org = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     'from v_district vd ' ||
                     'where vd.region = v_region.region ' ||
                     'and rownum = 1)';
   END IF;
   ---
   RETURN L_predicate;

END V_REGION_S;

--------------------------------------------------------------------------------
-- V_SEASONS_S()
--------------------------------------------------------------------------------

FUNCTION V_SEASONS_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(3000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

   L_org_null           VARCHAR2(50);
   L_merch_null         VARCHAR2(50);
   L_org_exists         VARCHAR2(1000);
   L_merch_exists       VARCHAR2(1500);

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF(GP_filter_org = 'N' AND GP_filter_merch = 'N') THEN
      RETURN NULL;
   END IF;

   L_org_null := 'v_seasons.filter_org_id is NULL';

   L_merch_null := 'v_seasons.filter_merch_id is NULL';

   L_org_exists := 'exists (select ''X'' ' ||
                   '          from sec_user_group sug, filter_group_org fgo, area ara, region reg, district dis ' ||
                   '         where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                   '           and sug.group_id = fgo.sec_group_id ' ||
                   '            and ara.area = reg.area ' ||
                   '            and reg.region = dis.region ' ||
                   '            and fgo.filter_org_level in (''C'', ''A'', ''R'', ''D'') ' ||
                   '            and ara.chain    = decode(fgo.filter_org_level, ''C'', fgo.filter_org_id, ara.chain) ' ||
                   '            and ara.area     = decode(fgo.filter_org_level, ''A'', fgo.filter_org_id, ara.area) ' ||
                   '            and reg.region   = decode(fgo.filter_org_level, ''R'', fgo.filter_org_id, reg.region) ' ||
                   '            and dis.district = decode(fgo.filter_org_level, ''D'', fgo.filter_org_id, dis.district) ';

   IF(GP_seasons_org_level = 'C') THEN
      L_org_exists := L_org_exists || 'and ara.chain = v_seasons.filter_org_id ';
   ELSIF(GP_seasons_org_level = 'A') THEN
      L_org_exists := L_org_exists || 'and ara.area = v_seasons.filter_org_id ';
   ELSIF(GP_seasons_org_level = 'R') THEN
      L_org_exists := L_org_exists || 'and reg.region = v_seasons.filter_org_id ';
   ELSIF(GP_seasons_org_level = 'D') THEN
      L_org_exists := L_org_exists || 'and dis.district = v_seasons.filter_org_id ';
   END IF;
   ---
   L_org_exists := L_org_exists || 'and rownum = 1)';
   ---

   L_merch_exists := 'exists (select ''X'' ' ||
                     '          from sec_user_group sug, filter_group_merch fgm, groups gps, deps dps, class cls, subclass sub ' ||
                     '         where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     '           and sug.group_id = fgm.sec_group_id ' ||
                     '           and gps.group_no = dps.group_no ' ||
                     '           and dps.dept     = cls.dept ' ||
                     '           and dps.dept     = sub.dept ' ||
                     '           and cls.class    = sub.class '||
                     '           and gps.division = decode(fgm.filter_merch_level, ''D'', fgm.filter_merch_id, gps.division) ' ||
                     '           and gps.group_no = decode(fgm.filter_merch_level, ''G'', fgm.filter_merch_id, gps.group_no) ' ||
                     '           and dps.dept     = decode(fgm.filter_merch_level, ''P'', fgm.filter_merch_id, dps.dept) ' ||
                     '           and cls.class    = decode(fgm.filter_merch_level, ''C'', fgm.filter_merch_id_class, cls.class) ' ||
                     '           and cls.dept     = decode(fgm.filter_merch_level, ''C'', fgm.filter_merch_id, cls.dept) ' ||
                     '           and sub.subclass = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_subclass, sub.subclass) ' ||
                     '           and sub.class    = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_class, sub.class) ' ||
                     '           and sub.dept     = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id, sub.dept) ';

   IF(GP_seasons_merch_level = 'D') THEN
      L_merch_exists := L_merch_exists || 'and gps.division = v_seasons.filter_merch_id ';
   ELSIF(GP_seasons_merch_level = 'G') THEN
      L_merch_exists := L_merch_exists || 'and gps.group_no = v_seasons.filter_merch_id ';
   ELSIF(GP_seasons_merch_level = 'P') THEN
      L_merch_exists := L_merch_exists || 'and dps.dept = v_seasons.filter_merch_id ';
   ELSIF(GP_seasons_merch_level = 'C') THEN
      L_merch_exists := L_merch_exists || 'and cls.class = v_seasons.filter_merch_id_class ' ||
                                          'and cls.dept = v_seasons.filter_merch_id ';
   ELSIF(GP_seasons_merch_level = 'S') THEN
      L_merch_exists := L_merch_exists || 'and sub.subclass = v_seasons.filter_merch_id_subclass ' ||
                                          'and sub.class = v_seasons.filter_merch_id_class ' ||
                                          'and sub.dept = v_seasons.filter_merch_id ';
   END IF;
   ---
   L_merch_exists := L_merch_exists || 'and rownum = 1)';
   ---

   L_predicate := ASSEMBLY(L_org_null, L_org_exists, L_merch_null, L_merch_exists);

   RETURN L_predicate;

END V_SEASONS_S;

--------------------------------------------------------------------------------
-- V_SKULIST_HEAD_S()
--------------------------------------------------------------------------------

FUNCTION V_SKULIST_HEAD_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(3000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

   L_org_null           VARCHAR2(50);
   L_merch_null         VARCHAR2(120);
   L_org_exists         VARCHAR2(1500);
   L_merch_exists       VARCHAR2(1000);

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF(GP_filter_org = 'N' AND GP_filter_merch = 'N') THEN
      RETURN NULL;
   END IF;

   L_org_null := 'v_skulist_head.filter_org_id is NULL';

   L_merch_null := 'not exists (select ''X'' ' ||
                   '   from skulist_dept sld ' ||
                   '  where sld.skulist = v_skulist_head.skulist ' ||
                   '    and rownum = 1) ';

   L_org_exists := 'exists (select ''X'' ' ||
                   'from sec_user_group sug, filter_group_org fgo, area ara, region reg, district dis ' ||
                   'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                   'and sug.group_id = fgo.sec_group_id ' ||
                   'and ara.area = reg.area ' ||
                   'and reg.region = dis.region ' ||
                   'and fgo.filter_org_level in (''C'', ''A'', ''R'', ''D'') ' ||
                   'and ara.chain    = decode(fgo.filter_org_level, ''C'', fgo.filter_org_id, ara.chain) ' ||
                   'and ara.area     = decode(fgo.filter_org_level, ''A'', fgo.filter_org_id, ara.area) ' ||
                   'and reg.region   = decode(fgo.filter_org_level, ''R'', fgo.filter_org_id, reg.region) ' ||
                   'and dis.district = decode(fgo.filter_org_level, ''D'', fgo.filter_org_id, dis.district) ';

   IF(GP_skulist_org_level = 'C') THEN
      L_org_exists := L_org_exists || 'and ara.chain = v_skulist_head.filter_org_id ';
   ELSIF(GP_skulist_org_level = 'A') THEN
      L_org_exists := L_org_exists || 'and ara.area = v_skulist_head.filter_org_id ';
   ELSIF(GP_skulist_org_level = 'R') THEN
      L_org_exists := L_org_exists || 'and reg.region = v_skulist_head.filter_org_id ';
   ELSIF(GP_skulist_org_level = 'D') THEN
      L_org_exists := L_org_exists || 'and dis.district = v_skulist_head.filter_org_id ';
   END IF;
   ---
   L_org_exists := L_org_exists || 'and rownum = 1)';
   ---

   L_merch_exists := 'v_skulist_head.skulist in ' ||
                     ' (select distinct sld1.skulist ' ||
                     '    from skulist_dept sld1 ' ||
                     ' minus ' ||
                     '  select distinct sld2.skulist ' ||
                     '    from skulist_detail sld2 ' ||
                     '   where not exists (select ''X'' ' ||
                                         '   from v_item_master vi ' ||
                                         '  where vi.item = sld2.item ' ||
                                         '    and rownum = 1) ) ';
   ---

   L_predicate := ASSEMBLY(L_org_null, L_org_exists, L_merch_null, L_merch_exists);

   RETURN L_predicate;

END V_SKULIST_HEAD_S;

--------------------------------------------------------------------------------
-- V_STORE_S()
--------------------------------------------------------------------------------
FUNCTION V_STORE_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_org = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     'from filter_group_org fgo, sec_user_group sug ' ||
                     'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     'and sug.group_id = fgo.sec_group_id ' ||
                     'and fgo.filter_org_level in (''C'', ''A'', ''R'', ''D'') ' ||
                     'and v_store.chain = DECODE(fgo.filter_org_level, ''C'', fgo.filter_org_id, v_store.chain) ' ||
                     'and v_store.area = DECODE(fgo.filter_org_level, ''A'', fgo.filter_org_id, v_store.area) ' ||
                     'and v_store.region = DECODE(fgo.filter_org_level, ''R'', fgo.filter_org_id, v_store.region) ' ||
                     'and v_store.district = DECODE(fgo.filter_org_level, ''D'', fgo.filter_org_id, v_store.district) ' ||
                     'and rownum = 1)';

   END IF;
   ---
   RETURN L_predicate;

END V_STORE_S;

--------------------------------------------------------------------------------
-- V_TICKET_TYPE_HEAD_S()
--------------------------------------------------------------------------------

FUNCTION V_TICKET_TYPE_HEAD_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   --Fix for NBS00006112 by Bahubali Dongare
   --Changed the size of the L_predicate from VARCHAR2(3000) to VARCHAR2(15000) as
   -- the function ASSEMBLY has the return value with VARCHAR2(15000)
   L_predicate          VARCHAR2(15000);
   --Fix for NBS00006112 by Bahubali Dongare
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

   L_org_null           VARCHAR2(50);
   L_merch_null         VARCHAR2(50);
   L_org_exists         VARCHAR2(1000);
   L_merch_exists       VARCHAR2(1500);

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF(GP_filter_org = 'N' AND GP_filter_merch = 'N') THEN
      RETURN NULL;
   END IF;

   L_org_null := 'v_ticket_type_head.filter_org_id is NULL';

   L_merch_null := 'v_ticket_type_head.filter_merch_id is NULL';

   L_org_exists := 'exists (select ''X'' ' ||
                   '          from sec_user_group sug, filter_group_org fgo, area ara, region reg, district dis ' ||
                   '         where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                   '           and sug.group_id = fgo.sec_group_id ' ||
                   '           and ara.area = reg.area ' ||
                   '           and reg.region = dis.region ' ||
                   '           and fgo.filter_org_level in (''C'', ''A'', ''R'', ''D'') ' ||
                   '           and ara.chain    = decode(fgo.filter_org_level, ''C'', fgo.filter_org_id, ara.chain) ' ||
                   '           and ara.area     = decode(fgo.filter_org_level, ''A'', fgo.filter_org_id, ara.area) ' ||
                   '           and reg.region   = decode(fgo.filter_org_level, ''R'', fgo.filter_org_id, reg.region) ' ||
                   '           and dis.district = decode(fgo.filter_org_level, ''D'', fgo.filter_org_id, dis.district) ';

   IF(GP_ticket_type_org_level = 'C') THEN
      L_org_exists := L_org_exists || 'and ara.chain = v_ticket_type_head.filter_org_id ';
   ELSIF(GP_ticket_type_org_level = 'A') THEN
      L_org_exists := L_org_exists || 'and ara.area = v_ticket_type_head.filter_org_id ';
   ELSIF(GP_ticket_type_org_level = 'R') THEN
      L_org_exists := L_org_exists || 'and reg.region = v_ticket_type_head.filter_org_id ';
   ELSIF(GP_ticket_type_org_level = 'D') THEN
      L_org_exists := L_org_exists || 'and dis.district = v_ticket_type_head.filter_org_id ';
   END IF;
   ---
   L_org_exists := L_org_exists || 'and rownum = 1)';
   ---

   L_merch_exists := 'exists (select ''X'' ' ||
                     '          from sec_user_group sug, filter_group_merch fgm, groups gps, deps dps, class cls, subclass sub ' ||
                     '         where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     '           and sug.group_id = fgm.sec_group_id ' ||
                     '           and gps.group_no = dps.group_no ' ||
                     '           and dps.dept     = cls.dept ' ||
                     '           and dps.dept     = sub.dept ' ||
                     '           and cls.class    = sub.class '||
                     '           and gps.division = decode(fgm.filter_merch_level, ''D'', fgm.filter_merch_id, gps.division) ' ||
                     '           and gps.group_no = decode(fgm.filter_merch_level, ''G'', fgm.filter_merch_id, gps.group_no) ' ||
                     '           and dps.dept     = decode(fgm.filter_merch_level, ''P'', fgm.filter_merch_id, dps.dept) ' ||
                     '           and cls.class    = decode(fgm.filter_merch_level, ''C'', fgm.filter_merch_id_class, cls.class) ' ||
                     '           and cls.dept     = decode(fgm.filter_merch_level, ''C'', fgm.filter_merch_id, cls.dept) ' ||
                     '           and sub.subclass = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_subclass, sub.subclass) ' ||
                     '           and sub.class    = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_class, sub.class) ' ||
                     '           and sub.dept     = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id, sub.dept) ';

   IF(GP_ticket_type_merch_level = 'D') THEN
      L_merch_exists := L_merch_exists || 'and gps.division = v_ticket_type_head.filter_merch_id ';
   ELSIF(GP_ticket_type_merch_level = 'G') THEN
      L_merch_exists := L_merch_exists || 'and gps.group_no = v_ticket_type_head.filter_merch_id ';
   ELSIF(GP_ticket_type_merch_level = 'P') THEN
      L_merch_exists := L_merch_exists || 'and dps.dept = v_ticket_type_head.filter_merch_id ';
   ELSIF(GP_ticket_type_merch_level = 'C') THEN
      L_merch_exists := L_merch_exists || 'and cls.class = v_ticket_type_head.filter_merch_id_class ' ||
                                          'and cls.dept  = v_ticket_type_head.filter_merch_id ';
   ELSIF(GP_ticket_type_merch_level = 'S') THEN
      L_merch_exists := L_merch_exists || 'and sub.subclass = v_ticket_type_head.filter_merch_id_subclass ' ||
                                          'and sub.class    = v_ticket_type_head.filter_merch_id_class ' ||
                                          'and sub.dept     = v_ticket_type_head.filter_merch_id ';
   END IF;
   ---
   L_merch_exists := L_merch_exists || 'and rownum = 1)';
   ---

   L_predicate := ASSEMBLY(L_org_null, L_org_exists, L_merch_null, L_merch_exists);

   RETURN L_predicate;

END V_TICKET_TYPE_HEAD_S;

--------------------------------------------------------------------------------
-- V_TRANSFER_FROM_STORE_S()
--------------------------------------------------------------------------------
FUNCTION V_TRANSFER_FROM_STORE_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF ( GP_filter_org = 'N' ) THEN
      RETURN NULL;
   ELSE
      L_predicate := 'store in (select sh.store ' ||
                     ' from sec_group_loc_matrix sglm, sec_user_group sug, store_hierarchy sh ' ||
                     'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     '  and sglm.group_id = sug.group_id ' ||
                     '  and sglm.column_code = ''LTXFRM'' ' ||
                     '  and sh.region = sglm.region ' ||
                     '  and sh.district = NVL(sglm.district, sh.district)' ||
                     '  and sh.store = NVL(sglm.store, sh.store))';
   END IF;

   RETURN L_predicate;

END V_TRANSFER_FROM_STORE_S;

--------------------------------------------------------------------------------
-- V_TRANSFER_FROM_WH_S()
--------------------------------------------------------------------------------
FUNCTION V_TRANSFER_FROM_WH_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF ( GP_filter_org = 'N' ) THEN
      RETURN NULL;
   ELSE
      L_predicate := 'wh in (select sglm.wh ' ||
                     'from sec_group_loc_matrix sglm, sec_user_group sug ' ||
                     'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') '  ||
                     '  and sglm.group_id = sug.group_id ' ||
                     '  and sglm.column_code = ''LTXFRM'' ' ||
                     '  and sglm.wh is not null)';
   END IF;

   RETURN L_predicate;

END V_TRANSFER_FROM_WH_S;

--------------------------------------------------------------------------------
-- V_TRANSFER_TO_STORE_S()
--------------------------------------------------------------------------------
FUNCTION V_TRANSFER_TO_STORE_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF ( GP_filter_org = 'N' ) THEN
      RETURN NULL;
   ELSE
      L_predicate := 'store in (select sh.store ' ||
                     ' from sec_group_loc_matrix sglm, sec_user_group sug, store_hierarchy sh ' ||
                     'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     '  and sglm.group_id = sug.group_id ' ||
                     '  and sglm.column_code = ''LTXFTO'' ' ||
                     '  and sh.region = sglm.region ' ||
                     '  and sh.district = NVL(sglm.district, sh.district) ' ||
                     '  and sh.store = NVL(sglm.store, sh.store)) ';
   END IF;

   RETURN L_predicate;

END V_TRANSFER_TO_STORE_S;

--------------------------------------------------------------------------------
-- V_TRANSFER_TO_WH_S()
--------------------------------------------------------------------------------
FUNCTION V_TRANSFER_TO_WH_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF ( GP_filter_org = 'N' ) THEN
      RETURN NULL;
   ELSE
      L_predicate := ' wh in (select sglm.wh ' ||
                     ' from sec_group_loc_matrix sglm, sec_user_group sug ' ||
                     ' where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') '  ||
                     '   and sglm.group_id = sug.group_id ' ||
                     '   and sglm.column_code = ''LTXFTO'' ' ||
                     '   and sglm.wh is not NULL) ';
   END IF;

   RETURN L_predicate;

END V_TRANSFER_TO_WH_S;

--------------------------------------------------------------------------------
-- V_TSF_ENTITY_S()
--------------------------------------------------------------------------------

FUNCTION V_TSF_ENTITY_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_org = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     'from filter_group_org fgo, sec_user_group sug ' ||
                     'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     'and sug.group_id = fgo.sec_group_id ' ||
                     'and fgo.filter_org_level = ''T'' ' ||
                     'and fgo.filter_org_id = v_tsf_entity.tsf_entity_id ' ||
                     'and rownum = 1)';
   END IF;

   ---
   RETURN L_predicate;

END V_TSF_ENTITY_S;

--------------------------------------------------------------------------------
-- V_UDA_S()
--------------------------------------------------------------------------------

FUNCTION V_UDA_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(3000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

   L_org_null           VARCHAR2(50);
   L_merch_null         VARCHAR2(50);
   L_org_exists         VARCHAR2(1000);
   L_merch_exists       VARCHAR2(1500);

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF(GP_filter_org = 'N' AND GP_filter_merch = 'N') THEN
      RETURN NULL;
   END IF;

   L_org_null := 'v_uda.filter_org_id is NULL';

   L_merch_null := 'v_uda.filter_merch_id is NULL';

   L_org_exists := 'exists (select ''X'' ' ||
                   '          from sec_user_group sug, filter_group_org fgo, area ara, region reg, district dis ' ||
                   '         where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                   '           and sug.group_id = fgo.sec_group_id ' ||
                   '           and ara.area = reg.area ' ||
                   '           and reg.region = dis.region ' ||
                   '           and fgo.filter_org_level in (''C'', ''A'', ''R'', ''D'') ' ||
                   '           and ara.chain    = decode(fgo.filter_org_level, ''C'', fgo.filter_org_id, ara.chain) ' ||
                   '           and ara.area     = decode(fgo.filter_org_level, ''A'', fgo.filter_org_id, ara.area) ' ||
                   '           and reg.region   = decode(fgo.filter_org_level, ''R'', fgo.filter_org_id, reg.region) ' ||
                   '           and dis.district = decode(fgo.filter_org_level, ''D'', fgo.filter_org_id, dis.district) ';

   IF(GP_uda_org_level = 'C') THEN
      L_org_exists := L_org_exists || 'and ara.chain = v_uda.filter_org_id ';
   ELSIF(GP_uda_org_level = 'A') THEN
      L_org_exists := L_org_exists || 'and ara.area = v_uda.filter_org_id ';
   ELSIF(GP_uda_org_level = 'R') THEN
      L_org_exists := L_org_exists || 'and reg.region = v_uda.filter_org_id ';
   ELSIF(GP_uda_org_level = 'D') THEN
      L_org_exists := L_org_exists || 'and dis.district = v_uda.filter_org_id ';
   END IF;
   ---
   L_org_exists := L_org_exists || 'and rownum = 1)';
   ---
   L_merch_exists := 'exists (select ''X'' ' ||
                     '          from sec_user_group sug, filter_group_merch fgm, groups gps, deps dps, class cls, subclass sub ' ||
                     '         where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     '           and sug.group_id = fgm.sec_group_id ' ||
                     '           and gps.group_no = dps.group_no ' ||
                     '           and dps.dept     = cls.dept ' ||
                     '           and cls.dept     = sub.dept ' ||
                     '           and cls.class    = sub.class ' ||
                     '           and gps.division = decode(fgm.filter_merch_level, ''D'', fgm.filter_merch_id, gps.division) ' ||
                     '           and gps.group_no = decode(fgm.filter_merch_level, ''G'', fgm.filter_merch_id, gps.group_no) ' ||
                     '           and dps.dept     = decode(fgm.filter_merch_level, ''P'', fgm.filter_merch_id, dps.dept) ' ||
                     '           and cls.class    = decode(fgm.filter_merch_level, ''C'', fgm.filter_merch_id_class, cls.class) ' ||
                     '           and cls.dept     = decode(fgm.filter_merch_level, ''C'', fgm.filter_merch_id, cls.dept) ' ||
                     '           and sub.subclass = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_subclass, sub.subclass) ' ||
                     '           and sub.class    = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id_class, sub.class) ' ||
                     '           and sub.dept     = decode(fgm.filter_merch_level, ''S'', fgm.filter_merch_id, sub.dept) ';

   IF(GP_uda_merch_level = 'D') THEN
      L_merch_exists := L_merch_exists || 'and gps.division = v_uda.filter_merch_id ';
   ELSIF(GP_uda_merch_level = 'G') THEN
      L_merch_exists := L_merch_exists || 'and gps.group_no = v_uda.filter_merch_id ';
   ELSIF(GP_uda_merch_level = 'P') THEN
      L_merch_exists := L_merch_exists || 'and dps.dept = v_uda.filter_merch_id ';
   ELSIF(GP_uda_merch_level = 'C') THEN
      L_merch_exists := L_merch_exists || 'and cls.class = v_uda.filter_merch_id_class ' ||
                                          'and cls.dept  = v_uda.filter_merch_id ';
   ELSIF(GP_uda_merch_level = 'S') THEN
      L_merch_exists := L_merch_exists || 'and sub.subclass = v_uda.filter_merch_id_subclass ' ||
                                          'and sub.class    = v_uda.filter_merch_id_class ' ||
                                          'and sub.dept     = v_uda.filter_merch_id ';
   END IF;
   ---
   L_merch_exists := L_merch_exists || 'and rownum = 1)';
   ---

   L_predicate := ASSEMBLY(L_org_null, L_org_exists, L_merch_null, L_merch_exists);

   RETURN L_predicate;

END V_UDA_S;

--------------------------------------------------------------------------------
-- V_WH_S()
--------------------------------------------------------------------------------

FUNCTION V_WH_S(d1 VARCHAR2, d2 VARCHAR2)
RETURN VARCHAR2 IS

   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;

BEGIN

   IF NOT GP_filter_set THEN
      L_dummy := SET_USER_FILTER(L_err_msg);
      IF NOT L_dummy THEN
         RETURN NULL;
      END IF;
   END IF;

   IF GP_filter_org = 'N' THEN
      RETURN NULL;
   ELSE
      L_predicate := 'exists (select ''X'' ' ||
                     'from filter_group_org fgo, sec_user_group sug ' ||
                     'where sug.user_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     'and sug.group_id = fgo.sec_group_id ' ||
                     'and fgo.filter_org_level = ''W'' ' ||
                     'and fgo.filter_org_id = v_wh.wh ' ||
                     'and rownum = 1)';
   END IF;

   ---
   RETURN L_predicate;

END V_WH_S;
--------------------------------------------------------------------------------
-- 10-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 Begin
--------------------------------------------------------------------------------
-- V_TSL_NON_MERCH_CODE_S
--------------------------------------------------------------------------------
FUNCTION V_TSL_NON_MERCH_CODE_S(d1 VARCHAR2,
                                d2 VARCHAR2)
RETURN VARCHAR2 IS
   L_predicate          VARCHAR2(2000);
   L_err_msg            VARCHAR2(250);
   L_dummy              BOOLEAN;
BEGIN

   if NOT GP_filter_set then
      L_dummy := SET_USER_FILTER(L_err_msg);
      if NOT L_dummy then
         return NULL;
      end if;
   end if;

   if GP_data_sec_ind = 'N' then
      return NULL;
   elsif GP_tsl_loc_sec_ind = 'N' then
      return NULL;
   -- 15-Nov-2010,DefNBS019716, Vinutha Raju, Vinutha.raju@in.tesco.com, Begin
   elsif GP_filter_merch = 'N' THEN
      return NULL;
   -- 15-Nov-2010,DefNBS019716, Vinutha Raju, Vinutha.raju@in.tesco.com, End
   else
        L_predicate := 'exists (Select ''X'' '||
                     '          from tsl_bhms_users a, tsl_bhms_hierarchy b , tsl_bhms_user_nonmerch_code c'||
                     '         where a.role_id= b.role_id'||
                     '           and b.role_id= c.role_id'||
                     '           and a.tpx_id =SYS_CONTEXT(''USERENV'', ''SESSION_USER'') ' ||
                     '           and c.non_merch_code = v_tsl_non_merch_code.non_merch_code) ';
   end if;
   ---
   RETURN L_predicate;

END V_TSL_NON_MERCH_CODE_S;
--------------------------------------------------------------------------------
-- 10-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 End
--------------------------------------------------------------------------------
END Filter_Policy_Sql;
/

