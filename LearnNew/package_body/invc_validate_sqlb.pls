CREATE OR REPLACE PACKAGE BODY INVC_VALIDATE_SQL AS
-------------------------------------------------------------------------------------------
FUNCTION INVC_EXIST (O_error_message   IN OUT  VARCHAR2,
                     O_exists          IN OUT  BOOLEAN,
                     I_invc_id         IN      INVC_HEAD.INVC_ID%TYPE)

   RETURN BOOLEAN IS
   L_exists          VARCHAR2(1);

   cursor C_INVC_EXIST is
      select 'x'
        from invc_head
       where invc_id = I_invc_id;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_VALIDATE_SQL.INVC_EXIST',
                                            NULL);
         return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_INVC_EXIST',
                    'invc_head',
                    'Invoice Id:'||to_char(I_invc_id));
   open C_INVC_EXIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVC_EXIST',
                    'invc_head',
                    'Invoice Id:'||to_char(I_invc_id));
   fetch C_INVC_EXIST into L_exists;
   if C_INVC_EXIST%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVC_EXIST',
                    'invc_head',
                    'Invoice Id:'||to_char(I_invc_id));
   close C_INVC_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.INVC_EXIST',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END INVC_EXIST;
-------------------------------------------------------------------------------------------
FUNCTION CHECK_LIMITS (O_error_message   IN OUT  VARCHAR2,
                       O_lower_overlap   IN OUT  BOOLEAN,
                       O_upper_overlap   IN OUT  BOOLEAN,
                       O_full_overlap    IN OUT  BOOLEAN,
                       I_supplier        IN      SUP_TOLERANCE.SUPPLIER%TYPE,
                       I_lower_limit     IN      SUP_TOLERANCE.LOWER_LIMIT%TYPE,
                       I_upper_limit     IN      SUP_TOLERANCE.UPPER_LIMIT%TYPE,
                       I_tolerance_level IN      SUP_TOLERANCE.TOLERANCE_LEVEL%TYPE,
                       I_tolerance_favor IN      SUP_TOLERANCE.TOLERANCE_FAVOR%TYPE,
                       I_tolerance_type  IN      SUP_TOLERANCE.TOLERANCE_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_lower_match          VARCHAR2(1);
   L_upper_match          VARCHAR2(1);
   L_full_overlap         VARCHAR2(1);

   cursor C_DEF_TOL_LOWER is
      select 'x'
        from invc_default_tolerance
       where tolerance_level = I_tolerance_level
         and tolerance_favor = I_tolerance_favor
         and tolerance_type  = I_tolerance_type
         and I_lower_limit between lower_limit and upper_limit;

   cursor C_DEF_TOL_UPPER is
      select 'x'
        from invc_default_tolerance
       where tolerance_level = I_tolerance_level
         and tolerance_favor = I_tolerance_favor
         and tolerance_type  = I_tolerance_type
         and I_upper_limit between lower_limit and upper_limit;

   cursor C_DEF_TOL_FULL_OVERLAP is
      select 'x'
        from invc_default_tolerance
       where tolerance_level = I_tolerance_level
         and tolerance_favor = I_tolerance_favor
         and tolerance_type  = I_tolerance_type
         and (lower_limit > I_lower_limit and upper_limit < I_upper_limit);

   ---
   cursor C_SUP_TOL_LOWER is
      select 'x'
        from sup_tolerance
       where supplier = I_supplier
         and tolerance_level = I_tolerance_level
         and tolerance_favor = I_tolerance_favor
         and tolerance_type  = I_tolerance_type
         and I_lower_limit between lower_limit and upper_limit;

   cursor C_SUP_TOL_UPPER is
      select 'x'
        from sup_tolerance
       where supplier = I_supplier
         and tolerance_level = I_tolerance_level
         and tolerance_favor = I_tolerance_favor
         and tolerance_type  = I_tolerance_type
         and I_upper_limit between lower_limit and upper_limit;

   cursor C_SUP_TOL_FULL_OVERLAP is
      select 'x'
        from sup_tolerance
       where supplier = I_supplier
         and tolerance_level = I_tolerance_level
         and tolerance_favor = I_tolerance_favor
         and tolerance_type  = I_tolerance_type
         and (lower_limit > I_lower_limit and upper_limit < I_upper_limit);

BEGIN

   if I_lower_limit is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_lower_limit',
                                            'INVC_VALIDATE_SQL.CHECK_LIMITS',
                                            NULL);
         return FALSE;
   elsif I_upper_limit is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_upper_limit',
                                            'INVC_VALIDATE_SQL.CHECK_LIMITS',
                                            NULL);
         return FALSE;
   elsif I_tolerance_level is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tolerance_level',
                                            'INVC_VALIDATE_SQL.CHECK_LIMITS',
                                            NULL);
         return FALSE;
   elsif I_tolerance_favor is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tolerance_favor',
                                            'INVC_VALIDATE_SQL.CHECK_LIMITS',
                                            NULL);
         return FALSE;
   elsif I_tolerance_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tolerance_type',
                                            'INVC_VALIDATE_SQL.CHECK_LIMITS',
                                            NULL);
         return FALSE;
   end if;

   if I_supplier is NULL then  -- if supplier null, use invc_default_tolerance table

      open C_DEF_TOL_LOWER;
      fetch C_DEF_TOL_LOWER into L_lower_match;
      if C_DEF_TOL_LOWER%FOUND then
         close C_DEF_TOL_LOWER;
         O_lower_overlap := TRUE;
         return TRUE;
      end if;

      close C_DEF_TOL_LOWER;
      ---
      open C_DEF_TOL_UPPER;
      fetch C_DEF_TOL_UPPER into L_upper_match;
      if C_DEF_TOL_UPPER%FOUND then
         close C_DEF_TOL_UPPER;
         O_upper_overlap := TRUE;
         return TRUE;
      end if;

      close C_DEF_TOL_UPPER;
      ---
      open C_DEF_TOL_FULL_OVERLAP;
      fetch C_DEF_TOL_FULL_OVERLAP into L_full_overlap;
      if C_DEF_TOL_FULL_OVERLAP%FOUND then
         close C_DEF_TOL_FULL_OVERLAP;
         O_full_overlap := TRUE;
         return TRUE;
      end if;

      close C_DEF_TOL_FULL_OVERLAP;

   else  --if the supplier is entered then it uses the sup_tolerance tables

      open C_SUP_TOL_LOWER;
      fetch C_SUP_TOL_LOWER into L_lower_match;
      if C_SUP_TOL_LOWER%FOUND then
         close C_SUP_TOL_LOWER;
         O_lower_overlap := TRUE;
         return TRUE;
      end if;

      close C_SUP_TOL_LOWER;
      ---
      open C_SUP_TOL_UPPER;
      fetch C_SUP_TOL_UPPER into L_upper_match;
      if C_SUP_TOL_UPPER%FOUND then
         close C_SUP_TOL_UPPER;
         O_upper_overlap := TRUE;
         return TRUE;
      end if;

      close C_SUP_TOL_UPPER;
      ---
      open C_SUP_TOL_FULL_OVERLAP;
      fetch C_SUP_TOL_FULL_OVERLAP into L_full_overlap;
      if C_SUP_TOL_FULL_OVERLAP%FOUND then
         close C_SUP_TOL_FULL_OVERLAP;
         O_full_overlap := TRUE;
         return TRUE;
      end if;

      close C_SUP_TOL_FULL_OVERLAP;

   end if;

   O_lower_overlap := FALSE;
   O_upper_overlap := FALSE;
   O_full_overlap  := FALSE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.CHECK_LIMITS',
                                             TO_CHAR(SQLCODE));
      return FALSE;

