CREATE OR REPLACE PACKAGE BODY BUYER_WORKSHEET_SQL AS
------------------------------------------------------------------------------
PROCEDURE QUERY_PROCEDURE (buyer_worksheet       IN OUT   BUYER_WKSHT_TAB,
                           I_source_type         IN       REPL_RESULTS.SOURCE_TYPE%TYPE,
                           I_item                IN       REPL_RESULTS.ITEM%TYPE,
                           I_dept                IN       REPL_RESULTS.DEPT%TYPE,
                           I_class               IN       REPL_RESULTS.CLASS%TYPE,
                           I_subclass            IN       REPL_RESULTS.SUBCLASS%TYPE,
                           I_buyer               IN       REPL_RESULTS.BUYER%TYPE,
                           I_before_date         IN       DATE,
                           I_after_date          IN       DATE,
                           I_supp_type           IN       VARCHAR2,
                           I_supplier            IN       REPL_RESULTS.PRIMARY_REPL_SUPPLIER%TYPE,
                           I_origin_country_id   IN       REPL_RESULTS.ORIGIN_COUNTRY_ID%TYPE,
                           I_loc_type            IN       REPL_RESULTS.LOC_TYPE%TYPE,
                           I_location            IN       REPL_RESULTS.LOCATION%TYPE,
                           I_incl_zero           IN       VARCHAR2,
                           I_incl_non_due        IN       VARCHAR2,
                           I_incl_po             IN       VARCHAR2,
                           I_order_by            IN       NUMBER,
                           I_asc_desc            IN       VARCHAR2) IS

   L_order_by               NUMBER(3) := NVL(I_order_by, 2);
   L_loop_counter           NUMBER;
   L_error_message          RTK_ERRORS.RTK_TEXT%TYPE;
   L_return_code            VARCHAR2(10);
   L_prim_curr_code         SYSTEM_OPTIONS.CURRENCY_CODE%TYPE;
   L_item                   REPL_RESULTS.ITEM%TYPE;
   L_prev_source_type       REPL_RESULTS.SOURCE_TYPE%TYPE;
   L_source_type_desc       CODE_DETAIL.CODE_DESC%TYPE;
   L_prev_item              REPL_RESULTS.ITEM%TYPE;
   L_item_desc              ITEM_MASTER.ITEM_DESC%TYPE;
   L_status                 ITEM_MASTER.STATUS%TYPE;
   L_item_level             ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level             ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_diff_1                 ITEM_MASTER.DIFF_1%TYPE;
   L_diff_2                 ITEM_MASTER.DIFF_2%TYPE;
   L_diff_3                 ITEM_MASTER.DIFF_3%TYPE;
   L_diff_4                 ITEM_MASTER.DIFF_4%TYPE;
   L_standard_uom           ITEM_MASTER.STANDARD_UOM%TYPE;
   L_prev_diff_1            ITEM_MASTER.DIFF_1%TYPE;
   L_prev_diff_2            ITEM_MASTER.DIFF_2%TYPE;
   L_prev_diff_3            ITEM_MASTER.DIFF_3%TYPE;
   L_prev_diff_4            ITEM_MASTER.DIFF_4%TYPE;
   L_diff_1_desc            V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_2_desc            V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_3_desc            V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_4_desc            V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_type              V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_id_group_ind           V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_prev_dept              REPL_RESULTS.DEPT%TYPE;
   L_dept_name              DEPS.DEPT_NAME%TYPE;
   L_prev_buyer             REPL_RESULTS.BUYER%TYPE;
   L_buyer_name             BUYER.BUYER_NAME%TYPE;
   L_prev_comp_item         REPL_RESULTS.MASTER_ITEM%TYPE;
   L_comp_item_desc         ITEM_MASTER.ITEM_DESC%TYPE;
   L_prev_supplier          REPL_RESULTS.PRIMARY_REPL_SUPPLIER%TYPE;
   L_sup_name               SUPS.SUP_NAME%TYPE;
   L_currency_code          SUPS.CURRENCY_CODE%TYPE;
   L_terms                  SUPS.TERMS%TYPE;
   L_terms_code             TERMS.TERMS_CODE%TYPE;
   L_freight_terms          SUPS.FREIGHT_TERMS%TYPE;
   L_sup_status             SUPS.SUP_STATUS%TYPE;
   L_qc_ind                 SUPS.QC_IND%TYPE;
   L_edi_po_ind             SUPS.EDI_PO_IND%TYPE;
   L_pre_mark_ind           SUPS.PRE_MARK_IND%TYPE;
   L_ship_method            SUPS.SHIP_METHOD%TYPE;
   L_payment_method         SUPS.PAYMENT_METHOD%TYPE;
   L_curr_desc              CURRENCIES.CURRENCY_DESC%TYPE;
   L_terms_desc             TERMS.TERMS_DESC%TYPE;
   L_freight_terms_desc     FREIGHT_TERMS.TERM_DESC%TYPE;
   L_prev_pool_supplier     REPL_RESULTS.POOL_SUPPLIER%TYPE;
   L_pool_sup_name          SUPS.SUP_NAME%TYPE;
   L_prev_location          REPL_RESULTS.LOCATION%TYPE;
   L_loc_name               STORE.STORE_NAME%TYPE;
   L_prev_physical_wh       REPL_RESULTS.PHYSICAL_WH%TYPE;
   L_phys_wh_name           WH.WH_NAME%TYPE;

   cursor C_ASC_QUERY is
      select 'R',
             NULL source_type_desc,
             item,
             NULL item_desc,
             dept,
             NULL dept_name,
             class,
             NULL class_name,
             subclass,
             NULL subclass_name,
             buyer,
             NULL buyer_name,
             NULL diff_1,
             NULL diff_1_desc,
             NULL diff_2,
             NULL diff_2_desc,
             NULL diff_3,
             NULL diff_3_desc,
             NULL diff_4,
             NULL diff_4_desc,
             item_type,
             DECODE(item_type, 'P', master_item, NULL) comp_item,
             NULL comp_item_desc,
             primary_repl_supplier supplier,
             NULL sup_name,
             origin_country_id,
             pool_supplier,
             NULL pool_sup_name,
             loc_type,
             location,
             NULL loc_name,
             physical_wh,
             NULL phys_wh_name,
             to_number(NULL) current_dscnt,
             to_number(NULL) roi,
             DECODE(item_type, 'P', raw_roq_pack, raw_roq) raw_roq,
             order_roq,
             NULL standard_uom,
             ti,
             hi,
             NULL terms,
             NULL terms_code,
             NVL(supp_lead_time,0) + NVL(pickup_lead_time, 0) total_lead_time,
             supp_unit_cost,
             to_number(NULL) prim_supp_unit_cost,
             unit_cost,
             NULL currency_code,
             NULL prim_curr_code,
             repl_date create_date,
             to_number(NULL) days_to_event,
             to_date(NULL) next_event_date,
             to_date(NULL) target_date,
             status,
             tsf_po_link_no,
             audsid,
             rowidtochar(rowid),
             DECODE(L_order_by, 1, to_char(audsid), 2, item, 3, to_char(primary_repl_supplier), to_char(location)),
             NULL return_code,
             NULL error_message
        from repl_results
       where repl_order_ctrl = 'B'
             /* The below line is to pull back records that are being */
             /* sourced by suppliers and are therefore associated with */
             /* purchase orders. */
         and primary_repl_supplier is NOT NULL
         and source_type = NVL(I_source_type, source_type)
         and item = NVL(I_item, item)
         and dept = NVL(I_dept, dept)
         and class = NVL(I_class, class)
         and subclass = NVL(I_subclass, subclass)
         and (buyer = NVL(I_buyer, buyer)
              or I_buyer is NULL)
         and (repl_date <= I_before_date
              or I_before_date is NULL)
         and (repl_date >= I_after_date
              or I_after_date is NULL)
         and (((I_supp_type = 'S' or I_supp_type is NULL)
              and primary_repl_supplier = NVL(I_supplier, primary_repl_supplier))
              or (I_supp_type = 'P'
              and (pool_supplier = NVL(I_supplier, pool_supplier)
                   or I_supplier is NULL)))
         and origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and (((I_loc_type != 'PW' or I_loc_type is NULL)
              and location = NVL(I_location, location))
              or (I_loc_type = 'PW'
              and (physical_wh = NVL(I_location, physical_wh)
                   or I_location is NULL)))
         and ((I_incl_zero = 'N' and raw_roq > 0)
              or I_incl_zero = 'Y')
         and ((I_incl_non_due = 'N' and due_ind = 'Y')
              or I_incl_non_due = 'Y')
         and ((I_incl_po = 'Y' and status in ('W', 'P'))
              or (I_incl_po = 'N' and status = 'W'))
   UNION ALL
      select 'I',
             NULL source_type_desc,
             item,
             NULL item_desc,
             dept,
             NULL dept_name,
             class,
             NULL class_name,
             subclass,
             NULL subclass_name,
             buyer,
             NULL buyer_name,
             NULL diff_1,
             NULL diff_1_desc,
             NULL diff_2,
             NULL diff_2_desc,
             NULL diff_3,
             NULL diff_3_desc,
             NULL diff_4,
             NULL diff_4_desc,
             item_type,
             DECODE(item_type, 'P', comp_item, NULL) comp_item,
             NULL comp_item_desc,
             supplier,
             NULL sup_name,
             origin_country_id,
             pool_supplier,
             NULL pool_sup_name,
             loc_type,
             location,
             NULL loc_name,
             physical_wh,
             NULL phys_wh_name,
             future_cost - current_cost current_dscnt,
             roi,
             raw_roq,
             order_roq,
             NULL standard_uom,
             ti,
             hi,
             NULL terms,
             NULL terms_code,
             NVL(supp_lead_time, 0) + NVL(pickup_lead_time, 0) total_lead_time,
             supp_unit_cost,
             to_number(NULL) prim_supp_unit_cost,
             unit_cost,
             NULL currency_code,
             NULL prim_curr_code,
             create_date,
             days_to_event,
             next_event_date,
             target_date,
             status,
             to_number(NULL) tsf_po_link_no,
             audsid,
             rowidtochar(rowid),
             DECODE(L_order_by, 1, to_char(audsid), 2, item, 3, to_char(supplier), to_char(location)),
             NULL return_code,
             NULL error_message
        from ib_results
       where ib_order_ctrl = 'B'
         and source_type = NVL(I_source_type, source_type)
         and item = NVL(I_item, item)
         and dept = NVL(I_dept, dept)
         and class = NVL(I_class, class)
         and subclass = NVL(I_subclass, subclass)
         and (buyer = NVL(I_buyer, buyer)
              or I_buyer is NULL)
         and (create_date <= I_before_date
              or I_before_date is NULL)
         and (create_date >= I_after_date
              or I_after_date is NULL)
         and (((I_supp_type = 'S' or I_supp_type is NULL)
              and supplier = NVL(I_supplier, supplier))
              or (I_supp_type = 'P'
              and (pool_supplier = NVL(I_supplier, pool_supplier)
                   or I_supplier is NULL)))
         and origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and (((I_loc_type != 'PW' or I_loc_type is NULL)
              and location = NVL(I_location, location))
              or (I_loc_type = 'PW'
              and (physical_wh = NVL(I_location, physical_wh)
                   or I_location is NULL)))
         and ((I_incl_zero = 'N' and raw_roq > 0)
              or I_incl_zero = 'Y')
         and ((I_incl_po = 'Y' and status in ('W', 'P'))
              or (I_incl_po = 'N' and status = 'W'))
   UNION ALL
      select 'M',
             NULL source_type_desc,
             item,
             NULL item_desc,
             dept,
             NULL dept_name,
             class,
             NULL class_name,
             subclass,
             NULL subclass_name,
             buyer,
             NULL buyer_name,
             NULL diff_1,
             NULL diff_1_desc,
             NULL diff_2,
             NULL diff_2_desc,
             NULL diff_3,
             NULL diff_3_desc,
             NULL diff_4,
             NULL diff_4_desc,
             item_type,
             DECODE(item_type, 'P', comp_item, NULL) comp_item,
             NULL comp_item_desc,
             supplier,
             NULL sup_name,
             origin_country_id,
             pool_supplier,
             NULL pool_sup_name,
             loc_type,
             location,
             NULL loc_name,
             physical_wh,
             NULL phys_wh_name,
             to_number(NULL) current_dscnt,
             to_number(NULL) roi,
             0 raw_roq,
             order_roq,
             NULL standard_uom,
             ti,
             hi,
             NULL terms,
             NULL terms_code,
             NVL(supp_lead_time, 0) + NVL(pickup_lead_time, 0) total_lead_time,
             supp_unit_cost,
             to_number(NULL) prim_supp_unit_cost,
             unit_cost,
             NULL currency_code,
             NULL prim_curr_code,
             create_date,
             to_number(NULL) days_to_event,
             to_date(NULL) next_event_date,
             to_date(NULL) target_date,
             status,
             tsf_po_link_no,
             audsid,
             rowidtochar(rowid),
             DECODE(L_order_by, 1, to_char(audsid), 2, item, 3, to_char(supplier), to_char(location)),
             NULL return_code,
             NULL error_message
        from buyer_wksht_manual
       where source_type = NVL(I_source_type, source_type)
         and item = NVL(I_item, item)
         and dept = NVL(I_dept, dept)
         and class = NVL(I_class, class)
         and subclass = NVL(I_subclass, subclass)
         and (buyer = NVL(I_buyer, buyer)
              or I_buyer is NULL)
         and (create_date <= I_before_date
              or I_before_date is NULL)
         and (create_date >= I_after_date
              or I_after_date is NULL)
         and (((I_supp_type = 'S' or I_supp_type is NULL)
              and supplier = NVL(I_supplier, supplier))
              or (I_supp_type = 'P'
              and (pool_supplier = NVL(I_supplier, pool_supplier)
                   or I_supplier is NULL)))
         and origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and (((I_loc_type != 'PW' or I_loc_type is NULL)
              and location = NVL(I_location, location))
              or (I_loc_type = 'PW'
              and (physical_wh = NVL(I_location, physical_wh)
                   or I_location is NULL)))
         and ((I_incl_po = 'Y' and status in ('W', 'P'))
              or (I_incl_po = 'N' and status = 'W'))
      order by 57 ASC;  /* The order by number is associated with the 'DECODE(L_order_by...' */
                        /* clause in the select statement.  If columns are added or */
                        /* removed from the select statement this number must be updated */
                        /* to reflect the 'DECODE(L_order_by...' statement's position */
                        /* in the select statement. */

   cursor C_DESC_QUERY is
      select 'R',
             NULL source_type_desc,
             item,
             NULL item_desc,
             dept,
             NULL dept_name,
             class,
             NULL class_name,
             subclass,
             NULL subclass_name,
             buyer,
             NULL buyer_name,
             NULL diff_1,
             NULL diff_1_desc,
             NULL diff_2,
             NULL diff_2_desc,
             NULL diff_3,
             NULL diff_3_desc,
             NULL diff_4,
             NULL diff_4_desc,
             item_type,
             DECODE(item_type, 'P', master_item, NULL) comp_item,
             NULL comp_item_desc,
             primary_repl_supplier supplier,
             NULL sup_name,
             origin_country_id,
             pool_supplier,
             NULL pool_sup_name,
             loc_type,
             location,
             NULL loc_name,
             physical_wh,
             NULL phys_wh_name,
             to_number(NULL) current_dscnt,
             to_number(NULL) roi,
             DECODE(item_type, 'P', raw_roq_pack, raw_roq) raw_roq,
             order_roq,
             NULL standard_uom,
             ti,
             hi,
             NULL terms,
             NULL terms_code,
             NVL(supp_lead_time,0) + NVL(pickup_lead_time, 0) total_lead_time,
             supp_unit_cost,
             to_number(NULL) prim_supp_unit_cost,
             unit_cost,
             NULL currency_code,
             NULL prim_curr_code,
             repl_date create_date,
             to_number(NULL) days_to_event,
             to_date(NULL) next_event_date,
             to_date(NULL) target_date,
             status,
             tsf_po_link_no,
             to_char(audsid),
             rowidtochar(rowid),
             DECODE(L_order_by, 1, to_char(audsid), 2, item, 3, to_char(primary_repl_supplier), to_char(location)),
             NULL return_code,
             NULL error_message
        from repl_results
       where repl_order_ctrl = 'B'
             /* The below line is to pull back records that are being */
             /* sourced by suppliers and are therefore associated with */
             /* purchase orders. */
         and primary_repl_supplier is NOT NULL
         and source_type = NVL(I_source_type, source_type)
         and item = NVL(I_item, item)
         and dept = NVL(I_dept, dept)
         and class = NVL(I_class, class)
         and subclass = NVL(I_subclass, subclass)
         and (buyer = NVL(I_buyer, buyer)
              or I_buyer is NULL)
         and (repl_date <= I_before_date
              or I_before_date is NULL)
         and (repl_date >= I_after_date
              or I_after_date is NULL)
         and (((I_supp_type = 'S' or I_supp_type is NULL)
              and primary_repl_supplier = NVL(I_supplier, primary_repl_supplier))
              or (I_supp_type = 'P'
              and (pool_supplier = NVL(I_supplier, pool_supplier)
                   or I_supplier is NULL)))
         and origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and (((I_loc_type != 'PW' or I_loc_type is NULL)
              and location = NVL(I_location, location))
              or (I_loc_type = 'PW'
              and (physical_wh = NVL(I_location, physical_wh)
                   or I_location is NULL)))
         and ((I_incl_zero = 'N' and raw_roq > 0)
              or I_incl_zero = 'Y')
         and ((I_incl_non_due = 'N' and due_ind = 'Y')
              or I_incl_non_due = 'Y')
        and ((I_incl_po = 'Y' and status in ('W', 'P'))
              or (I_incl_po = 'N' and status = 'W'))
   UNION ALL
      select 'I',
             NULL source_type_desc,
             item,
             NULL item_desc,
             dept,
             NULL dept_name,
             class,
             NULL class_name,
             subclass,
             NULL subclass_name,
             buyer,
             NULL buyer_name,
             NULL diff_1,
             NULL diff_1_desc,
             NULL diff_2,
             NULL diff_2_desc,
             NULL diff_3,
             NULL diff_3_desc,
             NULL diff_4,
             NULL diff_4_desc,
             item_type,
             DECODE(item_type, 'P', comp_item, NULL) comp_item,
             NULL comp_item_desc,
             supplier,
             NULL sup_name,
             origin_country_id,
             pool_supplier,
             NULL pool_sup_name,
             loc_type,
             location,
             NULL loc_name,
             physical_wh,
             NULL phys_wh_name,
             future_cost - current_cost current_dscnt,
             roi,
             raw_roq,
             order_roq,
             NULL standard_uom,
             ti,
             hi,
             NULL terms,
             NULL terms_code,
             NVL(supp_lead_time, 0) + NVL(pickup_lead_time, 0) total_lead_time,
             supp_unit_cost,
             to_number(NULL) prim_supp_unit_cost,
             unit_cost,
             NULL currency_code,
             NULL prim_curr_code,
             create_date,
             days_to_event,
             next_event_date,
             target_date,
             status,
             to_number(NULL) tsf_po_link_no,
             to_char(audsid),
             rowidtochar(rowid),
             DECODE(L_order_by, 1, to_char(audsid), 2, item, 3, to_char(supplier), to_char(location)),
             NULL return_code,
             NULL error_message
        from ib_results
       where ib_order_ctrl = 'B'
         and source_type = NVL(I_source_type, source_type)
         and item = NVL(I_item, item)
         and dept = NVL(I_dept, dept)
         and class = NVL(I_class, class)
         and subclass = NVL(I_subclass, subclass)
         and (buyer = NVL(I_buyer, buyer)
              or I_buyer is NULL)
         and (create_date <= I_before_date
              or I_before_date is NULL)
         and (create_date >= I_after_date
              or I_after_date is NULL)
         and (((I_supp_type = 'S' or I_supp_type is NULL)
              and supplier = NVL(I_supplier, supplier))
              or (I_supp_type = 'P'
              and (pool_supplier = NVL(I_supplier, pool_supplier)
                   or I_supplier is NULL)))
         and origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and (((I_loc_type != 'PW' or I_loc_type is NULL)
              and location = NVL(I_location, location))
              or (I_loc_type = 'PW'
              and (physical_wh = NVL(I_location, physical_wh)
                   or I_location is NULL)))
         and ((I_incl_zero = 'N' and raw_roq > 0)
              or I_incl_zero = 'Y')
        and ((I_incl_po = 'Y' and status in ('W', 'P'))
              or (I_incl_po = 'N' and status = 'W'))
   UNION ALL
      select 'M',
             NULL source_type_desc,
             item,
             NULL item_desc,
             dept,
             NULL dept_name,
             class,
             NULL class_name,
             subclass,
             NULL subclass_name,
             buyer,
             NULL buyer_name,
             NULL diff_1,
             NULL diff_1_desc,
             NULL diff_2,
             NULL diff_2_desc,
             NULL diff_3,
             NULL diff_3_desc,
             NULL diff_4,
             NULL diff_4_desc,
             item_type,
             DECODE(item_type, 'P', comp_item, NULL) comp_item,
             NULL comp_item_desc,
             supplier,
             NULL sup_name,
             origin_country_id,
             pool_supplier,
             NULL pool_sup_name,
             loc_type,
             location,
             NULL loc_name,
             physical_wh,
             NULL phys_wh_name,
             to_number(NULL) current_dscnt,
             to_number(NULL) roi,
             0 raw_roq,
             order_roq,
             NULL standard_uom,
             ti,
             hi,
             NULL terms,
             NULL terms_code,
             NVL(supp_lead_time, 0) + NVL(pickup_lead_time, 0) total_lead_time,
             supp_unit_cost,
             to_number(NULL) prim_supp_unit_cost,
             unit_cost,
             NULL currency_code,
             NULL prim_curr_code,
             create_date,
             to_number(NULL) days_to_event,
             to_date(NULL) next_event_date,
             to_date(NULL) target_date,
             status,
             tsf_po_link_no,
             to_char(audsid),
             rowidtochar(rowid),
             DECODE(L_order_by, 1, to_char(audsid), 2, item, 3, to_char(supplier), to_char(location)),
             NULL return_code,
             NULL error_message
        from buyer_wksht_manual
       where source_type = NVL(I_source_type, source_type)
         and item = NVL(I_item, item)
         and dept = NVL(I_dept, dept)
         and class = NVL(I_class, class)
         and subclass = NVL(I_subclass, subclass)
         and (buyer = NVL(I_buyer, buyer)
              or I_buyer is NULL)
         and (create_date < I_before_date
              or I_before_date is NULL)
         and (create_date > I_after_date
              or I_after_date is NULL)
         and (((I_supp_type = 'S' or I_supp_type is NULL)
              and supplier = NVL(I_supplier, supplier))
              or (I_supp_type = 'P'
              and (pool_supplier = NVL(I_supplier, pool_supplier)
                   or I_supplier is NULL)))
         and origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and (((I_loc_type != 'PW' or I_loc_type is NULL)
              and location = NVL(I_location, location))
              or (I_loc_type = 'PW'
              and (physical_wh = NVL(I_location, physical_wh)
                   or I_location is NULL)))
        and ((I_incl_po = 'Y' and status in ('W', 'P'))
              or (I_incl_po = 'N' and status = 'W'))
      order by 57 DESC;  /* The order by number is associated with the 'DECODE(L_order_by...' */
                         /* clause in the select statement.  If columns are added or */
                         /* removed from the select statement this number must be updated */
                         /* to reflect the 'DECODE(L_order_by...' statement's position */
                         /* in the select statement. */

   cursor C_GET_ITEM_INFO is
      select diff_1,
             diff_2,
             diff_3,
             diff_4,
             standard_uom
        from item_master
       where item = L_item;

