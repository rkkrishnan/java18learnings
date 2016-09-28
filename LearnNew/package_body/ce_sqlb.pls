CREATE OR REPLACE PACKAGE BODY CE_SQL AS
---------------------------------------------------------------------------------------------------------
FUNCTION GET_NEXT_CE_ID(O_error_message    IN OUT VARCHAR2,
                        O_ce_id            IN OUT CE_HEAD.CE_ID%TYPE)
   return BOOLEAN is

   L_first_time               VARCHAR2(3) := 'YES';
   L_wrap_seq_no              CE_HEAD.CE_ID%TYPE;
   L_exists                   VARCHAR2(1) := NULL;

   cursor C_CE_EXISTS is
      select 'x'
        from ce_head
       where ce_id  = O_ce_id;

   cursor C_SELECT_NEXTVAL is
      select ce_sequence.NEXTVAL
        from dual;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_SELECT_NEXTVAL','DUAL',NULL);
   open C_SELECT_NEXTVAL;
   LOOP
      SQL_LIB.SET_MARK('FETCH','C_SELECT_NEXTVAL','DUAL',NULL);
      fetch C_SELECT_NEXTVAL into O_ce_id;
      if L_first_time = 'YES' then
         L_wrap_seq_no   := O_ce_id;
         L_first_time    := 'NO';
      elsif O_ce_id = L_wrap_seq_no then
         O_error_message := SQL_LIB.CREATE_MSG('NO_CE_NUM', NULL, NULL, NULL);
         SQL_LIB.SET_MARK('CLOSE','C_SELECT_NEXTVAL','DUAL',NULL);
         close C_SELECT_NEXTVAL;
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_SELECT_NEXTVAL','DUAL',NULL);
      close C_SELECT_NEXTVAL;

      SQL_LIB.SET_MARK('OPEN','C_CE_EXISTS','CE_HEAD',
                      'ce_id: '||to_char(O_ce_id));
      open C_CE_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_CE_EXISTS','CE_HEAD',
                       'ce_id: '||to_char(O_ce_id));
      fetch C_CE_EXISTS into L_exists;
      if C_CE_EXISTS%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE','C_CE_EXISTS','CE_HEAD',
                          'ce_id: '||to_char(O_ce_id));
         close C_CE_EXISTS;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_CE_EXISTS','CE_HEAD',
                       'ce_id: '||to_char(O_ce_id));
      close C_CE_EXISTS;
   END LOOP;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.GET_NEXT_CE_ID',
                                            to_char(SQLCODE));
   return FALSE;
END GET_NEXT_CE_ID;
--------------------------------------------------------------------------------------------
FUNCTION GET_DEFAULTS(O_error_message       IN OUT VARCHAR2,
                      O_import_country_id   IN OUT CE_HEAD.IMPORT_COUNTRY_ID%TYPE,
                      O_currency_code       IN OUT CE_HEAD.CURRENCY_CODE%TYPE,
                      O_exchange_rate       IN OUT CE_HEAD.EXCHANGE_RATE%TYPE,
                      I_ce_id               IN     CE_HEAD.CE_ID%TYPE)
   return BOOLEAN is

L_temp number(1);

BEGIN
   if SYSTEM_OPTIONS_SQL.GET_BASE_COUNTRY(O_error_message,
                                          O_import_country_id) = FALSE then
      return FALSE;
   end if;
   ---
   if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                       O_currency_code) = FALSE then
      return FALSE;
   end if;
   ---
   if CURRENCY_SQL.GET_RATE(O_error_message,
                            O_exchange_rate,
                            O_currency_code,
                            'U',
                            Get_Vdate) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.GET_DEFAULTS',
                                            to_char(SQLCODE));
   return FALSE;
END GET_DEFAULTS;
-----------------------------------------------------------------------------------
FUNCTION GET_ENTRY_STATUS_DESC(O_error_message      IN OUT VARCHAR2,
                               O_exists             IN OUT BOOLEAN,
                               O_description        IN OUT ENTRY_STATUS.ENTRY_STATUS_DESC%TYPE,
                               I_entry_status       IN     ENTRY_STATUS.ENTRY_STATUS%TYPE,
                               I_import_country_id  IN     ENTRY_STATUS.IMPORT_COUNTRY_ID%TYPE)
   return BOOLEAN is

   cursor C_GET_ENTRY_STATUS_DESC is
      select entry_status_desc
        from ENTRY_STATUS
       where entry_status      = I_entry_status
         and import_country_id = I_import_country_id;
BEGIN

   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN','C_GET_ENTRY_STATUS_DESC','ENTRY_STATUS',
                    'entry_status: '||I_entry_status);
   open C_GET_ENTRY_STATUS_DESC;
   SQL_LIB.SET_MARK('FETCH','C_GET_ENTRY_STATUS_DESC','ENTRY_STATUS',
                    'entry_status: '||I_entry_status);
   fetch C_GET_ENTRY_STATUS_DESC into O_description;

   if C_GET_ENTRY_STATUS_DESC%NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ENTRY_STATUS',I_entry_status,NULL,NULL);
   else
      O_exists := TRUE;
      if LANGUAGE_SQL.TRANSLATE(O_description,
                                O_description,
                                O_error_message) = FALSE then
       return FALSE;
      end if;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ENTRY_STATUS_DESC','ENTRY_STATUS',
                    'entry_status: '||I_entry_status);
   close C_GET_ENTRY_STATUS_DESC;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.GET_ENTRY_STATUS',
                                            to_char(SQLCODE));
   return FALSE;
END GET_ENTRY_STATUS_DESC;
---------------------------------------------------------------------------------------------------------
FUNCTION GET_ENTRY_TYPE_DESC(O_error_message     IN OUT VARCHAR2,
                             O_exists            IN OUT BOOLEAN,
                             O_description       IN OUT ENTRY_TYPE.ENTRY_TYPE_DESC%TYPE,
                             I_entry_type        IN     ENTRY_TYPE.ENTRY_TYPE%TYPE,
                             I_import_country_id IN     ENTRY_TYPE.IMPORT_COUNTRY_ID%TYPE)
   return BOOLEAN is

   cursor C_GET_ENTRY_TYPE_DESC is
      select entry_type_desc
        from ENTRY_TYPE
       where entry_type        = I_entry_type
         and import_country_id = I_import_country_id;
BEGIN

   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN','C_GET_ENTRY_TYPE_DESC','ENTRY_TYPE',
                    'entry_type: '||I_entry_type);
   open C_GET_ENTRY_TYPE_DESC;
   SQL_LIB.SET_MARK('FETCH','C_GET_ENTRY_TYPE_DESC','ENTRY_TYPE',
                    'entry_type: '||I_entry_type);
   fetch C_GET_ENTRY_TYPE_DESC into O_description;

   if C_GET_ENTRY_TYPE_DESC%NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ENTRY_TYPE',I_entry_type,NULL,NULL);
   else
      O_exists := TRUE;
      if LANGUAGE_SQL.TRANSLATE(O_description,
                                O_description,
                                O_error_message) = FALSE then
       return FALSE;
      end if;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ENTRY_TYPE_DESC','ENTRY_TYPE',
                    'entry_type: '||I_entry_type);
   close C_GET_ENTRY_TYPE_DESC;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.GET_ENTRY_TYPE_DESC',
                                            to_char(SQLCODE));
   return FALSE;
END GET_ENTRY_TYPE_DESC;
----------------------------------------------------------------------
FUNCTION LOCK_HEAD_CHILDREN(O_error_message   IN OUT VARCHAR2,
                            I_ce_id           IN     CE_HEAD.CE_ID%TYPE)
   return BOOLEAN is

   L_table          VARCHAR2(30);
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_locked, -54);

   L_seq_no                ALC_HEAD.SEQ_NO%TYPE;
   L_order_no              ALC_HEAD.ORDER_NO%TYPE;
   L_vessel_id             TRANSPORTATION.VESSEL_ID%TYPE;
   L_voyage_flt_id         TRANSPORTATION.VOYAGE_FLT_ID%TYPE;
   L_estimated_depart_date TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE;

   cursor C_LOCK_CE_SHIPMENT is
      select 'Y'
        from CE_SHIPMENT
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_CE_ORD_ITEM is
      select 'Y'
        from CE_ORD_ITEM
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_CE_CHARGES is
      select 'Y'
        from CE_CHARGES
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_CE_LIC_VISA is
      select 'Y'
        from CE_LIC_VISA
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_CE_FORMS is
      select 'Y'
        from CE_FORMS
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_CE_PROTEST is
      select 'Y'
        from CE_PROTEST
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_MISSING_DOC is
      select 'Y'
        from MISSING_DOC
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_TIMELINE is
      select 'Y'
        from TIMELINE
       where timeline_type = 'CE'
         and key_value_1   = to_char(I_ce_id)
         for update nowait;

   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from ALC_HEAD
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_ALC_COMP_LOC is
      select 'x'
        from ALC_COMP_LOC
       where order_no = L_order_no
         and seq_no   = L_seq_no
         for update nowait;

   cursor C_LOCK_TRANSPORTATION is
      select 'x'
        from TRANSPORTATION
       where vessel_id             = L_vessel_id
         and voyage_flt_id         = L_voyage_flt_id
         and estimated_depart_date = L_estimated_depart_date
         and status                = 'F'
         for update nowait;

   cursor C_ALC_HEAD is
      select order_no,
             seq_no
        from ALC_HEAD
       where ce_id = I_ce_id;

   cursor C_CE_SHIPMENT is
      select vessel_id,
             voyage_flt_id,
             estimated_depart_date
        from CE_SHIPMENT
       where ce_id = I_ce_id;

BEGIN
   ---CE_SHIPMENT
   L_table := 'CE_SHIPMENT';
   open C_LOCK_CE_SHIPMENT;
   close C_LOCK_CE_SHIPMENT;

   ---CE_ORD_ITEM
   L_table := 'CE_ORD_ITEM';
   open C_LOCK_CE_ORD_ITEM;
   close C_LOCK_CE_ORD_ITEM;

   ---CE_CHARGES
   L_table := 'CE_CHARGES';
   open C_LOCK_CE_CHARGES;
   close C_LOCK_CE_CHARGES;

   ---CE_LIC_VISA
   L_table := 'CE_LIC_VISA';
   open C_LOCK_CE_LIC_VISA;
   close C_LOCK_CE_LIC_VISA;

   ---CE_FORMS
   L_table := 'CE_FORMS';
   open C_LOCK_CE_FORMS;
   close C_LOCK_CE_FORMS;

   ---CE_PROTEST
   L_table := 'CE_PROTEST';
   open C_LOCK_CE_PROTEST;
   close C_LOCK_CE_PROTEST;

   ---MISSING_DOC
   L_table := 'MISSING_DOC';
   open C_LOCK_MISSING_DOC;
   close C_LOCK_MISSING_DOC;

   ---TIMELINES
   L_table := 'TIMELINE';
   open C_LOCK_TIMELINE;
   close C_LOCK_TIMELINE;

   ---ALC
   FOR C_rec in C_ALC_HEAD LOOP
      L_order_no := C_rec.order_no;
      L_seq_no   := C_rec.seq_no;
      ---
      L_table := 'ALC_COMP_LOC';
      open C_LOCK_ALC_COMP_LOC;
      close C_LOCK_ALC_COMP_LOC;
   END LOOP;
   ---
   L_table := 'ALC_HEAD';
   open C_LOCK_ALC_HEAD;
   close C_LOCK_ALC_HEAD;

   ---TRANSPORTATION
   FOR C_rec in C_CE_SHIPMENT LOOP
      L_vessel_id             := C_rec.vessel_id;
      L_voyage_flt_id         := C_rec.voyage_flt_id;
      L_estimated_depart_date := C_rec.estimated_depart_date;
      ---
      L_table := 'TRANSPORTATION';
      open C_LOCK_TRANSPORTATION;
      close C_LOCK_TRANSPORTATION;
   END LOOP;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('DELRECS_REC_LOC',
                                            L_table,
                                            to_char(I_ce_id));
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'CE_SQL.LOCK_HEAD_CHILDREN',
                                             to_char(SQLCODE));
         return FALSE;
END LOCK_HEAD_CHILDREN;
----------------------------------------------------------------------
FUNCTION DELETE_HEAD_CHILDREN(O_error_message   IN OUT VARCHAR2,
                              I_ce_id           IN     CE_HEAD.CE_ID%TYPE)
   return BOOLEAN is

   L_seq_no                ALC_HEAD.SEQ_NO%TYPE;
   L_order_no              ALC_HEAD.ORDER_NO%TYPE;
   L_vessel_id             TRANSPORTATION.VESSEL_ID%TYPE;
   L_voyage_flt_id         TRANSPORTATION.VOYAGE_FLT_ID%TYPE;
   L_estimated_depart_date TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE;

   cursor C_ALC_HEAD is
      select order_no,
             seq_no
        from ALC_HEAD
       where ce_id = I_ce_id;

   cursor C_CE_SHIPMENT is
      select vessel_id,
             voyage_flt_id,
             estimated_depart_date
        from CE_SHIPMENT
       where ce_id = I_ce_id;


