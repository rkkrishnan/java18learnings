CREATE OR REPLACE PACKAGE BODY APPOINTMENT_PROCESS_SQL AS
-- global variables used for error-message generation
LP_appt       APPT_HEAD.APPT%TYPE;
LP_loc        APPT_HEAD.LOC%TYPE;
LP_loc_type   APPT_HEAD.LOC_TYPE%TYPE;
----------------------------------------------------------------------------------------------
/* Internal Processing Functions */
FUNCTION VAL_LOC(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                 O_valid_loc      IN OUT BOOLEAN,
                 O_loc_type       IN OUT APPT_HEAD.LOC_TYPE%TYPE,
                 I_loc            IN     APPT_HEAD.LOC%TYPE)
RETURN BOOLEAN IS
   L_function  VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.VAL_LOC';
   ---
   cursor C_VAL_LOC is
      select 'W'
        from wh
       where wh = physical_wh
         and wh = I_loc
      UNION ALL
      select 'S'
        from store
       where store = I_loc;

BEGIN
   O_valid_loc := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_VAL_LOC','WH, STORE',NULL);
   open C_VAL_LOC;
   SQL_LIB.SET_MARK('FETCH','C_VAL_LOC','WH, STORE',NULL);
   fetch C_VAL_LOC into O_loc_type;
   ---
   if C_VAL_LOC%FOUND then
      O_valid_loc := TRUE;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_APPT_LOC',
                                             LP_appt,
                                             I_loc,
                                             NULL);
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_VAL_LOC','WH, STORE',NULL);
   close C_VAL_LOC;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END VAL_LOC;
----------------------------------------------------------------------------------------------
FUNCTION VAL_DOC(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                 O_valid_doc      IN OUT BOOLEAN,
                 I_doc            IN     APPT_DETAIL.DOC%TYPE,
                 I_doc_type       IN     APPT_DETAIL.DOC_TYPE%TYPE)
RETURN BOOLEAN IS
   L_function  VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.VAL_DOC';
   L_dummy     VARCHAR2(1);
   ---
   cursor C_VAL_DOC is
      select 'x'
        from ordhead
       where I_doc_type = 'P'
         and order_no   = I_doc
      UNION ALL
      select 'x'
        from tsfhead
       where I_doc_type = 'T'
         and tsf_no     = I_doc
      UNION ALL
      select 'x'
        from alloc_header
       where I_doc_type = 'A'
         and alloc_no   = I_doc;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_VAL_DOC','ORDHEAD, TSFHEAD, ALLOC_HEADER',NULL);
   open C_VAL_DOC;
   SQL_LIB.SET_MARK('FETCH','C_VAL_LOC','ORDHEAD, TSFHEAD, ALLOC_HEADER',NULL);
   fetch C_VAL_DOC into L_dummy;
   ---
   if C_VAL_DOC%NOTFOUND then
      O_valid_doc := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_APPT_DOC',
                                             LP_appt,
                                             LP_loc,
                                             I_doc);
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_VAL_LOC','ORDHEAD, TSFHEAD, ALLOC_HEADER',NULL);
   close C_VAL_DOC;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END VAL_DOC;
----------------------------------------------------------------------------------------------
FUNCTION VAL_ITEM(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                  O_valid_item     IN OUT BOOLEAN,
                  I_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_function  VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.VAL_ITEM';
   L_dummy     VARCHAR2(1);
   ---
   cursor C_VAL_ITEM is
      select 'x'
        from item_master
       where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_VAL_ITEM','ITEM_MASTER',NULL);
   open C_VAL_ITEM;
   SQL_LIB.SET_MARK('FETCH','C_VAL_ITEM','ITEM_MASTER',NULL);
   fetch C_VAL_ITEM into L_dummy;
   ---
   if C_VAL_ITEM%NOTFOUND then
      O_valid_item := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_APPT_ITEM',
                                             LP_appt,
                                             LP_loc,
                                             I_item);
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_VAL_ITEM','ITEM_MASTER',NULL);
   close C_VAL_ITEM;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END VAL_ITEM;
