CREATE OR REPLACE PACKAGE BODY DOCUMENTS_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    21-Jun-2007
--Mod Ref:     Mod number. 365b1
--Mod Details: Cascading the base item req_doc to its variants.
--             Appeneded TSL_COPY_BASE_REQ_DOC new function.
------------------------------------------------------------------------------------------------
FUNCTION NEXT_DOC_NO( O_error_message IN OUT VARCHAR2,
                      O_doc_id        IN OUT DOC.DOC_ID%TYPE)
   RETURN BOOLEAN IS

   L_first_time  VARCHAR2(3)               := 'YES';
   L_wrap_seq_no DOC.DOC_ID%TYPE           := 0;
   L_program     VARCHAR2(64)              := 'DOCUMENTS_SQL.NEXT_DOC_NO';
   L_exists      VARCHAR2(1)               := NULL;

   cursor C_EXIST_DOCUMENTS is
      select 'X'
        from doc
       where doc_id = O_doc_id;

   cursor C_SELECT_NEXTVAL is
      select doc_sequence.NEXTVAL
        from dual;

BEGIN

   LOOP
      SQL_LIB.SET_MARK('OPEN',
                       'C_SELECT_NEXTVAL',
                       'DUAL',
                        NULL);
      open C_SELECT_NEXTVAL;
      SQL_LIB.SET_MARK('FETCH',
                       'C_SELECT_NEXTVAL',
                       'DUAL',
                        NULL);
      fetch C_SELECT_NEXTVAL into O_doc_id;
      if (L_first_time = 'YES') then
         L_wrap_seq_no := O_doc_id;
         L_first_time  := 'NO';
      elsif (O_doc_id = L_wrap_seq_no) then
         O_error_message := SQL_LIB.CREATE_MSG('NO_DOC_ID_AVAIL',
                                                NULL,
                                                NULL,
                                                NULL);
         SQL_LIB.SET_MARK('CLOSE',
                          'C_SELECT_NEXTVAL',
                          'DUAL',
                           NULL);
         close C_SELECT_NEXTVAL;
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SELECT_NEXTVAL',
                       'DUAL',
                        NULL);
      close C_SELECT_NEXTVAL;

      SQL_LIB.SET_MARK('OPEN',
                       'C_EXIST_DOCUMENTS',
                       'DOC',
                       'DOC ID: '|| to_char(O_doc_id));
      open C_EXIST_DOCUMENTS;
      SQL_LIB.SET_MARK('FETCH',
                       'C_EXIST_DOCUMENTS',
                       'DOC',
                       'DOC ID: '|| to_char(O_doc_id));
      fetch C_EXIST_DOCUMENTS into L_exists;
      if C_EXIST_DOCUMENTS%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EXIST_DOCUMENTS',
                          'DOC',
                          'DOC ID: '|| to_char(O_doc_id));
         close C_EXIST_DOCUMENTS;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_EXIST_DOCUMENTS',
                       'DOC',
                       'DOC ID: '|| to_char(O_doc_id));
      close C_EXIST_DOCUMENTS;
   END LOOP;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END NEXT_DOC_NO;

---------------------------------------------------------------------------------------------
FUNCTION NEXT_REQ_DOC_KEY( O_error_message IN OUT VARCHAR2,
                           O_doc_key       IN OUT REQ_DOC.DOC_KEY%TYPE)
   RETURN BOOLEAN IS

   L_first_time   VARCHAR2(3)               := 'YES';
   L_wrap_doc_key REQ_DOC.DOC_KEY%TYPE      := 0;
   L_program      VARCHAR2(64)              := 'DOCUMENTS_SQL.NEXT_REQ_DOC_KEY';
   L_exists       VARCHAR2(1)               := NULL;

   cursor C_EXIST_REQ_DOC is
      select 'X'
        from req_doc
       where doc_key = O_doc_key;

   cursor C_SEQUENCE_NEXTVAL is
      select req_doc_sequence.NEXTVAL
        from dual;

