CREATE OR REPLACE PACKAGE BODY ALLOC_ATTRIB_SQL AS
------------------------------------------------------------
   LP_table        VARCHAR2(15);
   LP_exception_id NUMBER(1);
   LP_sdate        DATE          := SYSDATE;
   LP_user         VARCHAR2(50)  := USER;
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

/*** Private Function Declarations ***/
-------------------------------------------------------------------------------
-- Name:    REINSTATE_ALLOC
-- Purpose: Calls a function to update the reserved qty and
--          expected qty's for an entire alloc_no by calling
--          UPD_ITEM_RESV_EXP for each alloc_detail on the alloc_no.  Then
--          sets the alloc header status to 'C'losed.
-------------------------------------------------------------------------------
FUNCTION REINSTATE_ALLOC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE)
   RETURN BOOLEAN;

/*** Function Bodies ***/

---------------------------------------------------------------------------------
FUNCTION ALLOC_DESC(O_error_message IN OUT VARCHAR2,
                    I_alloc         IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                    O_alloc_desc    IN OUT ALLOC_HEADER.ALLOC_DESC%TYPE)
   RETURN BOOLEAN IS

   cursor C_ATTRIB is
      select alloc_desc
        from alloc_header
       where alloc_no = I_alloc;

BEGIN

   SQL_LIB.SET_MARK('OPEN' , 'C_ATTRIB', 'ALLOC_HEADER', to_char(I_alloc));
   open C_ATTRIB;
   SQL_LIB.SET_MARK('FETCH' , 'C_ATTRIB', 'ALLOC_HEADER', to_char(I_alloc));
   fetch C_ATTRIB into O_alloc_desc;
   if C_ATTRIB%notfound then
      O_error_message := sql_lib.create_msg('INV_ALLOC_NUM',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE' , 'C_ATTRIB', 'ALLOC_HEADER', to_char(I_alloc));
      close C_ATTRIB;
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE' , 'C_ATTRIB', 'ALLOC_HEADER', to_char(I_alloc));
   close C_ATTRIB;

   if LANGUAGE_SQL.TRANSLATE(O_alloc_desc,
                             O_alloc_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ALLOC_ATTRIB_SQL.ALLOC_DESC',
                                            to_char(SQLCODE));
   return FALSE;
END ALLOC_DESC;
-------------------------------------------------------------------
FUNCTION GET_HEADER_INFO(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                         O_order_no      IN OUT ORDHEAD.ORDER_NO%TYPE,
                         O_wh            IN OUT WH.WH%TYPE,
                         O_item          IN OUT ITEM_MASTER.ITEM%TYPE,
                         O_status        IN OUT ALLOC_HEADER.STATUS%TYPE,
                         O_alloc_desc    IN OUT ALLOC_HEADER.ALLOC_DESC%TYPE)
   RETURN BOOLEAN IS

   cursor C_HEADER is
      select order_no,
             wh,
             item,
             status,
             alloc_desc
        from alloc_header
       where alloc_no = I_alloc_no;

BEGIN
   open C_HEADER;
   fetch C_HEADER into  O_order_no,
         O_wh,
         O_item,
         O_status,
         O_alloc_desc;
   if C_HEADER%NOTFOUND then
      close C_HEADER;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ALLOC_NUM',
                     null,null,null);
      return FALSE;
   end if;
   ---
   close C_HEADER;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_alloc_desc,
                             O_alloc_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ALLOC_ATTRIB_SQL.GET_HEADER_INFO',
                                            to_char(SQLCODE));
   return FALSE;
END GET_HEADER_INFO;
--------------------------------------------------------------------
FUNCTION DECODE_STATUS(O_error_message IN OUT   VARCHAR2,
             I_status_ind    IN  VARCHAR2,
                       O_status_decode IN OUT   VARCHAR2)
   RETURN BOOLEAN IS
BEGIN

   if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                 'ALST',
                                 I_status_ind,
                                 O_status_decode) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ALLOC_ATTRIB_SQL.DECODE_STATUS',
                                            to_char(SQLCODE));
      return FALSE;
END DECODE_STATUS;
--------------------------------------------------------------------
FUNCTION GET_TOTAL_QTY_ALLOC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                             O_total_qty     IN OUT NUMBER)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'ALLOC_ATTRIB_SQL.GET_TOTAL_QTY_ALLOC';

   cursor C_GET_QTY is
      select sum(nvl(qty_allocated,0))
        from alloc_detail
       where alloc_no = I_alloc_no;

BEGIN
   open C_GET_QTY;
   fetch C_GET_QTY into O_total_qty;
   if C_GET_QTY%NOTFOUND then
      close C_GET_QTY;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ALLOC_NUM',
                     null,null,null);
      return FALSE;
   end if;
   close C_GET_QTY;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TOTAL_QTY_ALLOC;
--------------------------------------------------------------------
FUNCTION GET_TOTAL_QTY_TSF(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                           O_total_qty     IN OUT NUMBER)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'ALLOC_ATTRIB_SQL.GET_TOTAL_QTY_ALLOC';

   cursor C_GET_QTY is
   select   sum(nvl(qty_transferred,0))
   from  alloc_detail
   where alloc_no = I_alloc_no;

BEGIN
   open C_GET_QTY;
   fetch C_GET_QTY into O_total_qty;
   if C_GET_QTY%NOTFOUND then
      close C_GET_QTY;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ALLOC_NUM',
                     null,null,null);
      return FALSE;
   end if;
   close C_GET_QTY;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TOTAL_QTY_TSF;
