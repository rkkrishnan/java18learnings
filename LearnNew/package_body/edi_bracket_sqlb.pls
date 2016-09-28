CREATE OR REPLACE PACKAGE BODY EDI_BRACKET_SQL AS
------------------------------------------------
FUNCTION UPDATE_COST_CHG(O_error_message   IN OUT   VARCHAR2,
                         I_cost_ind        IN       EDI_COST_CHG.STATUS%TYPE,
                         I_seq_no          IN       EDI_COST_CHG.SEQ_NO%TYPE) return BOOLEAN IS

   L_program         VARCHAR2(64) := 'EDI_BRACKET_SQL.UPDATE_COST_CHG';
   L_table           VARCHAR2(64) := 'EDI_COST_CHG';
   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_EDI_COST is
      select 'x'
        from EDI_COST_CHG
       where seq_no = I_seq_no
         for update nowait;

BEGIN
   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'Seq_No',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_EDI_COST', 'EDI_COST_CHG', NULL);
   open C_LOCK_EDI_COST;

   SQL_LIB.SET_MARK('CLOSE','C_LOCK_EDI_COST', 'EDI_COST_CHG', NULL);
   close C_LOCK_EDI_COST;

   SQL_LIB.SET_MARK('UPDATE',NULL,'EDI_COST_CHG', 'sequence number: ' || to_char(I_seq_no));

   update edi_cost_chg
      set status = I_cost_ind
    where seq_no = I_seq_no;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_seq_no,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_COST_CHG;
------------------------------------------------------------------------------------
FUNCTION VALIDATE_BRACKET(O_error_message   IN OUT   VARCHAR2,
                          O_exists          IN OUT   VARCHAR2,
                          O_default_Bracket IN OUT   SUP_BRACKET_COST.DEFAULT_BRACKET_IND%TYPE,
                          I_item            IN       ITEM_MASTER.ITEM%TYPE,
                          I_supplier        IN       SUP_BRACKET_COST.SUPPLIER%TYPE,
                          I_location        IN       SUP_BRACKET_COST.LOCATION%TYPE,
                          I_bracket_value1  IN       SUP_BRACKET_COST.BRACKET_VALUE1%TYPE,
                          I_uom1            IN       SUP_INV_MGMT.BRACKET_UOM1%TYPE,
                          I_bracket_type1   IN       SUP_INV_MGMT.BRACKET_TYPE1%TYPE,
                          I_bracket_value2  IN       SUP_BRACKET_COST.BRACKET_VALUE2%TYPE) return BOOLEAN IS

L_program         VARCHAR2(64) := 'EDI_BRACKET_SQL.VALIDATE_BRACKET';
L_dept            ITEM_MASTER.DEPT%TYPE;
L_class           ITEM_MASTER.CLASS%TYPE;
L_subclass        ITEM_MASTER.SUBCLASS%TYPE;
L_bracket_level   VARCHAR2(1);


---
cursor C_CHECK_SUPP_DPT_LOC is
   select 'Y',
          sbc.default_bracket_ind
     from sup_bracket_cost sbc,
          sup_inv_mgmt sim
    where sbc.supplier                 = I_supplier
      and sbc.dept                     = L_dept
      and sbc.location                 = I_location
      and sbc.bracket_value1           = I_bracket_value1
      and NVL(sbc.bracket_value2, -1)  = NVL(I_bracket_value2, -1)
      and NVL(sim.bracket_uom1,'NULL') = NVL(I_uom1,'NULL')
      and sim.bracket_type1            = I_bracket_type1
      and sim.sup_dept_seq_no          = sbc.sup_dept_seq_no;

---
cursor C_CHECK_SUPP_LOC is
   select 'Y',
          sbc.default_bracket_ind
     from sup_bracket_cost sbc,
          sup_inv_mgmt sim
    where sbc.supplier                 = I_supplier
      and sbc.location                 = I_location
      and sbc.bracket_value1           = I_bracket_value1
      and NVL(sbc.bracket_value2, -1)  = NVL(I_bracket_value2, -1)
      and sbc.dept                    is NULL
      and NVL(sim.bracket_uom1,'NULL') = NVL(I_uom1,'NULL')
      and sim.bracket_type1            = I_bracket_type1
      and sim.sup_dept_seq_no          = sbc.sup_dept_seq_no;

---
cursor C_CHECK_SUPP_DPT is
   select 'Y',
          sbc.default_bracket_ind
     from sup_bracket_cost sbc,
          sup_inv_mgmt sim
    where sbc.supplier                  = I_supplier
      and sbc.dept                      = L_dept
      and sbc.bracket_value1            = I_bracket_value1
      and NVL(sbc.bracket_value2, -1)   = NVL(I_bracket_value2, -1)
      and sbc.location                 is NULL
      and NVL(sim.bracket_uom1, 'NULL') = NVL(I_uom1,'NULL')
      and sim.bracket_type1             = I_bracket_type1
      and sim.sup_dept_seq_no           = sbc.sup_dept_seq_no;

---
cursor C_CHECK_SUPP is
   select 'Y',
          sbc.default_bracket_ind
     from sup_bracket_cost sbc,
          sup_inv_mgmt sim
    where sbc.supplier                 = I_supplier
      and sbc.bracket_value1           = I_bracket_value1
      and NVL(sbc.bracket_value2, -1)  = NVL(I_bracket_value2,-1)
      and sbc.dept                    is NULL
      and sbc.location                is NULL
      and NVL(sim.bracket_uom1,'NULL') = NVL(I_uom1,'NULL')
      and sim.bracket_type1            = I_bracket_type1
      and sim.sup_dept_seq_no          = sbc.sup_dept_seq_no;

---