BEGIN

   LOOP
      SQL_LIB.SET_MARK('OPEN',
                       'C_SEQUENCE_NEXTVAL',
                       'DUAL',
                        NULL);
      open C_SEQUENCE_NEXTVAL;
      SQL_LIB.SET_MARK('FETCH',
                       'C_SEQUENCE_NEXTVAL',
                       'DUAL', NULL);
      fetch C_SEQUENCE_NEXTVAL into O_doc_key;
      if (L_first_time = 'YES') then
         L_wrap_doc_key := O_doc_key;
         L_first_time  := 'NO';
      elsif L_wrap_doc_key = O_doc_key then
         O_error_message := SQL_LIB.CREATE_MSG('NO_SEQ_NO_AVAIL',
                                                NULL,
                                                NULL,
                                                NULL);
         SQL_LIB.SET_MARK('CLOSE',
                          'C_SEQUENCE_NEXTVAL',
                          'DUAL',
                           NULL);
         close c_SEQUENCE_NEXTVAL;
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SEQUENCE_NEXTVAL',
                       'DUAL',
                        NULL);
      close C_SEQUENCE_NEXTVAL;

      SQL_LIB.SET_MARK('OPEN',
                       'C_EXIST_REQ_DOC',
                       'REQ_DOC',
                       'DOC KEY: '|| to_char(O_doc_key));
      open C_EXIST_REQ_DOC;
      SQL_LIB.SET_MARK('FETCH',
                       'C_EXIST_REQ_DOC',
                       'REQ_DOC',
                       'DOC KEY: '|| to_char(O_doc_key));
      fetch C_EXIST_REQ_DOC into L_exists;
      if  C_EXIST_REQ_DOC%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EXIST_REQ_DOC',
                          'REQ_DOC',
                          'DOC KEY: '|| to_char(O_doc_key));
         close C_EXIST_REQ_DOC;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_EXIST_REQ_DOC',
                       'REQ_DOC',
                       'DOC KEY: '|| to_char(O_doc_key));
      close C_EXIST_REQ_DOC;
   END LOOP;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END NEXT_REQ_DOC_KEY;
-----------------------------------------------------------------------------------------------
FUNCTION GET_INFO (O_error_message  IN OUT  VARCHAR2,
                   O_exists	      IN OUT  BOOLEAN,
                   O_doc_desc       IN OUT  DOC.DOC_DESC%TYPE,
                   O_text           IN OUT  DOC.TEXT%TYPE,
                   I_doc_id         IN      DOC.DOC_ID%TYPE)
    RETURN BOOLEAN IS

   L_program   VARCHAR2(64)    := 'DOCUMENTS_SQL.GET_INFO';

   cursor C_GET_INFO is
      select doc_desc,
             text
        from doc
       where doc_id = I_doc_id;

BEGIN
   if I_doc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('NO_DOC_ID_FOUND',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_INFO',
                    'DOC',
                    'DOC_ID: '|| to_char(I_doc_id));
   open  C_GET_INFO;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_INFO',
                    'DOC',
                    'DOC_ID: '|| to_char(I_doc_id));
   fetch C_GET_INFO into O_doc_desc,
                         O_text;
   --- if there is no text found then O_exists is returned FALSE
   if C_GET_INFO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('NO_DOC_ID_FOUND',
                                            NULL,
                                            NULL,
                                            NULL);
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_INFO',
                    'DOC',
                    'DOC_ID: '|| to_char(I_doc_id));
   close C_GET_INFO;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_INFO;

---------------------------------------------------------------------------------------------
FUNCTION VALIDATE_TYPE( O_error_message IN OUT VARCHAR2,
                        O_exists        IN OUT BOOLEAN,
                        I_doc_module    IN     REQ_DOC.MODULE%TYPE,
                        I_doc_id        IN     DOC.DOC_ID%TYPE)
   RETURN BOOLEAN IS

   L_error_message      VARCHAR2(255);
   L_program		VARCHAR2(64) := 'DOCUMENT_SQL.VALIDATE_TYPE';
   L_exists	 	VARCHAR2(1);
   L_decode_module      VARCHAR2(40);
   L_module             REQ_DOC.MODULE%TYPE;
   ---
   cursor C_CHECK_DOC_ID is
   select 'Y'
     from doc, doc_link
    where doc.doc_type = doc_link.doc_type
      and doc_link.module = I_doc_module
      and doc.doc_id = I_doc_id;
   ---
BEGIN
   if (I_doc_module is NULL) or (I_doc_id is NULL) then
      O_error_message := 'INV_VALUE';
      return FALSE;
   end if;
   ---
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_DOC_ID',
                    'DOC, DOC_LINK',
                    'MODULE: '||I_doc_module ||
                    ', DOC_ID: ' || to_char(I_doc_id));
   open C_CHECK_DOC_ID;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_DOC_ID',
                    'DOC, DOC_LINK',
                    'MODULE: '||I_doc_module ||
                    ', DOC_ID: ' || to_char(I_doc_id));
   fetch C_CHECK_DOC_ID into L_exists;
   if C_CHECK_DOC_ID%NOTFOUND then
      if I_doc_module = 'LO' then
         L_module := 'LOG';
      elsif I_doc_module = 'CE' then
         L_module := 'CUST';
      elsif I_doc_module = 'CNTR' then
         L_module := 'CNT';
      elsif I_doc_module = 'PO' then
         L_module := 'PORD';
      elsif I_doc_module = 'SUPP' then
         L_module := 'SUP';
      elsif I_doc_module in ('LC','LCA') then
         L_module := 'LTCR';
      else
         L_module := I_doc_module;
      end if;

      if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                    'LABL',
                                    L_module,
                                    L_decode_module) = FALSE then
         return FALSE;
      end if;

      O_error_message := SQL_LIB.CREATE_MSG('NO_DOC_ID_TYPE_FOUND',
                                            L_decode_module,
                                            NULL,
                                            NULL);
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_DOC_ID',
                    'DOC, DOC_LINK',
                    'MODULE: '||I_doc_module ||
                    ', DOC_ID: ' || to_char(I_doc_id));
   close C_CHECK_DOC_ID;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALIDATE_TYPE;