BEGIN

   if I_asc_desc = 'ASC' then
      L_loop_counter := 1;
      open C_ASC_QUERY;
      LOOP
         fetch C_ASC_QUERY into buyer_worksheet(L_loop_counter);
         Exit when C_ASC_QUERY%NOTFOUND;
         L_loop_counter := L_loop_counter + 1;
      END LOOP;
      close C_ASC_QUERY;
   else
      L_loop_counter := 1;
      open C_DESC_QUERY;
      LOOP
         fetch C_DESC_QUERY into buyer_worksheet(L_loop_counter);
         Exit when C_DESC_QUERY%NOTFOUND;
         L_loop_counter := L_loop_counter + 1;
      END LOOP;
      close C_DESC_QUERY;
   end if;

   if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(L_error_message,
                                       L_prim_curr_code) = FALSE then
      L_return_code := 'FALSE';
   end if;

   /* Populate post-query fields */
   FOR i in 1..buyer_worksheet.COUNT LOOP
      buyer_worksheet(i).return_code := 'TRUE';
      L_item := buyer_worksheet(i).item;

      buyer_worksheet(i).prim_curr_code := L_prim_curr_code;

      /*  All of the below functions will only be called if the previous value */
      /*  does not equal the current value.  */

      if (L_prev_source_type is NULL) or (L_prev_source_type != buyer_worksheet(i).source_type) then
         if LANGUAGE_SQL.GET_CODE_DESC(buyer_worksheet(i).error_message,
                                       'SRCT',
                                       buyer_worksheet(i).source_type,
                                       L_source_type_desc) = FALSE then
            buyer_worksheet(i).return_code := 'FALSE';
         end if;
         L_prev_source_type := buyer_worksheet(i).source_type;
      end if;
      buyer_worksheet(i).source_type_desc := L_source_type_desc;

      if (L_prev_item is NULL) or (L_prev_item != buyer_worksheet(i).item) then
         if ITEM_ATTRIB_SQL.GET_DESC(buyer_worksheet(i).error_message,
                                     L_item_desc,
                                     L_status,
                                     L_item_level,
                                     L_tran_level,
                                     buyer_worksheet(i).item) = FALSE then
            buyer_worksheet(i).return_code := 'FALSE';
         end if;

         open C_GET_ITEM_INFO;
         fetch C_GET_ITEM_INFO into L_diff_1,
                                    L_diff_2,
                                    L_diff_3,
                                    L_diff_4,
                                    L_standard_uom;
         close C_GET_ITEM_INFO;

         L_prev_item := buyer_worksheet(i).item;
      end if;
      buyer_worksheet(i).item_desc := L_item_desc;
      buyer_worksheet(i).diff_1 := L_diff_1;
      buyer_worksheet(i).diff_2 := L_diff_2;
      buyer_worksheet(i).diff_3 := L_diff_3;
      buyer_worksheet(i).diff_4 := L_diff_4;
      buyer_worksheet(i).standard_uom := L_standard_uom;

      if buyer_worksheet(i).diff_1 is NOT NULL then
         if (L_prev_diff_1 is NULL) or (L_prev_diff_1 != buyer_worksheet(i).diff_1) then
            if DIFF_SQL.GET_DIFF_INFO(buyer_worksheet(i).error_message,
                                      L_diff_1_desc,
                                      L_diff_type,
                                      L_id_group_ind,
                                      buyer_worksheet(i).diff_1) = FALSE then
               buyer_worksheet(i).return_code := 'FALSE';
            end if;
            L_prev_diff_1 := buyer_worksheet(i).diff_1;
         end if;
         buyer_worksheet(i).diff_1_desc := L_diff_1_desc;
      end if;

      if buyer_worksheet(i).diff_2 is NOT NULL then
         if (L_prev_diff_2 is NULL) or (L_prev_diff_2 != buyer_worksheet(i).diff_2) then
            if DIFF_SQL.GET_DIFF_INFO(buyer_worksheet(i).error_message,
                                      L_diff_2_desc,
                                      L_diff_type,
                                      L_id_group_ind,
                                      buyer_worksheet(i).diff_2) = FALSE then
               buyer_worksheet(i).return_code := 'FALSE';
            end if;
            L_prev_diff_2 := buyer_worksheet(i).diff_2;
         end if;
         buyer_worksheet(i).diff_2_desc := L_diff_2_desc;
      end if;

      if buyer_worksheet(i).diff_3 is NOT NULL then
         if (L_prev_diff_3 is NULL) or (L_prev_diff_3 != buyer_worksheet(i).diff_3) then
            if DIFF_SQL.GET_DIFF_INFO(buyer_worksheet(i).error_message,
                                      L_diff_3_desc,
                                      L_diff_type,
                                      L_id_group_ind,
                                      buyer_worksheet(i).diff_3) = FALSE then
               buyer_worksheet(i).return_code := 'FALSE';
            end if;
            L_prev_diff_3 := buyer_worksheet(i).diff_3;
         end if;
         buyer_worksheet(i).diff_3_desc := L_diff_3_desc;
      end if;

      if buyer_worksheet(i).diff_4 is NOT NULL then
         if (L_prev_diff_4 is NULL) or (L_prev_diff_4 != buyer_worksheet(i).diff_4) then
            if DIFF_SQL.GET_DIFF_INFO(buyer_worksheet(i).error_message,
                                      L_diff_4_desc,
                                      L_diff_type,
                                      L_id_group_ind,
                                      buyer_worksheet(i).diff_4) = FALSE then
               buyer_worksheet(i).return_code := 'FALSE';
            end if;
            L_prev_diff_4 := buyer_worksheet(i).diff_4;
         end if;
         buyer_worksheet(i).diff_4_desc := L_diff_4_desc;
      end if;

      if (L_prev_dept is NULL) or (L_prev_dept != buyer_worksheet(i).dept) then
         if DEPT_ATTRIB_SQL.GET_NAME(buyer_worksheet(i).error_message,
                                     buyer_worksheet(i).dept,
                                     L_dept_name) = FALSE then
            buyer_worksheet(i).return_code := 'FALSE';
         end if;
         L_prev_dept := buyer_worksheet(i).dept;
      end if;
      buyer_worksheet(i).dept_name := L_dept_name;

      if CLASS_ATTRIB_SQL.GET_NAME(buyer_worksheet(i).error_message,
                                   buyer_worksheet(i).dept,
                                   buyer_worksheet(i).class,
                                   buyer_worksheet(i).class_name) = FALSE then
         buyer_worksheet(i).return_code := 'FALSE';
      end if;

      if SUBCLASS_ATTRIB_SQL.GET_NAME(buyer_worksheet(i).error_message,
                                      buyer_worksheet(i).dept,
                                      buyer_worksheet(i).class,
                                      buyer_worksheet(i).subclass,
                                      buyer_worksheet(i).subclass_name) = FALSE then
         buyer_worksheet(i).return_code := 'FALSE';
      end if;

      if buyer_worksheet(i).buyer is NOT NULL then
         if (L_prev_buyer is NULL) or (L_prev_buyer != buyer_worksheet(i).buyer) then
            if BUYER_ATTRIB_SQL.GET_NAME(buyer_worksheet(i).buyer,
                                         L_buyer_name,
                                         buyer_worksheet(i).error_message) = FALSE then
               buyer_worksheet(i).return_code := 'FALSE';
            end if;
            L_prev_buyer := buyer_worksheet(i).buyer;
         end if;
         buyer_worksheet(i).buyer_name := L_buyer_name;
      end if;

      if buyer_worksheet(i).comp_item is NOT NULL then
         if (L_prev_comp_item is NULL) or (L_prev_comp_item != buyer_worksheet(i).comp_item) then
            if ITEM_ATTRIB_SQL.GET_DESC(buyer_worksheet(i).error_message,
                                        L_comp_item_desc,
                                        L_status,
                                        L_item_level,
                                        L_tran_level,
                                        buyer_worksheet(i).comp_item) = FALSE then
               buyer_worksheet(i).return_code := 'FALSE';
            end if;
            L_prev_comp_item := buyer_worksheet(i).comp_item;
         end if;
         buyer_worksheet(i).comp_item_desc := L_comp_item_desc;
      end if;

      if (L_prev_supplier is NULL) or (L_prev_supplier != buyer_worksheet(i).supplier) then
         if SUPP_ATTRIB_SQL.GET_SUPP_DESC(buyer_worksheet(i).error_message,
                                          buyer_worksheet(i).supplier,
                                          L_sup_name) = FALSE then
            buyer_worksheet(i).return_code := 'FALSE';
         end if;

         if SUPP_ATTRIB_SQL.ORDER_SUP_DETAILS(buyer_worksheet(i).error_message,
                                              L_currency_code,
                                              L_terms,
                                              L_freight_terms,
                                              L_sup_status,
                                              L_qc_ind,
                                              L_edi_po_ind,
                                              L_pre_mark_ind,
                                              L_ship_method,
                                              L_payment_method,
                                              buyer_worksheet(i).supplier) = FALSE then
            buyer_worksheet(i).return_code := 'FALSE';
         end if;

         if SUPP_ATTRIB_SQL.GET_PAYMENT_DESC(buyer_worksheet(i).error_message,
                                             L_currency_code,
                                             L_terms,
                                             L_freight_terms,
                                             L_curr_desc,
                                             L_terms_code,
                                             L_terms_desc,
                                             L_freight_terms_desc) = FALSE then
            buyer_worksheet(i).return_code := 'FALSE';
         end if;

         L_prev_supplier := buyer_worksheet(i).supplier;
      end if;
      buyer_worksheet(i).sup_name := L_sup_name;
      buyer_worksheet(i).currency_code := L_currency_code;
      buyer_worksheet(i).terms := L_terms;
      buyer_worksheet(i).terms_code := L_terms_code;

      if buyer_worksheet(i).currency_code != buyer_worksheet(i).prim_curr_code then
         if CURRENCY_SQL.CONVERT(buyer_worksheet(i).error_message,
                                 buyer_worksheet(i).supp_unit_cost,
                                 buyer_worksheet(i).currency_code,
                                 buyer_worksheet(i).prim_curr_code,
                                 buyer_worksheet(i).prim_supp_unit_cost,
                                 'C',
                                 NULL,
                                 NULL) = FALSE then
            buyer_worksheet(i).return_code := 'FALSE';
         end if;
      else
         buyer_worksheet(i).prim_supp_unit_cost := buyer_worksheet(i).supp_unit_cost;
      end if;

      if buyer_worksheet(i).pool_supplier is NOT NULL then
         if (L_prev_pool_supplier is NULL) or (L_prev_pool_supplier != buyer_worksheet(i).pool_supplier) then
            if SUPP_ATTRIB_SQL.GET_SUPP_DESC(buyer_worksheet(i).error_message,
                                             buyer_worksheet(i).pool_supplier,
                                             L_pool_sup_name) = FALSE then
               buyer_worksheet(i).return_code := 'FALSE';
            end if;
            L_prev_pool_supplier := buyer_worksheet(i).pool_supplier;
         end if;
         buyer_worksheet(i).pool_sup_name := L_pool_sup_name;
      end if;

      if (L_prev_location is NULL) or (L_prev_location != buyer_worksheet(i).location) then
         if LOCATION_ATTRIB_SQL.GET_NAME(buyer_worksheet(i).error_message,
                                         L_loc_name,
                                         buyer_worksheet(i).location,
                                         buyer_worksheet(i).loc_type) = FALSE then
            buyer_worksheet(i).return_code := 'FALSE';
         end if;
         L_prev_location := buyer_worksheet(i).location;
      end if;
      buyer_worksheet(i).loc_name := L_loc_name;

      if buyer_worksheet(i).physical_wh is NOT NULL then
         if (L_prev_physical_wh is NULL) or (L_prev_physical_wh != buyer_worksheet(i).physical_wh) then
            if WH_ATTRIB_SQL.GET_NAME(buyer_worksheet(i).error_message,
                                      buyer_worksheet(i).physical_wh,
                                      L_phys_wh_name) = FALSE then
               buyer_worksheet(i).return_code := 'FALSE';
            end if;
            L_prev_physical_wh := buyer_worksheet(i).physical_wh;
         end if;
         buyer_worksheet(i).phys_wh_name := L_phys_wh_name;
      end if;
   END LOOP;

