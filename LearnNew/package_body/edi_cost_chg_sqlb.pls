CREATE OR REPLACE PACKAGE BODY EDI_COST_CHG_SQL AS
------------------------------------------------------------------------------------
FUNCTION CREATE_COST_CHG(O_error_message   IN OUT    VARCHAR2,
                         I_seq_no          IN        EDI_COST_CHG.SEQ_NO%TYPE,
                         I_cost_change_no  IN        COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                         I_cost_chg_desc   IN        COST_SUSP_SUP_HEAD.COST_CHANGE_DESC%TYPE,
                         I_reason          IN        COST_SUSP_SUP_HEAD.REASON%TYPE,
                         I_active_date     IN        DATE,
                         I_create_date     IN        DATE,
                         I_create_id       IN        COST_SUSP_SUP_HEAD.CREATE_ID%TYPE,
                         I_approval_date   IN        DATE,
                         I_approval_id     IN        COST_SUSP_SUP_HEAD.APPROVAL_ID%TYPE,
                         I_costed_ind      IN        VARCHAR2,
                         I_cost_status     IN        VARCHAR2,
                         I_supplier        IN        EDI_COST_CHG.SUPPLIER%TYPE) return BOOLEAN IS

L_program             VARCHAR2(64) := 'EDI_COST_CHG_SQL.CREATE_COST_CHG';
L_loc                 VARCHAR2(1) := 'N';
L_bracket             VARCHAR2(1) := 'N';
L_bracket_level       VARCHAR2(3);
L_multichannel_flag   VARCHAR2(1);
L_dept                ITEM_MASTER.DEPT%TYPE;
L_UOM                 SUP_INV_MGMT.BRACKET_UOM1%TYPE;


cursor C_SELECT_LOCATION is
   select 'Y'
     from edi_cost_loc
    where edi_cost_loc.seq_no = I_seq_no
      and location is not NULL;

---
cursor C_SELECT_BRACKET is
   select 'Y'
     from edi_cost_loc
    where edi_cost_loc.seq_no = I_seq_no
      and bracket_value1 is not NULL;

---
cursor C_GET_DEPT is
   select im.dept
     from item_master im,
          edi_cost_loc ecl
    where ecl.item   = im.item
      and ecl.seq_no = I_seq_no;

--- This package will first verify that all input fields necceasary
--- For processing are not null.  Then, a general insert into
--- COST_SUSP_SUP_HEAD will be initiated for the cost change that
--- is attached to the passed in sequence number on EDI_COST_CHG.
--- Process will be handled in two instances:
--- 1.  If cost changes are at the item level, an insert will be made into
---     COST_SUSP_SUP_DETAIL for the costs on the EDI_COST_CHG table that
---     That are attached to the passed in sequence number.
--- 2.  If the cost change is at the item/loc, item/bracket, or item/loc/bracket
---     levels, the following processing will occur:
---     1.  If locations are present but brackets are not, an insert will be
---         made into COST_SUSP_SUP_DETAIL_LOC for all location records
---         on EDI_COST_LOC for the passed in cost change sequence number.
---     2.  If locations and brackets are present, an insert will be
---         made into COST_SUSP_SUP_DETAIL_LOC for all location records and
---         their brackets
---         on EDI_COST_LOC for the passed in cost change sequence number.
---     3.  If brcakets are present but locations are not, an insert will be
---         made into COST_SUSP_SUP_DETAIL for all brcaket records
---         on EDI_COST_LOC for the passed in cost change sequence number.

