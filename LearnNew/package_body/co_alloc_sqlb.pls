CREATE OR REPLACE PACKAGE BODY CO_ALLOC_SQL AS
------------------------------------------------------------------------------------
FUNCTION ALLOC_PO(O_error_message         IN OUT VARCHAR2,
                  I_obligation_key        IN     OBLIGATION.OBLIGATION_KEY%TYPE,
                  I_obligation_level      IN     OBLIGATION.OBLIGATION_LEVEL%TYPE,
                  I_container_id          IN     TRANSPORTATION.CONTAINER_ID%TYPE,
                  I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                  I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                  I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                  I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                  I_comp_id               IN     ELC_COMP.COMP_ID%TYPE,
                  I_alloc_basis_uom       IN     UOM_CLASS.UOM%TYPE,
                  I_qty                   IN     OBLIGATION_COMP.QTY%TYPE,
                  I_amt_prim              IN     OBLIGATION_COMP.AMT%TYPE)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(64)                := 'CO_ALLOC_SQL.ALLOC_PO';
   L_obl_locs_exist       VARCHAR2(1)                 := 'N';
   L_child_items_exist    VARCHAR2(1)                 := 'N';
   L_item_ord_qty         ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_item_rec_qty         ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_temp_rec_qty         ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_pack_rec_qty         ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_comp_rec_qty         ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_comp_qty             ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_total_rec_qty        ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_rec_qty              ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_qty                  ALC_COMP_LOC.QTY%TYPE       := 0;
   L_item_qty             ALC_COMP_LOC.QTY%TYPE       := 0;
   L_child_item_qty             ALC_COMP_LOC.QTY%TYPE       := 0;
   L_loc_qty              ALC_COMP_LOC.QTY%TYPE       := 0;
   L_act_value            ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_amt_prim             ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_amt                  ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_total_rec_cost       ORDLOC.UNIT_COST%TYPE       := 0;
   L_unit_cost            ORDLOC.UNIT_COST%TYPE       := 0;
   L_temp_unit_cost       ORDLOC.UNIT_COST%TYPE       := 0;
   L_uom                  UOM_CLASS.UOM%TYPE          := I_alloc_basis_uom;
   L_total_comp_qty       ORDLOC.QTY_ORDERED%TYPE;
   L_order_no             ORDHEAD.ORDER_NO%TYPE;
   L_item                 ITEM_MASTER.ITEM%TYPE;
   L_comp_item            ITEM_MASTER.ITEM%TYPE;
   L_child_item           ITEM_MASTER.ITEM%TYPE;
   L_location             ORDLOC.LOCATION%TYPE;
   L_supplier             SUPS.SUPPLIER%TYPE;
   L_origin_country_id    COUNTRY.COUNTRY_ID%TYPE;
   L_temp_qty             ALC_HEAD.ALC_QTY%TYPE;
   L_standard_uom         UOM_CLASS.UOM%TYPE;
   L_item_rec_qty_uom     UOM_CLASS.UOM%TYPE;
   L_standard_class       UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor          UOM_CONVERSION.FACTOR%TYPE;
   L_exists               BOOLEAN;
   L_temp_uom             UOM_CLASS.UOM%TYPE;
   L_child_uom             UOM_CLASS.UOM%TYPE;
   L_pack_ind             ITEM_MASTER.PACK_IND%TYPE;
   L_pack_type            ITEM_MASTER.PACK_TYPE%TYPE;
   L_item_level           ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level           ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_sellable_ind         ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind        ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_item            ITEM_MASTER.ITEM%TYPE;
   ---
   L_carton_qty           TRANSPORTATION.CARTON_QTY%TYPE;
   L_tran_item_qty        TRANSPORTATION.ITEM_QTY%TYPE;
   L_gross_wt             TRANSPORTATION.GROSS_WT%TYPE;
   L_net_wt               TRANSPORTATION.NET_WT%TYPE;
   L_cubic                TRANSPORTATION.CUBIC%TYPE;
   L_invoice_amt          TRANSPORTATION.INVOICE_AMT%TYPE;

   cursor C_GET_ITEMS is
      select distinct t.item,
             o.supplier
        from ordhead o,
             transportation t
       where o.order_no              = I_order_no
         and t.order_no              = o.order_no
         and t.container_id          = I_container_id
         and t.vessel_id             = I_vessel_id
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date;

   cursor C_TRAN_CHILD_ITEMS_EXIST is
      select 'Y'
        from trans_sku s,
             transportation t
       where t.transportation_id     = s.transportation_id
         and t.order_no              = I_order_no
         and t.container_id          = I_container_id
         and t.vessel_id             = I_vessel_id
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.item                  = L_item;

   cursor C_GET_TRAN_CHILD_ITEMS is
      select distinct s.item,
             s.quantity qty,
             s.quantity_uom qty_uom
        from trans_sku s,
             transportation t
       where t.transportation_id     = s.transportation_id
         and t.order_no              = I_order_no
         and t.container_id          = I_container_id
         and t.vessel_id             = I_vessel_id
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.item                  = L_item;

   cursor C_GET_ORD_CHILD_ITEMS is
      select o.item,
             SUM(o.qty_received) qty_received,
             SUM(o.qty_ordered) qty_ordered
        from item_master im,
             ordloc o
       where o.order_no = I_order_no
         and im.item     = o.item
         and (im.item_parent = L_item
          or  im.item_grandparent = L_item)
       group by o.item;

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

   cursor C_GET_BL_INVC is
      select distinct bl_awb_id,
             invoice_id
        from transportation
       where vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and container_id          = I_container_id
         and order_no              = I_order_no
         and item                  = L_item;