END QUERY_PROCEDURE;
------------------------------------------------------------------------------
PROCEDURE LOCK_PROCEDURE (buyer_worksheet IN OUT buyer_wksht_tab)
IS
   L_exists   VARCHAR2(1);
BEGIN

   FOR i in 1..buyer_worksheet.COUNT LOOP
      if buyer_worksheet(i).source_type = 'R' then
         select 'x'
           into L_exists
           from repl_results
          where rowid = chartorowid(buyer_worksheet(i).row_id)
         for update nowait;
      elsif buyer_worksheet(i).source_type = 'I' then
         select 'x'
           into L_exists
           from ib_results
          where rowid = chartorowid(buyer_worksheet(i).row_id)
         for update nowait;
      else
         select 'x'
           into L_exists
           from buyer_wksht_manual
          where rowid = chartorowid(buyer_worksheet(i).row_id)
         for update nowait;
      end if;
   END LOOP;

END LOCK_PROCEDURE;
------------------------------------------------------------------------------
PROCEDURE UPDATE_PROCEDURE(buyer_worksheet IN OUT buyer_wksht_tab)
IS
BEGIN
   FOR i in 1..buyer_worksheet.COUNT LOOP
      if buyer_worksheet(i).source_type = 'R' then
         update repl_results
            set order_roq = buyer_worksheet(i).order_roq,
                unit_cost = buyer_worksheet(i).unit_cost,
                audsid = to_number(buyer_worksheet(i).audsid)
          where rowid = chartorowid(buyer_worksheet(i).row_id);
      elsif buyer_worksheet(i).source_type = 'I' then
         update ib_results
            set order_roq = buyer_worksheet(i).order_roq,
                unit_cost = buyer_worksheet(i).unit_cost,
                audsid = to_number(buyer_worksheet(i).audsid)
          where rowid = chartorowid(buyer_worksheet(i).row_id);
      else
         update buyer_wksht_manual
            set order_roq = buyer_worksheet(i).order_roq,
                unit_cost = buyer_worksheet(i).unit_cost,
                audsid = to_number(buyer_worksheet(i).audsid)
          where rowid = chartorowid(buyer_worksheet(i).row_id);
      end if;
   END LOOP;
