CREATE OR REPLACE PACKAGE BODY FILTER_LOV_VALIDATE_SQL as
--------------------------------------------------------------------------------
-- Mod By       : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date     : 14-Jul-2008
-- Mod Ref      : N147
-- Mod Details  : Added new function VALIDATE_NON_MERCH_CODE
--------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date     : 18-May-2010
-- Mod Ref      : CR316
-- Mod Details  : Added four new functions TSL_VALIDATE_REV_COMPANY,
--                                         TSL_VALIDATE_ACC_CODE,
--                                         TSL_VALIDATE_NON_MERCH_CODE_UK_ROI and
--                                         TSL_VALIDATE_DEBTOR_AREA
---------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date     : 31-May-2010
-- Mod Ref      : NBS00017761(Added as part of merge branch MrgNBS017783)
-- Mod Details  : Modified TSL_VALID_NON_MRCH_UKROI function to return debtor
--                area for ROI
---------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date     : 04-Jun-2010
-- Mod Ref      : Defect found as part of merge MrgNBS017783(added in DefNBS017760)
-- Mod Details  : Modified TSL_VALIDATE_DEBTOR_AREA function to validate
--                for ROI supplier.
---------------------------------------------------------------------------------
-- Mod By:      Vipindas T.P
-- Mod Date:    13-Aug-2010
-- Mod Ref:     CR354
-- Mod Details: New functions added TSL_VALIDATE_NON_MERCH_UKROI
---------------------------------------------------------------------------------
--MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com  Begin
-- Mod By       : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Date     : 02-Sep-2010
-- Mod Ref      : DefNBS019014/IM068213
-- Mod Ref      : Added a new parameter to the function TSL_VALIDATE_ACC_CODE
--MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com  End
---------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date     : 28-Sep-2010
-- Mod Ref      : CR340
-- Mod Details  : Added one new function TSL_GET_DEBTOR_AREA and
--                modified TSL_VALIDATE_DEBTOR_AREA.
---------------------------------------------------------------------------------
-- Mod By       : Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com
-- Mod Date     : 29-OCT-2010
-- Mod Ref      : CR332
-- Mod Details  : Added two new overloaded functions TSL_VALIDATE_STYLE_REF_CODE
---------------------------------------------------------------------------------
-- Mod By       : Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com
-- Mod Date     : 01-Nov-2010
-- Mod Ref      : CR332
-- Mod Details  : Added two new functions TSL_VLD_STYLE_REF_CODE_PACK and
--                TSL_VLD_STYLE_REF_CODE_TRAN
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Mod By       : Accenture/Sanju Nataraja Sanju.Natarajan@in.tesco.com
-- Mod Date     : 01-Nov-2010
-- Mod Ref      : CR332
-- Mod Details  : Added one function TSL_VLD_STYLE_REF_CODE_SCA
---------------------------------------------------------------------------------
-- Mod By       : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Date     : 24-Nov-2010
-- Mod Ref      : MrgNBS019839
-- Mod Details  : MrgNBS019839, Merge from 3.5b to PrdSi
---------------------------------------------------------------------------------
-- Mod By       : Usha Patil, usha.patil@in.tesco.com
-- Mod Date     : 10-Dec-2010
-- Mod Ref      : Def: NBS00020077
-- Mod Details  : Modified function TSL_VLD_STYLE_REF_CODE_SCA to validate pack exists
--                for a base item.
---------------------------------------------------------------------------------
-- Mod By       : Sathishkumar Alagar, satishkumar.alagar@in.tesco.com
-- Mod Date     : 22-Dec-2010
-- Mod Ref      : Def: NBS00020217
-- Mod Details  : Added function TSL_VALID_STYLE_REF_CODE to check the input Style
--                Reference Code occurs in simple packs
---------------------------------------------------------------------------------
-- Mod By       : Praven Rachaputi
-- Mod Date     : 25-Dec-2010
-- Mod Ref      : Def: NBS00020253
-- Mod Details  : Modifed function TSL_VALID_STYLE_REF_CODE to check the input Style
--                Reference Code occurs in simple packs
---------------------------------------------------------------------------------
-- Mod By       : Murali
-- Mod Date     : 05-Jan-2011
-- Mod Ref      : Def: NBS00020420
-- Mod Details  : Modifed function TSL_VLD_INT_CONTACT to remove non merch code check
--                for getiing ROI Int contacts.
---------------------------------------------------------------------------------
-- Mod By       : Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com
-- Mod Date     : 24-Jan-2011
-- Mod Ref      : Def: NBS00020631
-- Mod Details  : For making style ref code field case insensitive.
----------------------------------------------------------------------------------
-- Mod By     : Accenture/Veena Nanjundaiah, Veena.nanjundaiah@in.tesco.com
-- Mod Date   : 13-Jan-2011
-- Mod Ref    : DefNBS00020075
-- Mod Details: Added new function TSL_VLD_STYLE_REF_CODE_TPNB to filter only TPNB
--              items in style ref code
----------------------------------------------------------------------------------
-- Mod By      : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date    : 07-Feb-2011
-- Mod Ref     : MrgNBS021432(Merge from 3.5h to 3.5b)
-- Mod Details : No merge required simply checking in same code with this comment
--               As no changes found in source object.
---------------------------------------------------------------------------------
-- Mod By       : Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com
-- Mod Date     : 09-Feb-2011
-- Mod Ref      : DefNBS021474
-- Mod Details  : For making style ref code field case insensitive.
----------------------------------------------------------------------------------
-- Mod By      : Sripriya,Sripriya.karanam@in.tesco.com,
-- Mod Date    : 21-Apr-2011
-- Mod Ref     : DefNBS022386
-- Mod Details : Modified the function TSL_VALID_STYLE_REF_CODE.
---------------------------------------------------------------------------------
-- GET_ORG_DYNAMIC_CODE( )
----------------------------------------------------------------------------------
FUNCTION GET_ORG_DYNAMIC_CODE (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_org_code      IN OUT VARCHAR2,
                               I_org_level     IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.GET_ORG_DYNAMIC_CODE';

BEGIN
   if ( I_org_level = 'C' ) then
      O_org_code := '@OH2';
   elsif ( I_org_level = 'A' ) then
      O_org_code := '@OH3';
   elsif ( I_org_level = 'R' ) then
      O_org_code := '@OH4';
   elsif ( I_org_level = 'D' ) then
      O_org_code := '@OH5';
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_ORG_DYNAMIC_CODE;
--------------------------------------------------------------------------------
-- GET_MERCH_DYNAMIC_CODE( )
--------------------------------------------------------------------------------
FUNCTION GET_MERCH_DYNAMIC_CODE (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_merch_code    IN OUT VARCHAR2,
                                 I_merch_level   IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.GET_MERCH_DYNAMIC_CODE';

BEGIN
   if ( I_merch_level = 'D' ) then
      O_merch_code := '@MH2';
   elsif ( I_merch_level = 'G' ) then
      O_merch_code := '@MH3';
   elsif ( I_merch_level = 'P' ) then
      O_merch_code := '@MH4';
   elsif ( I_merch_level = 'C' ) then
      O_merch_code := '@MH5';
   elsif ( I_merch_level = 'S' ) then
      O_merch_code := '@MH6';
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_MERCH_DYNAMIC_CODE;
--------------------------------------------------------------------------------
-- GET_NON_VISIBLE_HIER( )
--------------------------------------------------------------------------------
FUNCTION GET_NON_VISIBLE_HIER (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_hier          IN OUT VARCHAR2,
                               I_org_id        IN     NUMBER,
                               I_org_level     IN     SYSTEM_OPTIONS.VAT_IND%TYPE,
                               I_merch_id      IN     NUMBER,
                               I_merch_level   IN     SYSTEM_OPTIONS.VAT_IND%TYPE,
                               I_class         IN     V_CLASS.CLASS%TYPE,
                               I_subclass      IN     V_SUBCLASS.SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.GET_NON_VISIBLE_HIER';

   L_valid       BOOLEAN;
   L_org_name    DIVISION.DIV_NAME%TYPE;
   L_merch_name  AREA.AREA_NAME%TYPE;
   L_code        VARCHAR2(4);
   L_code_desc   CODE_DETAIL.CODE_DESC%TYPE;
   L_cde_desc    CODE_DETAIL.CODE_DESC%TYPE;

BEGIN
   if I_org_id is NOT NULL then
      if VALIDATE_ORG_LEVEL(O_error_message,
                            L_valid,
                            L_org_name,
                            I_org_level,
                            I_org_id) = FALSE then
         return FALSE;
      end if;

      if L_valid = FALSE then
         if GET_ORG_DYNAMIC_CODE(O_error_message,
                                 L_code,
                                 I_org_level) = FALSE then
            return FALSE;
         end if;

         O_hier := L_code || ' ' || TO_CHAR(I_org_id);
         return TRUE;
      end if;
   end if;

   if I_merch_id is not NULL then
      if VALIDATE_MERCH_LEVEL(O_error_message,
                              L_valid,
                              L_merch_name,
                              I_merch_level,
                              I_merch_id,
                              I_class,
                              I_subclass) = FALSE then
         return FALSE;
      end if;

      if L_valid = FALSE then
         if GET_MERCH_DYNAMIC_CODE(O_error_message,
                                   L_code,
                                   I_merch_level) = FALSE then
            return FALSE;
         end if;

         if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                       'LABL',
                                       'DEP',
                                       L_code_desc) = FALSE then
            return FALSE;
         end if;
         if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                       'MER1',
                                       'C',
                                       L_cde_desc) = FALSE then
            return FALSE;
         end if;

         if I_merch_level = 'C' then
            O_hier := L_code_desc || '/' || L_code || ':' || ' ' || TO_CHAR(I_merch_id) || '/' || TO_CHAR(I_class);
         elsif I_merch_level = 'S' then
            O_hier := L_code_desc || '/' || L_cde_desc || '/' || L_code || ':' || ' ' || TO_CHAR(I_merch_id)|| '/' || TO_CHAR(I_class) || '/' || TO_CHAR(I_subclass);
         else
            O_hier := L_code || ' ' || TO_CHAR(I_merch_id);
         end if;

         return TRUE;
      end if;
   end if;

   -- If it's not the org or the merch there must be another reason.
   -- Return NULL so a generic error can be raised
   O_hier := NULL;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_NON_VISIBLE_HIER;
--------------------------------------------------------------------------------
-- VALIDATE_CHAIN( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_CHAIN(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_valid         IN OUT BOOLEAN,
                        O_chain_name    IN OUT V_CHAIN.CHAIN_NAME%TYPE,
                        I_chain         IN     V_CHAIN.CHAIN%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_CHAIN';

   cursor C_CHECK_CHAIN_TB is
      select chain_name
        from chain
       where chain = I_chain;

   cursor C_CHECK_CHAIN_V is
      select chain_name
        from v_chain
       where chain = I_chain;

BEGIN
   open C_CHECK_CHAIN_V;
   fetch C_CHECK_CHAIN_V into O_chain_name;
   if C_CHECK_CHAIN_V%NOTFOUND then
      open C_CHECK_CHAIN_TB;
      fetch C_CHECK_CHAIN_TB into O_chain_name;
      if C_CHECK_CHAIN_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_CHAIN', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', '@OH2', I_chain, NULL);
      end if;
      close C_CHECK_CHAIN_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_chain_name,
                                O_chain_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_CHECK_CHAIN_V;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_CHAIN;

--------------------------------------------------------------------------------
-- VALIDATE_AREA( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_AREA(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_valid         IN OUT BOOLEAN,
                       O_area_name     IN OUT V_AREA.AREA_NAME%TYPE,
                       I_area          IN     V_AREA.AREA%TYPE,
                       I_org_level     IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                       I_org_id        IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_AREA';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_AREA_REGION_V is
      select 'X'
        from v_region
       where area = I_area
         and region = I_org_id;

   cursor C_CHECK_AREA_DISTRICT_V is
      select 'X'
        from v_district
       where area = I_area
         and district = I_org_id;

BEGIN

   if(I_org_level = 'C') then
      if(VALIDATE_AREA(O_error_message,
                       O_valid,
                       O_area_name,
                       I_org_id,
                       I_area) = FALSE) then
         return FALSE;
      end if;
   else
      if(VALIDATE_AREA(O_error_message,
                       O_valid,
                       O_area_name,
                       NULL, -- chain
                       I_area) = FALSE) then
         return FALSE;
      end if;

      if(I_org_id IS NOT NULL) then
         if(I_org_level = 'R') then
            open C_CHECK_AREA_REGION_V;
            fetch C_CHECK_AREA_REGION_V into L_dummy;
            if C_CHECK_AREA_REGION_V%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER', '@OH3', '@OH4', NULL);
               O_valid := FALSE;
            else
               O_valid := TRUE;
            end if;
            close C_CHECK_AREA_REGION_V;
         elsif(I_org_level = 'D') then
            open C_CHECK_AREA_DISTRICT_V;
            fetch C_CHECK_AREA_DISTRICT_V into L_dummy;
            if C_CHECK_AREA_DISTRICT_V%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER', '@OH3', '@OH5', NULL);
               O_valid := FALSE;
            else
               O_valid := TRUE;
            end if;
            close C_CHECK_AREA_DISTRICT_V;
         else
            O_valid := TRUE;
         end if;
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

END VALIDATE_AREA;

--------------------------------------------------------------------------------
-- VALIDATE_AREA( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_AREA(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_valid         IN OUT BOOLEAN,
                       O_area_name     IN OUT V_AREA.AREA_NAME%TYPE,
                       I_chain         IN     V_CHAIN.CHAIN%TYPE,
                       I_area          IN     V_AREA.AREA%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_AREA';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_AREA_TB is
      select area_name
        from area
       where area = I_area;

   cursor C_CHECK_AREA_V is
      select area_name
        from v_area
       where area = I_area;

   cursor C_CHECK_AREA_CHAIN_V is
      select 'X'
        from v_area
       where area = I_area
         and chain = I_chain;

BEGIN
   open C_CHECK_AREA_V;
   fetch C_CHECK_AREA_V into O_area_name;
   if C_CHECK_AREA_V%NOTFOUND then
      open C_CHECK_AREA_TB;
      fetch C_CHECK_AREA_TB into O_area_name;
      if C_CHECK_AREA_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_AREA', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', '@OH3', I_area, NULL);
      end if;
      close C_CHECK_AREA_TB;
      O_valid := FALSE;
   else
      if I_chain is not null then
         open C_CHECK_AREA_CHAIN_V;
         fetch C_CHECK_AREA_CHAIN_V into L_dummy;
         if C_CHECK_AREA_CHAIN_V%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER', '@OH3', '@OH2', NULL);
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_AREA_CHAIN_V;
      else
         O_valid := TRUE;
      end if;
   end if;

   close C_CHECK_AREA_V;
   if O_valid = TRUE then
      if LANGUAGE_SQL.TRANSLATE(O_area_name,
                                O_area_name,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_AREA;

--------------------------------------------------------------------------------
-- VALIDATE_AREA( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_AREA(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_valid         IN OUT BOOLEAN,
                       O_area_name     IN OUT V_AREA.AREA_NAME%TYPE,
                       I_area          IN     V_AREA.AREA%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_AREA';

BEGIN
   if VALIDATE_AREA(O_error_message,
                    O_valid,
                    O_area_name,
                    null,
                    I_area) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_AREA;

--------------------------------------------------------------------------------
-- VALIDATE_REGION( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_REGION(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid         IN OUT BOOLEAN,
                         O_region_name   IN OUT V_REGION.REGION_NAME%TYPE,
                         I_chain         IN     V_CHAIN.CHAIN%TYPE,
                         I_area          IN     V_AREA.AREA%TYPE,
                         I_region        IN     V_REGION.REGION%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_REGION';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_REGION_TB is
      select region_name
        from region
       where region = I_region;

   cursor C_CHECK_REGION_V is
      select region_name
        from v_region
       where region = I_region;

   cursor C_CHECK_REGION_CHAIN_V is
      select 'X'
        from v_region
       where region = I_region
         and chain = I_chain;

   cursor C_CHECK_REGION_AREA_V is
      select 'X'
        from v_region
       where region = I_region
         and area = I_area;

BEGIN
   open C_CHECK_REGION_V;
   fetch C_CHECK_REGION_V into O_region_name;
   if C_CHECK_REGION_V%NOTFOUND then
      open C_CHECK_REGION_TB;
      fetch C_CHECK_REGION_TB into O_region_name;
      if C_CHECK_REGION_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_REGION', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', '@OH4', I_region, NULL);
      end if;
      close C_CHECK_REGION_TB;
      O_valid := FALSE;
   else
      if I_area is not null then
         open C_CHECK_REGION_AREA_V;
         fetch C_CHECK_REGION_AREA_V into L_dummy;
         if C_CHECK_REGION_AREA_V%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER', '@OH4', '@OH3', NULL);
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_REGION_AREA_V;
      elsif I_chain is not null then
            open C_CHECK_REGION_CHAIN_V;
            fetch C_CHECK_REGION_CHAIN_V into L_dummy;
            if C_CHECK_REGION_CHAIN_V%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER', '@OH4', '@OH2', NULL);
               O_valid := FALSE;
            else
               O_valid := TRUE;
            end if;
            close C_CHECK_REGION_CHAIN_V;
         else
            O_valid := TRUE;
      end if;
   end if;

   close C_CHECK_REGION_V;
   if O_valid = TRUE then
      if LANGUAGE_SQL.TRANSLATE(O_region_name,
                                O_region_name,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_REGION;

--------------------------------------------------------------------------------
-- VALIDATE_REGION( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_REGION(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid         IN OUT BOOLEAN,
                         O_look_down_ind IN OUT VARCHAR2,
                         O_region_name   IN OUT V_REGION.REGION_NAME%TYPE,
                         I_region        IN     V_REGION.REGION%TYPE,
                         I_org_level     IN     FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE,
                         I_org_id        IN     FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_REGION';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_REGION_DISTRICT_V is
      select 'X'
        from v_district
       where region = I_region
         and district = I_org_id;

BEGIN

   if(I_org_level = 'C') then
      O_look_down_ind := 'N';
      if(VALIDATE_REGION(O_error_message,
                         O_valid,
                         O_region_name,
                         I_org_id, -- chain
                         NULL, -- area
                         I_region) = FALSE) then
         return FALSE;
      end if;
   elsif(I_org_level = 'A') then
      O_look_down_ind := 'N';
      if(VALIDATE_REGION(O_error_message,
                         O_valid,
                         O_region_name,
                         NULL, -- chain
                         I_org_id, -- area
                         I_region) = FALSE) then
         return FALSE;
      end if;
   else
      O_look_down_ind := 'Y';
      open C_CHECK_REGION_DISTRICT_V;
      fetch C_CHECK_REGION_DISTRICT_V into L_dummy;
      if C_CHECK_REGION_DISTRICT_V%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER', '@OH4', '@OH5', NULL);
         O_valid := FALSE;
      else
         O_valid := TRUE;
      end if;
      close C_CHECK_REGION_DISTRICT_V;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_REGION;

--------------------------------------------------------------------------------
-- VALIDATE_REGION( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_REGION(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid         IN OUT BOOLEAN,
                         O_region_name   IN OUT V_REGION.REGION_NAME%TYPE,
                         I_region        IN     V_REGION.REGION%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_REGION';

BEGIN
   if VALIDATE_REGION(O_error_message,
                      O_valid,
                      O_region_name,
                      NULL,
                      NULL,
                      I_region) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_REGION;

--------------------------------------------------------------------------------
-- VALIDATE_DISTRICT( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_DISTRICT(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_valid         IN OUT BOOLEAN,
                           O_district_name IN OUT V_DISTRICT.DISTRICT_NAME%TYPE,
                           I_chain         IN     V_CHAIN.CHAIN%TYPE,
                           I_area          IN     V_AREA.AREA%TYPE,
                           I_region        IN     V_REGION.REGION%TYPE,
                           I_district      IN     V_DISTRICT.DISTRICT%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_DISTRICT';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_DISTRICT_TB is
      select district_name
        from district
       where district = I_district;

   cursor C_CHECK_DISTRICT_V is
      select district_name
        from v_district
       where district = I_district;

   cursor C_CHECK_DISTRICT_CHAIN_V is
      select 'X'
        from v_district
       where district = I_district
         and chain = I_chain;

   cursor C_CHECK_DISTRICT_AREA_V is
      select 'X'
        from v_district
       where district = I_district
         and area = I_area;

   cursor C_CHECK_DISTRICT_REGION_V is
      select 'X'
        from v_district
       where district = I_district
         and region = I_region;

BEGIN
   open C_CHECK_DISTRICT_V;
   fetch C_CHECK_DISTRICT_V into O_district_name;
   if C_CHECK_DISTRICT_V%NOTFOUND then
      open C_CHECK_DISTRICT_TB;
      fetch C_CHECK_DISTRICT_TB into O_district_name;
      if C_CHECK_DISTRICT_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_DISTRICT', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', '@OH5', I_district, NULL);
      end if;
      close C_CHECK_DISTRICT_TB;
      O_valid := FALSE;
   else
      if I_region is not null then
         open C_CHECK_DISTRICT_REGION_V;
         fetch C_CHECK_DISTRICT_REGION_V into L_dummy;
         if C_CHECK_DISTRICT_REGION_V%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER', '@OH5', '@OH4', NULL);
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_DISTRICT_REGION_V;
      elsif I_area is not null then
            open C_CHECK_DISTRICT_AREA_V;
            fetch C_CHECK_DISTRICT_AREA_V into L_dummy;
            if C_CHECK_DISTRICT_AREA_V%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER', '@OH5', '@OH3', NULL);
               O_valid := FALSE;
            else
               O_valid := TRUE;
            end if;
            close C_CHECK_DISTRICT_AREA_V;
         elsif I_chain is not null then
               open C_CHECK_DISTRICT_CHAIN_V;
               fetch C_CHECK_DISTRICT_CHAIN_V into L_dummy;
               if C_CHECK_DISTRICT_CHAIN_V%NOTFOUND then
                  O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER', '@OH5', '@OH2', NULL);
                  O_valid := FALSE;
               else
                  O_valid := TRUE;
               end if;
               close C_CHECK_DISTRICT_CHAIN_V;
            else
               O_valid := TRUE;
      end if;
   end if;

   close C_CHECK_DISTRICT_V;
   if O_valid = TRUE then
      if LANGUAGE_SQL.TRANSLATE(O_district_name,
                                O_district_name,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_DISTRICT;

--------------------------------------------------------------------------------
-- VALIDATE_DISTRICT( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_DISTRICT(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_valid         IN OUT BOOLEAN,
                           O_district_name IN OUT V_DISTRICT.DISTRICT_NAME%TYPE,
                           I_district      IN     V_DISTRICT.DISTRICT%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_DISTRICT';

BEGIN
   if VALIDATE_DISTRICT(O_error_message,
                        O_valid,
                        O_district_name,
                        null,
                        null,
                        null,
                        I_district) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_DISTRICT;

--------------------------------------------------------------------------------
-- VALIDATE_STORE( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_STORE(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_valid         IN OUT BOOLEAN,
                        O_store         IN OUT V_STORE%ROWTYPE,
                        I_chain         IN     V_CHAIN.CHAIN%TYPE,
                        I_area          IN     V_AREA.AREA%TYPE,
                        I_region        IN     V_REGION.REGION%TYPE,
                        I_district      IN     V_DISTRICT.DISTRICT%TYPE,
                        I_store         IN     V_STORE.STORE%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_STORE';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_STORE_TB is
      select store_name
        from store
       where store = I_store;

   cursor C_CHECK_STORE_V is
      select *
        from v_store
       where store = I_store;

   cursor C_CHECK_STORE_CHAIN_V is
      select 'X'
        from v_store
       where store = I_store
         and chain = I_chain;

   cursor C_CHECK_STORE_AREA_V is
      select 'X'
        from v_store
       where store = I_store
         and area = I_area;

   cursor C_CHECK_STORE_REGION_V is
      select 'X'
        from v_store
       where store = I_store
         and region = I_region;

   cursor C_CHECK_STORE_DISTRICT_V is
      select 'X'
        from v_store
       where store = I_store
         and district = I_district;

BEGIN
   open C_CHECK_STORE_V;
   fetch C_CHECK_STORE_V into O_store;
   if C_CHECK_STORE_V%NOTFOUND then
      open C_CHECK_STORE_TB;
      fetch C_CHECK_STORE_TB into O_store.store_name;
      if C_CHECK_STORE_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_STORE', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_LOC', I_store, NULL);
      end if;
      close C_CHECK_STORE_TB;
      O_valid := FALSE;
   else
      if I_district is not null then
         open C_CHECK_STORE_DISTRICT_V;
         fetch C_CHECK_STORE_DISTRICT_V into L_dummy;
         if C_CHECK_STORE_DISTRICT_V%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER_STORE', '@OH5', NULL);
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_STORE_DISTRICT_V;
      elsif I_region is not null then
            open C_CHECK_STORE_REGION_V;
            fetch C_CHECK_STORE_REGION_V into L_dummy;
            if C_CHECK_STORE_REGION_V%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER_STORE', '@OH4', NULL);
               O_valid := FALSE;
            else
               O_valid := TRUE;
            end if;
            close C_CHECK_STORE_REGION_V;
         elsif I_area is not null then
               open C_CHECK_STORE_AREA_V;
               fetch C_CHECK_STORE_AREA_V into L_dummy;
               if C_CHECK_STORE_AREA_V%NOTFOUND then
                  O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER_STORE', '@OH3', NULL);
                  O_valid := FALSE;
               else
                  O_valid := TRUE;
               end if;
               close C_CHECK_STORE_AREA_V;
            elsif I_chain is not null then
                  open C_CHECK_STORE_CHAIN_V;
                  fetch C_CHECK_STORE_CHAIN_V into L_dummy;
                  if C_CHECK_STORE_CHAIN_V%NOTFOUND then
                     O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER_STORE', '@OH2', NULL);
                     O_valid := FALSE;
                  else
                     O_valid := TRUE;
                  end if;
                  close C_CHECK_STORE_CHAIN_V;
               else
                  O_valid := TRUE;
      end if;
   end if;

   close C_CHECK_STORE_V;
   if O_valid = TRUE then
      if LANGUAGE_SQL.TRANSLATE(O_store.store_name,
                                O_store.store_name,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_STORE;

--------------------------------------------------------------------------------
-- VALIDATE_STORE( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_STORE(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_valid         IN OUT BOOLEAN,
                        O_store_name    IN OUT V_STORE.STORE_NAME%TYPE,
                        I_chain         IN     V_CHAIN.CHAIN%TYPE,
                        I_area          IN     V_AREA.AREA%TYPE,
                        I_region        IN     V_REGION.REGION%TYPE,
                        I_district      IN     V_DISTRICT.DISTRICT%TYPE,
                        I_store         IN     V_STORE.STORE%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_STORE';

   L_store     V_STORE%ROWTYPE;

BEGIN
   if VALIDATE_STORE(O_error_message,
                     O_valid,
                     L_store,
                     I_chain,
                     I_area,
                     I_region,
                     I_district,
                     I_store) = FALSE then
      return FALSE;
   end if;

   O_store_name := L_store.store_name;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_STORE;
--------------------------------------------------------------------------------
-- VALIDATE_STORE( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_STORE(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_valid         IN OUT BOOLEAN,
                        O_store_name    IN OUT V_STORE.STORE_NAME%TYPE,
                        I_store         IN     V_STORE.STORE%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_STORE';

   L_store     V_STORE%ROWTYPE;

BEGIN
   if VALIDATE_STORE(O_error_message,
                     O_valid,
                     L_store,
                     null,
                     null,
                     null,
                     null,
                     I_store) = FALSE then
      return FALSE;
   end if;

   O_store_name := L_store.store_name;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_STORE;

--------------------------------------------------------------------------------
-- VALIDATE_WH( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_WH(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     O_valid         IN OUT BOOLEAN,
                     O_wh            IN OUT V_WH%ROWTYPE,
                     I_wh            IN     V_WH.WH%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_WH';

   CURSOR C_CHECK_WH_TB IS
      SELECT wh_name, stockholding_ind
        FROM wh
       WHERE wh = I_wh
         AND finisher_ind = 'N';

   CURSOR C_CHECK_WH_V IS
      SELECT *
        FROM v_wh
       WHERE wh = I_wh;

BEGIN
   open C_CHECK_WH_V;
   fetch C_CHECK_WH_V into O_wh;
   if C_CHECK_WH_V%NOTFOUND then
      open C_CHECK_WH_TB;
      fetch C_CHECK_WH_TB into O_wh.wh_name, O_wh.stockholding_ind;
      if C_CHECK_WH_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_WH', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_LOC', I_wh, NULL);
      end if;
      close C_CHECK_WH_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_wh.wh_name,
                                O_wh.wh_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_CHECK_WH_V;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_WH;

--------------------------------------------------------------------------------
-- VALIDATE_PHYSICAL_WH( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_PHYSICAL_WH(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_valid         IN OUT BOOLEAN,
                              O_full_ind      IN OUT VARCHAR2,
                              O_wh            IN OUT V_PHYSICAL_WH%ROWTYPE,
                              I_wh            IN     V_PHYSICAL_WH.WH%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_PHYSICAL_WH';
   L_dummy     VARCHAR2(1)    := 'N';

   CURSOR C_CHECK_WH_TB IS
      SELECT wh_name
        FROM wh
       WHERE wh = I_wh
         and wh = physical_wh;

   CURSOR C_CHECK_WH_FULL IS
      SELECT *
        FROM v_physical_wh
       WHERE wh = I_wh;

   CURSOR C_CHECK_WH_PARTIAL IS
      SELECT 'Y'
        FROM wh
       WHERE wh = I_wh
         and wh = physical_wh
         and exists (select 'X'
                       from v_wh
                      where v_wh.physical_wh = wh.wh
                        and v_wh.physical_wh <> v_wh.wh);

BEGIN
   O_full_ind := 'N';

   open C_CHECK_WH_FULL;
   fetch C_CHECK_WH_FULL into O_wh;
   if C_CHECK_WH_FULL%NOTFOUND then
      open C_CHECK_WH_TB;
      fetch C_CHECK_WH_TB into O_wh.wh_name;
      if C_CHECK_WH_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_PHYSICAL_WH', NULL, NULL, NULL);
         O_valid := FALSE;
      else
         -- still populate message for both cases.  This will be used if full access is required
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_LOC', I_wh, NULL);

         open C_CHECK_WH_PARTIAL;
         fetch C_CHECK_WH_PARTIAL into L_dummy;
         if C_CHECK_WH_PARTIAL%NOTFOUND then
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_WH_PARTIAL;
      end if;
      close C_CHECK_WH_TB;
   else
      if LANGUAGE_SQL.TRANSLATE(O_wh.wh_name,
                                O_wh.wh_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_full_ind := 'Y';
      O_valid := TRUE;
   end if;

   close C_CHECK_WH_FULL;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_PHYSICAL_WH;

--------------------------------------------------------------------------------
-- VALIDATE_LOCATION( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_LOCATION(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_valid            IN OUT BOOLEAN,
                           O_loc_name         IN OUT V_STORE.STORE_NAME%TYPE,
                           O_stockholding_ind IN OUT V_STORE.STOCKHOLDING_IND%TYPE,
                           I_location         IN     V_STORE.STORE%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_LOCATION';

   L_loc_type  VARCHAR2(1);
   L_dummy     VARCHAR2(1);

   CURSOR C_CHECK_LOC_TB IS
      SELECT wh_name loc_name,
             stockholding_ind,
             'W' AS loc_type
        FROM wh
       WHERE wh = I_location
         and finisher_ind = 'N'
     UNION
      SELECT store_name loc_name,
             stockholding_ind,
             'S'
        FROM store
       WHERE store = I_location;

   CURSOR C_CHECK_WH_V IS
      SELECT 'X'
        FROM v_wh
       WHERE wh = I_location;

   CURSOR C_CHECK_STORE_V IS
      SELECT 'X'
        FROM v_store
       WHERE store = I_location;

BEGIN
   O_valid := FALSE;
   open C_CHECK_LOC_TB;
   fetch C_CHECK_LOC_TB into O_loc_name, O_stockholding_ind, L_loc_type;
   if C_CHECK_LOC_TB%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_LOC', NULL, NULL, NULL);
   else
      if L_loc_type = 'S' then
         open C_CHECK_STORE_V;
         fetch C_CHECK_STORE_V into L_dummy;
         if C_CHECK_STORE_V%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_LOC', I_location, NULL);
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_STORE_V;
      else
         open C_CHECK_WH_V;
         fetch C_CHECK_WH_V into L_dummy;
         if C_CHECK_WH_V%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_LOC', I_location, NULL);
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_WH_V;
      end if;

      if O_valid = TRUE then
         if LANGUAGE_SQL.TRANSLATE(O_loc_name,
                                   O_loc_name,
                                   O_error_message) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;

   close C_CHECK_LOC_TB;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_LOCATION;

--------------------------------------------------------------------------------
-- VALIDATE_DIVISION( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_DIVISION(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_valid         IN OUT BOOLEAN,
                           O_div_name      IN OUT V_DIVISION.DIV_NAME%TYPE,
                           I_division      IN     V_DIVISION.DIVISION%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_DIVISION';

   cursor C_CHECK_DIVISION_TB is
      select div_name
        from division
       where division = I_division;

   cursor C_CHECK_DIVISION_V is
      select div_name
        from v_division
       where division = I_division;

BEGIN
   open C_CHECK_DIVISION_V;
   fetch C_CHECK_DIVISION_V into O_div_name;
   if C_CHECK_DIVISION_V%NOTFOUND then
      open C_CHECK_DIVISION_TB;
      fetch C_CHECK_DIVISION_TB into O_div_name;
      if C_CHECK_DIVISION_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_DIVISION', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', '@MH2', I_division, NULL);
      end if;
      close C_CHECK_DIVISION_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_div_name,
                                O_div_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_CHECK_DIVISION_V;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_DIVISION;

--------------------------------------------------------------------------------
-- VALIDATE_GROUPS( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_GROUPS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid         IN OUT BOOLEAN,
                         O_group_name    IN OUT V_GROUPS.GROUP_NAME%TYPE,
                         I_division      IN     V_DIVISION.DIVISION%TYPE,
                         I_group_no      IN     V_GROUPS.GROUP_NO%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_GROUPS';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_GROUPS_TB is
      select group_name
        from groups
       where group_no = I_group_no;

   cursor C_CHECK_GROUPS_V is
      select group_name
        from v_groups
       where group_no = I_group_no;

   cursor C_CHECK_GROUPS_DIVISION_V is
      select 'X'
        from v_groups
       where group_no = I_group_no
         and division = I_division;

BEGIN
   open C_CHECK_GROUPS_V;
   fetch C_CHECK_GROUPS_V into O_group_name;
   if C_CHECK_GROUPS_V%NOTFOUND then
      open C_CHECK_GROUPS_TB;
      fetch C_CHECK_GROUPS_TB into O_group_name;
      if C_CHECK_GROUPS_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_GROUP', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', '@MH3', I_group_no, NULL);
      end if;
      close C_CHECK_GROUPS_TB;
      O_valid := FALSE;
   else
      if I_division is not null then
         open C_CHECK_GROUPS_DIVISION_V;
         fetch C_CHECK_GROUPS_DIVISION_V into L_dummy;
         if C_CHECK_GROUPS_DIVISION_V%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('INV_MERCH_HIER', '@MH3', '@MH2', NULL);
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_GROUPS_DIVISION_V;
      else
         O_valid := TRUE;
      end if;
   end if;

   close C_CHECK_GROUPS_V;
   if O_valid = TRUE then
      if LANGUAGE_SQL.TRANSLATE(O_group_name,
                                O_group_name,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_GROUPS;

--------------------------------------------------------------------------------
-- VALIDATE_GROUPS( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_GROUPS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid         IN OUT BOOLEAN,
                         O_group_name    IN OUT V_GROUPS.GROUP_NAME%TYPE,
                         I_group_no      IN     V_GROUPS.GROUP_NO%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_GROUPS';

BEGIN
   if VALIDATE_GROUPS(O_error_message,
                      O_valid,
                      O_group_name,
                      null,
                      I_group_no) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_GROUPS;

--------------------------------------------------------------------------------
-- VALIDATE_DEPS( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_DEPS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_valid         IN OUT BOOLEAN,
                       O_dept_name     IN OUT V_DEPS.DEPT_NAME%TYPE,
                       I_division      IN     V_DIVISION.DIVISION%TYPE,
                       I_group_no      IN     V_GROUPS.GROUP_NO%TYPE,
                       I_dept          IN     V_DEPS.DEPT%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_DEPS';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_DEPS_TB is
      select dept_name
        from deps
       where dept = I_dept;

   cursor C_CHECK_DEPS_V is
      select dept_name
        from v_deps
       where dept = I_dept;

   cursor C_CHECK_DEPS_GROUPS_V is
      select 'X'
        from v_deps
       where dept = I_dept
         and group_no = I_group_no;

   cursor C_CHECK_DEPS_DIVISION_V is
      select 'X'
        from v_deps
       where dept = I_dept
         and division = I_division;

BEGIN
   open C_CHECK_DEPS_V;
   fetch C_CHECK_DEPS_V into O_dept_name;
   if C_CHECK_DEPS_V%NOTFOUND then
      open C_CHECK_DEPS_TB;
      fetch C_CHECK_DEPS_TB into O_dept_name;
      if C_CHECK_DEPS_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_DEPT', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', '@MH4', I_dept, NULL);
      end if;
      close C_CHECK_DEPS_TB;
      O_valid := FALSE;
   else
      if I_group_no is not null then
         open C_CHECK_DEPS_GROUPS_V;
         fetch C_CHECK_DEPS_GROUPS_V into L_dummy;
         if C_CHECK_DEPS_GROUPS_V%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('INV_MERCH_HIER', '@MH4', '@MH3', NULL);
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_DEPS_GROUPS_V;
      elsif I_division is not null then
            open C_CHECK_DEPS_DIVISION_V;
            fetch C_CHECK_DEPS_DIVISION_V into L_dummy;
            if C_CHECK_DEPS_DIVISION_V%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INV_MERCH_HIER', '@MH4', '@MH2', NULL);
               O_valid := FALSE;
            else
               O_valid := TRUE;
            end if;
            close C_CHECK_DEPS_DIVISION_V;
         else
            O_valid := TRUE;
      end if;
   end if;

   close C_CHECK_DEPS_V;
   if O_valid = TRUE then
      if LANGUAGE_SQL.TRANSLATE(O_dept_name,
                                O_dept_name,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_DEPS;

--------------------------------------------------------------------------------
-- VALIDATE_DEPS( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_DEPS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_valid         IN OUT BOOLEAN,
                       O_dept_name     IN OUT V_DEPS.DEPT_NAME%TYPE,
                       I_dept          IN     V_DEPS.DEPT%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_DEPS';

BEGIN
   if VALIDATE_DEPS(O_error_message,
                    O_valid,
                    O_dept_name,
                    null,
                    null,
                    I_dept) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_DEPS;

--------------------------------------------------------------------------------
-- VALIDATE_CLASS( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_CLASS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_valid         IN OUT BOOLEAN,
                        O_class_name    IN OUT V_CLASS.CLASS_NAME%TYPE,
                        I_dept          IN     V_CLASS.DEPT%TYPE,
                        I_class         IN     V_CLASS.CLASS%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_CLASS';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_CLASS_TB is
      select class_name
        from class
       where dept = I_dept
         and class = I_class;

   cursor C_CHECK_CLASS_V is
      select class_name
        from v_class
       where dept = I_dept
         and class = I_class;

BEGIN
   O_class_name := NULL;

   open C_CHECK_CLASS_V;
   fetch C_CHECK_CLASS_V into O_class_name;
   close C_CHECK_CLASS_V;
   if O_class_name is NULL then
      open C_CHECK_CLASS_TB;
      fetch C_CHECK_CLASS_TB into O_class_name;
      close C_CHECK_CLASS_TB;
      if O_class_name is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_CLASS', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', '@MH5', I_class, NULL);
      end if;
      O_valid := FALSE;
   else
      O_valid := TRUE;
   end if;

   if O_valid = TRUE then
      if LANGUAGE_SQL.TRANSLATE(O_class_name,
                                O_class_name,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_CLASS;

--------------------------------------------------------------------------------
-- VALIDATE_SUBCLASS( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_SUBCLASS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_valid         IN OUT BOOLEAN,
                           O_subclass_name IN OUT V_SUBCLASS.SUB_NAME%TYPE,
                           I_dept          IN     V_SUBCLASS.DEPT%TYPE,
                           I_class         IN     V_SUBCLASS.CLASS%TYPE,
                           I_subclass      IN     V_SUBCLASS.SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_SUBCLASS';
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_SUBCLASS_TB is
      select sub_name
        from subclass
       where dept = I_dept
         and class = I_class
         and subclass = I_subclass;

   cursor C_CHECK_SUBCLASS_V is
      select sub_name
        from v_subclass
       where dept = I_dept
         and class = I_class
         and subclass = I_subclass;

BEGIN
   O_subclass_name := NULL;

   open C_CHECK_SUBCLASS_V;
   fetch C_CHECK_SUBCLASS_V into O_subclass_name;
   close C_CHECK_SUBCLASS_V;
   if O_subclass_name is NULL then
      open C_CHECK_SUBCLASS_TB;
      fetch C_CHECK_SUBCLASS_TB into O_subclass_name;
      close C_CHECK_SUBCLASS_TB;
      if O_subclass_name is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_SUBCLASS', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', '@MH6', I_subclass, NULL);
      end if;
      O_valid := FALSE;
   else
      O_valid := TRUE;
   end if;

   if O_valid = TRUE then
      if LANGUAGE_SQL.TRANSLATE(O_subclass_name,
                                O_subclass_name,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_SUBCLASS;

--------------------------------------------------------------------------------
-- VALIDATE_ITEM_MASTER( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_ITEM_MASTER(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_valid         IN OUT BOOLEAN,
                              O_item_master   IN OUT V_ITEM_MASTER%ROWTYPE,
                              I_division      IN     V_ITEM_MASTER.DIVISION%TYPE,
                              I_group_no      IN     V_ITEM_MASTER.GROUP_NO%TYPE,
                              I_dept          IN     V_ITEM_MASTER.DEPT%TYPE,
                              I_class         IN     V_ITEM_MASTER.CLASS%TYPE,
                              I_subclass      IN     V_ITEM_MASTER.SUBCLASS%TYPE,
                              I_item          IN     V_ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_ITEM_MASTER';

   L_dummy              VARCHAR2(1);

   cursor C_CHECK_ITEM_MASTER_TB is
      select 'X'
        from item_master
       where item = I_item;

   cursor C_CHECK_ITEM_MASTER_V is
      select *
        from v_item_master
       where item = I_item;

   cursor C_CHECK_ITEM_DIVISION_V is
      select 'X'
        from v_item_master
       where item = I_item
         and division = I_division;

   cursor C_CHECK_ITEM_GROUP_V is
      select 'X'
        from v_item_master
       where item = I_item
         and group_no = I_group_no;

   cursor C_CHECK_ITEM_DEPT_V is
      select 'X'
        from v_item_master
       where item = I_item
         and dept = I_dept;

   cursor C_CHECK_ITEM_CLASS_V is
      select 'X'
        from v_item_master
       where item = I_item
         and dept = I_dept
         and class = I_class;

   cursor C_CHECK_ITEM_SUBCLASS_V is
      select 'X'
        from v_item_master
       where item = I_item
         and dept = I_dept
         and class = I_class
         and subclass = I_subclass;

BEGIN
   open C_CHECK_ITEM_MASTER_V;
   fetch C_CHECK_ITEM_MASTER_V into O_item_master;
   if C_CHECK_ITEM_MASTER_V%NOTFOUND then
      open C_CHECK_ITEM_MASTER_TB;
      fetch C_CHECK_ITEM_MASTER_TB into L_dummy;
      if C_CHECK_ITEM_MASTER_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_ITEM', I_item, NULL);
      end if;
      close C_CHECK_ITEM_MASTER_TB;
      O_valid := FALSE;
   else
      if I_subclass is not null then
         open C_CHECK_ITEM_SUBCLASS_V;
         fetch C_CHECK_ITEM_SUBCLASS_V into L_dummy;
         if C_CHECK_ITEM_SUBCLASS_V%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER_ITEM', '@MH4/@MH5/@MH6', NULL);
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_ITEM_SUBCLASS_V;
      elsif I_class is not null then
            open C_CHECK_ITEM_CLASS_V;
            fetch C_CHECK_ITEM_CLASS_V into L_dummy;
            if C_CHECK_ITEM_CLASS_V%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER_ITEM', '@MH4/@MH5', NULL);
               O_valid := FALSE;
            else
               O_valid := TRUE;
            end if;
            close C_CHECK_ITEM_CLASS_V;
         elsif I_dept is not null then
               open C_CHECK_ITEM_DEPT_V;
               fetch C_CHECK_ITEM_DEPT_V into L_dummy;
               if C_CHECK_ITEM_DEPT_V%NOTFOUND then
                  O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER_ITEM', '@MH4', NULL);
                  O_valid := FALSE;
               else
                  O_valid := TRUE;
               end if;
               close C_CHECK_ITEM_DEPT_V;
            elsif I_group_no is not null then
                  open C_CHECK_ITEM_GROUP_V;
                  fetch C_CHECK_ITEM_GROUP_V into L_dummy;
                  if C_CHECK_ITEM_GROUP_V%NOTFOUND then
                     O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER_ITEM', '@MH3', NULL);
                     O_valid := FALSE;
                  else
                     O_valid := TRUE;
                  end if;
                  close C_CHECK_ITEM_GROUP_V;
               elsif I_division is not null then
                     open C_CHECK_ITEM_DIVISION_V;
                     fetch C_CHECK_ITEM_DIVISION_V into L_dummy;
                     if C_CHECK_ITEM_DIVISION_V%NOTFOUND then
                        O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_HIER_ITEM', '@MH2', NULL);
                        O_valid := FALSE;
                     else
                        O_valid := TRUE;
                     end if;
                     close C_CHECK_ITEM_DIVISION_V;
                  else
                     O_valid := TRUE;
      end if;
   end if;

   close C_CHECK_ITEM_MASTER_V;
   if O_valid = TRUE then
      if LANGUAGE_SQL.TRANSLATE(O_item_master.item_desc,
                                O_item_master.item_desc,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_ITEM_MASTER;

--------------------------------------------------------------------------------
-- VALIDATE_ITEM_MASTER( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_ITEM_MASTER(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_valid         IN OUT BOOLEAN,
                              O_item_master   IN OUT V_ITEM_MASTER%ROWTYPE,
                              I_item          IN     V_ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_ITEM_MASTER';

BEGIN
   if VALIDATE_ITEM_MASTER(O_error_message,
                           O_valid,
                           O_item_master,
                           null,
                           null,
                           null,
                           null,
                           null,
                           I_item) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_ITEM_MASTER;

--------------------------------------------------------------------------------
-- VALIDATE_DIFF_GROUP_HEAD( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_DIFF_GROUP_HEAD(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_valid           IN OUT BOOLEAN,
                                  O_diff_group_desc IN OUT V_DIFF_GROUP_HEAD.DIFF_GROUP_DESC%TYPE,
                                  I_diff_type       IN     V_DIFF_GROUP_HEAD.DIFF_TYPE%TYPE,
                                  I_diff_group_id   IN     V_DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
RETURN BOOLEAN IS

   L_program             VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_DIFF_GROUP_HEAD';

   L_hier                       VARCHAR2(128);
   L_org_id                     DIFF_GROUP_HEAD.FILTER_ORG_ID%TYPE;
   L_merch_id                   DIFF_GROUP_HEAD.FILTER_MERCH_ID%TYPE;
   L_filter_merch_id_class      DIFF_GROUP_HEAD.FILTER_MERCH_ID_CLASS%TYPE;
   L_filter_merch_id_subclass   DIFF_GROUP_HEAD.FILTER_MERCH_ID_SUBCLASS%TYPE;


   cursor C_CHECK_DIFF_GROUP_TB is
      select diff_group_desc,
             filter_org_id,
             filter_merch_id,
             filter_merch_id_class,
             filter_merch_id_subclass
        from diff_group_head
       where diff_group_id = I_diff_group_id
         and diff_type = I_diff_type;

   cursor C_CHECK_DIFF_GROUP_V is
      select diff_group_desc
        from v_diff_group_head
       where diff_group_id = I_diff_group_id
         and diff_type = I_diff_type;



BEGIN
   O_diff_group_desc := NULL;
   open C_CHECK_DIFF_GROUP_V;
   fetch C_CHECK_DIFF_GROUP_V into O_diff_group_desc;
   close C_CHECK_DIFF_GROUP_V;
   if O_diff_group_desc is NULL then
      open C_CHECK_DIFF_GROUP_TB;
      fetch C_CHECK_DIFF_GROUP_TB into O_diff_group_desc,
                                       L_org_id,
                                       L_merch_id,
                                       L_filter_merch_id_class,
                                       L_filter_merch_id_subclass;
      close C_CHECK_DIFF_GROUP_TB;
      if O_diff_group_desc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_DIFF_GROUP', NULL, NULL, NULL);
      else
         if GET_NON_VISIBLE_HIER(O_error_message,
                                 L_hier,
                                 L_org_id,
                                 FILTER_POLICY_SQL.GP_diff_group_org_level,
                                 L_merch_id,
                                 FILTER_POLICY_SQL.GP_diff_group_merch_level,
                                 L_filter_merch_id_class,
                                 L_filter_merch_id_subclass) = FALSE then
            return FALSE;
         end if;

         -- If no hierarchy was returned, raise a more generic error.
         if L_hier is not NULL then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_DIFF_GRP', L_hier, I_diff_group_id);
         else
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_ANY_DIFF_GRP', I_diff_group_id);
         end if;
      end if;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_diff_group_desc,
                                O_diff_group_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
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
-- VALIDATE_LOC_LISTS( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_LOC_LIST_HEAD(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_valid         IN OUT BOOLEAN,
                                O_loc_list_desc IN OUT V_LOC_LIST_HEAD.LOC_LIST_DESC%TYPE,
                                I_loc_list      IN     V_LOC_LIST_HEAD.LOC_LIST%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_LOC_LIST_HEAD';

   cursor C_CHECK_LOC_LIST_TB is
      select loc_list_desc
        from loc_list_head
       where loc_list = I_loc_list;

   cursor C_CHECK_LOC_LIST_V is
      select loc_list_desc
        from v_loc_list_head
       where loc_list = I_loc_list;

BEGIN
   open C_CHECK_LOC_LIST_V;
   fetch C_CHECK_LOC_LIST_V into O_loc_list_desc;
   if C_CHECK_LOC_LIST_V%NOTFOUND then
      open C_CHECK_LOC_LIST_TB;
      fetch C_CHECK_LOC_LIST_TB into O_loc_list_desc;
      if C_CHECK_LOC_LIST_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_LOC_LIST', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ANY_LOC_LIST', I_loc_list);
      end if;
      close C_CHECK_LOC_LIST_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_loc_list_desc,
                                O_loc_list_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_CHECK_LOC_LIST_V;
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
FUNCTION VALIDATE_LOC_TRAITS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_valid         IN OUT BOOLEAN,
                             O_description   IN OUT V_LOC_TRAITS.DESCRIPTION%TYPE,
                             I_loc_trait     IN     V_LOC_TRAITS.LOC_TRAIT%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_LOC_TRAITS';
   L_org_code  VARCHAR2(4);
   L_org_id    LOC_TRAITS.FILTER_ORG_ID%TYPE;

   cursor C_CHECK_LOC_TRAIT_TB is
      select description,
             filter_org_id
        from loc_traits
       where loc_trait = I_loc_trait;

   cursor C_CHECK_LOC_TRAIT_V is
      select description
        from v_loc_traits
       where loc_trait = I_loc_trait;

BEGIN
   open C_CHECK_LOC_TRAIT_V;
   fetch C_CHECK_LOC_TRAIT_V into O_description;
   if C_CHECK_LOC_TRAIT_V%NOTFOUND then
      open C_CHECK_LOC_TRAIT_TB;
      fetch C_CHECK_LOC_TRAIT_TB into O_description, L_org_id;
      if C_CHECK_LOC_TRAIT_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_LOC_TRAIT', NULL, NULL, NULL);
      else

         if GET_ORG_DYNAMIC_CODE(O_error_message,
                                 L_org_code,
                                 FILTER_POLICY_SQL.GP_loc_trait_org_level ) = FALSE then
            return FALSE;
         end if;

         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_LOC_TRAIT', L_org_code ||' '|| TO_CHAR(L_org_id), I_loc_trait);
      end if;
      close C_CHECK_LOC_TRAIT_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_description,
                                O_description,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_CHECK_LOC_TRAIT_V;
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
FUNCTION VALIDATE_SKULIST_HEAD(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_valid         IN OUT BOOLEAN,
                               O_skulist_desc  IN OUT V_SKULIST_HEAD.SKULIST_DESC%TYPE,
                               I_skulist       IN     V_SKULIST_HEAD.SKULIST%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_SKULIST_HEAD';

   L_skulist_head  V_SKULIST_HEAD%ROWTYPE;

BEGIN

   if VALIDATE_SKULIST_HEAD (O_error_message,
                             O_valid,
                             L_skulist_head,
                             I_skulist) = FALSE then
      return FALSE;
   end if;

   if O_valid then
      O_skulist_desc := L_skulist_head.skulist_desc;
   end if;

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
-- VALIDATE_SKULIST_HEAD( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_SKULIST_HEAD(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_valid         IN OUT BOOLEAN,
                               O_skulist_head  IN OUT V_SKULIST_HEAD%ROWTYPE,
                               I_skulist       IN     V_SKULIST_HEAD.SKULIST%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_SKULIST_HEAD';

   L_org_id    SKULIST_HEAD.FILTER_ORG_ID%TYPE;
   L_org_name  AREA.AREA_NAME%TYPE;
   L_valid     BOOLEAN;
   L_code      VARCHAR2(4);

   cursor C_CHECK_SKULIST_TB is
      select skulist_desc, filter_org_id
        from skulist_head
       where skulist = I_skulist;

   cursor C_CHECK_SKULIST_V is
      select *
        from v_skulist_head
       where skulist = I_skulist;

BEGIN
   open C_CHECK_SKULIST_V;
   fetch C_CHECK_SKULIST_V into O_skulist_head;
   if C_CHECK_SKULIST_V%NOTFOUND then
      open C_CHECK_SKULIST_TB;
      fetch C_CHECK_SKULIST_TB into O_skulist_head.skulist_desc, L_org_id;
      if C_CHECK_SKULIST_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_SKU_LIST', NULL, NULL, NULL);
      else
         L_valid := TRUE;
         if L_org_id is not NULL then
            if VALIDATE_ORG_LEVEL(O_error_message,
                                  L_valid,
                                  L_org_name,
                                  FILTER_POLICY_SQL.GP_skulist_org_level,
                                  L_org_id) = FALSE then
               return FALSE;
            end if;
         end if;

         if L_valid = FALSE then
            if GET_ORG_DYNAMIC_CODE(O_error_message,
                                    L_code,
                                    FILTER_POLICY_SQL.GP_skulist_org_level) = FALSE then
               return FALSE;
            end if;

            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_ITEM_LIST', L_code || ' ' || TO_CHAR(L_org_id), I_skulist);
         else
            -- must not have visibility to ALL departments
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ALL_DEPS_IL', I_skulist);
         end if;
      end if;
      close C_CHECK_SKULIST_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_skulist_head.skulist_desc,
                                O_skulist_head.skulist_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_CHECK_SKULIST_V;
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
FUNCTION VALIDATE_SEASONS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          O_valid         IN OUT BOOLEAN,
                          O_season_desc   IN OUT V_SEASONS.SEASON_DESC%TYPE,
                          I_season_id     IN     V_SEASONS.SEASON_ID%TYPE)
RETURN BOOLEAN IS

   L_program                    VARCHAR2(64)  := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_SEASONS';

   L_hier                       VARCHAR2(128);
   L_org_id                     SEASONS.FILTER_ORG_ID%TYPE;
   L_merch_id                   SEASONS.FILTER_MERCH_ID%TYPE;
   L_filter_merch_id_class      SEASONS.FILTER_MERCH_ID_CLASS%TYPE;
   L_filter_merch_id_subclass   SEASONS.FILTER_MERCH_ID_SUBCLASS%TYPE;

   cursor C_CHECK_SEASONS_TB is
      select season_desc,
             filter_org_id,
             filter_merch_id,
             filter_merch_id_class,
             filter_merch_id_subclass
        from seasons
       where season_id = I_season_id;

   cursor C_CHECK_SEASONS_V is
      select season_desc
        from v_seasons
       where season_id = I_season_id;

BEGIN
   O_season_desc := NULL;
   open C_CHECK_SEASONS_V;
   fetch C_CHECK_SEASONS_V into O_season_desc;
   close C_CHECK_SEASONS_V;
   if O_season_desc is NULL then
      open C_CHECK_SEASONS_TB;
      fetch C_CHECK_SEASONS_TB into O_season_desc,
                                    L_org_id,
                                    L_merch_id,
                                    L_filter_merch_id_class,
                                    L_filter_merch_id_subclass;
      close C_CHECK_SEASONS_TB;
      if O_season_desc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_SEASON', NULL, NULL, NULL);
      else
         if GET_NON_VISIBLE_HIER(O_error_message,
                                 L_hier,
                                 L_org_id,
                                 FILTER_POLICY_SQL.GP_seasons_org_level,
                                 L_merch_id,
                                 FILTER_POLICY_SQL.GP_seasons_merch_level,
                                 L_filter_merch_id_class,
                                 L_filter_merch_id_subclass) = FALSE then
            return FALSE;
         end if;

         if L_hier is not NULL then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_SEASON', L_hier, I_season_id);
         else
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_ANY_SEASON', I_season_id);
         end if;
      end if;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_season_desc,
                                O_season_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
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
FUNCTION VALIDATE_TICKET_TYPE_HEAD(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_valid            IN OUT BOOLEAN,
                                   O_ticket_type_desc IN OUT V_TICKET_TYPE_HEAD.TICKET_TYPE_DESC%TYPE,
                                   I_ticket_type_id   IN     V_TICKET_TYPE_HEAD.TICKET_TYPE_ID%TYPE)
RETURN BOOLEAN IS

   L_program                    VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_TICKET_TYPE_HEAD';

   L_hier                       VARCHAR2(128);
   L_org_id                     TICKET_TYPE_HEAD.FILTER_ORG_ID%TYPE;
   L_merch_id                   TICKET_TYPE_HEAD.FILTER_MERCH_ID%TYPE;
   L_filter_merch_id_class      TICKET_TYPE_HEAD.FILTER_MERCH_ID_CLASS%TYPE;
   L_filter_merch_id_subclass   TICKET_TYPE_HEAD.FILTER_MERCH_ID_SUBCLASS%TYPE;

   cursor C_CHECK_TICKET_TYPE_TB is
      select ticket_type_desc,
             filter_org_id,
             filter_merch_id,
             filter_merch_id_class,
             filter_merch_id_subclass
        from ticket_type_head
       where ticket_type_id = I_ticket_type_id;

   cursor C_CHECK_TICKET_TYPE_V is
      select ticket_type_desc
        from v_ticket_type_head
       where ticket_type_id = I_ticket_type_id;

BEGIN
   O_ticket_type_desc := NULL;
   open C_CHECK_TICKET_TYPE_V;
   fetch C_CHECK_TICKET_TYPE_V into O_ticket_type_desc;
   close C_CHECK_TICKET_TYPE_V;
   if O_ticket_type_desc is NULL then
      open C_CHECK_TICKET_TYPE_TB;
      fetch C_CHECK_TICKET_TYPE_TB into O_ticket_type_desc,
                                        L_org_id,
                                        L_merch_id,
                                        L_filter_merch_id_class,
                                        L_filter_merch_id_subclass;
      close C_CHECK_TICKET_TYPE_TB;
      if O_ticket_type_desc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_TCKT_TYPE', NULL, NULL, NULL);
      else
         if GET_NON_VISIBLE_HIER(O_error_message,
                                 L_hier,
                                 L_org_id,
                                 FILTER_POLICY_SQL.GP_ticket_type_org_level,
                                 L_merch_id,
                                 FILTER_POLICY_SQL.GP_ticket_type_merch_level,
                                 L_filter_merch_id_class,
                                 L_filter_merch_id_subclass) = FALSE then
            return FALSE;
         end if;

         if L_hier is not NULL then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_TKT_TYPE', L_hier, I_ticket_type_id);
         else
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_ANY_TKT_TYPE', I_ticket_type_id);
         end if;
      end if;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_ticket_type_desc,
                                O_ticket_type_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
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
FUNCTION VALIDATE_UDA(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                      O_valid         IN OUT BOOLEAN,
                      O_uda           IN OUT V_UDA%ROWTYPE,
                      O_uda_desc      IN OUT V_UDA.UDA_DESC%TYPE,
                      I_uda_id        IN     V_UDA.UDA_ID%TYPE)
RETURN BOOLEAN IS

   L_program                    VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_UDA';

   L_hier                       VARCHAR2(128);
   L_org_id                     UDA.FILTER_ORG_ID%TYPE;
   L_merch_id                   UDA.FILTER_MERCH_ID%TYPE;
   L_filter_merch_id_class      UDA.FILTER_MERCH_ID_CLASS%TYPE;
   L_filter_merch_id_subclass   UDA.FILTER_MERCH_ID_SUBCLASS%TYPE;

   cursor C_CHECK_UDA_TB is
      select uda_desc,
             filter_org_id,
             filter_merch_id,
             filter_merch_id_class,
             filter_merch_id_subclass
        from uda
       where uda_id = I_uda_id;

   cursor C_CHECK_UDA_V is
      select *
        from v_uda
       where uda_id = I_uda_id;

BEGIN
   O_uda_desc := NULL;
   open C_CHECK_UDA_V;
   fetch C_CHECK_UDA_V into O_uda;
   if C_CHECK_UDA_V%NOTFOUND then
      open C_CHECK_UDA_TB;
      fetch C_CHECK_UDA_TB into O_uda_desc,
                                L_org_id,
                                L_merch_id,
                                L_filter_merch_id_class,
                                L_filter_merch_id_subclass;
      close C_CHECK_UDA_TB;
      if O_uda_desc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_UDA', NULL, NULL, NULL);
      else
         if GET_NON_VISIBLE_HIER(O_error_message,
                                 L_hier,
                                 L_org_id,
                                 FILTER_POLICY_SQL.GP_uda_org_level,
                                 L_merch_id,
                                 FILTER_POLICY_SQL.GP_uda_merch_level,
                                 L_filter_merch_id_class,
                                 L_filter_merch_id_subclass) = FALSE then
            return FALSE;
         end if;

         if L_hier is not NULL then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_UDA', L_hier, I_uda_id);
         else
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_ANY_UDA', I_uda_id);
         end if;
      end if;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_uda.uda_desc,
                                O_uda.uda_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_uda_desc := O_uda.uda_desc;
      O_valid := TRUE;
   end if;

   close C_CHECK_UDA_V;
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
-- VALIDATE_UDA( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_UDA(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                      O_valid         IN OUT BOOLEAN,
                      O_uda_desc      IN OUT V_UDA.UDA_DESC%TYPE,
                      I_uda_id        IN     V_UDA.UDA_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_UDA';
   L_temp_uda V_UDA%ROWTYPE;

BEGIN

   if(VALIDATE_UDA(O_error_message,
                   O_valid,
                   L_temp_uda,
                   O_uda_desc,
                   I_uda_id) = FALSE) then
      return FALSE;
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
FUNCTION VALIDATE_TRANSFER_STORE(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_valid          IN OUT BOOLEAN,
                                 O_store_name     IN OUT V_TRANSFER_FROM_STORE.STORE_NAME%TYPE,
                                 IO_tsf_entity_id IN OUT V_TRANSFER_FROM_STORE.TSF_ENTITY_ID%TYPE,
                                 I_store          IN     V_TRANSFER_FROM_STORE.STORE%TYPE,
                                 I_to_from_ind    IN     VARCHAR2)
RETURN BOOLEAN IS

   L_inv_parm           VARCHAR2(30);
   L_stockholding_ind   STORE.STOCKHOLDING_IND%TYPE;
   L_tsf_entity_id      STORE.TSF_ENTITY_ID%TYPE;
   L_program            VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_TRANSFER_STORE';

   cursor C_CHECK_STORE_TB is
      select store_name,
             stockholding_ind
        from store
       where store = I_store;

   cursor C_CHECK_STORE_V is
      select store_name,
             tsf_entity_id
        from v_transfer_from_store
       where store = I_store
         and I_to_from_ind = 'F'
       UNION
      select store_name,
             tsf_entity_id
        from v_transfer_to_store
       where store = I_store
         and I_to_from_ind = 'T';

BEGIN

   if I_store is NULL then
      L_inv_parm := 'I_store';
   elsif I_to_from_ind is NULL then
      L_inv_parm := 'I_to_from_ind';
   end if;

   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_inv_parm,
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open C_CHECK_STORE_TB;
   fetch C_CHECK_STORE_TB into O_store_name, L_stockholding_ind;
   close C_CHECK_STORE_TB;

   if L_stockholding_ind is not NULL then
      -- the store exists in the system
      if L_stockholding_ind = 'N' then
         O_error_message := SQL_LIB.CREATE_MSG ('STOCKHOLD_STORE', NULL, NULL, NULL);
         O_valid := FALSE;
         return TRUE;
      end if;

      open C_CHECK_STORE_V;
      fetch C_CHECK_STORE_V into O_store_name,
                                 L_tsf_entity_id;
      if C_CHECK_STORE_V%NOTFOUND then
         if I_to_from_ind = 'T' then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_TRANS_TO', I_store);
         elsif I_to_from_ind = 'F' then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_TRANS_FROM', I_store);
         end if;
         O_valid := FALSE;
      else
         if IO_tsf_entity_id is not NULL and
         (L_tsf_entity_id is NULL or L_tsf_entity_id != IO_tsf_entity_id) then
            O_error_message:= SQL_LIB.CREATE_MSG('LOC_NOTIN_TSF_ENT', I_store, IO_tsf_entity_id, NULL);
            O_valid := FALSE;
         else
            IO_tsf_entity_id := L_tsf_entity_id;

            if LANGUAGE_SQL.TRANSLATE(O_store_name,
                                      O_store_name,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
            O_valid := TRUE;
         end if;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_STORE', NULL, NULL, NULL);
      O_valid := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_TRANSFER_STORE;
--------------------------------------------------------------------------------
FUNCTION VALIDATE_TRANSFER_WH(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_valid          IN OUT BOOLEAN,
                              O_wh_name        IN OUT V_TRANSFER_FROM_WH.WH_NAME%TYPE,
                              IO_tsf_entity_id IN OUT V_TRANSFER_FROM_WH.TSF_ENTITY_ID%TYPE,
                              I_wh             IN     V_TRANSFER_FROM_WH.WH%TYPE,
                              I_pwh_vwh_ind    IN     VARCHAR2,
                              I_to_from_ind    IN     VARCHAR2)
RETURN BOOLEAN IS

   L_inv_parm          VARCHAR2(30);
   L_code_desc         CODE_DETAIL.CODE_DESC%TYPE;
   L_view_query        VARCHAR2(100);
   L_program           VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_TRANSFER_WH';
   L_stockholding_ind  WH.STOCKHOLDING_IND%TYPE;

   cursor C_CHECK_WH_TB is
      select wh_name,
             stockholding_ind
        from wh
       where wh = I_wh
         and finisher_ind = 'N';

BEGIN

   if I_wh is NULL then
      L_inv_parm := 'I_wh';
   elsif I_pwh_vwh_ind is NULL then
      L_inv_parm := 'I_pwh_vwh_ind';
   elsif I_to_from_ind is NULL then
      L_inv_parm := 'I_to_from_ind';
   end if;

   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_inv_parm,
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   O_valid := TRUE;

   open C_CHECK_WH_TB;
   fetch C_CHECK_WH_TB into O_wh_name,
                            L_stockholding_ind;
   close C_CHECK_WH_TB;
   if O_wh_name is NULL and I_pwh_vwh_ind = 'P' then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PWH', NULL, NULL, NULL);
      O_valid := FALSE;
   elsif O_wh_name is NULL and I_pwh_vwh_ind = 'V' then
      O_error_message := SQL_LIB.CREATE_MSG('INV_VWH', NULL, NULL, NULL);
      O_valid := FALSE;
   elsif  I_pwh_vwh_ind = 'V' and L_stockholding_ind = 'N' then
      O_error_message := SQL_LIB.CREATE_MSG('PHYSICAL_WH_NOT_ALLOWED', NULL, NULL, NULL);
      O_valid := FALSE;
   else
      -- warehouse exists and has the correct physical/virtual distinction

      L_view_query := 'select wh_name, tsf_entity_id ';

      if I_to_from_ind = 'T' then
         L_view_query := L_view_query||' from v_transfer_to_wh';
      elsif I_to_from_ind = 'F' then
         L_view_query := L_view_query||' from v_transfer_from_wh';
      end if;

      L_view_query := L_view_query||' where wh = '||I_wh;

      ---
      DECLARE
         L_tsf_entity_id   WH.TSF_ENTITY_ID%TYPE;
      BEGIN
         -- this sub function is used to more precisely catch errors
         -- thrown by the dynamic query
         EXECUTE IMMEDIATE L_view_query into O_wh_name,
                                             L_tsf_entity_id;

         if IO_tsf_entity_id is not NULL
         and (L_tsf_entity_id is NULL or L_tsf_entity_id != IO_tsf_entity_id) then
            O_error_message:= SQL_LIB.CREATE_MSG('LOC_NOTIN_TSF_ENT', I_wh, IO_tsf_entity_id, NULL);
            O_valid := FALSE;
         else
            IO_tsf_entity_id := L_tsf_entity_id;
         end if;

      EXCEPTION
         when NO_DATA_FOUND then
            -- this exception is thrown if the dynamic query returns no rows
            if I_to_from_ind = 'F' then
               O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_TRANS_FROM', I_wh);
            elsif I_to_from_ind = 'T' then
               O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_TRANS_TO', I_wh);
            end if;
            O_valid := FALSE;

         when OTHERS then
            O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                   SQLERRM,
                                                   L_program,
                                                   to_char(SQLCODE));
            return FALSE;
      END;
      ---
   end if;

   if O_valid then
      if LANGUAGE_SQL.TRANSLATE(O_wh_name,
                                O_wh_name,
                                O_error_message) = FALSE then
         return FALSE;
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

END VALIDATE_TRANSFER_WH;
--------------------------------------------------------------------------------
-- VALIDATE_LOCATION_TYPE
--------------------------------------------------------------------------------
FUNCTION VALIDATE_LOCATION_TYPE(O_message       IN OUT VARCHAR2,
                                O_valid         IN OUT BOOLEAN,
                                O_value_desc    IN OUT VARCHAR2,
                                IO_second_value IN OUT VARCHAR2,
                                I_loc_type      IN     VARCHAR2,
                                I_value         IN     VARCHAR2)
         return BOOLEAN is

   QUICK_EXIT    EXCEPTION;
   L_program     VARCHAR2(60) := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_LOCATION_TYPE';

   L_stockholding_ind  STORE.STOCKHOLDING_IND%TYPE;
   L_wh                V_WH%ROWTYPE;
   L_physical_wh       V_PHYSICAL_WH%ROWTYPE;
   L_tsf_entity_id     V_INTERNAL_FINISHER.TSF_ENTITY_ID%TYPE;

BEGIN
   -- Store, District, Region, Area  (Chain is not done - C = Store Class)
   if I_loc_type in ('S', 'D','R','A') then
      if FILTER_LOV_VALIDATE_SQL.VALIDATE_ORG_LEVEL(O_message,
                                                    O_valid,
                                                    O_value_desc,
                                                    I_loc_type,
                                                    I_value) = FALSE then
         raise QUICK_EXIT;
      end if;
   --
      if O_valid and I_loc_type = 'S' then
         if LOCATION_ATTRIB_SQL.CHECK_STOCKHOLDING(O_message,
                                                   L_stockholding_ind,
                                                   I_value,
                                                   I_loc_type) = FALSE then
            raise QUICK_EXIT;
         end if;

         IO_second_value := L_stockholding_ind;
      end if;

   -- Location Traits
   elsif I_loc_type = 'L' then
      if FILTER_LOV_VALIDATE_SQL.VALIDATE_LOC_TRAITS(O_message,
                                                     O_valid,
                                                     O_value_desc,
                                                     I_value) = FALSE then
         raise QUICK_EXIT;
      end if;

   -- Location Lists (LL), Location Lists - Wh (LLW), Location Lists - St (LLS)
   elsif I_loc_type in ('LL', 'LLW', 'LLS') then
      if FILTER_LOV_VALIDATE_SQL.VALIDATE_LOC_LIST_HEAD(O_message,
                                                        O_valid,
                                                        O_value_desc,
                                                        I_value) = FALSE then
         raise QUICK_EXIT;
      end if;

   -- Store Classes
   elsif I_loc_type = 'C' then
      if FILTER_LOV_VALIDATE_SQL.VALIDATE_STORE_CLASS(O_message,
                                                      O_valid,
                                                      O_value_desc,
                                                      I_value) = FALSE then
         raise QUICK_EXIT;
      end if;


   -- Transfer Zone
   elsif I_loc_type = 'T' then
      if FILTER_LOV_VALIDATE_SQL.VALIDATE_TSF_ZONE(O_message,
                                                   O_valid,
                                                   O_value_desc,
                                                   I_value) = FALSE then
         raise QUICK_EXIT;
      end if;

   -- Price Zone ID
   elsif I_loc_type = 'Z' then
      if FILTER_LOV_VALIDATE_SQL.VALIDATE_PRICE_ZONE_ID(O_message,
                                                        O_valid,
                                                        O_value_desc,
                                                        I_value,
                                                        IO_second_value) = FALSE then
        raise QUICK_EXIT;
      end if;

   -- Warehouse
   elsif I_loc_type in ('DW', 'W') then

      if FILTER_LOV_VALIDATE_SQL.VALIDATE_WH(O_message,
                                             O_valid,
                                             L_wh,
                                             I_value) = FALSE then
         raise QUICK_EXIT;
      else
         O_value_desc    := L_wh.wh_name;
         IO_second_value := L_wh.stockholding_ind;
         if L_wh.stockholding_ind = 'N' then
            O_message := SQL_LIB.CREATE_MSG('ENTER_STOCK_LOCS', NULL, NULL, NULL);
            O_valid := FALSE;
         end if;
      end if;

   elsif I_loc_type = 'PW' then
      if FILTER_LOV_VALIDATE_SQL.VALIDATE_PHYSICAL_WH(O_message,
                                                      O_valid,
                                                      IO_second_value,
                                                      L_physical_wh,
                                                      I_value) = FALSE then
         raise QUICK_EXIT ;
      else
         O_value_desc    := L_physical_wh.wh_name;
      end if;
   elsif I_loc_type = 'I' then
      if FILTER_LOV_VALIDATE_SQL.VALIDATE_INTERNAL_FINISHER(O_message,
                                                            O_valid,
                                                            O_value_desc,
                                                            L_tsf_entity_id,
                                                            I_value) = FALSE then
        raise QUICK_EXIT;
      end if;

   elsif I_loc_type = 'E' then
      if FILTER_LOV_VALIDATE_SQL.VALIDATE_EXTERNAL_FINISHER(O_message,
                                                            O_valid,
                                                            O_value_desc,
                                                            L_tsf_entity_id,
                                                            I_value) = FALSE then
        raise QUICK_EXIT;
      end if;

   end if;

   return TRUE;

EXCEPTION
   when QUICK_EXIT then
      O_message := sql_lib.create_msg('PACKAGE_ERROR',
                                      O_message,
                                      L_program,
                                      null);

      return FALSE;
   when VALUE_ERROR then
      O_message := SQL_LIB.CREATE_MSG('ENTER_NUM',
                                       NULL,
                                       NULL,
                                       NULL);
      return FALSE;
   when OTHERS then
      O_message := sql_lib.create_msg('PACKAGE_ERROR',
                                      SQLERRM,
                                      L_program,
                                      null);

      return FALSE;
END VALIDATE_LOCATION_TYPE;
--------------------------------------------------------------------------------
-- VALIDATE_MERCH_LEVEL( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_MERCH_LEVEL(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_valid           IN OUT BOOLEAN,
                              O_name            IN OUT VARCHAR2,
                              I_merch_level_ind IN     SYSTEM_OPTIONS.VAT_IND%TYPE,
                              I_merch_level_id  IN     NUMBER,
                              I_class           IN     V_CLASS.CLASS%TYPE,
                              I_subclass        IN     V_SUBCLASS.SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_MERCH_LEVEL';

BEGIN
   if I_merch_level_ind = 'D' then
      if VALIDATE_DIVISION(O_error_message,
                           O_valid,
                           O_name,
                           I_merch_level_id) = FALSE then
         return FALSE;
      end if;
   elsif I_merch_level_ind = 'G' then
      if VALIDATE_GROUPS(O_error_message,
                         O_valid,
                         O_name,
                         null,
                         I_merch_level_id) = FALSE then
         return FALSE;
      end if;
   elsif I_merch_level_ind = 'P' then
      if VALIDATE_DEPS(O_error_message,
                       O_valid,
                       O_name,
                       null,
                       null,
                       I_merch_level_id) = FALSE then
         return FALSE;
      end if;
   elsif I_merch_level_ind = 'C' then
      if I_class is not NULL then
         if VALIDATE_CLASS(O_error_message,
                           O_valid,
                           O_name,
                           I_merch_level_id,
                           I_class) = FALSE then
            return FALSE;
         end if;
      end if;
   elsif I_merch_level_ind = 'S' then
      if I_subclass is not NULL then
         if VALIDATE_SUBCLASS(O_error_message,
                              O_valid,
                              O_name,
                              I_merch_level_id,
                              I_class,
                              I_subclass) = FALSE then
            return FALSE;
         end if;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_MERCH_LEVEL', NULL, NULL, NULL);
      O_valid := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_MERCH_LEVEL;
--------------------------------------------------------------------------------
-- VALIDATE_ORG_LEVEL( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_ORG_LEVEL(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                            O_valid          IN OUT  BOOLEAN,
                            O_name           IN OUT  VARCHAR2,
                            I_org_level_ind  IN      SYSTEM_OPTIONS.VAT_IND%TYPE,
                            I_org_level_id   IN      NUMBER)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_ORG_LEVEL';

BEGIN
   if I_org_level_ind = 'C' then
      if VALIDATE_CHAIN(O_error_message,
                        O_valid,
                        O_name,
                        I_org_level_id) = FALSE then
         return FALSE;
      end if;
   elsif I_org_level_ind = 'A' then
         if VALIDATE_AREA(O_error_message,
                          O_valid,
                          O_name,
                          null,
                          I_org_level_id) = FALSE then
            return FALSE;
         end if;
      elsif I_org_level_ind = 'R' then
            if VALIDATE_REGION(O_error_message,
                               O_valid,
                               O_name,
                               null,
                               null,
                               I_org_level_id) = FALSE then
               return FALSE;
            end if;
         elsif I_org_level_ind = 'D' then
               if VALIDATE_DISTRICT(O_error_message,
                                    O_valid,
                                    O_name,
                                    null,
                                    null,
                                    null,
                                    I_org_level_id) = FALSE then
                  return FALSE;
               end if;
            elsif I_org_level_ind = 'S' then
                  if VALIDATE_STORE(O_error_message,
                                    O_valid,
                                    O_name,
                                    I_org_level_id) = FALSE then
                     return FALSE;
                  end if;
               else
                  O_error_message := SQL_LIB.CREATE_MSG('INV_ORG_LEVEL', NULL, NULL, NULL);
                  O_valid := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_ORG_LEVEL;
----------------------------------------------------------------------------
FUNCTION VALIDATE_STORE_CLASS(O_error_message    IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                              O_valid            IN OUT  BOOLEAN,
                              O_store_class_desc IN OUT  CODE_DETAIL.CODE_DESC%TYPE,
                              I_store_class      IN      STORE.STORE_CLASS%TYPE)
RETURN BOOLEAN IS

   L_program           VARCHAR2(50) := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_STORE_CLASS';
   L_store_class_desc  CODE_DETAIL.CODE_DESC%TYPE := NULL;
   L_dummy             VARCHAR2(1);

   cursor C_CHECK_STORE_CLASS is
      select 'X'
        from code_detail
       where code_type = 'CSTR'
         and code = I_store_class;

   cursor C_CHECK_STORE_CLASS_TB is
      select c.code_desc
        from store s,
             code_detail c
       where s.store_class = I_store_class
         and c.code = s.store_class
         and c.code_type = 'CSTR'
         and rownum      = 1;

   cursor C_CHECK_STORE_CLASS_V is
      select c.code_desc
        from v_store s,
             code_detail c
       where s.store_class = I_store_class
         and c.code = s.store_class
         and c.code_type = 'CSTR'
         and rownum      = 1;

BEGIN

   if I_store_class is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_store_class,L_program,NULL);
      return FALSE;
   else
      open  C_CHECK_STORE_CLASS;
      fetch C_CHECK_STORE_CLASS into L_dummy;
      close C_CHECK_STORE_CLASS;

      if L_dummy is NULL then
         O_error_message := SQL_LIB.CREATE_MSG ('INV_STORE_CLASS', NULL, NULL, NULL);
         O_valid := FALSE;
         return TRUE;
      end if;
   end if;

   O_valid := TRUE;

   open  C_CHECK_STORE_CLASS_V;
   fetch C_CHECK_STORE_CLASS_V into L_store_class_desc;
   close C_CHECK_STORE_CLASS_V;
   ---
   O_store_class_desc := L_store_class_desc;

   if L_store_class_desc is NULL then
      ---
      open  C_CHECK_STORE_CLASS_TB;
      fetch C_CHECK_STORE_CLASS_TB into L_store_class_desc;
      close C_CHECK_STORE_CLASS_TB;
      ---
      if L_store_class_desc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('NO_STORES_EXIST_CLASS', I_store_class, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ANY_STORE_CLASS', I_store_class);
      end if;
      ---
      O_valid := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_STORE_CLASS;
---------------------------------------------------------------------------------------
-- VALIDATE_SHIPMENT()
---------------------------------------------------------------------------------------
FUNCTION VALIDATE_SHIPMENT(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                           O_valid           IN OUT  BOOLEAN,
                           O_shipment        IN OUT  V_SHIPMENT%ROWTYPE,
                           I_shipment        IN      SHIPMENT.SHIPMENT%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_SHIPMENT';
   L_from_loc  SHIPMENT.FROM_LOC%TYPE;
   L_to_loc    SHIPMENT.TO_LOC%TYPE;
   L_dummy     VARCHAR2(1);

   cursor C_CHECK_SHIPMENT_V is
      select *
        from v_shipment
       where shipment = I_shipment;

   cursor C_CHECK_SHIPMENT_TB is
      select from_loc, to_loc
        from shipment
       where shipment = I_shipment;

   cursor C_CHECK_FROM_LOC is
      select 'X'
        from shipment s
       where shipment = I_shipment
         and (  s.from_loc is NULL
             or s.from_loc in (select store
                                 from v_store
                                union all
                               select wh
                                 from v_wh
                               union all
                               select finisher_id
                                 from v_external_finisher
                               union all
                               select finisher_id
                                 from v_internal_finisher));

   cursor C_CHECK_TO_LOC is
      select 'X'
        from shipment s
       where shipment = I_shipment
         and s.to_loc in (select store
                              from v_store
                             union all
                            select wh
                              from v_wh
                             union all
                           select finisher_id
                             from v_external_finisher
                           union all
                           select finisher_id
                             from v_internal_finisher);

   cursor C_CHECK_ITEMS is
      select 'X'
        from shipsku ss,
             v_item_master vim
       where ss.shipment = I_shipment
         and vim.item = ss.item;

BEGIN

   if I_shipment is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_shipment',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   ---
   open C_CHECK_SHIPMENT_V;
   fetch C_CHECK_SHIPMENT_V into O_shipment;
   ---
   if C_CHECK_SHIPMENT_V%NOTFOUND then
      ---
      open C_CHECK_SHIPMENT_TB;
      fetch C_CHECK_SHIPMENT_TB into L_from_loc, L_to_loc;
      ---
      if C_CHECK_SHIPMENT_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_SHIP', NULL, NULL, NULL);
      else
         open C_CHECK_FROM_LOC;
         fetch C_CHECK_FROM_LOC into L_dummy;
         ---
         if C_CHECK_FROM_LOC%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_LOC_SHIP',L_from_loc, I_shipment);
         else
            open C_CHECK_TO_LOC;
            fetch C_CHECK_TO_LOC into L_dummy;
            ---
            if C_CHECK_TO_LOC%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_LOC_SHIP', L_to_loc, I_shipment);
            else
               O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ANY_ITEM_SHIP', I_shipment);
            end if;
         end if;
      end if;
      ---
      close C_CHECK_SHIPMENT_TB;
      O_valid := FALSE;
      ---
   else
      O_valid := TRUE;
   end if;
   ---
   close C_CHECK_SHIPMENT_V;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_SHIPMENT;
----------------------------------------------------------------------------
FUNCTION VALIDATE_ORDER(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                        O_valid          IN OUT  BOOLEAN,
                        O_ordhead        IN OUT  V_ORDHEAD%ROWTYPE,
                        I_order_no       IN      ORDHEAD.ORDER_NO%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(50)       := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_ORDER';

   cursor C_CHECK_ORDER_TB is
      select *
        from ordhead
       where order_no = I_order_no;

   cursor C_CHECK_ORDER_V is
      select *
        from v_ordhead
       where order_no = I_order_no;

BEGIN

   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_order_no,L_program,NULL);
      return FALSE;
   end if;

   O_valid := TRUE;

   open  C_CHECK_ORDER_V;
   fetch C_CHECK_ORDER_V into O_ordhead;
   ---
   if C_CHECK_ORDER_V%NOTFOUND then
      ---
      open  C_CHECK_ORDER_TB;
      fetch C_CHECK_ORDER_TB into O_ordhead;
      ---
      if C_CHECK_ORDER_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_ORDER_SEARCH', I_order_no);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY_ORDER', I_order_no, NULL);
      end if;
      ---
      O_valid := FALSE;
      close C_CHECK_ORDER_TB;
   end if;
 close C_CHECK_ORDER_V;
 return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_ORDER;
----------------------------------------------------------------------------
FUNCTION VALIDATE_RTV_ORDER_NO(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               O_valid          IN OUT  BOOLEAN,
                               O_rtv_head_row   IN OUT  V_RTV_HEAD%ROWTYPE,
                               I_rtv_order_no   IN      RTV_HEAD.RTV_ORDER_NO%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'FILTER_LOV_VALIDATE_SQL.EXISTS_ON_VIEW';
   L_rtv_order_no  RTV_HEAD.RTV_ORDER_NO%TYPE;

   cursor C_RTV_HEAD_V is
      select *
        from v_rtv_head
       where rtv_order_no = I_rtv_order_no;

   cursor C_RTV_HEAD_TB is
      select rtv_order_no
        from rtv_head
       where rtv_order_no = I_rtv_order_no;

BEGIN

   if I_rtv_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM_IN_FUNC', 'I_rtv_order_no', 'NULL', L_program);
      return FALSE;
   end if;

   O_rtv_head_row := NULL;
   O_valid        := TRUE;

   open  C_RTV_HEAD_V;
   fetch C_RTV_HEAD_V into O_rtv_head_row;
   close C_RTV_HEAD_V;
   ---
   if O_rtv_head_row.rtv_order_no is NULL then
      open  C_RTV_HEAD_TB;
      fetch C_RTV_HEAD_TB into L_rtv_order_no;
      close C_RTV_HEAD_TB;
      ---
      if L_rtv_order_no is NULL then
         O_error_message := sql_lib.create_msg('INV_RTV', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY_RTV', I_rtv_order_no, NULL);
      end if;
      O_valid := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;
END VALIDATE_RTV_ORDER_NO;
----------------------------------------------------------------------------------------------
FUNCTION VALIDATE_TSF_NO(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid         IN OUT BOOLEAN,
                         O_tsfhead_row   IN OUT V_TSFHEAD%ROWTYPE,
                         I_tsf_no        IN     V_TSFHEAD.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_TSF_NO';

   cursor C_TSFHEAD_V is
      select *
        from v_tsfhead
       where tsf_no = I_tsf_no;

   cursor C_TSFHEAD_TB is
      select tsf_no
        from tsfhead
       where tsf_no = I_tsf_no
         and (tsf_no = tsf_parent_no
              or tsf_parent_no is NULL);  --eliminates the tsf no for the second leg of transfers with finishing

BEGIN

   if I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open C_TSFHEAD_V;
   fetch C_TSFHEAD_V into O_tsfhead_row;
   if C_TSFHEAD_V%NOTFOUND then
      open C_TSFHEAD_TB;
      fetch C_TSFHEAD_TB into O_tsfhead_row.tsf_no;
      if C_TSFHEAD_TB%FOUND then
         O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY_TSF', I_tsf_no, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('INV_TSF', NULL, NULL, NULL);
      end if;
      close C_TSFHEAD_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_tsfhead_row.comment_desc,
                                O_tsfhead_row.comment_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_TSFHEAD_V;
   return TRUE;

EXCEPTION
   when OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALIDATE_TSF_NO;
----------------------------------------------------------------------------------------------
FUNCTION VALIDATE_PACK_TMPL_HEAD(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_valid          IN OUT BOOLEAN,
                                 O_pack_tmpl_head IN OUT V_PACK_TMPL_HEAD%ROWTYPE,
                                 I_pack_tmpl_id   IN     V_PACK_TMPL_HEAD.PACK_TMPL_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_PACK_TMPL_HEAD';

   cursor C_CHECK_PACK_TMPL_HEAD_TB is
      select pack_tmpl_desc
        from pack_tmpl_head
       where pack_tmpl_id = I_pack_tmpl_id;

   cursor C_CHECK_PACK_TMPL_HEAD_V is
      select *
        from v_pack_tmpl_head
       where pack_tmpl_id = I_pack_tmpl_id;

BEGIN

   if I_pack_tmpl_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_pack_tmpl_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open C_CHECK_PACK_TMPL_HEAD_V;
   fetch C_CHECK_PACK_TMPL_HEAD_V into O_pack_tmpl_head;
   if C_CHECK_PACK_TMPL_HEAD_V%NOTFOUND then
      open C_CHECK_PACK_TMPL_HEAD_TB;
      fetch C_CHECK_PACK_TMPL_HEAD_TB into O_pack_tmpl_head.pack_tmpl_desc;

      if C_CHECK_PACK_TMPL_HEAD_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('PACK_TMPL_NOT_EXIST', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY_PACK_TMPL', I_pack_tmpl_id, NULL);
      end if;

      close C_CHECK_PACK_TMPL_HEAD_TB;

      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_pack_tmpl_head.pack_tmpl_desc,
                                O_pack_tmpl_head.pack_tmpl_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_CHECK_PACK_TMPL_HEAD_V;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_PACK_TMPL_HEAD;
----------------------------------------------------------------------------------------------
FUNCTION VALIDATE_DIFF_RATIO_ID(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_valid           IN OUT BOOLEAN,
                                O_diff_ratio_head IN OUT V_DIFF_RATIO_HEAD%ROWTYPE,
                                I_diff_ratio_id   IN     V_DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_DIFF_RATIO_ID';
   L_dept      DIFF_RATIO_HEAD.DEPT%TYPE;

   cursor C_DIFF_RATIO_HEAD_TB is
      select description, dept
        from diff_ratio_head
       where diff_ratio_id = I_diff_ratio_id;

   cursor C_DIFF_RATIO_HEAD_V is
      select *
        from v_diff_ratio_head
       where diff_ratio_id = I_diff_ratio_id;

BEGIN

   if I_diff_ratio_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_diff_ratio_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open C_DIFF_RATIO_HEAD_V;
   fetch C_DIFF_RATIO_HEAD_V into O_diff_ratio_head;
   if C_DIFF_RATIO_HEAD_V%NOTFOUND then
      open C_DIFF_RATIO_HEAD_TB;
      fetch C_DIFF_RATIO_HEAD_TB into O_diff_ratio_head.description, L_dept;
      if C_DIFF_RATIO_HEAD_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_DIFF_RATIO', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_DIFF_RATIO', I_diff_ratio_id);
      end if;
      close C_DIFF_RATIO_HEAD_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_diff_ratio_head.description,
                                O_diff_ratio_head.description,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_DIFF_RATIO_HEAD_V;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_DIFF_RATIO_ID;
----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------
FUNCTION VALIDATE_TSF_ZONE (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_valid         IN OUT BOOLEAN,
                            O_tsf_desc      IN OUT TSFZONE.DESCRIPTION%TYPE,
                            I_tsf_zone      IN     TSFZONE.TRANSFER_ZONE%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_TSF_ZONE';

   cursor C_TSF_ZONE_V is
      select distinct t.description
        from tsfzone t,
             v_store v
       where t.transfer_zone = I_tsf_zone
         and t.transfer_zone = v.transfer_zone;

   cursor C_TSF_ZONE_TB is
      select description
        from tsfzone
       where transfer_zone = I_tsf_zone;

BEGIN

   if I_tsf_zone is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_zone',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open C_TSF_ZONE_V;
   fetch C_TSF_ZONE_V into O_tsf_desc;

   if C_TSF_ZONE_V%NOTFOUND then
      open C_TSF_ZONE_TB;
      fetch C_TSF_ZONE_TB into O_tsf_desc;
      if C_TSF_ZONE_TB%FOUND then
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ANY_TSF_ZONE', I_tsf_zone);
      else
         O_error_message := SQL_LIB.CREATE_MSG('INV_TRAN_ZONE', NULL, NULL, NULL);
      end if;
      close C_TSF_ZONE_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_tsf_desc,
                                O_tsf_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_TSF_ZONE_V;
   return TRUE;

EXCEPTION
   when OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALIDATE_TSF_ZONE;
----------------------------------------------------------------------------------------------
FUNCTION VALIDATE_PRICE_ZONE_ID(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_valid         IN OUT BOOLEAN,
                                O_price_desc    IN OUT PRICE_ZONE.DESCRIPTION%TYPE,
                                I_price_zone_id IN     PRICE_ZONE.ZONE_ID%TYPE,
                                I_zone_group_id IN     PRICE_ZONE_GROUP.ZONE_GROUP_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_PRICE_ZONE_ID';

   cursor C_PRICE_ZONE_ID_V is
      select distinct p.description
        from price_zone p,
             price_zone_group_store s,
             v_store v
       where p.zone_id = I_price_zone_id
         and p.zone_group_id = NVL(I_zone_group_id, p.zone_group_id)
         and p.zone_group_id = s.zone_group_id
         and p.zone_id = s.zone_id
         and s.store = v.store;

   cursor C_PRICE_ZONE_ID_TB is
      select distinct p.description
        from price_zone p
       where p.zone_id = I_price_zone_id
         and p.zone_group_id = NVL(I_zone_group_id, p.zone_group_id);

BEGIN

   if I_price_zone_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_price_zone_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   O_price_desc := NULL;

   open  C_PRICE_ZONE_ID_V;
   fetch C_PRICE_ZONE_ID_V into O_price_desc;
   close C_PRICE_ZONE_ID_V;

   if O_price_desc is NULL then
      ---
      open  C_PRICE_ZONE_ID_TB;
      fetch C_PRICE_ZONE_ID_TB into O_price_desc;
      close C_PRICE_ZONE_ID_TB;
      ---
      if O_price_desc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_PRICE_ZONE', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ANY_PRICE_ZONE', I_price_zone_id);
      end if;
      ---
      O_valid := FALSE;
      ---
   else
      ---
      if LANGUAGE_SQL.TRANSLATE(O_price_desc,
                                O_price_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      ---
      O_valid := TRUE;
      ---
   end if;

   return TRUE;

EXCEPTION
   when OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALIDATE_PRICE_ZONE_ID;
--------------------------------------------------------------------------------
-- VALIDATE_INTERNAL_FINISHER( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_INTERNAL_FINISHER(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    O_valid            IN OUT BOOLEAN,
                                    O_finisher_desc    IN OUT V_INTERNAL_FINISHER.FINISHER_DESC%TYPE,
                                    IO_tsf_entity_id   IN OUT V_INTERNAL_FINISHER.TSF_ENTITY_ID%TYPE,
                                    I_finisher         IN     V_INTERNAL_FINISHER.FINISHER_ID%TYPE)

RETURN BOOLEAN IS

   L_tsf_entity_id      STORE.TSF_ENTITY_ID%TYPE;
   L_program            VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_INT_FINISHER';

   cursor C_CHECK_FINISHER_TB is
      select wh_name
        from wh
       where wh = I_finisher
         and finisher_ind = 'Y';

   cursor C_CHECK_FINISHER_V is
      select finisher_desc,
             tsf_entity_id
        from v_internal_finisher
       where finisher_id = I_finisher;

BEGIN

   if I_finisher is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             I_finisher,
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open C_CHECK_FINISHER_V;
   fetch C_CHECK_FINISHER_V into O_finisher_desc,
                                 L_tsf_entity_id;

   if C_CHECK_FINISHER_V%NOTFOUND then
      open C_CHECK_FINISHER_TB;
      fetch C_CHECK_FINISHER_TB into O_finisher_desc;
      if C_CHECK_FINISHER_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_INT_FINISHER', NULL, NULL, NULL);
      else
        O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_LOC', I_finisher, NULL);
      end if;
      close C_CHECK_FINISHER_TB;
      O_valid := FALSE;
    else
      if IO_tsf_entity_id is not NULL and
        (L_tsf_entity_id is NULL or L_tsf_entity_id != IO_tsf_entity_id) then
            O_error_message:= SQL_LIB.CREATE_MSG('FIN_NOTIN_TSF_ENT', I_finisher, IO_tsf_entity_id, NULL);
            O_valid := FALSE;
      else
         IO_tsf_entity_id := L_tsf_entity_id;
            if LANGUAGE_SQL.TRANSLATE(O_finisher_desc,
                                      O_finisher_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
            O_valid := TRUE;
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

END VALIDATE_INTERNAL_FINISHER;
--------------------------------------------------------------------------------
-- VALIDATE_EXTERNAL_FINISHER( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_EXTERNAL_FINISHER(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    O_valid            IN OUT BOOLEAN,
                                    O_finisher_desc    IN OUT V_EXTERNAL_FINISHER.FINISHER_DESC%TYPE,
                                    IO_tsf_entity_id   IN OUT V_EXTERNAL_FINISHER.TSF_ENTITY_ID%TYPE,
                                    I_finisher         IN     V_EXTERNAL_FINISHER.FINISHER_ID%TYPE)

RETURN BOOLEAN IS

   L_tsf_entity_id      V_EXTERNAL_FINISHER.TSF_ENTITY_ID%TYPE;
   L_program            VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_EXTERNAL_FINISHER';

   cursor C_CHECK_FINISHER_TB is
      select partner_desc
        from partner
       where partner_id = I_finisher
         and partner_type = 'E';

   cursor C_CHECK_FINISHER_V is
      select finisher_desc,
             tsf_entity_id
        from v_external_finisher
       where finisher_id = I_finisher;

BEGIN

   if I_finisher is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             I_finisher,
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open C_CHECK_FINISHER_V;
   fetch C_CHECK_FINISHER_V into O_finisher_desc,
                                 L_tsf_entity_id;

   if C_CHECK_FINISHER_V%NOTFOUND then
      open C_CHECK_FINISHER_TB;
      fetch C_CHECK_FINISHER_TB into O_finisher_desc;
      if C_CHECK_FINISHER_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_EXT_FINISHER', NULL, NULL, NULL);
      else
        O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_LOC', I_finisher, NULL);
      end if;
      close C_CHECK_FINISHER_TB;
      O_valid := FALSE;
   else
      if  IO_tsf_entity_id is not NULL
      and (L_tsf_entity_id is NULL or L_tsf_entity_id != IO_tsf_entity_id) then
         O_error_message:= SQL_LIB.CREATE_MSG('FIN_NOTIN_TSF_ENT', I_finisher, IO_tsf_entity_id, NULL);
         O_valid := FALSE;
      else
         IO_tsf_entity_id := L_tsf_entity_id;
         if LANGUAGE_SQL.TRANSLATE(O_finisher_desc,
                                   O_finisher_desc,
                                   O_error_message) = FALSE then
            return FALSE;
         end if;
         O_valid := TRUE;
       end if;
   end if;

   close C_CHECK_FINISHER_V;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_EXTERNAL_FINISHER;
--------------------------------------------------------------------------------
-- VALIDATE_TSF_ENTITY( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_TSF_ENTITY(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_valid           IN OUT BOOLEAN,
                             O_tsf_entity_row  IN OUT V_TSF_ENTITY%ROWTYPE,
                             I_tsf_entity_id   IN     V_TSF_ENTITY.TSF_ENTITY_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(50)  := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_TSF_ENTITY';

   cursor C_CHECK_TSF_ENTITY_V is
      select vte.*
        from v_tsf_entity vte
       where vte.tsf_entity_id = I_tsf_entity_id;

   cursor C_CHECK_TSF_ENTITY_TB is
      select tsf_entity_desc
        from tsf_entity
       where tsf_entity_id = I_tsf_entity_id;

BEGIN

   if I_tsf_entity_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_entity_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open C_CHECK_TSF_ENTITY_V;
   fetch C_CHECK_TSF_ENTITY_V into O_tsf_entity_row;
   if C_CHECK_TSF_ENTITY_V%NOTFOUND then
      open C_CHECK_TSF_ENTITY_TB;
      fetch C_CHECK_TSF_ENTITY_TB into O_tsf_entity_row.tsf_entity_desc;
      if C_CHECK_TSF_ENTITY_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_ENTITY', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_TSF_ENT', I_tsf_entity_id, NULL);
      end if;
      close C_CHECK_TSF_ENTITY_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_tsf_entity_row.tsf_entity_desc,
                                O_tsf_entity_row.tsf_entity_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;

   close C_CHECK_TSF_ENTITY_V;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             NULL);
RETURN FALSE;

END VALIDATE_TSF_ENTITY;
-------------------------------------------------------------------------------------
FUNCTION VALIDATE_SHIP_ORDER(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                             O_valid          IN OUT  BOOLEAN,
                             O_ordhead        IN OUT  ORDHEAD.ORDER_NO%TYPE,
                             I_order_no       IN      ORDHEAD.ORDER_NO%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(50)       := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_SHIP_ORDER';

   cursor C_CHECK_SHIP_ORDER_TB is
      select order_no
        from ordhead
       where ordhead.status in ('A', 'C')
         and order_no = I_order_no;

   cursor C_CHECK_SHIP_ORDER_V is
      select distinct(ordhead.order_no)
        from ordhead,
             v_shipment,
             shipsku
       where v_shipment.order_no = I_order_no
         and ordhead.order_no = v_shipment.order_no
         and ordhead.status in ('A', 'C')
         and v_shipment.shipment = shipsku.shipment;

BEGIN

   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_order_no,L_program,NULL);
      return FALSE;
   end if;

   O_valid := TRUE;

   open  C_CHECK_SHIP_ORDER_V;
   fetch C_CHECK_SHIP_ORDER_V into O_ordhead;
   ---
   if C_CHECK_SHIP_ORDER_V%NOTFOUND then
      ---
      open  C_CHECK_SHIP_ORDER_TB;
      fetch C_CHECK_SHIP_ORDER_TB into O_ordhead;
      ---
      if C_CHECK_SHIP_ORDER_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_ORDER_SEARCH', I_order_no);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY_ORDER', I_order_no, NULL);
      end if;
      ---
      O_valid := FALSE;
      close C_CHECK_SHIP_ORDER_TB;
   end if;
 close C_CHECK_SHIP_ORDER_V;
 return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_SHIP_ORDER;

----------------------------------------------------------------------------
FUNCTION VALIDATE_CONTRACT(O_error_message    IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                           O_valid            IN OUT  BOOLEAN,
                           O_contract_header  IN OUT  V_CONTRACT_HEADER%ROWTYPE,
                           I_contract_no      IN      CONTRACT_HEADER.CONTRACT_NO%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(50)       := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_CONTRACT';
   cursor C_CHECK_CONTRACT_TB is
      select *
        from contract_header
       where contract_no = I_contract_no;

   cursor C_CHECK_CONTRACT_V is
      select *
        from v_contract_header
       where contract_no = I_contract_no;

BEGIN

   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_contract_no',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   O_valid := TRUE;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_CONTRACT_V',
                    'V_CONTRACT_HEADER',
                     NULL);
   open C_CHECK_CONTRACT_V;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_CONTRACT_V',
                    'V_CONTRACT_HEADER',
                     NULL);
   fetch C_CHECK_CONTRACT_V into O_contract_header;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_CONTRACT_V',
                    'V_CONTRACT_HEADER',
                     NULL);
   close C_CHECK_CONTRACT_V;
   if O_contract_header.contract_no is NULL then
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_CONTRACT_TB',
                       'CONTRACT_HEADER',
                       NULL);
      open C_CHECK_CONTRACT_TB;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_CONTRACT_TB',
                       'CONTRACT_HEADER',
                       NULL);
      fetch C_CHECK_CONTRACT_TB into O_contract_header;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_CONTRACT_TB',
                       'CONTRACT_HEADER',
                       NULL);
      close C_CHECK_CONTRACT_TB;
      ---
      if O_contract_header.contract_no is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_CONTRACT_SEARCH', I_contract_no);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY_CONTRACT', I_contract_no, NULL);
      end if;
      ---
      O_valid := FALSE;
      ---
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_CONTRACT;

----------------------------------------------------------------------------
FUNCTION VALIDATE_COUPON_ID (O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                             O_valid          IN OUT  BOOLEAN,
                             I_coupon_id      IN      POS_COUPON_HEAD.COUPON_ID%TYPE)
RETURN BOOLEAN IS

   L_program                    VARCHAR2(100) := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_COUPON_ID';
   L_dummy                      VARCHAR2(1);
   L_hier                       VARCHAR2(128);
   L_filter_org_id              FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE;
   L_filter_org_level           FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE;
   L_filter_merch_id            FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE;
   L_filter_merch_level         FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE;
   L_filter_merch_id_class      FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE;
   L_filter_merch_id_subclass   FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE;


   cursor C_CHECK_POS_COUPON_TB is
      select 'x'
        from pos_coupon_head
       where coupon_id = I_coupon_id;

   cursor C_CHECK_POS_COUPON_V is
      select 'x'
        from v_pos_coupon_head
       where coupon_id = I_coupon_id;

   cursor C_CHECK_FILTER_ORG is
      select b.filter_org_id,
             b.filter_org_level
        from filter_group_org b,
             sec_user_group a
       where a.group_id = b.sec_group_id
         AND a.user_id = user;

   cursor C_CHECK_FILTER_MERCH is
      select b.filter_merch_id,
             b.filter_merch_level,
             b.filter_merch_id_class,
             b.filter_merch_id_subclass
        from filter_group_merch b,
             sec_user_group a
       where a.group_id = b.sec_group_id
         AND a.user_id = user;

BEGIN

   if I_coupon_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_coupon_id,L_program,NULL);
      return FALSE;
   end if;

   O_valid := TRUE;

   open C_CHECK_POS_COUPON_V;
   fetch C_CHECK_POS_COUPON_V into L_dummy;
   ---
   if C_CHECK_POS_COUPON_V%NOTFOUND then
      ---O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ANY_COUPON', I_coupon_id);
      open C_CHECK_POS_COUPON_TB;
      fetch C_CHECK_POS_COUPON_TB into L_dummy;
      ---
      if C_CHECK_POS_COUPON_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('POS_INV_COUPON');
         return FALSE;
      else
         ---
         open C_CHECK_FILTER_ORG;
         fetch C_CHECK_FILTER_ORG into L_filter_org_id,
                                       L_filter_org_level;
         close C_CHECK_FILTER_ORG;
         ---
         open C_CHECK_FILTER_MERCH;
         fetch C_CHECK_FILTER_MERCH into L_filter_merch_id,
                                         L_filter_merch_level,
                                         L_filter_merch_id_class,
                                         L_filter_merch_id_subclass;
         close C_CHECK_FILTER_MERCH;
         ---
         if GET_NON_VISIBLE_HIER(O_error_message,
                                 L_hier,
                                 L_filter_org_id,
                                 L_filter_org_level,
                                 L_filter_merch_id,
                                 L_filter_merch_level,
                                 L_filter_merch_id_class,
                                 L_filter_merch_id_subclass) = FALSE then
            return FALSE;
         end if;
         ---
         if L_hier IS NOT NULL then
            O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY', L_hier, I_coupon_id);
         else
            O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ANY_COUPON', I_coupon_id);
         end if;
         ---
         O_valid := FALSE;
      end if;   -- c_check_coupon_merch found
   end if;
   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;
END VALIDATE_COUPON_ID;

----------------------------------------------------------------------------
FUNCTION VALIDATE_CE_ID (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid           IN OUT   BOOLEAN,
                         O_ce_head         IN OUT   CE_HEAD%ROWTYPE,
                         I_ce_id           IN       CE_HEAD.CE_ID%TYPE)
RETURN BOOLEAN IS
   L_program                    VARCHAR2(50)  := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_CE_ID';
   L_hier                       VARCHAR2(128);
   L_filter_org_id              FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE;
   L_filter_org_level           FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE;
   L_filter_merch_id            FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE;
   L_filter_merch_level         FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE;
   L_filter_merch_id_class      FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE;
   L_filter_merch_id_subclass   FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE;
   L_found                      BOOLEAN;

   cursor   C_CEH
       is
   select   ceh.*
     from   ce_head   ceh
    where   ceh.ce_id = I_ce_id;

   cursor C_CHECK_CE_V is
      select *
        from v_ce_head
       where ce_id = I_ce_id;

   cursor C_CHECK_FILTER_ORG is
      select b.filter_org_id,
             b.filter_org_level
        from filter_group_org b,
             sec_user_group a
       where a.group_id = b.sec_group_id
         and a.user_id = USER;

   cursor C_CHECK_FILTER_MERCH is
      select b.filter_merch_id,
             b.filter_merch_level,
             b.filter_merch_id_class,
             b.filter_merch_id_subclass
        from filter_group_merch b,
             sec_user_group a
       where a.group_id = b.sec_group_id
         and a.user_id = USER;


BEGIN
   if I_ce_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_ce_id,L_program,NULL);
      return FALSE;
   end if;
   ---
   O_valid := TRUE;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CEH',
                    'CE_HEAD',
                    'I_ce_id='||I_ce_id);

   open C_CEH;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CEH',
                    'CE_HEAD',
                    'I_ce_id='||I_ce_id);

   fetch C_CEH
    into O_ce_head;

   L_found := C_CEH%FOUND;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CEH',
                    'CE_HEAD',
                    'I_ce_id='||I_ce_id);

   close C_CEH;

   if not L_found then
      O_error_message := SQL_LIB.CREATE_MSG('INV_CE_ID',
                                            I_ce_id);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_CE_V',
                    'V_CE_HEAD',
                    I_ce_id);
   open C_CHECK_CE_V;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_CE_V',
                    'V_CE_HEAD',
                    I_ce_id);
   fetch C_CHECK_CE_V into O_ce_head;
   ---
   if C_CHECK_CE_V%NOTFOUND then
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_FILTER_ORG',
                       'FILTER_GROUP_ORG',
                       NULL);
      open C_CHECK_FILTER_ORG;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_FILTER_ORG',
                       'FILTER_GROUP_ORG',
                       NULL);
      fetch C_CHECK_FILTER_ORG into L_filter_org_id,
                                    L_filter_org_level;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_FILTER_ORG',
                       'FILTER_GROUP_ORG',
                       NULL);
      close C_CHECK_FILTER_ORG;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_FILTER_MERCH',
                       'FILTER_GROUP_MERCH',
                        NULL);
      open C_CHECK_FILTER_MERCH;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_FILTER_MERCH',
                       'FILTER_GROUP_MERCH',
                       NULL);
      fetch C_CHECK_FILTER_MERCH into L_filter_merch_id,
                                      L_filter_merch_level,
                                      L_filter_merch_id_class,
                                      L_filter_merch_id_subclass;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_FILTER_MERCH',
                       'FILTER_GROUP_MERCH',
                        NULL);
      close C_CHECK_FILTER_MERCH;
      ---
      if NOT GET_NON_VISIBLE_HIER(O_error_message,
                                  L_hier,
                                  L_filter_org_id,
                                  L_filter_org_level,
                                  L_filter_merch_id,
                                  L_filter_merch_level,
                                  L_filter_merch_id_class,
                                  L_filter_merch_id_subclass) then
         return FALSE;
      end if;
      ---
      if L_hier is NOT NULL then
         O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY', L_hier, I_ce_id);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ANY_CE_ID', I_ce_id);
      end if;
      ---
      O_valid := FALSE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_CE_V',
                       'CE_HEAD',
                       I_ce_id);
      close C_CHECK_CE_V;

   end if;

   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;
END VALIDATE_CE_ID;

--------------------------------------------------------------------------------
FUNCTION MANUAL_LOC_TRAITS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_valid           IN OUT   BOOLEAN,
                           O_description     IN OUT   V_LOC_TRAITS.DESCRIPTION%TYPE,
                           I_loc_trait       IN       V_LOC_TRAITS.LOC_TRAIT%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64)                    := 'FILTER_LOV_VALIDATE_SQL.MANUAL_LOC_TRAITS';
   L_exists     VARCHAR2(1);
   L_org_code   VARCHAR2(4);
   L_org_id     LOC_TRAITS.FILTER_ORG_ID%TYPE   := NULL;

   cursor C_CHECK_LOC_TRAIT_TB is
      select description,
             filter_org_id
        from loc_traits
       where loc_trait = I_loc_trait;

   cursor C_CHECK_LOC_TRAIT_V is
      select description
        from v_loc_traits
       where loc_trait = I_loc_trait;

   cursor C_CHECK_LOC_TRAITS_MATRIX is
      select 'X'
        from loc_traits_matrix l,
             v_store s
       where l.loc_trait = I_loc_trait
         and l.store     = s.store
         and rownum      = 1;

BEGIN
   if I_loc_trait is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_loc_trait,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   O_description := NULL;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_LOC_TRAIT_V',
                    'v_loc_traits',
                    'loc_trait: ' ||  to_char(I_loc_trait));
   open C_CHECK_LOC_TRAIT_V;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_LOC_TRAIT_V',
                    'v_loc_traits',
                    'loc_trait: ' ||  to_char(I_loc_trait));
   fetch C_CHECK_LOC_TRAIT_V into O_description;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_LOC_TRAIT_V',
                    'v_loc_traits',
                    'loc_trait: ' ||  to_char(I_loc_trait));
   close C_CHECK_LOC_TRAIT_V;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_LOC_TRAITS_MATRIX',
                    'loc_traits_matrix, v_store',
                    'loc_trait: ' ||  to_char(I_loc_trait));
   open C_CHECK_LOC_TRAITS_MATRIX;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_LOC_TRAITS_MATRIX',
                    'loc_traits_matrix, v_store',
                    'loc_trait: ' ||  to_char(I_loc_trait));
   fetch C_CHECK_LOC_TRAITS_MATRIX into L_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_LOC_TRAITS_MATRIX',
                    'loc_traits_matrix, v_store',
                    'loc_trait: ' ||  to_char(I_loc_trait));
   close C_CHECK_LOC_TRAITS_MATRIX;

   if O_description is NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_LOC_TRAIT_TB',
                       'loc_traits',
                       'loc_trait: ' ||  to_char(I_loc_trait));
      open C_CHECK_LOC_TRAIT_TB;

      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_LOC_TRAIT_TB',
                       'loc_traits',
                       'loc_trait: ' ||  to_char(I_loc_trait));
      fetch C_CHECK_LOC_TRAIT_TB into O_description, L_org_id;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_LOC_TRAIT_TB',
                       'loc_traits',
                       'loc_trait: ' ||  to_char(I_loc_trait));
      close C_CHECK_LOC_TRAIT_TB;

      if O_description is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_LOC_TRAIT',
                                               NULL,
                                               NULL,
                                               NULL);
      else
         if GET_ORG_DYNAMIC_CODE(O_error_message,
                                 L_org_code,
                                 FILTER_POLICY_SQL.GP_loc_trait_org_level) = FALSE then
            return FALSE;
         end if;
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_FUNC_LOC_TRAIT',
                                               L_org_code ||' '|| TO_CHAR(L_org_id),
                                               I_loc_trait,
                                               NULL);
      end if;
      O_valid := FALSE;
   elsif L_exists is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ALL_LOCS_LT',
                                            I_loc_trait,
                                            NULL,
                                            NULL);
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_description,
                                O_description,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END MANUAL_LOC_TRAITS;

----------------------------------------------------------------------------
FUNCTION VALIDATE_MRT_NO(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid_mrt      IN OUT  BOOLEAN,
                         O_mrt_row        IN OUT  V_MRT_ITEM%ROWTYPE,
                         I_mrt_no         IN      MRT.MRT_NO%TYPE)
RETURN BOOLEAN
 IS

   L_program      VARCHAR2(50)       := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_MRT_NO';

   cursor C_CHECK_MRT_NO is
      select *
        from v_mrt_item
       where mrt_no = I_mrt_no;

   L_dummy   VARCHAR2(1);

BEGIN

   if I_mrt_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_mrt_no,L_program,NULL);
      return FALSE;
   end if;

   open  C_CHECK_MRT_NO;
   fetch C_CHECK_MRT_NO into O_mrt_row;
   O_valid_mrt := C_CHECK_MRT_NO%FOUND;
   close C_CHECK_MRT_NO;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_MRT_NO;

----------------------------------------------------------------------------
FUNCTION MANUAL_COMP_STORE(O_error_message   IN OUT   VARCHAR2,
                           O_valid           IN OUT   BOOLEAN,
                           O_store_name      IN OUT   V_COMP_STORE.STORE_NAME%TYPE,
                           O_competitor      IN OUT   COMPETITOR.COMPETITOR%TYPE,
                           O_comp_name       IN OUT   COMPETITOR.COMP_NAME%TYPE,
                           O_currency        IN OUT   V_COMP_STORE.CURRENCY_CODE%TYPE,
                           I_comp_store      IN       V_COMP_STORE.STORE%TYPE)
   RETURN BOOLEAN IS

   L_competitor  competitor.competitor%TYPE := O_competitor;
   L_comp_name   competitor.comp_name%TYPE  := O_comp_name;

   cursor C_STORE is
      select cs.store_name
        from comp_store cs,
             competitor c
       where c.competitor = cs.competitor
         and cs.store = I_comp_store;
   cursor C_STORE_V is
      select cs.store_name,
             cs.competitor,
             c.comp_name,
             cs.currency_code
        from v_comp_store cs,
             competitor c
       where c.competitor = cs.competitor
         and cs.store = I_comp_store;

BEGIN

   if I_comp_store is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM',
                                           'I_COMP_STORE',
                                           'NULL',
                                           'NOT NULL');
      RETURN FALSE;
   end if;

   --select from v_comp_store
   SQL_LIB.SET_MARK('OPEN',
                    'C_STORE_V',
                    'V_COMP_STORE',
                    'V_COMP_STORE: '|| I_comp_store);
   open C_STORE_V;

   SQL_LIB.SET_MARK('FETCH',
                    'C_STORE_V',
                    'V_COMP_STORE',
                    'V_COMP_STORE: '|| I_comp_store);
   fetch C_STORE_V into O_store_name,
                        O_competitor,
                        O_comp_name,
                        O_currency;
   --

   if C_STORE_V%NOTFOUND then

      --select from comp_store
      SQL_LIB.SET_MARK('OPEN',
                       'C_STORE',
                       'COMP_STORE',
                       'COMP_STORE: '|| I_comp_store);
      open C_STORE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_STORE',
                       'COMP_STORE',
                       'COMP_STORE: '|| I_comp_store);
      fetch C_STORE into O_store_name;
      --
      if C_STORE%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_COMP_STORE', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_LOC', I_comp_store, NULL);
      end if;
      --
      SQL_LIB.SET_MARK('CLOSE',
                       'C_STORE',
                       'COMP_STORE',
                       'COMP_STORE: '|| I_comp_store);
      close C_STORE;

      O_valid := FALSE;

   else
      SQL_LIB.SET_MARK('CLOSE',
                       'C_STORE_V',
                       'V_COMP_STORE',
                       'V_COMP_STORE: '|| I_comp_store);
      O_valid := TRUE;
      close C_STORE_V;

      if L_competitor is NOT NULL then
         if L_competitor != O_competitor then
            O_competitor := L_competitor;
            O_comp_name  := L_comp_name;

            --- Invalid competitor/competitor store combination ---
            O_error_message:= SQL_LIB.CREATE_MSG('INVALID_COMP_LINK',
                                                 NULL,
                                                 NULL,
                                                 NULL);
            return FALSE;
         end if;
      end if;

      if LANGUAGE_SQL.TRANSLATE(O_store_name,
                                O_store_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;

      if LANGUAGE_SQL.TRANSLATE(O_comp_name,
                                O_comp_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;

   end if;

   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'FILTER_LOV_VALIDATE_SQL.MANUAL_COMP_STORE',
                                             TO_CHAR(SQLCODE));
   RETURN FALSE;
END MANUAL_COMP_STORE;
----------------------------------------------------------------------------
FUNCTION VALIDATE_MRT_ITEM(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid_mrt      IN OUT  BOOLEAN,
                         O_mrt_row        IN OUT  V_MRT_ITEM%ROWTYPE,
                         I_mrt_no         IN      V_MRT_ITEM.MRT_NO%TYPE ,
                         I_item           IN      V_MRT_ITEM.ITEM%TYPE )
RETURN BOOLEAN
 IS

   L_program      VARCHAR2(50)       := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_MRT_ITEM';

   cursor C_CHECK_MRT_ITEM is
      select *
        from v_mrt_item
       where mrt_no = I_mrt_no
         and item   = I_item ;

   L_dummy   VARCHAR2(1);

BEGIN

   if I_mrt_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_mrt_no,L_program,NULL);
      return FALSE;
   end if;

   open  C_CHECK_MRT_ITEM;
   fetch C_CHECK_MRT_ITEM into O_mrt_row;
   O_valid_mrt := C_CHECK_MRT_ITEM%FOUND;
   close C_CHECK_MRT_ITEM;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_MRT_ITEM;
----------------------------------------------------------------------------
FUNCTION VALIDATE_MRT(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      O_valid_mrt      IN OUT  BOOLEAN,
                      I_mrt_no         IN      V_MRT_ITEM.MRT_NO%TYPE)
RETURN BOOLEAN
 IS

   L_program      VARCHAR2(50)       := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_MRT';
   L_dummy        VARCHAR2(1);

   cursor C_CHECK_MRT is
      select 'Y'
        from mrt m,
             v_mrt_item_loc vm,
             v_wh vwh,
             v_mrt_item vmi
       where m.mrt_no = I_mrt_no
         and m.mrt_status in ('A','C','R')
         and m.mrt_no  = vm.mrt_no
         and vwh.wh = m.wh
         and vmi.item = vm.item
         and vmi.mrt_no = vm.mrt_no
         and rownum = 1;

BEGIN

   if I_mrt_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_mrt_no,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_MRT',
                    'MRT, V_MRT_ITEM_LOC, V_WH, V_MRT_ITEM',
                    'mrt_no: '|| I_mrt_no);
   open  C_CHECK_MRT;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_MRT',
                    'MRT, V_MRT_ITEM_LOC, V_WH, V_MRT_ITEM',
                    'mrt_no: '|| I_mrt_no);
   fetch C_CHECK_MRT into L_dummy;
   if L_dummy is NULL then
      O_valid_mrt := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_MRT',
                                             I_mrt_no,
                                             NULL,
                                             NULL);
   else
      O_valid_mrt := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_MRT',
                    'MRT, V_MRT_ITEM_LOC, V_WH, V_MRT_ITEM',
                    'mrt_no: '|| I_mrt_no);
   close C_CHECK_MRT;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_MRT;
----------------------------------------------------------------------------
FUNCTION VALIDATE_ENTRY_NO (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            O_valid           IN OUT   BOOLEAN,
                            O_ce_head         IN OUT   CE_HEAD%ROWTYPE,
                            I_entry_no        IN       CE_HEAD.ENTRY_NO%TYPE)
RETURN BOOLEAN IS
   L_program                    VARCHAR2(50)  := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_ENTRY_NO';
   L_hier                       VARCHAR2(128);
   L_filter_org_id              FILTER_GROUP_ORG.FILTER_ORG_ID%TYPE;
   L_filter_org_level           FILTER_GROUP_ORG.FILTER_ORG_LEVEL%TYPE;
   L_filter_merch_id            FILTER_GROUP_MERCH.FILTER_MERCH_ID%TYPE;
   L_filter_merch_level         FILTER_GROUP_MERCH.FILTER_MERCH_LEVEL%TYPE;
   L_filter_merch_id_class      FILTER_GROUP_MERCH.FILTER_MERCH_ID_CLASS%TYPE;
   L_filter_merch_id_subclass   FILTER_GROUP_MERCH.FILTER_MERCH_ID_SUBCLASS%TYPE;
   L_found                      BOOLEAN;

   cursor   C_CEH
       is
   select   ceh.*
     from   ce_head   ceh
    where   ceh.entry_no = I_entry_no;

   cursor C_CHECK_CE_V is
      select *
        from v_ce_head
       where entry_no = I_entry_no;

   cursor C_CHECK_FILTER_ORG is
      select b.filter_org_id,
             b.filter_org_level
        from filter_group_org b,
             sec_user_group a
       where a.group_id = b.sec_group_id
         and a.user_id = USER;

   cursor C_CHECK_FILTER_MERCH is
      select b.filter_merch_id,
             b.filter_merch_level,
             b.filter_merch_id_class,
             b.filter_merch_id_subclass
        from filter_group_merch b,
             sec_user_group a
       where a.group_id = b.sec_group_id
         and a.user_id = USER;


BEGIN
   if I_entry_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_entry_no,L_program,NULL);
      return FALSE;
   end if;
   ---
   O_valid := TRUE;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CEH',
                    'CE_HEAD',
                    'I_entry_no='||I_entry_no);

   open C_CEH;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CEH',
                    'CE_HEAD',
                    'I_entry_no='||I_entry_no);

   fetch C_CEH
    into O_ce_head;

   L_found := C_CEH%FOUND;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CEH',
                    'CE_HEAD',
                    'I_entry_no='||I_entry_no);

   close C_CEH;

   if not L_found then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ENTRY_NO',
                                            I_entry_no);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_CE_V',
                    'V_CE_HEAD',
                    I_entry_no);
   open C_CHECK_CE_V;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_CE_V',
                    'V_CE_HEAD',
                    I_entry_no);
   fetch C_CHECK_CE_V into O_ce_head;
   ---
   if C_CHECK_CE_V%NOTFOUND then
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_FILTER_ORG',
                       'FILTER_GROUP_ORG',
                       NULL);
      open C_CHECK_FILTER_ORG;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_FILTER_ORG',
                       'FILTER_GROUP_ORG',
                       NULL);
      fetch C_CHECK_FILTER_ORG into L_filter_org_id,
                                    L_filter_org_level;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_FILTER_ORG',
                       'FILTER_GROUP_ORG',
                       NULL);
      close C_CHECK_FILTER_ORG;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_FILTER_MERCH',
                       'FILTER_GROUP_MERCH',
                        NULL);
      open C_CHECK_FILTER_MERCH;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_FILTER_MERCH',
                       'FILTER_GROUP_MERCH',
                       NULL);
      fetch C_CHECK_FILTER_MERCH into L_filter_merch_id,
                                      L_filter_merch_level,
                                      L_filter_merch_id_class,
                                      L_filter_merch_id_subclass;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_FILTER_MERCH',
                       'FILTER_GROUP_MERCH',
                        NULL);
      close C_CHECK_FILTER_MERCH;
      ---
      if NOT GET_NON_VISIBLE_HIER(O_error_message,
                                  L_hier,
                                  L_filter_org_id,
                                  L_filter_org_level,
                                  L_filter_merch_id,
                                  L_filter_merch_level,
                                  L_filter_merch_id_class,
                                  L_filter_merch_id_subclass) then
         return FALSE;
      end if;
      ---
      if L_hier is NOT NULL then
         O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY', L_hier, I_entry_no);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_ANY_CE_ID', I_entry_no);
      end if;
      ---
      O_valid := FALSE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_CE_V',
                       'CE_HEAD',
                       I_entry_no);
      close C_CHECK_CE_V;

   end if;

   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;
END VALIDATE_ENTRY_NO;
----------------------------------------------------------------------------
FUNCTION VALIDATE_COST_CHANGE(O_error_message      IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                              O_valid              IN OUT  BOOLEAN,
                              I_cost_change        IN      COST_SUSP_SUP_DETAIL.COST_CHANGE%TYPE)
RETURN BOOLEAN
 IS

   L_program     VARCHAR2(50)  := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_COST_CHANGE';
   L_dummy       VARCHAR2(1);
   L_code_desc   CODE_DETAIL.CODE_DESC%TYPE;

   cursor C_CHECK_COST_CHANGE_VALID is
      select 'X'
        from cost_susp_sup_detail d
       where d.cost_change = I_cost_change
         and exists (select'X'
                       from v_item_master v
                      where v.item = d.item)
      union all
      select 'X'
        from cost_susp_sup_detail_loc dl
       where dl.cost_change = I_cost_change
         and exists (select'X'
                       from v_item_master v
                      where v.item = dl.item);

   cursor C_CHECK_COST_CHANGE_TB is
      select 'X'
        from cost_susp_sup_head
       where cost_change = I_cost_change;

BEGIN

   if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                 'PETP',
                                 'COST',
                                 L_code_desc) = FALSE then
      return FALSE;
   end if;

   if I_cost_change is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_cost_change', L_program, NULL);
      return FALSE;
   end if;

   open  C_CHECK_COST_CHANGE_VALID;
   fetch C_CHECK_COST_CHANGE_VALID into L_dummy;
   if L_dummy is NULL then
      open C_CHECK_COST_CHANGE_TB;
      fetch C_CHECK_COST_CHANGE_TB into L_dummy;
      if L_dummy is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_COST_CHANGE', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', L_code_desc, I_cost_change, NULL);
      end if;
      close C_CHECK_COST_CHANGE_TB;
      O_valid := FALSE;
   else
      O_valid := TRUE;
   end if;
   close C_CHECK_COST_CHANGE_VALID;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_COST_CHANGE;
--------------------------------------------------------------------------------
FUNCTION VALIDATE_TRANPO(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid          IN OUT  BOOLEAN,
                         I_order_no       IN      ORDHEAD.ORDER_NO%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(50)       := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_TRANPO';
   L_dummy        VARCHAR2(1);

   cursor C_CHECK_ORDER is
      select 'x'
        from ordhead
       where order_no = I_order_no;

   cursor C_CHECK_TRANPO is
      SELECT 'x'
        FROM code_detail    cdd,
             transportation trnp,
             v_ordhead      vohe,
             ordsku         osk
       WHERE cdd.code      = vohe.status
         AND cdd.code_type = 'ORST'
         AND vohe.order_no = I_order_no
         AND trnp.order_no = vohe.order_no
         AND vohe.status   = 'A'
         AND vohe.order_no = osk.order_no
         AND osk.item IS NOT NULL
         AND osk.order_no > 0;
BEGIN

   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_order_no,L_program,NULL);
      return FALSE;
   end if;

   O_valid := TRUE;

   open C_CHECK_ORDER;
   fetch C_CHECK_ORDER into L_dummy;
   ---
   if C_CHECK_ORDER%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ORDER_NO');
      O_valid := FALSE;
   else
      open  C_CHECK_TRANPO;
      fetch C_CHECK_TRANPO into L_dummy;
      ---
      if C_CHECK_TRANPO%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('NO_TRAN_ORD', I_order_no);
         O_valid := FALSE;
      end if;
      ---
      close C_CHECK_TRANPO;
   end if;
   ---
   close C_CHECK_ORDER;

 return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_TRANPO;
--------------------------------------------------------------------------------
-- VALIDATE_SEC_WH( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_SEC_WH(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid         IN OUT BOOLEAN,
                         O_wh            IN OUT V_SEC_WH%ROWTYPE,
                         I_wh            IN     V_WH.WH%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_SEC_WH';

   CURSOR C_CHECK_WH_TB IS
      SELECT wh_name, stockholding_ind
        FROM wh
       WHERE wh = I_wh
         AND finisher_ind = 'N';

   CURSOR C_CHECK_WH_V IS
      SELECT *
        FROM v_sec_wh
       WHERE wh = I_wh;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_WH_V',
                    'V_SEC_WH',
                     NULL);
   open C_CHECK_WH_V;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_WH_V',
                    'V_SEC_WH',
                     NULL);
   fetch C_CHECK_WH_V into O_wh;
   if C_CHECK_WH_V%NOTFOUND then
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_WH_TB',
                       'WH',
                        NULL);
      open C_CHECK_WH_TB;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_WH_TB',
                       'WH',
                        NULL);
      fetch C_CHECK_WH_TB into O_wh.wh_name, O_wh.stockholding_ind;
      if C_CHECK_WH_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_WH', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER_LOC', I_wh, NULL);
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_WH_TB',
                       'WH',
                        NULL);
      close C_CHECK_WH_TB;
      O_valid := FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE(O_wh.wh_name,
                                O_wh.wh_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      O_valid := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_WH_V',
                    'V_SEC_WH',
                     NULL);
   close C_CHECK_WH_V;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_SEC_WH;