BEGIN
   if I_alloc_basis_uom is not NULL then
      ---
      -- Loop through the items on transportation and sum the total qty received in the alloc basis uom.
      ---
      FOR C_rec in C_GET_ITEMS LOOP
         L_item              := C_rec.item;
         L_supplier          := C_rec.supplier;
         L_rec_qty           := 0;
         L_item_rec_qty      := 0;
         L_pack_rec_qty      := 0;
         ---
         if ORDER_ITEM_ATTRIB_SQL.GET_ORDER_ITEM_COUNTRY(O_error_message,
                                                         L_exists,
                                                         L_origin_country_id,
                                                         I_order_no,
                                                         L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then
            L_temp_uom := 'EA';
         else
            L_temp_uom := L_uom;
         end if;
         ---
         FOR L_rec in C_GET_BL_INVC LOOP
            if TRANSPORTATION_SQL.GET_QTYS(O_error_message,
                                           L_carton_qty,
                                           L_temp_uom, -- L_carton_qty_uom,
                                           L_tran_item_qty,
                                           L_temp_uom, -- L_tran_item_qty_uom,
                                           L_gross_wt,
                                           L_temp_uom, -- L_gross_wt_uom,
                                           L_net_wt,
                                           L_temp_uom, -- L_net_wt_uom,
                                           L_cubic,
                                           L_temp_uom, -- L_cubic_uom,
                                           L_invoice_amt,
                                           L_supplier,
                                           L_origin_country_id,
                                           I_vessel_id,
                                           I_voyage_flt_id,
                                           I_estimated_depart_date,
                                           I_order_no,
                                           L_item,
                                           I_container_id,
                                           L_rec.bl_awb_id,
                                           L_rec.invoice_id,
                                           NULL,
                                           NULL) = FALSE then
               return FALSE;
            end if;
            ---
            -- Need to determine L_rec_qty.  If item qty is null, use carton qty/supp pack size
            -- if no carton qty use gross wt/supp pack size, then cubic
            if L_tran_item_qty > 0 then
               L_temp_rec_qty := L_tran_item_qty;
            elsif L_carton_qty > 0 then
               L_temp_rec_qty := L_carton_qty;
            elsif L_gross_wt > 0 then
               L_temp_rec_qty := L_gross_wt;
            elsif L_cubic > 0 then
               L_temp_rec_qty := L_cubic;
            elsif L_net_wt > 0 then
               L_temp_rec_qty := L_net_wt;
            else
               L_temp_rec_qty := 0;
            end if;
            ---
            L_rec_qty := L_rec_qty + L_temp_rec_qty;
         END LOOP;
         ---
         if L_pack_type = 'B' then
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
               L_pack_rec_qty := L_pack_rec_qty + (L_rec_qty * L_comp_qty);
            END LOOP;
         else
            L_item_rec_qty := L_rec_qty;
         end if;
         ---
         L_total_rec_qty := L_total_rec_qty + L_item_rec_qty + L_pack_rec_qty;
      END LOOP;
      -- loop through items on transportation
      FOR C_rec in C_GET_ITEMS LOOP
         L_item              := C_rec.item;
         L_supplier          := C_rec.supplier;
         L_item_rec_qty      := 0;
         ---
         if ORDER_ITEM_ATTRIB_SQL.GET_ORDER_ITEM_COUNTRY(O_error_message,
                                                         L_exists,
                                                         L_origin_country_id,
                                                         I_order_no,
                                                         L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                       L_item_level,
                                       L_tran_level,
                                       L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_item_level = L_tran_level then
            L_rec_qty := 0;
            ---
            if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
               return FALSE;
            end if;
            ---
            if L_pack_type = 'B' then
               L_temp_uom := 'EA';
            else
               L_temp_uom := L_uom;
            end if;
            ---
            FOR L_rec in C_GET_BL_INVC LOOP
               if TRANSPORTATION_SQL.GET_QTYS(O_error_message,
                                              L_carton_qty,
                                              L_temp_uom, -- L_carton_qty_uom,
                                              L_tran_item_qty,
                                              L_temp_uom, -- L_tran_item_qty_uom,
                                              L_gross_wt,
                                              L_temp_uom, -- L_gross_wt_uom,
                                              L_net_wt,
                                              L_temp_uom, --  L_net_wt_uom,
                                              L_cubic,
                                              L_temp_uom, -- L_cubic_uom,
                                              L_invoice_amt,
                                              L_supplier,
                                              L_origin_country_id,
                                              I_vessel_id,
                                              I_voyage_flt_id,
                                              I_estimated_depart_date,
                                              I_order_no,
                                              L_item,
                                              I_container_id,
                                              L_rec.bl_awb_id,
                                              L_rec.invoice_id,
                                              NULL,
                                              NULL) = FALSE then
                  return FALSE;
               end if;
               ---
               -- Need to determine L_rec_qty.  If item qty is null, use carton qty/supp pack size
               -- if no carton qty use gross wt/supp pack size, then cubic
               if L_tran_item_qty > 0 then
                  L_temp_rec_qty := L_tran_item_qty;
               elsif L_carton_qty > 0 then
                  L_temp_rec_qty := L_carton_qty;
               elsif L_gross_wt > 0 then
                  L_temp_rec_qty := L_gross_wt;
               elsif L_cubic > 0 then
                  L_temp_rec_qty := L_cubic;
               elsif L_net_wt > 0 then
                  L_temp_rec_qty := L_net_wt;
               else
                  L_temp_rec_qty := 0;
               end if;
               ---
               L_rec_qty := L_rec_qty + L_temp_rec_qty;
            END LOOP;
         end if;
         ---
         if L_pack_type = 'B' then
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
               L_item_rec_qty := L_item_rec_qty + (L_rec_qty * L_comp_qty);
            END LOOP;
         else
            L_item_rec_qty := L_rec_qty;
         end if;
         ---
         if L_item_level = L_tran_level then
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
         else
            L_child_items_exist := 'N';
            ---
            SQL_LIB.SET_MARK('OPEN','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            open C_TRAN_CHILD_ITEMS_EXIST;
            SQL_LIB.SET_MARK('FETCH','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            fetch C_TRAN_CHILD_ITEMS_EXIST into L_child_items_exist;
            SQL_LIB.SET_MARK('CLOSE','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            close C_TRAN_CHILD_ITEMS_EXIST;
            ---
            if L_child_items_exist = 'Y' then
               FOR L_rec in C_GET_TRAN_CHILD_ITEMS LOOP
                  L_child_item         := L_rec.item;
                  L_item_rec_qty     := L_rec.qty;
                  L_item_rec_qty_uom := L_rec.qty_uom;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     I_alloc_basis_uom,
                                     L_item_rec_qty,
                                     L_item_rec_qty_uom,
                                     L_child_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
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
                                                  L_child_item,
                                                  I_comp_id,
                                                  I_alloc_basis_uom,
                                                  L_qty,
                                                  L_act_value) = FALSE then
                     return FALSE;
                  end if;
               END LOOP;
            else
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               FOR L_rec in C_GET_ORD_CHILD_ITEMS LOOP
                  L_child_item         := L_rec.item;
                  L_item_rec_qty     := NVL(L_rec.qty_received, L_rec.qty_ordered);
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     I_alloc_basis_uom,
                                     L_item_rec_qty,
                                     L_standard_uom,
                                     L_child_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
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
                                                  L_child_item,
                                                  I_comp_id,
                                                  I_alloc_basis_uom,
                                                  L_qty,
                                                  L_act_value) = FALSE then
                     return FALSE;
                  end if;
               END LOOP;
            end if;
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
         L_item      := C_rec.item;
         L_supplier  := C_rec.supplier;
         L_item_qty  := 0;
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
         if ORDER_ITEM_ATTRIB_SQL.GET_ORDER_ITEM_COUNTRY(O_error_message,
                                                         L_exists,
                                                         L_origin_country_id,
                                                         I_order_no,
                                                         L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                       L_item_level,
                                       L_tran_level,
                                       L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_item_level = L_tran_level then
            if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                       L_exists,
                                                       L_unit_cost,
                                                       I_order_no,
                                                       L_item,
                                                       L_pack_item,
                                                       L_location) then
               return FALSE;
            end if;
         else
            L_child_items_exist := 'N';
            ---
            SQL_LIB.SET_MARK('OPEN','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            open C_TRAN_CHILD_ITEMS_EXIST;
            SQL_LIB.SET_MARK('FETCH','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            fetch C_TRAN_CHILD_ITEMS_EXIST into L_child_items_exist;
            SQL_LIB.SET_MARK('CLOSE','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            close C_TRAN_CHILD_ITEMS_EXIST;
            ---
            if L_child_items_exist = 'Y' then
               L_unit_cost := 0;
               ---
               FOR L_rec in C_GET_TRAN_CHILD_ITEMS LOOP
                  L_child_item         := L_rec.item;
                  L_item_rec_qty     := L_rec.qty;
                  L_item_rec_qty_uom := L_rec.qty_uom;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     L_standard_uom,
                                     L_item_rec_qty,
                                     L_item_rec_qty_uom,
                                     L_child_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                             L_exists,
                                                             L_unit_cost,
                                                             I_order_no,
                                                             L_child_item,
                                                             L_pack_item,
                                                             L_location) then
                     return FALSE;
                  end if;
                  ---
                  L_unit_cost := L_unit_cost + (L_temp_unit_cost * L_item_rec_qty);
               END LOOP;
            else
               L_unit_cost := 0;
               ---
               FOR L_rec in C_GET_ORD_CHILD_ITEMS LOOP
                  L_child_item         := L_rec.item;
                  L_item_rec_qty     := NVL(L_rec.qty_received, L_rec.qty_ordered);
                  ---
                  if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                             L_exists,
                                                             L_temp_unit_cost,
                                                             I_order_no,
                                                             L_child_item,
                                                             L_pack_item,
                                                             L_location) then
                     return FALSE;
                  end if;
                  ---
                  L_unit_cost := L_unit_cost + (L_temp_unit_cost * L_item_rec_qty);
               END LOOP;
            end if;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then
            L_temp_uom := 'EA';
         else
            L_temp_uom := L_uom;
         end if;
         ---
         FOR L_rec in C_GET_BL_INVC LOOP
            if TRANSPORTATION_SQL.GET_QTYS(O_error_message,
                                           L_carton_qty,
                                           L_temp_uom, -- L_carton_qty_uom,
                                           L_tran_item_qty,
                                           L_temp_uom, -- L_tran_item_qty_uom,
                                           L_gross_wt,
                                           L_temp_uom, -- L_gross_wt_uom,
                                           L_net_wt,
                                           L_temp_uom, -- L_net_wt_uom,
                                           L_cubic,
                                           L_temp_uom, -- L_cubic_uom,
                                           L_invoice_amt,
                                           L_supplier,
                                           L_origin_country_id,
                                           I_vessel_id,
                                           I_voyage_flt_id,
                                           I_estimated_depart_date,
                                           I_order_no,
                                           L_item,
                                           I_container_id,
                                           L_rec.bl_awb_id,
                                           L_rec.invoice_id,
                                           NULL,
                                           NULL) = FALSE then
               return FALSE;
            end if;
            ---
            -- Need to determine L_rec_qty.  If item qty is null, use carton qty/supp pack size
            -- if no carton qty use gross wt/supp pack size, then cubic
            if L_tran_item_qty > 0 then
               L_temp_rec_qty := L_tran_item_qty;
            elsif L_carton_qty > 0 then
               L_temp_rec_qty := L_carton_qty;
            elsif L_gross_wt > 0 then
               L_temp_rec_qty := L_gross_wt;
            elsif L_cubic > 0 then
               L_temp_rec_qty := L_cubic;
            elsif L_net_wt > 0 then
               L_temp_rec_qty := L_net_wt;
            else
               L_temp_rec_qty := 0;
            end if;
            ---
            L_item_qty := L_item_qty + L_temp_rec_qty;
         END LOOP;
         ---
         if L_pack_type = 'B' then
            L_item_rec_qty := 0;
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
               L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_item_qty);
            END LOOP;
         else
            L_item_rec_qty := L_item_qty;
            ---
            if UOM_SQL.CONVERT(O_error_message,
                               L_item_qty,
                               L_standard_uom,
                               L_item_qty,
                               L_uom,
                               L_item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         if L_item_level = L_tran_level then
            L_total_rec_cost := L_total_rec_cost + (L_item_qty * L_unit_cost);
         else
            L_total_rec_cost := L_total_rec_cost + L_unit_cost;
         end if;
         ---
         L_total_rec_qty := L_total_rec_qty + L_item_rec_qty;
      END LOOP;
      ---
      L_item_rec_qty := 0;
      ---
      FOR C_rec in C_GET_ITEMS LOOP
         L_item              := C_rec.item;
         L_supplier          := C_rec.supplier;
         L_item_qty          := 0;
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
         if ORDER_ITEM_ATTRIB_SQL.GET_ORDER_ITEM_COUNTRY(O_error_message,
                                                         L_exists,
                                                         L_origin_country_id,
                                                         I_order_no,
                                                         L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                       L_item_level,
                                       L_tran_level,
                                       L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_item_level = L_tran_level then
            if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                       L_exists,
                                                       L_unit_cost,
                                                       I_order_no,
                                                       L_item,
                                                       L_pack_item,
                                                       L_location) then
               return FALSE;
            end if;
            ---
            if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                             L_pack_ind,
                                             L_sellable_ind,
                                             L_orderable_ind,
                                             L_pack_type,
                                             L_item) = FALSE then
               return FALSE;
            end if;
            ---
            if L_pack_type = 'B' then
               L_temp_uom := 'EA';
            else
               L_temp_uom := L_uom;
            end if;
            ---
            FOR L_rec in C_GET_BL_INVC LOOP
               if TRANSPORTATION_SQL.GET_QTYS(O_error_message,
                                              L_carton_qty,
                                              L_temp_uom, -- L_carton_qty_uom,
                                              L_tran_item_qty,
                                              L_temp_uom, -- L_tran_item_qty_uom,
                                              L_gross_wt,
                                              L_temp_uom, -- L_gross_wt_uom,
                                              L_net_wt,
                                              L_temp_uom, -- L_net_wt_uom,
                                              L_cubic,
                                              L_temp_uom, -- L_cubic_uom,
                                              L_invoice_amt,
                                              L_supplier,
                                              L_origin_country_id,
                                              I_vessel_id,
                                              I_voyage_flt_id,
                                              I_estimated_depart_date,
                                              I_order_no,
                                              L_item,
                                              I_container_id,
                                              L_rec.bl_awb_id,
                                              L_rec.invoice_id,
                                              NULL,
                                              NULL) = FALSE then
                  return FALSE;
               end if;
               ---
               -- Need to determine L_rec_qty.  If item qty is null, use carton qty/supp pack size
               -- if no carton qty use gross wt/supp pack size, then cubic
               if L_tran_item_qty > 0 then
                  L_temp_rec_qty := L_tran_item_qty;
               elsif L_carton_qty > 0 then
                  L_temp_rec_qty := L_carton_qty;
               elsif L_gross_wt > 0 then
                  L_temp_rec_qty := L_gross_wt;
               elsif L_cubic > 0 then
                  L_temp_rec_qty := L_cubic;
               elsif L_net_wt > 0 then
                  L_temp_rec_qty := L_net_wt;
               else
                  L_temp_rec_qty := 0;
               end if;
               ---
               L_item_qty := L_item_qty + L_temp_rec_qty;
            END LOOP;
         end if;
         ---
         if L_pack_type = 'B' then
            L_item_rec_qty := 0;
            FOR C_rec in C_GET_PACKITEMS LOOP
               L_comp_item     := C_rec.item;
               L_comp_rec_qty  := C_rec.qty;
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
               L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_item_qty);
            END LOOP;
         else
            L_item_rec_qty := L_item_qty;
            ---
            if UOM_SQL.CONVERT(O_error_message,
                               L_item_qty,
                               L_standard_uom,
                               L_item_qty,
                               L_uom,
                               L_item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         if L_item_level = L_tran_level then
            if L_total_rec_cost = 0 or L_total_rec_qty = 0 then
               L_amt_prim := 0;
               L_qty      := 0;
            else
               -- calculate: expense amt * (qty / total qty) and qty * (qty / total qty)
               L_amt_prim := I_amt_prim * ((L_item_qty * L_unit_cost) / L_total_rec_cost);
               L_qty      := I_qty      *  (L_item_rec_qty            / L_total_rec_qty);
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
         else
            L_child_items_exist := 'N';
            ---
            SQL_LIB.SET_MARK('OPEN','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            open C_TRAN_CHILD_ITEMS_EXIST;
            SQL_LIB.SET_MARK('FETCH','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            fetch C_TRAN_CHILD_ITEMS_EXIST into L_child_items_exist;
            SQL_LIB.SET_MARK('CLOSE','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            close C_TRAN_CHILD_ITEMS_EXIST;
            ---
            if L_child_items_exist = 'Y' then
               FOR L_rec in C_GET_TRAN_CHILD_ITEMS LOOP
                  L_child_item := L_rec.item;
                  L_child_item_qty := L_rec.qty;
                  L_child_uom := L_rec.qty_uom;
                  ---
                  if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                             L_exists,
                                                             L_unit_cost,
                                                             I_order_no,
                                                             L_child_item,
                                                             L_pack_item,
                                                             L_location) then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     L_uom,
                                     L_child_item_qty,
                                     L_child_uom,
                                     L_child_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_qty,
                                     L_standard_uom,
                                     L_child_item_qty,
                                     L_child_uom,
                                     L_child_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if L_total_rec_qty = 0 or L_total_rec_cost = 0 then
                     L_amt_prim := 0;
                     L_qty      := 0;
                  else
                     -- calculate: expense amt * (qty / total qty) and qty * (qty / total qty)
                     L_amt_prim := I_amt_prim * ((L_item_rec_qty * L_unit_cost) / L_total_rec_cost);
                     L_qty      := I_qty      *  (L_item_rec_qty                / L_total_rec_qty);
                  end if;
                  ---
                  if TRAN_ALLOC_SQL.ALLOC_PO_ITEM(O_error_message,
                                                  I_obligation_key,
                                                  I_obligation_level,
                                                  I_vessel_id,
                                                  I_voyage_flt_id,
                                                  I_estimated_depart_date,
                                                  I_order_no,
                                                  L_child_item,
                                                  I_comp_id,
                                                  I_alloc_basis_uom,
                                                  L_qty,
                                                  L_amt_prim) = FALSE then
                     return FALSE;
                  end if;
               END LOOP;
            else
               FOR L_rec in C_GET_ORD_CHILD_ITEMS LOOP
                  L_child_item  := L_rec.item;
                  L_item_qty  := NVL(L_rec.qty_received, L_rec.qty_ordered);
                  ---
                  if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                             L_exists,
                                                             L_unit_cost,
                                                             I_order_no,
                                                             L_child_item,
                                                             L_pack_item,
                                                             L_location) then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     L_uom,
                                     L_item_qty,
                                     L_standard_uom,
                                     L_child_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if L_total_rec_qty = 0 or L_total_rec_cost = 0 then
                     L_amt_prim := 0;
                     L_qty      := 0;
                  else
                     -- calculate: expense amt * (qty / total qty) and qty * (qty / total qty)
                     L_amt_prim := I_amt_prim * ((L_item_qty * L_unit_cost) / L_total_rec_cost);
                     L_qty      := I_qty      *  (L_item_rec_qty            / L_total_rec_qty);
                  end if;
                  ---
                  if TRAN_ALLOC_SQL.ALLOC_PO_ITEM(O_error_message,
                                                  I_obligation_key,
                                                  I_obligation_level,
                                                  I_vessel_id,
                                                  I_voyage_flt_id,
                                                  I_estimated_depart_date,
                                                  I_order_no,
                                                  L_child_item,
                                                  I_comp_id,
                                                  I_alloc_basis_uom,
                                                  L_qty,
                                                  L_amt_prim) = FALSE then
                     return FALSE;
                  end if;
               END LOOP;
            end if;
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
FUNCTION ALLOC_CONTAINER(O_error_message         IN OUT VARCHAR2,
                         I_obligation_key        IN     OBLIGATION.OBLIGATION_KEY%TYPE,
                         I_obligation_level      IN     OBLIGATION.OBLIGATION_LEVEL%TYPE,
                         I_container_id          IN     TRANSPORTATION.CONTAINER_ID%TYPE,
                         I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                         I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                         I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                         I_comp_id               IN     ELC_COMP.COMP_ID%TYPE,
                         I_alloc_basis_uom       IN     UOM_CLASS.UOM%TYPE,
                         I_qty                   IN     OBLIGATION_COMP.QTY%TYPE,
                         I_amt_prim              IN     OBLIGATION_COMP.AMT%TYPE,
                         I_order_no              IN     ORDHEAD.ORDER_NO%TYPE DEFAULT NULL)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)                        := 'CO_ALLOC_SQL.ALLOC_CONTAINER';
   L_child_items_exist    VARCHAR2(1)                         := 'N';
   L_order_no           ORDHEAD.ORDER_NO%TYPE;
   L_item               ITEM_MASTER.ITEM%TYPE;
   L_child_item           ITEM_MASTER.ITEM%TYPE;
   L_supplier           SUPS.SUPPLIER%TYPE;
   L_origin_country_id  COUNTRY.COUNTRY_ID%TYPE;
   L_qty                OBLIGATION_COMP.QTY%TYPE;
   L_amt                OBLIGATION_COMP.AMT%TYPE;
   L_container_total    OBLIGATION_COMP.QTY%TYPE            := 0;
   L_ord_item_total     OBLIGATION_COMP.QTY%TYPE            := 0;
   L_carton_qty         TRANSPORTATION.CARTON_QTY%TYPE;
   L_tran_item_qty      TRANSPORTATION.ITEM_QTY%TYPE;
   L_gross_wt           TRANSPORTATION.GROSS_WT%TYPE;
   L_net_wt             TRANSPORTATION.NET_WT%TYPE;
   L_cubic              TRANSPORTATION.CUBIC%TYPE;
   L_invoice_amt        TRANSPORTATION.INVOICE_AMT%TYPE;
   L_unit_cost          ORDLOC.UNIT_COST%TYPE             := 0;
   L_temp_unit_cost     ORDLOC.UNIT_COST%TYPE             := 0;
   L_total_cost         ORDLOC.UNIT_COST%TYPE             := 0;
   L_ord_item_cost      ORDLOC.UNIT_COST%TYPE             := 0;
   L_uom                UOM_CLASS.UOM%TYPE                := I_alloc_basis_uom;
   L_standard_uom       UOM_CLASS.UOM%TYPE;
   L_standard_class     UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor        UOM_CONVERSION.FACTOR%TYPE;
   L_item_rec_qty_uom   UOM_CLASS.UOM%TYPE;
   L_item_rec_qty       ORDLOC.QTY_RECEIVED%TYPE;
   L_temp_uom           UOM_CLASS.UOM%TYPE;
   L_pack_qty           ORDLOC.QTY_RECEIVED%TYPE;
   L_packsku_qty        ORDLOC.QTY_RECEIVED%TYPE;
   L_currency_code_ord  CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_ord  CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_pack_ind           ITEM_MASTER.PACK_IND%TYPE;
   L_pack_type          ITEM_MASTER.PACK_TYPE%TYPE;
   L_sellable_ind       ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind      ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_item_level         ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level         ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_pack_item          ITEM_MASTER.ITEM%TYPE;
   L_exists             BOOLEAN;
   L_location           ITEM_LOC.LOC%TYPE;

   cursor C_GET_QTY_UOM is
      select per_count_uom
        from obligation_comp
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

   cursor C_GET_SUPP_CTRY(L_item ITEM_MASTER.ITEM%TYPE) is
      select o.supplier,
             s.origin_country_id
        from ordhead o,
             ordsku s
       where o.order_no = s.order_no
         and o.order_no = L_order_no
         and s.item     = L_item;

   cursor C_TRAN_CHILD_ITEMS_EXIST is
      select 'Y'
        from trans_sku s,
             transportation t
       where t.transportation_id     = s.transportation_id
         and t.order_no              = L_order_no
         and t.container_id          = I_container_id
         and t.vessel_id             = I_vessel_id
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.item                  = L_item;

   cursor C_GET_TRAN_CHILD_ITEMS is
      select distinct s.item,
             s.quantity qty,
             s.quantity_uom qty_uom
        from trans_sku s,
             transportation t
       where t.transportation_id     = s.transportation_id
         and t.order_no              = L_order_no
         and t.container_id          = I_container_id
         and t.vessel_id             = I_vessel_id
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.item                  = L_item;

   cursor C_GET_ORD_CHILD_ITEMS is
      select o.item,
             SUM(o.qty_received) qty_received,
             SUM(o.qty_ordered) qty_ordered
        from item_master im,
             ordloc o
       where o.order_no = L_order_no
         and im.item     = o.item
         and (im.item_parent = L_item
          or  im.item_grandparent = L_item)
       group by o.item;

   cursor C_GET_PACKITEMS is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

   cursor C_GET_ORD_ITEM is
      select distinct order_no,
             item,
             bl_awb_id,
             invoice_id
        from transportation
       where container_id          = I_container_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = nvl(I_order_no, order_no)
    order by order_no;

   cursor C_GET_ORD is
      select distinct order_no
        from transportation
       where container_id          = I_container_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = nvl(I_order_no, order_no);

   cursor C_GET_DETAIL is
      select distinct item,
             bl_awb_id,
             invoice_id
        from transportation
       where container_id          = I_container_id
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
      L_order_no := C_rec.order_no;
      L_item     := C_rec.item;
      ---
      if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                    L_item_level,
                                    L_tran_level,
                                    L_item) = FALSE then
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
      if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                            L_currency_code_ord,
                                            L_exchange_rate_ord,
                                            L_order_no) = FALSE then
         return FALSE;
      end if;
      ---
      if L_item_level = L_tran_level then
         SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                    ' Item: '||L_item);
         open C_GET_SUPP_CTRY(L_item);
         SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                     ' Item: '||L_item);
         fetch C_GET_SUPP_CTRY into L_supplier,
                                    L_origin_country_id;
         SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                     ' Item: '||L_item);
         close C_GET_SUPP_CTRY;
         ---
         if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                    L_exists,
                                                    L_unit_cost,
                                                    L_order_no,
                                                    L_item,
                                                    L_pack_item,
                                                    L_location) then
            return FALSE;
         end if;
      else
         L_child_items_exist := 'N';
         ---
         SQL_LIB.SET_MARK('OPEN','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
         open C_TRAN_CHILD_ITEMS_EXIST;
         SQL_LIB.SET_MARK('FETCH','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
         fetch C_TRAN_CHILD_ITEMS_EXIST into L_child_items_exist;
         SQL_LIB.SET_MARK('CLOSE','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
         close C_TRAN_CHILD_ITEMS_EXIST;
         ---
         if L_child_items_exist = 'Y' then
            L_unit_cost := 0;
            ---
            FOR L_rec in C_GET_TRAN_CHILD_ITEMS LOOP
               L_child_item         := L_rec.item;
               L_item_rec_qty     := L_rec.qty;
               L_item_rec_qty_uom := L_rec.qty_uom;
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                          ' Item: '||L_child_item);
               open C_GET_SUPP_CTRY(L_child_item);
               SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                           ' Item: '||L_child_item);
               fetch C_GET_SUPP_CTRY into L_supplier,
                                          L_origin_country_id;
               SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                           ' Item: '||L_child_item);
               close C_GET_SUPP_CTRY;
               ---
               if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                          L_exists,
                                                          L_temp_unit_cost,
                                                          L_order_no,
                                                          L_child_item,
                                                          L_pack_item,
                                                          L_location) then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  L_standard_uom,
                                  L_item_rec_qty,
                                  L_item_rec_qty_uom,
                                  L_child_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               L_unit_cost := L_unit_cost + (L_temp_unit_cost * L_item_rec_qty);
            END LOOP;
         else
            L_unit_cost := 0;
            ---
            FOR L_rec in C_GET_ORD_CHILD_ITEMS LOOP
               L_child_item         := L_rec.item;
               L_item_rec_qty     := NVL(L_rec.qty_received, L_rec.qty_ordered);
               ---
               if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                          L_exists,
                                                          L_temp_unit_cost,
                                                          L_order_no,
                                                          L_child_item,
                                                          L_pack_item,
                                                          L_location) then
                  return FALSE;
               end if;
               ---
               L_unit_cost := L_unit_cost + (L_temp_unit_cost * L_item_rec_qty);
            END LOOP;
         end if;
      end if;
      ---
      if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                       L_pack_ind,
                                       L_sellable_ind,
                                       L_orderable_ind,
                                       L_pack_type,
                                       L_item) = FALSE then
         return FALSE;
      end if;
      ---
      if L_pack_type = 'B' then
         L_temp_uom := 'EA';
      else
         L_temp_uom := L_uom;
      end if;
      ---
      if TRANSPORTATION_SQL.GET_QTYS(O_error_message,
                                     L_carton_qty,
                                     L_temp_uom, -- L_carton_qty_uom,
                                     L_tran_item_qty,
                                     L_temp_uom, -- L_tran_item_qty_uom,
                                     L_gross_wt,
                                     L_temp_uom, -- L_gross_wt_uom,
                                     L_net_wt,
                                     L_temp_uom, -- L_net_wt_uom,
                                     L_cubic,
                                     L_temp_uom, -- L_cubic_uom,
                                     L_invoice_amt,
                                     L_supplier,
                                     L_origin_country_id,
                                     I_vessel_id,
                                     I_voyage_flt_id,
                                     I_estimated_depart_date,
                                     C_rec.order_no,
                                     C_rec.item,
                                     I_container_id,
                                     C_rec.bl_awb_id,
                                     C_rec.invoice_id,
                                     NULL,
                                     NULL) = FALSE then
         return FALSE;
      end if;
      ---
      -- Need to determine L_qty.  If item qty is null, use carton qty
      -- if no carton qty use gross wt, then cubic, net wt
      ---
      if L_tran_item_qty > 0 then
         L_qty := L_tran_item_qty;
      elsif L_carton_qty > 0 then
         L_qty := L_carton_qty;
      elsif L_gross_wt > 0 then
         L_qty := L_gross_wt;
      elsif L_cubic > 0 then
         L_qty := L_cubic;
      elsif L_net_wt > 0 then
         L_qty := L_net_wt;
      else
         L_qty := 0;
      end if;
      ---
      if L_pack_type = 'B' then
         L_pack_qty := 0;
         ---
         FOR C_rec in C_GET_PACKITEMS LOOP
            L_packsku_qty := C_rec.qty;
            ---
            if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                L_standard_uom,
                                                L_standard_class,
                                                L_conv_factor,
                                                C_rec.item,
                                                'N') = FALSE then
               return FALSE;
            end if;
            ---
            if UOM_SQL.CONVERT(O_error_message,
                               L_packsku_qty,
                               L_uom,
                               L_packsku_qty,
                               L_standard_uom,
                               C_rec.item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            L_pack_qty := L_pack_qty + (L_qty * L_packsku_qty);
         END LOOP;
         L_item_rec_qty := L_pack_qty;
      else
         L_item_rec_qty := L_qty;
         ---
         if UOM_SQL.CONVERT(O_error_message,
                            L_qty,
                            L_standard_uom,
                            L_qty,
                            L_uom,
                            L_item,
                            L_supplier,
                            L_origin_country_id) = FALSE then
            return FALSE;
         end if;
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
      L_container_total := L_container_total + L_item_rec_qty;
      ---
      if L_item_level = L_tran_level then
         L_total_cost   := L_total_cost   + (L_unit_cost * L_qty);
      else
         L_total_cost   := L_total_cost   + L_unit_cost;
      end if;
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
         L_item := L_rec.item;
         ---
         if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                       L_item_level,
                                       L_tran_level,
                                       L_item) = FALSE then
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
         if L_item_level = L_tran_level then
            SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                       ' Item: '||L_item);
            open C_GET_SUPP_CTRY(L_item);
            SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                        ' Item: '||L_item);
            fetch C_GET_SUPP_CTRY into L_supplier,
                                       L_origin_country_id;
            SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                        ' Item: '||L_item);
            close C_GET_SUPP_CTRY;
            ---
            if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                       L_exists,
                                                       L_unit_cost,
                                                       L_order_no,
                                                       L_item,
                                                       L_pack_item,
                                                       L_location) then
               return FALSE;
            end if;
         else
            L_child_items_exist := 'N';
            ---
            SQL_LIB.SET_MARK('OPEN','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            open C_TRAN_CHILD_ITEMS_EXIST;
            SQL_LIB.SET_MARK('FETCH','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            fetch C_TRAN_CHILD_ITEMS_EXIST into L_child_items_exist;
            SQL_LIB.SET_MARK('CLOSE','C_TRAN_CHILD_ITEMS_EXIST','TRANS_SKU, TRANSPORTATION',NULL);
            close C_TRAN_CHILD_ITEMS_EXIST;
            ---
            if L_child_items_exist = 'Y' then
               L_unit_cost := 0;
               ---
               FOR L_rec in C_GET_TRAN_CHILD_ITEMS LOOP
                  L_child_item         := L_rec.item;
                  L_item_rec_qty     := L_rec.qty;
                  L_item_rec_qty_uom := L_rec.qty_uom;
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                             ' Item: '||L_child_item);
                  open C_GET_SUPP_CTRY(L_child_item);
                  SQL_LIB.SET_MARK('FETCH','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                              ' Item: '||L_child_item);
                  fetch C_GET_SUPP_CTRY into L_supplier,
                                             L_origin_country_id;
                  SQL_LIB.SET_MARK('CLOSE','C_GET_SUPP_CTRY','ORDHEAD,ORDSKU','Order No: '||to_char(L_order_no)||
                                                                              ' Item: '||L_child_item);
                  close C_GET_SUPP_CTRY;
                  ---
                  if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                             L_exists,
                                                             L_temp_unit_cost,
                                                             L_order_no,
                                                             L_child_item,
                                                             L_pack_item,
                                                             L_location) then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     L_standard_uom,
                                     L_item_rec_qty,
                                     L_item_rec_qty_uom,
                                     L_child_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  L_unit_cost := L_unit_cost + (L_temp_unit_cost * L_item_rec_qty);
               END LOOP;
            else
               L_unit_cost := 0;
               ---
               FOR L_rec in C_GET_ORD_CHILD_ITEMS LOOP
                  L_child_item         := L_rec.item;
                  L_item_rec_qty     := NVL(L_rec.qty_received, L_rec.qty_ordered);
                  ---
                  if not ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                             L_exists,
                                                             L_temp_unit_cost,
                                                             L_order_no,
                                                             L_child_item,
                                                             L_pack_item,
                                                             L_location) then
                     return FALSE;
                  end if;
                  L_unit_cost := L_unit_cost + (L_temp_unit_cost * L_item_rec_qty);
               END LOOP;
            end if;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_type = 'B' then
            L_temp_uom := 'EA';
         else
            L_temp_uom := L_uom;
         end if;
         ---
         if TRANSPORTATION_SQL.GET_QTYS(O_error_message,
                                        L_carton_qty,
                                        L_temp_uom, -- L_carton_qty_uom,
                                        L_tran_item_qty,
                                        L_temp_uom, -- L_tran_item_qty_uom,
                                        L_gross_wt,
                                        L_temp_uom, -- L_gross_wt_uom,
                                        L_net_wt,
                                        L_temp_uom, -- L_net_wt_uom,
                                        L_cubic,
                                        L_temp_uom, -- L_cubic_uom,
                                        L_invoice_amt,
                                        L_supplier,
                                        L_origin_country_id,
                                        I_vessel_id,
                                        I_voyage_flt_id,
                                        I_estimated_depart_date,
                                        L_order_no,
                                        L_rec.item,
                                        I_container_id,
                                        L_rec.bl_awb_id,
                                        L_rec.invoice_id,
                                        NULL,
                                        NULL) = FALSE then
            return FALSE;
         end if;
         ---
         -- Need to determine L_qty.  If item qty is null, use carton qty
         -- if no carton qty use gross wt, then cubic, net wt
         ---
         if L_tran_item_qty > 0 then
            L_qty := L_tran_item_qty;
         elsif L_carton_qty > 0 then
            L_qty := L_carton_qty;
         elsif L_gross_wt > 0 then
            L_qty := L_gross_wt;
         elsif L_cubic > 0 then
            L_qty := L_cubic;
         elsif L_net_wt > 0 then
            L_qty := L_net_wt;
         else
            L_qty := 0;
         end if;
         ---
         if L_pack_type = 'B' then
            L_pack_qty := 0;
            ---
            FOR C_rec in C_GET_PACKITEMS LOOP
               L_packsku_qty := C_rec.qty;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   C_rec.item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_packsku_qty,
                                  L_uom,
                                  L_packsku_qty,
                                  L_standard_uom,
                                  C_rec.item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               L_pack_qty := L_pack_qty + (L_qty * L_packsku_qty);
            END LOOP;
            L_item_rec_qty := L_pack_qty;
         else
            L_item_rec_qty := L_qty;
            ---
            if UOM_SQL.CONVERT(O_error_message,
                               L_qty,
                               L_standard_uom,
                               L_qty,
                               L_uom,
                               L_item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         L_ord_item_total := L_ord_item_total + L_item_rec_qty;
         ---
         if L_item_level = L_tran_level then
            L_ord_item_cost  := L_ord_item_cost + (L_unit_cost * L_qty);
         else
            L_ord_item_cost  := L_ord_item_cost + L_unit_cost;
         end if;
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
      if L_container_total = 0 or L_total_cost = 0 then
         L_qty := 0;
         L_amt := 0;
      else
         L_qty := I_qty * (L_ord_item_total / L_container_total);
         ---
         if I_alloc_basis_uom is not NULL then
            L_amt := I_amt_prim * (L_ord_item_total / L_container_total);
         else
            L_amt := I_amt_prim * (L_ord_item_cost  / L_total_cost);
         end if;
      end if;
      ---
      if ALLOC_PO(O_error_message,
                  I_obligation_key,
                  I_obligation_level,
                  I_container_id,
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
END ALLOC_CONTAINER;
------------------------------------------------------------------------------------
END CO_ALLOC_SQL;
/