--------------------------------------------------------------------
FUNCTION GET_OTHER_ALLOC_QTY(O_error_message IN OUT VARCHAR2,
                             I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                             I_order_no      IN     ORDHEAD.ORDER_NO%TYPE,
                             I_wh            IN     WH.WH%TYPE,
                             I_item          IN     ITEM_MASTER.ITEM%TYPE,
                             O_qty_alloc     IN OUT ALLOC_DETAIL.QTY_ALLOCATED%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ALLOC_ATTRIB_SQL.GET_ORD_ITEM_ALLOC';

   cursor C_GET_QTY is
      select sum(qty_allocated)
        from alloc_detail d,
             alloc_header h
       where h.order_no  = I_order_no
         and h.wh        = I_wh
         and h.item      = I_item
         and h.status    = 'A'
         and h.alloc_no != I_alloc_no
         and d.alloc_no  = h.alloc_no;

BEGIN
   open C_GET_QTY;
   fetch C_GET_QTY into O_qty_alloc;
   if C_GET_QTY%NOTFOUND then
      close C_GET_QTY;
      O_qty_alloc := 0;
   else
      close C_GET_QTY;
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
END GET_OTHER_ALLOC_QTY;
-------------------------------------------------------------------------------------
FUNCTION CHECK_IN_PROGRESS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_in_progress    IN OUT VARCHAR2,
                           I_alloc_no       IN     ALLOC_HEADER.ALLOC_NO%TYPE)
   RETURN BOOLEAN IS

   L_dummy   VARCHAR2(1);

   cursor C_CHECK_IN_PROGRESS is
      select 'x'
        from alloc_detail
       where (nvl(qty_distro, 0) != 0
             or nvl(qty_selected, 0) != 0)
         and alloc_no = I_alloc_no;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_CHECK_IN_PROGRESS','ALLOC_DETAIL', NULL);
   open C_CHECK_IN_PROGRESS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_IN_PROGRESS','ALLOC_DETAIL', NULL);
   fetch C_CHECK_IN_PROGRESS into L_dummy;
   ---
   if C_CHECK_IN_PROGRESS%NOTFOUND then
      O_in_progress := 'N';
   else
      O_in_progress := 'Y';
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_IN_PROGRESS','ALLOC_DETAIL',NULL);
   close  C_CHECK_IN_PROGRESS;
   ---
   return TRUE;


EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ALLOC_ATTRIB_SQL.CHECK_IN_PROGRESS',
                                            to_char(SQLCODE));
      RETURN FALSE;
END CHECK_IN_PROGRESS;
-------------------------------------------------------------------------------------
FUNCTION UPD_QTYS_WHEN_CLOSE(O_error_message IN OUT VARCHAR2,
                             I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE)
RETURN BOOLEAN IS

   L_pack_no  item_master.item%TYPE := NULL;
   L_from_loc item_loc.loc%TYPE     := NULL;

   L_total_chrgs_prim         item_loc.unit_retail%TYPE := 0;
   L_profit_chrgs_to_loc      item_loc.unit_retail%TYPE := 0;
   L_exp_chrgs_to_loc         item_loc.unit_retail%TYPE := 0;
   L_pack_total_chrgs_prim    item_loc.unit_retail%TYPE := 0;
   L_pack_profit_chrgs_to_loc item_loc.unit_retail%TYPE := 0;
   L_pack_exp_chrgs_to_loc    item_loc.unit_retail%TYPE := 0;
   L_total_chrgs_to           item_loc.unit_retail%TYPE := 0;

   L_from_loc_pack_av_cost    item_loc_soh.av_cost%TYPE := 0;
   L_from_loc_cost            item_loc_soh.unit_cost%TYPE;
   L_from_loc_retail          item_loc.unit_retail%TYPE;
   L_from_selling_unit_retail item_loc.selling_unit_retail%TYPE;
   L_from_selling_uom         item_loc.selling_uom%TYPE;

   cursor C_ALLOC_DETAIL_QTY is
      select ah.item,
             nvl(ad.qty_transferred, 0) - nvl(ad.qty_allocated, 0) upd_qty,
             'W'            from_loc_type,
             ah.wh          from_loc,
             ad.to_loc_type to_loc_type,
             ad.to_loc      to_loc
     from alloc_header ah,
          alloc_detail ad
    where ah.alloc_no                 = I_alloc_no
      and ah.alloc_no                 = ad.alloc_no
      and nvl(ad.qty_transferred, 0)  < nvl(ad.qty_allocated, 0)
      and ah.order_no is NULL;

   cursor C_SHIPSKU_QTY is
      select nvl(ss.qty_expected, 0) ship_qty,
             nvl(ss.qty_received, 0) rcv_qty,
             ss.unit_cost,
             ss.item,
             ss.inv_status,
             ss.seq_no,
             ss.shipment,
             ad.to_loc,
             ad.to_loc_type,
             ah.wh   from_loc,
             'W'     from_loc_type,
             im.pack_ind,
             nvl(im.pack_type,'N') pack_type,
             im.dept,
             im.class,
             im.subclass,
             ah.release_date
        from shipsku ss,
             --join to alloc table since shipsku has phy locs
             alloc_header ah,
             alloc_detail ad,
             item_master im
       where ss.distro_no             = I_alloc_no
         and ah.alloc_no              = ss.distro_no
         and ah.alloc_no              = ad.alloc_no
         and ah.item                  = ss.item
         and nvl(ss.qty_expected, 0)  > nvl(ss.qty_received, 0)
         and ss.item                  = im.item;

   cursor C_ITEM_IN_PACK is
      select v.item      comp_item,
             v.qty       comp_qty,
             ils.av_cost comp_av_cost
        from v_packsku_qty v,
             item_loc_soh ils
       where v.pack_no = L_pack_no
         and ils.loc   = L_from_loc
         and ils.item  = v.item;

