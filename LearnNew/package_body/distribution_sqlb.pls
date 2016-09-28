CREATE OR REPLACE PACKAGE BODY DISTRIBUTION_SQL AS

-----------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Karthik Dhanapal, karthik.dhanapal@wipro.com
--Mod Date:    17-Mar-2008
--Mod Ref:     NBS00004699.
--Mod Details: Back ported the oracle fix for  Bugs 6371616(v12.0.6),6411268(v12.0.6)& 6682283  to 12.0.5.2 code
-----------------------------------------------------------------------------------------------------
--Mod By:      Murali Krishnan
--Mod Date:    28-Oct-2008
--Mod Ref:     Back Port Oracle fix(6732427)
--Mod Details: Back ported the oracle fix for Bug 6732427.Modified the function DISTRIBUTE.
-----------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                           GLOBAL VARIABLES                                 --
--------------------------------------------------------------------------------

TYPE INTERNAL_DIST_REC_TYPE IS RECORD
(
wh                              NUMBER,
protected_ind                   VARCHAR2(1),
restricted_ind                  VARCHAR2(1),
bucket_1                        NUMBER,
bucket_2                        NUMBER,
from_loc                        NUMBER,
to_loc                          NUMBER,
status                          VARCHAR2(1),
--
dist_qty                        NUMBER
);

TYPE INTERNAL_DIST_TABLE_TYPE IS TABLE OF INTERNAL_DIST_REC_TYPE
INDEX BY BINARY_INTEGER;

LP_dist_tab                     INTERNAL_DIST_TABLE_TYPE;
LP_cycle_count                  STAKE_SKU_LOC.CYCLE_COUNT%TYPE;
LP_protected_tab_index_1        INTEGER;
LP_protected_tab_index_2        INTEGER;
LP_unprotected_tab_index_1      INTEGER;
LP_unprotected_tab_index_2      INTEGER;