BEGIN
   ---ALC
   FOR C_rec in C_ALC_HEAD LOOP
      ---
      L_order_no := C_rec.order_no;
      L_seq_no   := C_rec.seq_no;
      ---
      delete from ALC_COMP_LOC
       where order_no = L_order_no
         and seq_no   = L_seq_no;
      ---
   END LOOP;

   ---TRANSPORTATION
   FOR C_rec in C_CE_SHIPMENT LOOP
      ---
      L_vessel_id             := C_rec.vessel_id;
      L_voyage_flt_id         := C_rec.voyage_flt_id;
      L_estimated_depart_date := C_rec.estimated_depart_date;
      ---
      update TRANSPORTATION
         set status = 'S'
       where vessel_id             = L_vessel_id
         and voyage_flt_id         = L_voyage_flt_id
         and estimated_depart_date = L_estimated_depart_date
         and status                = 'F';
      ---
   END LOOP;
   ---

   delete from ALC_HEAD
    where ce_id = I_ce_id;

   ---CE_LIC_VISA
   delete from CE_LIC_VISA
    where ce_id = I_ce_id;

   ---CE_CHARGES
   delete from CE_CHARGES
    where ce_id = I_ce_id;

   ---MISSING_DOC
   delete from MISSING_DOC
    where ce_id = I_ce_id;

   ---CE_ORD_ITEM
   delete from CE_ORD_ITEM
    where ce_id = I_ce_id;

   ---CE_SHIPMENT
   delete from CE_SHIPMENT
    where ce_id = I_ce_id;

   ---CE_FORMS
   delete from CE_FORMS
    where ce_id = I_ce_id;

   ---CE_PROTEST
   delete from CE_PROTEST
    where ce_id = I_ce_id;

   ---TIMELINES
   delete from TIMELINE
    where timeline_type = 'CE'
      and key_value_1   = to_char(I_ce_id);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'CE_SQL.DELETE_HEAD_CHILDREN',
                                             to_char(SQLCODE));
         return FALSE;
END DELETE_HEAD_CHILDREN;
----------------------------------------------------------------------
FUNCTION LOCK_SHIPMENT_CHILDREN(O_error_message         IN OUT VARCHAR2,
                                I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                                I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                                I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE)
   return BOOLEAN is

   L_table             VARCHAR2(30);
   RECORD_LOCKED       EXCEPTION;
   PRAGMA              EXCEPTION_INIT(Record_locked, -54);

   L_seq_no         ALC_HEAD.SEQ_NO%TYPE;
   L_order_no       ALC_HEAD.ORDER_NO%TYPE;

   cursor C_LOCK_CE_ORD_ITEM is
      select 'Y'
        from CE_ORD_ITEM
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         for update nowait;

   cursor C_LOCK_CE_CHARGES is
      select 'Y'
        from CE_CHARGES
       where ce_id = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         for update nowait;

   cursor C_LOCK_CE_LIC_VISA is
      select 'Y'
        from CE_LIC_VISA
       where ce_id = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         for update nowait;

   cursor C_LOCK_MISSING_DOC is
      select 'Y'
        from MISSING_DOC
       where ce_id = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         for update nowait;

   cursor C_LOCK_TRANSPORTATION is
      select 'Y'
        from TRANSPORTATION
       where vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and status                = 'F'
         for update nowait;

   cursor C_LOCK_ALC_HEAD is
      select 'Y'
        from ALC_HEAD
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_ALC_COMP_LOC is
      select 'Y'
        from ALC_COMP_LOC
       where order_no = L_order_no
         and seq_no   = L_seq_no
         for update nowait;

   cursor C_ALC_HEAD is
      select order_no,
             seq_no
        from ALC_HEAD
       where ce_id = I_ce_id;

BEGIN
   ---ALC
   FOR C_rec in C_ALC_HEAD LOOP
      L_order_no := C_rec.order_no;
      L_seq_no   := C_rec.seq_no;
      ---
      L_table := 'ALC_COMP_LOC';
      open C_LOCK_ALC_COMP_LOC;
      close C_LOCK_ALC_COMP_LOC;
   END LOOP;
   ---
   L_table := 'ALC_HEAD';
   open C_LOCK_ALC_HEAD;
   close C_LOCK_ALC_HEAD;

   ---CE_ORD_ITEM
   L_table := 'CE_ORD_ITEM';
   open C_LOCK_CE_ORD_ITEM;
   close C_LOCK_CE_ORD_ITEM;

   ---CE_CHARGES
   L_table := 'CE_CHARGES';
   open C_LOCK_CE_CHARGES;
   close C_LOCK_CE_CHARGES;

   ---CE_LIC_VISA
   L_table := 'CE_LIC_VISA';
   open C_LOCK_CE_LIC_VISA;
   close C_LOCK_CE_LIC_VISA;

   ---MISSING_DOC
   L_table := 'MISSING_DOC';
   open C_LOCK_MISSING_DOC;
   close C_LOCK_MISSING_DOC;

   --- TRANSPORTATION
   L_table := 'TRANSPORTATION';
   open C_LOCK_TRANSPORTATION;
   close C_LOCK_TRANSPORTATION;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('DELRECS_REC_LOC',
                                            L_table,
                                            to_char(I_ce_id));
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'CE_SQL.LOCK_SHIPMENT_CHILDREN',
                                             to_char(SQLCODE));
         return FALSE;
END LOCK_SHIPMENT_CHILDREN;
----------------------------------------------------------------------
FUNCTION DELETE_SHIPMENT_CHILDREN(O_error_message         IN OUT VARCHAR2,
                                  I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                                  I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                                  I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                  I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE)
   return BOOLEAN is

   L_seq_no         ALC_HEAD.SEQ_NO%TYPE;
   L_order_no       ALC_HEAD.ORDER_NO%TYPE;

   cursor C_ALC_HEAD is
      select order_no,
             seq_no
        from ALC_HEAD
       where ce_id = I_ce_id;

BEGIN
   ---ALC
   FOR C_rec in C_ALC_HEAD LOOP
      L_order_no := C_rec.order_no;
      L_seq_no   := C_rec.seq_no;
      ---
      delete from ALC_COMP_LOC
       where order_no = L_order_no
         and seq_no   = L_seq_no;
   END LOOP;
   ---
   delete from ALC_HEAD
    where ce_id = I_ce_id;

   ---CE_CHARGES
   delete from CE_CHARGES
    where ce_id                 = I_ce_id
      and vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_flt_id
      and estimated_depart_date = I_estimated_depart_date;

   ---CE_LIC_VISA
   delete from CE_LIC_VISA
    where ce_id                 = I_ce_id
      and vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_flt_id
      and estimated_depart_date = I_estimated_depart_date;

   ---CE_MISSING_DOC
   delete from MISSING_DOC
    where ce_id                 = I_ce_id
      and vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_flt_id
      and estimated_depart_date = I_estimated_depart_date;

   ---TRANSPORTATION
   update TRANSPORTATION
      set status = 'S'
    where vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_flt_id
      and estimated_depart_date = I_estimated_depart_date
      and status                = 'F';

   ---CE_ORD_ITEM
   delete from CE_ORD_ITEM
    where ce_id                 = I_ce_id
      and vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_flt_id
      and estimated_depart_date = I_estimated_depart_date;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'CE_SQL.DELETE_SHIPMENT_CHILDREN',
                                             to_char(SQLCODE));
         return FALSE;
END DELETE_SHIPMENT_CHILDREN;
----------------------------------------------------------------------
FUNCTION LOCK_ORD_ITEM_CHILDREN(O_error_message         IN OUT VARCHAR2,
                                I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                                I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                                I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                                I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                                I_item                  IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_table       VARCHAR2(30);
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_locked, -54);

   L_seq_no         ALC_HEAD.SEQ_NO%TYPE;
   L_order_no       ALC_HEAD.ORDER_NO%TYPE;

   cursor C_LOCK_CE_CHARGES is
      select 'Y'
        from CE_CHARGES
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and ((item                = I_item
               and pack_item is NULL)
          or (pack_item            = I_item
              and pack_item is NOT NULL))
         for update nowait;

   cursor C_LOCK_CE_LIC_VISA is
      select 'Y'
        from CE_LIC_VISA
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         for update nowait;

   cursor C_LOCK_MISSING_DOC is
      select 'Y'
        from MISSING_DOC
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         for update nowait;

   cursor C_LOCK_TRANSPORTATION is
      select 'Y'
        from TRANSPORTATION
       where vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and status                = 'F'
         for update nowait;

   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from ALC_HEAD
       where ce_id = I_ce_id
         for update nowait;

   cursor C_LOCK_ALC_COMP_LOC is
      select 'x'
        from ALC_COMP_LOC
       where order_no = L_order_no
         and seq_no   = L_seq_no
         for update nowait;

   cursor C_ALC_HEAD is
      select order_no,
             seq_no
        from ALC_HEAD
       where ce_id = I_ce_id;

BEGIN
   ---ALC
   FOR C_rec in C_ALC_HEAD LOOP
      L_order_no := C_rec.order_no;
      L_seq_no   := C_rec.seq_no;
      ---
      L_table := 'ALC_COMP_LOC';
      open C_LOCK_ALC_COMP_LOC;
      close C_LOCK_ALC_COMP_LOC;
   END LOOP;
   ---
   L_table := 'ALC_HEAD';
   open C_LOCK_ALC_HEAD;
   close C_LOCK_ALC_HEAD;

   ---CE_CHARGES
   L_table := 'CE_CHARGES';
   open C_LOCK_CE_CHARGES;
   close C_LOCK_CE_CHARGES;

   ---CE_LIC_VISA
   L_table := 'CE_LIC_VISA';
   open C_LOCK_CE_LIC_VISA;
   close C_LOCK_CE_LIC_VISA;

   ---MISSING_DOC
   L_table := 'MISSING_DOC';
   open C_LOCK_MISSING_DOC;
   close C_LOCK_MISSING_DOC;

   --- TRANSPORTATION
   L_table := 'TRANSPORTATION';
   open C_LOCK_TRANSPORTATION;
   close C_LOCK_TRANSPORTATION;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('DELRECS_REC_LOC',
                                            L_table,
                                            to_char(I_ce_id));
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'CE_SQL.DELETE_ORD_ITEM_CHILDREN',
                                             to_char(SQLCODE));
         return FALSE;
END LOCK_ORD_ITEM_CHILDREN;
----------------------------------------------------------------------
FUNCTION DELETE_ORD_ITEM_CHILDREN(O_error_message         IN OUT VARCHAR2,
                                  I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                                  I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                                  I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                  I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                                  I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                                  I_item                  IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_seq_no         ALC_HEAD.SEQ_NO%TYPE;
   L_order_no       ALC_HEAD.ORDER_NO%TYPE;

   cursor C_ALC_HEAD is
      select order_no,
             seq_no
        from ALC_HEAD
       where ce_id = I_ce_id;

BEGIN
   FOR C_rec in C_ALC_HEAD LOOP
      L_order_no := C_rec.order_no;
      L_seq_no   := C_rec.seq_no;
      ---
      delete from ALC_COMP_LOC
       where order_no = L_order_no
         and seq_no   = L_seq_no;
   END LOOP;
   ---
   delete from ALC_HEAD
    where ce_id = I_ce_id;

   ---CE_CHARGES
   delete from CE_CHARGES
    where ce_id = I_ce_id
      and vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_flt_id
      and estimated_depart_date = I_estimated_depart_date
      and order_no              = I_order_no
      and ((item                = I_item
            and pack_item is NULL)
       or (pack_item            = I_item
           and pack_item is NOT NULL));


   ---CE_LIC_VISA
   delete from CE_LIC_VISA
    where ce_id = I_ce_id
      and vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_flt_id
      and estimated_depart_date = I_estimated_depart_date
      and order_no              = I_order_no
      and item                  = I_item;

   ---CE_MISSING_DOC
   delete from MISSING_DOC
    where ce_id = I_ce_id
      and vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_flt_id
      and estimated_depart_date = I_estimated_depart_date
      and order_no              = I_order_no
      and item                  = I_item;

    ---TRANSPORTATION
   update TRANSPORTATION
      set status = 'S'
    where vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_flt_id
      and estimated_depart_date = I_estimated_depart_date
      and status                = 'F';

  return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'CE_SQL.DELETE_ORD_ITEM_CHILDREN',
                                             to_char(SQLCODE));
   return FALSE;
