CREATE OR REPLACE PACKAGE BODY ITEM_EXPENSE_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Ramasamy
--Mod Date:    05-Jul-2007
--Mod Ref:     Mod number. 365b
--Mod Details: Amended script to explodes the base varient item information.
------------------------------------------------------------------------------------------------
--Mod By     : Nitin Gour, nitin.gour@in.tesco.com
--Mod Date   : 29-Jan-2008
--Mod Ref    : 364.2
--Mod Details: Added function TSL_BASE_EXP_DISCHRG_PORT to retrieve the Discharge Port
--           : Added function TSL_GET_TNETT_COST to calculate Nett Cost
-- Mod By:      Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date:    28-Feb-2008
-- Mod Ref:     N53
-- Mod Details: New function TSL_DELETE_EXPENSE added.This function will deleted the information
--              related to the passed item, from the ITEM_EXP_HEAD, ITEM_EXP_DETAIL,
--              TSL_ITEM_EXP_HEAD and TSL_ITEM_EXP_DETAIL tables
------------------------------------------------------------------------------------------------
--Mod By     : Murali N, murali.natarajan@in.tesco.com
--Mod Date   : 24-Jun-2010
--Mod Ref    : NBS00017368
--Mod Details: Modified function TSL_BASE_EXP_DISCHRG_PORT to get discharge port based on cost zone.
---------------------------------------------------------------------------------------------
--Mod By     : Vivek Sharma, Vivek.Sharma@in.tesco.com
--Mod Date   : 07-Oct-10
--Mod Ref    : CR 339
--Mod Details: A new function which will be used to fetch discharge port, supplier currency indicator
--             and tolerance percent values from the table TSL_EXPENSE_DEFAULT.
---------------------------------------------------------------------------------------------
--Mod By     : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
--Mod Date   : 07-Oct-10
--Mod Ref    : CR 339
--Mod Details: New functions TSL_GET_EXP_HEAD_DATES, TSL_GET_EXP_DETL_FIELDS and TSL_UPD_ITEM_EXP_DETL
--             added to populate new columns in item expense screen
---------------------------------------------------------------------------------------------
--Mod By     : Chandru, chandrashekaran.natarajan@in.tesco.com
--Mod Date   : 10-Dec-10
--Mod Ref    : CR 338
--Mod Details: New functions TSL_INS_EXP_HEAD_TEMP, TSL_INS_EXP_DETAIL_TEMP and TSL_CASCADE_EXP_ALL_TPND
--             added to implement CR338 - expenses cascading functionality
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--Mod By     : Accenture/Kushal Kumar, kushalkumar.nakka@in.tesco.com
--Mod Date   : 24-Nov-10
--Mod Ref    : CR 332
--Mod Details: New functions TSL_GET_ITEMs_TO_UPDATE, TSL_INS_EXPENSE_HDR, TSL_INS_EXPENSE_TSLHDR,
--             TSL_INS_EXPENSE_DTL, TSL_INS_EXPENSE_TSLDTL
--             added to explode expenses to simple packs
---------------------------------------------------------------------------------------------
--Mod By     : Accenture/Sriram Gopal Krishnan, Sriram.Gopalkrishnan@in.tesco.com
--Mod Date   : 03-Dec-2010
--Mod Ref    : NBS00019971
--Mod Details: Modified function TSL_GET_ITEMS_TO_UPDATE to initilize collection to NULL
--             if no condition is satisfied
---------------------------------------------------------------------------------------------
--Mod By     : Chandrachooda H, Praveen R
--Mod Date   : 17-Dec-2010
--Mod Ref    : CR332
--Mod Details: Added new functions TSL_GET_WRKST_ITEMS, TSL_STYL_REF_ITEMS_UPDATE,
--             TSL_CHK_WRKST_ITEMS and TSL_STYL_REF_EXP_HDR
---------------------------------------------------------------------------------------------
-- Mod By     : Nandini M, nandini.mariyappa@in.tesco.com
-- Mod Date   : 11-Jan-2011
-- Mod Ref    : MrgNBS020482
-- Mod Details: Merge from 3.5h to 3.5b branches
---------------------------------------------------------------------------------------------
-- MrgNBS022379 21-Apr-2011 Veena Nanjundaiah veena.nanjundaiah@in.tesco.com Begin
--Mod By     : Murali N, murali.natarajan@in.tesco.com
--Mod Date   : 24-Mar-2011
--Mod Ref    : NBS00021683
--Mod Details: Modified function TSL_CASCADE_EXP_ALL_TPND to cal real_time_cost and to insert
--             into expense queue for each item.
---------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 03-Jun-2011
-- Mod Ref    : MrgNBS022853
-- Mod Details: Merge from Prd Si to 3.5b Merged 22498 defect
---------------------------------------------------------------------------------------------
-- MrgNBS022379 21-Apr-2011 Veena Nanjundaiah veena.nanjundaiah@in.tesco.com End
---------------------------------------------------------------------------------------------
-- Mod By     : Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com
-- Mod Date   : 06-Jul-2011
-- Mod Ref    : DefNBS023177
-- Mod Details: Modified cursor in TSL_BASE_EXP_DISCHRG_PORT function to ensure retrieval of
--            : single expense record.
---------------------------------------------------------------------------------------------
-- Mod By     : Vinutha Raju, vinutha.raju@in.tesco.com
-- Mod Date   : 23-Jan-2012
-- Mod Ref    : DefNBS024190
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Mod By     : Muthukumar, muthukumar.sathiyaseelan@in.tesco.com
-- Mod Date   : 10-Jul-2012
-- Mod Ref    : DefNBS025201
-- Mod Details: Modified Delete statement for delete only the particular item supplier combination.
---------------------------------------------------------------------------------------------- Mod By     : Sangamithra N , Sangamithra.Nagarajan@in.tesco.com
-- Mod Date   : 18-Feb-2014
-- Mod Ref    : DefNBS026825
-- Mod Details: Added two new functions TSL_INSERT_EXPENSES_HEAD and TSL_DELETE_EXPENSES_DETAIL
--------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 16-May-2014
-- Mod Ref    : CR518
-- Mod Details: Added new function TSL_EXCISE_COMP_EXISTS to check if the excise component
--exists for an item - supplier.
---------------------------------------------------------------------------------------------
FUNCTION GET_NEXT_SEQ(O_error_message IN OUT  VARCHAR2,
                      O_seq_no        IN OUT  ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE,
                      I_item          IN      ITEM_MASTER.ITEM%TYPE,
                      I_supplier      IN      SUPS.SUPPLIER%TYPE,
                      I_item_exp_type IN      ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE)
   return BOOLEAN is

      cursor C_MAX_SEQ is
         select nvl(max(item_exp_seq),0) + 1
           from item_exp_head
          where item          = I_item
            and supplier      = I_supplier
            and item_exp_type = I_item_exp_type;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_MAX_SEQ', 'ITEM_EXP_HEAD', NULL);
   open C_MAX_SEQ;
   SQL_LIB.SET_MARK('FETCH', 'C_MAX_SEQ', 'ITEM_EXP_HEAD', NULL);
   fetch C_MAX_SEQ into O_seq_no;
   SQL_LIB.SET_MARK('CLOSE', 'C_MAX_SEQ', 'ITEM_EXP_HEAD', NULL);
   close C_MAX_SEQ;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_EXPENSE_SQL.GET_NEXT_SEQ',
                                             to_char(SQLCODE));
   return FALSE;
END GET_NEXT_SEQ;
---------------------------------------------------------------------------------------------
FUNCTION BASE_EXP_CHANGED (O_error_message       IN OUT  VARCHAR2,
                           I_item                IN      ITEM_MASTER.ITEM%TYPE,
                           I_supplier            IN      SUPS.SUPPLIER%TYPE,
                           I_item_exp_type       IN      ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                           I_item_exp_seq        IN      ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE,
                           I_base_exp_ind        IN      ITEM_EXP_HEAD.BASE_EXP_IND%TYPE,
                           I_origin_country_id   IN      ITEM_EXP_HEAD.ORIGIN_COUNTRY_ID%TYPE)
   return BOOLEAN is
      L_table        VARCHAR2(30);
      RECORD_LOCKED  EXCEPTION;
      PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

      cursor C_LOCK_TYPE is
         select 'X'
           from item_exp_head
          where item              = I_item
            and supplier          = I_supplier
            and item_exp_type     = I_item_exp_type
            and (I_origin_country_id is NULL or
                 origin_country_id = I_origin_country_id)
            for update nowait;

BEGIN
   L_table            := 'ITEM_EXP_HEAD';
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_TYPE', 'ITEM_EXP_HEAD', NULL);
   open C_LOCK_TYPE;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_TYPE', 'ITEM_EXP_HEAD', NULL);
   close C_LOCK_TYPE;

   SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_EXP_HEAD', NULL);
   update item_exp_head
      set base_exp_ind         = 'N',
          last_update_datetime = sysdate,
          last_update_id       = SYS_CONTEXT('USERENV', 'SESSION_USER')
    where item                 = I_item
      and supplier             = I_supplier
      and item_exp_type        = I_item_exp_type
      and (I_origin_country_id is NULL or
           origin_country_id = I_origin_country_id);

   if I_base_exp_ind    = 'Y' then
   SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_EXP_HEAD', NULL);
      update item_exp_head
         set base_exp_ind         = 'Y',
             last_update_datetime = sysdate,
             last_update_id       = SYS_CONTEXT('USERENV', 'SESSION_USER')
       where item                 = I_item
         and supplier             = I_supplier
         and item_exp_type        = I_item_exp_type
         and item_exp_seq         = I_item_exp_seq
         and (I_origin_country_id is NULL or
              origin_country_id = I_origin_country_id);
   end if;

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             I_item,
                                             to_char(I_supplier));

      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_EXPENSE_SQL.BASE_EXP_CHANGED',
                                             to_char(SQLCODE));
   return FALSE;

END BASE_EXP_CHANGED;
---------------------------------------------------------------------------------------------
FUNCTION EXP_HEAD_EXIST(O_error_message     IN OUT  VARCHAR2,
                        O_exists            IN OUT  BOOLEAN,
                        I_item_exp_type     IN	    ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                        I_item              IN      ITEM_MASTER.ITEM%TYPE,
                        I_supplier          IN      SUPS.SUPPLIER%TYPE,
                        I_zone_id           IN      COST_ZONE.ZONE_ID%TYPE,
                        I_zone_group_id     IN      COST_ZONE.ZONE_GROUP_ID%TYPE,
                        I_origin_country_id IN      COUNTRY.COUNTRY_ID%TYPE,
                        I_lading_port       IN      OUTLOC.OUTLOC_ID%TYPE,
                        I_discharge_port    IN      OUTLOC.OUTLOC_ID%TYPE)
   return BOOLEAN is
      L_exists      VARCHAR2(1);

      cursor C_COUNTRY_EXISTS is
         select 'Y'
           from item_exp_head
          where item              = I_item
            and supplier          = I_supplier
            and item_exp_type     = 'C'
            and origin_country_id = I_origin_country_id
            and lading_port       = I_lading_port
            and discharge_port    = I_discharge_port;

      cursor C_ZONE_EXISTS is
         select 'Y'
           from item_exp_head
          where item              = I_item
            and supplier          = I_supplier
            and item_exp_type     = 'Z'
            and zone_group_id     = I_zone_group_id
            and zone_id           = I_zone_id
            and discharge_port    = I_discharge_port;


BEGIN
   O_exists := FALSE;
   if I_item_exp_type = 'C' then
      SQL_LIB.SET_MARK('OPEN', 'C_COUNTRY_EXISTS', 'ITEM_EXP_HEAD', NULL);
      open C_COUNTRY_EXISTS;
      SQL_LIB.SET_MARK('FETCH', 'C_COUNTRY_EXISTS', 'ITEM_EXP_HEAD', NULL);
      fetch C_COUNTRY_EXISTS into L_exists;

      if C_COUNTRY_EXISTS%FOUND then
         O_error_message := SQL_LIB.CREATE_MSG('DUP_ITEM_EXP_HEAD',NULL,NULL,NULL);
         O_exists        := TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_COUNTRY_EXISTS', 'ITEM_EXP_HEAD', NULL);
      close C_COUNTRY_EXISTS;

   elsif I_item_exp_type = 'Z' then
      SQL_LIB.SET_MARK('OPEN', 'C_ZONE_EXISTS', 'ITEM_EXP_HEAD', NULL);
      open C_ZONE_EXISTS;
      SQL_LIB.SET_MARK('FETCH', 'C_ZONE_EXISTS', 'ITEM_EXP_HEAD', NULL);
      fetch C_ZONE_EXISTS into L_exists;

      if C_ZONE_EXISTS%FOUND then
         O_error_message := SQL_LIB.CREATE_MSG('DUP_ITEM_EXP_ZONE',NULL,NULL,NULL);
         O_exists        := TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_ZONE_EXISTS', 'ITEM_EXP_HEAD', NULL);
      close C_ZONE_EXISTS;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_EXPENSE_SQL.EXP_HEAD_EXIST',
                                             to_char(SQLCODE));
   return FALSE;

END EXP_HEAD_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION EXP_DETAILS_EXIST(O_error_message     IN OUT  VARCHAR2,
                           O_exists            IN OUT  BOOLEAN,
                           I_item              IN      ITEM_MASTER.ITEM%TYPE,
                           I_supplier          IN      SUPS.SUPPLIER%TYPE,
                           I_item_exp_type     IN      ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                           I_item_exp_seq      IN      ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE,
                           I_comp_id           IN      ELC_COMP.COMP_ID%TYPE)
   return BOOLEAN is
      L_exists    VARCHAR2(1);

      cursor C_DETAIL_EXIST is
         select 'Y'
           from item_exp_detail
          where item            = I_item
            and supplier        = I_supplier
            and item_exp_type   = I_item_exp_type
            and item_exp_seq    = I_item_exp_seq
            and comp_id         = I_comp_id;
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_DETAIL_EXIST', 'ITEM_EXP_HEAD', NULL);
   open C_DETAIL_EXIST;
   SQL_LIB.SET_MARK('FETCH', 'C_DETAIL_EXIST', 'ITEM_EXP_HEAD', NULL);
   fetch C_DETAIL_EXIST into L_exists;
   if C_DETAIL_EXIST%FOUND then
      O_error_message := SQL_LIB.CREATE_MSG('DUP_ITEM_EXP_DETAIL',NULL,NULL,NULL);
      O_exists        := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_DETAIL_EXIST', 'ITEM_EXP_HEAD', NULL);
   close C_DETAIL_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_EXPENSE_SQL.EXP_DETAILS_EXIST',
                                             to_char(SQLCODE));
   return FALSE;

END EXP_DETAILS_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION LOCK_EXP_DETAILS(O_error_message    IN OUT  VARCHAR2,
                          I_item              IN      ITEM_MASTER.ITEM%TYPE,
                          I_supplier          IN      SUPS.SUPPLIER%TYPE,
                          I_item_exp_type     IN      ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                          I_item_exp_seq      IN      ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE)
   return BOOLEAN is

      L_table        VARCHAR2(30);
      RECORD_LOCKED  EXCEPTION;
      PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

      cursor C_LOCK_ITEM_DETAIL is
         select 'X'
           from item_exp_detail
          where item           = I_item
            and supplier       = I_supplier
            and item_exp_type  = I_item_exp_type
            and item_exp_seq   = I_item_exp_seq
            for update nowait;

BEGIN
   L_table := 'ITEM_EXP_DETAIL';
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_DETAIL', 'ITEM_EXP_DETAIL', NULL);
   open C_LOCK_ITEM_DETAIL;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_DETAIL', 'ITEM_EXP_DETAIL', NULL);
   close C_LOCK_ITEM_DETAIL;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             I_item,
                                             to_char(I_supplier));

      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_EXPENSE_SQL.LOCK_EXP_DETAILS',
                                             to_char(SQLCODE));
      return FALSE;
END LOCK_EXP_DETAILS;

---------------------------------------------------------------------------------------------
FUNCTION DEL_EXP_DETAILS(O_error_message     IN OUT  VARCHAR2,
                         I_item              IN      ITEM_MASTER.ITEM%TYPE,
                         I_supplier          IN      SUPS.SUPPLIER%TYPE,
                         I_item_exp_type     IN      ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                         I_item_exp_seq      IN      ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE)
   return BOOLEAN is

BEGIN
   SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_EXP_DETAIL', NULL);
   delete from item_exp_detail
          where item           = I_item
            and supplier       = I_supplier
            and item_exp_type  = I_item_exp_type
            and item_exp_seq   = I_item_exp_seq;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_EXPENSE_SQL.DEL_EXP_DETAILS',
                                             to_char(SQLCODE));
   return FALSE;
END DEL_EXP_DETAILS;
---------------------------------------------------------------------------------------------
FUNCTION CHECK_HEADER_NO_DETAILS(O_error_message     IN OUT  VARCHAR2,
                                 O_exists            IN OUT  BOOLEAN,
                                 I_item              IN      ITEM_MASTER.ITEM%TYPE,
                                 I_supplier          IN      SUPS.SUPPLIER%TYPE,
                                 I_item_exp_type     IN      ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE)
   return BOOLEAN is

      L_exists      VARCHAR2(1);

      cursor C_CHECK_FOR_DETAILS is
         select 'X'
           from item_exp_head ih
          where ih.item            = I_item
            and ih.supplier        = I_supplier
            and ih.item_exp_type   = I_item_exp_type
            and ih.item_exp_seq not in
                  (select id.item_exp_seq
                     from item_exp_detail id
                    where id.item            = I_item
                      and id.supplier        = I_supplier
                      and id.item_exp_type   = I_item_exp_type);

BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_CHECK FOR_DETAILS', 'ITEM_EXP_HEAD, ITEM_EXP_DETAIL', NULL);
   open C_CHECK_FOR_DETAILS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK FOR_DETAILS', 'ITEM_EXP_HEAD, ITEM_EXP_DETAIL', NULL);
   fetch C_CHECK_FOR_DETAILS into L_exists;

   if C_CHECK_FOR_DETAILS%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK FOR_DETAILS', 'ITEM_EXP_HEAD', NULL);
   close C_CHECK_FOR_DETAILS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_EXPENSE_SQL.CHECK_HEADER_NO_DETAILS',
                                             to_char(SQLCODE));
   return FALSE;

END CHECK_HEADER_NO_DETAILS;
---------------------------------------------------------------------------------------------
FUNCTION DELETE_HEADER(O_error_message     IN OUT  VARCHAR2,
                       I_item              IN      ITEM_MASTER.ITEM%TYPE,
                       I_supplier          IN      SUPS.SUPPLIER%TYPE,
                       I_item_exp_type     IN      ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE)
   return BOOLEAN is

      L_table        VARCHAR2(30);
      RECORD_LOCKED  EXCEPTION;
      PRAGMA         EXCEPTION_INIT(Record_Locked, -54);


      cursor C_LOCK_ITEM_HEAD is
         select 'X'
           from item_exp_head ih
          where ih.item            = I_item
            and ih.supplier        = I_supplier
            and ih.item_exp_type   = I_item_exp_type
            and ih.item_exp_seq not in
                  (select id.item_exp_seq
                     from item_exp_detail id
                    where id.item            = I_item
                      and id.supplier        = I_supplier
                      and id.item_exp_type   = I_item_exp_type)
            for update nowait;

BEGIN
   L_table := 'ITEM_EXP_HEAD';
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_HEAD', 'ITEM_EXP_HEAD, ITEM_EXP_DETAIL', NULL);
   open C_LOCK_ITEM_HEAD;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_HEAD', 'ITEM_EXP_HEAD, ITEM_EXP_DETAIL', NULL);
   close C_LOCK_ITEM_HEAD;

   SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_EXP_HEAD, ITEM_EXP_DETAIL', NULL);
   delete from item_exp_head ih
          where ih.item            = I_item
            and ih.supplier        = I_supplier
            and ih.item_exp_type   = I_item_exp_type
            and ih.item_exp_seq not in
                  (select id.item_exp_seq
                     from item_exp_detail id
                    where id.item            = I_item
                      and id.supplier        = I_supplier
                      and id.item_exp_type   = I_item_exp_type);

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             I_item,
                                             to_char(I_supplier));

      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_EXPENSE_SQL.DELETE_HEADER',
                                             to_char(SQLCODE));
   return FALSE;

