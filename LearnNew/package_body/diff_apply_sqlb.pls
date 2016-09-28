CREATE OR REPLACE PACKAGE BODY DIFF_APPLY_SQL AS
-------------------------------------------------------------------------------------------------------
--Modified By        : Nitin Kumar, nitin.kumar@in.tesco.com
--Date               : 03-Oct-2007
--Mod                : N105
--Function           : This package will be modify to generate item numbers from the RNA.
--Procedure Modified : COMPLETE_ITEM_TEMP
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Mod By       : Tarun Kumar Mishra, tarun.mishra@in.tesco.com
-- Mod Date     : 9-Dec-2008
-- Mod Ref      : DefNBS005996
-- Mod Details  : Added code to check condition L_use_rna_ind = 'Y'
-------------------------------------------------------------------------------------
-- Mod By       : Chandru, chandrashekaran.natarajan@in.tesco.com
-- Mod Date     : 12-Jan-2011
-- Mod Ref      : DefNBS020496
-- Mod Details  : POP_ITEM_TEMP function modified to remove the base from item desc
-------------------------------------------------------------------------------------
-- Mod By       : Sriranjitha, Sriranjitha.Bhagi@in.tesco.com
-- Mod Date     : 21-Mar-2014
-- Mod Ref      : DefNBS026931
-- Mod Details  : ITEM_NUMBER_TYPE function modified to fetch item_number_tpe as 'TPNB'
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
/***** Local Package PROCEDURE ************/
PROCEDURE COMPLETE_ITEM_TEMP(O_error_message     IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                             O_item_temp_created IN OUT  BOOLEAN,
                             O_dups_created      IN OUT  BOOLEAN,
                             I_parent            IN      ITEM_MASTER.ITEM%TYPE,
                             I_item_number_type  IN      ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                             I_auto_create       IN      VARCHAR2)
IS
   L_program   VARCHAR2(40) := 'DIFF_APPLY_SQL.COMPLETE_ITEM_TEMP';

   L_item      ITEM_TEMP.ITEM%TYPE;
   L_dummy     VARCHAR2(1);
   L_rna_type  BOOLEAN;
   program_error   exception;
   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
   L_use_rna_ind   SYSTEM_OPTIONS.TSL_RNA_IND%TYPE;
   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End

   cursor C_ITEM_TEMP_RECS is
      select diff_1
           , diff_2
           , diff_3
           , diff_4
        from item_temp
       order by display_seq_1,
                diff_1,
                display_seq_2,
                diff_2,
                display_seq_3,
                diff_3,
                display_seq_4,
                diff_4;

   cursor C_FIND_DUPS is
      select ROWID
        from item_temp it
       where exists (select 'x'
                       from item_master im
                      where I_parent = im.item_parent
                        and NVL(im.diff_1,'-*-') = NVL(it.diff_1,'-*-')
                        and NVL(im.diff_2,'-*-') = NVL(it.diff_2,'-*-')
                        and NVL(im.diff_3,'-*-') = NVL(it.diff_3,'-*-')
                        and NVL(im.diff_4,'-*-') = NVL(it.diff_4,'-*-'));

   PROCEDURE LP_chk_item_temp IS
   BEGIN
      O_item_temp_created := FALSE;
      L_dummy             := 'N';
      if CHECK_ITEM_TEMP(O_error_message,
                         L_dummy) = TRUE then
         if L_dummy = 'Y' then
            O_item_temp_created := TRUE;
         end if;
      end if;
   END LP_chk_item_temp;
BEGIN
   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
   if SYSTEM_OPTIONS_SQL.TSL_GET_RNA_IND(O_error_message,
                                         L_use_rna_ind) = FALSE then
      raise PROGRAM_ERROR;
   end if;
   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End
   --- If any records exist on item_temp table, set indicator to true
   LP_chk_item_temp;
   if O_item_temp_created then
   --- Create records on temp_diff_duplicate for all duplicate records
      FOR rec in C_FIND_DUPS LOOP
         ---
         insert into temp_diff_duplicate
                 ( diff_1
                 , diff_2
                 , diff_3
                 , diff_4 )
            select it.diff_1
                 , it.diff_2
                 , it.diff_3
                 , it.diff_4
              from item_temp it
             where rowid = rec.rowid
               and not exists (select 'x'
                                 from temp_diff_duplicate tdd
                                where it.diff_1 = tdd.diff_1
                                  and NVL(it.diff_2,'-*-') = NVL(tdd.diff_2, '-*-')
                                  and NVL(it.diff_3,'-*-') = NVL(tdd.diff_3, '-*-')
                                  and NVL(it.diff_4,'-*-') = NVL(tdd.diff_4, '-*-'));
         ---
         if sql%FOUND then
            O_dups_created := TRUE;
         end if;
         ---
         delete from item_temp where rowid = rec.ROWID;
      END LOOP;

      --- Reset indicator after deleting dups
      O_item_temp_created := FALSE;
      --- If auto create is selected, assign new item numbers to each record
      if I_auto_create = 'Y' then
         FOR rec in C_ITEM_TEMP_RECS LOOP
         --- Reset indicator since records do exist
            O_item_temp_created := TRUE;
            ---------------------------------------------------------------------------------------------
            -- 03-Oct-2007 Nitin Kumar,nitin.kumar@in.tesco.com - MOD N105 Begin
            ---------------------------------------------------------------------------------------------
            -- Get the next item number avaialbe for the item type
            if TSL_ITEM_NUMBER_SQL.IS_RNA_TYPE(O_error_message,
                                               I_item_number_type,
                                               L_rna_type) = FALSE then
               raise PROGRAM_ERROR;
            end if;
            ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008
            if L_rna_type and L_use_rna_ind = 'Y' then
              if ITEM_NUMBER_TYPE_SQL.TSL_GET_NEXT(O_error_message,
                                                   L_item,
                                                   I_item_number_type) = FALSE then
                 raise PROGRAM_ERROR;
              end if;
            else
            ---------------------------------------------------------------------------------------------
            -- 03-Oct-2007 Nitin Kumar,nitin.kumar@in.tesco.com - MOD N105 End
            ---------------------------------------------------------------------------------------------
               --- Get an item number for this item
                  if ITEM_NUMBER_TYPE_SQL.GET_NEXT(O_error_message,
                                                   L_item,
                                                   I_item_number_type) = FALSE then
                        raise PROGRAM_ERROR;
                  end if;
             end if;
            --- Update this record with new item number
            update item_temp
               set item = L_item
             where diff_1 = rec.diff_1
               and NVL(diff_2,'-*-') = NVL(rec.diff_2,'-*-')
               and NVL(diff_3,'-*-') = NVL(rec.diff_3,'-*-')
               and NVL(diff_4,'-*-') = NVL(rec.diff_4,'-*-');
         END LOOP;
      else
         LP_chk_item_temp;
      end if; -- auto create
   end if; -- item_temp created

EXCEPTION
   when OTHERS then
    if o_error_message is null  then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
   end if ;