LP_item                         ITEM_LOC.ITEM%TYPE;
LP_physical_wh                  ITEM_LOC.LOC%TYPE;
LP_qty_to_distribute            NUMBER;
LP_negative_distribution_qty    BOOLEAN;
LP_integer_rounding             BOOLEAN;
LP_dist_rule                    SYSTEM_OPTIONS.DISTRIBUTION_RULE%TYPE;
LP_CMI                          VARCHAR2(64);
--------------------------------------------------------------------------------
--                      PRIVATE FUNCTION PROTOTYPES                           --
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_RTV(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_INVADJ(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN;
FUNCTION DISTRIBUTE_INVADJ_OUT(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN;
FUNCTION DISTRIBUTE_INVADJ_IN(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_TRANSFER(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE,
                        I_to_loc_type   IN     VARCHAR2,
                        I_to_loc        IN     NUMBER,
                        I_shipment      IN     NUMBER,
                        I_seq_no        IN     NUMBER)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_TRANSFER_OUT(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE,
                        I_to_loc_type   IN     VARCHAR2,
                        I_to_loc        IN     NUMBER)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_TRANSFER_IN(O_error_message IN OUT VARCHAR2,
                                I_shipment      IN     NUMBER,
                                I_seq_no        IN     NUMBER)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_TRANSFER_IN_ADJ(O_error_message IN OUT VARCHAR2,
                                    I_shipment      IN     NUMBER,
                                    I_seq_no        IN     NUMBER)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_STKREC(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_ORDRCV(O_error_message IN OUT VARCHAR2,
                           I_order_no      IN     NUMBER)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_ORDRCV_IN(O_error_message IN OUT VARCHAR2,
                              I_order_no      IN     NUMBER)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_ORDRCV_ADJ(O_error_message IN OUT VARCHAR2,
                               I_order_no      IN     NUMBER)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_SHORT(O_error_message IN OUT VARCHAR2,
                          I_bucket_type   IN     VARCHAR2)
RETURN BOOLEAN;
--
FUNCTION DRAW_UP_SHORT(O_error_message IN OUT VARCHAR2,
                       I_bucket_type   IN     VARCHAR2)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_OVER(O_error_message  IN OUT VARCHAR2,
                         I_bucket_type    IN     VARCHAR2,
                         I_bucket_1_total IN     NUMBER)
RETURN BOOLEAN;
--
FUNCTION DISTRIBUTE_ALLOCATED_PO(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN;
--
FUNCTION OUTBOUND_DIST_RULE_1(O_error_message IN OUT VARCHAR2,
                              I_inv_status    IN     INV_ADJ.INV_STATUS%TYPE)
RETURN BOOLEAN;
--
FUNCTION OUTBOUND_DIST_RULE_2(O_error_message IN OUT VARCHAR2,
                              I_inv_status    IN     INV_ADJ.INV_STATUS%TYPE)
RETURN BOOLEAN;
--
FUNCTION OUTBOUND_DIST_RULE_3(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN;
--
FUNCTION POPULATE_BUCKET_1(O_error_message IN OUT VARCHAR2,
                           O_bucket_total  IN OUT NUMBER,
                           I_inv_status    IN     INV_ADJ.INV_STATUS%TYPE,
                           I_index_1       IN     INTEGER,
                           I_index_2       IN     INTEGER)
RETURN BOOLEAN;
--
FUNCTION PRORATE_BUCKET_1(O_error_message IN OUT VARCHAR2,
                          I_bucket_total  IN     NUMBER,
                          I_index_1       IN     INTEGER,
                          I_index_2       IN     INTEGER)
RETURN BOOLEAN;
--
FUNCTION DRAW_DOWN_BUCKET_1(O_error_message IN OUT VARCHAR2,
                            I_bucket_total  IN     NUMBER,
                            I_index_1       IN     INTEGER,
                            I_index_2       IN     INTEGER)
RETURN BOOLEAN;
--
FUNCTION POPULATE_BUCKET_2(O_error_message IN OUT VARCHAR2,
                           O_bucket_total  IN OUT NUMBER,
                           I_index_1       IN     INTEGER,
                           I_index_2       IN     INTEGER)
RETURN BOOLEAN;
--
FUNCTION PRORATE_BUCKET_2(O_error_message IN OUT VARCHAR2,
                          I_bucket_total  IN     NUMBER,
                          I_index_1       IN     INTEGER,
                          I_index_2       IN     INTEGER)
RETURN BOOLEAN;
--
FUNCTION DRAW_DOWN_BUCKET_2(O_error_message IN OUT VARCHAR2,
                            I_bucket_total  IN     NUMBER,
                            I_index_1       IN     INTEGER,
                            I_index_2       IN     INTEGER)
RETURN BOOLEAN;
--
FUNCTION DRAW_DOWN_WH(O_error_message IN OUT VARCHAR2,
                      I_wh            IN     NUMBER)
RETURN BOOLEAN;
--
FUNCTION INBOUND_DIST_RULE_1(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN;
--
FUNCTION GET_INBOUND_VWH(O_error_message IN OUT VARCHAR2,
                         O_dist_tab      IN OUT INTERNAL_DIST_TABLE_TYPE,
                         I_index_1       IN     INTEGER,
                         I_index_2       IN     INTEGER)
RETURN BOOLEAN;
--
FUNCTION CREATE_ITEM_LOC_REL(O_error_message  IN OUT VARCHAR2,
                             O_wh             IN OUT WH.WH%TYPE,
                             I_il_create_rule IN     VARCHAR2)
RETURN BOOLEAN;
--
FUNCTION SET_DIST_TAB_INDEXES(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN;
--
FUNCTION GET_DIST_TAB_INDEXES(O_error_message IN OUT VARCHAR2,
                              O_index_1       IN OUT INTEGER,
                              O_index_2       IN OUT INTEGER,
                              I_bucket_type   IN     VARCHAR2)
RETURN BOOLEAN;
--
FUNCTION SET_ITEM_ATTRIBUTES(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN;
--
FUNCTION VALIDATE_INPUTS(O_error_message IN OUT VARCHAR2,
                         I_item          IN     ITEM_LOC.ITEM%TYPE,
                         I_loc           IN     ITEM_LOC.LOC%TYPE,
                         I_qty           IN     NUMBER,
                         I_CMI           IN     VARCHAR2,
                         I_shipment      IN     SHIPITEM_INV_FLOW.SHIPMENT%TYPE)
RETURN BOOLEAN;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                            PUBLIC FUNCTIONS                                --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE(O_error_message IN OUT VARCHAR2,
                    O_dist_tab      IN OUT DIST_TABLE_TYPE,
                    I_item          IN     ITEM_LOC.ITEM%TYPE,
                    I_loc           IN     ITEM_LOC.LOC%TYPE,
                    I_qty           IN     NUMBER,
                    I_CMI           IN     VARCHAR2,
                    I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE,
                    I_to_loc_type   IN     ITEM_LOC.LOC_TYPE%TYPE,
                    I_to_loc        IN     ITEM_LOC.LOC%TYPE,
                    I_order_no      IN     ORDHEAD.ORDER_NO%TYPE,
                    I_shipment      IN     SHIPITEM_INV_FLOW.SHIPMENT%TYPE,
                    I_seq_no        IN     SHIPITEM_INV_FLOW.SEQ_NO%TYPE,
                    I_cycle_count   IN     STAKE_SKU_LOC.CYCLE_COUNT%TYPE DEFAULT NULL)

RETURN BOOLEAN IS

j        INTEGER;
L_sign   INTEGER;

BEGIN

   --

   if VALIDATE_INPUTS(O_error_message,
                      I_item,
                      I_loc,
                      I_qty,
                      I_CMI,
                      I_shipment) = FALSE then
      return FALSE;
   end if;

   --

   LP_dist_tab.delete;
   O_dist_tab.delete;

   --

   LP_item := I_item;
   LP_physical_wh := I_loc;
   --
   if I_qty < 0 then
      LP_negative_distribution_qty := TRUE;
      L_sign := -1;
   else
      LP_negative_distribution_qty := FALSE;
      L_sign := +1;
   end if;
   LP_qty_to_distribute := I_qty * L_sign;

   --

   if SET_ITEM_ATTRIBUTES(O_error_message) = FALSE then
      return FALSE;
   end if;

   --

   LP_CMI := I_CMI;

   if LP_CMI = 'RTV' then
      if DISTRIBUTE_RTV(O_error_message,
                        I_inv_status) = FALSE then
         return FALSE;
      end if;
   elsif LP_CMI = 'INVADJ' then
      if DISTRIBUTE_INVADJ(O_error_message,
                           I_inv_status) = FALSE then
         return FALSE;
      end if;
   elsif LP_CMI = 'TRANSFER' then
      if DISTRIBUTE_TRANSFER(O_error_message,
                             I_inv_status,
                             I_to_loc_type,
                             I_to_loc,
                             I_shipment,
                             I_seq_no) = FALSE then
         return FALSE;
      end if;
   elsif LP_CMI = 'STKREC' then
      LP_cycle_count := I_cycle_count;
      if DISTRIBUTE_STKREC(O_error_message) = FALSE then
         return FALSE;
      end if;
   elsif LP_CMI = 'ORDRCV' then
      if DISTRIBUTE_ORDRCV(O_error_message,
                           I_order_no) = FALSE then
         return FALSE;
      end if;
   end if;

   --

   if LP_dist_tab.count = 0 then
      O_error_message := SQL_LIB.CREATE_MSG('NO_DIST_WH',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   --

   j := 0;
   for i in LP_dist_tab.first .. LP_dist_tab.last
   loop
      if LP_dist_tab(i).dist_qty != 0 or
         -- 28-Oct-2008 TESCO HSC/Murali 6732427 Begin
         I_CMI = 'ORDRCV' or
         -- 28-Oct-2008 TESCO HSC/Murali 6732427 End
         I_CMI = 'STKREC' then
         j := j + 1;
         O_dist_tab(j).wh := LP_dist_tab(i).wh;
         O_dist_tab(j).from_loc := LP_dist_tab(i).from_loc;
         O_dist_tab(j).to_loc := LP_dist_tab(i).to_loc;
         O_dist_tab(j).dist_qty := LP_dist_tab(i).dist_qty * L_sign;
      end if;
   end loop;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DISTRIBUTION_SQL.DISTRIBUTE',
                                            to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                           PRIVATE FUNCTIONS                                --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_RTV(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN IS

BEGIN

   --

   if I_inv_status is null then
      if OUTBOUND_DIST_RULE_1(O_error_message,
                              I_inv_status) = FALSE then
         return FALSE;
      end if;
   else
      if OUTBOUND_DIST_RULE_2(O_error_message,
                              I_inv_status) = FALSE then
         return FALSE;
      end if;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DISTRIBUTION_SQL.DISTRIBUTE_RTV',
                                            to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_RTV;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_INVADJ(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN IS

L_il_create_rule   VARCHAR2(10);
L_wh               WH.WH%TYPE:= null;

BEGIN

   --

   if LP_negative_distribution_qty = TRUE then
      if DISTRIBUTE_INVADJ_OUT(O_error_message,
                               I_inv_status) = FALSE then
         return FALSE;
      end if;
      L_il_create_rule := 'OUTBOUND';
   else
      if DISTRIBUTE_INVADJ_IN(O_error_message,
                              I_inv_status) = FALSE then
         return FALSE;
      end if;
      L_il_create_rule := 'INBOUND';
   end if;
   --
   if LP_dist_tab.count = 0 then
      if CREATE_ITEM_LOC_REL(O_error_message,
                             L_wh,
                             L_il_create_rule) = FALSE then
         return FALSE;
      end if;
      --
      if L_wh is not null then
         LP_dist_tab(1).wh := L_wh;
         LP_dist_tab(1).dist_qty := LP_qty_to_distribute;
      end if;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           'DISTRIBUTION_SQL.DISTRIBUTE_INVADJ',
                                           to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_INVADJ;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_INVADJ_OUT(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN IS

BEGIN

   --

   if I_inv_status is null then
      if OUTBOUND_DIST_RULE_1(O_error_message,
                              I_inv_status) = FALSE then
         return FALSE;
      end if;
   else
      if OUTBOUND_DIST_RULE_2(O_error_message,
                              I_inv_status) = FALSE then
         return FALSE;
      end if;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                       SQLERRM,
                                       'DISTRIBUTION_SQL.DISTRIBUTE_INVADJ_OUT',
                                       to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_INVADJ_OUT;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_INVADJ_IN(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN IS

BEGIN

   --

   if INBOUND_DIST_RULE_1(O_error_message,
                          I_inv_status) = FALSE then
      return FALSE;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                        SQLERRM,
                                        'DISTRIBUTION_SQL.DISTRIBUTE_INVADJ_IN',
                                        to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_INVADJ_IN;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_TRANSFER(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE,
                        I_to_loc_type   IN     VARCHAR2,
                        I_to_loc        IN     NUMBER,
                        I_shipment      IN     NUMBER,
                        I_seq_no        IN     NUMBER)
RETURN BOOLEAN IS

BEGIN

   --

   if I_shipment is null then
      if DISTRIBUTE_TRANSFER_OUT(O_error_message,
                                 I_inv_status,
                                 I_to_loc_type,
                                 I_to_loc) = FALSE then
         return FALSE;
      end if;
   else
      if LP_negative_distribution_qty = FALSE then
         if DISTRIBUTE_TRANSFER_IN(O_error_message,
                                   I_shipment,
                                   I_seq_no) = FALSE then
            return FALSE;
         end if;
      else
         if DISTRIBUTE_TRANSFER_IN_ADJ(O_error_message,
                                       I_shipment,
                                       I_seq_no) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                         SQLERRM,
                                         'DISTRIBUTION_SQL.DISTRIBUTE_TRANSFER',
                                         to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_TRANSFER;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_TRANSFER_OUT(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE,
                        I_to_loc_type   IN     VARCHAR2,
                        I_to_loc        IN     NUMBER)
RETURN BOOLEAN IS

L_wh               WH.WH%TYPE := null;
L_channel_id       CHANNELS.CHANNEL_ID%TYPE;
L_channel_type     CHANNELS.CHANNEL_TYPE%TYPE;

   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
   L_financial_ap             SYSTEM_OPTIONS.FINANCIAL_AP%TYPE := NULL;
   L_intercompany_tsf_sys_opt SYSTEM_OPTIONS.INTERCOMPANY_TRANSFER_IND%TYPE := NULL;

   cursor C_GET_VWH_4 is
      select w.wh loc
        from wh       w,
             wh       w2,
             item_loc il,
             channels c
       where w.physical_wh = LP_physical_wh
         and w.stockholding_ind = 'Y'
         and il.loc = w.wh
         and il.item = LP_item
         and w.channel_id = c.channel_id(+)
         and w2.wh = LP_physical_wh
         and w2.finisher_ind = 'N'
       order by w.wh;

   cursor C_GET_VWH_1 is
      select w.wh loc
        from wh w,
             wh w2,
             item_loc il,
             channels c,
             store s
       where w.physical_wh = LP_physical_wh
         and w.stockholding_ind = 'Y'
         and il.loc = w.wh
         and il.item = LP_item
         and s.store = I_to_loc
         and NVL(s.org_unit_id,0) = NVL(w.org_unit_id,0)
         and s.tsf_entity_id = w.tsf_entity_id
         and w.channel_id = c.channel_id
         and w.channel_id = s.channel_id
         and w2.wh = LP_physical_wh
         and w2.finisher_ind = 'N'
       order by w.wh;

   cursor C_GET_VWH_2 is
      select w.wh loc
        from wh w,
             wh w2,
             item_loc il,
             channels c,
             store s
       where w.physical_wh = LP_physical_wh
         and w.stockholding_ind = 'Y'
         and il.loc = w.wh
         and il.item = LP_item
         and s.store = I_to_loc
         and NVL(s.org_unit_id,0) = NVL(w.org_unit_id,0)
         and w.channel_id = c.channel_id
         and s.channel_id = w.channel_id
         and w2.wh = LP_physical_wh
         and w2.finisher_ind = 'N'
       order by w.wh;

   cursor C_GET_VWH_3 is
      select w.wh loc
        from wh w,
             wh w2,
             item_loc il,
             channels c,
             store s
       where w.physical_wh = LP_physical_wh
         and w.stockholding_ind = 'Y'
         and il.loc = w.wh
         and il.item = LP_item
         and s.store = I_to_loc
         and s.tsf_entity_id = w.tsf_entity_id
         and w.channel_id = c.channel_id
         and w.channel_id = s.channel_id
         and w2.wh = LP_physical_wh
         and w2.finisher_ind = 'N'
       order by w.wh;

   cursor C_PRIM_VWH is
      select vir_w.wh wh
        from wh phy_w,
             wh vir_w
       where vir_w.physical_wh = LP_physical_wh
         and vir_w.stockholding_ind = 'Y'
         and phy_w.physical_wh(+) = vir_w.physical_wh
         and phy_w.stockholding_ind(+) = 'N'
        order by vir_w.protected_ind,
                 ABS(SIGN(phy_w.primary_vwh - vir_w.wh));
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
BEGIN

   /*
   *  Outbound Transfers will be distributed based on either the 'outbound
   *  distribution rule 1' (for null I_inv_status) or the 'outbound
   *  distribution rule 2' (for non null inv_status).  In the case of
   *  transfers from a wh to a store the following rule will be applied first,
   *  and if a wh that satisfies the rule is found the entire distribution
   *  quantity will will be pulled from that wh.
   *
   *  wh to store transfer rule:
   *                                              pull
   *     channel id   channel type   lowest id    till
   *                                   vwh      fulfilled
   *         X             -            -           X
   *         -             X            X           X
   */
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
   if SYSTEM_OPTIONS_SQL.GET_FINANCIAL_AP(O_error_message,
                                          L_financial_ap) = FALSE then
      return FALSE;
   end if;
   if SYSTEM_OPTIONS_SQL.GET_INTERCOMPANY_TRANSFER_IND(O_error_message,
                                                       L_intercompany_tsf_sys_opt) = FALSE then
      return FALSE;
   end if;   --
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
   if I_to_loc_type = 'S' then
      --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
      if NVL(L_financial_ap,'X') = 'O' and L_intercompany_tsf_sys_opt = 'Y' then
         --Opening the cursor C_GET_VWH_1
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VWH_1',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || LP_item);
         open C_GET_VWH_1;
         --Fetching the cursor C_GET_VWH_1
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_VWH_1',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || LP_item);

         fetch C_GET_VWH_1 into L_wh;
         --Closing the cursor C_GET_VWH_1
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_VWH_1',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || LP_item);
         close C_GET_VWH_1;
      elsif NVL(L_financial_ap,'X') = 'O' and L_intercompany_tsf_sys_opt = 'N' then
         --Opening the cursor C_GET_VWH_2
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VWH_2',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || LP_item);

         open C_GET_VWH_2;
         --Fetching the cursor C_GET_VWH_2
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_VWH_2',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || LP_item);

         fetch C_GET_VWH_2 into L_wh;
         --Closing the cursor C_GET_VWH_2
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_VWH_2',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || LP_item);
         close C_GET_VWH_2;
      elsif NVL(L_financial_ap,'X') != 'O' and L_intercompany_tsf_sys_opt = 'Y' then
         --Opening the cursor C_GET_VWH_3
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VWH_3',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || LP_item);

         open C_GET_VWH_3;
         --Fetching the cursor C_GET_VWH_3
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_VWH_3',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || LP_item);
         fetch C_GET_VWH_3 into L_wh;
         --Closing the cursor C_GET_VWH_3
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_VWH_3',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || LP_item);
         close C_GET_VWH_3;
      elsif NVL(L_financial_ap,'X') != 'O' and L_intercompany_tsf_sys_opt = 'N' then
         --Opening the cursor C_GET_VWH_4
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VWH_4',
                          'WH,ITEM_LOC,CHANNELS',
                          'ITEM: ' || LP_item);
         open C_GET_VWH_4;
         --Fetching the cursor C_GET_VWH_4
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_VWH_4',
                          'WH,ITEM_LOC,CHANNELS',
                          'ITEM: ' || LP_item);
         fetch C_GET_VWH_4 into L_wh;
         --Closing the cursor C_GET_VWH_4
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_VWH_4',
                          'WH,ITEM_LOC,CHANNELS',
                          'ITEM: ' || LP_item);
         close C_GET_VWH_4;
      end if;
      if L_wh is NULL then
         --Opening the cursor C_PRIM_VWH
         SQL_LIB.SET_MARK('OPEN',
                          'C_PRIM_VWH',
                          'WH',
                          'PHYSICAL_WH :' || LP_physical_wh);
         open C_PRIM_VWH;
         --Fetching the cursor C_PRIM_VWH
         SQL_LIB.SET_MARK('FETCH',
                          'C_PRIM_VWH',
                          'WH',
                          'PHYSICAL_WH :' || LP_physical_wh);
         fetch C_PRIM_VWH into L_wh;
         --Closing the cursor C_PRIM_VWH
         SQL_LIB.SET_MARK('CLOSE',
                          'C_PRIM_VWH',
                          'WH',
                          'PHYSICAL_WH :' || LP_physical_wh);
         close C_PRIM_VWH;
      end if;
      --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
      --
      if L_wh is not null then
         LP_dist_tab(1).wh := L_wh;
         LP_dist_tab(1).dist_qty := 0;
         --
         if DRAW_DOWN_WH(O_error_message,
                         L_wh) = FALSE then
            return FALSE;
         end if;
         return TRUE;
      end if;
   end if;

   --

   if I_inv_status is null then
      if OUTBOUND_DIST_RULE_1(O_error_message,
                              I_inv_status) = FALSE then
         return FALSE;
      end if;
   else
      if OUTBOUND_DIST_RULE_2(O_error_message,
                              I_inv_status) = FALSE then
         return FALSE;
      end if;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                     SQLERRM,
                                     'DISTRIBUTION_SQL.DISTRIBUTE_TRANSFER_OUT',
                                     to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_TRANSFER_OUT;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_TRANSFER_IN(O_error_message IN OUT VARCHAR2,
                                I_shipment      IN     NUMBER,
                                I_seq_no        IN     NUMBER)
RETURN BOOLEAN IS

i                  INTEGER;
L_bucket_1_total   NUMBER := 0;
L_bucket_2_total   NUMBER := 0;
L_total            NUMBER := 0;
L_remainder        NUMBER := 0;
L_dist_qty         NUMBER;
L_qty_1            NUMBER := 0;
L_qty_2            NUMBER := 0;

cursor C_SHIPITEM_INV_FLOW is
   select from_loc,
          to_loc,
          tsf_qty,
          nvl(received_qty,0) received_qty,
          dist_pct
    from shipitem_inv_flow
   where seq_no = I_seq_no
     and shipment = I_shipment
     and item = LP_item;

BEGIN

   /*
   *  Inbound transfer shipments will be distributed based on quantities in
   *  the shipitem_inv_flow table.
   *
   *  bucket_1 will hold the transfer quantity
   *  bucket_2 will hold the received quantity capped at the transfer quantity
   *
   *  If the quantity to distribute is equal to the unreceived quantity
   *  distribution quantities are assigned to fulfill the need.
   *
   *  If the quantity to distribute is less than the unreceived quantity
   *  distribution quantities are prorated based on the transfer quantity.
   *
   *  If the quantity to distribute is greater than the unreceived quantity
   *  distribution quantities are first assigned to fulfill the need and then
   *  the orverage is prorated based on the transfer quantity.
   *
   *  The global LP_dist_tab table will contain a from-to location pairing
   *  (from the shipitem_inv_flow table) along with the distribution quantity.
   */

   --

   i := 0;
   for c_rec in C_SHIPITEM_INV_FLOW
   loop
      i := i + 1;
      LP_dist_tab(i).from_loc := c_rec.from_loc;
      LP_dist_tab(i).to_loc := c_rec.to_loc;
      --
      LP_dist_tab(i).bucket_1 := c_rec.tsf_qty;
      if c_rec.received_qty < c_rec.tsf_qty then
         LP_dist_tab(i).bucket_2 := c_rec.received_qty;
      else
         LP_dist_tab(i).bucket_2 := c_rec.tsf_qty;
      end if;
      LP_dist_tab(i).dist_qty := 0;
      --
      L_bucket_1_total := L_bucket_1_total + LP_dist_tab(i).bucket_1;
      L_bucket_2_total := L_bucket_2_total + LP_dist_tab(i).bucket_2;
   end loop;

   if LP_dist_tab.count = 0 then
      return TRUE;
   end if;

   --

   if L_bucket_1_total = (L_bucket_2_total + LP_qty_to_distribute) then
      -- even
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1 -
         LP_dist_tab(i).bucket_2;
      end loop;
   elsif L_bucket_1_total > (L_bucket_2_total + LP_qty_to_distribute) then
      -- short
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         if LP_dist_tab(i).bucket_1 > LP_dist_tab(i).bucket_2 then
            L_total := L_total + LP_dist_tab(i).bucket_1;
         end if;
      end loop;
      --
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         if LP_dist_tab(i).bucket_1 > LP_dist_tab(i).bucket_2 then
            if LP_integer_rounding then
               L_dist_qty := L_remainder +
               (LP_qty_to_distribute * LP_dist_tab(i).bucket_1 / L_total);
               --
               LP_dist_tab(i).dist_qty := ROUND(L_dist_qty);
               L_remainder := L_dist_qty - LP_dist_tab(i).dist_qty;
            else
               LP_dist_tab(i).dist_qty := LP_qty_to_distribute *
               LP_dist_tab(i).bucket_1 / L_total;
            end if;
         end if;
      end loop;
   else
      -- over
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         if LP_dist_tab(i).bucket_1 > LP_dist_tab(i).bucket_2 then
            LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1 -
            LP_dist_tab(i).bucket_2;
            --
            LP_qty_to_distribute := LP_qty_to_distribute -
            LP_dist_tab(i).dist_qty;
         end if;
      end loop;
      --
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         if LP_integer_rounding then
            L_qty_1 := L_remainder +
            (LP_qty_to_distribute * LP_dist_tab(i).bucket_1 / L_bucket_1_total);
            L_qty_2 := ROUND(L_qty_1);
            L_remainder := L_qty_1 - L_qty_2;
            --
            LP_dist_tab(i).dist_qty := LP_dist_tab(i).dist_qty + L_qty_2;
         else
            LP_dist_tab(i).dist_qty := LP_dist_tab(i).dist_qty +
            (LP_qty_to_distribute * LP_dist_tab(i).bucket_1 / L_bucket_1_total);
         end if;
      end loop;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                      SQLERRM,
                                      'DISTRIBUTION_SQL.DISTRIBUTE_TRANSFER_IN',
                                      to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_TRANSFER_IN;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_TRANSFER_IN_ADJ(O_error_message IN OUT VARCHAR2,
                                    I_shipment      IN     NUMBER,
                                    I_seq_no        IN     NUMBER)
RETURN BOOLEAN IS

i                  INTEGER;
L_bucket_2_total   NUMBER := 0;
L_remainder        NUMBER := 0;
L_dist_qty         NUMBER := 0;

cursor C_SHIPITEM_INV_FLOW is
   select from_loc,
          to_loc,
          nvl(received_qty,0) received_qty
    from shipitem_inv_flow
   where seq_no = I_seq_no
     and shipment = I_shipment
     and item = LP_item;

BEGIN

   /*
   *  Inbound adjustments to transfer shipments will be distributed based on
   *  received quantities in the shipitem_inv_flow table.
   *
   *  bucket_2 will hold the received quantity
   *
   *  If the quantity to distribute is equal to the received quantity
   *  distribution quantities are assigned to reverse the receipt.
   *
   *  If the quantity to distribute is less than the received quantity
   *  distribution quantities are prorated based on the received quantity.
   *
   *  If the quantity to distribute is greater than the received quantity
   *  an error is raised.
   *
   *  The global LP_dist_tab table will contain a from-to location pairing
   *  (from the shipitem_inv_flow table) along with the distribution quantity.
   */

   --

   i := 0;
   for c_rec in C_SHIPITEM_INV_FLOW
   loop
      i := i + 1;
      LP_dist_tab(i).dist_qty := 0;
      LP_dist_tab(i).from_loc := c_rec.from_loc;
      LP_dist_tab(i).to_loc := c_rec.to_loc;
      LP_dist_tab(i).bucket_2 := c_rec.received_qty;
      --
      L_bucket_2_total := L_bucket_2_total + LP_dist_tab(i).bucket_2;
   end loop;

   if LP_dist_tab.count = 0 then
      return TRUE;
   end if;

   --

   if L_bucket_2_total = LP_qty_to_distribute then
      -- even
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_2;
      end loop;
   elsif L_bucket_2_total > LP_qty_to_distribute then
      -- short
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         if LP_integer_rounding then
            L_dist_qty := L_remainder +
            (LP_qty_to_distribute * LP_dist_tab(i).bucket_2 / L_bucket_2_total);
            --
            LP_dist_tab(i).dist_qty := ROUND(L_dist_qty);
            L_remainder := L_dist_qty - LP_dist_tab(i).dist_qty;
         else
            LP_dist_tab(i).dist_qty := LP_qty_to_distribute *
            LP_dist_tab(i).bucket_2 / L_bucket_2_total;
         end if;
      end loop;
   else
      -- over
      O_error_message := SQL_LIB.CREATE_MSG('ADJ_GT_RCV',
                                  SQLERRM,
                                  'DISTRIBUTION_SQL.DISTRIBUTE_TRANSFER_IN_ADJ',
                                  to_char(SQLCODE));
      return FALSE;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                  SQLERRM,
                                  'DISTRIBUTION_SQL.DISTRIBUTE_TRANSFER_IN_ADJ',
                                  to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_TRANSFER_IN_ADJ;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_STKREC(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

L_il_create_rule   VARCHAR2(10);
L_wh               WH.WH%TYPE:= null;

BEGIN

   --

   if LP_negative_distribution_qty = TRUE then
      if OUTBOUND_DIST_RULE_3(O_error_message) = FALSE then
         return FALSE;
      end if;
      L_il_create_rule := 'OUTBOUND';
   else
      if INBOUND_DIST_RULE_1(O_error_message,
                             null) = FALSE then
         return FALSE;
      end if;
      L_il_create_rule := 'INBOUND';
   end if;
   --
   if LP_dist_tab.count = 0 then
      if CREATE_ITEM_LOC_REL(O_error_message,
                             L_wh,
                             L_il_create_rule) = FALSE then
         return FALSE;
      end if;
      --
      if L_wh is not null then
         LP_dist_tab(1).wh := L_wh;
         LP_dist_tab(1).dist_qty := LP_qty_to_distribute;
      end if;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           'DISTRIBUTION_SQL.DISTRIBUTE_STKREC',
                                           to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_STKREC;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_ORDRCV(O_error_message IN OUT VARCHAR2,
                           I_order_no      IN     NUMBER)
RETURN BOOLEAN IS

BEGIN

   --

   if LP_negative_distribution_qty = FALSE then
      if DISTRIBUTE_ORDRCV_IN(O_error_message,
                              I_order_no) = FALSE then
         return FALSE;
      end if;
   else
      if DISTRIBUTE_ORDRCV_ADJ(O_error_message,
                               I_order_no) = FALSE then
         return FALSE;
      end if;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                         SQLERRM,
                                         'DISTRIBUTION_SQL.DISTRIBUTE_ORDRCV',
                                         to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_ORDRCV;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_ORDRCV_IN(O_error_message IN OUT VARCHAR2,
                              I_order_no      IN     NUMBER)
RETURN BOOLEAN IS

i                              INTEGER;
L_bucket_type                  VARCHAR2(50);
L_bucket_1_unprotected_total   NUMBER := 0;
L_bucket_1_protected_total     NUMBER := 0;
L_bucket_2_unprotected_total   NUMBER := 0;
L_bucket_2_protected_total     NUMBER := 0;
L_bucket_1_total               NUMBER := 0;
L_bucket_2_total               NUMBER := 0;
L_wh                           WH.WH%TYPE:= null;

cursor C_DISTRIBUTION_RULE is
   select distribution_rule
     from system_options;

cursor C_WH is
   select w.wh,
          w.protected_ind,
          w.restricted_ind,
          ol.qty_ordered - sum(nvl(ad.qty_allocated,0)) qty_ord,
          nvl(ol.qty_received,0) - sum(nvl(ad.po_rcvd_qty,0)) qty_rcv
     from wh w,
          ordloc ol,
          alloc_header ah,
          alloc_detail ad
    where ad.alloc_no (+) = nvl(ah.alloc_no,-999)
      --
      and ah.order_no (+) = ol.order_no
      and ah.item (+) = ol.item
      and ah.wh (+) = ol.location
      --
      and ol.order_no = I_order_no
      and ol.item = LP_item
      and ol.location = w.wh
      --
      and w.physical_wh = LP_physical_wh
 group by w.wh,
          w.protected_ind,
          w.restricted_ind,
          ol.qty_ordered,
          nvl(ol.qty_received,0)
 order by w.protected_ind desc,
          qty_ord,
          w.wh;

BEGIN

   /*
   *  Order receipts are distributed based on order and receipt quantities in
   *  the ordloc table.  Allocations associated with the order are ignored.
   *
   *  bucket_1 will hold the order quantity
   *  bucket_2 will hold the received quantity capped at the order quantity
   *
   *  If the quantity to distribute is equal to the unreceived quantity,
   *  distribution quantities are assigned to fulfill the need.
   *
   *  If the quantity to distribute is less than the unreceived quantity,
   *  distribution quantities are distributed based on the distribution rule.
   *  An attempt is made first to assign the distribution quantity to the
   *  protected warehouses, and then, if quantities are still left
   *  undistributed, they will be distributed among the unprotected warehouses.
   *
   *  If the quantity to distribute is greater than the unreceived quantity
   *  distribution quantities are first assigned to fulfill the need and then
   *  the orverage is prorated based on the order quantity.
   *
   *  If no ordloc records exist for the item-location-order_no then the
   *  distribution quantities are distributed using the 'inbound distribution
   *  rule 1'.  If we are unable to perform the distribution based on this
   *  rule (all item_loc relationships are in a status of 'D'), then an
   *  ttempt is made to create an item_loc relationship for the item at a
   *  virtual warehouse (of the physical warehouse) that currently has none
   *  and assign to it the entire quantity to distribute.
   */

   --

   open C_DISTRIBUTION_RULE;
   fetch C_DISTRIBUTION_RULE into LP_dist_rule;
   close C_DISTRIBUTION_RULE;

   --

   i := 0;
   for c_rec in C_WH
   loop
      i := i + 1;
      LP_dist_tab(i).wh := c_rec.wh;
      LP_dist_tab(i).protected_ind := c_rec.protected_ind;
      LP_dist_tab(i).restricted_ind := c_rec.restricted_ind;
      --
      LP_dist_tab(i).bucket_1 := c_rec.qty_ord;
      if c_rec.qty_rcv < c_rec.qty_ord then
         LP_dist_tab(i).bucket_2 := c_rec.qty_rcv;
      else
         LP_dist_tab(i).bucket_2 := c_rec.qty_ord;
      end if;
      LP_dist_tab(i).dist_qty := 0;
      --
      if c_rec.protected_ind = 'N' then
         L_bucket_1_unprotected_total := L_bucket_1_unprotected_total +
         LP_dist_tab(i).bucket_1;
         L_bucket_2_unprotected_total := L_bucket_2_unprotected_total +
         LP_dist_tab(i).bucket_2;
      else
         L_bucket_1_protected_total := L_bucket_1_protected_total +
         LP_dist_tab(i).bucket_1;
         L_bucket_2_protected_total := L_bucket_2_protected_total +
         LP_dist_tab(i).bucket_2;
      end if;
   end loop;

   L_bucket_1_total := L_bucket_1_unprotected_total +
   L_bucket_1_protected_total;
   L_bucket_2_total := L_bucket_2_unprotected_total +
   L_bucket_2_protected_total;

   --

   -- If the PO is fully allocated an even distribution is performed.

   if LP_dist_tab.count != 0 and L_bucket_1_total = 0 then
      if DISTRIBUTE_ALLOCATED_PO(O_error_message) = FALSE then
         return FALSE;
      end if;
      --
      return TRUE;
   end if;

   --

   if LP_dist_tab.count = 0 then
      if INBOUND_DIST_RULE_1(O_error_message,
                             null) = FALSE then
         return FALSE;
      end if;
      --
      if LP_dist_tab.count = 0 then
         if CREATE_ITEM_LOC_REL(O_error_message,
                                L_wh,
                                'INBOUND') = FALSE then
            return FALSE;
         end if;
         --
         if L_wh is not null then
            LP_dist_tab(1).wh := L_wh;
            LP_dist_tab(1).dist_qty := LP_qty_to_distribute;
         end if;
      end if;
      --
      return TRUE;
   end if;

   --

   if L_bucket_1_total = (L_bucket_2_total + LP_qty_to_distribute) then
      -- even
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1 -
         LP_dist_tab(i).bucket_2;
      end loop;
   elsif L_bucket_1_total > (L_bucket_2_total + LP_qty_to_distribute) then
      -- short
      if SET_DIST_TAB_INDEXES(O_error_message) = FALSE then
         return FALSE;
      end if;
      --
      L_bucket_type := 'PROTECTED';
      loop
         --
         if L_bucket_type = 'PROTECTED' then
            L_bucket_1_total := L_bucket_1_protected_total;
            L_bucket_2_total := L_bucket_2_protected_total;
         else
            L_bucket_1_total := L_bucket_1_unprotected_total;
            L_bucket_2_total := L_bucket_2_unprotected_total;
         end if;

         if (L_bucket_1_total - L_bucket_2_total) > LP_qty_to_distribute then
            if DISTRIBUTE_SHORT(O_error_message,
                                L_bucket_type) = FALSE then
               return FALSE;
            end if;
            return TRUE;
         else
            if DRAW_UP_SHORT(O_error_message,
                             L_bucket_type) = FALSE then
               return FALSE;
            end if;
         end if;
         --
         if L_bucket_type = 'PROTECTED' then
            L_bucket_type := 'UNPROTECTED';
         else
            exit;
         end if;
      end loop;
      --
   else
      -- over
      if DISTRIBUTE_OVER(O_error_message,
                         L_bucket_type,
                         L_bucket_1_total) = FALSE then
         return FALSE;
      end if;
   end if;


   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                        SQLERRM,
                                        'DISTRIBUTION_SQL.DISTRIBUTE_ORDRCV_IN',
                                        to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_ORDRCV_IN;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_ORDRCV_ADJ(O_error_message IN OUT VARCHAR2,
                               I_order_no      IN     NUMBER)
RETURN BOOLEAN IS

i                  INTEGER;
L_remainder        NUMBER := 0;
L_bucket_1_total   NUMBER := 0;
L_bucket_2_total   NUMBER := 0;
L_dist_qty         NUMBER := 0;
L_qty_1            NUMBER := 0;
L_qty_2            NUMBER := 0;

cursor C_WH is
   select w.wh,
          nvl(ol.qty_received,0) - sum(nvl(ad.po_rcvd_qty,0)) unalloc_qty_rcv,
          sum(nvl(ad.po_rcvd_qty,0)) alloc_qty_rcv
     from wh w,
          ordloc ol,
          alloc_header ah,
          alloc_detail ad
    where ad.alloc_no (+) = nvl(ah.alloc_no,-999)
      --
      and ah.order_no (+) = ol.order_no
      and ah.item (+) = ol.item
      and ah.wh (+) = ol.location
      --
      and ol.order_no = I_order_no
      and ol.item = LP_item
      and ol.location = w.wh
      --
      and w.physical_wh = LP_physical_wh
 group by w.wh,
          nvl(ol.qty_received,0);

BEGIN

   /*
   *  Receipt adjustments to order shipments will be distributed based on
   *  received quantities in the ordloc table.
   *
   *  bucket_1 will hold the unallocated received quantity
   *  bucket_2 will hold the allocated received quantity
   *
   *  If the quantity to distribute is equal to the unallocated received
   *  quantity, distribution quantities are assigned to reverse the receipt.
   *
   *  If the quantity to distribute is less than the unallocted received
   *  quantity, distribution quantities are prorated based on the received
   *  quantity.
   *
   *  If the quantity to distribute is greater than the unallocated received
   *  quantity we will attempt to pull the excess from allocated received
   *  quantities.
   *
   *  If however the quantity to distribute is greater than the total received
   *  quantity, an error is raised.
   */

   --

   i := 0;
   for c_rec in C_WH
   loop
      i := i + 1;
      LP_dist_tab(i).dist_qty := 0;
      LP_dist_tab(i).wh := c_rec.wh;
      LP_dist_tab(i).bucket_1 := c_rec.unalloc_qty_rcv;
      LP_dist_tab(i).bucket_2 := c_rec.alloc_qty_rcv;
      --
      L_bucket_1_total := L_bucket_1_total + LP_dist_tab(i).bucket_1;
      L_bucket_2_total := L_bucket_2_total + LP_dist_tab(i).bucket_2;
   end loop;

   if LP_dist_tab.count = 0 then
      return TRUE;
   end if;

   --

   if L_bucket_1_total = LP_qty_to_distribute then
      -- even
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1;
      end loop;
   elsif L_bucket_1_total > LP_qty_to_distribute then
      -- short
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         if LP_integer_rounding then
            L_dist_qty := L_remainder +
            (LP_qty_to_distribute * LP_dist_tab(i).bucket_1 / L_bucket_1_total);
            --
            LP_dist_tab(i).dist_qty := ROUND(L_dist_qty);
            L_remainder := L_dist_qty - LP_dist_tab(i).dist_qty;
         else
            LP_dist_tab(i).dist_qty := LP_qty_to_distribute *
            LP_dist_tab(i).bucket_1 / L_bucket_1_total;
         end if;
      end loop;
   else
      -- try to pull from total received quantities (allocated and unallocated)
      if (L_bucket_1_total + L_bucket_2_total) = LP_qty_to_distribute then
         -- even
         for i in LP_dist_tab.first .. LP_dist_tab.last
         loop
            LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1 +
            LP_dist_tab(i).bucket_2;
         end loop;
      elsif (L_bucket_1_total + L_bucket_2_total) > LP_qty_to_distribute then
         -- short
         -- first draw down bucket_1
         for i in LP_dist_tab.first .. LP_dist_tab.last
         loop
            LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1;
            LP_qty_to_distribute := LP_qty_to_distribute -
            LP_dist_tab(i).bucket_1;
         end loop;
         -- then pull the remainder from bucket_2
         for i in LP_dist_tab.first .. LP_dist_tab.last
         loop
            if LP_integer_rounding then
               L_qty_1 := L_remainder +
               (LP_qty_to_distribute * LP_dist_tab(i).bucket_2 /
               L_bucket_2_total);
               L_qty_2 := ROUND(L_qty_1);
               L_remainder := L_qty_1 - L_qty_2;
               --
               LP_dist_tab(i).dist_qty := LP_dist_tab(i).dist_qty + L_qty_2;
            else
               LP_dist_tab(i).dist_qty := LP_dist_tab(i).dist_qty +
               (LP_qty_to_distribute * LP_dist_tab(i).bucket_2 /
               L_bucket_2_total);
            end if;
         end loop;
      else
         -- over
         O_error_message := SQL_LIB.CREATE_MSG('ADJ_GT_RCV',
                                       SQLERRM,
                                       'DISTRIBUTION_SQL.DISTRIBUTE_ORDRCV_ADJ',
                                       to_char(SQLCODE));
         return FALSE;
      end if;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                       SQLERRM,
                                       'DISTRIBUTION_SQL.DISTRIBUTE_ORDRCV_ADJ',
                                       to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_ORDRCV_ADJ;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_SHORT(O_error_message IN OUT VARCHAR2,
                          I_bucket_type   IN     VARCHAR2)
RETURN BOOLEAN IS

i             INTEGER;
L_index_1     INTEGER;
L_index_2     INTEGER;
L_total       NUMBER := 0;
L_remainder   NUMBER := 0;
L_dist_qty    NUMBER;

BEGIN

   /*
   *  The distribution rule determines how the distribution quantity will be
   *  distributed.  The indexes control the set of global LP_dist_tab table
   *  records that are candidates for the distribution.  The indexes will
   *  represent the group of protected or unprotected warehouses.
   *
   *  Proration is based on the bucket_1 (order) quantity.
   *
   *  MN2MX and MX2MN is based on the bucket_1 quantity.  The global
   *  LP_dist_tab table must be ordered by the order quantity.  The direction
   *  of processing is adjusted based on whether the rule is MN2MX or MX2MN.
   */

   --

   if GET_DIST_TAB_INDEXES(O_error_message,
                           L_index_1,
                           L_index_2,
                           I_bucket_type) = FALSE then
      return FALSE;
   end if;

   if L_index_1 is null or L_index_2 is null then
      return TRUE;
   end if;

   if LP_dist_rule = 'PRORAT' then
      for i in L_index_1 .. L_index_2
      loop
         if LP_dist_tab(i).bucket_1 > LP_dist_tab(i).bucket_2 then
            L_total := L_total + LP_dist_tab(i).bucket_1;
         end if;
      end loop;
      --
      for i in L_index_1 .. L_index_2
      loop
         if LP_dist_tab(i).bucket_1 > LP_dist_tab(i).bucket_2 then
            if LP_integer_rounding then
               L_dist_qty := L_remainder +
               (LP_qty_to_distribute * LP_dist_tab(i).bucket_1 / L_total);
               --
               LP_dist_tab(i).dist_qty := ROUND(L_dist_qty);
               L_remainder := L_dist_qty - LP_dist_tab(i).dist_qty;
            else
               LP_dist_tab(i).dist_qty := LP_qty_to_distribute *
               LP_dist_tab(i).bucket_1 / L_total;
            end if;
         end if;
      end loop;
   else
      if LP_dist_rule = 'MN2MX' then
         i := L_index_1 - 1;
      else
         i := L_index_2 + 1;
      end if;
      --
      loop
         if LP_dist_rule = 'MN2MX' then
            i := i + 1;
            --
            if i > L_index_2 then
               exit;
            end if;
         else
            i := i - 1;
            --
            if i < L_index_1 then
               exit;
            end if;
         end if;
         --
         if LP_qty_to_distribute = 0 then
            exit;
         end if;
         --
         if LP_dist_tab(i).bucket_1 > LP_dist_tab(i).bucket_2 then
            if LP_qty_to_distribute >
            (LP_dist_tab(i).bucket_1 - LP_dist_tab(i).bucket_2) then
               LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1 -
               LP_dist_tab(i).bucket_2;
               --
               LP_qty_to_distribute := LP_qty_to_distribute -
               LP_dist_tab(i).dist_qty;
            else
               LP_dist_tab(i).dist_qty := LP_qty_to_distribute;
               --
               LP_qty_to_distribute := 0;
            end if;
         end if;
      end loop;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DISTRIBUTION_SQL.DISTRIBUTE_SHORT',
                                            to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_SHORT;
--------------------------------------------------------------------------------

FUNCTION DRAW_UP_SHORT(O_error_message IN OUT VARCHAR2,
                       I_bucket_type   IN     VARCHAR2)
RETURN BOOLEAN IS

L_index_1   INTEGER;
L_index_2   INTEGER;

BEGIN

   --

   -- This function will draw up (distribute) whatever stock is still
   -- unreceived.

   if GET_DIST_TAB_INDEXES(O_error_message,
                           L_index_1,
                           L_index_2,
                           I_bucket_type) = FALSE then
      return FALSE;
   end if;

   if L_index_1 is null or L_index_2 is null then
      return TRUE;
   end if;

   for i in L_index_1 .. L_index_2
   loop
      LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1 -
      LP_dist_tab(i).bucket_2;
      --
      LP_qty_to_distribute := LP_qty_to_distribute - LP_dist_tab(i).dist_qty;
   end loop;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DISTRIBUTION_SQL.DRAW_UP_SHORT',
                                            to_char(SQLCODE));
      return FALSE;

END DRAW_UP_SHORT;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_OVER(O_error_message  IN OUT VARCHAR2,
                         I_bucket_type    IN     VARCHAR2,
                         I_bucket_1_total IN     NUMBER)
RETURN BOOLEAN IS

L_dist_tab   INTERNAL_DIST_TABLE_TYPE;

L_index_1       INTEGER;
L_index_2       INTEGER;
L_total         NUMBER := 0;
L_remainder     NUMBER := 0;
L_qty_1         NUMBER := 0;
L_qty_2         NUMBER := 0;

BEGIN

   /*
   *  This function will distribute receipt overages.  First the unreceived
   *  quantities are drawn up.  Then, the overage is prorated among the
   *  unrestricted warehouses.  If all the warehouses are unrestricted,
   *  the overage is prorated among all of them.
   *
   *  A local L_dist_tab table is used to hold the unrestricted warehouses
   *  while doing the proration.  Once completed, the distributed quantities
   *  are copied back to the global LP_dist_tab_table.
   */

   --

   for i in LP_dist_tab.first .. LP_dist_tab.last
   loop
      if LP_dist_tab(i).bucket_1 > LP_dist_tab(i).bucket_2 then
         LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1 -
         LP_dist_tab(i).bucket_2;
         --
         LP_qty_to_distribute := LP_qty_to_distribute - LP_dist_tab(i).dist_qty;
      end if;
   end loop;

   --

   for i in LP_dist_tab.first .. LP_dist_tab.last
   loop
      if LP_dist_tab(i).restricted_ind = 'N' then
         L_dist_tab(i) := LP_dist_tab(i);
         L_total := L_total + L_dist_tab(i).bucket_1;
      end if;
   end loop;

   if L_total = 0 then
      L_dist_tab := LP_dist_tab;
      L_total := I_bucket_1_total;
   end if;

   for i in L_dist_tab.first .. L_dist_tab.last
   loop
      if L_dist_tab.exists(i) = TRUE then
         if LP_integer_rounding then
            L_qty_1 := L_remainder +
            (LP_qty_to_distribute * L_dist_tab(i).bucket_1 / L_total);
            L_qty_2 := ROUND(L_qty_1);
            L_remainder := L_qty_1 - L_qty_2;
            --
            L_dist_tab(i).dist_qty := L_dist_tab(i).dist_qty + L_qty_2;
         else
            L_dist_tab(i).dist_qty := L_dist_tab(i).dist_qty +
            (LP_qty_to_distribute * L_dist_tab(i).bucket_1 / L_total);
         end if;
      end if;
   end loop;

   for i in L_dist_tab.first .. L_dist_tab.last
   loop
      if L_dist_tab.exists(i) = TRUE then
         LP_dist_tab(i).dist_qty := L_dist_tab(i).dist_qty;
      end if;
   end loop;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DISTRIBUTION_SQL.DISTRIBUTE_OVER',
                                            to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_OVER;
--------------------------------------------------------------------------------

FUNCTION DISTRIBUTE_ALLOCATED_PO(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

L_remainder   NUMBER := 0;
L_dist_qty    NUMBER := 0;

BEGIN

   /*
   *  This function will distribute a fully allocated PO.  The quantity to
   *  distribute will be distributed evenly across all virtuals on the PO.
   */

   --

   if LP_integer_rounding then
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         L_dist_qty := L_remainder + (LP_qty_to_distribute / LP_dist_tab.count);
         --
         LP_dist_tab(i).dist_qty := ROUND(L_dist_qty);
         L_remainder := L_dist_qty - LP_dist_tab(i).dist_qty;
      end loop;
   else
      for i in LP_dist_tab.first .. LP_dist_tab.last
      loop
         LP_dist_tab(i).dist_qty := LP_qty_to_distribute / LP_dist_tab.count;
      end loop;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                     SQLERRM,
                                     'DISTRIBUTION_SQL.DISTRIBUTE_ALLOCATED_PO',
                                     to_char(SQLCODE));
      return FALSE;

END DISTRIBUTE_ALLOCATED_PO;
--------------------------------------------------------------------------------

FUNCTION OUTBOUND_DIST_RULE_1(O_error_message IN OUT VARCHAR2,
                              I_inv_status    IN     INV_ADJ.INV_STATUS%TYPE)
RETURN BOOLEAN IS

i                  INTEGER;
L_index_1          INTEGER;
L_index_2          INTEGER;
L_bucket_type      VARCHAR2(50);
L_bucket_1_total   NUMBER := 0;
L_bucket_2_total   NUMBER := 0;

cursor C_WH is
   select w.wh,
          w.protected_ind
     from wh w,
          item_loc il
    where il.item = LP_item
      and il.loc = w.wh
      --
      --17-Mar-2008--WiproEnabler/Karthik--Bug6411268/NBS00004699--Begin
      and w.stockholding_ind = 'Y'
      --17-Mar-2008--WiproEnabler/Karthik--Bug6411268/NBS00004699--End
      --17-Mar-2008--WiproEnabler/Karthik--Bug6682283/NBS00004699--Begin
      and w.finisher_ind = 'N'
      --17-Mar-2008--WiproEnabler/Karthik--Bug6682283/NBS00004699--End
      and w.physical_wh = LP_physical_wh
 order by protected_ind;

BEGIN

   /*
   *  outbound distribution rule 1:
   *                                                pull      pull   pull
   *     status   protected   primary   lowest id   till      till   till
   *                ind         vwh        vwh    fulfilled   NI=0   SOH=0
   *       -         N           -          -        -          X      -
   *       -         N           -          -        -          -      X
   *       -         Y           -          -        -          X      -
   *       -         Y           -          -        -          -      X
   *      !=D        -           X          -        X          -      -
   *      !=D        -           -          X        X          -      -
   *
   *  bucket_1 holds the NI postiion
   *  bucket_2 holds the SOH postiion
   */

   --

   i := 0;
   for c_rec in C_WH
   loop
      i := i + 1;
      LP_dist_tab(i).wh := c_rec.wh;
      LP_dist_tab(i).protected_ind := c_rec.protected_ind;
      LP_dist_tab(i).dist_qty := 0;
   end loop;

   if LP_dist_tab.count = 0 then
      return TRUE;
   end if;

   if SET_DIST_TAB_INDEXES(O_error_message) = FALSE then
      return FALSE;
   end if;

   --

   L_bucket_type := 'UNPROTECTED';
   loop
      if GET_DIST_TAB_INDEXES(O_error_message,
                              L_index_1,
                              L_index_2,
                              L_bucket_type) = FALSE then
         return FALSE;
      end if;

      if L_index_1 is not null and  L_index_2 is not null then
         if POPULATE_BUCKET_1(O_error_message,
                              L_bucket_1_total,
                              I_inv_status,
                              L_index_1,
                              L_index_2) = FALSE then
            return FALSE;
         end if;

         if L_bucket_1_total >= LP_qty_to_distribute then
            if PRORATE_BUCKET_1(O_error_message,
                                L_bucket_1_total,
                                L_index_1,
                                L_index_2) = FALSE then
               return FALSE;
            end if;
            return TRUE;
         else
            if DRAW_DOWN_BUCKET_1(O_error_message,
                                  L_bucket_1_total,
                                  L_index_1,
                                  L_index_2) = FALSE then
               return FALSE;
            end if;
         end if;
         --
         if POPULATE_BUCKET_2(O_error_message,
                              L_bucket_2_total,
                              L_index_1,
                              L_index_2) = FALSE then
            return FALSE;
         end if;

         if (L_bucket_2_total - L_bucket_1_total) >= LP_qty_to_distribute then
            if PRORATE_BUCKET_2(O_error_message,
                                (L_bucket_2_total - L_bucket_1_total),
                                L_index_1,
                                L_index_2) = FALSE then
               return FALSE;
            end if;
            return TRUE;
         else
            if DRAW_DOWN_BUCKET_2(O_error_message,
                                  (L_bucket_2_total - L_bucket_1_total),
                                  L_index_1,
                                  L_index_2) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
      --
      if L_bucket_type = 'UNPROTECTED' then
         L_bucket_type := 'PROTECTED';
      else
         exit;
      end if;
   end loop;
   --
   if DRAW_DOWN_WH(O_error_message,
                   null) = FALSE then
      return FALSE;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                        SQLERRM,
                                        'DISTRIBUTION_SQL.OUTBOUND_DIST_RULE_1',
                                        to_char(SQLCODE));
      return FALSE;

END OUTBOUND_DIST_RULE_1;
--------------------------------------------------------------------------------

FUNCTION OUTBOUND_DIST_RULE_2(O_error_message IN OUT VARCHAR2,
                              I_inv_status    IN     INV_ADJ.INV_STATUS%TYPE)
RETURN BOOLEAN IS

i                  INTEGER;
L_index_1          INTEGER;
L_index_2          INTEGER;
L_bucket_type      VARCHAR2(50);
L_bucket_1_total   NUMBER := 0;
L_wh               WH.WH%TYPE := null;

cursor C_WH is
   select w.wh,
          w.protected_ind
     from wh w,
          item_loc il
    where il.item = LP_item
      and il.loc = w.wh
      --
      --17-Mar-2008--WiproEnabler/Karthik--Bug6682283/NBS00004699--Begin
      and w.stockholding_ind = 'Y'
      and w.finisher_ind = 'N'
      --17-Mar-2008--WiproEnabler/Karthik--Bug6682283/NBS00004699--End
      and w.physical_wh = LP_physical_wh
 order by protected_ind;

BEGIN

   /*
   *  outbound distribution rule 2:
   *                                                pull      pull
   *     status   protected   primary   lowest id   till      till
   *                ind         vwh        vwh    fulfilled   UI=0
   *       -         N           -          -        -          X
   *       -         Y           -          -        -          X
   *      !=D        -           X          -        X          -
   *      !=D        -           -          X        X          -
   *
   *  bucket_1 holds the UI postiion
   */

   --

   i := 0;
   for c_rec in C_WH
   loop
      i := i + 1;
      LP_dist_tab(i).wh := c_rec.wh;
      LP_dist_tab(i).protected_ind := c_rec.protected_ind;
      LP_dist_tab(i).dist_qty := 0;
   end loop;

   if LP_dist_tab.count = 0 then
      return TRUE;
   end if;

   if SET_DIST_TAB_INDEXES(O_error_message) = FALSE then
      return FALSE;
   end if;

   --

   L_bucket_type := 'UNPROTECTED';
   loop
      if GET_DIST_TAB_INDEXES(O_error_message,
                              L_index_1,
                              L_index_2,
                              L_bucket_type) = FALSE then
         return FALSE;
      end if;

      if L_index_1 is not null and L_index_2 is not null then
         if POPULATE_BUCKET_1(O_error_message,
                              L_bucket_1_total,
                              I_inv_status,
                              L_index_1,
                              L_index_2) = FALSE then
            return FALSE;
         end if;

         if L_bucket_1_total >= LP_qty_to_distribute then
            if PRORATE_BUCKET_1(O_error_message,
                                L_bucket_1_total,
                                L_index_1,
                                L_index_2) = FALSE then
               return FALSE;
            end if;
            return TRUE;
         else
            if DRAW_DOWN_BUCKET_1(O_error_message,
                                  L_bucket_1_total,
                                  L_index_1,
                                  L_index_2) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
      --
      if L_bucket_type = 'UNPROTECTED' then
         L_bucket_type := 'PROTECTED';
      else
         exit;
      end if;
   end loop;
   --
   if DRAW_DOWN_WH(O_error_message,
                   null) = FALSE then
      return FALSE;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                        SQLERRM,
                                        'DISTRIBUTION_SQL.OUTBOUND_DIST_RULE_2',
                                        to_char(SQLCODE));
      return FALSE;

END OUTBOUND_DIST_RULE_2;
--------------------------------------------------------------------------------

FUNCTION OUTBOUND_DIST_RULE_3(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

i                  INTEGER;
L_index_1          INTEGER;
L_index_2          INTEGER;
L_bucket_type      VARCHAR2(50);
L_bucket_2_total   NUMBER := 0;

cursor C_WH is
   select w.wh,
          w.protected_ind
     from wh w,
          item_loc il
    where il.item = LP_item
      and il.loc = w.wh
      --
      and w.wh != w.physical_wh
      and w.physical_wh = LP_physical_wh
 order by protected_ind;

BEGIN

   /*
   *  outbound distribution rule 3:
   *                                                pull      pull   pull
   *     status   protected   primary   lowest id   till      till   till
   *                ind         vwh        vwh    fulfilled   NI=0   SOH=0
   *       -         N           -          -        -          -      X
   *       -         Y           -          -        -          -      X
   *      !=D        -           X          -        X          -      -
   *      !=D        -           -          X        X          -      -
   *
   *  bucket_2 holds the SOH postiion
   */

   --

   i := 0;
   for c_rec in C_WH
   loop
      i := i + 1;
      LP_dist_tab(i).wh := c_rec.wh;
      LP_dist_tab(i).protected_ind := c_rec.protected_ind;
      LP_dist_tab(i).bucket_1 := 0;
      LP_dist_tab(i).dist_qty := 0;
   end loop;

   if LP_dist_tab.count = 0 then
      return TRUE;
   end if;

   if SET_DIST_TAB_INDEXES(O_error_message) = FALSE then
      return FALSE;
   end if;

   --

   L_bucket_type := 'UNPROTECTED';
   loop
      if GET_DIST_TAB_INDEXES(O_error_message,
                              L_index_1,
                              L_index_2,
                              L_bucket_type) = FALSE then
         return FALSE;
      end if;

      if L_index_1 is not null and L_index_2 is not null then
         if POPULATE_BUCKET_2(O_error_message,
                              L_bucket_2_total,
                              L_index_1,
                              L_index_2) = FALSE then
            return FALSE;
         end if;

         if L_bucket_2_total >= LP_qty_to_distribute then
            if PRORATE_BUCKET_2(O_error_message,
                                L_bucket_2_total,
                                L_index_1,
                                L_index_2) = FALSE then
               return FALSE;
            end if;
            return TRUE;
         else
            if DRAW_DOWN_BUCKET_2(O_error_message,
                                  L_bucket_2_total,
                                  L_index_1,
                                  L_index_2) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
      --
      if L_bucket_type = 'UNPROTECTED' then
         L_bucket_type := 'PROTECTED';
      else
         exit;
      end if;
   end loop;
   --
   if DRAW_DOWN_WH(O_error_message,
                   null) = FALSE then
      return FALSE;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                        SQLERRM,
                                        'DISTRIBUTION_SQL.OUTBOUND_DIST_RULE_3',
                                        to_char(SQLCODE));
      return FALSE;

END OUTBOUND_DIST_RULE_3;
--------------------------------------------------------------------------------

FUNCTION POPULATE_BUCKET_1(O_error_message IN OUT VARCHAR2,
                           O_bucket_total  IN OUT NUMBER,
                           I_inv_status    IN     INV_ADJ.INV_STATUS%TYPE,
                           I_index_1       IN     INTEGER,
                           I_index_2       IN     INTEGER)
RETURN BOOLEAN IS

L_total     NUMBER := 0;
L_found     BOOLEAN;

BEGIN

   --

   -- bucket_1 of the records of the global LP_dist_tab table, between the
   -- indexes, is set equal to the the NI or the UI based on the
   -- I_inv_status.  The bucket_1 total is returned.

   if I_inv_status is null then
      for i in I_index_1 .. I_index_2
      loop
         if ITEMLOC_QUANTITY_SQL.GET_LOC_CURRENT_AVAIL(O_error_message,
                                                       LP_dist_tab(i).bucket_1,
                                                       LP_item,
                                                       LP_dist_tab(i).wh,
                                                       'W') = FALSE then
            return FALSE;
         end if;
         --
         if LP_dist_tab(i).bucket_1 > 0 then
            L_total := L_total + LP_dist_tab(i).bucket_1;
         end if;
      end loop;
   else
      for i in I_index_1 .. I_index_2
      loop
         if INVADJ_SQL.GET_UNAVAILABLE(LP_item,
                                       'W',
                                       LP_dist_tab(i).wh,
                                       LP_dist_tab(i).bucket_1,
                                       O_error_message,
                                       L_found) = FALSE then
            return FALSE;
         end if;
         --
         if LP_dist_tab(i).bucket_1 > 0 then
            L_total := L_total + LP_dist_tab(i).bucket_1;
         end if;
         --
      end loop;
   end if;

   O_bucket_total := L_total;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                          SQLERRM,
                                          'DISTRIBUTION_SQL.POPULATE_BUCKET_1',
                                          to_char(SQLCODE));
      return FALSE;

END POPULATE_BUCKET_1;
--------------------------------------------------------------------------------

FUNCTION PRORATE_BUCKET_1(O_error_message IN OUT VARCHAR2,
                          I_bucket_total  IN     NUMBER,
                          I_index_1       IN     INTEGER,
                          I_index_2       IN     INTEGER)
RETURN BOOLEAN IS

L_remainder   NUMBER := 0;
L_dist_qty    NUMBER := 0;

BEGIN

   --

   -- the quantity to distribute is prorated among the candidate warehouses
   -- of the global LP_dist_tab table, between the indexes passed in.  The
   -- proration is based on bucket_1 quantity.

   if LP_integer_rounding then
      for i in I_index_1 .. I_index_2
      loop
         if LP_dist_tab(i).bucket_1 > 0 then
            L_dist_qty := L_remainder +
            (LP_qty_to_distribute * LP_dist_tab(i).bucket_1 / I_bucket_total);
            --
            LP_dist_tab(i).dist_qty := ROUND(L_dist_qty);
            L_remainder := L_dist_qty - LP_dist_tab(i).dist_qty;
         end if;
      end loop;
   else
      for i in I_index_1 .. I_index_2
      loop
         if LP_dist_tab(i).bucket_1 > 0 then
            LP_dist_tab(i).dist_qty := LP_qty_to_distribute *
            LP_dist_tab(i).bucket_1 / I_bucket_total;
         end if;
      end loop;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DISTRIBUTION_SQL.PRORATE_BUCKET_1',
                                            to_char(SQLCODE));
      return FALSE;

END PRORATE_BUCKET_1;
--------------------------------------------------------------------------------

FUNCTION DRAW_DOWN_BUCKET_1(O_error_message IN OUT VARCHAR2,
                            I_bucket_total  IN     NUMBER,
                            I_index_1       IN     INTEGER,
                            I_index_2       IN     INTEGER)
RETURN BOOLEAN IS

BEGIN

   --

   -- This function will pull whatever stock is available in bucket_1.

   for i in I_index_1 .. I_index_2
   loop
      if LP_dist_tab(i).bucket_1 > 0 then
         LP_dist_tab(i).dist_qty := LP_dist_tab(i).bucket_1;
      end if;
   end loop;

   LP_qty_to_distribute := LP_qty_to_distribute - I_bucket_total;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                          SQLERRM,
                                          'DISTRIBUTION_SQL.DRAW_DOWN_BUCKET_1',
                                          to_char(SQLCODE));
      return FALSE;

END DRAW_DOWN_BUCKET_1;
--------------------------------------------------------------------------------

FUNCTION POPULATE_BUCKET_2(O_error_message IN OUT VARCHAR2,
                           O_bucket_total  IN OUT NUMBER,
                           I_index_1       IN     INTEGER,
                           I_index_2       IN     INTEGER)
RETURN BOOLEAN IS

L_total     NUMBER := 0;

L_bucket_2  NUMBER;

cursor C_SNAPSHOT_ON_HAND_QTY(cv_item     STAKE_SKU_LOC.ITEM%TYPE,
                              cv_location STAKE_SKU_LOC.LOCATION%TYPE) IS
   select NVL(ssl.snapshot_on_hand_qty, 0)
     from stake_sku_loc ssl
    where ssl.item =  cv_item
      and ssl.location = cv_location
      and ssl.cycle_count = LP_cycle_count;

BEGIN

   --

   -- bucket_2 of the records of the global LP_dist_tab table, between the
   -- indexes, is set equal to the SOH position of the item at the virtual
   -- warehouse.  The bucket_2 total is returned.

   for i in I_index_1 .. I_index_2
   loop
      if LP_CMI = 'STKREC' THEN
      -- -------------------------------------------------------------------
      -- For Stock Counts use the SOH at the time the stock count was taken
      -- -------------------------------------------------------------------
         open C_SNAPSHOT_ON_HAND_QTY(LP_item, LP_dist_tab(i).wh);
         fetch C_SNAPSHOT_ON_HAND_QTY INTO L_bucket_2;
         close C_SNAPSHOT_ON_HAND_QTY;
         --
         if L_bucket_2 is NULL then
            L_bucket_2 := 0;
         end if;
         --
         LP_dist_tab(i).bucket_2 := L_bucket_2;
      else
         if ITEMLOC_QUANTITY_SQL.GET_STOCK_ON_HAND(O_error_message,
                                                   LP_dist_tab(i).bucket_2,
                                                   LP_item,
                                                   LP_dist_tab(i).wh,
                                                   'W') = FALSE then
            return FALSE;
         end if;
      end if;
      --
      if LP_dist_tab(i).bucket_2 > 0 then
         L_total := L_total + LP_dist_tab(i).bucket_2;
      end if;
   end loop;

   O_bucket_total := L_total;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                          SQLERRM,
                                          'DISTRIBUTION_SQL.POPULATE_BUCKET_2',
                                          to_char(SQLCODE));
      return FALSE;

END POPULATE_BUCKET_2;
--------------------------------------------------------------------------------

FUNCTION PRORATE_BUCKET_2(O_error_message IN OUT VARCHAR2,
                          I_bucket_total  IN     NUMBER,
                          I_index_1       IN     INTEGER,
                          I_index_2       IN     INTEGER)
RETURN BOOLEAN IS

L_remainder           NUMBER := 0;
L_qty_1               NUMBER := 0;
L_qty_2               NUMBER := 0;
L_bucket_2_adjusted   NUMBER := 0;

BEGIN

   --

   -- the quantity to distribute is prorated among the candidate warehouses
   -- of the global LP_dist_tab table, between the indexes passed in.  The
   -- proration is based on the difference between the bucket_2 and bucket_1
   -- quantities.  This is done because this function will only be called
   -- after bucket_1 quantities are completely drawn down.

   if LP_integer_rounding then
      for i in I_index_1 .. I_index_2
      loop
         if LP_dist_tab(i).bucket_2 > 0 then
            if LP_dist_tab(i).bucket_1 > 0 then
               L_bucket_2_adjusted := LP_dist_tab(i).bucket_2 -
               LP_dist_tab(i).bucket_1;
            else
               L_bucket_2_adjusted := LP_dist_tab(i).bucket_2;
            end if;
            --
            if L_bucket_2_adjusted > 0 then
               L_qty_1 := L_remainder +
               (LP_qty_to_distribute * L_bucket_2_adjusted / I_bucket_total);
               L_qty_2 := ROUND(L_qty_1);
               L_remainder := L_qty_1 - L_qty_2;
               --
               LP_dist_tab(i).dist_qty := LP_dist_tab(i).dist_qty + L_qty_2;
            end if;
         end if;
      end loop;
   else
      for i in I_index_1 .. I_index_2
      loop
         if LP_dist_tab(i).bucket_2 > 0 then
            if LP_dist_tab(i).bucket_1 > 0 then
               L_bucket_2_adjusted := LP_dist_tab(i).bucket_2 -
               LP_dist_tab(i).bucket_1;
            else
               L_bucket_2_adjusted := LP_dist_tab(i).bucket_2;
            end if;
            --
            if L_bucket_2_adjusted > 0 then
               LP_dist_tab(i).dist_qty := LP_dist_tab(i).dist_qty +
               (LP_qty_to_distribute * L_bucket_2_adjusted / I_bucket_total);
            end if;
         end if;
      end loop;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DISTRIBUTION_SQL.PRORATE_BUCKET_2',
                                            to_char(SQLCODE));
      return FALSE;

END PRORATE_BUCKET_2;
--------------------------------------------------------------------------------

FUNCTION DRAW_DOWN_BUCKET_2(O_error_message IN OUT VARCHAR2,
                            I_bucket_total  IN     NUMBER,
                            I_index_1       IN     INTEGER,
                            I_index_2       IN     INTEGER)
RETURN BOOLEAN IS

BEGIN

   --

   -- This function will pull whatever stock is still available to pull.
   -- It is called only after drawing down bucket_1 quantities (NI stock),
   -- and will only pull the difference between the bucket_2 and bucket_1
   -- quantities, which represents the remaining stock.

   for i in I_index_1 .. I_index_2
   loop
      if LP_dist_tab(i).bucket_2 > 0 then
         if LP_dist_tab(i).bucket_1 > 0 then
            LP_dist_tab(i).dist_qty := LP_dist_tab(i).dist_qty +
            (LP_dist_tab(i).bucket_2 - LP_dist_tab(i).bucket_1);
         else
            LP_dist_tab(i).dist_qty := LP_dist_tab(i).dist_qty +
            LP_dist_tab(i).bucket_2;
         end if;
      end if;
   end loop;

   LP_qty_to_distribute := LP_qty_to_distribute - I_bucket_total;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                          SQLERRM,
                                          'DISTRIBUTION_SQL.DRAW_DOWN_BUCKET_2',
                                          to_char(SQLCODE));
      return FALSE;

END DRAW_DOWN_BUCKET_2;
--------------------------------------------------------------------------------

FUNCTION DRAW_DOWN_WH(O_error_message IN OUT VARCHAR2,
                      I_wh            IN     NUMBER)
RETURN BOOLEAN IS

L_wh   WH.WH%TYPE := null;

cursor C_PRIMARY_VWH is
   select w.primary_vwh
     from wh w,
          item_loc il
    where il.status != 'D'
      and il.item = LP_item
      and il.loc = w.primary_vwh
      and w.wh = LP_physical_wh;

cursor C_LOWEST_ID_VWH is
   select min(w.wh)
     from wh w,
          item_loc il
    where il.status != 'D'
      and il.item = LP_item
      and il.loc = w.wh
      and w.wh != w.physical_wh
      and w.physical_wh = LP_physical_wh;

BEGIN

   /*
   *  The remaining LP_qty_to_distribute is pulled from the I_wh passed into
   *  this function.  If however I_wh is null, then the following rule is
   *  used to choose the warehouse from which to pull the remaining stock.
   *
   *                                     pull
   *     status   primary   lowest id    till
   *                vwh       vwh      fulfilled
   *      !=D        X         -          X
   *      !=D        -         X          X
   *
   */

   --

   if I_wh is null then
      open C_PRIMARY_VWH;
      fetch C_PRIMARY_VWH into L_wh;
      close C_PRIMARY_VWH;
      --
      if L_wh is null then
         open C_LOWEST_ID_VWH;
         fetch C_LOWEST_ID_VWH into L_wh;
         close C_LOWEST_ID_VWH;
      end if;
      --
      if L_wh is null then
         O_error_message := SQL_LIB.CREATE_MSG('NO_DIST_WH',
                                               NULL,
                                               NULL,
                                               NULL);
         return FALSE;
      end if;
   else
      L_wh := I_wh;
   end if;

   for i in LP_dist_tab.first .. LP_dist_tab.last
   loop
      if LP_dist_tab(i).wh = L_wh then
         LP_dist_tab(i).dist_qty := LP_dist_tab(i).dist_qty +
         LP_qty_to_distribute;
         exit;
      end if;
   end loop;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           'DISTRIBUTION_SQL.DRAW_DOWN_WH',
                                           to_char(SQLCODE));
      return FALSE;

END DRAW_DOWN_WH;
--------------------------------------------------------------------------------

FUNCTION INBOUND_DIST_RULE_1(O_error_message IN OUT VARCHAR2,
                        I_inv_status    IN     INV_STATUS_TYPES.INV_STATUS%TYPE)
RETURN BOOLEAN IS

i             INTEGER;
L_index_1     INTEGER;
L_index_2     INTEGER;
L_status      ITEM_LOC.STATUS%TYPE;

L_total       NUMBER := 0;
L_remainder   NUMBER := 0;
L_dist_qty    NUMBER;
L_bucket_1    NUMBER;
L_dist_wh     WH.WH%TYPE;

L_dist_tab    INTERNAL_DIST_TABLE_TYPE;
L_found       BOOLEAN;

cursor C_WH is
   select w.wh,
          il.status,
          w.restricted_ind
     from wh w,
          item_loc il
    where il.status != 'D'
      and il.item = LP_item
      and il.loc = w.wh
      and w.finisher_ind = DECODE(LP_CMI,
                                  'ORDRCV', 'N',
                                  w.finisher_ind)
      and w.wh != w.physical_wh
      and w.physical_wh = LP_physical_wh
 order by il.status,
          w.restricted_ind,
          w.wh;

cursor C_SNAPSHOT_ON_HAND_QTY(cv_item     STAKE_SKU_LOC.ITEM%TYPE,
                              cv_location STAKE_SKU_LOC.LOCATION%TYPE) is
   select NVL(ssl.snapshot_on_hand_qty, 0)
     from stake_sku_loc ssl
    where ssl.item =  cv_item
      and ssl.location = cv_location
      and ssl.cycle_count = LP_cycle_count;


BEGIN

   /*
   *  inbound distribution rule 1:
   *     status   bucket_1   restriced_ind   logic      based on
   *       A        > 0            N         Prorate    bucket_1
   *       A        > 0            Y         Prorate    bucket_1
   *       A       <= 0            N          Even         -
   *       A       <= 0            Y          Even         -
   *       C        > 0            N         Prorate    bucket_1
   *       C        > 0            Y         Prorate    bucket_1
   *       C       <= 0            N          Even         -
   *       C       <= 0            Y          Even         -
   *       I        > 0            N         Prorate    bucket_1
   *       I        > 0            Y         Prorate    bucket_1
   *       I       <= 0            N          Even         -
   *       I       <= 0            Y          Even         -
   *
   *  bucket_1 holds the SOH postiion if the I_inv_status is null
   *  bucket_1 holds the UI postiion if the I_inv_status is not null
   */

   --

   i := 0;
   for c_rec in C_WH
   loop
      i := i + 1;
      LP_dist_tab(i).wh := c_rec.wh;
      LP_dist_tab(i).status := c_rec.status;
      LP_dist_tab(i).restricted_ind := c_rec.restricted_ind;
      --
      LP_dist_tab(i).dist_qty := 0;
   end loop;

   if LP_dist_tab.count = 0 then
      return TRUE;
   end if;

   --

   -- the bucket_1 column of the LP_dist_tab table is populated for records of
   -- a particular item_loc status.  GET_INBOUND_VWH is called for this set of
   -- records and will return a local L_dist_tab table with records that
   -- meet the inbound distribution rule 1.

   L_status := LP_dist_tab(1).status;
   L_index_1 := 1;
   for i in LP_dist_tab.first .. LP_dist_tab.last
   loop
      if LP_dist_tab(i).status != L_status then
         exit;
      else
         L_index_2 := i;
      end if;
      --
      if I_inv_status is null then
         if LP_CMI = 'STKREC' then
         -- -------------------------------------------------------------------
         -- For Stock Counts use the SOH at the time the stock count was taken
         -- -------------------------------------------------------------------
            L_bucket_1 := NULL;
            open C_SNAPSHOT_ON_HAND_QTY(LP_item, LP_dist_tab(i).wh);
            fetch C_SNAPSHOT_ON_HAND_QTY into L_bucket_1;
            if L_bucket_1 is NULL then
               L_bucket_1 := 0;
            end if;
            LP_dist_tab(i).bucket_1 := L_bucket_1;
            close C_SNAPSHOT_ON_HAND_QTY;
         else
            if ITEMLOC_QUANTITY_SQL.GET_STOCK_ON_HAND(O_error_message,
                                                      LP_dist_tab(i).bucket_1,
                                                      LP_item,
                                                      LP_dist_tab(i).wh,
                                                      'W') = FALSE then
               return FALSE;
            end if;
         end if;
      else
         if INVADJ_SQL.GET_UNAVAILABLE(LP_item,
                                       'W',
                                       LP_dist_tab(i).wh,
                                       LP_dist_tab(i).bucket_1,
                                       O_error_message,
                                       L_found) = FALSE then
            return FALSE;
         end if;
      end if;
   end loop;

   --

   if GET_INBOUND_VWH(O_error_message,
                      L_dist_tab,
                      L_index_1,
                      L_index_2) = FALSE then
      return FALSE;
   end if;

   if L_dist_tab.count = 0 then
      return TRUE;
   end if;

   --

   -- the local L_dist_tab table is a subset of records in the global
   -- LP_dist_tab table which meet one of the rules of the 'inbound
   -- distribution rule 1'.  The distribution quantities are now calculated
   -- based on either the bucket_1 total or an even distribution. The global
   -- LP_dist_tab table is then set equal to the local L_dist_tab_table.

   for i in L_dist_tab.first .. L_dist_tab.last
   loop
      L_total := L_total + L_dist_tab(i).bucket_1;
   end loop;

   if L_total > 0 then
      for i in L_dist_tab.first .. L_dist_tab.last
      loop
         if LP_integer_rounding then
            L_dist_qty := L_remainder +
            (LP_qty_to_distribute * L_dist_tab(i).bucket_1 / L_total);
            --
            L_dist_tab(i).dist_qty := ROUND(L_dist_qty);
            L_remainder := L_dist_qty - L_dist_tab(i).dist_qty;
         else
            L_dist_tab(i).dist_qty := LP_qty_to_distribute *
            L_dist_tab(i).bucket_1 / L_total;
         end if;
      end loop;
   else
      for i in L_dist_tab.first .. L_dist_tab.last
      loop
         if LP_integer_rounding then
            L_dist_qty := L_remainder +
            (LP_qty_to_distribute / L_dist_tab.count);
            --
            L_dist_tab(i).dist_qty := ROUND(L_dist_qty);
            L_remainder := L_dist_qty - L_dist_tab(i).dist_qty;
         else
            L_dist_tab(i).dist_qty := LP_qty_to_distribute / L_dist_tab.count;
         end if;
      end loop;
   end if;

   LP_dist_tab := L_dist_tab;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                         SQLERRM,
                                         'DISTRIBUTION_SQL.INBOUND_DIST_RULE_1',
                                         to_char(SQLCODE));
      return FALSE;

END INBOUND_DIST_RULE_1;
--------------------------------------------------------------------------------

FUNCTION GET_INBOUND_VWH(O_error_message IN OUT VARCHAR2,
                         O_dist_tab      IN OUT INTERNAL_DIST_TABLE_TYPE,
                         I_index_1       IN     INTEGER,
                         I_index_2       IN     INTEGER)
RETURN BOOLEAN IS

i                  INTEGER;
j                  INTEGER;
L_restricted_ind   WH.RESTRICTED_IND%TYPE;

BEGIN

   /*
   *  records of the LP_dist_tab table between the indexes I_index_1 and
   *  I_index_2, that meet any of the following rules, are returned
   *     bucket_1 position   restricted_ind
   *           > 0                N
   *           > 0                Y
   *          <= 0                N
   *          <= 0                Y
   *
   *  the indexes indicate the first and last record of the LP_dist_tab table,
   *  with a particular item_loc status
   */

   --

   -- bucket_1 position > 0
   i := I_index_1;
   j := 0;
   L_restricted_ind := 'N';
   loop
      if LP_dist_tab(i).bucket_1 > 0 then
         if LP_dist_tab(i).restricted_ind = L_restricted_ind then
            j := j + 1;
            O_dist_tab(j) := LP_dist_tab(i);
         end if;
      end if;
      --
      if i = I_index_2 then
         if L_restricted_ind = 'N' and j = 0 then
            L_restricted_ind := 'Y';
            i := I_index_1;
         else
            exit;
         end if;
      else
         i := i + 1;
      end if;
   end loop;

   if j != 0 then
      return TRUE;
   end if;

   -- bucket_1 position <= 0
   i := I_index_1;
   j := 0;
   L_restricted_ind := 'N';
   loop
      if LP_dist_tab(i).bucket_1 <= 0 then
         if LP_dist_tab(i).restricted_ind = L_restricted_ind then
            j := j + 1;
            O_dist_tab(j) := LP_dist_tab(i);
         end if;
         --
         if i = I_index_2 then
            if L_restricted_ind = 'N' and j = 0 then
               L_restricted_ind := 'Y';
               i := I_index_1;
            else
               exit;
            end if;
         else
            i := i + 1;
         end if;
      end if;
   end loop;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DISTRIBUTION_SQL.GET_INBOUND_VWH',
                                            to_char(SQLCODE));
      return FALSE;

END GET_INBOUND_VWH;
--------------------------------------------------------------------------------

FUNCTION CREATE_ITEM_LOC_REL(O_error_message  IN OUT VARCHAR2,
                             O_wh             IN OUT WH.WH%TYPE,
                             I_il_create_rule IN     VARCHAR2)
RETURN BOOLEAN IS

L_wh         WH.WH%TYPE := null;
L_ind_type   VARCHAR2(1);

cursor C_PRIMARY_VWH(I_ind_type  VARCHAR2,
                     I_ind_value VARCHAR2) is
   select w.primary_vwh
     from wh w
    where not exists (select 'x'
                        from item_loc il
                       where il.loc = w.primary_vwh
                         and il.item = LP_item)
      and w.protected_ind = decode(I_ind_type,'P',I_ind_value,w.protected_ind)
      and w.restricted_ind = decode(I_ind_type,'R',I_ind_value,w.restricted_ind)
      and w.wh = LP_physical_wh;

cursor C_LOWEST_ID_VWH(I_ind_type  VARCHAR2,
                       I_ind_value VARCHAR2) is
   select min(w.wh)
     from wh w
    where not exists (select 'x'
                        from item_loc il
                       where il.loc = w.wh
                         and il.item = LP_item)
      and w.protected_ind = decode(I_ind_type,'P',I_ind_value,w.protected_ind)
      and w.restricted_ind = decode(I_ind_type,'R',I_ind_value,w.restricted_ind)
      and w.wh != w.physical_wh
      and w.physical_wh = LP_physical_wh;

BEGIN

   /*
   *  inbound distribution item-loc creation rule:
   *    protected_ind    primary_vwh   lowest_id_vwh
   *         N              X              -
   *         N              -              X
   *         Y              X              -
   *         Y              -              X
   *
   *  outbound distribution item-loc creation rule:
   *    restricted_ind   primary_vwh   lowest_id_vwh
   *         N              X              -
   *         N              -              X
   *         Y              X              -
   *         Y              -              X
   */

   --

   if I_il_create_rule = 'OUTBOUND' then
      L_ind_type := 'P';   -- based on protected_ind
   else
      L_ind_type := 'R';   -- based on restricted_ind
   end if;

   open C_PRIMARY_VWH(L_ind_type,'N');
   fetch C_PRIMARY_VWH into L_wh;
   close C_PRIMARY_VWH;
   --
   if L_wh is null then
      open C_LOWEST_ID_VWH(L_ind_type,'N');
      fetch C_LOWEST_ID_VWH into L_wh;
      close C_LOWEST_ID_VWH;
      --
      if L_wh is null then
         open C_PRIMARY_VWH(L_ind_type,'Y');
         fetch C_PRIMARY_VWH into L_wh;
         close C_PRIMARY_VWH;
         --
         if L_wh is null then
            open C_LOWEST_ID_VWH(L_ind_type,'Y');
            fetch C_LOWEST_ID_VWH into L_wh;
            close C_LOWEST_ID_VWH;
            --
            if L_wh is null then
               return TRUE;
            end if;
         end if;
      end if;
   end if;

   --

   if NEW_ITEM_LOC(O_error_message,
                   LP_item,
                   L_wh,
                   NULL, -- ITEM_PARENT
                   NULL, -- ITEM_GRANDPARENT
                   'W',  -- LOC_TYPE,
                   NULL, -- SHORT_DESC
                   NULL, -- DEPT
                   NULL, -- CLASS
                   NULL, -- SUBCLASS
                   NULL, -- ITEM_LEVEL,
                   NULL, -- TRAN_LEVEL,
                   NULL, -- ITEM_STATUS
                   NULL, -- ZONE_GROUP_ID
                   NULL, -- WASTE TYPE
                   NULL, -- DAILY WASTE PCT
                   NULL, -- SELLABLE_IND
                   NULL, -- ORDERABLE_IND
                   NULL, -- PACK_IND,
                   NULL, -- PACK_TYPE
                   NULL, -- UNIT_COST_LOC
                   NULL, -- UNIT_RETAIL_LOC
                   NULL, -- SELLING_RETAIL_LOC
                   NULL, -- SELLING_UOM
                   NULL, -- ITEM_LOC_STATUS
                   NULL, -- TAXABLE_IND
                   NULL, -- TI
                   NULL, -- HI
                   NULL, -- STORE_ORD_MULT
                   NULL, -- MEAS_OF_EACH
                   NULL, -- MEAS_OF_PRICE
                   NULL, -- UOM_OF_PRICE
                   NULL, -- PRIMARY_VARIANT
                   NULL, -- PRIMARY_SUPP
                   NULL, -- PRIMARY_CNTRY
                   NULL, -- LOCAL_ITEM_DESC
                   NULL, -- LOCAL_SHORT_DESC
                   NULL, -- PRIMARY_COST_PACK
                   NULL, -- RECEIVE_AS_TYPE
                   NULL, -- DATE,
                   NULL) -- DEFAULT_TO_CHILDREN
                   = FALSE then
      return FALSE;
   end if;

   O_wh := L_wh;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                        SQLERRM,
                                        'DISTRIBUTION_SQL.CREATE_ITEM_LOC_REL',
                                        to_char(SQLCODE));
      return FALSE;