END DELETE_HEADER;
------------------------------------------------------------------------------------------------
FUNCTION DEFAULT_EXPENSES(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          I_item              IN     ITEM_MASTER.ITEM%TYPE,
                          I_supplier          IN     SUPS.SUPPLIER%TYPE,
                          I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(40)   := 'ITEM_EXPENSE_SQL.DEFAULT_EXPENSES';
   L_zone_group_id      COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE := NULL;


BEGIN
   if DEFAULT_EXPENSES(O_error_message,
                       I_item,
                       I_supplier,
                       I_origin_country_id,
                       L_zone_group_id)= FALSE  then
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

END DEFAULT_EXPENSES;
------------------------------------------------------------------------------------------------
FUNCTION DEFAULT_EXPENSES(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          I_item              IN     ITEM_MASTER.ITEM%TYPE,
                          I_supplier          IN     SUPS.SUPPLIER%TYPE,
                          I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                          I_cost_zone_group   IN     ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(40)   := 'ITEM_EXPENSE_SQL.DEFAULT_EXPENSES';
   L_records_inserted   VARCHAR2(1)    := 'N';
   L_zone_group_id      COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE;
   L_exp_type           ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE;
   L_module             EXP_PROF_HEAD.MODULE%TYPE := 'SUPP';
   L_seq_no             ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE;

   cursor C_SEQ_NO is
      select nvl(max(item_exp_seq), 0) + 1
        from item_exp_head
       where item          = I_item
         and supplier      = I_supplier
         and item_exp_type = L_exp_type;

   cursor C_ZONES is
      select zone_id
        from cost_zone
       where zone_group_id = L_zone_group_id;

BEGIN
   if I_origin_country_id is NULL then
      L_exp_type := 'Z';
   else
      L_exp_type := 'C';
   end if;
   ---
   if L_exp_type = 'Z' then
      if I_cost_zone_group is null then
      if ITEM_ATTRIB_SQL.GET_COST_ZONE_GROUP(O_error_message,
                                             L_zone_group_id,
                                             I_item) = FALSE then
         return FALSE;
      end if;
      else
         L_zone_group_id  :=I_cost_zone_group;
      end if;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_SEQ_NO','ITEM_EXP_HEAD',NULL);
   open C_SEQ_NO;
   SQL_LIB.SET_MARK('FETCH','C_SEQ_NO','ITEM_EXP_HEAD',NULL);
   fetch C_SEQ_NO into L_seq_no;
   SQL_LIB.SET_MARK('CLOSE','C_SEQ_NO','ITEM_EXP_HEAD',NULL);
   close C_SEQ_NO;
   ---
   if INSERT_EXPENSES(O_error_message,
                      L_records_inserted,
                      I_item,
                      I_supplier,
                      I_origin_country_id,
                      L_zone_group_id,
                      L_module,
                      L_exp_type,
                      L_seq_no) = FALSE then
      return FALSE;
   end if;
   ---
   if L_records_inserted = 'N' then   -- Get Base Profiles
      if L_exp_type = 'Z' then
         FOR C_rec in C_ZONES LOOP
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
                                      create_datetime,
                                      last_update_datetime,
                                      last_update_id)
                               select I_item,
                                      I_supplier,
                                      'Z',
                                      L_seq_no,
                                      NULL,
                                      C_rec.zone_id,
                                      NULL,
                                      eph.discharge_port,
                                      L_zone_group_id,
                                      'N',
                                      sysdate,
                                      sysdate,
                                      user
                                 from exp_prof_head eph
                                where eph.module        = 'SUPP'
                                  and eph.key_value_1   = to_char(I_supplier)
                                  and eph.exp_prof_type = L_exp_type
                                  and eph.base_prof_ind = 'Y'
                                  and not exists(select 'x'
                                                   from item_exp_head ieh
                                                  where ieh.item           = I_item
                                                    and ieh.supplier       = I_supplier
                                                    and ieh.item_exp_type  = L_exp_type
                                                    and ieh.zone_id        = C_rec.zone_id
                                                    and ieh.zone_group_id  = L_zone_group_id
                                                    and ieh.discharge_port = eph.discharge_port)
                                  and exists( select 'x'
                                                from item_supp_country isc
                                               where isc.item              = I_item
                                                 and isc.supplier          = I_supplier);
         ---
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
                                     create_datetime,
                                     last_update_datetime,
                                     last_update_id)
                              select I_item,
                                     I_supplier,
                                     'Z',
                                     ieh.item_exp_seq,
                                     epd.comp_id,
                                     epd.cvb_code,
                                     epd.comp_rate,
                                     epd.comp_currency,
                                     epd.per_count,
                                     epd.per_count_uom,
                                     0,
                                     epd.nom_flag_1,
                                     epd.nom_flag_2,
                                     epd.nom_flag_3,
                                     epd.nom_flag_4,
                                     epd.nom_flag_5,
                                     elc.display_order,
                                     sysdate,
                                     sysdate,
                                     user
                                from exp_prof_detail epd,
                                     exp_prof_head eph,
                                     item_exp_head ieh,
                                     elc_comp elc
                               where eph.module         = 'SUPP'
                                 and eph.key_value_1    = to_char(I_supplier)
                                 and eph.exp_prof_type  = L_exp_type
                                 and eph.base_prof_ind  = 'Y'
                                 and eph.exp_prof_key   = epd.exp_prof_key
                                 and epd.comp_id        = elc.comp_id
                                 and ieh.item           = I_item
                                 and ieh.supplier       = I_supplier
                                 and ieh.zone_group_id  = L_zone_group_id
                                 and ieh.item_exp_type  = eph.exp_prof_type
                                 and ieh.discharge_port = eph.discharge_port
                                 -- DefNBS024190 23-Jan-2012 Vinutha Raju, vinutha.raju@in.tesco.com Begin
                                 and eph.zone_id        = ieh.zone_id
                                 -- DefNBS024190 23-Jan-2012 Vinutha Raju, vinutha.raju@in.tesco.com End
                                 and not exists(select 'x'
                                                  from item_exp_detail ied
                                                 where ied.item           = I_item
                                                   and ied.supplier       = I_supplier
                                                   and ied.item_exp_type  = L_exp_type
                                                   and ied.item_exp_seq   = ieh.item_exp_seq
                                                   and ied.comp_id        = epd.comp_id);
            L_seq_no := L_seq_no + 1;
         END LOOP;
      else -- Get Supplier 'Country' level base profiles
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
                                   create_datetime,
                                   last_update_datetime,
                                   last_update_id)
                            select I_item,
                                   I_supplier,
                                   'C',
                                   L_seq_no,
                                   I_origin_country_id,
                                   NULL,
                                   eph.lading_port,
                                   eph.discharge_port,
                                   NULL,
                                   'N',
                                   sysdate,
                                   sysdate,
                                   user
                              from exp_prof_head eph
                             where eph.module        = 'SUPP'
                               and eph.key_value_1   = to_char(I_supplier)
                               and eph.exp_prof_type = L_exp_type
                               and eph.base_prof_ind = 'Y'
                               and not exists(select 'x'
                                                from item_exp_head ieh
                                               where ieh.item              = I_item
                                                 and ieh.supplier          = I_supplier
                                                 and ieh.item_exp_type     = L_exp_type
                                                 and ieh.origin_country_id = I_origin_country_id
                                                 and ieh.lading_port       = eph.lading_port
                                                 and ieh.discharge_port    = eph.discharge_port)
                               and exists( select 'x'
                                             from item_supp_country isc
                                             where isc.item              = I_item
                                               and isc.supplier          = I_supplier
                                               and isc.origin_country_id = I_origin_country_id);
         ---
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
                                     create_datetime,
                                     last_update_datetime,
                                     last_update_id)
                              select I_item,
                                     I_supplier,
                                     'C',
                                     ieh.item_exp_seq,
                                     epd.comp_id,
                                     epd.cvb_code,
                                     epd.comp_rate,
                                     epd.comp_currency,
                                     epd.per_count,
                                     epd.per_count_uom,
                                     0,
                                     epd.nom_flag_1,
                                     epd.nom_flag_2,
                                     epd.nom_flag_3,
                                     epd.nom_flag_4,
                                     epd.nom_flag_5,
                                     elc.display_order,
                                     sysdate,
                                     sysdate,
                                     user
                                from exp_prof_detail epd,
                                     exp_prof_head eph,
                                     item_exp_head ieh,
                                     elc_comp elc
                               where eph.module            = 'SUPP'
                                 and eph.key_value_1       = to_char(I_supplier)
                                 and eph.exp_prof_type     = L_exp_type
                                 and eph.base_prof_ind     = 'Y'
                                 and eph.exp_prof_key      = epd.exp_prof_key
                                 and epd.comp_id           = elc.comp_id
                                 and ieh.item              = I_item
                                 and ieh.supplier          = I_supplier
                                 and ieh.item_exp_type     = eph.exp_prof_type
                                 and ieh.discharge_port    = eph.discharge_port
                                 and ieh.origin_country_id = I_origin_country_id
                                 and ieh.lading_port       = eph.lading_port
                                 and not exists(select 'x'
                                                  from item_exp_detail ied
                                                 where ied.item           = I_item
                                                   and ied.supplier       = I_supplier
                                                   and ied.item_exp_type  = L_exp_type
                                                   and ied.item_exp_seq   = ieh.item_exp_seq
                                                   and ied.comp_id        = epd.comp_id);
      end if;
   end if;
   ---
   -- Insert country level expense profiles that are attached to the origin country
   ---
   if I_origin_country_id is not NULL then
      L_module   := 'CTRY';
      L_exp_type := 'C';
      ---
      SQL_LIB.SET_MARK('OPEN','C_SEQ_NO','ITEM_EXP_HEAD',NULL);
      open C_SEQ_NO;
      SQL_LIB.SET_MARK('FETCH','C_SEQ_NO','ITEM_EXP_HEAD',NULL);
      fetch C_SEQ_NO into L_seq_no;
      SQL_LIB.SET_MARK('CLOSE','C_SEQ_NO','ITEM_EXP_HEAD',NULL);
      close C_SEQ_NO;
      ---
      if INSERT_EXPENSES(O_error_message,
                         L_records_inserted,
                         I_item,
                         I_supplier,
                         I_origin_country_id,
                         L_zone_group_id,
                         L_module,
                         L_exp_type,
                         L_seq_no) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   -- Insert Always Default Expenses from the ELC_COMP table
   ---
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
                               create_datetime,
                               last_update_datetime,
                               last_update_id)
                        select I_item,
                               I_supplier,
                               L_exp_type,
                               ieh.item_exp_seq,
                               elc.comp_id,
                               elc.cvb_code,
                               elc.comp_rate,
                               elc.comp_currency,
                               elc.per_count,
                               elc.per_count_uom,
                               0,
                               elc.nom_flag_1,
                               elc.nom_flag_2,
                               elc.nom_flag_3,
                               elc.nom_flag_4,
                               elc.nom_flag_5,
                               elc.display_order,
                               sysdate,
                               sysdate,
                               user
                          from item_exp_head ieh,
                               elc_comp elc
                         where ieh.item               = I_item
                           and ieh.supplier           = I_supplier
                           and ieh.item_exp_type      = L_exp_type
                           and elc.always_default_ind = 'Y'
                           and elc.comp_type          = 'E'
                           and elc.expense_type       = ieh.item_exp_type
                           and not exists(select 'x'
                                            from item_exp_detail ied
                                           where ied.item           = I_item
                                             and ied.supplier       = I_supplier
                                             and ied.item_exp_type  = L_exp_type
                                             and ied.item_exp_seq   = ieh.item_exp_seq
                                             and ied.comp_id        = elc.comp_id);
   ---
   -- Calculate the Expenses that were inserted.
   ---
   if ELC_CALC_SQL.CALC_COMP(O_error_message,
                             'IE',
                             I_item,
                             I_supplier,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             I_origin_country_id,
                             NULL,
                             NULL) = FALSE then
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

END DEFAULT_EXPENSES;
------------------------------------------------------------------------------------------------
FUNCTION INSERT_EXPENSES(O_error_message     IN OUT VARCHAR2,
                         O_records_inserted  IN OUT VARCHAR2,
                         I_item              IN     ITEM_MASTER.ITEM%TYPE,
                         I_supplier          IN     SUPS.SUPPLIER%TYPE,
                         I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                         I_zone_group_id     IN     COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                         I_module            IN     EXP_PROF_HEAD.MODULE%TYPE,
                         I_exp_type          IN     EXP_PROF_HEAD.EXP_PROF_TYPE%TYPE,
                         I_seq_no            IN     ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE)
   RETURN BOOLEAN IS
   L_program     VARCHAR2(40)  := 'ITEM_EXPENSE_SQL.INSERT_EXPENSES';
   L_exists      VARCHAR2(1);

   cursor C_HEADER_EXISTS is
      select 'Y'
        from item_exp_head
       where item          = I_item
         and supplier      = I_supplier
         and item_exp_type = I_exp_type;

BEGIN
   O_records_inserted := 'Y';
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_EXP_HEAD', NULL);
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
                             create_datetime,
                             last_update_datetime,
                             last_update_id)
                      select I_item,
                             I_supplier,
                             I_exp_type,
                             I_seq_no + rownum,
                             I_origin_country_id,
                             eph.zone_id,
                             eph.lading_port,
                             eph.discharge_port,
                             I_zone_group_id,
                             'N',
                             sysdate,
                             sysdate,
                             user
                        from exp_prof_head eph
                       where eph.module        = I_module
                         and eph.key_value_1   = decode(I_module,'SUPP',to_char(I_supplier),'CTRY',I_origin_country_id)
                         and eph.exp_prof_type = I_exp_type
                         and ((I_exp_type                = 'Z'
                               and eph.zone_group_id     = I_zone_group_id)
                          or (I_exp_type                 = 'C'
                               and eph.origin_country_id = I_origin_country_id))
                         and not exists(select 'x'
                                          from item_exp_head ieh
                                         where ieh.item           = I_item
                                           and ieh.supplier       = I_supplier
                                           and ieh.item_exp_type  = I_exp_type
                                           and ((I_exp_type               = 'Z'
                                                 and ieh.zone_id          = eph.zone_id
                                                 and ieh.zone_group_id    = I_zone_group_id)
                                            or (I_exp_type                = 'C'
                                                and ieh.origin_country_id = I_origin_country_id
                                                and ieh.lading_port       = eph.lading_port))
                                           and ieh.discharge_port  = eph.discharge_port)
                         and exists( select 'x'
                                       from item_supp_country isc
                                      where isc.item              = I_item
                                        and isc.supplier          = I_supplier
                                        and isc.origin_country_id = NVL(I_origin_country_id, isc.origin_country_id));
   if SQL%FOUND then
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
                                  create_datetime,
                                  last_update_datetime,
                                  last_update_id)
                           select I_item,
                                  I_supplier,
                                  I_exp_type,
                                  ieh.item_exp_seq,
                                  epd.comp_id,
                                  epd.cvb_code,
                                  epd.comp_rate,
                                  epd.comp_currency,
                                  epd.per_count,
                                  epd.per_count_uom,
                                  0,
                                  epd.nom_flag_1,
                                  epd.nom_flag_2,
                                  epd.nom_flag_3,
                                  epd.nom_flag_4,
                                  epd.nom_flag_5,
                                  elc.display_order,
                                  sysdate,
                                  sysdate,
                                  user
                             from exp_prof_detail epd,
                                  exp_prof_head eph,
                                  item_exp_head ieh,
                                  elc_comp elc
                            where eph.module         = I_module
                              and eph.key_value_1    = decode(I_module,'SUPP',to_char(I_supplier),'CTRY',I_origin_country_id)
                              and eph.exp_prof_type  = I_exp_type
                              and eph.discharge_port = ieh.discharge_port
                              and eph.exp_prof_key   = epd.exp_prof_key
                              and epd.comp_id        = elc.comp_id
                              and ieh.item           = I_item
                              and ieh.supplier       = I_supplier
                              and ieh.item_exp_type  = eph.exp_prof_type
                              and ((I_exp_type            = 'Z'
                                    and eph.zone_group_id = I_zone_group_id
                                    and eph.zone_group_id = ieh.zone_group_id
                                    and eph.zone_id       = ieh.zone_id)
                               or (I_exp_type                = 'C'
                                   and eph.origin_country_id = I_origin_country_id
                                   and eph.origin_country_id = ieh.origin_country_id
                                   and eph.lading_port       = ieh.lading_port))
                              and not exists(select 'x'
                                               from item_exp_detail ied
                                              where ied.item           = I_item
                                                and ied.supplier       = I_supplier
                                                and ied.item_exp_type  = I_exp_type
                                                and ied.item_exp_seq   = ieh.item_exp_seq
                                                and ied.comp_id        = epd.comp_id);
   else
     if I_module = 'SUPP' and I_exp_type = 'C' then
         SQL_LIB.SET_MARK('OPEN', NULL, 'C_HEADER_EXISTS', NULL);
         open C_HEADER_EXISTS;
         SQL_LIB.SET_MARK('FETCH', NULL, 'C_HEADER_EXISTS', NULL);
         fetch C_HEADER_EXISTS into L_exists;
         SQL_LIB.SET_MARK('CLOSE', NULL, 'C_HEADER_EXISTS', NULL);
         close C_HEADER_EXISTS;
         ---
         if L_exists = 'Y' then
                  SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_EXP_DETAIL', NULL);
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
                                  create_datetime,
                                  last_update_datetime,
                                  last_update_id)
                           select I_item,
                                  I_supplier,
                                  I_exp_type,
                                  ieh.item_exp_seq,
                                  epd.comp_id,
                                  epd.cvb_code,
                                  epd.comp_rate,
                                  epd.comp_currency,
                                  epd.per_count,
                                  epd.per_count_uom,
                                  0,
                                  epd.nom_flag_1,
                                  epd.nom_flag_2,
                                  epd.nom_flag_3,
                                  epd.nom_flag_4,
                                  epd.nom_flag_5,
                                  elc.display_order,
                                  sysdate,
                                  sysdate,
                                  user
                             from exp_prof_detail epd,
                                  exp_prof_head eph,
                                  item_exp_head ieh,
                                  elc_comp elc
                            where eph.module         = I_module
                              and eph.key_value_1    = to_char(I_supplier)
                              and eph.exp_prof_type  = I_exp_type
                              and eph.discharge_port = ieh.discharge_port
                              and eph.exp_prof_key   = epd.exp_prof_key
                              and epd.comp_id        = elc.comp_id
                              and ieh.item           = I_item
                              and ieh.supplier       = I_supplier
                              and ieh.item_exp_type  = eph.exp_prof_type
                              and ((I_exp_type            = 'Z'
                                    and eph.zone_group_id = I_zone_group_id
                                    and eph.zone_group_id = ieh.zone_group_id
                                    and eph.zone_id       = ieh.zone_id)
                               or (I_exp_type                = 'C'
                                   and eph.origin_country_id = I_origin_country_id
                                   and eph.origin_country_id = ieh.origin_country_id
                                   and eph.lading_port       = ieh.lading_port))
                              and not exists(select 'x'
                                               from item_exp_detail ied
                                              where ied.item           = I_item
                                                and ied.supplier       = I_supplier
                                                and ied.item_exp_type  = I_exp_type
                                                and ied.item_exp_seq   = ieh.item_exp_seq
                                                and ied.comp_id        = epd.comp_id);
                 if SQL%NOTFOUND then
                    O_records_inserted := 'N';
                 end if;
         else
            O_records_inserted := 'N';
         end if;
      else
      O_records_inserted := 'N';
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

END INSERT_EXPENSES;
------------------------------------------------------------------------------------------------
FUNCTION INSERT_ALWAYS_EXPENSES(O_error_message     IN OUT VARCHAR2,
                                I_item              IN     ITEM_MASTER.ITEM%TYPE,
                                I_supplier          IN     SUPS.SUPPLIER%TYPE,
                                I_item_exp_type     IN     ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                                I_item_exp_seq      IN     ITEM_EXP_DETAIL.ITEM_EXP_SEQ%TYPE,
                                I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS
   L_program     VARCHAR2(40)  := 'ITEM_EXPENSE_SQL.INSERT_ALWAYS_EXPENSES';

BEGIN
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
                               create_datetime,
                               last_update_datetime,
                               last_update_id)
                        select I_item,
                               I_supplier,
                               I_item_exp_type,
                               ieh.item_exp_seq,
                               elc.comp_id,
                               elc.cvb_code,
                               elc.comp_rate,
                               elc.comp_currency,
                               elc.per_count,
                               elc.per_count_uom,
                               0,
                               elc.nom_flag_1,
                               elc.nom_flag_2,
                               elc.nom_flag_3,
                               elc.nom_flag_4,
                               elc.nom_flag_5,
                               elc.display_order,
                               sysdate,
                               sysdate,
                               user
                          from item_exp_head ieh,
                               elc_comp elc
                         where ieh.item               = I_item
                           and ieh.supplier           = I_supplier
                           and ieh.item_exp_type      = I_item_exp_type
                           and ieh.item_exp_seq       = I_item_exp_seq
                           and elc.always_default_ind = 'Y'
                           and elc.comp_type          = 'E'
                           and elc.expense_type       = ieh.item_exp_type
                           and not exists(select 'x'
                                            from item_exp_detail ied
                                           where ied.item           = I_item
                                             and ied.supplier       = I_supplier
                                             and ied.item_exp_type  = I_item_exp_type
                                             and ied.item_exp_seq   = ieh.item_exp_seq
                                             and ied.comp_id        = elc.comp_id);
   ---
   -- Calculate the Expenses that were inserted.
   ---
   if ELC_CALC_SQL.CALC_COMP(O_error_message,
                             'IE',
                             I_item,
                             I_supplier,
                             I_item_exp_type,
                             I_item_exp_seq,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             I_origin_country_id,
                             NULL,
                             NULL) = FALSE then
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

END INSERT_ALWAYS_EXPENSES;
------------------------------------------------------------------------------------------------
FUNCTION DEFAULT_GROUP_EXP(O_error_message        IN OUT VARCHAR2,
                           I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                           I_supplier             IN     SUPS.SUPPLIER%TYPE,
                           I_origin_country_id    IN     COUNTRY.COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(40)   := 'ITEM_EXPENSE_SQL.DEFAULT_GROUP_EXP';

   cursor C_GET_KIDS is
      select item
        from item_master
       where (item_parent = I_item
          or item_grandparent = I_item)
         and item_level <= tran_level;

BEGIN

   FOR C_rec in C_GET_KIDS LOOP
      if DEFAULT_EXPENSES(O_error_message,
                          C_rec.item,
                          I_supplier,
                          I_origin_country_id) = FALSE then
         return FALSE;
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
END DEFAULT_GROUP_EXP;

-----------------------------------------------------------------------------------------------
FUNCTION COPY_DOWN_PARENT_EXP(O_error_message        IN OUT VARCHAR2,
                              I_parent               IN     ITEM_MASTER.ITEM%TYPE,
                              I_supplier             IN     SUPS.SUPPLIER%TYPE,
                              I_origin_country_id    IN     COUNTRY.COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(40)   := 'ITEM_EXPENSE_SQL.COPY_DOWN_PARENT_EXP';
   L_exp_type           ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE;
   L_seq_no             ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE;
BEGIN
   if I_origin_country_id is NULL then
      L_exp_type := 'Z';
   else
      L_exp_type := 'C';
   end if;
   ---
   delete from item_exp_detail ied
      where exists (select 'x'
                      from item_master im, item_exp_head ieh
                     where im.item = ied.item
                       and (im.item_parent = I_parent
                        or im.item_grandparent = I_parent)
                       and (I_origin_country_id is NULL or
                            ieh.origin_country_id = I_origin_country_id)
                       and ieh.item_exp_type = L_exp_type
                       and ieh.supplier = I_supplier
                       and ieh.item = ied.item
                       and ied.item_exp_seq = ieh.item_exp_seq
                       and ied.supplier = ieh.supplier
                       and ied.item_exp_type = ieh.item_exp_type);

   delete from item_exp_head ieh
      where exists (select 'x'
                      from item_master im
                     where (im.item_parent = I_parent
                        or im.item_grandparent = I_parent)
                       and ieh.item = im.item)
           and (I_origin_country_id is NULL or
                ieh.origin_country_id = I_origin_country_id)
           and ieh.item_exp_type = L_exp_type
           and ieh.supplier = I_supplier;

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
                             create_datetime,
                             last_update_datetime,
                             last_update_id)
                      select im.item,
                             ieh.supplier,
                             ieh.item_exp_type,
                             ieh.item_exp_seq,
                             ieh.origin_country_id,
                             ieh.zone_id,
                             ieh.lading_port,
                             ieh.discharge_port,
                             ieh.zone_group_id,
                             ieh.base_exp_ind,
                             sysdate,
                             sysdate,
                             user
                        from item_exp_head ieh,
                             item_master im
                       where ieh.item               = I_parent
                         and (im.item_parent        = ieh.item or im.item_grandparent = ieh.item)
                         and (ieh.origin_country_id = I_origin_country_id or I_origin_country_id is NULL)
                         and ieh.supplier           = I_supplier
                         and ieh.item_exp_type      = L_exp_type
                         and exists( select 'x'
                                       from item_supp_country isc
                                      where isc.item              = im.item
                                        and isc.supplier          = ieh.supplier
                                        and isc.origin_country_id = NVL(ieh.origin_country_id, isc.origin_country_id));
      ---
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
                                  create_datetime,
                                  last_update_datetime,
                                  last_update_id)
                           select im.item,
                                  ied.supplier,
                                  ied.item_exp_type,
                                  ied.item_exp_seq,
                                  ied.comp_id,
                                  ied.cvb_code,
                                  ied.comp_rate,
                                  ied.comp_currency,
                                  ied.per_count,
                                  ied.per_count_uom,
                                  ied.est_exp_value,
                                  ied.nom_flag_1,
                                  ied.nom_flag_2,
                                  ied.nom_flag_3,
                                  ied.nom_flag_4,
                                  ied.nom_flag_5,
                                  ied.display_order,
                                  sysdate,
                                  sysdate,
                                  user
                             from item_master im,
                                  item_exp_detail ied,
                                  item_exp_head ieh
                            where ied.item               = I_parent
                              and (im.item_parent        = ied.item or im.item_grandparent = ied.item)
                              and ied.item               = ieh.item
                              and ied.item_exp_type      = L_exp_type
                              and ied.item_exp_seq       = ieh.item_exp_seq
                              and ied.item_exp_type      = ieh.item_exp_type
                              and (ieh.origin_country_id = I_origin_country_id or I_origin_country_id is NULL)
                              and ied.supplier = I_supplier
                              and ied.supplier = ieh.supplier
                              and exists( select 'x'
                                            from item_supp_country isc
                                           where isc.item              = im.item
                                             and isc.supplier          = ieh.supplier
                                             and isc.origin_country_id = NVL(ieh.origin_country_id, isc.origin_country_id));
