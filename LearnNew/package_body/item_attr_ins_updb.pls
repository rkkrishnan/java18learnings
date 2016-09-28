CREATE OR REPLACE PACKAGE BODY ITEM_ATTR_INS_UPD AS
-------------------------------------------------------------------------------------------------------
-- Mod By:      Nandini Mariyappa
-- Mod Date:    22-Nov-2007
-- Mod Ref:     Mod N105.
-- Mod Details: Modified functions INSERT_ATTRIBUTES and MODIFY_ATTRIBUTES to remove the fields
--              tsl_consumer_unit and tsl_consumer_unit_b.
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Mod By:      Nandini Mariyappa
-- Mod Date:    09-Oct-2007
-- Mod Ref:     Mod N20a.
-- Mod Details: 1. Modified the function INSERT_ATTRIBUTES to include three additonal attributes
--                 tsl_consumer_unit_b,tsl_weee_ind,tsl_deact_req_date while inserting
--                 item_attributes recieved from external systems.
--              2. Modified the function MODIFY_ATTRIBUTES to update newly added item attributes
--                 tsl_consumer_unit_b,tsl_weee_ind,tsl_deact_req_date.
-------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Mod By     : Wipro Enabler/Dhuraison Prince                                                    --
-- Mod Date   : 06-Feb-2008                                                                       --
-- Mod Ref    : Mod N114                                                                          --
-- Mod Details: Removed all references being made to the dropped columns namely TSL_MULTIPACK_QTY --
--              and TSL_UNIT_QTY of ITEM_ATTRIBUTES table.                                        --
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Mod By:      Usha Patil
-- Mod Date:    27-Mar-2008
-- Mod Ref:     Mod N126.
-- Mod Details: Modified INSERT_ATTRIBUTES and MODIFY_ATTRIBUTES to remove tsl_deact_req_date.
-------------------------------------------------------------------------------------------------------
-- Mod By     : Wipro Enabler/Sundara Rajan                                                       --
-- Mod Date   : 27-Mar-2008                                                                       --
-- Mod Ref    : Mod N53                                                                           --
-- Mod Details: Removed all references being made to the dropped columns namely TSL_MU_IND        --
--              in the ITEM_ATTRIBUTES table                                                      --
----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Mod By:      Rahul Soni
-- Mod Date:    8-May-2008
-- Mod Ref:     Mod N138/CR115.
-- Mod Details: Added tsl_local_sourced field for Item Attributes.
---------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- Mod By:      Bahubali Dongare Bahubali.Dongare@in.tesco.com
-- Mod Date:    29-May-2008
-- Mod Ref:     Mod N111.
-- Mod Details: Removed TSL_COMMON_PRODUCT_IND and TSL_PRIMARY_COUNTRY_IND from the package body.
-------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- Mod By:      Vinod Kumar.vinod.patalappa@in.tesco.com
-- Mod Date:    24-Jun-2008
-- Mod Ref:     Mod N111.
-- Mod Details: Added the NVL condition for the not null field tsl_weee_ind to avoid exception.
-------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Mod By:      Vijaya Bhaskar/Wipro-Enabler
-- Mod Date:    26-Jun-2008
-- Mod Ref:     Mod N155
-- Mod Details: Modified INSERT_ATTRIBUTES and MODIFY_ATTRIBUTES to add new fields
--              tsl_dev_line_ind,tsl_dev_end_date,tsl_base_label_size_ind,
--              tsl_pos_codes.
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Mod By:      Usha Patil
-- Mod Date:    18-Jly-2008
-- Mod Ref:     Mod N144.
-- Mod Details: Added tsl_pwdtu_ind field for Item Attributes.
---------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar,nitin.kumar@in.tesco.com
-- Mod Date   : 27-Nov-2008
-- Mod Ref    : CR187
-- Mod Details: Modified INSERT_ATTRIBUTES and MODIFY_ATTRIBUTES to add tsl_low_lvl_code,
--              tsl_low_lvl_code_desc and tsl_low_lvl_seq_no
-----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Mod By      : Nandini Mariyappa, Nandini.Mariyappa@in.tesco.com
-- Mod Date    : 27-Jan-2009
-- Def Ref     : DefNBS00011128
-- Def Detail  : Modified the function MODIFY_ATTRIBUTES to add NVL condition for the
--               not NULL field tsl_weee_ind.
-----------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 18-Aug-2009
-- Mod Ref    : CR236
-- Mod Details: Modified INSERT_ATTRIBUTES and MODIFY_ATTRIBUTES to add the newly added field tsl_country_id.
------------------------------------------------------------------------------------------------------------
-- Mod By      : Srinivasa Janga, Srinivasa.Janga@in.tesco.com
-- Mod Date    : 23-Sep-2009
-- Def Ref     : NBS00014852
-- Def Detail  : Modified the function MODIFY_ATTRIBUTES to add NVL condition for all
--                 fields.
---------------------------------------------------------------------------------------
-- Mod By     : Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 23-Oct-2009
-- Mod Ref    : MrgNBS015130
-- Mod Details: Merge 3.4 Dev to 3.5b
--------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 10-Mar-2010
-- Mod Ref    : DefNBS016142
-- Mod Details: Modified INSERT_ATTRIBUTES and MODIFY_ATTRIBUTES to remove the field tsl_low_lvl_code_desc.
------------------------------------------------------------------------------------------------------------
-- Mod By     : Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com
-- Mod Date   : 23-Nov-2010
-- Mod Ref    : DefNBS019847
-- Mod Details: Modified INSERT_ATTRIBUTES.
------------------------------------------------------------------------------------------------------------
-- Mod By     : Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com
-- Mod Date   : 03-Dec-2010
-- Mod Ref    : DefNBS019847a
-- Mod Details: Modified INSERT_ATTRIBUTES.
------------------------------------------------------------------------------------------------------------
-- Mod By     : Vivek Sharma  ,Vivek.Sharma@in.tesco.com
-- Mod Date   : 10-Dec-2010
-- Mod Ref    : NBS00020107
-- Mod Details: Modified INSERT_ATTRIBUTES and MODIFY_ATTRIBUTES for trimming tarif_code spaces.
------------------------------------------------------------------------------------------------------------
-- Mod By     : Vinutha Raju  ,Vinutha.Raju@in.tesco.com
-- Mod Date   : 05-Jan-2011
-- Mod Ref    : MrgNBS020416
-- Mod Details: Merged th Production defect NBS00020107 to 3.5b branch
------------------------------------------------------------------------------------------------------------
-- Mod By     : Ankush, ankush.khanna@in.tesco.com
-- Mod Date   : 02-Aug-2011
-- Mod Ref    : CR432
-- Mod Details: Modified INSERT_ATTRIBUTES and MODIFY_ATTRIBUTES to add the newly added field tsl_multipack_qty.
------------------------------------------------------------------------------------------------------------

