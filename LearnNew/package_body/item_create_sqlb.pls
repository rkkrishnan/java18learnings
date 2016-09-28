CREATE OR REPLACE PACKAGE BODY ITEM_CREATE_SQL AS
------------------------------------------------------------------------------------------------------
-- Mod By:      Vinod Kumar, vinod.patalappa@.in.tesco.com
-- Mod Date:    01-Apr-2008
-- Mod Ref:     Defect DefNBS00005519.
-- Mod Details: Modified to handle the defect #4589, which was missed during merging.
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Mod By:      Vinod Kumar, vinod.patalappa@.in.tesco.com
-- Mod Date:    15-Jan-2008
-- Mod Ref:     Defect DefNBS00004589.
-- Mod Details: The fields tsl_occ_barcode_auth and tsl_retail_barcode_auth
--              modified in INSERT_ITEM_MASTER() function.
-----------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Mod By:      Rahul Soni
-- Mod Date:    10-Oct-2007
-- Mod Ref:     Mod N22.
-- Mod Details: Added a new field tsl_occ_barcode_auth,tsl_retail_barcode_auth
--              in INSERT_ITEM_MASTER() function.
---------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Ramasamy
--Mod Date:    03-May-2007
--Mod Ref:     Mod number. 365a
--Mod Details: Amended script to include base varient item
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Mod By:      Natarajan Chandrasekaran, natarajan.chandrashekaran@in.tesco.com
-- Mod Date:    11-May-2007
-- Mod Ref:     Mod number. N20
-- Mod Details: Replace the old fileds on item_attributes with the new fileds from the item_attributes
-----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Mod By: RK
-- Mod Date: 13-Jun-2007
-- Mod Ref: Mod 365a.
-- Mod Details: Added a new field TSL_EXTERNAL_ITEM_IND on ITEM_MASTER table.
---------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    04-Oct-2007
--Mod Ref:     Mod number. N20a
--Mod Details: Product attributes cascading
---------------------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Ramasamy
--Mod Date:    16-Oct-2007
--Mod Ref:     CQ 3541
--Mod Details: Modified to add one parameter in TRAN_CHILDREN_LEVEL3
-----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--Mod By:      Nitin Kumar,nitin.kumar@in.tesco.com
--Mod Date:    04-Oct-2007
--Mod Ref:     N105
--Mod Details: Included a new function TSL_MASS_UPDATE_CHILDREN same as MASS_UPDATE_CHILDREN
--             to handle EAN type(EANOWN) returned by RNA Web Service.Modified the function
--             INSERT_ITEM_MASTER to insert the value of consumer unit in item_attributes table
------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Mod By:      Nandini Mariyappa
-- Mod Date:    22-Nov-2007
-- Mod Ref:     Mod N105.
-- Mod Details: Modified function INSERT_ITEM_MASTER to handle the newly added field tsl_consumer_unit
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Mod By:      Usha Patil
-- Mod Date:    18-Mar-2008
-- Mod Ref:     Mod N126.
-- Mod Details: included tsl_deactivate_date in INSERT_ITEM_MASTER function
-----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Mod By     : Wipro Enabler/Sundara Rajan                                                       --
-- Mod Date   : 27-Mar-2008                                                                       --
-- Mod Ref    : Mod N53                                                                           --
-- Mod Details: Modified function INSERT_ITEM_MASTER to handle the newly added column TSL_MU_IND  --
--              in the ITEM_MASTER table                                                          --
----------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Mod By     : Wipro Enabler/Vijaya Bhaskar
-- Mod Date   : 23-May-2008
-- Mod Ref    : Mod N127
-- Mod Details: Modified function INSERT_ITEM_MASTER to handle the newly added column tsl_range_auth_ind
--              in the ITEM_MASTER table
--------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 09-May-2008
-- Mod Ref    : Mod N111
-- Mod Details: Modified function INSERT_ITEM_MASTER to handle the common product funcionlaity
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- Mod By:      Vinod Kumar.vinod.patalappa@in.tesco.com
-- Mod Date:    24-Jun-2008
-- Mod Ref:     Mod N111.
-- Mod Details: Added the NVL condition for the not null field tsl_common_ind to avoid exception.
-------------------------------------------------------------------------------------------------
-- Mod By:      Murali, murali.natarjan@in.tesco.com
-- Mod Date:    27-Jun-2008
-- Mod Ref:     Mod N111.
-- Mod Details: Added condition to not default tsl_common_ind of parent for Level 2 non pack items.
----------------------------------------------------------------------------------------------------
--Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
--Mod Date:    04-Jul-2008
--Mod Ref:     DefNBS007602
--Mod Details: Range attributes cascading
----------------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 11-Nov-2008
-- Mod Ref    : N128.
-- Mod Details: Modified the function INSERT_ITEM_MASTER to handle newly added field tsl_primary_cua.
-----------------------------------------------------------------------------------------------------
-- Mod By       : Tarun Kumar Mishra, tarun.mishra@in.tesco.com
-- Mod Date     : 9-Dec-2008
-- Mod Ref      : DefNBS005996
-- Mod Details  : Modified the function TSL_MASS_UPDATE_CHILDREN
-----------------------------------------------------------------------------------------------------
--Mod By:      Raghuveer P R
--Mod Date:    12-Dec-2008
--Mod Ref:     Defect NBS00010292
--Mod Details: Added condition to generate a consumer unit for a level 2 complex pack TPNB.
----------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 07-Jan-2009
-- Mod Ref    : CR165.
-- Mod Details: Modified the function INSERT_ITEM_MASTER to handle newly added fields
--              tsl_suspended and tsl_suspend_date.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 13-Apr-2009
-- Mod Ref    : N156.
-- Mod Details: Modified the function INSERT_ITEM_MASTER to handle newly added field
--              tsl_item_upload_ind.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 17-Apr-2009
-- Mod Ref    : Defect(NBS00012450).
-- Mod Details: Modified the function INSERT_ITEM_MASTER to handle tsl_price_marked_except_ind field.
-----------------------------------------------------------------------------------------------------
-- Mod By       : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date     : 23-Jun-2009
-- Def Ref      : MrgNBS013573
-- Def Details  : Modified the function INSERT_ITEM_MASTER as a part of Merge.
-------------------------------------------------------------------------------------------------
-- Modified by : Nitin Kumar, nitin.kumar@in.tesco.com
-- Date        : 20-July-2009
-- Defect Id   : NBS00013905
-- Desc        : Modified Function TSL_MASS_UPDATE_CHILDREN for Checking Barcode i.e. EAN/OCC
--------------------------------------------------------------------------------------------------------
-- Merged by   : Nitin Kumar, nitin.kumar@in.tesco.com
-- Date        : 10-Aug-2009
-- Desc        : Merge 3.3b to 3.4  and  3.4 to 3.5a
--------------------------------------------------------------------------------------------------------
---Mod By      : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
---Mod Date    : 20-Aug-2009
---Def Ref     : NBS00014541
---Def Details : Modified the function INSERT_ITEM_MASTER to add NVL condition for 'tsl_occ_barcode_auth'
--               and tsl_retail_barcode_auth.
--------------------------------------------------------------------------------------------------------
--Mod By             : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
--Mod Date           : 19-Aug-2009
--Mod Ref            : CR236
--Includes functions : TSL_GET_EXT_MASTERED_IND
--Mod Details        : Modifies this function to return the externally mastered indicator for UK
--                     and ROI country an added one more IN/OUT patameter.
---------------------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 19-Aug-2009
-- Mod Ref    : CR236
-- Def Details: Modified the function INSERT_ITEM_MASTER to handle newly added column
--              'tsl_range_auth_ind_roi'.
---------------------------------------------------------------------------------------------------------
-- Mod By     : Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 23-Oct-2009
-- Mod Ref    : MrgNBS015130
-- Mod Details: Merge 3.4 Dev to 3.5b
--------------------------------------------------------------------------------------------------------
---Mod By      : Satish B.N, satish.narasimhaiah@in.tesco.com
---Mod Date    : 20-Nov-2009
---Def Ref     : DefNBS015424
---Def Details : Modified the function INSERT_ITEM_MASTER and TRAN_CHILDREN_LEVEL3 functions
--------------------------------------------------------------------------------------------------------
-- Mod By        : Sarayu Gouda
-- Mod Date      : 01-Feb-2010
-- Mod Ref       : MrgNBS016138
-- Mod Details   : PrdDi (Production branch) to 3.5b branches
--------------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 18-Feb-2010
-- Mod Ref    : CR288
-- Mod Details: Modified the function INSERT_ITEM_MASTER to remove 'tsl_range_auth_ind_roi' and handle
--              tsl_primary_cua_roi.
--------------------------------------------------------------------------------------------------------
-- Mod By        : Bhargavi Pujari
-- Mod Date      : 24-Feb-2010
-- Mod Ref       : DefNBS016363
-- Mod Details   : Modified INSERT_ITEM_MASTER,TRAN_CHILDREN_LEVEL3 to insert tsl_consumer_unit
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Mod By        : Sarayu Gouda
-- Mod Date      : 05-Mar-2010
-- Mod Ref       : MrgNBS016549
-- Mod Details   : merge  from 3.5d to 3.5b branches
----------------------------------------------------------------------------------------
--Mod By:      Nitin Kumar,nitin.kumar@in.tesco.com
--Mod Date:    31-Mar-2010
--Mod Ref:     CR224B
--Mod Details: Modified TSL_INSERT_ITEM_RANGE function to pick only those record whose end date
--             is NULL in TSL_ITEM_RANGE table
------------------------------------------------------------------------------------------------
--Mod By     : Usha Patil, usha.patil@in.tesco.com
--Mod Date   : 30-Apr-2010
--Mod Ref    : NBS00017065
--Mod Details: Modified TRAN_CHILDREN function check for item status before cascading the VAT.
------------------------------------------------------------------------------------------------
--Mod By     : Bhargavi Pujari, bharagavi.pujaril@in.tesco.com
--Mod Date   : 14-May-2010
--Mod Ref    : VAT ISUUE
--Mod Details: Modified TRAN_CHILDREN function to cascade vat info if the TPNA is having only one
--             record for vat_item table even if it's less than vdate,added one UNION condition.
------------------------------------------------------------------------------------------------
-- Mod By        : Joy Stephen
-- Mod Date      : 17-May-2010
-- Mod Ref       : DefNBS017480
-- Mod Details   : Modified the function INSERT_ITEM_MASTER for Item induction from RPS.
--------------------------------------------------------------------------------------------------
-- Mod By        : Reshma Koshy
-- Mod Date      : 21-May-2010
-- Mod Ref       : DefNBS017568
-- Mod Details   : Modified the function INSERT_ITEM_MASTER for cascading ITEM_DESC_SECONDARY for
--                 EAN and OCC from parent.
--------------------------------------------------------------------------------------------------
--Mod By:      Chandru, chandrashekaran.natarajan@in.tesco.com
--Mod Date:    27-Apr-2010
--Mod Ref:     CR258
--Mod Details: vpn and supp_label included in the insert statement of item_supplier table
------------------------------------------------------------------------------------------------
--Mod By:      Usha Patil, usha.patil@in.tesco.com
--Mod Date:    07-May-2010
--Mod Ref:     Def-NBS00017356
--Mod Details: Modified INSERT_ITEM_MASTER() not to cascade grocery attributes for sub tran items.
------------------------------------------------------------------------------------------------
--Mod By       : JK, jayakumar.gopal@in.tesco.com
--Mod Date     : 01-Jun-10
--Mod Ref      : MrgNBS017783
--Mod Details  : Added CR258 Def-NBS00017356
------------------------------------------------------------------------------------------------------
--Mod By       : Chandru, chandrashekaran.natarajan@in.tesco.com
--Mod Date     : 14-Jun-10
--Mod Ref      : DefNBS017889
--Mod Details  : Removing the fix of NBS00017356 defect to cascade the groc attr to EAN/OCC items
------------------------------------------------------------------------------------------------------
--Mod By       : Raghuveer P R
--Mod Date     : 19-Aug-10
--Mod Ref      : CR354
--Mod Details  : Modified functions INSERT_ITEM_MASTER for RIB item subscription, INSERT_ITEM_MASTER,
--               and TRAN_CHILDREN_LEVEL3 for form validations and logic.
------------------------------------------------------------------------------------------------------
--Mod By       : Joy Stephen
--Mod Date     : 20-Aug-10
--Mod Ref      : CR354
--Mod Details  : Modified the function TSL_INSERT_ITEM_ATTRIBUTES,TSL_INSERT_ITEM_RANGE to handle the
--               cascading of Item Attributes from parent to child.
------------------------------------------------------------------------------------------------------
--Mod By       : Joy Stephen
--Mod Date     : 03-Sep-2010
--Mod Ref      : CR354
--Mod Details  : Modified the function TSL_INSERT_ITEM_ATTRIBUTES.
--------------------------------------------------------------------------------------------------
--Mod By       : Phil Noon
--Mod Date     : 30-Nov-10
--Mod Ref      : CR338
--Mod Details  : Added functionality to process clothing diffs
------------------------------------------------------------------------------------------------------
-- Mod By     : Sathish Kumar
-- Mod Date   : 6-Dev-2010
-- Mod Ref    : CR364
-- Mod Details: Mods to TSL_INSERT_ITEM_RANGE to also update the End_Date while doing casacading
--              during itemchildren creation.
------------------------------------------------------------------------------------------------------
--Mod By       : Usha Patil
--Mod Date     : 03-Dec-2010
--Mod Ref      : PrfNBS018484
--Mod Details  : Modified the function TSL_INSERT_ITEM_ATTRIBUTES to use bind variables in
--               dynamic statements.
--------------------------------------------------------------------------------------------
--Mod By       : Shhireen Sheosunker
--Mod Date     : 17-Dec-2010
--Mod Ref      : DefNBS020133
--Mod Details  : Modified the function TSL_UPDATE_CHILD_PACK so that user can update the pack desc
--               for futer dates.
--------------------------------------------------------------------------------------------
--Mod By       : Shireen Sheosunker
--Mod Date     : 24-Jan-2011
--Mod Ref      : DefNBS020557
--Mod Details  : Modified the function TSL_UPDATE_CHILD_PACK to append the 5 characters of
--               size desc to pack desc and not the colour desc
---------------------------------------------------------------------------------------------
--Mod By       : Shireen Sheosunker
--Mod Date     : 31-Jan-2011
--Mod Ref      : DefNBS020557 on DefNBS020557a branch
--Mod Details  : Modified the function TSL_UPDATE_CHILD_PACK to append the 5 characters of
--               size desc to pack desc and restrict the pack desc to 24 characters
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa, nandini.mariyappa@in.tesco.com
-- Mod Date   : 07-Mar-2011
-- Def Ref    : NBS00021784
-- Mod Details: Modified the function INSERT_ITEM_MASTER to cascade the diffs for sub transaction
--              items from its parents during the item subscription.
---------------------------------------------------------------------------------------------
-- Mod By     : Veena Nanjundaiah, veena.nanjundaiah@in.tesco.com
-- Mod Date   : 28-Mar-2011
-- Def Ref    : NBS00022119
-- Mod Details: Modified the function INSERT_ITEM_MASTER to default handling temp for items comming from 3rd party system.
---------------------------------------------------------------------------------------------
-- Mod By     : Ankush,Ankush.khanna@in.tesco.com
-- Mod Date   : 23-June-2011
-- Mod Ref    : DefNBS023046(NBS00023046)
-- Mod Details: Record lock exception added in TSL_UPDATE_CHILD_PACK().
---------------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 08-Sep-2011
-- Mod Ref    : DefNBS023566
-- Mod Details: Added cursor C_ITEM_EXISTS and modified code of TSL_UPDATE_CHILD_PACK.
---------------------------------------------------------------------------------------------
-- Mod By     : Vatan Jaiswal, vatan.jaiswal@in.tesco.com
-- Mod Date   : 26-Oct-2011
-- Mod Ref    : CR434
-- Mod Details: Modified function INSERT_ITEM_MASTER to add the newly added field tsl_restrict_price_event.
---------------------------------------------------------------------------------------------
-- Mod By     : shweta.madnawat@in.tesco.com
-- Mod Date   : 28-Oct-2011
-- Mod Ref    : CR434
-- Mod Details: Modified the function INSERT_ITEM_MASTER to add the new
--              field tsl_restrict_price_event.
---------------------------------------------------------------------------------------------
--Mod By:      Vinutha Raju, vinutha.raju@in.tesco.com
--Mod Date:    24-Apr-2012
--Mod Ref:     NBS00024747
--Mod Details: Inserting record with the status I into tsl_picklist_status table
--             only when new approved EAN is not moved under picklist item using
--             barcode_mov_exchange screen
--------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--Mod By:      Smitha Ramesh smitharamesh.areyada@in.tesco.com
--Mod Date:    22-July-2013
--Mod Ref:     CR 480/ChrNBSC0480
--Mod Details: Modified function INSERT_ITEM_MASTER as part of CR 480
--------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--Mod By:      Smitha Ramesh smitharamesh.areyada@in.tesco.com
--Mod Date:    27-Sep-2013
--Mod Ref:     NBS00026243
--Mod Details: Modified function INSERT_ITEM_SUPPLIER and TRAN_CHILDRENto insert tsl_owner_country
-------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--Mod By:      Ramya Shetty K, Ramya.K.Shetty@in.tesco.com
--Mod Date:    30-Oct-2013
--Mod Ref:     PM020648
--Mod Details: Modified function TSL_INSERT_ITEM_ATTRIBUTES
------------------------------------------------------------------------------------------------
FUNCTION TRAN_CHILDREN(O_error_message            IN OUT   VARCHAR2,
                       I_item_master_insert       IN       VARCHAR2,
                       I_auto_approve_child_ind   IN       VARCHAR2)
