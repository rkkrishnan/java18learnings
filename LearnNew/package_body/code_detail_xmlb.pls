CREATE OR REPLACE PACKAGE BODY CODE_DETAIL_XML AS

--------------------------------------------------------------------------------
FUNCTION DELETE_CODE_DETAIL(O_status  	      OUT    VARCHAR2,
                            O_text    	      OUT    VARCHAR2,
                   	    I_code_detail_rec   IN     CODE_DETAIL%ROWTYPE,
                   	    root      	      IN OUT rib_sxw.SXWHandle)
RETURN BOOLEAN;
--------------------------------------------------------------------------------
FUNCTION ADD_UPDATE_CODE_DETAIL(O_status           OUT    VARCHAR2,
                       	        O_text             OUT    VARCHAR2,
                       	        I_code_detail_rec  IN     CODE_DETAIL%ROWTYPE,
                       	        root               IN OUT rib_sxw.SXWHandle)
RETURN BOOLEAN;
--------------------------------------------------------------------------------
FUNCTION BUILD_MESSAGE(O_status       	OUT VARCHAR2,
                       O_text         	OUT VARCHAR2,
                       O_code_detail_msg 	OUT rib_sxw.SXWHandle,
                       I_code_detail_rec  IN  CODE_DETAIL%ROWTYPE,
                       I_action_type  	IN  VARCHAR2)
RETURN BOOLEAN IS
   root            xmldom.DOMElement;
   L_doc_type  VARCHAR2(30) := NULL;

BEGIN
   if I_action_type = 'D' then
      L_doc_type := RMSMFM_SEEDDATA.DTL_REF_MSG;
      ---
      if not API_LIBRARY.CREATE_MESSAGE_STR(O_status,
                                            O_text,
                                            O_code_detail_msg,
                                            L_doc_type) then
         return FALSE;
      end if;
      ---
      if not DELETE_CODE_DETAIL(O_status,
                                O_text,
                       	        I_code_detail_rec,
                       	        O_code_detail_msg) then
         return FALSE;
      end if;

   else
      L_doc_type := RMSMFM_SEEDDATA.DTL_DESC_MSG;
      ---
      if not API_LIBRARY.CREATE_MESSAGE_STR(O_status,
                                            O_text,
                                            O_code_detail_msg,
                                            L_doc_type) then
         return FALSE;
      end if;
      ---
      if not ADD_UPDATE_CODE_DETAIL(O_status,
                                    O_text,
                                    I_code_detail_rec,
                                    O_code_detail_msg) then
         return FALSE;
      end if;

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status,
                                O_text,
                                API_LIBRARY.FATAL_ERROR,
                                'CODE_DETAIL_XML.BUILD_MESSAGE');
      return FALSE;

END BUILD_MESSAGE;
--------------------------------------------------------------------------------


      /*** Private Program Bodies ***/
--------------------------------------------------------------------------------
FUNCTION DELETE_CODE_DETAIL(O_status     	    OUT    VARCHAR2,
                            O_text       	    OUT    VARCHAR2,
                   	    I_code_detail_rec IN     CODE_DETAIL%ROWTYPE,
                   	    root         	    IN     OUT rib_sxw.SXWHandle)
RETURN BOOLEAN IS


BEGIN
   rib_sxw.addElement( root, 'code_type', I_code_detail_rec.code_type);
   rib_sxw.addElement( root, 'code', I_code_detail_rec.code);

   O_status := API_CODES.SUCCESS;

   return true;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status,
                                O_text,
                                API_LIBRARY.FATAL_ERROR,
                                'CODE_DETAIL_XML.DELETE_CODE_DETAIL');
      return FALSE;

END DELETE_CODE_DETAIL;
--------------------------------------------------------------------------------
FUNCTION ADD_UPDATE_CODE_DETAIL(O_status           OUT    VARCHAR2,
                       	        O_text             OUT    VARCHAR2,
                       	        I_code_detail_rec  IN     CODE_DETAIL%ROWTYPE,
                       	        root               IN OUT rib_sxw.SXWHandle)
RETURN BOOLEAN IS

BEGIN
   rib_sxw.addElement( root, 'code_type', I_code_detail_rec.code_type);
   rib_sxw.addElement( root, 'code', I_code_detail_rec.code);
   rib_sxw.addElement( root, 'code_desc', I_code_detail_rec.code_desc);
   rib_sxw.addElement( root, 'required_ind', I_code_detail_rec.required_ind);
   rib_sxw.addElement( root, 'code_seq', I_code_detail_rec.code_seq);

   O_status := API_CODES.SUCCESS;

   return true;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status,
                                O_text,
                                API_LIBRARY.FATAL_ERROR,
                                'CODE_DETAIL_XML.ADD_UPDATE_CODE_DETAIL');
      return FALSE;

END ADD_UPDATE_CODE_DETAIL;
--------------------------------------------------------------------------------
END CODE_DETAIL_XML;
/