END CREATE_ITEM_LOC_REL;
--------------------------------------------------------------------------------

FUNCTION SET_DIST_TAB_INDEXES(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   --
   -- set the global indexes for the first and last record of the LP_dist_tab
   -- table for protected and unprotected virtual warehouses

   LP_protected_tab_index_1 := null;
   LP_protected_tab_index_2 := null;
   LP_unprotected_tab_index_1 := null;
   LP_unprotected_tab_index_2 := null;

   if LP_dist_tab(1).protected_ind = 'Y' then
      LP_protected_tab_index_1 := 1;
      --
      for i in 1 .. LP_dist_tab.last
      loop
         if LP_dist_tab(i).protected_ind = 'N' then
            LP_unprotected_tab_index_1 := i;
            exit;
         end if;
      end loop;
   else
      LP_unprotected_tab_index_1 := 1;
      --
      for i in 1 .. LP_dist_tab.last
      loop
         if LP_dist_tab(i).protected_ind = 'Y' then
            LP_protected_tab_index_1 := i;
            exit;
         end if;
      end loop;
   end if;

   if LP_protected_tab_index_1 = 1 then
      if LP_unprotected_tab_index_1 is null then
         LP_protected_tab_index_2 := LP_dist_tab.last;
      else
         LP_protected_tab_index_2 := LP_unprotected_tab_index_1 - 1;
         LP_unprotected_tab_index_2 := LP_dist_tab.last;
      end if;
   else
      if LP_protected_tab_index_1 is null then
         LP_unprotected_tab_index_2 := LP_dist_tab.last;
      else
         LP_unprotected_tab_index_2 := LP_protected_tab_index_1 - 1;
         LP_protected_tab_index_2 := LP_dist_tab.last;
      end if;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                        SQLERRM,
                                        'DISTRIBUTION_SQL.SET_DIST_TAB_INDEXES',
                                        to_char(SQLCODE));
      return FALSE;