----------------------------------------------------------------------------------------------
FUNCTION HEAD_EXISTS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     O_head_exists    IN OUT BOOLEAN,
                     O_rowid          IN OUT ROWID,
                     I_appt_head      IN     APPT_HEAD%ROWTYPE)
RETURN BOOLEAN IS
   L_function     VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.HEAD_EXISTS';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);
   ---
   cursor C_HEAD_EXISTS is
      select rowid
        from appt_head
       where appt     = I_appt_head.appt
         and loc      = I_appt_head.loc
         and loc_type = LP_loc_type
         for update nowait;

BEGIN
   O_head_exists   := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_HEAD_EXISTS','APPT_HEAD',NULL);
   open C_HEAD_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_HEAD_EXISTS','APPT_HEAD',NULL);
   fetch C_HEAD_EXISTS into O_rowid;
   ---
   if C_HEAD_EXISTS%FOUND then
      O_head_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_HEAD_EXISTS','APPT_HEAD',NULL);
   close C_HEAD_EXISTS;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED_MODULE',
                                             'APPT_HEAD',
                                             'Appt.: '||I_appt_head.appt||', Loc.: '||I_appt_head.loc,
                                             L_function);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END HEAD_EXISTS;
----------------------------------------------------------------------------------------------
FUNCTION DETAIL_EXISTS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_detail_exists  IN OUT BOOLEAN,
                       O_rowid          IN OUT ROWID,
                       I_detail_rec     IN     APPT_DETAIL%ROWTYPE)
RETURN BOOLEAN IS
   L_function     VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.DETAIL_EXISTS';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);
   ---
   cursor C_DETAIL_EXISTS is
      select rowid
        from appt_detail
       where appt          = I_detail_rec.appt
         and loc           = I_detail_rec.loc
         and loc_type      = LP_loc_type
         and doc           = I_detail_rec.doc
         and doc_type      = I_detail_rec.doc_type
         and item          = I_detail_rec.item
         and NVL(asn, ' ') = nvl(I_detail_rec.asn, ' ')
         for update nowait;

BEGIN
   O_detail_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_DETAIL_EXISTS','APPT_HEAD',NULL);
   open C_DETAIL_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_DETAIL_EXISTS','APPT_HEAD',NULL);
   fetch C_DETAIL_EXISTS into O_rowid;
   ---
   if C_DETAIL_EXISTS%FOUND then
      O_detail_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_DETAIL_EXISTS','APPT_HEAD',NULL);
   close C_DETAIL_EXISTS;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED_MODULE',
                                             'APPT_DETAIL',
                                             'Appt.: '||I_detail_rec.appt||', Loc.: '||I_detail_rec.loc||', Item: '||I_detail_rec.item,
                                             L_function);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END DETAIL_EXISTS;
----------------------------------------------------------------------------------------------
/* External Processing Functions */
FUNCTION PROC_SCH(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                  I_appt_head      IN     APPT_HEAD%ROWTYPE,
                  I_appt_detail    IN     APPTDETAIL_TABLE)
RETURN BOOLEAN IS
   L_function       VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.PROC_SCH';
   L_valid          BOOLEAN;
   L_head_exists    BOOLEAN;
   L_detail_exists  BOOLEAN;
   L_rowid          ROWID;