BEGIN
   --- NULL value validation
   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_seq_no',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_costed_ind is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_costed_ind',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_cost_status is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_cost_status',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_cost_change_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_cost_change_no',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_cost_chg_desc is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_cost_change_desc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_reason is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_reason',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_create_date is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_create_date',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_create_id is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_create_id',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   --- Function should error out if the cost change is 'A'pproved and the
   --- approval date is NULL.
   if I_cost_status = 'A' and I_approval_date is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_approval_date',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   --- Function should error out if the cost change status is 'A'pproved and the
   --- and the approval id is null.
   if I_cost_status = 'A' and I_approval_id is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_approval_id',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_active_date is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_active_date',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   --- For all EDI cost change instances, insert into COST_SUSP_SUP_HEAD.
   SQL_LIB.SET_MARK('INSERT',NULL,'COST_SUSP_SUP_HEAD',NULL);
   insert into cost_susp_sup_head(cost_change,
                                  cost_change_desc,
                                  reason,
                                  active_date,
                                  status,
                                  cost_change_origin,
                                  create_date,
                                  create_id,
                                  approval_date,
                                  approval_id)
                           values(I_cost_change_no,
                                  I_cost_chg_desc,
                                  I_reason,
                                  I_active_date,
                                  I_cost_status,
                                  'SUP',
                                  I_create_date,
                                  I_create_id,
                                  I_approval_date,
                                  I_approval_id);

   --- If the EDI cost change is not by bracket and/or location,
   --- Insert into the COST_SUSP_SUP_DETAIL.
   if I_costed_ind = 'N' then
      SQL_LIB.SET_MARK('INSERT',NULL,'COST_SUSP_SUP_DETAIL',NULL);
      insert into cost_susp_sup_detail(cost_change,
                                       supplier,
                                       origin_country_id,
                                       item,
                                       unit_cost,
                                       recalc_ord_ind,
                                       default_bracket_ind)
                                select I_cost_change_no,
                                       ecg.supplier,
                                       ecg.origin_country_id,
                                       ecg.item,
                                       ecg.unit_cost,
                                       ecg.recalc_ord_ind,
                                       'N'
                                  from edi_cost_chg ecg
                                 where ecg.seq_no = I_seq_no;

      if I_cost_status = 'A' then
         -- If new cost change is inserted in 'A'pproved status, write
         -- record(s) to temp table so future_cost will be rebuilt
         insert into cost_change_trigger_temp(cost_change,
                                              item,
                                              supplier,
                                              origin_country_id,
                                              loc,
                                              loc_type,
                                              unit_cost,
                                              active_date)
                                       select I_cost_change_no,
                                              item,
                                              supplier,
                                              origin_country_id,
                                              NULL,
                                              NULL,
                                              unit_cost,
                                              I_active_date
                                         from cost_susp_sup_detail
                                        where cost_change = I_cost_change_no;
      end if;  --- End if I_cost_status = 'A'
   end if;  --- End if I_costed_ind = 'N'


   if I_costed_ind = 'Y' then

      --- Determine if the records for the sequence number on EDI_COST_LOC are location costed
      SQL_LIB.SET_MARK('OPEN', 'C_SELECT_LOCATION', 'EDI_COST_LOC',
                       'sequence number: '|| to_char(I_seq_no));
      OPEN C_SELECT_LOCATION;

      SQL_LIB.SET_MARK('FETCH', 'C_SELECT_LOCATION', 'EDI_COST_LOC',
                       'sequence number: '|| to_char(I_seq_no));
      FETCH C_SELECT_LOCATION into L_loc;

      SQL_LIB.SET_MARK('CLOSE', 'C_SELECT_LOCATION', 'EDI_COST_LOC',
                       'sequence number: '|| to_char(I_seq_no));
      CLOSE C_SELECT_LOCATION;

      --- Determine if the records on EDI_COST_LOC are bracket costed
      SQL_LIB.SET_MARK('OPEN', 'C_SELECT_BRACKET', 'EDI_COST_LOC',
                       'sequence number: '|| to_char(I_seq_no));
      OPEN C_SELECT_BRACKET;

      SQL_LIB.SET_MARK('FETCH', 'C_SELECT_BRACKET', 'EDI_COST_LOC',
                       'sequence number: '|| to_char(I_seq_no));
      FETCH C_SELECT_BRACKET into L_bracket;

      SQL_LIB.SET_MARK('CLOSE', 'C_SELECT_BRACKET', 'EDI_COST_LOC',
                       'sequence number: '|| to_char(I_seq_no));
      CLOSE C_SELECT_BRACKET;

      --- If the supplier is bracket costed then
      --- Get the supplier bracket level
      if L_bracket = 'Y' then

         if not SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                                    L_bracket_level,
                                                    I_supplier) then
            return FALSE;
         end if;
      end if;

      --- Get the department for the item if:
      --- 1.  Bracket level is Supp/dept/loc = A
      --- 2.  Bracket level is Supp/dept = D
      --- 3.  Only a location costed item
      if (L_bracket = 'Y' and L_bracket_level = 'A') or
         (L_bracket = 'Y' and L_bracket_level = 'D') or
         (L_loc = 'Y' and L_bracket = 'N' ) then

         SQL_LIB.SET_MARK('OPEN', 'C_GET_DEPT', 'ITEM_MASTER',
                          'sequence number: '|| to_char(I_seq_no));
         OPEN C_GET_DEPT;

         SQL_LIB.SET_MARK('FETCH', 'C_GET_DEPT', 'ITEM_MASTER',
                          'sequence number: '|| to_char(I_seq_no));
         FETCH C_GET_DEPT into L_dept;

         SQL_LIB.SET_MARK('CLOSE', 'C_GET_DEPT', 'ITEM_MASTER',
                          'sequence number: '|| to_char(I_seq_no));
         CLOSE C_GET_DEPT;

      end if;

      --- Insert into COST_SUSP_SUP_DETAIL_LOC if the records on
      --- EDI_COST_LOC are only location costed.  Both Stores and
      --- Warehouses can be location costed but not bracket costed.
      if L_bracket = 'N' and L_loc = 'Y' then

         --- First, insert into COST CHANGE dialog for warehouses
         SQL_LIB.SET_MARK('INSERT',NULL,'COST_SUSP_SUP_DETAIL_LOC',NULL);
         insert into cost_susp_sup_detail_loc(cost_change,
                                              supplier,
                                              origin_country_id,
                                              item,
                                              loc_type,
                                              loc,
                                              unit_cost,
                                              recalc_ord_ind,
                                              default_bracket_ind,
                                              dept)
                                       select I_cost_change_no,
                                              ecg.supplier,
                                              ecg.origin_country_id,
                                              ecg.item,
                                              ecl.loc_type,
                                              w.wh,
                                              ecl.unit_cost_new,
                                              ecg.recalc_ord_ind,
                                              'N',
                                              L_dept
                                         from edi_cost_loc ecl,
                                              edi_cost_chg ecg,
                                              wh w
                                        where ecg.seq_no      = I_seq_no
                                          and ecl.seq_no      = ecg.seq_no
                                          and w.wh            in (select w1.wh
                                                                    from wh w1
                                                                   where w1.physical_wh      = ecl.location
                                                                     and w1.stockholding_ind = 'Y');

         --- Next, insert into COST CHANGE dialog for stores
         SQL_LIB.SET_MARK('INSERT',NULL,'COST_SUSP_SUP_DETAIL_LOC',NULL);
         insert into cost_susp_sup_detail_loc(cost_change,
                                              supplier,
                                              origin_country_id,
                                              item,
                                              loc_type,
                                              loc,
                                              unit_cost,
                                              recalc_ord_ind,
                                              default_bracket_ind,
                                              dept)
                                       select I_cost_change_no,
                                              ecg.supplier,
                                              ecg.origin_country_id,
                                              ecg.item,
                                              ecl.loc_type,
                                              st.store,
                                              ecl.unit_cost_new,
                                              ecg.recalc_ord_ind,
                                              'N',
                                              L_dept
                                         from edi_cost_loc ecl,
                                              edi_cost_chg ecg,
                                              store st
                                        where ecg.seq_no      = I_seq_no
                                          and ecl.seq_no      = ecg.seq_no
                                          and st.store        = ecl.location;

         if I_cost_status = 'A' then
            -- If new cost change is inserted in 'A'pproved status, write
            -- record(s) to temp table so future_cost will be rebuilt
            insert into cost_change_trigger_temp(cost_change,
                                                 item,
                                                 supplier,
                                                 origin_country_id,
                                                 loc,
                                                 loc_type,
                                                 unit_cost,
                                                 active_date)
                                          select I_cost_change_no,
                                                 item,
                                                 supplier,
                                                 origin_country_id,
                                                 loc,
                                                 loc_type,
                                                 unit_cost,
                                                 I_active_date
                                            from cost_susp_sup_detail_loc
                                           where cost_change = I_cost_change_no;
         end if;
      end if;  --- end if L_bracket = 'N' and L_loc = 'Y'

      --- Insert into COST_SUSP_SUP_DETAIL_LOC if the records on
      --- EDI_COST_LOC are location costed and bracket costed
      --- For brackets, locations should only be warehouses.
      if L_bracket = 'Y' and L_loc = 'Y' then

         SQL_LIB.SET_MARK('INSERT',NULL,'COST_SUSP_SUP_DETAIL_LOC',NULL);
         insert into cost_susp_sup_detail_loc(cost_change,
                                              supplier,
                                              origin_country_id,
                                              item,
                                              loc_type,
                                              loc,
                                              bracket_value1,
                                              bracket_uom1,
                                              bracket_value2,
                                              unit_cost,
                                              recalc_ord_ind,
                                              default_bracket_ind,
                                              dept)
                                       select distinct I_cost_change_no,
                                                       ecg.supplier,
                                                       ecg.origin_country_id,
                                                       ecg.item,
                                                       ecl.loc_type,
                                                       w.wh,
                                                       ecl.bracket_value1,
                                                       ecl.bracket_uom1,
                                                       ecl.bracket_value2,
                                                       ecl.unit_cost_new,
                                                       ecg.recalc_ord_ind,
                                                       iscbc.default_bracket_ind,
                                                       L_dept
                                         from edi_cost_loc ecl,
                                              edi_cost_chg ecg,
                                              item_supp_country_bracket_cost iscbc,
                                              wh w
                                        where ecg.seq_no                = I_seq_no
                                          and ecl.seq_no                = ecg.seq_no
                                          and iscbc.item                = ecl.item
                                          and iscbc.supplier            = ecl.supplier
                                          and iscbc.origin_country_id   = ecl.origin_country_id
                                          and iscbc.location in (select w1.wh
                                                                   from wh w1
                                                                  where w1.physical_wh      = ecl.location
                                                                    and w1.stockholding_ind = 'Y')
                                          and w.wh           in (select w2.wh
                                                                   from wh w2
                                                                  where w2.physical_wh      = ecl.location
                                                                    and w2.stockholding_ind = 'Y')
                                          and iscbc.bracket_value1      = ecl.bracket_value1;

         if I_cost_status = 'A' then
            -- If new cost change is inserted in 'A'pproved status, write
            -- record(s) to temp table so future_cost will be rebuilt
            insert into cost_change_trigger_temp(cost_change,
                                                 item,
                                                 supplier,
                                                 origin_country_id,
                                                 loc,
                                                 loc_type,
                                                 unit_cost,
                                                 active_date)
                                          select I_cost_change_no,
                                                 item,
                                                 supplier,
                                                 origin_country_id,
                                                 loc,
                                                 loc_type,
                                                 unit_cost,
                                                 I_active_date
                                            from cost_susp_sup_detail_loc
                                           where cost_change = I_cost_change_no
                                             and default_bracket_ind = 'Y';
         end if;
      end if; ---  if L_bracket = 'Y' and L_loc = 'Y'

      --- Insert into COST_SUSP_SUP_DETAIL if the records on
      --- EDI_COST_LOC are not location costed but bracket costed.
      --- For brackets, locations should only be warehouses.
      --- Do inserts in the following order:
      if L_bracket = 'Y' and L_loc = 'N' then

         SQL_LIB.SET_MARK('INSERT',NULL,'COST_SUSP_SUP_DETAIL',NULL);
         insert into cost_susp_sup_detail(bracket_value1,
                                          bracket_value2,
                                          cost_change,
                                          supplier,
                                          origin_country_id,
                                          item,
                                          bracket_uom1,
                                          unit_cost,
                                          recalc_ord_ind,
                                          default_bracket_ind,
                                          dept)
                                   select ecl.bracket_value1,
                                          ecl.bracket_value2,
                                          I_cost_change_no,
                                          ecg.supplier,
                                          ecg.origin_country_id,
                                          ecg.item,
                                          ecl.bracket_uom1,
                                          ecl.unit_cost_new,
                                          ecg.recalc_ord_ind,
                                          iscbc.default_bracket_ind,
                                          L_dept
                                     from edi_cost_loc ecl,
                                          edi_cost_chg ecg,
                                          item_supp_country_bracket_cost iscbc
                                    where ecg.seq_no                = I_seq_no
                                      and ecl.seq_no                = ecg.seq_no
                                      and iscbc.item                = ecl.item
                                      and iscbc.supplier            = ecl.supplier
                                      and iscbc.origin_country_id   = ecl.origin_country_id
                                      and iscbc.bracket_value1      = ecl.bracket_value1
                                      and iscbc.location is NULL;

         if I_cost_status = 'A' then
            -- If new cost change is inserted in 'A'pproved status, write
            -- record(s) to temp table so future_cost will be rebuilt
            insert into cost_change_trigger_temp(cost_change,
                                                 item,
                                                 supplier,
                                                 origin_country_id,
                                                 loc,
                                                 loc_type,
                                                 unit_cost,
                                                 active_date)
                                          select I_cost_change_no,
                                                 item,
                                                 supplier,
                                                 origin_country_id,
                                                 NULL,
                                                 NULL,
                                                 unit_cost,
                                                 I_active_date
                                            from cost_susp_sup_detail
                                           where cost_change = I_cost_change_no
                                             and default_bracket_ind = 'Y';
         end if;
      end if; --- end if L_bracket = 'Y' and L_loc = 'N'
   end if; --- end if I_costed_ind = 'Y'

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CREATE_COST_CHG;
--------------------------------------------------------------------------------------------------------------
FUNCTION VERIFY_DETAIL_RECORDS(O_error_message    IN OUT   VARCHAR2,
                               O_exists           IN OUT   VARCHAR2,
                               I_seq_no           IN       EDI_COST_CHG.SEQ_NO%TYPE) return BOOLEAN is