END SET_DIST_TAB_INDEXES;
--------------------------------------------------------------------------------

FUNCTION GET_DIST_TAB_INDEXES(O_error_message IN OUT VARCHAR2,
                              O_index_1       IN OUT INTEGER,
                              O_index_2       IN OUT INTEGER,
                              I_bucket_type   IN     VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   --
   -- return the indexes of the first and last record of the LP_dist_tab
   -- table for the requested bucket type

   if I_bucket_type = 'UNPROTECTED' then
      O_index_1 := LP_unprotected_tab_index_1;
      O_index_2 := LP_unprotected_tab_index_2;
   else
      O_index_1 := LP_protected_tab_index_1;
      O_index_2 := LP_protected_tab_index_2;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                        SQLERRM,
                                        'DISTRIBUTION_SQL.GET_DIST_TAB_INDEXES',
                                        to_char(SQLCODE));
      return FALSE;

END GET_DIST_TAB_INDEXES;
--------------------------------------------------------------------------------

FUNCTION SET_ITEM_ATTRIBUTES(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

L_uom_class   UOM_CLASS.UOM_CLASS%TYPE;

cursor C_UOM_CLASS is
   select uc.uom_class
     from uom_class uc,
          item_master im
    where im.item = LP_item
      and im.standard_uom = uc.uom;

BEGIN

   --
   -- set the golbal item attribute LP_integer_rounding

   open C_UOM_CLASS;
   fetch C_UOM_CLASS into L_uom_class;
   close C_UOM_CLASS;

   if L_uom_class = 'PACK' or L_uom_class = 'QTY' then
      LP_integer_rounding := TRUE;
   else
      LP_integer_rounding := FALSE;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                         SQLERRM,
                                         'DISTRIBUTION_SQL.SET_ITEM_ATTRIBUTES',
                                         to_char(SQLCODE));
      return FALSE;

