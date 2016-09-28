CREATE OR REPLACE PACKAGE BODY DELETE_ITEM_RECORDS_SQL AS
----------------------------------------------------------------------
-- Mod By        : Satish BN, satish.narasimhaiah@in.tesco.com
-- Mod Date      : 19-Jun-2007
-- Mod Ref       : Mod number. N21
-- Purpose:      : To delete supply chain attribute information
----------------------------------------------------------------------
-- Mod By        : Ramasamy, ramasamy.thirumoorthi@wipro.com
-- Mod Date      : 19-Oct-2007
-- Mod Ref       : Fro CQ 3252
-- Purpose:      : To delete supply chain attribute information
----------------------------------------------------------------------
-- Mod By        : Chandrasekaran N, chandrashekaran.natarajan@in.tesco.com
-- Mod Date      : 15-Oct-2007
-- Mod Ref       : Mod number. N23
-- Purpose:      : A modification is required to delete the records in product
--                 descriptions table with item details
---------------------------------------------------------------------------------------------
-- Mod By       : Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
-- Mod Date     : 22-Nov-2007
-- Mod Ref      : DefNBS00004099
-- Mod Details  : Added a new function TSL_DEL_BARCODE_ATTRIB
---------------------------------------------------------------------------------------------
-- Mod By       : Rachaputi Praveen , praveen.rachaputi@in.tesco.com
-- Mod Date     : 05-Oct-2007
-- Mod Ref      : Mod N105,TESCO HSC
-- Mod Details:   When a item is deleted in ORMS, the TSL_RNA_SQL.RETURN_TO_RNA
--                function must be called to 'release' those numbers so that
--                they may be used again by the business.
---------------------------------------------------------------------------------------------
-- Mod By       : WiproEnabler/Karthik karthik.dhanapal@wipro.com
-- Mod Date     : 16-Apr-2008
-- Mod Ref      : Def NBS00006107
-- Mod Details  : Included the deletion of the Item attributes for the Sub Tran level Items in DEL_ITEM.
---------------------------------------------------------------------------------------------
-- Mod By       : TESCO HSC/Murali, murali.natarajan@in.tesco.com
-- Mod Date     : 23-Apr-2008
-- Mod Details  : Merging of Drop2a ST and IT defects to Drop3.
----------------------------------------------------------------------------------------------------
-- Fix By      : Wipro/Dhuraison Prince                                                           --
-- Fix Date    : 13-Aug-2008                                                                      --
-- Defect ID   : NBS00008124                                                                      --
-- Fix Details : Appended code to delete obsolete items from TSL_FUTURE_COST table when the items --
--               have been deleted from ITEM_MASTER table.                                        --
----------------------------------------------------------------------------------------------------
-- Mod By       : Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date     : 08-May-2008
-- Mod Details  : DEL_ITEM function modified to delete Ranging information.
---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Mod By      : Wipro/Dhuraison Prince                                                           --
-- Mod Date    : 15-May-2008                                                                      --
-- Mod Ref     : BSD_OR_CR135_Daily Purge Fix.doc                                                 --
-- Mod Details : CR135 | Fixing the following defects raised against the ORMS Daily Purge         --
--                       functionality:                                                           --
--                      1. Defect related to the elimination of Item Descriptions, that returns  --
--                          a constraint error message.                                           --
--                       2. Defect related to the Supply Chain Attributes, when trying deleting a --
--                          Simple Pack that was set as the Preferred Pack at a specific point in --
--                          time.                                                                 --
----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Mod By:      Bahubali Dongare Bahubali.Dongare@in.tesco.com
-- Mod Date:    12-May-2008
-- Mod Ref:     ModN111
-- Mod Details: Modified the function DEL_ITEM to delete the item's (And its chlidren's) records
-- from on TSL_COMMON_SUPS_MATRIX table.
---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
-- Mod By     : Murali Krishnan , murali.natarajan@in.tesco.com
-- Mod Date   : 29-Jul-2008
-- Mod Ref    : Defect#:DEFNBS007441,TESCO HSC
-- Mod Details: deleted all supply chain attributes assosciated with a pack
--              before deleting the pack.
-----------------------------------------------------------------------------------------
-- Mod By     : Murali Krishnan , murali.natarajan@in.tesco.com
-- Mod Date   : 04-Aug-2008
-- Mod Ref    : Defect#:DEFNBS006793,TESCO HSC
-- Mod Details: Moved Changes Done for Mod N127 to delete records from tsl_item_range
--              and tsl_prov_range table to before deleting the item from item_master to
--              avoid constraint error.
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa
-- Mod Date   : 23-Jul-2008
-- Mod Ref    : N111A.
-- Mod Details: 1.Modified the function DEL_ITEM to release the RNA once the item is deleted
--               in secondary instance.
--              2.Modified the call to the function  which was added by N111,
--                to delete the TSL_COMMON_SUPS_MATRIX table.
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By     : Satish BN, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 5-Sep-2008
-- Mod Ref    : DefNBS008703
-- Purpose:   : Modified DEL_ITEM, not to release OCC numbers with leading 0(zero)to RNA.
-----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
---Mod By      -- Tarun Kumar Mishra, tarun.mishra@in.tesco.com
---Mod Ref     -- CR162
---Mod Date    -- 14-Oct-2008
---Mod Details -- Added code to delete records from TSL_SCA_WH_ORDER,TSL_SCA_DIRECT_DIST_PACKS
---            -- TSL_SCA_PREF_PACK , TSL_SCA_DIST_GROUP_TRIG.
----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Mod By       : Tarun Kumar Mishra, tarun.mishra@in.tesco.com
-- Mod Date     : 9-Dec-2008
-- Mod Ref      : DefNBS005996
-- Mod Details  : Added code to check condition L_use_rna_ind = 'Y'
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By     : Chandru N chandrashekaran.natarajan@in.tesco.com
-- Mod Date   : 9-Feb-2009
-- Mod Ref    : DefNBS011401
-- Purpose:   : Modified DEL_ITEM to add delete statements for tsl_item_exp_head,
--              tsl_item_exp_detail and tsl_exp_queue tables
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 07-Apr-2009
-- Mod Ref    : CR209
-- Purpose:   : Modified DEL_ITEM to add delete statements for tsl_wawac_queue table.
-----------------------------------------------------------------------------------------
-- Mod By        : Satish BN, satish.narasimhaiah@in.tesco.com
-- Mod Date      : 01-Jul-2009
-- Mod Ref       : DefNBS013670
-- Purpose:      : Added delete from item_mfqueue in DEL_ITEM function
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 15-Jul-2009
-- Mod Ref    : Defect(NBS00013954)
-- Purpose:   : Modified DEL_ITEM to check for simple_pack_ind before calling TSL_CHECK_OCC_MATCH_EAN
--              function as the function should be called only for simple packs.
-----------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
-- Mod By     : Murali Krishnan , murali.natarajan@in.tesco.com
-- Mod Date   : 21-Aug-2009
-- Mod Ref    : Defect#:NBS00014560 ,TESCO HSC
-- Mod Details: Modified daily purge to check if TPNA has any children which are common,
--              if so do not release TPNA to RNA.
-----------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
-- Mod By     : Nikhil Narang , nikhil.narang@in.tesco.com
-- Mod Date   : 08-Dec-2009
-- Mod Ref    : Defect#:NBS00015685 ,TESCO HSC
-- Mod Details: Modified daily purge to delete the records from tsl_sca_mfqueue at item
--              deletion.
-----------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 09-Sep-2009
-- Mod Ref    : Defect(NBS00014580)
-- Purpose:   : Modified DEL_ITEM to delete the item from item_pub_info table once the item
--              is purged from all other tables.
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
--Mod By      : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
--Mod Date    : 06-Nov-2009
--Mod Ref     : CR220
--Mod Details : Modified the function to prevent the release of approved,deactivated
--            : TPN's(TPNA,TPNB,TPNC,TPND)
-----------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 21-Jan-2010
-- Mod Ref    : DefNBS016007
-- Mod Details: Added a new function TSL_BARCODE_COUNT
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By     : Sarayu Gouda, sarayu.gouda@in.tesco.com
-- Mod Date   : 01-Feb-2010
-- Mod Ref    : MrgNBS016138
-- Mod Detail : PrdDi (Production branch) to 3.5b branches
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 09-Feb-2010
-- Mod Ref    : Corrected the fix of 14580
-- Mod Detail : Deleted the item_pub_info table for items which have item_level <= tran_level.
-----------------------------------------------------------------------------------------
-- Mod By     : Srinivasa Janga, Srinivasa.Janga@in.tesco.com
-- Mod Date   : 22-MAR-2010
-- Mod Ref    : Defect#:NBS00016706 ,TESCO HSC
-- Mod Details: Modified daily purge not to delete the records from tsl_sca_mfqueue for approved items
-----------------------------------------------------------------------------------------
-- Mod By     : JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 20-APR-2010
-- Mod Ref    : MrgNBS017125
-- Mod Details: Defect NBS00016706 has been added.
-----------------------------------------------------------------------------------------
-- Mod By       : Reshma Koshy
-- Mod Date     : 11-May-2010
-- Def Ref      : DefNBS017418
-- Def Detail   : 1. Modified to delete item_pub_info in the RMSMFM.GETNXT function and not in DAILY_PURGE package
-------------------------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari,bhragavi.pujari@in.tesco.com
-- Mod Date     : 16-Jul-2010
-- Mod Ref      : NBS00018303
-- Mod Details  : Added a new parameter to DEL_ITEM function to avoid returning items to RNA
--                on barcode move or exchange and defaulting the new parameter to 'N' always
--                so that it can work same way as it's working now.only in barcode move/exchange
--                screen making this parameter as 'Y'(through screen) so that it can skip going
--                to RETURN_TO_RNA function.
---------------------------------------------------------------------------------------------
-- Mod By       : V Manikandan
-- Mod Date     : 16-Jul-2010
-- Def Ref      : DefNBS018335
-- Def Detail   : Modified DEL_ITEM function to handle the OCC for delete.
-------------------------------------------------------------------------------------------------
-- Mod By     : JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 28-Jul-2010
-- Mod Ref    : MrgNBS018480
-- Mod Details: Defect DefNBS018335 has been added.
-----------------------------------------------------------------------------------------
-- Mod By       : Gareth Jones
-- Mod Date     : 27-Jul-2010.  PrfNBS017475.
-- Mod Details  : Performance fixes applied to cursors that are poor-performing.  This applies
-- to 20 cursors that have been tuned.
---------------------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari
-- Mod Date     : 30-Jul-2010.
-- Mod Ref      : MrgNBS018480(merge 3.5b to 3.5f)
-- Mod Details  : Merged PrfNBS017475
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 25-Aug-2010
-- Def Ref    : NBS00018870
-- Def Details: Modified to handle EAN and OCC deletion scenario.
---------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 27-Aug-2010
-- Def Ref    : NBS00018887
-- Def Details: The TSL_SCA_PUB_INFO deletion is reoved from the dly prg as it is already
--              taken care by the PROCESS_QUEUE_RECORD procedure of the RMSMFM_TSLSUPPCHNATTR.
---------------------------------------------------------------------------------------------
--Mod By      : Sripriya,Sripriya.karanam@in.tesco.com
-- Mod Date   : 12-Nov-2010
-- Def Ref    : NBS00019715
-- Def Details: Modified the function DEL_ITEM.
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Mod By      : Parvesh parveshkumar.rulhan@in.tesco.com Begin
-- Mod Date   : 16-Feb-2011
-- Def Ref    : DefNBS021532 CR304
-- Def Details: Modified the function DEL_ITEM to delete items from tsl_deactivate_error table.
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--Mod By      : Accenture/Parvesh Rulhan,parveshkumar.rulhan@in.tesco.com                                    --
--Mod Date    : 21-Jul-2011                                                                                  --
--Mod Ref     : DefNBS023298                                                                                 --
--Mod Details : Added new function DAILY_PURGE_DEL_RPM_RECS to delete records from rpm_item_zone_price,      --
--            : rpm_zone_future_retail tables.                                                               --
---------------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P/Usha P,bharagavi.pujari@in.tesco.com/usha.patil@in.tesco.com
-- Mod Date   : 01-Jan-2012
-- Mod Ref    : N169/CR373
-- Mod Detail : Modified del_item to delete records from pos_item_button and called new function
--              TSL_PICKLIST_ITEM_PURGE to insert records into tsl_pickist_status table if there
--              is no picklist approval happened and no purge record is present in the table.
--              (action type as 'P')
---------------------------------------------------------------------------------------------
-- Mod By     : V Manikandan , Manikandan.varadhan@in.tesco.com
-- Mod Date   : 15-Mar-2013
-- Mod Ref    : MrgNBS025782
-- Mod Details: Defect DefNBS025484 has been added.
-----------------------------------------------------------------------------------------
--Mod By      : Sriranjitha Bhagi/Sriranjitha.Bhagi@in.tesco.com
--Mod Date    : 26-Sep-2012
--Mod Ref     : NBS00025484
--Mod Details : Modified the DEL_ITEM function to write the error failure and process the next record if
--              TSL_RNA_SQL.RETURN_TO_RNA is False.
---------------------------------------------------------------------------------------------
-- Mod By       : Sriranjitha Bhagi
-- Mod Date     : 20-Aug-2013
-- Mod Ref      : PrfNBS026215
-- Mod Details  : Performance fixes applied for better performance.
---------------------------------------------------------------------------------------------
-- Mod By       : Niraj Choudhary
-- Mod Date     : 18-Sep-2013
-- Mod Ref      : CR485-E2E issue
-- Mod Details  : Base Item is getting published before VAR and Base/VAR message published before TPND.
---------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P/Usha P,bharagavi.pujari@in.tesco.com/usha.patil@in.tesco.com
-- Mod Date   : 10-Mar-2014
-- Mod Ref    : NBS00026901
-- Mod Detail : Modified dele_item cursor for SCA Head deletion
--              added below condition as the pack which is getting deleted for that only SCA Head should be deleted
--              as an example UK & ROI can have diff pre packs and on deleting the UK it should not
--              delete the ROI records in the TSL_SCA_HEAD which will cause dlrprg batch failure with
--              unknown error, the fix is to delete base on the pack getting passed.
----------------------------------------------------------------------------------------------
-- Mod By       : Banashankari Ramachandra
-- Mod Date     : 07-Jan-2014
-- Mod Ref      : CR399
-- Mod Details  : Delete the records from TSL_ITEM_MIN_PRICE table
---------------------------------------------------------------------------------------------
-- Mod By       : Usha Patil
-- Mod Date     : 22-Oct-2014
-- Mod Ref      : PM035013
-- Mod Details  : Modified DEL_ITEM to call GET_ITEM_MASTER instead of GET_INFO as this func
--does some validations that are not required.
---------------------------------------------------------------------------------------------
RECORD_LOCKED   EXCEPTION;
PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
LP_table        VARCHAR2(50);

FUNCTION DEL_ITEM(error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                  I_key_value     IN       ITEM_MASTER.ITEM%TYPE,
                  I_cancel_item   IN       BOOLEAN,
                  -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                  I_barcode_move_exch_ind  IN VARCHAR2 DEFAULT 'N')
                  -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
    RETURN BOOLEAN IS
   L_class                    ITEM_MASTER.CLASS%TYPE;
   L_class_name               CLASS.CLASS_NAME%TYPE;
   L_default_waste_pct        ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE;
   L_dept                     ITEM_MASTER.DEPT%TYPE;
   L_dept_name                DEPS.DEPT_NAME%TYPE;
   L_elc_ind                  SYSTEM_OPTIONS.ELC_IND%TYPE;
   L_grandparent_desc         ITEM_MASTER.ITEM_DESC%TYPE;
   L_import_ind               SYSTEM_OPTIONS.IMPORT_IND%TYPE;
   L_item                     ITEM_EXP_DETAIL.ITEM%TYPE;
   L_item_desc                ITEM_MASTER.ITEM_DESC%TYPE;
   L_item_grandparent         ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_item_level               ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_item_parent              ITEM_MASTER.ITEM_PARENT%TYPE;
   L_orderable_ind            ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_ind                 ITEM_MASTER.PACK_IND%TYPE;
   L_pack_tmpl_id             PACK_TMPL_HEAD.PACK_TMPL_ID%TYPE;
   L_pack_type                ITEM_MASTER.PACK_TYPE%TYPE;
   L_parent_desc              ITEM_MASTER.ITEM_DESC%TYPE;
   L_retail_zone_group_id     ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE;
   L_sellable_ind             ITEM_MASTER.SELLABLE_IND%TYPE;
   L_selling_unit_retail_prim ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE;
   L_selling_uom_prim         ITEM_ZONE_PRICE.SELLING_UOM%TYPE;
   L_short_desc               ITEM_MASTER.SHORT_DESC%TYPE;
   L_simple_pack_ind          ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_status                   ITEM_MASTER.STATUS%TYPE;
   --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
   L_rna_item_status          ITEM_MASTER.STATUS%TYPE;
   --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
   L_std_unit_cost_prim       ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_std_unit_retail_prim     ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE;
   L_std_uom_prim             ITEM_MASTER.STANDARD_UOM%TYPE;
   L_subclass                 ITEM_MASTER.SUBCLASS%TYPE;
   L_sub_name                 SUBCLASS.SUB_NAME%TYPE;
   L_tran_level               ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_vdate                    PERIOD.VDATE%TYPE := DATES_SQL.GET_VDATE;
   L_waste_pct                ITEM_MASTER.WASTE_PCT%TYPE;
   L_waste_type               ITEM_MASTER.WASTE_TYPE%TYPE;
   L_pack_tmpl_del_ind        VARCHAR2(1) := 'X';
   L_item_exists              BOOLEAN;
   L_repl_attr_id             REPL_ATTR_UPDATE_HEAD.REPL_ATTR_ID%TYPE;
--05-Oct-2007 TESCO HSC/Praveen        Mod:N105- Change Begin
   L_item_number_type         ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   L_consumer_unit            ITEM_MASTER.TSL_CONSUMER_UNIT%TYPE;
   L_rna_type                 BOOLEAN;
   L_rna_item                 ITEM_MASTER.ITEM%TYPE;
   L_it_lvl                   ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_pk_ind                   ITEM_MASTER.PACK_IND%TYPE;
--05-Oct-2007 TESCO HSC/Praveen        Mod:N105- Change End
   L_config_type              POS_CONFIG_ITEMS.POS_CONFIG_TYPE%TYPE;
   L_config_id                POS_CONFIG_ITEMS.POS_CONFIG_ID%TYPE;
   L_num_items                NUMBER(7);
   L_dummy                    VARCHAR(1);
   --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    Begin
   L_tsl_common_ind           ITEM_MASTER.TSL_COMMON_IND%TYPE;
   --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    End
  TYPE TYP_ROWID              is TABLE of ROWID;
  TBL_ROWID                   TYP_ROWID;
  -- DefNBS008703, 5-Sep-2008 Tesco HSC/Satish Begin
  L_match                     BOOLEAN;
  L_flag                      VARCHAR2(1) := 'Y';
  -- DefNBS008703, 5-Sep-2008 Tesco HSC/Satish End
  ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
  L_use_rna_ind               SYSTEM_OPTIONS.TSL_RNA_IND%TYPE;
  ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End
   --20-Apr-2010 JK                        MrgNBS017125  Begin
   --22-MAR-2010 HSC/Srini                 NBS00016706 - Begin
   D_item                     ITEM_EXP_DETAIL.ITEM%TYPE;
    --22-MAR-2010 HSC/Srini                 NBS00016706 - End
    --20-Apr-2010 JK                        MrgNBS017125  End
   --DefNBS019715,12-Nov-2010,Sripriya,Sripriya.karanam@in.tesco.com Begin
   L_own_ctry                ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
   L_parent                  ITEM_MASTER.ITEM%TYPE;
   L_rna_child               BOOLEAN  := TRUE;
   L_attrib_rec              ITEM_ATTRIBUTES%ROWTYPE;
   --DefNBS019715,12-Nov-2010, Sripriya ,Sripriya.karanam@in.tesco.com End
   --PM035013, Usha Patil, usha.patil@in.tesco.com, 22-OCT-2014, BEGIN
   L_item_master_row         ITEM_MASTER%ROWTYPE;
   --PM035013, Usha Patil, usha.patil@in.tesco.com, 22-OCT-2014, END
--------_item----------------------------------------------------------------
-- 07-Jan-2014 Banashankari,Banashankari.Ramachandra@in.tesco.com CR399  Begin
-- Cursor to lock table 'tsl_item_min_price'
CURSOR C_LOCK_TSL_ITEM_MIN_PRICE IS
 SELECT item
  from tsl_item_min_price
  where  ROWID IN (SELECT t.ROWID
                       FROM item_Master i, tsl_item_min_price t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.ROWID
                       FROM item_master i, tsl_item_min_price t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value)
                        FOR UPDATE NOWAIT;

 -- 07-Jan-2014 Banashankari,Banashankari.Ramachandra@in.tesco.com CR399  End

-- 18-Jun-2007 Satish BN, satish.narasimhaiah@in.tesco.com  Mod N21  Begin

-- Cursor to lock table 'tsl_sca_wh_dist_grp'
-- PrfNBS017475 Gareth Jones 27-Jul-2010.
    CURSOR C_LOCK_TSL_SCA_WH_DIST_GRP is
    SELECT item
      FROM tsl_sca_wh_dist_grp
     WHERE rowid in (SELECT t.rowid
                       FROM item_Master i,tsl_sca_wh_dist_grp t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM item_master i,tsl_sca_wh_dist_grp t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value
                      UNION all
                     SELECT t.rowid
                       FROM tsl_sca_head ts,tsl_sca_wh_dist_grp t
                      WHERE ts.item          = t.item
                        AND ts.def_pref_pack = I_key_value)
     FOR UPDATE NOWAIT;