BEGIN

   O_exists := 'N';

   --- Verify that all values needed for process are not null
   if I_item is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_bracket_value1 is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_bracket_value1',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_bracket_type1 is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_bracket_type1',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_uom1 is NULL and (I_bracket_type1 = 'M' or I_bracket_type1 = 'V') then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_bracket_uom1',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;


   if not SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                              L_bracket_level,
                                              I_supplier) then

      return FALSE;
   end if;

   --- Bracket levels for L_bracket_level:
   --- A = Supp/dept/loc
   --- S = Supp
   --- D = Supp/Dept
   --- L = Supp/loc

   --- if the bracket is supp/dept/loc or supp/dept
   --- retrieve the department
   if L_bracket_level = 'A' or L_bracket_level = 'D' then

      if not ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                            I_item,
                                            L_dept,
                                            L_class,
                                            L_subclass) then
         return FALSE;
      end if;
   end if;

   --- If the bracket is labeled as a supplier/department/location level bracket
   --- 1.  Check against the supplier/department/location level bracket, if it does not exist then
   --- 2.  Check against the supplier/department level bracket, if it does not exist then
   --- 3.  Check against the supplier level bracket
   if L_bracket_level = 'A' then

      ---validat against supp/dept/loc
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SUPP_DPT_LOC', 'SUP_BRACKET_COST',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',department: '||to_char(L_dept)||
                       ',Location: '||to_char(I_location));
      open C_CHECK_SUPP_DPT_LOC;

      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SUPP_DPT_LOC', 'SUP_BRACKET_COST',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',department: '||to_char(L_dept)||
                       ',Location: '||to_char(I_location));
      fetch C_CHECK_SUPP_DPT_LOC into O_exists,
                                      O_default_bracket;

      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SUPP_DPT_LOC', 'SUP_BRACKET_COST',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',department: '||to_char(L_dept)||
                       ',Location: '||to_char(I_location));
      close C_CHECK_SUPP_DPT_LOC;

      --- if supp/dept/loc does not exist then check against supp/dept
      if O_exists = 'N' then

         SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SUPP_DPT', 'SUP_BRACKET_COST',
                       ',item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',department: '||to_char(L_dept));
         open C_CHECK_SUPP_DPT;

         SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SUPP_DPT', 'SUP_BRACKET_COST',
                       ',item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',department: '||to_char(L_dept));
         fetch C_CHECK_SUPP_DPT into O_exists,
                                     O_default_bracket;

         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SUPP_DPT', 'SUP_BRACKET_COST',
                       ',item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',department: '||to_char(L_dept));
         close C_CHECK_SUPP_DPT;
      end if;

      --- is supp/dept does not exist, check against supplier level
      if O_exists = 'N' then

         SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SUPP', 'SUP_BRACKET_COST',
                          'item: '|| I_item || ',supplier: '||to_char(I_supplier));
         open C_CHECK_SUPP;

         SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SUPP', 'SUP_BRACKET_COST',
                          'item: '|| I_item || ',supplier: '||to_char(I_supplier));
         fetch C_CHECK_SUPP into O_exists,
                                 O_default_bracket;

         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SUPP', 'SUP_BRACKET_COST',
                          'item: '|| I_item || ',supplier: '||to_char(I_supplier));
         close C_CHECK_SUPP;
      end if;

   --- If the bracket is a supplier/dept bracket then
   --- 1.  Validate against supp/dept, if the bracket does not exist then
   --- 2.  Validate against the supp level
   elsif L_bracket_level = 'D' then

      --- Validate against supp/dept
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SUPP_DPT', 'SUP_BRACKET_COST',
                       ',item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',department: '||to_char(L_dept));
      open C_CHECK_SUPP_DPT;

      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SUPP_DPT', 'SUP_BRACKET_COST',
                       ',item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',department: '||to_char(L_dept));
      fetch C_CHECK_SUPP_DPT into O_exists,
                                  O_default_bracket;

      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SUPP_DPT', 'SUP_BRACKET_COST',
                       ',item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',department: '||to_char(L_dept));
      close C_CHECK_SUPP_DPT;

      --- if supp/dept does not exist, validate against supp level
      if O_exists = 'N' then

         SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SUP', 'SUPP_BRACKET_COST',
                          'item: '|| I_item || ',supplier: '||to_char(I_supplier));
         open C_CHECK_SUPP;

         SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SUP', 'SUPP_BRACKET_COST',
                          'item: '|| I_item || ',supplier: '||to_char(I_supplier));
         fetch C_CHECK_SUPP into O_exists,
                                 O_default_bracket;

         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SUP', 'SUPP_BRACKET_COST',
                          'item: '|| I_item || ',supplier: '||to_char(I_supplier));
         close C_CHECK_SUPP;
      end if;

   --- If the bracket is a supplier/loc bracket then
   --- 1.  Validate against supp/loc, if the bracket does not exist then
   --- 2.  Validate against the supp level
   elsif L_bracket_level = 'L' then

      --- Validate against supp/loc
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SUPP_LOC', 'SUP_BRACKET_COST',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier)||
                       ',Location: '||to_char(I_location));
      open C_CHECK_SUPP_LOC;

      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SUPP_LOC', 'SUP_BRACKET_COST',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier)||
                       ',Location: '||to_char(I_location));
      fetch C_CHECK_SUPP_LOC into O_exists,
                                  O_default_bracket;

      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SUPP_LOC', 'SUP_BRACKET_COST',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier)||
                       ',Location: '||to_char(I_location));
      close C_CHECK_SUPP_LOC;

      --- if supp/dept does not exist, validate against supp level
      if O_exists = 'N' then

         SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SUPP', 'SUP_BRACKET_COST',
                          'item: '|| I_item || ',supplier: '||to_char(I_supplier));
         open C_CHECK_SUPP;

         SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SUPP', 'SUP_BRACKET_COST',
                          'item: '|| I_item || ',supplier: '||to_char(I_supplier));
         fetch C_CHECK_SUPP into O_exists,
                                 O_default_bracket;

         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SUPP', 'SUP_BRACKET_COST',
                          'item: '|| I_item || ',supplier: '||to_char(I_supplier));
         close C_CHECK_SUPP;
      end if;

   --- If the bracket is a supplier bracket, validate the against the supp level
   elsif L_bracket_level = 'S' then

      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SUPP', 'SUP_BRACKET_COST',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier));
      open C_CHECK_SUPP;

      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SUPP', 'SUP_BRACKET_COST',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier));
      fetch C_CHECK_SUPP into O_exists,
                              O_default_bracket;

      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SUPP', 'SUP_BRACKET_COST',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier));
      close C_CHECK_SUPP;
   end if; --- End if L_bracket_level = 'S';


   if O_exists = 'N' then

      if not INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                                  'Bracket value for supplier: ' || to_char(I_supplier)
                                                  || ' failed validation',
                                                  'EDI_BRACKET_SQL.VALIDATE_BRACKET',
                                                  'item: ' || I_item || ' location: ' || to_char(I_location) ||
                                                  ',bracket value1: ' || to_char(I_bracket_value1) ||
                                                  ',bracket value2: ' || to_char(I_bracket_value2)) then
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
END VALIDATE_BRACKET;
------------------------------------------------------------------------------------
FUNCTION UPDATE_COSTS(O_error_message   IN OUT    VARCHAR2,
                      I_item            IN        EDI_COST_LOC.ITEM%TYPE,
                      I_supplier        IN        EDI_COST_LOC.SUPPLIER%TYPE,
                      I_country         IN        EDI_COST_LOC.ORIGIN_COUNTRY_ID%TYPE,
                      I_seq_no          IN        EDI_COST_LOC.SEQ_NO%TYPE,
                      I_costed_ind      IN        VARCHAR2,
                      I_update_child    IN        VARCHAR2) return BOOLEAN IS