BEGIN

   FOR rec in C_ALLOC_DETAIL_QTY LOOP

      if TRANSFER_SQL.UPD_ITEM_RESV_EXP(O_error_message,
                                        rec.item,
                                        'A', --PL transfers are special case
                                        rec.upd_qty,
                                        rec.from_loc_type,
                                        rec.from_loc,
                                        rec.to_loc_type,
                                        rec.to_loc) = FALSE then
         return FALSE;
      end if;

   END LOOP;

   FOR rec in C_SHIPSKU_QTY LOOP

      if rec.pack_ind = 'N' then

         if UP_CHARGE_SQL.CALC_TSF_ALLOC_ITEM_LOC_CHRGS(
                             O_error_message,
                             L_total_chrgs_prim,
                             L_profit_chrgs_to_loc,
                             L_exp_chrgs_to_loc,
                             'A', --ALLOC
                             I_alloc_no,
                             NULL, --tsf_seq_no
                             NULL, --shipment
                             NULL, --shipsku.seq_no
                             rec.item,
                             NULL,           --pack_no
                             rec.from_loc,
                             rec.from_loc_type,
                             rec.to_loc,
                             rec.to_loc_type) = FALSE then
            return FALSE;
         end if;

         --the alloc was not fully received, update the sending
         --loc's soh by the qty that was not shipped buy not received
         if TRANSFER_SQL.UPDATE_FROM_LOC_ON_SHORTAGE(
                                        O_error_message,
                                        rec.item,
                                        'I',  --ITEM
                                        rec.inv_status,
                                        rec.ship_qty - rec.rcv_qty,
                                        rec.from_loc,
                                        rec.from_loc_type) = FALSE then
            return FALSE;
         end if;

         --write tran_data records to back out any non-received qty.  the full
         --qty is written to tran_data as if received when the tsf is shipped.
         if TRANSFER_SQL.TRAN_DATA_WRITES(
                             O_error_message,
                             I_alloc_no,
                             rec.item,
                             rec.dept,
                             rec.class,
                             rec.subclass,
                             rec.to_loc,
                             rec.to_loc_type,
                             rec.from_loc,
                             rec.from_loc_type,
                             rec.unit_cost,
                             rec.release_date,
                             rec.rcv_qty - rec.ship_qty,
                             L_profit_chrgs_to_loc,
                             L_exp_chrgs_to_loc) = FALSE then
            return FALSE;
         end if;

         --Shipment not fully received, decrement the intran qty and average cost
         --at the to loc.  Av_cost is updated at shiptime to reflect the full amount
         --being receivied.  For a item, the shipsku.unit_cost contains charges so don't
         --add the charges in again.
         if TRANSFER_SQL.UPD_INTRAN_AND_COST(
                                O_error_message,
                                rec.item,
                                'I',   --ITEM
                                NULL,
                                rec.to_loc,
                                rec.to_loc_type,
                                rec.from_loc,
                                rec.from_loc_type,
                                rec.rcv_qty - rec.ship_qty,
                                rec.unit_cost,
                                0) = FALSE then  --charges
            return FALSE;
         end if;

      else --item is a pack

         if rec.pack_type != 'B' then
            --if vendor pack, returns charges at the pack level
            if UP_CHARGE_SQL.CALC_TSF_ALLOC_ITEM_LOC_CHRGS(
                                O_error_message,
                                L_pack_total_chrgs_prim,
                                L_pack_profit_chrgs_to_loc,
                                L_pack_exp_chrgs_to_loc,
                                'A', --ALLOC
                                I_alloc_no,
                                NULL,           --tsf_seq_no,
                                NULL,           --shipment
                                NULL,           --ss_seq_no,
                                rec.item,       --item (send pack in item field)
                                NULL,           --pack_no
                                rec.from_loc,
                                rec.from_loc_type,
                                rec.to_loc,
                                rec.to_loc_type) = FALSE then
               return FALSE;
            end if;

            --get pack's average cost for use in proration of charges
            if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message,
                                                        rec.item,
                                                        rec.from_loc,
                                                        rec.from_loc_type,
                                                        L_from_loc_pack_av_cost,
                                                        L_from_loc_cost,
                                                        L_from_loc_retail,
                                                        L_from_selling_unit_retail,
                                                        L_from_selling_uom) = FALSE then
               return FALSE;
            end if;

         end if;

         --the alloc was not fully received, update the sending
         --loc's soh by the qty that was not shipped buy not received
         if TRANSFER_SQL.UPDATE_FROM_LOC_ON_SHORTAGE(
                                        O_error_message,
                                        rec.item,
                                        'P', --PACK
                                        rec.inv_status,
                                        rec.ship_qty - rec.rcv_qty,
                                        rec.from_loc,
                                        rec.from_loc_type) = FALSE then
            return FALSE;
         end if;

         --Shipment not fully received, decrement the intran qty and average cost
         --at the to loc.  For a pack, av_cost is not updated, don't send
         -- av_cost or charges.
         if TRANSFER_SQL.UPD_INTRAN_AND_COST(
                                O_error_message,
                                rec.item,
                                'P',             --PACK
                                NULL,
                                rec.to_loc,
                                rec.to_loc_type,
                                rec.from_loc,
                                rec.from_loc_type,
                                rec.rcv_qty - rec.ship_qty,
                                0,               --AV_COST
                                0) = FALSE then  --CHARGES
            return FALSE;
         end if;

         L_pack_no  := rec.item;
         L_from_loc := rec.from_loc;

         FOR comp_rec in C_ITEM_IN_PACK LOOP

           if rec.pack_type != 'B' then

               --prorate the charges calculated at the pack level across the comp items
               --need to use pack's av_cost not on shipsku --it does not have charges in it
               --******************************************************************************
               -- Value returned in L_pack_profit_chrgs_to_loc, L_pack_exp_chrgs_to_loc, and
               -- L_pack_total_chrgs_prim are unit values for the entire pack.  Need to take
               -- a proportionate piece of the value for each component item in the pack
               -- The formula for this is:
               --       [Pack Value * (Comp Item Avg Cost * Comp Qty in the Pack) /
               --                     (Total Pack Avg Cost)] /
               --       Comp Qty in the Pack
               -- You must divide the value by the Component Item Qty in the pack because the
               -- value will be for one pack.  In order to get a true unit value you need to
               -- do the last division.  Since we multiple by Comp Qty and then divide by it,
               -- it can be removed from the calculation completely.
               --******************************************************************************
               L_profit_chrgs_to_loc := L_pack_profit_chrgs_to_loc *
                                        comp_rec.comp_av_cost /
                                        L_from_loc_pack_av_cost;
               L_exp_chrgs_to_loc    := L_pack_exp_chrgs_to_loc *
                                        comp_rec.comp_av_cost /
                                        L_from_loc_pack_av_cost;
               L_total_chrgs_prim    := L_pack_total_chrgs_prim *
                                        comp_rec.comp_av_cost /
                                        L_from_loc_pack_av_cost;
            else

               if UP_CHARGE_SQL.CALC_TSF_ALLOC_ITEM_LOC_CHRGS(
                                   O_error_message,
                                   L_total_chrgs_prim,
                                   L_profit_chrgs_to_loc,
                                   L_exp_chrgs_to_loc,
                                   'A',      --ALLOC
                                   I_alloc_no,
                                   NULL,     --tsf_seq_no
                                   NULL,     --shipment
                                   NULL,     --ss_seq_no
                                   comp_rec.comp_item, --item
                                   rec.item,           --pack_no
                                   rec.from_loc,
                                   rec.from_loc_type,
                                   rec.to_loc,
                                   rec.to_loc_type) = FALSE then
                  return FALSE;
               end if;

            end if;

            --the alloc was not fully received, update the sending
            --loc's soh by the qty that was not shipped buy not received
            if TRANSFER_SQL.UPDATE_FROM_LOC_ON_SHORTAGE(
                                           O_error_message,
                                           comp_rec.comp_item,
                                           'C',
                                           rec.inv_status,
                                           (rec.ship_qty - rec.rcv_qty) * comp_rec.comp_qty,
                                           rec.from_loc,
                                           rec.from_loc_type) = FALSE then
               return FALSE;
            end if;

            --if charge exists convert it to the to currency
            if L_total_chrgs_prim != 0 then
               if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   rec.to_loc,
                                                   rec.to_loc_type,
                                                   NULL,
                                                   L_total_chrgs_prim,
                                                   L_total_chrgs_to,
                                                   'C',
                                                   NULL,
                                                   NULL) = FALSE then
                  return FALSE;
               end if;
            end if;

            --write tran_data records to back out any non-received qty.  the full
            --qty is written to tran_data as if received when the tsf is shipped.
            if TRANSFER_SQL.TRAN_DATA_WRITES(
                                O_error_message,
                                I_alloc_no,
                                comp_rec.comp_item,
                                rec.dept,
                                rec.class,
                                rec.subclass,
                                rec.to_loc,
                                rec.to_loc_type,
                                rec.from_loc,
                                rec.from_loc_type,
                                comp_rec.comp_av_cost,
                                rec.release_date,
                                (rec.rcv_qty - rec.ship_qty) * comp_rec.comp_qty,
                                L_profit_chrgs_to_loc,
                                L_exp_chrgs_to_loc) = FALSE then
               return FALSE;
            end if;

            --Shipment not fully received, decrement the intran qty and average cost
            --at the to loc.  Av_cost is updated at shiptime to reflect the full amount
            --being receivied.
            if TRANSFER_SQL.UPD_INTRAN_AND_COST(
                                   O_error_message,
                                   comp_rec.comp_item,
                                   'C',   --COMP_ITEM
                                   rec.item,
                                   rec.to_loc,
                                   rec.to_loc_type,
                                   rec.from_loc,
                                   rec.from_loc_type,
                                   (rec.rcv_qty - rec.ship_qty) * comp_rec.comp_qty,
                                   comp_rec.comp_av_cost,
                                   L_total_chrgs_to) = FALSE then  --charges
               return FALSE;
            end if;

         END LOOP; --comp items

      end if; --pack

   END LOOP; --shipsku loop

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ALLOC_ATTRIB_SQL.UPD_QTYS_WHEN_CLOSE',
                                            to_char(SQLCODE));
      return FALSE;