return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END COPY_DOWN_PARENT_EXP;
-----------------------------------------------------------------------------------------------
--05-Jul-2007 WiproEnabler/Ramasamy - MOD 365b   Begin
---------------------------------------------------------------------------------------------------------------
   --TSL_COPY_BASE_EXP    Remove old ITEM_EXP_HEAD and ITEM_EXP_DETAIL values of all Variant Items associated to
   --the passed Base Item, get latest values for the Base item, and insert new ITEM_EXP_HEAD and ITEM_EXP_DETAIL
   --values for the valid Variant Items.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_COPY_BASE_EXP(O_error_message     IN OUT VARCHAR2,
                              I_item              IN     ITEM_MASTER.ITEM%TYPE,
                              I_supplier          IN     SUPS.SUPPLIER%TYPE,
                              I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE)
      return BOOLEAN is

      L_program  VARCHAR2(64) := 'ITEM_EXPENSE_SQL.TSL_COPY_BASE_EXP ';
      L_table    VARCHAR2(65);
      L_exp_type ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE;
      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED,
                            -54);
      --This cursor will lock the variant information on the table ITEM_EXP_DETAIL
      cursor C_LOCK_ITEM_EXP_DETAIL is
         select 'x'
           from item_exp_detail ied
          where ied.supplier      = I_supplier
            and ied.item_exp_type = L_exp_type
            and ied.item in (select im.item
                               from item_master im
                              where im.tsl_base_item = I_item
                                and im.tsl_base_item != im.item
                                and im.item_level    = im.tran_level
                                and im.item_level    = 2)
            for update nowait;
      --This cursor will lock the variant information on the table ITEM_EXP_HEAD
      cursor C_LOCK_ITEM_EXP_HEAD is
         select 'x'
           from item_exp_head ieh
          where ieh.supplier      = I_supplier
            and (ieh.origin_country_id = I_origin_country_id or
                ieh.origin_country_id is NULL)
            and ieh.item_exp_type = L_exp_type
            and ieh.item in (select im.item
                               from item_master im
                              where im.tsl_base_item = I_item
                                and im.tsl_base_item != im.item
                                and im.item_level    = im.tran_level
                                and im.item_level    = 2)
            FOR update nowait;
   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_supplier is null
      if I_supplier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_supplier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_origin_country_id is null
      if I_origin_country_id is NULL then
         L_exp_type := 'Z';
      else
         L_exp_type := 'C';
      end if;
      --
      L_table := 'ITEM_EXP_DETAIL';
      --
      --Opening the cursor C_LOCK_ITEM_EXP_DETAIL
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ITEM_EXP_DETAIL',
                       'ITEM_EXP_DETAIL',
                       'ITEM: ' || I_item);
      open C_LOCK_ITEM_EXP_DETAIL;
      --Closing the cursor C_LOCK_ITEM_EXP_DETAIL
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ITEM_EXP_DETAIL',
                       'ITEM_EXP_DETAIL',
                       'ITEM: ' || I_item);
      close C_LOCK_ITEM_EXP_DETAIL;
      --
      --Delete records from the ITEM_EXP_DETAIL table
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'ITEM_EXP_DETAIL',
                       'ITEM: ' || I_item);
      --
      delete from item_exp_detail ied
       where exists (select 'x'
                       from item_master   im,
                            item_exp_head ieh
                      where im.item          = ied.item
                        and im.tsl_base_item = I_item
                        and im.tsl_base_item != im.item
                        and im.item_level    = im.tran_level
                        and im.item_level    = 2
                        and (I_origin_country_id is NULL or
                            ieh.origin_country_id = I_origin_country_id)
                        and ieh.item_exp_type = L_exp_type
                        and ieh.supplier      = I_supplier
                        and ieh.item          = ied.item
                        and ied.item_exp_seq  = ieh.item_exp_seq
                        and ied.supplier      = ieh.supplier
                        and ied.item_exp_type = ieh.item_exp_type);

      --
      L_table := 'ITEM_EXP_HEAD';
      --
      --Opening the cursor C_LOCK_ITEM_EXP_HEAD
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ITEM_EXP_HEAD',
                       'ITEM_EXP_HEAD',
                       'ITEM: ' || I_item);
      open C_LOCK_ITEM_EXP_HEAD;
      --Closing the cursor C_LOCK_ITEM_EXP_HEAD
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ITEM_EXP_HEAD',
                       'ITEM_EXP_HEAD',
                       'ITEM: ' || I_item);
      close C_LOCK_ITEM_EXP_HEAD;
      --
      --Delete records from the ITEM_EXP_HEAD table
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'ITEM_EXP_HEAD',
                       'ITEM: ' || I_item);
      --
      delete from item_exp_head ieh
       where exists (select 'x'
                       from item_master im
                      where im.tsl_base_item = I_item
                        and im.tsl_base_item != im.item
                        and im.item_level    = im.tran_level
                        and im.item_level    = 2
                        and ieh.item         = im.item)
         and (I_origin_country_id is NULL or
             ieh.origin_country_id = I_origin_country_id)
         and ieh.item_exp_type = L_exp_type
         and ieh.supplier      = I_supplier;
      --
      --Insert records into the ITEM_EXP_HEAD table
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'ITEM_EXP_HEAD',
                       'ITEM: ' || I_item);
      --
      insert into item_exp_head
         (item,
          supplier,
          item_exp_type,
          item_exp_seq,
          origin_country_id,
          zone_id,
          lading_port,
          discharge_port,
          zone_group_id,
          base_exp_ind,
          create_datetime,
          last_update_datetime,
          last_update_id)
         (select im.item,
                 ieh.supplier,
                 ieh.item_exp_type,
                 ieh.item_exp_seq,
                 ieh.origin_country_id,
                 ieh.zone_id,
                 ieh.lading_port,
                 ieh.discharge_port,
                 ieh.zone_group_id,
                 ieh.base_exp_ind,
                 SYSDATE,
                 SYSDATE,
                 USER
            from item_exp_head     ieh,
                 item_master       im,
                 item_supp_country isc
           where ieh.item              = I_item
             and ieh.supplier          = I_supplier
             and (ieh.origin_country_id = I_origin_country_id or
                 ieh.origin_country_id is NULL)
             and ieh.item_exp_type     = L_exp_type
             and ieh.item              = im.tsl_base_item
             and im.tsl_base_item      = I_item
             and im.tsl_base_item      != im.item
             and im.item_level         = im.tran_level
             and im.item_level         = 2
             and isc.item              = im.item
             and isc.supplier          = ieh.supplier
             and isc.origin_country_id =
                 NVL(ieh.origin_country_id,
                     isc.origin_country_id));
      --
      --
      --Insert records into the ITEM_EXP_DETAIL table
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'ITEM_EXP_DETAIL',
                       'ITEM: ' || I_item);
      --
      insert into item_exp_detail
         (item,
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
          create_datetime,
          last_update_datetime,
          last_update_id)
         (select im.item,
                 ied.supplier,
                 ied.item_exp_type,
                 ied.item_exp_seq,
                 ied.comp_id,
                 ied.cvb_code,
                 ied.comp_rate,
                 ied.comp_currency,
                 ied.per_count,
                 ied.per_count_uom,
                 ied.est_exp_value,
                 ied.nom_flag_1,
                 ied.nom_flag_2,
                 ied.nom_flag_3,
                 ied.nom_flag_4,
                 ied.nom_flag_5,
                 ied.display_order,
                 SYSDATE,
                 SYSDATE,
                 USER
            from item_exp_head     ieh,
                 item_exp_detail   ied,
                 item_master       im,
                 item_supp_country isc
           where ieh.item = ied.item
             and ieh.item_exp_seq      = ied.item_exp_seq
             and ieh.item_exp_type     = ied.item_exp_type
             and ieh.supplier          = ied.supplier
             and (ieh.origin_country_id = I_origin_country_id or
                 ieh.origin_country_id is NULL)
             and ied.item              = I_item
             and ied.supplier          = I_supplier
             and ied.item_exp_type     = L_exp_type
             and ieh.item              = im.tsl_base_item
             and im.tsl_base_item      = I_item
             and im.tsl_base_item      != im.item
             and im.item_level         = im.tran_level
             and im.item_level         = 2
             and isc.item              = im.item
             and isc.supplier          = ieh.supplier
             and isc.origin_country_id =
                 NVL(ieh.origin_country_id,
                     isc.origin_country_id));
      --
      ---
      return TRUE;
      ---
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               TO_CHAR(I_supplier));
         return FALSE;
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_COPY_BASE_EXP;
--05-Jul-2007 WiproEnabler/Ramasamy - MOD 365b   End
------------------------------------------------------------------------------------------------------
-- Mod 364.2, 29-Jan-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
-------------------------------------------------------------------------------------------------------------
-- Function : TSL_BASE_EXP_DISCHRG_PORT
-- Purpose  : This function retrieves the Discharge Port, for a given Item,Supplier and Costing Date.
-------------------------------------------------------------------------------------------------------------
FUNCTION TSL_BASE_EXP_DISCHRG_PORT(O_error_message  IN OUT NOCOPY RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_discharge_port IN OUT NOCOPY ITEM_EXP_HEAD.DISCHARGE_PORT%TYPE,
                                   I_item           IN            ITEM_SUPP_COUNTRY.ITEM%TYPE,
                                   I_supplier       IN            ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                                   -- NBS00017368 24-June-2010 Murali N Begin
   	                               I_cost_zone      IN            COST_ZONE.ZONE_ID%TYPE,
   	                               -- NBS00017368 24-June-2010 Murali N End
                                   I_costing_date   IN            DATE)
    RETURN BOOLEAN IS
    ---
    L_table        VARCHAR2(30):= 'ITEM_EXP_DETAIL';
    L_program      VARCHAR2(50):= 'ITEM_EXPENSE_SQL.TSL_BASE_EXP_DISCHRG_PORT';
    ---
    cursor C_GET_BASE_DISCHARGE_PORT is
    select ieh.discharge_port
      from item_exp_head ieh,
               (select tih.item,
                       tih.supplier,
                       tih.item_exp_type,
                       tih.item_exp_seq,
                       tih.active_date
                  from tsl_item_exp_head tih
                 where tih.item        = I_item
                   and tih.supplier    = I_supplier
                   and tih.active_date = (select MAX(tih2.active_date)
                                            from tsl_item_exp_head tih2,
                                                 -- NBS00017368 24-June-2010 Murali N Begin
                                                 item_exp_head ieh1
                                                 -- NBS00017368 24-June-2010 Murali N End
                                           where tih2.item          = tih.item
                                             and tih2.supplier      = tih.supplier
                                             and tih2.item_exp_type = tih.item_exp_type
                                             -- NBS00017368 24-June-2010 Murali N Begin
                                             and ieh1.item  = tih2.item
                                             and ieh1.supplier = tih2.supplier
                                             and ieh1.item_exp_type = tih2.item_exp_type
                                             and ieh1.item_exp_seq = tih2.item_exp_seq
                                             and ieh1.zone_id in (select ieh2.zone_id
                                                                   from item_exp_head ieh2
                                                                  where ieh2.item = tih.item
                                                                    AND ieh2.supplier = tih.supplier
                                                                    AND ieh2.item_exp_seq = tih.item_exp_seq
                                                                    AND ieh2.item_exp_type = tih.item_exp_type)
                                             -- NBS00017368 24-June-2010 Murali N End
                                             and tih2.active_date   <= I_costing_date)) exp
         where ieh.item          = I_item
           and ieh.supplier      = I_supplier
           and ieh.item          = exp.item (+)
           and ieh.supplier      = exp.supplier (+)
           and ieh.item_exp_type = exp.item_exp_type (+)
           -- DefNBS023177 06-Jul-2011 Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com Begin
           and ieh.item_exp_seq  = nvl(exp.item_exp_seq,ieh.item_exp_seq)
           -- DefNBS023177 06-Jul-2011 Accenture/Parvesh Rulhan, parveshkumar.rulhan@in.tesco.com End
           -- NBS00017368 24-June-2010 Murali N Begin
           and ieh.zone_id = I_cost_zone
           -- NBS00017368 24-June-2010 Murali N End
           and ((exp.active_date is NULL and ieh.base_exp_ind = 'Y')
              or exp.active_date is NOT NULL);

    ---
BEGIN
    if I_item is NULL then
        O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                              'I_item',
                                              'NULL',
                                              'NOT NULL');
        return FALSE;
    end if;
    ---
    if I_supplier is NULL then
        O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                              'I_supplier',
                                              'NULL',
                                              'NOT NULL');
        return FALSE;
    end if;
    ---
    if I_costing_date is NULL then
        O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                              'I_costing_date',
                                              'NULL',
                                              'NOT NULL');
        return FALSE;
    end if;
    ---
    SQL_LIB.SET_MARK('OPEN',
                     'C_GET_BASE_DISCHARGE_PORT',
                     'ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item||
                     ', SUPPLIER: '||I_supplier);
    open C_GET_BASE_DISCHARGE_PORT;
    ---
    SQL_LIB.SET_MARK('FETCH',
                     'C_GET_BASE_DISCHARGE_PORT',
                     'ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item||
                     ', SUPPLIER: '||I_supplier);
    fetch C_GET_BASE_DISCHARGE_PORT into O_discharge_port;
    ---
    -- NBS00017368 24-June-2010 Murali N Begin
    if C_GET_BASE_DISCHARGE_PORT%NOTFOUND then
       O_discharge_port := NULL;
    end if;
    -- NBS00017368 24-June-2010 Murali N End
    SQL_LIB.SET_MARK('CLOSE',
                     'C_GET_BASE_DISCHARGE_PORT',
                     'ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item||
                     ', SUPPLIER: '||I_supplier);
    close C_GET_BASE_DISCHARGE_PORT;
    ---

    return TRUE;


EXCEPTION
    ---
    when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
        return FALSE;
    ---
END TSL_BASE_EXP_DISCHRG_PORT;
-------------------------------------------------------------------------------------------------------------
-- Function : TSL_GET_TNETT_COST
-- Purpose  : This function retrieves the value of Tesco Nett cost for an item-supplier.
------------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_TNETT_COST(O_error_message IN OUT NOCOPY RTK_ERRORS.RTK_TEXT%TYPE,
                            O_tnett_cost    IN OUT NOCOPY ITEM_LOC_SOH.UNIT_COST%TYPE,
                            I_item          IN            ITEM_MASTER.ITEM%TYPE,
                            I_unit_cost     IN            ITEM_LOC_SOH.UNIT_COST%TYPE)
    RETURN BOOLEAN IS
    L_prim_supp                   SUPS.SUPPLIER%TYPE;
    L_est_exp_value               ITEM_EXP_DETAIL.EST_EXP_VALUE%TYPE;
    L_cash_settlement_discount    NUMBER;
    L_status                      BOOLEAN     := FALSE;
    L_date                        DATE        := GET_VDATE();
    L_program                     VARCHAR2(50):= 'ITEM_EXPENSE_SQL.TSL_GET_TNETT_COST';
    ---
    cursor C_GET_PRIM_SUPP is
        select supplier
          from item_supp_country
         where item = I_item
           and primary_supp_ind = 'Y';
    ---
    cursor C_GET_EST_EXP_VALUE is
        select ied.est_exp_value
          from item_exp_detail ied
         where ied.item          = I_item
           and ied.supplier      = L_prim_supp
           and ied.item_exp_type = 'Z'
           and ied.comp_id       = 'TEXP';
BEGIN
    ---
    if I_item is NULL then
        O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                              'I_item',
                                              'NULL',
                                              'NOT NULL');
        return FALSE;
    end if;
    ---
    if I_unit_cost is NULL then
        O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                              'I_unit_cost',
                                              'NULL',
                                              'NOT NULL');
        return FALSE;
    end if;
    ---
    SQL_LIB.SET_MARK('OPEN',
                     'C_GET_PRIM_SUPP',
                     'SUPPLIER',
                     'ITEM: ' || I_item);
    open C_GET_PRIM_SUPP;
    ---
    SQL_LIB.SET_MARK('FETCH',
                     'C_GET_PRIM_SUPP',
                     'SUPPLIER',
                     'ITEM: ' || I_item);
    fetch C_GET_PRIM_SUPP into L_prim_supp;
    ---
    -- To report error message for not existed Item Number this condition require
    if C_GET_PRIM_SUPP%FOUND then
        L_status := TRUE;
    end if;
    ---
    SQL_LIB.SET_MARK('CLOSE',
                     'C_GET_PRIM_SUPP',
                     'SUPPLIER',
                     'ITEM: ' || I_item);
    close C_GET_PRIM_SUPP;
    ---
    if L_status = FALSE then
        O_error_message := SQL_LIB.CREATE_MSG('INVALID_ITEM');
        return FALSE;
    end if;
    ---
    SQL_LIB.SET_MARK('OPEN',
                     'C_GET_EST_EXP_VALUE',
                     'ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    open C_GET_EST_EXP_VALUE;
    ---
    SQL_LIB.SET_MARK('FETCH',
                     'C_GET_EST_EXP_VALUE',
                     'ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    fetch C_GET_EST_EXP_VALUE into L_est_exp_value;
    ---
    SQL_LIB.SET_MARK('CLOSE',
                     'C_GET_EST_EXP_VALUE',
                     'ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    close C_GET_EST_EXP_VALUE;
    ---
    if not TSL_MARGIN_SQL.GET_CASH_STLEMNT_DISCOUNT_PRIM(O_error_message,
                                                         L_cash_settlement_discount,
                                                         L_prim_supp,
                                                         I_unit_cost,
                                                         L_date) then
        return FALSE;
    end if;
    ---
    -- Calculation to get 'Tesco Net Cost'
    O_tnett_cost := I_unit_cost - NVL(L_cash_settlement_discount,0) + NVL(L_est_exp_value,0);

    return TRUE;

EXCEPTION
    when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
        return FALSE;

END TSL_GET_TNETT_COST;

-------------------------------------------------------------------------------------------------------------
-- Mod 364.2, 29-Jan-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
-- Function Name: TSL_DELETE_EXPENSE
-- Mod Ref      : Mod N53
-- Date         : 28-Feb-08
-- Purpose      : This function will deleted the information related to the passed item, from the ITEM_EXP_HEAD,
--                ITEM_EXP_DETAIL, TSL_ITEM_EXP_HEAD and TSL_ITEM_EXP_DETAIL tables
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_EXPENSE(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_item                IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   --
   L_program     VARCHAR2(64) := 'ITEM_EXPENSE_SQL.TSL_DELETE_EXPENSE ';
   L_table       VARCHAR2(65);
   L_exp_type    ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE;
   RECORD_LOCKED EXCEPTION;
   PRAGMA EXCEPTION_INIT(RECORD_LOCKED, -54);

   --This cursor will lock the information on the table TSL_ITEM_EXP_DETAIL, for the passed Item
   CURSOR C_LOCK_FUT_EXP_DTL is
   select 'x'
     from tsl_item_exp_detail td
    where td.item = I_item
   for update nowait;

   --This cursor will lock the information on the table TSL_ITEM_EXP_HEAD, for the passed Item
   CURSOR C_LOCK_FUT_EXP_HDR is
   select 'x'
     from tsl_item_exp_head th
    where th.item = I_item
   for update nowait;

   --This cursor will lock the information on the table ITEM_EXP_DETAIL, for the passed Item
   CURSOR C_LOCK_EXP_DTL is
   select 'x'
     from item_exp_detail ied
    where ied.item = I_item
   for update nowait;

   --This cursor will lock the information on the table ITEM_EXP_HEAD, for the passed Item
   CURSOR C_LOCK_EXP_HDR is
   select 'x'
     from item_exp_head ieh
    where ieh.item = I_item
   for update nowait;

BEGIN
    -- Check if input parameter is NULL
       if I_item is NULL then
             O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                                    NULL,
                                                    L_program,
                                                    NULL);
             return FALSE;
       else
       --
          L_table := 'TSL_ITEM_EXP_DETAIL';
          --
          --Opening the cursor C_LOCK_FUT_EXP_DTL
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_FUT_EXP_DTL',
                           'TSL_ITEM_EXP_DETAIL',
                           'ITEM: ' || I_item);
          open C_LOCK_FUT_EXP_DTL;
          --Closing the cursor C_LOCK_FUT_EXP_DTL
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_FUT_EXP_DTL',
                           'TSL_ITEM_EXP_DETAIL',
                           'ITEM: ' || I_item);
          close C_LOCK_FUT_EXP_DTL;
          --
          --Delete records from the TSL_ITEM_EXP_DETAIL table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           'TSL_ITEM_EXP_DETAIL',
                           'ITEM: ' || I_item);
          delete from tsl_item_exp_detail td
                where td.item = I_item;
          --
          --
          L_table := 'TSL_ITEM_EXP_HEAD';
          --
          --Opening the cursor C_LOCK_FUT_EXP_HDR
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_FUT_EXP_HDR',
                           'TSL_ITEM_EXP_HEAD',
                           'ITEM: ' || I_item);
          open C_LOCK_FUT_EXP_HDR;
          --Closing the cursor C_LOCK_FUT_EXP_HDR
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_FUT_EXP_HDR',
                           'TSL_ITEM_EXP_HEAD',
                           'ITEM: ' || I_item);
          close C_LOCK_FUT_EXP_HDR;
          --
          --Delete records from the TSL_ITEM_EXP_HEAD table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           'TSL_ITEM_EXP_HEAD',
                           'ITEM: ' || I_item);
          delete from tsl_item_exp_head th
                where th.item = I_item;
          --
          --
          L_table := 'ITEM_EXP_DETAIL';
          --
          --Opening the cursor C_LOCK_EXP_DTL
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_EXP_DTL',
                           'ITEM_EXP_DETAIL',
                           'ITEM: ' || I_item);
          open C_LOCK_EXP_DTL;
          --Closing the cursor C_LOCK_EXP_DTL
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_EXP_DTL',
                           'ITEM_EXP_DETAIL',
                           'ITEM: ' || I_item);
          close C_LOCK_EXP_DTL;
          --
          --Delete records from the ITEM_EXP_DETAIL table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           'ITEM_EXP_DETAIL',
                           'ITEM: ' || I_item);
          delete from item_exp_detail ied
                where ied.item = I_item;
          --
          --
          L_table := 'ITEM_EXP_HEAD';
          --
          --Opening the cursor C_LOCK_EXP_HDR
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_EXP_HDR',
                           'ITEM_EXP_HEAD',
                           'ITEM: ' || I_item);
          open C_LOCK_EXP_HDR;
          --Closing the cursor C_LOCK_EXP_HDR
          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_EXP_HDR',
                           'ITEM_EXP_HEAD',
                           'ITEM: ' || I_item);
          close C_LOCK_EXP_HDR;
          --
          --Delete records from the ITEM_EXP_HEAD table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           'ITEM_EXP_HEAD',
                           'ITEM: ' || I_item);
          delete from item_exp_head ieh
                where ieh.item = I_item;
          --
      end if;
      --
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
                                               TO_CHAR(SQLCODE));
         return FALSE;

END TSL_DELETE_EXPENSE;