END CHECK_LIMITS;
-------------------------------------------------------------------------------------------
FUNCTION MATCH_RCPT (O_error_message  IN OUT  VARCHAR2,
                     O_valid          IN OUT  BOOLEAN,
                     I_rcpt           IN      INVC_MATCH_WKSHT.SHIPMENT%TYPE,
                     I_invc_id        IN      INVC_MATCH_WKSHT.INVC_ID%TYPE,
                     I_item           IN      INVC_MATCH_WKSHT.ITEM%TYPE,
                     I_carton         IN      INVC_MATCH_WKSHT.CARTON%TYPE)

   RETURN BOOLEAN IS

   L_match_invc_id            shipsku.match_invc_id%TYPE;

   cursor C_MATCH_RCPT is
      select match_invc_id
        from shipsku
       where shipment = I_rcpt
         and item     = I_item
         and (carton  = I_carton
              or (carton is NULL and I_carton is NULL));
BEGIN

   if I_rcpt is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_rcpt',
                                            'INVC_VALIDATE_SQL.MATCH_RCPT',
                                            NULL);
         return FALSE;
   elsif I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_VALIDATE_SQL.MATCH_RCPT',
                                            NULL);
         return FALSE;
   elsif I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            'INVC_VALIDATE_SQL.MATCH_RCPT',
                                            NULL);
         return FALSE;
   end if;

   open C_MATCH_RCPT;

   fetch C_MATCH_RCPT into L_match_invc_id;
   if C_MATCH_RCPT%NOTFOUND then
      O_valid := FALSE;
   elsif L_match_invc_id is NOT NULL and L_match_invc_id != I_invc_id then
      O_valid := FALSE;
   else
      O_valid := TRUE;
   end if;

   close C_MATCH_RCPT;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.MATCH_RCPT',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END MATCH_RCPT;