END UPD_QTYS_WHEN_CLOSE;
---------------------------------------------------------------------------------
FUNCTION UPD_ALLOC_RESV_EXP(O_error_message   IN OUT  VARCHAR2,
                            I_alloc_no        IN      ALLOC_HEADER.ALLOC_NO%TYPE,
                            I_add_delete_ind  IN      VARCHAR2)
RETURN BOOLEAN IS

   L_program        VARCHAR2(64)                     := 'ALLOC_ATTRIB_SQL.UPD_ALLOC_RESV_EXP';
   L_qty             ALLOC_DETAIL.QTY_ALLOCATED%TYPE;
   L_to_loc          ALLOC_DETAIL.TO_LOC%TYPE;
   L_to_loc_type     ITEM_LOC.LOC_TYPE%TYPE;
   L_from_loc        ALLOC_HEADER.WH%TYPE;
   L_from_loc_type   ITEM_LOC.LOC_TYPE%TYPE           := 'W';

   cursor C_ALLOC_DETAIL is
      select ah.item,
             nvl(ad.qty_allocated, 0) qty_allocated,
             ah.wh from_loc,
             ad.to_loc,
             ad.to_loc_type,
             im.pack_ind
        from alloc_detail ad,
             alloc_header ah,
             item_master im
       where ad.alloc_no = I_alloc_no
         and ad.alloc_no = ah.alloc_no
         and ah.item     = im.item;

BEGIN
   -- loop for each alloc_detail on the alloc_no
   ---
   for rec in C_ALLOC_DETAIL loop
      L_from_loc    := rec.from_loc;
      L_to_loc      := rec.to_loc;
      L_to_loc_type := rec.to_loc_type;
      ---
      if I_add_delete_ind = 'A' then
         L_qty := rec.qty_allocated;
      elsif I_add_delete_ind = 'D' then
         L_qty := (rec.qty_allocated) * (-1);
      end if;
      ---
      if UPD_ITEM_RESV_EXP(O_error_message,
                           rec.item,
                           L_qty,
                           L_from_loc,
                           L_from_loc_type,
                           L_to_loc,
                           L_to_loc_type) = FALSE then
         return FALSE;
      end if;
   end loop;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPD_ALLOC_RESV_EXP;
---------------------------------------------------------------------------------
--Internal Function called by UPD_ITEM_RESV_EXP
---------------------------------------------------------------------------------
FUNCTION UPD_ITEM_RESV(O_error_message IN OUT VARCHAR2,
                       I_item          IN     ITEM_MASTER.ITEM%TYPE,
                       I_pack_ind      IN     ITEM_MASTER.PACK_IND%TYPE,
                       I_from_loc      IN     ALLOC_HEADER.WH%TYPE,
                       I_from_loc_type IN     ITEM_LOC.LOC_TYPE%TYPE,
                       I_allocated_qty IN     ALLOC_DETAIL.QTY_ALLOCATED%TYPE)

   RETURN BOOLEAN IS

   L_program             VARCHAR2(64)  := 'ALLOC_ATTRIB_SQL.UPD_ITEM_RESV';

   cursor C_LOCK_ITEM_LOC_SOH is
      select 'x'
        from item_loc_soh
       where loc      = I_from_loc
         and loc_type = I_from_loc_type
         and item     = I_item
         for update nowait;
BEGIN

/* Assumes that allocations from locs are always whs */

   SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_LOC_SOH','ITEM: '||I_item||'Location: '||to_char(I_from_loc));
   LP_table := 'ITEM_LOC_SOH';
   open C_LOCK_ITEM_LOC_SOH;
   close C_LOCK_ITEM_LOC_SOH;
   ---
   update item_loc_soh
      set tsf_reserved_qty      = decode(I_pack_ind, 'Y', tsf_reserved_qty, tsf_reserved_qty + I_allocated_qty),
          pack_comp_resv        = decode(I_pack_ind, 'Y', pack_comp_resv + I_allocated_qty, pack_comp_resv),
          last_update_datetime  = LP_sdate,
          last_update_id        = LP_user
    where loc      = I_from_loc
      and loc_type = I_from_loc_type
      and item     = I_item;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            LP_table,
                                            to_char(I_from_loc),
                                            I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPD_ITEM_RESV;
