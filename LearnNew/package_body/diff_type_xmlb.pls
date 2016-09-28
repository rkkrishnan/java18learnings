CREATE OR REPLACE PACKAGE BODY DIFF_TYPE_XML AS

--------------------------------------------------------------------------------
FUNCTION DELETE_DIFF_TYPE(O_status  	  OUT    VARCHAR2,
                          O_text    	  OUT    VARCHAR2,
                   	  I_diff_type_rec   IN     DIFF_TYPE%ROWTYPE,
                   	  root      	  IN OUT rib_sxw.SXWHandle)
RETURN BOOLEAN;
--------------------------------------------------------------------------------
FUNCTION ADD_UPDATE_DIFF_TYPE(O_status         OUT    VARCHAR2,
                       	      O_text           OUT    VARCHAR2,
                       	      I_diff_type_rec  IN     DIFF_TYPE%ROWTYPE,
                       	      root             IN OUT rib_sxw.SXWHandle)
RETURN BOOLEAN;
--------------------------------------------------------------------------------
FUNCTION BUILD_MESSAGE(O_status       	OUT VARCHAR2,
                       O_text         	OUT VARCHAR2,
                       O_diff_type_msg 	OUT rib_sxw.SXWHandle,
                       I_diff_type_rec   	IN  DIFF_TYPE%ROWTYPE,
                       I_action_type  	IN  VARCHAR2)
RETURN BOOLEAN IS
   root            xmldom.DOMElement;
   L_doc_type  VARCHAR2(30) := NULL;

BEGIN
   if I_action_type = 'D' then
      L_doc_type := RMSMFM_SEEDDATA.DIFF_TYPE_REF_MSG;
      ---
      if not API_LIBRARY.CREATE_MESSAGE_STR(O_status,
                                            O_text,
                                            O_diff_type_msg,
                                            L_doc_type) then
         return FALSE;
      end if;
      ---
      if not DELETE_DIFF_TYPE(O_status,
                              O_text,
                       	      I_diff_type_rec,
                       	      O_diff_type_msg) then
         return FALSE;
      end if;

   else
      L_doc_type := RMSMFM_SEEDDATA.DIFF_TYPE_DESC_MSG;
      ---
      if not API_LIBRARY.CREATE_MESSAGE_STR(O_status,
                                            O_text,
                                            O_diff_type_msg,
                                            L_doc_type) then
         return FALSE;
      end if;
      ---
      if not ADD_UPDATE_DIFF_TYPE(O_status,
                                  O_text,
                                  I_diff_type_rec,
                                  O_diff_type_msg) then
         return FALSE;
      end if;

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status,
                                O_text,
                                API_LIBRARY.FATAL_ERROR,
                                'DIFF_TYPE_XML.BUILD_MESSAGE');
      return FALSE;

END BUILD_MESSAGE;
--------------------------------------------------------------------------------


      /*** Private Program Bodies ***/
--------------------------------------------------------------------------------
FUNCTION DELETE_DIFF_TYPE(O_status     	OUT    VARCHAR2,
                          O_text       	OUT    VARCHAR2,
                   	  I_diff_type_rec IN     DIFF_TYPE%ROWTYPE,
                   	  root         	IN     OUT rib_sxw.SXWHandle)
RETURN BOOLEAN IS


BEGIN
   rib_sxw.addElement( root, 'diff_type', I_diff_type_rec.diff_type);

   O_status := API_CODES.SUCCESS;

   return true;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status,
                                O_text,
                                API_LIBRARY.FATAL_ERROR,
                                'DIFF_TYPE_XML.DELETE_DIFF_TYPE');
      return FALSE;

END DELETE_DIFF_TYPE;
--------------------------------------------------------------------------------
FUNCTION ADD_UPDATE_DIFF_TYPE(O_status         OUT    VARCHAR2,
                       	      O_text           OUT    VARCHAR2,
                       	      I_diff_type_rec  IN     DIFF_TYPE%ROWTYPE,
                       	      root             IN OUT rib_sxw.SXWHandle)
RETURN BOOLEAN IS

BEGIN
   rib_sxw.addElement( root, 'diff_type', I_diff_type_rec.diff_type);
   rib_sxw.addElement( root, 'diff_type_desc', I_diff_type_rec.diff_type_desc);

   O_status := API_CODES.SUCCESS;

   return true;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status,
                                O_text,
                                API_LIBRARY.FATAL_ERROR,
                                'DIFF_TYPE_XML.ADD_UPDATE_DIFF_TYPE');
      return FALSE;

END ADD_UPDATE_DIFF_TYPE;
--------------------------------------------------------------------------------
END DIFF_TYPE_XML;
/

