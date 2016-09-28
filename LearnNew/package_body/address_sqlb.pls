CREATE OR REPLACE PACKAGE BODY ADDRESS_SQL AS
-------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message          IN OUT VARCHAR2,
                  O_module                 IN OUT ADDR.MODULE%TYPE,
                  O_key_value_1            IN OUT ADDR.KEY_VALUE_1%TYPE,
                  O_key_value_2            IN OUT ADDR.KEY_VALUE_2%TYPE,
                  O_addr_type              IN OUT ADDR.ADDR_TYPE%TYPE,
                  O_primary_addr_ind       IN OUT ADDR.PRIMARY_ADDR_IND%TYPE,
                  O_add_1                  IN OUT ADDR.ADD_1%TYPE,
                  O_add_2                  IN OUT ADDR.ADD_2%TYPE,
                  O_add_3                  IN OUT ADDR.ADD_3%TYPE,
                  O_city                   IN OUT ADDR.CITY%TYPE,
                  O_state                  IN OUT ADDR.STATE%TYPE,
                  O_country_id             IN OUT ADDR.COUNTRY_ID%TYPE,
                  O_post                   IN OUT ADDR.POST%TYPE,
                  O_contact_name           IN OUT ADDR.CONTACT_NAME%TYPE,
                  O_contact_phone          IN OUT ADDR.CONTACT_PHONE%TYPE,
                  O_contact_telex          IN OUT ADDR.CONTACT_TELEX%TYPE,
                  O_contact_fax            IN OUT ADDR.CONTACT_FAX%TYPE,
                  O_contact_email          IN OUT ADDR.CONTACT_EMAIL%TYPE,
                  O_oracle_vendor_site_id  IN OUT ADDR.ORACLE_VENDOR_SITE_ID%TYPE,
                  I_add_key                IN     ADDR.ADDR_KEY%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'ADDR_SQL.GET_INFO';

   cursor C_GET_INFO is
      select module,
             key_value_1,
             key_value_2,
             addr_type,
             primary_addr_ind,
             add_1,
             add_2,
             add_3,
             city,
             state,
             country_id,
             post,
             contact_name,
             contact_phone,
             contact_telex,
             contact_fax,
             contact_email,
             oracle_vendor_site_id
        from addr
       where addr.addr_key = I_add_key;

BEGIN


   open C_GET_INFO;

   fetch C_GET_INFO into O_module,
                         O_key_value_1,
                         O_key_value_2,
                         O_addr_type,
                         O_primary_addr_ind,
                         O_add_1,
                         O_add_2,
                         O_add_3,
                         O_city,
                         O_state,
                         O_country_id,
                         O_post,
                         O_contact_name,
                         O_contact_phone,
                         O_contact_telex,
                         O_contact_fax,
                         O_contact_email,
                         O_oracle_vendor_site_id;
   if C_GET_INFO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ADD_KEY',
                                           NULL,
                                           NULL,
                                           NULL);

      close C_GET_INFO;
      return FALSE;
   end if;
   ---

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
-----------------------------------------------------------------------------------
FUNCTION VALID_INVC_ADDR(O_error_message          IN OUT VARCHAR2,
                         O_exists                 IN OUT BOOLEAN,
                         I_supplier               IN     SUPS.SUPPLIER%TYPE,
                         I_partner_id             IN     PARTNER.PARTNER_ID%TYPE,
                         I_partner_type           IN     PARTNER.PARTNER_TYPE%TYPE)
   RETURN BOOLEAN IS
   L_exists     varchar2(1) := 'N';
   L_program             VARCHAR2(50):= 'ADDRESS_SQL.VALID_INVC_ADDR';

   cursor C_SUPP_INVC_ADDR is
       select 'Y'
         from addr
        where key_value_1 = to_char(I_supplier)
          and module = 'SUPP'
          and addr_type = '05';
   cursor C_PART_INVC_ADDR is
          select 'Y'
            from addr
           where (key_value_1 = I_partner_type
          and key_value_2 = I_partner_id)
          and module = 'PTNR'
          and addr_type = '05';

