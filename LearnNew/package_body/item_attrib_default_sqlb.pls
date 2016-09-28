CREATE OR REPLACE PACKAGE BODY ITEM_ATTRIB_DEFAULT_SQL AS
------------------------------------------------------------------------------------------------
-- Mod By:      Natarajan Chandrasekaran, chandrashekaran.natarajan@in.tesco.com
-- Mod Date:    11-May-2007
-- Mod Ref:     Mod number. N20
-- Mod Details: Replace the old fields on item_attributes with the new fields from the item_attributes
-----------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    28-Jun-2007
--Mod Ref:     Mod number. 365b2
--Mod Details: Cascading the base item attributes to its variants and to its children.
--             Appended TSL_COPY_BASE_ATTRIB new function.
-----------------------------------------------------------------------------------------------------
--Mod By:      Nitin Kumar, Nitin.Kumar@in.tesco.com
--Mod Date:    06-Sep-2007
--Mod Ref:     Mod number. N20
--Mod Details: Cascading the base item attributes to it's level3 children.
-----------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    06-Sep-2007
--Mod Ref:     Mod number. 365b2
--Mod Details: For the defect no DefNBS003083
-----------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    27-Sep-2007, 03-Oct-2007
--Mod Ref:     Mod number. N20a
--Mod Details: Product attributes cascading
-----------------------------------------------------------------------------------------------------
--Mod By:      Shweta Mandawat     shweta.madnawat@in.tesco.com
--Mod Date:    04-Aug-2009
--Mod Ref:     CR242
--Mod Details: Added the checks to stop cascade of brand ind from L1 to L2 which have barcodes set
--             up, also stop cascade of brand ind from base to variants with barcodes.
-----------------------------------------------------------------------------------------------------
--Mod By:      Shweta Mandawat     shweta.madnawat@in.tesco.com
--Mod Date:    24-Aug-2009
--Mod Ref:     NBSDef014555
--Mod Details: The cascade of brand ind and brand name will be as-is.
-----------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    05-Aug-2009
--Mod Ref:     CR236
--Mod Details: Modified TSL_COPY_ITEM_ATTRIB, TSL_COPY_ITEM_ATTRIB_L3,COPY_DOWN_PARENT_ATTRIB
--             and TSL_COPY_BASE_ATTRIB
-----------------------------------------------------------------------------------------------------
--Mod By:      Sarayu Gouda, sarayu.gouda@in.tesco.com
--Mod Date:    24-Aug-2009
--Mod Ref:     CR236
--Mod Details: Added two new overloaded functions TSL_COPY_DOWN_PARENT_EPW and TSL_COPY_BASE_EPW
--             to cascade the epw value to its children and variants respectively.
-----------------------------------------------------------------------------------------------------
--Mod By:      Satish B.N, satish.narasimhaiah@in.tesco.com
--Mod Date:    20-Oct-2009
--Mod Ref:     DefNBS015040
--Mod Details: Modified TSL_COPY_DOWN_PARENT_EPW function to set the epw ind to 'N' for all the children
--             before setting it to 'Y' or 'N'.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 23-Oct-2009
-- Mod Ref    : MrgNBS015130
-- Mod Details: Merge 3.4 Dev to 3.5b
------------------------------------------------------------------------------------------------------
--Mod By       : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date     : 15-Dec-2009
--Mod Ref      : CR236a
--Mod Details  : Modified TSL_COPY_DOWN_PARENT_EPW and TSL_COPY_BASE_EPW function
------------------------------------------------------------------------------------------------------
--Mod By       : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date     : 20-Jan-2010
--Mod Ref      : DefNBS015988 and DefNBS015999
--Mod Details  : Modified cursor where condition to cascade the EPW info to variant packs
------------------------------------------------------------------------------------------------------
--Mod By:      Chandru, chandrashkearan.natarajan@in.tesco.com
--Mod Date:    21-Apr-2010
--Mod Ref:     CR258
--Mod Details: Modified the existing functions and added TSL_COPY_ITEM_PACK_ATTRIB funciton to
--             implement the cascading functionality
-----------------------------------------------------------------------------------------------------
--Mod By:      Sripriya,sripriya.karanam@in.tesco.com
--Mod Date:    20-May-2010
--Mod Ref:     LT DEfNBS017489
--Mod Details: Modified TSL_COPY_DOWN_PARENT_EPW,TSL_COPY_BASE_EPW for cascading EPW Enddate
--             to child level items if set at Parent level.
-----------------------------------------------------------------------------------------------------
--Mod By       : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date     : 26-May-2010
--Mod Ref      : DefNBS017627
--Mod Details  : Added TSL_COPY_UK_ITEM_ATTRIB new function
------------------------------------------------------------------------------------------------------
--Mod By       : JK, jayakumar.gopal@in.tesco.com
--Mod Date     : 01-Jun-10
--Mod Ref      : MrgNBS017783
--Mod Details  : Added TSL_COPY_UK_ITEM_ATTRIB new function
------------------------------------------------------------------------------------------------------
--Mod By       : Chandru, chandrashekaran.natarajan@in.tesco.com
--Mod Date     : 08-Jun-10
--Mod Ref      : DefNBS017833
--Mod Details  : TSL_COPY_DOWN_PARENT_EPW function modified
------------------------------------------------------------------------------------------------------
--Mod By:      Sripriya,sripriya.karanam@in.tesco.com
--Mod Date:    20-Jul-2010
--Mod Ref:     CR347
--Mod Details: Added a new function TSL_GET_CODE_TYPE to get the code_type.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Nishant Gupta
-- Mod Date   : 19-Jul-2010
-- Mod Ref    : CR288d.
-- Mod Details: Modified TSL_COPY_DOWN_PARENT_EPW and TSL_COPY_BASE_EPW function.
--------------------------------------------------------------------------------------------------
--Mod By       : JK, jayakumar.gopal@in.tesco.com
--Mod Date     : 08-Jul-10
--Mod Ref      : DefNBS018117
--Mod Details  : In TSL_COPY_ITEM_PACK_ATTRIB function Queries are modified to improve the performance
------------------------------------------------------------------------------------------------------
--Mod By       : Chandru chandrashekaran.natarajan@in.tesco.com
--Mod Date     : 16-Jul-10
--Mod Ref      : DefNBS018184
--Mod Details  : function call added for ROI attributes in COPY_DOWN_PARENT_ATTRIB function
------------------------------------------------------------------------------------------------------
--Mod By:      Praveen, praveen.rachaputi@in.tesco.com
--Mod Date:    18-Aug-2010
--Mod Ref:     CR354
--Mod Details: CR258 cascading functionality changes modified to implement the Security Checks
------------------------------------------------------------------------------------------------------
--Mod By       : Joy Stephen
--Mod Date     : 03-Sep-2010
--Mod Ref      : DefNBS018990
--Mod Details  : Modified the function TSL_COPY_ITEM_ATTRIB,TSL_COPY_ITEM_ATTRIB_L3,TSL_COPY_BASE_ATTRIB,
--               TSL_COPY_ITEM_PACK_ATTRIB to handle the cascading logic for CR354
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
--Mod Date   : 05-Aug-2010
--Mod Ref    : MrgNBS018606(Merge 3.5f to 3.5g)
--Mod Details: Merged for DefNBS018117, DefNBS018184
------------------------------------------------------------------------------------------------------
--Mod By       : V Manikandan   manikandan.varadhan@in.tesco.com
--Mod Date     : 12-Aug-10
--Mod Ref      : DefNBS018719
--Mod Details  : Modified COPY_DOWN_PARENT_ATTRIB function
------------------------------------------------------------------------------------------------------
--Mod By     : JK, jayakumar.gopal@in.tesco.com
--Mod Date   : 31-Aug-2010
--Mod Ref    : MrgNBS018918(Merge 3.5f to 3.5g)
--Mod Details: Merged DefNBS018719
------------------------------------------------------------------------------------------------------
--Mod By:      Sripriya,sripriya.karanam@in.tesco.com
--Mod Date:    03-Sep-2010
--Mod Ref:     DefNBS018975
--Mod Details: Added a new function TSL_COUNT_ITEMNUMTYPE.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Date   : 16-Sep-2010
-- Mod Ref    : MrgNBS019188, (Merge from 3.5g to 3.5b)
-- Mod Details: Merged changes for CR347, CR288d, MrgNBS018606, MrgNBS018918, DefNBS018975
-------------------------------------------------------------------------------------------------------
--Mod By:      Praveen,praveen.rachaputi@in.tesco.com
--Mod Date:    14-Sep-2010
--Mod Ref:     PrfNBS018117d
--Mod Details: Modified TSL_COPY_ITEM_PACK_ATTRIB,TSL_COPY_ITEM_ATTRIB,TSL_COPY_BASE_ATTRIB,
--             TSL_COPY_ITEM_ATTRIB_L3 functions to include bind varibales
-----------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 28-Sep-2010
-- Mod Ref    : DefNBS019722
-- Mod Details: Modified TSL_COUNT_ITEMNUMTYPE not to count Complex Pack child TPNB
-------------------------------------------------------------------------------------------------------
--Mod By:      Praveen,praveen.rachaputi@in.tesco.com
--Mod Date:    01-Oct-2010
--Mod Ref:     DefNBS019341
--Mod Details: Modified TSL_COPY_ITEM_ATTRIB,TSL_COPY_BASE_ATTRIB,
--             TSL_COPY_ITEM_ATTRIB_L3 to fix cascading issues based on location security
---------------------------------------------------------------------------------------------------------
-- Mod By     : Ravi Nagaraju, ravi.nagaraju@in.tesco.com
-- Mod Date   : 29-Dec-2010
-- Mod Ref    : CR254
-- Mod Details: Modified the functions TSL_COPY_ITEM_ATTRIB and TSL_COPY_ITEM_ATTRIB_L3
--              to not to cascade to EAN and OCC level
-----------------------------------------------------------------------------------------------------
-- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
---------------------------------------------------------------------------------------------------------
--Mod By:      Yashavantharaja,yashavantharaja.thimmesh@in.tesco.com
--Mod Date:    13-Jan-2010
--Mod Ref:     DefNBS020504
--Mod Details: Modified TSL_COPY_ITEM_ATTRIB,TSL_COPY_BASE_ATTRIB,
--             TSL_COPY_ITEM_ATTRIB_L3 to fix cascading issues
---------------------------------------------------------------------------------------------------------
-- Mod By     : Ravi Nagaraju, ravi.nagaraju@in.tesco.com
-- Mod Date   : 02-Feb-2011
-- Mod Ref    : SIT defect DefNBS020804 for CR254
-- Mod Details: Modified the functions TSL_COPY_ITEM_PACK_ATTRIB to not to cascade to TPND to OCC for complex pack
-----------------------------------------------------------------------------------------------------
-- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
----------------------------------------------------------------------------------------------------
-- Mod By:      Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date:    14-Apr-2011
-- Def Ref:     PrfNBS022237
-- Def Details: Modified the functions COPY_DOWN_PARENT_ATTRIB,TSL_COPY_BASE_ATTRIB,TSL_COPY_ITEM_ATTRIB,
--              TSL_COPY_ITEM_ATTRIB_L3 and TSL_COPY_ITEM_PACK_ATTRIB to improve the performance of Mass itemlist upload.
----------------------------------------------------------------------------------------------------
-- Mod By:      Vinutha Raju, Vinutha.Raju@in.tesco.com
-- Mod Date:    19-Apr-2011
-- Def Ref:     MrgNBS022368(fix)
-- Def Details: Modified the functions TSL_COPY_ITEM_ATTRIB,TSL_COPY_ITEM_PACK_ATTRIB,TSL_COPY_ITEM_ATTRIB_L3
--              and TSL_COPY_BASE_ATTRIB to add the NVL condition
----------------------------------------------------------------------------------------------------
-- Mod By:      Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date:    26-Apr-2011
-- Def Ref:     MrgNBS022412(3.5b to PrdSi)
-- Mod Details: Merged PrfNBS022237e and f
----------------------------------------------------------------------------------------------------
--Mod By:      Praveen,praveen.rachaputi@in.tesco.com
--Mod Date:    28-Jun-2011
--Mod Ref:     DefNBS023046
--Mod Details: Modified TSL_COPY_UK_ITEM_ATTRIB to handle locking
-----------------------------------------------------------------------------------------------------
--Mod By:      Shweta, shweta.madnawat@in.tesco.com
--Mod Date:    06-Jul-2011
--Mod Ref:     DefNBS023175
--Mod Details: Modified TSL_COPY_BASE_ATTRIB, TSL_COPY_ITEM_ATTRIB and TSL_COPY_ITEM_PACK_ATTRIB to
--             allow cascade of NULL values for Launch Date.
-----------------------------------------------------------------------------------------------------
--Mod By:      Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com
--Mod Date:    13-Jul-2011
--Mod Ref:     DefNBS023239
--Mod Details: Modified the TSL_COPY_UK_ITEM_ATTRIB to remove L_id variable and instead calling
--             dbms_utility.get_hash_value function
-----------------------------------------------------------------------------------------------------
--Mod By:      Deepak Gupta, deepak.c.gupta@in.tesco.com
--Mod Date:    05-Aug-2011
--Mod Ref:     CR281
--Mod Details: Added TSL_PRF_VALUE column in TSL_COPY_UK_ITEM_ATTRIB function
-----------------------------------------------------------------------------------------------------
-- Mod By     : Ankush, ankush.khanna@in.tesco.com
-- Mod Date   : 02-Aug-2011
-- Mod Ref    : CR432
-- Mod Details: Modified TSL_COPY_UK_ITEM_ATTRIB to add the newly added field tsl_multipack_qty while
--              inserting into item_attributes table.
------------------------------------------------------------------------------------------------------------
--Mod by     : Gurutej.K, gurutej.kunjibettu@in.tesco.com
--Mod date   : 11-Aug-2011
--Mod        : MrgNBS023381
--Mod ref    : Merge from PrdSi to 3.5b(DefNBS023239)
-------------------------------------------------------------
-- Mod By     : Vinutha R, vinutha.raju@in.tesco.com
-- Mod Date   : 08-May-2012
-- Mod Ref    : DefNBS024857/PM015114
-- Mod Desc   : MODIFIED the function TSL_COPY_BASE_ATTRIB to avoid multipack qty getting cascaded
--              from base to variant.
--------------------------------------------------------------------------------------
--Mod by     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
--Mod date   : 28-Dec-2011
--Mod        : MrgNBS024095
--Mod ref    : Merge from 3.6 to 3.5b
-------------------------------------------------------------
--Mod by     : Swetha prasad ,swetha.prasad@in.tesco.com
--Mod date   : 28-Dec-2011
--Mod        : MrgNBS300712
--Mod ref    : Merge from 3.5b to PrdSi
-------------------------------------------------------------
-- Mod By     : Vinutha R, vinutha.raju@in.tesco.com
-- Mod Date   : 08-Oct-2012
-- Mod Ref    : DefNBS025514/PM017007
-- Mod Desc   : MODIFIED the function TSL_COPY_BASE_ATTRIB to avoid launch date getting cascaded
--              from base to variant.
--------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P, bharagavi.pujari@in.tesco.com
-- Mod Date   : 11-Oct-2012
-- Mod Ref    : DefNBS025514/PM017007
-- Mod Desc   : MODIFIED the function TSL_COPY_ITEM_ATTRIB to avoid launch date getting cascaded
--              from Style(TPNA) to variant and TSL_COPY_ITEM_PACK_ATTRIB to avoid the
--              cascade to variant's pack.
--------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P, bharagavi.pujari@in.tesco.com
-- Mod Date   : 19-Oct-2012
-- Mod Ref    : MrgNBS025514
-- Mod Desc   : Merged DefNBS025514/PM017007 (3.7 to 3.5b merge)
--------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P, bharagavi.pujari@in.tesco.com
-- Mod Date   : 18-Oct-2012
-- Mod Ref    : DefNBS025514b/PM017007
-- Mod Desc   : Removed the DefNBS025514 changes as per the latest design changes
--              which is to cascade the launch date from TPNA if variant is already exists.
--------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P, bharagavi.pujari@in.tesco.com
-- Mod Date   : 19-Oct-2012
-- Mod Ref    : MrgNBS025514b
-- Mod Desc   : Merged DefNBS025514b/PM017007 (3.7 to 3.5b merge)
--------------------------------------------------------------------------------------
-- Mod By     : Bhargavi P, bharagavi.pujari@in.tesco.com
-- Mod Date   : 08-Nov-2013
-- Mod Ref    : NBS00026492/PM020648(work around fix)
-- Mod Desc   : Modified TSL_COPY_ITEM_ATTRIB to avoid tarif code cascading from TPNA to TPNB.
----------------------------------------------------------------------------------------------------
-- Mod By     : V Manikandan
-- Mod Date   : 21-Mar-2014
-- Mod Ref    : MrgNBS26492 (PM20648 Permanent Fix)
-- Mod Desc   : The work around fix #26492 has removed
----------------------------------------------------------------------------------------------------
-- Mod by     : V Manikandan
-- Mod ref    : MrgNBS26492
-- Mod Desc   : The PM020648 have merged from 3.5b to PRDSi.
----------------------------------------------------------------------------------------------------
-- Mod By:      Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com
-- Mod Date:    23-Oct-2013
-- Def Ref:     PM020648
-- Def Details: Modified the functions COPY_DOWN_PARENT_ATTRIB,TSL_COPY_BASE_ATTRIB,TSL_COPY_ITEM_ATTRIB,
--              TSL_COPY_ITEM_ATTRIB_L3 and TSL_COPY_ITEM_PACK_ATTRIB to exclude the predefined attributes during cascade.
----------------------------------------------------------------------------------------------------

FUNCTION COPY_DOWN_PARENT_ATTRIB (O_error_message  IN OUT VARCHAR2,
                                  I_item           IN     ITEM_MASTER.ITEM%TYPE,
                                  -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                  I_country_id     IN     VARCHAR2,
                                  -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                  I_login_ctry     IN      VARCHAR2,
                                  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                                  I_column_name    IN     VARCHAR2,
                                  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                                  -- 14-Apr-11     Nandini M     PrfNBS022237     End
                                  -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                                  I_exclude_in_cascade IN  VARCHAR2 DEFAULT  'N'
                                  -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                  )

   RETURN BOOLEAN IS

   -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
   L_uk_ind        VARCHAR2(1) :=  'N';
   L_roi_ind       VARCHAR2(1) :=  'N';
   L_login_ctry    ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
   -- 14-Apr-11    Nandini M     PrfNBS022237     End
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   ------------------------------------------------------
   -- 03-Oct-2007 Govindarajan - MOD N20a Begin
   ------------------------------------------------------
   L_item_rec      ITEM_MASTER%ROWTYPE;
   L_program       VARCHAR2(300)   := 'ITEM_ATTRIB_DEFAULT_SQL.COPY_DOWN_PARENT_ATTRIB';

   cursor C_LOCK_ATTRIB is
      select 'x'
        from item_attributes ia
       where exists (select 'x'
                       from item_master im
                      where im.item = ia.item
                        and (im.item_parent = I_item
                         or im.item_grandparent = I_item))
         for update nowait;
   -------------------------------------------------------
   -- 03-Oct-2007 Govindarajan - MOD N20a End
   -------------------------------------------------------