--------------------------------------------------------------------------------------------------
FUNCTION REQ_DOCS_EXIST_ID( O_error_message IN OUT VARCHAR2,
                            O_exists        IN OUT BOOLEAN,
                            I_doc_id        IN     DOC.DOC_ID%TYPE)
   RETURN BOOLEAN IS

   L_exist VARCHAR2(1) := NULL;
   L_program   VARCHAR2(64)   := 'DOCUMENTS_SQL.REQ_DOCS_EXIST_ID';

   cursor C_EXIST is
      select 'x'
        from req_doc
       where doc_id = I_doc_id;

BEGIN
    SQL_LIB.SET_MARK('OPEN',
                     'C_EXIST',
                     'REQ_DOC',
                     'DOC_ID: ' || to_char(I_doc_id));
    open C_EXIST;
    SQL_LIB.SET_MARK('FETCH',
                     'C_EXIST',
                     'REQ_DOC',
                     'DOC_ID: ' || to_char(I_doc_id));
    fetch C_EXIST into L_exist;
    if C_EXIST%FOUND then
       O_exists := TRUE;
    else
       O_exists := FALSE;
    end if;
    SQL_LIB.SET_MARK('CLOSE',
                     'C_EXIST',
                     'REQ_DOC',
                     'DOC_ID: ' || to_char(I_doc_id));
    close C_EXIST;
    return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END REQ_DOCS_EXIST_ID;
--------------------------------------------------------------------------------------------------
FUNCTION REQ_DOCS_EXIST_MOD_KEY (O_error_message  IN OUT VARCHAR2,
                                 O_exists	   IN OUT BOOLEAN,
                                 I_module         IN     REQ_DOC.MODULE%TYPE,
                                 I_key_value_1    IN     REQ_DOC.KEY_VALUE_1%TYPE,
                                 I_key_value_2    IN     REQ_DOC.KEY_VALUE_2%TYPE,
                                 I_doc_id        IN     REQ_DOC.DOC_ID%TYPE)
	RETURN BOOLEAN IS

L_exists	  VARCHAR2(1);
L_program     VARCHAR2(64) := 'DOCUMENTS_SQL.REQ_DOCS_EXIST_MOD_KEY';

   cursor C_REQD_DOCS_EXIST is
      select 'x'
        from req_doc
       where module        = I_module
         and key_value_1   = I_key_value_1
         and ((key_value_2 = I_key_value_2) or
              (key_value_2 is NULL and I_key_value_2 is NULL))
         and doc_id        = NVL(I_doc_id, doc_id)
	 and ROWNUM	   = 1;
BEGIN

   if I_module is NOT NULL then
      if I_key_value_1 is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_VALUE',
                                                NULL,
                                                NULL,
                                                NULL);
         return FALSE;
      end if;
      if I_module in ('CTIT', 'POIT', 'PTNR') then
         if I_key_value_2 is NULL then
            O_error_message := SQL_LIB.CREATE_MSG('INV_VALUE',
                                                   NULL,
                                                   NULL,
                                                   NULL);
            return FALSE;
         end if;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_VALUE',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK ('OPEN',
                     'C_REQD_DOCS_EXIST',
                     'REQ_DOC',
                     'Module: ' || I_module ||
                     ', Key Value 1: '|| I_key_value_1 ||
                     ', Key Value 1: '|| I_key_value_2);
   open C_REQD_DOCS_EXIST;
   ---
   SQL_LIB.SET_MARK ('FETCH',
                     'C_REQD_DOCS_EXIST',
                     'REQ_DOC',
                     'Module: ' || I_module ||
                     ', Key Value 1: '|| I_key_value_1 ||
                     ', Key Value 2: '|| I_key_value_2);
   fetch C_REQD_DOCS_EXIST into L_exists;
   ---
   if C_REQD_DOCS_EXIST%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK ('CLOSE',
                     'C_REQD_DOCS_EXIST',
                     'REQ_DOC',
                     'Module: ' || I_module ||
                     ', Key Value 1: '|| I_key_value_1 ||
                     ', Key Value 2: '|| I_key_value_2);
   close C_REQD_DOCS_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;