BEGIN
   if I_supplier is NULL AND I_partner_id is NULL then
       O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                             'I_supplier',
                                             'I_partner_id',
                                             'NOT NULL');
      return FALSE;
   end if;
   if I_partner_type is NULL and I_partner_id is not NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_partner_type',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is not null then
      open C_SUPP_INVC_ADDR;

      fetch C_SUPP_INVC_ADDR into L_exists;
         if L_exists = 'Y' then
            O_exists := TRUE;
         else
            O_exists := FALSE;
         end if;
      close C_SUPP_INVC_ADDR;
   else
      open C_PART_INVC_ADDR;
      fetch C_PART_INVC_ADDR into L_exists;
         if L_exists = 'Y' then
            O_exists := TRUE;
         else
            O_exists := FALSE;
         end if;
      close C_PART_INVC_ADDR;
   end if;
  ---
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END VALID_INVC_ADDR;
------------------------------------------------------------------------------------
FUNCTION VALID_ORD_ADDR(O_error_message          IN OUT VARCHAR2,
                        O_exists                 IN OUT BOOLEAN,
                        I_supplier               IN     SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS
   L_exists              VARCHAR2(1) := NULL;
   L_program             VARCHAR2(50):= 'ADDRESS_SQL.VALID_ORD_ADDR';

   cursor C_SUPP_ORD_ADDR is
       select 'x'
         from addr
        where key_value_1 = to_char(I_supplier)
          and module = 'SUPP'
          and addr_type = '04';
BEGIN
   if I_supplier is NULL then
       O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                             'I_supplier',
                                             NULL,
                                             'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is not null then
      open C_SUPP_ORD_ADDR;
      fetch C_SUPP_ORD_ADDR into L_exists;
      if C_SUPP_ORD_ADDR%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      close C_SUPP_ORD_ADDR;
    end if;
  ---
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END VALID_ORD_ADDR;
------------------------------------------------------------------------------------
FUNCTION PREV_EXISTS(O_error_message       IN OUT VARCHAR2,
                     O_exists              IN OUT BOOLEAN,
                     I_key_value_1         IN     ADDR.KEY_VALUE_1%TYPE,
                     I_key_value_2         IN     ADDR.KEY_VALUE_2%TYPE,
                     I_addr_type           IN     ADDR.ADDR_TYPE%TYPE,
                     I_seq_no              IN     ADDR.SEQ_NO%TYPE)

   RETURN BOOLEAN IS

   L_dummy               VARCHAR2(1) := NULL;
   L_program             VARCHAR2(50):= 'ADDRESS_SQL.PREV_EXISTS';

   cursor C_CHECK_PREV is
      select 'x'
        from addr
       where key_value_1      = I_key_value_1
         and (key_value_2     = I_key_value_2
          or I_key_value_2 is NULL)
         and addr_type        = I_addr_type
         and seq_no           < I_seq_no;

BEGIN

   if I_key_value_1 is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_key_value_1',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_addr_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_addr_type',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_seq_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   open  C_CHECK_PREV;
   fetch C_CHECK_PREV into L_dummy;
   if C_CHECK_PREV%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   close C_CHECK_PREV;

  return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END PREV_EXISTS;
-----------------------------------------------------------------------------------
FUNCTION DELETE_ALLOWED(O_error_message       IN  OUT VARCHAR2,
                        O_allowed             IN  OUT BOOLEAN,
                        I_key_value_1         IN      ADDR.KEY_VALUE_1%TYPE,
                        I_key_value_2         IN      ADDR.KEY_VALUE_2%TYPE,
                        I_addr_type           IN      ADDR.ADDR_TYPE%TYPE,
                        I_seq_no              IN      ADDR.SEQ_NO%TYPE,
                        I_primary_addr_ind    IN      ADDR.PRIMARY_ADDR_IND%TYPE,
                        I_module              IN      ADDR.MODULE%TYPE,
                        I_mandatory          IN     ADD_TYPE_MODULE.MANDATORY_IND%TYPE
                        )
   RETURN BOOLEAN IS

   L_dummy               VARCHAR2(1) := NULL;
   L_program             VARCHAR2(50):= 'ADDRESS_SQL.DELETE_ALLOWED';

   cursor C_CHECK_MULTIPLE_EXISTS is
      select 'x'
        from addr
       where key_value_1      = I_key_value_1
         and (key_value_2     = I_key_value_2
          or I_key_value_2 is NULL)
         and addr_type        = I_addr_type
         AND module           = I_module
         and seq_no          != I_seq_no;

BEGIN

   if I_key_value_1 is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_key_value_1',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_addr_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_addr_type',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_seq_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   if I_module is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_module',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   if I_mandatory = 'N' then
      -- if address is a non-mandatory address type, it can be deleted regardless
      -- of whether it is the primary address for that address type
      O_allowed := TRUE;
   else
      open C_CHECK_MULTIPLE_EXISTS;
      fetch C_CHECK_MULTIPLE_EXISTS into L_dummy;

      if C_CHECK_MULTIPLE_EXISTS%FOUND and I_primary_addr_ind = 'Y' then
         -- can't delete primary address if multiple addresses exist for type
         O_allowed := FALSE;
      else
         O_allowed := TRUE;
      end if;
      close C_CHECK_MULTIPLE_EXISTS;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END DELETE_ALLOWED;
-----------------------------------------------------------------------------------

FUNCTION UPDATE_PRIM_ADD_IND(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_module           IN     ADDR.MODULE%TYPE,
                             I_key_value_1      IN     ADDR.KEY_VALUE_1%TYPE,
                             I_key_value_2      IN     ADDR.KEY_VALUE_2%TYPE,
                             I_addr_type        IN     ADDR.ADDR_TYPE%TYPE,
                             I_seq_no           IN     ADDR.SEQ_NO%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(50) := 'ADDRESS_SQL.UPDATE_PRIM_ADD_IND';
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   cursor C_LOCK_FORMER_PRIM_ADD is
      select 'x'
        from addr
       where module           = I_module
         and key_value_1      = I_key_value_1
         and (key_value_2     = I_key_value_2 or
             (key_value_2 is NULL and I_key_value_2 is NULL))
         and addr_type        = I_addr_type
         and primary_addr_ind = 'Y'
         and seq_no          != I_seq_no
         for update nowait;

BEGIN

   if I_key_value_1 is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_key_value_1',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   if I_module is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_module',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_addr_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_addr_type',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_seq_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   open C_LOCK_FORMER_PRIM_ADD;

   close C_LOCK_FORMER_PRIM_ADD;
   update addr
      set primary_addr_ind = 'N'
    where module           = I_module
      and key_value_1      = I_key_value_1
      and (key_value_2     = I_key_value_2 or
          (key_value_2 is NULL and I_key_value_2 is NULL))
      and addr_type        = I_addr_type
      and primary_addr_ind = 'Y'
      and seq_no          != I_seq_no;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED','ADDR',
                                            I_module);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_PRIM_ADD_IND;
-----------------------------------------------------------------------------------
FUNCTION GET_MAX_SEQ_NO(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_max_seq_no       IN OUT ADDR.SEQ_NO%TYPE,
                        I_module           IN     ADDR.MODULE%TYPE,
                        I_key_value_1      IN     ADDR.KEY_VALUE_1%TYPE,
                        I_key_value_2      IN     ADDR.KEY_VALUE_2%TYPE,
                        I_addr_type        IN     ADDR.ADDR_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'ADDRESS_SQL.GET_MAX_SEQ_NO';

   cursor C_MAX_SEQ_NO IS
      select NVL(MAX(SEQ_NO), 0)
        from addr
       where module       = I_module
         and key_value_1  = I_key_value_1
         and (key_value_2 = I_key_value_2 or
             (key_value_2 is NULL and I_key_value_2 is NULL))
         and addr_type    = I_addr_type;

BEGIN

   if I_key_value_1 is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_key_value_1',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_module is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_module',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_addr_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_addr_type',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   open C_MAX_SEQ_NO;
   fetch C_MAX_SEQ_NO into O_max_seq_no;
   close C_MAX_SEQ_NO;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END GET_MAX_SEQ_NO;
------------------------------------------------------------------------------------
FUNCTION GET_ADD_TYPE_MODULE_ROW(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_add_type_module  IN OUT ADD_TYPE_MODULE%ROWTYPE,
                                 I_module           IN     ADD_TYPE_MODULE.MODULE%TYPE,
                                 I_addr_type        IN     ADD_TYPE_MODULE.ADDRESS_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'ADDRESS_SQL.GET_ADD_TYPE_MODULE_ROW';

   cursor C_ADD_TYPE_ROW is
      select *
        from add_type_module
       where module       = I_module
         and address_type = I_addr_type
         and rownum       = 1;

BEGIN

   if I_addr_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_addr_type',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_module is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_module',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   O_add_type_module := NULL;

   open C_ADD_TYPE_ROW;

   fetch C_ADD_TYPE_ROW into O_add_type_module;

   close C_ADD_TYPE_ROW;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END GET_ADD_TYPE_MODULE_ROW;
------------------------------------------------------------------------------------
FUNCTION DELETE_ADDRESSES(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          I_key_value_1      IN     ADDR.KEY_VALUE_1%TYPE,
                          I_key_value_2      IN     ADDR.KEY_VALUE_2%TYPE,
                          I_addr_type        IN     ADDR.ADDR_TYPE%TYPE,
                          I_seq_no           IN     ADDR.SEQ_NO%TYPE,
                          I_primary_addr_ind IN     ADDR.PRIMARY_ADDR_IND%TYPE,
                          I_module           IN     ADDR.MODULE%TYPE,
                          I_mandatory          IN     ADD_TYPE_MODULE.MANDATORY_IND%TYPE
                          )
   RETURN BOOLEAN IS
   L_program            VARCHAR2(50) := 'ADDRESS_SQL.DELETE_ADDRESSES';
   L_allowed            BOOLEAN      := FALSE;
   L_seq_no             ADDR.SEQ_NO%TYPE := NULL;
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ADDR is
      select 'x'
        from addr
       where key_value_1  = I_key_value_1
         and (key_value_2 = I_key_value_2 or
             (key_value_2 is NULL and I_key_value_2 is NULL))
         and module       = I_module
         and addr_type    = I_addr_type
         and seq_no       = I_seq_no
         for update nowait;
   cursor C_CHECK_SEQ is
      select min(seq_no)
        from addr
       where key_value_1      = I_key_value_1
         and (key_value_2     = I_key_value_2
          or I_key_value_2 is NULL)
         and addr_type        = I_addr_type
         and module           = I_module
         and seq_no          != I_seq_no;
BEGIN

   if I_key_value_1 is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_key_value_1',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_module is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_module',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_addr_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_addr_type',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_seq_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   if DELETE_ALLOWED(O_error_message,
                     L_allowed,
                     I_key_value_1,
                     I_key_value_2,
                     I_addr_type,
                     I_seq_no,
                     I_primary_addr_ind,
                     I_module,
                     I_mandatory
                     ) = FALSE then
      return FALSE;
   end if;
   if L_allowed = TRUE then
      open C_LOCK_ADDR;
      close C_LOCK_ADDR;
      delete from ADDR
            where key_value_1  = I_key_value_1
              and (key_value_2 = I_key_value_2 or
                  (key_value_2 is NULL and I_key_value_2 is NULL))
              and module       = I_module
              and addr_type    = I_addr_type
              and seq_no       = I_seq_no;
      -- If the address type is non-mandatory and it is a primary address, return the seq_no
      -- for the earliest non-primary key address for the address type and assign that record
      -- to now be the primary address record for the address type
      if I_mandatory = 'N' and I_primary_addr_ind = 'Y' then
         -- Retrieve the next created sequence for the non-mandatoty address type
         -- if it exists
         open C_CHECK_SEQ;
         fetch C_CHECK_SEQ into L_seq_no;
         close C_CHECK_SEQ;
         if L_seq_no is not null then
            update ADDR
               set primary_addr_ind = 'Y'
             where key_value_1      = I_key_value_1
               and (key_value_2     = I_key_value_2
                or I_key_value_2 is NULL)
               and addr_type        = I_addr_type
               and module           = I_module
               and seq_no           = L_seq_no;
         end if;
      end if;
      if SQL%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('NO_RECORDS',
                                                NULL,
                                                NULL,
                                                NULL);
         return FALSE;
      end if;
   end if;
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED','ADDR',
                                            I_module);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END DELETE_ADDRESSES;
------------------------------------------------------------------------------------
FUNCTION MAND_ADD_EXISTS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_address_type    IN OUT   ADDR.ADDR_TYPE%TYPE,
                         I_module          IN       ADDR.MODULE%TYPE,
                         I_key_value_1     IN       ADDR.KEY_VALUE_1%TYPE,
                         I_key_value_2     IN       ADDR.KEY_VALUE_2%TYPE)
   RETURN BOOLEAN IS
   cursor C_MAND_ADD_TYPE is
      select address_type
        from add_type_module
       where module        = I_module
         and mandatory_ind = 'Y'
         and not exists (select 'x'
                           from addr
                          where addr.key_value_1  = I_key_value_1
                            and (addr.key_value_2 = I_key_value_2 or
                                (addr.key_value_2 is NULL and I_key_value_2 is NULL))
                            and addr.addr_type    = add_type_module.address_type
                            and addr.module       = I_module
                            and rownum            = 1)
         and rownum        = 1;

   L_program         VARCHAR2(50) := 'ADDRESS_SQL.MAND_ADD_EXISTS';
   L_mand_add_type   ADD_TYPE_MODULE.ADDRESS_TYPE%TYPE;

