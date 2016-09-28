CREATE OR REPLACE PACKAGE BODY EDITEM_SQL AS
---------------------------------------------------------------------------------------------------------------
--Fix By:      John Alister Anand, john.anand@in.tesco.com
--Fix Date:    14-Apr-2008
--Fix Ref:     NBS005922
--Fix Details: Modified to add one parameter in SIMPLE_PACK_SQL.BUILD_PACK
--						 referenced by MASS_INSERT_ITEM
---------------------------------------------------------------------------------------------------------------
FUNCTION BUILD_ITEM (O_error_message          IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     O_no_retail              IN OUT   VARCHAR2,
                     I_seq_no                 IN       EDI_NEW_ITEM.SEQ_NO%TYPE,
                     I_item                   IN       ITEM_MASTER.ITEM%TYPE,
                     I_item_level             IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                     I_tran_level             IN       ITEM_MASTER.TRAN_LEVEL%TYPE,
                     I_new_ind                IN       VARCHAR2,
                     I_item_number_type       IN       ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                     I_format_id              IN       ITEM_MASTER.FORMAT_ID%TYPE,
                     I_prefix                 IN       ITEM_MASTER.PREFIX%TYPE,
                     I_item_parent            IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                     I_item_grandparent       IN       ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                     I_diff_1                 IN       ITEM_MASTER.DIFF_1%TYPE,
                     I_diff_2                 IN       ITEM_MASTER.DIFF_2%TYPE,
                     I_diff_3                 IN       ITEM_MASTER.DIFF_3%TYPE,
                     I_diff_4                 IN       ITEM_MASTER.DIFF_4%TYPE,
                     I_dept                   IN       ITEM_MASTER.DEPT%TYPE,
                     I_class                  IN       ITEM_MASTER.CLASS%TYPE,
                     I_subclass               IN       ITEM_MASTER.SUBCLASS%TYPE,
                     I_item_desc              IN       ITEM_MASTER.ITEM_DESC%TYPE,
                     I_short_desc             IN       ITEM_MASTER.SHORT_DESC%TYPE,
                     I_retail_zone_group_id   IN       ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                     I_cost_zone_group_id     IN       ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE,
                     I_standard_uom           IN       ITEM_MASTER.STANDARD_UOM%TYPE,
                     I_uom_conv_factor        IN       ITEM_MASTER.UOM_CONV_FACTOR%TYPE,
                     I_store_ord_mult         IN       ITEM_MASTER.STORE_ORD_MULT%TYPE,
                     I_supplier               IN       ITEM_SUPPLIER.SUPPLIER%TYPE,
                     I_vpn                    IN       ITEM_SUPPLIER.VPN%TYPE,
                     I_supp_diff_1            IN       ITEM_SUPPLIER.SUPP_DIFF_1%TYPE,
                     I_supp_diff_2            IN       ITEM_SUPPLIER.SUPP_DIFF_2%TYPE,
                     I_supp_diff_3            IN       ITEM_SUPPLIER.SUPP_DIFF_3%TYPE,
                     I_supp_diff_4            IN       ITEM_SUPPLIER.SUPP_DIFF_4%TYPE,
                     I_origin_country_id      IN       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                     I_lead_time              IN       ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE,
                     I_unit_cost              IN       ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                     I_supp_pack_size         IN       ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE,
                     I_inner_pack_size        IN       ITEM_SUPP_COUNTRY.INNER_PACK_SIZE%TYPE,
                     I_min_order_qty          IN       ITEM_SUPP_COUNTRY.MIN_ORDER_QTY%TYPE,
                     I_max_order_qty          IN       ITEM_SUPP_COUNTRY.MAX_ORDER_QTY%TYPE,
                     I_packing_method         IN       ITEM_SUPP_COUNTRY.PACKING_METHOD%TYPE,
                     I_default_uop            IN       ITEM_SUPP_COUNTRY.DEFAULT_UOP%TYPE,
                     I_ti                     IN       ITEM_SUPP_COUNTRY.TI%TYPE,
                     I_hi                     IN       ITEM_SUPP_COUNTRY.HI%TYPE,
                     I_unit_length            IN       ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE,
                     I_unit_width             IN       ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE,
                     I_unit_height            IN       ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE,
                     I_unit_lwh_uom           IN       ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE,
                     I_unit_weight            IN       ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                     I_unit_net_weight        IN       ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE,
                     I_unit_weight_uom        IN       ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE,
                     I_unit_liquid_vol        IN       ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE,
                     I_unit_liquid_uom        IN       ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE,
                     I_case_length            IN       ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE,
                     I_case_width             IN       ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE,
                     I_case_height            IN       ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE,
                     I_case_lwh_uom           IN       ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE,
                     I_case_weight            IN       ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                     I_case_net_weight        IN       ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE,
                     I_case_weight_uom        IN       ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE,
                     I_case_liquid_vol        IN       ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE,
                     I_case_liquid_uom        IN       ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE,
                     I_pallet_length          IN       ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE,
                     I_pallet_width           IN       ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE,
                     I_pallet_height          IN       ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE,
                     I_pallet_lwh_uom         IN       ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE,
                     I_pallet_weight          IN       ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                     I_pallet_net_weight      IN       ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE,
                     I_pallet_weight_uom      IN       ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE,
                     I_elc_ind                IN       SYSTEM_OPTIONS.ELC_IND%TYPE,
                     I_vat_ind                IN       SYSTEM_OPTIONS.VAT_IND%TYPE,
                     I_default_retail_ind     IN       EDI_NEW_ITEM.DEFAULT_RETAIL_IND%TYPE,
                     I_consignment_rate       IN       ITEM_SUPPLIER.CONSIGNMENT_RATE%TYPE,
                     I_unit_retail            IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                     I_item_xform_ind         IN       EDI_NEW_ITEM.ITEM_XFORM_IND%TYPE
                     )

   return BOOLEAN IS

   L_user                   USER_USERS.USERNAME%TYPE;
   L_sysdate                PERIOD.VDATE%TYPE;
   L_action_date            PERIOD.VDATE%TYPE := DATES_SQL.GET_VDATE;
   L_program                VARCHAR2(64) := 'EDITEM_SQL.BUILD_ITEM';
   L_default_standard_uom   SYSTEM_OPTIONS.DEFAULT_STANDARD_UOM%TYPE;
   L_default_dimension_uom  SYSTEM_OPTIONS.DEFAULT_DIMENSION_UOM%TYPE;
   L_default_weight_uom     SYSTEM_OPTIONS.DEFAULT_WEIGHT_UOM%TYPE;
   L_default_packing_method SYSTEM_OPTIONS.DEFAULT_PACKING_METHOD%TYPE;
   L_default_pallet_name    SYSTEM_OPTIONS.DEFAULT_PALLET_NAME%TYPE;
   L_default_case_name      SYSTEM_OPTIONS.DEFAULT_CASE_NAME%TYPE;
   L_default_inner_name     SYSTEM_OPTIONS.DEFAULT_INNER_NAME%TYPE;
   L_standard_uom           SYSTEM_OPTIONS.DEFAULT_STANDARD_UOM%TYPE;
   L_packing_method         SYSTEM_OPTIONS.DEFAULT_PACKING_METHOD%TYPE;
   L_sellable_ind           ITEM_MASTER.SELLABLE_IND%TYPE;
   L_exists                 VARCHAR2(1);
   L_primary_ref_item_ind   ITEM_MASTER.PRIMARY_REF_ITEM_IND%TYPE := 'N';
   L_round_lvl              ITEM_SUPP_COUNTRY.ROUND_LVL%TYPE;
   L_round_to_inner_pct     ITEM_SUPP_COUNTRY.ROUND_TO_INNER_PCT%TYPE;
   L_round_to_case_pct      ITEM_SUPP_COUNTRY.ROUND_TO_CASE_PCT%TYPE;
   L_round_to_layer_pct     ITEM_SUPP_COUNTRY.ROUND_TO_LAYER_PCT%TYPE;
   L_round_to_pallet_pct    ITEM_SUPP_COUNTRY.ROUND_TO_PALLET_PCT%TYPE;
   L_ref_exist              VARCHAR2(1);
   L_bracket_costing_ind    VARCHAR2(1);
   L_inv_mgmt_level         VARCHAR2(3);
   L_markup_type            VARCHAR2(2);
   L_markup_pct             NUMBER(12,4);
   L_budget_markup          NUMBER(12,4);
   L_unit_cost              ITEM_SUPP_COUNTRY.UNIT_COST%TYPE := NULL;
   L_unit_retail            ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE;
   L_edi_cost_loc_exists    VARCHAR2(1) := 'N';
   L_case_ind               EDI_COST_LOC.CASE_IND%TYPE;
   L_location_exists        VARCHAR2(1) := 'N';
   L_bracket_exists         VARCHAR2(1) := 'N';
   L_supp_curr_code         SUPS.CURRENCY_CODE%TYPE;
   L_default_bracket        SUP_BRACKET_COST.DEFAULT_BRACKET_IND%TYPE;
   L_default_bracket_unit_cost ITEM_SUPP_COUNTRY_BRACKET_COST.UNIT_COST%TYPE;
   L_processing             VARCHAR2(10) := NULL;
   L_multichannel_ind       SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;

   L_orderable_ind          ITEM_MASTER.INVENTORY_IND%TYPE        ;
   L_inventory_ind          ITEM_MASTER.SELLABLE_IND%TYPE         ;
   L_retail_zone_group_id   ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE ;

   cursor C_GET_USER is
      select sysdate,
             user
        from dual;

   cursor C_ITEM_SUPPLIER is
      select 'Y'
        from item_supplier
       where item = I_item
         and supplier = I_supplier;

   cursor C_ITEM_SUPP_COUNTRY is
      select 'Y'
        from item_supp_country
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_origin_country_id;

   cursor C_GET_LOCS is
      select loc,
             loc_type
        from item_loc
       where item = I_item_parent;

   cursor C_REF_ITEM is
      select 'x'
        from item_master
       where item_parent = I_item_parent
         and primary_ref_item_ind = 'Y';

   ---
   cursor C_CHK_EDI_COST_LOC is
      select distinct 'Y', DECODE(location, NULL, 'N', 'Y'),
             DECODE(bracket_value1, NULL, 'N','Y')
        from edi_cost_loc
       where case_ind = 'N'
         and seq_no = I_seq_no;

   ---
   ---------------------------------------------------------------------------------------
   --- Internal Function: CALL_NEW_ITEM_LOC - calls NEW_ITEM_LOC
   ---------------------------------------------------------------------------------------
   FUNCTION CALL_NEW_ITEM_LOC(O_error_message IN OUT VARCHAR2,
                              I_location      IN     EDI_COST_LOC.LOCATION%TYPE,
                              I_loc_type      IN     EDI_COST_LOC.LOC_TYPE%TYPE,
                              I_loc_unit_cost IN     ITEM_SUPP_COUNTRY.UNIT_COST%TYPE)
      RETURN BOOLEAN is

      BEGIN
         if NEW_ITEM_LOC(O_error_message,
                         I_item,
                         I_location,
                         I_item_parent,
                         I_item_grandparent,
                         I_loc_type,
                         I_short_desc,
                         I_dept,
                         I_class,
                         I_subclass,
                         I_item_level,
                         I_tran_level,
                         'W',
                         L_retail_zone_group_id,
                         Null,
                         Null,
                         L_sellable_ind,
                         'N',
                         'N',
                         Null,
                         I_loc_unit_cost,
                         I_unit_retail,
                         I_unit_retail,
                         Null,
                         Null,
                         Null,
                         I_ti,
                         I_hi,
                         I_store_ord_mult,
                         Null,
                         Null,
                         Null,
                         Null,
                         I_supplier,
                         I_origin_country_id,
                         Null,
                         Null,
                         Null,
                         NULL,
                         L_sysdate,
                         TRUE) = FALSE then
            return FALSE;
         end if;

         ---
         return TRUE;
      EXCEPTION
         when OTHERS then
            O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                  SQLERRM,
                                                  L_program,
                                                  TO_CHAR(SQLCODE));
           return FALSE;
      END CALL_NEW_ITEM_LOC;
   ------------------------------------------------------------------------------------------
   --- Internal Function: GET_PRICE_ZONE_UNIT_COST - Returns unit cost for price zone inserts
   ---
   ------------------------------------------------------------------------------------------
   FUNCTION GET_UNIT_RETAIL return BOOLEAN IS
      L_markup_type            VARCHAR2(2);
      L_markup_pct             NUMBER(12,4);
      L_budget_markup          NUMBER(12,4);
      L_supp_curr_code         SUPS.CURRENCY_CODE%TYPE;
      ---
      cursor C_GET_COST_NO_LOC_SD is
         select e.unit_cost_new
           from sup_bracket_cost s,
                edi_cost_loc e
          where s.default_bracket_ind = 'Y'
            and s.dept     = I_dept
            and e.supplier = s.supplier
            and e.bracket_value1 = s.bracket_value1
            and e.case_ind = 'N'
            and e.seq_no   = I_seq_no;
     ---
     cursor C_GET_COST_NO_LOC_S is
         select e.unit_cost_new
           from sup_bracket_cost s,
                edi_cost_loc e
          where s.default_bracket_ind = 'Y'
            and s.dept is NULL
            and e.supplier = s.supplier
            and e.bracket_value1 = s.bracket_value1
            and e.case_ind = 'N'
            and e.seq_no   = I_seq_no;
     ---
     cursor C_GET_COST_LOC_SD is
        select e.unit_cost_new
          from sup_bracket_cost s,
               edi_cost_loc e
         where s.default_bracket_ind = 'Y'
           and e.location = s.location
           and s.dept     = I_dept
           and e.supplier = s.supplier
           and e.bracket_value1 = s.bracket_value1
           and e.location = (select min(c.location) from edi_cost_loc c
                             where c.case_ind = 'N'
                               and c.seq_no = e.seq_no)
           and e.case_ind = 'N'
           and e.seq_no   = I_seq_no;
     ---
     cursor C_GET_COST_LOC_S is
        select e.unit_cost_new
          from sup_bracket_cost s,
               edi_cost_loc e
         where s.default_bracket_ind = 'Y'
           and e.location = s.location
           and s.dept     is NULL
           and e.supplier = s.supplier
           and e.bracket_value1 = s.bracket_value1
           and e.location = (select min(c.location) from edi_cost_loc c
                             where c.case_ind = 'N'
                               and c.seq_no = e.seq_no)
           and e.case_ind = 'N'
           and e.seq_no   = I_seq_no;
     ---
     cursor C_GET_COST_LOC_SDL is
        select e.unit_cost_new
          from sup_bracket_cost s,
               edi_cost_loc e
         where s.default_bracket_ind = 'Y'
           and e.location = s.location
           and e.supplier = s.supplier
           and ((s.dept = I_dept and L_inv_mgmt_level = 'A') or
                (s.dept is NULL  and L_inv_mgmt_level = 'L'))
           and e.bracket_value1 = s.bracket_value1
           and e.location = (select min(c.location) from edi_cost_loc c
                             where c.case_ind = 'N'
                               and c.seq_no = e.seq_no)
           and e.case_ind = 'N'
           and e.seq_no   = I_seq_no;
     ---
     cursor C_GET_COST_ON_E_NOT_S is
        select e.unit_cost_new
          from sup_bracket_cost s,
               edi_cost_loc e
         where s.default_bracket_ind = 'Y'
           and s.location is null
           and ((s.dept = I_dept and L_inv_mgmt_level = 'A') or
                (s.dept is NULL  and L_inv_mgmt_level = 'L'))
           and e.supplier = s.supplier
           and e.bracket_value1 = s.bracket_value1
           and e.location = (select min(c.location) from edi_cost_loc c
                             where c.case_ind = 'N'
                               and c.seq_no = e.seq_no)
           and e.case_ind = 'N'
           and e.seq_no   = I_seq_no;
     ---
     cursor C_GET_COST_NO_DEPT_LOC is
        select e.unit_cost_new
          from sup_bracket_cost s,
               edi_cost_loc e
         where s.default_bracket_ind = 'Y'
           and s.location is null
           and s.dept is NULL
           and e.supplier = s.supplier
           and e.bracket_value1 = s.bracket_value1
           and e.location = (select min(c.location) from edi_cost_loc c
                             where c.case_ind = 'N'
                               and c.seq_no = e.seq_no)
           and e.case_ind = 'N'
           and e.seq_no   = I_seq_no;
     ---
     cursor C_GET_COST_NO_BRACKETS is
        select e.unit_cost_new
          from edi_cost_loc e
         where e.location IN (select min(c.location) from edi_cost_loc c
                              where c.case_ind = 'N'
                                and c.seq_no = e.seq_no)
           and e.bracket_value1 is NULL
           and e.case_ind = 'N'
           and e.seq_no = I_seq_no;
     ---
   ---
   BEGIN
      if DEPT_ATTRIB_SQL.GET_MARKUP(O_error_message,
                                    L_markup_type,
                                    L_markup_pct,
                                    L_budget_markup,
                                    I_dept) = FALSE then
         return FALSE;
      end if;

      ---
      -- Check if EDI_COST_LOC record exist for the passed in SEQ_N0
      ---
      if L_edi_cost_loc_exists = 'Y' then
         -- Check for Brackets on EDI_COST_LOC
         if L_bracket_exists = 'Y' then
            if L_location_exists = 'N' then
               -- If no locations are present on EDI_COST_LOC then the supplier is
               -- Supplier/Department or Supplier.  Check Supplier/Department first.
               open C_GET_COST_NO_LOC_SD;
               fetch C_GET_COST_NO_LOC_SD into L_unit_cost;
               close C_GET_COST_NO_LOC_SD;
               -- If this was not found then assume tht it is a supplier level bracket
               if L_unit_cost is NULL then
                  open C_GET_COST_NO_LOC_S;
                  fetch C_GET_COST_NO_LOC_S into L_unit_cost;
                  close C_GET_COST_NO_LOC_S;
               end if;
               ---
            else
               -- Locations are present on EDI_COST_LOC and Supplier bracket level
               -- is Supplier/Dept or Supplier.
               --
               if L_inv_mgmt_level in ('D','S') then
                  -- Get Supplier/Department cost
                  open C_GET_COST_LOC_SD;
                  fetch C_GET_COST_LOC_SD into L_unit_cost;
                  close C_GET_COST_LOC_SD;
                  ---
                  if L_unit_cost is NULL then
                     -- assume bracket is 'S'upplier level
                     open C_GET_COST_LOC_S;
                     fetch C_GET_COST_LOC_S into L_unit_cost;
                     close C_GET_COST_LOC_S;
                  end if;
                  ---
               elsif L_inv_mgmt_level in ('A','L') then
                  ---
                  -- If the supplier bracket cost level is Supplier/Location/Dept or
                  -- Supplier/Location
                  ---
                  open C_GET_COST_LOC_SDL;
                  fetch C_GET_COST_LOC_SDL into L_unit_cost;
                  close C_GET_COST_LOC_SDL;
                  ---
                  -- If not found then,
                  -- Check if locations exist on EDI_COST_LOC but not SUP_BRACKET_COST
                  ---
                  if L_unit_cost is NULL then
                     open C_GET_COST_ON_E_NOT_S;
                     fetch C_GET_COST_ON_E_NOT_S into L_unit_cost;
                     close C_GET_COST_ON_E_NOT_S;
                  end if;
                  ---
                  -- If not found then check,
                  -- No departments or Locations exist on SUP_BRACKET_COST
                  ---
                  if L_unit_cost is NULL then
                     open C_GET_COST_NO_DEPT_LOC;
                     fetch C_GET_COST_NO_DEPT_LOC into L_unit_cost;
                     close C_GET_COST_NO_DEPT_LOC;
                  end if;
               end if;     -- level SD/S
            end if;        -- locations exists
         else
            --- No Brackets exist, use the unit cost from EDI_COST_LOC
            --- where the location is the minimum location and case ind = N
            ---
            open C_GET_COST_NO_BRACKETS;
            fetch C_GET_COST_NO_BRACKETS into L_unit_cost;
            close C_GET_COST_NO_BRACKETS;
         end if;   -- Brackets exists
      end if;  -- L_edi_cost_loc_exists
      ---
      --- if no unit cost was found then use the passed in unit cost
      ---
      if L_unit_cost is NULL then
         L_unit_cost := I_unit_cost;
      end if;
      ---
      --- Calculate the unit retail cost
      if MARKUP_SQL.CALC_RETAIL_FROM_MARKUP(O_error_message,
                                            L_unit_retail,
                                            L_markup_pct,
                                            L_markup_type,
                                            L_unit_cost,
                                            I_item,
                                            NULL,
                                            NULL,
                                            I_dept,
                                            NULL,
                                            I_vat_ind,
                                            L_supp_curr_code) = FALSE then
         return FALSE;
      end if;
      ---
   return TRUE;
   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
      return FALSE;
   END GET_UNIT_RETAIL;
   ------------------------------------------------------------------------------------------
   ------------------------------------------------------------------------------------------
   --- Internal Function: BRACKET_COST - inserts into the item_supp_country_bracket_cost
   --- table.
   ---
   ------------------------------------------------------------------------------------------
   FUNCTION BRACKET_COST  return BOOLEAN IS
      ---
      cursor C_GET_ISC_UNIT_COST is
         select unit_cost
         from item_supp_country
         where origin_country_id = I_origin_country_id
           and supplier = I_supplier
           and item = I_item;

      cursor C_EDI_BRACKETS is
         select distinct bracket_value1,
                         bracket_uom1,
                         bracket_value2,
                         bracket_type1,
                         decode(edi.Location, null, edi.unit_cost_new, isc.unit_cost) unit_cost
           from item_supp_country isc,
                edi_cost_loc edi
          where edi.origin_country_id = isc.origin_country_id
            and edi.supplier = isc.supplier
            and I_item       = isc.item
            and edi.case_ind = 'N'
            and edi.seq_no  = I_seq_no;
      ---
      cursor C_DEFAULT_BRACKET_UNIT_COST is
         select unit_cost
           from item_supp_country_bracket_cost
          where default_bracket_ind = 'Y'
            and location is NULL
            and origin_country_id = I_origin_country_id
            and supplier          = I_supplier
            and item              = I_item;
      ---
      cursor C_EDI_LOCATION_COSTED is
         select distinct location,
                         loc_type,
                         unit_cost_new
           from edi_cost_loc
          where bracket_value1 is NULL
            and location is NOT NULL
            and case_ind = 'N'
            and seq_no = I_seq_no;
      ---
      cursor C_EDI_LOCATION_BRACKET_COSTED is
         select distinct location,
                         loc_type
           from edi_cost_loc
          where bracket_value1 is not null
            and location is not null
            and case_ind = 'N'
            and seq_no = I_seq_no;
      ---
      cursor C_EDI_VALIDATE_BRACKETS is
         select distinct edi.item,
                         edi.supplier,
                         edi.origin_country_id,
                         edi.location,
                         edi.bracket_value1,
                         edi.bracket_value2,
                         edi.unit_cost_new,
                         bc.default_bracket_ind
           from item_supp_country_bracket_cost bc,
                wh,
                edi_cost_loc edi
           where edi.bracket_value1    = bc.bracket_value1
             and wh.wh                 = bc.location
             and edi.origin_country_id = bc.origin_country_id
             and edi.supplier          = bc.supplier
             and I_item                = bc.item
             and edi.location          = wh.physical_wh
             and edi.case_ind          = 'N'
             and edi.seq_no            = I_seq_no;
      ---
      cursor C_VIRTUAL_WAREHOUSES (CP_location EDI_COST_LOC.LOCATION%TYPE) is
         select wh location
         from wh
         where stockholding_ind = 'Y'
           and physical_wh = CP_location
         UNION ALL
         select store location
         from store
         where store = CP_location;
      ---
   BEGIN
      if L_bracket_costing_ind = 'Y' then
         ---
         if L_bracket_exists = 'Y' then
            -- create item/supplier/country bracket cost records
            if L_inv_mgmt_level in ('S','D') then
               ---
               insert into item_supp_country_bracket_cost(item,
                                                          supplier,
                                                          origin_country_id,
                                                          location,
                                                          bracket_value1,
                                                          default_bracket_ind,
                                                          unit_cost,
                                                          bracket_value2,
                                                          sup_dept_seq_no)
                                                   select I_item,
                                                          I_supplier,
                                                          I_origin_country_id,
                                                          NULL,
                                                          bracket_value1,
                                                          default_bracket_ind,
                                                          0,
                                                          bracket_value2,
                                                          sup_dept_seq_no
                                                     from sup_bracket_cost
                                                    where location is NULL
                                                      and dept = I_dept
                                                      and supplier = I_supplier;
               if SQL%NOTFOUND then
                  insert into item_supp_country_bracket_cost(item,
                                                             supplier,
                                                             origin_country_id,
                                                             location,
                                                             bracket_value1,
                                                             default_bracket_ind,
                                                             unit_cost,
                                                             bracket_value2,
                                                             sup_dept_seq_no)
                                                      select I_item,
                                                             I_supplier,
                                                             I_origin_country_id,
                                                             NULL,
                                                             bracket_value1,
                                                             default_bracket_ind,
                                                             0,
                                                             bracket_value2,
                                                             sup_dept_seq_no
                                                        from sup_bracket_cost
                                                       where location is NULL
                                                         and dept is NULL
                                                         and supplier = I_supplier;
               end if;
               ---
               -- Loop through the EDI_COST_LOC distinct Brackets for the passed in SEQ_NO
               ---
               FOR edi_rec in C_EDI_BRACKETS LOOP
                  --  Verify that the brackets are valid for the supplier
                  ---
                  if EDI_BRACKET_SQL.VALIDATE_BRACKET(O_error_message,
                                                      L_exists,
                                                      L_default_bracket,
                                                      I_item,
                                                      I_supplier,
                                                      NULL,
                                                      edi_rec.bracket_value1,
                                                      edi_rec.bracket_uom1,
                                                      edi_rec.bracket_type1,
                                                      edi_rec.bracket_value2) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if L_exists = 'Y' then
                     ---
                     -- Get Unit Cost based on location and valid bracket
                     ---
                     if L_location_exists = 'N' then
                        L_unit_cost := edi_rec.unit_cost;
                     else
                        open C_GET_ISC_UNIT_COST;
                        fetch C_GET_ISC_UNIT_COST into L_unit_cost;
                        close C_GET_ISC_UNIT_COST;
                     end if;
                     ---
                     update item_supp_country_bracket_cost
                        set unit_cost = edi_rec.unit_cost
                      where ((bracket_value2 = edi_rec.bracket_value2) or
                             (bracket_value2 is NULL and edi_rec.bracket_value2 is null))
                        and bracket_value1 = edi_rec.bracket_value1
                        and origin_country_id = I_origin_country_id
                        and supplier = I_supplier
                        and item = I_item;

                  end if;
                  ---
               END LOOP;
               ---   Find the unit cost of the default bracket from newly created bracket sturcture
               open C_DEFAULT_BRACKET_UNIT_COST;
               fetch C_DEFAULT_BRACKET_UNIT_COST into L_default_bracket_unit_cost;
               close C_DEFAULT_BRACKET_UNIT_COST;
               ---
               --- End if inventory Management level is 'S' or 'D' check
            end if;
         end if;
      end if;
      ---
      -- If we are processing Children records then
      -- If records are not on EDI_COST_LOC or if locations are not provided
      -- then determine the unit cost to use and create the ITEM_SUPP_COUNTRY_LOC
      -- and ITEM_SUP_COUNTRY_BRACKET_COST records for all parent item locations
      ---
      if L_processing = 'CHILD' then
         if L_edi_cost_loc_exists = 'N' or L_location_exists = 'N' then
            if L_edi_cost_loc_exists = 'N' then
               L_unit_cost := I_unit_cost;
            else
               L_unit_cost := L_default_bracket_unit_cost;
            end if;
            ---
            -- Loop thru Parent locations
            ---
            FOR rec in C_GET_LOCS LOOP
               if CALL_NEW_ITEM_LOC(O_error_message,
                                    rec.loc,
                                    rec.loc_type,
                                    L_unit_cost ) = FALSE then
                  return FALSE;
               end if;
            END LOOP;
         end if; -- all parent item locations
      end if;
      ---
      -- If the record is location costed then call NEW_ITEM_LOC for each location
      -- on edi_cost_loc for the passed in sequence number
      ---
      if L_edi_cost_loc_exists = 'Y' and L_location_exists = 'Y' and L_bracket_exists = 'N' then
         FOR edi_rec in C_EDI_LOCATION_COSTED LOOP
            FOR vw_rec in C_VIRTUAL_WAREHOUSES (edi_rec.location) LOOP
               if CALL_NEW_ITEM_LOC(O_error_message,
                                    vw_rec.location,
                                    edi_rec.loc_type,
                                    edi_rec.unit_cost_new) = FALSE then
                  return FALSE;
               end if;
               ---
               update item_supp_country_loc
                  set unit_cost            = edi_rec.unit_cost_new,
                      last_update_id       = user,
                      last_update_datetime = sysdate
                where loc_type             = edi_rec.loc_type
                  and loc                  = vw_rec.location
                  and origin_country_id    = I_origin_country_id
                  and supplier             = I_supplier
                  and item                 = item;
               ---
               if UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                               I_item,
                                               I_supplier,
                                               I_origin_country_id,
                                               vw_rec.location,
                                               'N',
                                               'Y',
                                               NULL /* Cost Change Number */ ) = FALSE then
                  return FALSE;
               end if;
            END LOOP;
            ---
         END LOOP;
         ---
      end if;   -- location costed
      ---
      -- Call NEW_ITEM_LOC for edi_cost_loc records that are Location and bracket costed
      ---
      if L_edi_cost_loc_exists = 'Y' and L_location_exists = 'Y' and L_bracket_exists = 'Y' then
         ---
         -- Loop through all edi_cost_loc locations for passed in sequence number
         ---
         FOR edi_rec in C_EDI_LOCATION_BRACKET_COSTED LOOP
            FOR vw_rec in C_VIRTUAL_WAREHOUSES (edi_rec.location) LOOP
               if CALL_NEW_ITEM_LOC(O_error_message,
                                    vw_rec.location,
                                    edi_rec.loc_type,
                                    0 ) = FALSE then
                  return FALSE;
               end if;
               ---
            END LOOP;
            ---
         END LOOP;
         ---
         FOR edi_rec in C_EDI_VALIDATE_BRACKETS LOOP
            FOR vw_rec in C_VIRTUAL_WAREHOUSES (edi_rec.location) LOOP
               UPDATE item_supp_country_bracket_cost
                  set unit_cost         = edi_rec.unit_cost_new
                where bracket_value1    = edi_rec.bracket_value1
                  and location          = vw_rec.location
                  and origin_country_id = I_origin_country_id
                  and supplier          = I_supplier
                  and item              = I_item;
               ---
               if edi_rec.default_bracket_ind = 'Y' then
                  if ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                                I_item,
                                                                I_supplier,
                                                                I_origin_country_id,
                                                                vw_rec.location,
                                                                'N') = FALSE then
                     return FALSE;
                  end if;
               end if;
            END LOOP;
         END LOOP;
         ---
      end if;  --   location and bracket costed
      ---
   return TRUE;
   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
      return FALSE;
   END BRACKET_COST;
   --------------------------------------------------------------------------------------
   ---  Internal function to set default item prices
   --------------------------------------------------------------------------------------
   FUNCTION DEFAULT_PRICES (O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE)
   return BOOLEAN IS

      L_price_table  PM_RETAIL_API_SQL.ITEM_PRICING_TABLE ;

   BEGIN

      PM_RETAIL_API_SQL.GET_ITEM_PRICING_INFO( L_price_table,
                                               I_item       ,
                                               I_dept       ,
                                               I_class      ,
                                               I_subclass   ,
                                               L_supp_curr_code,
                                               I_unit_cost );

      PM_RETAIL_API_SQL.SET_ITEM_PRICING_INFO(L_price_table);

      return TRUE;

   EXCEPTION
      WHEN OTHERS THEN
          O_error_message := SQLERRM ;
          return FALSE;

   END;
   --------------------------------------------------------------------------------------
   ---  Start of BUILD_ITEM body
   --------------------------------------------------------------------------------------