END COMPLETE_ITEM_TEMP;
/***** End  Local Procedure  ******/
--------------------------------------------------------------------------------------------
--    Name: GET_DESC_LENGTH
-- Purpose: Calculate the number of characters that will be included from the parent desc
--          and any diff's that are associated with the parent.
--------------------------------------------------------------------------------------------
/***** Local Package PROCEDURE ************/
PROCEDURE GET_DESC_LENGTH(O_error_message      IN OUT  VARCHAR2,
                          O_parent_desc_length  IN OUT  NUMBER,
                          O_diff_desc_length    IN OUT  NUMBER,
                          I_item_temp_rec       IN      ITEM_TEMP_RECTYPE)
   IS

   L_program              VARCHAR2(40) := 'DIFF_APPLY_SQL.GET_DESC_LENGTH';

   L_parent_desc_length   NUMBER;
   L_diff_no              NUMBER;

BEGIN

   if I_item_temp_rec.parent_diff4 is NOT NULL then
      L_diff_no := 4;
   elsif I_item_temp_rec.parent_diff3 is NOT NULL then
      L_diff_no := 3;
   elsif I_item_temp_rec.parent_diff2 is NOT NULL then
      L_diff_no := 2;
   elsif I_item_temp_rec.parent_diff1 is NOT NULL then
      L_diff_no := 1;
   end if;

   if lengthb(I_item_temp_rec.parent_desc) < 150 then
      O_parent_desc_length := lengthb(I_item_temp_rec.parent_desc);
      O_diff_desc_length := trunc( ( (250 - L_diff_no) - O_parent_desc_length) / L_diff_no );
   else
     if L_diff_no = 4 then
        O_parent_desc_length := 134;
        O_diff_desc_length   := 28;
     elsif L_diff_no = 3 then
         O_parent_desc_length := 142;
         O_diff_desc_length   := 35;
      elsif L_diff_no = 2 then
         O_parent_desc_length := 148;
         O_diff_desc_length   := 50;
      elsif L_diff_no = 1 then
         O_parent_desc_length := 174;
         O_diff_desc_length   := 75;
      end if;
   end if;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);

END GET_DESC_LENGTH;
/***** End  Local Procedure  ******/
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--    Name: POP_TEMP_DIFF
-- Purpose: Populates TEMP_DIFFx tables with all applicable differential values.
--------------------------------------------------------------------------------------------
FUNCTION POP_TEMP_DIFF(O_error_message     IN OUT  VARCHAR2,
                       O_item_number_type  IN OUT  ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                       I_item_parent       IN      ITEM_MASTER.ITEM_PARENT%TYPE,
                       I_diff1_id          IN      DIFF_IDS.DIFF_ID%TYPE,
                       I_diff1_group_ind   IN      V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                       I_diff2_id          IN      DIFF_IDS.DIFF_ID%TYPE,
                       I_diff2_group_ind   IN      V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                       I_diff3_id          IN      DIFF_IDS.DIFF_ID%TYPE,
                       I_diff3_group_ind   IN      V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                       I_diff4_id          IN      DIFF_IDS.DIFF_ID%TYPE,
                       I_diff4_group_ind   IN      V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE)
RETURN BOOLEAN is
   L_program      VARCHAR2(40) := 'DIFF_APPLY_SQL.POP_TEMP_DIFF';
   cursor C_GET_ITEM_LEVEL is
      select item_number_type
        from item_master
       where item_parent = I_item_parent
         and item_level  = 2
         and item_number_type is NOT NULL;
BEGIN
   --- Validate input
   if I_item_parent is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_item_parent', 'NULL', 'NOT NULL');
      return FALSE;
   elsif (I_diff1_id is NOT NULL) and (I_diff1_group_ind is NULL) then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_diff1_group_ind', 'NULL', 'NOT NULL');
      return FALSE;
   elsif (I_diff1_group_ind is NOT NULL) and (I_diff1_id is NULL) then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_diff1_id', 'NULL', 'NOT NULL');
      return FALSE;
   elsif (I_diff2_id is NOT NULL) and (I_diff2_group_ind is NULL) then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_diff2_group_ind', 'NULL', 'NOT NULL');
      return FALSE;
   elsif (I_diff2_group_ind is NOT NULL) and (I_diff2_id is NULL) then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_diff2_id', 'NULL', 'NOT NULL');
      return FALSE;
   elsif (I_diff3_id is NOT NULL) and (I_diff3_group_ind is NULL) then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_diff3_group_ind', 'NULL', 'NOT NULL');
      return FALSE;
   elsif (I_diff3_group_ind is NOT NULL) and (I_diff3_id is NULL) then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_diff3_id', 'NULL', 'NOT NULL');
      return FALSE;
   elsif (I_diff4_id is NOT NULL) and (I_diff4_group_ind is NULL) then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_diff4_group_ind', 'NULL', 'NOT NULL');
      return FALSE;
   elsif (I_diff4_group_ind is NOT NULL) and (I_diff4_id is NULL) then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_diff4_id', 'NULL', 'NOT NULL');
      return FALSE;
   end if;
   --- Clean out temp_diffx tables
   delete from temp_diff1;
   delete from temp_diff2;
   delete from temp_diff3;
   delete from temp_diff4;
   --- Populate temp tables with diff info
   if I_diff1_id is NOT NULL then
      if I_diff1_group_ind = 'GROUP' then
         --- If this is a diff group, populate temp_diff1 from diff_group_detail
         insert into temp_diff1
              ( diff_1
              , diff_desc
              , selected_ind
              , display_seq)
         select di.diff_id
              , di.diff_desc
              , 'N'
              , dgd.display_seq
           from diff_group_detail dgd
              , diff_ids          di
          where I_diff1_id  = dgd.diff_group_id
            and dgd.diff_id = di.diff_id;
      elsif I_diff1_group_ind = 'ID' then
         --- If this is a diff ID, populate temp_diff1 from from diff_ids
         insert into temp_diff1
              ( diff_1
              , diff_desc
              , selected_ind
              , display_seq)
         select di.diff_id
              , di.diff_desc
              , 'Y'
              , NULL
           from diff_ids di
          where I_diff1_id  = di.diff_id;
      else
         O_error_message := sql_lib.create_msg('INVALID_DIFF_IND', I_diff1_group_ind, L_program, NULL);
         return FALSE;
      end if;
   end if;
   if I_diff2_id is NOT NULL then
      if I_diff2_group_ind = 'GROUP' then
         --- If this is a diff group, populate temp_diff2 from diff_group_detail
         insert into temp_diff2
              ( diff_2
              , diff_desc
              , selected_ind
              , display_seq)
         select di.diff_id
              , di.diff_desc
              , 'N'
              , dgd.display_seq
           from diff_group_detail dgd
              , diff_ids          di
          where I_diff2_id  = dgd.diff_group_id
            and dgd.diff_id = di.diff_id;
      elsif I_diff2_group_ind = 'ID' then
         --- If this is a diff ID, populate temp_diff2 from from diff_ids
         insert into temp_diff2
              ( diff_2
              , diff_desc
              , selected_ind
              , display_seq)
         select di.diff_id
              , di.diff_desc
              , 'Y'
              , NULL
           from diff_ids di
          where I_diff2_id  = di.diff_id;
      else
         O_error_message := sql_lib.create_msg('INVALID_DIFF_IND', I_diff2_group_ind, L_program, NULL);
         return FALSE;
      end if;
   end if;
   if I_diff3_id is NOT NULL then
      if I_diff3_group_ind = 'GROUP' then
         --- If this is a diff group, populate temp_diff3 from diff_group_detail
         insert into temp_diff3
              ( diff_3
              , diff_desc
              , selected_ind
              , display_seq)
         select di.diff_id
              , di.diff_desc
              , 'N'
              , dgd.display_seq
           from diff_group_detail dgd
              , diff_ids          di
          where I_diff3_id  = dgd.diff_group_id
            and dgd.diff_id = di.diff_id;
      elsif I_diff3_group_ind = 'ID' then
         --- If this is a diff ID, populate temp_diff2 from from diff_ids
         insert into temp_diff3
              ( diff_3
              , diff_desc
              , selected_ind
              , display_seq)
         select di.diff_id
              , di.diff_desc
              , 'Y'
              , NULL
           from diff_ids di
          where I_diff3_id  = di.diff_id;
      else
         O_error_message := sql_lib.create_msg('INVALID_DIFF_IND', I_diff3_group_ind, L_program, NULL);
         return FALSE;
      end if;
   end if;
   if I_diff4_id is NOT NULL then
      if I_diff4_group_ind = 'GROUP' then
         --- If this is a diff group, populate temp_diff4 from diff_group_detail
         insert into temp_diff4
              ( diff_4
              , diff_desc
              , selected_ind
              , display_seq)
         select di.diff_id
              , di.diff_desc
              , 'N'
              , dgd.display_seq
           from diff_group_detail dgd
              , diff_ids          di
          where I_diff4_id  = dgd.diff_group_id
            and dgd.diff_id = di.diff_id;
      elsif I_diff4_group_ind = 'ID' then
         --- If this is a diff ID, populate temp_diff2 from from diff_ids
         insert into temp_diff4
              ( diff_4
              , diff_desc
              , selected_ind
              , display_seq)
         select di.diff_id
              , di.diff_desc
              , 'Y'
              , NULL
           from diff_ids di
          where I_diff4_id  = di.diff_id;
      else
         O_error_message := sql_lib.create_msg('INVALID_DIFF_IND', I_diff4_group_ind, L_program, NULL);
         return FALSE;
      end if;
   end if;
   if ITEM_NUMBER_TYPE(O_error_message,
                       O_item_number_type,
                       I_item_parent) = FALSE then
      return FALSE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      return FALSE;