END SET_ITEM_ATTRIBUTES;
--------------------------------------------------------------------------------

FUNCTION VALIDATE_INPUTS(O_error_message IN OUT VARCHAR2,
                         I_item          IN     ITEM_LOC.ITEM%TYPE,
                         I_loc           IN     ITEM_LOC.LOC%TYPE,
                         I_qty           IN     NUMBER,
                         I_CMI           IN     VARCHAR2,
                         I_shipment      IN     SHIPITEM_INV_FLOW.SHIPMENT%TYPE)
RETURN BOOLEAN IS

BEGIN

   --

   if I_item is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item',
                                            'NULL','NOT NULL');
      return FALSE;
   end if;

   if I_loc is null then
      -- if not TRANSFER_IN or TRANSFER_IN_ADJ
      if not (I_CMI = 'TRANSFER' and I_shipment is not null) then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc',
                                               'NULL','NOT NULL');
         return FALSE;
      end if;
   end if;

   if I_qty is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_qty',
                                            'NULL','NOT NULL');
      return FALSE;
   end if;

   if I_CMI not in ('RTV','INVADJ','TRANSFER','STKREC','ORDRCV') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_CMI',
                 nvl(I_CMI,'NULL'),'RTV | INVADJ | TRANSFER | STKREC | ORDRCV');
      return FALSE;
   end if;

   --

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DISTRIBUTION_SQL.VALIDATE_INPUTS',
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_INPUTS;
--------------------------------------------------------------------------------
FUNCTION GET_EG_TSF_DIST_VWH(O_error_message IN OUT VARCHAR2,
                             O_dist_vwh   IN OUT WH.WH%TYPE,
                             I_tsf_no     IN     TSFHEAD.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_program  VARCHAR2(40) := 'DISTRIBUTION_SQL.GET_EG_TSF_DIST_VWH';

   cursor C_GET_VWH is
      select sif.to_loc
        from shipitem_inv_flow sif,
             shipsku s
       where s.distro_no = I_tsf_no
         and s.shipment = sif.shipment;

BEGIN

   if I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open C_GET_VWH;
   fetch C_GET_VWH into O_dist_vwh;
   if C_GET_VWH%NOTFOUND then
      close C_GET_VWH;
      O_error_message := SQL_LIB.CREATE_MSG('NO_TSF_DIST_VWH',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;

   close C_GET_VWH;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_EG_TSF_DIST_VWH;
--------------------------------------------------------------------------------
END DISTRIBUTION_SQL;
/