BEGIN

   if I_key_value_1 is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_key_value_1',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_module is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_module',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   open C_MAND_ADD_TYPE;

   fetch C_MAND_ADD_TYPE into L_mand_add_type;

   close C_MAND_ADD_TYPE;

   if L_mand_add_type is NULL then
      O_address_type := NULL;
   else
      O_address_type := L_mand_add_type;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END MAND_ADD_EXISTS;
-------------------------------------------------------------------------------------------------------
FUNCTION GET_ADDR_KEY(O_error_message  IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      O_addr_key          OUT   ADDR.ADDR_KEY%TYPE,
                      I_Store          IN       STORE.STORE%TYPE)
RETURN BOOLEAN IS

   L_program         VARCHAR2(60) := 'ADDRESS_SQL.GET_ADDR_KEY';


   cursor C_ADDR is
      select a.addr_key
        from addr a, add_type_module atm
       where atm.primary_ind = 'Y'
         and atm.mandatory_ind = 'Y'
         and a.module = 'ST'
         and a.primary_addr_ind = 'Y'
         and a.module = atm.module
         and a.key_value_1 = I_store;

BEGIN
   open C_ADDR;
   fetch C_ADDR into O_addr_key;
   if C_ADDR%NOTFOUND then
      CLOSE C_ADDR;
      O_error_message := SQL_LIB.CREATE_MSG('NO_PRIMARY_ADDRESS',
                                            NULL, NULL, NULL);
      return FALSE;
   end if;
   close C_ADDR;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END GET_ADDR_KEY;