BEGIN

   if I_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_seq_no','NOT NULL','NULL');
      return FALSE;
   elsif I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_supplier','NOT NULL','NULL');
      return FALSE;
   elsif I_item_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item_desc','NOT NULL','NULL');
      return FALSE;
   elsif I_item_level is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item_level','NOT NULL','NULL');
      return FALSE;
   elsif I_tran_level is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_tran_level','NOT NULL','NULL');
      return FALSE;
   elsif I_item_number_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item_number_type','NOT NULL','NULL');
      return FALSE;
   elsif I_short_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_short_desc','NOT NULL','NULL');
      return FALSE;
   elsif (I_cost_zone_group_id is NULL and I_elc_ind = 'Y') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_cost_zone_group_id','NOT NULL','NULL');
      return FALSE;
   elsif I_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_dept','NOT NULL','NULL');
      return FALSE;
   elsif I_class is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_class','NOT NULL','NULL');
      return FALSE;
   elsif I_subclass is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_subclass','NOT NULL','NULL');
      return FALSE;
   elsif I_store_ord_mult is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_store_ord_mult','NOT NULL','NULL');
      return FALSE;
   elsif I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_origin_country_id','NOT NULL','NULL');
      return FALSE;
   elsif I_unit_cost is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_unit_cost','NOT NULL','NULL');
      return FALSE;
   elsif I_item_xform_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item_xform_ind','NOT NULL','NULL');
      return FALSE;
   end if;

   open C_GET_USER;
   fetch C_GET_USER into L_sysdate,
                         L_user;
   close C_GET_USER;
   ---
   --   Get the system Bracket Costing Indicator
   ---
   if SYSTEM_OPTIONS_SQL.GET_BRACKET_COST_IND(O_error_message,
                                              L_bracket_costing_ind) = FALSE then
      return FALSE;
   end if;
   ---
   --   Get the Mulitchannel Indicator
   ---
   if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                              L_multichannel_ind) = FALSE then
      return FALSE;
   end if;
   ---
   --   Get the Inventory mangement level
   ---
   if SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                          L_inv_mgmt_level,
                                          I_supplier) = FALSE then
      return FALSE;
   end if;
   ---
   -- Get Suppliers Currency Code for the passed in supplier
   ---
   if SUPP_ATTRIB_SQL.GET_CURRENCY_CODE(O_error_message,
                                        L_supp_curr_code,
                                        I_supplier) = FALSE then
      return FALSE;
   end if;
   ---
   -- Get indicator/exists flags from EDI_COST_LOC for passed in EDI sequence number
   ---
   open C_CHK_EDI_COST_LOC;
   fetch C_CHK_EDI_COST_LOC into L_edi_cost_loc_exists,
                                 L_location_exists,
                                 L_bracket_exists;
   close C_CHK_EDI_COST_LOC;
   ---
   if I_new_ind = 'Y' then
      ---
      if SYSTEM_OPTIONS_SQL.GET_DEFAULT_UOM_AND_NAMES(O_error_message,
                                                      L_default_standard_uom,
                                                      L_default_dimension_uom,
                                                      L_default_weight_uom,
                                                      L_default_packing_method,
                                                      L_default_pallet_name,
                                                      L_default_case_name,
                                                      L_default_inner_name) = FALSE then
         return FALSE;
      else
          L_standard_uom := nvl(I_standard_uom, L_default_standard_uom);
          L_packing_method := nvl(I_packing_method, L_default_packing_method);
      end if;
      ---
      L_retail_zone_group_id := I_retail_zone_group_id ;
      if I_item_xform_ind = 'N' then
         if I_retail_zone_group_id is null then
            L_sellable_ind := 'N';
         else
            L_sellable_ind := 'Y';
         end if;
         L_orderable_ind := 'Y' ;
         L_inventory_ind := 'Y' ;
      else
         L_sellable_ind  := 'N';
         L_retail_zone_group_id := NULL;
         L_orderable_ind := 'Y' ;
         L_inventory_ind := 'Y' ;
      end if;
      ---
      if I_item_level > I_tran_level then
         if PM_RETAIL_API_SQL.CHECK_RETAIL_EXISTS(O_error_message,
                                                  O_no_retail,
                                                  I_item_parent) = FALSE then
            return FALSE;
         end if;

         if O_no_retail = 'N' then
            return TRUE;
         end if;
         ---
         open C_REF_ITEM;
         fetch C_REF_ITEM into L_ref_exist;
         close C_REF_ITEM;
         ---
         if L_ref_exist is not null then
            L_primary_ref_item_ind := 'N';
         else
            L_primary_ref_item_ind := 'Y';
         end if;
      end if;
      --- end of Item_level > I_tran_level
      ---

      insert into item_master(item,
                              item_number_type,
                              format_id,
                              prefix,
                              item_parent,
                              item_grandparent,
                              pack_ind,
                              item_level,
                              tran_level,
                              item_aggregate_ind,
                              diff_1,
                              diff_1_aggregate_ind,
                              diff_2,
                              diff_2_aggregate_ind,
                              diff_3,
                              diff_3_aggregate_ind,
                              diff_4,
                              diff_4_aggregate_ind,
                              dept,
                              class,
                              subclass,
                              status,
                              item_desc,
                              short_desc,
                              desc_up,
                              primary_ref_item_ind,
                              retail_zone_group_id,
                              cost_zone_group_id,
                              standard_uom,
                              uom_conv_factor,
                              package_size,
                              package_uom,
                              merchandise_ind,
                              store_ord_mult,
                              forecast_ind,
                              original_retail,
                              mfg_rec_retail,
                              retail_label_type,
                              retail_label_value,
                              handling_temp,
                              handling_sensitivity,
                              catch_weight_ind,
                              first_received,
                              last_received,
                              qty_received,
                              waste_type,
                              waste_pct,
                              default_waste_pct,
                              const_dimen_ind,
                              simple_pack_ind,
                              contains_inner_ind,
                              sellable_ind,
                              orderable_ind,
                              pack_type,
                              order_as_type,
                              comments,
                              gift_wrap_ind,
                              ship_alone_ind,
                              create_datetime,
                              last_update_id,
                              last_update_datetime,
                              item_xform_ind,
                              inventory_ind)
                       values(I_item,
                              I_item_number_type,
                              I_format_id,
                              I_prefix,
                              I_item_parent,
                              I_item_grandparent,
                              'N',
                              I_item_level,
                              I_tran_level,
                              'N',
                              I_diff_1,
                              'N',
                              I_diff_2,
                              'N',
                              I_diff_3,
                              'N',
                              I_diff_4,
                              'N',
                              I_dept,
                              I_class,
                              I_subclass,
                              'W',
                              I_item_desc,
                              I_short_desc,
                              UPPER(I_item_desc),
                              L_primary_ref_item_ind,
                              L_retail_zone_group_id,
                              I_cost_zone_group_id,
                              L_standard_uom,
                              I_uom_conv_factor,
                              Null,
                              Null,
                              'Y',
                              I_store_ord_mult,
                              'N',
                              Null,
                              Null,
                              Null,
                              Null,
                              Null,
                              Null,
                              'N', -- look into catch weight indicator
                              Null,
                              Null,
                              Null,
                              Null,
                              Null,
                              Null,
                              'N',
                              'N',
                              'N',
                              L_sellable_ind,
                              L_orderable_ind,
                              Null,
                              Null,
                              Null,
                              'N',
                              'N',
                              L_sysdate,
                              L_user,
                              L_sysdate,
                              I_item_xform_ind,
                              L_inventory_ind);

      ---
      insert into item_supplier(item,
                                supplier,
                                primary_supp_ind,
                                vpn,
                                supp_label,
                                consignment_rate,
                                supp_diff_1,
                                supp_diff_2,
                                supp_diff_3,
                                supp_diff_4,
                                pallet_name,
                                case_name,
                                inner_name,
                                supp_discontinue_date,
                                direct_ship_ind,
                                last_update_datetime,
                                last_update_id,
                                create_datetime)
                         values(I_item,
                                I_supplier,
                                'Y',
                                I_vpn,
                                NULL,

                                I_consignment_rate,

                                I_supp_diff_1,
                                I_supp_diff_2,
                                I_supp_diff_3,
                                I_supp_diff_4,
                                L_default_pallet_name,
                                L_default_case_name,
                                L_default_inner_name,
                                NULL,
                                'N',
                                L_sysdate,
                                L_user,
                                L_sysdate);

      -- create vat_item record if the vat indicator is set to Yes
      ---
      if I_vat_ind = 'Y' then
         if VAT_SQL.INSERT_VAT_SKU(O_error_message,
                                   I_item,
                                   I_dept,
                                   null,
                                   null,
                                   null,
                                   L_sysdate,
                                   L_user,
                                   L_sysdate,
                                   'B' ) = FALSE then
            return FALSE;
         end if;
         if NOT UDA_SQL.ASSIGN_DEFAULTS(O_error_message,
                                        I_item,
                                        I_dept,
                                        I_class,
                                        I_subclass) then
            return FALSE;
         end if;
         if ITEM_CHARGE_SQL.DEFAULT_CHRGS(O_error_message,
                                          I_item,
                                          I_item_level,
                                          I_tran_level,
                                          'N',
                                          NULL,
                                          I_dept) = FALSE then
            return FALSE;
         end if;
         if I_item_level != 1 then
            if SEASON_SQL.ASSIGN_DEFAULTS(O_error_message,
                                          I_item) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
      ---
      if I_item_level <= I_tran_level then
         /* Fetch Item's
            Rounding Info. */

         if ITEM_SUPP_COUNTRY_SQL.GET_DFLT_RND_LVL_ITEM(O_error_message,
                                                        L_round_lvl,
                                                        L_round_to_inner_pct,
                                                        L_round_to_case_pct,
                                                        L_round_to_layer_pct,
                                                        L_round_to_pallet_pct,
                                                        I_item,
                                                        I_supplier,
                                                        I_dept,
                                                        I_origin_country_id,
                                                        NULL) = FALSE then
            return FALSE;
         end if;
         --
         -- 1 is added onto the lead time passed to the function because
         -- lead time is defined by the supplier as the time that it takes to fill and
         -- ship an order once the order has been received.  Retek determines
         -- lead time (here) to be the time it takes to fill an order after
         -- it has been sent from the Retek system (that is, including the time
         -- it takes the order to get from here to there).
         --
         insert into item_supp_country(item,
                                       supplier,
                                       origin_country_id,
                                       unit_cost,
                                       lead_time,
                                       supp_pack_size,
                                       inner_pack_size,
                                       round_lvl,
                                       round_to_inner_pct,
                                       round_to_case_pct,
                                       round_to_layer_pct,
                                       round_to_pallet_pct,
                                       min_order_qty,
                                       max_order_qty,
                                       packing_method,
                                       primary_supp_ind,
                                       primary_country_ind,
                                       default_uop,
                                       ti,
                                       hi,
                                       supp_hier_type_1,
                                       supp_hier_lvl_1,
                                       supp_hier_type_2,
                                       supp_hier_lvl_2,
                                       supp_hier_type_3,
                                       supp_hier_lvl_3,
                                       last_update_datetime,
                                       last_update_id,
                                       create_datetime,
                                       cost_uom
                                       )
                                values(I_item,
                                       I_supplier,
                                       I_origin_country_id,
                                       I_unit_cost,
                                       I_lead_time + 1,
                                       nvl(I_supp_pack_size, 1),
                                       nvl(I_inner_pack_size, 1),
                                       L_round_lvl,
                                       L_round_to_inner_pct,
                                       L_round_to_case_pct,
                                       L_round_to_layer_pct,
                                       L_round_to_pallet_pct,
                                       I_min_order_qty,
                                       I_max_order_qty,
                                       L_packing_method,
                                       'Y',
                                       'Y',
                                       I_default_uop,
                                       nvl(I_ti, 1),
                                       nvl(I_hi, 1),
                                       Null,
                                       Null,
                                       Null,
                                       Null,
                                       Null,
                                       Null,
                                       L_sysdate,
                                       L_user,
                                       L_sysdate,
                                       I_standard_uom
                                       );
         ---
         if I_unit_length is not null or
            I_unit_width is not null or
            I_unit_height is not null or
            I_unit_weight is not null or
            I_unit_net_weight is not null or
            I_unit_liquid_vol is not null then
            ---
            insert into item_supp_country_dim(item,
                                              supplier,
                                              origin_country,
                                              dim_object,
                                              presentation_method,
                                              length,
                                              width,
                                              height,
                                              lwh_uom,
                                              weight,
                                              net_weight,
                                              weight_uom,
                                              liquid_volume,
                                              liquid_volume_uom,
                                              stat_cube,
                                              tare_weight,
                                              tare_type,
                                              last_update_datetime,
                                              last_update_id,
                                              create_datetime)
                                       values(I_item,
                                              I_supplier,
                                              I_origin_country_id,
                                              'EA',
                                              Null,
                                              I_unit_length,
                                              I_unit_width,
                                              I_unit_height,
                                              I_unit_lwh_uom,
                                              I_unit_weight,
                                              I_unit_net_weight,
                                              I_unit_weight_uom,
                                              I_unit_liquid_vol,
                                              I_unit_liquid_uom,
                                              Null,
                                              Null,
                                              Null,
                                              L_sysdate,
                                              L_user,
                                              L_sysdate);
         end if;
         ---
         if I_case_length is not null or
            I_case_width is not null or
            I_case_height is not null or
            I_case_weight is not null or
            I_case_net_weight is not null or
            I_case_liquid_vol is not null then
            ---
            insert into item_supp_country_dim(item,
                                              supplier,
                                              origin_country,
                                              dim_object,
                                              presentation_method,
                                              length,
                                              width,
                                              height,
                                              lwh_uom,
                                              weight,
                                              net_weight,
                                              weight_uom,
                                              liquid_volume,
                                              liquid_volume_uom,
                                              stat_cube,
                                              tare_weight,
                                              tare_type,
                                              last_update_datetime,
                                              last_update_id,
                                              create_datetime)
                                       values(I_item,
                                              I_supplier,
                                              I_origin_country_id,
                                              'CA',
                                              Null,
                                              I_case_length,
                                              I_case_width,
                                              I_case_height,
                                              I_case_lwh_uom,
                                              I_case_weight,
                                              I_case_net_weight,
                                              I_case_weight_uom,
                                              I_case_liquid_vol,
                                              I_case_liquid_uom,
                                              Null,
                                              Null,
                                              Null,
                                              L_sysdate,
                                              L_user,
                                              L_sysdate);
         end if;
         ---
         if I_pallet_length is not null or I_pallet_width is not null or I_pallet_height is not null or
            I_pallet_weight is not null or I_pallet_net_weight is not null then
            ---
            insert into item_supp_country_dim(item,
                                              supplier,
                                              origin_country,
                                              dim_object,
                                              presentation_method,
                                              length,
                                              width,
                                              height,
                                              lwh_uom,
                                              weight,
                                              net_weight,
                                              weight_uom,
                                              liquid_volume,
                                              liquid_volume_uom,
                                              stat_cube,
                                              tare_weight,
                                              tare_type,
                                              last_update_datetime,
                                              last_update_id,
                                              create_datetime)
                                       values(I_item,
                                              I_supplier,
                                              I_origin_country_id,
                                              'PA',
                                              Null,
                                              I_pallet_length,
                                              I_pallet_width,
                                              I_pallet_height,
                                              I_pallet_lwh_uom,
                                              I_pallet_weight,
                                              I_pallet_net_weight,
                                              I_pallet_weight_uom,
                                              NULL,
                                              NULL,
                                              Null,
                                              Null,
                                              Null,
                                              L_sysdate,
                                              L_user,
                                              L_sysdate);
         end if;
         ---
         ---
         if DEFAULT_PRICES(O_error_message)= FALSE then
            return FALSE;
         end if;
         -- The first call to item_expense_sql.default_expenses
         -- creates zone level expenses.  The second
         -- call creates country level expenses.
         if I_elc_ind = 'Y' then
            if ITEM_EXPENSE_SQL.DEFAULT_EXPENSES(O_error_message,
                                                 I_item,
                                                 I_supplier,
                                                 NULL) = FALSE then
               return FALSE;
            end if;
            if ITEM_EXPENSE_SQL.DEFAULT_EXPENSES(O_error_message,
                                                 I_item,
                                                 I_supplier,
                                                 I_origin_country_id) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
   end if;
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
END BUILD_ITEM;
-----------------------------------------------------------------------------------------------------------------
FUNCTION EDI_LIKE_ITEM_INSERT(O_error_message IN OUT VARCHAR2,
                              I_supplier_ind  IN     VARCHAR2,
                              I_price_ind     IN     VARCHAR2,
                              I_store_ind     IN     VARCHAR2,
                              I_wh_ind        IN     VARCHAR2,
                              I_repl_ind      IN     VARCHAR2,
                              I_uda_ind       IN     VARCHAR2,
                              I_seasons_ind   IN     VARCHAR2,
                              I_ticket_ind    IN     VARCHAR2,
                              I_req_doc_ind   IN     VARCHAR2,
                              I_hts_ind       IN     VARCHAR2,
                              I_tax_code_ind  IN     VARCHAR2,
                              I_children_ind  IN     VARCHAR2,
                              I_diff_1        IN     ITEM_MASTER.DIFF_1%TYPE,
                              I_diff_2        IN     ITEM_MASTER.DIFF_2%TYPE,
                              I_diff_3        IN     ITEM_MASTER.DIFF_3%TYPE,
                              I_diff_4        IN     ITEM_MASTER.DIFF_4%TYPE,
                              I_existing_item IN     ITEM_MASTER.ITEM%TYPE,
                              I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_user          USER_USERS.USERNAME%TYPE;
   L_sysdate       PERIOD.VDATE%TYPE;
   L_program       VARCHAR2(64) := 'EDITEM_SQL.EDI_LIKE_ITEM_INSERT';

   cursor C_GET_USER is
      select sysdate,
             user
        from dual;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   elsif I_existing_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   end if;

   open C_GET_USER;
   fetch C_GET_USER into L_sysdate,
                         L_user;
   close C_GET_USER;

   insert into edi_like_item(item,
                            existing_item,
                            diff_1,
                            diff_2,
                            diff_3,
                            diff_4,
                            children_ind,
                            supplier_ind,
                            price_ind,
                            store_ind,
                            wh_ind,
                            repl_ind,
                            uda_ind,
                            seasons_ind,
                            ticket_ind,
                            tax_code_ind,
                            req_doc_ind,
                            hts_ind,
                            create_datetime,
                            last_update_datetime,
                            last_update_id)
                     values(I_item,
                            I_existing_item,
                            I_diff_1,
                            I_diff_2,
                            I_diff_3,
                            I_diff_4,
                            I_children_ind,
                            I_supplier_ind,
                            I_price_ind,
                            I_store_ind,
                            I_wh_ind,
                            I_repl_ind,
                            I_uda_ind,
                            I_seasons_ind,
                            I_ticket_ind,
                            I_tax_code_ind,
                            I_req_doc_ind,
                            I_hts_ind,
                            L_sysdate,
                            L_sysdate,
                            L_user);

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END EDI_LIKE_ITEM_INSERT;
-----------------------------------------------------------------------------------------------------------------
FUNCTION EDI_LIKE_ITEM_UPDATE(O_error_message IN OUT VARCHAR2,
                              I_supplier_ind  IN     VARCHAR2,
                              I_price_ind     IN     VARCHAR2,
                              I_store_ind     IN     VARCHAR2,
                              I_wh_ind        IN     VARCHAR2,
                              I_repl_ind      IN     VARCHAR2,
                              I_uda_ind       IN     VARCHAR2,
                              I_seasons_ind   IN     VARCHAR2,
                              I_ticket_ind    IN     VARCHAR2,
                              I_req_doc_ind   IN     VARCHAR2,
                              I_hts_ind       IN     VARCHAR2,
                              I_tax_code_ind  IN     VARCHAR2,
                              I_children_ind  IN     VARCHAR2,
                              I_diff_1        IN     ITEM_MASTER.DIFF_1%TYPE,
                              I_diff_2        IN     ITEM_MASTER.DIFF_2%TYPE,
                              I_diff_3        IN     ITEM_MASTER.DIFF_3%TYPE,
                              I_diff_4        IN     ITEM_MASTER.DIFF_4%TYPE,
                              I_existing_item IN     ITEM_MASTER.ITEM%TYPE,
                              I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_user          USER_USERS.USERNAME%TYPE;
   L_sysdate       PERIOD.VDATE%TYPE;
   L_program       VARCHAR2(64) := 'EDITEM_SQL.EDI_LIKE_ITEM_UPDATE';
   L_table         VARCHAR2(30);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_GET_USER is
      select sysdate,
             user
        from dual;

   cursor C_LOCK_EDI_LIKE_ITEM is
      select 'x'
        from edi_like_item
       where item = I_item
         for update nowait;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   end if;

   open C_GET_USER;
   fetch C_GET_USER into L_sysdate,
                         L_user;
   close C_GET_USER;

   L_table := 'EDI_LIKE_ITEM';

   open C_LOCK_EDI_LIKE_ITEM;
   close C_LOCK_EDI_LIKE_ITEM;

   update edi_like_item
      set supplier_ind          =      I_supplier_ind,
          price_ind             =      I_price_ind,
          store_ind             =      I_store_ind,
          wh_ind                =      I_wh_ind,
          repl_ind              =      I_repl_ind,
          uda_ind               =      I_uda_ind,
          seasons_ind           =      I_seasons_ind,
          ticket_ind            =      I_ticket_ind,
          tax_code_ind          =      I_tax_code_ind,
          req_doc_ind           =      I_req_doc_ind,
          hts_ind               =      I_hts_ind,
          children_ind          =      I_children_ind,
          diff_1                =      I_diff_1,
          diff_2                =      I_diff_2,
          diff_3                =      I_diff_3,
          diff_4                =      I_diff_4,
          existing_item         =      I_existing_item,
          last_update_id        =      L_user,
          last_update_datetime  =      L_sysdate
    where item = I_item;

return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_program,
                                            I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END EDI_LIKE_ITEM_UPDATE;
-----------------------------------------------------------------------------------------------------------------
FUNCTION EDI_LIKE_ITEM_DELETE(O_error_message IN OUT VARCHAR2,
                              I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_program       VARCHAR2(64) := 'EDITEM_SQL.EDI_LIKE_ITEM_DELETE';

   cursor C_LOCK_EDI_LIKE_ITEM is
      select 'x'
        from edi_like_item
       where item = I_item
         for update nowait;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   end if;

   open C_LOCK_EDI_LIKE_ITEM;
   close C_LOCK_EDI_LIKE_ITEM;

   delete from edi_like_item
    where item = I_item;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END EDI_LIKE_ITEM_DELETE;
-----------------------------------------------------------------------------------------------------------------
FUNCTION EDI_LIKE_ITEM_EXISTS(O_error_message IN OUT VARCHAR2,
                              O_existing_item IN OUT VARCHAR2,
                              I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_program         VARCHAR2(64) := 'EDITEM_SQL.EDI_LIKE_ITEM_EXISTS';

   cursor C_EXISTS is
      select existing_item
        from edi_like_item
       where item = I_item;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   end if;

   O_existing_item := Null;

   open C_EXISTS;
   fetch C_EXISTS into O_existing_item;
   close C_EXISTS;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END EDI_LIKE_ITEM_EXISTS;
-----------------------------------------------------------------------------------------------------------------
FUNCTION GET_LIKE_ITEM_IND(O_error_message IN OUT VARCHAR2,
                           O_supplier_ind  IN OUT VARCHAR2,
                           O_price_ind     IN OUT VARCHAR2,
                           O_store_ind     IN OUT VARCHAR2,
                           O_wh_ind        IN OUT VARCHAR2,
                           O_repl_ind      IN OUT VARCHAR2,
                           O_uda_ind       IN OUT VARCHAR2,
                           O_seasons_ind   IN OUT VARCHAR2,
                           O_ticket_ind    IN OUT VARCHAR2,
                           O_req_doc_ind   IN OUT VARCHAR2,
                           O_hts_ind       IN OUT VARCHAR2,
                           O_tax_code_ind  IN OUT VARCHAR2,
                           O_children_ind  IN OUT VARCHAR2,
                           O_diff_1        IN OUT ITEM_MASTER.DIFF_1%TYPE,
                           O_diff_2        IN OUT ITEM_MASTER.DIFF_2%TYPE,
                           O_diff_3        IN OUT ITEM_MASTER.DIFF_3%TYPE,
                           O_diff_4        IN OUT ITEM_MASTER.DIFF_4%TYPE,
                           O_existing_item IN OUT ITEM_MASTER.ITEM%TYPE,
                           I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_program       VARCHAR2(64) := 'EDITEM_SQL.GET_LIKE_ITEM_IND';

   cursor C_GET_LIKE_ITEM_IND is
      select supplier_ind,
             price_ind,
             store_ind,
             wh_ind,
             uda_ind,
             seasons_ind,
             ticket_ind,
             tax_code_ind,
             req_doc_ind,
             hts_ind,
             children_ind,
             diff_1,
             diff_2,
             diff_3,
             diff_4,
             existing_item
        from edi_like_item
       where item = I_item;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   end if;

   open C_GET_LIKE_ITEM_IND;
   fetch C_GET_LIKE_ITEM_IND into O_supplier_ind,
                                  O_price_ind,
                                  O_store_ind,
                                  O_wh_ind,
                                  O_uda_ind,
                                  O_seasons_ind,
                                  O_ticket_ind,
                                  O_tax_code_ind,
                                  O_req_doc_ind,
                                  O_hts_ind,
                                  O_children_ind,
                                  O_diff_1,
                                  O_diff_2,
                                  O_diff_3,
                                  O_diff_4,
                                  O_existing_item;
   close C_GET_LIKE_ITEM_IND;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_LIKE_ITEM_IND;
-----------------------------------------------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message               IN OUT         VARCHAR2,
                  O_diff_1                      IN OUT          ITEM_MASTER.DIFF_1%TYPE,
                  O_diff_2                      IN OUT          ITEM_MASTER.DIFF_2%TYPE,
                  O_diff_3                      IN OUT          ITEM_MASTER.DIFF_3%TYPE,
                  O_diff_4                      IN OUT          ITEM_MASTER.DIFF_4%TYPE,
                  O_dept                        IN OUT      ITEM_MASTER.DEPT%TYPE,
                  O_class                       IN OUT      ITEM_MASTER.CLASS%TYPE,
                  O_subclass                    IN OUT      ITEM_MASTER.SUBCLASS%TYPE,
                  O_short_desc                  IN OUT      ITEM_MASTER.SHORT_DESC%TYPE,
                  O_retail_zone_group_id        IN OUT      ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                  O_cost_zone_group_id    IN OUT      ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE,
                  O_standard_uom          IN OUT      ITEM_MASTER.STANDARD_UOM%TYPE,
                  O_uom_conv_factor       IN OUT      ITEM_MASTER.UOM_CONV_FACTOR%TYPE,
                  O_store_ord_mult        IN OUT      ITEM_MASTER.STORE_ORD_MULT%TYPE,
                  O_supplier              IN OUT      ITEM_SUPPLIER.SUPPLIER%TYPE,
                  O_vpn                   IN OUT      ITEM_SUPPLIER.VPN%TYPE,
                  O_supp_diff_1        IN OUT      ITEM_SUPPLIER.SUPP_DIFF_1%TYPE,
                  O_supp_diff_2        IN OUT      ITEM_SUPPLIER.SUPP_DIFF_2%TYPE,
                  O_supp_diff_3        IN OUT      ITEM_SUPPLIER.SUPP_DIFF_3%TYPE,
                  O_supp_diff_4        IN OUT      ITEM_SUPPLIER.SUPP_DIFF_4%TYPE,
                  O_origin_country_id        IN OUT      ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                  O_lead_time                IN OUT      ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE,
                  O_unit_cost          IN OUT      ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                  O_supp_pack_size           IN OUT      ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE,
                  O_inner_pack_size          IN OUT      ITEM_SUPP_COUNTRY.INNER_PACK_SIZE%TYPE,
                  O_min_order_qty            IN OUT      ITEM_SUPP_COUNTRY.MIN_ORDER_QTY%TYPE,
                  O_max_order_qty            IN OUT      ITEM_SUPP_COUNTRY.MAX_ORDER_QTY%TYPE,
                  O_packing_method           IN OUT      ITEM_SUPP_COUNTRY.PACKING_METHOD%TYPE,
                  O_default_uop              IN OUT      ITEM_SUPP_COUNTRY.DEFAULT_UOP%TYPE,
                  O_ti           IN OUT      ITEM_SUPP_COUNTRY.TI%TYPE,
                  O_hi           IN OUT      ITEM_SUPP_COUNTRY.HI%TYPE,
                  O_unit_length        IN OUT      ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE,
                  O_unit_width         IN OUT      ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE,
                  O_unit_height        IN OUT      ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE,
                  O_unit_lwh_uom    IN OUT      ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE,
                  O_net_unit_weight          IN OUT      ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE,
                  O_gross_unit_weight          IN OUT    ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                  O_unit_weight_uom          IN OUT      ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE,
                  O_unit_liquid_vol          IN OUT      ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE,
                  O_unit_liquid_uom          IN OUT      ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE,
                  O_case_length                  IN OUT     ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE,
                  O_case_width                   IN OUT     ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE,
                  O_case_height                  IN OUT     ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE,
                  O_case_lwh_uom    IN OUT      ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE,
                  O_net_case_weight          IN OUT      ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE,
                  O_gross_case_weight           IN OUT      ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                  O_case_weight_uom          IN OUT      ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE,
                  O_case_liquid_vol          IN OUT      ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE,
                  O_case_liquid_uom          IN OUT      ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE,
                  O_pallet_length         IN OUT      ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE,
                  O_pallet_width    IN OUT      ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE,
                  O_pallet_height         IN OUT      ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE,
                  O_pallet_lwh_uom           IN OUT      ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE,
                  O_net_pallet_weight           IN OUT      ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE,
                  O_gross_pallet_weight           IN OUT    ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                  O_pallet_weight_uom           IN OUT      ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE,
                  O_item_parent                 IN OUT          ITEM_MASTER.ITEM%TYPE,
                  I_item                        IN               ITEM_MASTER.ITEM%TYPE)

   return BOOLEAN is

   L_program       VARCHAR2(64) := 'EDITEM_SQL.GET_INFO';

   cursor C_GET_INFO is
      select diff_1,
             diff_2,
             diff_3,
             diff_4,
             dept,
             class,
             subclass,
             short_desc,
             retail_zone_group_id,
             cost_zone_group_id,
             standard_uom,
             uom_conv_factor,
             store_ord_mult,
             supplier,
             vpn,
             supp_diff_1,
             supp_diff_2,
             supp_diff_3,
             supp_diff_4,
             origin_country_id,
             lead_time,
             unit_cost,
             supp_pack_size,
             inner_pack_size,
             min_order_qty,
             max_order_qty,
             packing_method,
             default_uop,
             ti,
             hi,
             unit_length,
             unit_width,
             unit_height,
             unit_lwh_uom,
             net_unit_weight,
             gross_unit_weight,
             unit_weight_uom,
             unit_liquid_vol,
             unit_liquid_vol_uom,
             case_length,
             case_width,
             case_height,
             case_lwh_uom,
             net_case_weight,
             gross_case_weight,
             case_weight_uom,
             case_liquid_vol,
             case_liquid_vol_uom,
             pallet_length,
             pallet_width,
             pallet_height,
             pallet_lwh_uom,
             net_pallet_weight,
             gross_pallet_weight,
             pallet_weight_uom,
             item_parent
        from edi_new_item
       where (item = I_item
          or item_parent = I_item);

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   end if;

   open C_GET_INFO;
   fetch C_GET_INFO into O_diff_1,
                         O_diff_2,
                         O_diff_3,
                         O_diff_4,
                         O_dept,
                         O_class,
                         O_subclass,
                         O_short_desc,
                         O_retail_zone_group_id,
                         O_cost_zone_group_id,
                         O_standard_uom,
                         O_uom_conv_factor,
                         O_store_ord_mult,
                         O_supplier,
                         O_vpn,
                         O_supp_diff_1,
                         O_supp_diff_2,
                         O_supp_diff_3,
                         O_supp_diff_4,
                         O_origin_country_id,
                         O_lead_time,
                         O_unit_cost,
                         O_supp_pack_size,
                         O_inner_pack_size,
                         O_min_order_qty,
                         O_max_order_qty,
                         O_packing_method,
                         O_default_uop,
                         O_ti,
                         O_hi,
                         O_unit_length,
                         O_unit_width,
                         O_unit_height,
                         O_unit_lwh_uom,
                         O_net_unit_weight,
                         O_gross_unit_weight,
                         O_unit_weight_uom,
                         O_unit_liquid_vol,
                         O_unit_liquid_uom,
                         O_case_length,
                         O_case_width,
                         O_case_height,
                         O_case_lwh_uom,
                         O_net_case_weight,
                         O_gross_case_weight,
                         O_case_weight_uom,
                         O_case_liquid_vol,
                         O_case_liquid_uom,
                         O_pallet_length,
                         O_pallet_width,
                         O_pallet_height,
                         O_pallet_lwh_uom,
                         O_net_pallet_weight,
                         O_gross_pallet_weight,
                         O_pallet_weight_uom,
                         O_item_parent;
   close C_GET_INFO;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_INFO;
-----------------------------------------------------------------------------------------------------------------
FUNCTION SUPP_COUNT (O_error_message            IN OUT          VARCHAR2,
                     O_supplier                 IN OUT          SUPS.SUPPLIER%TYPE,
                     I_item                     IN              ITEM_MASTER.ITEM%TYPE)

   return BOOLEAN is

   L_program       VARCHAR2(64) := 'EDITEM_SQL.SUPP_COUNT';
   L_count         NUMBER;

   cursor C_SUPP_COUNT is
      select count(supplier)
        from item_supplier
       where item = I_item;

   cursor C_GET_SUPP is
      select supplier
        from item_supplier
       where item = I_item;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   end if;

   open C_SUPP_COUNT;
   fetch C_SUPP_COUNT into L_count;
   close C_SUPP_COUNT;

   if L_count = 1 then
      open C_GET_SUPP;
      fetch C_GET_SUPP into O_supplier;
      close C_GET_SUPP;
   else
      O_supplier := NULL;
   end if;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END SUPP_COUNT;
-----------------------------------------------------------------------------------------------------------------
FUNCTION SIMPLE_PACK_TEMP_INSERT (O_error_message         IN OUT          VARCHAR2,
                                  I_pack_no                IN              SIMPLE_PACK_TEMP.PACK_NO%TYPE,
                                  I_item_number_type       IN              SIMPLE_PACK_TEMP.ITEM_NUMBER_TYPE%TYPE,
                                  I_item                   IN              SIMPLE_PACK_TEMP.ITEM%TYPE,
                                  I_pack_desc              IN              SIMPLE_PACK_TEMP.PACK_DESC%TYPE,
                                  I_item_qty               IN              SIMPLE_PACK_TEMP.ITEM_QTY%TYPE,
                                  I_primary_supp           IN              SIMPLE_PACK_TEMP.PRIMARY_SUPP%TYPE,
                                  I_primary_cntry_id       IN              SIMPLE_PACK_TEMP.PRIMARY_CNTRY_ID%TYPE,
                                  I_unit_cost              IN              SIMPLE_PACK_TEMP.UNIT_COST%TYPE,
                                  I_sellable_ind           IN              SIMPLE_PACK_TEMP.SELLABLE_IND%TYPE,
                                  I_vpn                    IN              SIMPLE_PACK_TEMP.VPN%TYPE,
                                  I_supp_pack_size         IN              SIMPLE_PACK_TEMP.SUPP_PACK_SIZE%TYPE,
                                  I_ti                     IN              SIMPLE_PACK_TEMP.TI%TYPE,
                                  I_hi                     IN              SIMPLE_PACK_TEMP.HI%TYPE,
                                  I_case_length            IN              SIMPLE_PACK_TEMP.CASE_LENGTH%TYPE,
                                  I_case_width             IN              SIMPLE_PACK_TEMP.CASE_WIDTH%TYPE,
                                  I_case_height            IN              SIMPLE_PACK_TEMP.CASE_HEIGHT%TYPE,
                                  I_case_lwh_uom           IN              SIMPLE_PACK_TEMP.CASE_LWH_UOM%TYPE,
                                  I_case_weight            IN              SIMPLE_PACK_TEMP.CASE_WEIGHT%TYPE,
                                  I_case_net_weight        IN              SIMPLE_PACK_TEMP.CASE_NET_WEIGHT%TYPE,
                                  I_case_weight_uom        IN              SIMPLE_PACK_TEMP.CASE_WEIGHT_UOM%TYPE,
                                  I_case_liquid_vol        IN              SIMPLE_PACK_TEMP.CASE_LIQUID_VOLUME%TYPE,
                                  I_case_liquid_vol_uom    IN              SIMPLE_PACK_TEMP.CASE_LIQUID_VOLUME_UOM%TYPE,
                                  I_pallet_length          IN              SIMPLE_PACK_TEMP.PALLET_LENGTH%TYPE,
                                  I_pallet_width           IN              SIMPLE_PACK_TEMP.PALLET_WIDTH%TYPE,
                                  I_pallet_height          IN              SIMPLE_PACK_TEMP.PALLET_HEIGHT%TYPE,
                                  I_pallet_lwh_uom         IN              SIMPLE_PACK_TEMP.PALLET_LWH_UOM%TYPE,
                                  I_pallet_weight          IN              SIMPLE_PACK_TEMP.PALLET_WEIGHT%TYPE,
                                  I_pallet_net_weight      IN              SIMPLE_PACK_TEMP.PALLET_NET_WEIGHT%TYPE,
                                  I_pallet_weight_uom      IN              SIMPLE_PACK_TEMP.PALLET_WEIGHT_UOM%TYPE)
   return Boolean is

   L_program       VARCHAR2(64) := 'EDITEM_SQL.SIMPLE_PACK_TEMP_INSERT';
   L_unit_retail   ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE;
   L_cost_uom      SIMPLE_PACK_TEMP.COST_UOM%TYPE;
   L_dummy_zone_gr ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE;
   L_dummy_zone    ITEM_ZONE_PRICE.ZONE_ID%TYPE;
   L_dummy_retail  ITEM_LOC.UNIT_RETAIL%TYPE;
   L_dummy_uom     ITEM_ZONE_PRICE.SELLING_UOM%TYPE;
   L_dummy_units   ITEM_ZONE_PRICE.MULTI_UNITS%TYPE;

   cursor C_GET_ISC_COST_UOM is
      select cost_uom
        from item_supp_country
       where origin_country_id = I_primary_cntry_id
         and supplier = I_primary_supp
         and item = I_item;

BEGIN

   if I_pack_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_pack_no','NULL','NOT NULL');
      return FALSE;
   elsif I_item_number_type is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item_number_type','NOT NULL','NULL');
      return FALSE;
   elsif I_item is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   elsif I_pack_desc is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_pack_desc','NOT NULL','NULL');
      return FALSE;
   elsif I_primary_supp is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_primary_supp','NOT NULL','NULL');
      return FALSE;
   elsif I_primary_cntry_id is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_primary_cntry_id','NOT NULL','NULL');
      return FALSE;
   elsif I_unit_cost is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_unit_cost','NOT NULL','NULL');
      return FALSE;
   end if;

   if PRICING_ATTRIB_SQL.GET_BASE_ZONE_RETAIL(O_error_message,
                                              L_dummy_zone_gr,
                                              L_dummy_zone,
                                              L_unit_retail,
                                              L_dummy_uom,
                                              L_dummy_retail,
                                              L_dummy_uom,
                                              L_dummy_units,
                                              L_dummy_retail,
                                              L_dummy_uom,
                                              I_item) = FALSE then
      return FALSE;
   end if;

   open  C_GET_ISC_COST_UOM;
   fetch C_GET_ISC_COST_UOM into L_cost_uom;
   close C_GET_ISC_COST_UOM;

   insert into simple_pack_temp(pack_no,
                                item_number_type,
                                item,
                                pack_desc,
                                item_qty,
                                primary_supp,
                                primary_cntry_id,
                                unit_cost,
                                const_dimen_ind,
                                sellable_ind,
                                unit_retail,
                                vpn,
                                supp_pack_size,
                                ti,
                                hi,
                                case_length,
                                case_width,
                                case_height,
                                case_lwh_uom,
                                case_weight,
                                case_net_weight,
                                case_weight_uom,
                                case_liquid_volume,
                                case_liquid_volume_uom,
                                pallet_length,
                                pallet_width,
                                pallet_height,
                                pallet_lwh_uom,
                                pallet_weight,
                                pallet_net_weight,
                                pallet_weight_uom,
                                pallet_liquid_volume,
                                pallet_liquid_volume_uom,
                                exists_ind,
                                cost_uom)
                         values(I_pack_no,
                                I_item_number_type,
                                I_item,
                                I_pack_desc,
                                nvl(I_item_qty,1),
                                I_primary_supp,
                                I_primary_cntry_id,
                                I_unit_cost,
                                'N',
                                I_sellable_ind,
                                decode(I_item_qty,
                                       1,L_unit_retail,
                                       NULL),
                                I_vpn,
                                1,
                                nvl(I_ti,1),
                                nvl(I_hi,1),
                                I_case_length,
                                I_case_width,
                                I_case_height,
                                I_case_lwh_uom,
                                I_case_weight,
                                I_case_net_weight,
                                I_case_weight_uom,
                                I_case_liquid_vol,
                                I_case_liquid_vol_uom,
                                I_pallet_length,
                                I_pallet_width,
                                I_pallet_height,
                                I_pallet_lwh_uom,
                                I_pallet_weight,
                                I_pallet_net_weight,
                                I_pallet_weight_uom,
                                NULL,
                                NULL,
                                'N',
                                L_cost_uom);
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END SIMPLE_PACK_TEMP_INSERT;
-----------------------------------------------------------------------------------------------------------------
FUNCTION CHILD_ITEM_NUMBER_TYPE (O_error_message            IN OUT          VARCHAR2,
                                 O_item_number_type         IN OUT          ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                                 I_item                     IN              ITEM_MASTER.ITEM%TYPE,
                                 I_item_level               IN              ITEM_MASTER.ITEM_LEVEL%TYPE)

   return BOOLEAN is

   L_program       VARCHAR2(64) := 'EDITEM_SQL.SUPP_COUNT';

   cursor C_ITEM_NUMBER_TYPE is
      select item_number_type
        from item_master
       where (item_parent = I_item
          or item_grandparent = I_item)
         and item_level = I_item_level;

BEGIN

   if I_item is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NOT NULL','NULL');
      return FALSE;
   elsif I_item_level is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item_level','NOT NULL','NULL');
      return FALSE;
   end if;

   open C_ITEM_NUMBER_TYPE;
   fetch C_ITEM_NUMBER_TYPE into O_item_number_type;
   close C_ITEM_NUMBER_TYPE;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END CHILD_ITEM_NUMBER_TYPE;
-----------------------------------------------------------------------------------------------------------------
FUNCTION ITEM_UPDATE (O_error_message                IN OUT  VARCHAR2,
                      O_supp_ctry_exist              IN OUT  VARCHAR2,
                      O_supp_ctry_dim_exist          IN OUT  VARCHAR2,
                      O_item                         IN OUT  ITEM_MASTER.ITEM%TYPE,
                      O_case_supp_ctry_exist         IN OUT  VARCHAR2,
                      O_case_supp_ctry_dim_exist     IN OUT  VARCHAR2,
                      O_case                         IN OUT  ITEM_MASTER.ITEM%TYPE,
                      I_supplier                     IN      ITEM_SUPPLIER.ITEM%TYPE)
   return BOOLEAN is

   L_program                VARCHAR2(64) := 'EDITEM_SQL.ITEM_UPDATE';
   L_item                   ITEM_SUPPLIER.ITEM%TYPE;
   L_case                   EDI_NEW_ITEM.CASE_REF_ITEM%TYPE;
   L_supplier               ITEM_SUPPLIER.SUPPLIER%TYPE;
   L_origin_country_id      ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
   L_lead_time              ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE;
   L_min_order_qty          ITEM_SUPP_COUNTRY.MIN_ORDER_QTY%TYPE;
   L_max_order_qty          ITEM_SUPP_COUNTRY.MAX_ORDER_QTY%TYPE;
   L_gross_unit_weight      EDI_NEW_ITEM.GROSS_UNIT_WEIGHT%TYPE;
   L_net_unit_weight        EDI_NEW_ITEM.NET_UNIT_WEIGHT%TYPE;
   L_unit_width             EDI_NEW_ITEM.UNIT_WIDTH%TYPE;
   L_unit_height            EDI_NEW_ITEM.UNIT_HEIGHT%TYPE;
   L_unit_length            EDI_NEW_ITEM.UNIT_LENGTH%TYPE;
   L_gross_case_weight      EDI_NEW_ITEM.GROSS_CASE_WEIGHT%TYPE;
   L_net_case_weight        EDI_NEW_ITEM.NET_CASE_WEIGHT%TYPE;
   L_case_width             EDI_NEW_ITEM.CASE_WIDTH%TYPE;
   L_case_height            EDI_NEW_ITEM.CASE_HEIGHT%TYPE;
   L_case_length            EDI_NEW_ITEM.CASE_LENGTH%TYPE;
   L_gross_pallet_weight    EDI_NEW_ITEM.GROSS_PALLET_WEIGHT%TYPE;
   L_net_pallet_weight      EDI_NEW_ITEM.NET_PALLET_WEIGHT%TYPE;
   L_pallet_width           EDI_NEW_ITEM.PALLET_WIDTH%TYPE;
   L_pallet_height          EDI_NEW_ITEM.PALLET_HEIGHT%TYPE;
   L_pallet_length          EDI_NEW_ITEM.PALLET_LENGTH%TYPE;
   L_supp_diff_1            EDI_NEW_ITEM.SUPP_DIFF_1%TYPE;
   L_supp_diff_2            EDI_NEW_ITEM.SUPP_DIFF_2%TYPE;
   L_supp_diff_3            EDI_NEW_ITEM.SUPP_DIFF_3%TYPE;
   L_supp_diff_4            EDI_NEW_ITEM.SUPP_DIFF_4%TYPE;
   L_supp_pack_size         EDI_NEW_ITEM.SUPP_PACK_SIZE%TYPE;
   L_inner_pack_size        EDI_NEW_ITEM.INNER_PACK_SIZE%TYPE;
   L_ti                     EDI_NEW_ITEM.TI%TYPE;
   L_hi                     EDI_NEW_ITEM.HI%TYPE;
   L_table                  VARCHAR2(30);
   L_exists                 VARCHAR2(1);
   L_user                   USER_USERS.USERNAME%TYPE := user;
   L_sysdate                PERIOD.VDATE%TYPE := sysdate;
   L_default_standard_uom   SYSTEM_OPTIONS.DEFAULT_STANDARD_UOM%TYPE;
   L_default_dimension_uom  SYSTEM_OPTIONS.DEFAULT_DIMENSION_UOM%TYPE;
   L_default_weight_uom     SYSTEM_OPTIONS.DEFAULT_WEIGHT_UOM%TYPE;
   L_default_packing_method SYSTEM_OPTIONS.DEFAULT_PACKING_METHOD%TYPE;
   L_default_pallet_name    SYSTEM_OPTIONS.DEFAULT_PALLET_NAME%TYPE;
   L_default_case_name      SYSTEM_OPTIONS.DEFAULT_CASE_NAME%TYPE;
   L_default_inner_name     SYSTEM_OPTIONS.DEFAULT_INNER_NAME%TYPE;
   L_item_level             ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level             ITEM_MASTER.TRAN_LEVEL%TYPE;
   RECORD_LOCKED            EXCEPTION;
   PRAGMA                   EXCEPTION_INIT(Record_Locked, -54);

   cursor C_GET_ITEM_UPDATES is
      select item,
             supplier,
             origin_country_id,
             lead_time,
             min_order_qty,
             max_order_qty,
             gross_unit_weight,
             net_unit_weight,
             unit_width,
             unit_height,
             unit_length,
             gross_case_weight,
             net_case_weight,
             case_width,
             case_height,
             case_length,
             gross_pallet_weight,
             net_pallet_weight,
             pallet_width,
             pallet_height,
             pallet_length,
             supp_diff_1,
             supp_diff_2,
             supp_diff_3,
             supp_diff_4,
             supp_pack_size,
             inner_pack_size,
             ti,
             hi
        from edi_new_item
       where status = 'A'
         and new_item_ind = 'N'
         and supplier = I_supplier;

   cursor C_GET_CASE_UPDATES is
      select case_ref_item,
             supplier,
             origin_country_id,
             lead_time,
             min_order_qty,
             max_order_qty,
             gross_unit_weight,
             net_unit_weight,
             unit_width,
             unit_height,
             unit_length,
             gross_case_weight,
             net_case_weight,
             case_width,
             case_height,
             case_length,
             gross_pallet_weight,
             net_pallet_weight,
             pallet_width,
             pallet_height,
             pallet_length,
             supp_diff_1,
             supp_diff_2,
             supp_diff_3,
             supp_diff_4,
             supp_pack_size,
             inner_pack_size,
             ti,
             hi
        from edi_new_item
       where status = 'A'
         and new_case_pack_ind = 'N'
         and supplier = I_supplier;

   cursor C_LOCK_ITEM_SUPPLIER is
      select 'x'
        from item_supplier
       where item = L_item
         and supplier = L_supplier
         for update of item nowait;

   cursor C_LOCK_ITEM_SUPP_COUNTRY is
      select 'x'
       from item_supp_country
      where item = L_item
        and supplier = L_supplier
        for update of item nowait;

   cursor C_LOCK_ITEM_SUPP_COUNTRY_DIM is
      select 'x'
        from item_supplier
       where item = L_item
         and supplier = L_supplier
         for update of item nowait;

   cursor C_ITEM_SUPP_EXIST is
      select 'x'
        from item_supplier
       where item = L_item
         and supplier = L_supplier;

   cursor C_ITEM_SUPP_CTRY_EXIST is
      select 'x'
       from item_supp_country
      where item = L_item
        and supplier = L_supplier;

   cursor C_ITEM_SUPP_CTRY_DIM_EA_EXIST is
      select 'x'
        from item_supp_country_dim
       where item = L_item
         and dim_object = 'EA'
         and supplier = L_supplier;

   cursor C_ITEM_SUPP_CTRY_DIM_CA_EXIST is
      select 'x'
        from item_supp_country_dim
       where item = L_item
         and dim_object = 'CA'
         and supplier = L_supplier;

   cursor C_ITEM_SUPP_CTRY_DIM_PA_EXIST is
      select 'x'
        from item_supp_country_dim
       where item = L_item
         and dim_object = 'PA'
         and supplier = L_supplier;

   cursor C_CASE_TRAN_LEVEL is
      select item_parent
        from item_master
       where item = L_case;

   cursor C_ITEM_SUPP_REF_EXIST IS
      select 'x'
        from item_supplier
       where item = L_case
         and supplier = L_supplier;

   cursor C_LOCK_CASE_REF_ITEM_SUPPLIER is
      select 'x'
        from item_supplier
       where item = L_case
         and supplier = L_supplier
         for update of item nowait;

BEGIN
   if SYSTEM_OPTIONS_SQL.GET_DEFAULT_UOM_AND_NAMES(O_error_message,
                                                   L_default_standard_uom,
                                                   L_default_dimension_uom,
                                                   L_default_weight_uom,
                                                   L_default_packing_method,
                                                   L_default_pallet_name,
                                                   L_default_case_name,
                                                   L_default_inner_name) = FALSE then
      return FALSE;
   end if;
   ---
   FOR C_rec in C_GET_ITEM_UPDATES LOOP

      L_item                 := C_rec.item;
      L_supplier             := C_rec.supplier;
      L_origin_country_id    := C_rec.origin_country_id;
      L_lead_time            := C_rec.lead_time;
      L_min_order_qty        := C_rec.min_order_qty;
      L_max_order_qty        := C_rec.max_order_qty;
      L_gross_unit_weight    := C_rec.gross_unit_weight;
      L_net_unit_weight      := C_rec.net_unit_weight;
      L_unit_width           := C_rec.unit_width;
      L_unit_height          := C_rec.unit_height;
      L_unit_length          := C_rec.unit_length;
      L_gross_case_weight    := C_rec.gross_case_weight;
      L_net_case_weight      := C_rec.net_case_weight;
      L_case_width           := C_rec.case_width;
      L_case_height          := C_rec.case_height;
      L_case_length          := C_rec.case_length;
      L_gross_pallet_weight  := C_rec.gross_pallet_weight;
      L_net_pallet_weight    := C_rec.net_pallet_weight;
      L_pallet_width         := C_rec.pallet_width;
      L_pallet_height        := C_rec.pallet_height;
      L_pallet_length        := C_rec.pallet_length;
      L_supp_diff_1          := C_rec.supp_diff_1;
      L_supp_diff_2          := C_rec.supp_diff_2;
      L_supp_diff_3          := C_rec.supp_diff_3;
      L_supp_diff_4          := C_rec.supp_diff_4;
      L_supp_pack_size       := C_rec.supp_pack_size;
      L_inner_pack_size      := C_rec.inner_pack_size;
      L_ti                   := C_rec.ti;
      L_hi                   := C_rec.hi;

      open C_ITEM_SUPP_EXIST;
      fetch C_ITEM_SUPP_EXIST into L_exists;
      close C_ITEM_SUPP_EXIST;

      if L_exists is not NULL then

         L_table := 'ITEM_SUPPLIER';
         open C_LOCK_ITEM_SUPPLIER;
         close C_LOCK_ITEM_SUPPLIER;

         update item_supplier
            set supp_diff_1 = NVL(L_supp_diff_1, supp_diff_1),
                supp_diff_2 = NVL(L_supp_diff_2, supp_diff_2),
                supp_diff_3 = NVL(L_supp_diff_3, supp_diff_3),
                supp_diff_4 = NVL(L_supp_diff_4, supp_diff_4),
                create_datetime = L_sysdate,
                last_update_datetime = L_sysdate,
                last_update_id = L_user
          where item = L_item
            and supplier = L_supplier;

      else
         insert into item_supplier(item,
                                   supplier,
                                   primary_supp_ind,
                                   vpn,
                                   supp_label,
                                   consignment_rate,
                                   supp_diff_1,
                                   supp_diff_2,
                                   supp_diff_3,
                                   supp_diff_4,
                                   pallet_name,
                                   case_name,
                                   inner_name,
                                   supp_discontinue_date,
                                   direct_ship_ind,
                                   last_update_datetime,
                                   last_update_id,
                                   create_datetime)
                            values(L_item,
                                   I_supplier,
                                   'N',
                                   NULL,
                                   NULL,
                                   NULL,
                                   L_supp_diff_1,
                                   L_supp_diff_2,
                                   L_supp_diff_3,
                                   L_supp_diff_4,
                                   L_default_pallet_name,
                                   L_default_case_name,
                                   L_default_inner_name,
                                   NULL,
                                   'N',
                                   L_sysdate,
                                   L_user,
                                   L_sysdate);
      end if;

      L_exists := NULL;
      open C_ITEM_SUPP_CTRY_EXIST;
      fetch C_ITEM_SUPP_CTRY_EXIST into L_exists;
      close C_ITEM_SUPP_CTRY_EXIST;

      if L_exists is not NULL then
         L_table := 'ITEM_SUPP_COUNTRY';
         open C_LOCK_ITEM_SUPP_COUNTRY;
         close C_LOCK_ITEM_SUPP_COUNTRY;

         update item_supp_country
            set lead_time            = NVL(L_lead_time, lead_time),
                min_order_qty        = NVL(L_min_order_qty, min_order_qty),
                max_order_qty        = NVL(L_max_order_qty, max_order_qty),
                create_datetime      = L_sysdate,
                last_update_datetime = L_sysdate,
                last_update_id       = L_user
          where item = L_item
            and supplier = L_supplier;

      else
         O_supp_ctry_exist := 'N';
         O_item := L_item;
      end if;

      if L_net_unit_weight is not NULL or L_unit_width is not NULL or
         L_unit_height is not NULL or L_unit_length is not NULL then

         L_exists := NULL;
         open C_ITEM_SUPP_CTRY_DIM_EA_EXIST;
         fetch C_ITEM_SUPP_CTRY_DIM_EA_EXIST into L_exists;
         close C_ITEM_SUPP_CTRY_DIM_EA_EXIST;

         if L_exists is not NULL then
            L_table := 'ITEM_SUPP_COUNTRY_DIM';
            open C_LOCK_ITEM_SUPP_COUNTRY_DIM;
            close C_LOCK_ITEM_SUPP_COUNTRY_DIM;

            update item_supp_country_dim
               set weight = NVL(L_gross_unit_weight, weight),
                   net_weight  = NVL(L_net_unit_weight, net_weight),
                   width = NVL(L_unit_width, width),
                   height = NVL(L_unit_height, height),
                   length = NVL(L_unit_length, length),
                   create_datetime = L_sysdate,
                   last_update_datetime = L_sysdate,
                   last_update_id = L_user
             where item = L_item
               and supplier = L_supplier
               and dim_object = 'EA';
         else
            O_supp_ctry_dim_exist := 'N';
            O_item := L_item;
         end if;
      end if;

      if L_net_case_weight is not NULL or L_case_width is not NULL or
         L_case_height is not NULL or L_case_length is not NULL then

         L_exists := NULL;
         open C_ITEM_SUPP_CTRY_DIM_CA_EXIST;
         fetch C_ITEM_SUPP_CTRY_DIM_CA_EXIST into L_exists;
         close C_ITEM_SUPP_CTRY_DIM_CA_EXIST;

         if L_exists is not NULL then
            L_table := 'ITEM_SUPP_COUNTRY_DIM';
            open C_LOCK_ITEM_SUPP_COUNTRY_DIM;
            close C_LOCK_ITEM_SUPP_COUNTRY_DIM;

            update item_supp_country_dim
               set weight = NVL(L_gross_case_weight, weight),
                   net_weight  = NVL(L_net_case_weight, net_weight),
                   width = NVL(L_case_width, width),
                   height = NVL(L_case_height, height),
                   length = NVL(L_case_length, length),
                   create_datetime = L_sysdate,
                   last_update_datetime = L_sysdate,
                   last_update_id = L_user
             where item = L_item
               and supplier = L_supplier
               and dim_object = 'CA';
         else
            O_supp_ctry_dim_exist := 'N';
            O_item := L_item;
         end if;
      end if;

      if L_net_pallet_weight is not NULL or L_pallet_width is not NULL or
         L_pallet_height is not NULL or L_pallet_length is not NULL then

         L_exists := NULL;
         open C_ITEM_SUPP_CTRY_DIM_PA_EXIST;
         fetch C_ITEM_SUPP_CTRY_DIM_PA_EXIST into L_exists;
         close C_ITEM_SUPP_CTRY_DIM_PA_EXIST;

         if L_exists is not NULL then
            L_table := 'ITEM_SUPP_COUNTRY_DIM';
            open C_LOCK_ITEM_SUPP_COUNTRY_DIM;
            close C_LOCK_ITEM_SUPP_COUNTRY_DIM;

            update item_supp_country_dim
               set weight = NVL(L_gross_pallet_weight, weight),
                   net_weight = NVL(L_net_pallet_weight, net_weight),
                   width = NVL(L_pallet_width, width),
                   height = NVL(L_pallet_height, height),
                   length = NVL(L_pallet_length, length),
                   create_datetime = L_sysdate,
                   last_update_datetime = L_sysdate,
                   last_update_id = L_user
             where item = L_item
               and supplier = L_supplier
               and dim_object = 'PA';
         else
            O_supp_ctry_dim_exist := 'N';
            O_item := L_item;
         end if;
      end if;
   END LOOP;

   FOR C_rec in C_GET_CASE_UPDATES LOOP
      L_case                 := C_rec.case_ref_item;
      L_supplier             := C_rec.supplier;
      L_origin_country_id    := C_rec.origin_country_id;
      L_lead_time            := C_rec.lead_time;
      L_min_order_qty        := C_rec.min_order_qty;
      L_max_order_qty        := C_rec.max_order_qty;
      L_gross_unit_weight    := C_rec.gross_unit_weight;
      L_net_unit_weight      := C_rec.net_unit_weight;
      L_unit_width           := C_rec.unit_width;
      L_unit_height          := C_rec.unit_height;
      L_unit_length          := C_rec.unit_length;
      L_gross_case_weight    := C_rec.gross_case_weight;
      L_net_case_weight      := C_rec.net_case_weight;
      L_case_width           := C_rec.case_width;
      L_case_height          := C_rec.case_height;
      L_case_length          := C_rec.case_length;
      L_gross_pallet_weight  := C_rec.gross_pallet_weight;
      L_net_pallet_weight    := C_rec.net_pallet_weight;
      L_pallet_width         := C_rec.pallet_width;
      L_pallet_height        := C_rec.pallet_height;
      L_pallet_length        := C_rec.pallet_length;
      L_supp_diff_1          := C_rec.supp_diff_1;
      L_supp_diff_2          := C_rec.supp_diff_2;
      L_supp_diff_3          := C_rec.supp_diff_3;
      L_supp_diff_4          := C_rec.supp_diff_4;
      L_supp_pack_size       := C_rec.supp_pack_size;
      L_inner_pack_size      := C_rec.inner_pack_size;
      L_ti                   := C_rec.ti;
      L_hi                   := C_rec.hi;

      -- This code will check to determine if the vendor has uploaded a ref item for the
      -- case or the transactionlevel item for the case.  If the ref item has been used,
      -- we will retrieve the transaction level item and update both tran andref case
      -- items.
      ---
      if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                       L_item_level,
                                       L_tran_level,
                                       L_case) = FALSE then
         return FALSE;
      end if;
      ---
      if L_item_level != L_tran_level then
         open C_CASE_TRAN_LEVEL;
         fetch C_CASE_TRAN_LEVEL into L_item;
         close C_CASE_TRAN_LEVEL;

         -- the item_supplier records for the case ref item need to be updated and/or
         -- created.
         ---
         L_exists := NULL;
         open C_ITEM_SUPP_REF_EXIST;
         fetch C_ITEM_SUPP_REF_EXIST into L_exists;
         close C_ITEM_SUPP_REF_EXIST;
         ---
         if L_exists is not NULL then
            L_table := 'ITEM_SUPPLIER';
            open C_LOCK_CASE_REF_ITEM_SUPPLIER;
            close C_LOCK_CASE_REF_ITEM_SUPPLIER;
            ---
            update item_supplier
               set supp_diff_1 = NVL(L_supp_diff_1, supp_diff_1),
                   supp_diff_2 = NVL(L_supp_diff_2, supp_diff_2),
                   supp_diff_3 = NVL(L_supp_diff_3, supp_diff_3),
                   supp_diff_4 = NVL(L_supp_diff_4, supp_diff_4),
                   create_datetime = L_sysdate,
                   last_update_datetime = L_sysdate,
                   last_update_id = L_user
            where item = L_case
              and supplier = L_supplier;
         else
            insert into item_supplier(item,
                                      supplier,
                                      primary_supp_ind,
                                      vpn,
                                      supp_label,
                                      consignment_rate,
                                      supp_diff_1,
                                      supp_diff_2,
                                      supp_diff_3,
                                      supp_diff_4,
                                      pallet_name,
                                      case_name,
                                      inner_name,
                                      supp_discontinue_date,
                                      direct_ship_ind,
                                      last_update_datetime,
                                      last_update_id,
                                      create_datetime)
                               values(L_case,
                                      I_supplier,
                                      'N',
                                      NULL,
                                      NULL,
                                      NULL,
                                      L_supp_diff_1,
                                      L_supp_diff_2,
                                      L_supp_diff_3,
                                      L_supp_diff_4,
                                      L_default_pallet_name,
                                      L_default_case_name,
                                      L_default_inner_name,
                                      NULL,
                                      'N',
                                      L_sysdate,
                                      L_user,
                                      L_sysdate);
         end if;
         ---
      else -- item_level is equal to tran_level
         L_item := L_case;
         L_case := NULL;
      end if;

      L_exists := NULL;
      open C_ITEM_SUPP_EXIST;
      fetch C_ITEM_SUPP_EXIST into L_exists;
      close C_ITEM_SUPP_EXIST;

      if L_exists is not NULL then

         L_table := 'ITEM_SUPPLIER';
         open C_LOCK_ITEM_SUPPLIER;
         close C_LOCK_ITEM_SUPPLIER;

         update item_supplier
            set supp_diff_1 = NVL(L_supp_diff_1, supp_diff_1),
                supp_diff_2 = NVL(L_supp_diff_2, supp_diff_2),
                supp_diff_3 = NVL(L_supp_diff_3, supp_diff_3),
                supp_diff_4 = NVL(L_supp_diff_4, supp_diff_4),
                create_datetime = L_sysdate,
                last_update_datetime = L_sysdate,
                last_update_id = L_user
          where item = L_item
            and supplier = L_supplier;

      else
         insert into item_supplier(item,
                                   supplier,
                                   primary_supp_ind,
                                   vpn,
                                   supp_label,
                                   consignment_rate,
                                   supp_diff_1,
                                   supp_diff_2,
                                   supp_diff_3,
                                   supp_diff_4,
                                   pallet_name,
                                   case_name,
                                   inner_name,
                                   supp_discontinue_date,
                                   direct_ship_ind,
                                   last_update_datetime,
                                   last_update_id,
                                   create_datetime)
                            values(L_item,
                                   I_supplier,
                                   'N',
                                   NULL,
                                   NULL,
                                   NULL,
                                   L_supp_diff_1,
                                   L_supp_diff_2,
                                   L_supp_diff_3,
                                   L_supp_diff_4,
                                   L_default_pallet_name,
                                   L_default_case_name,
                                   L_default_inner_name,
                                   NULL,
                                   'N',
                                   L_sysdate,
                                   L_user,
                                   L_sysdate);
      end if;

      L_exists := NULL;
      open C_ITEM_SUPP_CTRY_EXIST;
      fetch C_ITEM_SUPP_CTRY_EXIST into L_exists;
      close C_ITEM_SUPP_CTRY_EXIST;

      if L_exists is not NULL then
         L_table := 'ITEM_SUPP_COUNTRY';
         open C_LOCK_ITEM_SUPP_COUNTRY;
         close C_LOCK_ITEM_SUPP_COUNTRY;

         update item_supp_country
            set lead_time            = NVL(L_lead_time, lead_time),
                min_order_qty        = NVL(L_min_order_qty, min_order_qty),
                max_order_qty        = NVL(L_max_order_qty, max_order_qty),
                create_datetime      = L_sysdate,
                last_update_datetime = L_sysdate,
                last_update_id       = L_user
          where item                 = L_item
            and supplier             = L_supplier;

      else
         O_case_supp_ctry_exist := 'N';
         O_case := L_item;
      end if;

      if L_net_case_weight is not NULL or L_case_width is not NULL or
         L_case_height is not NULL or L_case_length is not NULL then

         L_exists := NULL;
         open C_ITEM_SUPP_CTRY_DIM_CA_EXIST;
         fetch C_ITEM_SUPP_CTRY_DIM_CA_EXIST into L_exists;
         close C_ITEM_SUPP_CTRY_DIM_CA_EXIST;

         if L_exists is not NULL then
            L_table := 'ITEM_SUPP_COUNTRY_DIM';
            open C_LOCK_ITEM_SUPP_COUNTRY_DIM;
            close C_LOCK_ITEM_SUPP_COUNTRY_DIM;

            update item_supp_country_dim
               set weight = NVL(L_gross_case_weight, weight),
                   net_weight = NVL(L_net_case_weight, net_weight),
                   width = NVL(L_case_width, width),
                   height = NVL(L_case_height, height),
                   length = NVL(L_case_length, length),
                   create_datetime = L_sysdate,
                   last_update_datetime = L_sysdate,
                   last_update_id = L_user
             where item = L_item
               and supplier = I_supplier
               and dim_object = 'CA';
         else
            O_case_supp_ctry_dim_exist := 'N';
            O_case := L_item;
         end if;
      end if;

      if L_net_pallet_weight is not NULL or L_pallet_width is not NULL or
         L_pallet_height is not NULL or L_pallet_length is not NULL then

         L_exists := NULL;
         open C_ITEM_SUPP_CTRY_DIM_PA_EXIST;
         fetch C_ITEM_SUPP_CTRY_DIM_PA_EXIST into L_exists;
         close C_ITEM_SUPP_CTRY_DIM_PA_EXIST;

         if L_exists is not NULL then
            L_table := 'ITEM_SUPP_COUNTRY_DIM';
            open C_LOCK_ITEM_SUPP_COUNTRY_DIM;
            close C_LOCK_ITEM_SUPP_COUNTRY_DIM;

            update item_supp_country_dim
               set weight = NVL(L_gross_pallet_weight, weight),
                   net_weight = NVL(L_net_pallet_weight, net_weight),
                   width = NVL(L_pallet_width, width),
                   height = NVL(L_pallet_height, height),
                   length = NVL(L_pallet_length, length),
                   create_datetime = L_sysdate,
                   last_update_datetime = L_sysdate,
                   last_update_id = L_user
             where item = L_item
               and supplier = I_supplier
               and dim_object = 'PA';
         else
            O_case_supp_ctry_dim_exist := 'N';
            O_case := L_item;
         end if;
      end if;

   END LOOP;

return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_program,
                                            I_supplier);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_UPDATE;
-----------------------------------------------------------------------------------------------------------------
FUNCTION CHECK_DUPL(O_error_message IN OUT VARCHAR2,
                    O_flag          IN OUT VARCHAR2,
                    I_item          IN     ITEM_MASTER.ITEM%TYPE,
                    I_diff_1        IN     ITEM_MASTER.DIFF_1%TYPE,
                    I_diff_2        IN     ITEM_MASTER.DIFF_2%TYPE,
                    I_diff_3        IN     ITEM_MASTER.DIFF_3%TYPE,
                    I_diff_4        IN     ITEM_MASTER.DIFF_4%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program       VARCHAR2(50)          := 'EDITEM_SQL.CHECK_DUPL';
   L_existing_item ITEM_MASTER.ITEM%TYPE := NULL;
   L_dummy         VARCHAR2(1)           := NULL;
   ---
   cursor C_GET_CHILDREN is
      select item
        from item_master
       where item_parent = I_item;
   ---
   cursor C_CHECK_DUPL is
      select 'x'
        from item_master
       where item   = L_existing_item
         and diff_1 = I_diff_1
         and diff_2 = I_diff_2
         and diff_3 = I_diff_3
         and diff_4 = I_diff_4
   union all
      select 'x'
        from item_master
       where item   = L_existing_item
         and diff_1 = I_diff_1
         and diff_2 = I_diff_2
         and diff_3 = I_diff_3
         and diff_4 IS NULL
   union all
      select 'x'
        from item_master
       where item   = L_existing_item
         and diff_1 = I_diff_1
         and diff_2 = I_diff_2
         and diff_3 IS NULL
         and diff_4 IS NULL
   union all
      select 'x'
        from item_master
       where item   = L_existing_item
         and diff_1 = I_diff_1
         and diff_2 IS NULL
         and diff_3 IS NULL
         and diff_4 IS NULL;

BEGIN
   FOR rec in C_GET_CHILDREN LOOP
      L_existing_item := rec.item;
      ---
      SQL_LIB.SET_MARK('OPEN','C_CHECK_DUPL','ITEM_MASTER','ITEM: '||L_existing_item);
      open C_CHECK_DUPL;
      ---
      SQL_LIB.SET_MARK('FETCH','C_CHECK_DUPL','ITEM_MASTER','ITEM: '||L_existing_item);
      fetch C_CHECK_DUPL into L_dummy;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_DUPL','ITEM_MASTER','ITEM: '||L_existing_item);
      close C_CHECK_DUPL;
      ---
      if L_dummy = 'x' then
         O_flag := 'Y';
         return TRUE;
      else
         O_flag := 'N';
      end if;
   END LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      RETURN FALSE;
END CHECK_DUPL;
-----------------------------------------------------------------------------------------------------------------
FUNCTION BUILD_SUPPLIER_RECORDS(O_error_message     IN OUT     VARCHAR2,
                                I_supplier          IN         ITEM_SUPPLIER.SUPPLIER%TYPE,
                                I_new_item          IN         ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program                    VARCHAR2(50) := 'EDITEM_SQL.BUILD_SUPPLIER_RECORDS';
   L_tran_level                 ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_item_level                 ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_user                       VARCHAR2(30) := USER;
   L_sysdate                    PERIOD.VDATE%TYPE := SYSDATE;
   L_edi_diff_1                 ITEM_MASTER.DIFF_1%TYPE;
   L_edi_diff_2                 ITEM_MASTER.DIFF_2%TYPE;
   L_edi_diff_3                 ITEM_MASTER.DIFF_3%TYPE;
   L_edi_diff_4                 ITEM_MASTER.DIFF_4%TYPE;
   L_dept                       ITEM_MASTER.DEPT%TYPE;
   L_class                      ITEM_MASTER.CLASS%TYPE;
   L_subclass                   ITEM_MASTER.SUBCLASS%TYPE;
   L_short_desc                 ITEM_MASTER.SHORT_DESC%TYPE;
   L_retail_zone_group_id       ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE;
   L_cost_zone_group_id         ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE;
   L_standard_uom               ITEM_MASTER.STANDARD_UOM%TYPE;
   L_uom_conv_factor            ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_store_ord_mult             ITEM_MASTER.STORE_ORD_MULT%TYPE;
   L_supplier                   ITEM_SUPPLIER.SUPPLIER%TYPE;
   L_vpn                        ITEM_SUPPLIER.VPN%TYPE;
   L_supp_diff_1                ITEM_SUPPLIER.SUPP_DIFF_1%TYPE;
   L_supp_diff_2                ITEM_SUPPLIER.SUPP_DIFF_2%TYPE;
   L_supp_diff_3                ITEM_SUPPLIER.SUPP_DIFF_3%TYPE;
   L_supp_diff_4                ITEM_SUPPLIER.SUPP_DIFF_4%TYPE;
   L_origin_country_id          ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
   L_lead_time                  ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE;
   L_unit_cost               ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_supp_pack_size             ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE;
   L_inner_pack_size            ITEM_SUPP_COUNTRY.INNER_PACK_SIZE%TYPE;
   L_min_order_qty              ITEM_SUPP_COUNTRY.MIN_ORDER_QTY%TYPE;
   L_max_order_qty              ITEM_SUPP_COUNTRY.MAX_ORDER_QTY%TYPE;
   L_packing_method             ITEM_SUPP_COUNTRY.PACKING_METHOD%TYPE;
   L_default_uop                ITEM_SUPP_COUNTRY.DEFAULT_UOP%TYPE;
   L_ti                         ITEM_SUPP_COUNTRY.TI%TYPE;
   L_hi                         ITEM_SUPP_COUNTRY.HI%TYPE;
   L_unit_length                ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
   L_unit_width                 ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
   L_unit_height                ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
   L_unit_lwh_uom               ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE;
   L_net_unit_weight            ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE;
   L_gross_unit_weight          ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
   L_unit_weight_uom            ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
   L_unit_liquid_vol            ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
   L_unit_liquid_uom            ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE;
   L_case_length                ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
   L_case_width                 ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
   L_case_height                ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
   L_case_lwh_uom               ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE;
   L_net_case_weight            ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE;
   L_gross_case_weight          ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
   L_case_weight_uom            ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
   L_case_liquid_vol            ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
   L_case_liquid_uom            ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE;
   L_pallet_length              ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
   L_pallet_width               ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
   L_pallet_height              ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
   L_pallet_lwh_uom             ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE;
   L_net_pallet_weight          ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE;
   L_gross_pallet_weight        ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
   L_pallet_weight_uom          ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
   L_unit_dim                   ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE;
   L_case_dim                   ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE;
   L_pallet_dim                 ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE;
   L_item_parent                ITEM_MASTER.ITEM%TYPE;
   L_default_standard_uom       SYSTEM_OPTIONS.DEFAULT_STANDARD_UOM%TYPE;
   L_default_dimension_uom      SYSTEM_OPTIONS.DEFAULT_DIMENSION_UOM%TYPE;
   L_default_weight_uom         SYSTEM_OPTIONS.DEFAULT_WEIGHT_UOM%TYPE;
   L_default_packing_method     SYSTEM_OPTIONS.DEFAULT_PACKING_METHOD%TYPE;
   L_default_pallet_name        SYSTEM_OPTIONS.DEFAULT_PALLET_NAME%TYPE;
   L_default_case_name          SYSTEM_OPTIONS.DEFAULT_CASE_NAME%TYPE;
   L_default_inner_name         SYSTEM_OPTIONS.DEFAULT_INNER_NAME%TYPE;
   L_round_lvl                  ITEM_SUPP_COUNTRY.ROUND_LVL%TYPE;
   L_round_to_inner_pct         ITEM_SUPP_COUNTRY.ROUND_TO_INNER_PCT%TYPE;
   L_round_to_case_pct          ITEM_SUPP_COUNTRY.ROUND_TO_CASE_PCT%TYPE;
   L_round_to_layer_pct         ITEM_SUPP_COUNTRY.ROUND_TO_LAYER_PCT%TYPE;
   L_round_to_pallet_pct        ITEM_SUPP_COUNTRY.ROUND_TO_PALLET_PCT%TYPE;

BEGIN

   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_supplier','NULL','NOT NULL');
      return FALSE;
   elsif I_new_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_new_item','NULL','NOT NULL');
      return FALSE;
   end if;

   if EDITEM_SQL.GET_INFO(O_error_message,
                          L_edi_diff_1,
                          L_edi_diff_2,
                          L_edi_diff_3,
                          L_edi_diff_4,
                          L_dept,
                          L_class,
                          L_subclass,
                          L_short_desc,
                          L_retail_zone_group_id,
                          L_cost_zone_group_id,
                          L_standard_uom,
                          L_uom_conv_factor,
                          L_store_ord_mult,
                          L_supplier,
                          L_vpn,
                          L_supp_diff_1,
                          L_supp_diff_2,
                          L_supp_diff_3,
                          L_supp_diff_4,
                          L_origin_country_id,
                          L_lead_time,
                          L_unit_cost,
                          L_supp_pack_size,
                          L_inner_pack_size,
                          L_min_order_qty,
                          L_max_order_qty,
                          L_packing_method,
                          L_default_uop,
                          L_ti,
                          L_hi,
                          L_unit_length,
                          L_unit_width,
                          L_unit_height,
                          L_unit_lwh_uom,
                          L_net_unit_weight,
                          L_gross_unit_weight,
                          L_unit_weight_uom,
                          L_unit_liquid_vol,
                          L_unit_liquid_uom,
                          L_case_length,
                          L_case_width,
                          L_case_height,
                          L_case_lwh_uom,
                          L_net_case_weight,
                          L_gross_case_weight,
                          L_case_weight_uom,
                          L_case_liquid_vol,
                          L_case_liquid_uom,
                          L_pallet_length,
                          L_pallet_width,
                          L_pallet_height,
                          L_pallet_lwh_uom,
                          L_net_pallet_weight,
                          L_gross_pallet_weight,
                          L_pallet_weight_uom,
                          L_item_parent,
                          I_new_item) = FALSE then
      return FALSE;
   end if;

   if SYSTEM_OPTIONS_SQL.GET_DEFAULT_UOM_AND_NAMES(O_error_message,
                                                   L_default_standard_uom,
                                                   L_default_dimension_uom,
                                                   L_default_weight_uom,
                                                   L_default_packing_method,
                                                   L_default_pallet_name,
                                                   L_default_case_name,
                                                   L_default_inner_name) = FALSE then
      return FALSE;
   else
       L_standard_uom := nvl(L_standard_uom, L_default_standard_uom);
       L_packing_method := nvl(L_packing_method, L_default_packing_method);
   end if;

   insert into item_supplier(item,
                             supplier,
                             primary_supp_ind,
                             vpn,
                             supp_label,
                             consignment_rate,
                             supp_diff_1,
                             supp_diff_2,
                             supp_diff_3,
                             supp_diff_4,
                             pallet_name,
                             case_name,
                             inner_name,
                             supp_discontinue_date,
                             direct_ship_ind,
                             last_update_datetime,
                             last_update_id,
                             create_datetime)
                      values(I_new_item,
                             L_supplier,
                             'Y',
                             L_vpn,
                             NULL,
                             NULL,
                             L_supp_diff_1,
                             L_supp_diff_2,
                             L_supp_diff_3,
                             L_supp_diff_4,
                             L_default_pallet_name,
                             L_default_case_name,
                             L_default_inner_name,
                             NULL,
                             'N',
                             L_sysdate,
                             L_user,
                             L_sysdate);
   /* Fetch Item's
      Rounding Info. */
   if ITEM_SUPP_COUNTRY_SQL.GET_DFLT_RND_LVL_ITEM(O_error_message,
                                                  L_round_lvl,
                                                  L_round_to_inner_pct,
                                                  L_round_to_case_pct,
                                                  L_round_to_layer_pct,
                                                  L_round_to_pallet_pct,
                                                  I_new_item,
                                                  I_supplier,
                                                  L_dept,
                                                  L_origin_country_id,
                                                  NULL) = FALSE then
      return FALSE;
   end if;
   --
   -- 1 is added onto the lead time passed to the function because
   -- lead time is defined by the supplier as the time that it takes to fill and
   -- ship an order once the order has been received.  Retek determines
   -- lead time (here) to be the time it takes to fill an order after
   -- it has been sent from the Retek system (that is, including the time
   -- it takes the order to get from here to there).
   --
   insert into item_supp_country(item,
                                 supplier,
                                 origin_country_id,
                                 unit_cost,
                                 lead_time,
                                 supp_pack_size,
                                 inner_pack_size,
                                 round_lvl,
                                 round_to_inner_pct,
                                 round_to_case_pct,
                                 round_to_layer_pct,
                                 round_to_pallet_pct,
                                 min_order_qty,
                                 max_order_qty,
                                 packing_method,
                                 primary_supp_ind,
                                 primary_country_ind,
                                 default_uop,
                                 ti,
                                 hi,
                                 supp_hier_type_1,
                                 supp_hier_lvl_1,
                                 supp_hier_type_2,
                                 supp_hier_lvl_2,
                                 supp_hier_type_3,
                                 supp_hier_lvl_3,
                                 last_update_datetime,
                                 last_update_id,
                                 create_datetime,
                                 cost_uom
                                 )
                          values(I_new_item,
                                 L_supplier,
                                 L_origin_country_id,
                                 L_unit_cost,
                                 L_lead_time + 1,
                                 nvl(L_supp_pack_size, 1),
                                 nvl(L_inner_pack_size, 1),
                                 L_round_lvl,
                                 L_round_to_inner_pct,
                                 L_round_to_case_pct,
                                 L_round_to_layer_pct,
                                 L_round_to_pallet_pct,
                                 L_min_order_qty,
                                 L_max_order_qty,
                                 L_packing_method,
                                 'Y',
                                 'Y',
                                 L_default_uop,
                                 nvl(L_ti, 1),
                                 nvl(L_hi, 1),
                                 Null,
                                 Null,
                                 Null,
                                 Null,
                                 Null,
                                 Null,
                                 L_sysdate,
                                 L_user,
                                 L_sysdate,
                                 L_standard_uom
                                 );

   if L_unit_length is not null or L_unit_width is not null or L_unit_height is not null or
      L_gross_unit_weight is not null or L_net_unit_weight is not null or L_unit_liquid_vol is not null then
      insert into item_supp_country_dim(item,
                                        supplier,
                                         origin_country,
                                        dim_object,
                                        presentation_method,
                                        length,
                                        width,
                                        height,
                                        lwh_uom,
                                        weight,
                                        net_weight,
                                        weight_uom,
                                        liquid_volume,
                                        liquid_volume_uom,
                                        stat_cube,
                                        tare_weight,
                                        tare_type,
                                        last_update_datetime,
                                        last_update_id,
                                        create_datetime)
                                 values(I_new_item,
                                        L_supplier,
                                        L_origin_country_id,
                                        'EA',
                                        Null,
                                        L_unit_length,
                                        L_unit_width,
                                        L_unit_height,
                                        L_unit_lwh_uom,
                                        L_gross_unit_weight,
                                        L_net_unit_weight,
                                        L_unit_weight_uom,
                                        L_unit_liquid_vol,
                                        L_unit_liquid_uom,
                                        Null,
                                        Null,
                                        Null,
                                        L_sysdate,
                                        L_user,
                                        L_sysdate);
   end if;

   if L_case_length is not null or L_case_width is not null or L_case_height is not null or
      L_gross_case_weight is not null or L_net_case_weight is not null or L_case_liquid_vol is not null then

      insert into item_supp_country_dim(item,
                                        supplier,
                                        origin_country,
                                        dim_object,
                                        presentation_method,
                                        length,
                                        width,
                                        height,
                                        lwh_uom,
                                        weight,
                                        net_weight,
                                        weight_uom,
                                        liquid_volume,
                                        liquid_volume_uom,
                                        stat_cube,
                                        tare_weight,
                                        tare_type,
                                        last_update_datetime,
                                        last_update_id,
                                        create_datetime)
                                 values(I_new_item,
                                        L_supplier,
                                        L_origin_country_id,
                                        'CA',
                                        Null,
                                        L_case_length,
                                        L_case_width,
                                        L_case_height,
                                        L_case_lwh_uom,
                                        L_gross_case_weight,
                                        L_net_case_weight,
                                        L_case_weight_uom,
                                        L_case_liquid_vol,
                                        L_case_liquid_uom,
                                        Null,
                                        Null,
                                        Null,
                                        L_sysdate,
                                        L_user,
                                        L_sysdate);
   end if;

   if L_pallet_length is not null or L_pallet_width is not null or L_pallet_height is not null or
      L_gross_pallet_weight is not null or L_net_pallet_weight is not null then

      insert into item_supp_country_dim(item,
                                        supplier,
                                        origin_country,
                                        dim_object,
                                        presentation_method,
                                        length,
                                        width,
                                        height,
                                        lwh_uom,
                                        weight,
                                        net_weight,
                                        weight_uom,
                                        liquid_volume,
                                        liquid_volume_uom,
                                        stat_cube,
                                        tare_weight,
                                        tare_type,
                                        last_update_datetime,
                                        last_update_id,
                                        create_datetime)
                                 values(I_new_item,
                                        L_supplier,
                                        L_origin_country_id,
                                        'PA',
                                        Null,
                                        L_pallet_length,
                                        L_pallet_width,
                                        L_pallet_height,
                                        L_pallet_lwh_uom,
                                        L_gross_pallet_weight,
                                        L_net_pallet_weight,
                                        L_pallet_weight_uom,
                                        Null,
                                        Null,
                                        Null,
                                        Null,
                                        Null,
                                        L_sysdate,
                                        L_user,
                                        L_sysdate);
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      RETURN FALSE;
END BUILD_SUPPLIER_RECORDS;
-----------------------------------------------------------------------------------------------------------------
FUNCTION SUPPLIER_EXISTS(O_error_message     IN OUT     VARCHAR2,
                         O_supplier_ind      IN OUT     VARCHAR2,
                         I_supplier          IN         ITEM_SUPPLIER.SUPPLIER%TYPE,
                         I_existing_item     IN         ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program                    VARCHAR2(50) := 'EDITEM_SQL.SUPPLIER_EXISTS';
   L_check_supplier             VARCHAR2(1);
   L_supplier_ind               VARCHAR2(1);
   ---
   cursor C_CHECK_SUPPLIER is
      select 'x'
        from item_supplier
       where item = I_existing_item
         and supplier = I_supplier;
BEGIN
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_supplier','NULL','NOT NULL');
      return FALSE;
   elsif I_existing_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_existing_item','NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_SUPPLIER','ITEM_SUPPLIER',NULL);
   open C_CHECK_SUPPLIER;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_SUPPLIER','ITEM_SUPPLIER',NULL);
   fetch C_CHECK_SUPPLIER into L_check_supplier;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_SUPPLIER','ITEM_SUPPLIER',NULL);
   close C_CHECK_SUPPLIER;
   ---
   if L_check_supplier is not null then
      O_supplier_ind := 'Y';
   else
      O_supplier_ind := 'N';
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      RETURN FALSE;
END SUPPLIER_EXISTS;
-----------------------------------------------------------------------------------------------------------------
-- Function Name : EDI_COST_DELETE
-- Purpose       : This function will delete from the edi_cost_chg and edi_cost_loc
--                 tables for a specific seq_no.
-----------------------------------------------------------------------------------------------------------------
FUNCTION EDI_COST_DELETE(O_error_message IN OUT VARCHAR2,
                         I_seq_no        IN     EDI_COST_CHG.SEQ_NO%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program       VARCHAR2(64) := 'EDITEM_SQL.EDI_COST_DELETE';
   ---
   cursor C_LOCK_EDI_COST_CHG is
      select 'x'
        from edi_cost_chg
       where seq_no   = I_seq_no
         for update nowait;
   ---
   cursor C_LOCK_EDI_COST_LOC is
      select 'x'
        from edi_cost_loc
       where seq_no   = I_seq_no
         for update nowait;
   ---
BEGIN
   if I_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_seq_no','NOT NULL','NULL');
      return FALSE;
   end if;
   ---
   -- Lock the edi_cost_loc record(s) to delete
   ---
   open C_LOCK_EDI_COST_LOC;
   close C_LOCK_EDI_COST_LOC;
   ---
   delete from edi_cost_loc
    where seq_no   = I_seq_no;
   ---
   -- Lock the edi_cost_chg record(s) to delete
   ---
   open C_LOCK_EDI_COST_CHG;
   close C_LOCK_EDI_COST_CHG;
   ---
   delete from edi_cost_chg
    where seq_no   = I_seq_no;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      RETURN FALSE;
END EDI_COST_DELETE;
-----------------------------------------------------------------------------------------------------------------
-- Function Name : ITEM_EXISTS
-- Purpose       : This function checks to see if the specified item exists on
--                 on the item_master table.
-----------------------------------------------------------------------------------------------------------------
FUNCTION ITEM_EXISTS (O_error_message IN OUT VARCHAR2,
                      O_exists        IN OUT BOOLEAN,
                      I_item          IN     ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   ---
   L_program       VARCHAR2(64) := 'EDITEM_SQL.ITEM_EXISTS';
   L_exists        VARCHAR2(1)  := NULL;
   ---
   cursor C_ITEM_EXISTS is
      select 'Y'
      from item_master
      where item = I_item;
BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ITEM_EXISTS','ITEM_MASTER',NULL);
   open  C_ITEM_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_EXISTS','ITEM_MASTER',NULL);
   fetch C_ITEM_EXISTS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_EXISTS','ITEM_MASTER',NULL);
   close C_ITEM_EXISTS;
   ---
   if L_exists is NOT NULL then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      RETURN FALSE;
END ITEM_EXISTS;
-----------------------------------------------------------------------------------------------------------------
FUNCTION CREATE_REF_CASE (O_error_message         IN OUT          RTK_ERRORS.RTK_TEXT%TYPE,
                          I_pack_no               IN              ITEM_MASTER.ITEM%TYPE,
                          I_pack_ref_no           IN              ITEM_MASTER.ITEM%TYPE)
   return Boolean is

   L_program       VARCHAR2(64) := 'EDITEM_SQL.CREATE_REF_CASE';

BEGIN

   if I_pack_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_pack_no','NULL','NOT NULL');
      return FALSE;
   end if;

   if I_pack_ref_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_pack_ref_no','NULL','NOT NULL');
      return FALSE;
   end if;

   -- Insert a record for the case ref item into the ITEM_MASTER table based on the transaction level
   -- item that was already created for the case.
   ---
   insert into item_master (item,
                            item_number_type,
                            item_parent,
                            item_grandparent,
                            pack_ind,
                            item_level,
                            tran_level,
                            item_aggregate_ind,
                            diff_1,
                            diff_1_aggregate_ind,
                            diff_2,
                            diff_2_aggregate_ind,
                            diff_3,
                            diff_3_aggregate_ind,
                            diff_4,
                            diff_4_aggregate_ind,
                            dept,
                            class,
                            subclass,
                            status,
                            item_desc,
                            short_desc,
                            desc_up,
                            primary_ref_item_ind,
                            retail_zone_group_id,
                            cost_zone_group_id,
                            standard_uom,
                            uom_conv_factor,
                            package_size,
                            package_uom,
                            merchandise_ind,
                            store_ord_mult,
                            forecast_ind,
                            original_retail,
                            mfg_rec_retail,
                            retail_label_type,
                            retail_label_value,
                            handling_temp,
                            handling_sensitivity,
                            catch_weight_ind,
                            first_received,
                            last_received,
                            qty_received,
                            waste_type,
                            waste_pct,
                            default_waste_pct,
                            const_dimen_ind,
                            simple_pack_ind,
                            contains_inner_ind,
                            sellable_ind,
                            orderable_ind,
                            pack_type,
                            order_as_type,
                            comments,
                            gift_wrap_ind,
                            ship_alone_ind,
                            create_datetime,
                            last_update_datetime,
                            last_update_id,
                            item_xform_ind,
                            inventory_ind)
                     select I_pack_ref_no,
                            item_number_type,
                            I_pack_no,
                            item_grandparent,
                            pack_ind,
                            2,
                            tran_level,
                            'N',
                            diff_1,
                            'N',
                            diff_2,
                            'N',
                            diff_3,
                            'N',
                            diff_4,
                            'N',
                            dept,
                            class,
                            subclass,
                            status,
                            item_desc,
                            short_desc,
                            desc_up,
                            'Y',
                            retail_zone_group_id,
                            cost_zone_group_id,
                            standard_uom,
                            uom_conv_factor,
                            package_size,
                            package_uom,
                            merchandise_ind,
                            store_ord_mult,
                            forecast_ind,
                            original_retail,
                            mfg_rec_retail,
                            retail_label_type,
                            retail_label_value,
                            handling_temp,
                            handling_sensitivity,
                            catch_weight_ind,
                            first_received,
                            last_received,
                            qty_received,
                            waste_type,
                            waste_pct,
                            default_waste_pct,
                            const_dimen_ind,
                            simple_pack_ind,
                            contains_inner_ind,
                            sellable_ind,
                            orderable_ind,
                            pack_type,
                            order_as_type,
                            comments,
                            gift_wrap_ind,
                            ship_alone_ind,
                            create_datetime,
                            last_update_datetime,
                            last_update_id,
                            item_xform_ind,
                            inventory_ind
                      from item_master
                      where item = I_pack_no;

      insert into item_supplier (item,
                                 supplier,
                                 primary_supp_ind,
                                 vpn,
                                 supp_label,
                                 consignment_rate,
                                 supp_diff_1,
                                 supp_diff_2,
                                 supp_diff_3,
                                 supp_diff_4,
                                 pallet_name,
                                 case_name,
                                 inner_name,
                                 supp_discontinue_date,
                                 direct_ship_ind,
                                 create_datetime,
                                 last_update_datetime,
                                 last_update_id)
                          select I_pack_ref_no,
                                 supplier,
                                 primary_supp_ind,
                                 NULL,
                                 supp_label,
                                 consignment_rate,
                                 supp_diff_1,
                                 supp_diff_2,
                                 supp_diff_3,
                                 supp_diff_4,
                                 pallet_name,
                                 case_name,
                                 inner_name,
                                 supp_discontinue_date,
                                 direct_ship_ind,
                                 create_datetime,
                                 last_update_datetime,
                                 last_update_id
                            from item_supplier
                           where item     = I_pack_no;


return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END CREATE_REF_CASE;
-----------------------------------------------------------------------------------------------------------------
FUNCTION SUPP_CNTRY_EXISTS(O_error_message OUT VARCHAR2,
                           O_exists        IN OUT VARCHAR2,
                           I_country       IN  item_supp_country.origin_country_id%TYPE,
                           I_supplier      IN  item_supp_country.supplier%TYPE,
                           I_item          IN  item_master.item%TYPE)
  return BOOLEAN is

   L_program VARCHAR2(64):= 'EDITEM_SQL.SUPP_CNTRY_EXISTS';
   L_exists            VARCHAR2(1);

cursor C_GET_SUPP_CNTRY is
   select 'x'
     from item_supp_country
    where item = I_item
      and supplier = I_supplier
      and origin_country_id = I_country;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_country is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_country',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_CNTRY','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_country);
   open C_GET_SUPP_CNTRY;
   SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_CNTRY','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_country);
   fetch C_GET_SUPP_CNTRY into L_exists;
      if C_GET_SUPP_CNTRY%FOUND then
         O_exists := 'Y';
      else
         O_exists := 'N';
      end if;
   SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_CNTRY','ITEM_SUPP_COUNTRY','Item: '||I_item||
                    ' Supplier: '||to_char(I_supplier)||' Origin_Country_Id: '|| I_country);
   close C_GET_SUPP_CNTRY;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END SUPP_CNTRY_EXISTS;
-----------------------------------------------------------------------------------------------------------------
FUNCTION GET_REF_ITEM_TYPE (O_error_message            IN OUT          VARCHAR2,
                            O_item_number_type         IN OUT          EDI_NEW_ITEM.REF_ITEM_TYPE%TYPE,
                            I_item                     IN              EDI_NEW_ITEM.REF_ITEM%TYPE)

return BOOLEAN is
   ---
   L_program       VARCHAR2(64) := 'EDITEM_SQL.GET_REF_ITEM_TYPE';
   ---
   cursor C_ITEM_TYPE is
      select ref_item_type
        from edi_new_item
       where ref_item = I_item;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NOT NULL',
                                            'NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_TYPE',
                    'EDI_NEW_ITEM',
                    'Ref_Item: '||I_item);
   open C_ITEM_TYPE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_TYPE',
                    'EDI_NEW_ITEM',
                    'Ref_Item: '||I_item);
   fetch C_ITEM_TYPE into O_item_number_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_TYPE',
                    'EDI_NEW_ITEM',
                    'Ref_Item: '||I_item);
   close C_ITEM_TYPE;

   if O_item_number_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_ITEM',
                                            to_char(I_item),
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_REF_ITEM_TYPE;

-----------------------------------------------------------------------------------------------------------------
FUNCTION MASS_UPDATE_COST(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          I_status          IN       EDI_COST_CHG.STATUS%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'EDITEM_SQL.MASS_UPDATE_COST';
   L_table         VARCHAR2(30) := NULL;
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_EDI_COST_CHG is
      select 'x'
        from edi_cost_chg
       where status = 'N'
         and exists (select 'x'
                       from edi_new_item
                      where edi_cost_chg.seq_no       = edi_new_item.seq_no
                        and edi_new_item.selected_ind = 'Y'
                        and edi_new_item.status       = 'N')
         for update nowait;

   cursor C_LOCK_EDI_NEW_ITEM is
      select 'x'
        from edi_new_item
       where selected_ind = 'Y'
         and status       = 'N'
         for update nowait;

BEGIN

   if I_status is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_status',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   -- ----------------------------------------------------
   -- ensure we can get locks on all records to be updated
   -- ----------------------------------------------------
   L_table := 'EDI_COST_CHG';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_EDI_COST_CHG',
                     L_table,
                     NULL);
   open C_LOCK_EDI_COST_CHG;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_EDI_COST_CHG',
                     L_table,
                     NULL);
   close C_LOCK_EDI_COST_CHG;


   L_table := 'EDI_NEW_ITEM';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_EDI_NEW_ITEM',
                     L_table,
                     NULL);
   open C_LOCK_EDI_NEW_ITEM;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_EDI_NEW_ITEM',
                     L_table,
                     NULL);
   close C_LOCK_EDI_NEW_ITEM;

   -- ----------------------------------------------------
   -- now update all the relevent records
   -- ----------------------------------------------------
   SQL_LIB.SET_MARK('UPDATE',
                    '',
                    'EDI_COST_CHG',
                    NULL);
   update edi_cost_chg
      set status       = I_status,
          acc_rej_date = GET_VDATE
    where status       = 'N'
      and exists (select 'x'
                    from edi_new_item
                   where edi_cost_chg.seq_no       = edi_new_item.seq_no
                     and edi_new_item.selected_ind = 'Y'
                     and edi_new_item.status       = 'N');

   SQL_LIB.SET_MARK('UPDATE',
                    '',
                    'EDI_NEW_ITEM',
                    NULL);
   update edi_new_item
      set status       = I_status,
          acc_rej_date = GET_VDATE
    where selected_ind = 'Y'
      and status       = 'N';

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             'I_status = ' || I_status,
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END MASS_UPDATE_COST;