END DELETE_ORD_ITEM_CHILDREN;
----------------------------------------------------------------------
FUNCTION CE_SHIPMENT_EXIST(O_error_message       IN OUT VARCHAR2,
                           O_shipment_exist      IN OUT BOOLEAN,
                           I_ce_id               IN     CE_SHIPMENT.CE_ID%TYPE)
  return  BOOLEAN IS

  L_program VARCHAR2(50) := 'CE_SQL.SHIPMENT_DETAILS_EXIST';
  L_exist   VARCHAR2(1);

  cursor C_SHIPMENT_EXIST IS
     select 'x'
       from ce_shipment
      where ce_id = I_ce_id;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_SHIPMENT_EXIST','CE_SHIPMENT','ce_id: '||to_char(I_ce_id));
   open C_SHIPMENT_EXIST;

   SQL_LIB.SET_MARK('FETCH','C_SHIPMENT_EXIST','CE_SHIPMENT','ce_id: '||to_char(I_ce_id));
   fetch C_SHIPMENT_EXIST into L_exist;

   if C_SHIPMENT_EXIST%NOTFOUND then
      O_shipment_exist := FALSE;
   else
      O_shipment_exist := TRUE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_ENTRY_NO','CE_HEAD','ce_id: '||to_char(I_ce_id));
   close C_SHIPMENT_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CE_SHIPMENT_EXIST;
---------------------------------------------------------------------------------------------------------------------
FUNCTION SHIPMENT_ORDER_ITEM_EXISTS(O_error_message		IN OUT VARCHAR2,
                                    O_exists 		      IN OUT BOOLEAN,
                                    I_ce_id			IN     CE_SHIPMENT.CE_ID%TYPE,
                                    I_vessel_id			IN	 TRANSPORTATION.VESSEL_ID%TYPE,
                                    I_voyage_flt_id		IN	 TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                    I_estimated_depart_date IN	 TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE)

  return  BOOLEAN IS

  L_program VARCHAR2(50) := 'CE_SQL.SHIPMENT_ORDER_ITEM_EXIST';
  L_exists	VARCHAR2(1)  := NULL;

  cursor C_SHIPMENT_ORDER_ITEM_EXISTS IS
     select 'X'
       from ce_ord_item
      where ce_id 			= I_ce_id
        and vessel_id    		= I_vessel_id
        and voyage_flt_id		= I_voyage_flt_id
        and estimated_depart_date	= I_estimated_depart_date;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_SHIPMENT_ORDER_ITEM_EXISTS','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
   open C_SHIPMENT_ORDER_ITEM_EXISTS;

   SQL_LIB.SET_MARK('FETCH','C_SHIPMENT_ORDER_ITEM_EXISTS','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
   fetch C_SHIPMENT_ORDER_ITEM_EXISTS into L_exists;

   if C_SHIPMENT_ORDER_ITEM_EXISTS %NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('INV_SHIPMENT_ORDER', NULL, NULL, NULL);
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_SHIPMENT_ORDER_ITEM_EXISTS','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
   close C_SHIPMENT_ORDER_ITEM_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END SHIPMENT_ORDER_ITEM_EXISTS;
--------------------------------------------------------------------------------------------------------------
FUNCTION SHIPMENT_EXISTS(O_error_message		 IN OUT VARCHAR2,
                         O_exists 		       IN OUT BOOLEAN,
                         I_ce_id			 IN     CE_SHIPMENT.CE_ID%TYPE,
                         I_vessel_id		 IN     TRANSPORTATION.VESSEL_ID%TYPE,
                         I_voyage_flt_id		 IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                         I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE)

   return  BOOLEAN IS

   L_program VARCHAR2(50) := 'CE_SQL.SHIPMENT_EXISTS';
   L_exists  VARCHAR2(1)  := NULL;

   cursor C_SHIPMENT_EXISTS IS
      select 'X'
        from ce_shipment
       where ce_id 			= I_ce_id
         and vessel_id    		= I_vessel_id
         and voyage_flt_id		= I_voyage_flt_id
         and estimated_depart_date	= I_estimated_depart_date;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_SHIPMENT_EXISTS','CE_SHIPMENT','ce_id: '||to_char(I_ce_id));
   open C_SHIPMENT_EXISTS;

   SQL_LIB.SET_MARK('FETCH','C_SHIPMENT_EXISTS','CE_SHIPMENT','ce_id: '||to_char(I_ce_id));
   fetch C_SHIPMENT_EXISTS into L_exists;

   if C_SHIPMENT_EXISTS %NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_SHIPMENT_EXISTS','CE_SHIPMENT','ce_id: '||to_char(I_ce_id));
   close C_SHIPMENT_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END SHIPMENT_EXISTS;
-----------------------------------------------------------------------------------------------------------------------
FUNCTION CHECK_CANDIDATE_IND(O_error_message         IN OUT VARCHAR2,
                             O_exists                IN OUT BOOLEAN,
                             I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                             I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                             I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE)

   return  BOOLEAN IS

   L_program VARCHAR2(50) := 'CE_SQL.CHECK_CANDIDATE_IND';
   L_exists  VARCHAR2(1)  := NULL;

   cursor C_CHECK_CANDIDATE_IND IS
      select 'X'
        from transportation
       where vessel_id    		= I_vessel_id
         and voyage_flt_id		= I_voyage_flt_id
         and estimated_depart_date	= I_estimated_depart_date
         and candidate_ind 		= 'Y';

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_CHECK_CANDIDATE_IND','TRANSPORTATION', NULL);
   open C_CHECK_CANDIDATE_IND;

   SQL_LIB.SET_MARK('FETCH','C_CHECK_CANDIDATE_IND','TRANSPORTATION', NULL);
   fetch C_CHECK_CANDIDATE_IND into L_exists;

   if C_CHECK_CANDIDATE_IND %NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('INV_CANDIDATE', NULL, NULL, NULL);
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_CHECK_CANDIDATE_IND','TRANSPORTATION', NULL);
   close C_CHECK_CANDIDATE_IND;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_CANDIDATE_IND;
------------------------------------------------------------------------------------------------------------------
FUNCTION DEFAULT_SHIPMENT_INFO(O_error_message         IN OUT VARCHAR2,
                               O_exists                IN OUT BOOLEAN,
                               O_vessel_scac_code      IN OUT TRANSPORTATION.VESSEL_SCAC_CODE%TYPE,
                               O_lading_port           IN OUT TRANSPORTATION.LADING_PORT%TYPE,
                               O_discharge_port        IN OUT TRANSPORTATION.DISCHARGE_PORT%TYPE,
                               O_tran_mode_id          IN OUT TRANSPORTATION.TRAN_MODE_ID%TYPE,
                               O_export_country_id     IN OUT TRANSPORTATION.EXPORT_COUNTRY_ID%TYPE,
                               O_actual_arrival_date   IN OUT TRANSPORTATION.ACTUAL_ARRIVAL_DATE%TYPE,
                               I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                               I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                               I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE)
   return  BOOLEAN IS

   L_program VARCHAR2(50) := 'CE_SQL.DEFAULT_SHIPMENT_INFO';

   cursor C_DEFAULT_SHIPMENT_INFO is
     select vessel_scac_code,
            lading_port,
            discharge_port,
            tran_mode_id,
            export_country_id,
            actual_arrival_date
       from transportation
      where vessel_id    		= I_vessel_id
        and voyage_flt_id		= I_voyage_flt_id
        and estimated_depart_date	= I_estimated_depart_date;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_DEFAULT_SHIPMENT_INFO','TRANSPORTATION', NULL);
   open C_DEFAULT_SHIPMENT_INFO;

   SQL_LIB.SET_MARK('FETCH','C_DEFAULT_SHIPMENT_INFO','TRANSPORTATION', NULL);
   fetch C_DEFAULT_SHIPMENT_INFO into O_vessel_scac_code,
                                      O_lading_port,
                                      O_discharge_port,
                                      O_tran_mode_id,
                                      O_export_country_id,
                                      O_actual_arrival_date;
   if C_DEFAULT_SHIPMENT_INFO %NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_SHIPMENT_INFO', NULL, NULL, NULL);
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_DEFAULT_SHIPMENT_INFO','TRANSPORTATION', NULL);
   close C_DEFAULT_SHIPMENT_INFO;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEFAULT_SHIPMENT_INFO;
------------------------------------------------------------------------------------------------------------------
FUNCTION FORM_EXISTS(O_error_message IN OUT VARCHAR2,
                     O_exists        IN OUT BOOLEAN,
                     I_ce_id         IN     CE_FORMS.CE_ID%TYPE,
                     I_form_type     IN     CE_FORMS.FORM_TYPE%TYPE,
                     I_oga_code      IN     CE_FORMS.OGA_CODE%TYPE)

   return BOOLEAN IS

   L_program VARCHAR2(50) := 'CE_SQL.FORM_EXISTS';
   L_exists  VARCHAR2(1)  := NULL;

   cursor C_FORM_EXISTS IS
      select 'X'
        from ce_forms
       where ce_id     = I_ce_id
         and form_type = NVL(I_form_type,form_type)
         and oga_code  = NVL(I_oga_code,oga_code);

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_FORM_EXISTS','CE_FORMS','ce_id: '||to_char(I_ce_id));
   open C_FORM_EXISTS;

   SQL_LIB.SET_MARK('FETCH','C_FORM_EXISTS','CE_FORMS','ce_id: '||to_char(I_ce_id));
   fetch C_FORM_EXISTS into L_exists;

   if C_FORM_EXISTS%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_FORM_EXISTS','CE_FORMS','ce_id: '||to_char(I_ce_id));
   close C_FORM_EXISTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END FORM_EXISTS;
------------------------------------------------------------------------------------------------------------------
FUNCTION PROTEST_NO_EXISTS(O_error_message IN OUT VARCHAR2,
                           O_exists        IN OUT BOOLEAN,
                           I_ce_id         IN     CE_PROTEST.CE_ID%TYPE,
                           I_protest_no    IN     CE_PROTEST.PROTEST_NO%TYPE)
   return BOOLEAN IS

   L_program VARCHAR2(50) := 'CE_SQL.PROTEST_NO_EXISTS';
   L_exists  VARCHAR2(1)  := NULL;

   cursor C_PROTEST_NO_EXISTS IS
      select 'X'
        from ce_protest
       where ce_id      = I_ce_id
         and protest_no = NVL(I_protest_no,protest_no);

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_PROTEST_NO_EXISTS','CE_PROTEST','ce_id: '||to_char(I_ce_id));
   open C_PROTEST_NO_EXISTS;

   SQL_LIB.SET_MARK('FETCH','C_PROTEST_NO_EXISTS','CE_PROTEST','ce_id: '||to_char(I_ce_id));
   fetch C_PROTEST_NO_EXISTS into L_exists;

   if C_PROTEST_NO_EXISTS%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_PROTEST_NO_EXISTS','PROTEST','ce_id: '||to_char(I_ce_id));
   close C_PROTEST_NO_EXISTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                             L_program,
					     to_char(SQLCODE));

      return FALSE;

END PROTEST_NO_EXISTS;
--------------------------------------------------------------------------------------
FUNCTION GET_CE_ENTRY_NO(O_error_message  IN OUT VARCHAR2,
                         O_exists         IN OUT BOOLEAN,
                         O_entry_no       IN OUT CE_HEAD.ENTRY_NO%TYPE,
                         I_ce_id          IN     CE_HEAD.CE_ID%TYPE)
   RETURN BOOLEAN IS

   cursor C_GET_ENTRY_NO is
      select entry_no
        from ce_head
       where ce_id = I_ce_id;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_ENTRY_NO','CE_HEAD','ce_id: '||to_char(I_ce_id));
   open C_GET_ENTRY_NO;
   SQL_LIB.SET_MARK('FETCH','C_GET_ENTRY_NO','CE_HEAD','ce_id: '||to_char(I_ce_id));
   fetch C_GET_ENTRY_NO into O_entry_no;
   ---
   if C_GET_ENTRY_NO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_CE_ID',NULL,NULL,NULL);
      O_exists        := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_ENTRY_NO','CE_HEAD','ce_id: '||to_char(I_ce_id));
   close C_GET_ENTRY_NO;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.GET_CE_ENTRY_NO',
                                            to_char(SQLCODE));
      return FALSE;