L_program             VARCHAR2(64) := 'EDI_COST_CHG_SQL.VERFIY_DETAIL_RECORDS';


cursor C_GET_DETAIL is
   select 'Y'
     from edi_cost_chg ecg,
          edi_cost_loc ecl
    where ecg.seq_no = I_seq_no
      and ecg.seq_no = ecl.seq_no;

BEGIN
   O_exists := 'N';

   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_seq_no',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_GET_DETAIL', 'EDI_COST_LOC','sequence number: ' || to_char(I_seq_no));
   OPEN C_GET_DETAIL;

   SQL_LIB.SET_MARK('FETCH', 'C_GET_DETAIL','EDI_COST_LOC','sequence number: ' || to_char(I_seq_no));
   FETCH C_GET_DETAIL into O_exists;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_DETAIL','EDI_COST_LOC','sequence number: ' || to_char(I_seq_no));
   CLOSE C_GET_DETAIL;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END VERIFY_DETAIL_RECORDS;
--------------------------------------------------------------------------------------------------------------
FUNCTION CHECK_SUPP_VARIANCES(O_error_message          IN OUT   VARCHAR2,
                              O_approved               IN OUT   BOOLEAN,
                              I_seq_no                 IN       EDI_COST_CHG.SEQ_NO%TYPE,
                              I_percent_dollar_var     IN       VARCHAR2,
                              I_new_cost               IN       EDI_COST_CHG.UNIT_COST%TYPE,
                              I_old_cost               IN       ITEM_SUPP_COUNTRY.UNIT_COST%TYPE,
                              I_costed_ind             IN       VARCHAR2,
                              I_supplier               IN       EDI_COST_CHG.SUPPLIER%TYPE) return BOOLEAN is