BEGIN
   LP_appt := I_appt_head.appt;
   LP_loc  := I_appt_head.loc;
   ---
   if VAL_LOC(O_error_message,
              L_valid,
              LP_loc_type,
              I_appt_head.loc) = FALSE then
      return FALSE;
   end if;
   ---
   if not L_valid then
      return FALSE;
   end if;
   ---
   if HEAD_EXISTS(O_error_message,
                  L_head_exists,
                  L_rowid,
                  I_appt_head) = FALSE then
      return FALSE;
   end if;
   ---
   if not L_head_exists then
      insert into appt_head values(I_appt_head.appt,
                                   I_appt_head.loc,
                                   LP_loc_type,
                                   I_appt_head.status);
   end if;
   ---
   FOR i in 1..I_appt_detail.COUNT LOOP
      if PROC_SCHDET(O_error_message,
                     I_appt_detail(i)) = FALSE then
         return FALSE;
      end if;
   END LOOP;
   if FLUSH_APPT_DETAIL(O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END PROC_SCH;
----------------------------------------------------------------------------------------------
FUNCTION PROC_SCHDET(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_appt_detail_rec  IN     APPT_DETAIL%ROWTYPE)
RETURN BOOLEAN IS
   L_function       VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.PROC_SCHDET';
   L_valid          BOOLEAN;
   L_detail_exists  BOOLEAN;
   L_rowid          ROWID;

BEGIN
   if LP_appt is NULL then
      LP_appt := I_appt_detail_rec.appt;
      LP_loc  := I_appt_detail_rec.loc;
   end if;
   ---
   if VAL_LOC(O_error_message,
              L_valid,
              LP_loc_type,
              I_appt_detail_rec.loc) = FALSE then
      return FALSE;
   end if;
   ---
   if not L_valid then
      return FALSE;
   end if;
   ---
   if DETAIL_EXISTS(O_error_message,
                    L_detail_exists,
                    L_rowid,
                    I_appt_detail_rec) = FALSE then
      return FALSE;
   end if;
   ---
   if not L_detail_exists then
      L_valid := TRUE;
      ---
      if VAL_DOC(O_error_message,
                 L_valid,
                 I_appt_detail_rec.doc,
                 I_appt_detail_rec.doc_type) = FALSE then
         return FALSE;
      end if;
      ---
      if L_valid then
         if VAL_ITEM(O_error_message,
                     L_valid,
                     I_appt_detail_rec.item) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      if L_valid then

         P_appt_detail_size                  := P_appt_detail_size + 1;
         P_appt(P_appt_detail_size)          := I_appt_detail_rec.appt;
         P_loc(P_appt_detail_size)           := I_appt_detail_rec.loc;
         P_loc_type(P_appt_detail_size)      := LP_loc_type;
         P_doc(P_appt_detail_size)           := I_appt_detail_rec.doc;
         P_doc_type(P_appt_detail_size)      := I_appt_detail_rec.doc_type;
         P_item(P_appt_detail_size)          := I_appt_detail_rec.item;
         P_asn(P_appt_detail_size)           := I_appt_detail_rec.asn;
         P_qty_appointed(P_appt_detail_size) := I_appt_detail_rec.qty_appointed;
         P_qty_received(P_appt_detail_size)  := NULL;
         P_receipt_no(P_appt_detail_size)    := NULL;

      else
         return FALSE;
      end if;

   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END PROC_SCHDET;
----------------------------------------------------------------------------------------------

FUNCTION FLUSH_APPT_DETAIL(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_function       VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.FLUSH_APPT_DETAIL';

BEGIN

   if P_appt_detail_size > 0 then
      FORALL i IN 1..P_appt_detail_size
         insert into appt_detail(appt,
                                 loc,
                                 loc_type,
                                 doc,
                                 doc_type,
                                 item,
                                 asn,
                                 qty_appointed,
                                 qty_received,
                                 receipt_no)
                         values (P_appt(i),
                                 P_loc(i),
                                 P_loc_type(i),
                                 P_doc(i),
                                 P_doc_type(i),
                                 P_item(i),
                                 P_asn(i),
                                 P_qty_appointed(i),
                                 P_qty_received(i),
                                 P_receipt_no(i));
   end if;

   P_appt_detail_size := 0;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END FLUSH_APPT_DETAIL;

----------------------------------------------------------------------------------------------

FUNCTION PROC_MODHED(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_appt_head      IN     APPT_HEAD%ROWTYPE)
RETURN BOOLEAN IS
   L_function       VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.PROC_MOD';
   L_valid          BOOLEAN;
   L_head_exists    BOOLEAN;
   L_rowid          ROWID;
   L_closed_ind     BOOLEAN;

BEGIN
   LP_appt         := I_appt_head.appt;
   LP_loc          := I_appt_head.loc;
   ---
   if VAL_LOC(O_error_message,
              L_valid,
              LP_loc_type,
              I_appt_head.loc) = FALSE then
      return FALSE;
   end if;
   ---
   if not L_valid then
      return FALSE;
   end if;
   ---
   if HEAD_EXISTS(O_error_message,
                  L_head_exists,
                  L_rowid,
                  I_appt_head) = FALSE then
      return FALSE;
   end if;
   ---
   if L_head_exists then
      update appt_head
         set status   = I_appt_head.status
       where rowid    = L_rowid;
      ---
      if I_appt_head.status = 'AC' then
         if APPT_DOC_CLOSE_SQL.CLOSE_DOC(O_error_message,
                                         L_closed_ind,
                                         I_appt_head) = FALSE then
            return FALSE;
         end if;
      end if;
   else
      insert into appt_head values(I_appt_head.appt,
                                   I_appt_head.loc,
                                   LP_loc_type,
                                   I_appt_head.status);
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END PROC_MODHED;
----------------------------------------------------------------------------------------------
FUNCTION PROC_MODDET(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_appt_detail_rec  IN     APPT_DETAIL%ROWTYPE)
RETURN BOOLEAN IS
   L_function       VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.PROC_MODDET';
   L_valid          BOOLEAN;
   L_detail_exists  BOOLEAN;
   L_rowid          ROWID;

BEGIN
   if VAL_LOC(O_error_message,
              L_valid,
              LP_loc_type,
              I_appt_detail_rec.loc) = FALSE then
      return FALSE;
   end if;
   ---
   if not L_valid then
      return FALSE;
   end if;
   ---
   if DETAIL_EXISTS(O_error_message,
                    L_detail_exists,
                    L_rowid,
                    I_appt_detail_rec) = FALSE then
      return FALSE;
   end if;
   ---
   if L_detail_exists then
      update appt_detail
         set loc           = I_appt_detail_rec.loc,
             loc_type      = LP_loc_type,
             doc           = I_appt_detail_rec.doc,
             doc_type      = I_appt_detail_rec.doc_type,
             item          = I_appt_detail_rec.item,
             asn           = I_appt_detail_rec.asn,
             qty_appointed = I_appt_detail_rec.qty_appointed
       where rowid         = L_rowid;
   else
      insert into appt_detail values(I_appt_detail_rec.appt,
                                     I_appt_detail_rec.loc,
                                     LP_loc_type,
                                     I_appt_detail_rec.doc,
                                     I_appt_detail_rec.doc_type,
                                     I_appt_detail_rec.item,
                                     I_appt_detail_rec.asn,
                                     I_appt_detail_rec.qty_appointed,
                                     NULL,
                                     NULL);
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END PROC_MODDET;
----------------------------------------------------------------------------------------------
FUNCTION PROC_DEL(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                  I_appt_head      IN     APPT_HEAD%ROWTYPE)
RETURN BOOLEAN IS
   L_function     VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.PROC_DEL';
   L_valid        BOOLEAN;
   L_head_exists  BOOLEAN;
   L_rowid        ROWID;
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);
   ---
   cursor C_LOCK_ALL_DETAILS is
      select 'x'
        from appt_detail
       where appt     = I_appt_head.appt
         and loc      = I_appt_head.loc
         and loc_type = LP_loc_type
         for update nowait;

BEGIN
   LP_appt         := I_appt_head.appt;
   LP_loc          := I_appt_head.loc;
   ---
   if VAL_LOC(O_error_message,
              L_valid,
              LP_loc_type,
              I_appt_head.loc) = FALSE then
      return FALSE;
   end if;
   ---
   if not L_valid then
      return FALSE;
   end if;
   ---
   if HEAD_EXISTS(O_error_message,
                  L_head_exists,
                  L_rowid,
                  I_appt_head) = FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_DETAILS','APPT_DETAIL',NULL);
   open C_LOCK_ALL_DETAILS;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_DETAILS','APPT_DETAIL',NULL);
   close C_LOCK_ALL_DETAILS;
   ---
   delete
     from appt_detail
    where appt     = I_appt_head.appt
      and loc      = I_appt_head.loc
      and loc_type = LP_loc_type;
   ---
   delete
     from appt_head
    where appt     = I_appt_head.appt
      and loc      = I_appt_head.loc
      and loc_type = LP_loc_type;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED_MODULE',
                                             'APPT_DETAIL',
                                             'Appt.: '||I_appt_head.appt||', Loc.: '||I_appt_head.loc,
                                             L_function);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END PROC_DEL;