-----------------------------------------------------------------------------------------------------------------

FUNCTION CLEAR_SELECTED (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE
                        )
   return BOOLEAN is

   L_program        VARCHAR2(64)  := 'EDITEM_SQL.CLEAR_SELECTED';

   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);
BEGIN
   update edi_new_item
      set selected_ind = 'N'
    where selected_ind = 'Y';
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             'EDI_NEW_ITEM',
                                             NULL,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CLEAR_SELECTED ;
-----------------------------------------------------------------------------
FUNCTION LOG_FAIL_REASON(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         I_seq_no           IN       EDI_NEW_ITEM.SEQ_NO%TYPE,
                         I_item             IN       EDI_NEW_ITEM.ITEM%TYPE ,
                         I_vpn              IN       EDI_NEW_ITEM.VPN%TYPE ,
                         I_rtk_key          IN       RTK_ERRORS.RTK_KEY%TYPE,
                         I_message_type_ind IN       EDI_FAIL_MESSAGES_TEMP.MESSAGE_TYPE_IND%TYPE DEFAULT 'F',
                         I_var1             IN       VARCHAR2 DEFAULT NULL,
                         I_var2             IN       VARCHAR2 DEFAULT NULL,
                         I_var3             IN       VARCHAR2 DEFAULT NULL
                        )
   return BOOLEAN is

   L_program        VARCHAR2(64)  := 'EDITEM_SQL.LOG_FAIL_REASON';
   L_message        RTK_ERRORS.RTK_TEXT%TYPE ;
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);
   L_key            VARCHAR2(30);
   cursor C_LOCK_RECORD is
      select 'x'
        from edi_new_item
       where seq_no = I_seq_no
         for update nowait;