BEGIN
  if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_item,
                                            L_program,
                                            NULL);
      return FALSE;
  end if;
  ---
  SQL_LIB.SET_MARK('OPEN',
                   'C_LOCK_ATTRIB',
                   'ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item);
  open C_LOCK_ATTRIB;

  SQL_LIB.SET_MARK('CLOSE',
                   'C_LOCK_ATTRIB',
                   'ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item);
  close C_LOCK_ATTRIB;
  ---------------------------------------------------------------------------------------------
  -- 03-Oct-2007 Govindarajan - MOD N20a Begin
  ---------------------------------------------------------------------------------------------
  if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                      L_item_rec,
                                      I_item) = FALSE then
    return FALSE;
  end if;

  L_login_ctry := I_login_ctry;
  ---
  if L_item_rec.tran_level = 2 and
     L_item_rec.item_level <= L_item_rec.tran_level and
     L_item_rec.pack_ind = 'N' then
      -- To copy item attribures from Level 1 to Level 2 base items and it's children/base Level 3 children
      if (L_item_rec.tsl_base_item = L_item_rec.item) or
         (L_item_rec.item_level = 1 ) then
          ---
         if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_ATTRIB (O_error_message,
                                                           L_item_rec,
                                                           'Y',
                                                           -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                           I_country_id,
                                                           -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
                                                           L_login_ctry,
                                                           -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                                                           I_column_name,
                                                           -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                                                           -- 14-Apr-11    Nandini M     PrfNBS022237     End
                                                           -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                                                           I_exclude_in_cascade
                                                           -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                                           ) = FALSE then
                                                           -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
              return FALSE;
          end if;
 ---
      end if;
      ---
      if (L_item_rec.tsl_base_item != L_item_rec.item) or
         (L_item_rec.item_level = 1 ) then
          -- To copy item attribures from Level 1 to Level 2 variant items it's Level 3 children/variant Level 3 children
          if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_ATTRIB (O_error_message,
                                                           L_item_rec,
                                                           'N',
                                          -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                           I_country_id,
                                                           -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
                                                           L_login_ctry,
                                                           -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                                                           I_column_name,
                                                           -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                                                           -- 14-Apr-11    Nandini M     PrfNBS022237     End
                                                           -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                                                           I_exclude_in_cascade
                                                           -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                                           ) = FALSE then
                                          -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
              return FALSE;
          end if;
          ---
      end if;
      -- CR258 22-Apr-2010 Chandru Begin
      if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_PACK_ATTRIB (O_error_message,
                                                            L_item_rec,
                                                            'N',
                                                            I_country_id,
                                                            -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
                                                            L_login_ctry,
                                                            -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                                                            I_column_name,
                                                            -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                                                            -- 14-Apr-11    Nandini M     PrfNBS022237     End
                                                            -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                                                            I_exclude_in_cascade
                                                            -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                                            ) = FALSE then
         return FALSE;
      end if;
      -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
      -- 28-Sep-2010  Praveen      PrfNBS018117d     End
      --CR258 22-Apr-2010 Chandru End
      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
      -- 31-Aug-2010  JK          MrgNBS018918      Begin
      -- DefNBS018719 12-Aug-2010 V Manikandan ---- Begin
      -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
      if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_BASE_ATTRIB (O_error_message,
                                                       L_item_rec.item,
                                                       I_country_id,
                                                       -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                                       L_login_ctry,
                                                       -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                                                       I_column_name,
                                                       -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                                                       -- 14-Apr-11     Nandini M     PrfNBS022237     End
                                                       -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                                                       I_exclude_in_cascade
                                                       -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                                       ) = FALSE then
         return FALSE;
      end if;
      -- DefNBS018719 12-Aug-2010 V Manikandan ---- End
      -- 28-Sep-2010  Praveen          PrfNBS018117d      End
      -- 31-Aug-2010  JK          MrgNBS018918      End
      -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
  end if;
  ---
  if L_item_rec.tran_level = 1 then
      -- To copy item attribures from Level 1 pack to Level 2 packs
      if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_ATTRIB (O_error_message,
                                                       L_item_rec,
                                                       NULL,
                                          -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                       I_country_id,
                                                       -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
                                                       L_login_ctry,
                                                       -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                                                       I_column_name,
                                                       -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                                                       -- 14-Apr-11    Nandini M     PrfNBS022237     End
                                                       -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                                                       I_exclude_in_cascade
                                                       -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                                       ) = FALSE then
                                          -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com,End
          return FALSE;
      end if;
  end if;
  ---------------------------------------------------------------------------------------------
  -- 03-Oct-2007 Govindarajan - MOD N20a End
  ---------------------------------------------------------------------------------------------
  return TRUE;
EXCEPTION
  when RECORD_LOCKED then
    O_error_message := sql_lib.create_msg('TABLE_LOCKED',
                                         'ITEM_ATTRIBUTES',
                                         I_item);
    return FALSE;
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                          SQLERRM,
                                          'ITEM_ATTRIB_DEFAULT_SQL.COPY_DOWN_PARENT_ATTRIB',
                                          to_char(SQLCODE));
    return FALSE;
END COPY_DOWN_PARENT_ATTRIB;
-----------------------------------------------------------------------------------------
-- 28-Jun-2007 Govindarajan - MOD 365b1 Begin
-----------------------------------------------------------------------------------------
-- Function Name : TSL_COPY_BASE_ATTRIB
-- Purpose       : Cascading the Level2 base atrributes to Level2 Varinats and it's children.
--                 Common information will be updated, exceptions will be kept.
---------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_BASE_ATTRIB (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_base_item      IN     ITEM_MASTER.ITEM%TYPE,
                               -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                               I_country_id     IN     VARCHAR2,
                               -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                               -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                               I_login_ctry     IN     VARCHAR2,
                               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                               I_column_name    IN     VARCHAR2,
                               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                               -- 14-Apr-11     Nandini M     PrfNBS022237     End
                               -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                               I_exclude_in_cascade IN  VARCHAR2 DEFAULT  'N'
                               -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                               )

    return BOOLEAN is

    L_table        VARCHAR2(30)    := 'ITEM_ATTRIBUTES';
    L_program      VARCHAR2(300)   := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_BASE_ATTRIB';
    L_close_cursor VARCHAR2(2000)  := ' close C_get_item_attrib;';
    L_end          VARCHAR2(10)    := ' end;';
    L_sql_select   VARCHAR2(32767) := NULL;
    L_sql_insert   VARCHAR2(32767) := NULL;
    L_sql_update   VARCHAR2(32767) := NULL;
    L_sql_column   VARCHAR2(32767) := NULL;
    L_statement    VARCHAR2(32767) := NULL;
    L_dept         DEPS.DEPT%TYPE;
    L_class        CLASS.CLASS%TYPE;
    L_subclass     SUBCLASS.SUBCLASS%TYPE;
    L_valid        BOOLEAN;
    --CR354 16-Aug-10 Praveen Begin
    L_tsl_loc_sec_ind   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
    L_owner_cntry   SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
    --CR354 16-Aug-10 Praveen End
    RECORD_LOCKED  EXCEPTION;
    PRAGMA         EXCEPTION_INIT(Record_Locked, -54);
    --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
    L_system_options_row    SYSTEM_OPTIONS%ROWTYPE;
    L_owner_country         ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
    L_security_ind          SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
    L_login_ctry            ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
    L_uk_ind                VARCHAR2(1) :=  'N';
    L_roi_ind               VARCHAR2(1) :=  'N';
     --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End

    -- This cursor will lock the variant items on the table ITEM_ATTRIBUTES table
    cursor C_LOCK_ITEM_ATTRIBUTES_LV2 is
      select 'x'
        from item_attributes ia
       where ia.item in (select im.item
                           from item_master im
                          where im.tsl_base_item    = I_base_item
                            and im.tsl_base_item   != im.item
                            and im.item_level       = im.tran_level
                            and im.item_level       = 2)
         -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         and ia.tsl_country_id = I_country_id
         -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
         for update nowait;

    -- This cursor will lock the children of the variant item on the table ITEM_ATTRIBUTES table
    cursor C_LOCK_ITEM_ATTRIBUTES_LV3 is
      select 'x'
        from item_attributes ia
       where ia.item in (select im2.item
                           from item_master im1,
                                item_master im2
                          where im1.tsl_base_item    = I_base_item
                            and im1.tsl_base_item   != im1.item
                            and im1.item_level       = im1.tran_level
                            and im1.item_level       = 2
                            and im1.item             = im2.item_parent)
         -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         and ia.tsl_country_id = I_country_id
         -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
         for update nowait;

    -- This cursor will retrieve the codes, and the corresponding column for the
    -- attributes that can be copied between the Base Item to its Variant Items.
    -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
    -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
    cursor C_GET_COLUMNS_LVL2 is
     select m.tsl_column_name column_name,
            m.tsl_code code,
            mb.required_ind req_ind
       from tsl_map_item_attrib_code m,
            merch_hier_default mb
      where m.tsl_column_name =  NVL(upper(I_column_name),m.tsl_column_name)
        and mb.tsl_var_ind = 'Y'
        and mb.available_ind = 'Y'
        and mb.tsl_item_lvl = 2
        -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
        and mb.tsl_country_id in (I_country_id,'B')
        -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
        and mb.dept = L_dept
        and mb.class = L_class
        and mb.subclass = L_subclass
        and mb.info = m.tsl_code
        -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, Begin
        -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, Begin
        -- Added TLDT as part of this defect
        and mb.info not in ('TEPW','TMQ','TLDT')
        -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, End
        -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, End
        and (exists (select 1
                      from merch_hier_default a
                     where a.tsl_base_ind = 'Y'
                       and a.info = mb.info
                       and a.available_ind = 'Y'
                       and a.tsl_item_lvl = 2
                       -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                       and a.tsl_country_id in (I_country_id,'B')
                       -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                       and a.dept = mb.dept
                       and a.class = mb.class
                       and a.subclass = mb.subclass)
                 or
         not exists (select 1
                       from merch_hier_default a
                      where a.tsl_base_ind = 'Y'
                        and a.info = mb.info
                        and a.tsl_item_lvl = 2
                        -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                        and a.tsl_country_id in (I_country_id,'B')
                        -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                        and a.dept = mb.dept
                        and a.class = mb.class
                        and a.subclass = mb.subclass))
    -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
		and (
			 (I_exclude_in_cascade='Y'
			  and not exists(select 1
							   from tsl_attr_stpcas sca
							  where sca.tsl_itm_attr_id=m.tsl_code
							)
			  )
			 or I_exclude_in_cascade='N'
			 )
     -- 23-Oct-2013  Gopinath Meganathan PM020648 End
      union
      select m.tsl_column_name column_name,
             m.tsl_code code,
             'N' req_ind
        from tsl_map_item_attrib_code m
       where m.tsl_column_name =  NVL(upper(I_column_name),m.tsl_column_name)
         -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, Begin
         -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, Begin
         -- Added TLDT as part of this defect
         and m.tsl_code not in ('TEPW','TMQ','TLDT')
         -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 09-Oct-12, End
         -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, End
         -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
         and not exists (select 1
                          from merch_hier_default a
                         where a.info = m.tsl_code
                           and a.tsl_var_ind = 'Y'
                           and a.tsl_item_lvl = 2
                           -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                           and a.tsl_country_id in (I_country_id,'B')
                           -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                           and a.dept = L_dept
                           and a.class = L_class
                           and a.subclass = L_subclass)
         and not exists (select 1
                          from merch_hier_default a
                         where a.info = m.tsl_code
                           and a.tsl_base_ind = 'Y'
                           and a.available_ind = 'N'
                           and a.tsl_item_lvl = 2
                           -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                           and a.tsl_country_id in (I_country_id,'B')
                           -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                           and a.dept = L_dept
                           and a.class = L_class
                           and a.subclass = L_subclass)
		and (
			 (I_exclude_in_cascade='Y'
			  and not exists(select 1
							   from tsl_attr_stpcas sca
							  where sca.tsl_itm_attr_id=m.tsl_code
							)
			  )
			 or I_exclude_in_cascade='N'
			 );
        -- 23-Oct-2013  Gopinath Meganathan PM020648 End

   -- 14-Apr-11     Nandini M     PrfNBS022237     End
   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end

    -- This cursor will retrieve the codes, and the corresponding column for the
    -- attributes that can be copied between the Base Item to the level3 item.
    -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
    -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
    cursor C_GET_COLUMNS_LVL3 is
      select m.tsl_column_name column_name,
             m.tsl_code code,
             mb.required_ind req_ind
        from tsl_map_item_attrib_code m,
             merch_hier_default mb
       where m.tsl_column_name =  NVL(upper(I_column_name),m.tsl_column_name)
         and mb.available_ind = 'Y'
         and mb.tsl_item_lvl = 3
         -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         and mb.tsl_country_id in (I_country_id,'B')
         -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
         and mb.dept = L_dept
         and mb.class = L_class
         and mb.subclass = L_subclass
         and mb.info = m.tsl_code
         -- 04-Jan-2011, DefNBS020385, Venkatesh S, venkatesh.suvarna@in.tesco.com, Begin
         -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, Begin
         -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, Begin
         -- Added TLDT as part of this defect
         and mb.info NOT IN ('TEPW','TTC','TSU','TMQ','TLDT')
         -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, End
         -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, End
          -- 04-Jan-2011, DefNBS020385, Venkatesh S, venkatesh.suvarna@in.tesco.com, End
         and ((exists (select 1
                         from merch_hier_default a
                        where a.tsl_var_ind = 'Y'
                          and a.available_ind = 'Y'
                          and a.tsl_item_lvl = 2
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                          and a.tsl_country_id in (I_country_id,'B')
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                          and a.info = mb.info
                          and a.dept = mb.dept
                          and a.class = mb.class
                          and a.subclass = mb.subclass)
               or
               not exists (select 1
                             from merch_hier_default a
                            where a.tsl_var_ind = 'Y'
                              and a.tsl_item_lvl = 2
                              -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                              and a.tsl_country_id in (I_country_id,'B')
                              -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                              and a.info = mb.info
                              and a.dept = mb.dept
                              and a.class = mb.class
                              and a.subclass = mb.subclass))
         and (exists (select 1
                        from merch_hier_default a
                       where a.tsl_base_ind = 'Y'
                         and a.available_ind = 'Y'
                         and a.tsl_item_lvl = 2
                         -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                         and a.tsl_country_id in (I_country_id,'B')
                         -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                         and a.info = mb.info
                         and a.dept = mb.dept
                         and a.class = mb.class
                         and a.subclass = mb.subclass)
              or
              not exists (select 1
                            from merch_hier_default a
                           where a.tsl_base_ind = 'Y'
                             and a.tsl_item_lvl = 2
                             -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                             and a.tsl_country_id in (I_country_id,'B')
                             -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                             and a.info = mb.info
                             and a.dept = mb.dept
                             and a.class = mb.class
                             and a.subclass = mb.subclass)))
      		 -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
		and (
			 (I_exclude_in_cascade='Y'
			  and not exists(select 1
							   from tsl_attr_stpcas sca
							  where sca.tsl_itm_attr_id=m.tsl_code
							)
			  )
			 or I_exclude_in_cascade='N'
			 )
        -- 23-Oct-2013  Gopinath Meganathan PM020648 End
      union
       select m.tsl_column_name column_name,
              m.tsl_code code,
              'N' req_ind
         from tsl_map_item_attrib_code m
        where not exists (select 1
                           from merch_hier_default a
                          where a.info = m.tsl_code
                            and a.tsl_item_lvl = 3
                            -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                            and a.tsl_country_id in (I_country_id,'B')
                            -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                            and a.dept = L_dept
                            and a.class = L_class
                            and a.subclass = L_subclass)
         and not exists (select 1
                          from merch_hier_default a
                         where a.info = m.tsl_code
                           and a.available_ind = 'N'
                           and a.tsl_item_lvl = 2
                           -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                           and a.tsl_country_id in (I_country_id,'B')
                           -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                           and a.tsl_pack_ind = 'N'
                           and a.dept = L_dept
                           and a.class = L_class
                           and a.subclass = L_subclass)
  -- 04-Jan-2011, DefNBS020385, Venkatesh S, venkatesh.suvarna@in.tesco.com, Begin
          and m.tsl_column_name =  NVL(upper(I_column_name),m.tsl_column_name)
          -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, Begin
          -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, Begin
          -- Added TLDT as part of this defect
          and m.tsl_code NOT IN('TEPW','TTC','TSU','TMQ','TLDT')
          -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
		 		 and (
				 (I_exclude_in_cascade='Y'
				  and not exists(select 1
								   from tsl_attr_stpcas sca
								  where sca.tsl_itm_attr_id=m.tsl_code
								)
				  )
				 or I_exclude_in_cascade='N'
			 );
        -- 23-Oct-2013  Gopinath Meganathan PM020648 End

          -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, End
          -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, End
  -- 14-Apr-11     Nandini M     PrfNBS022237     End
  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
  -- 04-Jan-2011, DefNBS020385, Venkatesh S, venkatesh.suvarna@in.tesco.com, End
   -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - Begin
   -- The cursor is no longer needed becuase its not possible for the base and variant to have
   -- different brand indicators.
   -- CR242, 03-Aug-2009, shweta.mandawat@in.tesco.com - Begin
   -- Cursor to select the variants which have barcode.
   -- CR242, 03-Aug-2009, shweta.mandawat@in.tesco.com - End
   -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - End
   -- CR258 22-Apr-2010 Chandru Begin
   -- To get variant packs for the passed base item
   cursor C_VAR_PACKS is
      select im.item item
        from item_master im
       where im.tsl_base_item    = I_base_item
         and im.tsl_base_item   != im.item
         and im.item_level       = im.tran_level
         and im.item_level       = 2
         -- CR354 18-Aug-2010 Praveen Begin
         and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry));
         -- CR354 18-Aug-2010 Praveen End
   L_item_rec      ITEM_MASTER%ROWTYPE;
   -- CR258 22-Apr-2010 Chandru End