FUNCTION INSERT_ATTRIBUTES(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           I_item_attr_rec IN ITEM_ATTRIBUTES%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_ATTR_INS_UPD.INSERT_ITEM_ATTRIBUTES';

BEGIN
   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_ATTRIBUTES','item: '||I_item_attr_rec.item);

   insert into item_attributes (item,
                                tsl_in_store_shelf_life_ind,
                                tsl_daily_shelf_life_mon,
                                tsl_daily_shelf_life_tue,
                                tsl_daily_shelf_life_wed,
                                tsl_daily_shelf_life_thu,
                                tsl_daily_shelf_life_fri,
                                tsl_daily_shelf_life_sat,
                                tsl_daily_shelf_life_sun,
                                tsl_in_store_shelf_life_days,
                                tsl_min_life_depot_days,
                                -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - Begin --
                                -- Removing the reference to the column tsl_multipack_qty which is being dropped
                                -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - End --
                                tsl_min_cus_storage_days,
                                tsl_diamond_line_ind,
                                tsl_sell_by_type,
                                tsl_drained_ind,
                                -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - Begin --
                                -- Removing the reference to the column tsl_unit_qty which is being dropped
                                -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - End --
                                -- 29-May-2008 Wipro Enabler/Bahubali Dongare - Mod:N111 - Begin
                                --tsl_common_product_ind,
                                --tsl_primary_country_ind,
                                -- 29-May-2008 Wipro Enabler/Bahubali Dongare - Mod:N111 - End
                                --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    Begin
                                --tsl_consumer_unit,
                                --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    End
                                tsl_country_of_origin,
                                tsl_supp_country,
                                tsl_brand_ind,
                                tsl_brand,
                                tsl_sell_by_100g_ind,
                                tsl_package_type,
                                -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - Begin --
                                -- Removing the reference to the column tsl_mu_ind which is being dropped
                                -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - End --
                                tsl_case_type,
                                tsl_tarif_code,
                                tsl_supp_unit,
                                tsl_process_type,
                                tsl_event,
                                tsl_supp_non_del_days_mon_ind,
                                tsl_supp_non_del_days_tue_ind,
                                tsl_supp_non_del_days_wed_ind,
                                tsl_supp_non_del_days_thu_ind,
                                tsl_supp_non_del_days_fri_ind,
                                tsl_supp_non_del_days_sat_ind,
                                tsl_supp_non_del_days_sun_ind,
                                tsl_case_per_pack,
                                tsl_high_value_ind,
                                tsl_epw_ind,
                                --09-Oct-2007     TESCO HSC/Nandini Mariyappa        Mod:N20a    Begin
                                --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    Begin
                                --tsl_consumer_unit_b,
                                --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    End
                                tsl_weee_ind,
                                --27-Mar-2008     Tesco HSC/Usha Patil           Mod:N126 Begin
                                -- tsl_deact_req_date,
                                --27-Mar-2008     Tesco HSC/Usha Patil           Mod:N126 End
                                --09-Oct-2007     TESCO HSC/Nandini Mariyappa        Mod:N20a    End
                                --26-Oct-2007 Tesco HSC/Vinod         Defect#:NBS00003704 Begin
                                tsl_launch_date,
                                --8-May-2008     TESCO HSC/Rahul Soni               Mod:N138/CR115    Begin
                                tsl_local_sourced,
                                --8-May-2008     TESCO HSC/Rahul Soni               Mod:N138/CR115    End
                                --18-Jly-2008     Tesco HSC/Usha Patil               Mod:N144    Begin
                                tsl_pwdtu_ind,
                                --18-Jly-2008     Tesco HSC/Usha Patil               Mod:N144    End
                                --26-Oct-2007 Tesco HSC/Vinod         Defect#:NBS00003704 End
                                --26-Jun-2008   TESCO HSC Vijaya Bhaskar/Wipro-Enabler   Mod:N155   Begin
                                tsl_dev_line_ind,
                                tsl_dev_end_date,
                                tsl_base_label_size_ind,
                                tsl_pos_codes,
                                --26-Jun-2008   TESCO HSC Vijaya Bhaskar/Wipro-Enabler   Mod:N155   End
                                -- CR187, 27-Nov-2008, Nitin Kumar, nitin.kumar@in.tesco.com Begin
                                tsl_low_lvl_code,
                                -- 10-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016142    Begin
                                -- As part of this defect we have removed the column tsl_low_lvl_code_desc from
                                -- item_attributes table.
                                --tsl_low_lvl_code_desc,
                                -- 10-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016142    End
                                tsl_low_lvl_seq_no,
                                -- CR187, 27-Nov-2008, Nitin Kumar, nitin.kumar@in.tesco.com End
                                --18-Aug-2009   TESCO HSC/Joy Stephen   CR236   Begin
                                tsl_country_id,
                                --18-Aug-2009   TESCO HSC/Joy Stephen   CR236   End
                                --02-Aug-2011   TESCO HSC/Ankush   CR432   Begin
                                tsl_multipack_qty)
                                --02-Aug-2011   TESCO HSC/Ankush   CR432   End
                        values (I_item_attr_rec.item,
                                I_item_attr_rec.tsl_in_store_shelf_life_ind,
                                I_item_attr_rec.tsl_daily_shelf_life_mon,
                                I_item_attr_rec.tsl_daily_shelf_life_tue,
                                I_item_attr_rec.tsl_daily_shelf_life_wed,
                                I_item_attr_rec.tsl_daily_shelf_life_thu,
                                I_item_attr_rec.tsl_daily_shelf_life_fri,
                                I_item_attr_rec.tsl_daily_shelf_life_sat,
                                I_item_attr_rec.tsl_daily_shelf_life_sun,
                                I_item_attr_rec.tsl_in_store_shelf_life_days,
                                I_item_attr_rec.tsl_min_life_depot_days,
                                -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - Begin --
                                -- Removing the reference to the column tsl_multipack_qty which is being dropped
                                -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - End --
                                I_item_attr_rec.tsl_min_cus_storage_days,
                                I_item_attr_rec.tsl_diamond_line_ind,
                                I_item_attr_rec.tsl_sell_by_type,
                                I_item_attr_rec.tsl_drained_ind,
                                -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - Begin --
                                -- Removing the reference to the column tsl_unit_qty which is being dropped
                                -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - End --
                                -- 29-May-2008 Wipro Enabler/Bahubali Dongare - Mod:N111 - Begin
                                --I_item_attr_rec.tsl_common_product_ind,
                                --I_item_attr_rec.tsl_primary_country_ind,
                                -- 29-May-2008 Wipro Enabler/Bahubali Dongare - Mod:N111 - End
                                --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    Begin
                                --I_item_attr_rec.tsl_consumer_unit,
                                --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    End
                                I_item_attr_rec.tsl_country_of_origin,
                                I_item_attr_rec.tsl_supp_country,
                                I_item_attr_rec.tsl_brand_ind,
                                I_item_attr_rec.tsl_brand,
                                I_item_attr_rec.tsl_sell_by_100g_ind,
                                I_item_attr_rec.tsl_package_type,
                                -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - Begin --
                                -- Removing the reference to the column I_item_attr_rec.tsl_mu_ind which is being dropped
                                -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - End --
                                I_item_attr_rec.tsl_case_type,
                                --10-Dec-2010 Tesco HSC/Vivek Sharma    Defect#:NBS00020107 Begin
                                trim(I_item_attr_rec.tsl_tarif_code),
                                --10-Dec-2010 Tesco HSC/Vivek Sharma    Defect#:NBS00020107 Begin
                                I_item_attr_rec.tsl_supp_unit,
                                I_item_attr_rec.tsl_process_type,
                                I_item_attr_rec.tsl_event,
                                I_item_attr_rec.tsl_supp_non_del_days_mon_ind,
                                I_item_attr_rec.tsl_supp_non_del_days_tue_ind,
                                I_item_attr_rec.tsl_supp_non_del_days_wed_ind,
                                I_item_attr_rec.tsl_supp_non_del_days_thu_ind,
                                I_item_attr_rec.tsl_supp_non_del_days_fri_ind,
                                I_item_attr_rec.tsl_supp_non_del_days_sat_ind,
                                I_item_attr_rec.tsl_supp_non_del_days_sun_ind,
                                I_item_attr_rec.tsl_case_per_pack,
                                I_item_attr_rec.tsl_high_value_ind,
                                I_item_attr_rec.tsl_epw_ind,
                                --09-Oct-2007     TESCO HSC/Nandini Mariyappa        Mod:N20a    Begin
                                --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    Begin
                                --I_item_attr_rec.tsl_consumer_unit_b,
                                --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    End
                                --26-Oct-2007 Tesco HSC/Vinod                    Mod:N111    Begin
                                NVL(I_item_attr_rec.tsl_weee_ind,'N'),
                                --26-Oct-2007 Tesco HSC/Vinod                    Mod:N111    End
                                --27-Mar-2008     Tesco HSC/Usha Patil           Mod:N126 Begin
                                --I_item_attr_rec.tsl_deact_req_date,
                                --27-Mar-2008     Tesco HSC/Usha Patil           Mod:N126 End
                                --09-Oct-2007     TESCO HSC/Nandini Mariyappa        Mod:N20a    End
                                --26-Oct-2007 Tesco HSC/Vinod         Defect#:NBS00003704 Begin
                                to_date(I_item_attr_rec.tsl_launch_date),
                                --8-May-2008     TESCO HSC/Rahul Soni               Mod:N138/CR115    Begin
                                I_item_attr_rec.tsl_local_sourced,
                                --8-May-2008     TESCO HSC/Rahul Soni               Mod:N138/CR115    End
                                --18-Jly-2008     Tesco HSC/Usha Patil               Mod:N144    Begin
                                I_item_attr_rec.tsl_pwdtu_ind,
                                --18-Jly-2008     Tesco HSC/Usha Patil               Mod:N144    End
                                --26-Oct-2007 Tesco HSC/Vinod         Defect#:NBS00003704 End
                                --26-Jun-2008   TESCO HSC Vijaya Bhaskar/Wipro-Enabler   Mod:N155   Begin
                                I_item_attr_rec.tsl_dev_line_ind,
                                to_date(I_item_attr_rec.tsl_dev_end_date),
                                I_item_attr_rec.tsl_base_label_size_ind,
                                I_item_attr_rec.tsl_pos_codes,
                                --26-Jun-2008   TESCO HSC Vijaya Bhaskar/Wipro-Enabler   Mod:N155   End
                                -- CR187, 27-Nov-2008, Nitin Kumar, nitin.kumar@in.tesco.com Begin
                                I_item_attr_rec.tsl_low_lvl_code,
                                -- 10-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016142    Begin
                                -- As part of this defect we have removed the column tsl_low_lvl_code_desc from
                                -- item_attributes table.
                                --I_item_attr_rec.tsl_low_lvl_code_desc,
                                -- 10-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016142    End
                                I_item_attr_rec.tsl_low_lvl_seq_no,
                                -- CR187, 27-Nov-2008, Nitin Kumar, nitin.kumar@in.tesco.com End
                                --18-Aug-2009   TESCO HSC/Joy Stephen   CR236   Begin
                                I_item_attr_rec.tsl_country_id,
                                --18-Aug-2009   TESCO HSC/Joy Stephen   CR236   End
                                --02-Aug-2011   TESCO HSC/Ankush   CR432   Begin
                                I_item_attr_rec.tsl_multipack_qty);
                                --02-Aug-2011   TESCO HSC/Ankush   CR432   End

   /*DefNBS019847a , 23-Nov-2010 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
   -- DefNBS019847 , 23-Nov-2010 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com Begin
   if ITEM_ATTRIB_DEFAULT_SQL.TSL_COPY_UK_ITEM_ATTRIB (O_error_message,
                                                       I_item_attr_rec.item,
                                                       I_item_attr_rec.tsl_country_id) = FALSE then
      return FALSE;
   end if;
   -- DefNBS019847 , 23-Nov-2010 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
   */--DefNBS019847a , 23-Nov-2010 ,Yashavantharaja M.T ,yashavantharaja.thimmesh@in.tesco.com End
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END INSERT_ATTRIBUTES;
-------------------------------------------------------------------------------------------------------
FUNCTION MODIFY_ATTRIBUTES(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           I_item_attr_rec IN ITEM_ATTRIBUTES%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_ATTR_INS_UPD.MODIFY_ITEM_ATTRIBUTES';
   L_table        VARCHAR2(30);
   L_item         ITEM_ATTRIBUTES.ITEM%TYPE;
   --- Following cursor will be called to lock the item for which
   --- item attributes will be updated
   cursor C_LOCK_ITEM_ATTR is
      select 'x'
        from item_attributes
       where item = I_item_attr_rec.item
         for update nowait;

BEGIN
  L_item  := I_item_attr_rec.item;
  L_table := 'ITEM_ATTRIBUTES';

  SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_ATTR','ITEM_ATTRIBUTES','Item: '||L_item);
  open C_LOCK_ITEM_ATTR;

  SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_ATTR','ITEM_ATTRIBUTES','Item: '||L_item);
  close C_LOCK_ITEM_ATTR;

   update item_attributes
   --23-Sep-2009 Srinivasa Janga defect# NBS00014852 begin
      set tsl_in_store_shelf_life_ind   = NVL(I_item_attr_rec.tsl_in_store_shelf_life_ind,tsl_in_store_shelf_life_ind),
          tsl_daily_shelf_life_mon      = NVL(I_item_attr_rec.tsl_daily_shelf_life_mon,tsl_daily_shelf_life_mon),
          tsl_daily_shelf_life_tue      = NVL(I_item_attr_rec.tsl_daily_shelf_life_tue,tsl_daily_shelf_life_tue),
          tsl_daily_shelf_life_wed      = NVL(I_item_attr_rec.tsl_daily_shelf_life_wed,tsl_daily_shelf_life_wed),
          tsl_daily_shelf_life_thu      = NVL(I_item_attr_rec.tsl_daily_shelf_life_thu,tsl_daily_shelf_life_thu),
          tsl_daily_shelf_life_fri      = NVL(I_item_attr_rec.tsl_daily_shelf_life_fri,tsl_daily_shelf_life_fri),
          tsl_daily_shelf_life_sat      = NVL(I_item_attr_rec.tsl_daily_shelf_life_sat,tsl_daily_shelf_life_sat),
          tsl_daily_shelf_life_sun      = NVL(I_item_attr_rec.tsl_daily_shelf_life_sun,tsl_daily_shelf_life_sun),
          tsl_in_store_shelf_life_days  = NVL(I_item_attr_rec.tsl_in_store_shelf_life_days,tsl_in_store_shelf_life_days),
          tsl_min_life_depot_days       = NVL(I_item_attr_rec.tsl_min_life_depot_days,tsl_min_life_depot_days),
          -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - Begin --
          -- Removing the reference to the column tsl_multipack_qty which is being dropped
          -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - End --
          tsl_min_cus_storage_days      = NVL(I_item_attr_rec.tsl_min_cus_storage_days,tsl_min_cus_storage_days),
          tsl_diamond_line_ind          = NVL(I_item_attr_rec.tsl_diamond_line_ind,tsl_diamond_line_ind),
          tsl_sell_by_type              = NVL(I_item_attr_rec.tsl_sell_by_type,tsl_sell_by_type),
          tsl_drained_ind               = NVL(I_item_attr_rec.tsl_drained_ind,tsl_drained_ind),
          -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - Begin --
          -- Removing the reference to the column tsl_unit_qty which is being dropped
          -- 06-Feb-2008 Wipro Enabler/Dhuraison Prince - Mod:N114 - End --
          -- 29-May-2008 Wipro Enabler/Bahubali Dongare - Mod:N111 - Begin
          --tsl_common_product_ind        = I_item_attr_rec.tsl_common_product_ind,
          --tsl_primary_country_ind       = I_item_attr_rec.tsl_primary_country_ind,
          -- 29-May-2008 Wipro Enabler/Bahubali Dongare - Mod:N111 - End
      --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    Begin
          --tsl_consumer_unit             = I_item_attr_rec.tsl_consumer_unit,
      --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    End
          tsl_country_of_origin         = NVL(I_item_attr_rec.tsl_country_of_origin,tsl_country_of_origin),
          tsl_supp_country              = NVL(I_item_attr_rec.tsl_supp_country,tsl_supp_country),
          tsl_brand_ind                 = NVL(I_item_attr_rec.tsl_brand_ind,tsl_brand_ind),
          tsl_brand                     = NVL(I_item_attr_rec.tsl_brand,tsl_brand),
          tsl_sell_by_100g_ind          = NVL(I_item_attr_rec.tsl_sell_by_100g_ind,tsl_sell_by_100g_ind),
          tsl_package_type              = NVL(I_item_attr_rec.tsl_package_type,tsl_package_type),
          -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - Begin --
          -- Removing the reference to the column tsl_mu_ind = I_item_attr_rec.tsl_mu_ind which is being dropped
          -- 27-Mar-2008 Wipro Enabler/Sundara Rajan - Mod:N53 - End --
          tsl_case_type                 = NVL(I_item_attr_rec.tsl_case_type,tsl_case_type),
          --10-Dec-2010 Tesco HSC/Vivek Sharma    Defect#:NBS00020107 Begin
          tsl_tarif_code                = trim(NVL(I_item_attr_rec.tsl_tarif_code,tsl_tarif_code)),
          --10-Dec-2010 Tesco HSC/Vivek Sharma    Defect#:NBS00020107 End
          tsl_supp_unit                 = NVL(I_item_attr_rec.tsl_supp_unit,tsl_supp_unit),
          tsl_process_type              = NVL(I_item_attr_rec.tsl_process_type,tsl_process_type),
          tsl_event                     = NVL(I_item_attr_rec.tsl_event,tsl_event),
          tsl_supp_non_del_days_mon_ind = NVL(I_item_attr_rec.tsl_supp_non_del_days_mon_ind,tsl_supp_non_del_days_mon_ind),
          tsl_supp_non_del_days_tue_ind = NVL(I_item_attr_rec.tsl_supp_non_del_days_tue_ind,tsl_supp_non_del_days_tue_ind),
          tsl_supp_non_del_days_wed_ind = NVL(I_item_attr_rec.tsl_supp_non_del_days_wed_ind,tsl_supp_non_del_days_wed_ind),
          tsl_supp_non_del_days_thu_ind = NVL(I_item_attr_rec.tsl_supp_non_del_days_thu_ind,tsl_supp_non_del_days_thu_ind),
          tsl_supp_non_del_days_fri_ind = NVL(I_item_attr_rec.tsl_supp_non_del_days_fri_ind,tsl_supp_non_del_days_fri_ind),
          tsl_supp_non_del_days_sat_ind = NVL(I_item_attr_rec.tsl_supp_non_del_days_sat_ind,tsl_supp_non_del_days_sat_ind),
          tsl_supp_non_del_days_sun_ind = NVL(I_item_attr_rec.tsl_supp_non_del_days_sun_ind,tsl_supp_non_del_days_sun_ind),
          tsl_case_per_pack             = NVL(I_item_attr_rec.tsl_case_per_pack,tsl_case_per_pack),
          tsl_high_value_ind            = NVL(I_item_attr_rec.tsl_high_value_ind,tsl_high_value_ind),
          tsl_epw_ind                   = NVL(I_item_attr_rec.tsl_epw_ind,tsl_epw_ind),
  --09-Oct-2007     TESCO HSC/Nandini Mariyappa        Mod:N20a    Begin
  --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    Begin
        --tsl_consumer_unit_b           = I_item_attr_rec.tsl_consumer_unit_b,
  --22-Nov-2007     TESCO HSC/Nandini Mariyappa    Mod:N105    End
  --27-Jan-2009 Tesco HSC/Nandini Mariyappa         Defect#:NBS00011128   Begin
          tsl_weee_ind                  = NVL(I_item_attr_rec.tsl_weee_ind,'N'),
  --27-Jan-2009 Tesco HSC/Nandini Mariyappa         Defect#:NBS00011128   End
  --27-Mar-2008     Tesco HSC/Usha Patil           Mod:N126 Begin
        --tsl_deact_req_date            = NVL(I_item_attr_rec.tsl_deact_req_date,
  --27-Mar-2008     Tesco HSC/Usha Patil           Mod:N126 End
  --09-Oct-2007     TESCO HSC/Nandini Mariyappa        Mod:N20a    End
   --26-Oct-2007 Tesco HSC/Vinod         Defect#:NBS00003704 Begin
          tsl_launch_date               = NVL(to_date(I_item_attr_rec.tsl_launch_date),tsl_launch_date),
   --8-May-2008     TESCO HSC/Rahul Soni               Mod:N138/CR115    Begin
          tsl_local_sourced             = NVL(I_item_attr_rec.tsl_local_sourced,tsl_local_sourced),
   --8-May-2008     TESCO HSC/Rahul Soni               Mod:N138/CR115    End
   --18-Jly-2008     Tesco hsc/Usha Patil               Mod:N144    Begin
          tsl_pwdtu_ind             = NVL(I_item_attr_rec.tsl_pwdtu_ind,tsl_pwdtu_ind),
   --18-Jly-2008     Tesco hsc/Usha Patil               Mod:N144    End
   --26-Oct-2007 Tesco HSC/Vinod         Defect#:NBS00003704 End
   --26-Jun-2008   TESCO HSC Vijaya Bhaskar/Wipro-Enabler   Mod:N155   Begin
          tsl_dev_line_ind              = NVL(I_item_attr_rec.tsl_dev_line_ind,tsl_dev_line_ind),
          tsl_dev_end_date              = NVL(to_date(I_item_attr_rec.tsl_dev_end_date),tsl_dev_end_date),
          tsl_base_label_size_ind       = NVL(I_item_attr_rec.tsl_base_label_size_ind,tsl_base_label_size_ind),
          tsl_pos_codes                 = NVL(I_item_attr_rec.tsl_pos_codes,tsl_pos_codes),
   --26-Jun-2008   TESCO HSC Vijaya Bhaskar/Wipro-Enabler   Mod:N155   End
   -- CR187, 27-Nov-2008, Nitin Kumar, nitin.kumar@in.tesco.com Begin
          tsl_low_lvl_code              = NVL(I_item_attr_rec.tsl_low_lvl_code,tsl_low_lvl_code),
          -- 10-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016142    Begin
          -- As part of this defect we have removed the column tsl_low_lvl_code_desc from
          -- item_attributes table.
          --tsl_low_lvl_code_desc         = NVL(I_item_attr_rec.tsl_low_lvl_code_desc,tsl_low_lvl_code_desc),
          -- 10-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016142    End
          tsl_low_lvl_seq_no            = NVL(I_item_attr_rec.tsl_low_lvl_seq_no,tsl_low_lvl_seq_no),
   -- CR187, 27-Nov-2008, Nitin Kumar, nitin.kumar@in.tesco.com End
   --23-Sep-2009 Srinivasa Janga defect# NBS00014852 end.
   --02-Aug-2011   TESCO HSC/Ankush   CR432   Begin
          tsl_multipack_qty             = NVL(I_item_attr_rec.tsl_multipack_qty,tsl_multipack_qty)
   --02-Aug-2011   TESCO HSC/Ankush   CR432   End
   where item = L_item
     --18-Aug-2009   TESCO HSC/Joy Stephen   CR236   Begin
     and tsl_country_id = I_item_attr_rec.tsl_country_id;
     --18-Aug-2009   TESCO HSC/Joy Stephen   CR236   End

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END MODIFY_ATTRIBUTES;
-------------------------------------------------------------------------------------------------------
END ITEM_ATTR_INS_UPD;
/

