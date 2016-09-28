CREATE OR REPLACE PACKAGE BODY APPOINTMENTS_SQL AS
--------------------------------------------------------
FUNCTION VALIDATE_APPOINTMENT(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exists          IN OUT   BOOLEAN,
                              I_appt            IN       APPT_HEAD.APPT%TYPE)
   RETURN BOOLEAN is

   L_program     VARCHAR2(64) := 'APPOINTMENTS_SQL.VALIDATE_APPOINTMENT';
   L_exists      VARCHAR2(1);

   cursor C_VALIDATE_APPT is
      select 'x'
        from appt_head
       where appt = I_appt;

   cursor C_VALIDATE_APPT_V is
       select 'x'
        from appt_detail ad, v_item_master vim
       where ad.appt = I_appt
         and vim.item = ad.item;

BEGIN
   if I_appt is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_appt', L_program, NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_VALIDATE_APPT_V', 'APPT_DETAIL'||'V_ITEM_MASTER', 'appt = '||to_char(I_appt));
   open C_VALIDATE_APPT_V;

   SQL_LIB.SET_MARK('FETCH', 'C_VALIDATE_APPT_V', 'APPT_DETAIL'||'V_ITEM_MASTER', 'appt = '||to_char(I_appt));
   fetch C_VALIDATE_APPT_V into L_exists;

   SQL_LIB.SET_MARK('CLOSE', 'C_VALIDATE_APPT_V', 'APPT_DETAIL'||'V_ITEM_MASTER', 'appt = '||to_char(I_appt));
   close C_VALIDATE_APPT_V;

   if L_exists is NULL then
      SQL_LIB.SET_MARK('OPEN', 'C_VALIDATE_APPT', 'APPT_HEAD', 'appt = '||to_char(I_appt));
      open C_VALIDATE_APPT;

      SQL_LIB.SET_MARK('FETCH', 'C_VALIDATE_APPT', 'APPT_HEAD', 'appt = '||to_char(I_appt));
      fetch C_VALIDATE_APPT into L_exists;

      SQL_LIB.SET_MARK('CLOSE', 'C_VALIDATE_APPT', 'APPT_HEAD', 'appt = '||to_char(I_appt));
      close C_VALIDATE_APPT;
      if L_exists is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('NO_APPT', NULL, NULL, NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_VIS_HIER', 'APPT', I_appt, NULL);
      end if;
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            to_char(SQLCODE),
                                            L_program);
      return FALSE;

END VALIDATE_APPOINTMENT;
-------------------------------------------------------------
FUNCTION VALIDATE_DOC(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      O_exists          IN OUT   BOOLEAN,
                      I_doc             IN       APPT_DETAIL.DOC%TYPE,
                      I_doc_type        IN       APPT_DETAIL.DOC_TYPE%TYPE)
   RETURN BOOLEAN is

   L_program   VARCHAR2(64) := 'APPOINTMENTS_SQL.VALIDATE_DOC';
   L_exists    VARCHAR2(1);

   cursor C_VALIDATE_DOC is
      select 'x'
        from appt_detail
       where doc = I_doc
         and doc_type    = I_doc_type;

BEGIN
   if I_doc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_doc', L_program, NULL);
      return FALSE;
   elsif I_doc_type not in ('P', 'T', 'A')
    or I_doc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_DOC_TYPE', NULL, NULL, NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_VALIDATE_DOC', 'appt_detail', 'doc = '||to_char(I_doc)||
                                                             ', doc_type = '||I_doc_type);
   open C_VALIDATE_DOC;
   SQL_LIB.SET_MARK('FETCH', 'C_VALIDATE_DOC', 'appt_detail', 'doc = '||to_char(I_doc)||
                                                              ', doc_type = '||I_doc_type);
   fetch C_VALIDATE_DOC into L_exists;
   if C_VALIDATE_DOC%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_VALIDATE_DOC', 'appt_detail', 'doc = '||to_char(I_doc)||
                                                              ', doc_type = '||I_doc_type);
   close C_VALIDATE_DOC;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            to_char(SQLCODE),
                                            L_program);
      return FALSE;
END VALIDATE_DOC;
-----------------------------------------------------------------------------------------------
FUNCTION VALIDATE_LOC(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      O_exists          IN OUT   BOOLEAN,
                      I_loc             IN       APPT_HEAD.LOC%TYPE,
                      I_loc_type        IN       APPT_HEAD.LOC_TYPE%TYPE)
   RETURN BOOLEAN is

   L_program   VARCHAR2(64) := 'APPOINTMENTS_SQL.VALIDATE_LOC';
   L_exists    VARCHAR2(1);

   cursor C_VALIDATE_LOC is
      select 'x'
        from appt_head
       where loc      = I_loc
         and loc_type = I_loc_type;

