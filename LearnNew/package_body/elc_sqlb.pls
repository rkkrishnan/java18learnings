CREATE OR REPLACE PACKAGE BODY ELC_SQL AS
--------------------------------------------------------------------------------------
-- Mod By        : Vinutha Raju, vinutha.raju@in.tesco.com
-- Mod Date      : 03-Oct-2011
-- Mod Ref       : CR409
-- Mod Details   : Added new functions TSL_CHK_DUPLICATE_FISCAL,TSL_FISCAL_COMPID_INSERT
--                 TSL_FISCAL_COMPID_DELETE,TSL_FISCAL_COMPID_EXISTS,TSL_FISCAL_ZONEID_EXISTS
-----------------------------------------------------------------------------------------------
-- Mod By        : Vinutha Raju, vinutha.raju@in.tesco.com
-- Mod Date      : 06-Jan-2012
-- Mod Ref       : DefNBS024103
-- Mod Details   : Modified TSL_FISCAL_COMPID_INSERT, TSL_FISCAL_COMPID_DELETE,
--                 TSL_FISCAL_COMPID_EXISTS, TSL_FISCAL_ZONEID_EXISTS
-----------------------------------------------------------------------------------------------
FUNCTION CHECK_DELETE_COMP(O_error_message IN OUT VARCHAR2,
                           O_exists        IN OUT BOOLEAN,
                           I_comp_id       IN     ELC_COMP.COMP_ID%TYPE,
                           I_comp_type     IN     ELC_COMP.COMP_TYPE%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.CHECK_DELETE_COMP';
   L_exists  VARCHAR2(1);

   cursor C_CHECK_EXP_PROF is
      select 'Y'
        from exp_prof_detail
       where comp_id = I_comp_id;

   cursor C_CHECK_ITEM_EXP is
      select 'Y'
        from item_exp_detail
       where comp_id = I_comp_id;

   cursor C_CHECK_ITEM_HTS is
      select 'Y'
        from item_hts_assess
       where comp_id = I_comp_id;

   cursor C_CHECK_ORDLOC_EXP is
      select 'Y'
        from ordloc_exp
       where comp_id = I_comp_id;

   cursor C_CHECK_ORDSKU_HTS is
      select 'Y'
        from ordsku_hts_assess
       where comp_id = I_comp_id;

   cursor C_CHECK_CVB_DETAIL is
      select 'Y'
        from cvb_detail
       where comp_id = I_comp_id;

   cursor C_CHECK_OBL_COMP is
      select 'Y'
        from obligation_comp
       where comp_id = I_comp_id;

   cursor C_CHECK_ALC_COMP_LOC is
      select 'Y'
        from alc_comp_loc
       where comp_id = I_comp_id;

   cursor C_ITEM_CHRG_DETAIL is
      select 'Y'
        from item_chrg_detail
       where comp_id = I_comp_id;

   cursor C_TSFDETAIL_CHRG is
      select 'Y'
        from tsfdetail_chrg
       where comp_id = I_comp_id;

   cursor C_CHECK_DEPT_CHRG_DETAIL is
      select 'Y'
        from dept_chrg_detail
       where comp_id = I_comp_id;

BEGIN
   if I_comp_type = 'E' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_EXP_PROF','EXP_PROF_DETAIL','Comp id: '|| I_comp_id);
      open C_CHECK_EXP_PROF;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_EXP_PROF','EXP_PROF_DETAIL','Comp id: '|| I_comp_id);
      fetch C_CHECK_EXP_PROF into L_exists;
      ---
      if C_CHECK_EXP_PROF%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_EXP_PROF','EXP_PROF_DETAIL','Comp id: '|| I_comp_id);
         close C_CHECK_EXP_PROF;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_EXP_PROF','EXP_PROF_DETAIL','Comp id: '|| I_comp_id);
      close C_CHECK_EXP_PROF;
      ---
      SQL_LIB.SET_MARK('OPEN','C_CHECK_ITEM_EXP','ITEM_EXP_DETAIL','Comp id: '|| I_comp_id);
      open C_CHECK_ITEM_EXP;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_ITEM_EXP','ITEM_EXP_DETAIL','Comp id: '|| I_comp_id);
      fetch C_CHECK_ITEM_EXP into L_exists;
      ---
      if C_CHECK_ITEM_EXP%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_EXP','ITEM_EXP_DETAIL','Comp id: '|| I_comp_id);
         close C_CHECK_ITEM_EXP;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_EXP','ITEM_EXP_DETAIL','Comp id: '|| I_comp_id);
      close C_CHECK_ITEM_EXP;
      ---
      SQL_LIB.SET_MARK('OPEN','C_CHECK_ORDLOC_EXP','ORDLOC_EXP','Comp id: '|| I_comp_id);
      open C_CHECK_ORDLOC_EXP;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_ORDLOC_EXP','ORDLOC_EXP','Comp id: '|| I_comp_id);
      fetch C_CHECK_ORDLOC_EXP into L_exists;
      ---
      if C_CHECK_ORDLOC_EXP%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_ORDLOC_EXP','ORDLOC_EXP','Comp id: '|| I_comp_id);
         close C_CHECK_ORDLOC_EXP;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ORDLOC_EXP','ORDLOC_EXP','Comp id: '|| I_comp_id);
      close C_CHECK_ORDLOC_EXP;
   elsif I_comp_type = 'A' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_ITEM_HTS','ITEM_HTS_ASSESS','Comp id: '|| I_comp_id);
      open C_CHECK_ITEM_HTS;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_ITEM_HTS','ITEM_HTS_ASSESS','Comp id: '|| I_comp_id);
      fetch C_CHECK_ITEM_HTS into L_exists;
      ---
      if C_CHECK_ITEM_HTS%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_HTS','ITEM_HTS_ASSESS','Comp id: '|| I_comp_id);
         close C_CHECK_ITEM_HTS;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_HTS','ITEM_HTS_ASSESS','Comp id: '|| I_comp_id);
      close C_CHECK_ITEM_HTS;
      ---
      SQL_LIB.SET_MARK('OPEN','C_CHECK_ORDSKU_HTS','ORDSKU_HTS_ASSESS','Comp id: '|| I_comp_id);
      open C_CHECK_ORDSKU_HTS;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_ORDSKU_HTS','ORDSKU_HTS_ASSESS','Comp id: '|| I_comp_id);
      fetch C_CHECK_ORDSKU_HTS into L_exists;
      ---
      if C_CHECK_ORDSKU_HTS%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_ORDSKU_HTS','ORDSKU_HTS_ASSESS','Comp id: '|| I_comp_id);
         close C_CHECK_ORDSKU_HTS;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ORDSKU_HTS','ORDSKU_HTS_ASSESS','Comp id: '|| I_comp_id);
      close C_CHECK_ORDSKU_HTS;
   else    -- I_comp_type = 'U'
      SQL_LIB.SET_MARK('OPEN','C_ITEM_CHRG_DETAIL','ITEM_CHRG_DETAIL','Comp id: '|| I_comp_id);
      open C_ITEM_CHRG_DETAIL;
      SQL_LIB.SET_MARK('FETCH','C_ITEM_CHRG_DETAIL','ITEM_CHRG_DETAIL','Comp id: '|| I_comp_id);
      fetch C_ITEM_CHRG_DETAIL into L_exists;
      ---
      if C_ITEM_CHRG_DETAIL%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_ITEM_CHRG_DETAIL','ITEM_CHRG_DETAIL','Comp id: '|| I_comp_id);
         close C_ITEM_CHRG_DETAIL;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_ITEM_CHRG_DETAIL','ITEM_CHRG_DETAIL','Comp id: '|| I_comp_id);
      close C_ITEM_CHRG_DETAIL;
      ---
      SQL_LIB.SET_MARK('OPEN','C_TSFDETAIL_CHRG','TSFDETAIL_CHRG','Comp id: '|| I_comp_id);
      open C_TSFDETAIL_CHRG;
      SQL_LIB.SET_MARK('FETCH','C_TSFDETAIL_CHRG','TSFDETAIL_CHRG','Comp id: '|| I_comp_id);
      fetch C_TSFDETAIL_CHRG into L_exists;
      ---
      if C_TSFDETAIL_CHRG%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_TSFDETAIL_CHRG','TSFDETAIL_CHRG','Comp id: '|| I_comp_id);
         close C_TSFDETAIL_CHRG;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_TSFDETAIL_CHRG','TSFDETAIL_CHRG','Comp id: '|| I_comp_id);
      close C_TSFDETAIL_CHRG;
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_DEPT_CHRG_DETAIL', 'DEPT_CHRG_DETAIL', 'Comp_id:  '||I_comp_id);
      open C_CHECK_DEPT_CHRG_DETAIL;
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_DEPT_CHRG_DETAIL', 'DEPT_CHRG_DETAIL', 'Comp_id:  '||I_comp_id);
      fetch C_CHECK_DEPT_CHRG_DETAIL into L_exists;
      if C_CHECK_DEPT_CHRG_DETAIL%FOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_DEPT_CHRG_DETAIL', 'DEPT_CHRG_DETAIL', 'Comp_id:  '||I_comp_id);
         close C_CHECK_DEPT_CHRG_DETAIL;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP', NULL, NULL, NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_DEPT_CHRG_DETAIL', 'DEPT_CHRG_DETAIL', 'Comp_id:  '||I_comp_id);
      close C_CHECK_DEPT_CHRG_DETAIL;
      ---
   end if;  -- I_comp_type = 'E/A/U'
   ---
   if I_comp_type in ('E','A') then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_OBL_COMP','OBLIGATION_COMP','Comp id: '|| I_comp_id);
      open C_CHECK_OBL_COMP;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_OBL_COMP','OBLIGATION_COMP','Comp id: '|| I_comp_id);
      fetch C_CHECK_OBL_COMP into L_exists;
      ---
      if C_CHECK_OBL_COMP%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_OBL_COMP','OBLIGATION_COMP','Comp id: '|| I_comp_id);
         close C_CHECK_OBL_COMP;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_OBL_COMP','OBLIGATION_COMP','Comp id: '|| I_comp_id);
      close C_CHECK_OBL_COMP;
      ---
      SQL_LIB.SET_MARK('OPEN','C_CHECK_ALC_COMP_LOC','ALC_COMP_LOC','Comp id: '|| I_comp_id);
      open C_CHECK_ALC_COMP_LOC;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_ALC_COMP_LOC','ALC_COMP_LOC','Comp id: '|| I_comp_id);
      fetch C_CHECK_ALC_COMP_LOC into L_exists;
      ---
      if C_CHECK_ALC_COMP_LOC%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_ALC_COMP_LOC','ALC_COMP_LOC','Comp id: '|| I_comp_id);
         close C_CHECK_ALC_COMP_LOC;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ALC_COMP_LOC','ALC_COMP_LOC','Comp id: '|| I_comp_id);
      close C_CHECK_ALC_COMP_LOC;
      ---
      SQL_LIB.SET_MARK('OPEN','C_CHECK_CVB_DETAIL','CVB_DETAIL','Comp id: '|| I_comp_id);
      open C_CHECK_CVB_DETAIL;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_CVB_DETAIL','CVB_DETAIL','Comp id: '|| I_comp_id);
      fetch C_CHECK_CVB_DETAIL into L_exists;
      ---
      if C_CHECK_CVB_DETAIL%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_CVB_DETAIL','CVB_DETAIL','Comp id: '|| I_comp_id);
         close C_CHECK_CVB_DETAIL;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_COMP',NULL,NULL,NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_CVB_DETAIL','CVB_DETAIL','Comp id: '|| I_comp_id);
      close C_CHECK_CVB_DETAIL;
   end if;
   ---
   -- comp id is not being referenced anywhere else.
   O_exists := FALSE;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_DELETE_COMP;