----------------------------------------------------------------------------------------------
FUNCTION PROC_DELDET(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_appt_detail    IN     APPT_DETAIL%ROWTYPE)
RETURN BOOLEAN IS
   L_function     VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.PROC_DELDET';
   L_valid        BOOLEAN;
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);
   ---
   cursor C_LOCK_ALL_DETAILS is
      select 'x'
        from appt_detail
       where appt     = I_appt_detail.appt
         and loc      = I_appt_detail.loc
         and loc_type = LP_loc_type
         for update nowait;

BEGIN
   LP_appt         := I_appt_detail.appt;
   LP_loc          := I_appt_detail.loc;
   ---
   if VAL_LOC(O_error_message,
              L_valid,
              LP_loc_type,
              I_appt_detail.loc) = FALSE then
      return FALSE;
   end if;
   ---
   if not L_valid then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_DETAILS','APPT_DETAIL',NULL);
   open C_LOCK_ALL_DETAILS;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_DETAILS','APPT_DETAIL',NULL);
   close C_LOCK_ALL_DETAILS;
   ---
   delete
     from appt_detail
    where appt          = I_appt_detail.appt
      and loc           = I_appt_detail.loc
      and loc_type      = LP_loc_type
      and item          = I_appt_detail.item
      and doc           = I_appt_detail.doc
      and NVL(asn, ' ') = NVL(I_appt_detail.asn, ' ');
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED_MODULE',
                                             'APPT_DETAIL',
                                             'Appt.: '||I_appt_detail.appt||', Loc.: '||I_appt_detail.loc,
                                             L_function);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END PROC_DELDET;
