CREATE OR REPLACE PACKAGE BODY DATES_SQL AS
------------------------------------------------------------------------------------------------
--Mod By      : Nitin Gour, nitin.gour@in.tesco.com
--Date        : 03-Mar-2008
--Reference   : N45 (Historical Deals)
--Description : Returns the begin of the week
------------------------------------------------------------------------------------------------
   /* declare global variables to hold all of the data from the */
   /* period table.  the globals will cache the values for the */
   /* entire session, thus reducing the overhead of calls to period */
   LP_sysavail               period.sysavail%TYPE := null;
   LP_vdate                  period.vdate%TYPE := null;
   LP_start_454_half         period.start_454_half%TYPE := null;
   LP_end_454_half           period.end_454_half%TYPE := null;
   LP_start_454_month        period.start_454_month%TYPE := null;
   LP_mid_454_month          period.mid_454_month%TYPE := null;
   LP_end_454_month          period.end_454_month%TYPE := null;
   LP_half_no                period.half_no%TYPE := null;
   LP_next_half_no           period.next_half_no%TYPE := null;
   LP_curr_454_day           period.curr_454_day%TYPE := null;
   LP_curr_454_week          period.curr_454_week%TYPE := null;
   LP_curr_454_month         period.curr_454_month%TYPE := null;
   LP_curr_454_year          period.curr_454_year%TYPE := null;
   LP_curr_454_month_in_half period.curr_454_month_in_half%TYPE := null;
   LP_curr_454_week_in_half  period.curr_454_week_in_half%TYPE := null;

   /* the basis eow_date is cached, and will be used for determining */
   /* the end of week date values for any date that is passed in */
   LP_basis_eow_date         period.vdate%TYPE := null;

   /* a globabl error variable can be used for functions that cannot use */
   /* IN OUT variables */
   LP_error_message          varchar2(255) := null;

-------------------------------------------------------
/* this is an overloaded function.  this version is the preferred */
/* because it uses standard error handling methods.  */
/* the other function is used for functions that are currently used */
/* in sql statements (no in/out variables can be used for those */
FUNCTION GET_PERIOD_VALUES(O_error_message IN OUT varchar2)

RETURN BOOLEAN IS
   cursor C_GET_PERIOD_DATA is
      select sysavail,
             vdate,
             start_454_half,
             end_454_half,
             start_454_month,
             mid_454_month,
             end_454_month,
             half_no,
             next_half_no,
             curr_454_day,
             curr_454_week,
             curr_454_month,
             curr_454_year,
             curr_454_month_in_half,
             curr_454_week_in_half
        from period;

   L_program VARCHAR2(255) := 'DATES_SQL.GET_PERIOD_DATA';
   L_cursor  VARCHAR2(255) := null;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_GET_PERIOD_DATA','PERIOD',null);
   open C_GET_PERIOD_DATA;

   SQL_LIB.SET_MARK('FETCH','C_GET_PERIOD_DATA','PERIOD',null);
   fetch C_GET_PERIOD_DATA
    into LP_sysavail,
         LP_vdate,
         LP_start_454_half,
         LP_end_454_half,
         LP_start_454_month,
         LP_mid_454_month,
         LP_end_454_month,
         LP_half_no,
         LP_next_half_no,
         LP_curr_454_day,
         LP_curr_454_week,
         LP_curr_454_month,
         LP_curr_454_year,
         LP_curr_454_month_in_half,
         LP_curr_454_week_in_half;
   if C_GET_PERIOD_DATA%notfound then
      close C_GET_PERIOD_DATA;
      L_cursor := 'C_GET_PERIOD_DATA';
      raise NO_DATA_FOUND;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_GET_PERIOD_DATA','PERIOD',null);
   close C_GET_PERIOD_DATA;

   return TRUE;

EXCEPTION
when NO_DATA_FOUND then
   O_error_message := sql_lib.create_msg('INV_CURSOR',
                                          L_cursor,
                                          L_program,NULL);
   RETURN FALSE;
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
end GET_PERIOD_VALUES;
-------------------------------------------------------
/* this function is overloaded.  this version has no */
/* input or output parameters.  this is necessary for */
/* functions that are called within sql statements */
FUNCTION GET_PERIOD_VALUES

RETURN BOOLEAN IS
   cursor C_GET_PERIOD_DATA is
      select sysavail,
             vdate,
             start_454_half,
             end_454_half,
             start_454_month,
             mid_454_month,
             end_454_month,
             half_no,
             next_half_no,
             curr_454_day,
             curr_454_week,
             curr_454_month,
             curr_454_year,
             curr_454_month_in_half,
             curr_454_week_in_half
        from period;