----------------------------------------------------------------------------------
FUNCTION CHECK_MAX_DBT_PCT(O_error_message  IN OUT  VARCHAR2,
                           O_over_max_dbt   IN OUT  BOOLEAN,
                           I_invc_id        IN      INVC_HEAD.INVC_ID%TYPE)
   RETURN BOOLEAN is

   L_max_dbt_pct           SYSTEM_OPTIONS.INVC_DBT_MAX_PCT%TYPE;
   L_max_sum_costs         INVC_HEAD.TOTAL_MERCH_COST%TYPE;
   L_total_invc_cost       INVC_HEAD.TOTAL_MERCH_COST%TYPE;
   L_dbt_cost              INVC_HEAD.TOTAL_MERCH_COST%TYPE;
   L_crdt_cost             INVC_HEAD.TOTAL_MERCH_COST%TYPE;
   L_sum_dbt_costs         INVC_HEAD.TOTAL_MERCH_COST%TYPE := 0;

   cursor C_GET_MAX_DBT_PCT is
      select invc_dbt_max_pct
        from system_options;

   cursor C_DBT_CRDTS is
      select invc_id
        from invc_head
       where ref_invc_id = I_invc_id
         and invc_type in ('D','R');

   cursor C_CRDT_MEMOS is
      select invc_id
        from invc_head
       where ref_invc_id = I_invc_id
         and invc_type   = ('M');

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_MAX_DBT_PCT',
                    'system_options',
                    NULL);
   open C_GET_MAX_DBT_PCT;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_MAX_DBT_PCT',
                    'system_options',
                    NULL);

   fetch C_GET_MAX_DBT_PCT into L_max_dbt_pct;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_MAX_DBT_PCT',
                    'system_options',
                    NULL);
   close C_GET_MAX_DBT_PCT;
   ---
   if INVC_ATTRIB_SQL.TOTAL_INVC_COST(O_error_message,
                                      L_total_invc_cost,
                                      I_invc_id,
                                      'N',
                                      'N') = FALSE then
      return FALSE;
   end if;
   ---
   L_max_sum_costs := L_total_invc_cost * (L_max_dbt_pct/100);
   ---
   FOR recs in C_DBT_CRDTS LOOP
      if INVC_ATTRIB_SQL.TOTAL_INVC_COST(O_error_message,
                                         L_dbt_cost,
                                         recs.invc_id,
                                         'N',
                                         'N') = FALSE then
         return FALSE;
      end if;
      ---
      L_sum_dbt_costs := L_sum_dbt_costs + NVL(L_dbt_cost,0);
   END LOOP;
   ---
   FOR rec in C_CRDT_MEMOS LOOP
      if INVC_ATTRIB_SQL.TOTAL_INVC_COST(O_error_message,
                                         L_crdt_cost,
                                         rec.invc_id,
                                         'N',
                                         'N') = FALSE then
         return FALSE;
      end if;
      ---
      L_sum_dbt_costs := L_sum_dbt_costs - NVL(L_crdt_cost,0);
   END LOOP;
   ---
   if (L_sum_dbt_costs > L_max_sum_costs) then
      O_over_max_dbt := TRUE;
   else
      O_over_max_dbt := FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.CHECK_MAX_DBT_PCT',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_MAX_DBT_PCT;