-------------------------------------------------------------------------------------------------------
FUNCTION GET_PRIMARY_ADDR_TYPE(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                               O_primary_addr_type    OUT   ADD_TYPE_MODULE.ADDRESS_TYPE%TYPE)
RETURN BOOLEAN IS

   L_program         VARCHAR2(60) := 'ADDRESS_SQL.GET_PRIMARY_ADDR_TYPE';

   cursor C_ADD_TYPE_MODULE is
      select address_type
       from add_type_module
      where primary_ind = 'Y'
        and mandatory_ind = 'Y'
        and module = 'ST';

BEGIN
   open C_ADD_TYPE_MODULE;
   fetch C_ADD_TYPE_MODULE into O_primary_addr_type;
   if C_ADD_TYPE_MODULE%NOTFOUND then
      close C_ADD_TYPE_MODULE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_PRIMARY_ADDR_TYPE',
                                             NULL, 'ADDRESS_SQL.GET_PRIMARY_ADDR_TYPE', NULL);
      return FALSE;
   end if;
   close C_ADD_TYPE_MODULE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END GET_PRIMARY_ADDR_TYPE;
---------------------------------------------------------------------------------------------
FUNCTION INSERT_ADDR(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     I_address_tbl     IN       TYPE_ADDRESS_TBL)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ADDRESS_SQL.INSERT_ADDR';