--------------------------------------------------------------------------------
-- VALIDATE_SEC_ORDER( )
--------------------------------------------------------------------------------
FUNCTION VALIDATE_SEC_ORDER(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                            O_valid          IN OUT  BOOLEAN,
                            O_ordhead        IN OUT  V_ORDHEAD%ROWTYPE,
                            I_order_no       IN      ORDHEAD.ORDER_NO%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(50)       := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_SEC_ORDER';

   cursor C_CHECK_ORDER_TB is
      select *
        from ordhead
       where order_no = I_order_no;

   cursor C_CHECK_ORDER_V is
      select *
        from v_sec_ordhead
       where order_no = I_order_no;

BEGIN

   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',I_order_no,L_program,NULL);
      return FALSE;
   end if;

   O_valid := TRUE;

   open  C_CHECK_ORDER_V;
   fetch C_CHECK_ORDER_V into O_ordhead;
   ---
   if C_CHECK_ORDER_V%NOTFOUND then
      ---
      open  C_CHECK_ORDER_TB;
      fetch C_CHECK_ORDER_TB into O_ordhead;
      ---
      if C_CHECK_ORDER_TB%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_ORDER_SEARCH', I_order_no);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY_ORDER', I_order_no, NULL);
      end if;
      ---
      O_valid := FALSE;
      close C_CHECK_ORDER_TB;
   end if;
 close C_CHECK_ORDER_V;
 return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_SEC_ORDER;
