CREATE OR REPLACE PACKAGE BODY CE_ALLOC_SQL AS
-------------------------------------------------------------------------------
   LP_vdate              DATE                          := GET_VDATE;
   LP_counter            NUMBER                        := 0;
-------------------------------------------------------------------------------
FUNCTION ALLOC_PO(O_error_message         IN OUT VARCHAR2,
                  I_obligation_key        IN     OBLIGATION.OBLIGATION_KEY%TYPE,
                  I_obligation_level      IN     OBLIGATION.OBLIGATION_LEVEL%TYPE,
                  I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                  I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                  I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                  I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                  I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                  I_comp_id               IN     ELC_COMP.COMP_ID%TYPE,
                  I_alloc_basis_uom       IN     UOM_CLASS.UOM%TYPE,
                  I_qty                   IN     OBLIGATION_COMP.QTY%TYPE,
                  I_amt_prim              IN     OBLIGATION_COMP.AMT%TYPE)
   RETURN BOOLEAN IS

   L_exists                 BOOLEAN;
   L_program                VARCHAR2(64)                := 'CE_ALLOC_SQL.ALLOC_PO';
   L_obl_locs_exist         VARCHAR2(1)                 := 'N';
   L_item_ord_qty           ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_item_rec_qty           ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_temp_rec_qty           ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_pack_rec_qty           ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_comp_rec_qty           ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_comp_qty               ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_total_rec_qty          ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_rec_qty                ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_qty                    ALC_COMP_LOC.QTY%TYPE       := 0;
   L_item_qty               ALC_COMP_LOC.QTY%TYPE       := 0;
   L_loc_qty                ALC_COMP_LOC.QTY%TYPE       := 0;
   L_act_value              ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_amt_prim               ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_amt                    ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_total_rec_cost         ORDLOC.UNIT_COST%TYPE       := 0;
   L_unit_cost              ORDLOC.UNIT_COST%TYPE       := 0;
   L_total_comp_qty         ORDLOC.QTY_ORDERED%TYPE;
   L_order_no               ORDHEAD.ORDER_NO%TYPE;
   L_pack_ind               ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind           ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind          ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type              ITEM_MASTER.PACK_TYPE%TYPE;
   L_item                   ITEM_MASTER.ITEM%TYPE;
   L_comp_item              ITEM_MASTER.ITEM%TYPE;
   L_pack_item              ITEM_MASTER.ITEM%TYPE;
   L_location               ORDLOC.LOCATION%TYPE;
   L_supplier               SUPS.SUPPLIER%TYPE;
   L_origin_country_id      COUNTRY.COUNTRY_ID%TYPE;
   L_temp_qty               ALC_HEAD.ALC_QTY%TYPE;
   L_standard_uom           UOM_CLASS.UOM%TYPE;
   L_carton_qty             TRANSPORTATION.CARTON_QTY%TYPE;
   L_carton_uom             TRANSPORTATION.CARTON_UOM%TYPE;
   L_cleared_qty            CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_cleared_qty_uom        CE_ORD_ITEM.CLEARED_QTY_UOM%TYPE;
   L_manifest_item_qty      TRANSPORTATION.ITEM_QTY%TYPE;
   L_manifest_item_qty_uom  TRANSPORTATION.ITEM_QTY_UOM%TYPE;
   L_gross_wt               TRANSPORTATION.GROSS_WT%TYPE;
   L_gross_wt_uom           TRANSPORTATION.GROSS_WT_UOM%TYPE;
   L_net_wt                 TRANSPORTATION.NET_WT%TYPE;
   L_net_wt_uom             TRANSPORTATION.NET_WT_UOM%TYPE;
   L_cubic                  TRANSPORTATION.CUBIC%TYPE;
   L_cubic_uom              TRANSPORTATION.CUBIC_UOM%TYPE;
   L_uom                    UOM_CLASS.UOM%TYPE          := I_alloc_basis_uom;
   L_standard_class         UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor            UOM_CONVERSION.FACTOR%TYPE;
   L_qty_uom                UOM_CLASS.UOM%TYPE;

   cursor C_GET_ITEMS is
      select distinct c.item,
             s.origin_country_id,
             o.supplier,
             c.manifest_item_qty,
             c.manifest_item_qty_uom,
             c.carton_qty,
             c.carton_qty_uom,
             c.gross_wt,
             c.gross_wt_uom,
             c.net_wt,
             c.net_wt_uom,
             c.cubic,
             c.cubic_uom,
             c.cleared_qty,
             c.cleared_qty_uom
        from ordsku s,
             ordhead o,
             ce_ord_item c
       where o.order_no              = I_order_no
         and o.order_no              = s.order_no
         and c.order_no              = o.order_no
         and c.item                  = s.item
         and c.ce_id                 = I_ce_id
         and c.vessel_id             = I_vessel_id
         and c.voyage_flt_id         = I_voyage_flt_id
         and c.estimated_depart_date = I_estimated_depart_date;

   cursor C_GET_PACKITEMS is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from alc_head
       where order_no       = I_order_no
         and obligation_key = I_obligation_key
         for update nowait;

   cursor C_GET_QTY_UOM is
      select per_count_uom
        from obligation_comp
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

