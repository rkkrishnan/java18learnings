CREATE OR REPLACE PACKAGE BODY ITEM_ADD_SQL AS
-------------------------------------------------------------------------------
FUNCTION INSERT_ITEM(O_error_message        IN OUT VARCHAR2,
                     I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                     I_item_number_type     IN     ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                     I_format_id            IN     ITEM_MASTER.FORMAT_ID%TYPE,
                     I_prefix               IN     ITEM_MASTER.PREFIX%TYPE,
                     I_tran_level           IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                     I_item_desc            IN     ITEM_MASTER.ITEM_DESC%TYPE,
                     I_short_desc           IN     ITEM_MASTER.SHORT_DESC%TYPE,
                     I_dept                 IN     DEPS.DEPT%TYPE,
                     I_class                IN     CLASS.CLASS%TYPE,
                     I_subclass             IN     SUBCLASS.SUBCLASS%TYPE,
                     I_retail_zone_group_id IN     PRICE_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                     I_cost_zone_group_id   IN     COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                     I_diff_1               IN     DIFF_IDS.DIFF_ID%TYPE,
                     I_diff_2               IN     DIFF_IDS.DIFF_ID%TYPE,
                     I_diff_3               IN     DIFF_IDS.DIFF_ID%TYPE,
                     I_diff_4               IN     DIFF_IDS.DIFF_ID%TYPE,
                     I_standard_uom         IN     UOM_CLASS.UOM%TYPE,
                     I_uom_conv_factor      IN     ITEM_MASTER.UOM_CONV_FACTOR%TYPE,
                     I_package_size         IN     ITEM_MASTER.PACKAGE_SIZE%TYPE,
                     I_package_uom          IN     ITEM_MASTER.PACKAGE_UOM%TYPE,
                     I_merchandise_ind      IN     ITEM_MASTER.MERCHANDISE_IND%TYPE,
                     I_store_ord_mult       IN     ITEM_MASTER.STORE_ORD_MULT%TYPE,
                     I_forecast_ind         IN     ITEM_MASTER.FORECAST_IND%TYPE,
                     I_original_retail      IN     ITEM_MASTER.ORIGINAL_RETAIL%TYPE,
                     I_mfg_rec_retail       IN     ITEM_MASTER.MFG_REC_RETAIL%TYPE,
                     I_retail_label_type    IN     ITEM_MASTER.RETAIL_LABEL_TYPE%TYPE,
                     I_retail_label_value   IN     ITEM_MASTER.RETAIL_LABEL_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(62)             := 'ITEM_ADD_SQL.INSERT_ITEM';
   L_user               VARCHAR2(30)             := USER;
   L_desc_up            ITEM_MASTER.DESC_UP%TYPE := UPPER(I_item_desc);

BEGIN

      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_MASTER','ITEM: '||I_item);
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
                              last_update_datetime)
                      values (I_item,
                              I_item_number_type,
                              I_format_id,
                              I_prefix,
                              NULL, -- item_parent,
                              NULL, -- item_grandparent,
                              'N',  -- pack_ind,
                              1,    -- item_level
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
                              L_desc_up, -- UPPER(I_item_desc),
                              'N',
                              I_retail_zone_group_id,
                              I_cost_zone_group_id,
                              I_standard_uom,
                              I_uom_conv_factor,
                              I_package_size,
                              I_package_uom,
                              I_merchandise_ind,
                              I_store_ord_mult,
                              I_forecast_ind,
                              I_original_retail,
                              I_mfg_rec_retail,
                              I_retail_label_type,
                              I_retail_label_value,
                              NULL, -- handling_temp,
                              NULL, -- handling_sensitivity,
                              'N',  -- catch_weight_ind,
                              NULL,
                              NULL,
                              NULL,
                              NULL, -- waste_type,
                              NULL, -- waste_pct,
                              NULL, -- default_waste_pct,
                              'N',  -- const_dimen_ind,
                              'N',  -- simple_pack_ind,
                              'N',  -- contains_inner_ind,
                              'N',  -- sellable_ind,
                              'N',  -- orderable_ind,
                              NULL, -- pack_type,
                              NULL, -- order_as_type,
                              NULL, -- comments,
                              'N',  -- gift_wrap_ind,
                              'N',  -- ship_alone_ind,
                              sysdate,
                              L_user,
                              sysdate);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_ITEM;
