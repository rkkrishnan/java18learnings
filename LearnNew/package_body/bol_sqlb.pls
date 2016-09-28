CREATE OR REPLACE PACKAGE BODY BOL_SQL AS
-----------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Karthik Dhanapal, karthik.dhanapal@wipro.com
--Mod Date:    17-Mar-2008
--Mod Ref:     NBS00004699.
--Mod Details: Back ported the oracle fix for  Bugs 6371616(v12.0.6) to 12.0.5.2 code.
--             Modified the function LOAD_INV_FLOW_LOC,added four cursors (Removed the cursors C_GET_VWH,C_MAP_WH and added
--             the new cursors C_GET_VWH_4,C_GET_VWH_1,C_GET_VWH_2,C_GET_VWH_3) to select the correct warehouse depending on
--             the system_options intercompany_transfer_ind and financial_ap flags.If no matching virtual warehouse is found
--             then the stock will taken from primary virtual warehouse.
-----------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Karthik Dhanapal, karthik.dhanapal@wipro.com
--Mod Date:    16-May-2008
--Mod Ref:     NBS00006616.
--Mod Details: Changed for NBS00006616.
-----------------------------------------------------------------------------------------------------
--Mod By:      Satish B.N, satish.narasimhaiah@in.tesco.com
--Mod Date:    26-May-2008
--Mod Ref:     NBS00006565.
--Mod Details: Back ported the oracle fix for  Bugs 6658242(v12.0.1.15) to 12.0.5.2 code.
--             Modified the function SEND_TSF , initialized the parameters to NULL , in case if the item is other
--             than catch weight items to avoid to carry over the previously calculated values
-----------------------------------------------------------------------------------------------------
--Mod By:      Murali Krishnan
--Mod Date:    21-Oct-2008
--Mod Ref:     Back Port Oracle fix(6907185)
--Mod Details: Back ported the oracle fix for Bug 6907185.Modified the functions PUT_ALLOC_ITEM,UPD_TO_ITEM_LOC,
--             UPDATE_PACK_LOCS.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 06-Jan-2009
-- Def Ref    : PrfNBS010460 and NBS00010460
-- Def Details: Code has modified for performance related issues in RIB.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 20-Jan-2009
-- Def Details: Merging of 3.3a and 3.3b.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Nandini M, Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 10-Aug-2009
-- Mod Ref    : CR236
-- Def Details: Modified the functions PUT_TSF and PUT_TSF_ITEM to handle Inter company Transfer.
-----------------------------------------------------------------------------------------------------
---Mod By      : Reshma Koshy,Reshma.Koshy@in.tesco.com
---Mod Date    : 06-Jan-2010
---Def Ref     : NBS00015819
---Def Details : Modified the CREATE_TSF function to avoid populating transfers_pub_info table when
--               Transfers are created from the external systems.
-------------------------------------------------------------------------------------------------------
---Mod By      : Usha Patil, usha.patil@in.tesco.com
---Mod Date    : 18-Feb-2010
---Def Ref     : NBS00015820
---Def Details : Modified the functuions UPD_TO_ITEM_LOC, UPDATE_PACK_LOCS to populate correct IN_TRANSIT_QTY,
--               PACK_COMP_INTRAN.(Production Fix has been applied - Defect Id NBS00016198).
-------------------------------------------------------------------------------------------------------
---Mod By      : Reshma Koshy,Reshma.Koshy@in.tesco.com
---Mod Date    : 13-Mar-2010
---Def Ref     : NBS00016111
---Def Details : Modified the PUT_TSF function to to pass virtual warehouse numbers as output parameters
-------------------------------------------------------------------------------------------------------
---Mod By      : Usha Patil, usha.patil@in.tesco.com
---Mod Date    : 14-Apr-2010
---Mod Ref     : NBS00016111
---Mod Details : Modified the PUT_TSF function to pass VWH to CREATE_TSF() for IC transfers.
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Mod By      : Nandini Mariyappa, nandini.mariyappa@in.tesco.com
-- Mod Date    : 18-Oct-2011
-- Mod Ref     : PrfNBS023626
---Mod Details : Modified the Select cursor in the WRITE_ISSUES.
-------------------------------------------------------------------------------------------------------
--globals
  LP_vdate                    period.vdate%TYPE := get_vdate;
  LP_user                     varchar2(50)      := user;
  LP_dept_level_transfers     system_options.dept_level_transfers%TYPE := NULL;
  LP_bol_rec                  bol_sql.bol_rec;
  LP_receipt_ind              VARCHAR2(1)       := 'N';

--used for internal sequence number generator (counts items across multi distros)
  LP_ss_seq_no                shipsku.seq_no%TYPE := NULL;

--SHIPSKU BULK--
   TYPE ss_shipment_TBL            is table of shipsku.shipment%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_seq_no_TBL              is table of shipsku.seq_no%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_item_TBL                is table of shipsku.item%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_distro_no_TBL           is table of shipsku.distro_no%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_distro_type_TBL         is table of shipsku.distro_type%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_ref_item_TBL            is table of shipsku.ref_item%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_carton_TBL              is table of shipsku.carton%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_inv_status_TBL          is table of shipsku.inv_status%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_qty_received_TBL        is table of shipsku.qty_received%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_unit_cost_TBL           is table of shipsku.unit_cost%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_unit_retail_TBL         is table of shipsku.unit_retail%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_qty_expected_TBL        is table of shipsku.qty_expected%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_weight_expected_TBL     is table of shipsku.weight_expected%TYPE INDEX BY BINARY_INTEGER;
   TYPE ss_weight_expected_uom_TBL is table of shipsku.weight_expected_uom%TYPE INDEX BY BINARY_INTEGER;

   ------
   P_ss_shipment              ss_shipment_TBL;
   P_ss_seq_no                ss_seq_no_TBL;
   P_ss_item                  ss_item_TBL;
   P_ss_distro_no             ss_distro_no_TBL;
   P_ss_distro_type           ss_distro_type_TBL;
   P_ss_ref_item              ss_ref_item_TBL;
   P_ss_carton                ss_carton_TBL;
   P_ss_inv_status            ss_inv_status_TBL;
   P_ss_qty_received          ss_qty_received_TBL;
   P_ss_unit_cost             ss_unit_cost_TBL;
   P_ss_unit_retail           ss_unit_retail_TBL;
   P_ss_qty_expected          ss_qty_expected_TBL;
   P_ss_weight_expected       ss_weight_expected_TBL;
   P_ss_weight_expected_uom   ss_weight_expected_uom_TBL;
   P_ss_size                  BINARY_INTEGER := 0;

--ITEM_LOC_HIST BULK--
   TYPE ilh_item_TBL                  is table of item_loc_hist.item%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_loc_TBL                   is table of item_loc_hist.loc%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_loc_type_TBL              is table of item_loc_hist.loc_type%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_eow_date_TBL              is table of item_loc_hist.eow_date%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_week_454_TBL              is table of item_loc_hist.week_454%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_month_454_TBL             is table of item_loc_hist.month_454%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_year_454_TBL              is table of item_loc_hist.year_454%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_sales_type_TBL            is table of item_loc_hist.sales_type%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_sales_issues_TBL          is table of item_loc_hist.sales_issues%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_create_datetime_TBL       is table of item_loc_hist.create_datetime%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_last_update_datetime_TBL  is table of item_loc_hist.last_update_datetime%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_last_update_id_TBL        is table of item_loc_hist.last_update_id%TYPE INDEX BY BINARY_INTEGER;
   TYPE ilh_rowid_TBL                 is table of ROWID INDEX BY BINARY_INTEGER;
   ------
   P_ilh_item                   ilh_item_TBL;
   P_ilh_loc                    ilh_loc_TBL;
   P_ilh_loc_type               ilh_loc_type_TBL;
   P_ilh_eow_date               ilh_eow_date_TBL;
   P_ilh_week_454               ilh_week_454_TBL;
   P_ilh_month_454              ilh_month_454_TBL;
   P_ilh_year_454               ilh_year_454_TBL;
   P_ilh_sales_type             ilh_sales_type_TBL;
   P_ilh_sales_issues           ilh_sales_issues_TBL;
   P_ilh_create_datetime        ilh_create_datetime_TBL;
   P_ilh_last_update_datetime   ilh_last_update_datetime_TBL;
   P_ilh_last_update_id         ilh_last_update_id_TBL;
   P_ilh_size                   BINARY_INTEGER := 0;
   ------
   P_upd_ilh_sales_issues       ilh_sales_issues_TBL;
   P_upd_ilh_rowid_TBL          ilh_rowid_TBL;
   P_upd_ilh_size               BINARY_INTEGER := 0;

-------------------------------------------------------------------------------
--FUNCTION PROTOTYPES--
-----------------------

FUNCTION CREATE_TSF(O_error_message     IN OUT rtk_errors.rtk_text%TYPE,
                    I_tsf_no            IN     tsfhead.tsf_no%TYPE,
                    I_tsf_type          IN     tsfhead.tsf_type%TYPE,
                    I_phy_from_loc      IN     item_loc.loc%TYPE,
                    I_from_loc_type     IN     item_loc.loc_type%TYPE,
                    I_phy_to_loc        IN     item_loc.loc%TYPE,
                    I_to_loc_type       IN     item_loc.loc_type%TYPE,
                    I_tran_date         IN     period.vdate%TYPE,
                    I_comment_desc      IN     tsfhead.comment_desc%TYPE)
RETURN BOOLEAN;

FUNCTION NEW_LOC(O_error_message  IN OUT rtk_errors.rtk_text%TYPE,
                 I_item           IN     item_master.item%TYPE,
                 I_pack_ind       IN     item_master.pack_ind%TYPE,
                 I_dept           IN     item_master.dept%TYPE,
                 I_class          IN     item_master.class%TYPE,
                 I_subclass       IN     item_master.subclass%TYPE,
                 I_loc            IN     item_loc.loc%TYPE,
                 I_loc_type       IN     item_loc.loc_type%TYPE)
RETURN BOOLEAN;

FUNCTION ITEM_CHECK(O_error_message    IN OUT rtk_errors.rtk_text%TYPE,
                    O_tran_item        IN OUT item_master.item%TYPE,
                    O_ref_item         IN OUT item_master.item%TYPE,
                    O_dept             IN OUT item_master.dept%TYPE,
                    O_class            IN OUT item_master.class%TYPE,
                    O_subclass         IN OUT item_master.subclass%TYPE,
                    O_pack_ind         IN OUT item_master.pack_ind%TYPE,
                    O_pack_type        IN OUT item_master.pack_type%TYPE,
                    O_simple_pack_ind  IN OUT item_master.simple_pack_ind%TYPE,
                    O_catch_weight_ind IN OUT item_master.catch_weight_ind%TYPE,
                    O_sellable_ind     IN OUT item_master.item_xform_ind%TYPE,
                    O_item_xform_ind   IN OUT item_master.item_xform_ind%TYPE,
                    O_supp_pack_size   IN OUT item_supp_country.supp_pack_size%TYPE,
                    O_ss_seq_no        IN OUT shipsku.seq_no%TYPE,
                    I_input_item       IN     item_master.item%TYPE)
RETURN BOOLEAN;

FUNCTION INS_TSFDETAIL(O_error_message     IN OUT rtk_errors.rtk_text%TYPE,
                       O_tsf_seq_no        IN OUT tsfdetail.tsf_seq_no%TYPE,
                       I_tsf_no            IN     tsfhead.tsf_no%TYPE,
                       I_item              IN     item_master.item%TYPE,
                       I_supp_pack_size    IN     item_supp_country.supp_pack_size%TYPE,
                       I_inv_status        IN     tsfdetail.inv_status%TYPE,
                       I_tsf_qty           IN     tsfdetail.tsf_qty%TYPE)
RETURN BOOLEAN;

FUNCTION CREATE_TSF_INV_MAP(O_error_message IN OUT rtk_errors.rtk_text%TYPE,
                            I_tsf_no        IN     tsfhead.tsf_no%TYPE,
                            I_item          IN     item_master.item%TYPE,
                            I_pack_ind      IN     item_master.pack_ind%TYPE,
                            I_inv_status    IN     shipsku.inv_status%TYPE,
                            I_tsf_seq_no    IN     tsfdetail.tsf_seq_no%TYPE,
                            I_phy_from_loc  IN     item_loc.loc%TYPE,
                            I_from_loc_type IN     item_loc.loc_type%TYPE,
                            I_phy_to_loc    IN     item_loc.loc%TYPE,
                            I_to_loc_type   IN     item_loc.loc_type%TYPE,
                            I_tsf_qty       IN     item_loc_soh.stock_on_hand%TYPE)
RETURN BOOLEAN;

FUNCTION LOAD_INV_FLOW_LOC(O_error_message  IN OUT rtk_errors.rtk_text%TYPE,
                           O_inv_flow_array IN OUT bol_sql.inv_flow_array,
                           I_to_from_ind    IN     VARCHAR2,
                           I_phy_loc        IN     item_loc.loc%TYPE,
                           I_loc_type       IN     item_loc.loc_type%TYPE,
                           I_other_loc      IN     item_loc.loc%TYPE,
                           I_other_loc_type IN     item_loc.loc_type%TYPE,
                           I_item           IN     item_master.item%TYPE,
                           I_pack_ind       IN     ITEM_MASTER.PACK_IND%TYPE)
RETURN BOOLEAN;


FUNCTION DIST_FROM_LOC(O_error_message  IN OUT rtk_errors.rtk_text%TYPE,
                       I_inv_flow_array IN OUT bol_sql.inv_flow_array,
                       I_item           IN     item_master.item%TYPE,
                       I_inv_status     IN     shipsku.inv_status%TYPE,
                       I_tsf_qty        IN     item_loc_soh.stock_on_hand%TYPE,
                       I_phy_to_loc     IN     item_loc.loc%TYPE,
                       I_to_loc_type    IN     item_loc.loc_type%TYPE,
                       I_phy_from_loc   IN     item_loc.loc%TYPE,
                       I_from_loc_type  IN     item_loc.loc_type%TYPE)
RETURN BOOLEAN;

FUNCTION INS_TSF_INV_FLOW(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN;

FUNCTION FIND_MAP(O_error_message IN OUT rtk_errors.rtk_text%TYPE,
                  O_keepgoing     IN OUT BOOLEAN,
                  I_from_loc      IN     item_loc.loc%TYPE,
                  I_from_loc_type IN     item_loc.loc_type%TYPE,
                  I_qty           IN     item_loc_soh.stock_on_hand%TYPE,
                  I_status        IN     item_loc.status%TYPE,
                  I_channel_id    IN     channels.channel_id%TYPE,
                  I_channel_type  IN     channels.channel_type%TYPE,
                  I_to_array      IN     bol_sql.inv_flow_array)
RETURN BOOLEAN;

FUNCTION PUT_TSF_INV_MAP(O_error_message   IN OUT rtk_errors.rtk_text%TYPE,
                         I_from_loc        IN     item_loc.loc%TYPE,
                         I_from_loc_type   IN     item_loc.loc_type%TYPE,
                         I_to_loc          IN     item_loc.loc%TYPE,
                         I_to_loc_type     IN     item_loc.loc_type%TYPE,
                         I_receive_as_type IN     item_loc.receive_as_type%TYPE,
                         I_tsf_qty         IN     tsfdetail.tsf_qty%TYPE)
RETURN BOOLEAN;

FUNCTION SEND_TSF(O_error_message IN OUT rtk_errors.rtk_text%TYPE,
                  I_bol_no        IN     shipment.bol_no%TYPE,
                  I_tsf_no        IN     tsfhead.tsf_no%TYPE,
                  I_tsf_type      IN     tsfhead.tsf_type%TYPE,
                  I_del_type      IN     ordcust.deliver_type%TYPE,
                  I_new_tsf       IN     VARCHAR2,
                  I_tsf_to_loc    IN     item_loc.loc%TYPE,
                  I_tsf_status    IN     tsfhead.status%TYPE,
                  I_tran_date     IN     period.vdate%TYPE,
                  I_ship_no       IN     shipment.shipment%TYPE,
                  I_eow_date      IN     period.vdate%TYPE,
                  I_bol_items     IN     bol_sql.bol_item_array)
return BOOLEAN;

--------------------------------------------------------------------------------------
--  Name   : GET_COSTS_AND_RETAILS
--  Purpose: The function will get the costs for the from loc.  If the from loc is an
--           external finisher the retail will be retreived for the to location.  Otherwise,
--           the from location's retail will be returned.
--------------------------------------------------------------------------------------
FUNCTION GET_COSTS_AND_RETAILS(O_error_message         IN OUT rtk_errors.rtk_text%TYPE,
                               O_av_cost               IN OUT item_loc_soh.av_cost%TYPE,
                               O_unit_retail           IN OUT item_loc.unit_retail%TYPE,
                               I_item                  IN     item_master.item%TYPE,
                               I_pack_ind              IN     VARCHAR2,
                               I_sellable_ind          IN     item_master.sellable_ind%TYPE,
                               I_item_xform_ind        IN     item_master.item_xform_ind%TYPE,
                               I_from_loc              IN     item_loc.loc%TYPE,
                               I_from_loc_type         IN     item_loc.loc_type%TYPE,
                               I_to_loc                IN     item_loc.loc%TYPE,
                               I_to_loc_type           IN     item_loc.loc_type%TYPE)

RETURN BOOLEAN;

FUNCTION SEND_ALLOC(O_error_message    IN OUT rtk_errors.rtk_text%TYPE,
                    I_alloc_no         IN     alloc_header.alloc_no%TYPE,
                    I_alloc_status     IN     alloc_header.status%TYPE,
                    I_alloc_type       IN     VARCHAR2,
                    I_new_ad_ind       IN     VARCHAR2,
                    I_ship_no          IN     shipment.shipment%TYPE,
                    I_ss_seq_no        IN     shipsku.seq_no%TYPE,
                    I_item             IN     item_master.item%TYPE,
                    I_ref_item         IN     item_master.item%TYPE,
                    I_pack_ind         IN     item_master.pack_ind%TYPE,
                    I_pack_type        IN     item_master.pack_type%TYPE,
                    I_dept             IN     item_master.dept%TYPE,
                    I_class            IN     item_master.class%TYPE,
                    I_subclass         IN     item_master.subclass%TYPE,
                    I_carton           IN     shipsku.carton%TYPE,
                    I_inv_status       IN     shipsku.inv_status%TYPE,
                    I_qty              IN     item_loc_soh.stock_on_hand%TYPE,
                    I_simple_pack_ind  IN     item_master.simple_pack_ind%TYPE,
                    I_catch_weight_ind IN     item_master.catch_weight_ind%TYPE,
                    I_weight           IN     item_loc_soh.average_weight%TYPE,
                    I_weight_uom       IN     uom_class.uom%TYPE,
                    I_sellable_ind     IN     item_master.sellable_ind%TYPE,
                    I_item_xform_ind   IN     item_master.item_xform_ind%TYPE,
                    I_ad_alloc_qty     IN     item_loc_soh.stock_on_hand%TYPE,
                    I_ad_tsf_qty       IN     item_loc_soh.stock_on_hand%TYPE,
                    I_from_loc         IN     item_loc.loc%TYPE,
                    I_from_loc_type    IN     item_loc.loc_type%TYPE,
                    I_to_loc           IN     item_loc.loc%TYPE,
                    I_to_loc_type      IN     item_loc.loc_type%TYPE,
                    I_tran_date        IN     period.vdate%TYPE,
                    I_eow_date         IN     period.vdate%TYPE)
RETURN BOOLEAN;

FUNCTION INS_SHIPSKU(O_error_message  IN OUT VARCHAR2,
                     I_shipment       IN     shipment.shipment%TYPE,
                     I_seq_no         IN     shipsku.seq_no%TYPE,
                     I_item           IN     item_master.item%TYPE,
                     I_ref_item       IN     item_master.item%TYPE,
                     I_distro_no      IN     shipsku.distro_no%TYPE,
                     I_distro_type    IN     shipsku.distro_type%TYPE,
                     I_carton         IN     shipsku.carton%TYPE,
                     I_inv_status     IN     shipsku.inv_status%TYPE,
                     I_rcv_qty        IN     shipsku.qty_expected%TYPE,
                     I_cost           IN     shipsku.unit_cost%TYPE,
                     I_retail         IN     shipsku.unit_retail%TYPE,
                     I_exp_qty        IN     shipsku.qty_expected%TYPE,
                     I_exp_weight     IN     shipsku.weight_expected%TYPE,
                     I_exp_weight_uom IN     shipsku.weight_expected_uom%TYPE)
RETURN BOOLEAN;

FUNCTION DEPT_LVL_CHK(O_error_message   IN OUT rtk_errors.rtk_text%TYPE,
                      I_dept            IN     deps.dept%TYPE,
                      I_tsf_no          IN     tsfhead.tsf_no%TYPE)
RETURN BOOLEAN;

FUNCTION UPDATE_INV_STATUS(O_error_message IN OUT VARCHAR2,
                           I_item          IN     item_master.item%TYPE,
                           I_pack_ind      IN     item_master.pack_ind%TYPE,
                           I_from_loc      IN     item_loc.loc%TYPE,
                           I_from_loc_type IN     item_loc.loc_type%TYPE,
                           I_qty           IN     item_loc_soh.stock_on_hand%TYPE,
                           I_inv_status    IN     shipsku.inv_status%TYPE)
RETURN BOOLEAN;

FUNCTION UPD_FROM_ITEM_LOC(O_error_message    IN OUT VARCHAR2,
                           O_from_av_cost     IN OUT item_loc_soh.av_cost%TYPE,
                           O_from_unit_retail IN OUT item_loc_soh.av_cost%TYPE,
                           I_item             IN     item_master.item%TYPE,
                           I_comp_item        IN     VARCHAR2,
                           I_sellable_ind     IN     item_master.sellable_ind%TYPE,
                           I_item_xform_ind   IN     item_master.item_xform_ind%TYPE,
                           I_inventory_ind    IN     item_master.inventory_ind%TYPE,
                           I_from_loc         IN     item_loc.loc%TYPE,
                           I_tsf_qty          IN     item_loc_soh.stock_on_hand%TYPE,
                           I_resv_qty         IN     item_loc_soh.stock_on_hand%TYPE,
                           I_tsf_weight       IN     item_loc_soh.average_weight%TYPE,
                           I_tsf_weight_uom   IN     uom_class.uom%TYPE,
                           I_eow_date         IN     period.vdate%TYPE)
RETURN BOOLEAN;

FUNCTION UPD_TO_ITEM_LOC(O_error_message   IN OUT rtk_errors.rtk_text%TYPE,
                         I_item            IN     item_master.item%TYPE,
                         I_pack_no         IN     item_master.item%TYPE,
                         I_percent_in_pack IN     NUMBER,
                         I_receive_as_type IN     item_loc.receive_as_type%TYPE,
                         I_tsf_type        IN     tsfhead.tsf_type%TYPE,
                         I_to_loc          IN     item_loc.loc%TYPE,
                         I_to_loc_type     IN     item_loc.loc_type%TYPE,
                         I_tsf_qty         IN     item_loc_soh.stock_on_hand%TYPE,
                         I_exp_qty         IN     item_loc_soh.stock_on_hand%TYPE,
                         I_intran_qty      IN     item_loc_soh.stock_on_hand%TYPE,
                         I_weight_cuom     IN     item_loc_soh.average_weight%TYPE,
                         I_cuom            IN     uom_class.uom%TYPE,
                         I_from_loc        IN     item_loc.loc%TYPE,
                         I_from_loc_type   IN     item_loc.loc_type%TYPE,
                         I_from_wac        IN     item_loc_soh.av_cost%TYPE,
                         I_prim_charge     IN     item_loc_soh.av_cost%TYPE,
                         I_distro_no       IN     shipsku.distro_no%TYPE,
                         I_distro_type     IN     shipsku.distro_type%TYPE,
                         I_intercompany    IN     BOOLEAN)
RETURN BOOLEAN;

FUNCTION UPDATE_PACK_LOCS(O_error_message       IN OUT VARCHAR2,
                          I_item                IN     item_master.item%TYPE,
                          I_from_loc            IN     item_loc.loc%TYPE,
                          I_from_loc_type       IN     item_loc.loc_type%TYPE,
                          I_to_loc              IN     item_loc.loc%TYPE,
                          I_to_loc_type         IN     item_loc.loc_type%TYPE,
                          I_to_receive_as_type  IN     item_loc.receive_as_type%TYPE,
                          I_tsf_type            IN     tsfhead.tsf_type%TYPE,
                          I_tsf_qty             IN     item_loc_soh.stock_on_hand%TYPE,
                          I_tsf_weight_cuom     IN     item_loc_soh.average_weight%TYPE,
                          I_intran_qty          IN     item_loc_soh.stock_on_hand%TYPE,
                          I_intran_weight_cuom  IN     item_loc_soh.average_weight%TYPE,
                          I_resv_exp_qty        IN     item_loc_soh.stock_on_hand%TYPE)
RETURN BOOLEAN;

FUNCTION UPD_TSF_ITEM_COST(O_error_message    IN OUT VARCHAR2,
                           I_item             IN     item_master.item%TYPE,
                           I_ship_qty         IN     tsf_item_cost.shipped_qty%TYPE,
                           I_tsf_no           IN     tsfhead.tsf_no%TYPE)
RETURN BOOLEAN;

FUNCTION WRITE_ISSUES(O_error_message   IN OUT VARCHAR2,
                      I_item            IN     item_master.item%TYPE,
                      I_from_wh         IN     item_loc.loc%TYPE,
                      I_transferred_qty IN     tsfdetail.tsf_qty%TYPE,
                      I_eow_date        IN     period.vdate%TYPE)
RETURN BOOLEAN;

FUNCTION NEXT_SS_SEQ_NO(O_error_message IN OUT rtk_errors.rtk_text%TYPE,
                        O_ss_seq_no     IN OUT shipsku.seq_no%TYPE)
RETURN BOOLEAN;

--BULK HELPERS

FUNCTION FLUSH_SHIPSKU_INSERT(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN;

FUNCTION FLUSH_ILH_INSERT(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN;

FUNCTION FLUSH_ILH_UPDATE(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN;

-------------------------------------------------------------------------------
--- This internal function has common code that is used in both PUT_TSF_ITEM
--- and RECEIPT_PUT_TSF_ITEM
-------------------------------------------------------------------------------
FUNCTION TSF_ITEM_COMMON(O_error_message    IN OUT rtk_errors.rtk_text%TYPE,
                         I_tsf_no           IN     tsfhead.tsf_no%TYPE,
                         I_carton           IN     shipsku.carton%TYPE,
                         I_qty              IN     tsfdetail.tsf_qty%TYPE,
                         I_weight           IN     item_loc_soh.average_weight%TYPE,
                         I_weight_uom       IN     uom_class.uom%TYPE,
                         I_phy_from_loc     IN     item_loc.loc%TYPE,
                         I_from_loc_type    IN     item_loc.loc_type%TYPE,
                         I_phy_to_loc       IN     item_loc.loc%TYPE,
                         I_to_loc_type      IN     item_loc.loc_type%TYPE,
                         I_tsfhead_to_loc   IN     item_loc.loc%TYPE,
                         I_tsfhead_from_loc IN     item_loc.loc%TYPE,
                         I_tsf_type         IN     tsfhead.tsf_type%TYPE,
                         I_inv_status       IN     inv_status_codes.inv_status%TYPE,
                         I_tsf_qty          IN     tsfdetail.tsf_qty%TYPE,
                         I_ship_qty         IN     tsfdetail.ship_qty%TYPE,
                         I_tsf_seq_no       IN     tsfdetail.tsf_seq_no%TYPE,
                         I_item_cnt         IN     BINARY_INTEGER,
                         I_dist_cnt         IN     BINARY_INTEGER)
RETURN BOOLEAN;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--public function--
FUNCTION PUT_BOL(O_error_message     IN OUT rtk_errors.rtk_text%TYPE,
                 O_bol_exists        IN OUT BOOLEAN,
                 I_bol_no            IN     shipment.bol_no%TYPE,
                 I_phy_from_loc      IN     shipment.from_loc%TYPE,
                 I_phy_to_loc        IN     shipment.to_loc%TYPE,
                 I_ship_date         IN     period.vdate%TYPE,
                 I_est_arr_date      IN     period.vdate%TYPE,
                 I_no_boxes          IN     shipment.no_boxes%TYPE,
                 I_courier           IN     shipment.courier%TYPE,
                 I_ext_ref_no_out    IN     shipment.ext_ref_no_out%TYPE,
                 I_comments          IN     shipment.comments%TYPE)
RETURN BOOLEAN IS

   L_shipment      shipment.shipment%TYPE := NULL;
   L_to_loc_type   item_loc.loc_type%TYPE := NULL;
   L_from_loc_type item_loc.loc_type%TYPE := NULL;
   L_table         VARCHAR2(30)          := 'SHIPMENT';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

  -- cursors
   cursor C_SHIPMENT is
      select sh.shipment,
             sh.to_loc_type,
             sh.from_loc_type
       from shipment sh
      where sh.bol_no = I_bol_no
        and sh.to_loc = I_phy_to_loc
        and sh.from_loc = I_phy_from_loc
        for update nowait;

   cursor C_BOL_EXISTS is
      select sh.shipment
        from shipment sh
       where sh.bol_no =  I_bol_no;

   cursor C_BOL_EXISTS_SEQ is
      select NVL(max(seq_no), 0)
        from shipsku
       where shipment =  L_shipment;

BEGIN

   if I_bol_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_bol_no','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_phy_from_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_phy_from_loc','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_phy_to_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_phy_to_loc','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_ship_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_ship_date','NULL','NOT NULL');
      return FALSE;
   end if;

   if I_phy_from_loc = I_phy_to_loc then
      O_error_message := SQL_LIB.CREATE_MSG('SAME_LOC',I_phy_from_loc,null,null);
      return FALSE;
   end if;

   LP_bol_rec := NULL;

   if INIT_BOL_PROCESS(O_error_message) = FALSE then
      return FALSE;
   end if;

   open C_SHIPMENT;
   fetch C_SHIPMENT into L_shipment,
                         L_to_loc_type,
                         L_from_loc_type;
   close C_SHIPMENT;

   if L_shipment IS NOT NULL then
      -- processing previously 'unwanded' carton that was
      -- physically on a shipment but wasn't initially scanned.
      O_bol_exists := TRUE;

      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'SHIPMENT',
                       'Shipment: '||to_char(L_shipment));
      update shipment
         set no_boxes = NVL(no_boxes,0) + NVL(I_no_boxes,0)
       where shipment = L_shipment;

      open C_BOL_EXISTS_SEQ;
      fetch C_BOL_EXISTS_SEQ into LP_ss_seq_no;
      close C_BOL_EXISTS_SEQ;
   else
      open  C_BOL_EXISTS;
      fetch C_BOL_EXISTS into L_shipment;
      close C_BOL_EXISTS;

      -- If L_shipment is NOT NULL then the BOL number exists for a different from location and to location
      if L_shipment is NOT NULL then
         -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
         --Following RIB error message has modified as the part of Performance issue.
         /*O_error_message := SQL_LIB.CREATE_MSG('BOL_FROM_TO_EXIST',null,null,null);*/
         --RIB error message enhancement start
         O_error_message := SQL_LIB.CREATE_MSG('BOL_FROM_TO_EXIST',
                                               'bol no='||I_bol_no,
                                               null,
                                               null);
         -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
         return FALSE;
      end if;
   end if;

   if L_shipment IS NULL then
      O_bol_exists := FALSE;

      if LOCATION_ATTRIB_SQL.GET_TYPE(O_error_message,
                                      L_from_loc_type,
                                      I_phy_from_loc) = FALSE then
         return FALSE;
      end if;

      if LOCATION_ATTRIB_SQL.GET_TYPE(O_error_message,
                                      L_to_loc_type,
                                      I_phy_to_loc) = FALSE then
         return FALSE;
      end if;

      if SHIPMENT_ATTRIB_SQL.NEXT_SHIPMENT(O_error_message,
                                           L_shipment) = FALSE then
         return FALSE;
      end if;

      insert into shipment ( shipment,
                             order_no,
                             bol_no,
                             asn,
                             ship_date,
                             receive_date,
                             est_arr_date,
                             ship_origin,
                             status_code,
                             invc_match_status,
                             invc_match_date,
                             to_loc,
                             to_loc_type,
                             from_loc,
                             from_loc_type,
                             courier,
                             no_boxes,
                             ext_ref_no_in,
                             ext_ref_no_out,
                             comments )
                    values ( L_shipment,              --shipment
                             NULL,                    --order_no
                             I_bol_no,                --bol
                             NULL,                    --asn
                             I_ship_date,             --ship_date
                             NULL,                    --receive_date
                             I_est_arr_date,          --est_arr_date
                             3,                       --ship_origin       --external
                             'I',                     --status_code       --input
                             NULL,                    --invc_match_status --unmatched
                             NULL,                    --invc_match_date
                             I_phy_to_loc,            --to_loc
                             L_to_loc_type,           --to_loc_type
                             I_phy_from_loc,          --from_loc
                             L_from_loc_type,         --from_loc_type
                             I_courier,               --courier (carrier_code in bol msg)
                             I_no_boxes,              --no_boxes (container_qty in bol msg)
                             NULL,                    --ext_ref_no_in
                             I_ext_ref_no_out,        --ext_ref_no_out (bol_no in bol msg)
                             I_comments);             --comments
   end if;

   LP_bol_rec.bol_no            := I_bol_no;
   LP_bol_rec.ship_no           := L_shipment;
   LP_bol_rec.phy_from_loc      := I_phy_from_loc;
   LP_bol_rec.phy_from_loc_type := L_from_loc_type;
   LP_bol_rec.phy_to_loc        := I_phy_to_loc;
   LP_bol_rec.phy_to_loc_type   := L_to_loc_type;
   LP_bol_rec.tran_date         := I_ship_date;

   if DATES_SQL.GET_EOW_DATE(O_error_message,
                             LP_bol_rec.eow_date,
                             I_ship_date) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             'SHIPMENT:'||to_char(L_shipment),
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.PUT_BOL',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END PUT_BOL;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--public function--

FUNCTION PUT_ALLOC(O_error_message       IN OUT rtk_errors.rtk_text%TYPE,
                   O_item                IN OUT item_master.item%TYPE,
                   O_alloc_head_from_loc IN OUT item_loc.loc%TYPE,
                   I_alloc_no            IN     alloc_header.alloc_no%TYPE,
                   I_phy_from_loc        IN     item_loc.loc%TYPE,
                   I_item                IN     item_master.item%TYPE)
RETURN BOOLEAN IS

   L_ah_wh    item_loc.loc%TYPE          := NULL;
   L_status   alloc_header.status%TYPE   := NULL;
   L_order_no alloc_header.order_no%TYPE := NULL;
   dist_cnt   BINARY_INTEGER             := NULL;
   item_cnt   BINARY_INTEGER             := NULL;

   L_item               item_master.item%TYPE := NULL;
   L_ref_item           item_master.item%TYPE := NULL;
   L_pack_ind           item_master.pack_ind%TYPE := NULL;
   L_pack_type          item_master.pack_type%TYPE := NULL;
   L_simple_pack_ind    item_master.simple_pack_ind%TYPE := NULL;
   L_catch_weight_ind   item_master.catch_weight_ind%TYPE := NULL;
   L_sellable_ind       item_master.sellable_ind%TYPE := NULL;
   L_item_xform_ind     item_master.item_xform_ind%TYPE := NULL;
   L_supp_pack_size     item_supp_country.supp_pack_size%TYPE := NULL;
   L_dept               item_master.dept%TYPE := NULL;
   L_class              item_master.class%TYPE := NULL;
   L_subclass           item_master.subclass%TYPE := NULL;
   L_ss_seq_no          shipsku.seq_no%TYPE := NULL;

  -- cursors
   cursor C_ALLOC_HEADER is
      select ah.wh,
             ah.status,
             ah.order_no
        from alloc_header ah,
             wh w
       where ah.alloc_no   = I_alloc_no
         and ah.wh         = w.wh
         and ah.item       = O_item
         and w.physical_wh = I_phy_from_loc;

BEGIN

   if I_alloc_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_alloc_no','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_phy_from_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_phy_from_loc','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NULL','NOT NULL');
      return FALSE;
   end if;

   /* reset the distro array */
   LP_bol_rec.distros.DELETE;
   dist_cnt := 1;

   LP_bol_rec.distros(dist_cnt).alloc_no := I_alloc_no;

   /* assumes that there is only one item per alloc */
   item_cnt := 1;

   if BOL_SQL.ITEM_CHECK(O_error_message,
                         L_item,
                         L_ref_item,
                         L_dept,
                         L_class,
                         L_subclass,
                         L_pack_ind,
                         L_pack_type,
                         L_simple_pack_ind,
                         L_catch_weight_ind,
                         L_sellable_ind,
                         L_item_xform_ind,
                         L_supp_pack_size,
                         L_ss_seq_no,
                         I_item) = FALSE then
      return FALSE;
   end if;

   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item := L_item;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ref_item := L_ref_item;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).dept := L_dept;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).class := L_class;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).subclass := L_subclass;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).pack_ind := L_pack_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).pack_type := L_pack_type;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).simple_pack_ind := L_simple_pack_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).catch_weight_ind := L_catch_weight_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).sellable_ind := L_sellable_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item_xform_ind := L_item_xform_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).supp_pack_size := L_supp_pack_size;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ss_seq_no := L_ss_seq_no;

   O_item := LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item;

   open C_ALLOC_HEADER;
   fetch C_ALLOC_HEADER into L_ah_wh,
                             L_status,
                             L_order_no;
   close C_ALLOC_HEADER;

   if L_ah_wh IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ALLOC_NUM', NULL, NULL, NULL);
      return FALSE;
   end if;

   LP_bol_rec.distros(dist_cnt).alloc_status := L_status;
   if L_order_no IS NULL then
      LP_bol_rec.distros(dist_cnt).alloc_type := 'SA';
   else
      LP_bol_rec.distros(dist_cnt).alloc_type := 'PRE';
   end if;

   LP_bol_rec.distros(dist_cnt).alloc_from_loc_phy := I_phy_from_loc;
   LP_bol_rec.distros(dist_cnt).alloc_from_loc_vir := L_ah_wh;

   O_alloc_head_from_loc :=  L_ah_wh;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.PUT_ALLOC',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END PUT_ALLOC;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--public function--
FUNCTION PUT_ALLOC_ITEM(O_error_message       IN OUT rtk_errors.rtk_text%TYPE,
                        I_alloc_no            IN     alloc_header.alloc_no%TYPE,
                        I_item                IN     item_master.item%TYPE,
                        I_carton              IN     shipsku.carton%TYPE,
                        I_qty                 IN     item_loc_soh.stock_on_hand%TYPE,
                        I_weight              IN     item_loc_soh.average_weight%TYPE,
                        I_weight_uom          IN     uom_class.uom%TYPE,
                        I_inv_status          IN     inv_status_codes.inv_status%TYPE,
                        I_phy_to_loc          IN     item_loc.loc%TYPE,
                        I_to_loc_type         IN     item_loc.loc_type%TYPE,
                        I_alloc_head_from_loc IN     item_loc.loc%TYPE)
RETURN BOOLEAN IS

   L_loc        item_loc.loc%TYPE                := NULL;
   L_alloc_qty  item_loc_soh.stock_on_hand%TYPE  := NULL;
   L_tsf_qty    item_loc_soh.stock_on_hand%TYPE  := NULL;
   dist_cnt     BINARY_INTEGER := 1;
   item_cnt     BINARY_INTEGER := 1;

   L_rowid      ROWID;

   L_table                 VARCHAR2(30);
   L_key1                  VARCHAR2(100);
   L_key2                  VARCHAR2(100);
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

  -- cursors
   cursor C_ALLOC_DETAIL is
      select ad.to_loc,
             NVL(ad.qty_allocated, 0),
             NVL(ad.qty_transferred, 0),
             ad.rowid
        from alloc_detail ad,
             wh w
       where ad.alloc_no = I_alloc_no
         --
         and ad.to_loc =  nvl(w.wh, I_phy_to_loc)
         and w.wh (+) = ad.to_loc
         and w.physical_wh (+) = I_phy_to_loc
         --
         for update of ad.qty_transferred, ad.qty_distro nowait;

   cursor C_LOC is
      select s.store
        from store s
       where s.store = I_phy_to_loc
       union
      select w.wh
        from wh w
       where w.wh != w.physical_wh
         and w.physical_wh = I_phy_to_loc;

BEGIN

   if I_alloc_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_alloc_no','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_qty is NULL or I_qty < 0 then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_qty','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_phy_to_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_phy_to_loc','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_to_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_to_loc_type','NULL','NOT NULL');
      return FALSE;
   end if;

   dist_cnt := LP_bol_rec.distros.COUNT;
   item_cnt := 1; --there can only ever be one item per alloc.
   L_table := 'ALLOC_DETAIL';
   L_key1 := TO_CHAR(I_alloc_no);
   L_key2 := TO_CHAR(I_phy_to_loc);

   open C_ALLOC_DETAIL;
   fetch C_ALLOC_DETAIL into L_loc,
                             L_alloc_qty,
                             L_tsf_qty,
                             L_rowid;
   close C_ALLOC_DETAIL;

   if L_loc is NULL then --record does not exist

      LP_bol_rec.distros(dist_cnt).new_alloc_detail_ind := 'Y';
      L_alloc_qty := 0;
      L_tsf_qty := 0;

      open C_LOC;
      fetch C_LOC into L_loc;
      close C_LOC;
      if L_loc is null then
         O_error_message := SQL_LIB.CREATE_MSG('INV_LOC',null,null,null);
         return FALSE;
      end if;

      if NEW_LOC(O_error_message,
                 LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item,
                 LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).pack_ind,
                 LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).dept,
                 LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).class,
                 LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).subclass,
                 L_loc,
                 I_to_loc_type) = FALSE then
         return FALSE;
      end if;

      insert into alloc_detail (alloc_no,
                                to_loc,
                                to_loc_type,
                                qty_transferred,
                                qty_allocated,
                                qty_prescaled,
                                qty_distro,
                                qty_selected,
                                qty_cancelled,
                                qty_received,
                                po_rcvd_qty,
                                non_scale_ind)
                        values (I_alloc_no,
                                L_loc,
                                I_to_loc_type,
                                I_qty,    --qty_transferred
                                I_qty,    --qty_allocated
                                0,        --qty_prescaled
                                0,        --qty_distro
                                0,        --qty_selected
                                0,        --qty_cancelled
                                0,        --qty_received
                                NULL,     --po_rcvd_qty
                                'N');     --non_scale_ind

      if ALLOC_CHARGE_SQL.DEFAULT_CHRGS(O_error_message,
                                 I_alloc_no,
                                 I_alloc_head_from_loc,
                                 L_loc,
                                 I_to_loc_type,
                                 I_item) = FALSE then
         return FALSE;
      end if;

   else --alloc_detail exists

      LP_bol_rec.distros(dist_cnt).new_alloc_detail_ind := 'N';

      /* We don not update qty_allocated here since we do not know
       * if the alloc_detail records was originally on the allocation
       * or if it was added through a previous run of this module.  In
       * the case of transfers, we do know if the transfer was externally
       * generated.  For externally generated transfers we do increment
       * tsfdetail.tsf_qty (the analogous field to qty_allocated for a transfer).
       */
      update alloc_detail ad
         set ad.qty_transferred = NVL(ad.qty_transferred, 0) + I_qty,
             ad.qty_distro      = NVL(ad.qty_distro, 0) - I_qty
       where ad.rowid = L_rowid;

   end if;

   --not possible to alloc nonsellable stock
   if I_inv_status != -1 then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INV_STATUS',I_inv_status,null,null);
      return FALSE;
   end if;

   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ad_to_loc_phy := I_phy_to_loc;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ad_to_loc_vir := L_loc;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).qty := I_qty;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).inv_status := I_inv_status;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).carton := I_carton;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ad_tsf_qty := L_tsf_qty;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ad_alloc_qty := L_alloc_qty;

   -- set weight for a simple pack catch weight item
   if LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).simple_pack_ind = 'Y' and
      LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).catch_weight_ind = 'Y' and
      I_weight is NOT NULL and
      I_weight_uom is NOT NULL then
      -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
      LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).weight := NULL;
      LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).weight_uom := NULL;
      -- 21-Oct-2008 TESCO HSC/Murali 6907185 End

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
                                            'BOL_SQL.PUT_ALLOC_ITEM',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END PUT_ALLOC_ITEM;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--public function--
FUNCTION PROCESS_ALLOC(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN IS

   dist_cnt BINARY_INTEGER := 1;
   item_cnt BINARY_INTEGER := 1;

BEGIN

   --no loop --distros are processed individually --allocs only ever have one item
   if BOL_SQL.SEND_ALLOC(O_error_message,
                         LP_bol_rec.distros(dist_cnt).alloc_no,
                         LP_bol_rec.distros(dist_cnt).alloc_status,
                         LP_bol_rec.distros(dist_cnt).alloc_type,
                         LP_bol_rec.distros(dist_cnt).new_alloc_detail_ind,
                         LP_bol_rec.ship_no,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ss_seq_no,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ref_item,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).pack_ind,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).pack_type,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).dept,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).class,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).subclass,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).carton,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).inv_status,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).qty,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).simple_pack_ind,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).catch_weight_ind,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).weight,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).weight_uom,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).sellable_ind,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item_xform_ind,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ad_alloc_qty,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ad_tsf_qty,
                         LP_bol_rec.distros(dist_cnt).alloc_from_loc_vir,
                         LP_bol_rec.phy_from_loc_type,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ad_to_loc_vir,
                         LP_bol_rec.phy_to_loc_type,
                         LP_bol_rec.tran_date,
                         LP_bol_rec.eow_date) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'BOL_SQL.PROCESS_ALLOC',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END PROCESS_ALLOC;

-------------------------------------------------------------------------------

FUNCTION SEND_ALLOC(O_error_message    IN OUT rtk_errors.rtk_text%TYPE,
                    I_alloc_no         IN     alloc_header.alloc_no%TYPE,
                    I_alloc_status     IN     alloc_header.status%TYPE,
                    I_alloc_type       IN     VARCHAR2,
                    I_new_ad_ind       IN     VARCHAR2,
                    I_ship_no          IN     shipment.shipment%TYPE,
                    I_ss_seq_no        IN     shipsku.seq_no%TYPE,
                    I_item             IN     item_master.item%TYPE,
                    I_ref_item         IN     item_master.item%TYPE,
                    I_pack_ind         IN     item_master.pack_ind%TYPE,
                    I_pack_type        IN     item_master.pack_type%TYPE,
                    I_dept             IN     item_master.dept%TYPE,
                    I_class            IN     item_master.class%TYPE,
                    I_subclass         IN     item_master.subclass%TYPE,
                    I_carton           IN     shipsku.carton%TYPE,
                    I_inv_status       IN     shipsku.inv_status%TYPE,
                    I_qty              IN     item_loc_soh.stock_on_hand%TYPE,
                    I_simple_pack_ind  IN     item_master.simple_pack_ind%TYPE,
                    I_catch_weight_ind IN     item_master.catch_weight_ind%TYPE,
                    I_weight           IN     item_loc_soh.average_weight%TYPE,
                    I_weight_uom       IN     uom_class.uom%TYPE,
                    I_sellable_ind     IN     item_master.sellable_ind%TYPE,
                    I_item_xform_ind   IN     item_master.item_xform_ind%TYPE,
                    I_ad_alloc_qty     IN     item_loc_soh.stock_on_hand%TYPE,
                    I_ad_tsf_qty       IN     item_loc_soh.stock_on_hand%TYPE,
                    I_from_loc         IN     item_loc.loc%TYPE,
                    I_from_loc_type    IN     item_loc.loc_type%TYPE,
                    I_to_loc           IN     item_loc.loc%TYPE,
                    I_to_loc_type      IN     item_loc.loc_type%TYPE,
                    I_tran_date        IN     period.vdate%TYPE,
                    I_eow_date         IN     period.vdate%TYPE)
RETURN BOOLEAN IS

   L_resv_exp_qty             item_loc_soh.stock_on_hand%TYPE := NULL;
   L_intran_qty               item_loc_soh.stock_on_hand%TYPE := NULL;

   -- This holds the from loc item cost based on the accounting methods.
   L_from_wac                 item_loc_soh.av_cost%TYPE       := NULL;
   L_from_unit_retail         item_loc.unit_retail%TYPE       := NULL;

   -- for prorating pack's charges
   L_from_av_cost             item_loc_soh.av_cost%TYPE   := NULL;
   L_pack_no                  item_master.item%TYPE       := NULL;
   L_pack_loc_av_cost         item_loc_soh.av_cost%TYPE   := NULL;
   L_pack_loc_retail          item_loc.unit_retail%TYPE   := NULL;
   -- dummy
   L_pack_loc_cost            item_loc_soh.unit_cost%TYPE := NULL;
   L_pack_selling_unit_retail item_loc.unit_retail%TYPE   := NULL;
   L_pack_selling_uom         item_loc.selling_uom%TYPE   := NULL;

   -- for charges
   L_total_chrgs_prim         item_loc.unit_retail%TYPE       := 0;
   L_profit_chrgs_to_loc      item_loc.unit_retail%TYPE       := 0;
   L_exp_chrgs_to_loc         item_loc.unit_retail%TYPE       := 0;
   L_pack_total_chrgs_prim    item_loc.unit_retail%TYPE       := 0;
   L_pack_profit_chrgs_to_loc item_loc.unit_retail%TYPE       := 0;
   L_pack_exp_chrgs_to_loc    item_loc.unit_retail%TYPE       := 0;
   L_pack_receive_as_type     item_loc.receive_as_type%TYPE   := NULL;

   L_to_wh           item_loc.loc%TYPE := NULL;
   L_to_store        item_loc.loc%TYPE := NULL;
   L_from_wh         item_loc.loc%TYPE := NULL;
   L_from_store      item_loc.loc%TYPE := NULL;

   --Alloc may be intercompany
   L_intercompany      BOOLEAN := FALSE;

   --This holds the unit cost used in stock ledger write.
   --For allocation, it should be the same as I_from_wac.
   L_alloc_unit_cost          item_loc_soh.av_cost%TYPE := NULL;

   L_ss_cost                  item_loc_soh.av_cost%TYPE := 0;
   L_ss_prim_chrgs            item_loc_soh.av_cost%TYPE := 0;
   L_ss_from_chrgs            item_loc_soh.av_cost%TYPE := 0;
   L_ss_retail                item_loc.unit_retail%TYPE := 0;

   -- for simple pack catch weight processing
   L_weight_cuom              item_loc_soh.average_weight%TYPE := NULL;
   L_cuom                     item_supp_country.cost_uom%TYPE := NULL;
   L_ss_exp_weight            shipsku.weight_expected%TYPE := NULL;
   L_ss_exp_weight_uom        shipsku.weight_expected_uom%TYPE := NULL;

   -- cursors
   cursor C_PACK_RCV_AS_TYPE is
      select NVL(il.receive_as_type, 'E')
        from item_loc il
       where il.loc  = I_to_loc
         and il.item = L_pack_no;

   cursor C_ITEM_IN_PACK is
      select v.item,
             v.qty,
             im.dept,
             im.class,
             im.subclass,
             im.sellable_ind,
             im.item_xform_ind,
             im.inventory_ind
        from item_master im,
             v_packsku_qty v
       where v.pack_no = L_pack_no
         and im.item   = v.item;

BEGIN

   L_from_wh    := I_from_loc;
   L_from_store := -1;
   L_to_wh    := -1;
   L_to_store := I_to_loc;

   if I_alloc_status = 'C' or
      I_alloc_type = 'PRE' or
      I_new_ad_ind = 'Y' then
      L_resv_exp_qty := 0;
   else
      if I_ad_tsf_qty >= I_ad_alloc_qty then
         L_resv_exp_qty := 0;
      elsif I_qty + I_ad_tsf_qty > I_ad_alloc_qty then
         L_resv_exp_qty := I_ad_alloc_qty - I_ad_tsf_qty;
      else
         L_resv_exp_qty := I_qty;
      end if;
   end if;

   L_intran_qty := I_qty;

   if TRANSFER_SQL.IS_INTERCOMPANY(O_error_message,
                                   L_intercompany,
                                   'A',  -- distro type
                                   NULL, -- transfer type
                                   I_from_loc,
                                   I_from_loc_type,
                                   I_to_loc,
                                   I_to_loc_type) = FALSE then
      return FALSE;
   end if;

   -- write weight on the message to shipsku weight_expected
   if I_simple_pack_ind = 'Y' and I_catch_weight_ind = 'Y' then
      if I_weight is NOT NULL and I_weight_uom is NOT NULL then
         L_ss_exp_weight := I_weight;
         L_ss_exp_weight_uom := I_weight_uom;
      end if;
   end if;

   if I_pack_ind = 'N' then
      if BOL_SQL.UPD_FROM_ITEM_LOC(O_error_message,
                                   L_from_av_cost,  -- not used
                                   L_from_unit_retail,
                                   I_item,
                                   'N',
                                   I_sellable_ind,
                                   I_item_xform_ind,
                                   NULL,  -- inventory ind
                                   I_from_loc,
                                   I_qty,
                                   L_resv_exp_qty,
                                   NULL,  -- weight
                                   NULL,  -- weight uom
                                   I_eow_date) = FALSE then
         return FALSE;
      end if;

      if ITEMLOC_ATTRIB_SQL.GET_WAC(O_error_message,
                                    L_from_wac,
                                    I_item,
                                    I_dept,
                                    I_class,
                                    I_subclass,
                                    I_from_loc,
                                    I_from_loc_type,
                                    I_tran_date) = FALSE then
         return FALSE;
      end if;

      if UP_CHARGE_SQL.CALC_TSF_ALLOC_ITEM_LOC_CHRGS(O_error_message,
                                                     L_total_chrgs_prim,
                                                     L_profit_chrgs_to_loc,
                                                     L_exp_chrgs_to_loc,
                                                     'A',                    --allocation
                                                     I_alloc_no,
                                                     NULL,                   --tsf_seq_no
                                                     NULL,                   --ship_no
                                                     NULL,                   --ship_seq_no,
                                                     I_item,
                                                     NULL,                   --pack_item
                                                     I_from_loc,
                                                     I_from_loc_type,
                                                     I_to_loc,
                                                     I_to_loc_type) = FALSE then
         return FALSE;
      end if;

      if BOL_SQL.UPD_TO_ITEM_LOC(O_error_message,
                                 I_item,
                                 NULL,  --pack_no
                                 NULL,  --percent in pack
                                 'E',   --receive_as_type
                                 'A',   --transfer_type
                                 I_to_loc,
                                 I_to_loc_type,
                                 I_qty,
                                 L_resv_exp_qty,
                                 L_intran_qty,
                                 NULL,   -- weight_cuom
                                 NULL,   -- cuom
                                 I_from_loc,
                                 I_from_loc_type,
                                 L_from_wac,
                                 L_total_chrgs_prim,
                                 I_alloc_no,
                                 'A',
                                 L_intercompany) = FALSE then
         return FALSE;
      end if;

      if I_from_loc_type = 'W' then
         if BOL_SQL.WRITE_ISSUES(O_error_message,
                                 I_item,
                                 I_from_loc,
                                 I_qty,
                                 I_eow_date) = FALSE then
             return FALSE;
         end if;
      end if;

      if STKLEDGR_SQL.WRITE_FINANCIALS(O_error_message,
                                       L_alloc_unit_cost,
                                       'A',
                                       I_ship_no,   --shipment
                                       I_alloc_no,
                                       I_tran_date, --tran date
                                       I_item,
                                       NULL,        --pack_no
                                       NULL,        --pct_in_pack
                                       I_dept,
                                       I_class,
                                       I_subclass,
                                       I_qty,
                                       NULL,        --weight_cuom
                                       I_from_loc,
                                       I_from_loc_type,
                                       'N',         --from finsiher (alloc won't have finishing)
                                       I_to_loc,
                                       I_to_loc_type,
                                       'N',         --to finisher
                                       L_from_wac,
                                       L_profit_chrgs_to_loc,
                                       L_exp_chrgs_to_loc,
                                       L_intercompany) = FALSE then
         return FALSE;
      end if;

      if UPDATE_SNAPSHOT_SQL.EXECUTE(O_error_message,
                                     'TSFO',
                                     I_item,
                                     'N',
                                     L_to_store,
                                     L_to_wh,
                                     L_from_store,
                                     L_from_wh,
                                     I_tran_date,
                                     LP_vdate,
                                     I_qty) = FALSE then
         return FALSE;
      end if;

      L_ss_prim_chrgs := L_total_chrgs_prim;
      L_ss_cost       := L_alloc_unit_cost;  -- same as L_from_wac
      -- For a sellable/non-orderable/inventory item, if non-transformed and non-pack,
      -- unit_retail won't be defined, default to 0 for shipsku insert.
      L_ss_retail     := NVL(L_from_unit_retail, 0);

   else -- item is a pack

      L_pack_no := I_item;

      -- Get pack's unit_retail and av_cost.
      -- For a non-sellable pack, retrieve pack's unit retail based on components.
      if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message,
                                                  L_pack_no,
                                                  I_from_loc,
                                                  I_from_loc_type,
                                                  'Y', -- nonsellable_pack_retail_ind
                                                  L_pack_loc_av_cost,
                                                  L_pack_loc_cost,
                                                  L_pack_loc_retail,
                                                  L_pack_selling_unit_retail,
                                                  L_pack_selling_uom) = FALSE then
         return FALSE;
      end if;

      -- for a simple pack catch weight item, get weight of I_qty.
      if I_simple_pack_ind = 'Y' and I_catch_weight_ind = 'Y' then
         if CATCH_WEIGHT_SQL.PRORATE_WEIGHT(O_error_message,
                                            L_weight_cuom,
                                            L_cuom,
                                            I_item, -- pack no
                                            I_from_loc,
                                            I_from_loc_type,
                                            I_weight,
                                            I_weight_uom,
                                            I_qty,
                                            I_qty) = FALSE then
            return FALSE;
         end if;

         -- write weight derived from average weight to shipsku
         if I_weight is NULL or I_weight_uom is NULL then
            L_ss_exp_weight := L_weight_cuom;
            L_ss_exp_weight_uom := L_cuom;
         end if;
      end if;

      open C_PACK_RCV_AS_TYPE;
      fetch C_PACK_RCV_AS_TYPE into L_pack_receive_as_type;
      close C_PACK_RCV_AS_TYPE;
      if L_pack_receive_as_type is NULL then
         L_pack_receive_as_type := 'E';
      end if;

      if BOL_SQL.UPDATE_PACK_LOCS(O_error_message,
                                  L_pack_no,
                                  I_from_loc,
                                  I_from_loc_type,
                                  I_to_loc,
                                  I_to_loc_type,
                                  L_pack_receive_as_type,
                                  'A',            -- tsf_type
                                  I_qty,
                                  L_weight_cuom,
                                  I_qty,          -- intran qty
                                  L_weight_cuom,  -- intran weight
                                  L_resv_exp_qty)= FALSE then
         return FALSE;
      end if;

      if I_from_loc_type = 'W' then
         if UPDATE_SNAPSHOT_SQL.EXECUTE(O_error_message,
                                        'TSFO',
                                        L_pack_no,
                                        'P',
                                        L_to_store,
                                        L_to_wh,
                                        L_from_store,
                                        L_from_wh,
                                        I_tran_date,
                                        LP_vdate,
                                        I_qty) = FALSE then
            return FALSE;
         end if;
      end if;

      if I_pack_type != 'B' then
         if UP_CHARGE_SQL.CALC_TSF_ALLOC_ITEM_LOC_CHRGS(O_error_message,
                                                        L_pack_total_chrgs_prim,
                                                        L_pack_profit_chrgs_to_loc,
                                                        L_pack_exp_chrgs_to_loc,
                                                        'A',                    --allocation
                                                        I_alloc_no,
                                                        NULL,                   --tsf_seq_no
                                                        NULL,                   --ship_no
                                                        NULL,                   --ship_seq_no,
                                                        I_item,
                                                        NULL,                   --pack_item
                                                        I_from_loc,
                                                        I_from_loc_type,
                                                        I_to_loc,
                                                        I_to_loc_type) = FALSE then
            return FALSE;
         end if;

         L_ss_prim_chrgs := L_pack_total_chrgs_prim;
      end if;

      FOR rec in C_ITEM_IN_PACK LOOP

         if BOL_SQL.UPD_FROM_ITEM_LOC(O_error_message,
                                      L_from_av_cost,
                                      L_from_unit_retail,
                                      rec.item,
                                      'Y',
                                      rec.sellable_ind,
                                      rec.item_xform_ind,
                                      rec.inventory_ind,
                                      I_from_loc,
                                      I_qty * rec.qty,
                                      L_resv_exp_qty * rec.qty,
                                      L_weight_cuom,
                                      L_cuom,
                                      I_eow_date) = FALSE then
            return FALSE;
         end if;

         if ITEMLOC_ATTRIB_SQL.GET_WAC(O_error_message,
                                       L_from_wac,
                                       rec.item,
                                       rec.dept,
                                       rec.class,
                                       rec.subclass,
                                       I_from_loc,
                                       I_from_loc_type,
                                       I_tran_date) = FALSE then
            return FALSE;
         end if;

         if I_pack_type != 'B' then
            --prorate the charges calculated at the pack level across the comp items
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
            L_profit_chrgs_to_loc := L_pack_profit_chrgs_to_loc * L_from_av_cost / L_pack_loc_av_cost;
            L_exp_chrgs_to_loc    := L_pack_exp_chrgs_to_loc    * L_from_av_cost / L_pack_loc_av_cost;
            L_total_chrgs_prim    := L_pack_total_chrgs_prim    * L_from_av_cost / L_pack_loc_av_cost;

         else
            --look up the charges at the comp level
            if UP_CHARGE_SQL.CALC_TSF_ALLOC_ITEM_LOC_CHRGS(O_error_message,
                                                           L_total_chrgs_prim,
                                                           L_profit_chrgs_to_loc,
                                                           L_exp_chrgs_to_loc,
                                                           'A',                    --allocation
                                                           I_alloc_no,
                                                           NULL,                   --tsf_seq_no
                                                           NULL,                   --ship_no
                                                           NULL,                   --ship_seq_no,
                                                           rec.item,               --item
                                                           I_item,                 --pack_no
                                                           I_from_loc,
                                                           I_from_loc_type,
                                                           I_to_loc,
                                                           I_to_loc_type) = FALSE then
               return FALSE;
            end if;

            L_ss_prim_chrgs := L_ss_prim_chrgs + (L_total_chrgs_prim * rec.qty);
         end if;

         if rec.inventory_ind = 'Y' then
            if BOL_SQL.UPD_TO_ITEM_LOC(O_error_message,
                                       rec.item,
                                       I_item,  --pack_no
                                       NULL,    --percent in pack used for transfer only
                                       L_pack_receive_as_type,
                                       'A', --transfer_type
                                       I_to_loc,
                                       I_to_loc_type,
                                       I_qty * rec.qty,
                                       L_resv_exp_qty * rec.qty,
                                       L_intran_qty * rec.qty,
                                       L_weight_cuom,
                                       L_cuom,
                                       I_from_loc,
                                       I_from_loc_type,
                                       L_from_wac,
                                       L_total_chrgs_prim,
                                       I_alloc_no,
                                       'A',
                                       L_intercompany) = FALSE then
               return FALSE;
            end if;
         end if;

         if I_from_loc_type = 'W' then
            if BOL_SQL.WRITE_ISSUES(O_error_message,
                                    rec.item,
                                    I_from_loc,
                                    I_qty * rec.qty,
                                    I_eow_date) = FALSE then
               return FALSE;
            end if;
         end if;

         if STKLEDGR_SQL.WRITE_FINANCIALS(O_error_message,
                                          L_alloc_unit_cost,
                                          'A',
                                          I_ship_no,   --shipment
                                          I_alloc_no,
                                          I_tran_date, --tran date
                                          rec.item,
                                          I_item,      --pack_no
                                          NULL,        --pct_in_pack
                                          rec.dept,
                                          rec.class,
                                          rec.subclass,
                                          I_qty * rec.qty,
                                          L_weight_cuom,
                                          I_from_loc,
                                          I_from_loc_type,
                                          'N',         --from finsiher (alloc won't have finishing)
                                          I_to_loc,
                                          I_to_loc_type,
                                          'N',         --to finisher
                                          L_from_wac,
                                          L_profit_chrgs_to_loc,
                                          L_exp_chrgs_to_loc,
                                          L_intercompany) = FALSE then
            return FALSE;
         end if;

         if I_from_loc_type = 'W' or L_pack_receive_as_type = 'E' then
            if UPDATE_SNAPSHOT_SQL.EXECUTE(O_error_message,
                                           'TSFO',
                                           rec.item,
                                           'C',
                                           L_to_store,
                                           L_to_wh,
                                           L_from_store,
                                           L_from_wh,
                                           I_tran_date,
                                           LP_vdate,
                                           I_qty * rec.qty) = FALSE then
               return FALSE;
            end if;
         end if;

         -- shipsku.unit_cost for pack should be based on component's wac
         L_ss_cost := L_ss_cost + (L_alloc_unit_cost * rec.qty);
      END LOOP;

      L_ss_retail := NVL(L_pack_loc_retail, 0);

   end if; -- item type

   L_ss_prim_chrgs := L_ss_prim_chrgs;

   if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                       NULL,
                                       NULL,
                                       NULL,
                                       I_from_loc,
                                       I_from_loc_type,
                                       NULL,
                                       L_ss_prim_chrgs,
                                       L_ss_from_chrgs,
                                       'C',
                                       NULL,
                                       NULL) = FALSE then
      return FALSE;
   end if;

   if BOL_SQL.INS_SHIPSKU(O_error_message,
                          I_ship_no,
                          I_ss_seq_no,
                          I_item,
                          I_ref_item,
                          I_alloc_no,
                          'A',
                          I_carton,
                          I_inv_status,
                          0,
                          L_ss_cost + L_ss_from_chrgs,
                          L_ss_retail,
                          I_qty,
                          L_ss_exp_weight,
                          L_ss_exp_weight_uom) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.SEND_ALLOC',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END SEND_ALLOC;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--public function--
FUNCTION PUT_TSF(O_error_message    IN OUT rtk_errors.rtk_text%TYPE,
                 O_tsfhead_to_loc   IN OUT tsfhead.to_loc%TYPE,
                 O_tsfhead_from_loc IN OUT item_loc.loc%TYPE,
                 O_tsf_type         IN OUT tsfhead.tsf_type%TYPE,
                 O_del_type         IN OUT ordcust.deliver_type%TYPE,
                 I_tsf_no           IN     tsfhead.tsf_no%TYPE,
                 I_phy_from_loc     IN     shipment.from_loc%TYPE,
                 I_from_loc_type    IN     shipment.from_loc_type%TYPE,
                 I_phy_to_loc       IN     shipment.to_loc%TYPE,
                 I_to_loc_type      IN     shipment.to_loc_type%TYPE,
                 I_tran_date        IN     period.vdate%TYPE,
                 I_comment_desc     IN     tsfhead.comment_desc%TYPE)
RETURN BOOLEAN IS

   L_exist     VARCHAR2(1)           := 'n';
   L_status    tsfhead.status%TYPE   := NULL;
   L_tsf_type  tsfhead.tsf_type%TYPE := NULL;
   L_vir_loc   item_loc.loc%TYPE     := NULL;
   L_phy_loc   item_loc.loc%TYPE     := NULL;
   L_to_loc    item_loc.loc%TYPE     := NULL;
   L_from_loc  item_loc.loc%TYPE     := NULL;

   --10-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   Begin
   L_to_loc_entity    TSF_ENTITY.TSF_ENTITY_ID%TYPE := NULL;
   L_from_loc_entity  TSF_ENTITY.TSF_ENTITY_ID%TYPE := NULL;
   L_entity_name                TSF_ENTITY.TSF_ENTITY_DESC%TYPE := NULL;
   --10-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   End
   --13-Mar-2010 Tesco HSC/Reshma Koshy   DefNBS016111   Begin
   L_vir_from_loc   item_loc.loc%TYPE     := NULL;
   L_vir_to_loc     item_loc.loc%TYPE     := NULL;
   --13-Mar-2010 Tesco HSC/Reshma Koshy   DefNBS016111   End
   dist_cnt    BINARY_INTEGER        := NULL;
   L_rowid     ROWID;

   L_table                 VARCHAR2(30);
   L_key1                  VARCHAR2(100);
   L_key2                  VARCHAR2(100);
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

  -- cursors
   cursor C_TSF is
      select th.status,
             th.tsf_type,
             th.from_loc,
             th.to_loc,
             th.rowid
        from tsfhead th
       where th.tsf_no   = I_tsf_no
         for update nowait;

   cursor C_PHY_WH is
      select 'x'
        from wh w
       where w.physical_wh = L_phy_loc
         and w.wh          = L_vir_loc;

    cursor C_DEL_TYPE is
       select o.deliver_type
         from ordcust o
        where o.tsf_no = I_tsf_no;

   --13-Mar-2010 Tesco HSC/Reshma Koshy   DefNBS016111   Begin
   cursor C_FROM_VWH is
      select primary_vwh
        from wh
       where wh = I_phy_from_loc
         for update nowait;

   cursor C_TO_VWH is
      select primary_vwh
        from wh
       where wh = I_phy_to_loc
         for update nowait;
   --13-Mar-2010 Tesco HSC/Reshma Koshy   DefNBS016111   End

BEGIN

   if I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_tsf_no','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_phy_from_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_phy_from_loc','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_from_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_from_loc_type','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_phy_to_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_phy_to_loc','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_to_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_to_loc_type','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_tran_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_tran_date','NULL','NOT NULL');
      return FALSE;
   end if;

   O_tsfhead_to_loc := NULL;
   O_tsfhead_from_loc := NULL;
   L_table := 'TSFHEAD';
   L_key1 := TO_CHAR(I_tsf_no);
   L_key2 := NULL;

   open C_TSF;
   fetch C_TSF into L_status,
                    O_tsf_type,
                    L_from_loc,
                    L_to_loc,
                    L_rowid;
   close C_TSF;

   /* if the passed in tsf not on table */
   if L_to_loc IS NULL then
      L_status := 'S';
      --10-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   Begin
      --Commented the folowing code to handle Inter Company transfer for Single Instance.
      --O_tsf_type := 'EG';
      O_del_type := 'X';

      if LOCATION_ATTRIB_SQL.GET_ENTITY(O_error_message,
                                        L_from_loc_entity,
                                        L_entity_name,
                                        I_phy_from_loc,
                                        I_from_loc_type) = FALSE then
         return FALSE;
      end if;

      if LOCATION_ATTRIB_SQL.GET_ENTITY(O_error_message,
                                        L_to_loc_entity,
                                        L_entity_name,
                                        I_phy_to_loc,
                                        I_to_loc_type) = FALSE then
         return FALSE;
      end if;

      if (L_from_loc_entity != L_to_loc_entity) then
         O_tsf_type := 'IC';
      else
         O_tsf_type := 'EG';
      end if;

      if O_tsf_type != 'EG' then
      --13-Mar-2010 Tesco HSC/Reshma Koshy   DefNBS016111   Begin
         open C_FROM_VWH;
         fetch C_FROM_VWH into L_vir_from_loc;
         close C_FROM_VWH;

         open C_TO_VWH;
         fetch C_TO_VWH into L_vir_to_loc;
         close C_TO_VWH;

         --14-Apr-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016111 Begin
         if I_to_loc_type = 'W' and I_from_loc_type ='W' then
            O_tsfhead_to_loc   := L_vir_to_loc;
            O_tsfhead_from_loc := L_vir_from_loc;
         elsif I_to_loc_type = 'S' and I_from_loc_type ='S' then
            O_tsfhead_to_loc := I_phy_to_loc;
            O_tsfhead_from_loc := I_phy_from_loc;
         elsif I_to_loc_type = 'S' and I_from_loc_type = 'W' then
            O_tsfhead_to_loc := I_phy_to_loc;
            O_tsfhead_from_loc := L_vir_from_loc;
         end if;

         if CREATE_TSF(O_error_message,
                       I_tsf_no,
                       O_tsf_type,
                       O_tsfhead_from_loc,
                       I_from_loc_type,
                       O_tsfhead_to_loc,
                       I_to_loc_type,
                       I_tran_date,
                       I_comment_desc) = FALSE then
            return FALSE;
         end if;
         --14-Apr-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016111 End
      --13-Mar-2010 Tesco HSC/Reshma Koshy   DefNBS016111   End
      end if;
      --10-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   End

      --14-Apr-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016111 Begin
      if O_tsf_type = 'EG' then
      --14-Apr-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016111 End
         if CREATE_TSF(O_error_message,
                       I_tsf_no,
                       O_tsf_type,
                       I_phy_from_loc,
                       I_from_loc_type,
                       I_phy_to_loc,
                       I_to_loc_type,
                       I_tran_date,
                       I_comment_desc) = FALSE then
            return FALSE;
         end if;
      --14-Apr-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016111 Begin
      end if;
       --14-Apr-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016111 End

   else -- the transfer exists

      -- either the locations must match (store or MC is off) or the
      -- loc on the tsf must exist in the passed phy loc

      -- verify locations match
      if L_from_loc != I_phy_from_loc then

         L_exist := 'n';
         L_phy_loc := I_phy_from_loc;
         L_vir_loc := L_from_loc;

         open C_PHY_WH;
         fetch C_PHY_WH into L_exist;
         close C_PHY_WH;
         if L_exist = 'n' then
            O_error_message := SQL_LIB.CREATE_MSG('INV_TSF_FROM_LOC', TO_CHAR(I_phy_from_loc),TO_CHAR(I_tsf_no), NULL);
            return FALSE;
         end if;

      end if;

      -- verify locations match
      if L_to_loc != I_phy_to_loc then

         L_exist := 'n';
         L_phy_loc := I_phy_to_loc;
         L_vir_loc := L_to_loc;

         open C_PHY_WH;
         fetch C_PHY_WH into L_exist;
         close C_PHY_WH;

         if L_exist = 'n' then
            O_error_message := SQL_LIB.CREATE_MSG('INV_TSF_TO_LOC', TO_CHAR(I_phy_to_loc), TO_CHAR(I_tsf_no), NULL);
            return FALSE;
         end if;

      end if;

      if O_tsf_type = 'CO' then
         open C_DEL_TYPE;
         fetch C_DEL_TYPE into O_del_type;

         if C_DEL_TYPE%NOTFOUND then
            close C_DEL_TYPE;
            O_error_message := SQL_LIB.CREATE_MSG('NO_ORD_CUST', TO_CHAR(I_tsf_no), NULL, NULL);
            return FALSE;
         end if;
         close C_DEL_TYPE;
      else
         O_del_type := 'X';
      end if;

      if (O_tsf_type != 'CO' or O_del_type != 'S') then
         update tsfhead th
            set th.status = 'S'
          where th.rowid   = L_rowid
            and th.status != 'C';
      end if;

      if O_tsf_type != 'EG' then
         O_tsfhead_to_loc := L_to_loc;
         O_tsfhead_from_loc := L_from_loc;
      end if;

   end if;

   -- reset the distro array
   LP_bol_rec.distros.DELETE;
   dist_cnt := 1;

   LP_bol_rec.distros(dist_cnt).tsf_no := I_tsf_no;
   LP_bol_rec.distros(dist_cnt).tsf_status := L_status;
   LP_bol_rec.distros(dist_cnt).tsf_type := O_tsf_type;
   LP_bol_rec.distros(dist_cnt).tsf_del_type := O_del_type;
   if L_to_loc IS NULL then
      LP_bol_rec.distros(dist_cnt).new_tsf_ind := 'Y';
   else
      LP_bol_rec.distros(dist_cnt).new_tsf_ind := 'N';
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
                                            'BOL_SQL.PUT_TSF',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END PUT_TSF;

-------------------------------------------------------------------------------

FUNCTION CREATE_TSF(O_error_message     IN OUT rtk_errors.rtk_text%TYPE,
                    I_tsf_no            IN     tsfhead.tsf_no%TYPE,
                    I_tsf_type          IN     tsfhead.tsf_type%TYPE,
                    I_phy_from_loc      IN     item_loc.loc%TYPE,
                    I_from_loc_type     IN     item_loc.loc_type%TYPE,
                    I_phy_to_loc        IN     item_loc.loc%TYPE,
                    I_to_loc_type       IN     item_loc.loc_type%TYPE,
                    I_tran_date         IN     period.vdate%TYPE,
                    I_comment_desc      IN     tsfhead.comment_desc%TYPE)
RETURN BOOLEAN IS

   L_zone     VARCHAR2(1) := 'n';
   L_loc      item_loc.loc%TYPE;

   L_pgm      if_errors.program_name%TYPE := 'BOL_SQL.CREATE_TSF';
   L_luw      if_errors.unit_of_work%TYPE := NULL;

   L_status_code         VARCHAR2(1) := NULL;
   L_max_details         Number := 0;
   L_num_threads         Number := 0;
   L_min_time_lag        Number := 0;


  -- cursors
   cursor C_ZONE_CHECK is
      select 'y'
        from store a,
             store b
       where a.store                = I_phy_from_loc
         and b.store                = I_phy_to_loc
         --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
         and NVL(a.transfer_zone,0) = NVL(b.transfer_zone,0);
         --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
BEGIN
   if I_from_loc_type = 'S' and I_to_loc_type = 'S' then
      open C_ZONE_CHECK;
      fetch C_ZONE_CHECK into L_zone;
      close C_ZONE_CHECK;
      --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
      if L_zone != 'y' then
         O_error_message := SQL_LIB.CREATE_MSG('EG_TSF_ZONE',
                                                To_Char(I_tsf_no),
                                                NULL,
                                                NULL);
         return FALSE;
      --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
      end if;
   end if;

   insert into tsfhead(tsf_no,
                       from_loc_type,
                       from_loc,
                       to_loc_type,
                       to_loc,
                       dept,
                       inventory_type,
                       tsf_type,
                       status,
                       freight_code,
                       routing_code,
                       create_date,
                       create_id,
                       approval_date,
                       approval_id,
                       delivery_date,
                       close_date,
                       ext_ref_no,
                       repl_tsf_approve_ind,
                       comment_desc)
                values(I_tsf_no,
                       I_from_loc_type,
                       I_phy_from_loc,
                       I_to_loc_type,
                       I_phy_to_loc,
                       NULL,          --dept--this will be updated later as needed
                       'A',           --assume 'EG' sends available inventory
                       I_tsf_type,
                       'S',
                       'N',
                       NULL,          --rounting_code
                       I_tran_date,
                       'EXTERNAL',
                       I_tran_date,
                       'EXTERNAL',
                       NULL,          --delivery_date
                       NULL,          --close_date
                       NULL,          --ext_ref_no
                       'N',
                       I_comment_desc);         --comment_desc

   API_LIBRARY.GET_RIB_SETTINGS(L_status_code,
                                O_error_message,
                                L_max_details,
                                L_num_threads,
                                L_min_time_lag,
                                RMSMFM_TRANSFERS.FAMILY);

   if L_status_code in (API_CODES.UNHANDLED_ERROR) then
      return FALSE;
   end if;

   -- 06-Jan-2010 TESCO HSC/Reshma Koshy NBS00015819 Begin
/*
   insert into transfers_pub_info (TSF_NO,
                                   TSF_TYPE,
                                   INITIAL_APPROVAL_IND,
                                   THREAD_NO,
                                   PHYSICAL_FROM_LOC,
                                   FROM_LOC,
                                   FROM_LOC_TYPE,
                                   PHYSICAL_TO_LOC,
                                   TO_LOC,
                                   TO_LOC_TYPE,
                                   FREIGHT_CODE,
                                   PUBLISHED)
                            values(I_tsf_no,
                                   I_tsf_type,
                                   'Y',
                                   L_num_threads,
                                   I_phy_from_loc,
                                   I_phy_from_loc,
                                   I_from_loc_type,
                                   I_phy_to_loc,
                                   I_phy_to_loc,
                                   I_to_loc_type,
                                   null,
                                   'Y');
*/
   -- 06-Jan-2010 TESCO HSC/Reshma Koshy NBS00015819 End

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_pgm,
                                                TO_CHAR(SQLCODE));
   return FALSE;
END CREATE_TSF;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--public function--
FUNCTION PUT_TSF_ITEM(O_error_message    IN OUT rtk_errors.rtk_text%TYPE,
                      I_tsf_no           IN     tsfhead.tsf_no%TYPE,
                      I_item             IN     item_master.item%TYPE,
                      I_carton           IN     shipsku.carton%TYPE,
                      I_qty              IN     tsfdetail.tsf_qty%TYPE,
                      I_weight           IN     item_loc_soh.average_weight%TYPE,
                      I_weight_uom       IN     uom_class.uom%TYPE,
                      I_inv_status       IN     inv_status_codes.inv_status%TYPE,
                      I_phy_from_loc     IN     item_loc.loc%TYPE,
                      I_from_loc_type    IN     item_loc.loc_type%TYPE,
                      I_phy_to_loc       IN     item_loc.loc%TYPE,
                      I_to_loc_type      IN     item_loc.loc_type%TYPE,
                      I_tsfhead_to_loc   IN     item_loc.loc%TYPE,
                      I_tsfhead_from_loc IN     item_loc.loc%TYPE,
                      I_tsf_type         IN     tsfhead.tsf_type%TYPE,
                      I_del_type         IN     ordcust.deliver_type%TYPE)
RETURN BOOLEAN IS

   L_tsf_qty            tsfdetail.tsf_qty%TYPE           := NULL;
   L_ship_qty           tsfdetail.ship_qty%TYPE          := NULL;
   L_tsf_seq_no         tsfdetail.tsf_seq_no%TYPE        := NULL;

   L_rcv_qty            tsfdetail.tsf_qty%TYPE := NULL;
   L_distro_qty         tsfdetail.tsf_qty%TYPE := NULL;
   L_upd_tsf_qty        tsfdetail.tsf_qty%TYPE := NULL;

   dist_cnt             BINARY_INTEGER := 1;
   item_cnt             BINARY_INTEGER := 1;

   L_item               item_master.item%TYPE := NULL;
   L_ref_item           item_master.item%TYPE := NULL;
   L_pack_ind           item_master.pack_ind%TYPE := NULL;
   L_pack_type          item_master.pack_type%TYPE := NULL;
   L_simple_pack_ind    item_master.simple_pack_ind%TYPE := NULL;
   L_catch_weight_ind   item_master.catch_weight_ind%TYPE := NULL;
   L_sellable_ind       item_master.sellable_ind%TYPE := NULL;
   L_item_xform_ind     item_master.item_xform_ind%TYPE := NULL;
   L_supp_pack_size     item_supp_country.supp_pack_size%TYPE := NULL;
   L_dept               item_master.dept%TYPE := NULL;
   L_class              item_master.class%TYPE := NULL;
   L_subclass           item_master.subclass%TYPE := NULL;
   L_ss_seq_no          shipsku.seq_no%TYPE := NULL;

   L_rowid              ROWID;

   L_table              VARCHAR2(30);
   L_key1               VARCHAR2(100);
   L_key2               VARCHAR2(100);
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);

   -- cursors
   cursor C_TSF_QTYS is
      select NVL(td.tsf_qty,0),
             NVL(td.ship_qty,0),
             td.tsf_seq_no,
             td.rowid
        from tsfdetail td
       where td.tsf_no  = I_tsf_no
         and td.item = LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item
         for update nowait;

BEGIN

   if I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_tsf_no','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item','NULL','NOT NULL');
      return FALSE;
   end if;
   if I_qty is NULL or I_qty < 0 then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_qty','NULL','NOT NULL');
      return FALSE;
   end if;

   dist_cnt := LP_bol_rec.distros.COUNT;
   item_cnt := LP_bol_rec.distros(dist_cnt).bol_items.COUNT;
   item_cnt := item_cnt + 1;

   if BOL_SQL.ITEM_CHECK(O_error_message,
                         L_item,
                         L_ref_item,
                         L_dept,
                         L_class,
                         L_subclass,
                         L_pack_ind,
                         L_pack_type,
                         L_simple_pack_ind,
                         L_catch_weight_ind,
                         L_sellable_ind,
                         L_item_xform_ind,
                         L_supp_pack_size,
                         L_ss_seq_no,
                         I_item) = FALSE then
      return FALSE;
   end if;

   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item := L_item;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ref_item := L_ref_item;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).dept := L_dept;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).class := L_class;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).subclass := L_subclass;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).pack_ind := L_pack_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).pack_type := L_pack_type;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).simple_pack_ind := L_simple_pack_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).catch_weight_ind := L_catch_weight_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).sellable_ind := L_sellable_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item_xform_ind := L_item_xform_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).supp_pack_size := L_supp_pack_size;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ss_seq_no := L_ss_seq_no;

   L_table := 'TSFDETAIL';
   L_key1 := TO_CHAR(I_tsf_no);
   L_key2 := TO_CHAR(L_tsf_seq_no);

   open C_TSF_QTYS;
   fetch C_TSF_QTYS into L_tsf_qty,
                         L_ship_qty,
                         L_tsf_seq_no,
                         L_rowid;
   close C_TSF_QTYS;

   if L_tsf_qty IS NULL then

      if LP_bol_rec.distros(dist_cnt).tsf_status = 'C' then
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_ADD_NEW_ITEM',
                                               I_item,
                                               I_tsf_no,
                                               NULL);
         return FALSE;
      end if;

      L_tsf_qty := 0;
      L_ship_qty := 0;

      --this item is not on the transfer, insert to TSFDETAIL
      --write tsf_price or tsf_cost depending on transfer type (inter vs intra).
      if INS_TSFDETAIL(O_error_message,
                       L_tsf_seq_no,
                       I_tsf_no,
                       LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item,
                       LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).supp_pack_size,
                       I_inv_status,
                       I_qty) = FALSE then
         return FALSE;
      end if;

      if I_tsf_type != 'EG' then
         if TRANSFER_CHARGE_SQL.DEFAULT_CHRGS(O_error_message,
                                              I_tsf_no,
                                              I_tsf_type,
                                              L_tsf_seq_no,
                                              NULL,              --ship_no     --only populate for EG tsfs
                                              NULL,              --ship_seq_no --only populate for EG tsfs
                                              --10-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   Begin
                                              NVL(I_tsfhead_from_loc,I_phy_from_loc),
                                              I_from_loc_type,
                                              NVL(I_tsfhead_to_loc,I_phy_to_loc),
                                              --10-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   End
                                              I_to_loc_type,
                                              LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item) = FALSE then
            return FALSE;
         end if;
      end if;

   else -- tsfdetail does exist

      if (I_tsf_type = 'CO' and I_del_type = 'S') then
         L_rcv_qty := I_qty;
      else
         L_rcv_qty := 0;
      end if;

      if (I_tsf_type = 'EG') then
         L_distro_qty := 0;
         L_upd_tsf_qty := I_qty;
      else
         L_distro_qty := I_qty;
         L_upd_tsf_qty := 0;
      end if;

      update tsfdetail td
         set td.ship_qty     = NVL(td.ship_qty, 0) + I_qty,
             td.tsf_qty      = NVL(td.tsf_qty, 0) + L_upd_tsf_qty,
             td.distro_qty   = DECODE(I_from_loc_type,
                                      'W', NVL(td.distro_qty, 0) - L_distro_qty,
                                      td.distro_qty),
             td.received_qty = NVL(td.received_qty, 0) + L_rcv_qty
       where td.rowid = L_rowid;

   end if;

   if TSF_ITEM_COMMON(O_error_message,
                      I_tsf_no,
                      I_carton,
                      I_qty,
                      I_weight,
                      I_weight_uom,
                      I_phy_from_loc,
                      I_from_loc_type,
                      I_phy_to_loc,
                      I_to_loc_type,
                      --10-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   Begin
                      NVL(I_tsfhead_to_loc,I_phy_to_loc),
                      NVL(I_tsfhead_from_loc,I_phy_from_loc),
                      --10-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   End
                      I_tsf_type,
                      I_inv_status,
                      L_tsf_qty,
                      L_ship_qty,
                      L_tsf_seq_no,
                      item_cnt,
                      dist_cnt) = FALSE then
      return FALSE;
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
                                            'BOL_SQL.PUT_TSF_ITEM',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END PUT_TSF_ITEM;
-------------------------------------------------------------------------------
FUNCTION NEW_LOC(O_error_message  IN OUT rtk_errors.rtk_text%TYPE,
                 I_item           IN     item_master.item%TYPE,
                 I_pack_ind       IN     item_master.pack_ind%TYPE,
                 I_dept           IN     item_master.dept%TYPE,
                 I_class          IN     item_master.class%TYPE,
                 I_subclass       IN     item_master.subclass%TYPE,
                 I_loc            IN     item_loc.loc%TYPE,
                 I_loc_type       IN     item_loc.loc_type%TYPE)
RETURN BOOLEAN IS
BEGIN
   if NEW_ITEM_LOC(O_error_message,
                   I_item,
                   I_loc,
                   NULL, NULL, I_loc_type, NULL,
                   I_dept,
                   I_class,
                   I_subclass,
                   NULL, NULL, NULL,
                   NULL, NULL, NULL, NULL, NULL,
                   I_pack_ind,
                   NULL, NULL, NULL, NULL, NULL, NULL,
                   NULL, NULL, NULL, NULL, NULL, NULL,
                   NULL, NULL, NULL, NULL, NULL, NULL,
                   NULL, NULL, NULL, NULL, NULL) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.NEW_LOC',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END NEW_LOC;
-------------------------------------------------------------------------------
FUNCTION ITEM_CHECK(O_error_message    IN OUT rtk_errors.rtk_text%TYPE,
                    O_tran_item        IN OUT item_master.item%TYPE,
                    O_ref_item         IN OUT item_master.item%TYPE,
                    O_dept             IN OUT item_master.dept%TYPE,
                    O_class            IN OUT item_master.class%TYPE,
                    O_subclass         IN OUT item_master.subclass%TYPE,
                    O_pack_ind         IN OUT item_master.pack_ind%TYPE,
                    O_pack_type        IN OUT item_master.pack_type%TYPE,
                    O_simple_pack_ind  IN OUT item_master.simple_pack_ind%TYPE,
                    O_catch_weight_ind IN OUT item_master.catch_weight_ind%TYPE,
                    O_sellable_ind     IN OUT item_master.item_xform_ind%TYPE,
                    O_item_xform_ind   IN OUT item_master.item_xform_ind%TYPE,
                    O_supp_pack_size   IN OUT item_supp_country.supp_pack_size%TYPE,
                    O_ss_seq_no        IN OUT shipsku.seq_no%TYPE,
                    I_input_item       IN     item_master.item%TYPE)
RETURN BOOLEAN IS

   L_sellable_ind 	ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind	ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_inventory_ind	ITEM_MASTER.INVENTORY_IND%TYPE;

   -- cursors
   cursor C_ITEM_EXIST is
      select im1.item,
             im1.dept,
             im1.class,
             im1.subclass,
             im1.pack_ind,
             NVL(im1.pack_type, 'N'),
             im1.simple_pack_ind,
             im1.catch_weight_ind,
             im1.sellable_ind,
             im1.item_xform_ind,
             im1.orderable_ind,
             im1.inventory_ind
        from item_master im1,
             item_master im2
       where (im2.item       = I_input_item and
              im2.item_level = im2.tran_level and
              im1.item       = im2.item)
              -- if item is below the tran level,
              -- get its tran level parent
          or (im2.item       = I_input_item and
              im2.item_level = im2.tran_level + 1 and
              im1.item      = im2.item_parent);

BEGIN
   open C_ITEM_EXIST;
   fetch C_ITEM_EXIST into O_tran_item,
                           O_dept,
                           O_class,
                           O_subclass,
                           O_pack_ind,
                           O_pack_type,
                           O_simple_pack_ind,
                           O_catch_weight_ind,
                           O_sellable_ind,
                           O_item_xform_ind,
                           L_orderable_ind,
                           L_inventory_ind;

   if C_ITEM_EXIST%NOTFOUND then
      close C_ITEM_EXIST;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM', I_input_item, NULL, NULL);
      return FALSE;
   end if;
   close C_ITEM_EXIST;
   ---
   if L_orderable_ind = 'Y' and
      L_sellable_ind  = 'N' and
      L_inventory_ind = 'N' then
      O_error_message := SQL_LIB.CREATE_MSG('NO_NONINVENT_ITEM', O_tran_item, NULL, NULL);
      return FALSE;
   end if;

   --for non-orderable packs(pack_type of NULL), use 1 as supp_pack_size
   if O_pack_ind = 'Y' and O_pack_type = 'N' then
      O_supp_pack_size := 1;
   else
      if SUPP_ITEM_ATTRIB_SQL.GET_SUPP_PACK_SIZE(O_error_message,
                                                 O_supp_pack_size,
                                                 O_tran_item,
                                                 NULL,
                                                 NULL) = FALSE then
         return FALSE;
      end if;
   end if;

   if O_tran_item != I_input_item then
      O_ref_item := I_input_item;
   else
      O_ref_item := NULL;
   end if;

   if NEXT_SS_SEQ_NO(O_error_message,
                     O_ss_seq_no) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.ITEM_CHECK',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END ITEM_CHECK;
-------------------------------------------------------------------------------
FUNCTION INS_TSFDETAIL(O_error_message     IN OUT rtk_errors.rtk_text%TYPE,
                       O_tsf_seq_no        IN OUT tsfdetail.tsf_seq_no%TYPE,
                       I_tsf_no            IN     tsfhead.tsf_no%TYPE,
                       I_item              IN     item_master.item%TYPE,
                       I_supp_pack_size    IN     item_supp_country.supp_pack_size%TYPE,
                       I_inv_status        IN     tsfdetail.inv_status%TYPE,
                       I_tsf_qty           IN     tsfdetail.tsf_qty%TYPE)
RETURN BOOLEAN IS

   L_inv_status		tsfdetail.inv_status%TYPE := NULL;

   -- cursors
   cursor C_MAX_SEQ is
      select NVL(MAX(td.tsf_seq_no), 0)
        from tsfdetail td
       where td.tsf_no = I_tsf_no;

BEGIN

   if I_inv_status != -1 then
      L_inv_status := I_inv_status;
   end if;

   O_tsf_seq_no := 0;
   open C_MAX_SEQ;
   fetch C_MAX_SEQ into O_tsf_seq_no;
   close C_MAX_SEQ;
   O_tsf_seq_no := O_tsf_seq_no + 1;

   --Since external transfers will have physical locations written to TSFHEAD,
   --and physical wh does not belong to a transfer entity, we cannot determine
   --if a transfer is inter or intracompany, and determine if tsf_price or
   --tsf_cost should be written. Therefore, we will NOT write TSF_COST and TSF_PRICE.
   insert into tsfdetail (tsf_no,
                          tsf_seq_no,
                          item,
                          inv_status,
                          tsf_price,
                          tsf_cost,
                          tsf_qty,
                          fill_qty,
                          distro_qty,
                          selected_qty,
                          cancelled_qty,
                          ship_qty,
                          received_qty,
                          supp_pack_size,
                          tsf_po_link_no,
                          mbr_processed_ind,
                          publish_ind)
                   values(I_tsf_no,
                          O_tsf_seq_no,
                          I_item,
                          L_inv_status,
                          NULL,      --tsf_price
                          NULL,      --tsf_cost
                          I_tsf_qty, --tsf_qty
                          0,         --fill_qty
                          0,         --distro_qty
                          0,         --selected_qty
                          0,         --cancelled_qty
                          I_tsf_qty, --ship_qty
                          0,         --received_qty
                          I_supp_pack_size,
                          NULL,
                          NULL,
                          'Y');

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.INS_TSFDETAIL',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END INS_TSFDETAIL;
-------------------------------------------------------------------------------
FUNCTION CREATE_TSF_INV_MAP(O_error_message IN OUT rtk_errors.rtk_text%TYPE,
                            I_tsf_no        IN     tsfhead.tsf_no%TYPE,
                            I_item          IN     item_master.item%TYPE,
                            I_pack_ind      IN     item_master.pack_ind%TYPE,
                            I_inv_status    IN     shipsku.inv_status%TYPE,
                            I_tsf_seq_no    IN     tsfdetail.tsf_seq_no%TYPE,
                            I_phy_from_loc  IN     item_loc.loc%TYPE,
                            I_from_loc_type IN     item_loc.loc_type%TYPE,
                            I_phy_to_loc    IN     item_loc.loc%TYPE,
                            I_to_loc_type   IN     item_loc.loc_type%TYPE,
                            I_tsf_qty       IN     item_loc_soh.stock_on_hand%TYPE)
RETURN BOOLEAN IS

   L_to_array   bol_sql.inv_flow_array;
   L_from_array bol_sql.inv_flow_array;

   from_cnt BINARY_INTEGER := 1;
   to_cnt   BINARY_INTEGER := 1;
   L_keepgoing BOOLEAN := TRUE;

BEGIN
   /******************************************************************************
    *
    * When EG transfers are sent to us by, they are sent by physical locations.
    *  Inventory is held at the virtual location level.  This function will determine
    *  which virtual locations should have their inventory effected when this happens.
    *
    *  1) Fill an array with all possible from locations
    *
    *  2) Call the distribution package to determine which of the possible from locs
    *     should actually have their stock pulled.
    *
    *  3) Fill an array with all possible to locations
    *
    *  4) Map each of from locations that have stock being pulled from them to one of
    *     the possible to locations.
    *
    * *NOTE: when multi-channel is being used it only applied to wh locations.
    *        all stores are stock holding locations and should be used in the mapping.
    *
    * *NOTE: when multi-channel is not being used, the message are sent by
    *        being sent by stock holding locattions.  The mapping should return
    *        the locations contained in the message.
    *
    ******************************************************************************/

   --load array for from loc
   if BOL_SQL.LOAD_INV_FLOW_LOC(O_error_message,
                                L_from_array,
                                'F',             --from_loc
                                I_phy_from_loc,
                                I_from_loc_type,
                                I_phy_to_loc,  --other loc
                                I_to_loc_type, --other loc type
                                I_item,
                                I_pack_ind) = FALSE then
      return FALSE;
   end if;

   --Reject if pack item is sent and the from location does
   --not stock packs (receive as Each wh).
   --One element will always exist on from flow array, receive_as_type
   --will be the same in all elements of the array so just look at first one.

   if I_pack_ind = 'Y' and
      L_from_array(1).receive_as_type = 'E' and
      I_from_loc_type = 'W' then
      O_error_message := SQL_LIB.CREATE_MSG('NO_PACK_STOCK',to_char(I_phy_from_loc),
                                             null,null);
      return FALSE;
   end if;

   --use library to distribute from loc qtys
   if BOL_SQL.DIST_FROM_LOC(O_error_message,
                            L_from_array,
                            I_item,
                            I_inv_status,
                            I_tsf_qty,
                            I_phy_to_loc,
                            I_to_loc_type,
                            I_phy_from_loc,
                            I_from_loc_type) = FALSE then
      return FALSE;
   end if;

   --load array for to loc
   if BOL_SQL.LOAD_INV_FLOW_LOC(O_error_message,
                                L_to_array,
                                'T',             --to_loc
                                I_phy_to_loc,
                                I_to_loc_type,
                                I_phy_from_loc,  --other loc
                                I_from_loc_type, --other loc type
                                I_item,
                                I_pack_ind) = FALSE then
      return FALSE;
   end if;

   /*
    * Assign from loc qtys to to locations:
    *   Walk through all the from locations, attempt to map each
    *   from location that has qty assigned to it to a to location.
    *
    *   First try to assign the qty to a to loc that has an item_loc
    *   of status A, if one cannot be found, attempt to assign the qty
    *   to a to loc that has an item_loc status of C.
    *
    *   If any qty assigned to a from loc can not be mapped to a to
    *   loc reject the transaction.
    */
   FOR from_cnt IN L_from_array.FIRST..L_from_array.LAST LOOP
      L_keepgoing := TRUE;

      --if the loc did not get any qty distributed to it, skip it
      if L_from_array(from_cnt).qty IS NULL then
         L_keepgoing := FALSE;
      end if;

      if L_keepgoing = TRUE then
         --apply rules for locs in approved (A) status
         if FIND_MAP(O_error_message,
                     L_keepgoing,
                     L_from_array(from_cnt).loc,
                     I_from_loc_type,
                     L_from_array(from_cnt).qty,
                     'A',
                     L_from_array(from_cnt).channel_id,
                     L_from_array(from_cnt).channel_type,
                     L_to_array) = FALSE then
            return FALSE;
         end if;
      end if;

      if L_keepgoing = TRUE then
         --apply rules for locs in discontinued (C) status
         if FIND_MAP(O_error_message,
                     L_keepgoing,
                     L_from_array(from_cnt).loc,
                     I_from_loc_type,
                     L_from_array(from_cnt).qty,
                     'C',
                     L_from_array(from_cnt).channel_id,
                     L_from_array(from_cnt).channel_type,
                     L_to_array) = FALSE then
            return FALSE;
         end if;
      end if;

      if L_keepgoing = TRUE then
         O_error_message := SQL_LIB.CREATE_MSG('NO_MAP_POSSIBLE',null,null,null);
         return FALSE;
      end if;

   END LOOP; --from loop

   if INS_TSF_INV_FLOW(O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.CREATE_TSF_INV_MAP',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END CREATE_TSF_INV_MAP;
-------------------------------------------------------------------------------
FUNCTION LOAD_INV_FLOW_LOC(O_error_message  IN OUT rtk_errors.rtk_text%TYPE,
                           O_inv_flow_array IN OUT bol_sql.inv_flow_array,
                           I_to_from_ind    IN     VARCHAR2,
                           I_phy_loc        IN     item_loc.loc%TYPE,
                           I_loc_type       IN     item_loc.loc_type%TYPE,
                           I_other_loc      IN     item_loc.loc%TYPE,
                           I_other_loc_type IN     item_loc.loc_type%TYPE,
                           I_item           IN     item_master.item%TYPE,
                           I_pack_ind       IN     ITEM_MASTER.PACK_IND%TYPE)
RETURN BOOLEAN IS

   i BINARY_INTEGER := 1;
   L_order_helper NUMBER(1);
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
   L_protected_ind  VARCHAR2(1);
   L_restricted_ind VARCHAR2(1);
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
   L_prim_ind     NUMBER(1);
   L_loc          item_loc.loc%TYPE := NULL;
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
   L_intercompany_tsf_sys_opt   SYSTEM_OPTIONS.INTERCOMPANY_TRANSFER_IND%TYPE := NULL;
   L_financial_ap               SYSTEM_OPTIONS.FINANCIAL_AP%TYPE              := NULL;
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End

   /******************************************************************************
    *
    *  For EG transfers, given a physical locations, load an array of all
    *  possible virtuals.  The array of virtuals will be used to create
    *  inventory flows.  The inventory flows are where the actual movement
    *  of stock takes place.
    *
    *  Physical location is a store.
    *     Call NEW_ITEM_LOC to ensure the relationship exists.
    *     Add the store to the output array (FINISHED).
    *
    *  Physical location is a wh.
    *
    *     Load all virtual with in the physical that stock the item being
    *     transferred into the output array.
    *
    *     If the array contains records (FINISHED)
    *
    *     If the array does not contain records, an item loc relationship
    *     does not exist between the item and any of the virtuals in the
    *     passed in physical wh, we need to create a relationship between
    *     the item and one of the virtuals (in a single channel environment
    *     the wh itself will always be returned by these cursor):
    *
    *       if the passed in loc is a phy_wh and the other loc is a wh create
    *          the relationship for the first vwh found in this order:
    *         -- primary not protected/restricted*
    *         -- low number not protected/restricted*
    *         -- primary protected/restricted*
    *
    *       if the passed in loc is a phy_wh and the other loc is a store
    *          create the relationship for the first vwh found in this order:
    *             -- channel_id match
    *             -- low number channel_type match not protected/restricted*
    *             -- low number channel_type match protected/restricted*
    *             -- primary not protected/restricted*
    *             -- low number not protected/restricted*
    *             -- primary protected/restricted*
    *
    *       * use protected when pulling stock(from loc)
    *       * use restricted when pushing stock(to_loc)
    *
    *     After creating the relationship, load its information into the
    *     output array (FINISHED).
    *
    *****************************************************************************/

   -- cursors
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
   cursor C_GET_VWH_4 is
      select I_phy_loc phy_loc,
             w.wh loc,
             I_loc_type loc_type,
             il.status status,
             NVL(il.receive_as_type, 'E') receive_as_type,
             c.channel_id channel_id,
             c.channel_type channel_type,
             w2.primary_vwh primary_vwh,
             w.protected_ind protected_ind,
             w.restricted_ind restricted_ind
        from wh w,
             wh w2,
             item_loc il,
             channels c
       where w.physical_wh      = I_phy_loc
         and w.stockholding_ind = 'Y'
         and il.loc             = w.wh
         and il.item            = I_item
         and w.channel_id       = c.channel_id(+)
         and w2.wh              = I_phy_loc
         and w2.finisher_ind    = 'N'
    order by w.wh;

   cursor C_GET_VWH_1 is
      select I_phy_loc phy_loc,
             w.wh loc,
             I_loc_type loc_type,
             il.status status,
             NVL(il.receive_as_type, 'E') receive_as_type,
             c.channel_id channel_id,
             c.channel_type channel_type,
             w2.primary_vwh primary_vwh,
             w.protected_ind protected_ind,
             w.restricted_ind restricted_ind
        from wh w,
             wh w2,
             item_loc il,
             channels c,
             store s
       where w.physical_wh      = I_phy_loc
         and w.stockholding_ind = 'Y'
         and il.loc             = w.wh
         and il.item            = I_item
         and s.store            = I_other_loc
         and NVL(s.org_unit_id,0) = NVL(w.org_unit_id,0)
         and s.tsf_entity_id    = w.tsf_entity_id
         and w.channel_id       = c.channel_id
         and w.channel_id       = s.channel_id
         and w2.wh              = I_phy_loc
         and w2.finisher_ind    = 'N'
    order by w.wh;

   cursor C_GET_VWH_2 is
      select I_phy_loc phy_loc,
             w.wh loc,
             I_loc_type loc_type,
             il.status status,
             NVL(il.receive_as_type, 'E') receive_as_type,
             c.channel_id channel_id,
             c.channel_type channel_type,
             w2.primary_vwh primary_vwh,
             w.protected_ind protected_ind,
             w.restricted_ind restricted_ind
        from wh w,
             wh w2,
             item_loc il,
             channels c,
             store s
       where w.physical_wh      = I_phy_loc
         and w.stockholding_ind = 'Y'
         and il.loc             = w.wh
         and il.item            = I_item
         and s.store            = I_other_loc
         and NVL(s.org_unit_id,0) = NVL(w.org_unit_id,0)
         and w.channel_id       = c.channel_id
         and s.channel_id       = w.channel_id
         and w2.wh              = I_phy_loc
         and w2.finisher_ind    = 'N'
    order by w.wh;

   cursor C_GET_VWH_3 is
      select I_phy_loc phy_loc,
             w.wh loc,
             I_loc_type loc_type,
             il.status status,
             NVL(il.receive_as_type, 'E') receive_as_type,
             c.channel_id channel_id,
             c.channel_type channel_type,
             w2.primary_vwh primary_vwh,
             w.protected_ind protected_ind,
             w.restricted_ind restricted_ind
        from wh w,
             wh w2,
             item_loc il,
             channels c,
             store s
       where w.physical_wh      = I_phy_loc
         and w.stockholding_ind = 'Y'
         and il.loc             = w.wh
         and il.item            = I_item
         and s.store            = I_other_loc
         and s.tsf_entity_id    = w.tsf_entity_id
         and w.channel_id       = c.channel_id
         and w.channel_id       = s.channel_id
         and w2.wh              = I_phy_loc
         and w2.finisher_ind    = 'N'
    order by w.wh;
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
   cursor C_GET_STORE is
      select I_phy_loc,
             s.store,
             I_loc_type,
             il.status,
             NVL(il.receive_as_type, 'E'),
             c.channel_id,
             c.channel_type,
             I_phy_loc,
             'N',
             'N'
        from store s,
             item_loc il,
             channels c
       where s.store         = I_phy_loc
         and il.loc          = s.store
         and il.item         = I_item
         and s.channel_id    = c.channel_id(+);

   cursor C_PRIM_VWH is
      select vir_w.wh wh,
             --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
             vir_w.protected_ind,
             vir_w.restricted_ind
             --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
        from wh phy_w,
             wh vir_w
       where vir_w.physical_wh         = I_phy_loc
         and vir_w.stockholding_ind    = 'Y'
         and phy_w.physical_wh(+)      = vir_w.physical_wh
         and phy_w.stockholding_ind(+) = 'N'
      --order by
      -- primary not protected
      -- low number not protected
      -- primary protected
      -- low number protected
      order by DECODE(I_to_from_ind,
                      'F', vir_w.protected_ind,
                      'T', vir_w.restricted_ind),
                      ABS(SIGN(phy_w.primary_vwh - vir_w.wh));
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
   --Removed the cursor C_MAP_WH.
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End

   cursor C_GET_FROM_VWH is
      select I_phy_loc phy_loc,
             w.wh loc,
             I_loc_type loc_type,
             il.status status,
             NVL(il.receive_as_type, 'E') receive_as_type,
             c.channel_id channel_id,
             c.channel_type channel_type,
             w2.primary_vwh primary_vwh,
             w.protected_ind protected_ind,
             w.restricted_ind restricted_ind
        from wh w,
             wh w2,
             item_loc il,
             channels c,
             store s
       where w.physical_wh      = I_phy_loc
         and w.stockholding_ind = 'Y'
         and il.loc             = w.wh
         and il.item            = I_item
         and w.channel_id       = c.channel_id(+)
         and w2.wh              = I_phy_loc
         and w.tsf_entity_id    = s.tsf_entity_id
         --16-May-2008--WiproEnabler/Karthik--NBS00006616--Begin
         and s.store            = I_other_loc
         --16-May-2008--WiproEnabler/Karthik--NBS00006616--End
         and rownum             = 1;

   cursor C_PRIM_FROM_VWH is
      select vir_w.wh wh
        from wh phy_w,
             wh vir_w,
             store s
       where vir_w.physical_wh         = I_phy_loc
         and vir_w.stockholding_ind    = 'Y'
         and vir_w.tsf_entity_id       = s.tsf_entity_id
         --16-May-2008--WiproEnabler/Karthik--NBS00006616--Begin
         and s.store                   = I_other_loc
         --16-May-2008--WiproEnabler/Karthik--NBS00006616--End
         and phy_w.primary_vwh(+)      = vir_w.wh
         and phy_w.physical_wh(+)      = vir_w.physical_wh
         and phy_w.stockholding_ind(+) = 'N'
         and rownum                    = 1
      order by vir_w.protected_ind;

BEGIN
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
   if SYSTEM_OPTIONS_SQL.GET_FINANCIAL_AP(O_error_message,
                                          L_financial_ap) = FALSE then
      return FALSE;
   end if;

   if SYSTEM_OPTIONS_SQL.GET_INTERCOMPANY_TRANSFER_IND(O_error_message,
                                                       L_intercompany_tsf_sys_opt) = FALSE then
      return FALSE;
   end if;
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End

   if I_loc_type = 'S' then
      if NEW_LOC(O_error_message,
                 I_item,
                 I_pack_ind,
                 NULL, NULL, NULL,
                 I_phy_loc,
                 'S') = FALSE then
         return FALSE;
      end if;

      i := 1;

      open C_GET_STORE;
      fetch  C_GET_STORE into O_inv_flow_array(i).phy_loc,
                              O_inv_flow_array(i).loc,
                              O_inv_flow_array(i).loc_type,
                              O_inv_flow_array(i).status,
                              O_inv_flow_array(i).receive_as_type,
                              O_inv_flow_array(i).channel_id,
                              O_inv_flow_array(i).channel_type,
                              O_inv_flow_array(i).primary_vwh,
                              O_inv_flow_array(i).protected_ind,
                              O_inv_flow_array(i).restricted_ind;
      close C_GET_STORE;
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
   elsif I_loc_type = 'W' and I_to_from_ind in ('T','F') THEN
   --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End

      i := 0;
      --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
      if NVL(L_financial_ap,'X') = 'O' and L_intercompany_tsf_sys_opt = 'Y' then
         --Opening the cursor C_GET_VWH_1
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VWH_1',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || I_item);

         FOR rec IN C_GET_VWH_1
         LOOP
            i := i + 1;
            O_inv_flow_array(i).phy_loc         := rec.phy_loc;
            O_inv_flow_array(i).loc             := rec.loc;
            O_inv_flow_array(i).loc_type        := rec.loc_type;
            O_inv_flow_array(i).status          := rec.status;
            O_inv_flow_array(i).receive_as_type := rec.receive_as_type;
            O_inv_flow_array(i).channel_id      := rec.channel_id;
            O_inv_flow_array(i).channel_type    := rec.channel_type;
            O_inv_flow_array(i).primary_vwh     := rec.primary_vwh;
            O_inv_flow_array(i).protected_ind   := rec.protected_ind;
            O_inv_flow_array(i).restricted_ind  := rec.restricted_ind;
         END LOOP;
         --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
         if i = 0 then
            --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
            --Open cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('OPEN',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            open C_PRIM_VWH;
            --Fetch cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('FETCH',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            fetch C_PRIM_VWH into L_loc,
                                  L_protected_ind,
                                  L_restricted_ind;
            --Close the cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('CLOSE',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
            close C_PRIM_VWH;
            if NEW_LOC(O_error_message,
                       I_item,
                       I_pack_ind,
                       NULL, NULL, NULL,
                       L_loc,
                       'W') = FALSE then
               return FALSE;
            end if;
            --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
            --Opening the cursor C_GET_VWH_1
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_VWH_1',
                             'WH,ITEM_LOC,CHANNELS,STORE',
                             'ITEM: ' || I_item);
            FOR rec IN C_GET_VWH_1
            LOOP
               i := i + 1;
               O_inv_flow_array(i).phy_loc         := rec.phy_loc;
               O_inv_flow_array(i).loc             := rec.loc;
               O_inv_flow_array(i).loc_type        := rec.loc_type;
               O_inv_flow_array(i).status          := rec.status;
               O_inv_flow_array(i).receive_as_type := rec.receive_as_type;
               O_inv_flow_array(i).channel_id      := rec.channel_id;
               O_inv_flow_array(i).channel_type    := rec.channel_type;
               O_inv_flow_array(i).primary_vwh     := rec.primary_vwh;
               O_inv_flow_array(i).protected_ind   := rec.protected_ind;
               O_inv_flow_array(i).restricted_ind  := rec.restricted_ind;
            END LOOP;
            if i = 0 then
               i := i + 1;
               O_inv_flow_array(i).phy_loc         := I_phy_loc;
               O_inv_flow_array(i).loc             := L_loc;
               O_inv_flow_array(i).loc_type        := I_loc_type;
               O_inv_flow_array(i).status          := 'A';
               O_inv_flow_array(i).receive_as_type := NULL;
               O_inv_flow_array(i).channel_id      := NULL;
               O_inv_flow_array(i).channel_type    := NULL;
               O_inv_flow_array(i).primary_vwh     := L_loc;
               O_inv_flow_array(i).protected_ind   := L_protected_ind;
               O_inv_flow_array(i).restricted_ind  := L_restricted_ind;
            end if;

         end if;
      elsif NVL(L_financial_ap,'X') = 'O' and L_intercompany_tsf_sys_opt = 'N' then
         --Opening the cursor C_GET_VWH_2
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VWH_2',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || I_item);
         FOR rec IN C_GET_VWH_2
         LOOP
            i := i + 1;
            O_inv_flow_array(i).phy_loc         := rec.phy_loc;
            O_inv_flow_array(i).loc             := rec.loc;
            O_inv_flow_array(i).loc_type        := rec.loc_type;
            O_inv_flow_array(i).status          := rec.status;
            O_inv_flow_array(i).receive_as_type := rec.receive_as_type;
            O_inv_flow_array(i).channel_id      := rec.channel_id;
            O_inv_flow_array(i).channel_type    := rec.channel_type;
            O_inv_flow_array(i).primary_vwh     := rec.primary_vwh;
            O_inv_flow_array(i).protected_ind   := rec.protected_ind;
            O_inv_flow_array(i).restricted_ind  := rec.restricted_ind;
         END LOOP;
         if i = 0 then
            --Opening the cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('OPEN',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            open C_PRIM_VWH;
            --Fetch cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('FETCH',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            fetch C_PRIM_VWH into L_loc,
                                  L_protected_ind,
                                  L_restricted_ind;
            --Close the cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('CLOSE',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            close C_PRIM_VWH;
            --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
            if NEW_LOC(O_error_message,
                       I_item,
                       I_pack_ind,
                       NULL, NULL, NULL,
                       L_loc,
                       'W') = FALSE then
               return FALSE;
            end if;
            --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
            --Opening the cursor C_GET_VWH_2
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_VWH_2',
                             'WH,ITEM_LOC,CHANNELS,STORE',
                             'ITEM: ' || I_item);
            FOR rec in C_GET_VWH_2
            LOOP
               i := i + 1;
               O_inv_flow_array(i).phy_loc         := rec.phy_loc;
               O_inv_flow_array(i).loc             := rec.loc;
               O_inv_flow_array(i).loc_type        := rec.loc_type;
               O_inv_flow_array(i).status          := rec.status;
               O_inv_flow_array(i).receive_as_type := rec.receive_as_type;
               O_inv_flow_array(i).channel_id      := rec.channel_id;
               O_inv_flow_array(i).channel_type    := rec.channel_type;
               O_inv_flow_array(i).primary_vwh     := rec.primary_vwh;
               O_inv_flow_array(i).protected_ind   := rec.protected_ind;
               O_inv_flow_array(i).restricted_ind  := rec.restricted_ind;
            END LOOP;
            if i = 0 then
               i := i + 1;
               O_inv_flow_array(i).phy_loc         := I_phy_loc;
               O_inv_flow_array(i).loc             := L_loc;
               O_inv_flow_array(i).loc_type        := I_loc_type;
               O_inv_flow_array(i).status          := 'A';
               O_inv_flow_array(i).receive_as_type := NULL;
               O_inv_flow_array(i).channel_id      := NULL;
               O_inv_flow_array(i).channel_type    := NULL;
               O_inv_flow_array(i).primary_vwh     := L_loc;
               O_inv_flow_array(i).protected_ind   := L_protected_ind;
               O_inv_flow_array(i).restricted_ind  := L_restricted_ind;
            end if;
            --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
         end if;
      --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
      elsif NVL(L_financial_ap,'X') != 'O' and L_intercompany_tsf_sys_opt = 'Y' then
         --Opening the cursor C_GET_VWH_3
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VWH_3',
                          'WH,ITEM_LOC,CHANNELS,STORE',
                          'ITEM: ' || I_item);
         FOR rec IN C_GET_VWH_3
         LOOP
            i := i + 1;
            O_inv_flow_array(i).phy_loc         := rec.phy_loc;
            O_inv_flow_array(i).loc             := rec.loc;
            O_inv_flow_array(i).loc_type        := rec.loc_type;
            O_inv_flow_array(i).status          := rec.status;
            O_inv_flow_array(i).receive_as_type := rec.receive_as_type;
            O_inv_flow_array(i).channel_id      := rec.channel_id;
            O_inv_flow_array(i).channel_type    := rec.channel_type;
            O_inv_flow_array(i).primary_vwh     := rec.primary_vwh;
            O_inv_flow_array(i).protected_ind   := rec.protected_ind;
            O_inv_flow_array(i).restricted_ind  := rec.restricted_ind;
         END LOOP;
         if i = 0 then
            --Open cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('OPEN',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            open C_PRIM_VWH;
            --Fetch cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('FETCH',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            fetch C_PRIM_VWH into L_loc,
                                  L_protected_ind,
                                  L_restricted_ind;
            --Close the cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('CLOSE',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            close C_PRIM_VWH;
            if NEW_LOC(O_error_message,
                       I_item,
                       I_pack_ind,
                       NULL,
                       NULL,
                       NULL,
                       L_loc,
                       'W') = FALSE then
               return FALSE;
            end if;
            --Opening the cursor C_GET_VWH_3
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_VWH_3',
                             'WH,ITEM_LOC,CHANNELS,STORE',
                             'ITEM: ' || I_item);
            FOR rec IN C_GET_VWH_3
            LOOP
               i := i + 1;
               O_inv_flow_array(i).phy_loc         := rec.phy_loc;
               O_inv_flow_array(i).loc             := rec.loc;
               O_inv_flow_array(i).loc_type        := rec.loc_type;
               O_inv_flow_array(i).status          := rec.status;
               O_inv_flow_array(i).receive_as_type := rec.receive_as_type;
               O_inv_flow_array(i).channel_id      := rec.channel_id;
               O_inv_flow_array(i).channel_type    := rec.channel_type;
               O_inv_flow_array(i).primary_vwh     := rec.primary_vwh;
               O_inv_flow_array(i).protected_ind   := rec.protected_ind;
               O_inv_flow_array(i).restricted_ind  := rec.restricted_ind;
            END LOOP;
            if i = 0 then
               i := i + 1;
               O_inv_flow_array(i).phy_loc         := I_phy_loc;
               O_inv_flow_array(i).loc             := L_loc;
               O_inv_flow_array(i).loc_type        := I_loc_type;
               O_inv_flow_array(i).status          := 'A';
               O_inv_flow_array(i).receive_as_type := NULL;
               O_inv_flow_array(i).channel_id      := NULL;
               O_inv_flow_array(i).channel_type    := NULL;
               O_inv_flow_array(i).primary_vwh     := L_loc;
               O_inv_flow_array(i).protected_ind   := L_protected_ind;
               O_inv_flow_array(i).restricted_ind  := L_restricted_ind;
            end if;
            --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
         end if;
      --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--Begin
      elsif NVL(L_financial_ap,'X') != 'O' and L_intercompany_tsf_sys_opt = 'N' then
         --Opening the cursor C_GET_VWH_4
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_VWH_4',
                          'WH,ITEM_LOC,CHANNELS',
                          'ITEM: ' || I_item);
         FOR rec IN C_GET_VWH_4
         LOOP
            i := i + 1;
            O_inv_flow_array(i).phy_loc         := rec.phy_loc;
            O_inv_flow_array(i).loc             := rec.loc;
            O_inv_flow_array(i).loc_type        := rec.loc_type;
            O_inv_flow_array(i).status          := rec.status;
            O_inv_flow_array(i).receive_as_type := rec.receive_as_type;
            O_inv_flow_array(i).channel_id      := rec.channel_id;
            O_inv_flow_array(i).channel_type    := rec.channel_type;
            O_inv_flow_array(i).primary_vwh     := rec.primary_vwh;
            O_inv_flow_array(i).protected_ind   := rec.protected_ind;
            O_inv_flow_array(i).restricted_ind  := rec.restricted_ind;
         END LOOP;
         if i = 0 then
            --Open cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('OPEN',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            open C_PRIM_VWH;
            --Fetch cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('FETCH',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            fetch C_PRIM_VWH into L_loc,
                                  L_protected_ind,
                                  L_restricted_ind;
            --Close the cursor C_PRIM_VWH
            SQL_LIB.SET_MARK('CLOSE',
                             'C_PRIM_VWH',
                             'WH',
                             'PHYSICAL_WH :' || I_phy_loc);
            close C_PRIM_VWH;
            if NEW_LOC(O_error_message,
                       I_item,
                       I_pack_ind,
                       NULL,
                       NULL,
                       NULL,
                       L_loc,
                       'W') = FALSE then
               return FALSE;
            end if;
            --Opening the cursor C_GET_VWH_4
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_VWH_4',
                             'WH,ITEM_LOC,CHANNELS',
                             'ITEM: ' || I_item);
            FOR rec IN C_GET_VWH_4
            LOOP
               i := i + 1;
               O_inv_flow_array(i).phy_loc         := rec.phy_loc;
               O_inv_flow_array(i).loc             := rec.loc;
               O_inv_flow_array(i).loc_type        := rec.loc_type;
               O_inv_flow_array(i).status          := rec.status;
               O_inv_flow_array(i).receive_as_type := rec.receive_as_type;
               O_inv_flow_array(i).channel_id      := rec.channel_id;
               O_inv_flow_array(i).channel_type    := rec.channel_type;
               O_inv_flow_array(i).primary_vwh     := rec.primary_vwh;
               O_inv_flow_array(i).protected_ind   := rec.protected_ind;
               O_inv_flow_array(i).restricted_ind  := rec.restricted_ind;
            END LOOP;
            if i = 0 then
               i := i + 1;
               O_inv_flow_array(i).phy_loc         := I_phy_loc;
               O_inv_flow_array(i).loc             := L_loc;
               O_inv_flow_array(i).loc_type        := I_loc_type;
               O_inv_flow_array(i).status          := 'A';
               O_inv_flow_array(i).receive_as_type := NULL;
               O_inv_flow_array(i).channel_id      := NULL;
               O_inv_flow_array(i).channel_type    := NULL;
               O_inv_flow_array(i).primary_vwh     := L_loc;
               O_inv_flow_array(i).protected_ind   := L_protected_ind;
               O_inv_flow_array(i).restricted_ind  := L_restricted_ind;
            end if;
         end if;
         --17-Mar-2008--WiproEnabler/Karthik--Bug6371616/NBS00004699--End
      end if;
   end if;

   /* ASSERT -- if this happens there is bad data */
   if i = 0 then
      O_error_message := SQL_LIB.CREATE_MSG('NO_MAP_POSSIBLE',null,null,null);
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.LOAD_INV_FLOW_LOC',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END LOAD_INV_FLOW_LOC;
-------------------------------------------------------------------------------
FUNCTION DIST_FROM_LOC(O_error_message  IN OUT rtk_errors.rtk_text%TYPE,
                       I_inv_flow_array IN OUT bol_sql.inv_flow_array,
                       I_item           IN     item_master.item%TYPE,
                       I_inv_status     IN     shipsku.inv_status%TYPE,
                       I_tsf_qty        IN     item_loc_soh.stock_on_hand%TYPE,
                       I_phy_to_loc     IN     item_loc.loc%TYPE,
                       I_to_loc_type    IN     item_loc.loc_type%TYPE,
                       I_phy_from_loc   IN     item_loc.loc%TYPE,
                       I_from_loc_type  IN     item_loc.loc_type%TYPE)
RETURN BOOLEAN IS

   L_to_loc      item_loc.loc%TYPE      := NULL;
   L_to_loc_type item_loc.loc_type%TYPE := NULL;
   L_inv_status  shipsku.inv_status%TYPE := NULL;

   dist_cnt      BINARY_INTEGER := 1;
   flow_cnt      BINARY_INTEGER := 1;
   L_dist_array  DISTRIBUTION_SQL.DIST_TABLE_TYPE;

BEGIN
   if I_inv_status IS NOT NULL and I_inv_status != -1 then
      L_inv_status := I_inv_status;
   end if;

   --if the from loc is a store, the flow array contains only the store
   --give it the entire qty.
   if I_from_loc_type = 'S' then
      I_inv_flow_array(1).qty := I_tsf_qty;
      return TRUE;
   end if;

   if I_to_loc_type = 'S' then
      L_to_loc_type := I_to_loc_type;
      L_to_loc := I_phy_to_loc;
   end if;

   if DISTRIBUTION_SQL.DISTRIBUTE(O_error_message,
                                  L_dist_array,
                                  I_item,
                                  I_phy_from_loc,
                                  I_tsf_qty,
                                  'TRANSFER',
                                  L_inv_status,
                                  L_to_loc_type,
                                  L_to_loc,
                                  NULL,              --order_no
                                  NULL,              --shipment
                                  NULL) = FALSE then --seq_no
      return FALSE;
   end if;

   /*
    * Assign dist table qtys to flow table qtys:
    *   -Walk through the array of distributed locations (L_dist_array)
    *    returned by the call to DISTRIBUTION_SQL.
    *
    *      -Walk through the array of possible locations to pull stock from
    *
    *         -If the distributed loc equals the possible loc
    *
    *             Assing the distribueted loc's qty to the possible loc.
    *
    */
   FOR dist_cnt IN L_dist_array.FIRST..L_dist_array.LAST LOOP

      FOR flow_cnt IN I_inv_flow_array.FIRST..I_inv_flow_array.LAST LOOP

         if L_dist_array(dist_cnt).wh = I_inv_flow_array(flow_cnt).loc then
            I_inv_flow_array(flow_cnt).qty := L_dist_array(dist_cnt).dist_qty;
            L_dist_array(dist_cnt).dist_qty := 0;
            EXIT;
         end if;

      END LOOP;

      if L_dist_array(dist_cnt).dist_qty != 0 then
         O_error_message := SQL_LIB.CREATE_MSG('NO_MAP_POSSIBLE',NULL,NULL,NULL);
         return FALSE;
      end if;

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.DIST_FROM_LOC',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END DIST_FROM_LOC;

-------------------------------------------------------------------------------

FUNCTION INS_TSF_INV_FLOW(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN IS

   dist_cnt     BINARY_INTEGER := 1;
   item_cnt     BINARY_INTEGER := 1;
   virloc_cnt   BINARY_INTEGER := 1;

BEGIN

   dist_cnt := LP_bol_rec.distros.COUNT;
   item_cnt := LP_bol_rec.distros(dist_cnt).bol_items.COUNT;
   virloc_cnt := LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs.COUNT;
   FOR virloc_cnt IN LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs.FIRST..LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs.LAST LOOP

      insert into shipitem_inv_flow(shipment,
                                    seq_no,
                                    item,
                                    from_loc,
                                    to_loc,
                                    from_loc_type,
                                    to_loc_type,
                                    tsf_no,
                                    tsf_seq_no,
                                    tsf_qty,
                                    received_qty,
                                    dist_pct)
                            values(LP_bol_rec.ship_no,
                                   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ss_seq_no,
                                   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item,
                                   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_from_loc,
                                   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_to_loc,
                                   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_from_loc_type,
                                   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_to_loc_type,
                                   LP_bol_rec.distros(dist_cnt).tsf_no,
                                   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).td_tsf_seq_no,
                                   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_qty,
                                   0,
                                   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_qty /
                                       LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).qty);

      if TRANSFER_CHARGE_SQL.DEFAULT_CHRGS(
                         O_error_message,
                         LP_bol_rec.distros(dist_cnt).tsf_no,
                         LP_bol_rec.distros(dist_cnt).tsf_type,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).td_tsf_seq_no,
                         LP_bol_rec.ship_no,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ss_seq_no,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_from_loc,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_from_loc_type,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_to_loc,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_to_loc_type,
                         LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item) = FALSE then
         return FALSE;
      end if;

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.INS_TSF_INV_FLOW',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END INS_TSF_INV_FLOW;
-------------------------------------------------------------------------------
FUNCTION FIND_MAP(O_error_message IN OUT rtk_errors.rtk_text%TYPE,
                  O_keepgoing     IN OUT BOOLEAN,
                  I_from_loc      IN     item_loc.loc%TYPE,
                  I_from_loc_type IN     item_loc.loc_type%TYPE,
                  I_qty           IN     item_loc_soh.stock_on_hand%TYPE,
                  I_status        IN     item_loc.status%TYPE,
                  I_channel_id    IN     channels.channel_id%TYPE,
                  I_channel_type  IN     channels.channel_type%TYPE,
                  I_to_array      IN     bol_sql.inv_flow_array)
RETURN BOOLEAN IS

   to_cnt BINARY_INTEGER := 1;

BEGIN

   /*
    * This function's job is to create inventory maps between a passed in
    * from location and one of the elements in a passed in an passed in
    * array of to locations.
    *
    * It creates the inventory map using the following rules.  If the
    * lower number's rule cannot be meet it moves on to the next rule.
    *
    *  1) The from loc's channel_id equals the to loc's channel id
    *
    *  2) The to loc with the smallest number that is not restricted
    *      where the from loc's channel type equals the to loc's channel_type.
    *
    *  3) The to loc with the smallest number that is restricted
    *      where the from loc's channel type equals the to loc's channel_type.
    *
    *  4) The primary to loc if it is not restricted.
    *
    *  5) The to loc with the smallest number that is not restricted.
    *
    *  6) The primary to loc if it is restricted.
    *
    */

   --channel_id
   FOR to_cnt IN I_to_array.FIRST..I_to_array.LAST LOOP

      if (I_channel_id = I_to_array(to_cnt).channel_id and
          I_status = I_to_array(to_cnt).status) then

         if PUT_TSF_INV_MAP(O_error_message,
                            I_from_loc,
                            I_from_loc_type,
                            I_to_array(to_cnt).loc,
                            I_to_array(to_cnt).loc_type,
                            I_to_array(to_cnt).receive_as_type,
                            I_qty) = FALSE then
            return FALSE;
         end if;

         O_keepgoing := FALSE;
         return TRUE;
      end if;
   END LOOP;

   --lowest channel_type, not restricted
   FOR to_cnt IN I_to_array.FIRST..I_to_array.LAST LOOP

       if (I_channel_type = I_to_array(to_cnt).channel_type and
           I_to_array(to_cnt).restricted_ind = 'N' and
           I_status = I_to_array(to_cnt).status) then

          if PUT_TSF_INV_MAP(O_error_message,
                             I_from_loc,
                             I_from_loc_type,
                             I_to_array(to_cnt).loc,
                             I_to_array(to_cnt).loc_type,
                             I_to_array(to_cnt).receive_as_type,
                             I_qty) = FALSE then
             return FALSE;
          end if;

          O_keepgoing := FALSE;
          return TRUE;

      end if;
   END LOOP;

   --lowest channel_type, restricted
   FOR to_cnt IN I_to_array.FIRST..I_to_array.LAST LOOP

       if (I_channel_type = I_to_array(to_cnt).channel_type and
           I_status = I_to_array(to_cnt).status) then

          if PUT_TSF_INV_MAP(O_error_message,
                             I_from_loc,
                             I_from_loc_type,
                             I_to_array(to_cnt).loc,
                             I_to_array(to_cnt).loc_type,
                             I_to_array(to_cnt).receive_as_type,
                             I_qty) = FALSE then
             return FALSE;
          end if;

          O_keepgoing := FALSE;
          return TRUE;

      end if;
   END LOOP;

   --primary, not restricted
   FOR to_cnt IN I_to_array.FIRST..I_to_array.LAST LOOP

      if (I_to_array(to_cnt).loc = I_to_array(to_cnt).primary_vwh and
          I_to_array(to_cnt).restricted_ind = 'N' and
          I_status = I_to_array(to_cnt).status) then

         if PUT_TSF_INV_MAP(O_error_message,
                            I_from_loc,
                            I_from_loc_type,
                            I_to_array(to_cnt).loc,
                            I_to_array(to_cnt).loc_type,
                            I_to_array(to_cnt).receive_as_type,
                            I_qty) = FALSE then
            return FALSE;
         end if;

         O_keepgoing := FALSE;
         return TRUE;

      end if;
   END LOOP;

   --lowest, not restricted
   FOR to_cnt IN I_to_array.FIRST..I_to_array.LAST LOOP

      if (I_to_array(to_cnt).restricted_ind = 'N' and
          I_status = I_to_array(to_cnt).status) then

         if PUT_TSF_INV_MAP(O_error_message,
                            I_from_loc,
                            I_from_loc_type,
                            I_to_array(to_cnt).loc,
                            I_to_array(to_cnt).loc_type,
                            I_to_array(to_cnt).receive_as_type,
                            I_qty) = FALSE then
            return FALSE;
         end if;

         O_keepgoing := FALSE;
         return TRUE;

      end if;
   END LOOP;

   --primary, restricted
   FOR to_cnt IN I_to_array.FIRST..I_to_array.LAST LOOP

      if (I_to_array(to_cnt).loc = I_to_array(to_cnt).primary_vwh and
          I_status = I_to_array(to_cnt).status) then

         if PUT_TSF_INV_MAP(O_error_message,
                            I_from_loc,
                            I_from_loc_type,
                            I_to_array(to_cnt).loc,
                            I_to_array(to_cnt).loc_type,
                            I_to_array(to_cnt).receive_as_type,
                            I_qty) = FALSE then
            return FALSE;
         end if;

         O_keepgoing := FALSE;
         return TRUE;

      end if;
   END LOOP;

   O_keepgoing := TRUE;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.FIND_MAP',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END FIND_MAP;
-------------------------------------------------------------------------------
FUNCTION PUT_TSF_INV_MAP(O_error_message   IN OUT rtk_errors.rtk_text%TYPE,
                         I_from_loc        IN     item_loc.loc%TYPE,
                         I_from_loc_type   IN     item_loc.loc_type%TYPE,
                         I_to_loc          IN     item_loc.loc%TYPE,
                         I_to_loc_type     IN     item_loc.loc_type%TYPE,
                         I_receive_as_type IN     item_loc.receive_as_type%TYPE,
                         I_tsf_qty         IN     tsfdetail.tsf_qty%TYPE)
RETURN BOOLEAN IS

   L_found      BOOLEAN := FALSE;
   dist_cnt     BINARY_INTEGER := 1;
   item_cnt     BINARY_INTEGER := 1;
   virloc_cnt   BINARY_INTEGER := 1;

BEGIN
   dist_cnt := LP_bol_rec.distros.COUNT;
   item_cnt := LP_bol_rec.distros(dist_cnt).bol_items.COUNT;

   --if already in map, update qty
   virloc_cnt := LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs.COUNT;
   if virloc_cnt > 0 then
      FOR virloc_cnt IN LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs.FIRST..LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs.LAST LOOP

         if LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_from_loc = I_from_loc and
            LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_to_loc = I_to_loc then

            LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_qty :=
            LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_qty + I_tsf_qty;
            L_found := TRUE;
            EXIT;

         end if;

      END LOOP;
   end if;

   virloc_cnt := LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs.COUNT;

   --add new map
   if L_found = FALSE then

      virloc_cnt := virloc_cnt + 1;

       LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_from_loc := I_from_loc;
       LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_from_loc_type := I_from_loc_type;
       LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_to_loc := I_to_loc;
       LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_to_loc_type := I_to_loc_type;
       LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).receive_as_type := I_receive_as_type;
       LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).virtual_locs(virloc_cnt).vir_qty := I_tsf_qty;

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.PUT_TSF_INV_MAP',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END PUT_TSF_INV_MAP;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--public function--
FUNCTION PROCESS_TSF(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN IS

   i BINARY_INTEGER := 1;

BEGIN
   --don't need to loop -- distros are processed one at a time
   if BOL_SQL.SEND_TSF(O_error_message,
                       LP_bol_rec.bol_no,
                       LP_bol_rec.distros(i).tsf_no,
                       LP_bol_rec.distros(i).tsf_type,
                       LP_bol_rec.distros(i).tsf_del_type,
                       LP_bol_rec.distros(i).new_tsf_ind,
                       LP_bol_rec.phy_to_loc,
                       LP_bol_rec.distros(i).tsf_status,
                       LP_bol_rec.tran_date,
                       LP_bol_rec.ship_no,
                       LP_bol_rec.eow_date,
                       LP_bol_rec.distros(i).bol_items) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.PROCESS_TSF',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END PROCESS_TSF;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--- This internal function has common code that is used in both PUT_TSF_ITEM
--- and RECEIPT_PUT_TSF_ITEM
-------------------------------------------------------------------------------
FUNCTION TSF_ITEM_COMMON(O_error_message    IN OUT rtk_errors.rtk_text%TYPE,
                         I_tsf_no           IN     tsfhead.tsf_no%TYPE,
                         I_carton           IN     shipsku.carton%TYPE,
                         I_qty              IN     tsfdetail.tsf_qty%TYPE,
                         I_weight           IN     item_loc_soh.average_weight%TYPE,
                         I_weight_uom       IN     uom_class.uom%TYPE,
                         I_phy_from_loc     IN     item_loc.loc%TYPE,
                         I_from_loc_type    IN     item_loc.loc_type%TYPE,
                         I_phy_to_loc       IN     item_loc.loc%TYPE,
                         I_to_loc_type      IN     item_loc.loc_type%TYPE,
                         I_tsfhead_to_loc   IN     item_loc.loc%TYPE,
                         I_tsfhead_from_loc IN     item_loc.loc%TYPE,
                         I_tsf_type         IN     tsfhead.tsf_type%TYPE,
                         I_inv_status       IN     inv_status_codes.inv_status%TYPE,
                         I_tsf_qty          IN     tsfdetail.tsf_qty%TYPE,
                         I_ship_qty         IN     tsfdetail.ship_qty%TYPE,
                         I_tsf_seq_no       IN     tsfdetail.tsf_seq_no%TYPE,
                         I_item_cnt         IN     BINARY_INTEGER,
                         I_dist_cnt         IN     BINARY_INTEGER)
RETURN BOOLEAN IS


   L_receive_as_type item_loc.receive_as_type%TYPE := NULL;
   L_from_finisher   BOOLEAN := FALSE;
   L_finisher_name   partner.partner_desc%TYPE := NULL;

   cursor C_FROM_RCV_AS_TYPE is
      select NVL(il.receive_as_type, 'E')
        from item_loc il
       where il.item = LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).item
         and il.loc  = I_tsfhead_from_loc;

   cursor C_TO_RCV_AS_TYPE is
      select NVL(il.receive_as_type, 'E')
        from item_loc il
       where il.item = LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).item
         and il.loc  = I_tsfhead_to_loc;

BEGIN

   LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).qty := I_qty;
   LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).inv_status := I_inv_status;
   LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).carton := I_carton;
   LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).td_tsf_seq_no := I_tsf_seq_no;
   LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).td_tsf_qty := I_tsf_qty;
   LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).td_ship_qty := I_ship_qty;

   -- set weight on object for a simple pack catch weight item
   if LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).simple_pack_ind = 'Y' and
      LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).catch_weight_ind = 'Y' and
      I_weight is NOT NULL and
      I_weight_uom is NOT NULL then

      -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
      LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).weight := NULL;
      LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).weight_uom := NULL;
      -- 21-Oct-2008 TESCO HSC/Murali 6907185 End
   end if;

   if I_tsf_type != 'EG' then
      if NEW_LOC(O_error_message,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).item,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).pack_ind,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).dept,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).class,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).subclass,
                 I_tsfhead_to_loc,
                 I_to_loc_type) = FALSE then
         return FALSE;
      end if;

      if NEW_LOC(O_error_message,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).item,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).pack_ind,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).dept,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).class,
                 LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).subclass,
                 I_tsfhead_from_loc,
                 I_from_loc_type) = FALSE then
         return FALSE;
      end if;

      if LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).pack_ind = 'Y' then

         open C_FROM_RCV_AS_TYPE;
         fetch C_FROM_RCV_AS_TYPE into L_receive_as_type;
         close C_FROM_RCV_AS_TYPE;

         --If sending a pack and from loc receive_as_type is 'E' then
         --determine if from loc is a finisher.
         --Finishers are allowed to send packs but do not track stock at pack level.
         if L_receive_as_type = 'E' and I_from_loc_type = 'W' then
            if WH_ATTRIB_SQL.CHECK_FINISHER(O_error_message,
                                            L_from_finisher,
                                            L_finisher_name,
                                            I_tsfhead_from_loc) = FALSE then
               return FALSE;
            end if;

         --external finisher
         elsif I_from_loc_type = 'E' then
            L_from_finisher := TRUE;
         end if;

         --reject if pack item is sent and the from location does
         --not stock packs (store or receive as Each wh) unless from loc is a finisher.
         if L_receive_as_type = 'E' and L_from_finisher = FALSE then
            O_error_message := SQL_LIB.CREATE_MSG('NO_PACK_STOCK',to_char(I_tsfhead_from_loc),null,null);
            return FALSE;
         end if;

         --set the 'to' receive as type
         open C_TO_RCV_AS_TYPE;
         fetch C_TO_RCV_AS_TYPE into L_receive_as_type;
         close C_TO_RCV_AS_TYPE;
      else --not pack
         L_receive_as_type := 'E';
      end if;

      --create flow in struct using locations on tsfhead (virtual)
      --non-EG transfer do not get records inserted in SHIPITEM_INV_FLOW
      if PUT_TSF_INV_MAP(O_error_message,
                         I_tsfhead_from_loc,
                         I_from_loc_type,
                         I_tsfhead_to_loc,
                         I_to_loc_type,
                         L_receive_as_type,
                         I_qty) = FALSE then
         return FALSE;
      end if;

   else -- I_tsf_type = 'EG'

      --create flow in struct and on SHIPITEM_INV_FLOW using locations (physical)
      --passed in the message -- only EG transfer get records on SHIPITEM_INV_FLOW
      if CREATE_TSF_INV_MAP(O_error_message,
                            I_tsf_no,
                            LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).item,
                            LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).pack_ind,
                            LP_bol_rec.distros(I_dist_cnt).bol_items(I_item_cnt).inv_status,
                            I_tsf_seq_no,
                            I_phy_from_loc,
                            I_from_loc_type,
                            I_phy_to_loc,
                            I_to_loc_type,
                            I_qty) = FALSE then
         return FALSE;
      end if;

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'BOL_SQL.TSF_ITEM_COMMON',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END TSF_ITEM_COMMON;
----------------------------------------------------------------------------------
FUNCTION SEND_TSF(O_error_message IN OUT rtk_errors.rtk_text%TYPE,
                  I_bol_no        IN     shipment.bol_no%TYPE,
                  I_tsf_no        IN     tsfhead.tsf_no%TYPE,
                  I_tsf_type      IN     tsfhead.tsf_type%TYPE,
                  I_del_type      IN     ordcust.deliver_type%TYPE,
                  I_new_tsf       IN     VARCHAR2,
                  I_tsf_to_loc    IN     item_loc.loc%TYPE,
                  I_tsf_status    IN     tsfhead.status%TYPE,
                  I_tran_date     IN     period.vdate%TYPE,
                  I_ship_no       IN     shipment.shipment%TYPE,
                  I_eow_date      IN     period.vdate%TYPE,
                  I_bol_items     IN     bol_sql.bol_item_array)
return BOOLEAN IS

   item_cnt BINARY_INTEGER := 1;
   loc_cnt  BINARY_INTEGER := 1;

   L_resv_exp_qty                   item_loc_soh.stock_on_hand%TYPE := 0;
   L_intran_qty                     item_loc_soh.stock_on_hand%TYPE := 0;

   -- This holds the pack's av_cost and retail at from loc.
   -- L_pack_loc_av_cost is used for prorating the charge.
   -- L_pack_loc_retail is used for writing shipsku.unit_retail.
   L_pack_no                        item_master.item%TYPE;
   L_pack_loc_av_cost               item_loc_soh.av_cost%TYPE;
   L_pack_loc_retail                item_loc.unit_retail%TYPE;

   -- This holds the from loc item cost depending on the accounting method.
   L_from_wac                       item_loc_soh.av_cost%TYPE := NULL;
   L_from_av_cost                   item_loc_soh.av_cost%TYPE := NULL;
   L_from_unit_retail               item_loc.unit_retail%TYPE := NULL;

   -- for charges
   L_total_chrgs_prim               item_loc.unit_retail%TYPE := 0;
   L_profit_chrgs_to_loc            item_loc.unit_retail%TYPE := 0;
   L_exp_chrgs_to_loc               item_loc.unit_retail%TYPE := 0;
   L_pack_total_chrgs_prim          item_loc.unit_retail%TYPE := NULL;
   L_pack_profit_chrgs_to_loc       item_loc.unit_retail%TYPE := NULL;
   L_pack_exp_chrgs_to_loc          item_loc.unit_retail%TYPE := NULL;

   -- This holds the item's (or component item's) transfer unit cost used for
   -- stock ledger. Shipsku.unit_cost should be based on the same unit cost.
   L_tsf_unit_cost                  item_loc_soh.av_cost%TYPE := NULL;

   -- This holds the pack's transfer unit cost, aggregated by components.
   L_pack_tsf_unit_cost             item_loc_soh.av_cost%TYPE := 0;

   -- These variables hold the item's (or pack's) total cost/retail/charges/qty
   -- across all virtual locations.
   L_ss_cost                  item_loc_soh.av_cost%TYPE := 0;
   L_ss_prim_chrgs            item_loc_soh.av_cost%TYPE := 0;
   L_ss_from_chrgs            item_loc_soh.av_cost%TYPE := 0;
   L_ss_retail                item_loc.unit_retail%TYPE := 0;
   L_ss_qty                   item_loc_soh.stock_on_hand%TYPE := 0;
   L_ss_exp_weight            shipsku.weight_expected%TYPE := NULL;
   L_ss_exp_weight_uom        shipsku.weight_expected_uom%TYPE := NULL;

   L_ins_cost                       shipsku.unit_cost%TYPE   := NULL;
   L_ins_retail                     shipsku.unit_retail%TYPE := NULL;
   L_ss_rcv_qty                     item_loc_soh.stock_on_hand%TYPE := 0;

   L_ship_no                        shipment.shipment%TYPE := NULL;
   L_ss_seq_no                      shipsku.seq_no%TYPE    := NULL;

   L_tsf_parent_no                  tsfhead.tsf_parent_no%TYPE;

   L_comp_item                      VARCHAR2(1) := 'Y';
   L_pack_ind                       VARCHAR2(1) := 'N';
   L_pct_in_pack                    NUMBER := 0;

   L_intercompany                   BOOLEAN := FALSE;
   L_finisher                       BOOLEAN := FALSE;
   L_finisher_name                  WH.WH_NAME%TYPE;
   L_from_finisher_ind              wh.finisher_ind%TYPE := 'N';
   L_to_finisher_ind                wh.finisher_ind%TYPE := 'N';

   L_upd_inv_status_qty             item_loc_soh.stock_on_hand%TYPE := 0;

   -- for simple pack catch weight processing
   L_cuom                           item_supp_country.cost_uom%TYPE := NULL;
   L_vir_weight_cuom                item_loc_soh.average_weight%TYPE := NULL;
   L_intran_weight_cuom             item_loc_soh.average_weight%TYPE := NULL;

   -- cursors
   cursor C_ITEM_IN_PACK is
       select v.item,
              v.qty,
              im.dept,
              im.class,
              im.subclass,
              im.sellable_ind,
              im.item_xform_ind,
              im.inventory_ind
         from item_master im,
              v_packsku_qty v
        where v.pack_no = L_pack_no
          and im.item   = v.item;

   cursor C_GET_TSF_PARENT_NO is
      select tsf_parent_no
        from tsfhead
       where tsf_no = I_tsf_no;

BEGIN

   if I_new_tsf = 'Y' then
      if BOL_SQL.DEPT_LVL_CHK(O_error_message,
                              I_bol_items(item_cnt).dept,
                              I_tsf_no) = FALSE then
         return FALSE;
      end if;
   end if;

   open C_GET_TSF_PARENT_NO;
   fetch C_GET_TSF_PARENT_NO into L_tsf_parent_no;
   close C_GET_TSF_PARENT_NO;

   if L_tsf_parent_no is not NULL then  --2nd leg of multi-legged tsf
      L_from_finisher_ind := 'Y';
      L_to_finisher_ind := 'N';
      --Finishers can send packs but do not track stock of packs or pack
      --components.  Set L_comp_item to N so upd_from_item_loc will update
      --the finisher 'from' loc correctly.
      L_comp_item := 'N';
   end if;

   if L_from_finisher_ind = 'Y' then
     --if second leg of the transfer then from loc is a finisher.
     --Call work order complete to perform any necessary transformations.
     --flush all the arrays build by INVADJ_SQL
     if INVADJ_SQL.FLUSH_ALL(O_error_message) = FALSE then
        return FALSE;
     end if;
     ---
      FOR item_cnt IN I_bol_items.FIRST..I_bol_items.LAST LOOP
         FOR loc_cnt IN I_bol_items(item_cnt).virtual_locs.FIRST..I_bol_items(item_cnt).virtual_locs.LAST LOOP
            --Because wo_item_comp writes (inits and flushes) its own tran_data records
            --put it in it's own item/loc loop to be processed first.  That way all work order complete adjustments
            --and tran data records are flushed, and only one flush is necessary at the end for the transfer in/out
            --tran data records created by WRITE_FINANCIALS.
            if TSF_WO_COMP_SQL.WO_ITEM_COMP(O_error_message,
                                            I_tsf_no,
                                            L_tsf_parent_no,
                                            I_bol_items(item_cnt).item,
                                            I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                            I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                            I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                            I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type,
                                            I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty,
                                            I_tran_date,
                                            FALSE) = FALSE then
               return FALSE;
            end if;
         end LOOP;
      end LOOP;

      --init all the arrays build by INVADJ_SQL
      if INVADJ_SQL.INIT_ALL(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   FOR item_cnt IN I_bol_items.FIRST..I_bol_items.LAST LOOP

      if I_tsf_type = 'EG' then
         L_ship_no := I_ship_no;
         L_ss_seq_no := I_bol_items(item_cnt).ss_seq_no;
      else
         L_ship_no := NULL;
         L_ss_seq_no := NULL;
      end if;

      -- write weight on the message to shipsku weight_expected
      if I_bol_items(item_cnt).simple_pack_ind = 'Y' and
         I_bol_items(item_cnt).catch_weight_ind = 'Y' then
         if I_bol_items(item_cnt).weight is NOT NULL and
            I_bol_items(item_cnt).weight_uom is NOT NULL then
            L_ss_exp_weight := I_bol_items(item_cnt).weight;
            L_ss_exp_weight_uom := I_bol_items(item_cnt).weight_uom;
         end if;
      end if;

      FOR loc_cnt IN I_bol_items(item_cnt).virtual_locs.FIRST..I_bol_items(item_cnt).virtual_locs.LAST LOOP

         --set qty to use when setting the resv / exp qtys on item_loc_soh
         if I_new_tsf = 'Y' or I_tsf_status = 'C' then
            L_resv_exp_qty := 0;
         else
            if I_bol_items(item_cnt).td_ship_qty >= I_bol_items(item_cnt).td_tsf_qty then
               L_resv_exp_qty := 0;
            elsif I_bol_items(item_cnt).qty + I_bol_items(item_cnt).td_ship_qty > I_bol_items(item_cnt).td_tsf_qty then
               L_resv_exp_qty := I_bol_items(item_cnt).td_tsf_qty - I_bol_items(item_cnt).td_ship_qty;
            else
               L_resv_exp_qty := I_bol_items(item_cnt).qty;
            end if;
         end if;

         L_intran_qty := I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty;

         if TRANSFER_SQL.IS_INTERCOMPANY(O_error_message,
                                         L_intercompany,
                                         'T',  -- distro type
                                         I_tsf_type, -- transfer type
                                         I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                         I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                         I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                         I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type) = FALSE then
            return FALSE;
         end if;

         if L_tsf_parent_no is NULL then  --single leg or 1st leg of multi-legged tsf
            if I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type = 'W' then
               if WH_ATTRIB_SQL.CHECK_FINISHER(O_error_message,
                                               L_finisher,
                                               L_finisher_name,
                                               I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc) = FALSE then
                  return FALSE;
               end if;
            elsif I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type = 'E' then
               --External Finisher
               L_finisher := TRUE;
            end if;

            if L_finisher = TRUE then
               --1st leg of multi-legged tsf
               L_to_finisher_ind := 'Y';
            else
               --one leg only tsf
               L_to_finisher_ind := 'N';
            end if;
         end if;

         if I_bol_items(item_cnt).inv_status != -1 and
            (I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type = 'W' or
             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type = 'S') then

            --Determine if more stock needs to be taken from the correct unavailable inv_status.
            --This assumes that EG is only for Available inventory and won't fall into here.  Therefore this will only be called once,
            --as there will only be one vir_loc in the loop.

            if I_bol_items(item_cnt).qty + I_bol_items(item_cnt).td_ship_qty > I_bol_items(item_cnt).td_tsf_qty then
               L_upd_inv_status_qty := (I_bol_items(item_cnt).qty + I_bol_items(item_cnt).td_ship_qty)
                                          - I_bol_items(item_cnt).td_tsf_qty;

               if BOL_SQL.UPDATE_INV_STATUS(O_error_message,
                                            I_bol_items(item_cnt).item,
                                            I_bol_items(item_cnt).pack_ind,
                                            I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                            I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                            L_upd_inv_status_qty,
                                            I_bol_items(item_cnt).inv_status) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;

         if I_bol_items(item_cnt).pack_ind = 'N' then
            if BOL_SQL.UPD_FROM_ITEM_LOC(O_error_message,
                                         L_from_av_cost,
                                         L_from_unit_retail,
                                         I_bol_items(item_cnt).item,
                                         'N',
                                         I_bol_items(item_cnt).sellable_ind,
                                         I_bol_items(item_cnt).item_xform_ind,
                                         NULL, -- inventory ind
                                         I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                         I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty,
                                         L_resv_exp_qty,
                                         NULL, -- weight
                                         NULL, -- weight uom
                                         I_eow_date) = FALSE then
               return FALSE;
            end if;

            ---
            if ITEMLOC_ATTRIB_SQL.GET_WAC(O_error_message,
                                          L_from_wac,
                                          I_bol_items(item_cnt).item,
                                          I_bol_items(item_cnt).dept,
                                          I_bol_items(item_cnt).class,
                                          I_bol_items(item_cnt).subclass,
                                          I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                          I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                          I_tran_date,
                                          I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                          I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type) = FALSE then
               return FALSE;
            end if;

            /* if this is the intercompany leg of a transfer, the tsf_item_cost.shipped_qty */
            /* needs to be updated */
            if L_intercompany then
               if UPD_TSF_ITEM_COST(O_error_message,
                                    I_bol_items(item_cnt).item,
                                    I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty,
                                    I_tsf_no) = FALSE then
                  return FALSE;
               end if;
            end if;

            if UP_CHARGE_SQL.CALC_TSF_ALLOC_ITEM_LOC_CHRGS(
                                   O_error_message,
                                   L_total_chrgs_prim,
                                   L_profit_chrgs_to_loc,
                                   L_exp_chrgs_to_loc,
                                   'T',                    --transfer
                                   I_tsf_no,
                                   I_bol_items(item_cnt).td_tsf_seq_no,
                                   L_ship_no,
                                   L_ss_seq_no,
                                   I_bol_items(item_cnt).item,
                                   NULL,                   --pack_item
                                   I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                   I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                   I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                   I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type) = FALSE then
               return FALSE;
            end if;

            if BOL_SQL.UPD_TO_ITEM_LOC(O_error_message,
                                       I_bol_items(item_cnt).item,
                                       NULL, --pack_no
                                       NULL, --percent in pack
                                       'E',  --receive_as_type
                                       I_tsf_type,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty,
                                       L_resv_exp_qty,
                                       L_intran_qty,
                                       NULL,  --weight_cuom
                                       NULL,  --cuom
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                       L_from_wac,
                                       L_total_chrgs_prim,
                                       I_tsf_no,
                                       'T',
                                       L_intercompany) = FALSE then
               return FALSE;
            end if;

            if I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type = 'W' then
               if BOL_SQL.WRITE_ISSUES(O_error_message,
                                       I_bol_items(item_cnt).item,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty,
                                       I_eow_date) = FALSE then
                  return FALSE;
               end if;
            end if;

            if STKLEDGR_SQL.WRITE_FINANCIALS(O_error_message,
                                             L_tsf_unit_cost,
                                             'T',
                                             I_ship_no,
                                             I_tsf_no,
                                             I_tran_date,
                                             I_bol_items(item_cnt).item,
                                             NULL,  --pack_no
                                             NULL,  --pct_in_pack
                                             I_bol_items(item_cnt).dept,
                                             I_bol_items(item_cnt).class,
                                             I_bol_items(item_cnt).subclass,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty,
                                             NULL,   --weight_cuom
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                             L_from_finisher_ind,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type,
                                             L_to_finisher_ind,
                                             L_from_wac,
                                             L_profit_chrgs_to_loc,
                                             L_exp_chrgs_to_loc,
                                             L_intercompany) = FALSE then
               return FALSE;
            end if;

            if UPDATE_SNAPSHOT_SQL.EXECUTE(O_error_message,
                                           'TSFO',
                                           I_bol_items(item_cnt).item,
                                           'N',
                                           I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type,
                                           I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                           I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                           I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                           I_tran_date,
                                           LP_vdate,
                                           I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty) = FALSE then
               return FALSE;
            end if;

            --before writing the shipsku retail check if from loc is an external finisher.
            --if so, the unit retail is null. Get the correct retail.
            --For an orderable BTS item, unit_retail is also not defined, in which case, get its sellable's retail.
            if L_from_unit_retail is NULL then
               if BOL_SQL.GET_COSTS_AND_RETAILS(O_error_message,
                                             L_from_av_cost,
                                             L_from_unit_retail,
                                             I_bol_items(item_cnt).item,
                                             'N',
                                             I_bol_items(item_cnt).sellable_ind,
                                             I_bol_items(item_cnt).item_xform_ind,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type) = FALSE then
                  return FALSE;
               end if;
            end if;

            --If unit retail is still NULL, it could be for an orderable/non-sellable non-pack/non-tranformed item.
            --Set unit_retail to 0 for writing to shipsku.
            if L_from_unit_retail is NULL then
               L_from_unit_retail := 0;
            end if;

            L_ss_prim_chrgs := L_ss_prim_chrgs +
               (L_total_chrgs_prim * I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty);

            -- if tsf_cost is defined, shipsku.unit_cost should be based off tsf_cost
            -- sum up shipsku cost across all virtual locations
            L_ss_cost := L_ss_cost + L_tsf_unit_cost *
               I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty;

            L_ss_retail := L_ss_retail + (L_from_unit_retail *
               I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty);

            L_ss_qty := L_ss_qty + I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty;

         else --pack
            L_pack_no := I_bol_items(item_cnt).item;
            if BOL_SQL.GET_COSTS_AND_RETAILS(O_error_message,
                                             L_pack_loc_av_cost,
                                             L_pack_loc_retail,
                                             I_bol_items(item_cnt).item,
                                             'Y',
                                             I_bol_items(item_cnt).sellable_ind,
                                             I_bol_items(item_cnt).item_xform_ind,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type) = FALSE then
               return FALSE;
            end if;

            -- If weight is not defined for a simple pack catch weight item,
            -- use the virtual from loc's average weight for the pack to derive weight.
            if I_bol_items(item_cnt).simple_pack_ind = 'Y' and
               I_bol_items(item_cnt).catch_weight_ind = 'Y' then

               if not CATCH_WEIGHT_SQL.PRORATE_WEIGHT(O_error_message,
                                                      L_vir_weight_cuom,
                                                      L_cuom,
                                                      I_bol_items(item_cnt).item,
                                                      I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                                      I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                                      I_bol_items(item_cnt).weight,
                                                      I_bol_items(item_cnt).weight_uom,
                                                      I_bol_items(item_cnt).qty,
                                                      I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty) then
                  return FALSE;
               end if;

               -- L_intran_qty is either 0 or vir_qty
               if L_intran_qty != 0 then
                  L_intran_weight_cuom := L_vir_weight_cuom;
               end if;

               -- sum up shipsku weight_expected across all virtual locations
               if I_bol_items(item_cnt).weight is NULL or
                  I_bol_items(item_cnt).weight_uom is NULL then
                  L_ss_exp_weight := NVL(L_ss_exp_weight, 0) + L_vir_weight_cuom;
                  L_ss_exp_weight_uom := L_cuom;
               end if;
            --20-Jan-2008, Raghuveer P R  3.3a to 3.3b merge - Begin
            /* START SirNBS6658242T */
            --26-May-2008, Satish B.N, satish.narasimhaiah@in.tesco.com BugNo.6658242/DefNBS006565 Begin
            else
               L_vir_weight_cuom := NULL;
               L_intran_weight_cuom := NULL;
            --26-May-2008, Satish B.N, satish.narasimhaiah@in.tesco.com BugNo.6658242/DefNBS006565 End
            /* END SirNBS6658242T */
            --20-Jan-2008, Raghuveer P R  3.3a to 3.3b merge - End
			end if;

            if BOL_SQL.UPDATE_PACK_LOCS(O_error_message,
                                        I_bol_items(item_cnt).item,
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type,
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).receive_as_type,
                                        I_tsf_type,
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty,
                                        L_vir_weight_cuom,
                                        L_intran_qty,
                                        L_intran_weight_cuom,
                                        L_resv_exp_qty) = FALSE then
               return FALSE;
            end if;

            if I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type = 'W' then
               if UPDATE_SNAPSHOT_SQL.EXECUTE(O_error_message,
                                              'TSFO',
                                              I_bol_items(item_cnt).item,
                                              'P',
                                              I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type,
                                              I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                              I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                              I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                              I_tran_date,
                                              LP_vdate,
                                              I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty) = FALSE then
                  return FALSE;
               end if;
            end if;

            if I_bol_items(item_cnt).pack_type != 'B' then

               if UP_CHARGE_SQL.CALC_TSF_ALLOC_ITEM_LOC_CHRGS(
                                       O_error_message,
                                       L_pack_total_chrgs_prim,
                                       L_pack_profit_chrgs_to_loc,
                                       L_pack_exp_chrgs_to_loc,
                                       'T',                         --transfer
                                       I_tsf_no,
                                       I_bol_items(item_cnt).td_tsf_seq_no,
                                       L_ship_no,
                                       L_ss_seq_no,
                                       I_bol_items(item_cnt).item,  --item (send pack in item field)
                                       NULL,                        --pack_no
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type) = FALSE then
                  return FALSE;
               end if;

               L_ss_prim_chrgs := L_ss_prim_chrgs + (L_pack_total_chrgs_prim *
                  I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty);
            end if;

            L_pack_tsf_unit_cost := 0;
            FOR rec in C_ITEM_IN_PACK LOOP
               if BOL_SQL.UPD_FROM_ITEM_LOC(O_error_message,
                                            L_from_av_cost,
                                            L_from_unit_retail,
                                            rec.item,
                                            L_comp_item,
                                            rec.sellable_ind,
                                            rec.item_xform_ind,
                                            rec.inventory_ind,
                                            I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                            I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty * rec.qty,
                                            L_resv_exp_qty * rec.qty,
                                            L_vir_weight_cuom, -- weight
                                            L_cuom, -- weight uom
                                            I_eow_date) = FALSE then
                  return FALSE;
               end if;

               if ITEMLOC_ATTRIB_SQL.GET_WAC(O_error_message,
                                             L_from_wac,
                                             rec.item,
                                             rec.dept,
                                             rec.class,
                                             rec.subclass,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                             I_tran_date,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type) = FALSE then
                  return FALSE;
               end if;

               /* if this is the intercompany leg of a transfer, the tsf_item_cost.shipped_qty */
               /* needs to be updated */
               if L_intercompany then
                  if UPD_TSF_ITEM_COST(O_error_message,
                                       rec.item,
                                       I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty * rec.qty,
                                       I_tsf_no) = FALSE then
                     return FALSE;
                  end if;
               end if;

               if I_bol_items(item_cnt).pack_type != 'B' then
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
                  L_profit_chrgs_to_loc := L_pack_profit_chrgs_to_loc * L_from_av_cost / L_pack_loc_av_cost;
                  L_exp_chrgs_to_loc    := L_pack_exp_chrgs_to_loc    * L_from_av_cost / L_pack_loc_av_cost;
                  L_total_chrgs_prim    := L_pack_total_chrgs_prim    * L_from_av_cost / L_pack_loc_av_cost;
               else
                  if UP_CHARGE_SQL.CALC_TSF_ALLOC_ITEM_LOC_CHRGS(
                                        O_error_message,
                                        L_total_chrgs_prim,
                                        L_profit_chrgs_to_loc,
                                        L_exp_chrgs_to_loc,
                                        'T',                         --transfer
                                        I_tsf_no,
                                        I_bol_items(item_cnt).td_tsf_seq_no,
                                        L_ship_no,
                                        L_ss_seq_no,
                                        rec.item,                    --item
                                        I_bol_items(item_cnt).item,  --pack_no
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                        I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type) = FALSE then
                     return FALSE;
                  end if;

                  L_ss_prim_chrgs := L_ss_prim_chrgs + (L_total_chrgs_prim * rec.qty *
                     I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty);

               end if;

               if TRANSFER_COST_SQL.PCT_IN_PACK(O_error_message,
                                                L_pct_in_pack,
                                                I_bol_items(item_cnt).item,
                                                rec.item,
                                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc) = FALSE then
                  return FALSE;
               end if;

               if rec.inventory_ind = 'Y' then
                  if BOL_SQL.UPD_TO_ITEM_LOC(O_error_message,
                                             rec.item,
                                             I_bol_items(item_cnt).item,
                                             L_pct_in_pack,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).receive_as_type,  --correct for all loc types!!
                                             I_tsf_type,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty * rec.qty,
                                             L_resv_exp_qty * rec.qty,
                                             L_intran_qty * rec.qty,
                                             L_intran_weight_cuom,
                                             L_cuom,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                             I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                             L_from_wac,
                                             L_total_chrgs_prim,
                                             I_tsf_no,
                                             'T',
                                             L_intercompany) = FALSE then
                     return FALSE;
                  end if;
               end if;

               if I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type = 'W' then
                  if BOL_SQL.WRITE_ISSUES(O_error_message,
                                          rec.item,
                                          I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                          I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty * rec.qty,
                                          I_eow_date) = FALSE then
                     return FALSE;
                  end if;
               end if;

               if STKLEDGR_SQL.WRITE_FINANCIALS(O_error_message,
                                                L_tsf_unit_cost,
                                                'T',
                                                I_ship_no, --shipment
                                                I_tsf_no,
                                                I_tran_date, --tran date
                                                rec.item,
                                                I_bol_items(item_cnt).item,  --pack_no
                                                L_pct_in_pack,  --pct_in_pack
                                                rec.dept,
                                                rec.class,
                                                rec.subclass,
                                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty * rec.qty,
                                                L_intran_weight_cuom,
                                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                                L_from_finisher_ind,
                                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type,
                                                L_to_finisher_ind,
                                                L_from_wac,
                                                L_profit_chrgs_to_loc,
                                                L_exp_chrgs_to_loc,
                                                L_intercompany) = FALSE then
                  return FALSE;
               end if;

               if I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type = 'S' or
                  I_bol_items(item_cnt).virtual_locs(loc_cnt).receive_as_type = 'E' then

                  if I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type = 'S' then
                     L_pack_ind := 'N';
                  else
                     L_pack_ind := 'C';
                  end if;

                  if UPDATE_SNAPSHOT_SQL.EXECUTE(O_error_message,
                                'TSFO',
                                rec.item,
                                L_pack_ind,
                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc_type,
                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_to_loc,
                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc_type,
                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_from_loc,
                                I_tran_date,
                                LP_vdate,
                                I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty * rec.qty) = FALSE then
                     return FALSE;
                  end if;
               end if;

               -- sum up component item's transfer unit cost
               L_pack_tsf_unit_cost := L_pack_tsf_unit_cost + L_tsf_unit_cost * rec.qty;
            END LOOP; --pack comp

            -- transfer is at the virtual locations
            -- shipment is at the physical locations
            -- sum up transfer cost across all virtual locations
            L_ss_cost := L_ss_cost + L_pack_tsf_unit_cost *
               I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty;
            L_ss_retail := L_ss_retail + (NVL(L_pack_loc_retail, 0) *
               I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty);
            L_ss_qty := L_ss_qty + I_bol_items(item_cnt).virtual_locs(loc_cnt).vir_qty;

         end if; --item type

      END LOOP; --virtual loc

      if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                          NULL,
                                          NULL,
                                          NULL,
                                          /* since all virtuals in a phy must have
                                          same currency code, just grab the 1st one */
                                          I_bol_items(item_cnt).virtual_locs(1).vir_from_loc,
                                          I_bol_items(item_cnt).virtual_locs(1).vir_from_loc_type,
                                          NULL,
                                          L_ss_prim_chrgs,
                                          L_ss_from_chrgs,
                                          'C',
                                          NULL,
                                          NULL) = FALSE then
         return FALSE;
      end if;

      L_ins_cost := (L_ss_cost / L_ss_qty) + (L_ss_from_chrgs / L_ss_qty);
      L_ins_retail := L_ss_retail / L_ss_qty;
      -- LP_receipt_ind is set for when the BOL process is being called from the Receiving process.
      --
      if LP_receipt_ind = 'Y' then
         L_ss_rcv_qty := L_ss_qty;
         L_ss_qty := 0;
      else
         L_ss_rcv_qty := 0;
      end if;

      if BOL_SQL.INS_SHIPSKU(O_error_message,
                             I_ship_no,
                             I_bol_items(item_cnt).ss_seq_no,
                             I_bol_items(item_cnt).item,
                             I_bol_items(item_cnt).ref_item,
                             I_tsf_no,
                             'T',
                             I_bol_items(item_cnt).carton,
                             I_bol_items(item_cnt).inv_status,
                             L_ss_rcv_qty,
                             L_ins_cost,
                             L_ins_retail,
                             L_ss_qty,
                             L_ss_exp_weight,
                             L_ss_exp_weight_uom) = FALSE then
         return FALSE;
      end if;

      L_ss_prim_chrgs := 0;
      L_ss_cost := 0;
      L_ss_retail := 0;
      L_ss_qty := 0;
      L_ss_rcv_qty := 0;
      L_ss_exp_weight := NULL;
      L_ss_exp_weight_uom := NULL;
      L_ins_cost := 0;
      L_ins_retail := 0;

      if (I_tsf_type = 'CO' and I_del_type = 'S') then
          --perform concurrent shipping and receiving for customer order transfers
          --that are being shipped direct to the customer.

         if STOCK_ORDER_RCV_SQL.INIT_TSF_ALLOC_GROUP(O_error_message) = FALSE then
            return FALSE;
         end if;

         if STOCK_ORDER_RCV_SQL.TSF_LINE_ITEM(O_error_message,
                                              I_tsf_to_loc,
                                              I_bol_items(item_cnt).item,
                                              I_bol_items(item_cnt).qty,
                                              I_bol_items(item_cnt).weight,
                                              I_bol_items(item_cnt).weight_uom,
                                              'R',
                                              I_tran_date,
                                              NULL,         --I_RECEIPT_NUMBER,
                                              I_bol_no,
                                              NULL,         --I_APPT_NO,
                                              I_bol_items(item_cnt).carton,
                                              'T',
                                              I_tsf_no,
                                              'ATS',        --I_DISP,
                                              NULL,
                                              NULL) = FALSE then
            return FALSE;
         end if;

         if STOCK_ORDER_RCV_SQL.FINISH_TSF_ALLOC_GROUP(O_error_message) = FALSE then
             return FALSE;
         end if;

      end if;

   END LOOP; --items

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.SEND_TSF',
                                            to_char(SQLCODE));
        return FALSE;
END SEND_TSF;
-------------------------------------------------------------------------------
FUNCTION GET_COSTS_AND_RETAILS(O_error_message         IN OUT rtk_errors.rtk_text%TYPE,
                               O_av_cost               IN OUT item_loc_soh.av_cost%TYPE,
                               O_unit_retail           IN OUT item_loc.unit_retail%TYPE,
                               I_item                  IN     item_master.item%TYPE,
                               I_pack_ind              IN     VARCHAR2,
                               I_sellable_ind          IN     item_master.sellable_ind%TYPE,
                               I_item_xform_ind        IN     item_master.item_xform_ind%TYPE,
                               I_from_loc              IN     item_loc.loc%TYPE,
                               I_from_loc_type         IN     item_loc.loc_type%TYPE,
                               I_to_loc                IN     item_loc.loc%TYPE,
                               I_to_loc_type           IN     item_loc.loc_type%TYPE)
RETURN BOOLEAN IS

   L_unit_cost            item_loc_soh.unit_cost%TYPE;
   L_av_cost              item_loc_soh.av_cost%TYPE;
   L_selling_unit_retail  item_loc.selling_unit_retail%TYPE;
   L_selling_uom          item_loc.selling_uom%TYPE;
   L_loc                  item_loc.loc%TYPE;

   cursor C_ITEM_LOC_RETAIL(CV_loc item_loc.loc%TYPE) is
      select il.unit_retail
        from item_loc  il
       where il.item = I_item
         and il.loc = CV_loc;

BEGIN
   --External finisher does not have unit retail.  Use the unit retail of the to loc
   if I_from_loc_type = 'E' and I_pack_ind = 'Y' then
      if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message,
                                                  I_item,
                                                  I_to_loc,
                                                  I_to_loc_type,
                                                  L_av_cost,
                                                  L_unit_cost,
                                                  O_unit_retail,
                                                  L_selling_unit_retail,
                                                  L_selling_uom) = FALSE then
         return FALSE;
      end if;

      if ITEMLOC_ATTRIB_SQL.GET_AV_COST(O_error_message,
                                        I_item,
                                        I_from_loc,
                                        I_from_loc_type,
                                        O_av_cost) = FALSE then
         return FALSE;
      end if;

   elsif I_pack_ind = 'Y' then
      if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message,
                                                  I_item,
                                                  I_from_loc,
                                                  I_from_loc_type,
                                                  O_av_cost,
                                                  L_unit_cost,
                                                  O_unit_retail,
                                                  L_selling_unit_retail,
                                                  L_selling_uom) = FALSE then
         return FALSE;
      end if;

   else
      if I_from_loc_type = 'E' then
         L_loc := I_to_loc;
      else
         L_loc := I_from_loc;
      end if;
      ---
      --- Non-sellable transformation item
      if I_sellable_ind = 'N' and I_item_xform_ind = 'Y' then

         if ITEM_XFORM_SQL.CALCULATE_RETAIL(O_error_message,
                                            I_item,
                                            L_loc,
                                            O_unit_retail) = FALSE then
            return FALSE;
         end if;
      ---
      ---Regular tran level item
      else
         open C_ITEM_LOC_RETAIL(L_loc);
         fetch C_ITEM_LOC_RETAIL into O_unit_retail;

         if C_ITEM_LOC_RETAIL%NOTFOUND then
            close C_ITEM_LOC_RETAIL;
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
            --Following RIB error message has modified as the part of Performance issue.
            /*O_error_message:= SQL_LIB.CREATE_MSG('NO_ITEM_LOC', L_loc, NULL, NULL);*/
            --RIB error message enhancement start
            O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_LOC_EXIST',
                                                  I_item,
                                                  L_loc,
                                                  NULL);
            -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
            return FALSE;
         end if;

         close C_ITEM_LOC_RETAIL;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.GET_COSTS_AND_RETAILS',
                                            to_char(SQLCODE));
        return FALSE;
END GET_COSTS_AND_RETAILS;
-------------------------------------------------------------------------------

FUNCTION DEPT_LVL_CHK(O_error_message   IN OUT rtk_errors.rtk_text%TYPE,
                      I_dept            IN     deps.dept%TYPE,
                      I_tsf_no          IN     tsfhead.tsf_no%TYPE)
RETURN BOOLEAN IS

   L_rowid                 ROWID;

   L_table                 VARCHAR2(30);
   L_key1                  VARCHAR2(100);
   L_key2                  VARCHAR2(100);
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

   -- cursors
   cursor C_LOCK_TH is
      select th.rowid
        from tsfhead th
       where th.tsf_no = I_tsf_no
         for update nowait;

BEGIN
   if LP_dept_level_transfers IS NULL then
      if SYSTEM_OPTIONS_SQL.GET_DEPT_LEVEL_TSF(O_error_message,
                                               LP_dept_level_transfers) = FALSE then
         return FALSE;
      end if;
   end if;

   if LP_dept_level_transfers = 'Y' then
      L_table := 'TSFHEAD';
      L_key1 := TO_CHAR(I_tsf_no);
      L_key2 := null;
      open C_LOCK_TH;
      fetch C_LOCK_TH into L_rowid;
      close C_LOCK_TH;
      update tsfhead th
         set th.dept = I_dept
      where th.rowid = L_rowid;
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
                                            'BOL_SQL.DEPT_LVL_CHK',
                                            to_char(SQLCODE));
      return FALSE;
END DEPT_LVL_CHK;
-------------------------------------------------------------------------------
FUNCTION INS_SHIPSKU(O_error_message  IN OUT VARCHAR2,
                     I_shipment       IN     shipment.shipment%TYPE,
                     I_seq_no         IN     shipsku.seq_no%TYPE,
                     I_item           IN     item_master.item%TYPE,
                     I_ref_item       IN     item_master.item%TYPE,
                     I_distro_no      IN     shipsku.distro_no%TYPE,
                     I_distro_type    IN     shipsku.distro_type%TYPE,
                     I_carton         IN     shipsku.carton%TYPE,
                     I_inv_status     IN     shipsku.inv_status%TYPE,
                     I_rcv_qty        IN     shipsku.qty_expected%TYPE,
                     I_cost           IN     shipsku.unit_cost%TYPE,
                     I_retail         IN     shipsku.unit_retail%TYPE,
                     I_exp_qty        IN     shipsku.qty_expected%TYPE,
                     I_exp_weight     IN     shipsku.weight_expected%TYPE,
                     I_exp_weight_uom IN     shipsku.weight_expected_uom%TYPE)
RETURN BOOLEAN IS

BEGIN
   P_ss_size := P_ss_size + 1;
   P_ss_shipment(P_ss_size)          := I_shipment;
   P_ss_seq_no(P_ss_size)            := I_seq_no;
   P_ss_item(P_ss_size)              := I_item;
   P_ss_distro_no (P_ss_size)        := I_distro_no;
   P_ss_distro_type (P_ss_size)      := I_distro_type;
   P_ss_ref_item(P_ss_size)          := I_ref_item;
   P_ss_carton(P_ss_size)            := I_carton;
   P_ss_inv_status(P_ss_size)        := I_inv_status;
   P_ss_qty_received(P_ss_size)      := I_rcv_qty;
   P_ss_unit_cost(P_ss_size)         := I_cost;
   P_ss_unit_retail(P_ss_size)       := I_retail;
   P_ss_qty_expected(P_ss_size)      := I_exp_qty;
   P_ss_weight_expected(P_ss_size)   := I_exp_weight;
   P_ss_weight_expected_uom(P_ss_size) := I_exp_weight_uom;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'BOL_SQL.INS_SHIPSKU',
                                            to_char(SQLCODE));
      return FALSE;
END INS_SHIPSKU;
-------------------------------------------------------------------------------
FUNCTION UPDATE_INV_STATUS(O_error_message IN OUT VARCHAR2,
                           I_item          IN     item_master.item%TYPE,
                           I_pack_ind      IN     item_master.pack_ind%TYPE,
                           I_from_loc      IN     item_loc.loc%TYPE,
                           I_from_loc_type IN     item_loc.loc_type%TYPE,
                           I_qty           IN     item_loc_soh.stock_on_hand%TYPE,
                           I_inv_status    IN     shipsku.inv_status%TYPE)
RETURN BOOLEAN IS

   L_pgm_name            TRAN_DATA.PGM_NAME%TYPE := 'BOL_SQL.UPDATE_INV_STATUS';
   L_tran_code           tran_data.tran_code%type := 25;
   L_neg_transferred_qty tsfdetail.tsf_qty%TYPE   := NULL;
   L_found               BOOLEAN;

BEGIN
   -- make the transferred_qty negative
   L_neg_transferred_qty := (I_qty * -1);

   if INVADJ_SQL.BUILD_ADJ_UNAVAILABLE(O_error_message,
                                       L_found,
                                       I_item,
                                       I_inv_status,
                                       I_from_loc_type,
                                       I_from_loc,
                                       L_neg_transferred_qty) = FALSE then
      return FALSE;
   end if;

   -- insert a tran_data record (code 25)
   if INVADJ_SQL.BUILD_ADJ_TRAN_DATA(O_error_message,
                                     L_found,
                                     I_item,
                                     I_from_loc_type,
                                     I_from_loc,
                                     L_neg_transferred_qty,
                                     NULL,    -- weight
                                     NULL,    -- weight_uom
                                     NULL,    -- I_order_no
                                     L_pgm_name,
                                     LP_vdate,
                                     L_tran_code,
                                     NULL,
                                     I_inv_status,
                                     NULL,    -- wac
                                     NULL,    -- unit_retail
                                     I_pack_ind) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_pgm_name,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_INV_STATUS;
-------------------------------------------------------------------------------
FUNCTION UPD_FROM_ITEM_LOC(O_error_message    IN OUT VARCHAR2,
                           O_from_av_cost     IN OUT item_loc_soh.av_cost%TYPE,
                           O_from_unit_retail IN OUT item_loc_soh.av_cost%TYPE,
                           I_item             IN     item_master.item%TYPE,
                           I_comp_item        IN     VARCHAR2,
                           I_sellable_ind     IN     item_master.sellable_ind%TYPE,
                           I_item_xform_ind   IN     item_master.item_xform_ind%TYPE,
                           I_inventory_ind    IN     item_master.inventory_ind%TYPE,
                           I_from_loc         IN     item_loc.loc%TYPE,
                           I_tsf_qty          IN     item_loc_soh.stock_on_hand%TYPE,
                           I_resv_qty         IN     item_loc_soh.stock_on_hand%TYPE,
                           I_tsf_weight       IN     item_loc_soh.average_weight%TYPE,
                           I_tsf_weight_uom   IN     uom_class.uom%TYPE,
                           I_eow_date         IN     period.vdate%TYPE)
RETURN BOOLEAN IS

   L_rowid                 ROWID;

   L_tsf_qty               ITEM_LOC_SOH.STOCK_ON_HAND%TYPE; -- hold units or weight
   L_resv_qty              ITEM_LOC_SOH.STOCK_ON_HAND%TYPE; -- hold units or weight
   L_from_loc_type         ITEM_LOC_SOH.LOC_TYPE%TYPE;

   L_from_unit_retail      ITEM_LOC.UNIT_RETAIL%TYPE := NULL;

   L_table                 VARCHAR2(30);
   L_key1                  VARCHAR2(100);
   L_key2                  VARCHAR2(100);
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

   -- cursors
   cursor C_LOCK_ILS is
      select ils.av_cost,
             il.unit_retail,
             ils.loc_type,
             ils.rowid
        from item_loc_soh ils,
             item_loc il
       where ils.item = I_item
         and ils.loc  = I_from_loc
         and il.item  = ils.item
         and il.loc   = ils.loc
      for update of ils.stock_on_hand,
                    ils.pack_comp_soh,
                    ils.tsf_reserved_qty,
                    ils.pack_comp_resv,
                    ils.last_hist_export_date nowait;

BEGIN

   -- update the simple pack catch weight component item's stock buckets with weight
   -- if component item's standard uom is MASS
   if I_tsf_weight is NOT NULL and
      I_tsf_weight_uom is NOT NULL then  -- a simple pack catch weight component item
      if CATCH_WEIGHT_SQL.CALC_COMP_UPDATE_QTY(O_error_message,
                                               L_tsf_qty,
                                               I_item,
                                               I_tsf_qty,
                                               I_tsf_weight,
                                               I_tsf_weight_uom) = FALSE then
         return FALSE;
      end if;
      L_resv_qty := L_tsf_qty * (I_resv_qty/I_tsf_qty);
   else
      L_tsf_qty := I_tsf_qty;
      L_resv_qty := I_resv_qty;
   end if;

   L_table := 'ITEM_LOC_SOH';
   L_key1 := I_item;
   L_key2 := TO_CHAR(I_from_loc);
   open C_LOCK_ILS;
   fetch C_LOCK_ILS into O_from_av_cost,
                         L_from_unit_retail,
                         L_from_loc_type,
                         L_rowid;
   close C_LOCK_ILS;

   update item_loc_soh ils
      set ils.stock_on_hand = DECODE(I_comp_item,
                                     'Y', DECODE(L_from_loc_type,
                                                 'S',
                                                 ils.stock_on_hand - L_tsf_qty,
                                                 ils.stock_on_hand),
                                     ils.stock_on_hand - L_tsf_qty),
          ils.pack_comp_soh = DECODE(I_comp_item,
                                     'Y', DECODE(L_from_loc_type,
                                                 'S',
                                                 ils.pack_comp_soh,
                                                 ils.pack_comp_soh - L_tsf_qty),
                                     ils.pack_comp_soh),
          ils.tsf_reserved_qty = DECODE(I_comp_item,
                                        'Y', ils.tsf_reserved_qty,
                                        GREATEST(ils.tsf_reserved_qty - L_resv_qty, 0)),
          ils.pack_comp_resv = DECODE(I_comp_item,
                                      'Y', GREATEST(ils.pack_comp_resv - L_resv_qty, 0),
                                      ils.pack_comp_resv),
          ils.last_hist_export_date = DECODE(ils.loc_type,'W',
                                             DECODE(SIGN(I_eow_date -
                                                         NVL(ils.last_hist_export_date,I_eow_date- 1)),
                                                    1, ils.last_hist_export_date,
                                                    I_eow_date - 7),
                                              ils.last_hist_export_date),
          ils.last_update_id        = LP_user,
          ils.last_update_datetime  = SYSDATE,
          ils.soh_update_datetime = DECODE(I_comp_item, 'Y',
                                           ils.soh_update_datetime,
                                           DECODE(L_tsf_qty, 0,
                                                  ils.soh_update_datetime,
                                                  SYSDATE))
    where ils.rowid = L_rowid
      and nvl(I_inventory_ind, 'Y') = 'Y';  -- I_inventory_ind is NULL for non-pack items

   if I_sellable_ind = 'N' and I_item_xform_ind = 'Y' then
      if ITEM_XFORM_SQL.CALCULATE_RETAIL(O_error_message,
                                         I_item,
                                         I_from_loc,
                                         O_from_unit_retail) = FALSE then
         return FALSE;
      end if;
   else
      O_from_unit_retail := L_from_unit_retail;
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
                                            'BOL_SQL.UPD_FROM_ITEM_LOC',
                                            to_char(SQLCODE));
      return FALSE;
END UPD_FROM_ITEM_LOC;
-------------------------------------------------------------------------------
FUNCTION UPD_TO_ITEM_LOC(O_error_message   IN OUT rtk_errors.rtk_text%TYPE,
                         I_item            IN     item_master.item%TYPE,
                         I_pack_no         IN     item_master.item%TYPE,
                         I_percent_in_pack IN     NUMBER,
                         I_receive_as_type IN     item_loc.receive_as_type%TYPE,
                         I_tsf_type        IN     tsfhead.tsf_type%TYPE,
                         I_to_loc          IN     item_loc.loc%TYPE,
                         I_to_loc_type     IN     item_loc.loc_type%TYPE,
                         I_tsf_qty         IN     item_loc_soh.stock_on_hand%TYPE,
                         I_exp_qty         IN     item_loc_soh.stock_on_hand%TYPE,
                         I_intran_qty      IN     item_loc_soh.stock_on_hand%TYPE,
                         I_weight_cuom     IN     item_loc_soh.average_weight%TYPE,
                         I_cuom            IN     uom_class.uom%TYPE,
                         I_from_loc        IN     item_loc.loc%TYPE,
                         I_from_loc_type   IN     item_loc.loc_type%TYPE,
                         I_from_wac        IN     item_loc_soh.av_cost%TYPE,
                         I_prim_charge     IN     item_loc_soh.av_cost%TYPE,
                         I_distro_no       IN     shipsku.distro_no%TYPE,
                         I_distro_type     IN     shipsku.distro_type%TYPE,
                         I_intercompany    IN     BOOLEAN)
RETURN BOOLEAN IS

   L_upd_av_cost           item_loc_soh.av_cost%TYPE;
   L_charge_to_loc         item_loc_soh.av_cost%TYPE;
   -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
   L_avg_weight_to         item_loc_soh.average_weight%TYPE := NULL;
   L_soh_curr              item_loc_soh.stock_on_hand%TYPE := NULL;
   L_avg_weight_new        item_loc_soh.average_weight%TYPE := NULL;
   -- 21-Oct-2008 TESCO HSC/Murali 6907185 End

   L_tsf_qty               item_loc_soh.stock_on_hand%TYPE; -- holds unit or weight
   L_intran_qty            item_loc_soh.stock_on_hand%TYPE; -- holds unit or weight
   L_exp_qty               item_loc_soh.stock_on_hand%TYPE;
   L_tsf_expected_qty      item_loc_soh.tsf_expected_qty%TYPE; -- holds unit or weight
   L_pack_comp_exp         item_loc_soh.pack_comp_exp%TYPE; -- holds unit or weight
   L_rowid                 ROWID;

   L_table                 VARCHAR2(30);
   L_key1                  VARCHAR2(100);
   L_key2                  VARCHAR2(100);
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

   -- cursors
   cursor C_LOCK_TO_ILS is
      select ils.tsf_expected_qty,
             ils.pack_comp_exp,
             -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
             ils.average_weight,
             ils.stock_on_hand+ils.in_transit_qty+ils.pack_comp_intran+ils.pack_comp_soh total_soh,
             -- 21-Oct-2008 TESCO HSC/Murali 6907185 End
             ils.rowid
        from item_loc_soh ils
       where ils.item = I_item
         and ils.loc  = I_to_loc
         for update nowait;

BEGIN

   -- for a simple pack catch weight component item, stock buckets will be updated
   -- by weight (in component's suom) if component's suom is MASS, and by units if
   -- component's suom is eaches.
   -- WAC calculation should be based on how stock buckets are updated.
   if I_weight_cuom is NOT NULL and
      I_cuom is NOT NULL then
      if CATCH_WEIGHT_SQL.CALC_COMP_UPDATE_QTY(O_error_message,
                                               L_tsf_qty,
                                               I_item,
                                               I_tsf_qty,
                                               I_weight_cuom,
                                               I_cuom) = FALSE then
         return FALSE;
      end if;
   else
      L_tsf_qty := I_tsf_qty;
   end if;

   --convert chrg from primary to to_loc's currency
   if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                       NULL,
                                       NULL,
                                       NULL,
                                       I_to_loc,
                                       I_to_loc_type,
                                       NULL,
                                       I_prim_charge,
                                       L_charge_to_loc,
                                       'C',
                                       NULL,
                                       NULL) = FALSE then
      return FALSE;
   end if;

   if TRANSFER_COST_SQL.RECALC_WAC(O_error_message,
                                   L_upd_av_cost,
                                   I_distro_no,
                                   I_distro_type,
                                   I_item,
                                   I_pack_no,
                                   I_percent_in_pack,
                                   I_from_loc,
                                   I_from_loc_type,
                                   I_to_loc,
                                   I_to_loc_type,
                                   L_tsf_qty,
                                   I_weight_cuom,
                                   I_from_wac,
                                   L_charge_to_loc,
                                   I_intercompany) = FALSE then
      return FALSE;
   end if;

   L_table := 'ITEM_LOC_SOH';
   L_key1 := I_item;
   L_key2 := TO_CHAR(I_to_loc);
   open C_LOCK_TO_ILS;
   fetch C_LOCK_TO_ILS into L_tsf_expected_qty,
                            L_pack_comp_exp,
                            -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
                            L_avg_weight_to,
                            L_soh_curr,
                            -- 21-Oct-2008 TESCO HSC/Murali 6907185 End
                            L_rowid;
   close C_LOCK_TO_ILS;

   if I_tsf_type = 'PL' then
      L_exp_qty := 0;
   else
      L_exp_qty := I_exp_qty;
   end if;

   --If 1st leg went to an external finisher the expected_qty was updated for the component
   --items of a pack rather then pack_comp_exp.
   --Therefore if sending second leg out of the EF we want to decrement tsf_expected_qty for the comp items.
   if I_from_loc_type = 'E' then
      L_tsf_expected_qty :=  L_tsf_expected_qty - L_exp_qty;
   else
      --Do normal processing:  If receiving as type 'P' then decrement pack_comp_exp otherwise tsf_expected_qty.
      if I_receive_as_type = 'P' then
         L_pack_comp_exp := L_pack_comp_exp - L_exp_qty;
      else
         L_tsf_expected_qty := L_tsf_expected_qty - L_exp_qty;
      end if;
   end if;

   -- update the simple pack catch weight component item's stock buckets with weight
   -- if component item's standard uom is MASS
   if I_weight_cuom is NOT NULL and
      I_cuom is NOT NULL then
      -- a simple pack catch weight component item
      L_intran_qty := L_tsf_qty * (I_intran_qty/I_tsf_qty);
      L_pack_comp_exp := L_tsf_qty * (L_pack_comp_exp/I_tsf_qty);
      L_tsf_expected_qty := L_tsf_qty * (L_tsf_expected_qty/I_tsf_qty);
      -- calculate new average weight at the receiving location
      -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
      if not CATCH_WEIGHT_SQL.CALC_AVERAGE_WEIGHT(O_error_message,
                                                  L_avg_weight_new,
                                                  I_item,
                                                  I_to_loc,
                                                  I_to_loc_type,
                                                  L_soh_curr,
                                                  L_avg_weight_to,
                                                  I_intran_qty,
                                                  I_weight_cuom,
                                                  NULL) then
         return FALSE;
      end if;
      -- 21-Oct-2008 TESCO HSC/Murali 6907185 End
   else
      L_intran_qty := I_intran_qty;
   end if;

   --18-Feb-2010 Tesco HSC/Usha Patil             NBS00015820 Begin
   --Commented the base code as part of  NBS00015820 and the same has been
   --modified and given below.
   /*update item_loc_soh ils
      set ils.in_transit_qty = DECODE(I_receive_as_type,
                                      'P', ils.in_transit_qty,
                                      ils.in_transit_qty + L_intran_qty),
          ils.pack_comp_intran = DECODE(I_receive_as_type,
                                        'P', ils.pack_comp_intran + L_intran_qty,
                                        ils.pack_comp_intran),
          ils.tsf_expected_qty = GREATEST(L_tsf_expected_qty, 0),
          ils.pack_comp_exp = GREATEST(L_pack_comp_exp, 0),
          ils.av_cost = ROUND(L_upd_av_cost, 4),
          -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
          ils.average_weight = NVL(L_avg_weight_new,ils.average_weight),
          -- 21-Oct-2008 TESCO HSC/Murali 6907185 End
          ils.last_update_id        = LP_user,
          ils.last_update_datetime  = SYSDATE
    where ils.rowid = L_rowid;*/
    update item_loc_soh ils
      set ils.in_transit_qty = DECODE(I_receive_as_type,
                                      'P', ils.in_transit_qty,
                                      NULL,
                                      decode(I_to_loc_type,
                                        'W',
                                        ils.in_transit_qty,
                                        ils.in_transit_qty + L_intran_qty),
                                        'E',
                                        decode(I_to_loc_type,
                                        'W',
                                        ils.in_transit_qty,
                                        ils.in_transit_qty + L_intran_qty),
                                      ils.in_transit_qty + L_intran_qty),
          ils.pack_comp_intran = DECODE(I_receive_as_type,
                                        'P', ils.pack_comp_intran + L_intran_qty,
                                        NULL,
                                        decode(I_to_loc_type,
                                        'W',
                                        ils.pack_comp_intran + L_intran_qty,
                                        ils.pack_comp_intran ),
                                        'E',
                                         decode(I_to_loc_type,
                                        'W',
                                        ils.pack_comp_intran + L_intran_qty,
                                      ils.pack_comp_intran ),
                                        ils.pack_comp_intran),
          ils.tsf_expected_qty = GREATEST(L_tsf_expected_qty, 0),
          ils.pack_comp_exp = GREATEST(L_pack_comp_exp, 0),
          ils.av_cost = ROUND(L_upd_av_cost, 4),
          ils.average_weight = NVL(L_avg_weight_new,ils.average_weight),
          ils.last_update_id        = LP_user,
          ils.last_update_datetime  = SYSDATE
    where ils.rowid = L_rowid;
    --18-Feb-2010 Tesco HSC/Usha Patil             NBS00015820 End

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
                                            'BOL_SQL.UPD_TO_ITEM_LOC',
                                            to_char(SQLCODE));
     return FALSE;
END UPD_TO_ITEM_LOC;
-------------------------------------------------------------------------------
FUNCTION UPD_TSF_ITEM_COST(O_error_message    IN OUT VARCHAR2,
                           I_item             IN     item_master.item%TYPE,
                           I_ship_qty         IN     tsf_item_cost.shipped_qty%TYPE,
                           I_tsf_no           IN     tsfhead.tsf_no%TYPE)
   RETURN BOOLEAN IS

   L_rowid                 ROWID;

   L_table                 VARCHAR2(30);
   L_key1                  VARCHAR2(100);
   L_key2                  VARCHAR2(100);
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

   -- cursors
   cursor C_LOCK_TIC is
      select rowid
        from tsf_item_cost
       where tsf_no = I_tsf_no
         and item   = I_item
         and (ict_leg_ind = 'Y'
              or ict_leg_ind is NULL)
      for update of shipped_qty nowait;

BEGIN
   L_table := 'TSF_ITEM_COST';
   L_key1 := I_item;
   L_key2 := TO_CHAR(I_tsf_no);
   open C_LOCK_TIC;
   fetch C_LOCK_TIC into L_rowid;
   close C_LOCK_TIC;

   update tsf_item_cost
      set shipped_qty = nvl(shipped_qty,0) + I_ship_qty
    where rowid = L_rowid;

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
                                            'BOL_SQL.UPD_TSF_ITEM_COST',
                                            to_char(SQLCODE));
      return FALSE;
END UPD_TSF_ITEM_COST;
-------------------------------------------------------------------------------
FUNCTION UPDATE_PACK_LOCS(O_error_message       IN OUT VARCHAR2,
                          I_item                IN     item_master.item%TYPE,
                          I_from_loc            IN     item_loc.loc%TYPE,
                          I_from_loc_type       IN     item_loc.loc_type%TYPE,
                          I_to_loc              IN     item_loc.loc%TYPE,
                          I_to_loc_type         IN     item_loc.loc_type%TYPE,
                          I_to_receive_as_type  IN     item_loc.receive_as_type%TYPE,
                          I_tsf_type            IN     tsfhead.tsf_type%TYPE,
                          I_tsf_qty             IN     item_loc_soh.stock_on_hand%TYPE,
                          I_tsf_weight_cuom     IN     item_loc_soh.average_weight%TYPE,
                          I_intran_qty          IN     item_loc_soh.stock_on_hand%TYPE,
                          I_intran_weight_cuom  IN     item_loc_soh.average_weight%TYPE,
                          I_resv_exp_qty        IN     item_loc_soh.stock_on_hand%TYPE)
RETURN BOOLEAN IS

   L_exp_qty               item_loc_soh.stock_on_hand%TYPE;

   L_table                 VARCHAR2(30);
   L_key1                  VARCHAR2(100);
   L_key2                  VARCHAR2(100);
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);

   L_rowid                 ROWID;
   L_avg_weight_from	   item_loc_soh.average_weight%TYPE := NULL;
   L_avg_weight_to	   item_loc_soh.average_weight%TYPE := NULL;
   L_soh_curr              item_loc_soh.stock_on_hand%TYPE := NULL;
   L_avg_weight_new   	   item_loc_soh.average_weight%TYPE := NULL;

   L_from_receive_as_type  item_loc.receive_as_type%TYPE;
   --18-Feb-2010 Tesco HSC/Usha Patil     NBS00015820 Begin
   L_to_receive_as_type  item_loc.receive_as_type%TYPE:= NULL;
   --18-Feb-2010 Tesco HSC/Usha Patil     NBS00015820 End

   -- cursors
   cursor C_LOCK_FROM_ITEM_LOC is
      select ils.average_weight,
             ils.stock_on_hand+ils.in_transit_qty+ils.pack_comp_intran+ils.pack_comp_soh total_soh,
             ils.rowid
        from item_loc_soh ils
       where ils.loc  = I_from_loc
         and ils.item = I_item
         for update nowait;

   cursor C_LOCK_TO_ITEM_LOC is
      select ils.average_weight,
             ils.stock_on_hand+ils.in_transit_qty+ils.pack_comp_intran+ils.pack_comp_soh total_soh,
             ils.rowid
        from item_loc_soh ils
       where ils.loc  = I_to_loc
         and ils.item = I_item
         for update nowait;

   cursor C_FROM_RCV_AS_TYPE is
      select nvl(receive_as_type, 'E')
        from item_loc
       where item = I_item
         and loc = I_from_loc;

   --18-Feb-2010 Tesco HSC/Usha Patil     NBS00015820 Begin
   cursor C_TO_RCV_AS_TYPE is
      select nvl(receive_as_type, 'P')
        from item_loc
       where item = I_item
         and loc = I_to_loc;
   --18-Feb-2010 Tesco HSC/Usha Patil     NBS00015820 End
BEGIN

   L_table := 'ITEM_LOC_SOH';
   L_key1 := I_item;
   L_key2 := TO_CHAR(I_from_loc);

   open C_FROM_RCV_AS_TYPE;
   fetch C_FROM_RCV_AS_TYPE into L_from_receive_as_type;
   close C_FROM_RCV_AS_TYPE;

   if L_from_receive_as_type = 'P' then
      open  C_LOCK_FROM_ITEM_LOC;
      fetch C_LOCK_FROM_ITEM_LOC into L_avg_weight_from,
                                      L_soh_curr,
                                      L_rowid;
      close C_LOCK_FROM_ITEM_LOC;

      -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
      -- Removed the call to CATCH_WEIGHT_SQL.CALC_AVERAGE_WEIGHT
      -- 21-Oct-2008 TESCO HSC/Murali 6907185 End

      update item_loc_soh ils
         set ils.stock_on_hand    = ils.stock_on_hand - I_tsf_qty,
             ils.tsf_reserved_qty = GREATEST(ils.tsf_reserved_qty - I_resv_exp_qty, 0),
             -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
             -- Removed Update of Column ils.average_weight
             -- 21-Oct-2008 TESCO HSC/Murali 6907185 End
             ils.soh_update_datetime = DECODE(I_tsf_qty,
                                              0, soh_update_datetime,
                                              SYSDATE),
             ils.last_update_datetime = SYSDATE,
             ils.last_update_id = LP_user
       where ils.rowid = L_rowid;
   end if;

   --If 'to' loc is IF/EF, the I_to_receive_as_type will be 'E', so it will not execute this

   --18-Feb-2010 Tesco HSC/Usha Patil     NBS00015820 Begin
   SQL_LIB.SET_MARK('OPEN', 'C_TO_RCV_AS_TYPE', 'ITEM_LOC', NULL);
   open C_TO_RCV_AS_TYPE;
   SQL_LIB.SET_MARK('FETCH', 'C_TO_RCV_AS_TYPE', 'ITEM_LOC', NULL);
   fetch C_TO_RCV_AS_TYPE into L_to_receive_as_type;
   SQL_LIB.SET_MARK('CLOSE', 'C_TO_RCV_AS_TYPE', 'ITEM_LOC', NULL);
   close C_TO_RCV_AS_TYPE;

   if I_to_loc_type = 'W' and (I_to_receive_as_type = 'P' or L_to_receive_as_type='P') then
   --18-Feb-2010 Tesco HSC/Usha Patil     NBS00015820 End

      L_key2 := TO_CHAR(I_to_loc);
      if I_tsf_type = 'PL' then
         L_exp_qty := 0;
      else
         L_exp_qty := I_resv_exp_qty;
      end if;

      open  C_LOCK_TO_ITEM_LOC;
      fetch C_LOCK_TO_ITEM_LOC into L_avg_weight_to,
                                    L_soh_curr,
                                    L_rowid;
      close C_LOCK_TO_ITEM_LOC;

      -- Update average weight for a simple pack catch weight item at to loc.
      L_avg_weight_new := NULL;
      if I_intran_weight_cuom is NOT NULL then
         if not CATCH_WEIGHT_SQL.CALC_AVERAGE_WEIGHT(O_error_message,
                                                     L_avg_weight_new,
                                                     I_item,
                                                     -- 21-Oct-2008 TESCO HSC/Murali 6907185 Begin
                                                     I_to_loc,
                                                     I_to_loc_type,
                                                     -- 21-Oct-2008 TESCO HSC/Murali 6907185 End
                                                     L_soh_curr,
                                                     L_avg_weight_to,
                                                     I_intran_qty,
                                                     I_intran_weight_cuom,
                                                     NULL) then
            return FALSE;
         end if;
      end if;

      --If from loc is an external finisher the expected qty was updated for the
      --pack comp items rather than the pack.  If from_loc is EF then don't decrement the pack's exp qty.
      update item_loc_soh ils
         set ils.in_transit_qty   = ils.in_transit_qty + I_intran_qty,
             ils.tsf_expected_qty = DECODE(I_from_loc_type, 'E',
                                           ils.tsf_expected_qty,
                                           GREATEST(ils.tsf_expected_qty - L_exp_qty, 0)),
             ils.average_weight   = NVL(L_avg_weight_new, ils.average_weight),
             ils.last_update_id        = LP_user,
             ils.last_update_datetime  = SYSDATE
       where ils.rowid = L_rowid;
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
                                            'BOL_SQL.UPDATE_PACK_LOCS',
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_PACK_LOCS;
-------------------------------------------------------------------------------------------
FUNCTION CARTON_EXISTS(O_error_message IN OUT VARCHAR2,
                       O_carton_exists IN OUT BOOLEAN,
                       I_carton        IN     shipsku.carton%TYPE,
                       I_bol_no        IN     shipment.bol_no%TYPE)

RETURN BOOLEAN IS

   L_program VARCHAR2(64) := 'BOL_SQL.CARTON_EXISTS';
   L_tmp     VARCHAR2(1);

   -- cursors
   cursor C_CARTON_EXISTS is
      select 'x'
        from shipment sh,
             shipsku ss
       where sh.shipment = ss.shipment
         and sh.bol_no = I_bol_no
         and ss.carton = I_carton;

BEGIN
   if I_carton is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_carton','NULL','NOT NULL');
      return FALSE;
   end if;

   if I_bol_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_bol_no','NULL','NOT NULL');
      return FALSE;
   end if;

   open C_CARTON_EXISTS;
   fetch C_CARTON_EXISTS into L_tmp;
   ---
   if (C_CARTON_EXISTS%FOUND) then
      O_carton_exists := TRUE;
   else
      O_carton_exists := FALSE;
   end if;
   ---
   close C_CARTON_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CARTON_EXISTS;
-------------------------------------------------------------------------------
FUNCTION WRITE_ISSUES(O_error_message   IN OUT VARCHAR2,
                      I_item            IN     item_master.item%TYPE,
                      I_from_wh         IN     item_loc.loc%TYPE,
                      I_transferred_qty IN     tsfdetail.tsf_qty%TYPE,
                      I_eow_date        IN     period.vdate%TYPE)
RETURN BOOLEAN IS

   L_day           NUMBER(2);
   L_mth           NUMBER(2);
   L_year          NUMBER(4);
   L_day_454       NUMBER(2);
   L_week_454      NUMBER(2);
   L_month_454     NUMBER(2);
   L_year_454      NUMBER(4);
   L_return_code   VARCHAR2(5) := 'none';

   L_issues        item_loc_hist.sales_issues%TYPE := ROUND(I_transferred_qty);

   L_rowid         ROWID;

   L_not_in_array  BOOLEAN := TRUE;

   L_table         VARCHAR2(30);
   L_key1          VARCHAR2(100);
   L_key2          VARCHAR2(100);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   --18-Oct-2011 Tesco HSC/Nandini Mariyappa Defect Id: PrfNBS023626 Begin
   cursor C_LOCK_ITEM_LOC_HIST is
      select ilh.rowid
        from item_loc_hist ilh
       where ilh.item        = I_item
         and ilh.loc         = I_from_wh
         and ilh.eow_date    = I_eow_date
         and ilh.sales_type  = 'I'
         for update nowait;
   --18-Oct-2011 Tesco HSC/Nandini Mariyappa Defect Id: PrfNBS023626 End

BEGIN
   L_day  := TO_NUMBER(TO_CHAR(I_eow_date, 'DD'));
   L_mth  := TO_NUMBER(TO_CHAR(I_eow_date, 'MM'));
   L_year := TO_NUMBER(TO_CHAR(I_eow_date, 'YYYY'));

   CAL_TO_454(L_day,
              L_mth,
              L_year,
              L_day_454,
              L_week_454,
              L_month_454,
              L_year_454,
              L_return_code,
              O_error_message);
   if L_return_code = 'FALSE' then
      return FALSE;
   end if;

   L_table := 'ITEM_LOC_HIST';
   L_key1 := I_item;
   L_key2 := TO_CHAR(I_from_wh);
   open  C_LOCK_ITEM_LOC_HIST;
   fetch C_LOCK_ITEM_LOC_HIST into L_rowid;
   if C_LOCK_ITEM_LOC_HIST%FOUND then
      close C_LOCK_ITEM_LOC_HIST;

      P_upd_ilh_size := P_upd_ilh_size + 1;
      P_upd_ilh_sales_issues(P_upd_ilh_size)   := L_issues;
      P_upd_ilh_rowid_TBL(P_upd_ilh_size)      := L_rowid;

   else
      close C_LOCK_ITEM_LOC_HIST;

      FOR i IN 1..P_ilh_size LOOP
         if P_ilh_item(i) = I_item and
            P_ilh_loc(i) = I_from_wh and
            P_ilh_eow_date(i) = I_eow_date then
            P_ilh_sales_issues(i) := P_ilh_sales_issues(i) + L_issues;
            L_not_in_array := FALSE;
         end if;
      END LOOP;

      if L_not_in_array then
         P_ilh_size := P_ilh_size + 1;
         P_ilh_item(P_ilh_size)                  := I_item;
         P_ilh_loc(P_ilh_size)                   := I_from_wh;
         P_ilh_loc_type(P_ilh_size)              := 'W';
         P_ilh_eow_date(P_ilh_size)              := I_eow_date;
         P_ilh_week_454(P_ilh_size)              := L_week_454;
         P_ilh_month_454(P_ilh_size)             := L_month_454;
         P_ilh_year_454(P_ilh_size)              := L_year_454;
         P_ilh_sales_type(P_ilh_size)            := 'I';
         P_ilh_sales_issues(P_ilh_size)          := L_issues;
         P_ilh_create_datetime(P_ilh_size)       := sysdate;
         P_ilh_last_update_datetime(P_ilh_size)  := sysdate;
         P_ilh_last_update_id(P_ilh_size)        := LP_user;
      end if;

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
                                            'BOL_SQL.WRITE_ISSUES',
                                            to_char(SQLCODE));
      return FALSE;
END WRITE_ISSUES;
-------------------------------------------------------------------------------
--public function--
FUNCTION RECEIPT_PUT_BOL(O_error_message     IN OUT rtk_errors.rtk_text%TYPE,
                         I_bol_no            IN     shipment.bol_no%TYPE,
                         I_phy_to_loc        IN     shipment.to_loc%TYPE,
                         I_ship_date         IN     period.vdate%TYPE,
                         I_shipment          IN     shipment.shipment%TYPE,
                         I_phy_from_loc      IN     item_loc.loc%TYPE,
                         I_to_loc_type       IN     tsfhead.to_loc_type%TYPE,
                         I_from_loc_type     IN     tsfhead.from_loc_type%TYPE,
                         I_tsf_no            IN     tsfhead.tsf_no%TYPE,
                         I_status            IN     tsfhead.status%TYPE,
                         I_tsf_type          IN     tsfhead.tsf_type%TYPE)
RETURN BOOLEAN IS


   dist_cnt    BINARY_INTEGER        := NULL;
   L_del_type  ORDCUST.DELIVER_TYPE%TYPE  := NULL;  --- not used for receipts
   L_program   VARCHAR2(50)          := 'BOL_SQL.RECEIPT_PUT_BOL';

BEGIN

   if I_bol_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','I_bol_no',
                                            L_program,NULL);
      return FALSE;
   end if;
   if I_phy_from_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','I_phy_from_loc',
                                            L_program,NULL);
      return FALSE;
   end if;
   if I_phy_to_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','I_phy_to_loc',
                                            L_program, NULL);
      return FALSE;
   end if;
   if I_ship_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','I_ship_date',
                                            L_program,NULL );
      return FALSE;
   end if;

   if I_phy_from_loc = I_phy_to_loc then
      O_error_message := SQL_LIB.CREATE_MSG('SAME_LOC',I_phy_from_loc,null,null);
      return FALSE;
   end if;

   if I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','I_tsf_no',
                                            L_program, NULL);
      return FALSE;
   end if;

   LP_bol_rec := NULL;

   if INIT_BOL_PROCESS(O_error_message) = FALSE then
      return FALSE;
   end if;

   LP_bol_rec.bol_no            := I_bol_no;
   LP_bol_rec.ship_no           := I_shipment;
   LP_bol_rec.phy_from_loc      := I_phy_from_loc;
   LP_bol_rec.phy_from_loc_type := I_from_loc_type;
   LP_bol_rec.phy_to_loc        := I_phy_to_loc;
   LP_bol_rec.phy_to_loc_type   := I_to_loc_type;
   LP_bol_rec.tran_date         := I_ship_date;

   if DATES_SQL.GET_EOW_DATE(O_error_message,
                             LP_bol_rec.eow_date,
                             I_ship_date) = FALSE then
      return FALSE;
   end if;

   /* reset the distro array */
   LP_bol_rec.distros.DELETE;
   dist_cnt := 1;

   LP_bol_rec.distros(dist_cnt).tsf_no := I_tsf_no;
   LP_bol_rec.distros(dist_cnt).tsf_status := I_status;
   LP_bol_rec.distros(dist_cnt).tsf_type := I_tsf_type;
   LP_bol_rec.distros(dist_cnt).tsf_del_type := L_del_type;
   LP_bol_rec.distros(dist_cnt).new_tsf_ind := 'N';

   LP_receipt_ind := 'Y';

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END RECEIPT_PUT_BOL;

-------------------------------------------------------------------------------

--public function--
FUNCTION RECEIPT_PUT_TSF_ITEM(O_error_message    IN OUT rtk_errors.rtk_text%TYPE,
                              O_tsf_seq_no       IN OUT tsfdetail.tsf_seq_no%TYPE,
                              O_ss_seq_no        IN OUT shipsku.seq_no%TYPE,
                              I_tsf_no           IN     tsfhead.tsf_no%TYPE,
                              I_item             IN     item_master.item%TYPE,
                              I_carton           IN     shipsku.carton%TYPE,
                              I_qty              IN     tsfdetail.tsf_qty%TYPE,
                              I_weight           IN     item_loc_soh.average_weight%TYPE,
                              I_weight_uom       IN     uom_class.uom%TYPE,
                              I_inv_status       IN     inv_status_codes.inv_status_code%TYPE,
                              I_phy_from_loc     IN     item_loc.loc%TYPE,
                              I_from_loc_type    IN     item_loc.loc_type%TYPE,
                              I_phy_to_loc       IN     item_loc.loc%TYPE,
                              I_to_loc_type      IN     item_loc.loc_type%TYPE,
                              I_tsfhead_to_loc   IN     item_loc.loc%TYPE,
                              I_tsfhead_from_loc IN     item_loc.loc%TYPE,
                              I_tsf_type         IN     tsfhead.tsf_type%TYPE,
                              I_ref_item         IN     item_master.item%TYPE,
                              I_dept             IN     item_master.dept%TYPE,
                              I_class            IN     item_master.class%TYPE,
                              I_subclass         IN     item_master.subclass%TYPE,
                              I_pack_ind         IN     item_master.pack_ind%TYPE,
                              I_pack_type        IN     item_master.pack_type%TYPE,
                              I_simple_pack_ind  IN     item_master.simple_pack_ind%TYPE,
                              I_catch_weight_ind IN     item_master.catch_weight_ind%TYPE,
                              I_supp_pack_size   IN     item_supp_country.supp_pack_size%TYPE,
                              I_sellable_ind     IN     item_master.sellable_ind%TYPE,
                              I_item_xform_ind   IN     item_master.item_xform_ind%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(50)                     := 'BOL_SQL.RECEIPT_PUT_TSF_ITEM';

   L_tsf_qty            tsfdetail.tsf_qty%TYPE           := NULL;
   L_ship_qty           tsfdetail.ship_qty%TYPE          := NULL;

   dist_cnt      BINARY_INTEGER := 1;
   item_cnt      BINARY_INTEGER := 1;

   cursor C_BOL_EXISTS_SEQ is
      select NVL(max(seq_no +1), 1)
        from shipsku
       where shipment =  LP_bol_rec.ship_no
         and item = I_item;

BEGIN

   if I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','I_tsf_no',
                                            L_program,NULL);
      return FALSE;
   end if;
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','I_item',
                                            L_program,NULL);
      return FALSE;
   end if;
   if I_qty is NULL or I_qty < 0 then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_qty',
                                            'NULL','NOT NULL');
      return FALSE;
   end if;

   dist_cnt := LP_bol_rec.distros.COUNT;
   item_cnt := LP_bol_rec.distros(dist_cnt).bol_items.COUNT;
   item_cnt := item_cnt + 1;

   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item           := I_item;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ref_item       := I_ref_item;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).dept           := I_dept;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).class          := I_class;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).subclass       := I_subclass;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).pack_ind       := I_pack_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).pack_type      := I_pack_type;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).simple_pack_ind  := I_simple_pack_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).catch_weight_ind := I_catch_weight_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).supp_pack_size := I_supp_pack_size;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).sellable_ind  := I_sellable_ind;
   LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).item_xform_ind := I_item_xform_ind;

      -- Perform check to avoid shipsku PK violation.
   open C_BOL_EXISTS_SEQ;
   fetch C_BOL_EXISTS_SEQ into LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ss_seq_no;
   if C_BOL_EXISTS_SEQ%NOTFOUND then
      if NEXT_SS_SEQ_NO(O_error_message,
                        LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ss_seq_no) = FALSE then
         return FALSE;
      end if;
   end if;

   close C_BOL_EXISTS_SEQ;

   O_ss_seq_no := LP_bol_rec.distros(dist_cnt).bol_items(item_cnt).ss_seq_no;

   L_tsf_qty := 0;
   L_ship_qty := 0;

   --this item is not on the transfer, insert to TSFDETAIL
   if INS_TSFDETAIL(O_error_message,
                    O_tsf_seq_no,
                    I_tsf_no,
                    I_item,
                    I_supp_pack_size,
                    I_inv_status,
                    L_tsf_qty) = FALSE then
      return FALSE;
   end if;

   if I_tsf_type != 'EG' then
      if TRANSFER_CHARGE_SQL.DEFAULT_CHRGS(
                        O_error_message,
                        I_tsf_no,
                        I_tsf_type,
                        O_tsf_seq_no,
                        NULL,              --ship_no     --only populate for EG tsfs
                        NULL,              --ship_seq_no --only populate for EG tsfs
                        I_tsfhead_from_loc,
                        I_from_loc_type,
                        I_tsfhead_to_loc,
                        I_to_loc_type,
                        I_item) = FALSE then
         return FALSE;
      end if;
   end if;

   if TSF_ITEM_COMMON(O_error_message,
                      I_tsf_no,
                      I_carton,
                      I_qty,
                      I_weight,
                      I_weight_uom,
                      I_phy_from_loc,
                      I_from_loc_type,
                      I_phy_to_loc,
                      I_to_loc_type,
                      I_tsfhead_to_loc,
                      I_tsfhead_from_loc,
                      I_tsf_type,
                      I_inv_status,
                      L_tsf_qty,
                      L_ship_qty,
                      O_tsf_seq_no,
                      item_cnt,
                      dist_cnt) = FALSE then
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
END RECEIPT_PUT_TSF_ITEM;
-------------------------------------------------------------------------------

FUNCTION INIT_BOL_PROCESS(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN IS

BEGIN

   LP_ss_seq_no := 0;

   if STKLEDGR_SQL.INIT_TRAN_DATA_INSERT(O_error_message) = FALSE then
      return FALSE;
   end if;

   if INVADJ_SQL.INIT_ALL(O_error_message) = FALSE then
      return FALSE;
   end if;

   P_ss_size               := 0;
   P_ilh_size              := 0;
   P_upd_ilh_size          := 0;

   LP_receipt_ind := 'N';

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.INIT_BOL_PROCESS',
                                            to_char(SQLCODE));
      return FALSE;
END INIT_BOL_PROCESS;
-------------------------------------------------------------------------------
FUNCTION FLUSH_BOL_PROCESS(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN IS

BEGIN

   if STKLEDGR_SQL.FLUSH_TRAN_DATA_INSERT(O_error_message) = FALSE then
      return FALSE;
   end if;

   if INVADJ_SQL.FLUSH_ALL(O_error_message) = FALSE then
      return FALSE;
   end if;

   if FLUSH_SHIPSKU_INSERT(O_error_message) = FALSE then
      return FALSE;
   end if;

   if FLUSH_ILH_INSERT(O_error_message) = FALSE then
      return FALSE;
   end if;

   if FLUSH_ILH_UPDATE(O_error_message) = FALSE then
      return FALSE;
   end if;


   LP_receipt_ind := 'N';
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.FLUSH_BOL_PROCESS',
                                            to_char(SQLCODE));
      return FALSE;
END FLUSH_BOL_PROCESS;
-------------------------------------------------------------------------------
FUNCTION NEXT_SS_SEQ_NO(O_error_message IN OUT rtk_errors.rtk_text%TYPE,
                        O_ss_seq_no     IN OUT shipsku.seq_no%TYPE)
RETURN BOOLEAN IS

BEGIN
   LP_ss_seq_no := LP_ss_seq_no + 1;
   O_ss_seq_no := LP_ss_seq_no;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.NEXT_SS_SEQ_NO',
                                            to_char(SQLCODE));
      return FALSE;
END NEXT_SS_SEQ_NO;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

/*------------------------------------------------------------------------*/
/* This function is only here as a debug aid.  It should not be used      */
/*   in prodcution code.                                                  */
/*------------------------------------------------------------------------*/
FUNCTION DISPLAY_BOL(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN IS

I_bol_record    bol_sql.bol_rec := LP_bol_rec;
        i BINARY_INTEGER := 1;
        j BINARY_INTEGER := 1;
        k BINARY_INTEGER := 1;
        l BINARY_INTEGER := 1;

BEGIN

--BOL
dbms_output.put_line(' BOL:'|| I_bol_record.bol_no);
dbms_output.put_line(' SHIP:'|| I_bol_record.ship_no);
dbms_output.put_line(' PHY_FROM_LOC:'|| I_bol_record.phy_from_loc);
dbms_output.put_line(' PHY_FROM_LOC_TYPE:'|| I_bol_record.phy_from_loc_type);
dbms_output.put_line(' PHY_TO_LOC:'|| I_bol_record.phy_to_loc);
dbms_output.put_line(' PHY_TO_LOC_TYPE:'|| I_bol_record.phy_to_loc_type);
dbms_output.put_line(' TRAN_DATE:'|| I_bol_record.tran_date);
dbms_output.put_line(' EOW_DATE:'|| I_bol_record.eow_date);

        --DISTRO
        if I_bol_record.distros.COUNT > 0 then
        FOR i IN I_bol_record.distros.FIRST..I_bol_record.distros.LAST LOOP
                null;

                dbms_output.put_line('---ALLOC: '||I_bol_record.distros(i).alloc_no);
                dbms_output.put_line('---ALLOC_STATUS: '||I_bol_record.distros(i).alloc_status);
                dbms_output.put_line('---ALLOC_TYPE: '||I_bol_record.distros(i).alloc_type);
                dbms_output.put_line('---ALLOC_NEW_DET: '||I_bol_record.distros(i).new_alloc_detail_ind);
                dbms_output.put_line('---ALLOC_FROMLOCPHY: '||I_bol_record.distros(i).alloc_from_loc_phy);
                dbms_output.put_line('---ALLOC_FROMLOCVIR: '||I_bol_record.distros(i).alloc_from_loc_vir);

                dbms_output.put_line('---TSF: '||I_bol_record.distros(i).tsf_no);
                dbms_output.put_line('---TSF_STATUS: '||I_bol_record.distros(i).tsf_status);
                dbms_output.put_line('---TSF_TYPE: '||I_bol_record.distros(i).tsf_type);
                dbms_output.put_line('---TSF_DEL_TYPE: '||I_bol_record.distros(i).tsf_del_type);
                dbms_output.put_line('---TSF_NEW_TSF: '||I_bol_record.distros(i).new_tsf_ind);

                --ITEM
                if I_bol_record.distros(i).bol_items.COUNT > 0 then
                FOR j IN I_bol_record.distros(i).bol_items.FIRST..I_bol_record.distros(i).bol_items.LAST LOOP
                        null;
                        dbms_output.put_line('------ITEM: '||I_bol_record.distros(i).bol_items(j).item);
                        dbms_output.put_line('------REFITEM: '||I_bol_record.distros(i).bol_items(j).ref_item);
                        dbms_output.put_line('------PACK_IND: '||I_bol_record.distros(i).bol_items(j).pack_ind);
                        dbms_output.put_line('------PACK_TYPE: '||I_bol_record.distros(i).bol_items(j).pack_type);
                        dbms_output.put_line('------PACKSIZE: '||I_bol_record.distros(i).bol_items(j).supp_pack_size);
                        dbms_output.put_line('------DEPT: '||I_bol_record.distros(i).bol_items(j).dept);
                        dbms_output.put_line('------CLASS: '||I_bol_record.distros(i).bol_items(j).class);
                        dbms_output.put_line('------SUBCLASS: '||I_bol_record.distros(i).bol_items(j).subclass);
                        dbms_output.put_line('------CARTON: '||I_bol_record.distros(i).bol_items(j).carton);
                        dbms_output.put_line('------QTY: '||to_char(I_bol_record.distros(i).bol_items(j).qty));
                        dbms_output.put_line('------INV_STATUS: '||to_char(I_bol_record.distros(i).bol_items(j).inv_status));

                        dbms_output.put_line('------TSFSEQ: '||I_bol_record.distros(i).bol_items(j).td_tsf_seq_no);
                        dbms_output.put_line('------TD_TSF_QTY: '||I_bol_record.distros(i).bol_items(j).td_tsf_qty);
                        dbms_output.put_line('------TD_TSF_SHIP: '||I_bol_record.distros(i).bol_items(j).td_ship_qty);

                        dbms_output.put_line('------alloc_tophy: '||I_bol_record.distros(i).bol_items(j).ad_to_loc_phy);
                        dbms_output.put_line('------alloc_tovir: '||I_bol_record.distros(i).bol_items(j).ad_to_loc_vir);
                        dbms_output.put_line('------ad_tsf_qty: '||I_bol_record.distros(i).bol_items(j).ad_tsf_qty);
                        dbms_output.put_line('------ad_alloc_qty: '||I_bol_record.distros(i).bol_items(j).ad_alloc_qty);

                        dbms_output.put_line('------ss_seq_no: '||I_bol_record.distros(i).bol_items(j).ss_seq_no);

                        --VIR LOCS
                        if I_bol_record.distros(i).bol_items(j).virtual_locs.COUNT > 0 then
                        FOR l IN I_bol_record.distros(i).bol_items(j).virtual_locs.FIRST..I_bol_record.distros(i).bol_items(j).virtual_locs.LAST LOOP
                                null;
                                dbms_output.put_line('---------VIR_FROM_LOC: '||to_char(I_bol_record.distros(i).bol_items(j).virtual_locs(l).vir_from_loc));
                                dbms_output.put_line('---------VIR_FROM_LOCtype: '||to_char(I_bol_record.distros(i).bol_items(j).virtual_locs(l).vir_from_loc_type));
                                dbms_output.put_line('---------VIR_TO_LOC: '||to_char(I_bol_record.distros(i).bol_items(j).virtual_locs(l).vir_to_loc));
                                dbms_output.put_line('---------VIR_TO_LOCtype: '||to_char(I_bol_record.distros(i).bol_items(j).virtual_locs(l).vir_to_loc_type));
                                dbms_output.put_line('---------FROMAVCOST: '||to_char(I_bol_record.distros(i).bol_items(j).virtual_locs(l).from_av_cost));
                                dbms_output.put_line('---------RCVASTYPE: '||to_char(I_bol_record.distros(i).bol_items(j).virtual_locs(l).receive_as_type));
                                dbms_output.put_line('---------VIR_QTY: '||to_char(I_bol_record.distros(i).bol_items(j).virtual_locs(l).vir_qty));
                        END LOOP; --VIR LOCS
                        end if;

                        dbms_output.put_line('----------------------------------------------------------');
                        dbms_output.put_line('----------------------------------------------------------');


                END LOOP; --ITEM
                end if;

        END LOOP; --DIST
        end if;

        return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.DISPLAY_BOL',
                                            TO_CHAR(SQLCODE));
     return FALSE;
END DISPLAY_BOL;

-------------------------------------------------------------------------------

FUNCTION FLUSH_SHIPSKU_INSERT(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN IS

BEGIN
   if P_ss_size > 0 then
      FORALL i IN 1..P_ss_size
         insert into shipsku(shipment,
                             seq_no,
                             item,
                             distro_no,
                             distro_type,
                             ref_item,
                             carton,
                             inv_status,
                             status_code,
                             qty_received,
                             unit_cost,
                             unit_retail,
                             qty_expected,
                             match_invc_id,
                             weight_expected,
                             weight_expected_uom)
                      values(P_ss_shipment(i),
                             P_ss_seq_no(i),
                             P_ss_item(i),
                             P_ss_distro_no(i),
                             P_ss_distro_type(i),
                             P_ss_ref_item(i),
                             P_ss_carton(i),
                             P_ss_inv_status(i),
                             'A',
                             P_ss_qty_received(i),
                             P_ss_unit_cost(i),
                             P_ss_unit_retail(i),
                             P_ss_qty_expected(i),
                             NULL,
                             P_ss_weight_expected(i),
                             P_ss_weight_expected_uom(i));
   end if;

   P_ss_size := 0;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.FLUSH_SHIPSKU_INSERT',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END FLUSH_SHIPSKU_INSERT;
-------------------------------------------------------------------------------
FUNCTION FLUSH_ILH_INSERT(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN IS

BEGIN
   if P_ilh_size > 0 then
      FORALL i IN 1..P_ilh_size
         insert into item_loc_hist(item,
                                   loc,
                                   loc_type,
                                   eow_date,
                                   week_454,
                                   month_454,
                                   year_454,
                                   sales_type,
                                   sales_issues,
                                   value,
                                   gp,
                                   stock,
                                   retail,
                                   av_cost,
                                   create_datetime,
                                   last_update_datetime,
                                   last_update_id)
                            values(P_ilh_item(i),
                                   P_ilh_loc(i),
                                   P_ilh_loc_type(i),
                                   P_ilh_eow_date(i),
                                   P_ilh_week_454(i),
                                   P_ilh_month_454(i),
                                   P_ilh_year_454(i),
                                   'I',
                                   P_ilh_sales_issues(i),
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   P_ilh_create_datetime(i),
                                   P_ilh_create_datetime(i),
                                   P_ilh_last_update_id(i));
   end if;

   P_ilh_size := 0;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.FLUSH_ILH_INSERT',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END FLUSH_ILH_INSERT;
-------------------------------------------------------------------------------
FUNCTION FLUSH_ILH_UPDATE(O_error_message IN OUT rtk_errors.rtk_text%TYPE)
RETURN BOOLEAN IS

BEGIN
   if P_upd_ilh_size > 0 then
      FORALL i IN 1..P_upd_ilh_size
         update item_loc_hist ilh
            set sales_issues = ilh.sales_issues + P_upd_ilh_sales_issues(i)
          where ilh.rowid = P_upd_ilh_rowid_TBL(i);

   end if;

   P_upd_ilh_size := 0;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BOL_SQL.FLUSH_ILH_UPDATE',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END FLUSH_ILH_UPDATE;
-----------------------------------------------------------------------------------------------
FUNCTION PUT_TSF_AV_RETAIL(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_shipment_retail   IN       TSFDETAIL.FINISHER_AV_RETAIL%TYPE,
                           I_shipment_qty      IN       TSFDETAIL.FINISHER_UNITS%TYPE,
                           I_tsf_no            IN       TSFDETAIL.TSF_NO%TYPE,
                           I_item              IN       TSFDETAIL.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(64) := 'BOL_SQL.PUT_TSF_AV_RETAIL';
   L_old_retail  TSFDETAIL.FINISHER_AV_RETAIL%TYPE;
   L_new_retail  TSFDETAIL.FINISHER_AV_RETAIL%TYPE;
   L_old_qty     TSFDETAIL.FINISHER_UNITS%TYPE;
   L_new_qty     TSFDETAIL.FINISHER_UNITS%TYPE;
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_OLD_TSF_RETAIL is
      select nvl(finisher_av_retail,0),
             nvl(finisher_units,0)
        from tsfdetail
       where tsf_no = I_tsf_no
         and item   = I_item
         for update nowait;

BEGIN
   if I_shipment_retail is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQ_INPUT_IS_NULL',
                                            'I_shipment_retail',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_shipment_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQ_INPUT_IS_NULL',
                                            'I_shipment_qty',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQ_INPUT_IS_NULL',
                                            'I_tsf_no',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQ_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_OLD_TSF_RETAIL',
                    'TSFDETAIL',
                    'Tsf_no: '||to_char(I_tsf_no)||',Item: '||I_item);
   open C_OLD_TSF_RETAIL;

   SQL_LIB.SET_MARK('FETCH',
                    'C_OLD_TSF_RETAIL',
                    'TSFDETAIL',
                    'Tsf_no: '||to_char(I_tsf_no)||',Item: '||I_item);
   fetch C_OLD_TSF_RETAIL into L_old_retail,
                               L_old_qty;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_OLD_TSF_RETAIL',
                    'TSFDETAIL',
                    'Tsf_no: '||to_char(I_tsf_no)||',Item: '||I_item);
   close C_OLD_TSF_RETAIL;

   L_new_qty   := L_old_qty + I_shipment_qty;

   if L_new_qty = 0 then
      L_new_retail := NULL;
      L_new_qty    := NULL;
   else
      L_new_retail := ((L_old_qty*L_old_retail) + (I_shipment_qty*I_shipment_retail))/L_new_qty;
      if L_new_retail = 0 then
         L_new_retail := NULL;
      end if;
   end if;

   SQL_LIB.SET_MARK('UPDATE',
                    'TSDETAIL',
                    'Tsf_no: '||to_char(I_tsf_no)||',Item: '||I_item,
                    NULL);
   update tsfdetail
      set finisher_av_retail = L_new_retail,
          finisher_units     = L_new_qty
    where tsf_no = I_tsf_no
      and item   = I_item;

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('ORDER_LOCKED',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END PUT_TSF_AV_RETAIL;
-----------------------------------------------------------------------------------------------
FUNCTION PUT_ILS_AV_RETAIL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_location        IN       ITEM_LOC_SOH.LOC%TYPE,
                           I_loc_type        IN       ITEM_LOC_SOH.LOC_TYPE%TYPE,
                           I_item            IN       TSFDETAIL.ITEM%TYPE,
                           I_shipment        IN       SHIPSKU.SHIPMENT%TYPE,
                           I_tsf_no          IN       SHIPSKU.DISTRO_NO%TYPE,
                           I_tsf_type        IN       TSFHEAD.TSF_TYPE%TYPE,
                           I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE)
   RETURN BOOLEAN is

   L_program                   VARCHAR2(64) := 'BOL_SQL.PUT_ILS_AV_RETAIL';
   L_old_retail                TSFDETAIL.FINISHER_AV_RETAIL%TYPE;
   L_new_retail                TSFDETAIL.FINISHER_AV_RETAIL%TYPE;
   L_old_qty                   TSFDETAIL.FINISHER_UNITS%TYPE;
   L_new_qty                   TSFDETAIL.FINISHER_UNITS%TYPE;
   L_qty_rcv                   SHIPSKU.QTY_EXPECTED%TYPE;
   L_qty_snd                   SHIPSKU.QTY_EXPECTED%TYPE;
   L_shipment_qty              TSFDETAIL.FINISHER_UNITS%TYPE := 0;
   L_shipment_retail           SHIPSKU.UNIT_RETAIL%TYPE := 0;
   L_ship_unit_retail          SHIPSKU.UNIT_RETAIL%TYPE := 0;
   L_pack_unit_retail          SHIPSKU.UNIT_RETAIL%TYPE := 0;
   L_temp_unit_retail          SHIPSKU.UNIT_RETAIL%TYPE := 0;
   L_ship_qty_received         SHIPSKU.QTY_RECEIVED%TYPE := 0;
   L_ship_qty_expected         SHIPSKU.QTY_EXPECTED%TYPE := 0;
   L_finisher_loc              ITEM_LOC_SOH.LOC%TYPE;
   L_finisher_loc_type         ITEM_LOC_SOH.LOC_TYPE%TYPE;
   L_finisher_entity           WH.TSF_ENTITY_ID%TYPE;
   L_finisher                  VARCHAR2(1)  :=  NULL;
   L_first_leg_ind             VARCHAR2(1)  :=  'N';
   L_tsf_mkdn_code             SYSTEM_OPTIONS.TSF_MD_STORE_TO_STORE_SND_RCV%TYPE;
   L_md_store_to_store         SYSTEM_OPTIONS.TSF_MD_STORE_TO_STORE_SND_RCV%TYPE;
   L_md_store_to_wh            SYSTEM_OPTIONS.TSF_MD_STORE_TO_WH_SND_RCV%TYPE;
   L_md_wh_to_store            SYSTEM_OPTIONS.TSF_MD_WH_TO_STORE_SND_RCV%TYPE;
   L_md_wh_to_wh               SYSTEM_OPTIONS.TSF_MD_WH_TO_WH_SND_RCV%TYPE;
   L_from_loc_type             TSFHEAD.FROM_LOC_TYPE%TYPE;
   L_final_loc_type            TSFHEAD.TO_LOC_TYPE%TYPE;
   L_xform_ind                 VARCHAR2(1)  :=  'N';
   L_item                      ITEM_MASTER.ITEM%TYPE  := I_item;
   L_item_qty                  PACKITEM.PACK_QTY%TYPE;
   L_xform_item                ITEM_MASTER.ITEM%TYPE;
   L_tsf_no                    TSFHEAD.TSF_NO%TYPE    := I_tsf_no;
   L_pack_ind                  VARCHAR2(1)  := 'N';
   L_item_ship_ind             VARCHAR2(1)  := 'N';
   L_ship_status               SHIPMENT.STATUS_CODE%TYPE;
   L_pack_comp_count           NUMBER(12)   := 1;
   L_pack_item                 ITEM_MASTER.ITEM%TYPE;
   L_tsf_item                  ITEM_MASTER.ITEM%TYPE;
   L_snd_loc                   ITEM_LOC.LOC%TYPE;
   L_snd_loc_type              ITEM_LOC.LOC_TYPE%TYPE;
   L_rcv_loc                   ITEM_LOC.LOC%TYPE;
   L_rcv_loc_type              ITEM_LOC.LOC_TYPE%TYPE;
   L_first_pack_comp           ITEM_MASTER.ITEM%TYPE;
   L_sum_shipped_tsf           SHIPSKU.QTY_EXPECTED%TYPE := 0;
   L_sum_received_tsf          SHIPSKU.QTY_RECEIVED%TYPE := 0;
   L_tsf_units                 TSFDETAIL.FINISHER_UNITS%TYPE := 0;
   L_itemloc                   ITEM_LOC%ROWTYPE;
   L_comp_bulk_ind             VARCHAR2(1) := 'N';
   L_bulk_qty_received         SHIPSKU.QTY_RECEIVED%TYPE := 0;
   L_bulk_qty_expected         SHIPSKU.QTY_EXPECTED%TYPE := 0;
   L_comp_qty_received         SHIPSKU.QTY_RECEIVED%TYPE := 0;
   L_comp_qty_expected         SHIPSKU.QTY_EXPECTED%TYPE := 0;
   L_bulk_unit_retail          SHIPSKU.UNIT_RETAIL%TYPE := 0;
   L_comp_unit_retail          SHIPSKU.UNIT_RETAIL%TYPE := 0;
   L_pack_tsf_units            TSFDETAIL.FINISHER_UNITS%TYPE := 0;
   L_bulk_tsf_units            TSFDETAIL.FINISHER_UNITS%TYPE := 0;
   L_pack_sum_shipped_tsf      SHIPSKU.QTY_EXPECTED%TYPE := 0;
   L_pack_sum_received_tsf     SHIPSKU.QTY_RECEIVED%TYPE := 0;
   L_pack_shipment_retail      SHIPSKU.UNIT_RETAIL%TYPE := 0;
   L_pack_shipment_qty         SHIPSKU.QTY_RECEIVED%TYPE := 0;
   L_bulk_shipment_retail      SHIPSKU.UNIT_RETAIL%TYPE := 0;
   L_bulk_shipment_qty         SHIPSKU.QTY_RECEIVED%TYPE := 0;
   L_av_cost                   ITEM_LOC_SOH.AV_COST%TYPE := 0;
   L_unit_cost                 ITEM_LOC_SOH.UNIT_COST%TYPE := 0;
   L_selling_unit_retail       ITEM_LOC.SELLING_UNIT_RETAIL%TYPE := 0;
   L_selling_uom               ITEM_LOC.SELLING_UOM%TYPE := 0;
   RECORD_LOCKED               EXCEPTION;
   PRAGMA                      EXCEPTION_INIT(RECORD_LOCKED, -54);
   L_base_unit_retail          ITEM_LOC.UNIT_RETAIL%TYPE;
   L_zone_group_id             ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE;
   L_zone_id                   ITEM_ZONE_PRICE.ZONE_ID%TYPE;
   L_standard_uom_zon          ITEM_MASTER.STANDARD_UOM%TYPE;
   L_selling_unit_retail_zon   ITEM_LOC.SELLING_UNIT_RETAIL%TYPE;
   L_selling_uom_zon           ITEM_LOC.SELLING_UOM%TYPE;
   L_multi_units_zon           ITEM_ZONE_PRICE.MULTI_UNITS%TYPE;
   L_multi_unit_retail_zon     ITEM_ZONE_PRICE.MULTI_UNIT_RETAIL%TYPE;
   L_multi_selling_uom_zon     ITEM_ZONE_PRICE.MULTI_SELLING_UOM%TYPE;
   L_tsf_shipment_ind          VARCHAR2(1) := 'Y';
   L_tsf_unit_retail           TSFDETAIL.FINISHER_AV_RETAIL%TYPE := 0;
   L_comp_item                 ITEM_MASTER.ITEM%TYPE;
   L_sum_pack_comp             NUMBER(12) := 0;
   L_tsf_qty                   TSFDETAIL.TSF_QTY%TYPE := 0;

   cursor C_GET_TSF_MKDN_CODE is
      select tsf_md_store_to_store_snd_rcv,
             tsf_md_store_to_wh_snd_rcv,
             tsf_md_wh_to_store_snd_rcv,
             tsf_md_wh_to_wh_snd_rcv
        from system_options;

   cursor C_GET_FROM_LOC_TYPE is
     select from_loc_type
       from tsfhead
      where tsf_parent_no is NULL
        and tsf_no = L_tsf_no;

   cursor C_GET_FINAL_LOC_TYPE is
      select to_loc_type
        from tsfhead
       where tsf_parent_no = L_tsf_no;

   cursor C_CHECK_SHIP_STATUS is
      select status_code
        from shipment
       where shipment = I_shipment;

   cursor C_CHECK_PACK_IND is
      select pack_ind
        from item_master
       where item = I_item;

   cursor C_COUNT_COMP is
      select count(*)
        from packitem
       where pack_no = I_item;

   cursor C_CHECK_ITEM_SHIP is
      select 'Y'
        from shipsku
       where item = I_item
         and shipment = I_shipment;

   cursor C_GET_PACK_ITEM is
      select p.pack_no ,
             p.pack_qty
        from packitem p,
             shipsku sh
       where p.item = I_item
         and p.pack_no = sh.item
         and sh.shipment = I_shipment;

   cursor C_GET_COMP_ITEMS is
      select item,
             pack_qty
        from packitem
       where pack_no = I_item;

   cursor C_FINISHER_ENTITY is
      select temp.tsf_entity_id
        from (select to_number(partner_id) loc, partner_type loc_type, tsf_entity_id
                from partner
               where partner_type = 'E'
               union all
              select wh loc, 'W' loc_type, tsf_entity_id
                from wh
               union all
              select store loc, 'S' loc_type, tsf_entity_id
                from store) temp,
                tsfhead t
             where t.tsf_no = I_tsf_no
               and t.from_loc_type = temp.loc_type
               and t.from_loc = temp.loc
       minus
      select temp.tsf_entity_id
        from (select to_number(partner_id) loc, partner_type loc_type, tsf_entity_id
                from partner
               where partner_type = 'E'
               union all
              select wh loc, 'W' loc_type, tsf_entity_id
                from wh
               union all
              select store loc, 'S' loc_type, tsf_entity_id
                from store) temp,
             tsfhead t
       where t.tsf_no = I_tsf_no
         and t.to_loc_type = temp.loc_type
         and t.to_loc = temp.loc;

   cursor C_CHECK_XFORM is
      select 'Y'
        from tsf_xform tx,
             tsf_xform_detail txd
       where tx.tsf_no = L_tsf_no
         and tx.tsf_xform_id = txd.tsf_xform_id
         and (txd.from_item = I_item or
              txd.to_item   = I_item)
         and rownum = 1;

   cursor C_GET_LOCS is
      select tsf.from_loc,
             tsf.from_loc_type,
             tsf1.to_loc,
             tsf1.to_loc_type
        from tsfhead tsf,
             tsfhead tsf1
       where tsf.tsf_parent_no is NULL
         and tsf.tsf_no = tsf1.tsf_parent_no
         and (tsf.tsf_no = I_tsf_no or
              tsf1.tsf_no = I_tsf_no);

   cursor C_GET_RETAIL_QTY_SHIP is
      select ss.unit_retail,
             nvl(ss.qty_expected,0),
             nvl(ss.qty_received,0)
        from shipsku ss
       where ss.shipment = I_shipment
         and ss.item     = I_item;

   cursor C_GET_RETAIL_QTY_SHIP_PACK_SND is
      select il.unit_retail,
             nvl(ss.qty_expected,0)*p.pack_qty,
             nvl(ss.qty_received,0)*p.pack_qty,
             ss.unit_retail
        from shipsku ss,
             packitem p,
             item_loc il
       where ss.shipment = I_shipment
         and ss.item    = p.pack_no
         and (p.pack_no  = I_item or
              (L_pack_item is NOT NULL and
               p.pack_no = L_pack_item))
         and p.item  = L_item
         and il.item = p.item
         and il.loc  = L_snd_loc
         and il.loc_type = L_snd_loc_type;

   cursor C_GET_RETAIL_QTY_SHIP_PACK_RCV is
      select il.unit_retail,
             nvl(ss.qty_expected,0)*p.pack_qty,
             nvl(ss.qty_received,0)*p.pack_qty,
             ss.unit_retail
        from shipsku ss,
             packitem p,
             item_loc il
       where ss.shipment = I_shipment
         and ss.item    = p.pack_no
         and (p.pack_no  = I_item or
              (L_pack_item is NOT NULL and
               p.pack_no = L_pack_item))
         and p.item  = L_item
         and il.item = p.item
         and il.loc  = L_rcv_loc
         and il.loc_type = L_rcv_loc_type;

   cursor C_GET_OLD_TSF_AVE_RETAIL is
      select nvl(finisher_av_retail, 0)
        from tsfdetail
       where tsf_no = L_tsf_no
         and item   = I_item;

   cursor C_GET_OLD_TSF_AVE_RETAIL_PACK is
      select nvl(il.unit_retail,0),
             nvl(tsf.finisher_av_retail, 0)
        from item_loc il,
             tsfdetail tsf
       where il.item = L_item
         and il.loc  = L_snd_loc
         and il.loc_type = L_snd_loc_type
         and tsf.tsf_no = L_tsf_no
         and tsf.item = L_pack_item;

   cursor C_GET_RETAIL_QTY_XFORM is
      select ss.unit_retail,
             txd.from_qty
        from shipsku ss,
             tsf_xform_detail txd,
             tsf_xform tx
       where ss.shipment       = I_shipment
         and ss.item           = I_item
         and ss.distro_type     = tx.tsf_no
         and tx.tsf_xform_id   = txd.tsf_xform_id
         and txd.from_item = ss.item;

   cursor C_GET_RETAIL_QTY_SEND is
      select il.unit_retail,
             nvl(ss.qty_expected,0),
             nvl(ss.qty_received,0)
        from item_loc il,
             shipsku ss
       where il.item = I_item
         and ss.item = il.item
         and ss.shipment = I_shipment
         and il.loc       = L_snd_loc
         and il.loc_type  = L_snd_loc_type;

   cursor C_GET_RETAIL_QTY_SEND_PACK is
      select il.unit_retail,
             nvl(ss.qty_expected,0)*p.pack_qty,
             nvl(ss.qty_received,0)*p.pack_qty
        from packitem p,
             item_loc il,
             shipsku ss
       where (p.pack_no = I_item or
              (L_pack_item is NOT NULL and
               p.pack_no = L_pack_item))
         and il.item      = p.item
         and p.item       = L_item
         and ss.item      = p.pack_no
         and ss.shipment  = I_shipment
         and il.loc       = L_snd_loc
         and il.loc_type  = L_snd_loc_type;

   cursor C_GET_RETAIL_QTY_RCV is
      select il.unit_retail,
             nvl(ss.qty_expected,0),
             nvl(ss.qty_received,0)
        from item_loc il,
             shipsku ss
       where il.item =I_item
         and il.item = ss.item
         and ss.shipment  = I_shipment
         and il.loc       = L_rcv_loc
         and il.loc_type  = L_rcv_loc_type;

   cursor C_GET_RETAIL_QTY_RCV_PACK is
      select il.unit_retail,
             nvl(ss.qty_expected,0)*p.pack_qty,
             nvl(ss.qty_received,0)*p.pack_qty
        from packitem p,
             item_loc il,
             shipsku ss
       where (p.pack_no = I_item or
              (L_pack_item is NOT NULL and
               p.pack_no = L_pack_item))
         and il.item      = p.item
         and p.item       = L_item
         and ss.item      = p.pack_no
         and ss.shipment  = I_shipment
         and il.loc       = L_rcv_loc
         and il.loc_type  = L_rcv_loc_type;

   cursor C_GET_XFORM_ITEM is
      select txd.from_item
        from tsf_xform_detail txd,
             tsf_xform tx
       where txd.tsf_xform_id = tx.tsf_xform_id
         and tx.tsf_no        = L_tsf_no
         and txd.to_item      = I_item;

   cursor C_GET_QTY_XFORM is
      select nvl(ss.qty_expected,0),
             nvl(ss.qty_received,0)
        from shipsku ss
       where ss.shipment = I_shipment
         and ss.item = I_item
         and ss.distro_type = 'T'
         and ss.distro_no = I_tsf_no;

   cursor C_OLD_RETAIL is
      select nvl(finisher_av_retail,0),
             nvl(finisher_units,0)
        from item_loc_soh
       where item     = L_item
         and loc      = L_finisher_loc
         and loc_type = L_finisher_loc_type
         for update nowait;

   cursor C_GET_FIRST_LEG_IND is
      select 'Y'
        from tsfhead
       where tsf_no = I_tsf_no
         and tsf_parent_no is NULL;

   cursor C_GET_FINISHER is
      select loc, loc_type
        from (select to_number(partner_id) loc, partner_type loc_type
                from partner
               where partner_type = 'E'
               union all
              select wh loc, 'W' loc_type
                from wh
               where finisher_ind = 'Y') temp,
             tsfhead t
       where t.tsf_no = I_tsf_no
         and t.from_loc_type = temp.loc_type
         and t.from_loc = temp.loc
       union all
      select loc, loc_type
        from (select to_number(partner_id) loc, partner_type loc_type
                from partner
               where partner_type = 'E'
               union all
              select wh loc, 'W' loc_type
                from wh
               where finisher_ind = 'Y') temp,
             tsfhead t
       where t.tsf_no = I_tsf_no
         and t.to_loc_type = temp.loc_type
         and t.to_loc = temp.loc;

   cursor C_GET_FIRST_LEG_TSF is
      select tsf_parent_no
        from tsfhead
       where tsf_no = I_tsf_no;

   cursor C_GET_TSF_RETAIL_PACK is
      select nvl(finisher_av_retail,0)
        from tsfdetail
       where tsf_no = L_tsf_no
         and item   = L_pack_item;

   cursor C_GET_FIRST_COMP_PACK is
      select item
        from packitem
       where pack_no = L_pack_item
         and rownum = 1
       order by item desc;

   cursor C_GET_SUM_SHIPPED_TSF is
      select nvl(sum(nvl(sk.qty_expected,0)),0)
        from shipsku sk,
             shipment sh
       where sk.item = L_item
         and sk.distro_no = I_tsf_no
         and sh.shipment = sk.shipment
         and sh.status_code != 'R'
         and sh.shipment != I_shipment;

   cursor C_GET_SUM_SHIPPED_TSF_PACK is
      select nvl(sum(nvl(sk.qty_expected,0)),0)
        from shipsku sk,
             shipment sh
       where sk.item = L_pack_item
         and sk.distro_no = I_tsf_no
         and sh.shipment = sk.shipment
         and sh.status_code != 'R'
         and sh.shipment != I_shipment;

   cursor C_GET_SUM_RECEIVED_TSF is
      select nvl(sum(nvl(sk.qty_received,0)),0)
        from shipsku sk,
             shipment sh
       where sk.item = L_item
         and sk.distro_no = I_tsf_no
         and sh.shipment = sk.shipment
         and sh.status_code = 'R'
         and sh.shipment != I_shipment;

   cursor C_GET_SUM_RECEIVED_TSF_PACK is
      select nvl(sum(nvl(sk.qty_received,0)),0)
        from shipsku sk,
             shipment sh
       where sk.item = L_pack_item
         and sk.distro_no = I_tsf_no
         and sh.shipment = sk.shipment
         and sh.status_code = 'R'
         and sh.shipment != I_shipment;

   cursor C_GET_TSF_FINISHER_UNITS is
      select nvl(finisher_units,0)
        from tsfdetail
       where tsf_no = L_tsf_no
         and item   = L_item;

   cursor C_GET_TSF_FINISHER_UNITS_PACK is
      select nvl(finisher_units,0)
        from tsfdetail
       where tsf_no = L_tsf_no
         and item = L_pack_item;

   cursor C_OLD_TSF_RETAIL is
      select nvl(finisher_av_retail,0)
        from tsfdetail
       where tsf_no = L_tsf_no
         and item   = L_item;

   cursor C_CHECK_COMP_IN_BULK is
      select p.pack_no,
             p.pack_qty
        from shipsku sk,
             packitem p
       where sk.shipment = I_shipment
         and sk.item = p.pack_no
         and p.item = I_item
         and exists (select 'x'
                       from shipsku sk1
                      where sk1.shipment = sk.shipment
                        and sk1.item     = p.item
                        and rownum = 1);

   cursor C_GET_SUM_PACK_COMP is
      select sum(pack_qty)
        from packitem
       where pack_no = L_pack_item;

   cursor C_GET_TSF_QTY is
      select tsf_qty
        from tsfdetail
       where tsf_no = I_tsf_no
         and item = I_item;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQ_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQ_INPUT_IS_NULL',
                                            'I_location',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQ_INPUT_IS_NULL',
                                            'I_loc_type',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_tsf_no is NOT NULL then
      if I_shipment is NOT NULL then
         --check status of shipment
         SQL_LIB.SET_MARK('OPEN',
                          'C_CHECK_SHIP_STATUS',
                          'SHIPMENT',
                          'Shipment: '||I_shipment);
         open C_CHECK_SHIP_STATUS;

         SQL_LIB.SET_MARK('FETCH',
                          'C_CHECK_SHIP_STATUS',
                          'SHIPMENT',
                          'Shipment: '||I_shipment);
         fetch C_CHECK_SHIP_STATUS into L_ship_status;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_SHIP_STATUS',
                          'SHIPMENT',
                          'Shipment: '||I_shipment);
         close C_CHECK_SHIP_STATUS;
      else
         L_tsf_shipment_ind := 'N';
      end if;
      --This section is needed to handle pack items
      --In shipment, the pack item will be passed to this function but in receiving the component items
      -- of the pack will be used.
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_PACK_IND',
                       'ITEMMASTER',
                       'Item: '||I_item);
      open C_CHECK_PACK_IND;

      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_PACK_IND',
                       'ITEMMASTER',
                       'Item: '||I_item);
      fetch C_CHECK_PACK_IND into L_pack_ind;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_PACK_IND',
                       'ITEMMASTER',
                       'Item: '||I_item);
      close C_CHECK_PACK_IND;

      --get sending and receiving locations
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_LOCS',
                       'TSFHEAD',
                       'Tsf_no: '||to_char(I_tsf_no));
      open C_GET_LOCS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_LOCS',
                       'TSFHEAD',
                       'Tsf_no: '||to_char(I_tsf_no));
      fetch C_GET_LOCS into L_snd_loc,
                            L_snd_loc_type,
                            L_rcv_loc,
                            L_rcv_loc_type;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_LOCS',
                       'TSFHEAD',
                       'Tsf_no: '||to_char(I_tsf_no));
      close C_GET_LOCS;

      --get leg indicator
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_FIRST_LEG_IND',
                       'TSFHEAD',
                       'Tsf_no: '||to_char(I_tsf_no));
      open C_GET_FIRST_LEG_IND;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_FIRST_LEG_IND',
                       'TSFHEAD',
                       'Tsf_no: '||to_char(I_tsf_no));
      fetch C_GET_FIRST_LEG_IND into L_first_leg_ind;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_FIRST_LEG_IND',
                       'TSFHEAD',
                       'Tsf_no: '||to_char(I_tsf_no));
      close C_GET_FIRST_LEG_IND;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_FINISHER',
                       'TSFHEAD',
                       'Tsf_no: '||to_char(I_tsf_no)||', Item: '||I_item);
      open C_GET_FINISHER;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_FINISHER',
                       'TSFHEAD',
                       'Tsf_no: '||to_char(I_tsf_no)||', Item: '||I_item);
      fetch C_GET_FINISHER into L_finisher_loc,
                                L_finisher_loc_type;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_FINISHER',
                       'TSFHEAD',
                       'Tsf_no: '||to_char(I_tsf_no)||', Item: '||I_item);
      close C_GET_FINISHER;

      if L_first_leg_ind = 'N' then

         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_FIRST_LEG_TSF',
                          'TSFHEAD',
                          'Tsf_no: '||to_char(I_tsf_no));
         open C_GET_FIRST_LEG_TSF;

         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_FIRST_LEG_TSF',
                          'TSFHEAD',
                          'Tsf_no: '||to_char(I_tsf_no));
         fetch C_GET_FIRST_LEG_TSF into L_tsf_no;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_FIRST_LEG_TSF',
                          'TSFHEAD',
                          'Tsf_no: '||to_char(I_tsf_no));
         close C_GET_FIRST_LEG_TSF;

         SQL_LIB.SET_MARK('OPEN',
                          'C_CHECK_XFORM',
                          'TSF_XFORM, TSF_XFORM_DETAIL',
                          'Tsf_no: '||to_char(L_tsf_no)||', Item: '||I_item);
         open C_CHECK_XFORM;

         SQL_LIB.SET_MARK('FETCH',
                          'C_CHECK_XFORM',
                          'TSF_XFORM, TSF_XFORM_DETAIL',
                          'Tsf_no: '||to_char(L_tsf_no)||', Item: '||I_item);
         fetch C_CHECK_XFORM into L_xform_ind;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_XFORM',
                          'TSF_XFORM, TSF_XFORM_DETAIL',
                          'Tsf_no: '||to_char(L_tsf_no)||', Item: '||I_item);
         close C_CHECK_XFORM;

         if L_xform_ind = 'Y' then
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_XFORM_ITEM',
                             'TSF_XFORM, TSF_XFORM_DETAIL',
                             'Tsf_no: '||to_char(L_tsf_no)||', Item: '||I_item);
            open C_GET_XFORM_ITEM;

            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_XFORM_ITEM',
                             'TSF_XFORM, TSF_XFORM_DETAIL',
                             'Tsf_no: '||to_char(L_tsf_no)||', Item: '||I_item);
            fetch C_GET_XFORM_ITEM into L_xform_item;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_XFORM_ITEM',
                             'TSF_XFORM, TSF_XFORM_DETAIL',
                             'Tsf_no: '||to_char(L_tsf_no)||', Item: '||I_item);
            close C_GET_XFORM_ITEM;

            L_item := L_xform_item;
         end if;
      end if;

      if L_tsf_shipment_ind = 'Y' then
         if L_pack_ind = 'Y' then
            L_pack_item := I_item;
            --get the number of component items of the pack item.
            SQL_LIB.SET_MARK('OPEN',
                             'C_COUNT_COMP',
                             'PACKITEM',
                             'Item: '||I_item);
            open C_COUNT_COMP;

            SQL_LIB.SET_MARK('FETCH',
                             'C_COUNT_COMP',
                             'PACKITEM',
                             'Item: '||I_item);
            fetch C_COUNT_COMP into L_pack_comp_count;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_COUNT_COMP',
                             'PACKITEM',
                             'Item: '||I_item);
            close C_COUNT_COMP;

            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_COMP_ITEMS',
                             'PACKITEM',
                             'Pack_no: '||I_item);
            open C_GET_COMP_ITEMS;

         else
            SQL_LIB.SET_MARK('OPEN',
                             'C_CHECK_ITEM_SHIP',
                             'SHIPSKU',
                             'Shipment: '|| to_char(I_shipment) || ', Item: '||I_item);
            open C_CHECK_ITEM_SHIP;

            SQL_LIB.SET_MARK('FETCH',
                             'C_CHECK_ITEM_SHIP',
                             'SHIPSKU',
                             'Shipment: '|| to_char(I_shipment) || ', Item: '||I_item);
            fetch C_CHECK_ITEM_SHIP into L_item_ship_ind;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_CHECK_ITEM_SHIP',
                             'SHIPSKU',
                             'Shipment: '|| to_char(I_shipment) || ', Item: '||I_item);
            close C_CHECK_ITEM_SHIP;

            if L_item_ship_ind = 'N' then --item is a component item
               --get pack item
               SQL_LIB.SET_MARK('OPEN',
                                'C_GET_PACK_ITEM',
                                'SHIPSKU, PACKITEM',
                                'Shipment: '|| to_char(I_shipment) || ', Item: '||I_item);
               open C_GET_PACK_ITEM;

               SQL_LIB.SET_MARK('FETCH',
                                'C_GET_PACK_ITEM',
                                'SHIPSKU, PACKITEM',
                                'Shipment: '|| to_char(I_shipment) || ', Item: '||I_item);
               fetch C_GET_PACK_ITEM into L_pack_item,
                                          L_item_qty;

               SQL_LIB.SET_MARK('CLOSE',
                                'C_GET_PACK_ITEM',
                                'SHIPSKU, PACKITEM',
                                'Shipment: '|| to_char(I_shipment) || ', Item: '||I_item);
               close C_GET_PACK_ITEM;
            elsif L_ship_status = 'R' then -- check if the item is a component and a bulk sku for receiving only
               SQL_LIB.SET_MARK('OPEN',
                                'C_CHECK_COMP_IN_BULK',
                                'SHIPSKU, PACKITEM',
                                'Shipment: '|| to_char(I_shipment) || ', Item: '||I_item);
               open C_CHECK_COMP_IN_BULK;

               SQL_LIB.SET_MARK('FETCH',
                                'C_CHECK_COMP_IN_BULK',
                                'SHIPSKU, PACKITEM',
                                'Shipment: '|| to_char(I_shipment) || ', Item: '||I_item);
               fetch C_CHECK_COMP_IN_BULK into L_pack_item,
                                               L_item_qty;

               SQL_LIB.SET_MARK('CLOSE',
                                'C_CHECK_COMP_IN_BULK',
                                'SHIPSKU, PACKITEM',
                                'Shipment: '|| to_char(I_shipment) || ', Item: '||I_item);
               close C_CHECK_COMP_IN_BULK;

               if L_pack_item is NOT NULL then
                  L_comp_bulk_ind := 'Y';
               else
                  L_comp_bulk_ind := 'N';
               end if;
            end if;
         end if;

         --get the sum of all the components of pack to be able to get the ratio
         --of each component for the computation of the unit retail
         if L_pack_ind = 'Y' or
            L_item_ship_ind = 'N' or
            L_comp_bulk_ind = 'Y' then

            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_SUM_PACK_COMP',
                             'PACKITEM',
                             'Pack_no: '||L_pack_item);
            open C_GET_SUM_PACK_COMP;

            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_SUM_PACK_COMP',
                             'PACKITEM',
                             'Pack_no: '||L_pack_item);
            fetch C_GET_SUM_PACK_COMP into L_sum_pack_comp;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_SUM_PACK_COMP',
                             'PACKITEM',
                             'Pack_no: '||L_pack_item);
            close C_GET_SUM_PACK_COMP;
         end if;
      end if;

      if I_tsf_type = 'IC' then  --intercompany transfer
         SQL_LIB.SET_MARK('OPEN',
                          'C_FINISHER_ENTITY',
                          'TSFHEAD',
                          'Tsf_no: '||to_char(I_tsf_no));
         open C_FINISHER_ENTITY;

         SQL_LIB.SET_MARK('FETCH',
                          'C_FINISHER_ENTITY',
                          'TSFHEAD',
                          'Tsf_no: '||to_char(I_tsf_no));
         fetch C_FINISHER_ENTITY into L_finisher_entity;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_FINISHER_ENTITY',
                          'TSFHEAD',
                          'Tsf_no: '||to_char(I_tsf_no));
         close C_FINISHER_ENTITY;

         if L_finisher_entity is NULL then
            if L_first_leg_ind = 'Y' then
               L_finisher := 'S';
            else
               L_finisher := 'R';
            end if;
         else
            if L_first_leg_ind = 'Y' then
               L_finisher := 'R';
            else
               L_finisher := 'S';
            end if;
         end if;
      else --intracompany transfer
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_TSF_MKDN_CODE',
                             'SYSTEM_OPTIONS',
                             NULL);
            open C_GET_TSF_MKDN_CODE;

            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_TSF_MKDN_CODE',
                             'SYSTEM_OPTIONS',
                             NULL);
            fetch C_GET_TSF_MKDN_CODE into L_md_store_to_store,
                                           L_md_store_to_wh,
                                           L_md_wh_to_store,
                                           L_md_wh_to_wh;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_TSF_MKDN_CODE',
                             'SYSTEM_OPTIONS',
                             NULL);
            close C_GET_TSF_MKDN_CODE;
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_FROM_LOC_TYPE',
                             'TSFHEAD',
                             'Tsf no: '||to_char(L_tsf_no));
            open C_GET_FROM_LOC_TYPE;

            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_FROM_LOC_TYPE',
                             'TSFHEAD',
                             'Tsf no: '||to_char(L_tsf_no));
            fetch C_GET_FROM_LOC_TYPE into L_from_loc_type;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_FROM_LOC_TYPE',
                             'TSFHEAD',
                             'Tsf no: '||to_char(L_tsf_no));
            close C_GET_FROM_LOC_TYPE;
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_FINAL_LOC_TYPE',
                             'TSFHEAD',
                             'Tsf no: '||to_char(L_tsf_no));
            open C_GET_FINAL_LOC_TYPE;

            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_FINAL_LOC_TYPE',
                             'TSFHEAD',
                             'Tsf no: '||to_char(L_tsf_no));
            fetch C_GET_FINAL_LOC_TYPE into L_final_loc_type;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_FINAL_LOC_TYPE',
                             'TSFHEAD',
                             'Tsf no: '||to_char(L_tsf_no));
            close C_GET_FINAL_LOC_TYPE;
            --
            if L_from_loc_type = 'W' then
               if L_final_loc_type = 'W' then
                  L_tsf_mkdn_code := L_md_wh_to_wh;
               else
                  L_tsf_mkdn_code := L_md_wh_to_store;
               end if;
            else
               if L_final_loc_type = 'W' then
                  L_tsf_mkdn_code := L_md_store_to_wh;
               else
                  L_tsf_mkdn_code := L_md_store_to_store;
               end if;
            end if;
      end if;
   end if;

   if L_tsf_shipment_ind = 'Y' then -- both transfers with shipment and invetory adjustment will be processed
      FOR i in 1..L_pack_comp_count LOOP
         if I_tsf_no is NOT NULL then
            if L_pack_ind = 'Y' then
               SQL_LIB.SET_MARK('FETCH',
                                'C_GET_COMP_ITEMS',
                                'PACKITEM',
                                'Pack_no: '||I_item);
               fetch C_GET_COMP_ITEMS into L_item,
                                           L_item_qty;
            end if;

            if I_tsf_type = 'IC' then
               if L_pack_ind = 'Y' or L_item_ship_ind = 'N' or L_comp_bulk_ind = 'Y' then
                  if L_finisher = 'R' then
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_RETAIL_QTY_SHIP_PACK_RCV',
                                      'PACKITEM, SHIPSKU, ITEM_LOC',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     open C_GET_RETAIL_QTY_SHIP_PACK_RCV;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_RETAIL_QTY_SHIP_PACK_RCV',
                                      'PACKITEM, SHIPSKU, ITEM_LOC',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     fetch C_GET_RETAIL_QTY_SHIP_PACK_RCV into L_ship_unit_retail,
                                                               L_ship_qty_expected,
                                                               L_ship_qty_received,
                                                               L_pack_unit_retail;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_RETAIL_QTY_SHIP_PACK_RCV',
                                      'PACKITEM, SHIPSKU, ITEM_LOC',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     close C_GET_RETAIL_QTY_SHIP_PACK_RCV;
                  else
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_RETAIL_QTY_SHIP_PACK_SND',
                                      'PACKITEM, SHIPSKU, ITEM_LOC',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     open C_GET_RETAIL_QTY_SHIP_PACK_SND;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_RETAIL_QTY_SHIP_PACK_SND',
                                      'PACKITEM, SHIPSKU, ITEM_LOC',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     fetch C_GET_RETAIL_QTY_SHIP_PACK_SND into L_ship_unit_retail,
                                                               L_ship_qty_expected,
                                                               L_ship_qty_received,
                                                               L_pack_unit_retail;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_RETAIL_QTY_SHIP_PACK_SND',
                                      'PACKITEM, SHIPSKU, ITEM_LOC',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     close C_GET_RETAIL_QTY_SHIP_PACK_SND;
                  end if;

                  if L_comp_bulk_ind = 'Y' then
                     L_comp_qty_received := L_ship_qty_received;
                     L_comp_qty_expected := L_ship_qty_expected;
                     L_comp_unit_retail  := L_ship_unit_retail;

                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_RETAIL_QTY_SHIP',
                                      'SHIPSKU',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     open C_GET_RETAIL_QTY_SHIP;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_RETAIL_QTY_SHIP',
                                      'SHIPSKU',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     fetch C_GET_RETAIL_QTY_SHIP into L_ship_unit_retail,
                                                      L_ship_qty_expected,
                                                      L_ship_qty_received;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_RETAIL_QTY_SHIP',
                                      'SHIPSKU',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     close C_GET_RETAIL_QTY_SHIP;

                     L_bulk_qty_received := L_ship_qty_received;
                     L_bulk_qty_expected := L_ship_qty_expected;
                     L_bulk_unit_retail  := L_ship_unit_retail;
                  end if;
               else
                  SQL_LIB.SET_MARK('OPEN',
                                   'C_GET_RETAIL_QTY_SHIP',
                                   'SHIPSKU',
                                   'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                  open C_GET_RETAIL_QTY_SHIP;

                  SQL_LIB.SET_MARK('FETCH',
                                   'C_GET_RETAIL_QTY_SHIP',
                                   'SHIPSKU',
                                   'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                  fetch C_GET_RETAIL_QTY_SHIP into L_ship_unit_retail,
                                                   L_ship_qty_expected,
                                                   L_ship_qty_received;

                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_GET_RETAIL_QTY_SHIP',
                                   'SHIPSKU',
                                   'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                  close C_GET_RETAIL_QTY_SHIP;
               end if;

               if L_first_leg_ind = 'Y' then
                  if L_finisher = 'R' then
                     --retrieve the retail at the receiving location and transfer quantity
                     if L_pack_ind = 'Y' or L_item_ship_ind = 'N' or L_comp_bulk_ind = 'Y' then
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_RCV_PACK',
                                         'PACKITEM, ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        open C_GET_RETAIL_QTY_RCV_PACK;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_RCV_PACK',
                                         'PACKITEM, ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        fetch C_GET_RETAIL_QTY_RCV_PACK into L_ship_unit_retail,
                                                             L_ship_qty_expected,
                                                             L_ship_qty_received;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_RCV_PACK',
                                         'PACKITEM, ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        close C_GET_RETAIL_QTY_RCV_PACK;

                        if L_comp_bulk_ind = 'Y' then
                           L_comp_qty_received := L_ship_qty_received;
                           L_comp_qty_expected := L_ship_qty_expected;
                           L_comp_unit_retail  := L_ship_unit_retail;

                           SQL_LIB.SET_MARK('OPEN',
                                            'C_GET_RETAIL_QTY_RCV',
                                            'ITEM_LOC, SHIPSKU, SHIPMENT',
                                            'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                           open C_GET_RETAIL_QTY_RCV;

                           SQL_LIB.SET_MARK('FETCH',
                                            'C_GET_RETAIL_QTY_RCV',
                                            'ITEM_LOC, SHIPSKU, SHIPMENT',
                                            'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                           fetch C_GET_RETAIL_QTY_RCV into L_ship_unit_retail,
                                                           L_ship_qty_expected,
                                                           L_ship_qty_received;

                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_GET_RETAIL_QTY_RCV',
                                            'ITEM_LOC, SHIPSKU, SHIPMENT',
                                            'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                           close C_GET_RETAIL_QTY_RCV;

                           L_bulk_qty_received := L_ship_qty_received;
                           L_bulk_qty_expected := L_ship_qty_expected;
                           L_bulk_unit_retail  := L_ship_unit_retail;
                        end if;
                     else
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_RCV',
                                         'ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        open C_GET_RETAIL_QTY_RCV;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_RCV',
                                         'ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        fetch C_GET_RETAIL_QTY_RCV into L_ship_unit_retail,
                                                        L_ship_qty_expected,
                                                        L_ship_qty_received;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_RCV',
                                         'ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        close C_GET_RETAIL_QTY_RCV;
                     end if;
                  else -- L_finisher = 'S'
                     --retrieve the retail at the sending location and the transfer quantity
                     if L_pack_ind = 'Y' or L_item_ship_ind = 'N' or L_comp_bulk_ind = 'Y' then
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_SEND_PACK',
                                         'PACKITEM, ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        open C_GET_RETAIL_QTY_SEND_PACK;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_SEND_PACK',
                                         'PACKITEM, ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        fetch C_GET_RETAIL_QTY_SEND_PACK into L_ship_unit_retail,
                                                              L_ship_qty_expected,
                                                              L_ship_qty_received;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_SEND_PACK',
                                         'PACKITEM, ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        close C_GET_RETAIL_QTY_SEND_PACK;

                        if L_comp_bulk_ind = 'Y' then
                           L_comp_qty_received := L_ship_qty_received;
                           L_comp_qty_expected := L_ship_qty_expected;
                           L_comp_unit_retail := L_ship_unit_retail;

                           SQL_LIB.SET_MARK('OPEN',
                                            'C_GET_RETAIL_QTY_SEND',
                                            'ITEM_LOC, SHIPSKU, SHIPMENT',
                                            'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                           open C_GET_RETAIL_QTY_SEND;

                           SQL_LIB.SET_MARK('FETCH',
                                            'C_GET_RETAIL_QTY_SEND',
                                            'ITEM_LOC, SHIPSKU, SHIPMENT',
                                            'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                           fetch C_GET_RETAIL_QTY_SEND into L_ship_unit_retail,
                                                            L_ship_qty_expected,
                                                            L_ship_qty_received;

                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_GET_RETAIL_QTY_SEND',
                                            'ITEM_LOC, SHIPSKU, SHIPMENT',
                                            'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                           close C_GET_RETAIL_QTY_SEND;

                           L_bulk_qty_received := L_ship_qty_received;
                           L_bulk_qty_expected := L_ship_qty_expected;
                           L_bulk_unit_retail  := L_ship_unit_retail;
                        end if;
                     else
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_SEND',
                                         'ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        open C_GET_RETAIL_QTY_SEND;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_SEND',
                                         'ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        fetch C_GET_RETAIL_QTY_SEND into L_ship_unit_retail,
                                                         L_ship_qty_expected,
                                                         L_ship_qty_received;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_SEND',
                                         'ITEM_LOC, SHIPSKU, SHIPMENT',
                                         'Shipment: '||to_char(I_shipment)||', Item: '||I_item);
                        close C_GET_RETAIL_QTY_SEND;
                     end if;
                  end if;
               else  --second leg of the transfer
                  --retrieve
                  if L_pack_ind = 'Y' or L_item_ship_ind = 'N' or L_comp_bulk_ind = 'Y' then
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_RETAIL_QTY_RCV_PACK',
                                      'PACKITEM, ITEM_LOC, SHIPSKU, SHIPMENT',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                     open C_GET_RETAIL_QTY_RCV_PACK;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_RETAIL_QTY_RCV_PACK',
                                      'PACKITEM, ITEM_LOC, SHIPSKU, SHIPMENT',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                     fetch C_GET_RETAIL_QTY_RCV_PACK into L_ship_unit_retail,
                                                          L_ship_qty_expected,
                                                          L_ship_qty_received;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_RETAIL_QTY_RCV_PACK',
                                      'PACKITEM, ITEM_LOC, SHIPSKU, SHIPMENT',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                     close C_GET_RETAIL_QTY_RCV_PACK;

                     if L_comp_bulk_ind = 'Y' then
                        L_comp_qty_received := L_ship_qty_received;
                        L_comp_qty_expected := L_ship_qty_expected;
                        L_comp_unit_retail  := L_ship_unit_retail;

                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_RCV',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                        open C_GET_RETAIL_QTY_RCV;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_RCV',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                        fetch C_GET_RETAIL_QTY_RCV into L_ship_unit_retail,
                                                        L_ship_qty_expected,
                                                        L_ship_qty_received;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_RCV',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                        close C_GET_RETAIL_QTY_RCV;

                        L_bulk_qty_received := L_ship_qty_received;
                        L_bulk_qty_expected := L_ship_qty_expected;
                        L_bulk_unit_retail  := L_ship_unit_retail;
                     end if;
                  else
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_RETAIL_QTY_RCV',
                                      'SHIPSKU',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                     open C_GET_RETAIL_QTY_RCV;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_RETAIL_QTY_RCV',
                                      'SHIPSKU',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                     fetch C_GET_RETAIL_QTY_RCV into L_ship_unit_retail,
                                                     L_ship_qty_expected,
                                                     L_ship_qty_received;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_RETAIL_QTY_RCV',
                                      'SHIPSKU',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                     close C_GET_RETAIL_QTY_RCV;
                  end if;
                  if L_finisher = 'S' then
                     -- retrieve the old transfer retail;
                     if L_pack_ind = 'Y' or L_item_ship_ind = 'N' or L_comp_bulk_ind = 'Y' then
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_OLD_TSF_AVE_RETAIL_PACK',
                                         'ITEM_LOC',
                                         'Item: '||L_item ||', Location: '||L_snd_loc);
                        open C_GET_OLD_TSF_AVE_RETAIL_PACK;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_OLD_TSF_AVE_RETAIL_PACK',
                                         'ITEM_LOC',
                                         'Item: '||L_item ||', Location: '||L_snd_loc);
                        fetch C_GET_OLD_TSF_AVE_RETAIL_PACK into L_ship_unit_retail,
                                                                 L_pack_unit_retail;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_OLD_TSF_AVE_RETAIL_PACK',
                                         'ITEM_LOC',
                                         'Item: '||L_item ||', Location: '||L_snd_loc);
                        close C_GET_OLD_TSF_AVE_RETAIL_PACK;

                        if L_ship_unit_retail = 0 then
                           if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                  L_itemloc,
                                                                  I_item,
                                                                  L_snd_loc) = FALSE then
                              return FALSE;
                           end if;
                           L_ship_unit_retail := L_itemloc.unit_retail;
                        end if;

                        if L_pack_unit_retail = 0 then
                           if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message ,
                                                                       L_pack_item,
                                                                       L_snd_loc,
                                                                       L_snd_loc_type,
                                                                       L_av_cost,
                                                                       L_unit_cost,
                                                                       L_pack_unit_retail,
                                                                       L_selling_unit_retail,
                                                                       L_selling_uom) = FALSE then
                              return FALSE;
                           end if;
                        end if;

                        if L_comp_bulk_ind = 'Y' then
                           L_comp_unit_retail := L_ship_unit_retail;

                           SQL_LIB.SET_MARK('OPEN',
                                            'C_GET_OLD_TSF_AVE_RETAIL',
                                            'SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                           open C_GET_OLD_TSF_AVE_RETAIL;

                           SQL_LIB.SET_MARK('FETCH',
                                            'C_GET_OLD_TSF_AVE_RETAIL',
                                            'SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                           fetch C_GET_OLD_TSF_AVE_RETAIL into L_ship_unit_retail;

                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_GET_OLD_TSF_AVE_RETAIL',
                                            'SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                           close C_GET_OLD_TSF_AVE_RETAIL;

                           if L_ship_unit_retail = 0 then
                              if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                     L_itemloc,
                                                                     I_item,
                                                                     L_snd_loc) = FALSE then
                                 return FALSE;
                              end if;
                              L_ship_unit_retail := L_itemloc.unit_retail;
                           end if;

                           L_bulk_unit_retail := L_ship_unit_retail;
                        end if;
                     else
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_OLD_TSF_AVE_RETAIL',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                        open C_GET_OLD_TSF_AVE_RETAIL;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_OLD_TSF_AVE_RETAIL',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                        fetch C_GET_OLD_TSF_AVE_RETAIL into L_ship_unit_retail;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_OLD_TSF_AVE_RETAIL',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
                        close C_GET_OLD_TSF_AVE_RETAIL;

                        if L_ship_unit_retail = 0 then
                           if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                  L_itemloc,
                                                                  I_item,
                                                                  L_snd_loc) = FALSE then
                              return FALSE;
                           end if;
                           L_ship_unit_retail := L_itemloc.unit_retail;
                        end if;
                     end if;
                  end if;
               end if;
            else --intracompany transfer
               if L_first_leg_ind = 'Y' then
                  if L_tsf_mkdn_code = 'R' then

                     --C_GET_RETAIL_QTY_SEND that will retrieve the retail at the
                     --sending location and the transfer quantity.
                     if L_pack_ind = 'Y' or L_item_ship_ind = 'N' or L_comp_bulk_ind = 'Y' then
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_SEND_PACK',
                                         'PACKITEM, ITEM_LOC, SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        open C_GET_RETAIL_QTY_SEND_PACK;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_SEND_PACK',
                                         'PACKITEM, ITEM_LOC, SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        fetch C_GET_RETAIL_QTY_SEND_PACK into L_ship_unit_retail,
                                                              L_ship_qty_expected,
                                                              L_ship_qty_received;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_SEND_PACK',
                                         'PACKITEM, ITEM_LOC, SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        close C_GET_RETAIL_QTY_SEND_PACK;

                        if L_comp_bulk_ind = 'Y' then
                           L_comp_qty_received := L_ship_qty_received;
                           L_comp_qty_expected := L_ship_qty_expected;
                           L_comp_unit_retail  := L_ship_unit_retail;

                           SQL_LIB.SET_MARK('OPEN',
                                            'C_GET_RETAIL_QTY_SEND',
                                            'ITEM_LOC, SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           open C_GET_RETAIL_QTY_SEND;

                           SQL_LIB.SET_MARK('FETCH',
                                            'C_GET_RETAIL_QTY_SEND',
                                            'ITEM_LOC,SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           fetch C_GET_RETAIL_QTY_SEND into L_ship_unit_retail,
                                                            L_ship_qty_expected,
                                                            L_ship_qty_received;

                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_GET_RETAIL_QTY_SEND',
                                            'ITEM_LOC, SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           close C_GET_RETAIL_QTY_SEND;

                           L_bulk_qty_received := L_ship_qty_received;
                           L_bulk_qty_expected := L_ship_qty_expected;
                           L_bulk_unit_retail  := L_ship_unit_retail;
                        end if;
                     else
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_SEND',
                                         'ITEM_LOC, SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        open C_GET_RETAIL_QTY_SEND;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_SEND',
                                         'ITEM_LOC,SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        fetch C_GET_RETAIL_QTY_SEND into L_ship_unit_retail,
                                                         L_ship_qty_expected,
                                                         L_ship_qty_received;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_SEND',
                                         'ITEM_LOC, SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        close C_GET_RETAIL_QTY_SEND;
                     end if;
                  else --markdown at sending location
                     if L_pack_ind = 'Y' or L_item_ship_ind = 'N' or L_comp_bulk_ind = 'Y' then
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_SHIP_PACK_RCV',
                                         'PACKITEM, SHIPSKU, ITEM_LOC',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        open C_GET_RETAIL_QTY_SHIP_PACK_RCV;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_SHIP_PACK_RCV',
                                         'PACKITEM, SHIPSKU, ITEM_LOC',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        fetch C_GET_RETAIL_QTY_SHIP_PACK_RCV into L_ship_unit_retail,
                                                                  L_ship_qty_expected,
                                                                  L_ship_qty_received,
                                                                  L_pack_unit_retail;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_SHIP_PACK_RCV',
                                         'PACKITEM, SHIPSKU, ITEM_LOC',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        close C_GET_RETAIL_QTY_SHIP_PACK_RCV;

                        if L_comp_bulk_ind = 'Y' then
                           L_comp_qty_received := L_ship_qty_received;
                           L_comp_qty_expected := L_ship_qty_expected;
                           L_comp_unit_retail  := L_ship_unit_retail;

                           SQL_LIB.SET_MARK('OPEN',
                                            'C_GET_RETAIL_QTY_SHIP',
                                            'SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           open C_GET_RETAIL_QTY_SHIP;

                           SQL_LIB.SET_MARK('FETCH',
                                            'C_GET_RETAIL_QTY_SHIP',
                                            'SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           fetch C_GET_RETAIL_QTY_SHIP into L_ship_unit_retail,
                                                            L_ship_qty_expected,
                                                            L_ship_qty_received;

                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_GET_RETAIL_QTY_SHIP',
                                            'SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           close C_GET_RETAIL_QTY_SHIP;

                           if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                  L_itemloc,
                                                                  I_item,
                                                                  L_rcv_loc) = FALSE then
                              return FALSE;
                           end if;

                           L_bulk_qty_received := L_ship_qty_received;
                           L_bulk_qty_expected := L_ship_qty_expected;
                           L_bulk_unit_retail  := L_itemloc.unit_retail;
                        end if;
                     else
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_SHIP',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        open C_GET_RETAIL_QTY_SHIP;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_SHIP',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        fetch C_GET_RETAIL_QTY_SHIP into L_ship_unit_retail,
                                                         L_ship_qty_expected,
                                                         L_ship_qty_received;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_SHIP',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        close C_GET_RETAIL_QTY_SHIP;

                        if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                               L_itemloc,
                                                               I_item,
                                                               L_rcv_loc) = FALSE then
                           return FALSE;
                        end if;

                        L_ship_unit_retail := L_itemloc.unit_retail;
                     end if;
                  end if;
               else --second leg of the transfer
                  if L_xform_ind = 'Y' then
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_QTY_XFORM',
                                      'SHIPSKU',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     open C_GET_QTY_XFORM;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_QTY_XFORM',
                                      'SHIPSKU',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     fetch C_GET_QTY_XFORM into L_ship_qty_expected,
                                                L_ship_qty_received;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_QTY_XFORM',
                                      'SHIPSKU',
                                      'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                     close C_GET_QTY_XFORM;

                      --get the unit retail of the parent transfer
                      SQL_LIB.SET_MARK('OPEN',
                                       'C_OLD_TSF_RETAIL',
                                       'TSFDETAIL',
                                       'Tsf no: '||to_char(L_tsf_no) ||', Item: '||L_item);
                      open C_OLD_TSF_RETAIL;

                      SQL_LIB.SET_MARK('FETCH',
                                       'C_OLD_TSF_RETAIL',
                                       'TSFDETAIL',
                                       'Tsf no: '||to_char(L_tsf_no) ||', Item: '||L_item);
                      fetch C_OLD_TSF_RETAIL into L_ship_unit_retail;

                      SQL_LIB.SET_MARK('CLOSE',
                                       'C_OLD_TSF_RETAIL',
                                       'TSFDETAIL',
                                       'Tsf no: '||to_char(L_tsf_no) ||', Item: '||L_item);
                      close C_OLD_TSF_RETAIL;

                      if L_ship_unit_retail = 0 then
                         if L_tsf_mkdn_code = 'R' then
                            if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                   L_itemloc,
                                                                   L_item,
                                                                   L_snd_loc) = FALSE then
                               return FALSE;
                            end if;
                         else
                            if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                   L_itemloc,
                                                                   L_item,
                                                                   L_rcv_loc) = FALSE then
                               return FALSE;
                            end if;
                         end if;
                         L_ship_unit_retail := L_itemloc.unit_retail;
                      end if;
                  else
                     if L_pack_ind = 'Y' or L_item_ship_ind = 'N' or L_comp_bulk_ind = 'Y' then
                        if L_tsf_mkdn_code = 'R' then
                           SQL_LIB.SET_MARK('OPEN',
                                            'C_GET_RETAIL_QTY_SHIP_PACK_SND',
                                            'PACKITEM, SHIPSKU, ITEM_LOC',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           open C_GET_RETAIL_QTY_SHIP_PACK_SND;

                           SQL_LIB.SET_MARK('FETCH',
                                            'C_GET_RETAIL_QTY_SHIP_PACK_SND',
                                            'PACKITEM, SHIPSKU, ITEM_LOC',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           fetch C_GET_RETAIL_QTY_SHIP_PACK_SND into L_ship_unit_retail,
                                                                     L_ship_qty_expected,
                                                                     L_ship_qty_received,
                                                                     L_pack_unit_retail;

                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_GET_RETAIL_QTY_SHIP_PACK_SND',
                                            'PACKITEM, SHIPSKU, ITEM_LOC',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           close C_GET_RETAIL_QTY_SHIP_PACK_SND;
                        else
                           SQL_LIB.SET_MARK('OPEN',
                                            'C_GET_RETAIL_QTY_SHIP_PACK_RCV',
                                            'PACKITEM, SHIPSKU, ITEM_LOC',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           open C_GET_RETAIL_QTY_SHIP_PACK_RCV;

                           SQL_LIB.SET_MARK('FETCH',
                                            'C_GET_RETAIL_QTY_SHIP_PACK_RCV',
                                            'PACKITEM, SHIPSKU, ITEM_LOC',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           fetch C_GET_RETAIL_QTY_SHIP_PACK_RCV into L_ship_unit_retail,
                                                                     L_ship_qty_expected,
                                                                     L_ship_qty_received,
                                                                     L_pack_unit_retail;

                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_GET_RETAIL_QTY_SHIP_PACK_RCV',
                                            'PACKITEM, SHIPSKU, ITEM_LOC',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           close C_GET_RETAIL_QTY_SHIP_PACK_RCV;
                        end if;

                        if L_comp_bulk_ind = 'Y' then
                           L_comp_qty_received := L_ship_qty_received;
                           L_comp_qty_expected := L_ship_qty_expected;
                           L_comp_unit_retail  := L_ship_unit_retail;

                           SQL_LIB.SET_MARK('OPEN',
                                            'C_GET_RETAIL_QTY_SHIP',
                                            'SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           open C_GET_RETAIL_QTY_SHIP;

                           SQL_LIB.SET_MARK('FETCH',
                                            'C_GET_RETAIL_QTY_SHIP',
                                            'SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           fetch C_GET_RETAIL_QTY_SHIP into L_ship_unit_retail,
                                                            L_ship_qty_expected,
                                                            L_ship_qty_received;

                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_GET_RETAIL_QTY_SHIP',
                                            'SHIPSKU',
                                            'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                           close C_GET_RETAIL_QTY_SHIP;

                           --get the unit retail of the parent transfer
                           SQL_LIB.SET_MARK('OPEN',
                                            'C_OLD_TSF_RETAIL',
                                            'TSFDETAIL',
                                            'Tsf no: '||to_char(L_tsf_no) ||', Item: '||L_item);
                           open C_OLD_TSF_RETAIL;

                           SQL_LIB.SET_MARK('FETCH',
                                            'C_OLD_TSF_RETAIL',
                                            'TSFDETAIL',
                                            'Tsf no: '||to_char(L_tsf_no) ||', Item: '||L_item);
                           fetch C_OLD_TSF_RETAIL into L_ship_unit_retail;

                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_OLD_TSF_RETAIL',
                                            'TSFDETAIL',
                                            'Tsf no: '||to_char(L_tsf_no) ||', Item: '||L_item);
                           close C_OLD_TSF_RETAIL;

                           if L_ship_unit_retail = 0 then
                              if L_tsf_mkdn_code = 'R' then
                                 if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                        L_itemloc,
                                                                        I_item,
                                                                        L_snd_loc) = FALSE then
                                    return FALSE;
                                 end if;
                              else
                                 if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                        L_itemloc,
                                                                        I_item,
                                                                        L_rcv_loc) = FALSE then
                                    return FALSE;
                                 end if;
                              end if;
                              L_ship_unit_retail := L_itemloc.unit_retail;
                           end if;

                           L_bulk_qty_received := L_ship_qty_received;
                           L_bulk_qty_expected := L_ship_qty_expected;
                           L_bulk_unit_retail  := L_ship_unit_retail;
                        end if;
                     else
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_RETAIL_QTY_SHIP',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        open C_GET_RETAIL_QTY_SHIP;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_RETAIL_QTY_SHIP',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        fetch C_GET_RETAIL_QTY_SHIP into L_ship_unit_retail,
                                                         L_ship_qty_expected,
                                                         L_ship_qty_received;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_RETAIL_QTY_SHIP',
                                         'SHIPSKU',
                                         'Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        close C_GET_RETAIL_QTY_SHIP;

                        --get the unit retail of the parent transfer
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_OLD_TSF_RETAIL',
                                         'TSFDETAIL',
                                         'Tsf no: '||to_char(L_tsf_no) ||', Item: '||L_item);
                        open C_OLD_TSF_RETAIL;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_OLD_TSF_RETAIL',
                                         'TSFDETAIL',
                                         'Tsf no: '||to_char(L_tsf_no) ||', Item: '||L_item);
                        fetch C_OLD_TSF_RETAIL into L_ship_unit_retail;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_OLD_TSF_RETAIL',
                                         'TSFDETAIL',
                                         'Tsf no: '||to_char(L_tsf_no) ||', Item: '||L_item);
                        close C_OLD_TSF_RETAIL;

                        if L_ship_unit_retail = 0 then
                           if L_tsf_mkdn_code = 'R' then
                              if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                     L_itemloc,
                                                                     I_item,
                                                                     L_snd_loc) = FALSE then
                                 return FALSE;
                              end if;
                           else
                              if ITEMLOC_ATTRIB_SQL.GET_ITEMLOC_INFO(O_error_message,
                                                                     L_itemloc,
                                                                     I_item,
                                                                     L_rcv_loc) = FALSE then
                                 return FALSE;
                              end if;
                           end if;
                           L_ship_unit_retail := L_itemloc.unit_retail;
                        end if;
                     end if;
                  end if;
               end if;
            end if;
            if L_ship_status = 'R' then
               if L_comp_bulk_ind = 'Y' then
                  L_ship_qty_expected := L_bulk_qty_expected + L_comp_qty_expected;
                  L_ship_qty_received := L_bulk_qty_received + L_comp_qty_received;
                  if L_ship_qty_received != 0 then
                     L_ship_unit_retail  := ((L_bulk_unit_retail*L_bulk_qty_received) +(L_comp_unit_retail*L_comp_qty_received))/L_ship_qty_received;
                  else
                     L_ship_unit_retail := 0;
                  end if;
               end if;

               if L_item_ship_ind = 'N' or L_comp_bulk_ind = 'Y' then
                  if L_first_leg_ind = 'Y' then
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_SUM_SHIPPED_TSF_PACK',
                                      'SHIPSKU, SHIPMENT',
                                      'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||L_pack_item);
                     open C_GET_SUM_SHIPPED_TSF_PACK;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_SUM_SHIPPED_TSF_PACK',
                                      'SHIPSKU, SHIPMENT',
                                      'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||L_pack_item);
                     fetch C_GET_SUM_SHIPPED_TSF_PACK into L_pack_sum_shipped_tsf;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_SUM_SHIPPED_TSF_PACK',
                                      'SHIPSKU, SHIPMENT',
                                      'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||L_pack_item);
                     close C_GET_SUM_SHIPPED_TSF_PACK;

                     if L_pack_sum_shipped_tsf is NULL then
                        L_pack_sum_shipped_tsf := 0;
                     end if;
                     ---
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_SUM_RECEIVED_TSF_PACK',
                                      'SHIPSKU, SHIPMENT',
                                      'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||L_pack_item);
                     open C_GET_SUM_RECEIVED_TSF_PACK;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_SUM_RECEIVED_TSF_PACK',
                                      'SHIPSKU, SHIPMENT',
                                      'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||L_pack_item);
                     fetch C_GET_SUM_RECEIVED_TSF_PACK into L_pack_sum_received_tsf;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_SUM_RECEIVED_TSF_PACK',
                                      'SHIPSKU, SHIPMENT',
                                      'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||L_pack_item);
                     close C_GET_SUM_RECEIVED_TSF_PACK;

                     if L_pack_sum_received_tsf is NULL then
                        L_pack_sum_received_tsf := 0;
                     end if;
                  end if;

                  SQL_LIB.SET_MARK('OPEN',
                                   'C_GET_TSF_FINISHER_UNITS_PACK',
                                   'TSFDETAIL',
                                   'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_pack_item);
                  open C_GET_TSF_FINISHER_UNITS_PACK;

                  SQL_LIB.SET_MARK('FETCH',
                                   'C_GET_TSF_FINISHER_UNITS_PACK',
                                   'TSFDETAIL',
                                   'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_pack_item);
                  fetch C_GET_TSF_FINISHER_UNITS_PACK into L_pack_tsf_units;

                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_GET_TSF_FINISHER_UNITS_PACK',
                                   'TSFDETAIL',
                                   'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_pack_item);
                  close C_GET_TSF_FINISHER_UNITS_PACK;

                  L_pack_tsf_units := (L_pack_tsf_units - (L_pack_sum_shipped_tsf + L_pack_sum_received_tsf))*L_item_qty;
                  L_tsf_units      := L_pack_tsf_units;
                  if L_comp_bulk_ind = 'Y' then
                     if L_first_leg_ind = 'Y' then
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_SUM_SHIPPED_TSF',
                                         'SHIPSKU, SHIPMENT',
                                         'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        open C_GET_SUM_SHIPPED_TSF;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_SUM_SHIPPED_TSF',
                                         'SHIPSKU, SHIPMENT',
                                         'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        fetch C_GET_SUM_SHIPPED_TSF into L_sum_shipped_tsf;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_SUM_SHIPPED_TSF',
                                         'SHIPSKU, SHIPMENT',
                                         'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        close C_GET_SUM_SHIPPED_TSF;

                        SQL_LIB.SET_MARK('OPEN',
                                         'C_GET_SUM_RECEIVED_TSF',
                                         'SHIPSKU, SHIPMENT',
                                         'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        open C_GET_SUM_RECEIVED_TSF;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_GET_SUM_RECEIVED_TSF',
                                         'SHIPSKU, SHIPMENT',
                                         'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        fetch C_GET_SUM_RECEIVED_TSF into L_sum_received_tsf;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_GET_SUM_RECEIVED_TSF',
                                         'SHIPSKU, SHIPMENT',
                                         'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                        close C_GET_SUM_RECEIVED_TSF;
                     end if;
                     ---
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_TSF_FINISHER_UNITS',
                                      'TSFDETAIL',
                                      'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_item);
                     open C_GET_TSF_FINISHER_UNITS;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_TSF_FINISHER_UNITS',
                                      'TSFDETAIL',
                                      'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_item);
                     fetch C_GET_TSF_FINISHER_UNITS into L_bulk_tsf_units;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_TSF_FINISHER_UNITS',
                                      'TSFDETAIL',
                                      'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_item);
                     close C_GET_TSF_FINISHER_UNITS;

                     L_bulk_tsf_units := L_bulk_tsf_units - (L_sum_shipped_tsf + L_sum_received_tsf);
                     L_tsf_units      := L_pack_tsf_units + L_bulk_tsf_units;
                  end if;
               elsif L_first_leg_ind = 'Y' then
                  SQL_LIB.SET_MARK('OPEN',
                                   'C_GET_SUM_SHIPPED_TSF',
                                   'SHIPSKU, SHIPMENT',
                                   'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                  open C_GET_SUM_SHIPPED_TSF;

                  SQL_LIB.SET_MARK('FETCH',
                                   'C_GET_SUM_SHIPPED_TSF',
                                   'SHIPSKU, SHIPMENT',
                                   'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                  fetch C_GET_SUM_SHIPPED_TSF into L_sum_shipped_tsf;

                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_GET_SUM_SHIPPED_TSF',
                                   'SHIPSKU, SHIPMENT',
                                   'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                  close C_GET_SUM_SHIPPED_TSF;

                  SQL_LIB.SET_MARK('OPEN',
                                   'C_GET_SUM_RECEIVED_TSF',
                                   'SHIPSKU, SHIPMENT',
                                   'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                  open C_GET_SUM_RECEIVED_TSF;

                  SQL_LIB.SET_MARK('FETCH',
                                   'C_GET_SUM_RECEIVED_TSF',
                                   'SHIPSKU, SHIPMENT',
                                   'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                  fetch C_GET_SUM_RECEIVED_TSF into L_sum_received_tsf;

                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_GET_SUM_RECEIVED_TSF',
                                   'SHIPSKU, SHIPMENT',
                                   'Tsf no: '||to_char(I_tsf_no)||', Shipment: '||to_char(I_shipment) ||', Item: '||I_item);
                  close C_GET_SUM_RECEIVED_TSF;

                  SQL_LIB.SET_MARK('OPEN',
                                   'C_GET_TSF_FINISHER_UNITS',
                                   'TSFDETAIL',
                                   'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_item);
                  open C_GET_TSF_FINISHER_UNITS;

                  SQL_LIB.SET_MARK('FETCH',
                                   'C_GET_TSF_FINISHER_UNITS',
                                   'TSFDETAIL',
                                   'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_item);
                  fetch C_GET_TSF_FINISHER_UNITS into L_tsf_units;

                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_GET_TSF_FINISHER_UNITS',
                                   'TSFDETAIL',
                                   'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_item);
                  close C_GET_TSF_FINISHER_UNITS;

                  L_tsf_units := L_tsf_units - (L_sum_shipped_tsf + L_sum_received_tsf);
               else
                  SQL_LIB.SET_MARK('OPEN',
                                   'C_GET_TSF_FINISHER_UNITS',
                                   'TSFDETAIL',
                                   'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_item);
                  open C_GET_TSF_FINISHER_UNITS;

                  SQL_LIB.SET_MARK('FETCH',
                                   'C_GET_TSF_FINISHER_UNITS',
                                   'TSFDETAIL',
                                   'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_item);
                  fetch C_GET_TSF_FINISHER_UNITS into L_tsf_units;

                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_GET_TSF_FINISHER_UNITS',
                                   'TSFDETAIL',
                                   'Tsf no: '||to_char(I_tsf_no)||', Item: '||L_item);
                  close C_GET_TSF_FINISHER_UNITS;
               end if;

               if L_tsf_units is NULL then
                  L_tsf_units := 0;
               end if;
               ---
               if (L_tsf_units = L_ship_qty_expected) or (L_tsf_units = 0 and L_first_leg_ind = 'N') then
                  L_shipment_qty := L_ship_qty_received - L_ship_qty_expected;
               elsif L_tsf_units != 0 and L_first_leg_ind = 'N' then
                  L_shipment_qty := L_ship_qty_received - (L_ship_qty_expected - L_tsf_units);
               else
                  L_shipment_qty := L_ship_qty_received - L_tsf_units;
               end if;

               if L_comp_bulk_ind = 'Y' then
                  if (L_bulk_tsf_units = L_bulk_qty_expected) or
                     (L_bulk_tsf_units = 0 and L_first_leg_ind = 'N') then
                     if L_bulk_qty_received != 0 then
                        L_bulk_shipment_qty := L_bulk_qty_received - L_bulk_qty_expected;
                     end if;
                  elsif L_bulk_tsf_units != 0 and L_first_leg_ind = 'N' then
                     if L_bulk_qty_received != 0 then
                        L_bulk_shipment_qty := L_bulk_qty_received - (L_bulk_qty_expected - L_bulk_tsf_units);
                     end if;
                  else
                     if L_bulk_qty_received != 0 then
                        L_bulk_shipment_qty := L_bulk_qty_received - L_bulk_tsf_units;
                     end if;
                  end if;
                  ---
                  if (L_pack_tsf_units = L_comp_qty_expected) or
                     (L_pack_tsf_units = 0 and L_first_leg_ind = 'N') then
                     if L_comp_qty_received != 0 then
                        L_pack_shipment_qty := L_comp_qty_received - L_comp_qty_expected;
                     end if;
                  elsif L_pack_tsf_units != 0 and L_first_leg_ind = 'N' then
                     if L_comp_qty_received != 0 then
                        L_pack_shipment_qty := L_comp_qty_received - (L_comp_qty_expected - L_pack_tsf_units);
                     end if;
                  else
                     if L_comp_qty_received != 0 then
                        L_pack_shipment_qty := L_comp_qty_received - L_pack_tsf_units;
                     end if;
                  end if;

                  L_shipment_qty := L_bulk_shipment_qty + L_pack_shipment_qty;
               end if;
            else
               if L_first_leg_ind = 'N' and L_comp_bulk_ind = 'Y' then
                  L_ship_qty_expected := L_bulk_qty_expected + L_comp_qty_expected;
               end if;
               ---
               L_shipment_qty := L_ship_qty_expected;
            end if;

            if L_first_leg_ind != 'Y' then
               L_shipment_qty := (L_shipment_qty)*(-1);
               if L_comp_bulk_ind = 'Y' then
                  L_bulk_shipment_qty := (L_bulk_shipment_qty)*(-1);
                  L_pack_shipment_qty := (L_pack_shipment_qty)*(-1);
               end if;
            end if;
            L_shipment_retail := L_ship_unit_retail;

         else --Inventory adjustment
            L_shipment_qty        := I_adj_qty;
            L_finisher_loc        := I_location;
            L_finisher_loc_type   := I_loc_type;

            -- get unit retail defaults for inventory adjusments if finisher_av_retail will be NULL
            if L_finisher_loc_type = 'E' then
               ---
               if PRICING_ATTRIB_SQL.GET_BASE_ZONE_RETAIL(O_error_message,
                                                          L_zone_group_id,
                                                          L_zone_id,
                                                          L_base_unit_retail,
                                                          L_standard_uom_zon,
                                                          L_selling_unit_retail_zon,
                                                          L_selling_uom_zon,
                                                          L_multi_units_zon,
                                                          L_multi_unit_retail_zon,
                                                          L_multi_selling_uom_zon,
                                                          L_item) = FALSE then
                  return FALSE;
               end if;
               ---

               if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                   L_zone_id,
                                                   'Z',
                                                   L_zone_group_id,
                                                   L_finisher_loc,
                                                   'E',
                                                   NULL,
                                                   L_base_unit_retail,
                                                   L_shipment_retail,
                                                   'R',
                                                   NULL,
                                                   NULL) = FALSE then
                  return FALSE;
               end if;
            else -- internal finisher
               if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message,
                                                           L_item,
                                                           L_finisher_loc,
                                                           L_finisher_loc_type,
                                                           L_av_cost,
                                                           L_unit_cost,
                                                           L_shipment_retail,
                                                           L_selling_unit_retail,
                                                           L_selling_uom) = FALSE then
                  return FALSE;
               end if;
               ---
            end if;

         end if;

         SQL_LIB.SET_MARK('OPEN',
                          'C_OLD_RETAIL',
                          'ITEM_LOC_SOH',
                          'Item: '||I_item);
         open C_OLD_RETAIL;

         SQL_LIB.SET_MARK('FETCH',
                          'C_OLD_RETAIL',
                          'ITEM_LOC_SOH',
                          'Item: '||I_item);
         fetch C_OLD_RETAIL into L_old_retail,
                                 L_old_qty;

         if L_pack_ind = 'Y' or
            L_item_ship_ind = 'N' or
            L_comp_bulk_ind = 'Y' then
            L_shipment_retail := L_pack_unit_retail*(L_item_qty/L_sum_pack_comp);
         end if;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_OLD_RETAIL',
                          'ITEM_LOC_SOH',
                          'Item: '||I_item);
         close C_OLD_RETAIL;

         L_new_qty   := L_old_qty + L_shipment_qty;

         if L_new_qty = 0 then
            L_new_retail := NULL;
            L_new_qty    := NULL;
         else
            L_new_retail := ((L_old_qty*L_old_retail) + (L_shipment_qty*L_shipment_retail))/L_new_qty;
            if L_new_retail = 0 then
               L_new_retail := NULL;
            end if;
         end if;

         SQL_LIB.SET_MARK('UPDATE',
                          'ITEM_LOC_SOH',
                          'Tsf_no: '||to_char(I_tsf_no)||',Item: '||I_item,
                          NULL);
         update item_loc_soh
            set finisher_av_retail = L_new_retail,
                finisher_units  = L_new_qty
          where item     = L_item
            and loc      = L_finisher_loc
            and loc_type = L_finisher_loc_type;

         if I_tsf_no is NOT NULL then
            if L_pack_ind = 'Y' then
               L_temp_unit_retail := L_temp_unit_retail + L_shipment_retail*L_item_qty;
            end if;
            if L_item_ship_ind = 'N' and L_ship_status = 'R' then
            ---C_GET_FIRST_COMP_PACK
               SQL_LIB.SET_MARK('OPEN',
                                'C_GET_FIRST_COMP_PACK',
                                'PACKITEM',
                                'Pack_no: '||L_pack_item);
               open C_GET_FIRST_COMP_PACK;

               SQL_LIB.SET_MARK('FETCH',
                                'C_GET_FIRST_COMP_PACK',
                                'PACKITEM',
                                'Pack_no: '||L_pack_item);
               fetch C_GET_FIRST_COMP_PACK into L_first_pack_comp;

               SQL_LIB.SET_MARK('CLOSE',
                                'C_GET_FIRST_COMP_PACK',
                                'PACKITEM',
                                'Pack_no: '||L_pack_item);
               close C_GET_FIRST_COMP_PACK;
            end if;
            if (L_pack_ind = 'Y' or (L_item_ship_ind = 'N' and L_first_pack_comp = I_item)) and i = L_pack_comp_count  then
               L_tsf_item := L_pack_item;
               ---
               if L_ship_status = 'R' and L_pack_unit_retail is NULL then
               --retrieve current average retail from transfer
                  SQL_LIB.SET_MARK('OPEN',
                                   'C_GET_TSF_RETAIL_PACK',
                                   'TSFDETAIL',
                                   'Tsf_no: '||to_char(I_tsf_no)||', Item: '||L_pack_item);
                  open C_GET_TSF_RETAIL_PACK;

                  SQL_LIB.SET_MARK('FETCH',
                                   'C_GET_TSF_RETAIL_PACK',
                                   'TSFDETAIL',
                                   'Tsf_no: '||to_char(I_tsf_no)||', Item: '||L_pack_item);
                  fetch C_GET_TSF_RETAIL_PACK into L_pack_unit_retail;

                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_GET_TSF_RETAIL_PACK',
                                   'TSFDETAIL',
                                   'Tsf_no: '||to_char(I_tsf_no)||', Item: '||L_pack_item);
                  close C_GET_TSF_RETAIL_PACK;
               elsif L_pack_unit_retail is NULL then
                  L_pack_unit_retail := L_temp_unit_retail;
               end if;
               ---
               if PUT_TSF_AV_RETAIL(O_error_message,
                                    L_pack_unit_retail,
                                    (L_shipment_qty/L_item_qty),
                                    L_tsf_no,
                                    L_tsf_item) = FALSE then
                  return FALSE;
               end if;
            elsif L_comp_bulk_ind = 'Y' and L_ship_status = 'R' then
               if PUT_TSF_AV_RETAIL(O_error_message,
                                    L_pack_unit_retail,
                                    L_pack_shipment_qty/L_item_qty,
                                    L_tsf_no,
                                    L_pack_item) = FALSE then
                  return FALSE;
               end if;

               if PUT_TSF_AV_RETAIL(O_error_message,
                                    L_bulk_unit_retail,
                                    L_bulk_shipment_qty,
                                    L_tsf_no,
                                    L_item) = FALSE then
                  return FALSE;
               end if;

            else
               if PUT_TSF_AV_RETAIL(O_error_message,
                                    L_shipment_retail,
                                    L_shipment_qty,
                                    L_tsf_no,
                                    L_item) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
         end if;
      END LOOP;
      ---
      if L_pack_ind = 'Y' then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_COMP_ITEMS',
                          'PACKITEM',
                          'Pack_no: '||I_item);
         close C_GET_COMP_ITEMS;
      end if;
   else --no shipment
      if L_first_leg_ind = 'Y' then
         if I_tsf_type = 'IC' then --intercompany transfer
            if L_finisher = 'R' then --tsf entity of finisher is the same as receiving location
               if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message ,
                                                           L_item,
                                                           L_rcv_loc,
                                                           L_rcv_loc_type,
                                                           L_av_cost,
                                                           L_unit_cost,
                                                           L_tsf_unit_retail,
                                                           L_selling_unit_retail,
                                                           L_selling_uom) = FALSE then
                  return FALSE;
               end if;
            else  --tsf entity of finisher is the same as sending location
               if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message ,
                                                           L_item,
                                                           L_snd_loc,
                                                           L_snd_loc_type,
                                                           L_av_cost,
                                                           L_unit_cost,
                                                           L_tsf_unit_retail,
                                                           L_selling_unit_retail,
                                                           L_selling_uom) = FALSE then
                  return FALSE;
               end if;
            end if;
         else --intracompany transfer
            if L_tsf_mkdn_code = 'R' then --markdown at receiving location
               if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message ,
                                                           L_item,
                                                           L_snd_loc,
                                                           L_snd_loc_type,
                                                           L_av_cost,
                                                           L_unit_cost,
                                                           L_tsf_unit_retail,
                                                           L_selling_unit_retail,
                                                           L_selling_uom) = FALSE then
                  return FALSE;
               end if;
            else  --markdown at sending location
               if ITEMLOC_ATTRIB_SQL.GET_COSTS_AND_RETAILS(O_error_message ,
                                                           L_item,
                                                           L_rcv_loc,
                                                           L_rcv_loc_type,
                                                           L_av_cost,
                                                           L_unit_cost,
                                                           L_tsf_unit_retail,
                                                           L_selling_unit_retail,
                                                           L_selling_uom) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
      else --2nd leg of transfer
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_OLD_TSF_AVE_RETAIL',
                          'SHIPSKU',
                          'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
         open C_GET_OLD_TSF_AVE_RETAIL;

         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_OLD_TSF_AVE_RETAIL',
                          'SHIPSKU',
                          'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
         fetch C_GET_OLD_TSF_AVE_RETAIL into L_tsf_unit_retail;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_OLD_TSF_AVE_RETAIL',
                          'SHIPSKU',
                          'Shipment: '||to_char(I_shipment) ||', Item: '||L_item);
         close C_GET_OLD_TSF_AVE_RETAIL;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_TSF_QTY',
                       'TSFDETAIL',
                       'Tsf_no: '||I_tsf_no||' ,Item: '||I_item);
      open C_GET_TSF_QTY;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_TSF_QTY',
                       'TSFDETAIL',
                       'Tsf_no: '||I_tsf_no||' ,Item: '||I_item);
      fetch C_GET_TSF_QTY into L_tsf_qty;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_TSF_QTY',
                       'TSFDETAIL',
                       'Tsf_no: '||I_tsf_no||' ,Item: '||I_item);
      close C_GET_TSF_QTY;

      if L_first_leg_ind = 'N' then
         if I_adj_qty is NOT NULL then
            L_tsf_qty := I_adj_qty;
         end if;
         L_tsf_qty := (-1)*L_tsf_qty;
      end if;

      --update item_loc_soh records of the component items
      if L_pack_ind = 'Y' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_COUNT_COMP',
                          'PACKITEM',
                          'Item: '||L_pack_item);
         open C_COUNT_COMP;

         SQL_LIB.SET_MARK('FETCH',
                          'C_COUNT_COMP',
                          'PACKITEM',
                          'Item: '||L_pack_item);
         fetch C_COUNT_COMP into L_pack_comp_count;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_COUNT_COMP',
                          'PACKITEM',
                          'Item: '||L_pack_item);
         close C_COUNT_COMP;

         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_COMP_ITEMS',
                          'PACKITEM',
                          'Item: '||L_pack_item);
         open C_GET_COMP_ITEMS;

         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_SUM_PACK_COMP',
                          'PACKITEM',
                          'Pack_no: '||L_pack_item);
         open C_GET_SUM_PACK_COMP;

         FOR i in 1..L_pack_comp_count LOOP
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_COMP_ITEMS',
                             'PACKITEM',
                             'Item: '||L_pack_item);
            fetch C_GET_COMP_ITEMS into L_comp_item,
                                        L_item_qty;

            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_SUM_PACK_COMP',
                             'PACKITEM',
                             'Pack_no: '||L_pack_item);
            fetch C_GET_SUM_PACK_COMP into L_sum_pack_comp;

            L_pack_unit_retail := L_tsf_unit_retail*(L_item_qty/L_sum_pack_comp);

            --get old item_loc_soh.finisher
            SQL_LIB.SET_MARK('OPEN',
                             'C_OLD_RETAIL',
                             'ITEM_LOC_SOH',
                             'Tsf_no: '||to_char(I_tsf_no)||', Item: '||I_item);
            open C_OLD_RETAIL;

            SQL_LIB.SET_MARK('FETCH',
                             'C_OLD_RETAIL',
                             'ITEM_LOC_SOH',
                             'Item: '||I_item);
            fetch C_OLD_RETAIL into L_old_retail,
                                    L_old_qty;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_OLD_RETAIL',
                             'ITEM_LOC_SOH',
                             'Item: '||I_item);
            close C_OLD_RETAIL;

            L_new_qty   := L_old_qty + L_tsf_qty;

            if L_new_qty = 0 then
               L_new_retail := NULL;
               L_new_qty    := NULL;
            else
               L_new_retail := ((L_old_qty*L_old_retail) + (L_tsf_qty*L_pack_unit_retail))/L_new_qty;
               if L_new_retail = 0 then
                  L_new_retail := NULL;
               end if;
            end if;

            SQL_LIB.SET_MARK('UPDATE',
                             'ITEM_LOC_SOH',
                             'Tsf_no: '||to_char(I_tsf_no)||',Item: '||I_item,
                             NULL);
            update item_loc_soh
               set finisher_av_retail = L_new_retail,
                   finisher_units  = L_new_qty
             where item     = L_item
               and loc      = L_finisher_loc
               and loc_type = L_finisher_loc_type;

         END LOOP;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_COMP_ITEMS',
                          'PACKITEM',
                          'Pack_no: '||I_item);
         close C_GET_COMP_ITEMS;

         SQL_LIB.SET_MARK('CLOSE',
		                  'C_GET_SUM_PACK_COMP',
		                  'PACKITEM',
		                  'Pack_no: '||L_pack_item);
		 close C_GET_SUM_PACK_COMP;
      else
         --get old item_loc_soh.finisher
         SQL_LIB.SET_MARK('OPEN',
                          'C_OLD_RETAIL',
                          'ITEM_LOC_SOH',
                          'Tsf_no: '||to_char(I_tsf_no)||', Item: '||I_item);
         open C_OLD_RETAIL;

         SQL_LIB.SET_MARK('FETCH',
                          'C_OLD_RETAIL',
                          'ITEM_LOC_SOH',
                          'Item: '||I_item);
         fetch C_OLD_RETAIL into L_old_retail,
                                 L_old_qty;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_OLD_RETAIL',
                          'ITEM_LOC_SOH',
                          'Item: '||I_item);
         close C_OLD_RETAIL;

         L_new_qty   := L_old_qty + L_tsf_qty;

         if L_new_qty = 0 then
            L_new_retail := NULL;
            L_new_qty    := NULL;
         else
            L_new_retail := ((L_old_qty*L_old_retail) + (L_tsf_qty*L_tsf_unit_retail))/L_new_qty;
            if L_new_retail = 0 then
               L_new_retail := NULL;
            end if;
         end if;

         SQL_LIB.SET_MARK('UPDATE',
                          'ITEM_LOC_SOH',
                          'Tsf_no: '||to_char(I_tsf_no)||',Item: '||I_item,
                          NULL);
         update item_loc_soh
            set finisher_av_retail = L_new_retail,
                finisher_units  = L_new_qty
          where item     = L_item
            and loc      = L_finisher_loc
            and loc_type = L_finisher_loc_type;
      end if;

      --update tsfdetail.finisher_av_retail and finisher_units
      if PUT_TSF_AV_RETAIL(O_error_message,
                           L_tsf_unit_retail,
                           L_tsf_qty,
                           L_tsf_no,
                           L_item) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('ORDER_LOCKED',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END PUT_ILS_AV_RETAIL;
-----------------------------------------------------------------------------------------------
END; --BOL_SQL
/