END POP_TEMP_DIFF;
--------------------------------------------------------------------------------------------
--    Name: TOGGLE_SELECTED
-- Purpose: Updates selected_ind column based on the value of I_selected for all records on
--          TEMP_DIFFx.
--------------------------------------------------------------------------------------------
FUNCTION TOGGLE_SELECTED(O_error_message  IN OUT  VARCHAR2,
                         I_selected       IN      BOOLEAN,
                         I_diff_no        IN      VARCHAR2)
RETURN BOOLEAN is
   L_program        VARCHAR2(40) := 'DIFF_APPLY_SQL.SELECT_ALL';
   L_new_select_val VARCHAR2(1) := 'N';
   L_old_select_val VARCHAR2(1) := 'N';
BEGIN
   --- Check for NULL input parameter
   if I_diff_no is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL', I_diff_no, L_program, NULL);
      return FALSE;
   end if;
   if I_selected then
      L_new_select_val := 'Y';
   else
      L_old_select_val := 'Y';
   end if;
   --- Update status to 'APPLIED' for all 'AVAILABLE' records on temp_diffx table
   if I_diff_no = '1' then
      update temp_diff1 td
         set td.selected_ind = L_new_select_val
       where td.selected_ind = L_old_select_val;
   elsif I_diff_no = '2' then
      update temp_diff2 td
         set td.selected_ind = L_new_select_val
       where td.selected_ind = L_old_select_val;
   elsif I_diff_no = '3' then
      update temp_diff3 td
         set td.selected_ind = L_new_select_val
       where td.selected_ind = L_old_select_val;
   elsif I_diff_no = '4' then
      update temp_diff4 td
         set td.selected_ind = L_new_select_val
       where td.selected_ind = L_old_select_val;
   else
      O_error_message := sql_lib.create_msg('INV_PARAM_PROG_UNIT', L_program, NULL, NULL);
      return FALSE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      return FALSE;
END TOGGLE_SELECTED;
--------------------------------------------------------------------------------------------
--    Name: POP_ITEM_TEMP
-- Purpose: Create potential new child records from the cartesian product of the
--          'SELECTED' temp_diffx records.
--------------------------------------------------------------------------------------------
FUNCTION POP_ITEM_TEMP(O_error_message       IN OUT   VARCHAR2,
                       O_item_temp_created   IN OUT   BOOLEAN,
                       O_dups_created        IN OUT   BOOLEAN,
                       I_item_temp_rec       item_temp_rectype)
RETURN BOOLEAN IS

   L_program              VARCHAR2(40) := 'DIFF_APPLY_SQL.POP_ITEM_TEMP';
   L_diff_desc_length     NUMBER;
   L_parent_desc_length   NUMBER;

   program_error          EXCEPTION;
