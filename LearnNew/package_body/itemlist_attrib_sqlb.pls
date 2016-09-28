CREATE OR REPLACE PACKAGE BODY ITEMLIST_ATTRIB_SQL AS
-------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    20-Feb-2008
-- Mod Ref:     ModN115,116,117
-- Mod Details: New function TSL_ITEMLIST_CHK_FIXEDMARGIN has been added.
-------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    09-Jun-2008
-- Mod Ref:     ModN32
-- Mod Details: New function TSL_GET_COMM_EXIST has been added.
-------------------------------------------------------------------------------
-- Mod By      :Satish B.N satish.narasimhaiah@in.tesco.com
-- Mod Date    :30-July-2008
-- Mod Ref     :Mod number. N153
-- Mod Details :Added GET_ITEMLIST_ITEMS to get all the items from the
--              itemlist
-------------------------------------------------------------------------------
-- Modified by :Nitin Kumar, nitin.kumar@in.tesco.com
-- Date        :27-Apr-2009
-- Defect Id   :NBS00012501
-- Desc        :Added one new function GET_SP_EXIST for checking that if Item
--              List has non-simple pack items.
-------------------------------------------------------------------------------
-- Modified by :Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        :16-Nov-2009
-- Defect Id   :CR208
-- Desc        :Added new functions TSL_GET_CUSTOM_CODE_DESC,TSL_IS_NUMBER,
--              TSL_DEL_VALUE_TEMP,TSL_VALIDATE_UPD_DATA,TSL_MASS_APPROVE,
--              TSL_GET_MERCH_DEPT for the Itemlist mass approve.
-------------------------------------------------------------------------------
-- Modified by :Vinod Patalappa,vinod.patalappa@in.tesco.com
-- Date        :08-Dec-2009
-- Defect Id   :DefNBS015668
-- Desc        :Modified the function TSL_VALIDATE_UPD_DATA.
-------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 10-Dec-2009
-- Mod Ref    : DefNBS015675
-- Mod Details: Modified the function TSL_MASS_APPROVE to handle the Mass
--              approval of Itemlist.
-------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 10-Dec-2009
-- Mod Ref    : DefNBS015664/DefNBS015700
-- Mod Details: Added a new function TSL_VALIDATE_DATA.
-------------------------------------------------------------------------------
-- Modified by :Vinod Patalappa, vinod.patalappa@in.tesco.com
-- Date        :10-Dec-2009
-- Defect Id   :NBS00015640
-- Desc        :1.Modified the function TSL_VALIDATE_UPD_DATA, added a
--                new parameter..
--              2.Add one new cursor to fetch the TSL_COUNTRY_ID for the
--                parent table.
-------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 15-Dec-2009
-- Mod Ref    : DefNBS015640
-- Mod Details: Added a new function TSL_CREATE_ITEMLIST to do the security check
--              and then to create a new Itemlist.
-------------------------------------------------------------------------------
-- Mod By     : Vinod Patalappa, vinod.patalappa@in.tesco.com
-- Mod Date   : 19-Dec-2009
-- Mod Ref    : DefNBS015722
-- Mod Details: Added a new function TSL_CASCADE_VALUES to cascade the values
--              to its child item.
-------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 22-Dec-2009
-- Mod Ref    : DefNBS015736
-- Mod Details: Modified the function TSL_CREATE_ITEMLIST.
-------------------------------------------------------------------------------
-- Mod By     : Vinod Patalappa, vinod.patalappa@in.tesco.com
-- Mod Date   : 29-Dec-2009
-- Mod Ref    : DefNBS015875
-- Mod Details: Modified the function TSL_VALIDATE_UPD_DATA to validate the
--              item_desc_secondary value.
-------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 15-Jan-2010
-- Mod Ref    : DefNBS00015930
-- Mod Details: Modified the function TSL_VALIDATE_UPD_DATA,TSL_VALIDATE_DATA.
-------------------------------------------------------------------------------
-- Mod By     : Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 20-Jan-2010
-- Mod Ref    : DefNBS00015979
-- Mod Details: In TSL_MASS_APPROVE Function, new condition added to not call
--              the SUBMIT Function for the already Approved Level1/TPNA items.
-------------------------------------------------------------------------------
-- Mod By     : Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 21-Jan-2010
-- Mod Ref    : DefNBS00016008
-- Mod Details: In TSL_CREATE_ITEMLIST Function, new condition added to not add
--              EANs and OCC in the item list and they will be moved to Rejected
--              list of items.
-------------------------------------------------------------------------------
--- Mod By   : Tarun Kumar Mishra tarun.mishra@in.tesco.com
--- Mod Date : 22-Jan-2010
--- Mod Ref  : NBS00015897
--- Mod Desc : Modified the function TSL_VALIDATE_UPD_DATA
-------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 08-Feb-2010
-- Mod Ref    : DefNBS016127
-- Mod Details: Modified the function TSL_VALIDATE_UPD_DATA.
---------------------------------------------------------------------------------
-- Mod By     : Raghuveer P R
-- Mod Date   : 10-Feb-2010
-- Mod Ref    : DefNBS016121
-- Mod Details: Modified the function TSL_MASS_APPROVE. Added the missing
--              parantheses for the and/or conditions.
---------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 26-Feb-2010
-- Mod Ref    : DefNBS016023
-- Mod Details: To handle the new date format(Design updation).
--              1.Modified the function TSL_VALIDATE_UPD_DATA.
--              2.Modified the function TSL_VALIDATE_DATA.
--              3.Added a new function TSL_VALIDATE_DATATYPE.
---------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 02-Mar-2010
-- Defect Id   : DefNBS016380
-- Desc        : Modified the function TSL_VALIDATE_UPD_DATA, added a new
--               parameter.
-----------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 04-Mar-2010
-- Defect Id   : DefNBS016143
-- Desc        : Modified the function TSL_VALIDATE_UPD_DATA to handle low level
--               code specifically.
-------------------------------------------------------------------------------------
-- Modified by : Sripriya, Sripriya.karanam@in.tesco.com
-- Date        : 18-Mar-2010
-- Defect Id   : DefNBS016539
-- Desc        : To handle the brand indicator code specifically
--               1. Modified the function TSL_VALIDATE_UPD_DATA.
--               2. Modified the function TSL_CASCADE_VALUES.
--               3. Added a new function TSL_MASS_ITEM_CHANGE_CHECK.
-----------------------------------------------------------------------------------
-- Modified by : Sripriya, Sripriya.karanam@in.tesco.com
-- Date        : 18-Mar-2010
-- Defect Id   : DefNBS016385
-- Desc        : To handle the foreign key constraint errors.
-----------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 01-Apr-2010
-- Mod Ref    : DefNBS016596
-- Mod Details: Modified the function TSL_CREATE_ITEMLIST.
-------------------------------------------------------------------------------
-- Modified by : Shireen, shireen.sheosunker@uk.tesco.com
-- Date        : 29-Mar-2010
-- Defect Id   : DefNBS016865
-- Desc        : Added a new function TSL_GET_RESTRICTIONS_CODE_DESC to get the
--               code desc from tsl_rest_fields table.
-----------------------------------------------------------------------------------
-- Modified by : Shireen Sheosunker, shireen.sheosunker@uk.tesco.com
-- Date        : 07-Apr-2010
-- Defect Id   : DefNBS016916
-- Desc        : Added new function TSL_GET_RESTRICTIONS_CODE_DESC to get code/desc from tsl_rest_fields.
--             : Added new function TSL_VALIDATE_UPD_DATA_RESTRICT for tsl_rest_fields.
--             : Added new function TSL_VALIDATE_DATATYPE_RESTRICT for tsl_rest_fields.
-----------------------------------------------------------------------------------------------------
-- Mod By     : JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 08-Apr-10
-- Mod Ref    : MrgNBS016979
-- Mod Details: Added a new functions TSL_GET_RESTRICTIONS_CODE_DESC, TSL_VALIDATE_UPD_DATA_RESTRICT
--              and TSL_VALIDATE_DATATYPE_RESTRICT.
----------------------------------------------------------------------------------------------------
-- Mod By     : Sripriya, sripriya.karanam@in.tesco.com
-- Mod Date   : 15-Apr-2010
-- Mod Ref    : DefNBS016385
-- Mod Details: 1.Added a new function TSL_VALIDATE to validate the default Pref Pack for the associated TPNB
--              2.Modified the function TSL_MASS_ITEM_CHANGE_CHECK.
------------------------------------------------------------------------------------------------------------
-- Mod By     : shweta.madnawat@in.tesco.com
-- Mod Date   : 15-Apr-2010
-- Mod Ref    : DefNBS017055
-- Mod Details: Updated the call to error message with proper format and parameters.
------------------------------------------------------------------------------------------------------------
--Mod By:      Chandru, chandrashekaran.natarajan@in.tesco.com
--Mod Date:    22-Apr-2010
--Mod Ref:     CR258
--Mod Details: Modified the TSL_CASCADE_VALUES function toimplement the cascading functionality
------------------------------------------------------------------------------------------------------------
-- Mod By     : shireen.sheosunker@uk.tesco.com
-- Mod Date   : 22-Apr-2010
-- Mod Ref    : DefNBS017079
-- Mod Details: Updated TSL_VALIDATE_UPD_DATA_RESTRICT to update the tsl_end_date for mass change on EPW
------------------------------------------------------------------------------------------------------------
-- Mod By     : Sripriya, sripriya.karanam@in.tesco.com
-- Mod Date   : 29-Apr-2010
-- Mod Ref    : DefNBS017246
-- Mod Details: Modified the functions TSL_GET_CUSTOM_CODE_DESC , TSL_VALIDATE_UPD_DATA.
-------------------------------------------------------------------------------------------------------------
--Mod By:      Murali N, murali.natarajan@in.tesco.com
--Mod Date:    17-May-2010
--Mod Ref:     CR288b
--Mod Details: Modified Function TSL_MASS_APPROVE to cann function to update TSL_COUNTRY_AUTH_IND after aproval.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 01-Jun-2010
-- Mod Ref    : MrgNBS017783(Merge 3.5b to 3.5f).
-- Mod Details: Merged DefNBS016385,DefNBS017055,DefNBS017079,DefNBS017246,CR288b
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 04-Aug-2010
-- Mod Ref    : PrfNBS018117
-- Mod Details: Modified the entire function TSL_VALIDATE_DATA.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Phil Noon
-- Mod Date   : 06-Aug-2010
-- Mod Ref    : DefNBS017227
-- Mod Details: Added the function TSL_MASS_UPDATE_ITEM_CTRY.
-------------------------------------------------------------------------------------------------------------
-- Mod By     : Rajendra B
-- Mod Date   : 31-Aug-2010
-- Mod Ref    : Mrg0NBS18918
-- Mod Details: Added the Comment as part of the merge from 3.5f to 3.5g
--------------------------------------------------------------------------------------------------------------
-- Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Date   : 16-Sep-2010
-- Mod Ref    : MrgNBS019188, Merge from 3.5g to 3.5b
-- Mod Details: Added Rajendra's header comments dated 31st Aug 2010
--------------------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 09-Aug-2010
-- Mod Ref    : CR354
-- Mod Details: Added a new function TSL_SHARED_ITEM_EXISTS.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 18-Aug-2010
-- Mod Ref    : CR354
-- Mod Details: Modified TSL_MASS_APPROVE function.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Sripriya,Sripriya.karanam@in.tesco.com
-- Mod Date   : 17-Sep-2010
-- Mod Ref    : DefNBS019211
-- Mod Details: Modified the TSL_CASCADE_VALUES to implement cascading functionality for Style Ref code.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Date   : 20-Sep-2010
-- Mod Ref    : MrgNBS019220, Merge from 3.5f3 to 3.5b
-- Mod Details: Merged changes for CR354 and DefNBS019211
-------------------------------------------------------------------------------------------------------
-- Mod By     : JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 23-Sep-2010
-- Mod Ref    : PrfNBS019234
-- Mod Details: Modified the queries which are using USER_TAB_COLUMNS table to improve the performance.
-----------------------------------------------------------------------------------------------------
--Mod By:      Praveen,praveen.rachaputi@in.tesco.com
--Mod Date:    21-Sep-2010
--Mod Ref:     PrfNBS018117d
--Mod Details: Modified TSL_CASCADE_VALUES function to include bind varibales
-----------------------------------------------------------------------------------------------------
--Mod By:      Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com
--Mod Date:    11-Nov-2010
--Mod Ref:     CR332
--Mod Details: This new function TSL_VALID_STYLE_REF_CODE_SEC validates the user security to access
--              the items in the Style Ref Code
-----------------------------------------------------------------------------------------------------
-- Mod By     : Sripriya,sripriya.karanam@in.tesco.com
-- Mod Date   : 05-Jan-2011
-- Mod Ref    : DefNBS020397
-- Mod Details: Added two new functions TSL_INS_PREF_PACK ,TSL_INS_WH_ORDER .
----------------------------------------------------------------------------------------------------
-- Mod By     : Deepak Gupta, deepak.c.gupta@in.tesco.com
-- Mod Date   : 14-Feb-2011
-- Mod Ref    : DefNBS021480
-- Mod Details: Added a new function TSL_CASCADE_VALUES_DEACT_RULE to cascade the values
--              to its child item.
-------------------------------------------------------------------------------
-- Mod By     : Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com
-- Mod Date   : 11-Mar-2011
-- Mod Ref    : DefNBS021885
-- Mod Desc   : Change the I_itemlist parameter data type to skulist_detail.item for
--              function TSL_MASS_ITEM_CHANGE_CHECK

-- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
--------------------------------------------------------------------------------------
-- Mod By     : Praveen Rachaputi
-- Mod Date   : 18-Mar-2011
-- Mod Ref    : DefNBS021971
-- Mod Desc   : Modified functions TSL_INS_WH_ORDER,TSL_INS_PREF_PACK to default effective_date to
--              vdate +1 instead of vdate
--------------------------------------------------------------------------------------
-- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
----------------------------------------------------------------------------------------------------
-- Mod By:      Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date:    14-Apr-2011
-- Def Ref:     PrfNBS022237
-- Def Details: Modified the functions TSL_CASCADE_VALUES,TSL_VALIDATE_UPD_DATA,COPY_DOWN_PARENT_ATTRIB
--              and TSL_VALIDATE_UPD_DATA_RESTRICT to improve the performance of Mass itemlist upload.
----------------------------------------------------------------------------------------------------
-- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
-- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End

-- Mod By     : Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com
-- Mod Date   : 21-Apr-2011
-- Mod Ref    : MrgNBS022379
-- Mod Desc   : Merge from PrdSi to 3.5b branches
--------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Mod By   : Iman, iman.chatterjee@in.tesco.com
-- Mod Date : 04-May-2011
-- Def Ref  : MrgNBS022413
----------------------------------------------------------------------------------------------------
-- Mod By:      Praveen Rachaputi
-- Mod Date:    23-Jun-2011
-- Def Ref:     DefNBS023046
-- Def Details: Modified the functions TSL_CASCADE_VALUES,TSL_VALIDATE_UPD_DATA,COPY_DOWN_PARENT_ATTRIB
--              and TSL_VALIDATE_UPD_DATA_RESTRICT to improve the performance of Mass itemlist upload.
----------------------------------------------------------------------------------------------------
-- Mod By    :  shweta.madnawat@in.tesco.com
-- Mod Date  :  25-Oct-2011
-- Def Ref   :  CR434
-- Def Details: Modified functions TSL_CASCADE_VALUES and TSL_VALIDATE_UPD_DATA for CR434, to allow
--              mass update of restrict pricec event indicator in item_master table.
----------------------------------------------------------------------------------------------------
-- Mod By    :  Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date  :  13-Nov-2011
-- Def Ref   :  CR434
-- Def Details: Modified functions TSL_MASS_ITEM_CHANGE_CHECK for CR434.
----------------------------------------------------------------------------------------------------
-- Mod By    :  Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date  :  23-Nov-2011
-- Def Ref   :  DefNBS023976
-- Def Details: Modified functions TSL_VALIDATE_UPD_DATA to update the ITEM_MASTER table only for
--              TPNB and VAR items.
----------------------------------------------------------------------------------------------------
-- Mod By    :  Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date  :  24-Nov-2011
-- Def Ref   :  DefNBS023974
-- Def Details: Modified cursor C_SUBCLASS_IND of functions TSL_VALIDATE_UPD_DATA.
----------------------------------------------------------------------------------------------------
-- Mod By    :  Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date  :  07-Dec-2011
-- Def Ref   :  DefNBS024002
-- Def Details: Modified functions TSL_VALIDATE_UPD_DATA as per design change.
----------------------------------------------------------------------------------------------------
-- Mod By    :  Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date  :  30-Dec-2011
-- Def Ref   :  DefNBS024052
-- Def Details: Modified functions TSL_VALIDATE_UPD_DATA to update the :AST_UPDATE_ID column
--              of ITEM_MASTER table.
----------------------------------------------------------------------------------------------------
-- Mod By    :  Swetha Prasad, swetha.prasad@in.tesco.com
-- Mod Date  :  27-Feb-2012
-- Def Ref   :  DefNBS024254
-- Def Details: Modified function TSL_INS_WH_ORDER to get the Dist Type for LEVEL1,LEVEL2 and Ratio pack items
--                to handle the WH orderability updation through itemlists.
----------------------------------------------------------------------------------------------------
-- Mod By    :  Swetha Prasad, swetha.prasad@in.tesco.com
-- Mod Date  :  29-Feb-2012
-- Def Ref   :  DefNBS024390
-- Def Details: Modified function TSL_MASS_ITEM_CHANGE_CHECK to handle the Def Pref Pack changes for itemlists.
----------------------------------------------------------------------------------------------------
-- Mod By     : Vinutha R, vinutha.raju@in.tesco.com
-- Mod Date   : 08-Oct-2012
-- Mod Ref    : DefNBS025514/PM017007
-- Mod Desc   : MODIFIED the function TSL_CASCADE_VALUES to avoid launch date getting cascaded
--              from base to variant.
--------------------------------------------------------------------------------------
--Mod By:      Niraj C nirajkumar.choudhary@in.tesco.com
--Mod Date:    04-Mar-2014
--Mod Ref:     CR399
--Mod Details: To incorporate the CR399 changes to insert the record in tsl_item_min_price
--             table when submit/Approve.
--------------------------------------------------------------------------------------------
-- Mod By     : Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com
-- Mod Date   : 11-Nov-2013
-- Mod Ref    : PM020648
-- Mod Desc   : MODIFIED the function TSL_CASCADE_VALUES and TSL_CASCADE_VALUES_DEACT_RULE to exclude cascading.
----------------------------------------------------------------------------------------------------

FUNCTION TSL_CASCADE_VALUES (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_tsl_parent_table IN       VARCHAR2,
                             I_column_name      IN       VARCHAR2,
                             I_value            IN       VARCHAR2,
                             I_item             IN       ITEM_MASTER.ITEM%TYPE,
                             I_country_id       IN       VARCHAR2,
                             --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
                             I_code_type        IN       VARCHAR2,
                             --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
                             -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                             -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                             -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                             I_login_ctry     IN      VARCHAR2
                             -- 14-Apr-11     Nandini M     PrfNBS022237     End
                             -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                             -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                             )

   RETURN BOOLEAN;
-------------------------------------------------------------------------------
-- Mod By     : shireen.sheosunker@uk.tesco.com
-- Mod Date   : 30-Apr-2010
-- Mod Ref    : DefNBS017261
-- Mod Details: Updated TSL_CASCADE_VALUES to cascade EPW for packs children below TPNB level
------------------------------------------------------------------------------------------------------------
-- DefNBS021480, 14-Feb-2011, Deepak Gupta, deepak.c.gupta@in.tesco.com (Begin)
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_CASCADE_VALUES_DEACT_RULE (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                        I_tsl_parent_table IN       VARCHAR2,
                                        I_column_name      IN       VARCHAR2,
                                        I_value            IN       VARCHAR2,
                                        I_item             IN       ITEM_MASTER.ITEM%TYPE,
                                        I_country_id       IN       VARCHAR2,
                                        I_code_type        IN       VARCHAR2,
                                        I_deact_pack       IN       VARCHAR2)
   RETURN BOOLEAN;
------------------------------------------------------------------------------------------------------------
-- DefNBS021480, 14-Feb-2011, Deepak Gupta, deepak.c.gupta@in.tesco.com (End)
------------------------------------------------------------------------------------------------------------
FUNCTION GET_NAME (O_error_message   IN OUT   VARCHAR2,
                   I_itemlist        IN       NUMBER,
                   O_list_name       IN OUT   VARCHAR2)

   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.GET_NAME';
   L_skulist_desc  SKULIST_HEAD.SKULIST_DESC%TYPE;
   ---
   cursor C_SKULIST is
      select skulist_desc
        from skulist_head
       where skulist = I_itemlist;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_SKULIST',
                    'SKULIST_HEAD',
                    to_char(I_itemlist));
   open C_SKULIST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_SKULIST',
                    'SKULIST_HEAD',
                    to_char(I_itemlist));
   fetch C_SKULIST into L_skulist_desc;
   if C_SKULIST%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_LIST',
                                            NULL,
                                            NULL,
                                            NULL);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SKULIST',
                       'SKULIST_HEAD',
                       to_char(I_itemlist));
      close C_SKULIST;
      return FALSE;
   else
      O_list_name := L_skulist_desc;
   end if;
   close C_SKULIST;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_list_name,
                             O_list_name,
                             O_error_message) = FALSE then
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
END GET_NAME;
--------------------------------------------------------------------
FUNCTION GET_ITEM_COUNT(O_error_message    IN OUT    VARCHAR2,
                        I_itemlist         IN        SKULIST_HEAD.SKULIST%TYPE,
                        O_count            IN OUT    NUMBER)
   RETURN BOOLEAN IS

   L_program  VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.GET_ITEM_COUNT';
   ---
   cursor C_COUNT is
      select count(*)
        from skulist_detail
       where skulist = I_itemlist;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_COUNT',
                    'SKULIST_DETAIL',
                    to_char(I_itemlist));
   open C_COUNT;
   SQL_LIB.SET_MARK('FETCH',
                    'C_COUNT',
                    'SKULIST_DETAIL',
                    to_char(I_itemlist));
   fetch C_COUNT into O_count;
   if C_COUNT%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_COUNT',
                       'SKULIST_DETAIL',
                       to_char(I_itemlist));
      close C_COUNT;
      O_error_message := SQL_LIB.CREATE_MSG('INV_SKU_LIST',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   else
      SQL_LIB.SET_MARK('CLOSE',
                       'C_COUNT',
                       'SKULIST_DETAIL',
                       to_char(I_itemlist));
      close C_COUNT;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ITEM_COUNT;
---------------------------------------------------------------------
FUNCTION GET_DEPOSIT_ITEM_COUNT(O_error_message   IN OUT   VARCHAR2,
                                I_itemlist        IN       SKULIST_HEAD.SKULIST%TYPE,
                                I_deposit_type    IN       ITEM_MASTER.DEPOSIT_ITEM_TYPE%TYPE,
                                O_count           IN OUT   NUMBER)
   RETURN BOOLEAN IS

   L_program  VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.GET_DEPOSIT_ITEM_COUNT';
   ---
   cursor C_COUNT is
      select count( im.item )
        from item_master    im,
             skulist_detail sd
       where im.deposit_item_type = I_deposit_type
         and im.item              = sd.item
         and sd.skulist           = I_itemlist;

BEGIN
   O_count := 0;

   SQL_LIB.SET_MARK('OPEN',
                    'C_COUNT',
                    'SKULIST_DETAIL, ITEM_MASTER',
                    'skulist = ' || to_char(I_itemlist) || ', deposit_item_type = ' || I_deposit_type );
   open C_COUNT;

   SQL_LIB.SET_MARK('FETCH',
                    'C_COUNT',
                    'SKULIST_DETAIL, ITEM_MASTER',
                    'skulist = ' || to_char(I_itemlist) || ', deposit_item_type = ' || I_deposit_type );
   fetch C_COUNT into O_count;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_COUNT',
                    'SKULIST_DETAIL, ITEM_MASTER',
                    'skulist = ' || to_char(I_itemlist) || ', deposit_item_type = ' || I_deposit_type );
   close C_COUNT;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_DEPOSIT_ITEM_COUNT;
---------------------------------------------------------------------
FUNCTION GET_HEADER_INFO(O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_skulist_desc            IN OUT   SKULIST_HEAD.SKULIST_DESC%TYPE,
                         O_create_date             IN OUT   SKULIST_HEAD.CREATE_DATE%TYPE,
                         O_last_rebuild_date       IN OUT   SKULIST_HEAD.LAST_REBUILD_DATE%TYPE,
                         O_create_id               IN OUT   SKULIST_HEAD.CREATE_ID%TYPE,
                         O_static_ind              IN OUT   SKULIST_HEAD.STATIC_IND%TYPE,
                         O_comment_desc            IN OUT   SKULIST_HEAD.COMMENT_DESC%TYPE,
                         O_tax_product_group_ind   IN OUT   SKULIST_HEAD.TAX_PROD_GROUP_IND%TYPE,
                         O_filter_org_id           IN OUT   SKULIST_HEAD.FILTER_ORG_ID%TYPE,
                         I_itemlist                IN       SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN IS

   L_program  VARCHAR2(64)  := 'ITEMLIST_ATTRIB_SQL.GET_HEADER_INFO';

   ---
   cursor C_HEADER is
      select skulist_desc,
             create_date,
             last_rebuild_date,
             create_id,
             static_ind,
             comment_desc,
             tax_prod_group_ind,
             filter_org_id
        from skulist_head
       where skulist = I_itemlist;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_HEADER',
                    'SKULIST_HEAD',
                    to_char(I_itemlist));
   open C_HEADER;

   SQL_LIB.SET_MARK('FETCH',
                    'C_HEADER',
                    'SKULIST_HEAD',
                    to_char(I_itemlist));
   fetch C_HEADER into O_skulist_desc,
                       O_create_date,
                       O_last_rebuild_date,
                       O_create_id,
                       O_static_ind,
                       O_comment_desc,
                       O_tax_product_group_ind,
                       O_filter_org_id;
   if C_HEADER%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_HEADER',
                       'SKULIST_HEAD',
                       to_char(I_itemlist));
      close C_HEADER;
      O_error_message := SQL_LIB.CREATE_MSG('INV_SKU_LIST',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_HEADER',
                    'SKULIST_HEAD',
                    to_char(I_itemlist));
   close C_HEADER;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_skulist_desc,
                             O_skulist_desc,
                             O_error_message) = FALSE then
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
END GET_HEADER_INFO;
--------------------------------------------------------------------
FUNCTION GET_HEADER_INFO(O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_skulist_desc            IN OUT   SKULIST_HEAD.SKULIST_DESC%TYPE,
                         O_create_date             IN OUT   SKULIST_HEAD.CREATE_DATE%TYPE,
                         O_last_rebuild_date       IN OUT   SKULIST_HEAD.LAST_REBUILD_DATE%TYPE,
                         O_create_id               IN OUT   SKULIST_HEAD.CREATE_ID%TYPE,
                         O_static_ind              IN OUT   SKULIST_HEAD.STATIC_IND%TYPE,
                         O_comment_desc            IN OUT   SKULIST_HEAD.COMMENT_DESC%TYPE,
                         O_tax_product_group_ind   IN OUT   SKULIST_HEAD.TAX_PROD_GROUP_IND%TYPE,
                         I_itemlist                IN       SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN IS

   L_dummy_filter_id   SKULIST_HEAD.FILTER_ORG_ID%TYPE; -- arbitrary typecast used

BEGIN

   if not GET_HEADER_INFO(O_error_message,
                         O_skulist_desc,
                         O_create_date,
                         O_last_rebuild_date,
                         O_create_id,
                         O_static_ind,
                         O_comment_desc,
                         O_tax_product_group_ind,
                         L_dummy_filter_id,
                         I_itemlist) then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'ITEMLIST_ATRIB_SQL.GET_HEADER_INFO',
                                             to_char(SQLCODE));
      return FALSE;
END GET_HEADER_INFO;
----------------------------------------------------------------------------------
FUNCTION ITEM_ON_CONSIGNMENT_EXISTS(O_error_message   IN OUT   VARCHAR2,
                                    O_exists          IN OUT   BOOLEAN,
                                    I_itemlist        IN       SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN IS

   L_program    VARCHAR2(64)    := 'ITEMLIST_ATTRIB_SQL.ITEM_ON_CONSIGNMENT_EXISTS';
   L_table      VARCHAR2(64)    := 'SKULIST_DETAIL, ITEM_SUPPLIER';
   L_exists     VARCHAR2(1);
   ---
   cursor C_EXISTS is
      select /*+ INDEX(s) */
             'Y'
        from skulist_detail l, item_supplier s
       where s.item = l.item
         and l.skulist = I_itemlist
         and s.consignment_rate IS NOT NULL;
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    L_table,
                    to_char(I_itemlist));
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    L_table,
                    to_char(I_itemlist));
   fetch C_EXISTS into L_exists;
   if C_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    L_table,
                    to_char(I_itemlist));
   close C_EXISTS;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_ON_CONSIGNMENT_EXISTS;
