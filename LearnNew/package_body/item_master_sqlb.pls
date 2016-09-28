CREATE OR REPLACE PACKAGE BODY ITEM_MASTER_SQL AS
---------------------------------------------------------------------------------------
-- Mod By:      Vinod Kumar, vinod.patalappa@in.tesco.com
-- Mod Date:    16-Jun-2008
-- Mod Ref:     Mod N111.
-- Mod Details: Modified the function UPDATE_ITEM_MASTER() to handlde the
--              primary_ref_item_ind.
----------------------------------------------------------------------------------------
-- Mod By:      Rahul Soni
-- Mod Date:    18-Mar-2008
-- Mod Ref:     Mod N114.
-- Mod Details: Added the new field tsl_variant_reason_code for ModN114 w.r.t to
--              updated TSD.
---------------------------------------------------------------------------------------
-- Mod By: RK
-- Mod Date: 14-Jun-2007
-- Mod Ref: Mod 365a.
-- Mod Details: Added a new field TSL_BASE_ITEM,TSL_PRIM_PACK_IND,TSL_PRICE_MARK_IND,
--              TSL_LAUNCH_BASE_IND in UPDATE_ITEM_MASTER() function.
-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date:    28-Jun-2007
-- Mod Ref:     Mod number. 365b1
-- Mod Details: Cascading the base item RCOM and GROC attributes to its variants.
--             Appeneded TSL_DEFAULT_BASE_RCOM_ATTRIB and TSL_DEFAULT_BASE_GROC_ATTRIB new functions.
------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Mod By:      Rahul Soni
-- Mod Date:    10-Oct-2007
-- Mod Ref:     Mod N22.
-- Mod Details: Added a new field tsl_occ_barcode_auth,tsl_retail_barcode_auth
--              in UPDATE_ITEM_MASTER() function.
---------------------------------------------------------------------------------------

-- Mod By:      Vinod
-- Mod Date:    26-Nov-2007
-- Mod Ref:     Defect # 4189,4190,4191
-- Mod Details: Modified the function UPDATE_ITEM_MASTER to update the appropriate values
--              tsl_occ_barcode_auth,tsl_retail_barcode_auth.

---------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Ramasamy
--Mod Date:    30-Jan-2008
--Mod Ref:     Mod number. N113
--Mod Details: Amended script to explodes the style ref ind information.
------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
--Mod By:      Usha Patil
--Mod Date:    18-Mar-2008
--Mod Ref:     Mod N126.
--Mod Details: Added tsl_deactivate_date in UPDATE_ITEM_MASTER.
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By:      Vijaya Bhaskar
-- Mod Date:    23-May-2008
-- Mod Ref:     Mod N127.
-- Mod Details: Added tsl_range_auth_ind in UPDATE_ITEM_MASTER
-----------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--Author      : Vijaya Bhaskar/Wipro-Enabler,
--Date        : 24-Jul-2008
--Mod Ref     : Defect#:NBS00007788
--Mod Details : Fix done by modifying tsl_range_auth_ind field in UPDATE_ITEM_MASTER function
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--Author      : Vijaya Bhaskar/Wipro-Enabler,
--Date        : 05-Aug-2008
--Mod Ref     : Defect#:NBS00008186
--Mod Details : Fix done by modifying tsl_range_auth_ind field in UPDATE_ITEM_MASTER function
--              if we are not passing any range data, it should accept previous value for
--              tsl_range_auth_ind as in item_master table.
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa
-- Mod Date   : 23-Jul-2008
-- Mod Ref    : N111A.
-- Mod Details: 1.Modified the function UPDATE_ITEM_MASTER to handle two newly added common product
--                fields TSL_COMMON_IND and TSL_PRIMARY_COUNTRY.
--              2.Used NVL functions for the NOT NULL fields.
------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 11-Nov-2008
-- Mod Ref    : N128.
-- Mod Details: Modified the function UPDATE_ITEM_MASTER to handle newly added field tsl_primary_cua.
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 07-Jan-2009
-- Mod Ref    : CR165.
-- Mod Details: Modified the function UPDATE_ITEM_MASTER to handle newly added fields
--              tsl_suspended and tsl_suspend_date.
------------------------------------------------------------------------------------------------------
--Author      : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Date        : 30-Jan-2009
--Mod Ref     : Patch #: 7475459 (Oracle patch number)
--Mod Details : Oracle base defect fix
------------------------------------------------------------------------------------------------
-- Mod By:      Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date:    03-Feb-2009
-- Def Ref:     DefNBS011227
-- Def Details: Modified the function UPDATE_ITEM_MASTER to handle grocery attributes.
------------------------------------------------------------------------------------------------
-- Mod By:      Usha Patil, usha.patil@in.tesco.com
-- Mod Date:    17-Apr-2009
-- Def Ref:     DefNBS012450
-- Def Details: Modified the function UPDATE_ITEM_MASTER to handle tsl_price_marked_except_ind.
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
---Mod By      : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
---Mod Date    : 20-Apr-2009
---Def Ref     : DefNBS012341
---Def Details : Modified the function UPDATE_ITEM_MASTER to allow the updation of item_parent,
--               item_grandparent,status and tsl_consumer_unit fields when the Barcode is moved
--               or exchanged between two Common products.
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
---Mod By      : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
---Mod Date    : 04-May-2009
---Def Ref     : DefNBS012710
---Def Details : Modified the function UPDATE_ITEM_MASTER to use NVL for the NOT NULL field 'Status'
------------------------------------------------------------------------------------------------
---Mod By      : Nitin Kumar, nitin.kumar@in.tesco.com
---Mod Date    : 12-May-2009
---Ref         : Phase  3.3b2 to Phase  3.3b Merge 12-May-2009
-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
---Mod By      : Uday Polimera, Uday.Polimera@in.tesco.com
---Mod Date    : 30-Jul-2009
---Def Ref     : DefNBS014319
---Def Details : Modified the function UPDATE_ITEM_MASTER to update the tsl_base_item with the old value
--               if it is null
------------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 19-Aug-2009
-- Mod Ref    : CR236
-- Def Details: Modified the function UPDATE_ITEM_MASTER to handle newly added column
--              'tsl_range_auth_ind_roi'.
-------------------------------------------------------------------------------------------------
-- Mod By     : Wipro/JK
-- Mod Date   : 25-Aug-2009
-- Mod Ref    : CR236
-- Mod Details: Added a new overloaded function ITEM_ATTIRBUTES to return the country specific record
-------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 23-Oct-2009
-- Mod Ref    : MrgNBS015130
-- Mod Details: Merge 3.4 to 3.5a(Merged DefNBS014398,NBS00014541)
-------------------------------------------------------------------------------------------------------
-- Mod By     : Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
-- Mod Date   : 12-Aug-2008
-- Mod Ref    : DefNBS014398
-- Mod Details: Modified the function ITEM_ATTRIBUTES
-------------------------------------------------------------------------------------------------------
-- Mod By      : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
-- Mod Date    : 20-Aug-2009
-- Def Ref     : NBS00014541
-- Def Details : Modified the function UPDATE_ITEM_MASTER to handle 'uom_conv_factor'.
-------------------------------------------------------------------------------------------------------
---Mod By   : Tarun Kumar Mishra, tarun.mishra@in.tesco.com
---Mod Ref  : NBS00015821
---Mod Date : 29-Dec-2009
---Mod Desc : Updated the function DEFAULT_CHILD_GROC_ATTRIB
-------------------------------------------------------------------------------------------------------
-- Function:    ITEM_ATTIRBUTES
-- Purpose:     Checks to determine if any item attribute records exist for the item
--------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
--Mod By:      Sarayu Gouda sarayu.gouda@in.tesco.com
--Mod Date:    09-Feb-2010
--Mod Ref:     CR288
--Mod Details: Removed the Cr236 code change
-----------------------------------------------------------------------------------------------------
--Mod By:      Chandru, chandrashekaran.natarajan@in.tesco.com
--Mod Date:    16-Apr-2010
--Mod Ref:     CR258
--Mod Details: DEFAULT_CHILD_RCOM_ATTRIB function has been modified to include the CR258 cascading
--             modification
------------------------------------------------------------------------------------------------------
--Mod By:      Sripriya,Sripriya.karanam@in.tesco.com
--Mod Date:    10-May-2010
--Mod Ref:     CR265
--Mod Details: Added TSL_CASCADE_STYLE_REF ,TSL_CASCADE_STYLE_WKSHT to cascade the style reference
--             to item's children based on their status.
------------------------------------------------------------------------------------------------------
---Mod By   : Murali, Usha Patil
---Mod Ref  : CR288b
---Mod Date : 13-May-2010
---Mod Desc : 3 new functions are included: TSL_UPDATE_ITEM_CTRY, TSL_UPDATE_CHILD_ITEM_CTRY and
--            TSL_TPNB_UPDATE_ITEM_CTRY
-------------------------------------------------------------------------------------------------------
---Mod By   : Usha Patil
---Mod Ref  : Def-NBS00017543
---Mod Date : 20-May-2010
---Mod Desc : Modified TSL_UPDATE_ITEM_CTRY to reset the variables in the LOOP.
-------------------------------------------------------------------------------------------------------
---Mod By   : Usha Patil
---Mod Ref  : Def-NBS00017600
---Mod Date : 24-May-2010
---Mod Desc : Modified TSL_UPDATE_ITEM_CTRY revert the fix 17594 and modified C_UPDATE_PACKS cursor.
-------------------------------------------------------------------------------------------------------
---Mod By   : Govindarajan K
---Mod Ref  : DefNBS017594
---Mod Date : 22-May-2010
---Mod Desc : Modified TSL_UPDATE_ITEM_CTRY function.
-------------------------------------------------------------------------------------------------------
---Mod By   : Murali N
---Mod Ref  : NBS00017727
---Mod Date : 28-May-2010
---Mod Desc : Modified TSL_UPDATE_ITEM_CTRY function to update for OCC when updating pack.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Sripriya,Sripriya.karanam@in.tesco.com
-- Mod Date   : 03-Jun-2010
-- Mod Ref    : MrgNBS017783
-- Mod Details: Merge 3.5b to 3.5f
-------------------------------------------------------------------------------------------------------
-- Mod By     : Chandru, chandrashekaran.natarajan@in.tesco.com
-- Mod Date   : 15-Jun-2010
-- Mod Ref    : DefNBS017893
-- Mod Details: 17889 groc attrib cascading fix - DEFAULT_CHILD_GROC_ATTRIB function
--              in DefNBS017893 branch
-------------------------------------------------------------------------------------------------------
---Mod By      : Amita Nandal,amita.nandal@in.tesco.com
---Mod Date    : 09-JUN-2010
---Def Ref     : NBS00017845
---Def Details : Backporting of defNBS017463 which includes modification the function TSL_VALIDATE_STYLE_REF to meet new requirement for style ref field
--               as first two chars alphabet and remaining 6 chars free text for mumeric 0-9.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 18-Jun-2010
-- Mod Ref    : MrgNBS017905(Merge 3.5b to 3.5f).
-- Mod Details: Merged NBS00017845
--------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
--MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
-------------------------------------------------------------------------------------------------------
-- Mod By     : Sripriya,Sripriya.karanam@in.tesco.com
-- Mod Date   : 28-Jul-2010
-- Mod Ref    : CR347.
-- Mod Details: Modified TSL_UPDATE_ITEM_CTRY
--------------------------------------------------------------------------------------------------
-- Mod By     : Nishant Gupta
-- Mod Date   : 2-Aug-2010
-- Mod Ref    : CR288d.
-- Mod Details: Added TSL_GET_AUTH_CTRY function to fetch the auth_ind
--------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 05-Aug-2010
-- Mod Ref    : MrgNBS018606
-- Mod Details: Merged Phase3.5f to 3.5g (CR288C,MrgNBS018360,DefNBS018129,NBS00018237,NBS00018416)
--------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
--MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
-------------------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 08-Jul-2010
-- Mod Ref    : CR288C
-- Mod Details: SI Big Fix
-------------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 09-Jul-2010
-- Mod Ref    : CR288C
-- Mod Details: SI Rollout Changes.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 20-Jul-2010
-- Mod Ref    : MrgNBS018360
-- Mod Details: Merged Def-18129.
--------------------------------------------------------------------------------------------
---Mod By   : Joy Stephen
---Mod Ref  : DefNBS018129
---Mod Date : 01-Jul-2010
---Mod Desc : Modified the function TSL_DEFAULT_BASE_GROC_ATTRIB.
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
---Mod By   : V Manikandan
---Mod Ref  : NBS00018237
---Mod Date : 21-Jul-2010
---Mod Desc : Modified DEFAULT_CHILD_GROC_ATTRIB function to improve the performance.
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
---Mod By   : V Manikandan
---Mod Ref  : NBS00018416
---Mod Date : 23-Jul-2010
---Mod Desc : Modified DEFAULT_CHILD_GROC_ATTRIB function to improve the performance.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 09-Aug-2010
-- Mod Ref    : CR354
-- Mod Details: SI security changes
-------------------------------------------------------------------------------------------------------
--Mod By:      Praveen, praveen.rachaputi@in.tesco.com
--Mod Date:    18-Aug-2010
--Mod Ref:     CR354
--Mod Details: DEFAULT_CHILD_RCOM_ATTRIB function has been modified to include the CR354 Security for cascading
--             modification
------------------------------------------------------------------------------------------------------
--MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com  Begin
--MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
-------------------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 08-Sep-2010
-- Mod Ref    : DefNBS018966
-- Mod Desc   : Added TSL_INCOMPLETE_TPNB function.
-------------------------------------------------------------------------------------------------------
---Mod By   : Grandhi Murali
---Mod Ref  : DefNBS00019116
---Mod Date : 14-Sep-2010
---Mod Desc : Modified TSL_CASCADE_STYLE_REF function to improve the performance.
-------------------------------------------------------------------------------------------------------
--MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Mod By:     : Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date    : 18-Sep-2010
-- Mod Ref     : MrgNBS019219
-- Mod Details : Phase 3.5PrdSi to 3.5b Merge(DefNBS018994).
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Mod By   : Sriranjitha Bhagi
-- Mod Ref  : DefNBS018994
-- Mod Date : 02-Sep-2010
-- Mod Desc : Modified TSL_GET_CHILD_ITEMS  function to
--           (i) Remove Barcodes - there is no validation required
--           (ii)Remove other rows which will have no validation - TPND(simple pack): RANGE, TPND :
--               SUPPLY CHAIN
-------------------------------------------------------------------------------------------------------
-- Mod By:     : Sanju Natarajan, Sanju.Natarajan@in.tesco.com
-- Mod Date    : 12-Dec-2010
-- Mod Ref     : CR259
-- Mod Details : Overloaded function DEFAULT_CHILD_GROC_ATTRIB , added one more parameter
-------------------------------------------------------------------------------------------------------
--MrgNBS019220,19-Sep-2010,(mrg 3.5f3 to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com  End
-------------------------------------------------------------------------------------------------------------
--Mod By:      Parvesh, parveshkumar.rulhan@in.tesco.com Begin
--Mod Date:    1-Dec-2010
--Mod Ref:     CR304
--Mod Details: Modified UPDATE_ITEM_MASTER function to set tsl_ignr_deact_rule column value.
----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------
--Mod by   : Ravi Nagaraju, ravi.nagaraju@in.tesco.com
--Mod date : 25-Dec-2010
--Mod ref. : MrgNBS020155,Merged phase 3.5b to 3.5h
---------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--Mod By:      Parvesh,parveshkumar.rulhan@in.tesco.com
--Mod Date:    23-Nov-2010
--Mod Ref:     CR363
--Mod Details: Added TSL_INCOMPLETE_CHILD function.
------------------------------------------------------------------------------------------------------
--Mod By     : Vinutha Raju, Vinutha.Raju@in.tesco.com
--Mod Date   : 21-Dec-2010
--Mod Ref    : PrfNBS020199
--Mod Details: Altered the query C_GET_TPN as part of performance issue on click of approval link
------------------------------------------------------------------------------------------------------
--Mod by     : Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com
--Mod date   : 25-Jan-2011
--Mod ref.   : CR259/NBS00020661
--Mod Details: Added one more parameter I_catch_weight_ind for catch_weight_ind
--             in overloaded function DEFAULT_CHILD_GROC_ATTRIB
------------------------------------------------------------------------------------------------------
--Mod By     : Veena Nanjundaiah,veena.nanjundaiah@in.tesco.com
--Mod Date   : 30-Mar-2011
--Mod Ref    : DefNBS022155a
--Mod Details: Created New function to check whether base desc 3 field should be enabled or disabled
------------------------------------------------------------------------------------------------------
-- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com Begin
------------------------------------------------------------------------------------------------------
--Mod by     : Accenture/Iman Chatterjee, iman.chatterjee@in.tesco.com
--Mod date   : 04-Mar-2011
--Mod ref.   : CR381
------------------------------------------------------------------------------------------------------
--Mod by     : Suman Guha Mustafi, suman.mustafi@in.tesco.com
--Mod date   : 28-Mar-2011
--Mod ref.   : Fixed Defect DefNBS022105
------------------------------------------------------------------------------------------------------
--Mod by     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
--Mod date   : 31-Mar-2011
--Mod ref.   : Fixed Defect DefNBS022142
------------------------------------------------------------------------------------------------------
--Mod by     : Vinutha Raju, Vinutha.raju@in.tesco.com
--Mod date   : 15-Apr-2011
--Mod ref.   : Fixed Defect DefNBS022347
------------------------------------------------------------------------------------------------------
-- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com End
------------------------------------------------------------------------------------------------------
--Mod By     : Deepak Gupta, deepak.c.gupta@in.tesco.com
--Mod Date   : 06-Jun-2011
--Mod Ref    : CR416
--Mod Details: Created New functions to get EAN, OCC and TPND
------------------------------------------------------------------------------------------------------
--Mod by     : Gareth Jones
--Mod date   : 13-Jun-2011
--Mod ref.   : PrfNBS022544 - amended function TSL_UPDATE_CHILD_ITEM_CTRY, cursor C_GET_CHILDREN_PACK
--             to remove OR statements and replace with UNION ALLs, for performance improvement.
------------------------------------------------------------------------------------------------------
-- Mod By     : Suman Guha Mustafi, suman.mustafi@in.tesco.com
-- Mod Date   : 23-June-2011
-- Mod Ref    : DefNBS023046(NBS00023046)
-- Mod Details: Record lock exception added in TSL_CASCADE_STYLE_REF(),TSL_CASCADE_STYLE_WKSHT(),
--            : TSL_UPD_ITEM_SUPP() and TSL_CASCADE_OWNER_CTRY().
-------------------------------------------------------------------------------------------------------------
-- MrgNBS023522 06-Sep-2011 chithraprabha.v, chitraprabha.vadakkedath@in.tesco.com Begin
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 02-Aug-2011
-- Mod Ref    : CR396
-- Mod Details: Modified the function UPDATE_ITEM_MASTER to update the Diffs value.
-- MrgNBS023522 06-Sep-2011 chithraprabha.v, chitraprabha.vadakkedath@in.tesco.com End
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Shweta Madnawat, shweta.madnawat@in.tesco.com
-- Mod Date   : 08-Jul-2011
-- Mod Ref    : DefNBS023195
-- Mod Details: Modified the function tsl_update_item_ctry to cascade the value of auth ind
--              for children of variant items.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com
-- Mod Date   : 13-Jul-2011
-- Mod Ref    : DefNBS023195a
-- Mod Details: Changing based on code review for DefNBS023195
-------------------------------------------------------------------------------------------------------------
--MrgNBS023522 06-Sep-2011 chithraprabha, chitraprabha.v@in.tesco.com Begin
--Mod by     : Gurutej.K, gurutej.kunjibettu@in.tesco.com
--Mod date   : 11-Aug-2011
--Mod        : MrgNBS023381
--Mod ref    : Merge from PrdSi to 3.5b(DefNBS023195 and DefNBS023195a)
--MrgNBS023522 06-Sep-2011 chithraprabha, chitraprabha.v@in.tesco.com End
-------------------------------------------------------------
--Mod By     : Shweta Madnawat shweta.madnawat@in.tesco.com
--Mod Date   : 20-Oct-2011
--Mod Ref    : CR434
--Mod Details: Created a new function to cascade the value of restrict price event indicator from
--             TPNA to TPNBs.
------------------------------------------------------------------------------------------------------
--Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
--Mod Date   : 07-Dec-2011
--Mod Ref    : DefNBS024002
--Mod Details: Modified function TSL_CASCADE_RESTRICT_PCEV as per design change.
------------------------------------------------------------------------------------------------------
--Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
--Mod Date   : 30-Dec-2011
--Mod Ref    : DefNBS024052
--Mod Details: Modified function TSL_CASCADE_RESTRICT_PCEV to update the LAST_UPDATE_ID column
--             of ITEM_MASTER table.
------------------------------------------------------------------------------------------------------
FUNCTION ITEM_ATTRIBUTES (O_error_message  IN OUT    VARCHAR2,
                          O_exist          IN OUT    BOOLEAN,
                          I_item           IN        ITEM_MASTER.ITEM%TYPE)
         RETURN BOOLEAN IS

   L_program        VARCHAR2(60) := 'ITEM_MASTER_SQL.ITEM_ATTRIBUTES';
   L_record_exists  VARCHAR2(1) := 'N';
   -- UAT NBS00014308, 07-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   L_dept           ITEM_MASTER.DEPT%TYPE;
   L_class          ITEM_MASTER.CLASS%TYPE;
   L_subclass       ITEM_MASTER.SUBCLASS%TYPE;
   L_item_level     ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_ia_info        MERCH_DEFAULT_SQL.TSL_IA_TBL;
   L_exists_base    VARCHAR2(1);
   L_exists_sel     VARCHAR2(1);
   L_exists_till    VARCHAR2(1);
   L_exists_pack    VARCHAR2(1);
   L_exists_iss     VARCHAR2(1);
   L_exists_episel  VARCHAR2(1);
   L_exist_var      BOOLEAN := FALSE;
   L_exist_base     BOOLEAN := FALSE;
   L_item_type      VARCHAR2(1);
   -- UAT NBS00014308, 07-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
   -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  Begin
   -- DefNBS014398, 12-Aug-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
   L_pack_ind       VARCHAR2(1);
   -- DefNBS014398, 12-Aug-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
   -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  End
----------------------------------------------------------------------------
-- To include the Item Descriptions also to ensure proper functioning of the
-- Item atributes link on the Item Master Screen
-- NBS004602, 16-Jan-2008, John Alister Anand, BEGIN
----------------------------------------------------------------------------
   cursor C_ITEM_ATTRIBUTES is
   select 'Y'
    from item_attributes
    where item = I_item
     and ROWNUM = 1
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
-- NBS004602, 16-Jan-2008, John Alister Anand, END
   -- UAT NBS00014308, 07-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   CURSOR C_GET_ITEM_INFO is
   select im.dept,
          im.class,
          im.subclass,
          im.item_level,
          -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  Begin
          -- DefNBS014398, 12-Aug-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
          im.pack_ind
          -- DefNBS014398, 12-Aug-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
          -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  End
     from item_master im
    where im.item = I_item;
   -- UAT NBS00014308, 07-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
BEGIN

   open C_ITEM_ATTRIBUTES;
   fetch C_ITEM_ATTRIBUTES into L_record_exists;
   close C_ITEM_ATTRIBUTES;
   ---
   if L_record_exists = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   -- UAT NBS00014308, 07-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   --
   if TSL_BASE_VARIANT_SQL.VALIDATE_BASE_ITEM(O_error_message,
                                              L_exist_base,
                                              I_item)= FALSE then
      return FALSE;
   end if;
   if L_exist_base then
      L_item_type := 'B';
   end if;
   --
   if TSL_BASE_VARIANT_SQL.VALIDATE_VARIANT_ITEM(O_error_message,
                                                 L_exist_var,
                                                 I_item)= FALSE then
      return FALSE;
   end if;
   if L_exist_var then
      L_item_type := 'V';
   end if;
   --
   if L_exist_var or L_exist_base then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||(I_item));
      open C_GET_ITEM_INFO;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||(I_item));
      fetch C_GET_ITEM_INFO into L_dept, L_class, L_subclass, L_item_level,
                                 -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  Begin
                                 -- DefNBS014398, 12-Aug-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
                                 L_pack_ind;
                                 -- DefNBS014398, 12-Aug-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
                                 -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  End
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||(I_item));
      close C_GET_ITEM_INFO;
      --
      -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  Begin
      -- DefNBS014398, 12-Aug-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
      if L_pack_ind ='Y' then
         L_item_type := 'P';
      end if;
      -- DefNBS014398, 12-Aug-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
      -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  End
      if NOT MERCH_DEFAULT_SQL.TSL_GET_REQ_INDS(O_error_message,
                                                L_ia_info,
                                                L_dept,
                                                L_class,
                                                L_subclass,
                                                L_item_level,
                                                L_item_type,
                                                'Y') then
         return FALSE;
      end if;
      --
      if L_ia_info.EXISTS(1) then
         --
         if NOT TSL_ITEMDESC_SQL.ITEMDESC_EXISTS(O_error_message,
                                                 I_item,
                                                 L_exists_base,
                                                 L_exists_sel,
                                                 L_exists_till,
                                                 L_exists_pack,
                                                 L_exists_iss,
                                                 L_exists_episel
                                                 ) then
            return FALSE;
         end if;
         --
         for i in 1..L_ia_info.COUNT()
         LOOP
            if L_ia_info(i) = 'BASE' and L_exists_base = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'SEL' and L_exists_sel = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'TILL' and L_exists_till = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'PACK' and L_exists_pack = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'ISS' and L_exists_iss = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'EPISEL' and L_exists_episel = 'Y' then
               O_exist := TRUE;
            else
               if L_ia_info(i) in ('BASE', 'SEL', 'TILL', 'PACK', 'ISS', 'EPISEL') then
                  O_exist := FALSE;
                  exit;
               end if;
            end if;
         END LOOP;
         --
      end if;
   end if;
   -- UAT NBS00014308, 07-Aug-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
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
END ITEM_ATTRIBUTES;
--------------------------------------------------------------------------------------------------------
--25-Aug-2009     Wipro/JK    CR236   Begin
--------------------------------------------------------------------------------------------------------
-- Function:    ITEM_ATTIRBUTES
-- Purpose:     Checks to determine if any item attribute records exist for the item and the country
--------------------------------------------------------------------------------------------------------
FUNCTION ITEM_ATTRIBUTES (O_error_message  IN OUT    VARCHAR2,
                          O_exist          IN OUT    BOOLEAN,
                          I_item           IN        ITEM_MASTER.ITEM%TYPE,
                          I_country        IN        VARCHAR2)
   return BOOLEAN is

   L_program        VARCHAR2(60) := 'ITEM_MASTER_SQL.ITEM_ATTRIBUTES';
   L_record_exists  VARCHAR2(1) := 'N';
   L_dept           ITEM_MASTER.DEPT%TYPE;
   L_class          ITEM_MASTER.CLASS%TYPE;
   L_subclass       ITEM_MASTER.SUBCLASS%TYPE;
   L_item_level     ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_ia_info        MERCH_DEFAULT_SQL.TSL_IA_TBL;
   L_exists_base    VARCHAR2(1);
   L_exists_sel     VARCHAR2(1);
   L_exists_till    VARCHAR2(1);
   L_exists_pack    VARCHAR2(1);
   L_exists_iss     VARCHAR2(1);
   L_exists_episel  VARCHAR2(1);
   L_exist_var      BOOLEAN := FALSE;
   L_exist_base     BOOLEAN := FALSE;
   L_item_type      VARCHAR2(1);

   cursor C_ITEM_ATTRIBUTES is
      select 'Y'
        from item_attributes
       where item = I_item
         and tsl_country_id = I_country
         and ROWNUM = 1;
        --CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 18-Feb-2010 Begin
        --Commented the below code as it is no longer required
       /*UNION
       select 'Y'
         from tsl_itemdesc_base
        where item = I_item
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
          --and tsl_country_id = I_country
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com End
          and ROWNUM = 1
       UNION
       select 'Y'
         from tsl_itemdesc_episel
        where item = I_item
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
          --and tsl_country_id = I_country
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com End
          and ROWNUM = 1
       UNION
       select 'Y'
         from tsl_itemdesc_iss
        where item = I_item
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
          --and tsl_country_id = I_country
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com End
          and ROWNUM = 1
       UNION
       select 'Y'
         from tsl_itemdesc_pack
        where pack_no = I_item
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
          --and tsl_country_id = I_country
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com End
          and ROWNUM = 1
       UNION
       select 'Y'
         from tsl_itemdesc_sel
        where item = I_item
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
          --and tsl_country_id = I_country
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com End
          and ROWNUM = 1
       UNION
       select 'Y'
         from tsl_itemdesc_till
        where item = I_item
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
          --and tsl_country_id = I_country
          --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com End
          and ROWNUM = 1;*/

   CURSOR C_GET_ITEM_INFO is
      select im.dept,
             im.class,
             im.subclass,
             im.item_level
        from item_master im
       where im.item = I_item;