--------------------------------------------------------------------------------
-- Mod N147, 14-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
-----------------------------------------------------------------------------------------------
-- Name   : VALIDATE_NON_MERCH_CODE
-- Purpose: To validate the non-merch code against the groups in table TSL_FILTER_GROUP_NON_MERCH
-----------------------------------------------------------------------------------------------
FUNCTION  TSL_VALIDATE_NON_MERCH_CODE(O_error_message   IN OUT NOCOPY RTK_ERRORS.RTK_TEXT%TYPE,
                                      O_valid           IN OUT NOCOPY VARCHAR2,
                                      O_non_merch_desc  IN OUT NOCOPY NON_MERCH_CODE_HEAD.NON_MERCH_CODE_DESC%TYPE,
                                      I_non_merch_code  IN            NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE)
   RETURN BOOLEAN IS
   L_program               VARCHAR2(64)                := 'FILTER_LOV_VALIDATE_SQL.VALIDATE_NON_MERCH_CODE';

   CURSOR C_CHECK_NON_MERCH_CODE is
   select nm.non_merch_code_desc
     from tsl_filter_group_non_merch tf,
          sec_user_group su,
          non_merch_code_head nm
    where su.group_id        = tf.sec_group_id
      and tf.non_merch_code  = nm.non_merch_code
      and nm.non_merch_code  = I_non_merch_code
      and su.user_id         = USER;