--------------------------------------------------------------------
FUNCTION PACK_ITEM_EXISTS(O_error_message   IN OUT   VARCHAR2,
                          O_exists          IN OUT   BOOLEAN,
                          I_itemlist        IN       SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN IS

   L_program    VARCHAR2(64)    := 'ITEMLIST_ATTRIB_SQL.PACK_ITEM_EXISTS';
   L_table      VARCHAR2(64)    := 'SKULIST_DETAIL';
   L_exists     VARCHAR2(1);
   ---
   cursor C_EXISTS is
      select 'Y'
        from skulist_detail
       where skulist = I_itemlist
         and pack_ind = 'Y';
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    L_table,
                    to_char(I_itemlist));
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    L_table,
                    to_char(I_itemlist));
   fetch C_EXISTS into L_exists;
   if C_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    L_table,
                    to_char(I_itemlist));
   close C_EXISTS;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END PACK_ITEM_EXISTS;
---------------------------------------------------------------------
FUNCTION GET_ZONE_GROUP_ID(O_error_message   IN OUT  VARCHAR2,
                           I_itemlist        IN      SKULIST_HEAD.SKULIST%TYPE,
                           O_zone_group_id   IN OUT  ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.GET_ZONE_GROUP_ID';
   ---
   cursor C_GET_ZONE_GROUP_ID is
      select im.retail_zone_group_id
        from item_master im,
             skulist_detail sd
       where sd.skulist = I_itemlist
         and (sd.item = im.item
              or sd.item = im.item_parent
              or sd.item = im.item_grandparent)
         and im.retail_zone_group_id IS NOT NULL;
BEGIN
   open C_GET_ZONE_GROUP_ID;
   fetch C_GET_ZONE_GROUP_ID into O_zone_group_id;
   if C_GET_ZONE_GROUP_ID%NOTFOUND then
      O_error_message := sql_lib.create_msg('INV_LIST',
                                            NULL,
                                            NULL,
                                            NULL);
      close C_GET_ZONE_GROUP_ID;
      return FALSE;
   end if;
   close C_GET_ZONE_GROUP_ID;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ZONE_GROUP_ID;
--------------------------------------------------------------------
FUNCTION ITEM_ON_CRITERIA(O_error_message   IN OUT   VARCHAR2,
                          O_exists          IN OUT   BOOLEAN,
                          O_action_type     IN OUT   SKULIST_CRITERIA.ACTION_TYPE%TYPE,
                          I_skulist         IN       SKULIST_CRITERIA.SKULIST%TYPE,
                          I_item            IN       SKULIST_CRITERIA.ITEM%TYPE)
return BOOLEAN is

   L_program      VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.ITEM_ON_CRITERIA';
   L_action_type  SKULIST_CRITERIA.ACTION_TYPE%TYPE;

   cursor C_ITEM_EXISTS is
      select action_type
        from skulist_criteria
       where item = I_item
         and skulist = I_skulist;
BEGIN
   open C_ITEM_EXISTS;
   fetch C_ITEM_EXISTS into L_action_type;
   O_action_type := L_action_type;
   if C_ITEM_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   close C_ITEM_EXISTS;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));

      return FALSE;
END ITEM_ON_CRITERIA;
--------------------------------------------------------------------
FUNCTION CRITERIA_EXISTS(O_error_message   IN OUT   VARCHAR2,
                         O_exists          IN OUT   BOOLEAN,
                         I_skulist         IN       SKULIST_CRITERIA.SKULIST%TYPE)
   RETURN BOOLEAN IS

   L_dummy        VARCHAR2(1);
   L_program      VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.CRITERIA_EXISTS';

   cursor C_CRIT_EXISTS is
      select 'X'
        from skulist_criteria
       where skulist = I_skulist;
BEGIN
   open C_CRIT_EXISTS;
   fetch C_CRIT_EXISTS into L_dummy;
   if C_CRIT_EXISTS%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   close C_CRIT_EXISTS;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));

      return FALSE;
END CRITERIA_EXISTS;
--------------------------------------------------------------------
FUNCTION SKULIST_DEPT_EXISTS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_dept_exists     IN OUT   BOOLEAN,
                             I_itemlist        IN       SKULIST_DEPT.SKULIST%TYPE,
                             I_dept            IN       SKULIST_DEPT.DEPT%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64)   := 'ITEMLIST_ADD_SQL.SKULIST_DEPT_EXISTS';
   L_count           NUMBER(1)      := 0;

BEGIN

   select count(1)
     into L_count
     from skulist_dept
    where skulist = I_itemlist
      and dept = I_dept
      and rownum = 1;

   if L_count > 0 then
      O_dept_exists := TRUE;
   else
      O_dept_exists := FALSE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END SKULIST_DEPT_EXISTS;
----------------------------------------------------------
FUNCTION ITEM_IN_SKULIST(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         I_item            IN       SKULIST_DETAIL.ITEM%TYPE,
                         I_dept            IN       SKULIST_DEPT.DEPT%TYPE,
                         I_class           IN       SKULIST_DEPT.CLASS%TYPE,
                         I_subclass        IN       SKULIST_DEPT.SUBCLASS%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60)              := 'ITEMLIST_ATTRIB_SQL.ITEM_IN_SKULIST';
   L_skulist   SKULIST_HEAD.SKULIST%TYPE := NULL;

   cursor C_ITEM_IN_SKULIST is
      select skulist
        from skulist_detail
       where item = I_item;

BEGIN
   -- Check if required input parameter is null
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_IN_SKULIST',
                    'SKULIST_DETAIL',
                    'SKULIST: '||I_item);

   FOR rec IN C_ITEM_IN_SKULIST LOOP
      if rec.skulist is not NULL then
         if UPDATE_ITEM_LIST(O_error_message,
                             rec.skulist,
                             I_dept,
                             I_class,
                             I_subclass) = FALSE then
            return FALSE;
         end if;
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
END ITEM_IN_SKULIST;
----------------------------------------------------------
FUNCTION UPDATE_ITEM_LIST(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          I_skulist         IN       SKULIST_HEAD.SKULIST%TYPE,
                          I_dept            IN       DEPS.DEPT%TYPE,
                          I_class           IN       SKULIST_DEPT.CLASS%TYPE,
                          I_subclass        IN       SKULIST_DEPT.SUBCLASS%TYPE)
   RETURN BOOLEAN IS

   L_program VARCHAR2(60) := 'ITEMLIST_ATTRIB_SQL.UPDATE_ITEM_LIST';
   L_exist   VARCHAR2(1)  := NULL;

   cursor C_UPDATE_ITEMLIST is
      select 'x'
        from skulist_dept
       where skulist = I_skulist
         and dept = I_dept
         and class = I_class
         and subclass = I_subclass;

BEGIN
   -- Verify if required input parameters are null
   if I_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_dept',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_skulist is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_skulist',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_class is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_class',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_subclass is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_subclass',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_UPDATE_ITEMLIST',
                    'SKULIST_DEPT',
                    'SKULIST: '||to_char(I_skulist) ||
                    ', DEPT: ' ||to_char(I_dept) ||
                    ', CLASS: '||to_char(I_class) ||
                    ', SUBCLASS: '||to_char(I_subclass));
   open C_UPDATE_ITEMLIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_UPDATE_ITEMLIST',
                    'SKULIST_DEPT',
                    'SKULIST: '||to_char(I_skulist) ||
                    ', DEPT: ' ||to_char(I_dept) ||
                    ', CLASS: '||to_char(I_class) ||
                    ', SUBCLASS: '||to_char(I_subclass));

   fetch C_UPDATE_ITEMLIST into L_exist;

   if C_UPDATE_ITEMLIST%NOTFOUND then
      -- The dept does not exist, insert a new record for it
      SQL_LIB.SET_MARK('INSERT',
                       'NULL',
                       'SKULIST_DEPT',
                       'SKULIST: '||to_char(I_skulist) ||
                       ', DEPT: ' ||to_char(I_dept) ||
                       ', CLASS: '||to_char(I_class) ||
                       ', SUBCLASS: '||to_char(I_subclass));

      insert into skulist_dept(skulist,
                               dept,
                               class,
                               subclass)
                        values(I_skulist,
                               I_dept,
                               I_class,
                               I_subclass);
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                       'C_UPDATE_ITEMLIST',
                       'SKULIST_DEPT',
                       'SKULIST: '||to_char(I_skulist) ||
                       ', DEPT: ' ||to_char(I_dept) ||
                       ', CLASS: '||to_char(I_class) ||
                       ', SUBCLASS: '||to_char(I_subclass));
   close C_UPDATE_ITEMLIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;
END UPDATE_ITEM_LIST;
--------------------------------------------------------------------
FUNCTION GET_INVENTORY_ITEM_COUNT(O_error_message    IN OUT    VARCHAR2,
                                  I_itemlist         IN        SKULIST_HEAD.SKULIST%TYPE,
                                  O_count            IN OUT    NUMBER)
   RETURN BOOLEAN IS

   L_program  VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.GET_INVENTORY_ITEM_COUNT';
   ---
   cursor C_COUNT is
      select count(*)
        from skulist_detail sd,
             item_master im
       where sd.skulist       = I_itemlist
         and sd.item          = im.item
         and im.inventory_ind = 'Y';

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_COUNT',
                    'SKULIST_DETAIL',
                    to_char(I_itemlist));
   open C_COUNT;
   SQL_LIB.SET_MARK('FETCH',
                    'C_COUNT',
                    'SKULIST_DETAIL',
                    to_char(I_itemlist));
   fetch C_COUNT into O_count;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_COUNT',
                    'SKULIST_DETAIL',
                    to_char(I_itemlist));
   close C_COUNT;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_INVENTORY_ITEM_COUNT;
----------------------------------------------------------------------------------------------------
-- Begin ModN115,116,117 Wipro/JK 20-Feb-2008
----------------------------------------------------------------------------------------------------
-- Function : TSL_ITEMLIST_CHK_FIXEDMARGIN
-- Purpose  : To check the given itemlist belongs to  fixed margin subclass
----------------------------------------------------------------------------------------------------
FUNCTION TSL_ITEMLIST_CHK_FIXEDMARGIN(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                      O_flg           IN OUT VARCHAR2,
                                      I_item_list     IN     SKULIST_DETAIL.SKULIST%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program       VARCHAR2(50)    := 'ITEMLIST_ATTRIB_SQL.TSL_ITEMLIST_CHK_FIXEDMARGIN';
   ---
   cursor C_CHK_SKULIST  is
      select 'Y'
        from skulist_detail skd,
             item_master iem,
             subclass scl
       where scl.tsl_fixed_margin is not null
         and iem.dept = scl.dept
         and iem.class = scl.class
         and iem.subclass = scl.subclass
         and iem.item = skd.item
         and skd.skulist = I_item_list
         and rownum = 1;
   ---
BEGIN
   if I_item_list is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_list',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHK_SKULIST',
                    'SKULIST, ITEM_MASTER, SUBCLASS',
                    'Item List: '|| I_item_list);
   open C_CHK_SKULIST ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHK_SKULIST',
                    'SKULIST, ITEM_MASTER, SUBCLASS',
                    'Item List: '|| I_item_list);

   fetch C_CHK_SKULIST into O_flg;

   if C_CHK_SKULIST%NOTFOUND then
      O_flg := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHK_SKULIST',
                    'SKULIST, ITEM_MASTER, SUBCLASS',
                    'Item List: '|| I_item_list);
   close C_CHK_SKULIST ;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_CHK_SKULIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CHK_SKULIST',
                          'SKULIST, ITEM_MASTER, SUBCLASS',
                          'Item List: '|| I_item_list);
         close C_CHK_SKULIST;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_ITEMLIST_CHK_FIXEDMARGIN;
----------------------------------------------------------------------------------------------------
-- End ModN115,116,117 Wipro/JK 20-Feb-2008
----------------------------------------------------------------------------------------------------
-- Begin ModN132 Wipro/JK 09-Jun-2008
---------------------------------------------------------------------------------------------
-- Function : TSL_GET_COMM_EXIST
-- Mod      : ModN132
-- Purpose  : This is a new function which will be used to check if an itemlist has common products in it.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_COMM_EXIST(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_exists        IN OUT VARCHAR2,
                            I_skulist       IN     SKULIST_DETAIL.SKULIST%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program       VARCHAR2(50)    := 'ITEMLIST_ATTRIB_SQL.TSL_GET_COMM_EXIST';
   L_item          ITEM_MASTER.ITEM%TYPE;
   ---
   cursor C_COMM_ITEM_EXIST is
     select DISTINCT iem.item
        from item_master iem,
             skulist_detail sl,
             system_options so
       -- 13-Aug-2008 - Govindarajan K - NBS00008445 - Begin
       where sl.item                           =  iem.item_parent
         and iem.item_level                    =  2
         and iem.tran_level                    =  2
         and NVL(iem.tsl_primary_country,'99') <> so.tsl_origin_country
       -- 13-Aug-2008 - Govindarajan K - NBS00008445 - End
         and iem.tsl_common_ind                =  'Y'
         and sl.skulist                        =  I_skulist;
   ---
BEGIN
   if I_skulist is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_skulist',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_COMM_ITEM_EXIST',
                    'SKULIST_DETAIL, ITEM_MASTER, SYSTEM_OPTIONS',
                    'Item List: '|| I_skulist);
   open C_COMM_ITEM_EXIST ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_COMM_ITEM_EXIST',
                    'SKULIST_DETAIL, ITEM_MASTER, SYSTEM_OPTIONS',
                    'Item List: '|| I_skulist);

   fetch C_COMM_ITEM_EXIST into L_item;

   if C_COMM_ITEM_EXIST%NOTFOUND then
      O_exists := 'N';
   else
      O_exists := 'Y';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_COMM_ITEM_EXIST',
                    'SKULIST_DETAIL, ITEM_MASTER, SYSTEM_OPTIONS',
                    'Item List: '|| I_skulist);
   close C_COMM_ITEM_EXIST ;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_COMM_ITEM_EXIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_COMM_ITEM_EXIST',
                          'SKULIST_DETAIL, ITEM_MASTER, SYSTEM_OPTIONS',
                          'Item List: '|| I_skulist);
         close C_COMM_ITEM_EXIST;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;

END TSL_GET_COMM_EXIST;
---------------------------------------------------------------------------------------------
-- Function : TSL_GET_SCALE_EXIST
-- Mod      : ModN132
-- Purpose  : This is a new function which will be used to check if an itemlist has scale
--            products in it.
---------------------------------------------------------------------------------------------
FUNCTION TSL_GET_SCALE_EXIST(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists         IN OUT VARCHAR2,
                             I_skulist        IN     SKULIST_DETAIL.SKULIST%TYPE,
                             I_origin_country IN     SUBCLASS.TSL_SCALE_INSTANCE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program        VARCHAR2(50)    := 'ITEMLIST_ATTRIB_SQL.TSL_GET_SCALE_EXIST';
   L_scale_ind      VARCHAR2(1);
   L_scale_instance SUBCLASS.TSL_SCALE_INSTANCE%TYPE;
   ---
   cursor C_GET_SCALE_ITEM is
      select sl.item,
             im.dept,
             im.class,
             im.subclass
        from skulist_detail sl,
             item_master im
       where sl.skulist = I_skulist
         and sl.item    = im.item;
   ---
BEGIN
   if I_skulist is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_skulist',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_SCALE_ITEM',
                    'SKULIST_DETAIL',
                    'SKULIST: '||I_skulist);

   O_exists := 'N';
   FOR c_rec IN C_GET_SCALE_ITEM LOOP
      if SUBCLASS_ATTRIB_SQL.TSL_GET_SCALE_IND(O_error_message,
                                               L_scale_ind,
                                               L_scale_instance,
                                               c_rec.dept,
                                               c_rec.class,
                                               c_rec.subclass) = FALSE then
         return FALSE;
      end if;

      if L_scale_ind = 'Y' then
         if I_origin_country <> L_scale_instance then
            O_exists := 'Y';
            return TRUE;
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

END TSL_GET_SCALE_EXIST;
-- End ModN132 Wipro/JK 09-Jun-2008
---------------------------------------------------------------------------------------------
--30-Jul-2008 Satish B.N, satish.narasimhaiah@in.tesco.com  ModN153 Begin
---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- Function Name : TSL_RANGE_EVENT_REQ
-- Purpose       : To get all the items from the itemlist
------------------------------------------------------------------------------------------------
FUNCTION GET_ITEMLIST_ITEMS (O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                               O_itemlist_table  IN OUT   ITEMLIST_ATTRIB_SQL.ITEMLIST_TABLE,
                               I_itemlist          IN     SKULIST_HEAD.SKULIST%TYPE)
   return BOOLEAN is

      CURSOR GET_ITEMLIST is
         select b.item
           from skulist_head a,
                skulist_detail b
          where a.skulist=b.skulist
            and a.skulist=I_itemlist;


    L_program            VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.GET_ITEMLIST_ITEMS';
    L_count              NUMBER(7):=1;

BEGIN

  SQL_LIB.SET_MARK('OPEN',
                   'GET_ITEMLIST',
                   'SKULIST_HEAD, SKULIST_DETAIL',
                   'Itemlist '||I_itemlist);
  FOR C_rec in GET_ITEMLIST
  LOOP
      O_itemlist_table(L_count).item         := C_rec.item;
      L_count := L_count + 1;
  END LOOP;
  return TRUE;

EXCEPTION
   when OTHERS then
      if GET_ITEMLIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'GET_ITEMLIST',
                          'SKULIST_HEAD, SKULIST_DETAIL',
                          'Itemlist '||I_itemlist);
         close GET_ITEMLIST;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_ITEMLIST_ITEMS;
---------------------------------------------------------------------------------------------
--30-Jul-2008 Satish B.N, satish.narasimhaiah@in.tesco.com  ModN153 End
---------------------------------------------------------------------------------------------
-- ST Def NBS00012501, 27-Apr-2009, Nitin Kumar, nitin.kumar@in.tesco.com (BEGIN)
------------------------------------------------------------------------------------------------------
-- Modified by : Nitin Kumar, nitin.kumar@in.tesco.com
-- Date        : 27-Apr-2009
-- Defect Id   : NBS00012501
-- Desc        : Added one new function GET_SP_EXIST for checking that if Item List has non-simple
--               pack items.
-----------------------------------------------------------------------------------------------------
FUNCTION GET_SP_EXIST(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      O_warn           IN OUT  VARCHAR2,
                      I_itemlist       IN      SKULIST_HEAD.SKULIST%TYPE)
  return BOOLEAN is

  ---
   L_program        VARCHAR2(50)              := 'ITEMLIST_ATTRIB_SQL.GET_SP_EXIST';
   L_itemlist_comp  ITEMLIST_ATTRIB_SQL.ITEMLIST_TABLE;
   L_sp_ind         ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   ---
BEGIN
   if I_itemlist is NULL then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('REQUIRED_INPUT_IS_NULL',
                                                  'I_itemlist',
                                                   L_program,
                                                   NULL);
      return FALSE;
   end if;
   ---
   -- Initialize the reocrd
   L_itemlist_comp.delete;
   --
   if ITEMLIST_ATTRIB_SQL.GET_ITEMLIST_ITEMS(O_error_message,
                                             L_itemlist_comp,
                                             I_itemlist) = FALSE then
      return FALSE;
   end if;
   --
   if L_itemlist_comp.count > 0 then
      FOR i in L_itemlist_comp.FIRST..L_itemlist_comp.LAST
      LOOP
         if ITEM_ATTRIB_SQL.GET_SIMPLE_PACK_IND(O_error_message,
                                                L_sp_ind,
                                                L_itemlist_comp(i).item)= FALSE then
            return FALSE;
         end if;
         if L_sp_ind = 'N' then
            O_warn := 'Y';
            return TRUE;
         end if;
      END LOOP;
   end if;

   -- All are Simple Pack Items
   O_warn := 'N';
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;

END GET_SP_EXIST;
-----------------------------------------------------------------------------------------------------
-- ST Def NBS00012501, 27-Apr-2009, Nitin Kumar, nitin.kumar@in.tesco.com (END)
-----------------------------------------------------------------------------------------------------
--09-Nov-2009   Joy Stephen, joy.johnchristopher@in.tesco.com  CR208 Begin
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_GET_CUSTOM_CODE_DESC
-- Purpose       : This function will take the input value and get the custom field code and its description
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_CUSTOM_CODE_DESC(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_custom_field      IN OUT   VARCHAR2,
                                  O_custom_field_desc IN OUT   VARCHAR2,
                                  --DefNBS00017246,29-Apr-2010 Tesco HSC,Sripriya,sripriya.karanam@in.tesco.com Begin
                                  O_code_type         IN OUT   VARCHAR2,
                                  --DefNBS00017246,29-Apr-2010 Tesco HSC,Sripriya,sripriya.karanam@in.tesco.com End
                                  I_custom_code       IN       VARCHAR2)
   RETURN BOOLEAN is

   L_program     VARCHAR2(50)    := 'ITEMLIST_ATTRIB_SQL.TSL_GET_CUSTOM_CODE_DESC';

   --This cursor fetches the Custom field and its description.
   cursor C_GET_CUSTOM_CODE_DESC is
   select custom_field_name,
          custom_field_desc,
          --DefNBS00017246,29-Apr-2010 Tesco HSC,Sripriya,sripriya.karanam@in.tesco.com Begin
          code_type
          --DefNBS00017246,29-Apr-2010 Tesco HSC,Sripriya,sripriya.karanam@in.tesco.com End
     from tsl_custom_fields
    where custom_code = I_custom_code;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CUSTOM_CODE_DESC',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_custom_code: '||I_custom_code);
   open C_GET_CUSTOM_CODE_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_CUSTOM_CODE_DESC',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_custom_code: '||I_custom_code);
   fetch C_GET_CUSTOM_CODE_DESC into O_custom_field,
                                     O_custom_field_desc,
                                     --DefNBS00017246,29-Apr-2010 Tesco HSC,Sripriya,sripriya.karanam@in.tesco.com Begin
                                     O_code_type;
                                     --DefNBS00017246,29-Apr-2010 Tesco HSC,Sripriya,sripriya.karanam@in.tesco.com End

      if C_GET_CUSTOM_CODE_DESC%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_CUST_CODE', NULL, NULL, NULL);
         return FALSE;
      end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CUSTOM_CODE_DESC',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_custom_code: '||I_custom_code);
   close C_GET_CUSTOM_CODE_DESC;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_CUSTOM_CODE_DESC;
--08-Apr-10   JK   MrgNBS016979     Begin
------------------------------------------------------------------------------------------------------------
--26-Mar-2010   Shireen Sheosunker, shireen.sheosunker@uk.tesco.com  CR261 Begin
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_GET_RESTRICTIONS_CODE_DESC
-- Purpose       : This function will take the input value and get the code and description from
--                table tsl_rest_fields (for restricted item attributes like EPW)
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_RESTRICTIONS_CODE_DESC(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                        O_custom_field      IN OUT   VARCHAR2,
                                        O_custom_field_desc IN OUT   VARCHAR2,
                                        I_custom_code       IN       VARCHAR2)
   RETURN BOOLEAN is

   L_program     VARCHAR2(50)    := 'ITEMLIST_ATTRIB_SQL.TSL_GET_RESTRICTIONS_CODE_DESC';

   --This cursor fetches the Custom field and its description.
   cursor C_GET_CUSTOM_CODE_DESC is
   select rest_custom_field_name,
          rest_custom_field_desc
     from tsl_rest_fields
    where rest_custom_code = I_custom_code;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CUSTOM_CODE_DESC',
                    'TSL_REST_FIELDS',
                    'rest_custom_code: '||I_custom_code);
   open C_GET_CUSTOM_CODE_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_CUSTOM_CODE_DESC',
                    'TSL_REST_FIELDS',
                    'rest_custom_code: '||I_custom_code);
   fetch C_GET_CUSTOM_CODE_DESC into O_custom_field,O_custom_field_desc;

      if C_GET_CUSTOM_CODE_DESC%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_CUST_CODE', NULL, NULL, NULL);
         return FALSE;
      end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CUSTOM_CODE_DESC',
                    'TSL_REST_FIELDS',
                    'rest_custom_code: '||I_custom_code);
   close C_GET_CUSTOM_CODE_DESC;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_RESTRICTIONS_CODE_DESC;
--08-Apr-10   JK   MrgNBS016979     End
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_IS_NUMBER
-- Purpose       : This function will take the input value and validate if it's a number.
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_IS_NUMBER(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_value           IN       VARCHAR2)
   RETURN BOOLEAN is

   L_program   VARCHAR2(50)    := 'ITEMLIST_ATTRIB_SQL.TSL_IS_NUMBER';
   L_number    NUMBER;