BEGIN
   --- Check for NULL parameters
   if I_item_temp_rec.item_number_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.item_number_type ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.auto_create is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.auto_create',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.item_parent is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.item_parent',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.parent_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.parent_desc',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   GET_DESC_LENGTH(O_error_message,
                   L_parent_desc_length,
                   L_diff_desc_length,
                   I_item_temp_rec);
   if O_error_message is not NULL then
      raise PROGRAM_ERROR;
   end if;
   --- Create new item_temp records from the cartesian product of the 'SELECTED' temp_diffx records.
   if I_item_temp_rec.parent_diff4 is NOT NULL then
      insert into item_temp it
                ( it.item_number_type
                , it.item_level
                , it.item_desc
                , it.diff_1
                , it.display_seq_1
                , it.diff_2
                , it.display_seq_2
                , it.diff_3
                , it.display_seq_3
                , it.diff_4
                , it.display_seq_4
                , it.existing_item_parent)
         --- 'SELECTED' records on all diffs
         (select distinct I_item_temp_rec.item_number_type
                , 2
                , rtrim(substrb(I_item_temp_rec.parent_desc,1,L_parent_desc_length))
                  ||':'
                  ||rtrim(substrb(td1.diff_desc,1,L_diff_desc_length))
                  ||':'
                  ||rtrim(substrb(td2.diff_desc,1,L_diff_desc_length))
                  ||':'
                  ||rtrim(substrb(td3.diff_desc,1,L_diff_desc_length))
                  --DefNBS020496 12-Jan-2011 Chandru Begin
                  --||':'
                  --||rtrim(substrb(td4.diff_desc,1,L_diff_desc_length))
                  --DefNBS020496 12-Jan-2011 Chandru End
                , td1.diff_1
                , td1.display_seq
                , td2.diff_2
                , td2.display_seq
                , td3.diff_3
                , td3.display_seq
                , td4.diff_4
                , td4.display_seq
                , I_item_temp_rec.item_parent
             from temp_diff1 td1
                , temp_diff2 td2
                , temp_diff3 td3
                , temp_diff4 td4
            where td1.selected_ind = 'Y'
              and td2.selected_ind = 'Y'
              and td3.selected_ind = 'Y'
              and td4.selected_ind = 'Y'
              and not exists (select 'x'
                                from item_temp itmp
                               where itmp.diff_1 = td1.diff_1
                                 and itmp.diff_2 = td2.diff_2
                                 and itmp.diff_3 = td3.diff_3
                                 and itmp.diff_4 = td4.diff_4));
   elsif I_item_temp_rec.parent_diff3 is NOT NULL then
      insert into item_temp it
                ( it.item_number_type
                , it.item_level
                , it.item_desc
                , it.diff_1
                , it.display_seq_1
                , it.diff_2
                , it.display_seq_2
                , it.diff_3
                , it.display_seq_3
                , it.existing_item_parent)
         --- 'SELECTED' records on diff_1, diff_2 and diff_3
         (select distinct I_item_temp_rec.item_number_type
                , 2
                , rtrim(substrb(I_item_temp_rec.parent_desc,1,L_parent_desc_length))
                  ||':'
                  ||rtrim(substrb(td1.diff_desc,1,L_diff_desc_length))
                  ||':'
                  ||rtrim(substrb(td2.diff_desc,1,L_diff_desc_length))
                  --DefNBS020496 12-Jan-2011 Chandru Begin
                  --||':'
                  --||rtrim(substrb(td3.diff_desc,1,L_diff_desc_length))
                  --DefNBS020496 12-Jan-2011 Chandru End
                , td1.diff_1
                , td1.display_seq
                , td2.diff_2
                , td2.display_seq
                , td3.diff_3
                , td3.display_seq
                , I_item_temp_rec.item_parent
             from temp_diff1 td1
                , temp_diff2 td2
                , temp_diff3 td3
            where td1.selected_ind = 'Y'
              and td2.selected_ind = 'Y'
              and td3.selected_ind = 'Y'
              and not exists (select 'x'
                                from item_temp itmp
                               where itmp.diff_4 is NULL
                                 and itmp.diff_1 = td1.diff_1
                                 and itmp.diff_2 = td2.diff_2
                                 and itmp.diff_3 = td3.diff_3));
   elsif I_item_temp_rec.parent_diff2 is NOT NULL then
      insert into item_temp it
                ( it.item_number_type
                , it.item_level
                , it.item_desc
                , it.diff_1
                , it.display_seq_1
                , it.diff_2
                , it.display_seq_2
                , it.existing_item_parent)
         --- 'SELECTED' records on diff_1 and diff2 only
          (select distinct I_item_temp_rec.item_number_type
                , 2
                , rtrim(substrb(I_item_temp_rec.parent_desc,1,L_parent_desc_length))
                  ||':'
                  ||rtrim(substrb(td1.diff_desc,1,L_diff_desc_length))
                  --DefNBS020496 12-Jan-2011 Chandru Begin
                  --||':'
                  --||rtrim(substrb(td2.diff_desc,1,L_diff_desc_length))
                  --DefNBS020496 12-Jan-2011 Chandru End
                , td1.diff_1
                , td1.display_seq
                , td2.diff_2
                , td2.display_seq
                , I_item_temp_rec.item_parent
             from temp_diff1 td1
                , temp_diff2 td2
            where td1.selected_ind = 'Y'
              and td2.selected_ind = 'Y'
              and not exists (select 'x'
                                from item_temp itmp
                               where itmp.diff_3 is NULL
                                 and itmp.diff_4 is NULL
                                 and itmp.diff_1 = td1.diff_1
                                 and itmp.diff_2 = td2.diff_2));
   elsif I_item_temp_rec.parent_diff1 is NOT NULL then
      insert into item_temp it
                ( it.item_number_type
                , it.item_level
                , it.item_desc
                , it.diff_1
                , it.display_seq_1
                , it.existing_item_parent)
          --- 'SELECTED' records on diff_1 only )
          (select distinct I_item_temp_rec.item_number_type
                , 2
                , rtrim(substrb(I_item_temp_rec.parent_desc,1,L_parent_desc_length))
                  --DefNBS020496 12-Jan-2011 Chandru Begin
                  --||':'
                  --||rtrim(substrb(td1.diff_desc,1,L_diff_desc_length))
                  --DefNBS020496 12-Jan-2011 Chandru End
                , td1.diff_1
                , td1.display_seq
                , I_item_temp_rec.item_parent
             from temp_diff1 td1
            where td1.selected_ind = 'Y'
              and not exists (select 'x'
                                from item_temp itmp
                               where itmp.diff_1 = td1.diff_1
                                 and itmp.diff_2 is NULL
                                 and itmp.diff_3 is NULL
                                 and itmp.diff_4 is NULL));
   end if;
   ---

   COMPLETE_ITEM_TEMP(O_error_message,
                      O_item_temp_created,
                      O_dups_created,
                      I_item_temp_rec.item_parent,
                      I_item_temp_rec.item_number_type,
                      I_item_temp_rec.auto_create);
   if O_error_message is not NULL then
      raise PROGRAM_ERROR;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      if O_error_message is NULL then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      end if;
      return FALSE;
END POP_ITEM_TEMP;
--------------------------------------------------------------------------------------------
--    Name: CLEAR_TEMP_TABLE
-- Purpose: Delete all records from specified temp table.
--------------------------------------------------------------------------------------------
FUNCTION CLEAR_TEMP_TABLE(O_error_message  IN OUT  VARCHAR2,
                          I_table_name     IN      VARCHAR2)
RETURN BOOLEAN is
   L_program   VARCHAR2(40) := 'DIFF_APPLY_SQL.CLEAR_TEMP_TABLE';
BEGIN
   --- Delete records from specified table.
   if upper(I_table_name) = 'ITEM_TEMP' then
      delete from ITEM_TEMP;
   elsif upper(I_table_name) = 'TEMP_DIFF1' then
      delete from TEMP_DIFF1;
   elsif upper(I_table_name) = 'TEMP_DIFF2' then
      delete from TEMP_DIFF2;
   elsif upper(I_table_name) = 'TEMP_DIFF3' then
      delete from TEMP_DIFF3;
   elsif upper(I_table_name) = 'TEMP_DIFF4' then
      delete from TEMP_DIFF4;
   elsif upper(I_table_name) = 'TEMP_DIFF_DUPLICATE' then
      delete from TEMP_DIFF_DUPLICATE;
   elsif upper(I_table_name) = 'ALL' then
      delete from ITEM_TEMP;
      delete from TEMP_DIFF1;
      delete from TEMP_DIFF2;
      delete from TEMP_DIFF3;
      delete from TEMP_DIFF4;
      delete from TEMP_DIFF_DUPLICATE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      return FALSE;