BEGIN

   open C_GET_PERIOD_DATA;

   fetch C_GET_PERIOD_DATA
    into LP_sysavail,
         LP_vdate,
         LP_start_454_half,
         LP_end_454_half,
         LP_start_454_month,
         LP_mid_454_month,
         LP_end_454_month,
         LP_half_no,
         LP_next_half_no,
         LP_curr_454_day,
         LP_curr_454_week,
         LP_curr_454_month,
         LP_curr_454_year,
         LP_curr_454_month_in_half,
         LP_curr_454_week_in_half;
   if C_GET_PERIOD_DATA%notfound then
      close C_GET_PERIOD_DATA;
      raise NO_DATA_FOUND;
   end if;

   close C_GET_PERIOD_DATA;

   return TRUE;

EXCEPTION
  when NO_DATA_FOUND then
     LP_error_message := 'DATES_SQL.GET_PERIOD_VALUES from period: ' || SQLERRM;
     return false;
  when others then
     LP_error_message := 'DATES_SQL.GET_PERIOD_VALUES from period: ' || SQLERRM;
     return false;
end GET_PERIOD_VALUES;
-----------------------------------------------------
FUNCTION GET_BASIS_EOW_DATE(O_error_message  IN OUT VARCHAR2,
                            O_basis_eow_date IN OUT period.vdate%TYPE)
RETURN BOOLEAN IS

   L_curr_454_day period.curr_454_day%TYPE;
   L_basis_date   period.vdate%TYPE;

BEGIN
   /* only need to get one valid eow_date per session */
   /* once this has been derived, then date arithmetic can */
   /* be used to derive all other end of week dates */
   if LP_basis_eow_date is null then

      if GET_VDATE(O_error_message,
                   L_basis_date) = FALSE then
         return FALSE;
      end if;

      if GET_454_DAY(O_error_message,
                     L_curr_454_day) = FALSE then
         return FALSE;
      end if;

      LP_basis_eow_date := L_basis_date + (7 - L_curr_454_day);

   end if;

   O_basis_eow_date := LP_basis_eow_date;

   return TRUE;

EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'DATES_SQL.GET_BASIS_EOW_DATE',
                                         to_char(SQLCODE));
   return FALSE;
END GET_BASIS_EOW_DATE;
-------------------------------------------------------
FUNCTION GET_SYSAVAIL(O_error_message IN OUT VARCHAR2,
                      O_sysavail      IN OUT period.sysavail%TYPE)
RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_SYSAVAIL';
BEGIN

   if LP_sysavail is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;
    O_sysavail := LP_sysavail;
    return TRUE;
EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_SYSAVAIL;
-------------------------------------------------------
/* this function is overloaded to allow calls within */
/* sql statements.  this is not the preferred function */
/* call because it does not contain robust error handling */
FUNCTION GET_VDATE
RETURN DATE IS
BEGIN
   if LP_vdate is null then
      if GET_PERIOD_VALUES = FALSE then
         return null;
      end if;
   end if;

   return LP_vdate;
END GET_VDATE;
-------------------------------------------------------
/* this function is overloaded to allow calls within sql */
/* statements (using the other function). this function */
/* uses standard and preferred error handling and should */
/* be the function of choice.  however both use caching */
/* for performance. */
FUNCTION GET_VDATE(O_error_message IN OUT varchar2,
                   O_vdate         IN OUT period.vdate%TYPE)

RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_VDATE';
BEGIN

   if LP_vdate is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_vdate := LP_vdate;
   return TRUE;
EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_VDATE;
-------------------------------------------------------
FUNCTION GET_START_454_HALF(O_error_message  IN OUT varchar2,
                            O_start_454_half IN OUT period.start_454_half%TYPE)

RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_START_454_HALF';
BEGIN

   if LP_start_454_half is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_start_454_half := LP_start_454_half;
   return TRUE;
EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_START_454_HALF;
-------------------------------------------------------
FUNCTION GET_END_454_HALF(O_error_message  IN OUT varchar2,
                          O_end_454_half   IN OUT period.end_454_half%TYPE)

RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_END_454_HALF';
BEGIN

   if LP_end_454_half is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_end_454_half := LP_end_454_half;
   return TRUE;
EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_END_454_HALF;
-------------------------------------------------------
FUNCTION GET_START_454_MONTH(O_error_message   IN OUT varchar2,
                             O_start_454_month IN OUT period.start_454_month%TYPE)

RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_START_454_MONTH';
BEGIN

   if LP_start_454_month is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_start_454_month := LP_start_454_half;
   return TRUE;
EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_START_454_MONTH;
-------------------------------------------------------
FUNCTION GET_MID_454_MONTH(O_error_message IN OUT varchar2,
                           O_mid_454_month IN OUT period.mid_454_month%TYPE)

RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_MID_454_MONTH';
BEGIN

   if LP_mid_454_month is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_mid_454_month := LP_mid_454_month;
   return TRUE;
EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_MID_454_MONTH;
-------------------------------------------------------
FUNCTION GET_END_454_MONTH(O_error_message IN OUT varchar2,
                           O_end_454_month IN OUT period.end_454_month%TYPE)

RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_END_454_MONTH';
BEGIN

   if LP_end_454_month is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_end_454_month := LP_end_454_month;
   return TRUE;
EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_END_454_MONTH;
-------------------------------------------------------
FUNCTION GET_HALF_NO(O_error_message IN OUT varchar2,
                     O_half_no       IN OUT period.half_no%TYPE)

RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_HALF_NO';
BEGIN

   if LP_half_no is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_half_no := LP_half_no;
   return TRUE;
EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_HALF_NO;
-------------------------------------------------------
FUNCTION GET_NEXT_HALF_NO(O_error_message IN OUT varchar2,
                          O_next_half_no  IN OUT period.next_half_no%TYPE)

RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_NEXT_HALF_NO';
BEGIN

   if LP_next_half_no is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_next_half_no := LP_next_half_no;
   return TRUE;
EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_NEXT_HALF_NO;
-------------------------------------------------------
/* overloaded function...if no input parameter is used */
/* then the function will return the 454 day for the */
/* the current vdate */
FUNCTION GET_454_DAY(O_error_message IN OUT VARCHAR2,
                     O_curr_454_day  IN OUT period.curr_454_day%TYPE)
RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_CURR_454_DAY';
BEGIN

   if LP_curr_454_day is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_curr_454_day := LP_curr_454_day;
   return TRUE;

EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_454_DAY;
-------------------------------------------------------
/* overloaded function....if the input date is included */
/* then the function returns the 454 day for the parameter date */
FUNCTION GET_454_DAY(O_error_message     IN OUT VARCHAR2,
                     O_454_day           IN OUT period.curr_454_day%TYPE,
                     I_action_date       IN     date)
RETURN BOOLEAN IS

   L_curr_454_day       period.curr_454_day%TYPE;
   L_action_454_day     period.curr_454_day%TYPE;
   L_basis_eow_date     period.vdate%TYPE;
   L_days_from_date     number(1);
   L_action_date_trunc  date  := TRUNC(I_action_date);

BEGIN
   if GET_BASIS_EOW_DATE(O_error_message,
                         L_basis_eow_date) = FALSE then
      return FALSE;
   end if;
   L_days_from_date := MOD(ABS(L_basis_eow_date - L_action_date_trunc),7);

   if L_basis_eow_date >= L_action_date_trunc then
      O_454_day := 7 - L_days_from_date;
   else
      if L_days_from_date = 0 then
         O_454_day := 7;
      else
         O_454_day := L_days_from_date;
      end if;
   end if;

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'DATES_SQL.GET_454_DAY',
                                         to_char(SQLCODE));
   return FALSE;
END GET_454_DAY;
-----------------------------------------------------------------------
FUNCTION GET_454_WEEK(O_error_message IN OUT VARCHAR2,
                      O_curr_454_week IN OUT period.curr_454_week%TYPE)
RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_CURR_454_WEEK';
BEGIN

   if LP_curr_454_week is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_curr_454_week := LP_curr_454_week;
   return TRUE;

EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_454_WEEK;
-------------------------------------------------------
FUNCTION GET_454_MONTH(O_error_message  IN OUT VARCHAR2,
                       O_curr_454_month IN OUT period.curr_454_month%TYPE)
RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_CURR_454_MONTH';
BEGIN

   if LP_curr_454_month is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_curr_454_month := LP_curr_454_month;
   return TRUE;

EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_454_MONTH;
-------------------------------------------------------
FUNCTION GET_454_YEAR(O_error_message IN OUT VARCHAR2,
                      O_curr_454_year IN OUT period.curr_454_year%TYPE)
RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_CURR_454_YEAR';
BEGIN

   if LP_curr_454_year is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_curr_454_year := LP_curr_454_year;
   return TRUE;

EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_454_YEAR;
-------------------------------------------------------
FUNCTION GET_454_MONTH_IN_HALF(O_error_message          IN OUT VARCHAR2,
                               O_curr_454_month_in_half IN OUT period.curr_454_month_in_half%TYPE)
RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_CURR_454_MONTH_IN_HALF';
BEGIN

   if LP_curr_454_month_in_half is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_curr_454_month_in_half := LP_curr_454_month_in_half;
   return TRUE;

EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_454_MONTH_IN_HALF;
-------------------------------------------------------
FUNCTION GET_454_WEEK_IN_HALF(O_error_message         IN OUT VARCHAR2,
                              O_curr_454_week_in_half IN OUT period.curr_454_week_in_half%TYPE)