END REQ_DOCS_EXIST_MOD_KEY;
---------------------------------------------------------------------------------------------
FUNCTION LOCK_REQ_DOCS   (O_error_message  IN OUT  VARCHAR2,
                          I_module         IN      REQ_DOC.MODULE%TYPE,
                          I_key_value_1    IN      REQ_DOC.KEY_VALUE_1%TYPE,
                          I_key_value_2    IN      REQ_DOC.KEY_VALUE_2%TYPE)
   RETURN BOOLEAN IS

   L_program        VARCHAR2(40) := 'DOCUMENTS_SQL.LOCK_REQ_DOCS';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_locked, -54);

   cursor C_LOCK_REQ_DOCS is
      select 'Y'
        from req_doc
       where module        = I_module
         and key_value_1   = I_key_value_1
         and ((key_value_2 = I_key_value_2)
              or (I_key_value_2 is NULL))
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_REQ_DOCS', 'REQ_DOC',
                    'Module: ' || I_module ||
                    ', Key Value 1: ' || I_key_value_1 ||
                    ', Key Value 2: ' || I_key_value_2);
   open C_LOCK_REQ_DOCS;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_REQ_DOCS', 'REQ_DOC',
                    'Module: ' || I_module ||
                    ', Key Value 1: ' || I_key_value_1 ||
                    ', Key Value 2: ' || I_key_value_2);
   close C_LOCK_REQ_DOCS;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED', 'REQ_DOC', I_module,
 I_key_value_1);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program,
 to_char(SQLCODE));
      return FALSE;

END LOCK_REQ_DOCS;
--------------------------------------------------------------------------------
----------
FUNCTION DELETE_REQ_DOCS (O_error_message  IN OUT  VARCHAR2,
                          I_module         IN      REQ_DOC.MODULE%TYPE,
                          I_key_value_1    IN      REQ_DOC.KEY_VALUE_1%TYPE,
                          I_key_value_2    IN      REQ_DOC.KEY_VALUE_2%TYPE)
   RETURN BOOLEAN IS

   L_program        VARCHAR2(40) := 'DOCUMENTS_SQL.DELETE_REQ_DOCS';

BEGIN
   SQL_LIB.SET_MARK('DELETE', NULL, 'REQ_DOC', 'Module: ' || I_module ||
                                               ', Key Value 1: ' ||
                                                  I_key_value_1 ||
                                               ', Key Value 2: ' ||
                                                  I_key_value_2);
   delete from req_doc
          where module        = I_module
            and key_value_1   = I_key_value_1
            and ((key_value_2 = I_key_value_2) or
                 (I_key_value_2 is NULL));

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program,
 to_char(SQLCODE));
      return FALSE;

END DELETE_REQ_DOCS;
--------------------------------------------------------------------------------
FUNCTION GET_DEFAULTS( O_error_message      IN OUT  VARCHAR2,
                       I_from_module        IN      REQ_DOC.MODULE%TYPE,
                       I_to_module          IN      REQ_DOC.MODULE%TYPE,
                       I_from_key_value_1   IN      REQ_DOC.KEY_VALUE_1%TYPE,
                       I_to_key_value_1     IN      REQ_DOC.KEY_VALUE_1%TYPE,
                       I_from_key_value_2   IN      REQ_DOC.KEY_VALUE_2%TYPE,
                       I_to_key_value_2     IN      REQ_DOC.KEY_VALUE_2%TYPE)
	RETURN BOOLEAN IS

   L_req_doc_no    REQ_DOC.DOC_KEY%TYPE;
   L_program       VARCHAR2(64)           := 'DOCUMENTS_SQL.GET_DEFAULTS';
   L_exists        BOOLEAN;
   ---
   cursor C_INSERT_REQ_DOC is
      select rd.doc_id,
             rd.doc_text
        from req_doc rd,
             doc d,
             doc_link dl
       where rd.module     = I_from_module
         and key_value_1   = I_from_key_value_1
         and ((key_value_2 = I_from_key_value_2)
         or (key_value_2 is NULL and I_from_key_value_2 is NULL))
         and rd.doc_id     = d.doc_id
         and d.doc_type    = dl.doc_type
         and dl.module     = I_to_module
         and ((I_to_module in ('LC', 'LCA')
              and d.lc_ind = 'Y')
              or I_to_module not in ('LC', 'LCA'));