BEGIN

   FOR i IN I_address_tbl.FIRST..I_address_tbl.LAST LOOP

      INSERT into addr(ADDR_KEY,
                       MODULE,
                       KEY_VALUE_1,
                       KEY_VALUE_2,
                       SEQ_NO,
                       ADDR_TYPE,
                       PRIMARY_ADDR_IND,
                       ADD_1,
                       ADD_2,
                       ADD_3,
                       CITY,
                       STATE,
                       COUNTRY_ID,
                       POST,
                       CONTACT_NAME,
                       CONTACT_PHONE,
                       CONTACT_TELEX,
                       CONTACT_FAX,
                       CONTACT_EMAIL,
                       ORACLE_VENDOR_SITE_ID,
                       EDI_ADDR_CHG,
                       COUNTY,
                       PUBLISH_IND)
                VALUES(addr_sequence.NEXTVAL,
                       I_address_tbl(i).module,
                       I_address_tbl(i).key_value_1,
                       I_address_tbl(i).key_value_2,
                       I_address_tbl(i).seq_no,
                       I_address_tbl(i).addr_type,
                       I_address_tbl(i).primary_addr_ind,
                       I_address_tbl(i).add_1,
                       I_address_tbl(i).add_2,
                   I_address_tbl(i).add_3,
                       I_address_tbl(i).city,
                       I_address_tbl(i).state,
                       I_address_tbl(i).country_id,
                       I_address_tbl(i).post,
                   I_address_tbl(i).contact_name,
                   I_address_tbl(i).contact_phone,
                   I_address_tbl(i).contact_telex,
                   I_address_tbl(i).contact_fax,
                   I_address_tbl(i).contact_email,
                   I_address_tbl(i).oracle_vendor_site_id,
                   I_address_tbl(i).edi_addr_chg,
                       I_address_tbl(i).county,
                   I_address_tbl(i).publish_ind);
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END INSERT_ADDR;
---------------------------------------------------------------------------------------------
FUNCTION UPDATE_ADDR(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     I_address_tbl     IN       TYPE_ADDRESS_TBL)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'ADDRESS_SQL.MODIFY_STORE';