END GET_CE_ENTRY_NO;
---------------------------------------------------------------------------------------------------------
FUNCTION GET_INFO (O_error_message          IN OUT VARCHAR2,
                   O_exists                 IN OUT BOOLEAN,
                   O_ce_id                  IN OUT CE_HEAD.CE_ID%TYPE,
                   O_entry_no               IN OUT CE_HEAD.ENTRY_NO%TYPE,
                   O_entry_date             IN OUT CE_HEAD.ENTRY_DATE%TYPE,
                   O_release_date           IN OUT CE_HEAD.RELEASE_DATE%TYPE,
                   O_summary_date           IN OUT CE_HEAD.SUMMARY_DATE%TYPE,
                   O_import_country_id      IN OUT CE_HEAD.IMPORT_COUNTRY_ID%TYPE,
                   O_entry_port             IN OUT CE_HEAD.ENTRY_PORT%TYPE,
                   O_entry_status           IN OUT CE_HEAD.ENTRY_STATUS%TYPE,
                   O_entry_type             IN OUT CE_HEAD.ENTRY_TYPE%TYPE,
                   O_importer_id            IN OUT CE_HEAD.IMPORTER_ID%TYPE,
                   O_bond_no                IN OUT CE_HEAD.BOND_NO%TYPE,
                   O_bond_type              IN OUT CE_HEAD.BOND_TYPE%TYPE,
                   O_broker_id              IN OUT CE_HEAD.BROKER_ID%TYPE,
                   O_broker_ref_id          IN OUT CE_HEAD.BROKER_REF_ID%TYPE,
                   I_ce_id                  IN     CE_HEAD.CE_ID%TYPE,
                   I_entry_no               IN     CE_HEAD.ENTRY_NO%TYPE)
   return BOOLEAN is

   L_program VARCHAR(50) := 'CE_SQL.GET_INFO';

   cursor C_GET_INFO_CE_ID is
      select entry_no,
             entry_date,
             release_date,
             summary_date,
             import_country_id,
             entry_port,
             entry_status,
             entry_type,
             importer_id,
             bond_no,
             bond_type,
             broker_id,
             broker_ref_id
        from ce_head
       where ce_id = I_ce_id;

   cursor C_GET_INFO_ENTRY_NO is
      select ce_id,
             entry_date,
             release_date,
             summary_date,
             import_country_id,
             entry_port,
             entry_status,
             entry_type,
             importer_id,
             bond_no,
             bond_type,
             broker_id,
             broker_ref_id
        from ce_head
       where entry_no = I_entry_no;

BEGIN
   O_exists := FALSE;
   if I_ce_id is not NULL then
      SQL_LIB.SET_MARK('OPEN','C_GET_INFO_CE_ID','CE_HEAD', 'ce_id: '||to_char(I_ce_id));
      open  C_GET_INFO_CE_ID;

      SQL_LIB.SET_MARK('FETCH','C_GET_INFO_CE_ID','CE_HEAD', 'ce_id: '||to_char(I_ce_id));
      fetch C_GET_INFO_CE_ID into O_entry_no,
                                  O_entry_date,
                                  O_release_date,
                                  O_summary_date,
                                  O_import_country_id,
                                  O_entry_port,
                                  O_entry_status,
                                  O_entry_type,
                                  O_importer_id,
                                  O_bond_no,
                                  O_bond_type,
                                  O_broker_id,
                                  O_broker_ref_id;
      if C_GET_INFO_CE_ID%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('NO_CE_INFO', to_char(I_ce_id));
         O_exists  := FALSE;
      else
         O_exists  := TRUE;
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_GET_INFO_CE_ID','CE_HEAD','ce_id: '||to_char(I_ce_id));
      close C_GET_INFO_CE_ID;
   else

      SQL_LIB.SET_MARK('OPEN','C_GET_INFO_ENTRY_NO','CE_HEAD','Entry_No: '||I_entry_no);
      open  C_GET_INFO_ENTRY_NO;

      SQL_LIB.SET_MARK('FETCH','C_GET_INFO_ENTRY_NO','CE_HEAD','Entry_No: '||I_entry_no);
      fetch C_GET_INFO_ENTRY_NO into O_ce_id,
                                     O_entry_date,
                                     O_release_date,
                                     O_summary_date,
                                     O_import_country_id,
                                     O_entry_port,
                                     O_entry_status,
                                     O_entry_type,
                                     O_importer_id,
                                     O_bond_no,
                                     O_bond_type,
                                     O_broker_id,
                                     O_broker_ref_id;
      if C_GET_INFO_ENTRY_NO%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('NO_ENTRY_NO_INFO', I_entry_no);
         O_exists := FALSE;
      else
         O_exists := TRUE;
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_GET_INFO_ENTRY_NO','CE_HEAD','Entry_No: '||I_entry_no);
      close C_GET_INFO_ENTRY_NO;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
         return FALSE;
END GET_INFO;
--------------------------------------------------------------------------------------
FUNCTION VALID_TRANS_ORDER_ITEM (O_error_message         IN OUT VARCHAR2,
                                 O_exists                IN OUT BOOLEAN,
                                 I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                                 I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                 I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                                 I_order_no              IN     TRANSPORTATION.ORDER_NO%TYPE,
                                 I_item                  IN     TRANSPORTATION.ITEM%TYPE)
   return BOOLEAN is

   L_exists   	      VARCHAR2(1) := NULL;
   L_item_level	      ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level	      ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_parent           ITEM_MASTER.ITEM_PARENT%TYPE;
   L_parent_desc      ITEM_MASTER.ITEM_DESC%TYPE;
   L_grandparent      ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_grandparent_desc ITEM_MASTER.ITEM_DESC%TYPE;

   cursor C_VVE_PO_ITEM(L_item  ITEM_MASTER.ITEM%TYPE) is
      select 'X'
        from transportation
       where vessel_id             = NVL(I_vessel_id, vessel_id)
         and voyage_flt_id         = NVL(I_voyage_flt_id, voyage_flt_id)
         and estimated_depart_date = NVL(I_estimated_depart_date, estimated_depart_date)
         and order_no              = NVL(I_order_no, order_no)
         and item                  = NVL(L_item, item)
         and candidate_ind         = 'Y'
         and vessel_id is not NULL
         and voyage_flt_id is not NULL
         and estimated_depart_date is not NULL
         and order_no is not NULL
         and item is not NULL;

BEGIN
   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_VVE_PO_ITEM','TRANSPORTATION','Order_No: '||to_char(I_order_no));
   open C_VVE_PO_ITEM(I_item);
   SQL_LIB.SET_MARK('FETCH','C_VVE_PO_ITEM','TRANSPORTATION','Order_No: '||to_char(I_order_no));
   fetch C_VVE_PO_ITEM into L_exists;
   if C_VVE_PO_ITEM%NOTFOUND then
      ---
      if I_item is NOT NULL then
         if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                       L_item_level,
                                       L_tran_level,
                                       I_item) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_VVE_PO_ITEM','TRANSPORTATION','Order_No: '||to_char(I_order_no));
      close C_VVE_PO_ITEM;
      if L_item_level <> 1 then
         if ITEM_ATTRIB_SQL.GET_PARENT_INFO(O_error_message,
                                            L_parent,
                                            L_parent_desc,
                                            L_grandparent,
                                            L_grandparent_desc,
                                            I_item) = FALSE then
            return FALSE;
         end if;
         SQL_LIB.SET_MARK('OPEN','C_VVE_PO_ITEM','TRANSPORTATION','Order_No: '||to_char(I_order_no));
         open C_VVE_PO_ITEM(L_parent);
         SQL_LIB.SET_MARK('FETCH','C_VVE_PO_ITEM','TRANSPORTATION','Order_No: '||to_char(I_order_no));
         fetch C_VVE_PO_ITEM into L_exists;
         if C_VVE_PO_ITEM%NOTFOUND then
            O_exists := FALSE;
            O_error_message := SQL_LIB.CREATE_MSG('INV_VVE_PO_ITEM',NULL,NULL,NULL);
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_VVE_PO_ITEM','TRANSPORTATION','Order_No: '||to_char(I_order_no));
         close C_VVE_PO_ITEM;
      else
         O_exists := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('INV_VVE_PO_ITEM',NULL,NULL,NULL);
      end if;
   else
      SQL_LIB.SET_MARK('CLOSE','C_VVE_PO_ITEM','TRANSPORTATION','Order_No: '||to_char(I_order_no));
      close C_VVE_PO_ITEM;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.VALID_TRANS_ORDER_ITEM',
                                            to_char(SQLCODE));
      return FALSE;
END VALID_TRANS_ORDER_ITEM;
-----------------------------------------------------------------------------------------------------------------
FUNCTION GET_TRANS_ORIGIN_COUNTRY(O_error_message         IN OUT  VARCHAR2,
                                  O_exists                IN OUT  BOOLEAN,
                                  O_origin_country_id     IN OUT  COUNTRY.COUNTRY_ID%TYPE,
                                  I_vessel_id             IN      TRANSPORTATION.VESSEL_ID%TYPE,
                                  I_voyage_flt_id         IN      TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                  I_estimated_depart_date IN      TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                                  I_order_no              IN      ORDHEAD.ORDER_NO%TYPE,
                                  I_item                  IN      ITEM_MASTER.ITEM%TYPE)

   return BOOLEAN is
   L_program   VARCHAR2(50)   := 'CE_SQL.GET_TRANS_ORIGIN_COUNTRY';

   cursor C_COUNTRY is
      select origin_country_id
        from transportation
       where vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item;