L_program             VARCHAR2(64) := 'EDI_BRACKET_SQL.UPDATE_COSTS';
L_table               VARCHAR2(64) := 'EDI_COST_CHG';
L_new_cost            ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
L_unit_cost           ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
L_bracket_value1      ITEM_SUPP_COUNTRY_BRACKET_COST.BRACKET_VALUE1%TYPE;
L_bracket_value2      ITEM_SUPP_COUNTRY_BRACKET_COST.BRACKET_VALUE1%TYPE;
L_loc_costed_flag     VARCHAR2(1) := NULL;
L_location            EDI_COST_LOC.LOCATION%TYPE;
L_virtual_loc         WH.WH%TYPE;
L_multichannel_flag   VARCHAR2(1);
RECORD_LOCKED         EXCEPTION;
PRAGMA                EXCEPTION_INIT(Record_Locked, -54);


--- Cursors for non-multichannel environment

cursor C_SUPP_LOC is
   select loc
     from item_supp_country_loc
    where item              = I_item
      and supplier          = I_supplier
      and origin_country_id = I_country;

---
cursor C_LOCK_ITEM_SUPP_COUNTRY is
   select 'x'
     from item_supp_country
    where origin_country_id = I_country
      and supplier          = I_supplier
      and item              = I_item
      for update nowait;

---
cursor C_LOCK_ITEM_SUPP_COUNTRY_CHILD is
   select 'x'
     from item_supp_country
    where origin_country_id = I_country
      and supplier          = I_supplier
      and item in (select im.item
                     from item_master im
                    where (im.item_parent       = I_item or
                           im.item_grandparent  = I_item)
                      and im.item_level        <= im.tran_level)
      for update nowait;
---

cursor C_SELECT_EDI_COST_CHG is
   select unit_cost
     from edi_cost_chg
    where seq_no = I_seq_no;

---
cursor C_LOCK_SUPP_CNTRY_BRKT_COST is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1    = L_bracket_value1
      and (location         = L_location
       or location          is NULL)
      and origin_country_id = I_country
      and supplier          = I_supplier
      and item              = I_item
      for update nowait;

---
cursor C_LOCK_SUPP_COUNTRY_LOC is
   select 'x'
     from item_supp_country_loc
    where loc               = L_location
      and origin_country_id = I_country
      and supplier          = I_supplier
      and item              = I_item
      for update nowait;

---
cursor C_SELECT_BRACKET is
   select bracket_value1,
          bracket_value2,
          unit_cost_new,
          location
     from edi_cost_loc
    where seq_no = I_seq_no;

---
cursor C_GET_LOCATIONS is
   select distinct location
     from edi_cost_loc
    where seq_no = I_seq_no;

---
cursor C_LOCK_BRACKET_CHILD is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1     = L_bracket_value1
      and location           is NULL
      and origin_country_id  = I_country
      and supplier           = I_supplier
      and item in (select im.item
                     from item_master im,
                          item_supp_country_bracket_cost iscbc
                    where iscbc.supplier          = I_supplier
                      and iscbc.origin_country_id = I_country
                      and (im.item_parent         = I_item or
                          im.item_grandparent     = I_item)
                      and im.item_level          <= im.tran_level
                      and iscbc.item              = im.item)
      for update nowait;

--- Cursors for multichannel environment

cursor C_LOCK_MULTICHANNEL is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1    = L_bracket_value1
      and location          = L_virtual_loc
      and origin_country_id = I_country
      and supplier          = I_supplier
      and item              = I_item
      for update nowait;

---
 cursor C_SELECT_VIRTUALS is
   select wh
     from wh
    where physical_wh = L_location;

---
cursor C_LOCK_SUPP_CTRY_LOC_MULT is
   select 'x'
     from item_supp_country_loc
    where loc               = L_virtual_loc
      and origin_country_id = I_country
      and supplier          = I_supplier
      and item              = I_item
      for update nowait;

---
cursor C_LOCK_SUPP_BRK_MULT_CHILD is
    select 'x'
      from item_supp_country_bracket_cost
     where bracket_value1    = L_bracket_value1
       and location in (select wh
                          from wh
                         where physical_wh = L_location)
       and origin_country_id  = I_country
       and supplier           = I_supplier
       and item in (select im.item
                      from item_master im,
                           item_supp_country_bracket_cost iscbc
                     where iscbc.supplier           = I_supplier
                       and iscbc.origin_country_id  = I_country
                       and (im.item_parent          = I_item or
                            im.item_grandparent     = I_item)
                       and im.item_level           <= im.tran_level
                       and iscbc.item               = im.item)
       for update nowait;

---
cursor C_SELECT_ALL_VIRTUALS is
   select wh
     from wh
    where physical_wh = L_location
      and stockholding_ind = 'Y'
 UNION ALL
   select store
     from store
    where store = L_location;

---