--------------------------------------------------------------------------------------
FUNCTION CHECK_DELETE_CVB(O_error_message IN OUT VARCHAR2,
                          O_exists        IN OUT BOOLEAN,
                          I_cvb_code      IN     CVB_HEAD.CVB_CODE%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.CHECK_DELETE_CVB';
   L_exists  VARCHAR2(1);

   cursor C_CHECK_EXP_PROF is
      select 'Y'
        from exp_prof_detail
       where cvb_code = I_cvb_code;

   cursor C_CHECK_ITEM_EXP is
      select 'Y'
        from item_exp_detail
       where cvb_code = I_cvb_code;

   cursor C_CHECK_ITEM_HTS is
      select 'Y'
        from item_hts_assess
       where cvb_code = I_cvb_code;

   cursor C_CHECK_ORDLOC_EXP is
      select 'Y'
        from ordloc_exp
       where cvb_code = I_cvb_code;

   cursor C_CHECK_ORDSKU_HTS is
      select 'Y'
        from ordsku_hts_assess
       where cvb_code = I_cvb_code;

   cursor C_CHECK_ELC_COMP is
      select 'Y'
        from elc_comp
       where cvb_code = I_cvb_code;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_CHECK_EXP_PROF','EXP_PROF_DETAIL','cvb code: '|| I_cvb_code);
   open C_CHECK_EXP_PROF;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_EXP_PROF','EXP_PROF_DETAIL','cvb code: '|| I_cvb_code);
   fetch C_CHECK_EXP_PROF into L_exists;
   ---
   if C_CHECK_EXP_PROF%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_EXP_PROF','EXP_PROF_DETAIL','cvb code: '|| I_cvb_code);
      close C_CHECK_EXP_PROF;
      O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_CVB',NULL,NULL,NULL);
      O_exists := TRUE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_EXP_PROF','EXP_PROF_DETAIL','cvb code: '|| I_cvb_code);
   close C_CHECK_EXP_PROF;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_ITEM_EXP','ITEM_EXP_DETAIL','cvb code: '|| I_cvb_code);
   open C_CHECK_ITEM_EXP;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ITEM_EXP','ITEM_EXP_DETAIL','cvb code: '|| I_cvb_code);
   fetch C_CHECK_ITEM_EXP into L_exists;
   ---
   if C_CHECK_ITEM_EXP%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_EXP','ITEM_EXP_DETAIL','cvb code: '|| I_cvb_code);
      close C_CHECK_ITEM_EXP;
      O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_CVB',NULL,NULL,NULL);
      O_exists := TRUE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_EXP','ITEM_EXP_DETAIL','cvb code: '|| I_cvb_code);
   close C_CHECK_ITEM_EXP;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_ITEM_HTS','ITEM_HTS_ASSESS','cvb code: '|| I_cvb_code);
   open C_CHECK_ITEM_HTS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ITEM_HTS','ITEM_HTS_ASSESS','cvb code: '|| I_cvb_code);
   fetch C_CHECK_ITEM_HTS into L_exists;
   ---
   if C_CHECK_ITEM_HTS%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_HTS','ITEM_HTS_ASSESS','cvb code: '|| I_cvb_code);
      close C_CHECK_ITEM_HTS;
      O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_CVB',NULL,NULL,NULL);
      O_exists := TRUE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_HTS','ITEM_HTS_ASSESS','cvb code: '|| I_cvb_code);
   close C_CHECK_ITEM_HTS;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_ORDLOC_EXP','ORDLOC_EXP','cvb code: '|| I_cvb_code);
   open C_CHECK_ORDLOC_EXP;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ORDLOC_EXP','ORDLOC_EXP','cvb code: '|| I_cvb_code);
   fetch C_CHECK_ORDLOC_EXP into L_exists;
   ---
   if C_CHECK_ORDLOC_EXP%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ORDLOC_EXP','ORDLOC_EXP','cvb code: '|| I_cvb_code);
      close C_CHECK_ORDLOC_EXP;
      O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_CVB',NULL,NULL,NULL);
      O_exists := TRUE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ORDLOC_EXP','ORDLOC_EXP','cvb code: '|| I_cvb_code);
   close C_CHECK_ORDLOC_EXP;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_ORDSKU_HTS','ORDSKU_HTS_ASSESS','cvb code: '|| I_cvb_code);
   open C_CHECK_ORDSKU_HTS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ORDSKU_HTS','ORDSKU_HTS_ASSESS','cvb code: '|| I_cvb_code);
   fetch C_CHECK_ORDSKU_HTS into L_exists;
   ---
   if C_CHECK_ORDSKU_HTS%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ORDSKU_HTS','ORDSKU_HTS_ASSESS','cvb code: '|| I_cvb_code);
      close C_CHECK_ORDSKU_HTS;
      O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_CVB',NULL,NULL,NULL);
      O_exists := TRUE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ORDSKU_HTS','ORDSKU_HTS_ASSESS','cvb code: '|| I_cvb_code);
   close C_CHECK_ORDSKU_HTS;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_ELC_COMP','ELC_COMP','cvb code: '|| I_cvb_code);
   open C_CHECK_ELC_COMP;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ELC_COMP','ELC_COMP','cvb code: '|| I_cvb_code);
   fetch C_CHECK_ELC_COMP into L_exists;
   ---
   if C_CHECK_ELC_COMP%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ELC_COMP','ELC_COMP','cvb code: '|| I_cvb_code);
      close C_CHECK_ELC_COMP;
      O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DELETE_CVB',NULL,NULL,NULL);
      O_exists := TRUE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ELC_COMP','ELC_COMP','cvb code: '|| I_cvb_code);
   close C_CHECK_ELC_COMP;
   ---
   -- cvb code is not being referenced anywhere else.
   O_exists := FALSE;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_DELETE_CVB;
--------------------------------------------------------------------------------------
FUNCTION GET_COMP_DESC(O_error_message  IN OUT VARCHAR2,
                       O_exists         IN OUT BOOLEAN,
                       O_comp_desc      IN OUT ELC_COMP.COMP_DESC%TYPE,
                       I_comp_id        IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS

   L_program  VARCHAR2(50) := 'ELC_SQL.GET_COMP_DESC';

   cursor C_GET_COMP_DESC is
      select comp_desc
        from elc_comp
       where comp_id = I_comp_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_COMP_DESC','ELC_COMP','Comp id: '|| I_comp_id);
   open C_GET_COMP_DESC;
   SQL_LIB.SET_MARK('FETCH','C_GET_COMP_DESC','ELC_COMP','Comp id: '|| I_comp_id);
   fetch C_GET_COMP_DESC into O_comp_desc;
   ---
   if C_GET_COMP_DESC%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_DESC','ELC_COMP','Comp id: '|| I_comp_id);
      close C_GET_COMP_DESC;
      O_error_message := SQL_LIB.CREATE_MSG('COMP_NOT_EXIST',NULL,NULL,NULL);
      O_exists := FALSE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_DESC','ELC_COMP','Comp id: '|| I_comp_id);
   close C_GET_COMP_DESC;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_comp_desc,
                             O_comp_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   O_exists := TRUE;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_COMP_DESC;
--------------------------------------------------------------------------------------
FUNCTION GET_CVB_DESC(O_error_message IN OUT VARCHAR2,
                      O_exists        IN OUT BOOLEAN,
                      O_cvb_desc      IN OUT CVB_HEAD.CVB_DESC%TYPE,
                      I_cvb_code      IN     CVB_HEAD.CVB_CODE%TYPE)
RETURN BOOLEAN IS

   L_program  VARCHAR2(50) := 'ELC_SQL.GET_CVB_DESC';

   cursor C_GET_CVB_DESC is
      select cvb_desc
        from cvb_head
       where cvb_code = I_cvb_code;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_CVB_DESC','CVB_HEAD','cvb code: '|| I_cvb_code);
   open C_GET_CVB_DESC;
   SQL_LIB.SET_MARK('FETCH','C_GET_CVB_DESC','CVB_HEAD','cvb code: '|| I_cvb_code);
   fetch C_GET_CVB_DESC into O_cvb_desc;
   ---
   if C_GET_CVB_DESC%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_GET_CVB_DESC','CVB_HEAD','cvb code: '|| I_cvb_code);
      close C_GET_CVB_DESC;
      O_error_message := SQL_LIB.CREATE_MSG('CVB_NOT_EXIST',NULL,NULL,NULL);
      O_exists := FALSE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_CVB_DESC','CVB_HEAD','cvb code: '|| I_cvb_code);
   close C_GET_CVB_DESC;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_cvb_desc,
                             O_cvb_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   O_exists := TRUE;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_CVB_DESC;
--------------------------------------------------------------------------------------
FUNCTION GET_COMP_DETAILS(O_error_message  IN OUT VARCHAR2,
                          O_exists         IN OUT BOOLEAN,
                          O_comp_desc      IN OUT ELC_COMP.COMP_DESC%TYPE,
                          O_comp_type      IN OUT ELC_COMP.COMP_TYPE%TYPE,
                          O_expense_type   IN OUT ELC_COMP.EXPENSE_TYPE%TYPE,
                          O_assess_type    IN OUT ELC_COMP.ASSESS_TYPE%TYPE,
                          O_import_country IN OUT ELC_COMP.IMPORT_COUNTRY_ID%TYPE,
                          O_cvb_code       IN OUT CVB_HEAD.CVB_CODE%TYPE,
                          O_comp_rate      IN OUT ELC_COMP.COMP_RATE%TYPE,
                          O_calc_basis     IN OUT ELC_COMP.CALC_BASIS%TYPE,
                          O_cost_basis     IN OUT ELC_COMP.COST_BASIS%TYPE,
                          O_display_order  IN OUT ELC_COMP.DISPLAY_ORDER%TYPE,
                          O_comp_currency  IN OUT CURRENCIES.CURRENCY_CODE%TYPE,
                          O_per_count      IN OUT ELC_COMP.PER_COUNT%TYPE,
                          O_per_count_uom  IN OUT ELC_COMP.PER_COUNT_UOM%TYPE,
                          O_nom_flag_1     IN OUT ELC_COMP.NOM_FLAG_1%TYPE,
                          O_nom_flag_2     IN OUT ELC_COMP.NOM_FLAG_2%TYPE,
                          O_nom_flag_3     IN OUT ELC_COMP.NOM_FLAG_3%TYPE,
                          O_nom_flag_4     IN OUT ELC_COMP.NOM_FLAG_4%TYPE,
                          O_nom_flag_5     IN OUT ELC_COMP.NOM_FLAG_5%TYPE,
                          I_comp_id        IN     ELC_COMP.COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.GET_COMP_DETAILS';

   cursor C_GET_COMP_INFO is
      select comp_desc,
             comp_type,
             expense_type,
             assess_type,
             import_country_id,
             cvb_code,
             comp_rate,
             calc_basis,
             cost_basis,
             display_order,
             comp_currency,
             per_count,
             per_count_uom,
             nom_flag_1,
             nom_flag_2,
             nom_flag_3,
             nom_flag_4,
             nom_flag_5
        from elc_comp
       where comp_id = I_comp_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_COMP_INFO','ELC_COMP','Comp id: '|| I_comp_id);
   open C_GET_COMP_INFO;
   SQL_LIB.SET_MARK('FETCH','C_GET_COMP_INFO','ELC_COMP','Comp id: '|| I_comp_id);
   fetch C_GET_COMP_INFO into O_comp_desc,
                              O_comp_type,
                              O_expense_type,
                              O_assess_type,
                              O_import_country,
                              O_cvb_code,
                              O_comp_rate,
                              O_calc_basis,
                              O_cost_basis,
                              O_display_order,
                              O_comp_currency,
                              O_per_count,
                              O_per_count_uom,
                              O_nom_flag_1,
                              O_nom_flag_2,
                              O_nom_flag_3,
                              O_nom_flag_4,
                              O_nom_flag_5;
   ---
   if C_GET_COMP_INFO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_INFO','ELC_COMP','Comp id: '|| I_comp_id);
      close C_GET_COMP_INFO;
      O_error_message := SQL_LIB.CREATE_MSG('ERR_COMP_DTLS',I_comp_id,NULL,NULL);
      O_exists := FALSE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_INFO','ELC_COMP','Comp id: '|| I_comp_id);
   close C_GET_COMP_INFO;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_comp_desc,
                             O_comp_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   O_exists := TRUE;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_COMP_DETAILS;
--------------------------------------------------------------------------------------
FUNCTION GET_CALC_BASIS(O_error_message IN OUT VARCHAR2,
                        O_calc_basis    IN OUT ELC_COMP.CALC_BASIS%TYPE,
                        I_comp_id       IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.GET_CALC_BASIS';

   cursor C_GET_CALC_BASIS is
      select calc_basis
        from elc_comp
       where comp_id = I_comp_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_CALC_BASIS','ELC_COMP','Comp id: '|| I_comp_id);
   open C_GET_CALC_BASIS;
   SQL_LIB.SET_MARK('FETCH','C_GET_CALC_BASIS','ELC_COMP','Comp id: '|| I_comp_id);
   fetch C_GET_CALC_BASIS into O_calc_basis;
   ---
   if C_GET_CALC_BASIS%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_GET_CALC_BASIS','ELC_COMP','Comp id: '|| I_comp_id);
      close C_GET_CALC_BASIS;
      O_error_message := SQL_LIB.CREATE_MSG('NO_CALC_BASIS',NULL,NULL,NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_CALC_BASIS','ELC_COMP','Comp id: '|| I_comp_id);
   close C_GET_CALC_BASIS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_CALC_BASIS;
--------------------------------------------------------------------------------------
FUNCTION GET_ASSESS_CURRENCY(O_error_message     IN OUT VARCHAR2,
                             O_exists            IN OUT BOOLEAN,
                             O_comp_currency     IN OUT ELC_COMP.COMP_CURRENCY%TYPE,
                             I_import_country_id IN     ELC_COMP.IMPORT_COUNTRY_ID%TYPE,
                             I_comp_id           IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.GET_ASSESS_CURRENCY';

   cursor C_GET_CURRENCY is
      select comp_currency
        from elc_comp
       where import_country_id = I_import_country_id
         and comp_id           = NVL(I_comp_id,comp_id);

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CURRENCY',
                    'ELC_COMP',
                    'Import country: '|| I_import_country_id ||', Component: ' || I_comp_id);
   open C_GET_CURRENCY;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_CURRENCY',
                    'ELC_COMP',
                    'Import country: '|| I_import_country_id ||', Component: ' || I_comp_id);
   fetch C_GET_CURRENCY into O_comp_currency;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CURRENCY',
                    'ELC_COMP',
                    'Import country: '|| I_import_country_id ||', Component: ' || I_comp_id);
   close C_GET_CURRENCY;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ASSESS_CURRENCY;
--------------------------------------------------------------------------------------
FUNCTION GET_ASSESS_DEFAULT_CURRENCY(O_error_message     IN OUT VARCHAR2,
                                     O_exists            IN OUT BOOLEAN,
                                     O_comp_currency     IN OUT ELC_COMP.COMP_CURRENCY%TYPE,
                                     I_import_country_id IN     ELC_COMP.IMPORT_COUNTRY_ID%TYPE,
                                     I_comp_id           IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.GET_ASSESS_DEFAULT_CURRENCY';

   cursor C_GET_CURRENCY is
      select comp_currency
        from elc_comp
       where import_country_id = I_import_country_id
         and comp_id          != I_comp_id;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_CURRENCY','ELC_COMP','Import country id: '|| I_import_country_id
                    || ', Component: ' || I_comp_id);
   open C_GET_CURRENCY;
   SQL_LIB.SET_MARK('FETCH','C_GET_CURRENCY','ELC_COMP','Import country id: '|| I_import_country_id
                    || ', Component: ' || I_comp_id);
   fetch C_GET_CURRENCY into O_comp_currency;
   ---
   if C_GET_CURRENCY%NOTFOUND then
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_CURRENCY','ELC_COMP','Import country id: '|| I_import_country_id
                    || ', Component: ' || I_comp_id);
   close C_GET_CURRENCY;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ASSESS_DEFAULT_CURRENCY;
--------------------------------------------------------------------------------------
FUNCTION ASSESS_TYPE_EXISTS(O_error_message IN OUT VARCHAR2,
                            O_exists        IN OUT BOOLEAN,
                            I_assess_type   IN     ELC_COMP.ASSESS_TYPE%TYPE)
RETURN BOOLEAN IS

   L_exists  ELC_COMP.ASSESS_TYPE%TYPE;
   L_program VARCHAR2(50) := 'ELC_SQL.ASSESS_TYPE_EXISTS';

   cursor C_GET_ASSESS_TYPE is
      select fee_type
        from hts_fee
       where fee_type = I_assess_type
      union all
      select tax_type
        from hts_tax
       where tax_type = I_assess_type;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_ASSESS_TYPE','HTS_FEE or HTS_TAX','Type: '|| I_assess_type);
   open C_GET_ASSESS_TYPE;
   SQL_LIB.SET_MARK('FETCH','C_GET_ASSESS_TYPE','HTS_FEE or HTS_TAX','Type: '|| I_assess_type);
   fetch C_GET_ASSESS_TYPE into L_exists;
   ---
   if C_GET_ASSESS_TYPE%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('ASSESS_NOT_EXIST',NULL,NULL,NULL);
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_ASSESS_TYPE','HTS_FEE or HTS_TAX','Type: '|| I_assess_type);
   close C_GET_ASSESS_TYPE;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ASSESS_TYPE_EXISTS;
--------------------------------------------------------------------------------------
FUNCTION COMP_EXISTS(O_error_message  IN OUT VARCHAR2,
                     O_exists         IN OUT BOOLEAN,
                     I_comp_id        IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.COMP_EXISTS';
   L_exists  VARCHAR2(1);

   cursor C_CHECK_COMP is
      select 'Y'
        from elc_comp
       where comp_id = I_comp_id;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_COMP','ELC_COMP','Comp id: '|| I_comp_id);
   open C_CHECK_COMP;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_COMP','ELC_COMP','Comp id: '|| I_comp_id);
   fetch C_CHECK_COMP into L_exists;
   ---
   if C_CHECK_COMP%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('COMP_NOT_EXIST',NULL,NULL,NULL);
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_COMP','ELC_COMP','Comp id: '|| I_comp_id);
   close C_CHECK_COMP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END COMP_EXISTS;
--------------------------------------------------------------------------------------
FUNCTION CVB_EXISTS(O_error_message IN OUT VARCHAR2,
                    O_exists        IN OUT BOOLEAN,
                    I_cvb_code      IN     CVB_HEAD.CVB_CODE%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.CVB_EXISTS';
   L_exists  VARCHAR2(1);

   cursor C_CHECK_CVB is
      select 'Y'
        from cvb_head
       where cvb_code = I_cvb_code;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_CVB','CVB_HEAD','cvb code: '|| I_cvb_code);
   open C_CHECK_CVB;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_CVB','CVB_HEAD','cvb code: '|| I_cvb_code);
   fetch C_CHECK_CVB into L_exists;
   ---
   if C_CHECK_CVB%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('CVB_NOT_EXIST',NULL,NULL,NULL);
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_CVB','CVB_HEAD','cvb code: '|| I_cvb_code);
   close C_CHECK_CVB;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CVB_EXISTS;
--------------------------------------------------------------------------------------
FUNCTION CVB_COMP_EXISTS(O_error_message IN OUT VARCHAR2,
                         O_exists        IN OUT BOOLEAN,
                         I_cvb_code      IN     CVB_HEAD.CVB_CODE%TYPE,
                         I_comp_id       IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.CVB_COMP_EXISTS';
   L_exists  VARCHAR2(1);

   cursor C_CHECK_CVB_COMP is
      select 'Y'
        from cvb_detail
       where cvb_code = I_cvb_code
         and comp_id  = I_comp_id;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_CVB_COMP','CVB_DETAIL',
                    'Comp id: '|| I_comp_id || ' ,cvb code: '|| I_cvb_code);
   open C_CHECK_CVB_COMP;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_CVB_COMP','CVB_DETAIL',
                    'Comp id: '|| I_comp_id || ' ,cvb code: '|| I_cvb_code);
   fetch C_CHECK_CVB_COMP into L_exists;
   ---
   if C_CHECK_CVB_COMP%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_CVB_COMP',I_comp_id,I_cvb_code,NULL);
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_CVB_COMP','CVB_DETAIL',
                    'Comp id: '|| I_comp_id || ' ,cvb code: '|| I_cvb_code);
   close C_CHECK_CVB_COMP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CVB_COMP_EXISTS;
--------------------------------------------------------------------------------------
FUNCTION VALIDATE_ASSESS_COMP(O_error_message     IN OUT VARCHAR2,
                              O_exists            IN OUT BOOLEAN,
                              I_comp_id           IN     ELC_COMP.COMP_ID%TYPE,
                              I_import_country_id IN     ELC_COMP.IMPORT_COUNTRY_ID%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.VALIDATE_ASSESS_COMP';
   L_exists  VARCHAR2(1);

   cursor C_CHECK_COMP is
      select 'Y'
        from elc_comp
       where comp_id           = I_comp_id
         and import_country_id = NVL(I_import_country_id,import_country_id);

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_COMP','ELC_COMP','Comp id: '|| I_comp_id);
   open C_CHECK_COMP;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_COMP','ELC_COMP','Comp id: '|| I_comp_id);
   fetch C_CHECK_COMP into L_exists;
   ---
   if C_CHECK_COMP%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('COMP_NOT_EXIST',NULL,NULL,NULL);
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_COMP','ELC_COMP','Comp id: '|| I_comp_id);
   close C_CHECK_COMP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END VALIDATE_ASSESS_COMP;
--------------------------------------------------------------------------------------
FUNCTION VALIDATE_EXP_COMP(O_error_message IN OUT VARCHAR2,
                           O_exists        IN OUT BOOLEAN,
                           I_comp_id       IN     ELC_COMP.COMP_ID%TYPE,
                           I_expense_type  IN     ELC_COMP.EXPENSE_TYPE%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.VALIDATE_EXP_COMP';
   L_exists  VARCHAR2(1);

   cursor C_CHECK_COMP is
      select 'Y'
        from elc_comp
       where comp_id      = I_comp_id
         and expense_type = NVL(I_expense_type,expense_type);

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_COMP','ELC_COMP','Comp id: '|| I_comp_id);
   open C_CHECK_COMP;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_COMP','ELC_COMP','Comp id: '|| I_comp_id);
   fetch C_CHECK_COMP into L_exists;
   ---
   if C_CHECK_COMP%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('COMP_NOT_EXIST',NULL,NULL,NULL);
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_COMP','ELC_COMP','Comp id: '|| I_comp_id);
   close C_CHECK_COMP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END VALIDATE_EXP_COMP;
--------------------------------------------------------------------------------------
FUNCTION VALIDATE_ASSESS_CVB(O_error_message      IN OUT VARCHAR2,
                             O_exists             IN OUT BOOLEAN,
                             IO_import_country_id IN OUT ELC_COMP.IMPORT_COUNTRY_ID%TYPE,
                             I_cvb_code           IN     CVB_HEAD.CVB_CODE%TYPE,
                             I_comp_id            IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'ELC_SQL.VALIDATE_ASSESS_CVB';
   L_assess_exist  VARCHAR2(1)  := 'N';
   L_import_match  VARCHAR2(1)  := 'N';

   cursor C_CHECK_TYPE is
      select 'Y'
        from cvb_detail c,
             elc_comp   e
       where c.comp_id   = e.comp_id
         and c.cvb_code  = I_cvb_code
         and e.comp_type = 'A';

   cursor C_GET_IMPORT is
      select e.import_country_id
        from cvb_detail c,
             elc_comp   e
       where c.comp_id   = e.comp_id
         and c.cvb_code  = I_cvb_code
         and e.comp_type = 'A';

   cursor C_CHECK_IMPORT is
      select 'Y'
        from cvb_detail c,
             elc_comp   e
       where c.comp_id           = e.comp_id
         and c.cvb_code          = I_cvb_code
         and e.comp_type         = 'A'
         and e.import_country_id = IO_import_country_id;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_TYPE','CVB_DETAIL, ELC_COMP','cvb code: '|| I_cvb_code);
   open C_CHECK_TYPE;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_TYPE','CVB_DETAIL, ELC_COMP','cvb code: '|| I_cvb_code);
   fetch C_CHECK_TYPE into L_assess_exist;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_TYPE','CVB_DETAIL, ELC_COMP','cvb code: '|| I_cvb_code);
   close C_CHECK_TYPE;
   ---
   -- if the given CVB has an assessment attached to it, then
   -- need to evaluate the import country
   ---
   if L_assess_exist = 'Y' then
      -- if no import country is passed in then get the import country
      -- of assessments attached to the cvb code.
      if IO_import_country_id is NULL then
         SQL_LIB.SET_MARK('OPEN','C_GET_IMPORT','ELC_COMP','cvb code: '|| I_cvb_code);
         open C_GET_IMPORT;
         SQL_LIB.SET_MARK('FETCH','C_GET_IMPORT','ELC_COMP','cvb code: '|| I_cvb_code);
         fetch C_GET_IMPORT into IO_import_country_id;
         SQL_LIB.SET_MARK('CLOSE','C_GET_IMPORT','ELC_COMP','cvb code: '|| I_cvb_code);
         close C_GET_IMPORT;
      else
         -- if an import country is passed in then check that the import country
         -- passed in matches the import country of assessments attached to the cvb code.
         SQL_LIB.SET_MARK('OPEN','C_CHECK_IMPORT','CVB_DETAIL, ELC_COMP',
                          'cvb code: '|| I_cvb_code || ', import country: ' || IO_import_country_id);
         open C_CHECK_IMPORT;
         SQL_LIB.SET_MARK('FETCH','C_CHECK_IMPORT','CVB_DETAIL, ELC_COMP',
                          'cvb code: '|| I_cvb_code || ', import country: ' || IO_import_country_id);
         fetch C_CHECK_IMPORT into L_import_match;
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_IMPORT','CVB_DETAIL, ELC_COMP',
                          'cvb code: '|| I_cvb_code || ', import country: ' || IO_import_country_id);
         close C_CHECK_IMPORT;
         ---
         if L_import_match = 'N' then
            O_error_message := SQL_LIB.CREATE_MSG('CVB_SAME_IMPORT',NULL,NULL,NULL);
            O_exists := FALSE;
         end if;
      end if;
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
END VALIDATE_ASSESS_CVB;
--------------------------------------------------------------------------------------
FUNCTION VALIDATE_CVB_COMP(O_error_message IN OUT VARCHAR2,
                           O_exists        IN OUT BOOLEAN,
                           I_cvb_code      IN     CVB_HEAD.CVB_CODE%TYPE,
                           I_comp_id       IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'ELC_SQL.VALIDATE_CVB_COMP';
   L_assess_exist  VARCHAR2(1)  := 'N';
   L_cvb_import    ELC_COMP.IMPORT_COUNTRY_ID%TYPE;
   L_comp_import   ELC_COMP.IMPORT_COUNTRY_ID%TYPE;
   L_comp_type     ELC_COMP.COMP_TYPE%TYPE;

   cursor C_GET_COMP_TYPE is
      select comp_type
        from elc_comp
       where comp_id = I_comp_id;

   cursor C_CHECK_TYPE is
      select 'Y'
        from cvb_detail c,
             elc_comp   e
       where c.comp_id   = e.comp_id
         and c.cvb_code  = I_cvb_code
         and e.comp_id  != I_comp_id
         and e.comp_type = 'A';

   cursor C_GET_CVB_IMPORT is
      select 'Y'
        from cvb_detail c,
             elc_comp   e
       where c.comp_id           = e.comp_id
         and c.cvb_code          = I_cvb_code
         and e.comp_type         = 'A'
         and e.import_country_id = (select ec.import_country_id
                                      from elc_comp ec
                                     where ec.comp_id = I_comp_id);
BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_COMP_TYPE','ELC_COMP','Comp Id: '||I_comp_id);
   open C_GET_COMP_TYPE;
   SQL_LIB.SET_MARK('FETCH','C_GET_COMP_TYPE','ELC_COMP','Comp Id: '||I_comp_id);
   fetch C_GET_COMP_TYPE into L_comp_type;
   SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_TYPE','ELC_COMP','Comp Id: '||I_comp_id);
   close C_GET_COMP_TYPE;
   ---
   if L_comp_type = 'U' then
      O_error_message := SQL_LIB.CREATE_MSG('UP_CHRG_NO_CVB',
                                            NULL,
                                            NULL,
                                            NULL);
      O_exists := FALSE;
   elsif L_comp_type = 'A' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_TYPE','CVB_DETAIL, ELC_COMP',NULL);
      open C_CHECK_TYPE;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_TYPE','CVB_DETAIL, ELC_COMP',NULL);
      fetch C_CHECK_TYPE into L_assess_exist;
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_TYPE','CVB_DETAIL, ELC_COMP',NULL);
      close C_CHECK_TYPE;
      ---
      -- If the passed in cvb code has an assessment attached to it, then
      -- check the import country matches the import country of the
      -- component passed in.  Import countries must be the same for all
      -- components attached to a cvb code.
      ---
      if L_assess_exist = 'Y' then
         SQL_LIB.SET_MARK('OPEN','C_GET_CVB_IMPORT','CVB_DETAIL, ELC_COMP','cvb code: '|| I_cvb_code);
         open C_GET_CVB_IMPORT;
         SQL_LIB.SET_MARK('FETCH','C_GET_CVB_IMPORT','CVB_DETAIL, ELC_COMP','cvb code: '|| I_cvb_code);
         fetch C_GET_CVB_IMPORT into L_cvb_import;
         ---
         -- If import countries are not the same, send an error message.
         ---
         if C_GET_CVB_IMPORT%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('CVB_SAME_IMPORT',NULL,NULL,NULL);
            O_exists := FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('CLOSE','C_GET_CVB_IMPORT','CVB_DETAIL, ELC_COMP','cvb code: '|| I_cvb_code);
         close C_GET_CVB_IMPORT;
      end if;
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
END VALIDATE_CVB_COMP;
----------------------------------------------------------------------------------
FUNCTION GET_COMP_TYPE(O_error_message  IN OUT VARCHAR2,
                       O_exists         IN OUT BOOLEAN,
                       O_comp_type      IN OUT ELC_COMP.COMP_TYPE%TYPE,
                       I_comp_id        IN     ELC_COMP.COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.GET_COMP_TYPE';

   cursor C_GET_COMP_TYPE is
      select comp_type
        from elc_comp
       where comp_id = I_comp_id;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_COMP_TYPE','ELC_COMP','Comp id: '|| I_comp_id);
   open C_GET_COMP_TYPE;
   SQL_LIB.SET_MARK('FETCH','C_GET_COMP_TYPE','ELC_COMP','Comp id: '|| I_comp_id);
   fetch C_GET_COMP_TYPE into O_comp_type;
   ---
   if C_GET_COMP_TYPE%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_TYPE','ELC_COMP','Comp id: '|| I_comp_id);
      close C_GET_COMP_TYPE;
      O_error_message := SQL_LIB.CREATE_MSG('COMP_NOT_EXIST',NULL,NULL,NULL);
      O_exists := FALSE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_TYPE','ELC_COMP','Comp id: '|| I_comp_id);
   close C_GET_COMP_TYPE;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_COMP_TYPE;
----------------------------------------------------------------------------------
FUNCTION GET_UP_CHRG_GROUP(O_error_message  IN OUT VARCHAR2,
                           O_exists         IN OUT BOOLEAN,
                           O_up_chrg_group  IN OUT ELC_COMP.UP_CHRG_GROUP%TYPE,
                           I_comp_id        IN     ELC_COMP.COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ELC_SQL.GET_UP_CHRG_GROUP';

   cursor C_GET_UP_CHRG_GROUP is
      select up_chrg_group
        from elc_comp
       where comp_id = I_comp_id;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_UP_CHRG_GROUP','ELC_COMP','Comp id: '|| I_comp_id);
   open C_GET_UP_CHRG_GROUP;
   SQL_LIB.SET_MARK('FETCH','C_GET_UP_CHRG_GROUP','ELC_COMP','Comp id: '|| I_comp_id);
   fetch C_GET_UP_CHRG_GROUP into O_up_chrg_group;
   ---
   if C_GET_UP_CHRG_GROUP%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_GET_UP_CHRG_GROUP','ELC_COMP','Comp id: '|| I_comp_id);
      close C_GET_UP_CHRG_GROUP;
      O_error_message := SQL_LIB.CREATE_MSG('COMP_NOT_EXIST',NULL,NULL,NULL);
      O_exists := FALSE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_UP_CHRG_GROUP','ELC_COMP','Comp id: '|| I_comp_id);
   close C_GET_UP_CHRG_GROUP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_UP_CHRG_GROUP;
-----------------------------------------------------------------------------------------
-- CR409 03-Oct-2011 Vinutha Raju, vinutha.raju@in.tesco.com Begin
-----------------------------------------------------------------------------------
FUNCTION TSL_CHK_DUPLICATE_FISCAL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_exists          IN OUT   BOOLEAN,
                                  I_code            IN       TSL_BWS_FISCAL_RATES.FISCAL_CODE%TYPE,
                                  I_cost_zone       IN       TSL_BWS_FISCAL_RATES.COST_ZONE%TYPE,
                                  I_effective_date  IN       TSL_BWS_FISCAL_RATES.EFFECTIVE_DATE%TYPE)
   RETURN BOOLEAN is

   L_program                VARCHAR2(50) := 'ELC_SQL.TSL_CHK_DUPLICATE_FISCAL';
   L_duplicate_exists       VARCHAR2(1)  := NULL;

   cursor C_DUPLICATE_EXISTS is
      select 'x'
        from tsl_bws_fiscal_rates tbfr
       where tbfr.fiscal_code    = I_code
         and tbfr.cost_zone      = I_cost_zone
         and tbfr.effective_date = I_effective_date;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_DUPLICATE_EXISTS',
                    'TSL_BWS_FISCAL_RATES',
                    'Fiscal_code: '||I_code);
   open C_DUPLICATE_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DUPLICATE_EXISTS',
                    'TSL_BWS_FISCAL_RATES',
                    'Fiscal_code: '||I_code);
   fetch C_DUPLICATE_EXISTS into L_duplicate_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DUPLICATE_EXISTS',
                    'TSL_BWS_FISCAL_RATES',
                    'Fiscal_code: '||I_code);
   close C_DUPLICATE_EXISTS;

   if L_duplicate_exists is NOT NULL then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHK_DUPLICATE_FISCAL;
-------------------------------------------------------------------------------------------------
-- DefNBS024103, Vinutha Raju, vinutha.raju@in.tesco.com, 06-Jan-12, Begin
---------------------------------------------------------------------------------------
FUNCTION TSL_FISCAL_COMPID_INSERT(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_code            IN       TSL_BWS_FISCAL_RATES.FISCAL_CODE%TYPE,
                                  I_comp_id         IN       ELC_COMP.COMP_ID%TYPE,
                                  I_effective_date  IN       TSL_FISCAL_COMPID.EFFECTIVE_DATE%TYPE)
   RETURN BOOLEAN is

   L_program      VARCHAR2(50) := 'ELC_SQL.TSL_FISCAL_COMPID_INSERT';
   L_exists       VARCHAR2(1)  := NULL;

   cursor C_EXISTS is
      select 'x'
        from tsl_fiscal_compid tfc
       where tfc.fiscal_code    = I_code
         and tfc.comp_id        = I_comp_id
         and tfc.effective_date = I_effective_date;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   open C_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   fetch C_EXISTS into L_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   close C_EXISTS;

   if L_exists is null then
      insert into tsl_fiscal_compid (fiscal_code,
                                     comp_id,
                                     effective_date)
                             values (I_code,
                                     I_comp_id,
                                     I_effective_date);
   end if;
   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_FISCAL_COMPID_INSERT;
-----------------------------------------------------------------------------------
FUNCTION TSL_FISCAL_COMPID_DELETE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_code            IN       TSL_BWS_FISCAL_RATES.FISCAL_CODE%TYPE,
                                  I_comp_id         IN       ELC_COMP.COMP_ID%TYPE,
                                  I_effective_date  IN       TSL_FISCAL_COMPID.EFFECTIVE_DATE%TYPE)
   RETURN BOOLEAN is

   L_program      VARCHAR2(50) := 'ELC_SQL.TSL_FISCAL_COMPID_DELETE';
   L_exists       VARCHAR2(1)  := NULL;

   cursor C_EXISTS is
      select 'x'
        from tsl_fiscal_compid tfc
       where tfc.fiscal_code    = I_code
         and tfc.comp_id        = I_comp_id
         and tfc.effective_date = I_effective_date;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   open C_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   fetch C_EXISTS into L_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   close C_EXISTS;

   if L_exists is not null then
      delete from tsl_fiscal_compid
            where fiscal_code    = I_code
              and comp_id        = I_comp_id
              and effective_date = I_effective_date;
   end if;
   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_FISCAL_COMPID_DELETE;
-----------------------------------------------------------------------------------
FUNCTION TSL_FISCAL_COMPID_EXISTS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_exists          IN OUT   BOOLEAN,
                                  I_code            IN       TSL_BWS_FISCAL_RATES.FISCAL_CODE%TYPE,
                                  I_comp_id         IN       ELC_COMP.COMP_ID%TYPE,
                                  I_effective_date  IN       TSL_FISCAL_COMPID.EFFECTIVE_DATE%TYPE)
   RETURN BOOLEAN is

   L_program      VARCHAR2(50) := 'ELC_SQL.TSL_FISCAL_COMPID_EXISTS';
   L_exists       VARCHAR2(1)  := NULL;

   cursor C_EXISTS is
      select 'x'
        from tsl_fiscal_compid tfc
       where tfc.fiscal_code    = I_code
         and tfc.comp_id        = NVL(I_comp_id,tfc.comp_id)
         and tfc.effective_date = I_effective_date;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   open C_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   fetch C_EXISTS into L_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   close C_EXISTS;

   if L_exists is not null then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_FISCAL_COMPID_EXISTS;
--------------------------------------------------------------------------------------------------
FUNCTION TSL_FISCAL_ZONEID_EXISTS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_exists          IN OUT   BOOLEAN,
                                  I_code            IN       TSL_BWS_FISCAL_RATES.FISCAL_CODE%TYPE,
                                  I_currency        IN       ELC_COMP.COMP_CURRENCY%TYPE,
                                  I_calc_basis      IN       ELC_COMP.CALC_BASIS%TYPE,
                                  I_effective_date  IN       TSL_FISCAL_COMPID.EFFECTIVE_DATE%TYPE)
   RETURN BOOLEAN  is

   L_program      VARCHAR2(50) := 'ELC_SQL.TSL_FISCAL_ZONEID_EXISTS';
   L_exists       VARCHAR2(1)  := NULL;

   cursor C_EXISTS is
      select 'x'
        from tsl_fiscal_compid tfc,
             elc_comp ec
       where tfc.fiscal_code    = I_code
         and tfc.comp_id        = ec.comp_id
         and tfc.effective_date = I_effective_date
         and ec.comp_currency   = I_currency
         and ec.calc_basis      = I_calc_basis;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   open C_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   fetch C_EXISTS into L_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   close C_EXISTS;

   if L_exists is not null then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_FISCAL_ZONEID_EXISTS;