BEGIN

   -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
   L_login_ctry := I_login_ctry;
   -- 14-Apr-11    Nandini M     PrfNBS022237     End

   --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_system_options_row) = FALSE then
      return FALSE;
   end if;
   ---
   L_security_ind := L_system_options_row.tsl_loc_sec_ind;
   ---
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                       L_item_rec,
                                       I_base_item) = FALSE then
   return FALSE;
   end if;
   ---
   -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
   -- MrgNBS022368(fix), 19-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com Begin
   if L_security_ind = 'Y' and NVL(I_login_ctry,'N') = 'N' then
   -- MrgNBS022368(fix), 19-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com End
   -- 14-Apr-11     Nandini M     PrfNBS022237     End
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
   end if;
   --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
      if I_base_item is NULL then                                       -- L1 begin
          -- If input item is null then throws an error
          O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                I_base_item,
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
                                                  I_base_item) = FALSE then
           return FALSE;
        end if;
        --CR354 16-Aug-10 Praveen End

          -- function to get the dept, class and subclass based on the base item
          L_valid := ITEM_ATTRIB_SQL.GET_MERCH_HIER (O_error_message,
                                                     I_base_Item,
                                                     L_dept,
                                                     L_class,
                                                     L_subclass);
          if L_valid = TRUE then        -- L2 begin
              -- This cursor will retrieve the codes, and the corresponding column for the attributes
              -- that can be copied between the Base Item to its Variant Items
              --Opening the cursor C_GET_COLUMNS_LVL2
              SQL_LIB.SET_MARK('OPEN',
                               'C_GET_COLUMNS_LVL2',
                               'TSL_MAP_ITEM_ATTRIB_CODE',
                               'ITEM: ' ||I_base_item);

              FOR C_rec in C_GET_COLUMNS_LVL2
              LOOP                                -- L3 begin
                 -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - Begin
                 -- Removed the below if condition as its not possible to have parent and child
                 -- with different brand indicators.
                 -- CR242, 04-Aug-2009, shweta.mandawat@in.tesco.com - Begin
                 -- L3 begin
                 -- The brand indicator will not be cascaded. New logic for cascading below.
                 -- CR242, 04-Aug-2009, shweta.mandawat@in.tesco.com - End
                 -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - End
                 -- checking L_sql_select is null or not
                 if L_sql_select is NULL then      -- L4 begin
                    L_sql_insert := 'ia.'||C_rec.column_name;
                    L_sql_select := C_rec.column_name;
                    --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
                    if (((L_item_rec.tsl_owner_country = L_login_ctry) or
                       L_security_ind = 'N') or
                       (L_item_rec.tsl_owner_country <> L_login_ctry and
                       -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
                       L_security_ind = 'Y'
                       -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
                        )) then
                       -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                       -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                       -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 Begin
                       if c_rec.code <> 'TLDT' then
                          L_sql_update := C_rec.column_name||' = decode(''' ||C_rec.req_ind || ''',
                                          '' Y'',' || ' nvl(row_data.' || C_rec.column_name || ','
                                          ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
                       elsif c_rec.code = 'TLDT' then
                          L_sql_update := C_rec.column_name||' = row_data.' || C_rec.column_name ;
                       end if;
                       -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 End
                    end if;
                    --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
                    -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, Begin
                    -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, Begin
                    -- Added TLDT as part of this defect
                    L_sql_column := ' and tmc.tsl_code NOT in (''TEPW'',''TMQ'',''TLDT''';
                    -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, Begin
                    -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, End
                  else                        -- L4 else
                     L_sql_insert := L_sql_insert ||',ia.'|| C_rec.column_name;
                     L_sql_select := L_sql_select || ', ' || C_rec.column_name;
                     --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
                     if (((L_item_rec.tsl_owner_country = L_login_ctry) or
                        L_security_ind = 'N') or
                        (L_item_rec.tsl_owner_country <> L_login_ctry and
                        L_security_ind = 'Y'
                        -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
                        -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
                        )) then
                        -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                        -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                        -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 Begin
                        if c_rec.code <> 'TLDT' then
                           L_sql_update := L_sql_update || ', ' || C_rec.column_name || ' =
                                           decode(''' || C_rec.req_ind || ''',''Y'',' || ' nvl(row_data.'
                                           || C_rec.column_name || ','  ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
                        elsif c_rec.code = 'TLDT' then
                           L_sql_update := L_sql_update || ', ' || C_rec.column_name || ' = row_data.'
                                           || C_rec.column_name ;
                        end if;
                        -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 End
                     end if;
                      --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
                  end if;                     -- L4 end
                  -- checking req_ind is 'Y' or 'N'
                  if C_rec.req_ind = 'N' then        -- L5 begin
                      L_sql_column := L_sql_column || ', '''|| C_rec.code || '''';
                  else            -- L5 else
                      L_sql_column := L_sql_column || ', decode(ia.' || C_rec.column_name ||
                                      ', null, ''x'', ''' || C_rec.code || ''')';
                  end if;          -- L5 end
              END LOOP;          -- L3 end
              if L_sql_column is NOT NULL then          -- L6 begin
                  L_sql_column := L_sql_column||')';
              end if;     -- L6 end
              --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
              --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   Begin
              if L_security_ind = 'Y' then
                 ---
                 L_owner_country := L_item_rec.tsl_owner_country;
                 ---
              --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   End
              elsif L_security_ind = 'N' then
                 L_owner_country := 'U';
              end if;
              --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
              -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
              -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
              if L_sql_update is NOT NULL then
               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
              -- Populate the L_sql_update variable for the update of the Level 2 Variant Items information
              L_sql_update := ' update item_attributes' ||
                              ' set ' || L_sql_update ||
                            -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                            ' where tsl_country_id = :I_country_id'||
                            -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                              ' and item in (select im.item' ||
                                               ' from item_master im' ||
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, Begin
                                              ' where im.tsl_base_item = :I_base_item '||
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, End
                                                ' and im.item != im.tsl_base_item' ||
                                                ' and im.item_level = im.tran_level' ||
                                                --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
                                                ' and im.item_level = 2 and ((im.tsl_owner_country = :L_owner_country) or (:L_security_ind = ''N'')));';
                                                --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
              -- Populate the L_sql_insert variable for the insert of the Level 2 Variant Items information
              -- CR236, 06-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
              -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin

              end if;
              -- 14-Apr-11     Nandini M     PrfNBS022237     End
              -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
              if L_sql_insert is NOT NULL then
              -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
              L_sql_insert := ' insert into item_attributes (item, tsl_country_id, ' || L_sql_select || ' )' ||
                                  ' select im.item, :I_country_id2,'|| L_sql_insert ||
              -- CR236, 06-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                  '   from item_master im, item_attributes ia'||
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, Begin
                                  '  where ia.item = :I_base_item2 '||
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, End
                              -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                     ' and ia.tsl_country_id = :I_country_id3'||
                              -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                     ' and im.tsl_base_item = ia.item'||
                                     ' and im.tsl_base_item != im.item'||
                                     ' and im.item_level = im.tran_level'||
                                     ' and im.item_level = 2'||
                                     ' and NOT exists (select 1' ||
                                                       ' from item_attributes b' ||
                                                      ' where b.item = im.item ' ||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                      '   and b.tsl_country_id = :I_country_id4)' ||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                                        ' and NOT exists (select 1' ||
                                                                          ' from merch_hier_default mhd,' ||
                                                                               ' tsl_map_item_attrib_code tmc' ||
                                                                         ' where mhd.info = tmc.tsl_code' ||
                                                                           ' and mhd.required_ind = ''Y''' ||
                                                                           ' and mhd.tsl_var_ind = ''Y''' ||
                                                                           ' and mhd.tsl_item_lvl = ''2''' ||
                                                                           -- CR236, 10-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                                           ' and mhd.tsl_country_id in (''B'',:I_country_id5) '||
                                                                           -- CR236, 10-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                                                           ' and mhd.dept = :L_dept' ||
                                                                           ' and mhd.class = :L_class' ||
                                                                           ' and mhd.subclass = :L_subclass' ||
                                                                           L_sql_column || ');';
              -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
              end if;
              -- 14-Apr-11     Nandini M     PrfNBS022237     End
               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
              -- Populate the L_sql_select variable for the select of the Level 2 Base Item information
              L_sql_select := ' select '|| L_sql_select ||
                                ' from item_attributes' ||
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, Begin
                               ' where item = :I_base_item3 '||
                                   -- CR236, 02-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                               '   and tsl_country_id = :I_country_id6;';
                                   -- CR236, 02-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, End
              -- 28-Sep-2010  Praveen      PrfNBS018117d     End
              if L_sql_select is NOT NULL then       -- L7 begin
                  SQL_LIB.SET_MARK('OPEN',
                                   'C_LOCK_ITEM_ATTRIBUTES_LV2',
                                   'ITEM_ATTRIBUTES',
                                   'ITEM: ' ||I_base_item);

                  open C_LOCK_ITEM_ATTRIBUTES_LV2;
                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_LOCK_ITEM_ATTRIBUTES_LV2',
                                   'ITEM_ATTRIBUTES',
                                   'ITEM: ' ||I_base_item);
                  close C_LOCK_ITEM_ATTRIBUTES_LV2;

                  -- Populate the L_statement variable to be used on the Execute Immediate statement
                  L_statement := 'Declare' ||
                                 ' Cursor C_get_item_attrib is' ||
                                        L_sql_select ||
                                 ' row_data C_get_item_attrib%ROWTYPE;' ||
                                 ' Begin' ||
                                      ' open C_get_item_attrib;'||
                                      ' fetch C_get_item_attrib into row_data;';
                  -- Execute the Dynamic SQL, using the instruction EXECUTE IMMEDIATE
                  -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
                -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
                -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin  Replace the I_country_id with L_Login_ctry to 3rd passing parameter
                  --DefNBS021727,25-Feb-2011,Sripriya,Sripriya.karanam@in.tesco.com,Begin
                  --replacing back I_country_id to L_Login_ctry for 3rd parameter
                  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                  if L_sql_insert is NOT NULL or  L_sql_update is NOT NULL then
                     EXECUTE IMMEDIATE L_statement||L_sql_update||L_close_cursor||L_sql_insert||L_end using I_base_item,I_country_id,I_country_id,I_base_item,L_owner_country,L_security_ind,I_country_id,I_base_item,I_country_id,I_country_id,I_country_id,L_dept,L_class,L_subclass;
                  end if;
                  -- 14-Apr-11     Nandini M     PrfNBS022237     End
                   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                  --DefNBS021727,25-Feb-2011,Sripriya,Sripriya.karanam@in.tesco.com,End
                  -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                  -- 28-Sep-2010  Praveen      PrfNBS018117d     End
              end if;    -- L7 end
              -- clearing the variable values
              L_sql_insert := NULL;
              L_sql_update := NULL;
              L_sql_column := NULL;
              L_sql_select := NULL;
              L_statement  := NULL;

              -- This cursor will retrieve the codes, and the corresponding column for the
              -- attributes that can be copied between the Base Item to the Variant Items children

              --Opening the cursor C_GET_COLUMNS_LVL3
              SQL_LIB.SET_MARK('OPEN',
                               'C_GET_COLUMNS_LVL3',
                               'TSL_MAP_ITEM_ATTRIB_CODE',
                               'ITEM: ' ||I_base_item);

              FOR C_rec in C_GET_COLUMNS_LVL3
              LOOP                                -- L8 begin
                 -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - Begin
                 -- Removed the below if condition as its not possible to have parent and child
                 -- with different brand indicators.
                 -- CR242, 04-Aug-2009, shweta.mandawat@in.tesco.com - Begin
                 -- Cascading of barcode to L3 items will not happen.
                 -- CR242, 04-Aug-2009, shweta.mandawat@in.tesco.com - End
                 -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - End
                 -- checking L_sql_select is null or not
                  if L_sql_select is NULL then      -- L9 begin
                      L_sql_insert := 'ia.'||C_rec.column_name;
                      L_sql_select := C_rec.column_name;
                      --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
                      if (((L_item_rec.tsl_owner_country = L_login_ctry) or
                          L_security_ind = 'N') or
                          (L_item_rec.tsl_owner_country <> L_login_ctry and
                           L_security_ind = 'Y'
                          -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
                          -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
                           /* and
                           C_rec.column_name NOT in
                           ('TSL_DIAMOND_LINE_IND','TSL_DEV_LINE_IND','TSL_LAUNCH_DATE','TSL_POS_CODES','TSL_DEV_END_DATE')*/)) then
                           -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                           -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                           L_sql_update := C_rec.column_name||' = decode(''' ||C_rec.req_ind || ''',
                                            ''Y'',' || ' nvl(row_data.' || C_rec.column_name || ','
                                            ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
                      end if;
                       --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
                      -- 04-Jan-2011, DefNBS020385, Venkatesh S, venkatesh.suvarna@in.tesco.com, Begin
                      -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, Begin
                      -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, Begin
                      -- Added TLDT as part of this defect
                      L_sql_column := ' and tmc.tsl_code NOT in (''TEPW'',''TTC'',''TMQ'',''TLDT'',''TSU''';
                      -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 08-Oct-12, End
                      -- DefNBS024857/PM015114, Vinutha Raju, vinutha.raju@in.tesco.com, 09-May-12, End
                      -- 04-Jan-2011, DefNBS020385, Venkatesh S, venkatesh.suvarna@in.tesco.com, End
                  else                        -- L9 else
                      L_sql_insert := L_sql_insert ||',ia.'|| C_rec.column_name;
                      L_sql_select := L_sql_select || ', ' || C_rec.column_name;
                      --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
                      if (((L_item_rec.tsl_owner_country = L_login_ctry) or
                          L_security_ind = 'N') or
                          (L_item_rec.tsl_owner_country <> L_login_ctry and
                           L_security_ind = 'Y'
                           -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
                           -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
                           /* and
                           C_rec.column_name NOT in
                           ('TSL_DIAMOND_LINE_IND','TSL_DEV_LINE_IND','TSL_LAUNCH_DATE','TSL_POS_CODES','TSL_DEV_END_DATE') */)) then
                           -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                           -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                           L_sql_update := L_sql_update || ', ' || C_rec.column_name || ' =
                                           decode(''' || C_rec.req_ind || ''',''Y'',' || ' nvl(row_data.'
                                           || C_rec.column_name || ','  ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
                      end if;
                      --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
                  end if;                     -- L9 end
                  -- checking req_ind is 'Y' or 'N'
                  if C_rec.req_ind = 'N' then        -- L10 begin
                      L_sql_column := L_sql_column || ', '''|| C_rec.code || '''';
                  else            -- L10 else
                      L_sql_column := L_sql_column || ', decode(ia.' || C_rec.column_name ||
                                      ', null, ''x'', ''' || C_rec.code || ''')';
                  end if;          -- L10 end
              END LOOP;          -- L8 end
              if L_sql_column is NOT NULL then          -- L11 begin
                  L_sql_column := L_sql_column||')';
              end if;     -- L11 end
              --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
              --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   Begin
              if L_security_ind = 'Y' then
                 ---
                 L_owner_country := L_item_rec.tsl_owner_country;
                 ---
              --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   End
              elsif L_security_ind = 'N' then
                 L_owner_country := 'U';
              end if;
              --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
              -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
              -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
              -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
              if L_sql_update is NOT NULL then
               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
              -- Populate the L_sql_update variable for the update of the Level 3 Items information
              L_sql_update := ' update item_attributes' ||
                                 ' set ' || L_sql_update ||
                               -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                               ' where tsl_country_id = :I_country_id'||
                               -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                 ' and item in (select im2.item' ||
                                                ' from item_master im1,' ||
                                                '      item_master im2'||
                               -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, Begin
                                               ' where im1.tsl_base_item     = :I_base_item '||
                               -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, End
                                         -- Commented by Nitin Kumar for mod N20 on 06-Sep-2007, Nitin.Kumar@in.tesco.com, Begin
                                                 ' and im1.item       != im1.tsl_base_item' ||
                                         -- Commented by Nitin Kumar for mod N20 on 06-Sep-2007, Nitin.Kumar@in.tesco.com, End
                                                 ' and im1.item_level  = im1.tran_level' ||
                                                 ' and im2.item_parent = im1.item' ||
                                                 --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
                                                 ' and im1.item_level = 2 and ((im1.tsl_owner_country = :L_owner_country) or (:L_security_ind = ''N'')));';
                                                 --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
              end if;
              if L_sql_insert is NOT NULL then
               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end

              -- Populate the L_sql_insert variable for the insert of the Level 3 Items information
              -- CR236, 06-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
              L_sql_insert := ' insert into item_attributes (item, tsl_country_id, ' || L_sql_select || ' )' ||
                                  ' select im2.item, :I_country_id2,'|| L_sql_insert ||
              -- CR236, 06-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                    ' from item_master im1, item_master im2, item_attributes ia'||
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, Begin
                                   ' where ia.item = :I_base_item2 '||
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, End
                              -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                     ' and ia.tsl_country_id = :I_country_id3'||
                              -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                     ' and im1.tsl_base_item = ia.item'||
                               -- Commented by Nitin Kumar for mod N20 on 06-Sep-2007, Nitin.Kumar@in.tesco.com, Begin
                                     ' and im1.tsl_base_item != im1.item'||
                               -- Commented by Nitin Kumar for mod N20 on 06-Sep-2007, Nitin.Kumar@in.tesco.com, End
                                     ' and im1.item_level = im1.tran_level'||
                                     ' and im1.item_level = 2'||
                                     ' and im1.item = im2.item_parent' ||
                                     ' and NOT exists (select 1' ||
                                                       ' from item_attributes b' ||
                                                      ' where b.item = im2.item ' ||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                      '   and b.tsl_country_id = :I_country_id4)' ||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                                        ' and NOT exists (select 1' ||
                                                                          ' from merch_hier_default mhd,' ||
                                                                               ' tsl_map_item_attrib_code tmc' ||
                                                                         ' where mhd.info = tmc.tsl_code' ||
                                                                           ' and mhd.required_ind = ''Y''' ||
                                                                           ' and mhd.tsl_item_lvl = ''3''' ||
                                                                           -- CR236, 10-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                                           ' and mhd.tsl_country_id in (''B'',:I_country_id5) '||
                                                                           -- CR236, 10-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                                                           ' and mhd.dept = :L_dept' ||
                                                                           ' and mhd.class = :L_class' ||
                                                                           ' and mhd.subclass = :L_subclass' ||
                                                                           L_sql_column || ');';
               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
              end if;
              -- 14-Apr-11     Nandini M     PrfNBS022237     end
               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
              -- Populate the L_sql_select variable for the select of the Level 2 Base Item information
              L_sql_select := ' select '|| L_sql_select ||
                                ' from item_attributes' ||
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, Begin
                               ' where item = :I_base_item3 '||
                              -- Modified by Govindarajan K on 06-Sep-2007 for the defecct no NBS003083, End
                                   -- CR236, 02-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                               '   and tsl_country_id = :I_country_id6;';
                                   -- CR236, 02-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
              -- 28-Sep-2010  Praveen      PrfNBS018117d     End
              if L_sql_select is NOT NULL then       -- L12 begin
                  SQL_LIB.SET_MARK('OPEN',
                                   'C_LOCK_ITEM_ATTRIBUTES_LV3',
                                   'ITEM_ATTRIBUTES',
                                   'ITEM: ' ||I_base_item);
                  open C_LOCK_ITEM_ATTRIBUTES_LV3;

                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_LOCK_ITEM_ATTRIBUTES_LV3',
                                   'ITEM_ATTRIBUTES',
                                   'ITEM: ' ||I_base_item);
                  close C_LOCK_ITEM_ATTRIBUTES_LV3;
                  -- Populate the L_statement variable to be used on the Execute Immediate statement
                  L_statement := 'Declare' ||
                                 ' Cursor C_get_item_attrib is' ||
                                        L_sql_select ||
                                 ' row_data C_get_item_attrib%ROWTYPE;' ||
                                 ' Begin' ||
                                      ' open C_get_item_attrib;'||
                                      ' fetch C_get_item_attrib into row_data;';
                  -- Execute the Dynamic SQL, using the instruction EXECUTE IMMEDIATE
                  -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
                  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
                  --DefNBS021727,25-Feb-2011,Sripriya,Sripriya.karanam@in.tesco.com,Begin
                  --replacing back I_country_id to L_Login_ctry for 3rd parameter
                   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                  if L_sql_update is NOT NULL or L_sql_insert is NOT NULL then
                     EXECUTE IMMEDIATE L_statement||L_sql_update||L_close_cursor||L_sql_insert||L_end using I_base_item,I_country_id,I_country_id,I_base_item,L_owner_country,L_security_ind,I_country_id,I_base_item,I_country_id,I_country_id,I_country_id,L_dept,L_class,L_subclass;
                  end if;
                  -- 14-Apr-11     Nandini M     PrfNBS022237     end
                   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                  --DefNBS021727,25-Feb-2011,Sripriya,Sripriya.karanam@in.tesco.com,End
                  -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                  -- 28-Sep-2010  Praveen      PrfNBS018117d     End
              end if;    -- L12 end
              -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - Begin
              -- The below code is removed, as the cascading will happen as per the existing logic.
              -- Cascade brand indicator and brand name to only those variants which do not have barcodes.
              -- CR242, 04-Aug-2009, shweta.mandawat@in.tesco.com - Begin
              -- CR242, 04-Aug-2009, shweta.mandawat@in.tesco.com - End*/
              -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - End
              -- Cascade down from Level1 pack to L2 packs
              -- CR258 22-Apr-2010 Chandru Begin
              -- Cascade down from Level1 pack to L2 packs
              FOR C_rec in C_VAR_PACKS LOOP
                 if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                                     L_item_rec,
                                                     C_rec.item) = FALSE then
                    return FALSE;
                 end if;
                 if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_PACK_ATTRIB (O_error_message,
                                                                       L_item_rec,
                                                                       'N',
                                                                       I_country_id,
                                                                       -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                                                       L_login_ctry,
                                                                       -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                                                                         I_column_name,
                                                                       -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                                                                       -- 14-Apr-11     Nandini M     PrfNBS022237     End
																	   																	 -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
																	   																	 I_exclude_in_cascade
																	   																	 -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                                                       ) = FALSE then
                    return FALSE;
                 end if;
              END LOOP;
              ---
              -- CR258 22-Apr-2010 Chandru End
              return TRUE;
          else                   -- L2 else
              return FALSE;
          end if;                -- L2 end
      end if;                    -- L1 end
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_program,
                                             'ITEM: ' ||I_base_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
  return FALSE;
END TSL_COPY_BASE_ATTRIB;
---------------------------------------------------------------------------------------------
-- 28-Jun-2007 Govindarajan - MOD 365b1 end
-----------------------------------------------------------------------------------------
-- 27-Sep-2007 Govindarajan - MOD N20a Begin
-----------------------------------------------------------------------------------------
-- Function Name : TSL_COPY_DOWN_PARENT_EPW
-- Purpose       : Updates/insert a values for the Emergency Product Withdrawal for
--                 all Approved Child and/or Grandchildren of the passed Item
---------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_DOWN_PARENT_EPW (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_item           IN     ITEM_MASTER.ITEM%TYPE,
                                   I_epw_ind        IN     ITEM_ATTRIBUTES.TSL_EPW_IND%TYPE)
   RETURN BOOLEAN is

    E_record_locked EXCEPTION;
    PRAGMA          EXCEPTION_INIT(E_record_locked, -54);
    L_program       VARCHAR2(300)   := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_DOWN_PARENT_EPW';

    -- This cursor will lock the item information on the table ITEM_ATTRIBUTES
    cursor C_LOCK_ITEM_ATTRIBUTES is
       select 'x'
         from item_attributes ia
        where exists (select 'x'
                        from item_master im
                       where ia.item              = im.item
                         and (im.item_parent      = I_item
                          or  im.item_grandparent = I_item)
                         and im.status            = 'A')
          for update nowait;

BEGIN
  if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_item,
                                             L_program,
                                             NULL);
      return FALSE;
  end if;

  -- Locking the records
  SQL_LIB.SET_MARK('OPEN',
                   'C_LOCK_ITEM_ATTRIBUTES',
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item);
  open C_LOCK_ITEM_ATTRIBUTES;

  SQL_LIB.SET_MARK('CLOSE',
                   'C_LOCK_ITEM_ATTRIBUTES',
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item);
  close C_LOCK_ITEM_ATTRIBUTES;

  -- Updating the epw for the child and grand child for the inputted item
  SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item);
  update item_attributes ia
     set tsl_epw_ind = I_epw_ind
   where exists (select 'x'
                   from item_master im
                  where ia.item              = im.item
                    and (im.item_parent      = I_item
                     or  im.item_grandparent = I_item)
                    and im.status            = 'A');

  -- This query will insert the record to the item_attributes table
  -- for the approved child and grand child for the inpuuted item
  SQL_LIB.SET_MARK('INSERT',
                    NULL,
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item);
  insert into item_attributes (item,
                               tsl_epw_ind)
                       select im.item,
                              I_epw_ind
                         from item_master im
                        where (im.item_parent      = I_item
                           or im.item_grandparent = I_item)
                          and im.status            = 'A'
                          and NOT exists (select 'x'
                                            from item_attributes ia
                                           where ia.item = im.item);
   ---
   return TRUE;
EXCEPTION
  when E_record_locked then
    O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                          'ITEM_MASTER, ITEM_ATTRIBUTES',
                                           L_program,
                                          'ITEM: ' ||I_item);
    return FALSE;
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
    return FALSE;
END TSL_COPY_DOWN_PARENT_EPW;
---------------------------------------------------------------------------------------------
-- Function Name : TSL_COPY_BASE_EPW
-- Purpose       : Updates/insert a values for the Emergency Product Withdrawal
--                 for all Approved Variant associated to a given Base Item
---------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_BASE_EPW (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_base_item      IN     ITEM_MASTER.ITEM%TYPE,
                            I_epw_ind        IN     ITEM_ATTRIBUTES.TSL_EPW_IND%TYPE)
   RETURN BOOLEAN is

    E_record_locked  EXCEPTION;
    PRAGMA           EXCEPTION_INIT(E_record_locked, -54);
    L_program        VARCHAR2(300)   := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_BASE_EPW';

    -- This cursor will lock the variant information on the table ITEM_ATTRIBUTES
    cursor C_LOCK_ITEM_ATTRIBUTES is
    select 'x'
      from item_attributes ia
     where ia.item in (select im2.item
                         from item_master im1,
                              item_master im2
                        where im1.tsl_base_item    = I_base_item
                          and im1.tsl_base_item   != im1.item
                          and im1.item_level       = im1.tran_level
                          and im1.item_level       = 2
                          and im2.status           = 'A'
                          and (im2.item_parent     = im1.item
                           or im1.item             = im2.item))
       for update nowait;