---------------------------------------------------------------------------------------------
FUNCTION RECONCILE_DETAILS(O_error_message      IN OUT VARCHAR2,
                           I_invc_id            IN     INVC_HEAD.INVC_ID%TYPE)
   RETURN BOOLEAN is

   L_head_cost      INVC_HEAD.TOTAL_MERCH_COST%TYPE;
   L_detail_cost    INVC_DETAIL.INVC_UNIT_COST%TYPE := 0;

   cursor C_INVC_HEAD is
      select total_merch_cost
        from invc_head
       where invc_id = I_invc_id;

   cursor C_INVC_DETAIL is
      select sum(invc_unit_cost * invc_qty)
        from invc_detail
       where invc_id = I_invc_id;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_VALIDATE_SQL.RECONCILE_DETAILS',
                                            NULL);
         return FALSE;
   end if;

   --- Get the totals from invc_head.
   SQL_LIB.SET_MARK('OPEN', 'C_INVC_HEAD', 'invc_head', 'Invoice:'||to_char(I_invc_id));
   open C_INVC_HEAD;
   SQL_LIB.SET_MARK('FETCH', 'C_INVC_HEAD', 'invc_head', 'Invoice:'||to_char(I_invc_id));
   fetch C_INVC_HEAD into L_head_cost;
   if C_INVC_HEAD%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_INVC_HEAD', 'invc_head', 'Invoice:'||to_char(I_invc_id));
      close C_INVC_HEAD;
      O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_INFO', NULL, NULL, NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_INVC_HEAD', 'invc_head', 'Invoice:'||to_char(I_invc_id));
   close C_INVC_HEAD;

   --- Get the totals from invc_detail.
   SQL_LIB.SET_MARK('OPEN', 'C_INVC_DETAIL', 'invc_detail', 'Invoice:'||to_char(I_invc_id));
   open C_INVC_DETAIL;
   SQL_LIB.SET_MARK('FETCH', 'C_INVC_DETAIL', 'invc_detail', 'Invoice:'||to_char(I_invc_id));
   fetch C_INVC_DETAIL into L_detail_cost;
   SQL_LIB.SET_MARK('CLOSE', 'C_INVC_DETAIL', 'invc_detail', 'Invoice:'||to_char(I_invc_id));
   close C_INVC_DETAIL;

   if L_detail_cost is NOT NULL and L_detail_cost != L_head_cost then
      O_error_message := SQL_LIB.CREATE_MSG('TOT_COST_DISCREPANCY', L_detail_cost, L_head_cost, NULL);
      return FALSE;
   end if;

   --- Costs reconcile so return TRUE.
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_VALIDATE_SQL.RECONCILE_DETAILS',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END RECONCILE_DETAILS;
---------------------------------------------------------------------------------------------
FUNCTION VAL_SERV_PERF_IND(O_error_message      IN OUT  VARCHAR2,
                           O_service_perf_fail  IN OUT  BOOLEAN,
                           I_invc_id            IN      INVC_HEAD.INVC_ID%TYPE,
                           I_supplier           IN      SUPS.SUPPLIER%TYPE,
                           I_partner_id         IN      PARTNER.PARTNER_ID%TYPE,
                           I_partner_type       IN      PARTNER.PARTNER_TYPE%TYPE)
   RETURN BOOLEAN is

   L_supplier                    SUPS.SUPPLIER%TYPE;
   L_partner_id                  PARTNER.PARTNER_ID%TYPE;
   L_partner_type                PARTNER.PARTNER_TYPE%TYPE;
   L_service_req_ind             VARCHAR2(1);
   L_exists                      VARCHAR2(1);

   cursor C_GET_SUPP is
      select supplier,
             partner_id,
             partner_type
        from invc_head
       where invc_id = I_invc_id;

   cursor C_GET_SUPS_SERV_IND is
      select service_perf_req_ind
      from sups
     where supplier = L_supplier;

   cursor C_GET_PARTNER_SERV_IND is
      select service_perf_req_ind
      from partner
     where partner_id   = L_partner_id
       and partner_type = L_partner_type;

   cursor C_VALIDATE_SERV_IND is
      select 'x'
      from invc_non_merch inm,
           non_merch_code_head nmch
     where nmch.service_ind     = 'Y'
       and inm.invc_id          = I_invc_id
       and inm.non_merch_code   = nmch.non_merch_code
       and inm.service_perf_ind = 'N';

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_VALIDATE_SQL.VAL_SERV_PERF_IND',
                                            NULL);
         return FALSE;
   end if;

   if I_supplier is NULL and I_partner_id is NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_SUPP',
                       'invc_head',
                       'invc_id: '||to_char(I_invc_id));
      open C_GET_SUPP;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_SUPP',
                       'invc_head',
                       'invc_id: '||to_char(I_invc_id));
      fetch C_GET_SUPP into L_supplier, L_partner_id, L_partner_type;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_SUPP',
                       'invc_head',
                       'invc_id: '||to_char(I_invc_id));
      close C_GET_SUPP;

   else
      L_supplier     := I_supplier;
      L_partner_id   := I_partner_id;
      L_partner_type := I_partner_type;
   end if;
   ---
   if L_supplier is not null then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_SUPS_SERV_IND',
                       'sups',
                       'supplier: '||to_char(L_supplier));
      open C_GET_SUPS_SERV_IND;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_SUPS_SERV_IND',
                       'sups',
                       'supplier: '||to_char(L_supplier));
      fetch C_GET_SUPS_SERV_IND into L_service_req_ind;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_SUPS_SERV_IND',
                       'sups',
                       'supplier: '||to_char(L_supplier));
      close C_GET_SUPS_SERV_IND;

   else
     SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PARTNER_SERV_IND',
                       'partner',
                       'partner_id: '||L_partner_id);
     open C_GET_PARTNER_SERV_IND;

     SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PARTNER_SERV_IND',
                       'partner',
                       'partner_id: '||L_partner_id);
     fetch C_GET_PARTNER_SERV_IND into L_service_req_ind;

     SQL_LIB.SET_MARK('CLOSE',
                      'C_GET_PARTNER_SERV_IND',
                      'partner',
                      'partner_id: '||L_partner_id);
     close C_GET_PARTNER_SERV_IND;

   end if;
   ---
   if L_service_req_ind = 'N' then
      return TRUE;
   end if;
   ---

   open C_VALIDATE_SERV_IND;
   fetch C_VALIDATE_SERV_IND into L_exists;
       if C_VALIDATE_SERV_IND%FOUND then
          O_service_perf_fail := TRUE;
       else
          O_service_perf_fail := FALSE;
       end if;
   close C_VALIDATE_SERV_IND;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.VAL_SERV_PERF_IND',
                                             TO_CHAR(SQLCODE));
      return FALSE;