----------------------------------------------------------------------------------------
FUNCTION INSERT_ITEM_SUPP_CTRY(O_error_message        IN OUT VARCHAR2,
                               I_item                 IN     item_supplier.item%TYPE,
                               I_supplier             IN     item_supplier.supplier%TYPE,
                               I_origin_country       IN     item_supp_country.origin_country_id%TYPE,
                               I_vpn                  IN     item_supplier.vpn%TYPE,
                               I_consignment_rate     IN     item_supplier.consignment_rate%TYPE,
                               I_pallet_name          IN     item_suppLIER.pallet_name%TYPE,
                               I_case_name            IN     item_suppLIER.case_name%TYPE,
                               I_inner_name           IN     item_suppLIER.inner_name%TYPE,
                               I_unit_cost            IN     item_supp_country.unit_cost%TYPE,
                               I_lead_time            IN     item_supp_country.lead_time%TYPE,
                               I_supp_pack_size       IN     item_supp_country.supp_pack_size%TYPE,
                               I_inner_pack_size      IN     item_supp_country.inner_pack_size%TYPE,
                               I_round_lvl            IN     ITEM_SUPP_COUNTRY.ROUND_LVL%TYPE,
                               I_round_to_inner_pct   IN     ITEM_SUPP_COUNTRY.ROUND_TO_INNER_PCT%TYPE,
                               I_round_to_case_pct    IN     ITEM_SUPP_COUNTRY.ROUND_TO_CASE_PCT%TYPE,
                               I_round_to_layer_pct   IN     ITEM_SUPP_COUNTRY.ROUND_TO_LAYER_PCT%TYPE,
                               I_round_to_pallet_pct  IN     ITEM_SUPP_COUNTRY.ROUND_TO_PALLET_PCT%TYPE,
                               I_packing_method       IN     ITEM_SUPP_COUNTRY.PACKING_METHOD%TYPE,
                               I_default_uop          IN     item_supp_country.default_uop%TYPE,
                               I_ti                   IN     item_supp_country.ti%TYPE,
                               I_hi                   IN     item_supp_country.hi%TYPE,
                               I_length               IN     item_supp_country_DIM.LENGTH%TYPE,
                               I_width                IN     item_supp_country_DIM.WIDTH%TYPE,
                               I_height               IN     item_supp_country_DIM.HEIGHT%TYPE,
                               I_lwh_uom              IN     uom_class.uom%TYPE,
                               I_weight               IN     item_supp_country_DIM.WEIGHT%TYPE,
                               I_weight_uom           IN     uom_class.uom%TYPE)

RETURN BOOLEAN IS

   L_program           VARCHAR2(64)             := 'ITEM_ADD_SQL.INSERT_ITEM_SUPP_CTRY';
   L_sysdate           DATE                     := SYSDATE;
   L_user              USER_ATTRIB.USER_ID%TYPE := USER;
   l_level			   varchar2(2);
   L_standard_uom 	   UOM_CLASS.UOM%TYPE;
   L_standard_class    UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor	   ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
BEGIN
   If NOT ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                          L_standard_uom,
                          L_standard_class,
                          L_conv_factor,
                          I_item,
                          NULL) then
				 Return false;
   End if;

   SQL_LIB.SET_MARK('INSERT',NULL,'item_supplier', NULL);
   ---
   insert into item_supplier(item,
                             supplier,
                             primary_supp_ind,
                             vpn,
                             consignment_rate,
                             pallet_name,
                             case_name,
                             inner_name,
                             direct_ship_ind,
                             create_datetime,
                             last_update_datetime,
                             last_update_id)
                      select I_item,
                             I_supplier,
                             'Y',
                             I_vpn,
                             I_consignment_rate,
                             I_pallet_name,
                             I_case_name,
                             I_inner_name,
                             'N',
                             L_sysdate,
                             L_sysdate,
                             L_user
                        from system_options
                       where not exists (select 'x'
                                           from item_supplier
                                          where item     = I_item
                                            and supplier = I_supplier);
   ---
   SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY',NULL);
   ---
   insert into item_supp_country ( item,
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
                                   create_datetime,
                                   last_update_datetime,
                                   last_update_id,
								   cost_uom
								  )
                            select I_item,
                                   I_supplier,
                                   I_origin_country,
                                   I_unit_cost,
                                   I_lead_time,
                                   I_supp_pack_size,
                                   I_inner_pack_size,
                                   I_round_lvl,
                                   I_round_to_inner_pct,
                                   I_round_to_case_pct,
                                   I_round_to_layer_pct,
                                   I_round_to_pallet_pct,
                                   I_packing_method,
                                   'Y',
                                   'Y',
                                   I_default_uop,
                                   I_ti,
                                   I_hi,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   L_sysdate,
                                   L_sysdate,
                                   L_user,
								   L_standard_uom
                              from system_options
                             where not exists (select 'x'
                                                 from item_supp_country
                                                where item              = I_item
                                                  and supplier          = I_supplier
                                                  and origin_country_id = I_origin_country);

   if I_length is not NULL then
      insert into item_supp_country_dim(item,
                                        supplier,
                                        origin_country,
                                        dim_object,
                                        length,
                                        width,
                                        height,
                                        lwh_uom,
                                        weight,
                                        net_weight,
                                        weight_uom,
                                        create_datetime,
                                        last_update_datetime,
                                        last_update_id)
                                 select I_item,
                                        I_supplier,
                                        I_origin_country,
                                        'CA',
                                        I_length,
                                        I_width,
                                        I_height,
                                        I_lwh_uom,
                                        I_weight,
                                        I_weight,
                                        I_weight_uom,
                                        L_sysdate,
                                        L_sysdate,
                                        L_user
                                   from system_options
                                  where not exists (select 'x'
                                                      from item_supp_country_dim
                                                     where item           = I_item
                                                       and supplier       = I_supplier
                                                       and origin_country = I_origin_country
                                                       and dim_object     = 'CA');
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      O_error_message := l_level||' - '||O_error_message;
	  return FALSE;