END CLEAR_TEMP_TABLE;
--------------------------------------------------------------------------------------------
--    Name: CHECK_ITEM_TEMP
-- Purpose: Check item_temp table to see if any diffs have been applied.
--------------------------------------------------------------------------------------------
FUNCTION CHECK_ITEM_TEMP(O_error_message  IN OUT  VARCHAR2,
                         O_diffs_applied  IN OUT  VARCHAR2)
RETURN BOOLEAN is
   L_program   VARCHAR2(40) := 'DIFF_APPLY_SQL.CHECK_DIFFS_APPLIED';
   cursor C_CHECK_DIFFS is
      select 'Y'
        from item_temp;
BEGIN
   O_diffs_applied := 'N';
   --- Check if any diffs have been applied.
   open C_CHECK_DIFFS;
   fetch C_CHECK_DIFFS into O_diffs_applied;
   close C_CHECK_DIFFS;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      return FALSE;
END CHECK_ITEM_TEMP;
--------------------------------------------------------------------------------------------
--    Name: VALIDATE_ITEM_TEMP
-- Purpose: Validate records on item_temp table before creating and commiting children.
--------------------------------------------------------------------------------------------
FUNCTION VALIDATE_ITEM_TEMP(O_error_message  IN OUT  VARCHAR2,
                            O_valid          IN OUT  BOOLEAN)
RETURN BOOLEAN IS
   L_program   VARCHAR2(40) := 'DIFF_APPLY_SQL.VALIDATE_ITEM_TEMP';
   cursor C_CHECK_RECORDS is
      select item
           , item_number_type
        from item_temp;
BEGIN
   for rec in C_CHECK_RECORDS loop
      if rec.item is NULL then
         if rec.item_number_type = 'VPLU' then
            O_error_message := sql_lib.create_msg('INV_ITEM_TEMP_VPLU_REC', NULL, NULL, NULL);
         else
            O_error_message := sql_lib.create_msg('INV_ITEM_TEMP_REC', NULL, NULL, NULL);
         end if;
         O_valid := FALSE;
         return TRUE;
      end if;
   end loop;
   O_valid := TRUE;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      return FALSE;
END VALIDATE_ITEM_TEMP;
--------------------------------------------------------------------------------------------
--    Name: TEMP_ITEM_EXISTS
-- Purpose: Determine if an item with diffs is on item_temp table before applying item to temp table.
--------------------------------------------------------------------------------------------
FUNCTION TEMP_ITEM_EXISTS(O_error_message  IN OUT  VARCHAR2,
                          O_exists         IN OUT  BOOLEAN,
                          I_item           IN      ITEM_MASTER.ITEM%TYPE,
                          I_diff1          IN      ITEM_MASTER.DIFF_1%TYPE,
                          I_diff2          IN      ITEM_MASTER.DIFF_2%TYPE,
                          I_diff3          IN      ITEM_MASTER.DIFF_3%TYPE,
                          I_diff4          IN      ITEM_MASTER.DIFF_4%TYPE)
RETURN BOOLEAN IS
   L_program   VARCHAR2(40) := 'DIFF_APPLY_SQL.TEMP_ITEM_EXISTS';
   L_found     VARCHAR2(1);
   cursor C_ITEM_EXISTS is
      select 'Y'
        from item_temp
       where item = I_item
         and (diff_1 != I_diff1
              or (diff_1 = I_diff1
                  and diff_2 != I_diff2 and diff_3 != I_diff3 and diff_4 != I_diff4)
              or (diff_2 = I_diff2
                  and diff_3 != I_diff3 and diff_4 != I_diff4)
              or (diff_3 = I_diff3
                  and diff_2 != I_diff2 and diff_4 != I_diff4));
BEGIN
   SQL_LIB.SET_MARK('OPEN','C_ITEM_EXISTS','item_temp','Item:'||I_item);
   open C_ITEM_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_EXISTS','item_temp','Item:'||I_item);
   fetch C_ITEM_EXISTS into L_found;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_EXISTS','item_temp','Item:'||I_item);
   close C_ITEM_EXISTS;
   ---
   O_exists := FALSE;
   if L_found = 'Y' then
      O_exists := TRUE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      return FALSE;
END TEMP_ITEM_EXISTS;
--------------------------------------------------------------------------------------------
--    Name: POP_RANGE_ITEM_TEMP
-- Purpose: Create potential new child records from the cartesian product of the
--          2 ranges on diff_range_detail records.  These ranges must have at least 2 diffs
--          specified.
--------------------------------------------------------------------------------------------
FUNCTION POP_RANGE_ITEM_TEMP(O_error_message     IN OUT  VARCHAR2,
                             O_item_temp_created IN OUT  BOOLEAN,
                             O_dups_created      IN OUT  BOOLEAN,
                             I_item_temp_rec     IN      item_temp_rectype,
                             I_info_rec          IN      diff_range_rectype)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(40) := 'DIFF_APPLY_SQL.POP_RANGE_ITEM_TEMP';

   program_error          exception;

   L_diff1_col            VARCHAR2(30);
   L_diff2_col            VARCHAR2(30);
   L_diff3_col            VARCHAR2(30);
   L_diff4_col            VARCHAR2(30);

   L_diff_desc_length     NUMBER;
   L_parent_desc_length   NUMBER;

   L_from_clause          VARCHAR2(500);
   L_where_clause         VARCHAR2(1000);

   L_insert_string        VARCHAR2(2000);

PROCEDURE LP_set_diff_values(I_diff_range_group1   IN   DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE,
                             I_diff_range_group2   IN   DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE,
                             I_table_alias         IN   VARCHAR2)
   IS