END VAL_SERV_PERF_IND;
----------------------------------------------------------------------------------------------
FUNCTION  LC_COMP_NON_MERCH_EXIST(O_error_message   IN OUT  VARCHAR2,
                                  O_exists          IN OUT  BOOLEAN,
                                  I_non_merch_code  IN      NON_MERCH_CODE_COMP.NON_MERCH_CODE%TYPE,
                                  I_comp_id         IN      NON_MERCH_CODE_COMP.COMP_ID%TYPE)

   RETURN BOOLEAN IS

   L_exists          VARCHAR2(1);

   cursor C_LC_COMP_NON_MERCH_EXIST is
      select 'x'
        from  non_merch_code_comp
       where  comp_id         = I_comp_id
         and  non_merch_code  = I_non_merch_code;

BEGIN

   if I_non_merch_code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_non_merch_code',
                                            'INVC_VALIDATE_SQL.LC_COMP_NON_MERCH_EXIST',
                                            NULL);
         return FALSE;
   elsif I_comp_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_comp_id',
                                            'INVC_VALIDATE_SQL.LC_COMP_NON_MERCH_EXIST',
                                            NULL);
         return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_LC_COMP_NON_MERCH_EXIST',
                    'non_merch_code_comp',
                     NULL);
   open C_LC_COMP_NON_MERCH_EXIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_LC_COMP_NON_MERCH_EXIST',
                    'non_merch_code_comp',
                     NULL);
   fetch C_LC_COMP_NON_MERCH_EXIST into L_exists;
   if C_LC_COMP_NON_MERCH_EXIST%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LC_COMP_NON_MERCH_EXIST',
                    'non_merch_code_comp',
                     NULL);
   close C_LC_COMP_NON_MERCH_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.LC_COMP_NON_MERCH_EXIST',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END LC_COMP_NON_MERCH_EXIST;
-----------------------------------------------------------------------------------------
FUNCTION  NON_MERCH_LC_COMP_EXIST(O_error_message   IN OUT  VARCHAR2,
                                  O_exists          IN OUT  BOOLEAN,
                                  I_non_merch_code  IN      INVC_NON_MERCH.NON_MERCH_CODE%TYPE)

   RETURN BOOLEAN IS

   L_exists          VARCHAR2(1);

   cursor C_NON_MERCH_LC_COMP_EXIST is
      select  'x'
        from  non_merch_code_comp
       where  non_merch_code  = I_non_merch_code;

BEGIN

   if I_non_merch_code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_non_merch_code',
                                            'INVC_VALIDATE_SQL.NON_MERCH_LC_COMP_EXIST',
                                            NULL);
         return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_NON_MERCH_LC_COMP_EXIST',
                    'non_merch_code_comp',
                     NULL);
   open C_NON_MERCH_LC_COMP_EXIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_NON_MERCH_LC_COMP_EXIST',
                    'non_merch_code_comp',
                     NULL);
   fetch C_NON_MERCH_LC_COMP_EXIST into L_exists;
   if C_NON_MERCH_LC_COMP_EXIST%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_NON_MERCH_LC_COMP_EXIST',
                    'non_merch_code_comp',
                     NULL);
   close C_NON_MERCH_LC_COMP_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.NON_MERCH_LC_COMP_EXIST',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END NON_MERCH_LC_COMP_EXIST;
-----------------------------------------------------------------------------------------
FUNCTION  NON_MERCH_CODE_EXIST(O_error_message   IN OUT  VARCHAR2,
                               O_exists          IN OUT  BOOLEAN,
                               I_non_merch_code  IN      NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE)

   RETURN BOOLEAN IS

   L_exists          VARCHAR2(1);

   cursor C_NON_MERCH_CODE_EXIST is
      select 'x'
        from  non_merch_code_head
       where  non_merch_code  = I_non_merch_code;

BEGIN

   if I_non_merch_code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_non_merch_code',
                                            'INVC_VALIDATE_SQL.NON_MERCH_CODE_EXIST',
                                            NULL);
         return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_NON_MERCH_CODE_EXIST',
                    'non_merch_code_head',
                     NULL);
   open C_NON_MERCH_CODE_EXIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_NON_MERCH_CODE_EXIST',
                    'non_merch_code_head',
                     NULL);
   fetch C_NON_MERCH_CODE_EXIST into L_exists;
   if C_NON_MERCH_CODE_EXIST%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_NON_MERCH_CODE_EXIST',
                    'non_merch_code_head',
                     NULL);
   close C_NON_MERCH_CODE_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.NON_MERCH_CODE_EXIST',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END NON_MERCH_CODE_EXIST;