-------------------------------------------------------------------------------------------------------------
-- Mod 339, 07-Oct-2010, Vivek Sharma, Vivek.Sharma@in.tesco.com
-- Function Name: TSL_GET_EXP_DEFAULT
-- Mod Ref      : Mod 339
-- Date         : 07-Oct-2010
-- Purpose      : This is a new function which will be used to fetch discharge port, supplier currency indicator
--                and tolerance percent values from the table TSL_EXPENSE_DEFAULT.
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EXP_DEFAULT (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_discharge_port IN OUT TSL_EXPENSE_DEFAULT.DISCHARGE_PORT%TYPE,
                              O_supp_curr_ind  IN OUT TSL_EXPENSE_DEFAULT.SUPP_CURR_IND%TYPE,
                              O_tolerance_pct  IN OUT TSL_EXPENSE_DEFAULT.TOLERANCE_PERCENT%TYPE,
                              I_dept           IN     TSL_EXPENSE_DEFAULT.DEPT%TYPE,
                              I_class          IN     TSL_EXPENSE_DEFAULT.CLASS%TYPE,
                              I_subclass       IN     TSL_EXPENSE_DEFAULT.SUBCLASS%TYPE)
   RETURN BOOLEAN IS
   L_program     VARCHAR2(64) := 'ITEM_EXPENSE_SQL.TSL_GET_EXP_DEFAULT';

   /* This cursor will fetch the discharge port, supplier currency indicator and tolerance
   *  information.
   */
   CURSOR C_GET_EXP_DEFAULT is
   select discharge_port,
          supp_curr_ind,
          tolerance_percent
     from TSL_EXPENSE_DEFAULT
    where dept = I_dept
      and class = I_class
      and subclass = I_subclass;
BEGIN
   O_supp_curr_ind := 'N';
   SQL_LIB.SET_MARK('OPEN', 'C_GET_EXP_DEFAULT', 'TSL_EXPENSE_DEFAULT', NULL);
   OPEN C_GET_EXP_DEFAULT;

   SQL_LIB.SET_MARK('FETCH', 'C_GET_EXP_DEFAULT', 'TSL_EXPENSE_DEFAULT', NULL);
   fetch C_GET_EXP_DEFAULT into O_discharge_port, O_supp_curr_ind, O_tolerance_pct;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_EXP_DEFAULT', 'TSL_EXPENSE_DEFAULT', NULL);
   close C_GET_EXP_DEFAULT;

   return TRUE;
EXCEPTION
    when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;

END TSL_GET_EXP_DEFAULT;
--------------------------------------------------------------------------------------------------------

-- Mod 339, 07-Oct-2010, Vivek Sharma, Vivek.Sharma@in.tesco.com
-- Function Name: TSL_GET_EXP_DEFAULT
-- Mod Ref      : Mod 339
-- Date         : 07-Oct-2010
-- Purpose      : This is a new function which will be used to fetch Expense exception for a Comp Id from
--                table TSL_EXP_COMP_EXCEPTION.
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EXP_COMP_EXCEPTION (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     I_dept           IN     ITEM_MASTER.DEPT%TYPE,
                                     I_class          IN     ITEM_MASTER.CLASS%TYPE,
                                     I_subclass       IN     ITEM_MASTER.SUBCLASS%TYPE,
                                     I_comp_id        IN     TSL_EXP_COMP_EXCEPTION.COMP_ID%TYPE,
                                     O_comp_exp       IN OUT BOOLEAN)
   RETURN BOOLEAN IS
   L_program     VARCHAR2(64) := 'ITEM_EXPENSE_SQL.TSL_GET_EXP_COMP_EXCEPTION';
   L_dummy       VARCHAR2(1) := '';
   /* Cursor to fetch the record */

   CURSOR C_GET_ITEM_EXP_COMPEXCEP is
   select 'x'
     from tsl_exp_comp_exception
    where dept = I_dept
      and class = I_class
      and subclass = I_subclass
      and comp_id = I_comp_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_GET_ITEM_EXP_COMPEXCEP', 'TSL_EXP_COMP_EXCEPTION', NULL);
   OPEN C_GET_ITEM_EXP_COMPEXCEP;

   SQL_LIB.SET_MARK('FETCH', 'C_GET_ITEM_EXP_COMPEXCEP', 'TSL_EXP_COMP_EXCEPTION', NULL);
   fetch C_GET_ITEM_EXP_COMPEXCEP into L_dummy;

   if c_get_item_exp_compexcep%NOTFOUND then
      O_comp_exp := FALSE;
   else
      O_comp_exp := TRUE;
   end if;


   SQL_LIB.SET_MARK('CLOSE', 'C_GET_ITEM_EXP_COMPEXCEP', 'TSL_EXP_COMP_EXCEPTION', NULL);
   close C_GET_ITEM_EXP_COMPEXCEP;

   return TRUE;
EXCEPTION
    when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;

END TSL_GET_EXP_COMP_EXCEPTION;
--------------------------------------------------------------------------------------------------------
-- Function Name: TSL_CHK_DISCHARGE_PORT
-- Mod Ref      : CR 339
-- Date         : 07-Oct-10
-- Purpose      : It will check the existense of the Discharge port in table EXP_PROF_HEAD for supplier
--                as fetched from TSL_EXPENSE_DEFAULT table.
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_DISCHARGE_PORT (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_discharge_port        IN OUT EXP_PROF_HEAD.DISCHARGE_PORT%TYPE,
                                 I_supplier              IN     SUPS.SUPPLIER%TYPE,
                                 I_discharge_port_chk    OUT    VARCHAR2)
   RETURN BOOLEAN IS
   L_program     VARCHAR2(64) := 'ITEM_EXPENSE_SQL.TSL_CHK_DISCHARGE_PORT';
   L_exists       VARCHAR2(1) := 'N';
   /* Cursor to fetch the record */

   CURSOR C_TSL_GET_DISCH_PORT is
   select 'X'
   from exp_prof_head
   where module = 'SUPP'
         and key_value_1 = I_supplier
         and discharge_port = I_discharge_port;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_TSL_GET_DISCH_PORT', 'EXP_PROF_HEAD', NULL);
   OPEN C_TSL_GET_DISCH_PORT;

   SQL_LIB.SET_MARK('FETCH', 'C_TSL_GET_DISCH_PORT', 'EXP_PROF_HEAD', NULL);
   fetch C_TSL_GET_DISCH_PORT into L_exists;

   if L_exists = 'X' then
      I_discharge_port_chk := 'Y';
   else
      I_discharge_port_chk := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_TSL_GET_DISCH_PORT', 'EXP_PROF_HEAD', NULL);
   close C_TSL_GET_DISCH_PORT;

   return TRUE;
EXCEPTION
    when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;