BEGIN
   if I_item_temp_rec.parent_diff1 = I_diff_range_group1 then
      L_diff1_col := I_table_alias||'.diff_1,';
      L_where_clause := L_where_clause||
                        ' and d1.diff_id = '||I_table_alias||'.diff_1';
   elsif I_item_temp_rec.parent_diff1 = I_diff_range_group2 then
      L_diff1_col := I_table_alias||'.diff_2,';
      L_where_clause := L_where_clause||
                        ' and d1.diff_id = '||I_table_alias||'.diff_2';
   elsif L_diff1_col is NULL then
      L_diff1_col := 'NULL,';
   end if;
   ---
   if I_item_temp_rec.parent_diff2 = I_diff_range_group1 then
      L_diff2_col := I_table_alias||'.diff_1,';
      L_where_clause := L_where_clause||
                        ' and d2.diff_id = '||I_table_alias||'.diff_1';
   elsif I_item_temp_rec.parent_diff2 = I_diff_range_group2 then
      L_diff2_col := I_table_alias||'.diff_2,';
      L_where_clause := L_where_clause||
                        ' and d2.diff_id = '||I_table_alias||'.diff_2';
   elsif L_diff2_col is NULL then
      L_diff2_col := 'NULL,';
   end if;
   ---
   if I_item_temp_rec.parent_diff3 = I_diff_range_group1 then
      L_diff3_col := I_table_alias||'.diff_1,';
      L_where_clause := L_where_clause||
                        ' and d3.diff_id = '||I_table_alias||'.diff_1';
   elsif I_item_temp_rec.parent_diff3 = I_diff_range_group2 then
      L_diff3_col := I_table_alias||'.diff_2,';
      L_where_clause := L_where_clause||
                        ' and d3.diff_id = '||I_table_alias||'.diff_2';
   elsif L_diff3_col is NULL then
      L_diff3_col := 'NULL,';
   end if;
   ---
   if I_item_temp_rec.parent_diff4 = I_diff_range_group1 then
      L_diff4_col := I_table_alias||'.diff_1, ';
      L_where_clause := L_where_clause||
                        ' and d4.diff_id = '||I_table_alias||'.diff_1';
   elsif I_item_temp_rec.parent_diff4 = I_diff_range_group2 then
      L_diff4_col := I_table_alias||'.diff_2, ';
      L_where_clause := L_where_clause||
                        ' and d4.diff_id = '||I_table_alias||'.diff_2';
   elsif L_diff4_col is NULL then
      L_diff4_col := 'NULL, ';
   end if;

END LP_set_diff_values;