RETURN BOOLEAN IS
   L_program                VARCHAR2(50)                  := 'ITEM_CREATE_SQL.TRAN_CHILDREN';
   L_item                   ITEM_MASTER.ITEM%TYPE;
   L_item_parent            ITEM_TEMP.EXISTING_ITEM_PARENT%TYPE;
   L_item_desc              ITEM_TEMP.ITEM_DESC%TYPE;
   L_short_desc             ITEM_MASTER.SHORT_DESC%TYPE;
   L_vat_ind                SYSTEM_OPTIONS.VAT_IND%TYPE;
   L_elc_ind                SYSTEM_OPTIONS.ELC_IND%TYPE;
   L_import_ind             SYSTEM_OPTIONS.IMPORT_IND%TYPE;
   L_loc                    ITEM_LOC.LOC%TYPE;
   L_item_level             ITEM_MASTER.ITEM%TYPE;
   L_tran_level             ITEM_MASTER.ITEM%TYPE;
   L_parent_status          ITEM_MASTER.STATUS%TYPE;
   L_seq_no                 PRODUCT_TAX_CODE.SEQ_NO%TYPE;
   L_parent_seq_no          PRODUCT_TAX_CODE.SEQ_NO%TYPE;
   L_vdate                  PERIOD.VDATE%TYPE             := GET_VDATE;
   L_item_approved          BOOLEAN                       := FALSE;
   L_children_approved      BOOLEAN                       := FALSE;
   L_item_submitted         BOOLEAN                       := FALSE;
   L_children_submitted     BOOLEAN                       := FALSE;
   L_user                   VARCHAR2(30)                  := USER;
   L_sysdate                DATE                          := SYSDATE;
   L_table                  VARCHAR2(20)                  := 'ITEM_MASTER';
   RECORD_LOCKED            EXCEPTION;
   PRAGMA                   EXCEPTION_INIT(RECORD_LOCKED, -54);
   L_supp_unit_cost         ITEM_SUPP_COUNTRY.UNIT_COST%TYPE         := NULL;
   L_loc_unit_cost          ITEM_LOC_SOH.UNIT_COST%TYPE              := NULL;
   L_prim_supp_curr         SUPS.CURRENCY_CODE%TYPE                  := NULL;
   L_landed_cost_prim       ITEM_LOC_SOH.UNIT_COST%TYPE              := NULL;
   L_total_exp              ITEM_LOC_SOH.UNIT_COST%TYPE              := NULL;
   L_exp_currency           CURRENCIES.CURRENCY_CODE%TYPE            := NULL;
   L_exchange_rate_exp      CURRENCY_RATES.EXCHANGE_RATE%TYPE        := NULL;
   L_total_duty             ITEM_LOC_SOH.UNIT_COST%TYPE              := NULL;
   L_dty_currency           CURRENCIES.CURRENCY_CODE%TYPE            := NULL;
   L_counter                NUMBER := 0;
   L_parent_sellable_ind    ITEM_MASTER.SELLABLE_IND%TYPE            := NULL;

   L_origin_country_id      ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE := NULL;
   L_supplier        ITEM_SUPP_COUNTRY.SUPPLIER%TYPE :=NULL;

   ---
   TYPE  il_item                IS TABLE OF ITEM_LOC.ITEM%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_loc                  IS TABLE OF ITEM_LOC.LOC%TYPE   INDEX BY BINARY_INTEGER;
   TYPE il_item_parent          IS TABLE OF ITEM_LOC.ITEM_PARENT%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_loc_type             IS TABLE OF ITEM_LOC.LOC_TYPE%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_unit_retail          IS TABLE OF ITEM_LOC.UNIT_RETAIL%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_regular_unit_retail  IS TABLE OF ITEM_LOC.REGULAR_UNIT_RETAIL%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_taxable_ind          IS TABLE OF ITEM_LOC.TAXABLE_IND%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_ti                   IS TABLE OF ITEM_LOC.TI%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_hi                   IS TABLE OF ITEM_LOC.HI%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_store_ord_mult       IS TABLE OF ITEM_LOC.STORE_ORD_MULT%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_status               IS TABLE OF ITEM_LOC.STATUS%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_daily_waste_pct      IS TABLE OF ITEM_LOC.DAILY_WASTE_PCT%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_meas_of_each         IS TABLE OF ITEM_LOC.MEAS_OF_EACH%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_meas_of_price        IS TABLE OF ITEM_LOC.MEAS_OF_PRICE%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_uom_of_price         IS TABLE OF ITEM_LOC.UOM_OF_PRICE%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_primary_variant      IS TABLE OF ITEM_LOC.PRIMARY_VARIANT%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_primary_supp         IS TABLE OF ITEM_LOC.PRIMARY_SUPP%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_primary_cntry        IS TABLE OF ITEM_LOC.PRIMARY_CNTRY%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_selling_unit_retail  IS TABLE OF ITEM_LOC.SELLING_UNIT_RETAIL%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_selling_uom          IS TABLE OF ITEM_LOC.SELLING_UOM%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_multi_units          IS TABLE OF ITEM_LOC.MULTI_UNITS%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_multi_unit_retail    IS TABLE OF ITEM_LOC.MULTI_UNIT_RETAIL%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_multi_selling_uom    IS TABLE OF ITEM_LOC.MULTI_SELLING_UOM%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_source_method        IS TABLE OF ITEM_LOC.SOURCE_METHOD%TYPE INDEX BY BINARY_INTEGER;
   TYPE il_source_wh            IS TABLE OF ITEM_LOC.SOURCE_WH%TYPE INDEX BY BINARY_INTEGER;

   L_previous_parent            ITEM_TEMP.EXISTING_ITEM_PARENT%TYPE := NULL;

   P_il_item il_item;
   P_il_loc  il_loc;
   P_il_item_parent il_item_parent;
   P_il_loc_type il_loc_type;
   P_il_unit_retail il_unit_retail;
   P_il_regular_unit_retail il_regular_unit_retail;
   P_il_taxable_ind il_taxable_ind;
   P_il_ti il_ti;
   P_il_hi il_hi;
   P_il_store_ord_mult il_store_ord_mult;
   P_il_status il_status;
   P_il_daily_waste_pct il_daily_waste_pct;
   P_il_meas_of_each il_meas_of_each;
   P_il_meas_of_price il_meas_of_price;
   P_il_uom_of_price il_uom_of_price;
   P_il_primary_variant il_primary_variant;
   P_il_primary_supp il_primary_supp;
   P_il_primary_cntry il_primary_cntry;
   P_il_selling_unit_retail il_selling_unit_retail;
   P_il_selling_uom il_selling_uom;
   P_il_multi_units il_multi_units;
   P_il_multi_unit_retail il_multi_unit_retail;
   P_il_multi_selling_uom il_multi_selling_uom;
   P_il_source_method il_source_method;
   P_il_source_wh il_source_wh;

   P_il_index           NUMBER := 0;

   -- Define the array to insert the item_loc_soh data into pl/sql table.
   -- using the pl/sql table to insert into item_loc_soh out of the loop
   TYPE ils_item_TBL        IS TABLE OF   ITEM_LOC_SOH.ITEM%TYPE                INDEX BY BINARY_INTEGER;
   TYPE ils_av_cost_TBL     IS TABLE OF   ITEM_LOC_SOH.AV_COST%TYPE             INDEX BY BINARY_INTEGER;
   TYPE ils_unit_cost_TBL   IS TABLE OF   ITEM_LOC_SOH.UNIT_COST%TYPE           INDEX BY BINARY_INTEGER;
   TYPE ils_currency_TBL    IS TABLE OF   SYSTEM_OPTIONS.CURRENCY_CODE%TYPE     INDEX BY BINARY_INTEGER;
   TYPE ils_loc_TBL         IS TABLE OF   ITEM_LOC.LOC%TYPE                     INDEX BY BINARY_INTEGER;

   ---
   P_ils_item          ils_item_TBL;
   P_ils_av_cost       ils_av_cost_TBL;
   P_ils_unit_cost     ils_unit_cost_TBL;
   P_ils_loc           ils_loc_TBL;
   P_ils_currency_cd   ils_currency_TBL;
   ---
   LP_item_loc_soh_table_index NUMBER := 0;
   ---
   TYPE it_item_TBL        IS TABLE OF   ITEM_TEMP.ITEM%TYPE                  INDEX BY BINARY_INTEGER;
   TYPE it_item_parent_TBL IS TABLE OF   ITEM_TEMP.EXISTING_ITEM_PARENT%TYPE     INDEX BY BINARY_INTEGER;
   TYPE it_item_desc_TBL   IS TABLE OF   ITEM_TEMP.ITEM_DESC%TYPE                INDEX BY BINARY_INTEGER;

   P_it_item          it_item_TBL;
   P_it_item_parent   it_item_parent_TBL;
   P_it_item_desc     it_item_desc_TBL;

   CURSOR C_GET_TEMP_ITEMS is
      select item,
             existing_item_parent,
             item_desc
        from item_temp
       order by existing_item_parent;
   ---
   CURSOR C_GET_SHORT_DESC is
      select im.short_desc
        from item_master im,
             item_temp it
       where im.item = it.existing_item_parent;
   ---
   CURSOR C_GET_SYS_OPTS is
      select vat_ind,
             elc_ind,
             import_ind
        from system_options;
   ---
   CURSOR C_GET_STATUS_SELLABLE_DEPOSIT is
      select status, sellable_ind, deposit_item_type
         from item_master
  where item = L_item_parent;
   ---
   CURSOR C_GET_TAX_CODES IS
      SELECT seq_no
        FROM product_tax_code
       WHERE item = L_item_parent;
   ---
   CURSOR C_LOCK_ITEM_MASTER is
      select 'x'
        from item_master
       where item = L_item
         for update nowait;
   ---
   CURSOR C_GET_UNIT_COST is
      select isc.unit_cost,
             s.currency_code,
       isc.supplier,
       isc.origin_country_id
        from item_supp_country isc,
             sups s
       where isc.item = L_item
         and isc.primary_supp_ind = 'Y'
         and isc.primary_country_ind = 'Y'
         and isc.supplier = s.supplier;
   ---
   CURSOR C_CURRENCY is
      select /*+ INDEX(il) INDEX(s) */ s.currency_code, il.loc
        from store s,
             item_loc il
       where s.store = il.loc
         and il.loc_type = 'S'
         and il.item = L_item
      union
      select /*+ INDEX(il) INDEX(wh) */  wh.currency_code, il.loc
        from wh,
             item_loc il
       where wh.wh = il.loc
         and il.loc_type = 'W'
         and il.item = L_item;

   ---  In the following select, the seemingly superfluous joins to the Store and Warehouse table
   ---  are done in order to enforce Location Security, i.e. to ensure that the current user has
   ---  visibility to the Locations they are attempting to utilize.

   CURSOR C_ITEM_LOC_PARENT is
      select i.item, --parent
             i.loc,
             i.item_parent, --grandparent
             i.loc_type,
             i.unit_retail,
             i.regular_unit_retail,
             i.taxable_ind,
             i.ti,
             i.hi,
             i.store_ord_mult,
             i.status,
             i.daily_waste_pct,
             i.meas_of_each,
             i.meas_of_price,
             i.uom_of_price,
             i.primary_variant,
             i.primary_supp,
             i.primary_cntry,
             i.selling_unit_retail,
             i.selling_uom,
             i.multi_units,
             i.multi_unit_retail,
             i.multi_selling_uom,
             i.source_method,
             i.source_wh
  from item_loc i
  where i.item = L_item_parent;

   CURSOR C_GET_ITEM_AVERAGE_WEIGHT(in_item ITEM_MASTER.ITEM%TYPE) is
      select average_weight
        from item_loc_soh
        where item = in_item
        and ROWNUM = 1;

   L_item_deposit_item_type ITEM_MASTER.DEPOSIT_ITEM_TYPE%TYPE;
   L_item_average_weight      ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;

   L_child_item_table         PM_RETAIL_API_SQL.CHILD_ITEM_PRICING_TABLE;

   BEGIN
   if I_item_master_insert = 'Y' then
      if ITEM_CREATE_SQL.INSERT_ITEM_MASTER(O_error_message,
                                            I_auto_approve_child_ind ) = FALSE then
         return FALSE;
      end if;
   end if;
   ---

   open C_GET_SYS_OPTS;
      fetch C_GET_SYS_OPTS into L_vat_ind, L_elc_ind, L_import_ind;
   close C_GET_SYS_OPTS;
   ---

   open C_GET_SHORT_DESC;
      fetch C_GET_SHORT_DESC into L_short_desc;
   close C_GET_SHORT_DESC;
   --

   open C_GET_TEMP_ITEMS;
      fetch C_GET_TEMP_ITEMS BULK COLLECT into P_it_item, P_it_item_parent, P_it_item_desc;
   close C_GET_TEMP_ITEMS;

   insert into item_supplier(item,
                             supplier,
                             primary_supp_ind,
                             vpn,
                             supp_label,
                             consignment_rate,
                             supp_diff_1,
                             supp_diff_2,
                             supp_diff_3,
                             supp_diff_4,
                             pallet_name,
                             case_name,
                             inner_name,
                             supp_discontinue_date,
                             direct_ship_ind,
                             last_update_datetime,
                             last_update_id,
                             create_datetime,
                             concession_rate,
							 --27-Sep-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com NBS00026243-Begin
                             tsl_owner_country
                             --27-Sep-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com NBS00026243-End
							 )
                      select it.item,
                             supplier,
                             primary_supp_ind,
                             -- 01-Jun-10    JK    MrgNBS017783   Begin
                             -- CR258 27-Apr-2010 Chandru Begin
                             vpn,
                             supp_label,
                             -- CR258 27-Apr-2010 Chandru End
                             -- 01-Jun-10    JK    MrgNBS017783   End
                             consignment_rate,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             pallet_name,
                             case_name,
                             inner_name,
                             supp_discontinue_date,
                             direct_ship_ind,
                             L_sysdate,
                             L_user,
                             L_sysdate,
                             concession_rate,
							 --27-Sep-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com NBS00026243-Begin
                             its.tsl_owner_country
							 --27-Sep-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com NBS00026243-End
                        from item_supplier its,
                             item_temp it
                       where its.item = it.existing_item_parent;
   ---

   FOR i IN 1 .. P_it_item.COUNT LOOP
      L_item        := P_it_item(i);
      L_item_parent := P_it_item_parent(i);
      L_item_desc   := P_it_item_desc(i);
      ---
      if L_item_parent != L_previous_parent OR L_previous_parent is NULL then
   -- Below two cursors are moved here to avoid excessive looping
   -- These will be fetched once initially and the values are used below for
   -- inserts into item_loc_soh and set the child item pricing info
         open C_GET_ITEM_AVERAGE_WEIGHT(L_item_parent);
            fetch C_GET_ITEM_AVERAGE_WEIGHT into L_item_average_weight;
            if C_GET_ITEM_AVERAGE_WEIGHT%NOTFOUND then
               L_item_average_weight := NULL;
            end if;
         close C_GET_ITEM_AVERAGE_WEIGHT;

   open C_GET_STATUS_SELLABLE_DEPOSIT;
      fetch C_GET_STATUS_SELLABLE_DEPOSIT into L_parent_status, L_parent_sellable_ind, L_item_deposit_item_type;
   close C_GET_STATUS_SELLABLE_DEPOSIT;

         open c_item_loc_parent;
            fetch c_item_loc_parent BULK COLLECT into P_il_item,P_il_loc,P_il_item_parent,
              P_il_loc_type,P_il_unit_retail,P_il_regular_unit_retail,P_il_taxable_ind,P_il_ti,
              P_il_hi,P_il_store_ord_mult,P_il_status,P_il_daily_waste_pct,P_il_meas_of_each,
              P_il_meas_of_price,P_il_uom_of_price,P_il_primary_variant,P_il_primary_supp,
              P_il_primary_cntry,P_il_selling_unit_retail,P_il_selling_uom,P_il_multi_units,
              P_il_multi_unit_retail,P_il_multi_selling_uom,P_il_source_method,P_il_source_wh;
         close c_item_loc_parent;

   FORALL i IN 1..P_il_item.COUNT
               insert into item_loc(item,
                                    loc,
                                    item_parent,
                                    item_grandparent,
                                    loc_type,
                                    unit_retail,
                                    regular_unit_retail,
                                    clear_ind,
                                    taxable_ind,
                                    local_item_desc,
                                    local_short_desc,
                                    ti,
                                    hi,
                                    store_ord_mult,
                                    status,
                                    status_update_date,
                                    daily_waste_pct,
                                    meas_of_each,
                                    meas_of_price,
                                    uom_of_price,
                                    primary_variant,
                                    primary_cost_pack,
                                    primary_supp,
                                    primary_cntry,
                                    selling_unit_retail,
                                    selling_uom,
                                    multi_units,
                                    multi_unit_retail,
                                    multi_selling_uom,
                                    rpm_ind,
                                    store_price_ind,
                                    last_update_datetime,
                                    last_update_id,
                                    create_datetime,
                                    source_method,
                                    source_wh
                                    --15-Jun-2007 WiproEnabler/Ramasamy - MOD 365a   Begin
                                    ,tsl_lead_item_ind
                                    --15-Jun-2007 WiproEnabler/Ramasamy - MOD 365a   End
                                    )
                             select it.item,
                                    P_il_loc(i),
                                    P_il_item(i), --parent
                                    P_il_item_parent(i), --grandparent
                                    P_il_loc_type(i),
                                    P_il_unit_retail(i),
                                    P_il_regular_unit_retail(i),
                                    'N',
                                    P_il_taxable_ind(i),
                                    it.item_desc,
                                    L_short_desc,
                                    P_il_ti(i),
                                    P_il_hi(i),
                                    P_il_store_ord_mult(i),
                                    P_il_status(i),
                                    L_vdate,
                                    P_il_daily_waste_pct(i),
                                    P_il_meas_of_each(i),
                                    P_il_meas_of_price(i),
                                    P_il_uom_of_price(i),
                                    P_il_primary_variant(i),
                                    NULL,
                                    P_il_primary_supp(i),
                                    P_il_primary_cntry(i),
                                    P_il_selling_unit_retail(i),
                                    P_il_selling_uom(i),
                                    P_il_multi_units(i),
                                    P_il_multi_unit_retail(i),
                                    P_il_multi_selling_uom(i),
                                    'N',
                                    'N',
                                    L_sysdate,
                                    L_user,
                                    L_sysdate,
                                    P_il_source_method(i),
                                    P_il_source_wh(i)
                                    --15-Jun-2007 WiproEnabler/Ramasamy - MOD 365a   Begin
                                    , DECODE(P_il_loc_type(i), 'S', DECODE(it.item_level, 2, 'Y', 'N'), 'N')
                                    --15-Jun-2007 WiproEnabler/Ramasamy - MOD 365a   End
                               from item_temp it
                              where existing_item_parent = L_item_parent;

            L_previous_parent := L_item_parent;
         end if;
      ---
      if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                    L_item_level,
                                    L_tran_level,
                                    L_item) = FALSE THEN
         return FALSE;
      end if;
      ---

      insert into item_supp_country(item,
                                    supplier,
                                    origin_country_id,
                                    unit_cost,
                                    lead_time,
                                    supp_pack_size,
                                    inner_pack_size,
                                    round_lvl,
                                    round_to_inner_pct,
                                    round_to_case_pct,
                                    round_to_layer_pct,
                                    round_to_pallet_pct,
                                    min_order_qty,
                                    max_order_qty,
                                    packing_method,
                                    primary_supp_ind,
                                    primary_country_ind,
                                    default_uop,
                                    ti,
                                    hi,
                                    supp_hier_type_1,
                                    supp_hier_lvl_1,
                                    supp_hier_type_2,
                                    supp_hier_lvl_2,
                                    supp_hier_type_3,
                                    supp_hier_lvl_3,
                                    pickup_lead_time,
                                    last_update_datetime,
                                    last_update_id,
                                    create_datetime,
                                    cost_uom,
                                    tolerance_type,
                                    max_tolerance,
                                    min_tolerance
                                    )
                             select L_item,
                                    supplier,
                                    origin_country_id,
                                    unit_cost,
                                    lead_time,
                                    supp_pack_size,
                                    inner_pack_size,
                                    round_lvl,
                                    round_to_inner_pct,
                                    round_to_case_pct,
                                    round_to_layer_pct,
                                    round_to_pallet_pct,
                                    min_order_qty,
                                    max_order_qty,
                                    packing_method,
                                    primary_supp_ind,
                                    primary_country_ind,
                                    default_uop,
                                    ti,
                                    hi,
                                    supp_hier_type_1,
                                    supp_hier_lvl_1,
                                    supp_hier_type_2,
                                    supp_hier_lvl_2,
                                    supp_hier_type_3,
                                    supp_hier_lvl_3,
                                    pickup_lead_time,
                                    L_sysdate,
                                    L_user,
                                    L_sysdate,
                                    cost_uom,
                                    tolerance_type,
                                    max_tolerance,
                                    min_tolerance
                               from item_supp_country
                              where item = L_item_parent;
      ---

      if L_parent_sellable_ind = 'Y' then
         -- Initialise the L_child_item_table before it is populated.
         L_child_item_table(1).child_item := L_item;
         -- call RPM to set the retail
         if not PM_RETAIL_API_SQL.SET_CHILD_ITEM_PRICING_INFO(O_error_message,
                                                              L_item_parent,
                                                              NULL,
                                                              l_child_item_table) then
            return FALSE;
         end if;
      end if;
      ---
      --- item_loc_soh records are only created for transaction level items

      if L_item_level = L_tran_level then
         --- get the unit cost from item_supp_country for the transaction level item
         open C_GET_UNIT_COST;
            fetch C_GET_UNIT_COST into L_supp_unit_cost, L_prim_supp_curr,  L_supplier, L_origin_country_id;
         close C_GET_UNIT_COST;

     --- For every currency that this item exists in at location, convert the unit cost

     if L_elc_ind = 'Y' then
            if ELC_CALC_SQL.CALC_TOTALS(O_error_message,
                                        L_landed_cost_prim,
                                        L_total_exp,
                                        L_exp_currency,
                                        L_exchange_rate_exp,
                                        L_total_duty,
                                        L_dty_currency,
                                        NULL,
                                        L_item,
                                        NULL,
                                        NULL,
                                        NULL,
                                        L_supplier,
                                        L_origin_country_id,
                                        NULL,
                                        L_supp_unit_cost) = FALSE then
                  return FALSE;
             end if;
     end if;

         FOR rec IN C_CURRENCY LOOP
        if L_elc_ind = 'Y' then
                 if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_landed_cost_prim,
                                       NULL,
                                       rec.currency_code,
                                       L_loc_unit_cost,
                                       'C',
                                       NULL,
                                       NULL) = FALSE then
                    return FALSE;
                 end if;
              else
                 if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_supp_unit_cost,
                                       L_prim_supp_curr,
                                       rec.currency_code,
                                       L_loc_unit_cost,
                                       'C',
                                       NULL,
                                       NULL) = FALSE then
                    return FALSE;
                 end if;
              end if;
            ---
            LP_item_loc_soh_table_index                      := LP_item_loc_soh_table_index + 1;

            P_ils_item(LP_item_loc_soh_table_index)          := L_item;
            P_ils_loc(LP_item_loc_soh_table_index)           := rec.loc;
            P_ils_av_cost(LP_item_loc_soh_table_index)       := NVL(L_loc_unit_cost,0);
            P_ils_unit_cost(LP_item_loc_soh_table_index)     := NVL(L_loc_unit_cost,0);
            P_ils_currency_cd(LP_item_loc_soh_table_index)   := rec.currency_code;
            --
         END LOOP;
      end if;
      ---
      FOR rec IN C_GET_TAX_CODES LOOP
         L_parent_seq_no := rec.seq_no;
         ---
         if NEXT_PRODUCT_TAX_CODE_SEQ(L_seq_no,
                                      O_error_message)= FALSE then
            return FALSE;
         end if;
         ---
         insert into product_tax_code(seq_no,
                                      dept,
                                      item,
                                      tax_jurisdiction_id,
                                      tax_type_id,
                                      start_date,
                                      end_date,
                                      download_ind,
                                      create_id,
                                      create_date,
                                      last_update_id,
                                      last_update_datetime,
                                      create_datetime)
                               select L_seq_no,
                                      dept,
                                      L_item,
                                      tax_jurisdiction_id,
                                      tax_type_id,
                                      start_date,
                                      end_date,
                                      'Y',
                                      L_user,
                                      L_vdate,
                                      L_user,
                                      L_sysdate,
                                      L_sysdate
                                 from product_tax_code
                                where seq_no = L_parent_seq_no;
      END LOOP;
      ---
      if Documents_Sql.GET_DEFAULTS(O_error_message,
                                    'IT',
                                    'IT',
                                    L_item_parent,
                                    L_item,
                                    NULL,
                                    NULL)= FALSE then
         return FALSE;
      end if;
      ---
      if Season_Sql.ASSIGN_DEFAULTS(O_error_message,
                                    L_item) = FALSE then
         return FALSE;
      end if;
      ---
      if Timeline_Sql.INSERT_DOWN_PARENT(O_error_message,
                                         L_item_parent) = FALSE then
         return FALSE;
      end if;

   END LOOP;

   ---
   /* Inserting the data from item_loc_soh pl/sql table to item_loc_soh */

   FORALL i IN 1..P_ils_item.COUNT
              insert into item_loc_soh(loc,
                                loc_type,
                                item,
                                item_parent,
                                item_grandparent,
                                av_cost,
                                unit_cost,
                                stock_on_hand,
                                soh_update_datetime,
                                last_hist_export_date,
                                in_transit_qty,
                                pack_comp_intran,
                                pack_comp_soh,
                                tsf_reserved_qty,
                                pack_comp_resv,
                                tsf_expected_qty,
                                pack_comp_exp,
                                rtv_qty,
                                non_sellable_qty,
                                customer_resv,
                                customer_backorder,
                                pack_comp_cust_resv,
                                pack_comp_cust_back,
        pack_comp_non_sellable,
                                last_update_datetime,
                                last_update_id,
                                create_datetime,
                                primary_supp,
                                primary_cntry,
                                average_weight)
             select il.loc,
                                il.loc_type,
                                P_ils_item(i),
                                il.item_parent,
                                il.item_grandparent,
                                P_ils_av_cost(i),
                                P_ils_unit_cost(i),
                                0,
                                NULL,
                                NULL,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
        0,
                                L_sysdate,
                                L_user,
                                L_sysdate,
                                il.primary_supp,
                                il.primary_cntry,
                                L_item_average_weight
                           from item_loc il
                          where il.item = P_ils_item(i)
                            and il.loc = P_ils_loc(i);

   FORALL j IN 1 .. p_it_item.COUNT
      insert into item_supp_country_loc(item,
                                        supplier,
                                        origin_country_id,
                                        loc,
                                        loc_type,
                                        primary_loc_ind,
                                        unit_cost,
                                        round_lvl,
                                        round_to_inner_pct,
                                        round_to_case_pct,
                                        round_to_layer_pct,
                                        round_to_pallet_pct,
                                        supp_hier_type_1,
                                        supp_hier_lvl_1,
                                        supp_hier_type_2,
                                        supp_hier_lvl_2,
                                        supp_hier_type_3,
                                        supp_hier_lvl_3,
                                        pickup_lead_time,
                                        last_update_datetime,
                                        last_update_id,
                                        create_datetime)
         select p_it_item(j),
          i.supplier,
                                        i.origin_country_id,
                                        i.loc,
                                        i.loc_type,
                                        i.primary_loc_ind,
                                        i.unit_cost,
                                        i.round_lvl,
                                        i.round_to_inner_pct,
                                        i.round_to_case_pct,
                                        i.round_to_layer_pct,
                                        i.round_to_pallet_pct,
                                        i.supp_hier_type_1,
                                        i.supp_hier_lvl_1,
                                        i.supp_hier_type_2,
                                        i.supp_hier_lvl_2,
                                        i.supp_hier_type_3,
                                        i.supp_hier_lvl_3,
                                        i.pickup_lead_time,
                                        L_sysdate,
                                        L_user,
                                        L_sysdate
                                   from item_supp_country_loc i
           where item = p_it_item_parent(j);

   FORALL i IN 1 .. p_it_item.COUNT
      insert into item_supp_country_bracket_cost(item,
                                                 supplier,
                                                 origin_country_id,
                                                 LOCATION,
                                                 bracket_value1,
                                                 loc_type,
                                                 default_bracket_ind,
                                                 unit_cost,
                                                 bracket_value2,
                                                 sup_dept_seq_no)
                                          select p_it_item(i),
                                                 supplier,
                                                 origin_country_id,
                                                 LOCATION,
                                                 bracket_value1,
                                                 loc_type,
                                                 default_bracket_ind,
                                                 unit_cost,
                                                 bracket_value2,
                                                 sup_dept_seq_no
                                            from item_supp_country_bracket_cost
                                           where item = p_it_item_parent(i);

   FORALL i IN 1 .. p_it_item.COUNT
      insert into item_supp_uom(item,
                                supplier,
                                uom,
                                VALUE,
                                last_update_datetime,
                                last_update_id,
                                create_datetime)
                         select p_it_item(i),
                                supplier,
                                uom,
                                VALUE,
                                L_sysdate,
                                L_user,
                                L_sysdate
                           from item_supp_uom
                          where item = p_it_item_parent(i);

   FORALL i IN 1 .. p_it_item.COUNT
      insert into item_supp_country_dim(item,
                                        supplier,
                                        origin_country,
                                        dim_object,
                                        presentation_method,
                                        LENGTH,
                                        width,
                                        height,
                                        lwh_uom,
                                        weight,
                                        net_weight,
                                        weight_uom,
                                        liquid_volume,
                                        liquid_volume_uom,
                                        stat_cube,
                                        tare_weight,
                                        tare_type,
                                        last_update_datetime,
                                        last_update_id,
                                        create_datetime)
                                 select p_it_item(i),
                                        supplier,
                                        origin_country,
                                        dim_object,
                                        presentation_method,
                                        LENGTH,
                                        width,
                                        height,
                                        lwh_uom,
                                        weight,
                                        net_weight,
                                        weight_uom,
                                        liquid_volume,
                                        liquid_volume_uom,
                                        stat_cube,
                                        tare_weight,
                                        tare_type,
                                        L_sysdate,
                                        L_user,
                                        L_sysdate
                                   from item_supp_country_dim
                                  where item = p_it_item_parent(i);


   if L_vat_ind = 'Y' then
  FORALL i IN 1 .. p_it_item.COUNT
         insert into vat_item(item,
                              vat_region,
                              active_date,
                              vat_type,
                              vat_code,
                              vat_rate,
                              create_date,
                              create_id,
                              last_update_datetime,
                              last_update_id,
                              create_datetime)
                       select p_it_item(i),
                              vat_region,
                              active_date,
                              vat_type,
                              vat_code,
                              vat_rate,
                              L_vdate,
                              L_user,
                              L_sysdate,
                              L_user,
                              L_sysdate
                         from vat_item vs1
                        where vs1.item = p_it_item_parent(i)
-- DefNBS016020  Reshma Koshy reshma.koshy@in.tesco.com 20-Jan-2010 Begin
                          and vs1.active_date in (select vs2.active_date
                                                   from vat_item vs2,
                          --29-Apr-2010 Tesco HSC/Usha Patil           Defect Id: NBS00017065 Begin
                                                        item_master iem
                          --29-Apr-2010 Tesco HSC/Usha Patil           Defect Id: NBS00017065 End
                                                  where vs2.vat_region   = vs1.vat_region
                                                    and vs2.active_date >= L_vdate
                                                    and vs2.item         = p_it_item_parent(i)
                          --29-Apr-2010 Tesco HSC/Usha Patil           Defect Id: NBS00017065 Begin
                                                    and iem.item         = vs2.item
                                                    -- 01-Mar-2011, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, DefNBS021744, Begin
                                                    --and iem.status       != 'A'
                                                    -- 01-Mar-2011, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, DefNBS021744, End
                          --29-Apr-2010 Tesco HSC/Usha Patil           Defect Id: NBS00017065 End
                          -- Vat issue 14-May-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                                                  UNION
                                                  select max(vs2.active_date)
                                                    from vat_item vs2,
                                                         item_master iem
                                                   where vs2.vat_region   = vs1.vat_region
                                                     and vs2.active_date < L_vdate
                                                     and vs2.item         = p_it_item_parent(i)
                                                     and iem.item         = vs2.item
                                                     -- 01-Mar-2011, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, DefNBS021744, Begin
                                                     --and iem.status       != 'A'
                                                     -- 01-Mar-2011, Sathishkumar Alagar/Accenture, satishkumar.alagar@in.tesco.com, DefNBS021744, End
                          -- Vat issue 14-May-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                                                    );