BEGIN
   if I_non_merch_code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_non_merch_code',
                                            L_program,
                                            'NULL');
      return FALSE;
   end if;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_NON_MERCH_CODE',
                    'NON_MERCH_CODE_HEAD',
                    'Non-Merch Code = ' ||I_non_merch_code);
   open C_CHECK_NON_MERCH_CODE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_NON_MERCH_CODE',
                    'NON_MERCH_CODE_HEAD',
                    'Non-Merch Code = ' ||I_non_merch_code);
   fetch C_CHECK_NON_MERCH_CODE into O_non_merch_desc;
   --
   if C_CHECK_NON_MERCH_CODE%NOTFOUND then
      O_valid := 'N';
   else
      O_valid := 'Y';
   end if;
   --
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_NON_MERCH_CODE',
                    'NON_MERCH_CODE_HEAD',
                    'Non-Merch Code = ' ||I_non_merch_code);
   close C_CHECK_NON_MERCH_CODE;
   --
   return TRUE;

EXCEPTION
   when OTHERS then
      --
      if C_CHECK_NON_MERCH_CODE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_NON_MERCH_CODE',
                          'NON_MERCH_CODE_HEAD',
                          'Non-Merch Code = ' ||I_non_merch_code);
         close C_CHECK_NON_MERCH_CODE;
      end if;
      --
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
      --