---------------------------------------------------------------------------------
-- DefNBS024103, Vinutha Raju, vinutha.raju@in.tesco.com, 06-Jan-12, End
----------------------------------------------------------------------------------
-- DefNBS024358 22-Feb-2012 Vinutha Raju, vinutha.raju@in.tesco.com Begin
---------------------------------------------------------------------------------------------
FUNCTION TSL_FISCAL_COMPID_UPDATE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_code            IN       TSL_BWS_FISCAL_RATES.FISCAL_CODE%TYPE,
                                  I_calc_basis      IN       ELC_COMP.CALC_BASIS%TYPE,
                                  I_effective_date  IN       TSL_FISCAL_COMPID.EFFECTIVE_DATE%TYPE,
                                  I_currency        IN       ELC_COMP.COMP_CURRENCY%TYPE)
   RETURN BOOLEAN is

   L_program      VARCHAR2(50) := 'ELC_SQL.TSL_FISCAL_COMPID_UPDATE';
   L_exists       VARCHAR2(1)  := NULL;

   cursor C_EXISTS is
      select 'x'
        from tsl_fiscal_compid tfc,
             elc_comp ec
       where tfc.fiscal_code    = I_code
         and tfc.comp_id        = ec.comp_id
         and tfc.effective_date = I_effective_date
         and ec.comp_currency   = I_currency
         and ec.calc_basis      <> I_calc_basis;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   open C_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   fetch C_EXISTS into L_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'TSL_FISCAL_COMPID',
                    'Fiscal_code: '||I_code);
   close C_EXISTS;

   if L_exists is not null then
      delete
        from tsl_fiscal_compid tfci
       where tfci.comp_id  in  ( select tfc.comp_id
                                  from tsl_fiscal_compid tfc,
                                       elc_comp ec
                                 where tfc.fiscal_code    = I_code
                                   and tfc.comp_id        = ec.comp_id
                                   and tfc.effective_date = I_effective_date
                                   and ec.comp_currency   = I_currency
                                   and ec.calc_basis      <> I_calc_basis)
         and tfci.fiscal_code    = I_code
         and tfci.effective_date = I_effective_date;
   end if;
   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_FISCAL_COMPID_UPDATE;
---------------------------------------------------------------------------------------------
-- DefNBS024358 22-Feb-2012 Vinutha Raju, vinutha.raju@in.tesco.com End
---------------------------------------------------------------------------------------------
-- CR409 03-Oct-2011 Vinutha Raju, vinutha.raju@in.tesco.com End
-----------------------------------------------------------------------------------
END ELC_SQL;
/