-----------------------------------------------------------------------------------------
FUNCTION  INVC_NON_MERCH_EXIST(O_error_message   IN OUT  VARCHAR2,
                               O_exists          IN OUT  BOOLEAN,
                               I_non_merch_code  IN      NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE)

   RETURN BOOLEAN IS

   L_exists          VARCHAR2(1);

   cursor C_INVC_NON_MERCH_EXIST is
      select 'x'
        from  invc_non_merch
       where  non_merch_code  = I_non_merch_code;

BEGIN

   if I_non_merch_code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_non_merch_code',
                                            'INVC_VALIDATE_SQL.INVC_NON_MERCH_EXIST',
                                            NULL);
         return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_INVC_NON_MERCH_EXIST',
                    'invc_non_merch',
                     NULL);
   open C_INVC_NON_MERCH_EXIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVC_NON_MERCH_EXIST',
                    'invc_non_merch',
                     NULL);
   fetch C_INVC_NON_MERCH_EXIST into L_exists;
   if C_INVC_NON_MERCH_EXIST%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVC_NON_MERCH_EXIST',
                    'invc_non_merch',
                     NULL);
   close C_INVC_NON_MERCH_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.INVC_NON_MERCH_EXIST',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END INVC_NON_MERCH_EXIST;
-----------------------------------------------------------------------------------------
FUNCTION  CHECK_MATCH_TO_QTY(O_error_message  IN OUT  VARCHAR2,
                             O_valid          IN OUT  BOOLEAN,
                             O_shipment       IN OUT  INVC_MATCH_WKSHT.SHIPMENT%TYPE,
                             O_carton         IN OUT  INVC_MATCH_WKSHT.CARTON%TYPE,
                             O_item           IN OUT  INVC_MATCH_WKSHT.ITEM%TYPE,
                             I_invc_id        IN      INVC_HEAD.INVC_ID%TYPE)
   RETURN BOOLEAN IS

   L_shipment           SHIPSKU.SHIPMENT%TYPE;
   L_carton             SHIPSKU.CARTON%TYPE;
   L_item               SHIPSKU.ITEM%TYPE;
   L_qty                SHIPSKU.QTY_RECEIVED%TYPE;
   L_match_to_qty       INVC_MATCH_WKSHT.MATCH_TO_QTY%TYPE;

   cursor C_SHIPMENT is
      select distinct shipment, carton, item
         from invc_match_wksht
        where invc_id = I_invc_id;

   cursor C_QTY is
      select nvl(qty_received,0)
         from shipsku
        where shipment = L_shipment
          and (carton  = L_carton
               or (carton is NULL and L_carton is NULL))
          and item     = L_item;

   cursor C_MATCH is
      select sum(nvl(match_to_qty,0))
         from invc_match_wksht
        where shipment = L_shipment
          and (carton  = L_carton
               or (carton is NULL and L_carton is NULL))
          and item     = L_item
          and invc_id  = I_invc_id;

BEGIN

   if I_invc_id is NULL then
      O_error_message := sql_lib.create_msg('INV_INVC_ID', null,null,null);
      return FALSE;
   end if;

   for rec in C_SHIPMENT LOOP
      L_shipment := rec.shipment;
      L_carton   := rec.carton;
      L_item     := rec.item;

      open C_QTY;
      fetch C_QTY into L_qty;
      if C_QTY%FOUND then
         open C_MATCH;
         fetch C_MATCH into L_match_to_qty;
         close C_MATCH;

         if L_qty = L_match_to_qty then
            O_valid := TRUE;
         else
            O_valid    := FALSE;
            O_shipment := L_shipment;
            O_carton   := L_carton;
            O_item     := L_item;
            return TRUE;
         end if;
      else
         O_error_message := sql_lib.create_msg('INV_RCPT_SHIP',null,null,null);
         close C_QTY;
         return FALSE;
      end if;
      close C_QTY;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.CHECK_MATCH_TO_QTY',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_MATCH_TO_QTY;
