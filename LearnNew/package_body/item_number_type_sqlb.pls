CREATE OR REPLACE PACKAGE BODY ITEM_NUMBER_TYPE_SQL AS
-----------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 05-Oct-2007
-- Mod Ref    : N105 (Drop 2)
-- Mod Details: Added two Functions TSL_GET_NEXT,
--              and TSL_CHECK_ALL_NUMBERS
--              Modificaton in VALIDATE_FORMAT function
-----------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 01-Feb-2008
-- Mod Ref    : N105a
-- Mod Details: Modified the function TSL_GET_NEXT
-------------------------------------------------------------------------
-- Defect fix by : Dhuraison Prince, dhuraison.princepraveen@wipro.com --
-- Fix date      : 22-Jul-2008                                         --
-- Defect ref    : DefNBS008002                                        --
-- Fix details   : Changed the VALIDATE_FORMAT function to bypass the  --
--                 validation of item number type TSLMPI'              --
--                 (Multipack Singles)                                 --
-------------------------------------------------------------------------
-- Defect fix by : Dhuraison Prince, dhuraison.princepraveen@wipro.com --
-- Fix date      : 22-Jul-2008                                         --
-- Defect ref    : DefNBS008002                                        --
-- Fix details   : Changed the VALIDATE_FORMAT function to bypass the  --
--                 validation of item number type 'PEIB'               --
-------------------------------------------------------------------------
-- Mod By       : Tarun Kumar Mishra, tarun.mishra@in.tesco.com
-- Mod Date     : 9-Dec-2008
-- Mod Ref      : DefNBS005996
-- Mod Details  : Modified the function TSL_GET_NEXT
-------------------------------------------------------------------------
-- Mod By     : Chandru N, chandrashekaran.natarajan@in.tesco.com
-- Mod Date   : 03-Mar-2009
-- Mod Ref    : CR195
-- Mod Details: Added TSL_CHECK_PEIB_FORMAT function and modified
--              VALIDATE_FORMAT function
-------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 13-Apr-2010
-- Defect Ref : NBS00016932
-- Mod Details: Added TSL_CHECK_SBWEAN_FORMAT and TSL_CHECK_SBWOCC_FORMAT
--              function.Modified VALIDATE_FORMAT function
-------------------------------------------------------------------------
FUNCTION CHECK_ALL_NUMBERS(O_error_message IN OUT VARCHAR2,
                           I_item_no       IN     ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_number_length NUMBER(2)    := NULL;
   L_program       VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_ALL_NUMBERS';
BEGIN

   L_number_length := LENGTH(I_item_no);

   WHILE (L_number_length > 0) LOOP
      if ((ASCII(SUBSTR(I_item_no, L_number_length, 1)) > 57 or
           ASCII(SUBSTR(I_item_no, L_number_length, 1)) < 48)) then

         O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_NEW_NUMBER',
                                                     NULL,
                                                     NULL,
                                                     NULL);
         return FALSE;
      end if;

      L_number_length := L_number_length -1;
   END LOOP;