BEGIN
   if I_alloc_basis_uom is not NULL then
      ---
      -- Loop through the items on transportation and sum the total qty received in the alloc basis uom.
      ---
      FOR C_rec in C_GET_ITEMS LOOP
         L_item                  := C_rec.item;
         L_origin_country_id     := C_rec.origin_country_id;
         L_supplier              := C_rec.supplier;
         L_manifest_item_qty     := C_rec.manifest_item_qty;
         L_manifest_item_qty_uom := C_rec.manifest_item_qty_uom;
         L_cleared_qty           := C_rec.cleared_qty;
         L_cleared_qty_uom       := C_rec.cleared_qty_uom;
         L_carton_qty            := C_rec.carton_qty;
         L_carton_uom            := C_rec.carton_qty_uom;
         L_gross_wt              := C_rec.gross_wt;
         L_gross_wt_uom          := C_rec.gross_wt_uom;
         L_cubic                 := C_rec.cubic;
         L_cubic_uom             := C_rec.cubic_uom;
         L_net_wt                := C_rec.net_wt;
         L_net_wt_uom            := C_rec.net_wt_uom;
         L_item_rec_qty          := 0;
         L_pack_rec_qty          := 0;
         ---
         if L_manifest_item_qty > 0 then
            L_qty     := L_manifest_item_qty;
            L_qty_uom := L_manifest_item_qty_uom;
         elsif L_cleared_qty > 0 then
            L_qty     := L_cleared_qty;
            L_qty_uom := L_cleared_qty_uom;
         elsif L_carton_qty > 0 then
            L_qty     := L_carton_qty;
            L_qty_uom := L_carton_uom;
         elsif L_gross_wt > 0 then
            L_qty     := L_gross_wt;
            L_qty_uom := L_gross_wt_uom;
         elsif L_cubic > 0 then
            L_qty     := L_cubic;
            L_qty_uom := L_cubic_uom;
         elsif L_net_wt > 0 then
            L_qty     := L_net_wt;
            L_qty_uom := L_net_wt_uom;
         else
            L_qty := 0;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS (O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then
            if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                            L_qty,
                                            L_item,
                                            L_qty,
                                            L_qty_uom,
                                            L_supplier,
                                            L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            FOR C_rec in C_GET_PACKITEMS LOOP
               L_comp_item := C_rec.item;
               L_comp_qty  := C_rec.qty;
               ---

               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_comp_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_comp_qty,
                                  I_alloc_basis_uom,
                                  L_comp_qty,
                                  L_standard_uom,
                                  L_comp_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               L_pack_rec_qty := L_pack_rec_qty + (L_qty * L_comp_qty);
            END LOOP;
         else
            if L_qty <> 0 then
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  L_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
         ---
         L_total_rec_qty := L_total_rec_qty + L_item_rec_qty + L_pack_rec_qty;
      END LOOP;
      -- loop through items on transportation
      FOR C_rec in C_GET_ITEMS LOOP
         L_item                  := C_rec.item;
         L_origin_country_id     := C_rec.origin_country_id;
         L_supplier              := C_rec.supplier;
         L_item_rec_qty          := 0;
         L_manifest_item_qty     := C_rec.manifest_item_qty;
         L_manifest_item_qty_uom := C_rec.manifest_item_qty_uom;
         L_cleared_qty           := C_rec.cleared_qty;
         L_cleared_qty_uom       := C_rec.cleared_qty_uom;
         L_carton_qty            := C_rec.carton_qty;
         L_carton_uom            := C_rec.carton_qty_uom;
         L_gross_wt              := C_rec.gross_wt;
         L_gross_wt_uom          := C_rec.gross_wt_uom;
         L_cubic                 := C_rec.cubic;
         L_cubic_uom             := C_rec.cubic_uom;
         L_net_wt                := C_rec.net_wt;
         L_net_wt_uom            := C_rec.net_wt_uom;
         ---
         if L_manifest_item_qty > 0 then
            L_qty     := L_manifest_item_qty;
            L_qty_uom := L_manifest_item_qty_uom;
         elsif L_cleared_qty > 0 then
            L_qty     := L_cleared_qty;
            L_qty_uom := L_cleared_qty_uom;
         elsif L_carton_qty > 0 then
            L_qty     := L_carton_qty;
            L_qty_uom := L_carton_uom;
         elsif L_gross_wt > 0 then
            L_qty     := L_gross_wt;
            L_qty_uom := L_gross_wt_uom;
         elsif L_cubic > 0 then
            L_qty     := L_cubic;
            L_qty_uom := L_cubic_uom;
         elsif L_net_wt > 0 then
            L_qty     := L_net_wt;
            L_qty_uom := L_net_wt_uom;
         else
            L_qty := 0;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS (O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then
            if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                            L_qty,
                                            L_item,
                                            L_qty,
                                            L_qty_uom,
                                            L_supplier,
                                            L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            FOR C_rec in C_GET_PACKITEMS LOOP
               L_comp_item := C_rec.item;
               L_comp_qty  := C_rec.qty;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_comp_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_comp_qty,
                                  I_alloc_basis_uom,
                                  L_comp_qty,
                                  L_standard_uom,
                                  L_comp_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               L_item_rec_qty := L_item_rec_qty + (L_qty * L_comp_qty);
            END LOOP;
         else
            if L_qty <> 0 then
               if UOM_SQL.CONVERT(O_error_message,
                                  L_rec_qty,
                                  L_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            L_item_rec_qty := L_rec_qty;
         end if;
         ---
         if L_total_rec_qty <> 0 then
            -- take qty * expense amt / total qty
            L_act_value := L_item_rec_qty * I_amt_prim / L_total_rec_qty;
            L_qty       := L_item_rec_qty * I_qty      / L_total_rec_qty;
         else
            L_act_value := 0;
            L_qty       := 0;
         end if;
         ---
         if TRAN_ALLOC_SQL.ALLOC_PO_ITEM(O_error_message,
                                         I_obligation_key,
                                         I_obligation_level,
                                         I_vessel_id,
                                         I_voyage_flt_id,
                                         I_estimated_depart_date,
                                         I_order_no,
                                         L_item,
                                         I_comp_id,
                                         I_alloc_basis_uom,
                                         L_qty,
                                         L_act_value) = FALSE then
             return FALSE;
         end if;
      END LOOP;
   else    -- L_alloc_basis_uom is NULL
      SQL_LIB.SET_MARK('OPEN','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                ' Component: '||I_comp_id);
      open C_GET_QTY_UOM;
      SQL_LIB.SET_MARK('FETCH','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                 ' Component: '||I_comp_id);
      fetch C_GET_QTY_UOM into L_uom;
      SQL_LIB.SET_MARK('CLOSE','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                 ' Component: '||I_comp_id);
      close C_GET_QTY_UOM;
      ---
      L_total_rec_cost := 0;
      L_total_rec_qty  := 0;
      ---
      -- I_alloc_basis_uom is NULL therefore allocate across monetary value.
      -- open cursor that sums the unit cost of each item on ordloc
      -- loop through items on ordloc and take unit cost * the expense amount / total cost.
      ---
      FOR C_rec in C_GET_ITEMS LOOP
         L_item                  := C_rec.item;
         L_supplier              := C_rec.supplier;
         L_origin_country_id     := C_rec.origin_country_id;
         L_item_qty              := 0;
         L_manifest_item_qty     := C_rec.manifest_item_qty;
         L_manifest_item_qty_uom := C_rec.manifest_item_qty_uom;
         L_cleared_qty           := C_rec.cleared_qty;
         L_cleared_qty_uom       := C_rec.cleared_qty_uom;
         L_carton_qty            := C_rec.carton_qty;
         L_carton_uom            := C_rec.carton_qty_uom;
         L_gross_wt              := C_rec.gross_wt;
         L_gross_wt_uom          := C_rec.gross_wt_uom;
         L_cubic                 := C_rec.cubic;
         L_cubic_uom             := C_rec.cubic_uom;
         L_net_wt                := C_rec.net_wt;
         L_net_wt_uom            := C_rec.net_wt_uom;
         ---
         if L_manifest_item_qty > 0 then
            L_qty     := L_manifest_item_qty;
            L_qty_uom := L_manifest_item_qty_uom;
         elsif L_cleared_qty > 0 then
            L_qty     := L_cleared_qty;
            L_qty_uom := L_cleared_qty_uom;
         elsif L_carton_qty > 0 then
            L_qty     := L_carton_qty;
            L_qty_uom := L_carton_uom;
         elsif L_gross_wt > 0 then
            L_qty     := L_gross_wt;
            L_qty_uom := L_gross_wt_uom;
         elsif L_cubic > 0 then
            L_qty     := L_cubic;
            L_qty_uom := L_cubic_uom;
         elsif L_net_wt > 0 then
            L_qty     := L_net_wt;
            L_qty_uom := L_net_wt_uom;
         else
            L_qty := 0;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS (O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then

            L_item_rec_qty := 0;
            ---
            if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                            L_qty,
                                            L_item,
                                            L_qty,
                                            L_qty_uom,
                                            L_supplier,
                                            L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            FOR C_rec in C_GET_PACKITEMS LOOP
               L_comp_item    := C_rec.item;
               L_comp_rec_qty := C_rec.qty;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_comp_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_comp_rec_qty,
                                  L_uom,
                                  L_comp_rec_qty,
                                  L_standard_uom,
                                  L_comp_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_qty);
            END LOOP;
         else
            if L_qty <> 0 then
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  L_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_qty,
                                  L_standard_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                      L_exists,
                                                      L_unit_cost,
                                                      I_order_no,
                                                      L_item,
                                                      L_pack_item,
                                                      L_location) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
         ---
         L_total_rec_cost := L_total_rec_cost + (L_qty * L_unit_cost);
         L_total_rec_qty  := L_total_rec_qty  +  L_item_rec_qty;

      END LOOP;
      ---
      L_item_rec_qty := 0;
      ---
      FOR C_rec in C_GET_ITEMS LOOP
         L_item                  := C_rec.item;
         L_supplier              := C_rec.supplier;
         L_origin_country_id     := C_rec.origin_country_id;
         L_item_qty              := 0;
         L_manifest_item_qty     := C_rec.manifest_item_qty;
         L_manifest_item_qty_uom := C_rec.manifest_item_qty_uom;
         L_cleared_qty           := C_rec.cleared_qty;
         L_cleared_qty_uom       := C_rec.cleared_qty_uom;
         L_carton_qty            := C_rec.carton_qty;
         L_carton_uom            := C_rec.carton_qty_uom;
         L_gross_wt              := C_rec.gross_wt;
         L_gross_wt_uom          := C_rec.gross_wt_uom;
         L_cubic                 := C_rec.cubic;
         L_cubic_uom             := C_rec.cubic_uom;
         L_net_wt                := C_rec.net_wt;
         L_net_wt_uom            := C_rec.net_wt_uom;
         ---
         if L_manifest_item_qty > 0 then
            L_qty     := L_manifest_item_qty;
            L_qty_uom := L_manifest_item_qty_uom;
         elsif L_cleared_qty > 0 then
            L_qty     := L_cleared_qty;
            L_qty_uom := L_cleared_qty_uom;
         elsif L_carton_qty > 0 then
            L_qty     := L_carton_qty;
            L_qty_uom := L_carton_uom;
         elsif L_gross_wt > 0 then
            L_qty     := L_gross_wt;
            L_qty_uom := L_gross_wt_uom;
         elsif L_cubic > 0 then
            L_qty     := L_cubic;
            L_qty_uom := L_cubic_uom;
         elsif L_net_wt > 0 then
            L_qty     := L_net_wt;
            L_qty_uom := L_net_wt_uom;
         else
            L_qty := 0;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS (O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then

            L_item_rec_qty := 0;
            ---
            if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                            L_qty,
                                            L_item,
                                            L_qty,
                                            L_qty_uom,
                                            L_supplier,
                                            L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            FOR C_rec in C_GET_PACKITEMS LOOP
               L_comp_item    := C_rec.item;
               L_comp_rec_qty := C_rec.qty;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_comp_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_comp_rec_qty,
                                  L_uom,
                                  L_comp_rec_qty,
                                  L_standard_uom,
                                  L_comp_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_qty);
            END LOOP;
         else
            if L_qty <> 0 then
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  L_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_qty,
                                  L_standard_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
         ---
         if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                L_exists,
                                                L_unit_cost,
                                                I_order_no,
                                                L_item,
                                                L_pack_item,
                                                L_location) = FALSE then
            return FALSE;
         end if;
         ---
         if L_total_rec_cost = 0 or L_total_rec_qty = 0 then
            L_amt_prim := 0;
            L_qty      := 0;
         else
            -- calculate: expense amt * (qty / total qty) and qty * (qty / total qty)
            L_amt_prim := I_amt_prim * ((L_qty * L_unit_cost) / L_total_rec_cost);
            L_qty      := I_qty      *  (L_item_rec_qty       / L_total_rec_qty);
         end if;
         ---
         if TRAN_ALLOC_SQL.ALLOC_PO_ITEM(O_error_message,
                                         I_obligation_key,
                                         I_obligation_level,
                                         I_vessel_id,
                                         I_voyage_flt_id,
                                         I_estimated_depart_date,
                                         I_order_no,
                                         L_item,
                                         I_comp_id,
                                         NULL,
                                         L_qty,
                                         L_amt_prim) = FALSE then
            return FALSE;
         end if;
      END LOOP;
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
END ALLOC_PO;
-------------------------------------------------------------------------------
FUNCTION ALLOC_VVE(O_error_message         IN OUT VARCHAR2,
                   I_obligation_key        IN     OBLIGATION.OBLIGATION_KEY%TYPE,
                   I_obligation_level      IN     OBLIGATION.OBLIGATION_LEVEL%TYPE,
                   I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                   I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                   I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                   I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                   I_comp_id               IN     ELC_COMP.COMP_ID%TYPE,
                   I_alloc_basis_uom       IN     UOM_CLASS.UOM%TYPE,
                   I_qty                   IN     OBLIGATION_COMP.QTY%TYPE,
                   I_amt_prim              IN     OBLIGATION_COMP.AMT%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64)                        := 'CE_ALLOC_SQL.ALLOC_VVE';
   L_exists                 BOOLEAN;
   L_order_no               ORDHEAD.ORDER_NO%TYPE;
   L_pack_ind               ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind           ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind          ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type              ITEM_MASTER.PACK_TYPE%TYPE;
   L_item                   ITEM_MASTER.ITEM%TYPE;
   L_pack_item              ITEM_MASTER.ITEM%TYPE;
   L_location               ORDLOC.LOCATION%TYPE;
   L_supplier               SUPS.SUPPLIER%TYPE;
   L_origin_country_id      COUNTRY.COUNTRY_ID%TYPE;
   L_qty                    OBLIGATION_COMP.QTY%TYPE;
   L_amt                    OBLIGATION_COMP.AMT%TYPE;
   L_vve_total              OBLIGATION_COMP.QTY%TYPE            := 0;
   L_ord_item_total         OBLIGATION_COMP.QTY%TYPE            := 0;
   L_carton_qty             TRANSPORTATION.CARTON_QTY%TYPE;
   L_carton_uom             TRANSPORTATION.CARTON_UOM%TYPE;
   L_cleared_qty            CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_cleared_qty_uom        CE_ORD_ITEM.CLEARED_QTY_UOM%TYPE;
   L_manifest_item_qty      TRANSPORTATION.ITEM_QTY%TYPE;
   L_manifest_item_qty_uom  TRANSPORTATION.ITEM_QTY_UOM%TYPE;
   L_gross_wt               TRANSPORTATION.GROSS_WT%TYPE;
   L_gross_wt_uom           TRANSPORTATION.GROSS_WT_UOM%TYPE;
   L_net_wt                 TRANSPORTATION.NET_WT%TYPE;
   L_net_wt_uom             TRANSPORTATION.NET_WT_UOM%TYPE;
   L_cubic                  TRANSPORTATION.CUBIC%TYPE;
   L_cubic_uom              TRANSPORTATION.CUBIC_UOM%TYPE;
   L_invoice_amt            TRANSPORTATION.INVOICE_AMT%TYPE;
   L_unit_cost              ORDLOC.UNIT_COST%TYPE;
   L_total_cost             ORDLOC.UNIT_COST%TYPE             := 0;
   L_ord_item_cost          ORDLOC.UNIT_COST%TYPE             := 0;
   L_uom                    UOM_CLASS.UOM%TYPE                := I_alloc_basis_uom;
   L_qty_uom                UOM_CLASS.UOM%TYPE;
   L_item_rec_qty           ORDLOC.QTY_ORDERED%TYPE           := 0;
   L_comp_rec_qty           ORDLOC.QTY_ORDERED%TYPE           := 0;
   L_comp_item              ITEM_MASTER.ITEM%TYPE;
   L_standard_uom           UOM_CLASS.UOM%TYPE;
   L_standard_class         UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor            UOM_CONVERSION.FACTOR%TYPE;
   L_currency_code_ord      CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_ord      CURRENCY_RATES.EXCHANGE_RATE%TYPE;

   cursor C_GET_QTY_UOM is
      select per_count_uom
        from obligation_comp
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

   cursor C_GET_SUPP_CTRY is
      select o.supplier,
             s.origin_country_id
        from ordhead o,
             ordsku s
       where o.order_no = s.order_no
         and o.order_no = L_order_no
         and s.item      = L_item;

   cursor C_GET_PACKITEMS is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

   cursor C_GET_ORD_ITEM is
      select order_no,
             item,
             manifest_item_qty,
             manifest_item_qty_uom,
             carton_qty,
             carton_qty_uom,
             gross_wt,
             gross_wt_uom,
             net_wt,
             net_wt_uom,
             cubic,
             cubic_uom,
             cleared_qty,
             cleared_qty_uom
        from ce_ord_item
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
    order by order_no;

   cursor C_GET_ORD is
      select distinct order_no
        from ce_ord_item
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date;

   cursor C_GET_DETAIL is
      select item,
             manifest_item_qty,
             manifest_item_qty_uom,
             carton_qty,
             carton_qty_uom,
             gross_wt,
             gross_wt_uom,
             net_wt,
             net_wt_uom,
             cubic,
             cubic_uom,
             cleared_qty,
             cleared_qty_uom
        from ce_ord_item
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = L_order_no;
BEGIN

   if I_alloc_basis_uom is NULL then
      SQL_LIB.SET_MARK('OPEN','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                ' Component: '||I_comp_id);
      open C_GET_QTY_UOM;
      SQL_LIB.SET_MARK('FETCH','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                 ' Component: '||I_comp_id);
      fetch C_GET_QTY_UOM into L_uom;
      SQL_LIB.SET_MARK('CLOSE','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                 ' Component: '||I_comp_id);
      close C_GET_QTY_UOM;
   end if;
   ---
   FOR C_rec in C_GET_ORD_ITEM LOOP
      L_order_no              := C_rec.order_no;
      L_item                  := C_rec.item;
      L_manifest_item_qty     := C_rec.manifest_item_qty;
      L_manifest_item_qty_uom := C_rec.manifest_item_qty_uom;
      L_cleared_qty           := C_rec.cleared_qty;
      L_cleared_qty_uom       := C_rec.cleared_qty_uom;
      L_carton_qty            := C_rec.carton_qty;
      L_carton_uom            := C_rec.carton_qty_uom;
      L_gross_wt              := C_rec.gross_wt;
      L_gross_wt_uom          := C_rec.gross_wt_uom;
      L_cubic                 := C_rec.cubic;
      L_cubic_uom             := C_rec.cubic_uom;
      L_net_wt                := C_rec.net_wt;
      L_net_wt_uom            := C_rec.net_wt_uom;
      ---
      if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                            L_currency_code_ord,
                                            L_exchange_rate_ord,
                                            L_order_no) = FALSE then
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                 ' Item: '||L_item);
      open C_GET_SUPP_CTRY;
      SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_CTRY','ORDHEAD, ORDSKU','Order No: '||to_char(L_order_no)||
                                                                  ' Item: '||L_item);
      fetch C_GET_SUPP_CTRY into L_supplier,
                                 L_origin_country_id;
      SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_CTRY','ORDHEAD, ORDSKU','Order No: '||to_char(L_order_no)||
                                                                  ' Item: '||L_item);
      close C_GET_SUPP_CTRY;
      ---
      if L_manifest_item_qty > 0 then
         L_qty     := L_manifest_item_qty;
         L_qty_uom := L_manifest_item_qty_uom;
      elsif L_cleared_qty > 0 then
         L_qty     := L_cleared_qty;
         L_qty_uom := L_cleared_qty_uom;
      elsif L_carton_qty > 0 then
         L_qty     := L_carton_qty;
         L_qty_uom := L_carton_uom;
      elsif L_gross_wt > 0 then
         L_qty     := L_gross_wt;
         L_qty_uom := L_gross_wt_uom;
      elsif L_cubic > 0 then
         L_qty     := L_cubic;
         L_qty_uom := L_cubic_uom;
      elsif L_net_wt > 0 then
         L_qty     := L_net_wt;
         L_qty_uom := L_net_wt_uom;
      else
         L_qty := 0;
      end if;
      ---
      if ITEM_ATTRIB_SQL.GET_PACK_INDS (O_error_message,
                                        L_pack_ind,
                                        L_sellable_ind,
                                        L_orderable_ind,
                                        L_pack_type,
                                        L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then

         L_item_rec_qty := 0;
         ---
         if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                         L_qty,
                                         L_item,
                                         L_qty,
                                         L_qty_uom,
                                         L_supplier,
                                         L_origin_country_id) = FALSE then
            return FALSE;
         end if;
         ---
         FOR C_rec in C_GET_PACKITEMS LOOP
            L_comp_item    := C_rec.item;
            L_comp_rec_qty := C_rec.qty;
            ---
            if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                L_standard_uom,
                                                L_standard_class,
                                                L_conv_factor,
                                                L_comp_item,
                                                'N') = FALSE then
               return FALSE;
            end if;
            ---
            if UOM_SQL.CONVERT(O_error_message,
                               L_comp_rec_qty,
                               L_uom,
                               L_comp_rec_qty,
                               L_standard_uom,
                               L_comp_item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_qty);
         END LOOP;
      else
         if L_qty <> 0 then
            if UOM_SQL.CONVERT(O_error_message,
                               L_item_rec_qty,
                               L_uom,
                               L_qty,
                               L_qty_uom,
                               L_item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                L_standard_uom,
                                                L_standard_class,
                                                L_conv_factor,
                                                L_item,
                                                'N') = FALSE then
               return FALSE;
            end if;
            ---
            if UOM_SQL.CONVERT(O_error_message,
                               L_qty,
                               L_standard_uom,
                               L_qty,
                               L_qty_uom,
                               L_item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
      ---
      if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                             L_exists,
                                             L_unit_cost,
                                             L_order_no,
                                             L_item,
                                             L_pack_item,
                                             L_location) = FALSE then
         return FALSE;
      end if;
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_unit_cost,
                              L_currency_code_ord,
                              NULL,  -- primary currency
                              L_unit_cost,
                              'N',
                              NULL,
                              NULL,
                              L_exchange_rate_ord,
                              NULL) = FALSE then
         return FALSE;
      end if;
      ---
      L_vve_total  := L_vve_total  + L_item_rec_qty;
      L_total_cost := L_total_cost + (L_unit_cost * L_qty);

   END LOOP;
   ---
   FOR C_rec in C_GET_ORD LOOP
      L_order_no := C_rec.order_no;
      ---
      if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                            L_currency_code_ord,
                                            L_exchange_rate_ord,
                                            L_order_no) = FALSE then
         return FALSE;
      end if;
      ---
      L_ord_item_total := 0;
      L_ord_item_cost  := 0;
      ---
      FOR L_rec in C_GET_DETAIL LOOP
         L_item                  := L_rec.item;
         L_manifest_item_qty     := L_rec.manifest_item_qty;
         L_manifest_item_qty_uom := L_rec.manifest_item_qty_uom;
         L_cleared_qty           := L_rec.cleared_qty;
         L_cleared_qty_uom       := L_rec.cleared_qty_uom;
         L_carton_qty            := L_rec.carton_qty;
         L_carton_uom            := L_rec.carton_qty_uom;
         L_gross_wt              := L_rec.gross_wt;
         L_gross_wt_uom          := L_rec.gross_wt_uom;
         L_cubic                 := L_rec.cubic;
         L_cubic_uom             := L_rec.cubic_uom;
         L_net_wt                := L_rec.net_wt;
         L_net_wt_uom            := L_rec.net_wt_uom;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                    ' Item: '||L_item);
         open C_GET_SUPP_CTRY;
         SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                     ' Item: '||L_item);
         fetch C_GET_SUPP_CTRY into L_supplier,
                                    L_origin_country_id;
         SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                     ' Item: '||L_item);
         close C_GET_SUPP_CTRY;
         ---
         if L_manifest_item_qty > 0 then
            L_qty     := L_manifest_item_qty;
            L_qty_uom := L_manifest_item_qty_uom;
         elsif L_cleared_qty > 0 then
            L_qty     := L_cleared_qty;
            L_qty_uom := L_cleared_qty_uom;
         elsif L_carton_qty > 0 then
            L_qty     := L_carton_qty;
            L_qty_uom := L_carton_uom;
         elsif L_gross_wt > 0 then
            L_qty     := L_gross_wt;
            L_qty_uom := L_gross_wt_uom;
         elsif L_cubic > 0 then
            L_qty     := L_cubic;
            L_qty_uom := L_cubic_uom;
         elsif L_net_wt > 0 then
            L_qty     := L_net_wt;
            L_qty_uom := L_net_wt_uom;
         else
            L_qty := 0;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS (O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then

            L_item_rec_qty := 0;
            ---
            if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                            L_qty,
                                            L_item,
                                            L_qty,
                                            L_qty_uom,
                                            L_supplier,
                                            L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            FOR C_rec in C_GET_PACKITEMS LOOP
               L_comp_item    := C_rec.item;
               L_comp_rec_qty := C_rec.qty;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_comp_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_comp_rec_qty,
                                  L_uom,
                                  L_comp_rec_qty,
                                  L_standard_uom,
                                  L_comp_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_qty);
            END LOOP;
         else
            if L_qty <> 0 then
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  L_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                L_standard_uom,
                                                L_standard_class,
                                                L_conv_factor,
                                                L_item,
                                                'N') = FALSE then
               return FALSE;
            end if;
            ---
            if UOM_SQL.CONVERT(O_error_message,
                               L_qty,
                               L_standard_uom,
                               L_qty,
                               L_qty_uom,
                               L_item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                L_exists,
                                                L_unit_cost,
                                                L_order_no,
                                                L_item,
                                                L_pack_item,
                                                L_location) = FALSE then
            return FALSE;
         end if;
         ---
         L_ord_item_total := L_ord_item_total + L_item_rec_qty;
         L_ord_item_cost  := L_ord_item_cost + (L_unit_cost * L_qty);
      END LOOP;
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_ord_item_cost,
                              L_currency_code_ord,
                              NULL,  -- primary currency
                              L_ord_item_cost,
                              'N',
                              NULL,
                              NULL,
                              L_exchange_rate_ord,
                              NULL) = FALSE then
         return FALSE;
      end if;
      ---
      if L_vve_total = 0 or L_total_cost = 0 then
         L_qty := 0;
         L_amt := 0;
      else
         L_qty := I_qty * (L_ord_item_total / L_vve_total);
         ---
         if I_alloc_basis_uom is not NULL then
            L_amt := I_amt_prim * (L_ord_item_total / L_vve_total);
         else
            L_amt := I_amt_prim * (L_ord_item_cost  / L_total_cost);
         end if;
      end if;
      ---
      if ALLOC_PO(O_error_message,
                  I_obligation_key,
                  I_obligation_level,
                  I_ce_id,
                  I_vessel_id,
                  I_voyage_flt_id,
                  I_estimated_depart_date,
                  L_order_no,
                  I_comp_id,
                  I_alloc_basis_uom,
                  L_qty,
                  L_amt) = FALSE then
          return FALSE;
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
      return FALSE;
