CREATE OR REPLACE PACKAGE BODY ITEMLOC_UPDATE_SQL AS
-----------------------------------------------------------------------------------------------
FUNCTION UPD_AV_COST_CHANGE_COST(O_error_message         IN OUT   VARCHAR2,
                                 I_item                  IN       ITEM_MASTER.ITEM%TYPE,
                                 I_location              IN       ORDLOC.LOCATION%TYPE,
                                 I_loc_type              IN       ORDLOC.LOC_TYPE%TYPE,
                                 I_new_cost              IN       ITEM_LOC_SOH.AV_COST%TYPE,
                                 I_old_cost              IN       ITEM_LOC_SOH.AV_COST%TYPE,
                                 I_receipt_qty           IN       ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                                 I_new_wac_loc           IN       ITEM_LOC_SOH.AV_COST%TYPE,
                                 I_neg_soh_wac_adj_amt   IN       ITEM_LOC_SOH.AV_COST%TYPE,
                                 I_recalc_ind            IN       VARCHAR2,
                                 I_order_number          IN       ORDHEAD.ORDER_NO%TYPE   DEFAULT NULL,
                                 I_ref_no_2              IN       TRAN_DATA.REF_NO_2%TYPE DEFAULT NULL,
                                 I_pack_item             IN       ITEM_MASTER.ITEM%TYPE DEFAULT NULL,
                                 I_pgm_name              IN       TRAN_DATA.PGM_NAME%TYPE DEFAULT NULL,
                                 I_adj_code              IN       TRAN_DATA.ADJ_CODE%TYPE DEFAULT 'C')

RETURN BOOLEAN IS

   cursor C_STOCK is
      select stock_on_hand + pack_comp_soh + in_transit_qty + pack_comp_intran,
             av_cost,
             rowid
        from item_loc_soh
       where loc = I_location
         and item = I_item
         for update nowait;

   L_stock_on_hand         ITEM_LOC_SOH.STOCK_ON_HAND%TYPE   := 0;
   L_old_av_cost_loc       ITEM_LOC_SOH.AV_COST%TYPE         := 0;
   L_new_av_cost_loc       ITEM_LOC_SOH.AV_COST%TYPE;
   L_neg_soh_wac_adj_amt   ITEM_LOC_SOH.AV_COST%TYPE;
   L_neg_soh_wac_adj_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE;

   L_recalc_ind            VARCHAR2(1)    := NVL(I_recalc_ind, 'Y');
   L_item_master           ITEM_MASTER%ROWTYPE;
   L_tran_code             TRAN_DATA.TRAN_CODE%TYPE;
   L_tran_date             DATE           := get_vdate;

   L_rowid                 ROWID;
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

   L_loc_string            VARCHAR2(25);
   L_table                 VARCHAR2(30);
   L_key1                  VARCHAR2(100);
   L_key2                  VARCHAR2(100);
   L_systems_options_row   SYSTEM_OPTIONS%ROWTYPE;
   L_adj_qty               ITEM_LOC_SOH.STOCK_ON_HAND%TYPE;
   L_program               VARCHAR2(45)   := 'ITEMLOC_UPDATE_SQL.UPD_AV_COST_CHANGE_COST';
   L_new_cst               TRAN_DATA.TOTAL_COST%TYPE;