BEGIN
  if I_base_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_base_item,
                                             L_program,
                                             NULL);
      return FALSE;
  end if;

  -- Locking the records
  SQL_LIB.SET_MARK('OPEN',
                   'C_LOCK_ITEM_ATTRIBUTES',
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_base_item);
  open C_LOCK_ITEM_ATTRIBUTES;

  SQL_LIB.SET_MARK('CLOSE',
                   'C_LOCK_ITEM_ATTRIBUTES',
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_base_item);
  close C_LOCK_ITEM_ATTRIBUTES;

  -- This query will return the Approved Variant Item for the
  -- passed Base Item that exists on the ITEM_ATTRIBUTES table
  SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_base_item);
  update item_attributes ia
     set tsl_epw_ind = I_epw_ind
   where ia.item in (select im2.item
                       from item_master im1,
                            item_master im2
                      where im1.tsl_base_item    = I_base_item
                        and im1.tsl_base_item   != im1.item
                        and im1.item_level       = im1.tran_level
                        and im1.item_level       = 2
                        and im2.status           = 'A'
                        and (im2.item_parent     = im1.item
                         or im1.item             = im2.item));

  -- This query will return the Approved Variant Items for the
  -- passed Base Item, that doesn?t exist on the ITEM_ATTRIBUTES table
  SQL_LIB.SET_MARK('INSERT',
                    NULL,
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_base_item);
  insert into item_attributes (item,
                               tsl_epw_ind)
                       select im2.item,
                              I_epw_ind
                         from item_master im1,
                              item_master im2
                        where im1.tsl_base_item    = I_base_item
                          and im1.tsl_base_item   != im1.item
                          and im1.item_level       = im1.tran_level
                          and im1.item_level       = 2
                          and im2.status           = 'A'
                          and (im2.item_parent     = im1.item
                           or im1.item             = im2.item)
                          and NOT exists (select 'x'
                                            from item_attributes ia
                                           where ia.item = im2.item) ;
  return TRUE;
EXCEPTION
  when E_record_locked then
    O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                          'ITEM_MASTER, ITEM_ATTRIBUTES',
                                           L_program,
                                          'ITEM: ' ||I_base_item);
    return FALSE;
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
    return FALSE;