null;
END UPDATE_PROCEDURE;
------------------------------------------------------------------------------
PROCEDURE DELETE_PROCEDURE(buyer_worksheet IN OUT buyer_wksht_tab)
IS
BEGIN
   FOR i in 1..buyer_worksheet.COUNT LOOP
      if buyer_worksheet(i).source_type = 'R' then
         update repl_results
            set status = 'D'
          where rowid = chartorowid(buyer_worksheet(i).row_id);
      elsif buyer_worksheet(i).source_type = 'I' then
         update ib_results
            set status = 'D'
          where rowid = chartorowid(buyer_worksheet(i).row_id);
      else
         delete from buyer_wksht_manual
               where rowid = chartorowid(buyer_worksheet(i).row_id);
      end if;
   END LOOP;

END DELETE_PROCEDURE;
------------------------------------------------------------------------------
PROCEDURE PO_QUERY_PROCEDURE (po_list               IN OUT   PO_LIST_TAB,
                              I_audsid              IN       REPL_RESULTS.AUDSID%TYPE,
                              I_order_no            IN       ORDHEAD.ORDER_NO%TYPE,
                              I_scale_cnstr_type1   IN       SUP_INV_MGMT.SCALE_CNSTR_TYPE1%TYPE,
                              I_scale_cnstr_uom1    IN       SUP_INV_MGMT.SCALE_CNSTR_UOM1%TYPE,
                              I_scale_cnstr_curr1   IN       SUP_INV_MGMT.SCALE_CNSTR_CURR1%TYPE,
                              I_scale_cnstr_type2   IN       SUP_INV_MGMT.SCALE_CNSTR_TYPE2%TYPE,
                              I_scale_cnstr_uom2    IN       SUP_INV_MGMT.SCALE_CNSTR_UOM2%TYPE,
                              I_scale_cnstr_curr2   IN       SUP_INV_MGMT.SCALE_CNSTR_CURR2%TYPE) is

   L_mult_supp_exists         BOOLEAN;
   L_supplier                 ORDHEAD.SUPPLIER%TYPE;
   L_mult_pool_supp_exists    BOOLEAN;
   L_pool_supplier            SUP_INV_MGMT.POOL_SUPPLIER%TYPE;
   L_mult_item_cntry_exists   BOOLEAN;
   L_mult_unit_cost_exists    BOOLEAN;
   L_mult_dept_exists         BOOLEAN;
   L_dept                     REPL_RESULTS.DEPT%TYPE;
   L_mult_loc_exists          BOOLEAN;
   L_location                 REPL_RESULTS.LOCATION%TYPE;
   L_loc_type                 REPL_RESULTS.LOC_TYPE%TYPE;
   L_vwh                      REPL_RESULTS.LOCATION%TYPE;
   L_mult_dept                VARCHAR2(1) := 'N';
   L_mult_loc                 VARCHAR2(1) := 'N';
   L_loop_counter             NUMBER;
   L_order_no                 ORDHEAD.ORDER_NO%TYPE;
   L_ord_dept                 ORDHEAD.DEPT%TYPE;
   L_error_message            RTK_ERRORS.RTK_TEXT%TYPE;
   L_return_code              VARCHAR2(10);
   L_exists                   VARCHAR2(1);
   L_valid                    VARCHAR2(1);
   L_item                     REPL_RESULTS.ITEM%TYPE;
   L_prepack_ord              BOOLEAN;
   L_diff_dept_exists         VARCHAR2(1);
   L_sup_name                 SUPS.SUP_NAME%TYPE;
   L_multiple_locs_exist      BOOLEAN;
   L_virtual_wh               WH.WH%TYPE;
   L_prev_location            ORDLOC.LOCATION%TYPE;
   L_loc_name                 WH.WH_NAME%TYPE;
   L_supp_prescale_cost       ORDLOC.UNIT_COST%TYPE;
   L_supp_ord_cost            ORDLOC.UNIT_COST%TYPE;
   L_prescale_cost            ORDLOC.UNIT_COST%TYPE;
   L_qty_prescaled_curr       ORDLOC.QTY_PRESCALED%TYPE;
   L_qty_ordered              NUMBER;
   L_supp_item_cost           ORDLOC.UNIT_COST%TYPE;
   L_ord_item_cost            ORDLOC.UNIT_COST%TYPE;
   L_qty_prescaled            NUMBER;
   L_currency_code            ORDHEAD.CURRENCY_CODE%TYPE;
   L_exchange_rate            ORDHEAD.EXCHANGE_RATE%TYPE;

   cursor C_PO_INFO is
      select distinct oh.order_no,
             oh.dept,
             oh.written_date,
             oh.supplier,
             NULL sup_name,
             oi.pool_supplier,
             NULL loc_type,
             NULL location,
             NULL loc_name,
             NULL first_order_total,
             NULL second_order_total,
             NULL return_code,
             NULL error_message
        from ordhead oh, ord_inv_mgmt oi
       where oh.order_no = oi.order_no
         and oh.order_no = I_order_no;

   cursor C_PO_QUERY is
      select distinct oh.order_no,
             oh.dept,
             oh.written_date,
             oh.supplier,
             NULL sup_name,
             oi.pool_supplier,
             NULL loc_type,
             NULL location,
             NULL loc_name,
             NULL first_order_total,
             NULL second_order_total,
             NULL return_code,
             NULL error_message
        from ordhead oh,
             ord_inv_mgmt oi
       where oh.order_no = oi.order_no
         and oh.status = 'W'
         and oh.supplier = L_supplier
         and oh.contract_no is NULL
         and (oh.dept is NULL
              or  (L_mult_dept = 'N' and oh.dept = L_dept))
         and (oh.location is NULL
              or  (L_mult_loc = 'N' and (oh.location = L_location or oh.location = L_vwh)))
     order by 1;

   cursor C_CHECK_PO_ITEM is
      select 'Y'
        from ordsku os
       where order_no = L_order_no
         and exists (select 'x'
                       from repl_results r
                      where r.repl_order_ctrl = 'B'
                        and r.status = 'W'
                        and r.audsid = I_audsid
                        and r.item = os.item
                        and r.origin_country_id != os.origin_country_id
                     UNION ALL
                     select 'x'
                       from ib_results i
                      where i.ib_order_ctrl = 'B'
                        and i.status = 'W'
                        and i.audsid = I_audsid
                        and i.item = os.item
                        and i.origin_country_id != os.origin_country_id
                     UNION ALL
                     select 'x'
                       from buyer_wksht_manual b
                      where b.status = 'W'
                        and b.audsid = I_audsid
                        and b.item = os.item
                        and b.origin_country_id != os.origin_country_id);

   cursor C_GET_ITEM is
      select r.item
        from repl_results r,
             item_master im
       where r.item = im.item
         and r.repl_order_ctrl = 'B'
         and r.status = 'W'
         and r.audsid = I_audsid
         and im.pack_ind = 'Y'
      UNION
      select i.item
        from ib_results i,
             item_master im
       where i.item = im.item
         and i.ib_order_ctrl = 'B'
         and i.status = 'W'
         and i.audsid = I_audsid
         and im.pack_ind = 'Y'
      UNION
      select b.item
        from buyer_wksht_manual b,
             item_master im
       where b.item = im.item
         and b.status = 'W'
         and b.audsid = I_audsid
         and im.pack_ind = 'Y';

   cursor C_CHECK_ITEM_DEPT is
      select 'Y'
        from v_packsku_qty vpq,
             item_master im
       where vpq.pack_no = L_item
         and vpq.item = im.item
         and im.dept != L_ord_dept;