BEGIN
   if (I_vessel_id             is NULL or
       I_voyage_flt_id         is NULL or
       I_estimated_depart_date is NULL or
       I_order_no              is NULL or
       I_item                  is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
   ---
   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_COUNTRY','TRANSPORTATION','Order_No: '||to_char(I_order_no));
   open C_COUNTRY;
   SQL_LIB.SET_MARK('FETCH','C_COUNTRY','TRANSPORTATION','Order_No: '||to_char(I_order_no));
   fetch C_COUNTRY into O_origin_country_id;
   if C_COUNTRY%NOTFOUND then
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_COUNTRY','TRANSPORTATION','Order_No: '||to_char(I_order_no));
   close C_COUNTRY;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
 					              SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_TRANS_ORIGIN_COUNTRY;
-----------------------------------------------------------------------------------------------------------------
FUNCTION VALID_TRANS_INVOICE(O_error_message         IN OUT  VARCHAR2,
                             O_exists                IN OUT  BOOLEAN,
                             I_vessel_id             IN      TRANSPORTATION.VESSEL_ID%TYPE,
                             I_voyage_flt_id         IN      TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                             I_estimated_depart_date IN      TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                             I_invoice_id            IN      TRANSPORTATION.INVOICE_ID%TYPE)

   return BOOLEAN is
   L_program   VARCHAR2(50)   := 'CE_SQL.VALID_TRANS_INVOICE';
   L_exists    VARCHAR2(1)    := NULL;

   cursor C_INVOICE is
      select 'x'
        from transportation
       where vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and invoice_id            = I_invoice_id;

BEGIN
   if (I_vessel_id             is NULL or
       I_voyage_flt_id         is NULL or
       I_estimated_depart_date is NULL or
       I_invoice_id            is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
   ---
   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_INVOICE','TRANSPORTATION','Invoice_id: '||I_invoice_id);
   open C_INVOICE;
   SQL_LIB.SET_MARK('FETCH','C_INVOICE','TRANSPORTATION','Invoice_id: '||I_invoice_id);
   fetch C_INVOICE into L_exists;
   if C_INVOICE%NOTFOUND then
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_INVOICE','TRANSPORTATION','Invoice_id: '||I_invoice_id);
   close C_INVOICE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
 					              SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END VALID_TRANS_INVOICE;
-----------------------------------------------------------------------------------------------------------------
FUNCTION VALID_BL_AWB(O_error_message         IN OUT VARCHAR2,
                      O_exists                IN OUT BOOLEAN,
                      I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                      I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                      I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                      I_bl_awb_id             IN     TRANSPORTATION.BL_AWB_ID%TYPE,
                      I_order_no              IN     TRANSPORTATION.ORDER_NO%TYPE,
                      I_item                  IN     TRANSPORTATION.ITEM%TYPE,
                      I_invoice_id            IN     TRANSPORTATION.INVOICE_ID%TYPE)
   return BOOLEAN is

   L_program   VARCHAR2(50)   := 'CE_SQL.VALID_BL_AWB';
   L_exists    VARCHAR2(1)    := NULL;

   cursor C_BL_AWB is
      select 'x'
        from transportation t
       where t.vessel_id             = I_vessel_id
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.order_no              = I_order_no
         and t.invoice_id            = NVL(I_invoice_id,t.invoice_id)
         and (t.item                 = I_item
              or exists (select 'x'
                           from ordsku os,
                                item_master im
                          where t.order_no                   = os.order_no
                            and (im.item_parent              = t.item
                                 or im.item_grandparent      = t.item)
                            and im.item                      = os.item
                            and im.item                      = I_item)
              or exists (select 'x'
                           from trans_sku s
                          where t.transportation_id           = s.transportation_id
                            and s.item                        = I_item))
         and t.bl_awb_id = I_bl_awb_id;

BEGIN
   if (I_vessel_id             is NULL or
       I_voyage_flt_id         is NULL or
       I_estimated_depart_date is NULL or
       I_bl_awb_id             is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
   ---
   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_BL_AWB','TRANSPORTATION',NULL);
   open C_BL_AWB;
   SQL_LIB.SET_MARK('FETCH','C_BL_AWB','TRANSPORTATION',NULL);
   fetch C_BL_AWB into L_exists;
   if C_BL_AWB%NOTFOUND then
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_BL_AWB','TRANSPORTATION',NULL);
   close C_BL_AWB;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END VALID_BL_AWB;
-----------------------------------------------------------------------------------------------------------------
FUNCTION VALIDATE_ENTRY_NO(O_error_message  IN OUT VARCHAR2,
                           O_exists         IN OUT BOOLEAN,
                           I_entry_no       IN     CE_HEAD.ENTRY_NO%TYPE)
   RETURN BOOLEAN is

   L_program      VARCHAR2(50) := 'CE_SQL.VALIDATE_ENTRY_NO';
   L_entry_dummy  VARCHAR2(1);

   cursor C_ENTRY_NO is
      select 'x'
        from CE_HEAD
       where entry_no = I_entry_no;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_ENTRY_NO','CE_HEAD','Entry_No: '||I_entry_no);
   open C_ENTRY_NO;

   SQL_LIB.SET_MARK('FETCH','C_ENTRY_NO','CE_HEAD','Entry_No: '||I_entry_no);
   fetch C_ENTRY_NO into L_entry_dummy;
   if C_ENTRY_NO%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_ENTRY_NO','CE_HEAD','Entry_No: '||I_entry_no);
   close C_ENTRY_NO;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
 					              SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END VALIDATE_ENTRY_NO;
-----------------------------------------------------------------------------------------------------------------
FUNCTION VALID_TARIFF_TREATMENT(O_error_message     IN OUT VARCHAR2,
                                O_exists            IN OUT BOOLEAN,
                                I_tariff_treatment  IN     CE_ORD_ITEM.TARIFF_TREATMENT%TYPE,
                                I_item              IN     CE_ORD_ITEM.ITEM%TYPE,
                                I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE)

   return BOOLEAN is

   L_program   VARCHAR2(50)   := 'CE_SQL.VALID_TARIFF_TREATMENT';
   L_exists    VARCHAR2(1)    := NULL;

   cursor C_TT is
      select 'x'
        from tariff_treatment t
       where (t.tariff_treatment in (select cou.tariff_treatment
                                       from country_tariff_treatment cou
                                      where cou.country_id = I_origin_country_id)
           or t.tariff_treatment in (select ctt.tariff_treatment
                                       from cond_tariff_treatment ctt
                                      where item = I_item))
          and t.tariff_treatment = I_tariff_treatment;

BEGIN
   if (I_tariff_treatment  is NULL or
       I_item              is NULL or
       I_origin_country_id is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
   ---
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_TT','COUNTRY_TARIFF_TREATMENT,COND_TARIFF_TREATMENT',
                    ' Tariff Treatment: '||I_tariff_treatment);
   open C_TT;
   SQL_LIB.SET_MARK('FETCH','C_TT','COUNTRY_TARIFF_TREATMENT,COND_TARIFF_TREATMENT',
                    ' Tariff Treatment: '||I_tariff_treatment);
   fetch C_TT into L_exists;
   if C_TT%NOTFOUND then
      O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_TT','COUNTRY_TARIFF_TREATMENT,COND_TARIFF_TREATMENT',
                    ' Tariff Treatment: '||I_tariff_treatment);
   close C_TT;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
 					              SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END VALID_TARIFF_TREATMENT;
-----------------------------------------------------------------------------------------------------------------
FUNCTION CE_OBL_EXISTS(O_error_message         IN OUT VARCHAR2,
                       O_exists                IN OUT BOOLEAN,
                       I_entry_no              IN     CE_HEAD.ENTRY_NO%TYPE)

   return BOOLEAN is

   L_program   VARCHAR2(50)   := 'CE_SQL.CE_OBL_EXISTS';
   L_exists    VARCHAR2(1)    := NULL;

   cursor C_ENTRY is
      select 'x'
        from obligation
       where obligation_level = 'CUST'
         and key_value_1      = I_entry_no;

BEGIN
   if I_entry_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
   ---
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ENTRY','OBLIGATION','Entry No. :'||I_entry_no);
   open C_ENTRY;
   SQL_LIB.SET_MARK('FETCH','C_ENTRY','OBLIGATION','Entry No. :'||I_entry_no);
   fetch C_ENTRY into L_exists;

   if C_ENTRY%NOTFOUND then
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_ENTRY','OBLIGATION','Entry No. :'||I_entry_no);
   close C_ENTRY;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CE_OBL_EXISTS;
-----------------------------------------------------------------------------------------------------------------
FUNCTION GET_CE_STATUS(O_error_message         IN OUT VARCHAR2,
                       O_exists                IN OUT BOOLEAN,
                       O_status                IN OUT CE_HEAD.STATUS%TYPE,
                       I_ce_id                 IN     CE_HEAD.CE_ID%TYPE)

   return BOOLEAN is

   cursor C_GET_CE_STATUS is
      select status
        from ce_head
       where ce_id = I_ce_id;

BEGIN
   if I_ce_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC','CE_SQL.GET_CE_STATUS');
      O_exists        := FALSE;
      return FALSE;
   end if;
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_CE_STATUS','CE_HEAD','ce_id: '||to_char(I_ce_id));
   open C_GET_CE_STATUS;
   SQL_LIB.SET_MARK('FETCH','C_GET_CE_STATUS','CE_HEAD','ce_id: '||to_char(I_ce_id));
   fetch C_GET_CE_STATUS into O_status;
   ---
   if C_GET_CE_STATUS%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_CE_ID',NULL,NULL,NULL);
      O_exists        := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_CE_STATUS','CE_HEAD','ce_id: '||to_char(I_ce_id));
   close C_GET_CE_STATUS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.GET_CE_STATUS',
                                            to_char(SQLCODE));
      return FALSE;
END GET_CE_STATUS;
-----------------------------------------------------------------------------------------------------------------
FUNCTION PROCESSED_ALC_EXISTS(O_error_message         IN OUT VARCHAR2,
                              O_exists                IN OUT BOOLEAN,
                              I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                              I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                              I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                              I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                              I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                              I_item                  IN     ITEM_MASTER.ITEM%TYPE)

   return BOOLEAN is

  L_program VARCHAR2(50) := 'CE_SQL.PROCESS_ALC_EXISTS';
  L_exists  VARCHAR2(1)  := NULL;

  cursor C_ENTRY IS
     select 'X'
       from ce_ord_item
      where ce_id 		    = I_ce_id
        and alc_status              = 'R';

  cursor C_SHIPMENT IS
     select 'X'
       from ce_ord_item
      where ce_id 		    = I_ce_id
        and vessel_id    	    = I_vessel_id
        and voyage_flt_id	    = I_voyage_flt_id
        and estimated_depart_date   = I_estimated_depart_date
        and alc_status              = 'R';

  cursor C_ORD_ITEM IS
     select 'X'
       from ce_ord_item
      where ce_id 		    = I_ce_id
        and vessel_id    	    = I_vessel_id
        and voyage_flt_id	    = I_voyage_flt_id
        and estimated_depart_date   = I_estimated_depart_date
        and order_no                = I_order_no
        and item                    = I_item
        and alc_status              = 'R';

BEGIN
   if I_ce_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',L_program);
      return FALSE;
   end if;

   O_exists := FALSE;

   if I_vessel_id is NULL then
      ---   check ALC status using the CE_ID
      SQL_LIB.SET_MARK('OPEN','C_ENTRY','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
      open C_ENTRY;
      SQL_LIB.SET_MARK('FETCH','C_ENTRY','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
      fetch C_ENTRY into L_exists;

      if C_ENTRY%FOUND then
         O_exists := TRUE;
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_ENTRY','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
      close C_ENTRY;

   elsif I_order_no is NULL then
      ---   check ALC status using the CE_ID, Vessel, Voyage/Flight and Estimated Departure Date
      SQL_LIB.SET_MARK('OPEN','C_SHIPMENT','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
      open C_SHIPMENT;
      SQL_LIB.SET_MARK('FETCH','C_SHIPMENT','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
      fetch C_SHIPMENT into L_exists;

      if C_SHIPMENT%FOUND then
         O_exists := TRUE;
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_SHIPMENT','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
      close C_SHIPMENT;

   else
      ---   check ALC status using the CE_ID/V/V/E ... Order and Item
      SQL_LIB.SET_MARK('OPEN','C_ORD_ITEM','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
      open C_ORD_ITEM;
      SQL_LIB.SET_MARK('FETCH','C_ORD_ITEM','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
      fetch C_ORD_ITEM into L_exists;

      if C_ORD_ITEM%FOUND then
         O_exists := TRUE;
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_ORD_ITEM','CE_ORD_ITEM','ce_id: '||to_char(I_ce_id));
      close C_ORD_ITEM;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END PROCESSED_ALC_EXISTS;
--------------------------------------------------------------------------------------------------------
FUNCTION LICENSE_VISA_EXISTS(O_error_message         IN OUT VARCHAR2,
                             O_exists                IN OUT BOOLEAN,
                             I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                             I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                             I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                             I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                             I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                             I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                             I_license_visa_type     IN     CE_LIC_VISA.LICENSE_VISA_TYPE%TYPE,
                             I_license_visa_id       IN     CE_LIC_VISA.LICENSE_VISA_ID%TYPE)
   return BOOLEAN is

   L_program   VARCHAR2(50)   := 'CE_SQL.LICENSE_VISA_EXISTS';
   L_exists    VARCHAR2(1)    := NULL;

   cursor C_LIC_VISA_EXISTS is
      select 'x'
        from CE_LIC_VISA
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and license_visa_type     = nvl(I_license_visa_type, license_visa_type)
         and license_visa_id       = nvl(I_license_visa_id,   license_visa_id);

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LIC_VISA_EXISTS','LICENSE_VISA_EXISTS','CE_ID: '||to_char(I_ce_id));
   open C_LIC_VISA_EXISTS;

   SQL_LIB.SET_MARK('FETCH','C_LIC_VISA_EXISTS','LICENSE_VISA_EXISTS','CE_ID: '||to_char(I_ce_id));
   fetch C_LIC_VISA_EXISTS into L_exists;

   if C_LIC_VISA_EXISTS%NOTFOUND then
     O_exists := FALSE;
   else
     O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_LIC_VISA_EXISTS','LICENSE_VISA_EXISTS','CE_ID: '||to_char(I_ce_id));
   close C_LIC_VISA_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END LICENSE_VISA_EXISTS;
-----------------------------------------------------------------------------------------------------
FUNCTION CE_VVE_PO_ITEM_EXISTS(O_error_message         IN OUT VARCHAR2,
                               O_exists                IN OUT BOOLEAN,
                               I_ce_id                 IN     CE_ORD_ITEM.CE_ID%TYPE,
                               I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                               I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                               I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                               I_order_no              IN     TRANSPORTATION.ORDER_NO%TYPE,
                               I_item                  IN     TRANSPORTATION.ITEM%TYPE)
   return BOOLEAN is

   L_exists   VARCHAR2(1) := NULL;

   cursor C_EXISTS is
      select 'X'
        from ce_ord_item
       where ce_id                 = NVL(I_ce_id, ce_id)
         and vessel_id             = NVL(I_vessel_id, vessel_id)
         and voyage_flt_id         = NVL(I_voyage_flt_id, voyage_flt_id)
         and estimated_depart_date = NVL(I_estimated_depart_date, estimated_depart_date)
         and order_no              = NVL(I_order_no, order_no)
         and item                  = NVL(I_item, item);

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_EXISTS','CE_ORD_ITEM','CE_ID: '||to_char(I_ce_id));
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_EXISTS','CE_ORD_ITEM','CE_ID: '||to_char(I_ce_id));
   fetch C_EXISTS into L_exists;
   if C_EXISTS%NOTFOUND then
      O_exists        := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('INV_CE_VVE_PO_ITEM',NULL,NULL,NULL);
   else
      O_exists        := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_EXISTS','CE_ORD_ITEM','CE_ID: '||to_char(I_ce_id));
   close C_EXISTS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.CE_VVE_PO_ITEM_EXISTS',
                                            to_char(SQLCODE));
      return FALSE;
END CE_VVE_PO_ITEM_EXISTS;
---------------------------------------------------------------------------------------------------------
FUNCTION GET_CE_ID(O_error_message  IN OUT VARCHAR2,
                   O_exists         IN OUT BOOLEAN,
                   O_ce_id          IN OUT CE_HEAD.CE_ID%TYPE,
                   I_entry_no       IN     CE_HEAD.ENTRY_NO%TYPE)
   RETURN BOOLEAN IS

   cursor C_GET_CE_ID is
      select ce_id
        from ce_head
       where entry_no = I_entry_no;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_CE_ID','CE_HEAD','Entry No.: '||I_entry_no);
   open C_GET_CE_ID;
   SQL_LIB.SET_MARK('FETCH','C_GET_CE_ID','CE_HEAD','Entry No.: '||I_entry_no);
   fetch C_GET_CE_ID into O_ce_id;
   ---
   if C_GET_CE_ID%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ENTRY_NO',NULL,NULL,NULL);
      O_exists        := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_CE_ID','CE_HEAD','Entry No.: '||I_entry_no);
   close C_GET_CE_ID;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.GET_CE_ID',
                                            to_char(SQLCODE));
      return FALSE;
END GET_CE_ID;
--------------------------------------------------------------------------------------
FUNCTION GET_CURRENCY_RATE(O_error_message   IN OUT VARCHAR2,
                           O_currency_code   IN OUT CURRENCIES.CURRENCY_CODE%TYPE,
                           O_exchange_rate   IN OUT CURRENCY_RATES.EXCHANGE_RATE%TYPE,
                           I_ce_id           IN     CE_HEAD.CE_ID%TYPE)
   return BOOLEAN is

   cursor C_GET_CURRENCY is
      select currency_code,
             exchange_rate
        from ce_head
       where ce_id = I_ce_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_CURRENCY','CE_HEAD',
                    'CE Ref ID: '||to_char(I_ce_id));
   open C_GET_CURRENCY;
   SQL_LIB.SET_MARK('FETCH','C_GET_CURRENCY','CE_HEAD',
                    'CE Ref ID: '||to_char(I_ce_id));
   fetch C_GET_CURRENCY into O_currency_code,
                             O_exchange_rate;

   if C_GET_CURRENCY%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_GET_CURRENCY','CE_HEAD',
                       'CE Ref ID: '||to_char(I_ce_id));
      close C_GET_CURRENCY;
      O_error_message := SQL_LIB.CREATE_MSG('INV_CE_ID',NULL,NULL,NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_GET_CURRENCY','CE_HEAD',
                    'CE Ref ID: '||to_char(I_ce_id));
   close C_GET_CURRENCY;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.GET_CURRENCY_RATE',
                                            to_char(SQLCODE));
      return FALSE;
END GET_CURRENCY_RATE;
--------------------------------------------------------------------------------------
FUNCTION DELETE_ALC(O_error_message  IN OUT  VARCHAR2,
                    I_ce_id          IN      CE_HEAD.CE_ID%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(60)	:= 'CE_SQL_SQL.DELETE_ALC';
   L_order_no        ORDHEAD.ORDER_NO%TYPE;
   L_item            ITEM_MASTER.ITEM%TYPE;
   L_pack_item       ITEM_MASTER.ITEM%TYPE;
   ---
   L_table           VARCHAR2(30);
   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_GET_ORD is
      select distinct order_no,
             item,
             pack_item
        from alc_head
       where ce_id = I_ce_id
         and status not in ('PW','PR');

   cursor C_LOCK_ALC_COMP_LOC is
      select 'x'
        from alc_comp_loc
       where order_no = L_order_no
         and seq_no in (select seq_no
                          from alc_head
                         where ce_id    = I_ce_id
                           and order_no = L_order_no
                           and item     = L_item
                           and ((pack_item = L_pack_item
                                 and L_pack_item is not NULL)
                                or (pack_item is NULL
                                    and L_pack_item is NULL)))
         for update nowait;

   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from alc_head
       where ce_id = I_ce_id
         and status not in ('PW','PR')
         for update nowait;

BEGIN
   FOR C_rec in C_GET_ORD LOOP
      L_order_no  := C_rec.order_no;
      L_item      := C_rec.item;
      L_pack_item := C_rec.pack_item;
      ---
      L_table := 'ALC_COMP_LOC';
      SQL_LIB.SET_MARK('OPEN','C_LOC_ALC_COMP_LOC','ALC_COMP_LOC','CE ID: '||to_char(I_ce_id)||
                                                                  ', ORDER: '||to_char(L_order_no));
      open C_LOCK_ALC_COMP_LOC;
      SQL_LIB.SET_MARK('CLOSE','C_LOC_ALC_COMP_LOC','ALC_COMP_LOC','CE_ID: '||to_char(I_ce_id)||
                                                                   ', ORDER: '||to_char(L_order_no));
      close C_LOCK_ALC_COMP_LOC;
      ---
      SQL_LIB.SET_MARK('DELETE',NULL,'ALC_COMP_LOC','CE_ID: '||to_char(I_ce_id)||
                                                    ', ORDER: '||to_char(L_order_no));
      delete from alc_comp_loc
            where order_no = L_order_no
              and seq_no in (select seq_no
                               from alc_head
                              where ce_id    = I_ce_id
                                and order_no = L_order_no
                                and item     = L_item
                                and ((pack_item = L_pack_item
                                      and L_pack_item is not NULL)
                                     or (pack_item is NULL
                                         and L_pack_item is NULL)));
      -- Assessment comps will be reallocated at the end of the process
      if ALC_ALLOC_SQL.ADD_PO_TO_QUEUE(O_error_message,
                                       L_order_no) = FALSE then
         return FALSE;
      end if;
   END LOOP;
   ---
   L_order_no := NULL;
   L_table    := 'ALC_HEAD';
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOC_ALC_HEAD','ALC_HEAD','CE_ID: '||to_char(I_ce_id));
   open C_LOCK_ALC_HEAD;
   SQL_LIB.SET_MARK('CLOSE','C_LOC_ALC_HEAD','ALC_HEAD','CE_ID: '||to_char(I_ce_id));
   close C_LOCK_ALC_HEAD;
   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'ALC_HEAD','CE_ID: '||to_char(I_ce_id));
   delete from alc_head
         where ce_id = I_ce_id
           and status not in ('PW','PR');
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_ce_id),
                                            to_char(L_order_no));
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_ALC;
--------------------------------------------------------------------------------
FUNCTION CHARGES_EXIST(O_error_message          IN OUT  VARCHAR2,
                       O_exists                 IN OUT  BOOLEAN,
                       I_ce_id                  IN      CE_CHARGES.CE_ID%TYPE,
                       I_vessel_id              IN      TRANSPORTATION.VESSEL_ID%TYPE,
                       I_voyage_flt_id          IN      TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                       I_estimated_depart_date  IN      TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                       I_order_no               IN      ORDHEAD.ORDER_NO%TYPE,
                       I_item                   IN      ITEM_MASTER.ITEM%TYPE)
         RETURN BOOLEAN is

   L_program     VARCHAR2(50) := 'CE_SQL.CHARGES_EXIST';
   L_exists      VARCHAR2(1)  := 'N';
   L_buyer_pack  VARCHAR2(1)  := 'N';

   cursor C_BUYER_PACK is
      select 'Y'
        from item_master
       where item = I_item
         and pack_type = 'B';

   cursor C_CUSTOM_ENTRY_ID is
      select 'Y'
        from ce_charges
       where ce_id = I_ce_id;

   cursor C_CHARGE_EXISTS is
      select 'Y'
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and ((item                = I_item
               and L_buyer_pack    = 'N')
             or (pack_item         = I_item
                 and L_buyer_pack  = 'Y'));