L_program            VARCHAR2(64) := 'EDI_COST_CHG_SQL.CHECK_SUPP_VARIANCE';
L_cost_pct_var       SUPS.COST_CHG_PCT_VAR%TYPE;
L_cost_amt_var       SUPS.COST_CHG_AMT_VAR%TYPE;
L_new_cost           EDI_COST_LOC.UNIT_COST_NEW%TYPE;
L_old_cost           EDI_COST_LOC.UNIT_COST_OLD%TYPE;
L_exists_amt         VARCHAR2(1);
L_exists_pct         VARCHAR2(1);

cursor C_SUPS is
   select nvl(cost_chg_pct_var,0),
          nvl(cost_chg_amt_var,0)
     from sups
    where sups.supplier = I_supplier;
---

cursor C_VAR_AMOUNT is
   select 'X'
     from edi_cost_loc e
    where e.unit_cost_new > (e.unit_cost_old + L_cost_amt_var)
      and e.seq_no        = I_seq_no
UNION ALL
   select 'X'
     from edi_cost_loc e
    where e.unit_cost_new < (e.unit_cost_old - L_cost_amt_var)
      and e.seq_no        = I_seq_no;
---

cursor C_VAR_PCT is
   select 'X'
     from edi_cost_loc e
    where e.unit_cost_new > (e.unit_cost_old + (e.unit_cost_old * (L_cost_pct_var/100)))
      and e.seq_no        = I_seq_no