END TSL_COPY_BASE_EPW;
---------------------------------------------------------------------------------------------
-- 27-Sep-2007 Govindarajan - MOD N20a end
---------------------------------------------------------------------------------------------
-- 03-Oct-2007 Govindarajan - MOD N20a Begin
-----------------------------------------------------------------------------------------
-- Function Name : TSL_COPY_ITEM_ATTRIB
-- Purpose       : Updates/creates the Item attributes for Items, from the Item Attributes
--                 defined for the selected Item parent. New records will be inserted with
--                 the same information of the Parent, if there is no other required
--                 information necessary to be entered.
---------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_ITEM_ATTRIB (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item_rec       IN     ITEM_MASTER%ROWTYPE,
                               I_base_ind       IN     VARCHAR2,
                               -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                               I_country_id     IN     VARCHAR2,
                               -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                               -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                               I_login_ctry     IN     VARCHAR2,
                               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                               I_column_name    IN     VARCHAR2,
                               -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                               -- 14-Apr-11     Nandini M     PrfNBS022237     End
                               -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                               I_exclude_in_cascade IN  VARCHAR2 DEFAULT  'N'
                               -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                               )
  RETURN BOOLEAN is

  E_record_locked  EXCEPTION;
  PRAGMA           EXCEPTION_INIT(E_record_locked, -54);
  L_program        VARCHAR2(300)   := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_ATTRIB';
  L_close_cursor   VARCHAR2(2000)  := ' close C_GET_ITEM_ATTRIB;';
  L_end            VARCHAR2(10)    := ' end;';
  L_sql_select     VARCHAR2(32767) := NULL;
  L_sql_insert     VARCHAR2(32767) := NULL;
  L_sql_update     VARCHAR2(32767) := NULL;
  L_sql_column     VARCHAR2(32767) := NULL;
  L_statement      VARCHAR2(32767) := NULL;
  L_clause         VARCHAR2(32767) := NULL;
  L_lvl2_ind       VARCHAR2(1)     := 'N';
  L_lvl3_ind       VARCHAR2(1)     := 'N';
  L_exists         BOOLEAN         := FALSE;
  L_item_level     NUMBER(1);
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
  L_system_options_row    SYSTEM_OPTIONS%ROWTYPE;
  L_owner_country         ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_security_ind          SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
  L_login_ctry            ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_uk_ind                VARCHAR2(1) :=  'N';
  L_roi_ind               VARCHAR2(1) :=  'N';
   --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End

  -- This cursor will lock the Level2 items on the table ITEM_ATTRIBUTES table
  cursor C_LOCK_ITEM_LV2 is
  select 'x'
    from item_attributes ia
   where ia.item in (select im.item
                       from item_master im
                      where im.item_parent = I_item_rec.item
                        and im.item_level  = I_item_rec.item_level + 1)
     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     and ia.tsl_country_id = I_country_id
     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     for update nowait;
  -- This cursor will retrieve the codes, and the corresponding column for the
  -- attributes that can be copied between a Level 1 Item to a Level 2 Item
  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
  cursor C_GET_COLUMNS is
  select tmc.tsl_column_name column_name,
         tmc.tsl_code code,
         mhd.required_ind req_ind
    from tsl_map_item_attrib_code tmc,
         merch_hier_default mhd
   where tmc.tsl_column_name =  NVL(upper(I_column_name),tmc.tsl_column_name)
     and tmc.tsl_code        = mhd.info
     -- NBS00026492/PM020648(work around fix) 08-Nov-2013 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
     -- MrgNBS26492   -- As part of Permanent fix the workaround has removed.
     and mhd.info           != 'TEPW'
     -- NBS00026492/PM020648(work around fix) 08-Nov-2013 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
     and mhd.tsl_pack_ind    = I_item_rec.pack_ind
     and mhd.available_ind   = 'Y'
     and mhd.tsl_item_lvl    = I_item_rec.item_level + 1
     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     and mhd.tsl_country_id in (I_country_id,'B')
     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     and mhd.dept            = I_item_rec.dept
     and mhd.class           = I_item_rec.class
     and mhd.subclass        = I_item_rec.subclass
     and DECODE(L_lvl2_ind,'Y',DECODE(I_base_ind,'Y',mhd.tsl_base_ind,mhd.tsl_var_ind),'Y') = 'Y'
     and (exists (select 1
                    from merch_hier_default a
                   where a.info = mhd.info
                     and a.available_ind = 'Y'
                     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                     and a.tsl_country_id in (I_country_id,'B')
                     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                     and a.dept          = mhd.dept
                     and a.class         = mhd.class
                     and a.subclass      = mhd.subclass
                     and a.tsl_item_lvl  = I_item_rec.item_level
                     and a.tsl_pack_ind  = I_item_rec.pack_ind
                     and DECODE(L_lvl3_ind,'Y',DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
              or
       not exists (select 1
                     from merch_hier_default a
                    where a.info = mhd.info
                      and a.dept          = mhd.dept
                      and a.class         = mhd.class
                      and a.subclass      = mhd.subclass
                      -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                      and a.tsl_country_id in (I_country_id,'B')
                      -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                      and a.tsl_item_lvl  = I_item_rec.item_level
                      and a.tsl_pack_ind  = I_item_rec.pack_ind
                      and DECODE(L_lvl3_ind,'Y',DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y'))
   -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
    and (
         (I_exclude_in_cascade='Y'
          and not exists(select 1
                           from tsl_attr_stpcas sca
                          where sca.tsl_itm_attr_id=tmc.tsl_code
                        )
          )
         or I_exclude_in_cascade='N'
         )
   -- 23-Oct-2013  Gopinath Meganathan PM020648 End
    union
    select tmc.tsl_column_name column_name,
           tmc.tsl_code code,
           'N' req_ind
      from tsl_map_item_attrib_code tmc
     where not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.dept = I_item_rec.dept
                          and a.class = I_item_rec.class
                          and a.subclass = I_item_rec.subclass
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                          and a.tsl_country_id in (I_country_id,'B')
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                          and a.tsl_pack_ind  = I_item_rec.pack_ind
                          and a.tsl_item_lvl = I_item_rec.item_level + 1
                          and DECODE(L_lvl2_ind,'Y',DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
       and not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.available_ind = 'N'
                          and a.dept = I_item_rec.dept
                          and a.class = I_item_rec.class
                          and a.subclass = I_item_rec.subclass
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                          and a.tsl_country_id in (I_country_id,'B')
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                          and a.tsl_pack_ind  = I_item_rec.pack_ind
                          and a.tsl_item_lvl = I_item_rec.item_level
                          and DECODE(L_lvl3_ind,'Y',DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
       and tmc.tsl_column_name =  NVL(upper(I_column_name),tmc.tsl_column_name)
       -- NBS00026492/PM020648(work around fix) 08-Nov-2013 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
       -- MrgNBS26492  -- V Manikandan -- 21-MAR-14 -- Removed the workaround
       and tmc.tsl_code != 'TEPW'
        -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
       and (
         (I_exclude_in_cascade='Y'
          and not exists(select 1
                           from tsl_attr_stpcas sca
                          where sca.tsl_itm_attr_id=tmc.tsl_code
                        )
          )
         or I_exclude_in_cascade='N'
         );
   -- 23-Oct-2013  Gopinath Meganathan PM020648 End

       -- NBS00026492/PM020648(work around fix) 08-Nov-2013 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
   -- 14-Apr-11     Nandini M     PrfNBS022237     End
    -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
   -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - Begin
   -- The following cursors are not needed anymore because the brand indicator will cascade
   -- this is due the change in BSD of CR242.
   -- CR242, 03-Aug-2009, shweta.mandawat@in.tesco.com - Begin
   -- Cursor to select L2 which do not have barcodes set.
   -- CR242, 19-Aug-2009, shweta.mandawat@in.tesco.com - End
   -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - End

BEGIN
  -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
   L_login_ctry := I_login_ctry;
   -- 14-Apr-11    Nandini M     PrfNBS022237     End

   if I_item_rec.item is NULL then      -- L1 begin
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_item_rec.item,
                                             L_program,
                                             NULL);
      return FALSE;
  end if;                             -- L1 end

  if I_item_rec.tran_level = 2 and
     I_item_rec.item_level < I_item_rec.tran_level and
     I_item_rec.pack_ind = 'N' then         -- L2 begin
        L_lvl2_ind := 'Y';
        L_item_level := 2;
  elsif I_item_rec.tran_level = 2 and
        I_item_rec.item_level = I_item_rec.tran_level and
        I_item_rec.pack_ind = 'N' then      -- L2 elseif
          L_lvl3_ind := 'Y';
          L_item_level := 3;
  elsif I_item_rec.pack_ind = 'Y' then -- L2 elseif
          L_item_level := 2;
  end if;      -- L2 end

  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
  if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                           L_system_options_row) = FALSE then
     return FALSE;
  end if;
  ---
  L_security_ind := L_system_options_row.tsl_loc_sec_ind;
  ---
  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
  -- MrgNBS022368(fix), 19-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com Begin
  if L_security_ind = 'Y' and NVL(I_login_ctry,'N') = 'N' then
  -- MrgNBS022368(fix), 19-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com End
  -- 14-Apr-11     Nandini M     PrfNBS022237     End
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
  end if;
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End

  -- This cursor will retrieve the codes, and the corresponding column for the attributes
  -- that can be copied between the L1 item to L2 Items
  --Opening the cursor C_GET_COLUMNS
  SQL_LIB.SET_MARK('OPEN',
                   'C_GET_COLUMNS',
                   'TSL_MAP_ITEM_ATTRIB_CODE',
                   'ITEM: ' ||I_item_rec.item);
  FOR C_rec in C_GET_COLUMNS
  LOOP                                -- L3 begin
     -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - Begin
     -- CR242, 03-Aug-2009, shweta.mandawat@in.tesco.com - Begin
     -- This if condition is no longer needed.
     -- Cascade of brand ind will not happen here. New logic written below.
     -- CR242, 03-Aug-2009, shweta.mandawat@in.tesco.com - End
     -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - End
     -- checking L_sql_select is null or not
      L_exists := TRUE;
      if L_sql_select is NULL then      -- L4 begin
        	L_sql_insert := 'ia.'||C_rec.column_name;
          L_sql_select := C_rec.column_name;
          --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
          if (((I_item_rec.tsl_owner_country = L_login_ctry) or
              L_security_ind = 'N') or
              (I_item_rec.tsl_owner_country <> L_login_ctry and
               L_security_ind = 'Y'
               -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
               -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
               )) then
                  -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                  -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com Begin
                  -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com Begin
                  -- DefNBS020805, Venkatesh S, Venkatesh.suvarna@in.tesco.com 3-Feb-2011 Begin
                  -- DefNBS020805, Venkatesh S, Venkatesh.suvarna@in.tesco.com 3-Feb-2011 End
                  -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com End
                  -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End
                  -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 Begin
                  if c_rec.code <> 'TLDT' then
                     L_sql_update := C_rec.column_name||' = decode(''' ||C_rec.req_ind || ''',
                                     '' Y'',' || ' nvl(row_data.' || C_rec.column_name || ','
                                     ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
                  elsif c_rec.code = 'TLDT' then
                        L_sql_update := C_rec.column_name||' = row_data.' || C_rec.column_name ;
                  end if;
                  -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 End
             -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com Begin
             -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com Begin
             -- end if;
             -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com End
             -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End
          end if;
          --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
          -- NBS00026492/PM020648(work around fix) 08-Nov-2013 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
          -- MrgNBS26492 -- V Manikandan - Removed the workaround fix.
          L_sql_column := ' and t.tsl_code NOT in (''TEPW''';
          --L_sql_column := ' and t.tsl_code NOT in (''TEPW'',''TTC''';
          -- NBS00026492/PM020648(work around fix) 08-Nov-2013 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
      else                        -- L4 else
        	L_sql_insert := L_sql_insert ||',ia.'|| C_rec.column_name;
          L_sql_select := L_sql_select || ', ' || C_rec.column_name;
          --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
          if (((I_item_rec.tsl_owner_country = L_login_ctry) or
              L_security_ind = 'N') or
              (I_item_rec.tsl_owner_country <> L_login_ctry and
               L_security_ind = 'Y'
               -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
               -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
               )) then
                  -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                  -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com Begin
                  -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com Begin
                  -- DefNBS020805, Venkatesh S, Venkatesh.suvarna@in.tesco.com 3-Feb-2011 Begin
                  -- DefNBS020805, Venkatesh S, Venkatesh.suvarna@in.tesco.com 3-Feb-2011 End
                  -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com End
                  -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End
                  -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 Begin
                  if c_rec.code <> 'TLDT' then
                     L_sql_update := L_sql_update || ', ' || C_rec.column_name || ' =
                                     decode(''' || C_rec.req_ind || ''',''Y'',' || ' nvl(row_data.'
                                     || C_rec.column_name || ','  ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
                  elsif c_rec.code = 'TLDT' then
                     L_sql_update := L_sql_update || ', ' || C_rec.column_name || ' = row_data.'
                                     || C_rec.column_name ;
                  end if;
                  -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 End
             -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com Begin
                 -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com Begin
             -- end if;
                 -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com End
             -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End
          end if;
          --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
      end if;                     -- L4 end
      -- checking req_ind is 'Y' or 'N'
      if C_rec.req_ind = 'N' then        -- L5 begin
          L_sql_column := L_sql_column || ', '''|| C_rec.code || '''';
      else            -- L5 else
          L_sql_column := L_sql_column || ', decode(ia.' || C_rec.column_name ||
                          ', null, ''x'', ''' || C_rec.code || ''')';
      end if;          -- L5 end
  END LOOP;          -- L3 end
  ---
  if L_sql_column is NOT NULL then          -- L6 begin
      L_sql_column := L_sql_column||')';
  end if;     -- L6 end
  ---
  if L_exists = TRUE then    -- L7 begin
      if I_item_rec.item_level < I_item_rec.tran_level then     -- L8 bein
          L_clause:= ' and im.item_level = im.tran_level';
          ---
          if I_base_ind = 'Y' then   -- L9 begin
              L_clause := L_clause || ' and im.item = im.tsl_base_item';
          elsif I_base_ind = 'N' then   -- L9 elseif
              L_clause := L_clause || ' and im.item != im.tsl_base_item';
          end if;   -- L9 end
          ---
      elsif I_item_rec.item_level = I_item_rec.tran_level then     -- L8 elseif
          L_clause := ' and im.item_level > im.tran_level';
      end if;   -- L8 end
  end if;   -- L7 end
  ---
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
  --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   Begin
  if L_security_ind = 'Y' then
     ---
     L_owner_country := I_item_rec.tsl_owner_country;
     ---
  --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   End
  elsif L_security_ind = 'N' then
     L_owner_country := 'U';
  end if;
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
  -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
  if L_sql_update is NOT NULL then
  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
  -- Populate the L_sql_update variable for the update of the Item children of the selected Item
  L_sql_update := ' update item_attributes' ||
                     ' set ' || L_sql_update ||
                   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                   ' where tsl_country_id = :I_country_id'||
                   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                     ' and item in (select im.item' ||
                                    ' from item_master im' ||
                                   ' where im.item_parent = :itm1 '||
                                     ' and im.item_level = '||L_item_level||' '||
                                    -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com Begin
                                    -- DefNBS020805, Venkatesh S, Venkatesh.suvarna@in.tesco.com 3-Feb-2011 Begin
                                    -- ' and not (im.pack_ind=''Y'' and im.item_level=2 and tran_level=1 ' ||
                                    -- ' and item_number_type=''OCC'')' ||
                                    -- DefNBS020805, Venkatesh S, Venkatesh.suvarna@in.tesco.com 3-Feb-2011 End
                                    -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com End
                                     --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
                                     ' and ((im.tsl_owner_country = :L_owner_country) or (:L_security_ind = ''N''))'||L_clause || ');';
                                     --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End

  -- Populate the L_sql_insert variable for the insert of the Item Children of the selected Item
-- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
end if;
  -- 14-Apr-11     Nandini M     PrfNBS022237     End
-- 14-Apr-11     Nandini M     PrfNBS022237     Begin
  if L_sql_insert is NOT NULL then
-- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
-- CR236, 06-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
  L_sql_insert := 'insert into item_attributes (item, tsl_country_id, '|| L_sql_select ||' )' ||
                                      ' select im.item, :I_country_id2,'|| L_sql_insert ||
  -- CR236, 06-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                        ' from item_master im, item_attributes ia'||
                                       ' where ia.item = :itm2 '||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                         ' and ia.tsl_country_id = :I_country_id3'||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                         ' and ia.item = im.item_parent'||
                                         ' and im.item_level = '||L_item_level||' '||
                                         L_clause||
                                         ' and not exists (select 1'||
                                                           ' from item_attributes b '||
                                                           ' where b.item = im.item '||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                           '   and b.tsl_country_id = :I_country_id4)' ||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                         ' and not exists (select 1 '||
                                                           ' from merch_hier_default m, '||
                                                                ' tsl_map_item_attrib_code t'||
                                                          ' where m.info = t.tsl_code'||
                                                            ' and m.required_ind = ''Y'''||
                                                            -- CR236, 10-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                            ' and m.tsl_country_id in (''B'',:I_country_id5) '||
                                                            -- CR236, 10-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                                            ' and m.dept = :dpt '||
                                                            ' and m.class = :cls '||
                                                            ' and m.subclass = :scs '||
                                                            ' and m.tsl_pack_ind = :pack_ind'||
                                                            ' and m.tsl_item_lvl = '||L_item_level;
  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
 -- 21-Apr-11     Nandini M     PrfNBS022237f     Begin
     if I_item_rec.tran_level = 2 and
        I_item_rec.item_level = I_item_rec.tran_level and L_sql_insert is NOT NULL then   -- L10 begin
         if I_base_ind = 'Y' then  -- L11 begin
             L_sql_insert := L_sql_insert ||  ' and m.tsl_base_ind = ''Y''';
         elsif I_base_ind = 'N' then  -- L11 else
             L_sql_insert := L_sql_insert ||  ' and m.tsl_var_ind = ''Y''';
         end if;  -- L11 end
     end if; -- l10 end
     -- 14-Apr-11     Nandini M     PrfNBS022237     End
      -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end

     -- Add to L_sql_insert variable the L_sql_column variable
     L_sql_insert := L_sql_insert || L_sql_column|| ');';
  end if;
  -- 21-Apr-11     Nandini M     PrfNBS022237f     End
   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
  ---
  -- Populate the L_sql_select variable for the select of the Item Parent information
  L_sql_select := ' select '|| L_sql_select ||
                       ' from item_attributes' ||
                      ' where item = :itm3 '||
                      -- CR236, 02-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                      '   and tsl_country_id = :I_country_id6;';
                      -- CR236, 02-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
  -- 28-Sep-2010  Praveen      PrfNBS018117d     End
  -- Populate the L_statement variable to be used on the Execute Immediate statement
  L_statement := 'Declare' ||
                   ' Cursor C_GET_ITEM_ATTRIB is' ||
                        L_sql_select ||
                   ' row_data C_GET_ITEM_ATTRIB%ROWTYPE;' ||
                   ' Begin' ||
                      ' open C_GET_ITEM_ATTRIB;'||
                      ' fetch C_GET_ITEM_ATTRIB into row_data;';
  ---
  if I_item_rec.tran_level = 2 and
     I_item_rec.item_level < I_item_rec.tran_level then   -- L12 begin
      if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_ATTRIB_L3 (O_error_message,
                                                          I_item_rec,
                                                          I_base_ind,
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                          I_country_id,
                                                          -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                                          L_login_ctry,
                                                          -- 14-Apr-11     Nandini M     PrfNBS022237     End
                                                          -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                                                          I_exclude_in_cascade
                                                          -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                                          ) = FALSE then
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
          return FALSE;
      end if;
      ---
  end if;  -- L12 end
  ---
  -- Locking the L2 items
  SQL_LIB.SET_MARK('OPEN',
                   'C_LOCK_ITEM_LV2',
                   'ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item_rec.item);
  open C_LOCK_ITEM_LV2;

  SQL_LIB.SET_MARK('CLOSE',
                   'C_LOCK_ITEM_LV2',
                   'ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item_rec.item);
  close C_LOCK_ITEM_LV2;
  -- Execute the Dynamic SQL, using the instruction EXECUTE IMMEDIATE
  -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
   -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin Replace the I_country_id with L_Login_ctry to 3rd passing parameter
  -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com Begin
  --DefNBS021727,25-Feb-2011,Sripriya,Sripriya.karanam@in.tesco.com,Begin
  --replacing back I_country_id to L_Login_ctry for 3rd parameter
   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
  if (L_sql_update is NOT NULL or L_sql_insert is NOT NULL) then
     EXECUTE IMMEDIATE L_statement||L_sql_update||L_close_cursor||L_sql_insert||L_end using I_item_rec.item,I_country_id,I_country_id,I_item_rec.item,L_owner_country,L_security_ind,I_country_id,I_item_rec.item,I_country_id,I_country_id,I_country_id,I_item_rec.dept,I_item_rec.class,I_item_rec.subclass,I_item_rec.pack_ind;
  end if;
  -- 14-Apr-11     Nandini M     PrfNBS022237     End
   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end

  -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com End
  -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
  -- 28-Sep-2010  Praveen      PrfNBS018117d     End
  ---
  -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - Begin
  -- CR242, 03-Aug-2009, shweta.mandawat@in.tesco.com - Begin
  -- Cascade Brand ind to only those L2 which do not have barcodes.
  -- CR242, 19-Aug-2009, shweta.mandawat@in.tesco.com - End*/
  -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - End

  -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com Begin
    update item_attributes
       set tsl_tarif_code = null,
           tsl_supp_unit  = null
     where item in (select im.item
                      from item_master im
                     where ((im.item_parent = I_item_rec.item or im.item_grandparent= I_item_rec.item)
                      and im.item_level = 3
                      and im.tran_level = 2
                      and im.pack_ind='N')
                      or (im.item_parent = I_item_rec.item
                      and im.item_level = 2
                      and tran_level = 1
                      and item_number_type='OCC'));
  -- DefNBS020838, 4-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com End

  return TRUE;
EXCEPTION
  when E_record_locked then
    O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                          'ITEM_MASTER, ITEM_ATTRIBUTES',
                                           L_program,
                                          'ITEM: ' ||I_item_rec.item);
    return FALSE;
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
    return FALSE;
END TSL_COPY_ITEM_ATTRIB;
--------------------------------------------------------------------------------------------
-- Function Name : TSL_COPY_ITEM_ATTRIB_L3
-- Purpose       : Updates/creates the Item attributes for Items, from the Item Attributes
--                 defined for the selected Item Grandparent. New records will be inserted
--                 with the same information of the Grandparent, if there is no other
--                 required information necessary to be entered.
---------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_ITEM_ATTRIB_L3 (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_item_rec       IN     ITEM_MASTER%ROWTYPE,
                                  I_base_ind       IN     VARCHAR2,
                                  -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                  I_country_id     IN     VARCHAR2,-- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                  I_login_ctry     IN     VARCHAR2,
                                  -- 14-Apr-11     Nandini M     PrfNBS022237     End
                                  -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                                  I_exclude_in_cascade IN  VARCHAR2 DEFAULT  'N'
                                  -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                  )
  RETURN BOOLEAN is

  E_record_locked  EXCEPTION;
  PRAGMA           EXCEPTION_INIT(E_record_locked, -54);
  L_program        VARCHAR2(300)   := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_ATTRIB_L3';
  L_close_cursor   VARCHAR2(2000)  := ' close C_GET_ITEM_ATTRIB;';
  L_end            VARCHAR2(10)    := ' end;';
  L_sql_select     VARCHAR2(32767) := NULL;
  L_sql_insert     VARCHAR2(32767) := NULL;
  L_sql_update     VARCHAR2(32767) := NULL;
  L_sql_column     VARCHAR2(32767) := NULL;
  L_statement      VARCHAR2(32767) := NULL;
  L_clause         VARCHAR2(32767) := NULL;
  L_exists         BOOLEAN         := FALSE;
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
  L_system_options_row    SYSTEM_OPTIONS%ROWTYPE;
  L_owner_country         ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_security_ind          SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
  L_login_ctry            ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_uk_ind                VARCHAR2(1) :=  'N';
  L_roi_ind               VARCHAR2(1) :=  'N';
   --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End

  -- This cursor will lock the Level2 items on the table ITEM_ATTRIBUTES table
  cursor C_LOCK_ITEM_LV3 is
  select 'x'
    from item_attributes ia
   where ia.item in (select im1.item
                       from item_master im1,
                            item_master im2
                      where im1.item_grandparent = I_item_rec.item
                        and im1.item_parent      = im2.item
                        and im2.item_level       = 2
                        and im2.item_level       = im2.tran_level)
     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     and ia.tsl_country_id  = I_country_id
     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     for update nowait;

  -- This cursor will retrieve the codes, and the corresponding column for the attributes
  -- that can be copied between a Level 1 Item to a Level 3 Item
  cursor C_GET_COLUMNS is
  select tmc.tsl_column_name column_name,
         tmc.tsl_code code,
         mhd.required_ind req_ind
    from tsl_map_item_attrib_code tmc,
         merch_hier_default mhd
   where tmc.tsl_code        = mhd.info
     -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com Begin
     --and mhd.info           != 'TEPW'
     and mhd.info           NOT IN ('TEPW','TTC','TSU')
     -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End
     and mhd.available_ind   = 'Y'
     and mhd.tsl_item_lvl    = 3
     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     and mhd.tsl_country_id in (I_country_id,'B')
     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     and mhd.dept            = I_item_rec.dept
     and mhd.class           = I_item_rec.class
     and mhd.subclass        = I_item_rec.subclass
     and (exists (select 1
                    from merch_hier_default a
                   where a.info = mhd.info
                     and a.available_ind = 'Y'
                     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                     and a.tsl_country_id in (I_country_id,'B')
                     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                     and a.dept          = mhd.dept
                     and a.class         = mhd.class
                     and a.subclass      = mhd.subclass
                     and a.tsl_item_lvl  = 1
                     and a.tsl_pack_ind  = I_item_rec.pack_ind)
              or
       not exists (select 1
                     from merch_hier_default a
                    where a.info = mhd.info
                      and a.dept          = mhd.dept
                      and a.class         = mhd.class
                      and a.subclass      = mhd.subclass
                      -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                      and a.tsl_country_id in (I_country_id,'B')
                      -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                      and a.tsl_item_lvl  = 1
                      and a.tsl_pack_ind  = I_item_rec.pack_ind))
     and (exists (select 1
                    from merch_hier_default a
                   where a.info = mhd.info
                     and a.available_ind = 'Y'
                     and a.dept          = mhd.dept
                     and a.class         = mhd.class
                     and a.subclass      = mhd.subclass
                     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                     and a.tsl_country_id in (I_country_id,'B')
                     -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                     and a.tsl_item_lvl  = 2
                     and a.tsl_pack_ind  = I_item_rec.pack_ind
                     and DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind) = 'Y')
              or
       not exists (select 1
                     from merch_hier_default a
                    where a.info = mhd.info
                      and a.dept          = mhd.dept
                      and a.class         = mhd.class
                      and a.subclass      = mhd.subclass
                      -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                      and a.tsl_country_id in (I_country_id,'B')
                      -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                      and a.tsl_item_lvl  = 2
                      and a.tsl_pack_ind  = I_item_rec.pack_ind
                      and DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind) = 'Y'))
     -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
     and (
         (I_exclude_in_cascade='Y'
          and not exists(select 1
                           from tsl_attr_stpcas sca
                          where sca.tsl_itm_attr_id=tmc.tsl_code
                        )
          )
         or I_exclude_in_cascade='N'
         )
     -- 23-Oct-2013  Gopinath Meganathan PM020648 End
    union
    select tmc.tsl_column_name column_name,
           tmc.tsl_code code,
           'N' req_ind
      from tsl_map_item_attrib_code tmc
     where not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.dept = I_item_rec.dept
                          and a.class = I_item_rec.class
                          and a.subclass = I_item_rec.subclass
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                          and a.tsl_country_id in (I_country_id,'B')
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                          and a.tsl_item_lvl = 3)
       and not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.available_ind = 'N'
                          and a.dept = I_item_rec.dept
                          and a.class = I_item_rec.class
                          and a.subclass = I_item_rec.subclass
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                          and a.tsl_country_id in (I_country_id,'B')
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                          and a.tsl_pack_ind  = I_item_rec.pack_ind
                          and a.tsl_item_lvl = 2
                          -- CR236, 10-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                          and DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind) = 'Y')
                          -- CR236, 01-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
       -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com Begin
       -- and tmc.tsl_code != 'TEPW';
          and tmc.tsl_code NOT IN ('TEPW','TTC','TSU')
       -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End
       -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
       and (
         (I_exclude_in_cascade='Y'
          and not exists(select 1
                           from tsl_attr_stpcas sca
                          where sca.tsl_itm_attr_id=tmc.tsl_code
                        )
          )
         or I_exclude_in_cascade='N'
         );
       -- 23-Oct-2013  Gopinath Meganathan PM020648 End;
       -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End


BEGIN

   -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
   L_login_ctry := I_login_ctry;
   -- 14-Apr-11    Nandini M     PrfNBS022237     End

   if I_item_rec.item is NULL then      -- L1 begin
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_item_rec.item,
                                             L_program,
                                             NULL);
      return FALSE;
  end if; -- L1 end
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
  if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                           L_system_options_row) = FALSE then
     return FALSE;
  end if;
  ---
  L_security_ind := L_system_options_row.tsl_loc_sec_ind;
  ---
  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
  -- MrgNBS022368(fix), 19-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com Begin
  if L_security_ind = 'Y' and NVL(I_login_ctry,'N') = 'N' then
  -- MrgNBS022368(fix), 19-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com End
  -- 14-Apr-11     Nandini M     PrfNBS022237     End
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
  end if;
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
  ---
  -- This cursor will retrieve the codes, and the corresponding column for the attributes
  -- that can be copied between the L1 item to L3 Items
  --Opening the cursor C_GET_COLUMNS
  SQL_LIB.SET_MARK('OPEN',
                   'C_GET_COLUMNS',
                   'TSL_MAP_ITEM_ATTRIB_CODE',
                   'ITEM: ' ||I_item_rec.item);
  FOR C_rec in C_GET_COLUMNS
  LOOP                                -- L2 begin
     -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - Begin
     -- CR242, 04-Aug-2009, shweta.mandawat@in.tesco.com - Begin
     -- The cascade will continue to work as it is. There is no change.
     -- Cascade will not happen for L3 items.
     -- CR242, 04-Aug-2009, shweta.mandawat@in.tesco.com - End
     -- Def014555, 24-Aug-2009, shweta.mandawat@in.tesco.com - End
     -- checking L_sql_select is null or not
      L_exists := TRUE;
      if L_sql_select is NULL then      -- L3 begin
          L_sql_insert := 'ia.'||C_rec.column_name;
          L_sql_select := C_rec.column_name;
          --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
          if (((I_item_rec.tsl_owner_country = L_login_ctry) or
              L_security_ind = 'N') or
              (I_item_rec.tsl_owner_country <> L_login_ctry and
               L_security_ind = 'Y'
               -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
               -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
               /* and
               C_rec.column_name NOT in
               ('TSL_DIAMOND_LINE_IND','TSL_DEV_LINE_IND','TSL_LAUNCH_DATE','TSL_POS_CODES','TSL_DEV_END_DATE')*/)) then
               -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
               -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
	             L_sql_update := C_rec.column_name||' = decode(''' ||C_rec.req_ind || ''',
	                             '' Y'',' || ' nvl(row_data.' || C_rec.column_name || ','
	                             ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
          end if;
          --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
          -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com Begin
          -- L_sql_column := ' and t.tsl_code NOT in (''TEPW''';
          L_sql_column := ' and t.tsl_code NOT in (''TEPW'',''TTC'',''TSU''';
          -- CR254, 28-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End
      else                        -- L3 else
          L_sql_insert := L_sql_insert ||',ia.'|| C_rec.column_name;
          L_sql_select := L_sql_select || ', ' || C_rec.column_name;
          --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
          if (((I_item_rec.tsl_owner_country = L_login_ctry) or
              L_security_ind = 'N') or
              (I_item_rec.tsl_owner_country <> L_login_ctry and
               L_security_ind = 'Y'
               -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
               -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
               /*and
               C_rec.column_name NOT in
               (TSL_DIAMOND_LINE_IND','TSL_DEV_LINE_IND','TSL_LAUNCH_DATE','TSL_POS_CODES','TSL_DEV_END_DATE')*/)) then
                -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                L_sql_update := L_sql_update || ', ' || C_rec.column_name || ' =
                                decode(''' || C_rec.req_ind || ''',''Y'',' || ' nvl(row_data.'
                                || C_rec.column_name || ','  ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
          end if;
          --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
      end if;                     -- L3 end
      -- checking req_ind is 'Y' or 'N'
      if C_rec.req_ind = 'N' then        -- L4 begin
          L_sql_column := L_sql_column || ', '''|| C_rec.code || '''';
      else            -- L4 else
          L_sql_column := L_sql_column || ', decode(ia.' || C_rec.column_name ||
                          ', null, ''x'', ''' || C_rec.code || ''')';
      end if;          -- L4 end
  END LOOP;          -- L2 end
  ---
  if L_sql_column is NOT NULL then          -- L5 begin
      L_sql_column := L_sql_column||')';
  end if;     -- L5 end
  ---
  if L_exists = TRUE then    -- L6 begin
      if I_base_ind = 'Y' then   -- L7 begin
          L_clause := L_clause || ' and im2.item = im2.tsl_base_item';
      elsif I_base_ind = 'N' then   -- L7 elseif
          L_clause := L_clause || ' and im2.item != im2.tsl_base_item';
      end if;   -- L7 end
  end if;  -- L6 end
  ---
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
  --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   Begin
  if L_security_ind = 'Y' then
     ---
     L_owner_country := I_item_rec.tsl_owner_country;
     ---
  --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   End
  elsif L_security_ind = 'N' then
     L_owner_country := 'U';
  end if;
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
  -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
  -- Populate the L_sql_update variable for the update of the Item Grandchildren of the selected Item
  L_sql_update := ' update item_attributes' ||
                     ' set '||L_sql_update||
                   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                   ' where tsl_country_id = :I_country_id'||
                   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                   ' and item in(select im1.item'||
                                   ' from item_master im1,
                                          item_master im2'||
                                  ' where im1.item_grandparent = :itm '||
                                    ' and im1.item_parent = im2.item ' ||
                                    ' and im2.item_level = im2.tran_level'||
                                    ' and im2.item_level = 2'||
                                    --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
                                    ' and ((im1.tsl_owner_country = :L_owner_country) or (:L_security_ind = ''N''))'||L_clause || ');';
                                    --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End

  -- Populate the L_sql_insert variable for the insert of the Item Grandchildren of the selected Item
  -- CR236, 06-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
  L_sql_insert := 'insert into item_attributes (item, tsl_country_id, '|| L_sql_select ||' )' ||
                                      ' select im1.item, :I_country_id2,'|| L_sql_insert ||
  -- CR236, 06-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                        ' from item_master im1, item_master im2, item_attributes ia'||
                                       ' where ia.item = :itm2 '||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                         ' and ia.tsl_country_id = :I_country_id3'||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                         ' and im1.item_grandparent = ia.item '||
                                         L_clause||
                                         ' and im1.item_parent = im2.item' ||
                                         ' and im2.item_level = im2.tran_level'||
                                         ' and im2.item_level = 2 '||
                                         ' and not exists (select 1'||
                                                           ' from item_attributes b'||
                                                          ' where b.item = im1.item ' ||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                           '  and b.tsl_country_id = :I_country_id4)' ||
                                         -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                         ' and not exists (select 1'||
                                                           ' from merch_hier_default m,'||
                                                                ' tsl_map_item_attrib_code t,'||
                                                          -- CR236, 09-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                                ' item_master im '||
                                                          ' where m.info = t.tsl_code'||
                                                            ' and im.item = :itm3 '||
                                                            ' and m.dept = im.dept '||
                                                            ' and m.class = im.class '||
                                                            ' and m.subclass = im.subclass '||
                                                            ' and m.tsl_country_id in (''B'',:I_country_id5) '||
                                                            -- CR236, 09-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                                            ' and m.required_ind = ''Y'''||
                                                            ' and m.tsl_item_lvl = 3'||
                                                            ' and m.tsl_pack_ind = :pack_ind'||
                                                            L_sql_column||');';
  -- Populate the L_sql_select variable for the select of the Level 2 Base Item information
  L_sql_select := ' select '|| L_sql_select ||
                    ' from item_attributes' ||
                   ' where item = :itm4 '||
                   -- CR236, 02-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                   '   and tsl_country_id = :I_country_id6;';
                   -- CR236, 02-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
  -- 28-Sep-2010  Praveen      PrfNBS018117d     End
  -- Populate the L_statement variable to be used on the Execute Immediate statement
  L_statement := 'Declare' ||
                   ' Cursor C_get_item_attrib is' ||
                        L_sql_select ||
                   ' row_data C_get_item_attrib%ROWTYPE;' ||
                   ' Begin' ||
                      ' open C_get_item_attrib;'||
                      ' fetch C_get_item_attrib into row_data;';
  -- Locking the L3 items
  SQL_LIB.SET_MARK('OPEN',
                   'C_LOCK_ITEM_LV3',
                   'ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item_rec.item);
  open C_LOCK_ITEM_LV3;

  SQL_LIB.SET_MARK('CLOSE',
                   'C_LOCK_ITEM_LV3',
                   'ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item_rec.item);
  close C_LOCK_ITEM_LV3;
  -- 28-Sep-2010  Praveen      PrfNBS018117d     Begin
  -- Execute the Dynamic SQL, using the instruction EXECUTE IMMEDIATE
  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
  -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin Replace the I_country_id with L_Login_ctry to 3rd passing parameter
  --DefNBS021727,25-Feb-2011,Sripriya,Sripriya.karanam@in.tesco.com,Begin
  --replacing back I_country_id to L_Login_ctry for 3rd parameter
  EXECUTE IMMEDIATE L_statement||L_sql_update||L_close_cursor||L_sql_insert||L_end using I_item_rec.item,I_country_id,I_country_id,I_item_rec.item,L_owner_country,L_security_ind,I_country_id,I_item_rec.item,I_country_id,I_country_id,I_item_rec.item,I_country_id,I_item_rec.pack_ind;
  --DefNBS021727,25-Feb-2011,Sripriya,Sripriya.karanam@in.tesco.com,End
  -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
  ---
  -- 28-Sep-2010  Praveen      PrfNBS018117d     End
  return TRUE;
EXCEPTION
  when E_record_locked then
    O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                          'ITEM_MASTER, ITEM_ATTRIBUTES',
                                           L_program,
                                          'ITEM: ' ||I_item_rec.item);
    return FALSE;
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
    return FALSE;
END TSL_COPY_ITEM_ATTRIB_L3;
---------------------------------------------------------------------------------------------
-- 03-Oct-2007 Govindarajan - MOD N20a end
---------------------------------------------------------------------------------------------
-- CR236, 24-Aug-2009, Sarayu Gouda, sarayu.gouda@in.tesco.com, Begin
-----------------------------------------------------------------------------------------
-- Function Name : TSL_COPY_DOWN_PARENT_EPW
-- Purpose       : Updates/insert a values for the Emergency Product Withdrawal for
--                 all Approved Child and/or Grandchildren of the passed Item based on the
--                 country indicator.
---------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_DOWN_PARENT_EPW (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_item           IN     ITEM_MASTER.ITEM%TYPE,
                                   I_epw_ind        IN     ITEM_ATTRIBUTES.TSL_EPW_IND%TYPE,
                                   I_country        IN     VARCHAR2,
                                   --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                   I_epw_dt         IN     ITEM_ATTRIBUTES.TSL_END_DATE%TYPE)
                                   --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
   RETURN BOOLEAN is

    E_record_locked EXCEPTION;
    PRAGMA          EXCEPTION_INIT(E_record_locked, -54);
    L_program       VARCHAR2(300)   := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_DOWN_PARENT_EPW';

    -- This cursor will lock the item information on the table ITEM_ATTRIBUTES
    cursor C_LOCK_ITEM_ATTRIBUTES is
       select 'x'
         from item_attributes ia
        where exists (select 'x'
                        from item_master im
                       where ia.item              = im.item
                         and (im.item_parent      = I_item
                          or  im.item_grandparent = I_item)
                         and im.status            = 'A')
          for update nowait;

BEGIN
  if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_item,
                                             L_program,
                                             NULL);
      return FALSE;
  end if;

  -- Locking the records
  SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ITEM_ATTRIBUTES',
                    'ITEM_MASTER, ITEM_ATTRIBUTES',
                    'ITEM: ' ||I_item);
  open C_LOCK_ITEM_ATTRIBUTES;

  SQL_LIB.SET_MARK('CLOSE',
                   'C_LOCK_ITEM_ATTRIBUTES',
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item);
  close C_LOCK_ITEM_ATTRIBUTES;

  if I_country IN ('U','R') then
     -- Updating the epw for the child and grand child for the inputted item and country
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_item);
     --DefNBS017833 08-Jun-2010 Chandru Begin
     -- Code has been commented to fix 17833 defect

     /*-- 20-Oct-2009 Satish B.N / TESCO HSC DefNBS015040 Begin
     -- Resetting tsl_epw_ind to 'N' before updating it for all children
     update item_attributes ia
        set tsl_epw_ind = 'N'
      where tsl_country_id IN ('U','R')
        and exists (select 'x'
                      from item_master im
                     where ia.item              = im.item
                       and (im.item_parent      = I_item
                        or  im.item_grandparent = I_item)
                       and im.status            = 'A');
     -- 20-Oct-2009 Satish B.N / TESCO HSC DefNBS015040 End
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_item);
     update item_attributes ia
        set tsl_epw_ind = 'N'
      where tsl_country_id in ('U','R')
        and item in (select im.item
                       from packitem_breakout a,
                            item_master im
                      where NOT exists (select b.pack_no
                                          from packitem_breakout b,
                                               item_master im2
                                         where im2.item = b.item
                                           and (NVL(im2.item_grandparent, '-999') != I_item)
                                           and (NVL(im2.item_parent, '-999') != I_item)
                                           and (NVL(im2.item, '-999') != I_item)
                                           and b.pack_no = a.pack_no)
                        and (im.item = a.pack_no
                         or im.item_parent = a.pack_no)
                        and im.status = 'A'
                      group by im.item);
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End*/
     --DefNBS017833 08-Jun-2010 Chandru End
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
            tsl_end_date = I_epw_dt
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
      where tsl_country_id = I_country
      and exists (select 'x'
                    from item_master im
                   where ia.item              = im.item
                     and (im.item_parent      = I_item
                      or  im.item_grandparent = I_item)
                     and im.status            = 'A');
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
            tsl_end_date = I_epw_dt
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
      where tsl_country_id = I_country
        and item in (select im.item
                       from packitem_breakout a,
                            item_master im
                      where NOT exists (select b.pack_no
                                          from packitem_breakout b,
                                               item_master im2
                                         where im2.item = b.item
                                           and (NVL(im2.item_grandparent, '-999') != I_item)
                                           and (NVL(im2.item_parent, '-999') != I_item)
                                           and (NVL(im2.item, '-999') != I_item)
                                           and b.pack_no = a.pack_no)
                        and (im.item = a.pack_no
                         or im.item_parent = a.pack_no)
                        and im.status = 'A'
                      group by im.item);
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     -- This query will insert the record to the item_attributes table
     -- for the approved child and grand child for the inputed item and country
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  tsl_end_date)
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                          select im.item,
                                 I_epw_ind,
                                 I_country,
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from item_master im
                           where (im.item_parent      = I_item
                              or im.item_grandparent = I_item)
                             and im.status            = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = I_country);
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  tsl_end_date)
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                          select im.item,
                                 I_epw_ind,
                                 I_country,
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from packitem_breakout a,
                                 item_master im
                           where NOT exists (select b.pack_no
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.item_grandparent, '-999') != I_item)
                                                and (NVL(im2.item_parent, '-999') != I_item)
                                                and (NVL(im2.item, '-999') != I_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = I_country)
                           group by im.item;

     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
  elsif I_country IN ('B','N') then
     -- Updating the epw for the child and grand child for the inputted item and for both UK and ROI
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
            tsl_end_date = I_epw_dt
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
      where tsl_country_id IN ('U','R')
      and exists (select 'x'
                      from item_master im
                     where ia.item              = im.item
                       and (im.item_parent      = I_item
                        or  im.item_grandparent = I_item)
                       and im.status            = 'A');

     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
            tsl_end_date = I_epw_dt
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
      where tsl_country_id in ('U','R')
        and item in (select im.item
                       from packitem_breakout a,
                            item_master im
                      where NOT exists (select b.pack_no
                                          from packitem_breakout b,
                                               item_master im2
                                         where im2.item = b.item
                                           and (NVL(im2.item_grandparent, '-999') != I_item)
                                           and (NVL(im2.item_parent, '-999') != I_item)
                                           and (NVL(im2.item, '-999') != I_item)
                                           and b.pack_no = a.pack_no)
                        and (im.item = a.pack_no
                         or im.item_parent = a.pack_no)
                        and im.status = 'A'
                      group by im.item);
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End

     -- This query will insert the record to the item_attributes table
     -- for the approved child and grand child for the inputed item and for both UK and ROI
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_item);

     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  tsl_end_date)
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                          (select im.item,
                                  I_epw_ind,
                                  'U',
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  I_epw_dt
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                             from item_master im
                            where (im.item_parent      = I_item
                               or im.item_grandparent = I_item)
                              and im.status            = 'A'
                              and NOT exists (select 'x'
                                                from item_attributes ia
                                               where ia.item = im.item
                                                 and ia.tsl_country_id = 'U'))
                          UNION
                          (select im.item,
                                  I_epw_ind,
                                  'R',
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  I_epw_dt
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                             from item_master im
                            where (im.item_parent      = I_item
                               or im.item_grandparent = I_item)
                              and im.status            = 'A'
                              and NOT exists (select 'x'
                                                from item_attributes ia
                                               where ia.item = im.item
                                                 and ia.tsl_country_id = 'R'));

     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  tsl_end_date)
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                         (select im.item,
                                 I_epw_ind,
                                 'U',
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from packitem_breakout a,
                                 item_master im
                           where NOT exists (select b.pack_no
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.item_grandparent, '-999') != I_item)
                                                and (NVL(im2.item_parent, '-999') != I_item)
                                                and (NVL(im2.item, '-999') != I_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = 'U')
                           group by im.item)
                           UNION
                         (select im.item,
                                 I_epw_ind,
                                 'R',
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from packitem_breakout a,
                                 item_master im
                           where NOT exists (select b.pack_no
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.item_grandparent, '-999') != I_item)
                                                and (NVL(im2.item_parent, '-999') != I_item)
                                                and (NVL(im2.item, '-999') != I_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = 'R')
                           group by im.item);
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
     -- CR288d, 19-Jul-2010, Nishant Gupta, nishant.gupta@in.tesco.com, Begin
    elsif I_country IN ('P','S') then
     -- Updating the epw for the child and grand child for the inputted item
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            tsl_end_date = I_epw_dt
      where tsl_country_id = decode(I_country,'P','U','S','R')
      and exists (select 'x'
                      from item_master im
                     where ia.item              = im.item
                       and (im.item_parent      = I_item
                        or  im.item_grandparent = I_item)
                       and im.status            = 'A');

     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            tsl_end_date = I_epw_dt
      where tsl_country_id = decode(I_country,'P','U','S','R')
        and item in (select im.item
                       from packitem_breakout a,
                            item_master im
                      where NOT exists (select b.pack_no
                                          from packitem_breakout b,
                                               item_master im2
                                         where im2.item = b.item
                                           and (NVL(im2.item_grandparent, '-999') != I_item)
                                           and (NVL(im2.item_parent, '-999') != I_item)
                                           and (NVL(im2.item, '-999') != I_item)
                                           and b.pack_no = a.pack_no)
                        and (im.item = a.pack_no
                         or im.item_parent = a.pack_no)
                        and im.status = 'A'
                      group by im.item);

     -- This query will insert the record to the item_attributes table
     -- for the approved child and grand child for the inputed item and for both UK and ROI
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_item);

     if I_country = 'P' then

      insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  tsl_end_date)
                          (select im.item,
                                  I_epw_ind,
                                  'U',
                                  I_epw_dt
                             from item_master im
                            where (im.item_parent      = I_item
                               or im.item_grandparent = I_item)
                              and im.status            = 'A'
                              and NOT exists (select 'x'
                                                from item_attributes ia
                                               where ia.item = im.item
                                                 and ia.tsl_country_id = 'U'));

     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_item);

     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  tsl_end_date)
                         (select im.item,
                                 I_epw_ind,
                                 'U',
                                 I_epw_dt
                            from packitem_breakout a,
                                 item_master im
                           where NOT exists (select b.pack_no
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.item_grandparent, '-999') != I_item)
                                                and (NVL(im2.item_parent, '-999') != I_item)
                                                and (NVL(im2.item, '-999') != I_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = 'U')
                           group by im.item);
 else

      insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  tsl_end_date)
                          (select im.item,
                                  I_epw_ind,
                                  'R',
                                  I_epw_dt
                             from item_master im
                            where (im.item_parent      = I_item
                               or im.item_grandparent = I_item)
                              and im.status            = 'A'
                              and NOT exists (select 'x'
                                                from item_attributes ia
                                               where ia.item = im.item
                                                 and ia.tsl_country_id = 'R'));

     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  tsl_end_date)
                         (select im.item,
                                 I_epw_ind,
                                 'R',
                                 I_epw_dt
                            from packitem_breakout a,
                                 item_master im
                           where NOT exists (select b.pack_no
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.item_grandparent, '-999') != I_item)
                                                and (NVL(im2.item_parent, '-999') != I_item)
                                                and (NVL(im2.item, '-999') != I_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = 'R')
                           group by im.item);
    end if;

     -- Updating the epw for the child and grand child for the inputted item
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            tsl_end_date = I_epw_dt
      where tsl_country_id = decode(I_country,'P','U','S','R')
      and exists (select 'x'
                      from item_master im
                     where ia.item              = im.item
                       and (im.item_parent      = I_item
                        or  im.item_grandparent = I_item)
                       and im.status            = 'A');

     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            tsl_end_date = I_epw_dt
      where tsl_country_id = decode(I_country,'P','U','S','R')
        and item in (select im.item
                       from packitem_breakout a,
                            item_master im
                      where NOT exists (select b.pack_no
                                          from packitem_breakout b,
                                               item_master im2
                                         where im2.item = b.item
                                           and (NVL(im2.item_grandparent, '-999') != I_item)
                                           and (NVL(im2.item_parent, '-999') != I_item)
                                           and (NVL(im2.item, '-999') != I_item)
                                           and b.pack_no = a.pack_no)
                        and (im.item = a.pack_no
                         or im.item_parent = a.pack_no)
                        and im.status = 'A'
                      group by im.item);

     -- This query will insert the record to the item_attributes table
     -- for the approved child and grand child for the inputed item and for both UK and ROI
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_item);

     if I_country = 'P' then
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  tsl_end_date)
                          (select im.item,
                                  I_epw_ind,
                                  'U',
                                  I_epw_dt
                             from item_master im
                            where (im.item_parent      = I_item
                               or im.item_grandparent = I_item)
                              and im.status            = 'A'
                              and NOT exists (select 'x'
                                                from item_attributes ia
                                               where ia.item = im.item
                                                 and ia.tsl_country_id = 'U'));

     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  tsl_end_date)
                         (select im.item,
                                 I_epw_ind,
                                 'U',
                                 I_epw_dt
                            from packitem_breakout a,
                                 item_master im
                           where NOT exists (select b.pack_no
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.item_grandparent, '-999') != I_item)
                                                and (NVL(im2.item_parent, '-999') != I_item)
                                                and (NVL(im2.item, '-999') != I_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = 'U')
                           group by im.item);
    else

           insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  tsl_end_date)
                          (select im.item,
                                  I_epw_ind,
                                  'R',
                                  I_epw_dt
                             from item_master im
                            where (im.item_parent      = I_item
                               or im.item_grandparent = I_item)
                              and im.status            = 'A'
                              and NOT exists (select 'x'
                                                from item_attributes ia
                                               where ia.item = im.item
                                                 and ia.tsl_country_id = 'R'));

     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  tsl_end_date)
                         (select im.item,
                                 I_epw_ind,
                                 'R',
                                 I_epw_dt
                            from packitem_breakout a,
                                 item_master im
                           where NOT exists (select b.pack_no
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.item_grandparent, '-999') != I_item)
                                                and (NVL(im2.item_parent, '-999') != I_item)
                                                and (NVL(im2.item, '-999') != I_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = 'R')
                           group by im.item);

    end if;
  -- CR288d, 19-Jul-2010, Nishant Gupta, nishant.gupta@in.tesco.com, End
  -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
  end if;
  return TRUE;