END TSL_CHK_DISCHARGE_PORT;
--------------------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_EXP_HEAD_DATES
-- Mod By       : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Ref      : CR 339
-- Date         : 07-Oct-10
-- Purpose      : This function will return the active date and future effective date from TSL_ITEM_EXP_HEAD table
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EXP_HEAD_DATES (O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_active_date         IN OUT TSL_ITEM_EXP_HEAD.ACTIVE_DATE%TYPE,
                                 O_future_eff_date     IN OUT TSL_ITEM_EXP_HEAD.ACTIVE_DATE%TYPE,
                                 I_item                IN     ITEM_MASTER.ITEM%TYPE,
                                 I_supplier            IN     SUPS.SUPPLIER%TYPE,
                                 I_item_exp_seq        IN     TSL_ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE,
                                 I_item_exp_type       IN     TSL_ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program     VARCHAR2(64) := 'ITEM_EXPENSE_SQL.TSL_GET_EXP_HEAD_DATES';
   /*L_active_date        TSL_ITEM_EXP_HEAD.ACTIVE_DATE%TYPE := null;*/

   cursor C_GET_ACTIVE_DATE is
   	  select tieh.active_date
   	    from tsl_item_exp_head tieh
   	   where tieh.item = I_item
   	     and tieh.supplier = I_supplier
   	     and tieh.item_exp_seq = I_item_exp_seq
   	     and tieh.item_exp_type = I_item_exp_type
   	     and tieh.active_date <= get_vdate()
   	order by tieh.active_date desc;

   cursor C_GET_FUTURE_EFF_DATE is
   	  select tieh.active_date
   	    from tsl_item_exp_head tieh
   	   where tieh.item = I_item
   	     and tieh.supplier = I_supplier
   	     and tieh.item_exp_seq = I_item_exp_seq
   	     and tieh.item_exp_type = I_item_exp_type
   	     and tieh.active_date > get_vdate()
   	order by tieh.active_date asc;

BEGIN

    SQL_LIB.SET_MARK('OPEN',
                     'C_GET_ACTIVE_DATE',
                     'TSL_ITEM_EXP_HEAD',
                     'ITEM: ' || I_item);
    open C_GET_ACTIVE_DATE ;
    ---
    SQL_LIB.SET_MARK('FETCH',
                     'C_GET_ACTIVE_DATE',
                     'TSL_ITEM_EXP_HEAD',
                     'ITEM: ' || I_item);
    fetch C_GET_ACTIVE_DATE into O_active_date;
    ---
    SQL_LIB.SET_MARK('CLOSE',
                     'C_GET_ACTIVE_DATE',
                     'TSL_ITEM_EXP_HEAD',
                     'ITEM: ' || I_item);
    close C_GET_ACTIVE_DATE;
    ---
    SQL_LIB.SET_MARK('OPEN',
                     'C_GET_FUTURE_EFF_DATE',
                     'TSL_ITEM_EXP_HEAD',
                     'ITEM: ' || I_item);
    open C_GET_FUTURE_EFF_DATE;
    ---
    SQL_LIB.SET_MARK('FETCH',
                     'C_GET_FUTURE_EFF_DATE',
                     'TSL_ITEM_EXP_HEAD',
                     'ITEM: ' || I_item);
    fetch C_GET_FUTURE_EFF_DATE into O_future_eff_date;
    ---
    SQL_LIB.SET_MARK('CLOSE',
                     'C_GET_FUTURE_EFF_DATE',
                     'TSL_ITEM_EXP_HEAD',
                     'ITEM: ' || I_item);
    close C_GET_FUTURE_EFF_DATE;
    return TRUE;

EXCEPTION
    when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
END TSL_GET_EXP_HEAD_DATES;
----------------------------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_EXP_DETL_FIELDS
-- Mod By       : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Ref      : CR 339
-- Date         : 07-Oct-10
-- Purpose      : This function will return the active date, future effective date, comp rate from TSL_ITEM_EXP_DETAIL table
----------------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_EXP_DETL_FIELDS (O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_active_date         IN OUT TSL_ITEM_EXP_DETAIL.ACTIVE_DATE%TYPE,
                                  O_future_eff_date     IN OUT TSL_ITEM_EXP_DETAIL.ACTIVE_DATE%TYPE,
                                  O_comp_rate           IN OUT TSL_ITEM_EXP_DETAIL.COMP_RATE%TYPE,
                                  O_future_rsn_code     IN OUT TSL_ITEM_EXP_DETAIL.TSL_COST_REASON_CODE%TYPE,
                                  I_item                IN     ITEM_MASTER.ITEM%TYPE,
                                  I_supplier            IN     SUPS.SUPPLIER%TYPE,
                                  I_item_exp_seq        IN     TSL_ITEM_EXP_DETAIL.ITEM_EXP_SEQ%TYPE,
                                  I_item_exp_type       IN     TSL_ITEM_EXP_DETAIL.ITEM_EXP_TYPE%TYPE,
                                  I_comp_id             IN     TSL_ITEM_EXP_DETAIL.COMP_ID%TYPE)
   RETURN BOOLEAN IS

      L_program     VARCHAR2(64) := 'ITEM_EXPENSE_SQL.TSL_GET_EXP_DETL_FIELDS';

   cursor C_GET_ACTIVE_DATE is
   	  select tied.active_date
   	    from tsl_item_exp_detail tied
   	   where tied.item = I_item
   	     and tied.supplier = I_supplier
   	     and tied.item_exp_seq = I_item_exp_seq
   	     and tied.item_exp_type = I_item_exp_type
   	     and tied.comp_id = I_comp_id
   	     and tied.active_date <= get_vdate()
   	order by tied.active_date desc;

   cursor C_GET_FUTURE_EFF_DATE is
   	  select tied.active_date
   	    from tsl_item_exp_detail tied
   	   where tied.item = I_item
   	     and tied.supplier = I_supplier
   	     and tied.item_exp_seq = I_item_exp_seq
   	     and tied.item_exp_type = I_item_exp_type
   	     and tied.comp_id = I_comp_id
   	     and tied.active_date > get_vdate()
   	order by tied.active_date asc;

   cursor C_GET_COMP_RATE is
   	  select tied.comp_rate,
   	         tied.tsl_cost_reason_code
   	    from tsl_item_exp_detail tied
   	   where tied.item = I_item
   	     and tied.supplier = I_supplier
   	     and tied.item_exp_seq = I_item_exp_seq
   	     and tied.item_exp_type = I_item_exp_type
   	     and tied.comp_id = I_comp_id
   	     and tied.active_date > get_vdate()
   	order by tied.active_date asc;

BEGIN

    SQL_LIB.SET_MARK('OPEN',
                     'C_GET_ACTIVE_DATE',
                     'TSL_ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    open C_GET_ACTIVE_DATE ;
    ---
    SQL_LIB.SET_MARK('FETCH',
                     'C_GET_ACTIVE_DATE',
                     'TSL_ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    fetch C_GET_ACTIVE_DATE into O_active_date;
    ---
    SQL_LIB.SET_MARK('CLOSE',
                     'C_GET_ACTIVE_DATE',
                     'TSL_ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    close C_GET_ACTIVE_DATE;
    ---
    SQL_LIB.SET_MARK('OPEN',
                     'C_GET_FUTURE_EFF_DATE',
                     'TSL_ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    open C_GET_FUTURE_EFF_DATE;
    ---
    SQL_LIB.SET_MARK('FETCH',
                     'C_GET_FUTURE_EFF_DATE',
                     'TSL_ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    fetch C_GET_FUTURE_EFF_DATE into O_future_eff_date;
    ---
    SQL_LIB.SET_MARK('CLOSE',
                     'C_GET_FUTURE_EFF_DATE',
                     'TSL_ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    close C_GET_FUTURE_EFF_DATE;
    ---
    SQL_LIB.SET_MARK('OPEN',
                     'C_GET_COMP_RATE',
                     'TSL_ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    open C_GET_COMP_RATE;
    ---
    SQL_LIB.SET_MARK('FETCH',
                     'C_GET_COMP_RATE',
                     'TSL_ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    fetch C_GET_COMP_RATE into O_comp_rate, O_future_rsn_code;
    ---
    SQL_LIB.SET_MARK('CLOSE',
                     'C_GET_FUTURE_EFF_DATE',
                     'TSL_ITEM_EXP_DETAIL',
                     'ITEM: ' || I_item);
    close C_GET_COMP_RATE;
    ---
    return TRUE;

EXCEPTION
    when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
END TSL_GET_EXP_DETL_FIELDS;
----------------------------------------------------------------------------------------------------------------
-- Function Name: TSL_UPD_ITEM_EXP_DETL
-- Mod By       : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
-- Mod Ref      : CR 339
-- Date         : 07-Oct-10
-- Purpose      : This function will update the active date, future effective date and comp rate fields of
--                the table TSL_ITEM_EXP_DETAIL
----------------------------------------------------------------------------------------------------------------
FUNCTION TSL_UPD_ITEM_EXP_DETL (O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_future_eff_date     IN     TSL_ITEM_EXP_DETAIL.ACTIVE_DATE%TYPE,
                                I_future_eff_date_old IN     TSL_ITEM_EXP_DETAIL.ACTIVE_DATE%TYPE,
                                I_comp_rate           IN     TSL_ITEM_EXP_DETAIL.COMP_RATE%TYPE,
                                I_comp_rate_old       IN     TSL_ITEM_EXP_DETAIL.COMP_RATE%TYPE,
                                I_item                IN     ITEM_MASTER.ITEM%TYPE,
                                I_supplier            IN     SUPS.SUPPLIER%TYPE,
                                I_item_exp_seq        IN     TSL_ITEM_EXP_DETAIL.ITEM_EXP_SEQ%TYPE,
                                I_item_exp_type       IN     TSL_ITEM_EXP_DETAIL.ITEM_EXP_TYPE%TYPE,
                                I_comp_currency       IN     TSL_ITEM_EXP_DETAIL.COMP_CURRENCY%TYPE,
                                I_comp_id             IN     TSL_ITEM_EXP_DETAIL.COMP_ID%TYPE,
                                I_cost_reason_code    IN     TSL_ITEM_EXP_DETAIL.TSL_COST_REASON_CODE%TYPE,
                                -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
                                -- DefNBS020176 21-Dec-2010 Chandru Begin
                                I_per_count           IN     TSL_ITEM_EXP_DETAIL.PER_COUNT%TYPE,
                                I_per_count_uom       IN     TSL_ITEM_EXP_DETAIL.PER_COUNT_UOM%TYPE                             -- DefNBS020176 21-Dec-2010 Chandru End
                                -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com End
                                )
   RETURN BOOLEAN IS

   L_program     VARCHAR2(64) := 'ITEM_EXPENSE_SQL.TSL_UPD_ITEM_EXP_DETL';
   L_rec_exist   VARCHAR2(1) := 'N';
   -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
   --DefNBS020176 21-Dec-2010 Chandru Begin
   L_calc_basis         ELC_COMP.CALC_BASIS%TYPE;
   L_per_count          TSL_ITEM_EXP_DETAIL.PER_COUNT%TYPE := NULL;
   L_per_count_uom      TSL_ITEM_EXP_DETAIL.PER_COUNT_UOM%TYPE := NULL;
   --DefNBS020176 21-Dec-2010 Chandru End
   -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com End
   cursor C_GET_RECORD is
   select 'x'
     from tsl_item_exp_detail tied
    where tied.item = I_item
      and tied.supplier = I_supplier
      and tied.item_exp_seq = I_item_exp_seq
      and tied.item_exp_type = I_item_exp_type
      and tied.comp_id = I_comp_id
      and NVL(tied.active_date, '01-JAN-01') = NVL(I_future_eff_date_old, '01-JAN-01')
      and NVL(tied.comp_rate,0) = NVL(I_comp_rate_old,0);
BEGIN
   -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
   -- DefNBS020176 21-Dec-2010 Chandru Begin
	 if ELC_SQL.GET_CALC_BASIS(O_error_message,
                             L_calc_basis,
                             I_comp_id)= FALSE then
      return FALSE;
   end if;
 	 L_per_count_uom := I_per_count_uom;
 	 L_per_count := I_per_count;
   if L_calc_basis = 'S' and L_per_count_uom is NULL then
      L_per_count_uom := 'EA';
   end if;
   if L_calc_basis = 'S' and L_per_count is NULL then
      L_per_count := 1;
   end if;
   -- DefNBS020176 21-Dec-2010 Chandru End
   -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com End
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_RECORD',
                    'TSL_ITEM_EXP_DETAIL',
                    'ITEM: ' || I_item);
   open C_GET_RECORD;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_RECORD',
                    'TSL_ITEM_EXP_DETAIL',
                    'ITEM: ' || I_item);
   fetch C_GET_RECORD into L_rec_exist;

   /*if record exists*/
   if C_GET_RECORD%FOUND = TRUE then
      /*if user is updating the record */
      if I_comp_rate is NOT NULL and I_future_eff_date is NOT NULL then
         update TSL_ITEM_EXP_DETAIL
            set active_date = I_future_eff_date,
                comp_rate = I_comp_rate,
                -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
                --DefNBS019819, 07-Oct-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                tsl_cost_reason_code = I_cost_reason_code
                --DefNBS019819, 07-Oct-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com End
          where item = I_item
            and supplier = I_supplier
            and item_exp_seq = I_item_exp_seq
            and item_exp_type = I_item_exp_type
            and comp_id = I_comp_id
            and active_date = I_future_eff_date_old
            and comp_rate = I_comp_rate_old;

         -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
         --CR338 10-Dec-2010 Chandru Begin
         insert into tsl_item_exp_detail_gtt (item,
                                              supplier,
                                              item_exp_seq,
                                              item_exp_type,
                                              comp_id,
                                              comp_rate,
                                              comp_currency,
                                              active_date,
                                              processed_ind,
                                              tsl_cost_reason_code,
         																		  ins_upd_ind,
         																		  --DefNBS020176 21-Dec-2010 Chandru Begin
         																		  per_count,
         																		  per_count_uom)
         																		  --DefNBS020176 21-Dec-2010 Chandru End
                                      --DefNBS020176a 23-Dec-2010 Chandru Begin
                                      select  I_item,
                                              I_supplier,
                                              I_item_exp_seq,
                                              I_item_exp_type,
                                              I_comp_id,
                                              I_comp_rate_old,
                                              I_comp_currency,
                                              I_future_eff_date_old,
                                              'N',
                                              I_cost_reason_code,
                                              'D',
                                              --DefNBS020176 21-Dec-2010 Chandru Begin
                                              L_per_count,
                                              L_per_count_uom
                                              --DefNBS020176 21-Dec-2010 Chandru End
                                        from tsl_item_exp_detail_gtt gtt
                                       where not exists (select 1
                                                           from tsl_item_exp_detail_gtt gtt2
                                                          where gtt2.item = I_item
                                                            and gtt2.supplier = I_supplier
                                                            and gtt2.item_exp_seq = I_item_exp_seq
                                                            and gtt2.item_exp_type = I_item_exp_type
                                                            and gtt2.comp_id = I_comp_id);
                                       --DefNBS020176a 23-Dec-2010 Chandru End
         insert into tsl_item_exp_detail_gtt (item,
                                              supplier,
                                              item_exp_seq,
                                              item_exp_type,
                                              comp_id,
                                              comp_rate,
                                              comp_currency,
                                              active_date,
                                              processed_ind,
                                              tsl_cost_reason_code,
         																		  ins_upd_ind,
         																		  --DefNBS020176 21-Dec-2010 Chandru Begin
         																		  per_count,
         																		  per_count_uom
         																		  --DefNBS020176 21-Dec-2010 Chandru End
         																		  )
                                       --DefNBS020176a 23-Dec-2010 Chandru Begin
                                       select I_item,
                                              I_supplier,
                                              I_item_exp_seq,
                                              I_item_exp_type,
                                              I_comp_id,
                                              I_comp_rate,
                                              I_comp_currency,
                                              I_future_eff_date,
                                              'N',
                                              I_cost_reason_code,
                                              'I',
                                              --DefNBS020176 21-Dec-2010 Chandru Begin
                                              L_per_count,
                                              L_per_count_uom
                                              --DefNBS020176 21-Dec-2010 Chandru End

                                              --DefNBS020176 21-Dec-2010 Chandru Begin
                                        from tsl_item_exp_detail_gtt gtt
                                       where not exists (select 1
                                                           from tsl_item_exp_detail_gtt gtt2
                                                          where gtt2.item = I_item
                                                            and gtt2.supplier = I_supplier
                                                            and gtt2.item_exp_seq = I_item_exp_seq
                                                            and gtt2.item_exp_type = I_item_exp_type
                                                            and gtt2.comp_id = I_comp_id);
                                       --DefNBS020176a 23-Dec-2010 Chandru End
      --CR338 10-Dec-2010 Chandru End
      -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com End
      /*if user is deleting the record*/
      elsif I_comp_rate is NULL and I_future_eff_date is NULL then
         delete
           from TSL_ITEM_EXP_DETAIL
          where item = I_item
            and supplier = I_supplier
            and item_exp_seq = I_item_exp_seq
            and item_exp_type = I_item_exp_type
            and comp_id = I_comp_id
            and active_date = I_future_eff_date_old
            and comp_rate = I_comp_rate_old;
          -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
         --CR338 10-Dec-2010 Chandru Begin
         insert into tsl_item_exp_detail_gtt (item,
                                              supplier,
                                              item_exp_seq,
                                              item_exp_type,
                                              comp_id,
                                              comp_rate,
                                              comp_currency,
                                              active_date,
                                              processed_ind,
                                              tsl_cost_reason_code,
         																		  ins_upd_ind,
         																		  --DefNBS020176 21-Dec-2010 Chandru Begin
         																		  per_count,
         																		  per_count_uom
         																		  --DefNBS020176 21-Dec-2010 Chandru End
         																		  )
         															 --DefNBS020176 23-Dec-2010 Chandru Begin
                                       select I_item,
                                              I_supplier,
                                              I_item_exp_seq,
                                              I_item_exp_type,
                                              I_comp_id,
                                              I_comp_rate_old,
                                              I_comp_currency,
                                              I_future_eff_date_old,
                                              'N',
                                              I_cost_reason_code,
                                              'D',
                                              --DefNBS020176 21-Dec-2010 Chandru Begin
                                              L_per_count,
                                              L_per_count_uom
                                              --DefNBS020176 21-Dec-2010 Chandru Begin
                                        from tsl_item_exp_detail_gtt gtt
                                       where not exists (select 1
                                                           from tsl_item_exp_detail_gtt gtt2
                                                          where gtt2.item = I_item
                                                            and gtt2.supplier = I_supplier
                                                            and gtt2.item_exp_seq = I_item_exp_seq
                                                            and gtt2.item_exp_type = I_item_exp_type
                                                            and gtt2.comp_id = I_comp_id);
                                       --DefNBS020176a 23-Dec-2010 Chandru End
      --CR338 10-Dec-2010 Chandru End
      end if;
      -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com End


   else /*if no record found for cursor C_GET_RECORD */
   	  -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
      --DefNBS020176 21-Dec-2010 Chandru Begin
      -- commented the below statement
   	  --NULL;
   	  --DefNBS020176 21-Dec-2010 Chandru End
      -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com End
      insert into TSL_ITEM_EXP_DETAIL
             (item,
              supplier,
              item_exp_seq,
              item_exp_type,
              comp_id,
              comp_rate,
              comp_currency,
              active_date,
              processed_ind,
              tsl_cost_reason_code,
              -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
              --DefNBS020176 21-Dec-2010 Chandru Begin
              per_count,
              per_count_uom
              --DefNBS020176 21-Dec-2010 Chandru End
              -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com End
              )
       values
             (I_item,
              I_supplier,
              I_item_exp_seq,
              I_item_exp_type,
              I_comp_id,
              I_comp_rate,
              I_comp_currency,
              I_future_eff_date,
              'N',
              I_cost_reason_code,
              --DefNBS020176 21-Dec-2010 Chandru Begin
              L_per_count,
              L_per_count_uom
              --DefNBS020176 21-Dec-2010 Chandru End
              );
         -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
         --CR338 10-Dec-2010 Chandru Begin
         insert into tsl_item_exp_detail_gtt (item,
                                              supplier,
                                              item_exp_seq,
                                              item_exp_type,
                                              comp_id,
                                              comp_rate,
                                              comp_currency,
                                              active_date,
                                              processed_ind,
                                              tsl_cost_reason_code,
         																		  ins_upd_ind,
         																		  --DefNBS020176 21-Dec-2010 Chandru Begin
         																		  per_count,
         																		  per_count_uom
         																		  --DefNBS020176 21-Dec-2010 Chandru End
         																		  )
         															 --DefNBS020176a 23-Dec-2010 Chandru Begin
                                       select I_item,
                                              I_supplier,
                                              I_item_exp_seq,
                                              I_item_exp_type,
                                              I_comp_id,
                                              I_comp_rate,
                                              I_comp_currency,
                                              I_future_eff_date,
                                              'N',
                                              I_cost_reason_code,
                                              'I',
                                              --DefNBS020176 21-Dec-2010 Chandru Begin
                                              L_per_count,
                                              L_per_count_uom
                                              --DefNBS020176 21-Dec-2010 Chandru End
                                        from tsl_item_exp_detail_gtt gtt
                                       where not exists (select 1
                                                           from tsl_item_exp_detail_gtt gtt2
                                                          where gtt2.item = I_item
                                                            and gtt2.supplier = I_supplier
                                                            and gtt2.item_exp_seq = I_item_exp_seq
                                                            and gtt2.item_exp_type = I_item_exp_type
                                                            and gtt2.comp_id = I_comp_id);
                                       --DefNBS020176a 23-Dec-2010 Chandru End

   --CR338 10-Dec-2010 Chandru End
   -- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.End
   end if;
   return TRUE;
   ---

EXCEPTION
    when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
END TSL_UPD_ITEM_EXP_DETL;
----------------------------------------------------------------------------------------------------------------
-- Function Name: TSL_GET_ITEMS_TO_UPDATE
-- Purpose      : To get the list of all simple packs to explode expenses.
--------------------------------------------------------------------------------------------
-- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
--CR332, 17-DEC-2010, Commenting accenture functions
/*
FUNCTION TSL_GET_ITEMS_TO_UPDATE(O_error_message     IN OUT VARCHAR2,
                                 I_item              IN     ITEM_MASTER.ITEM%TYPE,
                                 I_supplier          IN     SUPS.SUPPLIER%TYPE,
                                 I_change_level      IN     VARCHAR2,
                                 I_styleref_code     IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                                 O_item_rec             OUT TSL_OBJ_ITEM_TBL)
   return BOOLEAN is
   L_program  VARCHAR2(62) := 'ITEM_EXPENSE_SQL.TSL_GET_ITEMS_TO_UPDATE';
BEGIN
   If I_change_level = 'SREFCODE' then
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_SREF',
                       'ITEM_MASTER || ITEM_SUPPLIER',
                       NULL);
      select TSL_OBJ_ITEM_REC(im.item,
                              isup.supplier)
        bulk collect
        into O_item_rec
        from item_master im,
             item_supplier isup
       where im.item = isup.item
         and im.item_desc_secondary = I_styleref_code
         and isup.supplier = I_supplier;
   elsif I_change_level = 'ITEM1' then
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_LEVEL1 ',
                       'ITEM_MASTER || ITEM_SUPPLIER || PACKITEM',
                       NULL);
      select TSL_OBJ_ITEM_REC(p.pack_no,
                              isup.supplier)
        bulk collect
        into O_item_rec
        from item_master im,
             packitem p,
             item_supplier isup,
             item_master im2
       where im.item = p.item
         and im.item = isup.item
         and isup.supplier = I_supplier
         and im.item_parent in (select item
                                  from item_master
                                 where item = I_item )
         and im2.item = p.pack_no
         and im2.simple_pack_ind = 'Y';
   elsif  I_change_level = 'ITEM2' then
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_LEVEL2 ',
                       'ITEM_MASTER || ITEM_SUPPLIER || PACKITEM',
                       NULL);
      select TSL_OBJ_ITEM_REC(p.pack_no,
                              isup.supplier)
        bulk collect
        into O_item_rec
        from item_master im,
             packitem p,
             item_supplier isup,
             item_master im2
       where im.item = p.item
         and im.item = isup.item
         and isup.supplier = I_supplier
         and im.item = I_Item
         and im2.item = p.pack_no
         and im2.simple_pack_ind = 'Y';
  -- DefNBS00019971 03-Dec-2010/Accenture Sriram Gopalkrishnan Sriram.Gopalkrishnan@in.tesco.com Begin
   else
      O_item_rec := TSL_OBJ_ITEM_TBL(NULL,NULL);
  -- DefNBS00019971 03-Dec-2010/Accenture Sriram Gopalkrishnan Sriram.Gopalkrishnan@in.tesco.com End
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_GET_ITEMS_TO_UPDATE;
----------------------------------------------------------------------------------------------------------------
-- Procedure Name: TSL_INS_EXPENSE_HDR
-- Purpose       : To insert or update expense headers into ITEM_EXP_HEAD
---------------------------------------------------------------------------------------------
PROCEDURE TSL_INS_EXPENSE_HDR(O_error_message     IN OUT VARCHAR2,
                             I_slctd_item        IN     ITEM_MASTER.ITEM%TYPE,
                             I_copyto_item       IN     ITEM_MASTER.ITEM%TYPE,
                             I_supplier          IN     SUPS.SUPPLIER%TYPE)
   is
   L_item_cnt int;
   L_program  VARCHAR2(62) := 'ITEM_EXPENSE_SQL.TSL_INS_EXPENSE_HDR';
   cursor C_GET_SLCTD_ITEM_HDR(P_SLCTD_ITEM VARCHAR2,
                               P_SUPPLIER   VARCHAR2)
      is
      select item,
             supplier,
             item_exp_type,
             item_exp_seq,
             origin_country_id,
             zone_id,
             lading_port,
             discharge_port,
             zone_group_id,
             base_exp_ind,
             create_datetime,
             last_update_datetime,
             last_update_id
        from item_exp_head
       where item     = P_SLCTD_ITEM
         and supplier = P_SUPPLIER;
BEGIN
   for i in C_GET_SLCTD_ITEM_HDR(I_slctd_item,I_supplier )
   LOOP
      select count(1)
        into L_item_cnt
        from item_exp_head
       where item          = I_copyto_item
         and supplier      = i.supplier
         and item_exp_type = i.item_exp_type
         and item_exp_seq  = i.item_exp_seq;
         if L_item_cnt = 0 then
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'ITEM_EXP_HEAD',
                             NULL);
            insert
              into item_exp_head
                           (item,
                            supplier,
                            item_exp_type,
                            item_exp_seq,
                            origin_country_id,
                            zone_id,
                            lading_port,
                            discharge_port,
                            zone_group_id,
                            base_exp_ind,
                            create_datetime,
                            last_update_datetime,
                            last_update_id)
                     values (I_copyto_item,
                             i.supplier,
                             i.item_exp_type,
                             i.item_exp_seq,
                             i.origin_country_id,
                             i.zone_id,
                             i.lading_port,
                             i.discharge_port,
                             i.zone_group_id,
                             i.base_exp_ind,
                             sysdate,
                             sysdate,
                             user);
         else
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ITEM_EXP_HEAD',
                             NULL);
            update item_exp_head
               set origin_country_id    = i.origin_country_id,
                   zone_id              = i.zone_id,
                   lading_port          = i.lading_port,
                   discharge_port       = i.discharge_port,
                   zone_group_id        = i.zone_group_id,
                   base_exp_ind         = i.base_exp_ind,
                   create_datetime      = sysdate,
                   last_update_datetime = sysdate,
                   last_update_id       = user
             where item          = I_copyto_item
               and supplier      = i.supplier
               and item_exp_type = i.item_exp_type
               and item_exp_seq  = i.item_exp_seq;
         end if;
   END LOOP;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END TSL_INS_EXPENSE_HDR;
----------------------------------------------------------------------------------------------------------------
-- Procedure Name: TSL_INS_EXPENSE_TSLHDR
-- Purpose       : To insert or update expense headers into TSL_ITEM_EXP_HEAD
---------------------------------------------------------------------------------------------
PROCEDURE TSL_INS_EXPENSE_TSLHDR(O_error_message     IN OUT VARCHAR2,
                                I_slctd_item        IN     ITEM_MASTER.ITEM%TYPE,
                                I_copyto_item       IN     ITEM_MASTER.ITEM%TYPE,
                                I_supplier          IN     SUPS.SUPPLIER%TYPE)
   is
   L_item_cnt int;
   L_program  VARCHAR2(62) := 'ITEM_EXPENSE_SQL.TSL_INS_EXPENSE_TSLHDR';
   cursor C_GET_SLCTD_TSL_ITEM_HDR(P_SLCTD_ITEM VARCHAR2,
                                   P_SUPPLIER   VARCHAR2)
      is
      select item,
             supplier,
             item_exp_seq,
             item_exp_type,
             active_date,
             processed_ind
        from tsl_item_exp_head
       where item     = P_SLCTD_ITEM
         and supplier = P_SUPPLIER;
BEGIN
   for k in C_GET_SLCTD_TSL_ITEM_HDR(I_slctd_item, I_supplier)
   LOOP
      select count(1)
        into L_item_cnt
        from tsl_item_exp_head
       where item          = I_copyto_item
         and supplier      = k.supplier
         and item_exp_type = k.item_exp_type
         and item_exp_seq  = k.item_exp_seq
         and active_date   = k.active_date;
      if L_item_cnt = 0 then
         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'TSL_ITEM_EXP_HEAD',
                          NULL);
         insert
           into tsl_item_exp_head
                            (item,
                             supplier,
                             item_exp_seq,
                             item_exp_type,
                             active_date,
                             processed_ind)
                     values (I_copyto_item,
                             I_supplier,
                             k.item_exp_seq,
                             k.item_exp_type,
                             k.active_date,
                             k.processed_ind);
      else
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'TSL_ITEM_EXP_HEAD',
                          NULL);
         update tsl_item_exp_head
            set processed_ind = k.processed_ind
          where item          = I_copyto_item
            and supplier      = I_supplier
            and item_exp_type = k.item_exp_type
            and item_exp_seq  = k.item_exp_seq
            and active_date   = k.active_date;
      end if;
   END LOOP;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END TSL_INS_EXPENSE_TSLHDR;
----------------------------------------------------------------------------------------------------------------
-- Procedure Name: TSL_INS_EXPENSE_DTL
-- Purpose       : To insert or update expense headers into ITEM_EXP_DETAIL
---------------------------------------------------------------------------------------------
PROCEDURE TSL_INS_EXPENSE_DTL(O_error_message     IN OUT VARCHAR2,
                             I_slctd_item        IN     ITEM_MASTER.ITEM%TYPE,
                             I_copyto_item       IN     ITEM_MASTER.ITEM%TYPE,
                             I_supplier          IN     SUPS.SUPPLIER%TYPE)
   is
   L_item_cnt int;
   L_program  VARCHAR2(62) := 'ITEM_EXPENSE_SQL.TSL_INS_EXPENSE_DTL';
   cursor C_GET_SLCTD_ITEMEXP_DTLS(P_SLCTD_ITEM VARCHAR2,
                                   P_SUPPLIER   VARCHAR2)
      is
      select item,
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
             create_datetime,
             last_update_datetime,
             last_update_id
       from item_exp_detail
      where item     = P_SLCTD_ITEM
        and supplier = P_SUPPLIER;
BEGIN
   for i in C_GET_SLCTD_ITEMEXP_DTLS(I_slctd_item, I_supplier)
   LOOP
      select count(1)
        into L_item_cnt
        from item_exp_detail
       where item          = I_copyto_item
         and supplier      = i.supplier
         and item_exp_type = i.item_exp_type
         and item_exp_seq  = i.item_exp_seq
         and comp_id       = i.comp_id;
      if L_item_cnt = 0 then
         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'ITEM_EXP_DETAIL',
                          NULL);
         insert
           into item_exp_detail
                         (item,
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
                          create_datetime,
                          last_update_datetime,
                          last_update_id)
                  values (I_copyto_item,
                          i.supplier,
                          i.item_exp_type,
                          i.item_exp_seq,
                          i.comp_id,
                          i.cvb_code,
                          i.comp_rate,
                          i.comp_currency,
                          i.per_count,
                          i.per_count_uom,
                          i.est_exp_value,
                          i.nom_flag_1,
                          i.nom_flag_2,
                          i.nom_flag_3,
                          i.nom_flag_4,
                          i.nom_flag_5,
                          i.display_order,
                          sysdate,
                          sysdate,
                          user);
      else
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ITEM_EXP_DETAIL',
                          NULL);
         update item_exp_detail
            set cvb_code             = i.cvb_code,
                comp_rate            = i.comp_rate,
                comp_currency        = i.comp_currency,
                per_count            = i.per_count,
                per_count_uom        = i.per_count_uom,
                est_exp_value        = i.est_exp_value,
                nom_flag_1           = i.nom_flag_1,
                nom_flag_2           = i.nom_flag_2,
                nom_flag_3           = i. nom_flag_3,
                nom_flag_4           = i.nom_flag_4,
                nom_flag_5           = i.nom_flag_5,
                display_order        = i.display_order,
                create_datetime      = i.create_datetime,
                last_update_datetime = sysdate,
                last_update_id       = user
          where item          = I_copyto_item
            and supplier      = i.supplier
            and item_exp_type = i.item_exp_type
            and item_exp_seq  = i.item_exp_seq
            and comp_id       = i.comp_id;
      end if;
   END LOOP;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END TSL_INS_EXPENSE_DTL;
----------------------------------------------------------------------------------------------------------------
-- Procedure Name: TSL_INS_EXPENSE_TSLDTL
-- Purpose       : To insert or update expense headers TSL_ITEM_EXP_DETAIL
---------------------------------------------------------------------------------------------
PROCEDURE TSL_INS_EXPENSE_TSLDTL(O_error_message     IN OUT VARCHAR2,
                                I_slctd_item        IN     ITEM_MASTER.ITEM%TYPE,
                                I_copyto_item       IN     ITEM_MASTER.ITEM%TYPE,
                                I_supplier          IN     SUPS.SUPPLIER%TYPE)
   is
   L_item_cnt int;
   L_program  VARCHAR2(62) := 'ITEM_EXPENSE_SQL.TSL_INS_EXPENSE_TSLDTL';
   cursor C_GET_SLCTD_TSL_ITEMEXP_DTLS(P_SLCTD_ITEM VARCHAR2,
                                       P_SUPPLIER   VARCHAR2)
      is
      select item,
             supplier,
             item_exp_seq,
             item_exp_type,
             comp_id,
             comp_rate,
             comp_currency,
             per_count,
             per_count_uom,
             active_date,
             processed_ind
        from tsl_item_exp_detail
       where item     = P_SLCTD_ITEM
         and supplier = P_SUPPLIER;
BEGIN
   for k in C_GET_SLCTD_TSL_ITEMEXP_DTLS(I_slctd_item, I_supplier)
   LOOP
      select count(1)
        into L_item_cnt
        from tsl_item_exp_detail
       where item          = I_copyto_item
         and supplier      = k.supplier
         and item_exp_type = k.item_exp_type
         and item_exp_seq  = k.item_exp_seq
         and comp_id       = k.comp_id
         and active_date   = k.active_date;
      if L_item_cnt = 0 then
         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'TSL_ITEM_EXP_DETAIL',
                          NULL);
         insert
           into tsl_item_exp_detail
                              (item,
                             supplier,
                             item_exp_seq,
                             item_exp_type,
                             comp_id,
                             comp_rate,
                             comp_currency,
                             per_count,
                             per_count_uom,
                             active_date,
                             processed_ind)
                     values (I_copyto_item,
                             k.supplier,
                             k.item_exp_seq,
                             k.item_exp_type,
                             k.comp_id,
                             k.comp_rate,
                             k.comp_currency,
                             k.per_count,
                             k.per_count_uom,
                             k.active_date,
                             k.processed_ind);
      else
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'TSL_ITEM_EXP_DETAIL',
                          NULL);
         update tsl_item_exp_detail
            set comp_rate      = k.comp_rate,
                comp_currency  = k.comp_currency,
                per_count      = k.per_count,
                per_count_uom  = k.per_count_uom,
                processed_ind  = k.processed_ind
          where item          = I_copyto_item
            and supplier      = k.supplier
            and item_exp_type = k.item_exp_type
            and item_exp_seq  = k.item_exp_seq
            and comp_id       = k.comp_id
            and active_date   = k.active_date;
      end if;
   END LOOP;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END TSL_INS_EXPENSE_TSLDTL;
-----------------------------------------------------------------------------------------------------------------------
-- Function Name: TSL_INS_ALL_EXPENSES
-- Purpose      : To insert or update all simple packs with expenses.
---------------------------------------------------------------------------------------------
FUNCTION TSL_INS_ALL_EXPENSES(O_error_message     IN OUT VARCHAR2,
                              I_item              IN     ITEM_MASTER.ITEM%TYPE,
                              I_supplier          IN     SUPS.SUPPLIER%TYPE,
                              I_change_level      IN     VARCHAR2,
                              I_styleref_code     IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                              I_slctd_item        IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is
   L_item_rec TSL_OBJ_ITEM_TBL;
   L_program  VARCHAR2(62) := 'ITEM_EXPENSE_SQL.TSL_GET_ITEMS_TO_UPDATE';
BEGIN
   if TSL_GET_ITEMS_TO_UPDATE(O_error_message,
                              I_item,
                              I_supplier,
                              I_change_level,
                              I_styleref_code,
                              L_item_rec) and L_item_rec.count <>0 then
   for i in L_item_rec.first..L_item_rec.last
   LOOP
   if L_item_rec(i).I_item <> I_slctd_item then
      TSL_INS_EXPENSE_HDR(O_error_message,
                          I_slctd_item,
                          L_item_rec(i).I_item,
                          I_supplier);
      TSL_INS_EXPENSE_TSLHDR(O_error_message,
                             I_slctd_item,
                             L_item_rec(i).I_item,
                             I_supplier);
      TSL_INS_EXPENSE_DTL(O_error_message,
                          I_slctd_item,
                          L_item_rec(i).I_item,
                          I_supplier);
      TSL_INS_EXPENSE_TSLDTL(O_error_message,
                             I_slctd_item,
                             L_item_rec(i).I_item,
                             I_supplier);
   end if;
   END LOOP;
   else
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
END TSL_INS_ALL_EXPENSES;
*/ --CR332, 17-DEC-2010, Commenting accenture functions -End
-------------------------------------------------------------------------------------------------------------
-- MrgNBS020482 11-Jan-2011 Nandini M/nandini.mariyappa@in.tesco.com End
--CR338 01-Dec-2010 Chandru Begin
--------------------------------------------------------------------------------------------------------
-- Function : TSL_INS_EXP_HEAD_TEMP
-- Purpose  : This function to populate expense head gtt2 table and called from tsl_itemexp_head screen
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_INS_EXP_HEAD_TEMP(O_error_message        IN OUT VARCHAR2,
                               I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                               I_supplier             IN     SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_INS_EXP_HEAD_TEMP';
BEGIN
   insert into tsl_item_exp_head_gtt2(item,
                                      supplier,
                                      item_exp_seq,
                                      item_exp_type,
                                      active_date,
                                      processed_ind)
 															 select	item,
                                      supplier,
                                      item_exp_seq,
                                      item_exp_type,
                                      active_date,
                                      processed_ind
                                 from tsl_item_exp_head tieh
                                where tieh.item = I_item
                                  and tieh.supplier = I_supplier
                                  and tieh.active_date >= get_vdate + 1
                                  and not exists (select 1
                                                    from tsl_item_exp_head_gtt2 gtt2
                                                   where gtt2.item = I_item
                                                     and gtt2.supplier = I_supplier
                                                     and tieh.item_exp_seq = gtt2.item_exp_seq
                                                     and tieh.item_exp_type = gtt2.item_exp_type
                                                     and gtt2.active_date >= get_vdate + 1);
return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_INS_EXP_HEAD_TEMP;
--------------------------------------------------------------------------------------------------------------
-- Function : TSL_INS_EXP_DETAIL_TEMP
-- Purpose  : This function to populate expense detail gtt2 table and called from tsl_itemexp_detail screen
--------------------------------------------------------------------------------------------------------------
FUNCTION TSL_INS_EXP_DETAIL_TEMP(O_error_message        IN OUT VARCHAR2,
                                 I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                                 I_supplier             IN     SUPS.SUPPLIER%TYPE,
                                 I_exp_seq              IN     TSL_ITEM_EXP_DETAIL.ITEM_EXP_SEQ%TYPE,
                                 I_exp_type             IN     TSL_ITEM_EXP_DETAIL.ITEM_EXP_TYPE%TYPE,
                                 I_comp_id              IN     TSL_ITEM_EXP_DETAIL.COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_INS_EXP_DETAIL_TEMP';
BEGIN
   insert into tsl_item_exp_detail_gtt2 (item,
                                         supplier,
                                         item_exp_seq,
                                         item_exp_type,
                                         comp_id,
                                         comp_rate,
                                         comp_currency,
                                         per_count,
                                         per_count_uom,
                                         active_date,
                                         processed_ind,
                                         tsl_cost_reason_code)
                                  select item,
                                         supplier,
                                         item_exp_seq,
                                         item_exp_type,
                                         comp_id,
                                         comp_rate,
                                         comp_currency,
                                         per_count,
                                         per_count_uom,
                                         active_date,
                                         processed_ind,
                                         tsl_cost_reason_code
                                    from tsl_item_exp_detail tied
                                   where tied.item          = I_item
                                     and tied.supplier      = I_supplier
                                     and tied.item_exp_seq  = I_exp_seq
                                     and tied.item_exp_type = I_exp_type
                                     and tied.comp_id       = I_comp_id
                                     and tied.active_date  >= get_vdate + 1
                                     and not exists (select 1
                                                       from tsl_item_exp_detail_gtt2 gtt2
                                                      where gtt2.item     = I_item
                                                        and gtt2.supplier = I_supplier
                                                        and gtt2.item     = tied.item
                                                        and gtt2.supplier = tied.supplier
                                                        and gtt2.item_exp_seq = tied.item_exp_seq
                                                        and gtt2.item_exp_type = tied.item_exp_type
                                                        and gtt2.comp_id       = tied.comp_id
                                                        and gtt2.active_date   = tied.active_date
                                                        and gtt2.active_date >= get_vdate + 1);
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_INS_EXP_DETAIL_TEMP;
--------------------------------------------------------------------------------------------------------------
-- Function : TSL_INS_EXP_HEAD_DTL_GTT
-- Purpose  : This function to used to insert expenses gtt table, check the packs exist to cascade,
--            check non qty match pack exist and called from itemexp screen
--------------------------------------------------------------------------------------------------------------
FUNCTION TSL_INS_EXP_HEAD_DTL_GTT(O_error_message        IN OUT VARCHAR2,
                                  O_exp_changed          IN OUT VARCHAR2,
                                  O_pack_exist           IN OUT VARCHAR2,
                                  O_non_match_qty        IN OUT VARCHAR2,
                                  I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                                  I_supplier             IN     SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_INS_EXP_HEAD_DTL_GTT';
   L_exp_type           ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE;
   L_qty                PACKITEM.PACK_QTY%TYPE;
   L_match_pack         PACKITEM.PACK_NO%TYPE;
   L_non_pack           PACKITEM.PACK_NO%TYPE;
   L_cnt                NUMBER(4);
   cursor C_GET_QTY is
      select pack_qty
        from packitem
       where pack_no = I_item;
   cursor C_ALL_TPND is
      select pi.pack_no item
        from packitem pi
       where pi.item_parent in (select pi1.item_parent
                                  from packitem pi1
                                 where pi1.pack_no= I_item)
         and pi.pack_no <> I_item
         and pi.pack_qty = L_qty;
   cursor C_TPND_NON_QTY is
      select pi.pack_no item
        from packitem pi
       where pi.item_parent in (select pi1.item_parent
                                  from packitem pi1
                                 where pi1.pack_no= I_item)
         and pi.pack_no <> I_item
         and pi.pack_qty <> L_qty;
   --DefNBS019722b 20-Dec-2010 Chandru Begin
   cursor C_FUT_EXP_CHG is
      select exp.cnt from
         (select count(1) cnt
            from tsl_item_exp_head_gtt hgt
           where hgt.item = I_item
             and hgt.supplier = I_supplier
           union
          select count(1) cnt
            from tsl_item_exp_detail_gtt dgtt
           where dgtt.item=I_item
             and dgtt.supplier = I_supplier) exp
         where exp.cnt>0;
   --DefNBS019722b 20-Dec-2010 Chandru End
BEGIN
   open C_GET_QTY;
   fetch C_GET_QTY into L_qty;
   close C_GET_QTY;
   open C_ALL_TPND;
   fetch C_ALL_TPND into L_match_pack;
   if C_ALL_TPND%FOUND then
      O_pack_exist := 'Y';
   else
      O_pack_exist := 'N';
   end if;
   close C_ALL_TPND;
   open C_TPND_NON_QTY;
   fetch C_TPND_NON_QTY into L_non_pack;
   if C_TPND_NON_QTY%FOUND then
      O_non_match_qty := 'Y';
   else
      O_non_match_qty := 'N';
   end if;

         insert into tsl_item_exp_head_gtt (item,
         																		supplier,
         																		item_exp_seq,
         																		item_exp_type,
         																		active_date,
         																		processed_ind,
         																		ins_upd_ind)
                                         select tieh.item,
                                         				tieh.supplier,
                                         				tieh.item_exp_seq,
                                         				tieh.item_exp_type,
                                         				tieh.active_date,
                                         				tieh.processed_ind,
                                         				'I'
                                         from tsl_item_exp_head tieh
                                        where tieh.item     = I_item
                                          and tieh.supplier = I_supplier
                                          and not exists (select 1
                                                            from tsl_item_exp_head_gtt2 gtt2
                                                           where tieh.item = I_item
                                                             and tieh.supplier = I_supplier
                                                             and tieh.item    = gtt2.item
                                                             and tieh.supplier = gtt2.supplier
                                                             and tieh.item_exp_seq = gtt2.item_exp_seq
                                                             and tieh.item_exp_type = gtt2.item_exp_type
                                                             and gtt2.active_date >= get_vdate + 1);

         -- insert for deleted head records
         insert into tsl_item_exp_head_gtt (item,
         																		supplier,
         																		item_exp_seq,
         																		item_exp_type,
         																		active_date,
         																		processed_ind,
         																		ins_upd_ind)
                                         select tieh.item,
                                         				tieh.supplier,
                                         				tieh.item_exp_seq,
                                         				tieh.item_exp_type,
                                         				tieh.active_date,
                                         				tieh.processed_ind,
                                         				'D'
                                         from tsl_item_exp_head_gtt2 tieh
                                        where tieh.item     = I_item
                                          and tieh.supplier = I_supplier
                                          and not exists (select 1
                                                            from tsl_item_exp_head gtt2
                                                           where tieh.item = I_item
                                                             and tieh.supplier = I_supplier
                                                             and tieh.item     = gtt2.item
                                                             and tieh.supplier = gtt2.supplier
                                                             and tieh.item_exp_seq = gtt2.item_exp_seq
                                                             and tieh.item_exp_type = gtt2.item_exp_type
                                                             and gtt2.active_date >= get_vdate + 1);
            -- insert new detail records
 insert into tsl_item_exp_detail_gtt (item,
                                         supplier,
                                         item_exp_seq,
                                         item_exp_type,
                                         comp_id,
                                         comp_rate,
                                         comp_currency,
                                         per_count,
                                         per_count_uom,
                                         active_date,
                                         processed_ind,
                                         tsl_cost_reason_code,
                                         ins_upd_ind)
                                  select item,
                                         supplier,
                                         item_exp_seq,
                                         item_exp_type,
                                         comp_id,
                                         comp_rate,
                                         comp_currency,
                                         per_count,
                                         per_count_uom,
                                         active_date,
                                         processed_ind,
                                         tsl_cost_reason_code,
                                         'I'
                                    from tsl_item_exp_detail tied
                                   where tied.item         = I_item
                                     and tied.supplier     = I_supplier
                                     and not exists ( select 1
                                                        from tsl_item_exp_detail_gtt2 gtt2
                                                       where gtt2.item = I_item
                                                         and gtt2.supplier = I_supplier
                                                         and gtt2.item   = tied.item
                                                         and gtt2.supplier = tied.supplier
                                                         and gtt2.item_exp_type = tied.item_exp_type
                                                         and gtt2.item_exp_seq  = tied.item_exp_seq
                                                         and gtt2.comp_id = tied.comp_id
                                                         and gtt2.active_date = tied.active_date
                                                         and gtt2.active_date >= get_vdate + 1)
                                     and not exists ( select 1
                                                        from tsl_item_exp_detail_gtt gtt
                                                       where gtt.item      = I_item
                                                         and gtt.supplier  = I_supplier
                                                         and gtt.item      = tied.item
                                                         and gtt.supplier  = tied.supplier
                                                         and gtt.item_exp_type = tied.item_exp_type
                                                         and gtt.item_exp_seq  = tied.item_exp_seq
                                                         and gtt.comp_id       = tied.comp_id
                                                         and gtt.active_date   = gtt.active_date);

            -- insert deleted detail records
   insert into tsl_item_exp_detail_gtt (item,
                                         supplier,
                                         item_exp_seq,
                                         item_exp_type,
                                         comp_id,
                                         comp_rate,
                                         comp_currency,
                                         per_count,
                                         per_count_uom,
                                         active_date,
                                         processed_ind,
                                         tsl_cost_reason_code,
                                         ins_upd_ind)
                                  select item,
                                         supplier,
                                         item_exp_seq,
                                         item_exp_type,
                                         comp_id,
                                         comp_rate,
                                         comp_currency,
                                         per_count,
                                         per_count_uom,
                                         active_date,
                                         processed_ind,
                                         tsl_cost_reason_code,
                                         'D'
                                    from tsl_item_exp_detail_gtt2 tied
                                   where tied.item         = I_item
                                     and tied.supplier     = I_supplier
                                     and not exists ( select 1
                                                        from tsl_item_exp_detail gtt2
                                                       where gtt2.item = I_item
                                                         and gtt2.supplier = I_supplier
                                                         and gtt2.item   = tied.item
                                                         and gtt2.supplier = tied.supplier
                                                         and gtt2.item_exp_type = tied.item_exp_type
                                                         and gtt2.item_exp_seq  = tied.item_exp_seq
                                                         and gtt2.comp_id = tied.comp_id
                                                         and gtt2.active_date = tied.active_date
                                                         and gtt2.active_date >= get_vdate + 1)
                                     and not exists ( select 1
                                                        from tsl_item_exp_detail_gtt gtt
                                                       where gtt.item      = I_item
                                                         and gtt.supplier  = I_supplier
                                                         and gtt.item      = tied.item
                                                         and gtt.supplier  = tied.supplier
                                                         and gtt.item_exp_type = tied.item_exp_type
                                                         and gtt.item_exp_seq  = tied.item_exp_seq
                                                         and gtt.comp_id       = tied.comp_id
                                                         and gtt.active_date   = gtt.active_date);
   open C_FUT_EXP_CHG;
   fetch C_FUT_EXP_CHG into L_cnt;
   if L_cnt > 0 then
      O_exp_changed := 'Y';
   else
      O_exp_changed := 'N';
   end if;
   close C_FUT_EXP_CHG;
   return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END TSL_INS_EXP_HEAD_DTL_GTT;
--------------------------------------------------------------------------------------------------------------
-- Function : TSL_CASCADE_EXP_ALL_TPND
-- Purpose  : This function to used to cascade expenses and called from itemexp screen
--------------------------------------------------------------------------------------------------------------
FUNCTION TSL_CASCADE_EXP_ALL_TPND(O_error_message        IN OUT VARCHAR2,
                                  I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                                  I_supplier             IN     SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_CASCADE_EXP_ALL_TPND';
   L_exp_type           ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE;
   L_qty                PACKITEM.PACK_QTY%TYPE;
   -- MrgNBS022379 21-Apr-2011 Veena Nanjundaiah veena.nanjundaiah@in.tesco.com Begin
   --NBS00021683 , 23-Mar-11, Murali N Begin
   L_item_master_row    item_master%rowtype;
   L_component_item     item_master.item%type;
   --NBS00021683 , 23-Mar-11, Murali N End
   -- MrgNBS022379 21-Apr-2011 Veena Nanjundaiah veena.nanjundaiah@in.tesco.com End
   cursor C_GET_QTY is
      select pack_qty
        from packitem
       where pack_no = I_item;
   cursor C_ALL_TPND is
      select pi.pack_no item
        from packitem pi,
             -- MrgNBS022853 03-Jun-2011 Bhargavi.pujari,bharagavi.pujari@in.tesco.com Begin
             --DefNBS022498,04-May-2011,Sripriya,Sripriya.karanam@in.tesco.com , Begin
             item_supplier isup
             --DefNBS022498,04-May-2011,Sripriya,Sripriya.karanam@in.tesco.com , End
             -- MrgNBS022853 03-Jun-2011 Bhargavi.pujari,bharagavi.pujari@in.tesco.com End
       where pi.item_parent in (select pi1.item_parent
                                  from packitem pi1
                                 where pi1.pack_no= I_item)
         and pi.pack_no <> I_item
         and pi.pack_qty = L_qty
         -- MrgNBS022853 03-Jun-2011 Bhargavi.pujari,bharagavi.pujari@in.tesco.com Begin
         --DefNBS022498,04-May-2011,Sripriya,Sripriya.karanam@in.tesco.com , Begin
         and pi.pack_no = isup.item
         and isup.supplier = I_supplier;
         --DefNBS022498,04-May-2011,Sripriya,Sripriya.karanam@in.tesco.com , End
         -- MrgNBS022853 03-Jun-2011 Bhargavi.pujari,bharagavi.pujari@in.tesco.com End
   cursor C_TPND_NON_QTY is
      select pi.pack_no item
        from packitem pi,
             -- MrgNBS022853 03-Jun-2011 Bhargavi.pujari,bharagavi.pujari@in.tesco.com Begin
             --DefNBS022498,04-May-2011,Sripriya,Sripriya.karanam@in.tesco.com , Begin
             item_supplier isup
             --DefNBS022498,04-May-2011,Sripriya,Sripriya.karanam@in.tesco.com , End
             -- MrgNBS022853 03-Jun-2011 Bhargavi.pujari,bharagavi.pujari@in.tesco.com End
        where pi.item_parent in (select pi1.item_parent
                                  from packitem pi1
                                 where pi1.pack_no= I_item)
         and pi.pack_no <> I_item
         and pi.pack_qty <> L_qty
         -- MrgNBS022853 03-Jun-2011 Bhargavi.pujari,bharagavi.pujari@in.tesco.com Begin
         --DefNBS022498,04-May-2011,Sripriya,Sripriya.karanam@in.tesco.com , Begin
         and pi.pack_no = isup.item
         and isup.supplier = I_supplier;
         --DefNBS022498,04-May-2011,Sripriya,Sripriya.karanam@in.tesco.com , End
         -- MrgNBS022853 03-Jun-2011 Bhargavi.pujari,bharagavi.pujari@in.tesco.com End
BEGIN
   open C_GET_QTY;
   fetch C_GET_QTY into L_qty;
   close C_GET_QTY;

   FOR C_rec in C_ALL_TPND LOOP
       -- delete the records from detail table
       delete from tsl_item_exp_detail tied
         where tied.item = C_rec.item
           and tied.supplier = I_supplier
           and exists (select 1
                         from tsl_item_exp_detail_gtt gtt
                        where gtt.item = I_item
                          and gtt.supplier = tied.supplier
                          and gtt.item_exp_seq = tied.item_exp_seq
                          and gtt.item_exp_type = tied.item_exp_type
                          and gtt.active_date = tied.active_date
                          and gtt.comp_id = tied.comp_id
                          and gtt.ins_upd_ind  = 'D');
       -- delete the records from head table
      delete from tsl_item_exp_head tieh
        where tieh.item = C_rec.item
          and tieh.supplier = I_supplier
          and exists (select 1
                        from tsl_item_exp_head_gtt gtt
                       where gtt.item = I_item
                         and gtt.supplier = tieh.supplier
                         and gtt.item_exp_seq = tieh.item_exp_seq
                         and gtt.item_exp_type = tieh.item_exp_type
                         and gtt.active_date = tieh.active_date
                         and gtt.ins_upd_ind = 'D');
     -- for updation, deleting the existing components in other TPNDs
     delete from tsl_item_exp_detail tied
      where tied.item = C_rec.item
        and tied.supplier = I_supplier
        and exists (select 1
                      from tsl_item_exp_detail_gtt gtt
                     where gtt.item          = I_item
                       and gtt.supplier      = tied.supplier
                       and gtt.item_exp_seq  = tied.item_exp_seq
                       and gtt.item_exp_type = tied.item_exp_type
                       and gtt.comp_id       = tied.comp_id
                       and gtt.active_date   = tied.active_date
                       and gtt.comp_rate     <> tied.comp_rate
                       and gtt.ins_upd_ind   = 'I');

     -- insert into tsl_item_exp_head
     insert into tsl_item_exp_head(item,
                                     supplier,
                                     item_exp_seq,
                                     item_exp_type,
                                     active_date,
                                     processed_ind)
                             select C_rec.item,
                                    I_supplier,
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                    /* 05-Feb-11  Murali N NBS00020760 Begin */
                                    ieh2.item_exp_seq,
                                    ieh2.item_exp_type,
                                    /* 05-Feb-11  Murali N NBS00020760 End */
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                    tieh.active_date,
                                    tieh.processed_ind
                               from tsl_item_exp_head_gtt tieh,
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                    /* 05-Feb-11  Murali N NBS00020760 Begin */
                                    item_exp_head ieh1,
                                    item_exp_head ieh2
                                    /* 05-Feb-11  Murali N NBS00020760 End */
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                              where tieh.item = I_item
                                and tieh.supplier = I_supplier
                                --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                /* 05-Feb-11  Murali N NBS00020760 Begin */
                                and tieh.item = ieh1.item
                                and tieh.supplier = ieh1.supplier
                                and tieh.item_exp_seq = ieh1.item_exp_seq
                                and tieh.item_exp_type = ieh1.item_exp_type
                                and ieh2.item = C_rec.item
                                and ieh2.supplier = ieh1.supplier
                                and ieh2.item_exp_type = ieh1.item_exp_type
                                and ieh2.zone_id = ieh1.zone_id
                                and ieh2.discharge_port = ieh1.discharge_port
                                /* 05-Feb-11  Murali N NBS00020760 End */
                                --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                and tieh.ins_upd_ind = 'I'
                                and not exists (select 1
                                                  from tsl_item_exp_head tieh2
                                                 where tieh2.item = C_rec.item
                                                   and tieh2.supplier = I_supplier
                                                  -- and tieh2.item = tieh.item
                                                   and tieh2.supplier = tieh.supplier
                                                   --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                                   /* 05-Feb-11  Murali N NBS00020760 Begin */
                                                   and tieh2.item_exp_seq = ieh2.item_exp_seq
                                                   and tieh2.item_exp_type = ieh2.item_exp_type
                                                   /* 05-Feb-11  Murali N NBS00020760 End */
                                                   --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                                   and tieh2.active_date = tieh.active_date);
       -- insert into tsl_item_exp_detail
      insert into tsl_item_exp_detail (item,
                                        supplier,
                                        item_exp_seq,
                                        item_exp_type,
                                        comp_id,
                                        comp_rate,
                                        comp_currency,
                                        per_count,
                                        per_count_uom,
                                        active_date,
                                        processed_ind,
                                        tsl_cost_reason_code)
                                 select C_rec.item,
                                        I_supplier,
                                        --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                        /* 05-Feb-11  Murali N NBS00020760 Begin */
                                        ieh2.item_exp_seq,
                                        ieh2.item_exp_type,
                                        /* 05-Feb-11  Murali N NBS00020760 End */
                                        --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                        tied.comp_id,
                                        tied.comp_rate,
                                        tied.comp_currency,
                                        tied.per_count,
                                        tied.per_count_uom,
                                        tied.active_date,
                                        tied.processed_ind,
                                        tied.tsl_cost_reason_code
                                   from tsl_item_exp_detail_gtt tied,
                                        --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                        /* 05-Feb-11  Murali N NBS00020760 Begin */
                                        item_exp_head ieh1,
                                        item_exp_head ieh2
                                        /* 05-Feb-11  Murali N NBS00020760 End */
                                        --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                  where tied.item = I_item
                                    and tied.supplier = I_supplier
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                    /* 05-Feb-11  Murali N NBS00020760 Begin */
                                    and tied.item = ieh1.item
                                    and tied.supplier = ieh1.supplier
                                    and tied.item_exp_seq = ieh1.item_exp_seq
                                    and tied.item_exp_type = ieh1.item_exp_type
                                    and ieh2.item = C_rec.item
                                    and ieh2.supplier = ieh1.supplier
                                    and ieh2.item_exp_type = ieh1.item_exp_type
                                    and ieh2.zone_id = ieh1.zone_id
                                    and ieh2.discharge_port = ieh1.discharge_port
                                    /* 05-Feb-11  Murali N NBS00020760 End */
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                    and tied.ins_upd_ind = 'I'
                                    and not exists (select 1
                                                      from tsl_item_exp_detail tied2
                                                     where tied2.item = C_rec.item
                                                       and tied2.supplier = I_supplier
                                                       --  and tied2.item = tied.item
                                                       and tied2.supplier = tied.supplier
                                                       --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                                       /* 05-Feb-11  Murali N NBS00020760 Begin */
                                                       and tied2.item_exp_seq = ieh2.item_exp_seq
                                                       and tied2.item_exp_type = ieh2.item_exp_type
                                                       /* 05-Feb-11  Murali N NBS00020760 End */
                                                       --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                                       and tied2.comp_id = tied.comp_id
                                                       and tied2.active_date = tied.active_date);
      -- MrgNBS022379 21-Apr-2011 Veena Nanjundaiah veena.nanjundaiah@in.tesco.com Begin
      --NBS00021683 , 23-Mar-11, Murali N Begin
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item_master_row,
                                         C_rec.item) = FALSE then
         return FALSE;
      end if;

      if L_item_master_row.status = 'A' then
         if TSL_MARGIN_SQL.CHECK_PRIMARY_PACK_SUPP_CNTRY(O_error_message,
                                                         L_component_item,
                                                         c_rec.item,
                                                         I_supplier,
                                                         NULL) = FALSE then
            return FALSE;
         end if;

         if L_component_item IS NOT NULL then
            O_error_message := ' ';
            if TSL_APPLY_REAL_TIME_COST(O_error_message,
                                        L_component_item,
                                        'Y',
                                        'O') != 0 then
               return FALSE;
            end if;
         end if;

         if TSL_MARGIN_SQL.INSERT_TSL_EXP_QUEUE(O_error_message,
                                                c_rec.item,
                                                I_supplier) = FALSE then
            return FALSE;
         end if;
      end if;
      --NBS00021683 , 23-Mar-11, Murali N End
      -- MrgNBS022379 21-Apr-2011 Veena Nanjundaiah veena.nanjundaiah@in.tesco.com End
   END LOOP;
   -- For non matched pack qty TPND
   FOR C_rec in C_TPND_NON_QTY LOOP
       -- delete the records from detail table
       delete from tsl_item_exp_detail tied
         where tied.item = C_rec.item
           and tied.supplier = I_supplier
           and exists (select 1
                         from tsl_item_exp_detail_gtt gtt,
                              elc_comp ec
                        where gtt.item = I_item
                          and gtt.supplier = tied.supplier
                          and gtt.item_exp_seq = tied.item_exp_seq
                          and gtt.item_exp_type = tied.item_exp_type
                          and gtt.active_date = tied.active_date
                          and gtt.comp_id = tied.comp_id
                          and gtt.ins_upd_ind  = 'D'
                          and ec.comp_id  = gtt.comp_id
                          and ec.comp_id = tied.comp_id
                          and ec.calc_basis = 'V');
       -- delete the records from head table
      delete from tsl_item_exp_head tieh
        where tieh.item = C_rec.item
          and tieh.supplier = I_supplier
          and exists (select 1
                        from tsl_item_exp_head_gtt gtt
                       where gtt.item = I_item
                         and gtt.supplier = tieh.supplier
                         and gtt.item_exp_seq = tieh.item_exp_seq
                         and gtt.item_exp_type = tieh.item_exp_type
                         and gtt.active_date = tieh.active_date
                         and gtt.ins_upd_ind = 'D');
     -- for updation, deleting the existing components in other TPNDs
     delete from tsl_item_exp_detail tied
      where tied.item = C_rec.item
        and tied.supplier = I_supplier
        and exists (select 1
                      from tsl_item_exp_detail_gtt gtt,
                           elc_comp ec
                     where gtt.item          = I_item
                       and gtt.supplier      = tied.supplier
                       and gtt.item_exp_seq  = tied.item_exp_seq
                       and gtt.item_exp_type = tied.item_exp_type
                       and gtt.comp_id       = tied.comp_id
                       and gtt.active_date   = tied.active_date
                       and gtt.comp_rate     <> tied.comp_rate
                       and gtt.ins_upd_ind   = 'I'
                       and ec.comp_id  = gtt.comp_id
                       and ec.comp_id = tied.comp_id
                       and ec.calc_basis = 'V');

     -- insert into tsl_item_exp_head
     insert into tsl_item_exp_head(item,
                                     supplier,
                                     item_exp_seq,
                                     item_exp_type,
                                     active_date,
                                     processed_ind)
                             select C_rec.item,
                                    I_supplier,
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                    /* 05-Feb-11  Murali N NBS00020760 Begin */
                                    ieh2.item_exp_seq,
                                    ieh2.item_exp_type,
                                    /* 05-Feb-11  Murali N NBS00020760 End */
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                    tieh.active_date,
                                    tieh.processed_ind
                               from tsl_item_exp_head_gtt tieh,
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                    /* 05-Feb-11  Murali N NBS00020760 Begin */
                                    item_exp_head ieh1,
                                    item_exp_head ieh2
                                    /* 05-Feb-11  Murali N NBS00020760 End */
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                              where tieh.item = I_item
                                and tieh.supplier = I_supplier
                                --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                /* 05-Feb-11  Murali N NBS00020760 Begin */
                                and tieh.item = ieh1.item
                                and tieh.supplier = ieh1.supplier
                                and tieh.item_exp_seq = ieh1.item_exp_seq
                                and tieh.item_exp_type = ieh1.item_exp_type
                                and ieh2.item = C_rec.item
                                and ieh2.supplier = ieh1.supplier
                                and ieh2.item_exp_type = ieh1.item_exp_type
                                and ieh2.zone_id = ieh1.zone_id
                                and ieh2.discharge_port = ieh1.discharge_port
                                /* 05-Feb-11  Murali N NBS00020760 End */
                                --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                and tieh.ins_upd_ind = 'I'
                                and not exists (select 1
                                                  from tsl_item_exp_head tieh2
                                                 where tieh2.item = C_rec.item
                                                   and tieh2.supplier = I_supplier
                                                   -- and tieh2.item = tieh.item
                                                   and tieh2.supplier = tieh.supplier
                                                   --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                                   /* 05-Feb-11  Murali N NBS00020760 Begin */
                                                   and tieh2.item_exp_seq = ieh2.item_exp_seq
                                                   and tieh2.item_exp_type = ieh2.item_exp_type
                                                   /* 05-Feb-11  Murali N NBS00020760 End */
                                                   --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                                   and tieh2.active_date = tieh.active_date);
       -- insert into tsl_item_exp_detail
      insert into tsl_item_exp_detail (item,
                                        supplier,
                                        item_exp_seq,
                                        item_exp_type,
                                        comp_id,
                                        comp_rate,
                                        comp_currency,
                                        per_count,
                                        per_count_uom,
                                        active_date,
                                        processed_ind,
                                        tsl_cost_reason_code)
                                 select C_rec.item,
                                        I_supplier,
                                        --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                        /* 05-Feb-11  Murali N NBS00020760 Begin */
                                        ieh2.item_exp_seq,
                                        ieh2.item_exp_type,
                                        /* 05-Feb-11  Murali N NBS00020760 End */
                                        --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                        tied.comp_id,
                                        tied.comp_rate,
                                        tied.comp_currency,
                                        tied.per_count,
                                        tied.per_count_uom,
                                        tied.active_date,
                                        tied.processed_ind,
                                        tied.tsl_cost_reason_code
                                   from tsl_item_exp_detail_gtt tied,
                                        --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                        /* 05-Feb-11  Murali N NBS00020760 Begin */
                                        item_exp_head ieh1,
                                        item_exp_head ieh2,
                                        /* 05-Feb-11  Murali N NBS00020760 End */
                                        --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                        elc_comp ec
                                  where tied.item = I_item
                                    and tied.supplier = I_supplier
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                    /* 05-Feb-11  Murali N NBS00020760 Begin */
                                    and tied.item = ieh1.item
                                    and tied.supplier = ieh1.supplier
                                    and tied.item_exp_seq = ieh1.item_exp_seq
                                    and tied.item_exp_type = ieh1.item_exp_type
                                    and ieh2.item = C_rec.item
                                    and ieh2.supplier = ieh1.supplier
                                    and ieh2.item_exp_type = ieh1.item_exp_type
                                    and ieh2.zone_id = ieh1.zone_id
                                    and ieh2.discharge_port = ieh1.discharge_port
                                    /* 05-Feb-11  Murali N NBS00020760 End */
                                    --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                    and tied.ins_upd_ind = 'I'
                                    and ec.comp_id  = tied.comp_id
                                    and ec.calc_basis = 'V'
                                    and not exists (select 1
                                                      from tsl_item_exp_detail tied2
                                                     where tied2.item = C_rec.item
                                                       and tied2.supplier = I_supplier
                                                       --  and tied2.item = tied.item
                                                       and tied2.supplier = tied.supplier
                                                       --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, Begin
                                                       /* 05-Feb-11  Murali N NBS00020760 Begin */
                                                       and tied2.item_exp_seq = ieh2.item_exp_seq
                                                       and tied2.item_exp_type = ieh2.item_exp_type
                                                       /* 05-Feb-11  Murali N NBS00020760 End */
                                                       --MrgNBS021583/Merge from 3.5 PrdSi to 3.5b, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 16-Feb-2011, End
                                                       and tied2.comp_id = tied.comp_id
                                                       and tied2.active_date = tied.active_date
                                                       and ec.comp_id  = tied2.comp_id
                                                       and ec.comp_id = tied.comp_id
                                                       and ec.calc_basis = 'V');
      -- MrgNBS022379 21-Apr-2011 Veena Nanjundaiah veena.nanjundaiah@in.tesco.com Begin
      --NBS00021683 , 23-Mar-11, Murali N Begin
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item_master_row,
                                         C_rec.item) = FALSE then
         return FALSE;
      end if;

      if L_item_master_row.status = 'A' then
         if TSL_MARGIN_SQL.CHECK_PRIMARY_PACK_SUPP_CNTRY(O_error_message,
                                                         L_component_item,
                                                         c_rec.item,
                                                         I_supplier,
                                                         NULL) = FALSE then
            return FALSE;
         end if;

         if L_component_item IS NOT NULL then
            O_error_message := ' ';
            if TSL_APPLY_REAL_TIME_COST(O_error_message,
                                        L_component_item,
                                        'Y',
                                        'O') != 0 then
               return FALSE;
            end if;
         end if;

         if TSL_MARGIN_SQL.INSERT_TSL_EXP_QUEUE(O_error_message,
                                                c_rec.item,
                                                I_supplier) = FALSE then
            return FALSE;
         end if;
      end if;
      --NBS00021683 , 23-Mar-11, Murali N End
      -- MrgNBS022379 21-Apr-2011 Veena Nanjundaiah veena.nanjundaiah@in.tesco.com End
   END LOOP;
   --
   -- It is removed to add as a seperate function call in TSL_TPND_GTT_DELETE
   return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END TSL_CASCADE_EXP_ALL_TPND;
--DefNBS019972b 20-Dec-2010 Chandru Begin
FUNCTION TSL_TPND_GTT_DELETE(O_error_message        IN OUT VARCHAR2,
                             I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                             I_supplier             IN     SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS
   L_program   VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_TPND_GTT_DELETE';
BEGIN
-- DefNBS025201 10-Jul-2012 Muthukumar Begin
   delete
     from tsl_item_exp_head_gtt
      where item=I_item and supplier=I_supplier;
   delete
     from tsl_item_exp_head_gtt2
      where item=I_item and supplier=I_supplier;
   delete
     from tsl_item_exp_detail_gtt
      where item=I_item and supplier=I_supplier;
   delete
     from tsl_item_exp_detail_gtt2
      where item=I_item and supplier=I_supplier;
-- DefNBS025201 10-Jul-2012 Muthukumar End
   return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END TSL_TPND_GTT_DELETE;
--DefNBS019972b 20-Dec-2010 Chandru End
--CR338 01-Dec-2010 Chandru End
----------------------------------------------------------------------------------------------------------------
-- Function : TSL_GET_WRKST_ITEMS
-- Mod By     : Chandrachooda H
-- Mod Ref    : CR332
-- Mod Details: The function checks for existence of any worksheet items for the input style reference code
----------------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_WRKST_ITEMS (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_wk_item_exist  IN OUT VARCHAR2,
                              I_style_ref_code IN ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
   RETURN BOOLEAN IS

   L_item      ITEM_MASTER.ITEM%TYPE := NULL;
   L_program   VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_GET_WRKST_ITEMS';

   cursor c_check_items is
   select im.item
     from item_master im
    --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
    --where im.status = 'W'
    where im.status <> 'A'
    --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
      and lower(im.item_desc_secondary) = lower(I_style_ref_code);
BEGIN
	 SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_ITEMS',
                    'ITEM_MASTER',
                    'STYLE_REF_CODE: ' || I_style_ref_code);
   open C_CHECK_ITEMS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_ITEMS',
                    'ITEM_MASTER',
                    'STYLE_REF_CODE: ' || I_style_ref_code);

   fetch C_CHECK_ITEMS into L_item;

   /*if record exists*/
   if C_CHECK_ITEMS%FOUND = TRUE then
      O_wk_item_exist := 'Y';
   else
      O_wk_item_exist := 'N';
   end if;

	 SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_ITEMS',
                    'ITEM_MASTER',
                    'STYLE_REF_CODE: ' || I_style_ref_code);
   close C_CHECK_ITEMS;

   return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END	TSL_GET_WRKST_ITEMS;
-- CR332 Chandra end
----------------------------------------------------------------------------------------------------------------
-- Function : TSL_STYL_REF_ITEMS_UPDATE
-- Mod By     : Chandrachooda H
-- Mod Ref    : CR332
-- Mod Details: The function inserts/updates future date and comp rate for input style ref code/item number
----------------------------------------------------------------------------------------------------------------
FUNCTION TSL_STYL_REF_ITEMS_UPDATE (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item            IN     ITEM_MASTER.ITEM%TYPE,
                                    I_supplier        IN     SUPS.SUPPLIER%TYPE,
                                    I_style_ref_code  IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                                    I_zone_id         IN     ITEM_EXP_HEAD.ZONE_ID%TYPE,
                                    I_discharge_port  IN     ITEM_EXP_HEAD.DISCHARGE_PORT%TYPE,
                                    I_user_access_ind IN     VARCHAR2,
                                    I_future_date     IN     TSL_ITEM_EXP_DETAIL.ACTIVE_DATE%TYPE,
                                    I_exp_type        IN     TSL_ITEM_EXP_DETAIL.ITEM_EXP_TYPE%TYPE,
                                    I_comp_id         IN     TSL_ITEM_EXP_DETAIL.COMP_ID%TYPE,
                                    I_rsn_code        IN     TSL_ITEM_EXP_DETAIL.TSL_COST_REASON_CODE%TYPE,
                                    I_comp_rate       IN     TSL_ITEM_EXP_DETAIL.COMP_RATE%TYPE,
                                    I_per_count       IN     TSL_ITEM_EXP_DETAIL.PER_COUNT%TYPE,
                                    I_per_count_uom   IN     TSL_ITEM_EXP_DETAIL.PER_COUNT_UOM%TYPE,
                                    I_comp_currency   IN     TSL_ITEM_EXP_DETAIL.COMP_CURRENCY%TYPE)
   RETURN BOOLEAN IS

   L_owner_country VARCHAR2(1) := 'N';
   L_found         VARCHAR2(1) := NULL;
   L_program       VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_STYL_REF_ITEMS_UPDATE';
   L_item          ITEM_MASTER.ITEM%TYPE;
   L_item_exp_seq  TSL_ITEM_EXP_DETAIL.ITEM_EXP_SEQ%TYPE := 0;
   L_exists        BOOLEAN := FALSE;
   L_item_status   ITEM_MASTER.STATUS%TYPE;
   L_item_desc     ITEM_MASTER.ITEM_DESC%TYPE;
   L_item_level    ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level    ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_component_item     ITEM_MASTER.ITEM%TYPE;
   L_origin_country_id  ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
   L_calc_basis         ELC_COMP.CALC_BASIS%TYPE;
   L_per_count          TSL_ITEM_EXP_DETAIL.PER_COUNT%TYPE := NULL;
   L_per_count_uom      TSL_ITEM_EXP_DETAIL.PER_COUNT_UOM%TYPE := NULL;
   --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
   L_rsn_code           TSL_ITEM_EXP_DETAIL.TSL_COST_REASON_CODE%TYPE := NULL;
   --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end

   cursor c_get_exp_hdr_rec is
   select td.item item,
          td.supplier supplier,
          --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
          im.status status,
          --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
          td.item_exp_type item_exp_type,
          td.item_exp_seq item_exp_seq
     --DefNBS020298, 27-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
     --from tsl_item_exp_detail td
     from item_exp_detail td,
          --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
          item_master im
          --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
     --DefNBS020298, 27-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
    where td.supplier = I_supplier
      and td.comp_id = I_comp_id
      --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
      and im.item = td.item
      --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
      and td.item in ( select pk.pack_no
                         from packitem pk, item_master im
                        where lower(im.item_desc_secondary) = lower(I_style_ref_code)
                          and (pk.pack_no = im.item or
                               pk.item = im.item or
                               pk.item_parent = im.item)
                        UNION ALL
                       select pai.pack_no
                         from packitem pai
                        where pai.item = I_item or
                              pai.item_parent = I_item or
                              pai.pack_no = I_item);


   cursor c_chk_rec_exists is
   select 'x'
     from tsl_item_exp_detail
    where item = L_item
      and comp_id = I_comp_id
      and item_exp_type = I_exp_type
      and active_date = I_future_date
      and supplier = I_supplier;

   cursor c_get_item_exp_seq(Cp_item VARCHAR2) is
   select item_exp_seq
     from item_exp_head
    where item = Cp_item
      and discharge_port = I_discharge_port
      and zone_id = I_zone_id
      and supplier = I_supplier;

   cursor c_get_origin_country is
   select origin_country_id
     from item_supp_country
    where item = L_item
      and supplier = I_supplier;

BEGIN

   for c_rec in C_GET_EXP_HDR_REC
   LOOP

      --->
      /*get item's owner country from item master*/
      if ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY(O_error_message,
                                               L_owner_country,
                                               c_rec.item) = FALSE then

         return FALSE;
      end if;
      --->

      L_item := c_rec.item;
      --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
      L_rsn_code := I_rsn_code;
      --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end

      if (I_user_access_ind = 'B' or
          (I_user_access_ind = 'U' and L_owner_country = 'U') or
          (I_user_access_ind = 'R' and L_owner_country = 'R')) then

	       SQL_LIB.SET_MARK('OPEN',
                          'C_CHK_REC_EXISTS',
                          'TSL_ITEM_EXP_DETAIL',
                          'STYLE_REF_CODE: ' || I_style_ref_code);
         open C_CHK_REC_EXISTS;

	       SQL_LIB.SET_MARK('FETCH',
                          'C_CHK_REC_EXISTS',
                          'TSL_ITEM_EXP_DETAIL',
                          'STYLE_REF_CODE: ' || I_style_ref_code);
         fetch C_CHK_REC_EXISTS into L_found;
     	   --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
     	   --DefNBS020408, moved the code outside IF loop
     	   --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
         if c_rec.status <> 'A' then
            L_rsn_code := NULL;
         end if;
         --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
         --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end

         if C_CHK_REC_EXISTS%FOUND = TRUE then
         	  --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
            if c_rec.status <> 'A' then
               L_rsn_code := NULL;
            end if;
            --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
               update tsl_item_exp_detail
                  set comp_rate = I_comp_rate,
                      --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                      --tsl_cost_reason_code = I_rsn_code
                      tsl_cost_reason_code = L_rsn_code
                      --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                where item = c_rec.item
                  and supplier = I_supplier
                  and comp_id = I_comp_id
                  and active_date = I_future_date;

         else

	          if ELC_SQL.GET_CALC_BASIS(O_error_message,
                                      L_calc_basis,
                                      I_comp_id)= FALSE then
              return FALSE;
            end if;

 	          L_per_count_uom := I_per_count_uom;
 	          L_per_count := I_per_count;

 	          if L_calc_basis = 'S' and L_per_count_uom is NULL then
 	             L_per_count_uom := 'EA';
 	          end if;

 	          if L_calc_basis = 'S' and L_per_count is NULL then
 	             L_per_count := 1;
 	          end if;

 	          SQL_LIB.SET_MARK('OPEN',
                             'C_GET_ITEM_EXP_SEQ',
                             'TSL_ITEM_EXP_DETAIL',
                             'ITEM: ' || L_item);
            open c_get_item_exp_seq(L_item);

 	          SQL_LIB.SET_MARK('FETCH',
                             'C_GET_ITEM_EXP_SEQ',
                             'TSL_ITEM_EXP_DETAIL',
                             'ITEM: ' || L_item);

            fetch c_get_item_exp_seq into L_item_exp_seq;

            insert into tsl_item_exp_detail(item,
                                            supplier,
                                            item_exp_seq,
                                            item_exp_type,
                                            comp_id,
                                            comp_rate,
                                            per_count,
                                            per_count_uom,
                                            comp_currency,
                                            active_date,
                                            processed_ind,
                                            tsl_cost_reason_code)
                                    values (c_rec.item,
                                            I_supplier,
                                            L_item_exp_seq,
                                            I_exp_type,
                                            I_comp_id,
                                            I_comp_rate,
                                            L_per_count,
                                            L_per_count_uom,
                                            I_comp_currency,
                                            I_future_date,
                                            'N',
                                            --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                                            --I_rsn_code);
                                            L_rsn_code);
                                            --DefNBS020316, 28-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end

 	          SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_ITEM_EXP_SEQ',
                             'TSL_ITEM_EXP_DETAIL',
                             'ITEM: ' || L_item);
            close c_get_item_exp_seq;
         end if;

	    SQL_LIB.SET_MARK('CLOSE',
                       'C_CHK_REC_EXISTS',
                       'TSL_ITEM_EXP_DETAIL',
                       'STYLE_REF_CODE: ' || I_style_ref_code);
      close C_CHK_REC_EXISTS;

      end if;

      if ITEM_EXPENSE_SQL.CHECK_HEADER_NO_DETAILS(O_error_message,
                                                  L_exists,
                                                  c_rec.item,
                                                  c_rec.supplier,
                                                  c_rec.item_exp_type) = FALSE then
         return FALSE;
      end if;
      if L_exists = TRUE then
         if ITEM_EXPENSE_SQL.DELETE_HEADER(O_error_message,
                                           c_rec.item,
                                           c_rec.supplier,
                                           c_rec.item_exp_type) = FALSE then
            return FALSE;
         end if;
      end if;

      if c_rec.item_exp_type = 'Z' then
         if ELC_CALC_SQL.CALC_COMP(O_error_message,
                                   'IE',
                                   c_rec.item,
                                   c_rec.supplier,
                                   c_rec.item_exp_type,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL) = FALSE then
            return FALSE;
         end if;
      else
         if ELC_CALC_SQL.CALC_COMP(O_error_message,
                                   'IE',
                                   c_rec.item,
                                   c_rec.supplier,
                                   c_rec.item_exp_type,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   L_owner_country,
                                   NULL,
                                   NULL) = FALSE then
            return FALSE;
         end if;
      end if;

      if ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                                  L_item_desc,
                                  L_item_status,
                                  L_item_level,
                                  L_tran_level,
                                  c_rec.item) = FALSE then
         return FALSE;
      end if;

	    SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ORIGIN_COUNTRY',
                       'ITEM_SUPP_COUNTRY',
                       'STYLE_REF_CODE: ' || I_style_ref_code);
      open C_GET_ORIGIN_COUNTRY;

	    SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ORIGIN_COUNTRY',
                       'ITEM_SUPP_COUNTRY',
                       'STYLE_REF_CODE: ' || I_style_ref_code);
      fetch C_GET_ORIGIN_COUNTRY into L_origin_country_id;

	    SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ORIGIN_COUNTRY',
                       'ITEM_SUPP_COUNTRY',
                       'STYLE_REF_CODE: ' || I_style_ref_code);
      close C_GET_ORIGIN_COUNTRY;

      if L_item_level < L_tran_level then
         if ITEM_EXPENSE_SQL.COPY_DOWN_PARENT_EXP(O_error_message,
                                                  c_rec.item,
                                                  c_rec.supplier,
                                                  L_origin_country_id) = FALSE then
            return FALSE;
         end if;
      end if;

      if L_item_level = L_tran_level and L_item_level = 2 then
         if TSL_BASE_VARIANT_SQL.VARIANT_FOR_SUPP_EXISTS(O_error_message,
 	  			   																				     L_exists,
 		  																						       c_rec.item,
 			  																					       c_rec.supplier) = FALSE then
            return FALSE;
         end if;
         if L_exists then
            if ITEM_EXPENSE_SQL.TSL_COPY_BASE_EXP(O_error_message,
         		 																	    c_rec.item,
         																			    c_rec.supplier,
         																			    L_origin_country_id) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;

      if L_item_status = 'A' then
         if TSL_MARGIN_SQL.CHECK_PRIMARY_PACK_SUPP_CNTRY(O_error_message,
                                                         L_component_item,
                                                         c_rec.item,
                                                         c_rec.supplier,
                                                         NULL) = FALSE then
            return FALSE;
         end if;

         if L_component_item IS NOT NULL then
            O_error_message := ' ';
            if TSL_APPLY_REAL_TIME_COST(O_error_message,
                                        L_component_item,
                                        'Y',
                                        'O') != 0 then
               return FALSE;
            end if;
         end if;

         if TSL_MARGIN_SQL.INSERT_TSL_EXP_QUEUE(O_error_message,
                                                c_rec.item,
                                                c_rec.supplier) = FALSE then
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
END TSL_STYL_REF_ITEMS_UPDATE;
--------------------------------------------------------------------------------------------------------------
-- Function : TSL_CHK_WRKST_ITEMS
-- Mod By     : Praveen R
-- Mod Ref    : CR332
-- Mod Details: The function checks for existence of any worksheet packs for the item number
----------------------------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_WRKST_ITEMS (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_wk_item_exist IN OUT VARCHAR2,
                              I_item          IN ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_item      ITEM_MASTER.ITEM%TYPE := NULL;
   L_program   VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_CHK_WRKST_ITEMS';

   cursor c_check_items is
   select im.item
     from item_master im,
          packitem pai
    --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
    --where im.status = 'W'
    where im.status <> 'A'
    --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
      and (pai.item_parent = I_item or
          pai.item = I_item or
          pai.pack_no = I_item)
      and pai.pack_no = im.item;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_ITEMS',
                    'ITEM_MASTER',
                    'ITEM: ' || I_item);
   open C_CHECK_ITEMS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_ITEMS',
                    'ITEM_MASTER',
                    'ITEM: ' || I_item);

   fetch C_CHECK_ITEMS into L_item;

   /*if record exists*/
   if C_CHECK_ITEMS%FOUND = TRUE then
      O_wk_item_exist := 'Y';
   else
      O_wk_item_exist := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_ITEMS',
                    'ITEM_MASTER',
                    'ITEM: ' || I_item);
   close C_CHECK_ITEMS;

   return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END TSL_CHK_WRKST_ITEMS;
