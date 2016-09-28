CREATE OR REPLACE PACKAGE BODY FTERM_SQL AS

   GP_system_options SYSTEM_OPTIONS%ROWTYPE := NULL;

/* Function and Procedure Bodies */
---------------------------------------------------------------------------
FUNCTION PROCESS_TERMS (O_text             IN OUT VARCHAR2,
                        I_fterm_record     IN     FTERM_RECORD)
RETURN BOOLEAN IS

   L_freightrec       FTERM_RECORD        := I_fterm_record;
   L_exists           VARCHAR2(1)        := 'N';

   CURSOR c_freight IS
      select 'Y'
        from freight_terms
       where freight_terms = L_freightrec.terms;

BEGIN

   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_text,
                                            GP_system_options) = FALSE then
      return FALSE;
   end if;

   if VALIDATE_TERMS(O_text,
                     L_freightrec) = FALSE then
      return FALSE;
   end if;

   open c_freight;
   fetch c_freight into L_exists;
   close c_freight;

   if L_exists = 'N' then
      if INSERT_TERMS(O_text,
                      L_freightrec) = FALSE then
         return FALSE;
      end if;
   else
      if UPDATE_TERMS(O_text,
                      L_freightrec) = FALSE then
         return FALSE;
      end if;
  end if;

  return TRUE;

EXCEPTION
   when OTHERS then
       O_text := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                     SQLERRM,
                                     'FTERMS_SQL.PROCESS_TERMS',
                                     to_char(SQLCODE));
      return FALSE;

END PROCESS_TERMS;
---------------------------------------------------------------------------------
FUNCTION INSERT_TERMS(O_text         IN OUT VARCHAR2,
                      I_fterm_record   IN     FTERM_RECORD)
return BOOLEAN IS


BEGIN
   insert into freight_terms(freight_terms,
                             term_desc,
                             start_date_active,
                             end_date_active,
                             enabled_flag)
                      values(I_fterm_record.terms,
                             I_fterm_record.description,
                             I_fterm_record.start_date_active,
                             I_fterm_record.end_date_active,
                             I_fterm_record.enabled_flag);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_text := sql_lib.create_msg('PACKAGE_ERROR',
                                   SQLERRM,
                                   'FTERMS_SQL.SUB_TERMS.INSERT_TERMS',
                                   to_char(SQLCODE));
      return FALSE;
END INSERT_TERMS;
-----------------------------------------------------------------------------------------------
FUNCTION UPDATE_TERMS(O_text           IN OUT VARCHAR2,
                      I_fterm_record   IN     FTERM_RECORD)
return BOOLEAN IS

   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(RECORD_LOCKED, -54);

   CURSOR c_lock_terms IS
      select 'Y'
        from freight_terms
       where freight_terms = I_fterm_record.terms
         for update nowait;

BEGIN
   -- Lock the terms table before updating
   open c_lock_terms;
   close c_lock_terms;
   ---
   -- When RMS is being used with Oracle Financials version 11.5.10 or later,
   -- the Freight Term data within RMS must match the data in Oracle Financials.
   -- This includes having no start date active or end date active values.  For
   -- example, when a Freight Term with an end date active in the future is updated
   -- within Oracle Financials to be active forever (end date active is NULL), this
   -- API must reflect this change in the Freight Term within RMS.
   update freight_terms
      set term_desc = I_fterm_record.description,
          start_date_active = DECODE(GP_system_options.oracle_financials_vers,
                                     '1', I_fterm_record.start_date_active,
                                     NVL(I_fterm_record.start_date_active, start_date_active)),
          end_date_active = DECODE(GP_system_options.oracle_financials_vers,
                                   '1', I_fterm_record.end_date_active,
                                   NVL(I_fterm_record.end_date_active, end_date_active)),
          enabled_flag = I_fterm_record.enabled_flag
    where freight_terms = I_fterm_record.terms;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_text := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                   'FREIGHT_TERMS',
                                   I_fterm_record.terms,
                                   'FTERMS_SQL.UPDATE_TERMS');
      return TRUE;
   when OTHERS then
      O_text := sql_lib.create_msg('PACKAGE_ERROR',
                                   SQLERRM,
                                   'FTERMS_SQL.UPDATE_TERMS',
                                   to_char(SQLCODE));
      return FALSE;
END UPDATE_TERMS;
----------------------------------------------------------------------------------------
FUNCTION VALIDATE_TERMS(O_text        IN OUT VARCHAR2,
                        I_fterm_record  IN     FTERM_RECORD)