RETURN BOOLEAN IS
   L_program VARCHAR2(255) := 'DATES_SQL.GET_CURR_454_WEEK_IN_HALF';
BEGIN

   if LP_curr_454_week_in_half is null then
      if GET_PERIOD_VALUES(O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   O_curr_454_week_in_half := LP_curr_454_week_in_half;
   return TRUE;

EXCEPTION when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'L_program',
                                         to_char(SQLCODE));
   return FALSE;
END GET_454_WEEK_IN_HALF;
-------------------------------------------------------
FUNCTION GET_EOW_DATE(O_error_message     IN OUT VARCHAR2,
                      O_eow_date          IN OUT date,
                      I_action_date       IN     date)
/* this function will derive the end of week date associated with the */
/* action date passed into the function as an input parameter */
/* the function will only need to call the calendar function once during */
/* a given session.  Once one valid end of week date has been derived, */
/* date arithemetic can be used to derive any other valid eow_date. */

RETURN BOOLEAN IS

   L_curr_454_day       period.curr_454_day%TYPE;
   L_action_454_day     period.curr_454_day%TYPE;
   L_basis_eow_date     period.vdate%TYPE;
   L_action_date_trunc  date := TRUNC(I_action_date);

BEGIN
   if GET_454_DAY(O_error_message,
                  L_action_454_day,
                  L_action_date_trunc) = FALSE then
      return FALSE;
   end if;

   if L_action_454_day = 7 then
      O_eow_date := L_action_date_trunc;
   else
      O_eow_date := L_action_date_trunc + (7 - L_action_454_day);
   end if;

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'DATES_SQL.GET_VDATE',
                                         to_char(SQLCODE));
   return FALSE;
END GET_EOW_DATE;
-----------------------------------------------------------------------
FUNCTION GET_EOW_DATE(O_error_message     IN OUT VARCHAR2,
                      O_eow_date          IN OUT date)
/* this function will derive the current end of week date */
RETURN BOOLEAN IS

   L_curr_454_day   period.curr_454_day%TYPE;
   L_action_454_day period.curr_454_day%TYPE;
   L_basis_eow_date period.vdate%TYPE;

BEGIN
   if GET_BASIS_EOW_DATE(O_error_message,
                         L_basis_eow_date) = FALSE then
      return FALSE;
   end if;
   O_eow_date := L_basis_eow_date;

   return TRUE;

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                         'DATES_SQL.GET_VDATE',
                                         to_char(SQLCODE));
   return FALSE;
END GET_EOW_DATE;
-----------------------------------------------------------------------
FUNCTION RESET_GLOBALS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS
BEGIN

   LP_sysavail := null;
   LP_vdate := null;
   LP_start_454_half := null;
   LP_end_454_half := null;
   LP_start_454_month := null;
   LP_mid_454_month := null;
   LP_end_454_month := null;
   LP_half_no := null;
   LP_next_half_no := null;
   LP_curr_454_day := null;
   LP_curr_454_week := null;
   LP_curr_454_month := null;
   LP_curr_454_year := null;
   LP_curr_454_month_in_half := null;
   LP_curr_454_week_in_half := null;
   LP_basis_eow_date := null;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DATES_SQL.RESET_GLOBALS',
                                            to_char(SQLCODE));
      return FALSE;

END RESET_GLOBALS;
------------------------------------------------------------------------------------------------
--Author       : Nitin Gour, nitin.gour@in.tesco.com
--Date         : 03-Mar-2008
--Function Name: TSL_GET_BOW_DATE
--Description  : Returns the begin of the week
------------------------------------------------------------------------------------------------
  FUNCTION TSL_GET_BOW_DATE (O_error_message IN OUT NOCOPY RTK_ERRORS.RTK_TEXT%TYPE,
                             O_bow_date      IN OUT NOCOPY DATE,
                             I_action_date   IN            DATE)
    RETURN BOOLEAN IS

    L_action_454_day     PERIOD.CURR_454_DAY%TYPE;
    L_action_date_trunc  DATE := TRUNC(I_action_date);

  BEGIN
      ---
      if NOT GET_454_DAY(O_error_message,
                         L_action_454_day,
                         L_action_date_trunc) then
          return FALSE;
      end if;
      ---
      if L_action_454_day = 1 then
          O_bow_date := L_action_date_trunc;
      else
          O_bow_date := (L_action_454_day -1) - L_action_date_trunc;
      end if;
      ---
      return TRUE;

  EXCEPTION
      when OTHERS then
          O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                                SQLERRM,
                                                'DATES_SQL.TSL_GET_BOW_DATE',
                                                TO_CHAR(SQLCODE));
          return FALSE;

  END TSL_GET_BOW_DATE;
------------------------------------------------------------------------------------------------
END DATES_SQL;
/