BEGIN
   L_message := SQL_LIB.GET_MESSAGE_TEXT(I_rtk_key,
                                         I_var1,
                                         I_var2,
                                         I_var3);
   insert into edi_fail_messages_temp
        ( seq_no,
          item,
          vpn,
          message_type_ind,
          error_message)
      values
        ( I_seq_no,
          I_item,
          I_vpn,
          I_message_type_ind,
          L_message );
   if I_message_type_ind = 'F' then
      update edi_new_item
         set status = 'F'
       where seq_no = I_seq_no;
   end if;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             'EDI_NEW_ITEM',
                                             'SEQ_NO = ' || I_seq_no,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END LOG_FAIL_REASON ;
-----------------------------------------------------------------------------------------------------
FUNCTION CLEAR_ERRORS(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE
                      )
   return BOOLEAN is

   L_program        VARCHAR2(64)  := 'EDITEM_SQL.CLEAR_ERRORS';

BEGIN

   delete from edi_fail_messages_temp;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CLEAR_ERRORS ;
-----------------------------------------------------------------------------------------------------------------
FUNCTION MASS_INSERT_ITEM(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          O_non_fatal_ind   IN OUT   BOOLEAN,
                          O_warning_ind     IN OUT   BOOLEAN,
                          I_supp_currency   IN       SUPS.CURRENCY_CODE%TYPE,
                          I_elc_ind         IN       SYSTEM_OPTIONS.ELC_IND%TYPE,
                          I_vat_ind         IN       SYSTEM_OPTIONS.VAT_IND%TYPE
                          )
   return BOOLEAN is

   L_program                 VARCHAR2(64)                             := 'EDITEM_SQL.MASS_INSERT_ITEM';
   L_begin_item_digit        VAR_UPC_EAN.BEGIN_ITEM_DIGIT%TYPE;
   L_begin_var_digit         VAR_UPC_EAN.BEGIN_VAR_DIGIT%TYPE;
   L_check_digit             VAR_UPC_EAN.CHECK_DIGIT%TYPE;
   L_create_children_ind     EDI_LIKE_ITEM.CHILDREN_IND%TYPE;
   L_default_prefix          VAR_UPC_EAN.DEFAULT_PREFIX%TYPE;
   L_desc                    V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_1                  ITEM_MASTER.DIFF_1%TYPE;
   L_diff_2                  ITEM_MASTER.DIFF_2%TYPE;
   L_diff_3                  ITEM_MASTER.DIFF_3%TYPE;
   L_diff_4                  ITEM_MASTER.DIFF_4%TYPE;
   L_diff_1_group_ind        VARCHAR2(5);
   L_diff_2_group_ind        VARCHAR2(5);
   L_diff_3_group_ind        VARCHAR2(5);
   L_diff_4_group_ind        VARCHAR2(5);
   L_diff_type               V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