BEGIN

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   ---
   L_table := 'ITEM_LOC';
   L_key1  := I_item;
   L_key2  := to_char(I_location);
   ---
   if L_item_master.item_level = L_item_master.tran_level then
      L_loc_string := ' Location: '||TO_CHAR(I_location);
      SQL_LIB.SET_MARK('OPEN',
                       'C_STOCK',
                       'ITEM_LOC',
                       'ITEM: '||I_item||L_loc_string);
      open C_STOCK;
      SQL_LIB.SET_MARK('FETCH',
                       'C_STOCK',
                       'ITEM_LOC',
                       'ITEM: '||I_item||L_loc_string);
      fetch C_STOCK into L_stock_on_hand,
                         L_old_av_cost_loc,
                         L_rowid;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_STOCK',
                       'ITEM_LOC',
                       'ITEM: '||I_item||L_loc_string);
      close C_STOCK;
      ---
      if L_recalc_ind = 'Y' then
         ---
         if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                                  L_systems_options_row) = FALSE then
            return FALSE;
         end if;
         if L_systems_options_row.rcv_cost_adj_type = 'S' then
            if STKLEDGR_ACCTING_SQL.WAC_CALC_COST_CHANGE(O_error_message,
                                                         L_new_av_cost_loc,
                                                         L_neg_soh_wac_adj_amt,
                                                         L_old_av_cost_loc,
                                                         L_stock_on_hand,
                                                         I_new_cost,
                                                         I_old_cost,
                                                         I_receipt_qty) = FALSE then
               return FALSE;
            end if;
            ---
            --- note: currently only alc_sql is expecting this record to be written
            --- ultimately the other callers should be changed so that the 20 record
            --- is only written from here. The adj code is inserted as A only for
            --- alc sql
            if I_pgm_name is not null and I_receipt_qty > 0 then
               L_tran_code := 20;
               L_new_cst := (I_receipt_qty * (I_new_cost - I_old_cost));
               if STKLEDGR_SQL.TRAN_DATA_INSERT(O_error_message,
                                                I_item,
                                                L_item_master.dept,
                                                L_item_master.class,
                                                L_item_master.subclass,
                                                I_location,
                                                I_loc_type,
                                                L_tran_date,
                                                L_tran_code,
                                                I_adj_code,
                                                I_receipt_qty,
                                                L_new_cst,
                                                0,
                                                I_order_number,   -- I_ref_no_1,
                                                I_ref_no_2,   -- I_ref_no_2,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                nvl(I_pgm_name, L_program),
                                                NULL) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            if L_neg_soh_wac_adj_amt != 0 then
               ---
               L_tran_code := 70;
               ---
               if STKLEDGR_SQL.TRAN_DATA_INSERT(O_error_message,
                                                I_item,
                                                L_item_master.dept,
                                                L_item_master.class,
                                                L_item_master.subclass,
                                                I_location,
                                                I_loc_type,
                                                L_tran_date,
                                                L_tran_code,
                                                NULL,
                                                0,     -- unit
                                                L_neg_soh_wac_adj_amt,
                                                NULL,         -- Total Retail
                                                I_order_number,   -- I_ref_no_1,
                                                I_ref_no_2,   -- I_ref_no_2,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                nvl(I_pgm_name, L_program),
                                                NULL) = FALSE then
                  RETURN FALSE;
               end if;
            end if;
         elsif  L_systems_options_row.RCV_COST_ADJ_TYPE = 'F' then
            if STKLEDGR_ACCTING_SQL.ALT_WAC_CALC_COST_CHANGE(O_error_message,
                                                             L_new_av_cost_loc,
                                                             L_adj_qty,
                                                             L_neg_soh_wac_adj_qty,
                                                             L_old_av_cost_loc,
                                                             L_stock_on_hand,
                                                             I_old_cost,
                                                             I_order_number,
                                                             I_new_cost,
                                                             I_location,
                                                             I_item,
                                                             I_receipt_qty,
                                                             I_pack_item) = FALSE then
               return FALSE;
            end if;
            if L_adj_qty > 0 then
               L_tran_code := 20;
               L_new_cst := (L_adj_qty * (I_new_cost - I_old_cost));
               if STKLEDGR_SQL.TRAN_DATA_INSERT(O_error_message,
                                                I_item,
                                                L_item_master.dept,
                                                L_item_master.class,
                                                L_item_master.subclass,
                                                I_location,
                                                I_loc_type,
                                                L_tran_date,
                                                L_tran_code,
                                                I_adj_code,
                                                L_adj_qty,
                                                L_new_cst,
                                                0,
                                                I_order_number,   -- I_ref_no_1,
                                                I_ref_no_2,   -- I_ref_no_2,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                nvl(I_pgm_name, L_program),
                                                NULL) = FALSE then
                  return FALSE;
               end if;
            end if;
            if L_neg_soh_wac_adj_qty > 0 then
               L_tran_code := 73;
               L_new_cst   := (L_neg_soh_wac_adj_qty * (I_new_cost - I_old_cost));
               if STKLEDGR_SQL.TRAN_DATA_INSERT(O_error_message,
                                                I_item,
                                                L_item_master.dept,
                                                L_item_master.class,
                                                L_item_master.subclass,
                                                I_location,
                                                I_loc_type,
                                                L_tran_date,
                                                L_tran_code,
                                                NULL,
                                                L_neg_soh_wac_adj_qty,
                                                L_new_cst,
                                                NULL,
                                                I_order_number,   -- I_ref_no_1,
                                                I_ref_no_2,   -- I_ref_no_2,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                nvl(I_pgm_name, L_program),
                                                NULL) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
      else
         L_new_av_cost_loc := I_new_wac_loc;
         L_neg_soh_wac_adj_amt := I_neg_soh_wac_adj_amt;
      end if;
      ---
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ITEM_LOC_SOH',
                       'ITEM: '||I_item||L_loc_string);
      update item_loc_soh
         set av_cost = ROUND(L_new_av_cost_loc,4),
             last_update_datetime = SYSDATE,
             last_update_id = USER
       where rowid = L_rowid;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_key1,
                                             L_key2);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END UPD_AV_COST_CHANGE_COST;