-- CR332 Chandra end
----------------------------------------------------------------------------------------------------------------
-- Function : TSL_STYL_REF_EXP_HDR
-- Mod By     : Chandrachooda H
-- Mod Ref    : CR332
-- Mod Details: The function is called from future date item expense header screen to update
--              future date and comp rate for the input style ref code
----------------------------------------------------------------------------------------------------------------
FUNCTION TSL_STYL_REF_EXP_HDR (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item            IN     ITEM_MASTER.ITEM%TYPE,
                               I_supplier        IN     SUPS.SUPPLIER%TYPE,
                               I_style_ref_code  IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                               I_item_exp_type   IN     TSL_ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                               I_discharge_port  IN     VARCHAR2,
                               --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
                               I_user_access_ind IN     VARCHAR2,
                               --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
                               I_cost_zone       IN     ITEM_EXP_HEAD.ZONE_ID%TYPE,
                               I_future_date     IN     TSL_ITEM_EXP_HEAD.ACTIVE_DATE%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_STYL_REF_EXP_HDR';
   L_component_item        ITEM_MASTER.ITEM%TYPE;
   L_item_desc             ITEM_MASTER.ITEM_DESC%TYPE;
   L_item_level            ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level            ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_item_status           ITEM_MASTER.STATUS%TYPE;
   L_pack_ind              ITEM_MASTER.PACK_IND%TYPE;
   L_dept                  ITEM_MASTER.DEPT%TYPE;
   L_dept_name             DEPS.DEPT_NAME%TYPE;
   L_class                 ITEM_MASTER.CLASS%TYPE;
   L_class_name            CLASS.CLASS_NAME%TYPE;
   L_subclass              ITEM_MASTER.SUBCLASS%TYPE;
   L_subclass_name         SUBCLASS.SUB_NAME%TYPE;
   L_retail_zone_group_id  ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE;
   L_sellable_ind          ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind         ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type             ITEM_MASTER.PACK_TYPE%TYPE;
   L_simple_pack_ind       ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_waste_type            ITEM_MASTER.WASTE_TYPE%TYPE;
   L_item_parent           ITEM_MASTER.ITEM_PARENT%TYPE;
   L_item_grandparent      ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_short_desc            ITEM_MASTER.SHORT_DESC%TYPE;
   L_waste_pct             ITEM_MASTER.WASTE_PCT%TYPE;
   L_default_waste_pct     ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE;
   L_item_exp_seq          TSL_ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE;
   L_item                  ITEM_MASTER.ITEM%TYPE;
   L_found                 VARCHAR2(1) := NULL;
   --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
   L_owner_country         VARCHAR2(1) := 'N';
   --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end

   cursor c_get_all_items is
   select item,
          supplier,
          item_exp_seq,
          item_exp_type
     --DefNBS020298, 27-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
     --from tsl_item_exp_head
     from item_exp_head
     --DefNBS020298, 27-Dec-2010, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
    where supplier = I_supplier
      and item_exp_type = I_item_exp_type
      and item in (select pk.pack_no
                     from packitem pk, item_master im
                    where lower(im.item_desc_secondary) = lower(I_style_ref_code)
                      and (pk.pack_no = im.item or
                           pk.item = im.item or
                           pk.item_parent = im.item)
                   UNION ALL
                   select pai.pack_no
                     from packitem pai
                    where pai.item = I_item or
                          pai.item_parent = I_item or
                          pai.pack_no = I_item);

   cursor c_get_item_exp_seq(Cp_item VARCHAR2) is
   select item_exp_seq
     from item_exp_head
    where item = Cp_item
      and discharge_port = I_discharge_port
      and zone_id = I_cost_zone
      and supplier = I_supplier;

   cursor c_rec_exists is
   select 'x'
     from tsl_item_exp_head
    where item = L_item
      and item_exp_type = I_item_exp_type
      and item_exp_seq = L_item_exp_seq
      and active_date = I_future_date
      and supplier = I_supplier;

BEGIN
   for c_rec in c_get_all_items
   LOOP
      L_item := c_rec.item;

 	    SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_EXP_SEQ',
                       'ITEM_EXP_HEAD',
                       'ITEM: ' || L_item);
      open c_get_item_exp_seq(L_item);

 	    SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_EXP_SEQ',
                       'ITEM_EXP_HEAD',
                       'ITEM: ' || L_item);

      fetch c_get_item_exp_seq into L_item_exp_seq;

 	    SQL_LIB.SET_MARK('OPEN',
                       'C_REC_EXISTS',
                       'TSL_ITEM_EXP_HEAD',
                       'ITEM: ' || L_item);
      open c_rec_exists;

 	    SQL_LIB.SET_MARK('FETCH',
                       'C_REC_EXISTS',
                       'TSL_ITEM_EXP_HEAD',
                       'ITEM: ' || L_item);

      fetch c_rec_exists into L_found;

      if c_rec_exists%FOUND = TRUE then
         null;
      else
         --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
         /*get item's owner country from item master*/
         if ITEM_MASTER_SQL.TSL_GET_OWNER_COUNTRY(O_error_message,
                                                  L_owner_country,
                                                  c_rec.item) = FALSE then
            return FALSE;
         end if;
         --->
         if (I_user_access_ind = 'B' or
             (I_user_access_ind = 'U' and L_owner_country = 'U') or
             (I_user_access_ind = 'R' and L_owner_country = 'R')) then
         --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
	         insert into tsl_item_exp_head (item,
	                                        supplier,
	                                        item_exp_seq,
	                                        item_exp_type,
	                                        active_date,
	                                        processed_ind)
	                                values (c_rec.item,
	                                        c_rec.supplier,
	                                        L_item_exp_seq,
	                                        c_rec.item_exp_type,
	                                        I_future_date,
	                                        'N');

	         if ITEM_ATTRIB_SQL.GET_INFO (O_error_message,
	                                      L_item_desc,
	                                      L_item_level,
	                                      L_tran_level,
	                                      L_item_status,
	                                      L_pack_ind,
	                                      L_dept,
	                                      L_dept_name,
	                                      L_class,
	                                      L_class_name,
	                                      L_subclass,
	                                      L_subclass_name,
	                                      L_retail_zone_group_id,
	                                      L_sellable_ind,
	                                      L_orderable_ind,
	                                      L_pack_type,
	                                      L_simple_pack_ind,
	                                      L_waste_type,
	                                      L_item_parent,
	                                      L_item_grandparent,
	                                      L_short_desc,
	                                      L_waste_pct,
	                                         L_default_waste_pct,
	                                         c_rec.item) = FALSE then

	            return FALSE;
	         end if;

	         if L_item_status = 'A' then
	            if TSL_MARGIN_SQL.CHECK_PRIMARY_PACK_SUPP_CNTRY(O_error_message,
	                                                            L_component_item,
	                                                            c_rec.item,
	                                                            I_supplier,
	                                                            NULL) = FALSE then
	               return FALSE;
	            end if;

	            if L_component_item IS NOT NULL then
	            	 O_error_message := ' ';
	               if TSL_APPLY_REAL_TIME_COST(O_error_message,
	                                           L_component_item,
	                                          'Y',
	                                          'O') != 0 then
	                  return FALSE;
	               end if;
	            end if;
	            if TSL_MARGIN_SQL.INSERT_TSL_EXP_QUEUE(O_error_message,
	                                                   c_rec.item,
	                                                   I_supplier) = FALSE then
	               return FALSE;
	            end if;
	         end if;
		     --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
		     end if;
		     --DefNBS020408, 04-Jan-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
      end if;
 	    SQL_LIB.SET_MARK('CLOSE',
                       'C_REC_EXISTS',
                       'TSL_ITEM_EXP_HEAD',
                       'ITEM: ' || L_item);
      close c_rec_exists;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_EXP_SEQ',
                       'TSL_ITEM_EXP_DETAIL',
                       'ITEM: ' || L_item);
      close c_get_item_exp_seq;
   END LOOP;
   return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END TSL_STYL_REF_EXP_HDR;
