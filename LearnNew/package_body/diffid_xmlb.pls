CREATE OR REPLACE PACKAGE BODY DIFFID_XML AS

--------------------------------------------------------------------------------
FUNCTION DELETE_DIFFID(O_status         OUT    VARCHAR2,
                       O_text             OUT    VARCHAR2,
                       I_diffid_rec      IN     DIFF_IDS%ROWTYPE,
                       root              IN OUT xmldom.DOMElement)
RETURN BOOLEAN;
--------------------------------------------------------------------------------
FUNCTION ADD_UPDATE_DIFFID(O_status      OUT    VARCHAR2,
                           O_text        OUT    VARCHAR2,
                           I_diffid_rec  IN     DIFF_IDS%ROWTYPE,
                           root          IN OUT xmldom.DOMElement)
RETURN BOOLEAN;
--------------------------------------------------------------------------------
/* BUILD_MESSAGE is the only public function in the package.  It is called
   whenever the database trigger captures an event that needs to be published.
   The trigger should pass in a record with all of the values from the table
   row, except in the case of deletes, when the record will only contain
   the identifier.

   BUILD_MESSAGE creates the XML message, puts it in a CLOB, and returns the
   CLOB.  The trigger should then insert the XML-CLOB in the message queue table.
*/

--------------------------------------------------------------------------------
FUNCTION BUILD_MESSAGE(O_status          OUT VARCHAR2,
                       O_text            OUT VARCHAR2,
                       O_message         OUT CLOB,
                       I_diffid_rec      IN  DIFF_IDS%ROWTYPE,
                       I_action_type     IN  VARCHAR2)
RETURN BOOLEAN IS
   root            xmldom.DOMElement;
   L_document_type  VARCHAR2(64) := NULL;

BEGIN
   if I_action_type = 'D' then
      L_document_type := 'DiffRef';
      ---
      if not API_LIBRARY.CREATE_MESSAGE(O_status,
                                        O_text,
                                        root,
                                        L_document_type) then
         return FALSE;
      end if;
      ---
      if not DELETE_DIFFID(O_status,
                           O_text,
                           I_diffid_rec,
                           root) then
         return FALSE;
      end if;

   else
      L_document_type := 'DiffDesc';
      ---
      if not API_LIBRARY.CREATE_MESSAGE(O_status,
                                        O_text,
                                        root,
                                        L_document_type) then
         return FALSE;
      end if;
      ---
      if not ADD_UPDATE_DIFFID(O_status,
                               O_text,
                               I_diffid_rec,
                               root) then
         return FALSE;
      end if;

   end if;

   if not API_LIBRARY.WRITE_DOCUMENT(O_status,
                                     O_text,
                                     O_message,
                                     root) then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status,
                                O_text,
                                API_LIBRARY.FATAL_ERROR,
                                'DIFFID_XML.BUILD_MESSAGE');
      return FALSE;

END BUILD_MESSAGE;
--------------------------------------------------------------------------------


      /*** Private Program Bodies ***/
--------------------------------------------------------------------------------
FUNCTION DELETE_DIFFID(O_status     OUT    VARCHAR2,
                       O_text       OUT    VARCHAR2,
                       I_diffid_rec IN     DIFF_IDS%ROWTYPE,
                       root         IN OUT xmldom.DOMElement)
RETURN BOOLEAN IS

   /* This function sets up a delete message by adding appropriate values to
      the XML msg. */

BEGIN
   /* The delete message will usually just include the identifier of the record
      that was deleted. */

   rib_xml.addElement( root, 'diff_id', I_diffid_rec.diff_id);

   O_status := API_CODES.SUCCESS;

   return true;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status,
                                O_text,
                                API_LIBRARY.FATAL_ERROR,
                                'DIFFID_XML.DELETE_DIFFID');
      return FALSE;

END DELETE_DIFFID;
--------------------------------------------------------------------------------
FUNCTION ADD_UPDATE_DIFFID(O_status          OUT    VARCHAR2,
                           O_text            OUT    VARCHAR2,
                           I_diffid_rec      IN     DIFF_IDS%ROWTYPE,
                           root              IN OUT xmldom.DOMElement)
RETURN BOOLEAN IS

   /* This function sets up an add or update message by adding
      appropriate values to the XML msg. */

BEGIN

   /* The add and update messages will include the identifier and a bunch of values.
      In some cases, the add and update messages will include different values,
      and this function will have to be split. */

   rib_xml.addElement( root, 'diff_id', I_diffid_rec.diff_id);
   rib_xml.addElement( root, 'diff_type', I_diffid_rec.diff_type);
   rib_xml.addElement( root, 'diff_desc', I_diffid_rec.diff_desc);
   rib_xml.addElement( root, 'industry_code', I_diffid_rec.industry_code);
   rib_xml.addElement( root, 'industry_subcode', I_diffid_rec.industry_subgroup);

   O_status := API_CODES.SUCCESS;

   return true;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status,
                                O_text,
                                API_LIBRARY.FATAL_ERROR,
                                'DIFFID_XML.ADD_UPDATE_DIFFID');
      return FALSE;

END ADD_UPDATE_DIFFID;
--------------------------------------------------------------------------------
END DIFFID_XML;
/