BEGIN

   FOR i IN I_address_tbl.FIRST..I_address_tbl.LAST LOOP
      if not LOCK_ADDR(O_error_message,
                       I_address_tbl(i).addr_key) then
         return FALSE;
      end if;

      UPDATE addr
         SET ADD_1      = I_address_tbl(i).add_1,
             ADD_2      = I_address_tbl(i).add_2,
             CITY       = I_address_tbl(i).city,
             STATE      = I_address_tbl(i).state,
             COUNTRY_ID = I_address_tbl(i).country_id,
             POST       = I_address_tbl(i).post,
             COUNTY     = I_address_tbl(i).county
       WHERE addr_key = I_address_tbl(i).addr_key;

       if SQL%NOTFOUND then
          O_error_message := SQL_LIB.CREATE_MSG('COULD_NOT_UPDATE_REC');
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

END UPDATE_ADDR;
-----------------------------------------------------------------------------------------------
FUNCTION LOCK_ADDR(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                   I_addr_key        IN       ADDR.ADDR_KEY%TYPE)

   RETURN BOOLEAN IS

   L_program      VARCHAR2(50)  := 'ADDRESS_SQL.LOCK_ADDR';
   L_table        VARCHAR2(20)  := 'ADDR';

   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ADDR is
      select 'x'
        from addr
       where addr_key = I_addr_key
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ADDR', 'ADDR', 'addr: '||I_addr_key);
   open C_LOCK_ADDR;

   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ADDR', 'ADDR', 'addr: '||I_addr_key);
   close C_LOCK_ADDR;

   ---
   return TRUE;
EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('DELRECS_REC_LOC',
                                            L_table,
                                            'ADDR: '||I_addr_key,
                                            NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END LOCK_ADDR;
------------------------------------------------------------------------------------
FUNCTION GET_ADDR_TYPE_DESC(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            O_addr_type_desc   IN OUT   ADD_TYPE.TYPE_DESC%TYPE,
                            I_addr_type        IN       ADD_TYPE.ADDRESS_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50)  := 'ADDRESS_SQL.GET_ADDR_TYPE_DESC';
   L_table        VARCHAR2(20)  := 'ADD_TYPE';

   cursor C_ADDR_TYPE_DESC is
      select type_desc
        from add_type
       where address_type = I_addr_type;

BEGIN

   if I_addr_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_addr_type',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_ADDR_TYPE_DESC',
                    L_table,
                    'Add_type: '||I_addr_type);
   open C_ADDR_TYPE_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_ADDR_TYPE_DESC',
                    L_table,
                    'Add_type: '||I_addr_type);
   fetch C_ADDR_TYPE_DESC into O_addr_type_desc;

   SQL_LIB.SET_MARK('FETCH',
                    'C_ADDR_TYPE_DESC',
                    L_table,
                    'Add_type: '||I_addr_type);
   close C_ADDR_TYPE_DESC;

   if O_addr_type_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ADDR_TYPE',
                                            I_addr_type,
                                            NULL,
                                            NULL);
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