END ALLOC_VVE;
-------------------------------------------------------------------------------
FUNCTION ALLOC_CE(O_error_message         IN OUT VARCHAR2,
                  I_obligation_key        IN     OBLIGATION.OBLIGATION_KEY%TYPE,
                  I_obligation_level      IN     OBLIGATION.OBLIGATION_LEVEL%TYPE,
                  I_entry_no              IN     CE_HEAD.ENTRY_NO%TYPE,
                  I_comp_id               IN     ELC_COMP.COMP_ID%TYPE,
                  I_alloc_basis_uom       IN     UOM_CLASS.UOM%TYPE,
                  I_qty                   IN     OBLIGATION_COMP.QTY%TYPE,
                  I_amt_prim              IN     OBLIGATION_COMP.AMT%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64)                        := 'CE_ALLOC_SQL.ALLOC_CE';
   L_exists                 BOOLEAN;
   L_ce_id                  CE_HEAD.CE_ID%TYPE;
   L_order_no               ORDHEAD.ORDER_NO%TYPE;
   L_pack_ind               ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind           ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind          ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type              ITEM_MASTER.PACK_TYPE%TYPE;
   L_item                   ITEM_MASTER.ITEM%TYPE;
   L_pack_item              ITEM_MASTER.ITEM%TYPE;
   L_location               ORDLOC.LOCATION%TYPE;
   L_vessel_id              TRANSPORTATION.VESSEL_ID%TYPE;
   L_voyage_flt_id          TRANSPORTATION.VOYAGE_FLT_ID%TYPE;
   L_estimated_depart_date  TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE;
   L_supplier               SUPS.SUPPLIER%TYPE;
   L_origin_country_id      COUNTRY.COUNTRY_ID%TYPE;
   L_qty                    OBLIGATION_COMP.QTY%TYPE;
   L_amt                    OBLIGATION_COMP.AMT%TYPE;
   L_ce_total               OBLIGATION_COMP.QTY%TYPE            := 0;
   L_vve_total              OBLIGATION_COMP.QTY%TYPE            := 0;
   L_carton_qty             TRANSPORTATION.CARTON_QTY%TYPE;
   L_carton_uom             TRANSPORTATION.CARTON_UOM%TYPE;
   L_cleared_qty            CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_cleared_qty_uom        CE_ORD_ITEM.CLEARED_QTY_UOM%TYPE;
   L_manifest_item_qty      TRANSPORTATION.ITEM_QTY%TYPE;
   L_manifest_item_qty_uom  TRANSPORTATION.ITEM_QTY_UOM%TYPE;
   L_gross_wt               TRANSPORTATION.GROSS_WT%TYPE;
   L_gross_wt_uom           TRANSPORTATION.GROSS_WT_UOM%TYPE;
   L_net_wt                 TRANSPORTATION.NET_WT%TYPE;
   L_net_wt_uom             TRANSPORTATION.NET_WT_UOM%TYPE;
   L_cubic                  TRANSPORTATION.CUBIC%TYPE;
   L_cubic_uom              TRANSPORTATION.CUBIC_UOM%TYPE;
   L_invoice_amt            TRANSPORTATION.INVOICE_AMT%TYPE;
   L_unit_cost              ORDLOC.UNIT_COST%TYPE;
   L_total_cost             ORDLOC.UNIT_COST%TYPE             := 0;
   L_vve_cost               ORDLOC.UNIT_COST%TYPE             := 0;
   L_uom                    UOM_CLASS.UOM%TYPE                := I_alloc_basis_uom;
   L_qty_uom                UOM_CLASS.UOM%TYPE;
   L_item_rec_qty           ORDLOC.QTY_ORDERED%TYPE           := 0;
   L_comp_rec_qty           ORDLOC.QTY_ORDERED%TYPE           := 0;
   L_comp_item              ITEM_MASTER.ITEM%TYPE;
   L_standard_uom           UOM_CLASS.UOM%TYPE;
   L_standard_class         UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor            UOM_CONVERSION.FACTOR%TYPE;
   L_currency_code_ord      CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_ord      CURRENCY_RATES.EXCHANGE_RATE%TYPE;

   cursor C_GET_QTY_UOM is
      select per_count_uom
        from obligation_comp
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

   cursor C_GET_SUPP_CTRY is
      select o.supplier,
             s.origin_country_id
        from ordhead o,
             ordsku s
       where o.order_no = s.order_no
         and o.order_no = L_order_no
         and s.item     = L_item;

   cursor C_GET_VVE is
      select vessel_id,
             voyage_flt_id,
             estimated_depart_date
        from ce_shipment
       where ce_id = L_ce_id;

   cursor C_GET_PACKITEMS is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

   cursor C_GET_ORD_ITEM is
      select order_no,
             item,
             manifest_item_qty,
             manifest_item_qty_uom,
             carton_qty,
             carton_qty_uom,
             gross_wt,
             gross_wt_uom,
             net_wt,
             net_wt_uom,
             cubic,
             cubic_uom,
             cleared_qty,
             cleared_qty_uom
        from ce_ord_item
       where ce_id                 = L_ce_id
         and vessel_id             = L_vessel_id
         and voyage_flt_id         = L_voyage_flt_id
         and estimated_depart_date = L_estimated_depart_date
    order by order_no;