BEGIN
   --- NULL value validation
   if I_item is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_country is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'country',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_costed_ind is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'costed_ind',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_update_child is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'update_child',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'seq_no',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;


  --- If it is not location costed or bracket costed (record comes from EDI_COST_CHG):
   --- First update the ITEM_SUPP_COUNTRY record for the item.
   --- Then update the ITEM_SUPP_COUNTRY_LOC records with the unit cost
   --- from ITEM_SUPP_COUNTRY_LOC.  If children items are to be updated,
   --- first, update the children records on ITEM_SUPP_COUNTRY.  Then loop
   --- through the parent item's locations and update the costs on
   --- ITEM_SUPP_COUNTRY_LOC for the child items with the unit cost on
   --- ITEM_SUPP_COUNTRY.
   if I_costed_ind = 'N' then

      SQL_LIB.SET_MARK('OPEN', 'C_SELECT_EDI_COST_CHG', 'EDI_COST_CHG',NULL);
      open C_SELECT_EDI_COST_CHG;

      SQL_LIB.SET_MARK('FETCH', 'C_SELECT_EDI_COST_CHG', 'EDI_COST_CHG',NULL);
      fetch C_SELECT_EDI_COST_CHG into L_unit_cost;

      SQL_LIB.SET_MARK('CLOSE','C_SELECT_EDI_COST_CHG ', 'EDI_COST_CHG',NULL);
      close C_SELECT_EDI_COST_CHG;

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPP_COUNTRY',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier) || ',country: ' || I_country);
      open C_LOCK_ITEM_SUPP_COUNTRY;

      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPP_COUNTRY',
                       'item: '|| I_item || ',supplier: '||to_char(I_supplier)|| ',country: ' || I_country);
      close C_LOCK_ITEM_SUPP_COUNTRY;

      --- update ITEM_SUPP_COUNTRY with the new unit cost
      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY',
                       'Item: '||I_item
                       || ',Supplier: ' ||to_char(I_supplier)
                       || ',country: ' || I_country);

      update item_supp_country
         set unit_cost            = L_unit_cost,
             last_update_id       = user,
             last_update_datetime = sysdate
       where origin_country_id    = I_country
         and supplier             = I_supplier
         and item                 = I_item;

      --- update all ITEM_SUPP_COUNTRY_LOC records for the item
      --- with the unit cost on ITEM_SUPP_COUNTRY
      if not UPDATE_BASE_COST.CHANGE_ISC_COST(O_error_message,
                                              I_item,
                                              I_supplier,
                                              I_country,
                                              'Y')then
         return FALSE;
      end if;

      if I_update_child = 'Y' then
         -- Update the new parent unit cost on ITEM_SUPP_COUNTRY
         -- to children items on ITEM_SUPP_COUNTRY.

         SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPP_COUNTRY_CHILD', 'ITEM_SUPP_COUNTRY',NULL);
         open C_LOCK_ITEM_SUPP_COUNTRY_CHILD;

         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPP_COUNTRY_CHILD', 'ITEM_SUPP_COUNTRY',NULL);
         close C_LOCK_ITEM_SUPP_COUNTRY_CHILD;

         --- update ITEM_SUPP_COUNTRY with the new unit cost
         SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY',NULL);

              update item_supp_country
                 set unit_cost            = L_unit_cost,
                     last_update_id       = user,
                     last_update_datetime = sysdate
               where origin_country_id    = I_country
                 and supplier             = I_supplier
                 and item in (select im.item
                                from item_master im
                               where (im.item_parent         = I_item or
                                      im.item_grandparent    = I_item)
                                 and im.item_level          <= im.tran_level);

      end if; --- End if I_update_child = 'Y' .

      -- Loop through all locations for the parent item.  Update the unit cost
      -- on the ITEM_SUPP_COUNTRY_LOC table with the unit cost on ITEM_SUPP_COUNTRY.
      -- Update all children lcoations as well.
      SQL_LIB.SET_MARK('FETCH','C_SUPP_LOC','ITEM_SUPP_COUNTRY_LOC',NULL);
      FOR rec in C_SUPP_LOC
      LOOP
         L_location := rec.loc;

         if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                             I_item,
                                             I_supplier,
                                             I_country,
                                             L_location,
                                             I_update_child,
                                             'Y',
                                             NULL /* Cost Change Number */ ) then
            return FALSE;
         end if;

      END LOOP; --- End loop through locations

   end if;  --- end if not location or bracket costed

   --- If it is bracket costed and/or location costed (records come from EDI_COST_LOC):
   --- Grab the multichannel indicator from system option to see if the system is set
   --- for multichannel locations.
   --- Begin looping through records on EDI_COST_LOC.  Check to see if locations are provided.
   --- If locations are provided, then check to see if it is a multichannel environment.  If it is a
   --- multichannel environment, do the following:
   --- 1.  Check if brackets are provided, if they are update the cost on ITEM_SUPP_COUNTRY_BRACKET_COST
   ---     for the item/location/bracket where the location is the virtual location.
   --- 2.  Check to see if children are to be updated.  If they are, update the child item brackets on
   ---     ITEM_SUPP_COUNTRY_BRACKET_COST.
   --- 3.  Check to see if brackets are not provided.  If they are not, update only the virtual location records
   ---     On ITEM_SUPP_COUNTRY_LOC.  If the primary location is updated, update the unit cost on ITEM_SUPP_COUNTRY.
   ---     If child items are to be updated, perform the same cost updates for them.
   --- If the environment is not multi_channel, do the following:
   --- 1.  Check if brackets are provided, if they are update the cost on ITEM_SUPP_COUNTRY_BRACKET_COST
   ---     for the item/location/bracket where the location is the physical location.
   --- 2.  Check to see if children are to be updated.  If they are, update the child item brackets on
   ---     ITEM_SUPP_COUNTRY_BRACKET_COST.
   --- 3.  Check to see if brackets are not provided.  If they are not, update only the physical location records
   ---     On ITEM_SUPP_COUNTRY_LOC.  If the primary location is updated, update the unit cost on ITEM_SUPP_COUNTRY.
   ---     If child items are to be updated, perform the same cost updates for them.
   --- After looping through the EDI_COST_LOC records,loop through the distinct locations on EDI_COST_LOC if
   --- the supplier is bracket costed and locations are provided and update
   --- costs on ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY. First, grab all the distinct locations then loop through
   --- them.  If it is a multichannel environment, perform the following:
   --- 1.   Grab all the virtaul locations for the physical location and loop through them.
   --- 2.   Update the costs on ITEM_SUPP_COUNTRY_LOC with the default bracket cost for the virtual location.
   --- 3.   If the location is the primary location update ITEM_SUPP_COUNTRY with that unit cost.
   --- 4.   If children are to be updated, perform the same updates on them.
   --- If it is not a multichannel environment, perform the following:
   --- 1.   Update the costs on ITEM_SUPP_COUNTRY_LOC with the default bracket cost for the physical location.
   --- 2.   If the location is the primary location update ITEM_SUPP_COUNTRY with that unit cost.
   --- 3.   If children are to be updated, perform the same updates on them.
   --- If the item is not location costed but bracket costed,
   --- update all location level brackets for the item.  Then update
   --- item_supp_country_loc for the default bracket.  Update the
   --- unit cost on item_supp_country for the primary location.
   --- If the update child ind is passed in as 'Y', then make the same updates
   --- to the children.

   --- If the item is location or bracket costed (Records come from EDI_COST_LOC)
   if I_costed_ind = 'Y' then

      ---Get the multi_channel indicator
      if not SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                     L_multichannel_flag) then
         return FALSE;
      end if;

      --- loop through all records on EDI_COST_LOC
      --- and update costs on ITEM_SUPP_COUNTRY_BRACKET_COST if it is bracket
      --- costed or just ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY
      SQL_LIB.SET_MARK('FETCH','C_SELECT_BRACKET','EDI_COST_LOC',NULL);
      FOR rec in C_SELECT_BRACKET
      LOOP
         L_bracket_value1 := rec.bracket_value1;
         L_bracket_value2 := rec.bracket_value2;
         L_new_cost       := rec.unit_cost_new;
         L_location       := rec.location;

         --- Set location costed flag
         if L_location is NULL then
            L_loc_costed_flag := 'N';
         else
            L_loc_costed_flag := 'Y';
         end if;

         --- if locations are provided in the input variables
         --- Then perform costing at the location level
         if L_loc_costed_flag = 'Y' then

            --- If the multichannel environment indicator is set to
            --- 'Y' then make updates to virtual locations
            if L_multichannel_flag = 'Y' then

               --- If brackets are provided in the input parameter
               --- then update the bracket's unit cost
               if L_bracket_value1 is not null then

                  --- The following will be used in a multichannel environment.
                  --- if locations are present, check if virtuals are present
                  --- if virtual locations are found, update ITEM_SUPP_CNTRY_BRACK_COST
                  --- for the virtual locations

                  SQL_LIB.SET_MARK('OPEN', 'C_LOCK_MULTICHANNEL', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  open C_LOCK_MULTICHANNEL;

                  SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_MULTICHANNEL', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  close C_LOCK_MULTICHANNEL;

                  SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);

                  update item_supp_country_bracket_cost
                     set unit_cost          = L_new_cost
                   where bracket_value1     = L_bracket_value1
                     and location in (select wh
                                        from wh
                                       where physical_wh = L_location)
                     and origin_country_id  = I_country
                     and supplier           = I_supplier
                     and item               = I_item;

                  --- Check to see if the update child flag is set to 'Y'.
                  --- If it is update child item brackets at a
                  --- virtual location level
                  if I_update_child = 'Y' then

                     SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_BRK_MULT_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                     open C_LOCK_SUPP_BRK_MULT_CHILD;

                     SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_BRK_MULT_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                     close C_LOCK_SUPP_BRK_MULT_CHILD;

                     SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);

                     update item_supp_country_bracket_cost
                        set unit_cost          = L_new_cost
                      where bracket_value1     = L_bracket_value1
                        and location in (select wh
                                           from wh
                                          where physical_wh = L_location)
                        and origin_country_id  = I_country
                        and supplier           = I_supplier
                        and item in (select im.item
                                       from item_master im,
                                            item_supp_country_bracket_cost iscbc
                                      where iscbc.supplier           = I_supplier
                                        and iscbc.origin_country_id  = I_country
                                        and (im.item_parent          = I_item or
                                             im.item_grandparent     = I_item)
                                        and im.item_level           <= im.tran_level
                                        and iscbc.item               = im.item);

                  end if; -- I_update_child = 'Y'
               end if; --- end if L_bracket_value1 is not null

               --- If the item is costed by location but not bracket
               --- UPDATE item_supp_country_loc and item_supp_country
               --- for virtual locations
               if L_bracket_value1 is NULL then

                  SQL_LIB.SET_MARK('FETCH','C_SELECT_ALL_VIRTUALS','EDI_COST_LOC',NULL);
                  FOR rec in C_SELECT_ALL_VIRTUALS
                  LOOP

                     L_virtual_loc := rec.wh;

                     SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_CTRY_LOC_MULT', 'ITEM_SUPP_COUNTRY_LOC',NULL);
                     open C_LOCK_SUPP_CTRY_LOC_MULT;

                     SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_CTRY_LOC_MULT', 'ITEM_SUPP_COUNTRY_LOC',NULL);
                     close C_LOCK_SUPP_CTRY_LOC_MULT;

                     SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC',NULL);

                     update item_supp_country_loc
                        set unit_cost            = L_new_cost,
                            last_update_id       = user,
                            last_update_datetime = sysdate
                      where loc                  = L_virtual_loc
                        and origin_country_id    = I_country
                        and supplier             = I_supplier
                        and item                 = I_item;


                     --- Update the records on item_supp_country with the unit
                     --- cost at the primary location.  If the child indicator
                     --- is passed in as 'Y', update all child record at the
                     --- the passed in location and update item_supp_country
                     --- for the primary location of the child items.
                     if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                                         I_item,
                                                         I_supplier,
                                                         I_country,
                                                         L_virtual_loc,
                                                         I_update_child,
                                                         'Y',
                                                         NULL /* Cost Change Number */ ) then
                        return FALSE;
                     end if;
                  END LOOP; --- End update virtuals
               end if; --- end if L_bracket_value1 is NULL
            end if; --- end if if L_multichannel_flag = 'Y'


            --- if it is not a multichannel environment
            --- Update the location brackets on ITEM_SUPP_COUNTRY_BRACKET_COST
            if L_multichannel_flag = 'N' then

               --- Update the location brackets on ITEM_SUPP_COUNTRY_BRACKET_COST
               --- If the record has a bracket value.
               if L_bracket_value1 is not null then
                  SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  open C_LOCK_SUPP_CNTRY_BRKT_COST;

                  SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  close C_LOCK_SUPP_CNTRY_BRKT_COST;

                  SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);

                  update item_supp_country_bracket_cost
                     set unit_cost          = L_new_cost
                   where bracket_value1     = L_bracket_value1
                     and location           = L_location
                     and origin_country_id  = I_country
                     and supplier           = I_supplier
                     and item               = I_item;

                  --- update child item brackets
                  --- on ITEM_SUPP_COUNTRY_BRACKET_COST
                  --- If the update child indicator is passed in as 'Y'
                  if I_update_child = 'Y' then

                     SQL_LIB.SET_MARK('OPEN', 'C_LOCK_BRACKET_CHILD ', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                     open C_LOCK_BRACKET_CHILD ;

                     SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_BRACKET_CHILD ', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                     close C_LOCK_BRACKET_CHILD;

                     SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);

                     update item_supp_country_bracket_cost
                        set unit_cost          = L_new_cost
                      where bracket_value1     = L_bracket_value1
                        and location           = L_location
                        and origin_country_id  = I_country
                        and supplier           = I_supplier
                        and item in (select im.item
                                       from item_master im,
                                            item_supp_country_bracket_cost iscl
                                      where iscl.supplier          = I_supplier
                                        and iscl.origin_country_id = I_country
                                        and (im.item_parent        = I_item or
                                             im.item_grandparent   = I_item)
                                        and im.item_level          <= im.tran_level
                                        and iscl.item              = im.item);

                  end if; -- end if I_update_child = 'Y'
               end if; --- end if L_bracket_value1 is not null

               --- If the item is costed by location but not bracket
               --- UPDATE item_supp_country_loc and item_supp_country
               --- For the current item and it's children if indicated.
               if L_bracket_value1 is NULL then

                  SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_COUNTRY_LOC', 'ITEM_SUPP_COUNTRY_LOC',NULL);
                  open C_LOCK_SUPP_COUNTRY_LOC;

                  SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_COUNTRY_LOC', 'ITEM_SUPP_COUNTRY_LOC',NULL);
                  Close C_LOCK_SUPP_COUNTRY_LOC;

                  SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC',NULL);

                  update item_supp_country_loc
                     set unit_cost            = L_new_cost,
                         last_update_id       = user,
                         last_update_datetime = sysdate
                   where loc                  = L_location
                     and origin_country_id    = I_country
                     and supplier             = I_supplier
                     and item                 = I_item;

                  --- Update the records on item_supp_country with the unit
                  --- cost at the primary location.  If the child indicator
                  --- is passed in as 'Y', update all child record at the
                  --- the passed in location and update item_supp_country
                  --- for the primary location of the child items.
                  if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                                      I_item,
                                                      I_supplier,
                                                      I_country,
                                                      L_location,
                                                      I_update_child,
                                                      'Y',
                                                      NULL) then
                     return FALSE;
                  end if;
               end if; --- if L_bracket_value1 is NULL
            end if; --- end if L_multichannel_flag = 'N'
         end if; --- end if L_loc_costed_flag = 'Y'

         --- If the item is not costed by location but costed by bracket
         --- then update the brackets where the location is null on
         --- ITEM_SUPP_COUNTRY_BRACKET_COST
         if L_loc_costed_flag = 'N' and L_bracket_value1 is not NULL then
            SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            open C_LOCK_SUPP_CNTRY_BRKT_COST;

            SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            close C_LOCK_SUPP_CNTRY_BRKT_COST;

            SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);

            update item_supp_country_bracket_cost
               set unit_cost          = L_new_cost
             where bracket_value1     = L_bracket_value1
               and location           is NULL
               and origin_country_id  = I_country
               and supplier           = I_supplier
               and item               = I_item;

            --- update child item brackets
            --- on ITEM_SUPP_COUNTRY_BRACKET_COST
            --- If the update child indicator is passed in as 'Y'
            if I_update_child = 'Y' then

               SQL_LIB.SET_MARK('OPEN', 'C_LOCK_BRACKET_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               open C_LOCK_BRACKET_CHILD;

               SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_BRACKET_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               close C_LOCK_BRACKET_CHILD;

               SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);

               update item_supp_country_bracket_cost
                  set unit_cost          = L_new_cost
                where bracket_value1     = L_bracket_value1
                  and location           is NULL
                  and origin_country_id  = I_country
                  and supplier           = I_supplier
                  and item in (select im.item
                                 from item_master im,
                                      item_supp_country_bracket_cost iscbc
                                where iscbc.supplier          = I_supplier
                                  and iscbc.origin_country_id = I_country
                                  and (im.item_parent         = I_item or
                                       im.item_grandparent    = I_item)
                                  and im.item_level          <= im.tran_level
                                  and iscbc.item              = im.item);

            end if; -- end if I_update_child = 'Y'
         end if; --- end if L_bracket_value1 is not null and L_loc_costed = 'N'
      END LOOP;  --- end loop through EDI_COST_LOC


      --- If locations are present in the input parameters
      --- and brackets are provided
      --- grab the distinct locations on EDI_COST_LOC
      --- and update the unit costs on ITEM_SUPP_COUNTRY_LOC
      --- and ITEM_SUPP_COUNTRY for the priamry location
      if L_loc_costed_flag = 'Y' and L_bracket_value1 is not NULL then

         --- loop through all distinct locations on EDI_COST_LOC and update
         --- ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY
         SQL_LIB.SET_MARK('FETCH','C_GET_LOCATIONS','EDI_COST_LOC',NULL);
         FOR rec in C_GET_LOCATIONS
         LOOP

            L_location := rec.location;


            --- Grab virtual locations that may exist for the physical location
            --- in a virtual environment
            --- and update ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY for
            --- The virtual locations
            if L_multichannel_flag = 'Y' then
               SQL_LIB.SET_MARK('FETCH','C_SELECT_VIRTUALS','EDI_COST_LOC',NULL);
               FOR rec in C_SELECT_VIRTUALS
               LOOP
                  L_virtual_loc := rec.wh;

                  --- Update the unit cost on ITEM_SUPP_COUNTRY_LOC with the
                  --- unit cost of the default bracket at the passed in location.
                  --- Update the records on item_supp_country with the unit
                  --- cost at the primary location.  If the child indicator
                  --- is passed in as 'Y', update all child record at the
                  --- the passed in location and update item_supp_country
                  --- for the primary location of the child items.
                  if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                                    I_item,
                                                                    I_supplier,
                                                                    I_country,
                                                                    L_virtual_loc,
                                                                    I_update_child) then
                     return FALSE;
                  end if;
               END LOOP;

            --- Update the unit cost on ITEM_SUPP_COUTNRY_LOC with the
            --- unit cost of the default bracket at the passed in location.
            --- If it is not a multi-channel environment then
            --- Update the records on item_supp_country with the unit
            --- cost at the primary location.  If the child indicator
            --- is passed in as 'Y', update all child record at the
            --- the passed in location and update item_supp_country
            --- for the primary location of the child items.
            else

               if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                                 I_item,
                                                                 I_supplier,
                                                                 I_country,
                                                                 L_location,
                                                                 I_update_child) then
                  return FALSE;
               end if;
            end if;  --- if/else L_multichannel_flag = 'Y'
         END LOOP; --- End loop through distinct EDI_COST_LOC locations
      end if; --- end L_loc_costed_flag = 'Y' and L_bracket_value1 is not NULL

      --- if it is not location costed but bracket costed then
      --- update all location level brackets for the item.  Then update
      --- item_supp_country_loc for the default bracket.  Update the
      --- unit cost on item_supp_country for the primary location.
      --- If the update child ind is passed in as 'Y', then make the same updates
      --- to the children.
      if L_loc_costed_flag = 'N' and L_bracket_value1 is not NULL then

         if not ITEM_BRACKET_COST_SQL.UPDATE_ALL_LOCATION_BRACKETS(O_error_message,
                                                                   I_item,
                                                                   I_supplier,
                                                                   I_country,
                                                                   I_update_child)then
            return FALSE;
         end if;
      end if; --- end if L_loc_costed_flag = 'N' and L_bracket_value1 is not NULL
   end if; --- end if I_costed_ind = 'Y'

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message :=O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                             L_table,
                                                             I_item,
                                                             I_supplier);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END UPDATE_COSTS;