---------------------------------------------------------------------------------
--Internal Function called by UPD_ITEM_RESV_EXP
---------------------------------------------------------------------------------
FUNCTION UPD_ITEM_EXP(O_error_message    IN OUT VARCHAR2,
                       I_item            IN     ITEM_MASTER.ITEM%TYPE,
                       I_to_loc          IN     ALLOC_HEADER.WH%TYPE,
                       I_to_loc_type     IN     ITEM_LOC.LOC_TYPE%TYPE,
                       I_allocated_qty   IN     ALLOC_DETAIL.QTY_ALLOCATED%TYPE)

   RETURN BOOLEAN IS

   L_program             VARCHAR2(64)  := 'ALLOC_ATTRIB_SQL.UPD_ITEM_EXP';

   cursor C_LOCK_ITEM_LOC_SOH is
      select 'x'
        from item_loc_soh
       where loc      = I_to_loc
         and loc_type = I_to_loc_type
         and item     = I_item
         for update nowait;
BEGIN

/* Assumes that allocation to locations are always stores */

   SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_LOC_SOH','ITEM: '||I_item||'Location: '||to_char(I_to_loc));
   LP_table := 'ITEM_LOC_SOH';
   open C_LOCK_ITEM_LOC_SOH;
   close C_LOCK_ITEM_LOC_SOH;
   ---
   update item_loc_soh
      set tsf_expected_qty     = tsf_expected_qty + I_allocated_qty,
          last_update_datetime = LP_sdate,
          last_update_id       = LP_user
    where loc      = I_to_loc
      and loc_type = I_to_loc_type
      and item     = I_item;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            LP_table,
                                            to_char(I_to_loc),
                                            I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPD_ITEM_EXP;
---------------------------------------------------------------------------------
FUNCTION UPD_ITEM_RESV_EXP(O_error_message  IN OUT  VARCHAR2,
                           I_item           IN      ALLOC_HEADER.ITEM%TYPE,
                           I_allocated_qty  IN      ALLOC_DETAIL.QTY_ALLOCATED%TYPE,
                           I_from_loc       IN      ALLOC_HEADER.WH%TYPE,
                           I_from_loc_type  IN      ITEM_LOC_SOH.LOC_TYPE%TYPE,
                           I_to_loc         IN      ITEM_LOC_SOH.LOC%TYPE,
                           I_to_loc_type    IN      ITEM_LOC_SOH.LOC_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program             VARCHAR2(64)  := 'ALLOC_ATTRIB_SQL.UPD_ITEM_RESV_EXP';
   L_item_qty            ALLOC_DETAIL.QTY_ALLOCATED%TYPE;
   L_location            ITEM_LOC.LOC%TYPE;
   L_pack_ind            ITEM_MASTER.PACK_IND%TYPE;

   cursor C_ITEMS_IN_PACK IS
     select v.item,
            v.qty
       from v_packsku_qty v,
            item_master im
      where v.pack_no = I_item
        and v.pack_no = im.item
        and im.inventory_ind = 'Y';

   cursor C_LOCK_FROM_ITEM_LOC_SOH is
     select 'X'
       from item_loc_soh
      where loc      = I_from_loc
        and loc_type = 'W'
        and item     =  I_item
        for update nowait;

   cursor C_GET_PACK_IND is
      select pack_ind
        from item_master
        where item = I_item;

BEGIN

/* Assumes that to locs are always stores */

   SQL_LIB.SET_MARK('OPEN', 'C_GET_PACK_IND', 'ITEM_MASTER', 'ITEM:  ' ||(I_item));
   open C_GET_PACK_IND;
   SQL_LIB.SET_MARK('FETCH', 'C_GET_PACK_IND', 'ITEM_MASTER', 'ITEM:  ' ||(I_item));
   fetch C_GET_PACK_IND into L_pack_ind;
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_PACK_IND', 'ITEM_MASTER', 'ITEM:  ' ||(I_item));
   close C_GET_PACK_IND;
   ---
   if L_pack_ind = 'N' then
      if UPD_ITEM_RESV (O_error_message,
                        I_item,
                        L_pack_ind,
                        I_from_loc,
                        I_from_loc_type,
                        I_allocated_qty) = FALSE then
         return FALSE;
      end if;
      ---
      if UPD_ITEM_EXP (O_error_message,
                       I_item,
                       I_to_loc,
                       I_to_loc_type,
                       I_allocated_qty) = FALSE then
         return FALSE;
      end if;
   elsif L_pack_ind = 'Y' then
      L_location := I_from_loc;
      ---
      LP_table   := 'ITEM_LOC_SOH';
      open C_LOCK_FROM_ITEM_LOC_SOH;
      close C_LOCK_FROM_ITEM_LOC_SOH;
      ---
      SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_LOC_SOH', 'ITEM: '||(I_item)||'LOCATION: '||I_from_loc);
      update item_loc_soh
         set tsf_reserved_qty     = tsf_reserved_qty + I_allocated_qty,
             last_update_datetime = LP_sdate,
             last_update_id       = LP_user
       where loc      = I_from_loc
         and loc_type = 'W'
         and item     = I_item;
      ---
      if I_to_loc_type = 'W' then
         if UPD_ITEM_EXP(O_error_message,
                         I_item,
                         I_to_loc,
                         I_to_loc_type,
                         I_allocated_qty) = FALSE then
            return FALSE;
         end if;
      end if;

      for rec in C_ITEMS_IN_PACK loop
         L_item_qty := I_allocated_qty * rec.qty;
         ---
         if UPD_ITEM_RESV(O_error_message,
                          rec.item,
                          L_pack_ind,
                          I_from_loc,
                          I_from_loc_type,
                          L_item_qty) = FALSE then
             return FALSE;
          end if;
          ---
          if UPD_ITEM_EXP(O_error_message,
                          rec.item,
                          I_to_loc,
                          I_to_loc_type,
                          L_item_qty) = FALSE then
              return FALSE;
           end if;
      end loop;
   end if; --end if L_pack_ind = 'Y'

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            LP_table,
                                            to_char(I_from_loc),
                                            I_item);
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPD_ITEM_RESV_EXP;
---------------------------------------------------------------------------------
FUNCTION DELETE_ALLOC_HEADER(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE)
   RETURN BOOLEAN IS

   L_function  VARCHAR2(50)  := 'ALLOC_ATTRIB_SQL.DELETE_ALLOC_HEADER';

   cursor C_LOCK_ALLOC_HEADER is
      select 'x'
        from alloc_header
       where alloc_no = I_alloc_no
         for update nowait;