--------------------------------------------------------------------------------------------------
FUNCTION  MATCH_TO_COST_QTY(O_error_message  IN OUT  VARCHAR2,
                            O_valid          IN OUT  BOOLEAN,
                            I_invc_id        IN      INVC_HEAD.INVC_ID%TYPE,
                            I_shipment       IN      INVC_MATCH_WKSHT.SHIPMENT%TYPE,
                            I_carton         IN      INVC_MATCH_WKSHT.CARTON%TYPE,
                            I_item           IN      INVC_MATCH_WKSHT.ITEM%TYPE,
                            I_match_to_cost  IN      INVC_MATCH_WKSHT.MATCH_TO_COST%TYPE,
                            I_currency_invc  IN      INVC_HEAD.CURRENCY_CODE%TYPE,
                            I_exchange_rate  IN      INVC_HEAD.EXCHANGE_RATE%TYPE,
                            I_match_to_qty   IN      INVC_MATCH_WKSHT.MATCH_TO_QTY%TYPE)
   RETURN BOOLEAN IS

   L_qty_received               SHIPSKU.QTY_RECEIVED%TYPE := 0;
   L_qty                        ORDLOC_INVC_COST.QTY%TYPE := 0;
   L_order_no                   ORDLOC_INVC_COST.ORDER_NO%TYPE;
   L_location                   ORDLOC_INVC_COST.LOCATION%TYPE;
   L_order_curr                 ORDHEAD.CURRENCY_CODE%TYPE;
   L_ord_exchange_rate          ORDHEAD.EXCHANGE_RATE%TYPE;
   L_match_to_cost_ord          INVC_MATCH_WKSHT.MATCH_TO_COST%TYPE;
   L_dummy                      VARCHAR2(1);
   L_exists                     VARCHAR2(1) := NULL;

   cursor C_ORDER_LOC is
      select s.order_no,
             s.to_loc,
             oh.currency_code,
             oh.exchange_rate
        from shipment s,
             ordhead oh
       where shipment   = I_shipment
         and s.order_no = oh.order_no;

   cursor C_QTY_RECV is
      select NVL(qty_received,0)
        from shipsku
       where shipment = I_shipment
         and (carton  = I_carton
              or (carton is NULL and I_carton is NULL))
         and item     = I_item;

   cursor C_OFF_INVOICE_EXIST is
      select 'x'
        from dual
       where exists (select 'x'
                       from ordloc_invc_cost
                      where order_no       = L_order_no
                        and item           = I_item
                        and location       = L_location
                        and (shipment      = I_shipment
                             or (shipment is NULL and I_shipment is NULL))
                        and (carton        = I_carton
                             or (carton is NULL and I_carton is NULL)));

   cursor C_MATCHING_ORD_EXIST is
      select 'x'
        from dual
       where exists (select 'x'
                       from ordloc_invc_cost
                      where order_no       = L_order_no
                        and item           = I_item
                        and location       = L_location
                        and (shipment      = I_shipment
                             or (shipment is NULL and I_shipment is NULL))
                        and (carton        = I_carton
                             or (carton is NULL and I_carton is NULL))
                        and unit_cost      = L_match_to_cost_ord
                        and (qty          >= I_match_to_qty
                             or I_match_to_qty is NULL)
                        and (match_invc_id = I_invc_id
                             or match_invc_id is NULL));

   cursor C_CHECK_SHIP_COST is
      select 'x'
        from dual
       where exists (select 'x'
                       from shipsku
                      where shipment             = I_shipment
                        and item                 = I_item
                        and (carton              = I_carton
                             or (carton is NULL and I_carton is NULL))
                        and unit_cost            = L_match_to_cost_ord
                        and (match_invc_id       = I_invc_id
                             or match_invc_id    is NULL)
                        and (NVL(qty_received,0) >= I_match_to_qty
                             or I_match_to_qty   is NULL));

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_VALIDATE_SQL.MATCH_TO_COST_QTY',
                                            NULL);
         return FALSE;
   elsif I_shipment is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_shipment',
                                            'INVC_VALIDATE_SQL.MATCH_TO_COST_QTY',
                                            NULL);
         return FALSE;
   elsif I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            'INVC_VALIDATE_SQL.MATCH_TO_COST_QTY',
                                            NULL);
         return FALSE;
   elsif (I_match_to_cost is NULL and I_match_to_qty is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_EITHER',
                                            'I_match_to_cost',
                                            'I_match_to_qty',
                                            'INVC_VALIDATE_SQL.MATCH_TO_COST_QTY');
         return FALSE;
   end if;

   O_valid := TRUE;

   open C_ORDER_LOC;
   fetch C_ORDER_LOC into L_order_no,
                          L_location,
                          L_order_curr,
                          L_ord_exchange_rate;
   close C_ORDER_LOC;

   if I_match_to_qty is NOT NULL then
      ---
      open C_QTY_RECV;
      fetch C_QTY_RECV into L_qty_received;
      close C_QTY_RECV;
      ---
      if not (I_match_to_qty <= L_qty_received) then
         O_valid := FALSE;
         return TRUE;
      end if;
   end if;
   ---
   if I_match_to_cost is NOT NULL then

      /* first, convert passed in cost from invoice currency to order currency */

      if CURRENCY_SQL.CONVERT(O_error_message,
                              I_match_to_cost,
                              I_currency_invc,
                              L_order_curr,
                              L_match_to_cost_ord,
                              'C',
                              NULL,
                              NULL,
                              I_exchange_rate,
                              L_ord_exchange_rate) = FALSE then
         return FALSE;
      end if;

      /* records will be present on ordloc_invc_cost    */
      /* only if off-invoice deal(s) have been applied. */

      /* if no records are found on ordloc_invc_cost, attempt */
      /* to match to shipsku cost (and optionally quantity)   */

      open C_OFF_INVOICE_EXIST;
      fetch C_OFF_INVOICE_EXIST into L_exists;
      close C_OFF_INVOICE_EXIST;
      ---
      if L_exists is NOT NULL then
         open C_MATCHING_ORD_EXIST;
         fetch C_MATCHING_ORD_EXIST into L_dummy;
         if C_MATCHING_ORD_EXIST%NOTFOUND then
            O_valid := FALSE;
         end if;
         close C_MATCHING_ORD_EXIST;
      else
         open C_CHECK_SHIP_COST;
         fetch C_CHECK_SHIP_COST into L_dummy;
         if C_CHECK_SHIP_COST%NOTFOUND then
            O_valid := FALSE;
         end if;
         close C_CHECK_SHIP_COST;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.MATCH_TO_COST_QTY',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END MATCH_TO_COST_QTY;