-- Cursor to lock table 'tsl_sca_wh_order_pref_pack'
-- PrfNBS017475 Gareth Jones 27-Jul-2010.
    CURSOR C_LOCK_SCA_WH_ORDER_PREF_PACK is
    SELECT item
      FROM tsl_sca_wh_order_pref_pack
     WHERE rowid in (SELECT t.rowid
                       FROM item_Master i,tsl_sca_wh_order_pref_pack t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM item_master i,tsl_sca_wh_order_pref_pack t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value
                      UNION all
                     SELECT t.rowid
                       FROM tsl_sca_wh_order_pref_pack t
                      WHERE t.pref_pack = I_key_value)
     FOR UPDATE NOWAIT;
-- Cursor to lock table 'tsl_sca_wh_order_grp'
-- PrfNBS017475 Gareth Jones 27-Jul-2010
    CURSOR C_LOCK_TSL_SCA_WH_ORDER_GROUP is
    SELECT item
      FROM tsl_sca_wh_order_grp
     WHERE rowid in (SELECT t.rowid
                       FROM item_master i,tsl_sca_wh_order_grp t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM item_master i,tsl_sca_wh_order_grp t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM tsl_sca_head ts,tsl_sca_wh_order_grp t
                      WHERE ts.item          = t.item
                        AND ts.def_pref_pack = I_key_value)
    FOR UPDATE NOWAIT;
-- Cursor to lock table 'tsl_sca_direct_order_grp'
-- PrfNBS017475 Gareth Jones 27-Jul-2010
    CURSOR C_LOCK_SCA_DIRECT_ORDER_GROUP is
    SELECT item
      FROM tsl_sca_direct_order_grp
     WHERE rowid in (SELECT t.rowid
                       FROM item_Master i, tsl_sca_direct_order_grp t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM item_master i, tsl_sca_direct_order_grp t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM tsl_sca_head ts, tsl_sca_direct_order_grp t
                      WHERE ts.item          = t.item
                        AND ts.def_pref_pack = I_key_value)
     FOR UPDATE NOWAIT;
-- Cursor to lock table 'tsl_sca_direct_dist_grp'
-- PrfNBS017475 Gareth Jones 27-Jul-2010
    CURSOR C_LOCK_SCA_DIRECT_DIST_GROUP is
    SELECT item
      FROM tsl_sca_wh_dist_grp
     WHERE rowid in (SELECT t.rowid
                       FROM item_Master i,tsl_sca_wh_dist_grp t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM item_master i,tsl_sca_wh_dist_grp t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value
                      UNION all
                     SELECT t.rowid
                       FROM tsl_sca_head ts,tsl_sca_wh_dist_grp t
                      WHERE ts.item          = t.item
                        AND ts.def_pref_pack = I_key_value)
     FOR UPDATE NOWAIT;

-- Cursor to lock table 'tsl_sca_item_distribution_type'
-- PrfNBS017475 Gareth Jones - 27-Jul-2010
    CURSOR C_LOCK_TSL_SCA_ITEM_DIST_TYPE is
    SELECT item
      FROM tsl_sca_item_distribution_type
     WHERE rowid IN (SELECT t.rowid
                       FROM item_Master i,tsl_sca_item_distribution_type t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM item_master i,tsl_sca_item_distribution_type t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM tsl_sca_head ts,tsl_sca_item_distribution_type t
                      WHERE ts.item          = t.item
                        AND ts.def_pref_pack = I_key_value)
       FOR UPDATE NOWAIT;
-- 18-Jun-2007 Satish BN, satish.narasimhaiah@in.tesco.com  Mod N21  End
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Cursor to lock table 'tsl_sca_wh_order'
-- PrfNBS017475 Gareth Jones - 27-Jul-2010
   CURSOR C_LOCK_TSL_SCA_WH_ORDER is
    SELECT item
      FROM tsl_sca_wh_order
     WHERE rowid IN (SELECT t.rowid
                       FROM item_Master i,tsl_sca_wh_order t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM item_master i,tsl_sca_wh_order t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM tsl_sca_head ts,tsl_sca_wh_order t
                      WHERE ts.item          = t.item
                        AND ts.def_pref_pack = I_key_value)
       FOR UPDATE NOWAIT;
-- Cursor to lock table 'tsl_sca_direct_dist_packs'
-- PrfNBS017475 Gareth Jones 27-Jul-2010
   CURSOR C_LOCK_SCA_DIRECT_DIST_PACKS is
   SELECT item
      FROM tsl_sca_direct_dist_packs
     WHERE rowid in (SELECT t.rowid
                       FROM item_Master i, tsl_sca_direct_dist_packs t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM item_master i, tsl_sca_direct_dist_packs t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value
                      UNION all
                     SELECT t.rowid
                       FROM tsl_sca_direct_dist_packs t
                      WHERE t.pack_no = I_key_value)
      FOR UPDATE NOWAIT;

-- Cursor to lock table 'tsl_sca_pref_pack'
   CURSOR C_LOCK_TSL_SCA_PREF_PACK is
   select item
     from tsl_sca_pref_pack
    where (item in (select item
                          from item_master
                         where (item_parent      = I_key_value
                            or  item_master.item = I_key_value))
           or def_pref_pack = I_key_value)
      for update nowait;

-- Cursor to lock table 'tsl_sca_dist_group_trig'
-- PrfNBS017475 Gareth Jones 27-Jul-2010
   CURSOR C_LOCK_TSL_SCA_DIST_GROUP_TRIG is
   SELECT item
     FROM tsl_sca_dist_group_trig
    WHERE rowid in (SELECT t.rowid
                      FROM item_Master i, tsl_sca_dist_group_trig t
                     WHERE i.item = t.item
                       AND i.item = I_key_value
                     UNION ALL
                    SELECT t.rowid
                      FROM item_master i, tsl_sca_dist_group_trig t
                     WHERE i.item        = t.item
                       AND i.item_parent = I_key_value
                     UNION all
                    SELECT t.rowid
                      FROM tsl_sca_head ts, tsl_sca_dist_group_trig t
                     WHERE ts.item= t.item
                    AND ts.def_pref_pack = I_key_value)
      FOR UPDATE NOWAIT;
----------------------------------------------------------------------------------
   --PrfNBS017475 - Gareth Jones 27-Jul-2010.
   CURSOR C_LOCK_TSL_SCA_HEAD is
   SELECT item
     FROM tsl_sca_head
    WHERE rowid IN (SELECT t.rowid
                       FROM item_Master i,tsl_sca_head t
                      WHERE i.item = t.item
                        AND i.item = I_key_value
                      UNION ALL
                     SELECT t.rowid
                       FROM item_master i,tsl_sca_head t
                      WHERE i.item        = t.item
                        AND i.item_parent = I_key_value
                      UNION ALL
                     SELECT ts.rowid
                       FROM tsl_sca_head ts
                      WHERE ts.def_pref_pack = I_key_value)
      -- NBS00026901 10-Mar-2014 Bhargavi P/bharagavi.pujari@in.tesco.com Begin
      AND decode(L_simple_pack_ind,'Y',def_pref_pack,'N',item) = I_key_value
      -- NBS00026901 10-Mar-2014 Bhargavi P/bharagavi.pujari@in.tesco.com End
      FOR UPDATE NOWAIT;
 -- CR162 Tarun Kumar Mishra tarun.mishra@in.tesco.com 25-Oct-2008 Begin
 -- Removed the code from here for locking table TSL_SCA_WH_DIST_GROUP_DETAIL
 -- and TSL_SCA_WH_DIST_GROUP_HEAD as after CR162 the distribution group is
 -- going to maintain by external system.
 -- CR162 Tarun Kumar Mishra tarun.mishra@in.tesco.com 25-Oct-2008 End
 ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
 --08-Dec-2009 HSC/Nikhil                  DefNBS00015685 - Begin

 --20-Apr-2010 JK                        MrgNBS017125  Begin
 --22-MAR-2010 HSC/Srini                 NBS00016706 - Begin

 cursor C_LOCK_TSL_SCA_MFQUEUE is
      select item
        from tsl_sca_mfqueue
       where item in (select item
                        from item_master
                       where (item_parent = I_key_value  and item_master.status <> 'A' )or
                            (item_master.item = I_key_value and item_master.status <> 'A' )) for update;
  --22-MAR-2010 HSC/Srini                 NBS00016706 - End
  --20-Apr-2010 JK                        MrgNBS017125  End