BEGIN
   if I_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_loc', L_program, NULL);
      return FALSE;
   elsif I_loc_type not in ('S', 'W', 'E')
    or I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_LOC_TYPE', NULL, NULL, NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_VALIDATE_LOC', 'appt_head', 'loc = '||to_char(I_loc)||
                                                             ', loc_type = '||I_loc_type);
   open C_VALIDATE_LOC;
   SQL_LIB.SET_MARK('FETCH', 'C_VALIDATE_LOC', 'appt_head', 'loc = '||to_char(I_loc)||
                                                             ', loc_type = '||I_loc_type);
   fetch C_VALIDATE_LOC into L_exists;
   if C_VALIDATE_LOC%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_VALIDATE_LOC', 'appt_head', 'loc = '||to_char(I_loc)||
                                                             ', loc_type = '||I_loc_type);
   close C_VALIDATE_LOC;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            to_char(SQLCODE),
                                            L_program);
      return FALSE;
END VALIDATE_LOC;
-----------------------------------------------------------------------------------------------
FUNCTION VALIDATE_ASN(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                      O_exists          IN OUT BOOLEAN,
                      I_asn             IN     SHIPMENT.ASN%TYPE)
   RETURN BOOLEAN is

   L_program     VARCHAR2(64) := 'APPOINTMENTS_SQL.VALIDATE_ASN';
   L_exists      VARCHAR2(1);

   cursor C_VALIDATE_ASN is
      select 'x'
        from appt_detail
       where asn = I_asn;

BEGIN
   if I_asn is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_asn', L_program, NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_VALIDATE_ASN', 'appt_detail', 'asn = '||I_asn);
   open C_VALIDATE_ASN;
   SQL_LIB.SET_MARK('FETCH', 'C_VALIDATE_ASN', 'appt_detail','asn = '||I_asn);
   fetch C_VALIDATE_ASN into L_exists;
   if C_VALIDATE_ASN%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_VALIDATE_ASN', 'appt_detail','asn = '||I_asn);
   close C_VALIDATE_ASN;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            to_char(SQLCODE),
                                            L_program);
      return FALSE;

END VALIDATE_ASN;
-----------------------------------------------------------------------------------------------
FUNCTION OPEN_APPOINTMENTS(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_exists          IN OUT BOOLEAN,
                           I_doc             IN     APPT_DETAIL.DOC%TYPE,
                           I_doc_type        IN     APPT_DETAIL.DOC_TYPE%TYPE)
   RETURN BOOLEAN is

   L_program     VARCHAR2(64) := 'APPOINTMENTS_SQL.OPEN_APPOINTMENTS';
   L_exists      VARCHAR2(1);

   cursor C_open_appt is
      select 'x'
        from appt_head ah, appt_detail ad
       where ad.doc      = I_doc
         and ad.doc_type = I_doc_type
         and ad.appt     = ah.appt
         and ad.loc      = ah.loc
         and ad.loc_type = ah.loc_type
         and ah.status   != 'AC';
BEGIN
   if I_doc is NULL
    or I_doc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_doc', L_program, NULL);
      return FALSE;
   elsif I_doc_type not in ('P', 'T', 'A') then
      O_error_message := SQL_LIB.CREATE_MSG('INV_DOC_TYPE', NULL, NULL, NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_OPEN_APPT', 'appt_head, appt_detail', 'doc = '||to_char(I_doc)||
                                                                     ', doc_type = '||I_doc_type);
   open C_open_appt;
   SQL_LIB.SET_MARK('FETCH', 'C_OPEN_APPT', 'appt_head, appt_detail', 'doc = '||to_char(I_doc)||
                                                                      ', doc_type = '||I_doc_type);
   fetch C_open_appt into L_exists;
   if C_open_appt%FOUND then
      O_exists := TRUE;
   else --All Appointments are closed for this PO/Transfer/Alloc
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_OPEN_APPT', 'appt_head, appt_detail', 'doc = '||to_char(I_doc)||
                                                                      ', doc_type = '||I_doc_type);
   close C_open_appt;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            to_char(SQLCODE),
                                            L_program);
END OPEN_APPOINTMENTS;
-----------------------------------------------------------------------------------------------------
END;
/