BEGIN

   open C_ITEM_ATTRIBUTES;
   fetch C_ITEM_ATTRIBUTES into L_record_exists;
   close C_ITEM_ATTRIBUTES;
   ---
   if L_record_exists = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   ---CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 25-Feb-2010 Begin
   /*if TSL_BASE_VARIANT_SQL.VALIDATE_BASE_ITEM(O_error_message,
                                              L_exist_base,
                                              I_item)= FALSE then
      return FALSE;
   end if;
   if L_exist_base then
      L_item_type := 'B';
   end if;
   --
   if TSL_BASE_VARIANT_SQL.VALIDATE_VARIANT_ITEM(O_error_message,
                                                 L_exist_var,
                                                 I_item)= FALSE then
      return FALSE;
   end if;
   if L_exist_var then
      L_item_type := 'V';
   end if;
   --
   if L_exist_var or L_exist_base then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||(I_item));
      open C_GET_ITEM_INFO;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||(I_item));
      fetch C_GET_ITEM_INFO into L_dept, L_class, L_subclass, L_item_level;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_INFO',
                       'ITEM_MASTER',
                       'Item: '||(I_item));
      close C_GET_ITEM_INFO;
      --
      if NOT MERCH_DEFAULT_SQL.TSL_GET_REQ_INDS(O_error_message,
                                                L_ia_info,
                                                L_dept,
                                                L_class,
                                                L_subclass,
                                                L_item_level,
                                                L_item_type,
                                                'Y') then
         return FALSE;
      end if;
      --
      if L_ia_info.EXISTS(1) then
         --
         if NOT TSL_ITEMDESC_SQL.ITEMDESC_EXISTS(O_error_message,
                                                 I_item,
                                                 --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com Begin
                                                 -- Removed the CR236 code change
                                                 --CR288 09-Feb-2009 Sarayu Gouda sarayu.gouda@in.tesco.com End
                                                 L_exists_base,
                                                 L_exists_sel,
                                                 L_exists_till,
                                                 L_exists_pack,
                                                 L_exists_iss,
                                                 L_exists_episel) then

            return FALSE;
         end if;
         --
         for i in 1..L_ia_info.COUNT()
         LOOP
            if L_ia_info(i) = 'BASE' and L_exists_base = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'SEL' and L_exists_sel = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'TILL' and L_exists_till = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'PACK' and L_exists_pack = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'ISS' and L_exists_iss = 'Y' then
               O_exist := TRUE;
            elsif L_ia_info(i) = 'EPISEL' and L_exists_episel = 'Y' then
               O_exist := TRUE;
            else
               if L_ia_info(i) in ('BASE', 'SEL', 'TILL', 'PACK', 'ISS', 'EPISEL') then
                  O_exist := FALSE;
                  exit;
               end if;
            end if;
         END LOOP;
         --
      end if;
   end if;*/
   --CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 25-Feb-2010 End

   return TRUE;
   ---
EXCEPTION
 when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_ATTRIBUTES;
--25-Aug-2009     Wipro/JK    CR236   End
-------------------------------------------------------------------
-- Function:    VAT_ITEM
-- Purpose:     Checks to determine if any vat_item records exist for the item
-------------------------------------------------------------------
FUNCTION VAT_ITEM (O_error_message  IN OUT    VARCHAR2,
                   O_exist          IN OUT    BOOLEAN,
                   I_ITEM           IN        ITEM_MASTER.ITEM%TYPE)
         RETURN BOOLEAN IS

   L_program        VARCHAR2(60) := 'ITEM_MASTER_SQL.VAT_ITEM';
   L_record_exists  VARCHAR2(1) := 'N';
   cursor C_VAT_ITEM is
      select 'Y'
         from vat_item
        where item = I_item;
BEGIN

   open C_VAT_ITEM;
   fetch C_VAT_ITEM into L_record_exists;
   close C_VAT_ITEM;
   ---
   if L_record_exists = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
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
END VAT_ITEM;
-------------------------------------------------------------------
-- Function:    ITEM_IMAGE
-- Purpose:     Checks to determine if any item image records exist for the item
-------------------------------------------------------------------
FUNCTION ITEM_IMAGE (O_error_message  IN OUT    VARCHAR2,
                   O_exist          IN OUT    BOOLEAN,
                   I_ITEM           IN        ITEM_MASTER.ITEM%TYPE)
         RETURN BOOLEAN IS

   L_program        VARCHAR2(60) := 'ITEM_MASTER_SQL.ITEM_IMAGE';
   L_record_exists  VARCHAR2(1) := 'N';
   cursor C_ITEM_IMAGE is
      select 'Y'
         from item_image
        where item = I_item
   and ROWNUM = 1;
BEGIN

   open C_ITEM_IMAGE;
   fetch C_ITEM_IMAGE into L_record_exists;
   close C_ITEM_IMAGE;
   ---
   if L_record_exists = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
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
END ITEM_IMAGE;
-------------------------------------------------------------------
FUNCTION DEFAULT_CHILD_RETAIL_ZONE(O_error_message   IN OUT VARCHAR2,
                                   I_new_retail_zone IN     ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                                   I_item            IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_table       VARCHAR2(30) := 'ITEM_MASTER';
   L_program     VARCHAR2(60) := 'ITEM_MASTER_SQL.DEFAULT_CHILD_RETAIL_ZONE';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_CHILDREN is
      select 'x'
        from item_master
       where item_parent = I_item
          or item_grandparent = I_item
             for update nowait;

BEGIN

   if I_new_retail_zone is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_new_retail_zone',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   open C_LOCK_CHILDREN;
   close C_LOCK_CHILDREN;

   update item_master
      set retail_zone_group_id = I_new_retail_zone
    where item_parent = I_item
       or item_grandparent = I_item;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END DEFAULT_CHILD_RETAIL_ZONE;
-------------------------------------------------------------------
FUNCTION DEFAULT_CHILD_COST_ZONE(O_error_message IN OUT VARCHAR2,
                                 I_new_cost_zone IN     ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE,
                                 I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_table       VARCHAR2(30) := 'ITEM_MASTER';
   L_program     VARCHAR2(60) := 'ITEM_MASTER_SQL.DEFAULT_CHILD_COST_ZONE';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_CHILDREN is
      select 'x'
        from item_master
       where item_parent = I_item
          or item_grandparent = I_item
             for update nowait;

BEGIN

   if I_new_cost_zone is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_new_cost_zone',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   open C_LOCK_CHILDREN;
   close C_LOCK_CHILDREN;

   update item_master
      set cost_zone_group_id = I_new_cost_zone
    where item_parent = I_item
       or item_grandparent = I_item;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END DEFAULT_CHILD_COST_ZONE;
-------------------------------------------------------------------
FUNCTION UPDATE_PRIMARY_REF_ITEM_IND(O_error_message    IN OUT VARCHAR2,
                                     I_item_parent      IN     ITEM_MASTER.ITEM%TYPE,
                                     I_item             IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program          VARCHAR2(100) := 'ITEM_MASTER_SQL.UPDATE_PRIMARY_REF_ITEM_IND';
   L_table            VARCHAR2(30)  := 'ITEM_MASTER';
   RECORD_LOCKED      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_RECS is
      select 'x'
        from item_master im
       where im.item                 != I_item
         and im.item_parent           = I_item_parent
         and im.primary_ref_item_ind  = 'Y'
         and im.item_level > im.tran_level
       for update nowait;

BEGIN

   if I_item_parent is NULL
      or I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',
                                             L_program,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   open C_LOCK_RECS;
   close C_LOCK_RECS;
   ---
   update item_master im
      set im.primary_ref_item_ind  = 'N',
          im.last_update_id = user,
          im.last_update_datetime = sysdate
    where im.item                 != I_item
      and im.item_parent           = I_item_parent
      and im.primary_ref_item_ind  = 'Y'
      and im.item_level > im.tran_level;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END UPDATE_PRIMARY_REF_ITEM_IND;
--------------------------------------------------------------------
-- Function:   DEFAULT_CHILD_GROC_ATTRIB
-- Purpose: Defaults grocery attributes to all of an item's children.
-----------------------------------------------------------------------
FUNCTION DEFAULT_CHILD_GROC_ATTRIB(O_error_message            IN OUT VARCHAR2,
                                   I_item                     IN ITEM_MASTER.ITEM%TYPE,
                                   I_package_size             IN ITEM_MASTER.PACKAGE_SIZE%TYPE,
                                   I_package_uom              IN ITEM_MASTER.PACKAGE_UOM%TYPE,
                                   I_retail_label_type        IN ITEM_MASTER.RETAIL_LABEL_TYPE%TYPE,
                                   I_retail_label_value       IN ITEM_MASTER.RETAIL_LABEL_VALUE%TYPE,
                                   I_handling_sensitivity     IN ITEM_MASTER.HANDLING_SENSITIVITY%TYPE,
                                   I_handling_temp            IN ITEM_MASTER.HANDLING_TEMP%TYPE,
                                   I_waste_type               IN ITEM_MASTER.WASTE_TYPE%TYPE,
                                   I_default_waste_pct        IN ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE,
                                   I_waste_pct                IN ITEM_MASTER.WASTE_PCT%TYPE,
                                   I_container_item           IN ITEM_MASTER.CONTAINER_ITEM%TYPE,
                                   I_deposit_in_price_per_uom IN ITEM_MASTER.DEPOSIT_IN_PRICE_PER_UOM%TYPE,
                                   I_sale_type                IN ITEM_MASTER.SALE_TYPE%TYPE,
                                   I_order_type               IN ITEM_MASTER.ORDER_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(60) := 'ITEM_MASTER_SQL.DEFAULT_CHILD_GROC_ATTRIB';
   L_table        VARCHAR2(65):= 'ITEM_MASTER';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);
   --CR354 18-Aug-10 Praveen Begin
   L_tsl_loc_sec_ind   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
   L_owner_cntry   SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
   --CR354 18-Aug-10 Praveen End
   --DefNBS015821 Tarun Kumar Mishra tarun.mishra@in.tesco.com 23-Dec-2009 Begin
   L_cw_ind       ITEM_MASTER.CATCH_WEIGHT_IND%TYPE;
   --DefNBS015821 Tarun Kumar Mishra tarun.mishra@in.tesco.com 23-Dec-2009 End
   -------------------------------------------------------------------------------------------------------
   --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
   -------------------------------------------------------------------------------------------------------
   -- 05-Aug-2010 Tesco HSC/Usha Patil                MrgNBS018606 Begin
   --PrfNBS018237 Manikandan -- manikandan.varadhan@in.tesco.com  21-Jul-2010 Begin
   -- Below code has removed
   --PrfNBS018237 Manikandan -- manikandan.varadhan@in.tesco.com  21-Jul-2010 End
   --PrfNBS018416 Manikandan -- manikandan.varadhan@in.tesco.com  23-Jul-2010 Begin
   cursor C_LOCK_ITEM_MASTER is
      select im.item
       from item_master im
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            start with im2.item            = I_item
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   -- CR354 18-Aug-2010 Praveen Begin
         and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry))
   -- CR354 18-Aug-2010 Praveen End
   for update nowait;

   cursor C_LOCKT_ITEM_MASTER is
      select item
        from item_master im
       start with im.item = I_item
       connect by prior im.item = im.item_parent
       for update nowait;
  --PrfNBS018416 Manikandan -- manikandan.varadhan@in.tesco.com  23-Jul-2010 End
  -- 05-Aug-2010 Tesco HSC/Usha Patil                MrgNBS018606 End
  -------------------------------------------------------------------------------------------------------
--MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
-------------------------------------------------------------------------------------------------------

   cursor C_UPDATED_CONTAINER_ITEM is
      select item
        from item_master
       where (item_parent = I_item
          or item_grandparent = I_item)
         and item_level <= tran_level
         and NVL(container_item,'x') != NVL(I_container_item,'x');

   --DefNBS015821 Tarun Kumar Mishra tarun.mishra@in.tesco.com 23-Dec-2009 Begin
   cursor C_GET_CW_IND is
      select im.catch_weight_ind
        from item_master im
       where im.item = I_item;
   --DefNBS015821 Tarun Kumar Mishra tarun.mishra@in.tesco.com 23-Dec-2009 End

BEGIN
   --PrfNBS018237 Manikandan -- manikandan.varadhan@in.tesco.com  21-Jul-2010 Begin
   -- Below code has removed
   --PrfNBS018237 Manikandan -- manikandan.varadhan@in.tesco.com  21-Jul-2010 End
   --CR354 16-Aug-10 Praveen Begin
   if SYSTEM_OPTIONS_SQL.TSL_GET_LOC_SEC_IND (O_error_message,
                                              L_tsl_loc_sec_ind) = FALSE then
         return FALSE;
   end if;

   if ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY (O_error_message,
                                             L_owner_cntry,
                                             I_item) = FALSE then
      return FALSE;
   end if;
   --CR354 16-Aug-10 Praveen End
   --PrfNBS018416 Manikandan -- manikandan.varadhan@in.tesco.com  23-Jul-2010 Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ITEM_MASTER',
                    L_table,
                    'Item: '||I_item);
   open C_LOCK_ITEM_MASTER;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ITEM_MASTER',
                    L_table,
                    'Item: '||I_item);
   close C_LOCK_ITEM_MASTER;

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCKT_ITEM_MASTER',
                    L_table,
                    'Item: '||I_item);
   open C_LOCKT_ITEM_MASTER;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCKT_ITEM_MASTER',
                    L_table,
                    'Item: '||I_item);
   close C_LOCKT_ITEM_MASTER;
   --PrfNBS018416 Manikandan -- manikandan.varadhan@in.tesco.com  23-Jul-2010 End
   ---
   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    L_table,
                    'Item: '||I_item);
   for chg in C_UPDATED_CONTAINER_ITEM loop
      if not POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                             65,
                                              chg.item,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL) then

         return FALSE;
      end if;
   end loop;

   --PrfNBS018237 Manikandan -- manikandan.varadhan@in.tesco.com  21-Jul-2010 Begin
   --PrfNBS018416 Manikandan -- manikandan.varadhan@in.tesco.com  23-Jul-2010 Begin
   update item_master im
      set package_size = I_package_size,
          package_uom = I_package_uom ,
          retail_label_type = I_retail_label_type,
          retail_label_value = I_retail_label_value,
          handling_sensitivity = I_handling_sensitivity,
          handling_temp = I_handling_temp,
          waste_type = I_waste_type,
          default_waste_pct = I_default_waste_pct,
          waste_pct = I_waste_pct,
          container_item = I_container_item,
          deposit_in_price_per_uom = I_deposit_in_price_per_uom,
          order_type = I_order_type,
          sale_type = I_sale_type
    where item in (select im.item
     from item_master im
    start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            start with im2.item            = I_item
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   -- CR354 18-Aug-2010 Praveen Begin
   and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry))
   -- CR354 18-Aug-2010 Praveen End
   union all
   select item
     from item_master im
    start with im.item = I_item
   connect by prior im.item = im.item_parent
   -- CR354 18-Aug-2010 Praveen Begin
   and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry)));
   -- CR354 18-Aug-2010 Praveen End
   --PrfNBS018416 Manikandan -- manikandan.varadhan@in.tesco.com  23-Jul-2010 End
      -- and item_level <= tran_level;
      --DefNBS017893 (NBS00017889) 15-Jun-2010 Chandru End
       --CR258 16-Apr-10 Chandru End
   --PrfNBS018237 Manikandan -- manikandan.varadhan@in.tesco.com  21-Jul-2010 End

   --DefNBS015821 Tarun Kumar Mishra tarun.mishra@in.tesco.com 23-Dec-2009 Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CW_IND',
                    L_table,
                   'Item: '||I_item);
   open  C_GET_CW_IND;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_CW_IND',
                    L_table,
                    'I_item: '||I_item);
   fetch C_GET_CW_IND into L_cw_ind;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CW_IND',
                    L_table,
                    'Item: '||I_item);
   close C_GET_CW_IND;
   --DefNBS015821 Tarun Kumar Mishra tarun.mishra@in.tesco.com 23-Dec-2009 End

   -- 7475459, Oracle base fix, Govindarajan K, 30-Jan-2009, Begin
   --DefNBS015821 Tarun Kumar Mishra tarun.mishra@in.tesco.com 23-Dec-2009 Begin
   --Changed the set condition to take parent catch_weight_ind
    --PrfNBS018237 Manikandan -- manikandan.varadhan@in.tesco.com  21-Jul-2010 Begin
    --PrfNBS018416 Manikandan -- manikandan.varadhan@in.tesco.com  23-Jul-2010 Begin
    update item_master im
       set catch_weight_ind = L_cw_ind
     where item in (select im.item
      from item_master im
     start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            start with im2.item            = I_item
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   -- CR354 18-Aug-2010 Praveen Begin
   and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry))
   -- CR354 18-Aug-2010 Praveen End
   union all
   select item
     from item_master im
    start with im.item = I_item
   connect by prior im.item = im.item_parent
   -- CR354 18-Aug-2010 Praveen Begin
   and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry)));
   -- CR354 18-Aug-2010 Praveen End

       --PrfNBS018416 Manikandan -- manikandan.varadhan@in.tesco.com  23-Jul-2010 End
       --PrfNBS018237 Manikandan -- manikandan.varadhan@in.tesco.com  21-Jul-2010 End
       -- DefNBS017893 (NBS00017889) 15-Jun-2010 Chandru End
       --CR258 16-Apr-10 Chandru End
       --DefNBS015821 Tarun Kumar Mishra tarun.mishra@in.tesco.com 23-Dec-2009 Begin
       --and exists (select 'X'
       --              from item_master
       --             where item = I_ITEM
       --                and catch_weight_ind = 'Y');
       --DefNBS015821 Tarun Kumar Mishra tarun.mishra@in.tesco.com 23-Dec-2009 End
   -- 7475459, Oracle base fix, Govindarajan K, 30-Jan-2009, End

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEFAULT_CHILD_GROC_ATTRIB;
-----------------------------------------------------------------------
-- Function:   DEFAULT_CHILD_RCOM_ATTRIB
-- Purpose: Defaults RCOM attributes to all of an item's children.
-----------------------------------------------------------------------
FUNCTION DEFAULT_CHILD_RCOM_ATTRIB(O_error_message      IN OUT VARCHAR2,
                                   I_item               IN     ITEM_MASTER.ITEM%TYPE,
                                   I_item_service_level IN     ITEM_MASTER.ITEM_SERVICE_LEVEL%TYPE,
                                   I_gift_wrap_ind      IN     ITEM_MASTER.GIFT_WRAP_IND%TYPE,
                                   I_ship_alone_ind     IN     ITEM_MASTER.SHIP_ALONE_IND%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(60) := 'ITEM_MASTER_SQL.DEFAULT_CHILD_RCOM_ATTRIB';
   L_table        VARCHAR2(65) := 'ITEM_MASTER';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_MASTER is
      select 'x'
        from item_master
       where (item_parent = I_item
          or item_grandparent = I_item)
         and item_level <= tran_level
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ITEM_MASTER',
                    L_table,
                    'Item: '||I_item);
   open C_LOCK_ITEM_MASTER;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ITEM_MASTER',
                    L_table,
                    'Item: '||I_item);
   close C_LOCK_ITEM_MASTER;
   ---
   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    L_table,
                    'Item: '||I_item);
   update item_master
      set item_service_level = I_item_service_level,
          gift_wrap_ind = I_gift_wrap_ind,
          ship_alone_ind = I_ship_alone_ind
    where (item_parent = I_item
       or item_grandparent  = I_item)
      and item_level <= tran_level;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END DEFAULT_CHILD_RCOM_ATTRIB;
-----------------------------------------------------------------------
-- Function:   UPDATE_CHECK_UDA_IND
-- Purpose: Sets the item_master.check_uda_ind = Y.
--              Called when users click OK on the itemuda form for the
--              first time.
-----------------------------------------------------------------------
FUNCTION UPDATE_CHECK_UDA_IND(O_error_message      IN OUT VARCHAR2,
                              I_item               IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(60) := 'ITEM_MASTER_SQL.UPDATE_CHECK_UDA_IND';
   L_table        VARCHAR2(65) := 'ITEM_MASTER';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_MASTER is
      select 'x'
        from item_master
       where item = I_item
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ITEM_MASTER',
                    L_table,
                    'Item: '||I_item);
   open C_LOCK_ITEM_MASTER;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ITEM_MASTER',
                    L_table,
                    'Item: '||I_item);
   close C_LOCK_ITEM_MASTER;
   ---
   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    L_table,
                    'Item: '||I_item);
   update item_master
      set check_uda_ind = 'Y'
    where item = I_item;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_CHECK_UDA_IND;