BEGIN
   LP_table := 'ALLOC_HEADER';
   ---
   open C_LOCK_ALLOC_HEADER;
   close C_LOCK_ALLOC_HEADER;
   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'ALLOC_HEADER','Allocation: '||(I_alloc_no));
   delete from alloc_header
    where alloc_no = I_alloc_no;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END DELETE_ALLOC_HEADER;
-------------------------------------------------------------------------------
FUNCTION CLOSE_ALLOC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE)
   RETURN BOOLEAN IS

   L_function  VARCHAR2(50)  := 'ALLOC_ATTRIB_SQL.CLOSE_ALLOC';

   cursor C_LOCK_ALLOC_HEADER is
      select 'x'
        from alloc_header
       where alloc_no = I_alloc_no
         for update nowait;
BEGIN
   if ALLOC_ATTRIB_SQL.UPD_QTYS_WHEN_CLOSE(O_error_message,
                                           I_alloc_no) = FALSE then
      return FALSE;
   end if;
   ---
   LP_table := 'ALLOC_HEADER';
   ---
   open C_LOCK_ALLOC_HEADER;
   close C_LOCK_ALLOC_HEADER;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'ALLOC_HEADER','Allocation: '||to_char(I_alloc_no));
   update alloc_header
      set status   = 'C'
    where alloc_no = I_alloc_no;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            LP_table,
                                            to_char(I_alloc_no),
                                            NULL);
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CLOSE_ALLOC;
-------------------------------------------------------------------------------------------------------------
FUNCTION CHECK_IN_PROGRESS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_in_progress    OUT    BOOLEAN,
                           I_alloc_no       IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                           I_to_loc         IN     ALLOC_DETAIL.TO_LOC%TYPE,
                           I_to_loc_type    IN     ALLOC_DETAIL.TO_LOC_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_dummy   VARCHAR2(1);

   cursor C_CHECK_IN_PROGRESS is
      select 'x'
        from alloc_detail
       where (nvl(qty_distro, 0) != 0
             or nvl(qty_selected, 0) != 0
             or nvl(qty_received, 0) != 0
             or nvl(qty_cancelled, 0) != 0
             or nvl(po_rcvd_qty, 0) != 0)
         and alloc_no = I_alloc_no
         and to_loc   = nvl(I_to_loc, to_loc)
         and to_loc_type = nvl(I_to_loc_type, to_loc_type)
         and rownum = 1;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_CHECK_IN_PROGRESS','ALLOC_DETAIL', NULL);
   open C_CHECK_IN_PROGRESS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_IN_PROGRESS','ALLOC_DETAIL', NULL);
   fetch C_CHECK_IN_PROGRESS into L_dummy;
   ---
   if C_CHECK_IN_PROGRESS%NOTFOUND then
      O_in_progress := FALSE;
   else
      O_in_progress := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_IN_PROGRESS','ALLOC_DETAIL',NULL);
   close  C_CHECK_IN_PROGRESS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ALLOC_ATTRIB_SQL.CHECK_IN_PROGRESS',
                                            to_char(SQLCODE));
      RETURN FALSE;
END CHECK_IN_PROGRESS;
-------------------------------------------------------------------------------------
FUNCTION CHECK_RELEASE_DATE(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                            I_order_no      IN     ALLOC_HEADER.ORDER_NO%TYPE,
                            I_nbd_date      IN     ORDHEAD.NOT_BEFORE_DATE%TYPE)
   RETURN BOOLEAN IS

   L_inv_parm               VARCHAR2(30)             := NULL;
   L_function               TRAN_DATA.PGM_NAME%TYPE  := 'ALLOC_ATTRIB_SQL.CHECK_RELEASE_DATE';

   cursor C_GET_RELEASE_DATE is
      select release_date, alloc_no
        from alloc_header
       where alloc_no = NVL(I_alloc_no, alloc_no)
         and order_no = NVL(I_order_no, order_no);

BEGIN
   if I_nbd_date is NULL then
      L_inv_parm := 'I_nbd_date';
   end if;
   ---
   if L_inv_parm is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_parm,
                                            L_function,
                                            NULL);
      return FALSE;
   end if;
   ---
   FOR alloc_header in C_GET_RELEASE_DATE LOOP
      if alloc_header.release_date is NOT NULL and I_nbd_date > alloc_header.release_date then
         O_error_message := SQL_LIB.CREATE_MSG('NBD_AFTER_RELEASE_DATE',
                                               I_nbd_date,
                                               alloc_header.release_date,
                                               alloc_header.alloc_no);
         return FALSE;
      end if;
   END LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_function,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_RELEASE_DATE;
-----------------------------------------------------------------------------------------
FUNCTION UPDATE_RELEASE_DATE(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                             I_order_no      IN     ALLOC_HEADER.ORDER_NO%TYPE,
                             I_release_date  IN     ALLOC_HEADER.RELEASE_DATE%TYPE)
   RETURN BOOLEAN IS

   L_inv_parm              VARCHAR2(30)            := NULL;
   L_function              TRAN_DATA.PGM_NAME%TYPE := 'ALLOC_ATTRIB_SQL.UPDATE_RELEASE_DATE';

   cursor C_LOCK_ALLOC_HEADER is
      select 'x'
        from alloc_header
       where alloc_no = NVL(I_alloc_no, alloc_no)
         and order_no = NVL(I_order_no, order_no)
         for update nowait;