/*****  Start of Main Program  *****/
BEGIN

   --- Check for NULL parameters
   if I_item_temp_rec.item_number_type is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.item_number_type ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.auto_create is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.auto_create',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.item_parent is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.item_parent',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.parent_desc is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.parent_desc',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.parent_diff1 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.parent_diff1 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.parent_diff2 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.parent_diff2 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.parent_diff3 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.parent_diff3 ',
                                            L_program, NULL);
      return FALSE;
   elsif I_item_temp_rec.parent_diff4 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.parent_diff4 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_info_rec.multi_range1 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_info_rec.multi_range1 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_info_rec.multi_range2 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_info_rec.multi_range2 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_info_rec.diff_range1_group1 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_info_rec.diff_range1_group1 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_info_rec.diff_range1_group2 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_info_rec.diff_range1_group1 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_info_rec.diff_range2_group1 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_info_rec.diff_range2_group1 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_info_rec.diff_range2_group2 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_info_rec.diff_range2_group2 ',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   GET_DESC_LENGTH(O_error_message,
                   L_parent_desc_length,
                   L_diff_desc_length,
                   I_item_temp_rec);
   if O_error_message is not NULL then
      raise PROGRAM_ERROR;
   end if;
   ---
   L_from_clause := '  from diff_range_detail rgd1, '||
                           'diff_range_detail rgd2, '||
                           'diff_ids d1, '||
                           'diff_ids d2, '||
                           'diff_ids d3, '||
                           'diff_ids d4  ';

   L_where_clause := '  where rgd1.diff_range = '||I_info_rec.multi_range1||
                     ' and rgd2.diff_range = '||I_info_rec.multi_range2;

   LP_set_diff_values(I_info_rec.diff_range1_group1,
                      I_info_rec.diff_range1_group2,
                      'rgd1');

   LP_set_diff_values(I_info_rec.diff_range2_group1,
                      I_info_rec.diff_range2_group2,
                      'rgd2');

   L_where_clause := L_where_clause||
                     ' and not exists (select ''x'''||
                                ' from item_temp itmp '||
                          ' where itmp.diff_1 = d1.diff_id '||
                          '   and itmp.diff_2 = d2.diff_id '||
                          '   and itmp.diff_3 = d3.diff_id '||
                          '   and itmp.diff_4 = d4.diff_id) ' ;


   L_insert_string :=
      'insert into item_temp '||
       '(item_number_type,'||
         'item_level,'||
         'item_desc,'||
         'diff_1,diff_2,diff_3,diff_4,'||
         'existing_item_parent) '||
       ' select '''||I_item_temp_rec.item_number_type||''','||
       '2,'||
       'RTRIM(substrb('''||I_item_temp_rec.parent_desc||''',1,'||L_parent_desc_length||'))'||
             '||'':''
              ||RTRIM(substrb(d1.diff_desc,1,'||L_diff_desc_length||'))
              ||'':''
              ||RTRIM(substrb(d2.diff_desc,1,'||L_diff_desc_length||'))
              ||'':''
              ||RTRIM(substrb(d3.diff_desc,1,'||L_diff_desc_length||'))
              ||'':''
              ||RTRIM(substrb(d4.diff_desc,1,'||L_diff_desc_length||')),'||
       L_diff1_col||
       L_diff2_col||
       L_diff3_col||
       L_diff4_col||
       ''''||I_item_temp_rec.item_parent||''''||
       L_from_clause||
       L_where_clause;

    EXECUTE IMMEDIATE L_insert_string;
    ---
    COMPLETE_ITEM_TEMP(O_error_message,
                       O_item_temp_created,
                       O_dups_created,
                       I_item_temp_rec.item_parent,
                       I_item_temp_rec.item_number_type,
                       I_item_temp_rec.auto_create);
   if O_error_message is not NULL then
      raise PROGRAM_ERROR;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      if O_error_message is NULL then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      end if;
      return FALSE;
END POP_RANGE_ITEM_TEMP;
--------------------------------------------------------------------------------------------
--    Name: POP_MIXED_ITEM_TEMP
-- Purpose: Create potential new child records from the cartesian product of the
--          'SELECTED' temp_diffx records and records from diff_range_detail for 1 range that
--          has at least 2 diffs specified.  This also handles creating the child records for
--          a single range when no temp_diffx records exist.
--------------------------------------------------------------------------------------------
FUNCTION POP_MIXED_ITEM_TEMP(O_error_message     IN OUT  VARCHAR2,
                             O_item_temp_created IN OUT  BOOLEAN,
                             O_dups_created      IN OUT  BOOLEAN,
                             I_item_temp_rec     IN      item_temp_rectype,
                             I_info_rec          IN      diff_mixed_rectype)
RETURN BOOLEAN IS

   L_program              VARCHAR2(40) := 'DIFF_APPLY_SQL.POP_MIXED_ITEM_TEMP';

   program_error          exception;

   L_diff1_col            VARCHAR2(61);
   L_diff2_col            VARCHAR2(61);
   L_diff3_col            VARCHAR2(61);
   L_diff4_col            VARCHAR2(61);

   L_desc_string          VARCHAR2(255);

   L_diff1_display_seq    VARCHAR2(61) := 'NULL,';
   L_diff2_display_seq    VARCHAR2(61) := 'NULL,';
   L_diff3_display_seq    VARCHAR2(61) := 'NULL,';
   L_diff4_display_seq    VARCHAR2(61) := 'NULL,';

   L_diff_desc_length     NUMBER;
   L_parent_desc_length   NUMBER;

   L_from_clause          VARCHAR2(1000);
   L_from_length          NUMBER;
   L_where_clause         VARCHAR2(2000);

   L_insert_string        VARCHAR2(5000);

BEGIN

   --- Check for NULL parameters
   if I_item_temp_rec.item_number_type is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.item_number_type ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.auto_create is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.auto_create',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.item_parent is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.item_parent',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.parent_desc is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.parent_desc',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.parent_diff1 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.parent_diff1 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item_temp_rec.parent_diff2 is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_item_temp_rec.parent_diff2 ',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_info_rec.multi_range is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL',
                                            'I_info_rec.multi_range ',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   GET_DESC_LENGTH(O_error_message,
                   L_parent_desc_length,
                   L_diff_desc_length,
                   I_item_temp_rec);
   if O_error_message is not NULL then
      raise PROGRAM_ERROR;
   end if;

   L_program  := 'DIFF_APPLY_SQL.POP_MIXED_ITEM_TEMP';
   ---
   if I_info_rec.diff1_used = 'Y' then
      L_diff1_col := 'td1.diff_1,';
      L_diff1_display_seq := 'td1.display_seq,';
      L_from_clause := L_from_clause||' temp_diff1 td1,diff_ids d1,';
      L_where_clause := L_where_clause||' and td1.selected_ind = '||'''Y'''||
                                        ' and td1.diff_1 = d1.diff_id';
   else
      if I_item_temp_rec.parent_diff1 = I_info_rec.diff_range_group1 then
         L_diff1_col := 'rgd.diff_1,';
         L_from_clause := L_from_clause||' diff_ids d1,';
         L_where_clause := L_where_clause||' and rgd.diff_1 = d1.diff_id';
      elsif I_item_temp_rec.parent_diff1 = I_info_rec.diff_range_group2 then
         L_diff1_col := 'rgd.diff_2,';
         L_from_clause := L_from_clause||' diff_ids d1,';
         L_where_clause := L_where_clause||' and rgd.diff_2 = d1.diff_id';
      elsif I_item_temp_rec.parent_diff1 = I_info_rec.diff_range_group3 then
         L_diff1_col := 'rgd.diff_3,';
         L_from_clause := L_from_clause||' diff_ids d1,';
         L_where_clause := L_where_clause||' and rgd.diff_3 = d1.diff_id';
      else
         L_diff1_col := 'NULL,';
      end if;
   end if;

   if I_info_rec.diff2_used = 'Y' then
      L_diff2_col := 'td2.diff_2,';
      L_diff2_display_seq := 'td2.display_seq,';
      L_from_clause := L_from_clause||' temp_diff2 td2,diff_ids d2,';
      L_where_clause := L_where_clause||' and td2.selected_ind = '||'''Y'''||
                                        ' and td2.diff_2 = d2.diff_id';
   else
      if I_item_temp_rec.parent_diff2 = I_info_rec.diff_range_group1 then
         L_diff2_col := 'rgd.diff_1,';
         L_from_clause := L_from_clause||' diff_ids d2,';
         L_where_clause := L_where_clause||' and rgd.diff_1 = d2.diff_id';
      elsif I_item_temp_rec.parent_diff2 = I_info_rec.diff_range_group2 then
         L_diff2_col := 'rgd.diff_2,';
         L_from_clause := L_from_clause||' diff_ids d2,';
         L_where_clause := L_where_clause||' and rgd.diff_2 = d2.diff_id';
      elsif I_item_temp_rec.parent_diff2 = I_info_rec.diff_range_group3 then
         L_diff2_col := 'rgd.diff_3,';
         L_from_clause := L_from_clause||' diff_ids d2,';
         L_where_clause := L_where_clause||' and rgd.diff_3 = d2.diff_id';
      else
         L_diff2_col := 'NULL,';
      end if;
   end if;

   if I_info_rec.diff3_used = 'Y' then
      L_diff3_col := 'td3.diff_3,';
      L_diff3_display_seq := 'td3.display_seq,';
      L_from_clause := L_from_clause||' temp_diff3 td3,diff_ids d3,';
      L_where_clause := L_where_clause||' and td3.selected_ind = '||'''Y'''||
                                        ' and td3.diff_3 = d3.diff_id';
   else
      if I_item_temp_rec.parent_diff3 = I_info_rec.diff_range_group1 then
         L_diff3_col := 'rgd.diff_1,';
         L_from_clause := L_from_clause||' diff_ids d3,';
         L_where_clause := L_where_clause||' and rgd.diff_1 = d3.diff_id';
      elsif I_item_temp_rec.parent_diff3 = I_info_rec.diff_range_group2 then
         L_diff3_col := 'rgd.diff_2,';
         L_from_clause := L_from_clause||' diff_ids d3,';
         L_where_clause := L_where_clause||' and rgd.diff_2 = d3.diff_id';
      elsif I_item_temp_rec.parent_diff3 = I_info_rec.diff_range_group3 then
         L_diff3_col := 'rgd.diff_3,';
         L_from_clause := L_from_clause||' diff_ids d3,';
         L_where_clause := L_where_clause||' and rgd.diff_3 = d3.diff_id';
      else
         L_diff3_col := 'NULL,';
      end if;
   end if;

   if I_info_rec.diff4_used = 'Y' then
      L_diff4_col := 'td4.diff_4, ';
      L_diff4_display_seq := 'td4.display_seq,';
      L_from_clause := L_from_clause||' temp_diff4 td4,diff_ids d4,';
      L_where_clause := L_where_clause||' and td4.selected_ind = '||'''Y'''||
                                        ' and td4.diff_4 = d4.diff_id';
   else
      if I_item_temp_rec.parent_diff4 = I_info_rec.diff_range_group1 then
         L_diff4_col := 'rgd.diff_1, ';
         L_from_clause := L_from_clause||' diff_ids d4,';
         L_where_clause := L_where_clause||' and rgd.diff_1 = d4.diff_id';
      elsif I_item_temp_rec.parent_diff4 = I_info_rec.diff_range_group2 then
         L_diff4_col := 'rgd.diff_2, ';
         L_from_clause := L_from_clause||' diff_ids d4,';
         L_where_clause := L_where_clause||' and rgd.diff_2 = d4.diff_id';
      elsif I_item_temp_rec.parent_diff4 = I_info_rec.diff_range_group3 then
         L_diff4_col := 'rgd.diff_3, ';
         L_from_clause := L_from_clause||' diff_ids d4,';
         L_where_clause := L_where_clause||' and rgd.diff_3 = d4.diff_id';
      else
         L_diff4_col := 'NULL, ';
      end if;
   end if;

   L_from_clause := ' from diff_range_detail rgd,'||L_from_clause;
   L_from_length := length(L_from_clause);
   L_from_clause := substr(L_from_clause,1,L_from_length-1);

   L_where_clause := ' where rgd.diff_range = '||I_info_rec.multi_range||L_where_clause;
   L_where_clause := L_where_clause||
                     ' and not exists (select ''x'''||
                                ' from item_temp itmp '||
                          ' where itmp.diff_1 = d1.diff_id '||
                          '   and itmp.diff_2 = d2.diff_id ';

   if L_diff3_col not like 'NULL%' then
      L_desc_string := '||'':''||RTRIM(substrb(d3.diff_desc,1,'||L_diff_desc_length||'))';
      L_where_clause := L_where_clause||
                        '   and itmp.diff_3 = d3.diff_id ';
      if L_diff4_col not like 'NULL%' then
         L_desc_string := L_desc_string||'||'':''||RTRIM(substrb(d4.diff_desc,1,'||L_diff_desc_length||')),';
         L_where_clause := L_where_clause||
                           '   and itmp.diff_4 = d4.diff_id) ' ;
      else
         L_desc_string := L_desc_string||',';
         L_where_clause := L_where_clause||') ';
      end if;
   else
      L_desc_string := L_desc_string||',';
      L_where_clause := L_where_clause||') ';
   end if;
   L_insert_string :=
      'insert into item_temp '||
       '(item_number_type,'||
         'item_level,'||
         'item_desc,'||
         'diff_1,display_seq_1,diff_2,display_seq_2,diff_3,display_seq_3,diff_4,display_seq_4,'||
         'existing_item_parent)'||
       ' select '''||I_item_temp_rec.item_number_type||''','||
       '2,'||
       'RTRIM(substrb('''||I_item_temp_rec.parent_desc||''',1,'||L_parent_desc_length||'))'||
             '||'':''
              ||RTRIM(substrb(d1.diff_desc,1,'||L_diff_desc_length||'))
              ||'':''
              ||RTRIM(substrb(d2.diff_desc,1,'||L_diff_desc_length||'))'||
              L_desc_string||
       L_diff1_col||
       L_diff1_display_seq||
       L_diff2_col||
       L_diff2_display_seq||
       L_diff3_col||
       L_diff3_display_seq||
       L_diff4_col||
       L_diff4_display_seq||
       ''''||I_item_temp_rec.item_parent||''''||
       L_from_clause||
       L_where_clause;

   EXECUTE IMMEDIATE L_insert_string;
   COMPLETE_ITEM_TEMP(O_error_message,
                      O_item_temp_created,
                      O_dups_created,
                      I_item_temp_rec.item_parent,
                      I_item_temp_rec.item_number_type,
                      I_item_temp_rec.auto_create);
   if O_error_message is not NULL then
      raise PROGRAM_ERROR;
   end if;

   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      if O_error_message is NULL then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      end if;
      return FALSE;
END POP_MIXED_ITEM_TEMP;
--------------------------------------------------------------------------------------------
--    Name: UPDATE_TEMP_DIFF_RANGE
-- Purpose: Update a diff_tempx table to select the diff_ids in the diff_range_detail table
--          for the input diff_range identifier.  This is done only for diff ranges that have
--          1 diff specified.
--------------------------------------------------------------------------------------------
FUNCTION UPDATE_TEMP_DIFF_RANGE (O_error_message  IN OUT  VARCHAR2,
                                 I_diff_range     IN      DIFF_RANGE_HEAD.DIFF_RANGE%TYPE,
                                 I_table_no       IN      NUMBER)
RETURN BOOLEAN IS
   L_program    VARCHAR2(40) := 'DIFF_APPLY_SQL.UPDATE_TEMP_DIFF_RANGE';
   L_temp_table VARCHAR2(20)  := 'TEMP_DIFF'||I_table_no;
   L_diff_range DIFF_RANGE_HEAD.DIFF_RANGE%TYPE := I_diff_range;

   program_error   exception;

BEGIN

   EXECUTE IMMEDIATE
     'update '||L_temp_table||' td '
   ||  ' set selected_ind = ''Y'''
   ||' where exists(select ''x'''
   ||               ' from diff_range_detail rd '
   ||              ' where rd.diff_range = '||L_diff_range
   ||                ' and rd.diff_1 = td.diff_'||I_table_no||')';

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      return FALSE;
END UPDATE_TEMP_DIFF_RANGE;
--------------------------------------------------------------------------------------------
--    Name: ITEM_NUMBER_TYPE
-- Purpose: Returns the item_number_type if existing children exist.
--------------------------------------------------------------------------------------------
FUNCTION ITEM_NUMBER_TYPE(O_error_message     IN OUT  VARCHAR2,
                          O_item_number_type  IN OUT  ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                          I_item_parent       IN      ITEM_MASTER.ITEM_PARENT%TYPE)