BEGIN

   L_number := I_value;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_IS_NUMBER;
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_DEL_VALUE_TEMP
-- Purpose       : This function will flush the temp table.
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_DEL_VALUE_TEMP(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            I_skulist         IN       SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is

   L_program     VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_DEL_VALUE_TEMP';

   cursor C_LOCK_TEMP_TABLE is
   select 'X'
     from TSL_SKULIST_VALUE_TEMP
    where itemlist = I_skulist
      for update nowait;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_TEMP_TABLE',
                    'TSL_ITEMDESC_BASE',
                    NULL);
   open C_LOCK_TEMP_TABLE;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_TEMP_TABLE',
                    'TSL_ITEMDESC_BASE',
                    NULL);
   close C_LOCK_TEMP_TABLE;

   --It flushes from the temp table
   delete from tsl_skulist_value_temp
   where itemlist = I_skulist;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_DEL_VALUE_TEMP;
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_VALIDATE_UPD_DATA
-- Purpose       : This function will take the input values of column name and value and then validate if the
--                 value can be inserted/updated in the main tables. If there is either a length mismatch or
--                 data type mismatch, an error will be returned to the user.
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- Modified by : Vinod Patalappa, vinod.patalappa@in.tesco.com
-- Date        : 12-Dec-2009
-- Defect Id   : NBS00015640
-- Defect Desc : Added one new cursor to fetch the TSL_COUNTRY_ID for the parent table.
-------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- Modified by : Vinod Patalappa/Joy Stephen
-- Date        : 15-Jan-2010
-- Defect Id   : NBS00015930
-- Defect Desc : Modified the function to handle the new date format(DD-MM-YYYY).
-------------------------------------------------------------------------------------------------
-- Modified by : Joy Stephen
-- Date        : 26-Feb-2010
-- Defect Id   : DefNBS016023
-- Defect Desc : Modified the function to handle the new date format(DDMMYY). Revisited the
--               entire package.This behaves as of the base functionality.
-------------------------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 02-Mar-2010
-- Defect Id   : DefNBS016380
-- Desc        : Modified the function TSL_VALIDATE_UPD_DATA, added a new parameter.
-------------------------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 04-Mar-2010
-- Defect Id   : DefNBS016143
-- Desc        : Modified the function TSL_VALIDATE_UPD_DATA to handle low level code specifically.
-------------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_UPD_DATA(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               I_column_name    IN      VARCHAR2,
                               I_value          IN      VARCHAR2,
                               I_item           IN      ITEM_MASTER.ITEM%TYPE,
                               I_country_id     IN      VARCHAR2,
                               -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   Begin
                               I_code_type      IN      VARCHAR2,
                               -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   End
                               -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                               -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                               -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                               I_login_ctry     IN      VARCHAR2
                               -- 14-Apr-11     Nandini M     PrfNBS022237     End
                               -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                               -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                               )

   RETURN BOOLEAN is

   --Declaring the variables
   L_program               VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_VALIDATE_UPD_DATA';
   L_tsl_parent_table      TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;
   L_data_type             USER_TAB_COLUMNS.DATA_TYPE%TYPE;
   L_data_length           USER_TAB_COLUMNS.DATA_LENGTH%TYPE;
   L_nullable              USER_TAB_COLUMNS.NULLABLE%TYPE;
   L_sql_stmnt             VARCHAR2(10000);
   L_return_code           VARCHAR2(5);
   L_date                  DATE;
   L_column                DATE;

   -- LT DefNBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
   L_exist                VARCHAR2(1);
   L_vdate                DATE := GET_VDATE;
   -- LT DefNBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
   -- LT DefNBS00015875, 29-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
   L_valid               BOOLEAN;
   L_style_ref_exist     VARCHAR2(1);
   L_system_option_row   SYSTEM_OPTIONS%ROWTYPE;
   -- LT DefNBS00015875, 29-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
   L_error               EXCEPTION;
   -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   Begin
   -- As part of this defect fix this variable L_code_type has been removed.
   -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   End
   L_code_count          NUMBER;
   PRAGMA EXCEPTION_INIT(L_error,-2290);
   -- LT DefNBS015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
   --SIT DefNBS016127, 08-Feb-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
   L_seq_no              NUMBER(3);
   L_error_seq_no        EXCEPTION;
   PRAGMA EXCEPTION_INIT(L_error_seq_no,-06502);
   --SIT DefNBS016127, 08-Feb-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
   -- 04-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016143   Begin
   L_low_lvl_exists      VARCHAR2(1);
   -- 04-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016143   End
   --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
   L_brand_ind           VARCHAR2(1);
   --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
   --SIT DefNBS016385, 18-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
   L_invalid_value        EXCEPTION;
   PRAGMA EXCEPTION_INIT(L_invalid_value, -02291);
   --SIT DefNBS016385, 18-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
   -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
   L_custom_code          TSL_CUSTOM_FIELDS.CUSTOM_CODE%TYPE;
   -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
   -- 23-Jun-2011   TESCO HSC/Praveen  DefNBS023046   Begin
   L_statement      VARCHAR2(1024) := NULL;
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);
   -- 23-Jun-2011   TESCO HSC/Praveen  DefNBS023046   End
   --CR434 shweta.madnawat@in.tesco.com 25-Oct-2011, Begin
   L_restrict_price_event     VARCHAR2(1);
   --CR434 shweta.madnawat@in.tesco.com 25-Oct-2011, End
   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, Begin
   L_new_access_trpv          VARCHAR2(1) := NULL;
   L_edit_access_trpv         VARCHAR2(1) := NULL;
   L_view_access_trpv         VARCHAR2(1) := NULL;
   L_owner_country_uk         ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE  := NULL;
   L_owner_country_roi        ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE  := NULL;
   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, End

   --This cursor fetches the parent table
   cursor C_GET_TABLE_NAME is
   select parent_table,
          -- DefNBS010755 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
          custom_code
          -- DefNBS010755 shweta.madnawat@in.tesco.com 15-Apr-10 End
     from tsl_custom_fields
    where upper(custom_field_name) = upper(I_column_name);

   --This cursor fetches the data type length
   cursor C_DATA_TYP_LEN is
   select data_type,
          data_length,
          nullable
     from user_tab_columns
    --08-Dec-2009   TESCO HSC/Vinod Kumar    DefNBS015668   Begin
    --23-Sep-10  JK  DefNBS019234   Begin
    where table_name  = upper(L_tsl_parent_table)
    --08-Dec-2009   TESCO HSC/Vinod Kumar    DefNBS015668   End
      and column_name = upper(I_column_name);
    --23-Sep-10  JK  DefNBS019234   End

   -- LT DefNBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
   cursor C_GET_COUNTRY_ID is
   select 'X'
     from dual
    where exists (select 1
                    from user_tab_columns uts
                   where uts.table_name = L_tsl_parent_table
                     --23-Sep-10  JK  DefNBS019234   Begin
                     and uts.column_name = upper('tsl_country_id'));
                     --23-Sep-10  JK  DefNBS019234   End
   -- LT DefNBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)

   -- LT DefNBS00015875, 29-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
   cursor C_STYEL_REF_VALIDATE is
   select 'X'
    from subclass  scl
   where scl.tsl_style_ref_ind = 'Y'
    and exists (select 1
                  from item_master iem
                 where iem.item     = I_item
                   and iem.dept     = scl.dept
                   and iem.class    = scl.class
                   and iem.subclass = scl.subclass);
   -- LT DefNBS00015875, 29-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)

   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
   -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   Begin
   -- As part of this defect fix this cursor C_GET_CODE_TYPE has been removed.
   -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   End

   cursor C_GET_CODE is
   select code
     from code_detail
    -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   Begin
    where code_type = I_code_type;
    -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   End
    -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)

   --DefNBS015897 Tarun Kumar Mishra tarun.mishra@in.tesco.com 22-Jan-2010 Begin
   cursor C_GET_CODE_BR_NBR is
   select code
     from code_detail
    where code_type = 'TBRA';
   --DefNBS015897 Tarun Kumar Mishra tarun.mishra@in.tesco.com 22-Jan-2010 End

   -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   Begin
   cursor C_GET_CODE_NBR is
   select code
     from code_detail
    where code_type = 'TNBR';
   -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   End

   -- 04-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016143   Begin
   cursor C_LOW_LVL_CODE_EXISTS is
   select 'X'
     from item_master im,
          tsl_low_lvl_code lc
    where item = I_item
      and im.dept = lc.dept
      and im.class = lc.class
      and im.subclass = lc.subclass
      and lc.low_lvl_code = translate(I_value,'_',' ');
   -- 04-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016143   End
   --CR434 shweta.madnawat@in.tesco.com, 25-Oct-2011, Begin
   cursor C_SUBCLASS_IND is
      select 'X'
        from subclass sc,
             item_master iem
       where iem.item = I_item
         and iem.dept = sc.dept
         and iem.class = sc.class
         and iem.subclass = sc.subclass
         --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, Begin
         --24-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023974, Begin
         and sc.tsl_restrict_price_event = 'N'
         and iem.tsl_owner_country in (L_owner_country_uk, L_owner_country_roi);
         --decode(I_country_id,'B',sc.tsl_restrict_price_event, 'N');
         --24-Nov-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, DefNBS023974, End
         --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, End
   --CR434 shweta.madnawat@in.tesco.com, 25-Oct-2011, End
   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, Begin
   cursor C_USR_EDIT_ITEM is
   select 'X'
     from item_master
    where item = I_item
      and tsl_owner_country in (L_owner_country_uk, L_owner_country_roi);
   --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, End
BEGIN

   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
   -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (BEGIN)
   -- As part of the design updation we have removed this piece of code.
   -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (END)
   L_code_count := 1;
   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
   --SIT DefNBS016127, 08-Feb-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
   if UPPER(I_column_name) = 'TSL_LOW_LVL_SEQ_NO' then
      L_seq_no := TO_NUMBER(I_value);
   end if;
   --SIT DefNBS016127, 08-Feb-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)

   --Fetching the values from C_GET_TABLE_NAME
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   open C_GET_TABLE_NAME;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   fetch C_GET_TABLE_NAME into L_tsl_parent_table,
                               -- DefNBS010755 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                               L_custom_code;
                               -- DefNBS010755 shweta.madnawat@in.tesco.com 15-Apr-10 End

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   close C_GET_TABLE_NAME;

   --Fetching the values from C_DATA_TYP_LEN
   SQL_LIB.SET_MARK('OPEN',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_DATA_TYP_LEN;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_DATA_TYP_LEN into L_data_type,L_data_length,L_nullable;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_DATA_TYP_LEN;

   -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
   -- Fetching the TSL_COUNTRY_ID for the parent table.
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_GET_COUNTRY_ID;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_GET_COUNTRY_ID into L_exist;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_GET_COUNTRY_ID;
   -- LT DefNBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
   -- LT DefNBS00015875, 29-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)

   SQL_LIB.SET_MARK('OPEN',
                    'C_STYEL_REF_VALIDATE',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_STYEL_REF_VALIDATE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_STYEL_REF_VALIDATE',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_STYEL_REF_VALIDATE into L_style_ref_exist;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_STYEL_REF_VALIDATE',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_STYEL_REF_VALIDATE;
   -- LT DefNBS00015875, 29-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
   -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   Begin
   -- As part of this defect fix this cursor C_GET_CODE_TYPE has been removed.
   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
   -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   End

   if L_exist is NOT NULL then
      --condition 1
      if (L_nullable = 'N' and I_value is NULL) then
         O_error_message := SQL_LIB.CREATE_MSG('REQ_FIELD_NULL',L_custom_code, NULL, NULL);
         return FALSE;
      else


-- MrgNBS023176(PrdSi to 3.5b) 08-July-2011 chithra ,chitraprabha.vadakkedath@in.tesco.com Begin
         -- 23-Jun-2011   TESCO HSC/Praveen  DefNBS023046   Begin
         L_statement := 'Declare' ||
                      ' Cursor C_LOCK_TBL is' ||
                      ' select 1' ||
                      '   from ' || L_tsl_parent_table ||
                      '  where item = '||''''|| I_item||''''||
                      '    and tsl_country_id = decode('||''''|| I_country_id||''''||',''B'',tsl_country_id,'||''''|| I_country_id||''''||')' ||
                      '    for update nowait;' ||
                      ' Begin' ||
                      '   open C_LOCK_TBL;'||
                      '   close C_LOCK_TBL;'||
                      ' End;';
         EXECUTE IMMEDIATE L_statement;
         -- 23-Jun-2011   TESCO HSC/Praveen  DefNBS023046   End


         -- MrgNBS023176(PrdSi to 3.5b) 08-July-2011 chithra ,chitraprabha.vadakkedath@in.tesco.com End
         --condition 2
         if (L_nullable = 'Y' and I_value is NULL) then
            -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
            if I_country_id = 'B' then
               L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                              ' set ' || I_column_name || ' = '''||I_value ||'''
                              where item = ' ||''''|| I_item||'''';
               EXECUTE IMMEDIATE L_sql_stmnt;
            else
               L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                              ' set ' || I_column_name || ' = '''||I_value ||'''
                              where item = ' ||''''|| I_item||''''||
                              ' and tsl_country_id = '|| ''''||I_country_id||'''';
               EXECUTE IMMEDIATE L_sql_stmnt;
            end if;-- check for I_country_id ='B'
             update tsl_skulist_value_temp
                set value = I_value
              where item  = I_item;
             -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
         else
            --condition 3
            -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
            -- LT Def NBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
            if L_data_type = 'DATE' then
               -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (BEGIN)
               --As part of the design updation we have removed this piece of code.
               if I_value <= get_vdate then
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_VDATE');
                  return FALSE;
               end if;
               if length(substr(I_value,INSTR(I_value, '-', 1, 2) + 1)) = 2 then
                  if I_country_id = 'B' then
                     L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                    ' set ' || I_column_name || ' = '''||I_value ||'''
                                    where item = ' ||''''|| I_item||'''';
                     EXECUTE IMMEDIATE L_sql_stmnt;
                  else
                     L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                    ' set ' || I_column_name || ' = '''||I_value ||'''
                                    where item = ' ||''''|| I_item||''''||
                                    ' and tsl_country_id = '|| ''''||I_country_id||'''';
                     EXECUTE IMMEDIATE L_sql_stmnt;
                  end if;
                  update tsl_skulist_value_temp
                      set value = I_value
                   where item  = I_item;
               else
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
                  return FALSE;
               end if;
               -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (END)
               -- LT Def NBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
               -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
            else
            -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
               --condition 4
               if length(I_value) > L_data_length then
                  O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                  return FALSE;
               else
                  if L_data_type = 'NUMBER' then
                     if TSL_IS_NUMBER(O_error_message,
                                      I_value) = FALSE then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        return FALSE;
                     else
                        if I_country_id = 'B' then
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||'''';
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        else
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||''''||
                                          ' and tsl_country_id = '|| ''''||I_country_id||'''';
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        end if;
                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;
                     -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
                  end if;
                  if L_data_type = 'VARCHAR2' then
                     -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
                     if L_data_length  = 1 then
                        if I_value is NULL then
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           return FALSE;
                        end if;
                     end if;
                     -- 02-Mar-2010    TESCO HSC/Joy Stephen   DefNBS016380   Begin
                     if I_code_type is not NULL then
                        --DefNBS015897 Tarun Kumar Mishra tarun.mishra@in.tesco.com 22-Jan-2010 Begin
                        if I_code_type in ('TBRA') then
                           for c_rec in C_GET_CODE_BR_NBR LOOP
                              if c_rec.code = I_value then
                                 L_code_count := L_code_count+1;
                                 --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
                                 L_brand_ind := 'Y';
                                 --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
                              end if;
                           END LOOP;
                        elsif I_code_type in ('TNBR') then
                           for c_rec in C_GET_CODE_NBR LOOP
                              if c_rec.code = I_value then
                                 L_code_count := L_code_count+1;
                                 --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
                                 L_brand_ind := 'N';
                                 --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
                              end if;
                           END LOOP;
                        else
                        --DefNBS015897 Tarun Kumar Mishra tarun.mishra@in.tesco.com 22-Jan-2010 End
                        -- 02-Mar-2010    TESCO HSC/Joy Stephen   DefNBS016380   End
                           for c_rec in C_GET_CODE LOOP
                              if c_rec.code = I_value then
                                 L_code_count := L_code_count+1;
                              end if;
                           END LOOP;
                        --DefNBS015897 Tarun Kumar Mishra tarun.mishra@in.tesco.com 22-Jan-2010 Begin
                        end if;
                        --DefNBS015897 Tarun Kumar Mishra tarun.mishra@in.tesco.com 22-Jan-2010 End
                        if L_code_count = 1 then
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                           return FALSE;
                        end if;
                     end if;
                     -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
                     -- 04-Mar-2010    TESCO HSC/Joy Stephen    DefNBS016143    Begin
                     if UPPER(I_column_name) = 'TSL_LOW_LVL_CODE' then
                        open C_LOW_LVL_CODE_EXISTS;
                        fetch C_LOW_LVL_CODE_EXISTS into L_low_lvl_exists;
                        close C_LOW_LVL_CODE_EXISTS;

                        if L_low_lvl_exists is NULL then
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_LVL_CODE',I_value,NULL,NULL);
                           return FALSE;
                        end if;
                     end if;
                     -- 04-Mar-2010    TESCO HSC/Joy Stephen    DefNBS016143    End
                     if length(I_value) > L_data_length or I_value is NULL then
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                        return FALSE;
                     else
                        --DefNBS016385, 15-Apr-2009 , Sripriya ,Sripriya.karanam@in.tesco.com (begin)
                        if UPPER(I_column_name) = 'DEF_PREF_PACK' then
                           if TSL_VALIDATE(O_error_message,
                                           I_column_name,
                                           I_item,
                                           I_value) = FALSE then
                              return FALSE;
                           end if;
                           -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
                           if TSL_INS_PREF_PACK(O_error_message,
                                               I_item,
                                               I_value,
                                               I_country_id) = FALSE then

                              return FALSE;
                           end if;
                        --end if;
                        -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
                        --DefNBS016385, 15-Apr-2009 , Sripriya ,Sripriya.karanam@in.tesco.com (End)
                        -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
                        elsif UPPER(I_column_name) = 'ORDER_IND' then
                           if TSL_INS_WH_ORDER(O_error_message,
                                               I_item,
                                               I_value,
                                               I_country_id) = FALSE then

                              return FALSE;
                             end if;
                        else
                        -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
                        -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
                        if I_country_id = 'B' then
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||'''';
                           --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
                           if I_code_type in ('TBRA','TNBR') then
                              L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
                           end if;
                           --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        else
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||''''||
                                          ' and tsl_country_id = '|| ''''||I_country_id||'''';
                           --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
                           if I_code_type in ('TBRA','TNBR') then
                              L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
                           end if;
                           --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        end if;
                        -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
                        end if;
                        -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (End)

                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                        -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
                     end if;
                  end if;
               end if;--condition 4
            end if;--condition 3
         end if;--condition 2
      end if;--condition 1
      --
      -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
      if UPPER(I_column_name) not in ('ORDER_IND','DEF_PREF_PACK') then
      -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
      -- LT Def NBS00015722, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
         if TSL_CASCADE_VALUES(O_error_message,
                               L_tsl_parent_table,
                               I_column_name,
                               I_value,
                               I_item,
                               I_country_id,
                               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
                               I_code_type,
                               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
                               -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                               -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                               -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                               I_login_ctry
                               -- 14-Apr-11     Nandini M     PrfNBS022237     End
                               -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                               -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                               ) = FALSE then

            return FALSE;
         end if;
      --
      -- LT Def NBS00015722, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
      -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
      end if;
      -- DefNBS020397, 03-Jan-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
   else
      --condition 1
      if (L_nullable = 'N' and I_value is NULL) then
         O_error_message := SQL_LIB.CREATE_MSG('REQ_FIELD_NULL',L_custom_code, NULL, NULL);
         return FALSE;
      else
         -- MrgNBS023176(PrdSi to 3.5b) 08-July-2011 chithra ,chitraprabha.vadakkedath@in.tesco.com Begin
         -- 23-Jun-2011   TESCO HSC/Praveen  DefNBS023046   Begin
         L_statement := 'Declare' ||
                      ' Cursor C_LOCK_TBL is' ||
                      ' select 1' ||
                      '   from ' || L_tsl_parent_table ||
                      '  where item = '||''''|| I_item||''''||
                      '    for update nowait;' ||
                      ' Begin' ||
                      '   open C_LOCK_TBL;'||
                      '   close C_LOCK_TBL;'||
                      ' End;';
         EXECUTE IMMEDIATE L_statement;
         -- 23-Jun-2011   TESCO HSC/Praveen  DefNBS023046   End
         -- MrgNBS023176(PrdSi to 3.5b) 08-July-2011 chithra ,chitraprabha.vadakkedath@in.tesco.com End
         --condition 2
         if (L_nullable = 'Y' and I_value is NULL) then
            L_sql_stmnt := ' update '|| L_tsl_parent_table ||
            --DefNBS00017246,29-Apr-2010 Tesco HSC,Sripriya,sripriya.karanam@in.tesco.com Begin
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = ' ||''''|| I_item||'''';
            --DefNBS00017246,29-Apr-2010 Tesco HSC,Sripriya,sripriya.karanam@in.tesco.com End
            EXECUTE IMMEDIATE L_sql_stmnt;
            update tsl_skulist_value_temp
               set value = I_value
             where item  = I_item;
         else
            --condition 3
            -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
            -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (BEGIN)
            --As part of the design updation we have removed this piece of code.
            if L_data_type = 'DATE' then
               if I_value <= L_vdate then
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_EFF_DATE');
               end if;
               if length(substr(I_value,INSTR(I_value, '-', 1, 2) + 1)) = 2 then
                  L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                 ' set ' || I_column_name || ' = '''||I_value ||'''
                                 where item = ' ||''''|| I_item||'''';
                  --
                  EXECUTE IMMEDIATE L_sql_stmnt;
                  update tsl_skulist_value_temp
                     set value = I_value
                   where item  = I_item;
               else
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
                  return FALSE;
               end if;
               -- SIT DefNBS016023,  26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (END)
               -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
            else
               --condition 4
               if length(I_value) > L_data_length then
                  -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                  O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                  -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                  return FALSE;
               else
                  if L_data_type = 'NUMBER' then
                     if TSL_IS_NUMBER(O_error_message,
                                      I_value) = FALSE then
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                        return FALSE;
                     else
                        L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                       ' set ' || I_column_name || ' = '''||I_value ||'''
                                       where item = ' ||''''|| I_item||'''';
                        EXECUTE IMMEDIATE L_sql_stmnt;
                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;
                  end if;
                  if L_data_type = 'VARCHAR2' then
                     -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
                     if L_data_length  = 1 then
                        if I_value is NULL then
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                           return FALSE;
                        end if;
                     end if;
                     -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   Begin
                     if I_code_type is not NULL then
                     -- 02-Mar-2010   TESCO HSC/Joy Stephen  DefNBS016380   End
                        for c_rec in C_GET_CODE LOOP
                           if c_rec.code = I_value then
                              L_code_count := L_code_count+1;
                           end if;
                        END LOOP;
                        if L_code_count = 1 then
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                           return FALSE;
                        end if;
                     end if;
                     -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
                     -- LT DefNBS00015875, 29-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
                     if upper(I_column_name) = upper('item_desc_secondary') then
                        if L_style_ref_exist is NOT NULL then
                           if system_options_sql.get_system_options(O_error_message,
                                                                    L_system_option_row) =  FALSE then
                              return FALSE;
                           end if;
                           if L_system_option_row.tsl_style_ref_ind = 'Y' then
                              if ITEM_MASTER_SQL.TSL_VALIDATE_STYLE_REF(O_error_message,
                                                                        I_value,
                                                                        L_valid)= FALSE then
                                 return FALSE;
                              end if;
                           end if;
                           if NOT L_valid then
                              -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                              O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',''''||I_value||'''',NULL,NULL);
                              -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                              return FALSE;
                           end if;
                        end if;
                     end if;
                      -- LT DefNBS00015875, 29-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
                      --CR434 shweta.madnawat@in.tesco.com, 25-Oct-2011, Begin
                      if upper(I_column_name) = upper('tsl_restrict_price_event') then
                         --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, Begin
                         if PRIVILEGE_SQL.TSL_VALIDATE_ACCESS(O_error_message,
                                                              'TRPV',
                                                              L_new_access_trpv,
                                                              L_edit_access_trpv,
                                                              L_view_access_trpv,
                                                              USER) = FALSE then
                            return FALSE;
                         end if;

                         if I_country_id in ('B', 'U') then
                            L_owner_country_uk := 'U';
                         end if;

                         if I_country_id in ('B', 'R') then
                            L_owner_country_roi := 'R';
                         end if;

                         if NVL(L_edit_access_trpv, 'N') = 'N' then
                            SQL_LIB.SET_MARK('OPEN',
                                             'C_SUBCLASS_IND',
                                             'SUBCLASS,ITEM_MASTER',
                                             'Item = ' || I_item);
                            open C_SUBCLASS_IND;
                            fetch C_SUBCLASS_IND into L_restrict_price_event;
                            close C_SUBCLASS_IND;
                         elsif NVL(L_edit_access_trpv, 'N') = 'Y' then
                            SQL_LIB.SET_MARK('OPEN',
                                             'C_USR_EDIT_ITEM',
                                             'ITEM_MASTER',
                                             'Item = ' || I_item);
                            open C_USR_EDIT_ITEM;
                            fetch C_USR_EDIT_ITEM into L_restrict_price_event;
                            close C_USR_EDIT_ITEM;
                         end if;

                         if L_restrict_price_event is NOT NULL then
                            --DefNBS024052, Vatan jaiswal, vatan.jaiswal@in.tesco.com, 30-Dec-2011, Begin
                            L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                           ' set ' || I_column_name || ' = '''||I_value ||'''
                                             ,last_update_id = ' || ''''|| USER ||''''||
                                           ' where item = ' ||''''|| I_item||''''||
                                           ' and item_level = tran_level '||
                                           ' and pack_ind = ' || '''N''';
                            --DefNBS024052, Vatan jaiswal, vatan.jaiswal@in.tesco.com, 30-Dec-2011, End
                            EXECUTE IMMEDIATE L_sql_stmnt;
                         end if;
                         --DefNBS024002, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, 07-Dec-2011, End
                      end if;
                      --CR434 shweta.madnawat@in.tesco.com, 25-Oct-2011, End
                     if length(I_value) > L_data_length or I_value is NULL then
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                        return FALSE;
                     else
                        -- CR434 shweta.madnawat@in.tesco.com 28-Oct-2011, Begin
                        if upper(I_column_name) != upper('tsl_restrict_price_event') then
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||'''';
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        end if;
                        -- CR434 shweta.madnawat@in.tesco.com 28-Oct-2011, End
                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;
                  end if;
               end if;--condition 4
            end if;--condition 3
         end if;--condition 2
      end if;--condition 1
      --
      -- LT Def NBS00015722, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)

      if TSL_CASCADE_VALUES(O_error_message,
                            L_tsl_parent_table,
                            I_column_name,
                            I_value,
                            I_item,
                            NULL,
                            --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
                            I_code_type,
                            --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
                            -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                            -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                            -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                            I_login_ctry
                            -- 14-Apr-11     Nandini M     PrfNBS022237     End
                            -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                            -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                            ) = FALSE then
         return FALSE;
      end if;
      --
      -- LT Def NBS00015722, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
   end if;

   return TRUE;

EXCEPTION
    -- MrgNBS023176(PrdSi to 3.5b) 08-July-2011 chithra ,chitraprabha.vadakkedath@in.tesco.com Begin
    -- 23-Jun-2011   TESCO HSC/Praveen  DefNBS023046   Begin
    when RECORD_LOCKED then
       O_error_message := SQL_LIB.GET_MESSAGE_TEXT('RECORD_LOCKED',
                                                   L_tsl_parent_table ,
                                                   I_item,
                                                   NULL);
       return FALSE;
    -- 23-Jun-2011   TESCO HSC/Praveen  DefNBS023046   End
    -- MrgNBS023176(PrdSi to 3.5b) 08-July-2011 chithra ,chitraprabha.vadakkedath@in.tesco.com End
   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
   when L_error then
      -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
      -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
      return FALSE;
   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
   --SIT DefNBS016127, 08-Feb-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
   when L_error_seq_no then
      -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
      -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
      return FALSE;
   --SIT DefNBS016127, 08-Feb-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)
   --SIT DefNBS016385, 18-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
   when L_invalid_value then
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',
                                            -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                                            ''''||I_value||'''',
                                            -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                                            L_custom_code,
                                            NULL);
      return FALSE;
   --SIT DefNBS016385, 18-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
   when OTHERS then
      if L_data_type = 'DATE' then
       O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
       return FALSE;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VALIDATE_UPD_DATA;
--08-Apr-10   JK   MrgNBS016979    Begin
------------------------------------------------------------------------------------------------------------
--07-Apr-2010   Shireen Sheosunker, shireen.sheosunker@uk.tesco.com  DefNBS016916 Begin
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_VALIDATE_UPD_DATA_RESTRICT
-- Purpose       : This function will take the input value and get the code and description from
--                table tsl_rest_fields (for restricted item attributes like EPW)
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_UPD_DATA_RESTRICT(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               I_column_name    IN      VARCHAR2,
                               I_value          IN      VARCHAR2,
                               I_item           IN      ITEM_MASTER.ITEM%TYPE,
                               I_country_id     IN      VARCHAR2,
                               I_code_type      IN      VARCHAR2)
   RETURN BOOLEAN is

   --Declaring the variables
   L_program               VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_VALIDATE_UPD_DATA_RESTRICT';
   L_tsl_parent_table      TSL_REST_FIELDS.REST_PARENT_TABLE%TYPE;
   L_data_type             USER_TAB_COLUMNS.DATA_TYPE%TYPE;
   L_data_length           USER_TAB_COLUMNS.DATA_LENGTH%TYPE;
   L_nullable              USER_TAB_COLUMNS.NULLABLE%TYPE;
   L_sql_stmnt             VARCHAR2(10000);
   L_return_code           VARCHAR2(5);
   L_date                  DATE;
   L_column                DATE;
   L_exist                 VARCHAR2(1);
   L_vdate                 DATE := GET_VDATE;
   L_valid                 BOOLEAN;
   L_style_ref_exist       VARCHAR2(1);
   L_system_option_row     SYSTEM_OPTIONS%ROWTYPE;
   L_error                 EXCEPTION;
   L_code_count            NUMBER;
   PRAGMA EXCEPTION_INIT(L_error,-2290);
   L_seq_no                NUMBER(3);
   L_error_seq_no          EXCEPTION;
   PRAGMA EXCEPTION_INIT(L_error_seq_no,-06502);
   L_low_lvl_exists        VARCHAR2(1);

   -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
   L_custom_code           TSL_REST_FIELDS.REST_CUSTOM_CODE%TYPE;
   -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
   --This cursor fetches the parent table
   cursor C_GET_TABLE_NAME is
   select rest_parent_table,
          -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
          rest_custom_code
          -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
     from tsl_rest_fields
    where upper(rest_custom_field_name) = upper(I_column_name);

   --This cursor fetches the data type length
   cursor C_DATA_TYP_LEN is
   select data_type,
          data_length,
          nullable
     from user_tab_columns
    --23-Sep-10  JK  DefNBS019234   Begin
    where table_name  = upper(L_tsl_parent_table)
      and column_name = upper(I_column_name);
    --23-Sep-10  JK  DefNBS019234   End

   cursor C_GET_COUNTRY_ID is
   select 'X'
     from dual
    where exists (select 1
                    from user_tab_columns uts
                   where uts.table_name = L_tsl_parent_table
                     --23-Sep-10  JK  DefNBS019234   Begin
                     and uts.column_name = upper('tsl_country_id'));
                     --23-Sep-10  JK  DefNBS019234   End

   cursor C_STYEL_REF_VALIDATE is
   select 'X'
    from subclass  scl
   where scl.tsl_style_ref_ind = 'Y'
    and exists (select 1
                  from item_master iem
                 where iem.item     = I_item
                   and iem.dept     = scl.dept
                   and iem.class    = scl.class
                   and iem.subclass = scl.subclass);

   cursor C_GET_CODE is
   select code
     from code_detail
    where code_type = I_code_type;

   cursor C_GET_CODE_BR_NBR is
   select code
     from code_detail
    where code_type = 'TBRA';

   cursor C_GET_CODE_NBR is
   select code
     from code_detail
    where code_type = 'TNBR';

   cursor C_LOW_LVL_CODE_EXISTS is
   select 'X'
     from item_master im,
          tsl_low_lvl_code lc
    where item = I_item
      and im.dept = lc.dept
      and im.class = lc.class
      and im.subclass = lc.subclass
      and lc.low_lvl_code = translate(I_value,'_',' ');