UNION ALL
   select 'X'
     from edi_cost_loc e
    where e.unit_cost_new < (e.unit_cost_old - (e.unit_cost_old * (L_cost_pct_var/100)))
      and e.seq_no        = I_seq_no;

---

Begin
   --- Verify that input variables are correctly populated
   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_costed_ind is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_costed_ind',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_percent_dollar_var is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_percent_dollar_var',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   --- If the costed ind is 'N' (item level cost change) the old cost
   --- must not be passed in as NULL.
   if I_costed_ind = 'N' and I_old_cost is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_old_cost',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   --- If the costed ind is 'N' (item level cost change) the new cost
   --- must not be passed in as NULL.
   if I_costed_ind = 'N' and I_new_cost is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_new_cost',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   --- If the costed ind is 'Y' (cost chnage other than item level) the seq_no
   --- can not be passed in as NULL since the check will be driven off
   --- the seq_no.
   if I_costed_ind = 'Y' and I_seq_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_seq_no',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   --- Set the approval flag equal to False.  This function
   --- will set this flag to TRUE if any of the checks pass.
   O_approved := FALSE;

   --- retrieve the supplier costing variances
   SQL_LIB.SET_MARK('OPEN', 'C_SUPS', 'SUPS', 'Supplier: ' || to_char(I_supplier));
   open C_SUPS;

   SQL_LIB.SET_MARK('FETCH', 'C_SUPS', 'SUPS', 'Supplier: ' || to_char(I_supplier));
   fetch C_SUPS into L_cost_pct_var,
                     L_cost_amt_var;

   --- Check supplier tolerances for an EDI cost change at the item level.
   --- The old and new cost will be passed in directly from the EDICOST.fmb Form
   if I_costed_ind = 'N' then

      --- The new cost must fall within both percent and dollar variance
      --- of the old cost if 'B'oth is passed in.
      if I_percent_dollar_var = 'B' then
         if ((I_new_cost <= (I_old_cost + L_cost_amt_var)) and
             (I_new_cost >= (I_old_cost - L_cost_amt_var)) and
             (I_new_cost <= (I_old_cost + (I_old_cost * L_cost_pct_var/100))) and
             (I_new_cost >= (I_old_cost - (I_old_cost * L_cost_pct_var/100)))) then
            O_approved := TRUE;
         end if;

      --- The new cost must fall within either percent or dollar variance
      --- of the old cost if 'E'ither is passed in.
      elsif I_percent_dollar_var = 'E' then
         if (((I_new_cost <= (I_old_cost + L_cost_amt_var)) and
              (I_new_cost >= (I_old_cost - L_cost_amt_var))) OR
             ((I_new_cost <= (I_old_cost + (I_old_cost * L_cost_pct_var/100))) and
              (I_new_cost >= (I_old_cost - (I_old_cost * L_cost_pct_var/100))))) then
            O_approved := TRUE;
         end if;

      --- The new cost must fall within dollar variance of the old cost
      --- if 'D'ollar is passed in.
      elsif I_percent_dollar_var = 'D' then
         if ((I_new_cost <= (I_old_cost + L_cost_amt_var)) and
             (I_new_cost >= (I_old_cost - L_cost_amt_var))) then
            O_approved := TRUE;
         end if;

      --- The new cost must fall within percent variance of the old cost
      --- if 'P'ercent is passed in.
      elsif I_percent_dollar_var = 'P' then
         if ((I_new_cost <= (I_old_cost + (I_old_cost * L_cost_pct_var/100))) and
             (I_new_cost >= (I_old_cost - (I_old_cost * L_cost_pct_var/100)))) then
            O_approved := TRUE;
         end if;
      end if;

   else --- If the cost change is at the item/bracket, item/location, or item/location/bracket

      -- Find if the costs for the bracket or location are out of the tolerance limits.
      -- If they are, set O_approved to False.  If no records are found out of tolerance ranges, then
      -- set O_approved True.

      O_approved := FALSE;

      --- The new cost must fall within both percent and dollar variance
      --- of the old cost if 'B'oth is passed in.
      if I_percent_dollar_var = 'B' then

         SQL_LIB.SET_MARK('OPEN', 'C_VAR_AMOUNT', 'EDI_COST_LOC', NULL);
         open C_VAR_AMOUNT;

         SQL_LIB.SET_MARK('FETCH', 'C_VAR_AMOUNT', 'EDI_COST_LOC', NULL);
         fetch C_VAR_AMOUNT into L_exists_amt;

         --- If the cost is not outside of the amount variance
         --- then check to see if the cost is outside of the percent variance
         if C_VAR_AMOUNT%NOTFOUND then

            SQL_LIB.SET_MARK('OPEN', 'C_VAR_PCT', 'EDI_COST_LOC', NULL);
            open C_VAR_PCT;

            SQL_LIB.SET_MARK('FETCH', 'C_VAR_PCT', 'EDI_COST_LOC', NULL);
            fetch C_VAR_PCT into L_exists_pct;

            --- If the cost is still not outside of the variance then
            --- set O_approved equal to TRUE
            if C_VAR_PCT%NOTFOUND then
               O_approved := TRUE;
            end if;

            SQL_LIB.SET_MARK('CLOSE', 'C_VAR_PCT', 'EDI_COST_LOC', NULL);
            close C_VAR_PCT;
         end if;

         SQL_LIB.SET_MARK('CLOSE', 'C_VAR_AMOUNT', 'EDI_COST_LOC', NULL);
         close C_VAR_AMOUNT;

      end if;  --- end if  I_percent_dollar_var = 'B'

      --- The new cost must fall within either percent or dollar variance
      --- of the old cost if 'E'ither is passed in.
      if I_percent_dollar_var = 'E' then

         SQL_LIB.SET_MARK('OPEN', 'C_VAR_AMOUNT', 'EDI_COST_LOC', NULL);
         open C_VAR_AMOUNT;

         SQL_LIB.SET_MARK('FETCH', 'C_VAR_AMOUNT', 'EDI_COST_LOC', NULL);
         fetch C_VAR_AMOUNT into L_exists_amt;

         --- If the cost is not outside of the amount variance
         --- then update O_approved to TRUE
         if C_VAR_AMOUNT%NOTFOUND then
            O_approved := TRUE;

         --- If the amount is outside of the supplier dollar variance then
         --- check to see if it is outside the percent variance
         else

            SQL_LIB.SET_MARK('OPEN', 'C_VAR_PCT', 'EDI_COST_LOC', NULL);
            open C_VAR_PCT;

            SQL_LIB.SET_MARK('FETCH', 'C_VAR_PCT', 'EDI_COST_LOC', NULL);
            fetch C_VAR_PCT into L_exists_pct;

            --- If the cost is not outside of the variance then
            --- set O_approved equal to TRUE
            if C_VAR_PCT%NOTFOUND then
               O_approved := TRUE;
            end if;

            SQL_LIB.SET_MARK('CLOSE', 'C_VAR_PCT', 'EDI_COST_LOC', NULL);
            close C_VAR_PCT;
         end if;

         SQL_LIB.SET_MARK('CLOSE', 'C_VAR_AMOUNT', 'EDI_COST_LOC', NULL);
         close C_VAR_AMOUNT;
      end if;  --- end if I_percent_dollar_var = 'E'

      --- The new cost must fall within dollar variance of the old cost
      --- if 'D'ollar is passed in.
      if I_percent_dollar_var = 'D' then

         SQL_LIB.SET_MARK('OPEN', 'C_VAR_AMOUNT', 'EDI_COST_LOC', NULL);
         open C_VAR_AMOUNT;

         SQL_LIB.SET_MARK('FETCH', 'C_VAR_AMOUNT', 'EDI_COST_LOC', NULL);
         fetch C_VAR_AMOUNT into L_exists_amt;

         --- If the cost is not outside of the amount variance
         --- then update O_approved to TRUE
         if C_VAR_AMOUNT%NOTFOUND then
            O_approved := TRUE;
         end if;

         SQL_LIB.SET_MARK('CLOSE', 'C_VAR_AMOUNT', 'EDI_COST_LOC', NULL);
         close C_VAR_AMOUNT;
      end if;  --- end if I_percent_dollar_var = 'D'

      --- The new cost must fall within percent variance of the old cost
      --- if 'P'ercent is passed in.
      if I_percent_dollar_var = 'P' then

         SQL_LIB.SET_MARK('OPEN', 'C_VAR_PCT', 'EDI_COST_LOC', NULL);
         open C_VAR_PCT;

         SQL_LIB.SET_MARK('FETCH', 'C_VAR_PCT', 'EDI_COST_LOC', NULL);
         fetch C_VAR_PCT into L_exists_pct;

         --- If the cost is not outside of the variance then
         --- set O_approved equal to TRUE
         if C_VAR_PCT%NOTFOUND then
            O_approved := TRUE;
         end if;

         SQL_LIB.SET_MARK('CLOSE', 'C_VAR_PCT', 'EDI_COST_LOC', NULL);
         close C_VAR_PCT;
      end if;  --- end if I_percent_dollar_var = 'P'

   end if;  --- end L_costed_ind = 'N' else L_loc_costed_ind = 'Y'

   SQL_LIB.SET_MARK('CLOSE', 'C_SUPS', 'SUPS', 'Supplier: ' || I_supplier);
   close C_SUPS;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CHECK_SUPP_VARIANCES;
--------------------------------------------------------------------------------------------------------------
END EDI_COST_CHG_SQL;
/