--   L_edi_row                 EDI_NEW_ITEM%ROWTYPE;
   L_existing                ITEM_MASTER.ITEM%TYPE                    := NULL;
   L_existing_item           ITEM_MASTER.ITEM%TYPE;
   L_exists                  BOOLEAN;
   L_exists_item             ITEM_MASTER.ITEM%TYPE;
   L_exists2                 VARCHAR2(1);
   L_external_finisher       VARCHAR2(1)                              := 'N';
   L_flag                    VARCHAR2(1);
   L_format_desc             VAR_UPC_EAN.FORMAT_DESC%TYPE;
   L_grandparent             ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_grandparent_desc        ITEM_MASTER.ITEM_DESC%TYPE;
   L_hts_ind                 EDI_LIKE_ITEM.HTS_IND%TYPE;
   L_internal_finisher       VARCHAR2(1)                              := 'N';
   L_inventory_ind           VARCHAR2(1)                              := NULL;
   L_item_xform_ind          VARCHAR2(1);
   L_next_item               ITEM_MASTER.ITEM%TYPE;
   L_no_retail               VARCHAR2(1);
   L_null_input              VARCHAR2(64)                             := NULL;
   L_parent                  ITEM_MASTER.ITEM_PARENT%TYPE;
   L_parent_desc             ITEM_MASTER.ITEM_DESC%TYPE;
   L_parent_item_rec         ITEM_MASTER%ROWTYPE;
   L_prefix_length           VAR_UPC_EAN.PREFIX_LENGTH%TYPE;
   L_price_ind               EDI_LIKE_ITEM.PRICE_IND%TYPE;
   L_replenishment_ind       VARCHAR2(1);
   L_req_doc_ind             EDI_LIKE_ITEM.REQ_DOC_IND%TYPE;
   L_retail_zone_group_ind   SIMPLE_PACK_TEMP.SELLABLE_IND%TYPE;
   L_seasons_ind             EDI_LIKE_ITEM.SEASONS_IND%TYPE;
   L_seq_no                  EDI_NEW_ITEM.SEQ_NO%TYPE;
   L_store_ind               EDI_LIKE_ITEM.STORE_IND%TYPE;
   L_supplier_ind            EDI_LIKE_ITEM.SUPPLIER_IND%TYPE;
   L_tax_code_ind            EDI_LIKE_ITEM.TAX_CODE_IND%TYPE;
   L_ticket_ind              EDI_LIKE_ITEM.TICKET_IND%TYPE;
   L_tran_level_item         ITEM_MASTER.ITEM%TYPE;
   L_uda_ind                 EDI_LIKE_ITEM.UDA_IND%TYPE;
   L_valid                   BOOLEAN;
   L_vdate                   PERIOD.VDATE%TYPE                        := DATES_SQL.GET_VDATE;
   L_warehouse_ind           EDI_LIKE_ITEM.WH_IND%TYPE;

   L_item_non_fatal_ind      BOOLEAN ;
   L_item_warning_ind        BOOLEAN ;
   L_item                    EDI_NEW_ITEM.ITEM%TYPE;
   L_vpn                     EDI_NEW_ITEM.VPN%TYPE;
   L_error_message           RTK_ERRORS.RTK_TEXT%TYPE;
   L_grandparent_item        ITEM_MASTER.ITEM%TYPE  := NULL;
   L_aip_ind                 SYSTEM_OPTIONS.AIP_IND%TYPE;
   -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,Begin
   L_uk_location_access      VARCHAR2(1)   := NULL;
   L_roi_location_access     VARCHAR2(1)   := NULL;
   L_owner_country           ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE := NULL;
   L_location_security_ind   SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE := NULL;
   L_system_options          SYSTEM_OPTIONS%ROWTYPE;
   -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,End

   CREATION_ERROR   EXCEPTION;
   CREATION_PACK_ERROR   EXCEPTION;

   cursor C_LOCK_RECORD is
      select 'x'
        from edi_new_item
       where seq_no = L_seq_no
         for update nowait;

   cursor C_LOCK_EDI_COST_CHG is
      select 'x'
        from edi_cost_chg
       where seq_no = L_seq_no
         for update nowait;

   cursor C_GET_EDI_ROW is
      select *
        from edi_new_item e
       where e.selected_ind = 'Y'
         and e.status != 'A';

   cursor C_ITEM_GRANDPARENT(l_item ITEM_MASTER.ITEM%TYPE) is
      select ITEM_PARENT
        from item_master
       where item =l_item
         and Item_level  = 2;