EXCEPTION
  when E_record_locked then
    O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                          'ITEM_MASTER, ITEM_ATTRIBUTES',
                                           L_program,
                                          'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_item);
    return FALSE;
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
    return FALSE;
END TSL_COPY_DOWN_PARENT_EPW;
---------------------------------------------------------------------------------------------
-- Function Name : TSL_COPY_BASE_EPW
-- Purpose       : Updates/insert a values for the Emergency Product Withdrawal
--                 for all Approved Variant associated to a given Base Item and country
---------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_BASE_EPW (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_base_item      IN     ITEM_MASTER.ITEM%TYPE,
                            I_epw_ind        IN     ITEM_ATTRIBUTES.TSL_EPW_IND%TYPE,
                            I_country        IN     VARCHAR2,
                            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                            I_epw_dt         IN     ITEM_ATTRIBUTES.TSL_END_DATE%TYPE)
                            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
   RETURN BOOLEAN is

    E_record_locked  EXCEPTION;
    PRAGMA           EXCEPTION_INIT(E_record_locked, -54);
    L_program        VARCHAR2(300)   := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_BASE_EPW';

    -- This cursor will lock the variant information on the table ITEM_ATTRIBUTES
    cursor C_LOCK_ITEM_ATTRIBUTES is
    select 'x'
      from item_attributes ia
     where tsl_country_id = I_country
       and ia.item in (select im2.item
                         from item_master im1,
                              item_master im2
                        where im1.tsl_base_item    = I_base_item
                          and im1.tsl_base_item   != im1.item
                          and im1.item_level       = im1.tran_level
                          and im1.item_level       = 2
                          and im2.status           = 'A'
                          and (im2.item_parent     = im1.item
                           or im1.item             = im2.item))
       for update nowait;