return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_ALL_NUMBERS;
-------------------------------------------------------------------------
FUNCTION CHECK_UPCA_FMT(O_error_message IN OUT VARCHAR2,
                        I_item_no       IN     ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_UPCA_FMT';
BEGIN

   if LENGTH(I_item_no) != 12 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_UPCA',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_UCC(O_error_message, L_return_code, I_item_no);
   if L_return_code != 'TRUE' then
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
END CHECK_UPCA_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_UPCAS_FMT(O_error_message    OUT VARCHAR2,
                         I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_UPCAS_FMT';
BEGIN

   /* The length is the standard UPC-A (12) plus '-' and a 2-5 digit
   supplement code, which makes the codelength between 15 and 18
   */
   if LENGTH(I_item_no) < 15 OR LENGTH(I_item_no) > 18 OR SUBSTR(I_item_no, 13, 1) != '-' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_UPC_SUPP',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, SUBSTR(I_item_no, 14, LENGTH(I_item_no)-13)) = FALSE) then
      return FALSE;
   end if;

   if CHECK_UPCA_FMT(O_error_message, SUBSTR(I_item_no, 1, 12)) = FALSE then
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
END CHECK_UPCAS_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_UPCE_FMT(O_error_message    OUT VARCHAR2,
                        I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_UPC_A VARCHAR2(12) := NULL;
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_UPCE_FMT';
BEGIN

   if LENGTH(I_item_no) != 8 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_UPCE',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   UPC_E_EXPAND(O_error_message, L_return_code, L_UPC_A, I_item_no);
   if L_return_code != 'TRUE' then
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
END CHECK_UPCE_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_UPCES_FMT(O_error_message    OUT VARCHAR2,
                         I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_UPC_A VARCHAR2(12) := NULL;
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_UPCES_FMT';
BEGIN

   /* The length is the standard UPC-E (8) plus '-' and a 2-5 digit
   supplement code, which makes the codelength between 11 and 14
   */
   if LENGTH(I_item_no) < 11 OR LENGTH(I_item_no) > 14 OR SUBSTR(I_item_no, 9, 1) != '-' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_UPC_SUPP',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, SUBSTR(I_item_no, 1, 8)) = FALSE) then
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, SUBSTR(I_item_no, 10, LENGTH(I_item_no)-9)) = FALSE) then
      return FALSE;
   end if;

   UPC_E_EXPAND(O_error_message, L_return_code, L_UPC_A, SUBSTR(I_item_no, 1, 8));
   if L_return_code != 'TRUE' then
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
END CHECK_UPCES_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_UCC14_FMT(O_error_message    OUT VARCHAR2,
                         I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_UCC14_FMT';
BEGIN

   if LENGTH(I_item_no) != 14 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_UCC14',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_UCC(O_error_message, L_return_code, I_item_no);
   if L_return_code != 'TRUE' then
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
END CHECK_UCC14_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_ITEM_FMT(O_error_message    OUT VARCHAR2,
                        I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_check_digit NUMBER(2) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_ITEM_FMT';
BEGIN

   if LENGTH(I_item_no) != 9 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_ITEM_FMT',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY(L_check_digit, I_item_no);
   if L_check_digit = -1 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_CHK_DIG',
                                                  NULL,
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
END CHECK_ITEM_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_EAN8_FMT(O_error_message    OUT VARCHAR2,
                        I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_EAN8_FMT';
BEGIN

   if LENGTH(I_item_no) != 8 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_EAN8',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_UCC(O_error_message, L_return_code, I_item_no);
   if L_return_code != 'TRUE' then
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
END CHECK_EAN8_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_EAN13_FMT(O_error_message    OUT VARCHAR2,
                         I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_EAN13_FMT';
BEGIN

   if LENGTH(I_item_no) != 13 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_EAN13',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_UCC(O_error_message, L_return_code, I_item_no);
   if L_return_code != 'TRUE' then
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
END CHECK_EAN13_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_EAN13S_FMT(O_error_message    OUT VARCHAR2,
                          I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_EAN13S_FMT';
BEGIN

   /* The length is the standard EAN13 (13) plus '-' and a 2-5 digit
   supplement code, which makes the codelength between 16 and 19
   */
   if LENGTH(I_item_no) < 16 OR LENGTH(I_item_no) > 19 OR SUBSTR(I_item_no, 14, 1) != '-' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_UPC_SUPP',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, SUBSTR(I_item_no, 15, LENGTH(I_item_no)-14)) = FALSE) then
      return FALSE;
   end if;

   if CHECK_EAN13_FMT(O_error_message, SUBSTR(I_item_no, 1, 13)) = FALSE then
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
END CHECK_EAN13S_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_SSCC_FMT(O_error_message    OUT VARCHAR2,
                        I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_SSCC_FMT';
BEGIN

   if LENGTH(I_item_no) != 18 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_SSCC',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_UCC(O_error_message, L_return_code, I_item_no);
   if L_return_code != 'TRUE' then
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
END CHECK_SSCC_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_NDC_FMT(O_error_message    OUT VARCHAR2,
                       I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_NDC_FMT';
BEGIN

   if LENGTH(I_item_no) != 12 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_NDC',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_UCC(O_error_message, L_return_code, I_item_no);
   if L_return_code != 'TRUE' then
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
END CHECK_NDC_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_PLU_FMT(O_error_message    OUT VARCHAR2,
                       I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_PLU_FMT';
BEGIN

   if LENGTH(I_item_no) < 4 OR LENGTH(I_item_no) > 5 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_PLU',
                                                  '4 or 5',
                                                  LENGTH(I_item_no),
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
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
END CHECK_PLU_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_ISBN10_FMT(O_error_message    OUT VARCHAR2,
                        I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_ISBN10_FMT';
   L_isbn_length   NUMBER;
BEGIN

   L_isbn_length := length(I_item_no);

   if L_isbn_length != 10 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('ISBN_10CHAR',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, SUBSTR(I_item_no,1, L_isbn_length - 1)) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_ISBN(I_item_no, L_return_code, O_error_message);
   if L_return_code != 'TRUE' then
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
END CHECK_ISBN10_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_ISBN13_FMT(O_error_message    OUT VARCHAR2,
                        I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program  VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.CHECK_ISBN13_FMT';
   L_isbn_length   NUMBER;
BEGIN

   L_isbn_length := length(I_item_no);

   if L_isbn_length != 13 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('ISBN_13CHAR',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, SUBSTR(I_item_no,1, L_isbn_length - 1)) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_ISBN(I_item_no, L_return_code, O_error_message);
   if L_return_code != 'TRUE' then
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
END CHECK_ISBN13_FMT;
-------------------------------------------------------------------------
FUNCTION VALIDATE_FORMAT(O_error_message   IN OUT VARCHAR2,
                         I_item_no         IN     ITEM_MASTER.ITEM%TYPE,
                         I_item_type       IN     ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE)
return BOOLEAN
is
   L_program             VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.VALIDATE_FORMAT';
   -- Mod N105 (Drop 2), 05-Oct-2007, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   L_return_code_code    VARCHAR2(5);
   L_isbn_length         NUMBER       := 0;
   L_rna_type            BOOLEAN;
   -- Mod N105 (Drop 2), 05-Oct-2007, Nitin Gour, nitin.gour@in.tesco.com (END)

BEGIN
   -- Mod N105 (Drop 2), 05-Oct-2007, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   L_isbn_length := LENGTH(I_item_no);
   if TSL_ITEM_NUMBER_SQL.IS_RNA_TYPE(O_error_message,
                                      I_item_type,
                                      L_rna_type) = FALSE then
        return FALSE;
   end if;
   -- Mod N105 (Drop 2), 05-Oct-2007, Nitin Gour, nitin.gour@in.tesco.com (END)
   if (I_item_type = 'UPC-A') then
      if (CHECK_UPCA_FMT(O_error_message, I_item_no) = FALSE) then
         return FALSE;
      end if;
   elsif I_item_type = 'UPC-AS' then
      if CHECK_UPCAS_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'UPC-E' then
      if CHECK_UPCE_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'UPC-ES' then
      if CHECK_UPCES_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'UCC14' then
      if CHECK_UCC14_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'ITEM' then
      if CHECK_ITEM_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'EAN8' then
      if CHECK_EAN8_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'EAN13' then
      if CHECK_EAN13_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'EAN13S' then
      if CHECK_EAN13S_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'ISBN10' then
      if CHECK_ISBN10_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'ISBN13' then
      if CHECK_ISBN13_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'NDC' then
      if CHECK_NDC_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'PLU' then
      if CHECK_PLU_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'SSCC' then
      if CHECK_SSCC_FMT(O_error_message, I_item_no) = FALSE then
         return FALSE;
      end if;
   -- Mod N105 (Drop 2), 05-Oct-2007, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   -- This part will skip the validation of item number type which are coming from
   -- RNA or item number type = 'VAR'
   elsif ((L_rna_type) or
          (I_item_type = 'VAR')) then
         NULL;
   elsif I_item_type = 'EANNON' then
      if not CHECK_EAN13_FMT(O_error_message,
                             I_item_no) then
          return FALSE;
      end if;
   -- Mod N105 (Drop 2), 05-Oct-2007, Nitin Gour, nitin.gour@in.tesco.com (END)
   -- 02-Jun-2008 Dhuraison Prince - Defect NBS006894 BEGIN
   elsif I_item_type = 'TSLMPI' then
      NULL;
   -- 02-Jun-2008 Dhuraison Prince - Defect NBS006894 END
   -- 22-Jul-2008 Dhuraison Prince - Defect NBS008002 BEGIN
   elsif I_item_type = 'PEIB' then
      --CR195 03-Mar-09 Chandru Begin
      if TSL_CHECK_PEIB_FORMAT(O_error_message,
                            I_item_no) = FALSE then
         return FALSE;
      end if;
      --CR195 03-Mar-09 Chandru End
   -- 22-Jul-2008 Dhuraison Prince - Defect NBS008002 END
   -- NBS00016932, 13-Apr-2010, Nitin Kumar, nitin.kumar@in.tesco.com, Begin
   elsif I_item_type = 'SBWEAN' then
      if TSL_CHECK_SBWEAN_FORMAT(O_error_message,
                                 I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'SBWOCC' then
      if TSL_CHECK_SBWOCC_FORMAT(O_error_message,
                                 I_item_no) = FALSE then
         return FALSE;
      end if;
   -- NBS00016932, 13-Apr-2010, Nitin Kumar, nitin.kumar@in.tesco.com, End
   -- NBS00019715, 12-Nov-2010, Sripriya.karanam@in.tesco.com, Begin
   elsif I_item_type = 'EANBRCDE' then
      if TSL_CHECK_EANBRCDE_FMT(O_error_message,
                                 I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'OCCBRCDE' then
      if TSL_CHECK_OCCBRCDE_FMT(O_error_message,
                                 I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'SBWEANBRCDE' then
      if TSL_CHECK_SBWEANBRCDE_FMT(O_error_message,
                                 I_item_no) = FALSE then
         return FALSE;
      end if;
   elsif I_item_type = 'SBWOCCBRCDE' then
      if TSL_CHECK_SBWOCCBRCDE_FMT(O_error_message,
                                 I_item_no) = FALSE then
         return FALSE;
      end if;
   --NBS00019715, 12-Nov-2010, Sripriya.karanam@in.tesco.com, End
   else
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('SYS_INV_ITEM',
                                            I_item_type,
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
END VALIDATE_FORMAT;
-------------------------------------------------------------------------
FUNCTION CHECK_VPLU_FMT(O_error_message   IN OUT VARCHAR2,
                        I_item_no         IN ITEM_MASTER.ITEM%TYPE,
                        I_item_type       IN ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE,
                        I_format_id       IN VAR_UPC_EAN.FORMAT_ID%TYPE)
return BOOLEAN
is
   L_return_code      VARCHAR2(5)                         := NULL;
   L_program          VARCHAR2(50)                        := 'ITEM_NUMBER_TYPE_SQL.CHECK_VPLU_FMT';
   L_begin_item_digit VAR_UPC_EAN.BEGIN_ITEM_DIGIT%TYPE;
   L_begin_var_digit  VAR_UPC_EAN.BEGIN_VAR_DIGIT%TYPE;
   L_check_digit      VAR_UPC_EAN.CHECK_DIGIT%TYPE;
   L_item_length      NUMBER(5);
   L_VPLU_length      NUMBER(2);

   cursor C_VPLU_ATTRIB is
      select begin_item_digit,
             begin_var_digit,
             check_digit
         from  var_upc_ean
         where format_id = I_format_id;
BEGIN
   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   if I_item_type != 'VPLU' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('SYS_INV_ITEM',
                                            I_item_type,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   L_VPLU_length := LENGTH(I_item_no);

   if L_VPLU_length != 12 AND L_VPLU_length != 13 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_VPLU',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   if substr(I_item_no, 1, 1) != '2' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_VPLU_START',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   CHKDIG_VERIFY_UCC(O_error_message, L_return_code, I_item_no);
   if L_return_code != 'TRUE' then
      return FALSE;
   end if;

   open  C_VPLU_ATTRIB;
   fetch C_VPLU_ATTRIB into L_begin_item_digit,
                            L_begin_var_digit,
                            L_check_digit;
   if (C_VPLU_ATTRIB%NOTFOUND) then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_PREFIX',
                                            NULL,
                                            NULL,
                                            NULL);
      close C_VPLU_ATTRIB;
      return FALSE;
   end if;
   close C_VPLU_ATTRIB;

   --Calculate the length of the PLU within the VPLU
   if L_check_digit = 0 then
      L_item_length := L_begin_var_digit-L_begin_item_digit;
   ELSE
      L_item_length := L_check_digit-L_begin_item_digit;
   end if;

   if VALIDATE_FORMAT(O_error_message, substr(I_item_no, L_begin_item_digit, L_item_length), 'PLU') = FALSE then
      return FALSE;
   end if;

   if L_check_digit != 0 then
      CHKDIG_VERIFY_PRC(O_error_message, L_return_code, substr(I_item_no, L_check_digit, L_VPLU_length-L_check_digit));
      if L_return_code != 'TRUE' then
         return FALSE;
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
END CHECK_VPLU_FMT;
-------------------------------------------------------------------------
FUNCTION CHECK_VPLU_FMT(O_error_message   IN OUT VARCHAR2,
                        I_plu_code        IN ITEM_MASTER.ITEM%TYPE,
                        I_prefix_code     IN VAR_UPC_EAN.DEFAULT_PREFIX%TYPE,
                        I_format_id       IN VAR_UPC_EAN.FORMAT_ID%TYPE)
return BOOLEAN
is
   L_return_code      VARCHAR2(5)                          := NULL;
   L_program          VARCHAR2(50)                         := 'ITEM_NUMBER_TYPE_SQL.CHECK_VPLU_FMT';
   L_begin_item_digit VAR_UPC_EAN.BEGIN_ITEM_DIGIT%TYPE;
   L_begin_var_digit  VAR_UPC_EAN.BEGIN_VAR_DIGIT%TYPE;
   L_check_digit      VAR_UPC_EAN.CHECK_DIGIT%TYPE;
   L_item_length      NUMBER(1);

   cursor C_VPLU_ATTRIB is
      select begin_item_digit,
             begin_var_digit,
             check_digit
         from  var_upc_ean
         where format_id = I_format_id;
BEGIN
   open  C_VPLU_ATTRIB;
   fetch C_VPLU_ATTRIB into L_begin_item_digit,
                            L_begin_var_digit,
                            L_check_digit;
   if (C_VPLU_ATTRIB%NOTFOUND) then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_FORMAT_ID',
                                            NULL,
                                            NULL,
                                            NULL);
      close C_VPLU_ATTRIB;
      return FALSE;
   end if;
   close C_VPLU_ATTRIB;

   if L_begin_item_digit - 1 != LENGTH(I_prefix_code) then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_PREFIX_CODE',
                                            L_begin_item_digit - 1,
                                            LENGTH(I_prefix_code),
                                            NULL);
      return false;
   end if;

   if substr(I_prefix_code, 1, 1) != '2' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_VPLU_START',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   if L_check_digit = 0 then
      L_item_length := L_begin_var_digit-L_begin_item_digit;
   ELSE
      L_item_length := L_check_digit-L_begin_item_digit;
   end if;

   if L_item_length != LENGTH(I_plu_code) then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_PLU',
                                            L_item_length,
                                            LENGTH(I_plu_code),
                                            NULL);
      return false;
   end if;

   if VALIDATE_FORMAT(O_error_message, I_plu_code, 'PLU') = FALSE then
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
END CHECK_VPLU_FMT;
-------------------------------------------------------------------------
FUNCTION GET_NEXT(O_error_message   IN OUT VARCHAR2,
                  IO_item_no        IN OUT ITEM_MASTER.ITEM%TYPE,
                  I_item_type       IN ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE)
return BOOLEAN
is
   L_return_code VARCHAR2(5) := NULL;
   L_program VARCHAR2(50)  := 'ITEM_NUMBER_TYPE_SQL.GET_NEXT';
   L_ean13   ITEM_MASTER.ITEM%TYPE;
BEGIN
   if I_item_type = 'ITEM' then
      if ITEM_ATTRIB_SQL.NEXT_ITEM(O_error_message, IO_item_no) = FALSE then
         return FALSE;
      end if;
     return true;
   elsif I_item_type = 'UPC-A' then
      NEXT_UPC_A(O_error_message, L_return_code, IO_item_no);
      if L_return_code != 'TRUE' then
         return FALSE;
      end if;
   elsif I_item_type = 'UPC-AS' then
      NEXT_UPC_A(O_error_message, L_return_code, IO_item_no);
      if L_return_code != 'TRUE' then
         return FALSE;
      end if;
      IO_item_no := RPAD(IO_item_no,13,'-');
      IO_item_no := RPAD(IO_item_no,18,'0');
   elsif I_item_type = 'EAN13' then
      if ITEM_ATTRIB_SQL.NEXT_EAN(O_error_message,
                                  L_ean13) = FALSE then
         return FALSE;
      end if;
      IO_item_no := L_ean13;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_NEXT;
-------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 01-Feb-2008
-- Mod Ref    : N105a
-- Mod Details: Modified the function TSL_GET_NEXT
-------------------------------------------------------------------------
FUNCTION TSL_GET_NEXT(O_error_message   IN OUT VARCHAR2,
                      IO_item_no        IN OUT ITEM_MASTER.ITEM%TYPE,
                      I_item_type       IN     ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE)
return BOOLEAN is
    L_program     VARCHAR2(50)  := 'ITEM_NUMBER_TYPE_SQL.TSL_GET_NEXT';
    L_rna_type    BOOLEAN;
    ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
    L_use_rna_ind   SYSTEM_OPTIONS.TSL_RNA_IND%TYPE;
    ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End
BEGIN

    if TSL_ITEM_NUMBER_SQL.IS_RNA_TYPE(O_error_message,
                                       I_item_type,
                                       L_rna_type) = FALSE then
        return FALSE;
   end if;

   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 Begin
   if SYSTEM_OPTIONS_SQL.TSL_GET_RNA_IND(O_error_message,
                                         L_use_rna_ind) = FALSE then
      return FALSE;
   end if;
   ---DefNBS005996 ,Tarun Kumar Mishra ,tarun.mishra@in.tesco.com ,09-DEC-2008 End


   if L_rna_type = TRUE  and L_use_rna_ind = 'Y'  then
        if NOT TSL_RNA_SQL.GET_REF_NO(O_error_message,
                                      I_item_type,
                                      IO_item_no) then
            return FALSE;
        end if;
   end if;

    return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_NEXT;
-------------------------------------------------------------------------
FUNCTION TSL_CHECK_ALL_NUMBERS(O_error_message   IN OUT VARCHAR2,
                               I_item_no         IN     ITEM_MASTER.ITEM%TYPE)
return BOOLEAN
is
    L_number_length   NUMBER       := NULL;
    L_program         VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.TSL_CHECK_ALL_NUMBERS';

BEGIN
    L_number_length := LENGTH(I_ITEM_NO);
    WHILE (L_number_length > 0) LOOP
        if ((ASCII(SUBSTR(I_item_no, L_number_length, 1)) > 57
          or ASCII(SUBSTR(I_item_no, L_number_length, 1)) < 48)
           or ASCII (SUBSTR(I_item_no, L_number_length, 1)) = 96) then
            O_error_message := SQL_LIB.GET_MESSAGE_TEXT('INV_NEW_NUMBER',
                                                        L_number_length,
                                                        I_item_no,
                                                        NULL);
        end if;
      L_number_length := L_number_length - 1;
    END LOOP;

    return TRUE;

EXCEPTION
    when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
    return FALSE;
END TSL_CHECK_ALL_NUMBERS;
-------------------------------------------------------------------------
-- Function : TSL_CHECK_PEIB_FORMAT
-- Purpose  : This function validates the passed in item number against
--            the format for the PEIB item type
-------------------------------------------------------------------------
FUNCTION TSL_CHECK_PEIB_FORMAT(O_error_message   IN OUT VARCHAR2,
                               I_item_no         IN     ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_program         VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.TSL_CHECK_PEIB_FORMAT';

BEGIN
   if (CHECK_ALL_NUMBERS(O_error_message,
                         I_item_no) = FALSE) then
      return FALSE;
   end if;

   if LENGTH(I_item_no) != 13 or
      SUBSTR(I_item_no, 1, 1) != '2' or
      SUBSTR(I_item_no, 2, 1) != '1' or
      SUBSTR(I_item_no, 7, 7) != '0000000' or
      SUBSTR(I_item_no, 3, 4)  = '0000' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_PEIB',
                                                  NULL,
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
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_PEIB_FORMAT;
-------------------------------------------------------------------------
-- NBS00016932, 13-Apr-2010, Nitin Kumar, nitin.kumar@in.tesco.com (BEGIN)
-------------------------------------------------------------------------
-- Function : TSL_CHECK_SBWEAN_FORMAT
-- Purpose  : This function validates the passed in item number against
--            the format for the SBWEAN item type
-------------------------------------------------------------------------
FUNCTION TSL_CHECK_SBWEAN_FORMAT(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 I_item_no         IN     ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_program         VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.TSL_CHECK_SBWEAN_FORMAT';

BEGIN
   if (CHECK_ALL_NUMBERS(O_error_message,
                         I_item_no) = FALSE) then
      return FALSE;
   end if;

   if LENGTH(I_item_no) != 13 or
      SUBSTR(I_item_no, 1, 1) != '2' or
      SUBSTR(I_item_no, 2, 1) != '0' or
      SUBSTR(I_item_no, 8, 6) != '000000' or
      SUBSTR(I_item_no, 3, 5)  = '00000' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_SBWEAN',
                                                  NULL,
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
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_SBWEAN_FORMAT;
-------------------------------------------------------------------------
-- Function : TSL_CHECK_SBWOCC_FORMAT
-- Purpose  : This function validates the passed in item number against
--            the format for the SBWOCC item type
-------------------------------------------------------------------------
FUNCTION TSL_CHECK_SBWOCC_FORMAT(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item_no         IN     ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_program         VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.TSL_CHECK_SBWEAN_FORMAT';

BEGIN
   if (CHECK_ALL_NUMBERS(O_error_message,
                         I_item_no) = FALSE) then
      return FALSE;
   end if;

   if LENGTH(I_item_no) != 14 or
      SUBSTR(I_item_no, 1, 1) != '0' or
      SUBSTR(I_item_no, 2, 1) != '2' or
      SUBSTR(I_item_no, 3, 1) != '0' or
      SUBSTR(I_item_no, 9, 6) != '000000' or
      SUBSTR(I_item_no, 4, 5)  = '00000' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_SBWOCC',
                                                  NULL,
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
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_SBWOCC_FORMAT;
-------------------------------------------------------------------------
-- NBS00016932, 13-Apr-2010, Nitin Kumar, nitin.kumar@in.tesco.com (END)
-------------------------------------------------------------------------
-- NBS00019715, 12-Nov-2010, Sripriya.karanam@in.tesco.com, Begin
-- The below functions are added exclusively for Barcode Move/Exchange screen only
--for a typical requirement .
-------------------------------------------------------------------------------
-- Function : TSL_CHECK_EANBRCDE_FMT
-- Purpose  : This function validates the passed in item number against
--            the format for the EANNON item type
-------------------------------------------------------------------------
FUNCTION TSL_CHECK_EANBRCDE_FMT(O_error_message    IN OUT VARCHAR2,
                                I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_return_code     VARCHAR2(5)  := NULL;
   L_program         VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.TSL_CHECK_EANBRCDE_FMT';
BEGIN
    if LENGTH(I_item_no) != 13 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_EANBRCDE',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_UCC(O_error_message, L_return_code, I_item_no);
   if L_return_code != 'TRUE' then
      return FALSE;
   end if;

return TRUE;
EXCEPTION
    when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_EANBRCDE_FMT;
-------------------------------------------------------------------------
-- Function : TSL_CHECK_OCCBRCDE_FMT
-- Purpose  : This function validates the passed in item number against
--            the format for the  UCC14 item type
-------------------------------------------------------------------------
FUNCTION TSL_CHECK_OCCBRCDE_FMT(O_error_message    IN OUT VARCHAR2,
                                I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_return_code     VARCHAR2(5)  := NULL;
   L_program         VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.TSL_CHECK_OCCBRCDE_FMT';
BEGIN
   if LENGTH(I_item_no) != 14 then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_OCCBRCDE',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   if (CHECK_ALL_NUMBERS(O_error_message, I_item_no) = FALSE) then
      return FALSE;
   end if;

   CHKDIG_VERIFY_UCC(O_error_message, L_return_code, I_item_no);
   if L_return_code != 'TRUE' then
      return FALSE;
   end if;
return TRUE;
EXCEPTION
    when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_OCCBRCDE_FMT;
-------------------------------------------------------------------------
-- Function : TSL_CHECK_SBWEANBRCDE_FMT
-- Purpose  : This function validates the passed in item number against
--            the format for the SBWEAN item type
-------------------------------------------------------------------------
FUNCTION TSL_CHECK_SBWEANBRCDE_FMT(O_error_message    IN OUT VARCHAR2,
                                   I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_program         VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.TSL_CHECK_SBWEANBRCDE_FMT';
BEGIN
   if (CHECK_ALL_NUMBERS(O_error_message,
                         I_item_no) = FALSE) then
      return FALSE;
   end if;

   if LENGTH(I_item_no) != 13 or
      SUBSTR(I_item_no, 1, 1) != '2' or
      SUBSTR(I_item_no, 2, 1) != '0' or
      SUBSTR(I_item_no, 8, 6) != '000000' or
      SUBSTR(I_item_no, 3, 5)  = '00000' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_SBWEANBRCDE',
                                                  NULL,
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
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_SBWEANBRCDE_FMT;
-------------------------------------------------------------------------
-- Function : TSL_CHECK_SBWOCCBRCDE_FMT
-- Purpose  : This function validates the passed in item number against
--            the format for the SBWOCC item type
-------------------------------------------------------------------------
FUNCTION TSL_CHECK_SBWOCCBRCDE_FMT(O_error_message    IN OUT VARCHAR2,
                                   I_item_no          IN ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_program         VARCHAR2(50) := 'ITEM_NUMBER_TYPE_SQL.TSL_CHECK_SBWOCCBRCDE_FMT';
BEGIN
   if (CHECK_ALL_NUMBERS(O_error_message,
                         I_item_no) = FALSE) then
      return FALSE;
   end if;

   if LENGTH(I_item_no) != 14 or
      SUBSTR(I_item_no, 1, 1) != '0' or
      SUBSTR(I_item_no, 2, 1) != '2' or
      SUBSTR(I_item_no, 3, 1) != '0' or
      SUBSTR(I_item_no, 9, 6) != '000000' or
      SUBSTR(I_item_no, 4, 5)  = '00000' then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_INV_SBWOCCBRCDE',
                                                  NULL,
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
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CHECK_SBWOCCBRCDE_FMT;
-------------------------------------------------------------------------
-- NBS00019715, 12-Nov-2010, Sripriya.karanam@in.tesco.com, End
-------------------------------------------------------------------------
END ITEM_NUMBER_TYPE_SQL;
/