return BOOLEAN IS

BEGIN

   if CHECK_NULLS(O_text,
                  I_fterm_record.terms) = FALSE then
      return FALSE;
   end if;

   if CHECK_NULLS(O_text,
                  I_fterm_record.description) = FALSE then
      return FALSE;
   end if;

   if CHECK_NULLS(O_text,
                  I_fterm_record.enabled_flag) = FALSE then
      return FALSE;
   end if;

   -- Oracle Financials is the owner of Freight Term data, and RMS is only
   -- subscribing to this data.  Also, no business logic is currently driven
   -- off the start date active and end date active attributes of a Freight Term.
   -- Finally, within Oracle Financials there is no concept of an enabled flag, nor
   -- is there any validation on the start date active and end date active attributes
   -- of a Freight Term.  As such, when a Freight Term is coming into RMS from Oracle
   -- Financials, the validation within the CHECK_ENABLED function will be bypassed.
   if GP_system_options.oracle_financials_vers != '1' or
      GP_system_options.oracle_financials_vers IS NULL then
      if CHECK_ENABLED(O_text,
                       I_fterm_record) = FALSE then
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
    when OTHERS then
      O_text := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                   SQLERRM,
                                   'FTERMS_SQL.VALIDATE_TERMS',
                                   to_char(SQLCODE));
      return FALSE;

END VALIDATE_TERMS;
----------------------------------------------------------------------------------------
FUNCTION CHECK_NULLS (O_text            IN OUT VARCHAR2,
                      I_record_variable IN     VARCHAR2)
return BOOLEAN IS

BEGIN

   if I_record_variable is NULL then
      O_text := sql_lib.create_msg('INVALID_PARM_IN_FUNC',
                                   'I_record_variable',
                                   'NULL',
                                   'FTERMS_SQL.CHECK_NULLS');
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_text := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                   SQLERRM,
                                   'FTERMS_SQL.CHECK_NULLS',
                                   to_char(SQLCODE));
      return FALSE;

END CHECK_NULLS;
-----------------------------------------------------------------------
FUNCTION CHECK_ENABLED(O_text        IN OUT VARCHAR2,
                       I_fterm_record  IN     FTERM_RECORD)
return BOOLEAN IS

   PROGRAM_ERROR   EXCEPTION;
   L_freightrec    FTERM_RECORD                  := I_fterm_record;
   L_start_date    freight_terms.start_date_active%TYPE     := NULL;
   L_end_date      freight_terms.start_date_active%TYPE     := NULL;
   L_vdate         period.vdate%TYPE;

   CURSOR c_vdate IS
      select vdate
        from period;

   CURSOR c_get_daterange IS
      select start_date_active,
             end_date_active
        from freight_terms
       where freight_terms = L_freightrec.terms;

BEGIN

   open c_vdate;
   fetch c_vdate into L_vdate;
   close c_vdate;

   open c_get_daterange;
   fetch c_get_daterange into L_start_date,
                              L_end_date;
   close c_get_daterange;

   L_start_date := NVL(L_freightrec.start_date_active, L_start_date);
   L_end_date := NVL(L_freightrec.end_date_active, L_end_date);

   if L_start_date > L_end_date then
      raise PROGRAM_ERROR;
   end if;

   if L_vdate < NVL(L_start_date, L_vdate) AND L_freightrec.enabled_flag = 'Y' then
      raise PROGRAM_ERROR;
   elsif L_vdate > NVL(L_end_date, L_vdate) AND L_freightrec.enabled_flag = 'Y' then
      raise PROGRAM_ERROR;
   elsif (L_vdate >= NVL(L_start_date, L_vdate + 1) AND
          L_vdate < NVL(L_end_date, L_vdate - 1)) AND L_freightrec.enabled_flag = 'N' then
      raise PROGRAM_ERROR;
   end if;

   return TRUE;

EXCEPTION
   when PROGRAM_ERROR then
      O_text := sql_lib.create_msg('INVALID_ENABLED_IND',
                                   'EnabledInd',
                                   'FTERMS_SQL.CHECK_ENABLED',
                                   NULL);
      return FALSE;
   when OTHERS then
      O_text := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                   SQLERRM,
                                   'FTERMS_SQL.CHECK_ENABLED',
                                   to_char(SQLCODE));
      return FALSE;

END CHECK_ENABLED;
----------------------------------------------------------------------------
END FTERM_SQL;
/