BEGIN
  if I_base_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_base_item,
                                             L_program,
                                             NULL);
      return FALSE;
  end if;
  -- Locking the records
  SQL_LIB.SET_MARK('OPEN',
                   'C_LOCK_ITEM_ATTRIBUTES',
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_base_item);
  open C_LOCK_ITEM_ATTRIBUTES;

  SQL_LIB.SET_MARK('CLOSE',
                   'C_LOCK_ITEM_ATTRIBUTES',
                   'ITEM_MASTER, ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_base_item);
  close C_LOCK_ITEM_ATTRIBUTES;

  if I_country IN ('U','R') then
     -- Locking the records
     SQL_LIB.SET_MARK('OPEN',
                      'C_LOCK_ITEM_ATTRIBUTES',
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_base_item);
     open C_LOCK_ITEM_ATTRIBUTES;

     SQL_LIB.SET_MARK('CLOSE',
                      'C_LOCK_ITEM_ATTRIBUTES',
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_base_item);
     close C_LOCK_ITEM_ATTRIBUTES;

     -- This query will return the Approved Variant Item for the
     -- passed Base Item that exists on the ITEM_ATTRIBUTES table
     -- DefNBS015999, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_base_item);
     update item_attributes ia
        set tsl_epw_ind = 'N',
            tsl_end_date = NULL
      where tsl_country_id in ('U','R')
        and ia.item in (select im2.item
                          from item_master im1,
                               item_master im2
                         where im1.tsl_base_item    = I_base_item
                           and im1.tsl_base_item   != im1.item
                           and im1.item_level       = im1.tran_level
                           and im1.item_level       = 2
                           and im2.status           = 'A'
                           and (im2.item_parent     = im1.item
                             or im1.item             = im2.item));
     -- DefNBS015999, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     ---
     SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_base_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
            tsl_end_date = I_epw_dt
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
      where tsl_country_id = I_country
        and ia.item in (select im2.item
                          from item_master im1,
                               item_master im2
                         where im1.tsl_base_item    = I_base_item
                           and im1.tsl_base_item   != im1.item
                           and im1.item_level       = im1.tran_level
                           and im1.item_level       = 2
                           and im2.status           = 'A'
                           and (im2.item_parent     = im1.item
                            or im1.item             = im2.item));
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_base_item);
     update item_attributes ia
        set tsl_epw_ind = 'N',
            tsl_end_date = NULL
      where tsl_country_id in ('U','R')
        and item in (select im.item
                       from packitem_breakout a,
                            item_master im
                      where exists (select b.pack_no
                                          from packitem_breakout b,
                                               item_master im2
                                         where im2.item = b.item
                                           and (NVL(im2.tsl_base_item, '-999') = I_base_item)
                                           and b.pack_no = a.pack_no)
                        and (im.item = a.pack_no
                         or im.item_parent = a.pack_no)
                        and im.status = 'A'
                      group by im.item);
     -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     ---
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_base_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
            tsl_end_date = I_epw_dt
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
      where tsl_country_id = I_country
        and item in (select im.item
                       from packitem_breakout a,
                            item_master im
                      -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                      -- Changed from not exist to exist
                      where exists (select b.pack_no
                      -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                          from packitem_breakout b,
                                               item_master im2
                                         where im2.item = b.item
                                           and (NVL(im2.tsl_base_item, '-999') = I_base_item)
                                           and b.pack_no = a.pack_no)
                        and (im.item = a.pack_no
                         or im.item_parent = a.pack_no)
                        and im.status = 'A'
                      group by im.item);
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     -- This query will return the Approved Variant Items for the
     -- passed Base Item, that doesn?t exist on the ITEM_ATTRIBUTES table
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_base_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  tsl_end_date)
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                          select im2.item,
                                 I_epw_ind,
                                 I_country,
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from item_master im1,
                                 item_master im2
                           where im1.tsl_base_item    = I_base_item
                             and im1.tsl_base_item   != im1.item
                             and im1.item_level       = im1.tran_level
                             and im1.item_level       = 2
                             and im2.status           = 'A'
                             and (im2.item_parent     = im1.item
                              or im1.item             = im2.item)
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im2.item
                                                and ia.tsl_country_id = I_country) ;
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_base_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  tsl_end_date)
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                          select im.item,
                                 I_epw_ind,
                                 I_country,
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from packitem_breakout a,
                                 item_master im
                           -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                           -- Changed from not exist to exist
                           where exists (select b.pack_no
                           -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.tsl_base_item, '-999') = I_base_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = I_country)
                           group by im.item;

     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
  elsif I_country IN ('B','N') then
     -- This query will return the Approved Variant Item for the
     -- passed Base Item that exists on the ITEM_ATTRIBUTES table
     SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_base_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
            tsl_end_date = I_epw_dt
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
      where tsl_country_id IN ('U','R')
        and ia.item in (select im2.item
                          from item_master im1,
                               item_master im2
                         where im1.tsl_base_item    = I_base_item
                           and im1.tsl_base_item   != im1.item
                           and im1.item_level       = im1.tran_level
                           and im1.item_level       = 2
                           and im2.status           = 'A'
                           and (im2.item_parent     = im1.item
                            or im1.item             = im2.item));
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('UPDATE',
                      NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_base_item);
     update item_attributes ia
        set tsl_epw_ind = I_epw_ind,
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
            tsl_end_date = I_epw_dt
            --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
      where tsl_country_id in ('U','R')
        and item in (select im.item
                       from packitem_breakout a,
                            item_master im
                      -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                      -- Changed from not exist to exist
                      where exists (select b.pack_no
                      -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                          from packitem_breakout b,
                                               item_master im2
                                         where im2.item = b.item
                                           and (NVL(im2.tsl_base_item, '-999') = I_base_item)
                                           and b.pack_no = a.pack_no)
                        and (im.item = a.pack_no
                         or im.item_parent = a.pack_no)
                        and im.status = 'A'
                      group by im.item);
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     -- This query will return the Approved Variant Items for the
     -- passed Base Item, that doesn't exist on the ITEM_ATTRIBUTES table
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'ITEM: ' ||I_base_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  tsl_end_date)
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                         (select im2.item,
                                 I_epw_ind,
                                 'U',
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from item_master im1,
                                 item_master im2
                           where im1.tsl_base_item    = I_base_item
                             and im1.tsl_base_item   != im1.item
                             and im1.item_level       = im1.tran_level
                             and im1.item_level       = 2
                             and im2.status           = 'A'
                             and (im2.item_parent     = im1.item
                              or im1.item             = im2.item)
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im2.item
                                                and ia.tsl_country_id = 'U'))
                         UNION
                         (select im2.item,
                                 I_epw_ind,
                                 'R',
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from item_master im1,
                                 item_master im2
                           where im1.tsl_base_item    = I_base_item
                             and im1.tsl_base_item   != im1.item
                             and im1.item_level       = im1.tran_level
                             and im1.item_level       = 2
                             and im2.status           = 'A'
                             and (im2.item_parent     = im1.item
                              or im1.item             = im2.item)
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im2.item
                                                and ia.tsl_country_id = 'R'));

     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     SQL_LIB.SET_MARK('INSERT',
                       NULL,
                      'ITEM_MASTER, ITEM_ATTRIBUTES',
                      'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_base_item);
     insert into item_attributes (item,
                                  tsl_epw_ind,
                                  tsl_country_id,
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                  tsl_end_date)
                                  --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                         (select im.item,
                                 I_epw_ind,
                                 'U',
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from packitem_breakout a,
                                 item_master im
                           -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                           -- Changed from not exist to exist
                           where exists (select b.pack_no
                           -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.tsl_base_item, '-999') = I_base_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = 'U')
                           group by im.item)
                           UNION
                         (select im.item,
                                 I_epw_ind,
                                 'R',
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, Begin
                                 I_epw_dt
                                 --LT DefNBS017489, 20-May-2010, Sripriya,Sripriya.karanam@in.tesco.com, End
                            from packitem_breakout a,
                                 item_master im
                           -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                           -- Changed from not exist to exist
                           where exists (select b.pack_no
                           -- DefNBS015988, 20-Jan-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                               from packitem_breakout b,
                                                    item_master im2
                                              where im2.item = b.item
                                                and (NVL(im2.tsl_base_item, '-999') = I_base_item)
                                                and b.pack_no = a.pack_no)
                             and (im.item = a.pack_no
                              or im.item_parent = a.pack_no)
                             and im.status = 'A'
                             and NOT exists (select 'x'
                                               from item_attributes ia
                                              where ia.item = im.item
                                                and ia.tsl_country_id = 'R')
                           group by im.item);
     -- CR236a, 15-Dec-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
    -- CR288d, 19-Jul-2010, Nishant Gupta, nishant.gupta@in.tesco.com, Begin
    elsif I_country IN ('P','S') then
       -- This query will return the Approved Variant Item for the
       -- passed Base Item that exists on the ITEM_ATTRIBUTES table
       SQL_LIB.SET_MARK('UPDATE',
                         NULL,
                        'ITEM_MASTER, ITEM_ATTRIBUTES',
                        'TSL_COUNTRY_ID: ' ||I_country ||' '|| 'ITEM: ' ||I_base_item);
       update item_attributes ia
          set tsl_epw_ind = I_epw_ind,
              tsl_end_date = I_epw_dt
        where tsl_country_id = decode(I_country,'P','U','S','R')
          and ia.item in (select im2.item
                            from item_master im1,
                                 item_master im2
                           where im1.tsl_base_item    = I_base_item
                             and im1.tsl_base_item   != im1.item
                             and im1.item_level       = im1.tran_level
                             and im1.item_level       = 2
                             and im2.status           = 'A'
                             and (im2.item_parent     = im1.item
                              or im1.item             = im2.item));
       SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                        'ITEM_MASTER, ITEM_ATTRIBUTES',
                        'ITEM: ' ||I_base_item);
       update item_attributes ia
          set tsl_epw_ind = I_epw_ind,
              tsl_end_date = I_epw_dt
        where tsl_country_id = decode(I_country,'P','U','S','R')
          and item in (select im.item
                         from packitem_breakout a,
                              item_master im
                        where exists (select b.pack_no
                                            from packitem_breakout b,
                                                 item_master im2
                                           where im2.item = b.item
                                             and (NVL(im2.tsl_base_item, '-999') = I_base_item)
                                             and b.pack_no = a.pack_no)
                          and (im.item = a.pack_no
                           or im.item_parent = a.pack_no)
                          and im.status = 'A'
                        group by im.item);
       -- This query will return the Approved Variant Items for the
       -- passed Base Item, that doesn't exist on the ITEM_ATTRIBUTES table
       SQL_LIB.SET_MARK('INSERT',
                         NULL,
                        'ITEM_MASTER, ITEM_ATTRIBUTES',
                        'ITEM: ' ||I_base_item);
             if I_country = 'P' then

               insert into item_attributes (item,
                                            tsl_epw_ind,
                                            tsl_country_id,
                                            tsl_end_date)
                                   (select im2.item,
                                           I_epw_ind,
                                           'U',
                                           I_epw_dt
                                      from item_master im1,
                                           item_master im2
                                     where im1.tsl_base_item    = I_base_item
                                       and im1.tsl_base_item   != im1.item
                                       and im1.item_level       = im1.tran_level
                                       and im1.item_level       = 2
                                       and im2.status           = 'A'
                                       and (im2.item_parent     = im1.item
                                        or im1.item             = im2.item)
                                       and NOT exists (select 'x'
                                                         from item_attributes ia
                                                        where ia.item = im2.item
                                                          and ia.tsl_country_id = 'U'));

               SQL_LIB.SET_MARK('INSERT',
                                 NULL,
                                'ITEM_MASTER, ITEM_ATTRIBUTES',
                                'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_base_item);
               insert into item_attributes (item,
                                            tsl_epw_ind,
                                            tsl_country_id,
                                            tsl_end_date)
                                   (select im.item,
                                           I_epw_ind,
                                           'U',
                                           I_epw_dt
                                      from packitem_breakout a,
                                           item_master im
                                     where exists (select b.pack_no
                                                         from packitem_breakout b,
                                                              item_master im2
                                                        where im2.item = b.item
                                                          and (NVL(im2.tsl_base_item, '-999') = I_base_item)
                                                          and b.pack_no = a.pack_no)
                                       and (im.item = a.pack_no
                                        or im.item_parent = a.pack_no)
                                       and im.status = 'A'
                                       and NOT exists (select 'x'
                                                         from item_attributes ia
                                                        where ia.item = im.item
                                                          and ia.tsl_country_id = 'U')
                                     group by im.item);
          else

               insert into item_attributes (item,
                                            tsl_epw_ind,
                                            tsl_country_id,
                                            tsl_end_date)
                                   (select im2.item,
                                           I_epw_ind,
                                           'R',
                                           I_epw_dt
                                      from item_master im1,
                                           item_master im2
                                     where im1.tsl_base_item    = I_base_item
                                       and im1.tsl_base_item   != im1.item
                                       and im1.item_level       = im1.tran_level
                                       and im1.item_level       = 2
                                       and im2.status           = 'A'
                                       and (im2.item_parent     = im1.item
                                        or im1.item             = im2.item)
                                       and NOT exists (select 'x'
                                                         from item_attributes ia
                                                        where ia.item = im2.item
                                                          and ia.tsl_country_id = 'R'));

               SQL_LIB.SET_MARK('INSERT',
                                 NULL,
                                'ITEM_MASTER, ITEM_ATTRIBUTES',
                                'TSL_COUNTRY_ID: ' ||I_country ||' '||'ITEM: ' ||I_base_item);
               insert into item_attributes (item,
                                            tsl_epw_ind,
                                            tsl_country_id,
                                            tsl_end_date)
                                   (select im.item,
                                           I_epw_ind,
                                           'R',
                                           I_epw_dt
                                      from packitem_breakout a,
                                           item_master im
                                     where exists (select b.pack_no
                                                         from packitem_breakout b,
                                                              item_master im2
                                                        where im2.item = b.item
                                                          and (NVL(im2.tsl_base_item, '-999') = I_base_item)
                                                          and b.pack_no = a.pack_no)
                                       and (im.item = a.pack_no
                                        or im.item_parent = a.pack_no)
                                       and im.status = 'A'
                                       and NOT exists (select 'x'
                                                         from item_attributes ia
                                                        where ia.item = im.item
                                                          and ia.tsl_country_id = 'R')
                                     group by im.item);

          end if;
    -- CR288d, 19-Jul-2010, Nishant Gupta, nishant.gupta@in.tesco.com, End
    -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end


  end if;
  return TRUE;
EXCEPTION
  when E_record_locked then
    O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                          'ITEM_MASTER, ITEM_ATTRIBUTES',
                                           L_program,
                                          'ITEM: ' ||I_base_item);
    return FALSE;
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
    return FALSE;