END TSL_VALIDATE_NON_MERCH_CODE;
-----------------------------------------------------------------------------------------------
-- Name   : TSL_VALIDATE_USER
-- Purpose: To validate the current user is whether Super user or Normal Use.
-----------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_USER(O_error_message   IN OUT NOCOPY RTK_ERRORS.RTK_TEXT%TYPE,
                           O_super_user      IN OUT NOCOPY BOOLEAN)
   RETURN BOOLEAN IS

   L_dummy      VARCHAR2(1);
   L_program    VARCHAR2(64) := 'FILTER_LOV_VALIDATE_SQL.TSL_VALIDATE_USER';

   CURSOR C_CHECK_USER is
   select 'X'
     from sec_user_group su
    where su.user_id = USER
      and exists (select nm.non_merch_code
                    from tsl_filter_group_non_merch nm
                   where nm.sec_group_id = su.group_id);
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_USER',
                    'SEC_USER_GROUP',
                    'USER_ID = ' ||USER);
   open C_CHECK_USER;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_USER',
                    'SEC_USER_GROUP',
                    'USER_ID = ' ||USER);
   fetch C_CHECK_USER into L_dummy;

   if C_CHECK_USER%NOTFOUND then
      O_super_user := TRUE;
   else
      O_super_user := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_USER',
                    'SEC_USER_GROUP',
                    'USER_ID = ' ||USER);
   close C_CHECK_USER;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VALIDATE_USER;