BEGIN

   if I_ce_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',L_program);
      return FALSE;
   end if;

   O_exists := TRUE;

   if (I_vessel_id             is NULL and
       I_voyage_flt_id         is NULL and
       I_estimated_depart_date is NULL and
       I_order_no              is NULL and
       I_item                  is NULL) then

      SQL_LIB.SET_MARK('OPEN','C_CUSTOM_ENTRY_ID','CE_CHARGES','CE ID: '||to_char(I_ce_id));
      open C_CUSTOM_ENTRY_ID;
      SQL_LIB.SET_MARK('FETCH','C_CUSTOM_ENTRY_ID','CE_CHARGES','CE ID: '||to_char(I_ce_id));
      fetch C_CUSTOM_ENTRY_ID into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_CUSTOM_ENTRY_ID','CE_CHARGES','CE ID: '||to_char(I_ce_id));
      close C_CUSTOM_ENTRY_ID;
      ---
      if L_exists = 'N' then
         O_exists := FALSE;
      end if;
   else
      SQL_LIB.SET_MARK('OPEN','C_BUYER_PACK','PACKHEAD',NULL);
      open C_BUYER_PACK;
      SQL_LIB.SET_MARK('FETCH','C_BUYER_PACK','PACKHEAD',NULL);
      fetch C_BUYER_PACK into L_buyer_pack;
      SQL_LIB.SET_MARK('CLOSE','C_BUYER_PACK','PACKHEAD',NULL);
      close C_BUYER_PACK;
      ---
      SQL_LIB.SET_MARK('OPEN','C_CHARGE_EXISTS','CE_CHARGES',NULL);
      open C_CHARGE_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_CHARGE_EXISTS','CE_CHARGES',NULL);
      fetch C_CHARGE_EXISTS into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_CHARGE_EXISTS','CE_CHARGES',NULL);
      close C_CHARGE_EXISTS;
      ---
      if L_exists = 'N' then
         O_exists := FALSE;
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
END CHARGES_EXIST;
--------------------------------------------------------------------------------------
FUNCTION UPDATE_ORD_ITEM_ALC_STATUS(O_error_message          IN OUT  VARCHAR2,
                                    I_alc_status             IN      CE_ORD_ITEM.ALC_STATUS%TYPE,
                                    I_ce_id                  IN      CE_CHARGES.CE_ID%TYPE,
                                    I_vessel_id              IN      TRANSPORTATION.VESSEL_ID%TYPE,
                                    I_voyage_flt_id          IN      TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                    I_estimated_depart_date  IN      TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                                    I_order_no               IN      ORDHEAD.ORDER_NO%TYPE,
                                    I_item                   IN      ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program      VARCHAR2(50) := 'CE_SQL.UPDATE_ORD_ITEM_ALC_STATUS';
   L_exists       VARCHAR2(1);
   L_table        VARCHAR2(30) := 'CE_ORD_ITEM';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);


   cursor C_LOCK_ORDER_NO is
      select 'X'
        from CE_ORD_ITEM
       where order_no    = I_order_no
         and alc_status != 'R'
         for update nowait;

   cursor C_LOCK_CE_ID is
      select 'X'
        from CE_ORD_ITEM
       where ce_id       = I_ce_id
         and alc_status != 'R'
         for update nowait;

   cursor C_LOCK_ORDER_ITEM is
      select 'X'
        from CE_ORD_ITEM
       where order_no    = I_order_no
         and item        = I_item
         and alc_status != 'R'
         for update nowait;

   cursor C_LOCK_ALL is
      select 'X'
        from CE_ORD_ITEM
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and alc_status           != 'R'
         for update nowait;

BEGIN

   if (I_ce_id                 is not NULL and
       I_vessel_id             is not NULL and
       I_voyage_flt_id         is not NULL and
       I_estimated_depart_date is not NULL and
       I_order_no              is not NULL and
       I_item                  is not NULL) then

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL','CE_ORD_ITEM',NULL);
      open C_LOCK_ALL;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL','CE_ORD_ITEM',NULL);
      close C_LOCK_ALL;

         update ce_ord_item
            set alc_status = I_alc_status
          where ce_id                 = I_ce_id
            and vessel_id             = I_vessel_id
            and voyage_flt_id         = I_voyage_flt_id
            and estimated_depart_date = I_estimated_depart_date
            and order_no              = I_order_no
            and item                  = I_item
            and alc_status           != 'R';

   elsif (I_order_no is not NULL and
          I_item     is not NULL) then

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDER_ITEM','CE_ORD_ITEM',NULL);
      open C_LOCK_ORDER_ITEM;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDER_ITEM','CE_ORD_ITEM',NULL);
      close C_LOCK_ORDER_ITEM;

         update ce_ord_item
            set alc_status  = I_alc_status
          where order_no    = I_order_no
            and item        = I_item
            and alc_status != 'R';


   elsif I_order_no is not NULL then

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDER_NO','CE_ORD_ITEM',NULL);
      open C_LOCK_ORDER_NO;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDER_NO','CE_ORD_ITEM',NULL);
      close C_LOCK_ORDER_NO;

         update ce_ord_item
            set alc_status  = I_alc_status
          where order_no    = I_order_no
            and alc_status != 'R';

   elsif I_ce_id is not NULL then

      SQL_LIB.SET_MARK('OPEN','C_LOCK_CE_ID','CE_ORD_ITEM',NULL);
      open C_LOCK_CE_ID;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_CE_ID','CE_ORD_ITEM',NULL);
      close C_LOCK_CE_ID;

         update ce_ord_item
            set alc_status  = I_alc_status
          where ce_id       = I_ce_id
            and alc_status != 'R';

   end if;

   return TRUE;

   EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('CE_ORD_ITEM',
                                            L_table,
                                            to_char(I_ce_id));
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'L_program',
                                             to_char(SQLCODE));
         return FALSE;

END UPDATE_ORD_ITEM_ALC_STATUS;