------------------------------------------------------------------------------------
FUNCTION UPDATE_BRACKET_PACK_COSTS(O_error_message   IN OUT    VARCHAR2,
                                   I_item            IN        EDI_COST_LOC.ITEM%TYPE,
                                   I_supplier        IN        EDI_COST_LOC.SUPPLIER%TYPE,
                                   I_country         IN        EDI_COST_LOC.ORIGIN_COUNTRY_ID%TYPE,
                                   I_seq_no          IN        EDI_COST_LOC.SEQ_NO%TYPE) return BOOLEAN IS

L_program             VARCHAR2(64) := 'EDI_BRACKET_SQL.UPDATE_COSTS';
L_table               VARCHAR2(64) := 'EDI_COST_CHG';
L_new_cost            ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
L_unit_cost           ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
L_bracket_value1      ITEM_SUPP_COUNTRY_BRACKET_COST.BRACKET_VALUE1%TYPE;
L_bracket_value2      ITEM_SUPP_COUNTRY_BRACKET_COST.BRACKET_VALUE1%TYPE;
L_loc_costed_flag     VARCHAR2(1) := NULL;
L_location            EDI_COST_LOC.LOCATION%TYPE;
L_virtual_loc         WH.WH%TYPE;
L_multichannel_flag   VARCHAR2(1);
RECORD_LOCKED         EXCEPTION;
PRAGMA                EXCEPTION_INIT(Record_Locked, -54);