BEGIN
   LP_table := 'ALLOC_HEADER';
   ---
   open C_LOCK_ALLOC_HEADER;
   close C_LOCK_ALLOC_HEADER;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'ALLOC_HEADER','Allocation: '||to_char(I_alloc_no));
   update alloc_header
      set release_date = I_release_date
    where alloc_no = NVL(I_alloc_no, alloc_no)
      and order_no = NVL(I_order_no, order_no);
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            LP_table,
                                            to_char(I_alloc_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_RELEASE_DATE;
-----------------------------------------------------------------------------------------
FUNCTION UPDATE_ASN_RELEASE_DATE(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_order_no      IN     ALLOC_HEADER.ORDER_NO%TYPE,
                                 I_nb_date       IN     ALLOC_HEADER.RELEASE_DATE%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(100) := 'ALLOC_ATTRIB_SQL.UPDATE_ASN_RELEASE_DATE';
   L_alloc_no        ALLOC_HEADER.ALLOC_NO%TYPE;
   L_tier_alloc_no   ALLOC_HEADER.ALLOC_NO%TYPE;
   L_error_message   RTK_ERRORS.RTK_TEXT%TYPE;

   cursor C_ASN_ALLOC is
      select alloc_no
        from alloc_header
       where doc_type = 'ASN'
         and order_no = I_order_no;

   cursor C_ASN_TIER_ALLOC is
      select alloc_no
        from alloc_header
       where alloc_parent = L_alloc_no;

   cursor C_LOCK_ALLOC_PARENT is
      select 'x'
        from alloc_header
       where order_no = I_order_no
         for update nowait;

   cursor C_LOCK_ALLOC_CHILD is
      select 'x'
        from alloc_header
       where alloc_no = L_tier_alloc_no
         for update nowait;

BEGIN
   if I_order_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_order_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_nb_date IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_nb_date',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('LOOP',
                    'C_ASN_ALLOC',
                    'ALLOC_HEADER',
                    'order no: '||TO_CHAR(I_order_no));

   FOR c_asn_alloc_rec in C_ASN_ALLOC LOOP
      L_alloc_no := c_asn_alloc_rec.alloc_no;

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ALLOC_PARENT',
                       'ALLOC_HEADER',
                       'Alloc number: '||TO_CHAR(L_alloc_no));
      open C_LOCK_ALLOC_PARENT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ALLOC_PARENT',
                       'ALLOC_HEADER',
                       'Alloc number: '||TO_CHAR(L_alloc_no));
      close C_LOCK_ALLOC_PARENT;

      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ALLOC_HEADER',
                       'order no: '||TO_CHAR(I_order_no));
      update alloc_header
         set release_date = I_nb_date
       where order_no = I_order_no;

      SQL_LIB.SET_MARK('LOOP',
                       'C_ASN_TIER_ALLOC',
                       'ALLOC_HEADER',
                       'order no: '||TO_CHAR(I_order_no));

      FOR c_asn_tier_alloc_rec in C_ASN_TIER_ALLOC LOOP
         L_tier_alloc_no := c_asn_tier_alloc_rec.alloc_no;

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_ALLOC_CHILD',
                          'ALLOC_HEADER',
                          'Alloc number: '||TO_CHAR(L_tier_alloc_no));
         open C_LOCK_ALLOC_CHILD;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_ALLOC_CHILD',
                          'ALLOC_HEADER',
                          'Alloc number: '||TO_CHAR(L_tier_alloc_no));
         close C_LOCK_ALLOC_CHILD;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ALLOC_HEADER',
                          'Alloc no: '||TO_CHAR(L_tier_alloc_no));
         update alloc_header
            set release_date = I_nb_date
          where alloc_no = L_tier_alloc_no;

      END LOOP;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END UPDATE_ASN_RELEASE_DATE;
-------------------------------------------------------------------------------------------------------------
FUNCTION MANUAL_ALLOC_EXISTS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists        IN OUT BOOLEAN,
                             I_order_no      IN     ALLOC_HEADER.ORDER_NO%TYPE)
   RETURN BOOLEAN IS

   L_temp       VARCHAR2(1);
   L_function   VARCHAR2(100) := 'ALLOC_ATTRIB_SQL.MANUAL_ALLOC_EXISTS';

   cursor C_MANUAL_ALLOC_EXISTS is
      select 'x'
        from alloc_header
       where order_no = I_order_no
         and alloc_method = 'A'
         and rownum = 1;

BEGIN
   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_order_no',
                                             L_function,
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_MANUAL_ALLOC_EXISTS','ALLOC_HEADER','order_no: '||to_char(I_order_no));
   open C_MANUAL_ALLOC_EXISTS;

   SQL_LIB.SET_MARK('FETCH','C_MANUAL_ALLOC_EXISTS','ALLOC_HEADER','order_no: '||to_char(I_order_no));
   fetch C_MANUAL_ALLOC_EXISTS into L_temp;

   if C_MANUAL_ALLOC_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   close C_MANUAL_ALLOC_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END MANUAL_ALLOC_EXISTS;
-------------------------------------------------------------------------------------------------------------
FUNCTION CLOSE_MANUAL_ALLOC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_order_no      IN     ALLOC_HEADER.ORDER_NO%TYPE)
   RETURN BOOLEAN IS

   L_manual_alloc   ALLOC_HEADER.ALLOC_NO%TYPE;
   L_function       VARCHAR2(100) := 'ALLOC_ATTRIB_SQL.CLOSE_MANUAL_ALLOC';

   cursor C_GET_MANUAL_ALLOC is
      select alloc_no
        from alloc_header
       where order_no = I_order_no
         and alloc_method = 'A';

BEGIN
   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_order_no',
                                             L_function,
                                             NULL);
      return FALSE;
   end if;

   FOR rec in C_GET_MANUAL_ALLOC LOOP
      L_manual_alloc := rec.alloc_no;

      if ALLOC_ATTRIB_SQL.CLOSE_ALLOC(O_error_message,
                                      L_manual_alloc) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CLOSE_MANUAL_ALLOC;
-------------------------------------------------------------------------------------------------------------
FUNCTION REINSTATE_MANUAL_ALLOC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_order_no      IN     ALLOC_HEADER.ORDER_NO%TYPE)
   RETURN BOOLEAN IS

   L_manual_alloc   ALLOC_HEADER.ALLOC_NO%TYPE;
   L_function       VARCHAR2(100) := 'ALLOC_ATTRIB_SQL.REINSTATE_MANUAL_ALLOC';

   cursor C_GET_MANUAL_ALLOC is
      select alloc_no
        from alloc_header
       where order_no = I_order_no
         and alloc_method = 'A';

BEGIN
   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_order_no',
                                             L_function,
                                             NULL);
      return FALSE;
   end if;

   FOR rec in C_GET_MANUAL_ALLOC LOOP
      L_manual_alloc := rec.alloc_no;

      if ALLOC_ATTRIB_SQL.REINSTATE_ALLOC(O_error_message,
                                          L_manual_alloc) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END REINSTATE_MANUAL_ALLOC;
-------------------------------------------------------------------------------------------------------------
FUNCTION REINSTATE_REPL_ALLOC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              I_order_no      IN     ALLOC_HEADER.ORDER_NO%TYPE)
   RETURN BOOLEAN IS

   L_repl_alloc     ALLOC_HEADER.ALLOC_NO%TYPE;
   L_function       VARCHAR2(100) := 'ALLOC_ATTRIB_SQL.REINSTATE_REPL_ALLOC';

   cursor C_GET_REPL_ALLOC is
      select alloc_no
        from alloc_header
       where order_no = I_order_no
         and alloc_method = 'P';