BEGIN
   if I_order_no is NOT NULL then
      L_loop_counter := 1;
      open C_PO_INFO;
      LOOP
         fetch C_PO_INFO into po_list(L_loop_counter);
         Exit when C_PO_INFO%NOTFOUND;
         L_loop_counter := L_loop_counter + 1;
      END LOOP;
      close C_PO_INFO;
   else
     /* The query will select records that include the following criteria: */
     /* If line items with the same department are selected on the worksheet, orders */
     /* that are valid are those where the department is not specified or those that */
     /* have the selected department specified. */
     /* If line items with multiple departments are selected, orders that are valid are */
     /* those where the department is not specified.  */
     /* If multiple locations are selected on the worksheet, only orders that do not */
     /* have a location specified on ordhead are valid. */
     /* If the same location is selected, orders that have no location specified are */
     /* valid as well as orders that have that particular location specified on ordhead. */

      if BUYER_WKSHT_ATTRIB_SQL.CHECK_MULT_EXISTS(L_error_message,
                                                  L_mult_supp_exists,
                                                  L_supplier,
                                                  L_mult_pool_supp_exists,
                                                  L_pool_supplier,
                                                  L_mult_item_cntry_exists,
                                                  L_mult_unit_cost_exists,
                                                  L_mult_dept_exists,
                                                  L_dept,
                                                  L_mult_loc_exists,
                                                  L_location,
                                                  L_loc_type,
                                                  L_vwh,
                                                  'Y',   --- check for multiple suppliers
                                                  'N',   --- check for multiple pool suppliers
                                                  'N',   --- check for multiple item/countries
                                                  'N',   --- check for multiple item/loc/unit costs
                                                  'Y',   --- check for multiple departments
                                                  'Y',   --- check for multiple locations,
                                                  'N',   --- will not exit the function when multiple info is found
                                                  I_audsid) = FALSE then
         L_return_code := 'FALSE';
      end if;

      if L_mult_dept_exists = TRUE then
         L_mult_dept := 'Y';
      end if;

      if L_mult_loc_exists = TRUE then
         L_mult_loc := 'Y';
      end if;

      L_loop_counter := 1;
      FOR rec in C_PO_QUERY LOOP
         L_exists := 'N';
         L_valid := 'Y';
         L_order_no := rec.order_no;
         L_ord_dept := rec.dept;

         /* If an item that was selected exists on an order on the po list, the origin */
         /* country associated with the selected item must be the same as the origin */
         /* country on the order.  If not, the order is not added to the po_list table. */
         open C_CHECK_PO_ITEM;
         fetch C_CHECK_PO_ITEM into L_exists;
         close C_CHECK_PO_ITEM;

         /* Check if any of the worksheet items are packs.  If so, prepack orders are */
         /* not put on po_list. */
         /* Also, the packs' component items must be from the same department if the */
         /* order has a department specified.  Otherwise, the order is not put on po_list*/
         if L_exists = 'N' then
            open C_GET_ITEM;
            LOOP
               fetch C_GET_ITEM into L_item;
               Exit when C_GET_ITEM%NOTFOUND;

               if ORDER_ATTRIB_SQL.GET_PREPACK_IND(L_error_message,
                                                   L_prepack_ord,
                                                   L_order_no) = FALSE then
                  L_return_code := 'FALSE';
               end if;

               if L_prepack_ord = TRUE then
                  L_valid := 'N';
                  Exit;
               end if;

               if L_mult_dept_exists = FALSE then
                  L_diff_dept_exists := 'N';
                  open C_CHECK_ITEM_DEPT;
                  fetch C_CHECK_ITEM_DEPT into L_diff_dept_exists;
                  close C_CHECK_ITEM_DEPT;

                  if L_diff_dept_exists = 'Y' then
                     L_valid := 'N';
                     Exit;
                  end if;
               end if;
            END LOOP;
            close C_GET_ITEM;

            if L_valid = 'Y' then
               po_list(L_loop_counter).order_no := L_order_no;
               po_list(L_loop_counter).written_date := rec.written_date;
               po_list(L_loop_counter).supplier := rec.supplier;
               po_list(L_loop_counter).pool_supplier := rec.pool_supplier;
               L_loop_counter := L_loop_counter + 1;
            end if;
         end if;
      END LOOP;
   end if;

   /* Populate post-query fields */
   FOR i in 1..po_list.COUNT LOOP
      po_list(i).return_code := 'TRUE';
      L_order_no := po_list(i).order_no;
      L_location := NULL;

      if L_sup_name is NULL then
         if SUPP_ATTRIB_SQL.GET_SUPP_DESC(po_list(i).error_message,
                                          po_list(i).supplier,
                                          L_sup_name) = FALSE then
            po_list(i).return_code := 'FALSE';
         end if;
      end if;
      po_list(i).sup_name := L_sup_name;

      if ORDER_ATTRIB_SQL.MULTIPLE_LOCS_EXIST(po_list(i).error_message,
                                              L_location,
                                              po_list(i).loc_type,
                                              L_multiple_locs_exist,
                                              L_virtual_wh,
                                              po_list(i).order_no) = FALSE then
         po_list(i).return_code := 'FALSE';
      end if;

      if L_virtual_wh is NOT NULL then
         po_list(i).location := L_virtual_wh;
      elsif L_multiple_locs_exist = TRUE then
         if LANGUAGE_SQL.GET_CODE_DESC(po_list(i).error_message,
                                       'LABL',
                                       'MLOC',
                                       po_list(i).loc_name) = FALSE then
            po_list(i).return_code := 'FALSE';
         end if;
      else
         po_list(i).location := L_location;
      end if;

      if po_list(i).location is NOT NULL then
         if (L_prev_location is NULL) or (L_prev_location != po_list(i).location) then
            if LOCATION_ATTRIB_SQL.GET_NAME(po_list(i).error_message,
                                            L_loc_name,
                                            po_list(i).location,
                                            po_list(i).loc_type) = FALSE then
               po_list(i).return_code := 'FALSE';
            end if;
            L_prev_location := po_list(i).location;
         end if;
         po_list(i).loc_name := L_loc_name;
      end if;

      if I_scale_cnstr_type1 is NOT NULL then
         /* If the scaling constraint type is Amount */
         if I_scale_cnstr_type1 = 'A' then
            if ORDER_CALC_SQL.SUPPLIER_COST_UNITS(po_list(i).error_message,
                                                  L_supp_prescale_cost,
                                                  L_supp_ord_cost,
                                                  L_prescale_cost,
                                                  po_list(i).first_order_total,
                                                  L_qty_prescaled_curr,
                                                  L_qty_ordered,
                                                  L_supp_item_cost,
                                                  L_ord_item_cost,
                                                  po_list(i).order_no,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  po_list(i).supplier,
                                                  NULL,
                                                  NULL,
                                                  NULL) = FALSE then
               po_list(i).return_code := 'FALSE';
            end if;

            if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(po_list(i).error_message,
                                                  L_currency_code,
                                                  L_exchange_rate,
                                                  po_list(i).order_no) = FALSE then
               po_list(i).return_code := 'FALSE';
            end if;

            if L_currency_code != I_scale_cnstr_curr1 then
               if CURRENCY_SQL.CONVERT(po_list(i).error_message,
                                       po_list(i).first_order_total,
                                       L_currency_code,
                                       I_scale_cnstr_curr1,
                                       po_list(i).first_order_total,
                                       'C',
                                       NULL,
                                       NULL,
                                       L_exchange_rate,
                                       NULL) = FALSE then
                  po_list(i).return_code := 'FALSE';
               end if;
            end if;
         else /* All other scaling types */
            if ORD_INV_MGMT_SQL.CNSTR_ORD_QTYS(po_list(i).error_message,
                                               L_qty_prescaled,
                                               po_list(i).first_order_total,
                                               po_list(i).order_no,
                                               po_list(i).supplier,
                                               NULL,
                                               NULL,
                                               I_scale_cnstr_type1,
                                               I_scale_cnstr_uom1) = FALSE then
               po_list(i).return_code := 'FALSE';
            end if;
         end if;

         if po_list(i).first_order_total is NULL then
            po_list(i).first_order_total := 0;
         end if;

         if I_scale_cnstr_type2 is NOT NULL then
            /* If the scaling constraint type is Amount */
            if I_scale_cnstr_type2 = 'A' then
               if ORDER_CALC_SQL.SUPPLIER_COST_UNITS(po_list(i).error_message,
                                                     L_supp_prescale_cost,
                                                     L_supp_ord_cost,
                                                     L_prescale_cost,
                                                     po_list(i).second_order_total,
                                                     L_qty_prescaled_curr,
                                                     L_qty_ordered,
                                                     L_supp_item_cost,
                                                     L_ord_item_cost,
                                                     po_list(i).order_no,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     po_list(i).supplier,
                                                     NULL,
                                                     NULL,
                                                     NULL) = FALSE then
                  po_list(i).return_code := 'FALSE';
               end if;

               if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(po_list(i).error_message,
                                                     L_currency_code,
                                                     L_exchange_rate,
                                                     po_list(i).order_no) = FALSE then
                  po_list(i).return_code := 'FALSE';
               end if;

               if L_currency_code != I_scale_cnstr_curr2 then
                  if CURRENCY_SQL.CONVERT(po_list(i).error_message,
                                          po_list(i).second_order_total,
                                          L_currency_code,
                                          I_scale_cnstr_curr2,
                                          po_list(i).second_order_total,
                                          'C',
                                          NULL,
                                          NULL,
                                          L_exchange_rate,
                                          NULL) = FALSE then
                     po_list(i).return_code := 'FALSE';
                  end if;
               end if;
            else /* All other scaling types */
               if ORD_INV_MGMT_SQL.CNSTR_ORD_QTYS(po_list(i).error_message,
                                                  L_qty_prescaled,
                                                  po_list(i).second_order_total,
                                                  po_list(i).order_no,
                                                  po_list(i).supplier,
                                                  NULL,
                                                  NULL,
                                                  I_scale_cnstr_type2,
                                                  I_scale_cnstr_uom2) = FALSE then
                  po_list(i).return_code := 'FALSE';
               end if;
             end if;

            if po_list(i).second_order_total is NULL then
               po_list(i).second_order_total := 0;
            end if;
         end if;
      end if;
   END LOOP;

END PO_QUERY_PROCEDURE;
------------------------------------------------------------------------------
FUNCTION ADD_TO_PO(O_error_message   IN OUT   VARCHAR2,
                   I_order_no        IN       ORDHEAD.ORDER_NO%TYPE,
                   I_audsid          IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_elc_ind              SYSTEM_OPTIONS.ELC_IND%TYPE;
   L_latest_ship_days     SYSTEM_OPTIONS.LATEST_SHIP_DAYS%TYPE;
   L_multichannel_ind     SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;
   L_supplier             ORDHEAD.SUPPLIER%TYPE;
   L_ord_import_ind       ORDHEAD.IMPORT_ORDER_IND%TYPE;
   L_earliest_ship_date   ORDHEAD.EARLIEST_SHIP_DATE%TYPE;
   L_latest_ship_date     ORDHEAD.LATEST_SHIP_DATE%TYPE;
   L_ord_currency         ORDHEAD.CURRENCY_CODE%TYPE;
   L_ord_exchg_rate       ORDHEAD.EXCHANGE_RATE%TYPE;
   L_import_country_id    ORDHEAD.IMPORT_COUNTRY_ID%TYPE;
   L_pickup_loc           ORDHEAD.PICKUP_LOC%TYPE;
   L_pickup_no            ORDHEAD.PICKUP_NO%TYPE;
   L_supplier_currency    SUPS.CURRENCY_CODE%TYPE;
   L_recalc_hts           VARCHAR2(1) := 'N';
   L_item                 ITEM_MASTER.ITEM%TYPE;
   L_pack_ind             ITEM_MASTER.PACK_IND%TYPE;
   L_previous_item        ITEM_MASTER.ITEM%TYPE := -1;
   L_dummy                VARCHAR2(1);

   L_table                VARCHAR2(30);
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);

   cursor C_GET_INFO is
      select s.elc_ind,
             s.latest_ship_days,
             s.multichannel_ind,
             o.supplier,
             o.import_order_ind,
             o.earliest_ship_date,
             o.latest_ship_date,
             o.currency_code,
             o.exchange_rate,
             o.import_country_id,
             o.pickup_loc,
             o.pickup_no
        from system_options s,
             ordhead o
       where order_no = I_order_no;

   cursor C_GET_ITEM is
      select source_type,
             item,
             origin_country_id,
             NVL(supp_lead_time, 0) + NVL(pickup_lead_time, 0) total_lead_time,
             case_size,
             location,
             loc_type,
             item_type,
             order_roq,
             last_rounded_qty,
             last_grp_rounded_qty,
             unit_cost,
             supp_unit_cost,
             non_scaling_ind non_scale_ind,
             tsf_po_link_no
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION ALL
      select source_type,
             item,
             origin_country_id,
             NVL(supp_lead_time, 0) + NVL(pickup_lead_time, 0) total_lead_time,
             case_size,
             location,
             loc_type,
             item_type,
             order_roq,
             last_rounded_qty,
             last_grp_rounded_qty,
             unit_cost,
             supp_unit_cost,
             'Y' non_scale_ind,
             to_number(NULL) tsf_po_link_no
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION ALL
      select source_type,
             item,
             origin_country_id,
             NVL(supp_lead_time, 0) + NVL(pickup_lead_time, 0) total_lead_time,
             case_size,
             location,
             loc_type,
             item_type,
             order_roq,
             last_rounded_qty,
             last_grp_rounded_qty,
             unit_cost,
             supp_unit_cost,
             'N' non_scale_ind,
             tsf_po_link_no
        from buyer_wksht_manual
       where status = 'W'
         and audsid = I_audsid
      order by 2;

   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where audsid = I_audsid
         and status = 'W'
         and repl_order_ctrl = 'B'
         for update nowait;

   cursor C_LOCK_IB_RESULTS is
      select 'x'
        from ib_results
       where audsid = I_audsid
         and status = 'W'
         and ib_order_ctrl = 'B'
         for update nowait;

   cursor C_LOCK_BUYER_WKSHT_MANUAL is
      select 'x'
        from buyer_wksht_manual
       where audsid = I_audsid
         and status = 'W'
         for update nowait;

