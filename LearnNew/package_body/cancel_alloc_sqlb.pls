CREATE OR REPLACE PACKAGE BODY CANCEL_ALLOC_SQL AS
-----------------------------------------------------------------------------------------------------

FUNCTION CANCEL_SINGLE_ALLOC(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_order_no        IN       ALLOC_HEADER.ORDER_NO%TYPE)
RETURN BOOLEAN is
   cursor C_CLOSE_ALH is
   select   alloc_no
     from   alloc_header     alh
    where   alh.order_no     = I_order_no
      and   alh.release_date < (select (per.vdate - to_number(cdd.code_desc))
                                     from  period        per,
                                           code_detail   cdd
                                    where  cdd.code_type = 'DEFT'
                                      and  cdd.code      = 'DATE');

   L_alloc_no    ALLOC_HEADER.ALLOC_NO%TYPE;

   cursor C_LOCK_ALD is
         select   1
           from   alloc_detail     ald
          where   ald.alloc_no = L_alloc_no
            for   update nowait;

   CURSOR C_CLOSE_ALLOC_TIER IS
      SELECT alloc_no
        FROM alloc_header
       WHERE alloc_parent = L_alloc_no;

   L_tier_alloc_no  ALLOC_HEADER.ALLOC_NO%TYPE;
   L_program     VARCHAR2(50) := 'CANCEL_ALLOC_SQL.CANCEL_SINGLE_ALLOC';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);
   L_closed      BOOLEAN;
BEGIN

   if I_order_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG','I_ORDER_NO',NULL,NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('LOOP',' C_CLOSE_ALH ','alloc_header','order no: '||TO_CHAR(I_order_no));
   FOR C_close_alh_rec in C_CLOSE_ALH LOOP
      L_alloc_no := C_close_alh_rec.alloc_no;
      SQL_LIB.SET_MARK('OPEN',' C_LOCK_ALD ','alloc_detail','alloc no: '||TO_CHAR(L_alloc_no));
      open C_LOCK_ALD;
      SQL_LIB.SET_MARK('CLOSE',' C_LOCK_ALD ','alloc_detail','alloc no: '||TO_CHAR(L_alloc_no));
      close C_LOCK_ALD;

      SQL_LIB.SET_MARK('UPDATE',NULL,'alloc_detail','alloc no: '||TO_CHAR(L_alloc_no));
      update alloc_detail
         set qty_allocated = GREATEST(NVL(qty_transferred,0),NVL(qty_received,0)),
             qty_cancelled = qty_allocated - GREATEST(NVL(qty_transferred,0),NVL(qty_received,0))
       where alloc_no      = L_alloc_no;


      if APPT_DOC_CLOSE_SQL.CLOSE_ALLOC(O_error_message,
                                        L_closed,
                                        L_alloc_no) = FALSE then
          return FALSE;
      end if;

      FOR c_close_alloc_tier_rec IN C_CLOSE_ALLOC_TIER LOOP
         L_tier_alloc_no := c_close_alloc_tier_rec.alloc_no;
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_ALD',
                          'ALLOC_DETAIL',
                          'alloc no: '||TO_CHAR(L_tier_alloc_no));
         OPEN C_LOCK_ALD;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_ALD',
                          'ALLOC_DETAIL',
                          'alloc no: '||TO_CHAR(L_tier_alloc_no));
         CLOSE C_LOCK_ALD;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ALLOC_DETAIL',
                          'alloc no: '||TO_CHAR(L_tier_alloc_no));
         UPDATE alloc_detail
            SET qty_allocated = GREATEST(NVL(qty_transferred,0),NVL(qty_received,0)),
                qty_cancelled = qty_allocated - GREATEST(NVL(qty_transferred,0),NVL(qty_received,0))
          WHERE alloc_no      = L_tier_alloc_no;

         IF APPT_DOC_CLOSE_SQL.CLOSE_ALLOC(O_error_message,
                                           L_closed,
                                           L_tier_alloc_no) = FALSE THEN
            RETURN FALSE;
         END IF;

      END LOOP;
   END LOOP;
   return TRUE;

   ---
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('ALLOC_DETAIL_REC_LOCK_2',
                                             to_char(I_order_no),
                                             NULL,
                                             NULL);

      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CANCEL_SINGLE_ALLOC;
-----------------------------------------------------------------------------------------------------
FUNCTION CANCEL_ASN_ALLOC(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          I_order_no        IN       ALLOC_HEADER.ORDER_NO%TYPE)
RETURN BOOLEAN is

   L_closed         BOOLEAN;
   L_alloc_no       ALLOC_HEADER.ALLOC_NO%TYPE;
   L_tier_alloc_no  ALLOC_HEADER.ALLOC_NO%TYPE;
   L_program        VARCHAR2(50) := 'CANCEL_ALLOC_SQL.CANCEL_ASN_ALLOC';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   cursor C_CLOSE_ALH is
      select alh.alloc_no
        from alloc_header alh
       where alh.order_no = I_order_no
         and alh.doc_type = 'ASN'
         and alh.release_date < (select(per.vdate - TO_NUMBER(cdd.code_desc))
                                   from period per,
                                        code_detail cdd
                                  where cdd.code_type = 'DEFT'
                                    and cdd.code = 'DATE');

   cursor C_CLOSE_ALLOC_TIER is
      select alloc_no
        from alloc_header
       where alloc_parent = L_alloc_no;

   cursor C_LOCK_ALD is
      select 'x'
        from alloc_detail
       where alloc_no = L_alloc_no
         for update nowait;