BEGIN

   FOR L_rec in C_INSERT_REQ_DOC LOOP

      if DOCUMENTS_SQL.REQ_DOCS_EXIST_MOD_KEY(O_error_message,
                                              L_exists,
                                              I_to_module,
                                              I_to_key_value_1,
                                              I_to_key_value_2,
                                              L_rec.doc_id) = FALSE then
         return FALSE;
      end if;
      if L_exists = FALSE then
          ---
          if DOCUMENTS_SQL.NEXT_REQ_DOC_KEY(O_error_message,
                                           L_req_doc_no) = FALSE then
            return FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('INSERT', NULL, 'REQ_DOC', 'doc_key: '||to_char(L_req_doc_no));
         ---
         insert into req_doc
                (doc_key,
                 module,
                 key_value_1,
                 key_value_2,
                 doc_id,
                 doc_text)
         values(L_req_doc_no,
                I_to_module,
                I_to_key_value_1,
                I_to_key_value_2,
                L_rec.doc_id,
                L_rec.doc_text);
      end if;

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END GET_DEFAULTS;
--------------------------------------------------------------------------------------
FUNCTION INSERT_REQ_DOC(O_error_message  IN OUT  VARCHAR2,
                        I_module         IN      REQ_DOC.MODULE%TYPE,
                        I_key_value_1    IN      REQ_DOC.KEY_VALUE_1%TYPE,
                        I_key_value_2    IN      REQ_DOC.KEY_VALUE_2%TYPE,
                        I_doc_id         IN      REQ_DOC.DOC_ID%TYPE,
                        I_doc_text       IN      REQ_DOC.DOC_TEXT%TYPE)
RETURN BOOLEAN IS
   L_program  VARCHAR2(50) := 'DOCUMENTS_SQL.INSERT_REQ_DOC';
   L_doc_key  REQ_DOC.DOC_KEY%TYPE;

BEGIN
   if I_module      is NULL or
      I_key_value_1 is NULL or
      I_doc_id      is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',NULL,NULL,NULL);
      return FALSE;
   end if;

   if DOCUMENTS_SQL.NEXT_REQ_DOC_KEY(O_error_message,
                                     L_doc_key) = FALSE then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('INSERT',NULL,'REQ_DOC',NULL);
   insert into req_doc(doc_key,
                       module,
                       key_value_1,
                       key_value_2,
                       doc_id,
                       doc_text)
                values(L_doc_key,
                       I_module,
                       I_key_value_1,
                       I_key_value_2,
                       I_doc_id,
                       I_doc_text);

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END INSERT_REQ_DOC;
-------------------------------------------------------------------------------------------
FUNCTION NEXT_MISSING_DOC_KEY(O_error_message     IN OUT  VARCHAR2,
                              O_missing_doc_key   IN OUT  MISSING_DOC.MISSING_DOC_KEY%TYPE)
   return   BOOLEAN  IS

   L_first_time   VARCHAR2(3)            	            := 'YES';
   L_wrap_doc_key MISSING_DOC.MISSING_DOC_KEY%TYPE    := 0;
   L_program      VARCHAR2(64)              	      := 'DOCUMENTS_SQL.NEXT_MISSING_DOC_KEY';
   L_exists       VARCHAR2(1)                         := NULL;

   cursor C_EXIST_MISSING_DOC is
      select 'X'
        from missing_doc
       where missing_doc_key = O_missing_doc_key;

   cursor C_SEQUENCE_NEXTVAL is
      select missing_doc_sequence.NEXTVAL
        from dual;

