CREATE OR REPLACE PACKAGE BODY COUNTRY_VALIDATE_SQL AS

------------------------------------------------------------------------------
FUNCTION EXISTS_ON_TABLE(I_country_id    IN     country.country_id%TYPE,
                         I_table         IN     VARCHAR2,
                         O_error_message IN OUT VARCHAR2,
                         O_exists IN OUT BOOLEAN)
   RETURN BOOLEAN IS
   L_dummy VARCHAR2(1);
   L_program  VARCHAR2(64) := 'COUNTRY_VALIDATE_SQL.EXISTS_ON_TABLE';

   cursor C_COUNTRY_ID1 is
      select 'x'
        from COUNTRY
       where country_id = I_country_id;

   cursor C_COUNTRY_ID2 is
      select 'x'
        from addr
       where country_id = I_country_id;

BEGIN
   if I_table = 'COUNTRY' then
      open  C_COUNTRY_ID1;
      fetch C_COUNTRY_ID1 into L_dummy;
      if C_COUNTRY_ID1%FOUND then
         close C_COUNTRY_ID1;
         O_exists := TRUE;
      else
        O_exists := FALSE;
        close C_COUNTRY_ID1;
      end if;

   elsif I_table = 'ADDR' then
      open  C_COUNTRY_ID2;
      fetch C_COUNTRY_ID2 into L_dummy;
      if C_COUNTRY_ID2%FOUND then
         close C_COUNTRY_ID2;
         O_exists := TRUE;
      else
        O_exists := FALSE;
        close C_COUNTRY_ID2;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,L_program,NULL);
      return FALSE;
END EXISTS_ON_TABLE;

-----------------------------------------------------------------------------
FUNCTION CONSTRAINTS_EXIST(I_Foreign_Constraints  IN country.country_id%TYPE,
                           O_error_message 	  IN OUT VARCHAR2,
                           O_found                IN OUT BOOLEAN)
   RETURN BOOLEAN IS

   L_program VARCHAR2(64) := 'COUNTRY_VALIDATE_SQL.CONSTRAINTS_EXIST';
   L_dummy   VARCHAR2(1);

   cursor C_ORD is
      select 'x'
        from ordhead
       where import_country_id = I_Foreign_Constraints;

   cursor C_ADDR is
      select 'x'
        from addr
       where country_id = I_Foreign_Constraints;

   cursor C_CONTRACT_HEADER is
      select 'x'
        from contract_header
       where country_id = I_Foreign_Constraints;

   cursor C_COST is
      select 'x'
        from cost_susp_sup_detail
       where origin_country_id = I_Foreign_Constraints;

   cursor C_ELC_COMP is
      select 'x'
        from elc_comp
       where import_country_id = I_Foreign_Constraints;

   cursor C_EXP_PROF is
      select 'x'
        from exp_prof_head
       where origin_country_id = I_Foreign_Constraints;

   cursor C_HTS is
      select 'x'
        from hts
       where import_country_id = I_Foreign_Constraints;

   cursor C_HTS_AD is
      select 'x'
        from hts_ad
       where origin_country_id = I_Foreign_Constraints;

   cursor C_HTS_CHAP is
      select 'x'
        from hts_chapter_restraints
       where origin_country_id = I_Foreign_Constraints
          or import_country_id = I_Foreign_Constraints;

   cursor C_HTS_CVD is
      select 'x'
        from hts_cvd
       where origin_country_id = I_Foreign_Constraints;

   cursor C_ITEM_EXP is
      select 'x'
        from item_exp_head
       where origin_country_id = I_Foreign_Constraints;

   cursor C_ITEM_HTS is
      select 'x'
        from item_hts
       where origin_country_id = I_Foreign_Constraints;

   cursor C_ITEM_SUP is
      select 'x'
        from item_supp_country
       where origin_country_id = I_Foreign_Constraints;

   cursor C_ORDCUST is
      select 'x'
        from ordcust
       where deliver_country_id = I_Foreign_Constraints;

   cursor C_ORDLOC_W is
      select 'x'
        from ordloc_wksht
       where origin_country_id = I_Foreign_Constraints;

   cursor C_ORDSKU is
      select 'x'
        from ordsku
       where origin_country_id = I_Foreign_Constraints;

   cursor C_OUTLOC is
      select 'x'
        from outloc
       where outloc_country_id = I_Foreign_Constraints;

   cursor C_PARTNER is
      select 'x'
        from partner
       where principle_country_id = I_Foreign_Constraints;

   cursor C_QUOTA is
      select 'x'
        from quota_category
       where import_country_id = I_Foreign_Constraints;

   cursor C_RTV_HEAD is
      select 'x'
        from rtv_head
       where ship_to_country_id = I_Foreign_Constraints;

   cursor C_SYSTEM is
      select 'x'
        from system_options
       where base_country_id = I_Foreign_Constraints;