-- DefNBS016020  Reshma Koshy reshma.koshy@in.tesco.com 20-Jan-2010 End
   end if;

   FORALL i IN 1 .. p_it_item.COUNT
      insert into item_ticket(item,
                              ticket_type_id,
                              po_print_type,
                              print_on_pc_ind,
                              ticket_over_pct,
                              last_update_datetime,
                              last_update_id,
                              create_datetime)
                       select p_it_item(i),
                              ticket_type_id,
                              po_print_type,
                              print_on_pc_ind,
                              ticket_over_pct,
                              L_sysdate,
                              L_user,
                              L_sysdate
                         from item_ticket
                        where item = p_it_item_parent(i);

   FORALL i IN 1 .. p_it_item.COUNT
      insert into uda_item_lov(item,
                               uda_id,
                               uda_value,
                               last_update_datetime,
                               last_update_id,
                               create_datetime)
                        select p_it_item(i),
                               uda_id,
                               uda_value,
                               L_sysdate,
                               L_user,
                               L_sysdate
                          from uda_item_lov
                         where item = p_it_item_parent(i);

   FORALL i IN 1 .. p_it_item.COUNT
      insert into uda_item_ff(item,
                              uda_id,
                              uda_text,
                              last_update_datetime,
                              last_update_id,
                              create_datetime)
                       select p_it_item(i),
                              uda_id,
                              uda_text,
                              L_sysdate,
                              L_user,
                              L_sysdate
                         from uda_item_ff
                        where item = p_it_item_parent(i);

   FORALL i IN 1 .. p_it_item.COUNT
      insert into uda_item_date(item,
                                uda_id,
                                uda_date,
                                last_update_datetime,
                                last_update_id,
                                create_datetime)
                         select p_it_item(i),
                                uda_id,
                                uda_date,
                                L_sysdate,
                                L_user,
                                L_sysdate
                           from uda_item_date
                          where item = p_it_item_parent(i);

   if L_elc_ind = 'Y' then
        ---
        -- ELC may be set to Yes even if the client is not running RTM.
        -- Need to check the import ind to see if client has RTM and
        -- is therefore using the HTS/Assessments dialogs.
        ---
        if L_import_ind = 'Y' then
     FORALL i IN 1 .. p_it_item.COUNT
            insert into item_hts(item,
                                 hts,
                                 import_country_id,
                                 origin_country_id,
                                 effect_from,
                                 effect_to,
                                 status,
                                 last_update_datetime,
                                 last_update_id,
                                 create_datetime)
                          select p_it_item(i),
                                 hts,
                                 import_country_id,
                                 origin_country_id,
                                 effect_from,
                                 effect_to,
                                 status,
                                 L_sysdate,
                                 L_user,
                                 L_sysdate
                            from item_hts
                           where item = p_it_item_parent(i);

            FORALL i IN 1 .. p_it_item.COUNT
               insert into item_hts_assess(item,
                                        hts,
                                        import_country_id,
                                        origin_country_id,
                                        effect_from,
                                        effect_to,
                                        comp_id,
                                        cvb_code,
                                        comp_rate,
                                        per_count,
                                        per_count_uom,
                                        est_assess_value,
                                        nom_flag_1,
                                        nom_flag_2,
                                        nom_flag_3,
                                        nom_flag_4,
                                        nom_flag_5,
                                        display_order,
                                        last_update_datetime,
                                        last_update_id,
                                        create_datetime)
                                 select p_it_item(i),
                                        hts,
                                        import_country_id,
                                        origin_country_id,
                                        effect_from,
                                        effect_to,
                                        comp_id,
                                        cvb_code,
                                        comp_rate,
                                        per_count,
                                        per_count_uom,
                                        est_assess_value,
                                        nom_flag_1,
                                        nom_flag_2,
                                        nom_flag_3,
                                        nom_flag_4,
                                        nom_flag_5,
                                        display_order,
                                        L_sysdate,
                                        L_user,
                                        L_sysdate
                                   from item_hts_assess
                                  where item = p_it_item_parent(i);

            FORALL i IN 1 .. p_it_item.COUNT
               insert into cond_tariff_treatment(item,
                                              tariff_treatment,
                                              last_update_datetime,
                                              last_update_id,
                                              create_datetime)
                                       select p_it_item(i),
                                              tariff_treatment,
                                              L_sysdate,
                                              L_user,
                                              L_sysdate
                                         from cond_tariff_treatment
                                        where item = p_it_item_parent(i);
         end if;

      FORALL i IN 1 .. p_it_item.COUNT
         insert into item_exp_head(item,
                                   supplier,
                                   item_exp_type,
                                   item_exp_seq,
                                   origin_country_id,
                                   zone_id,
                                   lading_port,
                                   discharge_port,
                                   zone_group_id,
                                   base_exp_ind,
                                   last_update_datetime,
                                   last_update_id,
                                   create_datetime)
                            select p_it_item(i),
                                   supplier,
                                   item_exp_type,
                                   item_exp_seq,
                                   origin_country_id,
                                   zone_id,
                                   lading_port,
                                   discharge_port,
                                   zone_group_id,
                                   base_exp_ind,
                                   L_sysdate,
                                   L_user,
                                   L_sysdate
                              from item_exp_head
                             where item = p_it_item_parent(i);

      FORALL i IN 1 .. p_it_item.COUNT
         insert into item_exp_detail(item,
                                     supplier,
                                     item_exp_type,
                                     item_exp_seq,
                                     comp_id,
                                     cvb_code,
                                     comp_rate,
                                     comp_currency,
                                     per_count,
                                     per_count_uom,
                                     est_exp_value,
                                     nom_flag_1,
                                     nom_flag_2,
                                     nom_flag_3,
                                     nom_flag_4,
                                     nom_flag_5,
                                     display_order,
                                     last_update_datetime,
                                     last_update_id,
                                     create_datetime)
                              select p_it_item(i),
                                     supplier,
                                     item_exp_type,
                                     item_exp_seq,
                                     comp_id,
                                     cvb_code,
                                     comp_rate,
                                     comp_currency,
                                     per_count,
                                     per_count_uom,
                                     est_exp_value,
                                     nom_flag_1,
                                     nom_flag_2,
                                     nom_flag_3,
                                     nom_flag_4,
                                     nom_flag_5,
                                     display_order,
                                     L_sysdate,
                                     L_user,
                                     L_sysdate
                                from item_exp_detail
                               where item = p_it_item_parent(i);

      FORALL i IN 1 .. p_it_item.COUNT
         insert into item_chrg_head(item,
                                    from_loc,
                                    to_loc,
                                    from_loc_type,
                                    to_loc_type)
                             select p_it_item(i),
                                    from_loc,
                                    to_loc,
                                    from_loc_type,
                                    to_loc_type
                               from item_chrg_head
                              where item = p_it_item_parent(i);

      FORALL i IN 1 .. p_it_item.COUNT
         insert into item_chrg_detail(item,
                                      from_loc,
                                      to_loc,
                                      comp_id,
                                      from_loc_type,
                                      to_loc_type,
                                      comp_rate,
                                      per_count,
                                      per_count_uom,
                                      up_chrg_group,
                                      comp_currency,
                                      display_order)
                               select /*+ INDEX (item_chrg_detail, pk_item_chrg_detail) */ p_it_item(i),
                                      from_loc,
                                      to_loc,
                                      comp_id,
                                      from_loc_type,
                                      to_loc_type,
                                      comp_rate,
                                      per_count,
                                      per_count_uom,
                                      up_chrg_group,
                                      comp_currency,
                                      display_order
                                 from item_chrg_detail
                                where item = p_it_item_parent(i);
   end if;

   --FORALL i IN 1 .. p_it_item.COUNT
   FOR i IN 1 .. p_it_item.COUNT
   LOOP
      ---------------------------------------------------------------------------------------------------------------
      -- 04-Oct-2007 Govindarajan - MOD N20a Begin
      ---------------------------------------------------------------------------------------------------------------
      if ITEM_CREATE_SQL.TSL_INSERT_ITEM_ATTRIBUTES (O_error_message,
                                                     p_it_item(i),
                                                     p_it_item_parent(i),
                                                     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                     'U') = FALSE then
                                                     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
          return FALSE;
      end if;
      ---
      -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
      if ITEM_CREATE_SQL.TSL_INSERT_ITEM_ATTRIBUTES (O_error_message,
                                                     p_it_item(i),
                                                     p_it_item_parent(i),
                                                     'R') = FALSE then
          return FALSE;
      end if;
      -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
      ---------------------------------------------------------------------------------------------------------------
      -- 04-Oct-2007 Govindarajan - MOD N20a End
      ---------------------------------------------------------------------------------------------------------------
      -- 04-Jul-2008 Wipro/JK  DefNBS007602  Begin
      ---------------------------------------------------------------------------------------------------------------
      if ITEM_CREATE_SQL.TSL_INSERT_ITEM_RANGE(O_error_message,
                                               p_it_item(i),
                                               p_it_item_parent(i),
                                               -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                               'U') = FALSE then
                                               -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
          return FALSE;
      end if;

      -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
      if ITEM_CREATE_SQL.TSL_INSERT_ITEM_RANGE(O_error_message,
                                               p_it_item(i),
                                               p_it_item_parent(i),
                                               'R') = FALSE then
          return FALSE;
      end if;
      -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
      ---------------------------------------------------------------------------------------------------------------
      -- 04-Jul-2008 Wipro/JK  DefNBS007602  End
      ---------------------------------------------------------------------------------------------------------------
   END LOOP;
   ---
   if L_import_ind = 'Y' then
      FORALL i IN 1 .. p_it_item.COUNT
         insert into item_import_attr(item,
                                      tooling,
                                      first_order_ind,
                                      amortize_base,
                                      open_balance,
                                      commodity,
                                      import_desc)
                               select p_it_item(i),
                                      tooling,
                                      first_order_ind,
                                      amortize_base,
                                      open_balance,
                                      commodity,
                                      import_desc
                                 from item_import_attr
                                where item = p_it_item_parent(i);
   end if;

   FORALL i IN 1 .. p_it_item.COUNT
      insert into item_image(item,
                             image_name,
                             image_addr,
                             image_desc,
                             create_datetime,
                             last_update_datetime,
                             last_update_id)
                      select p_it_item(i),
                             image_name,
                             image_addr,
                             image_desc,
                             L_sysdate,
                             L_sysdate,
                             L_user
                        from item_image
                       where item = p_it_item_parent(i);

   FORALL j IN 1 .. p_it_item.COUNT
      insert into item_loc_traits(item,
                                  loc,
                                  launch_date,
                                  qty_key_options,
                                  manual_price_entry,
                                  deposit_code,
                                  food_stamp_ind,
                                  wic_ind,
                                  proportional_tare_pct,
                                  fixed_tare_value,
                                  fixed_tare_uom,
                                  reward_eligible_ind,
                                  natl_brand_comp_item,
                                  return_policy,
                                  stop_sale_ind,
                                  elect_mtk_clubs,
                                  report_code,
                                  req_shelf_life_on_selection,
                                  req_shelf_life_on_receipt,
                                  ib_shelf_life,
                                  store_reorderable_ind,
                                  rack_size,
                                  full_pallet_item,
                                  in_store_market_basket,
                                  storage_location,
                                  alt_storage_location,
                                  create_datetime,
                                  last_update_id,
                                  last_update_datetime)
                           select p_it_item(j),
                                  i.loc,
                                  i.launch_date,
                                  i.qty_key_options,
                                  i.manual_price_entry,
                                  i.deposit_code,
                                  i.food_stamp_ind,
                                  i.wic_ind,
                                  i.proportional_tare_pct,
                                  i.fixed_tare_value,
                                  i.fixed_tare_uom,
                                  i.reward_eligible_ind,
                                  i.natl_brand_comp_item,
                                  i.return_policy,
                                  i.stop_sale_ind,
                                  i.elect_mtk_clubs,
                                  i.report_code,
                                  i.req_shelf_life_on_selection,
                                  i.req_shelf_life_on_receipt,
                                  i.ib_shelf_life,
                                  i.store_reorderable_ind,
                                  i.rack_size,
                                  i.full_pallet_item,
                                  i.in_store_market_basket,
                                  i.storage_location,
                                  i.alt_storage_location,
                                  L_sysdate,
                                  L_user,
                                  L_sysdate
           from item_loc_traits i
           where i.item = p_it_item_parent(j);
   ---
   -- If the auto approve indicator is Yes and the parent is already approved
   -- then call approval to validate the item for approval and write the POS_MODS,
   -- PRICE_HIST, and RPM records.

   L_previous_parent := NULL;

   FOR i IN 1 .. p_it_item.COUNT LOOP
      L_item := P_it_item(i);
      L_item_parent := P_it_item_parent(i);

      if L_item_parent != L_previous_parent or L_previous_parent is NULL then
         open C_GET_STATUS_SELLABLE_DEPOSIT;
      fetch C_GET_STATUS_SELLABLE_DEPOSIT into L_parent_status, L_parent_sellable_ind, L_item_deposit_item_type;
   close C_GET_STATUS_SELLABLE_DEPOSIT;

          L_previous_parent := L_item_parent;
      end if;

      if I_auto_approve_child_ind = 'Y' and L_parent_status = 'A'
      and L_item_deposit_item_type is NULL then

         --- Need to submit the item before it can be approved.
         open C_LOCK_ITEM_MASTER;
         close C_LOCK_ITEM_MASTER;
         ---
         update item_master
            set status = 'S'
           where item  = L_item;
         ---
         if Item_Approval_Sql.APPROVE(O_error_message,
                                      L_item_approved,
                                      L_children_approved,
                                      'N',
                                      L_item) = FALSE then
            return FALSE;
         end if;
         ---
         -- Item passed approval set status to 'A'
         if L_item_approved = TRUE then

            open C_LOCK_ITEM_MASTER;
            close C_LOCK_ITEM_MASTER;
            ---
            update item_master
               set status = 'A'
             where item   = L_item;
         else
            -- Item failed approval set status back to 'W'
            open C_LOCK_ITEM_MASTER;
            close C_LOCK_ITEM_MASTER;
            ---
            update item_master
               set status = 'W'
             where item   = L_item;
         end if;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   WHEN RECORD_LOCKED THEN
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            NULL,
                                            TO_CHAR(SQLCODE));
      return FALSE;
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END TRAN_CHILDREN;
--------------------------------------------------------------------
FUNCTION INSERT_ITEM_MASTER(O_error_message            IN OUT   VARCHAR2,
                            I_auto_approve_child_ind   IN       VARCHAR2,
                            --16-Oct-2007 For CQ 3541 WiproEnabler/Ramasamy - Modified to add one parameter in INSERT_ITEM_MASTER - Begin
                            I_prim_ref_item_ind        IN       ITEM_MASTER.PRIMARY_REF_ITEM_IND%TYPE   DEFAULT NULL,
                            --16-Oct-2007 For CQ 3541 WiproEnabler/Ramasamy - Modified to add one parameter in INSERT_ITEM_MASTER - End
                            ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
                            --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
                             I_occ_ret_barcode_auth   IN       VARCHAR2 DEFAULT 'N')
                            --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
                            ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
                            ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
RETURN BOOLEAN IS
   L_program              VARCHAR2(40)                          := 'ITEM_CREATE_SQL.INSERT_ITEM_MASTER';
   L_item                 ITEM_MASTER.ITEM%TYPE                 := NULL;
   L_item_level           ITEM_MASTER.ITEM_LEVEL%TYPE           := NULL;
   L_item_parent          ITEM_MASTER.ITEM_PARENT%TYPE          := NULL;
   L_parent_tran_level    ITEM_MASTER.TRAN_LEVEL%TYPE           := NULL;
   L_user                 VARCHAR2(30)                          := USER;
   L_primary_ref_item_ind ITEM_MASTER.PRIMARY_REF_ITEM_IND%TYPE := NULL;
   L_sysdate              DATE                                  := SYSDATE;
   L_ref_item             item_master.item%TYPE                 := NULL;
   -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 Begin
   L_item_parent_common   VARCHAR2(1) := NULL;
   L_exists               BOOLEAN     := FALSE;
   L_common_ind           VARCHAR2(1) := NULL;
   L_system_options_row   SYSTEM_OPTIONS%ROWTYPE;
   L_old_item_parent      ITEM_MASTER.ITEM%TYPE;
   ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
   --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
   L_pack_ind             VARCHAR2(1) := NULL;
   --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
   ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
   -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 End
   --22-July-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com CR-480Begin
    L_delete_order  DAILY_PURGE.DELETE_ORDER%TYPE := 1;
    L_deactivate_date ITEM_MASTER.TSL_DEACTIVATE_DATE%type;
    L_deactivate_ind ITEM_MASTER.TSL_DEACTIVATED%type := 'N';
    --22-July-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com CR-480 End
   --03-May-2007 WiproEnabler/Ramasamy - MOD 365a   Begin
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(RECORD_LOCKED, -54);
   --Cursor to lock the item_temp table
   cursor C_LOCK_ITEM_TEMP is
   select item_temp.tsl_base_item
     from item_temp
    where item_temp.item = l_item
      for update of item_temp.tsl_base_item nowait;
   --03-May-2007 WiproEnabler/Ramasamy - MOD 365a   End
   ---
   CURSOR C_GET_TEMP_ITEMS IS
      SELECT it.item,
             it.item_number_type,
             it.format_id,
             it.prefix,
             it.item_level,
             it.item_desc,
             it.diff_1,
             it.diff_2,
             it.diff_3,
             it.diff_4,
             it.existing_item_parent,
             ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
             --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
             it.tsl_ret_occ_barcode_auth,
             --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
             ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
             im.tran_level,
        --04-Oct-2007 Nitin Kumar - Mod N105   - Begin
             im.pack_ind,
        --04-Oct-2007 Nitin Kumar - Mod N105   - End
        -- Defect NBS00010292 Raghuveer P R 12-Dec-2008  - Begin
             im.simple_pack_ind,
        -- Defect NBS00010292 Raghuveer P R 12-Dec-2008  - End
        -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
             it.tsl_consumer_unit,
        -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
        -- CR354 13-Aug-2010 Raghuveer P R Begin
             it.tsl_owner_country
        -- CR354 13-Aug-2010 Raghuveer P R End
        FROM item_temp it,
             item_master im
       WHERE im.item = it.existing_item_parent;
   ---
   CURSOR C_PRIM_REF_ITEM_EXISTS IS
      SELECT 'N'
        FROM item_master im
       WHERE im.primary_ref_item_ind  = 'Y'
         AND im.item_level            > tran_level
         AND im.item_parent           = L_item_parent
     AND ROWNUM         = 1;
   --
   -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 Begin
     --cursor to lock the item_master table and make Level 3/Level 2 Pack common
     CURSOR C_LOCK_ITEM_MASTER(Cp_item  ITEM_MASTER.ITEM%TYPE) is
     select 'X'
       from item_master im
      where im.item       = Cp_item
        and im.item_level > im.tran_level
     for update nowait;
     -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 End
     --22-July-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com CR 480-Begin
     CURSOR C_get_deactivate_data is
      select im.tsl_deactivated,
             im.tsl_deactivate_date
        from item_master im
       where im.item = L_item_parent;
    --22-July-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com CR480-End

BEGIN
   SQL_LIB.SET_MARK('FETCH','C_GET_TEMP_ITEMS','ITEM_TEMP',NULL);
   FOR rec IN C_GET_TEMP_ITEMS LOOP
      L_item              := rec.item;
      L_item_level        := rec.item_level;
      L_item_parent       := rec.existing_item_parent;
      L_parent_tran_level := rec.tran_level;
      ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
      --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
      L_pack_ind          := rec.pack_ind;
      --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
      ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
      ---
    --26-July-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com CR480-End
      open      C_get_deactivate_data;
      fetch C_get_deactivate_data into L_deactivate_ind,L_deactivate_date;
      close C_get_deactivate_data;
    --26-July-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com CR480-End
      --03-May-2007 WiproEnabler/Ramasamy - MOD 365a   Begin
      if L_item_level = L_parent_tran_level
         and L_item_level = 2 then

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_ITEM_TEMP',
                          'ITEM_TEMP',
                          'ITEM: ' || L_item);
         open C_LOCK_ITEM_TEMP;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_ITEM_TEMP',
                          'ITEM_TEMP',
                          'ITEM: ' || L_item);
         close C_LOCK_ITEM_TEMP;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_TEMP',
                          'ITEM: ' || L_item);
         update item_temp
            set item_temp.tsl_base_item = item_temp.item
          where item_temp.item = L_item;
      end if;
      --03-May-2007 WiproEnabler/Ramasamy - MOD 365a   End
      ---
      ---
      IF L_item_level > L_parent_tran_level  THEN
         --16-Oct-2007 WiproEnabler/Ramasamy - Modified to change the condition For CQ 3541- Begin
         --IF L_ref_item IS NULL THEN
         IF I_prim_ref_item_ind IS NULL THEN
         --16-Oct-2007 WiproEnabler/Ramasamy - Modified to change the condition For CQ 3541- End
            SQL_LIB.SET_MARK('OPEN','C_PRIM_REF_ITEM_EXISTS','ITEM_MASTER','ITEM: '||L_item_parent);
            OPEN C_PRIM_REF_ITEM_EXISTS;
            SQL_LIB.SET_MARK('FETCH','C_PRIM_REF_ITEM_EXISTS','ITEM_MASTER','ITEM: '||L_item_parent);
            FETCH C_PRIM_REF_ITEM_EXISTS INTO L_primary_ref_item_ind;
            IF C_PRIM_REF_ITEM_EXISTS%NOTFOUND THEN
               L_ref_item := L_item;
               EXIT;
            END IF;
            SQL_LIB.SET_MARK('CLOSE','C_PRIM_REF_ITEM_EXISTS','ITEM_MASTER','ITEM: '||L_item_parent);
            CLOSE C_PRIM_REF_ITEM_EXISTS;
         END IF;
      END IF;
      ---
   END LOOP;
   --
      --SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_MASTER')
   --03-May-2007 WiproEnabler/Ramasamy - MOD 365a  Added column tsl_base_item Begin
   INSERT INTO item_master(item,
                           item_number_type,
                           format_id,
                           prefix,
                           item_parent,
                           item_grandparent,
                           pack_ind,
                           item_level,
                           tran_level,
                           item_aggregate_ind,
                           diff_1,
                           diff_1_aggregate_ind,
                           diff_2,
                           diff_2_aggregate_ind,
                           diff_3,
                           diff_3_aggregate_ind,
                           diff_4,
                           diff_4_aggregate_ind,
                           dept,
                           CLASS,
                           subclass,
                           status,
                           item_desc,
                           item_desc_secondary,
                           short_desc,
                           desc_up,
                           primary_ref_item_ind,
                           retail_zone_group_id,
                           cost_zone_group_id,
                           standard_uom,
                           uom_conv_factor,
                           package_size,
                           package_uom,
                           merchandise_ind,
                           store_ord_mult,
                           forecast_ind,
                           original_retail,
                           mfg_rec_retail,
                           retail_label_type,
                           retail_label_value,
                           handling_temp,
                           handling_sensitivity,
                           catch_weight_ind,
                           first_received,
                           last_received,
                           qty_received,
                           waste_type,
                           waste_pct,
                           default_waste_pct,
                           const_dimen_ind,
                           simple_pack_ind,
                           contains_inner_ind,
                           sellable_ind,
                           orderable_ind,
                           pack_type,
                           order_as_type,
                           comments,
                           gift_wrap_ind,
                           ship_alone_ind,
                           check_uda_ind,
                           create_datetime,
                           last_update_id,
                           last_update_datetime,
                           item_xform_ind,
                           inventory_ind,
                           order_type,
                           sale_type,
                           deposit_item_type,
                           container_item,
                           deposit_in_price_per_uom,
                           tsl_base_item,
                           -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - Begin --
                           tsl_mu_ind,
                           -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - End --
                           -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 Begin
                           tsl_common_ind,
                           tsl_primary_country,
                           -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 End
                           ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
                           --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
                           tsl_retail_barcode_auth,
                           tsl_occ_barcode_auth,
                           -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                           tsl_consumer_unit,
                           -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                           --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
                           ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
                           -- CR354 13-Aug-2010 Raghuveer P R Begin
                           tsl_owner_country,
                           -- CR354 13-Aug-2010 Raghuveer P R End
                           --CR434 28-Oct-2011 shweta.madnawat@in.tesco.com, Begin
                           tsl_restrict_price_event,
                           --CR434 28-Oct-2011 shweta.madnawat@in.tesco.com, End
                           tsl_deactivated,
                           tsl_deactivate_date
                           )
                    SELECT it.item,
                           it.item_number_type,
                           it.format_id,
                           NVL(it.prefix, im.prefix),
                           it.existing_item_parent,
                           im.item_parent,
                           im.pack_ind,
                           it.item_level,
                           im.tran_level,
                           'N',
                           it.diff_1,
                           'N',
                           it.diff_2,
                           'N',
                           it.diff_3,
                           'N',
                           it.diff_4,
                           'N',
                           im.dept,
                           im.CLASS,
                           im.subclass,
                           --22-July-2013 Smitha Ramesh - Modified as part of CR 480 Begin
                           decode(L_deactivate_ind,'Y','A','W'),
                           ----22-July-2013 Smitha Ramesh - Modified as part of CR 480 End
                           it.item_desc,
                           im.item_desc_secondary,
                           im.short_desc,
                           UPPER(it.item_desc),
                           --16-Oct-2007 WiproEnabler/Ramasamy - Modified to add the column -For CQ 3541 Begin
                           NVL(I_prim_ref_item_ind, 'N'),
                           --16-Oct-2007 WiproEnabler/Ramasamy - Modified to add the column -For CQ 3541 End
                           im.retail_zone_group_id,
                           im.cost_zone_group_id,
                           im.standard_uom,
                           im.uom_conv_factor,
                           im.package_size,
                           im.package_uom,
                           im.merchandise_ind,
                           im.store_ord_mult,
                           im.forecast_ind,
                           im.original_retail,
                           im.mfg_rec_retail,
                           im.retail_label_type,
                           im.retail_label_value,
                           -- DefNBS017889 14-Jun-2010 Chandru Begin
                           -- Removing 17356 fix as part of 17889 design change
                           im.handling_temp,
                           im.handling_sensitivity,
                           -- DefNBS017889 14-Jun-2010 Chandru End
                           im.catch_weight_ind,
                           NULL,
                           NULL,
                           NULL,
                           im.waste_type,
                           im.waste_pct,
                           im.default_waste_pct,
                           im.const_dimen_ind,
                           im.simple_pack_ind,
                           im.contains_inner_ind,
                           im.sellable_ind,
                           im.orderable_ind,
                           im.pack_type,
                           im.order_as_type,
                           im.comments,
                           im.gift_wrap_ind,
                           im.ship_alone_ind,
                           im.check_uda_ind,
                           L_sysdate,
                           L_user,
                           L_sysdate,
                           im.item_xform_ind,
                           im.inventory_ind,
                           -- DefNBS017889 14-Jun-2010 Chandru Begin
                           -- Removed 17356 fix as part of 17889 design change
                           im.order_type,
                           im.sale_type,
                           -- DefNBS017889 14-Jun-2010 Chandru End
                           im.deposit_item_type,
                           im.container_item,
                           im.deposit_in_price_per_uom,
                           it.tsl_base_item,
                           -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - Begin --
                           im.tsl_mu_ind,
                           -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - End --
                           -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 Begin
                           -- 24-Jun-2008 TESCO HSC/Murali    Mod N111  Begin
                           CASE
                              when it.item_level = 2 and im.pack_ind = 'N' then 'N'
                              else im.tsl_common_ind
                           END,
                           -- 24-Jun-2008 TESCO HSC/Murali    Mod N111  End
                           im.tsl_primary_country,
                           -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 End
                           ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
                           --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
                           decode(L_pack_ind,'Y','N',I_occ_ret_barcode_auth),
                           decode(L_pack_ind,'Y',I_occ_ret_barcode_auth,'N'),
                           -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                           it.tsl_consumer_unit,
                           -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                           --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
                           ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
                           -- CR354 13-Aug-2010 Raghuveer P R Begin
                           it.tsl_owner_country,
                           -- CR354 13-Aug-2010 Raghuveer P R End
                           --CR434 28-Oct-2011 shweta.madnawat@in.tesco.com, Begin
                           CASE
                              when it.item_level = 2 and im.tran_level = 2 then im.tsl_restrict_price_event
                              else 'N'
                           END,
                           --CR434 28-Oct-2011 shweta.madnawat@in.tesco.com, End
                           --26-July-2013 Smitha Ramesh - Modified as part of CR 480 Begin
                           L_deactivate_ind,
                           L_deactivate_date
                           --26-July-2013 Smitha Ramesh - Modified as part of CR 480 End
                      FROM item_master im,
                           item_temp it
                     WHERE im.item = it.existing_item_parent;
         ---
   --03-May-2007 WiproEnabler/Ramasamy - MOD 365a  Added column tsl_base_item End
   IF L_ref_item IS NOT NULL THEN
      UPDATE item_master
      SET    primary_ref_item_ind = 'Y'
      WHERE  item = L_ref_item;
   END IF;
   --26-July-2013 Smitha Ramesh - Modified as part of CR 480 Begin
   if L_deactivate_date is not null and L_deactivate_ind='Y' then
         if DAILY_PURGE_SQL.INSERT_RECORD(O_error_message,
                                                L_item,
                                                'ITEM_MASTER',
                                                'D',
                                                L_delete_order) = FALSE then
                  return FALSE;
               end if;
   end if;
    --26-July-2013 Smitha Ramesh - Modified as part of CR 480 Begin
  --04-Oct-2007 Nitin Kumar - Mod N105   - Begin
   SQL_LIB.SET_MARK('FETCH','C_GET_TEMP_ITEMS','ITEM_TEMP',NULL);
   FOR C_rec IN C_GET_TEMP_ITEMS
   LOOP
      if (((C_rec.item_level in (2,3)) and (C_rec.pack_ind = 'N'))
         -- Defect NBS00010292 Raghuveer P R 12-Dec-2008  - Begin
         or (C_rec.item_level = 2 and C_rec.pack_ind = 'Y' and C_rec.simple_pack_ind = 'N' and C_rec.item_number_type = 'TPNB')) then
         -- Defect NBS00010292 Raghuveer P R 12-Dec-2008  - End
         -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
         if C_rec.tsl_consumer_unit is NULL then
         -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
            if TSL_ITEM_NUMBER_SQL.SET_CONSUMER_UNIT(O_error_message ,
                                                     C_rec.item) = FALSE then
               return FALSE;
            end if;
         -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
         end if;
         -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
      end if;
      -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 Begin
      if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                               L_system_options_row) = FALSE then
         return FALSE;
      end if;
      if C_rec.item_level > C_rec.tran_level then
         --
         if NVL(L_old_item_parent, '-') != C_rec.existing_item_parent then
            if ITEM_ATTRIB_SQL.TSL_GET_COMMON_IND(O_error_message,
                                                  L_common_ind,
                                                  C_rec.existing_item_parent) = FALSE then
               return FALSE;
            end if;
            if L_common_ind = 'N' then
               L_item_parent_common := 'N';
            else
               if TSL_COMMON_VALIDATE_SQL.CHECK_ITEM_PRIM_INSTANCE(O_error_message,
                                                                   L_exists,
                                                                   C_rec.existing_item_parent) = FALSE then
                  return FALSE;
               end if;
               if L_exists = FALSE then
                  L_item_parent_common := 'N';
               else
                  L_item_parent_common := 'Y';
               end if;
            end if;
         end if;
         --
         L_old_item_parent := C_rec.existing_item_parent;
         --
         if L_item_parent_common = 'Y' then
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_ITEM_MASTER',
                             'ITEM_MASTER',
                              NULL);
            open C_LOCK_ITEM_MASTER(C_rec.item);

            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_ITEM_MASTER',
                             'ITEM_MASTER',
                              NULL);
            close C_LOCK_ITEM_MASTER;

            --Update item_master and make the item as common
            SQL_LIB.SET_MARK('UPDATE',
                              NULL,
                             'ITEM_MASTER',
                              NULL);
            update item_master im
               set im.tsl_common_ind      = 'Y',
                   im.tsl_primary_country = L_system_options_row.tsl_origin_country
             where im.item       = C_rec.item
               and im.item_level > im.tran_level;
         end if;
         --
      end if;
      -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 End
   END LOOP;
   --04-Oct-2007 Nitin Kumar - Mod N105   End

         ---
   RETURN TRUE;

