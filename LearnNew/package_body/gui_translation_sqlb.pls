CREATE OR REPLACE PACKAGE BODY GUI_TRANSLATION_SQL AS

--------------------------------------------------------------------------------------------------------
-- Mod By     : V Manikandan, Manikandan.Varadhan@in.tesco.com
-- Mod Date   : 22-Jun-2010
-- Mod Ref    : PrfNBS00017520
-- Mod Details: Modified the cursor C_FORM_ELEMENTS to improve the performance
--------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------
FUNCTION GET_LABEL_PROMPT_AKEY(O_error_message                   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                               O_list_user_form_elements         IN OUT   LIST_USER_FORM_ELEMENTS,
                               O_list_user_menu_elements         IN OUT   LIST_USER_MENU_ELEMENTS,
                               I_form                            IN       FORM_ELEMENTS.FM_NAME%TYPE)
RETURN BOOLEAN IS

   L_program                       VARCHAR2(100) := 'GUI_TRANSLATION_SQL.GET_LABEL_PROMPT_AKEY';
   L_user_lang                     LANG.LANG%TYPE;
   L_is_multiview                  VARCHAR2(1) := 'N';
   L_is_col_head                   VARCHAR2(1) := 'N';
   ---
   L_before_access_key             FORM_ELEMENTS.DEFAULT_LABEL_PROMPT%TYPE;
   L_after_access_key              FORM_ELEMENTS.DEFAULT_LABEL_PROMPT%TYPE;
   ---
   L_access_key_position           NUMBER;
   ---
   user_form_element_table_index   NUMBER := 0;
   L_user_form_element             USER_FORM_ELEMENT_RECORD;
   L_list_user_form_elements       LIST_USER_FORM_ELEMENTS;
   ---
   user_menu_element_table_index   NUMBER := 0;
   L_user_menu_element             USER_MENU_ELEMENT_RECORD;
   L_list_user_menu_elements       LIST_USER_MENU_ELEMENTS;
   ---
   cursor C_IS_MULTIVIEW_FORM is
   select 'Y'
     from multiview_default_45
    where (upper(nvl(substr(fm_name,0,(instr(fm_name, '_', 4)-1)), fm_name)) = upper(I_form)
	   or upper(fm_name) = upper(I_form))
      and rownum = 1;


   cursor C_IS_MULTIVIEW_COL_HEAD is
   select 'Y'
     from multiview_default_45
    where (upper(nvl(substr(fm_name,0,(instr(fm_name, '_', 4)-1)), fm_name)) = upper(I_form)
       or upper(fm_name) = upper(I_form))
      and upper(ti_name) = upper(L_user_form_element.block_name||'.'||L_user_form_element.item_name);

-- PrfNBS017520, 22-Jun-2010, HSC/Manikandan , Begin
   cursor C_FORM_ELEMENTS is
select /*+ FIRST_ROWS(10) */ fe.block_name,
          fe.item_name,
          fe.sub_item_name,
          fe.item_type,
          nvl(fel.lang_label_prompt, fe.default_label_prompt) label_prompt,
          nvl(fel.lang_access_key,fe.default_access_key) access_key
     from form_elements_langs fel,
          form_elements fe
    where fe.fm_name = I_form
      and upper(fe.fm_name) = upper(fel.fm_name(+))
      and upper(fe.block_name) = upper(fel.block_name(+))
      and upper(fe.item_name) = upper(fel.item_name(+))
      and upper(fe.sub_item_name) = upper(fel.sub_item_name(+))
      and L_user_lang = fel.lang(+)
      and fe.default_label_prompt is not NULL;
-- PrfNBS017520, 22-Jun-2010, HSC/Manikandan , End


   cursor C_MENU_ELEMENTS is
   select me.menu_name,
          me.menu_item_name,
          nvl(mel.lang_label, me.default_label) label
     from menu_elements_langs mel,
          menu_elements me,
          form_menu_link fml
    where upper(fml.fm_name) = upper(I_form)
      and upper(fml.menu_filename) = upper(me.menu_filename)
      and upper(me.menu_filename) = upper(mel.menu_filename(+))
      and upper(me.menu_name) = upper(mel.menu_name(+))
      and upper(me.menu_item_name) = upper(mel.menu_item_name(+))
      and L_user_lang = mel.lang(+);