BEGIN
   LOOP
      SQL_LIB.SET_MARK('OPEN',
                       'C_SEQUENCE_NEXTVAL',
                       'DUAL',
                        NULL);
      open C_SEQUENCE_NEXTVAL;
      SQL_LIB.SET_MARK('FETCH',
                       'C_SEQUENCE_NEXTVAL',
                       'DUAL',
                        NULL);
      fetch C_SEQUENCE_NEXTVAL into O_missing_doc_key;
      if (L_first_time = 'YES') then
         L_wrap_doc_key := O_missing_doc_key;
         L_first_time  := 'NO';
      elsif L_wrap_doc_key = O_missing_doc_key then
         O_error_message := SQL_LIB.CREATE_MSG('NO_SEQ_NO_AVAIL',
                                                NULL,
                                                NULL,
                                                NULL);
         SQL_LIB.SET_MARK('CLOSE',
                          'C_SEQUENCE_NEXTVAL',
                          'DUAL',
                           NULL);
         close C_SEQUENCE_NEXTVAL;
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SEQUENCE_NEXTVAL',
                       'DUAL',
                        NULL);
      close C_SEQUENCE_NEXTVAL;

      SQL_LIB.SET_MARK('OPEN',
                       'C_EXIST_MISSING_DOC',
                       'MISSING_DOC',
                       'DOC KEY: '|| to_char(O_missing_doc_key));
      open C_EXIST_MISSING_DOC;
      SQL_LIB.SET_MARK('FETCH',
                       'C_EXIST_MISSING_DOC',
                       'MISSING_DOC',
                       'DOC KEY: '|| to_char(O_missing_doc_key));
      fetch C_EXIST_MISSING_DOC into L_exists;
      if  C_EXIST_MISSING_DOC%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EXIST_MISSING_DOC',
                          'MISSING_DOC',
                          'DOC KEY: '|| to_char(O_missing_doc_key));
         close C_EXIST_MISSING_DOC;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_EXIST_MISSING_DOC',
                       'MISSING_DOC',
                       'DOC KEY: '|| to_char(O_missing_doc_key));
      close C_EXIST_MISSING_DOC;
   END LOOP;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END NEXT_MISSING_DOC_KEY;
-------------------------------------------------------------------------------------------------
FUNCTION MISSING_DOCS_EXIST_ID(O_error_message         IN OUT  VARCHAR2,
                               O_exists                IN OUT  BOOLEAN,
                               I_doc_id                IN      MISSING_DOC.DOC_ID%TYPE,
      				 I_transportation_id     IN      MISSING_DOC.TRANSPORTATION_ID%TYPE,
 					 I_ce_id                 IN      MISSING_DOC.CE_ID%TYPE,
	    				 I_vessel_id             IN      MISSING_DOC.VESSEL_ID%TYPE,
 					 I_voyage_flt_id         IN      MISSING_DOC.VOYAGE_FLT_ID%TYPE,
				 	 I_estimated_depart_date IN      MISSING_DOC.ESTIMATED_DEPART_DATE%TYPE,
					 I_order_no              IN      MISSING_DOC.ORDER_NO%TYPE,
					 I_item                  IN      MISSING_DOC.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_exist VARCHAR2(1) := NULL;
   L_program   VARCHAR2(64)   := 'DOCUMENTS_SQL.MISSING_DOCS_EXIST_ID';

   cursor C_EXIST_TRAN is
      select 'x'
        from missing_doc
       where transportation_id = I_transportation_id
         and doc_id		 = nvl(I_doc_id, doc_id);

   cursor C_EXIST_CE is
      select 'x'
        from missing_doc
       where doc_id			= nvl(I_doc_id, doc_id)
         and ce_id 			= I_ce_id
         and vessel_id			= I_vessel_id
         and voyage_flt_id 		= I_voyage_flt_id
         and estimated_depart_date  = I_estimated_depart_date
         and order_no			= I_order_no
         and item				= I_item;
BEGIN
   if I_transportation_id is not NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_EXIST_TRAN',
                       'MISSING_DOC',
                       'transportation_id : ' || to_char(I_transportation_id));
      open C_EXIST_TRAN;
      SQL_LIB.SET_MARK('FETCH',
                       'C_EXIST_TRAN',
                       'MISSING_DOC',
                       'transportation_id : ' || to_char(I_transportation_id));
      fetch C_EXIST_TRAN into L_exist;
         if C_EXIST_TRAN%FOUND then
            O_exists := TRUE;
            O_error_message := SQL_LIB.CREATE_MSG('MISSING_DOC_EXIST_TRAN',
                                                  to_char(I_doc_id),
                                                  NULL,
                                                  NULL);
         else
            O_exists := FALSE;
         end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_EXIST_TRAN',
                       'MISSING_DOC',
                       'transportation_id : ' || to_char(I_transportation_id));
      close C_EXIST_TRAN;
   elsif I_ce_id is not NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_EXIST_CE',
                       'MISSING_DOC',
                       'ce_id : ' || to_char(I_ce_id));
      open C_EXIST_CE;
      SQL_LIB.SET_MARK('FETCH',
                       'C_EXIST_CE',
                       'MISSING_DOC',
                       'ce_id : ' || to_char(I_ce_id));
      fetch C_EXIST_CE into L_exist;
         if C_EXIST_CE%FOUND then
            O_exists := TRUE;
            O_error_message := SQL_LIB.CREATE_MSG('MISSING_DOC_EXIST_CE',
                                                  to_char(I_doc_id),
                                                  NULL,
                                                  NULL);
         else
            O_exists := FALSE;
         end if;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_EXIST_CE',
                       'MISSING_DOC',
                       'ce_id : ' || to_char(I_ce_id));
      close C_EXIST_CE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END MISSING_DOCS_EXIST_ID;