--08-Dec-2009 HSC/Nikhil                  DefNBS00015685 - End
---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
   CURSOR C_LOCK_TSL_SL_RECON_REPORT_DTL is
      select adj_item
        from tsl_sl_recon_report_detail
       where adj_item in (select item
                            from item_master
                           where (item_parent = I_key_value or
                                 item_master.item = I_key_value))
         for update nowait;

   CURSOR C_LOCK_TSL_SL_RECON_REPORT_HD is
      select 'x'
        from tsl_sl_recon_report_head
       where report_number in (select report_number
                                 from tsl_sl_recon_report_detail
                                where adj_item in (select item
                                                     from item_master
                                                    where (item_parent = I_key_value or
                                                          item_master.item = I_key_value)))
         for update nowait;

   CURSOR C_LOCK_TSL_SCA_PUB_INFO is
      select item
        from tsl_sca_pub_info
       where item in (select item
                        from item_master
                       where (item_parent = I_key_value or
                             item_master.item = I_key_value))
         for update nowait;
   --17-Oct-2007 WiproEnabler/Ramasamy - Modified to fix the issue for CQ 3252 - End
   ---------------------------------------------------------------------------
   cursor C_GET_ITEM is
      select item
        from item_master
       where item_parent = I_key_value
          or item_grandparent = I_key_value;
   cursor C_GET_TRAN_LEVEL_ITEMS is
      select item
        from item_master
       where (item_parent = I_key_value
          or item_grandparent = I_key_value)
         and item_level = tran_level;
   cursor C_GET_PACK_TMPL_ID is
    select i.pack_tmpl_id
      from packitem i,
           pack_tmpl_head h
     where i.pack_no = I_key_value
       and i.pack_tmpl_id = h.pack_tmpl_id
       and h.fash_prepack_ind = 'Y';
   cursor C_LOCK_SKULIST_CRITERIA is
      select 'x'
        from skulist_criteria
       where item = I_key_value
       --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, Begin
       --Removed the code from here where item_parent and item_grandparent is checked.
       --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, End
         for update nowait;
   cursor C_LOCK_SUB_ITEMS_DTL is
      select 'x'
        from sub_items_detail
       where item = I_key_value
          or sub_item = I_key_value
          or exists (select item
                       from item_master
                      where (item_parent = I_key_value
                         or item_grandparent = I_key_value)
                        and (item_master.item = sub_items_detail.item
                             or item_master.item = sub_items_detail.sub_item))
         for update nowait;
   cursor C_LOCK_SUB_ITEMS_HEAD is
      select 'x'
        from sub_items_head
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_SKULIST_DETAIL is
      select 'x'
        from skulist_detail
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_VAT_ITEM is
      select 'x'
        from vat_item
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_INV_STATUS_QTY is
      select 'x'
        from inv_status_qty
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_REPL_ATTR_UPD_EXCLUDE is
      select 'x'
        from repl_attr_update_exclude
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
          for update nowait;
   cursor C_LOCK_REPL_ATTR_UPDATE_LOC is
      select 'x'
        from repl_attr_update_loc
       where repl_attr_id
          in (select repl_attr_id
                from repl_attr_update_item
               where item
                  in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value)))
         for update nowait;
   cursor C_LOCK_REPL_ATTR_UPDATE_HEAD is
      select 'x'
        from repl_attr_update_head
       where repl_attr_id
          in (select repl_attr_id
                from repl_attr_update_item
               where item
                  in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value)))
         for update nowait;
   cursor C_LOCK_MASTER_REPL_ATTR is
      select 'x'
        from master_repl_attr
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
          for update nowait;
   cursor C_LOCK_REPL_ATTR is
      select 'x'
        from repl_attr_update_item
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
          for update nowait;
   cursor C_LOCK_REPL_DAY is
      select 'x'
        from repl_day
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_REPL_ITEM_LOC is
      select 'x'
        from repl_item_loc
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_REPL_ITEM_LOC_UPDATES is
      select 'x'
        from repl_item_loc_updates
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_COST_SS_DTL_LOC is
      select 'x'
        from cost_susp_sup_detail_loc
       where item
           in (select item
                 from item_master
                where (item_parent = I_key_value
                       or item_grandparent = I_key_value
                       or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_COST_SS_DTL is
      select 'x'
        from cost_susp_sup_detail
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   --DefNBS011401 09-Feb-09 Chandru Begin
   cursor C_LOCK_TSL_EXP_QUEUE is
      select 'x'
        from tsl_exp_queue
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_TSL_ITEM_EXP_DETAIL is
      select 'x'
        from tsl_item_exp_detail
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_TSL_ITEM_EXP_HEAD is
      select 'x'
        from tsl_item_exp_head
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   --DefNBS011401 09-Feb-09 Chandru End
   cursor C_LOCK_ITEM_EXP_DETAIL is
      select 'x'
        from item_exp_detail
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_EXP_HEAD is
      select 'x'
        from item_exp_head
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_HTS_ASSESS is
      select 'x'
        from item_hts_assess
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_HTS is
      select 'x'
        from item_hts
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_REQ_DOC is
      select 'x'
        from req_doc
       where module      = 'IT'
         and (key_value_2 = I_key_value
              or exists (select item
                           from item_master
                          where (item_parent = I_key_value
                                 or item_grandparent = I_key_value)
                            and item_master.item = req_doc.key_value_2))
         for update nowait;
   cursor C_LOCK_ITEM_IMPORT_ATTR is
      select 'x'
        from item_import_attr
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
    cursor C_LOCK_TIMELINE is
       select 'x'
         from timeline
        where timeline_type = 'IT'
          and  exists (select item
                            from item_master
                           where (item = I_key_value
                                  or item_parent = I_key_value
                                  or item_grandparent = I_key_value)
                             and (item_master.item = timeline.key_value_1
                                  or item_master.item = timeline.key_value_2))
          for update nowait;
   cursor C_LOCK_COND_TARIFF_TREATMENT is
      select 'x'
        from cond_tariff_treatment
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_IMAGE is
      select 'x'
        from item_image
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_SUPP_UOM is
      select 'x'
        from item_supp_uom
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_DEAL_SKU_TEMP is
      select 'x'
        from deal_sku_temp
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_FUTURE_COST is
      select 'x'
        from future_cost
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_DEAL_ITEMLOC is
      select 'x'
        from deal_itemloc
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_DEAL_DETAIL is
      select 'x'
        from deal_detail
       where (qty_thresh_buy_item = I_key_value
          or exists (select item
                       from item_master
                      where (item_parent = I_key_value
                         or item_grandparent = I_key_value)
                        and item_master.item = deal_detail.qty_thresh_buy_item))
          or (qty_thresh_get_item = I_key_value
          or exists (select item
                       from item_master
                      where (item_parent = I_key_value
                         or item_grandparent = I_key_value)
                        and item_master.item = deal_detail.qty_thresh_get_item))
         for update nowait;
   cursor C_LOCK_ITEM_SUPP_COUNTRY is
      select 'x'
        from item_supp_country
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_SUPP_COUNTRY_DIM is
      select 'x'
        from item_supp_country_dim
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_RECLASS_ITEM is
      select 'x'
        from reclass_item
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_SUP_AVAIL is
      select 'x'
        from sup_avail
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_ATTRIBUTES is
      select 'x'
       from item_attributes
      where item
         in (select item
               from item_master
              where (item_parent = I_key_value
                     or item_grandparent = I_key_value
                     or item_master.item = I_key_value))
        for update nowait;
   cursor C_LOCK_ITEM_LOC is
      select rowid
        from item_loc
       where rowid in (select rowid
                         from item_loc
                        where item = I_key_value
                        union all
                       select rowid
                         from item_loc
                        where item_parent = I_key_value
                        union all
                       select rowid
                         from item_loc
                        where item_grandparent = I_key_value)
         for update nowait;
   cursor C_LOCK_ITEM_LOC_SOH is
      select rowid
        from item_loc_soh
       where item = I_key_value
          or item_parent = I_key_value
          or item_grandparent = I_key_value
         for update nowait;
   cursor C_LOCK_ITEM_SUPPLIER is
       select /*+ ordered */ isp.rowid
        from (select item
                from item_master im
               where im.item = i_key_value
               union all
              select item
                from item_master im
               where im.item_parent = i_key_value
               union all
              select item
                from item_master im
               where im.item_grandparent = i_key_value) i,
             item_supplier isp
       where isp.item = i.item
       order by isp.rowid
         for update of isp.item nowait;
   cursor C_LOCK_PACK_TMPL_DETAIL is
      select 'x'
        from pack_tmpl_detail
       where pack_tmpl_id = L_pack_tmpl_id
         for update nowait;
   cursor C_LOCK_SUPS_PACK_TMPL_DESC is
      select 'x'
        from sups_pack_tmpl_desc
       where pack_tmpl_id = L_pack_tmpl_id
         for update nowait;
   cursor C_LOCK_PACK_TMPL_HEAD is
      select 'x'
        from pack_tmpl_head
       where pack_tmpl_id = L_pack_tmpl_id
         for update nowait;
   cursor C_LOCK_UDA_ITEM_LOV is
      select 'x'
        from uda_item_lov
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
        for update nowait;
   cursor C_LOCK_UDA_ITEM_DATE is
      select 'x'
        from uda_item_date
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_UDA_ITEM_FF is
      select 'x'
        from uda_item_ff
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_SEASONS is
      select 'x'
        from item_seasons
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_TICKET is
      select 'x'
        from item_ticket
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_DAILY_PURGE is
      select 'x'
       from daily_purge
      where (key_value = I_key_value
             or exists (select item
                          from item_master
                         where (item_parent = I_key_value
                                or item_grandparent = I_key_value)
                           and item_master.item = daily_purge.key_value))
        and table_name = 'ITEM_MASTER'
        for update nowait;
   cursor C_LOCK_DAILY_PURGE_II is
      select 'x'
       from daily_purge
      where key_value = I_key_value
        and table_name = 'ITEM_MASTER'
        for update nowait;
   cursor C_LOCK_COMP_SHOP_LIST is
      select 'x'
        from comp_shop_list
      where item = I_key_value
         or ref_item = I_key_value
         or exists (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value)
                       and (item_master.item = comp_shop_list.item
                            or item_master.item = comp_shop_list.ref_item))
        for update nowait;
   cursor C_LOCK_COMP_SHOP_LIST_REF_ITEM is
      select 'x'
        from comp_shop_list
       where ref_item = i_key_value
         for update nowait;
   cursor C_LOCK_ITEM_APPROVAL_ERROR is
      select 'x'
        from item_approval_error
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_TICKET_REQUEST is
      select 'x'
        from ticket_request
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                       or item_grandparent = I_key_value
                       or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_TAXCODE_ITEM is
      select 'x'
        from product_tax_code
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_SOURCE_DLVRY_SCHED_EXC is
      select 'x'
        from source_dlvry_sched_exc
       where item
          in (select item
                from item_master
                where (item_parent = I_key_value
                       or item_grandparent = I_key_value
                       or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_PRICE_HIST is
      select 'x'
        from price_hist
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_POS_MODS is
      select 'x'
        from pos_mods
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_LOC_TRAITS is
      select 'x'
        from item_loc_traits
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_EDI_DAILY_SALES is
      select 'x'
        from edi_daily_sales
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                       or item_grandparent = I_key_value
                       or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_PACKITEM_BREAKOUT is
      select rowid
        from packitem_breakout
       where pack_no
          in (select item
                from item_master
               where (item_parent = I_key_value
                       or item_grandparent = I_key_value)
                       or item_master.item = I_key_value)
         for update nowait;
   cursor C_LOCK_PACKITEM is
      select rowid
        from packitem
       where pack_no
          in (select item
                from item_master
               where (item_parent = I_key_value
                       or item_grandparent = I_key_value)
                       or item_master.item = I_key_value)
         for update nowait;
   cursor C_LOCK_ITM_SUP_CTRY_BRACK_COST is
      select 'x'
        from item_supp_country_bracket_cost
       where item
          in  (select item
                        from item_master
                       where (item_parent = I_key_value
                          or item_grandparent = I_key_value
                          or item_master.item = item_supp_country_bracket_cost.item))
         for update nowait;
   cursor C_LOCK_ITEM_SUPP_COUNTRY_LOC is
            select /*+ ordered index(iscl) */
              iscl.rowid
           from (select item
                  from item_master im
                  where im.item = i_key_value
                  union all
                  select item
                  from item_master im
                  where im.item_parent = i_key_value
                  union all
                  select item
                  from item_master im
                  where im.item_grandparent = i_key_value) i,
                  item_supp_country_loc iscl
           where iscl.item = i.item
           order by iscl.rowid
           for update of iscl.item nowait;
   cursor C_LOCK_EDI_COST_LOC is
      select 'x'
        from edi_cost_loc
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_EDI_COST_CHG is
      select 'x'
        from edi_cost_chg
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_POS_MERCH_CRITERIA is
      select 'x'
        from pos_merch_criteria
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_CHRG_DETAIL is
      select 'x'
        from item_chrg_detail
       where item
          in (select item
                from item_master
               where (item_parent     = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_CHRG_HEAD is
      select 'x'
        from item_chrg_head
       where item
          in (select item
                from item_master
               where (item_parent     = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_RECLASS_COST_CHG is
      select 'x'
        from reclass_cost_chg_queue
       where item
          in (select item
                from item_master
               where (item_parent     = I_key_value
                  or item_grandparent = I_key_value
                  or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_MFQUEUE is
      select 'x'
        from item_mfqueue
       where rowid in (SELECT t.rowid
                         FROM item_master i, item_mfqueue t
                        WHERE i.item = t.item
                          AND i.item = I_key_value
                        UNION ALL
                       SELECT t.rowid
                         FROM item_master i,item_mfqueue t
                        WHERE i.item        = t.item
                          AND i.item_parent = I_key_value
                      UNION all
                       SELECT t.rowid
                         FROM item_master i,item_mfqueue t
                        WHERE i.item        = t.item
                          AND i.item_grandparent = I_key_value)
      for update nowait;
   cursor C_LOCK_ITEMLOC_MFQUEUE is
      select 'x'
        from itemloc_mfqueue
       where item
          in (select item
                from item_master
               where (item_parent     = I_key_value
                  or item_grandparent = I_key_value
                  or item_master.item = I_key_value))
         for update nowait;
   cursor C_LOCK_ITEM_MASTER is
      select 'x'
        from item_master
       where item = I_key_value
          or item_parent = I_key_value
          or item_grandparent = I_key_value
         for update nowait;
   cursor C_CHECK_SIMPLE_PACK is
      select pack_no
        from packitem
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                      or item_grandparent = I_key_value
                      or item_master.item = I_key_value));
   cursor C_LOCK_ITEM_XFORM_HEAD IS
      select head_item
        from item_xform_head
       where head_item
          in (select item
                from item_master
               where (item_parent = I_key_value
                  or item_grandparent = I_key_value
                  or item_master.item = I_key_value))
       for update nowait;
  cursor C_LOCK_ITEM_XFORM_DETAIL IS
     select detail_item
       from item_xform_detail
      where detail_item
         in (select item
               from item_master
              where (item_parent = I_key_value
                 or item_grandparent = I_key_value
                 or item_master.item = I_key_value))
    for update nowait;
 cursor C_LOCK_DEAL_ITEM_LOC_EXPLODE IS
       select item
         from deal_item_loc_explode
        where item
           in (select item
                 from item_master
                where (item_parent = I_key_value
                   or item_grandparent = I_key_value
                   or item_master.item = I_key_value))
       for update nowait;
 cursor C_GET_REPL_ATTR_ID IS
       select NVL(repl_attr_id,0)
             from repl_attr_update_item
                where item = I_key_value
                  and item
           in (select item
                 from item_master
                where (item_parent = I_key_value
                   or item_grandparent = I_key_value
                   or item_master.item = I_key_value));
 --05-Oct-2007 TESCO HSC/Praveen        Mod:N105- Change Begin
cursor C_GET_RNA_ITEM is
select item,
       item_number_type,
       item_level,
       pack_ind,
       --CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
       status
       --CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
        from item_master
       where item = I_key_value
          or item_parent = I_key_value
          or item_grandparent = I_key_value;
--05-Oct-2007 TESCO HSC/Praveen        Mod:N105- Change End

cursor C_LOCK_POS_CONFIG_ITEMS is
      select 'x'
        from pos_config_items
       where item
          in (select item
                from item_master
               where ((item_parent = i_key_value
                      and item_parent is not null)
                  or (item_grandparent = i_key_value
                      and item_grandparent is not null)
                  or item_master.item = i_key_value))
         for update nowait;

   cursor C_LOCK_POS_STORE is
      select 'x'
        from pos_store
       where pos_config_id = L_config_id
         and pos_config_type = L_config_type
         for update nowait;

   cursor C_LOCK_POS_PROD_REST_HEAD is
      select 'x'
        from pos_prod_rest_head
       where pos_prod_rest_id = L_config_id
         for update nowait;

   cursor C_LOCK_POS_COUPON_HEAD is
      select 'x'
        from pos_coupon_head
       where coupon_id = L_config_id
         for update nowait;

   cursor C_GET_CONFIG is
      select distinct pos_config_type,
             pos_config_id
        from pos_config_items
       where item
          in (select item
                from item_master
               where ((item_parent = i_key_value
                      and item_parent is not null)
                  or (item_grandparent = i_key_value
                      and item_grandparent is not null)
                  or item_master.item = i_key_value));

   cursor C_GET_TOTAL_ITEMS is
      select count(item)
        from pos_config_items
       where pos_config_id = L_config_id
         and pos_config_type = L_config_type
       group by pos_config_type,
                pos_config_id;
 --N23 Change Begin
 CURSOR C_TSL_ITEMDESC_TILL IS
        select item
          from tsl_itemdesc_till
         where item
            in (select item
                  from item_master
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                 where (item_grandparent = I_key_value
                    or  item_parent      = I_key_value
                    or  item_master.item = I_key_value))
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END
           for update nowait;

 CURSOR C_TSL_ITEMDESC_PACK IS
        select pack_no
          from tsl_itemdesc_pack
         where pack_no
            in (select item
                  from item_master
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                 where (item_grandparent = I_key_value
                    or  item_parent      = I_key_value
                    or  item_master.item = I_key_value))
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END
           for update nowait;

 CURSOR C_TSL_ITEMDESC_SEL IS
        select item
          from tsl_itemdesc_sel
         where item
            in (select item
                  from item_master
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                 where (item_grandparent = I_key_value
                    or  item_parent      = I_key_value
                    or  item_master.item = I_key_value))
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END
           for update nowait;

 CURSOR C_TSL_ITEMDESC_BASE IS
        select item
          from tsl_itemdesc_base
         where item
            in (select item
                  from item_master
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                 where (item_grandparent = I_key_value
                    or  item_parent      = I_key_value
                    or  item_master.item = I_key_value))
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END
           for update nowait;

 CURSOR C_TSL_ITEMDESC_EPISEL IS
        select item
          from tsl_itemdesc_episel
         where item
            in (select item
                  from item_master
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                 where (item_grandparent = I_key_value
                    or  item_parent      = I_key_value
                    or  item_master.item = I_key_value))
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END
           for update nowait;

 CURSOR C_TSL_ITEMDESC_ISS IS
        select item
          from tsl_itemdesc_iss
         where item
            in (select item
                  from item_master
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                 where (item_grandparent = I_key_value
                    or  item_parent      = I_key_value
                    or  item_master.item = I_key_value))
                 -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END
           for update nowait;
 --N23 Change End

-- Mod N45 (Drop III), 03-Mar-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
    CURSOR C_LOCK_TSL_DEAL_ORDER_HIST is
    select 'X'
      from tsl_deal_order_hist tdoh
     where tdoh.item in (select im.item
                           from item_master im
                          where im.item_parent = I_key_value
                             or im.item_grandparent = I_key_value
                             or im.item = I_key_value)
       for update nowait;
    --
    CURSOR C_LOCK_TSL_DEAL_RECEIPT_HIST is
    select 'X'
      from tsl_deal_receipt_hist tdrh
     where tdrh.item in (select im.item
                           from item_master im
                          where im.item_parent = I_key_value
                             or im.item_grandparent = I_key_value
                             or im.item = I_key_value)
       for update nowait;
    --
    CURSOR C_LOCK_TSL_DEAL_SALES_HIST is
    select 'X'
      from tsl_deal_sales_hist tdsh
     where tdsh.item in (select im.item
                           from item_master im
                          where  im.item_parent = I_key_value
                             or im.item_grandparent = I_key_value
                             or im.item = I_key_value)
       for update nowait;
-- Mod N45 (Drop III), 03-Mar-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
-- 08-May-08 Bahubali D Mod N111 Begin
   cursor C_LOCK_COMMON_SUPS_MATRIX is
      select 'x'
        from tsl_common_sups_matrix tcsm
       where tcsm.item in (select im.item
                           from item_master im
                          where im.item_parent = I_key_value
                             or im.item_grandparent = I_key_value
                             or im.item = I_key_value)
       for update nowait;
-- 08-May-08 Bahubali D Mod N111 End
-- Begin ModN127 Wipro/JK 08-May-2008
    cursor C_LOCK_TSL_ITEM_RANGE IS
       select item
         from tsl_item_range
        where item
           in (select item
                 from item_master
                where (item_parent = I_key_value
                   or item_master.item = I_key_value))
       for update nowait;

    cursor C_LOCK_TSL_PROV_RANGE IS
       select item
         from tsl_prov_range
        where item
           in (select item
                 from item_master
                where (item_parent = I_key_value
                   or item_master.item = I_key_value))
       for update nowait;
-- End ModN127 Wipro/JK 08-May-2008

   -- 13-Aug-2008 Dhuraison Prince - Defect NBS008124 BEGIN
   CURSOR C_LOCK_TSL_FUTURE_COST is
   select 'X'
     from tsl_future_cost tfc
    where tfc.item in (select im.item
                         from item_master im
                        where im.item_parent      = I_key_value
                           or im.item_grandparent = I_key_value
                           or im.item             = I_key_value)
      for update nowait;
   -- 13-Aug-2008 Dhuraison Prince - Defect NBS008124 END
   --DefNBS019715,12-Nov-2010,Sripriya,Sripriya.karanam@in.tesco.com Begin
   CURSOR C_GET_ITEM_PARENT is
   select item_parent,
          tsl_owner_country
     from item_master
    where item = I_key_value;
  --DefNBS019715,12-Nov-2010,Sripriya,Sripriya.karanam@in.tesco.com End

BEGIN
---------------------------------------------------------------------------
   if ITEM_VALIDATE_SQL.EXIST(error_message,
                              L_item_exists,
                              I_key_value) = FALSE then
      return FALSE;
   end if;
   ---
   if L_item_exists = TRUE then
      FOR rec in C_CHECK_SIMPLE_PACK LOOP
         if DEL_ITEM(error_message,
                     rec.pack_no,
                     i_cancel_item) = FALSE then
            return FALSE;
         end if;
      END LOOP;
      if SYSTEM_OPTIONS_SQL.GET_IMPORT_ELC_IND(error_message,
                                               L_import_ind,
                                               L_elc_ind) = FALSE then
         return FALSE;
      end if;
      ---
      ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
      if SYSTEM_OPTIONS_SQL.TSL_GET_RNA_IND(error_message,
                                            L_use_rna_ind) = FALSE then
         return FALSE;
      end if;
      ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End
      --PM035013, Usha Patil, usha.patil@in.tesco.com, 22-OCT-2014, BEGIN
      --Commented the GET_INFO and called GET_ITEM_MASTER
      --if ITEM_ATTRIB_SQL.GET_INFO(error_message,
      --                          L_item_desc,                       /* item desc */
      --                          L_item_level,                      /* item level */
      --                          L_tran_level,                      /* tran level */
      --                          L_status,                          /* status */
      --                          L_pack_ind,                        /* pack ind */
      --                          L_dept,                            /* dept */
      --                          L_dept_name,                       /* dept name */
      --                          L_class,                           /* class */
      --                          L_class_name,                      /* class name */
      --                          L_subclass,                        /* subclass */
      --                          L_sub_name,                        /* subclass name */
      --                          L_retail_zone_group_id,            /* retail zone group id */
      --                          L_sellable_ind,                    /* sellable ind */
      --                          L_orderable_ind,                   /* orderable ind */
      --                          L_pack_type,                       /* pack type */
      --                          L_simple_pack_ind,                 /* simple pack ind */
      --                          L_waste_type,                      /* waste type */
      --                          L_item_parent,                     /* item parent */
      --                          L_item_grandparent,                /* item grandparent */
      --                          L_short_desc,                      /* short desc */
      --                          L_waste_pct,                       /* waste pct */
      --                          L_default_waste_pct,               /* default waste pct */
      --                          I_key_value) = FALSE then
      -- RETURN FALSE;
      --end if;

      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (error_message,
                                          L_item_master_row,
                                          I_key_value) = FALSE then
         return FALSE;
      end if;

      if L_item_master_row.item is NOT NULL then
         L_item_desc    :=  L_item_master_row.item_desc;
         L_item_level   :=  L_item_master_row.item_level;
         L_tran_level   :=  L_item_master_row.tran_level;
         L_status       :=  L_item_master_row.status;
         L_pack_ind     :=  L_item_master_row.pack_ind;
         L_dept         :=  L_item_master_row.dept;
         L_class        :=  L_item_master_row.class;
         L_subclass     :=  L_item_master_row.subclass;
         L_retail_zone_group_id := L_item_master_row.retail_zone_group_id;
         L_sellable_ind :=  L_item_master_row.sellable_ind;
         L_orderable_ind := L_item_master_row.orderable_ind;
         L_pack_type     := L_item_master_row.pack_type;
         L_simple_pack_ind := L_item_master_row.simple_pack_ind;
         L_waste_type    := L_item_master_row.waste_type;
         L_item_parent   := L_item_master_row.item_parent;
         L_item_grandparent := L_item_master_row.item_grandparent;
         L_short_desc    := L_item_master_row.short_desc;
         L_waste_pct     := L_item_master_row.waste_pct;
         L_default_waste_pct := L_item_master_row.default_waste_pct;
      end if;
      --PM035013, Usha Patil, usha.patil@in.tesco.com, 22-OCT-2014, END

      --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    Begin
      if ITEM_ATTRIB_SQL.TSL_GET_COMMON_IND(error_message,
                                            L_tsl_common_ind,
                                            I_key_value) = FALSE then
         return FALSE;
      end if;
      --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    End

      --21-Aug-2009 TESCO HSC/Murali N    NBS00014560   Begin
      if L_item_level < L_tran_level then
         if ITEM_ATTRIB_SQL.TSL_RECLASS_L2_COMMON(error_message,
                                                  L_tsl_common_ind,
                                                  I_key_value) = FALSE then
            return FALSE;
         end if;
      end if;
      --21-Aug-2009 TESCO HSC/Murali N    NBS00014560   End

      if L_pack_ind = 'Y' then
         SQL_LIB.SET_MARK('open',
                          'C_GET_PACK_TMPL_ID',
                          'packitem, pack_tmpl_head',
                          'PACK_NO: '||I_key_value);
         open C_GET_PACK_TMPL_ID;
         SQL_LIB.SET_MARK('fetch',
                          'C_GET_PACK_TMPL_ID',
                          'packitem, pack_tmpl_head',
                          'PACK_NO: '||I_key_value);
         fetch C_GET_PACK_TMPL_ID into L_pack_tmpl_id;
         if C_GET_PACK_TMPL_ID%FOUND then
            L_pack_tmpl_del_ind := 'Y';
         end if;
         SQL_LIB.SET_MARK('close',
                          'C_GET_PACK_TMPL_ID',
                          'packitem, pack_tmpl_head',
                          'PACK_NO: '||I_key_value);
         close C_GET_PACK_TMPL_ID;
      end if;  /* end if L_pack_ind = 'Y' */
      if I_cancel_item = FALSE then
         if L_status = 'A' then /* only want to do inserts for items in approved status */
           if L_item_level < L_tran_level then
            if NOT(L_pack_ind = 'Y' AND L_sellable_ind = 'N') then
               if ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL(error_message,
                                                       L_std_unit_cost_prim,
                                                       L_std_unit_retail_prim,
                                                       L_std_uom_prim,
                                                       L_selling_unit_retail_prim,
                                                       L_selling_uom_prim,
                                                       I_key_value) = FALSE then
                  return FALSE;
               end if;
               SQL_LIB.SET_MARK('INSERT',NULL,'PRICE_HIST',
                                'ITEM: '||I_key_value);
               insert into price_hist(tran_type,
                                      reason,
                                      item,
                                      loc,
                                      unit_cost,
                                      unit_retail,
                                      selling_unit_retail,
                                      selling_uom,
                                      action_date)
                               values(99,                         /* tran type */
                                      0,                          /* reason */
                                      I_key_value,                /* item */
                                      0,                          /* loc */
                                      L_std_unit_cost_prim,       /* unit cost */
                                      L_std_unit_retail_prim,     /* unit retail */
                                      L_selling_unit_retail_prim, /* selling unit retail */
                                      L_selling_uom_prim,         /* selling uom */
                                      TRUNC(to_date(to_char((L_vdate),'DDMMYY')||
                                      to_char(sysdate,'HH24MISS'),'DDMMYYHH24MISS')));
               SQL_LIB.SET_MARK('INSERT',NULL,'PRICE_HIST',
                                'ITEM: '||I_key_value);
               -- Item/Location record
               insert into price_hist(tran_type,
                                      reason,
                                      item,
                                      loc,
                                      loc_type,
                                      unit_cost,
                                      unit_retail,
                                      selling_unit_retail,
                                      selling_uom,
                                      action_date)
                              (select 99,
                                      0,
                                      I_key_value,
                                      il.loc,
                                      il.loc_type,
                                      iscl.unit_cost,
                                      il.unit_retail,
                                      il.selling_unit_retail,
                                      il.selling_uom,
                                      TRUNC(to_date(to_char(L_vdate,'DDMMYY')||to_char(sysdate,'HH24MISS'),'DDMMYYHH24MISS'))
                                 from item_loc il,
                                      item_supp_country_loc iscl
                                where il.item = I_key_value
                                  and il.item = iscl.item
                                  and il.loc  = iscl.loc);
            end if; /* end if NOT(L_pack_ind = 'Y' AND L_sellable_ind = 'N') */
            for c_rec in C_GET_TRAN_LEVEL_ITEMS LOOP
               if POS_UPDATE_SQL.POS_MODS_INSERT(error_message,
                                                 21,                  /* tran type */
                                                 c_rec.item,          /* item */
                                                 L_item_desc,         /* item desc */
                                                 NULL,                /* ref item */
                                                 L_dept,              /* dept */
                                                 L_class,             /* class */
                                                 L_subclass,          /* subclass */
                                                 NULL,                /* store */
                                                 NULL,                /* new price */
                                                 NULL,                /* new selling uom */
                                                 NULL,                /* old price */
                                                 NULL,                /* old selling uom */
                                                 NULL,                /* start date */
                                                 NULL,                /* new multi units */
                                                 NULL,                /* old multi units */
                                                 NULL,                /* new multi unit retail */
                                                 NULL,                /* new multi selling uom */
                                                 NULL,                /* old multi unit retail */
                                                 NULL,                /* old multi selling uom */
                                                 NULL,                /* status */
                                                 NULL,                /* taxable ind */
                                                 NULL,                /* launch date */
                                                 NULL,                /* qty key options */
                                                 NULL,                /* manual price entry */
                                                 NULL,                /* deposit code */
                                                 NULL,                /* food stamp ind */
                                                 NULL,                /* wic ind */
                                                 NULL,                /* proportional tare pct */
                                                 NULL,                /* fixed tare value */
                                                 NULL,                /* fixed tare uom */
                                                 NULL,                /* reward eligible ind */
                                                 NULL,                /* elect mtk clubs */
                                                 NULL,                /* return policy */
                                                 NULL) = FALSE then   /* stop sale ind */
                     return FALSE;
                  end if;
                  if NOT(L_pack_ind = 'Y' AND L_sellable_ind = 'N') then
                     if ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL(error_message,
                                                             L_std_unit_cost_prim,
                                                             L_std_unit_retail_prim,
                                                             L_std_uom_prim,
                                                             L_selling_unit_retail_prim,
                                                             L_selling_uom_prim,
                                                             c_rec.item) = FALSE then
                        return FALSE;
                     end if;
                     SQL_LIB.SET_MARK('INSERT',NULL,'PRICE_HIST',
                                      'ITEM: '||c_rec.item);
                     insert into price_hist(tran_type,
                                            reason,
                                            item,
                                            loc,
                                            unit_cost,
                                            unit_retail,
                                            selling_unit_retail,
                                            selling_uom,
                                            action_date)
                                     values(99,                         /* tran type */
                                            0,                          /* reason */
                                            c_rec.item,                 /* item */
                                            0,                          /* loc */
                                            L_std_unit_cost_prim,       /* unit cost */
                                            L_std_unit_retail_prim,     /* unit retail */
                                            L_selling_unit_retail_prim, /* selling unit retail */
                                            L_selling_uom_prim,         /* selling uom */
                                            TRUNC(to_date(to_char((L_vdate),'DDMMYY')||
                                            to_char(sysdate,'HH24MISS'),'DDMMYYHH24MISS')));
                     SQL_LIB.SET_MARK('INSERT',NULL,'PRICE_HIST',
                                      'ITEM: '||c_rec.item);
                     -- Item/Location record
                     insert into price_hist(tran_type,
                                            reason,
                                            item,
                                            loc,
                                            loc_type,
                                            unit_cost,
                                            unit_retail,
                                            selling_unit_retail,
                                            selling_uom,
                                            action_date)
                                           (select 99,
                                            0,
                                            c_rec.item,
                                            il.loc,
                                            il.loc_type,
                                            ils.unit_cost,
                                            il.unit_retail,
                                            il.selling_unit_retail,
                                            il.selling_uom,
                                            TRUNC(to_date(to_char(L_vdate,'DDMMYY')||to_char(sysdate,'HH24MISS'),'DDMMYYHH24MISS'))
                                       from item_loc il,
                                            item_loc_soh ils
                                      where il.item = c_rec.item
                                        and il.item = ils.item
                                        and il.loc  = ils.loc);
                  end if; /* end if NOT(L_pack_ind = 'Y' AND L_sellable_ind = 'N') */
            END LOOP; /*End of the FOR Loop */
         elsif L_item_level > L_tran_level then
               if POS_UPDATE_SQL.POS_MODS_INSERT(error_message,
                                                 22,                  /* tran type */
                                                 L_item_parent,       /* item */
                                                 L_item_desc,         /* item desc */
                                                 I_key_value,         /* ref item */
                                                 L_dept,              /* dept */
                                                 L_class,             /* class */
                                                 L_subclass,          /* subclass */
                                                 NULL,                /* store */
                                                 NULL,                /* new price */
                                                 NULL,                /* new selling uom */
                                                 NULL,                /* old price */
                                                 NULL,                /* old selling uom */
                                                 NULL,                /* start date */
                                                 NULL,                /* new multi units */
                                                 NULL,                /* old multi units */
                                                 NULL,                /* new multi unit retail */
                                                 NULL,                /* new multi selling uom */
                                                 NULL,                /* old multi unit retail */
                                                 NULL,                /* old multi selling uom */
                                                 NULL,                /* status */
                                                 NULL,                /* taxable ind */
                                                 NULL,                /* launch date */
                                                 NULL,                /* qty key options */
                                                 NULL,                /* manual price entry */
                                                 NULL,                /* deposit code */
                                                 NULL,                /* food stamp ind */
                                                 NULL,                /* wic ind */
                                                 NULL,                /* proportional tare pct */
                                                 NULL,                /* fixed tare value */
                                                 NULL,                /* fixed tare uom */
                                                 NULL,                /* reward eligible ind */
                                                 NULL,                /* elect mtk clubs */
                                                 NULL,                /* return policy */
                                                 NULL) = FALSE then   /* stop_sale_ind */
                  return FALSE;
               end if;
            elsif L_item_level = L_tran_level then
               if POS_UPDATE_SQL.POS_MODS_INSERT(error_message,
                                                 21,                  /* tran type */
                                                 I_key_value,         /* item */
                                                 L_item_desc,         /* item desc */
                                                 NULL,                /* ref item */
                                                 L_dept,              /* dept */
                                                 L_class,             /* class */
                                                 L_subclass,          /* subclass */
                                                 NULL,                /* store */
                                                 NULL,                /* new price */
                                                 NULL,                /* new selling uom */
                                                 NULL,                /* old price */
                                                 NULL,                /* old selling uom */
                                                 NULL,                /* start date */
                                                 NULL,                /* new multi units */
                                                 NULL,                /* old multi units */
                                                 NULL,                /* new multi unit retail */
                                                 NULL,                /* new multi selling uom */
                                                 NULL,                /* old multi unit retail */
                                                 NULL,                /* old multi selling uom */
                                                 NULL,                /* status */
                                                 NULL,                /* taxable ind */
                                                 NULL,                /* launch date */
                                                 NULL,                /* qty key options */
                                                 NULL,                /* manual price entry */
                                                 NULL,                /* deposit code */
                                                 NULL,                /* food stamp ind */
                                                 NULL,                /* wic ind */
                                                 NULL,                /* proportional tare pct */
                                                 NULL,                /* fixed tare value */
                                                 NULL,                /* fixed tare uom */
                                                 NULL,                /* reward eligible ind */
                                                 NULL,                /* elect mtk clubs */
                                                 NULL,                /* return policy */
                                                 NULL) = FALSE then   /* stop sale ind */
                  return FALSE;
               end if;
               if NOT(L_pack_ind = 'Y' AND L_sellable_ind = 'N') then
                  if ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL(error_message,
                                                          L_std_unit_cost_prim,
                                                          L_std_unit_retail_prim,
                                                          L_std_uom_prim,
                                                          L_selling_unit_retail_prim,
                                                          L_selling_uom_prim,
                                                          I_key_value) = FALSE then
                     return FALSE;
                  end if;
                  SQL_LIB.SET_MARK('INSERT',NULL,'PRICE_HIST',
                                   'ITEM: '||I_key_value);
                  insert into price_hist(tran_type,
                                         item,
                                         loc,
                                         unit_cost,
                                         unit_retail,
                                         selling_unit_retail,
                                         selling_uom,
                                         action_date)
                                   values(99,                         /* tran type */
                                          I_key_value,                /* item */
                                          0,                          /* loc */
                                          L_std_unit_cost_prim,       /* unit cost */
                                          L_std_unit_retail_prim,     /* unit retail */
                                          L_selling_unit_retail_prim, /* selling unit retail */
                                          L_selling_uom_prim,         /* selling uom */
                                          TRUNC(to_date(to_char((L_vdate),'DDMMYY')||
                                          to_char(sysdate,'HH24MISS'),'DDMMYYHH24MISS')));
                  SQL_LIB.SET_MARK('INSERT',NULL,'PRICE_HIST',
                                   'ITEM: '||I_key_value);
                  -- Item/Location record
                  insert into price_hist(tran_type,
                                         reason,
                                         item,
                                         loc,
                                         loc_type,
                                         unit_cost,
                                         unit_retail,
                                         selling_unit_retail,
                                         selling_uom,
                                         action_date)
                  (select 99,
                          0,
                          I_key_value,
                          il.loc,
                          il.loc_type,
                          ils.unit_cost,
                          il.unit_retail,
                          il.selling_unit_retail,
                          il.selling_uom,
                          TRUNC(to_date(to_char(L_vdate,'DDMMYY')||to_char(sysdate,'HH24MISS'),'DDMMYYHH24MISS'))
                     from item_loc il,
                          item_loc_soh ils
                    where il.item = I_key_value
                      and il.item = ils.item
                      and il.loc  = ils.loc);
               end if; /* end if NOT(L_pack_ind = 'Y' AND L_sellable_ind = 'N') */
            end if; /* end if L_item_level > L_tran_level */
         end if; /* end if L_status = 'A' */
      end if; /* end if I_cancel_item = FALSE */
      ---
      --07-Jan-2014,Banashankari,Banashankari.Ramachandra@in.tesco.com CR399 Begin
       --Lock the item from tsl_item_min_price  and delete the item
           LP_table := 'TSL_ITEM_MIN_PRICE';
            SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_TSL_ITEM_MIN_PRICE',
                          'TSL_ITEM_MIN_PRICE',
                          'ITEM:'||I_key_value);
          OPEN C_LOCK_TSL_ITEM_MIN_PRICE;
          SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_TSL_ITEM_MIN_PRICE',
                          'TSL_ITEM_MIN_PRICE',
                          'ITEM:'||I_key_value);
          CLOSE C_LOCK_TSL_ITEM_MIN_PRICE;
          SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_ITEM_MIN_PRICE',
                          'ITEM:'||I_key_value);
          DELETE FROM TSL_ITEM_MIN_PRICE
           WHERE item
              IN (SELECT item
                    FROM item_master
                WHERE (item_grandparent = I_key_value
                      OR  item_parent      = I_key_value
                      OR  item_master.item = I_key_value));
            --07-Jan-2014,Banashankari,Banashankari.Ramachandra@in.tesco.com CR399 End

      --N23 Changes Begin
          --Lock the item descriptions records and delete the item

          --Lock the tsl_itemdesc_till
          LP_table := 'TSL_ITEMDESC_TILL';
          SQL_LIB.SET_MARK('OPEN',
                          'C_TSL_ITEMDESC_TILL',
                          'TSL_ITEMDESC_TILL',
                          'ITEM:'||I_key_value);
          open C_TSL_ITEMDESC_TILL;
          SQL_LIB.SET_MARK('CLOSE',
                          'C_TSL_ITEMDESC_TILL',
                          'TSL_ITEMDESC_TILL',
                          'ITEM:'||I_key_value);
          close C_TSL_ITEMDESC_TILL;
          SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_ITEMDESC_TILL',
                          'ITEM:'||I_key_value);
          delete from tsl_itemdesc_till
           where item
              in (select item
                    from item_master
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                   where (item_grandparent = I_key_value
                      or  item_parent      = I_key_value
                      or  item_master.item = I_key_value));
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END

          --Lock the tsl_itemdesc_pack
          LP_table := 'TSL_ITEMDESC_PACK';
          SQL_LIB.SET_MARK('OPEN',
                          'C_TSL_ITEMDESC_PACK',
                          'TSL_ITEMDESC_PACK',
                          'ITEM:'||I_key_value);
          open C_TSL_ITEMDESC_PACK;
          SQL_LIB.SET_MARK('CLOSE',
                          'C_TSL_ITEMDESC_PACK',
                          'TSL_ITEMDESC_PACK',
                          'ITEM:'||I_key_value);
          close C_TSL_ITEMDESC_PACK;
          SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_ITEMDESC_PACK',
                          'ITEM:'||I_key_value);
          delete from tsl_itemdesc_pack
           where pack_no
              in (select item
                    from item_master
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                   where (item_grandparent = I_key_value
                      or  item_parent      = I_key_value
                      or  item_master.item = I_key_value));
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END

          --Lock the tsl_itemdesc_sel
          LP_table := 'TSL_ITEMDESC_SEL';
          SQL_LIB.SET_MARK('OPEN',
                          'C_TSL_ITEMDESC_SEL',
                          'TSL_ITEMDESC_SEL',
                          'ITEM:'||I_key_value);
          open C_TSL_ITEMDESC_SEL;
          SQL_LIB.SET_MARK('CLOSE',
                          'C_TSL_ITEMDESC_SEL',
                          'TSL_ITEMDESC_SEL',
                          'ITEM:'||I_key_value);
          close C_TSL_ITEMDESC_SEL;
          SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_ITEMDESC_SEL',
                          'ITEM:'||I_key_value);
          delete from tsl_itemdesc_sel
           where item
              in (select item
                    from item_master
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                   where (item_grandparent = I_key_value
                      or  item_parent      = I_key_value
                      or  item_master.item = I_key_value));
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END

          --Lock the tsl_itemdesc_base
          LP_table := 'TSL_ITEMDESC_BASE';
          SQL_LIB.SET_MARK('OPEN',
                          'C_TSL_ITEMDESC_BASE',
                          'TSL_ITEMDESC_BASE',
                          'ITEM:'||I_key_value);
          open C_TSL_ITEMDESC_BASE;
          SQL_LIB.SET_MARK('CLOSE',
                          'C_TSL_ITEMDESC_BASE',
                          'TSL_ITEMDESC_BASE',
                          'ITEM:'||I_key_value);
          close C_TSL_ITEMDESC_BASE;
          SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_ITEMDESC_BASE',
                          'ITEM:'||I_key_value);
          delete from tsl_itemdesc_base
           where item
              in (select item
                    from item_master
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                   where (item_grandparent = I_key_value
                      or  item_parent      = I_key_value
                      or  item_master.item = I_key_value));
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END

          --Lock the tsl_itemdesc_episel
          LP_table := 'TSL_ITEMDESC_EPISEL';
          SQL_LIB.SET_MARK('OPEN',
                          'C_TSL_ITEMDESC_EPISEL',
                          'TSL_ITEMDESC_EPISEL',
                          'ITEM:'||I_key_value);
          open C_TSL_ITEMDESC_EPISEL;
          SQL_LIB.SET_MARK('CLOSE',
                          'C_TSL_ITEMDESC_EPISEL',
                          'TSL_ITEMDESC_EPISEL',
                          'ITEM:'||I_key_value);
          close C_TSL_ITEMDESC_EPISEL;
          SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_ITEMDESC_EPISEL',
                          'ITEM:'||I_key_value);
          delete from tsl_itemdesc_episel
           where item
              in (select item
                    from item_master
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                   where (item_grandparent = I_key_value
                      or  item_parent      = I_key_value
                      or  item_master.item = I_key_value));
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END

          --Lock the tsl_itemdesc_iss
          LP_table := 'TSL_ITEMDESC_ISS';
          SQL_LIB.SET_MARK('OPEN',
                          'C_TSL_ITEMDESC_ISS',
                          'TSL_ITEMDESC_ISS',
                          'ITEM:'||I_key_value);
          open C_TSL_ITEMDESC_ISS;
          SQL_LIB.SET_MARK('CLOSE',
                          'C_TSL_ITEMDESC_ISS',
                          'TSL_ITEMDESC_ISS',
                          'ITEM:'||I_key_value);
          close C_TSL_ITEMDESC_ISS;
          SQL_LIB.SET_MARK('CLOSE',
                          NULL,
                          'TSL_ITEMDESC_ISS',
                          'ITEM:'||I_key_value);
          delete from tsl_itemdesc_iss
           where item
              in (select item
                    from item_master
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com BEGIN
                   where (item_grandparent = I_key_value
                      or  item_parent      = I_key_value
                      or  item_master.item = I_key_value));
                   -- CR135 15-May-2008 Wipro/Dhuraison Prince dhuraison.princepraveen@wipro.com END


          --N23 Chagnes End
      /* 04-Aug-2008 TESCO HSC/Murali   DEFNBS006793 Begin */
      --Delete data from tsl_item_range and tsl_prov_range tables.
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_TSL_ITEM_RANGE',
                       'TSL_ITEM_RANGE ',
                       'ITEM: '||I_key_value);
      open C_LOCK_TSL_ITEM_RANGE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_TSL_ITEM_RANGE',
                       'TSL_ITEM_RANGE ',
                       'ITEM: '||I_key_value);
      close C_LOCK_TSL_ITEM_RANGE;
      --
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'TSL_ITEM_RANGE ',
                       'ITEM: '||I_key_value);
      delete from tsl_item_range
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                  or item_master.item = I_key_value));

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_TSL_PROV_RANGE',
                       'TSL_PROV_RANGE ',
                       'ITEM: '||I_key_value);

      open C_LOCK_TSL_PROV_RANGE;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_TSL_PROV_RANGE',
                       'TSL_PROV_RANGE ',
                       'ITEM: '||I_key_value);
      close C_LOCK_TSL_PROV_RANGE;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'TSL_PROV_RANGE  ',
                       'ITEM: '||I_key_value);

      delete from tsl_prov_range
       where item
          in (select item
                from item_master
               where (item_parent = I_key_value
                  or item_master.item = I_key_value));

      /* 04-Aug-2008 TESCO HSC/Murali   DEFNBS006793 End */

      if L_tran_level >= L_item_level then
         if i_cancel_item = TRUE then
            LP_table := 'PRICE_HIST';
            open C_LOCK_PRICE_HIST;
            close C_LOCK_PRICE_HIST;
            SQL_LIB.SET_MARK('',NULL,'PRICE_HIST', 'Item: '||I_key_value);
            delete from price_hist
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
             ---
            LP_table := 'POS_MODS';
            open C_LOCK_POS_MODS;
            close C_LOCK_POS_MODS;
            SQL_LIB.SET_MARK('DELETE',NULL,'POS_MODS', 'Item: '||I_key_value);
            delete from pos_mods
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
         end if; /* end if i_cancel_item = TRUE */

         -- Mod N45 (Drop III), 03-Mar-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
         ---
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_TSL_DEAL_ORDER_HIST',
                          'TSL_DEAL_ORDER_HIST TDOH',
                          'ITEM: '||I_key_value);
         open C_LOCK_TSL_DEAL_ORDER_HIST;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_TSL_DEAL_ORDER_HIST',
                          'TSL_DEAL_ORDER_HIST',
                          'ITEM: '||I_key_value);
         close C_LOCK_TSL_DEAL_ORDER_HIST;
         --
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_DEAL_ORDER_HIST',
                          'ITEM: '||I_key_value);
         delete
           from tsl_deal_order_hist tdoh
          where tdoh.item = I_key_value;
         ---
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_TSL_DEAL_RECEIPT_HIST',
                          'TSL_DEAL_RECEIPT_HIST',
                          'ITEM: '||I_key_value);
         open C_LOCK_TSL_DEAL_RECEIPT_HIST;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_TSL_DEAL_RECEIPT_HIST',
                          'TSL_DEAL_RECEIPT_HIST',
                          'ITEM: '||I_key_value);
         close C_LOCK_TSL_DEAL_RECEIPT_HIST;
         --
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_DEAL_RECEIPT_HIST',
                          'ITEM: '||I_key_value);
         delete
           from tsl_deal_receipt_hist tdrh
          where tdrh.item = I_key_value;
         ---
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_TSL_DEAL_SALES_HIST',
                          'TSL_DEAL_SALES_HIST',
                          'ITEM: '||I_key_value);
         open C_LOCK_TSL_DEAL_SALES_HIST;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_TSL_DEAL_SALES_HIST',
                          'TSL_DEAL_SALES_HIST',
                          'ITEM: '||I_key_value);
         close C_LOCK_TSL_DEAL_SALES_HIST;
         --
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_DEAL_SALES_HIST',
                          'ITEM: '||I_key_value);
         delete
           from tsl_deal_sales_hist tdsh
          where tdsh.item = I_key_value;
         ---
         -- Mod N45 (Drop III), 03-Mar-2008, Nitin Gour, nitin.gour@in.tesco.com (END)

       ---SCB change  Removed the code
         LP_table := 'ITEM_ATTRIBUTES';
         open C_LOCK_ITEM_ATTRIBUTES;
         close C_LOCK_ITEM_ATTRIBUTES;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_ATTRIBUTES', 'Item: '||I_key_value);
         delete from item_attributes
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         if L_pack_ind = 'N' then
            LP_table := 'SUB_ITEMS_DETAIL';
            open C_LOCK_SUB_ITEMS_DTL;
            close C_LOCK_SUB_ITEMS_DTL;
            SQL_LIB.SET_MARK('DELETE',NULL,'SUB_ITEMS_DETAIL', 'ITEM, SUB_ITEM: '||I_key_value);
            delete from sub_items_detail
             where item = I_key_value
                or sub_item = I_key_value
                or exists (select item
                             from item_master
                            where (item_parent = I_key_value
                                   or item_grandparent = I_key_value)
                              and (item_master.item = sub_items_detail.item
                                   or item_master.item = sub_items_detail.sub_item));
            ---
            LP_table := 'SUB_ITEMS_HEAD';
            open C_LOCK_SUB_ITEMS_HEAD;
            close C_LOCK_SUB_ITEMS_HEAD;
            SQL_LIB.SET_MARK('DELETE',NULL,'SUB_ITEMS_HEAD', 'ITEM: '||I_key_value);
            delete from sub_items_head
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
         end if;
         ---
         LP_table := 'ITEM_LOC_TRAITS';
         open C_LOCK_ITEM_LOC_TRAITS;
         close C_LOCK_ITEM_LOC_TRAITS;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_LOC_TRAITS', 'Item: '||I_key_value);
         delete from item_loc_traits
           where item
              in (select item
                    from item_master
                   where (item_parent = I_key_value
                          or item_grandparent = I_key_value
                          or item_master.item = I_key_value));
         ---
         LP_table := 'ITEM_LOC_SOH';
          TBL_ROWID := TYP_ROWID();
         open C_LOCK_ITEM_LOC_SOH;
         fetch C_LOCK_ITEM_LOC_SOH bulk collect into TBL_ROWID;
         close C_LOCK_ITEM_LOC_SOH;
        if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_LOC_SOH', 'Item: '||i_key_value);
            FORALL i in TBL_ROWID.first..TBL_ROWID.last
               delete from item_loc_soh
                where rowid = TBL_ROWID(i);
         end if;
         ---
         LP_table := 'ITEM_LOC';
         TBL_ROWID := TYP_ROWID();
         open C_LOCK_ITEM_LOC;
         fetch C_LOCK_ITEM_LOC bulk collect into TBL_ROWID;
         close C_LOCK_ITEM_LOC;
         if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_LOC', 'Item: '||i_key_value);
            FORALL i in TBL_ROWID.first..TBL_ROWID.last
               delete from item_loc
                where rowid = TBL_ROWID(i);
         end if;
         ---
         LP_table := 'SOURCE_DLVRY_SCHED_EXC';
         open C_LOCK_SOURCE_DLVRY_SCHED_EXC;
         close C_LOCK_SOURCE_DLVRY_SCHED_EXC;
         SQL_LIB.SET_MARK('DELETE',NULL,'SOURCE_DLVRY_SCHED_EXC', 'Item: '||I_key_value);
         delete from source_dlvry_sched_exc
           where item
              in (select item
                    from item_master
                   where (item_parent = I_key_value
                          or item_grandparent = I_key_value
                          or item_master.item = I_key_value));
         ---
         LP_table := 'SKULIST_CRITERIA';
         open C_LOCK_SKULIST_CRITERIA;
         close C_LOCK_SKULIST_CRITERIA;
         SQL_LIB.SET_MARK('DELETE',NULL,'SKULIST_CRITERIA','ITEM: '||I_key_value);
         delete from skulist_criteria
          where item = I_key_value;
         --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, Begin
         --Removed the code from here where item_parent and item_grandparent is checked.
         --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, End
         ---
         LP_table := 'SKULIST_DETAIL';
         open C_LOCK_SKULIST_DETAIL;
         close C_LOCK_SKULIST_DETAIL;
         SQL_LIB.SET_MARK('DELETE',NULL,'SKULIST_DETAIL', 'ITEM:  '||I_key_value);
         delete from skulist_detail
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'VAT_ITEM';
         open C_LOCK_VAT_ITEM;
         close C_LOCK_VAT_ITEM;
         SQL_LIB.SET_MARK('DELETE',NULL,'VAT_ITEM', 'ITEM:  '||I_key_value);
         delete from vat_item
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'INV_STATUS_QTY';
         open C_LOCK_INV_STATUS_QTY;
         close C_LOCK_INV_STATUS_QTY;
         SQL_LIB.SET_MARK('DELETE',NULL,'INV_STATUS_QTY', 'ITEM:  '||I_key_value);
         delete from inv_status_qty
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'REQ_DOC';
         open C_LOCK_REQ_DOC;
         close C_LOCK_REQ_DOC;
         SQL_LIB.SET_MARK('DELETE',NULL,'REQ_DOC', 'KEY VALUE 1: '||I_key_value);
         delete from req_doc
          where module = 'IT'
            and (key_value_2 = I_key_value
                 or exists (select item
                              from item_master
                             where (item_parent = I_key_value
                                    or item_grandparent = I_key_value)
                               and item_master.item = req_doc.key_value_2));
         ---
         LP_table := 'TIMELINE';
         open C_LOCK_TIMELINE;
         close C_LOCK_TIMELINE;
         SQL_LIB.SET_MARK('DELETE',NULL,'TIMELINE', 'KEY VALUE 1: '||I_key_value);
         delete from timeline
          where timeline_type = 'IT'
            and exists (select item
                              from item_master
                             where (item = I_key_value
                                    or item_parent = I_key_value
                                    or item_grandparent = I_key_value)
                               and( item_master.item = timeline.key_value_1
                                    or item_master.item = timeline.key_value_2));
         ---
         LP_table := 'ITEM_IMAGE';
         open C_LOCK_ITEM_IMAGE;
         close C_LOCK_ITEM_IMAGE;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_IMAGE', 'ITEM: '||I_key_value);
         delete from item_image
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'ITEM_SUPP_UOM';
         open C_LOCK_ITEM_SUPP_UOM;
         close C_LOCK_ITEM_SUPP_UOM;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_UOM', 'ITEM: '||I_key_value);
         delete from item_supp_uom
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'DEAL_SKU_TEMP';
         open C_LOCK_DEAL_SKU_TEMP;
         close C_LOCK_DEAL_SKU_TEMP;
         SQL_LIB.SET_MARK('DELETE',NULL,'DEAL_SKU_TEMP', 'ITEM: '||I_key_value);
         delete from deal_sku_temp
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, Begin
         --Future Cost table is checked only for TPND
         if (L_item_level = 1 and L_tran_level = 1) then
         --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, End
         LP_table := 'FUTURE_COST';
         open C_LOCK_FUTURE_COST;
         close C_LOCK_FUTURE_COST;
         SQL_LIB.SET_MARK('DELETE',NULL,'FUTURE_COST', 'ITEM: '||I_key_value);
         delete from future_cost
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, Begin
         end if ;
         --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, End
         ---
         LP_table := 'DEAL_ITEMLOC';
         open C_LOCK_DEAL_ITEMLOC;
         close C_LOCK_DEAL_ITEMLOC;
         SQL_LIB.SET_MARK('DELETE',NULL,'DEAL_ITEMLOC', 'ITEM: '||I_key_value);
         delete from deal_itemloc
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'DEAL_DETAIL';
         open C_LOCK_DEAL_DETAIL;
         close C_LOCK_DEAL_DETAIL;
         SQL_LIB.SET_MARK('DELETE',NULL,'DEAL_DETAIL', 'ITEM: '||I_key_value);
         delete from deal_detail
          where (qty_thresh_buy_item = I_key_value
             or exists (select item
                          from item_master
                         where (item_parent = I_key_value
                            or item_grandparent = I_key_value)
                           and item_master.item = deal_detail.qty_thresh_buy_item))
             or (qty_thresh_get_item = I_key_value
             or exists (select item
                          from item_master
                         where (item_parent = I_key_value
                            or item_grandparent = I_key_value)
                           and item_master.item = deal_detail.qty_thresh_get_item));
         ---
         LP_table := 'RECLASS_ITEM';
         open C_LOCK_RECLASS_ITEM;
         close C_LOCK_RECLASS_ITEM;
         SQL_LIB.SET_MARK('DELETE',NULL,'RECLASS_ITEM', 'ITEM: '||I_key_value);
         delete from reclass_item
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'UDA_ITEM_LOV';
         open C_LOCK_UDA_ITEM_LOV;
         close C_LOCK_UDA_ITEM_LOV;
         SQL_LIB.SET_MARK('DELETE',NULL,'UDA_ITEM_LOV', 'ITEM: '||I_key_value);
         delete from uda_item_lov
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'UDA_ITEM_DATE';
         open C_LOCK_UDA_ITEM_DATE;
         close C_LOCK_UDA_ITEM_DATE;
         SQL_LIB.SET_MARK('DELETE',NULL,'UDA_ITEM_DATE', 'ITEM: '||I_key_value);
         delete from uda_item_date
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'UDA_ITEM_FF';
         open C_LOCK_UDA_ITEM_FF;
         close C_LOCK_UDA_ITEM_FF;
         SQL_LIB.SET_MARK('DELETE',NULL,'UDA_ITEM_FF', 'ITEM: '||I_key_value);
         delete from uda_item_ff
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'ITEM_SEASONS';
         open C_LOCK_ITEM_SEASONS;
         close C_LOCK_ITEM_SEASONS;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SEASONS', 'ITEM: '||I_key_value);
         delete from item_seasons
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'ITEM_TICKET';
         open C_LOCK_ITEM_TICKET;
         close C_LOCK_ITEM_TICKET;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_TICKET', 'ITEM: '||I_key_value);
         delete from item_ticket
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'PRODUCT_TAX_CODE';
         open C_LOCK_TAXCODE_ITEM;
         close C_LOCK_TAXCODE_ITEM;
         SQL_LIB.SET_MARK('DELETE',NULL,'PRODUCT_TAX_CODE','ITEM: '||I_key_value);
         delete from product_tax_code
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'DAILY_PURGE';
         open C_LOCK_DAILY_PURGE;
         close C_LOCK_DAILY_PURGE;
         SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_PURGE', 'KEY_VALUE: '||I_key_value);
         delete from daily_purge
          where (key_value = I_key_value
                 or exists (select item
                              from item_master
                             where (item_parent = I_key_value
                                    or item_grandparent = I_key_value)
                               and item_master.item = daily_purge.key_value))
            and table_name = 'ITEM_MASTER';
         ---
         LP_table := 'COMP_SHOP_LIST';
         open C_LOCK_COMP_SHOP_LIST;
         close C_LOCK_COMP_SHOP_LIST;
         SQL_LIB.SET_MARK('DELETE',NULL,'COMP_SHOP_LIST', 'ITEM: '||I_key_value);
         delete from comp_shop_list
          where item = I_key_value
             or ref_item = I_key_value
             or exists (select item
                          from item_master
                         where (item_parent = I_key_value
                                or item_grandparent = I_key_value)
                           and (item_master.item = comp_shop_list.item
                                or item_master.item = comp_shop_list.ref_item));
          ---
         ---
         LP_table := 'ITEM_APPROVAL_ERROR';
         open C_LOCK_ITEM_APPROVAL_ERROR;
         close C_LOCK_ITEM_APPROVAL_ERROR;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_APPROVAL_ERROR', 'ITEM: '||I_key_value);
         delete from item_approval_error
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'TICKET_REQUEST';
         open C_LOCK_TICKET_REQUEST;
         close C_LOCK_TICKET_REQUEST;
         SQL_LIB.SET_MARK('DELETE',NULL,'TICKET_REQUEST', 'ITEM: '||I_key_value);
         delete from ticket_request
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'POS_MERCH_CRITERIA';
         open C_LOCK_POS_MERCH_CRITERIA;
         close C_LOCK_POS_MERCH_CRITERIA;
         SQL_LIB.SET_MARK('DELETE',NULL,'POS_MERCH_CRITERIA', 'ITEM: '||I_key_value);
         delete from pos_merch_criteria
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'POS_CONFIG_ITEMS';
         open C_LOCK_POS_CONFIG_ITEMS;
         fetch C_LOCK_POS_CONFIG_ITEMS into L_dummy;
         if C_LOCK_POS_CONFIG_ITEMS%FOUND then
            SQL_LIB.SET_MARK('UPDATE',NULL,'POS_CONFIG_ITEMS', 'ITEM: '||i_key_value);
            update pos_config_items pci
               set status = 'D'
             where item
                in (select item
                      from item_master
                     where ((item_parent = i_key_value
                            and item_parent is not null)
                        or (item_grandparent = i_key_value
                            and item_grandparent is not null)
                        or item_master.item = i_key_value));

            for c1 in C_GET_CONFIG loop
               L_config_type := c1.pos_config_type;
               L_config_id   := c1.pos_config_id;
               L_num_items   := 0;
               open C_GET_TOTAL_ITEMS;
               fetch C_GET_TOTAL_ITEMS into L_num_items;
               if L_num_items = 1 then
                  open C_LOCK_POS_STORE;
                  close C_LOCK_POS_STORE;
                  SQL_LIB.SET_MARK('UPDATE',NULL,'POS_STORE', 'POS_CONFIG_ID: '||L_config_id);
                  update pos_store
                     set status = 'D'
                   where pos_config_id = L_config_id
                     and pos_config_type = L_config_type;

                  if (L_config_type = 'PRES') then
                     open C_LOCK_POS_PROD_REST_HEAD;
                     close C_LOCK_POS_PROD_REST_HEAD;
                     SQL_LIB.SET_MARK('UPDATE',NULL,'POS_PROD_REST_HEAD', 'POS_PROD_REST_ID: '||L_config_id);
                     update pos_prod_rest_head
                        set pos_config_status = 'D',
                            extract_req_ind = 'Y'
                      where pos_prod_rest_id = L_config_id;
                  end if;
                  if (L_config_type = 'COUP') then
                     open C_LOCK_POS_COUPON_HEAD;
                     close C_LOCK_POS_COUPON_HEAD;
                     SQL_LIB.SET_MARK('UPDATE',NULL,'POS_COUPON_HEAD', 'COUPON_ID: '||L_config_id);
                     update pos_coupon_head
                        set pos_config_status = 'D',
                            extract_req_ind = 'Y'
                      where coupon_id = L_config_id;
                  end if;
               end if;
               close C_GET_TOTAL_ITEMS;
            end loop;
         end if;
         close C_LOCK_POS_CONFIG_ITEMS;
         ---
         LP_table := 'ITEM_CHRG_DETAIL';
         open C_LOCK_ITEM_CHRG_DETAIL;
         close C_LOCK_ITEM_CHRG_DETAIL;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_DETAIL', 'ITEM: '||I_key_value);
         delete from item_chrg_detail
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'ITEM_CHRG_HEAD';
         open C_LOCK_ITEM_CHRG_HEAD;
         close C_LOCK_ITEM_CHRG_HEAD;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_CHRG_HEAD', 'ITEM: '||I_key_value);
         delete from item_chrg_head
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         if L_pack_ind = 'N' then
         ---
            LP_table := 'EDI_DAILY_SALES';
            open C_LOCK_EDI_DAILY_SALES;
            close C_LOCK_EDI_DAILY_SALES;
            SQL_LIB.SET_MARK('DELETE', NULL, 'EDI_DAILY_SALES', 'ITEM: '||I_key_value);
            delete from edi_daily_sales
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            LP_table := 'REPL_ATTR_UPDATE_EXCLUDE';
            open C_LOCK_REPL_ATTR_UPD_EXCLUDE;
            close C_LOCK_REPL_ATTR_UPD_EXCLUDE;
            SQL_LIB.SET_MARK('DELETE',NULL,'REPL_ATTR_UPD_EXCLUDE', 'ITEM: '||I_key_value);
            delete from repl_attr_update_exclude
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            LP_table := 'REPL_ATTR_UPDATE_LOC';
            open C_LOCK_REPL_ATTR_UPDATE_LOC;
            close C_LOCK_REPL_ATTR_UPDATE_LOC;
            SQL_LIB.SET_MARK('DELETE',NULL,'C_LOCK_REPL_ATTR_UPDATE_LOC', 'ITEM: '||I_key_value);
            delete from repl_attr_update_loc
             where repl_attr_id
                in (select repl_attr_id
                     from repl_attr_update_item
                    where item
                       in (select item
                             from item_master
                            where (item_parent = I_key_value
                               or item_grandparent = I_key_value
                               or item_master.item = I_key_value)));
                ---
                open  C_GET_REPL_ATTR_ID;
                        fetch C_GET_REPL_ATTR_ID into L_repl_attr_id;
                        close C_GET_REPL_ATTR_ID;
            LP_table := 'REPL_ATTR_UPDATE_ITEM';
            open C_LOCK_REPL_ATTR;
            close C_LOCK_REPL_ATTR;
            SQL_LIB.SET_MARK('DELETE',NULL,'REPL_ATTR_UPDATE_ITEM', 'ITEM: '||I_key_value);
            delete from repl_attr_update_item
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
         ---
            LP_table := 'REPL_ATTR_UPDATE_HEAD';
            open C_LOCK_REPL_ATTR_UPDATE_HEAD;
            close C_LOCK_REPL_ATTR_UPDATE_HEAD;
            SQL_LIB.SET_MARK('DELETE',NULL,'REPL_ATTR_UPDATE_HEAD', 'ITEM: '||I_key_value);
            delete from repl_attr_update_head
             where repl_attr_id = L_repl_attr_id;
            LP_table := 'MASTER_REPL_ATTR';
            open C_LOCK_MASTER_REPL_ATTR;
            close C_LOCK_MASTER_REPL_ATTR;
            SQL_LIB.SET_MARK('DELETE',NULL,'MASTER_REPL_ATTR', 'ITEM: '||I_key_value);
            delete from master_repl_attr
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
           ---
            LP_table := 'REPL_DAY';
            open C_LOCK_REPL_DAY;
            close C_LOCK_REPL_DAY;
            SQL_LIB.SET_MARK('DELETE',NULL,'REPL_DAY', 'ITEM: '||I_key_value);
            delete from repl_day
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
         ---
            LP_table := 'REPL_ITEM_LOC_UPDATES';
            open C_LOCK_REPL_ITEM_LOC_UPDATES;
            close C_LOCK_REPL_ITEM_LOC_UPDATES;
            SQL_LIB.SET_MARK('DELETE',NULL,'REPL_ITEM_LOC_UPDATES', 'ITEM: '||I_key_value);
            delete from repl_item_loc_updates
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
         ---
            if I_cancel_item = FALSE then
               SQL_LIB.SET_MARK('INSERT',NULL,'REPL_ITEM_LOC_UPDATES',
                                'ITEM: '||I_key_value);
               insert into repl_item_loc_updates(item,
                                                 location,
                                                 loc_type,
                                                 change_type)
                      select item,
                             location,
                             loc_type,
                             'RILD'
                        from repl_item_loc
                       where item
                          in (select item
                                from item_master
                               where (item_parent = I_key_value
                                      or item_grandparent = I_key_value
                                      or item_master.item = I_key_value));
         ---
            end if;
            LP_table := 'REPL_ITEM_LOC';
            open C_LOCK_REPL_ITEM_LOC;
            close C_LOCK_REPL_ITEM_LOC;
            SQL_LIB.SET_MARK('DELETE',NULL,'REPL_ITEM_LOC', 'ITEM: '||I_key_value);
            delete from repl_item_loc
                  where item
                     in (select item
                           from item_master
                          where (item_parent = I_key_value
                                 or item_grandparent = I_key_value
                                 or item_master.item = I_key_value));
         ---
            ---
            LP_table := 'SUP_AVAIL';
            open C_LOCK_SUP_AVAIL;
            close C_LOCK_SUP_AVAIL;
            SQL_LIB.SET_MARK('DELETE',NULL,'SUP_AVAIL', 'ITEM: '||I_key_value);
            delete from sup_avail
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
            LP_table := 'REPL_RESULTS';
            open C_LOCK_REPL_RESULTS;
            close C_LOCK_REPL_RESULTS;
            SQL_LIB.SET_MARK('DELETE',NULL,'REPL_RESULTS', 'ITEM: '||I_key_value);
            delete from repl_results
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
         end if; /* end if L_pack_ind = 'N' */
         if L_pack_ind = 'Y' then
            LP_table := 'PACKITEM_BREAKOUT';
            TBL_ROWID := TYP_ROWID();
      open C_LOCK_PACKITEM_BREAKOUT;
            fetch C_LOCK_PACKITEM_BREAKOUT bulk collect into TBL_ROWID;
            close C_LOCK_PACKITEM_BREAKOUT;
            if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
               SQL_LIB.SET_MARK('DELETE',NULL,'PACKITEM_BREAKOUT', 'ITEM: '||i_key_value);
                  FORALL i in TBL_ROWID.first..TBL_ROWID.last
                     delete from packitem_breakout
                      where rowid = TBL_ROWID(i);
            end if;
            ---
            LP_table := 'PACKITEM';
            TBL_ROWID := TYP_ROWID();
            open C_LOCK_PACKITEM;
            fetch C_LOCK_PACKITEM bulk collect into TBL_ROWID;
            close C_LOCK_PACKITEM;
            if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
               SQL_LIB.SET_MARK('DELETE', NULL, 'PACKITEM', 'ITEM: '||i_key_value);
                  FORALL i in TBL_ROWID.first..TBL_ROWID.last
                     delete from packitem
                     where rowid = TBL_ROWID(i);
            end if;
            ---
            if L_orderable_ind = 'Y' then
               LP_table := 'COST_SUSP_SUP_DETAIL_LOC';
               open C_LOCK_COST_SS_DTL_LOC;
               close C_LOCK_COST_SS_DTL_LOC;
               SQL_LIB.SET_MARK('DELETE',NULL,'COST_SUSP_SUP_DETAIL_LOC', 'ITEM: '||I_key_value);
               delete from cost_susp_sup_detail_loc
                where item
                   in (select item
                         from item_master
                        where (item_parent = I_key_value
                               or item_grandparent = I_key_value
                               or item_master.item = I_key_value));
               ---
               LP_table := 'COST_SUSP_SUP_DETAIL';
               open C_LOCK_COST_SS_DTL;
               close C_LOCK_COST_SS_DTL;
               SQL_LIB.SET_MARK('DELETE',NULL,'COST_SUSP_SUP_DETAIL', 'ITEM: '||I_key_value);
               delete from cost_susp_sup_detail
                where item
                   in (select item
                         from item_master
                        where (item_parent = I_key_value
                               or item_grandparent = I_key_value
                               or item_master.item = I_key_value));
               ---
               LP_table := 'ITEM_SUPP_COUNTRY_BRACKET_COST';
               open C_LOCK_ITM_SUP_CTRY_BRACK_COST;
               close C_LOCK_ITM_SUP_CTRY_BRACK_COST;
               SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST', 'ITEM: '||I_key_value);
               delete from item_supp_country_bracket_cost
                where item
                   in (select item
                         from item_master
                        where (item_parent = I_key_value
                               or item_grandparent = I_key_value
                               or item_master.item = I_key_value));
               ---
               LP_table := 'EDI_COST_LOC';
               open C_LOCK_EDI_COST_LOC;
               close C_LOCK_EDI_COST_LOC;
               SQL_LIB.SET_MARK('DELETE',NULL,'EDI_COST_LOC', 'ITEM: '||I_key_value);
               delete from edi_cost_loc
                where item
                   in (select item
                         from item_master
                        where (item_parent = I_key_value
                               or item_grandparent = I_key_value
                               or item_master.item = I_key_value));
               ---
               LP_table := 'EDI_COST_CHG';
               open C_LOCK_EDI_COST_CHG;
               close C_LOCK_EDI_COST_CHG;
               SQL_LIB.SET_MARK('DELETE',NULL,'EDI_COST_CHG', 'ITEM: '||I_key_value);
               delete from edi_cost_chg
                where item
                   in (select item
                         from item_master
                        where (item_parent = I_key_value
                               or item_grandparent = I_key_value
                               or item_master.item = I_key_value));
               ---
               if L_elc_ind = 'Y' then
                  --DefNBS011401 09-Feb-09 Chandru Begin
                  LP_table  := 'TSL_EXP_QUEUE';
                  open C_LOCK_TSL_EXP_QUEUE;
                  close C_LOCK_TSL_EXP_QUEUE;
                  SQL_LIB.SET_MARK('DELETE',NULL,'TSL_EXP_QUEUE', 'ITEM: '||I_key_value);
                  delete from tsl_exp_queue
                   where item
                      in (select item
                            from item_master
                           where (item_parent = I_key_value
                                  or item_grandparent = I_key_value
                                  or item_master.item = I_key_value));
                  ---
                  LP_table  := 'TSL_ITEM_EXP_DETAIL';
                  open C_LOCK_TSL_ITEM_EXP_DETAIL;
                  close C_LOCK_TSL_ITEM_EXP_DETAIL;
                  SQL_LIB.SET_MARK('DELETE',NULL,'TSL_ITEM_EXP_DETAIL', 'ITEM: '||I_key_value);
                  delete from tsl_item_exp_detail
                   where item
                      in (select item
                            from item_master
                           where (item_parent = I_key_value
                                  or item_grandparent = I_key_value
                                  or item_master.item = I_key_value));
                  ---
                  LP_table  := 'TSL_ITEM_EXP_HEAD';
                  open C_LOCK_TSL_ITEM_EXP_HEAD;
                  close C_LOCK_TSL_ITEM_EXP_HEAD;
                  SQL_LIB.SET_MARK('DELETE',NULL,'TSL_ITEM_EXP_HEAD', 'ITEM: '||I_key_value);
                  delete from tsl_item_exp_head
                   where item
                      in (select item
                            from item_master
                           where (item_parent = I_key_value
                                  or item_grandparent = I_key_value
                                  or item_master.item = I_key_value));
                  ---
                  --DefNBS011401 09-Feb-09 Chandru End
                  LP_table  := 'ITEM_EXP_DETAIL';
                  open C_LOCK_ITEM_EXP_DETAIL;
                  close C_LOCK_ITEM_EXP_DETAIL;
                  SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_EXP_DETAIL', 'ITEM: '||I_key_value);
                  delete from item_exp_detail
                   where item
                      in (select item
                            from item_master
                           where (item_parent = I_key_value
                                  or item_grandparent = I_key_value
                                  or item_master.item = I_key_value));
                  ---
                  LP_table  := 'ITEM_EXP_HEAD';
                  open C_LOCK_ITEM_EXP_HEAD;
                  close C_LOCK_ITEM_EXP_HEAD;
                  SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_EXP_HEAD', 'ITEM: '||I_key_value);
                  delete from item_exp_head
                   where item
                      in (select item
                            from item_master
                           where (item_parent = I_key_value
                                  or item_grandparent = I_key_value
                                  or item_master.item = I_key_value));
                  ---
                  LP_table  := 'ITEM_HTS_ASSESS';
                  open C_LOCK_ITEM_HTS_ASSESS;
                  close C_LOCK_ITEM_HTS_ASSESS;
                  SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_HTS_ASSESS', 'ITEM: '||I_key_value);
                  delete from item_hts_assess
                   where item
                      in (select item
                            from item_master
                           where (item_parent = I_key_value
                                  or item_grandparent = I_key_value
                                  or item_master.item = I_key_value));
                  ---
                  LP_table  := 'ITEM_HTS';
                  open C_LOCK_ITEM_HTS;
                  close C_LOCK_ITEM_HTS;
                  SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_HTS', 'ITEM: '||I_key_value);
                  delete from item_hts
                   where item
                      in (select item
                            from item_master
                           where (item_parent = I_key_value
                                  or item_grandparent = I_key_value
                                  or item_master.item = I_key_value));
                  ---
                  LP_table  := 'COND_TARIFF_TREATMENT';
                  open C_LOCK_COND_TARIFF_TREATMENT;
                  close C_LOCK_COND_TARIFF_TREATMENT;
                  SQL_LIB.SET_MARK('DELETE',NULL,'COND_TARIFF_TREATMENT', 'ITEM: '||I_key_value);
                  delete from cond_tariff_treatment
                   where item
                      in (select item
                            from item_master
                           where (item_parent = I_key_value
                                  or item_grandparent = I_key_value
                                  or item_master.item = I_key_value));
                  ---
               end if; /* end if L_elc_ind = 'Y' */
               LP_table := 'ITEM_SUPP_COUNTRY_LOC';
               TBL_ROWID := TYP_ROWID();
                 open C_LOCK_ITEM_SUPP_COUNTRY_LOC;
               fetch C_LOCK_ITEM_SUPP_COUNTRY_LOC bulk collect into TBL_ROWID;
               close C_LOCK_ITEM_SUPP_COUNTRY_LOC;
               if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
                  SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_LOC', 'ITEM: '||i_key_value);
                  FORALL i in TBL_ROWID.first..TBL_ROWID.last
                     delete from item_supp_country_loc
                       where rowid = TBL_ROWID(i);
               end if;
               ---
               LP_table := 'ITEM_SUPP_COUNTRY_DIM';
               open C_LOCK_ITEM_SUPP_COUNTRY_DIM;
               close C_LOCK_ITEM_SUPP_COUNTRY_DIM;
               SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_DIM', 'ITEM: '||I_key_value);
               delete from item_supp_country_dim
                where item
                   in (select item
                         from item_master
                        where (item_parent = I_key_value
                               or item_grandparent = I_key_value
                               or item_master.item = I_key_value));
               ---
               LP_table := 'ITEM_SUPP_COUNTRY';
               open C_LOCK_ITEM_SUPP_COUNTRY;
               close C_LOCK_ITEM_SUPP_COUNTRY;
               SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY', 'ITEM: '||I_key_value);
               delete from item_supp_country
                where item
                   in (select item
                         from item_master
                        where (item_parent = I_key_value
                               or item_grandparent = I_key_value
                               or item_master.item = I_key_value));
               ---
               LP_table := 'ITEM_SUPPLIER';
               TBL_ROWID := TYP_ROWID();
                 open C_LOCK_ITEM_SUPPLIER;
               fetch C_LOCK_ITEM_SUPPLIER bulk collect into TBL_ROWID;
               close C_LOCK_ITEM_SUPPLIER;
               if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
                  SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPPLIER', 'ITEM: '||i_key_value);
                  FORALL i in TBL_ROWID.first..TBL_ROWID.last
                     delete from item_supplier
                       where rowid = TBL_ROWID(i);
               end if;
               ---
               ---
            end if; /* end if L_orderable_ind = 'Y' */
            if L_pack_tmpl_del_ind = 'Y' then
               LP_table := 'PACK_TMPL_DETAIL';
               open C_LOCK_PACK_TMPL_DETAIL;
               close C_LOCK_PACK_TMPL_DETAIL;
               SQL_LIB.SET_MARK('DELETE', NULL, 'PACK_TMPL_DETAIL', 'PACK TMPL ID: '||L_pack_tmpl_id);
               delete from pack_tmpl_detail
                where pack_tmpl_id = L_pack_tmpl_id;
               ---
               LP_table := 'SUPS_PACK_TMPL_DESC';
               open C_LOCK_SUPS_PACK_TMPL_DESC;
               close C_LOCK_SUPS_PACK_TMPL_DESC;
               SQL_LIB.SET_MARK('DELETE', NULL, 'SUPS_PACK_TMPL_DESC', 'PACK TMPL ID: '||L_pack_tmpl_id);
               delete from sups_pack_tmpl_desc
                where pack_tmpl_id = L_pack_tmpl_id;
               ---
               LP_table := 'PACK_TMPL_HEAD';
               open C_LOCK_PACK_TMPL_HEAD;
               close C_LOCK_PACK_TMPL_HEAD;
               SQL_LIB.SET_MARK('DELETE', NULL, 'PACK_TMPL_HEAD', 'PACK TMPL ID: '||L_pack_tmpl_id);
               delete from pack_tmpl_head
                where pack_tmpl_id = L_pack_tmpl_id;
               ---
            end if;
         elsif L_pack_ind = 'N' then
            --DefNBS011401 09-Feb-09 Chandru Begin
            LP_table  := 'TSL_EXP_QUEUE';
            open C_LOCK_TSL_EXP_QUEUE;
            close C_LOCK_TSL_EXP_QUEUE;
            SQL_LIB.SET_MARK('DELETE',NULL,'TSL_EXP_QUEUE', 'ITEM: '||I_key_value);
            delete from tsl_exp_queue
                  where item
                     in (select item
                           from item_master
                           where (item_parent = I_key_value
                                  or item_grandparent = I_key_value
                                  or item_master.item = I_key_value));
            ---
            LP_table  := 'TSL_ITEM_EXP_DETAIL';
            open C_LOCK_TSL_ITEM_EXP_DETAIL;
            close C_LOCK_TSL_ITEM_EXP_DETAIL;
            SQL_LIB.SET_MARK('DELETE',NULL,'TSL_ITEM_EXP_DETAIL', 'ITEM: '||I_key_value);
            delete from tsl_item_exp_detail
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
            LP_table  := 'TSL_ITEM_EXP_HEAD';
            open C_LOCK_TSL_ITEM_EXP_HEAD;
            close C_LOCK_TSL_ITEM_EXP_HEAD;
            SQL_LIB.SET_MARK('DELETE',NULL,'TSL_ITEM_EXP_HEAD', 'ITEM: '||I_key_value);
            delete from tsl_item_exp_head
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                           or item_grandparent = I_key_value
                           or item_master.item = I_key_value));
            ---
            --DefNBS011401 09-Feb-09 Chandru End
            LP_table  := 'ITEM_EXP_DETAIL';
            open C_LOCK_ITEM_EXP_DETAIL;
            close C_LOCK_ITEM_EXP_DETAIL;
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_EXP_DETAIL', 'ITEM: '||I_key_value);
            delete from item_exp_detail
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
            LP_table  := 'ITEM_EXP_HEAD';
            open C_LOCK_ITEM_EXP_HEAD;
            close C_LOCK_ITEM_EXP_HEAD;
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_EXP_HEAD', 'ITEM: '||I_key_value);
            delete from item_exp_head
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
            LP_table  := 'ITEM_HTS_ASSESS';
            open C_LOCK_ITEM_HTS_ASSESS;
            close C_LOCK_ITEM_HTS_ASSESS;
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_HTS_ASSESS', 'ITEM: '||I_key_value);
            delete from item_hts_assess
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
            LP_table  := 'ITEM_HTS';
            open C_LOCK_ITEM_HTS;
            close C_LOCK_ITEM_HTS;
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_HTS', 'ITEM: '||I_key_value);
            delete from item_hts
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
            LP_table  := 'COND_TARIFF_TREATMENT';
            open C_LOCK_COND_TARIFF_TREATMENT;
            close C_LOCK_COND_TARIFF_TREATMENT;
            SQL_LIB.SET_MARK('DELETE',NULL,'COND_TARIFF_TREATMENT', 'ITEM: '||I_key_value);
            delete from cond_tariff_treatment
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
         end if; /* end if L_pack_ind = 'Y' */
         if L_pack_ind = 'N' then
            ---
            LP_table := 'COST_SUSP_SUP_DETAIL_LOC';
            open C_LOCK_COST_SS_DTL_LOC;
            close C_LOCK_COST_SS_DTL_LOC;
            SQL_LIB.SET_MARK('DELETE',NULL,'COST_SUSP_SUP_DETAIL_LOC', 'ITEM: '||I_key_value);
            delete from cost_susp_sup_detail_loc
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                           or item_grandparent = I_key_value
                           or item_master.item = I_key_value));
            ---
            LP_table := 'COST_SUSP_SUP_DETAIL';
            open C_LOCK_COST_SS_DTL;
            close C_LOCK_COST_SS_DTL;
            SQL_LIB.SET_MARK('DELETE',NULL,'COST_SUSP_SUP_DETAIL', 'ITEM: '||I_key_value);
            delete from cost_susp_sup_detail
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
            LP_table := 'ITEM_SUPP_COUNTRY_BRACKET_COST';
            open C_LOCK_ITM_SUP_CTRY_BRACK_COST;
            close C_LOCK_ITM_SUP_CTRY_BRACK_COST;
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST', 'ITEM: '||I_key_value);
            delete from item_supp_country_bracket_cost
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
               LP_table := 'ITEM_SUPP_COUNTRY_LOC';
               TBL_ROWID := TYP_ROWID();
                 open C_LOCK_ITEM_SUPP_COUNTRY_LOC;
               fetch C_LOCK_ITEM_SUPP_COUNTRY_LOC bulk collect into TBL_ROWID;
               close C_LOCK_ITEM_SUPP_COUNTRY_LOC;
               if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
                  SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_LOC', 'ITEM: '||i_key_value);
                  FORALL i in TBL_ROWID.first..TBL_ROWID.last
                     delete from item_supp_country_loc
                       where rowid = TBL_ROWID(i);
               end if;
             ---
            LP_table := 'ITEM_SUPP_COUNTRY_DIM';
            open C_LOCK_ITEM_SUPP_COUNTRY_DIM;
            close C_LOCK_ITEM_SUPP_COUNTRY_DIM;
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_DIM', 'ITEM: '||I_key_value);
            delete from item_supp_country_dim
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
            LP_table := 'ITEM_SUPP_COUNTRY';
            open C_LOCK_ITEM_SUPP_COUNTRY;
            close C_LOCK_ITEM_SUPP_COUNTRY;
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY', 'ITEM: '||I_key_value);
            delete from item_supp_country
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
               LP_table := 'ITEM_SUPPLIER';
               TBL_ROWID := TYP_ROWID();
                 open C_LOCK_ITEM_SUPPLIER;
               fetch C_LOCK_ITEM_SUPPLIER bulk collect into TBL_ROWID;
               close C_LOCK_ITEM_SUPPLIER;
               if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
                  SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPPLIER', 'ITEM: '||i_key_value);
                  FORALL i in TBL_ROWID.first..TBL_ROWID.last
                     delete from item_supplier
                       where rowid = TBL_ROWID(i);
               end if;
            ---
            LP_table := 'EDI_COST_LOC';
            open C_LOCK_EDI_COST_LOC;
            close C_LOCK_EDI_COST_LOC;
            SQL_LIB.SET_MARK('DELETE',NULL,'EDI_COST_LOC', 'ITEM: '||I_key_value);
            delete from edi_cost_loc
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
            LP_table := 'EDI_COST_CHG';
            open C_LOCK_EDI_COST_CHG;
            close C_LOCK_EDI_COST_CHG;
            SQL_LIB.SET_MARK('DELETE',NULL,'EDI_COST_CHG', 'ITEM: '||I_key_value);
            delete from edi_cost_chg
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
         end if; /* end if L_pack_ind = 'N' */
         if L_import_ind = 'Y' then
            LP_table := 'ITEM_IMPORT_ATTR';
            open C_LOCK_ITEM_IMPORT_ATTR;
            close C_LOCK_ITEM_IMPORT_ATTR;
            SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_IMPORT_ATTR', 'ITEM: '||I_key_value);
            delete from item_import_attr
             where item
                in (select item
                      from item_master
                     where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
            ---
         end if; /* end L_import_ind */
         LP_table := 'RECLASS_COST_CHG_QUEUE';
         open C_LOCK_RECLASS_COST_CHG;
         close C_LOCK_RECLASS_COST_CHG;
         SQL_LIB.SET_MARK('DELETE',NULL,'RECLASS_COST_CHG_QUEUE', 'ITEM: '||I_key_value);
         delete from reclass_cost_chg_queue
         where item
            in (select item
                  from item_master
                 where (item_parent = I_key_value
                    or item_grandparent = I_key_value
                    or item_master.item = I_key_value));
         ---
         --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    Begin
         -- 08-May-08 Bahubali D Mod N111 Begin
                  LP_table := 'TSL_COMMON_SUPS_MATRIX';
                  SQL_LIB.SET_MARK('OPEN',
                                   'C_LOCK_COMMON_SUPS_MATRIX',
                                   'TSL_COMMON_SUPS_MATRIX',
                                   'ITEM: '||I_key_value);
                  open C_LOCK_COMMON_SUPS_MATRIX;
                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_LOCK_COMMON_SUPS_MATRIX',
                                   'TSL_COMMON_SUPS_MATRIX',
                                   'ITEM: '||I_key_value);
                  close C_LOCK_COMMON_SUPS_MATRIX;
                  SQL_LIB.SET_MARK('DELETE',
                                   NULL,
                                   'TSL_COMMON_SUPS_MATRIX',
                                   'ITEM: '||I_key_value);
                  delete from tsl_common_sups_matrix tcsm
                        where tcsm.item in (select im.item
                                              from item_master im
                                             where im.item_parent = I_key_value
                                                or im.item_grandparent = I_key_value
                                                or im.item = I_key_value);
         -- 08-May-08 Bahubali D Mod N111 End
         --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    End

         LP_table := 'ITEM_MFQUEUE';
         open C_LOCK_ITEM_MFQUEUE;
         close C_LOCK_ITEM_MFQUEUE;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_MFQUEUE', 'ITEM: '||I_key_value);
         --25-Aug-2010   TESCO HSC/Nandini Mariyappa   Def:NBS00018870   Begin
         delete from item_mfqueue
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value))
         or ref_item =  I_key_value;
         --25-Aug-2010   TESCO HSC/Nandini Mariyappa   Def:NBS00018870   End
         ---
         LP_table := 'ITEMLOC_MFQUEUE';
         open C_LOCK_ITEMLOC_MFQUEUE;
         close C_LOCK_ITEMLOC_MFQUEUE;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEMLOC_MFQUEUE', 'ITEM: '||I_key_value);
         delete from itemloc_mfqueue
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         ---
         LP_table := 'ITEM_SUPPLIER';
         TBL_ROWID := TYP_ROWID();
         open C_LOCK_ITEM_SUPPLIER;
         fetch C_LOCK_ITEM_SUPPLIER bulk collect into TBL_ROWID;
         close C_LOCK_ITEM_SUPPLIER;
         if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPPLIER', 'ITEM: '||i_key_value);
            FORALL i in TBL_ROWID.first..TBL_ROWID.last
              delete from item_supplier
              where rowid = TBL_ROWID(i);
         end if;
         ---
         LP_table := 'DEAL_ITEM_LOC_EXPLODE';
         open C_LOCK_DEAL_ITEM_LOC_EXPLODE;
         close C_LOCK_DEAL_ITEM_LOC_EXPLODE;
         SQL_LIB.SET_MARK('DELETE',NULL,'DEAL_ITEM_LOC_EXPLODE', 'ITEM: '||I_key_value);
         delete from deal_item_loc_explode
            where item
               in (select item
                     from item_master
                    where (item_parent = I_key_value
                       or item_grandparent = I_key_value
              or item_master.item = I_key_value));
         LP_table := 'ITEM_XFORM_DETAIL';
         open C_LOCK_ITEM_XFORM_DETAIL;
         close C_LOCK_ITEM_XFORM_DETAIL;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_XFORM_DETAIL', 'ITEM: '||I_key_value);
         delete from item_xform_detail
            where detail_item
               in (select item
                     from item_master
                    where (item_parent = I_key_value
                       or item_grandparent = I_key_value
              or item_master.item = I_key_value));
         LP_table := 'ITEM_XFORM_HEAD';
         open C_LOCK_ITEM_XFORM_HEAD;
         close C_LOCK_ITEM_XFORM_HEAD;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_XFORM_HEAD', 'ITEM: '||I_key_value);
         delete from item_xform_head
          where head_item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                         or item_grandparent = I_key_value
                         or item_master.item = I_key_value));
         --
