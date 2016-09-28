CREATE OR REPLACE PACKAGE BODY ITEM_APPROVAL_SQL_FIX AS
---------------------------------------------------------------------------------------------
   --Mod By:      WiproEnabler/Ramasamy
   --Mod Date:    07-Dec-2007
   --Mod Ref:     Defect 4323
   --Mod Details: Should not allow to approve if RETAIL BY ZONE is mandatory
---------------------------------------------------------------------------------------------
   LP_vdate             PERIOD.VDATE%TYPE     := GET_VDATE;
   LP_tocc_req_ind      VARCHAR2(1)           := ''; --09-JAN-2008   Wipro/JK    DefNBS00004546
---------------------------------------------------------------------------------------------
-- Mod By:      Shweta Madnawat, shweta.madnawat@in.tesco.com
-- Mod Date:    18-Sep-2007
-- Mod Ref:     Mod number. N22drms12
-- Mod Details: Added logic to check if the new submit and approval
--              rules are met.
---------------------------------------------------------------------------------------------
-- Modified By      : Nitin Kumar, nitin.kumar@in.tesco.com
-- Modification Date: 19-NOV-2007
-- Defect Id        : NBS00004044
-- Purpose          : Modified the function APPROVAL_CHECK as it was approving the item
--                    even some mandatory information was not entered
---------------------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    20-Nov-2007
-- Mod Ref:     DefNBS4095
-- Mod Details: Parameter Order re arranged while calling TSL_GET_REQ_INDS method
---------------------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    23-Nov-2007
-- Mod Ref:     Defect 4206
-- Mod Details: To check the availability of retail and OCC barcode,
--              tsl_check_retail_occ_barcode has been called instead of tsl_subtran_exist
--              function.
---------------------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    09-JAN-2008
-- Mod Ref:     Defect 4546
-- Mod Details: Code added to approve the item when OCC barcode is optional and no OCC
--              found for the simple pack
---------------------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    10-JAN-2008
-- Mod Ref:     Defect 4560
-- Mod Details: Code added to block the submit/approve the level1 style when level 3 item
--              is mandatory and not fould.
---------------------------------------------------------------------------------------------
-- Mod By:      John Alister Anand john.anand@in.tesco.com
-- Mod Date:    22-JAN-2008
-- Mod Ref:     NBS004633
-- Mod Details: Modified the cursor to include search of Item Description for item approval.
---------------------------------------------------------------------------------------------
-- Mod By:      Vipindas Thekke Purakkal, vipindas.thekkepurakkal@in.tesco.com
-- Mod Date:    12-Mar-2008
-- Mod Ref:     Defect 5385
-- Mod Details: Modified the function Submit.
---------------------------------------------------------------------------------------------
-- Mod By:      WiproEnabler/Karthik ,karthik.dhanapal@wipro.com
-- Mod Date:    23-Apr-2008
-- Mod Ref:     NBS00005385
-- Mod Details: Modified the functions Submit and Approve to not to check for OCC for a pack of
--              a placeholder base item.
---------------------------------------------------------------------------------------------
-- Mod By:      Bahubali Dongare, Bahubali.Dongare@in.tesco.com
-- Mod Date:    24-Apr-2008
-- Mod Ref:     Defect NBS00005976
-- Mod Details: Modified the function PROCESS_ITEM as per the changes in TSD for the defect.
---------------------------------------------------------------------------------------------
-- Mod By:      Bahubali Dongare, Bahubali.Dongare@in.tesco.com
-- Mod Date:    05-Jun-2008
-- Mod Ref:     Defect NBS00006962
-- Mod Details: Modified the function PROCESS_ITEM as per the changes in TSD for the defect.
---------------------------------------------------------------------------------------------
-- Fix By      : Wipro/Dhuraison Prince                                                   --
-- Fix Date    : 14-Jul-2008                                                              --
-- Defect ID   : NBS00007787                                                              --
-- Fix Details : Added call to function INSERT_FUTURE_EXPENSES which will insert future   --
--               expense records into TSL_EXP_QUEUE table for packs with expense attached --
---------------------------------------------------------------------------------------------
-- Mod By:      Vipindas Thekke Purakkal, vipindas.thekkepurakkal@in.tesco.com
-- Mod Date:    12-May-2008
-- Mod Ref:     N127
-- Mod Details: Modified the function Approval_Check.
---------------------------------------------------------------------------------------------
--Mod By:      Chandru N, chandrashekaran.natarajan@in.tesco.com
--Mod Date:    23-Jun-2008
--Mod Ref:     N111
--Mod Details: Added functions TSL_SUBMIT_VARIANT and TSL_APPROVE_VARIANT
--             Modified functins APPROVAL_CHECK and WORKSHEET
---------------------------------------------------------------------------------------------
--Mod By:      Murali, murali.natarajan@in.tesco.com
--Mod Date:    10-Jul-2008
--Mod Ref:     MrgNBS007760(N111)
--Mod Details: Modified functions TSL_SUBMIT_VARIANT and TSL_APPROVE_VARIANT
---------------------------------------------------------------------------------------------
--Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
--Mod Date:    17-Jul-2008
--Mod Ref:     DefNBS007900
--Mod Details: Modified to avoid range validation error for variant items.
---------------------------------------------------------------------------------------------
-- Mod By:      WiproEnabler/Karthik ,karthik.dhanapal@wipro.com
-- Mod Date:    26-Aug-2008
-- Mod Ref:     NBS00007711
-- Mod Details: Modified the functions Submit and Approve to not to submit or approve the parent
--              item if any of the child/grand child or packs of the child fails.
---------------------------------------------------------------------------------------------
-- Mod By        : Satish B.N satish.narasimmhaiah@in.tesco.com
-- Mod Date      : 26-Aug-2008
-- Mod Details   : Added a new parameter to TSL_APPLY_REAL_TIME_COST function call as part of DefNBS007325
---------------------------------------------------------------------------------------------
---Mod By    --- Tarun Kumar Mishra
---Mod Date  --- 11-sep-2008
---Mod Ref   --- DefNBS009007
---------------------------------------------------------------------------------------------
--Mod By:      Murali, murali.natarajan@in.tesco.com
--Mod Date:    16-Sep-2008
--Mod Ref:     DefNBS008079
--Mod Details: Modified approval logic to clear approval errors once the item is approved.
---------------------------------------------------------------------------------------------
--Mod By:      Raghuveer P R
--Mod Date:    16-Jan-2009
--Mod Ref:     Defect NBS00010904
--Mod Details: Modified approval logic to exclude sub-trans level merch heir default while
--             approving place-holder base items.
---------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 04-Mar-2009
-- Mod Ref    : CR171
-- Mod Details: Added provision for Merchandise Unit in Function APPROVAL_CHECK
---------------------------------------------------------------------------------------------
-- Mod By:      Vipindas Thekke Purakkal, vipindas.thekkepurakkal@in.tesco.com
-- Mod Date:    05-Mar-2009
-- Mod Ref:     Defect 11755
-- Mod Details: Modified the function Approval_Check.
---------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 13-Apr-2009
-- Defect Id  : NBS00011868(UAT Defect)
-- Mod Details: Modified the function Approval_Check to exclude the check of OCC for
--              Complex packs.if it's item number type = system_options.tsl_ratio_pack_type
---------------------------------------------------------------------------------------------
--Mod By:      Murali, murali.natarajan@in.tesco.com
--Mod Date:    21-Apr-2009
--Mod Ref:     DefNBS012156
--Mod Details: Modified approval logic to not consider items in delete pending status
--             for approval.
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Mod By      : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
-- Mod Date    : 04-June-2009
-- Mod Ref     : DefNBS012917
-- Mod Details : Modified approval logic to consider required attributes in merch hier default table
---------------------------------------------------------------------------------------------
-- Mod By     : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 09-Jun-2009
-- Mod Ref    : DefNBS013056
-- Mod Details: Modified APPROVAL_CHECK function
---------------------------------------------------------------------------------------------
-- Mod By     : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 16-Jun-2009
-- Mod Ref    : DefNBS013324
-- Mod Details: Modified the cursor C_PACK_OCCS in SUBMIT function
---------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 23-Jun-2009
-- Def Ref    : MrgNBS013573
-- Def Details: Modified the function APPROVAL_CHECK,SUBMIT as a part of Merge.
-------------------------------------------------------------------------------------------------
-- Mod By     : Tarun Kumar Mishra, tarun.mishra@in.tesco.com
-- Mod Date   : 29-Jun-2009
-- Mod Ref    : DefNBS013690
-- Mod Details: Modified the function SUBMIT,APPROVE function
---------------------------------------------------------------------------------------------
-- Mod By     : Tarun Kumar Mishra, tarun.mishra@in.tesco.com
-- Mod Date   : 15-July-2009
-- Mod Ref    : DefNBS013907
-- Mod Details: Modified the function SUBMIT,APPROVE function
---------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 29-July-2009
-- Mod Ref    : Defect NBS00014202
-- Mod Details: Modified the function PROCESS_ITEM
---------------------------------------------------------------------------------------------
-- Mod By     : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 06-Aug-2009
-- Mod Ref    : DefNBS014327
-- Mod Details: Modified PROCESS_ITEM function to restrict duplicate insertion to price_hist table
---------------------------------------------------------------------------------------------
-- Merged by   : Nitin Kumar, nitin.kumar@in.tesco.com
-- Date        : 10-Aug-2009
-- Desc        : Merge 3.3b to 3.4  and 3.4 to 3.5a
---------------------------------------------------------------------------------------------
-- Mod By:      Vipindas Thekke Purakkal, vipindas.thekkepurakkal@in.tesco.com
-- Mod Date:    12-Aug-2009
-- Mod Ref:     Defect 14398
-- Mod Details: Modified the function Approval_Check.
--------------------------------------------------------------------------------------------------------
-- Mod By     : Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 25-Aug-2009
-- Mod Ref    : CR236
-- Mod Details: Modified PROCESS_ITEM and APPROVAL_CHECK functions
---------------------------------------------------------------------------------------------
-- Mod By:      Murali Natarajan, murali.natarajan@in.tesco.com
-- Mod Date:    26-Aug-2009
-- Mod Ref:     Defect 14572
-- Mod Details: Modified the functions SUBMIT and APPROVE to submit/approve the style and
--              tran level items when at least one barcode is authorised. This means that
--              in an item family whichever items are complete and can be sumbitted/approved
--              will be set in submit/approve status along with the style item. Rest of the
--              items which fail checks will continue to remain in Worksheet status.
---------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 18-Sep-2009
-- Mod Ref    : CR236
-- Mod Details: Modified the function APPROVAL_CHECK
---------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 22-Sep-2009
-- Mod Ref    : CR249
-- Mod Details: Range for Complex Pack
---------------------------------------------------------------------------------------------
-- Mod By     : Sarayu P Gouda
-- Mod Date   : 07-Oct-2009
-- Mod Ref    : NBS00014908
-- Mod Details: Modified the function SUBMIT
---------------------------------------------------------------------------------------------
-- Mod By     : Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 23-Oct-2009
-- Mod Ref    : MrgNBS015130
-- Mod Details: Merge 3.4 Dev to 3.5b
---------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 28-Oct-2009
-- Mod Ref    : NBS00014308
-- Mod Details: Modified SUBMIT() and APPROVE() not to assign values just based on L_pack_flg so that
--              and item which fails validation should not be submmited or approved.
--------------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 09-Nov-2009
-- Mod Ref    : CR213
-- Mod Details: New function TSL_CHECK_TBAN is added to check if the item number type belongs to TBAN.
--              Modified APPROVAL_CHECK() to ignore the TRET setup in merch hier defaults if the item number
--              type belongs to TBAN(Tesco Barcode Authorization Not Applicable).
--------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 10-Dec-2009
-- Mod Ref    : DefNBS015675
-- Mod Details: Modified the function TSL_SUBMIT_VARIANT to handle the Mass approval of Itemlist.
--------------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 17-Dec-2009
-- Mod Ref    : MrgNBS015789
-- Mod Details: Merged Phase 3.5a to 3.5b (Defect NBS00015773)
--------------------------------------------------------------------------------------------------------
--Mod By      : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
--Mod Date    : 16-Dec-2009
--Mod Ref     : NBS00015773
--Mod Details : Modified the function approval_check
--------------------------------------------------------------------------------------------------------
--Mod By      : Usha Patil, usha.patil@in.tesco.com
--Mod Date    : 05-Feb-2010
--Mod Ref     : DefNBS016054
--Mod Details : Modified the functions SUBMIT and APPROVE not to throw error if we try to submit or approve
--              the item which is already submitted or approved using All Items plus Children radio button.
--------------------------------------------------------------------------------------------------------
--Mod By   : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
--Mod Date : 18-Feb-2010
--Mod Ref  : CR288
--Mod Desc : Modified the function APPROVAL_CHECK for CR288
--------------------------------------------------------------------------------------------------------
--Mod By   : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
--Mod Date : 02-MARCh-2010
--Mod Ref  : NBS00016489
--Mod Desc : Modified the function APPROVAL_CHECK for CR288
--------------------------------------------------------------------------------------------------------
-- Merged by   : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Date        : 05-Mar-2010
-- Desc        : Merge 3.5d to 3.5b
---------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 17-Feb-2010
-- Mod Ref    : PrfNBS00016258
-- Mod Details: Modified the cursor in WORKSHEET and SUBMIT functions to improve the perfomance
--------------------------------------------------------------------------------------------------------
--Mod  By      : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
--Mod  Date    : 09-March-2010
--Mod  Ref     : NBS00016537
--Mod  Details : Modified the function Approvel_check for the defect 16537.
--------------------------------------------------------------------------------------------------------
--Mod  By      : Shweta Madnawat, shweta.madnawat@in.tesco.com
--Mod  Date    : 05-Apr-2010
--Mod  Ref     : NBS00016666
--Mod  Details : Modified the function APPROVAL_CHECK for the defect 16666
--------------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    05-Apr-2010
--Mod Ref:     DefNBS016764
--Mod Details: Added new function to validate TPNB/TPND attributes with TPND/TPNB.
--------------------------------------------------------------------------------------------
--Mod  By      : Usha Patil, usha.patil@in.tesco.com
--Mod  Date    : 06-Apr-2010
--Mod  Ref     : NBS00016671
--Mod  Details : Modified the function APPROVAL_CHECK for the defect 16671
--------------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 25-Mar-2010
-- Mod Ref    : CR275
-- Mod Details: Modified package to remove the item up charge population on item approval.
-------------------------------------------------------------------------------
-- Mod By     : JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 08-Apr-10
-- Mod Ref    : MrgNBS016979
-- Mod Details: CR275 changes added.
----------------------------------------------------------------------------------------------------
--Mod By:      Usha Patil, usha.patil@in.tesco.com
--Mod Date:    15-Apr-2010
--Mod Ref:     CR295
--Mod Details: Added new functions TSL_UPDATE_ITEM_ATTR and TSL_UPDATE_SCA to update effective
--             dates and launch date on item approval.
--------------------------------------------------------------------------------------------
--Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    12-Apr-2010
--Mod Ref:     DefNBS016998
--Mod Details: Modified approval_check function.
----------------------------------------------------------------------------------------------------
--Mod By:      Bhargavi Pujari, bharagavi.pujari@in.tesco.com Begin
--Mod Date:    22-Apr-2010
--Mod Ref:     NBS00017173
--Mod Details: Modified TSL_CHECK_COMP_ATTRIB function.
----------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    29-Apr-2010
--Mod Ref:     DefNBS016999
--Mod Details: Modified approval_check function to approve an item if one country
--             item attributes is complete.
----------------------------------------------------------------------------------------------------
--Mod By:      Usha Patil, usha.patil@in.tesco.com
--Mod Date:    06-May-2010
--Mod Ref:     Def - NBS00017304 and NBS00017306
--Mod Details: Modified function TSL_UPDATE_ITEM_ATTR to update the range effective date
--             properly and tsl_dev_end_date when launch date is changed.
--------------------------------------------------------------------------------------------
--Mod By:      Murali N, murali.natarajan@in.tesco.com
--Mod Date:    17-May-2010
--Mod Ref:     CR288b
--Mod Details: Added Function TSL_CHECK_RP_COMP and added validations in APPROVAL_CHECK.
--             Also Removed Comented Codes from approval check.
------------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    18-Apr-2010
--Mod Ref:     CR288b
--Mod Details: Modified TSL_CHECK_COMP_ATTRIB function.
------------------------------------------------------------------------------------------------------
--Mod By:      shweta.madnawat@in.tesco.com
--Mod Date:    18-May-2010
--Mod Ref:     DefNBS017490
--Mod Details: Modified the SUBMIT function to stop updating the pack's status to worksheet if it is
--             present in daily purge table.
----------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    20-Apr-2010
--Mod Ref:     DefNBS017547
--Mod Details: Modified TSL_CHECK_COMP_ATTRIB function to return country specific error key.
------------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    21-May-2010
--Mod Ref:     DefNBS016764 and CR288b- Big fix code have been moved to approval_check from sumit function
--Mod Details: Modified TSL_CHECK_COMP_ATTRIB function to return country specific error key.
------------------------------------------------------------------------------------------------------
--Mod By:      V Manikandan
--Mod Date:    28-May-2010
--Mod Ref:     NBS00017739
--Mod Details: Modified TSL_UPDATE_SCA function.
------------------------------------------------------------------------------------------------------
--Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
--Mod Date   : 02-May-2010
--Mod Ref    : MrgNBS017783(Merge 3.5b to 3.5f)
--Mod Details: Merged CR288b,DefNBS017490,DefNBS017547,DefNBS016764,CR288b - BIG FIX
------------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    12-Jul-2010
--Mod Ref:     CR288C- Big fix
--Mod Details: Modified APPROVAL_CHECK function modified to validate supplier.
------------------------------------------------------------------------------------------------------
--Mod By:      Usha Patil, usha.patil@in.tesco.com
--Mod Date:    13-Jul-2010
--Mod Ref:     CR288C
--Mod Details: Modified functions TSL_UPDATE_ITEM_ATTR and TSL_UPDATE_SCA to accept more
-- parameters are update the dates as and when the country_auth_indicator is updated.
--------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 20-Jul-2010
-- Mod Ref    : MrgNBS018360
-- Mod Details: Merged Def-18153.
--------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 07-Jul-2010
-- Mod Ref    : DefNBS018153
-- Mod Details: Modified the function UPDATE_STATUS to handle the CR295 changes.
--------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
---Mod By   : V Manikandan
---Mod Ref  : NBS00018415
---Mod Date : 02-Aug-2010
---Mod Desc : Modified TSL_UPDATE_ITEM_ATTR function to improve the performance.
-------------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    26-Aug-2010
--Mod Ref:     CR2354
--Mod Details: Modified SUBMIT and APPROVE function.
------------------------------------------------------------------------------------------------------
--Mod By:      yashavantharaja, yashavanhtaraja.thimmesh@in.tesco.com
--Mod Date:    14-Sep-2010
--Mod Ref:     DefNBS019141
--Mod Details: Modified SUBMIT and APPROVE function.
------------------------------------------------------------------------------------------------------
--MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com  Begin
-------------------------------------------------------------------------------------------------------
--Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
--Mod Date   : 05-Aug-2010
--Mod Ref    : MrgNBS018606(Merge 3.5f to 3.5g)
--Mod Details: Merged CR288C,MrgNBS018360,DefNBS018153,NBS00018415
------------------------------------------------------------------------------------------------------
--Mod By     : Sripriya, Sripriya.karanam@in.tesco.com
--Mod Date   : 01-Aug-2010
--Mod Ref    : CR347
--Mod Details: Modified Approval_check
------------------------------------------------------------------------------------------------------
--Mod By     : Sripriya, Sripriya.karanam@in.tesco.com
--Mod Date   : 10-Aug-2010
--Mod Ref    : DefNBS018653
--Mod Details: Modified Approval_check
------------------------------------------------------------------------------------------------------
-- Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Date   : 16-Sep-2010
-- Mod Ref    : MrgNBS019188, Merge from 3.5g to 3.5b
-- Mod Details: Merged changes for MrgNBS018606, CR347 and DefNBS018653
-------------------------------------------------------------------------------------------------------
--MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com  End
------------------------------------------------------------------------------------------------------
--Mod By     : Sripriya, Sripriya.karanam@in.tesco.com
--Mod Date   : 10-Nov-2010
--Mod Ref    : DefNBS019710
--Mod Details: Modified the functions SUBMIT and APPROVE.
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
--Mod Date   : 03-Dec-2010
--Mod Ref    : DefNBS019985
--Mod Details: Modified the function TSL_UPDATE_ITEM_ATTR
------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
--Mod By     : Merlyn Mathew, Merlyn.Mathew@in.tesco.com
--Mod Date   : 09-Dec-2010
--Mod Ref    : DefNBS00020078
--Mod Details: Modified TSL_CHECK_COMP_ATTRIB function to insert Simple Pack Approval error messages
--             as per CR 332.
--             Modified APPROVAL_CHECK function to insert Ratio Pack Approval error messages
--             as per CR 332.
------------------------------------------------------------------------------------------------------
--Mod By     : vipin s, vipin.simar@in.tesco.com
--Mod Date   : 28-Dec-2010
--Mod Ref    : DefNBS020236
--Mod Details: Put one condetion if user in ('U','B') then check the validation in APPROVAL_CHECK function
--             regarding CR335.
------------------------------------------------------------------------------------------------------

FUNCTION APPROVAL_CHECK(O_error_message        IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        O_approved             IN OUT   BOOLEAN,
                        I_skip_component_chk   IN       VARCHAR2,
                        I_parent_status        IN       ITEM_MASTER.STATUS%TYPE,
                        I_new_status           IN       ITEM_MASTER.STATUS%TYPE,
                        I_item                 IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program                    VARCHAR2(64)  := 'ITEM_APPROVAL_SQL_FIX.APPROVAL_CHECK';
   L_supp_exists                BOOLEAN;
   L_unit_retail_exists         VARCHAR2(1)   := 'N';
   L_component_exists           VARCHAR2(1)   := 'N';
   L_nonappr_component_exists   VARCHAR2(1)   := 'N';
   L_item_supp_country_exists   VARCHAR2(1)   := 'N';
   L_cost_change_exists         VARCHAR2(1)   := 'N';
   L_zone_change_exists         VARCHAR2(1)   := 'N';
   L_item_parent                ITEM_MASTER.ITEM%TYPE;
   L_parent_status              ITEM_MASTER.STATUS%TYPE;
   L_req_no_value               VARCHAR2(1);
   L_group_exist                VARCHAR2(1)   := 'N';
   L_loc_req_ind                VARCHAR2(1);
   L_loc_exists                 VARCHAR2(1)   := 'N';
   L_docs_req_ind               VARCHAR2(1);
   L_docs_exist                 VARCHAR2(1)   := 'N';
   L_hts_req_ind                VARCHAR2(1);
   L_hts_exists                 VARCHAR2(1)   := 'N';
   L_tariff_req_ind             VARCHAR2(1);
   L_tariff_exists              BOOLEAN       := FALSE;
   L_exp_req_ind                VARCHAR2(1);
   L_expense_exists             VARCHAR2(1)   := 'N';
   L_dimension_req_ind          VARCHAR2(1);
   L_dimensions_exist           VARCHAR2(1)   := 'N';
   L_diff_1                     ITEM_MASTER.DIFF_1%TYPE;
   L_diff_2                     ITEM_MASTER.DIFF_2%TYPE;
   L_diff_3                     ITEM_MASTER.DIFF_3%TYPE;
   L_diff_4                     ITEM_MASTER.DIFF_4%TYPE;
   L_diffs_req_ind              VARCHAR2(1);
   L_wastage_req_ind            VARCHAR2(1);
   L_pack_sz_req_ind            VARCHAR2(1);
   L_retail_lb_req_ind          VARCHAR2(1);
   L_mfg_rec_req_ind            VARCHAR2(1);
   L_handling_req_ind           VARCHAR2(1);
   L_handling_temp_req_ind      VARCHAR2(1);
   L_comments_req_ind           VARCHAR2(1);
   L_itattrib_req_ind           VARCHAR2(1);
   L_itattrib_exists            VARCHAR2(1)   := 'N';
   L_impattrib_req_ind          VARCHAR2(1);
   L_impattrib_exists           BOOLEAN       := FALSE;
   L_tax_codes_req_ind          VARCHAR2(1);
   L_tax_codes_exist            BOOLEAN       := FALSE;
   L_tickets_req_ind            VARCHAR2(1);
   L_tickets_exist              BOOLEAN       := FALSE;
   L_timeline_req_ind           VARCHAR2(1);
   L_timeline_exists            VARCHAR2(1)   := 'N';
   L_image_req_ind              VARCHAR2(1);
   L_image_exists               VARCHAR2(1)   := 'N';
   L_sub_tr_items_req_ind       VARCHAR2(1);
   L_sub_tr_exists              VARCHAR2(1)   := 'N';
   L_seasons_req_ind            VARCHAR2(1);
   L_seasons_exist              VARCHAR2(1)   := 'N';
   L_dummy                      VARCHAR2(62);
   L_ndummy                     NUMBER(20);
   L_bracket_no_cost            VARCHAR2(1)   := 'N';
   L_store_exists               VARCHAR2(1)   := 'N';
   L_item_master_rec            ITEM_MASTER%ROWTYPE;
   L_purchase_type              DEPS.DEPT%TYPE;
   L_sellable_exists            VARCHAR2(1)   := 'N' ;
   L_null_tolerances_exist      VARCHAR2(1)   := 'N' ;
   -- Begin Mod N22 on 18-Sep-2007
   L_lschld_req_ind             VARCHAR2(1);
   L_spstup_req_ind             VARCHAR2(1);
   L_tocc_req_ind               VARCHAR2(1);
   L_tret_req_ind               VARCHAR2(1);
   L_tslsca_req_ind             VARCHAR2(1);
   L_tocc_trans_exists          BOOLEAN                                 := FALSE;
   L_tret_trans_exists          BOOLEAN                                 := FALSE;
   L_lschld_trans_exists        BOOLEAN                                 := FALSE;
   L_spstup_trans_exists        BOOLEAN                                 := FALSE;
   L_tocc_subtrans_exists       BOOLEAN                                 := FALSE;
   L_tret_subtrans_exists       BOOLEAN                                 := FALSE;
   L_gchild_tret_exists         BOOLEAN                                 := FALSE;
   L_tslsca_exists              BOOLEAN                                 := FALSE;
   L_child_exists               BOOLEAN                                 := FALSE;
   L_child_attrib_exists        BOOLEAN                                 := FALSE;
   L_childph_attrib_exists      BOOLEAN                                 := FALSE;
   L_tsl_product_auth           SYSTEM_OPTIONS.TSL_PRODUCT_AUTH%TYPE;
   L_tsl_launch_base_ind        BOOLEAN                                 := FALSE;
   O_exists                     BOOLEAN;
   L_exists                     BOOLEAN;
   L_status                     ITEM_MASTER.STATUS%TYPE;
   -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 22-May-2009 , Begin
   L_new_itattrib_req_ind       VARCHAR2(1);
   L_new_attrib_req_exists      VARCHAR2(1);
   L_req_L1_L2_attrib_exists    VARCHAR2(1);
   -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 22-May-2009 , End

   -- Begin ModN115,116,117 Wipro/JK 20-Feb-2008
   L_flg                        VARCHAR2(1);
   -- End ModN115,116,117 Wipro/JK 20-Feb-2008

   --ModN127, 12-May-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
   L_merch_dft_rnge_exists      VARCHAR2(1);
   --ModN127, 12-May-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
   --CR236 Raghuveer P R 05-Sep-2009 -Begin
   L_merch_dft_rnge_exists_roi  VARCHAR2(1);
   --CR236 Raghuveer P R 05-Sep-2009 -End
   --UAT Defect NBS00011868, Nitin Kumar, nitin.kumar@in.tesco.com, 13-Apr-2009, Begin
   L_system_options_rec         SYSTEM_OPTIONS%ROWTYPE;
   --UAT Defect NBS00011868, Nitin Kumar, nitin.kumar@in.tesco.com, 13-Apr-2009, End
   --25-Aug-2009      Wipro/JK      CR236    Begin
   L_tsl_single_instance        SYSTEM_OPTIONS.TSL_SINGLE_INSTANCE_IND%TYPE;
   L_roi_itattrib_exists        VARCHAR2(1)   := 'N';
   L_tslsca_exists_roi          BOOLEAN       := FALSE;
   --25-Aug-2009      Wipro/JK      CR236    End
   -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 15-Feb-2010 Begin
   L_new_roi_itattrib_exists    VARCHAR2(1);
   L_tslsca_chk_exists_uk       VARCHAR2(1);
   L_tslsca_chk_exists_roi      VARCHAR2(1);
   L_range_exists_uk            VARCHAR2(1);
   L_range_exists_roi           VARCHAR2(1);
   L_base_item_sca_exists       VARCHAR2(1);
   -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 15-Feb-2010 End
   --09-Nov-2009 Tesco HSC/Usha Patil             Mod: CR213 Begin
   L_tban_type                  VARCHAR2(1)   := 'N';
   --09-Nov-2009 Tesco HSC/Usha Patil             Mod: CR213 End
   --12-May-2010 Murali  Cr288b Begin
   L_uk_specific_sp             BOOLEAN;
   L_roi_specific_sp            BOOLEAN;
   L_base_country_auth          ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE;
   L_var_country_auth           ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE;
   --12-May-2010 Murali  Cr288b End
   --19-May-2010 Murali  Cr288b Begin
   L_parent_country_auth ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE;
   L_error_key                  RTK_ERRORS.RTK_KEY%TYPE;
   --19-May-2010 Murali  Cr288b End
   -- DefNBS016764, 05-Apr-2010, Govindarajan K, Begin
   L_sink                       BOOLEAN   := FALSE;
   L_err_item                   ITEM_MASTER.ITEM%TYPE;
   L_rtk_key                    RTK_ERRORS.RTK_KEY%TYPE;
   -- DefNBS016764, 05-Apr-2010, Govindarajan K, End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
   --26-Jul-2010, Sripriya,Sripriya.karanam@in.tesco.com, Cr347 Begin
   L_tsocc_req_ind              VARCHAR2(1) := 'N';
   L_tsret_req_ind              VARCHAR2(1) := 'N';
   L_code_type                  CODE_DETAIL.CODE_TYPE%TYPE;
   --26-Jul-2010 Sripriya,Sripriya.karanam@in.tesco.com, Cr347 End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
   -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, Begin
   L_uk_ind                            VARCHAR2(1) := 'N';
   L_roi_ind                         VARCHAR2(1) := 'N';
   -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, End
   -- Cursor to get the value of tsl_product_auth from system options table.
   -- If it is 'Y', then the checks for ModN22 will be performed.
   cursor C_CHECK_PRODUCT_AUTH is
   select tsl_product_auth
       from system_options;
   -- End Mod N22 on 18-Sep-2007
   cursor C_COMPONENT_EXISTS is
      select 'Y'
        from packitem
       where pack_no = I_item;

   cursor C_COMPONENT_NOT_APPROVED is
      select 'Y'
        from packitem pi,
             item_master im
       where I_item     = pi.pack_no
         and im.item    = pi.item
   -- 16-Sep-2008 TESCO HSC/Murali  DefNBS008079  Begin
         and (I_new_status = 'S' and im.status not in('S','A')
              or (I_new_status = 'A'and im.status !='A'));
   -- 16-Sep-2008 TESCO HSC/Murali  DefNBS008079  End

   cursor C_ITEM_SUPP_COUNTRY_EXIST is
      select 'Y'
        from item_supp_country
       where item = I_item;


   cursor C_NULL_TOLERANCES_EXIST is
      select 'Y'
        from item_supp_country
       where item = I_item
         and (   max_tolerance is NULL
              or min_tolerance is NULL);

   cursor C_GET_PARENT_STATUS is
      select status
        from item_master
       where item = L_item_master_rec.item_parent;

   cursor C_ITEM_GROUPS is
      select 'Y'
        from item_master im
       where item_level          = tran_level
         and (item_parent        = I_item
             or item_grandparent = I_item)
   -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  Begin
         and not exists(select 1
                          from daily_purge dp
                         where dp.key_value = im.item
                           and table_name = 'ITEM_MASTER');
   -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  End

   cursor C_CHECK_LOC is
      select 'Y'
        from item_loc
       where item = I_item;

   cursor C_CHECK_SEASONS is
      select 'Y'
        from item_seasons
       where item = I_item;
   --25-Aug-2009      Wipro/JK      CR236    Begin
   cursor C_SINGLE_INSTANCE is
      select tsl_single_instance_ind
        from system_options;

   -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
   -- Removed the reference of country from the below cursor for the different table
   cursor C_UKROI_CHECK_ITATTRIB (Cp_country VARCHAR2) is
      select 'Y'
        from item_attributes
       where item = I_item
         and tsl_country_id = Cp_country
         --12-May-2010 Murali  Cr288b Begin
         and tsl_launch_date is not null
         --12-May-2010 Murali  Cr288b End
         and ROWNUM = 1;
      -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 15-Feb-2010 End
   --25-Aug-2009      Wipro/JK   CR236   End

   --12-May-2010 Murali  Cr288b Begin
   cursor C_UKROI_CHECK_ATTR_EAN_OCC (Cp_country VARCHAR2) is
      select 'Y'
        from item_attributes ia
       where item = I_item
         and tsl_country_id = Cp_country
         --19-May-2010 Murali  Cr288b Begin
         and exists(select 1
                      from item_attributes ia2,
                           item_master im
                     where im.item = ia.item
                       and im.item_parent = ia2.item
                       and ia2.tsl_country_id = ia.tsl_country_id
                       and ia2.tsl_launch_date is not null)
         --19-May-2010 Murali  Cr288b End
         and ROWNUM = 1;
   --12-May-2010 Murali  Cr288b End

   cursor C_CHECK_ITATTRIB is
      select 'Y'
        from item_attributes
       where item = I_item
         and ROWNUM = 1
-- NBS004633, John Alister Anand, 22-Jan-2008, BEGIN
      UNION
        select 'Y'
            from tsl_itemdesc_base
         where item = I_item
             and ROWNUM = 1
      UNION
        select 'Y'
            from tsl_itemdesc_episel
         where item = I_item
             and ROWNUM = 1
      UNION
        select 'Y'
            from tsl_itemdesc_iss
         where item = I_item
             and ROWNUM = 1
      UNION
        select 'Y'
            from tsl_itemdesc_pack
         where pack_no = I_item
             and ROWNUM = 1
      UNION
        select 'Y'
            from tsl_itemdesc_sel
         where item = I_item
             and ROWNUM = 1
      UNION
        select 'Y'
            from tsl_itemdesc_till
         where item = I_item
             and ROWNUM = 1;
-- NBS004633, John Alister Anand, 22-Jan-2008, END

   cursor C_CHECK_DOCS is
      select 'Y'
        from req_doc
       where module      = 'IT'
         and key_value_1 = I_item;

   cursor C_CHECK_HTS is
      select 'Y'
        from item_hts
       where item = I_item;

   cursor C_CHECK_EXPENSE is
      select 'Y'
        from item_exp_head
       where item = I_item;

   cursor C_CHECK_TIMELINE is
      select 'Y'
        from timeline
       where timeline_type = 'IT'
         and key_value_1   = I_item;

   cursor C_CHECK_IMAGE is
      select 'Y'
        from item_image
       where item = I_item
       and ROWNUM = 1;

   cursor C_CHECK_SUB_TR is
   select 'Y'
     from item_master
    where tran_level < item_level
      and (item_parent            = I_item
              or item_grandparent = I_item);

   cursor C_CHECK_DIMS is
      select 'Y'
        from item_supp_country_dim
       where dim_object = 'CA'
         and item       = I_item;

   cursor C_CHECK_BRACKET_SUPPLIER is
      select 'Y'
        from item_supp_country_bracket_cost
       where nvl(unit_cost,0) = 0
         and item             = I_item;

   cursor C_CHECK_FOR_CC is
      select 'Y'
        from cost_susp_sup_head ch,
             cost_susp_sup_detail cd,
             sups,
             item_supplier its
       where ch.status in ('W','S','A','R')
         and ch.reason in (1,2,3)
         and ch.cost_change_origin    = 'SUP'
         and cd.cost_change           = ch.cost_change
         and its.supplier             = cd.supplier
         and sups.bracket_costing_ind = 'Y'
         and its.supplier             = sups.supplier
         and its.item                 = cd.item
         and its.item                 = I_item
   UNION ALL
      select 'Y'
        from cost_susp_sup_head ch,
             cost_susp_sup_detail_loc cdl,
             sups,
             item_supplier its
       where ch.status in ('W','S','A','R')
         and ch.reason in (1,2,3)
         and ch.cost_change_origin    = 'SUP'
         and cdl.cost_change          = ch.cost_change
         and its.supplier             = cdl.supplier
         and sups.bracket_costing_ind = 'Y'
         and its.supplier             = sups.supplier
         and its.item                 = cdl.item
         and its.item                 = I_item;

   cursor C_DEPT_INFO is
      select purchase_type
        from deps
       where dept = L_item_master_rec.dept;


   cursor C_XFORM_EXISTS is
      select 'Y'
        from item_xform_head
       where head_item = L_item_master_rec.item
         and ROWNUM    = 1;

   -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 22-May-2009 , Begin
   cursor C_CHECK_ITEMA_EXISTS is
      select mhd.required_ind
        from merch_hier_default mhd
       where mhd.info     = 'ITEMA'
         and mhd.dept     = L_item_master_rec.dept
         and mhd.class    = L_item_master_rec.class
         and mhd.subclass = L_item_master_rec.subclass;
   -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 22-May-2009 , End
   ---
   -- 26-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   CURSOR C_GET_SEC_IND is
   select tsl_loc_sec_ind
     from system_options;
   -- 26-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   -- 14-Sep-2010, DefNBS019152, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   CURSOR C_STYLE_REF_IND is
   select tsl_style_ref_ind
     from system_options;
   -- 14-Sep-2010, DefNBS019152, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   -- DefNBS016764, 07-Apr-2010, Govindarajan K, Begin
   L_base_desc              ITEM_MASTER.ITEM_DESC%TYPE;
   L_base_status            ITEM_MASTER.STATUS%TYPE;
   L_base_item_lvl          ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_base_tran_lvl          ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_variant                BOOLEAN := FALSE;
   -- DefNBS016764, 07-Apr-2010, Govindarajan K, End
   -- 12-Jul-2010, CR288C, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
   -- 12-Jul-2010, CR288C, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   L_valid_supp_uk          VARCHAR2(1);
   L_valid_supp_roi         VARCHAR2(1);
   -- 12-Jul-2010, CR288C, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
   -- 12-Jul-2010, CR288C, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   -- 26-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   L_loc_sec_ind           SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE := 'N';
   -- 26-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   -- 14-Sep-2010, DefNBS019152, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   L_style_ref_ind         SYSTEM_OPTIONS.TSL_STYLE_REF_IND%TYPE := 'N';
   L_sub_style_ref_ind     SYSTEM_OPTIONS.TSL_STYLE_REF_IND%TYPE := 'N';
   L_merch_ind             SUBCLASS.TSL_MERCH_IND%TYPE;
   L_unit_qty              SUBCLASS.TSL_UNIT_QUANTITY%TYPE;
   -- 14-Sep-2010, DefNBS019152, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---

BEGIN
   O_approved := TRUE;
   ---
   delete from item_approval_error
    where item = I_item
      and override_ind = 'N';
   ---

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master_rec,
                                      I_item) = FALSE then

      return FALSE;
   end if;

   --25-Aug-2009      Wipro/JK      CR236    Begin
   SQL_LIB.SET_MARK('OPEN','C_SINGLE_INSTANCE','system_options: '||NULL,  NULL);
   open C_SINGLE_INSTANCE;
   SQL_LIB.SET_MARK('FETCH','C_SINGLE_INSTANCE','system_options: '||NULL, NULL);
   fetch C_SINGLE_INSTANCE into L_tsl_single_instance;
   SQL_LIB.SET_MARK('CLOSE','C_SINGLE_INSTANCE','system_options: '||NULL, NULL);
   close C_SINGLE_INSTANCE;
   --25-Aug-2009      Wipro/JK      CR236    End
   ----------------------------------------------------------------------------
   --- ALL ITEM LEVELS
   ----------------------------------------------------------------------------
   --- if I_new_status is 'A' and current item status = 'W' item can't be approved.

   if I_new_status = 'A' and L_item_master_rec.status = 'W' then

      if INSERT_ERROR(O_error_message,
                      I_item,
                      'IT_NO_APPROVE',
                      'Y',
                      'N') = FALSE then
         return FALSE;
      end if;
      O_approved := FALSE;
   end if;

   -- Begin ModN115,116,117 Wipro/JK 20-Feb-2008
   if L_item_master_rec.pack_ind = 'Y' and L_item_master_rec.simple_pack_ind = 'N' and
      L_item_master_rec.pack_type = 'V' and L_item_master_rec.item_level = 1 then
      if TSL_PACK_CHECK(O_error_message,
                        L_flg,
                        I_item) = FALSE then

         return FALSE;
      end if;

      if L_flg = 'N' then
         if INSERT_ERROR(O_error_message,
                         I_item,
                         'TSL_NO_PACK',
                         'Y',
                         'N') = FALSE then
            return FALSE;
         end if;
         O_approved := FALSE;
      end if;
   end if;
   -- End ModN115,116,117 Wipro/JK 20-Feb-2008


   --- Get the status of the parent
   if I_parent_status is NULL then
      --- Fetch the status of the parent
      SQL_LIB.SET_MARK('OPEN','C_GET_PARENT_STATUS','item_parent: '||L_item_parent,NULL);
      open C_GET_PARENT_STATUS;
      SQL_LIB.SET_MARK('FETCH','C_GET_PARENT_STATUS','item_parent: '||L_item_parent,NULL);
      fetch C_GET_PARENT_STATUS into L_parent_status;
      SQL_LIB.SET_MARK('CLOSE','C_GET_PARENT_STATUS','item_parent: '||L_item_parent,NULL);
      close C_GET_PARENT_STATUS;
      --- If no parent exists (level 1 item) then set status to A so processing can continue

      if L_parent_status is NULL then
         L_parent_status := 'A';
      end if;
      ---
   else
      L_parent_status := I_parent_status;
   end if;
   --- If parent status is below child status then write to errors table;
   --- child status can't pass parent status
   if I_new_status = 'S' and L_parent_status not in ('A','S') then

      -- NBS00015011, 12-Oct-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
      if L_item_master_rec.simple_pack_ind = 'Y' and L_item_master_rec.pack_ind = 'Y' and
       L_item_master_rec.Item_Level = L_item_master_rec.Tran_Level then
         --
         if NOT INSERT_ERROR(O_error_message,
                             I_item,
                             'TSL_IT_COMP_NOT_S',
                             'Y',
                             'N') then
            return FALSE;
         end if;
         --
      else
      -- NBS00015011, 12-Oct-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
         if INSERT_ERROR(O_error_message,
                         I_item,
                         'IT_PARENT_NOT_S',
                         'Y',
                         'N') = FALSE then
            return FALSE;
         end if;
      -- NBS00015011, 12-Oct-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
      end if;
      -- NBS00015011, 12-Oct-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
      O_approved := FALSE;
   elsif I_new_status = 'A' and L_parent_status != 'A' then
      if INSERT_ERROR(O_error_message,
                      I_item,
                      'IT_PARENT_NOT_A',
                      'Y',
                      'N') = FALSE then
         return FALSE;
      end if;
      O_approved := FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_DEPT_INFO',I_item,NULL);
   open C_DEPT_INFO;
   SQL_LIB.SET_MARK('FETCH','C_DEPT_INFO',I_item,NULL);
   fetch C_DEPT_INFO into L_purchase_type;
   SQL_LIB.SET_MARK('CLOSE','C_DEPT_INFO',I_item,NULL);
   close C_DEPT_INFO;

   if L_item_master_rec.catch_weight_ind = 'Y' then
      if L_item_master_rec.sale_type is NULL and L_item_master_rec.sellable_ind = 'Y' then



         if INSERT_ERROR(O_error_message,
                         I_item,
                         'IT_CWITEM_NO_SALE_TYPE',
                         'Y',
                         'N') = FALSE then
            return FALSE;

         end if;
         O_approved := FALSE;
      end if;
      if L_item_master_rec.order_type is NULL then



         if INSERT_ERROR(O_error_message,
                         I_item,
                         'IT_CWITEM_NO_ORDER_TYPE',
                         'Y',
                         'N') = FALSE then
            return FALSE;

         end if;
         O_approved := FALSE;
      end if;
   end if; -- catchweight_ind chk
   ----------------------------------------------------------------------------
   --- XFORM ITEMS
   ----------------------------------------------------------------------------

   if L_item_master_rec.item_xform_ind = 'Y'
      and L_item_master_rec.orderable_ind = 'Y'
      and L_item_master_rec.tran_level = L_item_master_rec.item_level then

      SQL_LIB.SET_MARK('OPEN','C_XFORM_EXISTS','item: '||L_item_master_rec.item,NULL);
      open C_XFORM_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_XFORM_EXISTS','item: '||L_item_master_rec.item,NULL);
      fetch C_XFORM_EXISTS into L_sellable_exists;
      SQL_LIB.SET_MARK('CLOSE','C_XFORM_EXISTS','item: '||L_item_master_rec.item,NULL);
      close C_XFORM_EXISTS;

      if L_sellable_exists != 'Y' then



         if INSERT_ERROR(O_error_message,
                         I_item,
                         'IT_ORDITEM_NO_SELL_DATA',
                         'Y',
                         'N') = FALSE then
            return FALSE;

         end if;
         O_approved := FALSE;
      end if;
   end if;




   if L_item_master_rec.orderable_ind = 'Y' or
      L_item_master_rec.deposit_item_type in ('E', 'A') or-- Contents item, Container item
      L_purchase_type in ('1','2')
      then

      if SUPP_ITEM_SQL.EXIST(O_error_message,
                             L_supp_exists,
                             I_item) = FALSE then
         return FALSE;
      end if;
      if L_supp_exists = FALSE then
         if INSERT_ERROR(O_error_message,
                         I_item,
                         'IT_NO_SUPP',
                         'Y',
                         'N') = FALSE then
            return FALSE;
         end if;
         O_approved := FALSE;
      end if;
   end if;

   if L_item_master_rec.sellable_ind ='Y' then

      if PM_RETAIL_API_SQL.CHECK_RETAIL_EXISTS( O_ERROR_MESSAGE,
                                                L_unit_retail_exists,
                                                I_item) = FALSE then
         return FALSE;
      end if;

      if L_unit_retail_exists = 'N' then

        if L_item_master_rec.item_parent is null and L_item_master_rec.item_grandparent is null then

            if INSERT_ERROR(O_error_message,
                            I_item,
                            'IT_NO_UNITRETAIL',
                            'Y',
                            'N') = FALSE then
               return FALSE;
            end if;
            O_approved := FALSE;
      end if;
      end if;
   end if;
     -- Begin mod N22 on 18-Sep-07
     SQL_LIB.SET_MARK('OPEN',
                      'C_CHECK_PRODUCT_AUTH',
                      'SYSTEM_OPTIONS',
                      NULL);
     open C_CHECK_PRODUCT_AUTH;
     SQL_LIB.SET_MARK('FETCH',
                      'C_CHECK_PRODUCT_AUTH',
                      'SYSTEM_OPTIONS',
                      NULL);
     fetch C_CHECK_PRODUCT_AUTH into L_tsl_product_auth;
     SQL_LIB.SET_MARK('CLOSE',
                      'C_CHECK_PRODUCT_AUTH',
                      'SYSTEM_OPTIONS',
                      NULL);
     close C_CHECK_PRODUCT_AUTH;
     -- If the tsl_product_auth is 'Y' in the system_options table then
     -- get all the indiccators for N22.
     if L_tsl_product_auth = 'Y' then
            if MERCH_DEFAULT_SQL.TSL_GET_REQ_INDS(O_error_message,
                                                  L_tslsca_req_ind, --20-Nov-2007 Wipro/JK DefNBS004095
                                                  L_lschld_req_ind,
                                                  L_spstup_req_ind,
                                                  L_tocc_req_ind,
                                                  L_tret_req_ind,
                                                  -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
                                                  --CR347, 25-Jul-2010, Sripriya, Sripriya.karanam@in.tesco.com, Begin
                                                  L_tsocc_req_ind,
                                                  L_tsret_req_ind,
                                                  --CR347, 25-Jul-2010, Sripriya, Sripriya.karanam@in.tesco.com, End
                                                  -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
                                                  L_item_master_rec.dept,
                                                  L_item_master_rec.class,
                                                  L_item_master_rec.subclass) = FALSE then
                 return FALSE;
            end if;
      LP_tocc_req_ind := L_tocc_req_ind; --09-JAN-2008  Wipro/JK  DefNBS00004546
            -- Check if the item is a launch base item.
            if TSL_BASE_VARIANT_SQL.LAUNCH_BASE_IND_EXISTS(O_error_message,
                                                           O_exists,
                                                           I_item) = FALSE then
                 return FALSE;
            else
                 L_tsl_launch_base_ind := O_exists;
            end if;

            -- Check if this pack is created from the place holder.
            if L_item_master_rec.pack_ind = 'Y' then
                 if TSL_BASE_VARIANT_SQL.SIMPLE_PACK_LAUNCH_EXISTS(O_error_message,
                                                                   O_exists,
                                                                   I_item) = FALSE then
                        return FALSE;
                 else
                        L_tsl_launch_base_ind := O_exists;
                 end if;
            end if;
     end if;
     -- End mod N22 on 18-Sep-07
   ----------------------------------------------------------------------------
   --- SUB-TRANSACTION LEVEL
   ----------------------------------------------------------------------------
   if L_item_master_rec.tran_level < L_item_master_rec.item_level then
      --- Check for supplier records if item is not a pack, or if it is a pack
      --- and it is orderable
      if L_item_master_rec.orderable_ind = 'Y' then
         --- Check that item supplier records exist
         if SUPP_ITEM_SQL.EXIST(O_error_message,
                                L_supp_exists,
                                I_item) = FALSE then
            return FALSE;
         end if;
         ---
         if L_supp_exists = FALSE then
            if INSERT_ERROR(O_error_message,
                            I_item,
                            'IT_NO_SUPP',
                            'Y',
                            'N') = FALSE then
               return FALSE;
            end if;
            O_approved := FALSE;
         end if;
      end if;
            -- Begin mod N22 on 18-Sep-07
            -- Check if tsl_product_auth is 'Y'.
            if L_tsl_product_auth = 'Y' then
              -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
               --CR347, 25-Jul-2010, Sripriya, Sripriya.karanam@in.tesco.com, Begin
               ----find the code_type ----
               if ITEM_ATTRIB_DEFAULT_SQL.TSL_GET_CODE_TYPE(O_error_message,
                                                             L_code_type,
                                                             L_item_master_rec.item_number_type) = FALSE then
                  return FALSE;
               end if;
               ----find the code_type-----
               if L_code_type = 'TSBO' then
               --CR347, 25-Jul-2010, Sripriya, Sripriya.karanam@in.tesco.com, End
               -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
                 -- OCCs
                 -- Check if the item is a pack item and the OCC ind in merch hier is 'Y'
                 if L_tocc_req_ind = 'Y' and L_item_master_rec.pack_ind = 'Y' and L_tsl_launch_base_ind = FALSE then
                        -- Check if the OCC exists for the item.
                        if ITEM_ATTRIB_SQL.TSL_OCC_EXIST(O_error_message,
                                                         L_tocc_subtrans_exists,
                                                         I_item) = FALSE then
                             return FALSE;
                        end if;
                        -- If OCC does not exist then write the error into item_approval_error table.
                        -- UAT Defect NBS00011868, Nitin Kumar, nitin.kumar@in.tesco.com, 13-Apr-2009, Begin
                        -- Avoid checking the OCC required if item number type is equal to
                        -- system_option.tsl_ratio_pack_number_type and is a complex pack
                        if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                                                 L_system_options_rec) = FALSE then
                           return FALSE;
                        end if;
                        if L_item_master_rec.simple_pack_ind = 'N' and
                           L_item_master_rec.pack_type       = 'V' and
                           L_system_options_rec.tsl_ratio_pack_number_type = L_item_master_rec.item_number_type then
                           L_tocc_subtrans_exists := TRUE;
                        end if;
                        --UAT Defect NBS00011868, Nitin Kumar, nitin.kumar@in.tesco.com, 13-Apr-2009, End
                        -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                        if L_tocc_subtrans_exists = TRUE then
                          ITEM_APPROVAL_SQL_FIX.G_occ_subtran_exist := TRUE;
                        elsif L_tocc_subtrans_exists = FALSE then
                          ITEM_APPROVAL_SQL_FIX.G_occ_subtran_exist := FALSE;
                        end if;
                        -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
                        if L_tocc_subtrans_exists = FALSE then
                             SQL_LIB.SET_MARK('INSERT',
                                              NULL,
                                              'ITEM_APPROVAL_ERROR',
                                              'Error Key: TSL_IT_NO_TOCC');
                             insert into item_approval_error (item,
                                                              error_key,
                                                              system_req_ind,
                                                              override_ind,
                                                              last_update_id,
                                                              last_update_datetime)
                                                                             (select I_item,
                                                                                     'TSL_IT_NO_TOCC',
                                                                                     -- UAT NBS00014479, 12-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
                                                                                     'Y',
                                                                                     -- UAT NBS00014479, 12-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
                                                                                     'N',
                                                                                     USER,
                                                                                     SYSDATE
                                                                                from dual
                                                                               where not exists (select 'x'
                                                                                                  from item_approval_error
                                                                                                 where item = I_item
                                                                                                   and error_key = 'TSL_IT_NO_TOCC'
                                                                                                   -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                                                   and system_req_ind = 'Y'));
                                                                                                   -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                             if SQL%FOUND then
                                    O_approved := FALSE;
                             end if;
                        end if;
                 end if;

              -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
              --CR347, 25-Jul-2010, Sripriya, Sripriya.karanam@in.tesco.com, BEGIN
              elsif L_code_type = 'NTBO' then
              --to chk for TSOCC ind
              -------------------------------------------------------------------------------------------
                 if L_tsocc_req_ind = 'Y' and L_item_master_rec.pack_ind = 'Y' and L_tsl_launch_base_ind = FALSE then
                    -- Check if the OCC exists for the item.
                    if ITEM_ATTRIB_SQL.TSL_OCC_EXIST(O_error_message,
                                                     L_tocc_subtrans_exists,
                                                     I_item) = FALSE then
                       return FALSE;
                    end if;
                    -- If OCC does not exist then write the error into item_approval_error table.
                    -- Avoid checking the OCC required if item number type is equal to
                    -- system_option.tsl_ratio_pack_number_type and is a complex pack
                    if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                                             L_system_options_rec) = FALSE then
                       return FALSE;
                    end if;
                    if L_item_master_rec.simple_pack_ind = 'N' and
                       L_item_master_rec.pack_type       = 'V' and
                       L_system_options_rec.tsl_ratio_pack_number_type = L_item_master_rec.item_number_type then
                       L_tocc_subtrans_exists := TRUE;
                    end if;

                    if L_tocc_subtrans_exists = TRUE then
                       ITEM_APPROVAL_SQL_FIX.G_occ_subtran_exist := TRUE;
                    elsif L_tocc_subtrans_exists = FALSE then
                       ITEM_APPROVAL_SQL_FIX.G_occ_subtran_exist := FALSE;
                    end if;

                    if L_tocc_subtrans_exists = FALSE then
                       SQL_LIB.SET_MARK('INSERT',
                                        NULL,
                                        'ITEM_APPROVAL_ERROR',
                                        'Error Key: TSL_IT_NO_TOCC');
                       insert into item_approval_error (item,
                                                        error_key,
                                                        system_req_ind,
                                                        override_ind,
                                                        last_update_id,
                                                        last_update_datetime)
                                                                      (select I_item,
                                                                              'TSL_IT_NO_TOCC',
                                                                              'Y',
                                                                              'N',
                                                                              USER,
                                                                              SYSDATE
                                                                         from dual
                                                                        where not exists (select 'x'
                                                                         from item_approval_error
                                                                        where item = I_item
                                                                          and error_key = 'TSL_IT_NO_TOCC'
                                                                          and override_ind = 'Y'));
                       if SQL%FOUND then
                          O_approved := FALSE;
                       end if;
                    end if;
                 end if;  -----end for tsocc req ind
              end if;
              ---check for Retail barcode auth ind-----
               if L_code_type = 'TSBE' then
               --CR347, 25-Jul-2010, Sripriya, Sripriya.karanam@in.tesco.com, End
               -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
                 -- Check if the item is not a pack and its retail barcode req ind is 'Y'.
                 if L_tret_req_ind = 'Y' and L_item_master_rec.pack_ind = 'N' then
                  --09-Nov-2009 Tesco HSC/Usha Patil              Mod: CR213 Begin
                    if ITEM_APPROVAL_SQL_FIX.TSL_CHECK_TBAN(O_error_message,
                                                        L_tban_type,
                                                        L_item_master_rec.item_number_type) = FALSE then
                       return FALSE;
                    end if;
                    if L_tban_type = 'N' then
                  --09-Nov-2009 Tesco HSC/Usha Patil              Mod: CR213 End
                        --Check if the retail barcode exists for this item
                        if ITEM_ATTRIB_SQL.TSL_RET_EXIST(O_error_message,
                                                         L_tret_subtrans_exists,
                                                         I_item) = FALSE then
                             return FALSE;
                        end if;

                        -- If retail barcode does not exist then write the error in the item_approval_error table.
                        if L_tret_subtrans_exists = FALSE then
                             SQL_LIB.SET_MARK('INSERT',
                                              NULL,
                                              'ITEM_APPROVAL_ERROR',
                                              ' Error Key: TSL_IT_NO_TRET');
                             insert into item_approval_error (item,
                                                              error_key,
                                                              system_req_ind,
                                                              override_ind,
                                                              last_update_id,
                                                              last_update_datetime)
                                                                                (select I_item,
                                                                                        'TSL_IT_NO_TRET',
                                                                                        -- UAT NBS00014479, 12-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
                                                                                        'Y',
                                                                                        -- UAT NBS00014479, 12-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (End)
                                                                                        'N',
                                                                                        USER,
                                                                                        SYSDATE
                                                                                   from dual
                                                                                  where not exists (select 'x'
                                                                                                      from item_approval_error
                                                                                                     where item = I_item
                                                                                                       and error_key = 'TSL_IT_NO_TRET'
                                                                                                       and override_ind = 'Y'));
                             if SQL%FOUND then
                                    O_approved := FALSE;
                             end if;
                        end if;
                    --09-Nov-2009 Tesco HSC/Usha Patil              Mod: CR213 Begin
                    end if;
                    --09-Nov-2009 Tesco HSC/Usha Patil              Mod: CR213 End
                 end if; --end for tret req ind
                  -------------Find retail ind ------------
               -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
               --CR347, 22-Jul-2010, Sripriya, Sripriya.karanam@in.tesco.com, Begin
               elsif L_code_type = 'NTBE' then
                  if L_tsret_req_ind = 'Y' and L_item_master_rec.pack_ind = 'N' then

                     if ITEM_APPROVAL_SQL_FIX.TSL_CHECK_TBAN(O_error_message,
                                                         L_tban_type,
                                                         L_item_master_rec.item_number_type) = FALSE then
                        return FALSE;
                     end if;
                     if L_tban_type = 'N' then

                     --Check if the retail barcode exists for this item
                        if ITEM_ATTRIB_SQL.TSL_RET_EXIST(O_error_message,
                                                         L_tret_subtrans_exists,
                                                         I_item) = FALSE then
                           return FALSE;
                        end if;

                        -- If retail barcode does not exist then write the error in the item_approval_error table.
                        if L_tret_subtrans_exists = FALSE then
                           SQL_LIB.SET_MARK('INSERT',
                                            NULL,
                                            'ITEM_APPROVAL_ERROR',
                                            ' Error Key: TSL_IT_NO_TRET');
                           insert into item_approval_error (item,
                                                            error_key,
                                                            system_req_ind,
                                                            override_ind,
                                                            last_update_id,
                                                            last_update_datetime)
                                                                                (select I_item,
                                                                                        'TSL_IT_NO_TRET',
                                                                                        'Y',
                                                                                        'N',
                                                                                        USER,
                                                                                        SYSDATE
                                                                                   from dual
                                                                                  where not exists (select 'x'
                                                                                                      from item_approval_error
                                                                                                     where item = I_item
                                                                                                       and error_key = 'TSL_IT_NO_TRET'
                                                                                                       and override_ind = 'Y'));
                           if SQL%FOUND then
                              O_approved := FALSE;
                           end if;
                        end if;

                     end if;

                  end if; --end for tsret req ind
               end if; --end for Code_type
                ------------Find retail ind --------
                --CR347, 25-Jul-2010, Sripriya, Sripriya.karanam@in.tesco.com, End
                -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
            end if;  --end for tsl product auth system option

            -- End mod N22 on 18-Sep-07
            -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com ,22-May-2009 ,Begin
            SQL_LIB.SET_MARK('OPEN','C_CHECK_ITEMA_EXISTS',I_item,NULL);
            open C_CHECK_ITEMA_EXISTS;
            SQL_LIB.SET_MARK('FETCH','C_CHECK_ITEMA_EXISTS',I_item,NULL);
            fetch C_CHECK_ITEMA_EXISTS into L_new_itattrib_req_ind;
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEMA_EXISTS',I_item,NULL);
            close C_CHECK_ITEMA_EXISTS;
            if L_new_itattrib_req_ind = 'Y' then
               --26-Aug-2009   Wipro/JK    CR236   Begin
               if L_tsl_single_instance = 'Y' then
                  --12-May-2010 Murali  Cr288b Begin
                  -- Modifed the cursor as Launch date is not available for EAN and OCC
                  SQL_LIB.SET_MARK('OPEN','C_UKROI_CHECK_ATTR_EAN_OCC',I_item,NULL);
                  open C_UKROI_CHECK_ATTR_EAN_OCC('U');
                  SQL_LIB.SET_MARK('FETCH','C_UKROI_CHECK_ATTR_EAN_OCC',I_item,NULL);
                  fetch C_UKROI_CHECK_ATTR_EAN_OCC into L_itattrib_exists;
                  SQL_LIB.SET_MARK('CLOSE','C_UKROI_CHECK_ATTR_EAN_OCC',I_item,NULL);
                  close C_UKROI_CHECK_ATTR_EAN_OCC;
                  -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 15-Feb-2010 Begin
                  -- Removed code
                  -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 15-Feb-2010 End

                  SQL_LIB.SET_MARK('OPEN','C_UKROI_CHECK_ATTR_EAN_OCC',I_item,NULL);
                  open C_UKROI_CHECK_ATTR_EAN_OCC('R');
                  SQL_LIB.SET_MARK('FETCH','C_UKROI_CHECK_ATTR_EAN_OCC',I_item,NULL);
                  fetch C_UKROI_CHECK_ATTR_EAN_OCC into L_roi_itattrib_exists;
                  SQL_LIB.SET_MARK('CLOSE','C_UKROI_CHECK_ATTR_EAN_OCC',I_item,NULL);
                  close C_UKROI_CHECK_ATTR_EAN_OCC;
                  -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
                  -- Removed code
                  -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
                  --12-May-2010 Murali  Cr288b End
               else
               --26-Aug-2009   Wipro/JK    CR236   End
                  SQL_LIB.SET_MARK('OPEN','C_CHECK_ITATTRIB',I_item,NULL);
                  open C_CHECK_ITATTRIB;
                  SQL_LIB.SET_MARK('FETCH','C_CHECK_ITATTRIB',I_item,NULL);
                  fetch C_CHECK_ITATTRIB into L_itattrib_exists;
                  SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITATTRIB',I_item,NULL);
                  close C_CHECK_ITATTRIB;
                  if L_itattrib_exists = 'N' then
                     insert into item_approval_error
                                (item,
                                 error_key,
                                 system_req_ind,
                                 override_ind,
                                 last_update_id,
                                last_update_datetime)
                          select I_item,
                                 'IT_NO_ATTRIB',
                                 'N',
                                 'N',
                                 user,
                                 sysdate
                            from dual
                           where not exists (select 'x'
                                        from item_approval_error
                                       where item = I_item
                                         and error_key = 'IT_NO_ATTRIB'
                                         and override_ind = 'Y');
                     if SQL%FOUND then
                        O_approved := FALSE;
                     end if;
                  end if;
               --26-Aug-2009   Wipro/JK    CR236   Begin
               end if;
               --26-Aug-2009   Wipro/JK    CR236   End
            end if;
            --26-Aug-2009   Wipro/JK    CR236   Begin
            if L_tsl_single_instance = 'Y' then
               if MERCH_DEFAULT_SQL.TSL_GET_REQD_ATTR(O_error_message,
                                                      L_new_attrib_req_exists,
                                                      -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 15-Feb-2010 Begin
                                                      L_new_roi_itattrib_exists,
                                                      -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 15-Feb-2010 End
                                                      I_item,
                                                      L_item_master_rec.dept,
                                                      L_item_master_rec.class,
                                                      L_item_master_rec.subclass) =  FALSE then
                     return FALSE;
               end if;

               -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
              if L_itattrib_exists = 'Y' then
              -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
                 if L_new_attrib_req_exists = 'N' then
                    SQL_LIB.SET_MARK('INSERT',
                                     NULL,
                                     'ITEM_APPROVAL_ERROR',
                                     ' Error Key: IT_NO_ATTRIB_CTRY@UK');
                    insert into item_approval_error(item,
                                                    error_key,
                                                    system_req_ind,
                                                    override_ind,
                                                    last_update_id,
                                                    last_update_datetime)
                                            select I_item,
                                                   'IT_NO_ATTRIB_CTRY@UK',
                                                   'N',
                                                   'N',
                                                   user,
                                                   sysdate
                                              from dual
                                              where not exists (select 'x'
                                                                  from item_approval_error
                                                                 where item = I_item
                                                                   and error_key = 'IT_NO_ATTRIB_CTRY@UK'
                                                                   and override_ind = 'Y');
                                               if SQL%FOUND then
                                                  O_approved := FALSE;
                                               end if;
                 end if;
              -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
              -- DefNBS016999, 28-Apr-2010, Govindarajan K, Begin
              -- commented the following code to approve an item if atleast on item attributes is complete.
              -- end if;
              elsif L_roi_itattrib_exists = 'Y' then
              -- DefNBS016999, 28-Apr-2010, Govindarajan K, End
              -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
                 if L_new_roi_itattrib_exists = 'N' then
                    SQL_LIB.SET_MARK('INSERT',
                                     NULL,
                                     'ITEM_APPROVAL_ERROR',
                                     ' Error Key: IT_NO_ATTRIB_CTRY@ROI');
                    insert into item_approval_error(item,
                                                    error_key,
                                                    system_req_ind,
                                                    override_ind,
                                                    last_update_id,
                                                    last_update_datetime)
                                            select I_item,
                                                   'IT_NO_ATTRIB_CTRY@ROI',
                                                   'N',
                                                   'N',
                                                   user,
                                                   sysdate
                                              from dual
                                              where not exists (select 'x'
                                                                  from item_approval_error
                                                                 where item = I_item
                                                                   and error_key = 'IT_NO_ATTRIB_CTRY@ROI'
                                                                   and override_ind = 'Y');
                                               if SQL%FOUND then
                                                  O_approved := FALSE;
                                               end if;
                 end if;
              -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
              end if;
              ---DefNBS016489 Tarun Kumar Mishra tarun.mishra@in.tesco.com 02-March-2010 Begin
              if L_new_itattrib_req_ind = 'Y' then
              ---DefNBS016489 Tarun Kumar Mishra tarun.mishra@in.tesco.com 02-March-2010 End
                 if L_itattrib_exists = 'N' and L_roi_itattrib_exists = 'N' then
                    SQL_LIB.SET_MARK('INSERT',
                                     NULL,
                                     'ITEM_APPROVAL_ERROR',
                                     ' Error Key: IT_NO_ATTRIB_CTRY@UK');
                    insert into item_approval_error(item,
                                                    error_key,
                                                    system_req_ind,
                                                    override_ind,
                                                    last_update_id,
                                                    last_update_datetime)
                                            select I_item,
                                                   'IT_NO_ATTRIB_CTRY@UK',
                                                   'N',
                                                   'N',
                                                   user,
                                                   sysdate
                                              from dual
                                              where not exists (select 'x'
                                                                  from item_approval_error
                                                                 where item = I_item
                                                                   and error_key = 'IT_NO_ATTRIB_CTRY@UK'
                                                                   and override_ind = 'Y');
                                               if SQL%FOUND then
                                                  O_approved := FALSE;
                                               end if;

                    SQL_LIB.SET_MARK('INSERT',
                                     NULL,
                                     'ITEM_APPROVAL_ERROR',
                                     ' Error Key: IT_NO_ATTRIB_CTRY@ROI');

                    insert into item_approval_error(item,
                                                    error_key,
                                                    system_req_ind,
                                                    override_ind,
                                                    last_update_id,
                                                    last_update_datetime)
                                            select I_item,
                                                   'IT_NO_ATTRIB_CTRY@ROI',
                                                   'N',
                                                   'N',
                                                   user,
                                                   sysdate
                                              from dual
                                              where not exists (select 'x'
                                                                  from item_approval_error
                                                                 where item = I_item
                                                                   and error_key = 'IT_NO_ATTRIB_CTRY@ROI'
                                                                   and override_ind = 'Y');
                                               if SQL%FOUND then
                                                  O_approved := FALSE;
                                               end if;


                 end if;
              ---DefNBS016489 Tarun Kumar Mishra tarun.mishra@in.tesco.com 02-March-2010 Begin
              end if;
              ---DefNBS016489 Tarun Kumar Mishra tarun.mishra@in.tesco.com 02-March-2010 End
              -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
            else
            --26-Aug-2009   Wipro/JK    CR236   End
               if MERCH_DEFAULT_SQL.TSL_GET_REQD_ATTR(O_error_message,
                                                      L_new_attrib_req_exists,
                                                      I_item,
                                                      L_item_master_rec.dept,
                                                      L_item_master_rec.class,
                                                      L_item_master_rec.subclass) =  FALSE then
                     return FALSE;
               end if;

               if L_new_attrib_req_exists = 'N' then
                  insert into item_approval_error(item,
                                                  error_key,
                                                  system_req_ind,
                                                  override_ind,
                                                  last_update_id,
                                                  last_update_datetime)
                                            select I_item,
                                                   'IT_NO_ATTRIB',
                                                   'N',
                                                   'N',
                                                   user,
                                                   sysdate
                                              from dual
                                              where not exists (select 'x'
                                                                  from item_approval_error
                                                                 where item = I_item
                                                                   and error_key = 'IT_NO_ATTRIB'
                                                                   and override_ind = 'Y');
                                               if SQL%FOUND then
                                                  O_approved := FALSE;
                                               end if;
               end if;
            --26-Aug-2009   Wipro/JK    CR236   Begin
            end if;
            --26-Aug-2009   Wipro/JK    CR236   End
            -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com ,22-May-2009 ,End
   else
   ----------------------------------------------------------------------------
   --- TRANSACTION LEVEL
   ----------------------------------------------------------------------------
      if L_item_master_rec.tran_level = L_item_master_rec.item_level then
        -----------------------------------------------------------------------
        ---ModN111 Chandru N Begin
        if TSL_BASE_VARIANT_SQL.VALIDATE_VARIANT_ITEM(O_error_message,
                                                      L_exists,
                                                      I_item) = FALSE then
          return FALSE;
        end if;
        if L_exists then
          if TSL_BASE_VARIANT_SQL.GET_BASE_ITEM_STATUS(O_error_message,
                                                       L_status,
                                                       I_item) = FALSE then
            return FALSE;
          end if;

          if I_new_status = 'S' and
            L_status not in ('A', 'S') and NOT ITEM_APPROVAL_SQL_FIX.G_base_approved then
            if INSERT_ERROR(O_error_message,
                            I_item,
                            'TSL_BASE_NOT_SUBAPP',
                            'Y',
                            'N') = FALSE then
              return FALSE;
            end if;
            O_approved := FALSE;
          else
            if I_new_status = 'A' and
               L_status <> 'A' and NOT ITEM_APPROVAL_SQL_FIX.G_base_approved then
              if INSERT_ERROR(O_error_message,
                              I_item,
                              'TSL_BASE_NOT_APP',
                              'Y',
                              'N') = FALSE then
                return FALSE;
              end if;
             O_approved := FALSE;
            end if;
          end if;
          --12-May-2010 Murali  Cr288b Begin
          if ITEM_ATTRIB_SQL.TSL_GET_ITEM_CTRY_IND(O_error_message,
                                                   I_item,
                                                   L_var_country_auth) = FALSE then
             return FALSE;
          end if;
          if ITEM_ATTRIB_SQL.TSL_GET_ITEM_CTRY_IND(O_error_message,
                                                   L_item_master_rec.Tsl_Base_Item,
                                                   L_base_country_auth) = FALSE then
             return FALSE;
          end if;
          --20-May-2010 Murali  DefNBS017560 Begin
          if L_var_country_auth <> L_base_country_auth and
               L_var_country_auth is not null and L_base_country_auth is not null then
             if L_var_country_auth = 'U' and L_base_country_auth = 'R' then
                L_error_key := 'TSL_UK_VAR';
             elsif L_var_country_auth = 'R' and L_base_country_auth = 'U' then
                L_error_key := 'TSL_ROI_VAR';
             elsif L_var_country_auth = 'B' and L_base_country_auth <> 'B' then
                L_error_key := 'TSL_UKROI_VAR';
             elsif L_var_country_auth <> 'B' and L_base_country_auth = 'B' then
                L_error_key := 'TSL_UKROI_BASE';
             end if;
          --20-May-2010 Murali  DefNBS017560 End
             if INSERT_ERROR(O_error_message,
                             I_item,
                             --20-May-2010 Murali  DefNBS017560 Begin
                             L_error_key,
                             --20-May-2010 Murali  DefNBS017560 End
                             'Y',
                             'N') = FALSE then
               return FALSE;
             end if;
             O_approved := FALSE;
          end if;
          --12-May-2010 Murali  Cr288b End
        end if; -- for l_exists
        ---ModN111 Chandru N End
        -----------------------------------------------------------------------
        -- 26-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
        SQL_LIB.SET_MARK('OPEN',
                         'C_GET_SEC_IND',
                         'SYSTEM_OPTIONS',
                         NULL);
        open C_GET_SEC_IND;
        ---
        SQL_LIB.SET_MARK('FETCH',
                         'C_GET_SEC_IND',
                         'SYSTEM_OPTIONS',
                         NULL);
        fetch C_GET_SEC_IND into L_loc_sec_ind;
        ---
        SQL_LIB.SET_MARK('CLOSE',
                         'C_GET_SEC_IND',
                         'SYSTEM_OPTIONS',
                         NULL);
        close C_GET_SEC_IND;
        ---
        -- 26-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
        --19-May-2010 Murali  Cr288b Begin
        if L_item_master_rec.tran_level = L_item_master_rec.item_level and
           L_item_master_rec.pack_ind = 'N' and
           -- 26-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
           L_loc_sec_ind = 'N' then
           -- 26-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
          /* Get country Auth Ind for L2 */
          if ITEM_ATTRIB_SQL.TSL_GET_ITEM_CTRY_IND(O_error_message,
                                                   I_item,
                                                   L_base_country_auth) =
             FALSE then
            return FALSE;
          end if;
          /* Get country Auth Ind for TPNA */
          if ITEM_ATTRIB_SQL.TSL_GET_ITEM_CTRY_IND(O_error_message,
                                                   L_item_master_rec.Item_Parent,
                                                   L_parent_country_auth) =
             FALSE then
            return FALSE;
          end if;

          if L_base_country_auth <> L_parent_country_auth and
             nvl(L_parent_country_auth, -999) <> 'B' then
            if L_parent_country_auth = 'R' then
               if INSERT_ERROR(O_error_message,
                               I_item,
                               'TSL_PARENT_CHILD_ROI_SINK',
                               'Y',
                               'N') = FALSE then
                 return FALSE;
               end if;
            else
               if INSERT_ERROR(O_error_message,
                               I_item,
                               'TSL_PARENT_CHILD_UK_SINK',
                               'Y',
                               'N') = FALSE then
                 return FALSE;
               end if;
            end if;
            O_approved := FALSE;
          end if;

        end if;
        --19-May-2010 Murali  Cr288b End
        ---
        -- 14-Sep-2010, DefNBS019152, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
        SQL_LIB.SET_MARK('OPEN',
                         'C_STYLE_REF_IND',
                         'SYSTEM_OPTIONS',
                         NULL);
        open C_STYLE_REF_IND;
        ---
        SQL_LIB.SET_MARK('FETCH',
                         'C_STYLE_REF_IND',
                         'SYSTEM_OPTIONS',
                         NULL);
        fetch C_STYLE_REF_IND into L_style_ref_ind;
        ---
        SQL_LIB.SET_MARK('CLOSE',
                         'C_STYLE_REF_IND',
                         'SYSTEM_OPTIONS',
                         NULL);
        close C_STYLE_REF_IND;
        ---
        if L_style_ref_ind = 'Y' then
           ---
           if MERCH_SQL.TSL_GET_SUBCLASS_INFO(O_error_message,
                                              L_item_master_rec.dept,
                                              L_item_master_rec.class,
                                              L_item_master_rec.subclass,
                                              L_merch_ind,
                                              L_unit_qty,
                                              L_sub_style_ref_ind) = FALSE then
              return FALSE;
           end if;
           ---
           if L_item_master_rec.item_desc_secondary IS NULL and
              L_sub_style_ref_ind = 'Y' then
              ---
              if INSERT_ERROR(O_error_message,
                              I_item,
                              'TSL_STYLE_REF_REQ',
                              'Y',
                              'N') = FALSE then
                return FALSE;
              end if;
              ---
              O_approved := FALSE;
              ---
           end if;
           ---
        end if;
        ---
        -- 14-Sep-2010, DefNBS019152, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
        ---
         if (L_item_master_rec.deposit_item_type = 'E' and
             L_item_master_rec.container_item is NULL) then
            if INSERT_ERROR(O_error_message,
                            I_item,
                            'INV_DEP_ITM1',
                            'Y',
                            'N') = FALSE then
               return FALSE;
            end if;
            O_approved := FALSE;
         end if;
      end if;

   ----------------------------------------------------------------------------
   --- TRANSACTION LEVEL OR ABOVE
   ----------------------------------------------------------------------------
      --12-May-2010 Murali  Cr288b Begin
      if L_tsl_single_instance = 'Y' then
         SQL_LIB.SET_MARK('OPEN','C_UKROI_CHECK_ITATTRIB',I_item,NULL);
         open C_UKROI_CHECK_ITATTRIB('U');
         SQL_LIB.SET_MARK('FETCH','C_UKROI_CHECK_ITATTRIB',I_item,NULL);
         fetch C_UKROI_CHECK_ITATTRIB into L_itattrib_exists;
         SQL_LIB.SET_MARK('CLOSE','C_UKROI_CHECK_ITATTRIB',I_item,NULL);
         close C_UKROI_CHECK_ITATTRIB;

         SQL_LIB.SET_MARK('OPEN','C_UKROI_CHECK_ITATTRIB',I_item,NULL);
         open C_UKROI_CHECK_ITATTRIB('R');
         SQL_LIB.SET_MARK('FETCH','C_UKROI_CHECK_ITATTRIB',I_item,NULL);
         fetch C_UKROI_CHECK_ITATTRIB into L_roi_itattrib_exists;
         SQL_LIB.SET_MARK('CLOSE','C_UKROI_CHECK_ITATTRIB',I_item,NULL);
         close C_UKROI_CHECK_ITATTRIB;
      end if;
      --12-May-2010 Murali  Cr288b End

      if L_item_master_rec.pack_ind = 'Y' then

         --- if the item is a pack item, it must contain at least one component
         SQL_LIB.SET_MARK('OPEN','C_COMPONENT_EXISTS',I_item,NULL);
         open C_COMPONENT_EXISTS;
         SQL_LIB.SET_MARK('FETCH','C_COMPONENT_EXISTS',I_item,NULL);
         fetch C_COMPONENT_EXISTS into L_component_exists;
         SQL_LIB.SET_MARK('CLOSE','C_COMPONENT_EXISTS',I_item,NULL);
         close C_COMPONENT_EXISTS;
         if L_component_exists = 'N' then
            if INSERT_ERROR(O_error_message,
                            I_item,
                            'PACKITEM_COMP_REQ',
                            'Y',
                            'N') = FALSE then
               return FALSE;
            end if;
            O_approved := FALSE;
         end if;
         --- we can skip the component check if this is being called for a
         --- simple pack being approved or submitted along with its component
         --- item
         if I_skip_component_chk = 'N' then
            --- All components of the pack item must have approved status.
            SQL_LIB.SET_MARK('OPEN','C_COMPONENT_NOT_APPROVED',I_item,NULL);
            open C_COMPONENT_NOT_APPROVED;
            SQL_LIB.SET_MARK('FETCH','C_COMPONENT_NOT_APPROVED',I_item,NULL);
            fetch C_COMPONENT_NOT_APPROVED into L_nonappr_component_exists;
            SQL_LIB.SET_MARK('CLOSE','C_COMPONENT_NOT_APPROVED',I_item,NULL);
            close C_COMPONENT_NOT_APPROVED;
            if L_nonappr_component_exists = 'Y' then
               if INSERT_ERROR(O_error_message,
                               I_item,
                               'APPR_COMP_REQ',
                               'Y',
                               'N') = FALSE then
                  return FALSE;
               end if;
               O_approved := FALSE;
            end if;
         end if;
      end if;
     --------------------------------------------------------------------

      if (L_item_master_rec.pack_ind = 'N' or
          (L_item_master_rec.pack_ind = 'Y' and L_item_master_rec.orderable_ind = 'Y'))
          and L_item_master_rec.sellable_ind ='Y' then

         --- all items, except non-sellable packs, must have an item_zone_price record.

         if PM_RETAIL_API_SQL.CHECK_RETAIL_EXISTS( O_ERROR_MESSAGE,
                                                   L_unit_retail_exists,
                                                   I_item) = FALSE then
            return FALSE;
         end if;

         if L_unit_retail_exists = 'N' then
         --07/12/2007 WiproEnabler/Ramasamy - For Defect 4323- Should not allow to approve if RETAIL BY ZONE is mandatory - Begin
         if L_item_master_rec.item_level = L_item_master_rec.tran_level then
         --07/12/2007 WiproEnabler/Ramasamy - For Defect 4323- Should not allow to approve if RETAIL BY ZONE is mandatory - End
               if INSERT_ERROR(O_error_message,
                               I_item,
                               'IT_NO_UNITRETAIL',
                               'Y',
                               'N') = FALSE then
                  return FALSE;
               end if;
               O_approved := FALSE;
         end if;
         end if;
      end if;

      --------------------------------------------------------------------

       If (L_item_master_rec.orderable_ind = 'Y' or L_purchase_type in ('1', '2')
       or L_item_master_rec.deposit_item_type = 'A') then

         --- all items, except non-orderable packs, must have an item_supp_country record.
         SQL_LIB.SET_MARK('OPEN','C_ITEM_SUPP_COUNTRY_EXIST',I_item,NULL);
         open C_ITEM_SUPP_COUNTRY_EXIST;
         SQL_LIB.SET_MARK('FETCH','C_ITEM_SUPP_COUNTRY_EXIST',I_item,NULL);
         fetch C_ITEM_SUPP_COUNTRY_EXIST into L_item_supp_country_exists;
         SQL_LIB.SET_MARK('CLOSE','C_ITEM_SUPP_COUNTRY_EXIST',I_item,NULL);
         close C_ITEM_SUPP_COUNTRY_EXIST;
         if L_item_supp_country_exists = 'N' then
            if INSERT_ERROR(O_error_message,
                            I_item,
                            'IT_NO_SUPP',
                            'Y',
                            'N') = FALSE then
               return FALSE;
            end if;
            O_approved := FALSE;
         end if;
         --- Verify supplier/country/location/bracket have a cost
         ---
         SQL_LIB.SET_MARK('OPEN','C_CHECK_BRACKET_SUPPLIER',I_item,NULL);
         open C_CHECK_BRACKET_SUPPLIER;
         SQL_LIB.SET_MARK('FETCH','C_CHECK_BRACKET_SUPPLIER',I_item,NULL);
         fetch C_CHECK_BRACKET_SUPPLIER into L_BRACKET_NO_COST;
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_BRACKET_SUPPLIER',I_item,NULL);
         close C_CHECK_BRACKET_SUPPLIER;
         if L_BRACKET_NO_COST = 'Y' then
            if INSERT_ERROR(O_error_message,
                            I_item,
                            'IT_SUPP_BRACKET_NO_COST',
                            'Y',
                            'N') = FALSE then
               return FALSE;
            end if;
            O_approved := FALSE;
         end if;
      end if;
      -------------------------------------------------------------------

      -------------------------------------------------------------------
       If (    L_item_master_rec.catch_weight_ind = 'Y'
           and L_item_master_rec.order_type       = 'V'
           and L_item_master_rec.orderable_ind    = 'Y'
           and L_item_master_rec.simple_pack_ind  = 'Y' ) then

         --- all items, except non-orderable packs, must have an item_supp_country record.
         SQL_LIB.SET_MARK('OPEN','C_NULL_TOLERANCES_EXIST',I_item,NULL);
         open C_NULL_TOLERANCES_EXIST;
         SQL_LIB.SET_MARK('FETCH','C_NULL_TOLERANCES_EXIST',I_item,NULL);
         fetch C_NULL_TOLERANCES_EXIST into L_null_tolerances_exist;
         SQL_LIB.SET_MARK('CLOSE','C_NULL_TOLERANCES_EXIST',I_item,NULL);
         close C_NULL_TOLERANCES_EXIST;
         if L_null_tolerances_exist = 'Y' then
            if INSERT_ERROR(O_error_message,
                            I_item,
                            'NULL_TOLERANCES',
                            'Y',
                            'N') = FALSE then
               return FALSE;
            end if;
            O_approved := FALSE;
         end if;
      end if;
      -------------------------------------------------------------------

      -------------------------------------------------------------------


      if L_item_master_rec.item_level < L_item_master_rec.tran_level then

         SQL_LIB.SET_MARK('OPEN','C_ITEM_GROUPS',I_item,NULL);
         open C_ITEM_GROUPS;
         SQL_LIB.SET_MARK('FETCH','C_ITEM_GROUPS',I_item,NULL);
         fetch C_ITEM_GROUPS into L_group_exist;
         SQL_LIB.SET_MARK('CLOSE','C_ITEM_GROUPS',I_item,NULL);
         close C_ITEM_GROUPS;
         if L_group_exist = 'N' then
            if INSERT_ERROR(O_error_message,
                            I_item,
                            'TR_ITEM_NOTIN_GRP',
                            'Y',
                            'N') = FALSE then
               return FALSE;
            end if;
            O_approved := FALSE;
         end if;
      end if;
      --------------------------------------------------------------------


      --------------------------------------------------------------------
      SQL_LIB.SET_MARK('OPEN','C_CHECK_FOR_CC',I_item,NULL);
      open C_CHECK_FOR_CC;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_FOR_CC',I_item,NULL);
      fetch C_CHECK_FOR_CC into L_cost_change_exists;
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_FOR_CC',I_item,NULL);
      close C_CHECK_FOR_CC;
      if L_cost_change_exists = 'Y' then
         if INSERT_ERROR(O_error_message,
                         I_item,
                         'IT_NO_A_CC',
                         'Y',
                         'N') = FALSE then
            return FALSE;
         end if;
         O_approved := FALSE;
      end if;
      --------------------------------------------------------------------
      --- if item is tranlevel or above check that UDAs have been entered
      if L_item_master_rec.item_level <= L_item_master_rec.tran_level then
         if UDA_SQL.CHECK_REQD_NO_VALUE(O_error_message,
                                        L_req_no_value,
                                        I_item,
                                        L_item_master_rec.dept,
                                        L_item_master_rec.class,
                                        L_item_master_rec.subclass) = FALSE then


            return FALSE;
         end if;
         if L_req_no_value = 'Y' then
            if INSERT_ERROR(O_error_message,
                            I_item,
                            'NO_UDA_VALUES',
                            'Y',
                            'N') = FALSE then
               return FALSE;
            end if;
            O_approved := FALSE;
         end if;
      end if;

/*     -----------------------------------------------------------------------------------------------
     -- DefNBS00020505, 13-Jan-2011, Accenture/Sanju Natarajan,Sanju.Natarajan@in.tesco.com, Begin
     -----------------------------------------------------------------------------------------------
     -- if item is above Tran level (i.e. Level 1 TPNA)
     -- If no approved supply chain attributes exists for item, then write into error table.
     -----------------------------------------------------------------------------------------------
     if L_item_master_rec.item_level < L_item_master_rec.tran_level then
        if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY (O_error_message,
                                                   L_uk_ind,
                                                   L_roi_ind) = FALSE then
           return FALSE;
        end if;
        if TSL_SUPPLY_CHAIN_ATTRIB_SQL.TSL_CHECK_APPROVED_SCA_EXISTS(O_error_message,
                                                                     L_tslsca_exists,
                                                                     L_tslsca_exists_roi,
                                                                     I_item) = FALSE then
           return FALSE;
        end if;

        if ((l_uk_ind = 'Y' AND l_roi_ind = 'Y') OR
           (l_roi_ind = 'Y')) then
           if L_tslsca_exists_roi = FALSE then
              if INSERT_ERROR(O_error_message,
                              I_item,
                              'TSL_IT_NO_TSLSCA_CTRY@ROI',
                              'Y',
                              'N') = FALSE then
                 return FALSE;
              end if;
              O_approved := FALSE;
           end if;
        elsif ((l_uk_ind = 'Y' AND l_roi_ind = 'Y') OR
              (l_uk_ind = 'Y')) then
           if L_tslsca_exists = FALSE then
              if INSERT_ERROR(O_error_message,
                              I_item,
                              'TSL_IT_NO_TSLSCA_CTRY@UK',
                              'Y',
                              'N') = FALSE then
                 return FALSE;
              end if;
              O_approved := FALSE;
           end if;
        end if;
     end if;
     ----------------------------------------------------------------------------------------------
     -- DefNBS00020505, 13-Jan-2011, Accenture/Sanju Natarajan,Sanju.Natarajan@in.tesco.com, End
     ----------------------------------------------------------------------------------------------
*/
      if L_item_master_rec.pack_ind = 'N' or
        (L_item_master_rec.pack_ind = 'Y' and L_item_master_rec.pack_type = 'V') then

         if MERCH_DEFAULT_SQL.GET_REQ_INDS(O_error_message,
                                           L_loc_req_ind,
                                           L_seasons_req_ind,
                                           L_tax_codes_req_ind,
                                           L_itattrib_req_ind,
                                           L_impattrib_req_ind,
                                           L_docs_req_ind,
                                           L_hts_req_ind,
                                           L_tariff_req_ind,
                                           L_exp_req_ind,
                                           L_timeline_req_ind,
                                           L_tickets_req_ind,
                                           L_image_req_ind,
                                           L_sub_tr_items_req_ind,
                                           L_dimension_req_ind,
                                           L_diffs_req_ind,
                                           L_mfg_rec_req_ind,
                                           L_pack_sz_req_ind,
                                           L_retail_lb_req_ind,
                                           L_handling_req_ind,
                                           L_handling_temp_req_ind,
                                           L_wastage_req_ind,
                                           L_comments_req_ind,
                                           L_item_master_rec.dept,
                                           L_item_master_rec.class,
                                           L_item_master_rec.subclass) = FALSE then
            return FALSE;
         end if;
         ---
         -- Begin Mod N22 on 18-Sep-07
         -- Check if the tsl_product_auth is 'Y' in the system_options table.
         if L_tsl_product_auth = 'Y' then
              --Complex packs or L2 Base items check that Supply Chain Attribs Authorised
            if L_tslsca_req_ind = 'Y' then
               if L_item_master_rec.item_level = L_item_master_rec.tran_level
                and L_item_master_rec.simple_pack_ind = 'N' and
                (L_item_master_rec.tsl_base_item = L_item_master_rec.item or L_item_master_rec.pack_ind = 'Y') then
                --L2 base items and complex pack check
                   --26-Aug-2009   Wipro/JK     CR236    Begin
                   if L_tsl_single_instance = 'Y' then
                      --12-May-2010 Murali  Cr288b Begin
                      -- Removed the cr288 code
                      --12-May-2010 Murali  Cr288b End
                      if TSL_SUPPLY_CHAIN_ATTRIB_SQL.TSL_ITEM_SCA_EXIST(O_error_message,
                                                                        L_tslsca_exists,
                                                                        L_tslsca_exists_roi,
                                                                        I_item) = FALSE then
                         return FALSE;
                      end if;
                      -- If no supply chain attributes for the item, write into item_approval_error table.
                      --12-May-2010 Murali  Cr288b Begin
                         -- Removed the cr288 code
                         if L_tslsca_exists = FALSE and L_itattrib_exists = 'Y' then
                         --12-May-2010 Murali  Cr288b End
                            SQL_LIB.SET_MARK('INSERT',
                                             NULL,
                                             'ITEM_APPROVAL_ERROR',
                                             ' Error Key: TSL_IT_NO_TSLSCA_CTRY@UK');

                            insert into item_approval_error (item,
                                                             error_key,
                                                             system_req_ind,
                                                             override_ind,
                                                             last_update_id,
                                                             last_update_datetime)
                                                        (select I_item,
                                                                'TSL_IT_NO_TSLSCA_CTRY@UK',
                                                                -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                'Y',
                                                                -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                                'N',
                                                                USER,
                                                                SYSDATE
                                                           from dual
                                                          where not exists (select 'x'
                                                                              from item_approval_error
                                                                             where item = I_item
                                                                               and error_key = 'TSL_IT_NO_TSLSCA_CTRY@UK'
                                                                               -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                               and system_req_ind = 'Y'));
                                                                               -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                            if SQL%FOUND then
                               O_approved := FALSE;
                            end if;
                         end if;
                         --12-May-2010 Murali  Cr288b Begin
                         -- Removed the cr288,NBSDef16666 code
                         -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, Begin
                         if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY (O_error_message,
                                                                    L_uk_ind,
                                                                    L_roi_ind)  = FALSE then
                             return FALSE;
                         end if;
                         if ((L_uk_ind = 'Y' and L_roi_ind = 'Y') or (L_roi_ind = 'Y')) then
                         -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, End
                              if L_tslsca_exists_roi = FALSE and L_roi_itattrib_exists = 'Y' then
                              --12-May-2010 Murali  Cr288b End
                                 SQL_LIB.SET_MARK('INSERT',
                                                  NULL,
                                                  'ITEM_APPROVAL_ERROR',
                                                  ' Error Key: TSL_IT_NO_TSLSCA_CTRY@ROI');
                                 insert into item_approval_error (item,
                                                                  error_key,
                                                                  system_req_ind,
                                                                  override_ind,
                                                                  last_update_id,
                                                                  last_update_datetime)
                                                             (select I_item,
                                                                     'TSL_IT_NO_TSLSCA_CTRY@ROI',
                                                                     -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                     'Y',
                                                                     -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                                     'N',
                                                                     USER,
                                                                     SYSDATE
                                                                from dual
                                                               where not exists (select 'x'
                                                                                   from item_approval_error
                                                                                  where item = I_item
                                                                                    and error_key = 'TSL_IT_NO_TSLSCA_CTRY@ROI'
                                                                                    -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                                    and system_req_ind = 'Y'));
                                                                                    -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                 if SQL%FOUND then
                                    O_approved := FALSE;
                                 end if;
                              end if;
                          -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, Begin
                           end if;
                          -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, End
                      --12-May-2010 Murali  Cr288b Begin
                      -- Removed the cr288 code
                      --12-May-2010 Murali  Cr288b End
                  else
                  --26-Aug-2009   Wipro/JK     CR236    End
                     if TSL_SUPPLY_CHAIN_ATTRIB_SQL.TSL_ITEM_SCA_EXIST(O_error_message,
                                                                       L_tslsca_exists,
                                                                       I_item) = FALSE then
                        return FALSE;
                     end if;
                     -- If no supply chain attributes for the item, write into item_approval_error table.
                     if L_tslsca_exists = FALSE then
                        SQL_LIB.SET_MARK('INSERT',
                                         NULL,
                                         'ITEM_APPROVAL_ERROR',
                                         ' Error Key: TSL_IT_NO_TSLSCA');
                        insert into item_approval_error (item,
                                                         error_key,
                                                         system_req_ind,
                                                         override_ind,
                                                         last_update_id,
                                                         last_update_datetime)
                                                        (select I_item,
                                                                'TSL_IT_NO_TSLSCA',
                                                                -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                'Y',
                                                                -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                                'N',
                                                                USER,
                                                                SYSDATE
                                                           from dual
                                                          where not exists (select 'x'
                                                                              from item_approval_error
                                                                             where item = I_item
                                                                               and error_key = 'TSL_IT_NO_TSLSCA'
                                                                               -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                               and system_req_ind = 'Y'));
                                                                               -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                        if SQL%FOUND then
                           O_approved := FALSE;
                        end if;
                     end if;  --end L_exists = FALSE
                  --26-Aug-2009   Wipro/JK     CR236    Begin
                  end if;
                  --26-Aug-2009   Wipro/JK     CR236    End
               end if;  --end item level = tran level
            end if;
            ------------------------------------
            if L_lschld_req_ind = 'Y' then
            --L2 non-placeholder items and packs must have children if indicator set
               --05-Mar-2009 Defect 11755 vipindas.thekkepurakkal@in.tesco.com
               --Added the braces in the below "if" condition
               if (L_item_master_rec.item_level= L_item_master_rec.tran_level or
                L_item_master_rec.item_level < L_item_master_rec.tran_level) --10-Jan-2008    Wipro/JK  DefNBS0004560 --styles - check that children exist
                and L_tsl_launch_base_ind = FALSE
                -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
                and (L_item_master_rec.tsl_mu_ind = 'N' or (L_item_master_rec.tsl_mu_ind = 'Y' and L_item_master_rec.pack_ind = 'Y')) then
                -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
                  if ITEM_ATTRIB_SQL.TSL_SUBTRAN_EXIST(O_error_message,
                                                       L_lschld_trans_exists,
                                                       I_item) = FALSE then
                     return FALSE;
                  end if;
                  if L_lschld_trans_exists = FALSE then
                     SQL_LIB.SET_MARK('INSERT',
                                      NULL,
                                      'ITEM_APPROVAL_ERROR',
                                      'Error Key: TSL_IT_NO_LSCHLD');
                     insert into item_approval_error (item,
                                                      error_key,
                                                      system_req_ind,
                                                      override_ind,
                                                      last_update_id,
                                                      last_update_datetime)
                                                     (select I_item,
                                                             'TSL_IT_NO_LSCHLD',
                                                             -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                             'Y',
                                                             -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                             'N',
                                                             USER,
                                                             SYSDATE
                                                        from dual
                                                       where not exists (select 'x'
                                                                           from item_approval_error
                                                                          where item = I_item
                                                                            and error_key = 'TSL_IT_NO_LSCHLD'
                                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                            and system_req_ind = 'Y'));
                                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                     if SQL%FOUND then
                        O_approved := FALSE;
                     end if;
                  end if;
               end if;
               --10-Jan-2008    Wipro/JK  DefNBS0004560   Begin
               -- The below If block has been removed as it has been taken care in the above if block
               --10-Jan-2008    Wipro/JK  DefNBS0004560   End
            end if;      --end of lschld_req_ind
            ---spstup
            -- 24-Dec-2008, Satish B.N  DefNBS007109 Begin
            -- added 'or  L_tsl_product_auth = 'Y' ' to if statement
            if L_spstup_req_ind = 'Y' or  L_tsl_product_auth = 'Y' then
            -- 24-Dec-2008, Satish B.N  DefNBS007109 End
                 --Now check if pack exists for L2 item only (including placeholders)
               if L_item_master_rec.item_level= L_item_master_rec.tran_level and L_item_master_rec.pack_ind = 'N' then
                  --check if pack exists for L2 item only
                  if ITEM_ATTRIB_SQL.TSL_PACK_EXIST(O_error_message,
                                                    L_spstup_trans_exists,
                                                    I_item) = FALSE then
                       return FALSE;
                  end if;
                  if L_spstup_trans_exists = FALSE then
                       SQL_LIB.SET_MARK('INSERT',
                                        NULL,
                                        'ITEM_APPROVAL_ERROR',
                                        'Error Key: TSL_IT_NO_SPSTUP');
                       insert into item_approval_error (item,
                                                        error_key,
                                                        system_req_ind,
                                                        override_ind,
                                                        last_update_id,
                                                        last_update_datetime)
                                                       (select I_item,
                                                               'TSL_IT_NO_SPSTUP',
                                                               -- 30-Oct-2008 Raghuveer P R Defect NBS00009166 - Begin
                                                               'Y',
                                                               -- 30-Oct-2008 Raghuveer P R Defect NBS00009166 - End
                                                               'N',
                                                               USER,
                                                               SYSDATE
                                                          from dual
                                                         where not exists (select 'x'
                                                                             from item_approval_error
                                                                            where item = I_item
                                                                              and error_key = 'TSL_IT_NO_SPSTUP'
                                                                              and override_ind = 'Y'));
                       if SQL%FOUND then
                              O_approved := FALSE;
                       end if;
                  end if;
               end if;    --item level = tran level
            end if;
            ---tocc for packs
            if L_tocc_req_ind = 'Y' then
                 --Now check if occ exists for Simple and Complex packs
               if L_item_master_rec.item_level= L_item_master_rec.tran_level and L_item_master_rec.pack_ind = 'Y' and L_tsl_launch_base_ind = FALSE then
                  --check if pack exists for L2 item only
                  if ITEM_ATTRIB_SQL.TSL_CHECK_RETAIL_OCC_BARCODE(O_error_message, --Defect 4206 Wipro/JK 23-Nov-2007
                                                                  L_tocc_trans_exists,
                                                                  I_item) = FALSE then
                       return FALSE;
                  end if;
                  if L_tocc_trans_exists = FALSE then
                     SQL_LIB.SET_MARK('INSERT',
                                      NULL,
                                      'ITEM_APPROVAL_ERROR',
                                      'Error Key: TSL_IT_NO_TOCC');
                     insert into item_approval_error (item,
                                                      error_key,
                                                      system_req_ind,
                                                      override_ind,
                                                      last_update_id,
                                                      last_update_datetime)
                                                     (select I_item,
                                                             'TSL_IT_NO_TOCC',
                                                             -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                             'Y',
                                                             -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                             'N',
                                                             USER,
                                                             SYSDATE
                                                        from dual
                                                       where not exists (select 'x'
                                                                           from item_approval_error
                                                                          where item = I_item
                                                                            and error_key = 'TSL_IT_NO_TOCC'
                                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                            and system_req_ind = 'Y'));
                                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                     if SQL%FOUND then
                            O_approved := FALSE;
                     end if;
                  end if;
               end if;    --item level = tran level
            end if;  -- end of tocc req ind
            --tret reqd ind
            if L_tret_req_ind = 'Y' then
               --check for retail barcodes existing for grandchildren
               if L_item_master_rec.item_level > L_item_master_rec.tran_level
                and L_item_master_rec.pack_ind = 'N'
                and L_tsl_launch_base_ind = FALSE
                -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
                and L_item_master_rec.tsl_mu_ind = 'N' then
                -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
                   if ITEM_ATTRIB_SQL.TSL_GCHILD_RET_EXIST(O_error_message,
                                                          L_gchild_tret_exists,
                                                          I_item) = FALSE then
                     return FALSE;
                  end if;
                  if L_gchild_tret_exists = FALSE then
                     SQL_LIB.SET_MARK('INSERT',
                                      NULL,
                                      'ITEM_APPROVAL_ERROR',
                                      ' Error Key: TSL_IT_NO_TRETG');
                     insert into item_approval_error (item,
                                                      error_key,
                                                      system_req_ind,
                                                      override_ind,
                                                      last_update_id,
                                                      last_update_datetime)
                                                     (select I_item,
                                                             'TSL_IT_NO_TRETG',
                                                             -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                             'Y',
                                                             -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                             'N',
                                                             USER,
                                                             SYSDATE
                                                        from dual
                                                       where not exists (select 'x'
                                                                           from item_approval_error
                                                                          where item = I_item
                                                                            and error_key = 'TSL_IT_NO_TRETG'
                                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                            and system_req_ind = 'Y'));
                                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                     if SQL%FOUND then
                        O_approved := FALSE;
                     end if;
                  end if;
               end if; --end item level < tran level
               --check for retail barcodes for children of L2 items
               if L_item_master_rec.item_level= L_item_master_rec.tran_level
                and L_item_master_rec.pack_ind = 'N'
                and L_tsl_launch_base_ind = FALSE
                -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
                and L_item_master_rec.tsl_mu_ind = 'N' then
                -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
                  if ITEM_ATTRIB_SQL.TSL_CHECK_RETAIL_OCC_BARCODE(O_error_message, --Defect 4206 Wipro/JK 23-Nov-2007
                                                                  L_tret_trans_exists,
                                                                  I_item) = FALSE then
                     return FALSE;
                  end if;
                  if L_tret_trans_exists= FALSE then
                     SQL_LIB.SET_MARK('INSERT',
                                      NULL,
                                      'ITEM_APPROVAL_ERROR',
                                      ' Error Key: TSL_IT_NO_LSCHLD');
                     insert into item_approval_error (item,
                                                      error_key,
                                                      system_req_ind,
                                                      override_ind,
                                                      last_update_id,
                                                      last_update_datetime)
                                                     (select I_item,
                                                             'TSL_IT_NO_LSCHLD',
                                                             -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                             'Y',
                                                             -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                             'N',
                                                             USER,
                                                             SYSDATE
                                                        from dual
                                                       where not exists (select 'x'
                                                                           from item_approval_error
                                                                          where item = I_item
                                                                            and error_key = 'TSL_IT_NO_LSCHLD'
                                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                            and system_req_ind = 'Y'));
                                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                     if SQL%FOUND then
                        O_approved := FALSE;
                     end if;
                  end if;  --end of L_exists
               end if;        --item level = tran level
            end if;  --L_tret_req_ind
               --now do style checks by calling function to verify that at least one item has required attribs
            if L_item_master_rec.item_level < L_item_master_rec.tran_level
             and L_item_master_rec.pack_ind = 'N'
             and L_tsl_launch_base_ind = FALSE
             -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
             and L_item_master_rec.tsl_mu_ind = 'N' then
             -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
            --check if required attribs exist
               if ITEM_ATTRIB_SQL.TSL_CHILD_ATTRIB_EXIST(O_error_message,
                                                         L_child_attrib_exists,
                                                         L_spstup_req_ind,
                                                         L_tret_req_ind,
                                                         L_tslsca_req_ind,
                                                         I_item,
                                                         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
                                                         --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,Begin
                                                         L_tsret_req_ind) = FALSE then
                                                         --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
                                                         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
                      return FALSE;
               end if;
               --based on what is required, insert data into item_approval_error.
               if L_child_attrib_exists = FALSE then
                  -- 09-Jun-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS013056 Begin
                  -- introduced multiple errors instead of one single error
                  L_tret_subtrans_exists := NULL;
                  L_tslsca_exists        := NULL;
                  L_spstup_trans_exists  := NULL;

                  if L_spstup_req_ind = 'Y' then
                     if ITEM_ATTRIB_SQL.TSL_PACK_EXIST(O_error_message,
                                                       L_spstup_trans_exists,
                                                       I_item) = FALSE then
                         return FALSE;
                     end if;
                     if L_spstup_trans_exists = FALSE then
                        SQL_LIB.SET_MARK('INSERT',
                                          NULL,
                                         'ITEM_APPROVAL_ERROR',
                                         ' Error Key: TSL_IT_NO_SPACK_CHILD');
                        insert into item_approval_error (item,
                                                         error_key,
                                                         system_req_ind,
                                                         override_ind,
                                                         last_update_id,
                                                         last_update_datetime)
                                                 (select I_item,
                                                         'TSL_IT_NO_SPACK_CHILD',
                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                         'Y',
                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                         'N',
                                                         USER,
                                                         SYSDATE
                                                from dual
                                                   where not exists (select 'x'
                                                                       from item_approval_error
                                                                      where item = I_item
                                                                        and error_key = 'TSL_IT_NO_SPACK_CHILD'
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                        and system_req_ind = 'Y'));
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End

                     end if;
                  end if;
                  if L_tret_req_ind = 'Y' then
                     if ITEM_ATTRIB_SQL.TSL_RET_EXIST(O_error_message,
                                                      L_tret_subtrans_exists,
                                                      I_item) = FALSE then
                        return FALSE;
                     end if;
                     if L_tret_subtrans_exists = FALSE then
                        SQL_LIB.SET_MARK('INSERT',
                                          NULL,
                                         'ITEM_APPROVAL_ERROR',
                                         ' Error Key: TSL_IT_NO_RETBAR_CHILD');
                        insert into item_approval_error (item,
                                                         error_key,
                                                         system_req_ind,
                                                         override_ind,
                                                         last_update_id,
                                                         last_update_datetime)
                                                 (select I_item,
                                                         'TSL_IT_NO_RETBAR_CHILD',
                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                         'Y',
                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                         'N',
                                                         USER,
                                                         SYSDATE
                                                    from dual
                                                   where not exists (select 'x'
                                                                       from item_approval_error
                                                                      where item = I_item
                                                                        and error_key = 'TSL_IT_NO_RETBAR_CHILD'
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                        and system_req_ind = 'Y'));
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                     end if;
                  end if;

                  if L_tslsca_req_ind = 'Y' then
                     --26-Aug-2009   Wipro/JK     CR236    Begin
                     if L_tsl_single_instance = 'Y' then
                        -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
                        if TSL_SUPPLY_CHAIN_ATTRIB_SQL.BASE_ITEM_SCA_EXISTS(O_error_message,
                                                                            L_base_item_sca_exists,
                                                                            I_item) = FALSE then
                           return FALSE;
                        end if;
                        -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
                        -- If no supply chain attributes for the item, write into item_approval_error table.
                        -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
                        if L_base_item_sca_exists = 'N' then
                        -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
                           SQL_LIB.SET_MARK('INSERT',
                                            NULL,
                                            'ITEM_APPROVAL_ERROR',
                                            ' Error Key: TSL_IT_NO_SCATTR_CHILD');
                           insert into item_approval_error (item,
                                                            error_key,
                                                            system_req_ind,
                                                            override_ind,
                                                            last_update_id,
                                                            last_update_datetime)
                                                    (select I_item,
                                                            -- NBSDef16666 Shweta Madnawat shweta.madnawat@in.tesco.com 04-Apr-2010 Begin
                                                            -- Changed the rtk_key to TSL_IT_NO_SCATTR_CHILD as we need to give a generic message now.
                                                            'TSL_IT_NO_SCATTR_CHILD',
                                                            -- NBSDef16666 Shweta Madnawat shweta.madnawat@in.tesco.com 04-Apr-2010 End
                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                            'Y',
                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                            'N',
                                                            USER,
                                                            SYSDATE
                                                       from dual
                                                      where not exists (select 'x'
                                                                          from item_approval_error
                                                                         where item = I_item
                                                                           and error_key = 'TSL_NO_CHILD_SCA_CTRY@UK'
                                                                           -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                           and system_req_ind = 'Y'));
                                                                           -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                              if SQL%FOUND then
                                 O_approved := FALSE;
                              end if;
                        -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
                        end if;
                        -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End

                    else
                    --26-Aug-2009   Wipro/JK     CR236    End
                       if TSL_SUPPLY_CHAIN_ATTRIB_SQL.TSL_ITEM_SCA_EXIST(O_error_message,
                                                                         L_tslsca_exists,
                                                                         I_item) = FALSE then
                          return FALSE;
                       end if;
                       if L_tslsca_exists = FALSE then
                          SQL_LIB.SET_MARK('INSERT',
                                             NULL,
                                            'ITEM_APPROVAL_ERROR',
                                            ' Error Key: TSL_IT_NO_SCATTR_CHILD');
                           insert into item_approval_error (item,
                                                            error_key,
                                                            system_req_ind,
                                                            override_ind,
                                                            last_update_id,
                                                            last_update_datetime)
                                                    (select I_item,
                                                            'TSL_IT_NO_SCATTR_CHILD',
                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                            'Y',
                                                            -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                            'N',
                                                            USER,
                                                            SYSDATE
                                                   from dual
                                                       where not exists (select 'x'
                                                                          from item_approval_error
                                                                         where item = I_item
                                                                           and error_key = 'TSL_IT_NO_SCATTR_CHILD'
                                                                           -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                           and system_req_ind = 'Y'));
                                                                           -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                        end if;
                     --26-Aug-2009   Wipro/JK     CR236    Begin
                     end if;
                     --26-Aug-2009   Wipro/JK     CR236    End
                  end if;
                  -- 09-Jun-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS013056 End
                  SQL_LIB.SET_MARK('INSERT',
                  NULL,
                  'ITEM_APPROVAL_ERROR',
                  ' Error Key: TSL_IT_NO_ATTRIB_CHILD');
                  insert into item_approval_error (item,
                                                  error_key,
                                                  system_req_ind,
                                                  override_ind,
                                                  last_update_id,
                                                  last_update_datetime)
                                                 (select I_item,
                                                         'TSL_IT_NO_ATTRIB_CHILD',
                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                         'Y',
                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                         'N',
                                                         USER,
                                                         SYSDATE
                                                    from dual
                                                   where not exists (select 'x'
                                                                       from item_approval_error
                                                                      where item = I_item
                                                                        and error_key = 'TSL_IT_NO_ATTRIB_CHILD'
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                        and system_req_ind = 'Y'));
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                  if SQL%FOUND then
                     O_approved := FALSE;
                  end if;
               end if;
               --end if;    --item level = tran level
            end if;  --L_tret_req_ind
               --now do style checks by calling function to verify that at least one item has required attribs
            if L_item_master_rec.item_level < L_item_master_rec.tran_level
             and L_item_master_rec.pack_ind = 'N'
             -- DefNBS016801, 31-Mar-2010, Govindarajan K, Begin
             and (L_tsl_launch_base_ind = FALSE
             -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
              or L_item_master_rec.tsl_mu_ind = 'Y') then
             -- DefNBS016801, 31-Mar-2010, Govindarajan K, End
             -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
            --check if required attribs exist
               --06-Apr-2010 Tesco HSC/Usha Patil              Defect Id: NBS00016671 Begin
               if L_item_master_rec.tsl_mu_ind = 'Y' then
                  if ITEM_ATTRIB_SQL.TSL_CHILD_ATTRIB_EXIST(O_error_message,
                                                            L_child_attrib_exists,
                                                            L_spstup_req_ind,
                                                            'N',
                                                            L_tslsca_req_ind,
                                                            I_item,
                                                            -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
                                                            --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,Begin
                                                            'N') = FALSE then
                                                            --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
                                                            -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
                      return FALSE;
                  end if;
               else
               --06-Apr-2010 Tesco HSC/Usha Patil              Defect Id: NBS00016671 End
                  if ITEM_ATTRIB_SQL.TSL_CHILD_ATTRIB_EXIST(O_error_message,
                                                            L_child_attrib_exists,
                                                            L_spstup_req_ind,
                                                            L_tret_req_ind,
                                                            L_tslsca_req_ind,
                                                            I_item,
                                                            -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
                                                            --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,Begin
                                                            L_tsret_req_ind) = FALSE then
                                                            --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
                                                            -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
                         return FALSE;
                  end if;
               --06-Apr-2010 Tesco HSC/Usha Patil              Defect Id: NBS00016671 Begin
               end if;
               --06-Apr-2010 Tesco HSC/Usha Patil              Defect Id: NBS00016671 End
               --based on what is required, insert data into item_approval_error.
               if L_child_attrib_exists = FALSE then
                  SQL_LIB.SET_MARK('INSERT',
                  NULL,
                  'ITEM_APPROVAL_ERROR',
                  ' Error Key: TSL_IT_NO_ATTRIB_CHILD');
                  insert into item_approval_error (item,
                                                  error_key,
                                                  system_req_ind,
                                                  override_ind,
                                                  last_update_id,
                                                  last_update_datetime)
                                                 (select I_item,
                                                         'TSL_IT_NO_ATTRIB_CHILD',
                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                         'Y',
                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                         'N',
                                                         USER,
                                                         SYSDATE
                                                    from dual
                                                   where not exists (select 'x'
                                                                       from item_approval_error
                                                                      where item = I_item
                                                                        and error_key = 'TSL_IT_NO_ATTRIB_CHILD'
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                        and system_req_ind = 'Y'));
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                  if SQL%FOUND then
                     O_approved := FALSE;
                  end if;
               end if;
               --end if;    --item level = tran level
            elsif L_item_master_rec.item_level < L_item_master_rec.tran_level
             and L_item_master_rec.pack_ind = 'N'
             and L_tsl_launch_base_ind = TRUE then
             -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
             -- DefNBS016801, 31-Mar-2010, Govindarajan K, Begin
             -- Commented following condition because it is conflict with the launch base condition
             -- and L_item_master_rec.tsl_mu_ind = 'Y' then
             -- DefNBS016801, 31-Mar-2010, Govindarajan K, End
             -- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
               L_tret_req_ind := 'N';
               --check if required attribs exist
               if ITEM_ATTRIB_SQL.TSL_CHILD_ATTRIB_EXIST(O_error_message,
                                                         -- DefNBS016801, 31-Mar-2010, Govindarajan K, Begin
                                                         -- using the L_child_attrib_exists variable instead of L_childph_attrib_exists
                                                         -- L_childph_attrib_exists,
                                                         L_child_attrib_exists,
                                                         -- DefNBS016801, 31-Mar-2010, Govindarajan K, End
                                                         L_spstup_req_ind,
                                                         L_tret_req_ind,
                                                         L_tslsca_req_ind,
                                                         I_item,
                                                         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
                                                         --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,Begin
                                                         L_tsret_req_ind) = FALSE then
                                                         --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
                                                         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
                  return FALSE;
               end if;
               -- DefNBS016801, 31-Mar-2010, Govindarajan K, Begin
               -- using the L_child_attrib_exists variable instead of L_childph_attrib_exists
               -- if L_childph_attrib_exists = FALSE then
               if L_child_attrib_exists = FALSE then
               -- DefNBS016801, 31-Mar-2010, Govindarajan K, End
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'ITEM_APPROVAL_ERROR',
                                   ' Error Key: TSL_IT_NO_ATTRIB_PHCHILD');
                  insert into item_approval_error (item,
                                                   error_key,
                                                   system_req_ind,
                                                   override_ind,
                                                   last_update_id,
                                                   last_update_datetime)
                                                  (select I_item,
                                                          'TSL_IT_NO_ATTRIB_PHCHILD',
                                                          -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                          'Y',
                                                          -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                          'N',
                                                          USER,
                                                          SYSDATE
                                                     from dual
                                                    where not exists (select 'x'
                                                                       from item_approval_error
                                                                      where item = I_item
                                                                        and error_key = 'TSL_IT_NO_ATTRIB_PHCHILD'
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                        and system_req_ind = 'Y'));
                                                                        -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                  if SQL%FOUND then
                       O_approved := FALSE;
                  end if;
               end if;
            end if;    --item level < tran level for styles
         end if;
      end if;     --end if for l_tsl_product_auth system option
      -- End Mod N22 on 18-Sep-07

      --ModN127, 12-May-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
      --The if condition for L_loc_req_ind as part of N22 has been removed
      if L_loc_req_ind = 'Y' then
         SQL_LIB.SET_MARK('OPEN','C_CHECK_LOC',I_item,NULL);
         open C_CHECK_LOC;
         SQL_LIB.SET_MARK('FETCH','C_CHECK_LOC',I_item,NULL);
         fetch C_CHECK_LOC into L_loc_exists;
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_LOC',I_item,NULL);
         close C_CHECK_LOC;
         if L_loc_exists = 'N' then
            insert into item_approval_error
                         (item,
                          error_key,
                          system_req_ind,
                          override_ind,
                          last_update_id,
                          last_update_datetime)
              select I_item,
                     'IT_NO_LOCS',
                     'N',
                     'N',
                     user,
                     sysdate
                from dual
               where not exists (select 'x'
                                   from item_approval_error
                                  where item = I_item
                                    and error_key = 'IT_NO_LOCS'
                                    and override_ind = 'Y');
            if SQL%FOUND then
               O_approved := FALSE;
            end if;
         end if;
      end if;
      --ModN127, 12-May-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
      --The endif condition for L_loc_req_ind as part of N22 has been removed
      if L_tsl_product_auth = 'Y' and
         (L_item_master_rec.item_level in (1,2) and
         L_item_master_rec.pack_ind ='N'  and
         --17-Jul-2008    Wipro/JK    DefNBS007900   Begin
           L_item_master_rec.item = NVL(L_item_master_rec.tsl_base_item, L_item_master_rec.item) or
           -- CR249, 22-Sep-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
           (L_item_master_rec.item_level = 1 and L_item_master_rec.tran_level = 1 and
            L_item_master_rec.pack_ind ='Y' and L_item_master_rec.simple_pack_ind = 'N')) then
           -- CR249, 22-Sep-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
         --17-Jul-2008    Wipro/JK    DefNBS007900   End
         if MERCH_DEFAULT_SQL.TSL_GET_MERCH_HIER_AVAIL(O_error_message,
                                                       L_merch_dft_rnge_exists,
                                                       --CR236 Raghuveer P R 05-Sep-2009 -Begin
                                                       L_merch_dft_rnge_exists_roi,
                                                       --CR236 Raghuveer P R 05-Sep-2009 -End
                                                       'RANGE',
                                                       L_item_master_rec.dept,
                                                       L_item_master_rec.class,
                                                       L_item_master_rec.subclass,
                                                       L_item_master_rec.item_level)=FALSE then
            return FALSE;
         end if;

         -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
         if TSL_RANGE_ATTRIB_SQL.ITEM_RANGE_EXISTS(O_error_message,
                                                   L_range_exists_uk,
                                                   I_item,
                                                   NULL) = FALSE then
            return FALSE;
         end if;

         if TSL_RANGE_ATTRIB_SQL.ITEM_RANGE_EXISTS_ROI(O_error_message,
                                                       L_range_exists_roi,
                                                       I_item,
                                                       NULL) = FALSE then
            return FALSE;
         end if;
         -- NBSDef16666 Shweta Madnawat shweta.madnawat@in.tesco.com 04-Apr-2010 Begin
         if L_tsl_single_instance = 'Y' then
            --12-May-2010 Murali  Cr288b Begin
            if L_merch_dft_rnge_exists ='Y' and L_itattrib_exists = 'Y' and
               (L_item_master_rec.tsl_range_auth_ind ='N' or L_range_exists_uk = 'N') then
            --12-May-2010 Murali  Cr288b End
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'ITEM_APPROVAL_ERROR',
                                   'Error Key: TSL_RGE_NOT_AUTH');
                  insert into item_approval_error (item,
                                                   error_key,
                                                   system_req_ind,
                                                   override_ind,
                                                   last_update_id,
                                                   last_update_datetime)
                                                  (select I_item,
                                                          'TSL_RGE_NOT_AUTH',
                                                          -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                          'Y',
                                                          -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                          'N',
                                                          USER,
                                                          SYSDATE
                                                     from dual
                                                    where not exists (select 'x'
                                                                        from item_approval_error
                                                                       where item = I_item
                                                                         and error_key = 'TSL_RGE_NOT_AUTH'
                                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                         and system_req_ind = 'Y'));
                                                                         -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End

                  if SQL%FOUND then
                     O_approved := FALSE;
                  end if;
            end if;
            --12-May-2010 Murali  Cr288b Begin
            -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, Begin
            if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY (O_error_message,
                                                       L_uk_ind,
                                                       L_roi_ind)  = FALSE then
               return FALSE;
            end if;
            if ((L_uk_ind = 'Y' and L_roi_ind = 'Y') or (L_roi_ind = 'Y')) then
            -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, End
                 if  L_merch_dft_rnge_exists_roi ='Y' and L_roi_itattrib_exists = 'Y' and
                    (L_item_master_rec.tsl_range_auth_ind ='N' or L_range_exists_roi = 'N') then
                       SQL_LIB.SET_MARK('INSERT',
                                        NULL,
                                        'ITEM_APPROVAL_ERROR',
                                        'Error Key: TSL_RGE_NOT_AUTH_ROI');
                       insert into item_approval_error (item,
                                                        error_key,
                                                        system_req_ind,
                                                        override_ind,
                                                        last_update_id,
                                                        last_update_datetime)
                                                       (select I_item,
                                                               'TSL_RGE_NOT_AUTH_ROI',
                                                               -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                               'Y',
                                                               -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                                                               'N',
                                                               USER,
                                                               SYSDATE
                                                          from dual
                                                         where not exists (select 'x'
                                                                             from item_approval_error
                                                                            where item = I_item
                                                                              and error_key = 'TSL_RGE_NOT_AUTH_ROI'
                                                                              -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com Begin
                                                                              and override_ind = 'Y'));
                                                                              -- DefNBS019141, 14-Sep-2010, Yashavantharaja, yashavantharaja.thimmesh@in.tesco.com End
                       if SQL%FOUND then
                          O_approved := FALSE;
                       end if;
                 end if;
              -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, Begin
            end if;
            -- DefNBS020236,28-Dec-2010, vipin.simar@in.tesco.com, End
            --12-May-2010 Murali  Cr288b End
         end if;
         -- NBSDef16666 Shweta Madnawat shweta.madnawat@in.tesco.com 04-Apr-2010 Begin
         -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
         -- Removed Code
         --CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 25-Feb-2010 End
         --26-Aug-2009      Wipro/JK     CR236    End
         -- NBSDef16666 Shweta Madnawat shweta.madnawat@in.tesco.com 04-Apr-2010 End
      end if;
      --ModN127, 12-May-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
       --------------------------------------------------------------------
         if L_seasons_req_ind = 'Y' then
            SQL_LIB.SET_MARK('OPEN','C_CHECK_SEASONS',I_item,NULL);
            open C_CHECK_SEASONS;
            SQL_LIB.SET_MARK('FETCH','C_CHECK_SEASONS',I_item,NULL);
            fetch C_CHECK_SEASONS into L_seasons_exist;
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_SEASONS',I_item,NULL);
            close C_CHECK_SEASONS;
            if L_seasons_exist = 'N' then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_SEASON',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_SEASON'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_tax_codes_req_ind = 'Y' then
            if ITEM_ATTRIB_SQL.TAX_CODES_EXIST(O_error_message,
                                               L_tax_codes_exist,
                                               I_item) = FALSE then
               return FALSE;
            end if;
            if L_tax_codes_exist = FALSE then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_TAXCODES',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_TAXCODES'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_itattrib_req_ind = 'Y' then
            --26-Aug-2009   Wipro/JK    CR236   Begin
            if L_tsl_single_instance = 'Y' then
               --12-May-2010 Murali  Cr288b Begin
               -- removed the cursor fetch as value is already fetched
               --12-May-2010 Murali  Cr288b End

               --DefNBS016537 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-March-2010 Begin
               -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
               -- Removed the code from here in order to fix the defect 16573
               -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End


               -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
               -- Removed the code from here in order to fix the defect 16573
               -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End

               --12-May-2010 Murali  Cr288b Begin
               -- Removed the Code added for cr288 and its related defects as the its
               -- not required to check for SCA, range and attribute as the validation
               -- is already done based on the launch date. Have added the below code
               -- to check if item attributes exist or not for the item.
               if L_itattrib_exists = 'N' and L_roi_itattrib_exists = 'N' then
                   SQL_LIB.SET_MARK('INSERT',
                                    NULL,
                                    'ITEM_APPROVAL_ERROR',
                                    ' Error Key: IT_NO_ATTRIB_CTRY@UK');
                   insert into item_approval_error(item,
                                                   error_key,
                                                   system_req_ind,
                                                   override_ind,
                                                   last_update_id,
                                                   last_update_datetime)
                                            select I_item,
                                                   'IT_NO_ATTRIB_CTRY@UK',
                                                   'N',
                                                   'N',
                                                   user,
                                                   sysdate
                                              from dual
                                             where not exists (select 'x'
                                                                from item_approval_error
                                                               where item = I_item
                                                                 and error_key = 'IT_NO_ATTRIB_CTRY@UK'
                                                                 and override_ind = 'Y');
                   if SQL%FOUND then
                      O_approved := FALSE;
                   end if;

                   SQL_LIB.SET_MARK('INSERT',
                                    NULL,
                                    'ITEM_APPROVAL_ERROR',
                                    ' Error Key: IT_NO_ATTRIB_CTRY@ROI');
                   insert into item_approval_error(item,
                                                   error_key,
                                                   system_req_ind,
                                                   override_ind,
                                                   last_update_id,
                                                   last_update_datetime)
                                            select I_item,
                                                   'IT_NO_ATTRIB_CTRY@ROI',
                                                   'N',
                                                   'N',
                                                   user,
                                                   sysdate
                                              from dual
                                             where not exists (select 'x'
                                                                from item_approval_error
                                                               where item = I_item
                                                                 and error_key = 'IT_NO_ATTRIB_CTRY@ROI'
                                                                 and override_ind = 'Y');
                   if SQL%FOUND then
                      O_approved := FALSE;
                   end if;
               end if;
               --12-May-2010 Murali  Cr288b End

               -- DefNBS016537 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-March-2010 End
               --12-May-2010 Murali  Cr288b Begin
               if L_item_master_rec.item_level = L_item_master_rec.tran_level and
                  L_item_master_rec.simple_pack_ind = 'N' and L_item_master_rec.pack_ind = 'Y' then

                  if TSL_CHECK_RP_COMP(O_error_message,
                                       L_uk_specific_sp,
                                       L_roi_specific_sp,
                                       I_item)= FALSE then
                     return FALSE;
                  end if;

                  if L_itattrib_exists = 'Y' and L_roi_itattrib_exists = 'Y' and
                     (L_uk_specific_sp or L_roi_specific_sp) then
                     if INSERT_ERROR(O_error_message,
                                     I_item,
                                     -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                                     --'TSL_IT_VALID_UKROI_SP',
                                     'TSL_INVALID_COMP_BCP',
                                     -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                                     'Y',
                                     'N') = FALSE then
                       return FALSE;
                     end if;
                     O_approved := FALSE;
                  end if;

                  if L_itattrib_exists = 'Y' and L_roi_itattrib_exists = 'N' and L_roi_specific_sp then
                     if INSERT_ERROR(O_error_message,
                                     I_item,
                                     -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                                     --'TSL_IT_VALID_UK_SP',
                                     'TSL_INVALID_COMP_UCP',
                                     -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                                     'Y',
                                     'N') = FALSE then
                       return FALSE;
                     end if;
                     O_approved := FALSE;
                  end if;

                  if L_itattrib_exists = 'N' and L_roi_itattrib_exists = 'Y' and L_uk_specific_sp then
                     if INSERT_ERROR(O_error_message,
                                     I_item,
                                     -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                                     --'TSL_IT_VALID_ROI_SP',
                                     'TSL_INVALID_COMP_RCP',
                                     -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                                     'Y',
                                     'N') = FALSE then
                       return FALSE;
                     end if;
                     O_approved := FALSE;
                  end if;
               end if;
               --12-May-2010 Murali  Cr288b End
            else
            --26-Aug-2009   Wipro/JK    CR236   End
               SQL_LIB.SET_MARK('OPEN','C_CHECK_ITATTRIB',I_item,NULL);
               open C_CHECK_ITATTRIB;
               SQL_LIB.SET_MARK('FETCH','C_CHECK_ITATTRIB',I_item,NULL);
               fetch C_CHECK_ITATTRIB into L_itattrib_exists;
               SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITATTRIB',I_item,NULL);
               close C_CHECK_ITATTRIB;
               if L_itattrib_exists = 'N' then
                  insert into item_approval_error
                              (item,
                               error_key,
                               system_req_ind,
                               override_ind,
                               last_update_id,
                               last_update_datetime)
                   select I_item,
                          'IT_NO_ATTRIB',
                          'N',
                          'N',
                          user,
                          sysdate
                     from dual
                    where not exists (select 'x'
                                        from item_approval_error
                                       where item = I_item
                                         and error_key = 'IT_NO_ATTRIB'
                                         and override_ind = 'Y');
                  if SQL%FOUND then
                     O_approved := FALSE;
                  end if;
               end if;
            --26-Aug-2009   Wipro/JK    CR236   Begin
            end if;
            --26-Aug-2009   Wipro/JK    CR236   End
         end if;
         --------------------------------------------------------------------
         if L_impattrib_req_ind = 'Y' then
            if ITEM_ATTRIB_SQL.IMPORT_ATTR_EXISTS(O_error_message,
                                                  L_impattrib_exists,
                                                  I_item) = FALSE then
               return FALSE;
            end if;
            if L_impattrib_exists = FALSE then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_IMPATTRIB',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_IMPATTRIB'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_docs_req_ind = 'Y' then
            SQL_LIB.SET_MARK('OPEN','C_CHECK_DOCS',I_item,NULL);
            open C_CHECK_DOCS;
            SQL_LIB.SET_MARK('FETCH','C_CHECK_DOCS',I_item,NULL);
            fetch C_CHECK_DOCS into L_docs_exist;
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_DOCS',I_item,NULL);
            close C_CHECK_DOCS;
            if L_docs_exist = 'N' then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_DOCS',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_DOCS'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_hts_req_ind = 'Y' then
            SQL_LIB.SET_MARK('OPEN','C_CHECK_HTS',I_item,NULL);
            open C_CHECK_HTS;
            SQL_LIB.SET_MARK('FETCH','C_CHECK_HTS',I_item,NULL);
            fetch C_CHECK_HTS into L_hts_exists;
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_HTS',I_item,NULL);
            close C_CHECK_HTS;
            if L_hts_exists = 'N' then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_HTS',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_HTS'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_tariff_req_ind = 'Y' then
            if ITEM_ATTRIB_SQL.ITEM_ELIGIBLE_EXISTS(O_error_message,
                                                    L_tariff_exists,
                                                    I_item) = FALSE then
               return FALSE;
            end if;
            if L_tariff_exists = FALSE then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_ETT',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_ETT'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_exp_req_ind = 'Y' then
            SQL_LIB.SET_MARK('OPEN','C_CHECK_EXPENSE',I_item,NULL);
            open C_CHECK_EXPENSE;
            SQL_LIB.SET_MARK('FETCH','C_CHECK_EXPENSE',I_item,NULL);
            fetch C_CHECK_EXPENSE into L_expense_exists;
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_EXPENSE',I_item,NULL);
            close C_CHECK_EXPENSE;
            if L_expense_exists = 'N' then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_EXPENSE',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_EXPENSE'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_tickets_req_ind = 'Y' then
            if ITEM_ATTRIB_SQL.TICKET_EXISTS(O_error_message,
                                             L_tickets_exist,
                                             I_item) = FALSE then
               return FALSE;
            end if;
            if L_tickets_exist = FALSE then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_TICKETS',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_TICKETS'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_timeline_req_ind = 'Y' then
            SQL_LIB.SET_MARK('OPEN','C_CHECK_TIMELINE',I_item,NULL);
            open C_CHECK_TIMELINE;
            SQL_LIB.SET_MARK('FETCH','C_CHECK_TIMELINE',I_item,NULL);
            fetch C_CHECK_TIMELINE into L_timeline_exists;
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_TIMELINE',I_item,NULL);
            close C_CHECK_TIMELINE;
            if L_timeline_exists = 'N' then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_TIMELINE',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_TIMELINE'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_image_req_ind = 'Y' then
            SQL_LIB.SET_MARK('OPEN','C_CHECK_IMAGE',I_item,NULL);
            open C_CHECK_IMAGE;
            SQL_LIB.SET_MARK('FETCH','C_CHECK_IMAGE',I_item,NULL);
            fetch C_CHECK_IMAGE into L_image_exists;
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_IMAGE',I_item,NULL);
            close C_CHECK_IMAGE;
            if L_image_exists = 'N' then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_IMAGE',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_IMAGE'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         /* Defect NBS00010904 Raghuveer P R 16-Jan-2009 - Begin */
         if (L_sub_tr_items_req_ind = 'Y' and L_tsl_launch_base_ind = FALSE)
          -- LT Defect NBS00013099, 05-Jun-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
          and L_item_master_rec.tsl_mu_ind != 'Y'  then
          -- LT Defect NBS00013099, 05-Jun-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
         /* Defect NBS00010904 Raghuveer P R 16-Jan-2009 - End */

            if L_item_master_rec.tran_level < 3 then

               SQL_LIB.SET_MARK('OPEN','C_CHECK_SUB_TR',I_item,NULL);
               open C_CHECK_SUB_TR;
               SQL_LIB.SET_MARK('FETCH','C_CHECK_SUB_TR',I_item,NULL);
               fetch C_CHECK_SUB_TR into L_sub_tr_exists;
               SQL_LIB.SET_MARK('CLOSE','C_CHECK_SUB_TR',I_item,NULL);
               close C_CHECK_SUB_TR;
               if L_sub_tr_exists = 'N' then
                  insert into item_approval_error
                              (item,
                               error_key,
                               system_req_ind,
                               override_ind,
                               last_update_id,
                               last_update_datetime)
                   select I_item,
                          'IT_NO_SUB_TR',
                          'N',
                          'N',
                          user,
                          sysdate
                     from dual
                    where not exists (select 'x'
                                        from item_approval_error
                                       where item = I_item
                                         and error_key = 'IT_NO_SUB_TR'
                                         and override_ind = 'Y');
                  if SQL%FOUND then
                     O_approved := FALSE;
                  end if;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_dimension_req_ind = 'Y' then
            SQL_LIB.SET_MARK('OPEN','C_CHECK_DIMS',I_item,NULL);
            open C_CHECK_DIMS;
            SQL_LIB.SET_MARK('FETCH','C_CHECK_DIMS',I_item,NULL);
            fetch C_CHECK_DIMS into L_dimensions_exist;
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_DIMS',I_item,NULL);
            close C_CHECK_DIMS;
            if L_dimensions_exist = 'N' then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_DIMS',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_DIMS'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_diffs_req_ind = 'Y' and L_item_master_rec.pack_ind != 'Y' then
            if ITEM_ATTRIB_SQL.GET_DIFFS(O_error_message,
                                         L_diff_1,
                                         L_diff_2,
                                         L_diff_3,
                                         L_diff_4,
                                         I_item) = FALSE then
               return FALSE;
            end if;
            if L_diff_1 is NULL and L_diff_2 is NULL and L_diff_3 is NULL and L_diff_4 is NULL then
               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_DIFFS',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_DIFFS'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------


         --------------------------------------------------------------------

         if L_mfg_rec_req_ind = 'Y' and L_item_master_rec.mfg_rec_retail is NULL and
            L_item_master_rec.sellable_ind = 'Y' then

            insert into item_approval_error
                        (item,
                         error_key,
                         system_req_ind,
                         override_ind,
                         last_update_id,
                         last_update_datetime)
             select I_item,
                    'IT_NO_MFG',
                    'N',
                    'N',
                    user,
                    sysdate
               from dual
              where not exists (select 'x'
                                  from item_approval_error
                                 where item = I_item
                                   and error_key = 'IT_NO_MFG'
                                   and override_ind = 'Y');
            if SQL%FOUND then
               O_approved := FALSE;
            end if;
         end if;
         --------------------------------------------------------------------

         if L_pack_sz_req_ind = 'Y' and (L_item_master_rec.package_size is NULL or L_item_master_rec.package_uom is NULL) then

            insert into item_approval_error
                        (item,
                         error_key,
                         system_req_ind,
                         override_ind,
                         last_update_id,
                         last_update_datetime)
             select I_item,
                    'IT_NO_PACKSIZE',
                    'N',
                    'N',
                    user,
                    sysdate
               from dual
              where not exists (select 'x'
                                  from item_approval_error
                                 where item = I_item
                                   and error_key = 'IT_NO_PACKSIZE'
                                   and override_ind = 'Y');
            if SQL%FOUND then
               O_approved := FALSE;
            end if;
         end if;
        --------------------------------------------------------------------



         if L_retail_lb_req_ind = 'Y' and
            (L_item_master_rec.retail_label_type is NULL or L_item_master_rec.retail_label_value is NULL) then

            insert into item_approval_error
                        (item,
                         error_key,
                         system_req_ind,
                         override_ind,
                         last_update_id,
                         last_update_datetime)
             select I_item,
                    'IT_NO_RET_LABEL',
                    'N',
                    'N',
                    user,
                    sysdate
               from dual
              where not exists (select 'x'
                                  from item_approval_error
                                 where item = I_item
                                   and error_key = 'IT_NO_RET_LABEL'
                                   and override_ind = 'Y');
            if SQL%FOUND then
               O_approved := FALSE;
            end if;
         end if;
         --------------------------------------------------------------------



         if  L_handling_req_ind = 'Y' and L_item_master_rec.handling_sensitivity is NULL then

            insert into item_approval_error
                        (item,
                         error_key,
                         system_req_ind,
                         override_ind,
                         last_update_id,
                         last_update_datetime)
             select I_item,
                    'IT_NO_HAND_SENS',
                    'N',
                    'N',
                    user,
                    sysdate
               from dual
              where not exists (select 'x'
                                  from item_approval_error
                                 where item = I_item
                                   and error_key = 'IT_NO_HAND_SENS'
                                   and override_ind = 'Y');
            if SQL%FOUND then
               O_approved := FALSE;
            end if;
         end if;
         --------------------------------------------------------------------



         if L_handling_temp_req_ind = 'Y' and L_item_master_rec.handling_temp is NULL then

            insert into item_approval_error
                        (item,
                         error_key,
                         system_req_ind,
                         override_ind,
                         last_update_id,
                         last_update_datetime)
             select I_item,
                    'IT_NO_HAND_TEMP',
                    'N',
                    'N',
                    user,
                    sysdate
               from dual
              where not exists (select 'x'
                                  from item_approval_error
                                 where item = I_item
                                   and error_key = 'IT_NO_HAND_TEMP'
                                   and override_ind = 'Y');
            if SQL%FOUND then
               O_approved := FALSE;
            end if;

         end if;
         --------------------------------------------------------------------



         if L_comments_req_ind = 'Y' and L_item_master_rec.comments is NULL then

            insert into item_approval_error
                        (item,
                         error_key,
                         system_req_ind,
                         override_ind,
                         last_update_id,
                         last_update_datetime)
             select I_item,
                    'IT_NO_COMMENTS',
                    'N',
                    'N',
                    user,
                    sysdate
               from dual
              where not exists (select 'x'
                                  from item_approval_error
                                 where item = I_item
                                   and error_key = 'IT_NO_COMMENTS'
                                   and override_ind = 'Y');
            if SQL%FOUND then
               O_approved := FALSE;
            end if;
         end if;
         --------------------------------------------------------------------
         if L_wastage_req_ind = 'Y' then



            if L_item_master_rec.waste_pct is NULL or
               L_item_master_rec.default_waste_pct is NULL or
               L_item_master_rec.waste_type is NULL then

               insert into item_approval_error
                           (item,
                            error_key,
                            system_req_ind,
                            override_ind,
                            last_update_id,
                            last_update_datetime)
                select I_item,
                       'IT_NO_WASTE',
                       'N',
                       'N',
                       user,
                       sysdate
                  from dual
                 where not exists (select 'x'
                                     from item_approval_error
                                    where item = I_item
                                      and error_key = 'IT_NO_WASTE'
                                      and override_ind = 'Y');
               if SQL%FOUND then
                  O_approved := FALSE;
               end if;
            end if;
         end if;
         --------------------------------------------------------------------
            -- Defect Id-NBS00004044, Nitin Kumar, nitin.kumar@in.tesco.com Begin
        --  end if;
            -- Defect Id-NBS00004044, Nitin Kumar, nitin.kumar@in.tesco.com End
         --26-Aug-2009   Wipro/JK    CR236   Begin
         if L_tsl_single_instance = 'Y' then
            if MERCH_DEFAULT_SQL.TSL_GET_REQD_ATTR(O_error_message,
                                                   L_new_attrib_req_exists,
                                                   -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
                                                   L_new_roi_itattrib_exists,
                                                   -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
                                                   I_item,
                                                   L_item_master_rec.dept,
                                                   L_item_master_rec.class,
                                                   L_item_master_rec.subclass) =  FALSE then
                  return FALSE;
            end if;

            -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
            if L_itattrib_exists = 'Y' then
            -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End

               if L_new_attrib_req_exists = 'N' then
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'ITEM_APPROVAL_ERROR',
                                   ' Error Key: IT_NO_ATTRIB_CTRY@UK');
                  insert into item_approval_error(item,
                                                  error_key,
                                                  system_req_ind,
                                                  override_ind,
                                                  last_update_id,
                                                  last_update_datetime)
                                         select I_item,
                                                'IT_NO_ATTRIB_CTRY@UK',
                                                'N',
                                                'N',
                                                user,
                                                sysdate
                                           from dual
                                           where not exists (select 'x'
                                                               from item_approval_error
                                                              where item = I_item
                                                                and error_key = 'IT_NO_ATTRIB_CTRY@UK'
                                                                and override_ind = 'Y');
                                            if SQL%FOUND then
                                               O_approved := FALSE;
                                            end if;
               end if;
            -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
            -- DefNBS016999, 28-Apr-2010, Govindarajan K, Begin
            -- commented the following code to approve an item if atleast on item attributes is complete.
            --12-May-2010 Murali  Cr288b Begin
            end if;
            if L_roi_itattrib_exists = 'Y' then
            --12-May-2010 Murali  Cr288b End
            -- DefNBS016999, 28-Apr-2010, Govindarajan K, End
            -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
               if L_new_roi_itattrib_exists = 'N' then
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'ITEM_APPROVAL_ERROR',
                                   ' Error Key: IT_NO_ATTRIB_CTRY@ROI');
                  insert into item_approval_error(item,
                                                  error_key,
                                                  system_req_ind,
                                                  override_ind,
                                                  last_update_id,
                                                  last_update_datetime)
                                         select I_item,
                                                'IT_NO_ATTRIB_CTRY@ROI',
                                                'N',
                                                'N',
                                                user,
                                                sysdate
                                           from dual
                                           where not exists (select 'x'
                                                               from item_approval_error
                                                              where item = I_item
                                                                and error_key = 'IT_NO_ATTRIB_CTRY@ROI'
                                                                and override_ind = 'Y');
                                            if SQL%FOUND then
                                               O_approved := FALSE;
                                            end if;
               end if;
            -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 Begin
            -- DefNBS016999, 28-Apr-2010, Govindarajan K, Begin
            -- commented the following code to approve an item if atleast on item attributes is complete.
            -- end if;
            elsif L_roi_itattrib_exists = 'Y' then
            -- DefNBS016999, 28-Apr-2010, Govindarajan K, End
            ---DefNBS016489 Tarun Kumar Mishra tarun.mishra@in.tesco.com 2-March-2010 End
               if L_itattrib_exists = 'N' and L_roi_itattrib_exists = 'N' then
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'ITEM_APPROVAL_ERROR',
                                   ' Error Key: IT_NO_ATTRIB_CTRY@UK');
                  insert into item_approval_error(item,
                                                  error_key,
                                                  system_req_ind,
                                                  override_ind,
                                                  last_update_id,
                                                  last_update_datetime)
                                         select I_item,
                                                'IT_NO_ATTRIB_CTRY@UK',
                                                'N',
                                                'N',
                                                user,
                                                sysdate
                                           from dual
                                           where not exists (select 'x'
                                                               from item_approval_error
                                                              where item = I_item
                                                                and error_key = 'IT_NO_ATTRIB_CTRY@UK'
                                                                and override_ind = 'Y');
                                            if SQL%FOUND then
                                               O_approved := FALSE;
                                            end if;

                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'ITEM_APPROVAL_ERROR',
                                   ' Error Key: IT_NO_ATTRIB_CTRY@ROI');

                  insert into item_approval_error(item,
                                                  error_key,
                                                  system_req_ind,
                                                  override_ind,
                                                  last_update_id,
                                                  last_update_datetime)
                                         select I_item,
                                                'IT_NO_ATTRIB_CTRY@ROI',
                                                'N',
                                                'N',
                                                user,
                                                sysdate
                                           from dual
                                           where not exists (select 'x'
                                                               from item_approval_error
                                                              where item = I_item
                                                                and error_key = 'IT_NO_ATTRIB_CTRY@ROI'
                                                                and override_ind = 'Y');
                                            if SQL%FOUND then
                                               O_approved := FALSE;
                                            end if;

               end if;
            ---DefNBS016489 Tarun Kumar Mishra tarun.mishra@in.tesco.com 2-March-2010 Begin
            end if;
            ---DefNBS016489 Tarun Kumar Mishra tarun.mishra@in.tesco.com 2-March-2010 End
            -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 09-Feb-2010 End
            -- DefNBS016764, 05-Apr-2010, Govindarajan K, Begin
            if (L_item_master_rec.item_level = 2 and L_item_master_rec.pack_ind = 'N' and L_item_master_rec.tran_level = 2) or
            -- 19-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
               (L_item_master_rec.item_level = 1 and L_item_master_rec.pack_ind = 'Y' and L_item_master_rec.simple_pack_ind = 'Y') then
            -- 19-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
               if ITEM_APPROVAL_SQL_FIX.TSL_CHECK_COMP_ATTRIB (O_error_message,
                                                           L_sink,
                                                           -- 20-May-2010, DefNBS017547, Govindarajan K,  Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                           L_rtk_key,
                                                           -- 20-May-2010, DefNBS017547, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                                           L_err_item,
                                                           I_item,
                                                           L_item_master_rec.item_level,
                                                           L_item_master_rec.pack_ind) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_sink = FALSE then
                  ---
                  -- 19-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                  if INSERT_ERROR(O_error_message,
                                  L_err_item,
                                  -- 20-May-2010, DefNBS017547, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                  L_rtk_key,
                                  'Y',
                                  -- 20-May-2010, DefNBS017547, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                  'N') = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if SQL%FOUND then
                     O_approved := FALSE;
                  end if;
                  -- 19-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                  ---
               end if;
            end if;
            -- DefNBS016764, 05-Apr-2010, Govindarajan K, End
            ---
            -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
            -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
            -- 12-Jul-2010, CR288C, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
            ---
            if L_item_master_rec.item_level <= L_item_master_rec.tran_level then
               if L_itattrib_exists = 'Y' then
                  L_valid_supp_uk := 'N';
                  if ITEM_MASTER_SQL.TSL_VALID_SUPP (O_error_message,
                                                     L_valid_supp_uk,
                                                     I_item,
                                                     'U') = FALSE then
                     return FALSE;
                  end if;
               end if;
               ---
               if L_roi_itattrib_exists = 'Y' then
                  L_valid_supp_roi := 'N';
                  if ITEM_MASTER_SQL.TSL_VALID_SUPP (O_error_message,
                                                     L_valid_supp_roi,
                                                     I_item,
                                                     'R') = FALSE then
                     return FALSE;
                  end if;
               end if;
               ---
               if (L_valid_supp_uk = 'N' or
                   L_valid_supp_roi = 'N') then
                  if L_valid_supp_uk = 'N' then
                     if INSERT_ERROR(O_error_message,
                                     I_item,
                                     'TSL_INVALID_UK_SUPP',
                                     'Y',
                                     'N') = FALSE then
                        return FALSE;
                     end if;
                     ---
                  end if;
                  ---
                  if L_valid_supp_roi = 'N' then
                     if INSERT_ERROR(O_error_message,
                                     I_item,
                                     'TSL_INVALID_ROI_SUPP',
                                     'Y',
                                     'N') = FALSE then
                        return FALSE;
                     end if;
                     ---
                  end if;
                  ---
                  if SQL%FOUND then
                     O_approved := FALSE;
                  end if;
                  ---
               end if;
               ---
            end if;
            ---
            -- 12-Jul-2010, CR288C, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
            -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
            -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
            ---
         else
         --26-Aug-2009   Wipro/JK    CR236   End
            -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com ,22-May-2009 ,Begin
            if MERCH_DEFAULT_SQL.TSL_GET_REQD_ATTR(O_error_message,
                                                   L_req_L1_L2_attrib_exists,
                                                   I_item,
                                                   L_item_master_rec.dept,
                                                   L_item_master_rec.class,
                                                   L_item_master_rec.subclass) =  FALSE then
                      return FALSE;
            end if;

            if L_req_L1_L2_attrib_exists = 'N' then
               insert into item_approval_error(item,
                                         error_key,
                                         system_req_ind,
                                         override_ind,
                                         last_update_id,
                                         last_update_datetime)
                                  select I_item,
                                         'IT_NO_ATTRIB',
                                         'N',
                                         'N',
                                         user,
                                         sysdate
                                    from dual
                                   where not exists (select 'x'
                                                       from item_approval_error
                                                      where item = I_item
                                                        and error_key = 'IT_NO_ATTRIB'
                                                        and override_ind = 'Y');
                                   if SQL%FOUND then
                                      O_approved := FALSE;
                                   end if;
            end if;
           -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com ,22-May-2009 ,End
        --26-Aug-2009   Wipro/JK    CR236   Begin
        end if;
        --26-Aug-2009   Wipro/JK    CR236   End
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when DUP_VAL_ON_INDEX then
      NULL;
      RETURN TRUE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END APPROVAL_CHECK;
----------------------------------------------------------------
FUNCTION UPDATE_STATUS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_new_status      IN       ITEM_MASTER.STATUS%TYPE,
                       I_item            IN       ITEM_MASTER.ITEM%TYPE,
                       I_item_level      IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                       I_tran_level      IN       ITEM_MASTER.TRAN_LEVEL%TYPE)
RETURN BOOLEAN IS

   L_program                VARCHAR2(40)                     := 'ITEM_APPROVAL_SQL_FIX.UPDATE_STATUS';
   L_dummy                  VARCHAR2(1);
   L_unit_cost              ITEM_SUPP_COUNTRY.UNIT_COST%TYPE := NULL;
   L_standard_unit_retail   ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE := NULL;
   L_standard_uom           ITEM_MASTER.STANDARD_UOM%TYPE    := NULL;
   L_selling_unit_retail    ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE := NULL;
   L_selling_uom            ITEM_ZONE_PRICE.SELLING_UOM%TYPE := NULL;


   cursor C_ITEM_MASTER is
      select 'x'
        from item_master
       where item = I_item
         for update nowait;

BEGIN
   if I_new_status = 'A' AND
      NVL(I_tran_level, 1) >= NVL(I_item_level, 1) then
      -- Get base retail
      if ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL(O_error_message,
                                              L_unit_cost,
                                              L_standard_unit_retail,
                                              L_standard_uom,
                                              L_selling_unit_retail,
                                              L_selling_uom,
                                              I_item) = FALSE then
          return FALSE;
      end if;
   end if;

   --- Lock the record
   open C_ITEM_MASTER;
   fetch C_ITEM_MASTER into L_dummy;
   close C_ITEM_MASTER;

   --12-May-2010 Murali  Cr288b Begin
   if I_new_status = 'A' then
      if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                              I_item) = FALSE then
         return FALSE;
      end if;
   end if;
   --12-May-2010 Murali  Cr288b End

   --- Update the status
   update item_master
      set status          = I_new_status,
          original_retail = L_standard_unit_retail,
          last_update_datetime = sysdate,
          last_update_id = user
    where item = I_item;


   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   --07-Jul-2010 Tesco HSC/Joy Stephen            DefNBS018153  Begin
   --As part of this defect fix we have moved the below piece of code after CR288b code.
   --15-Apr-2010 Tesco HSC/Usha Patil             Mod: CR295 Begin
   /*if I_new_status = 'A' then
      if ITEM_APPROVAL_SQL_FIX.TSL_UPDATE_ITEM_ATTR (O_error_message,
                                                 I_item) = FALSE then
         return FALSE;
      end if;

      if ITEM_APPROVAL_SQL_FIX.TSL_UPDATE_SCA (O_error_message,
                                           I_item) = FALSE then
         return FALSE;
      end if;
   end if;*/
   --15-Apr-2010 Tesco HSC/Usha Patil             Mod: CR295 End
   --07-Jul-2010 Tesco HSC/Joy Stephen            DefNBS018153  End
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End

   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_STATUS;
----------------------------------------------------------------
FUNCTION UPDATE_STATUS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_new_status      IN       ITEM_MASTER.STATUS%TYPE,
                       I_item            IN       ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program                VARCHAR2(40)                     := 'ITEM_APPROVAL_SQL_FIX.UPDATE_STATUS';

BEGIN

   if UPDATE_STATUS(O_error_message,
                    I_new_status,
                    I_item,
                    NULL, -- item level
                    NULL) = FALSE then -- tran level
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_STATUS;
----------------------------------------------------------------
FUNCTION PROCESS_ITEM(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                      I_new_status          IN     ITEM_MASTER.STATUS%TYPE,
                      I_single_record       IN     VARCHAR2,
                      I_item                IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program                     VARCHAR2(64) := 'ITEM_APPROVAL_SQL_FIX.PROCESS_ITEM';
   L_item_desc                   ITEM_MASTER.ITEM_DESC%TYPE := NULL;
   L_dept                        DEPS.DEPT%TYPE := NULL;
   L_class                       CLASS.CLASS%TYPE := NULL;
   L_subclass                    SUBCLASS.SUBCLASS%TYPE := NULL;
   L_parent                      ITEM_MASTER.ITEM%TYPE := NULL;
   L_temp_item                   ITEM_MASTER.ITEM%TYPE := NULL;
   L_item_level                  ITEM_MASTER.TRAN_LEVEL%TYPE := NULL;
   L_tran_level                  ITEM_MASTER.ITEM_LEVEL%TYPE := NULL;
   L_zone_group_id               ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE := NULL;
   L_unit_retail                 ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE := NULL;
   L_unit_cost                   ITEM_SUPP_COUNTRY.UNIT_COST%TYPE := NULL;
   L_selling_unit_retail         ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE := NULL;
   L_selling_uom                 ITEM_ZONE_PRICE.SELLING_UOM%TYPE := NULL;
   L_standard_uom                ITEM_MASTER.STANDARD_UOM%TYPE := NULL;
   L_sellable_ind                ITEM_MASTER.SELLABLE_IND%TYPE := NULL;
   L_unit_retail_loc             ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE := NULL;
   L_uom_loc                     ITEM_MASTER.STANDARD_UOM%TYPE := NULL;
   L_selling_unit_retail_loc     ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE := NULL;
   L_selling_uom_loc             ITEM_ZONE_PRICE.SELLING_UOM%TYPE := NULL;
   L_multi_units_loc             ITEM_ZONE_PRICE.MULTI_UNITS%TYPE := NULL;
   L_multi_unit_retail_loc       ITEM_ZONE_PRICE.MULTI_UNIT_RETAIL%TYPE := NULL;
   L_multi_selling_uom_loc       ITEM_ZONE_PRICE.MULTI_SELLING_UOM%TYPE := NULL;
   L_item_number_type            ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE := NULL;
   L_prefix                      ITEM_MASTER.PREFIX%TYPE := NULL;
   L_format_id                   ITEM_MASTER.FORMAT_ID%TYPE := NULL;
   L_loctr_exists                BOOLEAN;
   L_launch_date                 ITEM_LOC_TRAITS.LAUNCH_DATE%TYPE := NULL;
   L_qty_key_options             ITEM_LOC_TRAITS.QTY_KEY_OPTIONS%TYPE := NULL;
   L_manual_price_entry          ITEM_LOC_TRAITS.MANUAL_PRICE_ENTRY%TYPE := NULL;
   L_deposit_code                ITEM_LOC_TRAITS.DEPOSIT_CODE%TYPE := NULL;
   L_food_stamp_ind              ITEM_LOC_TRAITS.FOOD_STAMP_IND%TYPE := NULL;
   L_wic_ind                     ITEM_LOC_TRAITS.WIC_IND%TYPE := NULL;
   L_proportional_tare_pct       ITEM_LOC_TRAITS.PROPORTIONAL_TARE_PCT%TYPE := NULL;
   L_fixed_tare_value            ITEM_LOC_TRAITS.FIXED_TARE_VALUE%TYPE := NULL;
   L_fixed_tare_uom              ITEM_LOC_TRAITS.FIXED_TARE_UOM%TYPE := NULL;
   L_reward_eligible_ind         ITEM_LOC_TRAITS.REWARD_ELIGIBLE_IND%TYPE := NULL;
   L_natl_brand_comp_item        ITEM_LOC_TRAITS.NATL_BRAND_COMP_ITEM%TYPE := NULL;
   L_return_policy               ITEM_LOC_TRAITS.RETURN_POLICY%TYPE := NULL;
   L_stop_sale_ind               ITEM_LOC_TRAITS.STOP_SALE_IND%TYPE := NULL;
   L_elect_mtk_clubs             ITEM_LOC_TRAITS.ELECT_MTK_CLUBS%TYPE := NULL;
   L_report_code                 ITEM_LOC_TRAITS.REPORT_CODE%TYPE := NULL;
   L_req_shelf_life_on_selection ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_SELECTION%TYPE := NULL;
   L_req_shelf_life_on_receipt   ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_RECEIPT%TYPE := NULL;
   L_ib_shelf_life               ITEM_LOC_TRAITS.IB_SHELF_LIFE%TYPE := NULL;
   L_store_reorderable_ind       ITEM_LOC_TRAITS.STORE_REORDERABLE_IND%TYPE := NULL;
   L_rack_size                   ITEM_LOC_TRAITS.RACK_SIZE%TYPE := NULL;
   L_full_pallet_item            ITEM_LOC_TRAITS.FULL_PALLET_ITEM%TYPE := NULL;
   L_in_store_market_basket      ITEM_LOC_TRAITS.IN_STORE_MARKET_BASKET%TYPE := NULL;
   L_storage_location            ITEM_LOC_TRAITS.STORAGE_LOCATION%TYPE := NULL;
   L_alt_storage_location        ITEM_LOC_TRAITS.ALT_STORAGE_LOCATION%TYPE := NULL;
   L_pack_ind                    ITEM_MASTER.PACK_IND%TYPE := NULL;
   L_orderable_ind               ITEM_MASTER.ORDERABLE_IND%TYPE := NULL;
   L_unit_cost_sup               ITEM_LOC_SOH.UNIT_COST%TYPE := NULL;
   L_unit_cost_loc               ITEM_LOC_SOH.UNIT_COST%TYPE := NULL;
   L_loc                         ITEM_SUPP_COUNTRY_LOC.LOC%TYPE := NULL;
   --
   L_status                      ITEM_MASTER.STATUS%TYPE;
   L_dept_name                   DEPS.DEPT_NAME%TYPE;
   L_class_name                  CLASS.CLASS_NAME%TYPE;
   L_subclass_name               SUBCLASS.SUB_NAME%TYPE;
   L_pack_type                   ITEM_MASTER.PACK_TYPE%TYPE;
   L_simple_pack_ind             ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_waste_type                  ITEM_MASTER.WASTE_TYPE%TYPE;
   L_item_grandparent            ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_short_desc                  ITEM_MASTER.SHORT_DESC%TYPE;
   L_waste_pct                   ITEM_MASTER.WASTE_PCT%TYPE;
   L_default_waste_pct           ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE;
   L_diff_1                      ITEM_MASTER.DIFF_1%TYPE;
   L_diff_1_desc                 V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_1_type                 V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_1_id_group_ind         V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_diff_2                      ITEM_MASTER.DIFF_2%TYPE;
   L_diff_2_desc                 V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_2_type                 V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_2_id_group_ind         V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_order_as_type               ITEM_MASTER.ORDER_AS_TYPE%TYPE;
   L_store_ord_mult              ITEM_MASTER.STORE_ORD_MULT%TYPE;
   L_contains_inner_ind          ITEM_MASTER.CONTAINS_INNER_IND%TYPE;
   --
   L_returnable_ind              ITEM_LOC_TRAITS.RETURNABLE_IND%TYPE;
   L_refundable_ind              ITEM_LOC_TRAITS.RETURNABLE_IND%TYPE;
   L_back_order_ind              ITEM_LOC_TRAITS.BACK_ORDER_IND%TYPE;


   L_vat_ind                     SYSTEM_OPTIONS.VAT_IND%TYPE              := NULL;
   L_vat_code                    POS_MODS.VAT_CODE%TYPE                   := NULL;
   L_vat_rate                    POS_MODS.VAT_RATE%TYPE                   := NULL;
   -- 12.03.2008, ORMS 364.2,Richard Addison(BEGIN)
   L_tsl_tesco_cost_model        SYSTEM_OPTIONS.TSL_TESCO_COST_MODEL%TYPE := NULL;
   -- 12.03.2008, ORMS 364.2,Richard Addison(BEGIN)
   --Fix for NBS00006962 by Bahubali Dongare Begin
   L_epw_ind                     ITEM_ATTRIBUTES.TSL_EPW_IND%TYPE;
   --Fix for NBS00006962 by Bahubali Dongare End
   --Defect NBS014202 Raghuveer P R 27-Jul-2009  - Begin
   L_rec_exists      VARCHAR2(1) := NULL;
   --Defect NBS014202 Raghuveer P R 27-Jul-2009  - End
   --06-Aug-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS014327 Begin
   L_rec_found                   VARCHAR2(1);
   --06-Aug-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS014327 End
   --25-Aug-2009  Wipro/JK   CR236  Begin
   L_tsl_single_instance_ind     SYSTEM_OPTIONS.TSL_SINGLE_INSTANCE_IND%TYPE := NULL;
   L_cost_zone_group_id          ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE := NULL;
   --25-Aug-2009  Wipro/JK   CR236  End

   cursor C_ITEM_MASTER is
      select 'x'
        from item_master
       where item = I_item
         for update nowait;

   cursor C_LOCS is
      select il.item,
             il.loc,
             il.loc_type,
             il.local_item_desc,
             ils.unit_cost,
             il.taxable_ind,
             il.status,
             il.primary_supp,
             il.primary_cntry
        from item_loc il, item_loc_soh ils
       where il.item = I_item
         and il.item = ils.item(+)
         and il.loc  = ils.loc(+);

   cursor C_ITEM_SUPP_CTRY_LOC is
      select loc iscl_loc,
             loc_type iscl_loc_type,
             supplier iscl_supplier,
             origin_country_id iscl_origin_country_id,
             unit_cost iscl_unit_cost
        from item_supp_country_loc
       where item = I_item
         and loc = L_loc;

   cursor C_VAT_ITEM is
      select v.vat_code,
             v.vat_rate
        from vat_item v,
             store s
       where v.item        = I_item
         and s.store       = L_loc
         and s.vat_region  = v.vat_region
         and v.vat_type     in('R','B')
         and v.active_date = (select MAX(v2.active_date)
                                from vat_item v2
                               where v2.vat_region = v.vat_region
                                 and v2.item = I_item
                                 and v.vat_type in ('R','B')
                                 and v2.active_date <= LP_vdate);

   -- 12.03.2008, ORMS 364.2,Richard Addison(BEGIN)
   cursor C_SYS_OPTS is
      select NVL(tsl_tesco_cost_model,'N'),
             --25-Aug-2009  Wipro/JK   CR236   Begin
             tsl_single_instance_ind
             --25-Aug-2009  Wipro/JK   CR236   End
        from system_options;
   -- 12.03.2008, ORMS 364.2,Richard Addison(BEGIN)

   --Defect NBS014202 Raghuveer P R 27-Jul-2009  - Begin
   cursor C_RCCQ_DUP(Cp_supplier           ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                     Cp_origin_country_id  ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                     Cp_location           ITEM_SUPP_COUNTRY_LOC.LOC%TYPE) is
      select 'x'
        from reclass_cost_chg_queue
       where item              = I_item
         and supplier          = Cp_supplier
         and origin_country_id = Cp_origin_country_id
         and start_date        = LP_vdate
         and location          = Cp_location
         and rec_type          = 'N';
     --Defect NBS014202 Raghuveer P R 27-Jul-2009  - End

   --25-Aug-2009  Wipro/JK   CR236   Begin
   --08-Apr-10   JK   MrgNBS016979   Begin
   --25-Mar-2010 Tesco HSC/Usha Patil         Mod: CR275 Begin
   --Removed the code of CR236
   --25-Mar-2010 Tesco HSC/Usha Patil         Mod: CR275 End
   --08-Apr-10   JK   MrgNBS016979   End
   --25-Aug-2009  Wipro/JK   CR236   End

BEGIN
   ---
   if I_new_status = 'A' then
      if ITEM_ATTRIB_SQL.GET_INFO (O_error_message,
                                   L_item_desc,
                                   L_item_level,
                                   L_tran_level,
                                   L_status,
                                   L_pack_ind,
                                   L_dept,
                                   L_dept_name,
                                   L_class,
                                   L_class_name,
                                   L_subclass,
                                   L_subclass_name,
                                   L_zone_group_id,
                                   L_sellable_ind, --sellable_ind
                                   L_orderable_ind,
                                   L_pack_type,
                                   L_simple_pack_ind,
                                   L_waste_type,
                                   L_parent, --item_parent
                                   L_item_grandparent,
                                   L_short_desc,
                                   L_waste_pct,
                                   L_default_waste_pct,
                                   L_item_number_type,
                                   L_diff_1,
                                   L_diff_1_desc,
                                   L_diff_1_type,
                                   L_diff_1_id_group_ind,
                                   L_diff_2,
                                   L_diff_2_desc,
                                   L_diff_2_type,
                                   L_diff_2_id_group_ind,
                                   L_order_as_type,
                                   L_format_id,
                                   L_prefix,
                                   L_store_ord_mult,
                                   L_contains_inner_ind,
                                   I_item) = FALSE then
         return FALSE;
      end if;
   end if;

   if nvl(I_single_record,'N') = 'N' then
      if UPDATE_STATUS(O_error_message,
                       I_new_status,
                       I_item,
                       L_item_level,
                       L_tran_level) = FALSE then
         return false;
      end if;
      -- 12.02.2008, ORMS 364.2,Richard Addison(BEGIN)
      -- 14-Jul-2008 Dhuraison Prince - Defect NBS007787 BEGIN
         SQL_LIB.SET_MARK('OPEN', 'C_sys_opts','system_options',NULL);
         open C_SYS_OPTS;
      ---
         SQL_LIB.SET_MARK('FETCH', 'C_sys_opts','system_options',NULL);
         fetch C_SYS_OPTS into L_tsl_tesco_cost_model,
         --25-Aug-2009  Wipro/JK   CR236  Begin
                               L_tsl_single_instance_ind;
         --25-Aug-2009  Wipro/JK   CR236  End
      ---
         SQL_LIB.SET_MARK('CLOSE', 'C_sys_opts','system_options',NULL);
         close C_SYS_OPTS;
      ---
      if L_tsl_tesco_cost_model = 'Y' and I_new_status = 'A'then
         ---
         if L_item_level = L_tran_level and L_pack_ind = 'N' then
            O_error_message := ' ';
            if (TSL_APPLY_REAL_TIME_COST(O_error_message,
                                         I_item,
                                         'Y',
   -- 26-Aug-2008 Tesco HSC/Satish B.N DefNBS007325 Begin
                                         'O') != 0) then
   -- 26-Aug-2008 Tesco HSC/Satish B.N DefNBS007325 End
               return FALSE;
             end if;
         elsif L_item_level = L_tran_level and L_pack_ind = 'Y' then
            if TSL_MARGIN_SQL.INSERT_FUTURE_EXPENSES(O_error_message,
                                                     I_item) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
      end if;
      -- 14-Jul-2008 Dhuraison Prince - Defect NBS007787 END
      -- 12.02.2008, ORMS 364.2,Richard Addison(END)
      ---
   end if; --status update will have to be done in calling form for record locking issues
   ---
   if I_new_status = 'A' then
      --Fix for NBS00005976 and NBS00006962 by Bahubali Dongare Begin

      if ITEM_ATTRIB_SQL.TSL_GET_EPW (O_error_message,
                                      L_epw_ind,
                                      L_parent) = FALSE then
         return FALSE;
         --bb

      end if;
      if L_epw_ind is NOT NULL then
         if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_DOWN_PARENT_EPW(O_error_message,
                                                             I_item,
                                                             L_epw_ind) = FALSE then
            return FALSE;
         end if;
      end if;
     --Fix for NBS00005976 and NBS00006962 by Bahubali Dongare End
      ---
      if L_item_level <= L_tran_level then
         -- if the item is at or above the transaction level, then get the retail for the item
         L_temp_item := I_item;
      else
         -- if the item is below the transaction level, then get the retail for its parent
         L_temp_item := L_parent;
      end if;

      if ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL(O_error_message,
                                              L_unit_cost,
                                              L_unit_retail,
                                              L_standard_uom,
                                              L_selling_unit_retail,
                                              L_selling_uom,
                                              L_temp_item) = FALSE then
         return FALSE;
      end if;
      ---
      if L_item_level = L_tran_level then
         insert into repl_item_loc_updates(item,
                                           supplier,
                                           origin_country_id,
                                           location,
                                           loc_type,
                                           change_type)
                                   (select distinct item,
                                                    NULL,
                                                    NULL,
                                                    location,
                                                    loc_type,
                                                    'IM'
                                      from repl_item_loc
                                     where item = I_item
                                       and rownum = 1);
      end if;
      ---
      if L_item_level <= L_tran_level then
         ---
         insert into price_hist(tran_type,
                                reason,
                                event,
                                item,
                                loc,
                                loc_type,
                                unit_cost,
                                unit_retail,
                                selling_unit_retail,
                                selling_uom,
                                action_date,
                                multi_units,
                                multi_unit_retail,
                                multi_selling_uom)
                        values (0, --tran_type
                                0, --reason
                                NULL, --event
                                I_item,
                                0, --loc
                                NULL, --loc_type
                                L_unit_cost,
                                L_unit_retail,
                                L_selling_unit_retail,
                                L_selling_uom,
                                LP_vdate, --action_date
                                NULL, --multi_units
                                NULL, --multi_unit_retail
                                NULL --multi_selling_uom
                                );

         for recs in C_LOCS loop
            BEGIN


               ---
               if L_sellable_ind = 'Y' then


                     if PRICING_ATTRIB_SQL.GET_RETAIL(O_error_message,
                                                      L_unit_retail_loc,
                                                      L_uom_loc,
                                                      L_selling_unit_retail_loc,
                                                      L_selling_uom_loc,
                                                      L_multi_units_loc,
                                                      L_multi_unit_retail_loc,
                                                      L_multi_selling_uom_loc,
                                                      recs.item,
                                                      recs.loc_type,
                                                      recs.loc) = FALSE then
                        return FALSE;
                     end if;


               end if; -- end sellable_ind = 'Y'
               ---
               --For each location, insert a record into the RECLASS_COST_CHG_QUEUE
               --table to ensure that there is at least one record for each approved item/loc
               --on the table.  The PK on RECLASS_COST_CHG_QUEUE is item/supp/country/loc so
               --the supp/country combinations for each item/loc need to be fetched and looped through.
               ---
               if L_item_level = L_tran_level then
                  ---
                  --need to do this assignment - can't reference a rec. variable in a cursor definition
                  L_loc := recs.loc;
                  ---
                  for recs in C_ITEM_SUPP_CTRY_LOC loop
                     ---
                     --Unit cost on item_supp_country is stored in supplier currency
                     --and should be inserted into reclass_cost_change_queue in supp currency.
                     --The reclass_cost_chg_queue.start_date should be vdate.  The group,
                     --division, dept, class and subclass fields should only be
                     --populated in reclass_cost_chg_queue if the action creating the
                     --record is a reclass.
                     ---
                     --Defect NBS014202 Raghuveer P R 27-Jul-2009  - Begin
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_RCCQ_DUP',
                                      'RECLASS_COST_CHG_QUEUE',
                                      'Item: '|| I_item);
                     open  C_RCCQ_DUP(recs.iscl_supplier,
                                      recs.iscl_origin_country_id,
                                      recs.iscl_loc);
                     SQL_LIB.SET_MARK('FETCH',
                                      'C_RCCQ_DUP',
                                      'RECLASS_COST_CHG_QUEUE',
                                      'Item: '|| I_item);
                     fetch C_RCCQ_DUP into L_rec_exists;
                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_RCCQ_DUP',
                                      'RECLASS_COST_CHG_QUEUE',
                                      'Item: '|| I_item);
                     close C_RCCQ_DUP;
                     if L_rec_exists is NULL then
                     --Defect NBS014202 Raghuveer P R 27-Jul-2009  - End
                        insert into RECLASS_COST_CHG_QUEUE (item,
                                                            location,
                                                            supplier,
                                                            origin_country_id,
                                                            start_date,
                                                            unit_cost,
                                                            division,
                                                            group_no,
                                                            dept,
                                                            class,
                                                            subclass,
                                                            process_flag,
                                                            loc_type,
                                                            rec_type)
                              values                       (I_item,
                                                            recs.iscl_loc,
                                                            recs.iscl_supplier,
                                                            recs.iscl_origin_country_id,
                                                            LP_vdate,
                                                            recs.iscl_unit_cost,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            'N',
                                                            recs.iscl_loc_type,
                                                            'N');    --rec_type 'N' is for new item
                     --Defect NBS014202 Raghuveer P R 27-Jul-2009  - Begin
                     end if;
                     --Defect NBS014202 Raghuveer P R 27-Jul-2009  - End
                  end loop;
                  ---
               end if;
               ---
               /* Cost of Packs/non-tran level Items is not on item_loc_soh, so fetch cost from supplier tables */
               if ((L_pack_ind = 'Y' and L_orderable_ind = 'Y') or L_item_level < L_tran_level) then
                  if L_unit_cost_sup is NULL then
                     if SUPP_ITEM_SQL.GET_COST(O_error_message,
                                               L_unit_cost_sup,
                                               recs.item,
                                               recs.primary_supp,
                                               recs.primary_cntry,
                                               recs.loc) = FALSE then
                        return FALSE;
                     end if;
                  end if;
                  ---
                  if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                      recs.primary_supp,
                                                      'V',
                                                      NULL,
                                                      recs.loc,
                                                      recs.loc_type,
                                                      NULL,
                                                      L_unit_cost_sup,
                                                      L_unit_cost_loc,
                                                      'C',
                                                      NULL,
                                                      NULL) = FALSE then
                     return FALSE;
                  end if;
               else
                  L_unit_cost_loc := recs.unit_cost;
               end if;

               --06-Aug-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS014327 Begin
               if TSL_GET_PRICE_HIST_REC(O_error_message,
                                         L_rec_found,
                                         recs.item,
                                         recs.loc,
                                         LP_vdate,
                                         L_unit_cost_loc)= FALSE then
                   return FALSE;
               end if;
               if L_rec_found  <> 'Y' then
               --06-Aug-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS014327 End
                 insert into price_hist(tran_type,
                                        reason,
                                        event,
                                        item,
                                        loc,
                                        loc_type,
                                        unit_cost,
                                        unit_retail,
                                        selling_unit_retail,
                                        selling_uom,
                                        action_date,
                                        multi_units,
                                        multi_unit_retail,
                                        multi_selling_uom)
                                values (0, --tran_type
                                        0, --reason
                                        NULL, --event
                                        recs.item,
                                        recs.loc, --loc
                                        recs.loc_type, --loc_type
                                        L_unit_cost_loc,
                                        L_unit_retail_loc,
                                        L_selling_unit_retail_loc,
                                        L_selling_uom_loc,
                                        LP_vdate, --action_date
                                        L_multi_units_loc, --multi_units
                                        L_multi_unit_retail_loc, --multi_unit_retail
                                        L_multi_selling_uom_loc --multi_selling_uom
                                        );
               --06-Aug-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS014327 Begin
               end if;
               --06-Aug-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS014327 End
               if recs.loc_type = 'S'
                  and L_item_level = L_tran_level then
                  if ITEM_LOC_TRAITS_SQL.GET_VALUES(O_error_message,
                                                    L_loctr_exists,
                                                    L_launch_date,
                                                    L_qty_key_options,
                                                    L_manual_price_entry,
                                                    L_deposit_code,
                                                    L_food_stamp_ind,
                                                    L_wic_ind,
                                                    L_proportional_tare_pct,
                                                    L_fixed_tare_value,
                                                    L_fixed_tare_uom,
                                                    L_reward_eligible_ind,
                                                    L_natl_brand_comp_item,
                                                    L_return_policy,
                                                    L_stop_sale_ind,
                                                    L_elect_mtk_clubs,
                                                    L_report_code,
                                                    L_req_shelf_life_on_selection,
                                                    L_req_shelf_life_on_receipt,
                                                    L_ib_shelf_life,
                                                    L_store_reorderable_ind,
                                                    L_rack_size,
                                                    L_full_pallet_item,
                                                    L_in_store_market_basket,
                                                    L_storage_location,
                                                    L_alt_storage_location,
                                                    L_returnable_ind,
                                                    L_refundable_ind,
                                                    L_back_order_ind,
                                                    recs.item,
                                                    recs.loc) = FALSE then
                      return FALSE;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('OPEN', 'C_vat_item', 'store, vat_item', 'Item: '||recs.item||', Store: '||TO_CHAR(recs.loc));
                  open C_VAT_ITEM;
                  SQL_LIB.SET_MARK('FETCH', 'C_vat_item', 'store, vat_item', 'Item: '||recs.item||', Store: '||TO_CHAR(recs.loc));
                  fetch C_VAT_ITEM into L_vat_code,
                                        L_vat_rate;
                  SQL_LIB.SET_MARK('CLOSE', 'C_vat_item', 'store, vat_item', 'Item: '||recs.item||', Store: '||TO_CHAR(recs.loc));
                  close C_VAT_ITEM;
                  ---
                  if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                                    1,--I_tran_type,
                                                    recs.item,
                                                    recs.local_item_desc,--I_item_desc,
                                                    NULL,--I_ref_item,
                                                    L_dept,
                                                    L_class,
                                                    L_subclass,
                                                    recs.loc,--I_store,
                                                    L_selling_unit_retail_loc,--I_new_price
                                                    L_selling_uom_loc,--I_new_selling_uom
                                                    NULL,--I_old_price
                                                    NULL,--I_old_selling_uom
                                                    NULL,--I_start_date
                                                    L_multi_units_loc,--I_new_multi_units
                                                    NULL,--I_old_multi_units
                                                    L_multi_unit_retail_loc,--I_new_multi_unit_retail
                                                    L_multi_selling_uom_loc,--I_new_multi_selling_uom
                                                    NULL,--I_old_multi_unit_retail
                                                    NULL,--I_old_multi_selling_uom
                                                    recs.status,--I_status
                                                    recs.taxable_ind,--I_taxable_ind
                                                    L_launch_date,--I_launch_date
                                                    L_qty_key_options,--I_qty_key_options
                                                    L_manual_price_entry,--I_manual_price_entry
                                                    L_deposit_code,--I_deposit_code
                                                    L_food_stamp_ind,--I_food_stamp_ind
                                                    L_wic_ind,--I_wic_ind
                                                    L_proportional_tare_pct,--I_proportional_tare_pct
                                                    L_fixed_tare_value,--I_fixed_tare_value
                                                    L_fixed_tare_uom,--I_fixed_tare_uom
                                                    L_reward_eligible_ind,--I_reward_eligible_ind
                                                    L_elect_mtk_clubs,--I_elect_mtk_clubs
                                                    L_return_policy,--I_return_policy
                                                    L_stop_sale_ind,
                                                    L_returnable_ind,
                                                    L_refundable_ind,
                                                    L_back_order_ind,
                                                    L_vat_code,
                                                    L_vat_rate) = FALSE then
                     return FALSE;
                  end if;
               end if;
            END;
         end loop;

      elsif L_item_level > L_tran_level and I_single_record = 'Y' then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           2,--I_tran_type,
                                           L_parent,
                                           NULL,--I_item_desc,
                                           I_item,--I_ref_item,
                                           L_dept,
                                           L_class,
                                           L_subclass,
                                           NULL,--I_store,
                                           L_selling_unit_retail,--I_new_price,
                                           L_selling_uom,--I_new_selling_uom,
                                           NULL,--I_old_price,
                                           NULL,--I_old_selling_uom,
                                           NULL,--I_start_date,
                                           NULL,--I_new_multi_units,
                                           NULL,--I_old_multi_units,
                                           NULL,--I_new_multi_unit_retail,
                                           NULL,--I_new_multi_selling_uom,
                                           NULL,--I_old_multi_unit_retail,
                                           NULL,--I_old_multi_selling_uom,
                                           NULL,--I_status (store),
                                           NULL,--I_taxable_ind,
                                           NULL,--I_launch_date,
                                           NULL,--I_qty_key_options,
                                           NULL,--I_manual_price_entry,
                                           NULL,--I_deposit_code,
                                           NULL,--I_food_stamp_ind,
                                           NULL,--I_wic_ind,
                                           NULL,--I_proportional_tare_pct,
                                           NULL,--I_fixed_tare_value,
                                           NULL,--I_fixed_tare_uom,
                                           NULL,--I_reward_eligible_ind ,
                                           NULL,--I_elect_mtk_clubs,
                                           NULL,--I_return_policy,
                                           NULL) = FALSE then

            return FALSE;
         end if;
      end if;

      delete from item_approval_error
            where item = I_item
      -- 16-Sep-2008 TESCO HSC/Murali  DefNBS008079  Begin
               or item in (select item
                              from packitem_breakout
                              where pack_no = I_item);
      -- 16-Sep-2008 TESCO HSC/Murali  DefNBS008079  End

      --25-Aug-2009  Wipro/JK   CR236  Begin
      if L_tsl_single_instance_ind is null then
         SQL_LIB.SET_MARK('OPEN', 'C_sys_opts','system_options',NULL);
         open C_SYS_OPTS;
         ---
         SQL_LIB.SET_MARK('FETCH', 'C_sys_opts','system_options',NULL);
         fetch C_SYS_OPTS into L_tsl_tesco_cost_model, L_tsl_single_instance_ind;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_sys_opts','system_options',NULL);
         close C_SYS_OPTS;
      end if;

      if L_tsl_single_instance_ind = 'Y' and L_item_level = L_tran_level then
         if ITEM_ATTRIB_SQL.GET_COST_ZONE_GROUP(O_error_message,
                                                L_cost_zone_group_id,
                                                I_item)= FALSE then
            return FALSE;
         end if;
         --08-Apr-10   JK   MrgNBS016979     Begin
         --25-Mar-2010 Tesco HSC/Usha Patil         Mod: CR275 Begin
         --Removed the call to APPLY_CHARGES as it is not required.
         --25-Mar-2010 Tesco HSC/Usha Patil         Mod: CR275 End
         --08-Apr-10   JK   MrgNBS016979     End
      end if;
      --25-Aug-2009  Wipro/JK   CR236  End
   else
      --------------------------------------
      --- I_new_status = 'S'
      --------------------------------------
      delete from item_approval_error
            where item = I_item
              and override_ind = 'N';
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END PROCESS_ITEM;
----------------------------------------------------------------
FUNCTION ERRORS_EXIST(O_error_message        IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                      O_exist                IN OUT BOOLEAN,
                      I_item                 IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program       VARCHAR2(64) := 'ITEM_APPROVAL_SQL_FIX.ERRORS_EXIST';
   L_error_exists  VARCHAR2(1)  := 'N';

   cursor C_ERRORS is
      select /*+ INDEX(iae) */  'Y'
        from item_approval_error iae
           , item_master         im
       where im.item = iae.item
         and (I_item = im.item
              or I_item = im.item_parent
              or I_item = im.item_grandparent)
         and override_ind = 'N'
       and  rownum = 1;

BEGIN
   if I_item is NULL then
      O_error_message  := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                              NULL,
                                              NULL,
                                              NULL);
      return FALSE;
   end if;
   ---
   O_exist := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ERRORS',I_item,NULL);
   open C_ERRORS;
   SQL_LIB.SET_MARK('FETCH','C_ERRORS',I_item,NULL);
   fetch C_ERRORS into L_error_exists;
   SQL_LIB.SET_MARK('CLOSE','C_ERRORS',I_item,NULL);
   close C_ERRORS;
   ---
   if L_error_exists = 'Y' then
      O_exist := TRUE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END ERRORS_EXIST;
----------------------------------------------------------------
FUNCTION WORKSHEET(O_error_message       IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                   O_children_worksheet  IN OUT  BOOLEAN,
                   I_item                IN      ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_dummy     VARCHAR2(1);
   L_program   VARCHAR2(64) := 'ITEM_APPROVAL_SQL_FIX.WORKSHEET';

   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, Begin
   -- PrfNBS016258, 17-Feb-2010, Govindarajan K, Begin
   -- Commented the existing cursor and added new cursor to achieve same functionality
   /*
   cursor C_ITEM_MASTER is
      select 'x'
        from item_master
       where (   I_item = item_parent
              or I_item = item_grandparent
--N111 Chandru N 24-Jun-08 Begin
              or item_parent in (select item
                                   from item_master iem
                                  where iem.tsl_base_item = I_item
                                    and iem.item <> iem.tsl_base_item)
              or item in (select item
                            from item_master iem
                           where iem.tsl_base_item = I_item
                             and iem.item <> iem.tsl_base_item))
--N111 Chandru N 24-Jun-08 End
         and status = 'S'
         for update nowait;


   cursor C_NOT_IN_WORKSHEET is
      select 'x'
        from item_master
       where (   I_item = item_parent
              or I_item = item_grandparent
--N111 Chandru N 24-Jun-08 Begin
              or item_parent in (select item
                                   from item_master iem
                                  where iem.tsl_base_item = I_item
                                    and iem.item <> iem.tsl_base_item)
               or item in (select item
                             from item_master iem
                            where iem.tsl_base_item = I_item
                              and iem.item <> iem.tsl_base_item))
--N111 Chandru N 24-Jun-08 End
         and status in ('A','S');
   */

   cursor C_ITEM_MASTER_1 is
   select 'x'
     from item_master im
    where (im.item_parent = I_item
       or im.item_grandparent = I_item)
      and im.status in ('A','S')
      for update nowait;

   cursor C_ITEM_MASTER_2 is
   select 'x'
     from item_master im1,
          item_master im2
    where im1.tsl_base_item = I_item
      and im1.item != im1.tsl_base_item
      and (im2.item = im1.item
       or im2.item_parent = im1.item)
      and im2.status in ('A','S')
      for update nowait;

   cursor C_NOT_IN_WORKSHEET is
   select 'x'
     from item_master im
    where (im.item_parent = I_item
       or im.item_grandparent = I_item)
      and im.status in ('A','S')
    union
   select 'x'
     from item_master im1,
          item_master im2
    where im1.tsl_base_item = I_item
      and im1.item != im1.tsl_base_item
      and (im2.item = im1.item
       or im2.item_parent = im1.item)
      and im2.status in ('A','S');
   -- PrfNBS016258, 17-Feb-2010, Govindarajan K, End
   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, End

BEGIN
   --- Validate input
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   --- Lock records for updating
   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, Begin
   -- PrfNBS016258, 17-Feb-2010, Govindarajan K, Begin
   open C_ITEM_MASTER_1;
   fetch C_ITEM_MASTER_1 into L_dummy;
   close C_ITEM_MASTER_1;

   open C_ITEM_MASTER_2;
   fetch C_ITEM_MASTER_2 into L_dummy;
   close C_ITEM_MASTER_2;
   ---
   -- PrfNBS016258, 17-Feb-2010, Govindarajan K, End
   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, End

   --- Set to worksheet status
   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, Begin
   -- PrfNBS016258, 17-Feb-2010, Govindarajan K, Begin
   -- commented the existing update and added new update query to improve the performance
   /*
   update item_master
      set status = 'W',
          last_update_datetime = sysdate,
          last_update_id = user
    where item in (select item
                     from item_master
                    where (   I_item = item_parent
                           or I_item = item_grandparent
--N111 Chandru N 24-Jun-08 Begin
                           or item_parent in (select item
                                               from item_master iem
                                              where iem.tsl_base_item = I_item
                                                and iem.item <> iem.tsl_base_item)
                           or item in (select item
                                         from item_master iem
                                        where iem.tsl_base_item = I_item
                                          and iem.item <> iem.tsl_base_item))
--N111 Chandru N 24-Jun-08 End
                      and status = 'S');
   */

   update item_master im
      set im.status = 'W',
          im.last_update_datetime = sysdate,
          im.last_update_id = user
    where (im.item_parent = I_item
       or im.item_grandparent = I_item)
      and im.status = 'S';

   update item_master im
      set im.status = 'W',
          im.last_update_datetime = sysdate,
          im.last_update_id = user
    where im.item in (select im2.item
                        from item_master im1,
                             item_master im2
                       where im1.tsl_base_item = I_item
                         and im1.item != im1.tsl_base_item
                         and (im2.item = im1.item
                          or im2.item_parent = im1.item)
                         and im2.status = 'S');
   ---
   -- PrfNBS016258, 17-Feb-2010, Govindarajan K, End
   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, End
   ---
   --- Delete approval errors
   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, Begin
   -- PrfNBS016258, 17-Feb-2010, Govindarajan K, Begin
   -- commented the existing update and added new update query to improve the performance
   /*
   delete from item_approval_error
         where item in (select item
                          from item_master
                         where (   I_item = item
                                or I_item = item_parent
                                or I_item = item_grandparent)
--N111 Chandru N 24-Jun-08 Begin
                                or item_parent in (select item
                                                     from item_master iem
                                                    where iem.tsl_base_item = I_item
                                                      and iem.item <> iem.tsl_base_item)
                                or item in (select item
                                                     from item_master iem
                                                    where iem.tsl_base_item = I_item
                                                      and iem.item <> iem.tsl_base_item));
--N111 Chandru N 24-Jun-08 End
   */
   delete from item_approval_error iae
         where iae.item in (select im.item
                              from item_master im
                             where (im.item = I_item
                                or im.item_parent = I_item
                                or im.item_grandparent = I_item));

   ---
   delete from item_approval_error iae
         where iae.item in (select im2.item
                              from item_master im1,
                                   item_master im2
                             where im1.tsl_base_item = I_item
                               and im1.item != im1.tsl_base_item
                               and (im2.item = im1.item
                                or im2.item_parent = im1.item));
   ---
   -- PrfNBS016258, 17-Feb-2010, Govindarajan K, End
   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, End
   ---
   --- Check if any children/grandchildren are not in worksheet status
   open C_NOT_IN_WORKSHEET;
   fetch C_NOT_IN_WORKSHEET into L_dummy;
   if C_NOT_IN_WORKSHEET%FOUND then
      O_children_worksheet := FALSE;
   else
      O_children_worksheet := TRUE;
   end if;
   close C_NOT_IN_WORKSHEET;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END WORKSHEET;
----------------------------------------------------------------
FUNCTION APPROVE(O_error_message      IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                 O_item_approved      IN OUT  BOOLEAN,
                 O_children_approved  IN OUT  BOOLEAN,
                 I_appr_children_ind  IN      VARCHAR2,
                 I_item               IN      ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is

   L_program                VARCHAR2(64)            := 'ITEM_APPROVAL_SQL_FIX.APPROVE';
   L_original_item_status   ITEM_MASTER.STATUS%TYPE := NULL;
   L_item_status            ITEM_MASTER.STATUS%TYPE := NULL;
   L_child_status           ITEM_MASTER.STATUS%TYPE := NULL;
   L_tran_level             ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_item_level             ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_grandchilds_parent     ITEM_MASTER.ITEM%TYPE;
   L_grandchild             ITEM_MASTER.ITEM%TYPE;
   L_child                  ITEM_MASTER.ITEM%TYPE;
   L_pack_approved          BOOLEAN;
   L_all_packs_approved     BOOLEAN;
   L_child_approved         BOOLEAN;
   L_grandchild_approved    BOOLEAN;
   L_exists                 BOOLEAN;
   --19-Oct-2007    Wipro/JK ModN22   Begin
   L_tsl_product_auth           SYSTEM_OPTIONS.TSL_PRODUCT_AUTH%TYPE;
   L_valid_pack             BOOLEAN;
   L_valid_occ              BOOLEAN;
   L_valid_occ_sub          BOOLEAN;
   L_valid_occ_item         BOOLEAN;
   --19-Oct-2007    Wipro/JK ModN22  End
   -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , Begin
   L_exists_pack           BOOLEAN;
   -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , End
   -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
   L_occ_parent_status        ITEM_MASTER.STATUS%TYPE := NULL;
   -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
   --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
   L_grandchild_flg        BOOLEAN  :=FALSE;
   L_pack_flg              BOOLEAN  :=FALSE;
   L_new_status            VARCHAR2(1);
   L_pack_ind              VARCHAR2(1);
   --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
   -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 Begin
   --05-Feb-2010 Usha Patil, usha.patil@in.tesco.com DefNBS016054 Begin
   L_sbmt_or_wrksht_pack_exists VARCHAR2(1) := 'N';
   --05-Feb-2010 Usha Patil, usha.patil@in.tesco.com DefNBS016054 End
   ---
   -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   L_sys_opt_rec              SYSTEM_OPTIONS%ROWTYPE;
   L_loc_sec_ind              VARCHAR2(1) := 'N';
   L_location_access          VARCHAR2(1) := 'N';
   L_uk_access                VARCHAR2(1) := 'N';
   L_roi_access               VARCHAR2(1) := 'N';
   -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 End
   cursor C_ITEM_INFO is
      --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
      select status, item_level, tran_level, pack_ind
      --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
        from item_master
       where I_item = item;

   cursor C_CHILDREN is
      select item
           , tran_level
           , item_level
           , status
           --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik Begin
           , tsl_launch_base_ind
           --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik End
        from item_master
       where item_parent = I_item
         -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
         --Assigned tsl_owner_country for 'B' in decode
         and (((tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',tsl_owner_country)
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
         and   L_loc_sec_ind = 'Y')
          or  L_loc_sec_ind = 'N'));
         -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End

   cursor C_GRANDCHILDREN is
      select item
           , tran_level
           , item_level
           , status
        from item_master
       where item_grandparent = I_item
         and item_parent      = L_grandchilds_parent
         -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
         --Assigned tsl_owner_country for 'B' in decode
         and (((tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',tsl_owner_country)
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
         and   L_loc_sec_ind = 'Y')
          or  L_loc_sec_ind = 'N'));
         -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End

   cursor C_PACK(L_item ITEM_MASTER.ITEM%TYPE) is
     select distinct pack_no
       -- 16-Sep-2008 TESCO HSC/Murali  DefNBS008079  Begin
       from packitem pi,
            item_master im
      where im.item = pi.pack_no
        AND pi.item = L_item
        AND im.status in ('W','S')
        -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
        --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
         --Assigned tsl_owner_country for 'B' in decode
        and (((im.tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',im.tsl_owner_country)
        --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
        and   L_loc_sec_ind = 'Y')
         or  L_loc_sec_ind = 'N'));
        -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
        ---
        -- 16-Sep-2008 TESCO HSC/Murali  DefNBS008079  End

   cursor C_ITEM_PACKS(L_packitem ITEM_MASTER.ITEM%TYPE) is
       select item pack_no
         from item_master im
        where (im.item = L_packitem or
               im.item_parent=L_packitem or
               im.item_grandparent=L_packitem)
          and im.status in ('W','S')
          and im.simple_pack_ind='Y'
          -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
          --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
         --Assigned tsl_owner_country for 'B' in decode
          and (((im.tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',im.tsl_owner_country)
          --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
          and   L_loc_sec_ind = 'Y')
           or  L_loc_sec_ind = 'N'));
          -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End

   cursor C_PACK_SKUS is
      select pi.item
        from packitem pi,
        -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
             item_master im
       where pi.pack_no = I_item
         and im.item    = pi.item
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
         --Assigned tsl_owner_country for 'B' in decode
         and (((im.tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',im.tsl_owner_country)
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
         and   L_loc_sec_ind = 'Y')
          or  L_loc_sec_ind = 'N'))
         -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
         and exists (select 'x'
                      from item_master
                     where item = I_item
                       and simple_pack_ind = 'N')
         and exists (select 'x'
                       from item_master
                      where item = pi.item
                        and sellable_ind = 'Y');


   --19-Oct-2007    Wipro/JK ModN22 Begin
   -- Cursor to get the value of tsl_product_auth from system options table.
   -- If it is 'Y', then the checks for ModN22 will be performed.
   cursor C_CHECK_PRODUCT_AUTH is
   select tsl_product_auth
    from system_options;

     cursor C_PACK_OCCS(L_packitem ITEM_MASTER.ITEM%TYPE) is
     select item pack_no
       from item_master im
      where (im.item_parent=L_packitem)
        and im.status in ('W','S')
        and im.simple_pack_ind='Y'
        -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
        --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
        --Assigned tsl_owner_country for 'B' in decode
        and (((im.tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',im.tsl_owner_country)
        --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
        and   L_loc_sec_ind = 'Y')
         or  L_loc_sec_ind = 'N'));
        -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     --19-Oct-2007    Wipro/JK ModN22   End

BEGIN
   --- Check for invalid input parameters
   if I_appr_children_ind is NULL or I_item is NULL then
      O_error_message  := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                              NULL,
                                              NULL,
                                              NULL);
      return FALSE;
   end if;

   --- Initialize output parameters
   O_item_approved     := TRUE;
   O_children_approved := TRUE;

   --- Get status of the item passed in
   open C_ITEM_INFO;
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
   fetch C_ITEM_INFO into L_original_item_status, L_item_level, L_tran_level,L_pack_ind;
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
   close C_ITEM_INFO;

   --- Skip the approval and processing logic if this item is already approved
   if L_original_item_status = 'A' then
      O_item_approved := TRUE;
   else
      --- Do approval_check
      if APPROVAL_CHECK(O_error_message,
                        O_item_approved,
                        'N',              --- I_skip_component_chk
                        NULL,             --- I_parent_status
                        'A',              --- I_new_status
                        I_item) = FALSE then
         return FALSE;
      end if;
   end if;

   --- Set variable based on success of approval check and processing item
   if O_item_approved = TRUE then
      L_item_status := 'A';
   else
      L_item_status := 'S';
   end if;
   ---
   -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_sys_opt_rec) = FALSE then
      return FALSE;
   end if;
   ---
   L_loc_sec_ind := L_sys_opt_rec.tsl_loc_sec_ind;
   ---
   if L_loc_sec_ind = 'Y' then
      if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY(O_error_message,
                                                L_uk_access,
                                                L_roi_access) = FALSE then
         return FALSE;
      end if;
      ---
      if L_uk_access = 'Y' and
         L_roi_access = 'N' then
         L_location_access := 'U';
      elsif L_uk_access = 'N' and
         L_roi_access = 'Y' then
         L_location_access := 'R';
      elsif L_uk_access = 'Y' and
         L_roi_access = 'Y' then
         L_location_access := 'B';
      end if;
   else
      L_location_access := 'N';
   end if;
   ---
   -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   if L_item_level = L_tran_level then
      L_all_packs_approved := TRUE;
      for rec in c_pack(I_item) loop
         for pack in C_ITEM_PACKS(rec.pack_no) LOOP
            -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 Begin
            --05-Feb-2010 Usha Patil, usha.patil@in.tesco.com DefNBS016054 Begin
            L_sbmt_or_wrksht_pack_exists := 'Y';
            --05-Feb-2010 Usha Patil, usha.patil@in.tesco.com DefNBS016054 End
            -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 End
            if NOT APPROVAL_CHECK(O_error_message,
                                  L_pack_approved,
                                  'Y',              --- I_skip_component_chk
                                  L_item_status,
                                  'A',
                                  pack.pack_no) then
               return FALSE;
            end if;
            --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
            if L_pack_approved then
               L_pack_flg := TRUE;
               L_item_status := 'A';
               if PROCESS_ITEM(O_error_message,
                               'A',
                               NULL, -- I_single_record, updates item_master
                               pack.pack_no) = FALSE then
                  return FALSE;
               end if;
            end if;
            --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
            if NOT L_pack_approved then
               L_all_packs_approved := FALSE;
            end if;
         end LOOP;
         if NOT L_all_packs_approved then
            if NOT INSERT_ERROR(O_error_message,
                                I_item,
                                'NOT_APP_PACK',
                                'Y',
                                'N') then
               return FALSE;
            end if;
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
         end if;
      end loop; -- end of c_pack(I_item) loop
      -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 Begin
      --05-Feb-2010 Usha Patil, usha.patil@in.tesco.com DefNBS016054 Begin
      if L_sbmt_or_wrksht_pack_exists = 'N' and L_pack_ind = 'N' then
         L_pack_flg := TRUE;
      end if;
      --05-Feb-2010 Usha Patil, usha.patil@in.tesco.com DefNBS016054 End
      -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 End
      if NOT L_pack_flg and L_pack_ind = 'N' then
         O_item_approved := FALSE;
         L_item_status := L_original_item_status;
      end if;
   end if;
   /*          O_item_approved := FALSE;
            L_item_status := L_original_item_status;
         elsif L_item_status = 'A' then
            for pack in C_ITEM_PACKS(rec.pack_no) LOOP
               if PROCESS_ITEM(O_error_message,
                               'A',
                               NULL, -- I_single_record, updates item_master
                               pack.pack_no) = FALSE then
                  return FALSE;
               end if;
            end LOOP;
         end if;
      end loop; -- end of c_pack(I_item) loop
   end if;*/
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End

   for c_comp_packitem in C_PACK_SKUS LOOP
      if PROCESS_COMP_ITEMS(O_error_message,
                            'A',
                            NULL, -- I_single_record, updates item_master
                            c_comp_packitem.item) = FALSE then
         return FALSE;
      end if;
   end LOOP;

   --- If input parameter is Y, loop for children.  This should be done if I_item passed or failed so that all
   --- approval errors can be written right away.
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
   L_new_status := L_item_status;
   L_pack_flg := FALSE;
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
   if I_appr_children_ind = 'Y' then

      for child in C_CHILDREN loop
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
          L_item_status := L_new_status;
          --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
         --- Check if item or its parent/grandparent is on daily purge
         if DAILY_PURGE_SQL.ITEM_PARENT_GRANDPARENT_EXIST(O_error_message,
                                                          L_exists,
                                                          child.item,
                                                          'ITEM_MASTER')= FALSE then
            return FALSE;
         end if;

         --- Skip the approval and processing logic if this child is already approved or has been set for deletion
         if child.status = 'A' or L_exists = TRUE then
            L_child_approved := TRUE;
         else
            --- Do approval_check;
            if APPROVAL_CHECK(O_error_message,
                              L_child_approved,
                              'N',              --- I_skip_component_chk
                              L_item_status,    --- I_parent_status
                              'A',              --- I_new_status
                              child.item) = FALSE then
               return FALSE;
            end if;

            --- If any child fails to get updated then set output parameter to FALSE
            if L_child_approved = FALSE then
               O_children_approved := FALSE;
               --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
               O_item_approved := FALSE;
               L_item_status   := L_original_item_status;
               --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
            end if;
            ---
         end if; -- if child.status = 'A'

         --- Set variable based on success of approval check and processing child, also whether item is set for deletion
         if L_child_approved = TRUE and L_exists = FALSE then
            L_child_status := 'A';
         else
            L_child_status := 'S';
         end if;
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
         if child.item_level > child.tran_level and L_child_approved = TRUE and L_exists = FALSE then
            L_grandchild_flg := TRUE;
            L_child_status := 'A';
         end if;
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
         --19-Oct-2007    Wipro/JK ModN22    Begin
         --If system option is set execute functionality.
         SQL_LIB.SET_MARK('OPEN',
                          'C_CHECK_PRODUCT_AUTH',
                          'SYSTEM_OPTIONS',
                          NULL);
         open C_CHECK_PRODUCT_AUTH;
         SQL_LIB.SET_MARK('FETCH',
                          'C_CHECK_PRODUCT_AUTH',
                          'SYSTEM_OPTIONS',
                          NULL);
         fetch C_CHECK_PRODUCT_AUTH into L_tsl_product_auth;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_PRODUCT_AUTH',
                          'SYSTEM_OPTIONS',
                          NULL);
         close C_CHECK_PRODUCT_AUTH;
         -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  Begin
         if L_tsl_product_auth = 'Y' and L_exists = FALSE then
         -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  End

            if L_item_level + 1 = L_tran_level then
               L_all_packs_approved := TRUE;
               L_child := child.item;
               L_valid_pack := FALSE;
               for rec in c_pack(L_child) loop
                 -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , Begin
                 if DAILY_PURGE_SQL.ITEM_PARENT_GRANDPARENT_EXIST(O_error_message,
                                                                  L_exists_pack,
                                                                  rec.pack_no,
                                                                  'ITEM_MASTER')= FALSE then
                                                           return FALSE;
                 end if;
                 if L_exists_pack = TRUE then
                    L_pack_approved := TRUE;
                 else
                    -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                    L_occ_parent_status := 'S';
                   -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
                 -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , End
                     if NOT APPROVAL_CHECK(O_error_message,
                                           L_pack_approved,
                                           'Y',              --- I_skip_component_chk
                                           --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
                                           L_child_status,
                                           --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
                                           'A',
                                           rec.pack_no) then
                        return FALSE;
                     end if;
                     if NOT L_pack_approved then
                        L_all_packs_approved := FALSE;
                     end if;
                     -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                     if L_pack_approved = FALSE then
                        L_occ_parent_status := 'S';
                     elsif L_pack_approved = TRUE then
                        L_occ_parent_status := 'A';
                     end if;
                     -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End

                     L_valid_occ := FALSE;
                     for pack in C_PACK_OCCS(rec.pack_no) LOOP
                        if NOT APPROVAL_CHECK(O_error_message,
                                              L_valid_occ_sub,
                                              'Y',               --- I_skip_component_chk
                                              -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com ,14-July-2009 , Begin
                                              L_occ_parent_status,
                                              -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com ,14-July-2009 , End
                                              'A',
                                              pack.pack_no) then
                          return FALSE;
                        end if;

                        --If child (OCC) of pack passed approval check, set variables ok.
                        if L_valid_occ_sub then
                           L_valid_occ := TRUE;
                           L_valid_pack := TRUE;
                        end if;
                     end LOOP;  --end C_PACK_OCCS loop

                     --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik Begin
                     if child.tsl_launch_base_ind='Y' then
                        L_valid_occ  := TRUE;
                        L_valid_pack := TRUE;
                     end if;
                     --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik End

                     --If no valid occ exists, then insert error.
                     if NOT L_valid_occ then
                       -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                       if ITEM_APPROVAL_SQL_FIX.G_occ_subtran_exist = FALSE then
                       -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
                        if NOT INSERT_ERROR(O_error_message,
                                            rec.pack_no,
                                            'TSL_NOT_APP_OCC_PACK',
                                            'Y',
                                            'N') then
                           return FALSE;
                        end if;
                       -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                       end if;
                       -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
                        --09-JAN-2008  Wipro/JK  DefNBS00004546   Begin
                        if LP_tocc_req_ind = 'Y' then
                           O_item_approved := FALSE; --Defect 4206 Wipro/JK 23-Nov-2007
                           --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik Begin
                           L_item_status          := 'W';
                           L_all_packs_approved   := FALSE;
                           --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik End
                        end if;
                        --09-JAN-2008  Wipro/JK  DefNBS00004546   End
                     end if;

                     --If pack has not passed approval check, insert error.
                     if NOT L_valid_pack OR NOT L_all_packs_approved then
                        if NOT INSERT_ERROR(O_error_message,
                                            L_child,
                                            'NOT_APP_PACK',
                                            'Y',
                                            'N') then
                           return FALSE;
                        end if;
                     end if;  --end if for L_valid_pack = TRUE
                     --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
                     -- If at least one pack has passed the submit check, then set the indicators as
                     -- TRUE. This is done so that the base item and the style item can be submitted
                     -- successfully.
                     if L_pack_approved and L_valid_occ then
                        L_pack_flg := TRUE;
                     end if;

                     --12-Nov-2009 Tesco HSC/Usha Patil                      Mod: CR213 Begin
                     --28-Oct-2009 Tesco HSC/Usha Patil                      Defect Id: NBS00014308 Begin
                     if L_pack_flg then
                     --   L_child_approved := TRUE;
                     --   O_item_approved := TRUE;
                        L_child_status := 'A';
                     --   L_item_status := 'A';
                        L_all_packs_approved := TRUE;
                     end if;
                     --28-Oct-2009 Tesco HSC/Usha Patil                      Defect Id: NBS00014308 End
                     --12-Nov-2009 Tesco HSC/Usha Patil                      Mod: CR213 End
                     --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End

                     if NOT L_all_packs_approved then
                        L_child_approved := FALSE;
                        --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
                        O_item_approved := FALSE;
                        L_item_status   := L_original_item_status;
                        --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
                        L_child_status := 'S';
                        -- 16-Sep-2008 TESCO HSC/Murali  DefNBS008079  Begin
                        O_children_approved := FALSE;
                        -- 16-Sep-2008 TESCO HSC/Murali  DefNBS008079  End
                     elsif L_child_status = 'A' then
                        --simple pack approval check and process_item
                        --verify that pack passed approval check and then process item if pack is valid for approve.
                        L_valid_pack := FALSE;
                        if NOT APPROVAL_CHECK(O_error_message,
                                              L_valid_pack,
                                              'Y',               --- I_skip_component_chk
                                              L_item_status,
                                              'A',
                                              rec.pack_no) then
                           return FALSE;
                        end if;
                        --if pack ok, then process item
                        if L_valid_pack then
                           if PROCESS_ITEM(O_error_message,
                                           'A',
                                           NULL, -- I_single_record, updates item_master
                                           rec.pack_no) = FALSE then
                              return FALSE;
                           end if;
                        end if;
                        --now loop through OCCs and process each one.
                        --Only process OCCs that have passed approval check.
                        for pack in C_PACK_OCCS(rec.pack_no) LOOP
                           L_valid_occ_item := FALSE;
                           if NOT APPROVAL_CHECK(O_error_message,
                                                 L_valid_occ_item,
                                                 'Y',               --- I_skip_component_chk
                                                 L_item_status,
                                                 'A',
                                                 pack.pack_no) then
                              return FALSE;
                           end if;
                           if L_valid_occ_item then
                              if PROCESS_ITEM(O_error_message,
                                              'A',
                                              NULL, -- I_single_record, updates item_master
                                              pack.pack_no) = FALSE then
                                 return FALSE;
                             end if;
                           end if;
                        end LOOP;  --end loop for C_PACK_OCCS
                     end if;       --end of L_not_all_packs_approved
                 -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , Begin
                 end if;
                 -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , End
               end loop; -- end of c_pack(L_child) loop
            end if;      --end if for L_item_level +1
         -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  Begin
         elsif L_tsl_product_auth = 'N' and L_exists = FALSE  then
         -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  End
         --19-Oct-2007    Wipro/JK ModN22     End
            if L_item_level + 1 = L_tran_level then
               L_all_packs_approved := TRUE;
               L_child := child.item;
               for rec in c_pack(L_child) loop
                  for pack in C_ITEM_PACKS(rec.pack_no) LOOP
                     if NOT APPROVAL_CHECK(O_error_message,
                                           L_pack_approved,
                                           'Y',              --- I_skip_component_chk
                                           L_item_status,
                                           'A',
                                           pack.pack_no) then
                        return FALSE;
                     end if;
                     if NOT L_pack_approved then
                        L_all_packs_approved := FALSE;
                     end if;
                  end LOOP;
                  if NOT L_all_packs_approved then
                     if NOT INSERT_ERROR(O_error_message,
                                         child.item,
                                         'NOT_APP_PACK',
                                         'Y',
                                         'N') then
                        return FALSE;
                     end if;
                     L_child_approved := FALSE;
                     L_child_status := 'S';
                     --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
                     O_item_approved := FALSE;
                     L_item_status   := L_original_item_status;
                     --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
                  elsif L_child_status = 'A' then
                     for pack in C_ITEM_PACKS(rec.pack_no) LOOP
                        if PROCESS_ITEM(O_error_message,
                                        'A',
                                        NULL, -- I_single_record, updates item_master
                                        pack.pack_no) = FALSE then
                           return FALSE;
                        end if;
                     end LOOP;
                  end if;
               end loop; -- end of c_pack(L_child) loop
            end if;
         end if; --19-Oct-2007    Wipro/JK ModN22

         --- Loop through grandchildren for each child as it is processed.
         if L_exists = FALSE then    --only process grandchildren if the parent isn't on the daily purge (deletion) list

            L_grandchilds_parent := child.item;
            for grandchild in C_GRANDCHILDREN loop

               --- Skip the approval and processing logic if this grandchild is already approved
               if grandchild.status = 'A' then
                  L_grandchild_approved := TRUE;
               else
                  --- Do approval_check
                  if APPROVAL_CHECK(O_error_message,
                                    L_grandchild_approved,
                                    'N',              --- I_skip_component_chk
                                    L_child_status,   --- I_parent_status
                                    'A',              --- I_new_status
                                    grandchild.item) = FALSE then
                     return FALSE;
                  end if;

                  if L_item_level + 2 = L_tran_level then
                     L_all_packs_approved := TRUE;
                     L_grandchild := grandchild.item;
                     for rec in c_pack(L_grandchild) loop
                        for pack in C_ITEM_PACKS(rec.pack_no) LOOP
                           if NOT APPROVAL_CHECK(O_error_message,
                                                 L_pack_approved,
                                                 'N',      --- I_skip_component_chk
                                                 grandchild.status,
                                                 'A',
                                                 pack.pack_no) then
                              return FALSE;
                           end if;
                           if NOT L_pack_approved then
                              L_all_packs_approved := FALSE;
                           end if;
                        end LOOP;
                        if NOT L_all_packs_approved then
                           if NOT INSERT_ERROR(O_error_message,
                                               grandchild.item,
                                               'NOT_APP_PACK',
                                               'Y',
                                               'N') then
                              return FALSE;
                           end if;
                           L_grandchild_approved := FALSE;
                           --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
                           O_item_approved := FALSE;
                           L_item_status   := L_original_item_status;
                           --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
                        elsif L_grandchild_approved then
                           for pack in C_ITEM_PACKS(rec.pack_no) LOOP
                              if PROCESS_ITEM(O_error_message,
                                              'S',
                                              NULL, -- I_single_record, updates item_master
                                              pack.pack_no) = FALSE then
                                 return FALSE;
                              end if;
                           end LOOP;
                        end if;
                     end loop; -- end of c_pack(L_grandchild) loop
                  end if;

                  --- If grandchild passed approval check then update grandchild
                  if L_grandchild_approved = TRUE then
                     if PROCESS_ITEM(O_error_message,
                                     'A',
                                     NULL, -- I_single_record, updates item_master
                                     grandchild.item) = FALSE then
                        return FALSE;
                     end if;
                     --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
                     L_grandchild_flg := TRUE;
                     --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
                     if grandchild.item_level > grandchild.tran_level and L_child_status = 'A' then
                        if PROCESS_ITEM(O_error_message,
                                        'A',
                                        'Y',
                                        grandchild.item) = FALSE then
                           return FALSE;
                        end if;
                        --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
                        L_grandchild_flg := TRUE;
                        --26-Aug-2009 MUrali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
                     end if;
                  else
                  --- If any grandchild fails to get updated then set output parameter to FALSE
                     O_children_approved := FALSE;
                     --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
                     O_item_approved := FALSE;
                     L_item_status   := L_original_item_status;
                     --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
                  end if;

               end if;  -- if grandchild.status = 'A'
               ---
            end loop;  -- end C_GRANDCHILDREN loop
         end if; ---- child on daily purge list and will be deleted.

         --28-Oct-2009 Tesco HSC/Usha Patil                      Defect Id: NBS00014308 Begin
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
         if L_grandchild_flg and L_pack_flg then
            O_item_approved := TRUE;
            L_item_status := 'A';
         end if;
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
         --28-Oct-2009 Tesco HSC/Usha Patil                      Defect Id: NBS00014308 End

         --- If child passed approval check, is not already approved, and is not set for deletion then update child
         if L_child_approved = TRUE and child.status != 'A' and L_exists = FALSE then
            if PROCESS_ITEM(O_error_message,
                            'A',
                            NULL, -- I_single_record, updates item_master
                            child.item) = FALSE then
               return FALSE;
            end if;
            --- If parent is approved but the children below tran level is not approved, insert corresponding records in pos_mods
            if child.item_level > child.tran_level and L_original_item_status = 'A' then
               if PROCESS_ITEM(O_error_message,
                               'A',
                               'Y', -- I_single_record, doesn't update item_master
                               child.item) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;
         ---
      end loop;  -- end C_CHILDREN loop
      ---
   end if;

   --- If item passed approval check and it is not already approved, then update item

   -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  Begin
   if O_item_approved = TRUE and L_original_item_status != 'A'
                              and NOT ITEM_APPROVAL_SQL_FIX.G_var_approval_flg then
   -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  End
      if PROCESS_ITEM(O_error_message,
                      'A',
                      'Y', -- I_single_record, doesn't update item_master
                      I_item)= FALSE then
         return FALSE;
      end if;
   -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  Begin
   elsif O_item_approved = TRUE and L_original_item_status != 'A'
                              and ITEM_APPROVAL_SQL_FIX.G_var_approval_flg then
         if PROCESS_ITEM(O_error_message,
                         'A',
                         NULL, -- Updates Item Master
                         I_item)= FALSE then
            return FALSE;
         end if;
   -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  End
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END APPROVE;
----------------------------------------------------------------
FUNCTION SUBMIT(O_error_message       IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                O_item_submitted      IN OUT  BOOLEAN,
                O_children_submitted  IN OUT  BOOLEAN,
                I_sub_children_ind    IN      VARCHAR2,
                I_item                IN      ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_program                VARCHAR2(64)            := 'ITEM_APPROVAL_SQL_FIX.SUBMIT';
   L_item_status            ITEM_MASTER.STATUS%TYPE := NULL;
   L_original_item_status   ITEM_MASTER.STATUS%TYPE := NULL;
   L_child_status           ITEM_MASTER.STATUS%TYPE := NULL;
   L_tran_level             ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_item_level             ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_grandchilds_parent     ITEM_MASTER.ITEM%TYPE;
   L_grandchild             ITEM_MASTER.ITEM%TYPE;
   L_child                  ITEM_MASTER.ITEM%TYPE;
   L_child_submitted        BOOLEAN;
   L_grandchild_submitted   BOOLEAN;
   L_pack_submitted         BOOLEAN;
   L_all_packs_submitted    BOOLEAN;
   L_exists                 BOOLEAN;
   --19-Oct-2007    Wipro/JK ModN22    Begin
     L_tsl_product_auth           SYSTEM_OPTIONS.TSL_PRODUCT_AUTH%TYPE;
     L_valid_pack             BOOLEAN;
     L_valid_occ              BOOLEAN;
     L_valid_occ_sub          BOOLEAN;
     L_valid_occ_item         BOOLEAN;
   --19-Oct-2007    Wipro/JK ModN22    End
   -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , Begin
   L_exists_pack              BOOLEAN;
   -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , End
   -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
   L_occ_parent_status        ITEM_MASTER.STATUS%TYPE := NULL;
   -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
   --NBS00014908 Sarayu Gouda, sarayu.gouda@in.tesco.com 07-oct-2009 Begin
   L_dummy VARCHAR2(1);
   --NBS00014908 Sarayu Gouda, sarayu.gouda@in.tesco.com 07-oct-2009 End
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
   L_grandchild_flg           BOOLEAN   := FALSE;
   L_pack_flg                 BOOLEAN   := FALSE;
   L_new_status               VARCHAR2(1);
   L_pack_ind                 VARCHAR2(1);
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
   -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 Begin
   --05-Feb-2010 Usha Patil, usha.patil@in.tesco.com DefNBS016054 Begin
   L_worksheet_pack_exists    VARCHAR2(1) := 'N';
   --05-Feb-2010 Usha Patil, usha.patil@in.tesco.com DefNBS016054 End
   -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   L_sys_opt_rec              SYSTEM_OPTIONS%ROWTYPE;
   L_loc_sec_ind              VARCHAR2(1) := 'N';
   L_location_access          VARCHAR2(1) := 'N';
   L_uk_access                VARCHAR2(1) := 'N';
   L_roi_access               VARCHAR2(1) := 'N';
   -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 End
   ---
   -- Moved DefNBS016764 and CR288b-Big Fix code to Approval_check function
   ---
   cursor C_ITEM_INFO is
      --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
      select status,
             item_level,
             tran_level,
             pack_ind
      --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
        from item_master
       where I_item = item;

   cursor C_CHILDREN is
      select item
           , tran_level
           , item_level
           , status
           --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik Begin
           , tsl_launch_base_ind
           --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik End
        from item_master
       where item_parent = I_item
         -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
         --Assigned tsl_owner_country for 'B' in decode
         and (((tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',tsl_owner_country)
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
         and   L_loc_sec_ind = 'Y')
          or  L_loc_sec_ind = 'N'));
         -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End

   cursor C_GRANDCHILDREN is
      select item
           , tran_level
           , item_level
           , status
        from item_master
       where item_grandparent = I_item
         and item_parent      = L_grandchilds_parent
         -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
         --Assigned tsl_owner_country for 'B' in decode
         and (((tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',tsl_owner_country)
         --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
         and   L_loc_sec_ind = 'Y')
          or  L_loc_sec_ind = 'N'));
         -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End

   cursor C_PACK(L_item ITEM_MASTER.ITEM%TYPE)  is
     select distinct pi.pack_no
       from packitem pi,
       -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
            item_master im
      where pi.item = L_item
        and im.item = pi.pack_no
        --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
        --Assigned tsl_owner_country for 'B' in decode
        and (((im.tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',im.tsl_owner_country)
        --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
        and   L_loc_sec_ind = 'Y')
         or  L_loc_sec_ind = 'N'));
      -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End

   cursor C_ITEM_PACKS(L_packitem ITEM_MASTER.ITEM%TYPE) is
       select item pack_no
         from item_master im
        where (im.item = L_packitem or
               im.item_parent=L_packitem or
               im.item_grandparent=L_packitem)
           and im.status='W'
           and im.simple_pack_ind='Y'
           -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
           --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
           --Assigned tsl_owner_country for 'B' in decode
           and (((tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',tsl_owner_country)
           --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
           and   L_loc_sec_ind = 'Y')
            or  L_loc_sec_ind = 'N'));
           -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End

   --19-Oct-2007    Wipro/JK ModN22    Begin
     -- Cursor to get the value of tsl_product_auth from system options table.
     -- If it is 'Y', then the checks for ModN22 will be performed.
     cursor C_CHECK_PRODUCT_AUTH is
     select tsl_product_auth
        from system_options;

     cursor C_PACK_OCCS(L_packitem ITEM_MASTER.ITEM%TYPE) is
     select item pack_no
         from item_master im
        where (im.item_parent=L_packitem)
            -- 16-Jun-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS013324 Begin
            -- changed status = 'W' to status in ('W','S')
            and im.status in ('W','S')
            -- 16-Jun-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS013324 End
            and im.simple_pack_ind='Y'
            -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
            --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com Begin
            --Assigned tsl_owner_country for 'B' in decode
            and (((tsl_owner_country = DECODE(L_location_access, 'U','U','R','R','B',tsl_owner_country)
            --10-Nov-2010 , DefNBS19710 , Sripriya , Sripriya.karanam@in.tesco.com End
            and   L_loc_sec_ind = 'Y')
             or  L_loc_sec_ind = 'N'));
            -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End


   --19-Oct-2007    Wipro/JK ModN22    End
  --NBS00014908 Sarayu Gouda, sarayu.gouda@in.tesco.com 07-oct-2009  Begin
   cursor C_LOCK_ITEM_MASTER is
      select 'x'
        from item_master im
       where im.item_parent = I_item
          or im.item_grandparent = I_item
          or exists ( select 'Y'
                        from packitem p
                        where p.pack_no = im.item
                          and p.item_parent = I_item)
          or exists ( select 'Y'
                        from packitem p1
                       where im.item_parent=p1.pack_no
                         and im.simple_pack_ind = 'Y'
                         and p1.item_parent = I_item)
         for update nowait;
   --NBS00014908 Sarayu Gouda, sarayu.gouda@in.tesco.com 07-oct-2009  End
   ---
BEGIN
   --- Check for invalid input parameters
   if I_sub_children_ind is NULL or I_item is NULL then
      O_error_message  := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                              NULL,
                                              NULL,
                                              NULL);
      return FALSE;
   end if;

   --- Initialize output parameters
   O_item_submitted     := FALSE;
   O_children_submitted := TRUE;

   --- Get status of the item passed in
   open C_ITEM_INFO;
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
   -- Moved CR288b-Big Fix code to Approval function
   fetch C_ITEM_INFO into L_original_item_status, L_item_level, L_tran_level,L_pack_ind;
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
   close C_ITEM_INFO;

   --- Skip the approval check if this item is already submitted or approved
   if L_original_item_status != 'W' then
      O_item_submitted := TRUE;
   else
      -- Moved DefNBS016764 and CR288b-Big Fix code to Approval function
      --- Do approval check
      if APPROVAL_CHECK(O_error_message,
                        O_item_submitted,
                        'N',             --- I_skip_component_chk
                        NULL,            --- I_parent_status
                        'S',             --- I_new_status
                        I_item) = FALSE then
         return FALSE;
      end if;
   end if;

   --- Set variable based on success of approval check
   if O_item_submitted = TRUE then
      L_item_status := 'S';
   else
      L_item_status := 'W';
   end if;
   ---
   -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_sys_opt_rec) = FALSE then
      return FALSE;
   end if;
   ---
   L_loc_sec_ind := L_sys_opt_rec.tsl_loc_sec_ind;
   ---
   if L_loc_sec_ind = 'Y' then
      if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY(O_error_message,
                                                L_uk_access,
                                                L_roi_access) = FALSE then
         return FALSE;
      end if;
      ---
      if L_uk_access = 'Y' and
         L_roi_access = 'N' then
         L_location_access := 'U';
      elsif L_uk_access = 'N' and
         L_roi_access = 'Y' then
         L_location_access := 'R';
      elsif L_uk_access = 'Y' and
         L_roi_access = 'Y' then
         L_location_access := 'B';
      end if;
   else
      L_location_access := 'N';
   end if;
   ---
   -- 25-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   if L_item_level = L_tran_level then
      L_all_packs_submitted := TRUE;
      for rec in c_pack(I_item) loop
         for pack in C_ITEM_PACKS(rec.pack_no) LOOP
            -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 Begin
            --05-Feb-2010 Usha Patil usha.patil@in.tesco.com    DefNBS016054 Begin
            L_worksheet_pack_exists := 'Y';
            --05-Feb-2010 Usha Patil usha.patil@in.tesco.com    DefNBS016054 End
            -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 End
            if NOT APPROVAL_CHECK(O_error_message,
                                  L_pack_submitted,
                                  'Y',             --- I_skip_component_chk
                                  L_item_status,
                                  'S',
                                  pack.pack_no) then
               return FALSE;
            end if;
            --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
            if L_pack_submitted then
               L_pack_flg := TRUE;
               L_item_status := 'S';
               if PROCESS_ITEM(O_error_message,
                               'S',
                               NULL, -- I_single_record, updates item_master
                               pack.pack_no) = FALSE then
                  return FALSE;
               end if;
            end if;
            --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
            if NOT L_pack_submitted then
               L_all_packs_submitted := FALSE;
            end if;
         end LOOP;
         -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 Begin
         --05-Feb-2010 Usha Patil usha.patil@in.tesco.com    DefNBS016054 Begin
         if L_worksheet_pack_exists = 'N' and L_pack_ind = 'N' then
            L_pack_flg := TRUE;
         end if;
         --05-Feb-2010 Usha Patil usha.patil@in.tesco.com    DefNBS016054 End
         -- Merge 3.5d to 3.5b  Satish B.N, satish.narasimhaiah@in.tesco.com 05-Mar-2010 End
         if NOT L_all_packs_submitted then
            if NOT INSERT_ERROR(O_error_message,
                                I_item,
                                'NOT_SUB_PACK',
                                'Y',
                                'N') then
               return FALSE;
            end if;
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
         end if;
      end loop; -- end of c_pack(I_item) loop
      if NOT L_pack_flg and L_pack_ind = 'N' then
         O_item_submitted := FALSE;
         L_item_status := L_original_item_status;
      end if;
   end if;
            -- Commented the below code (DefNBS014572) as it is no longer needed.

            /*O_item_submitted := FALSE;
            L_item_status := L_original_item_status;
         elsif L_item_status = 'S' then
            for pack in C_ITEM_PACKS(rec.pack_no) LOOP
               if PROCESS_ITEM(O_error_message,
                               'S',
                               NULL, -- I_single_record, updates item_master
                               pack.pack_no) = FALSE then
                  return FALSE;
               end if;
            end LOOP;
         end if;
      end loop; -- end of c_pack(I_item) loop
   end if;*/
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End

   --- If input parameter is Y, loop for children.  This should be done if I_item passed or failed so that all
   --- submittal errors can be written right away.
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
   L_new_status := L_item_status;
   L_pack_flg := FALSE;
   --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
   if I_sub_children_ind = 'Y' then

      for child in C_CHILDREN loop
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
         L_item_status := L_new_status;
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
         --- Check if item or its parent/grandparent is on daily purge
         if DAILY_PURGE_SQL.ITEM_PARENT_GRANDPARENT_EXIST(O_error_message,
                                                          L_exists,
                                                          child.item,
                                                          'ITEM_MASTER')= FALSE then
            return FALSE;
         end if;

         --- Skip the approval check if this child is already submitted or approved or is set to be deleted
         if child.status != 'W' or L_exists = TRUE then
            L_child_submitted := TRUE;
         else
            --- Do approval_check
            if APPROVAL_CHECK(O_error_message,
                              L_child_submitted,
                              'N',               --- I_skip_component_chk
                              L_item_status,     --- I_parent_status
                              'S',               --- I_new_status
                              child.item) = FALSE then
               return FALSE;
            end if;

            --- If any child fails to get updated then set output parameter to FALSE
            if L_child_submitted = FALSE then
               O_children_submitted := FALSE;
               --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
               O_item_submitted := FALSE;
               L_item_status := L_original_item_status;
               --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
            end if;
         end if;

         --- Set variable based on success of approval check and processing child and whether the item will be deleted
         if L_child_submitted = TRUE and L_exists = FALSE then
             L_child_status := 'S';
         else
            L_child_status := 'W';
         end if;
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
         if child.item_level > child.tran_level and L_child_submitted = TRUE and L_exists = FALSE then
            L_grandchild_flg := TRUE;
            L_child_status := 'S';
         end if;
         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
        --19-Oct-2007    Wipro/JK ModN22    Begin
                --If system option is set execute functionality.
                SQL_LIB.SET_MARK('OPEN',
                                        'C_CHECK_PRODUCT_AUTH',
                                        'SYSTEM_OPTIONS',
                                        NULL);
                open C_CHECK_PRODUCT_AUTH;
                SQL_LIB.SET_MARK('FETCH',
                                        'C_CHECK_PRODUCT_AUTH',
                                        'SYSTEM_OPTIONS',
                                        NULL);
                fetch C_CHECK_PRODUCT_AUTH into L_tsl_product_auth;
                SQL_LIB.SET_MARK('CLOSE',
                                        'C_CHECK_PRODUCT_AUTH',
                                        'SYSTEM_OPTIONS',
                                         NULL);
                close C_CHECK_PRODUCT_AUTH;
                -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  Begin
                if L_tsl_product_auth = 'Y' and L_exists = FALSE then
                -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  End
                     if L_item_level + 1 = L_tran_level then
                            L_all_packs_submitted := TRUE;
                            L_child := child.item;
                            L_valid_pack := FALSE;
                            for rec in c_pack(L_child) loop
                              -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , Begin
                               if DAILY_PURGE_SQL.ITEM_PARENT_GRANDPARENT_EXIST(O_error_message,
                                                                                L_exists_pack,
                                                                                rec.pack_no,
                                                                                'ITEM_MASTER')= FALSE then
                                                                         return FALSE;
                               end if;
                               if L_exists_pack = TRUE then
                                 L_pack_submitted := TRUE;
                               else
                               -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , End
                                 -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                                  L_occ_parent_status := 'W';
                                  -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
                                 --check for approval on simple packs, not children of simple packs here
                                 if NOT APPROVAL_CHECK(O_error_message,
                                                                             L_pack_submitted,
                                                                             'Y',               --- I_skip_component_chk
                                                                             --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
                                                                             L_child_status,
                                                                             --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
                                                                             'S',
                                                                             rec.pack_no) then
                                         return FALSE;
                                 end if;
                                 --If pack eligible for submit, set valid pack to TRUE which will be checked before children (OCC)
                                 --for pack are checked whether they are eligible for submit.
                                 if NOT L_pack_submitted then
                                        L_all_packs_submitted := FALSE;
                                 end if;
                                 -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                                 if L_pack_submitted = FALSE then
                                    L_occ_parent_status := 'W';
                                 elsif L_pack_submitted = TRUE then
                                    L_occ_parent_status := 'S';
                                 end if;
                                 -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End

                             L_valid_occ := FALSE;
                             for pack in C_PACK_OCCS(rec.pack_no) LOOP
                                  if NOT APPROVAL_CHECK(O_error_message,
                                                        L_valid_occ_sub,
                                                        'Y',               --- I_skip_component_chk
                                                        -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                                                        L_occ_parent_status,
                                                        -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
                                                        'S',
                                                        pack.pack_no) then
                                         return FALSE;
                                  end if;
                                  --If child (OCC) of pack passed approval check, set variables ok.
                                  if L_valid_occ_sub then
                                         L_valid_occ := TRUE;
                                         L_valid_pack := TRUE;
                                  -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , Begin
                                  elsif L_valid_occ_sub = FALSE then
                                     L_all_packs_submitted := FALSE;
                                  -- DefNBS012917 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com ,End
                                  end if;
                             end LOOP;  --end C_PACK_OCCS loop

                 --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik Begin
                 if child.tsl_launch_base_ind='Y' then
                    L_valid_occ  := TRUE;
                    L_valid_pack := TRUE;
                 end if;
                 --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik End

                             --If no valid occ exists, then insert error.
                             if NOT L_valid_occ then
                              -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                               if ITEM_APPROVAL_SQL_FIX.G_occ_subtran_exist = FALSE then
                               -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
                                  if NOT INSERT_ERROR(O_error_message,
                                                      rec.pack_no,
                                                      'TSL_NOT_SUB_OCC_PACK',
                                                      'Y',
                                                      'N') then
                                         return FALSE;
                                  end if;
                               -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , Begin
                               end if;
                               -- DefNBS013907 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 14-July-2009 , End
                    --09-JAN-2008  Wipro/JK  DefNBS00004546   Begin
                    if LP_tocc_req_ind = 'Y' then
                       O_item_submitted := FALSE; --Defect 4206 Wipro/JK 23-Nov-2007
                       --12-Mar-2008 DefNBS005385 vipindas.thekkepurakkal@in.tesco.com Begin
                       --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik Begin
                       L_item_status          := 'W';
                       --23-Apr-2008 DefNBS00005385 WiproEnabler/Karthik End
                       L_all_packs_submitted  := FALSE;
                       --12-Mar-2008 DefNBS005385 vipindas.thekkepurakkal@in.tesco.com End
                    end if;
                    --09-JAN-2008  Wipro/JK  DefNBS00004546   End
                             end if;

                                 --If pack has not passed approval check, insert error.
                                 if NOT L_valid_pack OR NOT L_all_packs_submitted  then
                                        if NOT INSERT_ERROR(O_error_message,
                                                                                L_child,
                                                                                'NOT_SUB_PACK',
                                                                                'Y',
                                                                                'N') then
                                             return FALSE;
                                        end if;
                                 end if;  --end if for L_valid_pack = TRUE
                 --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
                 if L_pack_submitted and L_valid_occ then
                    L_pack_flg := TRUE;
                 end if;

                 --12-Nov-2009 Tesco HSC/Usha Patil                      Mod: CR213 Begin
                 --28-Oct-2009 Tesco HSC/Usha Patil              Defect Id: NBS00014308 Begin
                 if L_pack_flg then
                 --   L_child_submitted := TRUE;
                 --   O_item_submitted := TRUE;
                    L_child_status := 'S';
                 --   L_item_status := 'S';
                    L_all_packs_submitted := TRUE;
                 end if;
                 --28-Oct-2009 Tesco HSC/Usha Patil              Defect Id: NBS00014308 End
                 --12-Nov-2009 Tesco HSC/Usha Patil                      Mod: CR213 End
                 --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
                                 if NOT L_all_packs_submitted then
                                        L_child_submitted := FALSE;
                                        --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
                    O_item_submitted := FALSE;
                    L_item_status := L_original_item_status;
                    --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
                                        L_child_status := 'W';
                                 elsif L_child_status = 'S' then
                                        --simple pack approval check and process_item
                                        --verify that pack passed approval check and then process item if pack is valid for approve.
                                        L_valid_pack := FALSE;
                                        if NOT APPROVAL_CHECK(O_error_message,
                                                                                    L_valid_pack,
                                                                                    'Y',               --- I_skip_component_chk
                                                                                    L_item_status,
                                                                                    'S',
                                                                                    rec.pack_no) then
                                                return FALSE;
                                        end if;
                                        --if pack ok, then process item
                                        if L_valid_pack then
                                             if PROCESS_ITEM(O_error_message,
                                                                             'S',
                                                                             NULL, -- I_single_record, updates item_master
                                                                             rec.pack_no) = FALSE then
                                                     return FALSE;
                                             end if;
                                        end if;
                                        --now loop through OCCs and process each one.
                                        --Only process OCCs that have passed approval check.
                                        for pack in C_PACK_OCCS(rec.pack_no) LOOP
                                             L_valid_occ_item := FALSE;
                                             if NOT APPROVAL_CHECK(O_error_message,
                                                                                         L_valid_occ_item,
                                                                                         'Y',               --- I_skip_component_chk
                                                                                         L_item_status,
                                                                                         'S',
                                                                                         pack.pack_no) then
                                                    return FALSE;
                                             end if;
                                             if L_valid_occ_item then
                                                    if PROCESS_ITEM(O_error_message,
                                                                                    'S',
                                                                                    NULL, -- I_single_record, updates item_master
                                                                                    pack.pack_no) = FALSE then
                                                         return FALSE;
                                                    end if;
                                             end if;
                                        end LOOP;  --end loop for C_PACK_OCCS
                                    end if;    --end if for L_all_packs_submitted
                              -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , Begin
                              end if;
                              -- DefNBS013690 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , 29-Jun-2009 , End
                            end loop;      -- end of c_pack(L_child) loop
                     end if;           --end of L_item_level+1
                 -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  Begin
                 elsif L_tsl_product_auth = 'N' and L_exists = FALSE then
                 -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  End
         --19-Oct-2007    Wipro/JK ModN22   End
            if L_item_level + 1 = L_tran_level then
               L_all_packs_submitted := TRUE;
               L_child := child.item;
               for rec in c_pack(L_child) loop
                  for pack in C_ITEM_PACKS(rec.pack_no) LOOP
                     if NOT APPROVAL_CHECK(O_error_message,
                                           L_pack_submitted,
                                           'Y',               --- I_skip_component_chk
                                           L_item_status,
                                           'S',
                                           pack.pack_no) then
                        return FALSE;
                     end if;
                     if NOT L_pack_submitted then
                        L_all_packs_submitted := FALSE;
                     end if;
                  end LOOP;
                  if NOT L_all_packs_submitted then
                     if NOT INSERT_ERROR(O_error_message,
                                         child.item,
                                         'NOT_SUB_PACK',
                                         'Y',
                                         'N') then
                        return FALSE;
                     end if;
                     L_child_submitted := FALSE;
                     --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
                     O_item_submitted := FALSE;
                     L_item_status := L_original_item_status;
                     --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
                     L_child_status := 'W';
                  elsif L_child_status = 'S' then
                     for pack in C_ITEM_PACKS(rec.pack_no) LOOP
                        if PROCESS_ITEM(O_error_message,
                                        'S',
                                        NULL, -- I_single_record, updates item_master
                                        pack.pack_no) = FALSE then
                           return FALSE;
                        end if;
                     end LOOP;
                  end if;
               end loop; -- end of c_pack(L_child) loop
            end if;
         end if; --19-Oct-2007    Wipro/JK ModN22

         --- Loop through grandchildren for each child as it is processed.
         if L_exists = FALSE then    --only process grandchildren if the parent isn't on the daily purge (deletion) list
            L_grandchilds_parent := child.item;
            for grandchild in C_GRANDCHILDREN loop

               --- Skip the approval and processing logic if this grandchild is already submitted or approved or set to be deleted
               if grandchild.status != 'W' then
                  L_grandchild_submitted := TRUE;
               else
                  --- Do approval_check
                  if APPROVAL_CHECK(O_error_message,
                                    L_grandchild_submitted,
                                    'N',                --- I_skip_component_chk
                                    L_child_status,     --- I_parent_status
                                    'S',                --- I_new_status
                                    grandchild.item) = FALSE then
                     return FALSE;
                  end if;
                  if L_item_level + 2 = L_tran_level then
                     L_all_packs_submitted := TRUE;
                     L_grandchild := grandchild.item;
                     for rec in c_pack(L_grandchild) loop
                        for pack in C_ITEM_PACKS(rec.pack_no) LOOP
                           if NOT APPROVAL_CHECK(O_error_message,
                                                 L_pack_submitted,
                                                 'N',      --- I_skip_component_chk
                                                 grandchild.status,
                                                 'S',
                                                 pack.pack_no) then
                              return FALSE;
                           end if;
                           if NOT L_pack_submitted then
                              L_all_packs_submitted := FALSE;
                           end if;
                        end LOOP;
                        if NOT L_all_packs_submitted then
                           if NOT INSERT_ERROR(O_error_message,
                                               grandchild.item,
                                               'NOT_SUB_PACK',
                                               'Y',
                                               'N') then
                              return FALSE;
                           end if;
                           L_grandchild_submitted := FALSE;
                           --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
                           O_item_submitted := FALSE;
                           L_item_status := L_original_item_status;
                           --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
                        elsif L_grandchild_submitted then
                           for pack in C_ITEM_PACKS(rec.pack_no) LOOP
                              if PROCESS_ITEM(O_error_message,
                                              'S',
                                              NULL, -- I_single_record, updates item_master
                                              pack.pack_no) = FALSE then
                                 return FALSE;
                              end if;
                           end LOOP;
                        end if;
                     end loop; -- end of c_pack(L_grandchild) loop
                  end if;

                  --- If grandchild passed approval check then update grandchild
                  if L_grandchild_submitted = TRUE then
                     if PROCESS_ITEM(O_error_message,
                                     'S',
                                     NULL, -- I_single_record, updates item_master
                                     grandchild.item) = FALSE then
                        return FALSE;
                     end if;
                     --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
                     L_grandchild_flg := TRUE;
                     --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
                  else
                     --- If any grandchild fails to get updated then set output parameter to FALSE
                     O_children_submitted := FALSE;
                     --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik Begin
                     O_item_submitted := FALSE;
                     L_item_status := L_original_item_status;
                     --26-Aug-2008 DefNBS00007711 WiproEnabler/Karthik End
                  end if;
               end if;  -- if grandchild.status = 'A'

            end loop;  -- end C_GRANDCHILDREN loop

         end if; ---- child on daily purge list and will be deleted.

         --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 Begin
         -- If at least one grandchild passes all the checks the style and item for that child
         -- should be approved.
         --28-Oct-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014308 Begin
         --Added L_pack_flg check and assigned value to L_item_status.
         if L_grandchild_flg and L_pack_flg then
            O_item_submitted := TRUE;
            L_item_status := 'S';
         end if;
         --28-Oct-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014308 End
        --26-Aug-2009 Murali Natarajan, murali.natarajan@in.tesco.com DefNBS014572 End
         --- If child passed approval check and it is not already approved or is set to be deleted then update child
         if L_child_submitted = TRUE and child.status != 'A' and L_exists = FALSE then
            if PROCESS_ITEM(O_error_message,
                            'S',
                            NULL, -- I_single_record, updates item_master
                            child.item) = FALSE then
               return FALSE;
            end if;
         end if;

      end loop;  -- end C_CHILDREN loop
      ---
   end if;
   --
   --NBS00014908 Sarayu Gouda, sarayu.gouda@in.tesco.com 07-oct-2009 Begin
   if O_item_submitted = FALSE and O_children_submitted = FALSE and L_original_item_status = 'W' then

      --- Lock the record
      open C_LOCK_ITEM_MASTER;
      fetch C_LOCK_ITEM_MASTER into L_dummy;
      close C_LOCK_ITEM_MASTER;

      -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, Begin
      -- PrfNBS016258, 17-Feb-2010, Govindarajan K, Begin
      -- commented the existing update and added new update query to improve the performance
      /*
      update item_master im
         set im.status = L_original_item_status
       where im.item_parent = I_item
          or im.item_grandparent = I_item
          or exists ( select 'Y'
                        from packitem p
                        where p.pack_no = im.item
                          and p.item_parent = I_item)
          or exists ( select 'Y'
                        from packitem p1
                       where im.item_parent=p1.pack_no
                         and im.simple_pack_ind = 'Y'
                         and p1.item_parent = I_item);
      */
      ---
      update item_master im
         set im.status = L_original_item_status
       where (im.item_parent = I_item
          or im.item_grandparent = I_item);
      ---
      update item_master im
         set im.status = L_original_item_status
       where im.item in (select im1.item
                           from packitem_breakout pb,
                                item_master im1,
                                item_master im2
                          where pb.item = im2.item
                            and (im2.item = I_item
                             or  im2.item_parent = I_item)
                            and (im1.item = pb.pack_no or im1.item_parent = pb.pack_no)
                            -- DefNBS017490 shweta.madnawat@in.tesco.com 18-May-10, Begin
                            and not exists (select 1
                                              from daily_purge
                                             where key_value = pb.pack_no));
                            -- DefNBS017490 shweta.madnawat@in.tesco.com 18-May-10, End
      ---
      -- PrfNBS016258, 17-Feb-2010, Govindarajan K, End
      -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, End
      ---
   end if;
   --NBS00014908 Sarayu Gouda, sarayu.gouda@in.tesco.com 07-oct-2009 End
   --
   --- If item passed approval check and it is not already approved, then update item
   -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  Begin
   if O_item_submitted = TRUE and L_original_item_status != 'A'
                              and NOT ITEM_APPROVAL_SQL_FIX.G_var_approval_flg then
   -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  End
      if PROCESS_ITEM(O_error_message,
                      'S',
                      'Y', -- I_single_record, doesn't update item_master
                      I_item)= FALSE then
         return FALSE;
      end if;
   -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  Begin
   elsif O_item_submitted = TRUE and L_original_item_status != 'A'
                              and ITEM_APPROVAL_SQL_FIX.G_var_approval_flg then
         if PROCESS_ITEM(O_error_message,
                         'S',
                         NULL, -- Updates Item Master
                         I_item)= FALSE then
            return FALSE;
         end if;
   -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  End
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END SUBMIT;
--------------------------------------------------------------------------------------
FUNCTION INSERT_ERROR(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      I_item            IN      ITEM_APPROVAL_ERROR.ITEM%TYPE,
                      I_error_key       IN      ITEM_APPROVAL_ERROR.ERROR_KEY%TYPE,
                      I_system_req_ind  IN      ITEM_APPROVAL_ERROR.SYSTEM_REQ_IND%TYPE,
                      I_override_ind    IN      ITEM_APPROVAL_ERROR.OVERRIDE_IND%TYPE)
RETURN BOOLEAN IS

   L_program  VARCHAR2(40) := 'ITEM_APPROVAL_SQL_FIX.INSERT_ERROR';

BEGIN
   insert into item_approval_error
             ( item
             , error_key
             , system_req_ind
             , override_ind
             , last_update_id
             , last_update_datetime)
       values( I_item
             , I_error_key
             , I_system_req_ind
             , I_override_ind
             , user
             , sysdate);

   return TRUE;

EXCEPTION
   when DUP_VAL_ON_INDEX then
      NULL;
      RETURN TRUE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_ERROR;
----------------------------------------------------------------
FUNCTION PROCESS_COMP_ITEMS(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_new_status          IN     ITEM_MASTER.STATUS%TYPE,
                            I_single_record       IN     VARCHAR2,
                            I_item                IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program                     VARCHAR2(64) := 'ITEM_APPROVAL_SQL_FIX.PROCESS_COMP_ITEMS';
   L_item_desc                   ITEM_MASTER.ITEM_DESC%TYPE := NULL;
   L_dept                        DEPS.DEPT%TYPE := NULL;
   L_class                       CLASS.CLASS%TYPE := NULL;
   L_subclass                    SUBCLASS.SUBCLASS%TYPE := NULL;
   L_parent                      ITEM_MASTER.ITEM%TYPE := NULL;
   L_item_level                  ITEM_MASTER.TRAN_LEVEL%TYPE := NULL;
   L_tran_level                  ITEM_MASTER.ITEM_LEVEL%TYPE := NULL;
   L_zone_group_id               ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE := NULL;
   L_unit_retail                 ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE := NULL;
   L_unit_cost                   ITEM_SUPP_COUNTRY.UNIT_COST%TYPE := NULL;
   L_selling_unit_retail         ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE := NULL;
   L_selling_uom                 ITEM_ZONE_PRICE.SELLING_UOM%TYPE := NULL;
   L_standard_uom                ITEM_MASTER.STANDARD_UOM%TYPE := NULL;
   L_sellable_ind                ITEM_MASTER.SELLABLE_IND%TYPE := NULL;
   L_unit_retail_loc             ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE := NULL;
   L_uom_loc                     ITEM_MASTER.STANDARD_UOM%TYPE := NULL;
   L_selling_unit_retail_loc     ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE := NULL;
   L_selling_uom_loc             ITEM_ZONE_PRICE.SELLING_UOM%TYPE := NULL;
   L_multi_units_loc             ITEM_ZONE_PRICE.MULTI_UNITS%TYPE := NULL;
   L_multi_unit_retail_loc       ITEM_ZONE_PRICE.MULTI_UNIT_RETAIL%TYPE := NULL;
   L_multi_selling_uom_loc       ITEM_ZONE_PRICE.MULTI_SELLING_UOM%TYPE := NULL;
   L_item_number_type            ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE := NULL;
   L_prefix                      ITEM_MASTER.PREFIX%TYPE := NULL;
   L_format_id                   ITEM_MASTER.FORMAT_ID%TYPE := NULL;
   L_loctr_exists                BOOLEAN;
   L_launch_date                 ITEM_LOC_TRAITS.LAUNCH_DATE%TYPE := NULL;
   L_qty_key_options             ITEM_LOC_TRAITS.QTY_KEY_OPTIONS%TYPE := NULL;
   L_manual_price_entry          ITEM_LOC_TRAITS.MANUAL_PRICE_ENTRY%TYPE := NULL;
   L_deposit_code                ITEM_LOC_TRAITS.DEPOSIT_CODE%TYPE := NULL;
   L_food_stamp_ind              ITEM_LOC_TRAITS.FOOD_STAMP_IND%TYPE := NULL;
   L_wic_ind                     ITEM_LOC_TRAITS.WIC_IND%TYPE := NULL;
   L_proportional_tare_pct       ITEM_LOC_TRAITS.PROPORTIONAL_TARE_PCT%TYPE := NULL;
   L_fixed_tare_value            ITEM_LOC_TRAITS.FIXED_TARE_VALUE%TYPE := NULL;
   L_fixed_tare_uom              ITEM_LOC_TRAITS.FIXED_TARE_UOM%TYPE := NULL;
   L_reward_eligible_ind         ITEM_LOC_TRAITS.REWARD_ELIGIBLE_IND%TYPE := NULL;
   L_natl_brand_comp_item        ITEM_LOC_TRAITS.NATL_BRAND_COMP_ITEM%TYPE := NULL;
   L_return_policy               ITEM_LOC_TRAITS.RETURN_POLICY%TYPE := NULL;
   L_stop_sale_ind               ITEM_LOC_TRAITS.STOP_SALE_IND%TYPE := NULL;
   L_elect_mtk_clubs             ITEM_LOC_TRAITS.ELECT_MTK_CLUBS%TYPE := NULL;
   L_report_code                 ITEM_LOC_TRAITS.REPORT_CODE%TYPE := NULL;
   L_req_shelf_life_on_selection ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_SELECTION%TYPE := NULL;
   L_req_shelf_life_on_receipt   ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_RECEIPT%TYPE := NULL;
   L_ib_shelf_life               ITEM_LOC_TRAITS.IB_SHELF_LIFE%TYPE := NULL;
   L_store_reorderable_ind       ITEM_LOC_TRAITS.STORE_REORDERABLE_IND%TYPE := NULL;
   L_rack_size                   ITEM_LOC_TRAITS.RACK_SIZE%TYPE := NULL;
   L_full_pallet_item            ITEM_LOC_TRAITS.FULL_PALLET_ITEM%TYPE := NULL;
   L_in_store_market_basket      ITEM_LOC_TRAITS.IN_STORE_MARKET_BASKET%TYPE := NULL;
   L_storage_location            ITEM_LOC_TRAITS.STORAGE_LOCATION%TYPE := NULL;
   L_alt_storage_location        ITEM_LOC_TRAITS.ALT_STORAGE_LOCATION%TYPE := NULL;
   L_pack_ind                    ITEM_MASTER.PACK_IND%TYPE := NULL;
   L_orderable_ind               ITEM_MASTER.ORDERABLE_IND%TYPE := NULL;
   L_unit_cost_sup               ITEM_LOC_SOH.UNIT_COST%TYPE := NULL;
   L_unit_cost_loc               ITEM_LOC_SOH.UNIT_COST%TYPE := NULL;
   L_loc                         ITEM_SUPP_COUNTRY_LOC.LOC%TYPE := NULL;
   --
   L_status                      ITEM_MASTER.STATUS%TYPE;
   L_dept_name                   DEPS.DEPT_NAME%TYPE;
   L_class_name                  CLASS.CLASS_NAME%TYPE;
   L_subclass_name               SUBCLASS.SUB_NAME%TYPE;
   L_pack_type                   ITEM_MASTER.PACK_TYPE%TYPE;
   L_simple_pack_ind             ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_waste_type                  ITEM_MASTER.WASTE_TYPE%TYPE;
   L_item_grandparent            ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_short_desc                  ITEM_MASTER.SHORT_DESC%TYPE;
   L_waste_pct                   ITEM_MASTER.WASTE_PCT%TYPE;
   L_default_waste_pct           ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE;
   L_diff_1                      ITEM_MASTER.DIFF_1%TYPE;
   L_diff_1_desc                 V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_1_type                 V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_1_id_group_ind         V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_diff_2                      ITEM_MASTER.DIFF_2%TYPE;
   L_diff_2_desc                 V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_2_type                 V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_2_id_group_ind         V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_order_as_type               ITEM_MASTER.ORDER_AS_TYPE%TYPE;
   L_store_ord_mult              ITEM_MASTER.STORE_ORD_MULT%TYPE;
   L_contains_inner_ind          ITEM_MASTER.CONTAINS_INNER_IND%TYPE;
   --
   L_returnable_ind              ITEM_LOC_TRAITS.RETURNABLE_IND%TYPE;
   L_refundable_ind              ITEM_LOC_TRAITS.RETURNABLE_IND%TYPE;
   L_back_order_ind              ITEM_LOC_TRAITS.BACK_ORDER_IND%TYPE;


   L_vat_ind                     SYSTEM_OPTIONS.VAT_IND%TYPE              := NULL;
   L_vat_code                    POS_MODS.VAT_CODE%TYPE                   := NULL;
   L_vat_rate                    POS_MODS.VAT_RATE%TYPE                   := NULL;

   cursor C_ITEM_MASTER is
      select 'x'
        from item_master
       where item = I_item
         for update nowait;

   cursor C_LOCS is
      select il.item,
             il.loc,
             il.loc_type,
             il.local_item_desc,
             ils.unit_cost,
             il.taxable_ind,
             il.status,
             il.primary_supp,
             il.primary_cntry
        from item_loc il, item_loc_soh ils
       where il.item = I_item
         and il.item = ils.item(+)
         and il.loc  = ils.loc(+)
         and not exists (select 'x'
                           from pos_mods p
                          where p.item = I_item
                            and p.store = il.loc);

   cursor C_ITEM_SUPP_CTRY_LOC is
      select loc iscl_loc,
             loc_type iscl_loc_type,
             supplier iscl_supplier,
             origin_country_id iscl_origin_country_id,
             unit_cost iscl_unit_cost
        from item_supp_country_loc
       where item = I_item
         and loc = L_loc;

   cursor C_VAT_ITEM is
      select v.vat_code,
             v.vat_rate
        from vat_item v,
             store s
       where v.item        = I_item
         and s.store       = L_loc
         and s.vat_region  = v.vat_region
         and v.vat_type     in('R','B')
         and v.active_date = (select MAX(v2.active_date)
                                from vat_item v2
                               where v2.vat_region = v.vat_region
                                 and v2.item = I_item
                                 and v.vat_type in ('R','B')
                                 and v2.active_date <= LP_vdate);
BEGIN
   ---
   if nvl(I_single_record,'N') = 'N' then
      if UPDATE_STATUS(O_error_message,
                       I_new_status,
                       I_item) = FALSE then
         return false;
      end if;
   end if; --status update will have to be done in calling form for record locking issues
   ---
   if I_new_status = 'A' then
      if ITEM_ATTRIB_SQL.GET_INFO (O_error_message,
                                   L_item_desc,
                                   L_item_level,
                                   L_tran_level,
                                   L_status,
                                   L_pack_ind,
                                   L_dept,
                                   L_dept_name,
                                   L_class,
                                   L_class_name,
                                   L_subclass,
                                   L_subclass_name,
                                   L_zone_group_id,
                                   L_sellable_ind, --sellable_ind
                                   L_orderable_ind,
                                   L_pack_type,
                                   L_simple_pack_ind,
                                   L_waste_type,
                                   L_parent, --item_parent
                                   L_item_grandparent,
                                   L_short_desc,
                                   L_waste_pct,
                                   L_default_waste_pct,
                                   L_item_number_type,
                                   L_diff_1,
                                   L_diff_1_desc,
                                   L_diff_1_type,
                                   L_diff_1_id_group_ind,
                                   L_diff_2,
                                   L_diff_2_desc,
                                   L_diff_2_type,
                                   L_diff_2_id_group_ind,
                                   L_order_as_type,
                                   L_format_id,
                                   L_prefix,
                                   L_store_ord_mult,
                                   L_contains_inner_ind,
                                   I_item) = FALSE then
         return FALSE;
      end if;
      ---
      /* returns retail from non-sellable packs */
      if ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL(O_error_message,
                                              L_unit_cost,
                                              L_unit_retail,
                                              L_standard_uom,
                                              L_selling_unit_retail,
                                              L_selling_uom,
                                              I_item) = FALSE then
         return FALSE;
      end if;
      ---

      if L_item_level <= L_tran_level then
         ---
         insert into price_hist(tran_type,
                                reason,
                                event,
                                item,
                                loc,
                                loc_type,
                                unit_cost,
                                unit_retail,
                                selling_unit_retail,
                                selling_uom,
                                action_date,
                                multi_units,
                                multi_unit_retail,
                                multi_selling_uom)
                        values (0, --tran_type
                                0, --reason
                                NULL, --event
                                I_item,
                                0, --loc
                                NULL, --loc_type
                                L_unit_cost,
                                L_unit_retail,
                                L_selling_unit_retail,
                                L_selling_uom,
                                LP_vdate, --action_date
                                NULL, --multi_units
                                NULL, --multi_unit_retail
                                NULL --multi_selling_uom
                                );

         for recs in C_LOCS loop
            BEGIN
               ---
               if L_sellable_ind = 'Y' then

                     if PRICING_ATTRIB_SQL.GET_RETAIL(O_error_message,
                                                      L_unit_retail_loc,
                                                      L_uom_loc,
                                                      L_selling_unit_retail_loc,
                                                      L_selling_uom_loc,
                                                      L_multi_units_loc,
                                                      L_multi_unit_retail_loc,
                                                      L_multi_selling_uom_loc,
                                                      recs.item,
                                                      recs.loc_type,
                                                      recs.loc) = FALSE then
                        return FALSE;
                     end if;


               end if; -- end sellable_ind = 'Y'
               ---
               if L_item_level = L_tran_level then
                  --need to do this assignment - can't reference a rec. variable in a cursor definition
                  L_loc := recs.loc;
                  ---
               end if;
               ---
               /* Cost of Packs/non-tran level Items is not on item_loc_soh, so fetch cost from supplier tables */
               if ((L_pack_ind = 'Y' and L_orderable_ind = 'Y') or L_item_level < L_tran_level) then
                  if L_unit_cost_sup is NULL then
                     if SUPP_ITEM_SQL.GET_COST(O_error_message,
                                               L_unit_cost_sup,
                                               recs.item,
                                               recs.primary_supp,
                                               recs.primary_cntry,
                                               recs.loc) = FALSE then
                        return FALSE;
                     end if;
                  end if;
                  ---
                  if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                      recs.primary_supp,
                                                      'V',
                                                      NULL,
                                                      recs.loc,
                                                      recs.loc_type,
                                                      NULL,
                                                      L_unit_cost_sup,
                                                      L_unit_cost_loc,
                                                      'C',
                                                      NULL,
                                                      NULL) = FALSE then
                     return FALSE;
                  end if;
               else
                  L_unit_cost_loc := recs.unit_cost;
               end if;

               insert into price_hist(tran_type,
                                      reason,
                                      event,
                                      item,
                                      loc,
                                      loc_type,
                                      unit_cost,
                                      unit_retail,
                                      selling_unit_retail,
                                      selling_uom,
                                      action_date,
                                      multi_units,
                                      multi_unit_retail,
                                      multi_selling_uom)
                              values (0, --tran_type
                                      0, --reason
                                      NULL, --event
                                      recs.item,
                                      recs.loc, --loc
                                      recs.loc_type, --loc_type
                                      L_unit_cost_loc,
                                      L_unit_retail_loc,
                                      L_selling_unit_retail_loc,
                                      L_selling_uom_loc,
                                      LP_vdate, --action_date
                                      L_multi_units_loc, --multi_units
                                      L_multi_unit_retail_loc, --multi_unit_retail
                                      L_multi_selling_uom_loc --multi_selling_uom
                                      );
               if recs.loc_type = 'S'
                  and L_item_level = L_tran_level then
                  if ITEM_LOC_TRAITS_SQL.GET_VALUES(O_error_message,
                                                    L_loctr_exists,
                                                    L_launch_date,
                                                    L_qty_key_options,
                                                    L_manual_price_entry,
                                                    L_deposit_code,
                                                    L_food_stamp_ind,
                                                    L_wic_ind,
                                                    L_proportional_tare_pct,
                                                    L_fixed_tare_value,
                                                    L_fixed_tare_uom,
                                                    L_reward_eligible_ind,
                                                    L_natl_brand_comp_item,
                                                    L_return_policy,
                                                    L_stop_sale_ind,
                                                    L_elect_mtk_clubs,
                                                    L_report_code,
                                                    L_req_shelf_life_on_selection,
                                                    L_req_shelf_life_on_receipt,
                                                    L_ib_shelf_life,
                                                    L_store_reorderable_ind,
                                                    L_rack_size,
                                                    L_full_pallet_item,
                                                    L_in_store_market_basket,
                                                    L_storage_location,
                                                    L_alt_storage_location,
                                                    L_returnable_ind,
                                                    L_refundable_ind,
                                                    L_back_order_ind,
                                                    recs.item,
                                                    recs.loc) = FALSE then
                      return FALSE;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('OPEN', 'C_vat_item', 'store, vat_item', 'Item: '||recs.item||', Store: '||TO_CHAR(recs.loc));
                  open C_VAT_ITEM;
                  SQL_LIB.SET_MARK('FETCH', 'C_vat_item', 'store, vat_item', 'Item: '||recs.item||', Store: '||TO_CHAR(recs.loc));
                  fetch C_VAT_ITEM into L_vat_code,
                                        L_vat_rate;
                  SQL_LIB.SET_MARK('CLOSE', 'C_vat_item', 'store, vat_item', 'Item: '||recs.item||', Store: '||TO_CHAR(recs.loc));
                  close C_VAT_ITEM;
                  ---
                  if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                                    1,--I_tran_type,
                                                    recs.item,
                                                    recs.local_item_desc,--I_item_desc,
                                                    NULL,--I_ref_item,
                                                    L_dept,
                                                    L_class,
                                                    L_subclass,
                                                    recs.loc,--I_store,
                                                    L_selling_unit_retail_loc,--I_new_price
                                                    L_selling_uom_loc,--I_new_selling_uom
                                                    NULL,--I_old_price
                                                    NULL,--I_old_selling_uom
                                                    NULL,--I_start_date
                                                    L_multi_units_loc,--I_new_multi_units
                                                    NULL,--I_old_multi_units
                                                    L_multi_unit_retail_loc,--I_new_multi_unit_retail
                                                    L_multi_selling_uom_loc,--I_new_multi_selling_uom
                                                    NULL,--I_old_multi_unit_retail
                                                    NULL,--I_old_multi_selling_uom
                                                    recs.status,--I_status
                                                    recs.taxable_ind,--I_taxable_ind
                                                    L_launch_date,--I_launch_date
                                                    L_qty_key_options,--I_qty_key_options
                                                    L_manual_price_entry,--I_manual_price_entry
                                                    L_deposit_code,--I_deposit_code
                                                    L_food_stamp_ind,--I_food_stamp_ind
                                                    L_wic_ind,--I_wic_ind
                                                    L_proportional_tare_pct,--I_proportional_tare_pct
                                                    L_fixed_tare_value,--I_fixed_tare_value
                                                    L_fixed_tare_uom,--I_fixed_tare_uom
                                                    L_reward_eligible_ind,--I_reward_eligible_ind
                                                    L_elect_mtk_clubs,--I_elect_mtk_clubs
                                                    L_return_policy,--I_return_policy
                                                    L_stop_sale_ind,
                                                    L_returnable_ind,
                                                    L_refundable_ind,
                                                    L_back_order_ind,
                                                    L_vat_code,
                                                    L_vat_rate) = FALSE then
                     return FALSE;
                  end if;
               end if;
            END;
         end loop;
         ---
      elsif L_item_level > L_tran_level and I_single_record = 'Y' then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           2,--I_tran_type,
                                           L_parent,
                                           NULL,--I_item_desc,
                                           I_item,--I_ref_item,
                                           L_dept,
                                           L_class,
                                           L_subclass,
                                           NULL,--I_store,
                                           L_selling_unit_retail,--I_new_price,
                                           L_selling_uom,--I_new_selling_uom,
                                           NULL,--I_old_price,
                                           NULL,--I_old_selling_uom,
                                           NULL,--I_start_date,
                                           NULL,--I_new_multi_units,
                                           NULL,--I_old_multi_units,
                                           NULL,--I_new_multi_unit_retail,
                                           NULL,--I_new_multi_selling_uom,
                                           NULL,--I_old_multi_unit_retail,
                                           NULL,--I_old_multi_selling_uom,
                                           NULL,--I_status (store),
                                           NULL,--I_taxable_ind,
                                           NULL,--I_launch_date,
                                           NULL,--I_qty_key_options,
                                           NULL,--I_manual_price_entry,
                                           NULL,--I_deposit_code,
                                           NULL,--I_food_stamp_ind,
                                           NULL,--I_wic_ind,
                                           NULL,--I_proportional_tare_pct,
                                           NULL,--I_fixed_tare_value,
                                           NULL,--I_fixed_tare_uom,
                                           NULL,--I_reward_eligible_ind ,
                                           NULL,--I_elect_mtk_clubs,
                                           NULL,--I_return_policy,
                                           NULL) = FALSE then

            return FALSE;
         end if;
      end if;
      ---
      delete from item_approval_error
            where item = I_item;

   else
      --------------------------------------
      --- I_new_status = 'S'
      --------------------------------------
      delete from item_approval_error
            where item = I_item
              and override_ind = 'N';
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END PROCESS_COMP_ITEMS;
----------------------------------------------------------------------------------------------------
-- Begin ModN115,116,117 Wipro/JK 20-Feb-2008
----------------------------------------------------------------------------------------------------
-- Function : TSL_PACK_CHECK
-- Purpose  : The function checks whether pack has level2 pack number type as expected.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_PACK_CHECK(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_flg           IN OUT VARCHAR2,
                        I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program       VARCHAR2(50)    := 'ITEM_APPROVAL_SQL_FIX.TSL_PACK_CHECK';
   L_count         NUMBER := 0;
   ---
   cursor C_GET_COUNT  is
      select COUNT(*)
        from item_master iem,
             system_options sop
       where iem.item_parent      = i_item
         and iem.item_number_type = sop.tsl_ratio_pack_number_type ;
   ---
BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COUNT',
                    'ITEM_MASTER, SYSTEM_OPTIONS',
                    'Item: '|| I_item);
   open C_GET_COUNT ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COUNT',
                    'ITEM_MASTER, SYSTEM_OPTIONS',
                    'Item: '|| I_item);
   fetch C_GET_COUNT  into L_count;

   -- DefNBS007409, 19-Jun-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   if L_count = 1 then
   -- DefNBS007409, 19-Jun-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
      O_flg := 'Y';
   else
      O_flg := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COUNT',
                    'ITEM_MASTER, SYSTEM_OPTIONS',
                    'Item: '|| I_item);
   close C_GET_COUNT ;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_GET_COUNT%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_COUNT',
                          'ITEM_MASTER, SYSTEM_OPTIONS',
                          'item:'|| TO_CHAR(I_item));
         close C_GET_COUNT;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_PACK_CHECK;
---------------------------------------------------------------------------------------------------------------
-- End ModN115,116,117 Wipro/JK 20-Feb-2008
-- N111 chandru N 24-Jun-08 Begin
---------------------------------------------------------------------------------------------------------------
-- Function : TSL_SUBMIT_VARIANT
-- Purpose  : This function will loop through all the variants of the input base item and submit each one by one.
---------------------------------------------------------------------------------------------------------------
FUNCTION TSL_SUBMIT_VARIANT(O_error_message            IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_all_var_submitted        IN OUT BOOLEAN,
                            O_all_children_submitted   IN OUT BOOLEAN,
                            I_base_item                IN     ITEM_MASTER.ITEM%TYPE,
                            I_sub_children_ind         IN     VARCHAR2)
    return BOOLEAN is
    L_program       VARCHAR2(300)    := 'ITEM_APPROVAL_SQL_FIX.TSL_SUBMIT_VARIANT';
    L_var_item_submitted      BOOLEAN;
    L_var_children_submitted BOOLEAN;
    cursor C_GET_VAR_ITEMS is
      select iem.item
        from item_master iem
       where iem.tsl_base_item = I_base_item
         and iem.item <> iem.tsl_base_item
         --10-Dec-2009    TESCO HSC/Joy Stephen   DefNBS015675    Begin
         and iem.status = 'W';
         --10-Dec-2009    TESCO HSC/Joy Stephen   DefNBS015675    End
BEGIN
  -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  Begin
  O_all_var_submitted := TRUE;
  O_all_children_submitted := TRUE;
  ITEM_APPROVAL_SQL_FIX.G_base_approved     := TRUE;
  ITEM_APPROVAL_SQL_FIX.G_var_approval_flg  := TRUE;
  -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  End
  FOR C_rec in C_GET_VAR_ITEMS
  LOOP
    if ITEM_APPROVAL_SQL_FIX.SUBMIT(O_error_message,
                                L_var_item_submitted,
                                L_var_children_submitted,
                                I_sub_children_ind,
                                C_rec.item) = FALSE then
      return FALSE;
    end if;
    if NOT L_var_item_submitted then
      O_all_var_submitted := FALSE;
    end if;

    if I_sub_children_ind = 'Y' and
       L_var_children_submitted = FALSE then
       O_all_children_submitted := FALSE;
    end if;
  END LOOP;
  -- 10-Jul-2008 TESCO HSC/Murali MrgNBS007760(N111)  Begin
  -- Resetting the global variable after the variants are processed
  ITEM_APPROVAL_SQL_FIX.G_base_approved     := FALSE;
  ITEM_APPROVAL_SQL_FIX.G_var_approval_flg  := FALSE;
  -- 10-Jul-2008 TESCO HSC/Murali MrgNBS007760(N111)  End
  return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_SUBMIT_VARIANT;
---------------------------------------------------------------------------------------------------------------
-- Function : TSL_APPROVE_VARIANT
-- Purpose  : This function will loop through all the variants of the input base item and approves each one by one.
---------------------------------------------------------------------------------------------------------------
FUNCTION TSL_APPROVE_VARIANT(O_error_message            IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_all_var_approved         IN OUT BOOLEAN,
                             O_all_children_approved    IN OUT BOOLEAN,
                             I_base_item                IN     ITEM_MASTER.ITEM%TYPE,
                             I_appr_children_ind        IN     VARCHAR2)
    return BOOLEAN is
    L_program       VARCHAR2(300)    := 'ITEM_APPROVAL_SQL_FIX.TSL_APPROVE_VARIANT';
    L_var_item_approved      BOOLEAN;
    L_var_children_approved BOOLEAN;
    L_system_options_row    SYSTEM_OPTIONS%ROWTYPE;
    cursor C_GET_VAR_ITEMS is
      select iem.item
        from item_master iem
       where iem.tsl_base_item = I_base_item
         and iem.item <> iem.tsl_base_item;
BEGIN
  -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  Begin
  O_all_var_approved := TRUE;
  O_all_children_approved := TRUE;
  ITEM_APPROVAL_SQL_FIX.G_base_approved     := TRUE;
  ITEM_APPROVAL_SQL_FIX.G_var_approval_flg  := TRUE;
  -- 26-Jun-2008 TESCO HSC/Murali    Mod N111  End
  FOR C_rec in C_GET_VAR_ITEMS
  LOOP
    ---
    if system_options_sql.get_system_options(O_error_message,
                                             L_system_options_row) = FALSE then
      return FALSE;
    end if;
    ---
    if ITEM_APPROVAL_SQL_FIX.APPROVE(O_error_message,
                                L_var_item_approved,
                                L_var_children_approved,
                                I_appr_children_ind,
                                C_rec.item) = FALSE then
      return FALSE;
    end if;
    -- 10-Jul-2008 TESCO HSC/Murali MrgNBS007760(N111)  Begin
    if NOT L_var_item_approved then
      O_all_var_approved := FALSE;
    end if;
    if I_appr_children_ind = 'Y' and L_var_children_approved = FALSE then
      O_all_children_approved := FALSE;
    end if;
    if L_system_options_row.tsl_tesco_cost_model = 'Y' and
      L_var_item_approved then   /* Apply real time cost only if item is approved */
      O_error_message := ' ';
      if (TSL_APPLY_REAL_TIME_COST(O_error_message,
                                   C_rec.item,
                                   'Y',
      -- 26-Aug-2008 Tesco HSC/Satish B.N DefNBS007325 Begin
                                   'O') != 0) then
      -- 26-Aug-2008 Tesco HSC/Satish B.N DefNBS007325 End
         return FALSE;
      end if;
    end if;
    -- 10-Jul-2008 TESCO HSC/Murali MrgNBS007760(N111)  End
  END LOOP;
  -- 10-Jul-2008 TESCO HSC/Murali MrgNBS007760(N111)  Begin
  -- Resetting the global variable after the variants are processed
  ITEM_APPROVAL_SQL_FIX.G_base_approved     := FALSE;
  ITEM_APPROVAL_SQL_FIX.G_var_approval_flg  := FALSE;
  -- 10-Jul-2008 TESCO HSC/Murali MrgNBS007760(N111)  End
  return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_APPROVE_VARIANT;

-- N111 Chandru N 24-Jun-08 End
-- 26-Jun-2008 TESCO HSC/Murali    Mod N111  Begin
---------------------------------------------------------------------------------------------------------------
-- Procedure : TSL_BASE_APPROVED
-- Purpose   : This procedure will set the base approved flag aftre the base is approved so that
--             the variant is approved without any errors.
---------------------------------------------------------------------------------------------------------------
PROCEDURE TSL_BASE_APPROVED(I_approval_flg   IN  BOOLEAN DEFAULT FALSE) is
BEGIN
   ITEM_APPROVAL_SQL_FIX.G_base_approved := I_approval_flg;
END TSL_BASE_APPROVED;
-- 26-Jun-2008 TESCO HSC/Murali    Mod N111  End
--------------------------------------------------------------------------------
--06-Aug-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS014327 Begin
--------------------------------------------------------------------------------
-- Function name: TSL_GET_PRICE_HIST_REC
-- Purpose      : To check whether record is already inserted in price_hist table
--------------------------------------------------------------------------------
FUNCTION TSL_GET_PRICE_HIST_REC(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_rec_found       IN OUT VARCHAR2,
                                I_item            IN     ITEM_MASTER.ITEM%TYPE,
                                I_loc             IN     ITEM_LOC.LOC%TYPE,
                                I_date            IN     DATE,
                                I_cost            IN     ITEM_LOC_SOH.UNIT_COST%TYPE)
   RETURN BOOLEAN IS
   L_program VARCHAR2(50):= 'PRICE_HIST_SQL.TSL_GET_PRICE_HIST_REC';
   L_found  VARCHAR2(1) ;

   CURSOR C_GET_PH_REC is
      select 'x'
        from price_hist
       where item = I_item
         and loc  = I_loc
         and to_char(action_date,'yyyymmdd') = to_char(I_date,'yyyymmdd')
         and unit_cost = I_cost
         and tran_type = 0;

BEGIN
   open C_GET_PH_REC;
   fetch C_GET_PH_REC into L_found;
   if C_GET_PH_REC%FOUND then
      O_rec_found := 'Y';
   else
      O_rec_found := 'N';
   end if;
   close C_GET_PH_REC;
   return TRUE;
EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_GET_PRICE_HIST_REC;
--------------------------------------------------------------------------------
--06-Aug-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS014327 End
--------------------------------------------------------------------------------
--09-Nov-2009 Usha Patil, usha.patil@in.tesco.com          Mod: CR213 Begin
--------------------------------------------------------------------------------
-- Function name: TSL_CHECK_TBAN
-- Purpose      : To check whether the item number type belongs to TBAN
--------------------------------------------------------------------------------
FUNCTION TSL_CHECK_TBAN(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_tban_type       IN OUT VARCHAR2,
                        I_number_type     IN     ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE)
   RETURN BOOLEAN IS
   L_program VARCHAR2(50):= 'ITEM_APPROVAL_SQL_FIX.TSL_CHECK_TBAN';
   L_found  CODE_DETAIL.CODE%TYPE;

   CURSOR C_NON_AUTH_REC is
      select code
        from code_detail
       where code_type = 'TBAN'
         and code = I_number_type;

BEGIN
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_NON_AUTH_REC',
                    'CODE_DETAIL',
                    'Item Number Type: '|| I_number_type);
   open C_NON_AUTH_REC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_NON_AUTH_REC',
                    'CODE_DETAIL',
                    'Item Number Type: '|| I_number_type);
   fetch C_NON_AUTH_REC into L_found;
   if C_NON_AUTH_REC%FOUND then
      O_tban_type := 'Y';
   else
      O_tban_type := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_NON_AUTH_REC',
                    'CODE_DETAIL',
                    'Item Number Type: '|| I_number_type);
   close C_NON_AUTH_REC;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_TBAN;
--------------------------------------------------------------------------------
--09-Nov-2009 Usha Patil, usha.patil@in.tesco.com          Mod: CR213 End
-----------------------------------------------------------------------------------------------------
-- DefNBS016764, 05-Apr-2010 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
-----------------------------------------------------------------------------------------------------
-- Function name: TSL_CHECK_COMP_ATTRIB
-- Purpose      : To check whether TPND and its components attributes are sink at country level
-----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_COMP_ATTRIB (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_sink            IN OUT BOOLEAN,
                                -- 20-May-2010, DefNBS017547, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                O_rtk_key         IN OUT RTK_ERRORS.RTK_KEY%TYPE,
                                -- 20-May-2010, DefNBS017547, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                O_err_item        IN OUT ITEM_MASTER.ITEM%TYPE,
                                I_item            IN     ITEM_MASTER.ITEM%TYPE,
                                I_item_level      IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                                I_pack_ind        IN     ITEM_MASTER.PACK_IND%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(50):= 'ITEM_APPROVAL_SQL_FIX.TSL_CHECK_COMP_ATTRIB';
   -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   L_comp_uk_attrib     ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE := NULL;
   L_comp_roi_attrib    ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE := NULL;
   L_pack_uk_attrib     ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE := NULL;
   L_pack_roi_attrib    ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE := NULL;
   -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   L_count              NUMBER(3)   := 0;


   CURSOR C_GET_L2_B is
    select im.item
     from item_master im
    where im.item_parent = I_item
      and im.item_level = im.tran_level
      and NOT exists (select 1
                        from daily_purge
                       where table_name = 'ITEM_MASTER'
                         and key_value  = im.item);

   CURSOR C_GET_PACK (I_comp VARCHAR2) is
    select pb.pack_no
      from packitem_breakout pb
     where pb.item = I_comp
       and NOT exists (select 1
                         from daily_purge
                        where table_name = 'ITEM_MASTER'
                          and key_value  = pb.pack_no);

   CURSOR C_GET_COMP is
    select pb.item
      from packitem_breakout pb
     where pb.pack_no = I_item;

   TYPE L2_B_TABLE is TABLE of ITEM_MASTER.ITEM%TYPE
     INDEX BY BINARY_INTEGER;

   L2_table      L2_B_TABLE;

BEGIN
   ---
   if I_item_level = 1 and I_pack_ind = 'N' then
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_L2_B',
                       'ITEM_MASTER',
                       'Item : '|| I_item);
      FOR C_comp_rec in C_GET_L2_B
      LOOP
          L_count := L_count + 1;
          L2_table(L_count) := C_comp_rec.item;
          ---
      END LOOP;
      ---
   elsif (I_item_level = 2 and I_pack_ind = 'N') or
      (I_item_level = 1 and I_pack_ind = 'Y') then
      L2_table(L_count) := I_item;
   end if;
   ---
   -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   L_comp_uk_attrib := NULL;
   L_comp_roi_attrib := NULL;
   -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   -- NBS00017173 22-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   if L2_table.count > 0 then
   -- NBS00017173 22-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
     FOR i IN L2_table.first..L2_table.last
     LOOP
        ---
        -- To check TPNB/TPND UK attributes
        -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
        if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                               L2_table(i),
                                               L_comp_uk_attrib,
                                               'U') = FALSE then
           return FALSE;
        end if;
        ---
        if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                               L2_table(i),
                                               L_comp_roi_attrib,
                                               'R') = FALSE then
           return FALSE;
        end if;
        ---
        if I_pack_ind = 'N' then
           ---
           L_pack_uk_attrib := NULL;
           L_pack_roi_attrib := NULL;
        -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
           -- Getting the TPND attached for the TPNB
           SQL_LIB.SET_MARK('OPEN',
                            'C_GET_PACK',
                            'ITEM_MASTER',
                            'Item : '|| L2_table(i));
           FOR C_pack_rec in C_GET_PACK (L2_table(i))
           LOOP
              ---
              -- To check TPND UK attributes
              -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
              ---
              if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                                     C_pack_rec.pack_no,
                                                     L_pack_uk_attrib,
                                                     'U') = FALSE then
                 return FALSE;
              end if;
              ---
              if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                                     C_pack_rec.pack_no,
                                                     L_pack_roi_attrib,
                                                     'R') = FALSE then
                 return FALSE;
              end if;
              ---
              -- 20-May-2010, DefNBS017547, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
              if (L_comp_uk_attrib is NOT NULL and  L_pack_uk_attrib is NULL) and
                 (L_comp_roi_attrib is NULL and L_pack_roi_attrib is NOT NULL) then
                 ---
                 -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                 O_sink     := FALSE;
                 O_err_item := L2_table(i);
                 -- DefNBS00020078, 16-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                 --O_rtk_key  := 'TSL_UK_ITEM';
                 O_rtk_key  := 'TSL_INVALID_COMP_USP';
                 -- DefNBS00020078, 16-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                 return TRUE;
                 ---
              elsif (L_comp_uk_attrib is NULL and  L_pack_uk_attrib is NOT NULL) and
                 (L_comp_roi_attrib is NOT NULL and L_pack_roi_attrib is NULL) then
                 ---
                 O_sink     := FALSE;
                 O_err_item := L2_table(i);
                 -- DefNBS00020078, 16-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                 --O_rtk_key  := 'TSL_ROI_ITEM';
                 O_rtk_key  := 'TSL_INVALID_COMP_RSP';
                 -- DefNBS00020078, 16-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                 return TRUE;
                 ---
              elsif ((L_comp_uk_attrib is NULL and L_pack_uk_attrib is NOT NULL and
                 L_comp_roi_attrib is NOT NULL and L_pack_roi_attrib is NOT NULL) or
                 (L_comp_uk_attrib is NOT NULL and L_pack_uk_attrib is NOT NULL and
                 L_comp_roi_attrib is NULL and L_pack_roi_attrib is NOT NULL)) then
                 ---
                 O_sink     := FALSE;
                 O_err_item := L2_table(i);
                 -- DefNBS00020078, 16-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                 --O_rtk_key  := 'TSL_UKROI_ITEM';
                 O_rtk_key  := 'TSL_INVALID_COMP_BSP';
                 -- DefNBS00020078, 16-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                 return TRUE;
                 ---
              end if;
              ---
              -- 20-May-2010, DefNBS017547, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
           END LOOP;
           ---
        else
           ---
           -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
           L_pack_uk_attrib := NULL;
           L_pack_roi_attrib := NULL;
           -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
           -- Getting the TPNB for the TPND
           SQL_LIB.SET_MARK('OPEN',
                            'C_GET_COMP',
                            'ITEM_MASTER',
                            'Item : '|| L2_table(i));
           FOR C_comp_rec in C_GET_COMP
           LOOP
              ---
              -- To check TPND UK attributes
              -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
              ---
              if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                                     C_comp_rec.item,
                                                     L_pack_uk_attrib,
                                                     'U') = FALSE then
                 return FALSE;
              end if;
              ---
              if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                                     C_comp_rec.item,
                                                     L_pack_roi_attrib,
                                                     'R') = FALSE then
                 return FALSE;
              end if;
              ---
              ---
              -- 20-May-2010, DefNBS017547, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
              if (L_comp_uk_attrib is NOT NULL and L_pack_uk_attrib is NULL) and
                 (L_comp_roi_attrib is NULL and L_pack_roi_attrib is NOT NULL) then
              -- 18-May-2010, CR288b-Big Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                 ---
                 O_sink     := FALSE;
                 O_err_item := L2_table(i);
                 -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                 -- O_rtk_key  := 'TSL_UK_PACK';
                 O_rtk_key  := 'TSL_INVALID_COMP_USP';
                 -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                 return TRUE;
                 ---
              elsif (L_comp_uk_attrib is NULL and L_pack_uk_attrib is NOT NULL) and
                 (L_comp_roi_attrib is NOT NULL and L_pack_roi_attrib is NULL) then
                 ---
                 O_sink     := FALSE;
                 O_err_item := L2_table(i);
                 -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                 -- O_rtk_key  := 'TSL_ROI_PACK';
                 O_rtk_key  := 'TSL_INVALID_COMP_RSP';
                 -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                 return TRUE;
                 ---
              elsif ((L_comp_uk_attrib is NOT NULL and L_comp_roi_attrib is NOT NULL and
                      L_pack_uk_attrib is NOT NULL and L_pack_roi_attrib is NULL) or
                 (L_comp_uk_attrib is NOT NULL and L_comp_roi_attrib is NOT NULL and
                  L_pack_roi_attrib is NOT NULL and L_pack_uk_attrib is NULL)) then
                 ---
                 O_sink     := FALSE;
                 O_err_item := L2_table(i);
                 -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                 -- O_rtk_key  := 'TSL_UKROI_PACK';
                 O_rtk_key  := 'TSL_INVALID_COMP_BSP';
                 -- DefNBS00020078, 09-Dec-2010, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                 return TRUE;
                 ---
              end if;
              -- 20-May-2010, DefNBS017547, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
              ---
           END LOOP;
           ---
        end if;
        ---
     END LOOP;
   -- NBS00017173 22-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   end if;
   -- NBS00017173 22-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
   ---
   O_sink := TRUE;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_COMP_ATTRIB;
-----------------------------------------------------------------------------------------------------
-- DefNBS016764, 05-Apr-2010 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
-----------------------------------------------------------------------------------------------------
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
-- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
-- As the whole function was re-written for 288c, the code has been replaced from 3.5f
-----------------------------------------------------------------------------------------------------
-- 15-Apr-2010 Usha Patil, usha.patil@in.tesco.com          Mod: CR295 Begin
-----------------------------------------------------------------------------------------------------
-- Function name: TSL_UPDATE_ITEM_ATTR
-- Purpose      : To update the effective_dates in item attribute and item descriptions to future date
--                on item approval.
-----------------------------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_ITEM_ATTR(O_error_message   IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item            IN        ITEM_MASTER.ITEM%TYPE,
                              -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                              --Added parameters to the function
                              I_old_country_id  IN        ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE,
                              I_country_id      IN        ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE,
                              I_future_date     IN        ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE)
                              -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)      := 'ITEM_APPROVAL_SQL_FIX.TSL_UPDATE_ITEM_ATTR';
   L_launch_date_uk     ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE;
   L_launch_date_roi    ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE;
   L_effective_date     ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE;
   L_update_base        VARCHAR2(1) := 'N';
   L_update_episel      VARCHAR2(1) := 'N';
   L_update_sel         VARCHAR2(1) := 'N';
   L_update_pack        VARCHAR2(1) := 'N';
   L_update_till        VARCHAR2(1) := 'N';
   L_update_iss         VARCHAR2(1) := 'N';
   L_update_range       VARCHAR2(1) := 'N';
   L_item_master_row    ITEM_MASTER%ROWTYPE;
   --05-May-2010 Tesco HSC/Usha Patil        Defect Id: NSB00017306 Begin
   L_system_options_row SYSTEM_OPTIONS%ROWTYPE;
   --05-May-2010 Tesco HSC/Usha Patil        Defect Id: NSB00017306 End
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   L_update_item_desc   VARCHAR2(1) := 'Y';
   L_launch_update      VARCHAR2(1) := 'N';
   L_launch_date        ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE;
   L_country_id         ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE;
   L_item_launch_date   ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE;
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   -- Replaced C_UNAPPR_ITEMS cursor with C_GET_ITEMS and same is modified in other cursors in the function.
   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 Begin
   CURSOR C_GET_ITEMS is
   select im.item from item_master im where im.item in
  (select item
                       from item_master im
      start with im.item in (select pi.pack_no item
                               from packitem pi
                              where item in (select item
                                               from item_master im2
                                              start with im2.item            = I_item
                                            connect by prior im2.item      = im2.item_parent))
     connect by prior im.item = im.item_parent
     union all
        select item
          from item_master im
         start with im.item = I_item
         connect by prior im.item = im.item_parent)
         and (im.tsl_country_auth_ind = I_country_id
            or im.tsl_country_auth_ind = 'B');
   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 End

   TYPE get_items is TABLE OF C_GET_ITEMS%ROWTYPE
   INDEX BY BINARY_INTEGER;

   L_items_tbl get_items;
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   --Modified the cursor to validate with function parameter rather than cursor parameter.
   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 Begin
   CURSOR C_CHECK_LAUNCH_DATE is
   select 'Y'
    from item_attributes ia,
         item_master im
   where im.item in (select item
                       from item_master im
      start with im.item in (select pi.pack_no item
                               from packitem pi
                              where item in (select item
                                               from item_master im2
                                              start with im2.item            = I_item
                                            connect by prior im2.item      = im2.item_parent))
     connect by prior im.item = im.item_parent
     union all
        select item
          from item_master im
         start with im.item = I_item
         connect by prior im.item = im.item_parent)
      and ia.item = im.item
      and  ia.tsl_launch_date < LP_vdate
       and ia.tsl_launch_date is NOT NULL
       and ia.tsl_country_id = I_country_id
       and (im.tsl_country_auth_ind = I_country_id
            or im.tsl_country_auth_ind = 'B');
   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 End
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   CURSOR C_UPDATE_LAUNCH_DATE(Cp_item       ITEM_MASTER.ITEM%TYPE) is
   select item,
          tsl_launch_date,
          tsl_country_id
     from item_attributes
    where item = Cp_item
      and tsl_launch_date is NOT NULL
      -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      and tsl_country_id = I_country_id;

   L_item_attr_rec C_UPDATE_LAUNCH_DATE%ROWTYPE;
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   --Replaced the cursor C_LAUNCH_DATE which used to get launch date for cursor parameter country
   -- with C_GET_OTHR_CTRY_LDATE
   CURSOR C_GET_OTHR_CTRY_LDATE is
   select tsl_launch_date,
          tsl_country_id
     from item_attributes
    where item = I_item
      and tsl_launch_date is NOT NULL
      and tsl_country_id != I_country_id;
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   CURSOR C_GET_LAUNCH_DATE is
   select ia.tsl_launch_date
     from item_attributes ia
    where ia.item = I_item
      and ia.tsl_country_id = I_country_id;

   CURSOR C_UPDATE_CHILD is
   select item
     from item_master
    where item_parent = I_item
      and status = 'A';

   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 Begin
   CURSOR C_CHECK_BASE_DESC IS
   select 'Y'
  from tsl_itemdesc_base tidb,
       item_master im
  where im.item in (select item
                     from item_master im
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            start with im2.item            = I_item
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
      select item
        from item_master im
       start with im.item = I_item
       connect by prior im.item = im.item_parent)
      and tidb.item = im.item
      and tidb.effective_date < LP_vdate
      and tidb.effective_date != L_effective_date
      and (im.tsl_country_auth_ind = I_country_id
            or im.tsl_country_auth_ind = 'B');
     --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 End


   CURSOR C_GET_ITEMDESC_BASE(Cp_item        ITEM_MASTER.ITEM%TYPE) is
   select item,
          max(effective_date) effective_date
     from tsl_itemdesc_base
    where item = Cp_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_itemdesc_base
                       where item            = Cp_item
                         and (effective_date = LP_vdate
                          or effective_date  = L_effective_date))
    group by item;

   L_itemdesc_base_rec  C_GET_ITEMDESC_BASE%ROWTYPE;

   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 Begin
   CURSOR C_CHECK_EPISEL_DESC IS
   select 'Y'
  from tsl_itemdesc_episel tide,
       item_master im
  where im.item in (select item
                     from item_master im
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            start with im2.item            = I_item
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
      select item
        from item_master im
       start with im.item = I_item
       connect by prior im.item = im.item_parent)
      and tide.item = im.item
      and tide.effective_date < LP_vdate
      and tide.effective_date != L_effective_date
      and (im.tsl_country_auth_ind = I_country_id
            or im.tsl_country_auth_ind = 'B');
    --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 End

   CURSOR C_GET_ITEMDESC_EPISEL(Cp_item        ITEM_MASTER.ITEM%TYPE) is
   select item,
          max(effective_date) effective_date
     from tsl_itemdesc_episel
    where item = Cp_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_itemdesc_episel
                       where item            = Cp_item
                         and (effective_date = LP_vdate
                          or effective_date  = L_effective_date))
    group by item;

   L_itemdesc_episel_rec  C_GET_ITEMDESC_EPISEL%ROWTYPE;

   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 Begin
   CURSOR C_CHECK_SEL_DESC is
  select 'Y'
  from tsl_itemdesc_sel tids,
       item_master im
where im.item in (select item
                     from item_master im
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            start with im2.item            = I_item
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
      select item
        from item_master im
       start with im.item = I_item
       connect by prior im.item = im.item_parent)
      and tids.item = im.item
      and tids.effective_date < LP_vdate
      and tids.effective_date != L_effective_date
      and (im.tsl_country_auth_ind = I_country_id
            or im.tsl_country_auth_ind = 'B');
   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 End

   CURSOR C_GET_ITEMDESC_SEL(Cp_item        ITEM_MASTER.ITEM%TYPE) is
   select item,
          max(effective_date) effective_date
     from tsl_itemdesc_sel
    where item = Cp_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_itemdesc_sel
                       where item            = Cp_item
                         and (effective_date = LP_vdate
                          or effective_date  = L_effective_date))
    group by item;

   L_itemdesc_sel_rec  C_GET_ITEMDESC_SEL%ROWTYPE;

   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 Begin
   CURSOR C_CHECK_PACK_DESC is
   select 'Y'
  from tsl_itemdesc_pack tidp,
       item_master im
where im.item in (select item
                     from item_master im
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            start with im2.item            = I_item
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
      select item
        from item_master im
       start with im.item = I_item
       connect by prior im.item = im.item_parent)
      and tidp.pack_no = im.item
      and tidp.effective_date < LP_vdate
      and tidp.effective_date != L_effective_date
      and (im.tsl_country_auth_ind = I_country_id
            or im.tsl_country_auth_ind = 'B');

   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 End

   CURSOR C_GET_ITEMDESC_PACK(Cp_item        ITEM_MASTER.ITEM%TYPE) is
   select pack_no,
          max(effective_date) effective_date
     from tsl_itemdesc_pack
    where pack_no = Cp_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_itemdesc_pack
                       where pack_no         = Cp_item
                         and (effective_date = LP_vdate
                          or effective_date  = L_effective_date))
    group by pack_no;

   L_itemdesc_pack_rec  C_GET_ITEMDESC_PACK%ROWTYPE;


   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 Begin
   CURSOR C_CHECK_ISS_DESC is
   select 'Y'
  from tsl_itemdesc_iss tidi,
       item_master im
  where im.item in (select item
                     from item_master im
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            --DefNBS019985, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com,03-Dec-2010 begin
                                            start with im2.item            = I_item
                                            --DefNBS019985, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com,03-Dec-2010 end
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
      select item
        from item_master im
       --DefNBS019985, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com,03-Dec-2010 begin
       start with im.item = I_item
       --DefNBS019985, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com,03-Dec-2010 end
       connect by prior im.item = im.item_parent)
      and tidi.item = im.item
      and tidi.effective_date < LP_vdate
      and tidi.effective_date != L_effective_date
      and (im.tsl_country_auth_ind = I_country_id
            or im.tsl_country_auth_ind = 'B');

   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 End

   CURSOR C_GET_ITEMDESC_ISS(Cp_item        ITEM_MASTER.ITEM%TYPE) is
   select item,
          max(effective_date) effective_date
     from tsl_itemdesc_iss
    where item = Cp_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_itemdesc_iss
                       where item            = Cp_item
                         and (effective_date = LP_vdate
                          or effective_date  = L_effective_date))
    group by item;

   L_itemdesc_iss_rec  C_GET_ITEMDESC_ISS%ROWTYPE;

   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 Begin
   CURSOR C_CHECK_TILL_DESC is
   select 'Y'
  from tsl_itemdesc_till tidt,
       item_master im
where im.item in (select item
                     from item_master im
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            --DefNBS019985, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com,03-Dec-2010 begin
                                            start with im2.item            = I_item
                                            --DefNBS019985, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com,03-Dec-2010 end
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
      select item
        from item_master im
       --DefNBS019985, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com,03-Dec-2010 begin
       start with im.item = I_item
       --DefNBS019985, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com,03-Dec-2010 end
       connect by prior im.item = im.item_parent)
      and tidt.item = im.item
      and tidt.effective_date < LP_vdate
      and tidt.effective_date != L_effective_date
      and (im.tsl_country_auth_ind = I_country_id
            or im.tsl_country_auth_ind = 'B');

   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 End

   CURSOR C_GET_ITEMDESC_TILL(Cp_item        ITEM_MASTER.ITEM%TYPE) is
   select item,
          max(effective_date) effective_date
     from tsl_itemdesc_till
    where item = Cp_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_itemdesc_till
                       where item            = Cp_item
                         and (effective_date = LP_vdate
                          or effective_date  = L_effective_date))
    group by item;

   L_itemdesc_till_rec  C_GET_ITEMDESC_TILL%ROWTYPE;

   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 Begin
   CURSOR C_CHECK_RANGE_DESC is
   select 'Y'
  from tsl_item_range tir,
       item_master im
where im.item in (select item
                     from item_master im
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            start with im2.item            = I_item
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
      select item
        from item_master im
       start with im.item = I_item
       connect by prior im.item = im.item_parent)
      and tir.item = im.item
      and tir.effective_date < LP_vdate
      and tir.effective_date != L_effective_date
      and (im.tsl_country_auth_ind = I_country_id
            or im.tsl_country_auth_ind = 'B')
      -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      and tir.tsl_country_id = I_country_id;
     -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   --PrfNBS018415 Manikandan -- manikandan.varadhan@in.tesco.com  02-Aug-2010 End

   CURSOR C_GET_RANGE_INFO(Cp_item        ITEM_MASTER.ITEM%TYPE) is
   select item,
          max(effective_date) effective_date,
          tsl_country_id
     from tsl_item_range
    where item = Cp_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_item_range
                       where item            = Cp_item
                         and (effective_date = LP_vdate
                         ---5-May-2010 Tesco HSC/Usha Patil        Defect Id: NBS00017304 Begin
                          or effective_date  = I_future_date)
                          -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                          and tsl_country_id = I_country_id)
                         -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                         ---5-May-2010 Tesco HSC/Usha Patil        Defect Id: NBS00017304 End
      -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      and tsl_country_id = I_country_id
      -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
    group by item,
             tsl_country_id;

   L_range_rec C_GET_RANGE_INFO%ROWTYPE;

BEGIN
   --05-May-2010 Tesco HSC/Usha Patil        Defect Id: NSB00017306 Begin
   if system_options_sql.get_system_options(O_error_message,
                                            L_system_options_row) = FALSE then
      return FALSE;
   end if;
   --05-May-2010 Tesco HSC/Usha Patil        Defect Id: NSB00017306 End

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master_row,
                                      I_item) = FALSE then
      return FALSE;
   end if;

   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   --Changed the cursor to get child items and packs instead of un-approved items.
   SQL_LIB.SET_MARK('OPEN','C_GET_ITEMS','ITEM_MASTER',NULL);
   open C_GET_ITEMS;
   SQL_LIB.SET_MARK('FETCH','C_GET_ITEMS','ITEM_MASTER',NULL);
   fetch C_GET_ITEMS BULK COLLECT into L_items_tbl;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMS','ITEM_MASTER',NULL);
   close C_GET_ITEMS;
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   --Checks if there are any items which have launch date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_CHECK_LAUNCH_DATE','ITEM_ATTRIBUTES',NULL);
   open C_CHECK_LAUNCH_DATE;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_LAUNCH_DATE','ITEM_ATTRIBUTES',NULL);
   fetch C_CHECK_LAUNCH_DATE into L_launch_update;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_LAUNCH_DATE','ITEM_ATTRIBUTES',NULL);
   close C_CHECK_LAUNCH_DATE;

   --Loop to update the launch date for items.
   if (L_items_tbl is NOT NULL and L_items_tbl.COUNT > 0 and
      L_launch_update = 'Y' ) then
      FOR a in 1..L_items_tbl.COUNT LOOP
         SQL_LIB.SET_MARK('OPEN','C_UPDATE_LAUNCH_DATE','ITEM_ATTRIBUTES',NULL);
         open C_UPDATE_LAUNCH_DATE(L_items_tbl(a).item);
         SQL_LIB.SET_MARK('FETCH','C_UPDATE_LAUNCH_DATE','ITEM_ATTRIBUTES',NULL);
         -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
         fetch C_UPDATE_LAUNCH_DATE INTO L_item_attr_rec;
         -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
         SQL_LIB.SET_MARK('CLOSE','C_UPDATE_LAUNCH_DATE','ITEM_ATTRIBUTES',NULL);
         close C_UPDATE_LAUNCH_DATE;

         -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
         if L_item_attr_rec.item is NOT NULL then
         -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
            update item_attributes
               set tsl_launch_date = I_future_date,
               --05-May-2010 Tesco HSC/Usha Patil        Defect Id: NSB00017306 Begin
                   tsl_dev_end_date = decode(tsl_dev_line_ind, 'Y',
                                             I_future_date + (NVL(L_system_options_row.tsl_devline_weeks,12)*7), '')
               --05-May-2010 Tesco HSC/Usha Patil        Defect Id: NSB00017306 End
             -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
             where item            = L_item_attr_rec.item
               and tsl_country_id  = L_item_attr_rec.tsl_country_id
               and tsl_launch_date = L_item_attr_rec.tsl_launch_date;

            if L_item_attr_rec.tsl_country_id = 'U' then
               L_launch_date_uk := I_future_date;
            elsif L_item_attr_rec.tsl_country_id = 'R' then
               L_launch_date_roi := I_future_date;
            end if;
            -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
         end if;---attribute end if
      END LOOP;
   end if;

   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   if L_launch_update = 'N' then
      SQL_LIB.SET_MARK('OPEN','C_GET_LAUNCH_DATE','ITEM_ATTRIBUTES',NULL);
      open C_GET_LAUNCH_DATE;
      SQL_LIB.SET_MARK('OPEN','C_GET_LAUNCH_DATE','ITEM_ATTRIBUTES',NULL);
      fetch C_GET_LAUNCH_DATE into L_item_launch_date;
      SQL_LIB.SET_MARK('OPEN','C_GET_LAUNCH_DATE','ITEM_ATTRIBUTES',NULL);
      close C_GET_LAUNCH_DATE;

      if I_country_id = 'U' then
         L_launch_date_uk := L_item_launch_date;
      elsif I_country_id = 'R' then
         L_launch_date_roi := L_item_launch_date;
      end if;
   end if;

   if L_item_master_row.tsl_country_auth_ind is NOT NULL and
      L_item_master_row.tsl_country_auth_ind != I_country_id and
      I_old_country_id != 'N' then
      L_update_item_desc := 'N';
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_OTHR_CTRY_LDATE','ITEM_ATTRIBUTES',NULL);
   open C_GET_OTHR_CTRY_LDATE;
   SQL_LIB.SET_MARK('OPEN','C_GET_OTHR_CTRY_LDATE','ITEM_ATTRIBUTES',NULL);
   fetch C_GET_OTHR_CTRY_LDATE into L_launch_date,
                                    L_country_id;
   SQL_LIB.SET_MARK('OPEN','C_GET_OTHR_CTRY_LDATE','ITEM_ATTRIBUTES',NULL);
   close C_GET_OTHR_CTRY_LDATE;

   if L_country_id = 'U' then
      L_launch_date_uk := L_launch_date;
   elsif L_country_id = 'R' then
      L_launch_date_roi := L_launch_date;
   end if;
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   if L_launch_date_uk is NULL and L_launch_date_roi is NOT NULL then
      L_launch_date_uk := L_launch_date_roi;
   elsif L_launch_date_uk is NOT NULL and L_launch_date_roi is NULL then
      L_launch_date_roi := L_launch_date_uk;
   end if;

   if L_launch_date_uk < LP_vdate then
      L_launch_date_uk := I_future_date;
   end if;

   if L_launch_date_roi < LP_vdate then
      L_launch_date_roi := I_future_date;
   end if;

   -- Gets the minimal date among UK and ROI dates.
   if L_launch_date_uk < L_launch_date_roi then
      L_effective_date := L_launch_date_uk;
   else
      L_effective_date := L_launch_date_roi;
   end if;

   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   if L_effective_date is NULL then
      L_effective_date := L_item_launch_date;
   end if;
   --moved the below code from down.
   --Checks if there are any items which have Range effective date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_CHECK_RANGE_DESC','TSL_ITEM_RANGE',NULL);
   open C_CHECK_RANGE_DESC;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_RANGE_DESC','TSL_ITEM_RANGE',NULL);
   fetch C_CHECK_RANGE_DESC into L_update_range;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_RANGE_DESC','TSL_ITEM_RANGE',NULL);
   close C_CHECK_RANGE_DESC;

   if L_update_range = 'Y' then
      if L_items_tbl is NOT NULL and L_items_tbl.COUNT > 0 then
         FOR a in 1..L_items_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_RANGE_INFO','tsl_item_range','Item: '||I_item);
            open C_GET_RANGE_INFO(L_items_tbl(a).item);
            SQL_LIB.SET_MARK('FETCH','C_GET_RANGE_INFO','tsl_item_range','Item: '||I_item);
            -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            fetch C_GET_RANGE_INFO into L_range_rec;
            -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
            SQL_LIB.SET_MARK('CLOSE','C_GET_RANGE_INFO','tsl_item_range','Item: '||I_item);
            close C_GET_RANGE_INFO;

           -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
           if L_range_rec.item is NOT NULL then
           -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
              update tsl_item_range
                 ---5-May-2010 Tesco HSC/Usha Patil        Defect Id: NBS00017304 Begin
                 set effective_date = I_future_date
                 ---5-May-2010 Tesco HSC/Usha Patil        Defect Id: NBS00017304 End
               -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
               where item           = L_range_rec.item
                 and effective_date = L_range_rec.effective_date
                 and tsl_country_id = L_range_rec.tsl_country_id;
               -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
            end if;
         END LOOP;
      end if;
   end if;

   if L_update_item_desc = 'N' then
      return TRUE;
   end if;
   -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   --Checks if there are any items which have Base Desc effective date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_CHECK_BASE_DESC','TSL_ITEMDESC_BASE',NULL);
   open C_CHECK_BASE_DESC;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_BASE_DESC','TSL_ITEMDESC_BASE',NULL);
   fetch C_CHECK_BASE_DESC into L_update_base;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_BASE_DESC','TSL_ITEMDESC_BASE',NULL);
   close C_CHECK_BASE_DESC;

   if L_update_base = 'Y' then
      if L_items_tbl is NOT NULL and L_items_tbl.COUNT > 0 then
         FOR a in 1..L_items_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEMDESC_BASE','tsl_itemdesc_base','Item: '||I_item);
            open C_GET_ITEMDESC_BASE(L_items_tbl(a).item);
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEMDESC_BASE','tsl_itemdesc_base','Item: '||I_item);
            fetch C_GET_ITEMDESC_BASE into L_itemdesc_base_rec;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMDESC_BASE','tsl_itemdesc_base','Item: '||I_item);
            close C_GET_ITEMDESC_BASE;

            if L_itemdesc_base_rec.item is NOT NULL then
               update tsl_itemdesc_base
                  set effective_date = L_effective_date
                where item           = L_itemdesc_base_rec.item
                  and effective_date = L_itemdesc_base_rec.effective_date;
            end if;
         END LOOP;
      end if;
   end if;

   --Checks if there are any items which have eptsel Desc effective date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_CHECK_EPISEL_DESC','TSL_ITEMDESC_EPISEL',NULL);
   open C_CHECK_EPISEL_DESC;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_EPISEL_DESC','TSL_ITEMDESC_EPISEL',NULL);
   fetch C_CHECK_EPISEL_DESC into L_update_episel;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_EPISEL_DESC','TSL_ITEMDESC_EPISEL',NULL);
   close C_CHECK_EPISEL_DESC;

   if L_update_episel = 'Y' then
      if L_items_tbl is NOT NULL and L_items_tbl.COUNT > 0 then
         FOR a in 1..L_items_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEMDESC_EPISEL','tsl_itemdesc_episel','Item: '||I_item);
            open C_GET_ITEMDESC_EPISEL(L_items_tbl(a).item);
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEMDESC_EPISEL','tsl_itemdesc_episel','Item: '||I_item);
            fetch C_GET_ITEMDESC_EPISEL into L_itemdesc_episel_rec;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMDESC_EPISEL','tsl_itemdesc_episel','Item: '||I_item);
            close C_GET_ITEMDESC_EPISEL;

            if L_itemdesc_episel_rec.item is NOT NULL then
               update tsl_itemdesc_episel
                  set effective_date = L_effective_date
                where item           = L_itemdesc_episel_rec.item
                  and effective_date = L_itemdesc_episel_rec.effective_date;
            end if;
         END LOOP;
      end if;
   end if;


   --Checks if there are any items which have Sel Desc effective date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_CHECK_SEL_DESC','TSL_ITEMDESC_SEL',NULL);
   open C_CHECK_SEL_DESC;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_SEL_DESC','TSL_ITEMDESC_SEL',NULL);
   fetch C_CHECK_SEL_DESC into L_update_sel;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_SEL_DESC','TSL_ITEMDESC_SEL',NULL);
   close C_CHECK_SEL_DESC;

   if L_update_sel = 'Y' then
      if L_items_tbl is NOT NULL and L_items_tbl.COUNT > 0 then
         FOR a in 1..L_items_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEMDESC_SEL','tsl_itemdesc_sel','Item: '||I_item);
            open C_GET_ITEMDESC_SEL(L_items_tbl(a).item);
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEMDESC_SEL','tsl_itemdesc_sel','Item: '||I_item);
            fetch C_GET_ITEMDESC_SEL into L_itemdesc_sel_rec;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMDESC_SEL','tsl_itemdesc_sel','Item: '||I_item);
            close C_GET_ITEMDESC_SEL;

            if L_itemdesc_sel_rec.item is NOT NULL then
               update tsl_itemdesc_sel
                  set effective_date = L_effective_date
                where item           = L_itemdesc_sel_rec.item
                  and effective_date = L_itemdesc_sel_rec.effective_date;
            end if;
         END LOOP;
      end if;
   end if;

   --Checks if there are any items which have Pack Desc effective date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_CHECK_PACK_DESC','TSL_ITEMDESC_PACK',NULL);
   open C_CHECK_PACK_DESC;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_PACK_DESC','TSL_ITEMDESC_PACK',NULL);
   fetch C_CHECK_PACK_DESC into L_update_pack;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_PACK_DESC','TSL_ITEMDESC_PACK',NULL);
   close C_CHECK_PACK_DESC;

   if L_update_pack = 'Y' then
      if L_items_tbl is NOT NULL and L_items_tbl.COUNT > 0 then
         FOR a in 1..L_items_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEMDESC_PACK','tsl_itemdesc_pack','Item: '||I_item);
            open C_GET_ITEMDESC_PACK(L_items_tbl(a).item);
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEMDESC_PACK','tsl_itemdesc_pack','Item: '||I_item);
            fetch C_GET_ITEMDESC_PACK into L_itemdesc_pack_rec;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMDESC_PACK','tsl_itemdesc_pack','Item: '||I_item);
            close C_GET_ITEMDESC_PACK;

            if L_itemdesc_pack_rec.pack_no is NOT NULL then
               update tsl_itemdesc_pack
                  set effective_date = L_effective_date
                where pack_no        = L_itemdesc_pack_rec.pack_no
                  and effective_date = L_itemdesc_pack_rec.effective_date;
            end if;
         END LOOP;
      end if;
   end if;

   --Checks if there are any items which have ISS Desc effective date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_CHECK_ISS_DESC','TSL_ITEMDESC_ISS',NULL);
   open C_CHECK_ISS_DESC;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ISS_DESC','TSL_ITEMDESC_ISS',NULL);
   fetch C_CHECK_ISS_DESC into L_update_iss;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ISS_DESC','TSL_ITEMDESC_ISS',NULL);
   close C_CHECK_ISS_DESC;

   if L_update_iss = 'Y' then
      if L_items_tbl is NOT NULL and L_items_tbl.COUNT > 0 then
         FOR a in 1..L_items_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEMDESC_ISS','tsl_itemdesc_iss','Item: '||I_item);
            open C_GET_ITEMDESC_ISS(L_items_tbl(a).item);
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEMDESC_ISS','tsl_itemdesc_iss','Item: '||I_item);
            fetch C_GET_ITEMDESC_ISS into L_itemdesc_iss_rec;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMDESC_ISS','tsl_itemdesc_iss','Item: '||I_item);
            close C_GET_ITEMDESC_ISS;

            if L_itemdesc_iss_rec.item is NOT NULL then
               update tsl_itemdesc_iss
                  set effective_date = L_effective_date
                where item           = L_itemdesc_iss_rec.item
                  and effective_date = L_itemdesc_iss_rec.effective_date;
            end if;
         END LOOP;
      end if;
   end if;

   --Checks if there are any items which have Till Desc effective date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_CHECK_TILL_DESC','TSL_ITEMDESC_TILL',NULL);
   open C_CHECK_TILL_DESC;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_TILL_DESC','TSL_ITEMDESC_TILL',NULL);
   fetch C_CHECK_TILL_DESC into L_update_till;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_TILL_DESC','TSL_ITEMDESC_TILL',NULL);
   close C_CHECK_TILL_DESC;

   if L_update_till = 'Y' then
      if L_items_tbl is NOT NULL and L_items_tbl.COUNT > 0 then
         FOR a in 1..L_items_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEMDESC_TILL','tsl_itemdesc_till','Item: '||I_item);
            open C_GET_ITEMDESC_TILL(L_items_tbl(a).item);
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEMDESC_TILL','tsl_itemdesc_till','Item: '||I_item);
            fetch C_GET_ITEMDESC_TILL into L_itemdesc_till_rec;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMDESC_TILL','tsl_itemdesc_till','Item: '||I_item);
            close C_GET_ITEMDESC_TILL;

            if L_itemdesc_till_rec.item is NOT NULL then
               update tsl_itemdesc_till
                  set effective_date = L_effective_date
                where item           = L_itemdesc_till_rec.item
                  and effective_date = L_itemdesc_till_rec.effective_date;
            end if;
         END LOOP;
      end if;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END TSL_UPDATE_ITEM_ATTR;
-- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
-----------------------------------------------------------------------------------------------------
-- Function name: TSL_UPDATE_SCA
-- Purpose      : To update the effective_dates of supply chain attributes to future date on item approval.
-----------------------------------------------------------------------------------------------------
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
-- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
-- As the whole function was re-written for 288c, the code has been replaced from 3.5f

-----------------------------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_SCA(O_error_message   IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                        I_item            IN        ITEM_MASTER.ITEM%TYPE,
                        -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                        I_old_country_id  IN        ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE,
                        I_country_id      IN        ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE)
                        -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   RETURN BOOLEAN IS
   L_program       VARCHAR2(64)      := 'ITEM_APPROVAL_SQL_FIX.TSL_UPDATE_SCA';
   L_tomorrow      PERIOD.VDATE%TYPE := LP_vdate+1;

   CURSOR C_GET_WOG_EFF_DT is
   select max(effective_date) effective_date
     from tsl_sca_wh_order_grp
    where item = I_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_sca_wh_order_grp
                       where item            = I_item
                         and (effective_date = L_tomorrow
                          or effective_date  = LP_vdate));

   TYPE sca_wog_tbl is TABLE OF C_GET_WOG_EFF_DT%ROWTYPE
   INDEX BY BINARY_INTEGER;

   L_sca_wog_tbl sca_wog_tbl;

   CURSOR C_GET_WOG_EFF_DT_LOCK(Cp_effective_date    TSL_SCA_WH_ORDER_GRP.EFFECTIVE_DATE%TYPE) is
   select 'x'
     from tsl_sca_wh_order_grp
    where item           = I_item
      and effective_date = Cp_effective_date
      for update nowait;

   CURSOR C_GET_WDG_EFF_DT is
   select max(effective_date) effective_date
     from tsl_sca_wh_dist_grp
    where item = I_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_sca_wh_dist_grp
                       where item            = I_item
                         and (effective_date = L_tomorrow
                          or effective_date  = LP_vdate));

   TYPE sca_wdg_tbl is TABLE OF C_GET_WDG_EFF_DT%ROWTYPE
   INDEX BY BINARY_INTEGER;

   L_sca_wdg_tbl sca_wdg_tbl;

   CURSOR C_GET_WDG_EFF_DT_LOCK(Cp_effective_date    TSL_SCA_WH_DIST_GRP.EFFECTIVE_DATE%TYPE) is
   select 'x'
     from tsl_sca_wh_dist_grp
    where item           = I_item
      and effective_date = Cp_effective_date
      for update nowait;

   CURSOR C_GET_DDG_EFF_DT is
   select max(effective_date) effective_date
     from tsl_sca_direct_dist_grp
    where item = I_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_sca_direct_dist_grp
                       where item            = I_item
                         and (effective_date = L_tomorrow
                          or effective_date  = LP_vdate));

   TYPE sca_ddg_tbl is TABLE OF C_GET_DDG_EFF_DT%ROWTYPE
   INDEX BY BINARY_INTEGER;

   L_sca_ddg_tbl sca_ddg_tbl;

   CURSOR C_GET_DDG_EFF_DT_LOCK(Cp_effective_date    TSL_SCA_DIRECT_DIST_GRP.EFFECTIVE_DATE%TYPE) is
   select 'x'
     from tsl_sca_direct_dist_grp
    where item           = I_item
      and effective_date = Cp_effective_date
      for update nowait;

   CURSOR C_GET_DOG_EFF_DT is
   select max(effective_date) effective_date
     from tsl_sca_direct_order_grp
    where item = I_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_sca_direct_order_grp
                       where item            = I_item
                         and (effective_date = L_tomorrow
                          or effective_date  = LP_vdate));

   TYPE sca_dog_tbl is TABLE OF C_GET_DOG_EFF_DT%ROWTYPE
   INDEX BY BINARY_INTEGER;

   L_sca_dog_tbl sca_dog_tbl;

   CURSOR C_GET_DOG_EFF_DT_LOCK(Cp_effective_date    TSL_SCA_DIRECT_ORDER_GRP.EFFECTIVE_DATE%TYPE) is
   select 'x'
     from tsl_sca_direct_order_grp
    where item           = I_item
      and effective_date = Cp_effective_date
      for update nowait;

   CURSOR C_GET_DDP_INFO is
   select tsddp.item,
          tsddp.pack_no,
          tsddp.supplier,
          tsddp.start_date,
          tsddp.tsl_country_id
     from tsl_sca_direct_dist_packs tsddp
    where tsddp.item = I_item
      and tsddp.start_date = (select max(tsddp1.start_date)
                                from tsl_sca_direct_dist_packs tsddp1
                               where tsddp.item           = tsddp1.item
                                 and tsddp.pack_no        = tsddp1.pack_no
                                 and tsddp.supplier       = tsddp1.supplier
                                 and tsddp.tsl_country_id = tsddp1.tsl_country_id
                                 and tsddp1.start_date < LP_vdate)
      and NOT EXISTS (select 1
                        from tsl_sca_direct_dist_packs tsddp2
                       where tsddp.item           = tsddp2.item
                         and tsddp.pack_no        = tsddp2.pack_no
                         and tsddp.supplier       = tsddp2.supplier
                         and tsddp.tsl_country_id = tsddp2.tsl_country_id
                         and tsddp2.start_date in (LP_vdate, L_tomorrow))
      -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      and tsddp.tsl_country_id = I_country_id;
      -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   TYPE sca_ddp_info_tbl is TABLE OF C_GET_DDP_INFO%ROWTYPE
   INDEX BY BINARY_INTEGER;

   L_sca_ddp_info_tbl sca_ddp_info_tbl;

   CURSOR C_GET_DDP_INFO_LOCK(Cp_supplier      TSL_SCA_DIRECT_DIST_PACKS.SUPPLIER%TYPE,
                              Cp_pack_no       TSL_SCA_DIRECT_DIST_PACKS.PACK_NO%TYPE,
                              Cp_country_id    TSL_SCA_DIRECT_DIST_PACKS.TSL_COUNTRY_ID%TYPE,
                              Cp_start_date    TSL_SCA_DIRECT_DIST_PACKS.START_DATE%TYPE) is
   select 'x'
     from tsl_sca_direct_dist_packs
    where item           = I_item
      and supplier       = Cp_supplier
      and pack_no        = Cp_pack_no
      and tsl_country_id = Cp_country_id
      and start_date     = Cp_start_date
      for update nowait;

   CURSOR C_GET_WO_EFF_DT is
   select item,
          max(effective_date) effective_date,
          tsl_country_id
     from tsl_sca_wh_order
    where item = I_item
      and effective_date < LP_vdate
      and NOT EXISTS (select 1
                        from tsl_sca_wh_order
                       where item            = I_item
                         and (effective_date = L_tomorrow
                          or effective_date  = LP_vdate))
      -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      and tsl_country_id = I_country_id
      -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
    group by item,
             tsl_country_id;

   TYPE sca_wo_tbl is TABLE OF C_GET_WO_EFF_DT%ROWTYPE
   INDEX BY BINARY_INTEGER;

   L_sca_wo_tbl sca_wo_tbl;

   CURSOR C_GET_WO_EFF_DT_LOCK(Cp_effective_date    TSL_SCA_WH_ORDER.EFFECTIVE_DATE%TYPE,
                               Cp_country_id        TSL_SCA_WH_ORDER.TSL_COUNTRY_ID%TYPE) is
   select 'x'
     from tsl_sca_wh_order
    where item           = I_item
      and effective_date = Cp_effective_date
      and tsl_country_id = Cp_country_id
      for update nowait;

   CURSOR C_GET_WOPP_INFO is
   select tswopp.item,
          tswopp.wh,
          tswopp.effective_date,
          tswopp.tsl_country_id
     from tsl_sca_wh_order_pref_pack tswopp
    where tswopp.item = I_item
      and tswopp.effective_date = (select max(tswopp1.effective_date)
                                     from tsl_sca_wh_order_pref_pack tswopp1
                                    where tswopp.item           = tswopp1.item
                                      and tswopp.wh             = tswopp1.wh
                                      and tswopp.tsl_country_id = tswopp1.tsl_country_id
                                      and tswopp1.effective_date < LP_vdate)
      and NOT EXISTS (select 1
                        from tsl_sca_wh_order_pref_pack tswopp2
                       where tswopp.item           = tswopp2.item
                         and tswopp.wh             = tswopp2.wh
                         and tswopp.tsl_country_id = tswopp2.tsl_country_id
                         and tswopp2.effective_date in (LP_vdate, L_tomorrow))
      -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      and tsl_country_id = I_country_id;
      -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   TYPE sca_wopp_info_tbl is TABLE OF C_GET_WOPP_INFO%ROWTYPE
   INDEX BY BINARY_INTEGER;

   L_sca_wopp_info_tbl sca_wopp_info_tbl;

   CURSOR C_GET_WOPP_INFO_LOCK(Cp_wh                TSL_SCA_WH_ORDER_PREF_PACK.WH%TYPE,
                               Cp_country_id        TSL_SCA_WH_ORDER_PREF_PACK.TSL_COUNTRY_ID%TYPE,
                               Cp_effective_date    TSL_SCA_WH_ORDER_PREF_PACK.EFFECTIVE_DATE%TYPE) is
   select 'x'
     from tsl_sca_wh_order_pref_pack
    where item           = I_item
      and wh             = Cp_wh
      and tsl_country_id = Cp_country_id
      and effective_date = Cp_effective_date
      for update nowait;

BEGIN
   -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   if I_old_country_id = 'N' then
   -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
      --Checks if there are any items which have Wh Order Group effective date less than vdate.
      SQL_LIB.SET_MARK('OPEN','C_GET_WOG_EFF_DT','tsl_sca_wh_order_grp','Item: '||I_item);
      open C_GET_WOG_EFF_DT;
      SQL_LIB.SET_MARK('FETCH','C_GET_WOG_EFF_DT','tsl_sca_wh_order_grp','Item: '||I_item);
      fetch C_GET_WOG_EFF_DT BULK COLLECT into L_sca_wog_tbl;
      SQL_LIB.SET_MARK('CLOSE','C_GET_WOG_EFF_DT','tsl_sca_wh_order_grp','Item: '||I_item);
      close C_GET_WOG_EFF_DT;

      if L_sca_wog_tbl is NOT NULL and L_sca_wog_tbl.COUNT > 0 then
         FOR i IN 1..L_sca_wog_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_WOG_EFF_DT_LOCK','tsl_sca_wh_order_grp','Item: '||I_item);
            open C_GET_WOG_EFF_DT_LOCK(L_sca_wog_tbl(i).effective_date);
            SQL_LIB.SET_MARK('CLOSE','C_GET_WOG_EFF_DT_LOCK','tsl_sca_wh_order_grp','Item: '||I_item);
            close C_GET_WOG_EFF_DT_LOCK;

            update tsl_sca_wh_order_grp
               set effective_date = L_tomorrow
             where item           = I_item
               and effective_date = L_sca_wog_tbl(i).effective_date;

            ---28-May-2010 Tesco HSC/Manikandan       Defect Id: NBS00017739 Begin
             delete from tsl_sca_wh_order_grp
               where effective_date < LP_vdate
               and   item           = I_item;
            ---28-May-2010 Tesco HSC/Manikandan       Defect Id: NBS00017739 End
         END LOOP;
      end if;

      --Checks if there are any items which have Wh Dist Group effective date less than vdate.
      SQL_LIB.SET_MARK('OPEN','C_GET_WDG_EFF_DT','tsl_sca_wh_dist_grp','Item: '||I_item);
      open C_GET_WDG_EFF_DT;
      SQL_LIB.SET_MARK('FETCH','C_GET_WDG_EFF_DT','tsl_sca_wh_dist_grp','Item: '||I_item);
      fetch C_GET_WDG_EFF_DT BULK COLLECT into L_sca_wdg_tbl;
      SQL_LIB.SET_MARK('CLOSE','C_GET_WDG_EFF_DT','tsl_sca_wh_dist_grp','Item: '||I_item);
      close C_GET_WDG_EFF_DT;

      if L_sca_wdg_tbl is NOT NULL and L_sca_wdg_tbl.COUNT > 0 then
         FOR i IN 1..L_sca_wdg_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_WDG_EFF_DT_LOCK','tsl_sca_wh_dist_grp','Item: '||I_item);
            open C_GET_WDG_EFF_DT_LOCK(L_sca_wdg_tbl(i).effective_date);
            SQL_LIB.SET_MARK('CLOSE','C_GET_WDG_EFF_DT_LOCK','tsl_sca_wh_dist_grp','Item: '||I_item);
            close C_GET_WDG_EFF_DT_LOCK;

            update tsl_sca_wh_dist_grp
               set effective_date = L_tomorrow
             where item           = I_item
               and effective_date = L_sca_wdg_tbl(i).effective_date;
            ---28-May-2010 Tesco HSC/Manikandan       Defect Id: NBS00017739 Begin
            delete from tsl_sca_wh_dist_grp
               where effective_date < LP_vdate
               and   item           = I_item;
            ---28-May-2010 Tesco HSC/Manikandan       Defect Id: NBS00017739 End
         END LOOP;
      end if;

      --Checks if there are any items which have Direct Dist Group effective date less than vdate.
      SQL_LIB.SET_MARK('OPEN','C_GET_DDG_EFF_DT','tsl_sca_direct_dist_grp','Item: '||I_item);
      open C_GET_DDG_EFF_DT;
      SQL_LIB.SET_MARK('FETCH','C_GET_DDG_EFF_DT','tsl_sca_direct_dist_grp','Item: '||I_item);
      fetch C_GET_DDG_EFF_DT BULK COLLECT into L_sca_ddg_tbl;
      SQL_LIB.SET_MARK('CLOSE','C_GET_DDG_EFF_DT','tsl_sca_direct_dist_grp','Item: '||I_item);
      close C_GET_DDG_EFF_DT;

      if L_sca_ddg_tbl is NOT NULL and L_sca_ddg_tbl.COUNT > 0 then
         FOR i IN 1..L_sca_ddg_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_DDG_EFF_DT_LOCK','tsl_sca_direct_dist_grp','Item: '||I_item);
            open C_GET_DDG_EFF_DT_LOCK(L_sca_ddg_tbl(i).effective_date);
            SQL_LIB.SET_MARK('CLOSE','C_GET_DDG_EFF_DT_LOCK','tsl_sca_direct_dist_grp','Item: '||I_item);
            close C_GET_DDG_EFF_DT_LOCK;

            update tsl_sca_direct_dist_grp
               set effective_date = L_tomorrow
             where item           = I_item
               and effective_date = L_sca_ddg_tbl(i).effective_date;
            ---28-May-2010 Tesco HSC/Manikandan       Defect Id: NBS00017739 Begin
            delete from tsl_sca_direct_dist_grp
               where effective_date < LP_vdate
               and   item           = I_item;
            ---28-May-2010 Tesco HSC/Manikandan       Defect Id: NBS00017739 End
         END LOOP;
      end if;

      --Checks if there are any items which have Direct Order Group effective date less than vdate.
      SQL_LIB.SET_MARK('OPEN','C_GET_DOG_EFF_DT','tsl_sca_direct_order_grp','Item: '||I_item);
      open C_GET_DOG_EFF_DT;
      SQL_LIB.SET_MARK('FETCH','C_GET_DOG_EFF_DT','tsl_sca_direct_order_grp','Item: '||I_item);
      fetch C_GET_DOG_EFF_DT BULK COLLECT into L_sca_dog_tbl;
      SQL_LIB.SET_MARK('CLOSE','C_GET_DOG_EFF_DT','tsl_sca_direct_order_grp','Item: '||I_item);
      close C_GET_DOG_EFF_DT;

      if L_sca_dog_tbl is NOT NULL and L_sca_dog_tbl.COUNT > 0 then
         FOR i IN 1..L_sca_dog_tbl.COUNT LOOP
            SQL_LIB.SET_MARK('OPEN','C_GET_DOG_EFF_DT_LOCK','tsl_sca_direct_order_grp','Item: '||I_item);
            open C_GET_DOG_EFF_DT_LOCK(L_sca_dog_tbl(i).effective_date);
            SQL_LIB.SET_MARK('CLOSE','C_GET_DOG_EFF_DT_LOCK','tsl_sca_direct_order_grp','Item: '||I_item);
            close C_GET_DOG_EFF_DT_LOCK;

            update tsl_sca_direct_order_grp
               set effective_date = L_tomorrow
             where item           = I_item
               and effective_date = L_sca_dog_tbl(i).effective_date;
            ---28-May-2010 Tesco HSC/Manikandan       Defect Id: NBS00017739 Begin
            delete from tsl_sca_direct_order_grp
               where effective_date < LP_vdate
               and   item           = I_item;
            ---28-May-2010 Tesco HSC/Manikandan       Defect Id: NBS00017739 Begin
         END LOOP;
      end if;
   -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
  end if;
   -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   --Checks if there are any items which have Direct Dist Packs start date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_GET_DDP_INFO','tsl_sca_direct_dist_packs','Item: '||I_item);
   open C_GET_DDP_INFO;
   SQL_LIB.SET_MARK('FETCH','C_GET_DDP_INFO','tsl_sca_direct_dist_packs','Item: '||I_item);
   fetch C_GET_DDP_INFO BULK COLLECT into L_sca_ddp_info_tbl;
   SQL_LIB.SET_MARK('CLOSE','C_GET_DDP_INFO','tsl_sca_direct_dist_packs','Item: '||I_item);
   close C_GET_DDP_INFO;

   if L_sca_ddp_info_tbl is NOT NULL and L_sca_ddp_info_tbl.COUNT>0 then
      FOR i IN 1..L_sca_ddp_info_tbl.COUNT LOOP
         SQL_LIB.SET_MARK('OPEN','C_GET_DDP_INFO_LOCK','tsl_sca_direct_dist_packs','Item: '||I_item);
         open C_GET_DDP_INFO_LOCK(L_sca_ddp_info_tbl(i).supplier,
                                  L_sca_ddp_info_tbl(i).pack_no,
                                  L_sca_ddp_info_tbl(i).tsl_country_id,
                                  L_sca_ddp_info_tbl(i).start_date);
         SQL_LIB.SET_MARK('CLOSE','C_GET_DDP_INFO_LOCK','tsl_sca_direct_dist_packs','Item: '||I_item);
         close C_GET_DDP_INFO_LOCK;

         update tsl_sca_direct_dist_packs
            set start_date     = L_tomorrow
          where item           = I_item
            and supplier       = L_sca_ddp_info_tbl(i).supplier
            and pack_no        = L_sca_ddp_info_tbl(i).pack_no
            and tsl_country_id = L_sca_ddp_info_tbl(i).tsl_country_id
            and start_date     = L_sca_ddp_info_tbl(i).start_date;
      END LOOP;
   end if;

   --Checks if there are any items which have Wh Order effective date less than vdate.
   SQL_LIB.SET_MARK('OPEN','C_GET_WO_EFF_DT','tsl_sca_wh_order','Item: '||I_item);
   open C_GET_WO_EFF_DT;
   SQL_LIB.SET_MARK('FETCH','C_GET_WO_EFF_DT','tsl_sca_wh_order','Item: '||I_item);
   fetch C_GET_WO_EFF_DT BULK COLLECT into L_sca_wo_tbl;
   SQL_LIB.SET_MARK('CLOSE','C_GET_WO_EFF_DT','tsl_sca_wh_order','Item: '||I_item);
   close C_GET_WO_EFF_DT;

   if L_sca_wo_tbl is NOT NULL and L_sca_wo_tbl.COUNT > 0 then
      FOR i IN 1..L_sca_wo_tbl.COUNT LOOP
         SQL_LIB.SET_MARK('OPEN','C_GET_WO_EFF_DT_LOCK','tsl_sca_wh_order','Item: '||I_item);
         open C_GET_WO_EFF_DT_LOCK(L_sca_wo_tbl(i).effective_date,
                                   L_sca_wo_tbl(i).tsl_country_id);
         SQL_LIB.SET_MARK('CLOSE','C_GET_WO_EFF_DT_LOCK','tsl_sca_wh_order','Item: '||I_item);
         close C_GET_WO_EFF_DT_LOCK;

         update tsl_sca_wh_order
            set effective_date = L_tomorrow
          where item           = I_item
            and effective_date = L_sca_wo_tbl(i).effective_date
            and tsl_country_id = L_sca_wo_tbl(i).tsl_country_id;
      END LOOP;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_WOPP_INFO','tsl_sca_wh_order_pref_pack','Item: '||I_item);
   open C_GET_WOPP_INFO;
   SQL_LIB.SET_MARK('FETCH','C_GET_DDP_INFO','tsl_sca_wh_order_pref_pack','Item: '||I_item);
   fetch C_GET_WOPP_INFO BULK COLLECT into L_sca_wopp_info_tbl;
   SQL_LIB.SET_MARK('CLOSE','C_GET_DDP_INFO','tsl_sca_wh_order_pref_pack','Item: '||I_item);
   close C_GET_WOPP_INFO;

   --Checks if there are any items which have Wh Order Pref Pack effective date less than vdate.
   if L_sca_wopp_info_tbl is NOT NULL and L_sca_wopp_info_tbl.COUNT>0 then
      FOR i IN 1..L_sca_wopp_info_tbl.COUNT LOOP
         SQL_LIB.SET_MARK('OPEN','C_GET_WOPP_INFO_LOCK','tsl_sca_wh_order_pref_pack','Item: '||I_item);
         open C_GET_WOPP_INFO_LOCK(L_sca_wopp_info_tbl(i).wh,
                                   L_sca_wopp_info_tbl(i).tsl_country_id,
                                   L_sca_wopp_info_tbl(i).effective_date);
         SQL_LIB.SET_MARK('CLOSE','C_GET_WOPP_INFO_LOCK','tsl_sca_wh_order_pref_pack','Item: '||I_item);
         close C_GET_WOPP_INFO_LOCK;

         update tsl_sca_wh_order_pref_pack
            set effective_date = L_tomorrow
          where item           = I_item
            and wh             = L_sca_wopp_info_tbl(i).wh
            and tsl_country_id = L_sca_wopp_info_tbl(i).tsl_country_id
            and effective_date = L_sca_wopp_info_tbl(i).effective_date;
      END LOOP;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END TSL_UPDATE_SCA;
-- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
-----------------------------------------------------------------------------------------------------
-- 15-Apr-2010 Usha Patil, usha.patil@in.tesco.com          Mod: CR295 End
-----------------------------------------------------------------------------------------------------
--12-May-2010 Murali  Cr288b Begin
-----------------------------------------------------------------------------------------------------
-- Function name: TSL_CHECK_RP_COMP
-- Purpose      : To check if ratio pack contains country specific components.
-----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_RP_COMP (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_uk_exists       IN OUT BOOLEAN,
                            O_roi_exists      IN OUT BOOLEAN,
                            I_item            IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program            VARCHAR2(50):= 'ITEM_APPROVAL_SQL_FIX.TSL_CHECK_RP_COMP';
   L_country_id         VARCHAR2(1);
   L_dummy              NUMBER(1);

   CURSOR C_RP_COMP is
      select 1
        from packitem pi,
             item_master im
       where pi.pack_no = I_item
         and pi.item = im.item
         and im.tsl_country_auth_ind = L_country_id;

BEGIN
   O_uk_exists := TRUE;
   O_roi_exists := TRUE;
   L_country_id := 'U';

   SQL_LIB.SET_MARK('OPEN', 'C_RP_COMP', 'PACKITEM', 'Item: '|| I_item);
   open C_RP_COMP;

   SQL_LIB.SET_MARK('FETCH', 'C_RP_COMP', 'PACKITEM', 'Item: '|| I_item);
   fetch C_RP_COMP into L_dummy;

   if C_RP_COMP%NOTFOUND then
      O_uk_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_RP_COMP', 'PACKITEM', 'Item: '|| I_item);
   close C_RP_COMP;

   L_country_id := 'R';
   SQL_LIB.SET_MARK('OPEN', 'C_RP_COMP', 'PACKITEM', 'Item: '|| I_item);
   open C_RP_COMP;

   SQL_LIB.SET_MARK('FETCH', 'C_RP_COMP', 'PACKITEM', 'Item: '|| I_item);
   fetch C_RP_COMP into L_dummy;

   if C_RP_COMP%NOTFOUND then
      O_roi_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_RP_COMP', 'PACKITEM', 'Item: '|| I_item);
   close C_RP_COMP;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_RP_COMP;

-----------------------------------------------------------------------------------------------------
--12-May-2010 Murali  Cr288b End
-----------------------------------------------------------------------------------------------------
END;
/