END TSL_COPY_BASE_EPW;
-------------------------------------------------------------------------------------
-- CR236, 24-Aug-2009, Sarayu Gouda, sarayu.gouda@in.tesco.com, End
-------------------------------------------------------------------------------------
-- CR258 21-Apr-2010 Chandru Begin
-----------------------------------------------------------------------------------------
-- Function Name : TSL_COPY_ITEM_PACK_ATTRIB
-- Purpose       : Updates/creates the Item attributes for TPND, from the Item Attributes
--                 defined for the selected Item parent - L1/L2 item to pack level.
-----------------------------------------------------------------------------------------
FUNCTION TSL_COPY_ITEM_PACK_ATTRIB (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item_rec       IN     ITEM_MASTER%ROWTYPE,
                                    I_base_ind       IN     VARCHAR2,
                                    I_country_id     IN     VARCHAR2,
                                    -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                    I_login_ctry     IN     VARCHAR2,
                                    -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                                    I_column_name    IN     VARCHAR2,
                                    -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                                    -- 14-Apr-11     Nandini M     PrfNBS022237     End
                                    -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
                                    I_exclude_in_cascade IN  VARCHAR2 DEFAULT  'N'
                                    -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                    )
  RETURN BOOLEAN is

  E_record_locked  EXCEPTION;
  PRAGMA           EXCEPTION_INIT(E_record_locked, -54);
  L_program        VARCHAR2(300)   := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_PACK_ATTRIB';
  L_close_cursor   VARCHAR2(2000)  := ' close C_GET_ITEM_ATTRIB;';
  L_end            VARCHAR2(10)    := ' end;';
  L_sql_select     VARCHAR2(32767) := NULL;
  L_sql_insert     VARCHAR2(32767) := NULL;
 -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
  -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
  --08-Jul-10      JK    DefNBS018117    Begin
  L_insert_sql     VARCHAR2(32767) := NULL;
  L_update_sql     VARCHAR2(32767) := NULL;
  --08-Jul-10      JK    DefNBS018117    End
  -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
  -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
  L_sql_update     VARCHAR2(32767) := NULL;
  L_sql_column     VARCHAR2(32767) := NULL;
  L_statement      VARCHAR2(32767) := NULL;
  L_clause         VARCHAR2(32767) := NULL;
  L_lvl2_ind       VARCHAR2(1)     := 'N';
  L_lvl3_ind       VARCHAR2(1)     := 'N';
  L_exists         BOOLEAN         := FALSE;
  --CR354 16-Aug-10 Praveen Begin
  L_tsl_loc_sec_ind   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_owner_cntry   SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
  --CR354 16-Aug-10 Praveen End
  L_item_level     ITEM_MASTER.ITEM_LEVEL%TYPE;
  L_item_rec      ITEM_MASTER%ROWTYPE;
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
  L_system_options_row    SYSTEM_OPTIONS%ROWTYPE;
  L_owner_country         ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_security_ind          SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
  L_login_ctry            ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_uk_ind                VARCHAR2(1) :=  'N';
  L_roi_ind               VARCHAR2(1) :=  'N';
   --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End

  cursor C_LOCK_ITEM_PACK is
  select 'x'
    from item_attributes ia
   where ia.item in (select pack_no item
                       from packitem
                      where item in (select item
                                       from item_master
                                      where item_parent = I_item_rec.item
                                         or item        = I_item_rec.item
                                         -- CR354 18-Aug-2010 Praveen Begin
                                        and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry))))
                                         -- CR354 18-Aug-2010 Praveen End
     and ia.tsl_country_id = I_country_id
     for update nowait;
  -- Cursor will used to cascade the level1 pack to level2 pack process
  cursor C_GET_PACKS is
     select pack_no item
       from packitem
      where item in (select item
                       from item_master
                      where item_parent = I_item_rec.item
                         or item = I_item_rec.item
                        -- CR354 18-Aug-2010 Praveen Begin
                        and (L_tsl_loc_sec_ind = 'N' or (L_tsl_loc_sec_ind = 'Y' and tsl_owner_country = L_owner_cntry)));
                        -- CR354 18-Aug-2010 Praveen End

  -- This cursor will retrieve the codes, and the corresponding column for the
  -- attributes that can be copied between a Level 1 Item to Pack Item
  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
  cursor C_GET_COLUMNS is
     select tmc.tsl_column_name column_name,
            tmc.tsl_code code,
            mhd.required_ind req_ind
       from tsl_map_item_attrib_code tmc,
            merch_hier_default mhd
   where tmc.tsl_column_name =  NVL(upper(I_column_name),tmc.tsl_column_name)
     and tmc.tsl_code        = mhd.info
     and mhd.info           != 'TEPW'
     and mhd.tsl_pack_ind    = 'Y'
     and mhd.available_ind   = 'Y'
     and mhd.tsl_item_lvl    = 1
     and mhd.tsl_country_id in (I_country_id,'B')
     and mhd.dept            = I_item_rec.dept
     and mhd.class           = I_item_rec.class
     and mhd.subclass        = I_item_rec.subclass
     and (exists (select 1
                    from merch_hier_default a
                   where a.info = mhd.info
                     and a.available_ind = 'Y'
                     and a.tsl_country_id in (I_country_id,'B')
                     and a.dept          = mhd.dept
                     and a.class         = mhd.class
                     and a.subclass      = mhd.subclass
                     and a.tsl_item_lvl  = I_item_rec.item_level
                     and a.tsl_pack_ind  = I_item_rec.pack_ind
                     and DECODE(L_lvl2_ind,'Y',DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
              or
       not exists (select 1
                     from merch_hier_default a
                    where a.info = mhd.info
                      and a.dept          = mhd.dept
                      and a.class         = mhd.class
                      and a.subclass      = mhd.subclass
                      and a.tsl_country_id in (I_country_id,'B')
                      and a.tsl_item_lvl  = I_item_rec.item_level
                      and a.tsl_pack_ind  = I_item_rec.pack_ind
                      and DECODE(L_lvl2_ind,'Y',DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y'))
     -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
    and (
         (I_exclude_in_cascade='Y'
          and not exists(select 1
                           from tsl_attr_stpcas sca
                          where sca.tsl_itm_attr_id=tmc.tsl_code
                        )
          )
         or I_exclude_in_cascade='N'
         )
     -- 23-Oct-2013  Gopinath Meganathan PM020648 End
    union
    select tmc.tsl_column_name column_name,
           tmc.tsl_code code,
           'N' req_ind
      from tsl_map_item_attrib_code tmc
     where not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.dept = I_item_rec.dept
                          and a.class = I_item_rec.class
                          and a.subclass = I_item_rec.subclass
                          and a.tsl_country_id in (I_country_id,'B')
                          and a.tsl_pack_ind  = 'Y'
                          and a.tsl_item_lvl =  1)
       and not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.available_ind = 'N'
                          and a.dept = I_item_rec.dept
                          and a.class = I_item_rec.class
                          and a.subclass = I_item_rec.subclass
                          and a.tsl_country_id in (I_country_id,'B')
                          and a.tsl_pack_ind  = I_item_rec.pack_ind
                          and a.tsl_item_lvl = I_item_rec.item_level
                          and DECODE(L_lvl2_ind,'Y',DECODE(I_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
       and tmc.tsl_column_name =  NVL(upper(I_column_name),tmc.tsl_column_name)
       and tmc.tsl_code != 'TEPW'
       -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
       and (
			(I_exclude_in_cascade='Y'
			 and not exists(select 1
							  from tsl_attr_stpcas sca
							 where sca.tsl_itm_attr_id=tmc.tsl_code
						   )
		    )
			or I_exclude_in_cascade='N'
           );
   -- 23-Oct-2013  Gopinath Meganathan PM020648 End
   -- 14-Apr-11     Nandini M     PrfNBS022237     End
    -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
BEGIN
   -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
   L_login_ctry := I_login_ctry;
   -- 14-Apr-11    Nandini M     PrfNBS022237     End

   if I_item_rec.item is NULL then      -- L1 begin
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_item_rec.item,
                                            L_program,
                                            NULL);
      return FALSE;
  end if;                             -- L1 end

   --CR354 16-Aug-10 Praveen Begin
   if SYSTEM_OPTIONS_SQL.TSL_GET_LOC_SEC_IND (O_error_message,
                                              L_tsl_loc_sec_ind) = FALSE then
         return FALSE;
   end if;

   if ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY (O_error_message,
                                             L_owner_cntry,
                                             I_item_rec.item) = FALSE then
      return FALSE;
   end if;
   --CR354 16-Aug-10 Praveen End
   --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_system_options_row) = FALSE then
      return FALSE;
   end if;
   ---
   L_security_ind := L_system_options_row.tsl_loc_sec_ind;
   -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
   -- MrgNBS022368(fix), 19-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com Begin
   if L_security_ind = 'Y' and NVL(I_login_ctry,'N') = 'N' then
   -- MrgNBS022368(fix), 19-Apr-2011, Vinutha Raju, vinutha.raju@in.tesco.com End
   -- 14-Apr-11     Nandini M     PrfNBS022237     End
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
   end if;
   --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End

  if I_item_rec.tran_level = 2 and
     I_item_rec.item_level < I_item_rec.tran_level and
     I_item_rec.pack_ind = 'N' then         -- L2 begin
     L_lvl2_ind := 'N';
     L_item_level := 1;
  elsif I_item_rec.tran_level = 2 and
        I_item_rec.item_level = I_item_rec.tran_level and
        I_item_rec.pack_ind = 'N' then      -- L2 elseif
     L_lvl2_ind := 'Y';
     L_item_level := 1;
  end if;      -- L2 end

  -- This cursor will retrieve the codes, and the corresponding column for the attributes
  -- that can be copied between the L1 item to L2 Items
  --Opening the cursor C_GET_COLUMNS
  SQL_LIB.SET_MARK('OPEN',
                   'C_GET_COLUMNS',
                   'TSL_MAP_ITEM_ATTRIB_CODE',
                   'ITEM: ' ||I_item_rec.item);
  FOR C_rec in C_GET_COLUMNS LOOP                                -- L3 begin
     -- checking L_sql_select is null or not
      L_exists := TRUE;
      if L_sql_select is NULL then      -- L4 begin
         L_sql_insert := 'ia.'||C_rec.column_name;
         L_sql_select := C_rec.column_name;
         --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
         if (((I_item_rec.tsl_owner_country = L_login_ctry) or
             L_security_ind = 'N') or
             (I_item_rec.tsl_owner_country <> L_login_ctry and
              L_security_ind = 'Y'
              -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
              -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
              )) then
                 -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                 -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                 -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 Begin
                 if c_rec.code <> 'TLDT' then
                    L_sql_update := C_rec.column_name||' = decode(''' ||C_rec.req_ind || ''',
                                    '' Y'',' || ' nvl(row_data.' || C_rec.column_name || ','
                                    ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
                 elsif c_rec.code = 'TLDT' then
                    L_sql_update := C_rec.column_name||' = row_data.' || C_rec.column_name ;
                 end if;
                 -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 End
              end if;
         --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
         L_sql_column := ' and t.tsl_code NOT in (''TEPW''';
      else                        -- L4 else
         L_sql_insert := L_sql_insert ||',ia.'|| C_rec.column_name;
         L_sql_select := L_sql_select || ', ' || C_rec.column_name;
         --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
         if (((I_item_rec.tsl_owner_country = L_login_ctry) or
             L_security_ind = 'N') or
             (I_item_rec.tsl_owner_country <> L_login_ctry and
              L_security_ind = 'Y'
              -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
              -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
              )) then
                 -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
                 -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
                 -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 Begin
                 if c_rec.code <> 'TLDT' then
                    L_sql_update := L_sql_update || ', ' || C_rec.column_name || ' =
                                    decode(''' || C_rec.req_ind || ''',''Y'',' || ' nvl(row_data.'
                                    || C_rec.column_name || ','  ||C_rec.column_name || '), row_data.' || C_rec.column_name || ')';
                 elsif c_rec.code = 'TLDT' then
                    L_sql_update := L_sql_update || ', ' || C_rec.column_name || ' = row_data.'
                                    || C_rec.column_name ;
                 end if;
                 -- DefNBS023175 shweta.madnawat@in.tesco.com 06-Jul-2011 End
              end if;
             --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
           end if;                     -- L4 end
      -- checking req_ind is 'Y' or 'N'
      if C_rec.req_ind = 'N' then        -- L5 begin
         L_sql_column := L_sql_column || ', '''|| C_rec.code || '''';
      else            -- L5 else
         L_sql_column := L_sql_column || ', decode(ia.' || C_rec.column_name ||
                         ', null, ''x'', ''' || C_rec.code || ''')';
      end if;          -- L5 end
  END LOOP;          -- L3 end
  ---
  if L_sql_column is NOT NULL then          -- L6 begin
     L_sql_column := L_sql_column||')';
  end if;     -- L6 end
  ---
  if L_exists = TRUE then    -- L7 begin
     if I_item_rec.item_level < I_item_rec.tran_level then -- From Style
        L_clause:= ' and im.item_level = im.tran_level';
     elsif I_item_rec.item_level = I_item_rec.tran_level then
        if I_item_rec.item = I_item_rec.tsl_base_item then
           L_clause :=  ' and im.item = im.tsl_base_item';
        else
           L_clause :=  ' and im.item != im.tsl_base_item';
        end if;
     end if;   -- L8 end

  end if;   -- L7 end
  ---
  --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
  --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   Begin
  if L_security_ind = 'Y' then
     ---
     L_owner_country := I_item_rec.tsl_owner_country;
     ---
  --01-Oct-2010    TESCO HSC/Praveen        DefNBS019341   End
  elsif L_security_ind = 'N' then
     L_owner_country := 'U';
  end if;
  -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
  if L_sql_update is NOT NULL then
     --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
     --07-Jul-10     JK     DefNBS018117     Begin
     --28-Sep-10     praveen     PefNBS018117     Begin
      L_update_sql := ' update item_attributes' ||
                         ' set ' || L_sql_update ||
                       ' where tsl_country_id = :I_country_id1 '||
                         ' and item in (select im.item' ||
                                        ' from item_master im' ||
                                       ' where im.item in '||
                                       ' (select pai.pack_no '||
                                          ' from packitem pai '||
                                          ' where pai.item in (select im.item '||
                                          ' from item_master im '||
                                          --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   Begin
                                          ' where ((im.tsl_owner_country = :L_owner_country) or (:L_security_ind = ''N''))'||
                                          ' start with im.item = :itm1 connect by prior im.item = im.item_parent ))'||
                                        '  and ((im.tsl_owner_country = :L_owner_country2) or (:L_security_ind2 = ''N'')));';
                                        --03-Sep-2010    TESCO HSC/Joy Stephen    DefNBS018990   End
                                       /*' or im.item in '||
                                       ' (select pai.pack_no '||
                                          ' from packitem pai '||
                                          ' where pai.item = '''|| I_item_rec.item ||''')'||');'; */
                     --                   L_clause || ');';
  end if;
  -- 14-Apr-11     Nandini M     PrfNBS022237     End

  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
	if L_sql_insert is NOT NULL then
     -- Populate the L_sql_insert variable for the insert of the Item Children of the selected Item
     L_insert_sql := 'insert into item_attributes (item, tsl_country_id, '|| L_sql_select ||' )' ||
                                         ' select im.item, :I_country_id2,'|| L_sql_insert ||
                                           ' from item_master im, item_attributes ia'||
                                          ' where ia.item = :item2 '||
                                            ' and ia.tsl_country_id = :I_country_id3 '||
                                            ' and im.item in (select im.item' ||
                                                              ' from item_master im' ||
                                                             ' where im.item in '||
                                                                ' (select pai.pack_no '||
                                                                   ' from packitem pai '||
                                                                  ' where pai.item in (select im.item '||
                                                                                       ' from item_master im '||
                                                                                      ' start with im.item = :itm3 connect by prior im.item = im.item_parent )))'||
   /*                                       ' or im.item in '||
                                                 ' (select pai.pack_no '||
                                                    ' from packitem pai '||
                                                   ' where pai.item = '''|| I_item_rec.item ||''')'||')'|| */
                                             --' and im.item_level = '||L_item_level||' '||
                                            --L_clause||
                                            ' and not exists (select 1'||
                                                              ' from item_attributes b '||
                                                              ' where b.item = im.item '||
                                                              '   and b.tsl_country_id = :I_country_id4)' ||
                                            ' and not exists (select 1 '||
                                                              ' from merch_hier_default m, '||
                                                                   ' tsl_map_item_attrib_code t'||
                                                             ' where m.info = t.tsl_code'||
                                                               ' and m.required_ind = ''Y'''||
                                                               ' and m.tsl_country_id in (''B'',:I_country_id5) '||
                                                               ' and m.dept = :dpt '||
                                                               ' and m.class = :cls '||
                                                               ' and m.subclass = :subcls '||
                                                               ' and m.tsl_pack_ind = ''Y'''||
                                                               ' and m.tsl_item_lvl = '||NVL(L_item_level,1);

     -- Add to L_sql_insert variable the L_sql_column variable
     L_insert_sql := L_insert_sql || L_sql_column|| ');';
  end if;
  -- 14-Apr-11     Nandini M     PrfNBS022237     End
   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end


  --07-Jul-10     JK     DefNBS018117     End
  -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
  -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
  -- Populate the L_sql_select variable for the select of the Item Parent information
  -- Populate the L_sql_select variable for the select of the Item Parent information

	L_sql_select := ' select '|| L_sql_select ||
                    ' from item_attributes' ||
                    ' where item = :item6 '||
                    '   and tsl_country_id = :I_country_id6 ;';
  --28-Sep-10     praveen     PefNBS018117     End
  -- Populate the L_statement variable to be used on the Execute Immediate statement
  L_statement := 'Declare' ||
                   ' Cursor C_GET_ITEM_ATTRIB is' ||
                        L_sql_select ||
                   ' row_data C_GET_ITEM_ATTRIB%ROWTYPE;' ||
                   ' Begin' ||
                      ' open C_GET_ITEM_ATTRIB;'||
                      ' fetch C_GET_ITEM_ATTRIB into row_data;';
  ---
  if I_item_rec.tran_level = 2 and
     I_item_rec.item_level < I_item_rec.tran_level then   -- L12 begin
     if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_ATTRIB_L3 (O_error_message,
                                                         I_item_rec,
                                                         I_base_ind,
                                                         I_country_id,
                                                         -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                                         L_login_ctry,
                                                         -- 14-Apr-11     Nandini M     PrfNBS022237     End
														 -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
														 I_exclude_in_cascade
														 -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                                         ) = FALSE then
        return FALSE;
     end if;
      ---
  end if;  -- L12 end
  ---
  -- Locking the pack items
  SQL_LIB.SET_MARK('OPEN',
                   'C_LOCK_ITEM_PACK',
                   'ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item_rec.item);
  open C_LOCK_ITEM_PACK;

  SQL_LIB.SET_MARK('CLOSE',
                   'C_LOCK_ITEM_PACK',
                   'ITEM_ATTRIBUTES',
                   'ITEM: ' ||I_item_rec.item);
  close C_LOCK_ITEM_PACK;
  -- Execute the Dynamic SQL, using the instruction EXECUTE IMMEDIATE

  -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
  -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, Begin
  --08-Jul-10      JK    DefNBS018117    Begin
  --28-Sep-10     praveen     PefNBS018117     Begin
  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 Begin
  -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin Replace the I_country_id with L_Login_ctry to 3rd passing parameter
  -- DefNBS020780, Venkatesh S, Venkatesh.suvarna@in.tesco.com 3-Feb-2011 Begin
  --DefNBS021727,25-Feb-2011,Sripriya,Sripriya.karanam@in.tesco.com,Begin
  --replacing back I_country_id to L_Login_ctry for 3rd parameter
   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
  -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
	if L_update_sql is NOT NULL or L_insert_sql is NOT NULL then
	     EXECUTE IMMEDIATE L_statement||L_update_sql||L_close_cursor||L_insert_sql||L_end using I_item_rec.item,I_country_id,I_country_id,L_owner_country,L_security_ind,I_item_rec.item,L_owner_country,L_security_ind,I_country_id,I_item_rec.item,I_country_id,I_item_rec.item,I_country_id,I_country_id,I_item_rec.dept,I_item_rec.class,I_item_rec.subclass;
	end if;
  -- 14-Apr-11     Nandini M     PrfNBS022237     End
   -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
   --DefNBS021727,25-Feb-2011,Sripriya,Sripriya.karanam@in.tesco.com,End
  -- DefNBS020780, Venkatesh S, Venkatesh.suvarna@in.tesco.com 3-Feb-2011 End
  -- DefNBS020504 , 13-Jan-2011 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
  -- MrgNBS020599, Venkatesh S, Venkatesh.suvarna@in.tesco.com 21-Jan-2011 End
  --28-Sep-10     praveen     PefNBS018117     End
  --08-Jul-10      JK    DefNBS018117    End
  -- 05-Aug-2010, MrgNBS018606, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, End
  -- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end

  -- Cascade down from Level1 pack to L2 packs
  FOR C_rec in C_GET_PACKS LOOP
     if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                         L_item_rec,
                                         C_rec.item) = FALSE then
        return FALSE;
     end if;
     if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_ITEM_ATTRIB (O_error_message,
                                                      L_item_rec,
                                                      NULL,
                                                      I_country_id,
                                                      -- 14-Apr-11    Nandini M     PrfNBS022237     Begin
                                                      L_login_ctry,
                                                      -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, begin
                                                      I_column_name,
                                                      -- MrgNBS022412 (3.5b to PrdSi), Bhargavi Pujari, bharagavi.pujari@in.tesco.com, 26-Apr-2011, end
                                                      -- 14-Apr-11    Nandini M     PrfNBS022237     End
													  -- 23-Oct-2013  Gopinath Meganathan PM020648 Begin
													  I_exclude_in_cascade
												      -- 23-Oct-2013  Gopinath Meganathan PM020648 End
                                                      ) = FALSE then
        return FALSE;
     end if;
  END LOOP;
  ---
  return TRUE;
EXCEPTION
   when E_record_locked then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_MASTER, ITEM_ATTRIBUTES',
                                            L_program,
                                            'ITEM: ' ||I_item_rec.item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_COPY_ITEM_PACK_ATTRIB;
-- CR258 21-Apr-2010 Chandru End
-- 01-Jun-10    JK    MrgNBS017783   Begin
-- DefNBS017627, 26-May-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
---------------------------------------------------------------------------------------------
-- Function Name : TSL_COPY_UK_ITEM_ATTRIB
-- Purpose       : If item has only ROI record then it will create dummy UK record.
---------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_UK_ITEM_ATTRIB (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_item           IN     ITEM_MASTER.ITEM%TYPE,
                                  I_country        IN     VARCHAR2)
   RETURN BOOLEAN IS

   L_program          VARCHAR2(300) := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_UK_ITEM_ATTRIB';
   L_from_country     VARCHAR2(1);
   L_to_country       VARCHAR2(1);
   -- DefNBS023046g, 28-Jun-2011, Praveen R, Begin
   L_return           NUMBER;
   L_id               NUMBER(15);
   L_item             NUMBER;
   RECORD_LOCKED      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(RECORD_LOCKED, -20001);
   -- DefNBS023046g, 28-Jun-2011, Praveen R, End

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_item,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_country is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'COUNTRY : '||I_country,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_country = 'U' then
      L_from_country := 'U';
      L_to_country   := 'R';
   elsif I_country = 'R' then
      L_from_country := 'R';
      L_to_country   := 'U';
   end if;
   ---
   -- DefNBS023046g, 28-Jun-2011, Praveen R, Begin
   -- Calling dbms_utility.get_hash_value function instead L_id variable
   L_return := DBMS_LOCK.REQUEST(dbms_utility.get_hash_value(name => I_item,
                                                             base => 1,
                                                             hash_size => power(2,30)),
                                 6,1,true);
   if L_return != 0 then
      dbms_output.put_line(L_return);
      raise RECORD_LOCKED;
   end if;
   -- DefNBS023046g, 28-Jun-2011, Praveen R, End
   ---

   SQL_LIB.SET_MARK('INSERT',
                    NULL,
                    'ITEM_ATTRIBUTES',
                    'ITEM: ' ||I_item);
   ---
   insert into item_attributes (item,
                                tsl_daily_shelf_life_mon,
                                tsl_daily_shelf_life_tue,
                                tsl_daily_shelf_life_wed,
                                tsl_daily_shelf_life_thu,
                                tsl_daily_shelf_life_fri,
                                tsl_daily_shelf_life_sat,
                                tsl_daily_shelf_life_sun,
                                tsl_min_life_depot_days,
                                tsl_min_cus_storage_days,
                                tsl_tarif_code,
                                tsl_supp_unit,
                                tsl_event,
                                tsl_process_type,
                                tsl_case_type,
                                tsl_package_type,
                                tsl_brand,
                                tsl_country_of_origin,
                                tsl_in_store_shelf_life_days,
                                tsl_sell_by_type,
                                tsl_supp_country,
                                tsl_in_store_shelf_life_ind,
                                tsl_drained_ind,
                                tsl_brand_ind,
                                tsl_sell_by_100g_ind,
                                tsl_case_per_pack,
                                tsl_high_value_ind,
                                tsl_supp_non_del_days_mon_ind,
                                tsl_supp_non_del_days_tue_ind,
                                tsl_supp_non_del_days_wed_ind,
                                tsl_supp_non_del_days_thu_ind,
                                tsl_supp_non_del_days_fri_ind,
                                tsl_supp_non_del_days_sat_ind,
                                tsl_supp_non_del_days_sun_ind,
                                tsl_weee_ind,
                                --MrgNBS300712(merge from .5b to PrdSi), Swetha Prasad,swetha.prasad@in.tesco.com, 31-Jul-2012, Begin
                                --MrgNBS024095(merge from 3.6 to 3.5b), Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 28-Dec-2011, Begin
                                -- CR281, 05-Aug-2011, Deepak Gupta, deepak.c.gupta@in.tesco.com, Begin
                                tsl_prf_value,
                                -- CR281, 05-Aug-2011, Deepak Gupta, deepak.c.gupta@in.tesco.com, End
                                --MrgNBS024095(merge from 3.6 to 3.5b), Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 28-Dec-2011, End
                                --MrgNBS300712(merge from .5b to PrdSi), Swetha Prasad,swetha.prasad@in.tesco.com, 31-Jul-2012, End
                                tsl_local_sourced,
                                tsl_base_label_size_ind,
                                tsl_pwdtu_ind,
                                tsl_low_lvl_code,
                                tsl_low_lvl_seq_no,
                                tsl_country_id,
                                --02-Aug-2011   TESCO HSC/Ankush   CR432   Begin
                                tsl_multipack_qty
                                --02-Aug-2011   TESCO HSC/Ankush   CR432   End
                                )
                        (select I_item,
                                tsl_daily_shelf_life_mon,
                                tsl_daily_shelf_life_tue,
                                tsl_daily_shelf_life_wed,
                                tsl_daily_shelf_life_thu,
                                tsl_daily_shelf_life_fri,
                                tsl_daily_shelf_life_sat,
                                tsl_daily_shelf_life_sun,
                                tsl_min_life_depot_days,
                                tsl_min_cus_storage_days,
                                tsl_tarif_code,
                                tsl_supp_unit,
                                tsl_event,
                                tsl_process_type,
                                tsl_case_type,
                                tsl_package_type,
                                tsl_brand,
                                tsl_country_of_origin,
                                tsl_in_store_shelf_life_days,
                                tsl_sell_by_type,
                                tsl_supp_country,
                                tsl_in_store_shelf_life_ind,
                                tsl_drained_ind,
                                tsl_brand_ind,
                                tsl_sell_by_100g_ind,
                                tsl_case_per_pack,
                                tsl_high_value_ind,
                                tsl_supp_non_del_days_mon_ind,
                                tsl_supp_non_del_days_tue_ind,
                                tsl_supp_non_del_days_wed_ind,
                                tsl_supp_non_del_days_thu_ind,
                                tsl_supp_non_del_days_fri_ind,
                                tsl_supp_non_del_days_sat_ind,
                                tsl_supp_non_del_days_sun_ind,
                                tsl_weee_ind,
                                --MrgNBS300712(merge from .5b to PrdSi), Swetha Prasad,swetha.prasad@in.tesco.com, 31-Jul-2012, Begin
                                --MrgNBS024095(merge from 3.6 to 3.5b), Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 28-Dec-2011, Begin
                                -- CR281, 05-Aug-2011, Deepak Gupta, deepak.c.gupta@in.tesco.com, Begin
                                tsl_prf_value,
                                -- CR281, 05-Aug-2011, Deepak Gupta, deepak.c.gupta@in.tesco.com, End
                                --MrgNBS024095(merge from 3.6 to 3.5b), Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 28-Dec-2011, End
                                --MrgNBS300712(merge from .5b to PrdSi), Swetha Prasad,swetha.prasad@in.tesco.com, 31-Jul-2012, End
                                tsl_local_sourced,
                                tsl_base_label_size_ind,
                                tsl_pwdtu_ind,
                                tsl_low_lvl_code,
                                tsl_low_lvl_seq_no,
                                L_to_country,
                                --02-Aug-2011   TESCO HSC/Ankush   CR432   Begin
                                tsl_multipack_qty
                                --02-Aug-2011   TESCO HSC/Ankush   CR432   End
                          from  item_attributes
                         where  item = I_item
                           and  tsl_country_id = L_from_country
                           and  NOT exists (select 'x'
                                              from item_attributes ia
                                             where item = I_item
                                               and tsl_country_id = L_to_country));
   ---
   return TRUE;
   ---
EXCEPTION
  -- DefNBS023046g, 28-Jun-2011, Praveen R, Begin
  when RECORD_LOCKED then
    O_error_message := SQL_LIB.CREATE_MSG('RTK_ATTR_LOCKED',
                                          NULL,
                                          NULL,
                                          NULL);
       return FALSE;
  -- DefNBS023046g, 28-Jun-2011, Praveen R, End
  when OTHERS then
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
    return FALSE;
END TSL_COPY_UK_ITEM_ATTRIB;
---------------------------------------------------------------------------------------------
-- DefNBS017627, 26-May-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
---------------------------------------------------------------------------------------------
-- 01-Jun-10    JK    MrgNBS017783   End
---------------------------------------------------------------------------------------------
-- DefNBS017627, 26-May-2010, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
---------------------------------------------------------------------------------------------
-- 01-Jun-10    JK    MrgNBS017783   End
----------------------------------------------------------------------------------------------------
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
-- 21-Jun-2010, Sripriya,Sripriya.karanam@in.tesco.com, CR347, Begin
----------------------------------------------------------------------------------------------------
--Function : TSL_GET_CODE_TYPE
--Purpose  : This function fetches the code_type for the codes 'TSBE','TSBO','NTBE','NTBO'.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_CODE_TYPE(O_error_message  IN OUT VARCHAR2,
                           O_code_type      IN OUT CODE_DETAIL.CODE_TYPE%TYPE,
                           I_code           IN     CODE_DETAIL.CODE%TYPE)
   return BOOLEAN is
   ---
   L_program        VARCHAR2(64) := 'ITEM_ATTRIB_SQL.TSL_GET_CODE_TYPE';
   ---
   CURSOR C_GET_CODE_TYPE is
   select cd.code_type
     from code_detail cd
    where cd.code   = upper(I_code)
      and cd.code_type in ('TSBE','TSBO','NTBE','NTBO');
BEGIN
   ---
   if I_code is NOT NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_get_code_type',
                       'CODE_DETAIL',
                       'Code = '||I_code);
      open C_GET_CODE_TYPE;
      SQL_LIB.SET_MARK('FETCH',
                       'C_get_code_type',
                       'CODE_DETAIL',
                       'Code = '||I_code);
      fetch C_GET_CODE_TYPE into O_code_type;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_get_code_type',
                       'CODE_DETAIL',
                       'Code = '||I_code);
      close C_GET_CODE_TYPE;
      return TRUE;
   else
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_code',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_GET_CODE_TYPE;
--------------------------------------------------------------------------
-- 21-Jun-2010, Sripriya,Sripriya.karanam@in.tesco.com, CR347, End
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
----------------------------------------------------------------------------
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
-- 03-Sep-2010, Sripriya,Sripriya.karanam@in.tesco.com, DefNBS018975, Begin
----------------------------------------------------------------------------
--Function : TSL_COUNT_ITEMNUMTYPE
--Purpose  : This function fetches the count of tesco branded and Non tesco branded items under
--           an item_parent.
----------------------------------------------------------------------------------------------------
FUNCTION TSL_COUNT_ITEMNUMTYPE(O_error_message  IN OUT VARCHAR2,
                               O_count_tb       IN OUT NUMBER,
                               O_count_ntb      IN OUT NUMBER,
                               I_item           IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is
   ---
   L_program        VARCHAR2(64) := 'ITEM_ATTRIB_DEFAULT_SQL.TSL_COUNT_ITEMNUMTYPE';
   L_item_num       VARCHAR2(25);
   L_exists         BOOLEAN;
   L_code_type      CODE_DETAIL.CODE_TYPE%TYPE;
   ---
   CURSOR C_child_itemnum is
   select item_number_type
     from item_master
    where item_parent = I_item
    --28-Sep-2010 Tesco HSC/Usha Patil           DefNBS019277 Begin
      and NOT(item_number_type = 'TPNB'
          and simple_pack_ind = 'N'
          and pack_ind = 'Y');
    --28-Sep-2010 Tesco HSC/Usha Patil           DefNBS019277 End
BEGIN
   O_count_tb := 0;
   O_count_ntb := 0;

   for C_rec in  C_child_itemnum  LOOP
      if ITEM_ATTRIB_DEFAULT_SQL.TSL_GET_CODE_TYPE(O_error_message,
                                                   L_code_type,
                                                   c_rec.Item_Number_Type) = FALSE then
         return FALSE;
      end if;

      if L_code_type in ('TSBE','TSBO') then
         O_count_tb  := O_count_tb +1;
      elsif L_code_type in ('NTBE','NTBO') then
         O_count_ntb := O_count_ntb +1;
      end if;
   end loop;
   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_COUNT_ITEMNUMTYPE;
--------------------------------------------------------------------------
-- 03-Sep-2010, Sripriya,Sripriya.karanam@in.tesco.com, DefNBS018975, End
-- 16-Sep-2010, MrgNBS019188, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
--------------------------------------------------------------------------

END;
/