EXCEPTION
   --03-May-2007 WiproEnabler/Ramasamy - MOD 365a   Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             'ITEM_TEMP',
                                             L_program,
                                             NULL);
      return FALSE;
   --03-May-2007 WiproEnabler/Ramasamy - MOD 365a   End
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
   RETURN FALSE;
END INSERT_ITEM_MASTER;
-------------------------------------------------------------------
FUNCTION INSERT_ITEM_SUPPLIER(O_error_message   IN OUT   VARCHAR2,
                              I_item            IN       ITEM_MASTER.ITEM%TYPE,
                              I_item_parent     IN       ITEM_MASTER.ITEM_PARENT%TYPE)
RETURN BOOLEAN IS
   L_program VARCHAR2(40) := 'ITEM_CREATE_SQL.INSERT_ITEM_SUPPLIER';
   L_user    VARCHAR2(30) := USER;

BEGIN
   IF I_item IS NOT NULL AND I_item_parent IS NOT NULL THEN
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPPLIER','ITEM: '||I_item);
      INSERT INTO item_supplier(item,
                                supplier,
                                primary_supp_ind,
                                vpn,
                                supp_label,
                                consignment_rate,
                                supp_diff_1,
                                supp_diff_2,
                                supp_diff_3,
                                supp_diff_4,
                                pallet_name,
                                case_name,
                                inner_name,
                                supp_discontinue_date,
                                direct_ship_ind,
                                last_update_datetime,
                                last_update_id,
                                create_datetime,
                                concession_rate,
								--27-Sep-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com NBS00026243-Begin
                                tsl_owner_country
                                --27-Sep-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com NBS00026243-End
								)
                         SELECT I_item,
                                supplier,
                                primary_supp_ind,
                                -- 01-Jun-10    JK    MrgNBS017783   Begin
                                -- CR258 27-Apr-2010 Chandru Begin
                                vpn,
                                supp_label,
                                -- CR258 27-Apr-2010 Chandru End
                                -- 01-Jun-10    JK    MrgNBS017783   End
                                consignment_rate,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                pallet_name,
                                case_name,
                                inner_name,
                                supp_discontinue_date,
                                direct_ship_ind,
                                SYSDATE,
                                L_user,
                                SYSDATE,
                                concession_rate,
                                --27-Sep-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com NBS00026243-Begin
                                tsl_owner_country
                                --27-Sep-2013 , Smitha Ramesh, smitharamesh.areyada@in.tesco.com NBS00026243-End
                           FROM item_supplier
                          WHERE item = I_item_parent;
   END IF;
   ---
   RETURN TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      RETURN FALSE;
END INSERT_ITEM_SUPPLIER;
-------------------------------------------------------------------
FUNCTION SUB_TRAN_INSERT_ITEM_SUPPLIER(O_error_message   IN OUT   VARCHAR2,
                                       I_item_parent     IN       ITEM_MASTER.ITEM_PARENT%TYPE)
RETURN BOOLEAN IS
   L_program     VARCHAR2(80)                := 'ITEM_CREATE_SQL.SUB_TRAN_INSERT_ITEM_SUPPLIER';
   L_user        VARCHAR2(30)                := USER;
   L_item_parent ITEM_MASTER.ITEM%TYPE       := I_item_parent;

BEGIN
   IF I_item_parent IS NULL THEN
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_parent',
                                             L_program,
                                             NULL);
      RETURN FALSE;
   END IF;

   SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPPLIER','ITEM: '||NULL);
   INSERT INTO item_supplier(item,
                             supplier,
                             primary_supp_ind,
                             vpn,
                             supp_label,
                             consignment_rate,
                             supp_diff_1,
                             supp_diff_2,
                             supp_diff_3,
                             supp_diff_4,
                             pallet_name,
                             case_name,
                             inner_name,
                             supp_discontinue_date,
                             direct_ship_ind,
                             last_update_datetime,
                             last_update_id,
                             create_datetime)
                      SELECT it.item,
                             its.supplier,
                             its.primary_supp_ind,
                             -- 01-Jun-10    JK    MrgNBS017783   Begin
                             -- CR258 27-Apr-2010 Chandru Begin
                             vpn,
                             supp_label,
                             -- CR258 27-Apr-2010 Chandru End
                             -- 01-Jun-10    JK    MrgNBS017783   End
                             its.consignment_rate,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             its.pallet_name,
                             its.case_name,
                             its.inner_name,
                             its.supp_discontinue_date,
                             its.direct_ship_ind,
                             SYSDATE,
                             L_user,
                             SYSDATE
                        FROM item_supplier its,
                   item_temp it
                       WHERE its.item = I_item_parent;
   RETURN TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      RETURN FALSE;
END SUB_TRAN_INSERT_ITEM_SUPPLIER;
--------------------------------------------------------------------------
FUNCTION INSERT_ITEM_MASTER(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            I_item_rec        IN       ITEM_MASTER%ROWTYPE,
                            --17-May-2010     TESCO HSC/Joy Stephen     DefNBS017480    Begin
                            I_message         IN       RIB_XITEMDESC_REC)
                            --17-May-2010     TESCO HSC/Joy Stephen     DefNBS017480    End
   RETURN BOOLEAN IS

   L_program               VARCHAR2(50) := 'RMSSUB_XITEM_VALIDATE.INSERT_ITEM_MASTER';
   L_primary_ref_item_ind  CHAR(1);

   --07-Mar-2011 TESCO HSC/Nandini Mariyappa   DefNBS021784   Begin
   L_parent_diff_1   DIFF_IDS.DIFF_ID%TYPE;
   L_parent_diff_2   DIFF_IDS.DIFF_ID%TYPE;
   L_parent_diff_3   DIFF_IDS.DIFF_ID%TYPE;
   L_parent_diff_4   DIFF_IDS.DIFF_ID%TYPE;
   --07-Mar-2011 TESCO HSC/Nandini Mariyappa   DefNBS021784   End

   -- 28-Mar-2011 Veena Nanjundaiah / veena.nanjundaiah@in.tesco.com  DefNBS022119  Begin
   L_handling_temp         SUBCLASS.TSL_HANDLING_TEMP%TYPE  := NULL;
   -- 28-Mar-2011 Veena Nanjundaiah / veena.nanjundaiah@in.tesco.com  DefNBS022119  End

   CURSOR C_CHECK_REC_EXISTS IS
   SELECT 'N'
   FROM item_master
   WHERE item_parent = I_item_rec.item_parent
   AND rownum = 1;

   --17-May-2010     TESCO HSC/Joy Stephen     DefNBS017480    Begin
   --This cursor fetches cost_zone_group_id for Packs.
   CURSOR C_GET_PACK_COST_ZONE_GRP is
   select im.cost_zone_group_id
     from item_master im
    where im.item = I_message.XItemBOMDesc_TBL(1).component_item;

   --This cursor fetches cost_zone_group_id for EAN/OCC.
   CURSOR C_GET_BARCODE_COST_ZONE_GRP is
   select im.cost_zone_group_id
     from item_master im
    where im.item = I_message.item_parent;

   L_cost_zone_group_id   ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE;
   --17-May-2010     TESCO HSC/Joy Stephen     DefNBS017480    End

   --21-May-2010     TESCO HSC/Reshma Koshy    DefNBS017568    Begin
   L_item_desc_sec         ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE  := NULL;
   CURSOR C_FETCH_SEC_DESC is
      select item_desc_secondary
        from item_master
       where item = I_message.item_parent;
   --21-May-2010     TESCO HSC/Reshma Koshy    DefNBS017568    End

   -- 28-Mar-2011 Veena Nanjundaiah / veena.nanjundaiah@in.tesco.com  DefNBS022119  Begin
   CURSOR C_FETCH_HANDLING_TEMP is
      select tsl_handling_temp
        from subclass
       where dept  = I_item_rec.dept
         and class = I_item_rec.CLASS
         and subclass = I_item_rec.subclass;
   -- 28-Mar-2011 Veena Nanjundaiah / veena.nanjundaiah@in.tesco.com  DefNBS022119  End

BEGIN

   L_primary_ref_item_ind := I_item_rec.primary_ref_item_ind;
   if I_item_rec.item_level > I_item_rec.tran_level then
      open C_CHECK_REC_EXISTS;
      fetch C_CHECK_REC_EXISTS into L_primary_ref_item_ind;
      if C_CHECK_REC_EXISTS%NOTFOUND then
         L_primary_ref_item_ind := 'Y';
      end if;
      close C_CHECK_REC_EXISTS;
   end if;

   --17-May-2010     TESCO HSC/Joy Stephen     DefNBS017480    Begin
   L_cost_zone_group_id := NULL;
   if I_message.simple_pack_ind = 'Y' and I_message.pack_ind = 'Y' and I_message.item_level = I_message.tran_level then
      OPEN C_GET_PACK_COST_ZONE_GRP;
      FETCH C_GET_PACK_COST_ZONE_GRP into L_cost_zone_group_id;
      CLOSE C_GET_PACK_COST_ZONE_GRP;
   elsif I_message.item_level > I_message.tran_level then
      OPEN C_GET_BARCODE_COST_ZONE_GRP;
      FETCH C_GET_BARCODE_COST_ZONE_GRP into L_cost_zone_group_id;
      CLOSE C_GET_BARCODE_COST_ZONE_GRP;
   else
      L_cost_zone_group_id := I_message.cost_zone_group_id;
   end if;
   --17-May-2010     TESCO HSC/Joy Stephen     DefNBS017480    End
   --21-May-2010     TESCO HSC/Reshma Koshy    DefNBS017568    Begin
   if I_message.item_level > I_message.tran_level and I_message.item_desc_secondary is NULL then
      open C_FETCH_SEC_DESC;
      fetch C_FETCH_SEC_DESC into L_item_desc_sec;
      close C_FETCH_SEC_DESC;
   else
      L_item_desc_sec := I_message.item_desc_secondary;
   end if;
   --21-May-2010     TESCO HSC/Reshma Koshy    DefNBS017568    End
   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_MASTER','item: '||I_item_rec.item);

   --07-Mar-2011 TESCO HSC/Nandini Mariyappa   DefNBS021784   Begin
   if (I_message.item_level > I_message.tran_level and
       I_message.item_parent is NOT NULL) then

      if not ITEM_ATTRIB_SQL.GET_DIFFS(O_error_message,
                                       L_parent_diff_1,
                                       L_parent_diff_2,
                                       L_parent_diff_3,
                                       L_parent_diff_4,
                                       I_message.item_parent) then
         return FALSE;
      end if;
   end if;
   --07-Mar-2011 TESCO HSC/Nandini Mariyappa   DefNBS021784   End

   -- 28-Mar-2011 Veena Nanjundaiah / veena.nanjundaiah@in.tesco.com  DefNBS022119  Begin
   if I_item_rec.handling_temp is NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_FETCH_HANDLING_TEMP',
                       'SUBCLASS',
                       'L_handling_temp : '||L_handling_temp);
      open C_FETCH_HANDLING_TEMP;

      SQL_LIB.SET_MARK('FETCH',
                       'C_FETCH_HANDLING_TEMP',
                       'SUBCLASS',
                       'L_handling_temp : '||L_handling_temp);
      fetch C_FETCH_HANDLING_TEMP into L_handling_temp;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_FETCH_HANDLING_TEMP',
                       'SUBCLASS',
                       'L_handling_temp : '||L_handling_temp);
      close C_FETCH_HANDLING_TEMP;
   else
      L_handling_temp := I_item_rec.handling_temp;
   end if;
   -- 28-Mar-2011 Veena Nanjundaiah / veena.nanjundaiah@in.tesco.com  DefNBS022119  End

   INSERT INTO item_master(item,
                           item_number_type,
                           format_id,
                           prefix,
                           item_parent,
                           item_grandparent,
                           pack_ind,
                           item_level,
                           tran_level,
                           item_aggregate_ind,
                           diff_1,
                           diff_1_aggregate_ind,
                           diff_2,
                           diff_2_aggregate_ind,
                           diff_3,
                           diff_3_aggregate_ind,
                           diff_4,
                           diff_4_aggregate_ind,
                           dept,
                           CLASS,
                           subclass,
                           status,
                           item_desc,
                           item_desc_secondary,
                           short_desc,
                           desc_up,
                           primary_ref_item_ind,
                           retail_zone_group_id,
                           cost_zone_group_id,
                           standard_uom,
                           uom_conv_factor,
                           package_size,
                           package_uom,
                           merchandise_ind,
                           store_ord_mult,
                           forecast_ind,
                           original_retail,
                           mfg_rec_retail,
                           retail_label_type,
                           retail_label_value,
                           handling_temp,
                           handling_sensitivity,
                           catch_weight_ind,
                           first_received,
                           last_received,
                           qty_received,
                           waste_type,
                           waste_pct,
                           default_waste_pct,
                           const_dimen_ind,
                           simple_pack_ind,
                           contains_inner_ind,
                           sellable_ind,
                           orderable_ind,
                           pack_type,
                           order_as_type,
                           comments,
                           item_service_level,
                           gift_wrap_ind,
                           ship_alone_ind,
                           create_datetime,
                           last_update_id,
                           last_update_datetime,
                           check_uda_ind,
                           item_xform_ind,
                           inventory_ind,
                           order_type,
                           sale_type,
                           deposit_item_type,
                           container_item,
                           deposit_in_price_per_uom,
                           --13-Jun-2007 WiproEnabler/RK        Mod:365a Begin
                           tsl_base_item,
                           tsl_price_mark_ind,
                           tsl_prim_pack_ind,
                           tsl_launch_base_ind,
                           tsl_external_item_ind,
                           --13-Jun-2007 WiproEnabler/RK        Mod:365a End
                           --10-Oct-2007 TESCO HSC/Rahul Soni   Mod:N22 Begin
                           tsl_occ_barcode_auth,
                           tsl_retail_barcode_auth,
                           --10-Oct-2007 TESCO HSC/Rahul Soni   Mod:N22 End
                           --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    Begin
                           tsl_consumer_unit,
                           --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    End
                           --17-Mar-2008 Tesco HSC/Usha Patil       Mod:N126  Begin
                           tsl_deactivate_date,
                           --17-Mar-2008 Tesco HSC/Usha Patil       Mod:N126  End
                           --18-Mar-2008 Tesco HSC/Rahul Soni       Mod:N114 Begin
                           tsl_variant_reason_code,
                           --18-Mar-2008 Tesco HSC/Rahul Soni       Mod:N114 End
                           -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - Begin --
                           tsl_mu_ind,
                           -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - End --
                           -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 Begin
                           tsl_common_ind,
                           --CR354 Raghuveer P R 19-Aug-2010 -Begin
                           --tsl_primary_country,
                           tsl_owner_country,
                           --CR354 Raghuveer P R 19-Aug-2010 -End
                           -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 End
                           --23-May-2008     TESCO HSC Vijaya Bhaskar/Wipro-Enabler        Mod:N127    Begin
                           tsl_range_auth_ind,
                           --23-May-2008     TESCO HSC Vijaya Bhaskar/Wipro-Enabler        Mod:N127    End
                           --11-Nov-2008     TESCO HSC/Nandini Mariyappa   Mod:N128  Begin
                           tsl_primary_cua,
                           --11-Nov-2008     TESCO HSC/Nandini Mariyappa   Mod:N128  End
                           -- CR165, 07-Jan-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
                           tsl_suspended,
                           tsl_suspend_date,
                           -- CR165, 07-Jan-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
                           -- 13-Apr-2009     TESCO HSC/Govindarajan K,    Mod:N156    Begin
                           tsl_item_upload_ind,
                           -- 13-Apr-2009     TESCO HSC/Govindarajan K,    Mod:N156    End
                           --17-Apr-2009 Tesco HSC/Usha Patil       Defect Id:NBS00012450 Begin
                           tsl_price_marked_except_ind,
                           --17-Apr-2009 Tesco HSC/Usha Patil       Defect Id:NBS00012450 End
                           ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 Begin
                           ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 Begin
                           --18-Feb-2010 Tesco HSC/Nandini Mariyappa       Mod CR288   Begin
                           tsl_primary_cua_roi,
                           --18-Feb-2010 Tesco HSC/Nandini Mariyappa       Mod CR288   End
                           ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 End
                           --26-Oct-2011 Vatan Jaiswal, vatan.jaiswal@in.tesco.com CR434, Begin
                           tsl_restrict_price_event
                           --26-Oct-2011 Vatan Jaiswal, vatan.jaiswal@in.tesco.com CR434, Begin

                          )
                    VALUES(I_item_rec.item,
                           I_item_rec.item_number_type,
                           I_item_rec.format_id,
                           I_item_rec.prefix,
                           I_item_rec.item_parent,
                           I_item_rec.item_grandparent,
                           I_item_rec.pack_ind,
                           I_item_rec.item_level,
                           I_item_rec.tran_level,
                           I_item_rec.item_aggregate_ind,
                           --07-Mar-2011 TESCO HSC/Nandini Mariyappa   DefNBS021784   Begin
                           NVL(I_item_rec.diff_1,L_parent_diff_1),
                           I_item_rec.diff_1_aggregate_ind,
                           NVL(I_item_rec.diff_2,L_parent_diff_2),
                           I_item_rec.diff_2_aggregate_ind,
                           NVL(I_item_rec.diff_3,L_parent_diff_3),
                           I_item_rec.diff_3_aggregate_ind,
                           NVL(I_item_rec.diff_4,L_parent_diff_4),
                           --07-Mar-2011 TESCO HSC/Nandini Mariyappa   DefNBS021784   End
                           I_item_rec.diff_4_aggregate_ind,
                           I_item_rec.dept,
                           I_item_rec.CLASS,
                           I_item_rec.subclass,
                           I_item_rec.status,
                           I_item_rec.item_desc,
                           --21-May-2010     TESCO HSC/Reshma Koshy    DefNBS017568    Begin
                           NVL(I_item_rec.item_desc_secondary,L_item_desc_sec),
                           --21-May-2010     TESCO HSC/Reshma Koshy    DefNBS017568    End
                           I_item_rec.short_desc,
                           I_item_rec.desc_up,
                           L_primary_ref_item_ind,
                           I_item_rec.retail_zone_group_id,
                           --17-May-2010     TESCO HSC/Joy Stephen     DefNBS017480    Begin
                           L_cost_zone_group_id,
                           --17-May-2010     TESCO HSC/Joy Stephen     DefNBS017480    End
                           I_item_rec.standard_uom,
                           I_item_rec.uom_conv_factor,
                           I_item_rec.package_size,
                           I_item_rec.package_uom,
                           I_item_rec.merchandise_ind,
                           I_item_rec.store_ord_mult,
                           I_item_rec.forecast_ind,
                           I_item_rec.original_retail,
                           I_item_rec.mfg_rec_retail,
                           I_item_rec.retail_label_type,
                           I_item_rec.retail_label_value,
                           -- 28-Mar-2011 Veena Nanjundaiah / veena.nanjundaiah@in.tesco.com  DefNBS022119  Begin
                           L_handling_temp,
                           -- I_item_rec.handling_temp,
                           -- 28-Mar-2011 Veena Nanjundaiah / veena.nanjundaiah@in.tesco.com  DefNBS022119  End
                           I_item_rec.handling_sensitivity,
                           I_item_rec.catch_weight_ind,
                           I_item_rec.first_received,
                           I_item_rec.last_received,
                           I_item_rec.qty_received,
                           I_item_rec.waste_type,
                           I_item_rec.waste_pct,
                           I_item_rec.default_waste_pct,
                           I_item_rec.const_dimen_ind,
                           I_item_rec.simple_pack_ind,
                           I_item_rec.contains_inner_ind,
                           I_item_rec.sellable_ind,
                           I_item_rec.orderable_ind,
                           I_item_rec.pack_type,
                           I_item_rec.order_as_type,
                           I_item_rec.comments,
                           I_item_rec.item_service_level,
                           I_item_rec.gift_wrap_ind,
                           I_item_rec.ship_alone_ind,
                           I_item_rec.create_datetime,
                           I_item_rec.last_update_id,
                           SYSDATE,
                           I_item_rec.check_uda_ind,
                           I_item_rec.item_xform_ind,
                           I_item_rec.inventory_ind,
                           I_item_rec.order_type,
                           I_item_rec.sale_type,
                           I_item_rec.deposit_item_type,
                           I_item_rec.container_item,
                           I_item_rec.deposit_in_price_per_uom,
                           --13-Jun-2007 WiproEnabler/RK        Mod:365a Begin
                           I_item_rec.tsl_base_item,
                           I_item_rec.tsl_price_mark_ind,
                           I_item_rec.tsl_prim_pack_ind,
                           I_item_rec.tsl_launch_base_ind,
                           I_item_rec.tsl_external_item_ind,
                           --13-Jun-2007 WiproEnabler/RK        Mod:365a End
                           --10-Oct-2007 TESCO HSC/Rahul Soni   Mod:N22 Begin
                           --01-Apr-2008 TESCO HSC/Vinod        DefNBS00005519  Begin
                           --20-Aug-2009 Tesco HSC/Nandini Mariyappa       Defect#:NBS00014541   Begin
                           NVL(I_item_rec.tsl_occ_barcode_auth,'N'),
                           NVL(I_item_rec.tsl_retail_barcode_auth,'N'),
                           --20-Aug-2009 Tesco HSC/Nandini Mariyappa       Defect#:NBS00014541   End
                           --01-Apr-2008 TESCO HSC/Vinod        DefNBS00005519  End
                           --10-Oct-2007 TESCO HSC/Rahul Soni   Mod:N22 End
                           --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    Begin
                           I_item_rec.tsl_consumer_unit,
                           --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    End
                           --17-Mar-2008 Tesco HSC/Usha Patil       Mod:N126  Begin
                           I_item_rec.tsl_deactivate_date,
                           --17-Mar-2008 Tesco HSC/Usha Patil       Mod:N126  End
                           --18-Mar-2008 Tesco HSC/Rahul Soni       Mod:N114 Begin
                           I_item_rec.tsl_variant_reason_code,
                           --18-Mar-2008 Tesco HSC/Rahul Soni       Mod:N114 End
                           -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - Begin --
                           I_item_rec.tsl_mu_ind,
                           -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - End --
                           -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 Begin
                           -- 24-Jun-2008 Tesco HSC/Vinod                  Mod:N111 Begin
                           NVL(I_item_rec.tsl_common_ind,'N'),
                           -- 24-Jun-2008 Tesco HSC/Vinod                  Mod:N111 End
                           --CR354 Raghuveer P R 19-Aug-2010 - Begin
                           DECODE(I_item_rec.tsl_primary_country,'B','U',I_item_rec.tsl_primary_country),
                           --I_item_rec.tsl_owner_country,
                           --CR354 Raghuveer P R 19-Aug-2010 - End
                           -- 09-May-2008, Nitin Kumar,nitin.kumar@in.tesco.com, Mod N111 End
                           --23-May-2008     TESCO HSC Vijaya Bhaskar/Wipro-Enabler        Mod:N127    Begin
                           NVL(I_item_rec.tsl_range_auth_ind,'N'),
                           --11-Nov-2008     TESCO HSC/Nandini Mariyappa   Mod:N128  Begin
                           I_item_rec.tsl_primary_cua,
                           --11-Nov-2008     TESCO HSC/Nandini Mariyappa   Mod:N128  End
                           -- CR165, 07-Jan-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
                           I_item_rec.tsl_suspended,
                           I_item_rec.tsl_suspend_date,
                           -- CR165, 07-Jan-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
                           -- N156, 13-Apr-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                           NVL(I_item_rec.tsl_item_upload_ind,'N'),
                           -- N156, 13-Apr-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                           --17-Apr-2009 Tesco HSC/Usha Patil       Defect Id:NBS00012450 Begin
                           NVL(I_item_rec.tsl_price_marked_except_ind,'N'),
                           --17-Apr-2009 Tesco HSC/Usha Patil       Defect Id:NBS00012450 End
                           ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 Begin
                           --18-Feb-2010 Tesco HSC/Nandini Mariyappa       Mod CR288   Begin
                           I_item_rec.tsl_primary_cua_roi,
                           --18-Feb-2010 Tesco HSC/Nandini Mariyappa       Mod CR288   End
                           ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 End
                           --26-Oct-2011 Vatan Jaiswal, vatan.jaiswal@in.tesco.com CR434, Begin
                           NVL(I_item_rec.tsl_restrict_price_event, 'N')
                           --26-Oct-2011 Vatan Jaiswal, vatan.jaiswal@in.tesco.com CR434, End
                           );
                           --23-May-2008     TESCO HSC Vijaya Bhaskar/Wipro-Enabler        Mod:N127    End
   RETURN TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;

END INSERT_ITEM_MASTER;
------------------------------------------------------------------

FUNCTION MASS_UPDATE_CHILDREN(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_supplier          IN       SUPS.SUPPLIER%TYPE,
                              I_item_parent       IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                              I_rpm_zone_group_id IN       ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE,
                              I_rpm_zone_id       IN       ITEM_ZONE_PRICE.ZONE_ID%TYPE,
                              I_rpm_currency_code IN       CURRENCIES.CURRENCY_CODE%TYPE,
                              I_diff_group_id     IN       DIFF_GROUP_DETAIL.DIFF_GROUP_ID%TYPE,
                              I_diff_id           IN       DIFF_GROUP_DETAIL.DIFF_ID%TYPE,
                              I_supp_diff_id      IN       DIFF_GROUP_DETAIL.DIFF_ID%TYPE,
                              I_unit_retail       IN       ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE,
                              I_unit_cost         IN       ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                              I_generate_ean      IN       BOOLEAN,
                              I_auto_approve      IN       VARCHAR2)