---------------------------------------------------------------------------
         -- 18-Jun-2007 Satish BN, satish.narasimhaiah@in.tesco.com  Mod N21  Begin
          LP_table := 'TSL_SCA_WH_DIST_GRP';
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_TSL_SCA_WH_DIST_GRP',
                           'TSL_SCA_WH_DIST_GRP',
                           'ITEM:'||I_key_value);
          open C_LOCK_TSL_SCA_WH_DIST_GRP;
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_TSL_SCA_WH_DIST_GRP',
                           'TSL_SCA_WH_DIST_GRP',
                           'ITEM:'||I_key_value);
          close C_LOCK_TSL_SCA_WH_DIST_GRP;
          -- PrfNBS017475 27-Jul-2010 Gareth Jones - performance fix.
          DELETE FROM tsl_sca_wh_dist_grp
           WHERE item IN
                  (SELECT item
                     FROM item_master
                    WHERE item_parent = I_key_value
                    UNION ALL
                   SELECT item
                     FROM item_master
                    WHERE item = I_key_value
                    UNION ALL
                   SELECT item
                     FROM tsl_sca_head
                    WHERE def_pref_pack = I_key_value );
          --
          LP_table := 'TSL_SCA_WH_ORDER_PREF_PACK';
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_SCA_WH_ORDER_PREF_PACK',
                           'TSL_SCA_WH_ORDER_PREF_PACK',
                           'ITEM:'||I_key_value);
          open C_LOCK_SCA_WH_ORDER_PREF_PACK;
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_SCA_WH_ORDER_PREF_PACK',
                           'TSL_SCA_WH_ORDER_PREF_PACK',
                           'ITEM:'||I_key_value);
          close C_LOCK_SCA_WH_ORDER_PREF_PACK;
          --PrfNBS017475 Gareth Jones 27-Jul-2010
          DELETE FROM tsl_sca_wh_order_pref_pack
           WHERE item IN
                  (SELECT item
                     FROM item_master
                    WHERE item_parent = I_key_value
                    UNION ALL
                   SELECT item
                     FROM item_master
                    WHERE item = I_key_value
                    UNION ALL
                   SELECT item
                     FROM tsl_sca_wh_order_pref_pack
                    WHERE pref_pack = I_key_value );
          --
          LP_table := 'TSL_SCA_WH_ORDER_GRP';
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_TSL_SCA_WH_ORDER_GROUP',
                           'TSL_SCA_WH_ORDER_GRP',
                           'ITEM:'||I_key_value);
          open C_LOCK_TSL_SCA_WH_ORDER_GROUP;
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_TSL_SCA_WH_ORDER_GROUP',
                           'TSL_SCA_WH_ORDER_GRP',
                           'ITEM:'||I_key_value);
          close C_LOCK_TSL_SCA_WH_ORDER_GROUP;
          --PrfNBS017475 Gareth Jones, 27-Jul-2010
          DELETE FROM tsl_sca_wh_order_grp
           WHERE item IN
                  (SELECT item
                     FROM item_master
                    WHERE item_parent = I_key_value
                    UNION ALL
                   SELECT item
                     FROM item_master
                    WHERE item = I_key_value
                    UNION ALL
                   SELECT item
                     FROM tsl_sca_head
                    WHERE def_pref_pack = I_key_value);
          LP_table := 'TSL_SCA_DIRECT_ORDER_GRP';
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_SCA_DIRECT_ORDER_GROUP',
                           'TSL_SCA_DIRECT_ORDER_GRP',
                           'ITEM:'||I_key_value);
          open C_LOCK_SCA_DIRECT_ORDER_GROUP;
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_SCA_DIRECT_ORDER_GROUP',
                           'TSL_SCA_DIRECT_ORDER_GRP',
                           'ITEM:'||I_key_value);
          close C_LOCK_SCA_DIRECT_ORDER_GROUP;
          delete from tsl_sca_direct_order_grp
          --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, Begin
           where item in
                 (select item
                    from item_master
                   where item_parent = I_key_value
                   union all
                  select item
                    from item_master
                   where item = I_key_value
                   union all
                  select item
                    from tsl_sca_head
                   where def_pref_pack = I_key_value);
          --PrfNBS026215,Sriranjitha Bhagi, 20-Aug-2013, End
          LP_table := 'TSL_SCA_DIRECT_DIST_GRP';
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_SCA_DIRECT_DIST_GROUP',
                           'TSL_SCA_DIRECT_DIST_GRP',
                           'ITEM:'||I_key_value);
          open C_LOCK_SCA_DIRECT_DIST_GROUP;
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_SCA_DIRECT_DIST_GROUP',
                           'TSL_SCA_DIRECT_DIST_GRP',
                           'ITEM:'||I_key_value);
          close C_LOCK_SCA_DIRECT_DIST_GROUP;
          --PrfNBS017475 Gareth Jones 27-Jul-2010
          DELETE FROM tsl_sca_direct_dist_grp
           WHERE item IN
                  (SELECT item
                     FROM item_master
                    WHERE item_parent = I_key_value
                    UNION ALL
                   SELECT item
                     FROM item_master
                    WHERE item = I_key_value
                    UNION ALL
                   SELECT item
                     FROM tsl_sca_head
                    WHERE def_pref_pack = I_key_value );
          --
          LP_table := 'TSL_SCA_ITEM_DISTRIBUTION_TYPE';
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_TSL_SCA_ITEM_DIST_TYPE',
                           'TSL_SCA_ITEM_DISTRIBUTION_TYPE',
                           'ITEM:'||I_key_value);
          open C_LOCK_TSL_SCA_ITEM_DIST_TYPE;
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_TSL_SCA_ITEM_DIST_TYPE',
                           'TSL_SCA_ITEM_DISTRIBUTION_TYPE',
                           'ITEM:'||I_key_value);
          close C_LOCK_TSL_SCA_ITEM_DIST_TYPE;
          --PrfNBS017475 Gareth Jones - 27-Jul-2010.
          DELETE FROM tsl_sca_item_distribution_type
           WHERE item IN
                      (SELECT item
                         FROM item_master
                        WHERE item_parent = I_key_value
                        UNION ALL
                       SELECT item
                         FROM item_master
                        WHERE item = I_key_value
                        UNION ALL
                       SELECT item
                         FROM tsl_sca_head
                        WHERE def_pref_pack = I_key_value);
         -- 18-Jun-2007 Satish BN, satish.narasimhaiah@in.tesco.com  Mod N21  End
         ---------------------------------------------------------------------------
         -- CR162 Tarun Kumar Mishra tarun.mishra@in.tesco.com 14-Oct-2008 Begin
         LP_table := 'TSL_SCA_WH_ORDER';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_TSL_SCA_WH_ORDER',
                          'TSL_SCA_WH_ORDER',
                          'ITEM:'||I_key_value);
         open C_LOCK_TSL_SCA_WH_ORDER;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_TSL_SCA_WH_ORDER',
                          'TSL_SCA_WH_ORDER',
                          'ITEM:'||I_key_value);
         close C_LOCK_TSL_SCA_WH_ORDER;
         --PrfNBS017475 Gareth Jones 27-Jul-2010
         DELETE FROM tsl_sca_wh_order
          WHERE item IN
                 (SELECT item
                    FROM item_master
                   WHERE item_parent = I_key_value
                   UNION ALL
                  SELECT item
                    FROM item_master
                   WHERE item = I_key_value
                   UNION ALL
                  SELECT item
                    FROM tsl_sca_head
                   WHERE def_pref_pack = I_key_value );
         ---
         LP_table := 'TSL_SCA_DIRECT_DIST_PACKS';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_SCA_DIRECT_DIST_PACKS',
                          'TSL_SCA_DIRECT_DIST_PACKS',
                          'ITEM:'||I_key_value);
         open C_LOCK_SCA_DIRECT_DIST_PACKS;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_SCA_DIRECT_DIST_PACKS',
                          'TSL_SCA_DIRECT_DIST_PACKS',
                          'ITEM:'||I_key_value);
         close C_LOCK_SCA_DIRECT_DIST_PACKS;
         --PrfNBS017475 Gareth Jones 27-Jul-2010
         DELETE FROM tsl_sca_direct_dist_packs
         WHERE item IN
                (SELECT item
                   FROM item_master
                  WHERE item_parent = I_key_value
                  UNION ALL
                 SELECT item
                   FROM item_master
                  WHERE item = I_key_value
                  UNION ALL
                 SELECT item
                   FROM tsl_sca_direct_dist_packs
                  WHERE pack_no = I_key_value );
         ---
         LP_table := 'TSL_SCA_PREF_PACK';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_TSL_SCA_PREF_PACK',
                          'TSL_SCA_PREF_PACK',
                          'ITEM:'||I_key_value);
         open C_LOCK_TSL_SCA_PREF_PACK;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_TSL_SCA_PREF_PACK',
                          'TSL_SCA_PREF_PACK',
                          'ITEM:'||I_key_value);
         close C_LOCK_TSL_SCA_PREF_PACK;
         delete from tsl_sca_pref_pack
          where (item in (select item
                          from item_master
                         where (item_parent      = I_key_value
                            or  item_master.item = I_key_value))
           or def_pref_pack = I_key_value);


         ----
         LP_table := 'TSL_SCA_DIST_GROUP_TRIG';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_TSL_SCA_DIST_GROUP_TRIG',
                          'TSL_SCA_DIST_GROUP_TRIG',
                          'ITEM:'||I_key_value);
         open C_LOCK_TSL_SCA_DIST_GROUP_TRIG;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_TSL_SCA_DIST_GROUP_TRIG',
                          'TSL_SCA_DIST_GROUP_TRIG',
                          'ITEM:'||I_key_value);
         close C_LOCK_TSL_SCA_DIST_GROUP_TRIG;
         --PrfNBS017475 Gareth Jones 27-Jul-2010
         DELETE FROM tsl_sca_dist_group_trig
          WHERE item IN
                 (SELECT item
                    FROM item_master
                   WHERE item_parent = I_key_value
                   UNION ALL
                  SELECT item
                    FROM item_master
                   WHERE item = I_key_value
                   UNION ALL
                  SELECT item
                    FROM tsl_sca_head
                   WHERE def_pref_pack = I_key_value);
         -- CR162 Tarun Kumar Mishra tarun.mishra@in.tesco.com 14-Oct-2008 End
         ---------------------------------------------------------------------------
         --17-Oct-2007 WiproEnabler/Ramasamy - Modified to fix the issue for CQ 3252 - Begin
         ---
         -- CR162 Tarun Kumar Mishra tarun.mishra@in.tesco.com 25-Oct-2008 Begin
         -- Removed the code from here for deleting from table TSL_SCA_WH_DIST_GROUP_DETAIL
         -- and TSL_SCA_WH_DIST_GROUP_HEAD as after CR162 the distribution group is
         -- going to maintain by external system.
         -- CR162 Tarun Kumar Mishra tarun.mishra@in.tesco.com 25-Oct-2008 End
         ---
         LP_table := 'TSL_SL_RECON_REPORT_DETAIL';
         SQL_LIB.SET_MARK('OPEN',
                        'C_LOCK_TSL_SL_RECON_REPORT_DTL',
                        'TSL_SL_RECON_REPORT_DETAIL',
                        'ITEM:'||I_key_value);
         open C_LOCK_TSL_SL_RECON_REPORT_DTL;
         SQL_LIB.SET_MARK('CLOSE',
                        'C_LOCK_TSL_SL_RECON_REPORT_DTL',
                        'TSL_SL_RECON_REPORT_DETAIL',
                        'ITEM:'||I_key_value);
         close C_LOCK_TSL_SL_RECON_REPORT_DTL;
         SQL_LIB.SET_MARK('DELETE',
                        NULL,
                        'TSL_SL_RECON_REPORT_DETAIL',
                        'ITEM:'||I_key_value);
         delete from tsl_sl_recon_report_detail
             where adj_item in (select item
                                  from item_master
                                 where (item_parent = I_key_value or
                                       item_master.item = I_key_value));
         ---
         LP_table := 'TSL_SL_RECON_REPORT_HEAD';
         SQL_LIB.SET_MARK('OPEN',
                        'C_LOCK_TSL_SL_RECON_REPORT_HD',
                        'TSL_SL_RECON_REPORT_HEAD',
                        'ITEM:'||I_key_value);
         open C_LOCK_TSL_SL_RECON_REPORT_HD;
         SQL_LIB.SET_MARK('CLOSE',
                        'C_LOCK_TSL_SL_RECON_REPORT_HD',
                        'TSL_SL_RECON_REPORT_HEAD',
                        'ITEM:'||I_key_value);
         close C_LOCK_TSL_SL_RECON_REPORT_HD;
         SQL_LIB.SET_MARK('DELETE',
                        NULL,
                        'TSL_SL_RECON_REPORT_HEAD',
                        'ITEM:'||I_key_value);
         delete from tsl_sl_recon_report_head
             where report_number in (select report_number
                                       from tsl_sl_recon_report_detail
                                      where adj_item in (select item
                                                           from item_master
                                                          where (item_parent = I_key_value or
                                                                item_master.item = I_key_value)));
         ---
         --27-Aug-2010   TESCO HSC/Nandini Mariyappa   Def:NBS00018887   Begin
         /*LP_table := 'TSL_SCA_PUB_INFO';
         SQL_LIB.SET_MARK('OPEN',
                        'C_LOCK_TSL_SCA_PUB_INFO',
                        'TSL_SCA_PUB_INFO',
                        'ITEM:'||I_key_value);
         open C_LOCK_TSL_SCA_PUB_INFO;
         SQL_LIB.SET_MARK('CLOSE',
                        'C_LOCK_TSL_SCA_PUB_INFO',
                        'TSL_SCA_PUB_INFO',
                        'ITEM:'||I_key_value);
         close C_LOCK_TSL_SCA_PUB_INFO;
         SQL_LIB.SET_MARK('DELETE',
                        NULL,
                        'TSL_SCA_PUB_INFO',
                        'ITEM:'||I_key_value);
         delete from tsl_sca_pub_info
             where item in (select item
                              from item_master
                             where (item_parent = I_key_value or
                                   item_master.item = I_key_value));
         */
         --27-Aug-2010   TESCO HSC/Nandini Mariyappa   Def:NBS00018887   End
         ---
         LP_table := 'TSL_SCA_HEAD';
         SQL_LIB.SET_MARK('OPEN',
                        'C_LOCK_TSL_SCA_HEAD',
                        'TSL_SCA_HEAD',
                        'ITEM:'||I_key_value);
         open C_LOCK_TSL_SCA_HEAD;
         SQL_LIB.SET_MARK('CLOSE',
                        'C_LOCK_TSL_SCA_HEAD',
                        'TSL_SCA_HEAD',
                        'ITEM:'||I_key_value);
         close C_LOCK_TSL_SCA_HEAD;
         SQL_LIB.SET_MARK('DELETE',
                        NULL,
                        'TSL_SCA_HEAD',
                        'ITEM:'||I_key_value);
         --PrfNBS017475 Gareth Jones - 27-Jul-2010.
         -- NBS00026901 10-Mar-2014 Bhargavi P/bharagavi.pujari@in.tesco.com Begin
         -- added below condition AND as the pack which is getting deleted for that only SCA Head should be deleted
         -- as an example UK & ROI can have diff pre packs and on deleting the UK it should not
         -- delete the ROI records in the TSL_SCA_HEAD which will cause dlrprg batch failure with unknown error
         DELETE FROM tsl_sca_head
          WHERE item IN
                 (SELECT item
                    FROM item_master
                   WHERE item_parent = I_key_value
                  union all
                  SELECT item
                    FROM item_master
                   WHERE item = I_key_value
                  UNION ALL
                  SELECT item
                    FROM tsl_sca_head
                   WHERE def_pref_pack = I_key_value)
            AND decode(L_simple_pack_ind,'Y',def_pref_pack,'N',item) = I_key_value ;
         -- NBS00026901 10-Mar-2014 Bhargavi P/bharagavi.pujari@in.tesco.com End
         ---
         --17-Oct-2007 WiproEnabler/Ramasamy - Modified to fix the issue for CQ 3252 - End
         ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
         --08-Dec-2009 HSC/Nikhil                  DefNBS00015685 - Begin

        --20-Apr-2010 JK                        MrgNBS017125  Begin
        --22-MAR-2010 HSC/Srini                 NBS00016706 - Begin
     D_item:=NULL;
         --22-MAR-2010 HSC/Srini                 NBS00016706 - End
         --20-Apr-2010 JK                        MrgNBS017125  End

         LP_table := 'TSL_SCA_MFQUEUE';
         SQL_LIB.SET_MARK('OPEN',
                        'C_LOCK_TSL_SCA_MFQUEUE',
                        'TSL_SCA_MFQUEUE',
                        'ITEM:'||I_key_value);
         open C_LOCK_TSL_SCA_MFQUEUE;

           --20-Apr-2010 JK                        MrgNBS017125  Begin
           --22-MAR-2010 HSC/Srini                 NBS00016706 - Begin
          fetch C_LOCK_TSL_SCA_MFQUEUE into D_item;
           --22-MAR-2010 HSC/Srini                 NBS00016706 - End
           --20-Apr-2010 JK                        MrgNBS017125  End
         SQL_LIB.SET_MARK('CLOSE',
                        'C_LOCK_TSL_SCA_MFQUEUE',
                        'TSL_SCA_MFQUEUE',
                        'ITEM:'||I_key_value);
         close C_LOCK_TSL_SCA_MFQUEUE;
         SQL_LIB.SET_MARK('DELETE',
                        NULL,
                        'TSL_SCA_MFQUEUE',
                        'ITEM:'||I_key_value);

         --20-Apr-2010 JK                        MrgNBS017125  Begin
         --22-MAR-2010 HSC/Srini                 NBS00016706 - Begin
  if D_item is not NULL  then
         delete from tsl_sca_mfqueue
             where item in (select item
                        from item_master
                       where (item_parent = I_key_value  and item_master.status <> 'A' )or
                            (item_master.item = I_key_value and item_master.status <> 'A' ));


  end if;
  --22-MAR-2010 HSC/Srini                 NBS00016706 - end
  --20-Apr-2010 JK                        MrgNBS017125  End

         --08-Dec-2009 HSC/Nikhil                  DefNBS00015685 - End
         ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
         LP_table := 'ITEM_MASTER';
         open C_LOCK_ITEM_MASTER;
         close C_LOCK_ITEM_MASTER;
         SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_MASTER', 'ITEM: '||I_key_value);
    --04-Dec-2007 WIPRO-ENABLER Sayali Mod:N105- Change Begin
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_RNA_ITEM',
                          'ITEM_MASTER',
                          'ITEM: '||I_key_value);
         open C_GET_RNA_ITEM;
         --Fetching the cursor C_GET_ITEM_TYPE
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_RNA_ITEM',
                          'ITEM_MASTER',
                          'ITEM: '||I_key_value);
         loop
           fetch C_GET_RNA_ITEM into L_rna_item,
                                     L_item_number_type,
                                     L_it_lvl,
                                     L_pk_ind,
                                     --CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
                                     L_rna_item_status;
                                     --CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
           EXIT when C_GET_RNA_ITEM%NOTFOUND;
           if not TSL_ITEM_NUMBER_SQL.IS_RNA_TYPE(error_message,
                                                                     L_item_number_type,
                                                                   L_rna_type) then
                  return FALSE;
            end if;
           --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    Begin
           if L_tsl_common_ind = 'N' then
              if L_rna_type and L_use_rna_ind = 'Y' and
                --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
                (L_rna_item_status in ('W','S') or substr(L_item_number_type,1,3) <> 'TPN') then
                --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
                     --17-Aug-2009 Satish B.N, Satish.narasimhaiah@in.tesco.com CR243 Begin
                     if L_item_number_type = 'OCC' then
                        L_item_number_type := 'EANOWN';
                        --28-Jul-2010 JK                             MrgNBS018480  Begin
                        --16-Jul-2010 HSC/Manikandan                 NBS00018335 - Begin
                        if (substr(L_rna_item,1,1) = '0' and length(L_rna_item) = 14) then
                           L_rna_item := substr(L_rna_item,2);
                        end if;
                        --16-Jul-2010 HSC/Manikandan                 NBS00018335 - End
                        --28-Jul-2010 JK                             MrgNBS018480  End
                     end if;
                     --17-Aug-2009 Satish B.N, Satish.narasimhaiah@in.tesco.com CR243 End
                 -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                 if I_barcode_move_exch_ind != 'Y' then
                 -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                    if TSL_RNA_SQL.RETURN_TO_RNA(error_message,
                                                 L_item_number_type,
                                                 L_rna_item) = FALSE then
                       -- NBS00025484 26-Sep-2012 Sriranjitha Bhagi/Sriranjitha.Bhagi@in.tesco.com Begin
                       --return FALSE;
                       dbms_output.put_line('NOT IN RNA '||I_key_value);
                       -- NBS00025484 26-Sep-2012 Sriranjitha Bhagi/Sriranjitha.Bhagi@in.tesco.com End
                    end if;
                 -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                 end if;
                 -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
              end if;


              if ((L_it_lvl in (2,3)) and
                  (L_pk_ind = 'N')) and L_use_rna_ind = 'Y' then
                 if TSL_ITEM_NUMBER_SQL.GET_CONSUMER_UNIT(error_message,
                                                          L_rna_item,
                                                          L_consumer_unit) = FALSE then
                    return FALSE;
                 end if;
                 if L_consumer_unit is NOT NULL then
                   --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
                   if  L_rna_item_status in ('W','S') then
                   --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
                    -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                    if I_barcode_move_exch_ind != 'Y' then
                    -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                       if TSL_RNA_SQL.RETURN_TO_RNA(error_message,
                                                    'TPNC',
                                                     L_consumer_unit) = FALSE then
                          -- NBS00025484 26-Sep-2012 Sriranjitha Bhagi/Sriranjitha.Bhagi@in.tesco.com Begin
                          --return FALSE;
                          dbms_output.put_line('NOT IN RNA '||I_key_value);
                          -- NBS00025484 26-Sep-2012 Sriranjitha Bhagi/Sriranjitha.Bhagi@in.tesco.com End
                       end if;
                    -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                    end if;
                    -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                   --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
                   end if;
                   --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
                 end if;
              end if;
           end if; --L_tsl_common_ind
           --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    End
         End loop;
       --Closing the cursor C_GET_ITEM_TYPE
       SQL_LIB.SET_MARK('CLOSE',
                        'C_GET_RNA_ITEM',
                        'ITEM_MASTER',
                        'ITEM: '||I_key_value);
       close C_GET_RNA_ITEM;
    --04-Dec-2007 WIPRO-ENABLER Sayali Mod:N105- Change End

         -- 13-Aug-2008 Dhuraison Prince - Defect NBS008124 BEGIN
         LP_table := 'TSL_FUTURE_COST';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_TSL_FUTURE_COST',
                          'TSL_FUTURE_COST',
                          'Item: '||I_key_value);
         open C_LOCK_TSL_FUTURE_COST;
         ---
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_TSL_FUTURE_COST',
                          'TSL_FUTURE_COST',
                          'Item: '||I_key_value);
         close C_LOCK_TSL_FUTURE_COST;
         ---
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_FUTURE_COST',
                          'Item: '||I_key_value);
         ---
         delete from tsl_future_cost
          where item IN (select item
                           from item_master
                          where item             = I_key_value
                             or item_parent      = I_key_value
                             or item_grandparent = I_key_value);
         -- 13-Aug-2008 Dhuraison Prince - Defect NBS008124 END

         -- 07-Apr-2009 Tesco HSC/Usha Patil      Mod:CR209 Begin
         delete from tsl_wawac_queue
               where item = I_key_value;
         -- 07-Apr-2009 Tesco HSC/Usha Patil      Mod:CR209 End
         --DefNBS021532 CR304 16-Feb-2011 Parvesh parveshkumar.rulhan@in.tesco.com Begin
         delete from tsl_deactivate_error
          where item IN (select item
                           from item_master
                          where item             = I_key_value
                             or item_parent      = I_key_value
                             or item_grandparent = I_key_value);
         --DefNBS021532 CR304 16-Feb-2011 Parvesh parveshkumar.rulhan@in.tesco.com End
         -- DefNBS023298 21-Jul-2011 Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com Begin
         if DAILY_PURGE_DEL_RPM_RECS(error_message,
                                     I_key_value) = FALSE then
            RETURN FALSE;
         end if;
         -- DefNBS023298 21-Jul-2011 Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com End

         --30-Dec-2011 Tesco HSC/Usha Patil            Mod: N169 Begin
         if I_barcode_move_exch_ind = 'N' then
	          if DELETE_ITEM_RECORDS_SQL.TSL_PICKLIST_ITEM_PURGE (error_message,
	                                                              I_key_value) = FALSE then
	             return FALSE;
	          end if;
	       end if;
         -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com Begin
         if L_item_level = L_tran_level
         and L_pack_ind = 'N' then
	          delete
	            from pos_item_button pib
	           where pib.item = I_key_value;
	       end if;
         -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com End
         --30-Dec-2011 Tesco HSC/Usha Patil            Mod: N169 End

         delete from item_master
          where item_grandparent = I_key_value;
         --18-Sep-2013 Tesco HSC/Niraj Choudhary           Mod: CR485 Begin
         if L_tran_level > L_item_level then
            delete from item_master
                   where item_parent = I_key_value
                     and item != tsl_base_item;

            delete from item_master
                  where item_parent = I_key_value
                    and item = tsl_base_item;
        else
            delete from item_master
                where item_parent = I_key_value;
        end if;
         --18-Sep-2013 Tesco HSC/Niraj Choudhary           Mod: CR485 End
         --21-Aug-2009 TESCO HSC/Murali N    NBS00014560   Begin
         delete from item_master im
          where item = I_key_value;
          -- Commented as it is Common Product code and was blocking UPCDel messages for EAN items
            /*and not exists(select 1
                             from daily_purge dp
                            where dp.key_value = im.item_parent
                              and table_name = 'ITEM_MASTER');*/
         --21-Aug-2009 TESCO HSC/Murali N    NBS00014560   End
         --16-May-2010 Tesco HSC/Reshma Koshy  DefNBS016790/DefNBS017418 Begin
         --09-Feb-2010 Tesco HSC/Usha Patil            Defect Id: NBS00014580 Begin
         --delete from item_pub_info
          --where item = I_key_value;
         --09-Feb-2010 Tesco HSC/Usha Patil            Defect Id: NBS00014580 End
         --16-Apr-2010 Tesco HSC/Reshma Koshy  DefNBS016790/DefNBS017418 Begin
         ---
      else /* item_level > tran_level */
         --16-Apr-2008 WiproEnabler/Karthik   DefNBS00006107  Begin
         LP_table := 'ITEM_ATTRIBUTES';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_ITEM_ATTRIBUTES',
                          'ITEM_ATTRIBUTES',
                          'ITEM: '||I_key_value);
         open C_LOCK_ITEM_ATTRIBUTES;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_ITEM_ATTRIBUTES',
                          'ITEM_ATTRIBUTES',
                          'ITEM: '||I_key_value);
         close C_LOCK_ITEM_ATTRIBUTES;
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'ITEM_ATTRIBUTES',
                          'ITEM: '||I_key_value);
         delete from item_attributes
          where item = I_key_value;
         --16-Apr-2008 WiproEnabler/Karthik   DefNBS00006107  End
         LP_table := 'COMP_SHOP_LIST';
         open C_LOCK_COMP_SHOP_LIST_REF_ITEM;
         close C_LOCK_COMP_SHOP_LIST_REF_ITEM;
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'COMP_SHOP_LIST',
                          'REF_ITEM: '||i_key_value);
         update comp_shop_list
            set ref_item = NULL
          where ref_item = i_key_value;
         LP_table := 'ITEM_APPROVAL_ERROR';
         open C_LOCK_ITEM_APPROVAL_ERROR;
         close C_LOCK_ITEM_APPROVAL_ERROR;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_APPROVAL_ERROR', 'ITEM: '||I_key_value);
         delete from item_approval_error
          where item
             in (select item
                   from item_master
                  where (item_parent = I_key_value
                            or item_grandparent = I_key_value
                            or item_master.item = I_key_value));
          ---
         LP_table := 'ITEM_SUPPLIER';
         TBL_ROWID := TYP_ROWID();
         open C_LOCK_ITEM_SUPPLIER;
         fetch C_LOCK_ITEM_SUPPLIER bulk collect into TBL_ROWID;
         close C_LOCK_ITEM_SUPPLIER;
         if TBL_ROWID is not NULL and TBL_ROWID.count > 0 then
            SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPPLIER', 'ITEM: '||i_key_value);
            FORALL i in TBL_ROWID.first..TBL_ROWID.last
              delete from item_supplier
              where rowid = TBL_ROWID(i);
         end if;
         ---
         LP_table := 'ITEM_MASTER';
         open C_LOCK_ITEM_MASTER;
         close C_LOCK_ITEM_MASTER;
         SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_MASTER', 'ITEM: '||I_key_value);
  --04-Dec-2007 WIPRO-ENABLER Sayali Mod:N105- Change Begin
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_RNA_ITEM',
                          'ITEM_MASTER',
                          'ITEM: '||I_key_value);
         open C_GET_RNA_ITEM;
         --Fetching the cursor C_GET_RNA_ITEM
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_RNA_ITEM',
                          'ITEM_MASTER',
                          'ITEM: '||I_key_value);
         loop
            fetch C_GET_RNA_ITEM into L_rna_item,
                                      L_item_number_type,
                                      L_it_lvl,
                                      L_pk_ind,
                                      --CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
                                      L_rna_item_status;
                                      --CR220 , Tarun Kumar Mishra, tarun.mishra@in.tesco.com  06-Nov-2009  End
            EXIT when C_GET_RNA_ITEM%NOTFOUND;
            --DefNBS019715,12-Nov-2010,Sripriya,Sripriya.karanam@in.tesco.com Begin
            if L_item_number_type in ('EANOWN','OCC','PLUGB','PLUTU') then
               SQL_LIB.SET_MARK('OPEN',
                                'C_GET_ITEM_PARENT',
                                'ITEM_MASTER',
                                'ITEM: '||I_key_value);
               open C_GET_ITEM_PARENT;
               --Fetching the cursor C_GET_ITEM_PARENT
               SQL_LIB.SET_MARK('FETCH',
                                'C_GET_ITEM_PARENT',
                                'ITEM_MASTER',
                                'ITEM: '||I_key_value);
               fetch C_GET_ITEM_PARENT into L_parent,L_own_ctry;
               SQL_LIB.SET_MARK('CLOSE',
                                'C_GET_ITEM_PARENT',
                                'ITEM_MASTER',
                                'ITEM: '||I_key_value);
               close C_GET_ITEM_PARENT;

               if not ITEM_ATTRIB_SQL.TSL_GET_ITEM_ATTRIB(error_message,
                                                         L_attrib_rec,
                                                         L_parent,
                                                         L_own_ctry) then
                  return FALSE;
               end if;

               if NVL(L_attrib_rec.tsl_brand_ind,'Y') = 'N' then
                  L_rna_child := FALSE;
               end if;
            end if;

            if L_rna_child then
            --DefNBS019715,12-Nov-2010,Sripriya,Sripriya.karanam@in.tesco.com End
               if not TSL_ITEM_NUMBER_SQL.IS_RNA_TYPE(error_message,
                                                      L_item_number_type,
                                                      L_rna_type) then
                  return FALSE;
               end if;

            --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    Begin
            if L_tsl_common_ind = 'N' then
               if L_rna_type and L_use_rna_ind = 'Y' then
                  -- DefNBS008703, 5-Sep-2008 Tesco HSC/Satish Begin
                  --15-Jul-2009 Tesco HSC/Usha Patil                  Defect Id: NBS00013954 Begin
                  --Added condition to check for simple_pack_ind.
                  if L_item_number_type = 'OCC' and L_simple_pack_ind = 'Y' then
                  --15-Jul-2009 Tesco HSC/Usha Patil                  Defect Id: NBS00013954 End
                     if ITEM_ATTRIB_SQL.TSL_CHECK_OCC_MATCH_EAN(error_message,
                                                                L_match,
                                                                I_key_value) = FALSE then
                        return FALSE;
                     end if;
                     ----
                     if L_match = TRUE then
                        L_flag := 'N';
                     end if;
                  end if;
                  if L_flag = 'Y' then
                  -- DefNBS008703, 5-Sep-2008 Tesco HSC/Satish End
                     --17-Aug-2009 Satish B.N, Satish.narasimhaiah@in.tesco.com CR243 Begin
                     if L_item_number_type = 'OCC' then
                        L_item_number_type := 'EANOWN';
                        --28-Jul-2010 JK                             MrgNBS018480  Begin
                        --16-Jul-2010 HSC/Manikandan                 NBS00018335 - Begin
                        if (substr(L_rna_item,1,1) = '0' and length(L_rna_item) = 14) then
                           L_rna_item := substr(L_rna_item,2);
                        end if;
                        --16-Jul-2010 HSC/Manikandan                 NBS00018335 - End
                        --28-Jul-2010 JK                             MrgNBS018480  End
                     end if;
                     --17-Aug-2009 Satish B.N, Satish.narasimhaiah@in.tesco.com CR243 End
                     --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
                     if L_rna_item_status in ('W','S') or substr(L_item_number_type,1,3) <> 'TPN' then
                     --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
                        -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                        if I_barcode_move_exch_ind != 'Y' then
                        -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                          if TSL_RNA_SQL.RETURN_TO_RNA(error_message,
                                                       L_item_number_type,
                                                       L_rna_item) = FALSE then
                             -- NBS00025484 26-Sep-2012 Sriranjitha Bhagi/Sriranjitha.Bhagi@in.tesco.com Begin
                             --return FALSE;
                             dbms_output.put_line('NOT IN RNA '||I_key_value);
                             -- NBS00025484 26-Sep-2012 Sriranjitha Bhagi/Sriranjitha.Bhagi@in.tesco.com End
                          end if;
                      -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                      end if;
                      -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                     --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
                     end if;
                     --- CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
                  end if; -- DefNBS008703
               end if;


               if ((L_it_lvl in (2,3)) and
                   (L_pk_ind = 'N')) and L_use_rna_ind = 'Y'  then
                  if TSL_ITEM_NUMBER_SQL.GET_CONSUMER_UNIT(error_message,
                                                           L_rna_item,
                                                           L_consumer_unit) = FALSE then
                     return FALSE;
                  end if;
                  if L_consumer_unit is NOT NULL then
                    --CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
                    if  L_rna_item_status in ('W','S') then
                    --CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
                        -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                        if I_barcode_move_exch_ind != 'Y' then
                        -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                           if TSL_RNA_SQL.RETURN_TO_RNA(error_message,
                                                        'TPNC',
                                                        L_consumer_unit) = FALSE then
                              -- NBS00025484 26-Sep-2012 Sriranjitha Bhagi/Sriranjitha.Bhagi@in.tesco.com Begin
                              --return FALSE;
                              dbms_output.put_line('NOT IN RNA '||I_key_value);
                              -- NBS00025484 26-Sep-2012 Sriranjitha Bhagi/Sriranjitha.Bhagi@in.tesco.com End
                           end if;
                        -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                        end if;
                        -- NBS00018303 16-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                    --CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  Begin
                    end if;
                    --CR220 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com  06-Nov-2009  End
                  end if;
               end if;
            end if; --L_tsl_common_ind
           --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    End
         --DefNBS019715,12-Nov-2010,Sripriya,Sripriya.karanam@in.tesco.com Begin
         end if;
         --DefNBS019715,12-Nov-2010,Sripriya,Sripriya.karanam@in.tesco.com End
         End loop;
       --Closing the cursor C_GET_ITEM_TYPE
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_RNA_ITEM',
                          'ITEM_MASTER',
                          'ITEM: '||I_key_value);
       close C_GET_RNA_ITEM;
         -- 25-Aug-2010 TESCO HSC/Nandini Mariyappa   Def:NBS00018870   Begin
         -- 01-Jul-2009 Satish B.N, Satish.narasimhaiah@in.tesco.com DefNBS013670 Begin
         delete from item_mfqueue
          where item     = I_key_value
             or ref_item = I_key_value;
         -- 01-Jul-2009 Satish B.N, Satish.narasimhaiah@in.tesco.com DefNBS013670 End
         --25-Aug-2010   TESCO HSC/Nandini Mariyappa   Def:NBS00018870   End
    --04-Dec-2007 WIPRO-ENABLER Sayali Mod:N105- Change End
         --DefNBS021532 CR304 16-Feb-2011 Parvesh parveshkumar.rulhan@in.tesco.com Begin
         delete from tsl_deactivate_error
          where item IN (select item
                           from item_master
                          where item             = I_key_value
                             or item_parent      = I_key_value
                             or item_grandparent = I_key_value);
         --DefNBS021532 CR304 16-Feb-2011 Parvesh parveshkumar.rulhan@in.tesco.com End
         -- DefNBS023298 21-Jul-2011 Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com Begin
         if DAILY_PURGE_DEL_RPM_RECS(error_message,
                                     I_key_value) = FALSE then
            RETURN FALSE;
         end if;
         -- DefNBS023298 21-Jul-2011 Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com End

         --30-Dec-2011 Tesco HSC/Usha Patil            Mod: N169 Begin
         if I_barcode_move_exch_ind = 'N' then
	          if DELETE_ITEM_RECORDS_SQL.TSL_PICKLIST_ITEM_PURGE (error_message,
	                                                              I_key_value) = FALSE then
	             return FALSE;
	          end if;
	       end if;
         -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com Begin
         if L_item_level = L_tran_level
         and L_pack_ind = 'N' then
	          delete
	            from pos_item_button pib
	           where pib.item = I_key_value;
	       end if;
         -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com End
         --30-Dec-2011 Tesco HSC/Usha Patil            Mod: N169 End

         delete from item_master
          where item = I_key_value;
         --16-May-2010 Tesco HSC/Reshma Koshy  DefNBS016790/DefNBS017418 Begin
         --09-Sep-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014580 Begin
         --delete from item_pub_info
         -- where item = I_key_value;
         --09-Sep-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014580 End
         --16-May-2010 Tesco HSC/Reshma Koshy  DefNBS016790/DefNBS017418 Begin
         ---
         LP_table := 'DAILY_PURGE';
         open C_LOCK_DAILY_PURGE_II;
         close C_LOCK_DAILY_PURGE_II;
         SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_PURGE', 'KEY_VALUE: '||I_key_value);
         delete from daily_purge
          where key_value = I_key_value
            and table_name = 'ITEM_MASTER';
      end if; /* end if tran_level >= item_level */

      /* 04-Aug-2008 TESCO HSC/Murali   DEFNBS006793 Begin */
      -- Moved the changes(N127) to delete records from tsl_item_range and tsl_prov_range
      /* 04-Aug-2008 TESCO HSC/Murali   DEFNBS006793 End */
   else
      LP_table := 'DAILY_PURGE';
      open C_LOCK_DAILY_PURGE_II;
      close C_LOCK_DAILY_PURGE_II;
      SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_PURGE', 'KEY_VALUE: '||I_key_value);
      delete from daily_purge
       where key_value = I_key_value
         and table_name = 'ITEM_MASTER';
   end if;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                          LP_table,
                                          I_key_value);
      return FALSE;
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'DEL_ITEM', SQLCODE);
      return FALSE;