BEGIN
   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_order_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   open C_GET_INFO;
   fetch C_GET_INFO into L_elc_ind,
                         L_latest_ship_days,
                         L_multichannel_ind,
                         L_supplier,
                         L_ord_import_ind,
                         L_earliest_ship_date,
                         L_latest_ship_date,
                         L_ord_currency,
                         L_ord_exchg_rate,
                         L_import_country_id,
                         L_pickup_loc,
                         L_pickup_no;
   close C_GET_INFO;

   if CURRENCY_SQL.GET_CURR_LOC(O_error_message,
                                L_supplier,
                                'V',
                                NULL,
                                L_supplier_currency) = FALSE then
      return FALSE;
   end if;

   FOR rec in C_GET_ITEM LOOP
      L_item := rec.item;

      if rec.item_type = 'P' then
         L_pack_ind := 'Y';
      else
         L_pack_ind := 'N';
      end if;

      if ORDER_SETUP_SQL.ADD_ITEM_TO_PO(O_error_message,
                                        L_recalc_hts,
                                        I_order_no,
                                        L_elc_ind,
                                        L_latest_ship_days,
                                        L_multichannel_ind,
                                        L_ord_import_ind,
                                        L_earliest_ship_date,
                                        L_latest_ship_date,
                                        L_ord_currency,
                                        L_ord_exchg_rate,
                                        L_import_country_id,
                                        NULL,   --- I_contract_no
                                        NULL,   --- I_contract_currency
                                        L_pickup_loc,
                                        L_pickup_no,
                                        rec.item,
                                        /*rec.ref_item,*/ NULL,
                                        L_pack_ind,
                                        L_supplier,
                                        L_supplier_currency,
                                        rec.origin_country_id,
                                        rec.location,
                                        rec.loc_type,
                                        rec.case_size,
                                        rec.total_lead_time,
                                        rec.order_roq,
                                        rec.last_rounded_qty,
                                        rec.last_grp_rounded_qty,
                                        rec.unit_cost,
                                        rec.supp_unit_cost,
                                        rec.source_type,
                                        rec.non_scale_ind,
                                        rec.tsf_po_link_no,
                                        L_previous_item,
                                        NULL,   --- I_prev_pack_ind
                                        'BUYERWKSHT') = FALSE then
         return FALSE;
      end if;

      L_previous_item := L_item;
   END LOOP;

   /* Process the last item returned in the loop. */
   if L_recalc_hts = 'Y' then
      if ELC_CALC_SQL.CALC_COMP(O_error_message,
                                'PA',
                                L_item,
                                NULL,
                                NULL,
                                NULL,
                                I_order_no,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL) = FALSE then
         return FALSE;
      end if;

      if ELC_CALC_SQL.CALC_COMP(O_error_message,
                                'PE',
                                L_item,
                                NULL,
                                NULL,
                                NULL,
                                I_order_no,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL) = FALSE then
         return FALSE;
      end if;
   end if; -- end of L_recalc_hts = 'Y'

   if ORDER_SETUP_SQL.UPDATE_SHIP_DATES(O_error_message,
                                        I_order_no) = FALSE then
      return FALSE;
   end if;

   /* Set status to 'P'O - Processed on the three tables */
   L_table := 'REPL_RESULTS';
   open C_LOCK_REPL_RESULTS;
   fetch C_LOCK_REPL_RESULTS into L_dummy;
   ---
   if C_LOCK_REPL_RESULTS%FOUND then
      update repl_results
         set status = 'P'
       where audsid = I_audsid
         and status = 'W'
         and repl_order_ctrl = 'B';
   end if;
   ---
   close C_LOCK_REPL_RESULTS;

   L_table := 'IB_RESULTS';
   open C_LOCK_IB_RESULTS;
   fetch C_LOCK_IB_RESULTS into L_dummy;
   ---
   if C_LOCK_IB_RESULTS%FOUND then
      update ib_results
         set status = 'P'
       where audsid = I_audsid
         and status = 'W'
         and ib_order_ctrl = 'B';
   end if;
   ---
   close C_LOCK_IB_RESULTS;

   L_table := 'BUYER_WKSHT_MANUAL';
   open C_LOCK_BUYER_WKSHT_MANUAL;
   fetch C_LOCK_BUYER_WKSHT_MANUAL into L_dummy;
   ---
   if C_LOCK_BUYER_WKSHT_MANUAL%FOUND then
      update buyer_wksht_manual
         set status = 'P'
       where audsid = I_audsid
         and status = 'W';
   end if;
   ---
   close C_LOCK_BUYER_WKSHT_MANUAL;

   /* If there are any transfers linked to the line items just processed, */
   /* mark the transfer line items as processed. Set the transfer's freight */
   /* code to "Normal" if all of the transfer line items are processed. */
   if UPDATE_PO_TSF(O_error_message,
                    I_audsid) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_audsid),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.ADD_TO_PO',
                                            to_char(SQLCODE));
      return FALSE;
END ADD_TO_PO;
------------------------------------------------------------------------------
FUNCTION DELETE_REPL_RESULTS(O_error_message   IN OUT   VARCHAR2,
                             I_rowid           IN       ROWID)
   return BOOLEAN is

   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where rowid = I_rowid
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_REPL_RESULTS','REPL_RESULTS','ROWID: '||rowidtochar(I_rowid));
   open C_LOCK_REPL_RESULTS;
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_REPL_RESULTS','REPL_RESULTS','ROWID: '||rowidtochar(I_rowid));
   close C_LOCK_REPL_RESULTS;

   SQL_LIB.SET_MARK('UPDATE', NULL,'REPL_RESULTS','ROWID: '||rowidtochar(I_rowid));
   update repl_results
      set status = 'D'
    where rowid = I_rowid;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'REPL_RESULTS',
                                            rowidtochar(I_rowid),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.DELETE_REPL_RESULTS',
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_REPL_RESULTS;
------------------------------------------------------------------------------
FUNCTION DELETE_TSF_PO_LINK(O_error_message    IN OUT   VARCHAR2,
                            I_tsf_po_link_no   IN       REPL_RESULTS.TSF_PO_LINK_NO%TYPE,
                            I_rowid            IN       ROWID)
   return BOOLEAN is

   L_link_exists   VARCHAR2(1) := 'N';
   L_tsf_no        TSFDETAIL.TSF_NO%TYPE;
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LINK_EXISTS is
      select 'Y'
        from repl_results
       where tsf_po_link_no = I_tsf_po_link_no
         and repl_order_ctrl = 'B'
         and status != 'D'
         and rowid != I_rowid
      UNION ALL
      select 'x'
        from buyer_wksht_manual
       where tsf_po_link_no = I_tsf_po_link_no
         and rowid != I_rowid;

   cursor C_LINK_TSF_EXISTS is
      select tsf_no
        from tsfdetail
       where tsf_po_link_no = I_tsf_po_link_no
         and mbr_processed_ind = 'N'
         for update nowait;

BEGIN
   if I_tsf_po_link_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_tsf_po_link_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_rowid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_rowid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LINK_EXISTS', 'REPL_RESULTS, BUYER_WKSHT_MANUAL',
                    'TSF PO LINK: '||to_char(I_tsf_po_link_no));
   open C_LINK_EXISTS;

   SQL_LIB.SET_MARK('FETCH','C_LINK_EXISTS', 'REPL_RESULTS, BUYER_WKSHT_MANUAL',
                    'TSF PO LINK: '||to_char(I_tsf_po_link_no));
   fetch C_LINK_EXISTS into L_link_exists;

   SQL_LIB.SET_MARK('CLOSE','C_LINK_EXISTS', 'REPL_RESULTS, BUYER_WKSHT_MANUAL',
                    'TSF PO LINK: '||to_char(I_tsf_po_link_no));
   close C_LINK_EXISTS;

   if L_link_exists = 'N' then
      SQL_LIB.SET_MARK('OPEN','C_LINK_TSF_EXISTS', 'TSFDETAIL',
                       'TSF PO LINK: '||to_char(I_tsf_po_link_no));
      open C_LINK_TSF_EXISTS;

      LOOP
         SQL_LIB.SET_MARK('FETCH','C_LINK_TSF_EXISTS', 'TSFDETAIL',
                          'TSF PO LINK: '||to_char(I_tsf_po_link_no));
         fetch C_LINK_TSF_EXISTS into L_tsf_no;
         Exit when C_LINK_TSF_EXISTS%NOTFOUND;

         SQL_LIB.SET_MARK('UPDATE', NULL, 'TSFDETAIL',
                          'TSF PO LINK: '||to_char(I_tsf_po_link_no));
         update tsfdetail
            set tsf_po_link_no = NULL,
                mbr_processed_ind = 'Y'
          where tsf_no = L_tsf_no
            and tsf_po_link_no = I_tsf_po_link_no;

         if UPDATE_LINK_TSF(O_error_message,
                            L_tsf_no) = FALSE then
            return FALSE;
         end if;
      END LOOP;

      SQL_LIB.SET_MARK('CLOSE','C_LINK_TSF_EXISTS', 'TSFDETAIL',
                       'TSF PO LINK: '||to_char(I_tsf_po_link_no));
      close C_LINK_TSF_EXISTS;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'TSFDETAIL',
                                            to_char(I_tsf_po_link_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.DELETE_TSF_PO_LINK',
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_TSF_PO_LINK;
------------------------------------------------------------------------------
FUNCTION INSERT_MANUAL(O_error_message       IN OUT   VARCHAR2,
                       I_item                IN       BUYER_WKSHT_MANUAL.ITEM%TYPE,
                       I_supplier            IN       BUYER_WKSHT_MANUAL.SUPPLIER%TYPE,
                       I_origin_country_id   IN       BUYER_WKSHT_MANUAL.ORIGIN_COUNTRY_ID%TYPE,
                       I_loc_type            IN       BUYER_WKSHT_MANUAL.LOC_TYPE%TYPE,
                       I_location            IN       BUYER_WKSHT_MANUAL.LOCATION%TYPE,
                       I_aoq                 IN       BUYER_WKSHT_MANUAL.ORDER_ROQ%TYPE,
                       I_unit_cost           IN       BUYER_WKSHT_MANUAL.UNIT_COST%TYPE)
   return BOOLEAN is

   L_dept              ITEM_MASTER.DEPT%TYPE;
   L_class              ITEM_MASTER.CLASS%TYPE;
   L_subclass           ITEM_MASTER.CLASS%TYPE;
   L_item_type          BUYER_WKSHT_MANUAL.ITEM_TYPE%TYPE;
   L_comp_item          ITEM_MASTER.ITEM%TYPE;
   L_buyer              DEPS.BUYER%TYPE;
   L_pool_supplier      SUPS.SUPPLIER%TYPE;
   L_physical_wh        WH.WH%TYPE;
   L_repl_wh_link       WH.REPL_WH_LINK%TYPE;
   L_supp_lead_time     ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE;
   L_pickup_lead_time   ITEM_SUPP_COUNTRY_LOC.PICKUP_LEAD_TIME%TYPE;
   L_supp_unit_cost     ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE;
   L_supp_pack_size     ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE;
   L_ti                 ITEM_SUPP_COUNTRY.TI%TYPE;
   L_hi                 ITEM_SUPP_COUNTRY.HI%TYPE;
   L_create_date        DATE := GET_VDATE;

BEGIN
   if BUYER_WKSHT_ATTRIB_SQL.GET_BUYER_WKSHT_MANUAL_INFO(O_error_message,
                                                         L_dept,
                                                         L_class,
                                                         L_subclass,
                                                         L_item_type,
                                                         L_comp_item,
                                                         L_buyer,
                                                         L_pool_supplier,
                                                         L_physical_wh,
                                                         L_repl_wh_link,
                                                         L_supp_lead_time,
                                                         L_pickup_lead_time,
                                                         L_supp_unit_cost,
                                                         L_supp_pack_size,
                                                         L_ti,
                                                         L_hi,
                                                         I_item,
                                                         I_supplier,
                                                         I_origin_country_id,
                                                         I_loc_type,
                                                         I_location) = FALSE then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('INSERT',NULL,'BUYER_WKSHT_MANUAL','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id
                    ||', Location: '|| to_char(I_location));
   insert into buyer_wksht_manual(item,
                                  supplier,
                                  origin_country_id,
                                  location,
                                  loc_type,
                                  source_type,
                                  status,
                                  item_type,
                                  comp_item,
                                  dept,
                                  class,
                                  subclass,
                                  buyer,
                                  pool_supplier,
                                  physical_wh,
                                  repl_wh_link,
                                  supp_lead_time,
                                  pickup_lead_time,
                                  supp_unit_cost,
                                  unit_cost,
                                  order_roq,
                                  case_size,
                                  ti,
                                  hi,
                                  tsf_po_link_no,
                                  create_date,
                                  audsid)
      VALUES(I_item,
             I_supplier,
             I_origin_country_id,
             I_location,
             I_loc_type,
             'M',
             'W',
             L_item_type,
             L_comp_item,
             L_dept,
             L_class,
             L_subclass,
             L_buyer,
             L_pool_supplier,
             L_physical_wh,
             L_repl_wh_link,
             L_supp_lead_time,
             L_pickup_lead_time,
             L_supp_unit_cost,
             I_unit_cost,
             I_aoq,
             L_supp_pack_size,
             L_ti,
             L_hi,
             NULL,
             L_create_date,
             NULL);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.INSERT_MANUAL',
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_MANUAL;
------------------------------------------------------------------------------
FUNCTION REMOVE_ID(O_error_message   IN OUT   VARCHAR2,
                   I_audsid          IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_table         VARCHAR2(30);
   L_dummy         VARCHAR2(1);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where audsid = I_audsid
         and status = 'W'
         and repl_order_ctrl = 'B'
         for update nowait;

   cursor C_LOCK_IB_RESULTS is
      select 'x'
        from ib_results
       where audsid = I_audsid
         and status = 'W'
         and ib_order_ctrl = 'B'
         for update nowait;

   cursor C_LOCK_BUYER_WKSHT_MANUAL is
      select 'x'
        from buyer_wksht_manual
       where audsid = I_audsid
         and status = 'W'
         for update nowait;

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   L_table := 'REPL_RESULTS';

   SQL_LIB.SET_MARK('OPEN','C_LOCK_REPL_RESULTS','REPL_RESULTS','AUDSID: '||to_char(I_audsid));
   open C_LOCK_REPL_RESULTS;

   SQL_LIB.SET_MARK('FETCH','C_LOCK_REPL_RESULTS','REPL_RESULTS','AUDSID: '||to_char(I_audsid));
   fetch C_LOCK_REPL_RESULTS into L_dummy;

   if C_LOCK_REPL_RESULTS%FOUND then
      SQL_LIB.SET_MARK('UPDATE', NULL,'REPL_RESULTS','AUDSID: '||to_char(I_audsid));
      update repl_results
         set audsid = NULL
       where audsid = I_audsid
         and status = 'W'
         and repl_order_ctrl = 'B';
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_LOCK_REPL_RESULTS','REPL_RESULTS','AUDSID: '||to_char(I_audsid));
   close C_LOCK_REPL_RESULTS;

   L_table := 'IB_RESULTS';

   SQL_LIB.SET_MARK('OPEN','C_LOCK_IB_RESULTS','IB_RESULTS','AUDSID: '||to_char(I_audsid));
   open C_LOCK_IB_RESULTS;

   SQL_LIB.SET_MARK('FETCH','C_LOCK_IB_RESULTS','IB_RESULTS','AUDSID: '||to_char(I_audsid));
   fetch C_LOCK_IB_RESULTS into L_dummy;

   if C_LOCK_IB_RESULTS%FOUND then
      SQL_LIB.SET_MARK('UPDATE', NULL,'IB_RESULTS','AUDSID: '||to_char(I_audsid));
      update ib_results
         set audsid = NULL
       where audsid = I_audsid
         and status = 'W'
         and ib_order_ctrl = 'B';
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_LOCK_IB_RESULTS','IB_RESULTS','AUDSID: '||to_char(I_audsid));
   close C_LOCK_IB_RESULTS;


   L_table := 'BUYER_WKSHT_MANUAL';

   SQL_LIB.SET_MARK('OPEN','C_LOCK_BUYER_WKSHT_MANUAL','REPL_RESULTS','AUDSID: '||to_char(I_audsid));
   open C_LOCK_BUYER_WKSHT_MANUAL;

   SQL_LIB.SET_MARK('FETCH','C_LOCK_BUYER_WKSHT_MANUAL','REPL_RESULTS','AUDSID: '||to_char(I_audsid));
   fetch C_LOCK_BUYER_WKSHT_MANUAL into L_dummy;

   if C_LOCK_BUYER_WKSHT_MANUAL%FOUND then
      update buyer_wksht_manual
         set audsid = NULL
       where audsid = I_audsid
         and status = 'W';
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_LOCK_BUYER_WKSHT_MANUAL','REPL_RESULTS','AUDSID: '||to_char(I_audsid));
   close C_LOCK_BUYER_WKSHT_MANUAL;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_audsid),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.REMOVE_ID',
                                            to_char(SQLCODE));
      return FALSE;