--------------------------------------------------------------------------------------------------------------
-- Function   : TSL_CHK_BASE_EXP_IND
-- Mod By     : Chandrachooda H
-- Mod Ref    : DefNBS020408
-- Mod Details: The function checks the existence of a record with base_exp_ind as Y in the table ITEM_EXP_HEAD
--              for the input item-supplier combination
--------------------------------------------------------------------------------------------------------------
FUNCTION TSL_CHK_BASE_EXP_IND(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_base_exp_exist  IN OUT ITEM_EXP_HEAD.BASE_EXP_IND%TYPE,
                              I_item            IN     ITEM_MASTER.ITEM%TYPE,
                              I_supplier        IN     SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_CHK_BASE_EXP_IND';
   L_found VARCHAR(1) := 'N';

   cursor c_rec_exists is
   select 'x'
     from item_exp_head ieh
    where ieh.item = I_item
      and ieh.supplier = I_supplier
      and ieh.base_exp_ind = 'Y';

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_REC_EXISTS',
                    'ITEM_EXP_HEAD',
                    'ITEM: ' || I_item);
   open c_rec_exists;

   SQL_LIB.SET_MARK('FETCH',
                    'C_REC_EXISTS',
                    'ITEM_EXP_HEAD',
                    'ITEM: ' || I_item);
   fetch c_rec_exists into L_found;

   if c_rec_exists%FOUND = TRUE then
      O_base_exp_exist := 'Y';
   else
      O_base_exp_exist := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_REC_EXISTS',
                    'ITEM_EXP_HEAD',
                    'ITEM: ' || I_item);
   close c_rec_exists;

   return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END TSL_CHK_BASE_EXP_IND;
