CREATE OR REPLACE PACKAGE BODY ITEMLOC_QUANTITY_SQL AS

LP_item                     ITEM_MASTER.ITEM%TYPE;
LP_item_level               ITEM_MASTER.ITEM_LEVEL%TYPE;
LP_tran_level               ITEM_MASTER.TRAN_LEVEL%TYPE;
LP_pack_ind                 ITEM_MASTER.PACK_IND%TYPE;
LP_wh_crosslink_ind         SYSTEM_OPTIONS.WH_CROSS_LINK_IND%TYPE;

cursor C_ITEM_INFO is
  select pack_ind,
         item_level,
         tran_level
    from item_master
   where item = LP_item;

--------------------------------------------------------------------------------------
/* New function is created for replinishment purpose */
FUNCTION GET_LOC_FUTURE_AVAIL
        (O_error_message    IN OUT VARCHAR2,
         O_available        IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_stock_on_hand    IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_soh    IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_in_transit_qty   IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_intran IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_tsf_expected_qty IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_exp    IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_on_order         IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_alloc_in         IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_rtv_qty          IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_alloc_out        IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_tsf_reserved_qty IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_resv   IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_non_sellable_qty IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item             IN     item_loc.item%TYPE,
         I_loc              IN     item_loc.loc%TYPE,
         I_loc_type         IN     item_loc.loc_type%TYPE,
         I_date             IN     DATE,
         I_all_orders       IN     VARCHAR2,
         I_order_point      IN     repl_results.order_point%TYPE,
         I_repl_ind         IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL';
   L_customer_resv          item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_backorder     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_back    item_loc_soh.stock_on_hand%TYPE := 0;
   L_dist_qty               alloc_detail.qty_distro%TYPE    := 0;
   L_pack_qty               item_loc_soh.stock_on_hand%TYPE := 0;


BEGIN
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc_type is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc_type',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if not GET_TRAN_ITEM_LOC_QTYS(O_error_message,
                                 O_stock_on_hand,
                                 O_pack_comp_soh,
                                 O_in_transit_qty,
                                 O_pack_comp_intran,
                                 O_tsf_reserved_qty,
                                 O_pack_comp_resv,
                                 O_tsf_expected_qty,
                                 O_pack_comp_exp,
                                 O_rtv_qty,
                                 O_non_sellable_qty,
                                 L_customer_resv,
                                 L_customer_backorder,
                                 L_pack_comp_cust_resv,
                                 L_pack_comp_cust_back,
                                 I_item,
                                 I_loc,
                                 I_loc_type) then
      return FALSE;
   end if;

   /* since these may or may not be populated depending on loc_type
      they are initialized to zero */
   O_alloc_in := 0;
   O_on_order := 0;

   if I_loc_type = 'W' then
      if not GET_ALLOC_OUT(I_item,
                           I_loc,
                           I_date,
                           O_alloc_out,
                           O_error_message) then
         return FALSE;
      end if;
      if not ITEMLOC_QUANTITY_SQL.GET_TOTAL_DIST_QTY(O_error_message,
                                                     L_dist_qty,
                                                     I_item,
                                                     I_loc,
                                                     I_loc_type,
                                                     I_date,
                                                     I_repl_ind) then
         return FALSE;
      end if;

   else
      O_alloc_out := 0;
   end if;

   O_available := (GREATEST(O_stock_on_hand, 0) + O_pack_comp_soh +
                   O_in_transit_qty + O_pack_comp_intran +
                   O_tsf_expected_qty + O_pack_comp_exp +
                   O_on_order + O_alloc_in)
                 - (O_rtv_qty + O_alloc_out + L_dist_qty +
                    O_tsf_reserved_qty + O_pack_comp_resv +
                    GREATEST(O_non_sellable_qty,0) +
                    L_customer_resv + L_customer_backorder +
                    L_pack_comp_cust_resv + L_pack_comp_cust_back);

   if (I_order_point >= O_available) or (I_order_point = 0) then

      if not GET_ON_ORDER(I_item,
                          I_loc,
                          I_loc_type,
                          I_date,
                          I_all_orders,
                          O_on_order,
                          L_pack_qty,
                          O_error_message) then
         return FALSE;
      end if;

      if not GET_ALLOC_IN(I_item,
                          I_loc,
                          I_loc_type,
                          I_date,
                          I_all_orders,
                          I_repl_ind,
                          O_alloc_in,
                          O_error_message) then
         return FALSE;
      end if;

      O_available := (GREATEST(O_stock_on_hand, 0) + O_pack_comp_soh +
                      O_in_transit_qty + O_pack_comp_intran +
                      O_tsf_expected_qty + O_pack_comp_exp +
                      O_on_order + O_alloc_in)
                    - (O_rtv_qty + O_alloc_out + L_dist_qty +
                       O_tsf_reserved_qty + O_pack_comp_resv +
                       GREATEST(O_non_sellable_qty,0) +
                       L_customer_resv + L_customer_backorder +
                       L_pack_comp_cust_resv + L_pack_comp_cust_back);
   end if;

   if O_available < 0 then
      O_available := 0;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_LOC_FUTURE_AVAIL;

--------------------------------------------------------------------------------------
FUNCTION GET_LOC_FUTURE_AVAIL
        (O_error_message    IN OUT VARCHAR2,
         O_available        IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_stock_on_hand    IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_soh    IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_in_transit_qty   IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_intran IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_tsf_expected_qty IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_exp    IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_on_order         IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_alloc_in         IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_rtv_qty          IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_alloc_out        IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_tsf_reserved_qty IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_resv   IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_non_sellable_qty IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item             IN     item_loc.item%TYPE,
         I_loc              IN     item_loc.loc%TYPE,
         I_loc_type         IN     item_loc.loc_type%TYPE,
         I_date             IN     DATE,
         I_all_orders       IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL';
   L_customer_resv          item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_backorder     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_back    item_loc_soh.stock_on_hand%TYPE := 0;
   L_dist_qty               alloc_detail.qty_distro%TYPE    := 0;
   L_pack_qty               item_loc_soh.stock_on_hand%TYPE := 0;


BEGIN
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc_type is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc_type',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if not GET_ITEM_LOC_QTYS(O_error_message,
                            O_stock_on_hand,
                            O_pack_comp_soh,
                            O_in_transit_qty,
                            O_pack_comp_intran,
                            O_tsf_reserved_qty,
                            O_pack_comp_resv,
                            O_tsf_expected_qty,
                            O_pack_comp_exp,
                            O_rtv_qty,
                            O_non_sellable_qty,
                            L_customer_resv,
                            L_customer_backorder,
                            L_pack_comp_cust_resv,
                            L_pack_comp_cust_back,
                            I_item,
                            I_loc,
                            I_loc_type) then
      return FALSE;
   end if;

   /* since these may or may not be populated depending on loc_type
      they are initialized to zero */
   O_alloc_in := 0;


   if not GET_ON_ORDER(I_item,
                       I_loc,
                       I_loc_type,
                       I_date,
                       I_all_orders,
                       O_on_order,
                       L_pack_qty,
                       O_error_message) then
      return FALSE;
   end if;

   if not GET_ALLOC_IN(I_item,
                       I_loc,
                       I_loc_type,
                       I_date,
                       I_all_orders,
                       O_alloc_in,
                       O_error_message) then
      return FALSE;
   end if;

   if I_loc_type = 'W' then
      if not GET_ALLOC_OUT(I_item,
                           I_loc,
                           I_date,
                           O_alloc_out,
                           O_error_message) then
         return FALSE;
      end if;

      if not ITEMLOC_QUANTITY_SQL.GET_TOTAL_DIST_QTY(O_error_message,
                                                  L_dist_qty,
                                                  I_item,
                                                  I_loc,
                                                  I_loc_type,
                                                  NULL) then
         return FALSE;
      end if;

   else
      O_alloc_out := 0;
   end if;

   O_available := (GREATEST(O_stock_on_hand, 0) + O_pack_comp_soh +
                   O_in_transit_qty + O_pack_comp_intran +
                   O_tsf_expected_qty + O_pack_comp_exp +
                   O_on_order + O_alloc_in)
                 - (O_rtv_qty + O_alloc_out + L_dist_qty +
                    O_tsf_reserved_qty + O_pack_comp_resv +
                    GREATEST(O_non_sellable_qty,0) +
                    L_customer_resv + L_customer_backorder +
                    L_pack_comp_cust_resv + L_pack_comp_cust_back);

   if O_available < 0 then
      O_available := 0;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_LOC_FUTURE_AVAIL;