BEGIN
   L_code_count := 1;
   if UPPER(I_column_name) = 'TSL_LOW_LVL_SEQ_NO' then
      L_seq_no := TO_NUMBER(I_value);
   end if;

   --Fetching the values from C_GET_TABLE_NAME
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TABLE_NAME',
                    'TSL_REST_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   open C_GET_TABLE_NAME;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TABLE_NAME',
                    'TSL_REST_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   fetch C_GET_TABLE_NAME into L_tsl_parent_table,
                               -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                               L_custom_code;
                               -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TABLE_NAME',
                    'TSL_REST_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   close C_GET_TABLE_NAME;

   --Fetching the values from C_DATA_TYP_LEN
   SQL_LIB.SET_MARK('OPEN',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_DATA_TYP_LEN;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_DATA_TYP_LEN into L_data_type,L_data_length,L_nullable;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_DATA_TYP_LEN;

   -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
   -- Fetching the TSL_COUNTRY_ID for the parent table.
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_GET_COUNTRY_ID;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_GET_COUNTRY_ID into L_exist;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_GET_COUNTRY_ID;

   SQL_LIB.SET_MARK('OPEN',
                    'C_STYEL_REF_VALIDATE',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_STYEL_REF_VALIDATE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_STYEL_REF_VALIDATE',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_STYEL_REF_VALIDATE into L_style_ref_exist;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_STYEL_REF_VALIDATE',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_STYEL_REF_VALIDATE;

   if L_exist is NOT NULL then
      --condition 1
      if (L_nullable = 'N' and I_value is NULL) then
         -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
         O_error_message := SQL_LIB.CREATE_MSG('REQ_FIELD_NULL',L_custom_code, NULL, NULL);
         -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
         return FALSE;
      else
         --condition 2
         if (L_nullable = 'Y' and I_value is NULL) then
            if I_country_id = 'B' then
               if I_column_name = 'tsl_end_date' then
                 update item_attributes
                    set tsl_epw_ind = 'Y', tsl_end_date = I_value
                  where item = I_item;
               else
                 L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                              ' set ' || I_column_name || ' = '''||I_value ||'''
                              where item = ' ||''''|| I_item||'''';
                 EXECUTE IMMEDIATE L_sql_stmnt;
               -- DefNBS017079 Shireen Sheosunker@uk.tesco.com 23-Apr-10 Begin
               end if;
               -- DefNBS017079 Shireen Sheosunker@uk.tesco.com 23-Apr-10 End
            else
               if I_column_name = 'tsl_end_date' then
                  update item_attributes
                    set tsl_epw_ind = 'Y', tsl_end_date = I_value
                  where item = I_item and tsl_country_id = I_country_id;
               else
                  L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                              ' set ' || I_column_name || ' = '''||I_value ||'''
                              where item = ' ||''''|| I_item||''''||
                              ' and tsl_country_id = '|| ''''||I_country_id||'''';
                  EXECUTE IMMEDIATE L_sql_stmnt;
               end if;
               -- DefNBS017079 Shireen Sheosunker@uk.tesco.com 23-Apr-10 End
            end if;-- check for I_country_id ='B'
             update tsl_skulist_value_temp
                set value = I_value
              where item  = I_item;
         else
            --condition 3
            if L_data_type = 'DATE' then
               if I_value <= get_vdate then
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_VDATE');
                  return FALSE;
               end if;
               if length(substr(I_value,INSTR(I_value, '-', 1, 2) + 1)) = 2 then
                  if I_country_id = 'B' then
                     if I_column_name = 'tsl_end_date' then
                        update item_attributes
                            set tsl_epw_ind = 'Y', tsl_end_date = decode(I_value,null,null,to_date(I_value,'DD-MON-YY'))
                          where item = I_item;
                     else
                        L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                    ' set ' || I_column_name || ' = '''||I_value ||'''
                                    where item = ' ||''''|| I_item||'''';
                        EXECUTE IMMEDIATE L_sql_stmnt;
                     end if;
                  else
                     if I_column_name = 'tsl_end_date' then
                        update item_attributes
                            set tsl_epw_ind = 'Y', tsl_end_date = decode(I_value,null,null,to_date(I_value,'DD-MON-YY'))
                          where item = I_item and tsl_country_id = I_country_id;
                     else
                        L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                    ' set ' || I_column_name || ' = '''||I_value ||'''
                                    where item = ' ||''''|| I_item||''''||
                                    ' and tsl_country_id = '|| ''''||I_country_id||'''';
                        EXECUTE IMMEDIATE L_sql_stmnt;
                     end if;
                  end if;
                  update tsl_skulist_value_temp
                      set value = I_value
                   where item  = I_item;
               else
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
                  return FALSE;
               end if;
            else
               --condition 4
               if length(I_value) > L_data_length then
                  -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 Begin
                  if I_column_name = 'tsl_epw_ind' then
                     if upper(I_value) = 'Y' then
                        update item_attributes
                           set tsl_epw_ind = 'Y',tsl_end_date = null
                         where item = I_item;
                      else
                         O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                         return FALSE;
                     end if;
                  else
                  -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 End
                     -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                     O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                     -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                     return FALSE;
                  end if;
               else
                  if L_data_type = 'NUMBER' then
                     if TSL_IS_NUMBER(O_error_message,
                                      I_value) = FALSE then
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                        return FALSE;
                     else
                        if I_country_id = 'B' then
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||'''';
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        else
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||''''||
                                          ' and tsl_country_id = '|| ''''||I_country_id||'''';
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        end if;
                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;
                     -- LT Def NBS00015640, 12-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
                  end if;
                  if L_data_type = 'VARCHAR2' then
                     if L_data_length  = 1 then
                        if I_value is NULL then
                           -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 Begin
                           if I_column_name = 'tsl_epw_ind' then
                              if upper(I_value) = 'Y' then
                                 update item_attributes
                                    set tsl_epw_ind = 'Y',tsl_end_date = null
                                  where item = I_item;
                              else
                                  O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                                  return FALSE;
                              end if;
                           else
                           -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 End
                             -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                             O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                             -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                             return FALSE;
                           end if;
                        end if;
                     end if;
                     if I_code_type is not NULL then
                        if I_code_type in ('TBRA') then
                           for c_rec in C_GET_CODE_BR_NBR LOOP
                              if c_rec.code = I_value then
                                 L_code_count := L_code_count+1;
                              end if;
                           END LOOP;
                        elsif I_code_type in ('TNBR') then
                           for c_rec in C_GET_CODE_NBR LOOP
                              if c_rec.code = I_value then
                                 L_code_count := L_code_count+1;
                              end if;
                           END LOOP;
                        else
                           for c_rec in C_GET_CODE LOOP
                              if c_rec.code = I_value then
                                 L_code_count := L_code_count+1;
                              end if;
                           END LOOP;
                        end if;
                        if L_code_count = 1 then
                           -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 Begin
                           if I_column_name = 'tsl_epw_ind' then
                              if upper(I_value) = 'Y' then
                                  update item_attributes
                                     set tsl_epw_ind = 'Y',tsl_end_date = null
                                   where item = I_item;
                              else
                                  O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                                  return FALSE;
                              end if;
                           else
                           -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 End
                             -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                             O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                             -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                             return FALSE;
                           end if;
                        end if;
                     end if;
                     if UPPER(I_column_name) = 'TSL_LOW_LVL_CODE' then
                        open C_LOW_LVL_CODE_EXISTS;
                        fetch C_LOW_LVL_CODE_EXISTS into L_low_lvl_exists;
                        close C_LOW_LVL_CODE_EXISTS;

                        if L_low_lvl_exists is NULL then
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_LVL_CODE',I_value,NULL,NULL);
                           return FALSE;
                        end if;
                     end if;
                     if length(I_value) > L_data_length or I_value is NULL then
                        -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 Begin
                        if I_column_name = 'tsl_epw_ind' then
                           if upper(I_value) = 'Y' then
                              update item_attributes
                              set tsl_epw_ind = 'Y',tsl_end_date = null
                              where item = I_item;
                           else
                              O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                              return FALSE;
                           end if;
                        else
                        -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 End
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                           return FALSE;
                        end if;
                     else
                        if I_country_id = 'B' then
                            -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 Begin
                           if I_column_name = 'tsl_epw_ind' then
                              if upper(I_value) = 'Y' then
                                 update item_attributes
                                    set tsl_epw_ind = 'Y',tsl_end_date = null
                                  where item = I_item;
                              else
                                 O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                                 return FALSE;
                              end if;
                           else
                            -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 End
                              L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||'''';
                              EXECUTE IMMEDIATE L_sql_stmnt;
                           end if;
                        else
                           -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 Begin
                           if I_column_name = 'tsl_epw_ind' then
                              if upper(I_value) = 'Y' then
                                 update item_attributes
                                    set tsl_epw_ind = 'Y',tsl_end_date = null
                                  where item = I_item;
                              else
                                 O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                                 return FALSE;
                              end if;
                           else
                           -- DefNBS017095 shireen.sheosunker@uk.tesco.com 22-Apr-10 End
                              L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||''''||
                                          ' and tsl_country_id = '|| ''''||I_country_id||'''';
                              EXECUTE IMMEDIATE L_sql_stmnt;
                           end if;
                        end if;

                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;
                  end if;
               end if;--condition 4
            end if;--condition 3
         end if;--condition 2
      end if;--condition 1
      --
      if TSL_CASCADE_VALUES(O_error_message,
                            L_tsl_parent_table,
                            I_column_name,
                            I_value,
                            I_item,
                            I_country_id,
                            --08-Apr-10     JK    MrgNBS016979     Begin
                            I_code_type,
                            --08-Apr-10     JK    MrgNBS016979     End
                            -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                            -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                            -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                            NULL
                            -- 14-Apr-11     Nandini M     PrfNBS022237     End
                            -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                            -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                            ) = FALSE then

         return FALSE;
      end if;
      --
   else
      --condition 1
      if (L_nullable = 'N' and I_value is NULL) then
         O_error_message := SQL_LIB.CREATE_MSG('REQ_FIELD_NULL',L_custom_code, NULL, NULL);
         return FALSE;
      else
         --condition 2
         if (L_nullable = 'Y' and I_value is NULL) then
            L_sql_stmnt := 'update'||L_tsl_parent_table||'set'||I_column_name||'='||I_value||
                           'where item ='|| ''''||I_item||'''';
            EXECUTE IMMEDIATE L_sql_stmnt;
            update tsl_skulist_value_temp
               set value = I_value
             where item  = I_item;
         else
            --condition 3
            if L_data_type = 'DATE' then
               if I_value <= L_vdate then
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_EFF_DATE');
                  return FALSE;
               end if;
               if length(substr(I_value,INSTR(I_value, '-', 1, 2) + 1)) = 2 then
                  L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                 ' set ' || I_column_name || ' = '''||I_value ||'''
                                 where item = ' ||''''|| I_item||'''';
                  --
                  EXECUTE IMMEDIATE L_sql_stmnt;
                  update tsl_skulist_value_temp
                     set value = I_value
                   where item  = I_item;
               else
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
                  return FALSE;
               end if;
            else
               --condition 4
               if length(I_value) > L_data_length then
                  -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                  O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                  -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                  return FALSE;
               else
                  if L_data_type = 'NUMBER' then
                     if TSL_IS_NUMBER(O_error_message,
                                      I_value) = FALSE then
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                        return FALSE;
                     else
                        L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                       ' set ' || I_column_name || ' = '''||I_value ||'''
                                       where item = ' ||''''|| I_item||'''';
                        EXECUTE IMMEDIATE L_sql_stmnt;
                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;
                  end if;
                  if L_data_type = 'VARCHAR2' then
                     -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
                     if L_data_length  = 1 then
                        if I_value is NULL then
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                           return FALSE;
                        end if;
                     end if;
                     if I_code_type is not NULL then
                        for c_rec in C_GET_CODE LOOP
                           if c_rec.code = I_value then
                              L_code_count := L_code_count+1;
                           end if;
                        END LOOP;
                        if L_code_count = 1 then
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                           return FALSE;
                        end if;
                     end if;
                     if upper(I_column_name) = upper('item_desc_secondary') then
                        if L_style_ref_exist is NOT NULL then
                           if system_options_sql.get_system_options(O_error_message,
                                                                    L_system_option_row) =  FALSE then
                              return FALSE;
                           end if;
                           if L_system_option_row.tsl_style_ref_ind = 'Y' then
                              if ITEM_MASTER_SQL.TSL_VALIDATE_STYLE_REF(O_error_message,
                                                                        I_value,
                                                                        L_valid)= FALSE then
                                 return FALSE;
                              end if;
                           end if;
                           if NOT L_valid then
                              -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                              O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',''''||I_value||'''',NULL,NULL);
                              -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                              return FALSE;
                           end if;
                        end if;
                     end if;
                     if length(I_value) > L_data_length or I_value is NULL then
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
                        return FALSE;
                     else
                        L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                       ' set ' || I_column_name || ' = '''||I_value ||'''
                                       where item = ' ||''''|| I_item||'''';
                        EXECUTE IMMEDIATE L_sql_stmnt;
                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;
                  end if;
               end if;--condition 4
            end if;--condition 3
         end if;--condition 2
      end if;--condition 1
      --
      if TSL_CASCADE_VALUES(O_error_message,
                            L_tsl_parent_table,
                            I_column_name,
                            I_value,
                            I_item,
                            NULL,
                            --08-Apr-10     JK    MrgNBS016979     Begin
                            I_code_type,
                            --08-Apr-10     JK    MrgNBS016979     End
                            -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                            -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                            -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                            NULL
                            -- 14-Apr-11     Nandini M     PrfNBS022237     End
                            -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                            -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                            ) = FALSE then

         return FALSE;
      end if;
      --
   end if;

   return TRUE;

EXCEPTION
   when L_error then
      -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
      -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Ed
      return FALSE;
   when L_error_seq_no then
      -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 Begin
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
      -- DefNBS017055 shweta.madnawat@in.tesco.com 15-Apr-10 End
      return FALSE;
   when OTHERS then
      if L_data_type = 'DATE' then
       O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
       return FALSE;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VALIDATE_UPD_DATA_RESTRICT;
--08-Apr-10   JK   MrgNBS016979    End

------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_MASS_APPROVE
-- Purpose       : This function will mass approve the Itemlist.
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_MASS_APPROVE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                          O_sub_appr_ind   IN OUT  VARCHAR2,
                          I_itemlist       IN      VARCHAR2,
                          -- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
                          -- 18-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                          I_restrict_ctry  IN      VARCHAR2,
                          --CR399, 04-Mar-2014, Niraj C, nirajkumar.choudhary@in.tesco.com, Begin
                          I_ignore_min_price_ind   IN      VARCHAR2 DEFAULT 'N')
                         --CR399, 04-Mar-2014, Niraj C, nirajkumar.choudhary@in.tesco.com, End
                          -- 18-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                          -- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
   RETURN BOOLEAN is

   --Declaring the Local variable.
   L_program                    VARCHAR2(50):= 'ITEMLIST_ATTRIB_SQL.TSL_MASS_APPROVE';
   L_error_message              RTK_ERRORS.RTK_TEXT%TYPE;
   L_itemlist_table             ITEMLIST_ATTRIB_SQL.ITEMLIST_TABLE;
   L_itemmaster_rec             ITEM_MASTER%ROWTYPE;
   L_sub_err_ind                VARCHAR2(1):=NULL;
   L_item_submitted             BOOLEAN := FALSE;
   L_children_submitted         BOOLEAN := FALSE;
   L_exists                     BOOLEAN := FALSE;
   L_all_var_submitted          BOOLEAN := FALSE;
   L_all_children_submitted     BOOLEAN := FALSE;
   L_item_approved              BOOLEAN := FALSE;
   L_children_approved          BOOLEAN := FALSE;
   L_all_var_approved           BOOLEAN := FALSE;
   L_all_children_approved      BOOLEAN := FALSE;
   --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    Begin
   L_base_item                  ITEM_MASTER.ITEM%TYPE;
   L_var_exists                 VARCHAR2(1);

   --This cursor checks is there any variants in 'W' status for the given Base item in the list
   cursor C_GET_APPR_VAR is
   select 'X'
     from item_master im
    where im.tsl_base_item = L_base_item
      and im.item != L_base_item
      and status = 'W';
   --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    End

BEGIN

   O_sub_appr_ind := 'N';
   L_sub_err_ind  := 'N';

   if ITEMLIST_ATTRIB_SQL.GET_ITEMLIST_ITEMS(L_error_message,
                                             L_itemlist_table,
                                             I_itemlist) = FALSE then
      return FALSE;
   end if;

   if L_itemlist_table is NOT NULL and L_itemlist_table.COUNT > 0 then
      FOR i in 1 .. L_itemlist_table.COUNT LOOP
         if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(L_error_message,
                                            L_itemmaster_rec,
                                            L_itemlist_table(i).item) = FALSE then
            return FALSE;
         end if;
         ---
         -- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
         -- 18-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         if ((L_itemmaster_rec.tsl_owner_country != I_restrict_ctry) or
            (I_restrict_ctry = 'N')) then
         -- 18-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
         -- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
            ---
         --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    Begin
         -- Defect NBS00016121 Raghuveer P R 10-Feb-2010 - Begin
         -- Added the missing parantheses for defect NBS00016121
         if L_itemmaster_rec.status in('A') and ((L_itemmaster_rec.item_level = L_itemmaster_rec.tran_level and
            L_itemmaster_rec.pack_ind = 'N') or
            --20-Jan-10   Wipro/JK    DefNBS015979    Begin
            --Do not need to call Submit function for the already approved TPNA/Level 1 items
            --as Approved items cannot become to Submit status
            (L_itemmaster_rec.item_level = 1 and  L_itemmaster_rec.pack_ind = 'N')) then
            -- Defect NBS00016121 Raghuveer P R 10-Feb-2010 - End
            --20-Jan-10   Wipro/JK    DefNBS015979    End
            L_item_submitted := TRUE;
            L_children_submitted := TRUE;
         else
            if ITEM_APPROVAL_SQL.SUBMIT(L_error_message,
                                        L_item_submitted,
                                        L_children_submitted,
                                        'Y',
                                        L_itemlist_table(i).item,
                                        --CR399 Niraj C nirajkumar.choudhary@in.tesco.com Begin
                                        'Y') = FALSE then
                                        --CR399 Niraj C nirajkumar.choudhary@in.tesco.com End
               return FALSE;
            end if;
         end if;
         --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    End
         if L_item_submitted = TRUE and L_children_submitted = TRUE then
            O_sub_appr_ind := 'Y';
            if L_itemmaster_rec.item_level = 1 and L_itemmaster_rec.tran_level = 2 then
               if L_itemmaster_rec.status not in ('A') then
                  update item_master
                     set status = 'S'
                   where item   = L_itemmaster_rec.item;
               end if;
            elsif (L_itemmaster_rec.item_level = 2 and L_itemmaster_rec.tran_level = 2 and
                  L_itemmaster_rec.tsl_base_item = L_itemlist_table(i).item) then
               if TSL_BASE_VARIANT_SQL.VALIDATE_BASE_ITEM(L_error_message,
                                                          L_exists,
                                                          L_itemlist_table(i).item) = FALSE then
                  return FALSE;
               end if;
               if L_exists = TRUE then
                  if TSL_BASE_VARIANT_SQL.VARIANTS_EXISTS(L_error_message,
                                                          L_exists,
                                                          L_itemlist_table(i).item) = FALSE then
                     return FALSE;
                  end if;
                  if L_exists = TRUE then
                     --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    Begin
                     L_base_item := L_itemlist_table(i).item;
                     --Fetching the cursor C_GET_APPR_VAR
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_APPR_VAR',
                                      'ITEM_MASTER',
                                      'Item: '||L_base_item);
                     open C_GET_APPR_VAR;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_APPR_VAR',
                                      'ITEM_MASTER',
                                      'Item: '||L_base_item);
                     fetch C_GET_APPR_VAR into L_var_exists;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_APPR_VAR',
                                      'ITEM_MASTER',
                                      'Item: '||L_base_item);
                     close C_GET_APPR_VAR;

                     if L_var_exists is not NULL then
                        if ITEM_APPROVAL_SQL.TSL_SUBMIT_VARIANT(L_error_message,
                                                                L_all_var_submitted,
                                                                L_all_children_submitted,
                                                                L_itemlist_table(i).item,
                                                                'Y',
                                                                --CR399 Niraj C nirajkumar.choudhary@in.tesco.com Begin
                                                                'Y') = FALSE then
                                                                --CR399 Niraj C nirajkumar.choudhary@in.tesco.com End
                           return FALSE;
                        end if;
                        if (L_all_var_submitted = FALSE or L_all_children_submitted = FALSE) then
                           L_sub_err_ind := 'Y';
                        end if;
                     end if;
                     --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    End
                  end if;
               end if;
               if L_itemmaster_rec.status not in ('A') then
                  update item_master
                     set status = 'S'
                   where item   = L_itemmaster_rec.item;
               end if;
            elsif L_itemmaster_rec.item_level = 2 and L_itemmaster_rec.tran_level = 2 and
                  L_itemlist_table(i).item != L_itemmaster_rec.tsl_base_item then
               if ITEM_APPROVAL_SQL.TSL_SUBMIT_VARIANT(L_error_message,
                                                       L_all_var_submitted,
                                                       L_all_children_submitted,
                                                       L_itemlist_table(i).item,
                                                       'Y',
                                                       --CR399 Niraj C nirajkumar.choudhary@in.tesco.com Begin
                                                       'Y') = FALSE then
                                                       --CR399 Niraj C nirajkumar.choudhary@in.tesco.com End
                  return FALSE;
               end if;
               if ITEM_APPROVAL_SQL.TSL_APPROVE_VARIANT(L_error_message,
                                                        L_all_var_approved,
                                                        L_all_children_approved,
                                                        L_itemlist_table(i).item,
                                                        'Y',
                                                        --CR399 Niraj C nirajkumar.choudhary@in.tesco.com Begin
                                                        'Y') = FALSE then
                                                        --CR399 Niraj C nirajkumar.choudhary@in.tesco.com End
                  return FALSE;
               end if;
               --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    Begin
               if (L_all_var_approved = FALSE or L_all_children_approved = FALSE) then
                  L_sub_err_ind := 'Y';
               end if;
               --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    End
               if L_itemmaster_rec.status not in ('A') then
                  update item_master
                     set status = 'S'
                   where item   = L_itemmaster_rec.item;
               end if;
            else
               if ((L_itemmaster_rec.item_level = L_itemmaster_rec.tran_level) and (L_itemmaster_rec.Pack_Ind ='Y')) then
                  if L_itemmaster_rec.status not in ('A') then
                     update item_master
                        set status = 'S'
                      where item   = L_itemmaster_rec.item;
                  end if;
               end if;
            end if;
         else
            if L_item_submitted = TRUE then
               if L_itemmaster_rec.status not in ('A') then
                  update item_master
                     set status = 'S'
                   where item   = L_itemmaster_rec.item;
               end if;
            end if;
            L_sub_err_ind := 'Y';
         end if;

         if ITEM_APPROVAL_SQL.APPROVE(L_error_message,
                                      L_item_approved,
                                      L_children_approved,
                                      'Y',
                                      L_itemlist_table(i).item,
      --CR399 Niraj C nirajkumar.choudhary@in.tesco.com Begin
                                      'N',
                                      'Y') = FALSE then
      --CR399 Niraj C nirajkumar.choudhary@in.tesco.com End
            return FALSE;
         end if;
         --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    Begin
         if L_itemmaster_rec.status in('A') then
            L_item_approved := TRUE;
            L_children_approved := TRUE;
         end if;
         --10-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015675    End
         if L_item_approved = TRUE then
            if L_itemmaster_rec.item_level = 1 and L_itemmaster_rec.tran_level = 2 then
               update item_master
                  set status = 'A'
                where item   = L_itemmaster_rec.item;
               --12-May-2010 Murali  Cr288b Begin
               if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                                       L_itemmaster_rec.item) = FALSE then
                  return FALSE;
               end if;
               --12-May-2010 Murali  Cr288b End
            elsif L_itemmaster_rec.item_level = 2 and L_itemmaster_rec.tran_level = 2 then
               if TSL_BASE_VARIANT_SQL.VALIDATE_BASE_ITEM(L_error_message,
                                                          L_exists,
                                                          L_itemlist_table(i).item) = FALSE then
                  return FALSE;
               end if;
               if L_exists = TRUE then
                  if TSL_BASE_VARIANT_SQL.VARIANTS_EXISTS(L_error_message,
                                                          L_exists,
                                                          L_itemlist_table(i).item) = FALSE then
                     return FALSE;
                  end if;
                  if L_exists = TRUE then
                     if ITEM_APPROVAL_SQL.TSL_APPROVE_VARIANT(L_error_message,
                                                              L_all_var_approved,
                                                              L_all_children_approved,
                                                              L_itemlist_table(i).item,
                                                              'Y',
                                                              --CR399 Niraj C nirajkumar.choudhary@in.tesco.com Begin
                                                              'Y') = FALSE then
                                                              --CR399 Niraj C nirajkumar.choudhary@in.tesco.com End
                        return FALSE;
                     end if;
                  end if;
               end if;
               update item_master
                  set status = 'A'
                where item   = L_itemlist_table(i).item;
               --12-May-2010 Murali  Cr288b Begin
               if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                                       L_itemmaster_rec.item) = FALSE then
                  return FALSE;
               end if;
               --12-May-2010 Murali  Cr288b End
            elsif L_itemmaster_rec.item_level = 2 and L_itemmaster_rec.tran_level = 2 and
                  L_itemlist_table(i).item != L_itemmaster_rec.tsl_base_item then
               if ITEM_APPROVAL_SQL.TSL_APPROVE_VARIANT(L_error_message,
                                                        L_all_var_approved,
                                                        L_all_children_approved,
                                                        L_itemlist_table(i).item,
                                                        'Y',
                                                        --CR399 Niraj C nirajkumar.choudhary@in.tesco.com Begin
                                                        'Y') = FALSE then
                                                        --CR399 Niraj C nirajkumar.choudhary@in.tesco.com End

                  return FALSE;
               end if;
               if (L_all_var_submitted = FALSE or L_all_children_submitted = FALSE) then
                  L_sub_err_ind := 'Y';
               end if;
               update item_master
                  set status = 'A'
                where item   = L_itemlist_table(i).item;
               --12-May-2010 Murali  Cr288b Begin
               if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                                       L_itemmaster_rec.item) = FALSE then
                  return FALSE;
               end if;
               --12-May-2010 Murali  Cr288b End
            else
               if ((L_itemmaster_rec.item_level = L_itemmaster_rec.tran_level) and (L_itemmaster_rec.Pack_Ind ='Y')) then
                   update item_master
                      set status = 'A'
                    where item   = L_itemlist_table(i).item;
               end if;
               --12-May-2010 Murali  Cr288b Begin
               if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                                       L_itemmaster_rec.item) = FALSE then
                  return FALSE;
               end if;
               --12-May-2010 Murali  Cr288b End
            end if;
         else
            if L_children_approved = FALSE then
               O_sub_appr_ind := 'N';
            end if;
         end if;

             ---
         -- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
         -- 18-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         end if;
         -- 18-Aug-2010, CR354, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
         -- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
      END LOOP;
   end if;

   if L_sub_err_ind = 'Y' then
      O_sub_appr_ind := 'N';
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_sub_appr_ind := 'N';
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_MASS_APPROVE;
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_GET_MERCH_DEPT
-- Purpose       : This function will give the dept,class,subclass of the input Itemlist.
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_MERCH_DEPT(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            I_skulist         IN       SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is

   L_program      VARCHAR2(50):= 'ITEMLIST_ATTRIB_SQL.TSL_GET_MERCH_DEPT';

   cursor C_GET_MERCH_DEPT is
   select distinct im.dept,
          im.class,
          im.subclass
     from item_master im
    where item in (select item
                     from skulist_detail
                    where skulist = I_skulist);

BEGIN

   FOR c_rec IN C_GET_MERCH_DEPT LOOP
      if ITEMLIST_ATTRIB_SQL.UPDATE_ITEM_LIST(O_error_message,
                                              I_skulist,
                                              c_rec.dept,
                                              c_rec.class,
                                              c_rec.subclass) = FALSE then
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
END TSL_GET_MERCH_DEPT;
------------------------------------------------------------------------------------------------------------
--09-Nov-2009   Joy Stephen, joy.johnchristopher@in.tesco.com  CR208 End
------------------------------------------------------------------------------------------------------------
--10-Dec-2009     TESCO HSC/Joy Stephen    DefNBS015700/DefNBS015664     Begin
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_VALIDATE_DATA
-- Purpose       : This function will take the input values of column name and value and then validate.
--                 If there is either a length mismatch or data type mismatch, an error will be returned
--                 to the user.
------------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 04-Aug-2010
-- Mod Ref    : PrfNBS018117
-- Mod Details: We have re-engineered the entire function.
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_DATA(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                           I_column_name    IN      VARCHAR2,
                           I_value          IN      VARCHAR2,
                           --04-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117    Begin
                           I_code_type      IN      VARCHAR2)
                           --04-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117    End
   RETURN BOOLEAN is

   --Declaring the variables
   L_program               VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_VALIDATE_DATA';
   L_tsl_parent_table      TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;
   L_data_type             USER_TAB_COLUMNS.DATA_TYPE%TYPE;
   L_data_length           USER_TAB_COLUMNS.DATA_LENGTH%TYPE;
   L_nullable              USER_TAB_COLUMNS.NULLABLE%TYPE;
   L_sql_stmnt             VARCHAR2(10000);
   L_return_code           VARCHAR2(5);
   L_date                  DATE;
   L_column                DATE;
   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (BEGIN)
   L_error                 EXCEPTION;
   L_value                 VARCHAR2(30);
   PRAGMA EXCEPTION_INIT  (L_error,-2290);
   -- LT DefNBS00015930, 13-Jan-2010, Joy Stephen, Joy.johnchristopher@in.tesco.com (END)

   --04-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117    Begin
   L_exist                VARCHAR2(1);
   L_vdate                DATE := GET_VDATE;
   L_valid               BOOLEAN;
   L_system_option_row   SYSTEM_OPTIONS%ROWTYPE;
   L_code_count          NUMBER;
   PRAGMA EXCEPTION_INIT(L_error,-2290);
   L_seq_no              NUMBER(3);
   L_error_seq_no        EXCEPTION;
   PRAGMA EXCEPTION_INIT(L_error_seq_no,-06502);
   L_brand_ind           VARCHAR2(1);
   L_invalid_value        EXCEPTION;
   PRAGMA EXCEPTION_INIT(L_invalid_value, -02291);
   L_custom_code          TSL_CUSTOM_FIELDS.CUSTOM_CODE%TYPE;
   --04-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117    End

   --This cursor fetches the parent table
   cursor C_GET_TABLE_NAME is
   select parent_table,
          -- DefNBS017055 shweta.madnawat@in.tesco.com  16-Apr-10 Begin
          custom_code
          -- DefNBS017055 shweta.madnawat@in.tesco.com  16-Apr-10 End
     from tsl_custom_fields
    where upper(custom_field_name) = upper(I_column_name);

   --This cursor fetches the data type length
   cursor C_DATA_TYP_LEN is
   select data_type,
          data_length,
          nullable
     from user_tab_columns
    --23-Sep-10  JK  DefNBS019234   Begin
    where table_name  = upper(L_tsl_parent_table)
      and column_name = upper(I_column_name);
    --23-Sep-10  JK  DefNBS019234   End

   --04-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117    Begin
   cursor C_GET_COUNTRY_ID is
   select 'X'
     from dual
    where exists (select 1
                    from user_tab_columns uts
                   where uts.table_name = L_tsl_parent_table
                     --23-Sep-10  JK  DefNBS019234   Begin
                     and uts.column_name = upper('tsl_country_id'));
                     --23-Sep-10  JK  DefNBS019234   End

   cursor C_GET_CODE is
   select code
     from code_detail
    where code_type = I_code_type;

   cursor C_GET_CODE_BR_NBR is
   select code
     from code_detail
    where code_type = 'TBRA';

   cursor C_GET_CODE_NBR is
   select code
     from code_detail
    where code_type = 'TNBR';
   --04-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117    End

BEGIN

   L_code_count := 1;

   if UPPER(I_column_name) = 'TSL_LOW_LVL_SEQ_NO' then
      L_seq_no := TO_NUMBER(I_value);
   end if;

   --Fetching the values from C_GET_TABLE_NAME
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   open C_GET_TABLE_NAME;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   fetch C_GET_TABLE_NAME into L_tsl_parent_table,
                               L_custom_code;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   close C_GET_TABLE_NAME;

   --Fetching the values from C_DATA_TYP_LEN
   SQL_LIB.SET_MARK('OPEN',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_DATA_TYP_LEN;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_DATA_TYP_LEN into L_data_type,L_data_length,L_nullable;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_DATA_TYP_LEN;

   --04-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117    Begin
   -- Fetching the TSL_COUNTRY_ID for the parent table.
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_GET_COUNTRY_ID;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_GET_COUNTRY_ID into L_exist;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_GET_COUNTRY_ID;

   if L_exist is NOT NULL then
      --condition 1
      if (L_nullable = 'N' and I_value is NULL) then
         O_error_message := SQL_LIB.CREATE_MSG('REQ_FIELD_NULL',L_custom_code, NULL, NULL);
         return FALSE;
      else
         --condition 2
         if L_data_type = 'DATE' then
            if I_value <= get_vdate then
               O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_VDATE');
               return FALSE;
            end if;
            if not length(substr(I_value,INSTR(I_value, '-', 1, 2) + 1)) = 2 then
               O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
               return FALSE;
            end if;
         else
            --condition 3
            if length(I_value) > L_data_length then
               O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
               return FALSE;
            else
               if L_data_type = 'NUMBER' then
                  if TSL_IS_NUMBER(O_error_message,
                                   I_value) = FALSE then
                     O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                     return FALSE;
                  end if;
               end if;
               if L_data_type = 'VARCHAR2' then
                  if L_data_length  = 1 then
                     if I_value is NULL then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        return FALSE;
                     end if;
                  end if;
                  if I_code_type is not NULL then
                     if I_code_type in ('TBRA') then
                        for c_rec in C_GET_CODE_BR_NBR LOOP
                           if c_rec.code = I_value then
                              L_code_count := L_code_count+1;
                              L_brand_ind := 'Y';
                           end if;
                        END LOOP;
                     elsif I_code_type in ('TNBR') then
                        for c_rec in C_GET_CODE_NBR LOOP
                           if c_rec.code = I_value then
                              L_code_count := L_code_count+1;
                              L_brand_ind := 'N';
                           end if;
                        END LOOP;
                     else
                        for c_rec in C_GET_CODE LOOP
                           if c_rec.code = I_value then
                              L_code_count := L_code_count+1;
                           end if;
                        END LOOP;
                     end if;
                     if L_code_count = 1 then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        return FALSE;
                     end if;
                  end if;
               end if;
            end if;--condition 3
         end if;--condition 2
      end if;--condition 1
      --
   else
      --condition 1
      if (L_nullable = 'N' and I_value is NULL) then
         O_error_message := SQL_LIB.CREATE_MSG('REQ_FIELD_NULL',L_custom_code, NULL, NULL);
         return FALSE;
      else
         --condition 2
         if L_data_type = 'DATE' then
            if I_value <= L_vdate then
               O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_EFF_DATE');
            end if;
            if not length(substr(I_value,INSTR(I_value, '-', 1, 2) + 1)) = 2 then
               O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
               return FALSE;
            end if;
         else
            --condition 3
            if length(I_value) > L_data_length then
               O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
               return FALSE;
            else
               if L_data_type = 'NUMBER' then
                  if TSL_IS_NUMBER(O_error_message,
                                   I_value) = FALSE then
                     O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                     return FALSE;
                  end if;
               end if;
               if L_data_type = 'VARCHAR2' then
                  if L_data_length  = 1 then
                     if I_value is NULL then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        return FALSE;
                     end if;
                  end if;
                  if I_code_type is not NULL then
                     for c_rec in C_GET_CODE LOOP
                        if c_rec.code = I_value then
                           L_code_count := L_code_count+1;
                        end if;
                     END LOOP;
                     if L_code_count = 1 then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        return FALSE;
                     end if;
                  end if;
                  if upper(I_column_name) = upper('item_desc_secondary') then
                     if system_options_sql.get_system_options(O_error_message,
                                                              L_system_option_row) =  FALSE then
                        return FALSE;
                     end if;
                     if L_system_option_row.tsl_style_ref_ind = 'Y' then
                        if ITEM_MASTER_SQL.TSL_VALIDATE_STYLE_REF(O_error_message,
                                                                  I_value,
                                                                  L_valid)= FALSE then
                           return FALSE;
                        end if;
                     end if;
                     if NOT L_valid then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',''''||I_value||'''',NULL,NULL);
                        return FALSE;
                     end if;
                  end if;
                  if length(I_value) > L_data_length or I_value is NULL then
                     O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                     return FALSE;
                  end if;
               end if;
            end if;--condition 3
         end if;--condition 2
      end if;--condition 1
      --
   end if;
   return TRUE;

EXCEPTION
   when L_error then
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
      return FALSE;
   when L_error_seq_no then
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
      return FALSE;
   when L_invalid_value then
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',
                                            ''''||I_value||'''',
                                            L_custom_code,
                                            NULL);
      return FALSE;
   when OTHERS then
      if L_data_type = 'DATE' then
       O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
       return FALSE;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
   --04-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117    End
END TSL_VALIDATE_DATA;
------------------------------------------------------------------------------------------------------------
--10-Dec-2009     TESCO HSC/Joy Stephen    DefNBS015700/DefNBS015664     End
------------------------------------------------------------------------------------------------------------
--15-Dec-2009     TESCO HSC/Joy Stephen    DefNBS015640     Begin
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_CREATE_ITEMLIST
-- Purpose       : This function will do the security check and creates a new Itemlist.
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_CREATE_ITEMLIST(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_item_tbl         IN       ITEMLIST_ATTRIB_SQL.ITEMLIST_VALUE_TABLE,
                             O_invalid_item_tbl IN OUT   ITEMLIST_ATTRIB_SQL.ITEMLIST_VALUE_TABLE,
                             O_itemlist_number  IN OUT   SKULIST_HEAD.SKULIST%TYPE,
                             I_itemlist_desc    IN       VARCHAR2,
                             O_inval_err_ind    IN OUT   VARCHAR2)
   RETURN BOOLEAN is

   L_program                VARCHAR2(50):= 'ITEMLIST_ATTRIB_SQL.TSL_CREATE_ITEMLIST';
   L_error_message          RTK_ERRORS.RTK_TEXT%TYPE;
   L_itemlist_table         ITEMLIST_ATTRIB_SQL.ITEMLIST_TABLE;
   L_itemmaster_rec         ITEM_MASTER%ROWTYPE;
   L_rec_count              NUMBER(5) :=0;
   L_inval_item_cnt         NUMBER := 1;
   L_val_item_cnt           NUMBER := 1;
   L_curr_item              ITEM_MASTER.ITEM%TYPE;
   L_curr_value             SKULIST_CRITERIA.TSL_VALUE%TYPE;
   L_invalid_item_tbl       ITEMLIST_ATTRIB_SQL.ITEMLIST_VALUE_TABLE;
   L_valid_item_tbl         ITEMLIST_ATTRIB_SQL.ITEMLIST_VALUE_TABLE;
   L_return_code            VARCHAR2(10);
   L_sequence_no            SKULIST_CRITERIA.SEQ_NO%TYPE;
   L_itemlist_number        SKULIST_HEAD.SKULIST%TYPE;
   L_itemlist_desc          VARCHAR2(2000);

   -- LT Def NBS00015930, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
   L_temp_item              ITEM_MASTER.ITEM%TYPE;
   L_temp_value             VARCHAR2(255);
   L_sql_stmnt              VARCHAR2(10000);
   -- LT Def NBS00015930, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
   --This cursor does the security check
   cursor C_SEC_CHECK is
    select count(1)
      from v_subclass
     where (dept,class,subclass ) in (select dept,class,subclass
                                        from item_master
                                        where item = L_curr_item
                                          --21-JAN-10   Wipro/JK    DefNBS00016008    Begin
                                          -- The below check is required to ensure EANs and OCC
                                          -- Barcode items would not be inserted under itemlist.
                                          and item_level <= tran_level);
                                          --21-JAN-10   Wipro/JK    DefNBS00016008    End

   -- LT Def NBS00015930, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
   cursor C_SORT_DUP_ITEM is
   select distinct tsi.item item ,tsi.value value
     from tsl_sort_itemlist_temp tsi
    where rowid= (select max(rowid)
                    from tsl_sort_itemlist_temp
                   where item = tsi.item);
   -- LT Def NBS00015930, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)



BEGIN

   --01-Apr-2010   TESCO HSC/Joy Stephen    DefNBS016596     Begin
   O_invalid_item_tbl.delete;
   --01-Apr-2010   TESCO HSC/Joy Stephen    DefNBS016596     End
   if I_item_tbl is not NULL or I_item_tbl.COUNT > 0 then
      FOR i IN I_item_tbl.FIRST..I_item_tbl.LAST LOOP
         L_curr_item  := I_item_tbl(i).item;
         L_curr_value := I_item_tbl(i).value;
         L_rec_count := 0;

         SQL_LIB.SET_MARK('OPEN',
                          'C_SEC_CHECK',
                          'ITEM_MASTER',
                          'V_subclass: '||L_curr_item);
         open C_SEC_CHECK;

         SQL_LIB.SET_MARK('FETCH',
                          'C_SEC_CHECK',
                          'ITEM_MASTER',
                          'V_subclass: '||L_curr_item);
         fetch C_SEC_CHECK into L_rec_count;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_SEC_CHECK',
                          'ITEM_MASTER',
                          'V_subclass: '||L_curr_item);
         close C_SEC_CHECK;

         if L_rec_count > 0 then
            for i in L_val_item_cnt..L_val_item_cnt LOOP
               L_valid_item_tbl(L_val_item_cnt).item := L_curr_item;
               L_valid_item_tbl(L_val_item_cnt).value := L_curr_value;
               L_val_item_cnt := L_val_item_cnt+1;
            END LOOP;
         elsif L_rec_count = 0 then
            for i in L_inval_item_cnt..L_inval_item_cnt LOOP
               O_invalid_item_tbl(L_inval_item_cnt).item := L_curr_item;
               O_invalid_item_tbl(L_inval_item_cnt).value := L_curr_value;
               L_inval_item_cnt := L_inval_item_cnt+1;
            END LOOP;
         end if;
      END LOOP;
   end if;
   if L_valid_item_tbl is not NULL or L_valid_item_tbl.COUNT > 0 then
      NEXT_SKULIST_NUMBER(O_itemlist_number,
                          L_return_code,
                          O_error_message);
      if L_return_code = 'FALSE' then
         return FALSE;
      end if;
      insert into skulist_head values(O_itemlist_number,
                                      I_itemlist_desc,
                                      GET_VDATE(),
                                      user,
                                      'N',
                                      GET_VDATE(),
                                      'N',
                                      'N',
                                      'Item list uploaded using CSV file',
                                      null);

      FOR i IN 1..L_valid_item_tbl.COUNT LOOP
         L_sql_stmnt := 'insert into tsl_sort_itemlist_temp values (:1, :2)';
         EXECUTE IMMEDIATE  L_sql_stmnt USING  L_valid_item_tbl(i).item,L_valid_item_tbl(i).value ;
      END LOOP;
        -- LT Def NBS00015930, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
      FOR rec in C_SORT_DUP_ITEM LOOP
         if rec.value is NULL then
            if ITEMLIST_ADD_SQL.INSERT_SKULIST_DETAIL(O_error_message,
                                                      O_itemlist_number,
                                                      rec.item,
                                                      null) = FALSE then
               return FALSE;
            end if;
         else
            if ITEMLIST_ADD_SQL.TSL_POPULATE_TEMP(O_error_message,
                                                  O_itemlist_number,
                                                  rec.item,
                                                  rec.value) = FALSE then
               return FALSE;
            end if;
            if ITEMLIST_ADD_SQL.INSERT_SKULIST_DETAIL(O_error_message,
                                                   O_itemlist_number,
                                                   rec.item,
                                                   null) = FALSE then
               return FALSE;
            end if;
         end if;
         if ITEMLIST_BUILD_SQL.GET_MAX_SEQUENCE_NO(L_error_message,
                                                   L_sequence_no,
                                                  O_itemlist_number) = FALSE then
            return FALSE;
         end if;
         if ITEMLIST_BUILD_SQL.INSERT_CRITERIA(O_itemlist_number,
                                               L_sequence_no,
                                               'A',
                                                rec.item,
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
                                                rec.value,
                                                L_error_message) = FALSE then
             return FALSE;
         end if;
      END LOOP;
      -- LT Def NBS00015930, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)
   end if;

   --17-Dec-2009    TESCO HSC/Joy Stephen    DefNBS015736   Begin
   if L_val_item_cnt = 1 and L_inval_item_cnt > 1 then
      O_inval_err_ind := 'Y';
   elsif L_val_item_cnt > 1 and L_inval_item_cnt > 1 then
      O_inval_err_ind := 'N';
   elsif L_val_item_cnt > 1 and L_inval_item_cnt = 1 then
      O_inval_err_ind := NULL;
   end if;
   --17-Dec-2009    TESCO HSC/Joy Stephen    DefNBS015736   End
   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CREATE_ITEMLIST;
---------------------------------------------------------------------------------------------
-- 15-Dec-2009     TESCO HSC/Joy Stephen    DefNBS015640     End
---------------------------------------------------------------------------------------------
-- LT Def NBS00015722, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (BEGIN)
---------------------------------------------------------------------------------------------
-- Function Name : TSL_CASCADE_VALUES
-- Purpose       : This function will cascade the value to its childrens.
---------------------------------------------------------------------------------------------
FUNCTION TSL_CASCADE_VALUES (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_tsl_parent_table IN       VARCHAR2,
                             I_column_name      IN       VARCHAR2,
                             I_value            IN       VARCHAR2,
                             I_item             IN       ITEM_MASTER.ITEM%TYPE,
                             I_country_id       IN       VARCHAR2,
                             --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
                             I_code_type        IN       VARCHAR2,
                             --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
                             -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                             -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                             -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                             I_login_ctry     IN      VARCHAR2
                             -- 14-Apr-11     Nandini M     PrfNBS022237     End
                             -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                             -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                             )
   RETURN BOOLEAN is

   L_program                VARCHAR2(50):= 'ITEMLIST_ATTRIB_SQL.TSL_CASCADE_VALUES';
   L_error_message          RTK_ERRORS.RTK_TEXT%TYPE;
   L_sql_stmnt              VARCHAR2(10000);
   L_pack_ind               ITEM_MASTER.PACK_IND%TYPE;
   L_brand_ind              VARCHAR2(1);
   L_epw_ind                item_attributes.tsl_epw_ind%type;
   L_end_date               item_attributes.tsl_end_date%type;
   L_pack_no                ITEM_MASTER.ITEM_PARENT%TYPE;
   -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
   L_ATTR_ID                 CODE_DETAIL.CODE%TYPE;
   L_ATTR_EXC_EXISTS         BOOLEAN:=FALSE;
   -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End

   CURSOR C_GET_PACK_DETAIL is
    select item,
           im.status,
           im.item_number_type,
           im.item_level,
           im.item_parent,
           im.tran_level
      from item_master im
     start with im.item = I_item
     connect by prior im.item = im.item_parent;

   CURSOR C_GET_ITEM_DETAIL is
    select item,
           im.status,
           im.item_number_type,
           im.item_level,
           im.item_parent,
           im.tran_level
      from item_master im
     start with im.item = I_item
     connect by prior im.item = im.item_parent
    union
    select item,
           im.status,
           im.item_number_type,
           im.item_level,
           im.item_parent,
           im.tran_level
      from item_master im
     start with  im.tsl_base_item = I_item
     connect by prior im.item = im.item_parent
     order by 4;

   CURSOR C_VALIDATE_ITEM is
    select im.pack_ind
      from packitem pi,
           item_master im
     where im.item       = I_item
       and pi.pack_no(+) = im.item;

   CURSOR C_GET_PACKS is
    select pack_no
      from packitem pi
     where pi.item = I_item;

   CURSOR C_GET_OCC is
    select item
      from item_master im
     where im.item_parent = L_pack_no;
-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
   CURSOR C_GET_ATTR_ID is
   select tsl_code
     from tsl_map_item_attrib_code
    where tsl_column_name=UPPER(I_column_name);
-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End

BEGIN
   --cursor for non pack item.
   SQL_LIB.SET_MARK('OPEN', 'C_VALIDATE_ITEM', 'ITEM_MASTER', NULL);
   open C_VALIDATE_ITEM;

   SQL_LIB.SET_MARK('FETCH', 'C_VALIDATE_ITEM', 'ITEM_MASTER', NULL);
   fetch C_VALIDATE_ITEM INTO L_pack_ind;

   SQL_LIB.SET_MARK('CLOSE', 'C_VALIDATE_ITEM', 'ITEM_MASTER', NULL);
   close C_VALIDATE_ITEM;
   --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
   if I_code_type = 'TBRA' then
      L_brand_ind := 'Y';
   elsif I_code_type = 'TNBR'then
      L_brand_ind := 'N';
   end if;
   --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
   -- CR258 26-Apr-2010 Chandru Begin
   if upper(I_tsl_parent_table) = 'ITEM_ATTRIBUTES' then
		 -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
		   SQL_LIB.SET_MARK('OPEN',
							'C_GET_ATTR_ID',
							'TSL_MAP_ITEM_ATTRIB_CODE',
							'I_column_name: '||I_column_name);
		   open C_GET_ATTR_ID;

		   SQL_LIB.SET_MARK('FETCH',
							'C_GET_ATTR_ID',
							'TSL_MAP_ITEM_ATTRIB_CODE',
							'I_column_name: '||I_column_name);
		   fetch C_GET_ATTR_ID into L_ATTR_ID;

		   SQL_LIB.SET_MARK('CLOSE',
							'C_GET_ATTR_ID',
							'TSL_MAP_ITEM_ATTRIB_CODE',
							'I_column_name: '||I_column_name);
		   close C_GET_ATTR_ID;
		   if TSL_ATTR_STPCAS_EXISTS(O_error_message,
                 L_ATTR_ID,
								 L_ATTR_EXC_EXISTS)=FALSE then
					return FALSE;
		   end if;

	if L_ATTR_EXC_EXISTS=FALSE then
 -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End

      if I_country_id = 'B' then
         if NOT ITEM_ATTRIB_DEFAULT_SQL.COPY_DOWN_PARENT_ATTRIB(L_error_message,
                                                                I_item,
                                                                'U',
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                                                I_login_ctry,
                                                                I_column_name
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237     End
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                                                                ) then
            return FALSE;
         end if;
         if NOT ITEM_ATTRIB_DEFAULT_SQL.COPY_DOWN_PARENT_ATTRIB(L_error_message,
                                                                I_item,
                                                                'R',
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                                                I_login_ctry,
                                                                I_column_name
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237     End
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                                                                ) then
            return FALSE;
         end if;
      else
         if NOT ITEM_ATTRIB_DEFAULT_SQL.COPY_DOWN_PARENT_ATTRIB(L_error_message,
                                                                I_item,
                                                                I_country_id,
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237     Begin
                                                                I_login_ctry,
                                                                I_column_name
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237     End
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                                                                ) then
            return FALSE;
         end if;
      end if;
 -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
    end if;
 -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
   end if;

   -- CR258 26-Apr-2010 Chandru End
   --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
   -- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
   --UATDefNBS019211, 17-Sep-2010,sripriya,Sripriya.karanam@in.tesco.com (Begin)
   if upper(I_tsl_parent_table) = 'ITEM_MASTER' and
      upper(I_column_name) = 'ITEM_DESC_SECONDARY' then
      if item_master_sql.tsl_cascade_style_ref(L_error_message,
                                               I_value,
                                               I_item,
                                               'Y',
                                               'N') = FALSE then
         return FALSE;
      end if;
   end if;
   --CR434 shweta.madnawat@in.tesco.com, 25-Oct-2011, Begin
   if upper(I_tsl_parent_table) = 'ITEM_MASTER' and
      upper(I_column_name) = 'TSL_RESTRICT_PRICE_EVENT' then
      if ITEM_MASTER_SQL.TSL_CASCADE_RESTRICT_PCEV(L_error_message,
                                                   I_item,
                                                   I_value,
                                                   I_login_ctry) = FALSE then
         return FALSE;
      end if;
   end if;
   --CR434 shweta.madnawat@in.tesco.com, 25-Oct-2011, End
   --UATDefNBS019211, 17-Sep-2010,sripriya,Sripriya.karanam@in.tesco.com (End)
   -- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end

   if L_pack_ind = 'Y' then
      FOR rec IN C_GET_PACK_DETAIL LOOP
      if I_country_id is NOT NULL then
         if I_country_id = 'B' then
            --SIT DefNBS017261, 30-Apr-2010, shireen.sheosunker@uk.tesco.com (Begin)
            if I_column_name = 'tsl_end_date' then
 -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
			  if L_ATTR_EXC_EXISTS=FALSE then
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item;
				end if;
-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
            elsif I_column_name = 'tsl_epw_ind' then
 -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
			   if L_ATTR_EXC_EXISTS=FALSE then
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item;
			   end if;
 		    elsif (I_tsl_parent_table='ITEM_ATTRIBUTES' and L_ATTR_EXC_EXISTS=FALSE) or I_tsl_parent_table!='ITEM_ATTRIBUTES' then
-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
            --SIT DefNBS017261, 30-Apr-2010, shireen.sheosunker@uk.tesco.com (End)
               L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = ' ||''''|| rec.item||'''';
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
               end if;
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
               EXECUTE IMMEDIATE L_sql_stmnt;
            end if;
            --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (Begin)
         -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
		 if L_ATTR_EXC_EXISTS=FALSE then
            FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item;
                        end if;
                     END LOOP;
            END LOOP;
          end if;
          -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
            --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (End)
         else
            if I_column_name = 'tsl_end_date' then
               -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
			   if L_ATTR_EXC_EXISTS=FALSE then
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item and tsl_country_id = I_country_id;
				end if;
				-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
            elsif I_column_name = 'tsl_epw_ind' then
              --SIT DefNBS017461, 13-May-2010, shireen.sheosunker@uk.tesco.com (Begin)
              -- reset the epw_ind to 'N' before updating by country
              -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
			   if L_ATTR_EXC_EXISTS=FALSE then
                  update item_attributes
                     set tsl_epw_ind = 'N', tsl_end_date = null
                   where item = rec.item;
              --SIT DefNBS017461, 13-May-2010, shireen.sheosunker@uk.tesco.com (End)
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item and tsl_country_id = I_country_id;
			   end if;
		      elsif (I_tsl_parent_table='ITEM_ATTRIBUTES' and L_ATTR_EXC_EXISTS=FALSE) or I_tsl_parent_table!='ITEM_ATTRIBUTES' then
			  -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
               L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm' ||
                           ' and tsl_country_id = :I_country_id';
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
               end if;
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
               EXECUTE IMMEDIATE L_sql_stmnt using rec.item,I_country_id;
            end if;
            --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (Begin)
            -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
		 if L_ATTR_EXC_EXISTS=FALSE then
            FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no and tsl_country_id = I_country_id;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no and tsl_country_id = I_country_id;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item and tsl_country_id = I_country_id;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item and tsl_country_id = I_country_id;
                        end if;
                     END LOOP;
            END LOOP;
           end if;
		   -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
            --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (End)
         end if;
      else
         if I_column_name = 'tsl_end_date' then
             -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
			 if L_ATTR_EXC_EXISTS=FALSE then
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item;
			 end if;
         elsif I_column_name = 'tsl_epw_ind' then
	   -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
			if L_ATTR_EXC_EXISTS=FALSE then
       -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item;
			 end if;
         elsif (I_tsl_parent_table='ITEM_ATTRIBUTES' and L_ATTR_EXC_EXISTS=FALSE) or I_tsl_parent_table!='ITEM_ATTRIBUTES' then
			  -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
               L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                          --28-Sep-10     praveen     PefNBS018117     Begin
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm';
                          --28-Sep-10     praveen     PefNBS018117     End
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
               end if;
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
               --28-Sep-10     praveen     PefNBS018117     Begin
               EXECUTE IMMEDIATE L_sql_stmnt  using rec.item;
               --28-Sep-10     praveen     PefNBS018117     End
         end if;
         --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (Begin)
         -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
		 if L_ATTR_EXC_EXISTS=FALSE then
         -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
         FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item;
                        end if;
                     END LOOP;
         END LOOP;
 -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
  		 end if;
  -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
         --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (End)
      end if;
      END LOOP;
   else
    FOR rec IN C_GET_ITEM_DETAIL LOOP
      if  I_country_id is NOT NULL then
         if I_country_id = 'B' then
            if I_column_name = 'tsl_end_date' then
                -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
				 if L_ATTR_EXC_EXISTS=FALSE then
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item;
				 end if;
            elsif I_column_name = 'tsl_epw_ind' then
            	 if L_ATTR_EXC_EXISTS=FALSE then
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item;
				 end if;
            elsif (I_tsl_parent_table='ITEM_ATTRIBUTES' and L_ATTR_EXC_EXISTS=FALSE) or I_tsl_parent_table!='ITEM_ATTRIBUTES' then
               -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 09-Oct-12, Begin
               if rec.item_number_type = 'VAR' and rec.item <> I_item then
                  if lower(I_column_name) <> 'tsl_launch_date' then
                     L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm';
                     EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
                  end if;
               elsif rec.item_level = 3 and rec.tran_level = 2 then
                  if lower(I_column_name) <> 'tsl_launch_date' then
                     L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm';
                     EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
                  end if;
               else
                   L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm';
                   EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
               end if;

               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
                  EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
               end if;
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
               --28-Sep-10     praveen     PefNBS018117     Begin
               --EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
               --28-Sep-10     praveen     PefNBS018117     End
               -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 09-Oct-12, End
            end if;
			-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
            --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (Begin)
            -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
		 if L_ATTR_EXC_EXISTS=FALSE then
            FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item;
                        end if;
                     END LOOP;
            END LOOP;
         end if;
	-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
            --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (End)
         else
            if I_column_name = 'tsl_end_date' then
               -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
		     if L_ATTR_EXC_EXISTS=FALSE then
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item and tsl_country_id = I_country_id;
			 end if;
            elsif I_column_name = 'tsl_epw_ind' then
              --SIT DefNBS017461, 13-May-2010, shireen.sheosunker@uk.tesco.com (Begin)
              -- reset the epw_ind to 'N' before updating by country
                 if L_ATTR_EXC_EXISTS=FALSE then
                  update item_attributes
                     set tsl_epw_ind = 'N', tsl_end_date = null
                   where item = rec.item;
              --SIT DefNBS017461, 13-May-2010, shireen.sheosunker@uk.tesco.com (End)
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item and tsl_country_id = I_country_id;
				 end if;
            elsif (I_tsl_parent_table='ITEM_ATTRIBUTES' and L_ATTR_EXC_EXISTS=FALSE) or I_tsl_parent_table!='ITEM_ATTRIBUTES' then
               -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 09-Oct-12, Begin
               if rec.item_number_type = 'VAR' and rec.item <> I_item then
                  if lower(I_column_name) <> 'tsl_launch_date' then
                     L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm' ||
                           ' and tsl_country_id = :I_country_id';
                     EXECUTE IMMEDIATE L_sql_stmnt using rec.item,I_country_id;
                  end if;
               elsif rec.item_level = 3 and rec.tran_level = 2 then
                  if lower(I_column_name) <> 'tsl_launch_date' then
                     L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm' ||
                           ' and tsl_country_id = :I_country_id';
                     EXECUTE IMMEDIATE L_sql_stmnt using rec.item,I_country_id;
                  end if;
               else
                   L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           --28-Sep-10     praveen     PefNBS018117     Begin
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm' ||
                           ' and tsl_country_id = :I_country_id';
                           --28-Sep-10     praveen     PefNBS018117     End
                   EXECUTE IMMEDIATE L_sql_stmnt using rec.item,I_country_id;
               end if;

               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
                  EXECUTE IMMEDIATE L_sql_stmnt using rec.item,I_country_id;
               end if;
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
               --28-Sep-10     praveen     PefNBS018117     Begin
               --EXECUTE IMMEDIATE L_sql_stmnt using rec.item,I_country_id;
               --28-Sep-10     praveen     PefNBS018117     End
               -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 09-Oct-12, End
            end if;
		-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
            --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (Begin)
            -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
		 if L_ATTR_EXC_EXISTS=FALSE then
            FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no and tsl_country_id = I_country_id;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no and tsl_country_id = I_country_id;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item and tsl_country_id = I_country_id;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item and tsl_country_id = I_country_id;
                        end if;
                     END LOOP;
            END LOOP;
         end if;
         -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
            --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (End)
         end if;
      else
          if I_column_name = 'tsl_end_date' then
               -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
			if L_ATTR_EXC_EXISTS=FALSE then
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item;
			end if;
          elsif I_column_name = 'tsl_epw_ind' then
            -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
			if L_ATTR_EXC_EXISTS=FALSE then
            -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item;
            -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
						end if;
            -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
          else
		    if (I_tsl_parent_table='ITEM_ATTRIBUTES' and L_ATTR_EXC_EXISTS=FALSE) or I_tsl_parent_table!='ITEM_ATTRIBUTES' then
             -- CR434 shweta.madnawat@in.tesco.com 28-Oct-2011, Begin
             if upper(I_column_name) != upper('tsl_restrict_price_event') then
             -- CR434 shweta.madnawat@in.tesco.com 28-Oct-2011, End
                -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 09-Oct-12, Begin
               if rec.item_number_type = 'VAR' and rec.item <> I_item then
                  if lower(I_column_name) <> 'tsl_launch_date' then
                      L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                               ' set ' || I_column_name || ' = '''||I_value ||'''
                               where item = :itm';
                     EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
                  end if;
               elsif rec.item_level = 3 and rec.tran_level = 2 then
                  if lower(I_column_name) <> 'tsl_launch_date' then
                      L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                               ' set ' || I_column_name || ' = '''||I_value ||'''
                               where item = :itm';
                     EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
                  end if;
               else
                    L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                               --28-Sep-10     praveen     PefNBS018117     Begin
                               ' set ' || I_column_name || ' = '''||I_value ||'''
                               where item = :itm';
                               --28-Sep-10     praveen     PefNBS018117     End
                   EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
               end if;
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (Begin)
               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
                  EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
               end if;
			 end if;
			    -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
               --SIT DefNBS016539, 15-Mar-2010, sripriya,Sripriya.karanam@in.tesco.com (End)
               --28-Sep-10     praveen     PefNBS018117     Begin
               --EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
               --28-Sep-10     praveen     PefNBS018117     End
               -- DefNBS025514/PM017007, Vinutha Raju, vinutha.raju@in.tesco.com, 09-Oct-12, End
-- LTDefNBS018715 , 11-Aug-2010 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
-- the follwoing code using for cascading the items
                 if   ITEM_MASTER_SQL.TSL_CASCADE_STYLE_REF(O_error_message,
                                                          I_value,
                                                          rec.item,
                                                          'N',
                                                          'N') = FALSE then
                     return FALSE;
                 end if;
 -- LTDefNBS018715 , 11-Aug-2010 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
             end if;
          end if;
          --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (Begin)
          -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
		 if L_ATTR_EXC_EXISTS=FALSE then
          FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item;
                        end if;
                     END LOOP;
          END LOOP;
		 end if;
		 -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
          --SIT DefNBS017261, 10-May-2010, shireen.sheosunker@uk.tesco.com (End)
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
END TSL_CASCADE_VALUES;
---------------------------------------------------------------------------------------------
-- LT Def NBS00015722, 18-Dec-2009, Vinod Patalappa, vinod.patalappa@in.tesco.com (END)-
---------------------------------------------------------------------------------------------
-- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (BEGIN)
---------------------------------------------------------------------------------------------
-- Function Name : TSL_VALIDATE_DATATYPE
-- Purpose       : This function validates the datatype for the input field and returns the value.
---------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_DATATYPE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               I_column_name    IN      VARCHAR2,
                               O_datatype_ind   IN OUT  VARCHAR2)
   RETURN BOOLEAN is

   L_program               VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_VALIDATE_DATATYPE';
   L_tsl_parent_table      TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;
   L_data_type             USER_TAB_COLUMNS.DATA_TYPE%TYPE;

   --This cursor fetches the parent table
   cursor C_GET_TABLE_NAME is
   select parent_table
     from tsl_custom_fields
    where upper(custom_field_name) = upper(I_column_name);

   --This cursor fetches the data type length
   cursor C_DATA_TYP_LEN is
   select data_type
     from user_tab_columns
    --23-Sep-10  JK  DefNBS019234   Begin
    where table_name  = upper(L_tsl_parent_table)
      and column_name = upper(I_column_name);
    --23-Sep-10  JK  DefNBS019234   End

BEGIN

   --Fetching the values from C_GET_TABLE_NAME
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   open C_GET_TABLE_NAME;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   fetch C_GET_TABLE_NAME into L_tsl_parent_table;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   close C_GET_TABLE_NAME;

   --Fetching the values from C_DATA_TYP_LEN
   SQL_LIB.SET_MARK('OPEN',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_DATA_TYP_LEN;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_DATA_TYP_LEN into L_data_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_DATA_TYP_LEN;

   if L_data_type = 'DATE' then
      O_datatype_ind := 'Y';
   else
      O_datatype_ind := 'N';
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_VALIDATE_DATATYPE;
---------------------------------------------------------------------------------------------
-- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (END)
---------------------------------------------------------------------------------------------
-- SIT DefNBS016539, 18-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
---------------------------------------------------------------------------------------------
FUNCTION TSL_MASS_ITEM_CHANGE_CHECK(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_column_name    IN      VARCHAR2,
                                    -- DefNBS021885, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 11-Mar-2011 Begin
                                    --I_itemlist     IN      skulist_head.skulist%TYPE,
                                    I_itemlist       IN      skulist_detail.item%TYPE,
                                    -- DefNBS021885, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 11-Mar-2011 End
                                    I_code_type      IN      VARCHAR2,
                                    -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
                                    I_value          IN      VARCHAR2)
                                    -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
RETURN BOOLEAN IS
   L_program       VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_MASS_ITEM_CHANGE_CHECK';
   L_value         Varchar2(1);
   L_brand_ind     VARCHAR2(1);
   L_itemlist_tab  ITEMLIST_ATTRIB_SQL.ITEMLIST_TABLE;
   -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
   L_valid         Varchar2(1);
   -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
   cursor c_get_brandind(L_item varchar2) is
   select tsl_brand_ind
     from item_attributes
    where item = L_item;

   --CR434 shweta.madnawat@in.tesco.com 10-Nov-2011, Begin
   L_exist VARCHAR2(1);
   --CR434 vatan.jaiswal@in.tesco.com 13-Nov-2011, Begin
   L_itemlist  SKULIST_DETAIL.SKULIST%TYPE;

   CURSOR C_get_itemlist is
      select skulist
        from skulist_detail
       where item = I_itemlist;
   --CR434 vatan.jaiswal@in.tesco.com 13-Nov-2011, End
   CURSOR C_itemlist_exist is
      select 'X'
        from skulist_head
       where skulist = L_itemlist;
   --CR434 shweta.madnawat@in.tesco.com 10-Nov-2011, End
BEGIN
   --CR434 vatan.jaiswal@in.tesco.com 13-Nov-2011, Begin
   open C_get_itemlist;
   fetch C_get_itemlist into L_itemlist;
   close C_get_itemlist;
   --CR434 vatan.jaiswal@in.tesco.com 13-Nov-2011, End
   --CR434 shweta.madnawat@in.tesco.com 10-Nov-2011, Begin
   open C_itemlist_exist;
   fetch C_itemlist_exist into L_exist;
   close C_itemlist_exist;
   if L_exist is not null then
   --CR434 shweta.madnawat@in.tesco.com 10-Nov-2011, End
      -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
      --CR434 vatan.jaiswal@in.tesco.com 13-Nov-2011, Begin
      if ITEMLIST_ATTRIB_SQL.GET_ITEMLIST_ITEMS(O_error_message,
                                                L_itemlist_tab,
                                                L_itemlist) = FALSE then
         return FALSE;
      end if;
      --CR434 vatan.jaiswal@in.tesco.com 13-Nov-2011, End
      -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
      if I_column_name = 'tsl_brand' then
         if I_code_type = 'TBRA'   then
            L_value := 'Y';
         elsif I_code_type = 'TNBR'   then
            L_value := 'N';
         end if;
         -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
         -- removed the code and added it after BEGIN to genaralise for all the values of I_column_name.
         -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
         --
         if L_itemlist_tab.count > 0 then
            FOR i in L_itemlist_tab.FIRST..L_itemlist_tab.LAST
            LOOP
               SQL_LIB.SET_MARK('OPEN', 'C_GET_BRANDIND', 'ITEM_ATTRIBUTES', NULL);
               open c_get_brandind(L_itemlist_tab(i).item);
               SQL_LIB.SET_MARK('FETCH', 'C_GET_BRANDIND', 'ITEM_ATTRIBUTES', NULL);
               fetch c_get_brandind into L_brand_ind;
               if L_value != L_brand_ind then
                  O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_MASS_VALUE',
                                                        NULL,
                                                        NULL,
                                                        NULL);
                  return FALSE;
               end if;
               SQL_LIB.SET_MARK('CLOSE', 'C_GET_BRANDIND', 'ITEM_ATTRIBUTES', NULL);
               close  c_get_brandind;
            END LOOP;
         end if;
      end if;
      -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
      if upper(I_column_name) = 'DEF_PREF_PACK' then
         -- DefNBS024390, 29-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com Begin
         --Commented the loop because the same I_value (Pref Pack ) is passed against all the items in the list which fails the validation.
         /*if L_itemlist_tab.count > 0 then
            FOR i in L_itemlist_tab.FIRST..L_itemlist_tab.LAST
            LOOP*/
         -- DefNBS024390, 29-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com End
               if TSL_SUPPLY_CHAIN_ATTRIB_SQL.CHECK_PREF_PACK(O_error_message,
                                                              L_valid,
                                                              -- SIT DefNBS016385, 16-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
                                                              I_value,
                                                              -- SIT DefNBS016385, 16-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
                                                              -- DefNBS024390, 29-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com Begin
                                                              --L_itemlist_tab(i).item
                                                              -- DefNBS024390, 29-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com End
                                                              I_itemlist ) = FALSE then
                  return FALSE;
               end if;
               if L_valid = 'N' then
                  O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_PREF_PACK',
                                                        NULL,
                                                        NULL,
                                                        NULL);

                  return FALSE;
               end if;
           -- DefNBS024390, 29-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com Begin
           /* END LOOP;
         end if;*/
         -- DefNBS024390, 29-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com End
      end if;
      -- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_MASS_ITEM_CHANGE_CHECK;
---------------------------------------------------------------------------------------------
-- SIT DefNBS016539, 18-Mar-2010, Sripriya, sripriya.karanam@in.tesco.com (END)
---------------------------------------------------------------------------------------------
--08-Apr-10     JK     Mrg0NBS016979    Begin
---------------------------------------------------------------------------------------------
-- DefNBS016916, 07-Apr-2010, Shireen Sheosunker, shireen.sheosunker@uk.tesco.com
---------------------------------------------------------------------------------------------
-- Function Name : TSL_VALIDATE_DATATYPE_RESTRICT
-- Purpose       : This function validates the datatype for the input field and returns the value.
---------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_DATATYPE_RESTRICT(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               I_column_name    IN      VARCHAR2,
                               O_datatype_ind   IN OUT  VARCHAR2)
   RETURN BOOLEAN is

   L_program               VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_VALIDATE_DATATYPE_RESTRICT';
   L_tsl_parent_table      TSL_REST_FIELDS.REST_PARENT_TABLE%TYPE;
   L_data_type             USER_TAB_COLUMNS.DATA_TYPE%TYPE;

   --This cursor fetches the parent table
   cursor C_GET_TABLE_NAME is
   select rest_parent_table
     from tsl_rest_fields
    where upper(rest_custom_field_name) = upper(I_column_name);

   --This cursor fetches the data type length
   cursor C_DATA_TYP_LEN is
   select data_type
     from user_tab_columns
    --23-Sep-10  JK  DefNBS019234   Begin
    where table_name  = upper(L_tsl_parent_table)
      and column_name = upper(I_column_name);
    --23-Sep-10  JK  DefNBS019234   End

BEGIN

   --Fetching the values from C_GET_TABLE_NAME
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TABLE_NAME',
                    'TSL_REST_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   open C_GET_TABLE_NAME;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TABLE_NAME',
                    'TSL_REST_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   fetch C_GET_TABLE_NAME into L_tsl_parent_table;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TABLE_NAME',
                    'TSL_REST_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   close C_GET_TABLE_NAME;

   --Fetching the values from C_DATA_TYP_LEN
   SQL_LIB.SET_MARK('OPEN',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_DATA_TYP_LEN;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_DATA_TYP_LEN into L_data_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_DATA_TYP_LEN;

   if L_data_type = 'DATE' then
      O_datatype_ind := 'Y';
   else
      O_datatype_ind := 'N';
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_VALIDATE_DATATYPE_RESTRICT;
--08-Apr-10     JK     Mrg0NBS016979    End
------------------------------------------------------------------------------------------------
-- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (Begin)
---------------------------------------------------------------------------------------------
-- Function Name : TSL_VALIDATE
-- Purpose       : To validate the default Pref Pack for the associated TPNB.
---------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      I_column_name    IN      VARCHAR2,
                      I_item           IN      ITEM_MASTER.ITEM%TYPE,
                      I_value          IN      VARCHAR2)
   RETURN BOOLEAN is
   L_program    VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_VALIDATE';
   L_valid      VARCHAR2(1);
BEGIN
   if upper(I_column_name) = 'DEF_PREF_PACK' then
      if TSL_SUPPLY_CHAIN_ATTRIB_SQL.CHECK_PREF_PACK(O_error_message,
                                                     L_valid,
                                                     I_value,
                                                     I_item) = FALSE then
         return FALSE;
      end if;

      if L_valid = 'N' then
         O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_PREF_PACK',
                                               NULL,
                                               NULL,
                                               NULL);
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
END TSL_VALIDATE;
------------------------------------------------------------------------------------------------
-- SIT DefNBS016385, 15-Apr-2010, Sripriya, sripriya.karanam@in.tesco.com (End)
------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- 06-Aug-2010, Phil Noon, phil.noon@in.tesco.com, DefNBS017227, Start
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_MASS_UPDATE_ITEM_CTRY
-- Purpose       : This function will update tsl_country_auth_ind for all approved items on an itemlist
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_MASS_UPDATE_ITEM_CTRY(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_itemlist       IN      VARCHAR2)
   RETURN BOOLEAN is

   L_program                    VARCHAR2(50):= 'ITEMLIST_ATTRIB_SQL.TSL_MASS_UPDATE_ITEM_CTRY';
   L_error_message              RTK_ERRORS.RTK_TEXT%TYPE;
   L_itemlist_table             ITEMLIST_ATTRIB_SQL.ITEMLIST_TABLE;
   L_itemmaster_rec             ITEM_MASTER%ROWTYPE;

BEGIN

   if ITEMLIST_ATTRIB_SQL.GET_ITEMLIST_ITEMS(L_error_message,
                                             L_itemlist_table,
                                             I_itemlist) = FALSE then
      return FALSE;
   end if;

   if L_itemlist_table is NOT NULL and L_itemlist_table.COUNT > 0 then
      FOR i in 1 .. L_itemlist_table.COUNT LOOP
         if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(L_error_message,
                                            L_itemmaster_rec,
                                            L_itemlist_table(i).item) = FALSE then
            return FALSE;
         end if;

         if L_itemmaster_rec.item_level = 1 and
            L_itemmaster_rec.tran_level = 2 and
            L_itemmaster_rec.pack_ind   = 'N'
         then
            if ITEM_MASTER_SQL.TSL_TPNB_UPDATE_ITEM_CTRY(O_error_message,
                                                         L_itemmaster_rec.item) = FALSE then
               return FALSE;
            end if;
         else
            if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                                    L_itemmaster_rec.item) = FALSE then
               return FALSE;
            end if;
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
END TSL_MASS_UPDATE_ITEM_CTRY;
----------------------------------------------------------------------------------------------------
-- 06-Aug-2010, Phil Noon, phil.noon@in.tesco.com, DefNBS017227, End
----------------------------------------------------------------------------------------------------
-- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, begin
-- 09-Aug-2010 Tesco HSC/Usha Patil                    Mod: CR354 Begin
---------------------------------------------------------------------------------------------
--Function Name : TSL_SHARED_ITEM_EXISTS
-- Purpose      : To Check if the shared item exists in the itemlist.
---------------------------------------------------------------------------------------------
FUNCTION TSL_SHARED_ITEM_EXISTS (O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_shrd_itm_exits    OUT  VARCHAR2,
                                 I_skulist        IN      SKULIST_DETAIL.SKULIST%TYPE)
   RETURN BOOLEAN is
   L_program    VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_SHARED_ITEM_EXISTS';

   cursor C_SHARED_ITEM_EXISTS is
   select 'Y'
     from skulist_detail sku,
          item_master iem
    where sku.skulist = I_skulist
      and sku.item = iem.item
      and iem.tsl_country_auth_ind = 'B'
      and iem.status = 'A'
      and rownum = 1;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_SHARED_ITEM_EXISTS',
                    'SKULIST_DETAIL',
                    'skulist: '||I_skulist);
   open C_SHARED_ITEM_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_SHARED_ITEM_EXISTS',
                    'SKULIST_DETAIL',
                    'skulist: '||I_skulist);
   fetch C_SHARED_ITEM_EXISTS into O_shrd_itm_exits;

   if C_SHARED_ITEM_EXISTS%NOTFOUND then
      O_shrd_itm_exits := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_SHARED_ITEM_EXISTS',
                    'SKULIST_DETAIL',
                    'skulist: '||I_skulist);
   close C_SHARED_ITEM_EXISTS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_SHARED_ITEM_EXISTS;
----------------------------------------------------------------------------------------------------
--Function : TSL_VALID_ITEMLIST_SEC
--Purpose  : This function validates the user security to access the items in the item list.
---------------------------------------------------------------------------------------------
FUNCTION TSL_VALID_ITEMLIST_SEC (O_error_message    IN OUT VARCHAR2,
                                 O_valid            IN OUT BOOLEAN,
                                 I_skulist          IN     SKULIST_DETAIL.SKULIST%TYPE,
                                 I_user_loc         IN     VARCHAR2,
                                 I_mode_access      IN     VARCHAR2)
RETURN BOOLEAN is

   L_program         VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.TSL_VALID_ITEMLIST_SEC';
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

      if (I_user_loc = L_item_own_ctry or I_user_loc = 'B') and I_mode_access ='Y' then
         O_valid := TRUE;
         return TRUE;
      else
         O_valid := FALSE;
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
 END TSL_VALID_ITEMLIST_SEC;
---------------------------------------------------------------------------------------------
-- 09-Aug-2010 Tesco HSC/Usha Patil                    Mod: CR354 End
-- 20-Sep-2010, MrgNBS019220, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com, end
----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
--CR332, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com,  11-Nov-2010, begin
-----------------------------------------------------------------------------------------------------
--Function : TSL_VALID_STYLE_REF_CODE_SEC
--Purpose  : This new function validates the user security to access the items in the Style Ref Code
-----------------------------------------------------------------------------------------------------
FUNCTION TSL_VALID_STYLE_REF_CODE_SEC(O_error_message    IN OUT VARCHAR2,
                                      O_valid            IN OUT BOOLEAN,
                                      I_style_ref_code   IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                                      I_user_loc         IN     VARCHAR2,
                                      I_mode_access      IN     VARCHAR2)
RETURN BOOLEAN is

   L_program         VARCHAR2(64) := 'TSL_SUPPLY_CHAIN_ATTRIB_SQL.TSL_VALID_STYLE_REF_CODE_SEC';
   L_item_own_ctry   ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;

   CURSOR C_STYLE_REF_CODE is
   select item
     from item_master
    where item_desc_secondary = I_style_ref_code
      -- 03-Jan-2011, DefNBS020097, Govindarajan K, Begin
      and item_level <= tran_level
      -- 03-Jan-2011, DefNBS020097, Govindarajan K, End
      and simple_pack_ind = 'N';
BEGIN
   O_valid := TRUE;
   FOR C_item_rec in C_STYLE_REF_CODE
   LOOP
      if ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY(O_error_message,
                                               L_item_own_ctry,
                                               C_item_rec.item) = FALSE then
         return FALSE;
      end if;

      if (I_user_loc = L_item_own_ctry or I_user_loc = 'B') and I_mode_access ='Y' then
         O_valid := TRUE;
         return TRUE;
      else
         O_valid := FALSE;
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
 END TSL_VALID_STYLE_REF_CODE_SEC;
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- Function Name : TSL_SREF_MASS_UPDATE_ITEM_CTRY
-- Purpose       : This function will update tsl_country_auth_ind for all approved items on an style ref code
-----------------------------------------------------------------------------------------------------
FUNCTION TSL_SREF_MASS_UPDATE_ITEM_CTRY(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                        I_style_ref_code IN      VARCHAR2)
   RETURN BOOLEAN is

   L_program                    VARCHAR2(50):= 'ITEMLIST_ATTRIB_SQL.TSL_SREF_MASS_UPDATE_ITEM_CTRY';
   L_error_message              RTK_ERRORS.RTK_TEXT%TYPE;
   L_sref_table                 ITEMLIST_ATTRIB_SQL.ITEMLIST_TABLE;
   L_itemmaster_rec             ITEM_MASTER%ROWTYPE;

BEGIN

   if ITEMLIST_ATTRIB_SQL.TSL_GET_STYLE_REF_CODE_ITEMS(L_error_message,
                                                       L_sref_table,
                                                       I_style_ref_code) = FALSE then
      return FALSE;
   end if;

   if L_sref_table is NOT NULL and L_sref_table.COUNT > 0 then
      FOR i in 1 .. L_sref_table.COUNT
      LOOP
         if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(L_error_message,
                                            L_itemmaster_rec,
                                            L_sref_table(i).item) = FALSE then
            return FALSE;
         end if;

         if L_itemmaster_rec.item_level = 1 and
            L_itemmaster_rec.tran_level = 2 and
            L_itemmaster_rec.pack_ind   = 'N' then
            if ITEM_MASTER_SQL.TSL_TPNB_UPDATE_ITEM_CTRY(O_error_message,
                                                         L_itemmaster_rec.item) = FALSE then
               return FALSE;
            end if;
         else
            if ITEM_MASTER_SQL.TSL_UPDATE_ITEM_CTRY(O_error_message,
                                                    L_itemmaster_rec.item) = FALSE then
               return FALSE;
            end if;
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
END TSL_SREF_MASS_UPDATE_ITEM_CTRY;
-----------------------------------------------------------------------------------------------------
-- Function Name : TSL_GET_STYLE_REF_CODE_ITEMS
-- Purpose       : To get all the items from the style ref code
-----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_STYLE_REF_CODE_ITEMS(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                      O_itemlist_table  IN OUT  ITEMLIST_ATTRIB_SQL.ITEMLIST_TABLE,
                                      I_style_ref_code  IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
RETURN BOOLEAN is

   L_owner_country      ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE := NULL;
   L_error              RTK_ERRORS.RTK_TEXT%TYPE           := NULL;

   CURSOR C_GET_ITEMS is
   select item
     from item_master
    where item_desc_secondary = I_style_ref_code
      and ((item_level = tran_level)
      -- 26-Nov-2010 Tesco HSC/Usha Patil                 Mod: CR332 Begin
       or (item_level = tran_level
      and pack_ind = 'Y'))
      -- 26-Nov-2010 Tesco HSC/Usha Patil                 Mod: CR332 End
      and simple_pack_ind = 'N'
      and ((tsl_owner_country = L_owner_country) or (L_owner_country = 'B'));

    L_program            VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.TSL_GET_STYLE_REF_CODE_ITEMS';
    L_count              NUMBER(7)    := 1;

BEGIN
   if TSL_RP_STYLE_REF_CODE.GET_USER_LOCATION(L_error,                                                                                                                     L_owner_country) = FALSE then
        O_error_message := L_error;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ITEMS',
                    'ITEM_MASTER',
                    'Style Ref Code '||I_style_ref_code);
   open C_GET_ITEMS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ITEMS',
                    'ITEM_MASTER',
                    'Style Ref Code '||I_style_ref_code);
   fetch C_GET_ITEMS BULK COLLECT into O_itemlist_table;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ITEMS',
                    'ITEM_MASTER',
                    'Style Ref Code '||I_style_ref_code);
   close C_GET_ITEMS;

   return TRUE;

EXCEPTION
   when OTHERS then
      if C_GET_ITEMS%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEMS',
                          'ITEM_MASTER',
                          'Style Ref Code '||I_style_ref_code);
         close C_GET_ITEMS;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_STYLE_REF_CODE_ITEMS;


-----------------------------------------------------------------------------------------------------
-- Function Name : TSL_GET_STYLE_REF_CODE_ITEMS
-- Purpose       : To get dest_type for Style Ref Code
-----------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_DIST_STYLE_REF_CODE(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                     O_dist_type       IN OUT  VARCHAR2,
                                     I_style_ref_code  IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
RETURN BOOLEAN is

   L_owner_country      ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE := NULL;
   L_error              RTK_ERRORS.RTK_TEXT%TYPE           := NULL;

   CURSOR C_DIST_STYLE_REF_CODE is
   select case
             when cnt_wh > 0 and cnt_dir > 0 then 'B'
             when cnt_wh > 0 and cnt_dir = 0 then 'W'
             when cnt_wh = 0 and cnt_dir > 0 then 'D'
          end dist_type
     from (select (select count(1)
                     from item_master   im,
                          item_supplier isp,
                          sups          sup
                    where im.item = isp.item
                      and isp.supplier = sup.supplier
                      and im.item_desc_secondary = I_style_ref_code
                      and im.item_level = im.tran_level
                      and ((im.tsl_owner_country = L_owner_country) or (L_owner_country = 'B'))
                      and im.simple_pack_ind = 'N'
                      and sup.dsd_ind = 'N') as cnt_wh,
                  (select count(1)
                     from item_master   im,
                          item_supplier isp,
                          sups          sup
                    where im.item = isp.item
                      and isp.supplier = sup.supplier
                      and im.item_desc_secondary = I_style_ref_code
                      and im.item_level = im.tran_level
                      and ((im.tsl_owner_country = L_owner_country) or (L_owner_country = 'B'))
                      and im.simple_pack_ind = 'N'
                      and sup.dsd_ind = 'Y') as cnt_dir
             from dual);

   L_program            VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.TSL_GET_DIST_STYLE_REF_CODE';

BEGIN

   if TSL_RP_STYLE_REF_CODE.GET_USER_LOCATION(L_error,                                                                                                                     L_owner_country) = FALSE then
        O_error_message := L_error;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_DIST_STYLE_REF_CODE',
                    'ITEM_MASTER, ITEM_SUPPLIER, SUPS',
                    'Style Ref Code '||I_style_ref_code);
   open C_DIST_STYLE_REF_CODE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DIST_STYLE_REF_CODE',
                    'ITEM_MASTER, ITEM_SUPPLIER, SUPS',
                    'Style Ref Code '||I_style_ref_code);
   fetch C_DIST_STYLE_REF_CODE into O_dist_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DIST_STYLE_REF_CODE',
                    'ITEM_MASTER, ITEM_SUPPLIER, SUPS',
                    'Style Ref Code '||I_style_ref_code);
   close C_DIST_STYLE_REF_CODE;

   return TRUE;

EXCEPTION
   when OTHERS then
      if C_DIST_STYLE_REF_CODE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_DIST_STYLE_REF_CODE',
                          'ITEM_MASTER, ITEM_SUPPLIER, SUPS',
                          'Style Ref Code '||I_style_ref_code);
         close C_DIST_STYLE_REF_CODE;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_DIST_STYLE_REF_CODE;
-----------------------------------------------------------------------------------------------------
-- CR332, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com,  11-Nov-2010, end
-----------------------------------------------------------------------------------------------------
-- DefNBS020397, 03-Jan-2011, Sripriya, sripriya.karanam@in.tesco.com (Begin)
-----------------------------------------------------------------------------------------------------
-- Function Name : TSL_INS_WH_ORDER
-- Purpose       : To insert the WH ordered ind into TSL_SCA_WH_ORDER for vdate+1.
-----------------------------------------------------------------------------------------------------
FUNCTION TSL_INS_WH_ORDER(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                          I_item           IN      ITEM_MASTER.ITEM%TYPE,
                          I_value          IN      VARCHAR2,
                          I_country_id     IN      TSL_SCA_WH_ORDER.TSL_COUNTRY_ID%TYPE)
RETURN BOOLEAN is
   CURSOR C_ITEM_EXIST is
   select 'X'
     from tsl_sca_wh_order
    where item = I_item
      and tsl_country_id = Decode(I_country_id,'U','U','R','R','B',tsl_country_id);

   CURSOR C_ORDER_IND(cp_ctry_id VARCHAR2) is
   select order_ind
     from tsl_sca_head
    where item = I_item
      and tsl_country_id = cp_ctry_id;

   CURSOR C_ITEM_DETAIL is
   select item_level,
          tran_level,
          item_number_type,
          simple_pack_ind
     from item_master
    where item = I_item;

   L_order_ind        TSL_SCA_HEAD.ORDER_IND%TYPE := NULL;
   L_order_ind_roi    TSL_SCA_HEAD.ORDER_IND%TYPE := NULL;
   L_dummy            VARCHAR2(1)   := NULL;
   -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
   -- L_vdate                     DATE := GET_VDATE;
   -- DefNBS021917, 18-Mar-2011, Praveen (Begin)
   L_vdate                     DATE := GET_VDATE + 1;
   -- DefNBS021917, 18-Mar-2011, Praveen (End)
   -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
   L_program           VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.TSL_INS_WH_ORDER';
   -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com Begin
   L_item_level       ITEM_MASTER.ITEM_LEVEL%TYPE       := NULL;
   L_tran_level       ITEM_MASTER.TRAN_LEVEL%TYPE       := NULL;
   L_item_number_type ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE := NULL;
   L_simple_pack_ind  ITEM_MASTER.SIMPLE_PACK_IND%TYPE  := NULL;
   L_item_type        VARCHAR2(10)                      := NULL;
   -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com End
BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_EXIST',
                    'TSL_SCA_WH_ORDER',
                    'Item: '||I_item);
   open C_ITEM_EXIST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_EXIST',
                    'TSL_SCA_WH_ORDER',
                    'Item: '||I_item);
   fetch C_ITEM_EXIST into L_dummy;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_EXIST',
                    'TSL_SCA_WH_ORDER',
                    'Item: '||I_item);
   close C_ITEM_EXIST;
   --
   -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com Begin
    SQL_LIB.SET_MARK('OPEN',
                     'C_ITEM_DETAIL',
                     'ITEM_MASTER',
                     'Item: '||I_item);
    open C_ITEM_DETAIL ;
    SQL_LIB.SET_MARK('FETCH',
                     'C_ITEM_DETAIL',
                     'ITEM_MASTER',
                     'Item: '||I_item);
    fetch C_ITEM_DETAIL into L_item_level,L_tran_level,L_item_number_type,L_simple_pack_ind;
    if L_item_level = 1 and L_tran_level = 2 and L_item_number_type = 'TPNA' then
       L_item_type := 'LEVEL1';
    elsif L_item_level = 2 and L_tran_level = 2 and L_item_number_type = 'TPNB' then
       L_item_type := 'LEVEL2';
    elsif L_item_level = 1 and L_tran_level = 1 and L_item_number_type = 'TPND' and L_simple_pack_ind = 'N' then
       L_item_type := 'COMPLEX';
    end if;
    SQL_LIB.SET_MARK('CLOSE',
                     'C_ITEM_DETAIL',
                     'ITEM_MASTER',
                     'Item: '||I_item);
    close C_ITEM_DETAIL;
   -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com End
   --
   if I_country_id != 'B' then
      SQL_LIB.SET_MARK('OPEN',
                    'C_ORDER_IND',
                    'TSL_SCA_HEAD',
                    'Item: '||I_item);
      open C_ORDER_IND(I_country_id);
      SQL_LIB.SET_MARK('FETCH',
                        'C_ORDER_IND',
                        'TSL_SCA_HEAD',
                        'Item: '||I_item);
      fetch C_ORDER_IND into L_order_ind;
      SQL_LIB.SET_MARK('CLOSE',
                        'C_ORDER_IND',
                        'TSL_SCA_HEAD',
                        'Item: '||I_item);
      close C_ORDER_IND;
   -- If no order indicator has been set yet at the item level OR if the
   -- future dated order indicator is the same as the current one then
   -- ignore this item and return.
      if L_order_ind is NOT NULL and
         L_order_ind != I_value and
         -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com Begin
         (TSL_SUPPLY_CHAIN_ATTRIB_SQL.GET_DIST_TYPE(L_item_type,I_item,I_country_id) in ('W', 'B')) then
         --Modified to pass L_item_type to handle the WH orderability for LEVEL1,LEVEL2 and Ratio pack items.
         -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com End
         --(TSL_SUPPLY_CHAIN_ATTRIB_SQL.GET_DIST_TYPE('LEVEL2',I_item,I_country_id) in ('W', 'B'))

         if L_dummy is NOT NULL then
            SQL_LIB.SET_MARK('DELETE',
                             NULL,
                            'TSL_SCA_WH_ORDER',
                            'Item:'||I_item);
            delete from tsl_sca_wh_order
            where item = I_item
              and tsl_country_id = I_country_id;
         end if;

         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                         'TSL_SCA_WH_ORDER',
                         'Item:'||I_item);

         insert into tsl_sca_wh_order(item,
                                      order_ind,
                                      effective_date,
                                      tsl_country_id)
                               values(I_item,
                                      I_value,
                                      L_vdate,
                                      I_country_id);
      end if;
   else
   -- If no order indicator has been set yet at the item level OR if the
   -- future dated order indicator is the same as the current one then
   -- ignore this item and return.

      SQL_LIB.SET_MARK('OPEN',
                    'C_ORDER_IND',
                    'TSL_SCA_HEAD',
                    'Item: '||I_item);
      open C_ORDER_IND('U');
      SQL_LIB.SET_MARK('FETCH',
                        'C_ORDER_IND',
                        'TSL_SCA_HEAD',
                        'Item: '||I_item);
      fetch C_ORDER_IND into L_order_ind;
      SQL_LIB.SET_MARK('CLOSE',
                        'C_ORDER_IND',
                        'TSL_SCA_HEAD',
                        'Item: '||I_item);
      close C_ORDER_IND;

      if L_order_ind is NOT NULL and
         L_order_ind != I_value and
         -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com Begin
         (TSL_SUPPLY_CHAIN_ATTRIB_SQL.GET_DIST_TYPE(L_item_type,I_item,I_country_id) in ('W', 'B')) then
         --Modified to pass L_item_type to handle the WH orderability for LEVEL1,LEVEL2 and Ratio pack items.
         -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com End
         --(TSL_SUPPLY_CHAIN_ATTRIB_SQL.GET_DIST_TYPE('LEVEL2',I_item,I_country_id) in ('W', 'B'))

         if L_dummy is NOT NULL then
            SQL_LIB.SET_MARK('DELETE',
                             NULL,
                            'TSL_SCA_WH_ORDER',
                            'Item:'||I_item);
            delete from tsl_sca_wh_order
            where item = I_item
              and tsl_country_id = 'U';
         end if;

         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'TSL_SCA_WH_ORDER',
                          'Item:'||I_item);

         insert into tsl_sca_wh_order(item,
                                      order_ind,
                                      effective_date,
                                      tsl_country_id)
                               values(I_item,
                                      I_value,
                                      L_vdate,
                                      'U');
      end if;

    ------------for roi -------

      SQL_LIB.SET_MARK('OPEN',
                       'C_ORDER_IND',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      open C_ORDER_IND('R');
      SQL_LIB.SET_MARK('FETCH',
                        'C_ORDER_IND',
                        'TSL_SCA_HEAD',
                        'Item: '||I_item);
      fetch C_ORDER_IND into L_order_ind_roi;
      SQL_LIB.SET_MARK('CLOSE',
                        'C_ORDER_IND',
                        'TSL_SCA_HEAD',
                        'Item: '||I_item);
      close C_ORDER_IND;

      if L_order_ind_roi is NOT NULL and
         L_order_ind_roi != I_value and
         -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com Begin
         (TSL_SUPPLY_CHAIN_ATTRIB_SQL.GET_DIST_TYPE(L_item_type,I_item,I_country_id) in ('W', 'B')) then
         --Modified to pass L_item_type to handle the WH orderability for LEVEL1,LEVEL2 and Ratio pack items.
         -- DefNBS024254, 27-Feb-2012, Swetha Prasad,swetha.prasad@in.tesco.com End
         --(TSL_SUPPLY_CHAIN_ATTRIB_SQL.GET_DIST_TYPE('LEVEL2',I_item,I_country_id) in ('W', 'B'))

         if L_dummy is NOT NULL then
            SQL_LIB.SET_MARK('DELETE',
                             NULL,
                            'TSL_SCA_WH_ORDER',
                            'Item:'||I_item);
            delete from tsl_sca_wh_order
            where item = I_item
              and tsl_country_id = 'R';
         end if;
         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'TSL_SCA_WH_ORDER',
                          'Item:'||I_item);
         insert into tsl_sca_wh_order(item,
                                      order_ind,
                                      effective_date,
                                      tsl_country_id)
                               values(I_item,
                                      I_value,
                                      L_vdate,
                                      'R');
      end if;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_ITEM_EXIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_EXIST',
                          'TSL_SCA_WH_ORDER,',
                          'Item '||I_item);
         close C_ITEM_EXIST;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_INS_WH_ORDER;
-----------------------------------------------------------------------------------------------------
-- Function Name : TSL_INS_PREF_PACK
-- Purpose       : To insert the Preferred pack  into TSL_SCA_PREF_PACK for vdate+1.
-----------------------------------------------------------------------------------------------------
FUNCTION TSL_INS_PREF_PACK(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                           I_item           IN      ITEM_MASTER.ITEM%TYPE,
                           I_value          IN      VARCHAR2,
                           I_country_id     IN      TSL_SCA_WH_ORDER.TSL_COUNTRY_ID%TYPE)
RETURN BOOLEAN is
   CURSOR C_ITEM_EXIST is
   select 'X'
     from tsl_sca_pref_pack
    where item = I_item
      and tsl_country_id = Decode(I_country_id,'U','U','R','R','B',tsl_country_id);

   CURSOR C_SCA_EXIST(L_ctry_id VARCHAR2) is
   select 'X'
     from tsl_sca_head
    where item = I_item
      and tsl_country_id = L_ctry_id;

   L_dummy            VARCHAR2(1)  := NULL;
   L_exist            VARCHAR2(1)  := NULL;
   L_exist_roi        VARCHAR2(1)  := NULL;
   -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
   -- L_vdate            DATE         := GET_VDATE;
   -- DefNBS021917, 18-Mar-2011, Praveen (Begin)
   L_vdate            DATE         := GET_VDATE +1;
   -- DefNBS021917, 18-Mar-2011, Praveen (End)
   -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
   L_pack             TSL_SCA_PREF_PACK.DEF_PREF_PACK%TYPE;
   L_program          VARCHAR2(64) := 'ITEMLIST_ATTRIB_SQL.TSL_INS_PREF_PACK';
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_EXIST',
                    'TSL_SCA_PREF_PACK',
                    'Item: '||I_item);
   open C_ITEM_EXIST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_EXIST',
                    'TSL_SCA_PREF_PACK',
                    'Item: '||I_item);
   fetch C_ITEM_EXIST into L_dummy;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_EXIST',
                    'TSL_SCA_PREF_PACK',
                    'Item: '||I_item);
   close C_ITEM_EXIST;



   if I_country_id != 'B' then
      if TSL_SUPPLY_CHAIN_ATTRIB_SQL.CHECK_FUTR_PREF_PACK(O_error_message,
                                                          L_pack,
                                                          I_item,
                                                          I_country_id)= FALSE then
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('OPEN',
                       'C_SCA_EXIST',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      open C_SCA_EXIST(I_country_id);
      SQL_LIB.SET_MARK('FETCH',
                       'C_SCA_EXIST',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      fetch C_SCA_EXIST into L_exist;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SCA_EXIST',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      close C_SCA_EXIST;


      if L_exist is NOT NULL and
         NVL(L_pack,'X') != I_value then

         if L_dummy is NOT NULL then
            SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'TSL_SCA_PREF_PACK',
                          'Item:'||I_item);
            delete from tsl_sca_pref_pack
            where item = I_item
            and tsl_country_id = I_country_id;
         end if;

         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'TSL_SCA_PREF_PACK',
                          'Item:'||I_item);

         insert into tsl_sca_pref_pack(item,
                                       def_pref_pack,
                                       effective_date,
                                       tsl_country_id)
                                values(I_item,
                                       I_value,
                                       L_vdate,
                                       I_country_id);
     end if;
   else
      --check for UK--
      SQL_LIB.SET_MARK('OPEN',
                       'C_SCA_EXIST',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      open C_SCA_EXIST('U');
      SQL_LIB.SET_MARK('FETCH',
                       'C_SCA_EXIST',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      fetch C_SCA_EXIST into L_exist;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SCA_EXIST',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      close C_SCA_EXIST;

      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'TSL_SCA_PREF_PACK',
                       'Item:'||I_item);
      if L_exist is NOT NULL then
         if TSL_SUPPLY_CHAIN_ATTRIB_SQL.CHECK_FUTR_PREF_PACK(O_error_message,
                                                             L_pack,
                                                             I_item,
                                                             'U')= FALSE then
            return FALSE;
         end if;
         if NVL(L_pack,'X') != I_value then
            if L_dummy is NOT NULL then
               SQL_LIB.SET_MARK('DELETE',
                                NULL,
                                'TSL_SCA_PREF_PACK',
                                'Item:'||I_item);
               delete from tsl_sca_pref_pack
                where item = I_item
                  and tsl_country_id = 'U';
            end if;
            insert into tsl_sca_pref_pack(item,
                                          def_pref_pack,
                                          effective_date,
                                          tsl_country_id)
                                   values(I_item,
                                          I_value,
                                          L_vdate,
                                          'U');
         end if;
      end if;
      --for ROI ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_SCA_EXIST',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      open C_SCA_EXIST('R');
      SQL_LIB.SET_MARK('FETCH',
                       'C_SCA_EXIST',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      fetch C_SCA_EXIST into L_exist_roi;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SCA_EXIST',
                       'TSL_SCA_HEAD',
                       'Item: '||I_item);
      close C_SCA_EXIST;

      if L_exist_roi is NOT NULL then
         if TSL_SUPPLY_CHAIN_ATTRIB_SQL.CHECK_FUTR_PREF_PACK(O_error_message,
                                                             L_pack,
                                                             I_item,
                                                             'R')= FALSE then
            return FALSE;
         end if;
         if NVL(L_pack,'X') != I_value then
            if L_dummy is NOT NULL then
               SQL_LIB.SET_MARK('DELETE',
                                NULL,
                                'TSL_SCA_PREF_PACK',
                                'Item:'||I_item);
               delete from tsl_sca_pref_pack
                where item = I_item
                  and tsl_country_id = 'R';
            end if;

            insert into tsl_sca_pref_pack(item,
                                          def_pref_pack,
                                          effective_date,
                                          tsl_country_id)
                                   values(I_item,
                                          I_value,
                                          L_vdate,
                                          'R');
         end if;
      end if;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_ITEM_EXIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_EXIST',
                          'TSL_SCA_WH_ORDER,',
                          'Item '||I_item);
         close C_ITEM_EXIST;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_INS_PREF_PACK;
-----------------------------------------------------------------------------------------------------
-- DefNBS020397, 03-Jan-2011, Sripriya, sripriya.karanam@in.tesco.com (End)
-----------------------------------------------------------------------------------------------------
-- DefNBS021480, 14-Feb-2011, Deepak Gupta, deepak.c.gupta@in.tesco.com (Begin)
-------------------------------------------------------------------------------------------------
FUNCTION TSL_VALIDATE_IGNR_DEACT_RULE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                      I_column_name    IN      VARCHAR2,
                                      I_value          IN      VARCHAR2,
                                      I_item           IN      ITEM_MASTER.ITEM%TYPE,
                                      I_country_id     IN      VARCHAR2,
                                      I_code_type      IN      VARCHAR2,
                                      I_deact_pack     IN      VARCHAR2)
   RETURN BOOLEAN is

   --Declaring the variables
   L_program               VARCHAR2(50) := 'ITEMLIST_ATTRIB_SQL.TSL_VALIDATE_IGNR_DEACT_RULE';
   L_tsl_parent_table      TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;
   L_data_type             USER_TAB_COLUMNS.DATA_TYPE%TYPE;
   L_data_length           USER_TAB_COLUMNS.DATA_LENGTH%TYPE;
   L_nullable              USER_TAB_COLUMNS.NULLABLE%TYPE;
   L_sql_stmnt             VARCHAR2(10000);
   L_return_code           VARCHAR2(5);
   L_date                  DATE;
   L_column                DATE;

   L_exist                VARCHAR2(1);
   L_vdate                DATE := GET_VDATE;
   L_valid               BOOLEAN;
   L_style_ref_exist     VARCHAR2(1);
   L_system_option_row   SYSTEM_OPTIONS%ROWTYPE;
   L_error               EXCEPTION;
   L_code_count          NUMBER;
   PRAGMA EXCEPTION_INIT(L_error,-2290);
   L_seq_no              NUMBER(3);
   L_error_seq_no        EXCEPTION;
   PRAGMA EXCEPTION_INIT(L_error_seq_no,-06502);
   L_low_lvl_exists      VARCHAR2(1);
   L_brand_ind           VARCHAR2(1);
   L_invalid_value        EXCEPTION;
   PRAGMA EXCEPTION_INIT(L_invalid_value, -02291);
   L_custom_code          TSL_CUSTOM_FIELDS.CUSTOM_CODE%TYPE;

   --This cursor fetches the parent table
   cursor C_GET_TABLE_NAME is
   select parent_table,
          custom_code
     from tsl_custom_fields
    where upper(custom_field_name) = upper(I_column_name);

   --This cursor fetches the data type length
   cursor C_DATA_TYP_LEN is
   select data_type,
          data_length,
          nullable
     from user_tab_columns
    where table_name  = upper(L_tsl_parent_table)
      and column_name = upper(I_column_name);

   cursor C_GET_COUNTRY_ID is
   select 'X'
     from dual
    where exists (select 1
                    from user_tab_columns uts
                   where uts.table_name = L_tsl_parent_table
                     and uts.column_name = upper('tsl_country_id'));

   cursor C_STYEL_REF_VALIDATE is
   select 'X'
    from subclass  scl
   where scl.tsl_style_ref_ind = 'Y'
    and exists (select 1
                  from item_master iem
                 where iem.item     = I_item
                   and iem.dept     = scl.dept
                   and iem.class    = scl.class
                   and iem.subclass = scl.subclass);

   cursor C_GET_CODE is
   select code
     from code_detail
    where code_type = I_code_type;

   cursor C_GET_CODE_BR_NBR is
   select code
     from code_detail
    where code_type = 'TBRA';

   cursor C_GET_CODE_NBR is
   select code
     from code_detail
    where code_type = 'TNBR';

   cursor C_LOW_LVL_CODE_EXISTS is
   select 'X'
     from item_master im,
          tsl_low_lvl_code lc
    where item = I_item
      and im.dept = lc.dept
      and im.class = lc.class
      and im.subclass = lc.subclass
      and lc.low_lvl_code = translate(I_value,'_',' ');

BEGIN

   L_code_count := 1;
   if UPPER(I_column_name) = 'TSL_LOW_LVL_SEQ_NO' then
      L_seq_no := TO_NUMBER(I_value);
   end if;

   --Fetching the values from C_GET_TABLE_NAME
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   open C_GET_TABLE_NAME;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   fetch C_GET_TABLE_NAME into L_tsl_parent_table,
                               L_custom_code;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TABLE_NAME',
                    'TSL_CUSTOM_FIELDS',
                    'tsl_parent_table: '||I_column_name);
   close C_GET_TABLE_NAME;

   --Fetching the values from C_DATA_TYP_LEN
   SQL_LIB.SET_MARK('OPEN',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_DATA_TYP_LEN;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_DATA_TYP_LEN into L_data_type,L_data_length,L_nullable;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DATA_TYP_LEN',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_DATA_TYP_LEN;


   -- Fetching the TSL_COUNTRY_ID for the parent table.
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_GET_COUNTRY_ID;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_GET_COUNTRY_ID into L_exist;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COUNTRY_ID',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_GET_COUNTRY_ID;

   SQL_LIB.SET_MARK('OPEN',
                    'C_STYEL_REF_VALIDATE',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   open C_STYEL_REF_VALIDATE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_STYEL_REF_VALIDATE',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   fetch C_STYEL_REF_VALIDATE into L_style_ref_exist;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_STYEL_REF_VALIDATE',
                    'USER_TAB_COLUMNS',
                    'table_name: '||L_tsl_parent_table);
   close C_STYEL_REF_VALIDATE;

   if L_exist is NOT NULL then
      --condition 1
      if (L_nullable = 'N' and I_value is NULL) then
         O_error_message := SQL_LIB.CREATE_MSG('REQ_FIELD_NULL',L_custom_code, NULL, NULL);
         return FALSE;
      else
         --condition 2
         if (L_nullable = 'Y' and I_value is NULL) then
            if I_country_id = 'B' then
               L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                              ' set ' || I_column_name || ' = '''||I_value ||'''
                              where item = ' ||''''|| I_item||'''';
               EXECUTE IMMEDIATE L_sql_stmnt;
            else
               L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                              ' set ' || I_column_name || ' = '''||I_value ||'''
                              where item = ' ||''''|| I_item||''''||
                              ' and tsl_country_id = '|| ''''||I_country_id||'''';
               EXECUTE IMMEDIATE L_sql_stmnt;
            end if;-- check for I_country_id ='B'
             update tsl_skulist_value_temp
                set value = I_value
              where item  = I_item;

         else
            --condition 3
            if L_data_type = 'DATE' then
               if I_value <= get_vdate then
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_VDATE');
                  return FALSE;
               end if;
               if length(substr(I_value,INSTR(I_value, '-', 1, 2) + 1)) = 2 then
                  if I_country_id = 'B' then
                     L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                    ' set ' || I_column_name || ' = '''||I_value ||'''
                                    where item = ' ||''''|| I_item||'''';
                     EXECUTE IMMEDIATE L_sql_stmnt;
                  else
                     L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                    ' set ' || I_column_name || ' = '''||I_value ||'''
                                    where item = ' ||''''|| I_item||''''||
                                    ' and tsl_country_id = '|| ''''||I_country_id||'''';
                     EXECUTE IMMEDIATE L_sql_stmnt;
                  end if;
                  update tsl_skulist_value_temp
                      set value = I_value
                   where item  = I_item;
               else
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
                  return FALSE;
               end if;

            else

               --condition 4
               if length(I_value) > L_data_length then
                  O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                  return FALSE;
               else
                  if L_data_type = 'NUMBER' then
                     if TSL_IS_NUMBER(O_error_message,
                                      I_value) = FALSE then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        return FALSE;
                     else
                        if I_country_id = 'B' then
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||'''';
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        else
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||''''||
                                          ' and tsl_country_id = '|| ''''||I_country_id||'''';
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        end if;
                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;

                  end if;
                  if L_data_type = 'VARCHAR2' then

                     if L_data_length  = 1 then
                        if I_value is NULL then
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           return FALSE;
                        end if;
                     end if;
                     if I_code_type is not NULL then
                        if I_code_type in ('TBRA') then
                           for c_rec in C_GET_CODE_BR_NBR LOOP
                              if c_rec.code = I_value then
                                 L_code_count := L_code_count+1;
                                 L_brand_ind := 'Y';

                              end if;
                           END LOOP;
                        elsif I_code_type in ('TNBR') then
                           for c_rec in C_GET_CODE_NBR LOOP
                              if c_rec.code = I_value then
                                 L_code_count := L_code_count+1;
                                 L_brand_ind := 'N';

                              end if;
                           END LOOP;
                        else
                           for c_rec in C_GET_CODE LOOP
                              if c_rec.code = I_value then
                                 L_code_count := L_code_count+1;
                              end if;
                           END LOOP;
                        end if;
                        if L_code_count = 1 then
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           return FALSE;
                        end if;
                     end if;
                     if UPPER(I_column_name) = 'TSL_LOW_LVL_CODE' then
                        open C_LOW_LVL_CODE_EXISTS;
                        fetch C_LOW_LVL_CODE_EXISTS into L_low_lvl_exists;
                        close C_LOW_LVL_CODE_EXISTS;

                        if L_low_lvl_exists is NULL then
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_LVL_CODE',I_value,NULL,NULL);
                           return FALSE;
                        end if;
                     end if;
                     if length(I_value) > L_data_length or I_value is NULL then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        return FALSE;
                     else
                        if UPPER(I_column_name) = 'DEF_PREF_PACK' then
                           if TSL_VALIDATE(O_error_message,
                                           I_column_name,
                                           I_item,
                                           I_value) = FALSE then
                              return FALSE;
                           end if;
                           if TSL_INS_PREF_PACK(O_error_message,
                                               I_item,
                                               I_value,
                                               I_country_id) = FALSE then

                              return FALSE;
                           end if;
                        elsif UPPER(I_column_name) = 'ORDER_IND' then
                           if TSL_INS_WH_ORDER(O_error_message,
                                               I_item,
                                               I_value,
                                               I_country_id) = FALSE then

                              return FALSE;
                             end if;
                        else
                        if I_country_id = 'B' then
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||'''';
                           if I_code_type in ('TBRA','TNBR') then
                              L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
                           end if;
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        else
                           L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                          ' set ' || I_column_name || ' = '''||I_value ||'''
                                          where item = ' ||''''|| I_item||''''||
                                          ' and tsl_country_id = '|| ''''||I_country_id||'''';
                           if I_code_type in ('TBRA','TNBR') then
                              L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
                           end if;
                           EXECUTE IMMEDIATE L_sql_stmnt;
                        end if;
                        end if;

                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;

                     end if;
                  end if;
               end if;--condition 4
            end if;--condition 3
         end if;--condition 2
      end if;--condition 1
      --
      if UPPER(I_column_name) not in ('ORDER_IND','DEF_PREF_PACK') then
         if TSL_CASCADE_VALUES_DEACT_RULE (O_error_message,
                                           L_tsl_parent_table,
                                           I_column_name,
                                           I_value,
                                           I_item,
                                           I_country_id,
                                           I_code_type,
                                           I_deact_pack) = FALSE then

            return FALSE;
         end if;
      --
      end if;

   else
      --condition 1
      if (L_nullable = 'N' and I_value is NULL) then
         O_error_message := SQL_LIB.CREATE_MSG('REQ_FIELD_NULL',L_custom_code, NULL, NULL);
         return FALSE;
      else
         --condition 2
         if (L_nullable = 'Y' and I_value is NULL) then
            L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = ' ||''''|| I_item||'''';
            EXECUTE IMMEDIATE L_sql_stmnt;
            update tsl_skulist_value_temp
               set value = I_value
             where item  = I_item;
         else
            --condition 3
            if L_data_type = 'DATE' then
               if I_value <= L_vdate then
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_EFF_DATE');
               end if;
               if length(substr(I_value,INSTR(I_value, '-', 1, 2) + 1)) = 2 then
                  L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                 ' set ' || I_column_name || ' = '''||I_value ||'''
                                 where item = ' ||''''|| I_item||'''';
                  --
                  EXECUTE IMMEDIATE L_sql_stmnt;
                  update tsl_skulist_value_temp
                     set value = I_value
                   where item  = I_item;
               else
                  O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
                  return FALSE;
               end if;

            else
               --condition 4
               if length(I_value) > L_data_length then
                  O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                  return FALSE;
               else
                  if L_data_type = 'NUMBER' then
                     if TSL_IS_NUMBER(O_error_message,
                                      I_value) = FALSE then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        return FALSE;
                     else
                        L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                       ' set ' || I_column_name || ' = '''||I_value ||'''
                                       where item = ' ||''''|| I_item||'''';
                        EXECUTE IMMEDIATE L_sql_stmnt;
                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;
                  end if;
                  if L_data_type = 'VARCHAR2' then
                     if L_data_length  = 1 then
                        if I_value is NULL then
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           return FALSE;
                        end if;
                     end if;
                     if I_code_type is not NULL then
                        for c_rec in C_GET_CODE LOOP
                           if c_rec.code = I_value then
                              L_code_count := L_code_count+1;
                           end if;
                        END LOOP;
                        if L_code_count = 1 then
                           O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                           return FALSE;
                        end if;
                     end if;
                     if upper(I_column_name) = upper('item_desc_secondary') then
                        if L_style_ref_exist is NOT NULL then
                           if system_options_sql.get_system_options(O_error_message,
                                                                    L_system_option_row) =  FALSE then
                              return FALSE;
                           end if;
                           if L_system_option_row.tsl_style_ref_ind = 'Y' then
                              if ITEM_MASTER_SQL.TSL_VALIDATE_STYLE_REF(O_error_message,
                                                                        I_value,
                                                                        L_valid)= FALSE then
                                 return FALSE;
                              end if;
                           end if;
                           if NOT L_valid then
                              O_error_message := SQL_LIB.CREATE_MSG('TSL_INVALID_STYLE_REF',''''||I_value||'''',NULL,NULL);
                              return FALSE;
                           end if;
                        end if;
                     end if;

                     if length(I_value) > L_data_length or I_value is NULL then
                        O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
                        return FALSE;
                     else
                        L_sql_stmnt := ' update '|| L_tsl_parent_table ||
                                       ' set ' || I_column_name || ' = '''||I_value ||'''
                                       where item = ' ||''''|| I_item||'''';
                        EXECUTE IMMEDIATE L_sql_stmnt;
                        update tsl_skulist_value_temp
                           set value = I_value
                         where item  = I_item;
                     end if;
                  end if;
               end if;--condition 4
            end if;--condition 3
         end if;--condition 2
      end if;--condition 1
      --

      if TSL_CASCADE_VALUES_DEACT_RULE(O_error_message,
                                       L_tsl_parent_table,
                                       I_column_name,
                                       I_value,
                                       I_item,
                                       NULL,
                                       I_code_type,
                                       I_deact_pack) = FALSE then

         return FALSE;
      end if;
      --

   end if;

   return TRUE;

EXCEPTION

   when L_error then
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
      return FALSE;
   when L_error_seq_no then
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',''''||I_value||'''',L_custom_code,NULL);
      return FALSE;
   when L_invalid_value then
      O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_DATA_LEN',
                                            ''''||I_value||'''',
                                            L_custom_code,
                                            NULL);
      return FALSE;
   when OTHERS then
      if L_data_type = 'DATE' then
       O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_DT_FMT');
       return FALSE;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_VALIDATE_IGNR_DEACT_RULE;

FUNCTION TSL_CASCADE_VALUES_DEACT_RULE (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                        I_tsl_parent_table IN       VARCHAR2,
                                        I_column_name      IN       VARCHAR2,
                                        I_value            IN       VARCHAR2,
                                        I_item             IN       ITEM_MASTER.ITEM%TYPE,
                                        I_country_id       IN       VARCHAR2,
                                        I_code_type        IN       VARCHAR2,
                                        I_deact_pack       IN       VARCHAR2)
   RETURN BOOLEAN is

   L_program                VARCHAR2(50):= 'ITEMLIST_ATTRIB_SQL.TSL_CASCADE_VALUES_DEACT_RULE';
   L_error_message          RTK_ERRORS.RTK_TEXT%TYPE;
   L_sql_stmnt              VARCHAR2(10000);
   L_pack_ind               ITEM_MASTER.PACK_IND%TYPE;
   L_brand_ind              VARCHAR2(1);
   L_epw_ind                item_attributes.tsl_epw_ind%type;
   L_end_date               item_attributes.tsl_end_date%type;
   L_pack_no                ITEM_MASTER.ITEM_PARENT%TYPE;
-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
   L_ATTR_ID                 CODE_DETAIL.CODE%TYPE;
   L_ATTR_EXC_EXISTS         BOOLEAN:=FALSE;
-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End


   CURSOR C_GET_PACK_DETAIL is
    select item,
           im.status,
           im.item_number_type,
           im.item_level,
           im.item_parent,
           im.tran_level
      from item_master im
     start with im.item = I_item
     connect by prior im.item = im.item_parent;

   CURSOR C_GET_ITEM_DETAIL is
    select item,
           im.status,
           im.item_number_type,
           im.item_level,
           im.item_parent,
           im.tran_level
      from item_master im
     start with im.item = I_item
     connect by prior im.item = im.item_parent
    union
    select item,
           im.status,
           im.item_number_type,
           im.item_level,
           im.item_parent,
           im.tran_level
      from item_master im
     start with  im.tsl_base_item = I_item
     connect by prior im.item = im.item_parent
     order by 4;

   CURSOR C_VALIDATE_ITEM is
    select im.pack_ind
      from packitem pi,
           item_master im
     where im.item       = I_item
       and pi.pack_no(+) = im.item;

   CURSOR C_GET_PACKS is
    select pack_no
      from packitem pi
     where pi.item = I_item;

   CURSOR C_GET_OCC is
    select item
      from item_master im
     where im.item_parent = L_pack_no;
---New Change
   CURSOR C_GET_PACKS_TPNA is
     select pai1.pack_no item
     from packitem pai1
     where pai1.item_parent = I_item
     UNION ALL
     select im.item
     from item_master im,
          packitem pai2
     where pai2.item_parent = I_item
     and im.item_parent = pai2.pack_no;
   CURSOR C_GET_PACKS_BASE is
     --Get the simple packs of the base item
     select pai1.pack_no item
     from packitem pai1
     where pai1.item = I_item
     and   I_deact_pack ='Y'
     UNION ALL
     --Get the OCC of the simple packs of the base item
     select im.item
     from item_master im,
          packitem pai2
     where pai2.item = I_item
     and   im.item_parent = pai2.pack_no
     and   I_deact_pack ='Y'
     UNION ALL
     --Get the variants items of the base item
     select im.item
     from   item_master im
     where  im.tsl_base_item = I_item
     and    im.item <> im.tsl_base_item
     UNION ALL
     --Get the simple packs of the variants of the base item
     select pai1.pack_no item
     from packitem pai1
     where pai1.item IN (select im.item
                         from   item_master im
                         where  im.tsl_base_item = I_item
                         and    im.item <> im.tsl_base_item)
     and   I_deact_pack ='Y'
     UNION ALL
     --Get the OCC of the simple packs of the variants of the base item
     select im.item
     from item_master im,
          packitem pai2
     where pai2.item IN (select im.item
                         from   item_master im
                         where  im.tsl_base_item = I_item
                         and    im.item <> im.tsl_base_item)
     and   im.item_parent = pai2.pack_no
     and   I_deact_pack ='Y';
   CURSOR C_GET_PACKS_VAR is
     select pai1.pack_no item
     from packitem pai1
     where pai1.item = I_item
     UNION ALL
     select im.item
     from item_master im,
          packitem pai2
     where pai2.item = I_item
     and   im.item_parent = pai2.pack_no;
   L_item_master_rec ITEM_MASTER%ROWTYPE;
   L_item_tbl        TSL_DEACTIVATE_SQL.ITEM_MASTER_API_TBLTYPE;
---New Change
-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
   CURSOR C_GET_ATTR_ID is
   select tsl_code
     from tsl_map_item_attrib_code
    where tsl_column_name=UPPER(I_column_name);
-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
BEGIN
  --cursor for non pack item.
  SQL_LIB.SET_MARK('OPEN', 'C_VALIDATE_ITEM', 'ITEM_MASTER', NULL);
  open C_VALIDATE_ITEM;

  SQL_LIB.SET_MARK('FETCH', 'C_VALIDATE_ITEM', 'ITEM_MASTER', NULL);
  fetch C_VALIDATE_ITEM INTO L_pack_ind;

  SQL_LIB.SET_MARK('CLOSE', 'C_VALIDATE_ITEM', 'ITEM_MASTER', NULL);
  close C_VALIDATE_ITEM;
   if I_code_type = 'TBRA' then
      L_brand_ind := 'Y';
   elsif I_code_type = 'TNBR'then
      L_brand_ind := 'N';
   end if;
 ---New Change
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(o_error_message,
                                      L_item_master_rec,
                                      I_item) = FALSE then
      return FALSE;
   end if;
 ---New Change
   if upper(I_tsl_parent_table) = 'ITEM_ATTRIBUTES' then
 	  -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
		   SQL_LIB.SET_MARK('OPEN',
							'C_GET_ATTR_ID',
							'TSL_MAP_ITEM_ATTRIB_CODE',
							'I_column_name: '||I_column_name);
		   open C_GET_ATTR_ID;

		   SQL_LIB.SET_MARK('FETCH',
							'C_GET_ATTR_ID',
							'TSL_MAP_ITEM_ATTRIB_CODE',
							'I_column_name: '||I_column_name);
		   fetch C_GET_ATTR_ID into L_ATTR_ID;

		   SQL_LIB.SET_MARK('CLOSE',
							'C_GET_ATTR_ID',
							'TSL_MAP_ITEM_ATTRIB_CODE',
							'I_column_name: '||I_column_name);
		   close C_GET_ATTR_ID;
		   if TSL_ATTR_STPCAS_EXISTS(O_error_message,
								 L_ATTR_ID,
                 L_ATTR_EXC_EXISTS)=FALSE then
					return FALSE;
		   end if;

	if L_ATTR_EXC_EXISTS=FALSE then
 -- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End

      if I_country_id = 'B' then
         if NOT ITEM_ATTRIB_DEFAULT_SQL.COPY_DOWN_PARENT_ATTRIB(L_error_message,
                                                                I_item,
                                                                'U',
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237  Begin
                                                                NULL,
                                                                NULL
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237  End
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                                                                ) then
            return FALSE;
         end if;
         if NOT ITEM_ATTRIB_DEFAULT_SQL.COPY_DOWN_PARENT_ATTRIB(L_error_message,
                                                                I_item,
                                                                'R',
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237  Begin
                                                                NULL,
                                                                NULL
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237  End
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                                                                ) then
            return FALSE;
         end if;
      else
         if NOT ITEM_ATTRIB_DEFAULT_SQL.COPY_DOWN_PARENT_ATTRIB(L_error_message,
                                                                I_item,
                                                                I_country_id,
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 Begin
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, begin
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237  Begin
                                                                NULL,
                                                                NULL
                                                                -- 14-Apr-11     Nandini M     PrfNBS022237  End
                                                                -- MrgNBS022368, Deepak Gupta/Accenture, deepak.c.gupta@in.tesco.com, 18-Apr-2011, end
                                                                -- MrgNBS022379, Accenture/Ravi Nagaraju, ravi.nagaraju@in.tesco.com 21-Apr-2011 End
                                                                ) then
            return FALSE;
         end if;
      end if;
	-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  Begin
	end if;
	-- PM020648,11-Nov-2013,Gopinath Meganathan, Gopinath.Meganathan@in.tesco.com  End
   end if;

   if upper(I_tsl_parent_table) = 'ITEM_MASTER' and
      upper(I_column_name) = 'ITEM_DESC_SECONDARY' then
      if item_master_sql.tsl_cascade_style_ref(L_error_message,
                                               I_value,
                                               I_item,
                                               'Y',
                                               'N') = FALSE then
         return FALSE;
      end if;
   end if;

   if L_pack_ind = 'Y' then
      FOR rec IN C_GET_PACK_DETAIL LOOP
      if  I_country_id is NOT NULL then
         if I_country_id = 'B' then
            if I_column_name = 'tsl_end_date' then
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
			  if L_ATTR_EXC_EXISTS=FALSE then
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item;
			  end if;
            -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            elsif I_column_name = 'tsl_epw_ind' then
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
			  if L_ATTR_EXC_EXISTS=FALSE then
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item;
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
			  end if;
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            else
               L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = ' ||''''|| rec.item||'''';
               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
               end if;
               EXECUTE IMMEDIATE L_sql_stmnt;
            end if;
		-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		   if L_ATTR_EXC_EXISTS=FALSE then
		-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item;
                        end if;
                     END LOOP;
            END LOOP;
        -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		   end if;
		-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
         else
            if I_column_name = 'tsl_end_date' then
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
			 if L_ATTR_EXC_EXISTS=FALSE then
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item and tsl_country_id = I_country_id;
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
             end if;
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            elsif I_column_name = 'tsl_epw_ind' then
              -- reset the epw_ind to 'N' before updating by country
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
			 if L_ATTR_EXC_EXISTS=FALSE then
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
                  update item_attributes
                     set tsl_epw_ind = 'N', tsl_end_date = null
                   where item = rec.item;
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item and tsl_country_id = I_country_id;
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
             end if;
			-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            else
               L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm' ||
                           ' and tsl_country_id = :I_country_id';
               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
               end if;
               EXECUTE IMMEDIATE L_sql_stmnt using rec.item,I_country_id;
            end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		   if L_ATTR_EXC_EXISTS=FALSE then
	    -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no and tsl_country_id = I_country_id;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no and tsl_country_id = I_country_id;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item and tsl_country_id = I_country_id;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item and tsl_country_id = I_country_id;
                        end if;
                     END LOOP;
            END LOOP;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		   end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
         end if;
      else
         if I_column_name = 'tsl_end_date' then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		   if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		   end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
         elsif I_column_name = 'tsl_epw_ind' then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		   if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		   end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
         else
               L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm';

               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
               end if;
               EXECUTE IMMEDIATE L_sql_stmnt  using rec.item;

         end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
	    if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
         FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item;
                        end if;
                     END LOOP;
         END LOOP;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
	    end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
      end if;
      END LOOP;
   else--L_pack_ind <> 'Y'
    FOR rec IN C_GET_ITEM_DETAIL LOOP
      if  I_country_id is NOT NULL then
         if I_country_id = 'B' then
            if I_column_name = 'tsl_end_date' then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		     if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item;
       -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		     end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            elsif I_column_name = 'tsl_epw_ind' then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		      if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		      end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            else
               L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm';

               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
               end if;
               EXECUTE IMMEDIATE L_sql_stmnt using rec.item;
               ---New Change
               if (L_item_master_rec.item_level = 1 and L_item_master_rec.tran_level = 2 and L_item_master_rec.pack_ind = 'N') then
                   SQL_LIB.SET_MARK('OPEN',
                                    'C_GET_PACKS_TPNA',
                                    'ITEM_MASTER',
                                    'ITEM: ' ||I_item);
                   open C_GET_PACKS_TPNA;
                   SQL_LIB.SET_MARK('FETCH',
                                    'C_GET_PACKS_TPNA',
                                    'ITEM_MASTER',
                                    'ITEM: ' ||I_item);
                   fetch C_GET_PACKS_TPNA bulk collect into L_item_tbl;
                   SQL_LIB.SET_MARK('CLOSE',
                                    'C_GET_PACKS_TPNA',
                                    'ITEM_MASTER',
                                    'ITEM: ' ||I_item);
                   close C_GET_PACKS_TPNA;
               elsif (L_item_master_rec.item_level = 2 and L_item_master_rec.tran_level = 2
                  and L_item_master_rec.tsl_base_item = I_item and L_item_master_rec.pack_ind = 'N') then
                      SQL_LIB.SET_MARK('OPEN',
                                       'C_GET_PACKS_BASE',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      open C_GET_PACKS_BASE;
                      SQL_LIB.SET_MARK('FETCH',
                                       'C_GET_PACKS_BASE',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      fetch C_GET_PACKS_BASE bulk collect into L_item_tbl;
                      SQL_LIB.SET_MARK('CLOSE',
                                       'C_GET_PACKS_BASE',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      close C_GET_PACKS_BASE;
               elsif (I_deact_pack ='Y' and L_item_master_rec.item_level = 2 and L_item_master_rec.tran_level = 2
                  and L_item_master_rec.tsl_base_item <> I_item and L_item_master_rec.pack_ind = 'N') then
                      SQL_LIB.SET_MARK('OPEN',
                                       'C_GET_PACKS_VAR',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      open C_GET_PACKS_VAR;
                      SQL_LIB.SET_MARK('FETCH',
                                       'C_GET_PACKS_VAR',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      fetch C_GET_PACKS_VAR bulk collect into L_item_tbl;
                      SQL_LIB.SET_MARK('CLOSE',
                                       'C_GET_PACKS_VAR',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      close C_GET_PACKS_VAR;
               end if;
               if L_item_tbl is NOT NULL and L_item_tbl.COUNT > 0 then
                  FOR i in L_item_tbl.FIRST..L_item_tbl.LAST
                  LOOP
                     SQL_LIB.SET_MARK('UPDATE',
                                      NULL,
                                      'item_master',
                                      'I_item ' || L_item_tbl(i).item);
                     L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm';
                     EXECUTE IMMEDIATE L_sql_stmnt using L_item_tbl(i).item;
                  END LOOP;
               end if;
               ---New change

            end if;
		-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		if L_ATTR_EXC_EXISTS=FALSE then
	    -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item;
                        end if;
                     END LOOP;
            END LOOP;
	    -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
	    end if;
		-- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
         else--I_country_id <> 'B'
            if I_column_name = 'tsl_end_date' then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		     if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item and tsl_country_id = I_country_id;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		     end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            elsif I_column_name = 'tsl_epw_ind' then
              -- reset the epw_ind to 'N' before updating by country
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		    if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
                  update item_attributes
                     set tsl_epw_ind = 'N', tsl_end_date = null
                   where item = rec.item;
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item and tsl_country_id = I_country_id;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		    end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            else
               L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm' ||
                           ' and tsl_country_id = :I_country_id';

               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
               end if;
               EXECUTE IMMEDIATE L_sql_stmnt using rec.item,I_country_id;
               ---New Change
               if (L_item_master_rec.item_level = 1 and L_item_master_rec.tran_level = 2 and L_item_master_rec.pack_ind = 'N') then
                   SQL_LIB.SET_MARK('OPEN',
                                    'C_GET_PACKS_TPNA',
                                    'ITEM_MASTER',
                                    'ITEM: ' ||I_item);
                   open C_GET_PACKS_TPNA;
                   SQL_LIB.SET_MARK('FETCH',
                                    'C_GET_PACKS_TPNA',
                                    'ITEM_MASTER',
                                    'ITEM: ' ||I_item);
                   fetch C_GET_PACKS_TPNA bulk collect into L_item_tbl;
                   SQL_LIB.SET_MARK('CLOSE',
                                    'C_GET_PACKS_TPNA',
                                    'ITEM_MASTER',
                                    'ITEM: ' ||I_item);
                   close C_GET_PACKS_TPNA;
               elsif (L_item_master_rec.item_level = 2 and L_item_master_rec.tran_level = 2
                  and L_item_master_rec.tsl_base_item = I_item and L_item_master_rec.pack_ind = 'N') then
                      SQL_LIB.SET_MARK('OPEN',
                                       'C_GET_PACKS_BASE',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      open C_GET_PACKS_BASE;
                      SQL_LIB.SET_MARK('FETCH',
                                       'C_GET_PACKS_BASE',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      fetch C_GET_PACKS_BASE bulk collect into L_item_tbl;
                      SQL_LIB.SET_MARK('CLOSE',
                                       'C_GET_PACKS_BASE',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      close C_GET_PACKS_BASE;
               elsif (I_deact_pack ='Y' and L_item_master_rec.item_level = 2 and L_item_master_rec.tran_level = 2
                  and L_item_master_rec.tsl_base_item <> I_item and L_item_master_rec.pack_ind = 'N') then
                      SQL_LIB.SET_MARK('OPEN',
                                       'C_GET_PACKS_VAR',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      open C_GET_PACKS_VAR;
                      SQL_LIB.SET_MARK('FETCH',
                                       'C_GET_PACKS_VAR',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      fetch C_GET_PACKS_VAR bulk collect into L_item_tbl;
                      SQL_LIB.SET_MARK('CLOSE',
                                       'C_GET_PACKS_VAR',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      close C_GET_PACKS_VAR;
               end if;
               if L_item_tbl is NOT NULL and L_item_tbl.COUNT > 0 then
                  FOR i in L_item_tbl.FIRST..L_item_tbl.LAST
                  LOOP
                     SQL_LIB.SET_MARK('UPDATE',
                                      NULL,
                                      'item_master',
                                      'I_item ' || L_item_tbl(i).item);
                     L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm' ||
                           ' and tsl_country_id = :I_country_id';
                     EXECUTE IMMEDIATE L_sql_stmnt using L_item_tbl(i).item,I_country_id;
                  END LOOP;
               end if;
               ---New change

            end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		  if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
            FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no and tsl_country_id = I_country_id;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no and tsl_country_id = I_country_id;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item and tsl_country_id = I_country_id;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item and tsl_country_id = I_country_id;
                        end if;
                     END LOOP;
            END LOOP;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		  end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
         end if;--I_country_id = 'B'
      else--I_country_id is NULL
          if I_column_name = 'tsl_end_date' then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		     if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
               update item_attributes
                  set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                where item = rec.item;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		     end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
          elsif I_column_name = 'tsl_epw_ind' then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		     if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
                  update item_attributes
                     set tsl_epw_ind = 'Y', tsl_end_date = null
                   where item = rec.item;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		     end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
          else
               L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm';

               if I_code_type in ('TBRA','TNBR') then
                  L_sql_stmnt := L_sql_stmnt || ' and tsl_brand_ind = '|| ''''||L_brand_ind||'''';
               end if;
               EXECUTE IMMEDIATE L_sql_stmnt using rec.item;

               ---New Change
               if (L_item_master_rec.item_level = 1 and L_item_master_rec.tran_level = 2 and L_item_master_rec.pack_ind = 'N') then
                   SQL_LIB.SET_MARK('OPEN',
                                    'C_GET_PACKS_TPNA',
                                    'ITEM_MASTER',
                                    'ITEM: ' ||I_item);
                   open C_GET_PACKS_TPNA;
                   SQL_LIB.SET_MARK('FETCH',
                                    'C_GET_PACKS_TPNA',
                                    'ITEM_MASTER',
                                    'ITEM: ' ||I_item);
                   fetch C_GET_PACKS_TPNA bulk collect into L_item_tbl;
                   SQL_LIB.SET_MARK('CLOSE',
                                    'C_GET_PACKS_TPNA',
                                    'ITEM_MASTER',
                                    'ITEM: ' ||I_item);
                   close C_GET_PACKS_TPNA;
               elsif (L_item_master_rec.item_level = 2 and L_item_master_rec.tran_level = 2
                  and L_item_master_rec.tsl_base_item = I_item and L_item_master_rec.pack_ind = 'N') then
                      SQL_LIB.SET_MARK('OPEN',
                                       'C_GET_PACKS_BASE',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      open C_GET_PACKS_BASE;
                      SQL_LIB.SET_MARK('FETCH',
                                       'C_GET_PACKS_BASE',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      fetch C_GET_PACKS_BASE bulk collect into L_item_tbl;
                      SQL_LIB.SET_MARK('CLOSE',
                                       'C_GET_PACKS_BASE',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      close C_GET_PACKS_BASE;
               elsif (I_deact_pack ='Y' and L_item_master_rec.item_level = 2 and L_item_master_rec.tran_level = 2
                  and L_item_master_rec.tsl_base_item <> I_item and L_item_master_rec.pack_ind = 'N') then
                      SQL_LIB.SET_MARK('OPEN',
                                       'C_GET_PACKS_VAR',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      open C_GET_PACKS_VAR;
                      SQL_LIB.SET_MARK('FETCH',
                                       'C_GET_PACKS_VAR',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      fetch C_GET_PACKS_VAR bulk collect into L_item_tbl;
                      SQL_LIB.SET_MARK('CLOSE',
                                       'C_GET_PACKS_VAR',
                                       'ITEM_MASTER',
                                       'ITEM: ' ||I_item);
                      close C_GET_PACKS_VAR;
               end if;
               if L_item_tbl is NOT NULL and L_item_tbl.COUNT > 0 then
                  FOR i in L_item_tbl.FIRST..L_item_tbl.LAST
                  LOOP
                     SQL_LIB.SET_MARK('UPDATE',
                                      NULL,
                                      'item_master',
                                      'I_item ' || L_item_tbl(i).item);
                     L_sql_stmnt := ' update '|| I_tsl_parent_table ||
                           ' set ' || I_column_name || ' = '''||I_value ||'''
                           where item = :itm';
                     EXECUTE IMMEDIATE L_sql_stmnt using L_item_tbl(i).item;
                  END LOOP;
               end if;
               ---New change

-- the follwoing code using for cascading the items
                 if   ITEM_MASTER_SQL.TSL_CASCADE_STYLE_REF(O_error_message,
                                                          I_value,
                                                          rec.item,
                                                          'N',
                                                          'N') = FALSE then
                     return FALSE;
                 end if;
          end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		 if L_ATTR_EXC_EXISTS=FALSE then
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
          FOR tpnd_rec IN C_GET_PACKS LOOP
                    if I_column_name = 'tsl_end_date' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                        where item = tpnd_rec.pack_no;
                     end if;
                     if I_column_name = 'tsl_epw_ind' then
                       update item_attributes
                          set tsl_epw_ind = 'Y', tsl_end_date = null
                        where item = tpnd_rec.pack_no;
                     end if;
                     --get OCCs
                     L_pack_no := tpnd_rec.pack_no;
                     FOR occ_rec IN C_GET_OCC LOOP
                        if I_column_name = 'tsl_end_date' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = to_date(I_value,'DD-MON-YY')
                            where item = occ_rec.item;
                        end if;
                        if I_column_name = 'tsl_epw_ind' then
                           update item_attributes
                              set tsl_epw_ind = 'Y', tsl_end_date = null
                            where item = occ_rec.item;
                        end if;
                     END LOOP;
          END LOOP;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Begin
		 end if;
	   -- PM020648,19-Nov-2013,Smitha Ramesh, Smitharamesh.Areyada@in.tesco.com  Ends
      end if;----I_country_id is not NULL
    END LOOP;
  end if;--L_pack_ind = 'Y'
  return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CASCADE_VALUES_DEACT_RULE;
---------------------------------------------------------------------------------------------
-- DefNBS021480, 14-Feb-2011, Deepak Gupta, deepak.c.gupta@in.tesco.com (End)
---------------------------------------------------------------------------------------------

END ITEMLIST_ATTRIB_SQL;
/