/*
   cursor C_GET_ROW is
      select *
        from edi_new_item
       where seq_no = L_seq_no;
*/
BEGIN

   -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(L_error_message,
                                            L_system_options) = FALSE then
      raise CREATION_ERROR;
   end if;
   L_location_security_ind  := L_system_options.tsl_loc_sec_ind;
   --
   -- Code to check the location country of the user
   if L_location_security_ind = 'Y' then
      if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY(L_error_message,
  	                                            L_uk_location_access,
  	                                            L_roi_location_access) = FALSE then
         raise CREATION_ERROR;
      end if;
      if L_uk_location_access = 'Y' and L_roi_location_access = 'N' then
         L_owner_country  := 'U';
      elsif L_uk_location_access = 'N' and L_roi_location_access = 'Y' then
         L_owner_country  := 'R';
      elsif L_uk_location_access = 'Y' and L_roi_location_access = 'Y' then
         L_owner_country  := 'U';
      end if;
    end if;
   -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,end

   O_non_fatal_ind := FALSE;
   O_warning_ind   := FALSE;
   FOR L_edi_row in C_GET_EDI_ROW LOOP

      L_item_non_fatal_ind  := FALSE ;
      L_item_warning_ind    := FALSE ;
      L_item                := L_edi_row.item;
      L_vpn                 := L_edi_row.vpn ;

      L_seq_no := L_edi_row.seq_no;

      delete from edi_fail_messages_temp
         where seq_no = L_seq_no;