-------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_ITEM_MASTER(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_item_rec      IN ITEM_MASTER%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_MASTER_SQL.UPDATE_ITEM_MASTER';

BEGIN
   if not LOCK_ITEM_MASTER(O_error_message,
                           I_item_rec.item) then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_MASTER','item: '||I_item_rec.item);

   update item_master
          --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    Begin
      set item_desc = NVL(I_item_rec.item_desc,item_desc),
          short_desc = NVL(I_item_rec.short_desc,short_desc),
          desc_up = NVL(upper(I_item_rec.item_desc),upper(item_desc)),
          store_ord_mult = NVL( I_item_rec.store_ord_mult,store_ord_mult),
          forecast_ind = NVL(I_item_rec.forecast_ind,forecast_ind),
          --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    End
          comments = I_item_rec.comments,
          last_update_id = I_item_rec.last_update_id,
          last_update_datetime = sysdate,
          --14-Jun-2007 WiproEnabler/RK        Mod:365a Begin
          --30-Jul-2009 Tesco HSC/Uday Polimera   DefNBS014319 Begin
          tsl_base_item = NVL(I_item_rec.tsl_base_item,tsl_base_item),
          --30-Jul-2009 Tesco HSC/Uday Polimera   DefNBS014319 End
          --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    Begin
          tsl_price_mark_ind = NVL(I_item_rec.tsl_price_mark_ind,tsl_price_mark_ind),
          tsl_prim_pack_ind = NVL(I_item_rec.tsl_prim_pack_ind,tsl_prim_pack_ind),
          tsl_launch_base_ind = NVL(I_item_rec.tsl_launch_base_ind,tsl_launch_base_ind),
          --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    End
          --14-Jun-2007 WiproEnabler/RK        Mod:365a End
          --10-Oct-2007 TESCO HSC/Rahul Soni   Mod:N22 Begin
          --tsl_occ_barcode_auth = I_item_rec.tsl_retail_barcode_auth,
          --tsl_retail_barcode_auth = I_item_rec.tsl_occ_barcode_auth
          --10-Oct-2007 TESCO HSC/Rahul Soni   Mod:N22 End

          --26-Nov-2007 TESCO HSC/Vinod        Defect # 4190 Begin
          --21-Apr-2008 Tesco HSC/Usha Patil   DefNBS006323 Begin
          --Added NVL for the fields
          tsl_occ_barcode_auth = NVL(I_item_rec.tsl_occ_barcode_auth,tsl_occ_barcode_auth),
          tsl_retail_barcode_auth = NVL(I_item_rec.tsl_retail_barcode_auth,tsl_retail_barcode_auth),
          --21-Apr-2008 Tesco HSC/Usha Patil   DefNBS006323 End
          --26-Nov-2007 TESCO HSC/Vinod        Defect # 4190 End
          --17-Mar-2008 Tesco HSC/Usha Patil    Mod:N126 Begin
          tsl_deactivate_date = I_item_rec.tsl_deactivate_date,
          --17-Mar-2008 Tesco HSC/Usha Patil    Mod:N126 End
          --18-Mar-2008 Tesco HSC/Rahul Soni       Mod:N114 Begin
          tsl_variant_reason_code = I_item_rec.tsl_variant_reason_code,
          --18-Mar-2008 Tesco HSC/Rahul Soni       Mod:N114 End
          --23-May-2008     TESCO HSC Vijaya Bhaskar/Wipro-Enabler        Mod:N127    Begin
          tsl_range_auth_ind = NVL(I_item_rec.tsl_range_auth_ind,tsl_range_auth_ind),
          --23-May-2008     TESCO HSC Vijaya Bhaskar/Wipro-Enabler        Mod:N127    End
          --16-Jun-2008 Tesco HSC/Vinod Kumar      Mod:N111 Begin
          primary_ref_item_ind   = NVL(I_item_rec.primary_ref_item_ind,primary_ref_item_ind),
          --16-Jun-2008 Tesco HSC/Vinod Kumar      Mod:N111 End
          --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    Begin
          tsl_common_ind = NVL(I_item_rec.tsl_common_ind,tsl_common_ind),
          tsl_primary_country = I_item_rec.tsl_primary_country,
          --23-Jul-2008 TESCO HSC/Nandini Mariyappa        Mod:N111A    End
          --11-Nov-2008     TESCO HSC/Nandini Mariyappa   Mod:N128  Begin
          tsl_primary_cua = I_item_rec.tsl_primary_cua,
          --11-Nov-2008     TESCO HSC/Nandini Mariyappa   Mod:N128  End
          -- CR165, 07-Jan-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
          tsl_suspended    = I_item_rec.tsl_suspended,
          tsl_suspend_date = I_item_rec.tsl_suspend_date,
          -- CR165, 07-Jan-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
          --03-Feb-2009 Tesco HSC/Nandini Mariyappa       Defect#:DefNBS011227   Begin
          handling_temp = I_item_rec.handling_temp,
          handling_sensitivity = I_item_rec.handling_sensitivity,
          --03-Feb-2009 Tesco HSC/Nandini Mariyappa       Defect#:DefNBS011227   End
          --17-Apr-2009 Tesco HSC/Usha Patil              Defect Id: NBS00012450 Begin
          tsl_price_marked_except_ind = NVL(I_item_rec.tsl_price_marked_except_ind,'N'),
          --17-Apr-2009 Tesco HSC/Usha Patil              Defect Id: NBS00012450 End
          --04-May-2009 Tesco HSC/Nandini Mariyappa       Defect#:DefNBS012710  Begin
          --20-Apr-2009 Tesco HSC/Nandini Mariyappa       Defect#:DefNBS012341  Begin
          item_parent = NVL(I_item_rec.item_parent,item_parent),
          item_grandparent = NVL(I_item_rec.item_grandparent,item_grandparent),
          status = NVL(I_item_rec.status,status),
          tsl_consumer_unit = NVL(I_item_rec.tsl_consumer_unit,tsl_consumer_unit),
          --20-Apr-2009 Tesco HSC/Nandini Mariyappa       Defect#:DefNBS012341  End
          --04-May-2009 Tesco HSC/Nandini Mariyappa       Defect#:DefNBS012710  End
          --11-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   Begin
          --CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 18-Feb-2010 Begin
          --tsl_range_auth_ind_roi = NVL(I_item_rec.tsl_range_auth_ind_roi,'N'),
          --CR288 Tarun Kumar Mishra tarun.mishra@in.tesco.com 18-Feb-2010 End
          --11-Aug-2009 Tesco HSC/Nandini Mariyappa   Mod CR236   End
          -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  Begin
          --20-Aug-2009 Tesco HSC/Nandini Mariyappa       Defect#:NBS00014541   Begin
          uom_conv_factor = I_item_rec.uom_conv_factor,
          --20-Aug-2009 Tesco HSC/Nandini Mariyappa       Defect#:NBS00014541   End
          --09-Feb-2010 Tesco HSC/Nandini Mariyappa       Mod CR288   Begin
          tsl_primary_cua_roi = I_item_rec.tsl_primary_cua_roi,
          --09-Feb-2010 Tesco HSC/Nandini Mariyappa       Mod CR288   End
          -- MrgNBS015130  21-Oct-2009  Bhargavi Pujari/bharagavi.pujari@in.tesco.com  End
          ---CR304 13-Dec-2010 Parvesh,parveshkumar.rulhan@in.tesco.com Begin
          tsl_ignr_deact_rule = DECODE(I_item_rec.tsl_deactivate_date,NULL,'N',tsl_ignr_deact_rule),
          ---CR304 13-Dec-2010 Parvesh,parveshkumar.rulhan@in.tesco.com End
          --MrgNBS023522 06-Sep-2011 chithraprabha, chitraprabha.v@in.tesco.com Begin
          --CR396, 02-Aug-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, Begin
          diff_1              = NVL(I_item_rec.Diff_1, diff_1),
          diff_2              = NVL(I_item_rec.Diff_2, diff_2),
          diff_3              = NVL(I_item_rec.Diff_3, diff_3),
          diff_4              = NVL(I_item_rec.Diff_4, diff_4)
          --CR396, 02-Aug-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, End
          --MrgNBS023522 06-Sep-2011 chithraprabha, chitraprabha.v@in.tesco.com End
    where item = I_item_rec.item;
   ---
   if SQL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('NO_RECORDS');
      return FALSE;
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

END UPDATE_ITEM_MASTER;
-------------------------------------------------------------------------------------------------------
--- PRIVATE FUNCTION
-------------------------------------------------------------------------------------------------------
FUNCTION LOCK_ITEM_MASTER(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          I_item            IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_MASTER_SQL.LOCK_ITEM_MASTER';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);

   CURSOR C_LOCK_ITEM_MASTER IS
      select 'x'
        from item_master
       where item = I_item
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_MASTER', 'ITEM_MASTER','item: '||I_item);
   open C_LOCK_ITEM_MASTER;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_MASTER', 'ITEM_MASTER','item: '||I_item);
   close C_LOCK_ITEM_MASTER;
   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_MASTER',
                                            I_item,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END LOCK_ITEM_MASTER;
-------------------------------------------------------------------------------------------------------
-- 28-Jun-2007 Govindarajan - MOD 365b1 Begin
-------------------------------------------------------------------------------------------------------
-- Function Name  : TSL_DEFAULT_BASE_RCOM_ATTRIB
-- Purpose        : Defaults RCOM attributes to all Variant Items associated to the
--                  selected Base Item
-------------------------------------------------------------------------------------------------------
FUNCTION TSL_DEFAULT_BASE_RCOM_ATTRIB (O_error_message        IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                       I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                                       I_item_service_level   IN     ITEM_MASTER.ITEM_SERVICE_LEVEL%TYPE,
                                       I_gift_wrap_ind        IN     ITEM_MASTER.GIFT_WRAP_IND%TYPE,
                                       I_ship_alone_ind       IN     ITEM_MASTER.SHIP_ALONE_IND%TYPE)
   return BOOLEAN is

   L_table          VARCHAR2(65) := 'ITEM_MASTER';
   L_program        VARCHAR2(300) := 'ITEM_MASTER_SQL.TSL_DEFAULT_BASE_RCOM_ATTRIB';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);

   -- This cursor will lock the variant information
   -- on the table ITEM_MASTER
   cursor C_LOCK_ITEM_MASTER is
      select 'x'
        from item_master im
       where im.tsl_base_item  = I_item
         and im.tsl_base_item != im.item
         and im.item_level     = im.tran_level
         and im.item_level     = 2
         for update nowait;

BEGIN
      if I_item is NULL then                                       -- L1 begin
          -- If input item is null then throws an error
          O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                I_item,
                                                L_program,
                                                NULL);
          return FALSE;
      else                                                        -- L1 else

          -- Opening and closing the C_LOCK_ITEM_MASTER cursor
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_ITEM_MASTER',
                           L_table,
                           'ITEM: ' ||I_item);
          open C_LOCK_ITEM_MASTER;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_ITEM_MASTER',
                           L_table,
                           'ITEM: ' ||I_item);
          close C_LOCK_ITEM_MASTER;

          -- Updating the records from ITEM_MASTER table
          SQL_LIB.SET_MARK('UPDATE',
                           NULL,
                           L_table,
                           'ITEM: ' ||I_item);

          update item_master
             set item_service_level = I_item_service_level,
                 gift_wrap_ind      = I_gift_wrap_ind,
                 ship_alone_ind     = I_ship_alone_ind
           where tsl_base_item      = I_item
             and tsl_base_item     != item
             and item_level         = tran_level
             and item_level         = 2;

          return TRUE;
      end if;                                              -- L1 end
EXCEPTION
   -- Raising an exception for record lock error
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_program,
                                            'ITEM: ' ||I_item);
      return FALSE;

   -- Raising an exception for others
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END TSL_DEFAULT_BASE_RCOM_ATTRIB;
-------------------------------------------------------------------------------------------------------
-- Function Name  : TSL_DEFAULT_BASE_GROC_ATTRIB
-- Purpose        : Defaults Groc attributes to all Variant Items associated
--                  to the selected Base Item
-------------------------------------------------------------------------------------------------------
FUNCTION TSL_DEFAULT_BASE_GROC_ATTRIB  (O_error_message             IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                        I_item                      IN     ITEM_MASTER.ITEM%TYPE,
                                        I_package_size              IN     ITEM_MASTER.PACKAGE_SIZE%TYPE,
                                        I_package_uom               IN     ITEM_MASTER.PACKAGE_UOM%TYPE,
                                        I_retail_label_type         IN     ITEM_MASTER.RETAIL_LABEL_TYPE%TYPE,
                                        I_retail_label_value        IN     ITEM_MASTER.RETAIL_LABEL_VALUE%TYPE,
                                        I_handling_sensitivity      IN     ITEM_MASTER.HANDLING_SENSITIVITY%TYPE,
                                        I_handling_temp             IN     ITEM_MASTER.HANDLING_TEMP%TYPE,
                                        I_waste_type                IN     ITEM_MASTER.WASTE_TYPE%TYPE,
                                        I_default_waste_pct         IN     ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE,
                                        I_waste_pct                 IN     ITEM_MASTER.WASTE_PCT%TYPE,
                                        I_container_item            IN     ITEM_MASTER.CONTAINER_ITEM%TYPE,
                                        I_deposit_in_price_per_uom  IN     ITEM_MASTER.DEPOSIT_IN_PRICE_PER_UOM%TYPE,
                                        I_sale_type                 IN     ITEM_MASTER.SALE_TYPE%TYPE,
                                        I_order_type                IN     ITEM_MASTER.ORDER_TYPE%TYPE)
   return BOOLEAN is

   L_table          VARCHAR2(65) := 'ITEM_MASTER';
   L_program        VARCHAR2(300) := 'ITEM_MASTER_SQL.TSL_DEFAULT_BASE_GROC_ATTRIB';
   --CR354 16-Aug-10 Praveen Begin
   L_tsl_loc_sec_ind   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
   L_owner_cntry   SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
   --CR354 16-Aug-10 Praveen End
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);

   -- This cursor will lock the variant information
   -- on the table ITEM_MASTER
   cursor C_LOCK_ITEM_MASTER is
      select 'x'
        from item_master im
       where im.tsl_base_item  = I_item
         and im.tsl_base_item != im.item
         and im.item_level     = im.tran_level
         and im.item_level     = 2
         for update nowait;

   -- This cursor get the Variant Items associated to the selected Base Item,
   -- and the value for the CONTAINER_ATTRIBUTES is going to be change
   cursor C_UPDATED_CONTAINER_ITEM is
      select im.item item
        from item_master im
       where im.tsl_base_item            = I_item
         and im.tsl_base_item           != im.item
         and im.item_level               = im.tran_level
         and im.item_level               = 2
         and NVL(im.container_item,'x') != NVL(I_container_item,'x')
         for update nowait;

BEGIN
      if I_item is NULL then                                       -- L1 begin
          -- If input item is null then throws an error
          O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                I_item,
                                                L_program,
                                                NULL);
          return FALSE;
      else                                                        -- L1 else

          --CR354 16-Aug-10 Praveen Begin
          if SYSTEM_OPTIONS_SQL.TSL_GET_LOC_SEC_IND (O_error_message,
                                                     L_tsl_loc_sec_ind) = FALSE then
             return FALSE;
          end if;

          if ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY (O_error_message,
                                                    L_owner_cntry,
                                                    I_item) = FALSE then
             return FALSE;
          end if;
          --CR354 16-Aug-10 Praveen End
          -- Opening and closing the C_LOCK_VAT_ITEM cursor
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_ITEM_MASTER',
                           L_table,
                           'ITEM: ' ||I_item);
          open C_LOCK_ITEM_MASTER;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_ITEM_MASTER',
                           L_table,
                           'ITEM: ' ||I_item);
          close C_LOCK_ITEM_MASTER;

          -- Cursor for ITEM_MASTER table
          -- Opening the cursor C_UPDATED_CONTAINER_ITEM
          SQL_LIB.SET_MARK('OPEN',
                           'C_UPDATED_CONTAINER_ITEM',
                           L_table,
                           'ITEM: ' ||I_item);
          FOR C_rec in C_UPDATED_CONTAINER_ITEM
          LOOP                                            -- L2 begin

              if NOT POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                                     65,
                                                      C_rec.item,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      NULL) then    -- L3 begin
                          return FALSE;
              end if;   -- L3 end
          END LOOP;         -- L2 end

          SQL_LIB.SET_MARK('UPDATE',
                           NULL,
                           L_table,
                           'ITEM: ' ||I_item);
          update item_master
             set package_size             = I_package_size,
                 package_uom              = I_package_uom ,
                 retail_label_type        = I_retail_label_type,
                 retail_label_value       = I_retail_label_value,
                 handling_sensitivity     = I_handling_sensitivity,
                 handling_temp            = I_handling_temp,
                 waste_type               = I_waste_type,
                 default_waste_pct        = I_default_waste_pct,
                 waste_pct                = I_waste_pct,
                 container_item           = I_container_item,
                 deposit_in_price_per_uom = I_deposit_in_price_per_uom,
                 order_type               = I_order_type,
                 sale_type                = I_sale_type
           -- CR258 30-Apr-2010 Chandru Begin
           where item in (select item
                            from item_master
                           where tsl_base_item = I_item
                             and tsl_base_item != item)
              or item_parent in (select item
                                   from item_master
                                  where tsl_base_item = I_item
                                    and tsl_base_item != item
                                    -- CR354 18-Aug-2010 Praveen Begin
                                    and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry)))
                                    -- CR354 18-Aug-2010 Praveen End
              or item in (select pack_no
                            from packitem
                           where item in (select item
                                            from item_master
                                           where tsl_base_item = I_item
                                             and tsl_base_item != item
                                             -- CR354 18-Aug-2010 Praveen Begin
                                             and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry))))
                                             -- CR354 18-Aug-2010 Praveen End
              --01-Jul-2010    TESCO HSC/Joy Stephen    DefNBS018129   Begin
              or item_parent in (select pack_no
                            from packitem
                           where item in (select item
                                            from item_master
                                           where tsl_base_item = I_item
                                             and tsl_base_item != item
                                             -- CR354 18-Aug-2010 Praveen Begin
                                             and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry))));
                                             -- CR354 18-Aug-2010 Praveen End
              --01-Jul-2010    TESCO HSC/Joy Stephen    DefNBS018129   End
           -- CR258 30-Apr-2010 Chandru End
          return TRUE;
      end if;                                              -- L1 end
EXCEPTION
   -- Raising an exception for record lock error
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_program,
                                            'ITEM: ' ||I_item);
      return FALSE;

   -- Raising an exception for others
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END TSL_DEFAULT_BASE_GROC_ATTRIB;
-------------------------------------------------------------------------------------------------------
-- 28-Jun-2007 Govindarajan - MOD 365b1 End
-------------------------------------------------------------------------------------------------------
FUNCTION DEFAULT_CHILD_STORE_ORD_MULT (O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                       I_item              IN     ITEM_MASTER.ITEM%TYPE,
                                       I_store_ord_mult    IN     ITEM_MASTER.STORE_ORD_MULT%TYPE)
   RETURN BOOLEAN IS

   L_table       VARCHAR2(30) := 'ITEM_MASTER';
   L_program     VARCHAR2(60) := 'ITEM_MASTER_SQL.DEFAULT_CHILD_STORE_ORD_MULT';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_CHILDREN is
      select 'x'
        from item_master
       where item_parent = I_item
          or item_grandparent = I_item
             for update nowait;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_store_ord_mult is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_store_ord_mult',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_CHILDREN', 'ITEM_MASTER','item: '||I_item);
   open C_LOCK_CHILDREN;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_CHILDREN', 'ITEM_MASTER','item: '||I_item);
   close C_LOCK_CHILDREN;

   SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_MASTER','item: '||I_item);

   update item_master
      set store_ord_mult = I_store_ord_mult
    where item_parent = I_item
       or item_grandparent = I_item;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END DEFAULT_CHILD_STORE_ORD_MULT;
-------------------------------------------------------------------------
-- 30-Jan-2007 Ramasamy - MOD N113 Begin
FUNCTION TSL_VALIDATE_STYLE_REF(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_tsl_style_ref IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                                O_is_valid      OUT    BOOLEAN)
   return BOOLEAN is

   L_program VARCHAR2(60) := 'ITEM_MASTER_SQL.TSL_VALIDATE_STYLE_REF';

BEGIN
   ---
   O_is_valid      := TRUE;
   --Check the length of I_tsl_style_ref and if it is not 8 characters long then set O_is_valid to False and return True.
   if length(I_tsl_style_ref) < 8
      or length(I_tsl_style_ref) > 8
      or I_tsl_style_ref IS NULL then
      O_is_valid      := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            'I_tsl_style_ref',
                                            L_program,
                                            NULL);
      return TRUE;
   end if;
   ---
   --Check the first two characters of I_tsl_style_ref are are letters (A-Z)
   --If either are not letters then set O_is_valid to False and return True.
   if ASCII(upper(substr(I_tsl_style_ref, 1, 1))) < 65
      or ASCII(upper(SUBSTR(I_tsl_style_ref,1, 1))) > 90
      or ASCII(upper(SUBSTR(I_tsl_style_ref, 2, 1))) < 65
      or ASCII(upper(SUBSTR(I_tsl_style_ref, 2, 1))) > 90 then
      O_is_valid      := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            'I_tsl_style_ref',
                                            L_program,
                                            NULL);
      return TRUE;
   end if;
   ---
   -- MrgNBS017905 18-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   -- DefNBS00017845, 09-JUN-2010, Amita Nandal,amita.nandal@in.tesco.com (BEGIN)
   -- The code validating for the first two letters to form the string ?ZZ? has been removed.
   -- DefNBS00017845, 09-JUN-2010, Amita Nandal,amita.nandal@in.tesco.com (END)
   -- MrgNBS017905 18-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
   ---
   --Check the 3rd character of I_tsl_style_ref is a number between 0 and 9.
   --If it is not then set O_is_valid to False and return True.
   if ASCII(SUBSTR(I_tsl_style_ref, 3, 1)) < 48
      or ASCII(SUBSTR(I_tsl_style_ref, 3, 1)) > 57 then
      O_is_valid      := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            'I_tsl_style_ref',
                                            L_program,
                                            NULL);
      return TRUE;
   end if;
   ---
   -- MrgNBS017905 18-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   -- DefNBS00017845, 09-JUN-2010, Amita Nandal,amita.nandal@in.tesco.com (BEGIN)
   --Check the 4th character of I_tsl_style_ref is a number between 0 and 9.
   --If it is not then set O_is_valid to False and return True.
   if ASCII(SUBSTR(I_tsl_style_ref, 4, 1)) < 48 or
      ASCII(SUBSTR(I_tsl_style_ref, 4, 1)) > 57 then
   -- DefNBS00017845, 09-JUN-2010, Amita Nandal,amita.nandal@in.tesco.com (END)
   -- MrgNBS017905 18-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
      O_is_valid      := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            'I_tsl_style_ref',
                                            L_program,
                                            NULL);
      return TRUE;
   end if;
   ---
   --Check the 5th character of I_tsl_style_ref is a number between 0 and 9.
   --If it is not then set O_is_valid to False and return True.
   if ASCII(SUBSTR(I_tsl_style_ref, 5, 1)) < 48
      or ASCII(SUBSTR(I_tsl_style_ref, 5, 1)) > 57 then
      O_is_valid      := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            'I_tsl_style_ref',
                                            L_program,
                                            NULL);
      return TRUE;
   end if;
   ---
   -- MrgNBS017905 18-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   -- DefNBS00017845, 09-JUN-2010, Amita Nandal,amita.nandal@in.tesco.com (BEGIN)
   --Check that the 6th, 7th and 8th characters of I_tsl_style_ref is a number between 0 and 9.
   --If they do not then set O_is_valid to False and return True.
   if ASCII(SUBSTR(I_tsl_style_ref, 6, 1)) < 48 or
      ASCII(SUBSTR(I_tsl_style_ref, 6, 1)) > 57 or
      ASCII(SUBSTR(I_tsl_style_ref, 7, 1)) < 48 or
      ASCII(SUBSTR(I_tsl_style_ref, 7, 1)) > 57 or
   -- DefNBS009236, 01-Oct-2008, Ragesh Pillai, ragesh.pillai@in.tesco.com (BEGIN)
   --or ascii(SUBSTR(I_tsl_style_ref, 8, 1)) < 49
      ASCII(SUBSTR(I_tsl_style_ref, 8, 1)) < 48 or
   -- DefNBS009236, 01-Oct-2008, Ragesh Pillai, ragesh.pillai@in.tesco.com (END)
      ASCII(SUBSTR(I_tsl_style_ref, 8, 1)) > 57 then
      O_is_valid      := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',
                                            'I_tsl_style_ref',
                                            L_program,
                                            NULL);
      return TRUE;
   -- DefNBS009236, 01-Oct-2008, Ragesh Pillai, ragesh.pillai@in.tesco.com (BEGIN)
   --The code validating for last 3 chars to form string '000' has been removed.
   -- DefNBS00017845, 09-Jun-2010, Amita Nandal,amita.nandal@in.tesco.com (END)
   -- MrgNBS017905 18-Jun-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
   -- DefNBS009236, 01-Oct-2008, Ragesh Pillai, ragesh.pillai@in.tesco.com (END)

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
END TSL_VALIDATE_STYLE_REF;
-- 30-Jan-2007 Ramasamy - MOD N113 End
--------------------------------------------------------------------------------------------------------
-- 10-May-2010, Sripriya K, CR265, Begin
-------------------------------------------------------------------------------------------------------
-- Function:    TSL_CASCADE_STYLE_REF
-- Purpose:     To cascade style reference to item's children
-----------------------------------------------------------------------------------------
FUNCTION TSL_CASCADE_STYLE_REF (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_tsl_style_ref         IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                                I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                                I_cascade_var           IN     VARCHAR2,
                                I_cscd_single_item      IN     VARCHAR2)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(60) := 'ITEM_MASTER_SQL.TSL_CASCADE_STYLE_REF';
   L_item_rec        ITEM_MASTER%ROWTYPE;
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,Begin
   L_table       VARCHAR2(30) := 'ITEM_MASTER';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,End

   CURSOR C_ITEM_MASTER_SINGLE is
   select 'x'
     from item_master im
    where im.item = I_item
      for update nowait;

   CURSOR C_ITEM_MASTER_ITEM is
   select 'x'
     from item_master im
    where (im.item_parent = I_item
       or im.item_grandparent = I_item)
      for update nowait;

   -------------------------------------------------------------------------------------------------------
   --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
   -------------------------------------------------------------------------------------------------------
   		--14-Sep-2010    TESCO HSC/Grandhi Murali    DefNBS00019116   Begin
   CURSOR C_ITEM_MASTER_PACK is
   select 'x'
     from packitem b,
          item_master im1,
          item_master im2
 		where (im2.item = I_item
    	 or im2.item_parent = I_item
    	 or im2.item_grandparent = I_item)
   	  and im2.item_level = 2
   		and im2.tran_level = 2
      and im2.item = b.item
   		and (im1.item = b.pack_no or im1.item_parent = b.pack_no)
      for update nowait;
   		--14-Sep-2010    TESCO HSC/Grandhi Murali    DefNBS00019116   End
   		-------------------------------------------------------------------------------------------------------
      --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
      -------------------------------------------------------------------------------------------------------

   CURSOR C_ITEM_MASTER_VAR is
   select 'x'
     from item_master im1,
          item_master im2
    where im1.tsl_base_item = I_item
      and im1.item != im1.tsl_base_item
      and (im2.item = im1.item
       or im2.item_parent = im1.item)
      for update nowait;

   CURSOR C_ITEM_MASTER_VAR_PACK is
   select 'x'
     from packitem b,
          item_master im1,
          item_master im2
    where (im1.item = b.pack_no
       or im1.item_parent = b.pack_no)
      and im2.item = b.item
      and im2.tsl_base_item = I_item
      and im2.tsl_base_item != im2.item
      for update nowait;