--- Cursors for non-multichannel environment

cursor C_SUPP_LOC is
   select loc
     from item_supp_country_loc
    where item              = I_item
      and supplier          = I_supplier
      and origin_country_id = I_country;

---
cursor C_LOCK_SUPP_CNTRY_BRKT_COST is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1    = L_bracket_value1
      and (location         = L_location
       or location          is NULL)
      and origin_country_id = I_country
      and supplier          = I_supplier
      and item              = I_item
      for update nowait;

---
cursor C_LOCK_SUPP_COUNTRY_LOC is
   select 'x'
     from item_supp_country_loc
    where loc               = L_location
      and origin_country_id = I_country
      and supplier          = I_supplier
      and item              = I_item
      for update nowait;

---
cursor C_SELECT_BRACKET is
   select bracket_value1,
          bracket_value2,
          unit_cost_new,
          location
     from edi_cost_loc
    where seq_no = I_seq_no
      and case_ind = 'Y';

---
cursor C_GET_LOCATIONS is
   select distinct location
     from edi_cost_loc
    where seq_no = I_seq_no
      and case_ind = 'Y';


--- Cursors for multichannel environment

cursor C_LOCK_MULTICHANNEL is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1    = L_bracket_value1
      and location          = L_virtual_loc
      and origin_country_id = I_country
      and supplier          = I_supplier
      and item              = I_item
      for update nowait;