END REMOVE_ID;
------------------------------------------------------------------------------
FUNCTION SELECT_ALL(O_error_message       IN OUT   VARCHAR,
                    I_audsid              IN       REPL_RESULTS.AUDSID%TYPE,
                    I_source_type         IN       REPL_RESULTS.SOURCE_TYPE%TYPE,
                    I_item                IN       REPL_RESULTS.ITEM%TYPE,
                    I_dept                IN       REPL_RESULTS.DEPT%TYPE,
                    I_class               IN       REPL_RESULTS.CLASS%TYPE,
                    I_subclass            IN       REPL_RESULTS.SUBCLASS%TYPE,
                    I_buyer               IN       REPL_RESULTS.BUYER%TYPE,
                    I_before_date         IN       DATE,
                    I_after_date          IN       DATE,
                    I_supp_type           IN       VARCHAR2,
                    I_supplier            IN       REPL_RESULTS.PRIMARY_REPL_SUPPLIER%TYPE,
                    I_origin_country_id   IN       REPL_RESULTS.ORIGIN_COUNTRY_ID%TYPE,
                    I_loc_type            IN       REPL_RESULTS.LOC_TYPE%TYPE,
                    I_location            IN       REPL_RESULTS.LOCATION%TYPE,
                    I_incl_zero           IN       VARCHAR2,
                    I_incl_non_due        IN       VARCHAR2,
                    I_incl_po             IN       VARCHAR2)
   return BOOLEAN is

   L_table         VARCHAR2(30);
   L_dummy         VARCHAR2(1);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
             /* The below line is to pull back records that are being */
             /* sourced by suppliers and are therefore associated with */
             /* purchase orders. */
         and primary_repl_supplier is NOT NULL
         and source_type = NVL(I_source_type, source_type)
         and item = NVL(I_item, item)
         and dept = NVL(I_dept, dept)
         and class = NVL(I_class, class)
         and subclass = NVL(I_subclass, subclass)
         and (buyer = NVL(I_buyer, buyer)
              or I_buyer is NULL)
         and (repl_date <= I_before_date
              or I_before_date is NULL)
         and (repl_date >= I_after_date
              or I_after_date is NULL)
         and (((I_supp_type = 'S' or I_supp_type is NULL)
              and primary_repl_supplier = NVL(I_supplier, primary_repl_supplier))
              or (I_supp_type = 'P'
              and (pool_supplier = NVL(I_supplier, pool_supplier)
                   or I_supplier is NULL)))
         and origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and (((I_loc_type != 'PW' or I_loc_type is NULL)
              and location = NVL(I_location, location))
              or (I_loc_type = 'PW'
              and (physical_wh = NVL(I_location, physical_wh)
                   or I_location is NULL)))
         and ((I_incl_zero = 'N' and raw_roq > 0)
              or I_incl_zero = 'Y')
         and ((I_incl_non_due = 'N' and due_ind = 'Y')
              or I_incl_non_due = 'Y')
         and ((I_incl_po = 'Y' and status in ('W', 'P'))
              or (I_incl_po = 'N' and status = 'W'))
         for update nowait;

   cursor C_LOCK_IB_RESULTS is
      select 'x'
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and source_type = NVL(I_source_type, source_type)
         and item = NVL(I_item, item)
         and dept = NVL(I_dept, dept)
         and class = NVL(I_class, class)
         and subclass = NVL(I_subclass, subclass)
         and (buyer = NVL(I_buyer, buyer)
              or I_buyer is NULL)
         and (create_date <= I_before_date
              or I_before_date is NULL)
         and (create_date >= I_after_date
              or I_after_date is NULL)
         and (((I_supp_type = 'S' or I_supp_type is NULL)
              and supplier = NVL(I_supplier, supplier))
              or (I_supp_type = 'P'
              and (pool_supplier = NVL(I_supplier, pool_supplier)
                   or I_supplier is NULL)))
         and origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and (((I_loc_type != 'PW' or I_loc_type is NULL)
              and location = NVL(I_location, location))
              or (I_loc_type = 'PW'
              and (physical_wh = NVL(I_location, physical_wh)
                   or I_location is NULL)))
         and ((I_incl_zero = 'N' and raw_roq > 0)
              or I_incl_zero = 'Y')
         and ((I_incl_po = 'Y' and status in ('W', 'P'))
              or (I_incl_po = 'N' and status = 'W'))
         for update nowait;

   cursor C_LOCK_BUYER_WKSHT is
      select 'x'
        from buyer_wksht_manual
       where status = 'W'
         and source_type = NVL(I_source_type, source_type)
         and item = NVL(I_item, item)
         and dept = NVL(I_dept, dept)
         and class = NVL(I_class, class)
         and subclass = NVL(I_subclass, subclass)
         and (buyer = NVL(I_buyer, buyer)
              or I_buyer is NULL)
         and (create_date <= I_before_date
              or I_before_date is NULL)
         and (create_date >= I_after_date
              or I_after_date is NULL)
         and (((I_supp_type = 'S' or I_supp_type is NULL)
              and supplier = NVL(I_supplier, supplier))
              or (I_supp_type = 'P'
              and (pool_supplier = NVL(I_supplier, pool_supplier)
                   or I_supplier is NULL)))
         and origin_country_id = NVL(I_origin_country_id, origin_country_id)
         and (((I_loc_type != 'PW' or I_loc_type is NULL)
              and location = NVL(I_location, location))
              or (I_loc_type = 'PW'
              and (physical_wh = NVL(I_location, physical_wh)
                   or I_location is NULL)))
         and ((I_incl_po = 'Y' and status in ('W', 'P'))
              or (I_incl_po = 'N' and status = 'W'))
         for update nowait;

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_source_type is NULL or I_source_type = 'R' then
      L_table := 'REPL_RESULTS';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_REPL_RESULTS','REPL_RESULTS', NULL);
      open C_LOCK_REPL_RESULTS;

      SQL_LIB.SET_MARK('FETCH','C_LOCK_REPL_RESULTS','REPL_RESULTS', NULL);
      fetch C_LOCK_REPL_RESULTS into L_dummy;

      if C_LOCK_REPL_RESULTS%FOUND then
         SQL_LIB.SET_MARK('UPDATE', NULL,'REPL_RESULTS', NULL);
         update repl_results
            set audsid = I_audsid
          where repl_order_ctrl = 'B'
            and status = 'W'
            and primary_repl_supplier is NOT NULL
            and item = NVL(I_item, item)
            and dept = NVL(I_dept, dept)
            and class = NVL(I_class, class)
            and subclass = NVL(I_subclass, subclass)
            and (buyer = NVL(I_buyer, buyer)
                 or I_buyer is NULL)
            and (repl_date <= I_before_date
                 or I_before_date is NULL)
            and (repl_date >= I_after_date
                 or I_after_date is NULL)
            and (((I_supp_type = 'S' or I_supp_type is NULL)
                 and primary_repl_supplier = NVL(I_supplier, primary_repl_supplier))
                 or (I_supp_type = 'P'
                 and (pool_supplier = NVL(I_supplier, pool_supplier)
                      or I_supplier is NULL)))
            and origin_country_id = NVL(I_origin_country_id, origin_country_id)
            and (((I_loc_type != 'PW' or I_loc_type is NULL)
                 and location = NVL(I_location, location))
                 or (I_loc_type = 'PW'
                 and (physical_wh = NVL(I_location, physical_wh)
                      or I_location is NULL)))
            and ((I_incl_zero = 'N' and raw_roq > 0)
                 or I_incl_zero = 'Y')
            and ((I_incl_non_due = 'N' and due_ind = 'Y')
                 or I_incl_non_due = 'Y')
            and ((I_incl_po = 'Y' and status in ('W', 'P'))
                 or (I_incl_po = 'N' and status = 'W'));
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_REPL_RESULTS','REPL_RESULTS', NULL);
      close C_LOCK_REPL_RESULTS;
   end if;

   if I_source_type is NULL or I_source_type = 'I' then
      L_table := 'IB_RESULTS';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_IB_RESULTS','IB_RESULTS', NULL);
      open C_LOCK_IB_RESULTS;

      SQL_LIB.SET_MARK('FETCH','C_LOCK_IB_RESULTS','IB_RESULTS', NULL);
      fetch C_LOCK_IB_RESULTS into L_dummy;

      if C_LOCK_IB_RESULTS%FOUND then
         SQL_LIB.SET_MARK('UPDATE', NULL,'IB_RESULTS', NULL);
         update ib_results
            set audsid = I_audsid
          where ib_order_ctrl = 'B'
            and status = 'W'
            and item = NVL(I_item, item)
            and dept = NVL(I_dept, dept)
            and class = NVL(I_class, class)
            and subclass = NVL(I_subclass, subclass)
            and (buyer = NVL(I_buyer, buyer)
                 or I_buyer is NULL)
            and (create_date <= I_before_date
                 or I_before_date is NULL)
            and (create_date >= I_after_date
                 or I_after_date is NULL)
            and (((I_supp_type = 'S' or I_supp_type is NULL)
                 and supplier = NVL(I_supplier, supplier))
                 or (I_supp_type = 'P'
                 and (pool_supplier = NVL(I_supplier, pool_supplier)
                      or I_supplier is NULL)))
            and origin_country_id = NVL(I_origin_country_id, origin_country_id)
            and (((I_loc_type != 'PW' or I_loc_type is NULL)
                 and location = NVL(I_location, location))
                 or (I_loc_type = 'PW'
                 and (physical_wh = NVL(I_location, physical_wh)
                      or I_location is NULL)))
            and ((I_incl_zero = 'N' and raw_roq > 0)
                 or I_incl_zero = 'Y')
            and ((I_incl_po = 'Y' and status in ('W', 'P'))
                 or (I_incl_po = 'N' and status = 'W'));
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_IB_RESULTS','IB_RESULTS', NULL);
      close C_LOCK_IB_RESULTS;
   end if;

   if I_source_type is NULL or I_source_type = 'M' then
      L_table := 'BUYER_WKSHT_MANUAL';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_BUYER_WKSHT','BUYER_WKSHT_MANUAL', NULL);
      open C_LOCK_BUYER_WKSHT;

      SQL_LIB.SET_MARK('FETCH','C_LOCK_BUYER_WKSHT','BUYER_WKSHT_MANUAL', NULL);
      fetch C_LOCK_BUYER_WKSHT into L_dummy;

      if C_LOCK_BUYER_WKSHT%FOUND then
         SQL_LIB.SET_MARK('UPDATE', NULL,'BUYER_WKSHT_MANUAL', NULL);
         update buyer_wksht_manual
            set audsid = I_audsid
          where status = 'W'
            and item = NVL(I_item, item)
            and dept = NVL(I_dept, dept)
            and class = NVL(I_class, class)
            and subclass = NVL(I_subclass, subclass)
            and (buyer = NVL(I_buyer, buyer)
                 or I_buyer is NULL)
            and (create_date <= I_before_date
                 or I_before_date is NULL)
            and (create_date >= I_after_date
                 or I_after_date is NULL)
            and (((I_supp_type = 'S' or I_supp_type is NULL)
                 and supplier = NVL(I_supplier, supplier))
                 or (I_supp_type = 'P'
                 and (pool_supplier = NVL(I_supplier, pool_supplier)
                      or I_supplier is NULL)))
            and origin_country_id = NVL(I_origin_country_id, origin_country_id)
            and (((I_loc_type != 'PW' or I_loc_type is NULL)
                 and location = NVL(I_location, location))
                 or (I_loc_type = 'PW'
                 and (physical_wh = NVL(I_location, physical_wh)
                      or I_location is NULL)))
            and ((I_incl_po = 'Y' and status in ('W', 'P'))
                 or (I_incl_po = 'N' and status = 'W'));
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_BUYER_WKSHT','BUYER_WKSHT_MANUAL', NULL);
      close C_LOCK_BUYER_WKSHT;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            NULL,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.SELECT_ALL',
                                            to_char(SQLCODE));
      return FALSE;