/*
      SQL_LIB.SET_MARK('OPEN',
                       'C_get_row',
                       'edi_new_item',
                       NULL);
      open C_GET_ROW;

      SQL_LIB.SET_MARK('FETCH',
                       'C_get_row',
                       'edi_new_item',
                       NULL);
      fetch C_GET_ROW into L_edi_row;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_get_row',
                       'edi_new_item',
                       NULL);
      close C_GET_ROW;
*/
---
      if L_edi_row.new_item_ind = 'Y' then
         --- Validate 'NEW' new item information.  If item is an 'EXISTING'
         --- new item this information will not have changes so no validation needs
         --- to be performed.
         if L_edi_row.dept is NULL then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'ENTER_DEPT') = FALSE then
               return FALSE;
            end if;
            L_item_non_fatal_ind := TRUE;
         end if;
         if L_edi_row.class is NULL then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'ENTER_CLASS') = FALSE then
               return FALSE;
            end if;
            L_item_non_fatal_ind := TRUE;
         end if;
         if L_edi_row.subclass is NULL then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'ENTER_SUBCLASS') = FALSE then
               return FALSE;
            end if;
            L_item_non_fatal_ind := TRUE;
         end if;
         if L_edi_row.item_level is NULL then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'ITEM_LEVEL_REQ') = FALSE then
               return FALSE;
            end if;
            L_item_non_fatal_ind := TRUE;
         end if;
         if L_edi_row.tran_level is NULL then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'TRAN_LEVEL_REQ') = FALSE then
               return FALSE;
            end if;
            L_item_non_fatal_ind := TRUE;
         end if;
         if L_edi_row.retail_zone_group_id is NULL then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'RETAIL_ZONE_GRP_REQ') = FALSE then
               return FALSE;
            end if;
            L_item_non_fatal_ind := TRUE;
         end if;
         if L_edi_row.unit_cost is NULL then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'INVC_UNIT_COST') = FALSE then
               return FALSE;
            end if;
            L_item_non_fatal_ind := TRUE;
         end if;
         if L_edi_row.default_uop is NULL then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'DEFAULT_UOP_REQ') = FALSE then
               return FALSE;
            end if;
            L_item_non_fatal_ind := TRUE;
         end if;
         if L_edi_row.cost_zone_group_id is NULL
           and I_elc_ind = 'Y' then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'COST_ZONE_GRP_REQ') = FALSE then
               return FALSE;
            end if;
            L_item_non_fatal_ind := TRUE;
         end if;

         --- The following validation occurs for transaction level items
         if L_edi_row.tran_level = L_edi_row.item_level then
            if L_edi_row.item is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'SKU_NUM_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.item_number_type is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'ITEM_NUM_TYPE_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.store_ord_mult is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'STORE_ORD_MULT_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.short_desc is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'SKU_SHORT_DESC_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
         end if; /* if L_edi_row.tran_level = L_edi_row.item_level then */

         if L_edi_row.item_parent is NOT NULL and
            L_edi_row.item_grandparent is NULL then
            if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                               L_parent_item_rec,
                                               L_edi_row.item_parent) = FALSE then
               return FALSE;
            end if;
         end if; /* if L_edi_row.item_parent is not NULL then */

         ---
         if L_edi_row.item_parent is NOT NULL  and
            L_edi_row.item_grandparent is NULL then
            if L_parent_item_rec.item_level = 1   and
               L_edi_row.item_level = 2 then
               ---
               if L_edi_row.item is NULL then
                  if LOG_FAIL_REASON (O_error_message,
                                      L_seq_no,
                                      L_edi_row.item,
                                      L_edi_row.vpn,
                                      'SKU_NUM_REQ') = FALSE then
                     return FALSE;
                  end if;
                  L_item_non_fatal_ind := TRUE;
               end if;
               if L_edi_row.item_number_type is NULL then
                  if LOG_FAIL_REASON (O_error_message,
                                      L_seq_no,
                                      L_edi_row.item,
                                      L_edi_row.vpn,
                                      'ITEM_NUM_TYPE_REQ') = FALSE then
                     return FALSE;
                  end if;
                  L_item_non_fatal_ind := TRUE;
               end if;
               if L_edi_row.store_ord_mult is NULL then
                  if LOG_FAIL_REASON (O_error_message,
                                      L_seq_no,
                                      L_edi_row.item,
                                      L_edi_row.vpn,
                                      'STORE_ORD_MULT_REQ') = FALSE then
                     return FALSE;
                  end if;
                  L_item_non_fatal_ind := TRUE;
               end if;
               if L_edi_row.short_desc is NULL then
                  if LOG_FAIL_REASON (O_error_message,
                                      L_seq_no,
                                      L_edi_row.item,
                                      L_edi_row.vpn,
                                      'SKU_SHORT_DESC_REQ') = FALSE then
                     return FALSE;
                  end if;
                  L_item_non_fatal_ind := TRUE;
               end if;
            end if;/* L_parent_item_rec.item_level = 1 and L_edi_row.item_level = 2 */
         end if; /* if L_edi_row.item_parent is not NULL and L_edi_row.item_grandparent is NULL */

         --- if the new item is sub-transaction level, this will validate that all the parent
         --- level information has been entered
         if L_edi_row.item_parent is NOT NULL
            and L_edi_row.item_level = 3 then
         ---
            if L_edi_row.item_parent is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'ENT_ITEM_PARENT') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.item_parent_number_type is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'PRNT_NUM_TYPE_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            ---
            if L_edi_row.item_parent_number_type = 'VPLU' then
               if L_edi_row.item_parent_format_id is NULL then
                  if LOG_FAIL_REASON (O_error_message,
                                      L_seq_no,
                                      L_edi_row.item,
                                      L_edi_row.vpn,
                                      'PARENT_FORMAT_ID_REQ') = FALSE then
                     return FALSE;
                  end if;
                  L_item_non_fatal_ind := TRUE;
               end if;

               ---
               if L_edi_row.item_parent_prefix is NULL then
                  if LOG_FAIL_REASON (O_error_message,
                                      L_seq_no,
                                      L_edi_row.item,
                                      L_edi_row.vpn,
                                      'PARENT_PREFIX_REQ') = FALSE then
                     return FALSE;
                  end if;
                  L_item_non_fatal_ind := TRUE;
               end if;

               if VAR_UPC_SQL.GET_FORMAT_INFO(O_error_message,
                                              L_valid,
                                              L_format_desc,
                                              L_prefix_length,
                                              L_begin_item_digit,
                                              L_begin_var_digit,
                                              L_check_digit,
                                              L_default_prefix,
                                              L_edi_row.item_parent_format_id) then
                  return FALSE;
               end if;

               if L_prefix_length is NULL then
                  if LOG_FAIL_REASON (O_error_message,
                                      L_seq_no,
                                      L_edi_row.item,
                                      L_edi_row.vpn,
                                      'PARENT_PREFIX_LENGTH_REQ') = FALSE then
                     return FALSE;
                  end if;
                  L_item_non_fatal_ind := TRUE;
               end if;
            end if; /* if L_edi_row.item_parent_number_type = 'VPLU' then */
         end if; /* if L_edi_row.item_parent is not NULL */

         ---
         if L_edi_row.diff_1 is NOT NULL and L_edi_row.item_parent is NOT NULL
         and L_edi_row.item_level != 1 then
            if ITEM_ATTRIB_SQL.GET_DIFFS(O_error_message,
                                         L_diff_1,
                                         L_diff_2,
                                         L_diff_3,
                                         L_diff_4,
                                         L_edi_row.item_parent) = FALSE then

               return FALSE;
            end if;

            ---
            if DIFF_SQL.GET_DIFF_INFO(O_error_message,
                                      L_desc,
                                      L_diff_type,
                                      L_diff_1_group_ind,
                                      L_diff_1) = FALSE then

               return FALSE;
            end if;

            ---
            if L_edi_row.diff_2 is NOT NULL then
               if DIFF_SQL.GET_DIFF_INFO(O_error_message,
                                         L_desc,
                                         L_diff_type,
                                         L_diff_2_group_ind,
                                         L_diff_2) = FALSE then

                  return FALSE;
               end if;
            end if;

            ---
            if L_diff_1_group_ind = 'GROUP' or
               L_diff_2_group_ind = 'GROUP' or
               L_diff_3_group_ind = 'GROUP' or
               L_diff_4_group_ind = 'GROUP' then
               if EDITEM_SQL.CHECK_DUPL(O_error_message,
                                        L_flag,
                                        L_edi_row.item_parent,
                                        L_edi_row.diff_1,
                                        L_edi_row.diff_2,
                                        L_edi_row.diff_3,
                                        L_edi_row.diff_4) = FALSE then

                   return FALSE;
               elsif L_flag = 'Y' then
                  if LOG_FAIL_REASON (O_error_message,
                                      L_seq_no,
                                      L_edi_row.item,
                                      L_edi_row.vpn,
                                      'ITEM_EXISTS_DIFF',
                                      'F',
                                      L_edi_row.vpn) = FALSE then
                     return FALSE;
                  end if;
                  L_item_non_fatal_ind := TRUE;
               end if;
            end if;
         end if; /* if L_edi_row.diff_1 is not NULL and L_edi_row.item_parent is not NULL */

         if L_item_non_fatal_ind = FALSE then
            savepoint START_OF_CREATE_PROCESS;
            SQL_LIB.SET_MARK('OPEN',
                             'C_lock_record',
                             'edi_new_item',
                             NULL);
            open C_LOCK_RECORD;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_lock_record',
                             'edi_new_item',
                             NULL);
            close C_LOCK_RECORD;

            update edi_new_item
               set status = 'A'
             where seq_no = L_seq_no;

            if SQL%NOTFOUND then
               L_error_message := SQL_LIB.CREATE_MSG('CANNOT_UPD', NULL, NULL, NULL);
               raise CREATION_ERROR;
            end if;

            --- checks to be sure a record does not already exist on edi_like_item
            if EDITEM_SQL.EDI_LIKE_ITEM_EXISTS(L_error_message,
                                               L_existing,
                                               L_edi_row.item) = FALSE then

               raise CREATION_ERROR;
            end if;

            ---
            if L_existing is NULL and L_edi_row.item_grandparent is NOT NULL and
               L_edi_row.item_level = 3 then

               -- create the level 2 item
               if EDITEM_SQL.BUILD_ITEM(L_error_message,
                                        L_no_retail,
                                        L_seq_no,
                                        L_edi_row.item_parent,
                                        2,
                                        L_edi_row.tran_level,
                                        L_edi_row.new_item_ind,
                                        L_edi_row.item_parent_number_type,
                                        L_edi_row.item_parent_format_id,
                                        L_edi_row.item_parent_prefix,
                                        L_edi_row.item_grandparent,
                                        NULL,
                                        L_edi_row.diff_1,
                                        L_edi_row.diff_2,
                                        L_edi_row.diff_3,
                                        L_edi_row.diff_4,
                                        L_edi_row.dept,
                                        L_edi_row.class,
                                        L_edi_row.subclass,
                                        L_edi_row.item_parent_desc,
                                        L_edi_row.short_desc,
                                        L_edi_row.retail_zone_group_id,
                                        L_edi_row.cost_zone_group_id,
                                        L_edi_row.standard_uom,
                                        L_edi_row.uom_conv_factor,
                                        L_edi_row.store_ord_mult,
                                        L_edi_row.supplier,
                                        NULL,
                                        L_edi_row.supp_diff_1,
                                        L_edi_row.supp_diff_2,
                                        L_edi_row.supp_diff_3,
                                        L_edi_row.supp_diff_4,
                                        L_edi_row.origin_country_id,
                                        L_edi_row.lead_time,
                                        L_edi_row.unit_cost,
                                        L_edi_row.supp_pack_size,
                                        L_edi_row.inner_pack_size,
                                        L_edi_row.min_order_qty,
                                        L_edi_row.max_order_qty,
                                        L_edi_row.packing_method,
                                        L_edi_row.default_uop,
                                        L_edi_row.ti,
                                        L_edi_row.hi,
                                        L_edi_row.unit_length,
                                        L_edi_row.unit_width,
                                        L_edi_row.unit_height,
                                        L_edi_row.unit_lwh_uom,
                                        L_edi_row.gross_unit_weight,
                                        L_edi_row.net_unit_weight,
                                        L_edi_row.unit_weight_uom,
                                        L_edi_row.unit_liquid_vol,
                                        L_edi_row.unit_liquid_vol_uom,
                                        L_edi_row.case_length,
                                        L_edi_row.case_width,
                                        L_edi_row.case_height,
                                        L_edi_row.case_lwh_uom,
                                        L_edi_row.gross_case_weight,
                                        L_edi_row.net_case_weight,
                                        L_edi_row.case_weight_uom,
                                        L_edi_row.case_liquid_vol,
                                        L_edi_row.case_liquid_vol_uom,
                                        L_edi_row.pallet_length,
                                        L_edi_row.pallet_width,
                                        L_edi_row.pallet_height,
                                        L_edi_row.pallet_lwh_uom,
                                        L_edi_row.gross_pallet_weight,
                                        L_edi_row.net_pallet_weight,
                                        L_edi_row.pallet_weight_uom,
                                        I_elc_ind,
                                        I_vat_ind,
                                        L_edi_row.default_retail_ind,
                                        L_edi_row.consignment_rate,
                                        L_edi_row.unit_retail,
                                        L_edi_row.item_xform_ind
                                        ) = FALSE then
                  raise CREATION_ERROR;
               end if;

               --- Verify that the item zone price record exist for the parent item.
               if L_no_retail = 'N' then
                  L_error_message := SQL_LIB.CREATE_MSG('NO_RETAIL_RECORD_PARENT',
                                                        NULL,
                                                        NULL,
                                                        NULL);
                  raise CREATION_ERROR;
               end if;

               --- create the level 3 item
               if EDITEM_SQL.BUILD_ITEM(L_error_message,
                                        L_no_retail,
                                        L_seq_no,
                                        L_edi_row.item,
                                        L_edi_row.item_level,
                                        L_edi_row.tran_level,
                                        L_edi_row.new_item_ind,
                                        L_edi_row.item_number_type,
                                        L_edi_row.format_id,
                                        L_edi_row.prefix,
                                        L_edi_row.item_parent,
                                        L_edi_row.item_grandparent,
                                        L_edi_row.diff_1,
                                        L_edi_row.diff_2,
                                        L_edi_row.diff_3,
                                        L_edi_row.diff_4,
                                        L_edi_row.dept,
                                        L_edi_row.class,
                                        L_edi_row.subclass,
                                        L_edi_row.item_desc,
                                        L_edi_row.short_desc,
                                        L_edi_row.retail_zone_group_id,
                                        L_edi_row.cost_zone_group_id,
                                        L_edi_row.standard_uom,
                                        L_edi_row.uom_conv_factor,
                                        L_edi_row.store_ord_mult,
                                        L_edi_row.supplier,
                                        L_edi_row.vpn,
                                        L_edi_row.supp_diff_1,
                                        L_edi_row.supp_diff_2,
                                        L_edi_row.supp_diff_3,
                                        L_edi_row.supp_diff_4,
                                        L_edi_row.origin_country_id,
                                        L_edi_row.lead_time,
                                        L_edi_row.unit_cost,
                                        L_edi_row.supp_pack_size,
                                        L_edi_row.inner_pack_size,
                                        L_edi_row.min_order_qty,
                                        L_edi_row.max_order_qty,
                                        L_edi_row.packing_method,
                                        L_edi_row.default_uop,
                                        L_edi_row.ti,
                                        L_edi_row.hi,
                                        L_edi_row.unit_length,
                                        L_edi_row.unit_width,
                                        L_edi_row.unit_height,
                                        L_edi_row.unit_lwh_uom,
                                        L_edi_row.gross_unit_weight,
                                        L_edi_row.net_unit_weight,
                                        L_edi_row.unit_weight_uom,
                                        L_edi_row.unit_liquid_vol,
                                        L_edi_row.unit_liquid_vol_uom,
                                        L_edi_row.case_length,
                                        L_edi_row.case_width,
                                        L_edi_row.case_height,
                                        L_edi_row.case_lwh_uom,
                                        L_edi_row.gross_case_weight,
                                        L_edi_row.net_case_weight,
                                        L_edi_row.case_weight_uom,
                                        L_edi_row.case_liquid_vol,
                                        L_edi_row.case_liquid_vol_uom,
                                        L_edi_row.pallet_length,
                                        L_edi_row.pallet_width,
                                        L_edi_row.pallet_height,
                                        L_edi_row.pallet_lwh_uom,
                                        L_edi_row.gross_pallet_weight,
                                        L_edi_row.net_pallet_weight,
                                        L_edi_row.pallet_weight_uom,
                                        I_elc_ind,
                                        I_vat_ind,
                                        L_edi_row.default_retail_ind,
                                        L_edi_row.consignment_rate,
                                        L_edi_row.unit_retail,
                                        L_edi_row.item_xform_ind
                                        ) = FALSE then

                  raise CREATION_ERROR;
               end if;

            elsif L_existing is NULL then
               SQL_LIB.SET_MARK('OPEN',
                                'C_ITEM_GRANDPARENT',
                                'item_master',
                                NULL);
               open C_ITEM_GRANDPARENT(L_edi_row.item_parent);
               SQL_LIB.SET_MARK('FETCH',
                                'C_ITEM_GRANDPARENT',
                                'item_master',
                                NULL);
               fetch C_ITEM_GRANDPARENT into L_grandparent_item;
               SQL_LIB.SET_MARK('CLOSE',
                                'C_ITEM_GRANDPARENT',
                                'item_master',
                                NULL);
               close C_ITEM_GRANDPARENT;
               --- For NEW  items that have been accepted:
               if EDITEM_SQL.BUILD_ITEM(L_error_message,
                                        L_no_retail,
                                        L_seq_no,
                                        L_edi_row.item,
                                        L_edi_row.item_level,
                                        L_edi_row.tran_level,
                                        L_edi_row.new_item_ind,
                                        L_edi_row.item_number_type,
                                        L_edi_row.format_id,
                                        L_edi_row.prefix,
                                        L_edi_row.item_parent,
                                        L_grandparent_item,
                                        L_edi_row.diff_1,
                                        L_edi_row.diff_2,
                                        L_edi_row.diff_3,
                                        L_edi_row.diff_4,
                                        L_edi_row.dept,
                                        L_edi_row.class,
                                        L_edi_row.subclass,
                                        L_edi_row.item_desc,
                                        L_edi_row.short_desc,
                                        L_edi_row.retail_zone_group_id,
                                        L_edi_row.cost_zone_group_id,
                                        L_edi_row.standard_uom,
                                        L_edi_row.uom_conv_factor,
                                        L_edi_row.store_ord_mult,
                                        L_edi_row.supplier,
                                        L_edi_row.vpn,
                                        L_edi_row.supp_diff_1,
                                        L_edi_row.supp_diff_2,
                                        L_edi_row.supp_diff_3,
                                        L_edi_row.supp_diff_4,
                                        L_edi_row.origin_country_id,
                                        L_edi_row.lead_time,
                                        L_edi_row.unit_cost,
                                        L_edi_row.supp_pack_size,
                                        L_edi_row.inner_pack_size,
                                        L_edi_row.min_order_qty,
                                        L_edi_row.max_order_qty,
                                        L_edi_row.packing_method,
                                        L_edi_row.default_uop,
                                        L_edi_row.ti,
                                        L_edi_row.hi,
                                        L_edi_row.unit_length,
                                        L_edi_row.unit_width,
                                        L_edi_row.unit_height,
                                        L_edi_row.unit_lwh_uom,
                                        L_edi_row.gross_unit_weight,
                                        L_edi_row.net_unit_weight,
                                        L_edi_row.unit_weight_uom,
                                        L_edi_row.unit_liquid_vol,
                                        L_edi_row.unit_liquid_vol_uom,
                                        L_edi_row.case_length,
                                        L_edi_row.case_width,
                                        L_edi_row.case_height,
                                        L_edi_row.case_lwh_uom,
                                        L_edi_row.gross_case_weight,
                                        L_edi_row.net_case_weight,
                                        L_edi_row.case_weight_uom,
                                        L_edi_row.case_liquid_vol,
                                        L_edi_row.case_liquid_vol_uom,
                                        L_edi_row.pallet_length,
                                        L_edi_row.pallet_width,
                                        L_edi_row.pallet_height,
                                        L_edi_row.pallet_lwh_uom,
                                        L_edi_row.gross_pallet_weight,
                                        L_edi_row.net_pallet_weight,
                                        L_edi_row.pallet_weight_uom,
                                        I_elc_ind,
                                        I_vat_ind,
                                        L_edi_row.default_retail_ind,
                                        L_edi_row.consignment_rate,
                                        L_edi_row.unit_retail,
                                        L_edi_row.item_xform_ind
                                        ) = FALSE then
                  raise CREATION_ERROR;
               end if;

               --- Verify that the item zone price record exist for the parent item.
               if L_no_retail = 'N' then
                  L_error_message := SQL_LIB.CREATE_MSG('NO_RETAIL_RECORD_PARENT',
                                                        NULL,
                                                        NULL,
                                                        NULL);
                  raise CREATION_ERROR;
               end if;

            elsif L_existing is NOT NULL then
               --- For NEW items that have been accepted:
               if EDITEM_SQL.GET_LIKE_ITEM_IND(L_error_message,
                                               L_supplier_ind,
                                               L_price_ind,
                                               L_store_ind,
                                               L_warehouse_ind,
                                               L_replenishment_ind,
                                               L_uda_ind,
                                               L_seasons_ind,
                                               L_ticket_ind,
                                               L_req_doc_ind,
                                               L_hts_ind,
                                               L_tax_code_ind,
                                               L_create_children_ind,
                                               L_diff_1,
                                               L_diff_2,
                                               L_diff_3,
                                               L_diff_4,
                                               L_existing_item,
                                               L_edi_row.item) = FALSE then

                  raise CREATION_ERROR;
               end if;

               ---
               if L_edi_row.item_grandparent is NOT NULL and L_edi_row.item_level = 3 then
                  if ITEM_ATTRIB_SQL.GET_PARENT_INFO(L_error_message,
                                                     L_parent,
                                                     L_parent_desc,
                                                     L_grandparent,
                                                     L_grandparent_desc,
                                                     L_existing) = FALSE then
                     raise CREATION_ERROR;
                  end if;

                  ---
                  if EDITEM_SQL.SUPPLIER_EXISTS(L_error_message,
                                                L_supplier_ind,
                                                L_edi_row.supplier,
                                                L_existing) = FALSE then
                     raise CREATION_ERROR;
                  end if;

                  --- insert the level 2 item information
                  if LIKE_ITEM_SQL.LIKE_ITEM_INSERT(L_error_message,
                                                    L_edi_row.item_parent,
                                                    L_parent,
                                                    L_edi_row.item_parent_desc,
                                                    L_edi_row.item_parent_number_type,
                                                    L_edi_row.item_parent_format_id,
                                                    L_edi_row.item_parent_prefix,
                                                    L_diff_1,
                                                    L_diff_2,
                                                    L_diff_3,
                                                    L_diff_4,
                                                    L_create_children_ind,
                                                    L_supplier_ind,
                                                    L_price_ind,
                                                    L_store_ind,
                                                    L_warehouse_ind,
                                                    L_replenishment_ind,
                                                    L_uda_ind,
                                                    L_seasons_ind,
                                                    L_ticket_ind,
                                                    L_req_doc_ind,
                                                    L_hts_ind,
                                                    L_tax_code_ind,
                                                    'Y',
                                                    L_seq_no,
                                                    L_internal_finisher,
                                                    L_external_finisher) = FALSE then
                     raise CREATION_ERROR;
                  end if;

                  --- insert the level 3 item information
                  if LIKE_ITEM_SQL.LIKE_ITEM_INSERT(L_error_message,
                                                    L_edi_row.item,
                                                    L_existing,
                                                    L_edi_row.item_desc,
                                                    L_edi_row.item_number_type,
                                                    L_edi_row.format_id,
                                                    L_edi_row.prefix,
                                                    L_diff_1,
                                                    L_diff_2,
                                                    L_diff_3,
                                                    L_diff_4,
                                                    L_create_children_ind,
                                                    L_supplier_ind,
                                                    L_price_ind,
                                                    L_store_ind,
                                                    L_warehouse_ind,
                                                    L_replenishment_ind,
                                                    L_uda_ind,
                                                    L_seasons_ind,
                                                    L_ticket_ind,
                                                    L_req_doc_ind,
                                                    L_hts_ind,
                                                    L_tax_code_ind,
                                                    'Y',
                                                    L_seq_no,
                                                    L_internal_finisher,
                                                    L_external_finisher) = FALSE then
                     raise CREATION_ERROR;
                  end if;

               elsif L_edi_row.item_grandparent is NULL or L_edi_row.item_level != 3 then
                  if EDITEM_SQL.SUPPLIER_EXISTS(L_error_message,
                                                L_supplier_ind,
                                                L_edi_row.supplier,
                                                L_existing) = FALSE then

                     raise CREATION_ERROR;
                  end if;

                  ---
                  if LIKE_ITEM_SQL.LIKE_ITEM_INSERT(L_error_message,
                                                    L_edi_row.item,
                                                    L_existing,
                                                    L_edi_row.item_desc,
                                                    L_edi_row.item_number_type,
                                                    L_edi_row.format_id,
                                                    L_edi_row.prefix,
                                                    L_diff_1,
                                                    L_diff_2,
                                                    L_diff_3,
                                                    L_diff_4,
                                                    L_create_children_ind,
                                                    L_supplier_ind,
                                                    L_price_ind,
                                                    L_store_ind,
                                                    L_warehouse_ind,
                                                    L_replenishment_ind,
                                                    L_uda_ind,
                                                    L_seasons_ind,
                                                    L_ticket_ind,
                                                    L_req_doc_ind,
                                                    L_hts_ind,
                                                    L_tax_code_ind,
                                                    'Y',
                                                    L_seq_no,
                                                    L_internal_finisher,
                                                    L_external_finisher) = FALSE then
                     raise CREATION_ERROR;
                  end if;
               end if;

               ---
               if EDITEM_SQL.EDI_LIKE_ITEM_DELETE(L_error_message,
                                                  L_edi_row.item) = FALSE then

                  raise CREATION_ERROR;
               end if;
            end if;

            ---
            if L_edi_row.tran_level = 1 and L_edi_row.item_level = 1 then
               if L_edi_row.keep_ref_item_ind = 'Y' then
                  if EDITEM_SQL.BUILD_ITEM(L_error_message,
                                           L_no_retail,
                                           L_seq_no,
                                           L_edi_row.ref_item,
                                           '2',
                                           L_edi_row.tran_level,
                                           L_edi_row.new_item_ind,
                                           L_edi_row.item_number_type,
                                           L_edi_row.format_id,
                                           L_edi_row.prefix,
                                           L_edi_row.item,
                                           NULL,
                                           L_edi_row.diff_1,
                                           L_edi_row.diff_2,
                                           L_edi_row.diff_3,
                                           L_edi_row.diff_4,
                                           L_edi_row.dept,
                                           L_edi_row.class,
                                           L_edi_row.subclass,
                                           L_edi_row.item_desc,
                                           L_edi_row.short_desc,
                                           L_edi_row.retail_zone_group_id,
                                           L_edi_row.cost_zone_group_id,
                                           L_edi_row.standard_uom,
                                           L_edi_row.uom_conv_factor,
                                           L_edi_row.store_ord_mult,
                                           L_edi_row.supplier,
                                           NULL,
                                           L_edi_row.supp_diff_1,
                                           L_edi_row.supp_diff_2,
                                           L_edi_row.supp_diff_3,
                                           L_edi_row.supp_diff_4,
                                           L_edi_row.origin_country_id,
                                           L_edi_row.lead_time,
                                           L_edi_row.unit_cost,
                                           L_edi_row.supp_pack_size,
                                           L_edi_row.inner_pack_size,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                          'N',
                                          'N',
                                          L_edi_row.default_retail_ind,
                                          L_edi_row.consignment_rate,
                                          L_edi_row.unit_retail,
                                          L_edi_row.item_xform_ind
                                          ) = FALSE then
                     raise CREATION_ERROR;
                  end if;

                  --- Verify that the item zone price record exist for the parent item.
                  if L_no_retail = 'N' then
                     L_error_message := SQL_LIB.CREATE_MSG('NO_RETAIL_RECORD_PARENT',
                                                           NULL,
                                                           NULL,
                                                           NULL);
                     raise CREATION_ERROR;
                  end if;
               end if;
            end if;

            ---
            if L_edi_row.case_ref_item is NOT NULL and
               L_edi_row.new_case_pack_ind = 'Y' then
               --- For NEW items that have been accepted:
               if L_edi_row.item_level = L_edi_row.tran_level then
                  L_tran_level_item := L_edi_row.item;
               elsif L_edi_row.item_grandparent is not NULL and
                  L_edi_row.item_parent is NOT NULL then
                  if L_edi_row.tran_level = 2 then
                     L_tran_level_item := L_edi_row.item_parent;
                  elsif L_edi_row.tran_level = 3 then
                     L_tran_level_item := L_edi_row.item;
                  end if;

               elsif L_edi_row.item_parent is NOT NULL then
                  if L_parent_item_rec.item_level = L_edi_row.tran_level then
                     L_tran_level_item := L_edi_row.item_parent;
                  else
                     L_tran_level_item := L_edi_row.item;
                  end if;

              end if;

               ---
               if L_tran_level_item is NOT NULL then
                  if L_edi_row.retail_zone_group_id is NULL then
                     L_retail_zone_group_ind := 'N';
                  else
                     L_retail_zone_group_ind := 'Y';
                  end if;

                  ---
                  if L_edi_row.case_upc_ind = 'Y' then
                     --- retrieves a rtk item number to use as the tran level pack number
                     if ITEM_NUMBER_TYPE_SQL.GET_NEXT(L_error_message,
                                                      L_next_item,
                                                     'ITEM') = FALSE then
                        raise CREATION_ERROR;
                     end if;
                     ---
                     if EDITEM_SQL.SIMPLE_PACK_TEMP_INSERT(L_error_message,
                                                           L_next_item,
                                                           'ITEM',
                                                           L_tran_level_item,
                                                           L_edi_row.case_item_desc,
                                                           L_edi_row.supp_pack_size,    -- ITEM QUANTITY
                                                           L_edi_row.supplier,
                                                           L_edi_row.origin_country_id,
                                                           L_edi_row.case_cost,
                                                           L_retail_zone_group_ind,     -- SELLABLE IND
                                                           NULL,
                                                           1,
                                                           L_edi_row.ti,
                                                           L_edi_row.hi,
                                                           L_edi_row.case_length,
                                                           L_edi_row.case_width,
                                                           L_edi_row.case_height,
                                                           L_edi_row.case_lwh_uom,
                                                           L_edi_row.gross_case_weight,
                                                           L_edi_row.net_case_weight,
                                                           L_edi_row.case_weight_uom,
                                                           L_edi_row.case_liquid_vol,
                                                           L_edi_row.case_liquid_vol_uom,
                                                           L_edi_row.pallet_length,
                                                           L_edi_row.pallet_width,
                                                           L_edi_row.pallet_height,
                                                           L_edi_row.pallet_lwh_uom,
                                                           L_edi_row.gross_pallet_weight,
                                                           L_edi_row.net_pallet_weight,
                                                           L_edi_row.pallet_weight_uom) = FALSE then
                        raise CREATION_ERROR;
                     end if;

                     ---

                     if not SIMPLE_PACK_SQL.BUILD_PACK(L_error_message,
                                                       L_exists,
                                                       L_exists_item,
                                                       L_tran_level_item,
                                                       'N',
                                                       'Y',
                                                       'Y',
                                                       'Y',
                                                       'Y',
                                                       'Y',
                                                       'Y',
                                                       'Y',
                                                       'Y',
                                                       'Y',
                                                       'Y',
                                                       'Y',
                                                       -- NBS005922, John Alister Anand, 11-Apr-2008, Begin
                                                       'N',
                                                       -- NBS005922, John Alister Anand, 11-Apr-2008, End
                                                       I_supp_currency,
                                                       L_edi_row.item_xform_ind,
                                                       nvl( L_inventory_ind, 'N' ),
                                                       L_internal_finisher,
                                                       L_external_finisher,
                                                       -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,Begin
                                                       L_owner_country
                                                       -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,End
                                                       ) then
                        raise CREATION_ERROR;
                     end if;

                     ---
                     -- If one of the packs being built has an item number which is the same as another
                     -- item in the system, the pack build procedure is stopped and the user is informed of the
                     -- pack that has the invalid item number. When this happens, none of the packs are built.
                     -- The user must correct the invalid pack before the pack build process can proceed.
                     ---
                     if L_exists then
                        L_error_message := SQL_LIB.CREATE_MSG('NO_PACK_ITEM_IN_USE',
                                                              NULL,
                                                              NULL,
                                                              NULL);
                        raise CREATION_ERROR;
                     end if;

                     ---
                     if EDI_COST_CHG_SQL.VERIFY_DETAIL_RECORDS(L_error_message,
                                                               L_exists2,
                                                               L_seq_no) = FALSE then
                        raise CREATION_ERROR;
                     end if;

                     ---
                     if L_exists2 = 'Y' then
                        if EDI_BRACKET_SQL.UPDATE_BRACKET_PACK_COSTS(L_error_message,
                                                                     L_next_item,
                                                                     L_edi_row.supplier,
                                                                     L_edi_row.origin_country_id,
                                                                     L_seq_no) = FALSE then
                           raise CREATION_ERROR;
                        end if;
                     end if;

                     ---
                     if SIMPLE_PACK_SQL.DELETE_SIMPLE_PACK_TEMP(L_error_message,
                                                                L_tran_level_item) = FALSE then
                        raise CREATION_ERROR;
                     end if;

                     ---
                     if EDITEM_SQL.CREATE_REF_CASE(L_error_message,
                                                   L_next_item,
                                                   L_edi_row.case_ref_item)= FALSE then
                        raise CREATION_ERROR;
                     end if;

                  else   --- the case_upc_ind = 'N'
                     if EDITEM_SQL.SIMPLE_PACK_TEMP_INSERT(L_error_message,
                                                           L_edi_row.case_ref_item,
                                                           L_edi_row.case_ref_item_type,
                                                           L_tran_level_item,
                                                           L_edi_row.case_item_desc,
                                                           L_edi_row.supp_pack_size, -- ITEM QUANTITY
                                                           L_edi_row.supplier,
                                                           L_edi_row.origin_country_id,
                                                           L_edi_row.case_cost,
                                                           L_retail_zone_group_ind,  -- SELLABLE IND
                                                           NULL,
                                                           1,
                                                           L_edi_row.ti,
                                                           L_edi_row.hi,
                                                           L_edi_row.case_length,
                                                           L_edi_row.case_width,
                                                           L_edi_row.case_height,
                                                           L_edi_row.case_lwh_uom,
                                                           L_edi_row.gross_case_weight,
                                                           L_edi_row.net_case_weight,
                                                           L_edi_row.case_weight_uom,
                                                           L_edi_row.case_liquid_vol,
                                                           L_edi_row.case_liquid_vol_uom,
                                                           L_edi_row.pallet_length,
                                                           L_edi_row.pallet_width,
                                                           L_edi_row.pallet_height,
                                                           L_edi_row.pallet_lwh_uom,
                                                           L_edi_row.gross_pallet_weight,
                                                           L_edi_row.net_pallet_weight,
                                                           L_edi_row.pallet_weight_uom) = FALSE then
                        raise CREATION_ERROR;
                     end if;

                     ---
                     if SIMPLE_PACK_SQL.BUILD_PACK(L_error_message,
                                                   L_exists,
                                                   L_exists_item,
                                                   L_tran_level_item,
                                                   'N',
                                                   'Y',
                                                   'Y',
                                                   'Y',
                                                   'Y',
                                                   'Y',
                                                   'Y',
                                                   'Y',
                                                   'Y',
                                                   'Y',
                                                   'Y',
                                                   'Y',
                                                   -- NBS005922, John Alister Anand, 11-Apr-2008, Begin
                                                   'N',
                                                   -- NBS005922, John Alister Anand, 11-Apr-2008, End
                                                   I_supp_currency,
                                                   L_edi_row.item_xform_ind,
                                                   nvl( L_inventory_ind, 'N' ),
                                                   L_internal_finisher,
                                                   L_external_finisher,
                                                   -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,Begin
                                                   L_owner_country
                                                   -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,End
                                                   ) = FALSE then
                        raise CREATION_ERROR;
                     end if;
                  end if;

                  ---
                  -- If one of the packs being built has an item number which is the same as another
                  -- item in the system, the pack build procedure is stopped and the user is informed of the
                  -- pack that has the invalid item number. When this happens, none of the packs are built.
                  -- The user must correct the invalid pack before the pack build process can proceed.
                  ---
                  if L_exists then
                     L_error_message := SQL_LIB.CREATE_MSG('NO_PACK_ITEM_IN_USE',
                                                           NULL,
                                                           NULL,
                                                           NULL);
                     raise CREATION_ERROR;
                  end if;

                  ---
                  if EDI_COST_CHG_SQL.VERIFY_DETAIL_RECORDS(L_error_message,
                                                            L_exists2,
                                                            L_seq_no) = FALSE then

                     raise CREATION_ERROR;
                  end if;

                  ---
                  if L_exists2 = 'Y' then
                     if EDI_BRACKET_SQL.UPDATE_BRACKET_PACK_COSTS(L_error_message,
                                                                  L_edi_row.case_ref_item,
                                                                  L_edi_row.supplier,
                                                                  L_edi_row.origin_country_id,
                                                                  L_seq_no) = FALSE then
                        raise CREATION_ERROR;
                     end if;
                  end if;

                  ---
                  if SIMPLE_PACK_SQL.DELETE_SIMPLE_PACK_TEMP(L_error_message,
                                                             L_tran_level_item) = FALSE then

                     raise CREATION_ERROR;
                  end if;
               end if;
            end if;

            -- Delete the EDI_COST_CHG and EDI_COST_LOC records for this sequence number
            -- where the case indicator = N.
            --
            if EDITEM_SQL.EDI_COST_DELETE(L_error_message,
                                          L_seq_no) = FALSE then
               raise CREATION_ERROR;
            end if;
         end if;-- end O_non_fatal_ind = FALSE

      elsif L_edi_row.new_case_pack_ind = 'Y' then
         if L_edi_row.case_ref_item is NOT NULL then

            if L_edi_row.item_level is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'ITEM_LEVEL_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.tran_level is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'TRAN_LEVEL_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.item is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'SKU_NUM_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.item_number_type is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'ITEM_NUM_TYPE_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.case_ref_item_type is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'CASE_NUM_TYPE_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.case_item_desc is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'PACK_DESC_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;
            if L_edi_row.case_cost is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'CASE_COST_REQ') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;

            if L_edi_row.item_level = L_edi_row.tran_level then
               L_tran_level_item := L_edi_row.item;
            end if;

            if L_tran_level_item is NULL then
               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   'ITEM_TRAN_LEVEL') = FALSE then
                  return FALSE;
               end if;
               L_item_non_fatal_ind := TRUE;
            end if;

            ---
            if SYSTEM_OPTIONS_SQL.GET_AIP_IND (L_aip_ind,
                                               L_error_message) = FALSE then

               if LOG_FAIL_REASON (O_error_message,
                                   L_seq_no,
                                   L_edi_row.item,
                                   L_edi_row.vpn,
                                   L_error_message) = FALSE then
                  return FALSE;
               end if;

               L_item_non_fatal_ind := TRUE;
            end if;
            ---
            if L_tran_level_item is not NULL then
               if L_aip_ind = 'Y' then
                  if PACKITEM_VALIDATE_SQL.CHECK_DUPLICATE_PACK(L_error_message,
                                                                L_exists,
                                                                L_edi_row.case_ref_item,
                                                                L_tran_level_item,
                                                                nvl(L_edi_row.supp_pack_size,1)) = FALSE then
                     return FALSE;
                  end if;

                  if L_exists then
                     if LOG_FAIL_REASON (O_error_message,
                                         L_seq_no,
                                         L_edi_row.item,
                                         L_edi_row.vpn,
                                         'SIMPLE_PACK_EXISTS') = FALSE then
                        return FALSE;
                     end if;

                     L_item_non_fatal_ind := TRUE;
                  end if;
               end if;
            end if;
            ---
            if L_tran_level_item is NOT NULL then
               if L_edi_row.retail_zone_group_id is NULL then
                  L_retail_zone_group_ind := 'N';
               else
                  L_retail_zone_group_ind := 'Y';
               end if;
            end if;
            L_inventory_ind := 'Y';

            ---

            if L_item_non_fatal_ind = FALSE then
               savepoint START_OF_CREATE_PACK_PROCESS;
               SQL_LIB.SET_MARK('OPEN',
                                'C_lock_record',
                                'edi_new_item',
                                NULL);
               open C_LOCK_RECORD;

               SQL_LIB.SET_MARK('CLOSE',
                                'C_lock_record',
                                'edi_new_item',
                                NULL);
               close C_LOCK_RECORD;

               update edi_new_item
                  set status = 'A'
                where seq_no = L_seq_no;

               if SQL%NOTFOUND then
                  L_error_message := SQL_LIB.CREATE_MSG('CANNOT_UPD', NULL, NULL, NULL);
                  raise CREATION_PACK_ERROR;
               end if;

               if L_edi_row.case_upc_ind = 'Y' then
                  --- retrieves a rtk item number to use as the tran level pack number
                  if ITEM_NUMBER_TYPE_SQL.GET_NEXT(L_error_message,
                                                   L_next_item,
                                                   'ITEM') = FALSE then
                     raise CREATION_PACK_ERROR;
                  end if;
                  ---
                  if EDITEM_SQL.SIMPLE_PACK_TEMP_INSERT(L_error_message,
                                                        L_next_item,
                                                        'ITEM',
                                                        L_tran_level_item,
                                                        L_edi_row.case_item_desc,
                                                        L_edi_row.supp_pack_size,    -- ITEM QUANTITY
                                                        L_edi_row.supplier,
                                                        L_edi_row.origin_country_id,
                                                        L_edi_row.case_cost,
                                                        L_retail_zone_group_ind,     -- SELLABLE IND
                                                        NULL,
                                                        1,
                                                        L_edi_row.ti,
                                                        L_edi_row.hi,
                                                        L_edi_row.case_length,
                                                        L_edi_row.case_width,
                                                        L_edi_row.case_height,
                                                        L_edi_row.case_lwh_uom,
                                                        L_edi_row.gross_case_weight,
                                                        L_edi_row.net_case_weight,
                                                        L_edi_row.case_weight_uom,
                                                        L_edi_row.case_liquid_vol,
                                                        L_edi_row.case_liquid_vol_uom,
                                                        L_edi_row.pallet_length,
                                                        L_edi_row.pallet_width,
                                                        L_edi_row.pallet_height,
                                                        L_edi_row.pallet_lwh_uom,
                                                        L_edi_row.gross_pallet_weight,
                                                        L_edi_row.net_pallet_weight,
                                                        L_edi_row.pallet_weight_uom) = FALSE then
                     raise CREATION_PACK_ERROR;
                  end if;

                  ---
                  if not SIMPLE_PACK_SQL.BUILD_PACK(L_error_message,
                                                    L_exists,
                                                    L_exists_item,
                                                    L_tran_level_item,
                                                    'N',
                                                    'Y',
                                                    'Y',
                                                    'Y',
                                                    'Y',
                                                    'Y',
                                                    'Y',
                                                    'Y',
                                                    'Y',
                                                    'Y',
                                                    'Y',
                                                    'Y',
	                                                  -- NBS005922, John Alister Anand, 11-Apr-2008, Begin
	                                                  'N',
	                                                  -- NBS005922, John Alister Anand, 11-Apr-2008, End
                                                    I_supp_currency,
                                                    L_edi_row.item_xform_ind,
                                                    nvl( L_inventory_ind, 'N' ),
                                                    L_internal_finisher,
                                                    L_external_finisher,
                                                    -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,Begin
                                                    L_owner_country
                                                    -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,End
                                                    ) then
                     raise CREATION_PACK_ERROR;
                  end if;

                  ---
                  -- If one of the packs being built has an item number which is the same as another
                  -- item in the system, the pack build procedure is stopped and the user is informed of the
                  -- pack that has the invalid item number. When this happens, none of the packs are built.
                  -- The user must correct the invalid pack before the pack build process can proceed.
                  ---
                  if L_exists then
                     L_error_message := SQL_LIB.CREATE_MSG('NO_PACK_ITEM_IN_USE',
                                                           NULL,
                                                           NULL,
                                                           NULL);
                     raise CREATION_PACK_ERROR;
                  end if;

                  ---
                  if EDI_COST_CHG_SQL.VERIFY_DETAIL_RECORDS(L_error_message,
                                                            L_exists2,
                                                            L_seq_no) = FALSE then
                     raise CREATION_PACK_ERROR;
                  end if;

                  ---
                  if L_exists2 = 'Y' then
                     if EDI_BRACKET_SQL.UPDATE_BRACKET_PACK_COSTS(L_error_message,
                                                                  L_next_item,
                                                                  L_edi_row.supplier,
                                                                  L_edi_row.origin_country_id,
                                                                  L_seq_no) = FALSE then
                        raise CREATION_PACK_ERROR;
                     end if;
                  end if;

                  ---
                  if SIMPLE_PACK_SQL.DELETE_SIMPLE_PACK_TEMP(L_error_message,
                                                             L_tran_level_item) = FALSE then
                     raise CREATION_PACK_ERROR;
                  end if;

                  ---
                  if EDITEM_SQL.CREATE_REF_CASE(L_error_message,
                                                L_next_item,
                                                L_edi_row.case_ref_item)= FALSE then
                     raise CREATION_PACK_ERROR;
                  end if;

               else   --- the case_upc_ind = 'N'
                  if EDITEM_SQL.SIMPLE_PACK_TEMP_INSERT(L_error_message,
                                                        L_edi_row.case_ref_item,
                                                        L_edi_row.case_ref_item_type,
                                                        L_tran_level_item,
                                                        L_edi_row.case_item_desc,
                                                        L_edi_row.supp_pack_size, -- ITEM QUANTITY
                                                        L_edi_row.supplier,
                                                        L_edi_row.origin_country_id,
                                                        L_edi_row.case_cost,
                                                        L_retail_zone_group_ind,  -- SELLABLE IND
                                                        NULL,
                                                        1,
                                                        L_edi_row.ti,
                                                        L_edi_row.hi,
                                                        L_edi_row.case_length,
                                                        L_edi_row.case_width,
                                                        L_edi_row.case_height,
                                                        L_edi_row.case_lwh_uom,
                                                        L_edi_row.gross_case_weight,
                                                        L_edi_row.net_case_weight,
                                                        L_edi_row.case_weight_uom,
                                                        L_edi_row.case_liquid_vol,
                                                        L_edi_row.case_liquid_vol_uom,
                                                        L_edi_row.pallet_length,
                                                        L_edi_row.pallet_width,
                                                        L_edi_row.pallet_height,
                                                        L_edi_row.pallet_lwh_uom,
                                                        L_edi_row.gross_pallet_weight,
                                                        L_edi_row.net_pallet_weight,
                                                        L_edi_row.pallet_weight_uom) = FALSE then
                     raise CREATION_PACK_ERROR;
                  end if;

                  ---
                  if SIMPLE_PACK_SQL.BUILD_PACK(L_error_message,
                                                L_exists,
                                                L_exists_item,
                                                L_tran_level_item,
                                                'N',
                                                'Y',
                                                'Y',
                                                'Y',
                                                'Y',
                                                'Y',
                                                'Y',
                                                'Y',
                                                'Y',
                                                'Y',
                                                'Y',
                                                'Y',
                                                -- NBS005922, John Alister Anand, 11-Apr-2008, Begin
                                                'N',
                                                -- NBS005922, John Alister Anand, 11-Apr-2008, End
                                                I_supp_currency,
                                                L_edi_row.item_xform_ind,
                                                nvl( L_inventory_ind, 'N' ),
                                                L_internal_finisher,
                                                L_external_finisher,
                                                -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,Begin
                                                L_owner_country
                                                -- 20-Aug-2010, CR354, Vinutha R, Vinutha.Raju@in.tesco.com,End
                                                ) = FALSE then
                     raise CREATION_PACK_ERROR;
                  end if;
                  ---
                  -- If one of the packs being built has an item number which is the same as another
                  -- item in the system, the pack build procedure is stopped and the user is informed of the
                  -- pack that has the invalid item number. When this happens, none of the packs are built.
                  -- The user must correct the invalid pack before the pack build process can proceed.
                  ---
                  if L_exists then
                     L_error_message := SQL_LIB.CREATE_MSG('NO_PACK_ITEM_IN_USE',
                                                           NULL,
                                                           NULL,
                                                           NULL);
                     raise CREATION_PACK_ERROR;
                  end if;

                  ---
                  if EDI_COST_CHG_SQL.VERIFY_DETAIL_RECORDS(L_error_message,
                                                            L_exists2,
                                                            L_seq_no) = FALSE then

                     raise CREATION_PACK_ERROR;
                  end if;

                  ---
                  if L_exists2 = 'Y' then
                     if EDI_BRACKET_SQL.UPDATE_BRACKET_PACK_COSTS(L_error_message,
                                                                  L_edi_row.case_ref_item,
                                                                  L_edi_row.supplier,
                                                                  L_edi_row.origin_country_id,
                                                                  L_seq_no) = FALSE then
                        raise CREATION_PACK_ERROR;
                     end if;
                  end if;

                  ---
                  if SIMPLE_PACK_SQL.DELETE_SIMPLE_PACK_TEMP(L_error_message,
                                                             L_tran_level_item) = FALSE then

                     raise CREATION_PACK_ERROR;
                  end if;
               end if;/* if L_edi_row.case_upc_ind = 'Y' */
            end if;/* if L_item_non_fatal_ind = FALSE */
         end if;/* if L_edi_row.case_ref_item is NOT NULL */

      else
         if L_edi_row.case_ref_item is NULL then
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'UPDATE_ITEM_CASE',
                                'W',
                                L_edi_row.item,
                                L_edi_row.case_ref_item) = FALSE then
               return FALSE;
            end if;
         else
            if LOG_FAIL_REASON (O_error_message,
                                L_seq_no,
                                L_edi_row.item,
                                L_edi_row.vpn,
                                'UPDATE_ITEM_UPDATE_CASE',
                                'W',
                                L_edi_row.item,
                                L_edi_row.case_ref_item) = FALSE then
               return FALSE;
            end if;
         end if;

         L_item_warning_ind := TRUE;

         update edi_new_item
            set status = 'A'
         where seq_no = L_seq_no;

      end if; /* if L_edi_row.new_item_ind = 'Y' */
      ---

      SQL_LIB.SET_MARK('OPEN',
                       'C_lock_record',
                       'edi_new_item',
                       NULL);
      open C_LOCK_RECORD;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_lock_record',
                       'edi_new_item',
                       NULL);
      close C_LOCK_RECORD;

      update edi_new_item
         set acc_rej_date = get_vdate
       where seq_no       = L_seq_no;

      if SQL%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('COULD_NOT_UPDATE_REC', NULL, NULL, NULL);
         return FALSE;
      end if;

      if O_non_fatal_ind = FALSE then
         O_non_fatal_ind := L_item_non_fatal_ind ;
      end if;
      if O_warning_ind = FALSE then
         O_warning_ind := L_item_warning_ind ;
      end if;

   END LOOP;

   return TRUE;