RETURN BOOLEAN IS
   L_program      VARCHAR2(40) := 'DIFF_APPLY_SQL.ITEM_NUMBER_TYPE';
   cursor C_GET_ITEM_LEVEL is
      select item_number_type
        from item_master
       where item_parent = I_item_parent
         and item_level  = 2
         --DefNBS026931,21-Mar-2014,Sriranjitha,Sriranjitha.Bhagi@in.tesco.com BEGIN
         and item_number_type='TPNB';
         --DefNBS026931,21-Mar-2014,Sriranjitha,Sriranjitha.Bhagi@in.tesco.com END
BEGIN
   --- Look for the item number type of any existing children.
   O_item_number_type := NULL;
   open  C_GET_ITEM_LEVEL;
   fetch C_GET_ITEM_LEVEL into O_item_number_type;
   close C_GET_ITEM_LEVEL;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      return FALSE;
END ITEM_NUMBER_TYPE;

--------------------------------------------------------------------------------------------
--    Name: DELETE_SELECTED_ITEM_TEMP
-- Purpose: Delete records from the item_temp table based on filter criteria passed
--          into the function.
--------------------------------------------------------------------------------------------
FUNCTION DELETE_SELECTED_ITEM_TEMP(O_error_message     IN OUT  VARCHAR2,
                                   I_item_parent       IN      ITEM_MASTER.ITEM_PARENT%TYPE,
                                   I_diff_1            IN      ITEM_TEMP.DIFF_1%TYPE,
                                   I_diff_2            IN      ITEM_TEMP.DIFF_2%TYPE,
                                   I_diff_3            IN      ITEM_TEMP.DIFF_3%TYPE,
                                   I_diff_4            IN      ITEM_TEMP.DIFF_4%TYPE)
RETURN BOOLEAN IS

   L_program      VARCHAR2(40)           := 'DIFF_APPLY_SQL.DELETE_SELECTED_ITEM_TEMP';
BEGIN

   delete from item_temp
     where existing_item_parent = I_item_parent
       and (diff_1 like ('%'||I_diff_1||'%')
            or I_diff_1 is NULL)
       and (diff_2 like ('%'||I_diff_2||'%')
            or I_diff_2 is NULL)
       and (diff_3 like ('%'||I_diff_3||'%')
            or I_diff_3 is NULL)
       and (diff_4 like ('%'||I_diff_4||'%')
            or I_diff_4 is NULL);
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM, L_program, NULL);
      return FALSE;

END DELETE_SELECTED_ITEM_TEMP;
--------------------------------------------------------------------------------------------
END DIFF_APPLY_SQL;
/