--------------------------------------------------------------------------------------
FUNCTION GET_CE_ALC_STATUS(O_error_message   IN OUT  VARCHAR2,
                           O_alc_status      IN OUT  CE_ORD_ITEM.ALC_STATUS%TYPE,
                           I_ce_id           IN      CE_HEAD.CE_ID%TYPE,
                           I_order_no        IN      ORDHEAD.ORDER_NO%TYPE)
   RETURN BOOLEAN is

   L_program  VARCHAR2(50) := 'CE_SQL.GET_CE_ALC_STATUS';
   L_exists   VARCHAR2(1);

   cursor C_CE_ORD_ITEM_EXISTS is
      select 'Y'
        from CE_ORD_ITEM
       where ((ce_id = I_ce_id
               and I_ce_id is not NULL)
              or (order_no = I_order_no
               and I_order_no is not NULL));

   cursor C_CE_ORD_ITEM_PEND is
      select 'Y'
        from CE_ORD_ITEM
       where ((ce_id = I_ce_id
               and I_ce_id is not NULL)
              or (order_no = I_order_no
               and I_order_no is not NULL))
         and alc_status = 'P';

   cursor C_CE_ORD_ITEM_ALLOC is
      select 'Y'
        from CE_ORD_ITEM
       where ((ce_id = I_ce_id
               and I_ce_id is not NULL)
              or (order_no = I_order_no
               and I_order_no is not NULL))
         and alc_status = 'A';


BEGIN
   if (I_ce_id    is NULL and
       I_order_no is NULL)or
      (I_ce_id    is not NULL and
       I_order_no is not NULL)then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
  ---
   SQL_LIB.SET_MARK('OPEN','C_CE_ORD_ITEM_EXISTS','CE_ORD_ITEM','CE ID: '||to_char(I_ce_id));
   open C_CE_ORD_ITEM_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_CE_ORD_ITEM_EXISTS','CE_ORD_ITEM','CE ID: '||to_char(I_ce_id));
   fetch C_CE_ORD_ITEM_EXISTS into L_exists;

   if C_CE_ORD_ITEM_EXISTS%NOTFOUND then
      O_alc_status    := 'P';
   else

      SQL_LIB.SET_MARK('OPEN','C_CE_ORD_ITEM_PEND','CE_ORD_ITEM','CE ID: '||to_char(I_ce_id));
      open C_CE_ORD_ITEM_PEND;
      SQL_LIB.SET_MARK('FETCH','C_CE_ORD_ITEM_PEND','CE_ORD_ITEM','CE ID: '||to_char(I_ce_id));
      fetch C_CE_ORD_ITEM_PEND into L_exists;

      if C_CE_ORD_ITEM_PEND%NOTFOUND then

         SQL_LIB.SET_MARK('OPEN','C_CE_ORD_ITEM_ALLOC','CE_ORD_ITEM','CE ID: '||to_char(I_ce_id));
         open C_CE_ORD_ITEM_ALLOC;
         SQL_LIB.SET_MARK('FETCH','C_CE_ORD_ITEM_ALLOC','CE_ORD_ITEM','CE ID: '||to_char(I_ce_id));
         fetch C_CE_ORD_ITEM_ALLOC into L_exists;

         if C_CE_ORD_ITEM_ALLOC%NOTFOUND then
            O_alc_status := 'R';
         else
            O_alc_status := 'A';
         end if;

         SQL_LIB.SET_MARK('CLOSE','C_CE_ORD_ITEM_ALLOC','CE_ORD_ITEM','CE ID: '||to_char(I_ce_id));
         close C_CE_ORD_ITEM_ALLOC ;

      else
         O_alc_status    := 'P';

      end if;

      SQL_LIB.SET_MARK('CLOSE','C_CE_ORD_ITEM_PEND','CE_ORD_ITEM','CE ID: '||to_char(I_ce_id));
      close C_CE_ORD_ITEM_PEND;

   end if;

   SQL_LIB.SET_MARK('CLOSE','C_CE_ORD_ITEM_EXISTS','CE_ORD_ITEM','CE ID: '||to_char(I_ce_id));
   close C_CE_ORD_ITEM_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_CE_ALC_STATUS;
-----------------------------------------------------------------------------------------------------------------
FUNCTION GET_ORD_ITEM_TRAN_INFO(O_error_message         IN OUT  VARCHAR2,
                                O_exists                IN OUT  BOOLEAN,
                                O_invoice_date          OUT     TRANSPORTATION.INVOICE_DATE%TYPE,
                                O_invoice_amt           OUT     TRANSPORTATION.INVOICE_AMT%TYPE,
                                O_currency_code         OUT     TRANSPORTATION.CURRENCY_CODE%TYPE,
                                O_exchange_rate         OUT     TRANSPORTATION.EXCHANGE_RATE%TYPE,
                                O_item_qty              OUT     TRANSPORTATION.ITEM_QTY%TYPE,
                                O_item_qty_uom          OUT     TRANSPORTATION.ITEM_QTY_UOM%TYPE,
                                I_vessel_id             IN      TRANSPORTATION.VESSEL_ID%TYPE,
                                I_voyage_flt_id         IN      TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                I_estimated_depart_date IN      TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                                I_order_no              IN      TRANSPORTATION.ORDER_NO%TYPE,
                                I_item                  IN      TRANSPORTATION.ITEM%TYPE,
                                I_invoice_id            IN      TRANSPORTATION.INVOICE_ID%TYPE,
                                I_origin_country_id     IN      COUNTRY.COUNTRY_ID%TYPE)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(50)                    := 'CE_SQL.GET_ORD_ITEM_TRAN_INFO';
   L_supplier             SUPS.SUPPLIER%TYPE;
   L_invoice_amt          TRANSPORTATION.INVOICE_AMT%TYPE := 0;
   L_item_qty             TRANSPORTATION.ITEM%TYPE;
   L_carton_qty           TRANSPORTATION.CARTON_QTY%TYPE  := 0;
   L_carton_uom           UOM_CLASS.UOM%TYPE;
   L_gross_wt             TRANSPORTATION.GROSS_WT%TYPE    := 0;
   L_gross_wt_uom         UOM_CLASS.UOM%TYPE;
   L_net_wt               TRANSPORTATION.NET_WT%TYPE      := 0;
   L_net_wt_uom           UOM_CLASS.UOM%TYPE;
   L_cubic                TRANSPORTATION.CUBIC%TYPE       := 0;
   L_cubic_uom            UOM_CLASS.UOM%TYPE;
   L_transportation_id    TRANSPORTATION.TRANSPORTATION_ID%TYPE;
   L_level                VARCHAR2(1);
   L_order_item_qty       ORDLOC.QTY_ORDERED%TYPE;
   L_order_total_qty      ORDLOC.QTY_ORDERED%TYPE;
   L_ord_currency_code    TRANSPORTATION.CURRENCY_CODE%TYPE  := NULL;
   L_ord_exchange_rate    TRANSPORTATION.EXCHANGE_RATE%TYPE  := NULL;
   L_unit_cost            ORDLOC.UNIT_COST%TYPE;
   L_quantity_uom         TRANS_SKU.QUANTITY_UOM%TYPE;
   L_transportation_item  TRANSPORTATION.ITEM%TYPE;

   cursor C_GET_CO_BL is
      select t.item,
             t.container_id,
             t.bl_awb_id,
             t.transportation_id,
             'x' lvlflag
        from transportation t,
             item_master im
       where t.vessel_id             = I_vessel_id
         and t.order_no              = I_order_no
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.invoice_id            = I_invoice_id
         and t.item                  = I_item
         and t.item                  = im.item
      UNION ALL
      select t.item,
             t.container_id,
             t.bl_awb_id,
             t.transportation_id,
             'y' lvlflag
        from transportation t,
             item_master im,
             trans_sku ts
       where t.vessel_id             = I_vessel_id
         and t.order_no              = I_order_no
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.invoice_id            = I_invoice_id
         and ts.item                 = I_item
         and t.item                  = im.item
         and im.item_level           < im.tran_level
         and t.transportation_id     = ts.transportation_id
      UNION ALL
      select t.item,
             t.container_id,
             t.bl_awb_id,
             t.transportation_id,
             'z' lvlflag
        from transportation t,
             ordhead o,
             item_master im,
             ordsku os
       where t.order_no              = o.order_no
         and t.vessel_id             = I_vessel_id
         and t.order_no	             = I_order_no
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.invoice_id            = I_invoice_id
         and os.item                 = I_item
         and t.item                  = im.item
         and im.item_level           < im.tran_level
         and o.order_no              = os.order_no
         and not exists (select 'x'
                            from trans_sku ts
                           where t.transportation_id = ts.transportation_id
                             and ts.item             = I_item)
         and exists (select 'x'
                       from item_master im2
                      where (im2.item_parent        = im.item
                            or im2.item_grandparent = im.item)
                        and im2.item                = os.item);

   cursor C_INVOICE_INFO is
      select distinct t.invoice_date,
                      t.currency_code,
                      t.exchange_rate
        from transportation t
       where t.vessel_id             = I_vessel_id
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.invoice_id            = I_invoice_id
         and t.order_no              = I_order_no
         and ((t.item                = I_item)
             or (exists (select 'x'
                           from item_master im
                          where im.item = I_item
                            and (im.item_parent = t.item
                                 or im.item_grandparent = t.item))));

   cursor C_SUM_TRANS_SKU is
      select NVL(SUM(quantity),0)
        from trans_sku
       where transportation_id = L_transportation_id;

   cursor C_TRANS_SKU is
      select t.quantity,
             t.quantity_uom,
             ol.unit_cost,
             oh.currency_code,
             oh.exchange_rate
        from trans_sku  t,
             ordloc    ol,
             ordhead   oh
       where t.transportation_id = L_transportation_id
         and oh.order_no         = ol.order_no
         and ol.order_no         = I_order_no
         and ol.item             = t.item
         and t.item              = I_item;

   cursor C_SUM_ORDLOC is
      select NVL(SUM(qty_ordered),0)
        from ordloc
       where order_no = I_order_no;

   cursor C_ORDLOC is
      select NVL(SUM(ol.qty_ordered),0) qty,
             im.standard_uom,
             ol.unit_cost,
             oh.currency_code,
             oh.exchange_rate
        from ordloc    ol,
             ordhead   oh,
             item_master im
       where oh.order_no         = I_order_no
         and ol.order_no         = oh.order_no
         and ol.item             = im.item
         and im.item             = I_item
         and im.item_level       = im.tran_level
    group by ol.item,
             im.standard_uom,
             ol.unit_cost,
             oh.currency_code,
             oh.exchange_rate;