BEGIN
   ---
   if I_item is NULL then
       O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'ITEM : '||I_item,
                                             L_program,
                                             NULL);
       return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                       L_item_rec,
                                       I_item) = FALSE then
      return FALSE;
   end if;
   --
   if I_cscd_single_item = 'N' then
      -- Locking the records
      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_MASTER_ITEM',
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      open C_ITEM_MASTER_ITEM;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_MASTER_ITEM',
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      close C_ITEM_MASTER_ITEM;
   ---
   -- Updating the item's children records
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      ---
      update item_master im
         set im.item_desc_secondary = I_tsl_style_ref
       where (im.item_parent = I_item
          or im.item_grandparent = I_item);
      ---
   -- Locking the records
      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_MASTER_PACK',
                       'ITEM_MASTER, PACKITEM',
                       'ITEM: ' ||I_item);
      open C_ITEM_MASTER_PACK;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_MASTER_PACK',
                       'ITEM_MASTER, PACKITEM',
                       'ITEM: ' ||I_item);
      close C_ITEM_MASTER_PACK;
      ---
      -- Updating style reference for pack items
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      ---
      -------------------------------------------------------------------------------------------------------
     --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
     -------------------------------------------------------------------------------------------------------
 			--14-Sep-2010    TESCO HSC/Grandhi Murali    DefNBS00019116   Begin
      update item_master im
         set im.item_desc_secondary = I_tsl_style_ref
       where im.item in (select im1.item
                           from packitem b,
                                item_master im1,
                                item_master im2
  												where (im2.item = I_item
     												 or im2.item_parent = I_item
     												 or im2.item_grandparent = I_item)
    												and im2.item_level = 2
    												and im2.tran_level = 2
                            and im2.item = b.item
    												and (im1.item = b.pack_no or im1.item_parent = b.pack_no));
			--14-Sep-2010    TESCO HSC/Grandhi Murali    DefNBS00019116   End
			-------------------------------------------------------------------------------------------------------
       --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
     -------------------------------------------------------------------------------------------------------
   end if;
   ---
   if L_item_rec.Item_Level = L_item_rec.Tran_Level and L_item_rec.Pack_Ind = 'N' then

      if I_cascade_var = 'Y' and I_cscd_single_item = 'N' then
         -- Locking the records
         SQL_LIB.SET_MARK('OPEN',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         open C_ITEM_MASTER_VAR;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR;
         ---
         -- Updating for the variant items and it's children
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         ---
         update item_master im
            set im.item_desc_secondary = I_tsl_style_ref
          where im.item in (select im2.item
                              from item_master im1,
                                   item_master im2
                             where im1.tsl_base_item = I_item
                               and im1.item != im1.tsl_base_item
                               and (im2.item = im1.item
                                or im2.item_parent = im1.item));
         ---
         -- Locking the records
         SQL_LIB.SET_MARK('OPEN',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         open C_ITEM_MASTER_VAR_PACK;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR_PACK;
         ---
         -- Updating the style reference for variant TPND
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         ---
         update item_master im
            set im.item_desc_secondary = I_tsl_style_ref
          where im.item in (select im1.item
                              from packitem b,
                                   item_master im1,
                                   item_master im2
                             where (im1.item = b.pack_no
                                or im1.item_parent = b.pack_no)
                               and im2.item = b.item
                               and im2.tsl_base_item = I_item
                               and im2.tsl_base_item != im2.item);

      elsif I_cascade_var = 'N' and I_cscd_single_item = 'N' then
         -- Locking the records
         SQL_LIB.SET_MARK('OPEN',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         open C_ITEM_MASTER_VAR;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR;
         ---
         -- Updating for the variant items and it's children
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         ---
         update item_master im
            set im.item_desc_secondary = I_tsl_style_ref
          where im.item in (select im2.item
                              from item_master im1,
                                   item_master im2
                             where im1.tsl_base_item = I_item
                               and im1.item != im1.tsl_base_item
                               and (im2.item = im1.item
                                or im2.item_parent = im1.item))
            and im.status = 'W';
         ---
         -- Locking the records
         SQL_LIB.SET_MARK('OPEN',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         open C_ITEM_MASTER_VAR_PACK;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR_PACK;
         ---
         -- Updating the style reference for variant TPND
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         ---
         update item_master im
            set im.item_desc_secondary = I_tsl_style_ref
          where im.item in (select im1.item
                              from packitem b,
                                   item_master im1,
                                   item_master im2
                             where (im1.item = b.pack_no
                                or im1.item_parent = b.pack_no)
                               and im2.item = b.item
                               and im2.tsl_base_item = I_item
                               and im2.tsl_base_item != im2.item)
            and im.status = 'W';
      end if;
   end if;
   -- while adding a single record of item , pack
   if I_cscd_single_item = 'Y' then
      -- Locking the records
      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_MASTER_SINGLE',
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      open C_ITEM_MASTER_SINGLE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_MASTER_SINGLE',
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      close C_ITEM_MASTER_SINGLE;
   ---
   -- Updating the style reference for the item
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      update item_master im
         set im.item_desc_secondary = I_tsl_style_ref
       where im.item = I_item;
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011, Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,End

   when OTHERS then
      ---
      if C_ITEM_MASTER_SINGLE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_SINGLE',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_SINGLE;
      end if;
      ---
      if C_ITEM_MASTER_ITEM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_ITEM',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_ITEM;
      end if;
      ---
      if C_ITEM_MASTER_PACK%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_PACK;
      end if;
      ---
      if C_ITEM_MASTER_VAR%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR;
      end if;
      ---
      if C_ITEM_MASTER_VAR_PACK%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR_PACK;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CASCADE_STYLE_REF;
-------------------------------------------------------------------------------------------------
--FUNCTION     TSL_CASCADE_STYLE_WKSHT
-- Purpose:    To cascade style reference to item's children in Worksheet status
-------------------------------------------------------------------------------------------------
FUNCTION TSL_CASCADE_STYLE_WKSHT (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_tsl_style_ref         IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                                  I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                                  I_cascade_var           IN     VARCHAR2)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(60) := 'ITEM_MASTER_SQL.TSL_CASCADE_STYLE_WKSHT';
   L_item_rec        ITEM_MASTER%ROWTYPE;
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,Begin
   L_table       VARCHAR2(30) := 'ITEM_MASTER';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,End

   CURSOR C_ITEM_MASTER_ITEM is
   select 'x'
     from item_master im
    where (im.item_parent = I_item
       or im.item_grandparent = I_item)
      and im.status = 'W'
      for update nowait;

   CURSOR C_ITEM_MASTER_PACK is
   select 'x'
     from packitem b,
          item_master im1,
          item_master im2
    where (im1.item = b.pack_no
       or im1.item_parent = b.pack_no)
      and im2.item = b.item
      and ((NVL(im2.item_grandparent, '-999') = I_item)
       or (NVL(im2.item_parent, '-999') = I_item)
       or (NVL(im2.item, '-999') = I_item))
      and im1.status = 'W'
      for update nowait;

   CURSOR C_ITEM_MASTER_VAR is
   select 'x'
     from item_master im1,
          item_master im2
    where im1.tsl_base_item = I_item
      and im1.item != im1.tsl_base_item
      and (im2.item = im1.item
       or im2.item_parent = im1.item)
      for update nowait;

   CURSOR C_ITEM_MASTER_VAR_PACK is
   select 'x'
     from packitem b,
          item_master im1,
          item_master im2
    where (im1.item = b.pack_no
       or im1.item_parent = b.pack_no)
      and im2.item = b.item
      and im2.tsl_base_item = I_item
      and im2.tsl_base_item != im2.item
      for update nowait;

BEGIN
   ---
   if I_item is NULL then
       O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'ITEM : '||I_item,
                                             L_program,
                                             NULL);
       return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                       L_item_rec,
                                       I_item) = FALSE then
      return FALSE;
   end if;
   -- Locking the records
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_MASTER_ITEM',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   open C_ITEM_MASTER_ITEM;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_MASTER_ITEM',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   close C_ITEM_MASTER_ITEM;
   ---
   -- Updating the item's children records
   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   ---
   update item_master im
      set im.item_desc_secondary = I_tsl_style_ref
    where (im.item_parent = I_item
       or im.item_grandparent = I_item)
      and im.status = 'W';
   ---
   -- Locking the records
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_MASTER_PACK',
                    'ITEM_MASTER, PACKITEM',
                    'ITEM: ' ||I_item);
   open C_ITEM_MASTER_PACK;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_MASTER_PACK',
                    'ITEM_MASTER, PACKITEM',
                    'ITEM: ' ||I_item);
   close C_ITEM_MASTER_PACK;
   ---
   -- Updating style reference for pack items
   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   ---
   update item_master im
      set im.item_desc_secondary = I_tsl_style_ref
    where im.item in (select im1.item
                        from packitem b,
                             item_master im1,
                             item_master im2
                       where (im1.item = b.pack_no
                          or im1.item_parent = b.pack_no)
                         and im2.item = b.item
                         and ((NVL(im2.item_grandparent, '-999') = I_item)
                          or (NVL(im2.item_parent, '-999') = I_item)
                          or (NVL(im2.item, '-999') = I_item)))
      and im.status = 'W';
   ---
   --For Variant and it's children
   if L_item_rec.Item_Level = L_item_rec.Tran_Level and L_item_rec.Pack_Ind = 'N' then
      if I_cascade_var = 'Y' then
         -- Locking the records
         SQL_LIB.SET_MARK('OPEN',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         open C_ITEM_MASTER_VAR;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR;
      ---
      -- Updating for the variant items and it's children
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
      ---
         update item_master im
            set im.item_desc_secondary = I_tsl_style_ref
          where im.item in (select im2.item
                              from item_master im1,
                                   item_master im2
                             where im1.tsl_base_item = I_item
                               and im1.item != im1.tsl_base_item
                               and (im2.item = im1.item
                                or im2.item_parent = im1.item));
        ---
         -- Locking the records
         SQL_LIB.SET_MARK('OPEN',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         open C_ITEM_MASTER_VAR_PACK;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR_PACK;
         ---
         -- Updating the style reference for variant TPND
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         ---
         update item_master im
            set im.item_desc_secondary = I_tsl_style_ref
          where im.item in (select im1.item
                              from packitem b,
                                   item_master im1,
                                   item_master im2
                             where (im1.item = b.pack_no
                                or im1.item_parent = b.pack_no)
                               and im2.item = b.item
                               and im2.tsl_base_item = I_item
                               and im2.tsl_base_item != im2.item);

      elsif I_cascade_var = 'N' then
       -- Locking the records
         SQL_LIB.SET_MARK('OPEN',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         open C_ITEM_MASTER_VAR;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR;
         ---
         -- Updating for the variant items and it's children
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         ---
         update item_master im
            set im.item_desc_secondary = I_tsl_style_ref
          where im.item in (select im2.item
                              from item_master im1,
                                   item_master im2
                             where im1.tsl_base_item = I_item
                               and im1.item != im1.tsl_base_item
                               and (im2.item = im1.item
                                or im2.item_parent = im1.item))
            and im.status = 'W';
         ---
         -- Locking the records
         SQL_LIB.SET_MARK('OPEN',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         open C_ITEM_MASTER_VAR_PACK;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR_PACK;
         ---
         -- Updating the style reference for variant TPND
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         ---
         update item_master im
            set im.item_desc_secondary = I_tsl_style_ref
          where im.item in (select im1.item
                              from packitem b,
                                   item_master im1,
                                   item_master im2
                             where (im1.item = b.pack_no
                                or im1.item_parent = b.pack_no)
                               and im2.item = b.item
                               and im2.tsl_base_item = I_item
                               and im2.tsl_base_item != im2.item)
            and im.status = 'W';
      end if;
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011, Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,End

   when OTHERS then
      if C_ITEM_MASTER_ITEM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_ITEM',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_ITEM;
      end if;
      ---
      if C_ITEM_MASTER_PACK%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_PACK;
      end if;
      ---
      if C_ITEM_MASTER_VAR%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR;
      end if;
      ---
      if C_ITEM_MASTER_VAR_PACK%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_MASTER_VAR_PACK',
                          'ITEM_MASTER, PACKITEM',
                          'ITEM: ' ||I_item);
         close C_ITEM_MASTER_VAR_PACK;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CASCADE_STYLE_WKSHT;
--------------------------------------------------------------------------------------------------------
-- 10-May-2010, Sripriya K, CR265, End
--------------------------------------------------------------------------------------------------------
--MrgNBS017783,03-Jun-2010,(merge from 3.5b to 3.5f)Sripriya,sripriya.karanam@in.tesco.com Begin
-----------------------------------------------------------------------------------------
--12-May-2010 Murali  Cr288b Begin
-----------------------------------------------------------------------------------------
-- Function:    TSL_UPDATE_CHILD_ITEM_CTRY
-- Purpose:     To update the TSL_COUNTRY_AUTH_IND for child items.
-----------------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_CHILD_ITEM_CTRY(O_error_message IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item          IN      ITEM_MASTER.ITEM%TYPE,
                                    I_country       IN      VARCHAR2,
                                    I_var_cascade   IN      VARCHAR2,
                                    -- 14-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                                    I_supp_cascade  IN      VARCHAR2 DEFAULT 'N',
                                    I_supplier      IN      ITEM_SUPPLIER.SUPPLIER%TYPE DEFAULT NULL
                                    -- 14-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
                                    )
   return BOOLEAN is

   L_program            VARCHAR2(60) := 'ITEM_MASTER_SQL.TSL_UPDATE_CHILD_ITEM_CTRY';
   L_atr_exists         VARCHAR2(1) := 'N';
   TYPE T_CURSOR is     REF CURSOR ;
   V_CURSOR             T_CURSOR;
   L_dummy              VARCHAR2(1);

   CURSOR C_get_children is
      select im.item,
             im.dept,
             im.class,
             im.subclass,
             decode(im.item,NVL(im.tsl_base_item,'-999'),'Y','N') base_ind,
             decode(im.tsl_base_item,NULL,'N',im.item,'N','Y') var_ind
        from item_master im
       where (im.item_parent = I_item
          or im.item_grandparent = I_item)
         and im.status = 'A';

   CURSOR C_GET_REQD_INFO(Cp_item     ITEM_MASTER.ITEM%TYPE,
                          Cp_dept     DEPS.DEPT%TYPE,
                          Cp_class    CLASS.CLASS%TYPE,
                          Cp_subclass SUBCLASS.SUBCLASS%TYPE,
                          Cp_base_ind VARCHAR2,
                          Cp_var_ind  VARCHAR2) is
   select m.tsl_column_name column_name,
          mb.tsl_country_id country_id,
          mb.info info
     from tsl_map_item_attrib_code m,
          merch_hier_default mb ,
          item_master im
    where mb.required_ind = 'Y'
      and mb.dept = Cp_dept
      and mb.class = Cp_class
      and mb.subclass = Cp_subclass
      and mb.tsl_country_id = I_country
      and mb.info  = m.tsl_code
      and mb.tsl_item_lvl = im.item_level
      and mb.tsl_pack_ind = im.pack_ind
      and im.item = Cp_item
      and (mb.tsl_base_ind = Cp_base_ind or mb.tsl_var_ind  = Cp_var_ind)
      and mb.info in (select code  from code_detail where code_type = 'TIAT');

   CURSOR C_GET_VARIANTS is
   select im2.item
     from item_master im1,
          item_master im2
    where im1.tsl_base_item = I_item
      and im1.item != im1.tsl_base_item
      and (im2.item = im1.item
       or im2.item_parent = im1.item);

   -- 14-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   --PrfNBS022544, G Jones 13-Jun-11 - Replaced ORs with UNION ALLs for performance and removed old comments.
   CURSOR C_GET_CHILDREN_PACK is
   select im.item
     from item_master im,
          item_supplier its
    where im.item_parent = I_item
      and its.item       = I_item
      and im.status      = 'A'
      and its.supplier   = I_supplier
    union all
   select im.item
     from item_master im,
          item_supplier its
    where im.item_grandparent = I_item
      and its.item            = I_item
      and im.status           = 'A'
      and its.supplier        = I_supplier
    union all
   select im.item
     from item_master im,
          item_supplier its
    where im.item in (select pack_no
                        from packitem
                       where item = I_item
                      union all
                      select pack_no
                        from packitem
                       where item in (select item
                                         from item_master
                                        where item_parent = I_item))
      and its.item     = I_item
      and im.status    = 'A'
      and its.supplier = I_supplier
    union all
   select im.item
     from item_master im,
          item_supplier its
    where im.item_parent in (select pack_no
                               from packitem
                              where item = I_item
                             union all
                             select pack_no
                               from packitem
                              where item in (select item
                                               from item_master
                                              where item_parent = I_item))
      and its.item      = I_item
      and im.status     = 'A'
      and its.supplier  = I_supplier;
   -- 14-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   --end PrfNBS022544


BEGIN
   ---
   FOR C_child in C_get_children
   LOOP
      L_atr_exists := 'Y';
      FOR C_rec in  C_GET_REQD_INFO(C_child.item,
                                    C_child.dept,
                                    C_child.class,
                                    C_child.subclass,
                                    C_child.base_ind,
                                    C_child.var_ind)
      LOOP
         open V_CURSOR FOR' select 1 '||
                          '   from ITEM_ATTRIBUTES IA '||
                          '  where IA.ITEM = '''||I_item||''''||
                          '    and '||C_rec.column_name||' is not NULL '||
                          '    and IA.tsl_country_id = '''||I_country||'''';
         fetch V_CURSOR into L_dummy;
         if V_CURSOR%NOTFOUND  then
            L_atr_exists  := 'N';
            exit;
         end if;
         close V_CURSOR;
      END LOOP;

      if L_atr_exists = 'Y' then
        if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                                C_child.item) = FALSE then
           return FALSE;
        end if;
      end if;
   END LOOP;

   if I_var_cascade = 'Y' then
      FOR C_rec in C_GET_VARIANTS LOOP
         if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                                 C_rec.item) = FALSE then
           return FALSE;
        end if;
      END LOOP;
   end if;

   -- 14-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   if I_supp_cascade = 'Y' then
      FOR C_rec in C_GET_CHILDREN_PACK LOOP
         if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                                 C_rec.item) = FALSE then
           return FALSE;
        end if;
      END LOOP;
   end if;
   -- 14-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_UPDATE_CHILD_ITEM_CTRY;
--12-May-2010 Murali  Cr288b End
-------------------------------------------------------------------------
--13-May-2010 Tesco HSC/Usha Patil                Mod: CR288b Begin
-------------------------------------------------------------------------
-- Function:    TSL_UPDATE_ITEM_CTRY
-- Purpose:     To update the TSL_COUNTRY_AUTH_IND for an item.
-------------------------------------------------------------------------
FUNCTION TSL_UPDATE_ITEM_CTRY (O_error_message    IN OUT      RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item             IN          ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program                    VARCHAR2(60) := 'ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY';
   L_item_master_row            ITEM_MASTER%ROWTYPE;
   L_sca_exists                 VARCHAR2(1) := 'N';
   L_complete_uk                VARCHAR2(1) := 'N';
   L_complete_roi               VARCHAR2(1) := 'N';
   L_range_exists               VARCHAR2(1) := 'N';
   L_country_auth_ind           ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE := 'N';
   L_item_range_req             VARCHAR2(1) := 'N';
   L_item_sca_req               VARCHAR2(1) := 'N';
   L_item_child_req             VARCHAR2(1) := 'N';
   L_spack_setup_req            VARCHAR2(1) := 'N';
   L_occ_barcode_req            VARCHAR2(1) := 'N';
   L_retail_barcode_req         VARCHAR2(1) := 'N';
   -------------------------------------------------------------------------------------------------------
  --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
   -------------------------------------------------------------------------------------------------------
   --CR347,28-Jul-2010,Sripriya,Sripriya.karanam@in.tesco.com, Begin
   L_tsocc_barcode_req            VARCHAR2(1) := 'N';
   L_tsretail_barcode_req         VARCHAR2(1) := 'N';
   --CR347,28-Jul-2010,Sripriya,Sripriya.karanam@in.tesco.com, End
   -------------------------------------------------------------------------------------------------------
   --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
   -------------------------------------------------------------------------------------------------------
   L_base_country_auth_ind      ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE := 'N';
   L_sca_approved_uk            BOOLEAN     := FALSE;
   L_sca_approved_roi           BOOLEAN     := FALSE;
   L_ctry_auth_old              VARCHAR2(1) := 'N';
   L_update_country             ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE := 'N';
   L_update_country_roi         ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE := 'N';
   L_vdate                      PERIOD.VDATE%TYPE := get_vdate();
   L_vdate_1                    PERIOD.VDATE%TYPE;
   L_week_no                    VARCHAR2(1);
   L_day                        NUMBER(2);
   L_mth                        NUMBER(2);
   L_year                       NUMBER(4);
   L_dd                         NUMBER(2);
   L_mm                         NUMBER(2);
   L_yy                         NUMBER(4);
   L_future_date                DATE;
   L_return_code                VARCHAR2(5);
   L_error_msg                  RTK_ERRORS.RTK_TEXT%TYPE;
   L_system_options_row         SYSTEM_OPTIONS%ROWTYPE;
   L_base_item                  ITEM_MASTER.ITEM%TYPE;
   -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   L_valid_supplier             VARCHAR2(1) := 'N';
   L_valid_supplier_roi         VARCHAR2(1) := 'N';
   L_valid                      VARCHAR2(1) := 'N';
   L_parent_approved            VARCHAR2(1) := 'N';
   L_modified_ctry_auth         VARCHAR2(1) := 'N';
   -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   -------------------------------------------------------------------------------------------------------
   --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
   -------------------------------------------------------------------------------------------------------
   -- CR288d, 2-Aug-2010, Nishant Gupta, nishant.gupta@in.tesco.com (BEGIN)
   L_epw_item                   ITEM_MASTER.ITEM%TYPE;
   L_epw_tsl_country_id         ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE;
   L_epw_tsl_end_date           DATE;
   L_tsl_epw_ind                VARCHAR2(1);
   -- CR288d, 2-Aug-2010, Nishant Gupta, nishant.gupta@in.tesco.com (END)
   -------------------------------------------------------------------------------------------------------
   --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
   -------------------------------------------------------------------------------------------------------
   -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com Begin
   --DefNBS022105, 28-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
   --L_store_cntry        tsl_mu_loc.store%TYPE;
   L_store_cntry        VARCHAR2(1) := NULL;
   L_chk_common         VARCHAR2(1) := 'N';
   L_muitem_country_id  ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE;
   L_base_country_id    ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE;
   L_error_key_mu       RTK_ERRORS.RTK_KEY%TYPE;
   L_mu_uk_store           VARCHAR2(1):= 'N';
   L_mu_roi_store          VARCHAR2(1):= 'N';
   --DefNBS022105, 28-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
   --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
   L_valid_record      VARCHAR2(1) := '0';
   --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
   -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com end
   CURSOR C_GET_WEEKNO is
   select to_char(L_vdate,'D')
     from dual;

   CURSOR C_GET_COUNTRY_AUTH(Cp_item      ITEM_MASTER.ITEM%TYPE) is
   select NVL(tsl_country_auth_ind,'N')
     from item_master
    where item = Cp_item;

   CURSOR C_CHECK_RANGE_REQD(Cp_country_id      TSL_ITEM_RANGE.TSL_COUNTRY_ID%TYPE) is
   select 'Y'
     from merch_hier_default
    where dept = L_item_master_row.dept
      and class = L_item_master_row.class
      and subclass = L_item_master_row.subclass
      and info='RANGE'
      and required_ind='Y'
      --20-May-2010 Tesco HSC/Usha Patil         Defect Id: NBS00017543 Begin
      and tsl_country_id in (Cp_country_id,'B');
      --20-May-2010 Tesco HSC/Usha Patil         Defect Id: NBS00017543 End

   CURSOR C_GET_ITEM_ATTR is
   select item,
          tsl_country_id
     from item_attributes
    where item = I_item
      and tsl_launch_date is NOT NULL;

   CURSOR C_RANGE_EXISTS(Cp_country_id      TSL_ITEM_RANGE.TSL_COUNTRY_ID%TYPE) is
   select 'Y'
     from tsl_item_range tir,
          item_master im
    where tir.item = I_item
      and tir.item = im.item
      and im.tsl_range_auth_ind = 'Y'
      and tir.tsl_country_id = Cp_country_id;

   CURSOR C_UPDATE_CHILD is
   select item
     from item_master
    where item_parent = I_item
      and status = 'A';

   -------------------------------------------------------------------------------------------------------
   --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
   -------------------------------------------------------------------------------------------------------
   CURSOR C_UPD_ITEM_ATTR(Cp_item        ITEM_MASTER.ITEM%TYPE) is
   select item,
          tsl_country_id,
          tsl_launch_date
     from item_attributes
    where item = Cp_item
      and tsl_launch_date is NOT NULL
      --05-Aug-2010 Tesco HSC/ Usha Patil               MrgNBS018606 Begin
      --Commented the condition as this should be checked for CR288d to update the epw
      --and tsl_launch_date < L_vdate
      --05-Aug-2010 Tesco HSC/ Usha Patil               MrgNBS018606 End
      and tsl_country_id in (L_update_country,L_update_country_roi);
    -------------------------------------------------------------------------------------------------------
    --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
    -------------------------------------------------------------------------------------------------------

   CURSOR C_GET_VARIANTS is
   select im2.item
     from item_master im1,
          item_master im2
    where im1.tsl_base_item = I_item
      and im1.item != im1.tsl_base_item
      and (im2.item = im1.item
       or im2.item_parent = im1.item)
      and im2.status = 'A'
      and EXISTS (select 1
                    from item_attributes ia
                   where ia.item = im2.item
                     and ia.tsl_country_id = L_update_country
                     and ia.tsl_launch_date is NOT NULL);

   CURSOR C_UPDATE_PACKS(Cp_item      ITEM_MASTER.ITEM%TYPE) is
   select i.item
     from packitem p,
          item_master i
    where p.item = Cp_item
      and (p.pack_no = i.item
       or p.pack_no = i.item_parent)
      and i.status = 'A'
      -- 24-May-2010 Tesco HSC/Usha Patil           Def-NBS00017600  Begin
      and i.tsl_country_auth_ind != L_update_country
      -- 24-May-2010 Tesco HSC/Usha Patil           Def-NBS00017600  End
      and EXISTS (select 1
                    from item_attributes ia
                   where ia.item = i.item
                     and ia.tsl_country_id = L_update_country
                     and ia.tsl_launch_date is NOT NULL);

   CURSOR C_GET_BASE is
   select i.tsl_base_item
     from item_master i
    where i.item = I_item
      and i.item != i.tsl_base_item
      and i.tsl_base_item is NOT NULL
      and EXISTS (select 1
                    from item_master i2
                   where i2.item  = i.tsl_base_item
                     and i2.status = 'A')
   UNION
   select i.tsl_base_item
     from item_master i,
          packitem p
    where i.item = p.item
      and p.pack_no = I_item
      and EXISTS (select 1
                    from item_master i2
                   where i2.item  = i.tsl_base_item
                     and i2.status = 'A');
   -------------------------------------------------------------------------------------------------------
--MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
-------------------------------------------------------------------------------------------------------
   -- CR288d, 2-Aug-2010, Nishant Gupta, nishant.gupta@in.tesco.com (BEGIN)
   CURSOR C_ITEM_ATTR_EPW_COPY(Cp_item        ITEM_MASTER.ITEM%TYPE) is
   select item,
          tsl_country_id,
          tsl_end_date,
          tsl_epw_ind
     from item_attributes
    where item = Cp_item
      and tsl_launch_date is NOT NULL
      and tsl_epw_ind is NOT NULL;
   -- CR288d, 2-Aug-2010, Nishant Gupta, nishant.gupta@in.tesco.com (END)
-------------------------------------------------------------------------------------------------------
--MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
-------------------------------------------------------------------------------------------------------
   -- 14-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   CURSOR C_CHK_PARENT_APPR is
   select 'Y'
     from item_master iem2
    where iem2.item = (select iem.item_parent
                        from item_master iem
                       where iem.item = I_item)
      and iem2.status = 'A'
   union
   select 'Y'
     from item_master iem,
          packitem pai
    where pai.pack_no = I_item
      and iem.item = pai.item
      and iem.status = 'A';

   CURSOR C_VARIANTS is
   select im.item
     from item_master im
    where im.tsl_base_item = I_item
      and im.item != im.tsl_base_item
      and im.status = 'A';
  -- 14-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
  -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com Begin
  --DefNBS022105, 28-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
   CURSOR C_CHK_COMMON is
   select 'Y'
     from tsl_mu_loc tml, item_master im
    where tml.mu_item = I_item
      and tml.mu_item = im.item
      and im.item_number_type = 'TPNB'
      and im.tsl_mu_ind = 'Y'
      and im.tsl_deactivate_date is NULL
      and im.tsl_suspend_date is NULL
      and rownum=1;

   CURSOR C_EXIST_MU_ITEM is
   select DISTINCT tml.item
     from tsl_mu_loc tml
    where tml.mu_item = I_item;

   --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
   --DefNBS022406, Added parameter to the cursor and additional where condition
   CURSOR C_MU_STORE(P_std_item item_master.item%TYPE) is
   select store
     from tsl_mu_loc
    where mu_item = I_item
      and item = P_std_item;
   --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end

   CURSOR C_MU_STORE_CNTRY (P_store tsl_mu_loc.store%TYPE) is
   select decode(tsf_entity_id,1,'U',2,'R') country
     from store
    where store = P_store
   union all
   select decode(tsf_entity_id,1,'U',2,'R') country
     from wh
    where wh = P_store;

   --DefNBS022105, 28-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
   -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com End

   --DefNBS023195, 08-Jul-2011 shweta.madnawat@in.tesco.com Begin
   CURSOR C_GET_VAR_CHILD(P_var_item ITEM_MASTER.ITEM%TYPE) is
   select item
     from item_master
    where item_parent = P_var_item;
   --DefNBS023195, 08-Jul-2011 shweta.madnawat@in.tesco.com End

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_COUNTRY_AUTH','ITEM_MASTER',I_item);
   open C_GET_COUNTRY_AUTH(I_item);
   SQL_LIB.SET_MARK('FETCH','C_GET_COUNTRY_AUTH','ITEM_MASTER',I_item);
   fetch C_GET_COUNTRY_AUTH into L_country_auth_ind;
   SQL_LIB.SET_MARK('CLOSE','C_GET_COUNTRY_AUTH','ITEM_MASTER',I_item);
   close C_GET_COUNTRY_AUTH;

   if L_country_auth_ind = 'B' then
      return TRUE;
   end if;

   L_ctry_auth_old := L_country_auth_ind;

   if system_options_sql.get_system_options(O_error_message,
                                            L_system_options_row) = FALSE then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_WEEKNO','PERIOD',NULL);
   open C_GET_WEEKNO;
   SQL_LIB.SET_MARK('FETCH','C_GET_WEEKNO','PERIOD',NULL);
   fetch C_GET_WEEKNO into L_week_no;
   SQL_LIB.SET_MARK('CLOSE','C_GET_WEEKNO','PERIOD',NULL);
   close C_GET_WEEKNO;

   if L_week_no = 1 then
      L_vdate_1 := L_vdate+1;
   else
      L_vdate_1 := L_vdate;
   end if;

   L_day  := TO_NUMBER(TO_CHAR(L_vdate_1, 'DD'));
   L_mth  := TO_NUMBER(TO_CHAR(L_vdate_1, 'MM'));
   L_year := TO_NUMBER(TO_CHAR(L_vdate_1, 'YYYY'));

  --if the end date is sunday passing vdate+1 to fetch the next sunday.
   CAL_TO_454_LDOW(L_day,
                  L_mth,
                  L_year,
                  L_dd,
                  L_mm,
                  L_yy,
                  L_return_code,
                  L_error_msg);
   if L_return_code = 'FALSE' then
      return FALSE;
   end if;
   L_future_date := to_date((L_dd||'/' ||L_mm||'/' ||L_yy), 'DD/MM/YYYY');

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                       L_item_master_row,
                                       I_item) = FALSE then
      return FALSE;
   end if;

   For rec in C_GET_ITEM_ATTR LOOP
      -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      L_valid_supplier := 'N';

      if TSL_VALID_SUPP(O_error_message,
                        L_valid_supplier,
                        I_item,
                        rec.tsl_country_id) = FALSE then
         return FALSE;
      end if;
      -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
      ---For Base item and Complex Pack, check for SCA and Range.
      if (L_item_master_row.item_level = L_item_master_row.tran_level and
         ((L_item_master_row.pack_ind = 'N' and L_item_master_row.tsl_base_item = L_item_master_row.item)or
         (L_item_master_row.pack_ind ='Y' and L_item_master_row.simple_pack_ind = 'N'))) then

         --20-May-2010 Tesco HSC/Usha Patil         Defect Id: NBS00017543 Begin
         L_item_range_req := 'N';
         L_range_exists   := 'N';
         --20-May-2010 Tesco HSC/Usha Patil         Defect Id: NBS00017543 End

         if MERCH_DEFAULT_SQL.TSL_GET_REQ_INDS(O_error_message,
                                               L_item_sca_req,
                                               L_item_child_req,
                                               L_spack_setup_req,
                                               L_occ_barcode_req,
                                               L_retail_barcode_req,
                                               --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
                                               --CR347,28-Jul-2010,Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                               L_tsocc_barcode_req,
                                               L_tsretail_barcode_req,
                                               --CR347,28-Jul-2010,Sripriya,Sripriya.karanam@in.tesco.com, End
                                               --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
                                               L_item_master_row.dept,
                                               L_item_master_row.class,
                                               L_item_master_row.subclass) = FALSE then
            return FALSE;
         end if;
         if L_item_sca_req = 'Y' then
            if TSL_SUPPLY_CHAIN_ATTRIB_SQL.CHECK_SCA_EXISTS (O_error_message,
                                                             L_sca_exists,
                                                             rec.tsl_country_id,
                                                             I_item) = FALSE then
               return FALSE;
            end if;

            if L_sca_exists = 'Y' then
               if TSL_SUPPLY_CHAIN_ATTRIB_SQL.TSL_ITEM_SCA_EXIST(O_error_message,
                                                                 L_sca_approved_uk,
                                                                 L_sca_approved_roi,
                                                                 I_item) = FALSE then
                  return FALSE;
               end if;
            end if;
         end if;

         SQL_LIB.SET_MARK('OPEN','C_CHECK_RANGE_REQD','MERCH_HIER_DEFAULT',NULL);
         open C_CHECK_RANGE_REQD(rec.tsl_country_id);
         SQL_LIB.SET_MARK('FETCH','C_CHECK_RANGE_REQD','MERCH_HIER_DEFAULT',NULL);
         fetch C_CHECK_RANGE_REQD into L_item_range_req;
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_RANGE_REQD','MERCH_HIER_DEFAULT',NULL);
         close C_CHECK_RANGE_REQD;

         if L_item_range_req = 'Y' then
            SQL_LIB.SET_MARK('OPEN','C_RANGE_EXISTS','TSL_ITEM_RANGE',NULL);
            open C_RANGE_EXISTS(rec.tsl_country_id);
            SQL_LIB.SET_MARK('FETCH','C_RANGE_EXISTS','TSL_ITEM_RANGE',NULL);
            fetch C_RANGE_EXISTS into L_range_exists;
            SQL_LIB.SET_MARK('CLOSE','C_RANGE_EXISTS','TSL_ITEM_RANGE',NULL);
            close C_RANGE_EXISTS;
         end if;

         if rec.tsl_country_id = 'U' and
           (L_sca_approved_uk or L_item_sca_req = 'N') and
           (L_range_exists = 'Y' or L_item_range_req ='N') and
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            L_valid_supplier = 'Y'
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
            then
            L_complete_uk := 'Y';
         elsif rec.tsl_country_id = 'R' and
           (L_sca_approved_roi or L_item_sca_req = 'N') and
           (L_range_exists = 'Y' or L_item_range_req ='N') and
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            L_valid_supplier = 'Y'
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
           then
            L_complete_roi := 'Y';
         end if;
      --Items other than Base, Complex Pack and Subtran level.
      elsif L_item_master_row.item_level <= L_item_master_row.tran_level then
         if rec.tsl_country_id = 'U'  and
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            L_valid_supplier = 'Y'
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
         then
            L_complete_uk := 'Y';
         elsif rec.tsl_country_id = 'R' and
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            L_valid_supplier = 'Y'
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
            then
            L_complete_roi := 'Y';
         end if;
      end if;
   END LOOP;

   if L_complete_uk = 'Y' and L_complete_roi = 'Y' then
      L_country_auth_ind := 'B';

      if (L_item_master_row.item_level = L_item_master_row.tran_level and
         ((L_item_master_row.item != L_item_master_row.tsl_base_item and
          L_item_master_row.pack_ind = 'N') or
          L_item_master_row.simple_pack_ind = 'Y')) then
         open C_GET_BASE;
         fetch C_GET_BASE into L_base_item;
         close C_GET_BASE;
         SQL_LIB.SET_MARK('OPEN','C_GET_COUNTRY_AUTH','ITEM_MASTER',I_item);
         open C_GET_COUNTRY_AUTH(L_base_item);
         SQL_LIB.SET_MARK('FETCH','C_GET_COUNTRY_AUTH','ITEM_MASTER',I_item);
         fetch C_GET_COUNTRY_AUTH into L_country_auth_ind;
         SQL_LIB.SET_MARK('CLOSE','C_GET_COUNTRY_AUTH','ITEM_MASTER',I_item);
         close C_GET_COUNTRY_AUTH;
         -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
         L_modified_ctry_auth := 'Y';
         -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
      end if;
   elsif L_complete_uk = 'Y' and L_complete_roi = 'N' then
      L_country_auth_ind := 'U';
   elsif L_complete_uk = 'N' and L_complete_roi = 'Y' then
      L_country_auth_ind := 'R';
   end if;

   ---For subtrn levels coping the TSL_COUNTRY_AUTH_IND from Parent Item.
   if L_item_master_row.item_level > L_item_master_row.tran_level then

      SQL_LIB.SET_MARK('OPEN','C_GET_COUNTRY_AUTH','ITEM_MASTER',I_item);
      open C_GET_COUNTRY_AUTH(L_item_master_row.item_parent);
      SQL_LIB.SET_MARK('FETCH','C_GET_COUNTRY_AUTH','ITEM_MASTER',I_item);
      fetch C_GET_COUNTRY_AUTH into L_country_auth_ind;
      SQL_LIB.SET_MARK('CLOSE','C_GET_COUNTRY_AUTH','ITEM_MASTER',I_item);
      close C_GET_COUNTRY_AUTH;
      if L_country_auth_ind != L_item_master_row.tsl_country_auth_ind then
         L_modified_ctry_auth := 'Y';
      end if;
   end if;

   if L_country_auth_ind != 'N' then
      update item_master
         set tsl_country_auth_ind = L_country_auth_ind
       where item = I_item
         and (tsl_country_auth_ind != L_country_auth_ind
          or tsl_country_auth_ind is NULL);

      -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      if L_country_auth_ind = 'B' or L_modified_ctry_auth = 'Y' then
      -- 15-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
         if L_ctry_auth_old = 'U' then
            L_update_country := 'R';
         elsif L_ctry_auth_old = 'R' then
            L_update_country := 'U';
         elsif L_ctry_auth_old = 'N' then
            L_update_country := L_country_auth_ind;
         end if;
      else
         L_update_country := L_country_auth_ind;
      end if;

      if L_update_country = 'B' then
         L_update_country_roi := 'R';
         L_update_country     := 'U';
      end if;

      -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      if L_update_country = L_ctry_auth_old then
         return TRUE;
      end if;
      --Removed the update statement for item_attributes as TSL_UPDATE_ITEM_ATTR is called at the end.
      -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
     --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
     -- CR288d, 2-Aug-2010, Nishant Gupta, nishant.gupta@in.tesco.com (BEGIN)
     SQL_LIB.SET_MARK('OPEN','C_ITEM_ATTR_EPW_COPY','ITEM_ATTRIBUTES',I_item);
     open C_ITEM_ATTR_EPW_COPY(I_item);
     SQL_LIB.SET_MARK('FETCH','C_ITEM_ATTR_EPW_COPY','ITEM_ATTRIBUTES',I_item);
     fetch C_ITEM_ATTR_EPW_COPY into L_epw_item,
                                     L_epw_tsl_country_id,
                                     L_epw_tsl_end_date,
                                     L_tsl_epw_ind;
     SQL_LIB.SET_MARK('CLOSE','C_ITEM_ATTR_EPW_COPY','ITEM_ATTRIBUTES',I_item);
     close C_ITEM_ATTR_EPW_COPY;
     -- CR288d, 2-Aug-2010, Nishant Gupta, nishant.gupta@in.tesco.com (END)

      For C_rec in C_UPD_ITEM_ATTR(I_item) LOOP
         update item_attributes
         --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 Begin
         -- Removed the tsl_launch_date, tsl_dev_end_date updates as it is modified in CR288c
            set tsl_end_date = L_epw_tsl_end_date,
                tsl_epw_ind = L_tsl_epw_ind
         --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 End
          where item = I_item
            and tsl_country_id = C_rec.tsl_country_id
            and tsl_launch_date = C_rec.tsl_launch_date;
      END LOOP;
      --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End

      if L_item_master_row.item_level = L_item_master_row.tran_level and
         L_item_master_row.item = L_item_master_row.tsl_base_item then
         FOR C_rec IN C_GET_VARIANTS LOOP

            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            L_valid_supplier := 'N';
            L_valid_supplier_roi := 'N';
            L_valid := 'N';

            if TSL_VALID_SUPP(O_error_message,
                              L_valid_supplier,
                              C_rec.item,
                              L_update_country) = FALSE then
               return FALSE;
            end if;

            if L_update_country_roi = 'R' then
               if TSL_VALID_SUPP(O_error_message,
                                 L_valid_supplier_roi,
                                 C_rec.item,
                                 L_update_country_roi) = FALSE then
                  return FALSE;
               end if;
            end if;

            if L_country_auth_ind = 'B' and L_update_country_roi = 'R' then
               if L_valid_supplier = 'Y' and L_valid_supplier_roi = 'Y' then
                  L_country_auth_ind := L_country_auth_ind;
                  L_valid := 'Y';
               elsif L_valid_supplier = 'Y' and L_valid_supplier_roi = 'N' then
                  L_country_auth_ind := 'U';
                  L_valid := 'Y';
               elsif L_valid_supplier = 'N' and L_valid_supplier_roi = 'Y' then
                  L_country_auth_ind := 'R';
                  L_valid := 'Y';
               end if;
            elsif L_valid_supplier = 'Y' then
               L_valid := 'Y';
            end if;

            if L_valid = 'Y' then
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
               update item_master
                  set tsl_country_auth_ind = L_country_auth_ind
                where (item = C_rec.item
                --DefNBS023195, 08-Jul-2011 shweta.madnawat@in.tesco.com Begin
                      or item_parent = C_rec.item)
                --DefNBS023195, 08-Jul-2011 shweta.madnawat@in.tesco.com End
                  and (tsl_country_auth_ind != L_country_auth_ind
                   or tsl_country_auth_ind is NULL);

               -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
               --Removed the update statement for item_attributes as TSL_UPDATE_ITEM_ATTR is called at the end.
               -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
               --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
               For C_var in C_UPD_ITEM_ATTR(C_rec.item) LOOP
                  update item_attributes
                     --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 Begin
                     -- Removed the tsl_launch_date, tsl_dev_end_date updates as it is modified in CR288c
                     set tsl_end_date = L_epw_tsl_end_date,
                         tsl_epw_ind = L_tsl_epw_ind
                     --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 End
                where item = C_var.item
                  and tsl_country_id = C_var.tsl_country_id
                  and tsl_launch_date = C_var.tsl_launch_date;
               END LOOP;
               --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End

               For C_var_pack in C_UPDATE_PACKS(C_rec.item) LOOP
                  -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                  L_valid_supplier := 'N';
                  L_valid_supplier_roi := 'N';
                  L_valid := 'N';

                  if TSL_VALID_SUPP(O_error_message,
                                    L_valid_supplier,
                                    C_var_pack.item,
                                    L_update_country) = FALSE then
                     return FALSE;
                  end if;

                  if L_update_country_roi = 'R' then
                     if TSL_VALID_SUPP(O_error_message,
                                       L_valid_supplier_roi,
                                       C_var_pack.item,
                                       L_update_country_roi) = FALSE then
                        return FALSE;
                     end if;
                  end if;

                  if L_country_auth_ind = 'B' and L_update_country_roi = 'R' then
                     if L_valid_supplier = 'Y' and L_valid_supplier_roi = 'Y' then
                        L_country_auth_ind := L_country_auth_ind;
                        L_valid := 'Y';
                     elsif L_valid_supplier = 'Y' and L_valid_supplier_roi = 'N' then
                        L_country_auth_ind := 'U';
                        L_valid := 'Y';
                     elsif L_valid_supplier = 'N' and L_valid_supplier_roi = 'Y' then
                        L_country_auth_ind := 'R';
                        L_valid := 'Y';
                     end if;
                  elsif L_valid_supplier = 'Y' then
                     L_valid := 'Y';
                  end if;

                  if L_valid = 'Y' then
                  -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
                     update item_master
                        set tsl_country_auth_ind = L_country_auth_ind
                      -- 28-May-2010, NBS00017727, Murali N, Begin
                      where (item = C_var_pack.item
                         or item_parent = C_var_pack.item)
                      -- 28-May-2010, NBS00017727, Murali N, End
                        and tsl_country_auth_ind != L_country_auth_ind;

                     -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                     --Removed the update statement for item_attributes as TSL_UPDATE_ITEM_ATTR is called at the end.
                     -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
                     --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
                       For C_var in C_UPD_ITEM_ATTR(C_var_pack.item) LOOP
                        update item_attributes
                           --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 Begin
                           -- Removed the tsl_launch_date, tsl_dev_end_date updates as it is modified in CR288c
                           set tsl_end_date = L_epw_tsl_end_date,
                               tsl_epw_ind = L_tsl_epw_ind
                           --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 End
                         where item = C_var.item
                           and tsl_country_id = C_var.tsl_country_id
                           and tsl_launch_date = C_var.tsl_launch_date;
                     END LOOP;
                     --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
                  -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                  end if;
                  -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
               END LOOP;
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            end if;
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
         END LOOP;
         -- 22-May-2010, DefNBS017594, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         -- 24-May-2010, NBS00017600, Usha Patil, usha.patil@in.tesco.com, Begin
         For C_pack in C_UPDATE_PACKS(L_item_master_row.item) LOOP
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            L_valid_supplier := 'N';
            L_valid_supplier_roi := 'N';
            L_valid := 'N';

            if TSL_VALID_SUPP(O_error_message,
                              L_valid_supplier,
                              C_pack.item,
                              L_update_country) = FALSE then
               return FALSE;
            end if;

            if L_update_country_roi = 'R' then
               if TSL_VALID_SUPP(O_error_message,
                                 L_valid_supplier_roi,
                                 C_pack.item,
                                 L_update_country_roi) = FALSE then
                  return FALSE;
               end if;
            end if;

            if L_country_auth_ind = 'B' and L_update_country_roi = 'R' then
               if L_valid_supplier = 'Y' and L_valid_supplier_roi = 'Y' then
                  L_country_auth_ind := L_country_auth_ind;
                  L_valid := 'Y';
               elsif L_valid_supplier = 'Y' and L_valid_supplier_roi = 'N' then
                  L_country_auth_ind := 'U';
                  L_valid := 'Y';
               elsif L_valid_supplier = 'N' and L_valid_supplier_roi = 'Y' then
                  L_country_auth_ind := 'R';
                  L_valid := 'Y';
               end if;
            elsif L_valid_supplier = 'Y' then
               L_valid := 'Y';
            end if;

            if L_valid = 'Y' then
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
               update item_master
                  set tsl_country_auth_ind = L_country_auth_ind
                -- 28-May-2010, NBS00017727, Murali N, Begin
                where (item = C_pack.item
                       or item_parent = C_pack.item)
                -- 28-May-2010, NBS00017727, Murali N, End
                  and tsl_country_auth_ind != L_country_auth_ind;
               -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
               --Removed the update statement for item_attributes as TSL_UPDATE_ITEM_ATTR is called at the end.
               -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
               --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
                For C_base_pack in C_UPD_ITEM_ATTR(C_pack.item) LOOP
                  update item_attributes
                     --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 Begin
                     -- Removed the tsl_launch_date, tsl_dev_end_date updates as it is modified in CR288c
                     set tsl_end_date = L_epw_tsl_end_date,
                         tsl_epw_ind = L_tsl_epw_ind
                     --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 End
                   where item = C_base_pack.item
                     and tsl_country_id = C_base_pack.tsl_country_id
                     and tsl_launch_date = C_base_pack.tsl_launch_date;
               END LOOP;
              --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            end if;
            -- 09-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
         END LOOP;
         -- 24-May-2010, NBS00017600, Usha Patil, usha.patil@in.tesco.com, End
         -- 22-May-2010, DefNBS017594, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
      end if;

      if L_item_master_row.item_level = L_item_master_row.tran_level then
         FOR C_child in C_UPDATE_CHILD
         LOOP
            update item_master
               set tsl_country_auth_ind = L_country_auth_ind
             where item = C_child.item
               and (tsl_country_auth_ind != L_country_auth_ind
                or tsl_country_auth_ind is NULL);

            -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
            --Removed the update statement for item_attributes as TSL_UPDATE_ITEM_ATTR is called at the end.
            -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
            --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
            For C_rec in C_UPD_ITEM_ATTR(C_child.item) LOOP
               update item_attributes
                  --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 Begin
                  -- Removed the tsl_launch_date, tsl_dev_end_date updates as it is modified in CR288c
                  set tsl_end_date = L_epw_tsl_end_date,
                      tsl_epw_ind = L_tsl_epw_ind
                  --05-Aug-2010 Tesco HSC/Usha Patil        MrgNBS018606 End
                where item = C_rec.item
                  and tsl_country_id = C_rec.tsl_country_id
                  and tsl_launch_date = C_rec.tsl_launch_date;
            END LOOP;
            --MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
         END LOOP;
         --DefNBS023195, 08-Jul-2011 shweta.madnawat@in.tesco.com Begin
         if L_item_master_row.item = L_item_master_row.tsl_base_item then
            FOR C_var in C_GET_VARIANTS LOOP
               FOR C_child in C_GET_VAR_CHILD(C_var.item) LOOP
                  FOR C_rec in C_UPD_ITEM_ATTR(C_child.item) LOOP
                     update item_attributes
                        set tsl_end_date = L_epw_tsl_end_date,
                            tsl_epw_ind = L_tsl_epw_ind
                      where item = C_rec.item
                        and tsl_country_id = C_rec.tsl_country_id
                        and tsl_launch_date = C_rec.tsl_launch_date;
                  END LOOP;
               END LOOP;
            END LOOP;
         end if;
         --DefNBS023195, 08-Jul-2011 shweta.madnawat@in.tesco.com End
      end if;
      -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      if (L_item_master_row.item_level = L_item_master_row.tran_level) and
         (L_item_master_row.pack_ind = 'N' or
          L_item_master_row.pack_ind = 'Y' and L_item_master_row.simple_pack_ind = 'N') then
         if ITEM_APPROVAL_SQL.TSL_UPDATE_SCA (O_error_message,
                                              L_item_master_row.item,
                                              L_ctry_auth_old,
                                              L_update_country) = FALSE then
            return FALSE;
         end if;

         if L_update_country_roi = 'R' then
            if ITEM_APPROVAL_SQL.TSL_UPDATE_SCA (O_error_message,
                                                 L_item_master_row.item,
                                                 L_ctry_auth_old,
                                                 L_update_country_roi) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
      if L_item_master_row.item_level >= L_item_master_row.tran_level then
         SQL_LIB.SET_MARK('OPEN','C_CHK_PARENT_APPR','ITEM_MASTER',I_item);
         open C_CHK_PARENT_APPR;
         SQL_LIB.SET_MARK('FETCH','C_CHK_PARENT_APPR','ITEM_MASTER',I_item);
         fetch C_CHK_PARENT_APPR into L_parent_approved;
         SQL_LIB.SET_MARK('CLOSE','C_CHK_PARENT_APPR','ITEM_MASTER',I_item);
         close C_CHK_PARENT_APPR;
      end if;
      if L_parent_approved = 'Y' or
         L_item_master_row.item_level < L_item_master_row.tran_level or
         (L_item_master_row.item_level = L_item_master_row.tran_level and
          L_item_master_row.pack_ind = 'Y' and
          L_item_master_row.simple_pack_ind = 'N')then
         if ITEM_APPROVAL_SQL.TSL_UPDATE_ITEM_ATTR (O_error_message,
                                                    I_item,
                                                    L_ctry_auth_old,
                                                    L_update_country,
                                                    L_future_date) = FALSE then
            return FALSE;
         end if;

         if L_update_country_roi = 'R' then
            if ITEM_APPROVAL_SQL.TSL_UPDATE_ITEM_ATTR (O_error_message,
                                                       I_item,
                                                       L_ctry_auth_old,
                                                       L_update_country_roi,
                                                       L_future_date) = FALSE then
               return FALSE;
            end if;
         end if;

         if L_item_master_row.item_level = L_item_master_row.tran_level and
            L_item_master_row.pack_ind = 'N' then
            FOR C_rec in C_VARIANTS LOOP
               if ITEM_APPROVAL_SQL.TSL_UPDATE_ITEM_ATTR (O_error_message,
                                                          C_rec.item,
                                                          L_ctry_auth_old,
                                                          L_update_country,
                                                          L_future_date) = FALSE then
                  return FALSE;
               end if;

               if L_update_country_roi = 'R' then
                  if ITEM_APPROVAL_SQL.TSL_UPDATE_ITEM_ATTR (O_error_message,
                                                             C_rec.item,
                                                             L_ctry_auth_old,
                                                             L_update_country_roi,
                                                             L_future_date) = FALSE then
                     return FALSE;
                  end if;
               end if;
            END LOOP;
         end if;
      end if;
      -- 13-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   end if;

   if ITEM_ATTRIB_SQL.TSL_CASCADE_EPW(O_error_message,
                                      I_item,
                                      L_ctry_auth_old) = FALSE then
       return FALSE;
   end if;
   -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com Begin
   --DefNBS022105, 28-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
   if L_item_master_row.tsl_mu_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN', 'C_CHK_COMMON', I_item, NULL);
      open C_CHK_COMMON;
      SQL_LIB.SET_MARK('FETCH', 'C_CHK_COMMON', I_item, NULL);
      fetch C_CHK_COMMON into L_chk_common;

      if C_CHK_COMMON%NOTFOUND and L_item_master_row.item_number_type = 'TPNB' then
         --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
         --O_error_message := 'TSL_NO_MU_ITEM';
         --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
         update item_master
                  set tsl_country_auth_ind = L_ctry_auth_old
                where item = I_item;
         --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
         --return FALSE;
         --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End

      elsif C_CHK_COMMON%FOUND and L_item_master_row.item_number_type = 'TPNB' then
         --MU item country id
         if ITEM_ATTRIB_SQL.TSL_GET_ITEM_CTRY_IND(O_error_message,
                                                  I_item,
                                                  L_muitem_country_id) =FALSE then
            return FALSE;
         end if;
         -----
         FOR C_rec IN C_EXIST_MU_ITEM LOOP
            --Base item ctyr id
            if ITEM_ATTRIB_SQL.TSL_GET_ITEM_CTRY_IND(O_error_message,
                                                     C_rec.item,
                                                     L_base_country_id) =FALSE then
               return FALSE;
            end if;
            --
            --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
            --DefNBS022406, Added parameter to the cursor
            FOR C_rec_store IN C_MU_STORE(C_rec.item) LOOP
            --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
               open C_MU_STORE_CNTRY (c_rec_store.store);
               fetch C_MU_STORE_CNTRY into L_store_cntry;
            --

               if L_muitem_country_id is not null and
                  L_base_country_id is not null and
                  L_store_cntry is not null and
                  L_muitem_country_id <> L_base_country_id then
                  if L_muitem_country_id = 'U' and L_base_country_id = 'R'
                                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                                               and L_valid_record = '0' then
                                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --O_error_message := 'TSL_UK_MU';
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                     --DefNBS022406, commenting and moving the statement to the end
                     L_valid_record := '0';
                     /*
                     update item_master
                              set tsl_country_auth_ind = L_ctry_auth_old
                            where item = I_item;
                     */
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --return FALSE;
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                  elsif L_muitem_country_id = 'R' and L_base_country_id = 'U'
                  	                              --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                  	                              and L_valid_record = '0' then
                  	                              --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --O_error_message := 'TSL_ROI_MU';
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                     --DefNBS022406, commenting and moving the statement to the end
                     L_valid_record := '0';
                     /*
                     update item_master
                              set tsl_country_auth_ind = L_ctry_auth_old
                            where item = I_item;
                     */
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --return FALSE;
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                  --DefNBS022194, 08-Apr-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                  elsif L_muitem_country_id = 'B' and L_base_country_id not in ('B','U','R')
                  	                              --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                  	                              and L_valid_record = '0' then
                  	                              --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                  --DefNBS022194, 08-Apr-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --O_error_message := 'TSL_UKROI_MU';
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                     --DefNBS022406, commenting and moving the statement to the end
                     L_valid_record := '0';
                     /*
                     update item_master
                              set tsl_country_auth_ind = L_ctry_auth_old
                            where item = I_item;
                     */
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --return FALSE;
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                  elsif L_muitem_country_id <> 'B' and L_base_country_id = 'B'
                  	                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                  	                               and L_valid_record = '0' then
                  	                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --O_error_message := 'TSL_UKROI_MUBASE';
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                     --DefNBS022406, commenting and moving the statement to the end
                     --DefNBS022406A, 02-May-2011, Chandrachooda, Chandrachooda.Hirannaiah@in.tesco.com begin
                     null;
                     /*
                     L_valid_record := '0';
                     */
                     --DefNBS022406A, 02-May-2011, Chandrachooda, Chandrachooda.Hirannaiah@in.tesco.com end
                     /*
                     update item_master
                              set tsl_country_auth_ind = L_ctry_auth_old
                            where item = I_item;
                     */
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --return FALSE;
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                  --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin

                  -- DefNBS022553 11-May-2011 Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com Begin
                  -- else
                  --   L_valid_record := '1';
                  -- DefNBS022553 11-May-2011 Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com End

                  --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                  end if;
               end if;
               if L_muitem_country_id is not null and
                  L_base_country_id is not null and
                  L_store_cntry is not null then
                  if (L_muitem_country_id = 'U' and L_base_country_id = 'U') and L_store_cntry= 'R'
                                                --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                                                and L_valid_record = '0' then
                                                --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --O_error_message := 'TSL_UK_MU_LOC';
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                     --DefNBS022406, commenting and moving the statement to the end
                     L_valid_record := '0';
                     /*
                     update item_master
                              set tsl_country_auth_ind = L_ctry_auth_old
                            where item = I_item;
                     */
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --return FALSE;
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                  elsif (L_muitem_country_id = 'R' and L_base_country_id = 'R') and L_store_cntry= 'U'
                  	                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                  	                               and L_valid_record = '0' then
                  	                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --O_error_message := 'TSL_ROI_MU_LOC';
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                     --DefNBS022406, commenting and moving the statement to the end
                     L_valid_record := '0';
                     /*
                     update item_master
                              set tsl_country_auth_ind = L_ctry_auth_old
                            where item = I_item;
                     */
                     --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                     --return FALSE;
                     --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                  --DefNBS022406A, 02-May-2011, Chandrachooda, Chandrachooda.Hirannaiah@in.tesco.com begin
                  elsif L_muitem_country_id = 'U' and L_base_country_id = 'R' and L_valid_record = '0' then
                     L_valid_record := '0';
                  elsif L_muitem_country_id = 'R' and L_base_country_id = 'U' and L_valid_record = '0' then
                     L_valid_record := '0';
                  elsif L_muitem_country_id = 'B' and L_base_country_id not in ('B','U','R') and L_valid_record = '0' then
                  	 L_valid_record := '0';
                  --DefNBS022406A, 02-May-2011, Chandrachooda, Chandrachooda.Hirannaiah@in.tesco.com begin
                  /*
                  elsif L_muitem_country_id <> 'B' and L_base_country_id = 'B' and L_valid_record = '0' then
                  	 L_valid_record := '0';
                  */
                  --DefNBS022406A, 02-May-2011, Chandrachooda, Chandrachooda.Hirannaiah@in.tesco.com end
                  --DefNBS022406A, 02-May-2011, Chandrachooda, Chandrachooda.Hirannaiah@in.tesco.com end
                  --DefNBS022194, 08-Apr-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                  elsif (L_muitem_country_id = 'B' and L_base_country_id in ('B','U','R')) and L_store_cntry= 'U'
                  	                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                  	                               and L_valid_record = '0' then
                  	                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                  --DefNBS022194, 08-Apr-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                     L_mu_uk_store := 'Y';
                  --DefNBS022194, 08-Apr-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
                  elsif (L_muitem_country_id = 'B' and L_base_country_id in ('B','U','R')) and L_store_cntry= 'R'
                  	                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                  	                               and L_valid_record = '0' then
                  	                               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                  --DefNBS022194, 08-Apr-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
                     L_mu_roi_store := 'Y';
                  --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                  else
                     L_valid_record := 1;
                  --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                  end if;
               end if;
               close C_MU_STORE_CNTRY;
            end LOOP; -- end loop for C_rec_store
            --DefNBS022194, 08-Apr-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
            if (L_muitem_country_id = 'B' and ((L_base_country_id = 'U' and L_mu_uk_store != 'Y') or (L_base_country_id = 'R' and L_mu_roi_store != 'Y') or (L_base_country_id = 'B' and (L_mu_uk_store != 'Y' or L_mu_roi_store != 'Y'))))
                                          --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                                          /*and L_valid_record = '0'*/ then
                                          --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
            --DefNBS022194, 08-Apr-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
               --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
               --O_error_message := 'TSL_BOTH_MU_LOC';
               --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
               --DefNBS022406, commenting and moving the statement to the end
               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
               /*L_valid_record := '0';*/
               NULL;
               /*
               update item_master
                        set tsl_country_auth_ind = L_ctry_auth_old
                      where item = I_item;
               */
               --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
               --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com Begin
               --return FALSE;
               --DefNBS022125, 29-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End

            -- DefNBS022553 11-May-2011 Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com Begin
            elsif (L_muitem_country_id = 'B' and ((L_base_country_id = 'U' and L_mu_uk_store = 'Y') or (L_base_country_id = 'R' and L_mu_roi_store = 'Y') or (L_base_country_id = 'B' and (L_mu_uk_store != 'Y' or L_mu_roi_store != 'Y')))) then
               L_valid_record := 1;
            -- DefNBS022553 11-May-2011 Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com End

            end if;
            --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
            --DefNBS022406, if no valid record present, then revert back auth ind
            if L_valid_record = '0' then
               update item_master
                        set tsl_country_auth_ind = L_ctry_auth_old
                      where item = I_item;
            end if;
            --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
            L_mu_uk_store := 'N';
            L_mu_roi_store := 'N';
         end LOOP; -- end loop for C_rec
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CHK_COMMON', I_item, NULL);
      close C_CHK_COMMON;
   end if;
   --DefNBS022105, 28-MAR-2011, Suman Guha Mustafi, suman.mustafi@in.tesco.com End
    -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com End

   return TRUE;
EXCEPTION
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
  return FALSE;
END TSL_UPDATE_ITEM_CTRY;
-----------------------------------------------------------------------------------------
-- Function:    TSL_TPNB_UPDATE_ITEM_CTRY
-- Purpose:     To update the TSL_COUNTRY_AUTH_IND for base items.
-----------------------------------------------------------------------------------------
FUNCTION TSL_TPNB_UPDATE_ITEM_CTRY (O_error_message    IN OUT      RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item             IN          ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program                    VARCHAR2(60) := 'ITEM_MASTER_SQL.TSL_TPNB_UPDATE_ITEM_CTRY';

   CURSOR C_LVL2_CHILD is
   select item
     from item_master
    where item_parent = I_item
      and item_level  = tran_level
      and pack_ind    = 'N'
      and item        = tsl_base_item
      and status      = 'A';
BEGIN
   FOR C_rec in C_LVL2_CHILD LOOP
      if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                              C_rec.item) = FALSE then
         return FALSE;
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
END TSL_TPNB_UPDATE_ITEM_CTRY;
-------------------------------------------------------------------------------------------------
--MrgNBS017783,03-Jun-2010,(merge from 3.5b to 3.5f)Sripriya,sripriya.karanam@in.tesco.com End
-------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- CR288d, 2-Aug-2010, Nishant Gupta, nishant.gupta@in.tesco.com (BEGIN)
-----------------------------------------------------------------------------------------
-- Function:    TSL_GET_AUTH_CTRY
-- Purpose:     To get the TSL_COUNTRY_AUTH_IND from item_master for the item passed.
-----------------------------------------------------------------------------------------
FUNCTION TSL_GET_AUTH_CTRY(O_error_message IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                           I_item          IN      ITEM_MASTER.ITEM%TYPE,
                           O_country       IN OUT  VARCHAR2)
    RETURN BOOLEAN is

   L_program                    VARCHAR2(60) := 'ITEM_MASTER_SQL.TSL_GET_AUTH_CTRY';

   CURSOR C_GET_COUNTRY_AUTH is
   select NVL(tsl_country_auth_ind,'N')
     from item_master
    where item = I_item;

BEGIN

     SQL_LIB.SET_MARK('OPEN','C_GET_COUNTRY_AUTH','ITEM_MASTER',NULL);
     open C_GET_COUNTRY_AUTH;
     SQL_LIB.SET_MARK('FETCH','C_GET_COUNTRY_AUTH','ITEM_MASTER',NULL);
     fetch C_GET_COUNTRY_AUTH into O_country;
     SQL_LIB.SET_MARK('CLOSE','C_GET_COUNTRY_AUTH','ITEM_MASTER',NULL);
     close C_GET_COUNTRY_AUTH;

   return TRUE;

EXCEPTION
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
  return FALSE;
END TSL_GET_AUTH_CTRY;
-----------------------------------------------------------------------------------------
-- CR288d, 2-Aug-2010, Nishant Gupta, nishant.gupta@in.tesco.com (END)
--------------------------------------------------------------------------------------------------------
-- 09-Jul-2010, CR288C, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
--------------------------------------------------------------------------------------------------------
FUNCTION  TSL_GET_CHILD_ITEMS (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_child_item     IN OUT ITEM_MASTER_SQL.CHILD_ITEM_TBL,
                               I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_GET_CHILD_ITEMS';
   L_count                  NUMBER(9)    := 0;
   L_launch_dt_uk           DATE;
   L_launch_dt_roi          DATE;
   L_tslsca_exists_uk       BOOLEAN := FALSE;
   L_tslsca_exists_roi      BOOLEAN := FALSE;

   CURSOR C_GET_CHILD_ITEM is
   select DISTINCT item,
          item_number_type,
          item_desc,
          --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 BEGIN
          simple_pack_ind,
          pack_ind,
          item_level,
          tran_level
          --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 END
     from (select im.item,
                  item_number_type,
                  item_desc,
                  --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 BEGIN
                  simple_pack_ind,
                  pack_ind,
                  item_level,
                  tran_level
                  --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 END
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
          item_number_type,
          item_desc,
          --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 BEGIN
          simple_pack_ind,
          pack_ind,
          item_level,
          tran_level
          --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 END
     from item_master im
    start with im.item = I_item
  connect by prior im.item = im.item_parent);
  -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com Begin
  --04-Mar-2010, CR381, Iman Chatterjee, iman.chatterjee@in.tesco.com, Begin
    CURSOR C_CHK_MU is
       select NVL(tsl_mu_ind,'N')
        from item_master
        where item = I_item;

     CURSOR C_CHK_MU_CNTRY_TYPE is
        /*select NVL(im.tsl_country_auth_ind,'N'), im.item_number_type
          from  tsl_mu_loc tml, item_master im
         where tml.item = im.item
           and tml.mu_item = I_item;*/
   --29-Mar-2011, DefNBS00022125, Iman Chatterjee, iman.chatterjee@in.tesco.com, Begin
         select NVL(im.tsl_country_auth_ind,'N'), im.item_number_type
          from  tsl_mu_loc tml, item_master im
         where tml.item = im.item
           and tml.mu_item = I_item
         union all
         select NVL(im.tsl_country_auth_ind,'N'), im.item_number_type
          from  tsl_mu_loc tml, item_master im
         where tml.item = im.item
         -- DefNBS022347, 15-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com Begin
           and tml.mu_item in (select item from item_master where item_parent = I_item);
           -- and tml.mu_item = (select item from item_master where item_parent = I_item);
         -- DefNBS022347, 15-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com End
   --29-Mar-2011, DefNBS00022125, Iman Chatterjee, iman.chatterjee@in.tesco.com, End
      L_chk_mu             VARCHAR2(1) := 'N';
      L_chk_common         VARCHAR2(1) := 'N';
      L_item_type          ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
      L_country            ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE;
  --29-Mar-2011, DefNBS00022125, Iman Chatterjee, iman.chatterjee@in.tesco.com, Begin
      L_set_flg            VARCHAR2(1) := 'N';
  --29-Mar-2011, DefNBS00022125, Iman Chatterjee, iman.chatterjee@in.tesco.com, End
  --04-Mar-2010, CR381, Iman Chatterjee, iman.chatterjee@in.tesco.com, End
  -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com End

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
                    'C_GET_CHILD_ITEM',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   FOR C_rec IN C_GET_CHILD_ITEM
   LOOP
      ---
      --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 BEGIN
      if C_rec.item_level <= C_rec.tran_level then
      --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 END
      ---
      L_count := L_count + 1 ;
      O_child_item(L_count).item := C_rec.item;
      O_child_item(L_count).item_number_type := C_rec.item_number_type;
      O_child_item(L_count).item_desc := C_rec.item_desc;
      O_child_item(L_count).attributes := 'Launch Date';
      -- Getting item UK launch date
      if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                             C_rec.item,
                                             L_launch_dt_uk,
                                             'U') = FALSE then
         return FALSE;
      end if;
      -- Getting item ROI launch date
      if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                             C_rec.item,
                                             L_launch_dt_roi,
                                             'R') = FALSE then
         return FALSE;
      end if;
      ---
      if L_launch_dt_uk is NOT NULL then
         O_child_item(L_count).uk_ind := 'Y';
      else
         O_child_item(L_count).uk_ind := 'N';
      end if;
      ---
      if L_launch_dt_roi is NOT NULL then
         O_child_item(L_count).roi_ind := 'Y';
      else
         O_child_item(L_count).roi_ind := 'N';
      end if;
      ---
         --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 BEGIN
         if (c_rec.simple_pack_ind ='N' and c_rec.pack_ind ='N') or
            (c_rec.simple_pack_ind ='N' and c_rec.pack_ind ='Y') then
         --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 END

      L_count := L_count + 1 ;
      O_child_item(L_count).item := C_rec.item;
      O_child_item(L_count).item_number_type := C_rec.item_number_type;
      O_child_item(L_count).item_desc := C_rec.item_desc;
      O_child_item(L_count).attributes := 'Range';
      -- Getting item UK Range info
      if TSL_RANGE_ATTRIB_SQL.ITEM_RANGE_EXISTS (O_error_message,
                                                 O_child_item(L_count).uk_ind,
                                                 C_rec.item,
                                                 NULL) = FALSE then
         return FALSE;
      end if;
      ---
      -- Getting item ROI Range info
      if TSL_RANGE_ATTRIB_SQL.ITEM_RANGE_EXISTS_ROI (O_error_message,
                                                     O_child_item(L_count).roi_ind,
                                                     C_rec.item,
                                                     NULL) = FALSE then
         return FALSE;
      end if;
      ---
      L_count := L_count + 1 ;
      O_child_item(L_count).item := C_rec.item;
      O_child_item(L_count).item_number_type := C_rec.item_number_type;
      O_child_item(L_count).item_desc := C_rec.item_desc;
      O_child_item(L_count).attributes := 'Supply Chain';
      -- Getting item UK and ROI supply chain info
      if TSL_SUPPLY_CHAIN_ATTRIB_SQL.TSL_ITEM_SCA_EXIST (O_error_message,
                                                         L_tslsca_exists_uk,
                                                         L_tslsca_exists_roi,
      -- CR288c Fix, 22-Jul-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com Begin
                                                         --I_item
                                                         C_rec.item) = FALSE then
      -- CR288c Fix, 22-Jul-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com End
         return FALSE;
      end if;
      ---
      if L_tslsca_exists_uk then
         O_child_item(L_count).uk_ind := 'Y';
      else
         O_child_item(L_count).uk_ind := 'N';
      end if;
      ---
      if L_tslsca_exists_roi then
         O_child_item(L_count).roi_ind := 'Y';
      else
         O_child_item(L_count).roi_ind := 'N';
      end if;
         --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 BEGIN
         end if;
         --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 END
      ---
      L_count := L_count + 1 ;
      O_child_item(L_count).item := C_rec.item;
      O_child_item(L_count).item_number_type := C_rec.item_number_type;
      O_child_item(L_count).item_desc := C_rec.item_desc;
      O_child_item(L_count).attributes := 'Valid Supplier';
      ---
      -- 12-Jul-2010, CR288C, Vinutha R, Vinutha.Raju@in.tesco.com, Begin
      -- Getting item UK and ROI valid supplier info
      -- Getting item UK valid supplier info
      if TSL_VALID_SUPP (O_error_message,
                         O_child_item(L_count).uk_ind,
                         -- 27-Jul-2010, CR288C-Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                         C_rec.item,
                         -- 27-Jul-2010, CR288C-Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                         'U') = FALSE then
         return FALSE;
      end if;
      ---
       -- Getting item ROI valid supplier info
      if TSL_VALID_SUPP (O_error_message,
                         O_child_item(L_count).roi_ind,
                         -- 27-Jul-2010, CR288C-Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                         C_rec.item,
                         -- 27-Jul-2010, CR288C-Fix, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                         'R') = FALSE then
         return FALSE;
      end if;
      ---
       -- 12-Jul-2010, CR288C, Vinutha R, Vinutha.Raju@in.tesco.com, End
      --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 BEGIN
      -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com Begin
      --04-Mar-2010, CR381, Iman Chatterjee, iman.chatterjee@in.tesco.com, Begin
      --29-Mar-2011, DefNBS00022125, Iman Chatterjee, iman.chatterjee@in.tesco.com, Begin
      L_set_flg := 'N';
      --29-Mar-2011, DefNBS00022125, Iman Chatterjee, iman.chatterjee@in.tesco.com, Begin
      SQL_LIB.SET_MARK('OPEN', 'C_CHK_MU_CNTRY_TYPE', I_item, NULL);
      open C_CHK_MU_CNTRY_TYPE;

      SQL_LIB.SET_MARK('FETCH', 'C_CHK_MU_CNTRY_TYPE', I_item, NULL);
      fetch C_CHK_MU_CNTRY_TYPE into L_chk_common, L_item_type;
      if C_CHK_MU_CNTRY_TYPE%FOUND then
        if TSL_GET_AUTH_CTRY(O_error_message,
                                C_rec.item,
                                L_country) = FALSE then
              return FALSE;
        end if;
        SQL_LIB.SET_MARK('OPEN', 'C_CHK_MU', I_item, NULL);
        open C_CHK_MU;

        SQL_LIB.SET_MARK('FETCH', 'C_CHK_MU', I_item, NULL);
        fetch C_CHK_MU into L_chk_mu;
        SQL_LIB.SET_MARK('CLOSE', 'C_CHK_MU', I_item, NULL);
        close C_CHK_MU;

        /*if (L_chk_mu = 'Y' and L_country <> 'B' and L_item_type = 'TPNB') then*/
        if (L_chk_mu = 'Y' and L_country <> 'B') then
           if L_country = 'U' and L_chk_common not in ('R','B')then
             L_count := L_count + 1 ;
             O_child_item(L_count).item := C_rec.item;
             O_child_item(L_count).item_number_type := C_rec.item_number_type;
             O_child_item(L_count).item_desc := C_rec.item_desc;
             O_child_item(L_count).attributes := 'MU ITEM LINK';
             O_child_item(L_count).roi_ind := 'N';
             O_child_item(L_count).uk_ind := 'Y';
             L_set_flg := 'Y';
           elsif L_country = 'R' and L_chk_common not in ('U','B')then
             L_count := L_count + 1 ;
             O_child_item(L_count).item := C_rec.item;
             O_child_item(L_count).item_number_type := C_rec.item_number_type;
             O_child_item(L_count).item_desc := C_rec.item_desc;
             O_child_item(L_count).attributes := 'MU ITEM LINK';
             O_child_item(L_count).roi_ind := 'Y';
             O_child_item(L_count).uk_ind := 'N';
             L_set_flg := 'Y';
           end if;
        end if;
        --29-Mar-2011, DefNBS00022125, Iman Chatterjee, iman.chatterjee@in.tesco.com, Begin
        if (L_chk_mu = 'Y' and L_country in ('B','U','R') and c_rec.item_number_type = 'TPNB' and L_set_flg = 'N') then
             L_count := L_count + 1 ;
             O_child_item(L_count).item := C_rec.item;
             O_child_item(L_count).item_number_type := C_rec.item_number_type;
             O_child_item(L_count).item_desc := C_rec.item_desc;
             O_child_item(L_count).attributes := 'MU ITEM LINK';
             O_child_item(L_count).roi_ind := 'Y';
             O_child_item(L_count).uk_ind := 'Y';
        end if;
        --29-Mar-2011, DefNBS00022125, Iman Chatterjee, iman.chatterjee@in.tesco.com, End
     end if;
     SQL_LIB.SET_MARK('CLOSE', 'C_CHK_MU_CNTRY_TYPE', I_item, NULL);
     close C_CHK_MU_CNTRY_TYPE;
     --04-Mar-2010, CR381, Iman Chatterjee, iman.chatterjee@in.tesco.com, End
     -- MrgNBS022368 18-Apr-2011 Parvesh parveshkumar.rulhan@in.tesco.com End
      end if;
      --DefNBS018994 Sriranjitha , Sriranjitha.Bhgai@in.tesco.com 02-SEP-2010 END
   END LOOP;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_CHILD_ITEM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CHILD_ITEM',
                          'ITEM_MASTER',
                          'Item = ' || I_item);
         close C_GET_CHILD_ITEM;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_CHILD_ITEMS;
--------------------------------------------------------------------------------------------------------
-- 09-Jul-2010, CR288C, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- 09_Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
--------------------------------------------------------------------------------------------------------
-- Function to check whether the supplier is valid or no.
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_VALID_SUPP (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_valid_supp      IN OUT VARCHAR2,
                         I_item            IN     ITEM_MASTER.ITEM%TYPE,
                         I_country_id      IN     VARCHAR2)
   RETURN BOOLEAN IS
L_program VARCHAR2(64) := 'TSL_VALID_SUPP';

   CURSOR C_VALID_SUPP is
   select 'Y'
     from item_supplier isp,
          sups sup,
          item_supp_country isc
    where isp.item = I_item
      and isp.supplier = sup.supplier
      and (sup.dsd_ind = 'N'
       or sup.tsl_shared_supp_ind = 'Y'
       or sup.duns_number = decode(I_country_id,'U','GB','IE'))
      and isc.item = isp.item
      and isc.supplier = isp.supplier;
BEGIN
   SQL_LIB.SET_MARK('OPEN','C_VALID_SUPP','ITEM_SUPPLIER',I_item);
   open C_VALID_SUPP;
   SQL_LIB.SET_MARK('FETCH','C_VALID_SUPP','ITEM_SUPPLIER',I_item);
   fetch C_VALID_SUPP into O_valid_supp;
   if C_VALID_SUPP%NOTFOUND then
      O_valid_supp := 'N';
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_VALID_SUPP','ITEM_SUPPLIER',I_item);
   close C_VALID_SUPP;

   return TRUE;
EXCEPTION
   when OTHERS then
      if C_VALID_SUPP%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_VALID_SUPP',
                          'ITEM_SUPPLIER',
                          I_item);
         close C_VALID_SUPP;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
         return FALSE;
END TSL_VALID_SUPP;
--------------------------------------------------------------------------------------------------------
-- 09_Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
--------------------------------------------------------------------------------------------------------
-- 09-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
--------------------------------------------------------------------------------------------------------
FUNCTION  TSL_GET_COUNTRY_SINK (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_country_sink   IN OUT VARCHAR2,
                                I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_GET_COUNTRY_SINK';
   L_item                   ITEM_MASTER.ITEM%TYPE;

   CURSOR C_GET_CTRY_SINK is
   select 'x'
     from item_master im1,
          item_master im2
    where im1.item_parent = im2.item_parent
      and im1.item_parent = I_item
      and im1.tsl_owner_country != im2.tsl_owner_country
      and rownum < 2;

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
   O_country_sink := 'Y';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CTRY_SINK',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   open C_GET_CTRY_SINK;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_CTRY_SINK',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   fetch C_GET_CTRY_SINK into L_item;
   ---
   if C_GET_CTRY_SINK%FOUND then
      O_country_sink := 'N';
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CTRY_SINK',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   close C_GET_CTRY_SINK;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_CTRY_SINK%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CTRY_SINK',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_GET_CTRY_SINK;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
         return FALSE;
END TSL_GET_COUNTRY_SINK;
--------------------------------------------------------------------------------------------------------
FUNCTION  TSL_UPD_ITEM_SUPP (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_owner_country  IN     VARCHAR2,
                             I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_UPD_ITEM_SUPP';
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011, Begin
   L_table       VARCHAR2(30) := 'ITEM_SUPPLIER';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,End

   CURSOR C_LOCK_ITEM_SUPP is
   select 'x'
     from item_supplier
    where item = I_item
      for update nowait;

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
   if I_owner_country is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_owner_country',
                                                  L_program,
                                                  NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ITEM_SUPP',
                    'ITEM_SUPPLIER',
                    'ITEM: ' ||I_item);
   open C_LOCK_ITEM_SUPP;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ITEM_SUPP',
                    'ITEM_SUPPLIER',
                    'ITEM: ' ||I_item);
   close C_LOCK_ITEM_SUPP;
   ---
   SQL_LIB.SET_MARK('UPDATE',
                    'NULL',
                    'ITEM_SUPPLIER',
                    'ITEM: ' ||I_item);
   update item_supplier
      set tsl_owner_country = I_owner_country
    where item = I_item;
   ---
   return TRUE;
   ---
EXCEPTION
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011, Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,End

   when OTHERS then
      if C_LOCK_ITEM_SUPP%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_ITEM_SUPP',
                          'ITEM_SUPPLIER',
                          'ITEM: ' ||I_item);
         close C_LOCK_ITEM_SUPP;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
         return FALSE;
END TSL_UPD_ITEM_SUPP;
--------------------------------------------------------------------------------------------------------
FUNCTION  TSL_CASCADE_OWNER_CTRY (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_owner_country  IN     VARCHAR2,
                                  I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_CASCADE_OWNER_CTRY';
   L_base_item              BOOLEAN      := FALSE;
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011, Begin
   L_table       VARCHAR2(30) := 'ITEM_MASTER/ITEM_SUPPLIER';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,End

   CURSOR C_LOCK_CHILD_ITEM is
   select 'x'
     from item_master ima
    where ima.item in (select child_item.item
                        from (select DISTINCT item,
                                     item_number_type,
                                     item_desc
                                from (select im.item,
                                             item_number_type,
                                             item_desc
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
                                     item_number_type,
                                     item_desc
                                from item_master im
                               start with im.item = I_item
                             connect by prior im.item = im.item_parent)) child_item
                        where child_item.item != I_item)
      for update nowait;

   CURSOR C_LOCK_CHILD_SUPPLIER is
   select 'x'
     from item_supplier ist
    where ist.item in (select child_item.item
                        from (select DISTINCT item,
                                     item_number_type,
                                     item_desc
                                from (select im.item,
                                             item_number_type,
                                             item_desc
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
                                     item_number_type,
                                     item_desc
                                from item_master im
                               start with im.item = I_item
                             connect by prior im.item = im.item_parent)) child_item
                        where child_item.item != I_item)
      for update nowait;
   ---
   -- 06-Sep-2010, DefNBS019049, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   CURSOR C_LOCK_IM_VARIANT is
   select 'x'
     from item_master ima
    where ima.item in (select im2.item
                         from item_master im1,
                              item_master im2
                        where im1.tsl_base_item = I_item
                          and im1.item != im1.tsl_base_item
                          and (im2.item = im1.item
                           or im2.item_parent = im1.item)
                       UNION
                       select im2.item
                         from item_master im1,
                              item_master im2,
                              packitem pi
                        where pi.pack_no = im1.item
                          and (im2.item = im1.item
                           or  im2.item_parent = im1.item)
                          and pi.item in (select im2.item
                         from item_master im1, item_master im2
                        where im1.tsl_base_item = I_item
                          and im1.item != im1.tsl_base_item
                          and (im2.item = im1.item or im2.item_parent = im1.item)))
      for update nowait;
   ---
   CURSOR C_LOCK_VAR_SUPPLIER is
   select 'x'
     from item_supplier ist
    where ist.item in (select im2.item
                         from item_master im1,
                              item_master im2
                        where im1.tsl_base_item = I_item
                          and im1.item != im1.tsl_base_item
                          and (im2.item = im1.item
                           or im2.item_parent = im1.item)
                       UNION
                       select im2.item
                         from item_master im1,
                              item_master im2,
                              packitem pi
                        where pi.pack_no = im1.item
                          and (im2.item = im1.item
                           or  im2.item_parent = im1.item)
                          and pi.item in (select im2.item
                         from item_master im1, item_master im2
                        where im1.tsl_base_item = I_item
                          and im1.item != im1.tsl_base_item
                          and (im2.item = im1.item or im2.item_parent = im1.item)))
      for update nowait;
   ---
   -- 06-Sep-2010, DefNBS019049, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
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
   if I_owner_country is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_owner_country',
                                                  L_program,
                                                  NULL);
      return FALSE;
   end if;
   ---
   -- 06-Sep-2010, DefNBS019049, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   if TSL_BASE_VARIANT_SQL.VALIDATE_BASE_ITEM (O_error_message,
                                               L_base_item,
                                               I_item) = FALSE then
      return FALSE;
   end if;
   -- 06-Sep-2010, DefNBS019049, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_CHILD_ITEM',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   open C_LOCK_CHILD_ITEM;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_CHILD_ITEM',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   close C_LOCK_CHILD_ITEM;
   ---
   SQL_LIB.SET_MARK('UPDATE',
                    'NULL',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);

   update item_master ima
      set ima.tsl_owner_country = I_owner_country
    where ima.item in (select child_item.item
                     from (select DISTINCT item,
                                  item_number_type,
                                  item_desc
                             from (select im.item,
                                          item_number_type,
                                          item_desc
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
                                          item_number_type,
                                          item_desc
                                     from item_master im
                                    start with im.item = I_item
                                  connect by prior im.item = im.item_parent)) child_item
                    where child_item.item != I_item);
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_CHILD_SUPPLIER',
                    'ITEM_SUPPLIER',
                    'ITEM: ' ||I_item);
   open C_LOCK_CHILD_SUPPLIER;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_CHILD_SUPPLIER',
                    'ITEM_SUPPLIER',
                    'ITEM: ' ||I_item);
   close C_LOCK_CHILD_SUPPLIER;
   ---
   SQL_LIB.SET_MARK('UPDATE',
                    'NULL',
                    'ITEM_SUPPLIER',
                    'ITEM: ' ||I_item);
   update item_supplier its
      set its.tsl_owner_country = I_owner_country
    where its.item   in (select child_item.item
                           from (select DISTINCT item,
                                        item_number_type,
                                        item_desc
                                   from (select im.item,
                                                item_number_type,
                                                item_desc
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
                                       item_number_type,
                                       item_desc
                                  from item_master im
                                 start with im.item = I_item
                               connect by prior im.item = im.item_parent)) child_item
                          where child_item.item != I_item);
   ---
   -- 06-Sep-2010, DefNBS019049, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   if L_base_item then
      ---
      SQL_LIB.SET_MARK('OPEN',
                      'C_LOCK_IM_VARIANT',
                      'ITEM_MASTER',
                      'ITEM: ' ||I_item);
      open C_LOCK_IM_VARIANT;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                      'C_LOCK_IM_VARIANT',
                      'ITEM_MASTER',
                      'ITEM: ' ||I_item);
      close C_LOCK_IM_VARIANT;
      ---
      SQL_LIB.SET_MARK('UPDATE',
                      'NULL',
                      'ITEM_MASTER',
                      'ITEM: ' ||I_item);
      ---
     update item_master ima
        set ima.tsl_owner_country = I_owner_country
      where ima.item in(select im2.item
                         from item_master im1,
                              item_master im2
                        where im1.tsl_base_item = I_item
                          and im1.item != im1.tsl_base_item
                          and (im2.item = im1.item
                           or im2.item_parent = im1.item)
                       UNION
                       select im2.item
                         from item_master im1,
                              item_master im2,
                              packitem pi
                        where pi.pack_no = im1.item
                          and (im2.item = im1.item
                           or  im2.item_parent = im1.item)
                          and pi.item in (select im2.item
                         from item_master im1, item_master im2
                        where im1.tsl_base_item = I_item
                          and im1.item != im1.tsl_base_item
                          and (im2.item = im1.item or im2.item_parent = im1.item)));
      ---
      SQL_LIB.SET_MARK('OPEN',
                      'C_LOCK_VAR_SUPPLIER',
                      'ITEM_SUPPLIER',
                      'ITEM: ' ||I_item);
      open C_LOCK_VAR_SUPPLIER;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                      'C_LOCK_VAR_SUPPLIER',
                      'ITEM_SUPPLIER',
                      'ITEM: ' ||I_item);
      close C_LOCK_VAR_SUPPLIER;
      ---
      SQL_LIB.SET_MARK('UPDATE',
                      'NULL',
                      'ITEM_SUPPLIER',
                      'ITEM: ' ||I_item);
      ---
      update item_supplier its
        set its.tsl_owner_country = I_owner_country
      where its.item in (select im2.item
                         from item_master im1,
                              item_master im2
                        where im1.tsl_base_item = I_item
                          and im1.item != im1.tsl_base_item
                          and (im2.item = im1.item
                           or im2.item_parent = im1.item)
                       UNION
                       select im2.item
                         from item_master im1,
                              item_master im2,
                              packitem pi
                        where pi.pack_no = im1.item
                          and (im2.item = im1.item
                           or  im2.item_parent = im1.item)
                          and pi.item in (select im2.item
                         from item_master im1, item_master im2
                        where im1.tsl_base_item = I_item
                          and im1.item != im1.tsl_base_item
                          and (im2.item = im1.item or im2.item_parent = im1.item)));
      ---
   end if;
   ---
   -- 06-Sep-2010, DefNBS019049, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
   ---
   return TRUE;
   ---
EXCEPTION
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011, Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   -- DefNBS023046,Suman Guha Mustafi, suman.mustafi@in.tesco.com,23-June-2011,End

   when OTHERS then
      if C_LOCK_CHILD_ITEM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_CHILD_ITEM',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_LOCK_CHILD_ITEM;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
         return FALSE;
END TSL_CASCADE_OWNER_CTRY;
--------------------------------------------------------------------------------------------------------
-- 09-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
--------------------------------------------------------------------------------------------------------
-- Author  : Raghuveer P R
-- Date    : 13-Aug-2010
-- Function: TSL_GET_OWNER_COUNTRY
-- Purpose : Get the owner country for the passed item
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_OWNER_COUNTRY(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_owner_country  IN OUT ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE,
                               I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY';

   CURSOR C_GET_OWNER_COUNTRY is
   select im.tsl_owner_country
     from item_master im
    where im.item = I_item;

BEGIN
   -- Check if any of input parameter is NULL
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                  L_program,
                                                  NULL);
      return FALSE;
   end if;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_OWNER_COUNTRY',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   open C_GET_OWNER_COUNTRY;
   --
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_OWNER_COUNTRY',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   fetch C_GET_OWNER_COUNTRY into O_owner_country;
   --
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_OWNER_COUNTRY',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   close C_GET_OWNER_COUNTRY;
   --
   return TRUE;
   --
EXCEPTION
   when OTHERS then
      if C_GET_OWNER_COUNTRY%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_OWNER_COUNTRY',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_GET_OWNER_COUNTRY;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
         return FALSE;
END TSL_GET_OWNER_COUNTRY;
-------------------------------------------------------------------------------------------------
-- 24-Aug-2010, CR354, Praveen R, praveen.rachaputi@in.tesco.com, Begin
-------------------------------------------------------------------------------------------------
-- Author  : Praveen R
-- Date    : 24-Aug-2010
-- Function: TSL_DIFF_CHILD_CNTRY_IND
-- Purpose : Get the owner country for the passed item
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_DIFF_CHILD_CNTRY_IND(O_error_message          IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_diff_child_cntry_ind   IN OUT VARCHAR2,
                                  I_item                   IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_DIFF_CHILD_CNTRY_IND';
   L_owner_cntry   SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
   L_exists        VARCHAR2(1);

   CURSOR C_DIFF_CHILD_CNTRY_IND is
   /*
   select 'x'
     from item_master
    where (item_parent = I_item
       or item_grandparent = I_item
       or item in (select pack_no
                     from packitem
                    where (item = I_item or
                           item in (select item
                                      from item_master
                                     where item_parent = I_item))))
      and tsl_owner_country != L_owner_cntry
      and rownum < 2;
   */
   -- MrgNBS020155, Ravi Nagaraju, ravi.nagaraju@in.tesco.com 25-Dec-2010 Begin
   -- 09-Dec-2010, PrfNBS020028, V Manikandan, manikandan.varadhan@in.tesco.com, Begin
   select 'x' from item_master im where im.item in
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
         and tsl_owner_country != L_owner_cntry
         and rownum < 2;
   -- 09-Dec-2010, PrfNBS020028, V Manikandan, manikandan.varadhan@in.tesco.com, End
   -- MrgNBS020155, Ravi Nagaraju, ravi.nagaraju@in.tesco.com 25-Dec-2010 End

BEGIN
   -- Check if any of input parameter is NULL
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                  L_program,
                                                  NULL);
      return FALSE;
   end if;
   --
   if ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY (O_error_message,
                                             L_owner_cntry,
                                             I_item) = FALSE then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_DIFF_CHILD_CNTRY_IND',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   open C_DIFF_CHILD_CNTRY_IND;
   --
   SQL_LIB.SET_MARK('FETCH',
                    'C_DIFF_CHILD_CNTRY_IND',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   fetch C_DIFF_CHILD_CNTRY_IND into L_exists;
   --
   if L_exists is not null then
     O_diff_child_cntry_ind := 'Y';
   else
     O_diff_child_cntry_ind := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DIFF_CHILD_CNTRY_IND',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   close C_DIFF_CHILD_CNTRY_IND;
   --
   return TRUE;
   --
EXCEPTION
   when OTHERS then
      if C_DIFF_CHILD_CNTRY_IND%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_DIFF_CHILD_CNTRY_IND',
                          'ITEM_MASTER',
                          'ITEM: ' ||I_item);
         close C_DIFF_CHILD_CNTRY_IND;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
         return FALSE;
END TSL_DIFF_CHILD_CNTRY_IND;
--------------------------------------------------------------------------------------------------------
-- 24-Aug-2010, CR354, Praveen R, praveen.rachaputi@in.tesco.com, End
--------------------------------------------------------------------------------------------------------
--MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com Begin
-- 08-Sep-2010, DefNBS018966, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
--------------------------------------------------------------------------------------------------------
FUNCTION  TSL_INCOMPLETE_TPNB (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_incomp_tpnb    IN OUT BOOLEAN,
                               I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_INCOMPLETE_TPNB';
   L_other_country          VARCHAR2(1);
   L_launch_date            DATE;
   L_tslsca_exists_uk       BOOLEAN := FALSE;
   L_tslsca_exists_roi      BOOLEAN := FALSE;
   L_valid_supp             VARCHAR2(1) := 'N';
   L_valid_range            VARCHAR2(1) := 'N';

   CURSOR C_GET_TPNB is
   select im2.item,
          im2.tsl_country_auth_ind,
          'N' simple_pack
     from item_master im1,
          item_master im2
    where im1.item        = I_item
      and im2.item_parent = im1.item
      and im2.status      = 'A'
      and im2.tsl_country_auth_ind <> 'B'
   UNION
   select im1.item,
          im1.tsl_country_auth_ind,
          'Y' simple_pack
     from packitem pi,
          item_master im1
    where im1.item = pi.pack_no
      and im1.status = 'A'
      and im1.tsl_country_auth_ind <> 'B'
      and pi.item in (select im2.item
                        from item_master im1,
                             item_master im2
                       where im1.item        = I_item
                         and im2.item_parent = im1.item
                         and im2.status      = 'A');

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
   O_incomp_tpnb := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TPNB',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   FOR C_rec IN C_GET_TPNB
   LOOP
      ---
      if C_rec.tsl_country_auth_ind = 'U' then
         L_other_country := 'R';
      elsif C_rec.tsl_country_auth_ind = 'R' then
         L_other_country := 'U';
      end if;
      ---
      -- Getting item other country launch date
      L_launch_date := NULL;
      ---
      if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                             C_rec.item,
                                             L_launch_date,
                                             L_other_country) = FALSE then
         return FALSE;
      end if;
      ---
      if L_launch_date is NOT NULL then
         ---
         L_valid_supp := 'N';
         ---
         if TSL_VALID_SUPP (O_error_message,
                            L_valid_supp,
                            C_rec.item,
                            L_other_country) = FALSE then
            return FALSE;
         end if;
         ---
         if L_valid_supp = 'Y' and
            L_other_country = 'U' and
            C_rec.simple_pack = 'N' then
            ---
            L_valid_range := 'N';
            ---
            -- Getting item UK Range info
            if TSL_RANGE_ATTRIB_SQL.ITEM_RANGE_EXISTS (O_error_message,
                                                       L_valid_range,
                                                       C_rec.item,
                                                       NULL) = FALSE then
               return FALSE;
            end if;
         elsif L_valid_supp = 'Y' and
            L_other_country = 'R' and
            C_rec.simple_pack = 'N' then
            ---
            L_valid_range := 'N';
            ---
            -- Getting item ROI Range info
            if TSL_RANGE_ATTRIB_SQL.ITEM_RANGE_EXISTS_ROI (O_error_message,
                                                           L_valid_range,
                                                           C_rec.item,
                                                           NULL) = FALSE then
               return FALSE;
            end if;
            ---
         elsif L_valid_supp = 'N' then
            O_incomp_tpnb := TRUE;
            return TRUE;
         end if;
         ---
         if L_valid_range = 'Y' and
            C_rec.simple_pack = 'N' then
            ---
            if TSL_SUPPLY_CHAIN_ATTRIB_SQL.TSL_ITEM_SCA_EXIST (O_error_message,
                                                               L_tslsca_exists_uk,
                                                               L_tslsca_exists_roi,
                                                               C_rec.item) = FALSE then
              return FALSE;
            end if;
            ---
            if ((L_other_country = 'U' and
                 L_tslsca_exists_uk = FALSE) or
                (L_other_country = 'R' and
                 L_tslsca_exists_roi = FALSE))  then
               ---
               O_incomp_tpnb := TRUE;
               return TRUE;
               ---
            end if;
            ---
         elsif C_rec.simple_pack = 'N' then
            O_incomp_tpnb := TRUE;
            return TRUE;
         end if;
         ---
      else
         O_incomp_tpnb := TRUE;
         return TRUE;
      end if;
      ---
   END LOOP;
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
END TSL_INCOMPLETE_TPNB;
--------------------------------------------------------------------------------------------------------
-- 08-Sep-2010, DefNBS018966, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
--MrgNBS019188,16-Sep-2010,(mrg 3.5g to 3.5b) , Manikandan, manikandan.varadhan@in.tesco.com End
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- 12-Dec-2010, CR259 ,AccentureSanju Natarajan ,Sanju.Natarajan@in.tesco.com,
--Begin, Added one more parameter default_child_groc_attrib to cascade standard uom also to children
-------------------------------------------------------------------------------------------------------
--CR259/NBS00020661, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 25-Jan-2011
--Added one more parameter I_catch_weight_ind for catch_weight_ind
-------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------
-- Function:   DEFAULT_CHILD_GROC_ATTRIB
-- Purpose: Defaults grocery attributes to all of an item's children.
-----------------------------------------------------------------------
FUNCTION DEFAULT_CHILD_GROC_ATTRIB(O_error_message            IN OUT VARCHAR2,
                                   I_item                     IN ITEM_MASTER.ITEM%TYPE,
                                   I_package_size             IN ITEM_MASTER.PACKAGE_SIZE%TYPE,
                                   I_package_uom              IN ITEM_MASTER.PACKAGE_UOM%TYPE,
                                   I_retail_label_type        IN ITEM_MASTER.RETAIL_LABEL_TYPE%TYPE,
                                   I_retail_label_value       IN ITEM_MASTER.RETAIL_LABEL_VALUE%TYPE,
                                   I_handling_sensitivity     IN ITEM_MASTER.HANDLING_SENSITIVITY%TYPE,
                                   I_handling_temp            IN ITEM_MASTER.HANDLING_TEMP%TYPE,
                                   I_waste_type               IN ITEM_MASTER.WASTE_TYPE%TYPE,
                                   I_default_waste_pct        IN ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE,
                                   I_waste_pct                IN ITEM_MASTER.WASTE_PCT%TYPE,
                                   I_container_item           IN ITEM_MASTER.CONTAINER_ITEM%TYPE,
                                   I_deposit_in_price_per_uom IN ITEM_MASTER.DEPOSIT_IN_PRICE_PER_UOM%TYPE,
                                   I_sale_type                IN ITEM_MASTER.SALE_TYPE%TYPE,
                                   I_order_type               IN ITEM_MASTER.ORDER_TYPE%TYPE,
                                   I_standard_uom             IN ITEM_MASTER.STANDARD_UOM%TYPE,
                                   --CR259/NBS00020661, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 25-Jan-2011, begin
                                   I_catch_weight_ind         IN ITEM_MASTER.CATCH_WEIGHT_IND%TYPE)
                                   --CR259/NBS00020661, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 25-Jan-2011, end

   RETURN BOOLEAN IS
   L_program      VARCHAR2(60) := 'ITEM_MASTER_SQL.DEFAULT_CHILD_GROC_ATTRIB';
   L_table        VARCHAR2(65):= 'ITEM_MASTER';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);
   L_tsl_loc_sec_ind   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
   L_owner_cntry   SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
   L_cw_ind       ITEM_MASTER.CATCH_WEIGHT_IND%TYPE;
   -- DefNBS021456, 09-Feb-2011, Accenture/Sanju Natarajan, Sanju.Natarajan@in.tesco.com Begin
   L_error_message          RTK_ERRORS.RTK_TEXT%TYPE;
   L_std_uom_item           VARCHAR2(4);
   L_sell_uom_item          VARCHAR2(4);
   L_cost_uom_item          VARCHAR2(4);
   L_std_uom_pack           VARCHAR2(4);
   L_sell_uom_pack          VARCHAR2(4);
   L_cost_uom_pack          VARCHAR2(4);
   L_order_type             ITEM_MASTER.ORDER_TYPE%TYPE;
   L_sale_type              ITEM_MASTER.SALE_TYPE%TYPE;
   -- DefNBS021456, 09-Feb-2011, Accenture/Sanju Natarajan, Sanju.Natarajan@in.tesco.com End


   cursor C_UPDATED_CONTAINER_ITEM is
      select item
        from item_master
       where (item_parent = I_item
          or item_grandparent = I_item)
         and item_level <= tran_level
         and NVL(container_item,'x') != NVL(I_container_item,'x');
   cursor C_GET_CW_IND is
      select im.catch_weight_ind
        from item_master im
       where im.item = I_item;
BEGIN
   if SYSTEM_OPTIONS_SQL.TSL_GET_LOC_SEC_IND (O_error_message,
                                              L_tsl_loc_sec_ind) = FALSE then
         return FALSE;
   end if;
   if ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY (O_error_message,
                                             L_owner_cntry,
                                             I_item) = FALSE then
      return FALSE;
   end if;
   for chg in C_UPDATED_CONTAINER_ITEM LOOP
      if NOT POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                            65,
                                            chg.item,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL) then
         return FALSE;
      end if;
   end LOOP;

   --CR259/NBS00020661, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 25-Jan-2011, begin
   if I_catch_weight_ind = 'N' then
   --CR259/NBS00020661, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 25-Jan-2011, end
      update item_master im
         set package_size = I_package_size,
             package_uom = I_package_uom ,
             retail_label_type = I_retail_label_type,
             retail_label_value = I_retail_label_value,
             handling_sensitivity = I_handling_sensitivity,
             handling_temp = I_handling_temp,
             waste_type = I_waste_type,
             default_waste_pct = I_default_waste_pct,
             waste_pct = I_waste_pct,
             container_item = I_container_item,
             deposit_in_price_per_uom = I_deposit_in_price_per_uom,
             order_type = I_order_type,
             sale_type = I_sale_type,
             standard_uom = I_standard_uom
       where item in (select im.item
                        from item_master im
                       start with im.item in (select pi.pack_no item
                                                from packitem pi
                                               where item in (select item
                                                                from item_master im2
                                                               start with im2.item = I_item
                                                             connect by prior im2.item = im2.item_parent))
     connect by prior im.item = im.item_parent
     and (L_tsl_loc_sec_ind   = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry))
     union all
     select item
       from item_master im
      start with im.item     = I_item
    connect by prior im.item = im.item_parent
        and (L_tsl_loc_sec_ind  = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry)));

  --CR259/NBS00020661, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 25-Jan-2011, begin
  elsif I_catch_weight_ind = 'Y' then
     update item_master im
        set package_size         = I_package_size,
            package_uom          = I_package_uom ,
            retail_label_type    = I_retail_label_type,
            retail_label_value   = I_retail_label_value,
            handling_sensitivity = I_handling_sensitivity,
            handling_temp        = I_handling_temp,
            waste_type           = I_waste_type,
            default_waste_pct    = I_default_waste_pct,
            waste_pct            = I_waste_pct,
            container_item       = I_container_item,
            deposit_in_price_per_uom = I_deposit_in_price_per_uom,
            order_type           = I_order_type,
            sale_type            = I_sale_type,
            standard_uom         = I_standard_uom
      -- DefNBS021456, 09-Feb-2011, Accenture/Sanju Natarajan, Sanju.Natarajan@in.tesco.com Begin
      where item in (select im.item
                        from item_master im
                       start with im.item in (select pi.pack_no item
                                                from packitem pi
                                               where item in (select item
                                                                from item_master im2
                                                               start with im2.item = I_item
                                                             connect by prior im2.item = im2.item_parent))
     connect by prior im.item = im.item_parent
     and (L_tsl_loc_sec_ind   = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry))
     union all
     select item
       from item_master im
      start with im.item     = I_item
    connect by prior im.item = im.item_parent
        and (L_tsl_loc_sec_ind  = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry)));
     L_order_type := I_order_type;
     L_sale_type  := I_sale_type;
     if ITEM_ATTRIB_SQL.TSL_GET_UOMS_CATCHWEIGHT(L_error_message,
                                                     L_std_uom_item,
                                                     L_sell_uom_item,
                                                     L_cost_uom_item,
                                                     L_std_uom_pack,
                                                     L_sell_uom_pack,
                                                     L_cost_uom_pack,
                                                     L_order_type,
                                                     L_sale_type
                                                     ) = FALSE then
         return FALSE;
         end if;
     update item_master im
        set standard_uom = L_std_uom_pack
      where item in (select im.item
                       from item_master im
                    start with im.item in (select pi.pack_no item
                                                from packitem pi
                                               where item in (select item
                                                                from item_master im2
                                                               start with im2.item = I_item
                                                             connect by prior im2.item = im2.item_parent))
     connect by prior im.item = im.item_parent
     and (L_tsl_loc_sec_ind   = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry)));
     -- DefNBS021456, 09-Feb-2011, Accenture/Sanju Natarajan, Sanju.Natarajan@in.tesco.com End
    /*  where item in (select item
                       from item_master im
                      start with im.item = I_item
                    connect by prior im.item = im.item_parent
                        and (L_tsl_loc_sec_ind  = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry)));*/

  end if;
  --CR259/NBS00020661, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 25-Jan-2011, end
  SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CW_IND',
                    L_table,
                   'Item: '||I_item);
   open  C_GET_CW_IND;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_CW_IND',
                    L_table,
                    'I_item: '||I_item);
   fetch C_GET_CW_IND into L_cw_ind;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CW_IND',
                    L_table,
                    'Item: '||I_item);
   close C_GET_CW_IND;
    update item_master im
       set catch_weight_ind = L_cw_ind
     where item in (select im.item
      from item_master im
     start with im.item in (select pi.pack_no item
                             from packitem pi
                            where item in (select item
                                             from item_master im2
                                            start with im2.item            = I_item
                                          connect by prior im2.item      = im2.item_parent))
   connect by prior im.item = im.item_parent
   and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry))
    union all
   select item
     from item_master im
    start with im.item = I_item
   connect by prior im.item = im.item_parent
   and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry)));

  return TRUE;

END DEFAULT_CHILD_GROC_ATTRIB;
--------------------------------------------------------------------------------------------------------
-- 12-Dec-2010, CR259 ,AccentureSanju Natarajan ,Sanju.Natarajan@in.tesco.com, End
--------------------------------------------------------------------------------------------------------

-- MrgNBS020155, Ravi Nagaraju, ravi.nagaraju@in.tesco.com 25-Dec-2010 Begin
-- 23-Nov-2010, CR363 ,Parvesh K ,parveshkumar.rulhan@in.tesco.com, Begin
--------------------------------------------------------------------------------------------------------
FUNCTION  TSL_INCOMPLETE_CHILD (O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_incomp_tpnb        IN OUT BOOLEAN,
                                I_authorization_ind  IN ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE,
                                I_item               IN ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS
   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_INCOMPLETE_CHILD';
   L_other_country          VARCHAR2(1);
   L_launch_date            DATE;
   L_tslsca_exists_uk       BOOLEAN := FALSE;
   L_tslsca_exists_roi      BOOLEAN := FALSE;
   L_valid_supp             VARCHAR2(1) := 'N';
   L_valid_range            VARCHAR2(1) := 'N';
   ---
   CURSOR C_GET_TPN is
   -- 21-Dec-2010,PrfNBS020199, Vinutha Raju, Vinutha.Raju@in.tesco.com, Begin
   --commented the following query as part of performance issue.
   /* select item,
          tsl_country_auth_ind,
          simple_pack_ind
     from item_master
    where (item_parent = I_item
          or item in ( select pack_no
                         from packitem pi
                        where item in ( select item
                                          from item_master
                                         where item_parent = I_item
                                            or item = I_item)))
      and status      = 'A'
      and (simple_pack_ind = 'Y' and item_level= 1
       or simple_pack_ind = 'N' and item_level= 2);*/
       ---

      select item,
             tsl_country_auth_ind,
             simple_pack_ind
        from item_master
       where (item in ( select pack_no
                          from packitem pi
                         where item in ( select item
                                          from item_master
                                         where item_parent = I_item
                                            or item = I_item)))
         and status      = 'A'
         and ((simple_pack_ind = 'Y' and item_level= 1)
          or (simple_pack_ind = 'N' and item_level= 2))
      UNION
      select item,
             tsl_country_auth_ind,
             simple_pack_ind
        from item_master
       where item_parent = I_item
         and status      = 'A'
         and ((simple_pack_ind = 'Y' and item_level= 1)
          or (simple_pack_ind = 'N' and item_level= 2));
  -- 21-Dec-2010,PrfNBS020199, Vinutha Raju, Vinutha.Raju@in.tesco.com, End


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
   O_incomp_tpnb := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TPN',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   FOR C_rec IN C_GET_TPN
   LOOP
      ---
      if (C_rec.tsl_country_auth_ind != I_authorization_ind) then
         O_incomp_tpnb := TRUE;
         return TRUE;
      end if;
      ---
      if C_rec.tsl_country_auth_ind = 'U' then
         L_other_country := 'R';
      elsif C_rec.tsl_country_auth_ind = 'R' then
         L_other_country := 'U';
      end if;
      ---
      -- Getting item other country launch date
      L_launch_date := NULL;
      ---
      if ITEM_ATTRIB_SQL.TSL_GET_LUNCH_DATE (O_error_message,
                                             C_rec.item,
                                             L_launch_date,
                                             L_other_country) = FALSE then
         return FALSE;
      end if;
      ---
      if L_launch_date is NOT NULL then
         ---
         L_valid_supp := 'N';
         ---
         if TSL_VALID_SUPP (O_error_message,
                            L_valid_supp,
                            C_rec.item,
                            L_other_country) = FALSE then
            return FALSE;
         end if;
         ---
         if L_valid_supp = 'Y' and
            L_other_country = 'U' and
            C_rec.simple_pack_ind = 'N' then
            ---
            L_valid_range := 'N';
            ---
            -- Getting item UK Range info
            if TSL_RANGE_ATTRIB_SQL.ITEM_RANGE_EXISTS (O_error_message,
                                                       L_valid_range,
                                                       C_rec.item,
                                                       NULL) = FALSE then
               return FALSE;
            end if;
         elsif L_valid_supp = 'Y' and
            L_other_country = 'R' and
            C_rec.simple_pack_ind = 'N' then
            ---
            L_valid_range := 'N';
            ---
            -- Getting item ROI Range info
            if TSL_RANGE_ATTRIB_SQL.ITEM_RANGE_EXISTS_ROI (O_error_message,
                                                           L_valid_range,
                                                           C_rec.item,
                                                           NULL) = FALSE then
               return FALSE;
            end if;
            ---
         elsif L_valid_supp = 'N' then
            O_incomp_tpnb := TRUE;
            return TRUE;
         end if;
         ---
         if L_valid_range = 'Y' and
            C_rec.simple_pack_ind = 'N' then
            ---
            if TSL_SUPPLY_CHAIN_ATTRIB_SQL.TSL_ITEM_SCA_EXIST (O_error_message,
                                                               L_tslsca_exists_uk,
                                                               L_tslsca_exists_roi,
                                                               C_rec.item) = FALSE then
              return FALSE;
            end if;
            ---
            if ((L_other_country = 'U' and
                 L_tslsca_exists_uk = FALSE) or
                (L_other_country = 'R' and
                 L_tslsca_exists_roi = FALSE))  then
               ---
               O_incomp_tpnb := TRUE;
               return TRUE;
               ---
            end if;
            ---
         elsif C_rec.simple_pack_ind = 'N' then
            O_incomp_tpnb := TRUE;
            return TRUE;
         end if;
         ---
      elsif (I_authorization_ind = 'B'and C_rec.tsl_country_auth_ind ='B')
             or
            (I_authorization_ind = 'U'and C_rec.tsl_country_auth_ind ='U')
             or
            (I_authorization_ind = 'R'and C_rec.tsl_country_auth_ind ='R') then
         O_incomp_tpnb := FALSE;
         ---
      else
         O_incomp_tpnb := TRUE;
         return TRUE;
      end if;
      ---
   END LOOP;
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
END TSL_INCOMPLETE_CHILD;
--------------------------------------------------------------------------------------------------------
-- 23-Nov-2010, CR363 ,Parvesh K ,parveshkumar.rulhan@in.tesco.com, End
--------------------------------------------------------------------------------------------------------
-- MrgNBS020155, Ravi Nagaraju, ravi.nagaraju@in.tesco.com 25-Dec-2010 End

-- 30-Mar-2011, DefNBS022155a, Veena Nanjundaiah,veena.nanjundaiah@in.tesco.com, Begin
FUNCTION  TSL_GET_DIFF_CLOTHING_IND (O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     O_disable            IN OUT BOOLEAN,
                                     I_item               IN ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_GET_DIFF_CLOTHING_IND';
   L_item_tpna              ITEM_MASTER.ITEM%TYPE  := NULL;
   L_dummy                  VARCHAR2(1);
   L_continue               VARCHAR2(1);

   CURSOR C_CHECK_DIFF is
   select 'X'
     from item_master im
    where im.item = I_item
      and im.diff_1 is NOT NULL;

   CURSOR C_GET_DIFF is
   select 'X'
     from diff_group_head dgh, item_master im
    where im.item = L_item_tpna
      and dgh.tsl_clothing_ind = 'Y'
      and dgh.diff_group_id = im.diff_1
   UNION ALL
   select 'X'
     from diff_group_head dgh, item_master im
    where im.item = L_item_tpna
      and dgh.tsl_clothing_ind = 'Y'
      and dgh.diff_group_id = im.diff_2
   UNION ALL
   select 'X'
     from diff_group_head dgh, item_master im
    where im.item = L_item_tpna
      and dgh.tsl_clothing_ind = 'Y'
      and dgh.diff_group_id = im.diff_3
   UNION ALL
   select 'X'
     from diff_group_head dgh, item_master im
    where im.item = L_item_tpna
      and dgh.tsl_clothing_ind = 'Y'
      and dgh.diff_group_id = im.diff_4;

   CURSOR C_GET_TPNA is
   select item
     from item_master
    where item = I_item
      and item_parent is NULL
      and item_grandparent is NULL
      and pack_ind <> 'Y'
   UNION ALL
   select item_parent
     from item_master
    where item = I_item
      and item_parent is NOT NULL
      and item_grandparent is NULL
      and pack_ind <> 'Y'
   UNION ALL
   select item_grandparent
     from item_master
    where item = I_item
      and item_parent is NOT NULL
      and item_grandparent is NOT NULL
   UNION ALL
   select item_parent
     from packitem
    where pack_no = I_item
   UNION ALL
   select item_parent
     from packitem
    where pack_no in (select item_parent
                        from item_master
                       where item = I_item
                         and item_parent is NOT NULL
                         and pack_ind = 'Y');
BEGIN
   O_disable := FALSE;
   --
   L_continue := NULL;
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_DIFF',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   open C_CHECK_DIFF;
   --
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_DIFF',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   fetch C_CHECK_DIFF into L_continue;
   --
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_DIFF',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   close C_CHECK_DIFF;
   --
   if L_continue is NOT NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_TPNA',
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      open C_GET_TPNA;
      --
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_TPNA',
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      fetch C_GET_TPNA into L_item_tpna;
      --
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_TPNA',
                       'ITEM_MASTER',
                       'ITEM: ' ||I_item);
      close C_GET_TPNA;
      --
      if L_item_tpna is NOT NULL then
         --
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_DIFF',
                          'ITEM_MASTER',
                          'ITEM: ' ||L_item_tpna);
         open C_GET_DIFF;
         --
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_OWNER_COUNTRY',
                          'ITEM_MASTER',
                          'ITEM: ' ||L_item_tpna);
         fetch C_GET_DIFF into L_dummy;
         if C_GET_DIFF%NOTFOUND then
            O_disable := FALSE;
         else
            O_disable := TRUE;
         end if;
         --
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_DIFF',
                          'ITEM_MASTER',
                          'ITEM: ' ||L_item_tpna);
         close C_GET_DIFF ;
         --
      end if;
   end if;
   --
   return TRUE;
   --
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
         return FALSE;
END TSL_GET_DIFF_CLOTHING_IND;
-- 30-Mar-2011, DefNBS022155a, Veena Nanjundaiah,veena.nanjundaiah@in.tesco.com, End
--------------------------------------------------------------------------------------------------------
-- 06-Jun-2011, CR416, Deepak Gupta, deepak.c.gupta@in.tesco.com, Begin
--------------------------------------------------------------------------------------------------------
-- Function Name  : TSL_GET_CHILD_EAN
-- Purpose        : This function will return EAN
-------------------------------------------------------------------------------------------------------
FUNCTION  TSL_GET_CHILD_EAN (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_child_item     IN OUT ITEM_MASTER_SQL.CHILD_ITEM_TBL,
                             I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_GET_CHILD_EAN';
   L_count                  NUMBER(9)    := 0;
   L_launch_dt_uk           DATE;
   L_launch_dt_roi          DATE;
   L_tslsca_exists_uk       BOOLEAN := FALSE;
   L_tslsca_exists_roi      BOOLEAN := FALSE;

   CURSOR C_GET_CHILD_ITEM is
   select DISTINCT item
     from (select im.item, im.pack_ind, im.simple_pack_ind, im.item_level, im.tran_level
             from item_master im
            start with im.item in (select item
                                     from packitem pi
                                    where pack_no = I_item)
   connect by prior im.item = im.item_parent
   union all
   select item, pack_ind, simple_pack_ind, item_level, tran_level
     from item_master im
     start with im.item = I_item
  connect by prior im.item = im.item_parent)
  where pack_ind='N' and simple_pack_ind='N' and item_level=3 and tran_level=2
    and rownum = 1;

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
                    'C_GET_CHILD_ITEM',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   FOR C_rec IN C_GET_CHILD_ITEM
   LOOP
      L_count := L_count + 1 ;
      O_child_item(L_count).item := C_rec.item;
   END LOOP;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_CHILD_ITEM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CHILD_ITEM',
                          'ITEM_MASTER',
                          'Item = ' || I_item);
         close C_GET_CHILD_ITEM;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_CHILD_EAN;
--------------------------------------------------------------------------------------------------------
-- Function Name  : TSL_GET_CHILD_OCC
-- Purpose        : This function will return EAN
-------------------------------------------------------------------------------------------------------
FUNCTION  TSL_GET_CHILD_OCC (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_child_item     IN OUT ITEM_MASTER_SQL.CHILD_ITEM_TBL,
                             I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_GET_CHILD_OCC';
   L_count                  NUMBER(9)    := 0;
   L_launch_dt_uk           DATE;
   L_launch_dt_roi          DATE;
   L_tslsca_exists_uk       BOOLEAN := FALSE;
   L_tslsca_exists_roi      BOOLEAN := FALSE;

   CURSOR C_GET_CHILD_ITEM is
   select DISTINCT item
     from (select im.item, im.pack_ind, im.simple_pack_ind, im.item_level, im.tran_level
             from item_master im
            start with im.item in (select pi.pack_no item
                                     from packitem pi
                                    where item in (select item
                                                     from item_master im2
                                                    start with im2.item = I_item
                                                  connect by prior im2.item = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
   select item, pack_ind, simple_pack_ind, item_level, tran_level
     from item_master im
     start with im.item = I_item
  connect by prior im.item = im.item_parent)
  where pack_ind = 'Y' and simple_pack_ind = 'Y' and item_level = 2 and tran_level = 1
    and rownum = 1;

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
                    'C_GET_CHILD_ITEM',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   FOR C_rec IN C_GET_CHILD_ITEM
   LOOP
      L_count := L_count + 1 ;
      O_child_item(L_count).item := C_rec.item;
   END LOOP;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_CHILD_ITEM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CHILD_ITEM',
                          'ITEM_MASTER',
                          'Item = ' || I_item);
         close C_GET_CHILD_ITEM;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_CHILD_OCC;
--------------------------------------------------------------------------------------------------------
-- Function Name  : TSL_GET_TPND
-- Purpose        : This function will return TPND
-------------------------------------------------------------------------------------------------------
FUNCTION  TSL_GET_TPND      (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_child_item     IN OUT ITEM_MASTER_SQL.CHILD_ITEM_TBL,
                             I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64) := 'ITEM_MASTER_SQL.TSL_GET_TPND';
   L_count                  NUMBER(9)    := 0;
   L_launch_dt_uk           DATE;
   L_launch_dt_roi          DATE;
   L_tslsca_exists_uk       BOOLEAN := FALSE;
   L_tslsca_exists_roi      BOOLEAN := FALSE;

   CURSOR C_GET_CHILD_ITEM is
   select DISTINCT item
     from (select im.item, im.pack_ind, im.simple_pack_ind, im.item_level, im.tran_level, im.tsl_prim_pack_ind
             from item_master im
            start with im.item in (select pi.pack_no item
                                     from packitem pi
                                    where item in (select item
                                                     from item_master im2
                                                    start with im2.item = I_item
                                                  connect by prior im2.item = im2.item_parent))
   connect by prior im.item = im.item_parent
   union all
   select item, pack_ind, simple_pack_ind, item_level, tran_level, tsl_prim_pack_ind
     from item_master im
     start with im.item = I_item
  connect by prior im.item = im.item_parent)
  where pack_ind = 'Y' and simple_pack_ind = 'Y' and item_level = 1 and tran_level = 1 and  tsl_prim_pack_ind = 'Y';

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
                    'C_GET_CHILD_ITEM',
                    'ITEM_MASTER',
                    'ITEM: ' ||I_item);
   FOR C_rec IN C_GET_CHILD_ITEM
   LOOP
      L_count := L_count + 1 ;
      O_child_item(L_count).item := C_rec.item;
   END LOOP;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      if C_GET_CHILD_ITEM%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CHILD_ITEM',
                          'ITEM_MASTER',
                          'Item = ' || I_item);
         close C_GET_CHILD_ITEM;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_TPND;
--------------------------------------------------------------------------------------------------------
-- 06-Jun-2011, CR416, Deepak Gupta, deepak.c.gupta@in.tesco.com, End
--------------------------------------------------------------------------------------------------------
-- Mod By     : Shweta, shweta.madnawat@in.tesco.com  Begin
-- Mod Date   : 20-Oct-2011
-- Function   : TSL_CASCADE_RESTRICT_PCEV
-- Mod        : CR434
-- Purpose    : This is a new function which will be used to cascade the value of
--              restrict price event indicator from TPNA to TPNBs.
---------------------------------------------------------------------------------------------
FUNCTION TSL_CASCADE_RESTRICT_PCEV(O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                                   I_restrict_pcev_ind     IN     ITEM_MASTER.TSL_RESTRICT_PRICE_EVENT%TYPE,
                                   I_user_loc              IN     VARCHAR2)
RETURN BOOLEAN is

   L_program             VARCHAR2(60) := 'ITEM_MASTER_SQL.TSL_CASCADE_RESTRICT_PCEV';
   L_owner_country_uk    ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE  := NULL;
   L_owner_country_roi   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE  := NULL;

   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, Begin
   L_new_access_trpv     VARCHAR2(1) := NULL;
   L_edit_access_trpv    VARCHAR2(1) := NULL;
   L_view_access_trpv    VARCHAR2(1) := NULL;
   L_uk_loc_access       VARCHAR2(1);
   L_roi_loc_access      VARCHAR2(1);
   L_user_loc            VARCHAR2(1) := 'N';
   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, End
   CURSOR C_GET_CHILD_ITEMS is
   select item
     from item_master
    where item_parent = I_item
      and item_level = tran_level
      and pack_ind = 'N'
      and tsl_owner_country in (L_owner_country_uk, L_owner_country_roi);

   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, Begin
   CURSOR C_CHILD_ITEMS is
   select item
     from item_master im,
          subclass    sc
    where im.item_parent = I_item
      and im.dept        = sc.dept
      and im.class       = sc.class
      and im.subclass    = sc.subclass
      and im.item_level  = im.tran_level
      and im.pack_ind    = 'N'
      and sc.tsl_restrict_price_event = 'N'
      and im.tsl_owner_country in (L_owner_country_uk, L_owner_country_roi);
   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, End
BEGIN
   -- Check if any of input parameter is NULL
   if I_item is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_item',
                                                  L_program,
                                                  NULL);
      return FALSE;
   end if;

   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 08-Dec-2011, Begin
   if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY(O_error_message,
                                             L_uk_loc_access,
                                             L_roi_loc_access) = FALSE then
      return FALSE;
   end if;
   if L_uk_loc_access = 'Y' and L_roi_loc_access = 'Y' then
      L_user_loc := 'B';
   elsif L_uk_loc_access = 'Y' then
      L_user_loc := 'U';
   elsif L_roi_loc_access = 'Y' then
      L_user_loc := 'R';
   end if;

   if L_user_loc in ('B', 'U') then
      L_owner_country_uk := 'U';
   end if;
   if L_user_loc in ('B', 'R') then
      L_owner_country_roi := 'R';
   end if;
   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 08-Dec-2011, End
   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, Begin
   if PRIVILEGE_SQL.TSL_VALIDATE_ACCESS(O_error_message,
                                        'TRPV',
                                        L_new_access_trpv,
                                        L_edit_access_trpv,
                                        L_view_access_trpv,
                                        USER) = FALSE then
      return FALSE;
   end if;

   if NVL(L_edit_access_trpv, 'N') = 'N' then
      FOR c_rec in C_CHILD_ITEMS
      LOOP
         SQL_LIB.SET_MARK('UPDATE',
                          'ITEM_MASTER',
                          'ITEM_MASTER',
                          'Item: '||I_item);
         update item_master
            set tsl_restrict_price_event = I_restrict_pcev_ind,
                --DefNBS024052, Vatan jaiswal, vatan.jaiswal@in.tesco.com, 30-Dec-2011, Begin
                last_update_id           = USER
                --DefNBS024052, Vatan jaiswal, vatan.jaiswal@in.tesco.com, 30-Dec-2011, End
          where item = c_rec.item;
      END LOOP;
   elsif NVL(L_edit_access_trpv, 'N') = 'Y' then
      FOR c_rec in C_GET_CHILD_ITEMS
      LOOP
         SQL_LIB.SET_MARK('UPDATE',
                          'ITEM_MASTER',
                          'ITEM_MASTER',
                          'Item: '||I_item);
         update item_master
            set tsl_restrict_price_event = I_restrict_pcev_ind,
                --DefNBS024052, Vatan jaiswal, vatan.jaiswal@in.tesco.com, 30-Dec-2011, Begin
                last_update_id           = USER
                --DefNBS024052, Vatan jaiswal, vatan.jaiswal@in.tesco.com, 30-Dec-2011, End
          where item = c_rec.item;
      END LOOP;
   end if;
   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, End
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_GET_CHILD_ITEMS%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_CHILD_ITEMS',
                          'ITEM_MASTER',
                          'Item = ' || I_item);
         close C_GET_CHILD_ITEMS;
      end if;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_CASCADE_RESTRICT_PCEV;


END ITEM_MASTER_SQL;
/