END SELECT_ALL;
------------------------------------------------------------------------------
FUNCTION UPDATE_AOQ_UNIT_COST(O_error_message       IN OUT   VARCHAR2,
                              I_source_type         IN       BUYER_WKSHT_MANUAL.SOURCE_TYPE%TYPE,
                              I_rowid               IN       ROWID,
                              I_order_roq           IN       BUYER_WKSHT_MANUAL.ORDER_ROQ%TYPE,
                              I_unit_cost           IN       BUYER_WKSHT_MANUAL.UNIT_COST%TYPE)
   return BOOLEAN is

   L_table         VARCHAR2(30);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where rowid = I_rowid
         for update nowait;

   cursor C_LOCK_BUYER_WKSHT_MANUAL is
      select 'x'
        from buyer_wksht_manual
       where rowid = I_rowid
         for update nowait;

BEGIN
   if I_rowid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_rowid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_source_type = 'R' then
      L_table := 'REPL_RESULTS';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_REPL_RESULTS', 'REPL_RESULTS', 'ROWID: '||rowidtochar(I_rowid));
      open C_LOCK_REPL_RESULTS;
      SQL_LIB.SET_MARK('FETCH','C_LOCK_REPL_RESULTS', 'REPL_RESULTS', 'ROWID: '||rowidtochar(I_rowid));
      close C_LOCK_REPL_RESULTS;

      SQL_LIB.SET_MARK('OPEN', NULL, 'REPL_RESULTS', 'ROWID: '||rowidtochar(I_rowid));
      update repl_results
         set order_roq = order_roq + I_order_roq,
             unit_cost = I_unit_cost
       where rowid = I_rowid;
   else
      L_table := 'BUYER_WKSHT_MANUAL';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_BUYER_WKSHT_MANUAL', 'BUYER_WKSHT_MANUAL', 'ROWID: '||rowidtochar(I_rowid));
      open C_LOCK_BUYER_WKSHT_MANUAL;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_BUYER_WKSHT_MANUAL', 'BUYER_WKSHT_MANUAL', 'ROWID: '||rowidtochar(I_rowid));
      close C_LOCK_BUYER_WKSHT_MANUAL;

      SQL_LIB.SET_MARK('OPEN', NULL, 'BUYER_WKSHT_MANUAL', 'ROWID: '||rowidtochar(I_rowid));
      update buyer_wksht_manual
         set order_roq = order_roq + I_order_roq,
             unit_cost = I_unit_cost
       where rowid = I_rowid;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            rowidtochar(I_rowid),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.UPDATE_AOQ_UNIT_COST',
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_AOQ_UNIT_COST;
------------------------------------------------------------------------------
FUNCTION UPDATE_LINK_TSF(O_error_message    IN OUT   VARCHAR2,
                         I_tsf_no           IN       TSFHEAD.TSF_NO%TYPE)
   return BOOLEAN is

   L_vdate         DATE := DATES_SQL.GET_VDATE();
   L_exists        BOOLEAN;
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_TSF is
      select 'x'
        from tsfhead
       where tsf_no = I_tsf_no
         for update nowait;

BEGIN
   if I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_tsf_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if BUYER_WKSHT_ATTRIB_SQL.NON_PROCESSED_EXISTS(O_error_message,
                                                  L_exists,
                                                  I_tsf_no) = FALSE then
      return FALSE;
   end if;

   if L_exists = FALSE then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_TSF', 'TSFHEAD', 'TSF NO: '||to_char(I_tsf_no));
      open C_LOCK_TSF;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_TSF', 'TSFHEAD', 'TSF NO: '||to_char(I_tsf_no));
      close C_LOCK_TSF;

      SQL_LIB.SET_MARK('UPDATE', NULL, 'TSFHEAD', 'TSF NO: '||to_char(I_tsf_no));
      update tsfhead
         set status = 'A',
             approval_id = user,
             approval_date = L_vdate
       where tsf_no = I_tsf_no;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'TSFHEAD',
                                            to_char(I_tsf_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.UPDATE_LINK_TSF',
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_LINK_TSF;
------------------------------------------------------------------------------
FUNCTION UPDATE_PO_TSF(O_error_message   IN OUT   VARCHAR2,
                       I_audsid          IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_tsf_no        TSFDETAIL.TSF_NO%TYPE;
   L_tsf_po_link   TSFDETAIL.TSF_PO_LINK_NO%TYPE;
   L_dummy         VARCHAR2(1);
   L_table         VARCHAR2(30);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_TSF_LINK is
      select td.tsf_no,
             td.tsf_po_link_no
        from tsfdetail td
       where td.mbr_processed_ind = 'N'
         and exists (select 'x'
                       from repl_results r1
                      where r1.tsf_po_link_no = td.tsf_po_link_no
                        and r1.audsid = I_audsid
                     UNION ALL
                     select 'x'
                       from buyer_wksht_manual b1
                      where b1.tsf_po_link_no = td.tsf_po_link_no
                        and b1.audsid = I_audsid)
        and not exists (select 'x'
                          from repl_results r2
                         where r2.tsf_po_link_no = td.tsf_po_link_no
                           and r2.status = 'W'
                        UNION ALL
                        select 'x'
                          from buyer_wksht_manual b2
                         where b2.tsf_po_link_no = td.tsf_po_link_no
                           and b2.status = 'W');

   cursor C_LOCK_TSFDETAIL is
      select 'x'
        from tsfdetail
       where tsf_no = L_tsf_no
         and tsf_po_link_no = L_tsf_po_link
         for update nowait;

   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where audsid = I_audsid;

   cursor C_LOCK_IB_RESULTS is
      select 'x'
        from ib_results
       where audsid = I_audsid;

   cursor C_LOCK_BUYER_WKSHT_MANUAL is
      select 'x'
        from buyer_wksht_manual
       where audsid = I_audsid;

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   open C_TSF_LINK;
   LOOP
      fetch C_TSF_LINK into L_tsf_no,
                            L_tsf_po_link;
      Exit when C_TSF_LINK%NOTFOUND;

      L_table := 'TSFDETAIL';
      open C_LOCK_TSFDETAIL;
      close C_LOCK_TSFDETAIL;

      update tsfdetail
         set mbr_processed_ind = 'Y'
       where tsf_no = L_tsf_no
         and tsf_po_link_no = L_tsf_po_link;

      if UPDATE_LINK_TSF(O_error_message,
                         L_tsf_no) = FALSE then
         return FALSE;
      end if;
   END LOOP;
   close C_TSF_LINK;

   /* Clear out the audsid field */
   L_table := 'REPL_RESULTS';
   open C_LOCK_REPL_RESULTS;
   fetch C_LOCK_REPL_RESULTS into L_dummy;
   ---
   if C_LOCK_REPL_RESULTS%FOUND then
      update repl_results
         set audsid = NULL
       where audsid = I_audsid;
   end if;
   ---
   close C_LOCK_REPL_RESULTS;

   L_table := 'IB_RESULTS';
   open C_LOCK_IB_RESULTS;
   fetch C_LOCK_IB_RESULTS into L_dummy;
   ---
   if C_LOCK_IB_RESULTS%FOUND then
      update ib_results
         set audsid = NULL
       where audsid = I_audsid;
   end if;
   ---
   close C_LOCK_IB_RESULTS;

   L_table := 'BUYER_WKSHT_MANUAL';
   open C_LOCK_BUYER_WKSHT_MANUAL;
   fetch C_LOCK_BUYER_WKSHT_MANUAL into L_dummy;
   ---
   if C_LOCK_BUYER_WKSHT_MANUAL%FOUND then
      update buyer_wksht_manual
         set audsid = NULL
       where audsid = I_audsid;
   end if;
   ---
   close C_LOCK_BUYER_WKSHT_MANUAL;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_audsid),
                                            to_char(L_tsf_no)||' ,'||to_char(L_tsf_po_link));
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.UPDATE_PO_TSF',
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_PO_TSF;
------------------------------------------------------------------------------
FUNCTION UPDATE_REPL_RESULTS(O_error_message   IN OUT   VARCHAR2,
                             I_rowid           IN       ROWID,
                             I_unit_cost       IN       REPL_RESULTS.UNIT_COST%TYPE,
                             I_aoq             IN       REPL_RESULTS.ORDER_ROQ%TYPE)
   return BOOLEAN is

   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where rowid = I_rowid
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_REPL_RESULTS','REPL_RESULTS','ROWID: '||rowidtochar(I_rowid));
   open C_LOCK_REPL_RESULTS;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_REPL_RESULTS','REPL_RESULTS','ROWID: '||rowidtochar(I_rowid));
   close C_LOCK_REPL_RESULTS;

   SQL_LIB.SET_MARK('UPDATE', NULL,'REPL_RESULTS','ROWID: '||rowidtochar(I_rowid));
   update repl_results
      set unit_cost = I_unit_cost,
          order_roq = I_aoq
    where rowid = I_rowid;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'REPL_RESULTS',
                                            rowidtochar(I_rowid),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.UPDATE_REPL_RESULTS',
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_REPL_RESULTS;
------------------------------------------------------------------------------
END BUYER_WORKSHEET_SQL;
/

