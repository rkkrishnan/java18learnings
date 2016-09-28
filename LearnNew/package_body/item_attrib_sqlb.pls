CREATE OR REPLACE PACKAGE BODY ITEM_ATTRIB_SQL AS
---------------------------------------------------------------------------------------------
-- Mod By:      Natarajan Chandrashekaran, natarajan.chandrashekaran@in.tesco.com
-- Mod Date:    14-May-2007
-- Mod Ref:     Mod number. N20
-- Mod Details: The new function TSL_EPW_EXISTS has been added. This fuction used to gets the
--              information of EPW from the Merch_hirech_default table
---------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com.
-- Mod Date   : 31-Aug-2007
-- Mod Ref    : Mod No. 365b (Drop 2)
-- Mod Details: The new function TSL_GET_COMPLEX_PACK_IND has been added.
---------------------------------------------------------------------------------------------
-- Mod By:      Shweta Madnawat, shweta.madnawat@in.tesco.com
-- Mod Date:    18-Sep-2007
-- Mod Ref:     Mod number. N22
-- Mod Details: New functions have been added to check if all the required
--              conditions are met for an item to be submitted or approved.
---------------------------------------------------------------------------------------------
-- Mod By     : Rachaputi Praveen, praveen.rachaputi@in.tesco.com
-- Mod Date   : 08-Oct-2007
-- Mod Ref    : Mod N112
-- Mod Details: Added new function TSL_CHECK_ITEM_EXIST,To Check the item keyed-in in Barcode
--              Move Screen is available in Item master table.
--              Added new function TSL_GET_ITEM_INFO, To Get the item related information for
--              the item.
--              Added new function TSL_GET_ITEM_INFO, This is a over ride function which
--              Get relevant item information from Item master table.
--              Added new function TSL_SET_PRIMARY_REF_ITEM,This function will check the move
--              or exchanged the L3 Item / L2 Pack is a primary reference item and if yes it
--              will set another L3 item belongs to the same parent as primary reference item
---------------------------------------------------------------------------------------------
-- Mod By       : Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
-- Mod Date     : 22-Nov-2007
-- Mod Ref      : DefNBS00004099
-- Mod Details  : Added new functions TSL_GET_BARCODE_ATTRIB, TSL_SET_BARCODE_ATTRIB
-----------------------------------------------------------------------------------------------------
-- Mod By     : Rachaputi Praveen, praveen.rachaputi@in.tesco.com
-- Mod Date   : 03-Dec-2007
-- Mod Ref    : DefNBS00004280
-- Mod Details: TSL_SET_PRIMARY_REF_ITEM function modified to fix DefNBS00004280.
---------------------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    23-Nov-2007
-- Mod Ref:     Defect 4206
-- Mod Details: New function tsl_check_retail_occ_barcode has been added and tsl_subtran_exist
--              function modified to check only the presence of level3 items or level2 packs.
---------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 24-Sep-2007
-- Mod Ref    : Mod number. N105
-- Mod Details: Modified function DELETE_EAN to return the reference number back
--              to RNA before deleting from ITEM_MASTER table.
--
--              Added new function TSL_GET_FIRST_EAN.This function will retrieve the lowest value
--              of EANOWN Level 3 item from the item_master table for a parent item.
--
--              Added New Function TSL_GET_PRIMARY_REF_EAN.It will retrieve the primary reference
--              value of EANOWN type Level 3 item from the item_master table for a parent item.
--
--              Modification in POPULATE_EAN_TABLE function
----------------------------------------------------------------------------------------
-- Mod By     : John Anand, john.anand@in.tesco.com                                   --
-- Mod Date   : 30-Jan-2008                                                           --
-- Mod Ref    : Mod N114                                                              --
-- Mod Details: Amended script to fetch few values from item master table.            --
----------------------------------------------------------------------------------------
-- Mod By     : Wipro Enabler/Dhuraison Prince                                        --
-- Mod Date   : 31-Jan-2008                                                           --
-- Mod Ref    : Mod N114                                                              --
-- Mod Details: Amended script to fetch few values from item master table.            --
----------------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    20-Feb-2008
-- Mod Ref:     ModN115,116,117
-- Mod Details: New function TSL_CHK_ITEM_FIXEDMARGIN has been added.
----------------------------------------------------------------------------------------
-- Mod By     : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 20-Feb-2008
-- Mod Ref    : ModN115,116,117
-- Mod Details: New function TSL_GENERATE_MULTIPACK_ITEM has been added.
----------------------------------------------------------------------------------------
--
-- Mod By     : Wipro Enabler/Sundara Rajan                                                       --
-- Mod Date   : 27-Mar-2008                                                                       --
-- Mod Ref    : Mod N53                                                                           --
-- Mod Details: Modified Datatype of Parameters of the function TSL_GET_MU_IND.                   --
--              Modified Cursor C_GET_MU_IND of the function TSL_GET_MU_IND to get the value from --
--              ITEM_MASTER instead from ITEM_ATTRIBUTES.
--------------------------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    08-May-2008
-- Mod Ref:     ModN127
-- Mod Details: New function TSL_GET_ITEM_ATTRIB has been added.
----------------------------------------------------------------------------------------------------
-- Mod By     : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 8-May-2008
-- Mod Ref    : ModN138
-- Mod Details: New functions TSL_GET_BUYING_OFF_DESC and TSL_GET_COUNTY_DESC has been added.
----------------------------------------------------------------------------------------------
-- Mod By:      Bahubali Dongare Bahubali.Dongare@in.tesco.com
-- Mod Date:    12-May-2008
-- Mod Ref:     ModN111
-- Mod Details: New function TSL_GET_COMMON_IND has been added.
--------------------------------------------------------------------------------------------
-- Mod By     : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
-- Mod Date   : 10-JUN-2008
-- Mod Ref    : CR114
-- Mod Details: Added New Functions TSL_GET_CHILD_COUNT,TSL_GET_REQD_ATTRIBS,TSL_ITEM_EXISTS
--------------------------------------------------------------------------------------------
-- Mod By     : Sayali Bulakh sayali.bulakh@wipro.com
-- Mod Date   : 08-JULY-2008
-- Mod Ref    : For defect DefNBS7544 and DefNBS7620
-- Mod Details: Modified the function TSL_CHECK_ITEM_EXISTS
--------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 14-July-2008
-- Mod Ref    : N144
-- Mod Details: Added New Function TSL_CHECK_DUMMYTU_IND
--------------------------------------------------------------------------------------------
-- Mod By     : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 28-Jul-2008
-- Mod Ref    : DefNBS008033/CR114N112
-- Mod Details: New function UPDATE_PRIM_REF_ITEM has been added
----------------------------------------------------------------------------------------------------
-- Mod By     : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 5-Aug-2008
-- Mod Ref    : DefNBS008219
-- Mod Details: New function DELETE_ITEM_ATTRIBUTES has been added.
----------------------------------------------------------------------------------------
-- Fix By      : Wipro/Dhuraison Prince                                                           --
-- Fix Date    : 06-Aug-2008                                                                      --
-- Defect ID   : NBS00006802                                                                      --
-- Fix Details : Added two new functions TSL_INSERT_DEL_REC_INFO and TSL_DELETE_DESC_INFO to      --
--               cascade deletion of item descriptions from child(ren) item(s) when the same is   --
--               deleted from its parent item.                                                    --
----------------------------------------------------------------------------------------------------
-- Mod By     : Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
-- Mod Date   : 06-Aug-2007
-- Mod Ref    : DefNBS00008268
-- Mod Details: Modified functions TSL_INSERT_DEL_REC_INFO and TSL_DELETE_DESC_INFO to handle
--              delete cascade for range attributes
-----------------------------------------------------------------------------------------------------
-- Mod By     : Sayali Bulakh sayali.bulakh@wipro.com
-- Mod Date   : 04-JUNE-2008
-- Mod Ref    : DefNBS00006873
-- Mod Details: TSL_CHECK_ITEM_EXIST function modified to fix DefNBS00006873.
---------------------------------------------------------------------------------------------
-- Mod By:      Wipro/Bahubali, Bahubali.Dongare@in.tesco.com
-- Mod Date:    05-Jun-2008
-- Mod Ref:     Defect NBS00006962
-- Mod Details: New function TSL_GET_EPW has been added.
----------------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 13-Aug-2007
-- Mod Ref    : DefNBS00008445
-- Mod Details: Adding TSL_COMMON_L2_EXIST
---------------------------------------------------------------------------------------------
-- Mod By     : Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
-- Mod Date   : 01-Sep-2008
-- Mod Ref    : DefNBS008692
-- Mod Details: Modified function TSL_DELETE_DESC_INFO
-----------------------------------------------------------------------------------------
-- Mod By     : Satish BN, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 5-Sep-2008
-- Mod Ref    : DefNBS008703
-- Purpose:   : Added new function TSL_CHECK_OCC_MATCH_EAN
----------------------------------------------------------------------------------------------------
-- Mod By     : Murali Krishnan murali.natarjan@in.tesco.com
-- Mod Date   : 07-Oct-2008
-- Mod Ref    : DefNBS008542
-- Mod Details: Modified cursors in function TSL_VALIDATE_PACK_ITEM_ATTRIB to improve performance.
----------------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 18-Nov-2008
-- Mod Ref    : MrgNBS009715
-- Mod Details: Merge from 3.2 to 3.3
----------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 24-Nov-2008
-- Mod Ref    : CR187
-- Mod Details: Added one New function TSL_LOW_LVL_CODE_DESC
---------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 06-Jan-2009
-- Def Ref    : PrfNBS010460 and NBS00010460
-- Def Details: Code has modified for performance related issues in RIB.
---------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 21-Jan-2009
-- Mod Ref    : MrgNBS010972
-- Mod Details: Merge from 3.3a to 3.3b
----------------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 04-Feb-2009
-- Mod Ref    : Defect NBS00011072
-- Mod Details: Modified function DELETE_EAN
----------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 04-Mar-2009
-- Mod Ref    : CR171
-- Mod Details: Added new function TSL_UPDATE_MU_IND will update the MU
--              indicator of the input items.
-----------------------------------------------------------------------------------------
-- Mod By     : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 1-Apr-2009
-- Mod Ref    : DefNBS010471 and DefNBS010472
-- Mod Details: Modified TSL_GENERATE_MULTIPACK_ITEM function
----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Mod By     : Murali Krishnan murali.natarjan@in.tesco.com
-- Mod Date   : 03-Apr-2009
-- Mod Ref    : NBS00012155
-- Mod Details: The list children link on the item maintenance screen of TPNB is in red color.
-----------------------------------------------------------------------------------------------
--Mod By:      Murali, murali.natarajan@in.tesco.com
--Mod Date:    21-Apr-2009
--Mod Ref:     DefNBS012156
--Mod Details: Modified approval logic to not consider items in delete pending status
--             for approval.
---------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 15-May-2009
-- Mod Ref    : Defect NBS00012856
-- Mod Details: Modified function TSL_GET_REQD_ATTRIBS
-----------------------------------------------------------------------------------------
--Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    28-May-2009
--Mod Ref:     DefNBS013007
--Mod Details: Modified TSL_CHILD_ATTRIB_EXIST function.
---------------------------------------------------------------------------------------------
-- Mod By     : Satish B.N, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 09-Jun-2009
-- Mod Ref    : DefNBS013056
-- Mod Details: Modified cursors in TSL_PACK_EXIST and TSL_RET_EXIST functions
---------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 23-Jun-2009
-- Def Ref    : MrgNBS013573
-- Def Details: Modified the function TSL_GENERATE_MULTIPACK_ITEM, TSL_CHILD_ATTRIB_EXIST,
--              TSL_CHECK_RETAIL_OCC_BARCODE,TSL_PACK_EXIST,TSL_SUBTRAN_EXIST,TSL_RET_EXIST,
--              TSL_GCHILD_RET_EXIST,TSL_GET_REQD_ATTRIBS as a part of Merge.
---------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 23-Jun-2009
-- Mod Ref    : NBS00013345
-- Mod Details: Modified cursor in TSL_LOW_LVL_CODE_DESC and added a new function TSL_GET_ITEM_LVLCODE.
---------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 06-Jul-2009
-- Mod Ref    : NBS00012642
-- Mod Details: Applied oracle patch 7376952 to the function GET_BASE_COST_RETAIL
---------------------------------------------------------------------------------------------
-- Merged by   : Nitin Kumar, nitin.kumar@in.tesco.com
-- Date        : 10-Aug-2009
-- Desc        : Merge 3.3b to 3.4  and  3.4 to 3.5a
---------------------------------------------------------------------------------------------
-- Mod By     : Satish BN, satish.narasimhaiah@in.tesco.com
-- Mod Date   : 08-Oct-2009
-- Mod Ref    : DefNBS013960
-- Purpose:   : Added two new functions TSL_GET_CHILDREN_COUNT and TSL_CHK_SAME_ITEMTYPE_ITEM
---------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 21-Oct-2009
-- Mod Ref    : MrgNBS015080
-- Mod Details: Merge 3.3b Dev to 3.4Dev(Merged CR242,CR249,DefNBS014397(NBS00014402),
--              NBSDef014555,DefNBS014490,MrgNBS015067(NBSDef014851) and added
--              comments for DefNBS014490)
---------------------------------------------------------------------------------------------
-- Mod By     : Shweta Madnawat, shweta.mandawat@in.tesco.com
-- Mod Date   : 03-Aug-2009
-- Mod Ref    : CR242
-- Mod Details: Added two new functions TSL_CHECK_BARCODE_BRAND, TSL_UPDATE_BRAND_IND and
--              TSL_BARCODE_DELETED.
---------------------------------------------------------------------------------------------
-- Mod By     : Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
-- Mod Date   : 11-Aug-2009
-- Mod Ref    : DefNBS014397
-- Mod Details: Added new functions TSL_CHECK_ITEMA_DESC_EXIST
---------------------------------------------------------------------------------------------
-- Mod By     : Shweta Madnawat, shweta.mandawat@in.tesco.com
-- Mod Date   : 23-Aug-2009
-- Mod Ref    : NBSDef014555
-- Mod Details: Added funciton TSL_ITEM_FAMILY_DELETED  : This function will be used to check
--              if all the items of an item family are in
--              delete pending state. If the item passed is a style item then a check will be
--              made for TPNBs and TPNDs (simple) and if TPNB is passed check will be made for
--              all the barcodes. (EANs and OCCs).
---------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 15-Oct-2009
-- Mod Ref    : MrgNBS015067
-- Mod Details: Merge PrdDi to 3.3bDev(Merged NBSDef014851)
---------------------------------------------------------------------------------------------
-- Mod By     : Chandru, chandrashekaran.natarajan@in.tesco.com
-- Mod Date   : 23-Sep-2009
-- Mod Ref    : NBSDef014851
-- Mod Details: New function TSL_CHECK_MAND_ITATTR added to validate the all required
--              attributes added or not for the entire item structure
--------------------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 03-Aug-2009, 09-Sep-2009
-- Mod Ref    : CR236
-- Mod Details: Modified TSL_CHILD_ATTRIB_EXIST and added TSL_GET_EPW_COUNTRY functions.
--------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 31-Aug-2009
-- Def Ref    : CR236 (SI)
-- Def Details: Added new function TSL_SET_EPW.
--------------------------------------------------------------------------------------------------------
-- Mod By     : Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 23-Oct-2009
-- Mod Ref    : MrgNBS015130
-- Mod Details: Merge 3.4 Dev to 3.5b
--------------------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 24-Oct-2009
-- Mod Ref    : MrgNBS015130
-- Mod Details: Merge 3.4 Dev to 3.5b (Modified tsl_get_reqd_attribs to address an issue)
--------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 02-Nov-2009
-- Defect Id  : NBS00015205
-- Mod Details:  Added on extra country parameter in TSL_GET_ITEM_LVLCODE function
--------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 13-Nov-2009
-- Defect Id  : NBS00014668
-- Mod Details:  Added one new function TSL_GET_WORDCOUNT to fetch the number of words in a
--               sentence.This will be used on Item Children Form
---------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 19-Nov-2009
-- Defect Id  : NBS00015370
-- Mod Details: Modified the function TSL_CASCADE_BRAND_IND and added one extra parameter
--              for Brand Name
---------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 01-Dec-2009
-- Defect Id  : NBS00015504
-- Mod Details: Modified TSL_GET_REQD_ATTRIBS to revert the changes done for 12856. This is beacuse we will
--              passing L3 item or L2 pack to check the required attributes.
--              Modified TSL_GET_BARCODE_ATTRIB to get UK and ROI records as in Single Instance.
--------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 03-Dec-2009
-- Defect Id  : NBS00015526
-- Mod Details: Added one new function TSL_CHECK_VARIANT_QTY_UOM to compare the UOM values
--              with the Base item for variant item whose variant reason code is 'Y'/'C'.
---------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 04-Dec-2009
-- Mod Ref    : CR236A
-- Mod Details: Modified TSL_GET_REQD_ATTRIBS to validate both UK and ROI attributes.
---------------------------------------------------------------------------------------------
-- Mod By     : Naveen Babu.A, naveen.babu@in.tesco.com
-- Mod Date   : 02-Jan-2010
-- Mod Ref    : NBS00016163
-- Mod Details: Added a new function TSL_ITEM_DESC_CHECK for checking Effective-Date in the Description
--              tables of all Item and its children's when approving the item.
--------------------------------------------------------------------------------------------------------
--Mod By:      Sarayu Gouda sarayu.gouda@in.tesco.com
--Mod Date:    09-Feb-2010
--Mod Ref:     CR288
--Mod Details: Removed the Cr236 code change
-----------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari
-- Mod Date   : 23-Feb-2010
-- Mod Ref    : DefNBS016363
-- Mod Details: Modified TSL_GET_ITEM_INFO added input parameter I_consumer_unit
---------------------------------------------------------------------------------------------
-- Mod By        : Sarayu Gouda
-- Mod Date      : 05-Mar-2010
-- Mod Ref       : MrgNBS016549
-- Mod Details   : merge activity from 3.5d to 3.5b branches(The code is merged for CR288)
----------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 15-Feb-2010
-- Mod Ref    : PrfNBS00016258
-- Mod Details: Modified the cursor in TSL_CHECK_MAND_ITATTR function to improve the perfomance
--------------------------------------------------------------------------------------------------------
-- Mod By        : Sripriya
-- Mod Date      : 23-Mar-2010
-- Mod Ref       : DefNBS016673
-- Mod Details   : Modified TSL_CHECK_VARIANT_CONTENTS_QTY,added input parameter I_country for
--                 validating contents_qty_roi
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Mod By     : Shireen Sheosunker
-- Mod Date   : 24-Mar-2010
-- Mod Ref    : CR261
-- Mod Details: Modified  TSL_SET_EPW to add EPW END DATE and TSL_GET_EPW to return the EPW End Date
--------------------------------------------------------------------------------------------------------
-- Mod By     : Manikandan, Manikandan.varadhan@in.tesco.com
-- Mod Date   : 26-Mar-2010
-- Mod Ref    : MrgNBS016802
-- Mod Details: Merge 3.5e Dev to 3.5b (CR261 are merged)
-----------------------------------------------------------------------------------------------------------
-- Mod By        : Sripriya
-- Mod Date      : 14-Apr-2010
-- Mod Ref       : DefNBS016994
-- Mod Details   : Added a New function TSL_CHK_TESCO_BRAND_OCC to check if tesco branded OCC exist or not.
-----------------------------------------------------------------------------------------------------------
-- Mod By     : Naveen Babu.A, naveen.babu@in.tesco.com
-- Mod Date   : 20-Apr-2010
-- Mod Ref    : NBS00017157
-- Mod Details: Changed TSL_ITEM_DESC_CHECK function's UPDATE statements, added 'Effective_Date' field
--              in WHERE clause of all the update statements in this fucntion.
--------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 19-Apr-2010
-- Mod Ref    : MrgNBS017125(Merge 3.3prddi to 3.5b)
-- Mod Details: Merged NBS00016163 defect,merged another defect NBS00017157(which is done on 21-Apr-2010)
-----------------------------------------------------------------------------------------------------------
-- Mod By        : Sripriya
-- Mod Date      : 23-Apr-2010
-- Mod Ref       : DefNBS017154
-- Mod Details   : Modified TSL_CHK_TESCO_BRAND_OCC to check for non tesco branded OCC.
-----------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 24-Apr-2010
-- Mod Ref    : NBS00017188
-- Mod Details: Modified TSL_PACK_EXIST cursor
-----------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 28-Apr-2010
-- Mod Ref    : NBS00017234
-- Mod Details: Modified TSL_PACK_EXIST cursor
-----------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen
-- Mod Date   : 03-May-2010
-- Mod Ref    : DefNBS016887
-- Mod Details: Added new functions TSL_GET_EXT_RETAIL_INFO,TSL_DEL_EXT_RETAIL_INFO,TSL_UPD_UPLOAD_STATUS,
--              TSL_GET_EXT_ITEM_INFO to handle the uploading of retail info from RPS.
-----------------------------------------------------------------------------------------------------------
--Mod By:      Murali N, murali.natarajan@in.tesco.com
--Mod Date:    17-May-2010
--Mod Ref:     CR288b
--Mod Details: Added Function TSL_GET_ITEM_CTRY_IND
------------------------------------------------------------------------------------------------------
--Mod By:      Shireen Sheosunker, shireen.sheosunker@uk.tesco.com
--Mod Date:    20-May-2010
--Mod Ref:     CR261
--Mod Details: Changed function TSL_SET_EPW
------------------------------------------------------------------------------------------------------
--Mod By:      Murali N, murali.natarajan@in.tesco.com
--Mod Date:    21-May-2010
--Mod Ref:     NBS00017540
--Mod Details: Modifed  Function TSL_GET_STYLE_ITEM to fetch L1 style.
------------------------------------------------------------------------------------------------------
--Mod By:      Shireen Sheosunker, shireen.sheosunker@uk.tesco.com
--Mod Date:    21-May-2010
--Mod Ref:     Defect 17565
--Mod Details: Changed function TSL_GET_EPW_END_DATE to get both(UK and ROI) end dates for epw
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Mod By     : Sri Ranjitha B, Sriranjitha.Bhagi@in.tesco.com
-- Mod Date   : 19-May-2010
-- Mod Ref    : NBS00017468
-- Mod Details: Changed CHECK_DESC function for validating special characters
--------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen
-- Mod Date   : 17-Jun-2010
-- Mod Ref    : DefNBS017904
-- Mod Details: Added a new function TSL_PARENT_UPD_INFO to handle the uploading of retail info from RPS
--              at TPNA level.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 29-July-2010
-- Mod Ref    : CR347
-- Mod Details: Added a new function TSL_CHK_ZERO_PLUS_EAN to check whether an EAN has a corresponding
--              OCC (0 + EAN) or vice versa. Modified the function TSL_CHECK_RETAIL_OCC_BARCODE to meet
--              CR347 requirements
-------------------------------------------------------------------------------------------------------
-- Mod By     : Nishant Gupta
-- Mod Date   : 19-Jul-2010
-- Mod Ref    : CR288d.
-- Mod Details: Modified TSL_SET_EPW function.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen
-- Mod Date   : 18-Jun-2010
-- Mod Ref    : DefNBS017896
-- Mod Details: Modified the function TSL_GET_EXT_ITEM_INFO.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari
-- Mod Date   : 28-Jul-2010
-- Mod Ref    : MrgNBS018480
-- Mod Details: No need to merge as files are identical(which is already backported (DefNBS017896))
-------------------------------------------------------------------------------------------------------
--Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
--Mod Date   : 05-Aug-2010
--Mod Ref    : MrgNBS018606(Merge 3.5f to 3.5g)
--Mod Details: Merged DefNBS017896, MrgNBS018480
------------------------------------------------------------------------------------------------------
-- Mod By     : Sripriya
-- Mod Date   : 10-Aug-2010
-- Mod Ref    : DefNBS018653,DefNBS018613,DefNBS18707.
-- Mod Details: Modified the function TSL_CHILD_ATTRIB_EXIST ,TSL_CHECK_RETAIL_OCC_BARCODE.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Maheshwari Appuswamy
-- Mod Date   : 10-Aug-2010
-- Mod Ref    : DefNBS00018582
-- Mod Details: Modified the function TSL_CHECK_RETAIL_OCC_BARCODE.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 09-Sep-2010
-- Mod Ref    : NBS00019082
-- Mod Details: Modified TSL_CASCADE_EPW to cascade EPW indicator only when authorization country is
--              same for passed item and it's children and hierarchy and changed allignment of function.
--              That is if items(children,packs) become dual then only it will cascade to children
-----------------------------------------------------------------------------------------------------------
-- Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Date   : 16-Sep-2010
-- Mod Ref    : MrgNBS019188, Merge from 3.5g to 3.5b
-- Mod Details: Merged Changes for CR347, CR288d, MrgNBS018606, DefNBS018653,DefNBS018613,
--              DefNBS18707, DefNBS00018582,NBS00019082
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
--MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com begin
-- Mod By     : Maheshwari Appuswamy
-- Mod Date   : 18-Aug-2010
-- Mod Ref    : CR354
-- Mod Details: Modified for CR354.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen
-- Mod Date   : 06-Sep-2010
-- Mod Ref    : DefNBS018890
-- Mod Details: Modified the function TSL_COPY_COMPONENT_ATTRIB for CR354 cascading logic.
--MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com end
-------------------------------------------------------------------------------------------------------
-- Mod BY     : Accenture/Sreenath Madhavan, Sreenath.Madavan@in.tesco.com
-- Mod Date   : 09-Nov-2010
-- Mod Ref    : CR296
-- Mod Details: Added function TSL_GET_FIRST_L2
-------------------------------------------------------------------------------------------------------
-- Mod BY     : Phil Noon phil.noon@uk.tesco.com
-- Mod Date   : 21-Dec-2010
-- Mod Ref    : DefNBS020239
-- Mod Details: Amended tsl_copy_component_attrib to avoid selecting no columns in a SELECT
-------------------------------------------------------------------------------------------------------------
-- CR259, 25-Nov-2010, Merlyn Mathew, merlyn.mathew@in.tesco.com
-------------------------------------------------------------------------------------------------------------
-- CR259, 15-Dec-2010, Sanju Natarjan, Sanju.Natarajan@in.tesco.com
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Ankush, ankush.khanna@in.tesco.com
-- Mod Date   : 25-Dec-2010
-- Mod Ref    : MrgNBS020155
-- Mod Details: Merge from 3.5b to 3.5h branches
-------------------------------------------------------------------------------------------------------------
-- MrgNBS021583, Ravi Nagaraju, ravi.nagaraju@in.tesco.com 16-Feb-2011 Begin
-- Mod By        : Sripriya
-- Mod Date      : 28-Jan-2011
-- Mod Ref       : DefNBS020698
-- Mod Details   : Added a New function TSL_GET_EXT_UPD_IND.
-- MrgNBS021583, Ravi Nagaraju, ravi.nagaraju@in.tesco.com 16-Feb-2011 End
-----------------------------------------------------------------------------------------------------------
-- Mod By       : Ravi Nagaraju, ravi.nagaraju@in.tesco.com
-- Mod Date     : 09-Feb-2011
-- Mod Ref      : CR254
-- Mod Details  : Modified TSL_TARIFF_CODE_DESC function to correct the O_error_message
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Ravi Nagaraju, ravi.nagaraju@in.tesco.com
-- Mod Date   : 16-Feb-2011
-- Mod Ref    : MrgNBS021583
-- Mod Desc   : Merge from 3.5 PrdSi to 3.5b branches
--------------------------------------------------------------------------------------
-- Mod By     : Vinutha Raju, vinutha.raju@in.tesco.com
-- Mod Date   : 23-Feb-2011
-- Mod Ref    : DefNBS021403
-- Mod Desc   : Added new function TSL_GET_ACTIVE_CHILD_COUNT to get count of child items which
--              are not in daily purge
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Mod By     : Parvesh parveshkumar.rulhan@in.tesco.com
-- Mod Date   : 14-Mar-2011
-- Mod Ref    : DefNBS021869
-- Mod Desc   : Modified TSL_GET_UOMS_CATCHWEIGHT function's signature.
--------------------------------------------------------------------------------------
-- Mod By        : Sripriya Karanam
-- Mod Date      : 07-Apr-2011
-- Mod Ref       : DefNBS022246
-- Mod Details   : Modified the function TSL_CHK_SELL_BY_TYPE.
--------------------------------------------------------------------------------------
-- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
-------------------------------------------------------------------------------------------------------------
-- Mod By        : Nandini Mariyappa
-- Mod Date      : 18-Mar-2011
-- Mod Ref       : MrgNBS021914(Merge 3.5j to 3.5b)
-- Mod Details   : Merged the CR382b changes.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Veena Nanjundaiah, veena.nanjundaiah@in.tesco.com
-- Mod Date   : 11-Feb-2011
-- Mod Ref    : CR382b
-- Mod Desc   : Modified to add new function TSL_DELETE_ISS_DESC.
--            : This new function will delete records from table tsl_itemdesc_iss
-------------------------------------------------------------------------------------------------------------
-- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
-------------------------------------------------------------------------------------------------------------
-- Mod By        : Sripriya
-- Mod Date      : 31-May-2011
-- Mod Ref       : DefNBS022780
-- Mod Details   : Modified function GET_TSL_ITEM_DEFAULTS.
-----------------------------------------------------------------------------------------------------------
-- Mod By       : Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com
-- Mod Date     : 06-Jun-11
-- Mod Ref      : CR400
-- Mod Details  : Added following new new functions:
--                1. TSL_GET_SELLING_PRICE
--                2. TSL_VALIDATE_CONT_QTY_UOM
--                3. TSL_GET_CONT_QTY_UOM
--                4. TSL_GET_UNIT_QTY
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Gurutej.K
-- Mod Date   : 22-Jun-2011
-- Mod Ref    : NBS00023046
-- Mod Desc   : Modified to add new procedure ITEM_ATTRIB_SINGLE_LOCK.
--            : This new function will take care of locking sessions.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Ankush,Ankush.khanna@in.tesco.com
-- Mod Date   : 23-June-2011
-- Mod Ref    : DefNBS023046(NBS00023046).
-- Mod Details: Record lock exception added in TSL_SET_EPW(),TSL_ITEM_DESC_CHECK(),TSL_DEL_EXT_RETAIL_INFO
--            : and TSL_UPD_UPLOAD_STATUS()
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com
-- Mod Date   : 30-Jun-2011
-- Mod Ref    : NBS00023046
-- Mod Desc   : Modified to procedure ITEM_ATTRIB_SINGLE_LOCK.
--            : This new function will lock the item level records.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com
-- Mod Date   : 07-Jul-2011
-- Mod Ref    : CR400/DefNBS023188
-- Mod Details: To change column name and size of table tsl_unit_qty_map as per FD.
-------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- Mod By     : Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com
-- Mod Date   : 11-Jul-2011
-- Def Ref    : DefNBS023213
-- Def Details: Locking issue
--------------------------------------------------------------------------------------------------
-------------------------------------------------------------
--Mod by     : Gurutej.K, gurutej.kunjibettu@in.tesco.com
--Mod date   : 11-Aug-2011
--Mod        : MrgNBS023381
--Mod ref    : Merge from PrdSi to 3.5b(DefNBS023213)
-------------------------------------------------------------
-- Mod By     : shweta.madnawat@in.tesco.com
-- Mod Date   : 24-Oct-2011
-- Mod Ref    : CR434
-- Mod Desc   : Added new functions tsl_get_restrict_pcev, tsl_get_multipack_qty, tsl_get_linked_single,
--              tsl_valid_price, tsl_check_valid_single for cr434
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 02-Nov-2011
-- Mod Ref    : CR434
-- Mod Desc   : Added new functions TSL_INS_LINK_MP_SNGL, TSL_IS_LINK_EXISTS, TSL_DELETE_LINK and
--              TSL_CHECK_VALID_MULTI for cr434.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 21-Nov-2011
-- Mod Ref    : DefNBS023962
-- Mod Desc   : Modified function TSL_VALID_PRICE.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 23-Nov-2011
-- Mod Ref    : DefNBS023975
-- Mod Desc   : Modified function TSL_VALID_PRICE.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 23-Nov-2011
-- Mod Ref    : DefNBS023978
-- Mod Desc   : Modified function TSL_DELETE_LINK_MP.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 15-Dec-2011
-- Mod Ref    : DefNBS024054
-- Mod Desc   : Modified function TSL_CHECK_VALID_MULTI.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 06-Feb-2012
-- Mod Ref    : DefNBS024293
-- Mod Desc   : Added function TSL_CHECK_MP_QTY, which will check whether TPNA and all of TPNBS of
--              TPNA have same Multipack Quantity..
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P/Usha P,bharagavi.pujari@in.tesco.com/usha.patil@in.tesco.com
-- Mod Date   : 01-Jan-2012
-- Mod Ref    : N169/CR373
-- Mod Detail : Modified TSL_CHECK_RETAIL_OCC_BARCODE and added new function
--              TSL_INSERT_PICKLIST_BME_STATUS to insert records into tsl_pickist_status table with action type as 'B'
--              if there is no picklist approval happened and no barcode M/E/O(action type 'B')
--              record is present in the table on the same business day.
--              Added TSL_PICKLIST_ITEM to check whether item is picklist or not.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 08-Aug-2012
-- Mod Ref    : MrgNBS025284 (From PrdSi to 3.5b)
-- Mod Desc   : Merged DefNBS024857, DefNBS024857a, DefNBS024857b/PM015114 defect.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Vinutha R, vinutha.raju@in.tesco.com
-- Mod Date   : 02-May-2012
-- Mod Ref    : DefNBS024857/PM015114
-- Mod Desc   : MODIFIED the cursors, C_GET_RSP_SINGLE and C_GET_MIN_RSP in TSL_VALID_PRICE
--            : function to fetch the min (selling_retail) of only the the currently effective
--            : and future dated price in the restricted price event promo zone.
--------------------------------------------------------------------------------------
-- Mod By     : Vinutha R, vinutha.raju@in.tesco.com
-- Mod Date   : 18-May-2012
-- Mod Ref    : DefNBS024857a/PM015114
-- Mod Desc   : MODIFIED the cursors, C_GET_RSP_SINGLE and C_GET_MIN_RSP in TSL_VALID_PRICE
--            : function to fetch the min (selling_retail,clear_retail,simple_promo_retail,complex_promo_retail)
--              of only the the currently effective
--            : and future dated price in the restricted price event promo zone.
--------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 24-May-2012
-- Mod Ref    : DefNBS024857b/PM015114
-- Mod Desc   : Modified the function TSL_VALID_PRICE, added cursors C_GET_MIN_RSP_RZFR to find
--              the minimum selling retail for multipack and cursor C_GET_RSP_SINGLE_RZFR to find
--              the maximum selling retail for single level2 item.
--------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 12-Oct-2012
-- Mod Ref    : DefNBS025514\PM017007
-- Mod Desc   : Modified function TSL_CHECK_MAND_ITATTR to not show the missing attributes message for if launch date
--              is missimg for Variant and/or Variant' pack.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P/Usha P,bharagavi.pujari@in.tesco.com/usha.patil@in.tesco.com
-- Mod Date   : 01-Jan-2012
-- Mod Ref    : MrgNBS025514
-- Mod Detail : Merged DefNBS025514\PM017007(3.7 to 3.5b merge)
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P/Usha P,bharagavi.pujari@in.tesco.com/usha.patil@in.tesco.com
-- Mod Date   : 15-May-2013
-- Mod Ref    : MrgNBS025693
-- Mod Detail : Merged DefNBS025693a\PM015327 from 3.5b to PRDSI
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 06-Feb-2013
-- Mod Ref    : DefNBS025693a
-- Mod Detail : Modified TSL_UPDATE_BRAND_IND to update the brand value for TPNA item as NULL when
--              Brand indication of barcode and TPNA are not same.
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Mod By     : Smitha Ramesh A
-- Mod Date   : 23-July-2013
-- Mod Ref    : CR480
-- Mod Detail : Modified TSL_SET_PRIMARY_REF as part of CR 480
---------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Mod by     : V Manikandan
-- Mod ref    : MrgNBS26492
-- Mod Desc   : The PM020648 have merged from 3.5b to PRDSi.
---------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Mod By:      Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com
-- Mod Date:    23-Oct-2013
-- Def Ref:     PM020648
-- Def Details: Modified the functions
----------------------------------------------------------------------------------------------------
FUNCTION NEXT_ITEM (O_error_message    OUT VARCHAR2,
                    O_item          IN OUT item_master.item%TYPE)
RETURN BOOLEAN IS
   L_wrap_sequence_number   item_master.item%TYPE;
   L_check_digit            NUMBER(1);
   L_first_time             VARCHAR2(3) := 'Yes';
   L_dummy                  VARCHAR2(1);
   L_check_digit_ind        system_options.check_digit_ind%TYPE;

   cursor C_CHECK_DIGIT is
      select check_digit_ind
        from system_options;

   cursor C_EXISTS is
      select 'x'
        from item_master
       where item = O_item;

   cursor C_ITEM_SEQUENCE is
         select item_sequence.NEXTVAL
           from sys.dual;

   cursor C_ITEM_CHKDIG_SEQUENCE is
         select item_chkdig_sequence.NEXTVAL
           from sys.dual;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_DIGIT',
                    'system_options',
                    NULL);
   open C_CHECK_DIGIT;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_DIGIT',
                    'system_options',
                    NULL);
   fetch C_CHECK_DIGIT into L_check_digit_ind;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_DIGIT',
                    'system_options',
                    NULL);
   close C_CHECK_DIGIT;
   LOOP
      if L_check_digit_ind ='N' then
         SQL_LIB.SET_MARK('OPEN',
                          'item_sequence.NEXTVAL',
                          'sys.dual',
                          NULL);
         open C_ITEM_SEQUENCE;
         ---
         SQL_LIB.SET_MARK('FETCH',
                          'item_sequence.NEXTVAL',
                          'sys.dual',
                          NULL);
         fetch C_ITEM_SEQUENCE into O_item;
         ---
         SQL_LIB.SET_MARK('CLOSE',
                          'item_sequence.NEXTVAL',
                          'sys.dual',
                          NULL);
         close C_ITEM_SEQUENCE;
         L_check_digit := 0;
              --  Even though not doing check digit logic, we still want
              --  to do wrap sequence logic so we'll set L_check_digit
              --  = 0 to get past the if statement a few lines down
      elsif L_check_digit_ind ='Y' then
         SQL_LIB.SET_MARK('OPEN',
                          'item_chkdig_sequence.NEXTVAL',
                          'sys.dual',
                          NULL);
         open C_ITEM_CHKDIG_SEQUENCE;
         ---
         SQL_LIB.SET_MARK('FETCH',
                          'item_chkdig_sequence.NEXTVAL',
                          'sys.dual',
                          NULL);
         fetch C_ITEM_CHKDIG_SEQUENCE into O_item;
         ---
         SQL_LIB.SET_MARK('CLOSE',
                          'item_chkdig_sequence.NEXTVAL',
                          'sys.dual',
                          NULL);
         close C_ITEM_CHKDIG_SEQUENCE;
         CHKDIG_ADD(O_item, L_check_digit,'Y');
      end if;
      if (L_check_digit >= 0) then
         if L_first_time = 'Yes' then
            L_wrap_sequence_number := O_item;
            L_first_time := 'No';
         elsif O_item = L_wrap_sequence_number then
            O_error_message := 'Fatal error - no available item numbers';
            return FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('OPEN',
                          'C_EXISTS',
                          'item_master',
                          NULL);
         open C_EXISTS;
         ---
         SQL_LIB.SET_MARK('FETCH',
                          'C_EXISTS',
                          'item_master',
                          NULL);
         fetch C_EXISTS into L_dummy;
         if (C_EXISTS%NOTFOUND) then
           ---
           SQL_LIB.SET_MARK('CLOSE',
                            'C_EXISTS',
                            'item_master',
                            NULL);
            close C_EXISTS;
            exit;
         end if;
         ---
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EXISTS',
                          'item_master',
                          NULL);
         close C_EXISTS;
      end if;
   END LOOP;
   return TRUE;
EXCEPTION
    WHEN OTHERS THEN
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              'ITEM_ATTRIB_SQL.NEXT_ITEM',
                                              to_char(SQLCODE));
        return FALSE;
END NEXT_ITEM;
--------------------------------------------------------------------
FUNCTION INV_STATUS_DESC(O_error_message    IN OUT VARCHAR2,
                         I_inv_status       IN   NUMBER,
                         O_desc             IN OUT VARCHAR2)
RETURN BOOLEAN IS
   cursor C_ATTRIB is
   select inv_status_desc
     from inv_status_types
    where inv_status = I_inv_status;
BEGIN
   SQL_LIB.SET_MARK('OPEN' , 'C_ATTRIB', 'INV_STATUS_TYPES', to_char(I_inv_status));
   open C_ATTRIB;
   SQL_LIB.SET_MARK('FETCH' , 'C_ATTRIB', 'INV_STATUS_TYPES', to_char(I_inv_status));
   fetch C_ATTRIB into O_desc;
   if C_ATTRIB%NOTFOUND then
      O_error_message := sql_lib.create_msg('INV_STATUS',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE' , 'C_ATTRIB', 'INV_STATUS_TYPES', to_char(I_inv_status));
      close C_ATTRIB;
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE' , 'C_ATTRIB', 'INV_STATUS_TYPES', to_char(I_inv_status));
   close C_ATTRIB;
   if LANGUAGE_SQL.TRANSLATE(O_desc,
                             O_desc,
                             O_error_message) = FALSE then
      RETURN FALSE;
   end if;
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.INV_STATUS_DESC',
                                            to_char(SQLCODE));
   RETURN FALSE;
END INV_STATUS_DESC;
---------------------------------------------------------------------------------------------
FUNCTION GET_MERCH_HIER( O_error_message IN OUT VARCHAR2,
                         I_item          IN     item_master.item%TYPE,
                         O_dept          IN OUT item_master.dept%TYPE,
                         O_class         IN OUT item_master.class%TYPE,
                         O_subclass      IN OUT item_master.subclass%TYPE)
RETURN BOOLEAN IS
   L_program    VARCHAR2(64)        := 'ITEM_ATTRIB_SQL.GET_MERCH_HIER';
   cursor C_MERCH_HIER is
      select dept,
             class,
             subclass
        from item_master
       where item = I_item;
BEGIN
   ---
   SQL_LIB.SET_MARK('OPEN' , 'C_MERCH_HIER', 'ITEM_MASTER', I_item);
   open C_MERCH_HIER;
   ---
   SQL_LIB.SET_MARK('FETCH' , 'C_MERCH_HIER', 'ITEM_MASTER', I_item);
   fetch C_MERCH_HIER into O_dept,
                           O_class,
                           O_subclass;
   ---
   if C_MERCH_HIER%notfound then
      SQL_LIB.SET_MARK('CLOSE' , 'C_MERCH_HIER', 'ITEM_MASTER', I_item);
      close C_MERCH_HIER;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      ---
      /*O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             null,
                                             null,
                                             null);*/
      --RIB error message enhancement start
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             'item='||I_item,
                                             null,
                                             null);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE' , 'C_MERCH_HIER', 'ITEM_MASTER', I_item);
   close C_MERCH_HIER;
   return TRUE;

EXCEPTION
   when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                          SQLERRM,
                                          L_program,
                                          NULL);
        RETURN FALSE;
END GET_MERCH_HIER;
---------------------------------------------------------------------------------------------
FUNCTION GET_BASE_COST_RETAIL(O_error_message     IN OUT    VARCHAR2,
                              O_unit_cost_prim            IN OUT  ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                              O_standard_unit_retail_prim IN OUT  ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE,
                              O_standard_uom_prim         IN OUT  ITEM_MASTER.STANDARD_UOM%TYPE,
                              O_selling_unit_retail_prim  IN OUT  ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE,
                              O_selling_uom_prim          IN OUT  ITEM_ZONE_PRICE.SELLING_UOM%TYPE,
                              I_item                      IN      ITEM_SUPPLIER.ITEM%TYPE,
                              I_calc_type                 IN      VARCHAR2)
RETURN BOOLEAN IS
   L_program                    VARCHAR2(64) := 'ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL';
   L_return_code                NUMBER;
   L_error_msg                  VARCHAR2(255);
   L_zone_group_id              PRICE_ZONE.ZONE_GROUP_ID%TYPE;
   L_zone_id                    PRICE_ZONE.ZONE_ID%TYPE;
   L_unit_retail_zon            ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE;
   L_unit_cost_sup              ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_supplier                   ITEM_SUPPLIER.SUPPLIER%TYPE;
   L_orderable_ind              ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_sellable_ind               ITEM_MASTER.SELLABLE_IND%TYPE;
   L_pack_no                    ITEM_MASTER.ITEM%TYPE;
   L_dept                       ITEM_MASTER.DEPT%TYPE;
   L_class                      ITEM_MASTER.CLASS%TYPE;
   L_subclass                   ITEM_MASTER.SUBCLASS%TYPE;
   L_cost_zone_group_id         ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE;
   L_contains_inner_ind         ITEM_MASTER.CONTAINS_INNER_IND%TYPE;
   L_order_as_type              ITEM_MASTER.ORDER_AS_TYPE%TYPE;
   L_pack_type                  ITEM_MASTER.PACK_TYPE%TYPE;
   L_cost                       ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_pack_ind                   ITEM_MASTER.PACK_IND%TYPE;
   L_multi_unit_retail_zon      ITEM_ZONE_PRICE.MULTI_UNIT_RETAIL%TYPE;
   L_multi_selling_uom_zon      ITEM_ZONE_PRICE.ITEM%TYPE;
   L_multi_units_zon            ITEM_ZONE_PRICE.SELLING_UOM%TYPE;
   L_standard_class             UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor                ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_selling_unit_retail_prim   ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE;

   L_item_xform_ind             ITEM_MASTER.ITEM_XFORM_IND%TYPE;
   -- 06-Jul-2009   TESCO HSC/Bhargavi Pujari   Def# NBS012642 Begin
   -- Applied oracle patch 7376952
   L_pricing_level              PRICE_ZONE_GROUP.PRICING_LEVEL%TYPE;
   -- 06-Jul-2009   TESCO HSC/Bhargavi Pujari   Def# NBS012642 End

   ---
   cursor C_PACK_SKU IS
      select item,
             qty
        from v_packsku_qty
       where pack_no = I_item;


   cursor C_ITEM IS
      select item_xform_ind
        from item_master
       where item = I_item;

   -- 06-Jul-2009   TESCO HSC/Bhargavi Pujari   Def# NBS012642 Begin
   -- Applied oracle patch 7376952
   cursor C_PRICING_LEVEL IS
      select pricing_level
        from price_zone_group
       where zone_group_id = L_zone_group_id;

   cursor C_ZONE IS
      select zone_id
        from price_zone_group_store
       where store = L_zone_id;
   -- 06-Jul-2009   TESCO HSC/Bhargavi Pujari   Def# NBS012642 End


BEGIN

   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;


   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM',
                    'item_master',
                    'I_item: ' || I_Item);
   open C_ITEM;

   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM',
                    'item_master',
                    'I_item: ' || I_Item);
   fetch C_ITEM into L_item_xform_ind;

   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM',
                    'item_master',
                    'I_item: ' || I_Item);
   close C_ITEM;

   if (I_calc_type is NULL) or (I_calc_type = 'C') then
      if (L_orderable_ind = 'N'and L_pack_ind = 'Y') then
         O_unit_cost_prim := 0;
         ---
         SQL_LIB.SET_MARK('FETCH', 'C_PACK_SKU', 'V_PACKSKU_QTY', 'PACK_NO: '||I_item);
         FOR rec_in IN C_PACK_SKU LOOP
            ---get primary supplier cost for each sku
            if SUPP_ITEM_SQL.GET_PRI_SUP_COST(O_error_message,
                                              L_supplier,
                                              L_cost,
                                              rec_in.item,
                                              NULL) = FALSE then
               return FALSE;
            end if;
            ---
            if L_supplier is NOT NULL then
               ---convert primary supplier cost to the primary currency
               if not CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                       L_supplier,
                                                       'V',
                                                       NULL,
                                                       NULL,
                                                       NULL,
                                                       NULL,
                                                       L_cost,
                                                       L_cost,
                                                       'C',NULL,NULL) then
                  return FALSE;
               end if;
               O_unit_cost_prim := O_unit_cost_prim + (L_cost * rec_in.qty);
            end if;
         END LOOP;
      else
         -- Get primary supplier's cost
         if not SUPP_ITEM_SQL.GET_PRI_SUP_COST(O_error_message,
                                               L_supplier,
                                               L_unit_cost_sup,
                                               I_item,
                                               NULL) then
            return FALSE;
         end if;
         if L_unit_cost_sup is NOT NULL then
            -- Convert cost from supplier's currency to primary currency
            if not CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                    L_supplier,
                                                    'V',
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    L_unit_cost_sup,
                                                    O_unit_cost_prim,
                                                    'C',
                                                    NULL,
                                                    NULL) then
               return FALSE;
            end if;
         end if;
      end if;
   end if;
   if (I_calc_type is NULL) or (I_calc_type = 'R') then

      if (L_orderable_ind = 'Y') and
         (L_item_xform_ind = 'Y') then
         if ITEM_XFORM_SQL.CALCULATE_RETAIL(O_error_message,
                                            I_item,
                                            NULL,
                                            L_unit_retail_zon) = FALSE then
            return FALSE;
         end if;
         O_selling_unit_retail_prim := L_unit_retail_zon;
         O_standard_unit_retail_prim := L_unit_retail_zon;

      elsif (L_sellable_ind = 'N') and
            (L_pack_ind = 'N') then
          O_selling_unit_retail_prim := 0;
          O_standard_unit_retail_prim := 0;
      elsif (L_sellable_ind = 'N') and
            (L_pack_ind = 'Y') then

         O_selling_unit_retail_prim := 0;
         O_standard_unit_retail_prim := 0;

         if not ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                 O_standard_uom_prim,
                                                 L_conv_factor,
                                                 L_standard_class,
                                                 I_item,
                                                 NULL) then
               return FALSE;
          else
            O_selling_uom_prim := O_standard_uom_prim;
         end if;
        else
         -- Get base retail
         if not PRICING_ATTRIB_SQL.GET_BASE_ZONE_RETAIL(O_error_message,
                                                        L_zone_group_id,
                                                        L_zone_id,
                                                        L_unit_retail_zon,
                                                        O_standard_uom_prim,
                                                        L_selling_unit_retail_prim,
                                                        O_selling_uom_prim,
                                                        L_multi_units_zon,
                                                        L_multi_unit_retail_zon,
                                                        L_multi_selling_uom_zon,
                                                        I_item) then
            return FALSE;
         end if;
         if L_unit_retail_zon is NOT NULL then
   -- 06-Jul-2009   TESCO HSC/Bhargavi Pujari   Def# NBS012642 Begin
   -- Applied oracle patch 7376952
            SQL_LIB.SET_MARK('OPEN',
                             'C_PRICING_LEVEL',
                             'price_zone_group',
                             'L_zone_group_id: ' || L_zone_group_id);
            open C_PRICING_LEVEL;

            ---
            SQL_LIB.SET_MARK('FETCH',
                             'C_PRICING_LEVEL',
                             'price_zone_group',
                             'L_zone_group_id: ' || L_zone_group_id);
            fetch C_PRICING_LEVEL into L_pricing_level;

            ---
            SQL_LIB.SET_MARK('CLOSE',
                             'C_PRICING_LEVEL',
                             'price_zone_group',
                             'L_zone_group_id: ' || L_zone_group_id);
            close C_PRICING_LEVEL;
            ---

            if ( L_pricing_level = 'Z' OR L_pricing_level = 'C' ) then

               SQL_LIB.SET_MARK('OPEN',
                                'C_ZONE',
                                'price_zone_group_store',
                                'L_zone_id: ' || L_zone_id);
               open C_ZONE;

               SQL_LIB.SET_MARK('FETCH',
                                'C_ZONE',
                                'price_zone_group_store',
                                'L_zone_id: ' || L_zone_id);
               fetch C_ZONE into L_zone_id;

               ---
               SQL_LIB.SET_MARK('CLOSE',
                                'C_ZONE',
                                'price_zone_group_store',
                                'L_zone_id: ' || L_zone_id);
               close C_ZONE;
            end if;
   -- 06-Jul-2009   TESCO HSC/Bhargavi Pujari   Def# NBS012642 End
            -- Convert retail to primary currency
            if not CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                    L_zone_id,
                                                    'Z',
                                                    L_zone_group_id,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    L_unit_retail_zon,
                                                    O_standard_unit_retail_prim,
                                                    'R',
                                                    NULL,
                                                    NULL) then
               return FALSE;
            end if;
             if not CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                    L_zone_id,
                                                    'Z',
                                                    L_zone_group_id,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    L_selling_unit_retail_prim,
                                                    O_selling_unit_retail_prim,
                                                    'R',
                                                    NULL,
                                                    NULL) then
               return FALSE;
            end if;
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

END GET_BASE_COST_RETAIL;
---------------------------------------------------------------------------------------------
FUNCTION GET_BASE_COST_RETAIL(O_error_message             IN OUT  VARCHAR2,
                              O_unit_cost_prim            IN OUT  ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                              O_standard_unit_retail_prim IN OUT  ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE,
                              O_standard_uom_prim         IN OUT  ITEM_MASTER.STANDARD_UOM%TYPE,
                              O_selling_unit_retail_prim  IN OUT  ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE,
                              O_selling_uom_prim          IN OUT  ITEM_ZONE_PRICE.SELLING_UOM%TYPE,
                              I_item                      IN      ITEM_SUPPLIER.ITEM%TYPE)
                              RETURN BOOLEAN IS
   L_calc_type   VARCHAR2(1) := NULL;
   L_program     VARCHAR2(64) := 'ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL';
BEGIN
   if not GET_BASE_COST_RETAIL(O_error_message,
                               O_unit_cost_prim,
                               O_standard_unit_retail_prim,
                               O_standard_uom_prim,
                               O_selling_unit_retail_prim,
                               O_selling_uom_prim,
                               I_item,
                               L_calc_type) then
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
END GET_BASE_COST_RETAIL;
-----------------------------------------------------------------------------
FUNCTION CONSIGNMENT_ITEM(O_error_message IN OUT VARCHAR2,
                          I_item          IN     ITEM_SUPPLIER.ITEM%TYPE,
                          O_consignment   IN OUT BOOLEAN)
RETURN BOOLEAN IS
   L_dummy VARCHAR2(1);
   cursor C_ITEM_SUPPLIER is
      select 'x'
        from item_supplier
       where item_supplier.item = I_item
         and primary_supp_ind = 'Y'
         and consignment_rate is not NULL;
BEGIN
   O_consignment := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM_SUPPLIER',
                    'ITEM_SUPPLIER', 'ITEM:  '||I_item);
   open C_ITEM_SUPPLIER;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM_SUPPLIER',
                    'ITEM_SUPPLIER', 'ITEM:  '||I_item);
   fetch C_ITEM_SUPPLIER into L_dummy;
   if C_ITEM_SUPPLIER%FOUND then
      O_consignment := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_SUPPLIER',
                    'ITEM_SUPPLIER', 'ITEM:  '||I_item);
   close C_ITEM_SUPPLIER;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.CONSIGNMENT_ITEM',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END CONSIGNMENT_ITEM;
------------------------------------------------------------------------
FUNCTION GET_ZONE_GROUP(O_error_message IN OUT VARCHAR2,
                        O_zone_group_ID IN OUT ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE,
                        I_item          IN     ITEM_ZONE_PRICE.ITEM%TYPE)
RETURN BOOLEAN IS

L_system_ind  VARCHAR2(1);

   cursor C_ITEM is
      select retail_zone_group_id
        from item_master
       where item = I_item;

BEGIN

      SQL_LIB.SET_MARK('OPEN','C_ITEM','ITEM_MASTER','item:'||I_item);
      open C_ITEM;
      SQL_LIB.SET_MARK('FETCH','C_ITEM','ITEM_MASTER','item:'||I_item);
      fetch C_ITEM into O_zone_group_id;
      if C_ITEM%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                                null,
                                                null,
                                                null);
         SQL_LIB.SET_MARK('CLOSE','C_ITEM','ITEM_MASTER','item:'||I_item);
         close C_ITEM;
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_ITEM','ITEM_MASTER','item:'||I_item);
      close C_ITEM;
      return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_ZONE_GROUP',
                                            TO_CHAR(SQLCODE));
   RETURN FALSE;
END GET_ZONE_GROUP;
---------------------------------------------------------------------------
FUNCTION GET_COST_ZONE_GROUP(O_error_message           IN OUT VARCHAR2,
                             O_cost_zone_group_id      IN OUT COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                             I_item                    IN     ITEM_ZONE_PRICE.ITEM%TYPE)
RETURN BOOLEAN IS

L_system_ind  VARCHAR2(1);

   cursor C_ITEM is
      select cost_zone_group_id
        from item_master
       where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_ITEM','ITEM_MASTER','item:'||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH','C_ITEM','ITEM_MASTER','item:'||I_item);
   fetch C_ITEM into O_cost_zone_group_id;
   if C_ITEM%NOTFOUND then
        O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                               null,
                                               null,
                                               null);
         SQL_LIB.SET_MARK('CLOSE','C_ITEM','ITEM_MASTER','item:'||I_item);
         close C_ITEM;
         return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM','ITEM_MASTER','ITEM:'||I_item);
   close C_ITEM;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_COST_ZONE_GROUP',
                                            TO_CHAR(SQLCODE));
   RETURN FALSE;
END GET_COST_ZONE_GROUP;
---------------------------------------------------------------------------------------------
FUNCTION IMPORT_ATTR_EXISTS(O_error_message  IN OUT VARCHAR2,
                            O_exists         IN OUT BOOLEAN,
                            I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   ---
   L_dummy    VARCHAR2(1);
   ---
   cursor C_ITEM_IMPORT_ATTR is
      select 'x'
        from item_import_attr
       where item = I_item
       and ROWNUM = 1;
BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ITEM_IMPORT_ATTR','ITEM_IMPORT_ATTR','Item: '||I_item);
   open C_ITEM_IMPORT_ATTR;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_IMPORT_ATTR','ITEM_IMPORT_ATTR','Item: '||I_item);
   fetch C_ITEM_IMPORT_ATTR into L_dummy;
   if C_ITEM_IMPORT_ATTR%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_IMPORT_ATTR','ITEM_IMPORT_ATTR','Item: '||I_item);
   close C_ITEM_IMPORT_ATTR;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.IMPORT_ATTR_EXISTS',
                                            to_char(SQLCODE));
   RETURN FALSE;
END IMPORT_ATTR_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION ITEM_ELIGIBLE_EXISTS(O_error_message  IN OUT VARCHAR2,
                              O_exists         IN OUT BOOLEAN,
                              I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   ---
   L_dummy    VARCHAR2(1);
   ---
   cursor C_COND_TARIFF_TREATMENT is
      select 'x'
        from cond_tariff_treatment
        where item = I_item
        and ROWNUM = 1;
BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_COND_TARIFF_TREATMENT','COND_TARIFF_TREATMENT','Item: '||I_item);
   open C_COND_TARIFF_TREATMENT;
   SQL_LIB.SET_MARK('FETCH','C_COND_TARIFF_TREATMENT','COND_TARIFF_TREATMENT','Item: '||I_item);
   fetch C_COND_TARIFF_TREATMENT into L_dummy;
   if C_COND_TARIFF_TREATMENT%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_COND_TARIFF_TREATMENT','COND_TARIFF_TREATMENT','Item: '||I_item);
   close C_COND_TARIFF_TREATMENT;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.ITEM_ELIGIBLE_EXISTS',
                                            to_char(SQLCODE));
   RETURN FALSE;
END ITEM_ELIGIBLE_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION SUPPLIER_EXISTS(O_error_message  IN OUT VARCHAR2,
                         O_exists         IN OUT BOOLEAN,
                         I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   ---
   L_dummy      VARCHAR2(1);
   ---
   cursor C_ITEM_SUPPLIER is
      select 'x'
        from item_supplier
       where item = I_item
       and ROWNUM = 1;
BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ITEM_SUPPLIER','ITEM_SUPPLIER','Item: '||I_item);
   open C_ITEM_SUPPLIER;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_SUPPLIER','ITEM_SUPPLIER','Item: '||I_item);
   fetch C_ITEM_SUPPLIER into L_dummy;
   if C_ITEM_SUPPLIER%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_SUPPLIER','ITEM_SUPPLIER','Item: '||I_item);
   close C_ITEM_SUPPLIER;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.SUPPLIER_EXISTS',
                                            to_char(SQLCODE));
   RETURN FALSE;
END SUPPLIER_EXISTS;
----------------------------------------------------------------------------------------
FUNCTION GET_COST_ZONE(O_error_message IN OUT VARCHAR2,
                       O_zone_id       IN OUT COST_ZONE.ZONE_ID%TYPE,
                       I_item          IN     ITEM_MASTER.ITEM%TYPE,
                       I_zone_group_id IN     COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                       I_loc           IN     STORE.STORE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program         VARCHAR2(255) := 'ITEM_ATTRIB_SQL.GET_COST_ZONE';
   L_zone_group_id   COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE;
   ---
   cursor C_COST_ZONE_GROUP_LOC is
      select zone_id
        from cost_zone_group_loc
       where zone_group_id = L_zone_group_id
         and location = I_loc;
BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG',
                                            L_program,
                                            'I_item',
                                            'NULL');
      return FALSE;
   end if;

   if I_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG',
                                            L_program,
                                            'I_loc',
                                            'NULL');
      return FALSE;
   end if;

   L_zone_group_id := I_zone_group_id;

   if L_zone_group_id is NULL then
      if not ITEM_ATTRIB_SQL.GET_ZONE_GROUP(O_error_message,
                                            L_zone_group_id,
                                            I_item) then
         return FALSE;
      end if;
   end if;
   SQL_LIB.SET_MARK('OPEN', 'C_COST_ZONE_GROUP_LOC', 'COST_ZONE_GROUP_LOC',
                    'Zone group id: '||to_char(I_zone_group_id)||' Location: '||to_char(I_loc));
   open C_COST_ZONE_GROUP_LOC;
   SQL_LIB.SET_MARK('FETCH', 'C_COST_ZONE_GROUP_LOC', 'COST_ZONE_GROUP_LOC',
                    'Zone group id: '||to_char(I_zone_group_id)||' Location: '||to_char(I_loc));
   fetch C_COST_ZONE_GROUP_LOC into O_zone_id;
   if C_COST_ZONE_GROUP_LOC%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_COST_ZONE_GROUP_LOC', 'COST_ZONE_GROUP_LOC',
                       'Zone group id: '||to_char(I_zone_group_id)||' Location: '||to_char(I_loc));
      close C_COST_ZONE_GROUP_LOC;
      O_error_message := SQL_LIB.CREATE_MSG('NO_ZONE_ID', I_item, to_char(I_loc), NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_COST_ZONE_GROUP_LOC', 'COST_ZONE_GROUP_LOC',
                    'Zone group id: '||to_char(I_zone_group_id)||' Location: '||to_char(I_loc));
   close C_COST_ZONE_GROUP_LOC;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;
END GET_COST_ZONE;
---------------------------------------------------------------------------------------------
FUNCTION GET_STANDARD_UOM(O_error_message               IN OUT VARCHAR2,
                          O_standard_uom                IN OUT UOM_CLASS.UOM%TYPE,
                          O_standard_class              IN OUT UOM_CLASS.UOM_CLASS%TYPE,
                          O_conv_factor                 IN OUT ITEM_MASTER.UOM_CONV_FACTOR%TYPE,
                          I_item                        IN     ITEM_MASTER.ITEM%TYPE,
                          I_get_class_ind               IN     VARCHAR2)
   RETURN BOOLEAN IS
   ---
   L_program         VARCHAR2(64) := 'ITEM_ATTRIB_SQL.GET_STANDARD_UOM';
   ---
   cursor C_ITEM is
      select standard_uom, uom_conv_factor
        from item_master
       where item = I_item;

 BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','ITEM_MASTER','Item:'||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','ITEM_MASTER','Item:'||I_item);
   fetch C_ITEM into O_standard_uom, O_conv_factor;
   if C_ITEM%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','Item:'||I_item);
      close C_ITEM;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',NULL,NULL,NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','Item:'||I_item);
   close C_ITEM;

   ---
   if I_get_class_ind = 'Y' then
      ---
      if UOM_SQL.GET_CLASS (O_error_message,
                            O_standard_class,
                            O_standard_uom) = FALSE then
         return FALSE;
      end if;
      ---
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_STANDARD_UOM;
-----------------------------------------------------------------------------------------------
FUNCTION GET_STORE_ORD_MULT_AND_UOM(O_error_message   IN OUT VARCHAR2,
                            O_store_ord_mult  IN OUT ITEM_MASTER.STORE_ORD_MULT%TYPE,
                            O_standard_uom    IN OUT ITEM_MASTER.STANDARD_UOM%TYPE,
                            I_item            IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program      VARCHAR2(64)                := 'ITEM_ATTRIB_SQL.GET_STORE_ORD_MULT_AND_UOM';
   ---
   cursor C_ITEM is
      select store_ord_mult, standard_uom
        from item_master
       where item = I_item;

BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','ITEM_MASTER','Item:'||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','ITEM_MASTER','Item:'||I_item);
   fetch C_ITEM into O_store_ord_mult, O_standard_uom;
   if C_ITEM%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','Item:'||I_item);
      close C_ITEM;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',NULL,NULL,NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','Item:'||I_item);
   close C_ITEM;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_STORE_ORD_MULT_AND_UOM;
----------------------------------------------------------------------------------------------
FUNCTION GET_WASTAGE(O_error_message     IN OUT  VARCHAR2,
                     O_waste_type        IN OUT  ITEM_MASTER.WASTE_TYPE%TYPE,
                     O_waste_pct         IN OUT  ITEM_MASTER.WASTE_PCT%TYPE,
                     O_default_waste_pct IN OUT  ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE,
                     I_item              IN      ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_program    VARCHAR2(64) := 'ITEM_ATTRIB_SQL.GET_WASTAGE';
   cursor C_WASTE is
      select waste_type,
             NVL(waste_pct, 0),
             default_waste_pct
        from item_master
       where item = I_item;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_WASTE','ITEM_MASTER','Item:'||I_item);
   open C_WASTE;
   SQL_LIB.SET_MARK('FETCH', 'C_WASTE','ITEM_MASTER','Item:'||I_item);
   fetch C_WASTE into O_waste_type,
                      O_waste_pct,
                      O_default_waste_pct;
   SQL_LIB.SET_MARK('CLOSE', 'C_WASTE','ITEM_MASTER','Item:'||I_item);
   close C_WASTE;
   return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        null);
     RETURN FALSE;
END GET_WASTAGE;
-----------------------------------------------------------------------------------------------
FUNCTION UPDATE_DEFAULT_UOP(O_error_message     IN OUT VARCHAR2,
                            I_standard_uom      IN     ITEM_MASTER.STANDARD_UOM%TYPE,
                            I_item              IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_program  VARCHAR2(60) := 'ITEM_ATTRIB_SQL.UPDATE_DEFAULT_UOP';

   cursor C_PARENT is
      select item
        from item_master
       where item_parent = I_item;

   cursor C_GRANDPARENT is
      select item
        from item_master
       where item_grandparent = I_item;


BEGIN
   SQL_LIB.SET_MARK('UPDATE', 'ITEM_SUPP_COUNTRY','ITEM_SUPP_COUNTRY','Item: '||I_item);
   update item_supp_country
      set default_uop = I_standard_uom,
          last_update_id = user,
          last_update_datetime = sysdate
    where item = I_item
      and default_uop not in ('C','P');
---
   FOR rec IN C_PARENT LOOP
      SQL_LIB.SET_MARK('UPDATE', 'ITEM_SUPP_COUNTRY','ITEM_SUPP_COUNTRY','Item: '||I_item);
      update item_supp_country
        set default_uop = I_standard_uom,
            last_update_id = user,
            last_update_datetime = sysdate
       where item = rec.item
         and default_uop not in ('C','P');
   END LOOP;
---
   FOR rec IN C_GRANDPARENT LOOP
      SQL_LIB.SET_MARK('UPDATE', 'ITEM_SUPP_COUNTRY','ITEM_SUPP_COUNTRY','Item: '||I_item);
      update item_supp_country
        set default_uop = I_standard_uom,
            last_update_id = user,
            last_update_datetime = sysdate
       where item = rec.item
         and default_uop not in ('C','P');
   END LOOP;
---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             NULL);
      return FALSE;
END UPDATE_DEFAULT_UOP;
---------------------------------------------------------------------------------------------------
FUNCTION ON_ORD_CON_RCVD (O_error_message   IN OUT    VARCHAR2,
                          O_exists          IN OUT    BOOLEAN,
                          I_item            IN        ITEM_MASTER.ITEM%TYPE)

RETURN BOOLEAN IS

   L_program          VARCHAR2(60) := 'ITEM_ATTRIB_SQL.ON_ORD_OR_RCVD';
   L_first_received   ITEM_MASTER.FIRST_RECEIVED%TYPE;
   L_dummy            VARCHAR2(1);

   cursor C_ITEM is
      select first_received
        from item_master
       where item = I_item;

   cursor C_EXISTS is
      select 'x'
        from item_master im,
             ordsku ord
       where (im.item = I_item
          or im.item_parent = I_item
          or im.item_grandparent = I_item)
         and ord.item = im.item
   UNION ALL
      select 'x'
        from item_master im,
             contract_detail cd
       where (im.item = I_item
          or im.item_parent = I_item
          or im.item_grandparent = I_item)
         and cd.item = im.item
   UNION ALL
      select 'x'
        from item_master im,
             contract_cost cc
       where (im.item = I_item
          or im.item_parent = I_item
          or im.item_grandparent = I_item)
         and cc.item = im.item;

BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_ITEM into L_first_received;
   if L_first_received is NOT NULL then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM',
                       'ITEM_MASTER',
                       'item:'||I_item);
      close C_ITEM;
      O_exists := TRUE;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_ITEM;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_EXISTS into L_dummy;
   ---
   if C_EXISTS%FOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_EXISTS',
                       'ITEM_MASTER',
                       'Item: '||I_item);
      close C_EXISTS;
      O_exists := TRUE;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_EXISTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             NULL);
      return FALSE;
END ON_ORD_CON_RCVD;
---------------------------------------------------------------------------------------------------
FUNCTION PURCHASE_TYPE(O_error_message   IN OUT    VARCHAR2,
                       O_purchase_type   IN OUT    DEPS.PURCHASE_TYPE%TYPE,
                       I_item            IN        ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
---
L_purchase_type   DEPS.PURCHASE_TYPE%TYPE;
---
   cursor C_PURCHASE_TYPE is
      select deps.purchase_type
        from deps, item_master
       where deps.dept = item_master.dept
         and item_master.item = I_item;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_PURCHASE_TYPE','DEPS, ITEM_MASTER','ITEM: '||I_item);
   open C_PURCHASE_TYPE;
   SQL_LIB.SET_MARK('FETCH', 'C_PURCHASE_TYPE','DEPS, ITEM_MASTER','ITEM: '||I_item);
   fetch C_PURCHASE_TYPE into O_purchase_type;
   if C_PURCHASE_TYPE%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             null,
                                             null,
                                             null);
      SQL_LIB.SET_MARK('CLOSE','C_PURCHASE_TYPE','ITEM_MASTER','item:'||I_item);
      close C_PURCHASE_TYPE;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_PURCHASE_TYPE','DEPS, ITEM_MASTER','ITEM: '||I_item);
   close C_PURCHASE_TYPE;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.PURCHASE_TYPE',
                                            to_char(SQLCODE));
   RETURN FALSE;
END PURCHASE_TYPE;
---------------------------------------------------------------------------------------------------
FUNCTION GET_DESC( O_error_message IN OUT VARCHAR2,
                   O_desc          IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                   I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_dummy1   ITEM_MASTER.STATUS%TYPE;
   L_dummy2   ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_dummy3   ITEM_MASTER.TRAN_LEVEL%TYPE;

BEGIN
   if GET_DESC (O_error_message,
                O_desc,
                L_dummy1,
                L_dummy2,
                L_dummy3,
                I_item) = FALSE then
      return FALSE;
   else
      return TRUE;
   end if;
END GET_DESC;
---------------------------------------------------------------------------------------------
FUNCTION GET_DESC( O_error_message IN OUT VARCHAR2,
                   O_desc          IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                   O_status        IN OUT ITEM_MASTER.STATUS%TYPE,
                   I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_dummy2   ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_dummy3   ITEM_MASTER.TRAN_LEVEL%TYPE;

BEGIN
   if GET_DESC (O_error_message,
                O_desc,
                O_status,
                L_dummy2,
                L_dummy3,
                I_item) = FALSE then
      return FALSE;
   else
      return TRUE;
   end if;
END GET_DESC;
---------------------------------------------------------------------------------------------
FUNCTION GET_DESC(O_error_message IN OUT VARCHAR2,
                  O_desc          IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                  O_status        IN OUT ITEM_MASTER.STATUS%TYPE,
                  O_item_level    IN OUT ITEM_MASTER.ITEM_LEVEL%TYPE,
                  O_tran_level    IN OUT ITEM_MASTER.TRAN_LEVEL%TYPE,
                  I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.GET_DESC';

   cursor C_ITEM is
     select item_desc,
            status,
            item_level,
            tran_level
       from item_master
      where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   fetch C_ITEM into O_desc,
                     O_status,
                     O_item_level,
                     O_tran_level;
   if C_ITEM%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
      close C_ITEM;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             null,
                                             null,
                                             null);
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   close C_ITEM;
   if LANGUAGE_SQL.TRANSLATE(O_desc,
                             O_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        NULL);
      RETURN FALSE;
END GET_DESC;
---------------------------------------------------------------------------------------------
FUNCTION GET_LEVELS (O_error_message         IN OUT VARCHAR2,
                     O_item_level            IN OUT ITEM_MASTER.ITEM_LEVEL%TYPE,
                     O_tran_level            IN OUT ITEM_MASTER.TRAN_LEVEL%TYPE,
                     I_item                  IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   cursor C_ITEM is
     select item_level,
            tran_level
       from item_master
      where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   fetch C_ITEM into O_item_level, O_tran_level;
   if C_ITEM%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             null,
                                             null,
                                             null);
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
      close C_ITEM;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   close C_ITEM;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_LEVELS',
                                            to_char(SQLCODE));
   RETURN FALSE;
END GET_LEVELS;

---------------------------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message         IN OUT VARCHAR2,
                  O_item_desc             IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                  O_item_level            IN OUT ITEM_MASTER.ITEM_LEVEL%TYPE,
                  O_tran_level            IN OUT ITEM_MASTER.TRAN_LEVEL%TYPE,
                  O_status                IN OUT ITEM_MASTER.STATUS%TYPE,
                  O_pack_ind              IN OUT ITEM_MASTER.PACK_IND%TYPE,
                  O_dept                  IN OUT ITEM_MASTER.DEPT%TYPE,
                  O_dept_name             IN OUT DEPS.DEPT_NAME%TYPE,
                  O_class                 IN OUT ITEM_MASTER.CLASS%TYPE,
                  O_class_name            IN OUT CLASS.CLASS_NAME%TYPE,
                  O_subclass              IN OUT ITEM_MASTER.SUBCLASS%TYPE,
                  O_subclass_name         IN OUT SUBCLASS.SUB_NAME%TYPE,
                  O_retail_zone_group_id  IN OUT ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                  O_sellable_ind          IN OUT ITEM_MASTER.SELLABLE_IND%TYPE,
                  O_orderable_ind         IN OUT ITEM_MASTER.ORDERABLE_IND%TYPE,
                  O_pack_type             IN OUT ITEM_MASTER.PACK_TYPE%TYPE,
                  O_simple_pack_ind       IN OUT ITEM_MASTER.SIMPLE_PACK_IND%TYPE,
                  O_waste_type            IN OUT ITEM_MASTER.WASTE_TYPE%TYPE,
                  O_item_parent           IN OUT ITEM_MASTER.ITEM_PARENT%TYPE,
                  O_item_grandparent      IN OUT ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                  O_short_desc            IN OUT ITEM_MASTER.SHORT_DESC%TYPE,
                  O_waste_pct             IN OUT ITEM_MASTER.WASTE_PCT%TYPE,
                  O_default_waste_pct     IN OUT ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE,
                  I_item    IN    ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   --- Dummy variables for the call to the longer GET_INFO function
   L_item_number_type     ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   L_diff_1               ITEM_MASTER.DIFF_1%TYPE;
   L_diff_1_desc          V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_1_type          V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_1_id_group_ind  V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_diff_2               ITEM_MASTER.DIFF_2%TYPE;
   L_diff_2_desc          V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_2_type          V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_2_id_group_ind  V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_order_as_type        ITEM_MASTER.ORDER_AS_TYPE%TYPE;
   L_format_id            ITEM_MASTER.FORMAT_ID%TYPE;
   L_prefix               ITEM_MASTER.PREFIX%TYPE;
   L_contains_inner_ind   ITEM_MASTER.CONTAINS_INNER_IND%TYPE;
   L_store_ord_mult       ITEM_MASTER.STORE_ORD_MULT%TYPE;

BEGIN
   if GET_INFO(O_error_message,
               O_item_desc,
               O_item_level,
               O_tran_level,
               O_status,
               O_pack_ind,
               O_dept,
               O_dept_name,
               O_class,
               O_class_name,
               O_subclass,
               O_subclass_name,
               O_retail_zone_group_id,
               O_sellable_ind,
               O_orderable_ind,
               O_pack_type,
               O_simple_pack_ind,
               O_waste_type,
               O_item_parent,
               O_item_grandparent,
               O_short_desc,
               O_waste_pct,
               O_default_waste_pct,
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
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_INFO',
                                            to_char(SQLCODE));
   return FALSE;
END GET_INFO;
---------------------------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message         IN OUT VARCHAR2,
                  O_item_desc             IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                  O_item_level            IN OUT ITEM_MASTER.ITEM_LEVEL%TYPE,
                  O_tran_level            IN OUT ITEM_MASTER.TRAN_LEVEL%TYPE,
                  O_status                IN OUT ITEM_MASTER.STATUS%TYPE,
                  O_pack_ind              IN OUT ITEM_MASTER.PACK_IND%TYPE,
                  O_dept                  IN OUT ITEM_MASTER.DEPT%TYPE,
                  O_dept_name             IN OUT DEPS.DEPT_NAME%TYPE,
                  O_class                 IN OUT ITEM_MASTER.CLASS%TYPE,
                  O_class_name            IN OUT CLASS.CLASS_NAME%TYPE,
                  O_subclass              IN OUT ITEM_MASTER.SUBCLASS%TYPE,
                  O_subclass_name         IN OUT SUBCLASS.SUB_NAME%TYPE,
                  O_retail_zone_group_id  IN OUT ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                  O_sellable_ind          IN OUT ITEM_MASTER.SELLABLE_IND%TYPE,
                  O_orderable_ind         IN OUT ITEM_MASTER.ORDERABLE_IND%TYPE,
                  O_pack_type             IN OUT ITEM_MASTER.PACK_TYPE%TYPE,
                  O_item_parent           IN OUT ITEM_MASTER.ITEM_PARENT%TYPE,
                  O_item_number_type      IN OUT ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                  I_item                  IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   --- Dummy variables for the call to the longer GET_INFO function
   L_diff_1               ITEM_MASTER.DIFF_1%TYPE;
   L_diff_1_desc          V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_1_type          V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_1_id_group_ind  V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_diff_2               ITEM_MASTER.DIFF_2%TYPE;
   L_diff_2_desc          V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_2_type          V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_2_id_group_ind  V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_order_as_type        ITEM_MASTER.ORDER_AS_TYPE%TYPE;
   L_format_id            ITEM_MASTER.FORMAT_ID%TYPE;
   L_prefix               ITEM_MASTER.PREFIX%TYPE;
   L_contains_inner_ind   ITEM_MASTER.CONTAINS_INNER_IND%TYPE;
   L_store_ord_mult       ITEM_MASTER.STORE_ORD_MULT%TYPE;
   L_simple_pack_ind      ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_waste_type           ITEM_MASTER.WASTE_TYPE%TYPE;
   L_item_grandparent     ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_short_desc           ITEM_MASTER.SHORT_DESC%TYPE;
   L_waste_pct            ITEM_MASTER.WASTE_PCT%TYPE;
   L_default_waste_pct    ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE;

BEGIN
   if GET_INFO(O_error_message,
               O_item_desc,
               O_item_level,
               O_tran_level,
               O_status,
               O_pack_ind,
               O_dept,
               O_dept_name,
               O_class,
               O_class_name,
               O_subclass,
               O_subclass_name,
               O_retail_zone_group_id,
               O_sellable_ind,
               O_orderable_ind,
               O_pack_type,
               L_simple_pack_ind,
               L_waste_type,
               O_item_parent,
               L_item_grandparent,
               L_short_desc,
               L_waste_pct,
               L_default_waste_pct,
               O_item_number_type,
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
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_INFO',
                                            to_char(SQLCODE));
   return FALSE;
END GET_INFO;
---------------------------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message         IN OUT VARCHAR2,
                  O_item_desc             IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                  O_item_level            IN OUT ITEM_MASTER.ITEM_LEVEL%TYPE,
                  O_tran_level            IN OUT ITEM_MASTER.TRAN_LEVEL%TYPE,
                  O_status                IN OUT ITEM_MASTER.STATUS%TYPE,
                  O_pack_ind              IN OUT ITEM_MASTER.PACK_IND%TYPE,
                  O_dept                  IN OUT ITEM_MASTER.DEPT%TYPE,
                  O_dept_name             IN OUT DEPS.DEPT_NAME%TYPE,
                  O_class                 IN OUT ITEM_MASTER.CLASS%TYPE,
                  O_class_name            IN OUT CLASS.CLASS_NAME%TYPE,
                  O_subclass              IN OUT ITEM_MASTER.SUBCLASS%TYPE,
                  O_subclass_name         IN OUT SUBCLASS.SUB_NAME%TYPE,
                  O_retail_zone_group_id  IN OUT ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                  O_sellable_ind          IN OUT ITEM_MASTER.SELLABLE_IND%TYPE,
                  O_orderable_ind         IN OUT ITEM_MASTER.ORDERABLE_IND%TYPE,
                  O_pack_type             IN OUT ITEM_MASTER.PACK_TYPE%TYPE,
                  O_simple_pack_ind       IN OUT ITEM_MASTER.SIMPLE_PACK_IND%TYPE,
                  O_waste_type            IN OUT ITEM_MASTER.WASTE_TYPE%TYPE,
                  O_item_parent           IN OUT ITEM_MASTER.ITEM_PARENT%TYPE,
                  O_item_grandparent      IN OUT ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                  O_short_desc            IN OUT ITEM_MASTER.SHORT_DESC%TYPE,
                  O_waste_pct             IN OUT ITEM_MASTER.WASTE_PCT%TYPE,
                  O_default_waste_pct     IN OUT ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE,
                  O_item_number_type      IN OUT ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                  O_diff_1                IN OUT ITEM_MASTER.DIFF_1%TYPE,
                  O_diff_1_desc           IN OUT V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                  O_diff_1_type           IN OUT V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                  O_diff_1_id_group_ind   IN OUT V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                  O_diff_2                IN OUT ITEM_MASTER.DIFF_2%TYPE,
                  O_diff_2_desc           IN OUT V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                  O_diff_2_type           IN OUT V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                  O_diff_2_id_group_ind   IN OUT V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                  O_order_as_type         IN OUT ITEM_MASTER.ORDER_AS_TYPE%TYPE,
                  O_format_id             IN OUT ITEM_MASTER.FORMAT_ID%TYPE,
                  O_prefix                IN OUT ITEM_MASTER.PREFIX%TYPE,
                  O_store_ord_mult        IN OUT ITEM_MASTER.STORE_ORD_MULT%TYPE,
                  O_contains_inner_ind    IN OUT ITEM_MASTER.CONTAINS_INNER_IND%TYPE,
                  I_item                  IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_diff_3               ITEM_MASTER.DIFF_3%TYPE;
   L_diff_3_desc          V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_3_type          V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_3_id_group_ind  V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_diff_4               ITEM_MASTER.DIFF_4%TYPE;
   L_diff_4_desc          V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_4_type          V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_4_id_group_ind  V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;

BEGIN
   if GET_INFO(O_error_message,
               O_item_desc,
               O_item_level,
               O_tran_level,
               O_status,
               O_pack_ind,
               O_dept,
               O_dept_name,
               O_class,
               O_class_name,
               O_subclass,
               O_subclass_name,
               O_retail_zone_group_id,
               O_sellable_ind,
               O_orderable_ind,
               O_pack_type,
               O_simple_pack_ind,
               O_waste_type,
               O_item_parent,
               O_item_grandparent,
               O_short_desc,
               O_waste_pct,
               O_default_waste_pct,
               O_item_number_type,
               O_diff_1,
               O_diff_1_desc,
               O_diff_1_type,
               O_diff_1_id_group_ind,
               O_diff_2,
               O_diff_2_desc,
               O_diff_2_type,
               O_diff_2_id_group_ind,
               L_diff_3,
               L_diff_3_desc,
               L_diff_3_type,
               L_diff_3_id_group_ind,
               L_diff_4,
               L_diff_4_desc,
               L_diff_4_type,
               L_diff_4_id_group_ind,
               O_order_as_type,
               O_format_id,
               O_prefix,
               O_store_ord_mult,
               O_contains_inner_ind,
               I_item) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_INFO',
                                            to_char(SQLCODE));
   return FALSE;
END GET_INFO;
---------------------------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message         IN OUT VARCHAR2,
                  O_item_desc             IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                  O_item_level            IN OUT ITEM_MASTER.ITEM_LEVEL%TYPE,
                  O_tran_level            IN OUT ITEM_MASTER.TRAN_LEVEL%TYPE,
                  O_status                IN OUT ITEM_MASTER.STATUS%TYPE,
                  O_pack_ind              IN OUT ITEM_MASTER.PACK_IND%TYPE,
                  O_dept                  IN OUT ITEM_MASTER.DEPT%TYPE,
                  O_dept_name             IN OUT DEPS.DEPT_NAME%TYPE,
                  O_class                 IN OUT ITEM_MASTER.CLASS%TYPE,
                  O_class_name            IN OUT CLASS.CLASS_NAME%TYPE,
                  O_subclass              IN OUT ITEM_MASTER.SUBCLASS%TYPE,
                  O_subclass_name         IN OUT SUBCLASS.SUB_NAME%TYPE,
                  O_retail_zone_group_id  IN OUT ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                  O_sellable_ind          IN OUT ITEM_MASTER.SELLABLE_IND%TYPE,
                  O_orderable_ind         IN OUT ITEM_MASTER.ORDERABLE_IND%TYPE,
                  O_pack_type             IN OUT ITEM_MASTER.PACK_TYPE%TYPE,
                  O_simple_pack_ind       IN OUT ITEM_MASTER.SIMPLE_PACK_IND%TYPE,
                  O_waste_type            IN OUT ITEM_MASTER.WASTE_TYPE%TYPE,
                  O_item_parent           IN OUT ITEM_MASTER.ITEM_PARENT%TYPE,
                  O_item_grandparent      IN OUT ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                  O_short_desc            IN OUT ITEM_MASTER.SHORT_DESC%TYPE,
                  O_waste_pct             IN OUT ITEM_MASTER.WASTE_PCT%TYPE,
                  O_default_waste_pct     IN OUT ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE,
                  O_item_number_type      IN OUT ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                  O_diff_1                IN OUT ITEM_MASTER.DIFF_1%TYPE,
                  O_diff_1_desc           IN OUT V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                  O_diff_1_type           IN OUT V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                  O_diff_1_id_group_ind   IN OUT V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                  O_diff_2                IN OUT ITEM_MASTER.DIFF_2%TYPE,
                  O_diff_2_desc           IN OUT V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                  O_diff_2_type           IN OUT V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                  O_diff_2_id_group_ind   IN OUT V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                  O_diff_3                IN OUT ITEM_MASTER.DIFF_3%TYPE,
                  O_diff_3_desc           IN OUT V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                  O_diff_3_type           IN OUT V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                  O_diff_3_id_group_ind   IN OUT V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                  O_diff_4                IN OUT ITEM_MASTER.DIFF_4%TYPE,
                  O_diff_4_desc           IN OUT V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                  O_diff_4_type           IN OUT V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                  O_diff_4_id_group_ind   IN OUT V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                  O_order_as_type         IN OUT ITEM_MASTER.ORDER_AS_TYPE%TYPE,
                  O_format_id             IN OUT ITEM_MASTER.FORMAT_ID%TYPE,
                  O_prefix                IN OUT ITEM_MASTER.PREFIX%TYPE,
                  O_store_ord_mult        IN OUT ITEM_MASTER.STORE_ORD_MULT%TYPE,
                  O_contains_inner_ind    IN OUT ITEM_MASTER.CONTAINS_INNER_IND%TYPE,
                  I_item                  IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_short_desc ITEM_MASTER.SHORT_DESC%TYPE;

   cursor C_ITEM is
     select item_desc,
            item_level,
            tran_level,
            status,
            pack_ind,
            dept,
            class,
            subclass,
            retail_zone_group_id,
            sellable_ind,
            orderable_ind,
            pack_type,
            simple_pack_ind,
            waste_type,
            item_parent,
            item_grandparent,
            short_desc,
            waste_pct,
            default_waste_pct,
            item_number_type,
            diff_1,
            diff_2,
            diff_3,
            diff_4,
            order_as_type,
            format_id,
            prefix,
            store_ord_mult,
            contains_inner_ind
       from item_master
      where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   fetch C_ITEM into O_item_desc,
                     O_item_level,
                     O_tran_level,
                     O_status,
                     O_pack_ind,
                     O_dept,
                     O_class,
                     O_subclass,
                     O_retail_zone_group_id,
                     O_sellable_ind,
                     O_orderable_ind,
                     O_pack_type,
                     O_simple_pack_ind,
                     O_waste_type,
                     O_item_parent,
                     O_item_grandparent,
                     O_short_desc,
                     O_waste_pct,
                     O_default_waste_pct,
                     O_item_number_type,
                     O_diff_1,
                     O_diff_2,
                     O_diff_3,
                     O_diff_4,
                     O_order_as_type,
                     O_format_id,
                     O_prefix,
                     O_store_ord_mult,
                     O_contains_inner_ind;

   if C_ITEM%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM', NULL, NULL, NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
      close C_ITEM;
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   close C_ITEM;

   --- Get info for diff_1
   if O_diff_1 is NOT NULL then
      if DIFF_SQL.GET_DIFF_INFO(O_error_message,
                                O_diff_1_desc,
                                O_diff_1_type,
                                O_diff_1_id_group_ind,
                                O_diff_1) = FALSE then
         RETURN FALSE;
      end if;
   end if;

   --- Get info for diff_2
   if O_diff_2 is NOT NULL then
      if DIFF_SQL.GET_DIFF_INFO(O_error_message,
                                O_diff_2_desc,
                                O_diff_2_type,
                                O_diff_2_id_group_ind,
                                O_diff_2) = FALSE then
         RETURN FALSE;
      end if;
   end if;

   --- Get info for diff_3
   if O_diff_3 is NOT NULL then
      if DIFF_SQL.GET_DIFF_INFO(O_error_message,
                                O_diff_3_desc,
                                O_diff_3_type,
                                O_diff_3_id_group_ind,
                                O_diff_3) = FALSE then
         RETURN FALSE;
      end if;
   end if;

   --- Get info for diff_4
   if O_diff_4 is NOT NULL then
      if DIFF_SQL.GET_DIFF_INFO(O_error_message,
                                O_diff_4_desc,
                                O_diff_4_type,
                                O_diff_4_id_group_ind,
                                O_diff_4) = FALSE then
         RETURN FALSE;
      end if;
   end if;

   if LANGUAGE_SQL.TRANSLATE(O_item_desc,
                             O_item_desc,
                             O_error_message) = FALSE then
      RETURN FALSE;
   end if;

   if DEPT_ATTRIB_SQL.GET_NAME(O_error_message,
                               O_dept,
                               O_dept_name) = FALSE then
      RETURN FALSE;
   end if;

   if CLASS_ATTRIB_SQL.GET_NAME(O_error_message,
                                O_dept,
                                O_class,
                                O_class_name) = FALSE then
      RETURN FALSE;
   end if;

   if SUBCLASS_ATTRIB_SQL.GET_NAME(O_error_message,
                                   O_dept,
                                   O_class,
                                   O_subclass,
                                   O_subclass_name) = FALSE then
      RETURN FALSE;
   end if;

   if LANGUAGE_SQL.TRANSLATE(O_short_desc,
                             L_short_desc,
                             O_error_message) = FALSE then
      RETURN FALSE;
   end if;
   O_short_desc := L_short_desc;

   return TRUE;


EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_INFO',
                                            to_char(SQLCODE));
   RETURN FALSE;
END GET_INFO;
---------------------------------------------------------------------------------------------
FUNCTION GET_PACK_INDS (O_error_message  IN OUT VARCHAR2,
                        O_pack_ind       IN OUT ITEM_MASTER.PACK_IND%TYPE,
                        O_sellable_ind   IN OUT ITEM_MASTER.SELLABLE_IND%TYPE,
                        O_orderable_ind  IN OUT ITEM_MASTER.ORDERABLE_IND%TYPE,
                        O_pack_type      IN OUT ITEM_MASTER.PACK_TYPE%TYPE,
                        I_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

--Dummy variable
L_order_as_type         ITEM_MASTER.ORDER_AS_TYPE%TYPE;

BEGIN

   if GET_PACK_INDS (O_error_message,
                     O_pack_ind,
                     O_sellable_ind,
                     O_orderable_ind,
                     O_pack_type,
                     L_order_as_type,
                     I_item) = FALSE then
      return FALSE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_PACK_INDS',
                                            to_char(SQLCODE));
   RETURN FALSE;

END GET_PACK_INDS;
---------------------------------------------------------------------------------------------
FUNCTION GET_PACK_INDS (O_error_message  IN OUT VARCHAR2,
                        O_pack_ind       IN OUT ITEM_MASTER.PACK_IND%TYPE,
                        O_sellable_ind   IN OUT ITEM_MASTER.SELLABLE_IND%TYPE,
                        O_orderable_ind  IN OUT ITEM_MASTER.ORDERABLE_IND%TYPE,
                        O_pack_type      IN OUT ITEM_MASTER.PACK_TYPE%TYPE,
                        O_order_as_type  IN OUT ITEM_MASTER.ORDER_AS_TYPE%TYPE,
                        I_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   cursor C_ITEM is
     select pack_ind,
            sellable_ind,
            orderable_ind,
            pack_type,
            order_as_type
       from item_master
      where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   fetch C_ITEM into O_pack_ind,
                     O_sellable_ind,
                     O_orderable_ind,
                     O_pack_type,
                     O_order_as_type;
   if C_ITEM%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             null,
                                             null,
                                             null);
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
      close C_ITEM;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   close C_ITEM;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_PACK_INDS',
                                            to_char(SQLCODE));
   RETURN FALSE;
END GET_PACK_INDS;
---------------------------------------------------------------------------------------------
FUNCTION GET_PARENT_INFO  (O_error_message     IN OUT VARCHAR2,
                           O_parent            IN OUT ITEM_MASTER.ITEM_PARENT%TYPE,
                           O_parent_desc       IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                           O_grandparent       IN OUT ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                           O_grandparent_desc  IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                           I_item              IN  ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.GET_PARENT_INFO';

  cursor C_DESC IS
     select item_parent, item_grandparent
       from item_master
       where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_DESC','ITEM_MASTER','ITEM: '||I_item);
   open C_DESC;
   SQL_LIB.SET_MARK('FETCH', 'C_DESC','ITEM_MASTER','ITEM: '||I_item);
   fetch C_DESC into O_parent,O_grandparent;
   if O_grandparent IS NOT NULL then
      if ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                                  O_grandparent_desc,
                                  O_grandparent) = FALSE then
         return FALSE;
      end if;
   end if;
   if O_parent IS NOT NULL then
      if ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                                  O_parent_desc,
                                  O_parent) = FALSE then
         return FALSE;
      end if;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_DESC','ITEM_MASTER','ITEM: '||I_item);
   close C_DESC;

RETURN TRUE;


EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        NULL);
   RETURN FALSE;
END GET_PARENT_INFO;
---------------------------------------------------------------------------------------------
FUNCTION EXISTS_AS_SUB_ITEM (O_error_message  IN OUT VARCHAR2,
                             O_exists         IN OUT BOOLEAN,
                             I_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.EXISTS_AS_SUB_ITEM';
L_dummy      VARCHAR2(1);

cursor C_EXISTS IS
      select 'x'
        from sub_items_detail
       where sub_item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_EXISTS','SUB_ITEM_DETAIL','Sub: '||I_item);
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH', 'C_EXISTS','SUB_ITEM_DETAIL','Sub: '||I_item);
   fetch C_EXISTS into L_dummy;
   if C_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_EXISTS','SUB_ITEM_DETAIL','Sub: '||I_item);
   close C_EXISTS;

RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        NULL);
   RETURN FALSE;
END EXISTS_AS_SUB_ITEM;
---------------------------------------------------------------------------------------------
FUNCTION UDA_EXISTS (O_error_message  IN OUT VARCHAR2,
                     O_exists         IN OUT BOOLEAN,
                     I_item           IN    ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.UDA_EXISTS';
L_dummy      VARCHAR2(1);

cursor C_LOV_EXISTS IS
      select 'x'
        from uda_item_lov
       where item = I_item
       and ROWNUM = 1;

cursor C_DATE_EXISTS IS
      select 'x'
        from uda_item_date
       where item = I_item
       and ROWNUM = 1;

cursor C_FF_EXISTS IS
      select 'x'
        from uda_item_ff t3
       where item = I_item
       and ROWNUM = 1;


BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_LOV_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
   open C_LOV_EXISTS;
   SQL_LIB.SET_MARK('FETCH', 'C_LOV_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
   fetch C_LOV_EXISTS into L_dummy;
   if C_LOV_EXISTS%FOUND then
      O_exists := TRUE;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOV_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
      close C_LOV_EXISTS;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOV_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
   close C_LOV_EXISTS;

   SQL_LIB.SET_MARK('OPEN', 'C_DATE_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
   open C_DATE_EXISTS;
   SQL_LIB.SET_MARK('FETCH', 'C_DATE_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
   fetch C_DATE_EXISTS into L_dummy;
   if C_DATE_EXISTS%FOUND then
      O_exists := TRUE;
      SQL_LIB.SET_MARK('CLOSE', 'C_DATE_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
      close C_DATE_EXISTS;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_DATE_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
   close C_DATE_EXISTS;

   SQL_LIB.SET_MARK('OPEN', 'C_FF_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
   open C_FF_EXISTS;
   SQL_LIB.SET_MARK('FETCH', 'C_FF_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
   fetch C_FF_EXISTS into L_dummy;

   if C_FF_EXISTS%FOUND then
      O_exists := TRUE;
      SQL_LIB.SET_MARK('CLOSE', 'C_FF_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
      close C_FF_EXISTS;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_FF_EXISTS','UDA_ITEM_LOV','Item: '||I_item);
   close C_FF_EXISTS;

 RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        NULL);
   RETURN FALSE;
END UDA_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION TICKET_EXISTS (O_error_message  IN OUT VARCHAR2,
                        O_exists         IN OUT BOOLEAN,
                        I_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.TICKET_EXISTS';
L_dummy      VARCHAR2(1);

cursor C_EXISTS IS
      select 'x'
        from item_ticket
       where item = I_item
       and ROWNUM = 1;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_EXISTS','ITEM_TICKET','Item: '||I_item);
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH', 'C_EXISTS','ITEM_TICKET','Item: '||I_item);
   fetch C_EXISTS into L_dummy;
   if C_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_EXISTS','ITEM_TICKET','Item: '||I_item);
   close C_EXISTS;

RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        NULL);
   RETURN FALSE;
END TICKET_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION TAX_CODES_EXIST  (O_error_message  IN OUT VARCHAR2,
                           O_exists         IN OUT BOOLEAN,
                           I_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.TAX_CODES_EXISTS';
L_dummy      VARCHAR2(1);

cursor C_EXISTS IS
      select 'x'
        from product_tax_code
       where item = I_item
       and ROWNUM = 1;

BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_EXISTS','PRODUCT_TAX_CODE','Item: '||I_item);
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH', 'C_EXISTS','PRODUCT_TAX_CODE','Item: '||I_item);
   fetch C_EXISTS into L_dummy;
   if C_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_EXISTS','PRODUCT_TAX_CODE','Item: '||I_item);
   close C_EXISTS;

RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        NULL);
   RETURN FALSE;
END TAX_CODES_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION GET_DIFFS (O_error_message  IN OUT VARCHAR2,
                    O_diff_1         IN OUT ITEM_MASTER.DIFF_1%TYPE,
                    O_diff_2         IN OUT ITEM_MASTER.DIFF_2%TYPE,
                    O_diff_3         IN OUT ITEM_MASTER.DIFF_3%TYPE,
                    O_diff_4         IN OUT ITEM_MASTER.DIFF_4%TYPE,
                    I_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.GET_DIFFS';
L_dummy      VARCHAR2(1);

   cursor C_ITEM is
      select diff_1,
             diff_2,
             diff_3,
             diff_4
        from item_master
       where item = I_item;

BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','ITEM_MASTER','Item: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','ITEM_MASTER','Item: '||I_item);
   fetch C_ITEM into O_diff_1, O_diff_2, O_diff_3, O_diff_4;
   if C_ITEM%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             null,
                                             null,
                                             null);
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','Item: '||I_item);
      close C_ITEM;
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','Item: '||I_item);
   close C_ITEM;

RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
   RETURN FALSE;
END GET_DIFFS;
---------------------------------------------------------------------------------------------
FUNCTION VALIDATE_ITEM_DIFF(O_error_message  IN OUT VARCHAR2,
                            O_exists         IN OUT BOOLEAN,
                            I_item           IN     ITEM_MASTER.ITEM%TYPE,
                            I_diff_id        IN     DIFF_IDS.DIFF_ID%TYPE)
RETURN BOOLEAN IS

L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.VALIDATE_ITEM_DIFF';
L_dummy      VARCHAR2(1);

cursor C_EXISTS IS
      select 'Y'
        from item_master
       where (item_parent = I_item
       or item_grandparent = I_item)
       and (diff_1 = I_diff_id
       or diff_2 = I_diff_id
       or diff_3 = I_diff_id
       or diff_4 = I_diff_id);

BEGIN
   ---
   if I_item is NULL or I_diff_id is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_item,I_diff_id','NULL','NOT NULL');
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN', 'C_EXISTS','ITEM_MASTER','Item: '||I_item);
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH', 'C_EXISTS','ITEM_MASTER','Item: '||I_item);
   fetch C_EXISTS into L_dummy;
   if C_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_EXITS','ITEM_MASTER','Item: '||I_item);
   close C_EXISTS;

  RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        NULL);
   RETURN FALSE;
END VALIDATE_ITEM_DIFF;
---------------------------------------------------------------------------------------------
FUNCTION EXPENSE_EXISTS(O_error_message   IN OUT VARCHAR2,
                        O_exists          IN OUT BOOLEAN,
                        I_item            IN     ITEM_MASTER.ITEM%TYPE)

RETURN BOOLEAN IS

L_exists   VARCHAR2(255) := NULL;

cursor C_ITEM_EXISTS is
   select 'x'
     from item_exp_head
    where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_EXISTS',
                    'ITEM_EXP_HEAD',
                    NULL);
   open C_ITEM_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_EXISTS',
                    'ITEM_EXP_HEAD',
                    NULL);
   fetch C_ITEM_EXISTS into L_exists;

   if L_exists is not NULL then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_EXISTS',
                    'ITEM_EXP_HEAD',
                    NULL);
   close C_ITEM_EXISTS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            NULL,
                                            NULL);

    return FALSE;
END EXPENSE_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION VAT_EXISTS(O_error_message   IN OUT VARCHAR2,
                    O_exists          IN OUT BOOLEAN,
                    I_item            IN     ITEM_MASTER.ITEM%TYPE)

RETURN BOOLEAN IS

L_exists   VARCHAR2(255) := NULL;

cursor L_VAT_EXISTS is
   select 'x'
     from vat_item
    where item = I_item
    and ROWNUM = 1;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'L_VAT_EXISTS',
                    'VAT_ITEM',
                    NULL);

   open L_VAT_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'L_VAT_EXISTS',
                    'VAT_ITEM',
                    NULL);

   fetch L_VAT_EXISTS into L_exists;

   if L_exists is not NULL then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;


   SQL_LIB.SET_MARK('CLOSE',
                    'L_VAT_EXISTS',
                    'VAT_ITEM',
                    NULL);

   close L_VAT_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            NULL,
                                            NULL);
   RETURN FALSE;
END VAT_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION GET_CONST_DIMEN_IND(O_error_message   IN OUT VARCHAR2,
                             O_const_dim_ind   IN OUT ITEM_MASTER.CONST_DIMEN_IND%TYPE,
                             I_item            IN     ITEM_MASTER.ITEM%TYPE)

RETURN BOOLEAN IS

L_program               VARCHAR2(62)   := 'ITEM_ATTRIB_SQL.GET_CONST_DIMEN_IND';


cursor C_GET_CONST_DIMEN is
   select const_dimen_ind
     from item_master
    where item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_GET_CONST_DIMEN','ITEM_MASTER',NULL);
   open C_GET_CONST_DIMEN;

   SQL_LIB.SET_MARK('FETCH','C_GET_CONST_DIMEN','ITEM_MASTER',NULL);
   fetch C_GET_CONST_DIMEN into O_const_dim_ind;

   SQL_LIB.SET_MARK('CLOSE','C_GET_CONST_DIMEN','ITEM_MASTER', NULL);
   close C_GET_CONST_DIMEN;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
   RETURN FALSE;
END GET_CONST_DIMEN_IND;
---------------------------------------------------------------------------------------------
-- UNAV_INV_EXISTS - This function will return TRUE if any unavailable inventory records
--                   exist on inv_status_qty for the given item.
---------------------------------------------------------------------------------------------
FUNCTION UNAV_INV_EXISTS(O_error_message   IN OUT VARCHAR2,
                         O_exists          IN OUT BOOLEAN,
                         I_item            IN     ITEM_MASTER.ITEM%TYPE)

RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.UNAV_INV_EXISTS';
   L_exists    VARCHAR2(1)  := 'N';

   cursor C_CHECK_UNAV is
      select 'Y'
        from inv_status_qty
       where item = I_item
       and ROWNUM = 1;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_CHECK_UNAV','inv_status_qty',NULL);
   open C_CHECK_UNAV;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_UNAV','inv_status_qty',NULL);
   fetch C_CHECK_UNAV into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_UNAV','inv_status_qty',NULL);
   close C_CHECK_UNAV;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,L_program,NULL);
      return FALSE;
END UNAV_INV_EXISTS;

---------------------------------------------------------------------------------------------
FUNCTION CHECK_SUB_ITEM(O_error_message  IN OUT  VARCHAR2,
                        O_exists         IN OUT  BOOLEAN,
                        O_item_or_sub    IN OUT  VARCHAR2,
                        I_item           IN      SUB_ITEMS_DETAIL.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'ITEM_ATTRIB_SQL.CHECK_SUB_ITEM';

   cursor C_ITEM is
      select 'M'
        from sub_items_detail
       where item = I_item
       and ROWNUM = 1;

   cursor C_SUB is
      select 'S'
        from sub_items_detail
       where sub_item = I_item
       and ROWNUM = 1;

BEGIN
   O_exists := FALSE;

   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','SUB_ITEMS_DETAIL','Item: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','SUB_ITEMS_DETAIL','Item: '||I_item);
   fetch C_ITEM into O_item_or_sub;
   if C_ITEM%FOUND then
      --- Item contains sub items
      O_exists := TRUE;
   else
      SQL_LIB.SET_MARK('OPEN', 'C_SUB','SUB_ITEMS_DETAIL','Sub: '||I_item);
      open C_SUB;
      SQL_LIB.SET_MARK('FETCH', 'C_SUB','SUB_ITEMS_DETAIL','Sub: '||I_item);
      fetch C_SUB into O_item_or_sub;
      if C_SUB%FOUND then
         --- Item is a sub item
         O_exists := TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_SUB','SUB_ITEMS_DETAIL','Sub: '||I_item);
      close C_SUB;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','SUB_ITEMS_DETAIL','Item: '||I_item);
   close C_ITEM;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        NULL);
      return FALSE;
END CHECK_SUB_ITEM;
---------------------------------------------------------------------------------------------
FUNCTION GET_ITEM_NUMBER_TYPE(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_item_number_type  IN OUT ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                              I_item              IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   cursor C_TYPE is
      select item_number_type
        from item_master
       where item = I_item;

BEGIN
   open C_TYPE;
   fetch C_TYPE into O_item_number_type;
   close C_TYPE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_ITEM_NUMBER_TYPE',
                                            NULL);
      return FALSE;
END GET_ITEM_NUMBER_TYPE;
---------------------------------------------------------------------------------------------
FUNCTION GET_CHILD_ITEM_NUMBER_TYPE(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    O_item_number_type  IN OUT ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                                    O_exists            IN OUT BOOLEAN,
                                    I_item_parent       IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   cursor C_TYPE is
      select item_number_type
        from item_master
       where item_parent = I_item_parent;

BEGIN
   open C_TYPE;
   fetch C_TYPE into O_item_number_type;
   close C_TYPE;

   if O_item_number_type is NULL then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_CHILD_ITEM_NUMBER_TYPE',
                                            NULL);
      return FALSE;
END GET_CHILD_ITEM_NUMBER_TYPE;
---------------------------------------------------------------------------------------------
FUNCTION GET_PRIMARY_REF_ITEM(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_primary_ref_item  IN OUT ITEM_MASTER.ITEM%TYPE,
                              O_exists            IN OUT BOOLEAN,
                              I_item              IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   cursor C_REF_ITEM is
      select item
        from item_master
       where item_parent = I_item
         and primary_ref_item_ind = 'Y';

BEGIN
   open C_REF_ITEM;
   fetch C_REF_ITEM into O_primary_ref_item;
   close C_REF_ITEM;

   if O_primary_ref_item is NULL then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_PRIMARY_REF_ITEM',
                                            NULL);
      return FALSE;
END GET_PRIMARY_REF_ITEM;
---------------------------------------------------------------------------------------------
FUNCTION OUTSTAND_ORDERS_EXIST(O_error_message IN OUT VARCHAR2,
                               O_exists        IN OUT BOOLEAN,
                               I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60)  := 'ITEM_ATTRIB_SQL.OUTSTAND_ORDERS_EXIST';
   L_exists    VARCHAR2(1)   := 'N';

   cursor C_ORDERS_EXIST is
      select 'Y'
        from ordloc l
       where l.item = I_item
         and l.qty_ordered > NVL(l.qty_received,0)
         and rownum = 1
       union
      select /*+ INDEX(l ORDLOC_I1) */
             'Y'
        from ordloc l
       where l.item in (select i.item
                              from item_master i
                             where i.item_parent      = I_item
                                or i.item_grandparent = I_item)
         and l.qty_ordered > NVL(l.qty_received,0)
         and rownum = 1;


BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ORDERS_EXIST','ORDSKU','Item: '||I_item);
   open C_ORDERS_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_ORDERS_EXIST','ORDSKU','Item: '||I_item);
   fetch C_ORDERS_EXIST into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_ORDERS_EXIST','ORDSKU','Item: '||I_item);
   close C_ORDERS_EXIST;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
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
END OUTSTAND_ORDERS_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION GET_ITEM_IND_ATTRIB(O_error_message        IN OUT VARCHAR2,
                             O_cost_zone_group_id   IN OUT ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE,
                             O_forecast_ind         IN OUT ITEM_MASTER.FORECAST_IND%TYPE,
                             O_merchandise_ind      IN OUT ITEM_MASTER.MERCHANDISE_IND%TYPE,
                             O_retail_label_type    IN OUT ITEM_MASTER.RETAIL_LABEL_TYPE%TYPE,
                             O_retail_label_value   IN OUT ITEM_MASTER.RETAIL_LABEL_VALUE%TYPE,
                             O_handling_temp        IN OUT ITEM_MASTER.HANDLING_TEMP%TYPE,
                             O_handling_sensitivity IN OUT ITEM_MASTER.HANDLING_SENSITIVITY%TYPE,
                             O_catch_weight_ind     IN OUT ITEM_MASTER.CATCH_WEIGHT_IND%TYPE,
                             O_waste_type           IN OUT ITEM_MASTER.WASTE_TYPE%TYPE,
                             O_waste_pct            IN OUT ITEM_MASTER.WASTE_PCT%TYPE,
                             O_default_waste_pct    IN OUT ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE,
                             O_package_size         IN OUT ITEM_MASTER.PACKAGE_SIZE%TYPE,
                             O_package_uom          IN OUT ITEM_MASTER.PACKAGE_UOM%TYPE,
                             O_check_uda_ind        IN OUT ITEM_MASTER.CHECK_UDA_IND%TYPE,
                             O_comments             IN OUT ITEM_MASTER.COMMENTS%TYPE,
                             I_item                 IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.GET_ITEM_IND_ATTRIB';

   cursor C_ITEM_IND_ATTRIB is
     select cost_zone_group_id,
            forecast_ind,
            merchandise_ind,
            retail_label_type,
            retail_label_value,
            handling_temp,
            handling_sensitivity,
            catch_weight_ind,
            waste_type,
            waste_pct,
            default_waste_pct,
            package_size,
            package_uom,
            check_uda_ind,
            comments
       from item_master
      where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM_IND_ATTRIB','ITEM_MASTER','ITEM: '||I_item);
   open C_ITEM_IND_ATTRIB;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM_IND_ATTRIB','ITEM_MASTER','ITEM: '||I_item);
   fetch C_ITEM_IND_ATTRIB into O_cost_zone_group_id,
                                O_forecast_ind,
                                O_merchandise_ind,
                                O_retail_label_type,
                                O_retail_label_value,
                                O_handling_temp,
                                O_handling_sensitivity,
                                O_catch_weight_ind,
                                O_waste_type,
                                O_waste_pct,
                                O_default_waste_pct,
                                O_package_size,
                                O_package_uom,
                                O_check_uda_ind,
                                O_comments;

   if C_ITEM_IND_ATTRIB%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_IND_ATTRIB','ITEM_MASTER','ITEM: '||I_item);
      close C_ITEM_IND_ATTRIB;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             null,
                                             null,
                                             null);
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_IND_ATTRIB','ITEM_MASTER','ITEM: '||I_item);
   close C_ITEM_IND_ATTRIB;

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             NULL);
      RETURN FALSE;
END GET_ITEM_IND_ATTRIB;
---------------------------------------------------------------------------------------------
FUNCTION GET_SIMPLE_PACK_IND (O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_simple_pack_ind  IN OUT ITEM_MASTER.SIMPLE_PACK_IND%TYPE,
                              I_item             IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.GET_SIMPLE_PACK_IND';

   cursor C_GET_SIMPLE_PACK_IND is
     select simple_pack_ind
        from item_master
       where item = I_item;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_SIMPLE_PACK_IND','ITEM_MASTER','item: '||I_item);
   open C_GET_SIMPLE_PACK_IND;
   SQL_LIB.SET_MARK('FETCH','C_GET_SIMPLE_PACK_IND','ITEM_MASTER','item: '||I_item);
   fetch C_GET_SIMPLE_PACK_IND into O_simple_pack_ind;
   SQL_LIB.SET_MARK('CLOSE','C_GET_SIMPLE_PACK_IND','ITEM_MASTER','item: '||I_item);
   close C_GET_SIMPLE_PACK_IND;

RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             NULL);
      RETURN FALSE;
END GET_SIMPLE_PACK_IND;
---------------------------------------------------------------------------------------------
FUNCTION GET_ITEM_MASTER (O_error_message         OUT  VARCHAR2,
                          O_item_record           OUT  ITEM_MASTER%ROWTYPE,
                          I_item                  IN   ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   cursor C_ITEM is
     select *
       from item_master
      where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   fetch C_ITEM into O_item_record;
   if C_ITEM%NOTFOUND then
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             null,
                                             null,
                                             null);*/
      --RIB error message enhancement
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            'item='||I_item,
                                            null,
                                            null);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
      close C_ITEM;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   close C_ITEM;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_ITEM_MASTER',
                                            to_char(SQLCODE));
   RETURN FALSE;
END GET_ITEM_MASTER;
---------------------------------------------------------------------------------------------
FUNCTION GET_TSF_FILL_SHIP_RECEIVED_QTY (O_error_message           IN OUT VARCHAR2,
                                         O_fill_qty_suom           IN OUT TSFDETAIL.FILL_QTY%TYPE,
                                         O_tsf_qty_suom            IN OUT TSFDETAIL.TSF_QTY%TYPE,
                                         O_ship_qty_suom           IN OUT TSFDETAIL.SHIP_QTY%TYPE,
                                         O_received_qty            IN OUT TSFDETAIL.RECEIVED_QTY%TYPE,
                                         O_reconciled_qty          IN OUT TSFDETAIL.RECONCILED_QTY%TYPE,
                                         I_tsf_no                  IN     TSFDETAIL.TSF_NO%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program         VARCHAR2(64) := 'ITEM_ATTRIB_SQL.GET_TSF_FILL_SHIP_RECEIVED_QTY';
   L_count           NUMBER(5) := 0;
   ---
   cursor c_standard_uom is
      select count(distinct standard_uom)
        from item_master
       where item
          in ( select item
                 from tsfdetail
                where tsf_no     = I_tsf_no);

   cursor c_quantities is
      select sum(fill_qty) fill_qty,
             sum(tsf_qty) tsf_qty,
             sum(ship_qty) ship_qty,
             sum(received_qty) received_qty,
             sum(reconciled_qty) reconciled_qty
        from tsfdetail
       where tsf_no = I_tsf_no;

 BEGIN

   open C_STANDARD_UOM;
   fetch C_STANDARD_UOM into L_count;
   close C_STANDARD_UOM;
   if L_count > 1 then
      O_error_message := SQL_LIB.CREATE_MSG('TOTALS_IF_SAME_SUOM',NULL,NULL,NULL);
      return FALSE;
   else
      open C_QUANTITIES;
      fetch C_QUANTITIES into O_fill_qty_suom,
                              O_tsf_qty_suom,
                              O_ship_qty_suom,
                              O_received_qty,
                              O_reconciled_qty;
      close C_QUANTITIES;
   end if;
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TSF_FILL_SHIP_RECEIVED_QTY;
-------------------------------------------------------------------------------
FUNCTION GET_MERCH_HIER(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                        O_division       IN OUT  DIVISION.DIVISION%TYPE,
                        O_div_name       IN OUT  DIVISION.DIV_NAME%TYPE,
                        O_group_no       IN OUT  GROUPS.GROUP_NO%TYPE,
                        O_group_name     IN OUT  GROUPS.GROUP_NAME%TYPE,
                        O_dept           IN OUT  ITEM_MASTER.DEPT%TYPE,
                        O_dept_name      IN OUT  DEPS.DEPT_NAME%TYPE,
                        O_class          IN OUT  ITEM_MASTER.CLASS%TYPE,
                        O_class_name     IN OUT  CLASS.CLASS_NAME%TYPE,
                        O_subclass       IN OUT  ITEM_MASTER.SUBCLASS%TYPE,
                        O_sub_name       IN OUT  SUBCLASS.SUB_NAME%TYPE,
                        I_item           IN      ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program  VARCHAR2(60) := 'ITEM_ATTRIB_SQL.GET_MERCH_HIER';

   cursor C_GET_MERCH_HIER is
      select dv.division,
             dv.div_name,
             gr.group_no,
             gr.group_name,
             dp.dept,
             dp.dept_name,
             cl.class,
             cl.class_name,
             sc.subclass,
             sc.sub_name
        from division    dv,
             groups      gr,
             deps        dp,
             class       cl,
             subclass    sc,
             item_master im
       where im.item     = I_item
         and sc.subclass = im.subclass
         and sc.class    = im.class
         and sc.dept     = im.dept
         and cl.class    = im.class
         and cl.dept     = im.dept
         and dp.dept     = im.dept
         and gr.group_no = dp.group_no
         and dv.division = gr.division;


BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   open  C_GET_MERCH_HIER;
   fetch C_GET_MERCH_HIER into O_division,
                               O_div_name,
                               O_group_no,
                               O_group_name,
                               O_dept,
                               O_dept_name,
                               O_class,
                               O_class_name,
                               O_subclass,
                               O_sub_name;
   close C_GET_MERCH_HIER;

   if O_div_name is NOT NULL then
      if LANGUAGE_SQL.TRANSLATE(O_div_name,
                                O_div_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if O_group_name is NOT NULL then
      if LANGUAGE_SQL.TRANSLATE(O_group_name,
                                O_group_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if O_dept_name is NOT NULL then
      if LANGUAGE_SQL.TRANSLATE(O_dept_name,
                                O_dept_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if O_class_name is NOT NULL then
      if LANGUAGE_SQL.TRANSLATE(O_class_name,
                                O_class_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if O_sub_name is NOT NULL then
      if LANGUAGE_SQL.TRANSLATE(O_sub_name,
                                O_sub_name,
                                O_error_message) = FALSE then
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
END GET_MERCH_HIER;
-------------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message         IN OUT  VARCHAR2,
                  O_item_desc             IN OUT  ITEM_MASTER.ITEM_DESC%TYPE,
                  O_item_level            IN OUT  ITEM_MASTER.ITEM_LEVEL%TYPE,
                  O_tran_level            IN OUT  ITEM_MASTER.TRAN_LEVEL%TYPE,
                  O_status                IN OUT  ITEM_MASTER.STATUS%TYPE,
                  O_pack_ind              IN OUT  ITEM_MASTER.PACK_IND%TYPE,
                  O_division              IN OUT  DIVISION.DIVISION%TYPE,
                  O_div_name              IN OUT  DIVISION.DIV_NAME%TYPE,
                  O_group_no              IN OUT  GROUPS.GROUP_NO%TYPE,
                  O_group_name            IN OUT  GROUPS.GROUP_NAME%TYPE,
                  O_dept                  IN OUT  ITEM_MASTER.DEPT%TYPE,
                  O_dept_name             IN OUT  DEPS.DEPT_NAME%TYPE,
                  O_class                 IN OUT  ITEM_MASTER.CLASS%TYPE,
                  O_class_name            IN OUT  CLASS.CLASS_NAME%TYPE,
                  O_subclass              IN OUT  ITEM_MASTER.SUBCLASS%TYPE,
                  O_subclass_name         IN OUT  SUBCLASS.SUB_NAME%TYPE,
                  O_retail_zone_group_id  IN OUT  ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                  O_sellable_ind          IN OUT  ITEM_MASTER.SELLABLE_IND%TYPE,
                  O_orderable_ind         IN OUT  ITEM_MASTER.ORDERABLE_IND%TYPE,
                  O_pack_type             IN OUT  ITEM_MASTER.PACK_TYPE%TYPE,
                  O_item_parent           IN OUT  ITEM_MASTER.ITEM_PARENT%TYPE,
                  O_item_number_type      IN OUT  ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                  I_item                  IN      ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   --- Dummy variables for the call to the longer GET_INFO function
   L_diff_1               ITEM_MASTER.DIFF_1%TYPE;
   L_diff_1_desc          V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_1_type          V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_1_id_group_ind  V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_diff_2               ITEM_MASTER.DIFF_2%TYPE;
   L_diff_2_desc          V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE;
   L_diff_2_type          V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_2_id_group_ind  V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_order_as_type        ITEM_MASTER.ORDER_AS_TYPE%TYPE;
   L_format_id            ITEM_MASTER.FORMAT_ID%TYPE;
   L_prefix               ITEM_MASTER.PREFIX%TYPE;
   L_contains_inner_ind   ITEM_MASTER.CONTAINS_INNER_IND%TYPE;
   L_store_ord_mult       ITEM_MASTER.STORE_ORD_MULT%TYPE;
   L_simple_pack_ind      ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_waste_type           ITEM_MASTER.WASTE_TYPE%TYPE;
   L_item_grandparent     ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_short_desc           ITEM_MASTER.SHORT_DESC%TYPE;
   L_waste_pct            ITEM_MASTER.WASTE_PCT%TYPE;
   L_default_waste_pct    ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE;
   L_dept                 ITEM_MASTER.DEPT%TYPE;
   L_dept_name            DEPS.DEPT_NAME%TYPE;
   L_class                ITEM_MASTER.CLASS%TYPE;
   L_class_name           CLASS.CLASS_NAME%TYPE;
   L_subclass             ITEM_MASTER.SUBCLASS%TYPE;
   L_sub_name             SUBCLASS.SUB_NAME%TYPE;

BEGIN
   if GET_INFO(O_error_message,
               O_item_desc,
               O_item_level,
               O_tran_level,
               O_status,
               O_pack_ind,
               O_dept,
               O_dept_name,
               O_class,
               O_class_name,
               O_subclass,
               O_subclass_name,
               O_retail_zone_group_id,
               O_sellable_ind,
               O_orderable_ind,
               O_pack_type,
               L_simple_pack_ind,
               L_waste_type,
               O_item_parent,
               L_item_grandparent,
               L_short_desc,
               L_waste_pct,
               L_default_waste_pct,
               O_item_number_type,
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
   if GET_MERCH_HIER(O_error_message,
                     O_division,
                     O_div_name,
                     O_group_no,
                     O_group_name,
                     L_dept,
                     L_dept_name,
                     L_class,
                     L_class_name,
                     L_subclass,
                     L_sub_name,
                     I_item) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_INFO',
                                            to_char(SQLCODE));
   return FALSE;
END GET_INFO;
-------------------------------------------------------------------------------
FUNCTION GET_API_INFO(O_error_message   IN OUT          VARCHAR2,
                      O_api_item_rec    OUT    NOCOPY   API_ITEM_REC,
                      I_item            IN              ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   cursor C_ITEM is
     select item,
            dept,
            class,
            subclass,
            item_level,
            tran_level,
            status,
            pack_ind,
            sellable_ind,
            orderable_ind,
            pack_type,
            order_as_type,
            standard_uom,
            simple_pack_ind,
            contains_inner_ind,
            retail_zone_group_id,
            cost_zone_group_id,
            item_parent
       from item_master
      where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   fetch C_ITEM into O_api_item_rec;

   if C_ITEM%NOTFOUND then
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM', NULL, NULL, NULL);*/
      --RIB error message enhancement
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            'item='||I_item,
                                            null,
                                            null);
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
      close C_ITEM;
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM','ITEM_MASTER','ITEM: '||I_item);
   close C_ITEM;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.GET_API_INFO',
                                            to_char(SQLCODE));
   return FALSE;
END GET_API_INFO;
-------------------------------------------------------------------------------
FUNCTION ITEM_SUBQUERY(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_subquery          OUT VARCHAR2,
                       I_item_level     IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                       I_tran_level     IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                       I_diff_column    IN     VARCHAR2,
                       I_main_tab_item  IN     VARCHAR2,
                       I_item_bind_no   IN     VARCHAR,
                       I_diff_bind_no   IN     VARCHAR2,
                       I_include_parent IN     BOOLEAN)
RETURN BOOLEAN AS

   L_program         VARCHAR2(60) := 'ITEM_ATTRIB_SQL.ITEM_SUBQUERY';
   L_subquery        VARCHAR2(2000);
   L_diff_condition  VARCHAR2(1000);
   L_item_field_name VARCHAR2(20);

BEGIN
   --Create a diff sub query if diff id is passed in.  Only expecting to add
   --on diff ids, not groups, to limit item search.
   if I_diff_column is NOT NULL then
      L_diff_condition := ' im.'||I_diff_column||' = :'||I_diff_bind_no||' ';
   end if;

   if I_tran_level - I_item_level = 2 then
      L_item_field_name := 'im.item_grandparent';
   elsif I_tran_level - I_item_level = 1 then
      L_item_field_name := 'im.item_parent';
   elsif I_tran_level = I_item_level then
      L_item_field_name := 'im.item';
   end if;

   --Build query based on level of item coming in,
   --always selecting tran level items.  Have ability
   --to add on a passed in table column to join to item
   L_subquery := ' select item '||
                   ' from item_master im '||
                  ' where '||L_item_field_name||' = :'||I_item_bind_no;

   if I_main_tab_item is not null then
      L_subquery := L_subquery || ' and im.item = '||I_main_tab_item ||
                    ' and rownum = 1 ';
   end if;

   if L_diff_condition is NOT NULL then
      L_subquery := L_subquery || ' and '||L_diff_condition||' ';
   end if;

   --if include parent is passed in, then the query
   --will return tran level item(s) plus parent and/or
   --grandparent item depending on item level passed in.
   if I_include_parent then
      if I_tran_level - I_item_level = 2 then
         L_subquery := L_subquery ||
          ' union all '||
         ' select item '||
           ' from item_master im '||
          ' where im.item = :'||I_item_bind_no;

         if I_main_tab_item is not null then
            L_subquery := L_subquery || ' and im.item = '||I_main_tab_item ||
                          ' and rownum = 1 ';
         end if;

         L_subquery := L_subquery ||
          ' union all '||
         ' select item '||
           ' from item_master im '||
          ' where im.item_parent = :'||I_item_bind_no;

         if I_main_tab_item is not null then
            L_subquery := L_subquery || ' and im.item = '||I_main_tab_item ||
                          ' and rownum = 1 ';
         end if;

         if L_diff_condition is NOT NULL then
            L_subquery := L_subquery || ' and '||L_diff_condition||' ';
         end if;

      elsif I_tran_level - I_item_level = 1 then
         L_subquery := L_subquery ||
         '  union all '||
         ' select item '||
           ' from item_master im '||
          ' where im.item = :'||I_item_bind_no||' ';

         if I_main_tab_item is not null then
            L_subquery := L_subquery || ' and im.item = '||I_main_tab_item ||
                          ' and rownum = 1 ';
         end if;
      end if;
   end if;

   O_subquery := L_subquery;
   ---

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_SUBQUERY;
-------------------------------------------------------------------------------
FUNCTION ITEM_SUBQUERY(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_subquery          OUT VARCHAR2,
                       I_item_level     IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                       I_tran_level     IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                       I_diff_column    IN     VARCHAR2,
                       I_item_bind_no   IN     VARCHAR,
                       I_diff_bind_no   IN     VARCHAR2,
                       I_include_parent IN     BOOLEAN)
RETURN BOOLEAN AS

   L_program         VARCHAR2(60) := 'ITEM_ATTRIB_SQL.ITEM_SUBQUERY';
   L_subquery        VARCHAR2(2000);
   L_diff_condition  VARCHAR2(1000);
   L_item_field_name VARCHAR2(20);

BEGIN
   --Create a diff sub query if diff id is passed in.  Only expecting to add
   --on diff ids, not groups, to limit item search.
   if I_diff_column is NOT NULL then
      L_diff_condition := ' im.'||I_diff_column||' = :'||I_diff_bind_no||' ';
   end if;

   if I_tran_level - I_item_level = 2 then
      L_item_field_name := 'im.item_grandparent';
   elsif I_tran_level - I_item_level = 1 then
      L_item_field_name := 'im.item_parent';
   elsif I_tran_level = I_item_level then
      L_item_field_name := 'im.item';
   end if;

   --Build query based on level of item coming in,
   --always selecting tran level items.  Have ability
   --to add on a passed in table column to join to item
   L_subquery := ' select im.item '||
                   ' from item_master im '||
                  ' where ('||L_item_field_name||' = :'||I_item_bind_no;

   --if include parent is passed in, then the query
   --will return tran level item(s) plus parent and/or
   --grandparent item depending on item level passed in.
   if I_include_parent then
      if I_tran_level - I_item_level = 2 then
         L_subquery := L_subquery ||
          ' or im.item = :'||I_item_bind_no ||
          ' or im.item_parent = :'||I_item_bind_no || ')';

      elsif I_tran_level - I_item_level = 1 then
         L_subquery := L_subquery ||
          ' or im.item = :'||I_item_bind_no || ')';
      else
         L_subquery := L_subquery || ')';
      end if;
   else
      L_subquery := L_subquery || ')';
   end if;

   if L_diff_condition is NOT NULL then
      L_subquery := L_subquery || ' and '||L_diff_condition||' ';
   end if;

   O_subquery := L_subquery;
   ---

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_SUBQUERY;
-------------------------------------------------------------------------------
FUNCTION PACK_SUBQUERY(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                       O_subquery       OUT      VARCHAR2,
                       I_isc_exist      IN       BOOLEAN,
                       I_xpack_count    IN       NUMBER)

RETURN BOOLEAN AS

   L_program  VARCHAR2(60) := 'ITEM_ATTRIB_SQL.PACK_SUBQUERY';

BEGIN
    O_subquery := ' select /*+ cardinality(xpack ' || I_xpack_count || ') */ ' ||
                         ' distinct p.pack_no '||
                        ' from packitem p, '||
                        ' item_master im, '||
                        ' TABLE(cast(:1 as ITEM_TBL))xpack '||
                  ' where p.pack_no = im.item '||
                    ' and im.pack_type = ''B'' '||
                    ' and im.orderable_ind = ''Y'' '||
                    ' and p.item = value(xpack) ';

   if I_isc_exist then
      O_subquery := O_subquery || ' and exists (select ''x'' '||
                                  '               from item_supp_country sc '||
                                  '              where sc.item = p.pack_no '||
                                  '                and sc.supplier = :2 '||
                                  '                and sc.origin_country_id = :3 '||
                                  '                and rownum = 1) ';
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;
END PACK_SUBQUERY;
-------------------------------------------------------------------------------
FUNCTION ITEM_DIFF_EXISTS(O_error_message   IN OUT   VARCHAR2,
                          O_exists          OUT      BOOLEAN,
                          O_diff_column     OUT      VARCHAR2,
                          I_item            IN       ITEM_MASTER.ITEM%TYPE,
                          I_diff_id         IN       DIFF_IDS.DIFF_ID%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.VALIDATE_ITEM_DIFF';
   L_diff_1     ITEM_MASTER.DIFF_1%TYPE;
   L_diff_2     ITEM_MASTER.DIFF_2%TYPE;
   L_diff_3     ITEM_MASTER.DIFF_3%TYPE;
   L_diff_4     ITEM_MASTER.DIFF_4%TYPE;

   cursor C_EXISTS IS
      select diff_1,
             diff_2,
             diff_3,
             diff_4
        from item_master
       where (item_parent      = I_item
          or  item_grandparent = I_item)
         and (diff_1 = I_diff_id
          or  diff_2 = I_diff_id
          or  diff_3 = I_diff_id
          or  diff_4 = I_diff_id);

BEGIN
   ---
   if I_item is NULL or I_diff_id is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_item,I_diff_id','NULL','NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_EXISTS','ITEM_MASTER','Item: '||I_item);
   open C_EXISTS;

   SQL_LIB.SET_MARK('FETCH', 'C_EXISTS','ITEM_MASTER','Item: '||I_item);
   fetch C_EXISTS into L_diff_1,
                       L_diff_2,
                       L_diff_3,
                       L_diff_4;

   if C_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_EXITS','ITEM_MASTER','Item: '||I_item);
   close C_EXISTS;

   if L_diff_1 = I_diff_id then
      O_diff_column := 'diff_1';
   elsif L_diff_2 = I_diff_id then
      O_diff_column := 'diff_2';
   elsif L_diff_3 = I_diff_id then
      O_diff_column := 'diff_3';
   elsif L_diff_4 = I_diff_id then
      O_diff_column := 'diff_4';
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         L_program,
                         NULL);
   RETURN FALSE;
END ITEM_DIFF_EXISTS;
-------------------------------------------------------------------------------------------------------
FUNCTION GET_PACKS_FOR_ITEM(O_error_message   IN OUT          RTK_ERRORS.RTK_TEXT%TYPE,
                            O_pack_items      OUT    NOCOPY   ITEM_TBL,
                            I_item            IN              ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_ATTRIB_SQL.GET_PACKS_FOR_ITEM';

   cursor C_PACKS is
      select a.pack_no
        from packitem_breakout a
       where not exists (select b.pack_no
                           from packitem_breakout b,
                                item_master im2
                          where im2.item = b.item
                            and (NVL(im2.item_grandparent, '-999') != I_item)
                            and (NVL(im2.item_parent, '-999') != I_item)
                            and (NVL(im2.item, '-999') != I_item)
                            and b.pack_no = a.pack_no)
       group by a.pack_no;

BEGIN
   O_pack_items := ITEM_TBL();

   FOR rec in C_PACKS LOOP

      O_pack_items.extend();
      O_pack_items(O_pack_items.COUNT) := rec.pack_no;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_PACKS_FOR_ITEM;
-------------------------------------------------------------------------------------------------------
FUNCTION BUILD_TRAN_LEVEL_ITEMS(O_error_message       IN OUT          RTK_ERRORS.RTK_TEXT%TYPE,
                                O_items                  OUT NOCOPY   ITEM_TBL,
                                I_item                IN              ITEM_MASTER.ITEM%TYPE,
                                I_diff_id             IN              DIFF_IDS.DIFF_ID%TYPE,
                                I_tran_level          IN              ITEM_MASTER.TRAN_LEVEL%TYPE,
                                I_item_level          IN              ITEM_MASTER.ITEM_LEVEL%TYPE,
                                I_diff_column         IN              DIFF_IDS.DIFF_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50)  := 'ITEM_ATTRIB_SQL.BUILD_TRAN_LEVEL_ITEMS';
   L_subquery  VARCHAR2(2000);

   L_item_field_name  VARCHAR2(20) := NULL;
   L_item_bind_no     VARCHAR2(1) := '1';
   L_diff_bind_no     VARCHAR2(1) := '2';

BEGIN
   -- This function will only return tran level items.

   if I_tran_level - I_item_level = 2 then
      L_item_field_name := 'im.item_grandparent';
   elsif I_tran_level - I_item_level = 1 then
      L_item_field_name := 'im.item_parent';
   elsif I_tran_level = I_item_level then
      L_item_field_name := 'im.item';
   end if;

   --always selecting tran level items based on the level of item coming in
   L_subquery := ' select im.item '||
                   ' from item_master im '||
                  ' where '||L_item_field_name||' = :'||L_item_bind_no;

   if I_diff_id is NOT NULL then
      L_subquery := L_subquery ||
                   ' and (' || I_diff_column || ' = :' || L_diff_bind_no ||
                    ' or exists (select ''x''' ||
                                 ' from diff_group_detail' ||
                                ' where diff_group_id = :' || L_diff_bind_no ||
                                  ' and diff_id = im.' || I_diff_column ||'))';

      EXECUTE IMMEDIATE L_subquery bulk collect into O_items
         USING I_item,    -- Item, Item Parent or Item Grandparent
               I_diff_id, -- Diff ID
               I_diff_id; -- Diff Group ID
   else
      EXECUTE IMMEDIATE L_subquery bulk collect into O_items
         USING I_item;  -- Item, Item Parent or Item Grandparent
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END BUILD_TRAN_LEVEL_ITEMS;
-------------------------------------------------------------------------------------------------------
FUNCTION BUILD_PARENT_LEVEL_ITEMS(O_error_message       IN OUT          RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_items                  OUT NOCOPY   ITEM_TBL,
                                  I_item                IN              ITEM_MASTER.ITEM%TYPE,
                                  I_diff_id             IN              DIFF_IDS.DIFF_ID%TYPE,
                                  I_tran_level          IN              ITEM_MASTER.TRAN_LEVEL%TYPE,
                                  I_item_level          IN              ITEM_MASTER.ITEM_LEVEL%TYPE,
                                  I_diff_column         IN              DIFF_IDS.DIFF_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50)  := 'ITEM_ATTRIB_SQL.BUILD_PARENT_LEVEL_ITEMS';
   L_subquery  VARCHAR2(2000);

   L_item_bind_no     VARCHAR2(1) := '1';
   L_diff_bind_no     VARCHAR2(1) := '2';

BEGIN
   -- This function will only return parent level items.

   if I_tran_level = I_item_level then
      return TRUE;
   end if;

   L_subquery := ' select item '||
                   ' from item_master im '||
                  ' where im.item = :'||L_item_bind_no;

   if I_tran_level - I_item_level = 2 then
      L_subquery := L_subquery ||
                    ' union all '||
                    ' select item '||
                      ' from item_master im '||
                     ' where im.item_parent = :'||L_item_bind_no;
   end if;

   if I_diff_id is NOT NULL then
      L_subquery := L_subquery ||
                   ' and (' || I_diff_column || ' = :' || L_diff_bind_no ||
                    ' or exists (select ''x''' ||
                                 ' from diff_group_detail' ||
                                ' where diff_group_id = :' || L_diff_bind_no ||
                                  ' and diff_id = im.' || I_diff_column ||'))';

      if I_tran_level - I_item_level = 2 then
         EXECUTE IMMEDIATE L_subquery bulk collect into O_items
            USING I_item,    -- Item
                  I_item,    -- Item Parent
                  I_diff_id, -- Diff ID
                  I_diff_id; -- Diff Group ID
      elsif I_tran_level - I_item_level = 1 then
         EXECUTE IMMEDIATE L_subquery bulk collect into O_items
            USING I_item,    -- Item
                  I_diff_id, -- Diff ID
                  I_diff_id; -- Diff Group ID
      end if;
   else
      if I_tran_level - I_item_level = 2 then
         EXECUTE IMMEDIATE L_subquery bulk collect into O_items
            USING I_item,    -- Item
                  I_item;    -- Item Parent
      elsif I_tran_level - I_item_level = 1 then
         EXECUTE IMMEDIATE L_subquery bulk collect into O_items
            USING I_item;    -- Item
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
END BUILD_PARENT_LEVEL_ITEMS;
-------------------------------------------------------------------------------------------------------
FUNCTION BUILD_API_ITEM_TEMP(O_error_message       IN OUT          RTK_ERRORS.RTK_TEXT%TYPE,
                             I_item                IN              ITEM_MASTER.ITEM%TYPE,
                             I_diff_id             IN              DIFF_IDS.DIFF_ID%TYPE,
                             I_tran_level          IN              ITEM_MASTER.TRAN_LEVEL%TYPE,
                             I_item_level          IN              ITEM_MASTER.ITEM_LEVEL%TYPE,
                             I_diff_column         IN              DIFF_IDS.DIFF_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50)  := 'ITEM_ATTRIB_SQL.BUILD_API_ITEM_TEMP';
   L_subquery  VARCHAR2(2000);

   L_item_bind_no   VARCHAR2(1) := '1';
   L_diff_bind_no   VARCHAR2(1) := '2';

BEGIN

   L_subquery := 'insert into api_item_temp ' ||
                 ' select item '||
                   ' from item_master im '||
                  ' where im.item = :'||L_item_bind_no;

   if I_tran_level - I_item_level = 2 then
      L_subquery := L_subquery ||
                    ' union all '||
                    ' select item '||
                      ' from item_master im '||
                     ' where im.item_parent = :'||L_item_bind_no ||
                   '  union all '||
                    ' select item '||
                      ' from item_master im '||
                     ' where im.item_grandparent = :'||L_item_bind_no;

   elsif I_tran_level - I_item_level = 1 then
      L_subquery := L_subquery ||
                    ' union all '||
                    ' select item '||
                      ' from item_master im '||
                     ' where im.item_parent = :'||L_item_bind_no;
   end if;

   if I_diff_id is NOT NULL then
      L_subquery := L_subquery ||
                   ' and (' || I_diff_column || ' = :' || L_diff_bind_no ||
                    ' or exists (select ''x''' ||
                                 ' from diff_group_detail' ||
                                ' where diff_group_id = :' || L_diff_bind_no ||
                                  ' and diff_id = im.' || I_diff_column ||'))';

      if I_tran_level - I_item_level = 2 then
         EXECUTE IMMEDIATE L_subquery
            USING I_item,    -- Item
                  I_item,    -- Item Parent
                  I_item,    -- Item Grandparent
                  I_diff_id, -- Diff ID
                  I_diff_id; -- Diff Group ID

      elsif I_tran_level - I_item_level = 1 then
         EXECUTE IMMEDIATE L_subquery
            USING I_item,    -- Item
                  I_item,    -- Item Parent
                  I_diff_id, -- Diff ID
                  I_diff_id; -- Diff Group ID
      else
         EXECUTE IMMEDIATE L_subquery
            USING I_item,    -- Item
                  I_diff_id, -- Diff ID
                  I_diff_id; -- Diff Group ID
      end if;

   else
      if I_tran_level - I_item_level = 2 then
         EXECUTE IMMEDIATE L_subquery
            USING I_item,    -- Item
                  I_item,    -- Item Parent
                  I_item;    -- Item Grandparent

      elsif I_tran_level - I_item_level = 1 then
         EXECUTE IMMEDIATE L_subquery
            USING I_item,    -- Item
                  I_item;    -- Item Parent

      else
         EXECUTE IMMEDIATE L_subquery
            USING I_item;
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

END BUILD_API_ITEM_TEMP;

-------------------------------------------------------------------------------------------------------
FUNCTION GET_ITEM_TYPE (O_error_message       IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                        O_item_type_code         OUT  VARCHAR2                ,
                        I_item                IN      ITEM_MASTER.ITEM%TYPE    )
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50)  := 'ITEM_ATTRIB_SQL.GET_ITEM_TYPE';


   L_item   ITEM_MASTER%ROWTYPE ;

BEGIN
   if GET_ITEM_MASTER (O_error_message   ,
                       L_item            ,
                       I_item            ) = FALSE then
      return FALSE;
   end if;
   if L_item.sellable_ind       IN ('Y','N')
      and L_item.orderable_ind      = 'Y'
      and L_item.inventory_ind      = 'Y'
      and L_item.pack_ind           = 'Y'
      and L_item.simple_pack_ind    = 'Y'
      and L_item.item_xform_ind     = 'N'
      and L_item.deposit_item_type  IS NULL then
      O_item_type_code := 'S' ;
   elsif  L_item.sellable_ind       IN ('Y','N')
      and L_item.orderable_ind      IN ('Y','N')
      and L_item.inventory_ind      = 'Y'
      and L_item.pack_ind           = 'Y'
      and L_item.simple_pack_ind    = 'N'
      and L_item.item_xform_ind     = 'N'
      and (   L_item.deposit_item_type  IS NULL
           or L_item.deposit_item_type  = 'P') then
      O_item_type_code := 'C' ;
   elsif  L_item.sellable_ind       = 'Y'
      and L_item.orderable_ind      = 'Y'
      and L_item.inventory_ind      = 'Y'
      and L_item.pack_ind           = 'N'
      and L_item.simple_pack_ind    = 'N'
      and L_item.item_xform_ind     = 'N'
      and L_item.deposit_item_type  = 'E' then
      O_item_type_code := 'E' ;
   elsif  L_item.sellable_ind       = 'Y'
      and L_item.orderable_ind      = 'N'
      and L_item.inventory_ind      = 'N'
      and L_item.pack_ind           = 'N'
      and L_item.simple_pack_ind    = 'N'
      and L_item.item_xform_ind     = 'N'
      and L_item.deposit_item_type  = 'A' then
      O_item_type_code := 'A' ;
   elsif  L_item.sellable_ind       IN ('Y','N')
      and L_item.orderable_ind      = 'Y'
      and L_item.inventory_ind      = 'Y'
      and L_item.pack_ind           = 'N'
      and L_item.simple_pack_ind    = 'N'
      and L_item.item_xform_ind     = 'N'
      and L_item.deposit_item_type  = 'Z' then
      O_item_type_code := 'Z' ;
   elsif  L_item.sellable_ind       = 'Y'
      and L_item.orderable_ind      = 'N'
      and L_item.inventory_ind      = 'Y'
      and L_item.pack_ind           = 'N'
      and L_item.simple_pack_ind    = 'N'
      and L_item.item_xform_ind     = 'N'
      and L_item.deposit_item_type  = 'T' then
      O_item_type_code := 'T' ;
   elsif  L_item.sellable_ind       = 'Y'
      and L_item.orderable_ind      = 'N'
      and L_item.inventory_ind      = 'N'
      and L_item.pack_ind           = 'N'
      and L_item.simple_pack_ind    = 'N'
      and L_item.item_xform_ind     = 'N'
      and L_item.deposit_item_type  IS NULL then
      O_item_type_code := 'I' ;
   elsif  L_item.sellable_ind       = 'N'
      and L_item.orderable_ind      = 'Y'
      and L_item.inventory_ind      = 'Y'
      and L_item.pack_ind           = 'N'
      and L_item.simple_pack_ind    = 'Y'
      and L_item.item_xform_ind     = 'N'
      and L_item.deposit_item_type  IS NULL then
      O_item_type_code := 'O' ;
   elsif  L_item.sellable_ind       = 'Y'
      and L_item.orderable_ind      = 'N'
      and L_item.inventory_ind      = 'N'
      and L_item.pack_ind           = 'N'
      and L_item.simple_pack_ind    = 'N'
      and L_item.item_xform_ind     = 'Y'
      and L_item.deposit_item_type  IS NULL then
      O_item_type_code := 'L' ;
   elsif  L_item.sellable_ind       IN ('Y','N')
      and L_item.orderable_ind      IN ('Y','N')
      and L_item.inventory_ind      IN ('Y','N')
      and L_item.pack_ind           = 'N'
      and L_item.simple_pack_ind    = 'N'
      and L_item.item_xform_ind     = 'N'
      and L_item.deposit_item_type  IS NULL then
      O_item_type_code := 'R' ;
   else
      O_item_type_code := NULL ;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END GET_ITEM_TYPE;
-------------------------------------------------------------------------------------------------------
FUNCTION NEXT_EAN(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                  O_ean13           IN OUT   ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(25) := 'ITEM_ATTRIB_SQL.NEXT_EAN';
   L_ean_nextval            NUMBER(6);
   L_check_digit            NUMBER;
   L_valid_ean              BOOLEAN;
   L_item_record            ITEM_MASTER%ROWTYPE;
   L_system_options         SYSTEM_OPTIONS%ROWTYPE;
   L_wrap_sequence_number   ORDHEAD.ORDER_NO%TYPE;
   L_first_time             VARCHAR2(3) := 'Yes';

   L_found                  varchar2(1);

   CURSOR C_CHK_ITEM ( c_ean IN item_master.item%TYPE ) IS
   select 'x'
   from item_master
   where item = c_ean;

BEGIN

   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_system_options) = FALSE then
      return FALSE;
   end if;

   ---

      O_ean13 := L_system_options.auto_ean13_prefix * 1000000;

      select EAN13_SEQ.NEXTVAL
        into L_ean_nextval
        from dual;

      if (L_first_time = 'Yes') then
         L_wrap_sequence_number := L_ean_nextval;
         L_first_time := 'No';
      elsif (L_ean_nextval = L_wrap_sequence_number) then
         O_error_message := SQL_LIB.CREATE_MSG('NO_SEQ_NO_AVAIL',
                                               NULL,
                                               NULL,
                                               NULL);
         return FALSE;
      end if;

      ---

      O_ean13 := O_ean13 + L_ean_nextval;

      if length(O_ean13) < 12 then
         O_ean13 := lpad(O_ean13,12,'0');
      end if;

      FOR dig in 0..9 LOOP
         O_ean13 := substr(O_ean13, 1, 12) || dig;

      if ITEM_NUMBER_TYPE_SQL.VALIDATE_FORMAT(O_error_message,
                                              O_ean13,
                                              'EAN13') then
         open C_CHK_ITEM ( O_ean13 );
         fetch C_CHK_ITEM into L_found;
         if C_CHK_ITEM%NOTFOUND then
            CLOSE C_CHK_ITEM;
            EXIT;
         end if;
         close c_chk_item;

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
END NEXT_EAN;
------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 24-Sep-2007
-- Mod Ref    : Mod number. N105
-- Mod Details: Modified function DELETE_EAN to return the reference number back of EANOWN
--              to RNA before deleting from ITEM_MASTER table.Everywhere the code has been modified
--              to add the number type of EANOWN also alongwith EAN13
-------------------------------------------------------------------------------------------------------
FUNCTION DELETE_EAN(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                    I_parent_item     IN       ITEM_MASTER.ITEM%TYPE,
                    I_supplier        IN       SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(26) := 'ITEM_ATTRIB_SQL.DELETE_EAN';
   L_items         ITEM_TBL     := ITEM_TBL();
   L_table         VARCHAR2(25);
   -- Mod N105 (Drop 2), 24-Sep-2007, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   L_consumer_unit ITEM_MASTER.TSL_CONSUMER_UNIT%TYPE;
   -- Mod N105 (Drop 2), 24-Sep-2007, Nitin Gour, nitin.gour@in.tesco.com (END)
   /* Defect NBS00011072 Raghuveer P R 4-Feb-2008 - Begin */
   L_item          ITEM_MASTER.ITEM%TYPE;
   /* Defect NBS00011072 Raghuveer P R 4-Feb-2008 - End */
   RECORD_LOCKED   EXCEPTION;

   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_APPROVAL_ERROR is
      select 'x'
        from item_approval_error iae
       where exists (select 'x'
                       from item_master im,
                            code_detail cd
                      where cd.code_type        = 'EANT'
                        and im.item_number_type = cd.code
                        and im.item_parent      = I_parent_item
                        and im.item             = iae.item
                        and rownum              = 1)
         for update nowait;


   ---

   cursor C_LOCK_ITEM_SUPPLIER is
      select 'x'
        from item_supplier isu
       where (    isu.supplier = I_supplier
               or I_supplier is null )
         and exists (select 'x'
                       from item_master im,
                            code_detail cd
                      where cd.code_type        = 'EANT'
                        and im.item_number_type = cd.code
                        and im.item_parent      = I_parent_item
                        and im.item             = isu.item
                        and rownum              = 1)
         for update nowait;
   ---
   cursor C_LOCK_ITEM_MASTER is
      select 'x'
        from item_master im,
             code_detail cd
       where cd.code_type        = 'EANT'
         and im.item_parent      = I_parent_item
         and im.item_number_type = cd.code
         and im.item_level       = 3
         for update nowait;
   ---
   cursor C_GET_ITEM_TYPE is
      select im.item,
             im.item_number_type
        from item_master im,
             code_detail cd
       where cd.code_type        = 'EANT'
         and im.item_parent      = I_parent_item
         and im.item_number_type = cd.code
         and im.item_level       = 3
         for update nowait;
   ---
   cursor C_GET_RNA_ITEMS is
      select im.item,
             im.item_number_type
        from item_master im,
             code_detail cd,
             code_detail cd1
       where im.item_parent      = I_parent_item
         and im.item_number_type = cd1.code
         and im.item_level       = 3
         and cd1.code            = cd.code
         and cd1.code_type       = 'EANT'
         and cd.code_type        in ('RNA1','RNA2')
         for update nowait;

   L_item_type C_GET_RNA_ITEMS%ROWTYPE;

   ---
BEGIN

   if I_parent_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_parent_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   L_table := 'ITEM_APPROVAL_ERROR';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ITEM_APPROVAL_ERROR',
                    L_table,
                    'I_parent_item '||I_parent_item);
   open C_LOCK_ITEM_APPROVAL_ERROR;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ITEM_APPROVAL_ERROR',
                    L_table,
                   'I_parent_item '||I_parent_item);
   close C_LOCK_ITEM_APPROVAL_ERROR;
   ---
   L_table := 'ITEM_SUPPLIER';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ITEM_SUPPLIER',
                    L_table,
                    'I_supplier '||I_supplier);
   open C_LOCK_ITEM_SUPPLIER;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ITEM_SUPPLIER',
                    L_table,
                    'I_supplier '||I_supplier);
   close C_LOCK_ITEM_SUPPLIER;
   ---
   L_table := 'ITEM_MASTER';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ITEM_MASTER',
                    L_table,
                    'I_parent_item '||I_parent_item);
   open C_LOCK_ITEM_MASTER;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ITEM_MASTER',
                    L_table,
                    'I_parent_item '||I_parent_item);
   close C_LOCK_ITEM_MASTER;
   ---
   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'item_approval_error',
                    'I_parent_item '||I_parent_item);
   delete from item_approval_error iae
    where exists (select 'x'
                    from item_master im,
                         code_detail cd
                   where cd.code_type = 'EANT'
                     and im.item_number_type = cd.code
                     and im.item_parent      = I_parent_item
                     and im.item             = iae.item
                     and rownum              = 1);
   ---
   --if I_supplier is not null then
   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'item_supplier',
                    'I_supplier '||I_supplier);
   delete from item_supplier isu
    where (   isu.supplier = I_supplier
           or I_supplier is null )
      and exists (select 'x'
                    from item_master m2,
                         code_detail cd
                   where cd.code_type = 'EANT'
                     and m2.item_number_type  = cd.code
                     and m2.item_parent      = I_parent_item
                     and m2.item             = isu.item
                     and rownum              = 1);
   --end if;
   ---
   /* Defect NBS00011072 Raghuveer P R 4-Feb-2008 - Begin */
   FOR C_rec IN C_GET_ITEM_TYPE LOOP
      L_item :=  C_rec.item;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'item_attributes',
                       'I_parent_item '||I_parent_item);

      delete from item_attributes iat
       where iat.item = L_item;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'tsl_itemdesc_base',
                       'I_parent_item '||I_parent_item);

      delete from tsl_itemdesc_base tib
       where tib.item = L_item;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'tsl_itemdesc_episel',
                       'I_parent_item '||I_parent_item);

      delete from tsl_itemdesc_episel tie
       where tie.item = L_item;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'tsl_itemdesc_iss',
                       'I_parent_item '||I_parent_item);

      delete from tsl_itemdesc_iss tii
       where tii.item = L_item;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'tsl_itemdesc_sel',
                       'I_parent_item '||I_parent_item);

      delete from tsl_itemdesc_sel tis
       where tis.item = L_item;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'tsl_itemdesc_till',
                       'I_parent_item '||I_parent_item);

      delete from tsl_itemdesc_till tit
       where tit.item = L_item;

   END LOOP;
   /* Defect NBS00011072 Raghuveer P R 4-Feb-2008 - End */

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'item_master',
                    'I_parent_item '||I_parent_item);
   delete from item_master m
    where m.item_parent      = I_parent_item
      and m.item_number_type IN (select cd.code
                                   from code_detail cd
                                  where cd.code_type = 'EANT')
      and m.item_level       = 3;
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

END DELETE_EAN;
--------------------------------------------------------------------------------
FUNCTION GET_FIRST_EAN(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       O_exists             IN OUT   BOOLEAN,
                       O_item               IN OUT   ITEM_MASTER.ITEM%TYPE,
                       O_item_number_type   IN OUT   ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                       I_item_parent        IN       ITEM_MASTER.ITEM_PARENT%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.GET_FIRST_EAN';

   cursor C_GET_INFO is
      select im.item,
             im.item_number_type
        from item_master im
       where im.item = (select MIN(im1.item)
                          from item_master im1
                         where im1.item_parent = I_item_parent
                           and im1.item_number_type in ('A-EAN','EAN13')
                           and im1.item_level  = 3);

BEGIN
   --- Check required input parameters
   if I_item_parent is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_parent',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   --- Initialize the output variables
   O_item             := NULL;
   O_item_number_type := NULL;

   --- Get the required information
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   open C_GET_INFO;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   fetch C_GET_INFO into O_item,
                         O_item_number_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   close C_GET_INFO;

   O_exists := (O_item is NOT NULL);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END GET_FIRST_EAN;


-------------------------------------------------------------------------------------------------------
FUNCTION POPULATE_EAN_TABLE(O_error_message       IN OUT          RTK_ERRORS.RTK_TEXT%TYPE,
                            O_item_master         IN OUT NOCOPY   GV_ean_table_t,
                            I_item_parent         IN              ITEM_MASTER.ITEM_PARENT%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50)  := 'ITEM_ATTRIB_SQL.POPULATE_EAN_TABLE';


   cursor C_GET_ITEM_MASTER is
   select item
     from item_master      iem
    where item_grandparent = I_item_parent
    -- Mod N105 (Drop 2), 24-Sep-2007, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
      and item_number_type in ('EAN13','A-EAN','EANOWN');
    -- Mod N105 (Drop 2), 24-Sep-2007, Nitin Gour, nitin.gour@in.tesco.com (END)


BEGIN
   -- This function will only return parent level items.

   O_item_master := NULL;
   if I_item_parent is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_item_parent','NULL','NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_GET_ITEM_MASTER','ITEM_MASTER','Item Parent: '||I_item_parent);
   open C_GET_ITEM_MASTER;

   SQL_LIB.SET_MARK('FETCH', 'C_GET_ITEM_MASTER','ITEM_MASTER','Item Parent: '||I_item_parent);
   fetch C_GET_ITEM_MASTER BULK COLLECT into O_item_master;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_ITEM_MASTER','ITEM_MASTER','Item Parent: '||I_item_parent);
   close C_GET_ITEM_MASTER;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END POPULATE_EAN_TABLE;
----------------------------------------------------------------------------------------
-- Mod By: Nuno Correia nuno.correia@wipro.com
-- Mod Date: 11-Jun-2007
-- Mod Ref: TSD_OR_365a part2
-- Mod Details: New validation on GET_ITEMCHILDRENDIFF_INFO function, before
--              calling the CURRENCY_SQL.CONVERT function
---------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
FUNCTION GET_ITEMCHILDRENDIFF_INFO(O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_on_daily_purge    IN OUT  BOOLEAN,
                                   O_item_desc         IN OUT  ITEM_MASTER.ITEM_DESC%TYPE,
                                   O_unit_cost         IN OUT  ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                                   O_retail_price      IN OUT  ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE,
                                   O_unit_cost_curr    IN OUT  SUPS.CURRENCY_CODE%TYPE,
                                   O_unit_retail_curr  IN OUT  CURRENCIES.CURRENCY_CODE%TYPE,
                                   O_markup_percent    IN OUT  NUMBER,
                                   O_existing_vpn      IN OUT  ITEM_SUPPLIER.VPN%TYPE,
                                   O_diff_value        IN OUT  V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                                   O_ean               IN OUT  ITEM_MASTER.ITEM%TYPE,
                                   O_existing_ean_type IN OUT  ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                                   O_supp_diff_1       IN OUT  ITEM_SUPPLIER.SUPP_DIFF_1%TYPE,
                                   O_supp_diff_2       IN OUT  ITEM_SUPPLIER.SUPP_DIFF_2%TYPE,
                                   O_supp_diff_3       IN OUT  ITEM_SUPPLIER.SUPP_DIFF_3%TYPE,
                                   O_supp_diff_4       IN OUT  ITEM_SUPPLIER.SUPP_DIFF_4%TYPE,
                                   I_item              IN      ITEM_MASTER.ITEM%TYPE,
                                   I_supplier          IN      SUPS.SUPPLIER%TYPE,
                                   I_zone_group_id     IN      ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE,
                                   I_retail_zone_id    IN      ITEM_ZONE_PRICE.ZONE_ID%TYPE,
                                   I_effective_date    IN      CURRENCY_RATES.EFFECTIVE_DATE%TYPE DEFAULT NULL,
                                   I_exchange_type     IN      CURRENCY_RATES.EXCHANGE_TYPE%TYPE DEFAULT NULL,
                                   I_dept              IN      DEPS.DEPT%TYPE,
                                   I_diff_id           IN      V_DIFF_ID_GROUP_TYPE.ID_GROUP%TYPE,
                                   I_elc_ind           IN      SYSTEM_OPTIONS.ELC_IND%TYPE,
                                   I_item_xform_ind    IN      ITEM_MASTER.ITEM_XFORM_IND%TYPE
                                   )
RETURN BOOLEAN IS
------------------------- IS
   --Local Variables
   L_origin_country_id ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
   L_unit_cost         ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_retail_price      ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE;
   L_unit_cost_prm     ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_unit_retail_prm   ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE;
   L_total_exp         ORDLOC_EXP.EST_EXP_VALUE%TYPE;
   L_exp_currency      CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_exp CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_total_dty         ORDLOC_EXP.EST_EXP_VALUE%TYPE;
   L_dty_currency      CURRENCIES.CURRENCY_CODE%TYPE;
   L_dummy             VARCHAR2(200);
   L_diff_type         V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_id_group_ind      V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_markup_calc_type  DEPS.MARKUP_CALC_TYPE%TYPE;
   L_budgeted_intake   DEPS.BUD_INT%TYPE;
   L_budgeted_markup   DEPS.BUD_MKUP%TYPE;
   L_program           VARCHAR2(45) := 'ITEM_ATTRIB_SQL.GET_ITEMCHILDRENDIFF_INFO';

   L_item_type                VARCHAR2(2);
   L_item_has_suppliers       BOOLEAN;
   L_item_has_primary_supp    BOOLEAN;
   L_item_has_primary_cnty    BOOLEAN;
   L_supp_attrib_exists       BOOLEAN;
   L_primary_ref_ean_exists   BOOLEAN := TRUE;
   L_first_ean_exists         BOOLEAN;
   L_supplier                 SUPS.SUPPLIER%TYPE;

   L_item   ITEM_MASTER%ROWTYPE ;

   L_standard_uom                ITEM_MASTER.STANDARD_UOM%TYPE;
   L_selling_retail              ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE;
   L_selling_retail_currency     CURRENCIES.CURRENCY_CODE%TYPE;
   L_selling_uom                 ITEM_ZONE_PRICE.SELLING_UOM%TYPE;
   L_multi_units                 ITEM_ZONE_PRICE.MULTI_UNITS%TYPE;
   L_multi_unit_retail           ITEM_ZONE_PRICE.MULTI_UNIT_RETAIL%TYPE;
   L_multi_unit_retail_currency  CURRENCIES.CURRENCY_CODE%TYPE;
   L_multi_selling_uom           ITEM_ZONE_PRICE.MULTI_SELLING_UOM%TYPE;

   L_dummy_zone_group_id         ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE;
   L_dummy_zone_id               ITEM_ZONE_PRICE.ZONE_ID%TYPE;
   L_dummy_standard_uom          ITEM_LOC.SELLING_UOM%TYPE;
   L_dummy_selling_unit_retail   ITEM_LOC.UNIT_RETAIL%TYPE;
   L_dummy_selling_uom           ITEM_LOC.SELLING_UOM%TYPE;
   L_dummy_multi_units           ITEM_LOC.MULTI_UNITS%TYPE;
   L_dummy_multi_unit_retail     ITEM_LOC.MULTI_UNIT_RETAIL%TYPE;
   L_dummy_multi_selling_uom     ITEM_LOC.MULTI_SELLING_UOM%TYPE;

BEGIN
   if GET_ITEM_MASTER (O_error_message   ,
                       L_item            ,
                       I_item            ) = FALSE then
      return FALSE;
   end if;
   --- Get the item TYPE
   if ITEM_ATTRIB_SQL.GET_ITEM_TYPE(O_error_message,
                                    L_item_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;

   if SUPPLIER_EXISTS(O_error_message,
                      L_item_has_suppliers,
                      I_item )= FALSE then
      return FALSE;
   end if;
   --- Get the item description
   if ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                               O_item_desc,
                               I_item) = FALSE then
      return FALSE;
   end if;
   --- Check if item or its parent/grandparent is on daily purge
   if DAILY_PURGE_SQL.ITEM_PARENT_GRANDPARENT_EXIST(O_error_message,
                                                    O_on_daily_purge,
                                                    I_item,
                                                    'ITEM_MASTER')= FALSE then
      return FALSE;
   end if;
   ---
   if L_item_has_suppliers then
      if I_supplier is null then
         if SUPP_ITEM_ATTRIB_SQL.GET_PRIMARY_SUPP( O_error_message,
                                                   L_item_has_primary_supp,
                                                   L_supplier  ,
                                                   I_item ) = FALSE then
            return FALSE;
         end if;
      else
         L_supplier := I_supplier ;
      end if;
      if ITEM_SUPP_COUNTRY_SQL.GET_PRIMARY_COUNTRY(O_error_message,
                                                    L_item_has_primary_cnty,
                                                    L_origin_country_id,
                                                    I_item,
                                                    L_supplier)  = FALSE then
          return FALSE;
      end if;
      ---
      if L_item_has_primary_cnty then
         if ITEM_SUPP_COUNTRY_SQL.GET_UNIT_COST(O_error_message,
                                                O_unit_cost,
                                                I_item,
                                                L_supplier,
                                                L_origin_country_id)  = FALSE then
            return FALSE;
         end if;
         ---
      end if;

      if I_elc_ind = 'Y' and L_item_has_primary_cnty then
         if ELC_CALC_SQL.CALC_TOTALS(O_error_message,
                 L_unit_cost_prm,
                 L_total_exp,
                 L_exp_currency,
                 L_exchange_rate_exp,
                 L_total_dty,
                 L_dty_currency,
                 NULL,
                 I_item,
                 NULL,
                 I_retail_zone_id,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL) = FALSE then
          return FALSE;
         end if;
      end if;
      --Get the unit cost currency code for the supplier
      if SUPP_ATTRIB_SQL.GET_CURRENCY_CODE(O_error_message,
                                            O_unit_cost_curr,
                                            L_supplier) = FALSE then
          return FALSE;
      end if;
      ---
      --Convert the unit cost price using unit cost currency
      if not CURRENCY_SQL.CONVERT(O_error_message,
                                  O_unit_cost,
                                  O_unit_cost_curr,
                                  NULL,
                                  L_unit_cost_prm,
                                  'C',
                                  I_effective_date,
                                  I_exchange_type)then
         return FALSE;
      end if;
      if SUPP_ITEM_ATTRIB_SQL.GET_INFO ( O_error_message,
                                         L_supp_attrib_exists,
                                         L_dummy,
                                         O_existing_vpn,
                                         L_dummy,
                                         L_dummy,
                                         O_supp_diff_1,
                                         O_supp_diff_2,
                                         O_supp_diff_3,
                                         O_supp_diff_4,
                                         L_dummy,
                                         L_dummy,
                                         L_dummy,
                                         L_dummy,
                                         L_dummy,
                                         I_item,
                                         L_supplier) = FALSE then
         return FALSE;
      end if;
         ---
   end if; -- end of if_item_has_suppliers
   if L_item.sellable_ind = 'Y' and L_item.item_level <= L_item.tran_level then
      if ((I_zone_group_id is not null) and (I_retail_zone_id is not null)) then
         --populate the retail price.
         if NOT PM_RETAIL_API_SQL.GET_RPM_ITEM_ZONE_PRC_WRAPPER (O_error_message,
                                                                 I_item,
                                                                 I_retail_zone_id,
                                                                 O_retail_price,
                                                                 O_unit_retail_curr,
                                                                 L_standard_uom,
                                                                 L_selling_retail,
                                                                 L_selling_retail_currency,
                                                                 L_selling_uom,
                                                                 L_multi_units,
                                                                 L_multi_unit_retail,
                                                                 L_multi_unit_retail_currency,
                                                                 L_multi_selling_uom) then
            return FALSE;
         end if;

         --11-Jun-2007    Nuno Correia    TSD_OR_365a part2 - Begin
         if O_retail_price is NOT NULL and O_unit_retail_curr is NOT NULL then
         --11-Jun-2007    Nuno Correia    TSD_OR_365a part2 - End
         ---
         --Convert the retail price using unit retail currency
         if not CURRENCY_SQL.CONVERT(O_error_message,
                                     O_retail_price,
                                     O_unit_retail_curr,
                                     NULL,
                                     L_unit_retail_prm,
                                     'R',
                                     I_effective_date,
                                     I_exchange_type)then
            return FALSE;
         end if;
         --11-Jun-2007    Nuno Correia    TSD_OR_365a part2 - Begin
         end if;
         --11-Jun-2007    Nuno Correia    TSD_OR_365a part2 - End,
      else
         if PRICING_ATTRIB_SQL.GET_BASE_ZONE_RETAIL ( O_error_message,
                                                     L_dummy_zone_group_id,
                                                     L_dummy_zone_id,
                                                     O_retail_price,
                                                     L_dummy_standard_uom,
                                                     L_dummy_selling_unit_retail,
                                                     L_dummy_selling_uom,
                                                     L_dummy_multi_units,
                                                     L_dummy_multi_unit_retail,
                                                     L_dummy_multi_selling_uom,
                                                     I_item) = FALSE then
            return FALSE;
         end if;
      end if;
   end if; -- end of sellable
   -- the rest of this section should work
   -- regardless of suppliers and sellable ind
   ---
   if DEPT_ATTRIB_SQL.GET_MARKUP(O_error_message,
                                 L_markup_calc_type,
                                 L_budgeted_intake,
                                 L_budgeted_markup,
                                 I_dept) = FALSE then
      return FALSE;
   end if;
   ---
   if MARKUP_SQL.CALC_MARKUP_PERCENT_ITEM(O_error_message,
                                          O_markup_percent,
                                          'Y',
                                          L_markup_calc_type,
                                          L_unit_cost_prm,
                                          L_unit_retail_prm,
                                          I_item,
                                          NULL,
                                          'Z',
                                          I_retail_zone_id,
                                          NULL,
                                          NULL,
                                          NULL,
                                          NULL) = FALSE then
      return FALSE;
   end if;
   if DIFF_SQL.GET_DIFF_INFO(O_error_message,
                             O_diff_value,
                             L_diff_type,
                             L_id_group_ind,
                             I_diff_id) = FALSE then
      return FALSE;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_PRIMARY_REF_EAN(O_error_message,
                                          L_primary_ref_ean_exists,
                                          O_ean,
                                          O_existing_ean_type,
                                          I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if NOT L_primary_ref_ean_exists then
      if ITEM_ATTRIB_SQL.GET_FIRST_EAN(O_error_message,
                                       L_first_ean_exists,
                                       O_ean,
                                       O_existing_ean_type,
                                       I_item) = FALSE then
         return FALSE;
      end if;
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
END GET_ITEMCHILDRENDIFF_INFO;

-------------------------------------------------------------------------------------------------------
FUNCTION CONTENTS_ITEM_ORDERABLE(O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_orderable         IN OUT  ITEM_MASTER.ORDERABLE_IND%TYPE,
                                 I_container_item    IN      ITEM_MASTER.CONTAINER_ITEM%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(50)  := 'ITEM_ATTRIB_SQL.CONTENTS_ITEM_ORDERABLE';


   cursor C_ORDERABLE_CONTENTS is
   select 'Y'
     from item_master
    where container_item = I_container_item
      and orderable_ind = 'Y';


BEGIN

   O_orderable := 'N';
   if I_container_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_container_item','NULL','NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_ORDERABLE_CONTENTS','ITEM_MASTER','Container Item: '||I_container_item);
   open C_ORDERABLE_CONTENTS;

   SQL_LIB.SET_MARK('FETCH', 'C_ORDERABLE_CONTENTS','ITEM_MASTER','Container Item: '||I_container_item);
   fetch C_ORDERABLE_CONTENTS into O_orderable;

   SQL_LIB.SET_MARK('CLOSE', 'C_ORDERABLE_CONTENTS','ITEM_MASTER','Container Item: '||I_container_item);
   close C_ORDERABLE_CONTENTS;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CONTENTS_ITEM_ORDERABLE;
-------------------------------------------------------------------------------------------------------
FUNCTION CONTENTS_ITEM_EXISTS (O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               O_exists            IN OUT  VARCHAR2,
                               I_item              IN      ITEM_MASTER.CONTAINER_ITEM%TYPE)
RETURN BOOLEAN IS
   L_program   VARCHAR2(50)  := 'ITEM_ATTRIB_SQL.CONTENTS_ITEM_EXISTS';


   cursor C_CONTENTS_ITEMS is
   select 'Y'
     from item_master
    where container_item = I_item;

BEGIN

   O_exists := 'N';
   if I_item is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_container_item','NULL','NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_CONTENTS_ITEMS ','ITEM_MASTER','Container Item: '||I_item);
   open C_CONTENTS_ITEMS;

   SQL_LIB.SET_MARK('FETCH', 'C_CONTENTS_ITEMS','ITEM_MASTER','Container Item: '||I_item);
   fetch C_CONTENTS_ITEMS into O_exists;

   SQL_LIB.SET_MARK('CLOSE', 'C_CONTENTS_ITEMS','ITEM_MASTER','Container Item: '||I_item);
   close C_CONTENTS_ITEMS;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CONTENTS_ITEM_EXISTS;
-------------------------------------------------------------------------------------------------------
FUNCTION GET_CONTAINER_ITEM(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            O_container_item   IN OUT   ITEM_MASTER.ITEM%TYPE,
                            I_item             IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_ATTRIB_SQL.GET_CONTAINER_ITEM';
   ---
   cursor C_CONTAINER is
      select im.container_item
        from item_master im
       where im.item              = I_item
         and im.deposit_item_type = 'E';

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);

      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CONTAINER','ITEM_MASTER','item:'||I_item);
   open C_CONTAINER;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CONTAINER','ITEM_MASTER','item:'||I_item);
   fetch C_CONTAINER into O_container_item;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CONTAINER','ITEM_MASTER','ITEM:'||I_item);
   close C_CONTAINER;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_CONTAINER_ITEM;
-------------------------------------------------------------------------------------------------------
FUNCTION CHECK_DESC(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                    I_desc            IN       ITEM_MASTER.ITEM_DESC%TYPE,
                    O_exists             OUT   BOOLEAN)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50)  := 'ITEM_ATTRIB_SQL.CHECK_DESC';

BEGIN

   if I_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_desc',
                                            L_program,
                                            NULL);

      return FALSE;
   end if;
   ---
   if INSTR(I_desc,CHR(10))> 0 or
      INSTR(I_desc,CHR(13))> 0 or
      INSTR(I_desc,'|') > 0 or
      INSTR(I_desc,';') > 0 then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_DESC;
--------------------------------------------------------------------------------
FUNCTION GET_PRIMARY_REF_EAN(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists             IN OUT   BOOLEAN,
                             O_item               IN OUT   ITEM_MASTER.ITEM%TYPE,
                             O_item_number_type   IN OUT   ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                             I_item_parent        IN       ITEM_MASTER.ITEM_PARENT%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.GET_PRIMARY_REF_EAN';

   cursor C_GET_INFO is
      select im.item,
             im.item_number_type
        from item_master im
       where im.item = (select im1.item
                          from item_master im1
                         where im1.item_parent          = I_item_parent
                           and im1.item_number_type in ('A-EAN','EAN13')
                           and im1.item_level           = 3
                           and im1.primary_ref_item_ind = 'Y');

BEGIN
   --- Check required input parameters
   if I_item_parent is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_parent',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   --- Initialize the output variables
   O_item             := NULL;
   O_item_number_type := NULL;

   --- Get the required information
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   open C_GET_INFO;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   fetch C_GET_INFO into O_item,
                         O_item_number_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   close C_GET_INFO;

   if O_item is NOT NULL then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_PRIMARY_REF_EAN;
---------------------------------------------------------------------------------------------
-- Function : TSL_EPW_EXISTS
-- Mod      : Mod Number. N20
-- Purpose  : This fuction is used to get the information of EPW from the Item_Attributes table
---------------------------------------------------------------------------------------------
-- Modification By : Vinod Patalappa, vinod.patalappa@in.tesco.com
-- Date            : 20-AUG-2007
-- Purpose         : To include the updated logic for EPW indicator raised through
--                   defect id NBS00002681,NBS00002778  alongwith CR.
-- Description     : Changed the logic of cursor's property C_EPW_EXISTS%FOUND
----------------------------------------------------------------------------------------------
FUNCTION TSL_EPW_EXISTS(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        O_exists             IN OUT   BOOLEAN,
                        I_item               IN       ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN IS
    L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_EPW_EXISTS';
    L_epw  VARCHAR2(1);
    cursor C_EPW_EXISTS is
    select tsl_epw_ind
      from item_attributes
     where item        = I_item
       -- CR236, 02-Sep-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
       and tsl_epw_ind = 'Y';
       -- CR236, 02-Sep-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
BEGIN
   O_exists := FALSE;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_EPW_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   open C_EPW_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EPW_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   fetch C_EPW_EXISTS into L_epw;
   -- CR236, 02-Sep-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   -- Condition has been revised for CR236
   if C_EPW_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   -- CR236, 02-Sep-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EPW_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   close C_EPW_EXISTS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
  return FALSE;
END TSL_EPW_EXISTS;
---------------------------------------------------------------------------------------------
-- Function : TSL_GET_COMPLEX_PACK_IND
-- Mod      : Mod No. 365b
-- Purpose  : This function is used to check the provided item number is a complex pack.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_COMPLEX_PACK_IND(O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_complex_pack_ind  IN OUT  BOOLEAN,
                                  I_item              IN      ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
  L_exist VARCHAR2(255)    := NULL;
  L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_COMPLEX_PACK_IND';

  cursor C_COMPLEX_PACK_EXISTS is
      select 'X'
        from item_master IM
       where IM.item            = I_item
         and IM.pack_ind        = 'Y'
         and IM.simple_pack_ind = 'N';
BEGIN
  O_complex_pack_ind := FALSE;

  SQL_LIB.SET_MARK('OPEN','C_COMPLEX_PACK_EXISTS','ITEM_MASTER','X');
  open C_COMPLEX_PACK_EXISTS;
  SQL_LIB.SET_MARK('FETCH','C_COMPLEX_PACK_EXISTS','ITEM_MASTER','X');
  fetch C_COMPLEX_PACK_EXISTS into L_exist;
  SQL_LIB.SET_MARK('CLOSE','C_COMPLEX_PACK_EXISTS','ITEM_MASTER','X');
  close C_COMPLEX_PACK_EXISTS;

  if L_exist is not NULL then
      O_complex_pack_ind := TRUE;
  end if;

  return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
  return FALSE;
END TSL_GET_COMPLEX_PACK_IND;
---------------------------------------------------------------------------------------------
-- Begin Mod N22 on 18-Sep-2007
---------------------------------------------------------------------------------------------
-- Function : TSL_SUBTRAN_EXIST
-- Mod      : Mod Number. N22
-- Purpose  : This fuction checks if the item below transaction level has been created.
---------------------------------------------------------------------------------------------
FUNCTION TSL_SUBTRAN_EXIST(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_exists        IN OUT BOOLEAN,
                           I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_SUBTRAN_EXIST';
   L_temp    BOOLEAN;
   -- cursor to fetch the OCC barcode ind if item's parent is a pack or ret barcode ind
   -- if the item's parent is a level2 item
   cursor C_CHECK_SUBTRAN is
   select 'Y' auth --Defect 4206 Wipro/JK 23-Nov-2007
     from item_master iem
    where item_level > tran_level --(OCC or EAN)
      and (item_parent = I_item or item_grandparent = I_item)
   -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  Begin
      and not exists(select 1
                       from daily_purge dp
                       where dp.key_value = iem.item
                         and table_name = 'ITEM_MASTER');
   -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  End
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_SUBTRAN',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   -- If OCC barcode ind or ret barcode ind is found to be 'Y', then output variable is TRUE
   -- else output variable is FALSE.
   O_exists := FALSE;
   FOR c_rec in C_CHECK_SUBTRAN
   LOOP
      if c_rec.auth = 'Y' then
         O_exists := TRUE;
      end if;
   END LOOP;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_SUBTRAN_EXIST;
---------------------------------------------------------------------------------------------
-- Function : TSL_GCHILD_RET_EXIST
-- Mod      : Mod Number. N22
-- Purpose  : This fuction checks if the item's grandchild has retail barcode authorised.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GCHILD_RET_EXIST(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exists        IN OUT BOOLEAN,
                              I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GCHILD_RET_EXIST';
   L_exists  VARCHAR2(1);
   -- Cursor to check if the retail barcode ind is 'Y', for the level3 item.
   cursor C_RET_EXISTS IS
   select 'X'
   -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  Begin
     from item_master iem
    where item = I_Item
      and item_level > tran_level
      and tsl_retail_barcode_auth = 'Y'
      and not exists(select 1
                       from daily_purge dp
                       where dp.key_value = iem.item
                         and table_name = 'ITEM_MASTER');
   -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  End
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_RET_EXISTS',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_RET_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_RET_EXISTS',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_RET_EXISTS into L_exists;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_RET_EXISTS',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_RET_EXISTS;
   -- If retail barcode is 'N', then output variable is FALSE else it is TRUE.
   if L_exists is NULL then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_GCHILD_RET_EXIST;
---------------------------------------------------------------------------------------------
-- Function : TSL_PACK_EXIST
-- Mod      : Mod Number. N22
-- Purpose  : This fuction checks if packs exist for the item.
---------------------------------------------------------------------------------------------
FUNCTION TSL_PACK_EXIST(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_exists        IN OUT BOOLEAN,
                        I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program  VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_PACK_EXIST';
   L_exists   VARCHAR2(1);
   -- Cursor to check if a pack exists for an item.
   cursor C_CHECK_PACK is
   select 'Y'
     from packitem pai,
          item_master iem,
          -- NBS00017234 28-Apr-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com Begin
          item_master iem1
          -- NBS00017234 28-Apr-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com End
    where iem.item        = pai.item
      -- 09-Jun-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS013056 Begin
      and (iem.item       = I_Item
       or iem.item_parent = I_item)
      -- 09-Jun-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS013056 End
      and iem.item_level  = iem.tran_level
      and iem.pack_ind    = 'N'
      -- NBS00017234 28-Apr-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com Begin
      -- not to approve item if there are no Active primary packs means not in
      -- delete pending status
      and iem1.item              = pai.pack_no
      and iem1.tsl_prim_pack_ind = 'Y'
      -- NBS00017234 28-Apr-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com End
      -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  Begin
      and not exists(select 1
                       from daily_purge dp
                       where dp.key_value = pai.pack_no
                         and table_name = 'ITEM_MASTER');
                         -- NBS00017188 24-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                         -- commented followig code because it's fixed along with NBS00017144
                         -- and iem.status != 'A');
                         -- NBS00017188 24-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
      -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  End
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_PACK',
                    'ITEM_MASTER '||'PACKITEM',
                    'Item: '||I_item);
   open C_CHECK_PACK;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_PACK',
                    'ITEM_MASTER '||'PACKITEM',
                    'Item: '||I_item);
   fetch C_CHECK_PACK into L_exists;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_PACK',
                    'ITEM_MASTER '||'PACKITEM',
                    'Item: '||I_item);
   close C_CHECK_PACK;
   -- if pack does not exist output variable is FALSE else it is TRUE.
   if L_exists is NULL then
      O_exists :=  FALSE;
   else
      O_exists := TRUE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_PACK_EXIST;
---------------------------------------------------------------------------------------------
-- Function : TSL_OCC_EXIST
-- Mod      : Mod Number. N22
-- Purpose  : This fuction checks if OCC exist for the item.
---------------------------------------------------------------------------------------------
FUNCTION TSL_OCC_EXIST(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_exists        IN OUT BOOLEAN,
                       I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program  VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_OCC_EXIST';
   L_exists   VARCHAR2(1);
   -- Cursor to check if the OCC barcode ind is 'Y', for a given item.
   cursor C_CHECK_OCC is
   select 'X'
     from item_master
    where item                 = I_item
      and pack_ind             = 'Y'
      and item_level           > tran_level
      and tsl_occ_barcode_auth = 'Y';
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_OCC',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_CHECK_OCC;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_OCC',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_CHECK_OCC into L_exists;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_OCC',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_CHECK_OCC;
   -- If barcode is 'N', output variable is FALSE else it is TRUE.
   if L_exists is NULL then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_OCC_EXIST;
---------------------------------------------------------------------------------------------
-- Function : TSL_RET_EXIST
-- Mod      : Mod Number. N22
-- Purpose  : This fuction checks if retail barcode exist for the item.
---------------------------------------------------------------------------------------------
FUNCTION TSL_RET_EXIST(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_exists        IN OUT BOOLEAN,
                       I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program  VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_RET_EXIST';
   L_exists   VARCHAR2(1);
   -- Cursor to check if retail barcode is 'Y' for an item.
   cursor C_CHECK_RET is
   select 'X'
     from item_master
    -- 09-Jun-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS013056 Begin
    where (item = I_item
       or item_parent = I_item
       or item_grandparent = I_item)
    -- 09-Jun-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS013056 End
      and item_level > tran_level
      and pack_ind = 'N'
      and tsl_retail_barcode_auth = 'Y';
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_RET',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_CHECK_RET;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_RET',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_CHECK_RET into L_exists;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_RET',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_CHECK_RET;
   -- If retail barcode is 'N' then output variable is FALSE else it is TRUE.
   if L_exists is NULL then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_RET_EXIST;
---------------------------------------------------------------------------------------------
-- Function : TSL_CHILD_ATTRIB_EXIST
-- Mod      : Mod Number. N22
-- Purpose  : This fuction checks if attributes of children of a style exist.
---------------------------------------------------------------------------------------------
FUNCTION TSL_CHILD_ATTRIB_EXIST(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_exists        IN OUT BOOLEAN,
                                I_spstup_ind    IN     VARCHAR2,
                                I_tret_ind      IN     VARCHAR2,
                                I_tslsca_ind    IN     VARCHAR2,
                                I_item          IN     ITEM_MASTER.ITEM%TYPE,
                                -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
                                --DefNBS018653,18707,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,Begin
                                I_tsret_ind     IN     VARCHAR2 DEFAULT 'N')
                                --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
                                -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
RETURN BOOLEAN is
   L_program  VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CHILD_ATTRIB_EXIST';
   L_item     ITEM_MASTER.ITEM%TYPE;
   -- 28-May-2009 TESCO HSC/Govindarajan K    NBS00013007 Begin
   L_tslsca_ind    VARCHAR2(1);
   L_exist         BOOLEAN := FALSE;
   -- 28-May-2009 TESCO HSC/Govindarajan K    NBS00013007 End
   -- Cursor to check: If the tsl_sca_ind, tret_ind and spstup_ind is 'Y', then
   -- values for that item should have these values in the corresponding table.
   cursor C_CHILD_ATTRIB_EXIST is
   /* 03-Apr-2009 TESCO HSC/Murali    NBS00012155 Begin */
   select iem.item
     from item_master iem
    where iem.item_parent = I_item
      and (exists (select 1
                     from tsl_sca_head tsh
                    where ((iem.item = tsh.item and iem.item_level = 2) OR
                           (iem.item_parent = tsh.item and iem.item_level = 3))
                      -- 28-May-2009 TESCO HSC/Govindarajan K    NBS00013007 Begin
                      -- and tsh.status = 'A'
                      and L_tslsca_ind = 'Y')
                       or L_tslsca_ind = 'N')
                       -- 28-May-2009 TESCO HSC/Govindarajan K    NBS00013007 End
      and ((exists (select 1
                     from item_master iem1, code_detail cd
                    where ((iem.item = iem1.item_parent and iem.item_level = 2) OR
                           (iem.item = iem1.item and iem.item_level = 3))
                      and iem1.tsl_retail_barcode_auth='Y'
                      and I_tret_ind = 'Y'
                      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
                      --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,Begin
                      and iem1.item_number_type = cd.code
                      and cd.code_type = 'TSBE')
                      --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
                      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
                      or  (I_tret_ind = 'N'))
                      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
                      --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,Begin
        or (exists (select 1
                     from item_master iem1, code_detail cd
                    where ((iem.item = iem1.item_parent and iem.item_level = 2) OR
                           (iem.item = iem1.item and iem.item_level = 3))
                      and iem1.tsl_retail_barcode_auth='Y'
                      and I_tsret_ind = 'Y'
                      and iem1.item_number_type = cd.code
                      and cd.code_type = 'NTBE')
                       or  (I_tsret_ind = 'N')))
                      --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
                      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
      and (exists (select 1
                     from packitem pai,
                          item_master iem2
                    where iem2.item    = pai.item
                      and ((iem.item = iem2.item and iem.item_level = 2) OR
                           (iem.item_parent = iem2.item and iem.item_level = 3))
                      and iem2.item_level = iem2.tran_level
                      and iem2.pack_ind = 'N'
                      and I_spstup_ind = 'Y')
                      or I_spstup_ind = 'N')
      and rownum = 1;
      /* 03-Apr-2009 TESCO HSC/Murali    NBS00012155 End */
    ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 Begin
    -- CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 18-Feb-2010 Begin
   -- Added bracket in the below cursor to include either UK or ROI
   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   cursor C_UKROI_CHILD_ATTRIB_EXIST is
   select iem.item
     from item_master iem
    where iem.item_parent = I_item
      and ((exists (select 1
                     from tsl_sca_head tsh
                    where ((iem.item = tsh.item and iem.item_level = 2) OR
                           (iem.item_parent = tsh.item and iem.item_level = 3))
                      and L_tslsca_ind = 'Y'
                      --12-May-2010 Murali  Cr288b Begin
                      and tsh.status = 'A'
                      --12-May-2010 Murali  Cr288b End
                      and tsl_country_id = 'U')
                       or L_tslsca_ind = 'N')
       or (exists (select 1
                     from tsl_sca_head tsh
                    where ((iem.item = tsh.item and iem.item_level = 2) OR
                           (iem.item_parent = tsh.item and iem.item_level = 3))
                      and L_tslsca_ind = 'Y'
                      --12-May-2010 Murali  Cr288b Begin
                      and tsh.status = 'A'
                      --12-May-2010 Murali  Cr288b End
                      and tsl_country_id = 'R')
                       or L_tslsca_ind = 'N'))
      and ((exists (select 1
                     from item_master iem1, code_detail cd
                    where ((iem.item = iem1.item_parent and iem.item_level = 2) OR
                           (iem.item = iem1.item and iem.item_level = 3))
                      and iem1.tsl_retail_barcode_auth='Y'
                      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
                      --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,Begin
                      and I_tret_ind = 'Y'
                      and iem1.item_number_type = cd.code
                      and cd.code_type = 'TSBE')
                      --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
                      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
                       or (I_tret_ind = 'N'))
                       -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
                       --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,Begin
        or (exists (select 1
                      from item_master iem1,code_detail cd
                    where ((iem.item = iem1.item_parent and iem.item_level = 2) OR
                           (iem.item = iem1.item and iem.item_level = 3))
                      and iem1.tsl_retail_barcode_auth='Y'
                      and I_tsret_ind = 'Y'
                      and iem1.item_number_type = cd.code
                      and cd.code_type = 'NTBE')
                      or  (I_tsret_ind = 'N')))
                      --DefNBS018653,09-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
                      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
      and (exists (select 1
                     from packitem pai,
                          item_master iem2
                    where iem2.item    = pai.item
                      and ((iem.item = iem2.item and iem.item_level = 2) OR
                           (iem.item_parent = iem2.item and iem.item_level = 3))
                      and iem2.item_level = iem2.tran_level
                      and iem2.pack_ind = 'N'
                      and I_spstup_ind = 'Y')
                       or I_spstup_ind = 'N')
      and rownum = 1;
   L_sys_options_row      SYSTEM_OPTIONS%ROWTYPE;
   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 End
BEGIN
   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS (O_error_message,
                                             L_sys_options_row) = FALSE then
      return FALSE;
   end if;
   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   -- 28-May-2009 TESCO HSC/Govindarajan K    NBS00013007 Begin
   if TSL_BASE_VARIANT_SQL.VALIDATE_VARIANT_ITEM (O_error_message,
                                                  L_exist,
                                                  I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_exist = TRUE then
      L_tslsca_ind := 'N';
   else
      L_tslsca_ind := I_tslsca_ind;
   end if;
   -- 28-May-2009 TESCO HSC/Govindarajan K    NBS00013007 End
   ---
   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   if L_sys_options_row.tsl_single_instance_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_UKROI_CHILD_ATTRIB_EXIST',
                       'ITEM_MASTER' || 'PACKITEM',
                       'Item: '||I_item);
      open C_UKROI_CHILD_ATTRIB_EXIST;
      SQL_LIB.SET_MARK('FETCH',
                       'C_UKROI_CHILD_ATTRIB_EXIST',
                       'ITEM_MASTER' || 'PACKITEM',
                       'Item: '||I_item);
      fetch C_UKROI_CHILD_ATTRIB_EXIST into L_item;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_UKROI_CHILD_ATTRIB_EXIST',
                       'ITEM_MASTER' || 'PACKITEM',
                       'Item: '||I_item);
      close C_UKROI_CHILD_ATTRIB_EXIST;
      if L_item is NULL then
         O_exists := FALSE;
      else
         O_exists := TRUE;
      end if;
   else
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHILD_ATTRIB_EXIST',
                       'ITEM_MASTER' || 'PACKITEM',
                       'Item: '||I_item);
      open C_CHILD_ATTRIB_EXIST;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHILD_ATTRIB_EXIST',
                       'ITEM_MASTER' || 'PACKITEM',
                       'Item: '||I_item);
      fetch C_CHILD_ATTRIB_EXIST into L_item;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHILD_ATTRIB_EXIST',
                       'ITEM_MASTER' || 'PACKITEM',
                       'Item: '||I_item);
      close C_CHILD_ATTRIB_EXIST;
      if L_item is NULL then
         O_exists := FALSE;
      else
         O_exists := TRUE;
      end if;
   end if;
   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   return TRUE;
EXCEPTION
   when OTHERS then
      -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
      if C_CHILD_ATTRIB_EXIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHILD_ATTRIB_EXIST',
                          'ITEM_MASTER' || 'PACKITEM',
                          'Item: '||I_item);
         close C_CHILD_ATTRIB_EXIST;
      end if;
      ---
      if C_UKROI_CHILD_ATTRIB_EXIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_UKROI_CHILD_ATTRIB_EXIST',
                          'ITEM_MASTER' || 'PACKITEM',
                          'Item: '||I_item);
         close C_UKROI_CHILD_ATTRIB_EXIST;
      end if;
      -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_CHILD_ATTRIB_EXIST;
-- End Mod N22 on 18-Sep-2007
-- 08-Oct-2007 TESCO HSC/Praveen R    Mod N112  Begin
---------------------------------------------------------------------------------------------
-- Function : TSL_CHECK_ITEM_EXIST
-- Mod Ref  : Mod N112
-- Purpose  : To Check the item keyed-in in Barcode Move Screen is available in Item master table.
---------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_ITEM_EXIST(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item               IN       ITEM_MASTER.ITEM%TYPE,
                              I_item_level         IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                              I_item_parent        IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                              I_pack_ind           IN       ITEM_MASTER.PACK_IND%TYPE,
                              I_catch_weight_ind   IN       ITEM_MASTER.CATCH_WEIGHT_IND%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CHECK_ITEM_EXIST';
   L_item      ITEM_MASTER.ITEM%TYPE;
  --08-JULY-2008 DefNBS007455  Sayali Bulakh Begin
   cursor C_CHECK_ITEM_EXIST is
   select im.item
     from item_master im
    where im.item = I_item
      and im.item_level = I_item_level
      --04-June-2008 DefNBS007620/DefNBS00006873 Sayali Bulakh sayali.bulakh@wipro.com Begin
      and DECODE(to_char(I_item_level),'1','1',im.item_parent) = DECODE(to_char(I_item_level),'1','1',NVL(I_item_parent,im.item_parent))
      --04-June-2008 DefNBS007620/DefNBS00006873 Sayali Bulakh sayali.bulakh@wipro.com End
      and im.pack_ind = I_pack_ind
      and im.catch_weight_ind = NVL(I_catch_weight_ind, im.catch_weight_ind)
      and not exists (select 'X'
                        from daily_purge dp,
                             item_master im
                       where im.item              = I_item
                         and (im.item             = dp.key_value
                          or  im.item_parent      = dp.key_value
                          or  im.item_grandparent = dp.key_value));
   --08-JULY-2008 DefNBS007455  Sayali Bulakh End


BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_CHECK_ITEM_EXIST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_CHECK_ITEM_EXIST into L_item;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_CHECK_ITEM_EXIST;

   if L_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   else
      return TRUE;
   end if;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_CHECK_ITEM_EXIST;
---------------------------------------------------------------------------------------------
-- Function : TSL_GET_ITEM_INFO
-- Mod Ref  : Mod N112
-- Purpose  : To Get the item related information for the item.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_ITEM_INFO(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_item               IN       ITEM_MASTER.ITEM%TYPE,
                           O_item_desc             OUT   ITEM_MASTER.ITEM_DESC%TYPE,
                           O_item_parent           OUT   ITEM_MASTER.ITEM_PARENT%TYPE,
                           O_catch_weight_ind      OUT   ITEM_MASTER.CATCH_WEIGHT_IND%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_ITEM_INFO';
   L_item_desc          ITEM_MASTER.ITEM_DESC%TYPE;
   L_item_parent        ITEM_MASTER.ITEM_PARENT%TYPE;
   L_catch_weight_ind   ITEM_MASTER.CATCH_WEIGHT_IND%TYPE;

   cursor C_GET_ITEM_INFO is
   select item_desc,
          item_parent,
          catch_weight_ind
     from item_master
    where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ITEM_INFO',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_GET_ITEM_INFO;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ITEM_INFO',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_GET_ITEM_INFO into L_item_desc,
                              L_item_parent,
                              L_catch_weight_ind;

   if C_GET_ITEM_INFO%FOUND then
      O_item_desc        := L_item_desc;
      O_item_parent      := L_item_parent;
      O_catch_weight_ind := L_catch_weight_ind;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||I_item);
      close C_GET_ITEM_INFO;
      return TRUE;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||I_item);
      close C_GET_ITEM_INFO;
      return FALSE;
   end if;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_GET_ITEM_INFO;
---------------------------------------------------------------------------------------------
-- Function : TSL_GET_ITEM_INFO
-- Mod Ref  : Mod N112
-- Purpose  : This is a over ride function
--            Which Get relevant item information from Item master table.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_ITEM_INFO(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_item               IN       ITEM_MASTER.ITEM%TYPE,
                           O_item_number_type      OUT   ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                           O_item_level            OUT   ITEM_MASTER.ITEM_LEVEL%TYPE,
                           O_item_desc             OUT   ITEM_MASTER.ITEM_DESC%TYPE,
                           O_diff_1                OUT   ITEM_MASTER.DIFF_1%TYPE,
                           O_diff_2                OUT   ITEM_MASTER.DIFF_2%TYPE,
                           O_diff_3                OUT   ITEM_MASTER.DIFF_3%TYPE,
                           O_diff_4                OUT   ITEM_MASTER.DIFF_4%TYPE,
                           O_item_parent           OUT   ITEM_MASTER.ITEM_PARENT%TYPE,
                           O_status                OUT   ITEM_MASTER.STATUS%TYPE,
                           -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                           O_consumer_unit         OUT   ITEM_MASTER.TSL_CONSUMER_UNIT%TYPE
                           -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                           )
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_ITEM_INFO';
   L_item_number_type   ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   L_item_level         ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_item_desc          ITEM_MASTER.ITEM_DESC%TYPE;
   L_diff_1             ITEM_MASTER.DIFF_1%TYPE;
   L_diff_2             ITEM_MASTER.DIFF_2%TYPE;
   L_diff_3             ITEM_MASTER.DIFF_3%TYPE;
   L_diff_4             ITEM_MASTER.DIFF_4%TYPE;
   L_item_parent        ITEM_MASTER.ITEM_PARENT%TYPE;
   L_status             ITEM_MASTER.STATUS%TYPE;
   -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   L_consumer_unit      ITEM_MASTER.TSL_CONSUMER_UNIT%TYPE;
   -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End

   cursor C_GET_ITEM_INFO is
   select item_number_type,
          item_level,
          item_desc,
          diff_1,
          diff_2,
          diff_3,
          diff_4,
          item_parent,
          status,
          -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
          tsl_consumer_unit
          -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
     from item_master
    where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ITEM_INFO',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_GET_ITEM_INFO;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ITEM_INFO',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_GET_ITEM_INFO into L_item_number_type,
                              L_item_level,
                              L_item_desc,
                              L_diff_1,
                              L_diff_2,
                              L_diff_3,
                              L_diff_4,
                              L_item_parent,
                              L_status,
                              -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                              L_consumer_unit;
                              -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End

   if C_GET_ITEM_INFO%FOUND then
      O_item_number_type := L_item_number_type;
      O_item_level       := L_item_level;
      O_item_desc        := L_item_desc;
      O_diff_1           := L_diff_1;
      O_diff_2           := L_diff_2;
      O_diff_3           := L_diff_3;
      O_diff_4           := L_diff_4;
      O_item_parent      := L_item_parent;
      O_status           := L_status;
      -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
      O_consumer_unit    := L_consumer_unit;
      -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||I_item);
      close C_GET_ITEM_INFO;
      return TRUE;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||I_item);
      close C_GET_ITEM_INFO;
      return FALSE;
   end if;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_GET_ITEM_INFO;
---------------------------------------------------------------------------------------------
-- Function : TSL_SET_PRIMARY_REF_ITEM
-- Mod Ref  : Mod N112
-- Purpose  : This function will check the move or exchanged the L3 Item / L2 Pack is a
--            primary reference item and if yes it will set another L3 item belongs to the
--            same parent as primary reference item
---------------------------------------------------------------------------------------------
FUNCTION TSL_SET_PRIMARY_REF_ITEM(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_item               IN       ITEM_MASTER.ITEM%TYPE,
                                  --CR 480 Begin
                                  I_barcode_move_exchange_deact IN VARCHAR2 DEFAULT 'N')
                                  --CR 480 End
   RETURN BOOLEAN IS

   L_program          VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_ITEM_INFO';
   L_alternate_item   ITEM_MASTER.ITEM%TYPE;
   L_parent           ITEM_MASTER.ITEM_PARENT%TYPE;

   cursor C_CHK_PRIMARY_REF_ITEM is
   select item_parent
     from item_master
    where item = I_item
      and primary_ref_item_ind = 'Y';
   cursor C_GET_ALTERNATE_ITEM is
   select item
     from item_master
    where item_parent = L_parent
      and item <> I_item
      -- 03-Dec-2007 TESCO HSC/Praveen R    DefNBS00004280  Begin
      and item NOT IN (select key_value
                         from daily_purge
                        where table_name = 'ITEM_MASTER')
      -- 03-Dec-2007 TESCO HSC/Praveen R    DefNBS00004280  End
      and rownum = 1;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHK_PRIMARY_REF_ITEM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_CHK_PRIMARY_REF_ITEM;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHK_PRIMARY_REF_ITEM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_CHK_PRIMARY_REF_ITEM into L_parent;

   if C_CHK_PRIMARY_REF_ITEM%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHK_PRIMARY_REF_ITEM',
                       'ITEM_MASTER',
                       'Item: '||I_item);
      close C_CHK_PRIMARY_REF_ITEM;
      return TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHK_PRIMARY_REF_ITEM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_CHK_PRIMARY_REF_ITEM;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ALTERNATE_ITEM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_GET_ALTERNATE_ITEM;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ALTERNATE_ITEM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_GET_ALTERNATE_ITEM into L_alternate_item;

   if C_GET_ALTERNATE_ITEM%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ALTERNATE_ITEM',
                       'ITEM_MASTER',
                       'Item: '||I_item);
      close C_GET_ALTERNATE_ITEM;
      return TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ALTERNATE_ITEM',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_GET_ALTERNATE_ITEM;

   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    'ITEM_MASTER',
                    'Item: '||I_item);
   update item_master
      set primary_ref_item_ind = 'Y'
    where item = L_alternate_item;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_SET_PRIMARY_REF_ITEM;
---------------------------------------------------------------------------------------------
-- 08-Oct-2007 TESCO HSC/Praveen R    Mod N112  End
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- 22-Nov-2007 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS00004099 Begin
---------------------------------------------------------------------------------------
FUNCTION TSL_GET_BARCODE_ATTRIB(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                I_item            IN       ITEM_MASTER.ITEM%TYPE,
                                --30-Nov-2009 Tesco HSC/Usha Patil  Defect Id: NBS00015504 Begin
                                O_item_attrib_tbl     OUT  TSL_ITEM_ATTR_TBL)
                                --30-Nov-2009 Tesco HSC/Usha Patil  Defect Id: NBS00015504 End
  RETURN BOOLEAN IS

  TYPE utcol_name_TBL    is table of USER_TAB_COLUMNS.COLUMN_NAME%TYPE    INDEX BY BINARY_INTEGER;
  LP_utcol_name_TBL      utcol_name_TBL;
  L_sql_select           VARCHAR2(32767) := NULL;
  L_program              VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_GET_BARCODE_ATTRIB';
  L_item_attrib_count    NUMBER;
  L_sql_select_uk        VARCHAR2(32767) := NULL;
  L_sql_select_roi       VARCHAR2(32767) := NULL;

  cursor C_GET_COL_NAMES is
  select column_name
    from user_tab_columns
   where table_name='ITEM_ATTRIBUTES'
   order by column_id;

  cursor C_ITEM_ATTRIB_EXIST is
  select count(*) ia_count
    from item_attributes
   where item = I_item;

BEGIN
  --30-Nov-2009 Tesco HSC/Usha Patil  Defect Id: NBS00015504 Begin
  O_item_attrib_tbl := NULL;
  --30-Nov-2009 Tesco HSC/Usha Patil  Defect Id: NBS00015504 End

  SQL_LIB.SET_MARK('OPEN',
                  'C_ITEM_ATTRIB_EXIST',
                  'ITEM_ATTRIBUTES',
                  'ITEM: '||(I_item));
  FOR C_rec in C_ITEM_ATTRIB_EXIST
  LOOP
   L_item_attrib_count := C_rec.ia_count;
  END LOOP;
  SQL_LIB.SET_MARK('CLOSE',
                  'C_ITEM_ATTRIB_EXIST',
                  'ITEM_ATTRIBUTES',
                  'ITEM: '||(I_item));

  if L_item_attrib_count > 0 then
    SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COL_NAMES',
                    'USER_TAB_COLUMNS',
                    'ITEM: '||(I_item));
    open C_GET_COL_NAMES;
    fetch C_GET_COL_NAMES BULK COLLECT INTO LP_utcol_name_TBL;
    close C_GET_COL_NAMES;
    SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COL_NAMES',
                    'USER_TAB_COLUMNS',
                    'ITEM: '||(I_item));

    if LP_utcol_name_TBL.COUNT > 0 then
      L_sql_select := 'SELECT ';
      FOR i in 1..LP_utcol_name_TBL.COUNT
      LOOP
        if i = 1 then
          L_sql_select := L_sql_select || LP_utcol_name_TBL(i);
        else
          L_sql_select := L_sql_select ||', '|| LP_utcol_name_TBL(i);
        end if;
      END LOOP;
      L_sql_select := L_sql_select || ' from item_attributes';
      L_sql_select := L_sql_select || ' where item =' ||chr(39)||I_Item||chr(39);
    end if;
    --30-Nov-2009 Tesco HSC/Usha Patil  Defect Id: NBS00015504 Begin
    EXECUTE IMMEDIATE L_sql_select bulk collect into O_item_attrib_tbl;
    --30-Nov-2009 Tesco HSC/Usha Patil  Defect Id: NBS00015504 End

  end if;
  return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_GET_BARCODE_ATTRIB;
-------------------------------------------------------------------------------------
FUNCTION TSL_SET_BARCODE_ATTRIB(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_item            IN       ITEM_MASTER.ITEM%TYPE,
                                 I_item_attrib_rec IN       ITEM_ATTRIBUTES%ROWTYPE)
  RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'ITEM_ATTRIB_SQL.TSL_SET_BARCODE_ATTRIB';

BEGIN

  if I_item_attrib_rec.item IS NOT NULL then
    SQL_LIB.SET_MARK('INSERT',
                      NULL,
                     'ITEM_ATTRIBUTES',
                     'ITEM: ' ||I_item);
    insert into item_attributes values I_item_attrib_rec;
  end if;
  return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_SET_BARCODE_ATTRIB;

---------------------------------------------------------------------------------------
-- 22-Nov-2007 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS00004099 End
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Begin Defect 4206 Wipro/JK 23-Nov-2007
---------------------------------------------------------------------------------------------
-- Function : TSL_CHECK_RETAIL_OCC_BARCODE
-- Mod      : Defect 4206
-- Purpose  : This function checks the availability of retail and OCC barcode set items.
---------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_RETAIL_OCC_BARCODE(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                      O_exists        IN OUT BOOLEAN,
                                      I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program          VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_SUBTRAN_EXIST';
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   -- CR347 Raghuveer P R 29-July-2010 - Begin
   L_dept             SUBCLASS.DEPT%TYPE;
   L_class            SUBCLASS.Class%TYPE;
   L_subclass         SUBCLASS.SUBCLASS%TYPE;
   L_sca              VARCHAR2(1);
   L_lschld           VARCHAR2(1);
   L_spstup           VARCHAR2(1);
   L_tret             VARCHAR2(1);
   L_tocc             VARCHAR2(1);
   L_tsret            VARCHAR2(1);
   L_tsocc            VARCHAR2(1);
   L_code_type        CODE_DETAIL.CODE_TYPE%TYPE;
   -- CR347 Raghuveer P R 29-July-2010 - End
   --09-Jan-2012 Tesco HSC/Usha Patil       Mod: N169/CR373 Begin
   L_tban_type        VARCHAR2(6);
   --09-Jan-2012 Tesco HSC/Usha Patil       Mod: N169/CR373 End

   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
   -- cursor to fetch the OCC barcode ind if item's parent is a pack or ret barcode ind
   -- if the item's parent is a level2 item
   cursor C_CHECK_SUBTRAN is
   select DECODE(pack_ind, 'Y', tsl_occ_barcode_auth,tsl_retail_barcode_auth) auth,
          -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
          -- CR347 Raghuveer P R 29-July-2010 - Begin
          iem.item_number_type
          -- CR347 Raghuveer P R 29-July-2010 - End
          -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
     from item_master iem
    where item_level > tran_level --(OCC or EAN)
      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
      --DefNBS018613,11-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com, Begin
      and iem.item_number_type != 'TPNB'
      --DefNBS018613,11-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com,End
      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
      and (item_parent = I_item or item_grandparent = I_item)
   -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  Begin
      and not exists(select 1
                       from daily_purge dp
                       where dp.key_value = iem.item
                         and table_name = 'ITEM_MASTER');
   -- 21-Apr-2009 TESCO HSC/Murali  DefNBS012156  End

   --09-Jan-2012 Tesco HSC/Usha Patil       Mod: N169/CR373 Begin
   CURSOR C_CHECK_TBAN_TYPE(Cp_code VARCHAR2) is
   select 'Y'
     from code_detail
    where code_type='TBAN'
      and code = Cp_code;
   --09-Jan-2012 Tesco HSC/Usha Patil       Mod: N169/CR373 End
BEGIN
   -- If OCC barcode ind or ret barcode ind is found to be 'Y', then output variable is TRUE
   -- else output variable is FALSE.
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   -- CR347 Raghuveer P R 29-July-2010 - Begin
   if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                     I_item,
                                     L_dept,
                                     L_class,
                                     L_subclass) = FALSE then
      return FALSE;
   end if;
   --

   if MERCH_DEFAULT_SQL.TSL_GET_REQ_INDS(O_error_message,
                                         L_sca,
                                         L_lschld,
                                         L_spstup,
                                         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
                                         --DefNBS018613,11-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                         L_tocc,
                                         L_tret,
                                         L_tsocc,
                                         L_tsret,
                                         --DefNBS018613,11-Aug-2010,Sripriya,Sripriya.karanam@in.tesco.com, End
                                         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
                                         L_dept,
                                         L_class,
                                         L_subclass) = FALSE then
      return FALSE;
   end if;


   --
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   --10-Aug-2010 Tesco HSC/Maheshwari Appuswamy Defect Id: NBS00018582 Begin
   O_exists := FALSE;
   --O_exists := TRUE;
   --10-Aug-2010 Tesco HSC/Maheshwari Appuswamy Defect Id: NBS00018582 End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end

   FOR c_rec in C_CHECK_SUBTRAN
   LOOP
      if ITEM_ATTRIB_DEFAULT_SQL.TSL_GET_CODE_TYPE(O_error_message,
                                                   L_code_type,
                                                   c_rec.item_number_type) = FALSE then
         return FALSE;
      end if;
      --
      if (L_code_type = 'TSBE' and L_tret  = 'Y' and c_rec.auth = 'N') or
         (L_code_type = 'NTBE' and L_tsret = 'Y' and c_rec.auth = 'N') or
         (L_code_type = 'TSBO' and L_tocc  = 'Y' and c_rec.auth = 'N') or
         (L_code_type = 'NTBO' and L_tsocc = 'Y' and c_rec.auth = 'N') then
         --09-Jan-2012 Tesco HSC/Usha Patil       Mod: N169/CR373 Begin
         SQL_LIB.SET_MARK('OPEN',
                          'C_CHECK_TBAN_TYPE',
                          'code_detail',
                          'item_number_type: '||c_rec.item_number_type);
         open C_CHECK_TBAN_TYPE (c_rec.item_number_type);
         SQL_LIB.SET_MARK('FETCH',
                          'C_CHECK_TBAN_TYPE',
                          'code_detail',
                          'item_number_type: '||c_rec.item_number_type);
         fetch C_CHECK_TBAN_TYPE into L_tban_type;
         if C_CHECK_TBAN_TYPE%NOTFOUND then
         --09-Jan-2012 Tesco HSC/Usha Patil       Mod: N169/CR373 End
            O_exists := FALSE;
         --09-Jan-2012 Tesco HSC/Usha Patil       Mod: N169/CR373 Begin
         else
            O_exists := TRUE;
         end if;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_TBAN_TYPE',
                          'code_detail',
                          'item_number_type: '||c_rec.item_number_type);
         close C_CHECK_TBAN_TYPE;
         --09-Jan-2012 Tesco HSC/Usha Patil       Mod: N169/CR373 End
         -- MrgNBS020155 25-Dec-2010 Ankush/ankush.khanna@in.tesco.com Begin
         --14-Dec-2010 Tesco HSC/Manikandan Defect Id: NBS00020122 Begin
         -- EXIT;
         --14-Dec-2010 Tesco HSC/Manikandan Defect Id: NBS00020122 End
         -- MrgNBS020155 25-Dec-2010 Ankush/ankush.khanna@in.tesco.com Begin
      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
      --10-Aug-2010 Tesco HSC/Maheshwari Appuswamy Defect Id: NBS00018582 Begin
      else
         O_exists := TRUE;
      end if;
      --10-Aug-2010 Tesco HSC/Maheshwari Appuswamy Defect Id: NBS00018582 End
      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
      --
   END LOOP;
   -- CR347 Raghuveer P R 29-July-2010 - End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_CHECK_RETAIL_OCC_BARCODE;
----------------------------------------------------------------------------------------------
-- End Defect 4206 Wipro/JK 23-Nov-2007
-- Author       : Nitin Gour,nitin.gour@in.tesco.com
-- Function Name: TSL_GET_FIRST_EAN
-- Purpose      : This function will retrieve the lowest value of EANOWN Level 3 item from the
--                item_master table for a parent item.
-- Mod Ref      : N105.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_FIRST_EAN(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_exists             IN OUT   BOOLEAN,
                           O_item               IN OUT   ITEM_MASTER.ITEM%TYPE,
                           O_item_number_type   IN OUT   ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                           I_item_parent        IN       ITEM_MASTER.ITEM_PARENT%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_FIRST_EAN';

   cursor C_GET_INFO is
      select im.item,
             im.item_number_type
        from item_master im
       where im.item = (select MIN(im1.item)
                          from item_master im1
                         where im1.item_parent      = I_item_parent
                           and im1.item_number_type in ('EANOWN', 'EANNON')
                           and im1.item_level       = 3);

BEGIN
   --- Check required input parameters
   if I_item_parent is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_parent',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   --- Initialize the output variables
   O_item             := NULL;
   O_item_number_type := NULL;

   --- Get the required information
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   open C_GET_INFO;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   fetch C_GET_INFO into O_item,
                         O_item_number_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   close C_GET_INFO;

   O_exists := (O_item is NOT NULL);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END TSL_GET_FIRST_EAN;
----------------------------------------------------------------------------------------------
-- Author       : Nitin Gour,nitin.gour@in.tesco.com
-- Function Name: TSL_GET_PRIMARY_REF_EAN
-- Mod Ref      : Mod N105
-- Purpose      : This function will retrieve the primary reference value of EANOWN Level 3
--                item from the item_master table for a parent item.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_PRIMARY_REF_EAN(O_error_message  IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists             IN OUT   BOOLEAN,
                             O_item               IN OUT   ITEM_MASTER.ITEM%TYPE,
                             O_item_number_type   IN OUT   ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                             I_item_parent        IN       ITEM_MASTER.ITEM_PARENT%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_PRIMARY_REF_EAN';

   cursor C_GET_INFO is
      select im.item,
             im.item_number_type
        from item_master im
       where im.item = (select im1.item
                          from item_master im1
                         where im1.item_parent          = I_item_parent
                           and im1.item_number_type     in ('EANOWN', 'EANNON')
                           and im1.item_level           = 3
                           and im1.primary_ref_item_ind = 'Y');

BEGIN
   --- Check required input parameters
   if I_item_parent is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_parent',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   --- Initialize the output variables
   O_item             := NULL;
   O_item_number_type := NULL;

   --- Get the required information
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   open C_GET_INFO;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   fetch C_GET_INFO into O_item,
                         O_item_number_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_INFO',
                    'item_master',
                    'I_item_parent: '||I_item_parent);
   close C_GET_INFO;

   if O_item is NOT NULL then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END TSL_GET_PRIMARY_REF_EAN;
----------------------------------------------------------------------------------------------------
FUNCTION GET_ORDER_TYPE(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        O_order_type         IN OUT   ITEM_MASTER.ORDER_TYPE%TYPE,
                        I_item               IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.GET_ORDER_TYPE';

   cursor C_GET_ORDER_TYPE is
      select im.order_type
        from item_master im
       where im.item = I_item;

BEGIN
   --- Check required input parameters
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   --- Initialize the output variables
   O_order_type  := NULL;

   --- Get the required information
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ORDER_TYPE',
                    'item_master',
                    'I_item: '||I_item);
   open C_GET_ORDER_TYPE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ORDER_TYPE',
                    'item_master',
                    'I_item: '||I_item);
   fetch C_GET_ORDER_TYPE into O_order_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ORDER_TYPE',
                    'item_master',
                    'I_item: '||I_item);
   close C_GET_ORDER_TYPE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_ORDER_TYPE;
----------------------------------------------------------------------------------------------------
-- 30-Jan-2008 John Anand, john.anand@in.tesco.com - Mod:N114 - Begin
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_MU_IND(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - Begin
                        O_TSL_MU_IND    IN OUT ITEM_MASTER.TSL_MU_IND%TYPE,
                        I_ITEM          IN     ITEM_MASTER.ITEM%TYPE)
                        -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - End
RETURN BOOLEAN IS
   ---
   L_program       VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_GET_MU_IND';
   ---
   CURSOR C_GET_MU_IND  is
   select NVL(TSL_MU_IND,'N')
     -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - Begin
     from item_master
     -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - End
    where item = i_item;
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
                    'C_GET_MU_IND ',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   open C_GET_MU_IND ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_MU_IND ',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   fetch C_GET_MU_IND  into O_TSL_MU_IND;
   if C_GET_MU_IND%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_MU_IND ',
                       'ITEM_MASTER',
                       'Item: '||I_item);
      close C_GET_MU_IND ;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_MU_IND ',
                    'ITEM_MASTER',
                    'Item: '||I_item);
   close C_GET_MU_IND ;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_GET_MU_IND%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_MU_IND ',
                          'ITEM_MASTER',
                          'Item: '||I_item);
         close C_GET_MU_IND;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_GET_MU_IND;
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_SELL_BY_TYPE (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_pack_no       IN     PACKITEM.PACK_NO%TYPE,
                               I_item          IN     ITEM_ATTRIBUTES.ITEM%TYPE,
                               O_mismtach_ind     OUT VARCHAR2)
RETURN BOOLEAN IS

   L_program               VARCHAR2(50) := 'ITEM_ATTRIB_SQL.TSL_CHK_SELL_BY_TYPE';
   L_count                 NUMBER;
   L_existing_item_count   NUMBER;
   L_sell_by_type          ITEM_ATTRIBUTES.TSL_SELL_BY_TYPE%TYPE;
   L_sell_by_type_new_item ITEM_ATTRIBUTES.TSL_SELL_BY_TYPE%TYPE;
   L_exist                 VARCHAR2(1);
   L_mismtach_ind          VARCHAR2(2);
   L_item                  ITEM_ATTRIBUTES.ITEM%TYPE;
   --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, Begin
   L_simple_pack_ind       ITEM_MASTER.SIMPLE_PACK_IND%TYPE := 'N';
   L_rec_pack_ind          ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_component             ITEM_ATTRIBUTES.ITEM%TYPE;
   L_rec_component         ITEM_ATTRIBUTES.ITEM%TYPE;
   L_rec_item              ITEM_ATTRIBUTES.ITEM%TYPE;

   --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, End
   ---
   CURSOR C_COUNT_PACK_ITEM is
   select COUNT(*)
     from packitem
    where pack_no = I_pack_no;
   ---
   CURSOR C_GET_ITEM_SELL_BY_TYPE(L_item ITEM_ATTRIBUTES.ITEM%TYPE) is
   select NVL(tsl_sell_by_type, 'NA')
     from item_attributes
    where item = L_item;
   ---
   CURSOR C_GET_COMPONENT_ITEMS is
   select item,
          pack_ind,
          item p_item
     from item_master
    where item IN (select item
                     from packitem
                    where pack_no = I_pack_no)
      and pack_ind = 'N'
    UNION
    select i.item item,
           i.pack_ind,
           i.item p_item
      from item_master i
     where item IN (select item
                      from packitem
                     where pack_no = I_pack_no)
       and i.pack_ind = 'Y'
       and EXISTS (select item
                     from item_attributes i
                    where item = i.item)
    UNION
    select p.item item,
           'N',
           p.pack_no p_item
      from item_master im,
           packitem p,
           (select i.item, i.pack_ind
              from item_master i
             where item IN (select item
                              from packitem
                             where pack_no = I_pack_no)
               and i.pack_ind = 'Y'
               and NOT EXISTS (select item
                                 from item_attributes
                                where item = i.item)) component
     where im.item   = component.item
       and p.pack_no = component.item;

BEGIN
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_pack_no IS NULL THEN
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_pack_no',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   O_mismtach_ind := L_mismtach_ind;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_COUNT_PACK_ITEM',
                    'PACKITEM',
                    'PACK_NO: '|| I_pack_no);
   open C_COUNT_PACK_ITEM;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_COUNT_PACK_ITEM ',
                    'PACKITEM',
                    'PACK_NO: '|| I_pack_no);
   fetch C_COUNT_PACK_ITEM into L_count;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_COUNT_PACK_ITEM ',
                    'PACKITEM',
                    'PACK_NO: '|| I_pack_no);
   close C_COUNT_PACK_ITEM;
   ---
   if L_count = 0 then
      O_mismtach_ind := 'N';
      return TRUE;
   end if;
   ---
   --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, Begin
   if ITEM_ATTRIB_SQL.GET_SIMPLE_PACK_IND (O_error_message,
                                           L_simple_pack_ind,
                                           I_item) = FALSE then
      return FALSE;
   end if;

   if L_simple_pack_ind = 'Y' then
      if PACKITEM_ATTRIB_SQL.TSL_GET_COMP(O_error_message,
                                          L_component,
                                          I_item) = FALSE then
         return FALSE;
      end if;
      L_item := L_component;
   else
     L_item := I_item;
   end if;
   --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, End

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ITEM_SELL_BY_TYPE',
                    'ITEM_ATTRIBUTES',
   --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, Begin
   --replaced I_item to  L_item
                    'Item: '||L_item/*I_item*/);
   open C_GET_ITEM_SELL_BY_TYPE(L_item/*I_item*/);
   --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, End
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ITEM_SELL_BY_TYPE',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   fetch C_GET_ITEM_SELL_BY_TYPE into L_sell_by_type_new_item;
   ---
   if C_GET_ITEM_SELL_BY_TYPE%NOTFOUND then
      --- NBS006264, John Alister Anand, 16-Apr-2007, Begin
      L_sell_by_type_new_item := 'NA';
      --- NBS006264, John Alister Anand, 16-Apr-2007, End
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ITEM_SELL_BY_TYPE',
                    'PACKITEM',
                    'Item: '||I_item);
   close C_GET_ITEM_SELL_BY_TYPE;
   ---
   FOR rec IN c_get_component_items
   LOOP
      --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, Begin
      L_rec_pack_ind := 'N';
      L_rec_component := NULL;
      L_rec_item := NULL;
      if ITEM_ATTRIB_SQL.GET_SIMPLE_PACK_IND (O_error_message,
                                              L_rec_pack_ind,
                                              rec.item) = FALSE then
         return FALSE;
      end if;

      if L_rec_pack_ind = 'Y' then
         if PACKITEM_ATTRIB_SQL.TSL_GET_COMP(O_error_message,
                                             L_rec_component,
                                             rec.item) = FALSE then
            return FALSE;
         end if;
         L_rec_item := L_rec_component;
      else
         L_rec_item := rec.item;
      end if;
      --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, End

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_SELL_BY_TYPE',
                       'ITEM_ATTRIBUTES',
      --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, Begin
      --replaced rec.item to  L_rec_item
                       'Item: '||L_rec_item/*rec.item*/);
      open C_GET_ITEM_SELL_BY_TYPE(L_rec_item/*rec.item*/);
      --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, End
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_SELL_BY_TYPE',
                       'ITEM_ATTRIBUTES',
                       'Item: '||rec.item);
      fetch C_GET_ITEM_SELL_BY_TYPE into L_sell_by_type;
      ---
      if C_GET_ITEM_SELL_BY_TYPE%NOTFOUND then
         L_sell_by_type := NULL;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_SELL_BY_TYPE',
                       'ITEM_ATTRIBUTES',
                       'Item: '||rec.item);
      close C_GET_ITEM_SELL_BY_TYPE;
      ---
      if L_sell_by_type <> L_sell_by_type_new_item then
         if L_sell_by_type_new_item IS NULL then
            O_error_message := SQL_LIB.CREATE_MSG('TSL_SELL_BY_TYPE_MISMATCH',
                                                  'Item',
                                                  rec.item,
                                                  NULL);
            return FALSE;
         elsif L_sell_by_type IS NULL then
            if rec.pack_ind = 'N' then
               if rec.p_item <> rec.item then
                  O_error_message := SQL_LIB.CREATE_MSG('TSL_SELL_BY_TYPE_CMP_ITEM',
                                                        --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                                        rec.p_item,
                                                        --DefNBS022246,07-Apr-2011,Sripriya,Sripriya.karanam@in.tesco.com, End
                                                        NULL,
                                                        NULL);
                  return FALSE;
               else
                  O_error_message := SQL_LIB.CREATE_MSG('TSL_SELL_BY_TYPE_MISMATCH',
                                                        'Pack',
                                                        rec.item,
                                                        NULL);
                  return FALSE;
               end if;
            end if;
         else
            O_error_message := SQL_LIB.CREATE_MSG('TSL_DIFERNT_SELL_BY_TYPE',
                                                  I_item,
                                                  NULL,
                                                  NULL);
            return FALSE;
         end if;
      end if;
   ---
   END LOOP;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_COUNT_PACK_ITEM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_COUNT_PACK_ITEM',
                          'PACKITEM',
                          'PACK_NO: '||I_PACK_NO);
         close C_COUNT_PACK_ITEM;
      end if;
      ---
      if C_GET_ITEM_SELL_BY_TYPE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_SELL_BY_TYPE ',
                          'PACKITEM',
                          'Item: '||I_item);
         close C_GET_ITEM_SELL_BY_TYPE;
      end if;
      ---
      if C_GET_COMPONENT_ITEMS%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_COMPONENT_ITEMS',
                          'PACKITEM',
                          'Item: '||I_item);
         close C_GET_COMPONENT_ITEMS;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHK_SELL_BY_TYPE;
----------------------------------------------------------------------------------------------------
-- 30-Jan-2008 John Anand, john.anand@in.tesco.com - Mod:N114 - End
----------------------------------------------------------------------------------------------------
-- 31-Jan-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - Begin
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_ITEM_ATTRIB_INFO(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_status                OUT   ITEM_MASTER.STATUS%TYPE,
                                  O_catch_weight_ind      OUT   ITEM_MASTER.CATCH_WEIGHT_IND%TYPE,
                                  O_sale_type             OUT   ITEM_MASTER.SALE_TYPE%TYPE,
                                  O_base_item             OUT   ITEM_MASTER.TSL_BASE_ITEM%TYPE,
                                  I_item               IN       ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_ITEM_ATTRIB_INFO';

   CURSOR C_GET_ITEM_ATTRIB_INFO is
   select i.status,
          i.catch_weight_ind,
          i.sale_type,
          i.tsl_base_item
     from item_master i
    where i.item = I_item;

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
                    'C_GET_ITEM_ATTRIB_INFO',
                    'item_master',
                    'item: '||(I_item));
   open C_GET_ITEM_ATTRIB_INFO;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ITEM_ATTRIB_INFO',
                    'item_master',
                    'item: '||(I_item));
   fetch C_GET_ITEM_ATTRIB_INFO into O_status,
                                     O_catch_weight_ind,
                                     O_sale_type,
                                     O_base_item;
   ---
   if C_GET_ITEM_ATTRIB_INFO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_ATTRIB_INFO',
                       'item_master',
                       'item: '||(I_item));
      close C_GET_ITEM_ATTRIB_INFO;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ITEM_ATTRIB_INFO',
                    'item_master',
                    'item: '||(I_item));
   close C_GET_ITEM_ATTRIB_INFO;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_ITEM_ATTRIB_INFO%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_ATTRIB_INFO',
                          'item_master',
                          'item: '||(I_item));
         close C_GET_ITEM_ATTRIB_INFO;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_ITEM_ATTRIB_INFO;
-------------------------------------------------------------------------------------------------
FUNCTION GET_TSL_ITEM_DEFAULTS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                               O_tab                OUT   TSL_ITEM_DEFAULTS%ROWTYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(64) := 'ITEM_ATTRIB_SQL.GET_TSL_ITEM_DEFAULTS';

   CURSOR C_GET_TSL_ITEM_ATTRIB is
   select t.cost_zone_group,
          t.selling_uom_conv_fact,
          t.origin_country,
          t.case_size,
          t.inner_size,
          t.ti,
          t.hi,
          --DefNBS022780,31-May-2011,Sripriya,Sripriya.karanam@in.tesco.com,Begin
          t.gross_weight,
          t.weight_uom
          --DefNBS022780,31-May-2011,Sripriya,Sripriya.karanam@in.tesco.com,End
     from tsl_item_defaults t
    where rownum = 1;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TSL_ITEM_ATTRIB',
                    'tsl_item_defaults',
                    NULL);
   open C_GET_TSL_ITEM_ATTRIB;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TSL_ITEM_ATTRIB',
                    'tsl_item_defaults',
                    NULL);
   fetch C_GET_TSL_ITEM_ATTRIB into O_tab;
   ---
   if C_GET_TSL_ITEM_ATTRIB%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_TSL_ITEM_ATTRIB',
                       'tsl_item_defaults',
                       NULL);
      close C_GET_TSL_ITEM_ATTRIB;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('NO_RECORD',
                                            NULL,
                                            NULL,
                                            NULL);
      ---
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TSL_ITEM_ATTRIB',
                    'tsl_item_defaults',
                    NULL);
   close C_GET_TSL_ITEM_ATTRIB;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_TSL_ITEM_ATTRIB%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_TSL_ITEM_ATTRIB',
                          'tsl_item_defaults',
                          NULL);
         close C_GET_TSL_ITEM_ATTRIB;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_TSL_ITEM_DEFAULTS;
-------------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_VARIANT_CONTENTS_QTY(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                        O_status             OUT   VARCHAR2,
                                        I_item            IN       ITEM_MASTER.ITEM%TYPE,
                                        I_contents_qty    IN       TSL_ITEMDESC_SEL.CONTENTS_QTY%TYPE,
                                        -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
                                        I_country         IN       Varchar2 default NULL)
                                        -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
RETURN BOOLEAN IS

   L_program               VARCHAR(64) := 'ITEM_ATTRIB_SQL.TSL_CHECK_VARIANT_CONTENTS_QTY';
   L_contents_qty          TSL_ITEMDESC_SEL.CONTENTS_QTY%TYPE       := NULL;
   L_variant_reason_code   ITEM_MASTER.TSL_VARIANT_REASON_CODE%TYPE := NULL;
   -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
   L_contents_qty_roi      TSL_ITEMDESC_SEL.CONTENTS_QTY_ROI%TYPE   := NULL;
   -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (End)

   -- cursor declarations
   CURSOR C_GET_CONTENTS_QTY is
   select distinct t.contents_qty,
          -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
          t.contents_qty_roi
          -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
     from tsl_itemdesc_sel t
    where t.item in (select item from item_master i
                      where i.tsl_base_item in (select tsl_base_item
                                                  from item_master im
                                                 where im.item = I_item)
                        and i.item <> i.tsl_base_item
                        and i.tsl_variant_reason_code in ('Y','C'));

   CURSOR C_GET_VARIANT_REASON_CODE is
   select tsl_variant_reason_code
     from item_master im
    where im.item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_contents_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_contents_qty',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_VARIANT_REASON_CODE',
                    'item_master',
                    NULL);
   open C_GET_VARIANT_REASON_CODE;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_VARIANT_REASON_CODE',
                    'item_master',
                    NULL);
   fetch C_GET_VARIANT_REASON_CODE into L_variant_reason_code;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_VARIANT_REASON_CODE',
                    'item_master',
                    NULL);
   close C_GET_VARIANT_REASON_CODE;
   ---
   if L_variant_reason_code = 'Y' or L_variant_reason_code = 'C' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_CONTENTS_QTY',
                       'tsl_itemdesc_sel',
                       'item= ' || (I_item));
      open C_GET_CONTENTS_QTY;
      ---
      if C_GET_CONTENTS_QTY%ROWCOUNT>1 then
         O_status := 'N';
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_CONTENTS_QTY',
                       'tsl_itemdesc_sel',
                       'item= ' || (I_item));
      FETCH C_GET_CONTENTS_QTY into L_contents_qty,
                                    -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
                                    L_contents_qty_roi;
                                    -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
      ---
      if C_GET_CONTENTS_QTY%NOTFOUND then
         O_status := 'Y';
         ---
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CONTENTS_QTY',
                          'tsl_itemdesc_sel',
                          'item= ' || (I_item));
         close C_GET_CONTENTS_QTY;
         ---
         return TRUE;
      end if;
      ---
      -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
      if I_country = 'U' then
      -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
         if L_contents_qty = I_contents_qty then
            O_status := 'Y';
         elsif L_contents_qty <> I_contents_qty then
            O_status := 'N';
         end if;
      -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
      elsif I_country = 'R' then
         if L_contents_qty_roi = I_contents_qty then
            O_status := 'Y';
         elsif L_contents_qty_roi <> I_contents_qty then
            O_status := 'N';
         end if;
      end if;
      -- DefNBS016673, 23-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_CONTENTS_QTY',
                       'tsl_itemdesc_sel',
                       'item= ' || (I_item));
      close C_GET_CONTENTS_QTY;
      ---
   else
      O_status := 'Y';
   end if;
   ---
   return TRUE;

EXCEPTION
   when others then
      if C_GET_CONTENTS_QTY%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CONTENTS_QTY',
                          'tsl_itemdesc_sel',
                          'item= ' || (I_item));
         close C_GET_CONTENTS_QTY;
      end if;
      ---
      if C_GET_VARIANT_REASON_CODE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_VARIANT_REASON_CODE',
                          'item_master',
                          NULL);
         close C_GET_VARIANT_REASON_CODE;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_VARIANT_CONTENTS_QTY;
-------------------------------------------------------------------------------------------------
-- 31-Jan-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - End
-------------------------------------------------------------------------------------------------
-- Begin ModN115,116,117 Wipro/JK 20-Feb-2008
----------------------------------------------------------------------------------------------------
-- Function : TSL_CHK_ITEM_FIXEDMARGIN
-- Purpose  : To check the given item belongs to  fixed margin subclass
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_ITEM_FIXEDMARGIN(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_flg           IN OUT VARCHAR2,
                                  I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program       VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_CHK_ITEM_FIXEDMARGIN';
   ---
   cursor C_CHK_SUBCLASS  is
      select 'Y'
        from item_master iem,
             subclass scl
       where scl.tsl_fixed_margin is not null
         and iem.dept = scl.dept
         and iem.class = scl.class
         and iem.subclass = scl.subclass
         and iem.item = I_item;
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
                    'C_CHK_SUBCLASS',
                    'ITEM_MASTER, SUBCLASS',
                    'Item: '|| I_item);
   open C_CHK_SUBCLASS ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHK_SUBCLASS',
                    'ITEM_MASTER, SUBCLASS',
                    'Item: '|| I_item);
   fetch C_CHK_SUBCLASS into O_flg;

   if C_CHK_SUBCLASS%NOTFOUND then
      O_flg := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHK_SUBCLASS',
                    'ITEM_MASTER, SUBCLASS',
                    'Item: '|| I_item);
   close C_CHK_SUBCLASS ;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_CHK_SUBCLASS%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHK_SUBCLASS',
                          'ITEM_MASTER, SUBCLASS',
                          'Item: '|| I_item);
         close C_CHK_SUBCLASS;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_CHK_ITEM_FIXEDMARGIN;
----------------------------------------------------------------------------------------------------
-- End ModN115,116,117 Wipro/JK 20-Feb-2008
-- 1-Apr-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS010471 Begin
----------------------------------------------------------------------------------------------------
-- 20-Feb-2008 Satish B.N, satish.narasimhaiah@in.tesco.com ModN115,116,117 Begin
----------------------------------------------------------------------------------------------------
-- Function : TSL_GENERATE_MULTIPACK_ITEM
-- Purpose  : To generate new item number for multipack item
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GENERATE_MULTIPACK_ITEM(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     I_item          IN     ITEM_MASTER.ITEM %TYPE,
                                     O_item_number   IN OUT ITEM_MASTER.ITEM %TYPE)
   RETURN BOOLEAN IS

   --Local variable declaration
   L_program         VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GENERATE_MULTIPACK_ITEM';
   L_tpnc            ITEM_MASTER.TSL_CONSUMER_UNIT%TYPE;


BEGIN
   if TSL_ITEM_NUMBER_SQL.GET_CONSUMER_UNIT (O_error_message,
                                             I_item,
                                             L_tpnc) = FALSE then
      return FALSE;
   else
      O_item_number := '7777'||L_tpnc;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_GENERATE_MULTIPACK_ITEM;
----------------------------------------------------------------------------------------------------
-- 20-Feb-2008 Satish B.N, satish.narasimhaiah@in.tesco.com ModN115,116,117 End
----------------------------------------------------------------------------------------------------
-- 1-Apr-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS010471 End
-- NBS005922, John Alister Anand, 10-Apr-2008, Begin
----------------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_PACK_ITEM_ATTRIB(o_error_message  IN OUT rtk_errors.rtk_text%TYPE,
                                       I_item            IN item_master.item%TYPE,
                                       o_enable         OUT VARCHAR2)
  RETURN BOOLEAN IS

  L_program         VARCHAR2(255) := 'item_attrib_sql_john.tsl_copy_attrib';
  L_exist_iat       VARCHAR2(1);
  L_exist_pack      VARCHAR2(1);
  L_exist_pack_code VARCHAR2(1);
  L_exist_common    VARCHAR2(1);
  L_dept            ITEM_MASTER.DEPT%TYPE;
  L_class           ITEM_MASTER.CLASS%TYPE;
  L_subclass        ITEM_MASTER.SUBCLASS%TYPE;

  cursor C_GET_MHDI is
    select dept, class, subclass from item_master where item = I_item;

  cursor C_PACK_IAT is
    select 'Y' from item_attributes where item = I_item;

  cursor C_COMMON_CODE is
    /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin */
    /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 Begin */
    select 'Y'
    /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 End */
    /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End */
      from merch_hier_default mhd1
     where mhd1.info in
           (select code
              from code_detail
             where code_type = 'TIAT'
               and code in (select tsl_code from tsl_map_item_attrib_code))
       and mhd1.dept = L_dept
       and mhd1.class = L_class
       and mhd1.subclass = L_subclass
       and mhd1.tsl_item_lvl = 2
       and mhd1.tsl_pack_ind = 'N'
       and mhd1.available_ind = 'Y'
       and (exists (select 1
                      from merch_hier_default mhd2
                     where mhd2.info = mhd1.info
                       and mhd2.tsl_pack_ind = 'Y'
                       and mhd2.tsl_item_lvl = 1
                       and mhd2.available_ind = 'Y') or not exists
            (select 1
               from merch_hier_default mhd2
              where mhd2.info = mhd1.info
                and mhd2.tsl_pack_ind = 'Y'
                and mhd2.tsl_item_lvl = 1
                and mhd2.available_ind = 'Y'))
                /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin */
                /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 Begin */
                and rownum = 1;
                /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 End */
                /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End */

  cursor C_PACK_CODE is
    /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin */
    /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 Begin */
    select 'Y'
    /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 End */
    /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End */
      from merch_hier_default mhd1
     where mhd1.info in
           (select code
              from code_detail
             where code_type = 'TIAT'
               and code in (select tsl_code from tsl_map_item_attrib_code))
       and mhd1.dept = L_dept
       and mhd1.class = L_class
       and mhd1.subclass = L_subclass
       and mhd1.tsl_item_lvl = 1
       and mhd1.tsl_pack_ind = 'Y'
       and mhd1.available_ind = 'Y'
       /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin */
       /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 Begin */
       and rownum = 1;
       /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 End */
       /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End */

  cursor C_PACK_EXIST IS
    /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin */
    /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 Begin */
    select 'Y'
    /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 End */
    /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End */
      from merch_hier_default mhd1
     where mhd1.info in
           (select code
              from code_detail
             where code_type = 'TIAT'
               and code in (select tsl_code from tsl_map_item_attrib_code))
       and mhd1.dept = L_dept
       and mhd1.class = L_class
       and mhd1.subclass = L_subclass
       and mhd1.tsl_item_lvl = 1
       and mhd1.tsl_pack_ind = 'Y'
       /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin */
       /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 Begin */
       and rownum = 1;
       /* 07-Oct-2008 TESCO HSC/Murali    DefNBS008542 End */
       /* MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End */

BEGIN
  SQL_LIB.SET_MARK(i_action => 'OPEN',
                   i_cursor => 'C_PACK_IAT',
                   i_table  => 'item_attributes',
                   i_keys   => 'Item: ' || i_item);
  OPEN C_PACK_IAT;
  SQL_LIB.SET_MARK(i_action => 'FETCH',
                   i_cursor => 'C_PACK_IAT',
                   i_table  => 'MERCH_HIER_DEFAULT',
                   i_keys   => 'Item: ' || i_item);
  FETCH C_PACK_IAT
    INTO L_exist_iat;

  IF C_PACK_IAT%NOTFOUND THEN
    o_enable := 'N';
    return TRUE;
    SQL_LIB.SET_MARK(i_action => 'CLOSE',
                     i_cursor => 'C_PACK_IAT',
                     i_table  => 'MERCH_HIER_DEFAULT',
                     i_keys   => 'Item: ' || i_item);
    CLOSE C_PACK_IAT;
  ELSE
    ---
    SQL_LIB.SET_MARK(i_action => 'OPEN',
                     i_cursor => 'C_GET_mhd1I',
                     i_table  => 'MERCH_HIER_DEFAULT',
                     i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                 L_class || 'subclass: ' || L_subclass);
    OPEN C_GET_MHDI;
    SQL_LIB.SET_MARK(i_action => 'FETCH',
                     i_cursor => 'C_GET_MHDI',
                     i_table  => 'MERCH_HIER_DEFAULT',
                     i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                 L_class || 'subclass: ' || L_subclass);
    FETCH C_GET_MHDI
      INTO L_dept, L_class, L_subclass;
    SQL_LIB.SET_MARK(i_action => 'CLOSE',
                     i_cursor => 'C_GET_MHDI',
                     i_table  => 'MERCH_HIER_DEFAULT',
                     i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                 L_class || 'subclass: ' || L_subclass);
    CLOSE C_GET_MHDI;
    ---
    SQL_LIB.SET_MARK(i_action => 'OPEN',
                     i_cursor => 'C_COMMON_CODE',
                     i_table  => 'MERCH_HIER_DEFAULT',
                     i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                 L_class || 'subclass: ' || L_subclass);
    OPEN C_COMMON_CODE;
    SQL_LIB.SET_MARK(i_action => 'FETCH',
                     i_cursor => 'C_COMMON_CODE',
                     i_table  => 'MERCH_HIER_DEFAULT',
                     i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                 L_class || 'subclass: ' || L_subclass);
    FETCH C_COMMON_CODE
      INTO L_exist_common;
    SQL_LIB.SET_MARK(i_action => 'CLOSE',
                     i_cursor => 'C_COMMON_CODE',
                     i_table  => 'MERCH_HIER_DEFAULT',
                     i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                 L_class || 'subclass: ' || L_subclass);
    CLOSE C_COMMON_CODE;
    ---
    IF L_exist_common IS NOT NULL THEN
      o_enable := 'Y';
      return TRUE;
    ELSE
      SQL_LIB.SET_MARK(i_action => 'OPEN',
                       i_cursor => 'C_PACK_EXIST',
                       i_table  => 'MERCH_HIER_DEFAULT',
                       i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                   L_class || 'subclass: ' || L_subclass);
      OPEN C_PACK_EXIST;
      SQL_LIB.SET_MARK(i_action => 'FETCH',
                       i_cursor => 'C_PACK_EXIST',
                       i_table  => 'MERCH_HIER_DEFAULT',
                       i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                   L_class || 'subclass: ' || L_subclass);
      FETCH C_PACK_EXIST
        INTO L_exist_pack;
      SQL_LIB.SET_MARK(i_action => 'CLOSE',
                       i_cursor => 'C_PACK_EXIST',
                       i_table  => 'MERCH_HIER_DEFAULT',
                       i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                   L_class || 'subclass: ' || L_subclass);
      CLOSE C_PACK_EXIST;
      ---
      if L_exist_pack is NOT NULL then
        SQL_LIB.SET_MARK(i_action => 'OPEN',
                         i_cursor => 'C_PACK_CODE',
                         i_table  => 'MERCH_HIER_DEFAULT',
                         i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                     L_class || 'subclass: ' || L_subclass);
        OPEN C_PACK_CODE;
        SQL_LIB.SET_MARK(i_action => 'FETCH',
                         i_cursor => 'C_PACK_CODE',
                         i_table  => 'MERCH_HIER_DEFAULT',
                         i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                     L_class || 'subclass: ' || L_subclass);
        FETCH C_PACK_CODE
          INTO L_exist_pack_code;
        SQL_LIB.SET_MARK(i_action => 'CLOSE',
                         i_cursor => 'C_PACK_CODE',
                         i_table  => 'MERCH_HIER_DEFAULT',
                         i_keys   => 'dept: ' || L_dept || 'class: ' ||
                                     L_class || 'subclass: ' || L_subclass);
        CLOSE C_PACK_CODE;
        ---
        if L_exist_pack_code is NOT NULL then
          o_enable := 'Y';
          return TRUE;
        else
          o_enable := 'N';
          return TRUE;
        end if;
        ---
      else
        o_enable := 'Y';
        return TRUE;
      end if;
      ---
    END IF;
  END IF;
  SQL_LIB.SET_MARK(i_action => 'CLOSE',
                   i_cursor => 'C_PACK_IAT',
                   i_table  => 'MERCH_HIER_DEFAULT',
                   i_keys   => 'Item: ' || i_item);
  CLOSE C_PACK_IAT;

  return TRUE;
EXCEPTION
  WHEN OTHERS THEN
     o_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END tsl_validate_pack_item_attrib;
----------------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_COMPONENT_ATTRIB(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_component_item     IN     ITEM_MASTER.ITEM%TYPE,
                                   I_pack_item           IN     ITEM_MASTER.ITEM%TYPE,
                                   -- CR236, 14-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                   I_country_id         IN     VARCHAR2)
                                   -- CR236, 14-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
  RETURN BOOLEAN is

  L_table        VARCHAR2(30) := 'ITEM_ATTRIBUTES';
  L_program      VARCHAR2(300) := 'ITEM_ATTRIB.TSL_COPY_COMPONENT_ATTRIB';
  L_close_cursor VARCHAR2(2000) := ' close C_get_item_attrib;';
  L_end          VARCHAR2(10) := ' end;';
  L_sql_select   VARCHAR2(32767) := NULL;
  L_sql_insert   VARCHAR2(32767) := NULL;
  L_sql_update   VARCHAR2(32767) := NULL;
  L_sql_column   VARCHAR2(32767) := NULL;
  L_statement    VARCHAR2(32767) := NULL;
  L_dept            ITEM_MASTER.DEPT%TYPE;
  L_class           ITEM_MASTER.CLASS%TYPE;
  L_subclass        ITEM_MASTER.SUBCLASS%TYPE;
  --- NBS006264, John Alister Anand, 16-Apr-2007, Begin
  L_build_ins    VARCHAR2(1) := 'N';
  --- NBS006264, John Alister Anand, 16-Apr-2007, End
  --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    Begin
  L_system_options_row    SYSTEM_OPTIONS%ROWTYPE;
  L_item_rec              ITEM_MASTER%ROWTYPE;
  L_security_ind          SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
  L_item_parent_owner     ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_uk_ind                VARCHAR2(1) :=  'N';
  L_roi_ind               VARCHAR2(1) :=  'N';
  L_login_ctry            ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    End

  RECORD_LOCKED EXCEPTION;
  PRAGMA EXCEPTION_INIT(Record_Locked, -54);

  cursor C_GET_MHDI is
    select dept, class, subclass from item_master where item = I_component_item;

  cursor C_GET_COLUMNS_PACK is
    select tmiac.tsl_code, tmiac.tsl_column_name column_name
      from code_detail c, tsl_map_item_attrib_code tmiac
     where code_type = 'TIAT'
       and c.code = tmiac.tsl_code
       and exists
     (select 1 from tsl_map_item_attrib_code where c.code = tsl_code)
       and (exists (select 1
                      from merch_hier_default m
                     where m.info = c.code
                       and m.dept = L_dept
                       and m.class = L_class
                       and m.subclass = L_subclass
                       -- CR236, 14-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                       and m.tsl_country_id in (I_country_id,'B')
                       -- CR236, 14-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                       and m.tsl_item_lvl = 1
                       and m.tsl_pack_ind = 'Y'
                       and m.available_ind = 'Y') or not exists
            (select 1
               from merch_hier_default m
              where m.info = c.code
                and m.dept = L_dept
                and m.class = L_class
                and m.subclass = L_subclass
                -- CR236, 14-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                and m.tsl_country_id in (I_country_id,'B')
                -- CR236, 14-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                and m.tsl_item_lvl = 1
                and m.tsl_pack_ind = 'Y'))
       -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
       and  not exists(select 1
                         from tsl_attr_stpcas sca
                        where sca.tsl_itm_attr_id= tmiac.tsl_code);

       -- 23-Oct-2013  Gopinath Meganathan PM020648 End
BEGIN
  ---
  SQL_LIB.SET_MARK(i_action => 'OPEN',
                   i_cursor => 'C_GET_MHDI',
                   i_table  => 'MERCH_HIER_DEFAULT',
                   i_keys   => 'dept: ' || L_dept || 'class: ' ||
                               L_class || 'subclass: ' || L_subclass);
  OPEN C_GET_MHDI;
  SQL_LIB.SET_MARK(i_action => 'FETCH',
                   i_cursor => 'C_GET_MHDI',
                   i_table  => 'MERCH_HIER_DEFAULT',
                   i_keys   => 'dept: ' || L_dept || 'class: ' ||
                               L_class || 'subclass: ' || L_subclass);
  FETCH C_GET_MHDI
    INTO L_dept, L_class, L_subclass;
  SQL_LIB.SET_MARK(i_action => 'CLOSE',
                   i_cursor => 'C_GET_MHDI',
                   i_table  => 'MERCH_HIER_DEFAULT',
                   i_keys   => 'dept: ' || L_dept || 'class: ' ||
                               L_class || 'subclass: ' || L_subclass);
  CLOSE C_GET_MHDI;
  ---
  SQL_LIB.SET_MARK('OPEN',
                   'C_GET_COLUMNS_PACK',
                   'TSL_MAP_ITEM_ATTRIB_CODE',
                   'ITEM: ' || I_component_item);

    --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    Begin
  if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                           L_system_options_row) = FALSE then
     return FALSE;
  end if;
  L_security_ind := L_system_options_row.tsl_loc_sec_ind;
  ---
  if L_security_ind = 'Y' then
     ---
     if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY(O_error_message,
                                                                                         L_uk_ind,
                                                                                        L_roi_ind) = FALSE then
        return FALSE;
     end if;
     ---
     if L_uk_ind = 'Y' then
        L_login_ctry := 'U';
     elsif L_roi_ind = 'Y' and L_uk_ind = 'N' then
        L_login_ctry := 'R';
     end if;
     ---
     if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                         L_item_rec,
                                         I_component_item) = FALSE then
        return FALSE;
     end if;
     ---
  end if;
  --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    End

  FOR C_rec in C_GET_COLUMNS_PACK LOOP
    ---
    --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    Begin
    if (((L_item_rec.tsl_owner_country = L_login_ctry) or
       L_security_ind = 'N') or
       (L_item_rec.tsl_owner_country <> L_login_ctry and
       L_security_ind = 'Y' and
       C_rec.column_name NOT in
       ('TSL_DIAMOND_LINE_IND','TSL_DEV_LINE_IND','TSL_LAUNCH_DATE','TSL_POS_CODES','TSL_DEV_END_DATE'))) then
       if L_sql_select is NULL then
          L_sql_insert := 'ia.' || C_rec.column_name;
          L_sql_select := C_rec.column_name;
       else
          L_sql_insert := L_sql_insert || ',ia.' || C_rec.column_name;
          L_sql_select := L_sql_select || ', ' || C_rec.column_name;
       end if;
       -- MrgNBS020155 25-Dec-2010 Ankush/ankush.khanna@in.tesco.com Begin
       --- NBS0020239, Phil Noon, 21-Dec-2010, Begin
       L_build_ins := 'Y';
       --- NBS0020239, Phil Noon, 21-Dec-2010, End
       -- MrgNBS020155 25-Dec-2010 Ankush/ankush.khanna@in.tesco.com End
    end if;
    --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    End
    ---
    L_sql_column := L_sql_column || ', ''' || C_rec.tsl_code || '''';
    -- MrgNBS020155 25-Dec-2010 Ankush/ankush.khanna@in.tesco.com Begin
    --- NBS0020239, Phil Noon, 21-Dec-2010, Begin
    -- Setting of indicator moved inside if
    ----- NBS006264, John Alister Anand, 16-Apr-2007, Begin
    --L_build_ins := 'Y';
    ----- NBS006264, John Alister Anand, 16-Apr-2007, End
    --- NBS0020239, Phil Noon, 21-Dec-2010, End
    -- MrgNBS020155 25-Dec-2010 Ankush/ankush.khanna@in.tesco.com End
  END LOOP;
  ---
  --- NBS006264, John Alister Anand, 16-Apr-2007, Begin
  if L_build_ins = 'Y' then
  --- NBS006264, John Alister Anand, 16-Apr-2007, End
      -- CR236, 14-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
      L_sql_insert := ' insert into item_attributes (item, tsl_country_id, ' || L_sql_select || ' )' ||
                      ' select '''|| I_pack_item ||''','''||I_country_id||''', '||
                      L_sql_insert || ' from item_attributes ia' ||
                      '  where ia.item = ''' || I_component_item || '''' ||
                      '    and ia.tsl_country_id = '''||I_country_id||''';';
      L_sql_select := ' select ' || L_sql_select || ' from item_attributes' ||
                      ' where item = ''' || I_component_item || ''''||
                      ' and tsl_country_id = '''||I_country_id||''';';
      -- CR236, 14-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
      ---
      if L_sql_select is NOT NULL then
         L_statement := 'Declare' || ' Cursor C_get_item_attrib is' ||
                        L_sql_select || ' row_data C_get_item_attrib%ROWTYPE;' ||
                        ' Begin' || ' open C_get_item_attrib;' ||
                        ' fetch C_get_item_attrib into row_data;';
         EXECUTE IMMEDIATE L_statement || L_sql_update || L_close_cursor ||
                           L_sql_insert || L_end;
      end if;
      ---
      L_sql_insert := NULL;
      L_sql_update := NULL;
      L_sql_column := NULL;
      L_sql_select := NULL;
      L_statement  := NULL;
  --- NBS006264, John Alister Anand, 16-Apr-2007, Begin
  end if;
  --- NBS006264, John Alister Anand, 16-Apr-2007, End
  return TRUE;
EXCEPTION
  when RECORD_LOCKED then
     O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                           L_table,
                                           L_program,
                                           'ITEM: ' || I_component_item);
     return FALSE;
  when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
     return FALSE;
END TSL_COPY_COMPONENT_ATTRIB;
-- NBS005922, John Alister Anand, 10-Apr-2008, End
----------------------------------------------------------------------------------------------------
-- 8-May-2008 Satish B.N, satish.narasimhaiah@in.tesco.com ModN138 Begin
----------------------------------------------------------------------------------------------------
-- Function : TSL_GET_BUYING_OFF_DESC
-- Purpose  : Function to retrieve the description of the buying office when buying off id is given.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_BUYING_OFF_DESC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_office_desc   IN OUT TSL_BUYING_OFFICE.BUYING_OFFICE_DESC%TYPE,
                                 I_office_id     IN     TSL_BUYING_OFFICE.BUYING_OFFICE_ID%TYPE)
RETURN BOOLEAN IS
   --Local variable declaration
   L_program       VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.TSL_GET_BUYING_OFF_DESC';

   -- Cursor c_buying_off_desc
   cursor C_BUYING_OFF_DESC is
   select buying_office_desc
     from tsl_buying_office
    where buying_office_id = I_office_id;


BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_BUYING_OFF_DESC',
                    'TSL_BUYING_OFFICE',
                    'buying_office_id:'||TO_CHAR(I_office_id));

   open C_BUYING_OFF_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_BUYING_OFF_DESC',
                    'TSL_BUYING_OFFICE',
                    'buying_office_id:'||TO_CHAR(I_office_id));

   fetch C_BUYING_OFF_DESC into O_office_desc;

   if C_BUYING_OFF_DESC%NOTFOUND then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_BUYING_OFF',
                                                  NULL,
                                                  L_program,
                                                  NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_BUYING_OFF_DESC',
                    'TSL_BUYING_OFFICE',
                    'buying_office_id:'||TO_CHAR(I_office_id));

   close C_BUYING_OFF_DESC;

   return TRUE;
EXCEPTION
   when OTHERS then
      if C_BUYING_OFF_DESC%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_BUYING_OFF_DESC',
                          'TSL_BUYING_OFFICE',
                          'buying_office_id:'||TO_CHAR(I_office_id));
         close C_BUYING_OFF_DESC;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_BUYING_OFF_DESC;
----------------------------------------------------------------------------------------------------
-- Function : TSL_GET_COUNTY_DESC
-- Purpose  : Function to get the description of the county when county id is provided.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_COUNTY_DESC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_county_desc   IN OUT TSL_COUNTY.COUNTY_DESC%TYPE,
                             I_county_id     IN     TSL_COUNTY.COUNTY_ID%TYPE)
RETURN BOOLEAN IS
   --Local variable declaration
   L_program       VARCHAR2(64)    := 'ITEM_ATTRIB_SQL.TSL_GET_COUNTY_DESC';

   -- Cursor c_county_desc
   cursor C_COUNTY_DESC is
   select county_desc
     from tsl_county
    where county_id = I_county_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_COUNTY_DESC',
                    'TSL_COUNTY',
                    'county_id:'||TO_CHAR(I_county_id));

   open C_COUNTY_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_COUNTY_DESC',
                    'TSL_COUNTY',
                    'county_id:'||TO_CHAR(I_county_id));

   fetch C_COUNTY_DESC into O_county_desc;

   if C_COUNTY_DESC%NOTFOUND then
      O_error_message :=SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_COUNTY_ID',
                                                 NULL,
                                                 L_program,
                                                 NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_COUNTY_DESC',
                    'TSL_COUNTY',
                    'county_id:'||TO_CHAR(I_county_id));

   close C_COUNTY_DESC;

   return TRUE;
EXCEPTION
   when OTHERS then
      if C_COUNTY_DESC%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_COUNTY_DESC',
                          'TSL_COUNTY',
                          'county_id:'||TO_CHAR(I_county_id));
         close C_COUNTY_DESC;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_COUNTY_DESC;
----------------------------------------------------------------------------------------------------
-- 8-May-2008 Satish B.N, satish.narasimhaiah@in.tesco.com ModN138 End
----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Mod By:      Bahubali Dongare Bahubali.Dongare@in.tesco.com
-- Mod Date:    12-May-2008
-- Mod Ref:     ModN111
-- Mod Details: New function TSL_GET_COMMON_IND has been added.
----------------------------------------------------------------------------------------------
FUNCTION TSL_GET_COMMON_IND(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            O_common_ind      IN OUT   ITEM_MASTER.TSL_COMMON_IND%TYPE,
                            I_item            IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

    --
    L_program       VARCHAR2(100) := 'ITEM_ATTRIB_SQL.TSL_GET_COMMON_IND';
    --

    --This cursor will return the Common Product Indicator for the passed Item
    CURSOR C_GET_COMMOND_IND is
    select im.tsl_common_ind
      from item_master im
     where im.item    = I_item;

BEGIN
   -- Check if I_item is NULL
   if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                                NULL,
                                                L_program,
                                                NULL);
      return FALSE;
   end if;
   --
   -- Open Cursor C_GET_COMMOND_IND
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COMMOND_IND',
                    'ITEM_MASTER',
                    'ITEM NO: ' ||TO_CHAR( I_item));
   open C_GET_COMMOND_IND;
   -- Fetch Cursor C_GET_COMMOND_IND in to O_common_ind
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COMMOND_IND',
                    'ITEM_MASTER',
                    'ITEM NO: ' ||TO_CHAR( I_item));
   fetch C_GET_COMMOND_IND into O_common_ind;

   if C_GET_COMMOND_IND%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
   end if;
   -- Close Cursor C_GET_COMMOND_IND
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'ITEM_MASTER',
                    'ITEM NO: ' ||TO_CHAR( I_item));
   close C_GET_COMMOND_IND;

   return TRUE;

EXCEPTION
    when OTHERS then
       if C_GET_COMMOND_IND%ISOPEN then
          SQL_LIB.SET_MARK('CLOSE',
                           'C_GET_COMMOND_IND',
                           'ITEM_MASTER',
                            NULL);
          close C_GET_COMMOND_IND;
       end if;
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              TO_CHAR(SQLCODE));
       return FALSE;

END TSL_GET_COMMON_IND;
----------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-- Mod By     : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
-- Mod Date   : 10-JUN-2008
-- Mod Ref    : CR114
-- Mod Details: Added New Function TSL_GET_CHILD_COUNT which will get the child count as well as
--              the item number of the child of a parent.
--------------------------------------------------------------------------------------------
FUNCTION TSL_GET_CHILD_COUNT(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_count         IN OUT NUMBER,
                             O_child         IN OUT ITEM_MASTER.ITEM%TYPE,
                             I_parent_item   IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

L_program VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_CHILD_COUNT';
L_item    ITEM_MASTER.ITEM%TYPE;

CURSOR C_GET_CHILD is
   select item
     from item_master
    where item_parent = I_parent_item ;

BEGIN
   O_count  := 0;
   O_child  := NULL;

   if I_parent_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'NULL',
                                            'NULL',
                                            'NULL');
      return FALSE;
   end if;

   FOR C_rec in  C_GET_CHILD  LOOP

       L_item  := C_rec.item;
       O_count := O_count + 1;
   END LOOP;

   If O_count = 1 then

      O_child := L_item;
      return TRUE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
     return FALSE;
END TSL_GET_CHILD_COUNT;
--------------------------------------------------------------------------------------------
-- Mod By     : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
-- Mod Date   : 10-JUN-2008
-- Mod Ref    : CR114
-- Mod Details: Added New Function TSL_GET_REQD_ATTRIBS that will check if the required item attributes in the
--              destination subclass are present in Item attributes table for source Item.
-------------------------------------------------------------------------------------------
FUNCTION TSL_GET_REQD_ATTRIBS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exists        IN OUT VARCHAR2,
                              I_item          IN     ITEM_MASTER.ITEM%TYPE,
                              I_dept          IN     ITEM_MASTER.DEPT%TYPE,
                              I_class         IN     ITEM_MASTER.CLASS%TYPE,
                              I_subclass      IN     ITEM_MASTER.SUBCLASS%TYPE,
                              -- 22-May-2009 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS012988 Begin
                              I_item_type     IN     VARCHAR2)
                              -- 22-May-2009 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS012988 End
RETURN BOOLEAN IS

TYPE T_CURSOR is           REF CURSOR ;
V_CURSOR                   T_CURSOR;

L_program  VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_REQD_ATTRIBS';
L_dummy    VARCHAR2(1)  :=  NULL;
---Tarun Kumar Mishra , 02-july-2008  Defect fix NBS00007549 Begin----
L_info     MERCH_HIER_DEFAULT.INFO%TYPE;
L_ia_count NUMBER(2);
---Tarun Kumar Mishra , 02-july-2008  Defect fix NBS00007549 End----
-- Defect NBS00012856 Raghuveer P R, 15th May 2009 - Begin
L_item_ind NUMBER(1);
--30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 Begin
-- 3.4 to 3.5a merge Raghuveer P R (MrgNBS015130) 24-Oct-2009 -Begin
--L_found    VARCHAR2(1)  :=  'N';
-- 3.4 to 3.5a merge Raghuveer P R (MrgNBS015130) 24-Oct-2009 -End
--30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 End
-- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A Begin
L_country_id VARCHAR2(1);
-- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A End

  CURSOR C_GET_ITEM_INFO is
     select decode(iem.pack_ind, 'Y', 1, decode(iem.tsl_base_item, iem.item, 2, 3))
       from item_master iem
      where iem.item = I_item;
-- Defect NBS00012856 Raghuveer P R, 15th May 2009 - End

   CURSOR C_GET_REQD_INFO  is
   select distinct m.tsl_column_name column_name
    -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A Begin
         ,mhd.tsl_country_id
      -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A End
     from tsl_map_item_attrib_code m,
      -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A Begin
          merch_hier_default mhd
    where mhd.required_ind  = 'Y'
      and mhd.dept          = I_dept
      and mhd.class         = I_class
      and mhd.subclass      = I_subclass
      and mhd.info          = m.tsl_code
      -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A End
      and m.tsl_code in (select c.code
                           from code_detail c
                          where c.code_type = 'TIAT'
                            and c.code in (select mhd.info
                                             from merch_hier_default mhd
                                            where mhd.dept = I_dept
                                              and mhd.class = I_class
                                              and mhd.subclass = I_subclass
                                              and mhd.required_ind = 'Y'
                                              --30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 Begin
                                              -- Defect NBS00012856 Raghuveer P R, 15th May 2009 - Begin
                                              --and decode(L_item_ind, 1, mhd.tsl_pack_ind, 2, mhd.tsl_base_ind, 3, mhd.tsl_var_ind) = 'Y'
                                              -- Defect NBS00012856 Raghuveer P R, 15th May 2009 - End
                                              --30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 End
                                              -- 22-May-2009 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS012988 Begin
                                              and ((I_item_type ='I' and mhd.tsl_item_lvl=3 and mhd.tsl_pack_ind='N')
                                               or  (I_item_type ='P' and mhd.tsl_item_lvl=2 and mhd.tsl_pack_ind='Y') or            (I_item_type is null)                                                           )
                                              -- 22-May-2009 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS012988 End
                                           ));

---Tarun Kumar Mishra , 02-july-2008  Defect fix NBS00007549 Begin----
    CURSOR C_GET_INFO  is
      select mhd.info
             -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A Begin
             ,mhd.tsl_country_id
             -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A End
        from merch_hier_default mhd
       where mhd.dept = I_dept
         and mhd.class = I_class
         and mhd.subclass = I_subclass
         and mhd.required_ind = 'Y'
         and mhd.info = 'ITEMA';

    CURSOR C_GET_COUNT  is
      Select count(*)
        from item_attributes ia
       Where ia.item           = I_item;


---Tarun Kumar Mishra , 02-july-2008  Defect fix NBS00007549 End----

BEGIN
  O_exists := 'Y';
  --30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 Begin
  -- Defect NBS00012856 Raghuveer P R, 15th May 2009 - Begin
   --SQL_LIB.SET_MARK('OPEN',
   --                 'C_GET_ITEM_INFO',
   --                 'ITEM_MASTER',
   --                 'Item: '||I_item);
   --open C_GET_ITEM_INFO;
   --SQL_LIB.SET_MARK('FETCH',
   --                 'C_GET_ITEM_INFO',
   --                 'ITEM_MASTER',
   --                 'Item: '||I_item);
   --fetch C_GET_ITEM_INFO into L_item_ind;

   --SQL_LIB.SET_MARK('OPEN',
   --                 'C_GET_ITEM_INFO',
   --                 'ITEM_MASTER',
   --                 'Item: '||I_item);
   --close C_GET_ITEM_INFO;
   -- Defect NBS00012856 Raghuveer P R, 15th May 2009 - End
   --30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 End
  FOR C_rec in  C_GET_REQD_INFO  LOOP
      --30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 Begin
      --L_found := 'Y';
      --30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 End
      -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A Begin
     L_country_id := C_rec.tsl_country_id;
     if L_country_id != 'B' then
     -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A End
     -- Added one more condition to check attributes country wise
        open V_CURSOR FOR
           'select 1
             from ITEM_ATTRIBUTES IA
            where  IA.ITEM = '''||I_item||'''
              and '||C_rec.column_name||' is NOT NULL
              and IA.tsl_country_id ='''||c_rec.tsl_country_id||'''';

        fetch V_CURSOR into L_dummy;
        if V_CURSOR%NOTFOUND  then
           O_exists  := 'N';
           return TRUE;
        end if;
        close V_CURSOR;
     -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A Begin
     -- If the filed is required for both the countries then it will check for attributes
     -- in both UK and ROI.
     else
        open V_CURSOR FOR
            'select 1
               from ITEM_ATTRIBUTES IA
              where  IA.ITEM = '''||I_item||'''
                and '||C_rec.column_name||' is NOT NULL
                and IA.tsl_country_id = ''U''';

        fetch V_CURSOR into L_dummy;
        if V_CURSOR%NOTFOUND  then
            O_exists  := 'N';
            return TRUE;
        end if;
        close V_CURSOR;
        -- for ROI
        open V_CURSOR FOR
             'select 1
                from ITEM_ATTRIBUTES IA
               where  IA.ITEM = '''||I_item||'''
                 and '||C_rec.column_name||' is NOT NULL
                 and IA.tsl_country_id = ''R''';

        fetch V_CURSOR into L_dummy;
        if V_CURSOR%NOTFOUND  then
            O_exists  := 'N';
            return TRUE;
        end if;
        close V_CURSOR;
     end if;
     -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A End
  END LOOP;
     --30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 Begin
     -- 3.4 to 3.5a merge Raghuveer P R (MrgNBS015130) 24-Oct-2009 -Begin
     --if L_found = 'N' then
     --   O_exists := 'N';
     --   return TRUE;
     --end if;
     -- 3.4 to 3.5a merge Raghuveer P R (MrgNBS015130) 24-Oct-2009 -End
     --30-Nov-2009 Tesco HSC/Usha Patil       Defect Id: NBS00015504 End

---Tarun Kumar Mishra , 02-july-2008  Defect fix NBS00007549 Begin----
     /*SQL_LIB.SET_MARK('open','C_GET_COUNT','item_attributes',NULL);
     open  C_GET_COUNT;

     SQL_LIB.SET_MARK('fetch','C_GET_COUNT','item_attributes',NULL);
     fetch C_GET_COUNT  into L_ia_count;

     SQL_LIB.SET_MARK('close','C_GET_COUNT','item_attributes',NULL);
     close C_GET_COUNT;


     SQL_LIB.SET_MARK('open','C_GET_INFO','merch_hier_default',NULL);
     open  C_GET_INFO ;

     SQL_LIB.SET_MARK('fetch','C_GET_INFO','merch_hier_default',NULL);
     fetch C_GET_INFO into L_info ;

     if C_GET_INFO%FOUND and L_ia_count = 0 then
        O_exists  := 'N';
        return TRUE;
     end if ;

     SQL_LIB.SET_MARK('close','C_GET_INFO','merch_hier_default',NULL);
     close C_GET_INFO;*/

---Tarun Kumar Mishra , 02-july-2008  Defect fix NBS00007549 End----
   -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A Begin
   L_country_id := NULL;
   FOR c_rec1 in C_GET_INFO LOOP
      if c_rec1.tsl_country_id is NOT null then
         L_country_id := c_rec1.tsl_country_id;
         if L_country_id != 'B' then
            SQL_LIB.SET_MARK('open','C_GET_COUNT','item_attributes',NULL);
            open  C_GET_COUNT;

            SQL_LIB.SET_MARK('fetch','C_GET_COUNT','item_attributes',NULL);
            fetch C_GET_COUNT  into L_ia_count;

            SQL_LIB.SET_MARK('close','C_GET_COUNT','item_attributes',NULL);
            close C_GET_COUNT;

            if L_ia_count = 0 then
               O_exists  := 'N';
            end if;
         else
            SQL_LIB.SET_MARK('open','C_GET_COUNT','item_attributes',NULL);
            open  C_GET_COUNT;

            SQL_LIB.SET_MARK('fetch','C_GET_COUNT','item_attributes',NULL);
            fetch C_GET_COUNT  into L_ia_count;

            SQL_LIB.SET_MARK('close','C_GET_COUNT','item_attributes',NULL);
            close C_GET_COUNT;

            if L_ia_count < 2 then
               O_exists  := 'N';
            end if;
         end if;
      end if;
   END LOOP;
   -- 04-Dec-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com CR236A End


     return TRUE;
EXCEPTION
    when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END  TSL_GET_REQD_ATTRIBS;
--------------------------------------------------------------------------------------------
-- Mod By     : Tarun Kumar Mishra , tarun.mishra@in.tesco.com
-- Mod Date   : 10-JUN-2008
-- Mod Ref    : CR114
-- Mod Details: Added New Function TSL_ITEM_EXISTS which will be used to check whether a particular
--              item exist in the item_master or not.
--------------------------------------------------------------------------------------------
FUNCTION TSL_ITEM_EXISTS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_exists        IN OUT BOOLEAN,
                         I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

L_program VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_ITEM_EXISTS';
L_dummy   VARCHAR2(1);

CURSOR C_EXISTS is
   select 'x'
     from  item_master
    where item = I_item;
BEGIN

   if I_item is NULL then

      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                            NULL,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('open','C_EXISTS', 'ITEM_MASTER', NULL);
   open C_EXISTS;

   SQL_LIB.SET_MARK('fetch','C_EXISTS', 'ITEM_MASTER', NULL);
   fetch C_EXISTS into L_dummy;

   if C_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('close', 'C_EXISTS', 'ITEM_MASTER', NULL);
   close C_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_ITEM_EXISTS;


----------------------------------------------------------------------------------------------------
-- Begin ModN127 Wipro/JK 08-May-2008
---------------------------------------------------------------------------------------------
-- Function : TSL_GET_ITEM_ATTRIB
-- Mod      : ModN127
-- Purpose  : This new function will retrieve all the information for an item in the
--            item_attributes table.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_ITEM_ATTRIB(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_item_attrib_rec  IN OUT ITEM_ATTRIBUTES%ROWTYPE,
                             I_item             IN     ITEM_MASTER.ITEM%TYPE,
                             -- CR236, 14-Sep-2009, Sarayu Gouda, sarayu.gouda@in.tesco.com Begin
                             I_country          IN     ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE)
                             -- CR236, 14-Sep-2009, Sarayu Gouda, sarayu.gouda@in.tesco.com End
   RETURN BOOLEAN IS
   ---
   L_program       VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_GET_ITEM_ATTRIB';
   ---
   cursor C_ITEM_ATTR is
      select *
        from item_attributes
       where item = I_item
       -- CR236, 14-Sep-2009, Sarayu Gouda, sarayu.gouda@in.tesco.com Begin
         and tsl_country_id = I_country;
       -- CR236, 14-Sep-2009, Sarayu Gouda, sarayu.gouda@in.tesco.com End
   ---
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_ATTR',
                    'item_attributes',
                    'Item: '|| I_item);

   open C_ITEM_ATTR ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_ATTR',
                    'item_attributes',
                    'Item: '|| I_item);

   fetch C_ITEM_ATTR into O_item_attrib_rec;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_ATTR',
                    'item_attributes',
                    'Item: '|| I_item);
   close C_ITEM_ATTR;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_ITEM_ATTR%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_ATTR',
                          'item_attributes',
                          'Item: '|| I_item);
         close C_ITEM_ATTR;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_GET_ITEM_ATTRIB;
-- End ModN127 Wipro/JK 08-May-2008
---------------------------------------------------------------------------------------------
-- 14-July-2008 Nitin Kumar, nitin.kumar@in.tesco.com - Mod N144 Begin
---------------------------------------------------------------------------------------------
-- Function : TSL_CHECK_DUMMYTU_IND
-- Mod      : Mod N144
-- Purpose  : This new function will return an item is PWDTU(Product with dummy traded units)
--            or not.
---------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_DUMMYTU_IND(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_dummy           IN OUT BOOLEAN,
                               I_item            IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   ---
   L_program      VARCHAR2(100)                      := 'ITEM_ATTRIB_SQL.TSL_CHECK_DUMMYTU_IND';
   L_dummy        ITEM_ATTRIBUTES.TSL_PWDTU_IND%TYPE := NULL;
   L_item_level   ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level   ITEM_MASTER.TRAN_LEVEL%TYPE;
   ---
   CURSOR C_DUMMY_CHK is
     select NVL(tsl_pwdtu_ind, 'N')
       from item_attributes
      where item = I_item;
    ---
    CURSOR C_L1_DUMMY_CHK is
      select 'x'
        from item_attributes ia,
             item_master iem
       where ia.tsl_pwdtu_ind = 'Y'
         and ia.item          = iem.item
         and iem.item_parent  = I_item
         and iem.item         = iem.tsl_base_item
         and iem.item_level   = 2
         and iem.tran_level   = 2;
    ---
BEGIN
   -- Check if input parameter is NULL
   if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                NULL,
                                                L_program,
                                                NULL);
      return FALSE;
   end if;
   --
   -- Getting the item level
   if ITEM_ATTRIB_SQL.GET_LEVELS (O_error_message,
                                  L_item_level,
                                  L_tran_level,
                                  I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_item_level = 2 then
      SQL_LIB.SET_MARK('OPEN',
                       'C_DUMMY_CHK',
                       'item_attributes',
                       'Item: '|| I_item);

      open C_DUMMY_CHK ;
      SQL_LIB.SET_MARK('FETCH',
                       'C_DUMMY_CHK',
                       'item_attributes',
                       'Item: '|| I_item);

      fetch C_DUMMY_CHK into L_dummy;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_DUMMY_CHK',
                       'item_attributes',
                       'Item: '|| I_item);
      close C_DUMMY_CHK;

      if L_dummy = 'Y' then
         O_dummy := TRUE;
      else
         O_dummy := FALSE;
      end if;
      ---
   elsif L_item_level = 1 then
      SQL_LIB.SET_MARK('OPEN',
                       'C_L1_DUMMY_CHK',
                       'item_attributes',
                       'Item: '|| I_item);

      open C_L1_DUMMY_CHK;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_L1_DUMMY_CHK',
                       'item_attributes',
                       'Item: '|| I_item);

      fetch C_L1_DUMMY_CHK into L_dummy;
      ---
      if C_L1_DUMMY_CHK%FOUND then
         O_dummy := TRUE;
      else
         O_dummy := FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_L1_DUMMY_CHK',
                       'item_attributes',
                       'Item: '|| I_item);
      close C_L1_DUMMY_CHK;
      ---
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_DUMMY_CHK%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_DUMMY_CHK',
                          'item_attributes',
                          'Item: '|| I_item);
         close C_DUMMY_CHK;
      end if;
      ---
      if C_L1_DUMMY_CHK%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_L1_DUMMY_CHK',
                          'item_attributes',
                          'Item: '|| I_item);
         close C_L1_DUMMY_CHK;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;

END TSL_CHECK_DUMMYTU_IND;
-- 14-July-2008 Nitin Kumar, nitin.kumar@in.tesco.com - Mod N144 End
---------------------------------------------------------------------------
-- 28-Jul-2008, Satish B.N, DefNBS008033 Begin
---------------------------------------------------------------------------------------------
-- Function : UPDATE_PRIM_REF_ITEM
-- Mod      : DefNBS008033/CR114N112
-- Purpose  : This function update primary_ref_item_ind of Level3 item and EAN8 number
--            when EANOWN number is overwritten by EAN8 number
---------------------------------------------------------------------------------------------
FUNCTION UPDATE_PRIM_REF_ITEM (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item          IN     ITEM_MASTER.ITEM%TYPE,
                               P_ref_ind       IN     VARCHAR2)
   return BOOLEAN IS
   ---
   L_error_message      RTK_ERRORS.RTK_TEXT%TYPE := NULL;

   L_program            VARCHAR2(64) := 'ITEM_ATTRIBUTE_SQL.UPDATE_PRIM_REF_ITEM';
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   L_exists             NUMBER;
   ---
   cursor C_LOCK_RECORD is
      select 'x'
        from item_master
       where item = I_item
         for update nowait;
   ---
   cursor C_ITEM_EXISTS is
      select 1
        from item_master
       where item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_EXISTS',
                    'ITEM_MASTER',
                    'ITEM_NO: '||I_item);
   open C_ITEM_EXISTS;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_EXISTS',
                    'ITEM_MASTER',
                    'ITEM_NO: '||I_item);
   fetch C_ITEM_EXISTS into L_exists;
   ---
   if C_ITEM_EXISTS%FOUND then

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_RECORD',
                        'ITEM_MASTER',
                       'ITEM_NO: '||I_item);
      open C_LOCK_RECORD;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_RECORD',
                       'ITEM_MASTER',
                       'ITEM_NO: '||I_item);
      close C_LOCK_RECORD;
      ---
      -- Update itemmaster
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ITEM_MASTER',
                       'ITEM_NO: '||I_item);
      update item_master iem
         set iem.primary_ref_item_ind = P_ref_ind
       where iem.item = I_item;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_EXISTS',
                    'ITEM_MASTER',
                    'ITEM_NO: '||I_item);
   close C_ITEM_EXISTS;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'C_LOCK_RECORD',
                                            'ITEM_MASTER',
                                            'ITEM_NO: '||I_item);
      return FALSE;
   when OTHERS then
     if C_ITEM_EXISTS%ISOPEN then
        SQL_LIB.SET_MARK('CLOSE',
                         'C_ITEM_EXISTS',
                         'ITEM_MASTER',
                         'ITEM_NO: '||I_item);
        close C_ITEM_EXISTS;
     end if;
     if C_LOCK_RECORD%ISOPEN then
     SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_RECORD',
                       'ITEM_MASTER',
                       'ITEM_NO: '||I_item);
      close C_LOCK_RECORD;
     end if;
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              to_char(SQLCODE));
   return FALSE;
END UPDATE_PRIM_REF_ITEM;
-- 28-Jul-2008, Satish B.N, DefNBS008033 End
---------------------------------------------------------------------------
-- 05-Aug-2008, Satish B.N, DefNBS008219 Begin
---------------------------------------------------------------------------
-- Function : DELETE_ITEM_ATTRIBUTES
-- Mod      : DefNBS008219
-- Purpose  : This new function will delete item_attributs for the given item
---------------------------------------------------------------------------------------------
FUNCTION DELETE_ITEM_ATTRIBUTES (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_success          OUT BOOLEAN,
                                 I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN IS
   ---
 --  L_error_message      RTK_ERRORS.RTK_TEXT%TYPE := NULL;
   L_program            VARCHAR2(64) := 'ITEM_ATTRIBUTE_SQL.DELETE_ITEM_ATTRIBUTES';
   L_exists             NUMBER;
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_RECORD is
      select 'x'
        from item_attributes
       where item = I_item
         for update nowait;
   ---
   cursor C_ITEM_EXISTS is
      select 1
        from item_attributes
       where item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'ITEM_NO: '||I_item);
   open C_ITEM_EXISTS;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'ITEM_NO: '||I_item);
   fetch C_ITEM_EXISTS into L_exists;
   ---
   if C_ITEM_EXISTS%FOUND then

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_RECORD',
                        'ITEM_ATTRIBUTES',
                       'ITEM_NO: '||I_item);
      open C_LOCK_RECORD;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_RECORD',
                       'ITEM_ATTRIBUTES',
                       'ITEM_NO: '||I_item);
      close C_LOCK_RECORD;
      ---
      -- delete item_attributs
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'ITEM_ATTRIBUTES',
                       'ITEM_NO: '||I_item);
      delete item_attributes iat
       where iat.item = I_item;
      O_success := TRUE;
   else
     O_success := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'ITEM_NO: '||I_item);
   close C_ITEM_EXISTS;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'C_LOCK_RECORD',
                                            'ITEM_ATTRIBUTES',
                                            'ITEM_NO: '||I_item);
      return FALSE;
   when OTHERS then
     if C_ITEM_EXISTS%ISOPEN then
        SQL_LIB.SET_MARK('CLOSE',
                         'C_ITEM_EXISTS',
                         'ITEM_ATTRIBUTES',
                         'ITEM_NO: '||I_item);
        close C_ITEM_EXISTS;
     end if;
     if C_LOCK_RECORD%ISOPEN then
     SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_RECORD',
                       'ITEM_ATTRIBUTES',
                       'ITEM_NO: '||I_item);
      close C_LOCK_RECORD;
     end if;
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              to_char(SQLCODE));
   return FALSE;
END DELETE_ITEM_ATTRIBUTES;
-- 05-Aug-2008, Satish B.N, DefNBS008219 End
---------------------------------------------------------------------------
-- 06-Aug-2008 - Dhuraison Prince - NBS00006802 - BEGIN
---------------------------------------------------------------------------------------------------
-- Function : TSL_INSERT_DEL_REC_INFO                                                            --
-- Purpose  : This function is used to insert all item description records, which have been      --
--            deleted, into temporary table TSL_TEMP_DELETE_REC_INFO.                            --
---------------------------------------------------------------------------------------------------
FUNCTION TSL_INSERT_DEL_REC_INFO (O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_item              IN       TSL_TEMP_DELETE_REC_INFO.ITEM%TYPE,
                                  I_effective_date    IN       TSL_TEMP_DELETE_REC_INFO.EFFECTIVE_DATE%TYPE,
                                  I_desc_1            IN       TSL_TEMP_DELETE_REC_INFO.DESC1%TYPE,
                                  I_desc_2            IN       TSL_TEMP_DELETE_REC_INFO.DESC2%TYPE,
                                  I_desc_3            IN       TSL_TEMP_DELETE_REC_INFO.DESC3%TYPE,
                                  I_desc_4            IN       TSL_TEMP_DELETE_REC_INFO.DESC4%TYPE,
                                  I_desc_5            IN       TSL_TEMP_DELETE_REC_INFO.DESC5%TYPE,
                                  I_promo_override    IN       TSL_TEMP_DELETE_REC_INFO.PRMO_OVERRIDE%TYPE,
                                  I_episel_category   IN       TSL_TEMP_DELETE_REC_INFO.EPISEL_CATEGORY%TYPE,
                                  I_font_1            IN       TSL_TEMP_DELETE_REC_INFO.FONT_1%TYPE,
                                  I_font_2            IN       TSL_TEMP_DELETE_REC_INFO.FONT_2%TYPE,
                                  I_font_3            IN       TSL_TEMP_DELETE_REC_INFO.FONT_3%TYPE,
                                  I_font_4            IN       TSL_TEMP_DELETE_REC_INFO.FONT_4%TYPE,
                                  I_table_name        IN       TSL_TEMP_DELETE_REC_INFO.TABLE_NAME%TYPE,
                                  -- CR236, 31-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                  I_country_id          IN     VARCHAR2,
                                  -- CR236, 31-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                  -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
                                  I_ntl_range_class     IN     TSL_ITEM_RANGE.NTL_RANGE_CLASS%TYPE     DEFAULT NULL,
                                  I_ntl_rest_code       IN     TSL_ITEM_RANGE.NTL_REST_CODE%TYPE       DEFAULT NULL,
                                  I_high_st_range_class IN     TSL_ITEM_RANGE.HIGH_ST_RANGE_CLASS%TYPE DEFAULT NULL,
                                  I_high_st_rest_code   IN     TSL_ITEM_RANGE.HIGH_ST_REST_CODE%TYPE   DEFAULT NULL)
                                  -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End

return BOOLEAN is

   -- variables declaration
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_INSERT_DEL_REC_INFO';

BEGIN

   -- validating the input parameters for NULL condition
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_effective_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_effective_date',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_table_name is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_table_name',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('INSERT',
                    'TSL_TEMP_DELETE_REC_INFO',
                    NULL,
                    NULL);
   ---
   -- inserting the values in the tsl_temp_delete_rec_info table
   insert into tsl_temp_delete_rec_info (item,
                                         effective_date,
                                         desc1,
                                         desc2,
                                         desc3,
                                         desc4,
                                         desc5,
                                         prmo_override,
                                         episel_category,
                                         font_1,
                                         font_2,
                                         font_3,
                                         font_4,
                                         table_name,
                                         -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
                                         ntl_range_class,
                                         ntl_rest_code,
                                         high_st_range_class,
                                         high_st_rest_code,
                                         -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
                                         -- CR236, 31-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                         tsl_country_id
                                         -- CR236, 31-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                         )
                                 values (I_item,
                                         I_effective_date,
                                         I_desc_1,
                                         I_desc_2,
                                         I_desc_3,
                                         I_desc_4,
                                         I_desc_5,
                                         I_promo_override,
                                         I_episel_category,
                                         I_font_1,
                                         I_font_2,
                                         I_font_3,
                                         I_font_4,
                                         I_table_name,
                                         -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
                                         I_ntl_range_class,
                                         I_ntl_rest_code,
                                         I_high_st_range_class,
                                         I_high_st_rest_code,
                                         -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
                                         -- CR236, 31-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                         I_country_id
                                         -- CR236, 31-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                         );
   ---
   return TRUE;
   ---

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_INSERT_DEL_REC_INFO;
---------------------------------------------------------------------------------------------------
-- Function : TSL_DELETE_DESC_INFO                                                               --
-- Purpose  : This function is used to delete all the description records of children items when --
--            their parent item's descriptions have been deleted.                                --
---------------------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_DESC_INFO (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item            IN       ITEM_MASTER.ITEM%TYPE,
                               I_all_tables      IN       BOOLEAN)
                               ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 Begin
                               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
                               --Removed the CR236 code
                               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
                               ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 End
return BOOLEAN is

   -- variables declaration
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_DELETE_DESC_INFO';
   L_table     VARCHAR2(64) := NULL;
   ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 Begin
   --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
   L_country_id VARCHAR2(1);
   --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
   ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 End
   -- exceptions declaration
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   -- cursors declaration
   CURSOR C_RECORDS_TO_DEL is
   select effective_date,
          desc1,
          desc2,
          desc3,
          desc4,
          desc5,
          prmo_override,
          episel_category,
          font_1,
          font_2,
          font_3,
          font_4,
          table_name,
          -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
          ntl_range_class,
          ntl_rest_code,
          high_st_range_class,
          high_st_rest_code,
          -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
          --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
          tsl_country_id
          --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
     from tsl_temp_delete_rec_info;
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
      --Removed the CR236 code
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
BEGIN

   -- validating the input parameters for NULL condition
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_all_tables then
       ---
       FOR C_rec in C_RECORDS_TO_DEL
       LOOP
          ---
         if C_rec.table_name = 'TSL_ITEMDESC_BASE' then
             L_table := 'TSL_ITEMDESC_BASE';
             ---
            SQL_LIB.SET_MARK('DELETE',
                             L_table,
                             NULL,
                             NULL);
            ---
            -- deleting the child(ren) item records from TSL_ITEMDESC_BASE table
            delete from tsl_itemdesc_base tib
             where tib.item in (select item
                                  from item_master im
                                 where im.item_parent      = I_item
                                    or im.item_grandparent = I_item)
               and tib.effective_date   = C_rec.effective_date
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
               -- Removed the CR236 code change
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
               and tib.base_item_desc_1 = C_rec.desc1
               and tib.base_item_desc_2 = C_rec.desc2
               and tib.base_item_desc_3 = C_rec.desc3;
         end if;
         ---
         if C_rec.table_name = 'TSL_ITEMDESC_SEL' then
            L_table := 'TSL_ITEMDESC_SEL';
            ---
            SQL_LIB.SET_MARK('DELETE',
                             L_table,
                             NULL,
                             NULL);
            ---
            -- deleting the child(ren) item records from TSL_ITEMDESC_SEL table
            delete from tsl_itemdesc_sel tis
             where tis.item in (select item
                                  from item_master im
                                 where im.item_parent      = I_item
                                    or im.item_grandparent = I_item)
            and tis.effective_date = C_rec.effective_date
            --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
            -- Removed the CR236 code change
            --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
            and tis.sel_desc_1     = C_rec.desc1
            and tis.sel_desc_2     = C_rec.desc2
            and tis.sel_desc_3     = C_rec.desc3;
         end if;
         ---
         if C_rec.table_name = 'TSL_ITEMDESC_TILL' then
            L_table := 'TSL_ITEMDESC_TILL';
            ---
            SQL_LIB.SET_MARK('DELETE',
                             L_table,
                             NULL,
                             NULL);
            ---
            -- deleting the child(ren) item records from TSL_ITEMDESC_TILL table
            delete from tsl_itemdesc_till tit
             where tit.item in (select item
                                  from item_master im
                                 where im.item_parent      = I_item
                                    or im.item_grandparent = I_item)
               and tit.effective_date = C_rec.effective_date
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
               -- Removed the CR236 code change
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
               and tit.till_desc      = C_rec.desc1;
         end if;
         ---
         if C_rec.table_name = 'TSL_ITEMDESC_PACK' then
            L_table := 'TSL_ITEMDESC_PACK';
            ---
            SQL_LIB.SET_MARK('DELETE',
                             L_table,
                             NULL,
                             NULL);
            ---
            -- deleting the child(ren) item records from TSL_ITEMDESC_PACK table
            delete from tsl_itemdesc_pack tip
             where tip.pack_no in (select item
                                       from item_master im
                                      where im.item_parent = I_item)
               and tip.effective_date = C_rec.effective_date
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
               -- Removed the CR236 code change
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
               and tip.pack_desc      = C_rec.desc1;
         end if;
         ---
         if C_rec.table_name = 'TSL_ITEMDESC_ISS' then
            L_table := 'TSL_ITEMDESC_ISS';
            ---
            SQL_LIB.SET_MARK('DELETE',
                             L_table,
                             NULL,
                             NULL);
            ---
            -- deleting the child(ren) item records from TSL_ITEMDESC_ISS table
            delete from tsl_itemdesc_iss tii
             where tii.item in (select item
                                  from item_master im
                                 where im.item_parent      = I_item
                                    or im.item_grandparent = I_item)
               and tii.effective_date = C_rec.effective_date
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
               -- Removed the CR236 code change
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
               and tii.iss_desc_1     = C_rec.desc1
               and tii.font_1         = C_rec.font_1
               and tii.iss_desc_2     = C_rec.desc2
               and tii.font_2         = C_rec.font_2
               and tii.iss_desc_3     = C_rec.desc3
               and tii.font_3         = C_rec.font_3
               and tii.iss_desc_4     = C_rec.desc4
               and tii.font_4         = C_rec.font_4;
         end if;
         ---
         if C_rec.table_name = 'TSL_ITEMDESC_EPISEL' then
            L_table := 'TSL_ITEMDESC_EPISEL';
            ---
            SQL_LIB.SET_MARK('DELETE',
                             L_table,
                             NULL,
                             NULL);
            ---
            -- deleting the child(ren) item records from TSL_ITEMDESC_EPISEL table
            delete from tsl_itemdesc_episel tie
             where tie.item in (select item
                                  from item_master im
                                 where im.item_parent      = I_item
                                    or im.item_grandparent = I_item)
               and tie.effective_date = C_rec.effective_date
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
               -- Removed the CR236 code change
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
               and tie.episel_desc_1  = C_rec.desc1
               and tie.episel_desc_2  = C_rec.desc2
               and tie.episel_desc_3  = C_rec.desc3
               and tie.episel_desc_4  = C_rec.desc4
               and tie.episel_desc_5  = C_rec.desc5;
         end if;
         ---
         -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
         if C_rec.table_name = 'TSL_ITEM_RANGE' then
            L_table := 'TSL_ITEM_RANGE';
            --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
            L_country_id := C_rec.tsl_country_id;
            --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
            SQL_LIB.SET_MARK('DELETE',
                             L_table,
                             NULL,
                             NULL);
            -- Deleting the child(ren) item records from TSL_ITEM_RANGE table
            delete from tsl_item_range ier
             where ier.item in (select item
                                  from item_master im
                                 where im.item_parent      = I_item
                                    or im.item_grandparent = I_item)
               and ier.effective_date      = C_rec.effective_date
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
               -- Removed the CR236 code
               and ier.tsl_country_id   = L_country_id
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
               --DefNBS008692, 01-Sep-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
               --Added the NVL
               and nvl(ier.ntl_range_class,'-999')     = nvl(C_rec.ntl_range_class,'-999')
               and nvl(ier.ntl_rest_code,'-999')       = nvl(C_rec.ntl_rest_code,'-999')
               and nvl(ier.high_st_range_class,'-999') = nvl(C_rec.high_st_range_class,'-999')
               and nvl(ier.high_st_rest_code,'-999')   = nvl(C_rec.high_st_rest_code,'-999');
               --DefNBS008692, 01-Sep-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
         end if;
         -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
      END LOOP;
      ---
   -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
   else
      L_table := 'TSL_ITEM_RANGE';

      SQL_LIB.SET_MARK('DELETE',
                       L_table,
                       NULL,
                       NULL);
      -- Deleting the child(ren) item records from TSL_ITEM_RANGE table
       FOR C_rec in C_RECORDS_TO_DEL
       LOOP
         if C_rec.table_name = 'TSL_ITEM_RANGE' then
            --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
            L_country_id := C_rec.tsl_country_id;
            --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
            delete from tsl_item_range ier
             where ier.item in (select item
                                  from item_master im
                                 where im.item_parent      = I_item
                                    or im.item_grandparent = I_item)
               and ier.effective_date      = C_rec.effective_date
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
               --Removed the CR236 change
               and ier.tsl_country_id   = L_country_id
               --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
               --DefNBS008692, 01-Sep-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
               --Added the NVL
               and nvl(ier.ntl_range_class,'-999')     = nvl(C_rec.ntl_range_class,'-999')
               and nvl(ier.ntl_rest_code,'-999')       = nvl(C_rec.ntl_rest_code,'-999')
               and nvl(ier.high_st_range_class,'-999') = nvl(C_rec.high_st_range_class,'-999')
               and nvl(ier.high_st_rest_code,'-999')   = nvl(C_rec.high_st_rest_code,'-999');
               --DefNBS008692, 01-Sep-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
         end if;
      END LOOP;
   -- 06-Aug-2008 DefNBS008268 Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
   end if;
   ---
   return TRUE;
   ---

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   ---
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_DELETE_DESC_INFO;
---------------------------------------------------------------------------------------------------
-- 06-Aug-2008 - Dhuraison Prince - NBS00006802 - END
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_EPW
-- Purpose:       This function will retrieve the epw indicator from item_attributes for the
--passed item
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EPW(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     O_tpw_ind            IN OUT   ITEM_ATTRIBUTES.TSL_EPW_IND%TYPE,
                     I_item               IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_EPW';

   cursor C_GET_TPW is
      select ia.tsl_epw_ind
        from item_attributes ia
       where ia.item = I_item;
BEGIN
   --- Check required input parameters
   if I_item is NULL then
      O_tpw_ind  := NULL;
      return TRUE;-- Level-1 Item
   end if;

   --- Initialize the output variables
   O_tpw_ind  := NULL;

   --- Get the required information
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TPW',
                    'item_attributes',
                    'I_item: '||I_item);
   open C_GET_TPW;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TPW',
                    'item_attributes',
                    'I_item: '||I_item);
   fetch C_GET_TPW into O_tpw_ind;
   if C_GET_TPW%NOTFOUND  then
      O_tpw_ind := NULL;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_TPW',
                       'item_attributes',
                       'I_item: '||I_item);
      close C_GET_TPW;

      return TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TPW',
                    'item_attributes',
                    'I_item: '||I_item);
   close C_GET_TPW;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END TSL_GET_EPW;
---------------------------------------------------------------------------------------------------
-- CR236, 31-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
---------------------------------------------------------------------------------------------------
-- Author       : Nitin Gour, nitin.gour@in.tesco.com
-- Function Name: TSL_SET_EPW
-- Purpose      : Set the EPW indicator and country id in ITEM_ATTRIBUTES table for specific item
---------------------------------------------------------------------------------------------------
--26-Mar-2010  -   Manikandan V  - MrgNBS016802   -  Begin
---------------------------------------------------------------------------------------------------
-- CR261, 19-Mar-2010, Shireen Sheosunker, shireen.sheosunker@uk.tesco.com (BEGIN)
---------------------------------------------------------------------------------------------------
FUNCTION TSL_SET_EPW(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     I_item               IN       ITEM_MASTER.ITEM%TYPE,
                     I_country            IN       ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE,
                     I_end_date           IN       ITEM_ATTRIBUTES.TSL_END_DATE%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_SET_EPW';
   L_dummy     VARCHAR2(1)  := NULL;
   L_end_date ITEM_ATTRIBUTES.TSL_END_DATE%TYPE;
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,Begin
   L_table                       VARCHAR2(30)   := 'ITEM_ATTRIBUTES';
   RECORD_LOCKED                 EXCEPTION;
   PRAGMA                        EXCEPTION_INIT(RECORD_LOCKED, -54);
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End

   CURSOR C_EPW_EXISTS(CP_country_id  ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE) is
   select 'X', tsl_end_date
     from item_attributes
    where item           = I_item
      and tsl_country_id = CP_country_id;
   --
   CURSOR C_LOCK_RECORD(CP_country_id  ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE) is
   select 'X', tsl_end_date
     from item_attributes
    where item           = I_item
      and tsl_country_id = CP_country_id
      for update nowait;
   --
BEGIN
   --
   case (I_country)
      when 'U' then
         --
         SQL_LIB.SET_MARK('OPEN',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         open C_EPW_EXISTS('U');
         SQL_LIB.SET_MARK('FETCH',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         fetch C_EPW_EXISTS into L_dummy, L_end_date;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         close C_EPW_EXISTS;
         --
         if L_dummy is NULL then
            --
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            insert into item_attributes (item,
                                         tsl_epw_ind,
                                         tsl_country_id,
                                         tsl_end_date)
                                 values (I_item,
                                         'Y',
                                         'U',
                                         I_end_date);
            --
            L_dummy := NULL;

            SQL_LIB.SET_MARK('OPEN',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_EPW_EXISTS('R');
            SQL_LIB.SET_MARK('FETCH',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            fetch C_EPW_EXISTS into L_dummy, L_end_date;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_EPW_EXISTS;

            if L_dummy is NOT NULL then
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_RECORD',
                                'ITEM_ATTRIBUTES',
                                'Item: '||I_item);
               open C_LOCK_RECORD('R');
               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_RECORD',
                                'ITEM_ATTRIBUTES',
                                'Item: '||I_item);
               close C_LOCK_RECORD;

               update item_attributes
                  set tsl_epw_ind = 'N', tsl_end_date = NULL
                where item           = I_item
                  and tsl_country_id = 'R';

            end if;
            --
         else
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_LOCK_RECORD('U');
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_LOCK_RECORD;
            --
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            update item_attributes
               set tsl_epw_ind = 'Y', tsl_end_date = I_end_date
             where item           = I_item
               and tsl_country_id = 'U';
            --
            L_dummy := NULL;

            SQL_LIB.SET_MARK('OPEN',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_EPW_EXISTS('R');
            SQL_LIB.SET_MARK('FETCH',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            fetch C_EPW_EXISTS into L_dummy, L_end_date;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_EPW_EXISTS;

            if L_dummy is NOT NULL then
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_RECORD',
                                'ITEM_ATTRIBUTES',
                                'Item: '||I_item);
               open C_LOCK_RECORD('R');
               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_RECORD',
                                'ITEM_ATTRIBUTES',
                                'Item: '||I_item);
               close C_LOCK_RECORD;
-- Defect 17565 Shireen Sheosunker, shireen.sheosunker@uk.tesco.com Begin
               --update item_attributes
                 -- set tsl_epw_ind = 'N', tsl_end_date = null
                --where item           = I_item
                 -- and tsl_country_id = 'R';
-- Defect 17565 Shireen Sheosunker, shireen.sheosunker@uk.tesco.com End
            end if;
            --
         end if;
         --
      when 'R' then
         --
         SQL_LIB.SET_MARK('OPEN',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         open C_EPW_EXISTS('R');
         SQL_LIB.SET_MARK('FETCH',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         fetch C_EPW_EXISTS into L_dummy, L_end_date;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         close C_EPW_EXISTS;
         --
         if L_dummy is NULL then
            --
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            insert into item_attributes (item,
                                         tsl_epw_ind,
                                         tsl_country_id,
                                         tsl_end_date)
                                 values (I_item,
                                         'Y',
                                         'R',
                                         I_end_date);
            --
            L_dummy := NULL;

            SQL_LIB.SET_MARK('OPEN',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_EPW_EXISTS('U');
            SQL_LIB.SET_MARK('FETCH',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            fetch C_EPW_EXISTS into L_dummy, L_end_date;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_EPW_EXISTS;

            if L_dummy is NOT NULL then
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_RECORD',
                                'ITEM_ATTRIBUTES',
                                'Item: '||I_item);
               open C_LOCK_RECORD('U');
               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_RECORD',
                                'ITEM_ATTRIBUTES',
                                'Item: '||I_item);
               close C_LOCK_RECORD;

               update item_attributes
                  set tsl_epw_ind = 'N', tsl_end_date = null
                where item           = I_item
                  and tsl_country_id = 'U';

            end if;
            --
         else
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_LOCK_RECORD('R');
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_LOCK_RECORD;
            --
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            update item_attributes
               set tsl_epw_ind = 'Y', tsl_end_date = I_end_date
             where item           = I_item
               and tsl_country_id = 'R';
            --
            L_dummy := NULL;

            SQL_LIB.SET_MARK('OPEN',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_EPW_EXISTS('U');
            SQL_LIB.SET_MARK('FETCH',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            fetch C_EPW_EXISTS into L_dummy, L_end_date;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_EPW_EXISTS',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_EPW_EXISTS;

            if L_dummy is NOT NULL then
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_RECORD',
                                'ITEM_ATTRIBUTES',
                                'Item: '||I_item);
               open C_LOCK_RECORD('U');
               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_RECORD',
                                'ITEM_ATTRIBUTES',
                                'Item: '||I_item);
               close C_LOCK_RECORD;
-- Defect 17565 Shireen Sheosunker, shireen.sheosunker@uk.tesco.com Begin
               --update item_attributes
                --  set tsl_epw_ind    = 'N', tsl_END_DATE = NULL
                --where item           = I_item
                --  and tsl_country_id = 'U';
-- Defect 17565 Shireen Sheosunker, shireen.sheosunker@uk.tesco.com End

            end if;
            --
         end if;
         --
      when 'B' then
         --
         SQL_LIB.SET_MARK('OPEN',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         open C_EPW_EXISTS('U');
         SQL_LIB.SET_MARK('FETCH',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         fetch C_EPW_EXISTS into L_dummy, L_end_date;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         close C_EPW_EXISTS;
         --
         if L_dummy is NULL then
            --
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            insert into item_attributes (item,
                                         tsl_epw_ind,
                                         tsl_country_id,
                                         tsl_end_date)
                                 values (I_item,
                                         'Y',
                                         'U',
                                         I_end_date);
            --
         else
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_LOCK_RECORD('U');
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_LOCK_RECORD;
            --
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            update item_attributes
               set tsl_epw_ind = 'Y', tsl_end_date = I_end_date
             where item           = I_item
               and tsl_country_id = 'U';
            --
         end if;

         L_dummy := NULL;

         --
         SQL_LIB.SET_MARK('OPEN',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         open C_EPW_EXISTS('R');
         SQL_LIB.SET_MARK('FETCH',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         fetch C_EPW_EXISTS into L_dummy, L_end_date;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         close C_EPW_EXISTS;
         --
         if L_dummy is NULL then
            --
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            insert into item_attributes (item,
                                         tsl_epw_ind,
                                         tsl_country_id,
                                         tsl_end_date)
                                 values (I_item,
                                         'Y',
                                         'R',
                                         I_end_date);
            --
         else
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_LOCK_RECORD('R');
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_LOCK_RECORD;
            --
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            update item_attributes
               set tsl_epw_ind = 'Y', tsl_end_date = I_end_date
             where item           = I_item
               and tsl_country_id = 'R';
            --
         end if;
         --
      when 'N' then
         --
         SQL_LIB.SET_MARK('OPEN',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         open C_EPW_EXISTS('U');
         SQL_LIB.SET_MARK('FETCH',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         fetch C_EPW_EXISTS into L_dummy, L_end_date;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         close C_EPW_EXISTS;
         --
         if L_dummy is NULL then
            --
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            insert into item_attributes (item,
                                         tsl_epw_ind,
                                         tsl_country_id,
                                         tsl_end_date)
                                 values (I_item,
                                         'N',
                                         'U',
                                         I_end_date);
            --
         else
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_LOCK_RECORD('U');
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_LOCK_RECORD;
            --
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            update item_attributes
               set tsl_epw_ind = 'N', tsl_end_date = null
             where item           = I_item
               and tsl_country_id = 'U';
            --
         end if;

         L_dummy := NULL;

         --
         SQL_LIB.SET_MARK('OPEN',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         open C_EPW_EXISTS('R');
         SQL_LIB.SET_MARK('FETCH',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         fetch C_EPW_EXISTS into L_dummy, L_end_date;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         close C_EPW_EXISTS;
         --
         if L_dummy is NULL then
            --
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            insert into item_attributes (item,
                                         tsl_epw_ind,
                                         tsl_country_id,
                                         tsl_end_date)
                                 values (I_item,
                                         'N',
                                         'R',
                                         I_end_date);
            --
         else
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_LOCK_RECORD('R');
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_LOCK_RECORD;
            --
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            update item_attributes
               set tsl_epw_ind = 'N', tsl_end_date = null
             where item           = I_item
               and tsl_country_id = 'R';
            --
         end if;
         --
        -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
        -- CR288d, 19-Jul-2010, Nishant Gupta, nishant.gupta@in.tesco.com, Begin
      when 'P' then
         --
         SQL_LIB.SET_MARK('OPEN',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         open C_EPW_EXISTS('U');
         SQL_LIB.SET_MARK('FETCH',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         fetch C_EPW_EXISTS into L_dummy, L_end_date;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         close C_EPW_EXISTS;
         --
         if L_dummy is NULL then
            --
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            insert into item_attributes (item,
                                         tsl_epw_ind,
                                         tsl_country_id,
                                         tsl_end_date)
                                 values (I_item,
                                         'N',
                                         'U',
                                         I_end_date);
            --
         else
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_LOCK_RECORD('U');
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_LOCK_RECORD;
            --
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            update item_attributes
               set tsl_epw_ind = 'N',
                   tsl_end_date = null
             where item           = I_item
               and tsl_country_id = 'U';
            --
         end if;

         L_dummy := NULL;

      when 'S' then
         --
         SQL_LIB.SET_MARK('OPEN',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         open C_EPW_EXISTS('R');
         SQL_LIB.SET_MARK('FETCH',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         fetch C_EPW_EXISTS into L_dummy, L_end_date;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EPW_EXISTS',
                          'ITEM_ATTRIBUTES',
                          'Item: '||I_item);
         close C_EPW_EXISTS;
         --
         if L_dummy is NULL then
            --
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            insert into item_attributes (item,
                                         tsl_epw_ind,
                                         tsl_country_id,
                                         tsl_end_date)
                                 values (I_item,
                                         'N',
                                         'R',
                                         I_end_date);
            --
         else
            --
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            open C_LOCK_RECORD('R');
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_RECORD',
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            close C_LOCK_RECORD;
            --
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_ATTRIBUTES',
                             'Item: '||I_item);
            update item_attributes
               set tsl_epw_ind = 'N',
                   tsl_end_date = null
             where item           = I_item
               and tsl_country_id = 'R';
            --
         end if;
         --
        -- CR288d, 19-Jul-2010, Nishant Gupta, nishant.gupta@in.tesco.com, End
        -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end

   end case;
   --
   return TRUE;

EXCEPTION
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011, Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_SET_EPW;
-- CR261, 19-Mar-2010, Shireen Sheosunker, shireen.sheosunker@uk.tesco.com (End)
--26-Mar-2010  -   Manikandan V  - MrgNBS016802   -  End
---------------------------------------------------------------------------------------------------
-- CR236, 31-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
---------------------------------------------------------------------------------------------------
-- 13-Aug-2008 - Govindarajan K - NBS00008445 - Begin
---------------------------------------------------------------------------------------------------
-- Function : TSL_COMMON_L2_EXIST                                                            --
-- Purpose  : This function is used check L2 common product available for the L1 item
---------------------------------------------------------------------------------------------------
FUNCTION TSL_COMMON_L2_EXIST (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exists        IN OUT VARCHAR2,
                              I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_COMMON_L2_EXIST';
   L_item          ITEM_MASTER.ITEM%TYPE;
   ---
   CURSOR C_COMM_ITEM_EXIST is
     select iem.item
       from item_master iem,
            system_options so
      where iem.item_parent                    = I_item
        and NVL(iem.tsl_primary_country,'99') != so.tsl_origin_country
        and iem.item_level                     = 2
        and iem.tran_level                     = 2
        and iem.tsl_common_ind                 = 'Y';
   ---
BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_item,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_COMM_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item : '||I_item);
   open C_COMM_ITEM_EXIST ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_COMM_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item : '||I_item);

   fetch C_COMM_ITEM_EXIST into L_item;

   if C_COMM_ITEM_EXIST%NOTFOUND then
      O_exists := 'N';
   else
      O_exists := 'Y';
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_COMM_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item : '||I_item);
   close C_COMM_ITEM_EXIST ;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_COMM_ITEM_EXIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_COMM_ITEM_EXIST',
                          'ITEM_MASTER',
                          'Item : '||I_item);
         close C_COMM_ITEM_EXIST;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
     ---
     return FALSE;
     ---
END TSL_COMMON_L2_EXIST;
---------------------------------------------------------------------------------------------------
-- Function : TSL_RECLASS_L2_COMMON                                                            --
-- Purpose  : This function is used check L2 common product available for the L1 item
--            irrespective of the country
---------------------------------------------------------------------------------------------------
FUNCTION TSL_RECLASS_L2_COMMON (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_exists        IN OUT VARCHAR2,
                                I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   L_program       VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_COMMON_L2_EXIST';
   L_item          ITEM_MASTER.ITEM%TYPE;
   ---
   CURSOR C_COMM_ITEM_EXIST is
     select iem.item
       from item_master iem,
            system_options so
      where iem.item_parent = I_item
        and iem.item_level = 2
        and iem.tran_level = 2
        and iem.tsl_common_ind = 'Y';
   ---
BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_item,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_COMM_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item : '||I_item);
   open C_COMM_ITEM_EXIST ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_COMM_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item : '||I_item);

   fetch C_COMM_ITEM_EXIST into L_item;

   if C_COMM_ITEM_EXIST%NOTFOUND then
      O_exists := 'N';
   else
      O_exists := 'Y';
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_COMM_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item : '||I_item);
   close C_COMM_ITEM_EXIST ;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_COMM_ITEM_EXIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_COMM_ITEM_EXIST',
                          'ITEM_MASTER',
                          'Item : '||I_item);
         close C_COMM_ITEM_EXIST;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
     ---
     return FALSE;
     ---
END TSL_RECLASS_L2_COMMON;
---------------------------------------------------------------------------------------------------
-- 13-Aug-2008 - Govindarajan K - NBS00008445 - End
---------------------------------------------------------------------------------------------------
-- DefNBS008703, 5-Sep-2008 Tesco HSC/Satish Begin
---------------------------------------------------------------------------------------------------
-- Function : TSL_CHECK_OCC_MATCH_EAN
-- Purpose  : This new function will check if the OCC number is generated by prefixing 0 with
--            the EAN of the component of simple pack
---------------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_OCC_MATCH_EAN (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_match         IN OUT BOOLEAN,
                                  I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_CHECK_OCC_MATCH_EAN ';
   L_item          ITEM_MASTER.ITEM%TYPE;
   L_found         VARCHAR2(1) := 'N';
   ---
   CURSOR C_GET_EAN is
      select iem.item
        from item_master iem
       where iem.item_parent = (select item
                                  from packitem p
                                 where p.pack_no = (select item_parent
                                                      from item_master
                                                     where item = I_item))
         and iem.item_number_type = 'EANOWN';

   ---
BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_item,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---

   FOR c_rec in C_GET_EAN
   LOOP
      if I_item = '0'||c_rec.item then
         L_found := 'Y';
      end if;
   END LOOP;

   if L_found = 'Y' then
      O_match := TRUE;
   else
      O_match := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      if C_GET_EAN%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_EAN',
                          'ITEM_MASTER',
                          'Item : '||I_item);
         close C_GET_EAN;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_OCC_MATCH_EAN;
---------------------------------------------------------------------------------------------------
-- DefNBS008703, 5-Sep-2008 Tesco HSC/Satish End
---------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- CR187, 24-Nov-2008, Nitin Kumar, nitin.kumar@in.tesco.com BEGIN
----------------------------------------------------------------------------------------------------
-- Author        : Nitin Kumar, nitin.kumar@in.tesco.com
-- Function Name : TSL_LOW_LVL_CODE_DESC
-- Purpose       : This function will get the Low level code description for the code attached at
--                 subclass.
----------------------------------------------------------------------------------------------------
FUNCTION  TSL_LOW_LVL_CODE_DESC (O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_code_desc         IN OUT  TSL_LOW_LVL_CODE.LOW_LVL_CODE_DESC%TYPE,
                                 O_exist             IN OUT  BOOLEAN,
                                 I_dept              IN      SUBCLASS.DEPT%TYPE,
                                 I_grp               IN      SUBCLASS.CLASS%TYPE,
                                 I_sub_grp           IN      SUBCLASS.SUBCLASS%TYPE,
                                 I_lvl_code          IN      TSL_LOW_LVL_CODE.LOW_LVL_CODE%TYPE)
   return BOOLEAN is
   --
   L_program                  VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_LOW_LVL_CODE_DESC';
   --

   -- cursor C_CODE_DESC
   -- This cursor will get the Low level code description for the attached subgroup.
   CURSOR C_CODE_DESC is
   select lc.low_lvl_code_desc
     from tsl_low_lvl_code lc
    where lc.dept         = I_dept
      and lc.class        = I_grp
      and lc.subclass     = I_sub_grp
      --24-Jun-2009 Tesco HSC/Usha Patil            Defect Id:NBS00013345 Begin
      and lc.low_lvl_code = translate(I_lvl_code,'_',' ');
      --24-Jun-2009 Tesco HSC/Usha Patil            Defect Id:NBS00013345 End

BEGIN
   -- Check if any of input parameter is NULL
   if I_dept is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_dept',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;

   if I_grp is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_grp',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;

   if I_sub_grp is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_sub_grp',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;

   if I_lvl_code is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_lvl_code',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;
   --
   --Fetch the Code Description of input code
   SQL_LIB.SET_MARK('OPEN',
                    'C_CODE_DESC',
                    'TSL_LOW_LVL_CODE',
                    'Code = ' || I_lvl_code);
   open C_CODE_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CODE_DESC',
                    'TSL_LOW_LVL_CODE',
                    'Code = ' || I_lvl_code);
   fetch C_CODE_DESC into O_code_desc;

   if C_CODE_DESC%FOUND then
      O_exist := TRUE;
   else
      O_exist     := FALSE;
      O_code_desc := NULL;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CODE_DESC',
                    'TSL_LOW_LVL_CODE',
                    'Code = ' || I_lvl_code);
   close C_CODE_DESC;
   --
   return TRUE;

EXCEPTION
   when OTHERS then
      if C_CODE_DESC%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CODE_DESC',
                          'TSL_LOW_LVL_CODE',
                          'Code = ' || I_lvl_code);
         close C_CODE_DESC;
      end if;
      --
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_LOW_LVL_CODE_DESC;
-----------------------------------------------------------------------------------------------------
-- CR187, 24-Nov-2008, Nitin Kumar, nitin.kumar@in.tesco.com END
----------------------------------------------------------------------------------------------------
-- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
----------------------------------------------------------------------------------------------------
-- Author        : Nitin Gour, nitin.gour@in.tesco.com
-- Function Name : TSL_UPDATE_MU_IND
-- Purpose       : This is a new function which will update the MU indicator of the input items.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_MU_IND(O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                           I_item              IN      ITEM_MASTER.ITEM%TYPE,
                           I_mode              IN      VARCHAR2)
   RETURN BOOLEAN is

   L_program                  VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_UPDATE_MU_IND';

   -- Pass only LEVEL 1 item to get its TPND (Simple Pack) and OCC
   CURSOR C_GET_PACK is
   select im.item
     from item_master im
    where NVL(im.tsl_mu_ind, 'N') = 'N'
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            where NVL(im2.tsl_mu_ind, 'N') = 'Y'
                                            start with im2.item            = I_item
                                            connect by prior im2.item      = im2.item_parent))
   connect by prior im.item       = im.item_parent;
   --
   CURSOR C_GET_ITEM is
   select item
    from item_master im
   where NVL(im.tsl_mu_ind, 'N') = 'N'
     and im.tsl_launch_base_ind  = 'N'
   start with im.item            = I_item
   connect by prior im.item      = im.item_parent;
   --
   CURSOR C_LOCK(CP_item ITEM_MASTER.ITEM%TYPE) is
   select 'X'
     from item_master im
    where im.item = CP_item;
   --
BEGIN
   --
   if I_mode = 'P' then -- Get the Packs and its children
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      FOR C_rec in C_GET_PACK
      LOOP
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK',
                          'ITEM_MASTER',
                          'Item = ' || C_rec.item);
         open C_LOCK(C_rec.item);
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK',
                          'ITEM_MASTER',
                          'Item = ' || C_rec.item);
         close C_LOCK;
         --
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'Item: '||I_item);
         update item_master im
            set im.tsl_mu_ind = 'Y'
          where im.item       = C_rec.item;
         --
      END LOOP;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_PACK',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
   elsif I_mode = 'I'  then -- Get the Level2 Items and Variant Items
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      FOR C_rec in C_GET_ITEM
      LOOP
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK',
                          'ITEM_MASTER',
                          'Item = ' || C_rec.item);
         open C_LOCK(C_rec.item);
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK',
                          'ITEM_MASTER',
                          'Item = ' || C_rec.item);
         close C_LOCK;
         --
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'Item: '||I_item);
         update item_master im
            set im.tsl_mu_ind = 'Y'
          where im.item       = C_rec.item;
         --
      END LOOP;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
   end if;
   --
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_UPDATE_MU_IND;
----------------------------------------------------------------------------------------------------
-- CR171, 04-Mar-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
----------------------------------------------------------------------------------------------------
-- 24-Jun-2009 Tesco HSC/Usha Patil                    Defect Id: NBS00013345 Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_GET_ITEM_LVLCODE
--Purpose  : the function translates the space in item_attributes.tsl_low_lvl_code to '_'.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_ITEM_LVLCODE(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item               IN     ITEM_MASTER.ITEM%TYPE,
                              I_low_lvl_code       IN OUT TSL_LOW_LVL_CODE.LOW_LVL_CODE%TYPE,
                              -- NBS00015205, 02-Nov-2009, Nitin Kumar, nitin.kumar@in.tesco.com, Begin
                              I_country_id         IN     VARCHAR2)
                              -- NBS00015205, 02-Nov-2009, Nitin Kumar, nitin.kumar@in.tesco.com, End
RETURN BOOLEAN IS
   L_program              VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_GET_ITEM_LVLCODE';

   CURSOR C_TRANS_LVL_CODE is
   select translate(tsl_low_lvl_code,' ','_') tsl_low_lvl_code_trans
     from item_attributes
    where item = I_item
    -- NBS00015205, 02-Nov-2009, Nitin Kumar, nitin.kumar@in.tesco.com, Begin
      and tsl_country_id  = I_country_id;
    -- NBS00015205, 02-Nov-2009, Nitin Kumar, nitin.kumar@in.tesco.com, End

BEGIN

   FOR rec in C_TRANS_LVL_CODE
   LOOP
      I_low_lvl_code := rec.tsl_low_lvl_code_trans;
   END LOOP;

   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_GET_ITEM_LVLCODE;
----------------------------------------------------------------------------------------------------
-- 24-Jun-2009 Tesco HSC/Usha Patil                    Defect Id: NBS00013345 End
----------------------------------------------------------------------------------------------------
-- MrgNBS015130  Wipro/JK   23-Oct-09  Begin
-- MrgNBS015080 21-Oct-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
----------------------------------------------------------------------------------------------------
-- 03-Aug-2009 Tesco HSC/Shweta Madnawat               CR242 Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_CHECK_BARCODE_BRAND
--Purpose  : The function will check if the barcode created by the user on screen is a Tesco own
--           brand or not.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_BARCODE_BRAND(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_tesco_brand_ind    IN OUT VARCHAR2,
                                 I_code               IN     CODE_DETAIL.CODE%TYPE)
RETURN BOOLEAN IS
   L_program              VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_CHECK_BARCODE_BRAND';
   L_tbrand               VARCHAR2(1);

   -- CR249, 07-Oct-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   -- Cursor condition has been revised under CR242 for CR249
   CURSOR C_CHECK_TBRAND(L_code_type in CODE_HEAD.CODE_TYPE%TYPE) is
   select 'X'
     from code_detail cdd,
          system_options sop
    where code_type                       = L_code_type
      and sop.tsl_ratio_pack_number_type != I_code
      and code                            = I_code;
   -- CR249, 07-Oct-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_TBRAND',
                    'CODE_DETAIL',
                    'Code = ' || I_code);
   open C_CHECK_TBRAND ('TSBC');

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_TBRAND',
                    'CODE_DETAIL',
                    'Code = ' || I_code);
   fetch C_CHECK_TBRAND into L_tbrand;

   if C_CHECK_TBRAND%FOUND then
      O_tesco_brand_ind := 'Y';
   else
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_TBRAND',
                       'CODE_DETAIL',
                       'Code = ' || I_code);
      close C_CHECK_TBRAND;
      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_TBRAND',
                       'CODE_DETAIL',
                       'Code = ' || I_code);
      open C_CHECK_TBRAND ('NTBC');
      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_TBRAND',
                       'CODE_DETAIL',
                       'Code = ' || I_code);
      fetch C_CHECK_TBRAND into L_tbrand;
      if C_CHECK_TBRAND%FOUND then
         O_tesco_brand_ind := 'N';
      end if;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_TBRAND',
                    'CODE_DETAIL',
                    'Code = ' || I_code);
   close C_CHECK_TBRAND;

   return TRUE;
EXCEPTION
   when OTHERS then
      if C_CHECK_TBRAND%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_TBRAND',
                          'CODE_DETAIL',
                          'Code = ' || I_code);
         close C_CHECK_TBRAND;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_CHECK_BARCODE_BRAND;
----------------------------------------------------------------------------------------------------
--Function : TSL_UPDATE_BRAND_IND
--Purpose  : The function will update the brand indicator of the barcode and its parent.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_BRAND_IND(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              I_tesco_brand_ind    IN     VARCHAR2,
                              I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program              VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_UPDATE_BRAND_IND';
   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  Begin
   L_item_record          ITEM_MASTER%ROWTYPE;
   L_error_message        RTK_ERRORS.RTK_TEXT%TYPE;
   L_brand                ITEM_ATTRIBUTES.TSL_BRAND%TYPE;
   L_style_item           ITEM_MASTER.ITEM%TYPE;

-- Def014555, 21-Aug-2209, BSD change - Update the brand indicator for TPNB and TPNA also. shweta.madnawat@in.tesco.com - Begin
   /*CURSOR C_PARENT_BRAND is
      select tsl_brand
        from item_attributes
       where item = I_item_parent;*/
   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  End
   CURSOR C_GET_STYLE_FOR_OCC is
      select iem1.item
        from item_master iem1,
             packitem pai,
             item_master iem2
       where iem1.item   = pai.item_parent
         and pai.pack_no = iem2.item_parent
         and iem2.item   = I_item;
  -- Def014555, 21-Aug-2209, BSD change - Update the brand indicator for TPNB and TPNA also. shweta.madnawat@in.tesco.com - End
  --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
  CURSOR C_ITEM_ATTR(I_style_item ITEM_MASTER.ITEM%TYPE) is
    select *
      from item_attributes it
     where it.item =I_style_item;
  --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End

BEGIN
   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  Begin
   -- Def014555, 21-Aug-2209, BSD change - Update the brand indicator for TPNB and TPNA also. shweta.madnawat@in.tesco.com - Begin
   -- Insert the value for brand indicator into item attributes table for the barcode and its parent.
   /*SQL_LIB.SET_MARK('OPEN',
                    'C_PARENT_BRAND;',
                    'ITEM_ATTRIBUTES',
                    'Item = ' || I_item_parent);
   open C_PARENT_BRAND;

   SQL_LIB.SET_MARK('FETCH',
                    'C_PARENT_BRAND;',
                    'ITEM_ATTRIBUTES',
                    'Item = ' || I_item_parent);
   fetch C_PARENT_BRAND into L_brand;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_PARENT_BRAND;',
                    'ITEM_ATTRIBUTES',
                    'Item = ' || I_item_parent);
   close C_PARENT_BRAND;*/
   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  End
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(L_error_message,
                                      L_item_record,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   -- Def014555, 21-Aug-2009, BSD change - Update the brand indicator for TPNB and TPNA also. shweta.madnawat@in.tesco.com - End
   if (L_item_record.pack_ind = 'N' and L_item_record.item_level > L_item_record.tran_level) then
      L_style_item := L_item_record.item_grandparent;
   elsif L_item_record.pack_ind = 'Y' and L_item_record.simple_pack_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_STYLE_FOR_OCC;',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      open C_GET_STYLE_FOR_OCC;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_STYLE_FOR_OCC;',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      fetch C_GET_STYLE_FOR_OCC into L_style_item;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_STYLE_FOR_OCC;',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      close C_GET_STYLE_FOR_OCC;
   elsif L_item_record.pack_ind = 'Y' and L_item_record.simple_pack_ind = 'N' then
      L_style_item := L_item_record.item_parent;
   elsif L_item_record.item_level < L_item_record.tran_level then
      L_style_item := I_item;
   end if;

   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  Begin
   --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
   --Removed DefNBS014490 code change
   FOR rec IN C_ITEM_ATTR(L_style_item)
   LOOP
      if rec.tsl_country_id = 'U' then
         merge into item_attributes ia
          using (select item
                   from item_master
                  start with item_parent is null
                    and item = L_style_item
                connect by prior item = item_parent
                union
                 select item
                   from item_master
                   start with item in (select iem1.item
                                         from packitem pai,
                                              item_master iem1
                                        where pai.item_parent = L_style_item
                                          and iem1.item       = pai.pack_no)
                                          connect by prior item = item_parent) iem
            on (ia.item = iem.item and ia.tsl_country_id = 'U')
          when matched then
            -- DefNBS025693a, 06-Feb-2013, Vatan Jaiswal,vatan.jaiswal@in.tesco.com, Begin
            update set ia.tsl_brand = case
                                         when ia.tsl_brand_ind = I_tesco_brand_ind then ia.tsl_brand
                                         else NULL
                                      end,
            -- DefNBS025693a, 06-Feb-2013, Vatan Jaiswal,vatan.jaiswal@in.tesco.com, End
                       ia.tsl_brand_ind = I_tesco_brand_ind
             where ia.tsl_country_id    = 'U'
          when not matched then
             insert (ia.item,
                     ia.tsl_brand_ind,
                     ia.tsl_country_id)
              values (iem.item,
                      I_tesco_brand_ind,
                      'U');
      elsif rec.tsl_country_id = 'R' then
         merge into item_attributes ia
          using (select item
                   from item_master
                   start with item_parent is null
                     and item = L_style_item
                 connect by prior item = item_parent
                 union
                 select item
                   from item_master
                  start with item in (select iem1.item
                                        from packitem pai,
                                             item_master iem1
                                        where pai.item_parent = L_style_item
                                          and iem1.item       = pai.pack_no)
                                      connect by prior item = item_parent) iem
              on (ia.item = iem.item and ia.tsl_country_id = 'R')
         when matched then
              -- DefNBS025693a, 06-Feb-2013, Vatan Jaiswal,vatan.jaiswal@in.tesco.com, Begin
             update set ia.tsl_brand = case
                                          when ia.tsl_brand_ind = I_tesco_brand_ind then ia.tsl_brand
                                          else NULL
                                       end,
             -- DefNBS025693a, 06-Feb-2013, Vatan Jaiswal,vatan.jaiswal@in.tesco.com, End
                        ia.tsl_brand_ind = I_tesco_brand_ind
              where ia.tsl_country_id    = 'R'
         when not matched then
             insert (ia.item,
                     ia.tsl_brand_ind,
                     ia.tsl_country_id)
             values (iem.item,
                     I_tesco_brand_ind,
                     'R');
      end if;
   END LOOP;
   --Removed the Merge defect code change
   --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End

   -- Def014555, 21-Aug-2209, BSD change Begin
   -- Update the brand indicator of the Base item when variant is passed to the function.
   /*if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(L_error_message,
                                      L_item_record,
                                      I_item_parent) = FALSE then
      return FALSE;
   else
      if L_item_record.tsl_base_item != I_item_parent then
         merge into item_attributes ia
            using (select item
                     from item_master
                    where item        = L_item_record.tsl_base_item
                       or item_parent = L_item_record.tsl_base_item) iem
         on (ia.item = iem.item)
         when matched then
            update set ia.tsl_brand_ind = I_tesco_brand_ind,
                       ia.tsl_brand     = L_brand
         when not matched then
            insert (ia.item,
                    ia.tsl_brand_ind)
            values (iem.item,
                    I_tesco_brand_ind);
      end if;
   end if;*/
   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  End
   -- Def014555, 21-Aug-2209, BSD change End
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_UPDATE_BRAND_IND;
----------------------------------------------------------------------------------------------------
--Function : TSL_BARCODE_DELETED
--Purpose  : The function will check if all the barcodes of the transaction level items are deleted.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_BARCODE_DELETED(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_brcd_dltd          IN OUT VARCHAR2,
                             I_item_parent        IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program              VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_BARCODE_DELETED';
   L_system_options_rec   SYSTEM_OPTIONS%ROWTYPE;
   L_item                 ITEM_MASTER.ITEM%TYPE;
   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  Begin
   L_base_item            ITEM_MASTER.ITEM%TYPE;
   L_item_record          ITEM_MASTER%ROWTYPE;
   L_error_message        RTK_ERRORS.RTK_TEXT%TYPE;

   CURSOR C_GET_BASE_ITEM is
      select tsl_base_item
        from item_master
       where item = I_item_parent;

   CURSOR C_CHECK_BARCODE_DEL_L2 is
       select iem.item
         from item_master iem
        where iem.item_parent in (select item
                                    from item_master
                                   where tsl_base_item = L_base_item)
          and iem.item_number_type != L_system_options_rec.tsl_ratio_pack_number_type
          and not exists (select 'Y'
                            from daily_purge dp
                           where dp.key_value = iem.item);

   CURSOR C_GET_PACK_BARCODE is
      select iem.item
        from item_master iem
       where iem.item_parent = I_item_parent
         and iem.item_number_type != L_system_options_rec.tsl_ratio_pack_number_type
         and not exists (select 'Y'
                           from daily_purge dp
                          where dp.key_value = iem.item);
   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  End

BEGIN
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(L_error_message,
                                      L_item_record,
                                      I_item_parent) = FALSE then
      return FALSE;
   end if;
   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(L_error_message,
                                               L_system_options_rec) = FALSE then
         return FALSE;
   end if;
   if L_item_record.pack_ind = 'N' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_BASE_ITEM',
                       'ITEM_MASTER',
                       'Item = ' || I_item_parent);
      open C_GET_BASE_ITEM;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_BASE_ITEM',
                       'ITEM_MASTER',
                       'Item = ' || I_item_parent);
      fetch C_GET_BASE_ITEM into L_base_item;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_BASE_ITEM',
                       'ITEM_MASTER',
                       'Item = ' || I_item_parent);
      close C_GET_BASE_ITEM;

      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_BARCODE_DEL_L2',
                       'ITEM_MASTER',
                       'Item = ' || L_base_item);
      open C_CHECK_BARCODE_DEL_L2;

      SQL_LIB.SET_MARK('FETCH',
                       'C_CHECK_BARCODE_DEL_L2',
                       'ITEM_MASTER',
                       'Item = ' || L_base_item);
      fetch C_CHECK_BARCODE_DEL_L2 into L_item;

      if L_item is null then
         O_brcd_dltd := 'Y';
      else
         O_brcd_dltd := 'N';
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHECK_BARCODE_DEL_L2',
                       'ITEM_MASTER',
                       'Item = ' || L_base_item);
      close C_CHECK_BARCODE_DEL_L2;
   elsif L_item_record.pack_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_BARCODE',
                       'ITEM_MASTER',
                       'Item = ' || L_base_item);
      open C_GET_PACK_BARCODE;

      SQL_LIB.SET_MARK('FETCH',
                        'C_GET_PACK_BARCODE',
                        'ITEM_MASTER',
                       'Item = ' || L_base_item);
      fetch C_GET_PACK_BARCODE into L_item;
      if L_item is null then
         O_brcd_dltd := 'Y';
      else
         O_brcd_dltd := 'N';
      end if;

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_PACK_BARCODE',
                       'ITEM_MASTER',
                       'Item = ' || L_base_item);
      close C_GET_PACK_BARCODE;
   end if;
   -- DefNBS014490, 12-Aug-2009, shweta.mandawat@in.tesco.com  End

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_BARCODE_DELETED;
----------------------------------------------------------------------------------------------------
--Function : TSL_UPDATE_PACK_BRAND_IND
--Purpose  : The function will update the brand indicator of the pack from its barcodes. This is
--           called from tsl_autogen screen and the input param is the style item.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_PACK_BRAND_IND(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_style_item         IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program              VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_UPDATE_PACK_BRAND_IND';
   L_tesco_brand_ind      VARCHAR2(1);
   L_error_message        RTK_ERRORS.RTK_TEXT%TYPE;

   CURSOR C_SELECT_SP_BCDE is
      select distinct(pai.pack_no)          pack_no,
             iem.item_number_type item_number_type,
             iat.tsl_brand_ind    brand_ind
        from packitem pai,
             item_master iem,
             item_attributes iat
       where pai.item in (select item
                            from item_master
                           where item_parent = I_style_item)
         and pai.pack_no =  iem.item_parent
         and iem.pack_ind = 'Y'
         and iem.simple_pack_ind= 'Y'
         and pai.pack_no = iat.item(+);
BEGIN
   for C_rec in C_SELECT_SP_BCDE
   LOOP
      if c_rec.brand_ind is null then
         if ITEM_ATTRIB_SQL.TSL_CHECK_BARCODE_BRAND(L_error_message,
                                                    L_tesco_brand_ind,
                                                    c_rec.item_number_type) = FALSE then
            return FALSE;
         else
            -- Def014555, 24-Aug-2009, BSD change shweta.mandawat@in.tesco.com - Begin
            /*if ITEM_ATTRIB_SQL.TSL_UPDATE_BRAND_IND(L_error_message,
                                                    L_tesco_brand_ind,
                                                    C_rec.pack_no) = FALSE then
               return FALSE;
            end if; */
            merge into item_attributes ia
               using (select item
                        from item_master
                       where item           = c_rec.pack_no
                          or item_parent    = c_rec.pack_no) iem
               -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -Begin
               on (ia.item = iem.item and ia.tsl_country_id = 'U')
               -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -End
               when matched then
                  update set ia.tsl_brand_ind = L_tesco_brand_ind
                   -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -Begin
                   where ia.tsl_country_id    = 'U'
                   -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -End
               when not matched then
                  insert (ia.item,
                          ia.tsl_brand_ind,
                          -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -Begin
                          ia.tsl_country_id)
                          -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -End
                  values (iem.item,
                          L_tesco_brand_ind,
                          -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -Begin
                          'U');
                          -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -End
            -- Def014555, 24-Aug-2009, BSD change shweta.mandawat@in.tesco.com - End

            -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -Begin
            merge into item_attributes ia
               using (select item
                        from item_master
                       where item           = c_rec.pack_no
                          or item_parent    = c_rec.pack_no) iem
               on (ia.item = iem.item and ia.tsl_country_id = 'R')
               when matched then
                  update set ia.tsl_brand_ind = L_tesco_brand_ind
                   where ia.tsl_country_id    = 'R'
               when not matched then
                  insert (ia.item,
                          ia.tsl_brand_ind,
                          ia.tsl_country_id)
                  values (iem.item,
                          L_tesco_brand_ind,
                          'R');
            -- Defect NBS00015164 Raghuveer P R 28-Oct-2009 -End
         end if;
    end if;
   END LOOP;
   return TRUE;
END TSL_UPDATE_PACK_BRAND_IND;
----------------------------------------------------------------------------------------------------
-- 03-Aug-2009 Tesco HSC/Shweta Madnawat               CR242 End
----------------------------------------------------------------------------------------------------
-- 11-Aug-2009 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS014397 Begin
----------------------------------------------------------------------------------------------------
-- Function Name: TSL_CHECK_ITEMA_DESC_EXIST
--       Purpose: To check if any records exist for the item attributes or item descriptions
--                even if not all the mandatory fields are set. This is called to ensure that
--                records are available, when the item attribute is invoked in View mode
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_ITEMA_DESC_EXIST(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item             IN       ITEM_MASTER.ITEM%TYPE,
                                    O_itema_desc_exist IN OUT   VARCHAR2,
                                    --23-Oct-2009     Wipro/JK    MrgNBS015130     Begin
                                    I_country_id       IN         ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE)
                                    --23-Oct-2009     Wipro/JK    MrgNBS015130     End
RETURN BOOLEAN is

  L_program              VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_CHECK_ITEMA_DESC_EXIST';

   cursor C_ITEM_ATTRIBUTES is
   select 'Y'
     from item_attributes
    where item = I_item
      --23-Oct-2009     Wipro/JK    MrgNBS015130     Begin
      and tsl_country_id = I_country_id
      --23-Oct-2009     Wipro/JK    MrgNBS015130     End
      and ROWNUM = 1
    UNION
   select 'Y'
     from tsl_itemdesc_base
    where item = I_item
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
      -- Removed the MrgNBS015130 code change
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
      and ROWNUM = 1
    UNION
   select 'Y'
     from tsl_itemdesc_episel
    where item = I_item
      ---CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
      -- Removed the MrgNBS015130 code change
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
      and ROWNUM = 1
    UNION
   select 'Y'
     from tsl_itemdesc_iss
    where item = I_item
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
      -- Removed the MrgNBS015130 code change
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
      and ROWNUM = 1
    UNION
   select 'Y'
     from tsl_itemdesc_pack
    where pack_no = I_item
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
      -- Removed the MrgNBS015130 code change
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
      and ROWNUM = 1
    UNION
   select 'Y'
     from tsl_itemdesc_sel
    where item = I_item
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
      -- Removed the MrgNBS015130 code change
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
      and ROWNUM = 1
    UNION
   select 'Y'
     from tsl_itemdesc_till
    where item = I_item
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
      -- Removed the MrgNBS015130 code change
      --CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
      and ROWNUM = 1;

BEGIN

   O_itema_desc_exist := 'N';

   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_ATTRIBUTES',
                    'ITEM_ATTRIBUTES',
                    'ITEM: '||(I_item));
   open C_ITEM_ATTRIBUTES;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_ATTRIBUTES',
                    'ITEM_ATTRIBUTES',
                    'ITEM: '||(I_item));
   fetch C_ITEM_ATTRIBUTES into O_itema_desc_exist;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_ATTRIBUTES',
                    'ITEM_ATTRIBUTES',
                    'ITEM: '||(I_item));
   close C_ITEM_ATTRIBUTES;
   ---
  return TRUE;

EXCEPTION
   when OTHERS then
     if C_ITEM_ATTRIBUTES%ISOPEN then
        SQL_LIB.SET_MARK('CLOSE',
                         'C_ITEM_ATTRIBUTES',
                         'ITEM_ATTRIBUTES',
                         'ITEM: '||(I_item));
        close C_ITEM_ATTRIBUTES;
     end if;
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_CHECK_ITEMA_DESC_EXIST;
---------------------------------------------------------------------------------------------
-- 11-Aug-2009 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com DefNBS014397 End
---------------------------------------------------------------------------------------------
-- 23-Aug-2009 Tesco HSC/Shweta Madnawat               Def014555 Begin
---------------------------------------------------------------------------------------------
--Function : TSL_ITEM_FAMILY_DELETED
--Purpose  : This function will be used to check if all the items of an item family are in
--           delete pending state. If the item passed is a style item then a check will be
--           made for TPNBs and TPNDs (simple) and if TPNB is passed check will be made for
--           all the barcodes. (EANs and OCCs).
---------------------------------------------------------------------------------------------
FUNCTION TSL_ITEM_FAMILY_DELETED(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_family_deleted   IN OUT VARCHAR2,
                                 I_item       IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is

   L_check_barcode       BOOLEAN := FALSE;
   L_tran_level          BOOLEAN := FALSE;
   L_style_item          ITEM_MASTER.ITEM%TYPE;
   L_item                ITEM_MASTER.ITEM%TYPE;
   L_exist               VARCHAR2(1);
   L_item_record         ITEM_MASTER%ROWTYPE;
   L_system_options_rec  SYSTEM_OPTIONS%ROWTYPE;
   L_program             VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_ITEM_FAMILY_DELETED';

   CURSOR C_CHECK_BRCD_DAILY_PURGE is
      select iem.item
        from item_master iem,
             (select item
                from item_master
               start with item_parent is null
                 and item = L_style_item
              connect by prior item = item_parent
              union
              select item
                from item_master
               start with item in (select iem1.item
                                     from packitem pai,
                                          item_master iem1
                                    where pai.item_parent  = L_style_item
                                      and iem1.item = pai.pack_no)
              connect by prior item = item_parent) iem2
       where iem.item = iem2.item
         and not exists (select 'Y'
                           from daily_purge
                          where key_value = iem.item)
         and ((iem.item_level > iem.tran_level)
               and iem.item_number_type != L_system_options_rec.tsl_ratio_pack_number_type
               and not exists (select 'X'
                                 from daily_purge
                                where key_value = iem.item_parent));

   CURSOR C_GET_STYLE_FOR_TPND is
     select iem1.item
       from item_master iem1,
            packitem pai,
            item_master iem2
      where iem1.item   = pai.item_parent
        and pai.pack_no = iem2.item
        and iem2.item   = I_item;

BEGIN
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_system_options_rec) = FALSE then
      return FALSE;
   end if;
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_record,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   -- Def014555, 21-Aug-2209, BSD change - Check if the whole item family has been deleted before enabling the
   -- brand ind on item attributes screen. shweta.madnawat@in.tesco.com - Begin
   if L_item_record.item_level = L_item_record.tran_level then
      if L_item_record.pack_ind = 'N' then
         L_style_item := L_item_record.item_parent;
      elsif (L_item_record.pack_ind = 'Y' and L_item_record.simple_pack_ind = 'Y') then
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_STYLE_FOR_TPND;',
                          'ITEM_MASTER',
                          'Item = ' || I_item);
         open C_GET_STYLE_FOR_TPND;

         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_STYLE_FOR_TPND;',
                          'ITEM_MASTER',
                          'Item = ' || I_item);
         fetch C_GET_STYLE_FOR_TPND into L_style_item;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_STYLE_FOR_TPND;',
                          'ITEM_MASTER',
                          'Item = ' || I_item);

         close C_GET_STYLE_FOR_TPND;
      elsif L_item_record.pack_ind = 'Y' and L_item_record.simple_pack_ind = 'N' then
            L_style_item := L_item_record.item;
      end if;
   elsif L_item_record.item_level < L_item_record.tran_level then
         L_style_item := L_item_record.item;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_BRCD_DAILY_PURGE;',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   open C_CHECK_BRCD_DAILY_PURGE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_BRCD_DAILY_PURGE',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   fetch C_CHECK_BRCD_DAILY_PURGE into L_item;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_BRCD_DAILY_PURGE;',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   close C_CHECK_BRCD_DAILY_PURGE;

   if L_item is null then
      O_family_deleted := 'Y';
      return TRUE;
   end if;

   return TRUE;

END TSL_ITEM_FAMILY_DELETED;
----------------------------------------------------------------------------------------------------
-- 23-Aug-2009 Tesco HSC/Shweta Madnawat               Def014555 End
----------------------------------------------------------------------------------------------------
-- MrgNBS015067 15-Oct-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
----------------------------------------------------------------------------------------------------
--DefNBS014851 23-Sep-2009 Chandru Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_CHECK_MAND_ITATTR
--Purpose  : This function will be used to check all required attributes entered or not
--           for the entire item structure, called from item_master.fmb
----------------------------------------------------------------------------------------------------
FUNCTION  TSL_CHECK_MAND_ITATTR (O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_item              IN      ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is
   --
   L_program                  VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CHECK_MAND_ITATTR';
   L_dept                     ITEM_MASTER.DEPT%TYPE;
   L_class                    ITEM_MASTER.CLASS%TYPE;
   L_subclass                 ITEM_MASTER.SUBCLASS%TYPE;
   L_exists                   VARCHAR2(1) := 'N';
   L_message                  VARCHAR2(100) := NULL;
   L_item_level               ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_valid                    VARCHAR2(1) := NULL;
   --
   -- DefNBS025514\PM017007 Vatan Jaiswal, vatan.jaiswal@in.tesco.com 12-Oct-2012, Begin
   L_exist_var                BOOLEAN;
   L_exist_var_pack           BOOLEAN;
   L_var_ind                  VARCHAR2(1) := 'N';
   L_var_pack_ind             VARCHAR2(1) := 'N';
   L_launch_dt                VARCHAR2(1) := 'N';
   L_launch_dt_ind            VARCHAR2(1) := 'N';
   -- DefNBS025514\PM017007 Vatan Jaiswal, vatan.jaiswal@in.tesco.com 12-Oct-2012, End

   -- Cursor to check if item exists in Item Master
   CURSOR C_ITEM_EXISTS is
   select 'Y'
     from item_master
    where item = I_item;

   -- This cursor will get the Low level code description for the attached subgroup.
   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, Begin
   -- PrfNBS016258, 15-Feb-2010, Govindarajan K, Begin
   -- Modified the existing cursor
   CURSOR C_GET_ITEM is
   select DISTINCT item,
          item_level,
          pack_ind
     from (select im.item,
                  item_level,
                  pack_ind
             from item_master im
            start with im.item in (select pi.pack_no item
                                     from packitem pi
                                    where item in (select item
                                                     from item_master im2
                                                    start with im2.item = I_item
                                                  connect by prior im2.item = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
   select item,
          item_level,
          pack_ind
     from item_master im
    start with im.item = I_item
  connect by prior im.item = im.item_parent);
   ---
   -- PrfNBS016258, 15-Feb-2010, Govindarajan K, End
   -- 08-Mar-2010, MrgNBS016573, Merge from 3.5bp1 to 3.5b, End

   -- DefNBS025514\PM017007 Vatan Jaiswal, vatan.jaiswal@in.tesco.com 12-Oct-2012, Begin
   --Cursor to check Launch Date for the Item
   CURSOR C_LAUNCH_DATE(c_item  ITEM_MASTER.ITEM%TYPE) is
   select 'X'
     from item_attributes
    where item = c_item
      and tsl_launch_date is NOT NULL;
   -- DefNBS025514\PM017007 Vatan Jaiswal, vatan.jaiswal@in.tesco.com 12-Oct-2012, END
BEGIN
   -- Check if any of input parameter is NULL
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_EXISTS',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   open C_ITEM_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_EXISTS',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   fetch C_ITEM_EXISTS into L_valid;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_EXISTS',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   close C_ITEM_EXISTS;

   if L_valid is NOT NULL then
     --Fetch the Dept,class,Subclass
     if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                       I_item,
                                       L_dept,
                                       L_class,
                                       L_subclass) = FALSE then
        return FALSE;
     end if;

     --Fetch the Item Structure
     SQL_LIB.SET_MARK('OPEN',
                      'C_GET_ITEM',
                      'ITEM_MASTER',
                      'Item = ' || I_item);
     FOR C_rec in C_GET_ITEM
     LOOP
        L_message := NULL;
        L_item_level := NULL;
        if C_rec.pack_ind = 'Y' then
           L_message := ' Pack ';
        end if;
        --
        L_item_level := C_rec.item_level;
        --
        if MERCH_DEFAULT_SQL.TSL_GET_REQD_ATTR(O_error_message,
                                               L_exists,
                                               C_rec.item,
                                               L_dept,
                                               L_class,
                                               L_subclass) = FALSE then
           return FALSE;
        end if;

        if L_exists = 'N' then
           -- DefNBS025514\PM017007 Vatan Jaiswal, vatan.jaiswal@in.tesco.com 12-Oct-2012, Begin
           L_exist_var      := FALSE;
           L_exist_var_pack := FALSE;
           L_var_ind        := 'N';
           L_var_pack_ind   := 'N';
           L_launch_dt      := 'N';
           L_launch_dt_ind  := 'N';

           if TSL_BASE_VARIANT_SQL.VALIDATE_VARIANT_ITEM(O_error_message,
                                                         L_exist_var,
                                                         C_rec.item)= FALSE then
              return FALSE;
           end if;

           if L_exist_var = TRUE then
              L_var_ind := 'Y';
           end if;
           --
           if C_rec.pack_ind = 'Y' then
              if TSL_BASE_VARIANT_SQL.TSL_VALIDATE_VARIANT_PACK(O_error_message,
                                                                L_exist_var_pack,
                                                                C_rec.item)= FALSE then
                 return FALSE;
              end if;

              if L_exist_var_pack = TRUE then
                 L_var_pack_ind := 'Y';
              end if;
           end if;
           --
           SQL_LIB.SET_MARK('OPEN',
                            'C_LAUNCH_DATE',
                            'ITEM_ATTRIBUTES',
                            'Item = ' || C_rec.item);
           open C_LAUNCH_DATE(C_rec.item);

           SQL_LIB.SET_MARK('FETCH',
                            'C_LAUNCH_DATE',
                            'ITEM_ATTRIBUTES',
                            'Item = ' || C_rec.item);
           fetch C_LAUNCH_DATE into L_launch_dt;

           if C_LAUNCH_DATE%NOTFOUND then
              L_launch_dt_ind := 'Y';
           end if;

           SQL_LIB.SET_MARK('CLOSE',
                            'C_LAUNCH_DATE',
                            'ITEM_ATTRIBUTES',
                            'Item = ' || C_rec.item);
           close C_LAUNCH_DATE;
           --
           if NOT ((L_var_ind = 'Y' or L_var_pack_ind = 'Y') and L_launch_dt_ind = 'Y') then
           -- DefNBS025514\PM017007 Vatan Jaiswal, vatan.jaiswal@in.tesco.com 12-Oct-2012, End
              O_error_message :=SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_ATTR_MISSING',
                                                      L_item_level || L_message,
                                                      C_rec.item,
                                                      NULL);
              return FALSE;
           -- DefNBS025514\PM017007 Vatan Jaiswal, vatan.jaiswal@in.tesco.com 12-Oct-2012, Begin
           end if;
           -- DefNBS025514\PM017007 Vatan Jaiswal, vatan.jaiswal@in.tesco.com 12-Oct-2012, End
        end if;
     END LOOP;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_GET_ITEM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM',
                          'ITEM_MASTER',
                          'Item = ' || I_item);
         close C_GET_ITEM;
      end if;
      --
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_MAND_ITATTR;
---------------------------------------------------------------------------------------------
--DefNBS014851 23-Sep-2009 Chandru End
---------------------------------------------------------------------------------------------
-- MrgNBS015067 15-Oct-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
---------------------------------------------------------------------------------------------
-- MrgNBS015080 21-Oct-2009 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
---------------------------------------------------------------------------------------------
-- 08-Oct-2009 Tesco HSC/Satish B.N                   Defect Id: NBS00013960 Begin
---------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_SAME_ITEMTYPE_ITEM(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                            O_exist  IN OUT  VARCHAR2,
                                            I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program       VARCHAR2(50)    := 'ITEM_ATTRIB_SQL.TSL_CHECK_SAME_ITEMTYPE_ITEM_EXIST';

   cursor C_CHECK_ITEM_EXIST is
      select 1
        from item_master iem,
             system_options sop
       where iem.item_parent      = I_item
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
                    'C_CHECK_ITEM_EXIST',
                    'ITEM_MASTER, SYSTEM_OPTIONS',
                    'Item: '|| I_item);
   open C_CHECK_ITEM_EXIST ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_ITEM_EXIST',
                    'ITEM_MASTER, SYSTEM_OPTIONS',
                    'Item: '|| I_item);
   fetch C_CHECK_ITEM_EXIST into O_exist;
   if C_CHECK_ITEM_EXIST%FOUND then
     O_exist := 'Y';
   else
     O_exist := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_ITEM_EXIST',
                    'ITEM_MASTER, SYSTEM_OPTIONS',
                    'Item: '|| I_item);
   close C_CHECK_ITEM_EXIST ;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_CHECK_ITEM_EXIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHECK_ITEM_EXIST',
                          'ITEM_MASTER, SYSTEM_OPTIONS',
                          'item:'|| TO_CHAR(I_item));
         close C_CHECK_ITEM_EXIST;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_CHK_SAME_ITEMTYPE_ITEM;
--------------------------------------------------------------------------------------------
FUNCTION TSL_GET_CHILDREN_COUNT(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_count         IN OUT NUMBER,
                                I_parent_item   IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

L_program VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_CHILDREN_COUNT';


CURSOR C_GET_CHILD is
  select COUNT(*)
     from item_master iem
    where iem.item_parent = I_parent_item
      and tsl_deactivate_date is NULL
      and iem.status = 'A';

BEGIN
   O_count  := 0;
   if I_parent_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'NULL',
                                            'NULL',
                                            'NULL');
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CHILD',
                    'ITEM_MASTER',
                    'Item: '|| I_parent_item);
   open C_GET_CHILD ;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_ITEM_EXIST',
                    'ITEM_MASTER',
                    'Item: '|| I_parent_item);
   fetch C_GET_CHILD into O_count;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CHILD',
                    'ITEM_MASTER',
                    'Item: '|| I_parent_item);
   close C_GET_CHILD ;

   return TRUE;
EXCEPTION
   when OTHERS then
      if C_GET_CHILD%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CHILD',
                          'ITEM_MASTER',
                          'item:'|| TO_CHAR(I_parent_item));
         close C_GET_CHILD;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_GET_CHILDREN_COUNT;
----------------------------------------------------------------------------------------------------
-- 08-Oct-2009 Tesco HSC/Satish B.N                   Defect Id: NBS00013960 End
----------------------------------------------------------------------------------------------------
-- MrgNBS015130  Wipro/JK   23-Oct-09  End
----------------------------------------------------------------------------------------------------
-- CR236, 09-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
----------------------------------------------------------------------------------------------------
-- Function Name : TSL_GET_EPW_COUNTRY
-- Purpose       : This is a new function which will return the county in which epw indicator is set
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EPW_COUNTRY (O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_epw_country       IN OUT VARCHAR2,
                              I_item              IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_EPW_COUNTRY';
   L_exist     VARCHAR2(1);

   CURSOR C_GET_EPW (I_country VARCHAR2) is
      select ia.tsl_epw_ind
        from item_attributes ia
       where ia.item           = I_item
         and ia.tsl_epw_ind    = 'Y'
         and ia.tsl_country_id = I_country;


BEGIN
   -- Check if any of input parameter is NULL
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;
   ---
   -- checking for UK country
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_EPW',
                    'item_attributes',
                    'I_item: '||I_item);
   open C_GET_EPW('U');
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_EPW',
                    'item_attributes',
                    'I_item: '||I_item);
   fetch C_GET_EPW into L_exist;
   ---
   if C_GET_EPW%FOUND then
      O_epw_country := 'UK';
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_EPW',
                    'item_attributes',
                    'I_item: '||I_item);
   close C_GET_EPW;
   ---
   -- checking for ROI country
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_EPW',
                    'item_attributes',
                    'I_item: '||I_item);
   open C_GET_EPW('R');
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_EPW',
                    'item_attributes',
                    'I_item: '||I_item);
   fetch C_GET_EPW into L_exist;
   ---
   if C_GET_EPW%FOUND then
      if O_epw_country = 'UK' then
         O_epw_country := 'BOTH';
      else
         O_epw_country := 'ROI';
      end if;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_EPW',
                    'item_attributes',
                    'I_item: '||I_item);
   close C_GET_EPW;

   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_GET_EPW_COUNTRY;
----------------------------------------------------------------------------------------------------
-- CR236, 09-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
--26-Mar-2010  -   Manikandan V  - MrgNBS016802   -  Begin
-- CR261, 17-Mar-2010, Shireen, shireen.sheosunker@uk.tesco.com, Begin
----------------------------------------------------------------------------------------------------
-- Function Name : TSL_GET_EPW_END_DATE
-- Purpose       : This is a new function which will return the epw end date
----------------------------------------------------------------------------------------------------
-- Defect 17565a, Shireen Sheosunker
-- The package was not returning end dates, changed the package.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EPW_END_DATE (O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_epw_end_date       OUT ITEM_ATTRIBUTES.TSL_END_DATE%TYPE,
                              O_epw_end_date_uk    OUT ITEM_ATTRIBUTES.TSL_END_DATE%TYPE,
                              I_item               IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_EPW_END_DATE';
   L_exist     VARCHAR2(1);
   L_country   ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE;


   CURSOR C_GET_EPW is
      select tsl_end_date,
             tsl_country_id
        from item_attributes
       where item           = I_item
         and tsl_epw_ind    = 'Y';
--         and tsl_country_id = I_country;


BEGIN
   -- Check if any of input parameter is NULL
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_EPW',
                    'item_attributes',
                    'I_item: '||I_item);
   FOR C_rec in C_GET_EPW
   LOOP
       if c_rec.tsl_country_id = 'U' then
           O_epw_end_date_uk := c_rec.tsl_end_date;
       elsif c_rec.tsl_country_id = 'R' then
             O_epw_end_date := c_rec.tsl_end_date;
       end if;
   END LOOP;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_GET_EPW_END_DATE;
-- CR261, 17-Mar-2010, Shireen, shireen.sheosunker@uk.tesco.com, End
--26-Mar-2010  -   Manikandan V  - MrgNBS016802   -  End
----------------------------------------------------------------------------------------------------
-- DefNBS015164, 29-Oct-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
----------------------------------------------------------------------------------------------------
-- Function Name : TSL_CASCADE_BRAND_IND
-- Purpose       : This is a new function which will cascade brand ind at the country level
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CASCADE_BRAND_IND (O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_item              IN     ITEM_MASTER.ITEM%TYPE,
                                I_brand_ind         IN     ITEM_ATTRIBUTES.TSL_BRAND_IND%TYPE,
                                I_country           IN     ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE,
                                --NBS00015370, Nitin Kumar, nitin.kumar@in.tesco.com, 19-nov-2009, Begin
                                I_brand_name        IN     ITEM_ATTRIBUTES.TSL_BRAND%TYPE := NULL)
                                --NBS00015370, Nitin Kumar, nitin.kumar@in.tesco.com, 19-nov-2009, End
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CASCADE_BRAND_IND';
   L_country   ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE;

BEGIN
   ---
   if I_country = 'U' then
      L_country := 'R';
   elsif I_country = 'R' then
      L_country := 'U';
   end if;
   ---
   merge into item_attributes ia
      using (select 1 from dual) i
      on (ia.item = I_item and ia.tsl_country_id = L_country)
      when matched then
         update set ia.tsl_brand_ind = I_brand_ind,
         --NBS00015370, Nitin Kumar, nitin.kumar@in.tesco.com, 19-nov-2009, Begin
                    ia.tsl_brand     = I_brand_name
         --NBS00015370, Nitin Kumar, nitin.kumar@in.tesco.com, 19-nov-2009, End
          where ia.tsl_country_id    = L_country
      when not matched then
         insert (ia.item,
                 ia.tsl_brand_ind,
                 ia.tsl_country_id,
                 --NBS00015370, Nitin Kumar, nitin.kumar@in.tesco.com, 19-nov-2009, Begin
                 ia.tsl_brand)
                 --NBS00015370, Nitin Kumar, nitin.kumar@in.tesco.com, 19-nov-2009, End
         values (I_item,
                 I_brand_ind,
                 L_country,
                 --NBS00015370, Nitin Kumar, nitin.kumar@in.tesco.com, 19-nov-2009, Begin
                 I_brand_name);
                 --NBS00015370, Nitin Kumar, nitin.kumar@in.tesco.com, 19-nov-2009, End
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_CASCADE_BRAND_IND;
----------------------------------------------------------------------------------------------------
-- DefNBS015164, 29-Oct-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
----------------------------------------------------------------------------------------------------
-- Defect NBS00015164, 29-Oct-2009,Raghuveer P R - Begin
----------------------------------------------------------------------------------------------------
-- Function Name : TSL_ITEMDIFF_CHECK_EAN
-- Purpose       : Function will compare the code type 'EANT' with 'TSBC' and 'NTBC', for population
--                 of 'EAN TYPE' field in itemchildrendiff screen.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_ITEMDIFF_CHECK_EAN (O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_ean               IN OUT TSL_EAN_CODE,
                                 I_code_type         IN     CODE_DETAIL.CODE_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_ITEMDIFF_CHECK_EAN';
   L_ean_code  TSL_EAN_CODE;

   CURSOR C_GET_EANT_TSBC is
      select cd.code
        from code_detail cd
       where cd.code_type = 'TSBC'
   INTERSECT
      select cd.code
        from code_detail cd
       where cd.code_type = 'EANT';

   CURSOR C_GET_EANT_NTBC is
      select cd.code
        from code_detail cd
       where cd.code_type = 'NTBC'
   INTERSECT
      select cd.code
        from code_detail cd
       where cd.code_type = 'EANT';

BEGIN
   -- Check if any of input parameter is NULL
   if I_code_type is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_code_type',
                                                  L_program,
                                                  NULL);
   end if;
   --
   if I_code_type = 'TSBC' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_EANT_TSBC',
                       'code_detail',
                       'I_code_type: '||I_code_type);
      open C_GET_EANT_TSBC;
      --
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_EANT_TSBC',
                       'code_detail',
                       'I_code_type: '||I_code_type);
      fetch C_GET_EANT_TSBC bulk collect into O_ean;
      --
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_EANT_TSBC',
                       'code_detail',
                       'I_code_type: '||I_code_type);
      close C_GET_EANT_TSBC;
      --
   elsif I_code_type = 'NTBC' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_EANT_NTBC',
                       'code_detail',
                       'I_code_type: '||I_code_type);
      open C_GET_EANT_NTBC;
      --
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_EANT_NTBC',
                       'code_detail',
                       'I_code_type: '||I_code_type);
      fetch C_GET_EANT_NTBC bulk collect into O_ean;
      --
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_EANT_NTBC',
                       'code_detail',
                       'I_code_type: '||I_code_type);
      close C_GET_EANT_NTBC;
      --
   end if;
   --
   return TRUE;

EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_ITEMDIFF_CHECK_EAN;
-------------------------------------------------------------------------------------------
-- Defect NBS00015164, 29-Oct-2009,Raghuveer P R - End
-------------------------------------------------------------------------------------------
-- 13-Nov-2009 Nitin Kumar, nitin.kumar@in.tesco.com NBS00014668 Begin
----------------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_WORDCOUNT
-- Purpose      : Added one new function TSL_GET_WORDCOUNT to fetch the number of words in a
--                sentence.This will be used on Item Children Form.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_WORDCOUNT(I_input_string     IN       ITEM_MASTER.ITEM%TYPE)
RETURN PLS_INTEGER is
   --
   L_program      VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_WORDCOUNT';
   Words          PLS_INTEGER := 0;
   Len            PLS_INTEGER := NVL(LENGTH(I_input_string),0);
   Inside_a_word  BOOLEAN;
   --

BEGIN
   --
   FOR i IN 1..Len + 1
   LOOP
      if ASCII(SUBSTR(I_input_string, i, 1)) < 33 OR i > Len then
         if Inside_a_word then
            Words := Words + 1;
            Inside_a_word := FALSE;
         end if;
      else
         Inside_a_word := TRUE;
      end if;
   END LOOP;
   --
   return Words;

EXCEPTION
   when OTHERS then
      NULL;
END TSL_GET_WORDCOUNT;
----------------------------------------------------------------------------------------------------
-- 13-Nov-2009 Nitin Kumar, nitin.kumar@in.tesco.com NBS00014668 End
----------------------------------------------------------------------------------------------------
-- 03-Dec-2009 Nitin Kumar, nitin.kumar@in.tesco.com, NBS00015526, Begin
----------------------------------------------------------------------------------------------------
-- Function Name: TSL_CHECK_VARIANT_QTY_UOM
-- Purpose      : This function will be used to compare the UOM values with the Base item for variant
--                item whose variant reason code is 'Y'/'C'.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_VARIANT_QTY_UOM(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_status            OUT      VARCHAR2,
                                   I_item              IN       ITEM_MASTER.ITEM%TYPE,
                                   I_content_qty_uom  IN       TSL_ITEMDESC_SEL.CONTENTS_QTY_UOM%TYPE)
   return BOOLEAN is

   L_program               VARCHAR(64) := 'ITEM_ATTRIB_SQL.TSL_CHECK_VARIANT_QTY_UOM';
   L_contents_qty_uom      TSL_ITEMDESC_SEL.CONTENTS_QTY_UOM%TYPE       := NULL;
   L_variant_reason_code   ITEM_MASTER.TSL_VARIANT_REASON_CODE%TYPE := NULL;

   -- cursor declarations
   CURSOR C_GET_CONTENTS_QTY_UOM is
   select distinct t.contents_qty_uom
     from tsl_itemdesc_sel t
    where t.item in (select item from item_master i
                      where i.tsl_base_item in (select tsl_base_item
                                                  from item_master im
                                                 where im.item = I_item)
                        and i.item <> i.tsl_base_item
                        and i.tsl_variant_reason_code in ('Y','C'));

   CURSOR C_GET_VARIANT_REASON_CODE is
   select tsl_variant_reason_code
     from item_master im
    where im.item = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_content_qty_uom is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_content_qty_uom',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_VARIANT_REASON_CODE',
                    'item_master',
                    NULL);
   open C_GET_VARIANT_REASON_CODE;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_VARIANT_REASON_CODE',
                    'item_master',
                    NULL);
   fetch C_GET_VARIANT_REASON_CODE into L_variant_reason_code;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_VARIANT_REASON_CODE',
                    'item_master',
                    NULL);
   close C_GET_VARIANT_REASON_CODE;
   ---
   if L_variant_reason_code = 'Y' or L_variant_reason_code = 'C' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_CONTENTS_QTY_UOM',
                       'tsl_itemdesc_sel',
                       'item= ' || (I_item));
      open C_GET_CONTENTS_QTY_UOM;
      ---
      if C_GET_CONTENTS_QTY_UOM%ROWCOUNT>1 then
         O_status := 'N';
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_CONTENTS_QTY_UOM',
                       'tsl_itemdesc_sel',
                       'item= ' || (I_item));
      FETCH C_GET_CONTENTS_QTY_UOM into L_contents_qty_uom;
      ---
      if C_GET_CONTENTS_QTY_UOM%NOTFOUND then
         O_status := 'Y';
         ---
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CONTENTS_QTY_UOM',
                          'tsl_itemdesc_sel',
                          'item= ' || (I_item));
         close C_GET_CONTENTS_QTY_UOM;
         ---
         return TRUE;
      end if;
      ---
      if L_contents_qty_uom = I_content_qty_uom then
         O_status := 'Y';
      elsif L_contents_qty_uom <> I_content_qty_uom then
         O_status := 'N';
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_CONTENTS_QTY_UOM',
                       'tsl_itemdesc_sel',
                       'item= ' || (I_item));
      close C_GET_CONTENTS_QTY_UOM;
      ---
   else
      O_status := 'Y';
   end if;
   ---
   return TRUE;

EXCEPTION
   when others then
      if C_GET_CONTENTS_QTY_UOM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CONTENTS_QTY_UOM',
                          'tsl_itemdesc_sel',
                          'item= ' || (I_item));
         close C_GET_CONTENTS_QTY_UOM;
      end if;
      ---
      if C_GET_VARIANT_REASON_CODE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_VARIANT_REASON_CODE',
                          'item_master',
                          NULL);
         close C_GET_VARIANT_REASON_CODE;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_VARIANT_QTY_UOM;
----------------------------------------------------------------------------------------------------
-- 03-Dec-2009 Nitin Kumar, nitin.kumar@in.tesco.com, NBS00015526, End
-------------------------------------------------------------------------------------------------------
-- MrgNBS017125 19-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
-------------------------------------------------------------------------------------------------------
-- Prod Fix Def NBS00016163, 02-Feb-2010, Naveen Babu.A, naveen.babu@in.tesco.com (BEGIN)
-------------------------------------------------------------------------------------------------------
-- Mod By     : Naveen Babu.A, naveen.babu@in.tesco.com
-- Mod Date   : 02-Jan-2010
-- Mod Ref    : NBS00016163
-- Mod Details: Added a new function TSL_ITEM_DESC_CHECK for checking Effective-Date in the Description
--              tables of all Item and its children's when approving the item.
-------------------------------------------------------------------------------------------------------
FUNCTION TSL_ITEM_DESC_CHECK (O_error_message IN OUT VARCHAR2,
                              I_item          IN ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   L_pack_no            PACKITEM.PACK_NO%TYPE;
   L_pack_occ           ITEM_MASTER.ITEM%TYPE;
   L_item               ITEM_MASTER.ITEM%TYPE;
   L_effv_date_base     DATE;
   L_effv_date_pack     DATE;
   L_effv_date_occ      DATE;
   L_effv_date_sel      DATE;
   L_effv_date_episel   DATE;
   L_effv_date_iss      DATE;
   L_effv_date_till     DATE;
   L_vdate              DATE;
   L_program            VARCHAR2(64) := 'TSL_ITEM_DESC_CHECK';
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011, Begin
   L_table                       VARCHAR2(30)   := 'TSL_ITEM_DESC_*';
   RECORD_LOCKED                 EXCEPTION;
   PRAGMA                        EXCEPTION_INIT(RECORD_LOCKED, -54);
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End

   cursor C_GET_ALL_ITEMS is
      select item, item_number_type, item_level, tran_level
        from item_master
       where item              = I_ITEM
          or item_parent       = I_ITEM
          or item_grandparent  = I_ITEM;

   cursor C_GET_DESC_BASE is
      select effective_date
         from tsl_itemdesc_base
        where item = L_item
          and effective_date = (select max(effective_date)
                                  from tsl_itemdesc_base
                                 where item = L_item)
                                   for update nowait;

   cursor C_GET_DESC_TILL is
      select effective_date
         from tsl_itemdesc_till
        where item = L_item
          and effective_date = (select max(effective_date)
                                  from tsl_itemdesc_till
                                 where item = L_item)
                                   for update nowait;

   cursor C_GET_DESC_EPISEL is
      select  effective_date
         from tsl_itemdesc_episel
        where item = L_item
          and effective_date = (select max(effective_date)
                                  from tsl_itemdesc_episel
                                 where item = L_item)
                                   for update nowait;

   cursor C_GET_DESC_SEL is
      select  effective_date
         from tsl_itemdesc_sel
        where item = L_item
          and effective_date = (select max(effective_date)
                                  from tsl_itemdesc_sel
                                 where item = L_item)
                                    for update nowait;

   cursor C_GET_DESC_ISS is
      select  effective_date
         from tsl_itemdesc_iss
        where item = L_item
          and effective_date = (select max(effective_date)
                                  from tsl_itemdesc_iss
                                 where item = L_item)
                                   for update nowait;

   cursor C_GET_DESC_PACK is
      select effective_date
         from tsl_itemdesc_pack
        where pack_no = L_pack_no
          and effective_date = (select max(effective_date)
                                  from tsl_itemdesc_pack
                                 where pack_no = L_pack_no)
                                   for update nowait;

   cursor C_GET_DESC_OCC is
      select effective_date
         from tsl_itemdesc_pack
        where pack_no = L_pack_occ
          and effective_date = (select max(effective_date)
                                  from tsl_itemdesc_pack
                                 where pack_no = L_pack_occ)
                                   for update nowait;

   cursor C_GET_PACK_DETAILS is
      select pack_no
        from packitem
       where item = L_Item;

   cursor C_GET_OCC is
     select item
       from item_master
      where item_parent = L_pack_no;

BEGIN
   -- Get the VDATE from the system
   L_vdate := GET_VDATE();
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ALL_ITEMS',
                    'ITEM_MASTER',
                    'Item = ' || L_item);
   -- Process the Item and all its Children Items
   FOR recs in C_GET_ALL_ITEMS LOOP
       L_effv_date_base   := NULL;
       L_effv_date_pack   := NULL;
       L_effv_date_sel    := NULL;
       L_effv_date_episel := NULL;
       L_effv_date_iss    := NULL;
       L_effv_date_till   := NULL;
       L_item := recs.item;
       -- Check each Item Description table for the Effective-Date value.
       -- Update Effectiv-Date as VDATE+1 if Effv-Date is <= VDATE.

       -- Checking TSL_ITEMDESC_BASE table
       SQL_LIB.SET_MARK('OPEN',
                        'C_GET_DESC_BASE',
                        'TSL_ITEMDESC_BASE',
                        'Item = ' || L_item);
       open C_GET_DESC_BASE;

       SQL_LIB.SET_MARK('FETCH',
                        'C_GET_DESC_BASE',
                        'TSL_ITEMDESC_BASE',
                        'Item = ' || L_item);
       fetch C_GET_DESC_BASE into L_effv_date_base;

       if (C_GET_DESC_BASE%FOUND) and (L_effv_date_base <= L_vdate) then
          update tsl_itemdesc_base
             set effective_date = L_vdate + 1
           where item           = L_item
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  Begin
             and effective_date = L_effv_date_base;
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  End
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
       end if;

       SQL_LIB.SET_MARK('CLOSE',
                        'C_GET_DESC_BASE',
                        'TSL_ITEMDESC_BASE',
                        'Item = ' || L_item);
       close C_GET_DESC_BASE;

       -- Checking TSL_ITEMDESC_TILL table
       SQL_LIB.SET_MARK('OPEN',
                        'C_GET_DESC_TILL',
                        'TSL_ITEMDESC_TILL',
                        'Item = ' || L_item);
       open C_GET_DESC_TILL;

       SQL_LIB.SET_MARK('FETCH',
                        'C_GET_DESC_TILL',
                        'TSL_ITEMDESC_TILL',
                        'Item = ' || L_item);
       fetch C_GET_DESC_TILL into L_effv_date_till;

       if (C_GET_DESC_TILL%FOUND) and (L_effv_date_till <= L_vdate) then
          update tsl_itemdesc_till
             set effective_date = L_vdate + 1
           where item           = L_item
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  Begin
             and effective_date = L_effv_date_till;
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  End
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
       end if;

       SQL_LIB.SET_MARK('CLOSE',
                        'C_GET_DESC_TILL',
                        'TSL_ITEMDESC_TILL',
                        'Item = ' || L_item);
       close C_GET_DESC_TILL;

       -- Checking TSL_ITEMDESC_EPISEL table
       SQL_LIB.SET_MARK('OPEN',
                        'C_GET_DESC_EPISEL',
                        'TSL_ITEMDESC_EPISEL',
                        'Item = ' || L_item);
       open C_GET_DESC_EPISEL;

       SQL_LIB.SET_MARK('FETCH',
                        'C_GET_DESC_EPISEL',
                        'TSL_ITEMDESC_EPISEL',
                        'Item = ' || L_item);
       fetch C_GET_DESC_EPISEL into L_effv_date_episel;

       if (C_GET_DESC_EPISEL%FOUND) and (L_effv_date_episel <= L_vdate) then
          update tsl_itemdesc_episel
             set effective_date = L_vdate + 1
           where item           = L_item
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  Begin
             and effective_date = L_effv_date_episel;
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  End
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
       end if;

       SQL_LIB.SET_MARK('CLOSE',
                        'C_GET_DESC_EPISEL',
                        'TSL_ITEMDESC_EPISEL',
                        'Item = ' || L_item);
       close C_GET_DESC_EPISEL;

       -- Checking TSL_ITEMDESC_SEL table
       SQL_LIB.SET_MARK('OPEN',
                        'C_GET_DESC_SEL',
                        'TSL_ITEMDESC_SEL',
                        'Item = ' || L_item);
       open C_GET_DESC_SEL;

       SQL_LIB.SET_MARK('FETCH',
                        'C_GET_DESC_SEL',
                        'TSL_ITEMDESC_SEL',
                        'Item = ' || L_item);
       fetch C_GET_DESC_SEL into L_effv_date_sel;

       if (C_GET_DESC_SEL%FOUND) and (L_effv_date_sel <= L_vdate) then
          update tsl_itemdesc_sel
             set effective_date = L_vdate + 1
           where item           = L_item
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  Begin
             and effective_date = L_effv_date_sel;
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  End
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
       end if;

       SQL_LIB.SET_MARK('CLOSE',
                        'C_GET_DESC_SEL',
                        'TSL_ITEMDESC_SEL',
                        'Item = ' || L_item);
       close C_GET_DESC_SEL;

       -- Checking TSL_ITEMDESC_ISS table
       SQL_LIB.SET_MARK('OPEN',
                        'C_GET_DESC_ISS',
                        'TSL_ITEMDESC_ISS',
                        'Item = ' || L_item);
       open C_GET_DESC_ISS;

       SQL_LIB.SET_MARK('FETCH',
                        'C_GET_DESC_ISS',
                        'TSL_ITEMDESC_ISS',
                        'Item = ' || L_item);
       fetch C_GET_DESC_ISS into L_effv_date_iss;

       if (C_GET_DESC_ISS%FOUND) and (L_effv_date_iss <= L_vdate) then
          update tsl_itemdesc_iss
             set effective_date = L_vdate + 1
           where item           = L_item
           -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
           -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  Begin
           and effective_date   = L_effv_date_iss;
           -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  End
           -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
       end if;

       SQL_LIB.SET_MARK('CLOSE',
                        'C_GET_DESC_ISS',
                        'TSL_ITEMDESC_ISS',
                        'Item = ' || L_item);
       close C_GET_DESC_ISS;

       -- Checking TSL_ITEMDESC_PACK table
       L_pack_no := recs.item;
       SQL_LIB.SET_MARK('OPEN',
                        'C_GET_DESC_PACK',
                        'TSL_ITEMDESC_PACK',
                        'Item = ' || L_pack_no);
       open C_GET_DESC_PACK;

       SQL_LIB.SET_MARK('FETCH',
                        'C_GET_DESC_PACK',
                        'TSL_ITEMDESC_PACK',
                        'Item = ' || L_pack_no);
       fetch C_GET_DESC_PACK into L_effv_date_pack;

       if (C_GET_DESC_PACK%FOUND) and (L_effv_date_pack <= L_vdate) then
          update tsl_itemdesc_pack
             set effective_date = L_vdate + 1
           where pack_no        = L_pack_no
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  Begin
             and effective_date = L_effv_date_pack;
             -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  End
             -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
       end if;

       SQL_LIB.SET_MARK('CLOSE',
                        'C_GET_DESC_PACK',
                        'TSL_ITEMDESC_PACK',
                        'Item = ' || L_pack_no);
       close C_GET_DESC_PACK;

       -- Check whether the item is TPNB or VAR, if yes then check description
       -- for the corresponding PACK and its child items.
       if (recs.item_number_type = 'TPNB' or recs.item_number_type = 'VAR')
         and (recs.item_level = 2)
         and (recs.tran_level = 2) then

          SQL_LIB.SET_MARK('OPEN',
                           'C_GET_PACK_DETAILS',
                           'PACKITEM',
                           'Pack_no = ' || L_item);
          -- Processing all PACK items for a TPNB/VAR item.
          FOR recs_pack in C_GET_PACK_DETAILS LOOP
             L_effv_date_pack := NULL;
             L_pack_no := recs_pack.pack_no;

             -- Checking TSL_ITEMDESC_PACK for PACK Items
             SQL_LIB.SET_MARK('OPEN',
                              'C_GET_DESC_PACK',
                              'TSL_ITEMDESC_PACK',
                              'Pack_no = ' || L_pack_no);
             open C_GET_DESC_PACK;

             SQL_LIB.SET_MARK('FETCH',
                              'C_GET_DESC_PACK',
                              'TSL_ITEMDESC_PACK',
                              'Pack_no = ' || L_pack_no);
             fetch C_GET_DESC_PACK into L_effv_date_pack;

             if (C_GET_DESC_PACK%FOUND) and (L_effv_date_pack <= L_vdate) then
                update tsl_itemdesc_pack
                   set effective_date = L_vdate + 1
                 where pack_no        = L_pack_no
                   -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                   -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  Begin
                   and effective_date = L_effv_date_pack;
                   -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  End
                   -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
             end if;

             SQL_LIB.SET_MARK('CLOSE',
                              'C_GET_DESC_PACK',
                              'TSL_ITEMDESC_PACK',
                              'Pack_no = ' || L_pack_no);
             close C_GET_DESC_PACK;

             SQL_LIB.SET_MARK('OPEN',
                              'C_GET_OCC',
                              'ITEM_MASTER',
                              'Item = ' || L_item);
             -- Processing child Items of the PACK item
             FOR recs_occ in C_GET_OCC LOOP
                L_effv_date_occ := NULL;
                L_pack_occ := recs_occ.item;

                SQL_LIB.SET_MARK('OPEN',
                                 'C_GET_DESC_OCC',
                                 'TSL_ITEMDESC_PACK',
                                 'Pack_no = ' || L_pack_occ);
                open C_GET_DESC_OCC;

                SQL_LIB.SET_MARK('FETCH',
                                 'C_GET_DESC_OCC',
                                 'TSL_ITEMDESC_PACK',
                                 'Pack_no = ' || L_pack_occ);
                fetch C_GET_DESC_OCC into L_effv_date_occ;
                -- Checking TSL_ITEMDESC_PACK table for the OCC item
                if (C_GET_DESC_OCC%FOUND) and (L_effv_date_occ <= L_vdate) then
                   update tsl_itemdesc_pack
                      set effective_date = L_vdate + 1
                    where pack_no        = L_pack_occ
                      -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                      -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  Begin
                      and effective_date = L_effv_date_occ;
                      -- 20-Apr-2010   TESCO HSC/Naveen Babu.A   Def-NBS00017157  End
                      -- MrgNBS017125 21-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                end if;

                SQL_LIB.SET_MARK('CLOSE',
                                 'C_GET_DESC_OCC',
                                 'TSL_ITEMDESC_PACK',
                                 'Pack_no = ' || L_pack_occ);
                close C_GET_DESC_OCC;

             END LOOP;  -- end of C_GET_OCC loop
          END LOOP; --end of C_GET_PACK_DETAILS loop
       end if;
   END LOOP; -- end of C_GET_ALL_ITEMS loop
   return TRUE;

EXCEPTION
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011, Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            NULL,
                                            NULL);
      return FALSE;
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_ITEM_DESC_CHECK;
-----------------------------------------------------------------------------------------------------
-- Prod Fix Def NBS00016163, 02-Feb-2010, Naveen Babu.A, naveen.babu@in.tesco.com (END)
-----------------------------------------------------------------------------------------------------
-- MrgNBS017125 19-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
----------------------------------------------------------------------------------------------------
--CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_GET_LUNCH_DATE
--Purpose  : the function gets the lunch date from item_attributes table.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_LUNCH_DATE(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_item               IN     ITEM_MASTER.ITEM%TYPE,
                            I_lunch_date         IN OUT ITEM_ATTRIBUTES.TSL_LAUNCH_DATE%TYPE,
                            I_country_id         IN     VARCHAR2)
RETURN BOOLEAN IS
   L_program      VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE';
   L_exist        VARCHAR2(1);
   L_lunch_date   DATE;

   CURSOR C_GET_LUNCH_DATE is
      select ia.tsl_launch_date
        from item_attributes ia
       where ia.item           = I_item
         and ia.tsl_country_id = I_country_id;


BEGIN
   -- Check if any of input parameter is NULL
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_LUNCH_DATE',
                    'item_attributes',
                    'I_item: '||I_item);
   open C_GET_LUNCH_DATE;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_LUNCH_DATE',
                    'item_attributes',
                    'I_item: '||I_item);
   fetch C_GET_LUNCH_DATE into I_lunch_date;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_LUNCH_DATE',
                    'item_attributes',
                    'I_item: '||I_item);
   close C_GET_LUNCH_DATE;
   ---
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_GET_LUNCH_DATE;
----------------------------------------------------------------------------------------------------
--Function : TSL_DEL_ITEM_ATTRIBUTES
--Purpose  : the function will delete the records from item_attributes table.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_TESCO_BRAND_EAN(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     O_exist                 OUT VARCHAR2,
                                     I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CHK_TESCO_BRAND_EAN';
   L_exist     VARCHAR2(1) := 'N';
   CURSOR C_CHK_TESCO_BRAND_EAN is
      select im.item
        from item_master im,
             code_detail cd
       where im.item_grandparent= I_item
         and im.item_number_type = cd.code
         and cd.code_type = 'TSBC';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;

   FOR rec IN C_CHK_TESCO_BRAND_EAN
   LOOP
      L_exist := 'Y';
   END LOOP;
   ---
   O_exist := L_exist;
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_CHK_TESCO_BRAND_EAN;
----------------
FUNCTION TSL_GET_STYLE_ITEM(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_style_item            OUT ITEM_MASTER.ITEM%TYPE,
                            I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_program         VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_STYLE_ITEM';
   L_error_message   VARCHAR2(255);
   L_style_item      ITEM_MASTER.ITEM%TYPE;
   L_item_record     ITEM_MASTER%ROWTYPE;

   CURSOR C_GET_STYLE_FOR_TPND is
         -- 20-May-10 Murali N , NBS00017540  Begin
      select im1.item_parent
       from item_master im1,
            packitem p
      where p.pack_no = I_item
        and p.item = im1.item;
      -- 20-May-10 Murali N , NBS00017540  End

   CURSOR C_GET_STYLE_FOR_OCC is
      select iem1.item
        from item_master iem1,
             packitem pai,
             item_master iem2
       where iem1.item   = pai.item_parent
         and pai.pack_no = iem2.item_parent
         and iem2.item   = I_item;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(L_error_message,
                                      L_item_record,
                                      I_item) = FALSE then
      return FALSE;
   end if;

   if (L_item_record.pack_ind = 'N' and L_item_record.item_level > L_item_record.tran_level) then
      L_style_item := L_item_record.item_grandparent;
   elsif (L_item_record.pack_ind = 'N' and L_item_record.item_level = L_item_record.tran_level) then
      L_style_item := L_item_record.item_parent;
   elsif L_item_record.pack_ind = 'Y' and L_item_record.simple_pack_ind = 'Y' and
         L_item_record.item_level > L_item_record.tran_level then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_STYLE_FOR_OCC;',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      open C_GET_STYLE_FOR_OCC;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_STYLE_FOR_OCC;',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      fetch C_GET_STYLE_FOR_OCC into L_style_item;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_STYLE_FOR_OCC;',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      close C_GET_STYLE_FOR_OCC;
   elsif L_item_record.pack_ind = 'Y' and L_item_record.simple_pack_ind = 'Y' and
         L_item_record.item_level = L_item_record.tran_level then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_STYLE_FOR_TPND;',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      open C_GET_STYLE_FOR_TPND;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_STYLE_FOR_TPND;',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      fetch C_GET_STYLE_FOR_TPND into L_style_item;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_STYLE_FOR_TPND;',
                       'ITEM_MASTER',
                       'Item = ' || I_item);
      close C_GET_STYLE_FOR_TPND;
   elsif L_item_record.pack_ind = 'Y' and L_item_record.simple_pack_ind = 'N' and
         L_item_record.item_level > L_item_record.tran_level then
      L_style_item := L_item_record.item_parent;
   elsif L_item_record.pack_ind = 'Y' and L_item_record.simple_pack_ind = 'N' and
         L_item_record.item_level = L_item_record.tran_level then
      L_style_item := I_item;
   elsif L_item_record.item_level < L_item_record.tran_level then
      L_style_item := I_item;
   end if;
   O_style_item := L_style_item;
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_GET_STYLE_ITEM;
--CR288 09-Feb-2010 Sarayu Gouda sarayu.gouda@in.tesco.com End
----------------------------------------------------------------------------------------------------
-- 14-Apr-2010 Sripriya, sripriya.karanam@in.tesco.com, NBS00016994, Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_CHK_TESCO_BRAND_OCC
--Purpose  : the function checks if tesco branded OCC exist or not
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_TESCO_BRAND_OCC(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_exist                 OUT VARCHAR2,
                                 I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CHK_TESCO_BRAND_OCC';

   CURSOR C_CHK_TESCO_BRAND_OCC is
      select im.item
        from item_master im,
             code_detail cd
       where im.item_parent= I_item
         and im.item_number_type = cd.code
         and cd.code_type = 'TSBC'
         -- DefNBS017154, 23-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
         and cd.code != 'TPNB';
         -- DefNBS017154, 23-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (End)

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;
   O_exist := 'N';
   FOR rec IN C_CHK_TESCO_BRAND_OCC
   LOOP
      O_exist := 'Y';
      EXIT;
   END LOOP;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_CHK_TESCO_BRAND_OCC;
----------------------------------------------------------------------------------------------------
-- 14-Apr-2010 Sripriya, sripriya.karanam@in.tesco.com, NBS00016994, End
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- 03-May-2010 Joy Stephen, joy.johnchristopher@in.tesco.com, DefNBS016887, Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_GET_EXT_ITEM_INFO
--Purpose  : This function fetches the information of the externally loaded items from RPS.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EXT_ITEM_INFO(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_item_level         OUT    ITEM_MASTER.ITEM_LEVEL%TYPE,
                               O_tran_level         OUT    ITEM_MASTER.TRAN_LEVEL%TYPE,
                               O_pack_ind           OUT    ITEM_MASTER.PACK_IND%TYPE,
                               O_ext_item_ind       OUT    ITEM_MASTER.TSL_EXTERNAL_ITEM_IND%TYPE,
                               O_ext_upd_ind        OUT    TSL_ITEM_UPLOAD_STATUS.UPDATE_IND%TYPE,
                               I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_EXT_ITEM_INFO';
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
   --18-Jun-2010    TESCO HSC/Joy Stephen    DefNBS017896    Begin
   L_cnt_zone_price     NUMBER(4);
   L_cnt_zone_id_temp   NUMBER(4);
   --18-Jun-2010    TESCO HSC/Joy Stephen    DefNBS017896    End
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end

   CURSOR C_GET_EXT_ITEM_INFO is
   select im.item_level,
          im.tran_level,
          im.pack_ind,
          im.tsl_external_item_ind,
          tius.update_ind
     from item_master im,
          tsl_item_upload_status tius
    where im.item = I_item
      --17-Jun-2010    TESCO HSC/Joy Stephen    DefNBS017904    Begin
      and im.item_level <= im.tran_level
      --17-Jun-2010    TESCO HSC/Joy Stephen    DefNBS017904    End
      and im.pack_ind = 'N'
      and im.item = tius.item;

   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
   --18-Jun-2010    TESCO HSC/Joy Stephen    DefNBS017896    Begin
   CURSOR C_CNT_ITEM_ZONE_PRICE is
   select count(1)
     from rpm_item_zone_price
    where item = I_item;

   CURSOR C_CNT_ZONE_ID_TEMP is
   select count(distinct zone_id)
     from tsl_zone_id_temp
    where item = I_item;
   --18-Jun-2010    TESCO HSC/Joy Stephen    DefNBS017896    End
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_EXT_ITEM_INFO;',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   OPEN C_GET_EXT_ITEM_INFO;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_EXT_ITEM_INFO;',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   FETCH C_GET_EXT_ITEM_INFO into O_item_level,
                                  O_tran_level,
                                  O_pack_ind,
                                  O_ext_item_ind,
                                  O_ext_upd_ind;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_EXT_ITEM_INFO;',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   CLOSE C_GET_EXT_ITEM_INFO;
   ---
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
   --18-Jun-2010    TESCO HSC/Joy Stephen    DefNBS017896    Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_CNT_ITEM_ZONE_PRICE;',
                    'RPM_ITEM_ZONE_PRICE',
                    'Item = ' || I_item);
   OPEN C_CNT_ITEM_ZONE_PRICE;
   SQL_LIB.SET_MARK('OPEN',
                    'C_CNT_ITEM_ZONE_PRICE',
                    'RPM_ITEM_ZONE_PRICE',
                    'Item = ' || I_item);
   FETCH C_CNT_ITEM_ZONE_PRICE into L_cnt_zone_price;
   SQL_LIB.SET_MARK('OPEN',
                    'C_CNT_ITEM_ZONE_PRICE;',
                    'RPM_ITEM_ZONE_PRICE',
                    'Item = ' || I_item);
   CLOSE C_CNT_ITEM_ZONE_PRICE;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_CNT_ZONE_ID_TEMP;',
                    'TSL_ZONE_ID_TEMP',
                    'Item = ' || I_item);
   OPEN C_CNT_ZONE_ID_TEMP;
   SQL_LIB.SET_MARK('OPEN',
                    'C_CNT_ZONE_ID_TEMP;',
                    'TSL_ZONE_ID_TEMP',
                    'Item = ' || I_item);
   FETCH C_CNT_ZONE_ID_TEMP into L_cnt_zone_id_temp;
   SQL_LIB.SET_MARK('OPEN',
                    'C_CNT_ZONE_ID_TEMP;',
                    'TSL_ZONE_ID_TEMP',
                    'Item = ' || I_item);
   CLOSE C_CNT_ZONE_ID_TEMP;
   ---
   if L_cnt_zone_price = L_cnt_zone_id_temp then
      if ITEM_ATTRIB_SQL.TSL_UPD_UPLOAD_STATUS(O_error_message,
                                               I_item) = FALSE then
         return FALSE;
      end if;
      if ITEM_ATTRIB_SQL.TSL_DEL_EXT_RETAIL_INFO(O_error_message,
                                                 I_item) = FALSE then
         return FALSE;
      end if;
   end if;
   --18-Jun-2010    TESCO HSC/Joy Stephen    DefNBS017896    End
   -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_GET_EXT_ITEM_INFO;
----------------------------------------------------------------------------------------------------
--Function : TSL_GET_EXT_RETAIL_INFO
--Purpose  : This function fetches the retail information of the externally loaded items from RPS.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EXT_RETAIL_INFO(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_exists             OUT    VARCHAR2,
                                 I_item               IN     ITEM_MASTER.ITEM%TYPE,
                                 I_dept               IN     ITEM_MASTER.DEPT%TYPE,
                                 I_class              IN     ITEM_MASTER.CLASS%TYPE,
                                 I_subclass           IN     ITEM_MASTER.SUBCLASS%TYPE,
                                 I_display_id         IN     RPM_ZONE.ZONE_DISPLAY_ID%TYPE)
RETURN BOOLEAN IS
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_EXT_RETAIL_INFO';

   CURSOR C_GET_EXT_RETAIL_INFO is
   select 'X'
     from tsl_zone_id_temp tzit,
          rpm_zone rz
    where tzit.item = I_item
      and rz.zone_id = tzit.zone_id
      and rz.zone_display_id = I_display_id;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_EXT_RETAIL_INFO;',
                    'TSL_ZONE_ID_TEMP',
                    'Item = ' || I_item);
   OPEN C_GET_EXT_RETAIL_INFO;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_EXT_RETAIL_INFO;',
                    'TSL_ZONE_ID_TEMP',
                    'Item = ' || I_item);
   FETCH C_GET_EXT_RETAIL_INFO into O_exists;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_EXT_RETAIL_INFO;',
                    'TSL_ZONE_ID_TEMP',
                    'Item = ' || I_item);
   CLOSE C_GET_EXT_RETAIL_INFO;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_GET_EXT_RETAIL_INFO;
----------------------------------------------------------------------------------------------------
--Function : TSL_DEL_EXT_RETAIL_INFO
--Purpose  : This function flushes the temp table.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_DEL_EXT_RETAIL_INFO(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_DEL_EXT_RETAIL_INFO';
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011, Begin
   L_table                       VARCHAR2(30)   := 'TSL_ZONE_ID_TEMP';
   RECORD_LOCKED                 EXCEPTION;
   PRAGMA                        EXCEPTION_INIT(RECORD_LOCKED, -54);
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End

   CURSOR C_DEL_EXT_RETAIL_INFO is
   select 'X'
     from tsl_zone_id_temp
    where item = I_item
     for update nowait;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_DEL_EXT_RETAIL_INFO;',
                    'TSL_ZONE_ID_TEMP',
                    'Item = ' || I_item);
   OPEN C_DEL_EXT_RETAIL_INFO;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_DEL_EXT_RETAIL_INFO;',
                    'TSL_ZONE_ID_TEMP',
                    'Item = ' || I_item);
   CLOSE C_DEL_EXT_RETAIL_INFO;

   delete from tsl_zone_id_temp
         where item = I_item;
   ---
   return TRUE;
   ---
EXCEPTION
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011, Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End

   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_DEL_EXT_RETAIL_INFO;
----------------------------------------------------------------------------------------------------
--Function : TSL_DEL_EXT_RETAIL_INFO
--Purpose  : This function flushes the temp table.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_UPD_UPLOAD_STATUS(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_UPD_UPLOAD_STATUS';
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011, Begin
   L_table                       VARCHAR2(30)   := 'TSL_ITEM_UPLOAD_STATUS';
   RECORD_LOCKED                 EXCEPTION;
   PRAGMA                        EXCEPTION_INIT(RECORD_LOCKED, -54);
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End


   CURSOR C_UPD_UPLOAD_STATUS is
   select 'X'
     from tsl_item_upload_status
    where item = I_item
     for update nowait;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_UPD_UPLOAD_STATUS;',
                    'TSL_ITEM_UPLOAD_STATUS',
                    'Item = ' || I_item);
   OPEN C_UPD_UPLOAD_STATUS;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_UPD_UPLOAD_STATUS;',
                    'TSL_ITEM_UPLOAD_STATUS',
                    'Item = ' || I_item);
   CLOSE C_UPD_UPLOAD_STATUS;

   update tsl_item_upload_status
      set update_ind = 'Y'
    where item = I_item;
   ---
   return TRUE;
   ---
EXCEPTION
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011, Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End

   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_UPD_UPLOAD_STATUS;
----------------------------------------------------------------------------------------------------
-- 03-May-2010 Joy Stephen, joy.johnchristopher@in.tesco.com, DefNBS016887, End
----------------------------------------------------------------------------------------------------
--12-May-2010 Murali  Cr288b Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_GET_ITEM_CTRY_IND
--Purpose  : This function derives tsl_country_auth_ind for the item .
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_ITEM_CTRY_IND (O_error_message    IN OUT      RTK_ERRORS.RTK_TEXT%TYPE,
                                I_item             IN          ITEM_MASTER.ITEM%TYPE,
                                O_authind          IN OUT      ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE)
RETURN BOOLEAN is

   L_program                       VARCHAR2(60) := 'ITEM_ATTRIB_SQL.TSL_GET_ITEM_CTRY_IND';
   L_country_ind_uk                VARCHAR2(1) := NULL;
   L_country_ind_roi               VARCHAR2(1) := NULL;
   L_country_auth_ind              ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE := NULL;
   L_base_country_auth_ind         ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE := 'N';
   --19-May-2010 Murali  Cr288b Begin
   L_item_master_row               ITEM_MASTER%ROWTYPE;
   --19-May-2010 Murali  Cr288b End

   CURSOR C_GET_ITEM_ATTR is
   select item,
          tsl_country_id
     from item_attributes
    where item = I_item
      and tsl_launch_date is NOT NULL;

BEGIN

   --19-May-2010 Murali  Cr288b Begin
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                       L_item_master_row,
                                       I_item) = FALSE then
      return FALSE;
   end if;
   if L_item_master_row.Status = 'A' then
      O_authind := L_item_master_row.tsl_country_auth_Ind;
      return TRUE;
   end if;
   --19-May-2010 Murali  Cr288b End

   FOR C_rec in C_GET_ITEM_ATTR LOOP
      if C_rec.tsl_country_id = 'U' then
         L_country_ind_uk := 'U';
      elsif C_rec.tsl_country_id = 'R' then
         L_country_ind_roi := 'R';
      end if;
   END LOOP;

   if L_country_ind_uk = 'U' and L_country_ind_roi ='R' then
      L_country_auth_ind := 'B';
   elsif L_country_ind_uk = 'U' and L_country_ind_roi is NULL then
      L_country_auth_ind := 'U';
   elsif L_country_ind_uk is NULL and L_country_ind_roi = 'R' then
      L_country_auth_ind := 'R';
   elsif L_country_ind_uk is NULL and L_country_ind_roi is NULL then
      L_country_auth_ind := NULL;
   end if;

   O_authind := L_country_auth_ind;

   return TRUE;
EXCEPTION
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
  return FALSE;
END TSL_GET_ITEM_CTRY_IND;
----------------------------------------------------------------------------------------------------
--12-May-2010 Murali  Cr288b End
-- Function : TSL_EPW_EXISTS_CHILD
-- Mod      : Defect
-- Purpose  : This fuction is used to set the EPW link on the form to green/tick if an epw
--            exists in the item structure.
---------------------------------------------------------------------------------------------
-- Created By : Shireen Sheosunker, shireen.sheosunker@uk.tesco.com
-- Date       : 28-MAY-2010
----------------------------------------------------------------------------------------------
FUNCTION TSL_EPW_EXISTS_CHILD(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        O_exists             IN OUT   BOOLEAN,
                        I_item               IN       ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN IS
    L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_EPW_EXISTS_CHILD';
    L_epw  VARCHAR2(1);

    cursor C_EPW_EXISTS is
      select ia.tsl_epw_ind
        from item_master im,
             item_attributes ia
       where im.item_parent = I_item
         and im.item = ia.item
         and ia.tsl_epw_ind = 'Y';
BEGIN
   O_exists := FALSE;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_EPW_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   open C_EPW_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EPW_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   fetch C_EPW_EXISTS into L_epw;
   if C_EPW_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EPW_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   close C_EPW_EXISTS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
  return FALSE;
END TSL_EPW_EXISTS_CHILD;
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Mod By     : Sriranjitha Bhagi, Sriranjitha.Bhagi@in.tesco.com (BEGIN)
-- Mod Date   : 04-June-2010
-- Mod Ref    : NBS00017622
-- Mod Details: Added a new function CHECK_SPLCHR because RMS Online allowing special characters [] and
--              is causing downstream failures
-------------------------------------------------------------------------------------------------------
FUNCTION CHECK_SPLCHR(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      I_desc            IN       ITEM_MASTER.ITEM_DESC%TYPE,
                      O_exists             OUT   BOOLEAN)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50)  := 'ITEM_ATTRIB_SQL.CHECK_SPLCHR';

BEGIN

   if I_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_desc',
                                            L_program,
                                            NULL);

      return FALSE;
   end if;
   ---
   if INSTR(I_desc,CHR(91))>0 or
      INSTR(I_desc,CHR(93))>0 or
      -- 08-June-2010 Sriranjitha Bhagi, Sriranjitha.Bhagi@in.tesco.com ,Def-NBS00017837  Begin
      INSTR(I_desc,CHR(59))>0 or
      INSTR(I_desc,CHR(124))>0 or
      INSTR(I_desc,CHR(10))> 0 or
      INSTR(I_desc,CHR(13))> 0 then
      -- 08-June-2010 Sriranjitha Bhagi, Sriranjitha.Bhagi@in.tesco.com ,Def-NBS00017837  End
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_SPLCHR;
-----------------------------------------------------------------------------------------------------
-- Prod Fix Def NBS00017622, 04-June-2010, Sriranjitha Bhagi, Sriranjitha.Bhagi@in.tesco.com (END)
-----------------------------------------------------------------------------------------------------
-- 17-Jun-2010, Joy Stephen, joy.johnchristopher@in.tesco.com, DefNBS017904, Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_PARENT_UPD_INFO
--Purpose  : This function fetches the information of the externally loaded items parent from RPS.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_PARENT_UPD_INFO(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_parent_upd_ind     OUT    TSL_ITEM_UPLOAD_STATUS.UPDATE_IND%TYPE,
                             I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_PARENT_UPD_INFO';

   CURSOR C_GET_PARENT_INFO is
   select t.update_ind
     from tsl_item_upload_status t
    where item in (select i.item_parent
                     from item_master i
                    where i.item = I_item
                      and i.tsl_external_item_ind = 'Y'
                      and i.item_level = i.tran_level
                      and i.pack_ind = 'N');

BEGIN

   ---C_GET_PARENT_INFO
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_PARENT_INFO;',
                    'TSL_ITEM_UPLOAD_STATUS',
                    'Item = ' || I_item);
   OPEN C_GET_PARENT_INFO;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_PARENT_INFO;',
                    'TSL_ITEM_UPLOAD_STATUS',
                    'Item = ' || I_item);
   FETCH C_GET_PARENT_INFO into O_parent_upd_ind;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_PARENT_INFO;',
                    'TSL_ITEM_UPLOAD_STATUS',
                    'Item = ' || I_item);
   CLOSE C_GET_PARENT_INFO;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_PARENT_UPD_INFO;
----------------------------------------------------------------------------------------------------
-- 17-Jun-2010, Joy Stephen, joy.johnchristopher@in.tesco.com, DefNBS017904, End
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
----------------------------------------------------------------------------------------------------
--Function : TSL_GET_ZERO_PLUS_L3
--Author   : Raghuveer P R
--Mod Ref  : CR347
--Date     : 22-July-2010
--Purpose  : This function checks whether the L3 item's parent has a pack size 1 and whether it has
--           an OCC with 0+L3 item. Also checks whether an OCC has a corresponding 0-OCC as the L3
--           item.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_ZERO_PLUS_EAN(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_exists             IN OUT BOOLEAN,
                               O_item_pack          IN OUT ITEM_MASTER.ITEM%TYPE,
                               O_item_pack_parent   IN OUT ITEM_MASTER.ITEM%TYPE,
                               I_item_pack          IN     ITEM_MASTER.ITEM%TYPE,
                               I_item_type          IN     VARCHAR2)
RETURN BOOLEAN IS
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CHK_ZERO_PLUS_EAN';
   --
   CURSOR C_GET_ZERO_PLUS_EAN IS
   select im.item,
          im.item_parent
     from item_master im,
          (select pack_no
             from packitem pi
            where pack_qty  = 1
              and item      = (select item_parent
                                 from item_master
                                where item = I_item_pack)) t
    where t.pack_no = im.item_parent
      and substr(item,2) = I_item_pack;
   --
   CURSOR C_GET_OCC_MINUS_ZERO IS
   select im.item,
          im.item_parent
     from item_master im,
          (select item
             from packitem
            where pack_qty = 1
              and pack_no  = (select item_parent
                                 from item_master
                                where item = I_item_pack)) t
    where t.item = im.item_parent
      and substr(I_item_pack,2) = im.item;

BEGIN

   if I_item_type = 'I' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ZERO_PLUS_EAN;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      OPEN C_GET_ZERO_PLUS_EAN;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ZERO_PLUS_EAN;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      FETCH C_GET_ZERO_PLUS_EAN into O_item_pack, O_item_pack_parent;
      if C_GET_ZERO_PLUS_EAN%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ZERO_PLUS_EAN;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      CLOSE C_GET_ZERO_PLUS_EAN;
   elsif I_item_type = 'P' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_OCC_MINUS_ZERO;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      OPEN C_GET_OCC_MINUS_ZERO;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_OCC_MINUS_ZERO;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      FETCH C_GET_OCC_MINUS_ZERO into O_item_pack, O_item_pack_parent;
      if C_GET_OCC_MINUS_ZERO%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_OCC_MINUS_ZERO;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      CLOSE C_GET_OCC_MINUS_ZERO;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_CHK_ZERO_PLUS_EAN;
-----------------------------------------------------------------------------------------------------
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
-- CR288d, 19-Jul-2010, Nishant Gupta, nishant.gupta@in.tesco.com, Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_CASCADE_EPW
--Purpose  : This function inherites the EPW ind fromone country to another.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_CASCADE_EPW(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         I_item               IN     ITEM_MASTER.ITEM%TYPE,
                         I_ctry_auth_old      IN     ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CASCADE_EPW';

   L_tsl_epw_ind_u           varchar2(1);
   L_tsl_country_id_u        varchar2(1);
   L_tsl_end_date_u          DATE;
   ---
   L_item                    ITEM_MASTER.ITEM%TYPE;
   L_epw_uk_set              varchar2(1);
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   -- To fetch authorized country indicator for passed item.
   L_country_auth            ITEM_MASTER.Tsl_Country_Auth_Ind%TYPE;
   -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end

   CURSOR C_GET_ITEM is
         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
      -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
      -- Modified cursor to fetch authorized country indicator also.
   select DISTINCT item,
                   tsl_country_auth_ind
      -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
     from (select im.item,
                  item_level,
                  pack_ind,
                  -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
                  -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
                  tsl_country_auth_ind
                  -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
                  -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
             from item_master im
             start with im.item in (select pi.pack_no item
                                      from packitem pi
                                     where item in (select item
                                                      from item_master im2
                                                     start with im2.item = I_item
                                                   connect by prior im2.item = im2.item_parent))
  connect by prior im.item = im.item_parent
    union all
   select item,
          item_level,
          pack_ind,
          -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
          -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
          tsl_country_auth_ind
          -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
          -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
     from item_master im
    start with im.item = I_item
  connect by prior im.item = im.item_parent);

   CURSOR C_GET_EPW_CTRY is
   select NVL(tsl_epw_ind,'N'),
          tsl_country_id,
          tsl_end_date
     from item_attributes
    where item        = I_item
      and tsl_country_id = I_ctry_auth_old;

   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   -- New cursor to fetch country auth indicator.
   CURSOR C_GET_AUTH_CTRY is
   select im.tsl_country_auth_ind
     from item_master im
    where item        = I_item;
   -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end


BEGIN

   SQL_LIB.SET_MARK('OPEN' , 'C_GET_EPW_CTRY', 'item_attributes',I_item);
   open C_GET_EPW_CTRY;
   SQL_LIB.SET_MARK('FETCH' , 'C_GET_EPW_CTRY', 'item_attributes', I_item);
   fetch C_GET_EPW_CTRY into L_tsl_epw_ind_u,L_tsl_country_id_u,L_tsl_end_date_u;
   SQL_LIB.SET_MARK('CLOSE' , 'C_GET_EPW_CTRY', 'item_attributes',I_item);
   close C_GET_EPW_CTRY;

   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   -- New cursor to fetch country auth indicator.
   SQL_LIB.SET_MARK('OPEN' , 'C_GET_AUTH_CTRY', 'item_master',I_item);
   open C_GET_AUTH_CTRY;
   SQL_LIB.SET_MARK('FETCH' , 'C_GET_AUTH_CTRY', 'item_master', I_item);
   fetch C_GET_AUTH_CTRY into L_country_auth;
   SQL_LIB.SET_MARK('CLOSE' , 'C_GET_AUTH_CTRY', 'item_master',I_item);
   close C_GET_AUTH_CTRY;
   -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
   -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end

  if L_tsl_country_id_u = 'U' then
    FOR rec IN C_GET_ITEM LOOP
      SQL_LIB.SET_MARK('UPDATE', 'ITEM_ATTRIBUTES','Item: ',I_item);
      update item_attributes
        set tsl_epw_ind = L_tsl_epw_ind_u,
            tsl_end_date = L_tsl_end_date_u
       where item = rec.item
         and tsl_country_id = 'R'
         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
         -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
         -- Allowing cascade of EPW only when items country authization indicator is
         -- same as passed item(When items become dual)
         and rec.tsl_country_auth_ind = L_country_auth;
         -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
   END LOOP;
  end if;

  if L_tsl_country_id_u = 'R' then
    FOR rec IN C_GET_ITEM LOOP
      SQL_LIB.SET_MARK('UPDATE', 'ITEM_ATTRIBUTES','Item: ',I_item);
      update item_attributes
        set tsl_epw_ind = L_tsl_epw_ind_u,
            tsl_end_date = L_tsl_end_date_u
       where item = rec.item
         and tsl_country_id = 'U'
         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
         -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
         -- Allowing cascade of EPW only when items country authization indicator is
         -- same as passed item(When items become dual)
         and rec.tsl_country_auth_ind = L_country_auth;
         -- NBS00019082 09-Sep-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
         -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
   END LOOP;
  end if;

RETURN TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_CASCADE_EPW;

-----------------------------------------------------------------------------------------------------
-- CR288d, 19-Jul-2010, Nishant Gupta, nishant.gupta@in.tesco.com, End
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- 17-Jun-2010, Joy Stephen, joy.johnchristopher@in.tesco.com, DefNBS017904, End
----------------------------------------------------------------------------------------------------
-- CR354, 18-Aug-2010, Maheshwari Appuswamy, Maheshwari.Appuswamy@in.tesco.com, Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_VAL_ITEMLIST_SEC
--Purpose  : This function validates the user security to access all the items in the item list.
---------------------------------------------------------------------------------------------
FUNCTION TSL_VAL_ITEMLIST_SEC (O_error_message    IN OUT VARCHAR2,
                               O_valid            IN OUT BOOLEAN,
                               I_skulist          IN     SKULIST_DETAIL.SKULIST%TYPE,
                               I_user_loc         IN     VARCHAR2,
                               I_mode_access      IN     VARCHAR2)
RETURN BOOLEAN is

   L_program         VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_VAL_ITEMLIST_SEC';
   L_item_own_ctry   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;

   CURSOR C_SKULIST is
     select item
       from skulist_detail
      where skulist = I_skulist;

BEGIN
   O_valid := TRUE;
   FOR C_item_rec in C_SKULIST
   LOOP
      if ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY(O_error_message,
                                               L_item_own_ctry,
                                               C_item_rec.item) = FALSE then
         return FALSE;
      end if;

      if I_user_loc = 'B' and I_mode_access ='Y' then
         O_valid := TRUE;
      elsif I_user_loc = L_item_own_ctry and I_mode_access ='Y' then
         O_valid := TRUE;
      else
         O_valid := FALSE;
         return TRUE;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
 END TSL_VAL_ITEMLIST_SEC;
-- CR354, 18-Aug-2010, Maheshwari Appuswamy, Maheshwari.Appuswamy@in.tesco.com, End
---------------------------------------------------------------------------------------------------
-- CR296, 09-Nov-2010, Sreenath Madhavan, Sreenath sreenath.madavan@in.tesco.com, Begin
---------------------------------------------------------------------------------------------------
--Function : FUNCTION TSL_GET_FIRST_L2
--Purpose  : This function will get the first Level 2 item for TPNA level item.
---------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_FIRST_L2(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          O_exits         IN OUT BOOLEAN,
                          O_l2_item       IN OUT ITEM_MASTER.ITEM%TYPE,
                          I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_FIRST_L2';
   cursor C_GET_TPNB is
      select item
        from item_master
       where item_parent = I_ITEM
         and rownum = 1
       order by create_datetime;
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TPNB',
                    'item_master',
                    'item ='||I_ITEM);
   open C_GET_TPNB;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TPNB',
                    'item_master',
                    'item ='||I_ITEM);
   fetch C_GET_TPNB into O_l2_item;
   if C_GET_TPNB%FOUND then
      O_exits := TRUE;
   else
      O_exits := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TPNB',
                    'item_master',
                    'item ='||I_ITEM);
   close C_GET_TPNB;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   if C_GET_TPNB% isopen THEN
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_TPNB',
                       'item_master',
                       'item ='||I_ITEM);
      close C_GET_TPNB;
   end if;
   return FALSE;
END TSL_GET_FIRST_L2;
---------------------------------------------------------------------------------------------------
-- CR296, 09-Nov-2010, Sreenath Madhavan, Sreenath.Madavan@in.tesco.com, End
---------------------------------------------------------------------------------------------------
-- Created By : Shireen Sheosunker, shireen.sheosunker@uk.tesco.com
-- Date       : 24-NOV-2010
----------------------------------------------------------------------------------------------
FUNCTION TSL_ITEMATTR_EXISTS_ROI(O_error_message  IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_exists         IN OUT   VARCHAR2,
                                 O_item_rec       IN OUT   ITEM_ATTRIBUTES%ROWTYPE,
                                 I_item           IN       ITEM_ATTRIBUTES.ITEM%TYPE)
   return BOOLEAN IS
    L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_ITEMATTR_EXISTS_ROI';
    L_item_rec  ITEM_ATTRIBUTES%ROWTYPE;

    CURSOR C_EXISTS is
      select *
        from item_attributes
       where item = I_item
         and tsl_country_id = 'R';

BEGIN
   O_exists := 'N';
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   fetch C_EXISTS into L_item_rec;
   if C_EXISTS%FOUND then
      O_exists := 'Y';
      O_item_rec := L_item_rec;
   else
      O_exists := 'N';
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   close C_EXISTS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
  return FALSE;
END TSL_ITEMATTR_EXISTS_ROI;
----------------------------------------------------------------------------------------------------
-- CR335, 24-Nov-2010, Shireen Sheosunker, shireen.sheosunker@uk.tesco.com, End
-- MrgNBS020155 25-Dec-2010 Ankush/ankush.khanna@in.tesco.com End
---------------------------------------------------------------------------------------------------
-- CR259, 25-Nov-2010, Merlyn Mathew, merlyn.mathew@in.tesco.com, Begin
---------------------------------------------------------------------------------------------------
--Function : FUNCTION TSL_GET_UOMS_CATCHWEIGHT
--Purpose  : This function will get UOMSs for catchweight items.
---------------------------------------------------------------------------------------------------

FUNCTION TSL_GET_UOMS_CATCHWEIGHT(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_item_std_uom  OUT ITEM_MASTER.STANDARD_UOM%TYPE,
                                 O_item_sell_uom OUT ITEM_MASTER.STANDARD_UOM%TYPE,
                                 O_item_cost_uom OUT ITEM_MASTER.STANDARD_UOM%TYPE,
                                 O_pack_std_uom  OUT ITEM_MASTER.STANDARD_UOM%TYPE,
                                 O_pack_sell_uom OUT ITEM_MASTER.STANDARD_UOM%TYPE,
                                 O_pack_cost_uom OUT ITEM_MASTER.STANDARD_UOM%TYPE,
                                 --DefNBS021869 14-Mar-2011 Parvesh parveshkumar.rulhan@in.tesco.com Begin
                                 --I_order_type    IN OUT ITEM_MASTER.ORDER_TYPE%TYPE,
                                 --I_sale_type     IN OUT ITEM_MASTER.SALE_TYPE%TYPE)
                                 I_order_type    IN ITEM_MASTER.ORDER_TYPE%TYPE,
                                 I_sale_type     IN ITEM_MASTER.SALE_TYPE%TYPE)
                                 --DefNBS021869 14-Mar-2011 Parvesh parveshkumar.rulhan@in.tesco.com End
  RETURN BOOLEAN IS
  L_program VARCHAR2(70) := 'ITEM_ATTRIB_SQL.TSL_GET_UOMS_CATCHWEIGHT';
  CURSOR C_GET_UOMS_CATCHWEIGHT_ITEM(I_order_type IN VARCHAR2,
                                     I_sale_type  IN VARCHAR2) IS
     select item_std_uom,
            item_sell_uom,
            item_cost_uom,
            pack_std_uom,
            pack_sell_uom,
            pack_cost_uom
       from tsl_catchweight_type_uom
      where sale_type = I_sale_type
        and order_type = I_order_type;
BEGIN
  if I_sale_type IS NULL then
     O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_sale_type',
                                           L_program,
                                           NULL);
     RETURN FALSE;
  end if;
  if I_order_type IS NULL THEN
     O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_order_type',
                                           L_program,
                                           NULL);
     RETURN FALSE;
  end if;
  SQL_LIB.SET_MARK('OPEN',
                   'C_GET_UOMS_CATCHWEIGHT_ITEM',
                   'TSL_CATCHWEIGHT_TYPE_UOM',
                   'Order Type: ' || I_order_type ||
                   ', Sale Type: ' || I_sale_type);
  open C_GET_UOMS_CATCHWEIGHT_ITEM(I_order_type, I_sale_type);
  SQL_LIB.SET_MARK('FETCH',
                   'C_GET_UOMS_CATCHWEIGHT_ITEM',
                   'TSL_CATCHWEIGHT_TYPE_UOM',
                   'Order Type: ' || I_order_type ||
                   ', Sale Type: ' || I_sale_type);
  fetch C_GET_UOMS_CATCHWEIGHT_ITEM
     into O_item_std_uom,
          O_item_sell_uom,
          O_item_cost_uom,
          O_pack_std_uom,
          O_pack_sell_uom,
          O_pack_cost_uom;
  SQL_LIB.SET_MARK('CLOSE',
                   'C_GET_UOMS_CATCHWEIGHT_ITEM',
                   'TSL_CATCHWEIGHT_TYPE_UOM',
                   'Order Type: ' || I_order_type ||
                   ', Sale Type: ' || I_sale_type);
  close C_GET_UOMS_CATCHWEIGHT_ITEM;
  return TRUE;
EXCEPTION
  WHEN OTHERS THEN
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
     return FALSE;
END TSL_GET_UOMS_CATCHWEIGHT;
---------------------------------------------------------------------------------------------------
-- CR259, 25-Nov-2010, Merlyn Mathew, merlyn.mathew@in.tesco.com, End
---------------------------------------------------------------------------------------------------
-- CR259, 15-Dec-2010, Sanju Natarjan, Sanju.Natarajan@in.tesco.com, Begin
-- To update the selling uom to RPM tables
---------------------------------------------------------------------------------------------------
FUNCTION TSL_SET_UOMS_CATCHWEIGHT(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_item_sell_uom IN ITEM_MASTER.STANDARD_UOM%TYPE,
                                 I_item          IN ITEM_MASTER.ITEM%TYPE)
  RETURN BOOLEAN IS
  L_program       VARCHAR2(70) := 'ITEM_ATTRIB_SQL.TSL_SET_UOMS_CATCHWEIGHT';
  L_error_message RTK_ERRORS.RTK_TEXT%TYPE := NULL;
  L_exists        NUMBER;

  CURSOR C_ITEM_EXISTS IS
     select 1 from item_master where item = I_item;

  CURSOR C_CHILDREN IS
     select item
       from item_master
      where item_parent = I_item
         or item_grandparent = I_item;
  --DefNBS023213, Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com, 11-Jul-2011, Begin
  cursor C_LOCK_ZONE_PRICE(L_item ITEM_MASTER.ITEM%TYPE) is
     select 'x'
       from rpm_item_zone_price
      where item = L_item
        for update nowait;
  cursor C_LOCK_FUTURE_RETAIL(L_item ITEM_MASTER.ITEM%TYPE) is
     select 'x'
       from rpm_zone_future_retail
      where item = L_item
        for update nowait;
  cursor C_LOCK_SUPP_COUNTRY(L_item ITEM_MASTER.ITEM%TYPE) is
     select 'x'
       from item_supp_country
      where item = L_item
        for update nowait;
  --DefNBS023213, Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com, 11-Jul-2011, End
BEGIN
  if I_item IS NULL then
     O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                           'I_ITEM',
                                           'NULL',
                                           'NOT NULL');
     return FALSE;
  end if;

   if I_item_sell_uom IS NULL then
     O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                           'I_item_sell_uom',
                                           'NULL',
                                           'NOT NULL');
     return FALSE;
  end if;

  SQL_LIB.SET_MARK('OPEN',
                   'C_ITEM_EXISTS',
                   'ITEM_MASTER',
                   'ITEM_NO: ' || I_item);
  open C_ITEM_EXISTS;
  ---
  SQL_LIB.SET_MARK('FETCH',
                   'C_ITEM_EXISTS',
                   'ITEM_MASTER',
                   'ITEM_NO: ' || I_item);

  fetch C_ITEM_EXISTS
     into L_exists;

  if C_ITEM_EXISTS%FOUND then
     --DefNBS023213, Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com, 11-Jul-2011, Begin
     SQL_LIB.SET_MARK('OPEN',
                      'C_LOCK_ZONE_PRICE',
                      'RPM_ITEM_ZONE_PRICE',
                      'ITEM_NO: '||I_item);
     open C_LOCK_ZONE_PRICE(I_item);
     SQL_LIB.SET_MARK('CLOSE',
                      'C_LOCK_ZONE_PRICE',
                      'RPM_ITEM_ZONE_PRICE',
                      'ITEM_NO: '||I_item);
     close C_LOCK_ZONE_PRICE;
     ---
     SQL_LIB.SET_MARK('OPEN',
                      'C_LOCK_FUTURE_RETAIL',
                      'RPM_ZONE_FUTURE_RETAIL',
                      'ITEM_NO: '||I_item);
     open C_LOCK_FUTURE_RETAIL(I_item);
     SQL_LIB.SET_MARK('CLOSE',
                      'C_LOCK_FUTURE_RETAIL',
                      'RPM_ZONE_FUTURE_RETAIL',
                      'ITEM_NO: '||I_item);
     close C_LOCK_FUTURE_RETAIL;
     ---
     SQL_LIB.SET_MARK('OPEN',
                      'C_LOCK_SUPP_COUNTRY',
                      'ITEM_SUPP_COUNTRY',
                      'ITEM_NO: '||I_item);
     open C_LOCK_SUPP_COUNTRY(I_item);
     SQL_LIB.SET_MARK('CLOSE',
                      'C_LOCK_SUPP_COUNTRY',
                      'ITEM_SUPP_COUNTRY',
                      'ITEM_NO: '||I_item);
     close C_LOCK_SUPP_COUNTRY;
     --DefNBS023213, Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com, 11-Jul-2011, End
     update rpm_item_zone_price rizp
        set selling_uom = I_item_sell_uom
      where (rizp.item = I_item);

     update rpm_zone_future_retail rzft
        set selling_uom = I_item_sell_uom
      where rzft.item = I_item;

     update item_supp_country isc
        set cost_uom = I_item_sell_uom
      where isc.item = I_item;

  end if;
  SQL_LIB.SET_MARK('CLOSE',
                   'C_ITEM_EXISTS',
                   'ITEM_MASTER',
                   'ITEM_NO: ' || I_item);
  CLOSE C_ITEM_EXISTS;

  FOR i IN C_CHILDREN LOOP
     --DefNBS023213, Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com, 11-Jul-2011, Begin
     SQL_LIB.SET_MARK('OPEN',
                      'C_LOCK_ZONE_PRICE',
                      'RPM_ITEM_ZONE_PRICE',
                      'ITEM_NO: '||i.item);
     open C_LOCK_ZONE_PRICE(i.item);
     SQL_LIB.SET_MARK('CLOSE',
                      'C_LOCK_ZONE_PRICE',
                      'RPM_ITEM_ZONE_PRICE',
                      'ITEM_NO: '||i.item);
     close C_LOCK_ZONE_PRICE;
     ---
     SQL_LIB.SET_MARK('OPEN',
                      'C_LOCK_FUTURE_RETAIL',
                      'RPM_ZONE_FUTURE_RETAIL',
                      'ITEM_NO: '||i.item);
     open C_LOCK_FUTURE_RETAIL(i.item);
     SQL_LIB.SET_MARK('CLOSE',
                      'C_LOCK_FUTURE_RETAIL',
                      'RPM_ZONE_FUTURE_RETAIL',
                      'ITEM_NO: '||i.item);
     close C_LOCK_FUTURE_RETAIL;
     ---
     SQL_LIB.SET_MARK('OPEN',
                      'C_LOCK_SUPP_COUNTRY',
                      'ITEM_SUPP_COUNTRY',
                      'ITEM_NO: '||i.item);
     open C_LOCK_SUPP_COUNTRY(i.item);
     SQL_LIB.SET_MARK('CLOSE',
                      'C_LOCK_SUPP_COUNTRY',
                      'ITEM_SUPP_COUNTRY',
                      'ITEM_NO: '||i.item);
     close C_LOCK_SUPP_COUNTRY;
     --DefNBS023213, Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com, 11-Jul-2011, End
     update rpm_item_zone_price rizp
        set selling_uom = I_item_sell_uom
      where (rizp.item = i.item);

     update rpm_zone_future_retail rzft
        set selling_uom = I_item_sell_uom
      where rzft.item = i.item;

     update item_supp_country isc
        set cost_uom = I_item_sell_uom
      where isc.item = i.item;

  END LOOP;

  return TRUE;
EXCEPTION
  WHEN OTHERS THEN
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_SET_UOMS_CATCHWEIGHT;
---------------------------------------------------------------------------------------------------
-- CR259, 15-Dec-2010, Sanju Natarjan, Sanju.Natarajan@in.tesco.com, End
---------------------------------------------------------------------------------------------------
-- CR259, 15-Dec-2010, Sanju Natarjan, Sanju.Natarajan@in.tesco.com, Begin
-- To update the Cost UOM
---------------------------------------------------------------------------------------------------
FUNCTION TSL_SET_CUOMS_CATCHWEIGHT(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_cost_uom      IN ITEM_MASTER.STANDARD_UOM%TYPE,
                                  I_item          IN ITEM_MASTER.ITEM%TYPE)
  RETURN BOOLEAN IS
  L_program       VARCHAR2(70) := 'ITEM_ATTRIB_SQL.TSL_SET_CUOMS_CATCHWEIGHT';
  L_error_message RTK_ERRORS.RTK_TEXT%TYPE := NULL;
  L_exists        NUMBER;

  CURSOR C_ITEM_EXISTS IS
     select 1 from item_master where item = I_item;

  CURSOR C_PACKS IS
     select pack_no
       from packitem
      where item IN (select im.item
                       from item_master im
                      where im.item_parent = I_item);
BEGIN
  if I_item IS NULL then
     O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                           'I_ITEM',
                                           'NULL',
                                           'NOT NULL');
     return FALSE;
  end if;
  SQL_LIB.SET_MARK('OPEN',
                   'C_ITEM_EXISTS',
                   'ITEM_MASTER',
                   'ITEM_NO: ' || I_item);
  open C_ITEM_EXISTS;
  ---
  SQL_LIB.SET_MARK('FETCH',
                   'C_ITEM_EXISTS',
                   'ITEM_MASTER',
                   'ITEM_NO: ' || I_item);

  fetch C_ITEM_EXISTS
     INTO L_exists;

  if C_ITEM_EXISTS%FOUND then
     FOR i IN C_PACKS LOOP
        update item_supp_country isc
           set cost_uom = I_cost_uom
         where isc.item = i.pack_no;
     END LOOP;
  end if;
  SQL_LIB.SET_MARK('CLOSE',
                   'C_ITEM_EXISTS',
                   'ITEM_MASTER',
                   'ITEM_NO: ' || I_item);
  close C_ITEM_EXISTS;
  return TRUE;
EXCEPTION
  WHEN OTHERS THEN
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_SET_CUOMS_CATCHWEIGHT;
---------------------------------------------------------------------------------------------------
-- CR259, 15-Dec-2010, Sanju Natarajan, Sanju.Natarajan@in.tesco.com, End
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- CR254, 23-Nov-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com BEGIN
----------------------------------------------------------------------------------------------------
-- Author        : Ravi Nagaraju, ravi.nagaraju@in.tesco.com
-- Function Name : TSL_TARIFF_CODE_DESC
-- Purpose       : This function will get the Tariff code description for the code attached at
--                 subclass.
----------------------------------------------------------------------------------------------------
FUNCTION  TSL_TARIFF_CODE_DESC (O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                O_code_desc         IN OUT  TSL_TARIFF_CODE.TARIFF_CODE_DESC%TYPE,
                                O_supp_unit_ind     IN OUT  TSL_TARIFF_CODE.SUPPLEMENTARY_UNIT_IND%TYPE,
                                O_supp_unit_uom     IN OUT  TSL_TARIFF_CODE.SUPPLEMENTARY_UNIT_UOM%TYPE,
                                O_exist             IN OUT  BOOLEAN,
                                I_dept              IN      SUBCLASS.DEPT%TYPE,
                                I_grp               IN      SUBCLASS.CLASS%TYPE,
                                I_sub_grp           IN      SUBCLASS.SUBCLASS%TYPE,
                                I_tariff_code       IN      TSL_TARIFF_CODE.TARIFF_CODE%TYPE)
   return BOOLEAN is
   --
   L_program                  VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_TARIFF_CODE_DESC';
   --

   -- cursor C_CODE_DESC
   -- This cursor will get the Tariff code description for the attached subgroup.
   CURSOR C_CODE_DESC is
   select ttc.tariff_code_desc,
          ttc.supplementary_unit_ind,
          ttc.supplementary_unit_uom
     from tsl_tariff_code ttc
    where ttc.dept         = I_dept
      and ttc.class        = I_grp
      and ttc.subclass     = I_sub_grp
      and ttc.tariff_code  = I_tariff_code;

BEGIN
   -- Check if any of input parameter is NULL
   if I_dept is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                   I_dept,
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;

   if I_grp is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                   I_grp,
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;

   if I_sub_grp is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                   I_sub_grp,
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;

   if I_tariff_code is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                   I_tariff_code,
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;
   --
   --Fetch the Code Description of input code
   SQL_LIB.SET_MARK('OPEN',
                    'C_CODE_DESC',
                    'TSL_TARIFF_CODE',
                    'Code = ' || I_tariff_code);
   open C_CODE_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CODE_DESC',
                    'TSL_TARIFF_CODE',
                    'Code = ' || I_tariff_code);
   fetch C_CODE_DESC into O_code_desc,
                          O_supp_unit_ind,
                          O_supp_unit_uom;

   if C_CODE_DESC%FOUND then
      O_exist := TRUE;
   else
      O_exist         := FALSE;
      O_code_desc     := NULL;
      O_supp_unit_ind := NULL;
      O_supp_unit_uom := NULL;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CODE_DESC',
                    'TSL_TARIFF_CODE',
                    'Code = ' || I_tariff_code);
   close C_CODE_DESC;
   --
   return TRUE;

EXCEPTION
   when OTHERS then
      if C_CODE_DESC%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CODE_DESC',
                          'TSL_TARIFF_CODE',
                          'Code = ' || I_tariff_code);
         close C_CODE_DESC;
      end if;
      --
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_TARIFF_CODE_DESC;
-----------------------------------------------------------------------------------------------------
-- CR254, 23-Nov-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com END
----------------------------------------------------------------------------------------------------
-- MrgNBS021583, Ravi Nagaraju, ravi.nagaraju@in.tesco.com 16-Feb-2011 Begin
----------------------------------------------------------------------------------------------------
-- 28-Jan-2011 Sripriya, sripriya.karanam@in.tesco.com, NBS00020698, Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_GET_EXT_UPD_IND
--Purpose  : This function will fetch the value of Update_ind in tsl_item_upload_status table.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EXT_UPD_IND(O_error_message  IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_upd_ind        IN OUT   TSL_ITEM_UPLOAD_STATUS.UPDATE_IND%TYPE,
                             I_item           IN       ITEM_ATTRIBUTES.ITEM%TYPE)
   return BOOLEAN IS

 L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_EXT_UPD_IND';

   CURSOR C_UPD_UPLOAD_STATUS is
   select UPDATE_IND
     from tsl_item_upload_status
    where item = I_item;
BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_UPD_UPLOAD_STATUS;',
                    'TSL_ITEM_UPLOAD_STATUS',
                    'Item = ' || I_item);
   OPEN C_UPD_UPLOAD_STATUS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_UPD_UPLOAD_STATUS;',
                    'TSL_ITEM_UPLOAD_STATUS',
                    'Item = ' || I_item);
   FETCH C_UPD_UPLOAD_STATUS into O_upd_ind;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_UPD_UPLOAD_STATUS;',
                    'TSL_ITEM_UPLOAD_STATUS',
                    'Item = ' || I_item);
   CLOSE C_UPD_UPLOAD_STATUS;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
  return FALSE;
END TSL_GET_EXT_UPD_IND;
----------------------------------------------------------------------------------------------------
-- 28-Jan-2011 Sripriya, sripriya.karanam@in.tesco.com, NBS00020698, End
----------------------------------------------------------------------------------------------------
-- MrgNBS021583, Ravi Nagaraju, ravi.nagaraju@in.tesco.com 16-Feb-2011 End

--------------------------------------------------------------------------------------
-- DefNBS021496, 09-Feb-2011, Ravi Nagaraju, ravi.nagaraju@in.tesco.com BEGIN
--------------------------------------------------------------------------------------
FUNCTION TSL_TARIFF_CODE_EXISTS (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_exists        IN OUT BOOLEAN,
                                 O_tariff_code   IN OUT ITEM_ATTRIBUTES.TSL_TARIF_CODE%TYPE,
                                 O_supp_unit     IN OUT ITEM_ATTRIBUTES.TSL_SUPP_UNIT%TYPE,
                                 I_item          IN ITEM_MASTER.ITEM%TYPE
                                 --I_country_id    IN ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE
                                 )
RETURN BOOLEAN IS
   L_program VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_TARIFF_CODE_EXISTS';

   cursor C_ITEM_ATTR_TARIF_CODE is
      select tsl_tarif_code,
             tsl_supp_unit
        from item_attributes
       where item           = I_item
         --and tsl_country_id = I_country_id
         and ROWNUM         = 1;

BEGIN
   O_exists := FALSE;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_ATTR_TARIF_CODE',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   open C_ITEM_ATTR_TARIF_CODE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_ATTR_TARIF_CODE',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   fetch C_ITEM_ATTR_TARIF_CODE into O_tariff_code,O_supp_unit;

   if C_ITEM_ATTR_TARIF_CODE%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_ATTR_TARIF_CODE',
                    'ITEM_ATTRIBUTES',
                    'Item: '||I_item);
   close C_ITEM_ATTR_TARIF_CODE;

   return TRUE;
   --
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_TARIFF_CODE_EXISTS;
--------------------------------------------------------------------------------------
-- DefNBS021496, 09-Feb-2011, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Mod By     : Vinutha Raju, vinutha.raju@in.tesco.com
-- Mod Date   : 23-Feb-2011
-- Mod Ref    : DefNBS021403
-- Mod Desc   : Added new function TSL_GET_ACTIVE_CHILD_COUNT to get count of child items which
--              are not in daily purge
--------------------------------------------------------------------------------------
FUNCTION TSL_GET_ACTIVE_CHILD_COUNT(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    O_count         IN OUT NUMBER,
                                    I_parent_item   IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

L_program VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_CHILD_COUNT';

CURSOR C_GET_ACTIVE_CHILD is
   select count(*)
     from item_master
    where item_parent = I_parent_item
      and item not in
  (select key_value
     from daily_purge
    where key_value in
  (select item
     from item_master
    where item_parent = I_parent_item));

BEGIN
   O_count  := 0;
   if I_parent_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'NULL',
                                            'NULL',
                                            'NULL');
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ACTIVE_CHILD',
                    'ITEM_MASTER',
                    'Item: '|| I_parent_item);
   open C_GET_ACTIVE_CHILD ;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ACTIVE_CHILD',
                    'ITEM_MASTER',
                    'Item: '|| I_parent_item);
   fetch C_GET_ACTIVE_CHILD into O_count;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ACTIVE_CHILD',
                    'ITEM_MASTER',
                    'Item: '|| I_parent_item);
   close C_GET_ACTIVE_CHILD ;

   return TRUE;
EXCEPTION
   when OTHERS then
      if C_GET_ACTIVE_CHILD%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ACTIVE_CHILD',
                          'ITEM_MASTER',
                          'item:'|| TO_CHAR(I_parent_item));
         close C_GET_ACTIVE_CHILD;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_GET_ACTIVE_CHILD_COUNT;
------------------------------------------------------------------------------------------
-- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
--------------------------------------------------------------------------------------
--CR382b, Accenture/ Veena N, Veena.Nanjundaiah@in.tesco.com, 11-02-2011, Begin
--------------------------------------------------------------------------------------
-- Mod By     : Veena Nanjundaiah, veena.nanjundaiah@in.tesco.com
-- Mod Date   : 11-Feb-2011
-- Mod Ref    : CR382b
-- Mod Desc   : Modified to add new function TSL_DELETE_ISS_DESC.
--            : This new function will delete records from table tsl_itemdesc_iss
--------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_ISS_DESC(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                             I_item           IN      ITEM_MASTER.ITEM%TYPE,
                             I_delete_child   IN      VARCHAR2)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_DELETE_ISS_DESC';

BEGIN

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'TSL_DELETE_ISS_DESC',
                    'Item : ' || to_char(I_Item));

   if I_delete_child = 'Y' then
    delete from tsl_itemdesc_iss tii
     where tii.item in (select DISTINCT item
                          from (select im.item
                                  from item_master im
                                 start with im.item in (select pi.pack_no item
                                                          from packitem pi
                                                         where item in (select item
                                                                          from item_master im2
                                                                         start with im2.item = I_item
                                                                       connect by prior im2.item = im2.item_parent))
                                connect by prior im.item = im.item_parent
                                union all
                                 select item
                                   from item_master im
                                  start with im.item = I_item
                                connect by prior im.item = im.item_parent));
   else
      delete from tsl_itemdesc_iss
       where item = I_item;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END TSL_DELETE_ISS_DESC;
--------------------------------------------------------------------------------------
--CR382b, Accenture/ Veena N, Veena.Nanjundaiah@in.tesco.com, 11-02-2011, End
--------------------------------------------------------------------------------------
-- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
--------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--CR400, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 06-Jun-2011, Begin
---------------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_SELLING_PRICE
-- Purpose      : This function will be used to get the selling retail for TPNA and TPNB.
---------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_SELLING_PRICE(O_error_message IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               O_price         IN OUT  RPM_ITEM_ZONE_PRICE.SELLING_RETAIL%TYPE,
                               I_item_type     IN      VARCHAR2,
                               I_item          IN      ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is

   CURSOR C_GET_SELLING_PRICE_TPNA is
   select rizp.selling_retail
     from rpm_item_zone_price rizp
    where rizp.zone_id = 1
      and rizp.item = I_item;

   CURSOR C_GET_SELLING_PRICE_TPNB is
   select rzfr.selling_retail
     from rpm_zone_future_retail rzfr
    where rzfr.zone = 1
      and rzfr.item = I_item
      and rzfr.action_date = (select max(rzfr1.action_date)
                                from rpm_zone_future_retail rzfr1
                               where rzfr1.zone = 1
                                 and rzfr1.item = I_item
                                 and rzfr1.action_date <= get_vdate
                              );

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_SELLING_PRICE';
BEGIN

   if I_item_type = 'TPNA' then
      SQL_LIB.SET_MARK('OPEN', 'C_GET_SELLING_PRICE_TPNA','RPM_ITEM_ZONE_PRICE','ITEM: '||I_item);

      open C_GET_SELLING_PRICE_TPNA;

      SQL_LIB.SET_MARK('FETCH', 'C_GET_SELLING_PRICE_TPNA','RPM_ITEM_ZONE_PRICE','ITEM: '||I_item);

      fetch C_GET_SELLING_PRICE_TPNA into O_price;

      SQL_LIB.SET_MARK('CLOSE', 'C_GET_SELLING_PRICE_TPNA','RPM_ITEM_ZONE_PRICE','ITEM: '||I_item);

      close C_GET_SELLING_PRICE_TPNA;

   elsif I_item_type = 'TPNB' then
      SQL_LIB.SET_MARK('OPEN', 'C_GET_SELLING_PRICE_TPNB','RPM_ZONE_FUTURE_RETAIL','ITEM: '||I_item);

      open C_GET_SELLING_PRICE_TPNB;

      SQL_LIB.SET_MARK('FETCH', 'C_GET_SELLING_PRICE_TPNB','RPM_ZONE_FUTURE_RETAIL','ITEM: '||I_item);

      fetch C_GET_SELLING_PRICE_TPNB into O_price;

      SQL_LIB.SET_MARK('CLOSE', 'C_GET_SELLING_PRICE_TPNB','RPM_ZONE_FUTURE_RETAIL','ITEM: '||I_item);

      close C_GET_SELLING_PRICE_TPNB;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.TSL_GET_SELLING_PRICE',
                                            to_char(SQLCODE));
      return FALSE;
END TSL_GET_SELLING_PRICE;
---------------------------------------------------------------------------------------------------
-- Function Name: TSL_VALIDATE_CONT_QTY_UOM
-- Purpose      : This function will be used to check whether the contents_qty_uom is approved for
--              : the selected unit_qty.
---------------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_CONT_QTY_UOM(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_unit_qty       IN      TSL_ITEMDESC_SEL.UNIT_QTY%TYPE,
                                   I_cont_qty_uom   IN      TSL_ITEMDESC_SEL.CONTENTS_QTY_UOM%TYPE
                                   )
return BOOLEAN is

   CURSOR C_CHECK_VALID_CON_QTY_UOM is
   select 'Y'
     from tsl_unit_qty_map  tuqm
     --CR400/DefNBS023188, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 07-Jul-2011, Begin
    where tuqm.unitqty_code = I_UNIT_QTY
      and tuqm.conqtyuom_code = I_CONT_QTY_UOM;
      --CR400/DefNBS023188, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 07-Jul-2011, End


   I_exist     VARCHAR2(1)  := NULL;
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_VALIDATE_CONT_QTY_UOM';
BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_VALID_CON_QTY_UOM','TSL_UNIT_QTY_MAP','NULL');

   open C_CHECK_VALID_CON_QTY_UOM;

   SQL_LIB.SET_MARK('FETCH', 'C_CHECK_VALID_CON_QTY_UOM','TSL_UNIT_QTY_MAP','NULL');

   fetch C_CHECK_VALID_CON_QTY_UOM into I_exist;

   if C_CHECK_VALID_CON_QTY_UOM%FOUND then
      O_error_message := NULL;
   else
      O_error_message := 'TSL_INVALID_CON_QTY_UOM';
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_VALID_CON_QTY_UOM','TSL_UNIT_QTY_MAP','NULL');

   close C_CHECK_VALID_CON_QTY_UOM;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.TSL_VALIDATE_CONT_QTY_UOM',
                                            to_char(SQLCODE));
      return FALSE;
END TSL_VALIDATE_CONT_QTY_UOM;
---------------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_CONT_QTY_UOM
-- Purpose      : This function will be used to fetch the contents_qty_uom approved for
--              : the selected unit_qty.
---------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_CONT_QTY_UOM(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                              O_cont_qty_uom   IN OUT  TSL_ITEMDESC_SEL.CONTENTS_QTY_UOM%TYPE,
                              I_unit_qty_code  IN      TSL_ITEMDESC_SEL.UNIT_QTY%TYPE)
return BOOLEAN is

   CURSOR C_GET_CONT_QTY_UOM is
   --CR400/DefNBS023188, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 07-Jul-2011, Begin
   select tuqm.conqtyuom_code
     from tsl_unit_qty_map  tuqm
    where tuqm.unitqty_code = I_unit_qty_code;
    --CR400/DefNBS023188, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 07-Jul-2011, End

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_CONT_QTY_UOM';
BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_GET_CONT_QTY_UOM','TSL_UNIT_QTY_MAP','NULL');

   open C_GET_CONT_QTY_UOM;

   SQL_LIB.SET_MARK('FETCH', 'C_GET_CONT_QTY_UOM','TSL_UNIT_QTY_MAP','NULL');

   fetch C_GET_CONT_QTY_UOM into O_cont_qty_uom;

   if C_GET_CONT_QTY_UOM%NOTFOUND then
      O_cont_qty_uom := NULL;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_CONT_QTY_UOM','TSL_UNIT_QTY_MAP','NULL');

   close C_GET_CONT_QTY_UOM;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.TSL_GET_CONT_QTY_UOM',
                                            to_char(SQLCODE));
      return FALSE;
END TSL_GET_CONT_QTY_UOM;
---------------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_UNIT_QTY
-- Purpose      : This function will be used to fetch the unit_qty given for the selected item.
---------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_UNIT_QTY(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                          O_unit_qty_code  IN OUT  TSL_ITEMDESC_SEL.UNIT_QTY%TYPE,
                          I_item           IN      ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is

   CURSOR C_GET_UNIT_QTY is
   select unit_qty
     from tsl_itemdesc_sel
    where item = I_item;

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_UNIT_QTY';
BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_GET_UNIT_QTY','TSL_ITEMDESC_SEL','NULL');

   open C_GET_UNIT_QTY;

   SQL_LIB.SET_MARK('FETCH', 'C_GET_UNIT_QTY','TSL_ITEMDESC_SEL','NULL');

   fetch C_GET_UNIT_QTY into O_unit_qty_code;

   if C_GET_UNIT_QTY%NOTFOUND then
      O_unit_qty_code := NULL;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_UNIT_QTY','TSL_ITEMDESC_SEL','NULL');

   close C_GET_UNIT_QTY;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_ATTRIB_SQL.TSL_GET_UNIT_QTY',
                                            to_char(SQLCODE));
      return FALSE;
END TSL_GET_UNIT_QTY;
---------------------------------------------------------------------------------------------------
--CR400, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 06-Jun-2011, End
---------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- DefNBS023046, Gurutej.K, 22-Jul-2011, Begin
-----------------------------------------------------------------------------------------------
PROCEDURE ITEM_ATTRIB_SINGLE_LOCK(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     I_item          IN ITEM_MASTER.ITEM%TYPE,
                                     I_country_id    IN ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE) IS
      L_program        VARCHAR2(64) := 'ITEM_ATTRIB_SINGLE_LOCK';
      L_loc_sec_ind    SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE := 'N';
      L_loc_access_ind VARCHAR2(1);
      L_sec_uk_ind     VARCHAR2(1) := 'N';
      L_sec_roi_ind    VARCHAR2(1) := 'N';
      L_error          RTK_ERRORS.RTK_TEXT%TYPE := NULL;
      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED, -54);
      CURSOR C_ITEM_ATTRIB_LOCK(C_item ITEM_MASTER.ITEM%TYPE) IS
         SELECT item
           FROM item_attributes
          WHERE item = C_item
            --DefNBS023046i, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 30-Jun-11, Begin
            --AND tsl_country_id = I_country_id
            --DefNBS023046i, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, 30-Jun-11, End
            FOR UPDATE NOWAIT;
   BEGIN
      IF SYSTEM_OPTIONS_SQL.TSL_GET_LOC_SEC_IND(L_error, L_loc_sec_ind) =
         FALSE THEN
         O_error_message := L_error;
      END IF;
      IF L_loc_sec_ind = 'Y' THEN
         IF FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY(L_error,
                                                   L_sec_uk_ind,
                                                   L_sec_roi_ind) = FALSE THEN
            O_error_message := L_error;
         END IF;
         IF L_sec_uk_ind = 'Y' AND L_sec_roi_ind = 'N' THEN
            L_loc_access_ind := 'U';
         ELSIF L_sec_uk_ind = 'N' AND L_sec_roi_ind = 'Y' THEN
            L_loc_access_ind := 'R';
         ELSIF L_sec_uk_ind = 'Y' AND L_sec_roi_ind = 'Y' THEN
            L_loc_access_ind := 'B';
         END IF;
      ELSE
         L_loc_access_ind := 'B';
      END IF;
      IF L_loc_access_ind = I_country_id OR L_loc_access_ind = 'B' THEN
         SQL_LIB.SET_MARK('OPEN',
                          'C_ITEM_ATTRIB_LOCK',
                          'ITEM_ATTRIBUTES',
                          'Item:' || TO_CHAR(I_item));
         OPEN C_ITEM_ATTRIB_LOCK(I_item);
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_ATTRIB_LOCK',
                          'ITEM_ATTRIBUTES',
                          'Item:' || TO_CHAR(I_item));
         CLOSE C_ITEM_ATTRIB_LOCK;
      END IF;
   EXCEPTION
      WHEN RECORD_LOCKED THEN
         O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED_VIEW',
                                               NULL,
                                               NULL,
                                               NULL);
      WHEN OTHERS THEN
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
   END ITEM_ATTRIB_SINGLE_LOCK;
----------------------------------------------------------------------------------------------
-- DefNBS023046, Gurutej.K, 22-Jul-2011, End
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
--NBS00023042 CR416, Accenture/ Veena N, Veena.Nanjundaiah@in.tesco.com, 23-Jun-2011, Begin
----------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_CW_ZERO_PLUS_EAN(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_exists             IN OUT BOOLEAN,
                                  O_item_pack          IN OUT ITEM_MASTER.ITEM%TYPE,
                                  O_item_pack_parent   IN OUT ITEM_MASTER.ITEM%TYPE,
                                  I_item_pack          IN     ITEM_MASTER.ITEM%TYPE,
                                  I_item_type          IN     VARCHAR2)
RETURN BOOLEAN IS
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CHK_CW_ZERO_PLUS_EAN';
   --
   CURSOR C_GET_ZERO_PLUS_EAN IS
   select im.item,
          im.item_parent
     from item_master im,
          (select pack_no
             from packitem pi
            where item      = (select item_parent
                                 from item_master
                                where item = I_item_pack)) t
    where t.pack_no = im.item_parent
      and substr(item,2) = I_item_pack;
   --
   CURSOR C_GET_OCC_MINUS_ZERO IS
   select im.item,
          im.item_parent
     from item_master im,
          (select item
             from packitem
            where pack_no  = (select item_parent
                                 from item_master
                                where item = I_item_pack)) t
    where t.item = im.item_parent
      and substr(I_item_pack,2) = im.item;

BEGIN

   if I_item_type = 'I' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ZERO_PLUS_EAN;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      OPEN C_GET_ZERO_PLUS_EAN;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ZERO_PLUS_EAN;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      FETCH C_GET_ZERO_PLUS_EAN into O_item_pack, O_item_pack_parent;
      if C_GET_ZERO_PLUS_EAN%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ZERO_PLUS_EAN;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      CLOSE C_GET_ZERO_PLUS_EAN;
   elsif I_item_type = 'P' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_OCC_MINUS_ZERO;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      OPEN C_GET_OCC_MINUS_ZERO;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_OCC_MINUS_ZERO;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      FETCH C_GET_OCC_MINUS_ZERO into O_item_pack, O_item_pack_parent;
      if C_GET_OCC_MINUS_ZERO%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_OCC_MINUS_ZERO;',
                       'PACKITEM, ITEM_MASTER',
                       'Item = ' || I_item_pack);
      CLOSE C_GET_OCC_MINUS_ZERO;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_CHK_CW_ZERO_PLUS_EAN;
----------------------------------------------------------------------------------------------
--NBS00023042 CR416, Accenture/ Veena N, Veena.Nanjundaiah@in.tesco.com, 23-Jun-2011, End
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
--NBS00023464 PM009266, Accenture/ Veena N, Veena.Nanjundaiah@in.tesco.com, 19-Aug-2011, Begin
----------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_ITEM_SELLABLE(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_item_sell          IN OUT VARCHAR2,
                               I_item_pack          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_program            VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_CHK_ITEM_SELLABLE';
   L_item_record        ITEM_MASTER%ROWTYPE;
   L_error_message      RTK_ERRORS.RTK_TEXT%TYPE;
   L_item               ITEM_MASTER.ITEM%TYPE;
   --
   CURSOR C_GET_TPNB IS
   select item
     from packitem
    where pack_no = I_item_pack;
   --
BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TPNB',
                    'PACKITEM',
                    'Item = ' || I_item_pack);
   OPEN C_GET_TPNB;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TPNB',
                    'PACKITEM',
                    'Item = ' || I_item_pack);
   FETCH C_GET_TPNB into L_item;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TPNB',
                    'PACKITEM',
                    'Item = ' || I_item_pack);
   CLOSE C_GET_TPNB;

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(L_error_message,
                                      L_item_record,
                                      L_item) = FALSE then
      return FALSE;
   end if;

   O_item_sell := L_item_record.sellable_ind;

   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_CHK_ITEM_SELLABLE;
----------------------------------------------------------------------------------------------
--NBS00023464 PM009266, Accenture/ Veena N, Veena.Nanjundaiah@in.tesco.com, 19-Aug-2011, End
----------------------------------------------------------------------------------------------
-- Mod By     : shweta.madnawat@in.tesco.com
-- Mod Date   : 24-Oct-2011
-- Mod Ref    : CR434
-- Mod Desc   : Added function TSL_GET_RESTRICT_PCEV, which will find the restrict
--              price event indicator for the given item.
--------------------------------------------------------------------------------------
FUNCTION TSL_GET_RESTRICT_PCEV(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_restrict_pcev      IN OUT VARCHAR2,
                               I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is

   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_RESTRICT_PCEV';

   CURSOR C_GET_RESTRICT_PCEV_IND IS
      select tsl_restrict_price_event
        from item_master
       where item = I_item;
BEGIN
   O_restrict_pcev := 'N';
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_RESTRICT_PCEV_IND',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   OPEN C_GET_RESTRICT_PCEV_IND;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_RESTRICT_PCEV_IND',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   FETCH C_GET_RESTRICT_PCEV_IND into O_restrict_pcev;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_RESTRICT_PCEV_IND',
                    'ITEM_MASTER',
                    'Item = ' || I_item);
   CLOSE C_GET_RESTRICT_PCEV_IND;
   return TRUE;

EXCEPTION
   when OTHERS then
      if C_GET_RESTRICT_PCEV_IND%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_RESTRICT_PCEV_IND',
                          'ITEM_MASTER',
                          'Item = ' || I_item);
         close C_GET_RESTRICT_PCEV_IND;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_GET_RESTRICT_PCEV;
--------------------------------------------------------------------------------------
-- Mod Desc   : Added function TSL_GET_MULTIPACK_QTY, which will find the multipack
--              quantity for the given item.
--------------------------------------------------------------------------------------
FUNCTION TSL_GET_MULTIPACK_QTY(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_multipack_qty      IN OUT NUMBER,
                               I_item               IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program            VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_MULTIPACK_QTY';

   CURSOR C_GET_MULTIPACK_QTY IS
      select tsl_multipack_qty
        from item_attributes
       where item = I_item;
BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_MULTIPACK_QTY',
                    'ITEM_ATTRIBUTES',
                    'Item = ' || I_item);
   OPEN C_GET_MULTIPACK_QTY;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_MULTIPACK_QTY',
                    'ITEM_ATTRIBUTES',
                    'Item = ' || I_item);
   FETCH C_GET_MULTIPACK_QTY into O_multipack_qty;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_MULTIPACK_QTY',
                    'ITEM_ATTRIBUTES',
                    'Item = ' || I_item);
   CLOSE C_GET_MULTIPACK_QTY;
   return TRUE;

EXCEPTION
   when OTHERS then
      if C_GET_MULTIPACK_QTY%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_MULTIPACK_QTY',
                          'ITEM_ATTRIBUTES',
                          'Item = ' || I_item);
         close C_GET_MULTIPACK_QTY;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_GET_MULTIPACK_QTY;
--------------------------------------------------------------------------------
-- Mod Desc   : Added function TSL_GET_LINKED_SINGLE, which will find the single
--              item linked to a given multipack.
--------------------------------------------------------------------------------------
FUNCTION TSL_GET_LINKED_SINGLE(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_linked_single      IN OUT ITEM_MASTER.ITEM%TYPE,
                               I_multipack          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
  L_program            VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_LINKED_SINGLE';

   CURSOR C_GET_LINKED_SINGLE IS
      select item
        from tsl_link_mp_sngl
       where multipack = I_multipack;
BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_LINKED_SINGLE',
                    'TSL_LINK_MP_SNGL',
                    'Multipack = ' || I_multipack);
   OPEN C_GET_LINKED_SINGLE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_LINKED_SINGLE',
                    'TSL_LINK_MP_SNGL',
                    'Multipack = ' || I_multipack);
   FETCH C_GET_LINKED_SINGLE into O_linked_single;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_LINKED_SINGLE',
                    'TSL_LINK_MP_SNGL',
                    'Multipack = ' || I_multipack);
   CLOSE C_GET_LINKED_SINGLE;
   return TRUE;

EXCEPTION
   when OTHERS then
      if C_GET_LINKED_SINGLE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_LINKED_SINGLE',
                          'TSL_LINK_MP_SNGL',
                          'Multipack = ' || I_multipack);
         close C_GET_LINKED_SINGLE;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_GET_LINKED_SINGLE;
--------------------------------------------------------------------------------------
-- Mod Desc   : Added function TSL_VALID_PRICE, which will find if the multipack's
--              price is less than multipack qty times the price of teh single.
--------------------------------------------------------------------------------------
FUNCTION TSL_VALID_PRICE(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid_price        IN OUT BOOLEAN,
                         I_multipack          IN     ITEM_MASTER.ITEM%TYPE,
                         I_multipack_qty      IN     ITEM_ATTRIBUTES.TSL_MULTIPACK_QTY%TYPE,
                         I_link_single_tpnb   IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program            VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_VALID_PRICE';
   L_error_message      RTK_ERRORS.RTK_TEXT%TYPE;
   L_min_rsp            RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;
   L_rsp_single         RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;
   --21-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023962, Begin
   L_item_level         ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level         ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_exists             BOOLEAN;
   L_l2_item_multi      ITEM_MASTER.ITEM%TYPE := I_multipack;
   L_l2_item_sngl       ITEM_MASTER.ITEM%TYPE := I_link_single_tpnb;
   --21-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023962, End

   -- DefNBS024857a/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 18-May-12, Begin
   L_multi_retail1      RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;
   L_multi_retail2      RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;
   L_multi_retail3      RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;
   L_multi_retail4      RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;

   L_single_retail1      RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;
   L_single_retail2      RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;
   L_single_retail3      RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;
   L_single_retail4      RPM_ZONE_FUTURE_RETAIL.SELLING_RETAIL%TYPE;

   L_dept_multi          ITEM_MASTER.DEPT%TYPE;
   L_dept_sngl           ITEM_MASTER.DEPT%TYPE;
   L_class_multi         ITEM_MASTER.CLASS%TYPE;
   L_class_sngl          ITEM_MASTER.CLASS%TYPE;
   L_subclass_multi      ITEM_MASTER.SUBCLASS%TYPE;
   L_subclass_sngl       ITEM_MASTER.SUBCLASS%TYPE;

   CURSOR C_GET_MIN_RSP IS
      select min(rfr.selling_retail) retail1,
             min(rfr.clear_retail) retail2,
             min(rfr.simple_promo_retail) retail3,
             min(rfr.complex_promo_retail) retail4
        from rpm_future_retail rfr,
             rpm_zone_location rzl
       where rzl.tsl_restrict_price_event = 1
         and rzl.tsl_primary_loc_ind      = 1
         and rfr.location = rzl.location
         and rfr.item = L_l2_item_multi
         and rfr.dept  = L_dept_multi
         and rfr.class = L_class_multi
         and rfr.subclass = L_subclass_multi
         and rfr.action_date >= (select max(rfr1.action_date)
                                   from rpm_future_retail rfr1,
                                        rpm_zone_location rzl1
                                  where rzl1.tsl_restrict_price_event = 1
                                    and rzl1.tsl_primary_loc_ind      = 1
                                    and rfr1.location = rzl1.location
                                    and rfr1.item = L_l2_item_multi
                                    and rfr1.dept  = L_dept_multi
                                    and rfr1.class = L_class_multi
                                    and rfr1.subclass = L_subclass_multi
                                    and rfr1.action_date <= get_vdate);
   CURSOR C_GET_RSP_SINGLE IS
      select max(rfr.selling_retail) retail1,
             max(rfr.clear_retail) retail2,
             max(rfr.simple_promo_retail) retail3,
             max(rfr.complex_promo_retail) retail4
        from rpm_future_retail rfr,
             rpm_zone_location rzl
       where rzl.tsl_restrict_price_event = 1
         and rzl.tsl_primary_loc_ind      = 1
         and rfr.location = rzl.location
         and rfr.item = L_l2_item_sngl
         and rfr.dept  = L_dept_sngl
         and rfr.class = L_class_sngl
         and rfr.subclass = L_subclass_sngl
         and rfr.action_date >= (select max(rfr1.action_date)
                                   from rpm_future_retail rfr1,
                                        rpm_zone_location rzl1
                                  where rzl1.tsl_restrict_price_event = 1
                                    and rzl1.tsl_primary_loc_ind      = 1
                                    and rfr1.location = rzl1.location
                                    and rfr1.item = L_l2_item_sngl
                                    and rfr1.dept  = L_dept_sngl
                                    and rfr1.class = L_class_sngl
                                    and rfr1.subclass = L_subclass_sngl
                                    and rfr1.action_date <= get_vdate);


   CURSOR C_GET_MIN_RSP_MULTI IS
      Select Case When L_multi_retail1 < L_multi_retail2 And L_multi_retail1 < L_multi_retail3 and
                       L_multi_retail1 < L_multi_retail4 Then L_multi_retail1
                  When L_multi_retail2 < L_multi_retail3 And L_multi_retail2 < L_multi_retail4 and
                       L_multi_retail2 < L_multi_retail1 Then L_multi_retail2
                  When L_multi_retail3 < L_multi_retail4 And L_multi_retail3 < L_multi_retail1 and
                       L_multi_retail3 < L_multi_retail2 Then L_multi_retail3
                  Else L_multi_retail4
             End As TheMin
        From Dual;


   CURSOR C_GET_MAX_RSP_SINGLE IS
      Select Case When L_single_retail1 > L_single_retail2 And L_single_retail1 > L_single_retail3 and
                       L_single_retail1 > L_single_retail4 Then L_single_retail1
                  When L_single_retail2 > L_single_retail3 And L_single_retail2 > L_single_retail4 and
                       L_single_retail2 > L_single_retail1 Then L_single_retail2
                  When L_single_retail3 > L_single_retail4 And L_single_retail3 > L_single_retail1 and
                       L_single_retail3 > L_single_retail2 Then L_single_retail3
                  Else L_single_retail4
             End As TheMax
        From  Dual;
   -- DefNBS024857a/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 18-May-12, End
   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, Begin
   CURSOR C_GET_MIN_RSP_RZFR IS
   select min(selling_retail) selling_retail
     from rpm_zone_future_retail rzf,
          rpm_zone rz
    where rz.tsl_restrict_price_event = 1
      and rzf.zone = rz.zone_id
      and rzf.item = L_l2_item_multi
      and (rzf.action_date > get_vdate
           or rzf.action_date = (select max(rzfr1.action_date)
                                   from rpm_zone_future_retail rzfr1,
                                        rpm_zone rz1
                                  where rz1.tsl_restrict_price_event = 1
                                    and rzfr1.zone = rz1.zone_id
                                    and rzfr1.item = L_l2_item_multi
                                    and rzfr1.action_date <= get_vdate));

   CURSOR C_GET_RSP_SINGLE_RZFR IS
   select max(selling_retail) selling_retail
     from rpm_zone_future_retail rzf,
          rpm_zone rz
    where rz.tsl_restrict_price_event = 1
      and rzf.zone = rz.zone_id
      and rzf.item = L_l2_item_sngl
      and (rzf.action_date > get_vdate
           or rzf.action_date = (select max(rzfr1.action_date)
                                   from rpm_zone_future_retail rzfr1,
                                        rpm_zone rz1
                                  where rz1.tsl_restrict_price_event = 1
                                    and rzfr1.zone = rz1.zone_id
                                    and rzfr1.item = L_l2_item_sngl
                                    and rzfr1.action_date <= get_vdate));
   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, End
BEGIN
   --23-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023975, Begin
   --21-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023962, Begin
   if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                 L_item_level,
                                 L_tran_level,
                                 I_multipack) = FALSE then
      return FALSE;
   end if;

   -- DefNBS024857a/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 18-May-12, Begin
   if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                     L_l2_item_multi,
                                     L_dept_multi,
                                     L_class_multi,
                                     L_subclass_multi) = FALSE then
      return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                     L_l2_item_sngl,
                                     L_dept_sngl,
                                     L_class_sngl,
                                     L_subclass_sngl) = FALSE then
      return FALSE;
   end if;
   -- DefNBS024857a/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 18-May-12, End


   if L_item_level = 1 and L_tran_level = 2 then
      if ITEM_ATTRIB_SQL.TSL_GET_FIRST_L2(O_error_message,
                                          L_exists,
                                          L_l2_item_multi,
                                          I_multipack) = FALSE then
         return FALSE;
      end if;
   end if;

   if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                 L_item_level,
                                 L_tran_level,
                                 I_link_single_tpnb) = FALSE then
      return FALSE;
   end if;

   if L_item_level = 1 and L_tran_level = 2 then
      if ITEM_ATTRIB_SQL.TSL_GET_FIRST_L2(O_error_message,
                                          L_exists,
                                          L_l2_item_sngl,
                                          I_link_single_tpnb) = FALSE then
         return FALSE;
      end if;
   end if;
   --21-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023962, End
   --23-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023975, End
   O_valid_price := TRUE;
   -- DefNBS024857a/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 18-May-12, Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_MIN_RSP',
                    'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                    'Item = ' || I_multipack);
   OPEN C_GET_MIN_RSP;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_MIN_RSP',
                    'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                    'Item = ' || I_multipack);

   FETCH C_GET_MIN_RSP into L_multi_retail1,
                            L_multi_retail2,
                            L_multi_retail3,
                            L_multi_retail4;

   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, Begin
   if L_multi_retail1 is NULL and
      L_multi_retail2 is NULL and
      L_multi_retail3 is NULL and
      L_multi_retail4 is NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_MIN_RSP_RZFR',
                       'RPM_ZONE_FUTURE_RETAIL,RPM_ZONE',
                       'Item = ' || I_multipack);
      OPEN C_GET_MIN_RSP_RZFR;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_MIN_RSP_RZFR',
                       'RPM_ZONE_FUTURE_RETAIL,RPM_ZONE',
                       'Item = ' || I_multipack);
      FETCH C_GET_MIN_RSP_RZFR into L_min_rsp;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_MIN_RSP_RZFR',
                       'RPM_ZONE_FUTURE_RETAIL,RPM_ZONE',
                       'Item = ' || I_multipack);
      CLOSE C_GET_MIN_RSP_RZFR;
   else
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_MIN_RSP_MULTI',
                       'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                       'Item = ' || I_multipack);
      OPEN C_GET_MIN_RSP_MULTI;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_MIN_RSP_MULTI',
                       'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                       'Item = ' || I_multipack);
      FETCH C_GET_MIN_RSP_MULTI into L_min_rsp;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_MIN_RSP_MULTI',
                       'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                       'Item = ' || I_multipack);
      CLOSE C_GET_MIN_RSP_MULTI;
   end if;
   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, End
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_MIN_RSP',
                    'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                    'Item = ' || I_multipack);
   CLOSE C_GET_MIN_RSP;
   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, Begin
   --Remove code to fetch the record from C_GET_MIN_RSP_MULTI cursor and put the same in
   --else part of above if-then-else statement
   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, End
   ---

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_RSP_SINGLE',
                    'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                    'Item = ' || I_link_single_tpnb);
   OPEN C_GET_RSP_SINGLE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_RSP_SINGLE',
                    'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                    'Item = ' || I_link_single_tpnb);
   FETCH C_GET_RSP_SINGLE into L_single_retail1,
                               L_single_retail2,
                               L_single_retail3,
                               L_single_retail4;
   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, Begin
   if L_single_retail1 is NULL and
      L_single_retail2 is NULL and
      L_single_retail3 is NULL and
      L_single_retail4 is NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_RSP_SINGLE_RZFR',
                       'RPM_ZONE_FUTURE_RETAIL,RPM_ZONE',
                       'Item = ' || I_link_single_tpnb);
      OPEN C_GET_RSP_SINGLE_RZFR;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_RSP_SINGLE_RZFR',
                       'RPM_ZONE_FUTURE_RETAIL,RPM_ZONE',
                       'Item = ' || I_link_single_tpnb);
      FETCH C_GET_RSP_SINGLE_RZFR into L_rsp_single;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_RSP_SINGLE_RZFR',
                       'RPM_ZONE_FUTURE_RETAIL,RPM_ZONE',
                       'Item = ' || I_link_single_tpnb);
      CLOSE C_GET_RSP_SINGLE_RZFR;
   else
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_MAX_RSP_SINGLE',
                       'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                       'Item = ' || I_link_single_tpnb);
      OPEN C_GET_MAX_RSP_SINGLE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_MAX_RSP_SINGLE',
                       'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                       'Item = ' || I_link_single_tpnb);

      FETCH C_GET_MAX_RSP_SINGLE into L_rsp_single;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_MAX_RSP_SINGLE',
                       'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                       'Item = ' || I_link_single_tpnb);
      CLOSE C_GET_MAX_RSP_SINGLE;
   end if;
   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, End
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_RSP_SINGLE',
                    'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                    'Item = ' || I_link_single_tpnb);
   CLOSE C_GET_RSP_SINGLE;
   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, Begin
   --Remove code to fetch the record from C_GET_MAX_RSP_SINGLE cursor and put the same in
   --else part of above if-then-else statement
   -- DefNBS024857b/PM015114, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 24-May-2012, End
   -- DefNBS024857a/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 18-May-12, End

   if L_min_rsp < (L_rsp_single * I_multipack_qty) then
      O_valid_price := FALSE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      if C_GET_MIN_RSP%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_MIN_RSP',
                       'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                       'Item = ' || I_multipack);
         CLOSE C_GET_MIN_RSP;
      end if;

      if C_GET_RSP_SINGLE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_RSP_SINGLE',
                          'RPM_FUTURE_RETAIL,RPM_ZONE_LOCATION',
                          'Item = ' || I_link_single_tpnb);
         CLOSE C_GET_RSP_SINGLE;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_VALID_PRICE;
--------------------------------------------------------------------------------------
-- Mod Desc   : Added function TSL_CHECK_VALID_SINGLE, which will find if the user
--              has access to single item or not.
--------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_VALID_SINGLE(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_valid_single       IN OUT BOOLEAN,
                                I_single             IN     ITEM_MASTER.ITEM%TYPE,
                                I_user_country       IN     VARCHAR2,
                                I_multipack          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_item_rec        ITEM_MASTER%ROWTYPE;
   L_program         VARCHAR2(64)  := 'ITEM_ATTRIB_SQL.TSL_CHECK_VALID_SINGLE';
   L_valid_price     BOOLEAN;
   L_single          VARCHAR2(1);
   L_error_message   RTK_ERRORS.RTK_TEXT%TYPE;
   L_zones           VARCHAR2(255);
   L_uk              VARCHAR2(1);
   L_roi              VARCHAR2(1);

   CURSOR C_VALID_SINGLE is
      select Distinct 'X'
        from item_attributes ia,
             item_master iem
       where (ia.tsl_multipack_qty = 1 or ia.tsl_multipack_qty is null)
         and iem.item = I_single
         and iem.item = ia.item
         and iem.tsl_owner_country in (L_uk, L_roi)
         and iem.item_level = iem.tran_level
         and iem.item_level = 2;
BEGIN
   O_valid_single := FALSE;
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(L_error_message,
                                      L_item_rec,
                                      I_single) = FALSE then
      return FALSE;
   end if;
   if I_user_country in ('B', 'U') then
      L_uk := 'U';
   end if;
   if I_user_country in ('B', 'R') then
      L_roi := 'R';
   end if;
   if L_item_rec.status = 'A' then

      SQL_LIB.SET_MARK('OPEN',
                       'C_VALID_SINGLE',
                       'ITEM_ATTRIBUTES,ITEM_MASTER',
                       'Item = ' || I_single);
      OPEN C_VALID_SINGLE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_VALID_SINGLE',
                       'ITEM_ATTRIBUTES,ITEM_MASTER',
                       'Item = ' || I_single);
      FETCH C_VALID_SINGLE into L_single;
      if C_VALID_SINGLE%FOUND then
         O_valid_single := TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_VALID_SINGLE',
                       'ITEM_ATTRIBUTES,ITEM_MASTER',
                       'Item = ' || I_single);
      CLOSE C_VALID_SINGLE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      if C_VALID_SINGLE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_VALID_SINGLE',
                          'ITEM_ATTRIBUTES,ITEM_MASTER',
                          'Item = ' || I_multipack);
         CLOSE C_VALID_SINGLE;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_CHECK_VALID_SINGLE;
--------------------------------------------------------------------------------
-- Mod Desc   : Added function TSL_INS_LINK_MP_SNGL, which will insert/updatr the records
--              in TSL_LINK_MP_SNGL.
--------------------------------------------------------------------------------------
FUNCTION TSL_INS_LINK_MP_SNGL(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              I_single             IN     ITEM_MASTER.ITEM%TYPE,
                              I_multipack          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program             VARCHAR2(64)  := 'ITEM_ATTRIB_SQL.TSL_INS_LINK_MP_SNGL';
   L_linked_single       ITEM_MASTER.ITEM%TYPE;
   L_item_number_type    ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   L_exists              BOOLEAN;
   L_owner_country_uk    ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE  := NULL;
   L_owner_country_roi   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE  := NULL;
   L_sec_uk_ind          VARCHAR2(1) := 'N';
   L_sec_roi_ind         VARCHAR2(1) := 'N';
   L_loc_access_ind      VARCHAR2(1);
   L_item_rec            ITEM_MASTER%ROWTYPE;

   CURSOR C_GET_CHILD_ITEMS is
   select distinct iem.item
     from item_master     iem,
          item_attributes iatr
    where iem.item_parent = I_multipack
      and iem.item = iatr.item
      and iem.item_level = iem.tran_level
      and iem.pack_ind = 'N'
      and iem.tsl_owner_country in (L_owner_country_uk, L_owner_country_roi)
      and iatr.tsl_multipack_qty > 1;
BEGIN
   if I_single is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_single',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_multipack is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_multipack',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   -- To check whether the user has UK access or ROI or Both.
   if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY (O_error_message,
                                              L_sec_uk_ind,
                                              L_sec_roi_ind) = FALSE then
      return FALSE;
   end if;

   if L_sec_uk_ind = 'Y' and L_sec_roi_ind = 'Y' then
      L_loc_access_ind := 'B';
   elsif L_sec_uk_ind = 'Y' and L_sec_roi_ind = 'N' then
      L_loc_access_ind := 'U';
   elsif L_sec_uk_ind = 'N' and L_sec_roi_ind = 'Y' then
      L_loc_access_ind := 'R';
   end if;

   if L_loc_access_ind in ('B', 'U') then
      L_owner_country_uk := 'U';
   end if;

   if L_loc_access_ind in ('B', 'R') then
      L_owner_country_roi := 'R';
   end if;

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_rec,
                                      I_multipack) = FALSE then
      return FALSE;
   end if;

   if L_item_rec.item_number_type = 'TPNA' then
      if ITEM_ATTRIB_SQL.GET_CHILD_ITEM_NUMBER_TYPE(O_error_message,
                                                    L_item_number_type,
                                                    L_exists,
                                                    I_multipack) = FALSE then
         return FALSE;
      end if;

      if L_exists = TRUE then
         FOR c_rec in C_GET_CHILD_ITEMS
         LOOP
            if ITEM_ATTRIB_SQL.TSL_GET_LINKED_SINGLE(O_error_message,
                                                     L_linked_single,
                                                     c_rec.item) = FALSE then
               return FALSE;
            end if;

            if L_linked_single is NULL then
               SQL_LIB.SET_MARK('INSERT',
                                'TSL_LINK_MP_SNGL',
                                NULL,
                                NULL);
               -- inserting the values in the tsl_link_mp_sngl table
               insert into tsl_link_mp_sngl (item,
                                             multipack)
                                     values (I_single,
                                             c_rec.item);
            else
               -- updating the values in the tsl_link_mp_sngl table
               if L_linked_single <> I_single then
                  Update tsl_link_mp_sngl
                     set item = I_single
                   where multipack = c_rec.item;
               end if;
            end if;
         END LOOP;
      end if;
   else
      if ITEM_ATTRIB_SQL.TSL_GET_LINKED_SINGLE(O_error_message,
                                               L_linked_single,
                                               I_multipack) = FALSE then
         return FALSE;
      end if;

      if L_linked_single is NULL then
         SQL_LIB.SET_MARK('INSERT',
                          'TSL_LINK_MP_SNGL',
                          NULL,
                          NULL);

         -- inserting the values in the tsl_link_mp_sngl table
         insert into tsl_link_mp_sngl (item,
                                       multipack)
                               values (I_single,
                                       I_multipack);
      else
         -- updating the values in the tsl_link_mp_sngl table
         if L_linked_single <> I_single then
            Update tsl_link_mp_sngl
               set item = I_single
             where multipack = I_multipack;
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
END TSL_INS_LINK_MP_SNGL;
--------------------------------------------------------------------------------------
-- Mod Desc   : Added function TSL_IS_LINK_EXISTS, which will check if any link exists
--              for the single level2 item in table TSL_INS_LINK_MP_SNGL.
--------------------------------------------------------------------------------------
FUNCTION TSL_IS_LINK_EXISTS(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_link_Exists        IN OUT BOOLEAN,
                            I_single             IN     ITEM_MASTER.ITEM%TYPE,
                            I_multipack          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program         VARCHAR2(64)  := 'ITEM_ATTRIB_SQL.TSL_IS_LINK_EXISTS';
   L_is_exists       VARCHAR2(1);

   CURSOR C_IS_LINK_EXISTS is
      select 'X'
        from tsl_link_mp_sngl
       where item      =  I_single
         and multipack = I_multipack;
BEGIN
   O_link_Exists := FALSE;

   SQL_LIB.SET_MARK('OPEN',
                    'C_IS_LINK_EXISTS',
                    'TSL_LINK_MP_SNGL',
                    'Item = ' || I_single);
   OPEN C_IS_LINK_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_IS_LINK_EXISTS',
                    'TSL_LINK_MP_SNGL',
                    'Item = ' || I_single);
   FETCH C_IS_LINK_EXISTS into L_is_exists;

   if C_IS_LINK_EXISTS%NOTFOUND then
      O_link_Exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_IS_LINK_EXISTS',
                    'TSL_LINK_MP_SNGL',
                    'Item = ' || I_single);
   CLOSE C_IS_LINK_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      if C_IS_LINK_EXISTS%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_IS_LINK_EXISTS',
                          'TSL_LINK_MP_SNGL',
                          'Item = ' || I_single);
         CLOSE C_IS_LINK_EXISTS;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_IS_LINK_EXISTS;
---------------------------------------------------------------------------------------------
-- Mod Desc   : Added function TSL_DELETE_LINK, which will delete the link in
--              table TSL_INS_LINK_MP_SNGL.
--------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_LINK(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         I_multipack          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program             VARCHAR2(64)  := 'ITEM_ATTRIB_SQL.TSL_DELETE_LINK';
   L_item_rec            ITEM_MASTER%ROWTYPE;
   L_item_number_type    ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   L_exists              BOOLEAN;
   L_linked_single       ITEM_MASTER.ITEM%TYPE;

   CURSOR C_GET_CHILD_ITEMS is
   select distinct iem.item
     from item_master     iem,
          item_attributes iatr
    where iem.item_parent = I_multipack
      and iem.item = iatr.item
      and iem.item_level = iem.tran_level
      and iem.pack_ind = 'N';

BEGIN
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_rec,
                                      I_multipack) = FALSE then
      return FALSE;
   end if;
   if L_item_rec.item_number_type = 'TPNA' then
      if ITEM_ATTRIB_SQL.GET_CHILD_ITEM_NUMBER_TYPE(O_error_message,
                                                    L_item_number_type,
                                                    L_exists,
                                                    I_multipack) = FALSE then
         return FALSE;
      end if;

      if L_exists = TRUE then
         FOR c_rec in C_GET_CHILD_ITEMS
         LOOP
            if ITEM_ATTRIB_SQL.TSL_GET_LINKED_SINGLE(O_error_message,
                                                     L_linked_single,
                                                     c_rec.item) = FALSE then
               return FALSE;
            end if;

            if L_linked_single is NOT NULL then
               SQL_LIB.SET_MARK('DELETE',
                                NULL,
                                'tsl_link_mp_sngl',
                                'I_multipack '||c_rec.item);

               delete from tsl_link_mp_sngl tlms
                where tlms.multipack = c_rec.item;
            end if;
         END LOOP;
      end if;
   else
      if ITEM_ATTRIB_SQL.TSL_GET_LINKED_SINGLE(O_error_message,
                                               L_linked_single,
                                               I_multipack) = FALSE then
         return FALSE;
      end if;

      if L_linked_single is NOT NULL then
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'tsl_link_mp_sngl',
                          'I_multipack '||I_multipack);

               delete from tsl_link_mp_sngl tlms
                where tlms.multipack = I_multipack;
      end if;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));

END TSL_DELETE_LINK;
---------------------------------------------------------------------------------------------
-- Mod Desc   : Added function TSL_CHECK_VALID_MULTI, hich will find if the user
--              has access to multipack item or not.
--------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_VALID_MULTI(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_valid_multi        IN OUT BOOLEAN,
                               I_multipack          IN     ITEM_MASTER.ITEM%TYPE,
                               I_user_country       IN     VARCHAR2)
RETURN BOOLEAN is
   L_program         VARCHAR2(64)  := 'ITEM_ATTRIB_SQL.TSL_CHECK_VALID_MULTI';
   L_uk              VARCHAR2(1);
   L_roi             VARCHAR2(1);
   L_multi           VARCHAR2(1);

   CURSOR C_VALID_MULTI is
      select Distinct 'X'
        from item_master     im,
             item_attributes ia
       where im.item = I_multipack
         and im.item = ia.item
         and ia.tsl_multipack_qty > 1
         and im.status in ('W', 'S', 'A')
         and im.tsl_owner_country in (L_uk, L_roi)
         and im.item_level = 2
         and im.item_level = im.tran_level
         --DefNBS024054, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 15-Dec-2011, Begin
         and im.item NOT IN (select tlms.multipack from tsl_link_mp_sngl tlms);
         --DefNBS024054, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 15-Dec-2011, End
BEGIN
   O_valid_multi := FALSE;

   if I_user_country in ('B', 'U') then
      L_uk := 'U';
   end if;

   if I_user_country in ('B', 'R') then
      L_roi := 'R';
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_VALID_MULTI',
                    'ITEM_ATTRIBUTES,ITEM_MASTER',
                    'Item = ' || I_multipack);
   OPEN C_VALID_MULTI;

   SQL_LIB.SET_MARK('FETCH',
                    'C_VALID_MULTI',
                    'ITEM_ATTRIBUTES,ITEM_MASTER',
                    'Item = ' || I_multipack);
   FETCH  C_VALID_MULTI into L_multi;

   if C_VALID_MULTI%FOUND then
      O_valid_multi := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_VALID_MULTI',
                    'ITEM_ATTRIBUTES,ITEM_MASTER',
                    'Item = ' || I_multipack);
   CLOSE  C_VALID_MULTI;

   return TRUE;
EXCEPTION
   when OTHERS then
      if C_VALID_MULTI%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_VALID_MULTI',
                          'ITEM_ATTRIBUTES,ITEM_MASTER',
                          'Item = ' || I_multipack);
         CLOSE C_VALID_MULTI;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_CHECK_VALID_MULTI;
---------------------------------------------------------------------------------------------
-- Mod Desc   : Added function TSL_INS_LINK_CASCADE, which will insert all TPNBs of TPNA
--              in TSL_LINK_MP_SNGL.
--------------------------------------------------------------------------------------
FUNCTION TSL_INS_LINK_CASCADE(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              I_single             IN     ITEM_MASTER.ITEM%TYPE,
                              I_multipack          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program             VARCHAR2(64)  := 'ITEM_ATTRIB_SQL.TSL_INS_LINK_CASCADE';
   L_owner_country_uk    ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE  := NULL;
   L_owner_country_roi   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE  := NULL;
   L_sec_uk_ind          VARCHAR2(1) := 'N';
   L_sec_roi_ind         VARCHAR2(1) := 'N';
   L_loc_access_ind      VARCHAR2(1);
   L_link_Exists         BOOLEAN;
   L_item_number_type    ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   L_exists              BOOLEAN;

   CURSOR C_GET_CHILD_ITEMS is
   select distinct iem.item
     from item_master     iem,
          item_attributes iatr
    where iem.item_parent = I_single
      and iem.item = iatr.item
      and iem.item_level = iem.tran_level
      and iem.pack_ind = 'N'
      and iem.tsl_owner_country in (L_owner_country_uk, L_owner_country_roi)
      and (iatr.tsl_multipack_qty is NULL or iatr.tsl_multipack_qty = 1);
BEGIN
   if I_single is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_single',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_multipack is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_multipack',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   -- To check whether the user has UK access or ROI or Both.
   if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY (O_error_message,
                                              L_sec_uk_ind,
                                              L_sec_roi_ind) = FALSE then
      return FALSE;
   end if;

   if L_sec_uk_ind = 'Y' and L_sec_roi_ind = 'Y' then
      L_loc_access_ind := 'B';
   elsif L_sec_uk_ind = 'Y' and L_sec_roi_ind = 'N' then
      L_loc_access_ind := 'U';
   elsif L_sec_uk_ind = 'N' and L_sec_roi_ind = 'Y' then
      L_loc_access_ind := 'R';
   end if;

   if L_loc_access_ind in ('B', 'U') then
      L_owner_country_uk := 'U';
   end if;

   if L_loc_access_ind in ('B', 'R') then
      L_owner_country_roi := 'R';
   end if;

   if ITEM_ATTRIB_SQL.GET_CHILD_ITEM_NUMBER_TYPE(O_error_message,
                                                 L_item_number_type,
                                                 L_exists,
                                                 I_single) = FALSE then
      return FALSE;
   end if;

   if L_exists = TRUE then
      FOR c_rec in C_GET_CHILD_ITEMS
      LOOP
         if ITEM_ATTRIB_SQL.TSL_IS_LINK_EXISTS(O_error_message,
                                               L_link_Exists,
                                               c_rec.item,
                                               I_multipack) = FALSE then
            return FALSE;
         end if;

         if L_link_Exists then
            SQL_LIB.SET_MARK('INSERT',
                             'TSL_LINK_MP_SNGL',
                             NULL,
                             NULL);
            -- inserting the values in the tsl_link_mp_sngl table
            insert into tsl_link_mp_sngl (item,
                                          multipack)
                                  values (c_rec.item,
                                          I_multipack);
         else
            -- updating the values in the tsl_link_mp_sngl table
            Update tsl_link_mp_sngl
               set multipack = I_multipack
             where item      = c_rec.item
               and multipack = I_multipack;
         end if;
      END LOOP;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_INS_LINK_CASCADE;
--------------------------------------------------------------------------------------
-- Mod By     : vatan.jaiswal@in.tesco.com
-- Mod Date   : 12-Nov-2011
-- Mod Ref    : CR434
-- Mod Desc   : Added function TSL_DELETE_LINK_MP, which will delete Single Level2-Multipack
--              link from table TSL_INS_LINK_MP_SNGL.
--------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_LINK_MP(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_item               IN     ITEM_MASTER.ITEM%TYPE,
                            I_multipack          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is
   L_program             VARCHAR2(64)  := 'ITEM_ATTRIB_SQL.TSL_DELETE_LINK_MP';
   --23-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023978, Begin
   L_item_rec            ITEM_MASTER%ROWTYPE;
   L_item_number_type    ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   L_exists              BOOLEAN;
   --23-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023978, End

   CURSOR C_GET_CHILD_ITEMS is
   select distinct iem.item
     from item_master     iem,
          item_attributes iatr
    where iem.item_parent = I_item
      and iem.item = iatr.item
      and iem.item_level = iem.tran_level
      and iem.pack_ind = 'N';
BEGIN
   --23-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023978, Begin
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_rec,
                                      I_item) = FALSE then
      return FALSE;
   end if;

   if L_item_rec.item_number_type = 'TPNA' then
      if ITEM_ATTRIB_SQL.GET_CHILD_ITEM_NUMBER_TYPE(O_error_message,
                                                    L_item_number_type,
                                                    L_exists,
                                                    I_item) = FALSE then
         return FALSE;
      end if;
      if L_exists = TRUE then
   --23-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023978, End
         FOR c_rec in C_GET_CHILD_ITEMS
         LOOP
            SQL_LIB.SET_MARK('DELETE',
                             NULL,
                             'tsl_link_mp_sngl',
                             'I_item'||c_rec.item);

            delete from tsl_link_mp_sngl tlms
             where tlms.item      = c_rec.item
               and tlms.multipack = NVL(I_multipack, tlms.multipack);
         END LOOP;
   --23-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023978, Begin
      end if;
   else
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'tsl_link_mp_sngl',
                       'I_item'||I_item);
      delete from tsl_link_mp_sngl tlms
       where tlms.item      = I_item
         and tlms.multipack = NVL(I_multipack, tlms.multipack);
   end if;
   --23-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023978, End
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_DELETE_LINK_MP;
--------------------------------------------------------------------------------------
-- Mod By     : vatan.jaiswal@in.tesco.com
-- Mod Date   : 06-Feb-2012
-- Mod Ref    : DefNBS024293
-- Mod Desc   : Added function TSL_CHECK_MP_QTY, which will check whether TPNA and all of TPNBS of
--              TPNA have same Multipack Quantity.
--------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_MP_QTY(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          I_tpna               IN     ITEM_MASTER.ITEM%TYPE,
                          I_multipack          IN     ITEM_MASTER.ITEM%TYPE,
                          I_flag               IN OUT VARCHAR2)
RETURN BOOLEAN is
   L_program             VARCHAR2(64)  := 'ITEM_ATTRIB_SQL.TSL_CHECK_MP_QTY';
   --Cursor to find the all TPNBs of TPNA
   CURSOR C_GET_TPNB is
   select distinct iem.item, iatr.tsl_multipack_qty
     from item_master     iem,
          item_attributes iatr
    where iem.item_parent = I_tpna
      and iem.item = iatr.item
      and iem.item_level = iem.tran_level
      and iem.pack_ind = 'N';
BEGIN
   I_flag := 'N';

   FOR c_rec in C_GET_TPNB
   LOOP
      if I_multipack > 1 then
         if c_rec.tsl_multipack_qty > 1 then
            I_flag := 'Y';
         else
            I_flag := 'N';
            exit;
         end if;
      elsif (I_multipack is NULL or I_multipack = 1) then
         if (c_rec.tsl_multipack_qty is NULL or c_rec.tsl_multipack_qty = 1) then
            I_flag := 'Y';
         else
            I_flag := 'N';
            exit;
         end if;
      end if;
   END LOOP;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_MP_QTY;
----------------------------------------------------------------------------------------------
-- 29-Dec-2011 Tesco HSC/Usha Patil           Mod: N169 Begin
----------------------------------------------------------------------------------------------
-- Function : TSL_INSERT_PICKLIST_BME_STATUS
-- Purpose  : Function to insert records into tsl_picklist_status table if there are no approval
--            happened and no barcode move/exchange/overwrite record exists for the same business day.
----------------------------------------------------------------------------------------------
FUNCTION TSL_INSERT_PICKLIST_BME_STATUS (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                         O_picklist_item IN OUT VARCHAR2,
                                         I_item          IN     POS_ITEM_BUTTON.ITEM%TYPE)
   return BOOLEAN IS
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_INSERT_PICKLIST_BME_STATUS';

   L_picklist_ind          VARCHAR2(1);
   -- N169/CR373 13-Mar-2012 Bhargavi P/bharagavi.pujari@in.tesco.com Begin
   L_barcode_move_exchange VARCHAR2(1) := 'N';
   -- N169/CR373 13-Mar-2012 Bhargavi P/bharagavi.pujari@in.tesco.com End

   CURSOR C_CHK_BARCODE_APPROVED IS
   select 'Y'
     from tsl_picklist_status tis
    where tis.action_type in ('B','A')
      and tis.vdate  = get_vdate();

   CURSOR C_CHK_BARCODE_PARENT IS
   select 'Y'
     from pos_item_button pib
    where pib.item = I_item
UNION ALL
   select 'Y'
     from pos_item_button pib,
          item_master iem
    where iem.item          = I_item
      and iem.tsl_base_item = pib.item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_CHK_BARCODE_APPROVED', 'TSL_PICKLIST_STATUS', NULL);
   OPEN C_CHK_BARCODE_APPROVED;

   SQL_LIB.SET_MARK('FETCH', 'C_CHK_BARCODE_APPROVED', 'TSL_PICKLIST_STATUS', NULL);
   FETCH C_CHK_BARCODE_APPROVED INTO L_barcode_move_exchange;

   if C_CHK_BARCODE_APPROVED%FOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_CHK_BARCODE_APPROVED', 'TSL_PICKLIST_STATUS', NULL);
      CLOSE C_CHK_BARCODE_APPROVED;
      return TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_CHK_BARCODE_APPROVED', 'TSL_PICKLIST_STATUS', NULL);
   CLOSE C_CHK_BARCODE_APPROVED;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHK_BARCODE_PARENT;',
                    'POS_ITEM_BUTTON, ITEM_MASTER',
                    'Item = ' || I_item);
   OPEN C_CHK_BARCODE_PARENT;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHK_BARCODE_PARENT;',
                    'POS_ITEM_BUTTON, ITEM_MASTER',
                    'Item = ' || I_item);
   FETCH C_CHK_BARCODE_PARENT INTO L_picklist_ind;


   if C_CHK_BARCODE_PARENT%FOUND then
      O_picklist_item := 'Y';
      -- N169/CR373 13-Mar-2012 Bhargavi P/bharagavi.pujari@in.tesco.com Begin
      if L_barcode_move_exchange != 'Y' then
      -- N169/CR373 13-Mar-2012 Bhargavi P/bharagavi.pujari@in.tesco.com End
           insert into tsl_picklist_status (action_type,
                                            user_id,
                                            vdate,
                                            date_timestamp)
                                    values ('B',
                                            USER,
                                            get_vdate(),
                                            sysdate);
      -- N169/CR373 13-Mar-2012 Bhargavi P/bharagavi.pujari@in.tesco.com Begin
      end if;
      -- N169/CR373 13-Mar-2012 Bhargavi P/bharagavi.pujari@in.tesco.com End
   else
      O_picklist_item := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHK_BARCODE_PARENT;',
                    'POS_ITEM_BUTTON, ITEM_MASTER',
                    'Item = ' || I_item);
   CLOSE C_CHK_BARCODE_PARENT;

   return TRUE;

EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_INSERT_PICKLIST_BME_STATUS;
------------------------------------------------------------------------------------------------
-- Function : TSL_PICKLIST_ITEM
-- Purpose  : Function to check if the item exists in POS_ITEM_BUTTON
------------------------------------------------------------------------------------------------
FUNCTION TSL_PICKLIST_ITEM (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_exists        IN OUT VARCHAR2,
                            I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_program   VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_PICKLIST_ITEM';

   L_exists    VARCHAR2(1);

   CURSOR C_ITEM_EXISTS IS
   select 'Y'
     from pos_item_button pib
    where pib.item = I_item;
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_EXISTS',
                    'POS_ITEM_BUTTON',
                    'Item = ' || I_item);
   OPEN C_ITEM_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_EXISTS',
                    'POS_ITEM_BUTTON',
                    'Item = ' || I_item);
   FETCH C_ITEM_EXISTS INTO L_exists;

   if C_ITEM_EXISTS%FOUND then
      O_exists := 'Y';
   else
      O_exists := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_EXISTS',
                    'POS_ITEM_BUTTON',
                    'Item = ' || I_item);
   CLOSE C_ITEM_EXISTS;

   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_PICKLIST_ITEM;
----------------------------------------------------------------------------------------------
-- 29-Dec-2011 Tesco HSC/Usha Patil           Mod: N169 End
----------------------------------------------------------------------------------------------
END ITEM_ATTRIB_SQL;
/