BEGIN
   O_found := False;

   open C_ORD;
   fetch C_ORD into L_dummy;
   if C_ORD%FOUND then
      close C_ORD;
      O_found := TRUE;
      return TRUE;
   else
      close C_ORD;
   end if;

   open C_ADDR;
   fetch C_ADDR into L_dummy;
   if C_ADDR%FOUND then
      close C_ADDR;
      O_found := TRUE;
      return TRUE;
   else
      close C_ADDR;
   end if;

   open C_CONTRACT_HEADER;
   fetch C_CONTRACT_HEADER into L_dummy;
   if C_CONTRACT_HEADER%FOUND then
      close C_CONTRACT_HEADER;
      O_found := TRUE;
      return TRUE;
   else
      close C_CONTRACT_HEADER;
   end if;

   open C_COST;
   fetch C_COST into L_dummy;
   if C_COST%FOUND then
      close C_COST;
      O_found := TRUE;
      return TRUE;
   else
       close C_COST;
   end if;

   open C_ELC_COMP;
   fetch C_ELC_COMP into L_dummy;
   if C_ELC_COMP%FOUND then
      close C_ELC_COMP;
      O_found := TRUE;
      return TRUE;
   else
       close C_ELC_COMP;
   end if;

   open C_EXP_PROF;
   fetch C_EXP_PROF into L_dummy;
   if C_EXP_PROF%FOUND then
      close C_EXP_PROF;
      O_found := TRUE;
      return TRUE;
   else
      close C_EXP_PROF;
   end if;

   open C_HTS;
   fetch C_HTS into L_dummy;
   if C_HTS%FOUND then
      close C_HTS;
      O_found := TRUE;
      return TRUE;
   else
      close C_HTS;
   end if;

   open C_HTS_AD;
   fetch C_HTS_AD into L_dummy;
   if C_HTS_AD%FOUND then
      close C_HTS_AD;
      O_found := TRUE;
      return TRUE;
   else
      close C_HTS_AD;
   end if;

   open C_HTS_CHAP;
   fetch C_HTS_CHAP into L_dummy;
   if C_HTS_CHAP%FOUND then
      close C_HTS_CHAP;
      O_found := TRUE;
      return TRUE;
   else
      close C_HTS_CHAP;
   end if;

   open C_HTS_CVD;
   fetch C_HTS_CVD into L_dummy;
   if C_HTS_CVD%FOUND then
      close C_HTS_CVD;
      O_found := TRUE;
      return TRUE;
   else
      close C_HTS_CVD;
   end if;

   open C_ITEM_EXP;
   fetch C_ITEM_EXP into L_dummy;
   if C_ITEM_EXP%FOUND then
      close C_ITEM_EXP;
      O_found := TRUE;
      return TRUE;
   else
      close C_ITEM_EXP;
   end if;

   open C_ITEM_HTS;
   fetch C_ITEM_HTS into L_dummy;
   if C_ITEM_HTS%FOUND then
      close C_ITEM_HTS;
      O_found := TRUE;
      return TRUE;
   else
      close C_ITEM_HTS;
   end if;

   open C_ITEM_SUP;
   fetch C_ITEM_SUP into L_dummy;
   if C_ITEM_SUP%FOUND then
      close C_ITEM_SUP;
      O_found := TRUE;
      return TRUE;
   else
      close C_ITEM_SUP;
   end if;

   open C_ORDCUST;
   fetch C_ORDCUST into L_dummy;
   if C_ORDCUST%FOUND then
      close C_ORDCUST;
      O_found := TRUE;
      return TRUE;
   else
      close C_ORDCUST;
   end if;

   open C_ORDLOC_W;
   fetch C_ORDLOC_W into L_dummy;
   if C_ORDLOC_W%FOUND then
      close C_ORDLOC_W;
      O_found := TRUE;
      return TRUE;
   else
      close C_ORDLOC_W;
   end if;

   open C_ORDSKU;
   fetch C_ORDSKU into L_dummy;
   if C_ORDSKU%FOUND then
      close C_ORDSKU;
      O_found := TRUE;
      return TRUE;
   else
      close C_ORDSKU;
   end if;

   open C_OUTLOC;
   fetch C_OUTLOC into L_dummy;
   if C_OUTLOC%FOUND then
      close C_OUTLOC;
      O_found := TRUE;
      return TRUE;
   else
      close C_OUTLOC;
   end if;

   open C_PARTNER;
   fetch C_PARTNER into L_dummy;
   if C_PARTNER%FOUND then
      close C_PARTNER;
      O_found := TRUE;
      return TRUE;
   else
      close C_PARTNER;
   end if;

   open C_QUOTA;
   fetch C_QUOTA into L_dummy;
   if C_QUOTA%FOUND then
      close C_QUOTA;
      O_found := TRUE;
      return TRUE;
   else
      close C_QUOTA;
   end if;

   open C_RTV_HEAD;
   fetch C_RTV_HEAD into L_dummy;
   if C_RTV_HEAD%FOUND then
      close C_RTV_HEAD;
      O_found := TRUE;
      return TRUE;
   else
      close C_RTV_HEAD;
   end if;
   open C_SYSTEM;
   fetch C_SYSTEM into L_dummy;
   if C_SYSTEM%FOUND then
      close C_SYSTEM;
      O_found := TRUE;
      return TRUE;
   else
      close C_SYSTEM;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                             L_program,to_char(SQLCODE));
      return FALSE;
END CONSTRAINTS_EXIST;
-------------------------------------------------------------------------------------------
FUNCTION GET_NAME(O_error_message    IN OUT VARCHAR2,
                  I_country_id       IN     country.country_id%TYPE,
                  O_country_desc     IN OUT VARCHAR2)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64)  := 'COUNTRY_VALIDATE_SQL.GET_NAME';
   L_country_desc  country.country_desc%TYPE := NULL;

   cursor C_COUNTRY is
      select country_desc
        from country
       where country_id = I_country_id;

BEGIN
   open C_COUNTRY;
   fetch C_COUNTRY into L_country_desc;
   if C_COUNTRY%NOTFOUND then
       O_error_message := sql_lib.create_msg('INV_COUNTRY',
                                              NULL, NULL, NULL);
       close C_COUNTRY;
       return FALSE;
   end if;
   close C_COUNTRY;

   if LANGUAGE_SQL.TRANSLATE(L_country_desc,
                             O_country_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                             L_program,to_char(SQLCODE));
            return FALSE;
END GET_NAME;
------------------------------------------------------------------------------

END COUNTRY_VALIDATE_SQL;
/