-----------------------------------------------------------------------------------------------
-- Mod N147, 14-Jul-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
-----------------------------------------------------------------------------------------------
-- CR316 17-May-2010 Bhargavi Pujari,  bharagavi.pujari@in.tesco.com Begin
-----------------------------------------------------------------------------------------------
-- Name   : TSL_VALIDATE_REV_COMPANY
-- Purpose: To validate the enetered REV COMPANY
-----------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_REV_COMPANY(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_valid          IN OUT  BOOLEAN,
                                  I_rev_company    IN      CODE_DETAIL.CODE%TYPE,
                                  I_duns_number    IN      SUPS.DUNS_NUMBER%TYPE,
                                  I_shared_ind     IN      SUPS.TSL_SHARED_SUPP_IND%TYPE)
   RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'FILTER_LOV_VALIDATE_SQL.TSL_VALIDATE_REV_COMPANY';
   L_valid      VARCHAR2(1);

   CURSOR C_CHECK_REV_COMPANY_UK is
   select 'X'
     from code_detail cd
    where cd.code_type   = 'TRCU'
      and   cd.code      = I_rev_company;

   CURSOR C_CHECK_REV_COMPANY_ROI is
   select 'X'
     from code_detail cd
    where cd.code_type   = 'TRCR'
      and cd.code        = I_rev_company;
    --
   CURSOR C_CHECK_REV_COMP_UK_ROI is
   select 'X'
     from code_detail cd
    where cd.code_type   in ('TRCU','TRCR')
      and cd.code        = I_rev_company;
   --

BEGIN

   if I_shared_ind = 'N' then
       if I_duns_number = 'GB' then
          SQL_LIB.SET_MARK('OPEN',
                           'C_CHECK_REV_COMPANY_UK',
                           'CODE_DETAIL',
                           'CODE = ' ||I_rev_company);
          open C_CHECK_REV_COMPANY_UK;

          SQL_LIB.SET_MARK('FETCH',
                           'C_CHECK_REV_COMPANY_UK',
                           'CODE_DETAIL',
                           'CODE = ' ||I_rev_company);
          fetch C_CHECK_REV_COMPANY_UK into L_valid;

          if C_CHECK_REV_COMPANY_UK%NOTFOUND then
             O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_REV_COMP');
             O_valid := FALSE;
          else
             O_valid := TRUE;
          end if;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_CHECK_REV_COMPANY_UK',
                           'CODE_DETAIL',
                           'CODE = ' ||I_rev_company);
          close C_CHECK_REV_COMPANY_UK;
       else
          if I_duns_number = 'IE' then
            SQL_LIB.SET_MARK('OPEN',
                             'C_CHECK_REV_COMPANY_ROI',
                             'CODE_DETAIL',
                             'CODE = ' ||I_rev_company);
            open C_CHECK_REV_COMPANY_ROI;

            SQL_LIB.SET_MARK('FETCH',
                             'C_CHECK_REV_COMPANY_ROI',
                             'CODE_DETAIL',
                             'CODE = ' ||I_rev_company);
            fetch C_CHECK_REV_COMPANY_ROI into L_valid;

            if C_CHECK_REV_COMPANY_ROI%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_REV_COMP');
               O_valid := FALSE;
            else
               O_valid := TRUE;
            end if;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_CHECK_REV_COMPANY_ROI',
                             'CODE_DETAIL',
                             'CODE = ' ||I_rev_company);
            close C_CHECK_REV_COMPANY_ROI;
          end if;
       end if;
   elsif I_shared_ind = 'Y' then
     SQL_LIB.SET_MARK('OPEN',
                      'C_CHECK_REV_COMP_UK_ROI',
                      'CODE_DETAIL',
                      'CODE = ' ||I_rev_company);
     open C_CHECK_REV_COMP_UK_ROI;

     SQL_LIB.SET_MARK('FETCH',
                      'C_CHECK_REV_COMP_UK_ROI',
                      'CODE_DETAIL',
                      'CODE = ' ||I_rev_company);
     fetch C_CHECK_REV_COMP_UK_ROI into L_valid;

     if C_CHECK_REV_COMP_UK_ROI%NOTFOUND then
        -- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_REV_COMP');
        -- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
        O_valid := FALSE;
     else
        O_valid := TRUE;
     end if;

     SQL_LIB.SET_MARK('CLOSE',
                      'C_CHECK_REV_COMP_UK_ROI',
                      'CODE_DETAIL',
                      'CODE = ' ||I_rev_company);
     close C_CHECK_REV_COMP_UK_ROI;
   end if;
   --
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VALIDATE_REV_COMPANY;
-----------------------------------------------------------------------------------------------
-- Name   : TSL_VALIDATE_ACC_CODE
-- Purpose: To validate the entered ACCOUNT CODE.
-----------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_ACC_CODE (O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                O_valid          IN OUT  BOOLEAN,
                                I_acc_code       IN      CODE_DETAIL.CODE%TYPE,
                                I_duns_number    IN      SUPS.DUNS_NUMBER%TYPE,
                                I_shared_ind     IN      SUPS.TSL_SHARED_SUPP_IND%TYPE,
                                I_dsd_ind        IN      SUPS.Dsd_Ind%TYPE,
                                --DefNBS019014/IM068213, 02-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, begin
                                I_billing_type   IN      DEAL_HEAD.BILLING_TYPE%TYPE)
                                --DefNBS019014/IM068213, 02-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, end

   RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'FILTER_LOV_VALIDATE_SQL.TSL_VALIDATE_ACC_CODE';
   L_valid      VARCHAR2(1);

   -- UK Direct Supplier
   CURSOR C_CHK_UK_DIR_ACC_CODE is
   select 'X'
     from code_detail cd
    where cd.code_type   = 'TMCU'
      and   cd.code      = I_acc_code;

   -- UK WH supplier
   CURSOR C_CHK_UK_WH_ACC_CODE is
   select 'X'
     from code_detail cd
    where cd.code_type   = 'TAUW'
      and   cd.code      = I_acc_code;

   -- ROI Direct Supplier
   CURSOR C_CHK_ROI_DIR_ACC_CODE is
   select 'X'
     from code_detail cd
    where cd.code_type   = 'TMCR'
      and cd.code        = I_acc_code;

   -- ROI WH Supplier
   CURSOR C_CHK_ROI_WH_ACC_CODE is
   select 'X'
     from code_detail cd
    where cd.code_type   = 'TARW'
      and cd.code        = I_acc_code;

   -- Shared Direct supplier
   CURSOR C_CHK_DIR_SHARED_ACC_CODE is
   select 'X'
     from code_detail cd
    where cd.code_type   in ('TMCR','TMCU')
      and cd.code        = I_acc_code;

   -- Shared WH Supplier
   CURSOR C_CHK_WH_SHARED_ACC_CODE is
   select 'X'
     from code_detail cd
    where cd.code_type   in ('TAUW','TARW')
      and cd.code        = I_acc_code;

   --DefNBS019014/IM068213, 02-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, begin
   -- BB Deals
   CURSOR C_CHK_BBDEAL_ACC_CODE is
   select 'X'
     from code_detail cd
    where cd.code_type   = 'TMIC'
      and cd.code        = I_acc_code;
   --DefNBS019014/IM068213, 02-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, end