END DEL_ITEM;
------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- 22-Nov-2007 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS00004099 Begin
-------------------------------------------------------------------------------------
FUNCTION TSL_DEL_BARCODE_ATTRIB(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_item            IN       ITEM_MASTER.ITEM%TYPE)
  RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'DELETE_ITEM_RECORDS_SQL.TSL_DEL_BARCODE_ATTRIB';
      cursor C_LOCK_ITEM_ATTRIBUTES is
      select 'x'
        from item_attributes
       where item =I_item
         for update nowait;

BEGIN

   open C_LOCK_ITEM_ATTRIBUTES;
   close C_LOCK_ITEM_ATTRIBUTES;

   SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_ATTRIBUTES', 'Item: '||I_item);
   delete from item_attributes
    where item =I_item;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                          'ITEM_ATTRIBUTES',
                                          I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_DEL_BARCODE_ATTRIB;
-------------------------------------------------------------------------------------
-- 22-Nov-2007 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS00004099 End
-------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- 21-Jan-2010 Joy Stephen, joy,johnchristopher@in.tesco.com DefNBS016007 Begin
---------------------------------------------------------------------------------------------
FUNCTION TSL_BARCODE_COUNT(O_error_message  IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_rec_count      IN OUT   NUMBER,
                           I_item           IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(64) := 'DELETE_ITEM_RECORDS_SQL.TSL_BARCODE_COUNT';
   L_rec_count    NUMBER  := 0;

   cursor C_COUNT is
      select count(item)
        from item_master i
       where item_parent = I_item
         and item_level  > tran_level
         and status = 'A';

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_COUNT',
                    'item_master',
                    NULL);
   open C_COUNT;

   SQL_LIB.SET_MARK('FETCH',
                    'C_COUNT',
                    'item_master',
                    NULL);
   fetch C_COUNT into L_rec_count;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_COUNT',
                    'item_master',
                    NULL);
   close C_COUNT;
   O_rec_count := L_rec_count;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_BARCODE_COUNT;