EXCEPTION
   when CREATION_ERROR then
       rollback to START_OF_CREATE_PROCESS;
       if SQL_LIB.PARSE_MSG(L_error_message,
                            L_error_message) = FALSE then
          null;
       end if;
       if LOG_FAIL_REASON (O_error_message,
                           L_seq_no,
                           L_item,
                           L_vpn,
                           L_error_message) = FALSE then
          return FALSE;
       end if;
       O_non_fatal_ind := TRUE;
       return TRUE;

   when CREATION_PACK_ERROR then
       rollback to START_OF_CREATE_PACK_PROCESS;
       if SQL_LIB.PARSE_MSG(L_error_message,
                            L_error_message) = FALSE then
          null;
       end if;
       if LOG_FAIL_REASON (O_error_message,
                           L_seq_no,
                           L_item,
                           L_vpn,
                           L_error_message) = FALSE then
          return FALSE;
       end if;
       O_non_fatal_ind := TRUE;
       return TRUE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END MASS_INSERT_ITEM;

-----------------------------------------------------------------------------------------------------------------

FUNCTION UPDATE_SELECTED_IND(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_selected_ind    IN       EDI_NEW_ITEM.SELECTED_IND%TYPE,
                             I_where_clause    IN       VARCHAR2 DEFAULT NULL)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(50)   := 'EDITEM_SQL.UPDATE_SELECTED_IND';
   L_table         VARCHAR2(30)   := NULL;
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(RECORD_LOCKED, -54);

BEGIN

   if I_selected_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_selected_ind',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   L_table := 'EDI_NEW_ITEM';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_EDI_NEW_ITEM',
                     L_table,
                     NULL);

   EXECUTE IMMEDIATE 'select * from edi_new_item '||
                     I_where_clause ||
                     ' for update nowait ';

   EXECUTE IMMEDIATE 'update edi_new_item '||
                     ' set selected_ind = '''||I_selected_ind ||''' '||
                     I_where_clause ;

   if SQL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('NO_RECORDS_UPDATE',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             'I_selected_ind = ' || I_selected_ind,
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_SELECTED_IND;

-----------------------------------------------------------------------------------------------------------------
END EDITEM_SQL;
/

