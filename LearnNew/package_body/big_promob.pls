CREATE OR REPLACE PACKAGE BODY BIG_PROMO
AS
---------------------------------------------------------------------------------------
-- Mod By: RK
-- Mod Date: 3-Jan-2008
-- Mod Ref: Forward Porting.
-- Mod Details: Modified GET_PROMOTION_OBJECT(),PRICE_EVENT_INSERT() to handle the multiple
--              promotion ids.
---------------------------------------------------------------------------------------
-- Mod By: Lakshmi Natarajan
-- Mod Date: 15-Jan-2008
-- Mod Ref: Forward Porting.
-- Mod Details: Modified function REMOVE_PROMOTION(),GET_PROMOTION_OBJECT(),INSERT_PROMO(),IGNORE_APPROVED_LOC_MOVES() to handle MultiBuy Promotion Components
---------------------------------------------------------------------------------------
-- Mod By     : Rachaputi Praveen
-- Mod Date   : 11-Feb-2008
-- Mod Ref    : Mod N75.
-- Mod Details: Modified functions PRICE_EVENT_INSERT() and PRICE_EVENT_REMOVE()
--              for allowing publication of zone level price changes at zone level.
--------------------------------------------------------------------------------
-- Mod By     : Kumaravadivel Shanmugam , Kumaravadivel.Shanmugam@in.tesco.com
-- Mod Date   : 4-Apr-2008
-- Mod Ref    : DefNBS005699 in Mod N75.
-- Mod Details: Modified functions PUBLISH_CHANGES() for allowing
--              publication of zone level price changes at zone level.
--------------------------------------------------------------------------------
-- Mod By: Lakshmi   Natarajan
-- Mod Date: 29-Apr-2008
-- Description: Modified function GET_PROMOTION_OBJECT() for ST Defect Fix #5537
--------------------------------------------------------------------------------
-- Mod By: Murali - murali.natarajan@in.tesco.com
-- Mod Date: 05-Nov-2008
-- Mod Ref:  CR167,173
-- Mod Details: Modified to enable zone level publications for promotions
--------------------------------------------------------------------------------
-- Mod By       : Sourabh Sharva, sourabh.sharva@in.tesco.com
-- Mod Date     : 12-Dec-2008
-- Mod Ref      : ST DefNBS010377
-- Mod Details  : Modified the mapping of TSL_VALID_DEFAULTS_IND to TSL_RPM_ZONE_LVL_IND.
--                renamed the variable L_valid_defaults_ind to L_rpm_zone_lvl_ind
---------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Mod By       : Abhijeet Suman
-- Mod Date     : 23-Feb-2008
-- Mod Ref      : ST DefNBS05242
-- Mod Details  : Oracle Patch Merge 7364392
---------------------------------------------------------------------------------------
-- Mod By       : Sourabh Sharva, sourabh.sharva@in.tesco.com
-- Mod Date     : 21-May-2009
-- Mod Ref      : LT DefNBS012982
-- Mod Details  : Modified the function  GET_PROMOTION_OBJECT()
---------------------------------------------------------------------------------------
-- Mod By: Vikash Prasad , vikash.prasad@in.tesco.com
-- Mod Date: 25-May-2009
-- Mod Ref: Mod N25
-- Mod Details: Modified function SCHEDULE_LOCATION_MOVE to call functions based on
--              TSL_RPM_LOC_MOVE_CHGS indicator and added TSL_PUSH_BACK to be called if
--              TSL_RPM_LOC_MOVE_CHGS is set to 'Y'.
--------------------------------------------------------------------------------
-- Modified By   : Debadatta Patra, debadatta.patra@in.tesco.com
-- Modified Date : 26-May-2009
-- Mod Ref       : Mod N25.
-- Description   : Modified the function PRICE_EVENT_INSERT for controlling the
--                 publication depending on the system options
--------------------------------------------------------------------------------
-- Modified By    : Jini Moses
-- Date           : 23-July-2009
-- Mod Ref        : Mod 93b
-- Description    : Modified TSL_ZONE_PUSH_BACK, to match the 93b changes
---------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Mod By      : Debadatta Patra
-- Mod Date    : 25-July-2009
-- Mod Ref     : NBS00013973(N25)
-- Mod Details : Modified the function SCHEDULE_LOCATION_MOVE() for scheduling location move as per N25.
--
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Mod By      : Debadatta Patra
-- Mod Date    : 27-July-2009
-- Mod Ref     : NBS00013883(N25)
-- Mod Details : Modified the function INSERT_PROMO() to call function TSL_LM_MERGE_PROMOTION of
--             : RPM_FUTURE_RETAIL_GTT_SQL for merge promotion of location move during locationMove batch run.
--------------------------------------------------------------------------------------------------------

   -- Mod By       : Abhijeet Suman, abhijeet.suman@in.tesco.com
-- Mod Date     : 14-Aug-2009
-- Mod Ref      : FST DefNBS014255
-- Mod Details  : When New Item Loc Batch runs if item inherit the promotion
--                the item promotion component details should be there in
--                tsl_rpm_promo_comp_tpnd.
---------------------------------------------------------------------------------------
-- Mod By       : Yohida Ramamurthy, yohida.ramamurthy@in.tesco.com
-- Mod Date     : 03-Nov-2009
-- Mod Ref      : Prod fix DefNBS015225
-- Mod Details  : Condition added to restrict the publication if the new item Loc batch
--                execute. Modified the function  PUBLISH_CHANGES()
---------------------------------------------------------------------------------------
-- Mod By       : Debadatta Patra
-- Mod Date     : 17-NOV-2009
-- Mod Ref      : NBS00015345
-- Mod Details  : Added TSL_PUSH_BACK_REMOVE() and TSL_ZONE_PUSH_BACK_REMOVE() function for clearing
--                promotion details from rpm_future_retail table for any cancelled /unapproved promotion.
----------------------------------------------------------------------------------------------
-- Mod By      : Debadatta Patra
-- Mod Date    : 24-NOV-2009
-- Mod Ref     : NBS00015404(N25)
-- Mod Details : Modified the function INSERT_PRICE_CHANGE() to call function TSL_LM_MERGE_PRICE_CHANGE of
--             : RPM_FUTURE_RETAIL_GTT_SQL for merge price change of location move during locationMove batch run.
--
--------------------------------------------------------------------------------------------------------
-- Mod By       : Bernard Craddock
-- Mod Date     : 20-OCT-2009
-- Mod Ref      : NBS000015287
-- Mod Details  : Modified PUSH_BACK()function driving off wrong table added rowid(rfr) hint.
--------------------------------------------------------------------------------------------------------
-- Mod By      : Debadatta Patra
-- Mod Date    : 11-DEC-2009
-- Mod Details : Forward porting N25 latest fixes from 3.3b(Pre-production)
--------------------------------------------------------------------------------------------------------
-- Mod By       : Bernard Craddock / Kiran Chalamala
-- Mod Date     : 24-Dec-2009
-- Mod Ref      : Promotions Performance Chagnes
-- Mod Details  : Modified PUSH_BACK() method.When number of distinct depts on GTT less than given number 64 then loop through
--                depts and merge directly on dept partition otherwise merge on table..
---------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By      : Sajjad Ahmed
-- Mod Date    : 11-Jan-2009
-- Def Ref     : NBS00015249
-- Mod Details : Modified INSERT_CLEARANCE function for implementing mod N25 for clearances
-----------------------------------------------------------------------------------------
-- Modified By   : kumar, kumaravadivel.shanmugam@in.tesco.com
-- Modified Date : 08-Feb-2010
-- Mod Ref       : DefNBS16113
-- Description   : Modified the function PUBLISH_CHANGES to remove the zone level publication
--                 call for price changes which is moved to RPM_ZONE_FUTURE_RETAIL_SQL.
---------------------------------------------------------------------------------------
-- Mod By      : Sajjad Ahmed / Murali
-- Mod Date    : 09-Feb-2010
-- Def Ref     : NBS00016274
-- Mod Details : Modified INSERT_CLEARANCE function for implementing mod N25 for clearances
-----------------------------------------------------------------------------------------

   -- Mod By      : Sajjad Ahmed
-- Mod Date    : 09-Mar-2010
-- Def Ref     : NBS00016476
-- Mod Details : Added TSL_VALID_PROMO_FOR_LM_MERGE function implementing Mod N25 for promotion
-----------------------------------------------------------------------------------------
-- Mod By       : Bernard Craddock / Kiran Chalamala
-- Mod Date     : 12-Mar-2010
-- Mod Ref      : Price Changes Performance Changes
-- Mod Details  : Modified TSL_PUSH_BACK() method.
-----------------------------------------------------------------------------------------------------------
-- Mod By      : Raghuveer P R
-- Mod Date    : 06-Apr-2010
-- Def Ref     : CR291
-- Mod Details : Modified function INSERT_PROMO to call RPM_FUTURE_RETAIL_GTT_SQL.TSL_RECLS_MERGE_PROMOTION
--               in case the Item Reclassfication RPM batch runs.
-----------------------------------------------------------------------------------------------------------
-- Mod By      : Raghuveer P R
-- Mod Date    : 06-Apr-2010
-- Def Ref     : 3.5e to 3.5e merge (MrgNBS017012)
-----------------------------------------------------------------------------------------------------------
-- Mod By     : Kiran Chalamala / Bernard C
-- Mod Date   : 19-Apr-2010
-- Defect ID  : NBS00017378
-- Mod Details: To improve the performance (Merged By sarath)
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By      : Debadatta Patra
-- Mod Date    : 23-MAY-2010
-- Def Ref     : NBS00017599
-- Mod Details : Modified for avoiding 'No seed record' problem while cancelling an active promotion.
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By      : Hema M
-- Mod Date    : 11-JUN-2010
-- Def Ref     : NBS00017875
-- Mod Details : Modified for backporting the defect NBS00017599
-----------------------------------------------------------------------------------------
-- Mod By       : Deepali Rakshe
-- Date         : 28-Jun-2010
-- Mod Ref      : SIT Def NBS00017899
-- Description  : Modified publish_changes to publish multi buy promotion messages
----------------------------------------------------------------------------------------
-- Mod By      : Debadatta Patra
-- Mod Date    : 01-JUL-2010
-- Def Ref     : NBS00018090
-- Mod Details : Modified for updating end date and tsl_state of a promotion only after
--         successfully cancellation of an active promotion
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By      : Debadatta Patra
-- Mod Date    : 12-JUL-2010
-- Def Ref     : NBS00018252
-- Mod Details : Modified for backporting the defect NBS00018090
-----------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
-- Mod By      : Debadatta Patra
-- Mod Date    : 15-Jul-2010
-- Defect ID   : PrfNBS017910
-- Mod Details : Modified for puttting the cancellation process to back ground (publication)
-------------------------------------------------------------------------------------------------------------------------------
-- Mod By      : Rajendra Bondili
-- Mod Date    : 11-Aug-2010
-- Defect ID   : DefBS018642
-- Mod Details : Modified the method update_promo_end_date()
-------------------------------------------------------------------------------------------------------------------------------
-- Mod By      : Vikash Prasad
-- Mod Date    : 02-SEP-2010
-- MOD Ref     : CR301
-- Mod Details : Modified function GET_PROMOTION_OBJECT to fetch the change amount based on the system option
--               tsl_complex_retail_usg_thr_qty.
-----------------------------------------------------------------------------------------
-- Mod By     : Jini Moses,jini.moses@in.tesco.com
-- Mod Date   : 15-Sep-2010
-- Mod Ref    : NBS00019162
-- Mod Details: Modified publish_changes to restrict publication for clearance based on system option.
-----------------------------------------------------------------------------------------------------------
-- Mod By      : Vikash Prasad
-- Mod Date    : 23-Sep-2010
-- Def Ref     : CR357a
-- Mod Details : Modified SAVE_CLEARANCE_RESET function for switching off chunk ind for clearances.
-----------------------------------------------------------------------------------------
-- Mod By       : Jini Moses , jini.moses@in.tesco.com
-- Mod Date     : 28-Sep-2010
-- Mod Ref      : NBS00019261
-- Mod Details  : Modified hint in VALIDATE_CLEARANCE_DATES.
---------------------------------------------------------------------------------------
-- Mod By       : Jini Moses , jini.moses@in.tesco.com
-- Mod Date     : 01-Oct-2010
-- Mod Ref      : NBS00019337
-- Mod Details  : Modified INSERT_CLEARANCE. Removed validation of RPM_CC_POST_RESET_CLR since
--                overlapping clearances were failing in this validation.
---------------------------------------------------------------------------------------
-- Mod By      : Vikash Prasad
-- Mod Date    : 01-Oct-2010
-- Def Ref     : NBS00019337a
-- Mod Details :Modified INSERT_CLEARANCE. call to RPM_CC_POST_RESET_CLR depending upon CR357 system option.
-----------------------------------------------------------------------------------------
-- Mod By      : Jini Moses/Vikash Prasad
-- Mod Date    : 02-Oct-2010
-- Def Ref     : NBS00019337b
-- Mod Details :Modified INSERT_CLEARANCE. call to RPM_CLR_RESET depending upon CR357 system option.
-----------------------------------------------------------------------------------------
-- Mod By      : Rajendra Bondili
-- Mod Date    : 14-Oct-2010
-- Def Ref     : NBS00019380b
-- Mod Details :Reverting back 19380,19380a changes as it is not required for production right now.
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By      : Hema M
-- Mod Date    : 22-OCT-2010
-- Def Ref     : NBS00019516
-- Mod Details : Modified to prevent pubication of redundant message when there
--               Overlapping price change with existing complex promotion.
-----------------------------------------------------------------------------------------
-- Mod By      : Manoj Auku
-- Mod Date    : 22-Oct-2010
-- Def Ref     : NBS00019517
-- Mod Details : Modified TSL_RPM_NIL_TPND_INSERT funtion inorder to prevent duplicate records in
--               TSL_RPM_PROMO_COMP_TPND Table.
-----------------------------------------------------------------------------------------
-- Mod By:Rajendra Bondili
-- Mod Date    : 24-Nov-2010
-- Def Ref     : Merge from 3.5b to Prdsi
-- Mod Details : No Changes were present.
--
-----------------------------------------------------------------------------------------
-- Mod By       : RK
-- Mod Date     : 21-Aug-2013
-- Mod Ref      : CR479
-- Mod Details  : Modified two functions PRICE_EVENT_REMOVE(), SCHEDULE_LOCATION_MOVE()
--                when calling RPM_CC_EXE_QUERY_RULES.EXECUTE() function to pass additional parameters
--                I_price_event_ids, I_price_event_type so that CR479 CC Rule2 can be called with additional
--                parameters.
------------------------------------------------------------------------------------------------------------
--                            PRIVATE GLOBALS                                 --
--------------------------------------------------------------------------------
   TYPE rf_dates IS TABLE OF DATE
      INDEX BY BINARY_INTEGER;

   lp_persist_ind            VARCHAR2 (30);
   lp_push_back_start_date   DATE;
   lp_specific_item_loc      NUMBER        := 0;
   lp_rib_trans_id           NUMBER;
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
   lp_chunk_ind              NUMBER        := NULL;

--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End

   --------------------------------------------------------------------------------
--                          PRIVATE PROTOTYPES                                --
--------------------------------------------------------------------------------
   FUNCTION init_globals (o_cc_error_tbl OUT conflict_check_error_tbl)
      RETURN NUMBER;

--
-- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 Begin
   FUNCTION merge_into_timeline (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_override_tbl       IN       obj_varchar_desc_table
   )
      RETURN NUMBER;

-- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 End

   --
   FUNCTION insert_price_change (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION insert_clearance (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION update_clearance_reset (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION insert_promo (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

-- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 Begin
   FUNCTION update_promo_end_date (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_override_tbl       IN       obj_varchar_desc_table
   )
      RETURN NUMBER;

-- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 End
--
   FUNCTION remove_from_timeline (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_rib_trans_id       IN       NUMBER
   )
      RETURN NUMBER;

--
   FUNCTION remove_price_change (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_rib_trans_id       IN       NUMBER
   )
      RETURN NUMBER;

   FUNCTION remove_clearance (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_rib_trans_id       IN       NUMBER
   )
      RETURN NUMBER;

   FUNCTION remove_promotion (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_rib_trans_id       IN       NUMBER
   )
      RETURN NUMBER;

--
   FUNCTION get_promotion_object (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      o_promo_recs         OUT      obj_rpm_cc_promo_tbl,
      i_promo_ids          IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION validate_promotion_for_merge (
      o_cc_error_tbl   OUT      conflict_check_error_tbl,
      i_promo_ids      IN       obj_numeric_id_table
   )
      RETURN NUMBER;

--Added for defect fix NBS00016476 by Sajjad Ahmed on 09-Mar-2010 Begin
   FUNCTION tsl_valid_promo_for_lm_merge (
      o_cc_error_tbl   OUT      conflict_check_error_tbl,
      i_promo_ids      IN       obj_numeric_id_table
   )
      RETURN NUMBER;

--Added for defect fix NBS00016476 by Sajjad Ahmed on 09-NOV-2009 End
   FUNCTION ignore_approved_exceptions (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION ignore_approved_loc_moves (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION process_exclusion_event (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION roll_forward (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION publish_changes (
      o_cc_error_tbl              OUT      conflict_check_error_tbl,
      i_rib_trans_id              IN       NUMBER,
      i_remove_price_event_ids    IN       obj_numeric_id_table,
      i_remove_price_event_type   IN       VARCHAR2,
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
      i_price_event_type          IN       VARCHAR2
   )
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End
   RETURN NUMBER;

   /*Modified by Debadatta Patra for PrfNBS017910 on 15-07-2010 - SU/TU/MU End */
   FUNCTION push_back_error_rows (
      io_cc_error_tbl   IN OUT   conflict_check_error_tbl
   )
      RETURN NUMBER;

--

   --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
   FUNCTION push_back (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      l_price_event_id     IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End

   -- Abhijeet Changes #5242 Start
   FUNCTION push_back_all (o_cc_error_tbl OUT conflict_check_error_tbl)
      RETURN NUMBER;

-- Abhijeet Chages ends #5242
   FUNCTION consolidate_cc_error_tbl (
      o_cc_error_tbl    OUT      conflict_check_error_tbl,
      i_cc_error_tbl1   IN       conflict_check_error_tbl,
      i_cc_error_tbl2   IN       conflict_check_error_tbl
   )
      RETURN NUMBER;

--05-Nov-2008 Murali CR167 and  173  Begin
--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
   FUNCTION tsl_zone_push_back (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      l_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
   RETURN NUMBER;

--05-Nov-2008 Murali CR167 and  173  End

   -- Mod N25 Vikash Prasad 25-May-2009 BEGIN
   FUNCTION tsl_push_back (o_cc_error_tbl OUT conflict_check_error_tbl)
      RETURN NUMBER;

-- Mod N25 Vikash Prasad 25-May-2009 END

   ---- Abhijeet FST Defect fix DefNBS014255  Starts ---
   FUNCTION tsl_rpm_nil_tpnd_insert (
      o_cc_error_tbl   OUT   conflict_check_error_tbl
   )
      RETURN NUMBER;

---- Abhijeet FST Defect fix DefNBS014255  Ends   ---

   --Added for defect fix NBS00015345 by Debadatta on 17-NOV-2009 Begin
--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
   FUNCTION tsl_push_back_remove (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      l_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION tsl_zone_push_back_remove (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      l_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER;

--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
--Added for defect fix NBS00015345 by Debadatta on 17-NOV-2009 End

   --------------------------------------------------------------------------------
--                          PUBLIC PROCEDURES                                 --
--------------------------------------------------------------------------------
   FUNCTION price_event_insert (
      o_cc_error_tbl        OUT      conflict_check_error_tbl,
      i_price_event_ids     IN       obj_numeric_id_table,
      i_price_event_type    IN       VARCHAR2,
      i_rib_trans_id        IN       NUMBER,
      i_persist_ind         IN       VARCHAR2,
      i_override_tbl        IN       obj_varchar_desc_table,
      i_specific_item_loc   IN       NUMBER DEFAULT 0,
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
      i_chunk_ind           IN       NUMBER DEFAULT 0
   )
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End
   RETURN NUMBER
   IS
      l_program                   VARCHAR2 (100)
                                := 'RPM_FUTURE_RETAIL_SQL.PRICE_EVENT_INSERT';
--
      l_remove_price_event_ids    obj_numeric_id_table                := NULL;
      l_remove_price_event_type   VARCHAR2 (2)                        := NULL;
--
      l_price_event_ids           obj_numeric_id_table;
      l_nc_price_event_ids        obj_numeric_id_table;
--
      l_cc_error_tbl              conflict_check_error_tbl;
--
      l_gtt_count                 NUMBER;
----------------------------------------------------------------------------------------
-- 14-Aug-2007 Sajjad Ahmed M.N,sajjad.ahmed@in.tesco.com - MOD 501 p2              Begin
----------------------------------------------------------------------------------------
      o_function_name             rpm_conflict_query_control.conflict_query_function_name%TYPE
                                                                      := NULL;
----------------------------------------------------------------------------------------
-- 14-Aug-2007 Sajjad Ahmed M.N,sajjad.ahmed@in.tesco.com - MOD 501 p2             End
----------------------------------------------------------------------------------------
--05-Nov-2008 Murali CR167 and  173  Begin
      o_error_message             VARCHAR2 (255);
--12-Dec-2008 Sourabh ST DefNBS010377 BEGIN
      l_rpm_zone_lvl_ind          system_options.tsl_rpm_zone_lvl_ind%TYPE;
--12-Dec-2008 Sourabh ST DefNBS010377 END
--05-Nov-2008 Murali CR167 and  173  End
--
--04-Nov-2009 Ameet Acharya NBS00015168  BEGIN
      l_active_error_tbl          conflict_check_error_tbl;

      CURSOR c_ids
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids)
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE EXISTS (SELECT 1
                          FROM rpm_future_retail_gtt
                         WHERE price_event_id = VALUE (ids));

--
      CURSOR c_nc
      IS
         SELECT VALUE (ids) price_event_id
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
         MINUS
         SELECT ccet.price_event_id
           FROM TABLE (CAST (l_cc_error_tbl AS conflict_check_error_tbl)) ccet;

--
      CURSOR c_state
      IS
         SELECT conflict_check_error_rec (ccet.price_event_id,
                                          NULL,
                                          ccet.ERROR_TYPE,
                                          ccet.error_string
                                         )
           FROM rpm_promo_comp_detail rpcd,
                (SELECT DISTINCT ids.price_event_id, ids.ERROR_TYPE,
                                 ids.error_string
                            FROM TABLE
                                    (CAST
                                        (l_cc_error_tbl AS conflict_check_error_tbl
                                        )
                                    ) ids) ccet
          WHERE ccet.price_event_id = rpcd.rpm_promo_comp_detail_id
            AND rpcd.state = 'pcd.active';
--
--04-Nov-2009 Ameet Acharya NBS00015168  End
   BEGIN
      --
      o_cc_error_tbl := conflict_check_error_tbl ();
      lp_persist_ind := i_persist_ind;
      lp_specific_item_loc := i_specific_item_loc;
      lp_rib_trans_id := i_rib_trans_id;
      --Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
      lp_chunk_ind := i_chunk_ind;

       --Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End
       --
       -- Return with success if Future Retail GTT is empty.
       -- e.g approving a zone level promotion where the zone is empty
      --CR357a, Vikash Prasad on 23-Sep-2010 -- Begin
      IF i_price_event_type = 'CL'
      THEN
         lp_chunk_ind := 0;
      END IF;

      --CR357a, Vikash Prasad on 23-Sep-2010 -- End
      OPEN c_ids;

      FETCH c_ids
      BULK COLLECT INTO l_price_event_ids;

      CLOSE c_ids;

      IF l_price_event_ids IS NULL OR l_price_event_ids.COUNT = 0
      THEN
         RETURN 1;
      END IF;

      --
      IF init_globals (o_cc_error_tbl) = 0
      THEN
         RETURN 0;
      END IF;

      --

      -- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 Begin
      IF merge_into_timeline (o_cc_error_tbl,
                              l_price_event_ids,
                              i_price_event_type,
                              i_override_tbl
                             ) = 0
      THEN
         RETURN 0;
      END IF;

-- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 End
----------------------------------------------------------------------------------------
-- 14-Aug-2007 Sajjad Ahmed M.N,sajjad.ahmed@in.tesco.com - MOD 501              Begin
----------------------------------------------------------------------------------------
-- murali
/*   if I_price_event_type='PC' then
      --3-Jan-2008 WiproEnabler/RK        Forward Porting Begin
      --Call the below method based on each price Event id
      FOR i IN 1..I_price_event_ids.COUNT LOOP
          if RPM_EXE_CC_QUERY_RULES.EXECUTE(O_cc_error_tbl,
                           I_override_tbl, I_price_event_ids(i), O_function_name) = 0 then
              if O_function_name != 'TSL_RPM_CC_PMP.VALIDATE' then
                  if PUSH_BACK_ERROR_ROWS(O_cc_error_tbl) = 0 then
                    return 0;
                  end if;
              end if;
              return 0;
          end if;
      END LOOP;
      --3-Jan-2008 WiproEnabler/RK        Forward Porting End
   else



   -- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 Begin
   if I_price_event_type NOT IN (RPM_CONFLICT_LIBRARY.SIMPLE_UPDATE,
                                 RPM_CONFLICT_LIBRARY.THRESHOLD_UPDATE, RPM_CONFLICT_LIBRARY.BUYGET_UPDATE,
                    RPM_CONFLICT_LIBRARY.MULTIBUY_UPDATE) then

      if RPM_EXE_CC_QUERY_RULES.EXECUTE(O_cc_error_tbl,
                                     I_override_tbl) = 0 then
         if PUSH_BACK_ERROR_ROWS(O_cc_error_tbl) = 0 then
            return 0;
         end if;
         --
         return 0;
      end if;
   end if;
   -- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 End
   end if;*/

      ----------------------------------------------------------------------------------------
-- 14-Aug-2007 Sajjad Ahmed M.N,sajjad.ahmed@in.tesco.com - MOD 501              End
----------------------------------------------------------------------------------------
-- OLD CODE IS COMMENTED for 501 b changes by sajjad
--   if RPM_EXE_CC_QUERY_RULES.EXECUTE(O_cc_error_tbl,
--                                     I_override_tbl) = 0 then
--      if PUSH_BACK_ERROR_ROWS(O_cc_error_tbl) = 0 then
--         return 0;
--      end if;
--      --
--      return 0;
--   end if;
----------------------------------------------------------------------------------------
   --
      IF push_back_error_rows (o_cc_error_tbl) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF o_cc_error_tbl IS NOT NULL AND o_cc_error_tbl.COUNT > 0
      THEN
         l_cc_error_tbl := o_cc_error_tbl;
      END IF;

      --
      -- If RPM_FUTURE_RETAIL_GTT is empty, it means all price events have conflicts.
      --    Stop the process.
      --
      SELECT COUNT (*)
        INTO l_gtt_count
        FROM rpm_future_retail_gtt;

      IF l_gtt_count = 0
      THEN
         o_cc_error_tbl := l_cc_error_tbl;

         --04-Nov-2009 Ameet Acharya NBS00015168  BEGIN
         OPEN c_state;

         FETCH c_state
         BULK COLLECT INTO l_active_error_tbl;

         CLOSE c_state;

         IF l_active_error_tbl IS NOT NULL AND l_active_error_tbl.COUNT > 0
         THEN
            o_cc_error_tbl := l_active_error_tbl;
         END IF;

         --04-Nov-2009 Ameet Acharya NBS00015168  End
         RETURN 1;
      END IF;

      --
      IF i_persist_ind = 'Y'
      THEN
         --
         -- Approve Clearance Reset and Push Back Clearance
         --
         IF i_price_event_type = rpm_conflict_library.clearance
         THEN
            IF rpm_clearance_gtt_sql.remove_conflicts (o_cc_error_tbl,
                                                       l_cc_error_tbl
                                                      ) = 0
            THEN
               RETURN 0;
            END IF;

            --
            IF rpm_clearance_gtt_sql.approve_clearance_reset
                                                         (o_cc_error_tbl,
                                                          i_price_event_ids,
                                                          lp_specific_item_loc
                                                         ) = 0
            THEN
               RETURN 0;
            END IF;

            --
            IF rpm_clearance_gtt_sql.push_back (o_cc_error_tbl) = 0
            THEN
               RETURN 0;
            END IF;
         END IF;

         -- Changes By Abhijeet #5242 Start
         IF    (o_cc_error_tbl IS NULL)
            OR (o_cc_error_tbl IS NOT NULL AND o_cc_error_tbl.COUNT = 0)
         THEN
            IF i_price_event_type = rpm_conflict_library.new_clearance_reset
            THEN
               IF rpm_clearance_gtt_sql.push_back (o_cc_error_tbl) = 0
               THEN
                  RETURN 0;
               END IF;
            END IF;
         END IF;

         -- Chages By Abhijeet #5242 Ends

         ---------Defect fix Changes By Abhijeet  DefNBS014255 Starts ------------
-- murali
/*     if RPM_BULK_CC_ACTIONS_SQL.IS_NEW_ITEM_LOC_IND ='Y' then
          if TSL_RPM_NIL_TPND_INSERT(O_cc_error_tbl) = 0 then
             return 0;
         end if;
      end if;*/
      ----Defect fix Changes By Abhijeet  DefNBS014255    Ends-----------------

         --
      --
      --
      -- murali
    --Modified For N25 By Debadatta Patra on 26-May-2009 Begin.
/*    if RPM_BULK_CC_THREADING_SQL.IS_LOC_MOVE_PUBLISH != 'Y' then
    --Modified For N25 By Debadatta Patra on 26-May-2009 Ends.
 \*Modified by Debadatta Patra for PrfNBS017910 on 15-07-2010 - SU/TU/MU Start *\
      if PUBLISH_CHANGES(O_cc_error_tbl,
                         I_rib_trans_id,
                         L_remove_price_event_ids,
                         L_remove_price_event_type,
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
                         I_price_event_type) = 0 then
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End
         return 0;
      end if;
    --Modified For N25 By Debadatta Patra on 26-May-2009 Begin.
    end if;*/
    --Modified For N25 By Debadatta Patra on 26-May-2009 Ends.
      --
         IF rpm_purge_future_retail_sql.PURGE (o_cc_error_tbl) = 0
         THEN
            RETURN 0;
         END IF;

         --
         lp_push_back_start_date := get_vdate ();

         --

         --05-Nov-2008 Murali CR167 and  173  Begin
         --12-Dec-2008 Sourabh ST DefNBS010377 BEGIN
         IF system_options_sql.tsl_get_rpm_zone_lvl_ind (o_error_message,
                                                         l_rpm_zone_lvl_ind
                                                        ) = FALSE
         THEN
            RETURN 0;
         END IF;

         IF l_rpm_zone_lvl_ind = 'Y'
         THEN
            --12-Dec-2008 Sourabh ST DefNBS010377 END
             --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
            IF tsl_zone_push_back (o_cc_error_tbl,
                                   i_price_event_ids,
                                   i_price_event_type
                                  ) = 0
            THEN
               RETURN 0;
            END IF;
         --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
         END IF;

         --05-Nov-2008 Murali CR167 and  173  End

         --- Changes By Abhijeet Start #5242
-- if LP_specific_item_loc is 2 then NewItemLocBatch process is calling PUSH_BACK_ALL.
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
         IF lp_chunk_ind = 0
         THEN
            IF (lp_specific_item_loc = 2)
            THEN
               IF push_back_all (o_cc_error_tbl) = 0
               THEN
                  RETURN 0;
               END IF;
            ELSE
               --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
               IF push_back (o_cc_error_tbl,
                             i_price_event_ids,
                             i_price_event_type
                            ) = 0
               THEN
                  RETURN 0;
               END IF;
            END IF;

  --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
--- Changes By Abhijeet Start #5242

            --
            -- Update RPM_ZONE_FUTURE_RETAIL for Primary Zone Level Price change
            --
            IF i_price_event_type = rpm_conflict_library.price_change
            THEN
               --
               IF l_cc_error_tbl IS NOT NULL AND l_cc_error_tbl.COUNT > 0
               THEN
                  OPEN c_nc;

                  FETCH c_nc
                  BULK COLLECT INTO l_nc_price_event_ids;

                  CLOSE c_nc;
               ELSE
                  l_nc_price_event_ids := i_price_event_ids;
               END IF;

               --
               IF rpm_zone_future_retail_sql.price_change_insert
                                                        (o_cc_error_tbl,
                                                         l_nc_price_event_ids,
                                                         --11-Feb-2008 TescoHsc/Praveen        Mod: N75 Begin
                                                         i_rib_trans_id
                                                        ) = 0
               THEN
                  --11-Feb-2008 TescoHsc/Praveen        Mod: N75 End
                  RETURN 0;
               END IF;
            END IF;
         END IF;                                        -- if LP_chunk_ind = 0
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End
      END IF;

      --
      o_cc_error_tbl := l_cc_error_tbl;
      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END price_event_insert;

--------------------------------------------------------------------------------
   FUNCTION price_event_remove (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_rib_trans_id       IN       NUMBER,
      i_persist_ind        IN       VARCHAR2,
      i_override_tbl       IN       obj_varchar_desc_table,
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
      i_chunk_ind          IN       NUMBER DEFAULT 0
   )
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End
   RETURN NUMBER
   IS
      l_program                   VARCHAR2 (100)
                                := 'RPM_FUTURE_RETAIL_SQL.PRICE_EVENT_REMOVE';
--
      l_remove_price_event_ids    obj_numeric_id_table   := i_price_event_ids;
      l_remove_price_event_type   VARCHAR2 (2)          := i_price_event_type;
--
      l_price_event_ids           obj_numeric_id_table;
--
      l_cc_error_tbl              conflict_check_error_tbl;
--
      l_gtt_count                 NUMBER;
--
--05-Nov-2008 Murali CR167 and  173  Begin
      o_error_message             VARCHAR2 (255);
--12-Dec-2008 Sourabh ST DefNBS010377 BEGIN
      l_rpm_zone_lvl_ind          system_options.tsl_rpm_zone_lvl_ind%TYPE;

--12-Dec-2008 Sourabh ST DefNBS010377 END
--05-Nov-2008 Murali CR167 and  173  End
      CURSOR c_ids
      IS
         SELECT /*+ cardinality(ids 100) */
                VALUE (ids)
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE EXISTS (SELECT 1
                          FROM rpm_future_retail_gtt
                         WHERE price_event_id = VALUE (ids));
--
   BEGIN
      o_cc_error_tbl := conflict_check_error_tbl ();
      lp_rib_trans_id := i_rib_trans_id;
      --Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
      lp_chunk_ind := i_chunk_ind;

      --Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End
      --
      -- Return with success if Future Retail GTT is empty.
      -- e.g approving a zone level promotion where the zone is empty
      OPEN c_ids;

      FETCH c_ids
      BULK COLLECT INTO l_price_event_ids;

      CLOSE c_ids;

      IF l_price_event_ids IS NULL OR l_price_event_ids.COUNT = 0
      THEN
         RETURN 1;
      END IF;

      --
      IF init_globals (o_cc_error_tbl) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF remove_from_timeline (o_cc_error_tbl,
                               l_price_event_ids,
                               i_price_event_type,
                               i_rib_trans_id
                              ) = 0
      THEN
         RETURN 0;
      END IF;

      --

      -- Modified by RK for CR479 on 21-Aug-2013 - Start
      -- Function call has been changed to add additional parameters which were used
      -- for incorporating CR479 CC rule2 call.
      IF rpm_exe_cc_query_rules.EXECUTE (o_cc_error_tbl,
                                         i_override_tbl,
                                         i_price_event_type,
                                         l_price_event_ids
                                        ) = 0
      THEN
         -- Modified by RK for CR479 on 21-Aug-2013 - End
         IF push_back_error_rows (o_cc_error_tbl) = 0
         THEN
            RETURN 0;
         END IF;

         --
         RETURN 0;
      END IF;

      --
      IF push_back_error_rows (o_cc_error_tbl) = 0
      THEN
         RETURN 0;
      END IF;

      --
      --
      IF o_cc_error_tbl IS NOT NULL AND o_cc_error_tbl.COUNT > 0
      THEN
         l_cc_error_tbl := o_cc_error_tbl;
      END IF;

      --
      -- If RPM_FUTURE_RETAIL_GTT is empty, it means all price events have conflicts.
      --    Stop the process.
      --
      SELECT COUNT (*)
        INTO l_gtt_count
        FROM rpm_future_retail_gtt;

      IF l_gtt_count = 0
      THEN
         RETURN 1;
      END IF;

      --
      IF i_persist_ind = 'Y'
      THEN
         /*Modified by Debadatta Patra for PrfNBS017910 on 15-07-2010 - SU/TU/MU Start */
         IF publish_changes (o_cc_error_tbl,
                             i_rib_trans_id,
                             l_remove_price_event_ids,
                             l_remove_price_event_type,
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
                             i_price_event_type
                            ) = 0
         THEN
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End
            RETURN 0;
         END IF;

         /*Modified by Debadatta Patra for PrfNBS017910 on 15-07-2010 - SU/TU/MU End */
              --
         IF rpm_purge_future_retail_sql.PURGE (o_cc_error_tbl) = 0
         THEN
            RETURN 0;
         END IF;

         --
         lp_push_back_start_date := get_vdate ();

         --

         --05-Nov-2008 Murali CR167 and  173  Begin
         --12-Dec-2008 Sourabh ST DefNBS010377 BEGIN
         IF system_options_sql.tsl_get_rpm_zone_lvl_ind (o_error_message,
                                                         l_rpm_zone_lvl_ind
                                                        ) = FALSE
         THEN
            RETURN 0;
         END IF;

         IF l_rpm_zone_lvl_ind = 'Y'
         THEN
            --12-Dec-2008 Sourabh ST DefNBS010377 END
             --Modified for defect fix NBS00015345 by Debadatta on 17-NOV-2009 Begin
             --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
            IF tsl_zone_push_back_remove (o_cc_error_tbl,
                                          l_remove_price_event_ids,
                                          i_price_event_type
                                         ) = 0
            THEN
               RETURN 0;
            END IF;
         --Modified for defect fix NBS00015345 by Debadatta on 17-NOV-2009 End
         END IF;

         --05-Nov-2008 Murali CR167 and 173  End

         --Modified for defect fix NBS00015345 by Debadatta on 17-NOV-2009 Begin
         IF tsl_push_back_remove (o_cc_error_tbl,
                                  l_remove_price_event_ids,
                                  i_price_event_type
                                 ) = 0
         THEN
            RETURN 0;
         END IF;

         --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
         --Modified for defect fix NBS00015345 by Debadatta on 17-NOV-2009 End

         --
         -- Push Back Clearance
         --
         IF i_price_event_type = rpm_conflict_library.clearance
         THEN
            --
            IF rpm_clearance_gtt_sql.push_back (o_cc_error_tbl) = 0
            THEN
               RETURN 0;
            END IF;
         --
         END IF;

         --
         IF i_price_event_type = rpm_conflict_library.price_change
         THEN
            IF rpm_zone_future_retail_sql.price_change_remove
                                                          (o_cc_error_tbl,
                                                           i_price_event_ids,
                                                           --11-Feb-2008 TescoHsc/Praveen        Mod: N75 Begin
                                                           i_rib_trans_id
                                                          ) = 0
            THEN
               --11-Feb-2008 TescoHsc/Praveen        Mod: N75 End
               RETURN 0;
            END IF;
         END IF;
      END IF;

      --
      o_cc_error_tbl := l_cc_error_tbl;
      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END price_event_remove;

--------------------------------------------------------------------------------
   FUNCTION schedule_location_move (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_location_move_id   IN       rpm_location_move.location_move_id%TYPE,
      i_rib_trans_id       IN       rpm_price_event_payload.transaction_id%TYPE,
      i_persist_ind        IN       VARCHAR2,
      i_override_tbl       IN       obj_varchar_desc_table
   )
      RETURN NUMBER
   IS
      l_program             VARCHAR2 (100)
                                     := 'RPM_LOCATION_MOVE_SCHEDULE.SCHEDULE';
      l_lm_rec              rpm_location_move%ROWTYPE                 := NULL;
      l_call_sequence       NUMBER;
      l_gtt_count           NUMBER;
      -- Mod N25 Vikash Prasad 25-May-2009 BEGIN
      o_error_message       VARCHAR2 (255);
      l_rpm_loc_move_chgs   system_options.tsl_rpm_loc_move_chgs%TYPE;
      l_rpm_loc_move_msg    system_options.tsl_rpm_loc_move_msg%TYPE;
      -- Mod N25 Vikash Prasad 25-May-2009 END
      l_price_event_ids     obj_numeric_id_table;

      CURSOR c_location_move
      IS
         SELECT *
           FROM rpm_location_move
          WHERE location_move_id = i_location_move_id;

      --Get all Price event ids which are required for conflict check
      CURSOR c_price_event_ids
      IS
         SELECT DISTINCT price_event_id
                    FROM rpm_future_retail_gtt;
   -- Modified by RK for CR479 on 21-Aug-2013 - End
   BEGIN
      lp_rib_trans_id := i_rib_trans_id;

      IF init_globals (o_cc_error_tbl) = 0
      THEN
         RETURN 0;
      END IF;

      --
      OPEN c_location_move;

      FETCH c_location_move
       INTO l_lm_rec;

      CLOSE c_location_move;

      IF l_lm_rec.location_move_id IS NULL
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('NO_DATA_FOUND',
                                                              NULL,
                                                              NULL,
                                                              NULL
                                                             )
                                         )
               );
         RETURN 0;
      END IF;

      --
      IF rpm_future_retail_gtt_sql.merge_location_move (o_cc_error_tbl,
                                                        l_lm_rec
                                                       ) = 0
      THEN
         RETURN 0;
      END IF;

      -- Mod N25 Vikash Prasad 25-May-2009 BEGIN
      IF system_options_sql.tsl_get_rpm_loc_move_chgs (o_error_message,
                                                       l_rpm_loc_move_chgs
                                                      ) = FALSE
      THEN
         RETURN 0;
      END IF;

      IF system_options_sql.tsl_get_rpm_loc_move_msg (o_error_message,
                                                      l_rpm_loc_move_msg
                                                     ) = FALSE
      THEN
         RETURN 0;
      END IF;

      IF l_rpm_loc_move_chgs = 'Y'
      THEN
         IF l_rpm_loc_move_msg = 'Y'
         THEN
            IF rpm_cc_publish.tsl_stage_lm_scrub_messages
                                                     (o_cc_error_tbl,
                                                      i_rib_trans_id,
                                                      l_lm_rec.old_zone_id,
                                                      l_lm_rec.LOCATION,
                                                      l_lm_rec.loc_type,
                                                      l_lm_rec.effective_date
                                                     ) = 0
            THEN
               RETURN 0;
            END IF;
         END IF;

         IF rpm_future_retail_gtt_sql.tsl_location_move_scrub (o_cc_error_tbl,
                                                               l_lm_rec,
                                                               i_rib_trans_id
                                                              ) = 0
         THEN
            RETURN 0;
         END IF;
      ELSE
         IF rpm_cc_publish.stage_lm_scrub_messages (o_cc_error_tbl,
                                                    i_rib_trans_id,
                                                    l_lm_rec.old_zone_id,
                                                    l_lm_rec.LOCATION,
                                                    l_lm_rec.loc_type,
                                                    l_lm_rec.effective_date
                                                   ) = 0
         THEN
            RETURN 0;
         END IF;

         IF rpm_future_retail_gtt_sql.location_move_scrub (o_cc_error_tbl,
                                                           l_lm_rec,
                                                           i_rib_trans_id
                                                          ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      -- Mod N25 Vikash Prasad 25-May-2009 END
      SELECT COUNT (1)
        INTO l_gtt_count
        FROM rpm_future_retail_gtt;

      l_call_sequence := 1;

      IF l_gtt_count > 0
      THEN
         -- Defect fix NBS00013973(N25) By Debadatta Patra 25-July-2009 BEGIN
         IF l_rpm_loc_move_chgs = 'Y'
         THEN
            IF rpm_roll_forward_sql.EXECUTE
                                         (o_cc_error_tbl,
                                          l_lm_rec.location_move_id,
                                          rpm_conflict_library.location_move,
                                          l_lm_rec.effective_date,
                                          l_lm_rec.effective_date,
                                          l_call_sequence,
                                          l_gtt_count
                                         ) = 0
            THEN
               IF push_back_error_rows (o_cc_error_tbl) = 0
               THEN
                  RETURN 0;
               END IF;

               --
               RETURN 0;
            END IF;
         ELSE
            IF rpm_roll_forward_sql.EXECUTE
                                         (o_cc_error_tbl,
                                          l_lm_rec.location_move_id,
                                          rpm_conflict_library.location_move,
                                          l_lm_rec.effective_date,
                                          NULL,
                                          l_call_sequence,
                                          l_gtt_count
                                         ) = 0
            THEN
               IF push_back_error_rows (o_cc_error_tbl) = 0
               THEN
                  RETURN 0;
               END IF;

               --
               RETURN 0;
            END IF;
         END IF;
      -- Defect fix NBS00013973(N25) By Debadatta Patra 25-July-2009 End
      END IF;

      -- Modified by RK for CR479 on 21-Aug-2013 - Start
      --Added additional parameters to Execute query rules to cater
      --CR479 conflict rule2 to be called
      --Get the price event ids which will be sent to Conflict rule check
      OPEN c_price_event_ids;

      FETCH c_price_event_ids
      BULK COLLECT INTO l_price_event_ids;

      CLOSE c_price_event_ids;

      --
      IF rpm_exe_cc_query_rules.EXECUTE (o_cc_error_tbl,
                                         i_override_tbl,
                                         rpm_conflict_library.location_move,
                                         l_price_event_ids
                                        ) = 0
      THEN
         -- Modified by RK for CR479 on 21-Aug-2013 - End
         IF push_back_error_rows (o_cc_error_tbl) = 0
         THEN
            RETURN 0;
         END IF;

         --
         RETURN 0;
      END IF;

      IF i_persist_ind = 'Y'
      THEN
         IF rpm_purge_future_retail_sql.PURGE (o_cc_error_tbl) = 0
         THEN
            RETURN 0;
         END IF;

         lp_push_back_start_date := l_lm_rec.effective_date;

         -- Mod N25 Vikash Prasad 25-May-2009 BEGIN
         IF l_rpm_loc_move_chgs = 'Y'
         THEN
            IF tsl_push_back (o_cc_error_tbl) = 0
            THEN
               RETURN 0;
            END IF;
         ELSE
            --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
            IF push_back (o_cc_error_tbl,
                          obj_numeric_id_table (-999),
                          rpm_conflict_library.location_move
                         ) = 0
            THEN
               RETURN 0;
            END IF;
         --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
         END IF;
      -- Mod N25 Vikash Prasad 25-May-2009 END
      END IF;

      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END schedule_location_move;

--------------------------------------------------------------------------------

   --------------------------------------------------------------------------------
--                         PRIVATE PROCEDURES                                 --
--------------------------------------------------------------------------------
   FUNCTION init_globals (o_cc_error_tbl OUT conflict_check_error_tbl)
      RETURN NUMBER
   IS
      l_program     VARCHAR2 (100) := 'RPM_FUTURE_RETAIL_SQL.INIT_GLOBALS';
      l_error_msg   VARCHAR2 (255) := NULL;
   BEGIN
      IF rpm_system_options_sql.reset_globals (l_error_msg) = FALSE
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
                 (conflict_check_error_rec (NULL,
                                            NULL,
                                            rpm_conflict_library.plsql_error,
                                            l_error_msg
                                           )
                 );
         RETURN 0;
      END IF;

      --
      IF rpm_system_options_def_sql.reset_globals (l_error_msg) = FALSE
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
                 (conflict_check_error_rec (NULL,
                                            NULL,
                                            rpm_conflict_library.plsql_error,
                                            l_error_msg
                                           )
                 );
         RETURN 0;
      END IF;

      --
      IF dates_sql.reset_globals (l_error_msg) = FALSE
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
                 (conflict_check_error_rec (NULL,
                                            NULL,
                                            rpm_conflict_library.plsql_error,
                                            l_error_msg
                                           )
                 );
         RETURN 0;
      END IF;

      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END init_globals;

--------------------------------------------------------------------------------
   FUNCTION merge_into_timeline (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_override_tbl       IN       obj_varchar_desc_table
   )
      RETURN NUMBER
   IS
      l_program   VARCHAR2 (100)
                               := 'RPM_FUTURE_RETAIL_SQL.MERGE_INTO_TIMELINE';
--
   BEGIN
      IF i_price_event_type = rpm_conflict_library.price_change
      THEN
         IF insert_price_change (o_cc_error_tbl,
                                 i_price_event_ids,
                                 i_price_event_type
                                ) = 0
         THEN
            RETURN 0;
         END IF;
      --
      ELSIF i_price_event_type IN
              (rpm_conflict_library.clearance,
               rpm_conflict_library.clearance_reset,
               --Chages By Abhijeet #5242
               rpm_conflict_library.new_clearance_reset
              )
      THEN
         IF i_price_event_type = rpm_conflict_library.clearance
         THEN
            IF insert_clearance (o_cc_error_tbl,
                                 i_price_event_ids,
                                 i_price_event_type
                                ) = 0
            THEN
               RETURN 0;
            END IF;
         -- Chages by Abhijeet #5242
         ELSIF i_price_event_type IN
                 (rpm_conflict_library.clearance_reset,
                  rpm_conflict_library.new_clearance_reset
                 )
         THEN
            IF update_clearance_reset (o_cc_error_tbl,
                                       i_price_event_ids,
                                       i_price_event_type
                                      ) = 0
            THEN
               RETURN 0;
            END IF;
         END IF;
--23-Nov-2007 WiproEnabler/RK        Mod:93 Begin
   --Including the MultiBuy promotion component
      ELSIF i_price_event_type IN
              (rpm_conflict_library.simple_promotion,
               rpm_conflict_library.threshold_promotion,
               rpm_conflict_library.buyget_promotion,
               rpm_conflict_library.multibuy_promotion
              )
      THEN
         --23-Nov-2007 WiproEnabler/RK        Mod:93 End
         IF insert_promo (o_cc_error_tbl,
                          i_price_event_ids,
                          i_price_event_type
                         ) = 0
         THEN
            RETURN 0;
         END IF;
      --23-Nov-2007 WiproEnabler/RK        Mod:93 Begin
        --Including the MultiBuy promotion component
      ELSIF i_price_event_type IN
              (rpm_conflict_library.simple_update,
               rpm_conflict_library.threshold_update,
               rpm_conflict_library.buyget_update,
               rpm_conflict_library.multibuy_update
              )
      THEN
         --23-Nov-2007 WiproEnabler/RK        Mod:93 End

         -- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 Begin
         IF update_promo_end_date (o_cc_error_tbl,
                                   i_price_event_ids,
                                   i_price_event_type,
                                   i_override_tbl
                                  ) = 0
         THEN
            RETURN 0;
         END IF;
      -- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 End
      END IF;

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END merge_into_timeline;

--------------------------------------------------------------------------------
   FUNCTION insert_price_change (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program             VARCHAR2 (100)
                               := 'RPM_FUTURE_RETAIL_SQL.INSERT_PRICE_CHANGE';
--
      l_exclusion_ids       obj_numeric_id_table;
      l_regular_ids         obj_numeric_id_table;
      l_parent_rpcs         obj_num_num_date_tbl;
      l_removable_parents   obj_num_num_date_tbl;
      l_invalid_pc          BOOLEAN                  := FALSE;
      l_pc_ids_need_merge   obj_numeric_id_table;
--
      l_cc_error_tbl        conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();
--
      l_rf_cc_error_tbl     conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();

--
      CURSOR c_check_pc
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (SELECT 1
                              FROM rpm_price_change rpc
                             WHERE rpc.price_change_id = VALUE (ids));

--
      CURSOR c_exclusion
      IS
         SELECT /*+ cardinality(ids 1000) */
                rpc.price_change_id
           FROM rpm_price_change rpc,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rpc.price_change_id = VALUE (ids)
            AND rpc.change_type = rpm_conflict_library.retail_exclude;

--
      CURSOR c_regular
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
         MINUS
         SELECT /*+ cardinality(exc 1000) */
                VALUE (exc) ID
           FROM TABLE (CAST (l_exclusion_ids AS obj_numeric_id_table)) exc;

--
      CURSOR c_need_merge
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
         MINUS
         SELECT /*+ cardinality(con 1000) */
                con.price_event_id ID
           FROM TABLE (CAST (l_cc_error_tbl AS conflict_check_error_tbl)) con;

--
      CURSOR c_removable_parents
      IS
         SELECT /*+ cardinality(parents 1000) cardinality(ids 1000)*/
                obj_num_num_date_rec (parents.numeric_col1,
                                      parents.numeric_col2,
                                      NULL
                                     )
           FROM rpm_price_change rpc,
                TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) parents,
                TABLE (CAST (l_pc_ids_need_merge AS obj_numeric_id_table)) ids
          WHERE parents.numeric_col1 = VALUE (ids)
            AND rpc.price_change_id = parents.numeric_col1
            AND rpc.effective_date !=
                                    NVL (parents.date_col, rpc.effective_date);
--
   BEGIN
      --
      -- Stop the whole process if any of the price change id is not valid
      --
      FOR rec IN c_check_pc
      LOOP
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec
                             (NULL,
                              NULL,
                              rpm_conflict_library.plsql_error,
                              sql_lib.create_msg (   'INVALID_PRICE_EVENT - '
                                                  || rec.ID,
                                                  NULL,
                                                  NULL,
                                                  NULL
                                                 )
                             )
               );
         l_invalid_pc := TRUE;
      END LOOP;

      --
      IF l_invalid_pc
      THEN
         RETURN 0;
      END IF;

      --
      -- Get Exclusion Price Changes
      --
      OPEN c_exclusion;

      FETCH c_exclusion
      BULK COLLECT INTO l_exclusion_ids;

      CLOSE c_exclusion;

      --
      -- Get Regular Price Changes
      --
      IF l_exclusion_ids IS NOT NULL AND l_exclusion_ids.COUNT != 0
      THEN
         OPEN c_regular;

         FETCH c_regular
         BULK COLLECT INTO l_regular_ids;

         CLOSE c_regular;

         --
         -- Process the Exclusion
         --
         IF process_exclusion_event (o_cc_error_tbl,
                                     l_exclusion_ids,
                                     i_price_event_type
                                    ) = 0
         THEN
            RETURN 0;
         END IF;
      --
      ELSE
         l_regular_ids := i_price_event_ids;
      END IF;

      --
      -- Process the Regular
      --
      IF l_regular_ids IS NULL OR l_regular_ids.COUNT = 0
      THEN
         RETURN 1;
      END IF;

      --
      IF ignore_approved_exceptions (o_cc_error_tbl,
                                     l_regular_ids,
                                     i_price_event_type
                                    ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF ignore_approved_loc_moves (o_cc_error_tbl,
                                    l_regular_ids,
                                    i_price_event_type
                                   ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF rpm_future_retail_gtt_sql.get_affected_parent (o_cc_error_tbl,
                                                        i_price_event_ids,
                                                        i_price_event_type,
                                                        l_parent_rpcs
                                                       ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      INSERT INTO rpm_rf_dates_gtt
         SELECT /*+ cardinality(ids 1000) index(rpc pk_rpm_price_change) */
                rpc.price_change_id, rpc.effective_date
           FROM rpm_price_change rpc,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rpc.price_change_id = VALUE (ids)
         UNION ALL
         SELECT t.numeric_col1, t.date_col
           FROM TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) t
          WHERE t.date_col IS NOT NULL;

      --
      IF rpm_cc_one_pc_per_day.VALIDATE (o_cc_error_tbl, l_parent_rpcs) = 0
      THEN
         RETURN 0;
      END IF;

      --
      l_cc_error_tbl := o_cc_error_tbl;

      --
      OPEN c_need_merge;

      FETCH c_need_merge
      BULK COLLECT INTO l_pc_ids_need_merge;

      CLOSE c_need_merge;

      --
      -- If there is nothing to be merge then EXIT
      --
      IF l_pc_ids_need_merge IS NULL OR l_pc_ids_need_merge.COUNT = 0
      THEN
         o_cc_error_tbl := l_cc_error_tbl;
         RETURN 1;
      END IF;

      --
      -- Defect fix NBS00015404(N25) By Debadatta Patra on 24-Nov-2009 BEGIN
      IF rpm_bulk_cc_threading_sql.is_loc_move_ind = 'Y'
      THEN
         IF rpm_future_retail_gtt_sql.tsl_lm_merge_price_change
                                                         (o_cc_error_tbl,
                                                          l_pc_ids_need_merge
                                                         ) = 0
         THEN
            RETURN 0;
         END IF;
      ELSE
         IF rpm_future_retail_gtt_sql.merge_price_change (o_cc_error_tbl,
                                                          l_pc_ids_need_merge
                                                         ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      -- Defect fix NBS00015404(N25) By Debadatta Patra on 24-Nov-2009 End
      --
      IF l_parent_rpcs IS NOT NULL AND l_parent_rpcs.COUNT > 0
      THEN
         --
         OPEN c_removable_parents;

         FETCH c_removable_parents
         BULK COLLECT INTO l_removable_parents;

         CLOSE c_removable_parents;

         --
         IF l_removable_parents IS NOT NULL
            AND l_removable_parents.COUNT != 0
         THEN
            --
            IF rpm_future_retail_gtt_sql.remove_event
                                           (o_cc_error_tbl,
                                            l_removable_parents,
                                            rpm_conflict_library.price_change
                                           ) = 0
            THEN
               RETURN 0;
            END IF;
         END IF;
      END IF;

      --
      IF roll_forward (l_rf_cc_error_tbl,
                       l_pc_ids_need_merge,
                       i_price_event_type
                      ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF l_rf_cc_error_tbl IS NOT NULL AND l_rf_cc_error_tbl.COUNT > 0
      THEN
         --
         IF l_cc_error_tbl IS NULL
         THEN
            l_cc_error_tbl := conflict_check_error_tbl ();
         END IF;

         --
         FOR i IN 1 .. l_rf_cc_error_tbl.COUNT
         LOOP
            l_cc_error_tbl.EXTEND;
            l_cc_error_tbl (l_cc_error_tbl.COUNT) := l_rf_cc_error_tbl (i);
         END LOOP;
      END IF;

      --
      o_cc_error_tbl := l_cc_error_tbl;
      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END insert_price_change;

--------------------------------------------------------------------------------
   FUNCTION validate_clearance_dates (
      o_cc_error_tbl       IN OUT   conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
--
      l_program          VARCHAR2 (100)
                          := 'RPM_FUTURE_RETAIL_SQL.VALIDATE_CLEARANCE_DATES';
--
      l_validation_tbl   obj_itemloc_validation_tbl;
--
      l_error_rec        conflict_check_error_rec   := NULL;
      l_error_tbl        conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();
      lo_error_tbl       conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();
      t_error_tbl        conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();

      CURSOR c_existing_markdown
      IS
         SELECT conflict_check_error_rec
                                        (rfrg.price_event_id,
                                         rfrg.future_retail_id,
                                         rpm_conflict_library.conflict_error,
                                         'validate_clearence_date_err'
                                        )
           -- NBS00019261, Gary/Jini, 28-Sep-2010 - Begin
         FROM   (SELECT /*+ use_nl(rc)*/
                        -- NBS00019261, Gary/Jini, 28-Sep-2010 - End
                        rc.*
                   FROM rpm_clearance_gtt rc,
                        TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)
                              ) ids,
                        TABLE (CAST (l_error_tbl AS conflict_check_error_tbl)) ccet
                  WHERE rc.clearance_id = VALUE (ids)
                    AND ccet.price_event_id != VALUE (ids)
                    AND (   rc.out_of_stock_date IS NOT NULL
                         OR rc.reset_date IS NOT NULL
                        )) rc1,
                rpm_clearance rc2,
                rpm_future_retail_gtt rfrg
          WHERE rc1.price_event_id = rfrg.price_event_id
            AND rfrg.clearance_id IS NOT NULL
            AND rfrg.clearance_id = rc2.clearance_id
            AND (       rc1.out_of_stock_date IS NOT NULL
                    AND rc1.out_of_stock_date <= rc2.effective_date
                 OR     rc1.reset_date IS NOT NULL
                    AND rc1.reset_date <= rc2.effective_date
                )
            AND rc2.state = lp_pc_approved_state_code
            AND rc2.effective_date >= rc1.effective_date
            AND rc2.reset_ind = 0;
--    and rownum = 1;
   BEGIN
      IF o_cc_error_tbl IS NOT NULL AND o_cc_error_tbl.COUNT > 0
      THEN
         l_error_tbl := o_cc_error_tbl;
      ELSE
         l_error_rec := conflict_check_error_rec (-99999, NULL, NULL, NULL);
         l_error_tbl := conflict_check_error_tbl (l_error_rec);
      END IF;

      OPEN c_existing_markdown;

      FETCH c_existing_markdown
      BULK COLLECT INTO lo_error_tbl;

      CLOSE c_existing_markdown;

      IF lo_error_tbl IS NOT NULL AND lo_error_tbl.COUNT > 0
      THEN
         IF o_cc_error_tbl IS NULL OR o_cc_error_tbl.COUNT = 0
         THEN
            o_cc_error_tbl := lo_error_tbl;
         ELSE
            FOR i IN 1 .. lo_error_tbl.COUNT
            LOOP
               o_cc_error_tbl.EXTEND;
               o_cc_error_tbl (o_cc_error_tbl.COUNT) := lo_error_tbl (i);
            END LOOP;
         END IF;
      END IF;

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END validate_clearance_dates;

--------------------------------------------------------------------
   FUNCTION insert_clearance (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program             VARCHAR2 (100)
                                  := 'RPM_FUTURE_RETAIL_SQL.INSERT_CLEARANCE';
--
      l_exclusion_ids       obj_numeric_id_table;
      l_regular_ids         obj_numeric_id_table;
      l_parent_rcs          obj_num_num_date_tbl;
      l_removable_parents   obj_num_num_date_tbl;
      l_invalid_cl          BOOLEAN                                 := FALSE;
      l_pc_ids_need_merge   obj_numeric_id_table;
      o_validation_tbl      obj_itemloc_validation_tbl;
--
      l_cc_error_tbl        conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();
--
      l_rf_cc_error_tbl     conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();
--
-- NBS00019337a, Vikash Prasad, 01-Oct-2010 -- Begin
      l_tsl_cr357_ind       rpm_system_options.tsl_cr357_ind%TYPE   := NULL;
      l_error_message       VARCHAR2 (10000);

-- NBS00019337a, Vikash Prasad, 01-Oct-2010 -- End
      CURSOR c_check_cl
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (SELECT 1
                              FROM rpm_clearance rc
                             WHERE rc.clearance_id = VALUE (ids));

--
      CURSOR c_exclusion
      IS
         SELECT /*+ cardinality(ids 1000) */
                rc.clearance_id
           FROM rpm_clearance_gtt rc,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rc.price_event_id = VALUE (ids)
            AND rc.clearance_id = VALUE (ids)
            AND rc.change_type = rpm_conflict_library.retail_exclude;

--
      CURSOR c_regular
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
         MINUS
         SELECT /*+ cardinality(exc 1000) */
                VALUE (exc) ID
           FROM TABLE (CAST (l_exclusion_ids AS obj_numeric_id_table)) exc;

--
      CURSOR c_removable_parents
      IS
         SELECT /*+ cardinality(ids 1000) */
                obj_num_num_date_rec (parents.numeric_col1,
                                      parents.numeric_col2,
                                      NULL
                                     )
           FROM TABLE (CAST (l_parent_rcs AS obj_num_num_date_tbl)) parents
          WHERE parents.numeric_col2 IS NOT NULL;

--
      CURSOR c_need_merge
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
         MINUS
         SELECT /*+ cardinality(con 1000) */
                con.price_event_id ID
           FROM TABLE (CAST (l_cc_error_tbl AS conflict_check_error_tbl)) con;
--
   BEGIN
      -- NBS00019337a, Vikash Prasad, 01-Oct-2010 -- Begin
      IF rpm_system_options_sql.get_tsl_cr357_ind (l_tsl_cr357_ind,
                                                   l_error_message
                                                  ) = FALSE
      THEN
         RETURN 0;
      END IF;

      -- NBS00019337a, Vikash Prasad, 01-Oct-2010 -- End
      --
      -- Stop the whole process if any of the clearance id is not valid
      --
      FOR rec IN c_check_cl
      LOOP
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec
                             (NULL,
                              NULL,
                              rpm_conflict_library.plsql_error,
                              sql_lib.create_msg (   'INVALID_PRICE_EVENT - '
                                                  || rec.ID,
                                                  NULL,
                                                  NULL,
                                                  NULL
                                                 )
                             )
               );
         l_invalid_cl := TRUE;
      END LOOP;

      --
      IF l_invalid_cl
      THEN
         RETURN 0;
      END IF;

      --
      -- Do what the ClearancePriceChangeSaveResetAction.java used to do
      --
      IF rpm_clearance_gtt_sql.populate_gtt (o_cc_error_tbl,
                                             i_price_event_ids) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF lp_persist_ind = 'Y'
      THEN
         --
         --Added For N25/Defect By Murali  on Feb-09-2010 / Sajjad Ahmed  defect #16274 Starts
         IF rpm_bulk_cc_threading_sql.is_loc_move_ind = 'Y'
         THEN
            IF rpm_clearance_gtt_sql.tsl_save_lm_clearance_reset
                                                        (o_cc_error_tbl,
                                                         i_price_event_ids,
                                                         lp_specific_item_loc
                                                        ) = 0
            THEN
               RETURN 0;
            END IF;
         ELSE
            --Added For N25/Defect By Murali  on Feb-09-2010 / Sajjad Ahmed  defect #16274 Starts
            IF rpm_clearance_gtt_sql.save_clearance_reset
                                                        (o_cc_error_tbl,
                                                         i_price_event_ids,
                                                         lp_specific_item_loc
                                                        ) = 0
            THEN
               RETURN 0;
            END IF;
         --Added For N25/Defect By Murali  on Feb-09-2010 / Sajjad Ahmed  defect #16274 Ends
         END IF;
      --Added For N25/Defect By Murali  on Feb-09-2010 / Sajjad Ahmed  defect #16274 Ends
       --
      END IF;

      --
      IF validate_clearance_dates (o_cc_error_tbl,
                                   i_price_event_ids,
                                   i_price_event_type
                                  ) = 0
      THEN
         RETURN 0;
      END IF;

      -- Get Exclusion Clearances
      --
      OPEN c_exclusion;

      FETCH c_exclusion
      BULK COLLECT INTO l_exclusion_ids;

      CLOSE c_exclusion;

      --
      -- Get Regular Clearances
      --
      IF l_exclusion_ids IS NOT NULL AND l_exclusion_ids.COUNT != 0
      THEN
         OPEN c_regular;

         FETCH c_regular
         BULK COLLECT INTO l_regular_ids;

         CLOSE c_regular;

         --
         -- Process the Exclusion
         --
         IF process_exclusion_event (o_cc_error_tbl,
                                     l_exclusion_ids,
                                     i_price_event_type
                                    ) = 0
         THEN
            RETURN 0;
         END IF;
      --
      ELSE
         l_regular_ids := i_price_event_ids;
      END IF;

      --
      -- Process the Regular
      --
      IF l_regular_ids IS NULL OR l_regular_ids.COUNT = 0
      THEN
         RETURN 1;
      END IF;

      --
      IF ignore_approved_exceptions (o_cc_error_tbl,
                                     l_regular_ids,
                                     i_price_event_type
                                    ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF ignore_approved_loc_moves (o_cc_error_tbl,
                                    l_regular_ids,
                                    i_price_event_type
                                   ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF rpm_future_retail_gtt_sql.get_affected_parent (o_cc_error_tbl,
                                                        i_price_event_ids,
                                                        i_price_event_type,
                                                        l_parent_rcs
                                                       ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF l_parent_rcs IS NOT NULL AND l_parent_rcs.COUNT > 0
      THEN
         --
         OPEN c_removable_parents;

         FETCH c_removable_parents
         BULK COLLECT INTO l_removable_parents;

         CLOSE c_removable_parents;

         --
         IF l_removable_parents IS NOT NULL
            AND l_removable_parents.COUNT != 0
         THEN
            --
            IF rpm_future_retail_gtt_sql.remove_event
                                              (o_cc_error_tbl,
                                               l_removable_parents,
                                               rpm_conflict_library.clearance
                                              ) = 0
            THEN
               RETURN 0;
            END IF;
         END IF;
      END IF;

      --
      -- NBS00019337b, Jini/Vikash Prasad, 02-Oct-2010 -- Begin
      IF (l_tsl_cr357_ind = 0)
      THEN
         IF rpm_clr_reset.VALIDATE (o_cc_error_tbl) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      -- NBS00019337b, Jini/Vikash Prasad, 02-Oct-2010 -- End
       --
      l_cc_error_tbl := o_cc_error_tbl;

      --
      OPEN c_need_merge;

      FETCH c_need_merge
      BULK COLLECT INTO l_pc_ids_need_merge;

      CLOSE c_need_merge;

      --
      -- If there is nothing to be merge then EXIT
      --
      IF l_pc_ids_need_merge IS NULL OR l_pc_ids_need_merge.COUNT = 0
      THEN
         o_cc_error_tbl := l_cc_error_tbl;
         RETURN 1;
      END IF;

      --
      IF rpm_future_retail_gtt_sql.upd_clearance_reset (o_cc_error_tbl,
                                                        i_price_event_ids
                                                       ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      o_cc_error_tbl := l_cc_error_tbl;

      --
      -- NBS00019337, Jini Moses, 01-Oct-2010 - Begin
      -- NBS00019337a, Vikash Prasad, 01-Oct-2010 -- Begin
      IF (l_tsl_cr357_ind = 0)
      THEN
         IF rpm_cc_post_reset_clr.VALIDATE (o_cc_error_tbl,
                                            i_price_event_ids) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      -- NBS00019337a, Vikash Prasad, 01-Oct-2010 -- End
       -- NBS00019337, Jini Moses, 01-Oct-2010 - End
       --
      l_cc_error_tbl := o_cc_error_tbl;

      --
      OPEN c_need_merge;

      FETCH c_need_merge
      BULK COLLECT INTO l_pc_ids_need_merge;

      CLOSE c_need_merge;

      --
      -- If there is nothing to be merge then EXIT
      --
      IF l_pc_ids_need_merge IS NULL OR l_pc_ids_need_merge.COUNT = 0
      THEN
         o_cc_error_tbl := l_cc_error_tbl;
         RETURN 1;
      END IF;

      --
      IF rpm_cc_one_clr_per_day.VALIDATE (o_cc_error_tbl, i_price_event_ids) =
                                                                             0
      THEN
         RETURN 0;
      END IF;

      --
      l_cc_error_tbl := o_cc_error_tbl;

      --
      OPEN c_need_merge;

      FETCH c_need_merge
      BULK COLLECT INTO l_pc_ids_need_merge;

      CLOSE c_need_merge;

      --
      -- If there is nothing to be merge then EXIT
      --
      IF l_pc_ids_need_merge IS NULL OR l_pc_ids_need_merge.COUNT = 0
      THEN
         o_cc_error_tbl := l_cc_error_tbl;
         RETURN 1;
      END IF;

       --
      -- Defect fix NBS00015249(N25) By Sajjad Ahmed 11-Jan-2010 Begin
      IF rpm_bulk_cc_threading_sql.is_loc_move_ind = 'Y'
      THEN
         IF rpm_future_retail_gtt_sql.tsl_lm_merge_clearance
                                              (o_cc_error_tbl,
                                               i_price_event_ids,
                                               rpm_conflict_library.start_ind
                                              ) = 0
         THEN
            RETURN 0;
         END IF;
      ELSE
         IF rpm_future_retail_gtt_sql.merge_clearance
                                              (o_cc_error_tbl,
                                               i_price_event_ids,
                                               rpm_conflict_library.start_ind
                                              ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      -- Defect fix NBS00015249(N25) By Sajjad Ahmed 11-Jan-2010 End
       --
      INSERT INTO rpm_rf_dates_gtt
         SELECT /*+ cardinality(ids 1000) index(rc pk_rpm_clearance) */
                VALUE (ids), rc.effective_date
           FROM rpm_clearance rc,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rc.clearance_id = VALUE (ids)
         UNION ALL
         SELECT parents.numeric_col1, parents.date_col
           FROM TABLE (CAST (l_parent_rcs AS obj_num_num_date_tbl)) parents
          WHERE parents.date_col IS NOT NULL;

      --
      IF roll_forward (l_rf_cc_error_tbl,
                       l_pc_ids_need_merge,
                       i_price_event_type
                      ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF l_rf_cc_error_tbl IS NOT NULL AND l_rf_cc_error_tbl.COUNT > 0
      THEN
         --
         IF l_cc_error_tbl IS NULL
         THEN
            l_cc_error_tbl := conflict_check_error_tbl ();
         END IF;

         --
         FOR i IN 1 .. l_rf_cc_error_tbl.COUNT
         LOOP
            l_cc_error_tbl.EXTEND;
            l_cc_error_tbl (l_cc_error_tbl.COUNT) := l_rf_cc_error_tbl (i);
         END LOOP;
      END IF;

      --
      o_cc_error_tbl := l_cc_error_tbl;
      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END insert_clearance;

--------------------------------------------------------------------------------
   FUNCTION update_clearance_reset (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program             VARCHAR2 (100)
                            := 'RPM_FUTURE_RETAIL_SQL.UPDATE_CLEARANCE_RESET';
--
      l_cc_error_tbl        conflict_check_error_tbl;
      l_cl_ids_to_process   obj_numeric_id_table;

--
      CURSOR c_check_cl
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (SELECT 1
                              FROM rpm_clearance rc
                             WHERE rc.clearance_id = VALUE (ids));

--
      CURSOR c_ids_to_process
      IS
         SELECT VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
         MINUS
         SELECT ccet.price_event_id
           FROM TABLE (CAST (l_cc_error_tbl AS conflict_check_error_tbl)) ccet;
--
   BEGIN
   --
   -- Stop the whole process if any of the price change id is not valid
   --
--Changes By Abhijeet #5242 Start
      IF i_price_event_type != rpm_conflict_library.new_clearance_reset
      THEN
         FOR rec IN c_check_cl
         LOOP
            o_cc_error_tbl :=
               conflict_check_error_tbl
                  (conflict_check_error_rec
                                   (NULL,
                                    NULL,
                                    rpm_conflict_library.plsql_error,
                                    sql_lib.create_msg (   'NO_DATA_FOUND - '
                                                        || rec.ID,
                                                        NULL,
                                                        NULL,
                                                        NULL
                                                       )
                                   )
                  );
            RETURN 0;
         END LOOP;

         --
         -- Populate RPM_CLEARANCE_GTT
         --
         IF rpm_clearance_gtt_sql.populate_gtt (o_cc_error_tbl,
                                                i_price_event_ids
                                               ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;                                             -- added by Abhijeet

      --
      IF ignore_approved_exceptions (o_cc_error_tbl,
                                     i_price_event_ids,
                                     i_price_event_type
                                    ) = 0
      THEN
         RETURN 0;
      END IF;

      IF ignore_approved_loc_moves (o_cc_error_tbl,
                                    i_price_event_ids,
                                    i_price_event_type
                                   ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF rpm_clr_reset.VALIDATE (o_cc_error_tbl) = 0
      THEN
         RETURN 0;
      END IF;

      --
      l_cc_error_tbl := o_cc_error_tbl;

      --
      OPEN c_ids_to_process;

      FETCH c_ids_to_process
      BULK COLLECT INTO l_cl_ids_to_process;

      CLOSE c_ids_to_process;

   --
--Added By Abhijeet
      IF i_price_event_type = rpm_conflict_library.new_clearance_reset
      THEN
         IF rpm_future_retail_gtt_sql.upd_new_clearance_reset
                                                         (o_cc_error_tbl,
                                                          l_cl_ids_to_process
                                                         ) = 0
         THEN
            RETURN 0;
         END IF;
      ELSE
         IF rpm_future_retail_gtt_sql.upd_clearance_reset
                                                         (o_cc_error_tbl,
                                                          l_cl_ids_to_process
                                                         ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;                                             -- added by Abhijeet

      --
      IF roll_forward (o_cc_error_tbl, l_cl_ids_to_process,
                       i_price_event_type) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF rpm_cc_publish.stage_clr_rst_remove_messages (o_cc_error_tbl,
                                                       lp_rib_trans_id
                                                      ) = 0
      THEN
         RETURN 0;
      END IF;

      o_cc_error_tbl := l_cc_error_tbl;
      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END update_clearance_reset;

--------------------------------------------------------------------------------
   FUNCTION insert_promo (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program             VARCHAR2 (100)
                                      := 'RPM_FUTURE_RETAIL_SQL.INSERT_PROMO';
--
      l_invalid_pr          BOOLEAN                  := FALSE;
      l_parent_rpcs         obj_num_num_date_tbl;
      l_removable_parents   obj_num_num_date_tbl;
      l_pc_ids_need_merge   obj_numeric_id_table;
--
      l_promo_recs          obj_rpm_cc_promo_tbl;
--
      l_cc_error_tbl        conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();
--
      l_rf_cc_error_tbl     conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();

--
      CURSOR c_check_simple
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (
                            SELECT 1
                              FROM rpm_promo_comp_simple rpcs
                             WHERE rpcs.rpm_promo_comp_detail_id =
                                                                  VALUE (ids));

--
      CURSOR c_check_threshold
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (
                            SELECT 1
                              FROM rpm_promo_comp_threshold rpct
                             WHERE rpct.rpm_promo_comp_detail_id =
                                                                  VALUE (ids));

--
      CURSOR c_check_buyget
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (
                            SELECT 1
                              FROM rpm_promo_comp_buy_get rpbg
                             WHERE rpbg.rpm_promo_comp_detail_id =
                                                                  VALUE (ids));

--
--15-Jan-2008 Lakshmi Natarajan Forward Porting Mod:93 Begin
      CURSOR c_check_multibuy
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (
                          SELECT 1
                            FROM tsl_rpm_promo_comp_m_b trpcmb
                           WHERE trpcmb.rpm_promo_comp_detail_id =
                                                                  VALUE (ids));

--15-Jan-2008 Lakshmi Natarajan Forward Porting Mod:93 End
--
      CURSOR c_removable_parents
      IS
         SELECT /*+ cardinality(ids 1000) */
                obj_num_num_date_rec (parents.numeric_col1,
                                      parents.numeric_col2,
                                      NULL
                                     )
           FROM TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) parents
          WHERE parents.numeric_col2 IS NOT NULL;

--
      CURSOR c_need_merge
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
         MINUS
         SELECT /*+ cardinality(con 1000) */
                con.price_event_id ID
           FROM TABLE (CAST (l_cc_error_tbl AS conflict_check_error_tbl)) con;
--
   BEGIN
      --
      -- Stop the whole process if any of the price change id is not valid
      --
      IF i_price_event_type = rpm_conflict_library.simple_promotion
      THEN
         FOR rec IN c_check_simple
         LOOP
            o_cc_error_tbl :=
               conflict_check_error_tbl
                  (conflict_check_error_rec
                             (NULL,
                              NULL,
                              rpm_conflict_library.plsql_error,
                              sql_lib.create_msg (   'INVALID_PRICE_EVENT - '
                                                  || rec.ID,
                                                  NULL,
                                                  NULL,
                                                  NULL
                                                 )
                             )
                  );
            l_invalid_pr := TRUE;
         END LOOP;
      --
      ELSIF i_price_event_type = rpm_conflict_library.threshold_promotion
      THEN
         FOR rec IN c_check_threshold
         LOOP
            o_cc_error_tbl :=
               conflict_check_error_tbl
                  (conflict_check_error_rec
                             (NULL,
                              NULL,
                              rpm_conflict_library.plsql_error,
                              sql_lib.create_msg (   'INVALID_PRICE_EVENT - '
                                                  || rec.ID,
                                                  NULL,
                                                  NULL,
                                                  NULL
                                                 )
                             )
                  );
            l_invalid_pr := TRUE;
         END LOOP;
      --
      ELSIF i_price_event_type = rpm_conflict_library.buyget_promotion
      THEN
         FOR rec IN c_check_buyget
         LOOP
            o_cc_error_tbl :=
               conflict_check_error_tbl
                  (conflict_check_error_rec
                             (NULL,
                              NULL,
                              rpm_conflict_library.plsql_error,
                              sql_lib.create_msg (   'INVALID_PRICE_EVENT - '
                                                  || rec.ID,
                                                  NULL,
                                                  NULL,
                                                  NULL
                                                 )
                             )
                  );
            l_invalid_pr := TRUE;
         END LOOP;
        --
      --15-Jan-2008 Lakshmi Natarajan Forward Porting Mod:93 Begin
      ELSIF i_price_event_type = rpm_conflict_library.multibuy_promotion
      THEN
         FOR rec IN c_check_multibuy
         LOOP
            o_cc_error_tbl :=
               conflict_check_error_tbl
                  (conflict_check_error_rec
                             (NULL,
                              NULL,
                              rpm_conflict_library.plsql_error,
                              sql_lib.create_msg (   'INVALID_PRICE_EVENT - '
                                                  || rec.ID,
                                                  NULL,
                                                  NULL,
                                                  NULL
                                                 )
                             )
                  );
            l_invalid_pr := TRUE;
         END LOOP;
      --15-Jan-2008 Lakshmi Natarajan Forward Porting Mod:93 End
      END IF;

      --
      IF l_invalid_pr
      THEN
         RETURN 0;
      END IF;

      --
      IF ignore_approved_loc_moves (o_cc_error_tbl,
                                    i_price_event_ids,
                                    i_price_event_type
                                   ) = 0
      THEN
         RETURN 0;
      END IF;

      --

      --23-Nov-2007 WiproEnabler/RK        Mod:93 Begin
      --if I_price_event_type != RPM_CONFLICT_LIBRARY.BUYGET_PROMOTION then
      --Including the MultiBuy promotion component
      IF i_price_event_type NOT IN
            (rpm_conflict_library.buyget_promotion,
             rpm_conflict_library.multibuy_promotion
            )
      THEN
         --23-Nov-2007 WiproEnabler/RK        Mod:93 End
         IF ignore_approved_exceptions (o_cc_error_tbl,
                                        i_price_event_ids,
                                        i_price_event_type
                                       ) = 0
         THEN
            RETURN 0;
         END IF;

         --
         IF rpm_future_retail_gtt_sql.get_affected_parent (o_cc_error_tbl,
                                                           i_price_event_ids,
                                                           i_price_event_type,
                                                           l_parent_rpcs
                                                          ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      --
      INSERT INTO rpm_rf_dates_gtt
         SELECT /*+ cardinality(ids 1000) */
                rpcd.rpm_promo_comp_detail_id, rpcd.start_date
           FROM rpm_promo_comp_detail rpcd,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rpcd.rpm_promo_comp_detail_id = VALUE (ids)
         UNION ALL
         SELECT /*+ cardinality(ids 1000) */
                rpcd.rpm_promo_comp_detail_id, rpcd.end_date
           FROM rpm_promo_comp_detail rpcd,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rpcd.rpm_promo_comp_detail_id = VALUE (ids)
            AND rpcd.end_date IS NOT NULL
         UNION ALL
         SELECT /*+ cardinality(ids 1000) */
                rpcd.rpm_promo_comp_detail_id, rpcd.end_date + 1
           FROM rpm_promo_comp_detail rpcd,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rpcd.rpm_promo_comp_detail_id = VALUE (ids)
            AND rpcd.end_date IS NOT NULL;

      --
      IF l_parent_rpcs IS NOT NULL AND l_parent_rpcs.COUNT > 0
      THEN
         --
         INSERT INTO rpm_rf_dates_gtt
            SELECT /*+ cardinality(ids 1000) */
                   ids.numeric_col1, rpcd.start_date
              FROM rpm_promo_comp_detail rpcd,
                   TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) ids
             WHERE rpcd.rpm_promo_comp_detail_id = ids.numeric_col2
            UNION ALL
            SELECT /*+ cardinality(ids 1000) */
                   ids.numeric_col1, rpcd.end_date
              FROM rpm_promo_comp_detail rpcd,
                   TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) ids
             WHERE rpcd.rpm_promo_comp_detail_id = ids.numeric_col2
               AND rpcd.end_date IS NOT NULL
            UNION ALL
            SELECT /*+ cardinality(ids 1000) */
                   ids.numeric_col1, rpcd.end_date + 1
              FROM rpm_promo_comp_detail rpcd,
                   TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) ids
             WHERE rpcd.rpm_promo_comp_detail_id = ids.numeric_col2
               AND rpcd.end_date IS NOT NULL;

         --
         OPEN c_removable_parents;

         FETCH c_removable_parents
         BULK COLLECT INTO l_removable_parents;

         CLOSE c_removable_parents;

         --
         IF l_removable_parents IS NOT NULL AND l_removable_parents.COUNT != 0
         THEN
            --
            IF rpm_future_retail_gtt_sql.remove_event (o_cc_error_tbl,
                                                       l_removable_parents,
                                                       i_price_event_type
                                                      ) = 0
            THEN
               RETURN 0;
            END IF;
         END IF;
      END IF;

   --
-- murali
/*   --Added for defect fix NBS00016476 by Sajjad Ahmed on 09-Mar-2010 Begin
   if RPM_BULK_CC_THREADING_SQL.IS_LOC_MOVE_IND ='Y' then
    if TSL_VALID_PROMO_FOR_LM_MERGE(O_cc_error_tbl,
                                   I_price_event_ids) = 0 then
      return 0;
   end if;
   else
     if VALIDATE_PROMOTION_FOR_MERGE(O_cc_error_tbl,
                                   I_price_event_ids) = 0 then
      return 0;
   end if;
  end if;*/
  --Added for defect fix NBS00016476 by Sajjad Ahmed on 09-Mar-2010 End
   --
      l_cc_error_tbl := o_cc_error_tbl;

      --
      OPEN c_need_merge;

      FETCH c_need_merge
      BULK COLLECT INTO l_pc_ids_need_merge;

      CLOSE c_need_merge;

      --
      -- If there is nothing to be merge then EXIT
      --
      IF l_pc_ids_need_merge IS NULL OR l_pc_ids_need_merge.COUNT = 0
      THEN
         o_cc_error_tbl := l_cc_error_tbl;
         RETURN 1;
      END IF;

      --
      IF get_promotion_object (o_cc_error_tbl,
                               l_promo_recs,
                               l_pc_ids_need_merge,
                               i_price_event_type
                              ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 BEGIN

      --
      IF rpm_bulk_cc_threading_sql.is_loc_move_ind = 'Y'
      THEN
         IF rpm_future_retail_gtt_sql.tsl_lm_merge_promotion (o_cc_error_tbl,
                                                              l_promo_recs
                                                             ) = 0
         THEN
            RETURN 0;
         END IF;
      -- CR291 Raghuveer P R 02-Apr-2010 -Begin
      ELSIF rpm_bulk_cc_threading_sql.is_recls_ind = 'Y'
      THEN
         IF rpm_future_retail_gtt_sql.tsl_recls_merge_promotion
                                                             (o_cc_error_tbl,
                                                              l_promo_recs
                                                             ) = 0
         THEN
            RETURN 0;
         END IF;
      -- CR291 Raghuveer P R 02-Apr-2010 -End
      ELSE
         IF rpm_future_retail_gtt_sql.merge_promotion (o_cc_error_tbl,
                                                       l_promo_recs
                                                      ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 End

      --
      IF roll_forward (l_rf_cc_error_tbl,
                       l_pc_ids_need_merge,
                       i_price_event_type
                      ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF l_rf_cc_error_tbl IS NOT NULL AND l_rf_cc_error_tbl.COUNT > 0
      THEN
         --
         IF l_cc_error_tbl IS NULL
         THEN
            l_cc_error_tbl := conflict_check_error_tbl ();
         END IF;

         --
         FOR i IN 1 .. l_rf_cc_error_tbl.COUNT
         LOOP
            l_cc_error_tbl.EXTEND;
            l_cc_error_tbl (l_cc_error_tbl.COUNT) := l_rf_cc_error_tbl (i);
         END LOOP;
      END IF;

      --
      o_cc_error_tbl := l_cc_error_tbl;
      --

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END insert_promo;

--------------------------------------------------------------------------------
   FUNCTION update_promo_end_date (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_override_tbl       IN       obj_varchar_desc_table
   )
      RETURN NUMBER
   IS
      l_program       VARCHAR2 (100)
                             := 'RPM_FUTURE_RETAIL_SQL.UPDATE_PROMO_END_DATE';
--
      l_promo_rec     obj_rpm_cc_promo_rec;
      l_rf_date_tbl   date_tbl             := date_tbl ();
--
      l_promo_recs    obj_rpm_cc_promo_tbl;
--
   BEGIN
      --
      IF get_promotion_object (o_cc_error_tbl,
                               l_promo_recs,
                               i_price_event_ids,
                               i_price_event_type
                              ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF ignore_approved_loc_moves (o_cc_error_tbl,
                                    i_price_event_ids,
                                    i_price_event_type
                                   ) = 0
      THEN
         RETURN 0;
      END IF;

      --

      --28-Nov-2007 WiproEnabler/RK        Mod:93 Begin
--Including the Multibuy update also
   --if I_price_event_type != RPM_CONFLICT_LIBRARY.BUYGET_UPDATE then
      IF i_price_event_type NOT IN
            (rpm_conflict_library.buyget_update,
             rpm_conflict_library.multibuy_update
            )
      THEN
--28-Nov-2007 WiproEnabler/RK        Mod:93 End
         IF ignore_approved_exceptions (o_cc_error_tbl,
                                        i_price_event_ids,
                                        i_price_event_type
                                       ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      --
      INSERT INTO rpm_rf_dates_gtt
         SELECT /*+ cardinality(pr 1000) */
                pr.promo_comp_detail_id, pr.rpcd_start_date
           FROM TABLE (CAST (l_promo_recs AS obj_rpm_cc_promo_tbl)) pr
         UNION ALL
         SELECT /*+ cardinality(pr 1000) */
                pr.promo_comp_detail_id, pr.old_rpcd_end_date
           FROM TABLE (CAST (l_promo_recs AS obj_rpm_cc_promo_tbl)) pr
          WHERE pr.old_rpcd_end_date IS NOT NULL
         UNION ALL
         SELECT /*+ cardinality(pr 1000) */
                pr.promo_comp_detail_id, pr.old_rpcd_end_date + 1
           FROM TABLE (CAST (l_promo_recs AS obj_rpm_cc_promo_tbl)) pr
          WHERE pr.old_rpcd_end_date IS NOT NULL
         UNION ALL
         SELECT /*+ cardinality(pr 1000) */
                pr.promo_comp_detail_id, pr.rpcd_end_date
           FROM TABLE (CAST (l_promo_recs AS obj_rpm_cc_promo_tbl)) pr
          WHERE pr.rpcd_end_date IS NOT NULL
         UNION ALL
         SELECT /*+ cardinality(pr 1000) */
                pr.promo_comp_detail_id, pr.rpcd_end_date + 1
           FROM TABLE (CAST (l_promo_recs AS obj_rpm_cc_promo_tbl)) pr
          WHERE pr.rpcd_end_date IS NOT NULL;

      --
      IF validate_promotion_for_merge (o_cc_error_tbl, i_price_event_ids) = 0
      THEN
         RETURN 0;
      END IF;

      IF rpm_future_retail_gtt_sql.merge_new_promo_end_date (o_cc_error_tbl,
                                                             l_promo_recs
                                                            ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF roll_forward (o_cc_error_tbl, i_price_event_ids, i_price_event_type) =
                                                                             0
      THEN
         RETURN 0;
      END IF;

      -- Modified for defect fix NBS00018090 by Debadatta Patra on 01-Jul-2010 Begin
      IF rpm_exe_cc_query_rules.tsl_EXECUTE (o_cc_error_tbl,
                                         i_override_tbl,
                                         i_price_event_ids,
                                         i_price_event_type
                                        ) = 0
      THEN
         IF push_back_error_rows (o_cc_error_tbl) = 0
         THEN
            RETURN 0;
         END IF;

         --
         RETURN 0;
      END IF;

      --removed 18090 code for the defect fix:18642 by Rajendra B on 11-Aug-2010
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END update_promo_end_date;

--------------------------------------------------------------------------------
   FUNCTION remove_from_timeline (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_rib_trans_id       IN       NUMBER
   )
      RETURN NUMBER
   IS
      l_program   VARCHAR2 (100)
                              := 'RPM_FUTURE_RETAIL_SQL.REMOVE_FROM_TIMELINE';
--
   BEGIN
      IF i_price_event_type = rpm_conflict_library.price_change
      THEN
         IF remove_price_change (o_cc_error_tbl,
                                 i_price_event_ids,
                                 i_price_event_type,
                                 i_rib_trans_id
                                ) = 0
         THEN
            RETURN 0;
         END IF;
      --
      ELSIF i_price_event_type = rpm_conflict_library.clearance
      THEN
         IF remove_clearance (o_cc_error_tbl,
                              i_price_event_ids,
                              i_price_event_type,
                              i_rib_trans_id
                             ) = 0
         THEN
            RETURN 0;
         END IF;
      --28-Nov-2007 WiproEnabler/RK        Mod:93 Begin
      ELSIF i_price_event_type IN
              (rpm_conflict_library.simple_promotion,
               rpm_conflict_library.threshold_promotion,
               rpm_conflict_library.buyget_promotion,
               rpm_conflict_library.multibuy_promotion
              )
      THEN
--23-Nov-2007 WiproEnabler/RK        Mod:93 End
         IF remove_promotion (o_cc_error_tbl,
                              i_price_event_ids,
                              i_price_event_type,
                              i_rib_trans_id
                             ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END remove_from_timeline;

--------------------------------------------------------------------------------
   FUNCTION remove_price_change (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_rib_trans_id       IN       NUMBER
   )
      RETURN NUMBER
   IS
      l_program                VARCHAR2 (100)
                               := 'RPM_FUTURE_RETAIL_SQL.REMOVE_PRICE_CHANGE';
--
      l_parent_rpcs            obj_num_num_date_tbl;
      l_validate_parent_rpcs   obj_num_num_date_tbl;
--
      l_cc_error_tbl           conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();
--
      l_rf_cc_error_tbl        conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();

--
      CURSOR c_check_pc
      IS
         SELECT /*+ cardinality(ids 100) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (SELECT 1
                              FROM rpm_price_change rpc
                             WHERE rpc.price_change_id = VALUE (ids));

--
      CURSOR c_validate_parents
      IS
         SELECT /*+ cardinality(ids 100) */
                obj_num_num_date_rec (parents.numeric_col1,
                                      parents.numeric_col2,
                                      parents.date_col
                                     )
           FROM rpm_price_change rpc,
                TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) parents
          WHERE rpc.price_change_id = parents.numeric_col1
            AND (    parents.date_col IS NOT NULL
                 AND rpc.effective_date != parents.date_col
                );

--
      CURSOR c_test
      IS
         SELECT VALUE (ids) id1, VALUE (ids) id2
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (
                   SELECT 1
                     FROM TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) parents
                    WHERE parents.numeric_col1 = VALUE (ids))
             OR EXISTS (
                   SELECT 1
                     FROM rpm_price_change rpc,
                          TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) parents
                    WHERE parents.numeric_col1 = VALUE (ids)
                      AND rpc.price_change_id = VALUE (ids)
                      AND rpc.effective_date !=
                                    NVL (parents.date_col, rpc.effective_date));
   BEGIN
      --
      -- Stop the whole process if any of the price change id is not valid
      --
      FOR rec IN c_check_pc
      LOOP
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec
                                   (NULL,
                                    NULL,
                                    rpm_conflict_library.plsql_error,
                                    sql_lib.create_msg (   'NO_DATA_FOUND - '
                                                        || rec.ID,
                                                        NULL,
                                                        NULL,
                                                        NULL
                                                       )
                                   )
               );
         RETURN 0;
      END LOOP;

      --
      IF ignore_approved_exceptions (o_cc_error_tbl,
                                     i_price_event_ids,
                                     i_price_event_type
                                    ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF ignore_approved_loc_moves (o_cc_error_tbl,
                                    i_price_event_ids,
                                    i_price_event_type
                                   ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF rpm_future_retail_gtt_sql.get_affected_parent (o_cc_error_tbl,
                                                        i_price_event_ids,
                                                        i_price_event_type,
                                                        l_parent_rpcs
                                                       ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      INSERT INTO rpm_rf_dates_gtt
         SELECT /*+ cardinality(ids 1000) index(rpc pk_rpm_price_change) */
                rpc.price_change_id, rpc.effective_date
           FROM rpm_price_change rpc,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rpc.price_change_id = VALUE (ids)
         UNION ALL
         SELECT t.numeric_col1, t.date_col
           FROM TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) t
          WHERE t.date_col IS NOT NULL;

      --
      UPDATE rpm_future_retail_gtt rfrg
         SET rfrg.price_change_id = NULL,
             rfrg.price_change_display_id = NULL,
             rfrg.pc_exception_parent_id = NULL,
             rfrg.pc_change_type = NULL,
             rfrg.pc_change_amount = NULL,
             rfrg.pc_change_currency = NULL,
             rfrg.pc_change_percent = NULL,
             rfrg.pc_change_selling_uom = NULL,
             rfrg.pc_null_multi_ind = NULL,
             rfrg.pc_multi_units = NULL,
             rfrg.pc_multi_unit_retail = NULL,
             rfrg.pc_multi_unit_retail_currency = NULL,
             rfrg.pc_multi_selling_uom = NULL,
             rfrg.pc_price_guide_id = NULL
       WHERE (rfrg.price_event_id, rfrg.price_change_id) IN (
                SELECT VALUE (ids), VALUE (ids)
                  FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
                 WHERE NOT EXISTS (
                          SELECT /*+ cardinality(parents 1000) */
                                 1
                            FROM TABLE
                                    (CAST
                                        (l_parent_rpcs AS obj_num_num_date_tbl)
                                    ) parents
                           WHERE parents.numeric_col1 = VALUE (ids)
                             AND parents.numeric_col2 IS NOT NULL)
                    OR EXISTS (
                          SELECT /*+ cardinality(parents 1000) */
                                 1
                            FROM rpm_price_change rpc,
                                 TABLE
                                    (CAST
                                        (l_parent_rpcs AS obj_num_num_date_tbl)
                                    ) parents
                           WHERE parents.numeric_col1 = VALUE (ids)
                             AND parents.numeric_col2 IS NOT NULL
                             AND rpc.price_change_id = VALUE (ids)
                             AND rpc.effective_date !=
                                    NVL (parents.date_col, rpc.effective_date)));

      --
      -- ADD_PARENT
      --
      OPEN c_validate_parents;

      FETCH c_validate_parents
      BULK COLLECT INTO l_validate_parent_rpcs;

      CLOSE c_validate_parents;

      --
      IF     l_validate_parent_rpcs IS NOT NULL
         AND l_validate_parent_rpcs.COUNT > 0
      THEN
         IF rpm_cc_one_pc_per_day.VALIDATE (o_cc_error_tbl,
                                            l_validate_parent_rpcs
                                           ) = 0
         THEN
            RETURN 0;
         END IF;

         --
         l_cc_error_tbl := o_cc_error_tbl;
      --
      END IF;

      --
      IF l_parent_rpcs IS NOT NULL AND l_parent_rpcs.COUNT > 0
      THEN
         IF rpm_future_retail_gtt_sql.merge_parent_price_change
                                                             (o_cc_error_tbl,
                                                              l_parent_rpcs
                                                             ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      --
      -- END ADD_PARENT
      --
      IF roll_forward (l_rf_cc_error_tbl,
                       i_price_event_ids,
                       i_price_event_type
                      ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF l_rf_cc_error_tbl IS NOT NULL AND l_rf_cc_error_tbl.COUNT > 0
      THEN
         --
         IF l_cc_error_tbl IS NULL
         THEN
            l_cc_error_tbl := conflict_check_error_tbl ();
         END IF;

         --
         FOR i IN 1 .. l_rf_cc_error_tbl.COUNT
         LOOP
            l_cc_error_tbl.EXTEND;
            l_cc_error_tbl (l_cc_error_tbl.COUNT) := l_rf_cc_error_tbl (i);
         END LOOP;
      END IF;

      --
      o_cc_error_tbl := l_cc_error_tbl;
      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END remove_price_change;

--------------------------------------------------------------------------------
   FUNCTION remove_clearance (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_rib_trans_id       IN       NUMBER
   )
      RETURN NUMBER
   IS
      l_program            VARCHAR2 (100)
                                  := 'RPM_FUTURE_RETAIL_SQL.REMOVE_CLEARANCE';
--
      l_parent_rcs         obj_num_num_date_tbl;
--
      l_pe_ids_to_remove   obj_num_num_date_tbl;
--
      l_cc_error_tbl       conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();
--
      l_rf_cc_error_tbl    conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();

--
      CURSOR c_check_cl
      IS
         SELECT /*+ cardinality(ids 1000) */
                VALUE (ids) ID
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE NOT EXISTS (SELECT 1
                              FROM rpm_clearance rc
                             WHERE rc.clearance_id = VALUE (ids));

--
      CURSOR c_remove_ids
      IS
         SELECT /*+ cardinality(ids 1000) */
                obj_num_num_date_rec (VALUE (ids), VALUE (ids), NULL)
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids;
--
   BEGIN
      --
      -- Stop the whole process if any of the price change id is not valid
      --
      FOR rec IN c_check_cl
      LOOP
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec
                                   (NULL,
                                    NULL,
                                    rpm_conflict_library.plsql_error,
                                    sql_lib.create_msg (   'NO_DATA_FOUND - '
                                                        || rec.ID,
                                                        NULL,
                                                        NULL,
                                                        NULL
                                                       )
                                   )
               );
         RETURN 0;
      END LOOP;

      --
      -- Do what the ClearancePriceChangeSaveResetAction.java used to do
      --
      IF rpm_clearance_gtt_sql.populate_gtt (o_cc_error_tbl,
                                             i_price_event_ids) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF lp_persist_ind = 'Y'
      THEN
         IF rpm_clearance_gtt_sql.remove_clearance_reset (o_cc_error_tbl,
                                                          i_price_event_ids
                                                         ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      --
      IF ignore_approved_exceptions (o_cc_error_tbl,
                                     i_price_event_ids,
                                     i_price_event_type
                                    ) = 0
      THEN
         RETURN 0;
      END IF;

      IF ignore_approved_loc_moves (o_cc_error_tbl,
                                    i_price_event_ids,
                                    i_price_event_type
                                   ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      OPEN c_remove_ids;

      FETCH c_remove_ids
      BULK COLLECT INTO l_pe_ids_to_remove;

      CLOSE c_remove_ids;

      --
      IF rpm_future_retail_gtt_sql.remove_event (o_cc_error_tbl,
                                                 l_pe_ids_to_remove,
                                                 i_price_event_type
                                                ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF rpm_future_retail_gtt_sql.get_affected_parent (o_cc_error_tbl,
                                                        i_price_event_ids,
                                                        i_price_event_type,
                                                        l_parent_rcs
                                                       ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF l_parent_rcs IS NOT NULL AND l_parent_rcs.COUNT > 0
      THEN
         --
         -- ADD_PARENT
         --
         IF rpm_cc_post_reset_clr.VALIDATE (o_cc_error_tbl, l_parent_rcs) = 0
         THEN
            RETURN 0;
         END IF;

         IF rpm_cc_one_clr_per_day.VALIDATE (o_cc_error_tbl, l_parent_rcs) = 0
         THEN
            RETURN 0;
         END IF;

         --
         l_cc_error_tbl := o_cc_error_tbl;

         --
         IF rpm_future_retail_gtt_sql.merge_clearance
                                               (o_cc_error_tbl,
                                                l_parent_rcs,
                                                rpm_conflict_library.start_ind
                                               ) = 0
         THEN
            RETURN 0;
         END IF;

         --
         -- END ADD_PARENT
         --
         INSERT INTO rpm_rf_dates_gtt
            SELECT t.numeric_col1, t.date_col
              FROM TABLE (CAST (l_parent_rcs AS obj_num_num_date_tbl)) t
             WHERE t.date_col IS NOT NULL;
      --
      END IF;

      --
      INSERT INTO rpm_rf_dates_gtt
         SELECT /*+ cardinality(ids 1000) index(rc pk_rpm_clearance) */
                rc.clearance_id, rc.effective_date
           FROM rpm_clearance rc,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rc.clearance_id = VALUE (ids);

      --
      IF roll_forward (l_rf_cc_error_tbl,
                       i_price_event_ids,
                       i_price_event_type
                      ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF l_rf_cc_error_tbl IS NOT NULL AND l_rf_cc_error_tbl.COUNT > 0
      THEN
         --
         IF l_cc_error_tbl IS NULL
         THEN
            l_cc_error_tbl := conflict_check_error_tbl ();
         END IF;

         --
         FOR i IN 1 .. l_rf_cc_error_tbl.COUNT
         LOOP
            l_cc_error_tbl.EXTEND;
            l_cc_error_tbl (l_cc_error_tbl.COUNT) := l_rf_cc_error_tbl (i);
         END LOOP;
      END IF;

      --
      IF rpm_future_retail_gtt_sql.upd_reset_on_clr_remove (o_cc_error_tbl,
                                                            lp_rib_trans_id
                                                           ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      o_cc_error_tbl := l_cc_error_tbl;
      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END remove_clearance;

--------------------------------------------------------------------------------
   FUNCTION remove_promotion (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2,
      i_rib_trans_id       IN       NUMBER
   )
      RETURN NUMBER
   IS
      l_program             VARCHAR2 (100)
                                  := 'RPM_FUTURE_RETAIL_SQL.REMOVE_PROMOTION';
--
      l_promotion_type      rpm_future_retail.p1_c1_type%TYPE;
      l_parent_rpcs         obj_num_num_date_tbl;
      l_parent_ids          obj_numeric_id_table;
      l_parent_promo_recs   obj_rpm_cc_promo_tbl;
--
      l_pe_ids_to_remove    obj_num_num_date_tbl;
--
      l_cc_error_tbl        conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();
--
      l_rf_cc_error_tbl     conflict_check_error_tbl
                                               := conflict_check_error_tbl
                                                                          ();

--
      CURSOR c_parent_ids
      IS
         SELECT /*+ cardinality(ids 1000) */
                parents.numeric_col2
           FROM TABLE (CAST (l_parent_rpcs AS obj_num_num_date_tbl)) parents
          WHERE parents.numeric_col2 IS NOT NULL;

--
      CURSOR c_remove_ids
      IS
         SELECT /*+ cardinality(ids 1000) */
                obj_num_num_date_rec (VALUE (ids), VALUE (ids), NULL)
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids;
--
   BEGIN
      --
      IF ignore_approved_exceptions (o_cc_error_tbl,
                                     i_price_event_ids,
                                     i_price_event_type
                                    ) = 0
      THEN
         RETURN 0;
      END IF;

      IF ignore_approved_loc_moves (o_cc_error_tbl,
                                    i_price_event_ids,
                                    i_price_event_type
                                   ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF i_price_event_type = rpm_conflict_library.simple_promotion
      THEN
         l_promotion_type := rpm_conflict_library.simple_code;
      ELSIF i_price_event_type = rpm_conflict_library.threshold_promotion
      THEN
         l_promotion_type := rpm_conflict_library.threshold_code;
      ELSIF i_price_event_type = rpm_conflict_library.buyget_promotion
      THEN
         l_promotion_type := rpm_conflict_library.buy_get_code;
      --15-Jan-2008 Lakshmi Natarajan Forward Porting Mod:93 Begin
      ELSIF i_price_event_type = rpm_conflict_library.multibuy_promotion
      THEN
         l_promotion_type := rpm_conflict_library.multibuy_code;
      --15-Jan-2008 Lakshmi Natarajan Forward Porting Mod:93 End
      END IF;

      IF rpm_cc_publish.stage_prom_remove_messages (o_cc_error_tbl,
                                                    i_rib_trans_id,
                                                    i_price_event_ids,
                                                    l_promotion_type
                                                   ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      OPEN c_remove_ids;

      FETCH c_remove_ids
      BULK COLLECT INTO l_pe_ids_to_remove;

      CLOSE c_remove_ids;

      --
      IF rpm_future_retail_gtt_sql.remove_event (o_cc_error_tbl,
                                                 l_pe_ids_to_remove,
                                                 i_price_event_type
                                                ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF rpm_future_retail_gtt_sql.get_affected_parent (o_cc_error_tbl,
                                                        i_price_event_ids,
                                                        i_price_event_type,
                                                        l_parent_rpcs
                                                       ) = 0
      THEN
         RETURN 0;
      END IF;

      --

      --
      IF l_parent_rpcs IS NOT NULL AND l_parent_rpcs.COUNT > 0
      THEN
         OPEN c_parent_ids;

         FETCH c_parent_ids
         BULK COLLECT INTO l_parent_ids;

         CLOSE c_parent_ids;

         IF get_promotion_object (o_cc_error_tbl,
                                  l_parent_promo_recs,
                                  l_parent_ids,
                                  i_price_event_type
                                 ) = 0
         THEN
            RETURN 0;
         END IF;

         --validate parent
         IF validate_promotion_for_merge (o_cc_error_tbl, l_parent_ids) = 0
         THEN
            RETURN 0;
         END IF;

         --
         l_cc_error_tbl := o_cc_error_tbl;

         --
         --merge parent
         IF rpm_future_retail_gtt_sql.merge_promotion (o_cc_error_tbl,
                                                       l_parent_promo_recs
                                                      ) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      --
      INSERT INTO rpm_rf_dates_gtt
         SELECT /*+ cardinality(ids 1000) */
                rpcd.rpm_promo_comp_detail_id, rpcd.start_date
           FROM rpm_promo_comp_detail rpcd,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rpcd.rpm_promo_comp_detail_id = VALUE (ids)
         UNION ALL
         SELECT /*+ cardinality(ids 1000) */
                rpcd.rpm_promo_comp_detail_id, rpcd.end_date
           FROM rpm_promo_comp_detail rpcd,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rpcd.rpm_promo_comp_detail_id = VALUE (ids)
            AND rpcd.end_date IS NOT NULL
         UNION ALL
         SELECT /*+ cardinality(ids 1000) */
                rpcd.rpm_promo_comp_detail_id, rpcd.end_date + 1
           FROM rpm_promo_comp_detail rpcd,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rpcd.rpm_promo_comp_detail_id = VALUE (ids)
            AND rpcd.end_date IS NOT NULL;

      --
      IF l_parent_ids IS NOT NULL AND l_parent_ids.COUNT > 0
      THEN
         --
         INSERT INTO rpm_rf_dates_gtt
            SELECT /*+ cardinality(ids 1000) */
                   rpcd.rpm_promo_comp_detail_id, rpcd.start_date
              FROM rpm_promo_comp_detail rpcd,
                   TABLE (CAST (l_parent_ids AS obj_numeric_id_table)) ids
             WHERE rpcd.rpm_promo_comp_detail_id = VALUE (ids)
            UNION ALL
            SELECT /*+ cardinality(ids 1000) */
                   rpcd.rpm_promo_comp_detail_id, rpcd.end_date
              FROM rpm_promo_comp_detail rpcd,
                   TABLE (CAST (l_parent_ids AS obj_numeric_id_table)) ids
             WHERE rpcd.rpm_promo_comp_detail_id = VALUE (ids)
               AND rpcd.end_date IS NOT NULL
            UNION ALL
            SELECT /*+ cardinality(ids 1000) */
                   rpcd.rpm_promo_comp_detail_id, rpcd.end_date + 1
              FROM rpm_promo_comp_detail rpcd,
                   TABLE (CAST (l_parent_ids AS obj_numeric_id_table)) ids
             WHERE rpcd.rpm_promo_comp_detail_id = VALUE (ids)
               AND rpcd.end_date IS NOT NULL;
      --
      END IF;

      --
      IF roll_forward (l_rf_cc_error_tbl,
                       i_price_event_ids,
                       i_price_event_type
                      ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      IF l_rf_cc_error_tbl IS NOT NULL AND l_rf_cc_error_tbl.COUNT > 0
      THEN
         --
         IF l_cc_error_tbl IS NULL
         THEN
            l_cc_error_tbl := conflict_check_error_tbl ();
         END IF;

         --
         FOR i IN 1 .. l_rf_cc_error_tbl.COUNT
         LOOP
            l_cc_error_tbl.EXTEND;
            l_cc_error_tbl (l_cc_error_tbl.COUNT) := l_rf_cc_error_tbl (i);
         END LOOP;
      END IF;

      --
      o_cc_error_tbl := l_cc_error_tbl;
      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END remove_promotion;

--------------------------------------------------------------------------------
   FUNCTION get_promotion_object (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      o_promo_recs         OUT      obj_rpm_cc_promo_tbl,
      i_promo_ids          IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program                        VARCHAR2 (100)
                          := 'RPM_FUTURE_RETAIL_GTT_SQL.GET_PROMOTION_OBJECT';
--
      l_promo_recs                     obj_rpm_cc_promo_tbl;
      l_old_end_dates                  obj_numeric_date_tbl;
-- CR301, Vikash Prasad, 01-Sep-2010 - Begin
      l_complex_retail_using_thrsqty   rpm_system_options.tsl_hier_prom_pub_simple%TYPE
                                                                      := NULL;
      l_error_msg                      rtk_errors.rtk_text%TYPE;

-- CR301, Vikash Prasad, 01-Sep-2010 - End
--
      CURSOR c_old_end_date
      IS
         SELECT obj_numeric_date_rec (price_event_id, action_date)
           FROM (SELECT          /*+ cardinality(ids 1000) */
                        --21-May-2009 Sourabh Sharva  LT defect DefNBS012982 Begin
                 DISTINCT
                                 --21-May-2009 Sourabh Sharva  LT defect DefNBS012982 End
                                 price_event_id, action_date,
                                 RANK () OVER (PARTITION BY price_event_id ORDER BY action_date)
                                                                   rank_value
                            FROM rpm_future_retail_gtt gtt,
                                 TABLE
                                    (CAST (i_promo_ids AS obj_numeric_id_table)
                                    ) ids
                           WHERE gtt.price_event_id = VALUE (ids)
                             AND (   (    p1_c1_detail_id = VALUE (ids)
                                      AND p1_c1_start_ind IN
                                             (rpm_conflict_library.end_ind,
                                              rpm_conflict_library.start_end_ind
                                             )
                                     )
                                  OR (    p1_c2_detail_id = VALUE (ids)
                                      AND p1_c2_start_ind IN
                                             (rpm_conflict_library.end_ind,
                                              rpm_conflict_library.start_end_ind
                                             )
                                     )
                                  OR (    p1_exclusion1_id = VALUE (ids)
                                      AND p1_e1_start_ind IN
                                             (rpm_conflict_library.end_ind,
                                              rpm_conflict_library.start_end_ind
                                             )
                                     )
                                  OR (    p1_exclusion2_id = VALUE (ids)
                                      AND p1_e2_start_ind IN
                                             (rpm_conflict_library.end_ind,
                                              rpm_conflict_library.start_end_ind
                                             )
                                     )
                                  --
                                  OR (    p2_c1_detail_id = VALUE (ids)
                                      AND p2_c1_start_ind IN
                                             (rpm_conflict_library.end_ind,
                                              rpm_conflict_library.start_end_ind
                                             )
                                     )
                                  OR (    p2_c2_detail_id = VALUE (ids)
                                      AND p2_c2_start_ind IN
                                             (rpm_conflict_library.end_ind,
                                              rpm_conflict_library.start_end_ind
                                             )
                                     )
                                  OR (    p2_exclusion1_id = VALUE (ids)
                                      AND p2_e1_start_ind IN
                                             (rpm_conflict_library.end_ind,
                                              rpm_conflict_library.start_end_ind
                                             )
                                     )
                                  OR (    p2_exclusion2_id = VALUE (ids)
                                      AND p2_e2_start_ind IN
                                             (rpm_conflict_library.end_ind,
                                              rpm_conflict_library.start_end_ind
                                             )
                                     )
                                 ))
          WHERE rank_value = 1;

--
      CURSOR c_promo_obj
      IS
         SELECT /*+ cardinality(pr 1000, od 1000) */
                obj_rpm_cc_promo_rec (promo_id,
                                      promo_display_id,
                                      rp_start_date,
                                      rp_secondary_ind,
                                      --
                                      promo_comp_id,
                                      comp_display_id,
                                      rpc_secondary_ind,
                                      --
                                      promo_comp_detail_id,
                                      rpcd_start_date,
                                      rpcd_end_date,
                                      old_rpcd_start_date,
                                      date_col,
                                      apply_to_code,
                                      --
                                      zone_ids,
                                      --
                                      change_type,
                                      change_amount,
                                      change_currency,
                                      change_percent,
                                      change_selling_uom,
                                      price_guide_id,
                                      --
                                      promotion_type,
                                      exclusion
                                     )
           FROM TABLE (CAST (l_promo_recs AS obj_rpm_cc_promo_tbl)) pr,
                TABLE (CAST (l_old_end_dates AS obj_numeric_date_tbl)) od
          WHERE pr.promo_comp_detail_id = od.numeric_col(+);

--
      CURSOR c_simple_promo
      IS
         SELECT /*+ cardinality(ids 1000) */
                obj_rpm_cc_promo_rec
                                 (rp.promo_id,
                                  rp.promo_display_id,
                                  TRUNC (rp.start_date),
                                  NVL (rp.secondary_ind, 0),
                                  --
                                  rpc.promo_comp_id,
                                  rpc.comp_display_id,
                                  NVL (rpc.secondary_ind, 0),
                                  --
                                  rpcd.rpm_promo_comp_detail_id,
                                  TRUNC (rpcd.start_date),
                                  TRUNC (rpcd.end_date),
                                  TRUNC (rpcd.start_date),
                                  NULL,
                                  rpcd.apply_to_code,
                                  --
                                  obj_numeric_id_table (rpcs.zone_id),
                                  --
                                  rpcs.change_type,
                                  rpcs.change_amount,
                                  rpcs.change_currency,
                                  rpcs.change_percent,
                                  rpcs.change_selling_uom,
                                  NVL (rpcs.price_guide_id, 0),
                                  --
                                  rpm_conflict_library.simple_code,
                                  DECODE (rpcs.change_type,
                                          rpm_conflict_library.retail_exclude, 1,
                                          0
                                         )
                                 )
           FROM rpm_promo_comp_simple rpcs,
                rpm_promo_comp_detail rpcd,
                rpm_promo_comp rpc,
                rpm_promo rp,
                TABLE (CAST (i_promo_ids AS obj_numeric_id_table)) ids
          WHERE rp.promo_id = rpc.promo_id
            AND rpc.promo_comp_id = rpcd.promo_comp_id
            --
            AND rpcd.rpm_promo_comp_detail_id = VALUE (ids)
            AND rpcs.rpm_promo_comp_detail_id = VALUE (ids);

--
      CURSOR c_threshold_promo
      IS
         SELECT obj_rpm_cc_promo_rec (promo_id,
                                      promo_display_id,
                                      rp_start_date,
                                      rp_secondary_ind,
                                      --
                                      promo_comp_id,
                                      comp_display_id,
                                      rpc_secondary_ind,
                                      --
                                      rpm_promo_comp_detail_id,
                                      rpcd_start_date,
                                      rpcd_end_date,
                                      rpcd_start_date,
                                      NULL,
                                      apply_to_code,
                                      --
                                      obj_numeric_id_table (zone_id),
                                      --
                                      change_type,
                                      change_amount,
                                      change_currency,
                                      change_percent,
                                      change_uom,
                                      price_guide_id,
                                      --
                                      rpm_conflict_library.threshold_code,
                                      exclusion_ind
                                     )
           FROM (SELECT /*+ cardinality(ids 1000) */
                        rp.promo_id promo_id,
                        rp.promo_display_id promo_display_id,
                        TRUNC (rp.start_date) rp_start_date,
                        NVL (rp.secondary_ind, 0) rp_secondary_ind,

                        --
                        rpc.promo_comp_id promo_comp_id,
                        rpc.comp_display_id comp_display_id,
                        NVL (rpc.secondary_ind, 0) rpc_secondary_ind,

                        --
                        rpcd.rpm_promo_comp_detail_id
                                                     rpm_promo_comp_detail_id,
                        TRUNC (rpcd.start_date) rpcd_start_date,
                        TRUNC (rpcd.end_date) rpcd_end_date,
                                                            --
                                                            rpct.zone_id,
                        rpcd.apply_to_code apply_to_code,

                        --
                        rti.change_type change_type,

                        -- CR301, Vikash Prasad, 01-Sep-2010 - Begin
                        DECODE (l_complex_retail_using_thrsqty,
                                0, rti.change_amount,
                                rti.change_amount / rti.threshold_qty
                               ) change_amount,

                        -- CR301, Vikash Prasad, 01-Sep-2010 - End
                        rti.change_currency change_currency,
                        rti.change_percent change_percent,
                        rti.change_uom change_uom, 0 price_guide_id,

                        --
                        NVL (rpct.exclusion, 0) exclusion_ind,
                        RANK () OVER (PARTITION BY VALUE (ids) ORDER BY rti.threshold_amount DESC,
                         rti.threshold_qty DESC) RANK
                   FROM rpm_promo_comp_threshold rpct,
                        rpm_promo_comp_detail rpcd,
                        rpm_threshold_interval rti,
                        rpm_promo_comp rpc,
                        rpm_promo rp,
                        TABLE (CAST (i_promo_ids AS obj_numeric_id_table)) ids
                  WHERE rp.promo_id = rpc.promo_id
                    AND rpc.promo_comp_id = rpcd.promo_comp_id
                    --
                    AND rti.threshold_id = rpct.threshold_id
                    --
                    AND rpcd.rpm_promo_comp_detail_id = VALUE (ids)
                    AND rpct.rpm_promo_comp_detail_id = VALUE (ids))
          WHERE RANK = 1;

--
      CURSOR c_buy_get_promo
      IS
         SELECT /*+ cardinality(ids 1000) */
                obj_rpm_cc_promo_rec (rp.promo_id,
                                      rp.promo_display_id,
                                      TRUNC (rp.start_date),
                                      NVL (rp.secondary_ind, 0),
                                      --
                                      rpc.promo_comp_id,
                                      rpc.comp_display_id,
                                      NVL (rpc.secondary_ind, 0),
                                      --
                                      rpcd.rpm_promo_comp_detail_id,
                                      TRUNC (rpcd.start_date),
                                      TRUNC (rpcd.end_date),
                                      TRUNC (rpcd.start_date),
                                      NULL,
                                      rpcd.apply_to_code,
                                      --
                                      obj_numeric_id_table (),
                                      --
                                      rpcbg.change_type,
                                      rpcbg.change_amount,
                                      rpcbg.change_currency,
                                      rpcbg.change_percent,
                                      rpcbg.change_selling_uom,
                                      NVL (rpcbg.price_guide_id, 0),
                                      --
                                      rpm_conflict_library.buy_get_code,
                                      DECODE (rpcbg.exclusion_parent_id,
                                              NULL, 0,
                                              1
                                             )
                                     )
           FROM rpm_promo_comp_buy_get rpcbg,
                rpm_promo_comp_detail rpcd,
                rpm_promo_comp rpc,
                rpm_promo rp,
                TABLE (CAST (i_promo_ids AS obj_numeric_id_table)) ids
          WHERE rp.promo_id = rpc.promo_id
            AND rpc.promo_comp_id = rpcd.promo_comp_id
            --
            AND rpcd.rpm_promo_comp_detail_id = VALUE (ids)
            AND rpcbg.rpm_promo_comp_detail_id = VALUE (ids);

--23-Nov-2007 WiproEnabler/RK        Mod:93 Begin
--3-Jan-2008 WiproEnabler/RK        Forward Porting Begin
--Removed the cursor argument I_pcd_id
      CURSOR c_multi_buy_promo
      IS
--3-Jan-2008 WiproEnabler/RK        Forward Porting End
--3-Jan-2008 WiproEnabler/RK        Forward Porting End
         SELECT obj_rpm_cc_promo_rec
                   (rp.promo_id,
                    rp.promo_display_id,
                    TRUNC (rp.start_date),
                    rp.secondary_ind,
                    --
                    rpc.promo_comp_id,
                    rpc.comp_display_id,
                    rpc.secondary_ind,
                    --
                    rpcd.rpm_promo_comp_detail_id,
                    TRUNC (rpcd.start_date),
                    TRUNC (rpcd.end_date),
                    NULL,
                    NULL,
                    rpcd.apply_to_code,
                    --
                    CAST
                       (MULTISET (SELECT trpmbz.zone_id
                                    FROM tsl_rpm_promo_multi_buy_zone trpmbz
                                   WHERE trpmbz.rpm_promo_comp_detail_id =
                                                 rpcd.rpm_promo_comp_detail_id
                                     AND trpmbz.zone_id IS NOT NULL
                                 ) AS obj_numeric_id_table
                       ),
                    --
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                     --trpcmb.price_guide_id,
                    --29-Apr-2008 WiproEnabler/LN       ST Defect Fix #5537 Begin
                    NVL (trpcmb.price_guide_id, 0),
                    --29-Apr-2008 WiproEnabler/LN       ST Defect Fix #5537 End
                    --
                    rpm_conflict_library.multibuy_code,
                    DECODE (trpcmb.exclusion_parent_id, NULL, 0, 1)
                   )
           FROM tsl_rpm_promo_comp_m_b trpcmb,
                rpm_promo_comp_detail rpcd,
                rpm_promo_comp rpc,
                rpm_promo rp,
                --3-Jan-2008 WiproEnabler/RK        Forward Porting Begin
                TABLE (CAST (i_promo_ids AS obj_numeric_id_table)) ids
          --3-Jan-2008 WiproEnabler/RK        Forward Porting End
         WHERE  rp.promo_id = rpc.promo_id
            AND rpc.promo_comp_id = rpcd.promo_comp_id
            --3-Jan-2008 WiproEnabler/RK        Forward Porting Begin
            AND rpcd.rpm_promo_comp_detail_id = VALUE (ids)
            AND trpcmb.rpm_promo_comp_detail_id = VALUE (ids);
   --3-Jan-2008 WiproEnabler/RK        Forward Porting End
--23-Nov-2007 WiproEnabler/RK        Mod:93 End
   BEGIN
      --
       -- CR301, Vikash Prasad, 01-Sep-2010 - Begin
      IF rpm_system_options_sql.get_tsl_cmplx_rtl_usg_thr_qty
                                             (l_complex_retail_using_thrsqty,
                                              l_error_msg
                                             ) = FALSE
      THEN
         RETURN 0;
      END IF;

      -- CR301, Vikash Prasad, 01-Sep-2010 - End
      IF i_price_event_type IN
            (rpm_conflict_library.simple_promotion,
             rpm_conflict_library.simple_update
            )
      THEN
         OPEN c_simple_promo;

         FETCH c_simple_promo
         BULK COLLECT INTO l_promo_recs;

         CLOSE c_simple_promo;
      ELSIF i_price_event_type IN
              (rpm_conflict_library.threshold_promotion,
               rpm_conflict_library.threshold_update
              )
      THEN
         OPEN c_threshold_promo;

         FETCH c_threshold_promo
         BULK COLLECT INTO l_promo_recs;

         CLOSE c_threshold_promo;
      ELSIF i_price_event_type IN
              (rpm_conflict_library.buyget_promotion,
               rpm_conflict_library.buyget_update
              )
      THEN
         OPEN c_buy_get_promo;

         FETCH c_buy_get_promo
         BULK COLLECT INTO l_promo_recs;

         CLOSE c_buy_get_promo;
      --23-Nov-2007 WiproEnabler/RK        Mod:93 Begin
      ELSIF i_price_event_type IN
              (rpm_conflict_library.multibuy_promotion,
               rpm_conflict_library.multibuy_update
              )
      THEN
         --3-Jan-2008 WiproEnabler/RK        Forward Porting Begin
         --Remove the cursor parameter
         OPEN c_multi_buy_promo;

         --Changed the output variable from O_promo_rec to L_promo_recs
         --Changed into bulk collect
         FETCH c_multi_buy_promo
         BULK COLLECT INTO l_promo_recs;

         --3-Jan-2008 WiproEnabler/RK        Forward Porting End
         CLOSE c_multi_buy_promo;
      --23-Nov-2007 WiproEnabler/RK        Mod:93 End
      END IF;

      --15-Jan-2008 Lakshmi Forward Porting       Mod:93 End
      IF i_price_event_type IN
            (rpm_conflict_library.simple_update,
             rpm_conflict_library.threshold_update,
             rpm_conflict_library.buyget_update,
             rpm_conflict_library.multibuy_update
            )
      THEN
         --15-Jan-2008 Lakshmi  Forward Porting      Mod:93 End
         OPEN c_old_end_date;

         FETCH c_old_end_date
         BULK COLLECT INTO l_old_end_dates;

         CLOSE c_old_end_date;

         --
         OPEN c_promo_obj;

         FETCH c_promo_obj
         BULK COLLECT INTO o_promo_recs;

         CLOSE c_promo_obj;
      --
      ELSE
         o_promo_recs := l_promo_recs;
      END IF;

      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END get_promotion_object;

--------------------------------------------------------------------------------
   FUNCTION validate_promotion_for_merge (
      o_cc_error_tbl   OUT      conflict_check_error_tbl,
      i_promo_ids      IN       obj_numeric_id_table
   )
      RETURN NUMBER
   IS
      l_program             VARCHAR2 (100)
                      := 'RPM_FUTURE_RETAIL_SQL.VALIDATE_PROMOTION_FOR_MERGE';
      -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 BEGIN
      o_error_message       VARCHAR2 (255);
      l_rpm_loc_move_chgs   system_options.tsl_rpm_loc_move_chgs%TYPE;
   -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 End
   BEGIN
      --
      IF rpm_cc_two_prom_limit.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
      THEN
         RETURN 0;
      END IF;

      IF rpm_cc_two_promcomp_limit.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
      THEN
         RETURN 0;
      END IF;

      IF rpm_cc_promcomp_overlap.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
      THEN
         RETURN 0;
      END IF;

      IF rpm_cc_two_promexcl_limit.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
      THEN
         RETURN 0;
      END IF;

      -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 BEGIN
      IF system_options_sql.tsl_get_rpm_loc_move_chgs (o_error_message,
                                                       l_rpm_loc_move_chgs
                                                      ) = FALSE
      THEN
         RETURN 0;
      END IF;

      IF    l_rpm_loc_move_chgs != 'Y'
         OR rpm_bulk_cc_threading_sql.is_loc_move_ind != 'Y'
      THEN
         IF rpm_cc_prom_span_lm.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 End

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END validate_promotion_for_merge;

--------------------------------------------------------------------------------
   FUNCTION ignore_approved_exceptions (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program           VARCHAR2 (100)
                        := 'RPM_FUTURE_RETAIL_SQL.IGNORE_APPROVED_EXCEPTIONS';
--
      l_child_event_ids   obj_num_num_date_tbl := NULL;
   BEGIN
      --
      IF rpm_future_retail_gtt_sql.get_children (o_cc_error_tbl,
                                                 i_price_event_ids,
                                                 i_price_event_type,
                                                 --
                                                 l_child_event_ids
                                                ) = 0
      THEN
         RETURN 0;
      END IF;

      IF l_child_event_ids IS NULL OR l_child_event_ids.COUNT = 0
      THEN
         RETURN 1;
      END IF;

      --
      IF rpm_future_retail_gtt_sql.remove_timelines (o_cc_error_tbl,
                                                     i_price_event_type,
                                                     l_child_event_ids
                                                    ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END ignore_approved_exceptions;

--------------------------------------------------------------------------------
   FUNCTION ignore_approved_loc_moves (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program          VARCHAR2 (100)
                         := 'RPM_FUTURE_RETAIL_SQL.IGNORE_APPROVED_LOC_MOVES';
--
      l_zone_level_pes   obj_num_num_date_tbl;

--
      CURSOR c_zone_pc
      IS
         SELECT /*+ cardinality(ids 1000) */
                NEW obj_num_num_date_rec (VALUE (ids),
                                          rpc.zone_id,
                                          rpc.effective_date
                                         )
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids,
                rpm_price_change rpc
          WHERE rpc.price_change_id = VALUE (ids) AND rpc.zone_id IS NOT NULL;

--
      CURSOR c_zone_cl
      IS
         SELECT /*+ cardinality(ids 1000) */
                NEW obj_num_num_date_rec (VALUE (ids),
                                          rc.zone_id,
                                          rc.effective_date
                                         )
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids,
                rpm_clearance_gtt rc
          WHERE rc.price_event_id = VALUE (ids)
            AND rc.clearance_id = VALUE (ids)
            AND rc.zone_id IS NOT NULL;

--
      CURSOR c_zone_sp
      IS
         SELECT /*+ cardinality(ids 1000) */
                NEW obj_num_num_date_rec (VALUE (ids),
                                          rpcs.zone_id,
                                          rpcd.start_date
                                         )
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids,
                rpm_promo_comp_simple rpcs,
                rpm_promo_comp_detail rpcd
          WHERE rpcs.rpm_promo_comp_detail_id = VALUE (ids)
            AND rpcs.zone_id IS NOT NULL
            AND rpcd.rpm_promo_comp_detail_id = rpcs.rpm_promo_comp_detail_id;

--
      CURSOR c_zone_th
      IS
         SELECT /*+ cardinality(ids 1000) */
                NEW obj_num_num_date_rec (VALUE (ids),
                                          rpct.zone_id,
                                          rpcd.start_date
                                         )
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids,
                rpm_promo_comp_threshold rpct,
                rpm_promo_comp_detail rpcd
          WHERE rpct.rpm_promo_comp_detail_id = VALUE (ids)
            AND rpct.zone_id IS NOT NULL
            AND rpcd.rpm_promo_comp_detail_id = rpct.rpm_promo_comp_detail_id;

--
      CURSOR c_zone_bg
      IS
         SELECT /*+ cardinality(ids 1000) */
                NEW obj_num_num_date_rec (VALUE (ids),
                                          rpbgz.zone_id,
                                          rpcd.start_date
                                         )
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids,
                rpm_promo_comp_buy_get rpcbg,
                rpm_promo_buy_get_zone rpbgz,
                rpm_promo_comp_detail rpcd
          WHERE rpcbg.rpm_promo_comp_detail_id = VALUE (ids)
            AND rpbgz.rpm_promo_comp_detail_id =
                                                rpcbg.rpm_promo_comp_detail_id
            AND rpcd.rpm_promo_comp_detail_id = rpcbg.rpm_promo_comp_detail_id;

--

      --15-Jan-2008 Lakshmi Forward Porting       Mod:93 End
      CURSOR c_zone_mb
      IS
         SELECT /*+ cardinality(ids 1000) */
                NEW obj_num_num_date_rec (VALUE (ids),
                                          trpmbz.zone_id,
                                          rpcd.start_date
                                         )
           FROM TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids,
                tsl_rpm_promo_comp_m_b trpcmb,
                tsl_rpm_promo_multi_buy_zone trpmbz,
                rpm_promo_comp_detail rpcd
          WHERE trpcmb.rpm_promo_comp_detail_id = VALUE (ids)
            AND trpmbz.rpm_promo_comp_detail_id =
                                               trpcmb.rpm_promo_comp_detail_id
            AND rpcd.rpm_promo_comp_detail_id =
                                               trpcmb.rpm_promo_comp_detail_id;
   --15-Jan-2008 Lakshmi Forward Porting       Mod:93 End
   BEGIN
      IF i_price_event_type = rpm_conflict_library.price_change
      THEN
         OPEN c_zone_pc;

         FETCH c_zone_pc
         BULK COLLECT INTO l_zone_level_pes;

         CLOSE c_zone_pc;

         IF l_zone_level_pes IS NULL OR l_zone_level_pes.COUNT = 0
         THEN
            RETURN 1;
         END IF;
      ELSIF i_price_event_type = rpm_conflict_library.clearance
      THEN
         OPEN c_zone_cl;

         FETCH c_zone_cl
         BULK COLLECT INTO l_zone_level_pes;

         CLOSE c_zone_cl;

         IF l_zone_level_pes IS NULL OR l_zone_level_pes.COUNT = 0
         THEN
            RETURN 1;
         END IF;
      ELSIF i_price_event_type IN
              (rpm_conflict_library.simple_promotion,
               rpm_conflict_library.simple_update
              )
      THEN
         OPEN c_zone_sp;

         FETCH c_zone_sp
         BULK COLLECT INTO l_zone_level_pes;

         CLOSE c_zone_sp;

         IF l_zone_level_pes IS NULL OR l_zone_level_pes.COUNT = 0
         THEN
            RETURN 1;
         END IF;
      ELSIF i_price_event_type IN
              (rpm_conflict_library.threshold_promotion,
               rpm_conflict_library.threshold_update
              )
      THEN
         OPEN c_zone_th;

         FETCH c_zone_th
         BULK COLLECT INTO l_zone_level_pes;

         CLOSE c_zone_th;

         IF l_zone_level_pes IS NULL OR l_zone_level_pes.COUNT = 0
         THEN
            RETURN 1;
         END IF;
      ELSIF i_price_event_type IN
              (rpm_conflict_library.buyget_promotion,
               rpm_conflict_library.buyget_update
              )
      THEN
         OPEN c_zone_bg;

         FETCH c_zone_bg
         BULK COLLECT INTO l_zone_level_pes;

         CLOSE c_zone_bg;

         IF l_zone_level_pes IS NULL OR l_zone_level_pes.COUNT = 0
         THEN
            RETURN 1;
         END IF;
      --15-Jan-2008 Lakshmi Forward Porting       Mod:93 End
      ELSIF i_price_event_type IN
              (rpm_conflict_library.multibuy_promotion,
               rpm_conflict_library.multibuy_update
              )
      THEN
         OPEN c_zone_mb;

         FETCH c_zone_mb
         BULK COLLECT INTO l_zone_level_pes;

         CLOSE c_zone_mb;

         IF l_zone_level_pes IS NULL OR l_zone_level_pes.COUNT = 0
         THEN
            RETURN 1;
         END IF;
      --15-Jan-2008 Lakshmi Forward Porting       Mod:93 End
      END IF;

      --
      IF rpm_future_retail_gtt_sql.remove_loc_move_timelines (o_cc_error_tbl,
                                                              l_zone_level_pes
                                                             ) = 0
      THEN
         RETURN 0;
      END IF;

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END ignore_approved_loc_moves;

--------------------------------------------------------------------------------
   FUNCTION process_exclusion_event (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program               VARCHAR2 (100)
                           := 'RPM_FUTURE_RETAIL_SQL.PROCESS_EXCLUSION_EVENT';
--
      l_rpc_ids               obj_numeric_id_table;
      l_parent_rpc_ids        obj_num_num_date_tbl;
--
      l_rc_ids                obj_numeric_id_table;
      l_parent_rc_ids         obj_num_num_date_tbl;
      l_parent_rc_reset_ids   obj_num_num_date_tbl;

--
      CURSOR c_parent_rpc
      IS
         SELECT obj_num_num_date_rec (price_event_id, price_change_id, NULL)
           FROM (SELECT          /*+ cardinality(ids 100) */
                        DISTINCT rfrg.price_event_id, rfrg.price_change_id
                            FROM rpm_future_retail_gtt rfrg,
                                 rpm_price_change rpc,
                                 TABLE
                                    (CAST
                                        (i_price_event_ids AS obj_numeric_id_table
                                        )
                                    ) ids
                           WHERE rfrg.price_event_id = VALUE (ids)
                             AND rpc.price_change_id = VALUE (ids)
                             AND rfrg.price_change_id =
                                    NVL (rpc.loc_exception_parent_id,
                                         rpc.parent_exception_parent_id
                                        ));

--
      CURSOR c_parent_rc
      IS
         SELECT obj_num_num_date_rec (price_event_id, clearance_id, NULL)
           FROM (SELECT          /*+ cardinality(ids 100) */
                        DISTINCT rfrg.price_event_id, rfrg.clearance_id
                            FROM rpm_future_retail_gtt rfrg,
                                 rpm_clearance rc,
                                 TABLE
                                    (CAST
                                        (i_price_event_ids AS obj_numeric_id_table
                                        )
                                    ) ids
                           WHERE rfrg.price_event_id = VALUE (ids)
                             AND rc.clearance_id = VALUE (ids)
                             AND rfrg.clearance_id =
                                    NVL (rc.loc_exception_parent_id,
                                         rc.parent_exception_parent_id
                                        ));

--
      CURSOR c_parent_reset
      IS
         SELECT /*+ cardinality(ids 100) */
                obj_num_num_date_rec (NVL (rc.loc_exception_parent_id,
                                           rc.parent_exception_parent_id
                                          ),
                                      rc.clearance_reset_id,
                                      NULL
                                     )
           FROM rpm_clearance rc,
                TABLE (CAST (i_price_event_ids AS obj_numeric_id_table)) ids
          WHERE rc.clearance_id = VALUE (ids)
            AND NVL (rc.loc_exception_parent_id,
                     rc.parent_exception_parent_id) IS NOT NULL
            AND rc.clearance_reset_id IS NOT NULL;

--
      CURSOR c_pe
      IS
         SELECT DISTINCT price_event_id
                    FROM rpm_rf_dates_gtt;
--
   BEGIN
      IF i_price_event_type = rpm_conflict_library.price_change
      THEN
         OPEN c_parent_rpc;

         FETCH c_parent_rpc
         BULK COLLECT INTO l_parent_rpc_ids;

         CLOSE c_parent_rpc;

         IF l_parent_rpc_ids IS NULL OR l_parent_rpc_ids.COUNT = 0
         THEN
            RETURN 1;
         END IF;

         --
         IF rpm_future_retail_gtt_sql.remove_event (o_cc_error_tbl,
                                                    l_parent_rpc_ids,
                                                    i_price_event_type
                                                   ) = 0
         THEN
            RETURN 0;
         END IF;

         --
         INSERT INTO rpm_rf_dates_gtt
            SELECT /*+ cardinality(ids 100) */
                   rpc2.price_change_id, rpc1.effective_date
              FROM rpm_price_change rpc1,
                   rpm_price_change rpc2,
                   TABLE (CAST (l_parent_rpc_ids AS obj_num_num_date_tbl)) ids
             WHERE rpc1.price_change_id = ids.numeric_col2
               AND rpc1.price_change_id =
                      NVL (rpc2.loc_exception_parent_id,
                           rpc2.parent_exception_parent_id
                          )
               AND rpc2.price_change_id = ids.numeric_col1;

         --
         OPEN c_pe;

         FETCH c_pe
         BULK COLLECT INTO l_rpc_ids;

         CLOSE c_pe;

         --
         IF roll_forward (o_cc_error_tbl, l_rpc_ids, i_price_event_type) = 0
         THEN
            RETURN 0;
         END IF;
      --
      ELSIF i_price_event_type = rpm_conflict_library.clearance
      THEN
         --
         OPEN c_parent_rc;

         FETCH c_parent_rc
         BULK COLLECT INTO l_parent_rc_ids;

         CLOSE c_parent_rc;

         --
         IF l_parent_rc_ids IS NULL OR l_parent_rc_ids.COUNT = 0
         THEN
            RETURN 1;
         END IF;

         --
         OPEN c_parent_reset;

         FETCH c_parent_reset
         BULK COLLECT INTO l_parent_rc_reset_ids;

         CLOSE c_parent_reset;

         --
         IF     l_parent_rc_reset_ids IS NOT NULL
            AND l_parent_rc_reset_ids.COUNT > 0
         THEN
            FOR i IN 1 .. l_parent_rc_reset_ids.COUNT
            LOOP
               UPDATE rpm_clearance
                  SET clearance_reset_id = NULL,
                      (reset_date, out_of_stock_date) =
                         (SELECT effective_date, out_of_stock_date
                            FROM rpm_clearance
                           WHERE clearance_id =
                                        l_parent_rc_reset_ids (i).numeric_col2)
                WHERE clearance_id = l_parent_rc_reset_ids (i).numeric_col1;
            END LOOP;
         END IF;

         --
         IF rpm_future_retail_gtt_sql.remove_event (o_cc_error_tbl,
                                                    l_parent_rc_ids,
                                                    i_price_event_type
                                                   ) = 0
         THEN
            RETURN 0;
         END IF;

         --
         INSERT INTO rpm_rf_dates_gtt
            SELECT /*+ cardinality(ids 100) */
                   rc2.clearance_id, rc1.effective_date
              FROM rpm_clearance rc1,
                   rpm_clearance rc2,
                   TABLE (CAST (l_parent_rc_ids AS obj_num_num_date_tbl)) ids
             WHERE rc1.clearance_id = ids.numeric_col2
               AND rc1.clearance_id =
                      NVL (rc2.loc_exception_parent_id,
                           rc2.parent_exception_parent_id
                          )
               AND rc2.clearance_id = ids.numeric_col1;

         --
         OPEN c_pe;

         FETCH c_pe
         BULK COLLECT INTO l_rc_ids;

         CLOSE c_pe;

         --
         IF roll_forward (o_cc_error_tbl, l_rc_ids, i_price_event_type) = 0
         THEN
            RETURN 0;
         END IF;

         --
         IF rpm_future_retail_gtt_sql.upd_reset_on_clr_remove (o_cc_error_tbl,
                                                               lp_rib_trans_id
                                                              ) = 0
         THEN
            RETURN 0;
         END IF;
      --
      END IF;

      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END process_exclusion_event;

--------------------------------------------------------------------------------
   FUNCTION roll_forward (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      i_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program          VARCHAR2 (100)
                                      := 'RPM_FUTURE_RETAIL_SQL.ROLL_FORWARD';
--
      l_rf_dates         rf_dates;
      l_start_date       DATE;
      l_end_date         DATE;
      l_call_sequence    NUMBER;
      l_price_event_id   NUMBER;
      l_cc_error_tbl     conflict_check_error_tbl;
      l_gtt_count        NUMBER;
      l_fr_conflict      NUMBER                   := 0;
      l_pl_sql_error     NUMBER                   := 0;

      CURSOR c_roll_forward_dates
      IS
         SELECT   MIN (rf_date)
             FROM rpm_rf_dates_gtt
            WHERE price_event_id = l_price_event_id
         ORDER BY rf_date ASC;
   BEGIN
      SELECT COUNT (1)
        INTO l_gtt_count
        FROM rpm_future_retail_gtt;

      FOR j IN 1 .. i_price_event_ids.COUNT
      LOOP
         --
         l_price_event_id := i_price_event_ids (j);

         --
         OPEN c_roll_forward_dates;

         FETCH c_roll_forward_dates
         BULK COLLECT INTO l_rf_dates;

         CLOSE c_roll_forward_dates;

         IF l_rf_dates IS NOT NULL AND l_rf_dates.COUNT != 0
         THEN
            --
            l_cc_error_tbl := conflict_check_error_tbl ();
            l_fr_conflict := 0;

            --
            FOR i IN 1 .. l_rf_dates.COUNT
            LOOP
               l_call_sequence := i;
               l_start_date := l_rf_dates (i);

               IF i = l_rf_dates.COUNT
               THEN
                  l_end_date := NULL;
               ELSE
                  l_end_date := l_rf_dates (i + 1);
               END IF;

               IF rpm_roll_forward_sql.EXECUTE (l_cc_error_tbl,
                                                l_price_event_id,
                                                i_price_event_type,
                                                l_start_date,
                                                l_end_date,
                                                l_call_sequence,
                                                l_gtt_count
                                               ) = 0
               THEN
                  --
                  IF l_cc_error_tbl IS NOT NULL AND l_cc_error_tbl.COUNT > 0
                  THEN
                     FOR i IN 1 .. l_cc_error_tbl.COUNT
                     LOOP
                        IF l_cc_error_tbl (i).ERROR_TYPE =
                                             rpm_conflict_library.plsql_error
                        THEN
                           l_pl_sql_error := 1;
                           EXIT;
                        END IF;
                     END LOOP;
                  END IF;

                  --
                  IF l_pl_sql_error = 1
                  THEN
                     o_cc_error_tbl := l_cc_error_tbl;
                     --
                     RETURN 0;
                  ELSE
                     l_fr_conflict := 1;
                     EXIT;
                  END IF;
               END IF;
            END LOOP;

            --
            -- Populate push back table
            --
            IF l_fr_conflict = 0
            THEN
               INSERT INTO rpm_pb_dates_gtt
                    VALUES (l_price_event_id, l_rf_dates (1));
            ELSE
               IF o_cc_error_tbl IS NULL
               THEN
                  o_cc_error_tbl := conflict_check_error_tbl ();
               END IF;

               --
               IF l_cc_error_tbl IS NOT NULL AND l_cc_error_tbl.COUNT > 0
               THEN
                  FOR i IN 1 .. l_cc_error_tbl.COUNT
                  LOOP
                     o_cc_error_tbl.EXTEND;
                     o_cc_error_tbl (o_cc_error_tbl.COUNT) :=
                                                           l_cc_error_tbl (i);
                  END LOOP;
               END IF;
            END IF;
         --
         END IF;
      END LOOP;

      --
      -- Clean the rpm_rf_dates_gtt table for the next roll forward
      --
      DELETE FROM rpm_rf_dates_gtt;

      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END roll_forward;

--------------------------------------------------------------------------------
/*Modified by Debadatta Patra for PrfNBS017910 on 15-07-2010 - SU/TU/MU Start */
   FUNCTION publish_changes (
      o_cc_error_tbl              OUT      conflict_check_error_tbl,
      i_rib_trans_id              IN       NUMBER,
      i_remove_price_event_ids    IN       obj_numeric_id_table,
      i_remove_price_event_type   IN       VARCHAR2,
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :Begin
      i_price_event_type          IN       VARCHAR2
   )
--Modifed by Robin Issac on 13-May-2010 as part of Oracle Chunk Back Porting :End
   RETURN NUMBER
   IS
 /*Modified by Debadatta Patra for PrfNBS017910 on 15-07-2010 - SU/TU/MU End */
--
      l_program         VARCHAR2 (100)
                                   := 'RPM_FUTURE_RETAIL_SQL.PUBLISH_CHANGES';
-- NBS00019162, Jini Moses, 15-Sep-2010 - Begin
      l_tsl_302_dummy   rpm_system_options.tsl_302_dummy%TYPE   := NULL;
      l_error_message   VARCHAR2 (10000);
-- NBS00019162, Jini Moses, 15-Sep-2010 - End
--
   BEGIN
      -- NBS00019162, Jini Moses, 15-Sep-2010 - Begin
      IF rpm_system_options_sql.get_tsl_302_dummy (l_tsl_302_dummy,
                                                   l_error_message
                                                  ) = FALSE
      THEN
         RETURN 0;
      END IF;

      -- NBS00019162, Jini Moses, 15-Sep-2010 - End

      --
      IF i_remove_price_event_type = rpm_conflict_library.price_change
      THEN
         IF rpm_cc_publish.stage_pc_remove_messages (o_cc_error_tbl,
                                                     i_rib_trans_id,
                                                     i_remove_price_event_ids
                                                    ) = 0
         THEN
            RETURN 0;
         END IF;
      -- Code removed from here and moved to rpm_zone_future_retail_sql for DefNBS16113
      END IF;

      --
      IF i_remove_price_event_type = rpm_conflict_library.clearance
      THEN
         -- NBS00019162, Jini Moses, 15-Sep-2010 - Begin
         IF (l_tsl_302_dummy = 0)
         THEN
            -- NBS00019162, Jini Moses, 15-Sep-2010 - End
            IF rpm_cc_publish.stage_clr_remove_messages
                                                    (o_cc_error_tbl,
                                                     i_rib_trans_id,
                                                     i_remove_price_event_ids
                                                    ) = 0
            THEN
               RETURN 0;
            END IF;
         -- NBS00019162, Jini Moses, 15-Sep-2010 - Begin
         END IF;
      -- NBS00019162, Jini Moses, 15-Sep-2010 - End
      END IF;

      --
      IF rpm_cc_publish.stage_pc_messages (o_cc_error_tbl, i_rib_trans_id) = 0
      THEN
         RETURN 0;
      END IF;

      --
      -- NBS00019162, Jini Moses, 15-Sep-2010 - Begin

      --Modified by Hema M for DefNBS019516 on 22-Oct-2010 Start
      IF rpm_bulk_cc_actions_sql.is_new_item_loc_ind != 'Y'
      THEN
         --Modified by Hema M for DefNBS019516 on 22-Oct-2010 End
         IF (l_tsl_302_dummy = 0)
         THEN
            -- NBS00019162, Jini Moses, 15-Sep-2010 - End
            IF rpm_cc_publish.stage_clr_messages (o_cc_error_tbl,
                                                  i_rib_trans_id
                                                 ) = 0
            THEN
               RETURN 0;
            END IF;
         -- NBS00019162, Jini Moses, 15-Sep-2010 - Begin
         END IF;

          -- NBS00019162, Jini Moses, 15-Sep-2010 - End
          --
         /*Modified by Debadatta Patra for PrfNBS017910 on 15-07-2010 - SU/TU/MU Start */
         IF i_price_event_type IN
               (rpm_conflict_library.simple_update,
                rpm_conflict_library.threshold_update,
                rpm_conflict_library.buyget_update,
                rpm_conflict_library.multibuy_update
               )
         THEN
            IF rpm_cc_publish.tsl_stage_z_thr_prom_can_msg (o_cc_error_tbl,
                                                            i_rib_trans_id
                                                           ) = 0
            THEN
               RETURN 0;
            END IF;

            IF rpm_cc_publish.tsl_stage_z_simp_prom_can_msg (o_cc_error_tbl,
                                                             i_rib_trans_id
                                                            ) = 0
            THEN
               RETURN 0;
            END IF;
         ELSE
            IF rpm_cc_publish.stage_simple_prom_messages (o_cc_error_tbl,
                                                          i_rib_trans_id
                                                         ) = 0
            THEN
               RETURN 0;
            END IF;

             --
             --03-Nov-2009 yohida Ramamurthy   Defect:DefNBS015225 Begin
            /* if RPM_BULK_CC_ACTIONS_SQL.IS_NEW_ITEM_LOC_IND !='Y' then*/
            IF rpm_cc_publish.stage_thresh_prom_messages (o_cc_error_tbl,
                                                          i_rib_trans_id
                                                         ) = 0
            THEN
               RETURN 0;
            END IF;
         --03-Nov-2009 yohida Ramamurthy   Defect:DefNBS015225 End
         --
         END IF;

         /*Modified by Debadatta Patra for PrfNBS017910 on 15-07-2010 - SU/TU/MU End */
         IF rpm_cc_publish.stage_bg_prom_messages (o_cc_error_tbl,
                                                   i_rib_trans_id
                                                  ) = 0
         THEN
            RETURN 0;
         END IF;

         --
         --03-Nov-2009 yohida Ramamurthy   Defect:DefNBS015225 Begin
         --20-Nov-2007 WiproEnabler/RK        Mod:93 Begin
         --28-Jun-2010 Deepali Rakshe        SIT Def: NBS00017899 Begin
         IF rpm_cc_publish.stage_mb_prom_messages (o_cc_error_tbl,
                                                   i_rib_trans_id
                                                  ) = 0
         THEN
            RETURN 0;
         END IF;
      --Modified by Hema M for DefNBS019516 on 22-Oct-2010 Start
      END IF;

       --Modified by Hema M for DefNBS019516 on 22-Oct-2010 End
      --28-Jun-2010 Deepali Rakshe        SIT Def: NBS00017899 End
      --20-Nov-2007 WiproEnabler/RK        Mod:93 End
      --03-Nov-2009 yohida Ramamurthy   Defect:DefNBS015225 End
      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END publish_changes;

--------------------------------------------------------------------------------
   FUNCTION push_back_error_rows (
      io_cc_error_tbl   IN OUT   conflict_check_error_tbl
   )
      RETURN NUMBER
   IS
      l_program        VARCHAR2 (100)
                              := 'RPM_FUTURE_RETAIL_SQL.PUSH_BACK_ERROR_ROWS';
--
      l_cc_error_tbl   conflict_check_error_tbl;

--
      CURSOR c_load_error_tbl
      IS
         SELECT   conflict_check_error_rec (price_event_id,
                                            future_retail_id,
                                            ERROR_TYPE,
                                            error_string
                                           )
             FROM (SELECT price_event_id, future_retail_id, ERROR_TYPE,
                          error_string,
                                       --
                                       item, LOCATION, action_date
                     FROM (SELECT rfrg2.price_event_id,
                                  rfrg2.future_retail_id, ccet.ERROR_TYPE,
                                  ccet.error_string,

                                  --
                                  RANK () OVER (PARTITION BY rfrg2.price_event_id, rfrg2.item, rfrg2.LOCATION ORDER BY rfrg2.action_date DESC)
                                                                AS rank_value,

                                  --
                                  rfrg2.item, rfrg2.LOCATION,
                                  rfrg2.action_date
                             FROM TABLE
                                     (CAST
                                         (io_cc_error_tbl AS conflict_check_error_tbl
                                         )
                                     ) ccet,
                                  rpm_future_retail_gtt rfrg1,
                                  rpm_future_retail_gtt rfrg2
                            WHERE rfrg2.rfr_rowid IS NOT NULL
                              --
                              AND rfrg2.action_date < rfrg1.action_date
                              AND rfrg2.LOCATION = rfrg1.LOCATION
                              AND rfrg2.item = rfrg1.item
                              --
                              AND rfrg1.rfr_rowid IS NULL
                              AND rfrg1.future_retail_id =
                                                         ccet.future_retail_id
                              AND rfrg1.price_event_id = ccet.price_event_id
                              AND rfrg2.price_event_id = ccet.price_event_id
                              --
                              AND ccet.ERROR_TYPE =
                                           rpm_conflict_library.conflict_error)
                    WHERE rank_value = 1
                   UNION
                   SELECT ccet.price_event_id, ccet.future_retail_id,
                          ccet.ERROR_TYPE, ccet.error_string,
                                                             --
                                                             rfrg.item,
                          rfrg.LOCATION, rfrg.action_date
                     FROM TABLE
                             (CAST
                                  (io_cc_error_tbl AS conflict_check_error_tbl)
                             ) ccet,
                          rpm_future_retail_gtt rfrg
                    WHERE rfrg.rfr_rowid IS NOT NULL
                      AND rfrg.future_retail_id = ccet.future_retail_id
                      AND rfrg.price_event_id = ccet.price_event_id
                      --
                      AND ccet.ERROR_TYPE =
                                           rpm_conflict_library.conflict_error
                   UNION
                   SELECT ccet.price_event_id, ccet.future_retail_id,
                          ccet.ERROR_TYPE, ccet.error_string,
                                                             --
                          NULL, NULL, NULL
                     FROM TABLE
                             (CAST
                                  (io_cc_error_tbl AS conflict_check_error_tbl)
                             ) ccet
                    WHERE ccet.ERROR_TYPE = rpm_conflict_library.plsql_error)
         ORDER BY item, LOCATION, action_date;
   BEGIN
      --
      OPEN c_load_error_tbl;

      FETCH c_load_error_tbl
      BULK COLLECT INTO l_cc_error_tbl;

      CLOSE c_load_error_tbl;

      io_cc_error_tbl := l_cc_error_tbl;

      --
      IF io_cc_error_tbl IS NOT NULL AND io_cc_error_tbl.COUNT > 0
      THEN
         DELETE FROM rpm_future_retail_gtt
               WHERE price_event_id IN (
                        SELECT ccet.price_event_id
                          FROM TABLE
                                  (CAST
                                      (io_cc_error_tbl AS conflict_check_error_tbl
                                      )
                                  ) ccet);
      END IF;

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         io_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END push_back_error_rows;

--------------------------------------------------------------------------------
--19-Apr-2010 BC_KC  NBS00017378      performances fix Begin

   --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
   FUNCTION push_back (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      l_price_event_id     IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program           VARCHAR2 (100) := 'RPM_FUTURE_RETAIL_SQL.PUSH_BACK';
--
      l_active_state      VARCHAR2 (50)        := 'notactive';

      CURSOR c_active_promo
      IS
         SELECT DISTINCT state
                    FROM rpm_promo_comp_detail
                   WHERE rpm_promo_comp_detail_id IN (
                            SELECT VALUE (ID)
                              FROM TABLE
                                      (CAST
                                          (NVL (l_price_event_id,
                                                obj_numeric_id_table (0)
                                               ) AS obj_numeric_id_table
                                          )
                                      ) ID);

--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
      l_price_event_ids   obj_numeric_id_table;
      l_dept              NUMBER;

      CURSOR c1
      IS
         SELECT DISTINCT dept
                    FROM rpm_future_retail_gtt;
   BEGIN
      OPEN c1;

      FETCH c1
      BULK COLLECT INTO l_price_event_ids;

      CLOSE c1;

      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
      IF i_price_event_type IN
            (rpm_conflict_library.simple_promotion,
             rpm_conflict_library.simple_update,
             rpm_conflict_library.threshold_promotion,
             rpm_conflict_library.threshold_update,
             rpm_conflict_library.multibuy_promotion,
             rpm_conflict_library.multibuy_update
            )
      THEN
         FOR v_rec IN c_active_promo
         LOOP
            IF v_rec.state = 'pcd.active'
            THEN
               l_active_state := v_rec.state;
               EXIT;
            END IF;
         END LOOP;
      END IF;

      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
      IF l_price_event_ids IS NOT NULL AND l_price_event_ids.COUNT > 0
      THEN
         IF l_price_event_ids.COUNT > 64
         THEN
            l_program := 'RPM_FUTURE_RETAIL_SQL.PUSH_BACK_TABLE';
            /* BC 20/10/2009 added below hint may need to revisit under full volumes - NBS000015287*/
            -- renamed alias rfr_pbt to identify within trace file
            MERGE                         /*+ rowid(rfr_pbt) */ INTO rpm_future_retail rfr_pbt
               USING (SELECT /*+ full(rfrg) */
                             gtt.*
                        FROM rpm_future_retail_gtt gtt
                                                      /*where trunc(gtt.action_date) >= trunc(LP_push_back_start_date)*/
            ) rfrg
               ON (rfr_pbt.ROWID = rfrg.rfr_rowid)
               WHEN MATCHED THEN
                  UPDATE
                     SET rfr_pbt.selling_retail = rfrg.selling_retail,
                         rfr_pbt.selling_retail_currency =
                                                 rfrg.selling_retail_currency,
                         rfr_pbt.selling_uom = rfrg.selling_uom,
                         rfr_pbt.multi_units = rfrg.multi_units,
                         rfr_pbt.multi_unit_retail = rfrg.multi_unit_retail,
                         rfr_pbt.multi_unit_retail_currency =
                                              rfrg.multi_unit_retail_currency,
                         rfr_pbt.multi_selling_uom = rfrg.multi_selling_uom,
                         rfr_pbt.clear_retail = rfrg.clear_retail,
                         rfr_pbt.clear_retail_currency =
                                                   rfrg.clear_retail_currency,
                         rfr_pbt.clear_uom = rfrg.clear_uom,
                         rfr_pbt.simple_promo_retail =
                                                     rfrg.simple_promo_retail,
                         rfr_pbt.simple_promo_retail_currency =
                                            rfrg.simple_promo_retail_currency,
                         rfr_pbt.simple_promo_uom = rfrg.simple_promo_uom,
                         rfr_pbt.complex_promo_retail =
                                                    rfrg.complex_promo_retail,
                         rfr_pbt.complex_promo_retail_currency =
                                           rfrg.complex_promo_retail_currency,
                         rfr_pbt.complex_promo_uom = rfrg.complex_promo_uom,
                         rfr_pbt.price_change_id = rfrg.price_change_id,
                         rfr_pbt.price_change_display_id =
                                                 rfrg.price_change_display_id,
                         rfr_pbt.pc_exception_parent_id =
                                                  rfrg.pc_exception_parent_id,
                         rfr_pbt.pc_change_type = rfrg.pc_change_type,
                         rfr_pbt.pc_change_amount = rfrg.pc_change_amount,
                         rfr_pbt.pc_change_currency = rfrg.pc_change_currency,
                         rfr_pbt.pc_change_percent = rfrg.pc_change_percent,
                         rfr_pbt.pc_change_selling_uom =
                                                   rfrg.pc_change_selling_uom,
                         rfr_pbt.pc_null_multi_ind = rfrg.pc_null_multi_ind,
                         rfr_pbt.pc_multi_units = rfrg.pc_multi_units,
                         rfr_pbt.pc_multi_unit_retail =
                                                    rfrg.pc_multi_unit_retail,
                         rfr_pbt.pc_multi_unit_retail_currency =
                                           rfrg.pc_multi_unit_retail_currency,
                         rfr_pbt.pc_multi_selling_uom =
                                                    rfrg.pc_multi_selling_uom,
                         rfr_pbt.pc_price_guide_id = rfrg.pc_price_guide_id,
                         rfr_pbt.clearance_id = rfrg.clearance_id,
                         rfr_pbt.clearance_display_id =
                                                    rfrg.clearance_display_id,
                         rfr_pbt.clear_mkdn_index = rfrg.clear_mkdn_index,
                         rfr_pbt.clear_start_ind = rfrg.clear_start_ind,
                         rfr_pbt.clear_change_type = rfrg.clear_change_type,
                         rfr_pbt.clear_change_amount =
                                                     rfrg.clear_change_amount,
                         rfr_pbt.clear_change_currency =
                                                   rfrg.clear_change_currency,
                         rfr_pbt.clear_change_percent =
                                                    rfrg.clear_change_percent,
                         rfr_pbt.clear_change_selling_uom =
                                                rfrg.clear_change_selling_uom,
                         rfr_pbt.clear_price_guide_id =
                                                    rfrg.clear_price_guide_id,
                         rfr_pbt.promotion1_id = rfrg.promotion1_id,
                         rfr_pbt.promo1_display_id = rfrg.promo1_display_id,
                         rfr_pbt.p1_start_date = rfrg.p1_start_date,
                         rfr_pbt.p1_rank = rfrg.p1_rank,
                         rfr_pbt.p1_secondary_ind = rfrg.p1_secondary_ind,
                         rfr_pbt.p1_component1_id = rfrg.p1_component1_id,
                         rfr_pbt.p1_comp1_display_id =
                                                     rfrg.p1_comp1_display_id,
                         rfr_pbt.p1_c1_detail_id = rfrg.p1_c1_detail_id,
                         rfr_pbt.p1_c1_type = rfrg.p1_c1_type,
                         rfr_pbt.p1_c1_rank = rfrg.p1_c1_rank,
                         rfr_pbt.p1_c1_secondary_ind =
                                                     rfrg.p1_c1_secondary_ind,
                         rfr_pbt.p1_c1_start_date = rfrg.p1_c1_start_date,
                         rfr_pbt.p1_c1_start_ind = rfrg.p1_c1_start_ind,
                         rfr_pbt.p1_c1_apply_to_code =
                                                     rfrg.p1_c1_apply_to_code,
                         rfr_pbt.p1_c1_change_type = rfrg.p1_c1_change_type,
                         rfr_pbt.p1_c1_change_amount =
                                                     rfrg.p1_c1_change_amount,
                         rfr_pbt.p1_c1_change_currency =
                                                   rfrg.p1_c1_change_currency,
                         rfr_pbt.p1_c1_change_percent =
                                                    rfrg.p1_c1_change_percent,
                         rfr_pbt.p1_c1_change_selling_uom =
                                                rfrg.p1_c1_change_selling_uom,
                         rfr_pbt.p1_c1_price_guide_id =
                                                    rfrg.p1_c1_price_guide_id,
                         rfr_pbt.p1_component2_id = rfrg.p1_component2_id,
                         rfr_pbt.p1_comp2_display_id =
                                                     rfrg.p1_comp2_display_id,
                         rfr_pbt.p1_c2_detail_id = rfrg.p1_c2_detail_id,
                         rfr_pbt.p1_c2_type = rfrg.p1_c2_type,
                         rfr_pbt.p1_c2_rank = rfrg.p1_c2_rank,
                         rfr_pbt.p1_c2_secondary_ind =
                                                     rfrg.p1_c2_secondary_ind,
                         rfr_pbt.p1_c2_start_date = rfrg.p1_c2_start_date,
                         rfr_pbt.p1_c2_start_ind = rfrg.p1_c2_start_ind,
                         rfr_pbt.p1_c2_apply_to_code =
                                                     rfrg.p1_c2_apply_to_code,
                         rfr_pbt.p1_c2_change_type = rfrg.p1_c2_change_type,
                         rfr_pbt.p1_c2_change_amount =
                                                     rfrg.p1_c2_change_amount,
                         rfr_pbt.p1_c2_change_currency =
                                                   rfrg.p1_c2_change_currency,
                         rfr_pbt.p1_c2_change_percent =
                                                    rfrg.p1_c2_change_percent,
                         rfr_pbt.p1_c2_change_selling_uom =
                                                rfrg.p1_c2_change_selling_uom,
                         rfr_pbt.p1_c2_price_guide_id =
                                                    rfrg.p1_c2_price_guide_id,
                         rfr_pbt.p1_exclusion1_id = rfrg.p1_exclusion1_id,
                         rfr_pbt.p1_exclusion1_display_id =
                                                rfrg.p1_exclusion1_display_id,
                         rfr_pbt.p1_exclusion1_type = rfrg.p1_exclusion1_type,
                         rfr_pbt.p1_e1_start_ind = rfrg.p1_e1_start_ind,
                         rfr_pbt.p1_exclusion2_id = rfrg.p1_exclusion2_id,
                         rfr_pbt.p1_exclusion2_display_id =
                                                rfrg.p1_exclusion2_display_id,
                         rfr_pbt.p1_exclusion2_type = rfrg.p1_exclusion2_type,
                         rfr_pbt.p1_e2_start_ind = rfrg.p1_e2_start_ind,
                         rfr_pbt.promotion2_id = rfrg.promotion2_id,
                         rfr_pbt.promo2_display_id = rfrg.promo2_display_id,
                         rfr_pbt.p2_start_date = rfrg.p2_start_date,
                         rfr_pbt.p2_rank = rfrg.p2_rank,
                         rfr_pbt.p2_secondary_ind = rfrg.p2_secondary_ind,
                         rfr_pbt.p2_component1_id = rfrg.p2_component1_id,
                         rfr_pbt.p2_comp1_display_id =
                                                     rfrg.p2_comp1_display_id,
                         rfr_pbt.p2_c1_detail_id = rfrg.p2_c1_detail_id,
                         rfr_pbt.p2_c1_type = rfrg.p2_c1_type,
                         rfr_pbt.p2_c1_rank = rfrg.p2_c1_rank,
                         rfr_pbt.p2_c1_secondary_ind =
                                                     rfrg.p2_c1_secondary_ind,
                         rfr_pbt.p2_c1_start_date = rfrg.p2_c1_start_date,
                         rfr_pbt.p2_c1_start_ind = rfrg.p2_c1_start_ind,
                         rfr_pbt.p2_c1_apply_to_code =
                                                     rfrg.p2_c1_apply_to_code,
                         rfr_pbt.p2_c1_change_type = rfrg.p2_c1_change_type,
                         rfr_pbt.p2_c1_change_amount =
                                                     rfrg.p2_c1_change_amount,
                         rfr_pbt.p2_c1_change_currency =
                                                   rfrg.p2_c1_change_currency,
                         rfr_pbt.p2_c1_change_percent =
                                                    rfrg.p2_c1_change_percent,
                         rfr_pbt.p2_c1_change_selling_uom =
                                                rfrg.p2_c1_change_selling_uom,
                         rfr_pbt.p2_c1_price_guide_id =
                                                    rfrg.p2_c1_price_guide_id,
                         rfr_pbt.p2_component2_id = rfrg.p2_component2_id,
                         rfr_pbt.p2_comp2_display_id =
                                                     rfrg.p2_comp2_display_id,
                         rfr_pbt.p2_c2_detail_id = rfrg.p2_c2_detail_id,
                         rfr_pbt.p2_c2_type = rfrg.p2_c2_type,
                         rfr_pbt.p2_c2_rank = rfrg.p2_c2_rank,
                         rfr_pbt.p2_c2_secondary_ind =
                                                     rfrg.p2_c2_secondary_ind,
                         rfr_pbt.p2_c2_start_date = rfrg.p2_c2_start_date,
                         rfr_pbt.p2_c2_start_ind = rfrg.p2_c2_start_ind,
                         rfr_pbt.p2_c2_apply_to_code =
                                                     rfrg.p2_c2_apply_to_code,
                         rfr_pbt.p2_c2_change_type = rfrg.p2_c2_change_type,
                         rfr_pbt.p2_c2_change_amount =
                                                     rfrg.p2_c2_change_amount,
                         rfr_pbt.p2_c2_change_currency =
                                                   rfrg.p2_c2_change_currency,
                         rfr_pbt.p2_c2_change_percent =
                                                    rfrg.p2_c2_change_percent,
                         rfr_pbt.p2_c2_change_selling_uom =
                                                rfrg.p2_c2_change_selling_uom,
                         rfr_pbt.p2_c2_price_guide_id =
                                                    rfrg.p2_c2_price_guide_id,
                         rfr_pbt.p2_exclusion1_id = rfrg.p2_exclusion1_id,
                         rfr_pbt.p2_exclusion1_display_id =
                                                rfrg.p2_exclusion1_display_id,
                         rfr_pbt.p2_exclusion1_type = rfrg.p2_exclusion1_type,
                         rfr_pbt.p2_e1_start_ind = rfrg.p2_e1_start_ind,
                         rfr_pbt.p2_exclusion2_id = rfrg.p2_exclusion2_id,
                         rfr_pbt.p2_exclusion2_display_id =
                                                rfrg.p2_exclusion2_display_id,
                         rfr_pbt.p2_exclusion2_type = rfrg.p2_exclusion2_type,
                         rfr_pbt.p2_e2_start_ind = rfrg.p2_e2_start_ind,
                         rfr_pbt.loc_move_from_zone_id =
                                                   rfrg.loc_move_from_zone_id,
                         rfr_pbt.loc_move_to_zone_id =
                                                     rfrg.loc_move_to_zone_id,
                         rfr_pbt.location_move_id = rfrg.location_move_id
               WHEN NOT MATCHED THEN
                  INSERT (future_retail_id, dept, CLASS, subclass, item,
                          zone_node_type, LOCATION, action_date,
                          selling_retail, selling_retail_currency,
                          selling_uom, multi_units, multi_unit_retail,
                          multi_unit_retail_currency, multi_selling_uom,
                          clear_retail, clear_retail_currency, clear_uom,
                          simple_promo_retail, simple_promo_retail_currency,
                          simple_promo_uom, complex_promo_retail,
                          complex_promo_retail_currency, complex_promo_uom,
                          price_change_id, price_change_display_id,
                          pc_exception_parent_id, pc_change_type,
                          pc_change_amount, pc_change_currency,
                          pc_change_percent, pc_change_selling_uom,
                          pc_null_multi_ind, pc_multi_units,
                          pc_multi_unit_retail,
                          pc_multi_unit_retail_currency,
                          pc_multi_selling_uom, pc_price_guide_id,
                          clearance_id, clearance_display_id,
                          clear_mkdn_index, clear_start_ind,
                          clear_change_type, clear_change_amount,
                          clear_change_currency, clear_change_percent,
                          clear_change_selling_uom, clear_price_guide_id,
                          promotion1_id, promo1_display_id, p1_start_date,
                          p1_rank, p1_secondary_ind, p1_component1_id,
                          p1_comp1_display_id, p1_c1_detail_id, p1_c1_type,
                          p1_c1_rank, p1_c1_secondary_ind, p1_c1_start_date,
                          p1_c1_start_ind, p1_c1_apply_to_code,
                          p1_c1_change_type, p1_c1_change_amount,
                          p1_c1_change_currency, p1_c1_change_percent,
                          p1_c1_change_selling_uom, p1_c1_price_guide_id,
                          p1_component2_id, p1_comp2_display_id,
                          p1_c2_detail_id, p1_c2_type, p1_c2_rank,
                          p1_c2_secondary_ind, p1_c2_start_date,
                          p1_c2_start_ind, p1_c2_apply_to_code,
                          p1_c2_change_type, p1_c2_change_amount,
                          p1_c2_change_currency, p1_c2_change_percent,
                          p1_c2_change_selling_uom, p1_c2_price_guide_id,
                          p1_exclusion1_id, p1_exclusion1_display_id,
                          p1_exclusion1_type, p1_e1_start_ind,
                          p1_exclusion2_id, p1_exclusion2_display_id,
                          p1_exclusion2_type, p1_e2_start_ind, promotion2_id,
                          promo2_display_id, p2_start_date, p2_rank,
                          p2_secondary_ind, p2_component1_id,
                          p2_comp1_display_id, p2_c1_detail_id, p2_c1_type,
                          p2_c1_rank, p2_c1_secondary_ind, p2_c1_start_date,
                          p2_c1_start_ind, p2_c1_apply_to_code,
                          p2_c1_change_type, p2_c1_change_amount,
                          p2_c1_change_currency, p2_c1_change_percent,
                          p2_c1_change_selling_uom, p2_c1_price_guide_id,
                          p2_component2_id, p2_comp2_display_id,
                          p2_c2_detail_id, p2_c2_type, p2_c2_rank,
                          p2_c2_secondary_ind, p2_c2_start_date,
                          p2_c2_start_ind, p2_c2_apply_to_code,
                          p2_c2_change_type, p2_c2_change_amount,
                          p2_c2_change_currency, p2_c2_change_percent,
                          p2_c2_change_selling_uom, p2_c2_price_guide_id,
                          p2_exclusion1_id, p2_exclusion1_display_id,
                          p2_exclusion1_type, p2_e1_start_ind,
                          p2_exclusion2_id, p2_exclusion2_display_id,
                          p2_exclusion2_type, p2_e2_start_ind,
                          loc_move_from_zone_id, loc_move_to_zone_id,
                          location_move_id)
                  VALUES (rfrg.future_retail_id, rfrg.dept, rfrg.CLASS,
                          rfrg.subclass, rfrg.item, rfrg.zone_node_type,
                          rfrg.LOCATION, rfrg.action_date,
                          rfrg.selling_retail, rfrg.selling_retail_currency,
                          rfrg.selling_uom, rfrg.multi_units,
                          rfrg.multi_unit_retail,
                          rfrg.multi_unit_retail_currency,
                          rfrg.multi_selling_uom, rfrg.clear_retail,
                          rfrg.clear_retail_currency, rfrg.clear_uom,
                          rfrg.simple_promo_retail,
                          rfrg.simple_promo_retail_currency,
                          rfrg.simple_promo_uom, rfrg.complex_promo_retail,
                          rfrg.complex_promo_retail_currency,
                          rfrg.complex_promo_uom, rfrg.price_change_id,
                          rfrg.price_change_display_id,
                          rfrg.pc_exception_parent_id, rfrg.pc_change_type,
                          rfrg.pc_change_amount, rfrg.pc_change_currency,
                          rfrg.pc_change_percent, rfrg.pc_change_selling_uom,
                          rfrg.pc_null_multi_ind, rfrg.pc_multi_units,
                          rfrg.pc_multi_unit_retail,
                          rfrg.pc_multi_unit_retail_currency,
                          rfrg.pc_multi_selling_uom, rfrg.pc_price_guide_id,
                          rfrg.clearance_id, rfrg.clearance_display_id,
                          rfrg.clear_mkdn_index, rfrg.clear_start_ind,
                          rfrg.clear_change_type, rfrg.clear_change_amount,
                          rfrg.clear_change_currency,
                          rfrg.clear_change_percent,
                          rfrg.clear_change_selling_uom,
                          rfrg.clear_price_guide_id, rfrg.promotion1_id,
                          rfrg.promo1_display_id, rfrg.p1_start_date,
                          rfrg.p1_rank, rfrg.p1_secondary_ind,
                          rfrg.p1_component1_id, rfrg.p1_comp1_display_id,
                          rfrg.p1_c1_detail_id, rfrg.p1_c1_type,
                          rfrg.p1_c1_rank, rfrg.p1_c1_secondary_ind,
                          rfrg.p1_c1_start_date, rfrg.p1_c1_start_ind,
                          rfrg.p1_c1_apply_to_code, rfrg.p1_c1_change_type,
                          rfrg.p1_c1_change_amount,
                          rfrg.p1_c1_change_currency,
                          rfrg.p1_c1_change_percent,
                          rfrg.p1_c1_change_selling_uom,
                          rfrg.p1_c1_price_guide_id, rfrg.p1_component2_id,
                          rfrg.p1_comp2_display_id, rfrg.p1_c2_detail_id,
                          rfrg.p1_c2_type, rfrg.p1_c2_rank,
                          rfrg.p1_c2_secondary_ind, rfrg.p1_c2_start_date,
                          rfrg.p1_c2_start_ind, rfrg.p1_c2_apply_to_code,
                          rfrg.p1_c2_change_type, rfrg.p1_c2_change_amount,
                          rfrg.p1_c2_change_currency,
                          rfrg.p1_c2_change_percent,
                          rfrg.p1_c2_change_selling_uom,
                          rfrg.p1_c2_price_guide_id, rfrg.p1_exclusion1_id,
                          rfrg.p1_exclusion1_display_id,
                          rfrg.p1_exclusion1_type, rfrg.p1_e1_start_ind,
                          rfrg.p1_exclusion2_id,
                          rfrg.p1_exclusion2_display_id,
                          rfrg.p1_exclusion2_type, rfrg.p1_e2_start_ind,
                          rfrg.promotion2_id, rfrg.promo2_display_id,
                          rfrg.p2_start_date, rfrg.p2_rank,
                          rfrg.p2_secondary_ind, rfrg.p2_component1_id,
                          rfrg.p2_comp1_display_id, rfrg.p2_c1_detail_id,
                          rfrg.p2_c1_type, rfrg.p2_c1_rank,
                          rfrg.p2_c1_secondary_ind, rfrg.p2_c1_start_date,
                          rfrg.p2_c1_start_ind, rfrg.p2_c1_apply_to_code,
                          rfrg.p2_c1_change_type, rfrg.p2_c1_change_amount,
                          rfrg.p2_c1_change_currency,
                          rfrg.p2_c1_change_percent,
                          rfrg.p2_c1_change_selling_uom,
                          rfrg.p2_c1_price_guide_id, rfrg.p2_component2_id,
                          rfrg.p2_comp2_display_id, rfrg.p2_c2_detail_id,
                          rfrg.p2_c2_type, rfrg.p2_c2_rank,
                          rfrg.p2_c2_secondary_ind, rfrg.p2_c2_start_date,
                          rfrg.p2_c2_start_ind, rfrg.p2_c2_apply_to_code,
                          rfrg.p2_c2_change_type, rfrg.p2_c2_change_amount,
                          rfrg.p2_c2_change_currency,
                          rfrg.p2_c2_change_percent,
                          rfrg.p2_c2_change_selling_uom,
                          rfrg.p2_c2_price_guide_id, rfrg.p2_exclusion1_id,
                          rfrg.p2_exclusion1_display_id,
                          rfrg.p2_exclusion1_type, rfrg.p2_e1_start_ind,
                          rfrg.p2_exclusion2_id,
                          rfrg.p2_exclusion2_display_id,
                          rfrg.p2_exclusion2_type, rfrg.p2_e2_start_ind,
                          rfrg.loc_move_from_zone_id,
                          rfrg.loc_move_to_zone_id, rfrg.location_move_id);

            --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
            IF (l_active_state != 'pcd.active')
            THEN
               DELETE FROM rpm_future_retail rfr
                     WHERE rfr.ROWID IN (SELECT rfrg.rfr_rowid
                                           FROM rpm_future_retail_gtt rfrg
                                          WHERE rfrg.timeline_seq = -999);
            END IF;
         --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
         ELSE
            l_program := 'RPM_FUTURE_RETAIL_SQL.PUSH_BACK_DEPT';

            FOR i IN 1 .. l_price_event_ids.COUNT
            LOOP
               l_dept := l_price_event_ids (i);
               MERGE INTO rpm_future_retail rfr_pbd
                  USING (SELECT /*+ full(rfrg) */
                                gtt.*
                           FROM rpm_future_retail_gtt gtt
                          WHERE gtt.dept = l_dept
                                                 /*and trunc(gtt.action_date) >= trunc(LP_push_back_start_date)*/
               ) rfrg
                  ON (rfr_pbd.dept = l_dept
                      AND rfr_pbd.ROWID = rfrg.rfr_rowid)
                  WHEN MATCHED THEN
                     UPDATE
                        SET rfr_pbd.selling_retail = rfrg.selling_retail,
                            rfr_pbd.selling_retail_currency =
                                                 rfrg.selling_retail_currency,
                            rfr_pbd.selling_uom = rfrg.selling_uom,
                            rfr_pbd.multi_units = rfrg.multi_units,
                            rfr_pbd.multi_unit_retail =
                                                       rfrg.multi_unit_retail,
                            rfr_pbd.multi_unit_retail_currency =
                                              rfrg.multi_unit_retail_currency,
                            rfr_pbd.multi_selling_uom =
                                                       rfrg.multi_selling_uom,
                            rfr_pbd.clear_retail = rfrg.clear_retail,
                            rfr_pbd.clear_retail_currency =
                                                   rfrg.clear_retail_currency,
                            rfr_pbd.clear_uom = rfrg.clear_uom,
                            rfr_pbd.simple_promo_retail =
                                                     rfrg.simple_promo_retail,
                            rfr_pbd.simple_promo_retail_currency =
                                            rfrg.simple_promo_retail_currency,
                            rfr_pbd.simple_promo_uom = rfrg.simple_promo_uom,
                            rfr_pbd.complex_promo_retail =
                                                    rfrg.complex_promo_retail,
                            rfr_pbd.complex_promo_retail_currency =
                                           rfrg.complex_promo_retail_currency,
                            rfr_pbd.complex_promo_uom =
                                                       rfrg.complex_promo_uom,
                            rfr_pbd.price_change_id = rfrg.price_change_id,
                            rfr_pbd.price_change_display_id =
                                                 rfrg.price_change_display_id,
                            rfr_pbd.pc_exception_parent_id =
                                                  rfrg.pc_exception_parent_id,
                            rfr_pbd.pc_change_type = rfrg.pc_change_type,
                            rfr_pbd.pc_change_amount = rfrg.pc_change_amount,
                            rfr_pbd.pc_change_currency =
                                                      rfrg.pc_change_currency,
                            rfr_pbd.pc_change_percent =
                                                       rfrg.pc_change_percent,
                            rfr_pbd.pc_change_selling_uom =
                                                   rfrg.pc_change_selling_uom,
                            rfr_pbd.pc_null_multi_ind =
                                                       rfrg.pc_null_multi_ind,
                            rfr_pbd.pc_multi_units = rfrg.pc_multi_units,
                            rfr_pbd.pc_multi_unit_retail =
                                                    rfrg.pc_multi_unit_retail,
                            rfr_pbd.pc_multi_unit_retail_currency =
                                           rfrg.pc_multi_unit_retail_currency,
                            rfr_pbd.pc_multi_selling_uom =
                                                    rfrg.pc_multi_selling_uom,
                            rfr_pbd.pc_price_guide_id =
                                                       rfrg.pc_price_guide_id,
                            rfr_pbd.clearance_id = rfrg.clearance_id,
                            rfr_pbd.clearance_display_id =
                                                    rfrg.clearance_display_id,
                            rfr_pbd.clear_mkdn_index = rfrg.clear_mkdn_index,
                            rfr_pbd.clear_start_ind = rfrg.clear_start_ind,
                            rfr_pbd.clear_change_type =
                                                       rfrg.clear_change_type,
                            rfr_pbd.clear_change_amount =
                                                     rfrg.clear_change_amount,
                            rfr_pbd.clear_change_currency =
                                                   rfrg.clear_change_currency,
                            rfr_pbd.clear_change_percent =
                                                    rfrg.clear_change_percent,
                            rfr_pbd.clear_change_selling_uom =
                                                rfrg.clear_change_selling_uom,
                            rfr_pbd.clear_price_guide_id =
                                                    rfrg.clear_price_guide_id,
                            rfr_pbd.promotion1_id = rfrg.promotion1_id,
                            rfr_pbd.promo1_display_id =
                                                       rfrg.promo1_display_id,
                            rfr_pbd.p1_start_date = rfrg.p1_start_date,
                            rfr_pbd.p1_rank = rfrg.p1_rank,
                            rfr_pbd.p1_secondary_ind = rfrg.p1_secondary_ind,
                            rfr_pbd.p1_component1_id = rfrg.p1_component1_id,
                            rfr_pbd.p1_comp1_display_id =
                                                     rfrg.p1_comp1_display_id,
                            rfr_pbd.p1_c1_detail_id = rfrg.p1_c1_detail_id,
                            rfr_pbd.p1_c1_type = rfrg.p1_c1_type,
                            rfr_pbd.p1_c1_rank = rfrg.p1_c1_rank,
                            rfr_pbd.p1_c1_secondary_ind =
                                                     rfrg.p1_c1_secondary_ind,
                            rfr_pbd.p1_c1_start_date = rfrg.p1_c1_start_date,
                            rfr_pbd.p1_c1_start_ind = rfrg.p1_c1_start_ind,
                            rfr_pbd.p1_c1_apply_to_code =
                                                     rfrg.p1_c1_apply_to_code,
                            rfr_pbd.p1_c1_change_type =
                                                       rfrg.p1_c1_change_type,
                            rfr_pbd.p1_c1_change_amount =
                                                     rfrg.p1_c1_change_amount,
                            rfr_pbd.p1_c1_change_currency =
                                                   rfrg.p1_c1_change_currency,
                            rfr_pbd.p1_c1_change_percent =
                                                    rfrg.p1_c1_change_percent,
                            rfr_pbd.p1_c1_change_selling_uom =
                                                rfrg.p1_c1_change_selling_uom,
                            rfr_pbd.p1_c1_price_guide_id =
                                                    rfrg.p1_c1_price_guide_id,
                            rfr_pbd.p1_component2_id = rfrg.p1_component2_id,
                            rfr_pbd.p1_comp2_display_id =
                                                     rfrg.p1_comp2_display_id,
                            rfr_pbd.p1_c2_detail_id = rfrg.p1_c2_detail_id,
                            rfr_pbd.p1_c2_type = rfrg.p1_c2_type,
                            rfr_pbd.p1_c2_rank = rfrg.p1_c2_rank,
                            rfr_pbd.p1_c2_secondary_ind =
                                                     rfrg.p1_c2_secondary_ind,
                            rfr_pbd.p1_c2_start_date = rfrg.p1_c2_start_date,
                            rfr_pbd.p1_c2_start_ind = rfrg.p1_c2_start_ind,
                            rfr_pbd.p1_c2_apply_to_code =
                                                     rfrg.p1_c2_apply_to_code,
                            rfr_pbd.p1_c2_change_type =
                                                       rfrg.p1_c2_change_type,
                            rfr_pbd.p1_c2_change_amount =
                                                     rfrg.p1_c2_change_amount,
                            rfr_pbd.p1_c2_change_currency =
                                                   rfrg.p1_c2_change_currency,
                            rfr_pbd.p1_c2_change_percent =
                                                    rfrg.p1_c2_change_percent,
                            rfr_pbd.p1_c2_change_selling_uom =
                                                rfrg.p1_c2_change_selling_uom,
                            rfr_pbd.p1_c2_price_guide_id =
                                                    rfrg.p1_c2_price_guide_id,
                            rfr_pbd.p1_exclusion1_id = rfrg.p1_exclusion1_id,
                            rfr_pbd.p1_exclusion1_display_id =
                                                rfrg.p1_exclusion1_display_id,
                            rfr_pbd.p1_exclusion1_type =
                                                      rfrg.p1_exclusion1_type,
                            rfr_pbd.p1_e1_start_ind = rfrg.p1_e1_start_ind,
                            rfr_pbd.p1_exclusion2_id = rfrg.p1_exclusion2_id,
                            rfr_pbd.p1_exclusion2_display_id =
                                                rfrg.p1_exclusion2_display_id,
                            rfr_pbd.p1_exclusion2_type =
                                                      rfrg.p1_exclusion2_type,
                            rfr_pbd.p1_e2_start_ind = rfrg.p1_e2_start_ind,
                            rfr_pbd.promotion2_id = rfrg.promotion2_id,
                            rfr_pbd.promo2_display_id =
                                                       rfrg.promo2_display_id,
                            rfr_pbd.p2_start_date = rfrg.p2_start_date,
                            rfr_pbd.p2_rank = rfrg.p2_rank,
                            rfr_pbd.p2_secondary_ind = rfrg.p2_secondary_ind,
                            rfr_pbd.p2_component1_id = rfrg.p2_component1_id,
                            rfr_pbd.p2_comp1_display_id =
                                                     rfrg.p2_comp1_display_id,
                            rfr_pbd.p2_c1_detail_id = rfrg.p2_c1_detail_id,
                            rfr_pbd.p2_c1_type = rfrg.p2_c1_type,
                            rfr_pbd.p2_c1_rank = rfrg.p2_c1_rank,
                            rfr_pbd.p2_c1_secondary_ind =
                                                     rfrg.p2_c1_secondary_ind,
                            rfr_pbd.p2_c1_start_date = rfrg.p2_c1_start_date,
                            rfr_pbd.p2_c1_start_ind = rfrg.p2_c1_start_ind,
                            rfr_pbd.p2_c1_apply_to_code =
                                                     rfrg.p2_c1_apply_to_code,
                            rfr_pbd.p2_c1_change_type =
                                                       rfrg.p2_c1_change_type,
                            rfr_pbd.p2_c1_change_amount =
                                                     rfrg.p2_c1_change_amount,
                            rfr_pbd.p2_c1_change_currency =
                                                   rfrg.p2_c1_change_currency,
                            rfr_pbd.p2_c1_change_percent =
                                                    rfrg.p2_c1_change_percent,
                            rfr_pbd.p2_c1_change_selling_uom =
                                                rfrg.p2_c1_change_selling_uom,
                            rfr_pbd.p2_c1_price_guide_id =
                                                    rfrg.p2_c1_price_guide_id,
                            rfr_pbd.p2_component2_id = rfrg.p2_component2_id,
                            rfr_pbd.p2_comp2_display_id =
                                                     rfrg.p2_comp2_display_id,
                            rfr_pbd.p2_c2_detail_id = rfrg.p2_c2_detail_id,
                            rfr_pbd.p2_c2_type = rfrg.p2_c2_type,
                            rfr_pbd.p2_c2_rank = rfrg.p2_c2_rank,
                            rfr_pbd.p2_c2_secondary_ind =
                                                     rfrg.p2_c2_secondary_ind,
                            rfr_pbd.p2_c2_start_date = rfrg.p2_c2_start_date,
                            rfr_pbd.p2_c2_start_ind = rfrg.p2_c2_start_ind,
                            rfr_pbd.p2_c2_apply_to_code =
                                                     rfrg.p2_c2_apply_to_code,
                            rfr_pbd.p2_c2_change_type =
                                                       rfrg.p2_c2_change_type,
                            rfr_pbd.p2_c2_change_amount =
                                                     rfrg.p2_c2_change_amount,
                            rfr_pbd.p2_c2_change_currency =
                                                   rfrg.p2_c2_change_currency,
                            rfr_pbd.p2_c2_change_percent =
                                                    rfrg.p2_c2_change_percent,
                            rfr_pbd.p2_c2_change_selling_uom =
                                                rfrg.p2_c2_change_selling_uom,
                            rfr_pbd.p2_c2_price_guide_id =
                                                    rfrg.p2_c2_price_guide_id,
                            rfr_pbd.p2_exclusion1_id = rfrg.p2_exclusion1_id,
                            rfr_pbd.p2_exclusion1_display_id =
                                                rfrg.p2_exclusion1_display_id,
                            rfr_pbd.p2_exclusion1_type =
                                                      rfrg.p2_exclusion1_type,
                            rfr_pbd.p2_e1_start_ind = rfrg.p2_e1_start_ind,
                            rfr_pbd.p2_exclusion2_id = rfrg.p2_exclusion2_id,
                            rfr_pbd.p2_exclusion2_display_id =
                                                rfrg.p2_exclusion2_display_id,
                            rfr_pbd.p2_exclusion2_type =
                                                      rfrg.p2_exclusion2_type,
                            rfr_pbd.p2_e2_start_ind = rfrg.p2_e2_start_ind,
                            rfr_pbd.loc_move_from_zone_id =
                                                   rfrg.loc_move_from_zone_id,
                            rfr_pbd.loc_move_to_zone_id =
                                                     rfrg.loc_move_to_zone_id,
                            rfr_pbd.location_move_id = rfrg.location_move_id
                  WHEN NOT MATCHED THEN
                     INSERT (future_retail_id, dept, CLASS, subclass, item,
                             zone_node_type, LOCATION, action_date,
                             selling_retail, selling_retail_currency,
                             selling_uom, multi_units, multi_unit_retail,
                             multi_unit_retail_currency, multi_selling_uom,
                             clear_retail, clear_retail_currency, clear_uom,
                             simple_promo_retail,
                             simple_promo_retail_currency, simple_promo_uom,
                             complex_promo_retail,
                             complex_promo_retail_currency,
                             complex_promo_uom, price_change_id,
                             price_change_display_id, pc_exception_parent_id,
                             pc_change_type, pc_change_amount,
                             pc_change_currency, pc_change_percent,
                             pc_change_selling_uom, pc_null_multi_ind,
                             pc_multi_units, pc_multi_unit_retail,
                             pc_multi_unit_retail_currency,
                             pc_multi_selling_uom, pc_price_guide_id,
                             clearance_id, clearance_display_id,
                             clear_mkdn_index, clear_start_ind,
                             clear_change_type, clear_change_amount,
                             clear_change_currency, clear_change_percent,
                             clear_change_selling_uom, clear_price_guide_id,
                             promotion1_id, promo1_display_id, p1_start_date,
                             p1_rank, p1_secondary_ind, p1_component1_id,
                             p1_comp1_display_id, p1_c1_detail_id,
                             p1_c1_type, p1_c1_rank, p1_c1_secondary_ind,
                             p1_c1_start_date, p1_c1_start_ind,
                             p1_c1_apply_to_code, p1_c1_change_type,
                             p1_c1_change_amount, p1_c1_change_currency,
                             p1_c1_change_percent, p1_c1_change_selling_uom,
                             p1_c1_price_guide_id, p1_component2_id,
                             p1_comp2_display_id, p1_c2_detail_id,
                             p1_c2_type, p1_c2_rank, p1_c2_secondary_ind,
                             p1_c2_start_date, p1_c2_start_ind,
                             p1_c2_apply_to_code, p1_c2_change_type,
                             p1_c2_change_amount, p1_c2_change_currency,
                             p1_c2_change_percent, p1_c2_change_selling_uom,
                             p1_c2_price_guide_id, p1_exclusion1_id,
                             p1_exclusion1_display_id, p1_exclusion1_type,
                             p1_e1_start_ind, p1_exclusion2_id,
                             p1_exclusion2_display_id, p1_exclusion2_type,
                             p1_e2_start_ind, promotion2_id,
                             promo2_display_id, p2_start_date, p2_rank,
                             p2_secondary_ind, p2_component1_id,
                             p2_comp1_display_id, p2_c1_detail_id,
                             p2_c1_type, p2_c1_rank, p2_c1_secondary_ind,
                             p2_c1_start_date, p2_c1_start_ind,
                             p2_c1_apply_to_code, p2_c1_change_type,
                             p2_c1_change_amount, p2_c1_change_currency,
                             p2_c1_change_percent, p2_c1_change_selling_uom,
                             p2_c1_price_guide_id, p2_component2_id,
                             p2_comp2_display_id, p2_c2_detail_id,
                             p2_c2_type, p2_c2_rank, p2_c2_secondary_ind,
                             p2_c2_start_date, p2_c2_start_ind,
                             p2_c2_apply_to_code, p2_c2_change_type,
                             p2_c2_change_amount, p2_c2_change_currency,
                             p2_c2_change_percent, p2_c2_change_selling_uom,
                             p2_c2_price_guide_id, p2_exclusion1_id,
                             p2_exclusion1_display_id, p2_exclusion1_type,
                             p2_e1_start_ind, p2_exclusion2_id,
                             p2_exclusion2_display_id, p2_exclusion2_type,
                             p2_e2_start_ind, loc_move_from_zone_id,
                             loc_move_to_zone_id, location_move_id)
                     VALUES (rfrg.future_retail_id, rfrg.dept, rfrg.CLASS,
                             rfrg.subclass, rfrg.item, rfrg.zone_node_type,
                             rfrg.LOCATION, rfrg.action_date,
                             rfrg.selling_retail,
                             rfrg.selling_retail_currency, rfrg.selling_uom,
                             rfrg.multi_units, rfrg.multi_unit_retail,
                             rfrg.multi_unit_retail_currency,
                             rfrg.multi_selling_uom, rfrg.clear_retail,
                             rfrg.clear_retail_currency, rfrg.clear_uom,
                             rfrg.simple_promo_retail,
                             rfrg.simple_promo_retail_currency,
                             rfrg.simple_promo_uom,
                             rfrg.complex_promo_retail,
                             rfrg.complex_promo_retail_currency,
                             rfrg.complex_promo_uom, rfrg.price_change_id,
                             rfrg.price_change_display_id,
                             rfrg.pc_exception_parent_id,
                             rfrg.pc_change_type, rfrg.pc_change_amount,
                             rfrg.pc_change_currency, rfrg.pc_change_percent,
                             rfrg.pc_change_selling_uom,
                             rfrg.pc_null_multi_ind, rfrg.pc_multi_units,
                             rfrg.pc_multi_unit_retail,
                             rfrg.pc_multi_unit_retail_currency,
                             rfrg.pc_multi_selling_uom,
                             rfrg.pc_price_guide_id, rfrg.clearance_id,
                             rfrg.clearance_display_id,
                             rfrg.clear_mkdn_index, rfrg.clear_start_ind,
                             rfrg.clear_change_type,
                             rfrg.clear_change_amount,
                             rfrg.clear_change_currency,
                             rfrg.clear_change_percent,
                             rfrg.clear_change_selling_uom,
                             rfrg.clear_price_guide_id, rfrg.promotion1_id,
                             rfrg.promo1_display_id, rfrg.p1_start_date,
                             rfrg.p1_rank, rfrg.p1_secondary_ind,
                             rfrg.p1_component1_id, rfrg.p1_comp1_display_id,
                             rfrg.p1_c1_detail_id, rfrg.p1_c1_type,
                             rfrg.p1_c1_rank, rfrg.p1_c1_secondary_ind,
                             rfrg.p1_c1_start_date, rfrg.p1_c1_start_ind,
                             rfrg.p1_c1_apply_to_code,
                             rfrg.p1_c1_change_type,
                             rfrg.p1_c1_change_amount,
                             rfrg.p1_c1_change_currency,
                             rfrg.p1_c1_change_percent,
                             rfrg.p1_c1_change_selling_uom,
                             rfrg.p1_c1_price_guide_id,
                             rfrg.p1_component2_id, rfrg.p1_comp2_display_id,
                             rfrg.p1_c2_detail_id, rfrg.p1_c2_type,
                             rfrg.p1_c2_rank, rfrg.p1_c2_secondary_ind,
                             rfrg.p1_c2_start_date, rfrg.p1_c2_start_ind,
                             rfrg.p1_c2_apply_to_code,
                             rfrg.p1_c2_change_type,
                             rfrg.p1_c2_change_amount,
                             rfrg.p1_c2_change_currency,
                             rfrg.p1_c2_change_percent,
                             rfrg.p1_c2_change_selling_uom,
                             rfrg.p1_c2_price_guide_id,
                             rfrg.p1_exclusion1_id,
                             rfrg.p1_exclusion1_display_id,
                             rfrg.p1_exclusion1_type, rfrg.p1_e1_start_ind,
                             rfrg.p1_exclusion2_id,
                             rfrg.p1_exclusion2_display_id,
                             rfrg.p1_exclusion2_type, rfrg.p1_e2_start_ind,
                             rfrg.promotion2_id, rfrg.promo2_display_id,
                             rfrg.p2_start_date, rfrg.p2_rank,
                             rfrg.p2_secondary_ind, rfrg.p2_component1_id,
                             rfrg.p2_comp1_display_id, rfrg.p2_c1_detail_id,
                             rfrg.p2_c1_type, rfrg.p2_c1_rank,
                             rfrg.p2_c1_secondary_ind, rfrg.p2_c1_start_date,
                             rfrg.p2_c1_start_ind, rfrg.p2_c1_apply_to_code,
                             rfrg.p2_c1_change_type,
                             rfrg.p2_c1_change_amount,
                             rfrg.p2_c1_change_currency,
                             rfrg.p2_c1_change_percent,
                             rfrg.p2_c1_change_selling_uom,
                             rfrg.p2_c1_price_guide_id,
                             rfrg.p2_component2_id, rfrg.p2_comp2_display_id,
                             rfrg.p2_c2_detail_id, rfrg.p2_c2_type,
                             rfrg.p2_c2_rank, rfrg.p2_c2_secondary_ind,
                             rfrg.p2_c2_start_date, rfrg.p2_c2_start_ind,
                             rfrg.p2_c2_apply_to_code,
                             rfrg.p2_c2_change_type,
                             rfrg.p2_c2_change_amount,
                             rfrg.p2_c2_change_currency,
                             rfrg.p2_c2_change_percent,
                             rfrg.p2_c2_change_selling_uom,
                             rfrg.p2_c2_price_guide_id,
                             rfrg.p2_exclusion1_id,
                             rfrg.p2_exclusion1_display_id,
                             rfrg.p2_exclusion1_type, rfrg.p2_e1_start_ind,
                             rfrg.p2_exclusion2_id,
                             rfrg.p2_exclusion2_display_id,
                             rfrg.p2_exclusion2_type, rfrg.p2_e2_start_ind,
                             rfrg.loc_move_from_zone_id,
                             rfrg.loc_move_to_zone_id, rfrg.location_move_id);

               --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
               IF (l_active_state != 'pcd.active')
               THEN
                  DELETE FROM rpm_future_retail rfr
                        WHERE rfr.ROWID IN (SELECT rfrg.rfr_rowid
                                              FROM rpm_future_retail_gtt rfrg
                                             WHERE rfrg.timeline_seq = -999);
               END IF;
            --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
            END LOOP;
         END IF;
      END IF;

      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END push_back;

--19-Apr-2010 BC_KC  NBS00017378      performances fix End

   --------------------------------------------------------------------------------

   --19-Apr-2010 BC_KC  NBS00017378      performances fix Begin
   FUNCTION push_back_all (o_cc_error_tbl OUT conflict_check_error_tbl)
      RETURN NUMBER
   IS
      l_program           VARCHAR2 (100)
                                     := 'RPM_FUTURE_RETAIL_SQL.PUSH_BACK_ALL';
      l_price_event_ids   obj_numeric_id_table;
      l_dept              NUMBER;

      CURSOR c1
      IS
         SELECT DISTINCT dept
                    FROM rpm_future_retail_gtt;
   BEGIN
      OPEN c1;

      FETCH c1
      BULK COLLECT INTO l_price_event_ids;

      CLOSE c1;

      IF l_price_event_ids IS NOT NULL AND l_price_event_ids.COUNT > 0
      THEN
         IF l_price_event_ids.COUNT > 64
         THEN
            l_program := 'RPM_FUTURE_RETAIL_SQL.PUSH_BACK_ALL_TABLE';
            -- BC_KC 20/04/2010 copied from performance tuned push_back function
            -- removed the action_date join ppredicate ???? and renamed alias to identify within trace file
            MERGE                         /*+ rowid(rfr_pbat) */ INTO rpm_future_retail rfr_pbat
               USING (SELECT /*+ full(rfrg) */
                             gtt.*
                        FROM rpm_future_retail_gtt gtt) rfrg
               --where trunc(action_date) >= trunc(LP_push_back_start_date)) rfrg
            ON (rfr_pbat.ROWID = rfrg.rfr_rowid)
               WHEN MATCHED THEN
                  UPDATE
                     SET rfr_pbat.selling_retail = rfrg.selling_retail,
                         rfr_pbat.selling_retail_currency =
                                                 rfrg.selling_retail_currency,
                         rfr_pbat.selling_uom = rfrg.selling_uom,
                         rfr_pbat.multi_units = rfrg.multi_units,
                         rfr_pbat.multi_unit_retail = rfrg.multi_unit_retail,
                         rfr_pbat.multi_unit_retail_currency =
                                              rfrg.multi_unit_retail_currency,
                         rfr_pbat.multi_selling_uom = rfrg.multi_selling_uom,
                         rfr_pbat.clear_retail = rfrg.clear_retail,
                         rfr_pbat.clear_retail_currency =
                                                   rfrg.clear_retail_currency,
                         rfr_pbat.clear_uom = rfrg.clear_uom,
                         rfr_pbat.simple_promo_retail =
                                                     rfrg.simple_promo_retail,
                         rfr_pbat.simple_promo_retail_currency =
                                            rfrg.simple_promo_retail_currency,
                         rfr_pbat.simple_promo_uom = rfrg.simple_promo_uom,
                         rfr_pbat.complex_promo_retail =
                                                    rfrg.complex_promo_retail,
                         rfr_pbat.complex_promo_retail_currency =
                                           rfrg.complex_promo_retail_currency,
                         rfr_pbat.complex_promo_uom = rfrg.complex_promo_uom,
                         rfr_pbat.price_change_id = rfrg.price_change_id,
                         rfr_pbat.price_change_display_id =
                                                 rfrg.price_change_display_id,
                         rfr_pbat.pc_exception_parent_id =
                                                  rfrg.pc_exception_parent_id,
                         rfr_pbat.pc_change_type = rfrg.pc_change_type,
                         rfr_pbat.pc_change_amount = rfrg.pc_change_amount,
                         rfr_pbat.pc_change_currency =
                                                      rfrg.pc_change_currency,
                         rfr_pbat.pc_change_percent = rfrg.pc_change_percent,
                         rfr_pbat.pc_change_selling_uom =
                                                   rfrg.pc_change_selling_uom,
                         rfr_pbat.pc_null_multi_ind = rfrg.pc_null_multi_ind,
                         rfr_pbat.pc_multi_units = rfrg.pc_multi_units,
                         rfr_pbat.pc_multi_unit_retail =
                                                    rfrg.pc_multi_unit_retail,
                         rfr_pbat.pc_multi_unit_retail_currency =
                                           rfrg.pc_multi_unit_retail_currency,
                         rfr_pbat.pc_multi_selling_uom =
                                                    rfrg.pc_multi_selling_uom,
                         rfr_pbat.pc_price_guide_id = rfrg.pc_price_guide_id,
                         rfr_pbat.clearance_id = rfrg.clearance_id,
                         rfr_pbat.clearance_display_id =
                                                    rfrg.clearance_display_id,
                         rfr_pbat.clear_mkdn_index = rfrg.clear_mkdn_index,
                         rfr_pbat.clear_start_ind = rfrg.clear_start_ind,
                         rfr_pbat.clear_change_type = rfrg.clear_change_type,
                         rfr_pbat.clear_change_amount =
                                                     rfrg.clear_change_amount,
                         rfr_pbat.clear_change_currency =
                                                   rfrg.clear_change_currency,
                         rfr_pbat.clear_change_percent =
                                                    rfrg.clear_change_percent,
                         rfr_pbat.clear_change_selling_uom =
                                                rfrg.clear_change_selling_uom,
                         rfr_pbat.clear_price_guide_id =
                                                    rfrg.clear_price_guide_id,
                         rfr_pbat.promotion1_id = rfrg.promotion1_id,
                         rfr_pbat.promo1_display_id = rfrg.promo1_display_id,
                         rfr_pbat.p1_start_date = rfrg.p1_start_date,
                         rfr_pbat.p1_rank = rfrg.p1_rank,
                         rfr_pbat.p1_secondary_ind = rfrg.p1_secondary_ind,
                         rfr_pbat.p1_component1_id = rfrg.p1_component1_id,
                         rfr_pbat.p1_comp1_display_id =
                                                     rfrg.p1_comp1_display_id,
                         rfr_pbat.p1_c1_detail_id = rfrg.p1_c1_detail_id,
                         rfr_pbat.p1_c1_type = rfrg.p1_c1_type,
                         rfr_pbat.p1_c1_rank = rfrg.p1_c1_rank,
                         rfr_pbat.p1_c1_secondary_ind =
                                                     rfrg.p1_c1_secondary_ind,
                         rfr_pbat.p1_c1_start_date = rfrg.p1_c1_start_date,
                         rfr_pbat.p1_c1_start_ind = rfrg.p1_c1_start_ind,
                         rfr_pbat.p1_c1_apply_to_code =
                                                     rfrg.p1_c1_apply_to_code,
                         rfr_pbat.p1_c1_change_type = rfrg.p1_c1_change_type,
                         rfr_pbat.p1_c1_change_amount =
                                                     rfrg.p1_c1_change_amount,
                         rfr_pbat.p1_c1_change_currency =
                                                   rfrg.p1_c1_change_currency,
                         rfr_pbat.p1_c1_change_percent =
                                                    rfrg.p1_c1_change_percent,
                         rfr_pbat.p1_c1_change_selling_uom =
                                                rfrg.p1_c1_change_selling_uom,
                         rfr_pbat.p1_c1_price_guide_id =
                                                    rfrg.p1_c1_price_guide_id,
                         rfr_pbat.p1_component2_id = rfrg.p1_component2_id,
                         rfr_pbat.p1_comp2_display_id =
                                                     rfrg.p1_comp2_display_id,
                         rfr_pbat.p1_c2_detail_id = rfrg.p1_c2_detail_id,
                         rfr_pbat.p1_c2_type = rfrg.p1_c2_type,
                         rfr_pbat.p1_c2_rank = rfrg.p1_c2_rank,
                         rfr_pbat.p1_c2_secondary_ind =
                                                     rfrg.p1_c2_secondary_ind,
                         rfr_pbat.p1_c2_start_date = rfrg.p1_c2_start_date,
                         rfr_pbat.p1_c2_start_ind = rfrg.p1_c2_start_ind,
                         rfr_pbat.p1_c2_apply_to_code =
                                                     rfrg.p1_c2_apply_to_code,
                         rfr_pbat.p1_c2_change_type = rfrg.p1_c2_change_type,
                         rfr_pbat.p1_c2_change_amount =
                                                     rfrg.p1_c2_change_amount,
                         rfr_pbat.p1_c2_change_currency =
                                                   rfrg.p1_c2_change_currency,
                         rfr_pbat.p1_c2_change_percent =
                                                    rfrg.p1_c2_change_percent,
                         rfr_pbat.p1_c2_change_selling_uom =
                                                rfrg.p1_c2_change_selling_uom,
                         rfr_pbat.p1_c2_price_guide_id =
                                                    rfrg.p1_c2_price_guide_id,
                         rfr_pbat.p1_exclusion1_id = rfrg.p1_exclusion1_id,
                         rfr_pbat.p1_exclusion1_display_id =
                                                rfrg.p1_exclusion1_display_id,
                         rfr_pbat.p1_exclusion1_type =
                                                      rfrg.p1_exclusion1_type,
                         rfr_pbat.p1_e1_start_ind = rfrg.p1_e1_start_ind,
                         rfr_pbat.p1_exclusion2_id = rfrg.p1_exclusion2_id,
                         rfr_pbat.p1_exclusion2_display_id =
                                                rfrg.p1_exclusion2_display_id,
                         rfr_pbat.p1_exclusion2_type =
                                                      rfrg.p1_exclusion2_type,
                         rfr_pbat.p1_e2_start_ind = rfrg.p1_e2_start_ind,
                         rfr_pbat.promotion2_id = rfrg.promotion2_id,
                         rfr_pbat.promo2_display_id = rfrg.promo2_display_id,
                         rfr_pbat.p2_start_date = rfrg.p2_start_date,
                         rfr_pbat.p2_rank = rfrg.p2_rank,
                         rfr_pbat.p2_secondary_ind = rfrg.p2_secondary_ind,
                         rfr_pbat.p2_component1_id = rfrg.p2_component1_id,
                         rfr_pbat.p2_comp1_display_id =
                                                     rfrg.p2_comp1_display_id,
                         rfr_pbat.p2_c1_detail_id = rfrg.p2_c1_detail_id,
                         rfr_pbat.p2_c1_type = rfrg.p2_c1_type,
                         rfr_pbat.p2_c1_rank = rfrg.p2_c1_rank,
                         rfr_pbat.p2_c1_secondary_ind =
                                                     rfrg.p2_c1_secondary_ind,
                         rfr_pbat.p2_c1_start_date = rfrg.p2_c1_start_date,
                         rfr_pbat.p2_c1_start_ind = rfrg.p2_c1_start_ind,
                         rfr_pbat.p2_c1_apply_to_code =
                                                     rfrg.p2_c1_apply_to_code,
                         rfr_pbat.p2_c1_change_type = rfrg.p2_c1_change_type,
                         rfr_pbat.p2_c1_change_amount =
                                                     rfrg.p2_c1_change_amount,
                         rfr_pbat.p2_c1_change_currency =
                                                   rfrg.p2_c1_change_currency,
                         rfr_pbat.p2_c1_change_percent =
                                                    rfrg.p2_c1_change_percent,
                         rfr_pbat.p2_c1_change_selling_uom =
                                                rfrg.p2_c1_change_selling_uom,
                         rfr_pbat.p2_c1_price_guide_id =
                                                    rfrg.p2_c1_price_guide_id,
                         rfr_pbat.p2_component2_id = rfrg.p2_component2_id,
                         rfr_pbat.p2_comp2_display_id =
                                                     rfrg.p2_comp2_display_id,
                         rfr_pbat.p2_c2_detail_id = rfrg.p2_c2_detail_id,
                         rfr_pbat.p2_c2_type = rfrg.p2_c2_type,
                         rfr_pbat.p2_c2_rank = rfrg.p2_c2_rank,
                         rfr_pbat.p2_c2_secondary_ind =
                                                     rfrg.p2_c2_secondary_ind,
                         rfr_pbat.p2_c2_start_date = rfrg.p2_c2_start_date,
                         rfr_pbat.p2_c2_start_ind = rfrg.p2_c2_start_ind,
                         rfr_pbat.p2_c2_apply_to_code =
                                                     rfrg.p2_c2_apply_to_code,
                         rfr_pbat.p2_c2_change_type = rfrg.p2_c2_change_type,
                         rfr_pbat.p2_c2_change_amount =
                                                     rfrg.p2_c2_change_amount,
                         rfr_pbat.p2_c2_change_currency =
                                                   rfrg.p2_c2_change_currency,
                         rfr_pbat.p2_c2_change_percent =
                                                    rfrg.p2_c2_change_percent,
                         rfr_pbat.p2_c2_change_selling_uom =
                                                rfrg.p2_c2_change_selling_uom,
                         rfr_pbat.p2_c2_price_guide_id =
                                                    rfrg.p2_c2_price_guide_id,
                         rfr_pbat.p2_exclusion1_id = rfrg.p2_exclusion1_id,
                         rfr_pbat.p2_exclusion1_display_id =
                                                rfrg.p2_exclusion1_display_id,
                         rfr_pbat.p2_exclusion1_type =
                                                      rfrg.p2_exclusion1_type,
                         rfr_pbat.p2_e1_start_ind = rfrg.p2_e1_start_ind,
                         rfr_pbat.p2_exclusion2_id = rfrg.p2_exclusion2_id,
                         rfr_pbat.p2_exclusion2_display_id =
                                                rfrg.p2_exclusion2_display_id,
                         rfr_pbat.p2_exclusion2_type =
                                                      rfrg.p2_exclusion2_type,
                         rfr_pbat.p2_e2_start_ind = rfrg.p2_e2_start_ind,
                         rfr_pbat.loc_move_from_zone_id =
                                                   rfrg.loc_move_from_zone_id,
                         rfr_pbat.loc_move_to_zone_id =
                                                     rfrg.loc_move_to_zone_id,
                         rfr_pbat.location_move_id = rfrg.location_move_id
               WHEN NOT MATCHED THEN
                  INSERT (future_retail_id, dept, CLASS, subclass, item,
                          zone_node_type, LOCATION, action_date,
                          selling_retail, selling_retail_currency,
                          selling_uom, multi_units, multi_unit_retail,
                          multi_unit_retail_currency, multi_selling_uom,
                          clear_retail, clear_retail_currency, clear_uom,
                          simple_promo_retail, simple_promo_retail_currency,
                          simple_promo_uom, complex_promo_retail,
                          complex_promo_retail_currency, complex_promo_uom,
                          price_change_id, price_change_display_id,
                          pc_exception_parent_id, pc_change_type,
                          pc_change_amount, pc_change_currency,
                          pc_change_percent, pc_change_selling_uom,
                          pc_null_multi_ind, pc_multi_units,
                          pc_multi_unit_retail,
                          pc_multi_unit_retail_currency,
                          pc_multi_selling_uom, pc_price_guide_id,
                          clearance_id, clearance_display_id,
                          clear_mkdn_index, clear_start_ind,
                          clear_change_type, clear_change_amount,
                          clear_change_currency, clear_change_percent,
                          clear_change_selling_uom, clear_price_guide_id,
                          promotion1_id, promo1_display_id, p1_start_date,
                          p1_rank, p1_secondary_ind, p1_component1_id,
                          p1_comp1_display_id, p1_c1_detail_id, p1_c1_type,
                          p1_c1_rank, p1_c1_secondary_ind, p1_c1_start_date,
                          p1_c1_start_ind, p1_c1_apply_to_code,
                          p1_c1_change_type, p1_c1_change_amount,
                          p1_c1_change_currency, p1_c1_change_percent,
                          p1_c1_change_selling_uom, p1_c1_price_guide_id,
                          p1_component2_id, p1_comp2_display_id,
                          p1_c2_detail_id, p1_c2_type, p1_c2_rank,
                          p1_c2_secondary_ind, p1_c2_start_date,
                          p1_c2_start_ind, p1_c2_apply_to_code,
                          p1_c2_change_type, p1_c2_change_amount,
                          p1_c2_change_currency, p1_c2_change_percent,
                          p1_c2_change_selling_uom, p1_c2_price_guide_id,
                          p1_exclusion1_id, p1_exclusion1_display_id,
                          p1_exclusion1_type, p1_e1_start_ind,
                          p1_exclusion2_id, p1_exclusion2_display_id,
                          p1_exclusion2_type, p1_e2_start_ind, promotion2_id,
                          promo2_display_id, p2_start_date, p2_rank,
                          p2_secondary_ind, p2_component1_id,
                          p2_comp1_display_id, p2_c1_detail_id, p2_c1_type,
                          p2_c1_rank, p2_c1_secondary_ind, p2_c1_start_date,
                          p2_c1_start_ind, p2_c1_apply_to_code,
                          p2_c1_change_type, p2_c1_change_amount,
                          p2_c1_change_currency, p2_c1_change_percent,
                          p2_c1_change_selling_uom, p2_c1_price_guide_id,
                          p2_component2_id, p2_comp2_display_id,
                          p2_c2_detail_id, p2_c2_type, p2_c2_rank,
                          p2_c2_secondary_ind, p2_c2_start_date,
                          p2_c2_start_ind, p2_c2_apply_to_code,
                          p2_c2_change_type, p2_c2_change_amount,
                          p2_c2_change_currency, p2_c2_change_percent,
                          p2_c2_change_selling_uom, p2_c2_price_guide_id,
                          p2_exclusion1_id, p2_exclusion1_display_id,
                          p2_exclusion1_type, p2_e1_start_ind,
                          p2_exclusion2_id, p2_exclusion2_display_id,
                          p2_exclusion2_type, p2_e2_start_ind,
                          loc_move_from_zone_id, loc_move_to_zone_id,
                          location_move_id)
                  VALUES (rfrg.future_retail_id, rfrg.dept, rfrg.CLASS,
                          rfrg.subclass, rfrg.item, rfrg.zone_node_type,
                          rfrg.LOCATION, rfrg.action_date,
                          rfrg.selling_retail, rfrg.selling_retail_currency,
                          rfrg.selling_uom, rfrg.multi_units,
                          rfrg.multi_unit_retail,
                          rfrg.multi_unit_retail_currency,
                          rfrg.multi_selling_uom, rfrg.clear_retail,
                          rfrg.clear_retail_currency, rfrg.clear_uom,
                          rfrg.simple_promo_retail,
                          rfrg.simple_promo_retail_currency,
                          rfrg.simple_promo_uom, rfrg.complex_promo_retail,
                          rfrg.complex_promo_retail_currency,
                          rfrg.complex_promo_uom, rfrg.price_change_id,
                          rfrg.price_change_display_id,
                          rfrg.pc_exception_parent_id, rfrg.pc_change_type,
                          rfrg.pc_change_amount, rfrg.pc_change_currency,
                          rfrg.pc_change_percent, rfrg.pc_change_selling_uom,
                          rfrg.pc_null_multi_ind, rfrg.pc_multi_units,
                          rfrg.pc_multi_unit_retail,
                          rfrg.pc_multi_unit_retail_currency,
                          rfrg.pc_multi_selling_uom, rfrg.pc_price_guide_id,
                          rfrg.clearance_id, rfrg.clearance_display_id,
                          rfrg.clear_mkdn_index, rfrg.clear_start_ind,
                          rfrg.clear_change_type, rfrg.clear_change_amount,
                          rfrg.clear_change_currency,
                          rfrg.clear_change_percent,
                          rfrg.clear_change_selling_uom,
                          rfrg.clear_price_guide_id, rfrg.promotion1_id,
                          rfrg.promo1_display_id, rfrg.p1_start_date,
                          rfrg.p1_rank, rfrg.p1_secondary_ind,
                          rfrg.p1_component1_id, rfrg.p1_comp1_display_id,
                          rfrg.p1_c1_detail_id, rfrg.p1_c1_type,
                          rfrg.p1_c1_rank, rfrg.p1_c1_secondary_ind,
                          rfrg.p1_c1_start_date, rfrg.p1_c1_start_ind,
                          rfrg.p1_c1_apply_to_code, rfrg.p1_c1_change_type,
                          rfrg.p1_c1_change_amount,
                          rfrg.p1_c1_change_currency,
                          rfrg.p1_c1_change_percent,
                          rfrg.p1_c1_change_selling_uom,
                          rfrg.p1_c1_price_guide_id, rfrg.p1_component2_id,
                          rfrg.p1_comp2_display_id, rfrg.p1_c2_detail_id,
                          rfrg.p1_c2_type, rfrg.p1_c2_rank,
                          rfrg.p1_c2_secondary_ind, rfrg.p1_c2_start_date,
                          rfrg.p1_c2_start_ind, rfrg.p1_c2_apply_to_code,
                          rfrg.p1_c2_change_type, rfrg.p1_c2_change_amount,
                          rfrg.p1_c2_change_currency,
                          rfrg.p1_c2_change_percent,
                          rfrg.p1_c2_change_selling_uom,
                          rfrg.p1_c2_price_guide_id, rfrg.p1_exclusion1_id,
                          rfrg.p1_exclusion1_display_id,
                          rfrg.p1_exclusion1_type, rfrg.p1_e1_start_ind,
                          rfrg.p1_exclusion2_id,
                          rfrg.p1_exclusion2_display_id,
                          rfrg.p1_exclusion2_type, rfrg.p1_e2_start_ind,
                          rfrg.promotion2_id, rfrg.promo2_display_id,
                          rfrg.p2_start_date, rfrg.p2_rank,
                          rfrg.p2_secondary_ind, rfrg.p2_component1_id,
                          rfrg.p2_comp1_display_id, rfrg.p2_c1_detail_id,
                          rfrg.p2_c1_type, rfrg.p2_c1_rank,
                          rfrg.p2_c1_secondary_ind, rfrg.p2_c1_start_date,
                          rfrg.p2_c1_start_ind, rfrg.p2_c1_apply_to_code,
                          rfrg.p2_c1_change_type, rfrg.p2_c1_change_amount,
                          rfrg.p2_c1_change_currency,
                          rfrg.p2_c1_change_percent,
                          rfrg.p2_c1_change_selling_uom,
                          rfrg.p2_c1_price_guide_id, rfrg.p2_component2_id,
                          rfrg.p2_comp2_display_id, rfrg.p2_c2_detail_id,
                          rfrg.p2_c2_type, rfrg.p2_c2_rank,
                          rfrg.p2_c2_secondary_ind, rfrg.p2_c2_start_date,
                          rfrg.p2_c2_start_ind, rfrg.p2_c2_apply_to_code,
                          rfrg.p2_c2_change_type, rfrg.p2_c2_change_amount,
                          rfrg.p2_c2_change_currency,
                          rfrg.p2_c2_change_percent,
                          rfrg.p2_c2_change_selling_uom,
                          rfrg.p2_c2_price_guide_id, rfrg.p2_exclusion1_id,
                          rfrg.p2_exclusion1_display_id,
                          rfrg.p2_exclusion1_type, rfrg.p2_e1_start_ind,
                          rfrg.p2_exclusion2_id,
                          rfrg.p2_exclusion2_display_id,
                          rfrg.p2_exclusion2_type, rfrg.p2_e2_start_ind,
                          rfrg.loc_move_from_zone_id,
                          rfrg.loc_move_to_zone_id, rfrg.location_move_id);

            DELETE FROM rpm_future_retail rfr
                  WHERE rfr.ROWID IN (SELECT rfrg.rfr_rowid
                                        FROM rpm_future_retail_gtt rfrg
                                       WHERE rfrg.timeline_seq = -999);
         ELSE
            l_program := 'RPM_FUTURE_RETAIL_SQL.PUSH_BACK_ALL_DEPT';

            FOR i IN 1 .. l_price_event_ids.COUNT
            LOOP
               l_dept := l_price_event_ids (i);
               MERGE INTO rpm_future_retail rfr_pbad
                  USING (SELECT /*+ full(rfrg) */
                                gtt.*
                           FROM rpm_future_retail_gtt gtt
                          WHERE gtt.dept = l_dept
                                                 -- and trunc(gtt.action_date) >= trunc(LP_push_back_start_date)
               ) rfrg
                  ON (rfr_pbad.dept = l_dept
                  AND rfr_pbad.ROWID = rfrg.rfr_rowid)
                  WHEN MATCHED THEN
                     UPDATE
                        SET rfr_pbad.selling_retail = rfrg.selling_retail,
                            rfr_pbad.selling_retail_currency =
                                                  rfrg.selling_retail_currency,
                            rfr_pbad.selling_uom = rfrg.selling_uom,
                            rfr_pbad.multi_units = rfrg.multi_units,
                            rfr_pbad.multi_unit_retail =
                                                        rfrg.multi_unit_retail,
                            rfr_pbad.multi_unit_retail_currency =
                                               rfrg.multi_unit_retail_currency,
                            rfr_pbad.multi_selling_uom =
                                                        rfrg.multi_selling_uom,
                            rfr_pbad.clear_retail = rfrg.clear_retail,
                            rfr_pbad.clear_retail_currency =
                                                    rfrg.clear_retail_currency,
                            rfr_pbad.clear_uom = rfrg.clear_uom,
                            rfr_pbad.simple_promo_retail =
                                                      rfrg.simple_promo_retail,
                            rfr_pbad.simple_promo_retail_currency =
                                             rfrg.simple_promo_retail_currency,
                            rfr_pbad.simple_promo_uom = rfrg.simple_promo_uom,
                            rfr_pbad.complex_promo_retail =
                                                     rfrg.complex_promo_retail,
                            rfr_pbad.complex_promo_retail_currency =
                                            rfrg.complex_promo_retail_currency,
                            rfr_pbad.complex_promo_uom =
                                                        rfrg.complex_promo_uom,
                            rfr_pbad.price_change_id = rfrg.price_change_id,
                            rfr_pbad.price_change_display_id =
                                                  rfrg.price_change_display_id,
                            rfr_pbad.pc_exception_parent_id =
                                                   rfrg.pc_exception_parent_id,
                            rfr_pbad.pc_change_type = rfrg.pc_change_type,
                            rfr_pbad.pc_change_amount = rfrg.pc_change_amount,
                            rfr_pbad.pc_change_currency =
                                                       rfrg.pc_change_currency,
                            rfr_pbad.pc_change_percent =
                                                        rfrg.pc_change_percent,
                            rfr_pbad.pc_change_selling_uom =
                                                    rfrg.pc_change_selling_uom,
                            rfr_pbad.pc_null_multi_ind =
                                                        rfrg.pc_null_multi_ind,
                            rfr_pbad.pc_multi_units = rfrg.pc_multi_units,
                            rfr_pbad.pc_multi_unit_retail =
                                                     rfrg.pc_multi_unit_retail,
                            rfr_pbad.pc_multi_unit_retail_currency =
                                            rfrg.pc_multi_unit_retail_currency,
                            rfr_pbad.pc_multi_selling_uom =
                                                     rfrg.pc_multi_selling_uom,
                            rfr_pbad.pc_price_guide_id =
                                                        rfrg.pc_price_guide_id,
                            rfr_pbad.clearance_id = rfrg.clearance_id,
                            rfr_pbad.clearance_display_id =
                                                     rfrg.clearance_display_id,
                            rfr_pbad.clear_mkdn_index = rfrg.clear_mkdn_index,
                            rfr_pbad.clear_start_ind = rfrg.clear_start_ind,
                            rfr_pbad.clear_change_type =
                                                        rfrg.clear_change_type,
                            rfr_pbad.clear_change_amount =
                                                      rfrg.clear_change_amount,
                            rfr_pbad.clear_change_currency =
                                                    rfrg.clear_change_currency,
                            rfr_pbad.clear_change_percent =
                                                     rfrg.clear_change_percent,
                            rfr_pbad.clear_change_selling_uom =
                                                 rfrg.clear_change_selling_uom,
                            rfr_pbad.clear_price_guide_id =
                                                     rfrg.clear_price_guide_id,
                            rfr_pbad.promotion1_id = rfrg.promotion1_id,
                            rfr_pbad.promo1_display_id =
                                                        rfrg.promo1_display_id,
                            rfr_pbad.p1_start_date = rfrg.p1_start_date,
                            rfr_pbad.p1_rank = rfrg.p1_rank,
                            rfr_pbad.p1_secondary_ind = rfrg.p1_secondary_ind,
                            rfr_pbad.p1_component1_id = rfrg.p1_component1_id,
                            rfr_pbad.p1_comp1_display_id =
                                                      rfrg.p1_comp1_display_id,
                            rfr_pbad.p1_c1_detail_id = rfrg.p1_c1_detail_id,
                            rfr_pbad.p1_c1_type = rfrg.p1_c1_type,
                            rfr_pbad.p1_c1_rank = rfrg.p1_c1_rank,
                            rfr_pbad.p1_c1_secondary_ind =
                                                      rfrg.p1_c1_secondary_ind,
                            rfr_pbad.p1_c1_start_date = rfrg.p1_c1_start_date,
                            rfr_pbad.p1_c1_start_ind = rfrg.p1_c1_start_ind,
                            rfr_pbad.p1_c1_apply_to_code =
                                                      rfrg.p1_c1_apply_to_code,
                            rfr_pbad.p1_c1_change_type =
                                                        rfrg.p1_c1_change_type,
                            rfr_pbad.p1_c1_change_amount =
                                                      rfrg.p1_c1_change_amount,
                            rfr_pbad.p1_c1_change_currency =
                                                    rfrg.p1_c1_change_currency,
                            rfr_pbad.p1_c1_change_percent =
                                                     rfrg.p1_c1_change_percent,
                            rfr_pbad.p1_c1_change_selling_uom =
                                                 rfrg.p1_c1_change_selling_uom,
                            rfr_pbad.p1_c1_price_guide_id =
                                                     rfrg.p1_c1_price_guide_id,
                            rfr_pbad.p1_component2_id = rfrg.p1_component2_id,
                            rfr_pbad.p1_comp2_display_id =
                                                      rfrg.p1_comp2_display_id,
                            rfr_pbad.p1_c2_detail_id = rfrg.p1_c2_detail_id,
                            rfr_pbad.p1_c2_type = rfrg.p1_c2_type,
                            rfr_pbad.p1_c2_rank = rfrg.p1_c2_rank,
                            rfr_pbad.p1_c2_secondary_ind =
                                                      rfrg.p1_c2_secondary_ind,
                            rfr_pbad.p1_c2_start_date = rfrg.p1_c2_start_date,
                            rfr_pbad.p1_c2_start_ind = rfrg.p1_c2_start_ind,
                            rfr_pbad.p1_c2_apply_to_code =
                                                      rfrg.p1_c2_apply_to_code,
                            rfr_pbad.p1_c2_change_type =
                                                        rfrg.p1_c2_change_type,
                            rfr_pbad.p1_c2_change_amount =
                                                      rfrg.p1_c2_change_amount,
                            rfr_pbad.p1_c2_change_currency =
                                                    rfrg.p1_c2_change_currency,
                            rfr_pbad.p1_c2_change_percent =
                                                     rfrg.p1_c2_change_percent,
                            rfr_pbad.p1_c2_change_selling_uom =
                                                 rfrg.p1_c2_change_selling_uom,
                            rfr_pbad.p1_c2_price_guide_id =
                                                     rfrg.p1_c2_price_guide_id,
                            rfr_pbad.p1_exclusion1_id = rfrg.p1_exclusion1_id,
                            rfr_pbad.p1_exclusion1_display_id =
                                                 rfrg.p1_exclusion1_display_id,
                            rfr_pbad.p1_exclusion1_type =
                                                       rfrg.p1_exclusion1_type,
                            rfr_pbad.p1_e1_start_ind = rfrg.p1_e1_start_ind,
                            rfr_pbad.p1_exclusion2_id = rfrg.p1_exclusion2_id,
                            rfr_pbad.p1_exclusion2_display_id =
                                                 rfrg.p1_exclusion2_display_id,
                            rfr_pbad.p1_exclusion2_type =
                                                       rfrg.p1_exclusion2_type,
                            rfr_pbad.p1_e2_start_ind = rfrg.p1_e2_start_ind,
                            rfr_pbad.promotion2_id = rfrg.promotion2_id,
                            rfr_pbad.promo2_display_id =
                                                        rfrg.promo2_display_id,
                            rfr_pbad.p2_start_date = rfrg.p2_start_date,
                            rfr_pbad.p2_rank = rfrg.p2_rank,
                            rfr_pbad.p2_secondary_ind = rfrg.p2_secondary_ind,
                            rfr_pbad.p2_component1_id = rfrg.p2_component1_id,
                            rfr_pbad.p2_comp1_display_id =
                                                      rfrg.p2_comp1_display_id,
                            rfr_pbad.p2_c1_detail_id = rfrg.p2_c1_detail_id,
                            rfr_pbad.p2_c1_type = rfrg.p2_c1_type,
                            rfr_pbad.p2_c1_rank = rfrg.p2_c1_rank,
                            rfr_pbad.p2_c1_secondary_ind =
                                                      rfrg.p2_c1_secondary_ind,
                            rfr_pbad.p2_c1_start_date = rfrg.p2_c1_start_date,
                            rfr_pbad.p2_c1_start_ind = rfrg.p2_c1_start_ind,
                            rfr_pbad.p2_c1_apply_to_code =
                                                      rfrg.p2_c1_apply_to_code,
                            rfr_pbad.p2_c1_change_type =
                                                        rfrg.p2_c1_change_type,
                            rfr_pbad.p2_c1_change_amount =
                                                      rfrg.p2_c1_change_amount,
                            rfr_pbad.p2_c1_change_currency =
                                                    rfrg.p2_c1_change_currency,
                            rfr_pbad.p2_c1_change_percent =
                                                     rfrg.p2_c1_change_percent,
                            rfr_pbad.p2_c1_change_selling_uom =
                                                 rfrg.p2_c1_change_selling_uom,
                            rfr_pbad.p2_c1_price_guide_id =
                                                     rfrg.p2_c1_price_guide_id,
                            rfr_pbad.p2_component2_id = rfrg.p2_component2_id,
                            rfr_pbad.p2_comp2_display_id =
                                                      rfrg.p2_comp2_display_id,
                            rfr_pbad.p2_c2_detail_id = rfrg.p2_c2_detail_id,
                            rfr_pbad.p2_c2_type = rfrg.p2_c2_type,
                            rfr_pbad.p2_c2_rank = rfrg.p2_c2_rank,
                            rfr_pbad.p2_c2_secondary_ind =
                                                      rfrg.p2_c2_secondary_ind,
                            rfr_pbad.p2_c2_start_date = rfrg.p2_c2_start_date,
                            rfr_pbad.p2_c2_start_ind = rfrg.p2_c2_start_ind,
                            rfr_pbad.p2_c2_apply_to_code =
                                                      rfrg.p2_c2_apply_to_code,
                            rfr_pbad.p2_c2_change_type =
                                                        rfrg.p2_c2_change_type,
                            rfr_pbad.p2_c2_change_amount =
                                                      rfrg.p2_c2_change_amount,
                            rfr_pbad.p2_c2_change_currency =
                                                    rfrg.p2_c2_change_currency,
                            rfr_pbad.p2_c2_change_percent =
                                                     rfrg.p2_c2_change_percent,
                            rfr_pbad.p2_c2_change_selling_uom =
                                                 rfrg.p2_c2_change_selling_uom,
                            rfr_pbad.p2_c2_price_guide_id =
                                                     rfrg.p2_c2_price_guide_id,
                            rfr_pbad.p2_exclusion1_id = rfrg.p2_exclusion1_id,
                            rfr_pbad.p2_exclusion1_display_id =
                                                 rfrg.p2_exclusion1_display_id,
                            rfr_pbad.p2_exclusion1_type =
                                                       rfrg.p2_exclusion1_type,
                            rfr_pbad.p2_e1_start_ind = rfrg.p2_e1_start_ind,
                            rfr_pbad.p2_exclusion2_id = rfrg.p2_exclusion2_id,
                            rfr_pbad.p2_exclusion2_display_id =
                                                 rfrg.p2_exclusion2_display_id,
                            rfr_pbad.p2_exclusion2_type =
                                                       rfrg.p2_exclusion2_type,
                            rfr_pbad.p2_e2_start_ind = rfrg.p2_e2_start_ind,
                            rfr_pbad.loc_move_from_zone_id =
                                                    rfrg.loc_move_from_zone_id,
                            rfr_pbad.loc_move_to_zone_id =
                                                      rfrg.loc_move_to_zone_id,
                            rfr_pbad.location_move_id = rfrg.location_move_id
                  WHEN NOT MATCHED THEN
                     INSERT (future_retail_id, dept, CLASS, subclass, item,
                             zone_node_type, LOCATION, action_date,
                             selling_retail, selling_retail_currency,
                             selling_uom, multi_units, multi_unit_retail,
                             multi_unit_retail_currency, multi_selling_uom,
                             clear_retail, clear_retail_currency, clear_uom,
                             simple_promo_retail,
                             simple_promo_retail_currency, simple_promo_uom,
                             complex_promo_retail,
                             complex_promo_retail_currency, complex_promo_uom,
                             price_change_id, price_change_display_id,
                             pc_exception_parent_id, pc_change_type,
                             pc_change_amount, pc_change_currency,
                             pc_change_percent, pc_change_selling_uom,
                             pc_null_multi_ind, pc_multi_units,
                             pc_multi_unit_retail,
                             pc_multi_unit_retail_currency,
                             pc_multi_selling_uom, pc_price_guide_id,
                             clearance_id, clearance_display_id,
                             clear_mkdn_index, clear_start_ind,
                             clear_change_type, clear_change_amount,
                             clear_change_currency, clear_change_percent,
                             clear_change_selling_uom, clear_price_guide_id,
                             promotion1_id, promo1_display_id, p1_start_date,
                             p1_rank, p1_secondary_ind, p1_component1_id,
                             p1_comp1_display_id, p1_c1_detail_id, p1_c1_type,
                             p1_c1_rank, p1_c1_secondary_ind,
                             p1_c1_start_date, p1_c1_start_ind,
                             p1_c1_apply_to_code, p1_c1_change_type,
                             p1_c1_change_amount, p1_c1_change_currency,
                             p1_c1_change_percent, p1_c1_change_selling_uom,
                             p1_c1_price_guide_id, p1_component2_id,
                             p1_comp2_display_id, p1_c2_detail_id, p1_c2_type,
                             p1_c2_rank, p1_c2_secondary_ind,
                             p1_c2_start_date, p1_c2_start_ind,
                             p1_c2_apply_to_code, p1_c2_change_type,
                             p1_c2_change_amount, p1_c2_change_currency,
                             p1_c2_change_percent, p1_c2_change_selling_uom,
                             p1_c2_price_guide_id, p1_exclusion1_id,
                             p1_exclusion1_display_id, p1_exclusion1_type,
                             p1_e1_start_ind, p1_exclusion2_id,
                             p1_exclusion2_display_id, p1_exclusion2_type,
                             p1_e2_start_ind, promotion2_id,
                             promo2_display_id, p2_start_date, p2_rank,
                             p2_secondary_ind, p2_component1_id,
                             p2_comp1_display_id, p2_c1_detail_id, p2_c1_type,
                             p2_c1_rank, p2_c1_secondary_ind,
                             p2_c1_start_date, p2_c1_start_ind,
                             p2_c1_apply_to_code, p2_c1_change_type,
                             p2_c1_change_amount, p2_c1_change_currency,
                             p2_c1_change_percent, p2_c1_change_selling_uom,
                             p2_c1_price_guide_id, p2_component2_id,
                             p2_comp2_display_id, p2_c2_detail_id, p2_c2_type,
                             p2_c2_rank, p2_c2_secondary_ind,
                             p2_c2_start_date, p2_c2_start_ind,
                             p2_c2_apply_to_code, p2_c2_change_type,
                             p2_c2_change_amount, p2_c2_change_currency,
                             p2_c2_change_percent, p2_c2_change_selling_uom,
                             p2_c2_price_guide_id, p2_exclusion1_id,
                             p2_exclusion1_display_id, p2_exclusion1_type,
                             p2_e1_start_ind, p2_exclusion2_id,
                             p2_exclusion2_display_id, p2_exclusion2_type,
                             p2_e2_start_ind, loc_move_from_zone_id,
                             loc_move_to_zone_id, location_move_id)
                     VALUES (rfrg.future_retail_id, rfrg.dept, rfrg.CLASS,
                             rfrg.subclass, rfrg.item, rfrg.zone_node_type,
                             rfrg.LOCATION, rfrg.action_date,
                             rfrg.selling_retail,
                             rfrg.selling_retail_currency, rfrg.selling_uom,
                             rfrg.multi_units, rfrg.multi_unit_retail,
                             rfrg.multi_unit_retail_currency,
                             rfrg.multi_selling_uom, rfrg.clear_retail,
                             rfrg.clear_retail_currency, rfrg.clear_uom,
                             rfrg.simple_promo_retail,
                             rfrg.simple_promo_retail_currency,
                             rfrg.simple_promo_uom, rfrg.complex_promo_retail,
                             rfrg.complex_promo_retail_currency,
                             rfrg.complex_promo_uom, rfrg.price_change_id,
                             rfrg.price_change_display_id,
                             rfrg.pc_exception_parent_id, rfrg.pc_change_type,
                             rfrg.pc_change_amount, rfrg.pc_change_currency,
                             rfrg.pc_change_percent,
                             rfrg.pc_change_selling_uom,
                             rfrg.pc_null_multi_ind, rfrg.pc_multi_units,
                             rfrg.pc_multi_unit_retail,
                             rfrg.pc_multi_unit_retail_currency,
                             rfrg.pc_multi_selling_uom,
                             rfrg.pc_price_guide_id, rfrg.clearance_id,
                             rfrg.clearance_display_id, rfrg.clear_mkdn_index,
                             rfrg.clear_start_ind, rfrg.clear_change_type,
                             rfrg.clear_change_amount,
                             rfrg.clear_change_currency,
                             rfrg.clear_change_percent,
                             rfrg.clear_change_selling_uom,
                             rfrg.clear_price_guide_id, rfrg.promotion1_id,
                             rfrg.promo1_display_id, rfrg.p1_start_date,
                             rfrg.p1_rank, rfrg.p1_secondary_ind,
                             rfrg.p1_component1_id, rfrg.p1_comp1_display_id,
                             rfrg.p1_c1_detail_id, rfrg.p1_c1_type,
                             rfrg.p1_c1_rank, rfrg.p1_c1_secondary_ind,
                             rfrg.p1_c1_start_date, rfrg.p1_c1_start_ind,
                             rfrg.p1_c1_apply_to_code, rfrg.p1_c1_change_type,
                             rfrg.p1_c1_change_amount,
                             rfrg.p1_c1_change_currency,
                             rfrg.p1_c1_change_percent,
                             rfrg.p1_c1_change_selling_uom,
                             rfrg.p1_c1_price_guide_id, rfrg.p1_component2_id,
                             rfrg.p1_comp2_display_id, rfrg.p1_c2_detail_id,
                             rfrg.p1_c2_type, rfrg.p1_c2_rank,
                             rfrg.p1_c2_secondary_ind, rfrg.p1_c2_start_date,
                             rfrg.p1_c2_start_ind, rfrg.p1_c2_apply_to_code,
                             rfrg.p1_c2_change_type, rfrg.p1_c2_change_amount,
                             rfrg.p1_c2_change_currency,
                             rfrg.p1_c2_change_percent,
                             rfrg.p1_c2_change_selling_uom,
                             rfrg.p1_c2_price_guide_id, rfrg.p1_exclusion1_id,
                             rfrg.p1_exclusion1_display_id,
                             rfrg.p1_exclusion1_type, rfrg.p1_e1_start_ind,
                             rfrg.p1_exclusion2_id,
                             rfrg.p1_exclusion2_display_id,
                             rfrg.p1_exclusion2_type, rfrg.p1_e2_start_ind,
                             rfrg.promotion2_id, rfrg.promo2_display_id,
                             rfrg.p2_start_date, rfrg.p2_rank,
                             rfrg.p2_secondary_ind, rfrg.p2_component1_id,
                             rfrg.p2_comp1_display_id, rfrg.p2_c1_detail_id,
                             rfrg.p2_c1_type, rfrg.p2_c1_rank,
                             rfrg.p2_c1_secondary_ind, rfrg.p2_c1_start_date,
                             rfrg.p2_c1_start_ind, rfrg.p2_c1_apply_to_code,
                             rfrg.p2_c1_change_type, rfrg.p2_c1_change_amount,
                             rfrg.p2_c1_change_currency,
                             rfrg.p2_c1_change_percent,
                             rfrg.p2_c1_change_selling_uom,
                             rfrg.p2_c1_price_guide_id, rfrg.p2_component2_id,
                             rfrg.p2_comp2_display_id, rfrg.p2_c2_detail_id,
                             rfrg.p2_c2_type, rfrg.p2_c2_rank,
                             rfrg.p2_c2_secondary_ind, rfrg.p2_c2_start_date,
                             rfrg.p2_c2_start_ind, rfrg.p2_c2_apply_to_code,
                             rfrg.p2_c2_change_type, rfrg.p2_c2_change_amount,
                             rfrg.p2_c2_change_currency,
                             rfrg.p2_c2_change_percent,
                             rfrg.p2_c2_change_selling_uom,
                             rfrg.p2_c2_price_guide_id, rfrg.p2_exclusion1_id,
                             rfrg.p2_exclusion1_display_id,
                             rfrg.p2_exclusion1_type, rfrg.p2_e1_start_ind,
                             rfrg.p2_exclusion2_id,
                             rfrg.p2_exclusion2_display_id,
                             rfrg.p2_exclusion2_type, rfrg.p2_e2_start_ind,
                             rfrg.loc_move_from_zone_id,
                             rfrg.loc_move_to_zone_id, rfrg.location_move_id);

               DELETE FROM rpm_future_retail rfr
                     WHERE rfr.ROWID IN (SELECT rfrg.rfr_rowid
                                           FROM rpm_future_retail_gtt rfrg
                                          WHERE rfrg.timeline_seq = -999);
            END LOOP;
         END IF;
      END IF;

      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END push_back_all;

--19-Apr-2010 BC_KC  NBS00017378      performances fix End

   --------------------------------------------------
   FUNCTION consolidate_cc_error_tbl (
      o_cc_error_tbl    OUT      conflict_check_error_tbl,
      i_cc_error_tbl1   IN       conflict_check_error_tbl,
      i_cc_error_tbl2   IN       conflict_check_error_tbl
   )
      RETURN NUMBER
   IS
--
      l_program         VARCHAR2 (100)
                          := 'RPM_FUTURE_RETAIL_SQL.CONSOLIDATE_CC_ERROR_TBL';
--
      l_cc_error_tbl1   conflict_check_error_tbl := i_cc_error_tbl1;
      l_cc_error_tbl2   conflict_check_error_tbl := i_cc_error_tbl2;
--
   BEGIN
      --
      o_cc_error_tbl := conflict_check_error_tbl ();

      --
      IF l_cc_error_tbl1 IS NOT NULL AND l_cc_error_tbl1.COUNT > 0
      THEN
         FOR i IN 1 .. l_cc_error_tbl1.COUNT
         LOOP
            o_cc_error_tbl.EXTEND;
            o_cc_error_tbl (o_cc_error_tbl.COUNT) := l_cc_error_tbl1 (i);
         END LOOP;
      END IF;

      --
      IF l_cc_error_tbl2 IS NOT NULL AND l_cc_error_tbl2.COUNT > 0
      THEN
         FOR i IN 1 .. l_cc_error_tbl1.COUNT
         LOOP
            o_cc_error_tbl.EXTEND;
            o_cc_error_tbl (o_cc_error_tbl.COUNT) := l_cc_error_tbl2 (i);
         END LOOP;
      END IF;

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END consolidate_cc_error_tbl;

--------------------------------------------------------------------------------
--05-Nov-2008 Murali CR167 and  173  Begin
--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
   FUNCTION tsl_zone_push_back (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      l_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program        VARCHAR2 (100)
                                := 'RPM_FUTURE_RETAIL_SQL.TSL_ZONE_PUSH_BACK';
      l_active_state   VARCHAR2 (50)  := 'notactive';

      CURSOR c_active_promo
      IS
         SELECT DISTINCT state
                    FROM rpm_promo_comp_detail
                   WHERE rpm_promo_comp_detail_id IN (
                            SELECT VALUE (ID)
                              FROM TABLE
                                      (CAST
                                          (NVL (l_price_event_ids,
                                                obj_numeric_id_table (0)
                                               ) AS obj_numeric_id_table
                                          )
                                      ) ID);
--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
   BEGIN
      --
      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
      IF i_price_event_type IN
            (rpm_conflict_library.simple_promotion,
             rpm_conflict_library.simple_update,
             rpm_conflict_library.threshold_promotion,
             rpm_conflict_library.threshold_update,
             rpm_conflict_library.multibuy_promotion,
             rpm_conflict_library.multibuy_update
            )
      THEN
         FOR v_rec IN c_active_promo
         LOOP
            IF v_rec.state = 'pcd.active'
            THEN
               l_active_state := v_rec.state;
               EXIT;
            END IF;
         END LOOP;
      END IF;

      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
      MERGE INTO tsl_rpm_pro_zone_fut_ret rfr
         USING (SELECT *
                  FROM rpm_future_retail_gtt
                 WHERE TRUNC (action_date) >= TRUNC (lp_push_back_start_date)
                   AND LOCATION IN (SELECT zone_id
                                      FROM rpm_zone rz)
                   --23-Jul-2009 Jini Moses Mod93b  Begin
                   AND zone_node_type = 1) rfrg
         --23-Jul-2009 Jini Moses Mod93b  End
      ON (rfr.ROWID = rfrg.rfr_rowid)
         WHEN MATCHED THEN
            UPDATE
               SET rfr.selling_retail = rfrg.selling_retail,
                   rfr.selling_retail_currency = rfrg.selling_retail_currency,
                   rfr.selling_uom = rfrg.selling_uom,
                   rfr.multi_units = rfrg.multi_units,
                   rfr.multi_unit_retail = rfrg.multi_unit_retail,
                   rfr.multi_unit_retail_currency =
                                               rfrg.multi_unit_retail_currency,
                   rfr.multi_selling_uom = rfrg.multi_selling_uom,
                   rfr.clear_retail = rfrg.clear_retail,
                   rfr.clear_retail_currency = rfrg.clear_retail_currency,
                   rfr.clear_uom = rfrg.clear_uom,
                   rfr.simple_promo_retail = rfrg.simple_promo_retail,
                   rfr.simple_promo_retail_currency =
                                             rfrg.simple_promo_retail_currency,
                   rfr.simple_promo_uom = rfrg.simple_promo_uom,
                   rfr.complex_promo_retail = rfrg.complex_promo_retail,
                   rfr.complex_promo_retail_currency =
                                            rfrg.complex_promo_retail_currency,
                   rfr.complex_promo_uom = rfrg.complex_promo_uom,
                   rfr.price_change_id = rfrg.price_change_id,
                   rfr.price_change_display_id = rfrg.price_change_display_id,
                   rfr.pc_exception_parent_id = rfrg.pc_exception_parent_id,
                   rfr.pc_change_type = rfrg.pc_change_type,
                   rfr.pc_change_amount = rfrg.pc_change_amount,
                   rfr.pc_change_currency = rfrg.pc_change_currency,
                   rfr.pc_change_percent = rfrg.pc_change_percent,
                   rfr.pc_change_selling_uom = rfrg.pc_change_selling_uom,
                   rfr.pc_null_multi_ind = rfrg.pc_null_multi_ind,
                   rfr.pc_multi_units = rfrg.pc_multi_units,
                   rfr.pc_multi_unit_retail = rfrg.pc_multi_unit_retail,
                   rfr.pc_multi_unit_retail_currency =
                                            rfrg.pc_multi_unit_retail_currency,
                   rfr.pc_multi_selling_uom = rfrg.pc_multi_selling_uom,
                   rfr.pc_price_guide_id = rfrg.pc_price_guide_id,
                   rfr.clearance_id = rfrg.clearance_id,
                   rfr.clearance_display_id = rfrg.clearance_display_id,
                   rfr.clear_mkdn_index = rfrg.clear_mkdn_index,
                   rfr.clear_start_ind = rfrg.clear_start_ind,
                   rfr.clear_change_type = rfrg.clear_change_type,
                   rfr.clear_change_amount = rfrg.clear_change_amount,
                   rfr.clear_change_currency = rfrg.clear_change_currency,
                   rfr.clear_change_percent = rfrg.clear_change_percent,
                   rfr.clear_change_selling_uom =
                                                 rfrg.clear_change_selling_uom,
                   rfr.clear_price_guide_id = rfrg.clear_price_guide_id,
                   rfr.promotion1_id = rfrg.promotion1_id,
                   rfr.promo1_display_id = rfrg.promo1_display_id,
                   rfr.p1_start_date = rfrg.p1_start_date,
                   rfr.p1_rank = rfrg.p1_rank,
                   rfr.p1_secondary_ind = rfrg.p1_secondary_ind,
                   rfr.p1_component1_id = rfrg.p1_component1_id,
                   rfr.p1_comp1_display_id = rfrg.p1_comp1_display_id,
                   rfr.p1_c1_detail_id = rfrg.p1_c1_detail_id,
                   rfr.p1_c1_type = rfrg.p1_c1_type,
                   rfr.p1_c1_rank = rfrg.p1_c1_rank,
                   rfr.p1_c1_secondary_ind = rfrg.p1_c1_secondary_ind,
                   rfr.p1_c1_start_date = rfrg.p1_c1_start_date,
                   rfr.p1_c1_start_ind = rfrg.p1_c1_start_ind,
                   rfr.p1_c1_apply_to_code = rfrg.p1_c1_apply_to_code,
                   rfr.p1_c1_change_type = rfrg.p1_c1_change_type,
                   rfr.p1_c1_change_amount = rfrg.p1_c1_change_amount,
                   rfr.p1_c1_change_currency = rfrg.p1_c1_change_currency,
                   rfr.p1_c1_change_percent = rfrg.p1_c1_change_percent,
                   rfr.p1_c1_change_selling_uom =
                                                 rfrg.p1_c1_change_selling_uom,
                   rfr.p1_c1_price_guide_id = rfrg.p1_c1_price_guide_id,
                   rfr.p1_component2_id = rfrg.p1_component2_id,
                   rfr.p1_comp2_display_id = rfrg.p1_comp2_display_id,
                   rfr.p1_c2_detail_id = rfrg.p1_c2_detail_id,
                   rfr.p1_c2_type = rfrg.p1_c2_type,
                   rfr.p1_c2_rank = rfrg.p1_c2_rank,
                   rfr.p1_c2_secondary_ind = rfrg.p1_c2_secondary_ind,
                   rfr.p1_c2_start_date = rfrg.p1_c2_start_date,
                   rfr.p1_c2_start_ind = rfrg.p1_c2_start_ind,
                   rfr.p1_c2_apply_to_code = rfrg.p1_c2_apply_to_code,
                   rfr.p1_c2_change_type = rfrg.p1_c2_change_type,
                   rfr.p1_c2_change_amount = rfrg.p1_c2_change_amount,
                   rfr.p1_c2_change_currency = rfrg.p1_c2_change_currency,
                   rfr.p1_c2_change_percent = rfrg.p1_c2_change_percent,
                   rfr.p1_c2_change_selling_uom =
                                                 rfrg.p1_c2_change_selling_uom,
                   rfr.p1_c2_price_guide_id = rfrg.p1_c2_price_guide_id,
                   rfr.p1_exclusion1_id = rfrg.p1_exclusion1_id,
                   rfr.p1_exclusion1_display_id =
                                                 rfrg.p1_exclusion1_display_id,
                   rfr.p1_exclusion1_type = rfrg.p1_exclusion1_type,
                   rfr.p1_e1_start_ind = rfrg.p1_e1_start_ind,
                   rfr.p1_exclusion2_id = rfrg.p1_exclusion2_id,
                   rfr.p1_exclusion2_display_id =
                                                 rfrg.p1_exclusion2_display_id,
                   rfr.p1_exclusion2_type = rfrg.p1_exclusion2_type,
                   rfr.p1_e2_start_ind = rfrg.p1_e2_start_ind,
                   rfr.promotion2_id = rfrg.promotion2_id,
                   rfr.promo2_display_id = rfrg.promo2_display_id,
                   rfr.p2_start_date = rfrg.p2_start_date,
                   rfr.p2_rank = rfrg.p2_rank,
                   rfr.p2_secondary_ind = rfrg.p2_secondary_ind,
                   rfr.p2_component1_id = rfrg.p2_component1_id,
                   rfr.p2_comp1_display_id = rfrg.p2_comp1_display_id,
                   rfr.p2_c1_detail_id = rfrg.p2_c1_detail_id,
                   rfr.p2_c1_type = rfrg.p2_c1_type,
                   rfr.p2_c1_rank = rfrg.p2_c1_rank,
                   rfr.p2_c1_secondary_ind = rfrg.p2_c1_secondary_ind,
                   rfr.p2_c1_start_date = rfrg.p2_c1_start_date,
                   rfr.p2_c1_start_ind = rfrg.p2_c1_start_ind,
                   rfr.p2_c1_apply_to_code = rfrg.p2_c1_apply_to_code,
                   rfr.p2_c1_change_type = rfrg.p2_c1_change_type,
                   rfr.p2_c1_change_amount = rfrg.p2_c1_change_amount,
                   rfr.p2_c1_change_currency = rfrg.p2_c1_change_currency,
                   rfr.p2_c1_change_percent = rfrg.p2_c1_change_percent,
                   rfr.p2_c1_change_selling_uom =
                                                 rfrg.p2_c1_change_selling_uom,
                   rfr.p2_c1_price_guide_id = rfrg.p2_c1_price_guide_id,
                   rfr.p2_component2_id = rfrg.p2_component2_id,
                   rfr.p2_comp2_display_id = rfrg.p2_comp2_display_id,
                   rfr.p2_c2_detail_id = rfrg.p2_c2_detail_id,
                   rfr.p2_c2_type = rfrg.p2_c2_type,
                   rfr.p2_c2_rank = rfrg.p2_c2_rank,
                   rfr.p2_c2_secondary_ind = rfrg.p2_c2_secondary_ind,
                   rfr.p2_c2_start_date = rfrg.p2_c2_start_date,
                   rfr.p2_c2_start_ind = rfrg.p2_c2_start_ind,
                   rfr.p2_c2_apply_to_code = rfrg.p2_c2_apply_to_code,
                   rfr.p2_c2_change_type = rfrg.p2_c2_change_type,
                   rfr.p2_c2_change_amount = rfrg.p2_c2_change_amount,
                   rfr.p2_c2_change_currency = rfrg.p2_c2_change_currency,
                   rfr.p2_c2_change_percent = rfrg.p2_c2_change_percent,
                   rfr.p2_c2_change_selling_uom =
                                                 rfrg.p2_c2_change_selling_uom,
                   rfr.p2_c2_price_guide_id = rfrg.p2_c2_price_guide_id,
                   rfr.p2_exclusion1_id = rfrg.p2_exclusion1_id,
                   rfr.p2_exclusion1_display_id =
                                                 rfrg.p2_exclusion1_display_id,
                   rfr.p2_exclusion1_type = rfrg.p2_exclusion1_type,
                   rfr.p2_e1_start_ind = rfrg.p2_e1_start_ind,
                   rfr.p2_exclusion2_id = rfrg.p2_exclusion2_id,
                   rfr.p2_exclusion2_display_id =
                                                 rfrg.p2_exclusion2_display_id,
                   rfr.p2_exclusion2_type = rfrg.p2_exclusion2_type,
                   rfr.p2_e2_start_ind = rfrg.p2_e2_start_ind,
                   rfr.loc_move_from_zone_id = rfrg.loc_move_from_zone_id,
                   rfr.loc_move_to_zone_id = rfrg.loc_move_to_zone_id,
                   rfr.location_move_id = rfrg.location_move_id
         WHEN NOT MATCHED THEN
            INSERT (pro_zone_fut_ret_id, dept, CLASS, subclass, item,
                    zone_node_type, LOCATION, action_date, selling_retail,
                    selling_retail_currency, selling_uom, multi_units,
                    multi_unit_retail, multi_unit_retail_currency,
                    multi_selling_uom, clear_retail, clear_retail_currency,
                    clear_uom, simple_promo_retail,
                    simple_promo_retail_currency, simple_promo_uom,
                    complex_promo_retail, complex_promo_retail_currency,
                    complex_promo_uom, price_change_id,
                    price_change_display_id, pc_exception_parent_id,
                    pc_change_type, pc_change_amount, pc_change_currency,
                    pc_change_percent, pc_change_selling_uom,
                    pc_null_multi_ind, pc_multi_units, pc_multi_unit_retail,
                    pc_multi_unit_retail_currency, pc_multi_selling_uom,
                    pc_price_guide_id, clearance_id, clearance_display_id,
                    clear_mkdn_index, clear_start_ind, clear_change_type,
                    clear_change_amount, clear_change_currency,
                    clear_change_percent, clear_change_selling_uom,
                    clear_price_guide_id, promotion1_id, promo1_display_id,
                    p1_start_date, p1_rank, p1_secondary_ind,
                    p1_component1_id, p1_comp1_display_id, p1_c1_detail_id,
                    p1_c1_type, p1_c1_rank, p1_c1_secondary_ind,
                    p1_c1_start_date, p1_c1_start_ind, p1_c1_apply_to_code,
                    p1_c1_change_type, p1_c1_change_amount,
                    p1_c1_change_currency, p1_c1_change_percent,
                    p1_c1_change_selling_uom, p1_c1_price_guide_id,
                    p1_component2_id, p1_comp2_display_id, p1_c2_detail_id,
                    p1_c2_type, p1_c2_rank, p1_c2_secondary_ind,
                    p1_c2_start_date, p1_c2_start_ind, p1_c2_apply_to_code,
                    p1_c2_change_type, p1_c2_change_amount,
                    p1_c2_change_currency, p1_c2_change_percent,
                    p1_c2_change_selling_uom, p1_c2_price_guide_id,
                    p1_exclusion1_id, p1_exclusion1_display_id,
                    p1_exclusion1_type, p1_e1_start_ind, p1_exclusion2_id,
                    p1_exclusion2_display_id, p1_exclusion2_type,
                    p1_e2_start_ind, promotion2_id, promo2_display_id,
                    p2_start_date, p2_rank, p2_secondary_ind,
                    p2_component1_id, p2_comp1_display_id, p2_c1_detail_id,
                    p2_c1_type, p2_c1_rank, p2_c1_secondary_ind,
                    p2_c1_start_date, p2_c1_start_ind, p2_c1_apply_to_code,
                    p2_c1_change_type, p2_c1_change_amount,
                    p2_c1_change_currency, p2_c1_change_percent,
                    p2_c1_change_selling_uom, p2_c1_price_guide_id,
                    p2_component2_id, p2_comp2_display_id, p2_c2_detail_id,
                    p2_c2_type, p2_c2_rank, p2_c2_secondary_ind,
                    p2_c2_start_date, p2_c2_start_ind, p2_c2_apply_to_code,
                    p2_c2_change_type, p2_c2_change_amount,
                    p2_c2_change_currency, p2_c2_change_percent,
                    p2_c2_change_selling_uom, p2_c2_price_guide_id,
                    p2_exclusion1_id, p2_exclusion1_display_id,
                    p2_exclusion1_type, p2_e1_start_ind, p2_exclusion2_id,
                    p2_exclusion2_display_id, p2_exclusion2_type,
                    p2_e2_start_ind, loc_move_from_zone_id,
                    loc_move_to_zone_id, location_move_id)
            VALUES (rfrg.future_retail_id, rfrg.dept, rfrg.CLASS,
                    rfrg.subclass, rfrg.item, rfrg.zone_node_type,
                    rfrg.LOCATION, rfrg.action_date, rfrg.selling_retail,
                    rfrg.selling_retail_currency, rfrg.selling_uom,
                    rfrg.multi_units, rfrg.multi_unit_retail,
                    rfrg.multi_unit_retail_currency, rfrg.multi_selling_uom,
                    rfrg.clear_retail, rfrg.clear_retail_currency,
                    rfrg.clear_uom, rfrg.simple_promo_retail,
                    rfrg.simple_promo_retail_currency, rfrg.simple_promo_uom,
                    rfrg.complex_promo_retail,
                    rfrg.complex_promo_retail_currency,
                    rfrg.complex_promo_uom, rfrg.price_change_id,
                    rfrg.price_change_display_id, rfrg.pc_exception_parent_id,
                    rfrg.pc_change_type, rfrg.pc_change_amount,
                    rfrg.pc_change_currency, rfrg.pc_change_percent,
                    rfrg.pc_change_selling_uom, rfrg.pc_null_multi_ind,
                    rfrg.pc_multi_units, rfrg.pc_multi_unit_retail,
                    rfrg.pc_multi_unit_retail_currency,
                    rfrg.pc_multi_selling_uom, rfrg.pc_price_guide_id,
                    rfrg.clearance_id, rfrg.clearance_display_id,
                    rfrg.clear_mkdn_index, rfrg.clear_start_ind,
                    rfrg.clear_change_type, rfrg.clear_change_amount,
                    rfrg.clear_change_currency, rfrg.clear_change_percent,
                    rfrg.clear_change_selling_uom, rfrg.clear_price_guide_id,
                    rfrg.promotion1_id, rfrg.promo1_display_id,
                    rfrg.p1_start_date, rfrg.p1_rank, rfrg.p1_secondary_ind,
                    rfrg.p1_component1_id, rfrg.p1_comp1_display_id,
                    rfrg.p1_c1_detail_id, rfrg.p1_c1_type, rfrg.p1_c1_rank,
                    rfrg.p1_c1_secondary_ind, rfrg.p1_c1_start_date,
                    rfrg.p1_c1_start_ind, rfrg.p1_c1_apply_to_code,
                    rfrg.p1_c1_change_type, rfrg.p1_c1_change_amount,
                    rfrg.p1_c1_change_currency, rfrg.p1_c1_change_percent,
                    rfrg.p1_c1_change_selling_uom, rfrg.p1_c1_price_guide_id,
                    rfrg.p1_component2_id, rfrg.p1_comp2_display_id,
                    rfrg.p1_c2_detail_id, rfrg.p1_c2_type, rfrg.p1_c2_rank,
                    rfrg.p1_c2_secondary_ind, rfrg.p1_c2_start_date,
                    rfrg.p1_c2_start_ind, rfrg.p1_c2_apply_to_code,
                    rfrg.p1_c2_change_type, rfrg.p1_c2_change_amount,
                    rfrg.p1_c2_change_currency, rfrg.p1_c2_change_percent,
                    rfrg.p1_c2_change_selling_uom, rfrg.p1_c2_price_guide_id,
                    rfrg.p1_exclusion1_id, rfrg.p1_exclusion1_display_id,
                    rfrg.p1_exclusion1_type, rfrg.p1_e1_start_ind,
                    rfrg.p1_exclusion2_id, rfrg.p1_exclusion2_display_id,
                    rfrg.p1_exclusion2_type, rfrg.p1_e2_start_ind,
                    rfrg.promotion2_id, rfrg.promo2_display_id,
                    rfrg.p2_start_date, rfrg.p2_rank, rfrg.p2_secondary_ind,
                    rfrg.p2_component1_id, rfrg.p2_comp1_display_id,
                    rfrg.p2_c1_detail_id, rfrg.p2_c1_type, rfrg.p2_c1_rank,
                    rfrg.p2_c1_secondary_ind, rfrg.p2_c1_start_date,
                    rfrg.p2_c1_start_ind, rfrg.p2_c1_apply_to_code,
                    rfrg.p2_c1_change_type, rfrg.p2_c1_change_amount,
                    rfrg.p2_c1_change_currency, rfrg.p2_c1_change_percent,
                    rfrg.p2_c1_change_selling_uom, rfrg.p2_c1_price_guide_id,
                    rfrg.p2_component2_id, rfrg.p2_comp2_display_id,
                    rfrg.p2_c2_detail_id, rfrg.p2_c2_type, rfrg.p2_c2_rank,
                    rfrg.p2_c2_secondary_ind, rfrg.p2_c2_start_date,
                    rfrg.p2_c2_start_ind, rfrg.p2_c2_apply_to_code,
                    rfrg.p2_c2_change_type, rfrg.p2_c2_change_amount,
                    rfrg.p2_c2_change_currency, rfrg.p2_c2_change_percent,
                    rfrg.p2_c2_change_selling_uom, rfrg.p2_c2_price_guide_id,
                    rfrg.p2_exclusion1_id, rfrg.p2_exclusion1_display_id,
                    rfrg.p2_exclusion1_type, rfrg.p2_e1_start_ind,
                    rfrg.p2_exclusion2_id, rfrg.p2_exclusion2_display_id,
                    rfrg.p2_exclusion2_type, rfrg.p2_e2_start_ind,
                    rfrg.loc_move_from_zone_id, rfrg.loc_move_to_zone_id,
                    rfrg.location_move_id);

      --
      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
      IF (l_active_state != 'pcd.active')
      THEN
         DELETE FROM tsl_rpm_pro_zone_fut_ret rfr
               WHERE rfr.ROWID IN (SELECT rfrg.rfr_rowid
                                     FROM rpm_future_retail_gtt rfrg
                                    WHERE rfrg.timeline_seq = -999);
      END IF;

      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
      DELETE FROM rpm_future_retail_gtt rfrg
            WHERE rfrg.LOCATION IN (SELECT zone_id
                                      FROM rpm_zone rz);

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END tsl_zone_push_back;

--05-Nov-2008 Murali CR167 and 173  End
--------------------------------------------------------------------------------

   -- Mod N25 Vikash Prasad 25-May-2009 BEGIN
----------------------------------------------------------------------------------------
-- Function Name : TSL_PUSH_BACK
-- Purpose       : This function is used to update the RPM_FUTURE_RETAIL table if if TSL_RPM_LOC_MOVE_CHGS is set to 'Y'
-----------------------------------------------------------------------------------------

   --19-Apr-2010 BC_KC  NBS00017378      performances fix Begin
   FUNCTION tsl_push_back (o_cc_error_tbl OUT conflict_check_error_tbl)
      RETURN NUMBER
   IS
      l_program   VARCHAR2 (100) := 'RPM_FUTURE_RETAIL_SQL.TSL_PUSH_BACK';
--
   BEGIN
      -- BC_KC 19/04/2010 Performance fix rowid hint
      -- also suffixed alias rfr_tpb
      -- so as to identify within trace file
      MERGE                         /*+ rowid(rfr_tpb) */ INTO rpm_future_retail rfr_tpb
         USING (SELECT /*+ full(rfrg) */
                       gtt.*
                  FROM rpm_future_retail_gtt gtt) rfrg
         ON (rfr_tpb.ROWID = rfrg.rfr_rowid)
         WHEN MATCHED THEN
            UPDATE
               SET rfr_tpb.selling_retail = rfrg.selling_retail,
                   rfr_tpb.selling_retail_currency =
                                                 rfrg.selling_retail_currency,
                   rfr_tpb.selling_uom = rfrg.selling_uom,
                   rfr_tpb.multi_units = rfrg.multi_units,
                   rfr_tpb.multi_unit_retail = rfrg.multi_unit_retail,
                   rfr_tpb.multi_unit_retail_currency =
                                              rfrg.multi_unit_retail_currency,
                   rfr_tpb.multi_selling_uom = rfrg.multi_selling_uom,
                   rfr_tpb.clear_retail = rfrg.clear_retail,
                   rfr_tpb.clear_retail_currency = rfrg.clear_retail_currency,
                   rfr_tpb.clear_uom = rfrg.clear_uom,
                   rfr_tpb.simple_promo_retail = rfrg.simple_promo_retail,
                   rfr_tpb.simple_promo_retail_currency =
                                            rfrg.simple_promo_retail_currency,
                   rfr_tpb.simple_promo_uom = rfrg.simple_promo_uom,
                   rfr_tpb.complex_promo_retail = rfrg.complex_promo_retail,
                   rfr_tpb.complex_promo_retail_currency =
                                           rfrg.complex_promo_retail_currency,
                   rfr_tpb.complex_promo_uom = rfrg.complex_promo_uom,
                   rfr_tpb.price_change_id = rfrg.price_change_id,
                   rfr_tpb.price_change_display_id =
                                                 rfrg.price_change_display_id,
                   rfr_tpb.pc_exception_parent_id =
                                                  rfrg.pc_exception_parent_id,
                   rfr_tpb.pc_change_type = rfrg.pc_change_type,
                   rfr_tpb.pc_change_amount = rfrg.pc_change_amount,
                   rfr_tpb.pc_change_currency = rfrg.pc_change_currency,
                   rfr_tpb.pc_change_percent = rfrg.pc_change_percent,
                   rfr_tpb.pc_change_selling_uom = rfrg.pc_change_selling_uom,
                   rfr_tpb.pc_null_multi_ind = rfrg.pc_null_multi_ind,
                   rfr_tpb.pc_multi_units = rfrg.pc_multi_units,
                   rfr_tpb.pc_multi_unit_retail = rfrg.pc_multi_unit_retail,
                   rfr_tpb.pc_multi_unit_retail_currency =
                                           rfrg.pc_multi_unit_retail_currency,
                   rfr_tpb.pc_multi_selling_uom = rfrg.pc_multi_selling_uom,
                   rfr_tpb.pc_price_guide_id = rfrg.pc_price_guide_id,
                   rfr_tpb.clearance_id = rfrg.clearance_id,
                   rfr_tpb.clearance_display_id = rfrg.clearance_display_id,
                   rfr_tpb.clear_mkdn_index = rfrg.clear_mkdn_index,
                   rfr_tpb.clear_start_ind = rfrg.clear_start_ind,
                   rfr_tpb.clear_change_type = rfrg.clear_change_type,
                   rfr_tpb.clear_change_amount = rfrg.clear_change_amount,
                   rfr_tpb.clear_change_currency = rfrg.clear_change_currency,
                   rfr_tpb.clear_change_percent = rfrg.clear_change_percent,
                   rfr_tpb.clear_change_selling_uom =
                                                rfrg.clear_change_selling_uom,
                   rfr_tpb.clear_price_guide_id = rfrg.clear_price_guide_id,
                   rfr_tpb.promotion1_id = rfrg.promotion1_id,
                   rfr_tpb.promo1_display_id = rfrg.promo1_display_id,
                   rfr_tpb.p1_start_date = rfrg.p1_start_date,
                   rfr_tpb.p1_rank = rfrg.p1_rank,
                   rfr_tpb.p1_secondary_ind = rfrg.p1_secondary_ind,
                   rfr_tpb.p1_component1_id = rfrg.p1_component1_id,
                   rfr_tpb.p1_comp1_display_id = rfrg.p1_comp1_display_id,
                   rfr_tpb.p1_c1_detail_id = rfrg.p1_c1_detail_id,
                   rfr_tpb.p1_c1_type = rfrg.p1_c1_type,
                   rfr_tpb.p1_c1_rank = rfrg.p1_c1_rank,
                   rfr_tpb.p1_c1_secondary_ind = rfrg.p1_c1_secondary_ind,
                   rfr_tpb.p1_c1_start_date = rfrg.p1_c1_start_date,
                   rfr_tpb.p1_c1_start_ind = rfrg.p1_c1_start_ind,
                   rfr_tpb.p1_c1_apply_to_code = rfrg.p1_c1_apply_to_code,
                   rfr_tpb.p1_c1_change_type = rfrg.p1_c1_change_type,
                   rfr_tpb.p1_c1_change_amount = rfrg.p1_c1_change_amount,
                   rfr_tpb.p1_c1_change_currency = rfrg.p1_c1_change_currency,
                   rfr_tpb.p1_c1_change_percent = rfrg.p1_c1_change_percent,
                   rfr_tpb.p1_c1_change_selling_uom =
                                                rfrg.p1_c1_change_selling_uom,
                   rfr_tpb.p1_c1_price_guide_id = rfrg.p1_c1_price_guide_id,
                   rfr_tpb.p1_component2_id = rfrg.p1_component2_id,
                   rfr_tpb.p1_comp2_display_id = rfrg.p1_comp2_display_id,
                   rfr_tpb.p1_c2_detail_id = rfrg.p1_c2_detail_id,
                   rfr_tpb.p1_c2_type = rfrg.p1_c2_type,
                   rfr_tpb.p1_c2_rank = rfrg.p1_c2_rank,
                   rfr_tpb.p1_c2_secondary_ind = rfrg.p1_c2_secondary_ind,
                   rfr_tpb.p1_c2_start_date = rfrg.p1_c2_start_date,
                   rfr_tpb.p1_c2_start_ind = rfrg.p1_c2_start_ind,
                   rfr_tpb.p1_c2_apply_to_code = rfrg.p1_c2_apply_to_code,
                   rfr_tpb.p1_c2_change_type = rfrg.p1_c2_change_type,
                   rfr_tpb.p1_c2_change_amount = rfrg.p1_c2_change_amount,
                   rfr_tpb.p1_c2_change_currency = rfrg.p1_c2_change_currency,
                   rfr_tpb.p1_c2_change_percent = rfrg.p1_c2_change_percent,
                   rfr_tpb.p1_c2_change_selling_uom =
                                                rfrg.p1_c2_change_selling_uom,
                   rfr_tpb.p1_c2_price_guide_id = rfrg.p1_c2_price_guide_id,
                   rfr_tpb.p1_exclusion1_id = rfrg.p1_exclusion1_id,
                   rfr_tpb.p1_exclusion1_display_id =
                                                rfrg.p1_exclusion1_display_id,
                   rfr_tpb.p1_exclusion1_type = rfrg.p1_exclusion1_type,
                   rfr_tpb.p1_e1_start_ind = rfrg.p1_e1_start_ind,
                   rfr_tpb.p1_exclusion2_id = rfrg.p1_exclusion2_id,
                   rfr_tpb.p1_exclusion2_display_id =
                                                rfrg.p1_exclusion2_display_id,
                   rfr_tpb.p1_exclusion2_type = rfrg.p1_exclusion2_type,
                   rfr_tpb.p1_e2_start_ind = rfrg.p1_e2_start_ind,
                   rfr_tpb.promotion2_id = rfrg.promotion2_id,
                   rfr_tpb.promo2_display_id = rfrg.promo2_display_id,
                   rfr_tpb.p2_start_date = rfrg.p2_start_date,
                   rfr_tpb.p2_rank = rfrg.p2_rank,
                   rfr_tpb.p2_secondary_ind = rfrg.p2_secondary_ind,
                   rfr_tpb.p2_component1_id = rfrg.p2_component1_id,
                   rfr_tpb.p2_comp1_display_id = rfrg.p2_comp1_display_id,
                   rfr_tpb.p2_c1_detail_id = rfrg.p2_c1_detail_id,
                   rfr_tpb.p2_c1_type = rfrg.p2_c1_type,
                   rfr_tpb.p2_c1_rank = rfrg.p2_c1_rank,
                   rfr_tpb.p2_c1_secondary_ind = rfrg.p2_c1_secondary_ind,
                   rfr_tpb.p2_c1_start_date = rfrg.p2_c1_start_date,
                   rfr_tpb.p2_c1_start_ind = rfrg.p2_c1_start_ind,
                   rfr_tpb.p2_c1_apply_to_code = rfrg.p2_c1_apply_to_code,
                   rfr_tpb.p2_c1_change_type = rfrg.p2_c1_change_type,
                   rfr_tpb.p2_c1_change_amount = rfrg.p2_c1_change_amount,
                   rfr_tpb.p2_c1_change_currency = rfrg.p2_c1_change_currency,
                   rfr_tpb.p2_c1_change_percent = rfrg.p2_c1_change_percent,
                   rfr_tpb.p2_c1_change_selling_uom =
                                                rfrg.p2_c1_change_selling_uom,
                   rfr_tpb.p2_c1_price_guide_id = rfrg.p2_c1_price_guide_id,
                   rfr_tpb.p2_component2_id = rfrg.p2_component2_id,
                   rfr_tpb.p2_comp2_display_id = rfrg.p2_comp2_display_id,
                   rfr_tpb.p2_c2_detail_id = rfrg.p2_c2_detail_id,
                   rfr_tpb.p2_c2_type = rfrg.p2_c2_type,
                   rfr_tpb.p2_c2_rank = rfrg.p2_c2_rank,
                   rfr_tpb.p2_c2_secondary_ind = rfrg.p2_c2_secondary_ind,
                   rfr_tpb.p2_c2_start_date = rfrg.p2_c2_start_date,
                   rfr_tpb.p2_c2_start_ind = rfrg.p2_c2_start_ind,
                   rfr_tpb.p2_c2_apply_to_code = rfrg.p2_c2_apply_to_code,
                   rfr_tpb.p2_c2_change_type = rfrg.p2_c2_change_type,
                   rfr_tpb.p2_c2_change_amount = rfrg.p2_c2_change_amount,
                   rfr_tpb.p2_c2_change_currency = rfrg.p2_c2_change_currency,
                   rfr_tpb.p2_c2_change_percent = rfrg.p2_c2_change_percent,
                   rfr_tpb.p2_c2_change_selling_uom =
                                                rfrg.p2_c2_change_selling_uom,
                   rfr_tpb.p2_c2_price_guide_id = rfrg.p2_c2_price_guide_id,
                   rfr_tpb.p2_exclusion1_id = rfrg.p2_exclusion1_id,
                   rfr_tpb.p2_exclusion1_display_id =
                                                rfrg.p2_exclusion1_display_id,
                   rfr_tpb.p2_exclusion1_type = rfrg.p2_exclusion1_type,
                   rfr_tpb.p2_e1_start_ind = rfrg.p2_e1_start_ind,
                   rfr_tpb.p2_exclusion2_id = rfrg.p2_exclusion2_id,
                   rfr_tpb.p2_exclusion2_display_id =
                                                rfrg.p2_exclusion2_display_id,
                   rfr_tpb.p2_exclusion2_type = rfrg.p2_exclusion2_type,
                   rfr_tpb.p2_e2_start_ind = rfrg.p2_e2_start_ind,
                   rfr_tpb.loc_move_from_zone_id = rfrg.loc_move_from_zone_id,
                   rfr_tpb.loc_move_to_zone_id = rfrg.loc_move_to_zone_id,
                   rfr_tpb.location_move_id = rfrg.location_move_id
         WHEN NOT MATCHED THEN
            INSERT (future_retail_id, dept, CLASS, subclass, item,
                    zone_node_type, LOCATION, action_date, selling_retail,
                    selling_retail_currency, selling_uom, multi_units,
                    multi_unit_retail, multi_unit_retail_currency,
                    multi_selling_uom, clear_retail, clear_retail_currency,
                    clear_uom, simple_promo_retail,
                    simple_promo_retail_currency, simple_promo_uom,
                    complex_promo_retail, complex_promo_retail_currency,
                    complex_promo_uom, price_change_id,
                    price_change_display_id, pc_exception_parent_id,
                    pc_change_type, pc_change_amount, pc_change_currency,
                    pc_change_percent, pc_change_selling_uom,
                    pc_null_multi_ind, pc_multi_units, pc_multi_unit_retail,
                    pc_multi_unit_retail_currency, pc_multi_selling_uom,
                    pc_price_guide_id, clearance_id, clearance_display_id,
                    clear_mkdn_index, clear_start_ind, clear_change_type,
                    clear_change_amount, clear_change_currency,
                    clear_change_percent, clear_change_selling_uom,
                    clear_price_guide_id, promotion1_id, promo1_display_id,
                    p1_start_date, p1_rank, p1_secondary_ind,
                    p1_component1_id, p1_comp1_display_id, p1_c1_detail_id,
                    p1_c1_type, p1_c1_rank, p1_c1_secondary_ind,
                    p1_c1_start_date, p1_c1_start_ind, p1_c1_apply_to_code,
                    p1_c1_change_type, p1_c1_change_amount,
                    p1_c1_change_currency, p1_c1_change_percent,
                    p1_c1_change_selling_uom, p1_c1_price_guide_id,
                    p1_component2_id, p1_comp2_display_id, p1_c2_detail_id,
                    p1_c2_type, p1_c2_rank, p1_c2_secondary_ind,
                    p1_c2_start_date, p1_c2_start_ind, p1_c2_apply_to_code,
                    p1_c2_change_type, p1_c2_change_amount,
                    p1_c2_change_currency, p1_c2_change_percent,
                    p1_c2_change_selling_uom, p1_c2_price_guide_id,
                    p1_exclusion1_id, p1_exclusion1_display_id,
                    p1_exclusion1_type, p1_e1_start_ind, p1_exclusion2_id,
                    p1_exclusion2_display_id, p1_exclusion2_type,
                    p1_e2_start_ind, promotion2_id, promo2_display_id,
                    p2_start_date, p2_rank, p2_secondary_ind,
                    p2_component1_id, p2_comp1_display_id, p2_c1_detail_id,
                    p2_c1_type, p2_c1_rank, p2_c1_secondary_ind,
                    p2_c1_start_date, p2_c1_start_ind, p2_c1_apply_to_code,
                    p2_c1_change_type, p2_c1_change_amount,
                    p2_c1_change_currency, p2_c1_change_percent,
                    p2_c1_change_selling_uom, p2_c1_price_guide_id,
                    p2_component2_id, p2_comp2_display_id, p2_c2_detail_id,
                    p2_c2_type, p2_c2_rank, p2_c2_secondary_ind,
                    p2_c2_start_date, p2_c2_start_ind, p2_c2_apply_to_code,
                    p2_c2_change_type, p2_c2_change_amount,
                    p2_c2_change_currency, p2_c2_change_percent,
                    p2_c2_change_selling_uom, p2_c2_price_guide_id,
                    p2_exclusion1_id, p2_exclusion1_display_id,
                    p2_exclusion1_type, p2_e1_start_ind, p2_exclusion2_id,
                    p2_exclusion2_display_id, p2_exclusion2_type,
                    p2_e2_start_ind, loc_move_from_zone_id,
                    loc_move_to_zone_id, location_move_id)
            VALUES (rfrg.future_retail_id, rfrg.dept, rfrg.CLASS,
                    rfrg.subclass, rfrg.item, rfrg.zone_node_type,
                    rfrg.LOCATION, rfrg.action_date, rfrg.selling_retail,
                    rfrg.selling_retail_currency, rfrg.selling_uom,
                    rfrg.multi_units, rfrg.multi_unit_retail,
                    rfrg.multi_unit_retail_currency, rfrg.multi_selling_uom,
                    rfrg.clear_retail, rfrg.clear_retail_currency,
                    rfrg.clear_uom, rfrg.simple_promo_retail,
                    rfrg.simple_promo_retail_currency, rfrg.simple_promo_uom,
                    rfrg.complex_promo_retail,
                    rfrg.complex_promo_retail_currency,
                    rfrg.complex_promo_uom, rfrg.price_change_id,
                    rfrg.price_change_display_id,
                    rfrg.pc_exception_parent_id, rfrg.pc_change_type,
                    rfrg.pc_change_amount, rfrg.pc_change_currency,
                    rfrg.pc_change_percent, rfrg.pc_change_selling_uom,
                    rfrg.pc_null_multi_ind, rfrg.pc_multi_units,
                    rfrg.pc_multi_unit_retail,
                    rfrg.pc_multi_unit_retail_currency,
                    rfrg.pc_multi_selling_uom, rfrg.pc_price_guide_id,
                    rfrg.clearance_id, rfrg.clearance_display_id,
                    rfrg.clear_mkdn_index, rfrg.clear_start_ind,
                    rfrg.clear_change_type, rfrg.clear_change_amount,
                    rfrg.clear_change_currency, rfrg.clear_change_percent,
                    rfrg.clear_change_selling_uom, rfrg.clear_price_guide_id,
                    rfrg.promotion1_id, rfrg.promo1_display_id,
                    rfrg.p1_start_date, rfrg.p1_rank, rfrg.p1_secondary_ind,
                    rfrg.p1_component1_id, rfrg.p1_comp1_display_id,
                    rfrg.p1_c1_detail_id, rfrg.p1_c1_type, rfrg.p1_c1_rank,
                    rfrg.p1_c1_secondary_ind, rfrg.p1_c1_start_date,
                    rfrg.p1_c1_start_ind, rfrg.p1_c1_apply_to_code,
                    rfrg.p1_c1_change_type, rfrg.p1_c1_change_amount,
                    rfrg.p1_c1_change_currency, rfrg.p1_c1_change_percent,
                    rfrg.p1_c1_change_selling_uom, rfrg.p1_c1_price_guide_id,
                    rfrg.p1_component2_id, rfrg.p1_comp2_display_id,
                    rfrg.p1_c2_detail_id, rfrg.p1_c2_type, rfrg.p1_c2_rank,
                    rfrg.p1_c2_secondary_ind, rfrg.p1_c2_start_date,
                    rfrg.p1_c2_start_ind, rfrg.p1_c2_apply_to_code,
                    rfrg.p1_c2_change_type, rfrg.p1_c2_change_amount,
                    rfrg.p1_c2_change_currency, rfrg.p1_c2_change_percent,
                    rfrg.p1_c2_change_selling_uom, rfrg.p1_c2_price_guide_id,
                    rfrg.p1_exclusion1_id, rfrg.p1_exclusion1_display_id,
                    rfrg.p1_exclusion1_type, rfrg.p1_e1_start_ind,
                    rfrg.p1_exclusion2_id, rfrg.p1_exclusion2_display_id,
                    rfrg.p1_exclusion2_type, rfrg.p1_e2_start_ind,
                    rfrg.promotion2_id, rfrg.promo2_display_id,
                    rfrg.p2_start_date, rfrg.p2_rank, rfrg.p2_secondary_ind,
                    rfrg.p2_component1_id, rfrg.p2_comp1_display_id,
                    rfrg.p2_c1_detail_id, rfrg.p2_c1_type, rfrg.p2_c1_rank,
                    rfrg.p2_c1_secondary_ind, rfrg.p2_c1_start_date,
                    rfrg.p2_c1_start_ind, rfrg.p2_c1_apply_to_code,
                    rfrg.p2_c1_change_type, rfrg.p2_c1_change_amount,
                    rfrg.p2_c1_change_currency, rfrg.p2_c1_change_percent,
                    rfrg.p2_c1_change_selling_uom, rfrg.p2_c1_price_guide_id,
                    rfrg.p2_component2_id, rfrg.p2_comp2_display_id,
                    rfrg.p2_c2_detail_id, rfrg.p2_c2_type, rfrg.p2_c2_rank,
                    rfrg.p2_c2_secondary_ind, rfrg.p2_c2_start_date,
                    rfrg.p2_c2_start_ind, rfrg.p2_c2_apply_to_code,
                    rfrg.p2_c2_change_type, rfrg.p2_c2_change_amount,
                    rfrg.p2_c2_change_currency, rfrg.p2_c2_change_percent,
                    rfrg.p2_c2_change_selling_uom, rfrg.p2_c2_price_guide_id,
                    rfrg.p2_exclusion1_id, rfrg.p2_exclusion1_display_id,
                    rfrg.p2_exclusion1_type, rfrg.p2_e1_start_ind,
                    rfrg.p2_exclusion2_id, rfrg.p2_exclusion2_display_id,
                    rfrg.p2_exclusion2_type, rfrg.p2_e2_start_ind,
                    rfrg.loc_move_from_zone_id, rfrg.loc_move_to_zone_id,
                    rfrg.location_move_id);

      DELETE FROM rpm_future_retail rfr
            WHERE rfr.ROWID IN (SELECT rfrg.rfr_rowid
                                  FROM rpm_future_retail_gtt rfrg
                                 WHERE rfrg.timeline_seq = -999);

      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END tsl_push_back;

-- Mod N25 Vikash Prasad 25-May-2009 END
--19-Apr-2010 BC_KC  NBS00017378      performances fix End
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Added for prd defect fix NBS00015345 by Debadatta on 17-NOV-2009 Begin
------------------------------------------------------------------------------------------------
-- Function Name : TSL_PUSH_BACK_REMOVE
-- Purpose       : This function is used to update the RPM_FUTURE_RETAIL table for cancelling or
--                 deleting any promotion component for clearing all promotion related details.
------------------------------------------------------------------------------------------------
--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
   FUNCTION tsl_push_back_remove (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      l_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program        VARCHAR2 (100)
                              := 'RPM_FUTURE_RETAIL_SQL.TSL_PUSH_BACK_REMOVE';
--
      l_active_state   VARCHAR2 (50)  := 'notactive';

      CURSOR c_active_promo
      IS
         SELECT DISTINCT state
                    FROM rpm_promo_comp_detail
                   WHERE rpm_promo_comp_detail_id IN (
                            SELECT VALUE (ID)
                              FROM TABLE
                                      (CAST
                                          (NVL (l_price_event_ids,
                                                obj_numeric_id_table (0)
                                               ) AS obj_numeric_id_table
                                          )
                                      ) ID);
--Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
   BEGIN
      IF i_price_event_type IN
            (rpm_conflict_library.simple_promotion,
             rpm_conflict_library.simple_update,
             rpm_conflict_library.threshold_promotion,
             rpm_conflict_library.threshold_update,
             rpm_conflict_library.multibuy_promotion,
             rpm_conflict_library.multibuy_update
            )
      THEN
         FOR v_rec IN c_active_promo
         LOOP
            IF v_rec.state = 'pcd.active'
            THEN
               l_active_state := v_rec.state;
               EXIT;
            END IF;
         END LOOP;
      END IF;

      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
      --
      /* BC 20/10/2009 added below hint may need to revisit under full volumes - NBS000015287*/
      MERGE                         /*+ rowid(rfr) */ INTO rpm_future_retail rfr
         USING (SELECT /*+ full(rfrg) */
                       *
                  FROM rpm_future_retail_gtt) rfrg
         ON (rfr.ROWID = rfrg.rfr_rowid)
         WHEN MATCHED THEN
            UPDATE
               SET rfr.selling_retail = rfrg.selling_retail,
                   rfr.selling_retail_currency = rfrg.selling_retail_currency,
                   rfr.selling_uom = rfrg.selling_uom,
                   rfr.multi_units = rfrg.multi_units,
                   rfr.multi_unit_retail = rfrg.multi_unit_retail,
                   rfr.multi_unit_retail_currency =
                                               rfrg.multi_unit_retail_currency,
                   rfr.multi_selling_uom = rfrg.multi_selling_uom,
                   rfr.clear_retail = rfrg.clear_retail,
                   rfr.clear_retail_currency = rfrg.clear_retail_currency,
                   rfr.clear_uom = rfrg.clear_uom,
                   rfr.simple_promo_retail = rfrg.simple_promo_retail,
                   rfr.simple_promo_retail_currency =
                                             rfrg.simple_promo_retail_currency,
                   rfr.simple_promo_uom = rfrg.simple_promo_uom,
                   rfr.complex_promo_retail = rfrg.complex_promo_retail,
                   rfr.complex_promo_retail_currency =
                                            rfrg.complex_promo_retail_currency,
                   rfr.complex_promo_uom = rfrg.complex_promo_uom,
                   rfr.price_change_id = rfrg.price_change_id,
                   rfr.price_change_display_id = rfrg.price_change_display_id,
                   rfr.pc_exception_parent_id = rfrg.pc_exception_parent_id,
                   rfr.pc_change_type = rfrg.pc_change_type,
                   rfr.pc_change_amount = rfrg.pc_change_amount,
                   rfr.pc_change_currency = rfrg.pc_change_currency,
                   rfr.pc_change_percent = rfrg.pc_change_percent,
                   rfr.pc_change_selling_uom = rfrg.pc_change_selling_uom,
                   rfr.pc_null_multi_ind = rfrg.pc_null_multi_ind,
                   rfr.pc_multi_units = rfrg.pc_multi_units,
                   rfr.pc_multi_unit_retail = rfrg.pc_multi_unit_retail,
                   rfr.pc_multi_unit_retail_currency =
                                            rfrg.pc_multi_unit_retail_currency,
                   rfr.pc_multi_selling_uom = rfrg.pc_multi_selling_uom,
                   rfr.pc_price_guide_id = rfrg.pc_price_guide_id,
                   rfr.clearance_id = rfrg.clearance_id,
                   rfr.clearance_display_id = rfrg.clearance_display_id,
                   rfr.clear_mkdn_index = rfrg.clear_mkdn_index,
                   rfr.clear_start_ind = rfrg.clear_start_ind,
                   rfr.clear_change_type = rfrg.clear_change_type,
                   rfr.clear_change_amount = rfrg.clear_change_amount,
                   rfr.clear_change_currency = rfrg.clear_change_currency,
                   rfr.clear_change_percent = rfrg.clear_change_percent,
                   rfr.clear_change_selling_uom =
                                                 rfrg.clear_change_selling_uom,
                   rfr.clear_price_guide_id = rfrg.clear_price_guide_id,
                   rfr.promotion1_id = rfrg.promotion1_id,
                   rfr.promo1_display_id = rfrg.promo1_display_id,
                   rfr.p1_start_date = rfrg.p1_start_date,
                   rfr.p1_rank = rfrg.p1_rank,
                   rfr.p1_secondary_ind = rfrg.p1_secondary_ind,
                   rfr.p1_component1_id = rfrg.p1_component1_id,
                   rfr.p1_comp1_display_id = rfrg.p1_comp1_display_id,
                   rfr.p1_c1_detail_id = rfrg.p1_c1_detail_id,
                   rfr.p1_c1_type = rfrg.p1_c1_type,
                   rfr.p1_c1_rank = rfrg.p1_c1_rank,
                   rfr.p1_c1_secondary_ind = rfrg.p1_c1_secondary_ind,
                   rfr.p1_c1_start_date = rfrg.p1_c1_start_date,
                   rfr.p1_c1_start_ind = rfrg.p1_c1_start_ind,
                   rfr.p1_c1_apply_to_code = rfrg.p1_c1_apply_to_code,
                   rfr.p1_c1_change_type = rfrg.p1_c1_change_type,
                   rfr.p1_c1_change_amount = rfrg.p1_c1_change_amount,
                   rfr.p1_c1_change_currency = rfrg.p1_c1_change_currency,
                   rfr.p1_c1_change_percent = rfrg.p1_c1_change_percent,
                   rfr.p1_c1_change_selling_uom =
                                                 rfrg.p1_c1_change_selling_uom,
                   rfr.p1_c1_price_guide_id = rfrg.p1_c1_price_guide_id,
                   rfr.p1_component2_id = rfrg.p1_component2_id,
                   rfr.p1_comp2_display_id = rfrg.p1_comp2_display_id,
                   rfr.p1_c2_detail_id = rfrg.p1_c2_detail_id,
                   rfr.p1_c2_type = rfrg.p1_c2_type,
                   rfr.p1_c2_rank = rfrg.p1_c2_rank,
                   rfr.p1_c2_secondary_ind = rfrg.p1_c2_secondary_ind,
                   rfr.p1_c2_start_date = rfrg.p1_c2_start_date,
                   rfr.p1_c2_start_ind = rfrg.p1_c2_start_ind,
                   rfr.p1_c2_apply_to_code = rfrg.p1_c2_apply_to_code,
                   rfr.p1_c2_change_type = rfrg.p1_c2_change_type,
                   rfr.p1_c2_change_amount = rfrg.p1_c2_change_amount,
                   rfr.p1_c2_change_currency = rfrg.p1_c2_change_currency,
                   rfr.p1_c2_change_percent = rfrg.p1_c2_change_percent,
                   rfr.p1_c2_change_selling_uom =
                                                 rfrg.p1_c2_change_selling_uom,
                   rfr.p1_c2_price_guide_id = rfrg.p1_c2_price_guide_id,
                   rfr.p1_exclusion1_id = rfrg.p1_exclusion1_id,
                   rfr.p1_exclusion1_display_id =
                                                 rfrg.p1_exclusion1_display_id,
                   rfr.p1_exclusion1_type = rfrg.p1_exclusion1_type,
                   rfr.p1_e1_start_ind = rfrg.p1_e1_start_ind,
                   rfr.p1_exclusion2_id = rfrg.p1_exclusion2_id,
                   rfr.p1_exclusion2_display_id =
                                                 rfrg.p1_exclusion2_display_id,
                   rfr.p1_exclusion2_type = rfrg.p1_exclusion2_type,
                   rfr.p1_e2_start_ind = rfrg.p1_e2_start_ind,
                   rfr.promotion2_id = rfrg.promotion2_id,
                   rfr.promo2_display_id = rfrg.promo2_display_id,
                   rfr.p2_start_date = rfrg.p2_start_date,
                   rfr.p2_rank = rfrg.p2_rank,
                   rfr.p2_secondary_ind = rfrg.p2_secondary_ind,
                   rfr.p2_component1_id = rfrg.p2_component1_id,
                   rfr.p2_comp1_display_id = rfrg.p2_comp1_display_id,
                   rfr.p2_c1_detail_id = rfrg.p2_c1_detail_id,
                   rfr.p2_c1_type = rfrg.p2_c1_type,
                   rfr.p2_c1_rank = rfrg.p2_c1_rank,
                   rfr.p2_c1_secondary_ind = rfrg.p2_c1_secondary_ind,
                   rfr.p2_c1_start_date = rfrg.p2_c1_start_date,
                   rfr.p2_c1_start_ind = rfrg.p2_c1_start_ind,
                   rfr.p2_c1_apply_to_code = rfrg.p2_c1_apply_to_code,
                   rfr.p2_c1_change_type = rfrg.p2_c1_change_type,
                   rfr.p2_c1_change_amount = rfrg.p2_c1_change_amount,
                   rfr.p2_c1_change_currency = rfrg.p2_c1_change_currency,
                   rfr.p2_c1_change_percent = rfrg.p2_c1_change_percent,
                   rfr.p2_c1_change_selling_uom =
                                                 rfrg.p2_c1_change_selling_uom,
                   rfr.p2_c1_price_guide_id = rfrg.p2_c1_price_guide_id,
                   rfr.p2_component2_id = rfrg.p2_component2_id,
                   rfr.p2_comp2_display_id = rfrg.p2_comp2_display_id,
                   rfr.p2_c2_detail_id = rfrg.p2_c2_detail_id,
                   rfr.p2_c2_type = rfrg.p2_c2_type,
                   rfr.p2_c2_rank = rfrg.p2_c2_rank,
                   rfr.p2_c2_secondary_ind = rfrg.p2_c2_secondary_ind,
                   rfr.p2_c2_start_date = rfrg.p2_c2_start_date,
                   rfr.p2_c2_start_ind = rfrg.p2_c2_start_ind,
                   rfr.p2_c2_apply_to_code = rfrg.p2_c2_apply_to_code,
                   rfr.p2_c2_change_type = rfrg.p2_c2_change_type,
                   rfr.p2_c2_change_amount = rfrg.p2_c2_change_amount,
                   rfr.p2_c2_change_currency = rfrg.p2_c2_change_currency,
                   rfr.p2_c2_change_percent = rfrg.p2_c2_change_percent,
                   rfr.p2_c2_change_selling_uom =
                                                 rfrg.p2_c2_change_selling_uom,
                   rfr.p2_c2_price_guide_id = rfrg.p2_c2_price_guide_id,
                   rfr.p2_exclusion1_id = rfrg.p2_exclusion1_id,
                   rfr.p2_exclusion1_display_id =
                                                 rfrg.p2_exclusion1_display_id,
                   rfr.p2_exclusion1_type = rfrg.p2_exclusion1_type,
                   rfr.p2_e1_start_ind = rfrg.p2_e1_start_ind,
                   rfr.p2_exclusion2_id = rfrg.p2_exclusion2_id,
                   rfr.p2_exclusion2_display_id =
                                                 rfrg.p2_exclusion2_display_id,
                   rfr.p2_exclusion2_type = rfrg.p2_exclusion2_type,
                   rfr.p2_e2_start_ind = rfrg.p2_e2_start_ind,
                   rfr.loc_move_from_zone_id = rfrg.loc_move_from_zone_id,
                   rfr.loc_move_to_zone_id = rfrg.loc_move_to_zone_id,
                   rfr.location_move_id = rfrg.location_move_id
         WHEN NOT MATCHED THEN
            INSERT (future_retail_id, dept, CLASS, subclass, item,
                    zone_node_type, LOCATION, action_date, selling_retail,
                    selling_retail_currency, selling_uom, multi_units,
                    multi_unit_retail, multi_unit_retail_currency,
                    multi_selling_uom, clear_retail, clear_retail_currency,
                    clear_uom, simple_promo_retail,
                    simple_promo_retail_currency, simple_promo_uom,
                    complex_promo_retail, complex_promo_retail_currency,
                    complex_promo_uom, price_change_id,
                    price_change_display_id, pc_exception_parent_id,
                    pc_change_type, pc_change_amount, pc_change_currency,
                    pc_change_percent, pc_change_selling_uom,
                    pc_null_multi_ind, pc_multi_units, pc_multi_unit_retail,
                    pc_multi_unit_retail_currency, pc_multi_selling_uom,
                    pc_price_guide_id, clearance_id, clearance_display_id,
                    clear_mkdn_index, clear_start_ind, clear_change_type,
                    clear_change_amount, clear_change_currency,
                    clear_change_percent, clear_change_selling_uom,
                    clear_price_guide_id, promotion1_id, promo1_display_id,
                    p1_start_date, p1_rank, p1_secondary_ind,
                    p1_component1_id, p1_comp1_display_id, p1_c1_detail_id,
                    p1_c1_type, p1_c1_rank, p1_c1_secondary_ind,
                    p1_c1_start_date, p1_c1_start_ind, p1_c1_apply_to_code,
                    p1_c1_change_type, p1_c1_change_amount,
                    p1_c1_change_currency, p1_c1_change_percent,
                    p1_c1_change_selling_uom, p1_c1_price_guide_id,
                    p1_component2_id, p1_comp2_display_id, p1_c2_detail_id,
                    p1_c2_type, p1_c2_rank, p1_c2_secondary_ind,
                    p1_c2_start_date, p1_c2_start_ind, p1_c2_apply_to_code,
                    p1_c2_change_type, p1_c2_change_amount,
                    p1_c2_change_currency, p1_c2_change_percent,
                    p1_c2_change_selling_uom, p1_c2_price_guide_id,
                    p1_exclusion1_id, p1_exclusion1_display_id,
                    p1_exclusion1_type, p1_e1_start_ind, p1_exclusion2_id,
                    p1_exclusion2_display_id, p1_exclusion2_type,
                    p1_e2_start_ind, promotion2_id, promo2_display_id,
                    p2_start_date, p2_rank, p2_secondary_ind,
                    p2_component1_id, p2_comp1_display_id, p2_c1_detail_id,
                    p2_c1_type, p2_c1_rank, p2_c1_secondary_ind,
                    p2_c1_start_date, p2_c1_start_ind, p2_c1_apply_to_code,
                    p2_c1_change_type, p2_c1_change_amount,
                    p2_c1_change_currency, p2_c1_change_percent,
                    p2_c1_change_selling_uom, p2_c1_price_guide_id,
                    p2_component2_id, p2_comp2_display_id, p2_c2_detail_id,
                    p2_c2_type, p2_c2_rank, p2_c2_secondary_ind,
                    p2_c2_start_date, p2_c2_start_ind, p2_c2_apply_to_code,
                    p2_c2_change_type, p2_c2_change_amount,
                    p2_c2_change_currency, p2_c2_change_percent,
                    p2_c2_change_selling_uom, p2_c2_price_guide_id,
                    p2_exclusion1_id, p2_exclusion1_display_id,
                    p2_exclusion1_type, p2_e1_start_ind, p2_exclusion2_id,
                    p2_exclusion2_display_id, p2_exclusion2_type,
                    p2_e2_start_ind, loc_move_from_zone_id,
                    loc_move_to_zone_id, location_move_id)
            VALUES (rfrg.future_retail_id, rfrg.dept, rfrg.CLASS,
                    rfrg.subclass, rfrg.item, rfrg.zone_node_type,
                    rfrg.LOCATION, rfrg.action_date, rfrg.selling_retail,
                    rfrg.selling_retail_currency, rfrg.selling_uom,
                    rfrg.multi_units, rfrg.multi_unit_retail,
                    rfrg.multi_unit_retail_currency, rfrg.multi_selling_uom,
                    rfrg.clear_retail, rfrg.clear_retail_currency,
                    rfrg.clear_uom, rfrg.simple_promo_retail,
                    rfrg.simple_promo_retail_currency, rfrg.simple_promo_uom,
                    rfrg.complex_promo_retail,
                    rfrg.complex_promo_retail_currency,
                    rfrg.complex_promo_uom, rfrg.price_change_id,
                    rfrg.price_change_display_id, rfrg.pc_exception_parent_id,
                    rfrg.pc_change_type, rfrg.pc_change_amount,
                    rfrg.pc_change_currency, rfrg.pc_change_percent,
                    rfrg.pc_change_selling_uom, rfrg.pc_null_multi_ind,
                    rfrg.pc_multi_units, rfrg.pc_multi_unit_retail,
                    rfrg.pc_multi_unit_retail_currency,
                    rfrg.pc_multi_selling_uom, rfrg.pc_price_guide_id,
                    rfrg.clearance_id, rfrg.clearance_display_id,
                    rfrg.clear_mkdn_index, rfrg.clear_start_ind,
                    rfrg.clear_change_type, rfrg.clear_change_amount,
                    rfrg.clear_change_currency, rfrg.clear_change_percent,
                    rfrg.clear_change_selling_uom, rfrg.clear_price_guide_id,
                    rfrg.promotion1_id, rfrg.promo1_display_id,
                    rfrg.p1_start_date, rfrg.p1_rank, rfrg.p1_secondary_ind,
                    rfrg.p1_component1_id, rfrg.p1_comp1_display_id,
                    rfrg.p1_c1_detail_id, rfrg.p1_c1_type, rfrg.p1_c1_rank,
                    rfrg.p1_c1_secondary_ind, rfrg.p1_c1_start_date,
                    rfrg.p1_c1_start_ind, rfrg.p1_c1_apply_to_code,
                    rfrg.p1_c1_change_type, rfrg.p1_c1_change_amount,
                    rfrg.p1_c1_change_currency, rfrg.p1_c1_change_percent,
                    rfrg.p1_c1_change_selling_uom, rfrg.p1_c1_price_guide_id,
                    rfrg.p1_component2_id, rfrg.p1_comp2_display_id,
                    rfrg.p1_c2_detail_id, rfrg.p1_c2_type, rfrg.p1_c2_rank,
                    rfrg.p1_c2_secondary_ind, rfrg.p1_c2_start_date,
                    rfrg.p1_c2_start_ind, rfrg.p1_c2_apply_to_code,
                    rfrg.p1_c2_change_type, rfrg.p1_c2_change_amount,
                    rfrg.p1_c2_change_currency, rfrg.p1_c2_change_percent,
                    rfrg.p1_c2_change_selling_uom, rfrg.p1_c2_price_guide_id,
                    rfrg.p1_exclusion1_id, rfrg.p1_exclusion1_display_id,
                    rfrg.p1_exclusion1_type, rfrg.p1_e1_start_ind,
                    rfrg.p1_exclusion2_id, rfrg.p1_exclusion2_display_id,
                    rfrg.p1_exclusion2_type, rfrg.p1_e2_start_ind,
                    rfrg.promotion2_id, rfrg.promo2_display_id,
                    rfrg.p2_start_date, rfrg.p2_rank, rfrg.p2_secondary_ind,
                    rfrg.p2_component1_id, rfrg.p2_comp1_display_id,
                    rfrg.p2_c1_detail_id, rfrg.p2_c1_type, rfrg.p2_c1_rank,
                    rfrg.p2_c1_secondary_ind, rfrg.p2_c1_start_date,
                    rfrg.p2_c1_start_ind, rfrg.p2_c1_apply_to_code,
                    rfrg.p2_c1_change_type, rfrg.p2_c1_change_amount,
                    rfrg.p2_c1_change_currency, rfrg.p2_c1_change_percent,
                    rfrg.p2_c1_change_selling_uom, rfrg.p2_c1_price_guide_id,
                    rfrg.p2_component2_id, rfrg.p2_comp2_display_id,
                    rfrg.p2_c2_detail_id, rfrg.p2_c2_type, rfrg.p2_c2_rank,
                    rfrg.p2_c2_secondary_ind, rfrg.p2_c2_start_date,
                    rfrg.p2_c2_start_ind, rfrg.p2_c2_apply_to_code,
                    rfrg.p2_c2_change_type, rfrg.p2_c2_change_amount,
                    rfrg.p2_c2_change_currency, rfrg.p2_c2_change_percent,
                    rfrg.p2_c2_change_selling_uom, rfrg.p2_c2_price_guide_id,
                    rfrg.p2_exclusion1_id, rfrg.p2_exclusion1_display_id,
                    rfrg.p2_exclusion1_type, rfrg.p2_e1_start_ind,
                    rfrg.p2_exclusion2_id, rfrg.p2_exclusion2_display_id,
                    rfrg.p2_exclusion2_type, rfrg.p2_e2_start_ind,
                    rfrg.loc_move_from_zone_id, rfrg.loc_move_to_zone_id,
                    rfrg.location_move_id);

      --

      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
      IF (l_active_state != 'pcd.active')
      THEN
         DELETE FROM rpm_future_retail rfr
               WHERE rfr.ROWID IN (SELECT rfrg.rfr_rowid
                                     FROM rpm_future_retail_gtt rfrg
                                    WHERE rfrg.timeline_seq = -999);
      END IF;

      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END tsl_push_back_remove;

------------------------------------------------------------------------------------------------
-- Function Name : TSL_ZONE_PUSH_BACK_REMOVE
-- Purpose       : This function is used to update the RPM_FUTURE_RETAIL table for cancelling or
--                 deleting any promotion component for clearing all promotion related details.
------------------------------------------------------------------------------------------------

   --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
   FUNCTION tsl_zone_push_back_remove (
      o_cc_error_tbl       OUT      conflict_check_error_tbl,
      l_price_event_ids    IN       obj_numeric_id_table,
      i_price_event_type   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      l_program        VARCHAR2 (100)
                         := 'RPM_FUTURE_RETAIL_SQL.TSL_ZONE_PUSH_BACK_REMOVE';
--
      l_active_state   VARCHAR2 (50)  := 'notactive';

      CURSOR c_active_promo
      IS
         SELECT DISTINCT state
                    FROM rpm_promo_comp_detail
                   WHERE rpm_promo_comp_detail_id IN (
                            SELECT VALUE (ID)
                              FROM TABLE
                                      (CAST
                                          (NVL (l_price_event_ids,
                                                obj_numeric_id_table (0)
                                               ) AS obj_numeric_id_table
                                          )
                                      ) ID);
   BEGIN
      --
      IF i_price_event_type IN
            (rpm_conflict_library.simple_promotion,
             rpm_conflict_library.simple_update,
             rpm_conflict_library.threshold_promotion,
             rpm_conflict_library.threshold_update,
             rpm_conflict_library.multibuy_promotion,
             rpm_conflict_library.multibuy_update
            )
      THEN
         FOR v_rec IN c_active_promo
         LOOP
            IF v_rec.state = 'pcd.active'
            THEN
               l_active_state := v_rec.state;
               EXIT;
            END IF;
         END LOOP;
      END IF;

      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
      MERGE INTO tsl_rpm_pro_zone_fut_ret rfr
         USING (SELECT *
                  FROM rpm_future_retail_gtt
                 WHERE LOCATION IN (SELECT zone_id
                                      FROM rpm_zone rz) AND zone_node_type = 1) rfrg
         ON (rfr.ROWID = rfrg.rfr_rowid)
         WHEN MATCHED THEN
            UPDATE
               SET rfr.selling_retail = rfrg.selling_retail,
                   rfr.selling_retail_currency = rfrg.selling_retail_currency,
                   rfr.selling_uom = rfrg.selling_uom,
                   rfr.multi_units = rfrg.multi_units,
                   rfr.multi_unit_retail = rfrg.multi_unit_retail,
                   rfr.multi_unit_retail_currency =
                                               rfrg.multi_unit_retail_currency,
                   rfr.multi_selling_uom = rfrg.multi_selling_uom,
                   rfr.clear_retail = rfrg.clear_retail,
                   rfr.clear_retail_currency = rfrg.clear_retail_currency,
                   rfr.clear_uom = rfrg.clear_uom,
                   rfr.simple_promo_retail = rfrg.simple_promo_retail,
                   rfr.simple_promo_retail_currency =
                                             rfrg.simple_promo_retail_currency,
                   rfr.simple_promo_uom = rfrg.simple_promo_uom,
                   rfr.complex_promo_retail = rfrg.complex_promo_retail,
                   rfr.complex_promo_retail_currency =
                                            rfrg.complex_promo_retail_currency,
                   rfr.complex_promo_uom = rfrg.complex_promo_uom,
                   rfr.price_change_id = rfrg.price_change_id,
                   rfr.price_change_display_id = rfrg.price_change_display_id,
                   rfr.pc_exception_parent_id = rfrg.pc_exception_parent_id,
                   rfr.pc_change_type = rfrg.pc_change_type,
                   rfr.pc_change_amount = rfrg.pc_change_amount,
                   rfr.pc_change_currency = rfrg.pc_change_currency,
                   rfr.pc_change_percent = rfrg.pc_change_percent,
                   rfr.pc_change_selling_uom = rfrg.pc_change_selling_uom,
                   rfr.pc_null_multi_ind = rfrg.pc_null_multi_ind,
                   rfr.pc_multi_units = rfrg.pc_multi_units,
                   rfr.pc_multi_unit_retail = rfrg.pc_multi_unit_retail,
                   rfr.pc_multi_unit_retail_currency =
                                            rfrg.pc_multi_unit_retail_currency,
                   rfr.pc_multi_selling_uom = rfrg.pc_multi_selling_uom,
                   rfr.pc_price_guide_id = rfrg.pc_price_guide_id,
                   rfr.clearance_id = rfrg.clearance_id,
                   rfr.clearance_display_id = rfrg.clearance_display_id,
                   rfr.clear_mkdn_index = rfrg.clear_mkdn_index,
                   rfr.clear_start_ind = rfrg.clear_start_ind,
                   rfr.clear_change_type = rfrg.clear_change_type,
                   rfr.clear_change_amount = rfrg.clear_change_amount,
                   rfr.clear_change_currency = rfrg.clear_change_currency,
                   rfr.clear_change_percent = rfrg.clear_change_percent,
                   rfr.clear_change_selling_uom =
                                                 rfrg.clear_change_selling_uom,
                   rfr.clear_price_guide_id = rfrg.clear_price_guide_id,
                   rfr.promotion1_id = rfrg.promotion1_id,
                   rfr.promo1_display_id = rfrg.promo1_display_id,
                   rfr.p1_start_date = rfrg.p1_start_date,
                   rfr.p1_rank = rfrg.p1_rank,
                   rfr.p1_secondary_ind = rfrg.p1_secondary_ind,
                   rfr.p1_component1_id = rfrg.p1_component1_id,
                   rfr.p1_comp1_display_id = rfrg.p1_comp1_display_id,
                   rfr.p1_c1_detail_id = rfrg.p1_c1_detail_id,
                   rfr.p1_c1_type = rfrg.p1_c1_type,
                   rfr.p1_c1_rank = rfrg.p1_c1_rank,
                   rfr.p1_c1_secondary_ind = rfrg.p1_c1_secondary_ind,
                   rfr.p1_c1_start_date = rfrg.p1_c1_start_date,
                   rfr.p1_c1_start_ind = rfrg.p1_c1_start_ind,
                   rfr.p1_c1_apply_to_code = rfrg.p1_c1_apply_to_code,
                   rfr.p1_c1_change_type = rfrg.p1_c1_change_type,
                   rfr.p1_c1_change_amount = rfrg.p1_c1_change_amount,
                   rfr.p1_c1_change_currency = rfrg.p1_c1_change_currency,
                   rfr.p1_c1_change_percent = rfrg.p1_c1_change_percent,
                   rfr.p1_c1_change_selling_uom =
                                                 rfrg.p1_c1_change_selling_uom,
                   rfr.p1_c1_price_guide_id = rfrg.p1_c1_price_guide_id,
                   rfr.p1_component2_id = rfrg.p1_component2_id,
                   rfr.p1_comp2_display_id = rfrg.p1_comp2_display_id,
                   rfr.p1_c2_detail_id = rfrg.p1_c2_detail_id,
                   rfr.p1_c2_type = rfrg.p1_c2_type,
                   rfr.p1_c2_rank = rfrg.p1_c2_rank,
                   rfr.p1_c2_secondary_ind = rfrg.p1_c2_secondary_ind,
                   rfr.p1_c2_start_date = rfrg.p1_c2_start_date,
                   rfr.p1_c2_start_ind = rfrg.p1_c2_start_ind,
                   rfr.p1_c2_apply_to_code = rfrg.p1_c2_apply_to_code,
                   rfr.p1_c2_change_type = rfrg.p1_c2_change_type,
                   rfr.p1_c2_change_amount = rfrg.p1_c2_change_amount,
                   rfr.p1_c2_change_currency = rfrg.p1_c2_change_currency,
                   rfr.p1_c2_change_percent = rfrg.p1_c2_change_percent,
                   rfr.p1_c2_change_selling_uom =
                                                 rfrg.p1_c2_change_selling_uom,
                   rfr.p1_c2_price_guide_id = rfrg.p1_c2_price_guide_id,
                   rfr.p1_exclusion1_id = rfrg.p1_exclusion1_id,
                   rfr.p1_exclusion1_display_id =
                                                 rfrg.p1_exclusion1_display_id,
                   rfr.p1_exclusion1_type = rfrg.p1_exclusion1_type,
                   rfr.p1_e1_start_ind = rfrg.p1_e1_start_ind,
                   rfr.p1_exclusion2_id = rfrg.p1_exclusion2_id,
                   rfr.p1_exclusion2_display_id =
                                                 rfrg.p1_exclusion2_display_id,
                   rfr.p1_exclusion2_type = rfrg.p1_exclusion2_type,
                   rfr.p1_e2_start_ind = rfrg.p1_e2_start_ind,
                   rfr.promotion2_id = rfrg.promotion2_id,
                   rfr.promo2_display_id = rfrg.promo2_display_id,
                   rfr.p2_start_date = rfrg.p2_start_date,
                   rfr.p2_rank = rfrg.p2_rank,
                   rfr.p2_secondary_ind = rfrg.p2_secondary_ind,
                   rfr.p2_component1_id = rfrg.p2_component1_id,
                   rfr.p2_comp1_display_id = rfrg.p2_comp1_display_id,
                   rfr.p2_c1_detail_id = rfrg.p2_c1_detail_id,
                   rfr.p2_c1_type = rfrg.p2_c1_type,
                   rfr.p2_c1_rank = rfrg.p2_c1_rank,
                   rfr.p2_c1_secondary_ind = rfrg.p2_c1_secondary_ind,
                   rfr.p2_c1_start_date = rfrg.p2_c1_start_date,
                   rfr.p2_c1_start_ind = rfrg.p2_c1_start_ind,
                   rfr.p2_c1_apply_to_code = rfrg.p2_c1_apply_to_code,
                   rfr.p2_c1_change_type = rfrg.p2_c1_change_type,
                   rfr.p2_c1_change_amount = rfrg.p2_c1_change_amount,
                   rfr.p2_c1_change_currency = rfrg.p2_c1_change_currency,
                   rfr.p2_c1_change_percent = rfrg.p2_c1_change_percent,
                   rfr.p2_c1_change_selling_uom =
                                                 rfrg.p2_c1_change_selling_uom,
                   rfr.p2_c1_price_guide_id = rfrg.p2_c1_price_guide_id,
                   rfr.p2_component2_id = rfrg.p2_component2_id,
                   rfr.p2_comp2_display_id = rfrg.p2_comp2_display_id,
                   rfr.p2_c2_detail_id = rfrg.p2_c2_detail_id,
                   rfr.p2_c2_type = rfrg.p2_c2_type,
                   rfr.p2_c2_rank = rfrg.p2_c2_rank,
                   rfr.p2_c2_secondary_ind = rfrg.p2_c2_secondary_ind,
                   rfr.p2_c2_start_date = rfrg.p2_c2_start_date,
                   rfr.p2_c2_start_ind = rfrg.p2_c2_start_ind,
                   rfr.p2_c2_apply_to_code = rfrg.p2_c2_apply_to_code,
                   rfr.p2_c2_change_type = rfrg.p2_c2_change_type,
                   rfr.p2_c2_change_amount = rfrg.p2_c2_change_amount,
                   rfr.p2_c2_change_currency = rfrg.p2_c2_change_currency,
                   rfr.p2_c2_change_percent = rfrg.p2_c2_change_percent,
                   rfr.p2_c2_change_selling_uom =
                                                 rfrg.p2_c2_change_selling_uom,
                   rfr.p2_c2_price_guide_id = rfrg.p2_c2_price_guide_id,
                   rfr.p2_exclusion1_id = rfrg.p2_exclusion1_id,
                   rfr.p2_exclusion1_display_id =
                                                 rfrg.p2_exclusion1_display_id,
                   rfr.p2_exclusion1_type = rfrg.p2_exclusion1_type,
                   rfr.p2_e1_start_ind = rfrg.p2_e1_start_ind,
                   rfr.p2_exclusion2_id = rfrg.p2_exclusion2_id,
                   rfr.p2_exclusion2_display_id =
                                                 rfrg.p2_exclusion2_display_id,
                   rfr.p2_exclusion2_type = rfrg.p2_exclusion2_type,
                   rfr.p2_e2_start_ind = rfrg.p2_e2_start_ind,
                   rfr.loc_move_from_zone_id = rfrg.loc_move_from_zone_id,
                   rfr.loc_move_to_zone_id = rfrg.loc_move_to_zone_id,
                   rfr.location_move_id = rfrg.location_move_id
         WHEN NOT MATCHED THEN
            INSERT (pro_zone_fut_ret_id, dept, CLASS, subclass, item,
                    zone_node_type, LOCATION, action_date, selling_retail,
                    selling_retail_currency, selling_uom, multi_units,
                    multi_unit_retail, multi_unit_retail_currency,
                    multi_selling_uom, clear_retail, clear_retail_currency,
                    clear_uom, simple_promo_retail,
                    simple_promo_retail_currency, simple_promo_uom,
                    complex_promo_retail, complex_promo_retail_currency,
                    complex_promo_uom, price_change_id,
                    price_change_display_id, pc_exception_parent_id,
                    pc_change_type, pc_change_amount, pc_change_currency,
                    pc_change_percent, pc_change_selling_uom,
                    pc_null_multi_ind, pc_multi_units, pc_multi_unit_retail,
                    pc_multi_unit_retail_currency, pc_multi_selling_uom,
                    pc_price_guide_id, clearance_id, clearance_display_id,
                    clear_mkdn_index, clear_start_ind, clear_change_type,
                    clear_change_amount, clear_change_currency,
                    clear_change_percent, clear_change_selling_uom,
                    clear_price_guide_id, promotion1_id, promo1_display_id,
                    p1_start_date, p1_rank, p1_secondary_ind,
                    p1_component1_id, p1_comp1_display_id, p1_c1_detail_id,
                    p1_c1_type, p1_c1_rank, p1_c1_secondary_ind,
                    p1_c1_start_date, p1_c1_start_ind, p1_c1_apply_to_code,
                    p1_c1_change_type, p1_c1_change_amount,
                    p1_c1_change_currency, p1_c1_change_percent,
                    p1_c1_change_selling_uom, p1_c1_price_guide_id,
                    p1_component2_id, p1_comp2_display_id, p1_c2_detail_id,
                    p1_c2_type, p1_c2_rank, p1_c2_secondary_ind,
                    p1_c2_start_date, p1_c2_start_ind, p1_c2_apply_to_code,
                    p1_c2_change_type, p1_c2_change_amount,
                    p1_c2_change_currency, p1_c2_change_percent,
                    p1_c2_change_selling_uom, p1_c2_price_guide_id,
                    p1_exclusion1_id, p1_exclusion1_display_id,
                    p1_exclusion1_type, p1_e1_start_ind, p1_exclusion2_id,
                    p1_exclusion2_display_id, p1_exclusion2_type,
                    p1_e2_start_ind, promotion2_id, promo2_display_id,
                    p2_start_date, p2_rank, p2_secondary_ind,
                    p2_component1_id, p2_comp1_display_id, p2_c1_detail_id,
                    p2_c1_type, p2_c1_rank, p2_c1_secondary_ind,
                    p2_c1_start_date, p2_c1_start_ind, p2_c1_apply_to_code,
                    p2_c1_change_type, p2_c1_change_amount,
                    p2_c1_change_currency, p2_c1_change_percent,
                    p2_c1_change_selling_uom, p2_c1_price_guide_id,
                    p2_component2_id, p2_comp2_display_id, p2_c2_detail_id,
                    p2_c2_type, p2_c2_rank, p2_c2_secondary_ind,
                    p2_c2_start_date, p2_c2_start_ind, p2_c2_apply_to_code,
                    p2_c2_change_type, p2_c2_change_amount,
                    p2_c2_change_currency, p2_c2_change_percent,
                    p2_c2_change_selling_uom, p2_c2_price_guide_id,
                    p2_exclusion1_id, p2_exclusion1_display_id,
                    p2_exclusion1_type, p2_e1_start_ind, p2_exclusion2_id,
                    p2_exclusion2_display_id, p2_exclusion2_type,
                    p2_e2_start_ind, loc_move_from_zone_id,
                    loc_move_to_zone_id, location_move_id)
            VALUES (rfrg.future_retail_id, rfrg.dept, rfrg.CLASS,
                    rfrg.subclass, rfrg.item, rfrg.zone_node_type,
                    rfrg.LOCATION, rfrg.action_date, rfrg.selling_retail,
                    rfrg.selling_retail_currency, rfrg.selling_uom,
                    rfrg.multi_units, rfrg.multi_unit_retail,
                    rfrg.multi_unit_retail_currency, rfrg.multi_selling_uom,
                    rfrg.clear_retail, rfrg.clear_retail_currency,
                    rfrg.clear_uom, rfrg.simple_promo_retail,
                    rfrg.simple_promo_retail_currency, rfrg.simple_promo_uom,
                    rfrg.complex_promo_retail,
                    rfrg.complex_promo_retail_currency,
                    rfrg.complex_promo_uom, rfrg.price_change_id,
                    rfrg.price_change_display_id, rfrg.pc_exception_parent_id,
                    rfrg.pc_change_type, rfrg.pc_change_amount,
                    rfrg.pc_change_currency, rfrg.pc_change_percent,
                    rfrg.pc_change_selling_uom, rfrg.pc_null_multi_ind,
                    rfrg.pc_multi_units, rfrg.pc_multi_unit_retail,
                    rfrg.pc_multi_unit_retail_currency,
                    rfrg.pc_multi_selling_uom, rfrg.pc_price_guide_id,
                    rfrg.clearance_id, rfrg.clearance_display_id,
                    rfrg.clear_mkdn_index, rfrg.clear_start_ind,
                    rfrg.clear_change_type, rfrg.clear_change_amount,
                    rfrg.clear_change_currency, rfrg.clear_change_percent,
                    rfrg.clear_change_selling_uom, rfrg.clear_price_guide_id,
                    rfrg.promotion1_id, rfrg.promo1_display_id,
                    rfrg.p1_start_date, rfrg.p1_rank, rfrg.p1_secondary_ind,
                    rfrg.p1_component1_id, rfrg.p1_comp1_display_id,
                    rfrg.p1_c1_detail_id, rfrg.p1_c1_type, rfrg.p1_c1_rank,
                    rfrg.p1_c1_secondary_ind, rfrg.p1_c1_start_date,
                    rfrg.p1_c1_start_ind, rfrg.p1_c1_apply_to_code,
                    rfrg.p1_c1_change_type, rfrg.p1_c1_change_amount,
                    rfrg.p1_c1_change_currency, rfrg.p1_c1_change_percent,
                    rfrg.p1_c1_change_selling_uom, rfrg.p1_c1_price_guide_id,
                    rfrg.p1_component2_id, rfrg.p1_comp2_display_id,
                    rfrg.p1_c2_detail_id, rfrg.p1_c2_type, rfrg.p1_c2_rank,
                    rfrg.p1_c2_secondary_ind, rfrg.p1_c2_start_date,
                    rfrg.p1_c2_start_ind, rfrg.p1_c2_apply_to_code,
                    rfrg.p1_c2_change_type, rfrg.p1_c2_change_amount,
                    rfrg.p1_c2_change_currency, rfrg.p1_c2_change_percent,
                    rfrg.p1_c2_change_selling_uom, rfrg.p1_c2_price_guide_id,
                    rfrg.p1_exclusion1_id, rfrg.p1_exclusion1_display_id,
                    rfrg.p1_exclusion1_type, rfrg.p1_e1_start_ind,
                    rfrg.p1_exclusion2_id, rfrg.p1_exclusion2_display_id,
                    rfrg.p1_exclusion2_type, rfrg.p1_e2_start_ind,
                    rfrg.promotion2_id, rfrg.promo2_display_id,
                    rfrg.p2_start_date, rfrg.p2_rank, rfrg.p2_secondary_ind,
                    rfrg.p2_component1_id, rfrg.p2_comp1_display_id,
                    rfrg.p2_c1_detail_id, rfrg.p2_c1_type, rfrg.p2_c1_rank,
                    rfrg.p2_c1_secondary_ind, rfrg.p2_c1_start_date,
                    rfrg.p2_c1_start_ind, rfrg.p2_c1_apply_to_code,
                    rfrg.p2_c1_change_type, rfrg.p2_c1_change_amount,
                    rfrg.p2_c1_change_currency, rfrg.p2_c1_change_percent,
                    rfrg.p2_c1_change_selling_uom, rfrg.p2_c1_price_guide_id,
                    rfrg.p2_component2_id, rfrg.p2_comp2_display_id,
                    rfrg.p2_c2_detail_id, rfrg.p2_c2_type, rfrg.p2_c2_rank,
                    rfrg.p2_c2_secondary_ind, rfrg.p2_c2_start_date,
                    rfrg.p2_c2_start_ind, rfrg.p2_c2_apply_to_code,
                    rfrg.p2_c2_change_type, rfrg.p2_c2_change_amount,
                    rfrg.p2_c2_change_currency, rfrg.p2_c2_change_percent,
                    rfrg.p2_c2_change_selling_uom, rfrg.p2_c2_price_guide_id,
                    rfrg.p2_exclusion1_id, rfrg.p2_exclusion1_display_id,
                    rfrg.p2_exclusion1_type, rfrg.p2_e1_start_ind,
                    rfrg.p2_exclusion2_id, rfrg.p2_exclusion2_display_id,
                    rfrg.p2_exclusion2_type, rfrg.p2_e2_start_ind,
                    rfrg.loc_move_from_zone_id, rfrg.loc_move_to_zone_id,
                    rfrg.location_move_id);

       --
      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 Begin
      IF (l_active_state != 'pcd.active')
      THEN
         DELETE FROM tsl_rpm_pro_zone_fut_ret rfr
               WHERE rfr.ROWID IN (SELECT rfrg.rfr_rowid
                                     FROM rpm_future_retail_gtt rfrg
                                    WHERE rfrg.timeline_seq = -999);
      END IF;

      --Modified by Debadatta Patra for prd defect fix #17599 on 23-May-2010 End
      DELETE FROM rpm_future_retail_gtt rfrg
            WHERE rfrg.LOCATION IN (SELECT zone_id
                                      FROM rpm_zone rz);

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END tsl_zone_push_back_remove;

------------------------------------------------------------------------------------------------
--Added for prd defect fix NBS00015345 by Debadatta on 17-NOV-2009 End
------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Defect fix DefNBS14255 Starts
-- New Item Loc IPML - To Insert the records in TPND tables Starts .
   FUNCTION tsl_rpm_nil_tpnd_insert (
      o_cc_error_tbl   OUT   conflict_check_error_tbl
   )
      RETURN NUMBER
   IS
      l_program   VARCHAR2 (100)
                           := 'RPM_FUTURE_RETAIL_SQL.TSL_RPM_NIL_TPND_INSERT';
   --
   BEGIN
      INSERT ALL
            INTO tsl_rpm_promo_comp_tpnd
                 (rpm_promo_comp_tpnd_id, rpm_promo_comp_detail_id, tpnb_id,
                  merch_type, tpna_id, diff_id, tpnd_id, primary_tpnd,
                  lock_version
                 )
          VALUES (tsl_rpm_promo_comp_tpnd_seq.NEXTVAL, promo_dtl_id, tpnb,
                  2, tpna, NULL, tpnd, 1,
                  NULL
                 )
         SELECT DISTINCT rfrgt.p1_c1_detail_id promo_dtl_id, rfrgt.item tpnb,
                         pt.item_parent tpna, pt.pack_no tpnd
                    FROM rpm_future_retail_gtt rfrgt,
                         tsl_rpm_promo_comp_tpnd trpct,
                         packitem pt
                   WHERE rfrgt.p1_c1_detail_id IS NOT NULL
                     AND rfrgt.p1_c1_detail_id =
                                                trpct.rpm_promo_comp_detail_id
                     AND rfrgt.item != trpct.tpnb_id
                     AND rfrgt.item = pt.item
                     --Modified by Manoj Auku for Def:NBS00019517 on 22-Oct-2010 Begin
                     AND NOT EXISTS (
                            SELECT 1
                              FROM tsl_rpm_promo_comp_tpnd trpct1
                             WHERE trpct.rpm_promo_comp_detail_id =
                                               trpct1.rpm_promo_comp_detail_id
                               AND trpct.tpnb_id = trpct1.tpnb_id)
         --Modified by Manoj Auku for Def:NBS00019517 on 22-Oct-2010 End
         UNION ALL
         SELECT DISTINCT rfrgt.p1_c2_detail_id promo_dtl_id, rfrgt.item tpnb,
                         pt.item_parent tpna, pt.pack_no tpnd
                    FROM rpm_future_retail_gtt rfrgt,
                         tsl_rpm_promo_comp_tpnd trpct,
                         packitem pt
                   WHERE rfrgt.p1_c2_detail_id IS NOT NULL
                     AND rfrgt.p1_c2_detail_id =
                                                trpct.rpm_promo_comp_detail_id
                     AND rfrgt.item != trpct.tpnb_id
                     AND rfrgt.item = pt.item
                     --Modified by Manoj Auku for Def:NBS00019517 on 22-Oct-2010 Begin
                     AND NOT EXISTS (
                            SELECT 1
                              FROM tsl_rpm_promo_comp_tpnd trpct1
                             WHERE trpct.rpm_promo_comp_detail_id =
                                               trpct1.rpm_promo_comp_detail_id
                               AND trpct.tpnb_id = trpct1.tpnb_id)
         --Modified by Manoj Auku for Def:NBS00019517 on 22-Oct-2010 End
         UNION ALL
         SELECT DISTINCT rfrgt.p2_c1_detail_id promo_dtl_id, rfrgt.item tpnb,
                         pt.item_parent tpna, pt.pack_no tpnd
                    FROM rpm_future_retail_gtt rfrgt,
                         tsl_rpm_promo_comp_tpnd trpct,
                         packitem pt
                   WHERE rfrgt.p2_c1_detail_id IS NOT NULL
                     AND rfrgt.p2_c1_detail_id =
                                                trpct.rpm_promo_comp_detail_id
                     AND rfrgt.item != trpct.tpnb_id
                     AND rfrgt.item = pt.item
                     --Modified by Manoj Auku for Def:NBS00019517 on 22-Oct-2010 Begin
                     AND NOT EXISTS (
                            SELECT 1
                              FROM tsl_rpm_promo_comp_tpnd trpct1
                             WHERE trpct.rpm_promo_comp_detail_id =
                                               trpct1.rpm_promo_comp_detail_id
                               AND trpct.tpnb_id = trpct1.tpnb_id)
         --Modified by Manoj Auku for Def:NBS00019517 on 22-Oct-2010 End
         UNION ALL
         SELECT DISTINCT rfrgt.p2_c2_detail_id promo_dtl_id, rfrgt.item tpnb,
                         pt.item_parent tpna, pt.pack_no tpnd
                    FROM rpm_future_retail_gtt rfrgt,
                         tsl_rpm_promo_comp_tpnd trpct,
                         packitem pt
                   WHERE rfrgt.p2_c2_detail_id IS NOT NULL
                     AND rfrgt.p2_c2_detail_id =
                                                trpct.rpm_promo_comp_detail_id
                     AND rfrgt.item != trpct.tpnb_id
                     AND rfrgt.item = pt.item
                     --Modified by Manoj Auku for Def:NBS00019517 on 22-Oct-2010 Begin
                     AND NOT EXISTS (
                            SELECT 1
                              FROM tsl_rpm_promo_comp_tpnd trpct1
                             WHERE trpct.rpm_promo_comp_detail_id =
                                               trpct1.rpm_promo_comp_detail_id
                               AND trpct.tpnb_id = trpct1.tpnb_id);
      --Modified by Manoj Auku for Def:NBS00019517 on 22-Oct-2010 End
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END tsl_rpm_nil_tpnd_insert;

--  Defect fix DefNBS014255 ends
--  New Item Loc - To Insert the records in TPND tables when new Item Location batch Runs , and if it inherit the promotions .
--  Ends

   --------------------------------------------------------------------------------
--Added for defect fix NBS00016476 by Sajjad Ahmed on 09-Mar-2010 Begin
   FUNCTION tsl_valid_promo_for_lm_merge (
      o_cc_error_tbl   OUT      conflict_check_error_tbl,
      i_promo_ids      IN       obj_numeric_id_table
   )
      RETURN NUMBER
   IS
      l_program             VARCHAR2 (100)
                      := 'RPM_FUTURE_RETAIL_SQL.TSL_VALID_PROMO_FOR_LM_MERGE';
      -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 BEGIN
      o_error_message       VARCHAR2 (255);
      l_rpm_loc_move_chgs   system_options.tsl_rpm_loc_move_chgs%TYPE;
   -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 End
   BEGIN
      --
      DELETE FROM rpm_future_retail_gtt fr
            WHERE fr.promotion1_id IS NOT NULL
               OR fr.promo1_display_id IS NOT NULL
               OR fr.p1_component1_id IS NOT NULL
               OR fr.p1_comp1_display_id IS NOT NULL
               OR fr.p1_c1_start_date IS NOT NULL
               OR fr.p1_component2_id IS NOT NULL
               OR fr.p1_comp2_display_id IS NOT NULL
               OR fr.p1_c2_start_date IS NOT NULL
               OR fr.promotion2_id IS NOT NULL
               OR fr.promo2_display_id IS NOT NULL
               OR fr.p2_component1_id IS NOT NULL
               OR fr.p2_comp1_display_id IS NOT NULL
               OR fr.p2_c1_start_date IS NOT NULL
               OR fr.p2_component2_id IS NOT NULL
               OR fr.p2_comp2_display_id IS NOT NULL
               OR fr.p2_c2_start_date IS NOT NULL;

      IF rpm_cc_two_prom_limit.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
      THEN
         RETURN 0;
      END IF;

      IF rpm_cc_two_promcomp_limit.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
      THEN
         RETURN 0;
      END IF;

      IF rpm_cc_promcomp_overlap.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
      THEN
         RETURN 0;
      END IF;

      IF rpm_cc_two_promexcl_limit.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
      THEN
         RETURN 0;
      END IF;

      -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 BEGIN
      IF system_options_sql.tsl_get_rpm_loc_move_chgs (o_error_message,
                                                       l_rpm_loc_move_chgs
                                                      ) = FALSE
      THEN
         RETURN 0;
      END IF;

      IF    l_rpm_loc_move_chgs != 'Y'
         OR rpm_bulk_cc_threading_sql.is_loc_move_ind != 'Y'
      THEN
         IF rpm_cc_prom_span_lm.VALIDATE (o_cc_error_tbl, i_promo_ids) = 0
         THEN
            RETURN 0;
         END IF;
      END IF;

      -- Defect fix NBS00013883(N25) By Debadatta Patra 27-July-2009 End

      --
      RETURN 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_cc_error_tbl :=
            conflict_check_error_tbl
               (conflict_check_error_rec (NULL,
                                          NULL,
                                          rpm_conflict_library.plsql_error,
                                          sql_lib.create_msg ('PACKAGE_ERROR',
                                                              SQLERRM,
                                                              l_program,
                                                              TO_CHAR (SQLCODE)
                                                             )
                                         )
               );
         RETURN 0;
   END tsl_valid_promo_for_lm_merge;
--Added for defect fix NBS00016476 by Sajjad Ahmed on 09-Mar-2010 End
END big_promo;
/