END INSERT_ITEM_SUPP_CTRY;
----------------------------------------------------------------------------------------
FUNCTION GET_ITEM_SUPP_CTRY_INFO(O_error_message        IN OUT VARCHAR2,
                                 O_vpn                  IN OUT item_supplier.vpn%TYPE,
                                 O_consignment_rate     IN OUT item_supplier.consignment_rate%TYPE,
                                 O_pallet_name          IN OUT item_suppLIER.pallet_name%TYPE,
                                 O_case_name            IN OUT item_suppLIER.case_name%TYPE,
                                 O_inner_name           IN OUT item_suppLIER.inner_name%TYPE,
                                 O_supp_pack_size       IN OUT item_supp_country.supp_pack_size%TYPE,
                                 O_inner_pack_size      IN OUT item_supp_country.inner_pack_size%TYPE,
                                 O_packing_method       IN OUT ITEM_SUPP_COUNTRY.PACKING_METHOD%TYPE,
                                 O_ti                   IN OUT ITEM_SUPP_COUNTRY.TI%TYPE,
                                 O_hi                   IN OUT ITEM_SUPP_COUNTRY.HI%TYPE,
                                 O_length               IN OUT item_supp_country_DIM.LENGTH%TYPE,
                                 O_width                IN OUT item_supp_country_DIM.WIDTH%TYPE,
                                 O_height               IN OUT item_supp_country_DIM.HEIGHT%TYPE,
                                 O_lwh_uom              IN OUT uom_class.uom%TYPE,
                                 O_weight               IN OUT item_supp_country_DIM.WEIGHT%TYPE,
                                 O_weight_uom           IN OUT uom_class.uom%TYPE,
                                 I_item                 IN     item_supplier.item%TYPE,
                                 I_supplier             IN     item_supplier.supplier%TYPE,
                                 I_origin_country_id    IN     item_supp_country.origin_country_id%TYPE)

RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_ADD_SQL.GET_ITEM_SUPP_CTRY_INFO';
   L_exists               BOOLEAN;
   L_dim_object           ITEM_SUPP_COUNTRY_DIM.DIM_OBJECT%TYPE;
   L_presentation_method  ITEM_SUPP_COUNTRY_DIM.PRESENTATION_METHOD%TYPE;
   L_net_weight           ITEM_SUPP_COUNTRY_DIM.NET_WEIGHT%TYPE;
   L_liquid_volume        ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
   L_liquid_volume_uom    ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE;
   L_stat_cube            ITEM_SUPP_COUNTRY_DIM.STAT_CUBE%TYPE;
   L_tare_weight          ITEM_SUPP_COUNTRY_DIM.TARE_WEIGHT%TYPE;
   L_tare_type            ITEM_SUPP_COUNTRY_DIM.TARE_TYPE%TYPE;

   cursor C_GET_ITEM_SUPP_CTRY is
      select s.vpn,
             s.consignment_rate,
             s.pallet_name,
             s.case_name,
             s.inner_name,
             c.supp_pack_size,
             c.inner_pack_size,
             c.packing_method,
             c.ti,
             c.hi
        from item_supplier s,
             item_supp_country c
       where s.item              = I_item
         and s.supplier          = I_supplier
         and s.item              = c.item
         and s.supplier          = c.supplier
         and c.origin_country_id = I_origin_country_id;