---------------------------------------------------------------------------------------------
-- 21-Jan-2010 Joy Stephen, joy,johnchristopher@in.tesco.com DefNBS016007 End
---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- DefNBS023298 21-Jul-2011 Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com Begin  --
------------------------------------------------------------------------------------------------
-- Function Name: DAILY_PURGE_DEL_RPM_RECS                                                    --
--       Purpose: To delete records from rpm_item_zone_price,rpm_zone_future_retail tables.   --
------------------------------------------------------------------------------------------------
FUNCTION DAILY_PURGE_DEL_RPM_RECS(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_item                IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program          VARCHAR2(100)   := 'DELETE_ITEM_RECORDS_SQL.DAILY_PURGE_DEL_RPM_RECS';
   L_item_rec         ITEM_MASTER%ROWTYPE;
   RECORD_LOCKED      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_RPM_ZONE_FUTURE_RETAIL is
   select 'X'
     from rpm_zone_future_retail
    where item = I_item
      for update nowait;

   cursor C_LOCK_RPM_ITEM_ZONE_PRICE is
   select 'X'
     from rpm_item_zone_price
    where item = I_item
      for update nowait;

BEGIN
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_rec,
                                      I_item) = FALSE then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_RPM_ITEM_ZONE_PRICE', 'RPM_ITEM_ZONE_PRICE', 'ITEM: ' ||I_item);
   open C_LOCK_RPM_ITEM_ZONE_PRICE;

   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_RPM_ITEM_ZONE_PRICE', 'RPM_ITEM_ZONE_PRICE', 'ITEM: ' ||I_item);
   close C_LOCK_RPM_ITEM_ZONE_PRICE;

   delete from rpm_item_zone_price rizp
         where exists(select 1
                        from rpm_item_zone_price rizp2
                       where rizp2.item = I_item
                         and rizp2.rowid = rizp.rowid);

   if L_item_rec.item_level = L_item_rec.tran_level and L_item_rec.pack_ind = 'N' and L_item_rec.simple_pack_ind = 'N' then

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_RPM_ZONE_FUTURE_RETAIL', 'RPM_ZONE_FUTURE_RETAIL', 'ITEM: ' ||I_item);
      open C_LOCK_RPM_ZONE_FUTURE_RETAIL;

      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_RPM_ZONE_FUTURE_RETAIL', 'RPM_ZONE_FUTURE_RETAIL', 'ITEM: ' ||I_item);
      close C_LOCK_RPM_ZONE_FUTURE_RETAIL;

      delete from rpm_zone_future_retail rzfr
            where exists (select 1
                            from rpm_zone_future_retail rzfr2
                           where rzfr2.item = I_item
                             and rzfr2.rowid = rzfr.rowid);
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             NULL,
                                             L_program,
                                             'ITEM: ' ||I_item);
      return FALSE;

   when OTHERS then
      if C_LOCK_RPM_ZONE_FUTURE_RETAIL%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_RPM_ZONE_FUTURE_RETAIL', 'RPM_ZONE_FUTURE_RETAIL', NULL);
         close C_LOCK_RPM_ZONE_FUTURE_RETAIL;
      end if;
      ---
      if C_LOCK_RPM_ITEM_ZONE_PRICE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_RPM_ITEM_ZONE_PRICE','RPM_ITEM_ZONE_PRICE', NULL);
         close C_LOCK_RPM_ITEM_ZONE_PRICE;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));

      return FALSE;