BEGIN
   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_order_no',
                                             L_function,
                                             NULL);
      return FALSE;
   end if;

   FOR rec in C_GET_REPL_ALLOC LOOP
      L_repl_alloc := rec.alloc_no;

      if ALLOC_ATTRIB_SQL.REINSTATE_ALLOC(O_error_message,
                                          L_repl_alloc) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END REINSTATE_REPL_ALLOC;
-------------------------------------------------------------------------------------------------------------
FUNCTION REINSTATE_ALLOC(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         I_alloc_no        IN       ALLOC_HEADER.ALLOC_NO%TYPE)
   RETURN BOOLEAN IS

   L_to_loc            ALLOC_DETAIL.TO_LOC%TYPE;
   L_qty_transferred   ALLOC_DETAIL.QTY_TRANSFERRED%TYPE;
   L_qty_distro        ALLOC_DETAIL.QTY_DISTRO%TYPE;
   L_qty_selected      ALLOC_DETAIL.QTY_SELECTED%TYPE;
   L_qty_cancelled     ALLOC_DETAIL.QTY_CANCELLED%TYPE;
   L_qty_received      ALLOC_DETAIL.QTY_RECEIVED%TYPE;
   L_update_detail     BOOLEAN := FALSE;
   L_table             VARCHAR2(50);
   L_function          VARCHAR2(100) := 'ALLOC_ATTRIB_SQL.REINSTATE_ALLOC';

   cursor C_LOCK_ALLOC_HEADER is
      select 'x'
        from alloc_header
       where alloc_no = I_alloc_no
         for update nowait;

   cursor C_LOCK_ALLOC_DETAIL is
      select 'x'
        from alloc_detail
       where alloc_no = I_alloc_no
         for update nowait;

    cursor C_DETAIL_TO_LOC is
      select to_loc,
             qty_transferred,
             qty_distro,
             qty_selected,
             qty_cancelled,
             qty_received
        from alloc_detail
       where alloc_no = I_alloc_no;

BEGIN
   if I_alloc_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_alloc_no',
                                             L_function,
                                             NULL);
      return FALSE;
   end if;

   L_table := 'ALLOC_DETAIL';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ALLOC_DETAIL',
                    'alloc_detail',
                    'alloc_no: '||TO_CHAR(I_alloc_no));
   open C_LOCK_ALLOC_DETAIL;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ALLOC_DETAIL',
                    'alloc_detail',
                    'alloc_no: '||TO_CHAR(I_alloc_no));
   close C_LOCK_ALLOC_DETAIL;

   FOR rec in C_DETAIL_TO_LOC LOOP
      L_to_loc          := rec.to_loc;
      L_qty_transferred := NVL(rec.qty_transferred,0);
      L_qty_distro      := NVL(rec.qty_distro,0);
      L_qty_selected    := NVL(rec.qty_selected,0);
      L_qty_cancelled   := NVL(rec.qty_cancelled,0);
      L_qty_received    := NVL(rec.qty_received,0);

      -- Check if all the quantity fields are zero
      if L_qty_transferred != 0 then
         L_update_detail := TRUE;
      elsif L_qty_distro != 0 then
         L_update_detail := TRUE;
      elsif L_qty_selected != 0 then
         L_update_detail := TRUE;
      elsif L_qty_cancelled != 0 then
         L_update_detail := TRUE;
      elsif L_qty_received != 0 then
         L_update_detail := TRUE;
      end if;

      -- If all the quanity fields are zero, then there is no need to update ALLOC_DETAIL
      -- because there have been no operations on the allocation
      if L_update_detail then

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ALLOC_DETAIL',
                          'alloc_no: '||TO_CHAR(I_alloc_no));

         update alloc_detail ald
            set qty_allocated = NVL(ald.qty_selected, 0) +
                                NVL(ald.qty_distro, 0) +
                                NVL(ald.qty_transferred, 0) +
                                NVL(ald.qty_cancelled, 0),
                ald.qty_cancelled = 0
          where ald.alloc_no = I_alloc_no
            and ald.to_loc = L_to_loc
            and exists (select alh.alloc_no
                          from alloc_header alh
                         where alh.alloc_no = ald.alloc_no
                           and (alh.doc_type != 'ASN' or alh.doc_type is NULL));

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ALLOC_DETAIL',
                          'ASN_alloc_no: '||TO_CHAR(I_alloc_no));

         update alloc_detail ald
            set ald.qty_allocated = NVL(ald.qty_selected, 0) +
                                    NVL(ald.qty_distro, 0) +
                                    NVL(ald.qty_transferred, 0) +
                                    NVL(ald.qty_cancelled, 0),
                ald.qty_cancelled = 0
         where exists (select alh.alloc_no
                         from alloc_header alh
                        where alh.alloc_no = ald.alloc_no
                          and ((alh.alloc_parent = I_alloc_no)
                              or (ald.alloc_no = I_alloc_no
                                 and alh.doc_type = 'ASN'))
                          and rownum = 1);

      end if;

      -- Reset the variable
      L_update_detail := FALSE;
   END LOOP;

   L_table := 'ALLOC_HEADER';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ALLOC_HEADER',
                    'alloc_header',
                    'alloc_no: '||TO_CHAR(I_alloc_no));
   open C_LOCK_ALLOC_HEADER;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ALLOC_HEADER',
                    'alloc_header',
                    'alloc_no: '||TO_CHAR(I_alloc_no));
   close C_LOCK_ALLOC_HEADER;

   -- The allocation must be reinstated to 'A'pproved status because a user interface in RMS does not exist to
   -- reset replenishment-generated allocation into 'A'pproved status. Also, there would be significant impact
   -- to the Allocation product for manually created allocations.

   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    'ALLOC_HEADER',
                    'alloc_no: '||TO_CHAR(I_alloc_no));
   update alloc_header
      set status = 'A'
    where alloc_no = I_alloc_no;

   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    'ALLOC_HEADER',
                    'ASN_alloc_no: '||TO_CHAR(I_alloc_no));
   update alloc_header
      set status = 'A'
    where ((alloc_no = I_alloc_no and doc_type = 'ASN')
          or (alloc_parent = I_alloc_no));

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                        L_table,
                        TO_CHAR(I_alloc_no),
                        NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END REINSTATE_ALLOC;
-----------------------------------------------------------------------------------------
END ALLOC_ATTRIB_SQL;
/