END GET_ADDR_TYPE_DESC;
-------------------------------------------------------------------------------------
FUNCTION GET_DEFAULT_ADDR_TYPE(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                               O_addr_type_desc   IN OUT   ADD_TYPE.TYPE_DESC%TYPE,
                               O_addr_type        IN OUT   ADD_TYPE.ADDRESS_TYPE%TYPE,
                               I_module           IN       ADD_TYPE_MODULE.MODULE%TYPE)
   RETURN BOOLEAN IS
   L_program      VARCHAR2(50)  := 'ADDRESS_SQL.GET_DEFAULT_ADDR_TYPE';
   L_table        VARCHAR2(20)  := 'ADD_TYPE';

   cursor C_ADDR_DEFAULT_TYPE_DESC is
      select at.type_desc,
             at.address_type
        from add_type at,
             add_type_module atm
       where get_primary_lang = get_user_lang
         and at.address_type = atm.address_type
         and decode(atm.primary_ind, 'N', atm.mandatory_ind, atm.primary_ind) = 'Y'
         and atm.module = I_module
       union all
      select nvl(ts.translated_value, at.type_desc),
             at.address_type
        from tl_shadow ts,
             add_type at,
             add_type_module atm
       where get_primary_lang != get_user_lang
         and upper(at.type_desc) = ts.key(+)
         and get_user_lang = ts.lang(+)
         and at.address_type = atm.address_type
         and decode(atm.primary_ind, 'N', atm.mandatory_ind, atm.primary_ind) = 'Y'
         and atm.module = I_module;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_ADDR_DEFAULT_TYPE_DESC',
                    L_table,
                    'Module: '||I_module);
   open C_ADDR_DEFAULT_TYPE_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_ADDR_DEFAULT_TYPE_DESC',
                    L_table,
                    'Module: '||I_module);

   fetch C_ADDR_DEFAULT_TYPE_DESC into O_addr_type_desc,
                                       O_addr_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_ADDR_DEFAULT_TYPE_DESC',
                    L_table,
                    'Module: '||I_module);
   close C_ADDR_DEFAULT_TYPE_DESC;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END GET_DEFAULT_ADDR_TYPE;
-------------------------------------------------------------------------------------
FUNCTION CREATE_UPDATE_ALLOWED(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                               O_allowed          IN OUT   BOOLEAN,
                               I_addr_type        IN       ADD_TYPE.ADDRESS_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(50)  := 'ADDRESS_SQL.CREATE_UPDATE_ALLOWED';
   L_external_addr_ind  ADD_TYPE.EXTERNAL_ADDR_IND%TYPE;

   cursor C_EXT_IND_CHECK is
      select external_addr_ind
        from add_type
       where address_type = I_addr_type;

BEGIN
   if I_addr_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_addr_type',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   O_allowed := TRUE;

   open C_EXT_IND_CHECK;
   fetch C_EXT_IND_CHECK into L_external_addr_ind;
   close C_EXT_IND_CHECK;

   if L_external_addr_ind = 'Y' then
      O_allowed := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
END CREATE_UPDATE_ALLOWED;
-------------------------------------------------------------------------------------
FUNCTION GET_SUPP_PRIMARY_ADDR_TYPE(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                    O_primary_addr_type    OUT   ADD_TYPE_MODULE.ADDRESS_TYPE%TYPE)
RETURN BOOLEAN IS

   L_program         VARCHAR2(60) := 'ADDRESS_SQL.GET_SUPP_PRIMARY_ADDR_TYPE';

   cursor C_ADD_TYPE_MODULE is
      select address_type
       from add_type_module
      where primary_ind = 'Y'
        and mandatory_ind = 'Y'
        and module = 'SUPP';

BEGIN
   open C_ADD_TYPE_MODULE;
   fetch C_ADD_TYPE_MODULE into O_primary_addr_type;
   if C_ADD_TYPE_MODULE%NOTFOUND then
      close C_ADD_TYPE_MODULE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_PRIMARY_ADDR_TYPE',
                                             NULL, 'ADDRESS_SQL.GET_PRIMARY_ADDR_TYPE', NULL);
      return FALSE;
   end if;
   close C_ADD_TYPE_MODULE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END GET_SUPP_PRIMARY_ADDR_TYPE;