BEGIN
   if (I_vessel_id             is NULL or
       I_voyage_flt_id         is NULL or
       I_estimated_depart_date is NULL or
       I_order_no              is NULL or
       I_item                  is NULL or
       I_invoice_id            is NULL) then

      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',
                                            L_program);
      return FALSE;
   end if;
   ---
   if ORDER_ATTRIB_SQL.GET_SUPPLIER(O_error_message,
                                    O_exists,
                                    L_supplier,
                                    I_order_no) = FALSE then
      return FALSE;
   end if;
   ---
   O_exists := TRUE;
   ---
   O_item_qty := 0;
   O_invoice_amt := 0;
   ---
   O_invoice_date := NULL;
   SQL_LIB.SET_MARK('OPEN',
                    'C_INVOICE_INFO',
                    'TRANSPORTATION',
                    'Invoice_id: '||I_invoice_id);

   open C_INVOICE_INFO;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVOICE_INFO',
                    'TRANSPORTATION',
                    'Invoice_id: '||I_invoice_id);

   fetch C_INVOICE_INFO into O_invoice_date,
                             L_ord_currency_code,
                             L_ord_exchange_rate;

   if O_invoice_date is NULL and
      L_ord_currency_code is NULL and
      L_ord_exchange_rate is NULL then
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVOICE_INFO',
                    'TRANSPORTATION',
                    'Invoice_id: '||I_invoice_id);

   close C_INVOICE_INFO;
   ---
   for C_rec in C_GET_CO_BL loop

      L_transportation_id     := C_rec.transportation_id;
      L_level                 := C_rec.lvlflag;
      L_transportation_item   := C_rec.item;

      --- L_level is a flag set in C_GET_CO_BL.
      --- It is selected into the alias 'lvlflg' and set, in the
      --- cursor, to L_level.  'y' indicates information
      --- is being pulled from the trans_sku table and 'z' indicates
      --- that information is being pulled from ordloc.
       if L_level = 'y' then  --- trans_sku
         ---
         SQL_LIB.SET_MARK('OPEN',
                    'C_SUM_TRANS_SKU',
                    'TRANS_SKU',
                    'Transportation_ID: '||L_transportation_id);

         open C_SUM_TRANS_SKU;

         SQL_LIB.SET_MARK('FETCH',
                    'C_SUM_TRANS_SKU',
                    'TRANS_SKU',
                    'Transportation_ID: '||L_transportation_id);

         fetch C_SUM_TRANS_SKU into L_order_total_qty;

         SQL_LIB.SET_MARK('CLOSE',
                    'C_SUM_TRANS_SKU',
                    'TRANS_SKU',
                    'Transportation_ID: '||L_transportation_id);

         close C_SUM_TRANS_SKU;
         ---
         SQL_LIB.SET_MARK('OPEN',
                    'C_TRANS_SKU',
                    'ORDLOC',
                    'Order_no: '||I_order_no);

         open C_TRANS_SKU;

         SQL_LIB.SET_MARK('FETCH',
                    'C_TRANS_SKU',
                    'ORDLOC',
                    'Order_no: '||I_order_no);

         fetch C_TRANS_SKU into L_order_item_qty,
                                L_quantity_uom,
                                L_unit_cost,
                                L_ord_currency_code,
                                L_ord_exchange_rate;

         SQL_LIB.SET_MARK('CLOSE',
                    'C_TRANS_SKU',
                    'ORDLOC',
                    'Order_no: '||I_order_no);

         close C_TRANS_SKU;
         ---
      elsif L_level = 'z' then  ---ordloc table
         ---
         SQL_LIB.SET_MARK('OPEN',
                    'C_SUM_ORDLOC',
                    'ORDLOC',
                    'Order_no: '||I_order_no);

         open C_SUM_ORDLOC;

         SQL_LIB.SET_MARK('FETCH',
                    'C_SUM_ORDLOC',
                    'ORDLOC',
                    'Order_no: '||I_order_no);

         fetch C_SUM_ORDLOC into L_order_total_qty;

         SQL_LIB.SET_MARK('CLOSE',
                    'C_SUM_ORDLOC',
                    'ORDLOC',
                    'Order_no: '||I_order_no);

         close C_SUM_ORDLOC;
         ---
         SQL_LIB.SET_MARK('OPEN',
                    'C_ORDLOC',
                    'ORDLOC',
                    'Order_no: '||I_order_no);

         open C_ORDLOC;

         SQL_LIB.SET_MARK('FETCH',
                    'C_ORDLOC',
                    'ORDLOC',
                    'Order_no: '||I_order_no);

         fetch C_ORDLOC into L_order_item_qty,
                             L_quantity_uom,
                             L_unit_cost,
                             L_ord_currency_code,
                             L_ord_exchange_rate;

         SQL_LIB.SET_MARK('CLOSE',
                    'C_ORDLOC',
                    'ORDLOC',
                    'Order_no: '||I_order_no);

         close C_ORDLOC;
         ---
      end if;

      if TRANSPORTATION_SQL.GET_QTYS(O_error_message,
                                     L_carton_qty,
                                     L_carton_uom,
                                     L_item_qty,
                                     O_item_qty_uom,
                                     L_gross_wt,
                                     L_gross_wt_uom,
                                     L_net_wt,
                                     L_net_wt_uom,
                                     L_cubic,
                                     L_cubic_uom,
                                     L_invoice_amt,
                                     L_supplier,
                                     I_origin_country_id,
                                     I_vessel_id,
                                     I_voyage_flt_id,
                                     I_estimated_depart_date,
                                     I_order_no,
                                     L_transportation_item,
                                     C_rec.container_id,  --- O_container_id,
                                     C_rec.bl_awb_id,     --- O_bl_awb_id,
                                     I_invoice_id,
                                     L_ord_currency_code,                --- O_currency_code,
                                     L_ord_exchange_rate) = FALSE then   --- O_exchange_rate
         return FALSE;
      end if;
      ---
      if L_level = 'z' then
         ---
         if L_order_item_qty = 0 then
            L_order_item_qty := 1;
         end if;

         --- find ratios of item quantities on trans_sku/ordloc to total
         --- quantity on transportation and insert as manifest_item_qty

         L_item_qty     := L_item_qty  * (L_order_item_qty / L_order_total_qty);
         L_invoice_amt  := L_unit_cost * L_item_qty;

      elsif L_level = 'y' then
         -- data is from trans_sku or transportation.
         -- detail-level qtys from trans_sku should override
         -- header-level item_qty from transportation

         L_item_qty     := L_order_item_qty;
         L_invoice_amt  := L_unit_cost * L_item_qty;
      end if;

      O_item_qty    := O_item_qty    +  L_item_qty;
      O_invoice_amt := O_invoice_amt +  L_invoice_amt;

   end loop;

   O_currency_code := L_ord_currency_code;
   O_exchange_rate := L_ord_exchange_rate;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_ORD_ITEM_TRAN_INFO;
-----------------------------------------------------------------------------------------------------------------
FUNCTION INVOICE_EXIST(O_error_message         IN OUT VARCHAR2,
                       O_exists                IN OUT BOOLEAN,
                       I_vessel_id             IN     CE_ORD_ITEM.VESSEL_ID%TYPE,
                       I_voyage_id             IN     CE_ORD_ITEM.VOYAGE_FLT_ID%TYPE,
                       I_estimated_depart_date IN     CE_ORD_ITEM.ESTIMATED_DEPART_DATE%TYPE,
                       I_order_no              IN     CE_ORD_ITEM.ORDER_NO%TYPE,
                       I_item                  IN     CE_ORD_ITEM.ITEM%TYPE,
                       I_invoice_id            IN     CE_ORD_ITEM.INVOICE_ID%TYPE,
                       I_ce_id                 IN     CE_ORD_ITEM.CE_ID%TYPE)
   return BOOLEAN is

   L_program      VARCHAR2(60)  := 'CE_SQL.INVOICE_EXIST';
   L_exists       VARCHAR2(1)   := NULL;

   cursor C_INVOICE_EXIST is
      select 'Y'
        from ce_ord_item
       where vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and invoice_id            = I_invoice_id
         and ce_id                <> I_ce_id;

   cursor C_MULTIPLE_EXIST is
      select 'Y'
        from ce_ord_item
       where vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and invoice_id           <> I_invoice_id
         and ce_id                 = I_ce_id;

BEGIN

   ---
   -- First check for another CE with the same VVE/Order/Item/Invoice
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_INVOICE_EXIST',
                    'CE_ORD_ITEM',
                    'Order No: '||I_order_no);
   open C_INVOICE_EXIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVOICE_EXIST',
                    'CE_ORD_ITEM',
                    'Order No: '||I_order_no);
   fetch C_INVOICE_EXIST into L_exists;

   if L_exists is NOT NULL then
      O_exists := TRUE;
      O_error_message := 'DUP_CE_INVC';
      return TRUE;
   else
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVOICE_EXIST',
                    'CE_ORD_ITEM',
                    'Order No: '||I_order_no);
   close C_INVOICE_EXIST;
   ---
   L_exists :=NULL;
   -- Then check for a different Invoice on the CE for the same VVE/Order/Item
   ---
   if O_exists = FALSE then
      SQL_LIB.SET_MARK('OPEN',
                       'C_MULTIPLE_EXIST',
                       'CE_ORD_ITEM',
                       'Order No: '||I_order_no);
      open C_MULTIPLE_EXIST;

      SQL_LIB.SET_MARK('FETCH',
                       'C_MULTIPLE_EXIST',
                       'CE_ORD_ITEM',
                       'Order No: '||I_order_no);
      fetch C_MULTIPLE_EXIST into L_exists;

      if L_exists is NOT NULL then
         O_exists := TRUE;
         O_error_message := 'DUP_INVC_CE';
         return TRUE;
      else
         O_exists := FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_MULTIPLE_EXIST',
                       'CE_ORD_ITEM','Order No:
                       '||I_order_no);
      close C_MULTIPLE_EXIST;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INVOICE_EXIST;
-----------------------------------------------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                  O_exists         IN OUT  BOOLEAN,
                  O_ce_head_row    IN OUT  CE_HEAD%ROWTYPE,
                  I_ce_id          IN      CE_HEAD.CE_ID%TYPE,
                  I_entry_no       IN      CE_HEAD.ENTRY_NO%TYPE)
return BOOLEAN is

   L_program VARCHAR(50) := 'CE_SQL.GET_INFO';

   cursor C_GET_INFO is
      select *
        from ce_head
       where ce_id    = NVL(I_ce_id, ce_id)
         and entry_no = NVL(I_entry_no, entry_no);

BEGIN

   O_ce_head_row := NULL;
   O_exists      := FALSE;

   if I_ce_id is NULL and I_entry_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG',
                                            'I_ce_id/I_entry_no',
                                            'NULL',
                                            L_program);
      return FALSE;
   end if;

   open  C_GET_INFO;
   fetch C_GET_INFO into O_ce_head_row;
   close C_GET_INFO;

   if O_ce_head_row.ce_id is NOT NULL then
      O_exists := TRUE;
   else
      if I_ce_id is NOT NULL then
         O_error_message := SQL_LIB.CREATE_MSG('NO_CE_INFO', to_char(I_ce_id));
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_ENTRY_NO_INFO', I_entry_no);
      end if;
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
         return FALSE;
END GET_INFO;
----------------------------------------------------------------------------------------------------------------
FUNCTION VALID_INVOICE(O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_exists                IN OUT BOOLEAN,
                       I_vessel_id             IN     TRANSPORTATION.VESSEL_ID%TYPE,
                       I_voyage_flt_id         IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                       I_estimated_depart_date IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                       I_order_no              IN     TRANSPORTATION.ORDER_NO%TYPE,
                       I_item                  IN     TRANSPORTATION.ITEM%TYPE,
                       I_bl_awb_id             IN     TRANSPORTATION.BL_AWB_ID%TYPE,
                       I_invoice_id            IN     TRANSPORTATION.INVOICE_ID%TYPE)
  return BOOLEAN IS

   cursor C_INVOICE is
      select 'x'
        from transportation t
       where t.vessel_id             = I_vessel_id
         and t.voyage_flt_id         = I_voyage_flt_id
         and t.estimated_depart_date = I_estimated_depart_date
         and t.order_no              = I_order_no
         and (I_bl_awb_id            = t.bl_awb_id
              or I_bl_awb_id         = 'MULTI'
              or I_bl_awb_id         is null)
         and t.invoice_id            = I_invoice_id
         and (t.item                 = I_item
              or exists (select 'x'
                           from ordsku os, item_master im
                          where t.order_no                   = os.order_no
                            and (im.item_parent              = t.item
                                 or im.item_grandparent      = t.item)
                            and im.item                      = os.item
                            and im.item                      = I_item)
              or exists (select 'x'
                          from trans_sku s
                         where t.transportation_id           = s.transportation_id
                           and s.item                        = I_item));

   L_invoice_exists        varchar2(1)  :=NULL;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_INVOICE',
                    'TRANSPORTATION',
                    NULL);
   open C_INVOICE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVOICE',
                    'TRANSPORTATION',
                    NULL);
   fetch C_INVOICE into L_invoice_exists;

   if L_invoice_exists is NOT NULL then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVOICE',
                    'TRANSPORTATION',
                    NULL);
   close C_INVOICE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CE_SQL.VALID_INVOICE',
                                            to_char(SQLCODE));
      return FALSE;
END VALID_INVOICE;
-----------------------------------------------------------------------------------------------------------------
FUNCTION CHECK_CANDIDATE_IND_NO(O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                O_exists                  IN OUT   BOOLEAN,
                                I_vessel_id               IN       TRANSPORTATION.VESSEL_ID%TYPE,
                                I_voyage_flt_id           IN       TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                                I_estimated_depart_date   IN       TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE)

   return  BOOLEAN IS

   L_program VARCHAR2(50) := 'CE_SQL.CHECK_CANDIDATE_IND_NO';
   L_exists  VARCHAR2(1)  := NULL;

   cursor C_CHECK_CANDIDATE_IND_NO IS
      select 'X'
        from transportation
       where vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and candidate_ind         = 'N'
         and rownum                = 1;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_CANDIDATE_IND_NO',
                    'TRANSPORTATION',
                    'VESSEL ID: '||I_vessel_id||
                    'VOYAGE FLT ID: '||I_voyage_flt_id||
                    'ESTIMATED DEPART DATE: '||I_estimated_depart_date);
   open C_CHECK_CANDIDATE_IND_NO;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_CANDIDATE_IND_NO',
                    'TRANSPORTATION',
                    'VESSEL ID: '||I_vessel_id||
                    'VOYAGE FLT ID: '||I_voyage_flt_id||
                    'ESTIMATED DEPART DATE: '||I_estimated_depart_date);
   fetch C_CHECK_CANDIDATE_IND_NO into L_exists;

   if L_exists is NULL then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_CANDIDATE_IND_NO',
                    'TRANSPORTATION',
                    'VESSEL ID: '||I_vessel_id||
                    'VOYAGE FLT ID: '||I_voyage_flt_id||
                    'ESTIMATED DEPART DATE: '||I_estimated_depart_date);
   close C_CHECK_CANDIDATE_IND_NO;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_CANDIDATE_IND_NO;
-----------------------------------------------------------------------------------------------------------------

END CE_SQL;
/