BEGIN

   --DefNBS019014/IM068213, 02-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, begin
   if I_billing_type != 'BB' then
   --DefNBS019014/IM068213, 02-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, end
   if I_shared_ind = 'N' and I_dsd_ind = 'Y' then
       if I_duns_number = 'GB' then
          SQL_LIB.SET_MARK('OPEN',
                           'C_CHK_UK_DIR_ACC_CODE',
                           'CODE_DETAIL',
                           'CODE = ' ||I_acc_code);
          open C_CHK_UK_DIR_ACC_CODE;

          SQL_LIB.SET_MARK('FETCH',
                           'C_CHK_UK_DIR_ACC_CODE',
                           'CODE_DETAIL',
                           'CODE = ' ||I_acc_code);
          fetch C_CHK_UK_DIR_ACC_CODE into L_valid;

          if C_CHK_UK_DIR_ACC_CODE%NOTFOUND then
             O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_ACC_CODE');
             O_valid := FALSE;
          else
             O_valid := TRUE;
          end if;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_CHK_UK_DIR_ACC_CODE',
                           'CODE_DETAIL',
                           'CODE = ' ||I_acc_code);
          close C_CHK_UK_DIR_ACC_CODE;
       else
          if I_duns_number = 'IE' then
             SQL_LIB.SET_MARK('OPEN',
                              'C_CHK_ROI_DIR_ACC_CODE',
                              'CODE_DETAIL',
                              'CODE = ' ||I_acc_code);
             open C_CHK_ROI_DIR_ACC_CODE;

             SQL_LIB.SET_MARK('FETCH',
                              'C_CHK_ROI_DIR_ACC_CODE',
                              'CODE_DETAIL',
                              'CODE = ' ||I_acc_code);
             fetch C_CHK_ROI_DIR_ACC_CODE into L_valid;

             if C_CHK_ROI_DIR_ACC_CODE%NOTFOUND then
                O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_ACC_CODE');
                O_valid := FALSE;
             else
                 O_valid := TRUE;
             end if;

              SQL_LIB.SET_MARK('CLOSE',
                               'C_CHK_ROI_DIR_ACC_CODE',
                               'CODE_DETAIL',
                               'CODE = ' ||I_acc_code);
              close C_CHK_ROI_DIR_ACC_CODE;
          end if;
       end if;
   elsif I_shared_ind = 'N' and I_dsd_ind = 'N' then
      if I_duns_number = 'GB' then
          SQL_LIB.SET_MARK('OPEN',
                           'C_CHK_UK_WH_ACC_CODE',
                           'CODE_DETAIL',
                           'CODE = ' ||I_acc_code);
          open C_CHK_UK_WH_ACC_CODE;

          SQL_LIB.SET_MARK('FETCH',
                           'C_CHK_UK_WH_ACC_CODE',
                           'CODE_DETAIL',
                           'CODE = ' ||I_acc_code);
          fetch C_CHK_UK_WH_ACC_CODE into L_valid;

          if C_CHK_UK_WH_ACC_CODE%NOTFOUND then
             O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_ACC_CODE');
             O_valid := FALSE;
          else
             O_valid := TRUE;
          end if;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_CHK_UK_WH_ACC_CODE',
                           'CODE_DETAIL',
                           'CODE = ' ||I_acc_code);
          close C_CHK_UK_WH_ACC_CODE;
       else
          if I_duns_number = 'IE' then
             SQL_LIB.SET_MARK('OPEN',
                              'C_CHK_ROI_WH_ACC_CODE',
                              'CODE_DETAIL',
                              'CODE = ' ||I_acc_code);
             open C_CHK_ROI_WH_ACC_CODE;

             SQL_LIB.SET_MARK('FETCH',
                              'C_CHK_ROI_WH_ACC_CODE',
                              'CODE_DETAIL',
                              'CODE = ' ||I_acc_code);
             fetch C_CHK_ROI_WH_ACC_CODE into L_valid;

             if C_CHK_ROI_WH_ACC_CODE%NOTFOUND then
                O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_ACC_CODE');
                O_valid := FALSE;
             else
                 O_valid := TRUE;
             end if;

              SQL_LIB.SET_MARK('CLOSE',
                               'C_CHK_ROI_WH_ACC_CODE',
                               'CODE_DETAIL',
                               'CODE = ' ||I_acc_code);
              close C_CHK_ROI_WH_ACC_CODE;
          end if;
       end if;
   elsif I_shared_ind = 'Y' and I_dsd_ind = 'Y' then
    SQL_LIB.SET_MARK('OPEN',
                      'C_CHK_DIR_SHARED_ACC_CODE',
                      'CODE_DETAIL',
                      'CODE = ' ||I_acc_code);
     open C_CHK_DIR_SHARED_ACC_CODE;

     SQL_LIB.SET_MARK('FETCH',
                      'C_CHK_DIR_SHARED_ACC_CODE',
                      'CODE_DETAIL',
                      'CODE = ' ||I_acc_code);
     fetch C_CHK_DIR_SHARED_ACC_CODE into L_valid;

     if C_CHK_DIR_SHARED_ACC_CODE%NOTFOUND then
        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_ACC_CODE');
        O_valid := FALSE;
     else
        O_valid := TRUE;
     end if;

     SQL_LIB.SET_MARK('CLOSE',
                      'C_CHK_DIR_SHARED_ACC_CODE',
                      'CODE_DETAIL',
                      'CODE = ' ||I_acc_code);
     close C_CHK_DIR_SHARED_ACC_CODE;
  elsif I_shared_ind = 'Y' and I_dsd_ind = 'N' then
    SQL_LIB.SET_MARK('OPEN',
                      'C_CHK_WH_SHARED_ACC_CODE',
                      'CODE_DETAIL',
                      'CODE = ' ||I_acc_code);
     open C_CHK_WH_SHARED_ACC_CODE;

     SQL_LIB.SET_MARK('FETCH',
                      'C_CHK_WH_SHARED_ACC_CODE',
                      'CODE_DETAIL',
                      'CODE = ' ||I_acc_code);
     fetch C_CHK_WH_SHARED_ACC_CODE into L_valid;

     if C_CHK_WH_SHARED_ACC_CODE%NOTFOUND then
        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_ACC_CODE');
        O_valid := FALSE;
     else
        O_valid := TRUE;
     end if;

     SQL_LIB.SET_MARK('CLOSE',
                      'C_CHK_WH_SHARED_ACC_CODE',
                      'CODE_DETAIL',
                      'CODE = ' ||I_acc_code);
     close C_CHK_WH_SHARED_ACC_CODE;
  end if;
   --MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
   --DefNBS019014/IM068213, 02-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, begin
	 elsif I_billing_type = 'BB' then
     SQL_LIB.SET_MARK('OPEN',
                      'C_CHK_BBDEAL_ACC_CODE',
                      'CODE_DETAIL',
                      'CODE = ' ||I_acc_code);
     open C_CHK_BBDEAL_ACC_CODE;

     SQL_LIB.SET_MARK('FETCH',
                      'C_CHK_BBDEAL_ACC_CODE',
                      'CODE_DETAIL',
                      'CODE = ' ||I_acc_code);
     fetch C_CHK_BBDEAL_ACC_CODE into L_valid;

     if C_CHK_BBDEAL_ACC_CODE%NOTFOUND then
        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_ACC_CODE');
        O_valid := FALSE;
     else
        O_valid := TRUE;
     end if;

     SQL_LIB.SET_MARK('CLOSE',
                      'C_CHK_BBDEAL_ACC_CODE',
                      'CODE_DETAIL',
                      'CODE = ' ||I_acc_code);
     close C_CHK_BBDEAL_ACC_CODE;
	 end if;
	 --DefNBS019014/IM068213, 02-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, end
   --MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VALIDATE_ACC_CODE;
-----------------------------------------------------------------------------------------------
-- Name   : TSL_VALIDATE_NON_MERCH_CODE_UK_ROI
-- Purpose: To validate the entered NON MERCH CODE for ROI and UK.
-----------------------------------------------------------------------------------------------
FUNCTION  TSL_VALID_NON_MRCH_UKROI(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_valid          IN OUT  BOOLEAN,
                                   O_debtor_area    IN OUT  TSL_DEBTOR_AREA.DEBTOR_AREA%TYPE,
                                   I_non_merch_code IN      NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE,
                                   I_duns_number    IN      SUPS.DUNS_NUMBER%TYPE,
                                   I_shared_ind     IN      SUPS.TSL_SHARED_SUPP_IND%TYPE)
   RETURN BOOLEAN IS
   L_program               VARCHAR2(64)                := 'FILTER_LOV_VALIDATE_SQL.TSL_VALID_NON_MRCH_UKROI';
   L_valid                 VARCHAR2(1);
   L_non_merch_code        NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE;

   CURSOR C_VALIDATE_NON_MERCH_CODE_UK is
   select 'X'
     from non_merch_code_head nmcd
    where nmcd.non_merch_code   = I_non_merch_code;

   CURSOR C_VALIDATE_NON_MERCH_CODE_ROI is
   select 'X'
     from tsl_non_merch_code_head_roi  tnmr
    where tnmr.non_merch_code  = I_non_merch_code;

   CURSOR C_GET_DEBTOR_AREA is
   select debtor_area
     from tsl_debtor_area  tda
    where tda.rev_cost_centre = I_non_merch_code;

    --
     CURSOR C_NON_MERCH_UK_ROI is
     select non_merch_code from non_merch_code_head
      where non_merch_code = I_non_merch_code
      UNION
     select non_merch_code from tsl_non_merch_code_head_roi
      where non_merch_code = I_non_merch_code;
    --

BEGIN

   if I_shared_ind = 'N' then
       if I_duns_number = 'GB' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_VALIDATE_NON_MERCH_CODE_UK',
                          'NON_MERCH_CODE_HEAD',
                          'Non-Merch Code = ' ||I_non_merch_code);
         open C_VALIDATE_NON_MERCH_CODE_UK;
         SQL_LIB.SET_MARK('FETCH',
                          'C_VALIDATE_NON_MERCH_CODE_UK',
                          'NON_MERCH_CODE_HEAD',
                          'Non-Merch Code = ' ||I_non_merch_code);
         fetch C_VALIDATE_NON_MERCH_CODE_UK into L_valid;
         --
         if C_VALIDATE_NON_MERCH_CODE_UK%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_COST_CENTRE');
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         --
         SQL_LIB.SET_MARK('CLOSE',
                          'C_VALIDATE_NON_MERCH_CODE_UK',
                          'NON_MERCH_CODE_HEAD',
                          'Non-Merch Code = ' ||I_non_merch_code);
         close C_VALIDATE_NON_MERCH_CODE_UK;

         -- Selecting debtor_area
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_DEBTOR_AREA',
                          'TSL_DEBTOR_AREA',
                          'Non-Merch Code = ' ||I_non_merch_code);
         open C_GET_DEBTOR_AREA;
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_DEBTOR_AREA',
                          'TSL_DEBTOR_AREA',
                          'Non-Merch Code = ' ||I_non_merch_code);
         fetch C_GET_DEBTOR_AREA into O_debtor_area;
         if C_GET_DEBTOR_AREA%NOTFOUND then
            O_debtor_area := NULL;
         end if;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_DEBTOR_AREA',
                          'TSL_DEBTOR_AREA',
                          'Non-Merch Code = ' ||I_non_merch_code);
         close C_GET_DEBTOR_AREA;

       else
          if I_duns_number = 'IE' then
             SQL_LIB.SET_MARK('OPEN',
                              'C_VALIDATE_NON_MERCH_CODE_ROI',
                              'TSL_NON_MERCH_CODE_HEAD',
                              'Non-Merch Code = ' ||I_non_merch_code);
             open C_VALIDATE_NON_MERCH_CODE_ROI;
             SQL_LIB.SET_MARK('FETCH',
                              'C_VALIDATE_NON_MERCH_CODE_ROI',
                              'TSL_NON_MERCH_CODE_HEAD_ROI',
                              'Non-Merch Code = ' ||I_non_merch_code);
             fetch C_VALIDATE_NON_MERCH_CODE_ROI into L_valid;
             --
             if C_VALIDATE_NON_MERCH_CODE_ROI%NOTFOUND then
                O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_COST_CENTRE');
                O_valid := FALSE;
             else
                O_valid := TRUE;
             end if;
             SQL_LIB.SET_MARK('CLOSE',
                            'C_VALIDATE_NON_MERCH_CODE_ROI',
                            'TSL_NON_MERCH_CODE_HEAD_ROI',
                            'Non-Merch Code = ' ||I_non_merch_code);
             close C_VALIDATE_NON_MERCH_CODE_ROI;
             -- NBS00017761 31-May-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
             -- Selecting debtor_area
             SQL_LIB.SET_MARK('OPEN',
                              'C_GET_DEBTOR_AREA',
                              'TSL_DEBTOR_AREA',
                              'Non-Merch Code = ' ||I_non_merch_code);
             open C_GET_DEBTOR_AREA;
             SQL_LIB.SET_MARK('FETCH',
                              'C_GET_DEBTOR_AREA',
                              'TSL_DEBTOR_AREA',
                              'Non-Merch Code = ' ||I_non_merch_code);
             fetch C_GET_DEBTOR_AREA into O_debtor_area;
             if C_GET_DEBTOR_AREA%NOTFOUND then
                O_debtor_area := NULL;
             end if;
             SQL_LIB.SET_MARK('CLOSE',
                              'C_GET_DEBTOR_AREA',
                              'TSL_DEBTOR_AREA',
                              'Non-Merch Code = ' ||I_non_merch_code);
             close C_GET_DEBTOR_AREA;
             -- NBS00017761 31-May-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
          end if;
       end if;
       --
    elsif I_shared_ind = 'Y' then
       SQL_LIB.SET_MARK('OPEN',
                        'C_NON_MERCH_UK_ROI',
                        'NON_MERCH_CODE',
                        'Non-Merch Code = ' ||I_non_merch_code);
       open C_NON_MERCH_UK_ROI;
       SQL_LIB.SET_MARK('FETCH',
                         'C_NON_MERCH_UK_ROI',
                         'NON_MERCH_CODE',
                         'Non-Merch Code = ' ||I_non_merch_code);
       fetch C_NON_MERCH_UK_ROI into L_non_merch_code ;
         --
       if C_NON_MERCH_UK_ROI%NOTFOUND then
          O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_COST_CENTRE');
          O_valid := FALSE;
       else
          O_valid := TRUE;
       end if;
       SQL_LIB.SET_MARK('CLOSE',
                        'C_NON_MERCH_UK_ROI',
                        'NON_MERCH_CODE',
                        'Non-Merch Code = ' ||I_non_merch_code);
       close C_NON_MERCH_UK_ROI;
        -- Selecting debtor_area
       SQL_LIB.SET_MARK('OPEN',
                        'C_GET_DEBTOR_AREA',
                        'TSL_DEBTOR_AREA',
                        'Non-Merch Code = ' ||I_non_merch_code);
       open C_GET_DEBTOR_AREA;
       SQL_LIB.SET_MARK('FETCH',
                        'C_GET_DEBTOR_AREA',
                        'TSL_DEBTOR_AREA',
                        'Non-Merch Code = ' ||I_non_merch_code);
       fetch C_GET_DEBTOR_AREA into O_debtor_area;
       if C_GET_DEBTOR_AREA%NOTFOUND then
          O_debtor_area := NULL;
       end if;
       SQL_LIB.SET_MARK('CLOSE',
                        'C_GET_DEBTOR_AREA',
                        'TSL_DEBTOR_AREA',
                        'Non-Merch Code = ' ||I_non_merch_code);
       close C_GET_DEBTOR_AREA;

    end if;
   --
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
      --
END TSL_VALID_NON_MRCH_UKROI;
-----------------------------------------------------------------------------------------------
-- Name   : TSL_VALIDATE_DEBTOR_AREA
-- Purpose: To validate the entered  DEBTOR AREA depends on COST CENTRE(one-one relation).
-----------------------------------------------------------------------------------------------
FUNCTION  TSL_VALIDATE_DEBTOR_AREA(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_valid           IN OUT  BOOLEAN,
                                   I_debtor_area     IN      TSL_DEBTOR_AREA.DEBTOR_AREA%TYPE,
                                   I_duns_number     IN      SUPS.DUNS_NUMBER%TYPE,
                                   I_shared_ind      IN      SUPS.TSL_SHARED_SUPP_IND%TYPE)
   RETURN BOOLEAN IS
   L_program               VARCHAR2(64)                := 'FILTER_LOV_VALIDATE_SQL.TSL_VALIDATE_DEBTOR_AREA';
   L_valid                 VARCHAR2(1);
   -- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
   -- CR340 15-Oct-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   L_sec_ind               SYSTEM_OPTIONS.Tsl_Loc_Sec_Ind%TYPE;
   L_uk_ind                VARCHAR2(1);
   L_roi_ind               VARCHAR2(1);
   -- CR340 15-Oct-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
   -- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end

   -- MrgNBS017783 04-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   CURSOR C_CHECK_DEBT_AREA_UK is
   select 'X'
     from tsl_debtor_area  tba,non_merch_code_head tn
    where tba.debtor_area      =  I_debtor_area
      and tba.rev_cost_centre  = tn.non_merch_code;

   CURSOR C_CHECK_DEBT_AREA_ROI is
   select 'X'
     from tsl_debtor_area  tba,tsl_non_merch_code_head_roi tn
    where tba.debtor_area      =  I_debtor_area
      and tba.rev_cost_centre  = tn.non_merch_code;
   -- MrgNBS017783 04-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End

   CURSOR C_CHECK_DEBT_AREA is
   select 'X'
     from tsl_debtor_area  tba
    where tba.debtor_area      =  I_debtor_area;

BEGIN
   -- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
   -- CR340 15-Oct-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   if NOT SYSTEM_OPTIONS_SQL.TSL_GET_LOC_SEC_IND (O_error_message,
                               L_sec_ind) then
      return FALSE;
   end if;
   if NOT FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY (O_error_message,
                                                  L_uk_ind,
                                                  L_roi_ind) then
       return FALSE;
   end if;
   -- MrgNBS017783 04-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   if L_sec_ind = 'N' then
   -- CR340 15-Oct-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
   -- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
   if I_shared_ind = 'N' then
      if I_duns_number = 'GB' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_CHECK_DEBT_AREA_UK',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         open C_CHECK_DEBT_AREA_UK;
         SQL_LIB.SET_MARK('FETCH',
                          'C_CHECK_DEBT_AREA_UK',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         fetch C_CHECK_DEBT_AREA_UK into L_valid;
         --
         if C_CHECK_DEBT_AREA_UK%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DEBTOR_AREA');
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         --
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_DEBT_AREA_UK',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         close C_CHECK_DEBT_AREA_UK;
      -- For ROI
      elsif I_duns_number = 'IE' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_CHECK_DEBT_AREA_ROI',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         open C_CHECK_DEBT_AREA_ROI;
         SQL_LIB.SET_MARK('FETCH',
                          'C_CHECK_DEBT_AREA_ROI',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         fetch C_CHECK_DEBT_AREA_ROI into L_valid;
         --
         if C_CHECK_DEBT_AREA_ROI%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DEBTOR_AREA');
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         --
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_DEBT_AREA_ROI',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         close C_CHECK_DEBT_AREA_ROI;
      end if;
   -- shared supplier
   elsif I_shared_ind = 'Y' then
   -- MrgNBS017783 04-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_DEBT_AREA',
                       'TSL_DEBTOR_AREA',
                       'DEBTOR-AREA = ' ||I_debtor_area);
      open C_CHECK_DEBT_AREA;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_DEBT_AREA',
                       'TSL_DEBTOR_AREA',
                       'DEBTOR-AREA = ' ||I_debtor_area);
      fetch C_CHECK_DEBT_AREA into L_valid;
     --
      if C_CHECK_DEBT_AREA%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DEBTOR_AREA');
         O_valid := FALSE;
      else
         O_valid := TRUE;
      end if;
     --
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_DEBT_AREA',
                       'TSL_DEBTOR_AREA',
                       'DEBTOR-AREA = ' ||I_debtor_area);
      close C_CHECK_DEBT_AREA;
   end if;
   -- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
   -- CR340 15-Oct-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   elsif L_sec_ind = 'Y' then
      if L_uk_ind = 'Y' and L_roi_ind = 'N' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_CHECK_DEBT_AREA_UK',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         open C_CHECK_DEBT_AREA_UK;
         SQL_LIB.SET_MARK('FETCH',
                          'C_CHECK_DEBT_AREA_UK',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         fetch C_CHECK_DEBT_AREA_UK into L_valid;
         --
         if C_CHECK_DEBT_AREA_UK%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DEBTOR_AREA');
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         --
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_DEBT_AREA_UK',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         close C_CHECK_DEBT_AREA_UK;
      elsif L_uk_ind = 'N' and L_roi_ind = 'Y' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_CHECK_DEBT_AREA_ROI',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         open C_CHECK_DEBT_AREA_ROI;
         SQL_LIB.SET_MARK('FETCH',
                          'C_CHECK_DEBT_AREA_ROI',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         fetch C_CHECK_DEBT_AREA_ROI into L_valid;
         --
         if C_CHECK_DEBT_AREA_ROI%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DEBTOR_AREA');
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         --
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_DEBT_AREA_ROI',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         close C_CHECK_DEBT_AREA_ROI;
      elsif L_uk_ind = 'Y' and L_roi_ind = 'Y' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_CHECK_DEBT_AREA',
                          'TSL_DEBTOR_AREA',
                        'DEBTOR-AREA = ' ||I_debtor_area);
         open C_CHECK_DEBT_AREA;
         SQL_LIB.SET_MARK('FETCH',
                          'C_CHECK_DEBT_AREA',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         fetch C_CHECK_DEBT_AREA into L_valid;
         --
         if C_CHECK_DEBT_AREA%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DEBTOR_AREA');
            O_valid := FALSE;
         else
            O_valid := TRUE;
         end if;
         --
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_DEBT_AREA',
                          'TSL_DEBTOR_AREA',
                          'DEBTOR-AREA = ' ||I_debtor_area);
         close C_CHECK_DEBT_AREA;
      end if;
   end if;
   -- CR340 15-Oct-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
   -- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
      --
END TSL_VALIDATE_DEBTOR_AREA;
-----------------------------------------------------------------------------------------------
-- CR316 17-May-2010 Bhargavi Pujari,  bharagavi.pujari@in.tesco.com End
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- 13-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 Begin
---------------------------------------------------------------------------------------------
-- Author         : Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
-- Function Name  : TSL_VALIDATE_NON_MERCH_UKROI
-- Purpose        : This function is called to validate the non-merch code in search/view modes
--                  In search or view mode, user should be able to select either UK or ROI Cost Centre
--                  In edit/new mode, user should be able to select only the cost Center to which
--                  they are associated. I_mode- E-Edit, V- View
---------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_NON_MERCH_UKROI(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                      O_valid           IN OUT   BOOLEAN,
                                      O_non_merch_desc  IN OUT   NON_MERCH_CODE_HEAD.NON_MERCH_CODE_DESC%TYPE,
                                      I_non_merch_code  IN       TSL_BHMS_USER_NONMERCH_CODE.NON_MERCH_CODE%TYPE,
                                      I_mode            IN       VARCHAR2)
RETURN BOOLEAN is

   L_program               VARCHAR2(64)     := 'FILTER_LOV_VALIDATE_SQL.TSL_VALIDATE_NON_MERCH_UKROI';
   L_valid                 VARCHAR2(1);
   L_non_merch_code        NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE;
   L_non_merch_code_desc   NON_MERCH_CODE_HEAD.NON_MERCH_CODE_DESC%TYPE;

     CURSOR C_NON_MERCH_UK_ROI is
     select non_merch_code,
            non_merch_code_desc
       from non_merch_code_head
      where non_merch_code = I_non_merch_code
      UNION
     select non_merch_code ,
            non_merch_code_desc
       from tsl_non_merch_code_head_roi
      where non_merch_code = I_non_merch_code;
    --
     --The view filters and shows only the merch codes
     --to which the user has access
     CURSOR C_NON_MERCH_UK_ROI_EDIT is
     select non_merch_code,
            non_merch_code_desc
       from v_tsl_non_merch_code
      where non_merch_code = I_non_merch_code;


BEGIN
   if I_mode != 'E' then

     SQL_LIB.SET_MARK('OPEN',
                      'C_NON_MERCH_UK_ROI',
                      'NON_MERCH_CODE',
                      'Non-Merch Code : ' ||I_non_merch_code);
     open C_NON_MERCH_UK_ROI;
     SQL_LIB.SET_MARK('FETCH',
                       'C_NON_MERCH_UK_ROI',
                       'NON_MERCH_CODE',
                       'Non-Merch Code = ' ||I_non_merch_code);
     fetch C_NON_MERCH_UK_ROI into L_non_merch_code,L_non_merch_code_desc ;
       --
     if C_NON_MERCH_UK_ROI%NOTFOUND then
        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_COST_CENTRE');
        O_valid := FALSE;
     else
        O_valid := TRUE;
     end if;
     SQL_LIB.SET_MARK('CLOSE',
                      'C_NON_MERCH_UK_ROI',
                      'NON_MERCH_CODE',
                      'Non-Merch Code = ' ||I_non_merch_code);
     close C_NON_MERCH_UK_ROI;

   else

     SQL_LIB.SET_MARK('OPEN',
                      'C_NON_MERCH_UK_ROI_EDIT',
                      'NON_MERCH_CODE',
                      'Non-Merch Code : ' ||I_non_merch_code);
     open C_NON_MERCH_UK_ROI_EDIT;
     SQL_LIB.SET_MARK('FETCH',
                       'C_NON_MERCH_UK_ROI_EDIT',
                       'NON_MERCH_CODE',
                       'Non-Merch Code = ' ||I_non_merch_code);
     fetch C_NON_MERCH_UK_ROI_EDIT into L_non_merch_code,L_non_merch_code_desc ;
       --
     if C_NON_MERCH_UK_ROI_EDIT%NOTFOUND then
        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_COST_CENTRE');
        O_valid := FALSE;
     else
        O_valid := TRUE;
     end if;
     SQL_LIB.SET_MARK('CLOSE',
                      'C_NON_MERCH_UK_ROI_EDIT',
                      'NON_MERCH_CODE',
                      'Non-Merch Code = ' ||I_non_merch_code);
     close C_NON_MERCH_UK_ROI_EDIT;

   end if;

   O_non_merch_desc := L_non_merch_code_desc;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VALIDATE_NON_MERCH_UKROI;
---------------------------------------------------------------------------------------------
-- 13-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 End
-- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
---------------------------------------------------------------------------------------------
-- CR340 28-Sep-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
---------------------------------------------------------------------------------------------
-- Name   : TSL_GET_DEBTOR_AREA
-- Purpose: To get debtor area for passed non merch code.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_DEBTOR_AREA(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_debtor_area     IN OUT   TSL_DEBTOR_AREA.DEBTOR_AREA%TYPE,
                             I_non_merch_code  IN       TSL_DEBTOR_AREA.REV_COST_CENTRE%TYPE)
RETURN BOOLEAN IS
L_program VARCHAR2(50) := 'FILTER_LOV_VALIDATE_SQL.TSL_GET_DEBTOR_AREA';

   CURSOR C_GET_DEBTOR_AREA is
   select td.debtor_area
     from tsl_debtor_area td
    where td.rev_cost_centre = I_non_merch_code;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_DEBTOR_AREA',
                    'TSL_DEBTOR_AREA',
                    'COST CENTRE: '||I_non_merch_code);
   open C_GET_DEBTOR_AREA;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_DEBTOR_AREA',
                    'TSL_DEBTOR_AREA',
                    'COST CENTRE: '||I_non_merch_code);
   fetch C_GET_DEBTOR_AREA into O_debtor_area;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_DEBTOR_AREA',
                    'TSL_DEBTOR_AREA',
                    'COST CENTRE: '||I_non_merch_code);
   close C_GET_DEBTOR_AREA;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_DEBTOR_AREA;