BEGIN
   if I_alloc_basis_uom is NULL then
      SQL_LIB.SET_MARK('OPEN','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                ' Component: '||I_comp_id);
      open C_GET_QTY_UOM;
      SQL_LIB.SET_MARK('FETCH','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                 ' Component: '||I_comp_id);
      fetch C_GET_QTY_UOM into L_uom;
      SQL_LIB.SET_MARK('CLOSE','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                 ' Component: '||I_comp_id);
      close C_GET_QTY_UOM;
   end if;
   ---
   if CE_SQL.GET_CE_ID(O_error_message,
                       L_exists,
                       L_ce_id,
                       I_entry_no) = FALSE then
      return FALSE;
   end if;
   ---
   FOR V_rec in C_GET_VVE LOOP
      L_vessel_id             := V_rec.vessel_id;
      L_voyage_flt_id         := V_rec.voyage_flt_id;
      L_estimated_depart_date := V_rec.estimated_depart_date;
      L_vve_total             := 0;
      L_vve_cost              := 0;
      ---
      FOR C_rec in C_GET_ORD_ITEM LOOP
         L_order_no              := C_rec.order_no;
         L_item                  := C_rec.item;
         L_manifest_item_qty     := C_rec.manifest_item_qty;
         L_manifest_item_qty_uom := C_rec.manifest_item_qty_uom;
         L_cleared_qty           := C_rec.cleared_qty;
         L_cleared_qty_uom       := C_rec.cleared_qty_uom;
         L_carton_qty            := C_rec.carton_qty;
         L_carton_uom            := C_rec.carton_qty_uom;
         L_gross_wt              := C_rec.gross_wt;
         L_gross_wt_uom          := C_rec.gross_wt_uom;
         L_cubic                 := C_rec.cubic;
         L_cubic_uom             := C_rec.cubic_uom;
         L_net_wt                := C_rec.net_wt;
         L_net_wt_uom            := C_rec.net_wt_uom;
         ---
         if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                               L_currency_code_ord,
                                               L_exchange_rate_ord,
                                               L_order_no) = FALSE then
            return FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                    ' Item: '||L_item);
         open C_GET_SUPP_CTRY;
         SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                     ' Item: '||L_item);
         fetch C_GET_SUPP_CTRY into L_supplier,
                                    L_origin_country_id;
         SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                     ' Item: '||L_item);
         close C_GET_SUPP_CTRY;
         ---
         if L_manifest_item_qty > 0 then
            L_qty     := L_manifest_item_qty;
            L_qty_uom := L_manifest_item_qty_uom;
         elsif L_cleared_qty > 0 then
            L_qty     := L_cleared_qty;
            L_qty_uom := L_cleared_qty_uom;
         elsif L_carton_qty > 0 then
            L_qty     := L_carton_qty;
            L_qty_uom := L_carton_uom;
         elsif L_gross_wt > 0 then
            L_qty     := L_gross_wt;
            L_qty_uom := L_gross_wt_uom;
         elsif L_cubic > 0 then
            L_qty     := L_cubic;
            L_qty_uom := L_cubic_uom;
         elsif L_net_wt > 0 then
            L_qty     := L_net_wt;
            L_qty_uom := L_net_wt_uom;
         else
            L_qty := 0;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS (O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then
            L_item_rec_qty := 0;
            ---
            if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                            L_qty,
                                            L_item,
                                            L_qty,
                                            L_qty_uom,
                                            L_supplier,
                                            L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            FOR C_rec in C_GET_PACKITEMS LOOP
               L_comp_item     := C_rec.item;
               L_comp_rec_qty := C_rec.qty;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_comp_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_comp_rec_qty,
                                  L_uom,
                                  L_comp_rec_qty,
                                  L_standard_uom,
                                  L_comp_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_qty);
            END LOOP;
         else
            if L_qty <> 0 then
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  L_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_qty,
                                  L_standard_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
         ---
         if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                L_exists,
                                                L_unit_cost,
                                                L_order_no,
                                                L_item,
                                                L_pack_item,
                                                L_location) = FALSE then
            return FALSE;
         end if;
         ---
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_unit_cost,
                                 L_currency_code_ord,
                                 NULL,  -- primary currency
                                 L_unit_cost,
                                 'N',
                                 NULL,
                                 NULL,
                                 L_exchange_rate_ord,
                                 NULL) = FALSE then
            return FALSE;
         end if;
         ---
         L_vve_total := L_vve_total + L_item_rec_qty;
         L_vve_cost  := L_vve_cost  + (L_unit_cost * L_qty);
      END LOOP;
      ---
      L_ce_total   := L_ce_total   + L_vve_total;
      L_total_cost := L_total_cost + L_vve_cost;
   END LOOP;
   ---
   FOR V_rec in C_GET_VVE LOOP
      L_vessel_id             := V_rec.vessel_id;
      L_voyage_flt_id         := V_rec.voyage_flt_id;
      L_estimated_depart_date := V_rec.estimated_depart_date;
      L_vve_total             := 0;
      L_vve_cost              := 0;
      ---
      FOR C_rec in C_GET_ORD_ITEM LOOP
         L_order_no              := C_rec.order_no;
         L_item                  := C_rec.item;
         L_manifest_item_qty     := C_rec.manifest_item_qty;
         L_manifest_item_qty_uom := C_rec.manifest_item_qty_uom;
         L_cleared_qty           := C_rec.cleared_qty;
         L_cleared_qty_uom       := C_rec.cleared_qty_uom;
         L_carton_qty            := C_rec.carton_qty;
         L_carton_uom            := C_rec.carton_qty_uom;
         L_gross_wt              := C_rec.gross_wt;
         L_gross_wt_uom          := C_rec.gross_wt_uom;
         L_cubic                 := C_rec.cubic;
         L_cubic_uom             := C_rec.cubic_uom;
         L_net_wt                := C_rec.net_wt;
         L_net_wt_uom            := C_rec.net_wt_uom;
         ---
         if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                               L_currency_code_ord,
                                               L_exchange_rate_ord,
                                               L_order_no) = FALSE then
            return FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                    ' Item: '||L_item);
         open C_GET_SUPP_CTRY;
         SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                     ' Item: '||L_item);
         fetch C_GET_SUPP_CTRY into L_supplier,
                                    L_origin_country_id;
         SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                     ' Item: '||L_item);
         close C_GET_SUPP_CTRY;
         ---
         if L_manifest_item_qty > 0 then
            L_qty     := L_manifest_item_qty;
            L_qty_uom := L_manifest_item_qty_uom;
         elsif L_cleared_qty > 0 then
            L_qty     := L_cleared_qty;
            L_qty_uom := L_cleared_qty_uom;
         elsif L_carton_qty > 0 then
            L_qty     := L_carton_qty;
            L_qty_uom := L_carton_uom;
         elsif L_gross_wt > 0 then
            L_qty     := L_gross_wt;
            L_qty_uom := L_gross_wt_uom;
         elsif L_cubic > 0 then
            L_qty     := L_cubic;
            L_qty_uom := L_cubic_uom;
         elsif L_net_wt > 0 then
            L_qty     := L_net_wt;
            L_qty_uom := L_net_wt_uom;
         else
            L_qty := 0;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS (O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then
            L_item_rec_qty := 0;
            ---
            if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                            L_qty,
                                            L_item,
                                            L_qty,
                                            L_qty_uom,
                                            L_supplier,
                                            L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            FOR C_rec in C_GET_PACKITEMS LOOP
               L_comp_item     := C_rec.item;
               L_comp_rec_qty := C_rec.qty;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_comp_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_comp_rec_qty,
                                  L_uom,
                                  L_comp_rec_qty,
                                  L_standard_uom,
                                  L_comp_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_qty);
            END LOOP;
         else
            if L_qty <> 0 then
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  L_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_qty,
                                  L_standard_uom,
                                  L_qty,
                                  L_qty_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
         ---
         if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                L_exists,
                                                L_unit_cost,
                                                L_order_no,
                                                L_item,
                                                L_pack_item,
                                                L_location) = FALSE then
            return FALSE;
         end if;
         ---
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_unit_cost,
                                 L_currency_code_ord,
                                 NULL,  -- primary currency
                                 L_unit_cost,
                                 'N',
                                 NULL,
                                 NULL,
                                 L_exchange_rate_ord,
                                 NULL) = FALSE then
            return FALSE;
         end if;
         ---
         L_vve_total := L_vve_total + L_item_rec_qty;
         L_vve_cost  := L_vve_cost  + (L_unit_cost * L_qty);
      END LOOP;
      ---
      if L_ce_total = 0 or L_total_cost = 0 then
         L_qty := 0;
         L_amt := 0;
      else
         L_qty := I_qty * (L_vve_total / L_ce_total);
         ---
         if I_alloc_basis_uom is not NULL then
            L_amt := I_amt_prim * (L_vve_total / L_ce_total);
         else
            L_amt := I_amt_prim * (L_vve_cost  / L_total_cost);
         end if;
      end if;
      ---
      if ALLOC_VVE(O_error_message,
                   I_obligation_key,
                   I_obligation_level,
                   L_ce_id,
                   L_vessel_id,
                   L_voyage_flt_id,
                   L_estimated_depart_date,
                   I_comp_id,
                   I_alloc_basis_uom,
                   L_qty,
                   L_amt) = FALSE then
         return FALSE;
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
      return FALSE;