RETURN BOOLEAN IS

   L_program               VARCHAR2(40) := 'ITEM_CREATE_SQL.MASS_UPDATE_CHILDREN';
   L_supplier_diff_number  ITEM_MASTER.DIFF_1%TYPE;
   L_standard_uom          ITEM_MASTER.STANDARD_UOM%TYPE;
   L_standard_class        UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor           ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_zone_currency         PRICE_ZONE.CURRENCY_CODE%TYPE;
   L_to_value              NUMBER;
   L_retail                NUMBER;
   L_selling_unit_retail   NUMBER;
   L_table                 VARCHAR2(20) := 'ITEM_SUPPLIER';
   L_child_table_index     NUMBER := 1;
   L_child_item_table      PM_RETAIL_API_SQL.CHILD_ITEM_PRICING_TABLE;
   L_first_ean_exists      BOOLEAN;
   L_ean                   ITEM_MASTER.ITEM%TYPE;
   L_item_number_type      ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(RECORD_LOCKED, -54);

   L_location_table        OBJ_RPM_LOC_TBL;
   L_prev_item             ITEM_MASTER.ITEM%TYPE;

   L_zone_group_id         CONSTANT NUMBER(10) := 1;

   L_itemloc_table OBJ_ITEMLOC_TBL := OBJ_ITEMLOC_TBL();
   L_item_table ITEM_TBL;

   TYPE TABLE1 IS TABLE OF ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE
      INDEX BY BINARY_INTEGER;

   TYPE TABLE2 IS TABLE OF ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE
      INDEX BY BINARY_INTEGER;

   TYPE TABLE3 IS TABLE OF ITEM_ZONE_PRICE.ZONE_ID%TYPE
      INDEX BY BINARY_INTEGER;

   TYPE TABLE4 IS TABLE OF ITEM_ZONE_PRICE.ITEM%TYPE
      INDEX BY BINARY_INTEGER;

   L_rpm_selling_unit  TABLE1;
   L_rpm_zone_group_id TABLE2;
   L_rpm_zone_id       TABLE3;
   L_rpm_item          TABLE4;
   L_cnt               NUMBER := 0;

   CURSOR C_LOCK_ITEM_SUPPLIER IS
      SELECT isupp.supp_diff_1
        FROM item_supplier isupp
       WHERE isupp.supplier=I_supplier
         AND isupp.item IN (SELECT im.item
                              FROM item_master im
                             WHERE im.item_parent=I_item_parent
                               AND I_diff_id IS NULL
                               AND EXISTS (SELECT '1'
                                             FROM diff_group_detail dgd
                                            WHERE dgd.diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                                              AND dgd.diff_group_id=I_diff_group_id
                  AND ROWNUM = 1)
                             UNION
                            SELECT im.item
                              FROM item_master im
                             WHERE im.item_parent=I_item_parent
                               AND I_diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                               AND I_diff_id IS NOT NULL
                             UNION
                            SELECT im.item
                              FROM item_master im
                             WHERE im.item_parent=I_item_parent
                               AND I_diff_group_id IS NULL
                               AND I_diff_id IS NULL)
      FOR UPDATE OF supp_diff_1 NOWAIT;

   CURSOR C_GET_SUPP_DIFF_NUMBER IS
      SELECT DECODE(I_diff_group_id,diff_1,1,diff_2,2,diff_3,3,diff_4,4)
        FROM item_master
       WHERE item=I_item_parent;

   CURSOR C_LOCK_ITEM_SUPP_COUNTRY IS
      SELECT isc.unit_cost
        FROM item_supp_country isc
       WHERE isc.supplier=I_supplier
         AND isc.primary_country_ind ='Y'
         AND isc.item IN (SELECT im.item
                            FROM item_master im
                           WHERE im.item_parent=I_item_parent
                             AND im.status='W'
                             AND I_diff_id IS NULL
                             AND EXISTS (SELECT '1'
                                           FROM diff_group_detail dgd
                                          WHERE dgd.diff_id IN (im.diff_1, im.diff_2,im.diff_3,im.diff_4)
                                            AND dgd.diff_group_id=I_diff_group_id
                AND ROWNUM = 1)
                           UNION
                          SELECT im.item
                            FROM item_master im
                           WHERE im.item_parent=I_item_parent
                             AND im.status='W'
                             AND I_diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                             AND I_diff_id IS NOT NULL
                           UNION
                          SELECT im.item
                            FROM item_master im
                           WHERE im.item_parent=I_item_parent
                             AND im.status='W'
                             AND I_diff_group_id IS NULL
                             AND I_diff_id IS NULL)
      FOR UPDATE OF unit_cost NOWAIT;

   CURSOR C_ITEM_CHILDREN_INFO IS
      SELECT im.item
        FROM item_master im
       WHERE im.item_parent = I_item_parent
         AND im.status IN ('W','S')
         AND I_diff_id IS NULL
         AND EXISTS (SELECT '1'
                       FROM diff_group_detail dgd
                      WHERE dgd.diff_id IN (im.diff_1, im.diff_2, im.diff_3, im.diff_4)
                        AND dgd.diff_group_id = I_diff_group_id
                        AND rownum = 1)
       UNION
      SELECT im.item
        FROM item_master im
       WHERE im.item_parent = I_item_parent
         AND im.status IN ('W','S')
         AND I_diff_id IN (im.diff_1, im.diff_2, im.diff_3, im.diff_4)
         AND I_diff_id IS NOT NULL
       UNION
      SELECT im.item
        FROM item_master im
       WHERE im.item_parent = I_item_parent
         AND im.status IN ('W','S')
         AND I_diff_group_id IS NULL
         AND I_diff_id IS NULL;

   CURSOR C_LOCK_ITEM_LOC IS
      SELECT il.item,
             il.loc,
             il.unit_retail,
             il.selling_unit_retail,
             il.regular_unit_retail,
             il.selling_uom,
             il.multi_units,
             il.multi_unit_retail,
             il.multi_selling_uom
        FROM item_loc il,
             TABLE(CAST(L_itemloc_table AS OBJ_ITEMLOC_TBL)) itl
       WHERE il.item = itl.item
         AND il.loc = itl.loc
       ORDER BY il.item
     FOR UPDATE OF unit_retail NOWAIT;

   TYPE UPDATE_ITEM_LOC_TYPE IS TABLE OF C_LOCK_ITEM_LOC%ROWTYPE INDEX BY BINARY_INTEGER;
   L_item_loc UPDATE_ITEM_LOC_TYPE;

   CURSOR C_APPLY_RECS IS
      SELECT im1.item,
             im1.item_desc,
             im1.diff_1,
             im1.diff_2,
             im1.diff_3,
             im1.diff_4,
             im1.status
        FROM item_master im1
       WHERE im1.item_parent = I_item_parent
         AND I_diff_id IS NULL
         AND EXISTS (SELECT '1'
                      FROM diff_group_detail dgd
                     WHERE dgd.diff_id IN (im1.diff_1,im1.diff_2,im1.diff_3,im1.diff_4)
                       AND dgd.diff_group_id=I_diff_group_id
           AND ROWNUM = 1)
       UNION
      SELECT im2.item,
             im2.item_desc,
             im2.diff_1,
             im2.diff_2,
             im2.diff_3,
             im2.diff_4,
             im2.status
        FROM item_master im2
       WHERE im2.item_parent=I_item_parent
         AND I_diff_id IN (im2.diff_1,im2.diff_2,im2.diff_3,im2.diff_4)
         AND I_diff_id IS NOT NULL
       UNION
      SELECT im3.item,
             im3.item_desc,
             im3.diff_1,
             im3.diff_2,
             im3.diff_3,
             im3.diff_4,
             im3.status
        FROM item_master im3
       WHERE im3.item_parent=I_item_parent
         AND I_diff_group_id IS NULL
         AND I_diff_id IS NULL;

BEGIN

   IF I_generate_ean = TRUE THEN
      FOR rec IN C_APPLY_RECS LOOP
         IF ITEM_ATTRIB_SQL.GET_FIRST_EAN(O_error_message,
                                          L_first_ean_exists,
                                          L_ean,
                                          L_item_number_type,
                                          rec.item) = FALSE THEN
            RETURN FALSE;
         END IF;
         --- Call package to auto generate the next EAN number
         IF L_ean IS NULL THEN
            IF ITEM_ATTRIB_SQL.NEXT_EAN (O_error_message,
                                         L_ean) = FALSE THEN
               RETURN FALSE;
            ELSE
               IF L_ean IS NOT NULL THEN

                  L_item_number_type := 'EAN13';
                  ---
                  --Create the level 3 EAN items
                  IF ITEM_CREATE_SQL.TRAN_CHILDREN_LEVEL3(O_error_message,
                                                          L_ean,
                                                          L_item_number_type,
                                                          3,
                                                          rec.item_desc,
                                                          rec.diff_1,
                                                          rec.diff_2,
                                                          rec.diff_3,
                                                          rec.diff_4,
                                                          rec.item,
                                                          I_auto_approve,
                                                          rec.status) = FALSE THEN
                     RETURN FALSE;
                  END IF;
                  ---
               END IF;
               ---
            END IF;
            ---
         END IF;

      END LOOP;

   END IF;

   IF I_supp_diff_id IS NOT NULL THEN

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPPLIER', 'ITEM_SUPPLIER', I_supplier);
      OPEN  C_LOCK_ITEM_SUPPLIER;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPPLIER', 'ITEM_SUPPLIER', I_supplier);
      CLOSE C_LOCK_ITEM_SUPPLIER;

      SQL_LIB.SET_MARK('OPEN', 'C_GET_SUPP_DIFF_NUMBER', 'ITEM_MASTER', I_item_parent);
      OPEN  C_GET_SUPP_DIFF_NUMBER;

      SQL_LIB.SET_MARK('FETCH', 'C_GET_SUPP_DIFF_NUMBER', 'ITEM_MASTER', I_item_parent);
      FETCH C_GET_SUPP_DIFF_NUMBER INTO L_supplier_diff_number;

      SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPP_DIFF_NUMBER', 'ITEM_MASTER', I_item_parent);
      CLOSE C_GET_SUPP_DIFF_NUMBER;

      SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_SUPPLIER', L_supplier_diff_number);

      UPDATE item_supplier
         SET supp_diff_1 = DECODE(L_supplier_diff_number,1,I_supp_diff_id,supp_diff_1),
             supp_diff_2 = DECODE(L_supplier_diff_number,2,I_supp_diff_id,supp_diff_2),
             supp_diff_3 = DECODE(L_supplier_diff_number,3,I_supp_diff_id,supp_diff_3),
             supp_diff_4 = DECODE(L_supplier_diff_number,4,I_supp_diff_id,supp_diff_4),
             last_update_datetime = SYSDATE,
             last_update_id       = USER
      WHERE  supplier=I_supplier
        AND  item IN (SELECT im.item
                        FROM item_master im
                       WHERE im.item_parent=I_item_parent
                         AND I_diff_id IS NULL
                         AND EXISTS (SELECT '1'
                                       FROM diff_group_detail dgd
                                      WHERE dgd.diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                                        AND dgd.diff_group_id=I_diff_group_id
                AND ROWNUM = 1)
                       UNION
                      SELECT im.item
                        FROM item_master im
                       WHERE im.item_parent=I_item_parent
                         AND I_diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                         AND I_diff_id IS NOT NULL
                       UNION
                      SELECT im.item
                        FROM item_master im
                       WHERE im.item_parent=I_item_parent
                         AND I_diff_group_id IS NULL
                         AND I_diff_id IS NULL);
   END IF;

   IF I_unit_cost IS NOT NULL THEN

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPPLIER', I_supplier);
      OPEN  C_LOCK_ITEM_SUPP_COUNTRY;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPPLIER', I_supplier);
      CLOSE C_LOCK_ITEM_SUPP_COUNTRY;

      SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_SUPPLIER_COUNTRY', I_supplier);

      UPDATE item_supp_country
         SET unit_cost=I_unit_cost
       WHERE supplier=I_supplier
         AND primary_country_ind ='Y'
         AND item IN ( SELECT im.item
                         FROM item_master im
                        WHERE im.item_parent=I_item_parent
                          AND im.status='W'
                          AND I_diff_id IS NULL
                          AND EXISTS (SELECT '1'
                                        FROM diff_group_detail dgd
                                       WHERE dgd.diff_id IN (im.diff_1, im.diff_2,im.diff_3,im.diff_4)
                                         AND dgd.diff_group_id=I_diff_group_id
                 AND ROWNUM = 1)
                        UNION
                       SELECT im.item
                         FROM item_master im
                        WHERE im.item_parent=I_item_parent
                          AND im.status='W'
                          AND I_diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                          AND I_diff_id IS NOT NULL
                        UNION
                       SELECT im.item
                         FROM item_master im
                        WHERE im.item_parent=I_item_parent
                          AND im.status='W'
                          AND I_diff_group_id IS NULL
                          AND I_diff_id IS NULL)   ;
   END IF;

   IF I_unit_retail IS NOT NULL THEN
      L_child_item_table.DELETE;
      SAVEPOINT S1;

      -- Retreive all of the locations that RPM knows about.
      PM_RETAIL_API_SQL.GET_ZONE_LOCATIONS(L_location_table,
                                           I_rpm_zone_group_id,
                                           I_rpm_zone_id);

      IF ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                          L_standard_uom,
                                          L_standard_class,
                                          L_conv_factor,
                                          I_item_parent,
                                          'N') = FALSE THEN
         RETURN FALSE;
      END IF;

      -- Select all child items for the retail update.  The child items are selected based
      -- on the diff_group and diff_id filter criteria from the user.
      SQL_LIB.SET_MARK('OPEN', 'C_ITEM_CHILDREN_INFO', 'ITEM_MASTER', I_item_parent);
      open C_ITEM_CHILDREN_INFO;
      SQL_LIB.SET_MARK('FETCH', 'C_ITEM_CHILDREN_INFO', 'ITEM_MASTER', I_item_parent);
      fetch C_ITEM_CHILDREN_INFO BULK COLLECT into L_item_table;
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_CHILDREN_INFO', 'ITEM_MASTER', I_item_parent);
      close C_ITEM_CHILDREN_INFO;

      -- Build a table of item/location combinations which will be used in the ITEM_LOC
      -- retail updates for the child items.  Note that after this block of code, the
      -- L_itemloc_table will only contain item/location combinations, where the location
      -- is known in RPM.  Any location within RMS that has not been communicated to RPM
      -- will be added to the L_itemloc_table later in this function.
      IF L_location_table.COUNT > 0 AND L_item_table.COUNT > 0 THEN
         FOR b IN L_item_table.FIRST..L_item_table.LAST LOOP
            FOR c IN L_location_table.FIRST..L_location_table.LAST LOOP
                L_itemloc_table.EXTEND;
                L_itemloc_table(L_itemloc_table.COUNT) := OBJ_ITEMLOC_REC(L_item_table(b),
                                                                          L_location_table(c).location_id);
            END LOOP;
         END LOOP;
      END IF;

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_LOC', 'ITEM_LOC', NULL);
      open C_LOCK_ITEM_LOC;
      SQL_LIB.SET_MARK('FETCH', 'C_LOCK_ITEM_LOC', 'ITEM_LOC', NULL);
      fetch C_LOCK_ITEM_LOC BULK COLLECT into L_item_loc;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_LOC', 'ITEM_LOC', NULL);
      close C_LOCK_ITEM_LOC;

      if L_item_loc.COUNT > 0 then
         FOR d IN L_item_loc.FIRST..L_item_loc.LAST LOOP
            IF CURRENCY_SQL.GET_CURR_LOC(O_error_message,
                                         L_item_loc(d).loc,
                                         'Z',
                                         L_zone_group_id,
                                         L_zone_currency) = FALSE THEN
               RETURN FALSE;
            END IF;

            IF L_standard_uom != L_item_loc(d).selling_uom THEN
               IF UOM_SQL.CONVERT(O_error_message,            -- error message
                                  L_to_value,                 -- to value
                                  L_standard_uom,             -- to uom
                                  1,                          -- from value
                                  L_item_loc(d).selling_uom,  -- from uom
                                  L_item_loc(d).item,         -- item
                                  NULL,                       -- supplier
                                  NULL) = FALSE THEN          -- origin country
                  RETURN FALSE;
               END IF;

               L_selling_unit_retail := I_unit_retail * L_to_value;
            ELSE
               L_selling_unit_retail := I_unit_retail;
            END IF;

            IF L_item_loc(d).multi_units IS NOT NULL AND
               L_item_loc(d).multi_unit_retail IS NOT NULL THEN

               IF UOM_SQL.CONVERT(O_error_message,                  -- error message
                                  L_to_value,                       -- to value
                                  L_item_loc(d).multi_selling_uom,  -- to uom
                                  L_item_loc(d).multi_unit_retail,  -- from value
                                  L_item_loc(d).selling_uom,        -- from uom
                                  L_item_loc(d).item,               -- item
                                  NULL,                             -- supplier
                                  NULL) = FALSE THEN                -- origin country
                  RETURN FALSE;
               END IF;

               IF L_to_value <= 0 THEN
                  O_error_message := SQL_LIB.CREATE_MSG('NO_DIM_CONV',
                                                        L_item_loc(d).selling_uom,
                                                        L_item_loc(d).multi_selling_uom,
                                                        NULL);
                  RETURN FALSE;
               END IF;

               L_retail := L_to_value / L_item_loc(d).multi_units;

               IF L_retail > L_selling_unit_retail THEN
                  O_error_message := SQL_LIB.CREATE_MSG('MULTI_UNITS',
                                                        NULL,
                                                        NULL,
                                                        NULL);
                  RETURN FALSE;
               END IF;

               IF L_to_value < L_selling_unit_retail THEN
                  O_error_message := SQL_LIB.CREATE_MSG('MULTI_RETAIL_LESS_SINGLE',
                                                        NULL,
                                                        NULL,
                                                        NULL);
                  RETURN FALSE;
               END IF;
            END IF;

            L_cnt := L_cnt + 1;
            L_rpm_selling_unit(L_cnt)  := L_selling_unit_retail;
            L_rpm_zone_group_id(L_cnt) := L_zone_group_id;
            L_rpm_zone_id(L_cnt)       := L_item_loc(d).loc;
            L_rpm_item(L_cnt)          := L_item_loc(d).item;

            IF (L_child_table_index = 1 OR L_prev_item != L_item_loc(d).item) THEN
               L_child_item_table(L_child_table_index).child_item          := L_item_loc(d).item;
               L_child_item_table(L_child_table_index).unit_retail         := I_unit_retail;
               L_child_item_table(L_child_table_index).standard_uom        := L_standard_uom;
               L_child_item_table(L_child_table_index).currency_code       := I_rpm_currency_code;
               L_child_item_table(L_child_table_index).selling_unit_retail := L_selling_unit_retail;
               L_child_item_table(L_child_table_index).selling_uom         := L_item_loc(d).selling_uom;
               L_child_table_index := L_child_table_index + 1;
               L_prev_item := L_item_loc(d).item;
            END IF;
         END LOOP;

         SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_LOC',NULL);
         FORALL i IN 1 .. L_cnt
            UPDATE item_loc
               SET unit_retail         = I_unit_retail,
                   selling_unit_retail = L_rpm_selling_unit(i),
                   regular_unit_retail = I_unit_retail
             WHERE loc                 = L_rpm_zone_id(i)
               AND item                = L_rpm_item(i);

      else
         -- No ITEM_LOC records exisxt, so build the child item table, which is sent to RPM
         -- for the child item retail updates.
         IF L_item_table.COUNT > 0 THEN
            FOR e IN L_item_table.FIRST..L_item_table.LAST LOOP
                L_child_item_table(L_child_table_index).child_item          := L_item_table(e);
                L_child_item_table(L_child_table_index).unit_retail         := I_unit_retail;
                L_child_item_table(L_child_table_index).standard_uom        := L_standard_uom;
                L_child_item_table(L_child_table_index).currency_code       := I_rpm_currency_code;
                L_child_item_table(L_child_table_index).selling_unit_retail := I_unit_retail;
                L_child_item_table(L_child_table_index).selling_uom         := L_standard_uom;
                L_child_table_index := L_child_table_index + 1;
            END LOOP;
         END IF;
      end if;

      IF L_child_item_table.COUNT > 0 THEN
         IF NOT PM_RETAIL_API_SQL.SET_CHILD_ITEM_PRICING_INFO(O_error_message,
                                                              I_item_parent,
                                                              I_rpm_zone_id,
                                                              L_child_item_table) THEN
            ROLLBACK TO S1;
            RETURN FALSE;
         END IF;
      END IF;
   END IF;

   RETURN TRUE;

EXCEPTION
   WHEN RECORD_LOCKED THEN
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_program,
                                             NULL);

   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;

END MASS_UPDATE_CHILDREN;
------------------------------------------------------------------
FUNCTION MASS_UPDATE_CHILDREN(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_supplier        IN       SUPS.SUPPLIER%TYPE,
                              I_item            IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                              I_vpn             IN       ITEM_SUPPLIER.VPN%TYPE)
RETURN BOOLEAN IS

   L_program          VARCHAR2(40) := 'ITEM_CREATE_SQL.MASS_UPDATE_CHILDREN';
   L_table            VARCHAR2(20) := 'ITEM_SUPPLIER';
   RECORD_LOCKED      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(RECORD_LOCKED, -54);

   CURSOR C_LOCK_ITEM_SUPPLIER IS
      SELECT isupp.vpn
        FROM item_supplier isupp
       WHERE isupp.supplier=I_supplier
         AND isupp.item = I_item
  FOR UPDATE OF vpn NOWAIT;

BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPPLIER', 'ITEM_SUPPLIER', I_supplier);
   OPEN  C_LOCK_ITEM_SUPPLIER;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPPLIER', 'ITEM_SUPPLIER', I_supplier);
   CLOSE C_LOCK_ITEM_SUPPLIER;

   SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPPLIER','ITEM: '||I_item);

   UPDATE item_supplier
      SET vpn = I_vpn
    WHERE supplier=I_supplier
      AND item = I_item;

   RETURN TRUE;

EXCEPTION

   WHEN RECORD_LOCKED THEN
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_program,
                                             NULL);
      RETURN FALSE;
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;

END MASS_UPDATE_CHILDREN;
------------------------------------------------------------------
FUNCTION TRAN_CHILDREN_LEVEL3 (O_error_message          IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item                   IN       ITEM_TEMP.ITEM%TYPE,
                               I_item_number_type       IN       ITEM_TEMP.ITEM_NUMBER_TYPE%TYPE,
                               I_item_level             IN       ITEM_TEMP.ITEM_LEVEL%TYPE,
                               I_item_desc              IN       ITEM_TEMP.ITEM_DESC%TYPE,
                               I_diff_1                 IN       ITEM_TEMP.DIFF_1%TYPE,
                               I_diff_2                 IN       ITEM_TEMP.DIFF_2%TYPE,
                               I_diff_3                 IN       ITEM_TEMP.DIFF_3%TYPE,
                               I_diff_4                 IN       ITEM_TEMP.DIFF_4%TYPE,
                               I_existing_item_parent   IN       ITEM_TEMP.EXISTING_ITEM_PARENT%TYPE,
                               I_auto_approve           IN       VARCHAR2,
                               I_status                 IN       ITEM_MASTER.STATUS%TYPE,
                               --16-Oct-2007 WiproEnabler/Ramasamy - Modified to add one parameter in TRAN_CHILDREN_LEVEL3 - Begin
                               I_primary_ref_item_ind   IN       ITEM_MASTER.PRIMARY_REF_ITEM_IND%TYPE   DEFAULT NULL,
                               --16-Oct-2007 WiproEnabler/Ramasamy - Modified to add one parameter in TRAN_CHILDREN_LEVEL3 - End
                               ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
                               --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
                               I_occ_ret_barcode_auth   IN       VARCHAR2 DEFAULT 'N',
                               -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                               I_consumer_unit          IN       ITEM_TEMP.TSL_CONSUMER_UNIT%TYPE DEFAULT NULL,
                               -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com end
                               -- CR354 13-Aug-2010 Raghuveer P R Begin
                               I_owner_country          IN       ITEM_TEMP.TSL_OWNER_COUNTRY%TYPE DEFAULT 'U',
                               -- CR354 13-Aug-2010 Raghuveer P R End
                               -- DefNBS024747, Vinutha Raju, vinutha.raju@in.tesco.com, 24-Apr-12, Begin
                               I_barcode_move_exch_ind  IN VARCHAR2 DEFAULT 'N'
                               -- DefNBS024747, Vinutha Raju, vinutha.raju@in.tesco.com, 24-Apr-12, End
                               )
                               --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
                               ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
   RETURN BOOLEAN IS
   L_program         VARCHAR2(80) := 'ITEM_CREATE_SQL.TRAN_CHILDREN_LEVEL3';
   L_item_approved         BOOLEAN;
   L_children_approved     BOOLEAN;
BEGIN
   SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_TEMP','ITEM: '||I_item);
   INSERT INTO item_temp (item,
                          item_number_type,
                          item_level,
                          item_desc,
                          diff_1,
                          diff_2,
                          diff_3,
                          diff_4,
                          existing_item_parent,
                          ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
                          --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
                          tsl_ret_occ_barcode_auth,
                          -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                          tsl_consumer_unit,
                          -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                          -- CR354 13-Aug-2010 Raghuveer P R Begin
                          tsl_owner_country
                          -- CR354 13-Aug-2010 Raghuveer P R End
                          )
                          --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
                          ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
                  VALUES
                         (I_item,
                          I_item_number_type,
                          I_item_level,
                          I_item_desc,
                          I_diff_1,
                          I_diff_2,
                          I_diff_3,
                          I_diff_4,
                          I_existing_item_parent,
                          ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
                          --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
                          I_occ_ret_barcode_auth,
                          -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                          I_consumer_unit,
                          -- NBS00016363 23-Feb-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                          -- CR354 13-Aug-2010 Raghuveer P R Begin
                          I_owner_country
                          -- CR354 13-Aug-2010 Raghuveer P R End
                          );
                          --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
                          ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
    --16-Oct-2007 WiproEnabler/Ramasamy - Modified to add one parameter in INSERT_ITEM_MASTER - Begin
    IF ITEM_CREATE_SQL.INSERT_ITEM_MASTER(o_error_message,
                                     I_auto_approve,
                                     I_primary_ref_item_ind,
                                     ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
                                     --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 Begin
                                     I_occ_ret_barcode_auth) = FALSE THEN
                                     --20-Nov-2009 Satish B.N, satish.narasimhaiah@in.tesco.com DefNBS015424 End
                                     ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
    --16-Oct-2007 WiproEnabler/Ramasamy - Modified to add one parameter in INSERT_ITEM_MASTER - End
             RETURN FALSE;
    END IF;
    IF ITEM_CREATE_SQL.INSERT_ITEM_SUPPLIER(o_error_message,
                                        I_item,
                                        I_existing_item_parent) = FALSE THEN
             RETURN FALSE;
    END IF;
    ---
    ---------------------------------------------------------------------------------------------------------------
    -- 04-Oct-2007 Govindarajan - MOD N20a Begin
    ---------------------------------------------------------------------------------------------------------------
    if ITEM_CREATE_SQL.TSL_INSERT_ITEM_ATTRIBUTES (O_error_message,
                                                   I_item,
                                                   I_existing_item_parent,
                                                   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                   'U') = FALSE then
                                                   -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
        return FALSE;
    end if;
    -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
    if ITEM_CREATE_SQL.TSL_INSERT_ITEM_ATTRIBUTES (O_error_message,
                                                   I_item,
                                                   I_existing_item_parent,
                                                   'R') = FALSE then
        return FALSE;
    end if;
    -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
    ---------------------------------------------------------------------------------------------------------------
    -- 04-Oct-2007 Govindarajan - MOD N20a End
    ---------------------------------------------------------------------------------------------------------------
    ---
    IF I_auto_approve = 'Y' AND I_status  = 'A' THEN
    --- Need to set to submitted status before approval will work
       IF ITEM_APPROVAL_SQL.UPDATE_STATUS(O_error_message,
                                         'S',
                                         I_item)= FALSE THEN
                 RETURN FALSE;
       END IF;
       IF ITEM_APPROVAL_SQL.APPROVE(O_error_message,
                                    L_item_approved,
                                    L_children_approved,
                                    'N', -- don't process children
                                    I_item,
                                    -- DefNBS024747, Vinutha Raju, vinutha.raju@in.tesco.com, 24-Apr-12, Begin
                                    I_barcode_move_exch_ind)= FALSE THEN
                                    -- DefNBS024747, Vinutha Raju, vinutha.raju@in.tesco.com, 24-Apr-12, End
                  RETURN FALSE;
       END IF;
       IF L_item_approved THEN
     --- Item passed approval check so set status to A
      IF ITEM_APPROVAL_SQL.UPDATE_STATUS(O_error_message,
                                         'A',
                                         I_item)= FALSE THEN
           RETURN FALSE;
      END IF;
       ELSE
    --- Item failed approval check so set status to W
      IF ITEM_APPROVAL_SQL.UPDATE_STATUS(O_error_message,
                                        'W',
                                        I_item)= FALSE THEN
           RETURN FALSE;
           END IF;
       END IF;
   END IF;
   IF DIFF_APPLY_SQL.CLEAR_TEMP_TABLE(O_error_message, 'ALL') =  FALSE THEN
      RETURN FALSE;
   END IF;
      RETURN TRUE;
EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      RETURN FALSE;

END TRAN_CHILDREN_LEVEL3;
---------------------------------------------------------------------------------------------------------------
-- 04-Oct-2007 Govindarajan - MOD N20a Begin
---------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_INSERT_ITEM_ATTRIBUTES
-- Purpose       : Creates the Item attributes for the new Item, from the Item Attributes defined for the
--                 selected Item parent. New records will be inserted with the same information of the Parent,
--                 if there is no other required information necessary to be entered.
---------------------------------------------------------------------------------------------------------------
FUNCTION TSL_INSERT_ITEM_ATTRIBUTES (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     I_item           IN     ITEM_MASTER.ITEM%TYPE,
                                     I_item_parent    IN     ITEM_MASTER.ITEM%TYPE,
                                     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                     I_country_id     IN     VARCHAR2)
                                     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
  RETURN BOOLEAN is

  E_record_locked     EXCEPTION;
  PRAGMA              EXCEPTION_INIT(E_record_locked, -54);
  L_program           VARCHAR2(300)   := 'ITEM_CREATE_SQL.TSL_INSERT_ITEM_ATTRIBUTES';
  L_sql_select        VARCHAR2(32767) := NULL;
  L_sql_insert        VARCHAR2(32767) := NULL;
  L_sql_column        VARCHAR2(32767) := NULL;
  L_item_rec          ITEM_MASTER%ROWTYPE;
  L_item_parent_rec   ITEM_MASTER%ROWTYPE;
  L_lvl2_ind          VARCHAR2(1)     := 'N';
  L_lvl3_ind          VARCHAR2(1)     := 'N';
  L_base_ind          VARCHAR2(1);
  L_exists            BOOLEAN         := FALSE;
  L_item_level        NUMBER(1);
  --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    Begin
  L_system_options_row    SYSTEM_OPTIONS%ROWTYPE;
  L_security_ind          SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
  L_item_parent_owner     ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_uk_ind                VARCHAR2(1) :=  'N';
  L_roi_ind               VARCHAR2(1) :=  'N';
  --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    Begin
  L_login_ctry            ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    End
  --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    End
  ---
  -- 16-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
  L_loc_access            VARCHAR2(1) := 'N';
  -- 16-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
  ---
  --03-Dec-2010 Tesco HSC/Usha Patil             Defect: PrfNBS018484 Begin
  L_begin                 VARCHAR2(10) := 'Begin ';
  L_end                   VARCHAR2(10) := ' End;';
  --03-Dec-2010 Tesco HSC/Usha Patil             Defect: PrfNBS018484 End

  -- This cursor will lock the items on the table ITEM_ATTRIBUTES table
  cursor C_LOCK_ITEM is
  select 'x'
    from item_attributes ia
   where ia.item in (select im.item
                       from item_master im
                      where im.item_parent = L_item_rec.item
                        and im.item_level  = L_item_rec.item_level + 1)
     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     and ia.tsl_country_id = I_country_id
     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     for update nowait;
  -- This cursor will retrieve the codes, and the corresponding column for the
  -- attributes that can be copied between a Level 1 Item to a Level 2 Item
  cursor C_GET_COLUMNS is
  select tmc.tsl_column_name column_name,
         tmc.tsl_code code,
         mhd.required_ind req_ind
    from tsl_map_item_attrib_code tmc,
         merch_hier_default mhd
   where tmc.tsl_code            = mhd.info
     and mhd.info           != 'TEPW'
     and mhd.tsl_pack_ind    = L_item_rec.pack_ind
     and mhd.available_ind   = 'Y'
     and mhd.tsl_item_lvl    = L_item_rec.item_level
     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     and mhd.tsl_country_id in (I_country_id,'B')
     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     and mhd.dept            = L_item_rec.dept
     and mhd.class           = L_item_rec.class
     and mhd.subclass        = L_item_rec.subclass
     and DECODE(L_lvl2_ind,'Y',DECODE(L_base_ind,'Y',mhd.tsl_base_ind,mhd.tsl_var_ind),'Y') = 'Y'
     and (exists (select 1
                    from merch_hier_default a
                   where a.info = mhd.info
                     and a.available_ind = 'Y'
                     and a.dept          = mhd.dept
                     and a.class         = mhd.class
                     and a.subclass      = mhd.subclass
                     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                     and a.tsl_country_id in (I_country_id,'B')
                     -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                     and a.tsl_item_lvl  = L_item_rec.item_level - 1
                     and a.tsl_pack_ind  = L_item_rec.pack_ind
                     and DECODE(L_lvl3_ind,'Y',DECODE(L_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
              or
       not exists (select 1
                     from merch_hier_default a
                    where a.info          = mhd.info
                      and a.dept          = mhd.dept
                      and a.class         = mhd.class
                      and a.subclass      = mhd.subclass
                      -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                      and a.tsl_country_id in (I_country_id,'B')
                      -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                      and a.tsl_item_lvl  = L_item_rec.item_level - 1
                      and a.tsl_pack_ind  = L_item_rec.pack_ind
                      and DECODE(L_lvl3_ind,'Y',DECODE(L_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y'))
                      --30-Oct-2013 , Ramya Shetty K, Ramya.K.Shetty@in.tesco.com PM020648-Begin
     and  not exists(select 1
		                   from tsl_attr_stpcas sca
		                  where sca.tsl_itm_attr_id= tmc.tsl_code)
                      --30-Oct-2013 , Ramya Shetty K, Ramya.K.Shetty@in.tesco.com PM020648-End
    union
    select tmc.tsl_column_name column_name,
           tmc.tsl_code code,
           'N' req_ind
      from tsl_map_item_attrib_code tmc
     where not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.dept = L_item_rec.dept
                          and a.class = L_item_rec.class
                          and a.subclass = L_item_rec.subclass
                          -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                          and a.tsl_country_id in (I_country_id,'B')
                          -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                          and a.tsl_pack_ind  = L_item_rec.pack_ind
                          and a.tsl_item_lvl = L_item_rec.item_level
                          and DECODE(L_lvl2_ind,'Y',DECODE(L_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
       and not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.available_ind = 'N'
                          and a.dept = L_item_rec.dept
                          and a.class = L_item_rec.class
                          and a.subclass = L_item_rec.subclass
                          -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                          and a.tsl_country_id in (I_country_id,'B')
                          -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                          and a.tsl_pack_ind  = L_item_rec.pack_ind
                          and a.tsl_item_lvl = L_item_rec.item_level
                          and DECODE(L_lvl2_ind,'Y',DECODE(L_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
       and tmc.tsl_code != 'TEPW'
    --30-Oct-2013 , Ramya Shetty K, Ramya.K.Shetty@in.tesco.com PM020648-Begin
       and  not exists(select 1
		                     from tsl_attr_stpcas sca
		                    where sca.tsl_itm_attr_id= tmc.tsl_code);
    --30-Oct-2013 , Ramya Shetty K, Ramya.K.Shetty@in.tesco.com PM020648-End
   --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    Begin
   CURSOR C_GET_ITEM_PARENT_OWNER is
   select i.tsl_owner_country
     from item_master i
    where i.item = I_item_parent;
   --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    End
BEGIN

  if I_item is NULL then
      -- If input item is null then throws an error
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             I_item,
                                             L_program,
                                             NULL);
      return FALSE;
  elsif I_item_parent is NULL then
      -- If input item is null then throws an error
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             I_item_parent,
                                             L_program,
                                             NULL);
      return FALSE;
  end if;
  ---
  if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                      L_item_rec,
                                      I_item_parent) = FALSE then
      return FALSE;
  end if;
  ---
  --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    Begin
  if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                           L_system_options_row) = FALSE then
     return FALSE;
  end if;
  L_security_ind := L_system_options_row.tsl_loc_sec_ind;
  ---
  if L_security_ind = 'Y' then
     open C_GET_ITEM_PARENT_OWNER;
     fetch C_GET_ITEM_PARENT_OWNER into L_item_parent_owner;
     close C_GET_ITEM_PARENT_OWNER;
     ---
     if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY(O_error_message,
     	 																			   L_uk_ind,
      	 																			 L_roi_ind) = FALSE then
        return FALSE;
     end if;
     ---
     --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    Begin
     if L_uk_ind = 'Y' then
        L_login_ctry := 'U';
     elsif L_roi_ind = 'Y' and L_uk_ind = 'N' then
        L_login_ctry := 'R';
     end if;
     --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990    End
     ---
     -- 16-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     if L_uk_ind = 'Y' and
     	  L_roi_ind = 'N' then
        L_loc_access := 'U';
     elsif L_uk_ind = 'N' and
     	  L_roi_ind = 'Y' then
        L_loc_access := 'R';
     elsif L_uk_ind = 'Y' and
     	  L_roi_ind = 'Y' then
        L_loc_access := 'B';
     end if;
     -- 16-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     ---
  end if;
  --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    End
  if L_item_rec.tran_level = 2 and
     L_item_rec.item_level = L_item_rec.tran_level and
     L_item_rec.pack_ind = 'N' then
      ---
      if L_item_rec.item = L_item_rec.tsl_base_item then
          L_base_ind := 'Y';
      else
          L_base_ind := 'N';
      end if;
      ---
      L_lvl2_ind := 'Y';
      L_item_level := 2;
      ---
  elsif L_item_rec.tran_level = 2 and
        L_item_rec.item_level > L_item_rec.tran_level and
        L_item_rec.pack_ind = 'N' then
      ---
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                          L_item_parent_rec,
                                          I_item_parent) = FALSE then
          return FALSE;
      end if;
      ---
      if L_item_parent_rec.item = L_item_parent_rec.tsl_base_item then
          L_base_ind := 'Y';
      else
          L_base_ind := 'N';
      end if;
      ---
      L_lvl3_ind := 'Y';
      L_item_level := 3;
      ---
  end if;
  ---
  -- This cursor will retrieve the codes, and the corresponding column for the attributes
  -- that can be copied between the L1 item to L2 Items
  --Opening the cursor C_GET_COLUMNS
  SQL_LIB.SET_MARK('OPEN',
                   'C_GET_COLUMNS',
                   'TSL_MAP_ITEM_ATTRIB_CODE',
                   'ITEM: ' ||I_item);
  FOR C_rec in C_GET_COLUMNS
  LOOP
      -- checking L_sql_select is null or not
      L_exists := TRUE;
      --03-Sep-2010     TESCO HSC/Joy Stephen  DefNBS018990   Begin
      --As part of this defect fix we have removed the previous code.
      --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    Begin
      if (((L_login_ctry = I_country_id) or
         L_security_ind = 'N') or
          -- 16-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
          (L_loc_access = 'B' and L_security_ind = 'Y') or
          -- 16-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
         (L_login_ctry <> I_country_id and
         L_security_ind = 'Y' and
         C_rec.column_name NOT in
         ('TSL_DIAMOND_LINE_IND','TSL_DEV_LINE_IND','TSL_LAUNCH_DATE','TSL_POS_CODES','TSL_DEV_END_DATE'))) then
         if L_sql_select is NULL then
             L_sql_insert := 'ia.'||C_rec.column_name;
             L_sql_select := C_rec.column_name;
         else
             L_sql_insert := L_sql_insert ||',ia.'|| C_rec.column_name;
             L_sql_select := L_sql_select || ', ' || C_rec.column_name;
         end if;
      end if;
      --20-Aug-2010   TESCO HSC/Joy Stephen   CR354    End
      --03-Sep-2010   TESCO HSC/Joy Stephen   DefNBS018990   End
      -- checking req_ind is 'Y' or 'N'
      -- 21-Apr-2010, MrgNBS017125, Govindarajan K, Begin
      -- Commented the following code to cacade the IA to children if children attributes are not filled at the parent level
      /*
      if C_rec.req_ind = 'N' then
          L_sql_column := L_sql_column || ', '''|| C_rec.code || '''';
      else
          L_sql_column := L_sql_column || ', decode(ia.' || C_rec.column_name ||
                          ', null, ''x'', ''' || C_rec.code || ''')';
      end if;
      */
      -- 21-Apr-2010, MrgNBS017125, Govindarajan K, End
  END LOOP;
  ---
  -- 21-Apr-2010, MrgNBS017125, Govindarajan K, Begin
  -- Commented the following code to cacade the IA to children if children attributes are not filled at the parent level
  /*
  if L_sql_column is NOT NULL then
      L_sql_column := L_sql_column||')';
  end if;
  */
  -- 21-Apr-2010, MrgNBS017125, Govindarajan K, End
  ---
  if L_exists = TRUE then
      -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
      -- 03-Dec-2010 Tesco HSC/Usha Patil            Defect: PrfNBS018484 Begin
      -- Re-wrote the below code to improve the performance using bind varibales.
/*      L_sql_insert := ' insert into item_attributes (ITEM, tsl_country_id, '||L_sql_select||' )' ||
                                           ' select '||chr(39)||I_item||chr(39)||', '||chr(39)||I_country_id||chr(39)||', ' ||L_sql_insert||
      -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                            ' from item_attributes ia'||
                                           ' where ia.item = '''|| I_item_parent ||''''||
                                             ' and not exists (select 1'||
                                                               ' from item_attributes b '||
                                             -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                               'where b.item = '''||I_item||''''||
                                                               '  and b.tsl_country_id = '''||I_country_id||''')'||
                                             ' and ia.tsl_country_id = '''||I_country_id||''';';*/

         L_sql_insert := ' insert into item_attributes (ITEM, tsl_country_id, '||L_sql_select||' )' ||
                                           ' select :item, :country_id, ' ||L_sql_insert||
                                                  ' from item_attributes ia'||
                                           ' where ia.item = :item_parent '||
                                             ' and not exists (select 1'||
                                                               ' from item_attributes b '||
                                                               'where b.item = :item'||
                                                               '  and b.tsl_country_id = :country_id)'||
                                             ' and ia.tsl_country_id = :country_id;';
         -- 03-Dec-2010 Tesco HSC/Usha Patil            Defect: PrfNBS018484 End
                                             -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                             -- 21-Apr-2010, MrgNBS017125, Govindarajan K, Begin
                                             -- Commented the following code to cacade the IA to children if children attributes are not filled at the parent level
                                             /*
                                             ' and not exists (select 1 '||
                                                               ' from merch_hier_default m, '||
                                                                    ' tsl_map_item_attrib_code t'||
                                                              ' where m.info = t.tsl_code'||
                                                                ' and m.required_ind = ''Y'''||
                                                                -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                                                ' and m.tsl_country_id in (''B'','''||I_country_id||''') '||
                                                                -- CR236, 03-Aug-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                                                ' and m.dept = '|| L_item_rec.dept||
                                                                ' and m.class = ' || L_item_rec.class||
                                                                ' and m.subclass = ' || L_item_rec.subclass ||
                                                                ' and m.tsl_pack_ind = '''||L_item_rec.pack_ind||''''||
                                                                ' and m.tsl_item_lvl = ' || L_item_rec.item_level;
                                             */
                                             -- 21-Apr-2010, MrgNBS017125, Govindarajan K, End
     -- 21-Apr-2010, MrgNBS017125, Govindarajan K, Begin
     -- Commented the following code to cacade the IA to children if children attributes are not filled at the parent level
     /*
     if L_item_rec.tran_level = 2 and
        L_item_rec.item_level = L_item_rec.tran_level then
          ---
          if L_base_ind = 'Y' then
              L_sql_insert := L_sql_insert ||  ' and m.tsl_base_ind = ''Y''';
          else
              L_sql_insert := L_sql_insert ||  ' and m.tsl_var_ind = ''Y''';
          end if;
          ---
     end if;
     */
     -- 21-Apr-2010, MrgNBS017125, Govindarajan K, End
     ---
     --  Add to L_sql_insert variable the L_sql_column variable
     -- 21-Apr-2010, MrgNBS017125, Govindarajan K, Begin
     -- Commented the following code to cacade the IA to children if children attributes are not filled at the parent level
     -- L_sql_insert := L_sql_insert || L_sql_column|| ');';
     -- 21-Apr-2010, MrgNBS017125, Govindarajan K, End
     ---
     -- 03-Dec-2010 Tesco HSC/Usha Patil            Defect: PrfNBS018484 Begin
     --re-wrote the below to accept variable values and execute
     -- Execute the Dynamic SQL, using the instruction EXECUTE IMMEDIATE:
     --EXECUTE IMMEDIATE 'Begin '|| L_sql_insert ||' End;';
     EXECUTE IMMEDIATE L_Begin|| L_sql_insert ||L_end using I_item, I_country_id, I_item_parent;
     -- 03-Dec-2010 Tesco HSC/Usha Patil            Defect: PrfNBS018484 End
  end if;
  ---
  return TRUE;
  ---
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
END TSL_INSERT_ITEM_ATTRIBUTES;
---------------------------------------------------------------------------------------------------------------
-- 04-Oct-2007 Govindarajan - MOD N20a end
---------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Mod By  : Nitin Kumar,nitin.kumar@in.tesco.com
-- Mod Date: 04-Oct-2007
-- Function: TSL_MASS_UPDATE_CHILDREN
-- Purpose:  This function is a copy of the base MASS_UPDATE_CHILDREN function
--          (the version with 13 parameters). The changes are to call the RNA
--           for EAN(EANOWN) generation rather than the ORMS internal number allocation
-----------------------------------------------------------------------------------------
-- Modified by : Nitin Kumar, nitin.kumar@in.tesco.com
-- Date        : 20-July-2009
-- Defect Id   : NBS00013905
-- Desc        : Modified Function TSL_MASS_UPDATE_CHILDREN for Checking Barcode i.e. EAN/OCC
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_MASS_UPDATE_CHILDREN(O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
-- CR338, 15-Nov-2010, Phil Noon phil.noon@uk.tesco.com, Begin
                                  O_eans_created      IN OUT  EAN_TABLE,
-- CR338, 15-Nov-2010, Phil Noon phil.noon@uk.tesco.com, End
                                  I_supplier          IN      SUPS.SUPPLIER%TYPE,
                                  I_item_parent       IN      ITEM_MASTER.ITEM_PARENT%TYPE,
                                  I_rpm_zone_group_id IN      ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE,
                                  I_rpm_zone_id       IN      ITEM_ZONE_PRICE.ZONE_ID%TYPE,
                                  I_rpm_currency_code IN       CURRENCIES.CURRENCY_CODE%TYPE,
                                  I_diff_group_id     IN      DIFF_GROUP_DETAIL.DIFF_GROUP_ID%TYPE,
                                  I_diff_id           IN      DIFF_GROUP_DETAIL.DIFF_ID%TYPE,
                                  I_supp_diff_id      IN      DIFF_GROUP_DETAIL.DIFF_ID%TYPE,
                                  I_unit_retail       IN      ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE,
                                  I_unit_cost         IN      ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                                  I_generate_ean      IN      BOOLEAN,
                                  I_auto_approve      IN      VARCHAR2)
RETURN BOOLEAN IS

   L_program               VARCHAR2(40) := 'ITEM_CREATE_SQL.TSL_MASS_UPDATE_CHILDREN';
   L_supplier_diff_number  ITEM_MASTER.DIFF_1%TYPE;
   L_standard_uom          ITEM_MASTER.STANDARD_UOM%TYPE;
   L_standard_class        UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor           ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_zone_currency         PRICE_ZONE.CURRENCY_CODE%TYPE;
   L_to_value              NUMBER;
   L_retail                NUMBER;
   L_selling_unit_retail   NUMBER;
   L_table                 VARCHAR2(20) := 'ITEM_SUPPLIER';
   L_child_table_index     NUMBER := 1;
   L_child_item_table      PM_RETAIL_API_SQL.CHILD_ITEM_PRICING_TABLE;
   L_first_ean_exists      BOOLEAN;
   L_ean                   ITEM_MASTER.ITEM%TYPE;
   L_item_number_type      ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(RECORD_LOCKED, -54);

   L_location_table        OBJ_RPM_LOC_TBL;
   L_prev_item             ITEM_MASTER.ITEM%TYPE;

   L_zone_group_id         CONSTANT NUMBER(10) := 1;

   L_itemloc_table OBJ_ITEMLOC_TBL := OBJ_ITEMLOC_TBL();
   L_item_table ITEM_TBL;
   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
   L_use_rna_ind           SYSTEM_OPTIONS.TSL_RNA_IND%TYPE;
   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End
   --UAT defect NBS00013905, Nitin Kumar, nitin.kumar@in.tesco.com, 20-July-2009, Begin
   L_barcode_exists        BOOLEAN := FALSE;
   --UAT defect NBS00013905, Nitin Kumar, nitin.kumar@in.tesco.com, 20-July-2009, End

   TYPE TABLE1 IS TABLE OF ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE
      INDEX BY BINARY_INTEGER;

   TYPE TABLE2 IS TABLE OF ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE
      INDEX BY BINARY_INTEGER;

   TYPE TABLE3 IS TABLE OF ITEM_ZONE_PRICE.ZONE_ID%TYPE
      INDEX BY BINARY_INTEGER;

   TYPE TABLE4 IS TABLE OF ITEM_ZONE_PRICE.ITEM%TYPE
      INDEX BY BINARY_INTEGER;

   L_rpm_selling_unit  TABLE1;
   L_rpm_zone_group_id TABLE2;
   L_rpm_zone_id       TABLE3;
   L_rpm_item          TABLE4;
   L_cnt               NUMBER := 0;

   CURSOR C_LOCK_ITEM_SUPPLIER IS
      SELECT isupp.supp_diff_1
        FROM item_supplier isupp
       WHERE isupp.supplier=I_supplier
         AND isupp.item IN (SELECT im.item
                              FROM item_master im
                             WHERE im.item_parent=I_item_parent
                               AND I_diff_id IS NULL
                               AND EXISTS (SELECT '1'
                                             FROM diff_group_detail dgd
                                            WHERE dgd.diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                                              AND dgd.diff_group_id=I_diff_group_id
                  AND ROWNUM = 1)
                             UNION
                            SELECT im.item
                              FROM item_master im
                             WHERE im.item_parent=I_item_parent
                               AND I_diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                               AND I_diff_id IS NOT NULL
                             UNION
                            SELECT im.item
                              FROM item_master im
                             WHERE im.item_parent=I_item_parent
                               AND I_diff_group_id IS NULL
                               AND I_diff_id IS NULL)
      FOR UPDATE OF supp_diff_1 NOWAIT;

   CURSOR C_GET_SUPP_DIFF_NUMBER IS
      SELECT DECODE(I_diff_group_id,diff_1,1,diff_2,2,diff_3,3,diff_4,4)
        FROM item_master
       WHERE item=I_item_parent;

   CURSOR C_LOCK_ITEM_SUPP_COUNTRY IS
      SELECT isc.unit_cost
        FROM item_supp_country isc
       WHERE isc.supplier=I_supplier
         AND isc.primary_country_ind ='Y'
         AND isc.item IN (SELECT im.item
                            FROM item_master im
                           WHERE im.item_parent=I_item_parent
                             AND im.status='W'
                             AND I_diff_id IS NULL
                             AND EXISTS (SELECT '1'
                                           FROM diff_group_detail dgd
                                          WHERE dgd.diff_id IN (im.diff_1, im.diff_2,im.diff_3,im.diff_4)
                                            AND dgd.diff_group_id=I_diff_group_id
                AND ROWNUM = 1)
                           UNION
                          SELECT im.item
                            FROM item_master im
                           WHERE im.item_parent=I_item_parent
                             AND im.status='W'
                             AND I_diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                             AND I_diff_id IS NOT NULL
                           UNION
                          SELECT im.item
                            FROM item_master im
                           WHERE im.item_parent=I_item_parent
                             AND im.status='W'
                             AND I_diff_group_id IS NULL
                             AND I_diff_id IS NULL)
      FOR UPDATE OF unit_cost NOWAIT;

   CURSOR C_ITEM_CHILDREN_INFO IS
      SELECT im.item
        FROM item_master im
       WHERE im.item_parent = I_item_parent
         AND im.status IN ('W','S')
         AND I_diff_id IS NULL
         AND EXISTS (SELECT '1'
                       FROM diff_group_detail dgd
                      WHERE dgd.diff_id IN (im.diff_1, im.diff_2, im.diff_3, im.diff_4)
                        AND dgd.diff_group_id = I_diff_group_id
                        AND rownum = 1)
       UNION
      SELECT im.item
        FROM item_master im
       WHERE im.item_parent = I_item_parent
         AND im.status IN ('W','S')
         AND I_diff_id IN (im.diff_1, im.diff_2, im.diff_3, im.diff_4)
         AND I_diff_id IS NOT NULL
       UNION
      SELECT im.item
        FROM item_master im
       WHERE im.item_parent = I_item_parent
         AND im.status IN ('W','S')
         AND I_diff_group_id IS NULL
         AND I_diff_id IS NULL;

   CURSOR C_LOCK_ITEM_LOC IS
      SELECT il.item,
             il.loc,
             il.unit_retail,
             il.selling_unit_retail,
             il.regular_unit_retail,
             il.selling_uom,
             il.multi_units,
             il.multi_unit_retail,
             il.multi_selling_uom
        FROM item_loc il,
             TABLE(CAST(L_itemloc_table AS OBJ_ITEMLOC_TBL)) itl
       WHERE il.item = itl.item
         AND il.loc = itl.loc
       ORDER BY il.item
     FOR UPDATE OF unit_retail NOWAIT;

   TYPE UPDATE_ITEM_LOC_TYPE IS TABLE OF C_LOCK_ITEM_LOC%ROWTYPE INDEX BY BINARY_INTEGER;
   L_item_loc UPDATE_ITEM_LOC_TYPE;

   CURSOR C_APPLY_RECS IS
      SELECT im1.item,
             im1.item_desc,
             im1.diff_1,
             im1.diff_2,
             im1.diff_3,
             im1.diff_4,
             im1.status
        FROM item_master im1
       WHERE im1.item_parent = I_item_parent
         AND I_diff_id IS NULL
         AND EXISTS (SELECT '1'
                      FROM diff_group_detail dgd
                     WHERE dgd.diff_id IN (im1.diff_1,im1.diff_2,im1.diff_3,im1.diff_4)
                       AND dgd.diff_group_id=I_diff_group_id
           AND ROWNUM = 1)
       UNION
      SELECT im2.item,
             im2.item_desc,
             im2.diff_1,
             im2.diff_2,
             im2.diff_3,
             im2.diff_4,
             im2.status
        FROM item_master im2
       WHERE im2.item_parent=I_item_parent
         AND I_diff_id IN (im2.diff_1,im2.diff_2,im2.diff_3,im2.diff_4)
         AND I_diff_id IS NOT NULL
       UNION
      SELECT im3.item,
             im3.item_desc,
             im3.diff_1,
             im3.diff_2,
             im3.diff_3,
             im3.diff_4,
             im3.status
        FROM item_master im3
       WHERE im3.item_parent=I_item_parent
         AND I_diff_group_id IS NULL
         AND I_diff_id IS NULL;

BEGIN
   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
   if SYSTEM_OPTIONS_SQL.TSL_GET_RNA_IND(O_error_message,
                                         L_use_rna_ind) = FALSE then
        return FALSE;
   end if;
   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End


   IF I_generate_ean = TRUE THEN
      FOR rec IN C_APPLY_RECS LOOP
         IF ITEM_ATTRIB_SQL.TSL_GET_FIRST_EAN(O_error_message,
                                              L_first_ean_exists,
                                              L_ean,
                                              L_item_number_type,
                                              rec.item) = FALSE THEN
            RETURN FALSE;
         END IF;
        --- Call package to auto generate the next EAN number fetched from RNA
         IF L_ean is NULL then
            ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
            IF L_use_rna_ind = 'Y' THEN
            ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End
               IF TSL_RNA_SQL.GET_REF_NO (O_error_message,
                                          'EANOWN',
                                          L_ean) = FALSE THEN
                  RETURN FALSE;
               ELSE
                  IF L_ean IS NOT NULL THEN
                      --UAT defect NBS00013905, Nitin Kumar, nitin.kumar@in.tesco.com, 20-July-2009, Begin
                      if ITEM_VALIDATE_SQL.TSL_BARCODE_CHECK(O_error_message,
                                                             L_barcode_exists,
                                                             L_ean,
                                                             'EAN') = FALSE then
                         --
                         if TSL_ITEM_NUMBER_SQL.INSERT_RNA_NUMBR(O_error_message,
               	                                                 'EANOWN',
               	                                                 L_ean) = FALSE then
                            return FALSE;
                         end if;
                         --
                         return FALSE;
                      end if;
                     --UAT defect NBS00013905, Nitin Kumar, nitin.kumar@in.tesco.com, 20-July-2009, End

                     L_item_number_type := 'EANOWN';
                     ---
                     --UAT defect NBS00013905, Nitin Kumar, nitin.kumar@in.tesco.com, 20-July-2009, Begin
                     if L_barcode_exists = FALSE then
                     --UAT defect NBS00013905, Nitin Kumar, nitin.kumar@in.tesco.com, 20-July-2009, End
                        -- CR338, 15-Nov-2010, Phil Noon phil.noon@uk.tesco.com, Begin
                        O_eans_created(L_ean).item             := L_ean;
                        O_eans_created(L_ean).item_number_type := L_item_number_type;
                        -- CR338, 15-Nov-2010, Phil Noon phil.noon@uk.tesco.com, End
                        --Create the level 3 EAN items
                        IF ITEM_CREATE_SQL.TRAN_CHILDREN_LEVEL3(O_error_message,
                                                                L_ean,
                                                                L_item_number_type,
                                                                3,
                                                                rec.item_desc,
                                                                rec.diff_1,
                                                                rec.diff_2,
                                                                rec.diff_3,
                                                                rec.diff_4,
                                                                rec.item,
                                                                I_auto_approve,
                                                                rec.status) = FALSE THEN
                          RETURN FALSE;
                       END IF;
                     --UAT defect NBS00013905, Nitin Kumar, nitin.kumar@in.tesco.com, 20-July-2009, Begin
                     else
                        O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_BAROCDE_EAN_EXISTS',
                                                                     NULL,
                                                                     NULL,
                                                                     NULL);
                        return FALSE;
                     end if;
                    --UAT defect NBS00013905, Nitin Kumar, nitin.kumar@in.tesco.com, 20-July-2009, End
                   ---
                  END IF;
                 ---
               END IF;
            ---
            ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
            END IF;
            ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End
         END IF;
      END LOOP;

   END IF;

   IF I_supp_diff_id IS NOT NULL THEN

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPPLIER', 'ITEM_SUPPLIER', I_supplier);
      OPEN  C_LOCK_ITEM_SUPPLIER;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPPLIER', 'ITEM_SUPPLIER', I_supplier);
      CLOSE C_LOCK_ITEM_SUPPLIER;

      SQL_LIB.SET_MARK('OPEN', 'C_GET_SUPP_DIFF_NUMBER', 'ITEM_MASTER', I_item_parent);
      OPEN  C_GET_SUPP_DIFF_NUMBER;

      SQL_LIB.SET_MARK('FETCH', 'C_GET_SUPP_DIFF_NUMBER', 'ITEM_MASTER', I_item_parent);
      FETCH C_GET_SUPP_DIFF_NUMBER INTO L_supplier_diff_number;

      SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPP_DIFF_NUMBER', 'ITEM_MASTER', I_item_parent);
      CLOSE C_GET_SUPP_DIFF_NUMBER;

      SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_SUPPLIER', L_supplier_diff_number);

      UPDATE item_supplier
         SET supp_diff_1 = DECODE(L_supplier_diff_number,1,I_supp_diff_id,supp_diff_1),
             supp_diff_2 = DECODE(L_supplier_diff_number,2,I_supp_diff_id,supp_diff_2),
             supp_diff_3 = DECODE(L_supplier_diff_number,3,I_supp_diff_id,supp_diff_3),
             supp_diff_4 = DECODE(L_supplier_diff_number,4,I_supp_diff_id,supp_diff_4),
             last_update_datetime = SYSDATE,
             last_update_id       = USER
      WHERE  supplier=I_supplier
        AND  item IN (SELECT im.item
                        FROM item_master im
                       WHERE im.item_parent=I_item_parent
                         AND I_diff_id IS NULL
                         AND EXISTS (SELECT '1'
                                       FROM diff_group_detail dgd
                                      WHERE dgd.diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                                        AND dgd.diff_group_id=I_diff_group_id
                AND ROWNUM = 1)
                       UNION
                      SELECT im.item
                        FROM item_master im
                       WHERE im.item_parent=I_item_parent
                         AND I_diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                         AND I_diff_id IS NOT NULL
                       UNION
                      SELECT im.item
                        FROM item_master im
                       WHERE im.item_parent=I_item_parent
                         AND I_diff_group_id IS NULL
                         AND I_diff_id IS NULL);
   END IF;

   IF I_unit_cost IS NOT NULL THEN

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPPLIER', I_supplier);
      OPEN  C_LOCK_ITEM_SUPP_COUNTRY;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPPLIER', I_supplier);
      CLOSE C_LOCK_ITEM_SUPP_COUNTRY;

      SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_SUPPLIER_COUNTRY', I_supplier);

      UPDATE item_supp_country
         SET unit_cost=I_unit_cost
       WHERE supplier=I_supplier
         AND primary_country_ind ='Y'
         AND item IN ( SELECT im.item
                         FROM item_master im
                        WHERE im.item_parent=I_item_parent
                          AND im.status='W'
                          AND I_diff_id IS NULL
                          AND EXISTS (SELECT '1'
                                        FROM diff_group_detail dgd
                                       WHERE dgd.diff_id IN (im.diff_1, im.diff_2,im.diff_3,im.diff_4)
                                         AND dgd.diff_group_id=I_diff_group_id
                 AND ROWNUM = 1)
                        UNION
                       SELECT im.item
                         FROM item_master im
                        WHERE im.item_parent=I_item_parent
                          AND im.status='W'
                          AND I_diff_id IN (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                          AND I_diff_id IS NOT NULL
                        UNION
                       SELECT im.item
                         FROM item_master im
                        WHERE im.item_parent=I_item_parent
                          AND im.status='W'
                          AND I_diff_group_id IS NULL
                          AND I_diff_id IS NULL)   ;
   END IF;

   IF I_unit_retail IS NOT NULL THEN
      L_child_item_table.DELETE;
      SAVEPOINT S1;

      -- Retreive all of the locations that RPM knows about.
      PM_RETAIL_API_SQL.GET_ZONE_LOCATIONS(L_location_table,
                                           I_rpm_zone_group_id,
                                           I_rpm_zone_id);

      IF ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                          L_standard_uom,
                                          L_standard_class,
                                          L_conv_factor,
                                          I_item_parent,
                                          'N') = FALSE THEN
         RETURN FALSE;
      END IF;

      -- Select all child items for the retail update.  The child items are selected based
      -- on the diff_group and diff_id filter criteria from the user.
      SQL_LIB.SET_MARK('OPEN', 'C_ITEM_CHILDREN_INFO', 'ITEM_MASTER', I_item_parent);
      open C_ITEM_CHILDREN_INFO;
      SQL_LIB.SET_MARK('FETCH', 'C_ITEM_CHILDREN_INFO', 'ITEM_MASTER', I_item_parent);
      fetch C_ITEM_CHILDREN_INFO BULK COLLECT into L_item_table;
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_CHILDREN_INFO', 'ITEM_MASTER', I_item_parent);
      close C_ITEM_CHILDREN_INFO;

      -- Build a table of item/location combinations which will be used in the ITEM_LOC
      -- retail updates for the child items.  Note that after this block of code, the
      -- L_itemloc_table will only contain item/location combinations, where the location
      -- is known in RPM.  Any location within RMS that has not been communicated to RPM
      -- will be added to the L_itemloc_table later in this function.
      IF L_location_table.COUNT > 0 AND L_item_table.COUNT > 0 THEN
         FOR b IN L_item_table.FIRST..L_item_table.LAST LOOP
            FOR c IN L_location_table.FIRST..L_location_table.LAST LOOP
                L_itemloc_table.EXTEND;
                L_itemloc_table(L_itemloc_table.COUNT) := OBJ_ITEMLOC_REC(L_item_table(b),
                                                                          L_location_table(c).location_id);
            END LOOP;
         END LOOP;
      END IF;

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_LOC', 'ITEM_LOC', NULL);
      open C_LOCK_ITEM_LOC;
      SQL_LIB.SET_MARK('FETCH', 'C_LOCK_ITEM_LOC', 'ITEM_LOC', NULL);
      fetch C_LOCK_ITEM_LOC BULK COLLECT into L_item_loc;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_LOC', 'ITEM_LOC', NULL);
      close C_LOCK_ITEM_LOC;

      if L_item_loc.COUNT > 0 then
         FOR d IN L_item_loc.FIRST..L_item_loc.LAST LOOP
            IF CURRENCY_SQL.GET_CURR_LOC(O_error_message,
                                         L_item_loc(d).loc,
                                         'Z',
                                         L_zone_group_id,
                                         L_zone_currency) = FALSE THEN
               RETURN FALSE;
            END IF;

            IF L_standard_uom != L_item_loc(d).selling_uom THEN
               IF UOM_SQL.CONVERT(O_error_message,            -- error message
                                  L_to_value,                 -- to value
                                  L_standard_uom,             -- to uom
                                  1,                          -- from value
                                  L_item_loc(d).selling_uom,  -- from uom
                                  L_item_loc(d).item,         -- item
                                  NULL,                       -- supplier
                                  NULL) = FALSE THEN          -- origin country
                  RETURN FALSE;
               END IF;

               L_selling_unit_retail := I_unit_retail * L_to_value;
            ELSE
               L_selling_unit_retail := I_unit_retail;
            END IF;

            IF L_item_loc(d).multi_units IS NOT NULL AND
               L_item_loc(d).multi_unit_retail IS NOT NULL THEN

               IF UOM_SQL.CONVERT(O_error_message,                  -- error message
                                  L_to_value,                       -- to value
                                  L_item_loc(d).multi_selling_uom,  -- to uom
                                  L_item_loc(d).multi_unit_retail,  -- from value
                                  L_item_loc(d).selling_uom,        -- from uom
                                  L_item_loc(d).item,               -- item
                                  NULL,                             -- supplier
                                  NULL) = FALSE THEN                -- origin country
                  RETURN FALSE;
               END IF;

               IF L_to_value <= 0 THEN
                  O_error_message := SQL_LIB.CREATE_MSG('NO_DIM_CONV',
                                                        L_item_loc(d).selling_uom,
                                                        L_item_loc(d).multi_selling_uom,
                                                        NULL);
                  RETURN FALSE;
               END IF;

               L_retail := L_to_value / L_item_loc(d).multi_units;

               IF L_retail > L_selling_unit_retail THEN
                  O_error_message := SQL_LIB.CREATE_MSG('MULTI_UNITS',
                                                        NULL,
                                                        NULL,
                                                        NULL);
                  RETURN FALSE;
               END IF;

               IF L_to_value < L_selling_unit_retail THEN
                  O_error_message := SQL_LIB.CREATE_MSG('MULTI_RETAIL_LESS_SINGLE',
                                                        NULL,
                                                        NULL,
                                                        NULL);
                  RETURN FALSE;
               END IF;
            END IF;

            L_cnt := L_cnt + 1;
            L_rpm_selling_unit(L_cnt)  := L_selling_unit_retail;
            L_rpm_zone_group_id(L_cnt) := L_zone_group_id;
            L_rpm_zone_id(L_cnt)       := L_item_loc(d).loc;
            L_rpm_item(L_cnt)          := L_item_loc(d).item;

            IF (L_child_table_index = 1 OR L_prev_item != L_item_loc(d).item) THEN
               L_child_item_table(L_child_table_index).child_item          := L_item_loc(d).item;
               L_child_item_table(L_child_table_index).unit_retail         := I_unit_retail;
               L_child_item_table(L_child_table_index).standard_uom        := L_standard_uom;
               L_child_item_table(L_child_table_index).currency_code       := I_rpm_currency_code;
               L_child_item_table(L_child_table_index).selling_unit_retail := L_selling_unit_retail;
               L_child_item_table(L_child_table_index).selling_uom         := L_item_loc(d).selling_uom;
               L_child_table_index := L_child_table_index + 1;
               L_prev_item := L_item_loc(d).item;
            END IF;
         END LOOP;

         SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_LOC',NULL);
         FORALL i IN 1 .. L_cnt
            UPDATE item_loc
               SET unit_retail         = I_unit_retail,
                   selling_unit_retail = L_rpm_selling_unit(i),
                   regular_unit_retail = I_unit_retail
             WHERE loc                 = L_rpm_zone_id(i)
               AND item                = L_rpm_item(i);

      else
         -- No ITEM_LOC records exisxt, so build the child item table, which is sent to RPM
         -- for the child item retail updates.
         IF L_item_table.COUNT > 0 THEN
            FOR e IN L_item_table.FIRST..L_item_table.LAST LOOP
                L_child_item_table(L_child_table_index).child_item          := L_item_table(e);
                L_child_item_table(L_child_table_index).unit_retail         := I_unit_retail;
                L_child_item_table(L_child_table_index).standard_uom        := L_standard_uom;
                L_child_item_table(L_child_table_index).currency_code       := I_rpm_currency_code;
                L_child_item_table(L_child_table_index).selling_unit_retail := I_unit_retail;
                L_child_item_table(L_child_table_index).selling_uom         := L_standard_uom;
                L_child_table_index := L_child_table_index + 1;
            END LOOP;
         END IF;
      end if;

      IF L_child_item_table.COUNT > 0 THEN
         IF NOT PM_RETAIL_API_SQL.SET_CHILD_ITEM_PRICING_INFO(O_error_message,
                                                              I_item_parent,
                                                              I_rpm_zone_id,
                                                              L_child_item_table) THEN
            ROLLBACK TO S1;
            RETURN FALSE;
         END IF;
      END IF;
   END IF;

   RETURN TRUE;

EXCEPTION
   WHEN RECORD_LOCKED THEN
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_program,
                                             NULL);

   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;

END TSL_MASS_UPDATE_CHILDREN;
------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- 04-Jul-2008 Wipro/JK  DefNBS007602  Begin
---------------------------------------------------------------------------------------------------------------
-- Function Name : TSL_INSERT_ITEM_RANGE
-- Purpose       : It copies the range attributes from the parent item.
---------------------------------------------------------------------------------------------------------------
--Mod By:      Nitin Kumar,nitin.kumar@in.tesco.com
--Mod Date:    31-Mar-2010
--Mod Ref:     CR224B
--Mod Details: Modified TSL_INSERT_ITEM_RANGE function to pick only those record whose end date
--             is NULL in TSL_ITEM_RANGE table
----------------------------------------------------------------------------------------------------------------
FUNCTION TSL_INSERT_ITEM_RANGE(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item           IN     ITEM_MASTER.ITEM%TYPE,
                               I_item_parent    IN     ITEM_MASTER.ITEM%TYPE,
                               -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                               I_country_id     IN     VARCHAR2)
                               -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
RETURN BOOLEAN is
   L_program      VARCHAR2(40) := 'ITEM_CREATE_SQL.TSL_INSERT_ITEM_RANGE';
   L_ind          VARCHAR2(1);
   L_ext_mastered VARCHAR2(1);
   -- 19-Aug-2009 Bhargavi Pujari , bharagvi.pujari@in.tesco.com ,CR236 Begin
   L_ext_mastered_roi  VARCHAR2(1);
   -- 19-Aug-2009 Bhargavi Pujari , bharagvi.pujari@in.tesco.com ,CR236 End
   L_item         ITEM_MASTER%ROWTYPE;
   cursor C_ITEM_RANGE_EXIST is
   select 'X'
     from tsl_item_range
    where item = I_item_parent
      -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
      and tsl_country_id = I_country_id;
      -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End

   --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    Begin
   L_item_parent_owner     ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
   L_system_options_row    SYSTEM_OPTIONS%ROWTYPE;
   L_security_ind          SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
   L_uk_ind                VARCHAR2(1) :=  'N';
   L_roi_ind               VARCHAR2(1) :=  'N';

   CURSOR C_GET_ITEM_PARENT_OWNER is
   select i.tsl_owner_country
     from item_master i
    where i.item = I_item_parent;
   --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    End
   --03-Sep-2010   TESCO HSC/Joy Stephen    DefNBS018990    Begin
   L_item_rec          ITEM_MASTER%ROWTYPE;
   L_login_ctry        ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
   --03-Sep-2010   TESCO HSC/Joy Stephen    DefNBS018990    End
   -- 17-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
   L_loc_access        VARCHAR2(1) := 'N';
   -- 17-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
BEGIN

   --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    Begin
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_system_options_row) = FALSE then
      return FALSE;
   end if;
   if FILTER_GROUP_HIER_SQL.TSL_USER_COUNTRY(O_error_message,
   	 																			   L_uk_ind,
     	 																			 L_roi_ind) = FALSE then
      return FALSE;
   end if;
   L_security_ind := L_system_options_row.tsl_loc_sec_ind;
   ---
   if L_security_ind = 'Y' then
      open C_GET_ITEM_PARENT_OWNER;
      fetch C_GET_ITEM_PARENT_OWNER into L_item_parent_owner;
      close C_GET_ITEM_PARENT_OWNER;
     ---
     --03-Sep-2010   TESCO HSC/Joy Stephen    DefNBS018990    Begin
     if L_uk_ind = 'Y' then
        L_login_ctry := 'U';
     elsif L_roi_ind = 'Y' and L_uk_ind = 'N' then
        L_login_ctry := 'R';
     end if;
     --03-Sep-2010   TESCO HSC/Joy Stephen    DefNBS018990    End
     ---
     -- 17-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
     if L_uk_ind = 'Y' and
     	  L_roi_ind = 'N' then
        L_loc_access := 'U';
     elsif L_uk_ind = 'N' and
     	  L_roi_ind = 'Y' then
        L_loc_access := 'R';
     elsif L_uk_ind = 'Y' and
     	  L_roi_ind = 'Y' then
        L_loc_access := 'B';
     end if;
     -- 17-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
     ---
   end if;
   --03-Sep-2010   TESCO HSC/Joy Stephen    DefNBS018990    Begin
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                      L_item_rec,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   --03-Sep-2010   TESCO HSC/Joy Stephen    DefNBS018990    End
   --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    End
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_RANGE_EXIST',
                    'TSL_ITEM_RANGE',
                    'Item: '|| I_item);

   open C_ITEM_RANGE_EXIST ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_RANGE_EXIST',
                    'TSL_ITEM_RANGE',
                    'Item: '|| I_item);

   fetch C_ITEM_RANGE_EXIST into L_ind;

   if C_ITEM_RANGE_EXIST%FOUND then
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item,
                                         I_item) = FALSE then
         return FALSE;
      end if;
      --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    Begin
      if L_security_ind = 'Y' then
         --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990   Begin
         -- 17-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
         if ((L_login_ctry = I_country_id) or
             (L_loc_access ='B'))then
         -- 17-Sep-2010, DefNBS019186, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
         --03-Sep-2010    TESCO HSC/Joy Stephen   DefNBS018990   End
            SQL_LIB.SET_MARK('INSERT',
                              NULL,
                              'TSL_ITEM_RANGE',
                              'ITEM: '||I_item);
            INSERT INTO TSL_ITEM_RANGE(item,
                                       effective_date,
                                       -- CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, Begin
                                       end_date,
                                       -- CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, End
                                       ntl_range_class,
                                       ntl_rest_code,
                                       high_st_range_class,
                                       high_st_rest_code,
                                       tsl_country_id)
                                SELECT I_item,
                                       t.effective_date,
                                       -- CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, Begin
                                       t.end_date,
                                       -- CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, End
                                       t.ntl_range_class,
                                       t.ntl_rest_code,
                                       t.high_st_range_class,
                                       t.high_st_rest_code,
                                       t.tsl_country_id
                                  FROM tsl_item_range t,
                                       item_master i
                                 WHERE t.item     =  I_item_parent
                                   AND i.item     =  t.item
                                   and t.tsl_country_id = I_country_id
                                   AND i.pack_ind <> 'Y'
                                   -- CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, Begin
                                   AND i.item     =  NVL(i.tsl_base_item, i.item);
                                   -- AND t.end_date is NULL;
                                   -- CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, End

            if L_item.pack_ind <> 'Y' and L_item.item = NVL(L_item.tsl_base_item, L_item.item) then
               if SUBCLASS_ATTRIB_SQL.TSL_GET_EXT_MASTERED_IND(O_error_message,
                                                               L_ext_mastered,
                                                               L_ext_mastered_roi,
                                                               L_item.dept,
                                                               L_item.class,
                                                               L_item.subclass) = FALSE then
                  return FALSE;
               end if;

               if L_ext_mastered = 'Y' then
                  if TSL_RANGE_ATTRIB_SQL.UPDATE_RANGE_AUTH(O_error_message,
                                                            I_item) = FALSE then
                     return FALSE;
                  end if;
               end if;
            end if;
         end if;
      else
         SQL_LIB.SET_MARK('INSERT',
                           NULL,
                           'TSL_ITEM_RANGE',
                           'ITEM: '||I_item);
         INSERT INTO TSL_ITEM_RANGE(item,
                                    effective_date,
                                    --CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, Begin
                                    end_date,
                                    --CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, End
                                    ntl_range_class,
                                    ntl_rest_code,
                                    high_st_range_class,
                                    high_st_rest_code,
                                    -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                    tsl_country_id)
                                    -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                             SELECT I_item,
                                    t.effective_date,
                                    --CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, Begin
                                    t.end_date,
                                    --CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 06-Dec-2010, End
                                    t.ntl_range_class,
                                    t.ntl_rest_code,
                                    t.high_st_range_class,
                                    t.high_st_rest_code,
                                    -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                    t.tsl_country_id
                                    -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                               FROM tsl_item_range t,
                                    item_master i
                              WHERE t.item     =  I_item_parent
                                AND i.item     =  t.item
                                -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, Begin
                                and t.tsl_country_id = I_country_id
                                -- CR236, 04-Sep-2009, Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com, End
                                AND i.pack_ind <> 'Y'
                                -- CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 02-Dec-2010, Begin
                                AND i.item     =  NVL(i.tsl_base_item, i.item);
                                -- CR224B, 31-Mar-2010, Nitin Kumar, nitin.kumar@in.tesco.com, Begin
                                -- AND t.end_date is NULL;
                                -- CR364, Sathishkumar Alagar, satishkumar.alagar@in.tesco.com, 02-Dec-2010, Begin
                                -- CR224B, 31-Mar-2010, Nitin Kumar, nitin.kumar@in.tesco.com, End

         if L_item.pack_ind <> 'Y' and L_item.item = NVL(L_item.tsl_base_item, L_item.item) then
            if SUBCLASS_ATTRIB_SQL.TSL_GET_EXT_MASTERED_IND(O_error_message,
                                                            L_ext_mastered,
                                                            -- 19-Aug-2009 Bhargavi Pujari , bharagvi.pujari@in.tesco.com ,CR236 Begin
                                                            L_ext_mastered_roi,
                                                            -- 19-Aug-2009 Bhargavi Pujari , bharagvi.pujari@in.tesco.com ,CR236 End
                                                            L_item.dept,
                                                            L_item.class,
                                                            L_item.subclass) = FALSE then
               return FALSE;
            end if;

            if L_ext_mastered = 'Y' then
               if TSL_RANGE_ATTRIB_SQL.UPDATE_RANGE_AUTH(O_error_message,
                                                         I_item) = FALSE then
                  return FALSE;
               end if;
            end if;

            ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 Begin
            --18-Feb-2010   Tesco HSC/Nandini Mariyappa       Mod CR288   Begin
            --Remove CR236 Chnges
            --18-Feb-2010   Tesco HSC/Nandini Mariyappa       Mod CR288   End
            ---MrgNBS016548  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,05-Mar-2010 End

         end if;
      end if;
      --20-Aug-2010     TESCO HSC/Joy Stephen  CR354    End
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_RANGE_EXIST',
                    'TSL_ITEM_RANGE',
                    'Item: '|| I_item);
   close C_ITEM_RANGE_EXIST;
   return TRUE;