END DAILY_PURGE_DEL_RPM_RECS;
----------------------------------------------------------------------------------------------
-- DefNBS023298 21-Jul-2011 Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com End  --
----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- 30-Dec-2011 Tesco HSC/Usha Patil, usha.patil@in.tesco.com Mod: N169 Begin
---------------------------------------------------------------------------------------------
-- Function Name: TSL_PICKLIST_ITEM_PURGE
--       Purpose: This function insert record into tsl_pickist_status
--                table if there is no picklist approval happened and no purge record is present
--                in the table for the same business day(action type as 'P').
---------------------------------------------------------------------------------------------
FUNCTION TSL_PICKLIST_ITEM_PURGE(O_error_message  IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_item           IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   L_program      VARCHAR2(64) := 'DELETE_ITEM_RECORDS_SQL.TSL_PICKLIST_ITEM_PURGE';

   L_picklist_ind        SYSTEM_OPTIONS.TSL_PICKLIST_IND%TYPE := 'N';
   L_tpnb_var_purged     VARCHAR2(1) := 'N';
   L_purged_approved     VARCHAR2(1) := 'N';
   L_ean_purged          VARCHAR2(1) := 'N';
   -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com Begin
   L_exist               VARCHAR2(1);
   -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com End
   L_item_master_row     ITEM_MASTER%ROWTYPE;

   cursor C_CHK_PURGED_APPROVED is
   select 'Y'
     from tsl_picklist_status tps
    where tps.action_type in ('P','A')
      and vdate = get_vdate();

   cursor C_TPNB_VAR_PURGED is
   select 'Y'
     from pos_item_button pib,
          item_master iem
    where iem.item = I_item
      and iem.status = 'A'
      and (iem.item = pib.item
       or iem.tsl_base_item = pib.item);

   cursor C_EAN_PURGED is
   select 'Y'
     from pos_item_button pib,
          item_master iem,
          item_master iem2
    where iem.item            = I_item
      and iem.status          = 'A'
      and (iem.item_parent    = pib.item
       or (iem.item_parent    = iem2.item
      and iem2.tsl_base_item = pib.item));

BEGIN
   if SYSTEM_OPTIONS_SQL.TSL_GET_PICKLIST_IND (O_error_message,
                                               L_picklist_ind) = FALSE then
      return FALSE;
   end if;

   if L_picklist_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHK_PURGED_APPROVED',
                       'tsl_picklist_status',
                       NULL);
      open C_CHK_PURGED_APPROVED;

      SQL_LIB.SET_MARK('FETCH',
                       'C_CHK_PURGED_APPROVED',
                       'tsl_picklist_status',
                       NULL);
      fetch C_CHK_PURGED_APPROVED into L_purged_approved;

      if C_CHK_PURGED_APPROVED%FOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHK_PURGED_APPROVED',
                          'tsl_picklist_status',
                          NULL);
         close C_CHK_PURGED_APPROVED;

         return TRUE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHK_PURGED_APPROVED',
                       'tsl_picklist_status',
                       NULL);
      close C_CHK_PURGED_APPROVED;
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                          L_item_master_row,
                                          I_item) = FALSE then
	       return FALSE;
	    end if;
      -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com Begin
      if L_purged_approved != 'Y' then
      -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com End
	       if L_item_master_row.item_level = L_item_master_row.tran_level and
	          L_item_master_row.pack_ind = 'N' then
	          SQL_LIB.SET_MARK('OPEN',
	                           'C_TPNB_VAR_PURGED',
	                           'item_master, pos_item_button',
	                           NULL);
	          open C_TPNB_VAR_PURGED;

	          SQL_LIB.SET_MARK('FETCH',
	                           'C_TPNB_VAR_PURGED',
	                           'item_master, pos_item_button',
	                           NULL);
	          fetch C_TPNB_VAR_PURGED into L_tpnb_var_purged;

	          SQL_LIB.SET_MARK('CLOSE',
	                           'C_TPNB_VAR_PURGED',
	                           'item_master, pos_item_button',
	                           NULL);
	          close C_TPNB_VAR_PURGED;

	       elsif L_item_master_row.item_level > L_item_master_row.tran_level and
	         L_item_master_row.pack_ind = 'N' then
	          SQL_LIB.SET_MARK('OPEN',
	                           'C_EAN_PURGED',
	                           'item_master, pos_item_button',
	                           NULL);
	          open C_EAN_PURGED;

	          SQL_LIB.SET_MARK('FETCH',
	                           'C_EAN_PURGED',
	                           'item_master, pos_item_button',
	                           NULL);
	          fetch C_EAN_PURGED into L_ean_purged;

	          SQL_LIB.SET_MARK('CLOSE',
	                           'C_EAN_PURGED',
	                           'item_master, pos_item_button',
	                           NULL);
	          close C_EAN_PURGED;
	       end if;
	       if L_tpnb_var_purged = 'Y' or L_ean_purged = 'Y' then
		        insert into tsl_picklist_status (action_type,
		                                         user_id,
		                                         vdate,
		                                         date_timestamp)
		                                  values('P',
		                                         USER,
		                                         get_vdate(),
		                                         sysdate);
	       end if;
	    -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com Begin
	    end if;
	    -- N169/CR373 15-Mar-2012 Bhargavi P,bharagavi.pujari@in.tesco.com End
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_PICKLIST_ITEM_PURGE;
---------------------------------------------------------------------------------------------
-- 30-Dec-2011 Tesco HSC/Usha Patil, usha.patil@in.tesco.com Mod: N169 End
---------------------------------------------------------------------------------------------
END DELETE_ITEM_RECORDS_SQL;
/