BEGIN
   if I_order_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_order_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('LOOP',
                    'C_CLOSE_ALH',
                    'ALLOC_HEADER',
                    'order no: '||TO_CHAR(I_order_no));

   FOR c_close_alh_rec in C_CLOSE_ALH LOOP
      L_alloc_no := c_close_alh_rec.alloc_no;

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ALD',
                       'ALLOC_DETAIL',
                       'alloc no: '||TO_CHAR(L_alloc_no));
      open C_LOCK_ALD;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ALD',
                       'ALLOC_DETAIL',
                       'alloc no: '||TO_CHAR(L_alloc_no));
      close C_LOCK_ALD;

      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ALLOC_DETAIL',
                       'alloc no: '||TO_CHAR(L_alloc_no));
      update alloc_detail
         set qty_allocated = GREATEST(NVL(qty_transferred,0),NVL(qty_received,0)),
             qty_cancelled = qty_allocated - GREATEST(NVL(qty_transferred,0),NVL(qty_received,0))
       where alloc_no      = L_alloc_no;

      if APPT_DOC_CLOSE_SQL.CLOSE_ALLOC(O_error_message,
                                        L_closed,
                                        L_alloc_no) = FALSE then
         return FALSE;
      end if;

      FOR c_close_alloc_tier_rec in C_CLOSE_ALLOC_TIER LOOP
         L_tier_alloc_no := c_close_alloc_tier_rec.alloc_no;
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_ALD',
                          'ALLOC_DETAIL',
                          'alloc no: '||TO_CHAR(L_tier_alloc_no));
         open C_LOCK_ALD;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_ALD',
                          'ALLOC_DETAIL',
                          'alloc no: '||TO_CHAR(L_tier_alloc_no));
         close C_LOCK_ALD;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ALLOC_DETAIL',
                          'alloc no: '||TO_CHAR(L_tier_alloc_no));
         update alloc_detail
            set qty_allocated = GREATEST(NVL(qty_transferred,0),NVL(qty_received,0)),
                qty_cancelled = qty_allocated - GREATEST(NVL(qty_transferred,0),NVL(qty_received,0))
          where alloc_no      = L_tier_alloc_no;

         if APPT_DOC_CLOSE_SQL.CLOSE_ALLOC(O_error_message,
                                           L_closed,
                                           L_tier_alloc_no) = FALSE then
            return FALSE;
         end if;

      END LOOP;
   END LOOP;
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('C_LOCK_ALD',
                                             to_char(I_order_no),
                                             NULL,
                                             NULL);

      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CANCEL_ASN_ALLOC;
-----------------------------------------------------------------------------------------------------
FUNCTION CLOSE_CHILD_ALLOC(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_alloc_no        IN       ALLOC_HEADER.ALLOC_NO%TYPE)
RETURN BOOLEAN is

   L_tier_alloc_no   ALLOC_HEADER.ALLOC_NO%TYPE;
   L_program         VARCHAR2(50) := 'CANCEL_ALLOC_SQL.CLOSE_CHILD_ALLOC';
   L_closed          BOOLEAN;
   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ALD is
      select 1
        from alloc_detail ald
       where ald.alloc_no = L_tier_alloc_no
         and ald.qty_allocated > NVL(ald.qty_transferred,0)
         for update nowait;

   CURSOR C_CLOSE_ALLOC_TIER IS
      select alloc_no
        from alloc_header
       where alloc_parent = I_alloc_no;

BEGIN
   if I_alloc_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG','I_ALLOC_NO',NULL,NULL);
      return FALSE;
   end if;

   FOR c_close_alloc_tier_rec IN C_CLOSE_ALLOC_TIER LOOP
      L_tier_alloc_no := c_close_alloc_tier_rec.alloc_no;
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ALD',
                       'ALLOC_DETAIL',
                       'alloc no: '||TO_CHAR(L_tier_alloc_no));
      OPEN C_LOCK_ALD;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ALD',
                       'ALLOC_DETAIL',
                       'alloc no: '||TO_CHAR(L_tier_alloc_no));
      CLOSE C_LOCK_ALD;

      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ALLOC_DETAIL',
                       'alloc no: '||TO_CHAR(L_tier_alloc_no));
      UPDATE alloc_detail
         SET qty_allocated = GREATEST(NVL(qty_selected,0),NVL(qty_distro,0)) + NVL(qty_transferred,0),
             qty_cancelled = qty_allocated - (GREATEST(NVL(qty_selected,0),NVL(qty_distro,0)) + NVL(qty_transferred,0))
       WHERE alloc_no      = L_tier_alloc_no
         AND qty_allocated > NVL(qty_transferred,0);

      IF APPT_DOC_CLOSE_SQL.CLOSE_ALLOC(O_error_message,
                                        L_closed,
                                        L_tier_alloc_no) = FALSE THEN
         RETURN FALSE;
      END IF;

   END LOOP;

   return TRUE;

   ---
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('ALLOC_DETAIL_REC_LOCK_2',
                                             to_char(I_alloc_no),
                                             NULL,
                                             NULL);

      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CLOSE_CHILD_ALLOC;
-----------------------------------------------------------------------------------------------------
END CANCEL_ALLOC_SQL;
/