BEGIN
   open C_GET_ITEM_SUPP_CTRY;
   fetch C_GET_ITEM_SUPP_CTRY into O_vpn,
                                   O_consignment_rate,
                                   O_pallet_name,
                                   O_case_name,
                                   O_inner_name,
                                   O_supp_pack_size,
                                   O_inner_pack_size,
                                   O_packing_method,
                                   O_ti,
                                   O_hi;
   close C_GET_ITEM_SUPP_CTRY;
   ---
   if ITEM_SUPP_COUNTRY_SQL.DEFAULT_PRIM_CASE_DIMENSIONS(O_error_message,
                                                         I_item,
                                                         I_supplier,
                                                         I_origin_country_id,
                                                         L_exists,
                                                         L_dim_object,
                                                         L_presentation_method,
                                                         O_length,
                                                         O_width,
                                                         O_height,
                                                         O_lwh_uom,
                                                         O_weight,
                                                         L_net_weight,
                                                         O_weight_uom,
                                                         L_liquid_volume,
                                                         L_liquid_volume_uom,
                                                         L_stat_cube,
                                                         L_tare_weight,
                                                         L_tare_type) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_ITEM_SUPP_CTRY_INFO;
--------------------------------------------------------------------------------------------
FUNCTION POST_QUERY(O_error_message        IN OUT VARCHAR2,
                    O_supplier             IN OUT SUPS.SUPPLIER%TYPE,
                    O_origin_country_id    IN OUT COUNTRY.COUNTRY_ID%TYPE,
                    O_vpn                  IN OUT ITEM_SUPPLIER.VPN%TYPE,
                    O_consignment_rate     IN OUT ITEM_SUPPLIER.CONSIGNMENT_RATE%TYPE,
                    O_pallet_name          IN OUT ITEM_SUPPLIER.PALLET_NAME%TYPE,
                    O_case_name            IN OUT ITEM_SUPPLIER.CASE_NAME%TYPE,
                    O_inner_name           IN OUT ITEM_SUPPLIER.INNER_NAME%TYPE,
                    O_supp_pack_size       IN OUT ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE,
                    O_inner_pack_size      IN OUT ITEM_SUPP_COUNTRY.INNER_PACK_SIZE%TYPE,
                    O_packing_method       IN OUT ITEM_SUPP_COUNTRY.PACKING_METHOD%TYPE,
                    O_ti                   IN OUT ITEM_SUPP_COUNTRY.TI%TYPE,
                    O_hi                   IN OUT ITEM_SUPP_COUNTRY.HI%TYPE,
                    O_length               IN OUT ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE,
                    O_width                IN OUT ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE,
                    O_height               IN OUT ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE,
                    O_lwh_uom              IN OUT UOM_CLASS.UOM%TYPE,
                    O_weight               IN OUT ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE,
                    O_weight_uom           IN OUT UOM_CLASS.UOM%TYPE,
                    I_item                 IN     ITEM_MASTER.ITEM%TYPE)

RETURN BOOLEAN IS

   L_program    VARCHAR2(60) := 'ITEM_ADD_SQL.POST_QUERY';

   cursor C_GET_ITEM_SUPP is
      select supplier,
             vpn,
             consignment_rate,
             inner_name,
             case_name,
             pallet_name
        from item_supplier
       where item             = I_item
         and primary_supp_ind = 'Y';

   cursor C_GET_ITEM_SUPP_CTRY is
      select origin_country_id,
             supp_pack_size,
             inner_pack_size,
             packing_method,
             ti,
             hi
        from item_supp_country
       where item                = I_item
         and primary_supp_ind    = 'Y'
         and primary_country_ind = 'Y';

   cursor C_GET_DIM is
      select length,
             width,
             height,
             lwh_uom,
             weight,
             weight_uom
        from item_supp_country_dim
       where item           = I_item
         and supplier       = O_supplier
         and origin_country = O_origin_country_id
         and dim_object     = 'CA';

BEGIN
   open C_GET_ITEM_SUPP;
   fetch C_GET_ITEM_SUPP into O_supplier,
                              O_vpn,
                              O_consignment_rate,
                              O_inner_name,
                              O_case_name,
                              O_pallet_name;
   close C_GET_ITEM_SUPP;
   ---
   open C_GET_ITEM_SUPP_CTRY;
   fetch C_GET_ITEM_SUPP_CTRY into O_origin_country_id,
                                   O_supp_pack_size,
                                   O_inner_pack_size,
                                   O_packing_method,
                                   O_ti,
                                   O_hi;
   close C_GET_ITEM_SUPP_CTRY;
   ---
   open C_GET_DIM;
   fetch C_GET_DIM into O_length,
                        O_width,
                        O_height,
                        O_lwh_uom,
                        O_weight,
                        O_weight_uom;
   close C_GET_DIM;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END POST_QUERY;
----------------------------------------------------------------------------------------
END ITEM_ADD_SQL;
/