BEGIN
   ---
   L_user_lang := get_user_lang;
   ---
   --Initialize the list that will be passed out of the function.
   ---
   L_list_user_form_elements := list_user_form_elements();
   L_list_user_menu_elements := list_user_menu_elements();
   ---
   --Check if the form is multiview - if the form is multiview, some special processing
   --is required to determine if text items are multiview column headers.
   ---Because the fm_name colum on mview_default_45 can contain the fm)name plus _xxx
   ---when there are multiple instances of multiview on a single form (ie. fm_dealmain_head
   ---fm_dealmain_detl, string manipulation must be done to the

   ---
   open C_IS_MULTIVIEW_FORM;
   fetch C_IS_MULTIVIEW_FORM into L_is_multiview;
   close C_IS_MULTIVIEW_FORM;
   ---
      for rec in C_FORM_ELEMENTS loop
         ---
         L_list_user_form_elements.extend;
         user_form_element_table_index  := user_form_element_table_index  +1;
	 ---
	 L_user_form_element.block_name               := rec.block_name;
	 L_user_form_element.item_name                := rec.item_name;
	 L_user_form_element.sub_item_name            := rec.sub_item_name;
	 L_user_form_element.item_type                := rec.item_type;
	 L_user_form_element.label_prompt             := rec.label_prompt;
	 L_user_form_element.access_key               := rec.access_key;
	 ---
	 --If the element is a button, an ampersand must be concatonated in to create the forms access key
	 if rec.item_type in ('Push Button') and rec.access_key is NOT NULL then
            ---
            L_access_key_position := INSTRB( upper(rec.label_prompt), upper(rec.access_key));
            ---
            if L_access_key_position > 0 then
	       ---
	       L_before_access_key := SUBSTRB(rec.label_prompt, 1, (L_access_key_position-1));
	       L_after_access_key  := SUBSTRB(rec.label_prompt,L_access_key_position);
	       ---
	       L_user_form_element.label_prompt := L_before_access_key||'&'||L_after_access_key;

	    else ---If this not greater than zero, the hotkey is not in the string and should be appended to the label
	       L_user_form_element.label_prompt := rec.label_prompt ||'  (&'|| rec.access_key||')';
	    end if;
	    ---
	 elsif L_is_multiview = 'Y' and rec.item_type in ('Text Item') then
	    ---
	    --Check to see if the current item is in the list of multiview items for the form
	    ---
	    open C_IS_MULTIVIEW_COL_HEAD;
	    fetch C_IS_MULTIVIEW_COL_HEAD into L_is_col_head;
	    close C_IS_MULTIVIEW_COL_HEAD;
	    ---
	    --If the text item is a column header, reassign the item type to Mview Col Header
	    --so that the initial value (as opposed to prompt/label) can be set
	    ---
	    if L_is_col_head = 'Y' then
	       L_user_form_element.item_type := 'Mview Col Header';
	    end if;
	    ---
	    --Reset the variable for the check of the next item.
	    ---
	    L_is_col_head := 'N';
	    ---
	 end if;
	 ---
         L_list_user_form_elements(user_form_element_table_index) := L_user_form_element;
         ---
      end loop;
      ---
      for rec in C_MENU_ELEMENTS loop
         ---
         L_list_user_menu_elements.extend;
         user_menu_element_table_index  := user_menu_element_table_index  +1;
      	 ---
      	 L_user_menu_element.menu_name                := rec.menu_name;
      	 L_user_menu_element.menu_item_name           := rec.menu_item_name;
      	 L_user_menu_element.label                    := rec.label;
      	 ---
         L_list_user_menu_elements(user_menu_element_table_index) := L_user_menu_element;
         ---
      end loop;
      ---
   O_list_user_form_elements := L_list_user_form_elements;
   O_list_user_menu_elements := L_list_user_menu_elements;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := O_error_message|| 'checkpoint:error' || SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END GET_LABEL_PROMPT_AKEY ;
----------------------------------------------------------------------------------------------------------------
END GUI_TRANSLATION_SQL;
/