---------------------------------------------------------------------------------------------
-- Name   : TSL_VLD_INT_CONTACT
-- Purpose: To validate user depend on passed non merch code.
---------------------------------------------------------------------------------------------
FUNCTION TSL_VLD_INT_CONTACT(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists          IN OUT   BOOLEAN,
                             I_non_merch_code  IN       NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE,
                             I_int_contact     IN       USER_ATTRIB.USER_NAME%TYPE,
                             I_duns_number     IN       SUPS.DUNS_NUMBER%TYPE)
RETURN BOOLEAN IS
   L_program VARCHAR2(50) := 'FILTER_LOV_VALIDATE_SQL.TSL_VLD_INT_CONTACT';
   L_valid   VARCHAR2(1);

   CURSOR C_VLD_INT_CONTACT_UK is
   select 'X'
     from user_attrib ua,
          tsl_bhms_users tb,
          tsl_bhms_user_nonmerch_code tbn
    where tb.role_id         = tbn.role_id and
          ua.user_id         = tb.tpx_id
      and tbn.non_merch_code = I_non_merch_code
      and ua.user_name       = I_int_contact;

   CURSOR C_VLD_INT_CONTACT_ROI is
   select 'X'
     from user_attrib ua,
          tsl_bhms_users tb
     -- 04-JAN-2011 , Murali N  NBS00020420 Begin
   where ua.user_id         = tb.tpx_id
     and ua.user_name       = I_int_contact;
     -- 04-JAN-2011 , Murali N  NBS00020420 End
BEGIN
   if I_duns_number = 'GB' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_VLD_INT_CONTACT_UK',
                       'tsl_bhms_user_nonmerch_code',
                       'COST CENTRE: '||I_non_merch_code);
      open C_VLD_INT_CONTACT_UK;
      SQL_LIB.SET_MARK('FETCH',
                       'C_VLD_INT_CONTACT_UK',
                       'tsl_bhms_user_nonmerch_code',
                       'COST CENTRE: '||I_non_merch_code);
      fetch C_VLD_INT_CONTACT_UK into L_valid;
      if C_VLD_INT_CONTACT_UK%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('TSL_NO_ACCESS_CST_CENT');
         O_exists := FALSE;
      else
         O_exists := TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_VLD_INT_CONTACT_UK',
                       'tsl_bhms_user_nonmerch_code',
                       'COST CENTRE: '||I_non_merch_code);
      close C_VLD_INT_CONTACT_UK;
   else
      SQL_LIB.SET_MARK('OPEN',
                       'C_VLD_INT_CONTACT_ROI',
                       'tsl_bhms_user_nonmerch_code',
                       'COST CENTRE: '||I_non_merch_code);
      open C_VLD_INT_CONTACT_ROI;
      SQL_LIB.SET_MARK('FETCH',
                       'C_VLD_INT_CONTACT_ROI',
                       'tsl_bhms_user_nonmerch_code',
                       'COST CENTRE: '||I_non_merch_code);
      fetch C_VLD_INT_CONTACT_ROI into L_valid;
      if C_VLD_INT_CONTACT_ROI%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('TSL_NO_ACCESS_CST_CENT');
         O_exists := FALSE;
      else
         O_exists := TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_VLD_INT_CONTACT_ROI',
                       'tsl_bhms_user_nonmerch_code',
                       'COST CENTRE: '||I_non_merch_code);
      close C_VLD_INT_CONTACT_ROI;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VLD_INT_CONTACT;
---------------------------------------------------------------------------------------------
-- CR340 28-Sep-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
-- MrgNBS019839, 24-Nov-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--CR332, Accenture/Bijaya Kumar Behera, Bijayakumar.Behera@in.tesco.com, 29-Oct-2010, Begin
---------------------------------------------------------------------------------------------
-- Name   : TSL_VALIDATE_STYLE_REF_CODE
-- Purpose: To validate if the style reference code exists in the system
---------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_STYLE_REF_CODE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                     O_valid          IN OUT  BOOLEAN,
                                     I_Style_Ref_Code IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(60)       := 'FILTER_LOV_VALIDATE_SQL.TSL_VALIDATE_STYLE_REF_CODE';
   L_exist        VARCHAR2(1);

   CURSOR C_CHECK_STYLE_REF_CODE is
   select 'X'
     from item_master im
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
    where UPPER(im.item_desc_secondary) = UPPER(I_style_ref_code);
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End

BEGIN

   if I_Style_Ref_Code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_Style_Ref_Code,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   open C_CHECK_STYLE_REF_CODE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   fetch C_CHECK_STYLE_REF_CODE into L_exist;
   if L_exist is NULL then
      O_valid := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            I_Style_Ref_Code,
                                            NULL,
                                            NULL);
   else
      O_valid := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   close C_CHECK_STYLE_REF_CODE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_VALIDATE_STYLE_REF_CODE;
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Name   : TSL_VALIDATE_STYLE_REF_CODE
-- Purpose: To validate whether the input Style Reference Code exists in the system for a
--          simple pack
---------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_STYLE_REF_CODE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                     O_valid          IN OUT  BOOLEAN,
                                     I_Supplier       IN      ITEM_SUPPLIER.SUPPLIER%TYPE,
                                     I_Style_Ref_Code IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(60)       := 'FILTER_LOV_VALIDATE_SQL.TSL_VALIDATE_STYLE_REF_CODE';
   L_exist        VARCHAR2(1);
   L_location_access  VARCHAR2(1) := 'N';
   L_error_message    RTK_ERRORS.RTK_TEXT%TYPE;

   CURSOR C_CHECK_SIMPLE_PACK is
   select 'X'
     from item_master im
    --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
    where UPPER(im.item_desc_secondary) = UPPER(I_style_ref_code)
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End
      and im.simple_pack_ind = 'Y'
      and im.tran_level = 1
      and im.item_level = 1
      and im.status = 'A'
      and ((L_location_access = 'U' and im.tsl_country_auth_ind in ('U','B'))
            or (L_location_access = 'R' and im.tsl_country_auth_ind in ('R','B'))
            or (L_location_access = 'B' and im.tsl_country_auth_ind in ('U','R','B')));

   CURSOR C_CHECK_SUPPLIER is
   select 'X'
     from item_master im
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
    where UPPER(item_desc_secondary) = UPPER(I_style_ref_code)
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End
      and simple_pack_ind = 'Y'
      and item_level = 1
      and tran_level = 1
      and status = 'A'
      and exists (select 'X'
                    from item_supplier isp
                   where isp.item = im.item
                     and isp.supplier = I_Supplier);
BEGIN

   O_valid := FALSE;
   if I_Style_Ref_Code is NOT NULL then
      if I_supplier is NOT NULL then
         open C_CHECK_SUPPLIER;
         fetch C_CHECK_SUPPLIER into L_exist;
         if C_CHECK_SUPPLIER%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',I_Style_Ref_Code, NULL, NULL);
         else
            O_valid := TRUE;
         end if;
         close C_CHECK_SUPPLIER;
      else
         if TSL_RP_STYLE_REF_CODE.GET_USER_LOCATION(L_error_message,L_location_access) = FALSE then
            return FALSE;
         end if;
         open C_CHECK_SIMPLE_PACK;
         fetch C_CHECK_SIMPLE_PACK into L_exist;
         if C_CHECK_SIMPLE_PACK%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',I_Style_Ref_Code, NULL, NULL);
	       else
            O_valid := TRUE;
         end if;
         close C_CHECK_SIMPLE_PACK;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_Style_Ref_Code,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if O_valid = TRUE then
      return TRUE;
   else
      return FALSE;
   end if;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_VALIDATE_STYLE_REF_CODE;
---------------------------------------------------------------------------------------------
FUNCTION TSL_VLD_STYLE_REF_CODE_PACK(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                     O_valid          IN OUT  BOOLEAN,
                                     I_pack_id        IN      ITEM_MASTER.ITEM%TYPE,
                                     I_Style_Ref_Code IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(60)       := 'FILTER_LOV_VALIDATE_SQL.TSL_VLD_STYLE_REF_CODE_PACK';
   L_exist        VARCHAR2(1);

  CURSOR C_CHECK_STYLE_REF_CODE is
   select 'X'
     from v_item_master im
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
    where UPPER(im.item_desc_secondary) = UPPER(I_style_ref_code)
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End
      and im.item_level = 1
      and im.tran_level = 1
      and im.simple_pack_ind = 'Y'
      and im.pack_ind = 'Y'
      and exists (select iscp.supplier
                    from item_supp_country iscp
                   where iscp.item = I_pack_id
                  INTERSECT
                  select iscq.supplier
                    from item_supp_country iscq
                    where iscq.item = im.item);
BEGIN

   if I_pack_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_pack_id,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_Style_Ref_Code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_Style_Ref_Code,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_STYLE_REF_CODE',
                    'V_ITEM_MASTER,PACKITEM,ITEM_SUPP_COUNTRY,ITEM_SUPPLIER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   open C_CHECK_STYLE_REF_CODE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_STYLE_REF_CODE',
                    'V_ITEM_MASTER,PACKITEM,ITEM_SUPP_COUNTRY,ITEM_SUPPLIER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   fetch C_CHECK_STYLE_REF_CODE into L_exist;
   if L_exist is NULL then
      O_valid := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            I_Style_Ref_Code,
                                            NULL,
                                            NULL);
   else
      O_valid := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_STYLE_REF_CODE',
                    'V_ITEM_MASTER,PACKITEM,ITEM_SUPP_COUNTRY,ITEM_SUPPLIER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   close C_CHECK_STYLE_REF_CODE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_VLD_STYLE_REF_CODE_PACK;
---------------------------------------------------------------------------------------------
-- Name   :  TSL_VLD_STYLE_REF_CODE_TRAN
-- Purpose: To validate whether the input Style Reference Code exists in the system for
--          a simple pack with at least one supplier which is same as the complex pack
---------------------------------------------------------------------------------------------
FUNCTION TSL_VLD_STYLE_REF_CODE_TRAN (O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                      O_valid          IN OUT  BOOLEAN,
                                      I_Style_Ref_Code IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(70)       := 'FILTER_LOV_VALIDATE_SQL.TSL_VALIDATE_STYLE_REF_CODE_TRAN';
   L_exist        VARCHAR2(1);

   CURSOR C_CHECK_STYLE_REF_CODE is
   select 'X'
     from item_master im
    --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
    where UPPER(im.item_desc_secondary) = UPPER(I_style_ref_code)
      --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End
      and item_level<= tran_level;

BEGIN

   if I_Style_Ref_Code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_Style_Ref_Code,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   open C_CHECK_STYLE_REF_CODE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   fetch C_CHECK_STYLE_REF_CODE into L_exist;
   if L_exist is NULL then
      O_valid := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            I_Style_Ref_Code,
                                            NULL,
                                            NULL);
   else
      O_valid := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   close C_CHECK_STYLE_REF_CODE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_VLD_STYLE_REF_CODE_TRAN;
---------------------------------------------------------------------------------------------
--CR332, Accenture/Bijaya Kumar Behera, Bijayakumar.Behera@in.tesco.com, 01-Nov-2010, End
---------------------------------------------------------------------------------------------
--Function Name : TSL_VLD_STYLE_REF_CODE
--Purpose       : CR332 - To validate the input style reference code
---------------------------------------------------------------------------------------------
FUNCTION TSL_VLD_STYLE_REF_CODE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                O_valid          IN OUT  BOOLEAN,
                                I_Supplier       IN      ITEM_SUPPLIER.SUPPLIER%TYPE,
                                I_Style_Ref_Code IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
RETURN BOOLEAN IS
   L_program      VARCHAR2(60)       := 'FILTER_LOV_VALIDATE_SQL.TSL_VALIDATE_STYLE_REF_CODE';
   L_exist        VARCHAR2(1);
   CURSOR C_CHECK_STYLEREF is
   select 'X'
     from item_master im
    --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
    where UPPER(item_desc_secondary) = UPPER(I_style_ref_code)
      --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End
      and simple_pack_ind = 'Y'
      and item_level = tran_level
      --23-Dec-2010 Suman Guha Mustafi, suman.mustafi@in.tesco.com fixed Defect: NBS00020253 Begin
      --and status = 'A'
      --23-Dec-2010 Suman Guha Mustafi, suman.mustafi@in.tesco.com fixed Defect: NBS00020253 End
      and exists (select 'X'
                    from item_supplier isp
                   where isp.item = im.item
                     and isp.supplier = I_supplier)
   union
  select 'X'
    from item_master im
    --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
    where UPPER(item_desc_secondary) = UPPER(I_style_ref_code)
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End
     and simple_pack_ind = 'N'
     and item_level = tran_level
     --23-Dec-2010 Suman Guha Mustafi, suman.mustafi@in.tesco.com fixed Defect: NBS00020253 Begin
     --and status = 'A'
     --23-Dec-2010 Suman Guha Mustafi, suman.mustafi@in.tesco.com fixed Defect: NBS00020253 End
     and exists (select 'X'
                   from item_supplier isp
                   where isp.item = im.item
                     and isp.supplier = I_supplier)
      and exists (select 'X'
                    from  packitem p
                   where p.item=im.item)
   union
   select 'X'
     from item_master im
    where simple_pack_ind = 'N'
      and item_level = tran_level
      and item_parent in (select item
                            from item_master
                           --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
                           where UPPER(item_desc_secondary) = UPPER(I_style_ref_code)
                           --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End
                             and item_level < tran_level
                             and simple_pack_ind = 'N')
      --23-Dec-2010 Suman Guha Mustafi, suman.mustafi@in.tesco.com fixed Defect: NBS00020253 Begin
      --and status = 'A'
      --23-Dec-2010 Suman Guha Mustafi, suman.mustafi@in.tesco.com fixed Defect: NBS00020253 End
      and exists (select 'X'
                    from item_supplier isp
                   where isp.item = im.item
                     and isp.supplier = I_supplier)
      and exists (select 'X'
                   from  packitem p
                   where p.item=im.item);
BEGIN
   O_valid := FALSE;
   if I_Style_Ref_Code is NOT NULL and I_supplier is NOT NULL then
         open C_CHECK_STYLEREF;
         fetch C_CHECK_STYLEREF into L_exist;
         if C_CHECK_STYLEREF%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',I_Style_Ref_Code, NULL, NULL);
            return FALSE;
         else
            O_valid := TRUE;
            return TRUE;
         end if;
         close C_CHECK_STYLEREF;
   else
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                         I_Style_Ref_Code,
                                         L_program,
                                         NULL);
      return FALSE;
      O_valid := FALSE;
   end if;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VLD_STYLE_REF_CODE;
---------------------------------------------------------------------------------------------
--CR332, Accenture/Sanju Natarajan, Sanju.Natarajan@in.tesco.com, 25-Nov-2010, End
---------------------------------------------------------------------------------------------
FUNCTION TSL_VLD_STYLE_REF_CODE_SCA(O_error_message    IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                     O_valid           IN OUT  BOOLEAN,
                                     I_Style_Ref_Code  IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                                     I_Location_access IN      VARCHAR2)
RETURN BOOLEAN IS
   L_program      VARCHAR2(60)       := 'FILTER_LOV_VALIDATE_SQL.TSL_VLD_STYLE_REF_CODE_SCA';
   L_exist        VARCHAR2(1);
   CURSOR C_CHECK_STYLE_REF_CODE is
   select 'X'
     from item_master im
    --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
    where UPPER(im.item_desc_secondary) = UPPER(I_style_ref_code)
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End
      and (im.tsl_owner_country=I_location_access or I_location_access='B' or I_location_access='N')
      --10-Dec-2010 Tesco HSC/Usha Patil              Defect: NBS00020077 Begin
      and im.item_level = im.tran_level
      and ((im.tran_level = 2
          and exists (select 1
                        from packitem pai
                       where pai.item = im.item))
       or (im.tran_level = 1
          and im.simple_pack_ind = 'N'));
      --10-Dec-2010 Tesco HSC/Usha Patil              Defect: NBS00020077 End
BEGIN
   if I_Style_Ref_Code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_Style_Ref_Code,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   open C_CHECK_STYLE_REF_CODE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code
                    );
   fetch C_CHECK_STYLE_REF_CODE into L_exist;
   if L_exist is NULL then
      O_valid := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            I_Style_Ref_Code,
                                            NULL,
                                            NULL);
   else
      O_valid := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   close C_CHECK_STYLE_REF_CODE;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VLD_STYLE_REF_CODE_SCA;
---------------------------------------------------------------------------------------------
--Function Name : TSL_VLD_STYLE_REF_CODE_TPNB
--Purpose       : Def  To validate the input style reference code
---------------------------------------------------------------------------------------------
-- DefNBS00020075, Accenture/Veena Nanjundaiah, veena.nanjundaiah@in.tesco.com, 13-01-2011, Begin
FUNCTION TSL_VLD_STYLE_REF_CODE_TPNB(O_error_message    IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                     O_valid            IN OUT  BOOLEAN,
                                     I_Style_Ref_Code   IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                                     I_Location_access  IN      VARCHAR2)
RETURN BOOLEAN IS
   L_program      VARCHAR2(60)       := 'FILTER_LOV_VALIDATE_SQL.TSL_VLD_STYLE_REF_CODE_TPNB';
   L_exist        VARCHAR2(1);
   CURSOR C_CHECK_STYLE_REF_CODE is
   select 'X'
     from item_master im
    --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, Begin
    where UPPER(im.item_desc_secondary) = UPPER(I_style_ref_code)
     --DefNBS021474, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 09-Feb-2011, End
      and (im.tsl_owner_country=I_location_access or I_location_access='B' or I_location_access='N')
      and im.item_level = im.tran_level
      and ((im.tran_level = 2
          and im.item = im.tsl_base_item
          and exists (select 1
                        from packitem pai
                       where pai.item = im.item))
       or (im.tran_level = 1
          and im.simple_pack_ind = 'N'));
BEGIN
   if I_Style_Ref_Code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_Style_Ref_Code,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   open C_CHECK_STYLE_REF_CODE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code
                    );
   fetch C_CHECK_STYLE_REF_CODE into L_exist;
   if L_exist is NULL then
      O_valid := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            I_Style_Ref_Code,
                                            NULL,
                                            NULL);
   else
      O_valid := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_STYLE_REF_CODE',
                    'ITEM_MASTER',
                    'item_desc_secondary: '|| I_Style_Ref_Code);
   close C_CHECK_STYLE_REF_CODE;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VLD_STYLE_REF_CODE_TPNB;
-- DefNBS00020075, Accenture/Veena Nanjundaiah, veena.nanjundaiah@in.tesco.com, 13-01-2011, End
---------------------------------------------------------------------------------------------
-- DefNBS00020217, 22-Dec-2010, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, Begin
-----------------------------------------------------------------------------------------------------
-- Function Name   :  TSL_VALID_STYLE_REF_CODE
-- Purpose         :  To validate the input Style Reference Code whether it occurs in simple packs
---------------------------------------------------------------------------------------------------
FUNCTION TSL_VALID_STYLE_REF_CODE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_valid          IN OUT  BOOLEAN,
                                  I_Style_Ref_Code IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
RETURN BOOLEAN IS

   L_program          VARCHAR2(60)  := 'FILTER_LOV_VALIDATE_SQL.TSL_VALID_STYLE_REF_CODE';
   L_exist            VARCHAR2(1);
   L_location_access  VARCHAR2(1)   := 'N';
   L_error_message    RTK_ERRORS.RTK_TEXT%TYPE;

    -- DefNBS022386, 21-Apr-2011, Sripriya,Sripriya.karanam@in.tesco.com, Begin
   CURSOR C_CHECK_SIMPLE_PACK(cp_location_access VARCHAR2) is
    -- DefNBS022386, 21-Apr-2011, Sripriya,Sripriya.karanam@in.tesco.com, End
   select 'X'
     -- DefNBS022386, 21-Apr-2011, Sripriya,Sripriya.karanam@in.tesco.com, Begin
     from v_item_master im,
     item_master it
     -- DefNBS022386, 21-Apr-2011, Sripriya,Sripriya.karanam@in.tesco.com, End
     --Def: NBS00020631, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 24-Jan-2011, Begin
    where UPPER(im.item_desc_secondary) = UPPER(I_style_ref_code)
     --Def: NBS00020631, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 24-Jan-2011, End
      and im.pack_ind = 'Y'
      and im.simple_pack_ind = 'Y'
      and im.tran_level = 1
      and im.item_level = 1
      -- DefNBS022386, 21-Apr-2011, Sripriya,Sripriya.karanam@in.tesco.com, Begin
      and im.item = it.item
      and it.tsl_owner_country = Decode(cp_location_access,'U','U','R','R','B',it.tsl_owner_country);
      -- DefNBS022386, 21-Apr-2011, Sripriya,Sripriya.karanam@in.tesco.com, End

BEGIN

   O_valid := FALSE;
   if I_Style_Ref_Code is NOT NULL then
      if TSL_RP_STYLE_REF_CODE.GET_USER_LOCATION(L_error_message,
                                                 L_location_access) = FALSE then
         return FALSE;
      end if;
       -- DefNBS022386, 21-Apr-2011, Sripriya,Sripriya.karanam@in.tesco.com, Begin
      open C_CHECK_SIMPLE_PACK(L_location_access);
       -- DefNBS022386, 21-Apr-2011, Sripriya,Sripriya.karanam@in.tesco.com, End
      fetch C_CHECK_SIMPLE_PACK into L_exist;
      if L_exist is NULL then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                               I_Style_Ref_Code,
                                               NULL,
                                               NULL);
	    else
         O_valid := TRUE;
      end if;
      close C_CHECK_SIMPLE_PACK;

   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_VALID_STYLE_REF_CODE;
-----------------------------------------------------------------------------------------------------
-- DefNBS00020217, 22-Dec-2010, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, End
-----------------------------------------------------------------------------------------------------
END FILTER_LOV_VALIDATE_SQL;
/