------------------------------------------------------------------------------------------------
FUNCTION GET_LC_IND( O_error_message IN OUT VARCHAR2,
                     O_lc_ind        IN OUT DOC.LC_IND%TYPE,
		             I_doc_id        IN     DOC.DOC_ID%TYPE)
   RETURN BOOLEAN IS

    L_program		VARCHAR2(64) := 'DOCUMENT_SQL.VALIDATE_TYPE';

   cursor C_LC_IND is
      select lc_ind
        from doc
       where doc_id = I_doc_id;

BEGIN
   open C_LC_IND;
   fetch C_LC_IND into O_lc_ind;
   if C_LC_IND%NOTFOUND then
      O_error_message := 'INVALID_DOCUMENT';
      close C_LC_IND;
      return FALSE;
   end if;
   close C_LC_IND;
   return TRUE;

EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
     return FALSE;
END GET_LC_IND;
-------------------------------------------------------------------------------
FUNCTION COPY_DOWN_PARENT_REQ_DOC (O_error_message  IN OUT VARCHAR2,
                                   I_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(65) := 'DOCUMENTS_SQL.COPY_DOWN_PARENT_REQ_DOC';
   L_table         VARCHAR2(65) := 'REQ_DOC';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   L_doc_key        REQ_DOC.DOC_KEY%TYPE;
   L_module         REQ_DOC.MODULE%TYPE;
   L_key_value_1    REQ_DOC.KEY_VALUE_1%TYPE;
   L_key_value_2    REQ_DOC.KEY_VALUE_2%TYPE;
   L_doc_id         REQ_DOC.DOC_ID%TYPE;
   L_doc_text       REQ_DOC.DOC_TEXT%TYPE;
   L_dummy          VARCHAR2(1);

   cursor C_LOCK_REQ_DOC is
      select 'x'
        from req_doc
       where key_value_1 in (select item
                               from item_master
                              where (item_parent = I_item
                                 or item_grandparent = I_item)
                                and item_level <= tran_level)
         and module = 'IT'
         for update nowait;

   cursor C_INSERT_REQ_DOC is
      select r.module,
             im.item,
             r.key_value_2,
             r.doc_id,
             r.doc_text
        from req_doc r,
             item_master im
       where r.key_value_1 = I_item
         and (item_parent = r.key_value_1
          or im.item_grandparent = r.key_value_1)
         and im.item_level <= im.tran_level
         and r.module = 'IT';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_REQ_DOC',
                    'REQ_DOC', 'Item: ' || I_item);
   OPEN  C_LOCK_REQ_DOC;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_REQ_DOC',
                    'REQ_DOC', 'Item: ' || I_item);
   CLOSE C_LOCK_REQ_DOC;

   SQL_LIB.SET_MARK('DELETE', NULL, 'REQ_DOC',
                    'Item: ' || I_item);

   delete req_doc
    where key_value_1 in (select item
                            from item_master
                           where (item_parent = I_item
                              or item_grandparent = I_item)
                             and item_level <= tran_level)
      and module = 'IT';
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_INSERT_REQ_DOC',
                    'REQ_DOC', 'Item: ' || I_item);
   OPEN C_INSERT_REQ_DOC;
   LOOP
      if DOCUMENTS_SQL.NEXT_REQ_DOC_KEY(O_error_message,
                                        L_doc_key) = FALSE then
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('FETCH','C_INSERT_REQ_DOC',
                       'REQ_DOC', 'Item: '||I_item);
      fetch C_INSERT_REQ_DOC into L_module,
                                  L_key_value_1,
                                  L_key_value_2,
                                  L_doc_id,
                                  L_doc_text;
      EXIT WHEN C_INSERT_REQ_DOC%NOTFOUND;
      SQL_LIB.SET_MARK('INSERT', NULL, 'REQ_DOC',
                       'Item: ' || L_key_value_1);
      insert into req_doc(doc_key,
                          module,
                          key_value_1,
                          key_value_2,
                          doc_id,
                          doc_text)
         values(L_doc_key,
                L_module,
                L_key_value_1,
                L_key_value_2,
                L_doc_id,
                L_doc_text);
   END LOOP;
   SQL_LIB.SET_MARK('CLOSE', 'C_INSERT_REQ_DOC',
                    'REQ_DOC', 'Item: ' || I_item);
   CLOSE C_INSERT_REQ_DOC;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                           L_table,
                                           I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END COPY_DOWN_PARENT_REQ_DOC;