--------------------------------------------------------------------------------------------------
FUNCTION INVC_NON_MERCH_EXIST(O_error_message   IN OUT  VARCHAR2,
                              O_exists          IN OUT  BOOLEAN,
                              I_non_merch_code  IN      NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE,
                              I_invc_id         IN      INVC_NON_MERCH.INVC_ID%TYPE)

RETURN BOOLEAN IS

   L_exists          VARCHAR2(1);

   cursor C_INVC_NON_MERCH_EXIST is
      select 'Y'
        from  invc_non_merch
       where  non_merch_code  = I_non_merch_code
         and  invc_id         = I_invc_id;

BEGIN

   if I_non_merch_code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_non_merch_code',
                                            'INVC_VALIDATE_SQL.INVC_NON_MERCH_EXIST',
                                            NULL);
         return FALSE;
   elsif I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_VALIDATE_SQL.INVC_NON_MERCH_EXIST',
                                            NULL);
         return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_INVC_NON_MERCH_EXIST',
                    'invc_non_merch',
                     NULL);
   open C_INVC_NON_MERCH_EXIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVC_NON_MERCH_EXIST',
                    'invc_non_merch',
                     NULL);
   fetch C_INVC_NON_MERCH_EXIST into L_exists;
   if C_INVC_NON_MERCH_EXIST%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVC_NON_MERCH_EXIST',
                    'invc_non_merch',
                     NULL);
   close C_INVC_NON_MERCH_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_VALIDATE_SQL.INVC_NON_MERCH_EXIST',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END INVC_NON_MERCH_EXIST;
-----------------------------------------------------------------------------------------
FUNCTION DETAILS_EXIST(O_error_message IN OUT VARCHAR2,
                       O_exists        IN OUT BOOLEAN,
                       I_invc_id       IN     INVC_DETAIL.INVC_ID%TYPE,
                       I_item          IN     INVC_DETAIL.ITEM%TYPE,
                       I_ref_item      IN     INVC_DETAIL.REF_ITEM%TYPE,
                       I_item_parent   IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                       I_diff_1        IN     ITEM_MASTER.DIFF_1%TYPE,
                       I_diff_2        IN     ITEM_MASTER.DIFF_2%TYPE,
                       I_diff_3        IN     ITEM_MASTER.DIFF_3%TYPE,
                       I_diff_4        IN     ITEM_MASTER.DIFF_4%TYPE)
   RETURN BOOLEAN IS

   L_program     VARCHAR2(50) := 'INVC_VALIDATE_SQL.DETAILS_EXIST';
   L_exist_ind   VARCHAR2(1);

   cursor C_DETAILS_EXIST is
      select 'x'
        from dual
       where exists (select 'x'
                       from invc_detail id,
                            item_master im
                      where id.invc_id      = I_invc_id
                        and id.item         = NVL(I_item, id.item)
                        and (  (id.ref_item is NULL and I_ref_item is NULL)
                             or id.ref_item = NVL(I_ref_item, id.ref_item))
                        and im.item         = id.item
                        and (  (im.item_parent is NULL and I_item_parent is NULL)
                             or im.item_parent = NVL(I_item_parent, im.item_parent))
                        and (  (im.diff_1 is NULL and I_diff_1 is NULL)
                             or im.diff_1      = NVL(I_diff_1, im.diff_1))
                        and (  (im.diff_2 is NULL and I_diff_2 is NULL)
                             or im.diff_2      = NVL(I_diff_2, im.diff_2))
                        and (  (im.diff_3 is NULL and I_diff_3 is NULL)
                             or im.diff_3      = NVL(I_diff_3, im.diff_3))
                        and (  (im.diff_4 is NULL and I_diff_4 is NULL)
                             or im.diff_4      = NVL(I_diff_4, im.diff_4)));

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   open C_DETAILS_EXIST;
   fetch C_DETAILS_EXIST into L_exist_ind;
   if C_DETAILS_EXIST%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   close C_DETAILS_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END DETAILS_EXIST;
--------------------------------------------------------------------------------------------------
END INVC_VALIDATE_SQL;
/