EXCEPTION
   when OTHERS then
      if C_ITEM_RANGE_EXIST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ITEM_RANGE_EXIST',
                          'TSL_ITEM_RANGE',
                          'Item: '|| I_item);
         close C_ITEM_RANGE_EXIST;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_INSERT_ITEM_RANGE;
---------------------------------------------------------------------------------------------------------------
-- 04-Jul-2008 Wipro/JK  DefNBS007602  End
---------------------------------------------------------------------------------------------------------------
-- CR338, 15-Nov-2010, Phil Noon phil.noon@uk.tesco.com, Begin
FUNCTION TSL_UPDATE_CHILD_PACK(
                              O_error_message           IN OUT RTK_ERRORS.RTK_TEXT%TYPE
                             ,IO_occ                    IN OUT item_master.item%TYPE
                             ,I_tpnb                    IN item_master.item%TYPE
                             ,I_tpnd_item               In item_master.item%TYPE
                             ,I_tpnd_status             In item_master.status%TYPE
                             ,I_tpnd_desc               In item_master.item_desc%TYPE
                             ,I_ean                     IN item_master.item%TYPE
                             ,I_ean_type                IN item_master.item_number_type%TYPE
                             ,I_item_base_desc_1        IN TSL_ITEMDESC_BASE.BASE_ITEM_DESC_1%TYPE DEFAULT NULL
                             ,I_item_base_desc_2        IN TSL_ITEMDESC_BASE.BASE_ITEM_DESC_2%TYPE DEFAULT NULL
                             ,I_item_base_desc_3        IN TSL_ITEMDESC_BASE.BASE_ITEM_DESC_3%TYPE DEFAULT NULL
                             ,I_item_base_desc_eff_date IN DATE DEFAULT NULL
                             ,I_pack_desc               IN TSL_ITEMDESC_PACK.pack_desc%TYPE DEFAULT NULL
                             ,I_pack_desc_eff_date      IN DATE DEFAULT NULL
                             ,I_pack_qty                IN packitem.pack_qty%TYPE DEFAULT NULL
                             ,I_pack_cost               IN item_supp_country.unit_cost%TYPE DEFAULT NULL
                             ,I_generate_occ            IN BOOLEAN DEFAULT FALSE
                             ,I_occ_type                IN VARCHAR2 DEFAULT NULL
                              )