---
 cursor C_SELECT_VIRTUALS is
   select wh
     from wh
    where physical_wh = L_location;

---
cursor C_SELECT_ALL_VIRTUALS is
   select wh
     from wh
    where physical_wh = L_location
      and stockholding_ind = 'Y'
 UNION ALL
   select store
     from store
    where store = L_location;

---
cursor C_LOCK_SUPP_CTRY_LOC_MULT is
   select 'x'
     from item_supp_country_loc
    where loc               = L_virtual_loc
      and origin_country_id = I_country
      and supplier          = I_supplier
      and item              = I_item
      for update nowait;

---

BEGIN
   --- NULL value validation
   if I_item is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_country is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'country',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'seq_no',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   --- This function will be used for new item case UPC packs.
   --- If a pack is bracket costed and/or location costed (records come from EDI_COST_LOC):
   --- Grab the multichannel indicator from system option to see if the system is set
   --- for multichannel locations.
   --- Begin looping through records on EDI_COST_LOC.  Check to see if locations are provided.
   --- If locations are provided, then check to see if it is a multichannel environment.  If it is a
   --- multichannel environment, do the following:
   --- 1.  Check if brackets are provided, if they are update the cost on ITEM_SUPP_COUNTRY_BRACKET_COST
   ---     for the item/location/bracket where the location is the virtual location.
   --- 2.  Check to see if brackets are not provided.  If they are not, update only the virtual location records
   ---     On ITEM_SUPP_COUNTRY_LOC.  If the primary location is updated, update the unit cost on ITEM_SUPP_COUNTRY.
   ---     If child items are to be updated, perform the same cost updates for them.
   --- If the environment is not multi_channel, do the following:
   --- 1.  Check if brackets are provided, if they are update the cost on ITEM_SUPP_COUNTRY_BRACKET_COST
   ---     for the item/location/bracket where the location is the physical location.
   --- 2.  Check to see if brackets are not provided.  If they are not, update only the physical location records
   ---     On ITEM_SUPP_COUNTRY_LOC.  If the primary location is updated, update the unit cost on ITEM_SUPP_COUNTRY.
   ---     If child items are to be updated, perform the same cost updates for them.
   --- After looping through the EDI_COST_LOC records,loop through the distinct locations on EDI_COST_LOC if
   --- the supplier is bracket costed and locations are provided and update
   --- costs on ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY. First, grab all the distinct locations then loop through
   --- them.  If it is a multichannel environment, perform the following:
   --- 1.   Grab all the virtaul locations for the physical location and loop through them.
   --- 2.   Update the costs on ITEM_SUPP_COUNTRY_LOC with the default bracket cost for the virtual location.
   --- 3.   If the location is the primary location update ITEM_SUPP_COUNTRY with that unit cost.
   --- If it is not a multichannel environment, perform the following:
   --- 1.   Update the costs on ITEM_SUPP_COUNTRY_LOC with the default bracket cost for the physical location.
   --- 2.   If the location is the primary location update ITEM_SUPP_COUNTRY with that unit cost.
   --- If the item is not location costed but bracket costed,
   --- update all location level brackets for the item.  Then update
   --- item_supp_country_loc for the default bracket.  Update the
   --- unit cost on item_supp_country for the primary location.

   ---Get the multi_channel indicator
   if not SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                  L_multichannel_flag) then
      return FALSE;
   end if;

   --- loop through all records on EDI_COST_LOC
   --- and update costs on ITEM_SUPP_COUNTRY_BRACKET_COST if it is bracket
   --- costed or just ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY
   SQL_LIB.SET_MARK('FETCH','C_SELECT_BRACKET','EDI_COST_LOC',NULL);
   FOR rec in C_SELECT_BRACKET
   LOOP
      L_bracket_value1 := rec.bracket_value1;
      L_bracket_value2 := rec.bracket_value2;
      L_new_cost       := rec.unit_cost_new;
      L_location       := rec.location;

      --- Set location costed flag
      if L_location is NULL then
         L_loc_costed_flag := 'N';
      else
         L_loc_costed_flag := 'Y';
      end if;

      --- if locations are provided in the input variables
      --- Then perform costing at the location level
      if L_loc_costed_flag = 'Y' then

         --- If the multichannel environment indicator is set to
         --- 'Y' then make updates to virtual locations
         if L_multichannel_flag = 'Y' then

            --- If brackets are provided in the input parameter
            --- then update the bracket's unit cost
            if L_bracket_value1 is not null then

               --- The following will be used in a multichannel environment.
               --- if locations are present, check if virtuals are present
               --- if virtual locations are found, update ITEM_SUPP_CNTRY_BRACK_COST
               --- for the virtual locations

               SQL_LIB.SET_MARK('OPEN', 'C_LOCK_MULTICHANNEL', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               open C_LOCK_MULTICHANNEL;

               SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_MULTICHANNEL', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               close C_LOCK_MULTICHANNEL;

               SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);

               update item_supp_country_bracket_cost
                  set unit_cost          = L_new_cost
                where bracket_value1     = L_bracket_value1
                  and location in (select wh
                                     from wh
                                    where physical_wh = L_location)
                  and origin_country_id  = I_country
                  and supplier           = I_supplier
                  and item               = I_item;

            end if; --- end if L_bracket_value1 is not null

            --- If the item is costed by location but not bracket
            --- UPDATE item_supp_country_loc and item_supp_country
            --- for virtual locations
            if L_bracket_value1 is NULL then

               SQL_LIB.SET_MARK('FETCH','C_SELECT_ALL_VIRTUALS','EDI_COST_LOC',NULL);
               FOR rec in C_SELECT_ALL_VIRTUALS
               LOOP

                  L_virtual_loc := rec.wh;

                  SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_CTRY_LOC_MULT', 'ITEM_SUPP_COUNTRY_LOC',NULL);
                  open C_LOCK_SUPP_CTRY_LOC_MULT;

                  SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_CTRY_LOC_MULT', 'ITEM_SUPP_COUNTRY_LOC',NULL);
                  close C_LOCK_SUPP_CTRY_LOC_MULT;

                  SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC',NULL);

                  update item_supp_country_loc
                     set unit_cost            = L_new_cost,
                         last_update_id       = user,
                         last_update_datetime = sysdate
                   where loc                  = L_virtual_loc
                     and origin_country_id    = I_country
                     and supplier             = I_supplier
                     and item                 = I_item;

                  --- Update the records on item_supp_country with the unit
                  --- cost at the primary location.
                  if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                                      I_item,
                                                      I_supplier,
                                                      I_country,
                                                      L_virtual_loc,
                                                      'N',
                                                      'Y',
                                                      NULL) then
                     return FALSE;
                  end if;
               END LOOP; --- End update virtuals
            end if; --- end if L_bracket_value1 is NULL
         end if; --- end if if L_multichannel_flag = 'Y'

         --- if it is not a multichannel environment
         --- Update the location brackets on ITEM_SUPP_COUNTRY_BRACKET_COST
         if L_multichannel_flag = 'N' then

            --- Update the location brackets on ITEM_SUPP_COUNTRY_BRACKET_COST
            --- If the record has a bracket value.
            if L_bracket_value1 is not null then
               SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               open C_LOCK_SUPP_CNTRY_BRKT_COST;

               SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               close C_LOCK_SUPP_CNTRY_BRKT_COST;

               SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);

               update item_supp_country_bracket_cost
                  set unit_cost          = L_new_cost
                where bracket_value1     = L_bracket_value1
                  and location           = L_location
                  and origin_country_id  = I_country
                  and supplier           = I_supplier
                  and item               = I_item;

            end if; --- end if L_bracket_value1 is not null

            --- If the item is costed by location but not bracket
            --- UPDATE item_supp_country_loc and item_supp_country
            --- For the current item and it's children if indicated.
            if L_bracket_value1 is NULL then

               SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_COUNTRY_LOC', 'ITEM_SUPP_COUNTRY_LOC',NULL);
               open C_LOCK_SUPP_COUNTRY_LOC;

               SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_COUNTRY_LOC', 'ITEM_SUPP_COUNTRY_LOC',NULL);
               Close C_LOCK_SUPP_COUNTRY_LOC;

               SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC',NULL);

               update item_supp_country_loc
                  set unit_cost         = L_new_cost,
                      last_update_id       = user,
                      last_update_datetime = sysdate
                where loc               = L_location
                  and origin_country_id = I_country
                  and supplier          = I_supplier
                  and item              = I_item;

               --- Update the records on item_supp_country with the unit
               --- cost at the primary location.
               if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                                   I_item,
                                                   I_supplier,
                                                   I_country,
                                                   L_location,
                                                   'N',
                                                   'Y',
                                                   NULL) then
                  return FALSE;
               end if;
            end if; --- if L_bracket_value1 is NULL
         end if; --- end if L_multichannel_flag = 'N'
      end if; --- end if L_loc_costed_flag = 'Y'

      --- If the item is not costed by location but costed by bracket
      --- then update the brackets where the location is null on
      --- ITEM_SUPP_COUNTRY_BRACKET_COST
      if L_loc_costed_flag = 'N' and L_bracket_value1 is not NULL then
         SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         open C_LOCK_SUPP_CNTRY_BRKT_COST;

         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         close C_LOCK_SUPP_CNTRY_BRKT_COST;

         SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);

         update item_supp_country_bracket_cost
            set unit_cost          = L_new_cost
          where bracket_value1     = L_bracket_value1
            and location           is NULL
            and origin_country_id  = I_country
            and supplier           = I_supplier
            and item               = I_item;

      end if; --- end if L_bracket_value1 is not null and L_loc_costed = 'N'
   END LOOP;  --- end loop through EDI_COST_LOC


   --- If locations are present in the input parameters
   --- and brackets are provided
   --- grab the distinct locations on EDI_COST_LOC
   --- and update the unit costs on ITEM_SUPP_COUNTRY_LOC
   --- and ITEM_SUPP_COUNTRY for the priamry location
   if L_loc_costed_flag = 'Y' and L_bracket_value1 is not NULL then

      --- loop through all distinct locations on EDI_COST_LOC and update
      --- ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY
      SQL_LIB.SET_MARK('FETCH','C_GET_LOCATIONS','EDI_COST_LOC',NULL);
      FOR rec in C_GET_LOCATIONS
      LOOP

         L_location := rec.location;

         --- Grab virtual locations that may exist for the physical location
         --- in a virtual environment
         --- and update ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY for
         --- The virtual locations
         if L_multichannel_flag = 'Y' then
            SQL_LIB.SET_MARK('FETCH','C_SELECT_VIRTUALS','EDI_COST_LOC',NULL);
            FOR rec in C_SELECT_VIRTUALS
            LOOP
               L_virtual_loc := rec.wh;

               --- Update the unit cost on ITEM_SUPP_COUNTRY_LOC with the
               --- unit cost of the default bracket at the passed in location.
               --- Update the records on item_supp_country with the unit
               --- cost at the primary location.
               if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                                 I_item,
                                                                 I_supplier,
                                                                 I_country,
                                                                 L_virtual_loc,
                                                                 'N') then
                  return FALSE;
               end if;
            END LOOP;

         --- Update the unit cost on ITEM_SUPP_COUTNRY_LOC with the
         --- unit cost of the default bracket at the passed in location.
         --- If it is not a multi-channel environment then
         --- Update the records on item_supp_country with the unit
         --- cost at the primary location.
         else

            if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                              I_item,
                                                              I_supplier,
                                                              I_country,
                                                              L_location,
                                                              'N') then
               return FALSE;
            end if;
         end if;  --- if/else L_multichannel_flag = 'Y'
      END LOOP; --- End loop through distinct EDI_COST_LOC locations
   end if; --- end L_loc_costed_flag = 'Y' and L_bracket_value1 is not NULL

   --- if it is not location costed but bracket costed then
   --- update all location level brackets for the item.  Then update
   --- item_supp_country_loc for the default bracket.  Update the
   --- unit cost on item_supp_country for the primary location.
   if L_loc_costed_flag = 'N' and L_bracket_value1 is not NULL then

      if not ITEM_BRACKET_COST_SQL.UPDATE_ALL_LOCATION_BRACKETS(O_error_message,
                                                                I_item,
                                                                I_supplier,
                                                                I_country,
                                                                'N')then
         return FALSE;
      end if;
   end if; --- end if L_loc_costed_flag = 'N' and L_bracket_value1 is not NULL

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message :=O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                             L_table,
                                                             I_item,
                                                             I_supplier);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END UPDATE_BRACKET_PACK_COSTS;
------------------------------------------------------------------------------------
END EDI_BRACKET_SQL ;
/