-------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- Function   : TSL_INSERT_EXPENSES_HEAD
-- Mod By     : Sangamithra N , Sangamithra.Nagarajan@in.tesco.com
-- Mod Ref    : DefNBS026825
-- Mod Details: The function checks if a record is added in the item expense detail future screen and no
--              entry exists in tsl_item_exp_head table, then a record is inserted for the discharge port.
--------------------------------------------------------------------------------------------------------------
FUNCTION TSL_INSERT_EXPENSES_HEAD(O_error_message     IN OUT VARCHAR2,
                                  I_active_date       IN     TSL_ITEM_EXP_DETAIL.ACTIVE_DATE%TYPE,
                                  I_item              IN     ITEM_MASTER.ITEM%TYPE,
                                  I_supplier          IN     SUPS.SUPPLIER%TYPE,
                                  I_exp_type          IN     EXP_PROF_HEAD.EXP_PROF_TYPE%TYPE,
                                  I_seq_no            IN     ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE)
   RETURN BOOLEAN IS
   L_program            VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_INSERT_EXPENSES_HEAD';

BEGIN


  SQL_LIB.SET_MARK('INSERT', NULL, 'TSL_ITEM_EXP_HEAD', NULL);
  insert into tsl_item_exp_head  (ITEM,
                                 SUPPLIER,
                                 ITEM_EXP_SEQ,
                                 ITEM_EXP_TYPE,
                                 ACTIVE_DATE,
                                 PROCESSED_IND)
                         select  I_item,
                                 I_supplier,
                                 I_seq_no,
                                 I_exp_type,
                                 I_active_date,
                                 'N'
                           from  dual
                          where not exists(select 'x'
                                               from tsl_item_exp_head ih
                                              where ih.item           = I_item
                                                and ih.supplier       = I_supplier
                                                and ih.item_exp_type  = I_exp_type
                                                and ih.item_exp_seq   = I_seq_no
                                                and ih.active_date    = I_active_date);

  return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;

END TSL_INSERT_EXPENSES_HEAD;
--------------------------------------------------------------------------------------------------------------
-- Function   : TSL_DELETE_EXPENSES_DETAIL
-- Mod By     : Sangamithra N , Sangamithra.Nagarajan@in.tesco.com
-- Mod Ref    : DefNBS026825
-- Mod Details: When a record is deleted in the item expense head future screen the corresponding detail level
--              record will be deleted as well.
--------------------------------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_EXPENSES_DETAIL(O_error_message     IN OUT VARCHAR2,
                                    I_active_date       IN     TSL_ITEM_EXP_DETAIL.ACTIVE_DATE%TYPE,
                                    I_item              IN     ITEM_MASTER.ITEM%TYPE,
                                    I_supplier          IN     SUPS.SUPPLIER%TYPE,
                                    I_exp_type          IN     EXP_PROF_HEAD.EXP_PROF_TYPE%TYPE,
                                    I_seq_no            IN     ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE)
   RETURN BOOLEAN IS
   L_program            VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_DELETE_EXPENSES_DETAIL';

BEGIN

   SQL_LIB.SET_MARK('DELETE', NULL, 'TSL_ITEM_EXP_DETAIL', NULL);
   delete from tsl_item_exp_detail td
         where td.item = I_item
           and td.supplier = I_supplier
           and td.item_exp_seq = I_seq_no
           and td.item_exp_type = I_exp_type
           and td.active_date = I_active_date ;

  return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;

END TSL_DELETE_EXPENSES_DETAIL;
-------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--CR518, 16-May-2014, Usha Patil, BEGIN
--------------------------------------------------------------------------------
--FUNCTION: TSL_EXCISE_COMP_EXISTS
--Purpose: Checks if the input item and supplier has active excise duty associated.
--------------------------------------------------------------------------------
FUNCTION TSL_EXCISE_COMP_EXISTS(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_excise_exp_exists  IN OUT VARCHAR2,
                                I_item               IN     ITEM_MASTER.ITEM%TYPE,
                                I_supplier           IN     SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

    L_program   VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_EXCISE_COMP_EXISTS';

   cursor C_EXCISE_EXISTS is
   select 'Y'
     from tsl_item_exp_detail tied
    where tied.item = I_item
      and tied.supplier = I_supplier
      and tied.comp_id ='104A'
      and tied.comp_rate > 0
      and tied.item_exp_seq in (select ieh.item_exp_seq
                                 from item_exp_head ieh
                                where ieh.item = I_item
                                  and ieh.supplier = I_supplier
                                  and ieh.base_exp_ind = 'Y')
      and tied.active_date = (select NVL(max(tied2.active_date), get_vdate())
                           from tsl_item_exp_detail tied2
                          where tied2.item = tied.item
                            and tied2.supplier = tied.supplier
                            and tied2.comp_id = tied.comp_id
                            and tied2.item_exp_seq = tied.item_exp_seq
                            and tied2.active_date <= get_vdate());

BEGIN
   O_excise_exp_exists := NULL;

   SQL_LIB.SET_MARK('OPEN','C_EXCISE_EXISTS', 'TSL_ITEM_EXP_DETAIL', 'ITEM: ' || I_item);
   open C_EXCISE_EXISTS;

   SQL_LIB.SET_MARK('FETCH','C_EXCISE_EXISTS', 'TSL_ITEM_EXP_DETAIL', 'ITEM: ' || I_item);
   fetch C_EXCISE_EXISTS into O_excise_exp_exists;

   SQL_LIB.SET_MARK('CLOSE','C_EXCISE_EXISTS', 'TSL_ITEM_EXP_DETAIL', 'ITEM: ' || I_item);
   close C_EXCISE_EXISTS;

EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END TSL_EXCISE_COMP_EXISTS;
--------------------------------------------------------------------------------
--FUNCTION: TSL_VALID_DISCHRG_PORT
--Purpose: Checks if the input item has valid discharge port associated
--------------------------------------------------------------------------------
FUNCTION TSL_VALID_DISCHRG_PORT(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_valid              IN OUT VARCHAR2,
                                I_item               IN     ITEM_MASTER.ITEM%TYPE,
                                I_supplier           IN     SUPS.SUPPLIER%TYPE,
                                I_duty_paid          IN     ITEM_SUPPLIER.TSL_DUTYPAID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_VALID_DISCHRG_PORT';

   cursor C_INVALID_DISC_PORT is
   select 'N'
     from item_exp_head ie
    where ie.item = I_item
      and ie.supplier = I_supplier
      and ((ie.discharge_port = 'DPD'
          and I_duty_paid = 'N')
       or ie.discharge_port != 'DPD'
          and I_duty_paid = 'Y')
      and ie.base_exp_ind = 'Y';

BEGIN

   O_valid := 'Y';

   --if I_duty_paid is N then User changing from Duty Paid to Duty Deferred else
   --I_duty_paid is Y then user changing from Duty Deferref to Duty Paid

   SQL_LIB.SET_MARK('OPEN','C_INVALID_DISC_PORT', 'item_exp_head', 'ITEM: ' || I_item);
   open C_INVALID_DISC_PORT;

   SQL_LIB.SET_MARK('FETCH','C_INVALID_DISC_PORT', 'item_exp_head', 'ITEM: ' || I_item);
   fetch C_INVALID_DISC_PORT into O_valid;

   if C_INVALID_DISC_PORT%FOUND then
      O_valid := 'N';
   else
      O_valid := 'Y';
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_INVALID_DISC_PORT', 'item_exp_head', 'ITEM: ' || I_item);
   close C_INVALID_DISC_PORT;

   return TRUE;
EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END TSL_VALID_DISCHRG_PORT;
--------------------------------------------------------------------------------
--FUNCTION: TSL_INSERT_EXCISE_COMP
--Purpose: Inserts the expense details as per the duty paid indicator.
--------------------------------------------------------------------------------
FUNCTION TSL_INSERT_EXCISE_COMP(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_item            IN     ITEM_MASTER.ITEM%TYPE,
                                I_supplier        IN     SUPS.SUPPLIER%TYPE,
                                I_dutypaid        IN     ITEM_SUPPLIER.TSL_DUTYPAID%TYPE)
   RETURN BOOLEAN IS

    L_program   VARCHAR2(64)   := 'ITEM_EXPENSE_SQL.TSL_INSERT_EXCISE_COMP';

    L_valid           VARCHAR2(1) := 'N';
    L_comp_rate       TSL_ITEM_EXP_DETAIL.COMP_RATE%TYPE := NULL;
    L_exp_exists      VARCHAR2(1) := 'N';
    L_deleted_records VARCHAR2(1) := 'N';
    L_item_master_row ITEM_MASTER%ROWTYPE := NULL;

BEGIN

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                       L_item_master_row,
                                       I_item) = FALSE then
      return FALSE;
   end if;

   if I_dutypaid = 'N' then
      if TSL_MIN_PRICE_SQL.DUTY_CHG(O_error_message,
                                    L_valid,
                                    L_comp_rate,
                                    I_item,
                                    I_supplier,
                                    I_dutypaid) = FALSE then
         return FALSE;
      end if;
   elsif I_dutypaid = 'Y' then
      L_comp_rate := 0;

      /*open C_EXPENSE_EXISTS;
      fetch C_EXPENSE_EXISTS into L_exp_exists;

      if C_EXPENSE_EXISTS%FOUND then*/
      delete from tsl_item_exp_detail tied
            where tied.item = I_item
              and tied.supplier = I_supplier
              and tied.comp_id = '104A'
              and tied.active_date >= get_vdate+1;

      if SQL%FOUND then
         L_deleted_records := 'Y';
      end if;

      insert into tsl_item_exp_detail (item,
                                       supplier,
                                       item_exp_seq,
                                       item_exp_type,
                                       comp_id,
                                       comp_rate,
                                       comp_currency,
                                       per_count,
                                       per_count_uom,
                                       active_date,
                                       processed_ind,
                                       tsl_cost_reason_code
                                       )
                               select tied.item,
                                      tied.supplier,
                                      tied.item_exp_seq,
                                      tied.item_exp_type,
                                      '104A',
                                      0,
                                      'GBP',
                                      1,
                                      'EA',
                                      get_vdate +1,
                                      'N',
                                      22
                                 from tsl_item_exp_detail tied
                                where tied.item = I_item
                                  and tied.supplier = I_supplier
                                  and tied.item_exp_type = 'Z'
                                  and tied.comp_id = '104A'
                                  and tied.active_date = (select max(tied1.active_date)
                                                            from tsl_item_exp_detail tied1
                                                           where tied1.item = tied.item
                                                             and tied1.supplier = tied.supplier
                                                             and tied1.item_exp_type = tied.item_exp_type
                                                             and tied1.item_exp_seq = tied.item_exp_seq
                                                             and tied1.comp_id = tied.comp_id
                                                             and tied1.active_date <= get_vdate());

      if (SQL%FOUND or L_deleted_records = 'Y') and L_item_master_row.status = 'A' then
         if TSL_MARGIN_SQL.INSERT_TSL_EXP_QUEUE (O_error_message,
                                                 I_item,
                                                 I_supplier) = FALSE then
            return FALSE;
         end if;
      end if;

     /* end if;
      close C_EXPENSE_EXISTS;*/
   end if;

   if L_valid  = 'Y' and I_dutypaid = 'N' and L_comp_rate > 0 then
      MERGE INTO tsl_item_exp_detail tied
      using (select ied.item item,
                    ied.supplier supplier,
                    ied.item_exp_type item_exp_type,
                    ied.item_exp_seq item_exp_seq,
                    get_vdate + 1 active_date,
                    ied.comp_id comp_id,
                    L_comp_rate comp_rate,
                    ied.per_count_uom per_count_uom
               from item_exp_head ieh,
                    item_exp_detail ied
              where ieh.item = I_item
                and ieh.supplier = I_supplier
                --and ieh.base_exp_ind = 'Y'
                and ieh.zone_id = 1
                and ied.item = ieh.item
                and ied.supplier = ieh.supplier
                and ied.item_exp_type = ieh.item_exp_type
                and ied.item_exp_seq = ieh.item_exp_seq
                and ied.comp_id = '104A') t2
          ON (tied.item = t2.item
          and tied.supplier = t2.supplier
          and tied.item_exp_type = t2.item_exp_type
          and tied.item_exp_seq = t2.item_exp_seq
          and tied.comp_id = t2.comp_id
          and tied.active_date = t2.active_date)
       WHEN MATCHED then
          update set comp_rate = L_comp_rate
       WHEN NOT MATCHED then
          insert (item,
                  supplier,
                  item_exp_type,
                  item_exp_seq,
                  comp_id,
                  comp_rate,
                  comp_currency,
                  per_count,
                  per_count_uom,
                  active_date,
                  processed_ind,
                  tsl_cost_reason_code)
           values (t2.item,
                   t2.supplier,
                   t2.item_exp_type,
                   t2.item_exp_seq,
                   t2.comp_id,
                   t2.comp_rate,
                   'GBP',
                   1,
                   t2.per_count_uom,
                   t2.active_date,
                   'N',
                   22);

      if SQL%FOUND and L_item_master_row.status = 'A' then
         if TSL_MARGIN_SQL.INSERT_TSL_EXP_QUEUE (O_error_message,
                                                 I_item,
                                                 I_supplier) = FALSE then
            return FALSE;
         end if;
      end if;

      insert into tsl_process_fiscal_temp (item)
                                    select distinct pi.item
     from tsl_bws_fiscal_rates bfr,
          tsl_fiscal_compid fc,
          uda_values uv,
          uda_item_lov uil,
          period per,
          packitem pi
    where uv.uda_id = 409
      and uv.uda_value = uil.uda_value
      and uil.uda_id = uv.uda_id
      and uil.item = pi.item
      and pi.pack_no = I_item
      and uil.uda_value = fc.fiscal_code
      and bfr.fiscal_code = fc.fiscal_code
      and bfr.cost_zone = 1
      and fc.comp_id = '104A'
      and fc.effective_date = bfr.effective_date
      and bfr.effective_date > per.vdate
      and bfr.processed_ind = 'Y'
      and not exists (select 1
                        from tsl_process_fiscal_temp tpf
                       where tpf.item = pi.item);

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                SQLERRM,
                                                L_program,
                                                to_char(SQLCODE));
      return FALSE;
END TSL_INSERT_EXCISE_COMP;
--------------------------------------------------------------------------------
--CR518, 16-May-2014, Usha Patil, END
--------------------------------------------------------------------------------
END;
/