------------------------------------------------------------------------------------
-- 21-Jun-2007 Govindarajan - MOD 365b1 Begin
------------------------------------------------------------------------------------
-- Function Name: TSL_COPY_BASE_REQ_DOC
-- Purpose    : This function will default identical required document records
--              to the Variants Items for the inputted Base Item.
------------------------------------------------------------------------------------
FUNCTION TSL_COPY_BASE_REQ_DOC (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_table          VARCHAR2(65) := 'REQ_DOC';
   L_program        VARCHAR2(300) := 'DOCUMENTS_SQL.TSL_COPY_BASE_REQ_DOC';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);
   O_doc_key        REQ_DOC.DOC_KEY%TYPE;
   L_dummy          VARCHAR2(1);
   L_Valid_doc_key  BOOLEAN;

   -- This cursor will lock the variant information
   -- on the table REQ_DOC table
   cursor C_LOCK_REQ_DOC is
      select 'x'
        from req_doc rd
       where rd.module = 'IT'
         and rd.key_value_1 in (select im.item
                                  from item_master im
                                 where im.tsl_base_item = I_item
                                   and im.tsl_base_item      != im.item
                                   and im.item_level          = im.tran_level
                                   and im.item_level          = 2)
         for update nowait;

   -- This cursor will return the Required Documents info
   -- for all the Variants items associated to the selected Base Item
   cursor C_INSERT_REQ_DOC is
      select rd.module module,
             im.item key_value_1,
             rd.key_value_2 key_value_2,
             rd.doc_id doc_id,
             rd.doc_text doc_text
        from req_doc rd,
             item_master im
       where rd.key_value_1     = I_item
         and rd.module          = 'IT'
         and rd.key_value_1     = NVL(im.tsl_base_item, im.item)
         and im.item_level      = im.tran_level
         and im.tsl_base_item  != im.item
         and im.item_level      = 2
         for update nowait;

BEGIN
      if I_item is NULL then           -- L1 begin
        -- If input item is null then throws an error
        O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                              I_item,
                                              L_program,
                                              NULL);
        return FALSE;
      else                -- L1 else
        -- Opening and closing the C_LOCK_REQ_DOC cursor
        SQL_LIB.SET_MARK('OPEN',
                         'C_LOCK_REQ_DOC',
                         L_table,
                         'ITEM: '||I_item);
        open C_LOCK_REQ_DOC;

        SQL_LIB.SET_MARK('CLOSE',
                         'C_LOCK_REQ_DOC',
                         L_table,
                         'ITEM: '||I_item);
        close C_LOCK_REQ_DOC;

        -- Deleting the records from REQ_DOC table
        SQL_LIB.SET_MARK('DELETE',
                         NULL,
                         L_table,
                         'ITEM: '||I_item);

        delete from req_doc
         where key_value_1 in (select im.item
                                 from item_master im
                                where im.tsl_base_item  = I_item
                                  and im.tsl_base_item != im.item
                                  and im.item_level     = im.tran_level
                                  and im.item_level     = 2)
           and module = 'IT';

        -- Opening the cursor C_INSERT_REQ_DOC
        SQL_LIB.SET_MARK('OPEN',
                         'C_INSERT_REQ_DOC',
                         L_table,
                         'ITEM: '||I_item);
        FOR C_rec in C_INSERT_REQ_DOC
        LOOP                           -- L2 begin
              -- getting the doc_key by calling DOCUMNETS_SQL.NEXT_REQ_DOC_KEY function
              L_Valid_doc_key := DOCUMENTS_SQL.NEXT_REQ_DOC_KEY (O_error_message,
                                                                 O_doc_key);
              if L_Valid_doc_key = TRUE then    -- L3 begin
                  -- Insert into the REQ_DOC table
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   L_table,
                                   'ITEM: '||I_item);

                  insert into req_doc
                              (doc_key,
                              module,
                              key_value_1,
                              key_value_2,
                              doc_id,
                              doc_text)
                       values (O_doc_key,
                              C_rec.module,
                              C_rec.key_value_1,
                              C_rec.key_value_2,
                              C_rec.doc_id,
                              C_rec.doc_text);
              else                         -- L3 else
                  return FALSE;
              end if;             -- L3 end
        END LOOP;       -- L2 end
        return TRUE;
      end if;             -- L1 end
EXCEPTION
   -- Raising an exception for record lock error
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_program,
                                            'ITEM: '||I_item);
      return FALSE;

   -- Raising an exception for others
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END TSL_COPY_BASE_REQ_DOC;
------------------------------------------------------------------------------------
-- 21-Jun-2007 Govindarajan - MOD 365b1 End
------------------------------------------------------------------------------------
END DOCUMENTS_SQL;
/