---------------------------------------------------------------------------------------------
-- CR604 05-Sep-2014 Raghavendra.Shivaswamy@in.tesco.com Begin
-----------------------------------------------------------------------------------------------
--FUNCTION NAME: TSL_GET_SUPPLIER_COUNTRY
--Purpose:       This function fetches the suppliers country, country_origin  and first two character from the tsl_supp_addr table for the supplier
-----------------------------------------------------------------------------------------------
FUNCTION TSL_GET_SUPPLIER_COUNTRY (O_error_message OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_country_id    OUT   TSL_SUPP_ADDR.COUNTRY_ORIGIN%TYPE,
                                   O_supp_country  OUT   TSL_SUPP_ADDR.SUP_COUNTRY%TYPE,
                                   O_vat_no        OUT   TSL_SUPP_ADDR.VAT_NO%TYPE,
                                   I_supplier      IN    SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50)  := 'ADDRESS_SQL.GET_SUPPLIER_COUNTRY';
   L_table        VARCHAR2(20)  := 'TSL_SUPP_ADDR';
   L_table1       VARCHAR2(50)  := 'TSL_STAGE_MISSING_SUPPLIERS';
   L_vat_no       TSL_SUPP_ADDR.VAT_NO%TYPE := NULL;
   L_country_id   TSL_SUPP_ADDR.COUNTRY_ORIGIN%TYPE := NULL;
   L_supp_country TSL_SUPP_ADDR.SUP_COUNTRY%TYPE := NULL;
   L_num          INTEGER := NULL;
   L_exists       VARCHAR2(1) := NULL;

   cursor C_COUNTRY_ID is
      select 1, sup_country, vat_no, country_origin
        from tsl_supp_addr
       where UPPER(SUBSTR(ltrim(nvl(vat_no,'0')),1 ,2))='GB'
         and supplier=to_char(I_supplier)
         and country_origin = 'UK'
      UNION
      select 2, sup_country, vat_no, country_origin
        from tsl_supp_addr
       where UPPER(SUBSTR(ltrim(nvl(vat_no,'0')),1 ,2)) ='IE'
         and supplier=to_char(I_supplier)
         and country_origin = 'ROI'
      UNION
      select 3, sup_country, vat_no, country_origin
        from tsl_supp_addr
       where UPPER(SUBSTR(ltrim(nvl(vat_no,'0')),1 ,2)) ='XX'
         and supplier=to_char(I_supplier)
         and country_origin = 'UK'
         and upper(sup_country)='UNITED KINGDOM'
      UNION
      select 4, sup_country, vat_no, country_origin
        from tsl_supp_addr
       where UPPER(SUBSTR(ltrim(nvl(vat_no,'0')),1 ,2)) ='XX'
         and supplier=to_char(I_supplier)
         and country_origin = 'ROI'
         and upper(sup_country)='IRELAND'
      UNION
      select 5, sup_country, vat_no, country_origin
        from tsl_supp_addr
       where supplier=to_char(I_supplier)
         and rownum=1
       order by 1;

   cursor C_SUPP_CHK is
     select 'X'
       from tsl_fixed_deal_vat_missing_sup
      where supplier=to_char(I_supplier);


BEGIN

   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_supplier',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_COUNTRY_ID',
                    L_table,
                    'supplier: '||I_supplier);
   open C_COUNTRY_ID;

   SQL_LIB.SET_MARK('FETCH',
                    'C_COUNTRY_ID',
                    L_table,
                    'supplier: '||I_supplier);
   fetch C_COUNTRY_ID into L_num, L_supp_country, L_vat_no, L_country_id;

   if C_COUNTRY_ID%NOTFOUND then
      SQL_LIB.SET_MARK('OPEN',
                    'C_SUPP_CHK',
                    L_table1,
                    'supplier: '||I_supplier);
      open C_SUPP_CHK;
      SQL_LIB.SET_MARK('FETCH',
                    'C_SUPP_CHK',
                    L_table1,
                    'supplier: '||I_supplier);

      fetch C_SUPP_CHK into L_exists;

      if L_exists is null then

	     insert into tsl_fixed_deal_vat_missing_sup
         select distinct supplier, sup_name, duns_number, sup_status
         from SUPS
         where supplier=to_char(I_supplier);

      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_SUPP_CHK',
                       L_table1,
                       'supplier: '||I_supplier);
      close C_SUPP_CHK;
   end if;

      O_country_id := L_country_id;
      if L_supp_country is NOT NULL then
         O_supp_country := UPPER(L_supp_country);
      else
	     O_supp_country := L_supp_country;
      end if;
      if L_vat_no is NOT NULL then
         O_vat_no := UPPER(SUBSTR(ltrim(L_vat_no),1 ,2));
      else
	     O_vat_no := L_vat_no;
      end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_COUNTRY_ID',
                    L_table,
                    'supplier: '||I_supplier);
   close C_COUNTRY_ID;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END TSL_GET_SUPPLIER_COUNTRY;
----------------------------------------------------------------------------------------------
-- CR604 05-Sep-2014 Raghavendra.Shivaswamy@in.tesco.com End
-----------------------------------------------------------------------------------------------
END;
/