RETURN BOOLEAN IS

   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,Begin
   L_table                       VARCHAR2(40)   := 'TSL_ITEMDESC_BASE/TSL_ITEMDESC_PACK';
   L_program                     VARCHAR2(60)   := 'ITEM_CREATE_SQL.TSL_UPDATE_CHILD_PACK';
   RECORD_LOCKED                 EXCEPTION;
   PRAGMA                        EXCEPTION_INIT(RECORD_LOCKED, -54);
   -- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End

      Cursor C_base_desc (c_item in item_master.item%TYPE) Is
         select tib1.item
               ,tib1.effective_date
               ,tib1.base_item_desc_1
               ,tib1.base_item_desc_2
               ,tib1.base_item_desc_3
         from   tsl_itemdesc_base tib1
         where  tib1.item           = C_item
         AND    tib1.effective_date = ( SELECT MIN(dt)
                                        FROM(
                                             SELECT MAX(tib3.effective_date) dt
                                             FROM   tsl_itemdesc_base tib3
                                             WHERE  tib3.item           = C_item
                                             AND    tib3.effective_date <= get_vdate()
                                             UNION
                                             SELECT MIN(tib4.effective_date) dt
                                             FROM   tsl_itemdesc_base tib4
                                             WHERE  tib4.item           = C_item
                                             AND    tib4.effective_date > get_vdate()
                                            )
                                      )
         for update nowait;

     r_base_desc c_base_desc%ROWTYPE;
     L_occ       item_master.item%TYPE;

      Cursor C_pack_desc (c_pack_no in item_master.item%TYPE) Is
         select tip1.pack_no
               ,tip1.effective_date
               ,tip1.pack_desc
         from   tsl_itemdesc_pack tip1
         where  tip1.pack_no        = C_pack_no
 -- DefNBS020133, 17-Dec-2010, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, Begin
           and  tip1.effective_date = I_pack_desc_eff_date
          /* AND    tip1.effective_date = ( SELECT MIN(dt)
                                        FROM(
                                             SELECT MAX(tip3.effective_date) dt
                                             FROM   tsl_itemdesc_pack tip3
                                             WHERE  tip3.pack_no        = C_pack_no
                                             AND    tip3.effective_date <= get_vdate()
                                             UNION
                                             SELECT MIN(tip4.effective_date) dt
                                             FROM   tsl_itemdesc_pack tip4
                                             WHERE  tip4.pack_no        = C_pack_no
                                             AND    tip4.effective_date > get_vdate()
                                            )
                                      )*/
 -- DefNBS020133, 17-Dec-2010, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, End
         for update nowait;

     --DefNBS023566, 08-Sep-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, Begin
     cursor C_ITEM_EXISTS(C_item           in ITEM_MASTER.ITEM%TYPE,
                          C_effective_date in TSL_ITEMDESC_BASE.EFFECTIVE_DATE%TYPE) is
     select 'Y'
       from tsl_itemdesc_base
      where item           = C_item
        and effective_date = C_effective_date;
     --DefNBS023566, 08-Sep-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, End
     r_pack_desc             c_pack_desc%ROWTYPE;
     L_pack_qty              packitem.pack_qty%TYPE;
     L_exists                boolean;
     L_component_item        item_master.item%TYPE;
  -- CR338, DefNBS020557, 24-Jan-2011, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, Begin
  -- L_Colour_diff           diff_ids.diff_desc%TYPE;
     L_size_diff             diff_ids.diff_desc%TYPE;
  -- CR338, DefNBS020557, 24-Jan-2011, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, End
     L_is_non_tesco_occ_type boolean;
     --DefNBS023566, 08-Sep-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, Begin
     L_item_exists           VARCHAR2(1) := 'N';
     --DefNBS023566, 08-Sep-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, End

BEGIN
   --
   -- Update the item descriptions
   --
   if ( I_item_base_desc_1 is not null or
        I_item_base_desc_3 is not null or
        I_item_base_desc_3 is not null
      ) and I_item_base_desc_eff_date is not null
   then
      Open  C_base_desc(I_tpnb);
      Fetch C_base_desc into R_base_desc;

      if R_base_desc.effective_date > get_vdate() and
         R_base_desc.effective_date = I_item_base_desc_eff_date
      then
         update tsl_itemdesc_base tib
         set    tib.base_item_desc_1 = nvl(I_item_base_desc_1, R_base_desc.base_item_desc_1)
               ,tib.base_item_desc_2 = nvl(I_item_base_desc_2, R_base_desc.base_item_desc_2)
               ,tib.base_item_desc_3 = nvl(I_item_base_desc_3, R_base_desc.base_item_desc_3)
         where  CURRENT OF C_base_desc;
      else
         --DefNBS023566, 08-Sep-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, Begin
         open C_ITEM_EXISTS(I_tpnb,
                            I_item_base_desc_eff_date);
         fetch C_ITEM_EXISTS into L_item_exists;
         close C_ITEM_EXISTS;

         if NVL(L_item_exists, 'N') = 'Y' then
            update tsl_itemdesc_base tib
               set tib.base_item_desc_1 = nvl(I_item_base_desc_1, R_base_desc.base_item_desc_1),
                   tib.base_item_desc_2 = nvl(I_item_base_desc_2, R_base_desc.base_item_desc_2),
                   tib.base_item_desc_3 = nvl(I_item_base_desc_3, R_base_desc.base_item_desc_3)
             where item           = I_tpnb
               and effective_date = I_item_base_desc_eff_date;
         else
         --DefNBS023566, 08-Sep-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, End
            insert into tsl_itemdesc_base (
                                           item,
                                           effective_date,
                                           base_item_desc_1,
                                           base_item_desc_2,
                                           base_item_desc_3
                                          )
                                   values (I_tpnb,      /* ITEM */
                                           I_item_base_desc_eff_date,      /* EFFECTIVE_DATE */
                                           nvl(i_item_base_desc_1, R_base_desc.base_item_desc_1), /* BASE_ITEM_DESC_1 */
                                           nvl(i_item_base_desc_2, R_base_desc.base_item_desc_2), /* BASE_ITEM_DESC_2 */
                                           nvl(i_item_base_desc_3, R_base_desc.base_item_desc_3) /* BASE_ITEM_DESC_3 */
                                          );
         --DefNBS023566, 08-Sep-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, Begin
         end if;
         --DefNBS023566, 08-Sep-2011, Vatan Jaiswal, vatan.jaiswal@in.tesco.com, End
      end if;

      Close C_Base_desc;

      if tsl_itemdesc_sql.copy_product_desc(
                     O_error_message  => O_Error_message
                    ,I_item           => I_tpnb
                    ,I_cascade_var    => 'Y'
             ) = FALSE then
         return FALSE;
      end if;
   end if;

   IF I_tpnd_item IS NOT NULL THEN
      -- Def20833, 04-Feb-2011, Veena Nanjundaiah, veena.nanjundaiah@in.tesco.com, Begin
      if I_Pack_qty  is NOT NULL or
      -- Def20833, 04-Feb-2011, Veena Nanjundaiah, veena.nanjundaiah@in.tesco.com, End
         I_Pack_cost is not null
      THEN
         --
         -- Update pack
         --
         if tsl_item_diff_sql.update_pack(
                 O_error_message           => O_error_message
                ,I_Pack_No                 => I_tpnd_item
                ,I_Pack_Qty                => I_pack_qty
                ,I_Pack_Cost               => I_pack_cost
                ) = FALSE then
            return FALSE;
         end if;
      END IF;

      --
      -- Update the 'pack' description
      --
      if I_pack_desc is not null and
         I_pack_desc_eff_date is not null
      then
         --
         -- We need to get the co
         --
 -- CR338, DefNBS020557, 24-Jan-2011, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, Begin
       --if tsl_item_diff_sql.f_get_colour_diff(
         if tsl_item_diff_sql.f_get_size_diff(
                                O_error_message => O_error_message
                             --,O_Colour_Diff     => L_Colour_diff
                               ,O_Size_Diff     => L_size_diff
 -- CR338, DefNBS020557, 24-Jan-2011, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, End
                               ,I_Item          => I_tpnb
                              ) = FALSE then
            return FALSE;
         end if;
         --
         -- Now insert/update the description as appropriate
         --
         Open  C_pack_desc(I_tpnd_item);
         Fetch C_pack_desc into R_pack_desc;
 -- DefNBS020133, 17-Dec-2010, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, Begin
         if --R_pack_desc.effective_date > get_vdate() and
            R_pack_desc.Pack_No   = I_tpnd_item and
            R_pack_desc.effective_date = I_pack_desc_eff_date
 -- DefNBS020133, 17-Dec-2010, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, End
         then
            update tsl_itemdesc_pack tip
 -- DefNBS020557a, 31-Jan-2011, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, Begin
            --set    tip.pack_desc = nvl(rpad(I_pack_desc,19)||L_size_diff, R_pack_desc.pack_desc)
            set    tip.pack_desc = substr(nvl(rpad(I_pack_desc,19)||L_size_diff, R_pack_desc.pack_desc),1,24)
 -- DefNBS020557a, 31-Jan-2011, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, End
            where  CURRENT OF C_pack_desc;
         else
            insert into tsl_itemdesc_pack (
                   pack_no
                 , effective_date
                 , pack_desc
                 )
              values ( I_tpnd_item      /* Pack */
                     , I_pack_desc_eff_date      /* EFFECTIVE_DATE */
 -- DefNBS020557a, 31-Jan-2011, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, Begin
                     --, nvl(rpad(I_pack_desc,19)||L_size_diff, R_pack_desc.pack_desc) /* PACK_DESC */
                     , substr(nvl(rpad(I_pack_desc,19)||L_size_diff, R_pack_desc.pack_desc),1,24) /* PACK_DESC */
 -- DefNBS020557a, 31-Jan-2011, Shireen Sheosunker shireen.sheosunker@uk.tesco.com, End
                 );
         end if;

         Close C_pack_desc;
      end if;

      --
      -- If there is no occ then create one
      --
      L_is_non_tesco_occ_type := tsl_item_diff_sql.f_is_non_tesco_occ_type(I_occ_type);
      if I_generate_occ or
         ( I_ean_type is not null and L_is_non_tesco_occ_type )
      then
         if IO_occ is null then
            --
            -- If the passed in package qty is null then we must
            -- use the existing package quantity
            --
            if I_pack_qty is null then
               if packitem_attrib_sql.get_item_and_qty(
                              O_error_message => O_error_message
                             ,O_exists        => L_exists
                             ,O_item          => L_component_item
                             ,O_qty           => L_pack_qty
                             ,I_pack_no       => I_tpnd_item
                              ) = FALSE then
                  return FALSE;
               end if;
            else
               L_pack_qty := I_pack_qty;
            end if;
            if ( L_is_non_tesco_occ_type and L_pack_qty=1 ) or
                I_generate_occ
            then
              if TSL_ITEM_DIFF_SQL.create_occ (
                       O_error_message => O_error_message
                      ,O_occ           => L_occ
                      ,I_ean           => I_ean
                      ,I_ean_type      => I_ean_type
                      ,I_pack_qty      => L_pack_qty
                      ,I_primary_pack  => I_tpnd_item
                      ,I_status        => I_tpnd_status
                      ,I_occ_type      => I_occ_type
                      ,I_item_desc     => I_tpnd_desc
                      ,I_diff_1        => null
                      ,I_diff_2        => null
                      ,I_diff_3        => null
                      ,I_diff_4        => null
                      ,I_auto_approve  => 'N'
                      ) = FALSE then
               return FALSE;
              end if;
              IO_occ := L_occ;
            end if;
         end if;
      end if;
   end if;
   return TRUE;
-- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,Begin
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
-- DefNBS023046,Ankush, ankush.khanna@in.tesco.com,23-June-2011,End
END TSL_UPDATE_CHILD_PACK;
------------------------------------------------------------------------------
-- Function: TSL_MASS_UPDATE_CHILDREN_PACK
-- Purpose:  Pack updates from itemchildrendiff
--------------------------------------------------------------------------

FUNCTION TSL_MASS_UPDATE_CHILDREN_PACK(
                              O_error_message           IN OUT  RTK_ERRORS.RTK_TEXT%TYPE
                             ,I_item_parent             IN      ITEM_MASTER.ITEM_PARENT%TYPE
                             ,I_item_base_desc_1        IN TSL_ITEMDESC_BASE.BASE_ITEM_DESC_1%TYPE DEFAULT NULL
                             ,I_item_base_desc_2        IN TSL_ITEMDESC_BASE.BASE_ITEM_DESC_2%TYPE DEFAULT NULL
                             ,I_item_base_desc_3        IN TSL_ITEMDESC_BASE.BASE_ITEM_DESC_3%TYPE DEFAULT NULL
                             ,I_item_base_desc_eff_date IN DATE DEFAULT NULL
                             ,I_pack_desc               IN TSL_ITEMDESC_PACK.pack_desc%TYPE DEFAULT NULL
                             ,I_pack_desc_eff_date      IN DATE DEFAULT NULL
                             ,I_pack_qty                IN packitem.pack_qty%TYPE DEFAULT NULL
                             ,I_pack_cost               IN item_supp_country.unit_cost%TYPE DEFAULT NULL
                             ,I_generate_occ            IN BOOLEAN DEFAULT FALSE
                             ,I_occ_type                IN VARCHAR2 DEFAULT NULL
                              )
RETURN BOOLEAN IS
   CURSOR c_tpnbs IS
     Select tpnb.item            tpnb
          , ean.item             ean
          , ean.item_number_type ean_type
          , pack.pack_no
          , pack.component_item
          , pack.pack_qty
          , pack.occ
          , pack.tpnd_status
          , pack.tpnd_desc
     From   item_master tpna
           ,item_master tpnb
           ,item_master ean
           ,( select tpnd.status    tpnd_status
                    ,tpnd.item_desc tpnd_desc
                    ,pi.pack_no
                    ,pi.item        component_item
                    ,pi.pack_qty
                    ,occ.item       occ
                    ,occ.status     occ_status
              from   item_master tpnd
                    ,packitem    pi
                    ,item_master occ
              where  tpnd.tran_level        = 1
              and    tpnd.item_level        = 1
              and    tpnd.tsl_prim_pack_ind = 'Y'
              and    pi.pack_no             = tpnd.item
              and    occ.item_parent    (+) = tpnd.item
              and    occ.item_level     (+) = 2
              and    occ.tran_level     (+) = 1
              and    occ.primary_ref_item_ind (+)= 'Y'
            ) pack
     Where  tpna.item                   = I_item_parent
     and    tpna.item_level             = 1
     and    tpna.tran_level             = 2
     and    tpnb.item_parent            = tpna.item
     and    tpnb.item_level             = 2
     and    tpnb.tran_level             = 2
     and    ean.item_parent          (+)= tpnb.item
     and    ean.item_level           (+)= 3
     and    ean.tran_level           (+)= 2
     and    ean.primary_ref_item_ind (+)= 'Y'
     and    pack.component_item      (+)= tpnb.item
     ;

     L_occ         item_master.item%TYPE;
BEGIN
   FOR rec IN c_tpnbs LOOP
      l_occ := rec.occ;
      if TSL_UPDATE_CHILD_PACK(
                O_error_message           => O_error_message
               ,IO_occ                    => L_occ
               ,I_tpnb                    => rec.tpnb
               ,I_tpnd_item               => rec.pack_no
               ,I_tpnd_status             => rec.tpnd_status
               ,I_tpnd_desc               => rec.tpnd_desc
               ,I_ean                     => rec.ean
               ,I_ean_type                => rec.ean_type
               ,I_item_base_desc_1        => I_item_base_desc_1
               ,I_item_base_desc_2        => I_item_base_desc_2
               ,I_item_base_desc_3        => I_item_base_desc_3
               ,I_item_base_desc_eff_date => I_item_base_desc_eff_date
               ,I_pack_desc               => I_pack_desc
               ,I_pack_desc_eff_date      => I_pack_desc_eff_date
               ,I_pack_qty                => I_pack_qty
               ,I_pack_cost               => I_pack_cost
               ,I_generate_occ            => I_generate_occ
               ,I_occ_type                => I_occ_type
                ) = FALSE then
        return FALSE;
      end if;
   END LOOP;

   return TRUE;

END TSL_MASS_UPDATE_CHILDREN_PACK;
-- CR338, 15-Nov-2010, Phil Noon phil.noon@uk.tesco.com, End
----------------------------------------------------------------------------------------------------
-- CR254, 21-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com BEGIN
----------------------------------------------------------------------------------------------------
-- Author        : Ravi Nagaraju, ravi.nagaraju@in.tesco.com
-- Function Name : TSL_INSERT_ITEM_ATTRIBUTES
-- Purpose       : This function will not insert data into item attribute table for EAN/OCC for tariff code
--                 and supplementory unit fields
----------------------------------------------------------------------------------------------------
FUNCTION TSL_INSERT_ITEM_ATTRIBUTES (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     I_item           IN     ITEM_MASTER.ITEM%TYPE,
                                     I_item_parent    IN     ITEM_MASTER.ITEM%TYPE,
                                     I_country_id     IN     VARCHAR2,
                                     I_excl_code_1    IN     VARCHAR2,
                                     I_excl_code_2    IN     VARCHAR2)
  RETURN BOOLEAN is

  E_record_locked     EXCEPTION;
  PRAGMA              EXCEPTION_INIT(E_record_locked, -54);
  L_program           VARCHAR2(300)   := 'ITEM_CREATE_SQL.TSL_INSERT_ITEM_ATTRIBUTES';
  L_sql_select        VARCHAR2(32767) := NULL;
  L_sql_insert        VARCHAR2(32767) := NULL;
  L_sql_column        VARCHAR2(32767) := NULL;
  L_item_rec          ITEM_MASTER%ROWTYPE;
  L_item_parent_rec   ITEM_MASTER%ROWTYPE;
  L_lvl2_ind          VARCHAR2(1)     := 'N';
  L_lvl3_ind          VARCHAR2(1)     := 'N';
  L_base_ind          VARCHAR2(1);
  L_exists            BOOLEAN         := FALSE;
  L_item_level        NUMBER(1);
  L_system_options_row    SYSTEM_OPTIONS%ROWTYPE;
  L_security_ind          SYSTEM_OPTIONS.TSL_LOC_SEC_IND%TYPE;
  L_item_parent_owner     ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_uk_ind                VARCHAR2(1) :=  'N';
  L_roi_ind               VARCHAR2(1) :=  'N';
  L_login_ctry            ITEM_MASTER.TSL_OWNER_COUNTRY%TYPE;
  L_loc_access            VARCHAR2(1) := 'N';

  -- This cursor will lock the items on the table ITEM_ATTRIBUTES table
  cursor C_LOCK_ITEM is
  select 'x'
    from item_attributes ia
   where ia.item in (select im.item
                       from item_master im
                      where im.item_parent = L_item_rec.item
                        and im.item_level  = L_item_rec.item_level + 1)
     and ia.tsl_country_id = I_country_id
     for update nowait;

  -- This cursor will retrieve the codes, and the corresponding column for the
  -- attributes that can be copied between a Level 1 Item to a Level 2 Item
  cursor C_GET_COLUMNS is
  select tmc.tsl_column_name column_name,
         tmc.tsl_code code,
         mhd.required_ind req_ind
    from tsl_map_item_attrib_code tmc,
         merch_hier_default mhd
   where tmc.tsl_code            = mhd.info
     and mhd.info           NOT IN ('TEPW',I_excl_code_1,I_excl_code_2)
     and mhd.tsl_pack_ind    = L_item_rec.pack_ind
     and mhd.available_ind   = 'Y'
     -- DefNBS020837, 7-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com Begin
     and mhd.tsl_item_lvl    = L_item_rec.item_level + 1
     -- DefNBS020837, 7-Feb-2011 , Venkatesh S, venkatesh.suvarna@in.tesco.com End
     and mhd.tsl_country_id in (I_country_id,'B')
     and mhd.dept            = L_item_rec.dept
     and mhd.class           = L_item_rec.class
     and mhd.subclass        = L_item_rec.subclass
     and DECODE(L_lvl2_ind,'Y',DECODE(L_base_ind,'Y',mhd.tsl_base_ind,mhd.tsl_var_ind),'Y') = 'Y'
     and (exists (select 1
                    from merch_hier_default a
                   where a.info = mhd.info
                     and a.available_ind = 'Y'
                     and a.dept          = mhd.dept
                     and a.class         = mhd.class
                     and a.subclass      = mhd.subclass
                     and a.tsl_country_id in (I_country_id,'B')
                     and a.tsl_item_lvl  = L_item_rec.item_level - 1
                     and a.tsl_pack_ind  = L_item_rec.pack_ind
                     and DECODE(L_lvl3_ind,'Y',DECODE(L_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
              or
       not exists (select 1
                     from merch_hier_default a
                    where a.info          = mhd.info
                      and a.dept          = mhd.dept
                      and a.class         = mhd.class
                      and a.subclass      = mhd.subclass
                      and a.tsl_country_id in (I_country_id,'B')
                      and a.tsl_item_lvl  = L_item_rec.item_level - 1
                      and a.tsl_pack_ind  = L_item_rec.pack_ind
                      and DECODE(L_lvl3_ind,'Y',DECODE(L_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y'))
    union
    select tmc.tsl_column_name column_name,
           tmc.tsl_code code,
           'N' req_ind
      from tsl_map_item_attrib_code tmc
     where not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.dept = L_item_rec.dept
                          and a.class = L_item_rec.class
                          and a.subclass = L_item_rec.subclass
                          and a.tsl_country_id in (I_country_id,'B')
                          and a.tsl_pack_ind  = L_item_rec.pack_ind
                          and a.tsl_item_lvl = L_item_rec.item_level
                          and DECODE(L_lvl2_ind,'Y',DECODE(L_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
       and not exists (select 1
                         from merch_hier_default a
                        where a.info = tmc.tsl_code
                          and a.available_ind = 'N'
                          and a.dept = L_item_rec.dept
                          and a.class = L_item_rec.class
                          and a.subclass = L_item_rec.subclass
                          and a.tsl_country_id in (I_country_id,'B')
                          and a.tsl_pack_ind  = L_item_rec.pack_ind
                          and a.tsl_item_lvl = L_item_rec.item_level
                          and DECODE(L_lvl2_ind,'Y',DECODE(L_base_ind,'Y',a.tsl_base_ind,a.tsl_var_ind),'Y') = 'Y')
       and tmc.tsl_code NOT IN ('TEPW',I_excl_code_1,I_excl_code_2);

   CURSOR C_GET_ITEM_PARENT_OWNER is
   select i.tsl_owner_country
     from item_master i
    where i.item = I_item_parent;

BEGIN

  if I_item is NULL then
      -- If input item is null then throws an error
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             I_item,
                                             L_program,
                                             NULL);
      return FALSE;
  elsif I_item_parent is NULL then
      -- If input item is null then throws an error
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             I_item_parent,
                                             L_program,
                                             NULL);
      return FALSE;
  end if;
  ---
  if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                      L_item_rec,
                                      I_item_parent) = FALSE then
      return FALSE;
  end if;
  ---

  if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                           L_system_options_row) = FALSE then
     return FALSE;
  end if;
  L_security_ind := L_system_options_row.tsl_loc_sec_ind;
  ---
  if L_security_ind = 'Y' then
     open C_GET_ITEM_PARENT_OWNER;
     fetch C_GET_ITEM_PARENT_OWNER into L_item_parent_owner;
     close C_GET_ITEM_PARENT_OWNER;
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

     if L_uk_ind = 'Y' and
         L_roi_ind = 'N' then
        L_loc_access := 'U';
     elsif L_uk_ind = 'N' and
         L_roi_ind = 'Y' then
        L_loc_access := 'R';
     elsif L_uk_ind = 'Y' and
         L_roi_ind = 'Y' then
        L_loc_access := 'B';
     end if;

     ---
  end if;

  if L_item_rec.tran_level = 2 and
     L_item_rec.item_level = L_item_rec.tran_level and
     L_item_rec.pack_ind = 'N' then
      ---
      if L_item_rec.item = L_item_rec.tsl_base_item then
          L_base_ind := 'Y';
      else
          L_base_ind := 'N';
      end if;
      ---
      L_lvl2_ind := 'Y';
      L_item_level := 2;
      ---
  elsif L_item_rec.tran_level = 2 and
        L_item_rec.item_level > L_item_rec.tran_level and
        L_item_rec.pack_ind = 'N' then
      ---
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                          L_item_parent_rec,
                                          I_item_parent) = FALSE then
          return FALSE;
      end if;
      ---
      if L_item_parent_rec.item = L_item_parent_rec.tsl_base_item then
          L_base_ind := 'Y';
      else
          L_base_ind := 'N';
      end if;
      ---
      L_lvl3_ind := 'Y';
      L_item_level := 3;
      ---
  end if;
  ---
  -- This cursor will retrieve the codes, and the corresponding column for the attributes
  -- that can be copied between the L1 item to L2 Items
  --Opening the cursor C_GET_COLUMNS
  SQL_LIB.SET_MARK('OPEN',
                   'C_GET_COLUMNS',
                   'TSL_MAP_ITEM_ATTRIB_CODE',
                   'ITEM: ' ||I_item);
  FOR C_rec in C_GET_COLUMNS
  LOOP
      -- checking L_sql_select is null or not
      L_exists := TRUE;

      if (((L_login_ctry = I_country_id) or
         L_security_ind = 'N') or
          (L_loc_access = 'B' and L_security_ind = 'Y') or
         (L_login_ctry <> I_country_id and
         L_security_ind = 'Y' and
         C_rec.column_name NOT in
         ('TSL_DIAMOND_LINE_IND','TSL_DEV_LINE_IND','TSL_LAUNCH_DATE','TSL_POS_CODES','TSL_DEV_END_DATE'))) then
         if L_sql_select is NULL then
             L_sql_insert := 'ia.'||C_rec.column_name;
             L_sql_select := C_rec.column_name;
         else
             L_sql_insert := L_sql_insert ||',ia.'|| C_rec.column_name;
             L_sql_select := L_sql_select || ', ' || C_rec.column_name;
         end if;
      end if;
  END LOOP;
  ---
  if L_exists = TRUE then
      L_sql_insert := ' insert into item_attributes (ITEM, tsl_country_id, '||L_sql_select||' )' ||
                                           ' select '||chr(39)||I_item||chr(39)||', '||chr(39)||I_country_id||chr(39)||', ' ||L_sql_insert||
                                            ' from item_attributes ia'||
                                           ' where ia.item = '''|| I_item_parent ||''''||
                                             ' and not exists (select 1'||
                                                               ' from item_attributes b '||
                                                               'where b.item = '''||I_item||''''||
                                                               '  and b.tsl_country_id = '''||I_country_id||''')'||
                                             ' and ia.tsl_country_id = '''||I_country_id||''';';

     ---
     -- Execute the Dynamic SQL, using the instruction EXECUTE IMMEDIATE:
     EXECUTE IMMEDIATE 'Begin '|| L_sql_insert ||' End;';
  end if;
  ---
  return TRUE;
  ---
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
END TSL_INSERT_ITEM_ATTRIBUTES;
-- CR254, 21-Dec-2010, Ravi Nagaraju, ravi.nagaraju@in.tesco.com End

END ITEM_CREATE_SQL;
/