----------------------------------------------------------------------------------------------
FUNCTION PROC_CLS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                  I_appt_head      IN     APPT_HEAD%ROWTYPE)
RETURN BOOLEAN IS
   L_function     VARCHAR2(50) := 'APPOINTMENT_PROCESS_SQL.PROC_CLS';
   L_valid        BOOLEAN;
   L_head_exists  BOOLEAN;
   L_rowid        ROWID;
   L_closed_ind   BOOLEAN;

BEGIN
   LP_appt         := I_appt_head.appt;
   LP_loc          := I_appt_head.loc;
   ---
   if VAL_LOC(O_error_message,
              L_valid,
              LP_loc_type,
              I_appt_head.loc) = FALSE then
      return FALSE;
   end if;
   ---
   if not L_valid then
      return FALSE;
   end if;
   ---
   if HEAD_EXISTS(O_error_message,
                  L_head_exists,
                  L_rowid,
                  I_appt_head) = FALSE then
      return FALSE;
   end if;
   ---
   if L_head_exists then
      update appt_head
         set status = I_appt_head.status
       where rowid  = L_rowid;
      ---
      if APPT_DOC_CLOSE_SQL.CLOSE_DOC(O_error_message,
                                      L_closed_ind,
                                      I_appt_head) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;
END PROC_CLS;
----------------------------------------------------------------------------------------------
END APPOINTMENT_PROCESS_SQL;
/