--------------------------------------------------------------------------------------
FUNCTION GET_LOC_FUTURE_AVAIL
        (O_error_message  IN OUT VARCHAR2,
         O_available      IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item           IN     item_loc.item%TYPE,
         I_loc            IN     item_loc.loc%TYPE,
         I_loc_type       IN     item_loc.loc_type%TYPE,
         I_date           IN     DATE,
         I_all_orders     IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL';

   L_soh               item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_soh     item_loc_soh.stock_on_hand%TYPE := 0;
   L_in_transit        item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_intran  item_loc_soh.stock_on_hand%TYPE := 0;
   L_expected          item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp     item_loc_soh.stock_on_hand%TYPE := 0;
   L_on_order          item_loc_soh.stock_on_hand%TYPE := 0;
   L_alloc_in          item_loc_soh.stock_on_hand%TYPE := 0;
   L_rtv               item_loc_soh.stock_on_hand%TYPE := 0;
   L_alloc_out         item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_reserved_qty  item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_non_sellable_qty  item_loc_soh.stock_on_hand%TYPE := 0;

BEGIN

   O_available := 0;

   if not GET_LOC_FUTURE_AVAIL(O_error_message,
                               O_available,
                               L_soh,
                               L_pack_comp_soh,
                               L_in_transit,
                               L_pack_comp_intran,
                               L_expected,
                               L_pack_comp_exp,
                               L_on_order,
                               L_alloc_in,
                               L_rtv,
                               L_alloc_out,
                               L_tsf_reserved_qty,
                               L_pack_comp_resv,
                               L_non_sellable_qty,
                               I_item,
                               I_loc,
                               I_loc_type,
                               I_date,
                               I_all_orders) then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_LOC_FUTURE_AVAIL;

--------------------------------------------------------------------------------------
-- New function with parameter I_include_pack_comp

FUNCTION GET_LOC_FUTURE_AVAIL
        (O_error_message     IN OUT VARCHAR2,
         O_available         IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_stock_on_hand     IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_soh     IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_in_transit_qty    IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_intran  IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_tsf_expected_qty  IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_exp     IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_on_order          IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_alloc_in          IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_rtv_qty           IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_alloc_out         IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_tsf_reserved_qty  IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_resv    IN OUT item_loc_soh.stock_on_hand%TYPE,
         O_non_sellable_qty  IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item              IN     item_loc.item%TYPE,
         I_loc               IN     item_loc.loc%TYPE,
         I_loc_type          IN     item_loc.loc_type%TYPE,
         I_date              IN     DATE,
         I_all_orders        IN     VARCHAR2,
         I_include_pack_comp IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL';
   L_customer_resv          item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_backorder     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_back    item_loc_soh.stock_on_hand%TYPE := 0;
   L_dist_qty               alloc_detail.qty_distro%TYPE    := 0;
   L_pack_qty               item_loc_soh.stock_on_hand%TYPE := 0;


BEGIN
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc_type is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc_type',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if not GET_ITEM_LOC_QTYS(O_error_message,
                            O_stock_on_hand,
                            O_pack_comp_soh,
                            O_in_transit_qty,
                            O_pack_comp_intran,
                            O_tsf_reserved_qty,
                            O_pack_comp_resv,
                            O_tsf_expected_qty,
                            O_pack_comp_exp,
                            O_rtv_qty,
                            O_non_sellable_qty,
                            L_customer_resv,
                            L_customer_backorder,
                            L_pack_comp_cust_resv,
                            L_pack_comp_cust_back,
                            I_item,
                            I_loc,
                            I_loc_type) then
      return FALSE;
   end if;

   /* since these may or may not be populated depending on loc_type
      they are initialized to zero */
   O_alloc_in := 0;


   if not GET_ON_ORDER(I_item,
                       I_loc,
                       I_loc_type,
                       I_date,
                       I_all_orders,
                       O_on_order,
                       L_pack_qty,
                       O_error_message) then
      return FALSE;
   end if;

   if not GET_ALLOC_IN(I_item,
                       I_loc,
                       I_loc_type,
                       I_date,
                       I_all_orders,
                       O_alloc_in,
                       O_error_message) then
      return FALSE;
   end if;

   if I_loc_type = 'W' then
      if not GET_ALLOC_OUT(I_item,
                           I_loc,
                           I_date,
                           O_alloc_out,
                           O_error_message) then
         return FALSE;
      end if;

      if not ITEMLOC_QUANTITY_SQL.GET_TOTAL_DIST_QTY(O_error_message,
                                                  L_dist_qty,
                                                  I_item,
                                                  I_loc,
                                                  I_loc_type,
                                                  NULL) then
         return FALSE;
      end if;

   else
      O_alloc_out := 0;
   end if;

   if I_include_pack_comp = 'Y' then
      O_available := (GREATEST(O_stock_on_hand, 0) + O_pack_comp_soh +
                   O_in_transit_qty + O_pack_comp_intran +
                   O_tsf_expected_qty + O_pack_comp_exp +
                   O_on_order + O_alloc_in)
                 - (O_rtv_qty + O_alloc_out + L_dist_qty +
                    O_tsf_reserved_qty + O_pack_comp_resv +
                    GREATEST(O_non_sellable_qty,0) +
                    L_customer_resv + L_customer_backorder +
                    L_pack_comp_cust_resv + L_pack_comp_cust_back);
   else
      O_available := (GREATEST(O_stock_on_hand, 0) +
                   O_in_transit_qty +
                   O_tsf_expected_qty +
                   O_on_order + O_alloc_in)
                 - (O_rtv_qty + O_alloc_out + L_dist_qty +
                    O_tsf_reserved_qty +
                    GREATEST(O_non_sellable_qty,0) +
                    L_customer_resv + L_customer_backorder);
   end if;

   if O_available < 0 then
      O_available := 0;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_LOC_FUTURE_AVAIL;

--------------------------------------------------------------------------------------
-- Function Name: GET_LOC_FUTURE_AVAIL
-- Purpose: Overloads the other GET_LOC_FUTURE_AVAIL functions
--          with I_include_pack_component indicator.  This function is called
--          by the allocation product.
--          When the I_include_pack_comp indicator is 'Y" or null, then
--          the future available quantity will include all inventory including
--          the component quantities within the pack
--------------------------------------------------------------------------------------
FUNCTION GET_LOC_FUTURE_AVAIL
        (O_error_message      IN OUT VARCHAR2,
         O_available          IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item               IN     item_loc.item%TYPE,
         I_loc                IN     item_loc.loc%TYPE,
         I_loc_type           IN     item_loc.loc_type%TYPE,
         I_date               IN     DATE,
         I_all_orders         IN     VARCHAR2,
         I_include_pack_comp  IN     VARCHAR2)
RETURN BOOLEAN IS

  L_program    VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL';

   L_soh               item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_soh     item_loc_soh.stock_on_hand%TYPE := 0;
   L_in_transit        item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_intran  item_loc_soh.stock_on_hand%TYPE := 0;
   L_expected          item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp     item_loc_soh.stock_on_hand%TYPE := 0;
   L_on_order          item_loc_soh.stock_on_hand%TYPE := 0;
   L_alloc_in          item_loc_soh.stock_on_hand%TYPE := 0;
   L_rtv               item_loc_soh.stock_on_hand%TYPE := 0;
   L_alloc_out         item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_reserved_qty  item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_non_sellable_qty  item_loc_soh.stock_on_hand%TYPE := 0;

BEGIN

   O_available := 0;

   if not GET_LOC_FUTURE_AVAIL(O_error_message,
                               O_available,
                               L_soh,
                               L_pack_comp_soh,
                               L_in_transit,
                               L_pack_comp_intran,
                               L_expected,
                               L_pack_comp_exp,
                               L_on_order,
                               L_alloc_in,
                               L_rtv,
                               L_alloc_out,
                               L_tsf_reserved_qty,
                               L_pack_comp_resv,
                               L_non_sellable_qty,
                               I_item,
                               I_loc,
                               I_loc_type,
                               I_date,
                               I_all_orders,
			       I_include_pack_comp) then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_LOC_FUTURE_AVAIL;

--------------------------------------------------------------------------------------
FUNCTION GET_LOC_CURRENT_AVAIL
        (O_error_message  IN OUT VARCHAR2,
         O_available      IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item           IN     item_loc.item%TYPE,
         I_loc            IN     item_loc.loc%TYPE,
         I_loc_type       IN     item_loc.loc_type%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_LOC_CURRENT_AVAIL';

   L_soh                    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_soh          item_loc_soh.stock_on_hand%TYPE := 0;
   L_in_transit_qty         item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_intran       item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_reserved_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_resv         item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_expected_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp          item_loc_soh.stock_on_hand%TYPE := 0;
   L_rtv_qty                item_loc_soh.stock_on_hand%TYPE := 0;
   L_non_sellable_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_resv          item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_backorder     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_back    item_loc_soh.stock_on_hand%TYPE := 0;
   L_dist_qty               alloc_detail.qty_distro%TYPE    := 0;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc_type is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc_type',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   O_available := 0;

   if not ITEMLOC_QUANTITY_SQL.GET_ITEM_LOC_QTYS(O_error_message,
                                                 L_soh,
                                                 L_pack_comp_soh,
                                                 L_in_transit_qty,
                                                 L_pack_comp_intran,
                                                 L_tsf_reserved_qty,
                                                 L_pack_comp_resv,
                                                 L_tsf_expected_qty,
                                                 L_pack_comp_exp,
                                                 L_rtv_qty,
                                                 L_non_sellable_qty,
                                                 L_customer_resv,
                                                 L_customer_backorder,
                                                 L_pack_comp_cust_resv,
                                                 L_pack_comp_cust_back,
                                                 I_item,
                                                 I_loc,
                                                 I_loc_type) then
      return FALSE;
   end if;

   if not ITEMLOC_QUANTITY_SQL.GET_TOTAL_DIST_QTY(O_error_message,
                                                  L_dist_qty,
                                                  I_item,
                                                  I_loc,
                                                  I_loc_type,
                                                  NULL) then
      return FALSE;
   end if;

   O_available := GREATEST(L_soh, 0)
                  - (L_tsf_reserved_qty + L_rtv_qty +
                     GREATEST(L_non_sellable_qty, 0) + L_dist_qty +
                     L_customer_resv + L_customer_backorder);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_LOC_CURRENT_AVAIL;

--------------------------------------------------------------------------------------
/* New function being called from reqext.pc*/
FUNCTION GET_LOC_CURRENT_AVAIL
        (O_error_message  IN OUT VARCHAR2,
         O_available      IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item           IN     item_loc.item%TYPE,
         I_loc            IN     item_loc.loc%TYPE,
         I_loc_type       IN     item_loc.loc_type%TYPE,
         I_repl_ind       IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program      VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_LOC_CURRENT_AVAIL';

   L_soh                    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_soh          item_loc_soh.stock_on_hand%TYPE := 0;
   L_in_transit_qty         item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_intran       item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_reserved_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_resv         item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_expected_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp          item_loc_soh.stock_on_hand%TYPE := 0;
   L_rtv_qty                item_loc_soh.stock_on_hand%TYPE := 0;
   L_non_sellable_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_resv          item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_backorder     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_back    item_loc_soh.stock_on_hand%TYPE := 0;
   L_dist_qty               alloc_detail.qty_distro%TYPE    := 0;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc_type is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_loc_type',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   O_available := 0;

   if not GET_TRAN_ITEM_LOC_QTYS(O_error_message,
                                 L_soh,
                                 L_pack_comp_soh,
                                 L_in_transit_qty,
                                 L_pack_comp_intran,
                                 L_tsf_reserved_qty,
                                 L_pack_comp_resv,
                                 L_tsf_expected_qty,
                                 L_pack_comp_exp,
                                 L_rtv_qty,
                                 L_non_sellable_qty,
                                 L_customer_resv,
                                 L_customer_backorder,
                                 L_pack_comp_cust_resv,
                                 L_pack_comp_cust_back,
                                 I_item,
                                 I_loc,
                                 I_loc_type) then
      return FALSE;
   end if;

   if not ITEMLOC_QUANTITY_SQL.GET_TOTAL_DIST_QTY(O_error_message,
                                                  L_dist_qty,
                                                  I_item,
                                                  I_loc,
                                                  I_loc_type,
                                                  NULL,
                                                  I_repl_ind) then
      return FALSE;
   end if;

   O_available := GREATEST(L_soh, 0)
                  - (L_tsf_reserved_qty + L_rtv_qty +
                     GREATEST(L_non_sellable_qty, 0) + L_dist_qty +
                     L_customer_resv + L_customer_backorder);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_LOC_CURRENT_AVAIL;

--------------------------------------------------------------------------------------
FUNCTION GET_STOCK_ON_HAND
        (O_error_message  IN OUT VARCHAR2,
         O_quantity       IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item           IN     item_loc.item%TYPE,
         I_loc            IN     item_loc.loc%TYPE,
         I_loc_type       IN     item_loc.loc_type%TYPE)

RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_STOCK_ON_HAND';

   L_pack_comp_soh          item_loc_soh.stock_on_hand%TYPE := 0;
   L_in_transit_qty         item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_intran       item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_reserved_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_resv         item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_expected_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp          item_loc_soh.stock_on_hand%TYPE := 0;
   L_rtv_qty                item_loc_soh.stock_on_hand%TYPE := 0;
   L_non_sellable_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_resv          item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_backorder     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_back    item_loc_soh.stock_on_hand%TYPE := 0;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   O_quantity := 0;

   if not ITEMLOC_QUANTITY_SQL.GET_ITEM_LOC_QTYS(O_error_message,
                                                 O_quantity,
                                                 L_pack_comp_soh,
                                                 L_in_transit_qty,
                                                 L_pack_comp_intran,
                                                 L_tsf_reserved_qty,
                                                 L_pack_comp_resv,
                                                 L_tsf_expected_qty,
                                                 L_pack_comp_exp,
                                                 L_rtv_qty,
                                                 L_non_sellable_qty,
                                                 L_customer_resv,
                                                 L_customer_backorder,
                                                 L_pack_comp_cust_resv,
                                                 L_pack_comp_cust_back,
                                                 I_item,
                                                 I_loc,
                                                 I_loc_type) then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_STOCK_ON_HAND;

--------------------------------------------------------------------------------------
FUNCTION GET_ITEM_STOCK
        (O_error_message            IN OUT  VARCHAR2,
         O_soh_all_store            IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_soh_all_wh               IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_soh_all_i                IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_soh_all_e                IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_comp_soh_all_wh          IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_comp_soh_all_i           IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_intran_all_store         IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_intran_all_wh            IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_intran_all_i             IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_intran_all_ext_fin       IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_comp_intran_all_wh       IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_comp_intran_all_i        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_resv_all_store           IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_resv_all_wh              IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_resv_all_i               IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_resv_all_ext_fin         IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_comp_resv_all_wh         IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_comp_resv_all_i          IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_exp_all_store            IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_exp_all_wh               IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_exp_all_i                IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_exp_all_ext_fin          IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_comp_exp_all_wh          IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_comp_exp_all_i           IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_non_sell_all_store       IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_non_sell_all_wh          IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_non_sell_all_i           IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_non_sell_all_ext_fin     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_rtv_all_store            IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_rtv_all_wh               IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_rtv_all_i                IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_rtv_all_ext_fin          IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_customer_resv            IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_cust_resv      IN OUT  item_loc_soh.stock_on_hand%TYPE,
         I_item                     IN      item_loc.item%TYPE,
         I_loc_type                 IN      item_loc.loc_type%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ITEM_STOCK';

   L_pack_comp_soh          item_loc_soh.stock_on_hand%TYPE;
   L_pack_comp_intran       item_loc_soh.stock_on_hand%TYPE;
   L_pack_comp_resv         item_loc_soh.stock_on_hand%TYPE;
   L_pack_comp_exp          item_loc_soh.stock_on_hand%TYPE;
   L_dummy                  item_loc_soh.stock_on_hand%TYPE;

   L_customer_backorder     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_back    item_loc_soh.stock_on_hand%TYPE := 0;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_loc_type = 'S' or I_loc_type is NULL then

      if not ITEMLOC_QUANTITY_SQL.GET_ITEM_LOC_QTYS(O_error_message,
                                                    O_soh_all_store,
                                                    L_pack_comp_soh,
                                                    O_intran_all_store,
                                                    L_pack_comp_intran,
                                                    O_resv_all_store,
                                                    L_pack_comp_resv,
                                                    O_exp_all_store,
                                                    L_pack_comp_exp,
                                                    O_rtv_all_store,
                                                    O_non_sell_all_store,
                                                    O_customer_resv,
                                                    L_customer_backorder,
                                                    L_pack_comp_cust_resv,
                                                    L_pack_comp_cust_back,
                                                    I_item,
                                                    NULL,
                                                    'S') then
         return FALSE;
      end if;
   end if;

   if I_loc_type = 'W' or I_loc_type is NULL then

      if not ITEMLOC_QUANTITY_SQL.GET_ITEM_LOC_QTYS(O_error_message,
                                                    O_soh_all_wh,
                                                    O_comp_soh_all_wh,
                                                    O_intran_all_wh,
                                                    O_comp_intran_all_wh,
                                                    O_resv_all_wh,
                                                    O_comp_resv_all_wh,
                                                    O_exp_all_wh,
                                                    O_comp_exp_all_wh,
                                                    O_rtv_all_wh,
                                                    O_non_sell_all_wh,
                                                    O_customer_resv,
                                                    L_customer_backorder,
                                                    O_pack_comp_cust_resv,
                                                    L_pack_comp_cust_back,
                                                    I_item,
                                                    NULL,
                                                    'W') then
         return FALSE;
      end if;
   end if;

   if I_loc_type = 'I' or I_loc_type is NULL then

      if not ITEMLOC_QUANTITY_SQL.GET_ITEM_LOC_QTYS(O_error_message,
                                                    O_soh_all_i,
                                                    O_comp_soh_all_i,
                                                    O_intran_all_i,
                                                    O_comp_intran_all_i,
                                                    O_resv_all_i,
                                                    O_comp_resv_all_i,
                                                    O_exp_all_i,
                                                    O_comp_exp_all_i,
                                                    O_rtv_all_i,
                                                    O_non_sell_all_i,
                                                    O_customer_resv,
                                                    L_customer_backorder,
                                                    O_pack_comp_cust_resv,
                                                    L_pack_comp_cust_back,
                                                    I_item,
                                                    NULL,
                                                    'I') then
         return FALSE;
      end if;

   end if;

   if I_loc_type = 'E' or I_loc_type is NULL then

      if not ITEMLOC_QUANTITY_SQL.GET_ITEM_LOC_QTYS(O_error_message,
                                                    O_soh_all_e,
                                                    L_pack_comp_soh,
                                                    O_intran_all_ext_fin,
                                                    L_pack_comp_intran,
                                                    O_resv_all_ext_fin,
                                                    L_pack_comp_resv,
                                                    O_exp_all_ext_fin,
                                                    L_pack_comp_exp,
                                                    O_rtv_all_ext_fin,
                                                    O_non_sell_all_ext_fin,
                                                    O_customer_resv,
                                                    L_customer_backorder,
                                                    L_pack_comp_cust_resv,
                                                    L_pack_comp_cust_back,
                                                    I_item,
                                                    NULL,
                                                    'E') then
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ITEM_STOCK;

--------------------------------------------------------------------------------------
FUNCTION GET_ITEM_LOC_QTYS
        (O_error_message        IN OUT  VARCHAR2,
         O_stock_on_hand        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_soh        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_in_transit_qty       IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_intran     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_tsf_reserved_qty     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_resv       IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_tsf_expected_qty     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_exp        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_rtv_qty              IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_non_sellable_qty     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_customer_resv        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_customer_backorder   IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_cust_resv  IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_cust_back  IN OUT  item_loc_soh.stock_on_hand%TYPE,
         I_item                 IN      item_loc.item%TYPE,
         I_loc                  IN      item_loc.loc%TYPE,
         I_loc_type             IN      item_loc.loc_type%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ITEM_LOC_QTYS';
   L_tsf_expected_qty  item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pl_tsf_item_qty   tsfdetail.tsf_qty%TYPE := 0;
   L_pl_tsf_pack_qty   tsfdetail.tsf_qty%TYPE := 0;

   cursor C_SOH_ALL_WH is
      select /*+ INDEX(item_loc_soh, pk_item_loc_soh) INDEX(item_loc_soh, item_loc_soh_I3) INDEX(item_loc_soh, item_loc_soh_I4) */
             nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh, wh
       where loc_type = 'W'
         and loc = wh.wh
         and wh.finisher_ind = 'N'
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_ALL_I is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh,
             wh
       where loc_type = 'W'
         and loc = wh.wh
         and wh.finisher_ind = 'Y'
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_ALL_ST is
      select /*+ INDEX(item_loc_soh, pk_item_loc_soh) INDEX(item_loc_soh, item_loc_soh_I3) INDEX(item_loc_soh, item_loc_soh_I4) */
             nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh
       where loc_type = 'S'
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_ALL_E is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh
       where loc_type = 'E'
         and (item = TO_CHAR(I_item) or
              item_parent = TO_CHAR(I_item) or
              item_grandparent = TO_CHAR(I_item));

   cursor C_SOH_ALL is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh
       where (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_LOC is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh
       where loc = I_loc
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);



   BEGIN

   if (LP_wh_crosslink_ind is NULL) then
     if not SYSTEM_OPTIONS_SQL.GET_WH_CROSS_LINK_IND(O_error_message,
                                                     LP_wh_crosslink_ind) then
        return FALSE;
     end if;
   end if;

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_loc is not NULL then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_LOC', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      open C_SOH_LOC;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_LOC', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      fetch C_SOH_LOC into O_stock_on_hand,
                           O_pack_comp_soh,
                           O_in_transit_qty,
                           O_pack_comp_intran,
                           O_tsf_reserved_qty,
                           O_pack_comp_resv,
                           L_tsf_expected_qty,
                           L_pack_comp_exp,
                           O_rtv_qty,
                           O_non_sellable_qty,
                           O_customer_resv,
                           O_customer_backorder,
                           O_pack_comp_cust_resv,
                           O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_LOC', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      close C_SOH_LOC;

   elsif I_loc_type is NULL then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL into O_stock_on_hand,
                           O_pack_comp_soh,
                           O_in_transit_qty,
                           O_pack_comp_intran,
                           O_tsf_reserved_qty,
                           O_pack_comp_resv,
                           L_tsf_expected_qty,
                           L_pack_comp_exp,
                           O_rtv_qty,
                           O_non_sellable_qty,
                           O_customer_resv,
                           O_customer_backorder,
                           O_pack_comp_cust_resv,
                           O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL;

   elsif I_loc_type = 'S' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL_ST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL_ST;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL_ST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL_ST into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL_ST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL_ST;

   elsif I_loc_type = 'W' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL_WH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL_WH;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL_WH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL_WH into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL_WH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL_WH;

   elsif I_loc_type = 'I' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL_I', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL_I;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL_I', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL_I into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL_I', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL_I;

   elsif I_loc_type = 'E' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL_E', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL_E;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL_E', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL_E into O_stock_on_hand,
                             O_pack_comp_soh,
                             O_in_transit_qty,
                             O_pack_comp_intran,
                             O_tsf_reserved_qty,
                             O_pack_comp_resv,
                             L_tsf_expected_qty,
                             L_pack_comp_exp,
                             O_rtv_qty,
                             O_non_sellable_qty,
                             O_customer_resv,
                             O_customer_backorder,
                             O_pack_comp_cust_resv,
                             O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL_E', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL_E;

   end if;

   if ((I_loc_type != 'W' or I_loc_type is NULL) and
        LP_wh_crosslink_ind = 'Y') then
      if not GET_PL_TRANSFER(O_error_message,
                             L_pl_tsf_item_qty,
                             L_pl_tsf_pack_qty,
                             I_item,
                             I_loc,
                             I_loc_type,
                             NULL) then
         return FALSE;
      end if;

      O_tsf_expected_qty := L_tsf_expected_qty +
                            L_pl_tsf_item_qty;
      O_pack_comp_exp := L_pack_comp_exp +
                         L_pl_tsf_pack_qty;
   else
      O_tsf_expected_qty := L_tsf_expected_qty;
      O_pack_comp_exp := L_pack_comp_exp;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ITEM_LOC_QTYS;

--------------------------------------------------------------------------------------
FUNCTION GET_TRANSFER_OUT
        (O_error_message  IN OUT VARCHAR2,
         O_quantity       IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item           IN     item_loc.item%TYPE,
         I_loc            IN     item_loc.loc%TYPE,
         I_loc_type       IN     item_loc.loc_type%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_TRANSFER_OUT';

   L_stock_on_hand          item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_soh          item_loc_soh.stock_on_hand%TYPE := 0;
   L_in_transit_qty         item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_intran       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_resv         item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_expected_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp          item_loc_soh.stock_on_hand%TYPE := 0;
   L_rtv_qty                item_loc_soh.stock_on_hand%TYPE := 0;
   L_non_sellable_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_resv          item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_backorder     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_back    item_loc_soh.stock_on_hand%TYPE := 0;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if not ITEMLOC_QUANTITY_SQL.GET_ITEM_LOC_QTYS(O_error_message,
                                                 L_stock_on_hand,
                                                 L_pack_comp_soh,
                                                 L_in_transit_qty,
                                                 L_pack_comp_intran,
                                                 O_quantity, /* tsf_reserved_qty */
                                                 L_pack_comp_resv,
                                                 L_tsf_expected_qty,
                                                 L_pack_comp_exp,
                                                 L_rtv_qty,
                                                 L_non_sellable_qty,
                                                 L_customer_resv,
                                                 L_customer_backorder,
                                                 L_pack_comp_cust_resv,
                                                 L_pack_comp_cust_back,
                                                 I_item,
                                                 I_loc,
                                                 I_loc_type) then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TRANSFER_OUT;

--------------------------------------------------------------------------------------
FUNCTION GET_TRANSFER
        (O_error_message   IN OUT VARCHAR2,
         O_quantity        IN OUT item_loc_soh.stock_on_hand%TYPE,
         I_item            IN     item_loc.item%TYPE,
         I_loc             IN     item_loc.loc%TYPE,
         I_loc_type        IN     item_loc.loc_type%TYPE,
         I_include_pack_wh IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program     VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_TRANSFER';

   L_stock_on_hand          item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_soh          item_loc_soh.stock_on_hand%TYPE := 0;
   L_in_transit_qty         item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_intran       item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_reserved_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_resv         item_loc_soh.stock_on_hand%TYPE := 0;
   L_tsf_expected_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp          item_loc_soh.stock_on_hand%TYPE := 0;
   L_rtv_qty                item_loc_soh.stock_on_hand%TYPE := 0;
   L_non_sellable_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_resv          item_loc_soh.stock_on_hand%TYPE := 0;
   L_customer_backorder     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_resv    item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_cust_back    item_loc_soh.stock_on_hand%TYPE := 0;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if not ITEMLOC_QUANTITY_SQL.GET_ITEM_LOC_QTYS(O_error_message,
                                                 L_stock_on_hand,
                                                 L_pack_comp_soh,
                                                 L_in_transit_qty,
                                                 L_pack_comp_intran,
                                                 L_tsf_reserved_qty,
                                                 L_pack_comp_resv,
                                                 L_tsf_expected_qty,
                                                 L_pack_comp_exp,
                                                 L_rtv_qty,
                                                 L_non_sellable_qty,
                                                 L_customer_resv,
                                                 L_customer_backorder,
                                                 L_pack_comp_cust_resv,
                                                 L_pack_comp_cust_back,
                                                 I_item,
                                                 I_loc,
                                                 I_loc_type) then
      return FALSE;
   end if;

   if I_include_pack_wh = 'Y' then
      O_quantity := L_in_transit_qty + L_pack_comp_intran;
   else
      O_quantity := L_in_transit_qty;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TRANSFER;

FUNCTION GET_ONLINE_STOCK
                (I_item             IN     ITEM_LOC.ITEM%TYPE,
                 I_loc              IN     ITEM_LOC.LOC%TYPE,
                 I_loc_type         IN     ITEM_LOC.LOC_TYPE%TYPE,
                 I_date             IN     DATE,
                 I_all_orders       IN     VARCHAR2,
                 O_on_order         IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                 O_in_allocs        IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                 O_out_allocs       IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                 O_error_message    IN OUT VARCHAR2)
RETURN BOOLEAN IS

   L_program      VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ONLINE_STOCK';
   L_pack_qty     ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

BEGIN

   if (LP_item != I_item or LP_item is NULL) then
      LP_item := I_item;

     SQL_LIB.SET_MARK('OPEN', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
     open C_ITEM_INFO;
     SQL_LIB.SET_MARK('FETCH', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
     fetch C_ITEM_INFO into LP_pack_ind,
                            LP_item_level,
                            LP_tran_level;
     SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
     close C_ITEM_INFO;

   end if;

   if not GET_ON_ORDER
       (I_item,
        I_loc,
        I_loc_type,
        I_date,
        I_all_orders,
        O_on_order,
        L_pack_qty,
        O_error_message) then
      return FALSE;
   end if;

   if not GET_ALLOC_IN
       (I_item,
        I_loc,
        I_loc_type,
        I_date,
        I_all_orders,
        O_in_allocs,
        O_error_message) then
      return FALSE;
   end if;

   if I_loc_type = 'W' then
      if not GET_ALLOC_OUT
           (I_item,
            I_loc,
            I_date,
            O_out_allocs,
            O_error_message) then
          return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ONLINE_STOCK;

--------------------------------------------------------------------------------------
FUNCTION GET_ON_ORDER(I_item           IN     ITEM_LOC.ITEM%TYPE,
                      I_loc            IN     ITEM_LOC.LOC%TYPE,
                      I_loc_type       IN     ITEM_LOC.LOC_TYPE%TYPE,
                      I_date           IN     DATE,
                      I_all_orders     IN     VARCHAR2,
                      O_quantity       IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                      O_pack_quantity  IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                      O_error_message  IN OUT VARCHAR2)
RETURN BOOLEAN IS

   L_program     VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ON_ORDER';

   FUNCTION ORDER_QUANTITY ( I_item      IN     ITEM_LOC.ITEM%TYPE,
                             O_total_qty IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                             O_pack_qty IN OUT  ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)

                           RETURN BOOLEAN IS

      L_item_qty ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_qty ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_ON_ORDER_ITEM is
         select nvl(sum(l.qty_ordered - nvl(l.qty_received,0)),0)
           from ordhead h,
                ordloc l
          where l.item = I_item
            and l.location = nvl(I_loc, l.location)
            and l.loc_type = nvl(I_loc_type, l.loc_type)
            and l.order_no = h.order_no
            and h.status = 'A'
            and l.qty_ordered > nvl(l.qty_received,0)
            and (h.not_before_date < I_date  or (I_date is NULL))
            and NOT (I_all_orders = 'N' and h.include_on_order_ind = 'N');

      cursor C_ON_ORDER_PACK is
         select /*+ index(l) index(p) */ nvl(sum(p.pack_item_qty *
                       (l.qty_ordered - nvl(l.qty_received,0))),0)
           from ordhead h,
                ordloc l,
                packitem_breakout p
          where l.location = nvl(I_loc, l.location)
            and l.loc_type = nvl(I_loc_type, l.loc_type)
            and l.order_no = h.order_no
            and h.status = 'A'
            and l.qty_ordered > nvl(l.qty_received,0)
            and (h.not_before_date < I_date or (I_date is NULL))
            and NOT (I_all_orders = 'N' and h.include_on_order_ind = 'N')
            and l.item = pack_no
            and p.item = I_item;


   BEGIN
     SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM',
                      'ORDHEAD, ORDLOC', 'item:  '||I_item);
     open C_ON_ORDER_ITEM;
     SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM',
                      'ORDHEAD, ORDLOC', 'item:  '||I_item);
     fetch C_ON_ORDER_ITEM into L_item_qty;
     SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM',
                      'ORDHEAD, ORDLOC', 'item:  '||I_item);
     close C_ON_ORDER_ITEM;

     SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PACK',
                      'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
     open C_ON_ORDER_PACK;
     SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PACK',
                      'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
     fetch C_ON_ORDER_PACK into L_pack_qty;
     SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PACK',
                      'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
     close C_ON_ORDER_PACK;

     O_total_qty := L_item_qty + L_pack_qty;
     O_pack_qty  := L_pack_qty;

     return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
      return FALSE;
   END ORDER_QUANTITY;
   ---

   FUNCTION ITEM_PARENT_QTY (I_item_parent IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                             O_total_qty   IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
                          RETURN BOOLEAN IS

      L_item_qty            ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_qty            ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_ON_ORDER_ITEM is
         select /*+ index(l ordloc_i1) */ nvl(sum(l.qty_ordered - nvl(l.qty_received,0)),0)
           from ordhead h,
                ordloc l,
                item_master im
          where l.location = nvl(I_loc, l.location)
            and l.loc_type = nvl(I_loc_type, l.loc_type)
            and l.order_no = h.order_no
            and h.status = 'A'
            and l.qty_ordered > nvl(l.qty_received,0)
            and (h.not_before_date < I_date
                or
                 (I_date is NULL))
            and NOT (I_all_orders = 'N' and h.include_on_order_ind = 'N')
            and im.item = l.item
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_ON_ORDER_PI is
         select /*+ index(ol ordloc_i1)*/ nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                item_master im
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or
                 (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.location = nvl(I_loc, ol.location)
            and ol.loc_type = nvl(I_loc_type, ol.loc_type)
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

   BEGIN
      SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      open C_ON_ORDER_ITEM;
      SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      fetch C_ON_ORDER_ITEM into L_item_qty;
      SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      close C_ON_ORDER_ITEM;

      SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      open C_ON_ORDER_PI;
      SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      fetch C_ON_ORDER_PI into L_pack_qty;
      SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      close C_ON_ORDER_PI;

      O_total_qty := L_item_qty + L_pack_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END ITEM_PARENT_QTY;
   ---

   FUNCTION PACK_AND_ITEM_QTY ( I_item       IN     ITEM_LOC.ITEM%TYPE,
                                O_total_qty  IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
      RETURN BOOLEAN IS

      L_item_qty        ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_qty        ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_qty_dummy  ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_ON_ORDER_PI is
         select /*+ index(ol ordloc_i1) index(p) */ nvl(sum(p.pack_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem p
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or
                 (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.loc_type = nvl(I_loc_type, ol.loc_type)
            and ol.location = nvl(I_loc, ol.location)
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and p.item = I_item;

   BEGIN
      if not ORDER_QUANTITY ( I_item,
                              L_item_qty,
                              L_pack_qty_dummy ) then
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_ALL_LOC',
                       'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
      open C_ON_ORDER_PI;
      SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_ALL_LOC',
                       'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
      fetch C_ON_ORDER_PI into L_pack_qty;
      SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_ALL_LOC',
                       'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
      close C_ON_ORDER_PI;

      O_total_qty := L_item_qty + L_pack_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END PACK_AND_ITEM_QTY;
   ---

BEGIN

   if (LP_item != I_item or LP_item is NULL) then
      LP_item := I_item;

     SQL_LIB.SET_MARK('OPEN', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
     open C_ITEM_INFO;
     SQL_LIB.SET_MARK('FETCH', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
     fetch C_ITEM_INFO into LP_pack_ind,
                            LP_item_level,
                            LP_tran_level;
     SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
     close C_ITEM_INFO;

   end if;

   if LP_item_level < LP_tran_level then
      if not ITEM_PARENT_QTY (I_item,
                              O_quantity ) then
         return FALSE;
      end if;

   elsif LP_item_level = LP_tran_level then
      if LP_pack_ind = 'Y' then
         if not PACK_AND_ITEM_QTY ( I_item,
                                    O_quantity ) then
            return FALSE;
         end if;
      else  --LP_pack_ind = 'N'
         if not ORDER_QUANTITY ( I_item,
                                 O_quantity,
                                 O_pack_quantity ) then
            return FALSE;
         end if;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ON_ORDER;

--------------------------------------------------------------------------------------
FUNCTION GET_ALLOC_IN(I_item            IN       ITEM_LOC.ITEM%TYPE,
                      I_loc             IN       ITEM_LOC.LOC%TYPE,
                      I_loc_type        IN       ITEM_LOC.LOC_TYPE%TYPE,
                      I_date            IN       DATE,
                      I_all_orders      IN       VARCHAR2,
                      O_quantity        IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                      O_error_message   IN OUT   VARCHAR2)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ALLOC_IN';


   FUNCTION ALLOC_QUANTITY(I_item       IN       ITEM_LOC.ITEM%TYPE,
                           O_quantity      OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
      RETURN BOOLEAN IS

      L_alloc_item_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_alloc_pack_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ALLOC_IN_ITEM is
         select /*+ INDEX(h) */
                NVL(SUM(d.qty_allocated - NVL(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h
          where h.item = I_item
            and d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and (d.to_loc =I_loc or I_loc IS NULL)
            and (d.to_loc_type = I_loc_type or I_loc_type IS NULL)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date
                            and not (I_all_orders = 'N' and o.include_on_order_ind = 'N')) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                               and h1.status in ('A', 'R')
                               and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

      cursor C_GET_ALLOC_IN_PACK is
      select NVL(SUM(p.pack_item_qty *
                (d.qty_allocated - NVL(d.qty_transferred,0))),0)
        from alloc_detail d,
             alloc_header h,
             packitem_breakout p
       where p.pack_no = h.item
         and p.item = I_item
         and d.alloc_no = h.alloc_no
         and h.status in ('A', 'R')
         and d.qty_allocated > NVL(d.qty_transferred,0)
         and (d.to_loc = I_loc or I_loc IS NULL)
         and (d.to_loc_type = I_loc_type or I_loc_type IS NULL)
         and (exists (select 'x'
                        from ordhead o
                       where o.order_no = h.order_no
                         and o.status in ('A', 'C')
                         and NVL(I_date, o.not_before_date) >= o.not_before_date
                         and not (I_all_orders = 'N' and o.include_on_order_ind = 'N')) or
              exists (select 'x'
                        from alloc_header h1
                       where h1.alloc_no = h.order_no
                         and h1.status in ('A', 'R')
                         and NVL(I_date, h1.release_date) = h1.release_date) or
              exists (select 'x'
                        from tsfhead t
                       where t.tsf_no = h.order_no
                         and t.status in ('A','S','P','L','C')
                         and t.not_after_date is null
                      union
                      select 'x'
                        from tsfhead t
                       where t.tsf_no = h.order_no
                         and t.status in ('A','S','P','L','C')
                         and t.not_after_date is not null
                         and NVL(I_date, t.not_after_date) <= t.not_after_date));

   BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ALLOC_IN_ITEM',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                       'item:  '||I_item);
      open C_GET_ALLOC_IN_ITEM;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ALLOC_IN_ITEM',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                       'item:  '||I_item);
      fetch C_GET_ALLOC_IN_ITEM into L_alloc_item_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ALLOC_IN_ITEM',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                       'item:  '||I_item);
      close C_GET_ALLOC_IN_ITEM;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      open C_GET_ALLOC_IN_PACK;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      fetch C_GET_ALLOC_IN_PACK into L_alloc_pack_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      close C_GET_ALLOC_IN_PACK;

      O_quantity := L_alloc_item_qty + L_alloc_pack_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
      return FALSE;
   END ALLOC_QUANTITY;
   ---

   FUNCTION ITEM_PARENT_QTY(I_item_parent   IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                            O_total_qty     IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
      RETURN BOOLEAN IS

      L_item_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ALLOC_IN_ITEM is
         select NVL(sum(d.qty_allocated - NVL(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h,
                item_master im
          where d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and im.item = h.item
            and (d.to_loc = I_loc or I_loc is null)
            and (d.to_loc_type = I_loc_type or I_loc_type is null)
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date
                            and not (I_all_orders = 'N' and o.include_on_order_ind = 'N')) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

      cursor C_GET_ALLOC_IN_PACK is
         select NVL(sum(p.pack_item_qty * (d.qty_allocated - NVL(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                packitem_breakout p,
                item_master im
          where (d.to_loc = I_loc or I_loc is null)
            and (d.to_loc_type = I_loc_type or I_loc_type is null)
            and d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and h.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item
            And (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date
                            and not (I_all_orders = 'N' and o.include_on_order_ind = 'N')) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

   BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ALLOC_IN_ITEM',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      open C_GET_ALLOC_IN_ITEM;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ALLOC_IN_ITEM',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      fetch C_GET_ALLOC_IN_ITEM into L_item_alloc_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ALLOC_IN_ITEM',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      close C_GET_ALLOC_IN_ITEM;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      open C_GET_ALLOC_IN_PACK;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      fetch C_GET_ALLOC_IN_PACK into L_pack_alloc_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      close C_GET_ALLOC_IN_PACK;

      O_total_qty := L_item_alloc_qty + L_pack_alloc_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                TO_CHAR(SQLCODE));
         return FALSE;
   END ITEM_PARENT_QTY;
   ---
   FUNCTION PACK_AND_ITEM_QTY(I_item        IN       ITEM_LOC.ITEM%TYPE,
                              O_total_qty   IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
      RETURN BOOLEAN IS

      L_item_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_PACK_ALLOC_IN is
         select NVL(sum(p.pack_qty *
                (d.qty_allocated - NVL(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                packitem p
          where (d.to_loc = I_loc or I_loc is null)
            and (d.to_loc_type = I_loc_type or I_loc_type is null)
            and d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and h.item = p.pack_no
            and p.item = I_item
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date
                            and not (I_all_orders = 'N' and o.include_on_order_ind = 'N')) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

   BEGIN
      if not ALLOC_QUANTITY(I_item,
                            L_item_alloc_qty) then
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_ALLOC_IN',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM',
                       'item:  '||I_item);
      open C_GET_PACK_ALLOC_IN;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PACK_ALLOC_IN',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM',
                       'item:  '||I_item);
      fetch C_GET_PACK_ALLOC_IN into L_pack_alloc_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK_ALLOC_IN',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM',
                       'item:  '||I_item);
      close C_GET_PACK_ALLOC_IN;

      O_total_qty := L_item_alloc_qty + L_pack_alloc_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END PACK_AND_ITEM_QTY;
   ---

BEGIN

   if (LP_item != I_item or LP_item is NULL) then
      LP_item := I_item;

      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      open C_ITEM_INFO;

      SQL_LIB.SET_MARK('FETCH',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      fetch C_ITEM_INFO into LP_pack_ind,
                            LP_item_level,
                            LP_tran_level;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      close C_ITEM_INFO;

   end if;

   if LP_item_level < LP_tran_level then
      if not ITEM_PARENT_QTY(I_item,
                             O_quantity) then
         return FALSE;
      end if;

   elsif LP_item_level = LP_tran_level then
      if LP_pack_ind = 'Y' then
         if not PACK_AND_ITEM_QTY(I_item,
                                  O_quantity) then
            return FALSE;
         end if;
      else  --LP_pack_ind = 'N'
         if not ALLOC_QUANTITY(I_item,
                               O_quantity) then
            return FALSE;
         end if;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_ALLOC_IN;

--------------------------------------------------------------------------------------
/* New function created for replenishement */
FUNCTION GET_ALLOC_IN(I_item            IN       ITEM_LOC.ITEM%TYPE,
                      I_loc             IN       ITEM_LOC.LOC%TYPE,
                      I_loc_type        IN       ITEM_LOC.LOC_TYPE%TYPE,
                      I_date            IN       DATE,
                      I_all_orders      IN       VARCHAR2,
                      I_repl_ind        IN       VARCHAR2,
                      O_quantity        IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                      O_error_message   IN OUT   VARCHAR2)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ALLOC_IN';


   FUNCTION ALLOC_QUANTITY(I_item       IN       ITEM_LOC.ITEM%TYPE,
                           O_quantity      OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
      RETURN BOOLEAN IS

      L_alloc_item_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_alloc_pack_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ALLOC_IN_ITEM_2 is
         select NVL(sum(alloc_in_qty),0)
           from rpl_alloc_in_tmp
          where item = I_item
            and (to_loc = I_loc or I_loc is null)
            and (to_loc_type = I_loc_type or I_loc_type is null)
            and NVL(I_date, not_before_date) >= not_before_date ;

      cursor C_GET_ALLOC_IN_PACK is
          select NVL(sum(p.pack_item_qty *
                    (d.qty_allocated - NVL(d.qty_transferred,0))),0)
            from alloc_detail d,
                 alloc_header h,
                 packitem_breakout p
           where p.pack_no = h.item
             and p.item = I_item
             and d.alloc_no = h.alloc_no
             and h.status in ('A', 'R')
             and d.qty_allocated > NVL(d.qty_transferred,0)
             and (d.to_loc = I_loc or I_loc is null)
             and (d.to_loc_type = I_loc_type or I_loc_type is null)
             and (exists (select 'x'
                            from ordhead o
                           where o.order_no = h.order_no
                             and o.status in ('A', 'C')
                             and NVL(I_date, o.not_before_date) >= o.not_before_date
                             and not (I_all_orders = 'N' and o.include_on_order_ind = 'N')) or
                  exists (select 'x'
                            from alloc_header h1
                           where h1.alloc_no = h.order_no
                             and h1.status in ('A', 'R')
                             and NVL(I_date, h1.release_date) = h1.release_date) or
                  exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

   BEGIN
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ALLOC_IN_ITEM_2',
                       'REPL_ALLOC_IN_TMP',
                       'item:  '||I_item);
      open C_GET_ALLOC_IN_ITEM_2;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ALLOC_IN_ITEM_2',
                       'REPL_ALLOC_IN_TMP',
                       'item:  '||I_item);
      fetch C_GET_ALLOC_IN_ITEM_2 into L_alloc_item_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ALLOC_IN_ITEM_2',
                       'REPL_ALLOC_IN_TMP',
                       'item:  '||I_item);
      close C_GET_ALLOC_IN_ITEM_2;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      open C_GET_ALLOC_IN_PACK;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      fetch C_GET_ALLOC_IN_PACK into L_alloc_pack_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      close C_GET_ALLOC_IN_PACK;

      O_quantity := L_alloc_item_qty + L_alloc_pack_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
      return FALSE;
   END ALLOC_QUANTITY;
   ---

   FUNCTION ITEM_PARENT_QTY(I_item_parent   IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                             O_total_qty    IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
      RETURN BOOLEAN IS

      L_item_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ALLOC_IN_ITEM is
         select NVL(sum(d.qty_allocated - NVL(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h,
                item_master im
          where d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and im.item = h.item
            and (d.to_loc = I_loc or I_loc is null)
            and (d.to_loc_type = I_loc_type or I_loc_type is null)
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date
                            and not (I_all_orders = 'N' and o.include_on_order_ind = 'N')) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

      cursor C_GET_ALLOC_IN_PACK is
         select NVL(sum(p.pack_item_qty * (d.qty_allocated - NVL(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                packitem_breakout p,
                item_master im
          where (d.to_loc = I_loc or I_loc is null)
            and (d.to_loc_type = I_loc_type or I_loc_type is null)
            and d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and h.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date
                            and not (I_all_orders = 'N' and o.include_on_order_ind = 'N')) or
              exists (select 'x'
                        from alloc_header h1
                       where h1.alloc_no = h.order_no
                         and h1.status in ('A', 'R')
                         and NVL(I_date, h1.release_date) = h1.release_date) or
              exists (select 'x'
                        from tsfhead t
                       where t.tsf_no = h.order_no
                         and t.status in ('A','S','P','L','C')
                         and t.not_after_date is null
                      union
                      select 'x'
                        from tsfhead t
                       where t.tsf_no = h.order_no
                         and t.status in ('A','S','P','L','C')
                         and t.not_after_date is not null
                         and NVL(I_date, t.not_after_date) <= t.not_after_date));

   BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ALLOC_IN_ITEM',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      open C_GET_ALLOC_IN_ITEM;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ALLOC_IN_ITEM',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      fetch C_GET_ALLOC_IN_ITEM into L_item_alloc_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ALLOC_IN_ITEM',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      close C_GET_ALLOC_IN_ITEM;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      open C_GET_ALLOC_IN_PACK;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      fetch C_GET_ALLOC_IN_PACK into L_pack_alloc_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ALLOC_IN_PACK',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
      close C_GET_ALLOC_IN_PACK;

      O_total_qty := L_item_alloc_qty + L_pack_alloc_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                TO_CHAR(SQLCODE));
         return FALSE;
   END ITEM_PARENT_QTY;
   ---

   FUNCTION PACK_AND_ITEM_QTY(I_item        IN       ITEM_LOC.ITEM%TYPE,
                              O_total_qty   IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
      RETURN BOOLEAN IS

      L_item_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_PACK_ALLOC_IN is
         select NVL(sum(p.pack_qty *
                   (d.qty_allocated - NVL(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                packitem p
          where (d.to_loc = I_loc or I_loc is null)
            and (d.to_loc_type = I_loc_type or I_loc_type is null)
            and d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and h.item = p.pack_no
            and p.item = I_item
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date
                            and not (I_all_orders = 'N' and o.include_on_order_ind = 'N')) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

   BEGIN
      if not ALLOC_QUANTITY(I_item,
                            L_item_alloc_qty) then
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_ALLOC_IN',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM',
                       'item:  '||I_item);
      open C_GET_PACK_ALLOC_IN;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PACK_ALLOC_IN',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM',
                       'item:  '||I_item);
      fetch C_GET_PACK_ALLOC_IN into L_pack_alloc_qty;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK_ALLOC_IN',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM',
                       'item:  '||I_item);
      close C_GET_PACK_ALLOC_IN;

      O_total_qty := L_item_alloc_qty + L_pack_alloc_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END PACK_AND_ITEM_QTY;
   ---

BEGIN

   if (LP_item != I_item or LP_item is NULL) then
      LP_item := I_item;

      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      open C_ITEM_INFO;

      SQL_LIB.SET_MARK('FETCH',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      fetch C_ITEM_INFO into LP_pack_ind,
                             LP_item_level,
                             LP_tran_level;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      close C_ITEM_INFO;

   end if;

   if LP_item_level < LP_tran_level then
      if not ITEM_PARENT_QTY(I_item,
                             O_quantity) then
         return FALSE;
      end if;

   elsif LP_item_level = LP_tran_level then
      if LP_pack_ind = 'Y' then
         if not PACK_AND_ITEM_QTY(I_item,
                                  O_quantity) then
            return FALSE;
         end if;
      else  --LP_pack_ind = 'N'
         if not ALLOC_QUANTITY(I_item,
                               O_quantity) then
            return FALSE;
         end if;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_ALLOC_IN;

--------------------------------------------------------------------------------------
FUNCTION GET_ALLOC_OUT(I_item            IN       ITEM_LOC.ITEM%TYPE,
                       I_loc             IN       ITEM_LOC.LOC%TYPE,
                       I_date            IN       DATE,
                       O_quantity        IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                       O_error_message   IN OUT   VARCHAR2)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ALLOC_OUT';

   FUNCTION ALLOC_QUANTITY(I_item       IN       ITEM_LOC.ITEM%TYPE,
                           O_quantity   IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )

      RETURN BOOLEAN IS

      L_item_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ITEM_ALLOC_OUT is
         select NVL(sum(d.qty_allocated - NVL(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h
          where h.item = I_item
            and d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and h.wh = NVL(I_loc, h.wh)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

      cursor C_GET_PACK_ALLOC_OUT is
         select NVL(sum(p.pack_item_qty *
                       (d.qty_allocated - NVL(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                packitem_breakout p
          where h.item = p.pack_no
            and d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and p.item = I_item
            and h.wh = NVL(I_loc, h.wh)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

   BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                       'item:  '||I_item);
      open C_GET_ITEM_ALLOC_OUT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                       'item:  '||I_item);
      fetch C_GET_ITEM_ALLOC_OUT into L_item_alloc_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                       'item:  '||I_item);
      close C_GET_ITEM_ALLOC_OUT;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      open C_GET_PACK_ALLOC_OUT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PACK_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      fetch C_GET_PACK_ALLOC_OUT into L_pack_alloc_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      close C_GET_PACK_ALLOC_OUT;

      O_quantity := L_item_alloc_qty + L_pack_alloc_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
      return FALSE;

   END ALLOC_QUANTITY;
   ---

   FUNCTION ITEM_PARENT_QTY(I_item_parent   IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                            O_total_qty     IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
      RETURN BOOLEAN IS

      L_item_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_alloc_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ITEM_ALLOC_OUT is
         select NVL(sum(d.qty_allocated - NVL(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h,
                item_master im
          where d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and im.item = h.item
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and h.wh = NVL(I_loc, h.wh)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

      cursor C_GET_PACK_ALLOC_OUT is
         select NVL(sum(p.pack_item_qty * (d.qty_allocated - NVL(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                packitem_breakout p,
                item_master im
          where d.alloc_no = h.alloc_no
            and h.status in ('A', 'R')
            and d.qty_allocated > NVL(d.qty_transferred,0)
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and p.item = im.item
            and h.item = p.pack_no
            and h.wh = NVL(I_loc, h.wh)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date) or
                 exists (select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is null
                         union
                         select 'x'
                           from tsfhead t
                          where t.tsf_no = h.order_no
                            and t.status in ('A','S','P','L','C')
                            and t.not_after_date is not null
                            and NVL(I_date, t.not_after_date) <= t.not_after_date));

   BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      open C_GET_ITEM_ALLOC_OUT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      fetch C_GET_ITEM_ALLOC_OUT into L_item_alloc_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      close C_GET_ITEM_ALLOC_OUT;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      open C_GET_PACK_ALLOC_OUT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PACK_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      fetch C_GET_PACK_ALLOC_OUT into L_pack_alloc_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK_ALLOC_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      close C_GET_PACK_ALLOC_OUT;

      O_total_qty := L_item_alloc_qty + L_pack_alloc_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));

      return FALSE;
   END ITEM_PARENT_QTY;
   ---

BEGIN
   if (LP_item != I_item or LP_item is NULL) then
      LP_item := I_item;

      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      open C_ITEM_INFO;

      SQL_LIB.SET_MARK('FETCH',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      fetch C_ITEM_INFO into LP_pack_ind,
                             LP_item_level,
                             LP_tran_level;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      close C_ITEM_INFO;

   end if;

   if LP_item_level < LP_tran_level then
      if not ITEM_PARENT_QTY ( I_item,
                               O_quantity ) then
         return FALSE;
      end if;

   elsif LP_item_level = LP_tran_level then
      if not ALLOC_QUANTITY ( I_item,
                              O_quantity ) then
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_ALLOC_OUT;

--------------------------------------------------------------------------------------
FUNCTION GET_PL_TRANSFER(O_error_message IN OUT VARCHAR2,
                         O_item_qty      IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                         O_pack_qty      IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                         I_item          IN     ITEM_LOC.ITEM%TYPE,
                         I_loc           IN     ITEM_LOC.LOC%TYPE,
                         I_loc_type      IN     ITEM_LOC.LOC_TYPE%TYPE,
                         I_date          IN     DATE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_PL_TRANSFER';

   ----
   FUNCTION PL_TSF_QUANTITY ( I_item      IN     ITEM_LOC.ITEM%TYPE,
                              O_item_qty  IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                              O_pack_qty  IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)

                            RETURN BOOLEAN IS

      cursor C_PL_TSF_QTY is
         select nvl(sum(d.tsf_qty - nvl(d.ship_qty,0)),0)
           from tsfhead h,
                tsfdetail d
          where d.item = I_item
            and h.to_loc = nvl(I_loc, h.to_loc)
            and h.to_loc_type = nvl(I_loc_type, h.to_loc_type)
            and h.tsf_no = d.tsf_no
            and h.status in ('A','E','S','B')
            and h.tsf_type = 'PL'
            and d.tsf_qty > nvl(d.ship_qty,0)
            and h.delivery_date <= nvl(I_date, h.delivery_date);

      cursor C_PL_TSF_PACK_QTY is
         select nvl(sum(p.pack_item_qty *
                       (d.tsf_qty - nvl(d.ship_qty, 0))),0)
           from tsfhead h,
                tsfdetail d,
                packitem_breakout p
          where h.to_loc = nvl(I_loc, h.to_loc)
            and h.to_loc_type = nvl(I_loc_type, h.to_loc_type)
            and h.tsf_no = d.tsf_no
            and h.status in ('A','E','S','B')
            and h.tsf_type = 'PL'
            and d.tsf_qty > nvl(d.ship_qty,0)
            and h.delivery_date <= nvl(I_date, h.delivery_date)
            and d.item = p.pack_no
            and p.item = I_item;

   BEGIN
     SQL_LIB.SET_MARK('OPEN','C_PL_TSF_QTY','TSFHEAD, TSFDETAIL','item:  '||I_item);
     open C_PL_TSF_QTY;
     SQL_LIB.SET_MARK('FETCH','C_PL_TSF_QTY','TSFHEAD, TSFDETAIL','item:  '||I_item);
     fetch C_PL_TSF_QTY into O_item_qty;
     SQL_LIB.SET_MARK('CLOSE','C_PL_TSF_QTY','TSFHEAD, TSFDETAIL','item:  '||I_item);
     close C_PL_TSF_QTY;

     SQL_LIB.SET_MARK('OPEN','C_PL_TSF_PACK_QTY',
                             'TSFHEAD, TSFDETAIL, PACKITEM_BREAKOUT',
                             'item:  '||I_item);
     open C_PL_TSF_PACK_QTY;
     SQL_LIB.SET_MARK('FETCH','C_PL_TSF_PACK_QTY',
                              'TSFHEAD, TSFDETAIL, PACKITEM_BREAKOUT',
                              'item:  '||I_item);
     fetch C_PL_TSF_PACK_QTY into O_pack_qty;
     SQL_LIB.SET_MARK('CLOSE','C_PL_TSF_PACK_QTY',
                              'TSFHEAD, TSFDETAIL, PACKITEM_BREAKOUT',
                              'item:  '||I_item);
     close C_PL_TSF_PACK_QTY;

     return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
      return FALSE;
   END PL_TSF_QUANTITY;
   ----

   FUNCTION PL_TSF_PARENT_QTY (I_item_parent IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                               O_item_qty    IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                               O_pack_qty    IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)

                            RETURN BOOLEAN IS

      cursor C_PL_TSF_PARENT_QTY is
         select nvl(sum(d.tsf_qty - nvl(d.ship_qty,0)),0)
           from tsfhead h,
                tsfdetail d,
                item_master im
          where h.to_loc = nvl(I_loc, h.to_loc)
            and h.to_loc_type = nvl(I_loc_type, h.to_loc_type)
            and d.tsf_no = h.tsf_no
            and h.status in ('A','E','S','B')
            and h.tsf_type = 'PL'
            and d.tsf_qty > nvl(d.ship_qty,0)
            and h.delivery_date <= nvl(I_date, h.delivery_date)
            and im.item = d.item
            and (im.item_parent = I_item_parent
                 or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_PL_TSF_PARENT_PACK_QTY is
         select nvl(sum(p.pack_item_qty *
                       (d.tsf_qty - nvl(d.ship_qty,0))),0)
           from tsfhead h,
                tsfdetail d,
                packitem_breakout p,
                item_master im
          where h.status in ('A','E','S','B')
            and h.tsf_type = 'PL'
            and h.delivery_date <= nvl(I_date, h.delivery_date)
            and h.tsf_no = d.tsf_no
            and h.to_loc = nvl(I_loc, h.to_loc)
            and h.to_loc_type = nvl(I_loc_type, h.to_loc_type)
            and d.tsf_qty > nvl(d.ship_qty,0)
            and d.item = p.pack_no
            and (im.item_parent = I_item_parent
                 or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

   BEGIN
      SQL_LIB.SET_MARK('OPEN', 'C_PL_TSF_PARENT_QTY','TSFHEAD, TSFDETAIL, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||
                       'item grandparent:  '||I_item_parent);
      open C_PL_TSF_PARENT_QTY;
      SQL_LIB.SET_MARK('FETCH', 'C_PL_TSF_PARENT_QTY','TSFHEAD, TSFDETAIL, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||
                       'item grandparent:  '||I_item_parent);
      fetch C_PL_TSF_PARENT_QTY into O_item_qty;
      SQL_LIB.SET_MARK('CLOSE', 'C_PL_TSF_PARENT_QTY', 'TSFHEAD, TSFDETAIL, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||
                       'item grandparent:  '||I_item_parent);
      close C_PL_TSF_PARENT_QTY;

      if (LP_pack_ind = 'N') then  -- packs will not exist as an item on packitem_breakout
         SQL_LIB.SET_MARK('OPEN', 'C_PL_TSF_PARENT_PACK_QTY',
                          'TSFHEAD, TSFDETAIL, PACKITEM_BREAKOUT, ITEM_MASTER',
                          'item parent:  '||I_item_parent||' or '||
                          'item grandparent:  '||I_item_parent);
         open C_PL_TSF_PARENT_PACK_QTY;
         SQL_LIB.SET_MARK('FETCH', 'C_PL_TSF_PARENT_PACK_QTY',
                          'TSFHEAD, TSFDETAIL, PACKITEM_BREAKOUT, ITEM_MASTER',
                          'item parent:  '||I_item_parent||' or '||
                          'item grandparent:  '||I_item_parent);
         fetch C_PL_TSF_PARENT_PACK_QTY into O_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_PL_TSF_PARENT_PACK_QTY',
                          'TSFHEAD, TSFDETAIL, PACKITEM_BREAKOUT, ITEM_MASTER',
                          'item parent:  '||I_item_parent||' or '||
                          'item grandparent:  '||I_item_parent);
         close C_PL_TSF_PARENT_PACK_QTY;
      end if;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END PL_TSF_PARENT_QTY;
   ----

   FUNCTION PL_TSF_PACK_ITEM_QTY ( I_item       IN     ITEM_LOC.ITEM%TYPE,
                                   O_item_qty   IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                                   O_pack_qty   IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
         RETURN BOOLEAN IS

      L_dummy_qty     ITEM_LOC_SOH.STOCK_ON_HAND%TYPE;
        -- dummy variable to fetch pack qty from PL_TSF_QUANTITY.
        -- Pack qty will always be zero, since it is looking for a
        -- pack as a component on packitem_breakout.

      cursor C_PL_TSF_PACKITEM_QTY is
         select nvl(sum(p.pack_qty *
                       (d.tsf_qty - nvl(d.ship_qty,0))),0)
           from tsfhead h,
                tsfdetail d,
                packitem p
          where h.status in ('A','E','S','B')
            and h.tsf_type = 'PL'
            and h.delivery_date <= nvl(I_date, h.delivery_date)
            and h.tsf_no = d.tsf_no
            and h.to_loc_type = nvl(I_loc_type, h.to_loc_type)
            and h.to_loc = nvl(I_loc, h.to_loc)
            and d.tsf_qty > nvl(d.ship_qty,0)
            and d.item = p.pack_no
            and p.item = I_item;

   BEGIN
      if not PL_TSF_QUANTITY ( I_item,
                               O_item_qty,
                               L_dummy_qty ) then
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('OPEN', 'C_PL_TSF_PACKITEM_QTY',
                       'TSFHEAD, TSFDETAIL, PACKITEM','item:  '||I_item);
      open C_PL_TSF_PACKITEM_QTY;
      SQL_LIB.SET_MARK('FETCH', 'C_PL_TSF_PACKITEM_QTY',
                       'TSFHEAD, TSFDETAIL, PACKITEM','item:  '||I_item);
      fetch C_PL_TSF_PACKITEM_QTY into O_pack_qty;
      SQL_LIB.SET_MARK('CLOSE', 'C_PL_TSF_PACKITEM_QTY',
                       'TSFHEAD, TSFDETAIL, PACKITEM','item:  '||I_item);
      close C_PL_TSF_PACKITEM_QTY;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END PL_TSF_PACK_ITEM_QTY;
   ----

BEGIN
   if (LP_item != I_item or LP_item is NULL) then
      LP_item := I_item;

     SQL_LIB.SET_MARK('OPEN', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
     open C_ITEM_INFO;
     SQL_LIB.SET_MARK('FETCH', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
     fetch C_ITEM_INFO into LP_pack_ind,
                            LP_item_level,
                            LP_tran_level;
     SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
     close C_ITEM_INFO;

   end if;

   if LP_item_level < LP_tran_level then
      if not PL_TSF_PARENT_QTY (I_item,
                                O_item_qty,
                                O_pack_qty ) then
         return FALSE;
      end if;

   elsif LP_item_level = LP_tran_level then
      if LP_pack_ind = 'Y' then
         if not PL_TSF_PACK_ITEM_QTY ( I_item,
                                       O_item_qty,
                                       O_pack_qty ) then
            return FALSE;
         end if;
      else  --LP_pack_ind = 'N'
         if not PL_TSF_QUANTITY ( I_item,
                                  O_item_qty,
                                  O_pack_qty ) then
            return FALSE;
         end if;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_PL_TRANSFER;

--------------------------------------------------------------------------------------
/* New function is created for reqext */

FUNCTION GET_TOTAL_DIST_QTY (O_error_message    IN OUT   VARCHAR2,
                             O_total_dist_qty   IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                             I_item             IN       ITEM_LOC_SOH.ITEM%TYPE,
                             I_loc              IN       ITEM_LOC.LOC%TYPE,
                             I_loc_type         IN       ITEM_LOC.LOC_TYPE%TYPE,
                             I_date             IN       DATE,
                             I_repl_ind         IN       VARCHAR2)
   RETURN BOOLEAN is

   L_program   VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_TOTAL_DIST_QTY';


   FUNCTION ALLOC_QUANTITY(I_item       IN       ITEM_LOC.ITEM%TYPE,
                           O_quantity   IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
      RETURN BOOLEAN IS

      L_item_dist_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_dist_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_PACK_DIST_QTY is
       select /*+ INDEX(h) */
              nvl(sum(p.pack_item_qty * d.qty_distro),0)
           from alloc_detail d,
                alloc_header h,
                packitem_breakout p
          where h.item = p.pack_no
            and d.alloc_no = h.alloc_no
            and p.item = I_item
            and (h.wh = I_loc or I_loc IS NULL)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and o.status in ('A', 'C')
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and h1.status in ('A', 'R')
                            and NVL(I_date, h1.release_date) = h1.release_date));

      cursor C_GET_ITEM_DIST_QTY_2 is
         select qty_distro
           from rpl_distro_tmp
          where item = I_item
            and (wh = I_loc or (I_loc IS NULL));

   BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_DIST_QTY_2',
                       'RPL_DISTRO_TMP',
                       'item:  '||I_item);
      open C_GET_ITEM_DIST_QTY_2;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_DIST_QTY_2',
                       'RPL_DISTRO_TMP',
                       'item:  '||I_item);
      fetch C_GET_ITEM_DIST_QTY_2 into L_item_dist_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_DIST_QTY_2',
                       'RPL_DISTRO_TMP',
                       'item:  '||I_item);
      close C_GET_ITEM_DIST_QTY_2;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_DIST_QTY',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      open C_GET_PACK_DIST_QTY;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PACK_DIST_QTY',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      fetch C_GET_PACK_DIST_QTY into L_pack_dist_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK_DIST_QTY',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      close C_GET_PACK_DIST_QTY;

      O_quantity := L_item_dist_qty + L_pack_dist_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
      return FALSE;

   END ALLOC_QUANTITY;
   ---

   FUNCTION ITEM_PARENT_QTY(I_item_parent   IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                            O_total_qty     IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
      RETURN BOOLEAN IS

      L_item_dist_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_dist_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ITEM_ALLOC_DIST_OUT is
         select nvl(sum(d.qty_distro),0)
           from alloc_detail d,
                alloc_header h,
                item_master im
          where d.alloc_no = h.alloc_no
            and im.item = h.item
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and  im.item_level = im.tran_level
            and (h.wh = I_loc or I_loc is NULL)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and NVL(I_date, h1.release_date) = h1.release_date));

      cursor C_GET_PACK_ALLOC_DIST_OUT is
         select nvl(sum(d.qty_distro),0)
           from alloc_detail d,
                alloc_header h,
                packitem_breakout p,
                item_master im
          where d.alloc_no = h.alloc_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and p.item = im.item
            and h.item = p.pack_no
            and (h.wh = I_loc or I_loc is null)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and NVL(I_date, h1.release_date) = h1.release_date));

   BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      open C_GET_ITEM_ALLOC_DIST_OUT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      fetch C_GET_ITEM_ALLOC_DIST_OUT into L_item_dist_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      close C_GET_ITEM_ALLOC_DIST_OUT;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      open C_GET_PACK_ALLOC_DIST_OUT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PACK_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      fetch C_GET_PACK_ALLOC_DIST_OUT into L_pack_dist_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      close C_GET_PACK_ALLOC_DIST_OUT;

      O_total_qty := L_item_dist_qty + L_pack_dist_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));

      return FALSE;
   END ITEM_PARENT_QTY;
   ---

BEGIN
   if (LP_item != I_item or LP_item is NULL) then
      LP_item := I_item;

      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      open C_ITEM_INFO;

      SQL_LIB.SET_MARK('FETCH',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      fetch C_ITEM_INFO into LP_pack_ind,
                             LP_item_level,
                             LP_tran_level;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      close C_ITEM_INFO;

   end if;

   if LP_item_level < LP_tran_level then
      if not ITEM_PARENT_QTY(I_item,
                             O_total_dist_qty) then
         return FALSE;
      end if;

   elsif LP_item_level = LP_tran_level then
      if not ALLOC_QUANTITY(I_item,
                            O_total_dist_qty) then
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_TOTAL_DIST_QTY;

--------------------------------------------------------------------------------------
FUNCTION GET_TOTAL_DIST_QTY (O_error_message    IN OUT   VARCHAR2,
                             O_total_dist_qty   IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                             I_item             IN       ITEM_LOC_SOH.ITEM%TYPE,
                             I_loc              IN       ITEM_LOC.LOC%TYPE,
                             I_loc_type         IN       ITEM_LOC.LOC_TYPE%TYPE,
                             I_date             IN       DATE)
   RETURN BOOLEAN is

   L_program     VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_TOTAL_DIST_QTY';


   FUNCTION ALLOC_QUANTITY(I_item       IN       ITEM_LOC.ITEM%TYPE,
                           O_quantity   IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )

      RETURN BOOLEAN IS

      L_item_dist_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_dist_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ITEM_DIST_QTY is
         select nvl(sum(d.qty_distro),0)
           from alloc_detail d,
                alloc_header h
          where h.item = I_item
            and h.wh is null
            and d.alloc_no = h.alloc_no
            and (exists (select 'x'
                          from ordhead o
                         where o.order_no = h.order_no) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no));

      cursor C_GET_ITEM_DIST_QTY2 is
         select nvl(sum(d.qty_distro),0)
           from alloc_detail d,
                alloc_header h
          where h.item = I_item
            and h.wh = I_loc
            and d.alloc_no = h.alloc_no
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and I_date >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and I_date = h1.release_date));

      cursor C_GET_ITEM_DIST_QTY3 is
         select nvl(sum(d.qty_distro),0)
           from alloc_detail d,
                alloc_header h
          where h.item = I_item
            and h.wh = I_loc
            and d.alloc_no = h.alloc_no
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no));

      cursor C_GET_ITEM_DIST_QTY4 is
         select nvl(sum(d.qty_distro),0)
           from alloc_detail d,
                alloc_header h
          where h.item = I_item
            and h.wh is null
            and d.alloc_no = h.alloc_no
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and I_date >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and I_date = h1.release_date));

      cursor C_GET_PACK_DIST_QTY is
         select /*+ INDEX(h) */
                nvl(sum(p.pack_item_qty * d.qty_distro),0)
           from alloc_detail d,
                alloc_header h,
                packitem_breakout p
          where h.item = p.pack_no
            and d.alloc_no = h.alloc_no
            and p.item = I_item
            and h.wh = nvl(I_loc, h.wh)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and NVL(I_date, h1.release_date) = h1.release_date));

   BEGIN
      if I_loc is NULL and I_date is NULL then
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_ITEM_DIST_QTY',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         open C_GET_ITEM_DIST_QTY;

         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_ITEM_DIST_QTY',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         fetch C_GET_ITEM_DIST_QTY into L_item_dist_qty;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_DIST_QTY',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         close C_GET_ITEM_DIST_QTY;
      elsif I_loc is NOT NULL and I_date is NULL then
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_ITEM_DIST_QTY3',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         open C_GET_ITEM_DIST_QTY3;

         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_ITEM_DIST_QTY3',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         fetch C_GET_ITEM_DIST_QTY3 into L_item_dist_qty;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_DIST_QTY3',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         close C_GET_ITEM_DIST_QTY3;
      elsif I_loc is NULL and I_date is NOT NULL then
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_ITEM_DIST_QTY4',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         open C_GET_ITEM_DIST_QTY4;

         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_ITEM_DIST_QTY4',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         fetch C_GET_ITEM_DIST_QTY4 into L_item_dist_qty;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_DIST_QTY4',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         close C_GET_ITEM_DIST_QTY4;
      elsif I_loc is NOT NULL and I_date is NOT NULL then
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_ITEM_DIST_QTY2',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         open C_GET_ITEM_DIST_QTY2;

         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_ITEM_DIST_QTY2',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         fetch C_GET_ITEM_DIST_QTY2 into L_item_dist_qty;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_DIST_QTY2',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD',
                          'item:  '||I_item);
         close C_GET_ITEM_DIST_QTY2;
      end if;
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_DIST_QTY',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      open C_GET_PACK_DIST_QTY;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PACK_DIST_QTY',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      fetch C_GET_PACK_DIST_QTY into L_pack_dist_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK_DIST_QTY',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                       'item:  '||I_item);
      close C_GET_PACK_DIST_QTY;

      O_quantity := L_item_dist_qty + L_pack_dist_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
      return FALSE;

   END ALLOC_QUANTITY;
   ---

   FUNCTION ITEM_PARENT_QTY(I_item_parent   IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                            O_total_qty     IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
      RETURN BOOLEAN IS

      L_item_dist_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_dist_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ITEM_ALLOC_DIST_OUT is
         select nvl(sum(d.qty_distro),0)
           from alloc_detail d,
                alloc_header h,
                item_master im
          where d.alloc_no = h.alloc_no
            and im.item = h.item
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and  im.item_level = im.tran_level
            and (h.wh = I_loc or I_loc is null)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and NVL(I_date, h1.release_date) = h1.release_date));

      cursor C_GET_PACK_ALLOC_DIST_OUT is
         select nvl(sum(d.qty_distro),0)
           from alloc_detail d,
                alloc_header h,
                packitem_breakout p,
                item_master im
          where d.alloc_no = h.alloc_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and  im.item_level = im.tran_level
            and p.item = im.item
            and h.item = p.pack_no
            and (h.wh = I_loc or I_loc is null)
            and (exists (select 'x'
                           from ordhead o
                          where o.order_no = h.order_no
                            and NVL(I_date, o.not_before_date) >= o.not_before_date) or
                 exists (select 'x'
                           from alloc_header h1
                          where h1.alloc_no = h.order_no
                            and NVL(I_date, h1.release_date) = h1.release_date));

   BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      open C_GET_ITEM_ALLOC_DIST_OUT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      fetch C_GET_ITEM_ALLOC_DIST_OUT into L_item_dist_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      close C_GET_ITEM_ALLOC_DIST_OUT;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      open C_GET_PACK_ALLOC_DIST_OUT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_PACK_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      fetch C_GET_PACK_ALLOC_DIST_OUT into L_pack_dist_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK_ALLOC_DIST_OUT',
                       'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER',
                       'item parent:  '||I_item_parent||' or '||'item grandparent  '||I_item_parent);
      close C_GET_PACK_ALLOC_DIST_OUT;

      O_total_qty := L_item_dist_qty + L_pack_dist_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));

      return FALSE;
   END ITEM_PARENT_QTY;
   ---

BEGIN
   if (LP_item != I_item or LP_item is NULL) then
      LP_item := I_item;

      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      open C_ITEM_INFO;

      SQL_LIB.SET_MARK('FETCH',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      fetch C_ITEM_INFO into LP_pack_ind,
                             LP_item_level,
                             LP_tran_level;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_INFO',
                       'ITEM_MASTER',
                       'item:  '||I_item);
      close C_ITEM_INFO;

   end if;

   if LP_item_level < LP_tran_level then
      if not ITEM_PARENT_QTY(I_item,
                             O_total_dist_qty) then
         return FALSE;
      end if;

   elsif LP_item_level = LP_tran_level then
      if not ALLOC_QUANTITY(I_item,
                            O_total_dist_qty) then
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_TOTAL_DIST_QTY;

--------------------------------------------------------------------------------------
FUNCTION GET_TRAN_ITEM_LOC_QTYS
        (O_error_message        IN OUT  VARCHAR2,
         O_stock_on_hand        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_soh        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_in_transit_qty       IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_intran     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_tsf_reserved_qty     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_resv       IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_tsf_expected_qty     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_exp        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_rtv_qty              IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_non_sellable_qty     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_customer_resv        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_customer_backorder   IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_cust_resv  IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_cust_back  IN OUT  item_loc_soh.stock_on_hand%TYPE,
         I_item                 IN      item_loc.item%TYPE,
         I_loc                  IN      item_loc.loc%TYPE,
         I_loc_type             IN      item_loc.loc_type%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_TRAN_ITEM_LOC_QTYS';
   L_tsf_expected_qty  item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp     item_loc_soh.stock_on_hand%TYPE := 0;
   L_pl_tsf_item_qty   tsfdetail.tsf_qty%TYPE := 0;
   L_pl_tsf_pack_qty   tsfdetail.tsf_qty%TYPE := 0;

   cursor C_SOH_ALL_WH is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh
       where loc_type = 'W'
         and item = I_item;

   cursor C_SOH_ALL_ST is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh
       where loc_type = 'S'
         and item = I_item;

   cursor C_SOH_ALL is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh
       where item = I_item;

   cursor C_SOH_LOC is
      select nvl(stock_on_hand,0),
             nvl(pack_comp_soh,0),
             nvl(in_transit_qty,0),
             nvl(pack_comp_intran,0),
             nvl(tsf_reserved_qty,0),
             nvl(pack_comp_resv,0),
             nvl(tsf_expected_qty,0),
             nvl(pack_comp_exp,0),
             nvl(rtv_qty,0),
             nvl(non_sellable_qty,0),
             nvl(customer_resv,0),
             nvl(customer_backorder,0),
             nvl(pack_comp_cust_resv,0),
             nvl(pack_comp_cust_back,0)
        from item_loc_soh
       where loc = I_loc
         and item = I_item;

   BEGIN

   O_stock_on_hand         := 0;
   O_pack_comp_soh         := 0;
   O_in_transit_qty        := 0;
   O_pack_comp_intran      := 0;
   O_tsf_reserved_qty      := 0;
   O_pack_comp_resv        := 0;
   O_tsf_expected_qty      := 0;
   O_pack_comp_exp         := 0;
   O_rtv_qty               := 0;
   O_non_sellable_qty      := 0;
   O_customer_resv         := 0;
   O_customer_backorder    := 0;
   O_pack_comp_cust_resv   := 0;
   O_pack_comp_cust_back   := 0;

   if (LP_wh_crosslink_ind is NULL) then
     if not SYSTEM_OPTIONS_SQL.GET_WH_CROSS_LINK_IND(O_error_message,
                                                     LP_wh_crosslink_ind) then
        return FALSE;
     end if;
   end if;

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_loc is not NULL then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_LOC', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      open C_SOH_LOC;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_LOC', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      fetch C_SOH_LOC into O_stock_on_hand,
                           O_pack_comp_soh,
                           O_in_transit_qty,
                           O_pack_comp_intran,
                           O_tsf_reserved_qty,
                           O_pack_comp_resv,
                           L_tsf_expected_qty,
                           L_pack_comp_exp,
                           O_rtv_qty,
                           O_non_sellable_qty,
                           O_customer_resv,
                           O_customer_backorder,
                           O_pack_comp_cust_resv,
                           O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_LOC', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      close C_SOH_LOC;

   elsif I_loc_type is NULL then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL into O_stock_on_hand,
                           O_pack_comp_soh,
                           O_in_transit_qty,
                           O_pack_comp_intran,
                           O_tsf_reserved_qty,
                           O_pack_comp_resv,
                           L_tsf_expected_qty,
                           L_pack_comp_exp,
                           O_rtv_qty,
                           O_non_sellable_qty,
                           O_customer_resv,
                           O_customer_backorder,
                           O_pack_comp_cust_resv,
                           O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL;

   elsif I_loc_type = 'S' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL_ST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL_ST;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL_ST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL_ST into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL_ST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL_ST;

   elsif I_loc_type = 'W' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL_WH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL_WH;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL_WH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL_WH into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL_WH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL_WH;

   end if;

   if ((I_loc_type != 'W' or I_loc_type is NULL) and
        LP_wh_crosslink_ind = 'Y') then
      if not GET_PL_TRANSFER(O_error_message,
                             L_pl_tsf_item_qty,
                             L_pl_tsf_pack_qty,
                             I_item,
                             I_loc,
                             I_loc_type,
                             NULL) then
         return FALSE;
      end if;

      O_tsf_expected_qty := L_tsf_expected_qty +
                            L_pl_tsf_item_qty;
      O_pack_comp_exp := L_pack_comp_exp +
                         L_pl_tsf_pack_qty;
   else
      O_tsf_expected_qty := L_tsf_expected_qty;
      O_pack_comp_exp := L_pack_comp_exp;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TRAN_ITEM_LOC_QTYS;

--------------------------------------------------------------------------------------
FUNCTION GET_FUTURE_EXPECTED(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_future_expected IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                             I_item            IN       ITEM_MASTER.ITEM%TYPE,
                             I_location        IN       ITEM_LOC.LOC%TYPE)
RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_FUTURE_EXPECTED';

   cursor C_FUTURE_EXPECTED is
      select SUM(NVL(td.tsf_qty, 0)) - SUM(NVL(td.ship_qty, 0))
        from tsfhead   th,
             tsfdetail td
       where th.status        IN ('A', 'S')
         and th.tsf_parent_no is NOT NULL
         and th.to_loc        = I_location
         and th.tsf_no        = td.tsf_no
         and td.item          = I_item;

BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_location is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_location',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;

   open C_FUTURE_EXPECTED;

   fetch C_FUTURE_EXPECTED into O_future_expected;

   close C_FUTURE_EXPECTED;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_FUTURE_EXPECTED;

--------------------------------------------------------------------------------------
FUNCTION GET_LOC_PACK_COMP_NON_SELLABLE(O_error_message           IN OUT  rtk_errors.rtk_text%TYPE,
                                        O_pack_comp_non_sellable  IN OUT  item_loc_soh.pack_comp_non_sellable%TYPE,
                                        I_item                    IN      item_loc.item%TYPE,
                                        I_loc                     IN      item_loc.loc%TYPE,
                                        I_loc_type                IN      item_loc.loc_type%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_LOC_PACK_COMP_NON_SELABLE';

   cursor C_SOH_ALL_WH is
      select /*+ INDEX(item_loc_soh, pk_item_loc_soh) INDEX(item_loc_soh, item_loc_soh_I3) INDEX(item_loc_soh, item_loc_soh_I4) */
             nvl(sum(pack_comp_non_sellable),0)
        from item_loc_soh
       where loc_type = 'W'
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_ALL_ST is
      select /*+ INDEX(item_loc_soh, pk_item_loc_soh) INDEX(item_loc_soh, item_loc_soh_I3) INDEX(item_loc_soh, item_loc_soh_I4) */
             nvl(sum(pack_comp_non_sellable),0)
        from item_loc_soh
       where loc_type = 'S'
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_ALL_E is
      select nvl(sum(pack_comp_non_sellable),0)
        from item_loc_soh
       where loc_type = 'E'
         and (item = TO_CHAR(I_item) or
              item_parent = TO_CHAR(I_item) or
              item_grandparent = TO_CHAR(I_item));

   cursor C_SOH_ALL is
      select nvl(sum(pack_comp_non_sellable),0)
        from item_loc_soh
       where (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_LOC is
      select /*+ INDEX(item_loc_soh, pk_item_loc_soh) INDEX(item_loc_soh, item_loc_soh_I3) INDEX(item_loc_soh, item_loc_soh_I4) */
             nvl(sum(pack_comp_non_sellable),0)
        from item_loc_soh
       where loc = I_loc
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);


BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_loc is not NULL then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_LOC', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      open C_SOH_LOC;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_LOC', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      fetch C_SOH_LOC into O_pack_comp_non_sellable;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_LOC', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item||' Loc: '||to_char(I_loc));
      close C_SOH_LOC;

   elsif I_loc_type is NULL then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL into O_pack_comp_non_sellable;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL;

   elsif I_loc_type = 'S' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL_ST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL_ST;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL_ST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL_ST into O_pack_comp_non_sellable;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL_ST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL_ST;

   elsif I_loc_type = 'W' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL_WH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL_WH;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL_WH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL_WH into O_pack_comp_non_sellable;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL_WH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL_WH;

   elsif I_loc_type = 'E' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_ALL_E', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_ALL_E;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_ALL_E', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_ALL_E into O_pack_comp_non_sellable;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_ALL_E', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_ALL_E;

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_LOC_PACK_COMP_NON_SELLABLE;

--------------------------------------------------------------------------------------
FUNCTION GET_ITEM_GROUP_QTYS
        (O_error_message        IN OUT  VARCHAR2,
         O_stock_on_hand        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_soh        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_in_transit_qty       IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_intran     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_tsf_reserved_qty     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_resv       IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_tsf_expected_qty     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_exp        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_rtv_qty              IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_non_sellable_qty     IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_customer_resv        IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_customer_backorder   IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_cust_resv  IN OUT  item_loc_soh.stock_on_hand%TYPE,
         O_pack_comp_cust_back  IN OUT  item_loc_soh.stock_on_hand%TYPE,
         I_item                 IN      item_loc.item%TYPE,
         I_group_id             IN      partner.partner_id%TYPE,
         I_group_type           IN      code_detail.code%TYPE)
RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ITEM_GROUP_QTYS';
   L_loc_type               ITEM_LOC.LOC_TYPE%TYPE := NULL;
   L_loc                    ITEM_LOC.LOC%TYPE := NULL;
   L_tsf_expected_qty       item_loc_soh.stock_on_hand%TYPE := 0;
   L_pack_comp_exp          item_loc_soh.stock_on_hand%TYPE := 0;
   L_pl_tsf_item_qty   tsfdetail.tsf_qty%TYPE := 0;
   L_pl_tsf_pack_qty   tsfdetail.tsf_qty%TYPE := 0;

   cursor C_SOH_PWH is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh,
             wh
       where loc_type = 'W'
         and loc = wh.wh
         and wh.finisher_ind = 'N'
         and wh.physical_wh = I_group_id
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_STS is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh ils,
             store_hierarchy sh,
             store s
       where ils.loc_type = 'S'
         and ils.loc = sh.store
         and ils.loc = s.store
         and ((I_group_type = 'A' and sh.area = I_group_id)
              or (I_group_type = 'R' and sh.region = I_group_id)
              or (I_group_type = 'D' and sh.district = I_group_id)
              or (I_group_type = 'C' and s.store_class = I_group_id)
              or (I_group_type = 'DW' and s.default_wh = I_group_id)
              or (I_group_type = 'T' and s.transfer_zone = I_group_id))
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_PZGS is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh ils,
             price_zone pz,
             price_zone_group_store pzgs
       where ils.loc = pzgs.store
         and pz.zone_group_id = pzgs.zone_group_id
         and pz.zone_id = pzgs.zone_id
         and pz.zone_id = I_group_id
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_LOC_TRAITS is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh ils,
             loc_traits_matrix ltm
       where ils.loc = ltm.store
         and ltm.loc_trait = I_group_id
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

   cursor C_SOH_LOC_LST is
      select nvl(sum(stock_on_hand),0),
             nvl(sum(pack_comp_soh),0),
             nvl(sum(in_transit_qty),0),
             nvl(sum(pack_comp_intran),0),
             nvl(sum(tsf_reserved_qty),0),
             nvl(sum(pack_comp_resv),0),
             nvl(sum(tsf_expected_qty),0),
             nvl(sum(pack_comp_exp),0),
             nvl(sum(rtv_qty),0),
             nvl(sum(non_sellable_qty),0),
             nvl(sum(customer_resv),0),
             nvl(sum(customer_backorder),0),
             nvl(sum(pack_comp_cust_resv),0),
             nvl(sum(pack_comp_cust_back),0)
        from item_loc_soh ils,
             loc_list_detail lld
       where ils.loc = lld.location
         and ils.loc_type = lld.loc_type
         and lld.loc_list = I_group_id
         and (item = I_item or
              item_parent = I_item or
              item_grandparent = I_item);

BEGIN
   ---
   if (LP_wh_crosslink_ind is NULL) then
     if not SYSTEM_OPTIONS_SQL.GET_WH_CROSS_LINK_IND(O_error_message,
                                                     LP_wh_crosslink_ind) then
        return FALSE;
     end if;
   end if;

   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   ---
   if I_group_type in ('S', 'W', 'I', 'E', 'AS', 'AL', 'AW', 'AI', 'AE') then
      ---
      if I_group_type in ('S', 'W', 'I', 'E') then
         L_loc_type := I_group_type;
         L_loc := I_group_id;
      elsif I_group_type = 'AS' then
         L_loc_type := 'S';
      elsif I_group_type = 'AW' then
         L_loc_type := 'W';
         L_loc := NULL;
      elsif I_group_type = 'AI' then
         L_loc_type := 'I';
         L_loc := NULL;
      elsif I_group_type = 'AE' then
         L_loc_type := 'E';
         L_loc := NULL;
      end if;
      ---
      if GET_ITEM_LOC_QTYS(O_error_message,
                           O_stock_on_hand,
                           O_pack_comp_soh,
                           O_in_transit_qty,
                           O_pack_comp_intran,
                           O_tsf_reserved_qty,
                           O_pack_comp_resv,
                           O_tsf_expected_qty,
                           O_pack_comp_exp,
                           O_rtv_qty,
                           O_non_sellable_qty,
                           O_customer_resv,
                           O_customer_backorder,
                           O_pack_comp_cust_resv,
                           O_pack_comp_cust_back,
                           I_item,
                           L_loc,
                           L_loc_type) = FALSE then
         return FALSE;
      end if;
      ---
   elsif I_group_type = 'PW' then
      ---
      L_loc_type := 'W';
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_SOH_PWH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_PWH;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_PWH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_PWH into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_PWH', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_PWH;

   elsif I_group_type in ('A','R','D', 'C', 'DW', 'T', 'P') then
      ---
      L_loc_type := 'S';
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_SOH_STS', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_STS;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_STS', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_STS into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_STS', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_STS;

   elsif I_group_type = 'Z' then

      SQL_LIB.SET_MARK('OPEN', 'C_SOH_PZGS', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_PZGS;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_PZGS', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_PZGS into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_PZGS', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_PZGS;

   elsif I_group_type = 'L' then
      ---
      L_loc_type := 'S';
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_SOH_LOC_TRAITS', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_LOC_TRAITS;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_LOC_TRAITS', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_LOC_TRAITS into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_LOC_TRAITS', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_LOC_TRAITS;

   elsif I_group_type in ('LLS', 'LLW') then
      ---
      if I_group_type = 'LLS' then
         L_loc_type := 'S';
      else
         L_loc_type := 'W';
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_SOH_LOC_LST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      open C_SOH_LOC_LST;
      SQL_LIB.SET_MARK('FETCH', 'C_SOH_LOC_LST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      fetch C_SOH_LOC_LST into O_stock_on_hand,
                              O_pack_comp_soh,
                              O_in_transit_qty,
                              O_pack_comp_intran,
                              O_tsf_reserved_qty,
                              O_pack_comp_resv,
                              L_tsf_expected_qty,
                              L_pack_comp_exp,
                              O_rtv_qty,
                              O_non_sellable_qty,
                              O_customer_resv,
                              O_customer_backorder,
                              O_pack_comp_cust_resv,
                              O_pack_comp_cust_back;
      SQL_LIB.SET_MARK('CLOSE', 'C_SOH_LOC_LST', 'ITEM_LOC_SOH',
                       'Item: ' ||I_item);
      close C_SOH_LOC_LST;

   end if;
   ---
   if I_group_type not in ('S', 'W', 'I', 'E', 'AS', 'AL', 'AW', 'AI', 'AE') then
      ---
      if ((L_loc_type not in ('W', 'I') or L_loc_type is NULL) and
         LP_wh_crosslink_ind = 'Y') then
         if not GET_PL_TRANSFER(O_error_message,
                                L_pl_tsf_item_qty,
                                L_pl_tsf_pack_qty,
                                I_item,
                                L_loc,
                                L_loc_type,
                                NULL) then
            return FALSE;
         end if;

         O_tsf_expected_qty := L_tsf_expected_qty + L_pl_tsf_item_qty;
         O_pack_comp_exp := L_pack_comp_exp + L_pl_tsf_pack_qty;
      else
         O_tsf_expected_qty := L_tsf_expected_qty;
         O_pack_comp_exp := L_pack_comp_exp;
      end if;
      ---
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
END GET_ITEM_GROUP_QTYS;
----------------------------------------------------------------------------------------
FUNCTION GET_ON_ORDER_GROUP(I_item           IN     ITEM_LOC.ITEM%TYPE,
                            I_group_id       IN     PARTNER.PARTNER_ID%TYPE,
                            I_group_type     IN     CODE_DETAIL.CODE%TYPE,
                            I_date           IN     DATE,
                            I_all_orders     IN     VARCHAR2,
                            O_quantity       IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                            O_pack_quantity  IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                            O_error_message  IN OUT VARCHAR2)
RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ON_ORDER_GROUP';
   L_loc                    ITEM_LOC.LOC%TYPE := NULL;
   L_loc_type               ITEM_LOC.LOC_TYPE%TYPE := NULL;

   FUNCTION ORDER_QUANTITY_GROUP(I_item      IN     ITEM_LOC.ITEM%TYPE,
                                 O_total_qty IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                                 O_pack_qty  IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)

   RETURN BOOLEAN IS

      L_item_qty ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_qty ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_ON_ORDER_ITEM_PWH is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                wh
          where ol.item = I_item
            and ol.loc_type = 'W'
            and ol.order_no = oh.order_no
            and ol.location = wh.wh
            and wh.physical_wh = I_group_id
            and wh.finisher_ind = 'N'
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and oh.status = 'A'
            and (oh.not_before_date < I_date  or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N');

      cursor C_ON_ORDER_ITEM_STS is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                store s,
                store_hierarchy sh
          where ol.item = I_item
            and ol.loc_type = 'S'
            and ol.order_no = oh.order_no
            and ol.location = s.store
            and s.store = sh.store
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and oh.status = 'A'
            and (oh.not_before_date < I_date  or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ((I_group_type = 'A' and sh.area = I_group_id)
                 or (I_group_type = 'R' and sh.region = I_group_id)
                 or (I_group_type = 'D' and sh.district = I_group_id)
                 or (I_group_type = 'C' and s.store_class = I_group_id)
                 or (I_group_type = 'T' and s.transfer_zone = I_group_id)
                 or (I_group_type = 'DW' and s.default_wh = I_group_id));

      cursor C_ON_ORDER_ITEM_LOCLST is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                loc_list_detail lld
          where ol.item = I_item
            and ol.location = lld.location
            and ((ol.loc_type = 'W' and I_group_type = 'LLW')
                 or (ol.loc_type = 'S' and I_group_type = 'LLS'))
            and lld.loc_list = I_group_id
            and ol.order_no = oh.order_no
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and oh.status = 'A'
            and (oh.not_before_date < I_date  or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N');

      cursor C_ON_ORDER_ITEM_LOCTRAIT is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                loc_traits_matrix ltm
          where ol.item = I_item
            and ol.location = ltm.store
            and ol.loc_type = 'S'
            and ltm.loc_trait = I_group_id
            and ol.order_no = oh.order_no
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and oh.status = 'A'
            and (oh.not_before_date < I_date  or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N');

      cursor C_ON_ORDER_ITEM_PZGS is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                price_zone_group_store pzgs
          where ol.item = I_item
            and ol.order_no = oh.order_no
            and ol.location = pzgs.store
            and pzgs.zone_id = I_group_id
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and oh.status = 'A'
            and (oh.not_before_date < I_date  or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N');

      cursor C_ON_ORDER_PACK_PWH is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                wh
          where ol.loc_type = 'W'
            and ol.location = wh.wh
            and wh.physical_wh = I_group_id
            and wh.finisher_ind = 'N'
            and ol.order_no = oh.order_no
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = pack_no
            and oh.status = 'A'
            and (oh.not_before_date < I_date or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and p.item = I_item;

      cursor C_ON_ORDER_PACK_STS is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                store s,
                store_hierarchy sh
          where ol.loc_type = 'S'
            and ol.location = s.store
            and s.store = sh.store
            and ol.order_no = oh.order_no
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = pack_no
            and oh.status = 'A'
            and (oh.not_before_date < I_date or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and p.item = I_item
            and ((I_group_type = 'A' and sh.area = I_group_id)
                 or (I_group_type = 'R' and sh.region = I_group_id)
                 or (I_group_type = 'D' and sh.district = I_group_id)
                 or (I_group_type = 'C' and s.store_class = I_group_id)
                 or (I_group_type = 'T' and s.transfer_zone = I_group_id)
                 or (I_group_type = 'DW' and s.default_wh = I_group_id));

      cursor C_ON_ORDER_PACK_LOCLST is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                loc_list_detail lld
          where ol.location = lld.location
            and ((ol.loc_type = 'W' and I_group_type = 'LLW')
                 or (ol.loc_type = 'S' and I_group_type = 'LLS'))
            and lld.loc_list = I_group_id
            and ol.order_no = oh.order_no
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = pack_no
            and oh.status = 'A'
            and (oh.not_before_date < I_date or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and p.item = I_item;

      cursor C_ON_ORDER_PACK_LOCTRAIT is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                loc_traits_matrix ltm
          where ol.location = ltm.store
            and ol.loc_type = 'S'
            and ltm.loc_trait = I_group_id
            and ol.order_no = oh.order_no
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = pack_no
            and oh.status = 'A'
            and (oh.not_before_date < I_date or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and p.item = I_item;

      cursor C_ON_ORDER_PACK_PZGS is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                price_zone_group_store pzgs
          where ol.location = pzgs.store
            and pzgs.zone_id = I_group_id
            and ol.order_no = oh.order_no
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = pack_no
            and oh.status = 'A'
            and (oh.not_before_date < I_date or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and p.item = I_item;

   BEGIN
     ---
     if I_group_type = 'PW' then
        ---
        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_PWH',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        open C_ON_ORDER_ITEM_PWH;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_PWH',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        fetch C_ON_ORDER_ITEM_PWH into L_item_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_PWH',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        close C_ON_ORDER_ITEM_PWH;

        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PACK_PWH',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        open C_ON_ORDER_PACK_PWH;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PACK_PWH',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        fetch C_ON_ORDER_PACK_PWH into L_pack_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PACK_PWH',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        close C_ON_ORDER_PACK_PWH;
        ---
     elsif I_group_type in ('A','R','D', 'C', 'DW', 'T', 'P') then
        ---
        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_STS',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        open C_ON_ORDER_ITEM_STS;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_STS',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        fetch C_ON_ORDER_ITEM_STS into L_item_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_STS',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        close C_ON_ORDER_ITEM_STS;

        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PACK_STS',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        open C_ON_ORDER_PACK_STS;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PACK_STS',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        fetch C_ON_ORDER_PACK_STS into L_pack_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PACK_STS',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        close C_ON_ORDER_PACK_STS;
        ---
     elsif I_group_type in ('LLW', 'LLS') then
        ---
        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_LOCLST',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        open C_ON_ORDER_ITEM_LOCLST;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_LOCLST',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        fetch C_ON_ORDER_ITEM_LOCLST into L_item_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_LOCLST',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        close C_ON_ORDER_ITEM_LOCLST;

        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PACK_LOCLST',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        open C_ON_ORDER_PACK_LOCLST;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PACK_LOCLST',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        fetch C_ON_ORDER_PACK_LOCLST into L_pack_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PACK_STS',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        close C_ON_ORDER_PACK_LOCLST;
        ---
     elsif I_group_type = 'L' then
        ---
        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_LOCTRAIT',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        open C_ON_ORDER_ITEM_LOCTRAIT;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_LOCTRAIT',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        fetch C_ON_ORDER_ITEM_LOCTRAIT into L_item_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_LOCTRAIT',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        close C_ON_ORDER_ITEM_LOCTRAIT;

        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PACK_LOCTRAIT',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        open C_ON_ORDER_PACK_LOCTRAIT;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PACK_LOCTRAIT',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        fetch C_ON_ORDER_PACK_LOCTRAIT into L_pack_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PACK_LOCTRAIT',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        close C_ON_ORDER_PACK_LOCTRAIT;
        ---
     elsif I_group_type = 'Z' then
        ---
        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_PZGS',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        open C_ON_ORDER_ITEM_PZGS;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_PZGS',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        fetch C_ON_ORDER_ITEM_PZGS into L_item_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_PZGS',
                         'ORDHEAD, ORDLOC', 'item:  '||I_item);
        close C_ON_ORDER_ITEM_PZGS;

        SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PACK_PZGS',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        open C_ON_ORDER_PACK_PZGS;
        SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PACK_PZGS',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        fetch C_ON_ORDER_PACK_PZGS into L_pack_qty;
        SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PACK_PZGS',
                         'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT', 'item:  '||I_item);
        close C_ON_ORDER_PACK_PZGS;
        ---
     end if;
     ---
     O_total_qty := L_item_qty + L_pack_qty;
     O_pack_qty  := L_pack_qty;

     return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
      return FALSE;
   END ORDER_QUANTITY_GROUP;
   ---
   FUNCTION ITEM_PARENT_QTY_GROUP(I_item_parent IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                                  O_total_qty   IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
   RETURN BOOLEAN IS

      L_item_qty                ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_qty                ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_ON_ORDER_ITEM_PWH is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                item_master im,
                wh
          where ol.loc_type = 'W'
            and ol.order_no = oh.order_no
            and ol.location = wh.wh
            and wh.physical_wh = I_group_id
            and wh.finisher_ind = 'N'
            and oh.status = 'A'
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and im.item = ol.item
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_ON_ORDER_ITEM_STS is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                item_master im,
                store_hierarchy sh,
                store s
          where ol.location = s.store
            and s.store = sh.store
            and ((I_group_type = 'A' and sh.area = I_group_id)
                 or (I_group_type = 'R' and sh.region = I_group_id)
                 or (I_group_type = 'D' and sh.district = I_group_id)
                 or (I_group_type = 'C' and s.store_class = I_group_id)
                 or (I_group_type = 'T' and s.transfer_zone = I_group_id)
                 or (I_group_type = 'DW' and s.default_wh = I_group_id))
            and ol.order_no = oh.order_no
            and oh.status = 'A'
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and im.item = ol.item
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_ON_ORDER_ITEM_LOCLST is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                item_master im,
                loc_list_detail lld
          where ol.location = lld.location
            and ((lld.loc_type = 'W' and I_group_type = 'LLW')
                 or (lld.loc_type = 'S' and I_group_type = 'LLS'))
            and lld.loc_list = I_group_id
            and ol.order_no = oh.order_no
            and oh.status = 'A'
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and im.item = ol.item
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_ON_ORDER_ITEM_LOCTRAIT is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                item_master im,
                loc_traits_matrix ltm
          where ol.loc_type = 'S'
            and ol.order_no = oh.order_no
            and ol.location = ltm.store
            and ltm.loc_trait = I_group_id
            and oh.status = 'A'
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and im.item = ol.item
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_ON_ORDER_ITEM_PZGS is
         select nvl(sum(ol.qty_ordered - nvl(ol.qty_received,0)),0)
           from ordhead oh,
                ordloc ol,
                item_master im,
                price_zone_group_store pzgs
          where ol.order_no = oh.order_no
            and ol.location = pzgs.store
            and pzgs.zone_id = I_group_id
            and oh.status = 'A'
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and im.item = ol.item
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_ON_ORDER_PI_PWH is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                item_master im,
                wh
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.loc_type = 'W'
            and ol.location = wh.wh
            and wh.physical_wh = I_group_id
            and wh.finisher_ind = 'N'
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

      cursor C_ON_ORDER_PI_STS is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                item_master im,
                store_hierarchy sh,
                store s
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.loc_type = 'S'
            and ol.location = s.store
            and sh.store = sh.store
            and ((I_group_type = 'A' and sh.area = I_group_id)
                 or (I_group_type = 'R' and sh.region = I_group_id)
                 or (I_group_type = 'D' and sh.district = I_group_id)
                 or (I_group_type = 'C' and s.store_class = I_group_id)
                 or (I_group_type = 'T' and s.transfer_zone = I_group_id)
                 or (I_group_type = 'DW' and s.default_wh = I_group_id))
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

      cursor C_ON_ORDER_PI_LOCLST is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                item_master im,
                loc_list_detail lld
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.location = lld.location
            and ((lld.loc_type = 'W' and I_group_type = 'LLW')
                 or (lld.loc_type = 'S' and I_group_type = 'LLS'))
            and lld.loc_list = I_group_id
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

      cursor C_ON_ORDER_PI_LOCTRAIT is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                item_master im,
                loc_traits_matrix ltm
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.loc_type = 'S'
            and ol.location = ltm.store
            and ltm.loc_trait = I_group_id
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

      cursor C_ON_ORDER_PI_PZGS is
         select nvl(sum(p.pack_item_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem_breakout p,
                item_master im,
                price_zone_group_store pzgs
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.location = pzgs.store
            and pzgs.zone_id = I_group_id
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;
   BEGIN
      if I_group_type = 'PW' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_PWH', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_ITEM_PWH;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_PWH', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_ITEM_PWH into L_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_PWH', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_ITEM_PWH;

         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_PWH', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_PI_PWH;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_PWH', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_PI_PWH into L_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_PWH', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_PI_PWH;
         ---
      elsif I_group_type in ('A','R','D', 'C', 'DW', 'T', 'P') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_STS', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_ITEM_STS;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_STS', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_ITEM_STS into L_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_STS', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_ITEM_STS;

         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_STS', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_PI_STS;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_STS', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_PI_STS into L_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_STS', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_PI_STS;
         ---
      elsif I_group_type in ('LLW', 'LLS') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_LOCLST', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_ITEM_LOCLST;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_LOCLST', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_ITEM_LOCLST into L_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_LOCLST', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_ITEM_LOCLST;

         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_LOCLST', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_PI_LOCLST;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_LOCLST', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_PI_LOCLST into L_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_LOCLST', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_PI_LOCLST;
         ---
      elsif I_group_type = 'L' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_LOCTRAIT', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_ITEM_LOCTRAIT;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_LOCTRAIT', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_ITEM_LOCTRAIT into L_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_LOCTRAIT', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_ITEM_LOCTRAIT;

         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_LOCTRAIT', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_PI_LOCTRAIT;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_LOCTRAIT', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_PI_LOCTRAIT into L_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_LOCTRAIT', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_PI_LOCTRAIT;
         ---
      elsif I_group_type = 'Z' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_ITEM_PZGS', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_ITEM_PZGS;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_ITEM_PZGS', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_ITEM_PZGS into L_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_ITEM_PZGS', 'ORDHEAD, ORDLOC, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_ITEM_PZGS;

         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_PZGS', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_ON_ORDER_PI_PZGS;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_PZGS', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_ON_ORDER_PI_PZGS into L_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_PZGS', 'ORDHEAD, ORDLOC, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_ON_ORDER_PI_PZGS;
         ---
      end if;
      ---
      O_total_qty := L_item_qty + L_pack_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END ITEM_PARENT_QTY_GROUP;
   ---
   FUNCTION PACK_AND_ITEM_QTY_GROUP(I_item       IN     ITEM_LOC.ITEM%TYPE,
                                    O_total_qty  IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
   RETURN BOOLEAN IS

      L_item_qty        ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_qty        ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_qty_dummy  ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_ON_ORDER_PI_PWH is
         select nvl(sum(p.pack_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem p,
                wh
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.loc_type = 'W'
            and ol.location = wh.wh
            and wh.physical_wh = I_group_id
            and wh.finisher_ind = 'N'
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and p.item = I_item;

      cursor C_ON_ORDER_PI_STS is
         select nvl(sum(p.pack_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem p,
                store_hierarchy sh,
                store s
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.loc_type = 'S'
            and ol.location = sh.store
            and s.store = sh.store
            and ((I_group_type = 'A' and sh.area = I_group_id)
                 or (I_group_type = 'R' and sh.region = I_group_id)
                 or (I_group_type = 'D' and sh.district = I_group_id)
                 or (I_group_type = 'C' and s.store_class = I_group_id)
                 or (I_group_type = 'T' and s.transfer_zone = I_group_id)
                 or (I_group_type = 'DW' and s.default_wh = I_group_id))
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and p.item = I_item;

      cursor C_ON_ORDER_PI_LOCLST is
         select nvl(sum(p.pack_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem p,
                loc_list_detail lld
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.location = lld.location
            and ((lld.loc_type = 'W' and I_group_type = 'LLW')
                 or (lld.loc_type = 'S' and I_group_type = 'LLS'))
            and lld.loc_list = I_group_id
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and p.item = I_item;

      cursor C_ON_ORDER_PI_LOCTRAIT is
         select nvl(sum(p.pack_qty *
                       (ol.qty_ordered - nvl(ol.qty_received,0))),0)
           from ordhead oh,
                ordloc ol,
                packitem p,
                loc_traits_matrix ltm
          where oh.status = 'A'
            and (oh.not_before_date < I_date
                or (I_date is NULL))
            and NOT (I_all_orders = 'N' and oh.include_on_order_ind = 'N')
            and ol.order_no = oh.order_no
            and ol.location = ltm.store
            and ol.loc_type = 'S'
            and ltm.loc_trait = I_group_id
            and ol.qty_ordered > nvl(ol.qty_received,0)
            and ol.item = p.pack_no
            and p.item = I_item;

   BEGIN
      ---
      if not ORDER_QUANTITY_GROUP(I_item,
                                  L_item_qty,
                                  L_pack_qty_dummy ) then
         return FALSE;
      end if;
      ---
      if I_group_type = 'PW' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_PWH',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         open C_ON_ORDER_PI_PWH;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_PWH',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         fetch C_ON_ORDER_PI_PWH into L_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_PWH',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         close C_ON_ORDER_PI_PWH;
         ---
      elsif I_group_type in ('A','R','D', 'C', 'DW', 'T', 'P') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_STS',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         open C_ON_ORDER_PI_STS;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_STS',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         fetch C_ON_ORDER_PI_STS into L_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_PWH',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         close C_ON_ORDER_PI_STS;
         ---
      elsif I_group_type in ('LLW', 'LLS') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_LOCLST',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         open C_ON_ORDER_PI_LOCLST;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_LOCLST',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         fetch C_ON_ORDER_PI_LOCLST into L_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_LOCLST',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         close C_ON_ORDER_PI_LOCLST;
         ---
      elsif I_group_type = 'L' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ON_ORDER_PI_LOCTRAIT',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         open C_ON_ORDER_PI_LOCTRAIT;
         SQL_LIB.SET_MARK('FETCH', 'C_ON_ORDER_PI_LOCTRAIT',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         fetch C_ON_ORDER_PI_LOCTRAIT into L_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_ON_ORDER_PI_LOCTRAIT',
                          'ORDHEAD, ORDLOC, PACKITEM', 'item:  '||I_item);
         close C_ON_ORDER_PI_LOCTRAIT;
         ---
      end if;
      ---
      O_total_qty := L_item_qty + L_pack_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END PACK_AND_ITEM_QTY_GROUP;
   ---

BEGIN
   ---
   -- Finishers won't be applied to POs, so the stock on order in finisher locations is
   -- always zero.
   ---
   if I_group_type in ('I', 'E', 'AI', 'AE') then
      O_quantity := 0;
      return TRUE;
   end if;
   ---
   if I_group_type in ('S', 'W', 'AL', 'AS', 'AW') then
      ---
      if I_group_type in ('S', 'W') then
         ---
         L_loc := I_group_id;
         L_loc_type := I_group_type;
         ---
      elsif I_group_type = 'AS' then
         ---
         L_loc_type := 'S';
         ---
      elsif I_group_type = 'AW' then
         ---
         L_loc_type := 'W';
         ---
      end if;
      ---
      if GET_ON_ORDER(I_item,
                      L_loc,
                      L_loc_type,
                      I_date,
                      I_all_orders,
                      O_quantity,
                      O_pack_quantity,
                      O_error_message) = FALSE then
         return FALSE;
      end if;
      ---
   else
      ---
      if (LP_item != I_item or LP_item is NULL) then
         LP_item := I_item;

         SQL_LIB.SET_MARK('OPEN', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
         open C_ITEM_INFO;
         SQL_LIB.SET_MARK('FETCH', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
         fetch C_ITEM_INFO into LP_pack_ind,
                                LP_item_level,
                                LP_tran_level;
         SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
         close C_ITEM_INFO;

      end if;
      ---
      if LP_item_level < LP_tran_level then
         if not ITEM_PARENT_QTY_GROUP(I_item,
                                      O_quantity ) then
            return FALSE;
         end if;

      elsif LP_item_level = LP_tran_level then
         if LP_pack_ind = 'Y' then
            if not PACK_AND_ITEM_QTY_GROUP(I_item,
                                           O_quantity ) then
               return FALSE;
            end if;
         else  --LP_pack_ind = 'N'
            if not ORDER_QUANTITY_GROUP(I_item,
                                        O_quantity,
                                        O_pack_quantity ) then
               return FALSE;
            end if;
         end if;
      end if;
      ---
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ON_ORDER_GROUP;
----------------------------------------------------------------------------------------
FUNCTION GET_ALLOC_IN_GROUP(I_item          IN     ITEM_LOC.ITEM%TYPE,
                            I_group_id      IN     PARTNER.PARTNER_ID%TYPE,
                            I_group_type    IN     CODE_DETAIL.CODE%TYPE,
                            I_date          IN     DATE,
                            I_all_orders    IN     VARCHAR2,
                            O_quantity      IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                            O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEMLOC_QUANTITY_SQL.GET_ON_ORDER_GROUP';
   L_loc                    ITEM_LOC.LOC%TYPE := NULL;
   L_loc_type               ITEM_LOC.LOC_TYPE%TYPE := NULL;


   FUNCTION ALLOC_QUANTITY_GROUP(I_item      IN  ITEM_LOC.ITEM%TYPE,
                                 O_quantity  OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
   RETURN BOOLEAN IS

   L_alloc_item_qty        ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
   L_alloc_pack_qty        ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

   cursor C_GET_ALLOC_IN_ITEM_PWH is
      select /*+ INDEX(h) */
             nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             wh
       where h.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = wh.wh
         and d.to_loc_type = 'W'
         and wh.physical_wh = I_group_id
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   cursor C_GET_ALLOC_IN_ITEM_STS is
      select /*+ INDEX(h) */
             nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             store_hierarchy sh,
             store s
       where h.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = s.store
         and s.store = sh.store
         and ((I_group_type = 'A' and sh.area = I_group_id)
              or (I_group_type = 'R' and sh.region = I_group_id)
              or (I_group_type = 'D' and sh.district = I_group_id)
              or (I_group_type = 'C' and s.store_class = I_group_id)
              or (I_group_type = 'T' and s.transfer_zone = I_group_id)
              or (I_group_type = 'DW' and s.default_wh = I_group_id))
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   cursor C_GET_ALLOC_IN_ITEM_LOCLST is
      select /*+ INDEX(h) */
             nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             loc_list_detail lld
       where h.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = lld.location
         and d.to_loc_type = lld.loc_type
         and ((lld.loc_type = 'W' and I_group_type = 'LLW')
              or (lld.loc_type = 'S' and I_group_type = 'LLS'))
         and lld.loc_list = I_group_id
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   cursor C_GET_ALLOC_IN_ITEM_LOCTRAIT is
      select /*+ INDEX(h) */
             nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             loc_traits_matrix ltm
       where h.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = ltm.store
         and d.to_loc_type = 'S'
         and ltm.loc_trait = I_group_id
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   cursor C_GET_ALLOC_IN_ITEM_PZGS is
      select /*+ INDEX(h) */
             nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             price_zone_group_store pzgs
       where h.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = pzgs.store
         and pzgs.zone_id = I_group_id
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   cursor C_GET_ALLOC_IN_PACK_PWH is
      select nvl(sum(p.pack_item_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             packitem_breakout p,
             wh
       where p.pack_no = h.item
         and p.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = wh.wh
         and d.to_loc_type = 'W'
         and wh.physical_wh = I_group_id
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   cursor C_GET_ALLOC_IN_PACK_STS is
      select nvl(sum(p.pack_item_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             packitem_breakout p,
             store_hierarchy sh,
             store s
       where p.pack_no = h.item
         and p.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = s.store
         and s.store = sh.store
         and ((I_group_type = 'A' and sh.area = I_group_id)
              or (I_group_type = 'R' and sh.region = I_group_id)
              or (I_group_type = 'D' and sh.district = I_group_id)
              or (I_group_type = 'C' and s.store_class = I_group_id)
              or (I_group_type = 'T' and s.transfer_zone = I_group_id)
              or (I_group_type = 'DW' and s.default_wh = I_group_id))
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   cursor C_GET_ALLOC_IN_PACK_LOCLST is
      select nvl(sum(p.pack_item_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             packitem_breakout p,
             loc_list_detail lld
       where p.pack_no = h.item
         and p.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = lld.location
         and d.to_loc_type = lld.loc_type
         and ((lld.loc_type = 'W' and I_group_type = 'LLW')
              or (lld.loc_type = 'S' and I_group_type = 'LLs'))
         and lld.loc_list = I_group_id
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   cursor C_GET_ALLOC_IN_PACK_LOCTRAIT is
      select nvl(sum(p.pack_item_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             packitem_breakout p,
             loc_traits_matrix ltm
       where p.pack_no = h.item
         and p.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = ltm.store
         and d.to_loc_type = 'S'
         and ltm.loc_trait = I_group_id
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   cursor C_GET_ALLOC_IN_PACK_PZGS is
      select nvl(sum(p.pack_item_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
        from alloc_detail d,
             alloc_header h,
             ordhead o,
             packitem_breakout p,
             price_zone_group_store pzgs
       where p.pack_no = h.item
         and p.item = I_item
         and d.alloc_no = h.alloc_no
         and o.status in ('A', 'C')
         and h.status in ('A', 'R')
         and h.order_no = o.order_no
         and d.qty_allocated > nvl(d.qty_transferred,0)
         and nvl(I_date, o.not_before_date) >= o.not_before_date
         and d.to_loc = pzgs.store
         and pzgs.zone_id = I_group_id
         and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N');

   BEGIN
      ---
      if I_group_type = 'PW' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_PWH',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         open C_GET_ALLOC_IN_ITEM_PWH;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_PWH',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         fetch C_GET_ALLOC_IN_ITEM_PWH into L_alloc_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_PWH',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         close C_GET_ALLOC_IN_ITEM_PWH;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_PWH',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         open C_GET_ALLOC_IN_PACK_PWH;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_PWH',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         fetch C_GET_ALLOC_IN_PACK_PWH into L_alloc_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_PWH',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         close C_GET_ALLOC_IN_PACK_PWH;
         ---
      elsif I_group_type in ('A','R','D','AS', 'C', 'DW', 'S', 'T', 'P') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_STS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         open C_GET_ALLOC_IN_ITEM_STS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_STS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         fetch C_GET_ALLOC_IN_ITEM_STS into L_alloc_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_STS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         close C_GET_ALLOC_IN_ITEM_STS;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_STS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         open C_GET_ALLOC_IN_PACK_STS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_STS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         fetch C_GET_ALLOC_IN_PACK_STS into L_alloc_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_STS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         close C_GET_ALLOC_IN_PACK_STS;
         ---
      elsif I_group_type in ('LLW', 'LLS') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_LOCLST',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         open C_GET_ALLOC_IN_ITEM_LOCLST;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_LOCLST',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         fetch C_GET_ALLOC_IN_ITEM_LOCLST into L_alloc_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_LOCLST',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         close C_GET_ALLOC_IN_ITEM_LOCLST;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_LOCLST',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         open C_GET_ALLOC_IN_PACK_LOCLST;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_LOCLST',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         fetch C_GET_ALLOC_IN_PACK_LOCLST into L_alloc_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_LOCLST',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         close C_GET_ALLOC_IN_PACK_LOCLST;
         ---
      elsif I_group_type = 'L' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_LOCTRAIT',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         open C_GET_ALLOC_IN_ITEM_LOCTRAIT;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_LOCTRAIT',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         fetch C_GET_ALLOC_IN_ITEM_LOCTRAIT into L_alloc_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_LOCTRAIT',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         close C_GET_ALLOC_IN_ITEM_LOCTRAIT;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_LOCTRAIT',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         open C_GET_ALLOC_IN_PACK_LOCTRAIT;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_LOCTRAIT',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         fetch C_GET_ALLOC_IN_PACK_LOCTRAIT into L_alloc_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_LOCTRAIT',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         close C_GET_ALLOC_IN_PACK_LOCTRAIT;
         ---
      elsif I_group_type = 'Z' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_PZGS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         open C_GET_ALLOC_IN_ITEM_PZGS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_PZGS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         fetch C_GET_ALLOC_IN_ITEM_PZGS into L_alloc_item_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_PZGS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD', 'item:  '||I_item);
         close C_GET_ALLOC_IN_ITEM_PZGS;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_PZGS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         open C_GET_ALLOC_IN_PACK_PZGS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_PZGS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         fetch C_GET_ALLOC_IN_PACK_PZGS into L_alloc_pack_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_PZGS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT',
                          'item:  '||I_item);
         close C_GET_ALLOC_IN_PACK_PZGS;
         ---
      end if;
      ---
      O_quantity := L_alloc_item_qty + L_alloc_pack_qty;
      ---

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
      return FALSE;
   END ALLOC_QUANTITY_GROUP;
   ---

   FUNCTION ITEM_PARENT_QTY_GROUP(I_item_parent IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                                  O_total_qty   IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE )
   RETURN BOOLEAN IS

      L_item_alloc_qty       ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_alloc_qty       ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

      cursor C_GET_ALLOC_IN_ITEM_PWH is
         select nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                wh,
                item_master im
          where d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and im.item = h.item
            and d.to_loc = wh.wh
            and d.to_loc_type = 'W'
            and wh.physical_wh = I_group_id
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_GET_ALLOC_IN_PACK_PWH is
         select nvl(sum(p.pack_item_qty * (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                wh,
                packitem_breakout p,
                item_master im
          where d.to_loc = wh.wh
            and d.to_loc_type = 'W'
            and wh.physical_wh = I_group_id
            and d.alloc_no = h.alloc_no
            and o.status  in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

      cursor C_GET_ALLOC_IN_ITEM_STS is
         select nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                store_hierarchy sh,
                store s,
                item_master im
          where d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and im.item = h.item
            and d.to_loc = s.store
            and s.store = sh.store
            and ((I_group_type = 'A' and sh.area = I_group_id)
                 or (I_group_type = 'R' and sh.region = I_group_id)
                 or (I_group_type = 'D' and sh.district = I_group_id)
                 or (I_group_type = 'C' and s.store_class = I_group_id)
                 or (I_group_type = 'T' and s.transfer_zone = I_group_id)
                 or (I_group_type = 'DW' and s.default_wh = I_group_id))
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_GET_ALLOC_IN_PACK_STS is
         select nvl(sum(p.pack_item_qty * (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                store_hierarchy sh,
                store s,
                packitem_breakout p,
                item_master im
          where d.to_loc = s.store
            and s.store = sh.store
            and ((I_group_type = 'A' and sh.area = I_group_id)
                 or (I_group_type = 'R' and sh.region = I_group_id)
                 or (I_group_type = 'D' and sh.district = I_group_id)
                 or (I_group_type = 'C' and s.store_class = I_group_id)
                 or (I_group_type = 'T' and s.transfer_zone = I_group_id)
                 or (I_group_type = 'DW' and s.default_wh = I_group_id))
            and d.alloc_no = h.alloc_no
            and o.status  in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

      cursor C_GET_ALLOC_IN_ITEM_LOCLST is
         select nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                loc_list_detail lld,
                item_master im
          where d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and im.item = h.item
            and d.to_loc = lld.location
            and d.to_loc_type = lld.loc_type
            and ((lld.loc_type = 'W' and I_group_type = 'LLW')
                 or (lld.loc_type = 'S' and I_group_type = 'LLS'))
            and lld.loc_list = I_group_id
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_GET_ALLOC_IN_PACK_LOCLST is
         select nvl(sum(p.pack_item_qty * (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                loc_list_detail lld,
                packitem_breakout p,
                item_master im
          where d.to_loc = lld.location
            and d.to_loc_type = lld.loc_type
            and ((lld.loc_type = 'W' and I_group_type = 'LLW')
                 or (lld.loc_type = 'S' and I_group_type = 'LLS'))
            and lld.loc_list = I_group_id
            and d.alloc_no = h.alloc_no
            and o.status  in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

      cursor C_GET_ALLOC_IN_ITEM_LOCTRAIT is
         select nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                loc_traits_matrix ltm,
                item_master im
          where d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and im.item = h.item
            and d.to_loc = ltm.store
            and d.to_loc_type = 'S'
            and ltm.loc_trait = I_group_id
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_GET_ALLOC_IN_PACK_LOCTRAIT is
         select nvl(sum(p.pack_item_qty * (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                loc_traits_matrix ltm,
                packitem_breakout p,
                item_master im
          where d.to_loc = ltm.store
            and d.to_loc_type = 'S'
            and ltm.loc_trait = I_group_id
            and d.alloc_no = h.alloc_no
            and o.status  in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;

      cursor C_GET_ALLOC_IN_ITEM_PZGS is
         select nvl(sum(d.qty_allocated - nvl(d.qty_transferred,0)),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                price_zone_group_store pzgs,
                item_master im
          where d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and im.item = h.item
            and d.to_loc = pzgs.store
            and pzgs.zone_id = I_group_id
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level;

      cursor C_GET_ALLOC_IN_PACK_PZGS is
         select nvl(sum(p.pack_item_qty * (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                price_zone_group_store pzgs,
                packitem_breakout p,
                item_master im
          where d.to_loc = pzgs.store
            and pzgs.zone_id = I_group_id
            and d.alloc_no = h.alloc_no
            and o.status  in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and (im.item_parent = I_item_parent or im.item_grandparent = I_item_parent)
            and im.item_level = im.tran_level
            and im.item = p.item;
   BEGIN
      ---
      if I_group_type = 'PW' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_PWH', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_ITEM_PWH;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_PWH', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_ITEM_PWH into L_item_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_PWH', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_ITEM_PWH;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_PWH', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_PACK_PWH;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_PWH', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_PACK_PWH into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_PWH', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_PACK_PWH;
         ---
      elsif I_group_type in ('A','R','D','AS', 'C', 'DW', 'S', 'T', 'P') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_STS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_ITEM_STS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_STS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_ITEM_STS into L_item_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_STS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_ITEM_STS;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_STS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_PACK_STS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_STS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_PACK_STS into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_STS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_PACK_STS;
         ---
      elsif I_group_type in ('LLW', 'LLS') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_LOCLST', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_ITEM_LOCLST;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_LOCLST', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_ITEM_LOCLST into L_item_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_LOCLST', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_ITEM_LOCLST;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_LOCLST', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_PACK_LOCLST;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_LOCLST', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_PACK_LOCLST into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_LOCLST', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_PACK_LOCLST;
         ---
      elsif I_group_type = 'L' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_LOCTRAIT', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_ITEM_LOCTRAIT;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_LOCTRAIT', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_ITEM_LOCTRAIT into L_item_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_LOCTRAIT', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_ITEM_LOCTRAIT;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_LOCTRAIT', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_PACK_LOCTRAIT;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_LOCTRAIT', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_PACK_LOCTRAIT into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_LOCTRAIT', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_PACK_LOCTRAIT;
         ---
      elsif I_group_type = 'Z' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_ITEM_PZGS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_ITEM_PZGS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_ITEM_PZGS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_ITEM_PZGS into L_item_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_ITEM_PZGS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_ITEM_PZGS;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_ALLOC_IN_PACK_PZGS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         open C_GET_ALLOC_IN_PACK_PZGS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_ALLOC_IN_PACK_PZGS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         fetch C_GET_ALLOC_IN_PACK_PZGS into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_ALLOC_IN_PACK_PZGS', 'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM_BREAKOUT, ITEM_MASTER', 'item parent:  '||I_item_parent||' or '||'item grandparent:  '||I_item_parent);
         close C_GET_ALLOC_IN_PACK_PZGS;
         ---
      end if;
      ---
      O_total_qty := L_item_alloc_qty + L_pack_alloc_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
         return FALSE;
   END ITEM_PARENT_QTY_GROUP;
   ---
   FUNCTION PACK_AND_ITEM_QTY_GROUP(I_item         IN     ITEM_LOC.ITEM%TYPE,
                                    O_total_qty    IN OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE)
   RETURN BOOLEAN IS

      L_item_alloc_qty          ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
      L_pack_alloc_qty          ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;


      cursor C_GET_PACK_ALLOC_IN_PWH is
         select nvl(sum(p.pack_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                wh,
                packitem p
          where d.to_loc = wh.wh
            and d.to_loc_type = 'W'
            and wh.physical_wh = I_group_id
            and d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and p.item = I_item;

      cursor C_GET_PACK_ALLOC_IN_STS is
         select nvl(sum(p.pack_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                store_hierarchy sh,
                store s,
                packitem p
          where d.to_loc = s.store
            and s.store = sh.store
            and ((I_group_type = 'A' and sh.area = I_group_id)
                 or (I_group_type = 'R' and sh.region = I_group_id)
                 or (I_group_type = 'D' and sh.district = I_group_id)
                 or (I_group_type = 'C' and s.store_class = I_group_id)
                 or (I_group_type = 'T' and s.transfer_zone = I_group_id)
                 or (I_group_type = 'DW' and s.default_wh = I_group_id))
            and d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and p.item = I_item;

      cursor C_GET_PACK_ALLOC_IN_LOCLST is
         select nvl(sum(p.pack_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                loc_list_detail lld,
                packitem p
          where d.to_loc = lld.location
            and d.to_loc_type = lld.loc_type
            and ((lld.loc_type = 'W' and I_group_type = 'LLW')
                 or (lld.loc_type = 'S' and I_group_type = 'LLS'))
            and lld.loc_list = I_group_id
            and d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and p.item = I_item;

      cursor C_GET_PACK_ALLOC_IN_LOCTRAIT is
         select nvl(sum(p.pack_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                loc_traits_matrix ltm,
                packitem p
          where d.to_loc = ltm.store
            and d.to_loc_type = 'S'
            and ltm.loc_trait = I_group_id
            and d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and p.item = I_item;

      cursor C_GET_PACK_ALLOC_IN_PZGS is
         select nvl(sum(p.pack_qty *
                    (d.qty_allocated - nvl(d.qty_transferred,0))),0)
           from alloc_detail d,
                alloc_header h,
                ordhead o,
                price_zone_group_store pzgs,
                packitem p
          where d.to_loc = pzgs.store
            and pzgs.zone_id = I_group_id
            and d.alloc_no = h.alloc_no
            and o.status in ('A', 'C')
            and h.status in ('A', 'R')
            and h.order_no = o.order_no
            and d.qty_allocated > nvl(d.qty_transferred,0)
            and nvl(I_date, o.not_before_date)
                     >= o.not_before_date
            and NOT (I_all_orders = 'N' and o.include_on_order_ind = 'N')
            and h.item = p.pack_no
            and p.item = I_item;

   BEGIN
      ---
      if not ALLOC_QUANTITY_GROUP(I_item,
                                  L_item_alloc_qty ) then
         return FALSE;
      end if;
      ---
      if I_group_type = 'PW' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_PACK_ALLOC_IN_PWH',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         open C_GET_PACK_ALLOC_IN_PWH;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_PACK_ALLOC_IN_PWH',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         fetch C_GET_PACK_ALLOC_IN_PWH into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_PACK_ALLOC_IN_PWH',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         close C_GET_PACK_ALLOC_IN_PWH;
         ---
      elsif I_group_type in ('A','R','D','AS', 'C', 'DW', 'S', 'T', 'P') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_PACK_ALLOC_IN_STS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         open C_GET_PACK_ALLOC_IN_STS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_PACK_ALLOC_IN_STS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         fetch C_GET_PACK_ALLOC_IN_STS into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_PACK_ALLOC_IN_STS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         close C_GET_PACK_ALLOC_IN_STS;
         ---
      elsif I_group_type in ('LLW', 'LLS') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_PACK_ALLOC_IN_LOCLST',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         open C_GET_PACK_ALLOC_IN_LOCLST;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_PACK_ALLOC_IN_LOCLST',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         fetch C_GET_PACK_ALLOC_IN_LOCLST into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_PACK_ALLOC_IN_LOCLST',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         close C_GET_PACK_ALLOC_IN_LOCLST;
         ---
      elsif I_group_type = 'L' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_PACK_ALLOC_IN_LOCTRAIT',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         open C_GET_PACK_ALLOC_IN_LOCTRAIT;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_PACK_ALLOC_IN_LOCTRAIT',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         fetch C_GET_PACK_ALLOC_IN_LOCTRAIT into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_PACK_ALLOC_IN_LOCTRAIT',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         close C_GET_PACK_ALLOC_IN_LOCTRAIT;
         ---
      elsif I_group_type = 'Z' then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_PACK_ALLOC_IN_PZGS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         open C_GET_PACK_ALLOC_IN_PZGS;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_PACK_ALLOC_IN_PZGS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         fetch C_GET_PACK_ALLOC_IN_PZGS into L_pack_alloc_qty;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_PACK_ALLOC_IN_PZGS',
                          'ALLOC_DETAIL, ALLOC_HEADER, ORDHEAD, PACKITEM', 'item:  '||I_item);
         close C_GET_PACK_ALLOC_IN_PZGS;
         ---
      end if;
      ---
      O_total_qty := L_item_alloc_qty + L_pack_alloc_qty;

      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END PACK_AND_ITEM_QTY_GROUP;
   ---

BEGIN
   ---
   -- Finishers won't be applied to Allocations, so the total stock on order allocations is
   -- always zero.
   ---
   if I_group_type in ('I', 'E', 'AI', 'AE') then
      O_quantity := 0;
      return TRUE;
   end if;
   ---
   if I_group_type in ('S', 'W', 'AL', 'AS', 'AW') then
      ---
      if I_group_type in ('S', 'W') then
         ---
         L_loc := I_group_id;
         L_loc_type := I_group_type;
         ---
      elsif I_group_type = 'AS' then
         ---
         L_loc_type := 'S';
         ---
      elsif I_group_type = 'AW' then
         ---
         L_loc_type := 'W';
         ---
      end if;
      ---
      if GET_ALLOC_IN(I_item,
                      L_loc,
                      L_loc_type,
                      I_date,
                      I_all_orders,
                      O_quantity,
                      O_error_message) = FALSE then
         return FALSE;
      end if;
      ---
   else
      ---
      if (LP_item != I_item or LP_item is NULL) then
         ---
         LP_item := I_item;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
         open C_ITEM_INFO;
         SQL_LIB.SET_MARK('FETCH', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
         fetch C_ITEM_INFO into LP_pack_ind,
                                LP_item_level,
                                LP_tran_level;
         SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_INFO', 'ITEM_MASTER', 'item:  '||I_item);
         close C_ITEM_INFO;
         ---
      end if;
      ---
      if LP_item_level < LP_tran_level then
         if not ITEM_PARENT_QTY_GROUP(I_item,
                                      O_quantity ) then
            return FALSE;
         end if;

      elsif LP_item_level = LP_tran_level then
         if LP_pack_ind = 'Y' then
            if not PACK_AND_ITEM_QTY_GROUP(I_item,
                                           O_quantity ) then
               return FALSE;
            end if;
         else  --LP_pack_ind = 'N'
            if not ALLOC_QUANTITY_GROUP(I_item,
                                        O_quantity ) then
               return FALSE;
            end if;
         end if;
      end if;
      ---
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ALLOC_IN_GROUP;
---------------------------------------------------------------------------------------
END ITEMLOC_QUANTITY_SQL;
/