-------------------------------------------------------------------------------
FUNCTION UPD_AVG_COST_CHANGE_QTY(I_item            IN       ITEM_MASTER.ITEM%TYPE,
                                 I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                                 I_location        IN       INV_ADJ.LOCATION%TYPE,
                                 I_new_cost        IN       ORDLOC.UNIT_COST%TYPE,
                                 I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                                 O_error_message   IN OUT   VARCHAR2)
RETURN BOOLEAN is

   L_program   VARCHAR2(64)   := 'ITEMLOC_UPDATE_SQL.UPD_AVG_COST_CHANGE_QTY';

   cursor C_STOCK is
      select stock_on_hand + pack_comp_soh + in_transit_qty + pack_comp_intran,
             av_cost,
             rowid
        from item_loc_soh
       where loc  = I_location
         and item = I_item
         for update nowait;

   L_old_av_cost_loc       ITEM_LOC_SOH.AV_COST%TYPE         := 0;
   L_stock_on_hand         ITEM_LOC_SOH.STOCK_ON_HAND%TYPE   := 0;

   L_new_av_cost_loc       ITEM_LOC_SOH.AV_COST%TYPE         := 0;
   L_neg_soh_wac_adj_amt   ITEM_LOC_SOH.AV_COST%TYPE;

   L_item_master           ITEM_MASTER%ROWTYPE;
   L_tran_code             TRAN_DATA.TRAN_CODE%TYPE;
   L_tran_date             DATE   := get_vdate;

   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);
   L_rowid                 ROWID;

   L_loc_string            VARCHAR2(25);
   L_table                 VARCHAR2(30);
   L_key1                  VARCHAR2(100);
   L_key2                  VARCHAR2(100);

BEGIN
   ---
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   ---
   L_table := 'ITEM_LOC';
   L_key1  := I_item;
   L_key2  := to_char(I_location);
   ---
   if L_item_master.item_level = L_item_master.tran_level then
      ---
      L_loc_string := ' Location: '||TO_CHAR(I_location);
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_STOCK',
                       'ITEM_LOC',
                       'ITEM: '||I_item||L_loc_string);
      open C_STOCK;
      SQL_LIB.SET_MARK('FETCH',
                       'C_STOCK',
                       'ITEM_LOC',
                       'ITEM: '||I_item||L_loc_string);
      ---
      fetch C_STOCK into L_stock_on_hand,
                         L_old_av_cost_loc,
                         L_rowid;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_STOCK',
                       'ITEM_LOC',
                       'ITEM: '||I_item||L_loc_string);
      close C_STOCK;
      ---
      if STKLEDGR_ACCTING_SQL.WAC_CALC_QTY_CHANGE(O_error_message,
                                                  L_new_av_cost_loc,
                                                  L_neg_soh_wac_adj_amt,
                                                  L_old_av_cost_loc,
                                                  L_stock_on_hand,
                                                  I_new_cost,
                                                  I_adj_qty) = FALSE then
         return FALSE;
      end if;
      ---
      if L_neg_soh_wac_adj_amt != 0 then
         ---
         L_tran_code := 70;
         ---
         if STKLEDGR_SQL.TRAN_DATA_INSERT(O_error_message,
                                          I_item,
                                          L_item_master.dept,
                                          L_item_master.class,
                                          L_item_master.subclass,
                                          I_location,
                                          I_loc_type,
                                          L_tran_date,
                                          L_tran_code,
                                          NULL,
                                          0,     -- unit
                                          L_neg_soh_wac_adj_amt,
                                          NULL,         -- Total Retail
                                          NULL,         -- I_ref_no_1,
                                          NULL,         -- I_ref_no_2,
                                          NULL,
                                          NULL,
                                          NULL,
                                          NULL,
                                          NULL,
                                          NULL,
                                          NULL,
                                          L_program,
                                          NULL) = FALSE then
            RETURN FALSE;
         end if;
      end if;
      ---
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ITEM_LOC_SOH',
                       'ITEM: '||I_item||L_loc_string);
      update item_loc_soh
         set stock_on_hand        = stock_on_hand + I_adj_qty,
             av_cost              = ROUND(L_new_av_cost_loc,4),
             soh_update_datetime  = DECODE(I_adj_qty, 0, soh_update_datetime,
                                                         SYSDATE),
             last_update_datetime = SYSDATE,
             last_update_id       = USER
       where rowid = L_rowid;
      ---
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_key1,
                                             L_key2);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END UPD_AVG_COST_CHANGE_QTY;
-----------------------------------------------------------------------------------
END ITEMLOC_UPDATE_SQL;
/