END ALLOC_CE;
------------------------------------------------------------------------------------
--- Removed function INSERT_ELC_COMPS.  The function of inserting ALC records
--- For each assessment component is now done by alc_alloc_sql.insert_assess_comps
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
FUNCTION INSERT_ALC_COMP_LOCS(O_error_message     IN OUT VARCHAR2,
                              I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                              I_item              IN     ITEM_MASTER.ITEM%TYPE,
                              I_pack_item         IN     ITEM_MASTER.ITEM%TYPE,
                              I_ce_id             IN     CE_HEAD.CE_ID%TYPE,
                              I_vessel_id         IN     TRANSPORTATION.VESSEL_ID%TYPE,
                              I_voyage_flt_id     IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                              I_etd               IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                              I_comp_id           IN     ELC_COMP.COMP_ID%TYPE,
                              I_location          IN     ORDLOC.LOCATION%TYPE,
                              I_loc_type          IN     ORDLOC.LOC_TYPE%TYPE,
                              I_act_value         IN     ALC_COMP_LOC.ACT_VALUE%TYPE,
                              I_qty               IN     ALC_COMP_LOC.QTY%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'CE_ALLOC_SQL.INSERT_ALC_COMP_LOCS';

BEGIN

  -- Assessment comps will be reallocated at the end of the process
   if ALC_ALLOC_SQL.ADD_PO_TO_QUEUE(O_error_message,
                                    I_order_no) = FALSE then
      return FALSE;
   end if;
   insert into alc_comp_loc (order_no,
                             seq_no,
                             comp_id,
                             location,
                             loc_type,
                             act_value,
                             qty,
                             last_calc_date)
                      select I_order_no,
                             seq_no,
                             I_comp_id,
                             I_location,
                             I_loc_type,
                             I_act_value,
                             I_qty,
                             LP_vdate
                        from alc_head
                       where order_no              = I_order_no
                         and item                  = I_item
                         and ((pack_item           is NULL
                               and I_pack_item     is NULL)
                           or (pack_item           = I_pack_item
                               and pack_item       is not NULL
                               and I_pack_item     is not NULL))
                         and ce_id                 = I_ce_id
                         and vessel_id             = I_vessel_id
                         and voyage_flt_id         = I_voyage_flt_id
                         and estimated_depart_date = I_etd;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_ALC_COMP_LOCS;
----------------------------------------------------------------------------------
FUNCTION ALLOC_PO_ITEM(O_error_message         IN OUT VARCHAR2,
                       I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                       I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                       I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                       I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                       I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                       I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                       I_pack_item             IN     ITEM_MASTER.ITEM%TYPE,
                       I_comp_id               IN     CE_CHARGES.COMP_ID%TYPE,
                       I_comp_value_prim       IN     CE_CHARGES.COMP_VALUE%TYPE,
                       I_qty                   IN     CE_ORD_ITEM.CLEARED_QTY%TYPE,
                       I_error_ind             IN     ALC_HEAD.ERROR_IND%TYPE)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(64)                := 'CE_ALLOC_SQL.ALLOC_PO_ITEM';
   L_alc_head_exists      VARCHAR2(1)                 := 'N';
   L_amt_prim             ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_qty                  ALC_COMP_LOC.QTY%TYPE       := 0;
   L_qty_rec              ORDLOC.QTY_RECEIVED%TYPE    := 0;
   L_qty_shp              ORDLOC.QTY_RECEIVED%TYPE    := 0;
   L_qty_ord              ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_loc_qty              ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_qty_shipped          SHIPSKU.QTY_EXPECTED%TYPE   := 0;
   L_item                  ITEM_MASTER.ITEM%TYPE;
   L_supplier             SUPS.SUPPLIER%TYPE;
   L_origin_country_id    COUNTRY.COUNTRY_ID%TYPE;
   L_location             ORDLOC.LOCATION%TYPE;
   ---
   L_table                VARCHAR2(30);
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_GET_ORD_SUP_CTRY is
      select o.supplier,
             s.origin_country_id
        from ordhead o,
             ordsku s
       where o.order_no = I_order_no
         and o.order_no = s.order_no
         and ((s.item      = I_item
              and I_pack_item is NULL)
          or (s.item      = I_pack_item
              and I_pack_item is NOT NULL));

   cursor C_GET_ITEM_QTY is
      select NVL(SUM(qty_ordered), 0) qty_ordered,
             NVL(SUM(qty_received), 0) qty_received
        from ordloc
       where order_no = I_order_no
         and ((item      = I_item
              and I_pack_item is NULL)
          or (item      = I_pack_item
              and I_pack_item is NOT NULL));

   cursor C_GET_ITEM_SHP_QTY is
      select NVL(SUM(k.qty_expected), 0) qty_expected
        from shipment s,
             shipsku k
       where s.order_no = I_order_no
         and ((k.item      = I_item
               and I_pack_item is NULL)
          or (item         = I_pack_item
              and I_pack_item is NOT NULL))
         and s.shipment = k.shipment;

   cursor C_ALC_HEAD_EXISTS is
      select 'Y'
        from alc_head
       where order_no              = I_order_no
         and item                  = I_item
         and ((pack_item             = I_pack_item
              and I_pack_item is NOT NULL)
          or  (pack_item           is NULL
               and I_pack_item is NULL))
         and ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date;

   cursor C_GET_ORD_LOCS is
      select location,
             loc_type,
             NVL(qty_received, 0) qty_received,
             NVL(qty_ordered, 0) qty_ordered
        from ordloc
       where order_no = I_order_no
         and ((item      = I_item
               and I_pack_item is NULL)
          or  (item      = I_pack_item
               and I_pack_item is NOT NULL));

   cursor C_GET_QTY_SHIPPED is
      select NVL(SUM(k.qty_expected), 0) qty_expected
        from shipment s,
             shipsku k
       where s.order_no = I_order_no
         and ((k.item      = I_item
               and I_pack_item is NULL)
          or  (k.item      = I_pack_item
               and I_pack_item is NOT NULL))
         and s.to_loc = L_location
         and s.shipment = k.shipment;

   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from alc_head
       where order_no              = I_order_no
         and ((item                = I_item
               and I_pack_item     is NULL)
           or (item                = I_pack_item
               and I_pack_item     is NOT NULL))
         and ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_ORD_SUP_CTRY','ORDHEAD,ORDLOC','Order: '||to_char(I_order_no));
   open C_GET_ORD_SUP_CTRY;
   SQL_LIB.SET_MARK('FETCH','C_GET_ORD_SUP_CTRY','ORDHEAD,ORDLOC','Order: '||to_char(I_order_no));
   fetch C_GET_ORD_SUP_CTRY into L_supplier,
                                 L_origin_country_id;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ORD_SUP_CTRY','ORDHEAD,ORDLOC','Order: '||to_char(I_order_no));
   close C_GET_ORD_SUP_CTRY;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(I_order_no)||
                                                     ' item: '||I_item);
   open C_GET_ITEM_QTY;
   SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(I_order_no)||
                                                      ' item: '||I_item);
   fetch C_GET_ITEM_QTY into L_qty_ord,
                             L_qty_rec;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(I_order_no)||
                                                      ' item: '||I_item);
   close C_GET_ITEM_QTY;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_SHP_QTY','SHIPMENT,SHIPSKU','order no: '||to_char(I_order_no)||
                                                                   ' item: '||I_item);
   open C_GET_ITEM_SHP_QTY;
   SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_SHP_QTY','SHIPMENT,SHIPSKU','order no: '||to_char(I_order_no)||
                                                                    ' item: '||I_item);
   fetch C_GET_ITEM_SHP_QTY into L_qty_shp;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_SHP_QTY','SHIPMENT,SHIPSKU','order no: '||to_char(I_order_no)||
                                                                    ' item: '||I_item);
   close C_GET_ITEM_SHP_QTY;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ALC_HEAD_EXISTS','ALC_HEAD',NULL);
   open C_ALC_HEAD_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_ALC_HEAD_EXISTS','ALC_HEAD',NULL);
   fetch C_ALC_HEAD_EXISTS into L_alc_head_exists;
   SQL_LIB.SET_MARK('CLOSE','C_ALC_HEAD_EXISTS','ALC_HEAD',NULL);
   close C_ALC_HEAD_EXISTS;
   ---
   if I_pack_item is NOT NULL then
      L_item := I_pack_item;
   else
      L_item := I_item;
   end if;
   ---
   if L_alc_head_exists = 'N' then
      if TRAN_ALLOC_SQL.INSERT_ALC_HEAD(O_error_message,
                                        I_order_no,
                                        I_item,
                                        I_pack_item,
                                        NULL,
                                        I_ce_id,
                                        I_vessel_id,
                                        I_voyage_flt_id,
                                        I_estimated_depart_date,
                                        I_qty,
                                        I_error_ind) = FALSE then
         return FALSE;
      end if;
   else
      if I_error_ind = 'Y' then
         ---
         --- Lock the ALC records.
         ---
         L_table := 'ALC_HEAD';
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ALC_HEAD','ALC_HEAD',NULL);
         open C_LOCK_ALC_HEAD;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALC_HEAD','ALC_HEAD',NULL);
         close C_LOCK_ALC_HEAD;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'ALC_HEAD',NULL);
         ---
         update alc_head
            set error_ind = 'Y'
          where order_no              = I_order_no
            and ((item                = I_item
                  and I_pack_item     is NULL)
              or (item                = I_pack_item
                  and pack_item       is NOT NULL))
            and ce_id                 = I_ce_id
            and vessel_id             = I_vessel_id
            and voyage_flt_id         = I_voyage_flt_id
            and estimated_depart_date = I_estimated_depart_date;
      end if;
   end if;
   ---
   FOR L_rec in C_GET_ORD_LOCS LOOP
      L_location := L_rec.location;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_QTY_SHIPPED','SHIPMENT,SHIPSKU',NULL);
      open C_GET_QTY_SHIPPED;
      SQL_LIB.SET_MARK('FETCH','C_GET_QTY_SHIPPED','SHIPMENT,SHIPSKU',NULL);
      fetch C_GET_QTY_SHIPPED into L_qty_shipped;
      SQL_LIB.SET_MARK('CLOSE','C_GET_QTY_SHIPPED','SHIPMENT,SHIPSKU',NULL);
      close C_GET_QTY_SHIPPED;
      ---
      if L_qty_rec >= L_qty_ord then
         L_loc_qty := (NVL(L_rec.qty_received, 0) / L_qty_rec) * I_qty;
      elsif L_qty_shp > 0 then
         L_loc_qty := (NVL(L_qty_shipped, 0) / L_qty_shp) * I_qty;
      else
         L_loc_qty := (NVL(L_rec.qty_ordered, 0) / L_qty_ord) * I_qty;
      end if;
      ---
      if L_loc_qty = 0 then
         L_amt_prim := 0;
         L_qty      := 1;
      else
         L_amt_prim := I_comp_value_prim;
         L_qty      := I_qty;
      end if;
      ---
      if INSERT_ALC_COMP_LOCS(O_error_message,
                              I_order_no,
                              I_item,
                              I_pack_item,
                              I_ce_id,
                              I_vessel_id,
                              I_voyage_flt_id,
                              I_estimated_depart_date,
                              I_comp_id,
                              L_rec.location,
                              L_rec.loc_type,
                              L_amt_prim,
                              L_loc_qty) = FALSE then
         return FALSE;
      end if;
      ---
      -- Removed call to insert_elc_comps.  Assessments are now
      -- logged at order approval time in alc_alloc_sql.insert_assess_comps
      ---
   END LOOP;
   ---
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
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ALLOC_PO_ITEM;
------------------------------------------------------------------------------------
FUNCTION ALLOC_CE_DETAIL(O_error_message IN OUT VARCHAR2,
                         I_ce_id         IN     CE_HEAD.CE_ID%TYPE,
                         I_entry_no      IN     CE_HEAD.ENTRY_NO%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(50) := 'CE_ALLOC_SQL.ALLOC_CE_DETAIL';
   L_currency_code          CURRENCIES.CURRENCY_CODE%TYPE;
   L_vessel_id              TRANSPORTATION.VESSEL_ID%TYPE;
   L_voyage_flt_id          TRANSPORTATION.VOYAGE_FLT_ID%TYPE;
   L_estimated_depart_date  TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE;
   L_order_no               ORDHEAD.ORDER_NO%TYPE;
   L_item                   ITEM_MASTER.ITEM%TYPE;
   L_pack_item              ITEM_MASTER.ITEM%TYPE;
   L_supplier               ITEM_SUPPLIER.SUPPLIER%TYPE;
   L_origin_country         ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
   L_comp_id                CE_CHARGES.COMP_ID%TYPE;
   L_comp_value_ce          CE_CHARGES.COMP_VALUE%TYPE;
   L_comp_value_prim        CE_CHARGES.COMP_VALUE%TYPE;
   L_cleared_qty            CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_cleared_qty_uom        CE_ORD_ITEM.CLEARED_QTY_UOM%TYPE;
   L_exchange_rate          CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_conv_factor            ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_item_conv_factor       ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_pack_standard_uom      ITEM_MASTER.STANDARD_UOM%TYPE;
   L_class                  VARCHAR2(6);
   L_error_ind              ALC_HEAD.ERROR_IND%TYPE := 'N';
   L_packitem_qty           CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_pack_qty               CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_converted_qty          CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_total_cleared_qty      CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_item_standard_uom      ITEM_MASTER.STANDARD_UOM%TYPE;
   L_unit_of_work           VARCHAR2(200);
   L_total_cleared_qty_stnd CE_ORD_ITEM.CLEARED_QTY%TYPE;

   cursor C_CE_ORD_ITEM is
      select distinct coi.vessel_id,
             coi.voyage_flt_id,
             coi.estimated_depart_date,
             coi.order_no,
             cc.item,
             cc.pack_item,
             NVL(coi.cleared_qty,0) cleared_qty,
             NVL(coi.cleared_qty_uom,'EA') cleared_qty_uom
        from ce_charges cc,
             ce_ord_item coi
       where cc.ce_id                 = I_ce_id
         and cc.ce_id                 = coi.ce_id
         and cc.vessel_id             = coi.vessel_id
         and cc.voyage_flt_id         = coi.voyage_flt_id
         and cc.estimated_depart_date = coi.estimated_depart_date
         and cc.order_no              = coi.order_no
          and ((cc.item                = coi.item
                and cc.pack_item is NULL)
           or  (cc.pack_item           = coi.item
                and cc.pack_item is NOT NULL))
         and coi.alc_status          != 'R';

   cursor C_CE_CHARGES is
      select SUM(comp_value) comp_value,
             comp_id
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id = L_vessel_id
         and voyage_flt_id = L_voyage_flt_id
         and estimated_depart_date = L_estimated_depart_date
         and order_no              = L_order_no
         and item                  = L_item
         and ((pack_item     is NULL
               and L_pack_item is NULL)
          or (pack_item      = L_pack_item
              and pack_item is not NULL
              and L_pack_item is not NULL))
       group by comp_id;

   cursor C_GET_SUPP_COUNTRY is
      select oh.supplier,
             os.origin_country_id
        from ordhead oh,
             ordsku os
       where oh.order_no = L_order_no
         and oh.order_no = os.order_no
         and ((os.item = L_item
               and L_pack_item is NULL)
          or  (os.item = L_pack_item
               and L_pack_item is NOT NULL));

   cursor C_GET_PACK_QTY is
      select qty
        from v_packsku_qty
       where pack_no = L_pack_item
         and item     = L_item;

BEGIN

   if CE_SQL.GET_CURRENCY_RATE(O_error_message,
                               L_currency_code,
                               L_exchange_rate,
                               I_ce_id) = FALSE then
      return FALSE;
   end if;
   ---
   if CE_SQL.DELETE_ALC(O_error_message,
                        I_ce_id) = FALSE then
      return FALSE;
   end if;
   ---
   if ALC_SQL.DELETE_ERRORS(O_error_message,
                            NULL,
                            NULL,
                            I_entry_no) = FALSE then
      return FALSE;
   end if;
   ---
   for A_rec in C_CE_ORD_ITEM LOOP
      L_vessel_id             := A_rec.vessel_id;
      L_voyage_flt_id         := A_rec.voyage_flt_id;
      L_estimated_depart_date := A_rec.estimated_depart_date;
      L_order_no              := A_rec.order_no;
      L_item                  := A_rec.item;
      L_pack_item             := A_rec.pack_item;
      L_cleared_qty           := A_rec.cleared_qty;
      L_cleared_qty_uom       := A_rec.cleared_qty_uom;
      ---
      for B_rec in C_CE_CHARGES LOOP
         L_comp_id         := B_rec.comp_id;
         L_comp_value_ce   := B_rec.comp_value;
         ---
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_comp_value_ce,
                                 L_currency_code,
                                 NULL,
                                 L_comp_value_prim,
                                 'C',
                                 NULL,
                                 NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_item is NOT NULL then
            SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_COUNTRY','ORDHEAD, ORDLOC','order no.: '||to_char(L_order_no)||
                                                         ' item: '||L_item||' pack no.: '||L_pack_item);
            open C_GET_SUPP_COUNTRY;
            SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_COUNTRY','ORDHEAD, ORDLOC','order no.: '||to_char(L_order_no)||
                                                         ' item: '||L_item||' pack no.: '||L_pack_item);
            fetch C_GET_SUPP_COUNTRY into L_supplier,
                                          L_origin_country;
            SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_COUNTRY','ORDHEAD, ORDLOC','order no.: '||to_char(L_order_no)||
                                                         ' item: '||L_item||' pack no.: '||L_pack_item);
            close C_GET_SUPP_COUNTRY;
            ---
            if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                            L_pack_qty,
                                            L_pack_item,
                                            L_cleared_qty,
                                            L_cleared_qty_uom,
                                            L_supplier,
                                            L_origin_country) = FALSE then
               return FALSE;
            end if;
            ---
            if L_pack_qty = 0 and L_cleared_qty != 0 then
               L_unit_of_work := 'Order No. '||to_char(L_order_no)||', Item '||L_item||
                                 ', Pack '||L_pack_item||', Entry No. '||I_entry_no||
                                 ', Vessel '||L_vessel_id||', Voyage/Flight '||L_voyage_flt_id||
                                 ', ETD '||to_char(L_estimated_depart_date)||', Component '||L_comp_id;
               L_error_ind    := 'Y';
               ---
               if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                                       SQL_LIB.GET_MESSAGE_TEXT('CE_UOM_ERROR',
                                                                                 NULL,
                                                                                 NULL,
                                                                                 NULL),
                                                       L_program,
                                                       L_unit_of_work) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_PACK_QTY','V_PACKSKU_QTY','pack no.: '||L_pack_item||
                                                                            ' item: '||L_item);
            open C_GET_PACK_QTY;
            SQL_LIB.SET_MARK('FETCH','C_GET_PACK_QTY','V_PACKSKU_QTY','pack no.: '||L_pack_item||
                                                                            ' item: '||L_item);
            fetch C_GET_PACK_QTY into L_packitem_qty;
            SQL_LIB.SET_MARK('CLOSE','C_GET_PACK_QTY','V_PACKSKU_QTY','pack no.: '||L_pack_item||
                                                                            ' item: '||L_item);
            close C_GET_PACK_QTY;
            ---
            L_total_cleared_qty := L_pack_qty * L_packitem_qty;
         else
            L_total_cleared_qty := L_cleared_qty;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                             L_item_standard_uom,
                                             L_class,
                                             L_item_conv_factor,
                                             L_item,
                                             'N') = FALSE then
            return FALSE;
         end if;
         ---
         if L_total_cleared_qty = 0 and L_cleared_qty_uom is NULL then
            L_cleared_qty_uom := L_item_standard_uom;
         end if;
         ---
         if L_total_cleared_qty <> 0 then
            if UOM_SQL.CONVERT(O_error_message,
                               L_total_cleared_qty_stnd,
                               L_item_standard_uom,
                               L_total_cleared_qty,
                               L_cleared_qty_uom,
                               L_item,
                               NULL,
                               NULL) = FALSE then
               return FALSE;
            end if;
            ---
            if L_total_cleared_qty_stnd = 0 then
               if L_pack_item is NOT NULL then
                  L_unit_of_work := 'Order No. '||to_char(L_order_no)||', Item '||L_item||
                                    ', Pack '||L_pack_item||', Entry No. '||I_entry_no||
                                    ', Vessel '||L_vessel_id||', Voyage/Flight '||L_voyage_flt_id||
                                    ', ETD '||to_char(L_estimated_depart_date)||', Component '||L_comp_id;
               else
                  L_unit_of_work := 'Order No. '||to_char(L_order_no)||', Item '||L_item||
                                    ', Entry No. '||I_entry_no|| ', Vessel '||L_vessel_id||
                                    ', Voyage/Flight '||L_voyage_flt_id||', ETD      '||to_char(L_estimated_depart_date)||
                                    ', Component '||L_comp_id;
               end if;
               ---
               L_error_ind    := 'Y';
               ---
               if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                                       SQL_LIB.GET_MESSAGE_TEXT('CE_UOM_ERROR',
                                                                                 NULL,
                                                                                 NULL,
                                                                                 NULL),
                                                       L_program,
                                                       L_unit_of_work) = FALSE then
                  return FALSE;
               end if;
            end if;
         else
            L_total_cleared_qty_stnd := 0;
         end if;
         ---
         if ALLOC_PO_ITEM(O_error_message,
                          I_ce_id,
                          L_vessel_id,
                          L_voyage_flt_id,
                          L_estimated_depart_date,
                          L_order_no,
                          L_item,
                          L_pack_item,
                          L_comp_id,
                          L_comp_value_prim,
                          L_total_cleared_qty_stnd,
                          L_error_ind) = FALSE then
            return FALSE;
         end if;
      END LOOP;
   END LOOP;
   -- Reallocate assessment comps for all affected pos.
   if ALC_ALLOC_SQL.INSERT_ELC_COMPS_FOR_QUEUE(O_error_message) = FALSE then
      return FALSE;
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
END ALLOC_CE_DETAIL;
------------------------------------------------------------------------------------
END CE_ALLOC_SQL;
/

