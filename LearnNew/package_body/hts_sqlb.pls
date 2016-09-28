CREATE OR REPLACE PACKAGE BODY HTS_SQL AS
--------------------------------------------------------------------
FUNCTION HTS_FEE_EXISTS  (O_error_message	      IN OUT VARCHAR2,
                          O_exists              IN OUT BOOLEAN,
                          I_hts                 IN  hts.hts%TYPE,
                          I_import_country_id   IN  hts.import_country_id%TYPE,
                          I_effect_from         IN  hts.effect_from%TYPE,
                          I_effect_to           IN  hts.effect_to%TYPE)
   return BOOLEAN is

      L_exists      VARCHAR2(1) := NULL;

      cursor C_HTS_FEE is
         select 'Y'
           from hts_fee
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to;
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_HTS_FEE', 'HTS_FEE', NULL);
   open C_HTS_FEE;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_FEE', 'HTS_FEE', NULL);
   fetch C_HTS_FEE into L_exists;
   if C_HTS_FEE%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS_FEE', 'HTS_FEE', NULL);
   close C_HTS_FEE;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.HTS_FEE_EXISTS',
                                             to_char(SQLCODE));
   return FALSE;
END HTS_FEE_EXISTS;
--------------------------------------------------------------------
FUNCTION HTS_TAX_EXISTS  (O_error_message	      IN OUT VARCHAR2,
                          O_exists              IN OUT BOOLEAN,
                          I_hts			IN  hts.hts%TYPE,
                          I_import_country_id	IN  hts.import_country_id%TYPE,
                          I_effect_from		IN  hts.effect_from%TYPE,
                          I_effect_to		IN  hts.effect_to%TYPE)
   return BOOLEAN is

      L_exists      VARCHAR2(1)  := NULL;

      cursor C_HTS_TAX is
         select 'Y'
           from hts_tax
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to;
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_HTS_TAX', 'HTS_TAX', NULL);
   open C_HTS_TAX;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_TAX', 'HTS_TAX', NULL);
   fetch C_HTS_TAX into L_exists;
   if C_HTS_TAX%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS_TAX', 'HTS_TAX', NULL);
   close C_HTS_TAX;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.HTS_TAX_EXISTS',
                                             to_char(SQLCODE));
   return FALSE;
END HTS_TAX_EXISTS;
--------------------------------------------------------------------
FUNCTION HTS_OGA_EXISTS  (O_error_message       IN OUT VARCHAR2,
                          O_exists              IN OUT BOOLEAN,
                          I_hts                 IN  hts.hts%TYPE,
                          I_import_country_id	IN  hts.import_country_id%TYPE,
                          I_effect_from         IN  hts.effect_from%TYPE,
                          I_effect_to           IN  hts.effect_to%TYPE)
   return BOOLEAN is

      L_exists      VARCHAR2(1)  := NULL;

      cursor C_HTS_OGA is
         select 'Y'
           from hts_oga
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to;
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_HTS_OGA', 'HTS_OGA', NULL);
   open C_HTS_OGA;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_OGA', 'HTS_OGA', NULL);
   fetch C_HTS_OGA into L_exists;
   if C_HTS_OGA%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS_OGA', 'HTS_OGA', NULL);
   close C_HTS_OGA;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.HTS_OGA_EXISTS',
					     to_char(SQLCODE));
   return FALSE;

END HTS_OGA_EXISTS;

--------------------------------------------------------------------
FUNCTION HTS_REFERENCE_EXISTS  (O_error_message	IN OUT VARCHAR2,
                          O_exists              IN OUT BOOLEAN,
                          I_hts			IN  hts.hts%TYPE,
                          I_import_country_id	IN  hts.import_country_id%TYPE,
                          I_effect_from		IN  hts.effect_from%TYPE,
                          I_effect_to		IN  hts.effect_to%TYPE)
   return BOOLEAN is

      L_exists      VARCHAR2(1) := NULL;

      cursor C_HTS_REFERENCE is
         select 'Y'
           from hts_reference
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to;
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_HTS_REFERENCE', 'HTS_REFERENCE', NULL);
   open C_HTS_REFERENCE;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_REFERENCE', 'HTS_REFERENCE', NULL);
   fetch C_HTS_REFERENCE into L_exists;
   if C_HTS_REFERENCE%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS_REFERENCE', 'HTS_REFERENCE', NULL);
   close C_HTS_REFERENCE;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.HTS_REFERENCE_EXISTS',
					     to_char(SQLCODE));
   return FALSE;
END HTS_REFERENCE_EXISTS;
--------------------------------------------------------------------
FUNCTION HTS_CVD_EXISTS  (O_error_message	      IN OUT VARCHAR2,
                          O_exists              IN OUT BOOLEAN,
                          I_hts			IN  hts.hts%TYPE,
                          I_import_country_id	IN  hts.import_country_id%TYPE,
                          I_effect_from		IN  hts.effect_from%TYPE,
                          I_effect_to		IN  hts.effect_to%TYPE)
   return BOOLEAN is
      L_exists      VARCHAR2(1) := NULL;

      cursor C_HTS_CVD is
         select 'Y'
           from hts_cvd
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to;
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_HTS_CVD', 'HTS_CVD', NULL);
   open C_HTS_CVD;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_CVD', 'HTS_CVD', NULL);
   fetch C_HTS_CVD into L_exists;
   if C_HTS_CVD%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS_CVD', 'HTS_CVD', NULL);
   close C_HTS_CVD;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.HTS_CVD_EXISTS',
					     to_char(SQLCODE));
   return FALSE;
END HTS_CVD_EXISTS;
--------------------------------------------------------------------
FUNCTION HTS_AD_EXISTS   (O_error_message	IN OUT VARCHAR2,
                          O_exists              IN OUT BOOLEAN,
                          I_hts			IN  hts.hts%TYPE,
                          I_import_country_id	IN  hts.import_country_id%TYPE,
                          I_effect_from		IN  hts.effect_from%TYPE,
                          I_effect_to		IN  hts.effect_to%TYPE)
   return BOOLEAN is

      L_exists      VARCHAR2(1) := NULL;

      cursor C_HTS_AD is
         select 'Y'
           from hts_ad
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to;
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_HTS_AD', 'HTS_AD', NULL);
   open C_HTS_AD;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_AD', 'HTS_AD', NULL);
   fetch C_HTS_AD into L_exists;
   if C_HTS_AD%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS_AD', 'HTS_AD', NULL);
   close C_HTS_AD;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.HTS_AD_EXISTS',
					     to_char(SQLCODE));
   return FALSE;
END HTS_AD_EXISTS;
--------------------------------------------------------------------
FUNCTION HTS_TARIFF_TREATMENT_EXISTS  (O_error_message	IN OUT VARCHAR2,
                          O_exists              IN OUT BOOLEAN,
                          I_hts			IN  hts.hts%TYPE,
                          I_import_country_id	IN  hts.import_country_id%TYPE,
                          I_effect_from		IN  hts.effect_from%TYPE,
                          I_effect_to		IN  hts.effect_to%TYPE,
                          I_tariff_treatment    IN  hts_tariff_treatment.tariff_treatment%TYPE)
   return BOOLEAN is

      L_exists      VARCHAR2(1) := NULL;

      cursor C_HTS_TARIFF_TREATMENT is
         select 'Y'
           from hts_tariff_treatment
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            and tariff_treatment  = nvl(I_tariff_treatment, tariff_treatment);
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN' , 'C_HTS_TARIFF_TREATMENT', 'HTS_TARIFF_TREATMENT', NULL);
   open C_HTS_TARIFF_TREATMENT;
   SQL_LIB.SET_MARK('FETCH' , 'C_HTS_TARIFF_TREATMENT', 'HTS_TARIFF_TREATMENT', NULL);
   fetch C_HTS_TARIFF_TREATMENT into L_exists;
   if C_HTS_TARIFF_TREATMENT%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE' , 'C_HTS_TARIFF_TREATMENT', 'HTS_TARIFF_TREATMENT', NULL);
   close C_HTS_TARIFF_TREATMENT;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.HTS_TARIFF_TREATMENT_EXISTS',
					     to_char(SQLCODE));
   return FALSE;
END HTS_TARIFF_TREATMENT_EXISTS;
--------------------------------------------------------------------
FUNCTION HTS_TT_EXCLUSIONS_EXISTS  (O_error_message	IN OUT VARCHAR2,
                          O_exists              IN OUT BOOLEAN,
                          I_hts			IN  hts.hts%TYPE,
                          I_import_country_id	IN  hts.import_country_id%TYPE,
                          I_effect_from		IN  hts.effect_from%TYPE,
                          I_effect_to		IN  hts.effect_to%TYPE,
                          I_tariff_treatment    IN  hts_tt_exclusions.tariff_treatment%TYPE,
                          I_origin_country_id   IN  hts_tt_exclusions.origin_country_id%TYPE)
   return BOOLEAN is

      L_exists      VARCHAR2(1) := NULL;

      cursor C_HTS_TT_EXCLUSIONS is
         select 'Y'
           from hts_tt_exclusions
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            and tariff_treatment  = nvl(I_tariff_treatment, tariff_treatment)
            and origin_country_id = nvl(I_origin_country_id, origin_country_id);
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN' , 'C_HTS_TT_EXCLUSIONS', 'HTS_TT_EXCLUSIONS', NULL);
   open C_HTS_TT_EXCLUSIONS;
   SQL_LIB.SET_MARK('FETCH' , 'C_HTS_TT_EXCLUSIONS', 'HTS_TT_EXCLUSIONS', NULL);
   fetch C_HTS_TT_EXCLUSIONS into L_exists;
   if C_HTS_TT_EXCLUSIONS%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE' , 'C_HTS_TT_EXCLUSIONS', 'HTS_TT_EXCLUSIONS', NULL);
   close C_HTS_TT_EXCLUSIONS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.HTS_TT_EXCLUSIONS_EXISTS',
					     to_char(SQLCODE));
   return FALSE;
END HTS_TT_EXCLUSIONS_EXISTS;
--------------------------------------------------------------------
FUNCTION GET_HTS_CHAPTER_DESC      (O_error_message	IN OUT  VARCHAR2,
                                    O_chapter_desc	IN OUT  hts_chapter.chapter_desc%TYPE,
                                    I_chapter         IN      hts_chapter.chapter%TYPE)
   return BOOLEAN IS

      cursor C_CHAPTER is
         select chapter_desc
           from hts_chapter
          where chapter = I_chapter;

BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_CHAPTER', 'HTS_CHAPTER', 'Chapter:'||I_chapter);
   open C_CHAPTER;
   SQL_LIB.SET_MARK('FETCH', 'C_CHAPTER', 'HTS_CHAPTER', 'Chapter:'||I_chapter);
   fetch C_CHAPTER into O_chapter_desc;
   if C_CHAPTER%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_CHAPTER',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_CHAPTER', 'HTS_CHAPTER', 'Chapter:'||I_chapter);
      close C_CHAPTER;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_CHAPTER', 'HTS_CHAPTER', 'Chapter:'||I_chapter);
   close C_CHAPTER;

   if LANGUAGE_SQL.TRANSLATE(O_chapter_desc,
                             O_chapter_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.GET_HTS_CHAPTER_DESC',
                                             to_char(SQLCODE));
   return FALSE;
END GET_HTS_CHAPTER_DESC;
---------------------------------------------------------------------------------------------
FUNCTION GET_HTS_DESC  (O_error_message		IN OUT VARCHAR2,
                        O_hts_desc              IN OUT hts.hts_desc%TYPE,
                        I_hts                   IN     hts.hts%TYPE,
                        I_import_country_id	IN     hts.import_country_id%TYPE,
                        I_effect_from		IN     hts.effect_from%TYPE,
                        I_effect_to             IN     hts.effect_to%TYPE)
   return BOOLEAN is

      cursor C_HTS is
         select hts_desc
           from hts
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to;

BEGIN

   SQL_LIB.SET_MARK ('OPEN', 'C_HTS', 'HTS', NULL);
   open C_HTS;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS', 'HTS', NULL);
   fetch C_HTS into O_hts_desc;
   if C_HTS%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_HTS',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_HTS', 'HTS',  NULL);
      close C_HTS;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS', 'HTS', NULL);
   close C_HTS;

   if LANGUAGE_SQL.TRANSLATE(O_hts_desc,
                             O_hts_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.GET_HTS_DESC',
					     to_char(SQLCODE));
   return FALSE;
END GET_HTS_DESC;
---------------------------------------------------------------------------------------------
FUNCTION CHECK_LOCK_HTS(O_error_message       IN OUT VARCHAR2,
                       O_exists               IN OUT BOOLEAN,
                       I_mode                 IN     VARCHAR2,
                       I_hts                  IN     hts.hts%TYPE,
                       I_import_country_id    IN     hts.import_country_id%TYPE,
                       I_effect_from          IN     hts.effect_from%TYPE,
                       I_effect_to            IN     hts.effect_to%TYPE)
   return BOOLEAN is

      L_exists	VARCHAR2(1)      := NULL;
      L_table	VARCHAR2(30);
      RECORD_LOCKED	EXCEPTION;
      PRAGMA	EXCEPTION_INIT(Record_locked, -54);

      cursor C_ITEM_HTS is
         select 'Y'
           from item_hts
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to;

      cursor C_ORDSKU_HTS is
         select 'Y'
           from ordsku_hts os, ordhead oh
          where os.hts               = I_hts
            and os.effect_from       = I_effect_from
            and os.effect_to         = I_effect_to
            and os.order_no          = oh.order_no
            and oh.import_country_id = I_import_country_id;
---
      cursor C_LOCK_HTS_FEE is
         select 'Y'
           from hts_fee
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            for update nowait;

      cursor C_LOCK_HTS_TAX is
         select 'Y'
           from hts_tax
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            for update nowait;

      cursor C_LOCK_HTS_OGA is
         select 'Y'
           from hts_oga
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            for update nowait;

      cursor C_LOCK_HTS_CVD is
         select 'Y'
           from hts_cvd
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            for update nowait;

      cursor C_LOCK_HTS_AD is
         select 'Y'
           from hts_ad
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            for update nowait;

      cursor C_LOCK_HTS_REFERENCE is
         select 'Y'
           from hts_reference
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            for update nowait;

      cursor C_LOCK_TARIFF_TRMT is
         select 'Y'
           from hts_tariff_treatment
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            for update nowait;

      cursor C_LOCK_TT_EXCLUSIONS is
         select 'Y'
           from hts_tt_exclusions
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            for update nowait;

BEGIN
   O_exists := FALSE;
   if I_mode = 'EDIT' then
   --ITEM_HTS--
      open C_ITEM_HTS;
      fetch C_ITEM_HTS into L_exists;
      if C_ITEM_HTS%FOUND then
         close C_ITEM_HTS;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DEL_HTS_ITEM', NULL, NULL, NULL);
         O_exists        := TRUE;
         return TRUE;
      end if;
      close C_ITEM_HTS;
   --PO_ITEM_HTS--
      open C_ORDSKU_HTS;
      fetch C_ORDSKU_HTS into L_exists;
      if C_ORDSKU_HTS%FOUND then
         close C_ORDSKU_HTS;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DEL_HTS_POITEM', NULL, NULL, NULL);
         O_exists        := TRUE;
         return TRUE;
      end if;
      close C_ORDSKU_HTS;
   end if;

--HTS_TT_EXCLUSIONS
   L_table := 'HTS_TT_EXCLUSIONS';
   open C_LOCK_TT_EXCLUSIONS;
   close C_LOCK_TT_EXCLUSIONS;

--HTS_TARIFF_TREATMENT
   L_table := 'HTS_TARIFF_TREATMENT';
   open C_LOCK_TARIFF_TRMT;
   close C_LOCK_TARIFF_TRMT;

--HTS_FEE--
   L_table := 'HTS_FEE';
   open C_LOCK_HTS_FEE;
   close C_LOCK_HTS_FEE;

--HTS_TAX--
   L_table := 'HTS_TAX';
   open C_LOCK_HTS_TAX;
   close C_LOCK_HTS_TAX;

--HTS_OGA--
   L_table := 'HTS_OGA';
   open C_LOCK_HTS_OGA;
   close C_LOCK_HTS_OGA;

--HTS_REFERENCE--
   L_table := 'HTS_REFERENCE';
   open C_LOCK_HTS_REFERENCE;
   close C_LOCK_HTS_REFERENCE;

--HTS_CVD--
   L_table := 'HTS_CVD';
   open C_LOCK_HTS_CVD;
   close C_LOCK_HTS_CVD;

--HTS_AD--
   L_table := 'HTS_AD';
   open C_LOCK_HTS_AD;
   close C_LOCK_HTS_AD;
---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED', L_table,
                                             I_hts, I_import_country_id);
   return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.CHECK_LOCK_HTS',
                                             to_char(SQLCODE));
   return FALSE;
END CHECK_LOCK_HTS;
---------------------------------------------------------------------------------------------
FUNCTION DELETE_HTS      (O_error_message       IN OUT VARCHAR2,
                          I_hts			IN     hts.hts%TYPE,
                          I_import_country_id	IN     hts.import_country_id%TYPE,
                          I_effect_from		IN     hts.effect_from%TYPE,
                          I_effect_to		IN     hts.effect_to%TYPE)
   return BOOLEAN is

BEGIN
--HTS_TT_EXCLUSIONS
   delete from hts_tt_exclusions
    where hts               = I_hts
      and import_country_id = I_import_country_id
      and effect_from       = I_effect_from
      and effect_to         = I_effect_to;

--HTS_TARIFF_TREATMENT
   delete from hts_tariff_treatment
    where hts               = I_hts
      and import_country_id = I_import_country_id
      and effect_from       = I_effect_from
      and effect_to         = I_effect_to;

--HTS_FEE--
   delete from hts_fee
    where hts               = I_hts
      and import_country_id = I_import_country_id
      and effect_from       = I_effect_from
      and effect_to         = I_effect_to;

--HTS_TAX--
   delete from hts_tax
    where hts               = I_hts
      and import_country_id = I_import_country_id
      and effect_from       = I_effect_from
      and effect_to         = I_effect_to;

--HTS_OGA--
   delete from hts_oga
    where hts               = I_hts
      and import_country_id = I_import_country_id
      and effect_from       = I_effect_from
      and effect_to         = I_effect_to;

--HTS_REFERENCE--
   delete from hts_reference
    where hts               = I_hts
      and import_country_id = I_import_country_id
      and effect_from       = I_effect_from
      and effect_to         = I_effect_to;

--HTS_CVD--
   delete from hts_cvd
    where hts               = I_hts
      and import_country_id = I_import_country_id
      and effect_from       = I_effect_from
      and effect_to         = I_effect_to;

--HTS_AD--
   delete from hts_ad
    where hts               = I_hts
      and import_country_id = I_import_country_id
      and effect_from       = I_effect_from
      and effect_to         = I_effect_to;
---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.DELETE_HTS',
                                             to_char(SQLCODE));
   return FALSE;
END DELETE_HTS;

---------------------------------------------------------------------------------------------
FUNCTION CHECK_LOCK_HTS_CHAPTER(O_error_message      IN OUT VARCHAR2,
                                O_exists             IN OUT BOOLEAN,
                                I_hts_chapter        IN  hts_chapter.chapter%TYPE)

   return BOOLEAN is

      L_exists	VARCHAR2(1) := NULL;
      L_table	VARCHAR2(30);
      RECORD_LOCKED	EXCEPTION;
      PRAGMA	EXCEPTION_INIT(Record_locked, -54);

      cursor C_HTS is
         select 'Y'
           from hts
          where chapter = I_hts_chapter;

      cursor C_LOCK_HTS_CHAPTER_RESTRAINTS is
         select 'Y'
           from hts_chapter_restraints
          where chapter     = I_hts_chapter
            for update nowait;

      cursor C_LOCK_REQ_DOC is
         select 'Y'
           from req_doc
           where module     = 'HTSC'
           and key_value_1  = I_hts_chapter
           for update nowait;

BEGIN
   O_exists := FALSE;
--HTS--
   open C_HTS;
   fetch C_HTS into L_exists;
   if C_HTS%FOUND then
      close C_HTS;
      O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DEL_CHAP_HTS',NULL, NULL, NULL);
      O_exists := TRUE;
      return TRUE;
   end if;
   close C_HTS;
--HTS_CHAPTER_RESTRAINTS--
   L_table := 'HTS_CHAPTER_RESTRAINTS';
   open C_LOCK_HTS_CHAPTER_RESTRAINTS;
   close C_LOCK_HTS_CHAPTER_RESTRAINTS;

--REQ_DOC--
   L_table := 'REQ_DOC';
   open C_LOCK_REQ_DOC;
   close C_LOCK_REQ_DOC;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED', L_table,
                                             I_hts_chapter, NULL);
   return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.CHECK_LOCK_HTS_CHAPTER',
                                             to_char(SQLCODE));
   return FALSE;
END CHECK_LOCK_HTS_CHAPTER;
---------------------------------------------------------------------------------------------
FUNCTION DELETE_HTS_CHAPTER    (O_error_message      IN OUT VARCHAR2,
                                I_hts_chapter        IN  hts_chapter.chapter%TYPE)
   return BOOLEAN is

BEGIN
--HTS_CHAPTER_RESTRAINTS--
   delete from hts_chapter_restraints
    where chapter = I_hts_chapter;

--REQ_DOC--
   delete from req_doc
         where module      = 'HTSC'
           and key_value_1 = I_hts_chapter;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.DELETE_HTS_CHAPTER',
                                             to_char(SQLCODE));
   return FALSE;
END DELETE_HTS_CHAPTER;

---------------------------------------------------------------------------------------------
FUNCTION GET_HTS_INFO (O_error_message     IN OUT VARCHAR2,
                       O_hts_desc		 IN OUT hts.hts_desc%TYPE,
                       O_chapter		 IN OUT hts.chapter%TYPE,
                       O_quota_cat		 IN OUT hts.quota_cat%TYPE,
                       O_more_hts_ind	 IN OUT hts.more_hts_ind%TYPE,
                       O_duty_comp_code	 IN OUT hts.duty_comp_code%TYPE,
                       O_units		 IN OUT hts.units%TYPE,
                       O_units_1		 IN OUT hts.units_1%TYPE,
                       O_units_2		 IN OUT hts.units_2%TYPE,
                       O_units_3		 IN OUT hts.units_3%TYPE,
                       O_cvd_ind		 IN OUT hts.cvd_ind%TYPE,
                       O_ad_ind		 IN OUT hts.ad_ind%TYPE,
                       O_quota_ind		 IN OUT hts.quota_ind%TYPE,
                       I_hts               IN     hts.hts%TYPE,
                       I_import_country_id IN     hts.import_country_id%TYPE,
                       I_effect_from	 IN     hts.effect_from%TYPE,
                       I_effect_to		 IN     hts.effect_to%TYPE)
   return BOOLEAN is

      cursor C_GET_INFO is
         select hts_desc,
                chapter,
                quota_cat,
                more_hts_ind,
                duty_comp_code,
                units,
                units_1,
                units_2,
                units_3,
                cvd_ind,
                ad_ind,
                quota_ind
           from hts
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to;

BEGIN
   SQL_LIB.SET_MARK ('OPEN', 'C_GET_INFO', 'HTS', NULL);
   open C_GET_INFO;
   SQL_LIB.SET_MARK('FETCH', 'C_GET_INFO', 'HTS', NULL);
   fetch C_GET_INFO into O_hts_desc,
                         O_chapter,
                         O_quota_cat,
                         O_more_hts_ind,
                         O_duty_comp_code,
                         O_units,
                         O_units_1,
                         O_units_2,
                         O_units_3,
                         O_cvd_ind,
                         O_ad_ind,
                         O_quota_ind;
   if C_GET_INFO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_HTS',NULL, NULL, NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_INFO', 'HTS', NULL);
      close C_GET_INFO;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE' , 'C_GET_INFO', 'HTS', NULL);
   close C_GET_INFO;

   if LANGUAGE_SQL.TRANSLATE(O_hts_desc,
                             O_hts_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.GET_HTS_INFO',
					     to_char(SQLCODE));
   return FALSE;
END GET_HTS_INFO;
---------------------------------------------------------------------------------------------
FUNCTION HTS_COUNT (O_error_message	IN OUT VARCHAR2,
                    O_count         IN OUT NUMBER,
                    I_hts           IN     HTS.HTS%TYPE,
                    I_import_country_id	IN     HTS.IMPORT_COUNTRY_ID%TYPE)
   RETURN BOOLEAN is

      cursor C_HTS_COUNT is
         select count(hts)
           from hts
          where hts               = I_hts
            and import_country_id = I_import_country_id;

BEGIN
   SQL_LIB.SET_MARK ('OPEN', 'C_HTS_COUNT', 'HTS',
                     'hts:'||I_hts||' import country id:'||I_import_country_id);
   open C_HTS_COUNT;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_COUNT', 'HTS',
                    'hts:'||I_hts||'import country id:'||I_import_country_id);
   fetch C_HTS_COUNT into O_count;
   SQL_LIB.SET_MARK('CLOSE' , 'C_HTS_COUNT', 'HTS',
                    'hts:'||I_hts||' import country id:'||I_import_country_id);
   close C_HTS_COUNT;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.HTS_COUNT',
					     to_char(SQLCODE));
   return FALSE;
END HTS_COUNT;
---------------------------------------------------------------------------------------------
FUNCTION GET_EFFECTIVE_DATES (O_error_message	        IN OUT VARCHAR2,
                              O_effect_from             IN OUT HTS.EFFECT_FROM%TYPE,
                              O_effect_to               IN OUT HTS.EFFECT_TO%TYPE,
                              I_hts                     IN     HTS.HTS%TYPE,
                              I_import_country_id       IN     HTS.IMPORT_COUNTRY_ID%TYPE)
   return BOOLEAN is

      cursor C_DATES is
         select effect_from,
                effect_to
           from hts
          where hts               = I_hts
            and import_country_id = I_import_country_id;

BEGIN
   SQL_LIB.SET_MARK ('OPEN', 'C_DATES', 'HTS',
                     'hts:'||I_hts||' import_country_id:'||I_import_country_id);
   open C_DATES;
   SQL_LIB.SET_MARK('FETCH', 'C_DATES', 'HTS',
                    'hts:'||I_hts||' import_country_id:'||I_import_country_id);
   fetch C_DATES into O_effect_from,
                      O_effect_to;
   if C_DATES%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_HTS_IMP',NULL, NULL, NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_DATES', 'HTS',
                       'hts:'||I_hts||' import_country_id:'||I_import_country_id);
      close C_DATES;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE' , 'C_DATES', 'HTS',
                    'hts:'||I_hts||' import_country_id:'||I_import_country_id);
   close C_DATES;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.GET_EFFECTIVE_DATES',
					     to_char(SQLCODE));
   return FALSE;

END GET_EFFECTIVE_DATES;
---------------------------------------------------------------------------------------------
FUNCTION GET_VALID_EFFECTIVE_DATES (O_error_message	        IN OUT VARCHAR2,
                                    O_effect_from             IN OUT HTS.EFFECT_FROM%TYPE,
                                    O_effect_to               IN OUT HTS.EFFECT_TO%TYPE,
                                    I_hts                     IN     HTS.HTS%TYPE,
                                    I_import_country_id       IN     HTS.IMPORT_COUNTRY_ID%TYPE,
                                    I_date                    IN     HTS.EFFECT_FROM%TYPE)
   return BOOLEAN is
   ---
   L_date             HTS.EFFECT_FROM%TYPE       := NULL;
   ---
      cursor C_DATES is
         select effect_from,
                effect_to
           from hts
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       <= L_date
            and effect_to         >= L_date;

BEGIN
   L_date := nvl(I_date, get_vdate);
   SQL_LIB.SET_MARK ('OPEN', 'C_DATES', 'HTS',
                     'hts:'||I_hts||' import_country_id:'||I_import_country_id);
   open C_DATES;
   SQL_LIB.SET_MARK('FETCH', 'C_DATES', 'HTS',
                    'hts:'||I_hts||' import_country_id:'||I_import_country_id);
   fetch C_DATES into O_effect_from,
                      O_effect_to;
   if C_DATES%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_HTS_IMP',NULL, NULL, NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_DATES', 'HTS',
                       'hts:'||I_hts||' import_country_id:'||I_import_country_id);
      close C_DATES;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE' , 'C_DATES', 'HTS',
                    'hts:'||I_hts||' import_country_id:'||I_import_country_id);
   close C_DATES;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
				             SQLERRM,
					    'HTS_SQL.GET_EFFECTIVE_DATES',
					     to_char(SQLCODE));
   return FALSE;

END GET_VALID_EFFECTIVE_DATES;
---------------------------------------------------------------------------------------------
FUNCTION GET_QUOTA_CATEGORY_DESC(O_error_message	IN OUT VARCHAR2,
                                 O_quota_cat_desc	IN OUT QUOTA_CATEGORY.CATEGORY_DESC%TYPE,
                                 I_quota_cat		IN     QUOTA_CATEGORY.QUOTA_CAT%TYPE,
                                 I_import_country_id	IN     QUOTA_CATEGORY.IMPORT_COUNTRY_ID%TYPE)
   return BOOLEAN is

      cursor C_QUOTA is
         select category_desc
           from quota_category
          where quota_cat          = I_quota_cat
            and import_country_id = I_import_country_id;
BEGIN
   SQL_LIB.SET_MARK ('OPEN', 'C_QUOTA', 'QUOTA_CATEGORY',
		     'quota category:'||I_quota_cat||' import_country_id:'||I_import_country_id);
   open C_QUOTA;
   SQL_LIB.SET_MARK ('FETCH', 'C_QUOTA', 'QUOTA_CATEGORY',
		     'quota category:'||I_quota_cat||' import_country_id:'||I_import_country_id);
   fetch C_QUOTA into O_quota_cat_desc;
   if C_QUOTA%NOTFOUND then
      SQL_LIB.SET_MARK ('CLOSE', 'C_QUOTA', 'QUOTA_CATEGORY',
	         'quota category:'||I_quota_cat||' import_country_id:'||I_import_country_id);
      close C_QUOTA;
      O_error_message := SQL_LIB.CREATE_MSG('QUOTA_CAT_INV',NULL, NULL, NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK ('CLOSE', 'C_QUOTA', 'QUOTA_CATEGORY',
          'quota category:'||I_quota_cat||' import_country_id:'||I_import_country_id);
   close C_QUOTA;

   if LANGUAGE_SQL.TRANSLATE(O_quota_cat_desc,
                             O_quota_cat_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.GET_QUOTA_CATEGORY_DESC',
                                             to_char(SQLCODE));
   return FALSE;

END GET_QUOTA_CATEGORY_DESC;
-----------------------------------------
FUNCTION HTS_VDATE (O_error_message	      IN OUT VARCHAR2,
		        O_return_value	      IN OUT BOOLEAN,
		        I_hts	    	      IN     HTS.HTS%TYPE,
                    I_import_country_id	IN     HTS.IMPORT_COUNTRY_ID%TYPE)
   return BOOLEAN is

   L_vdate HTS.EFFECT_FROM%TYPE := Get_Vdate;
   L_exists      VARCHAR2(1) := NULL;

      cursor C_HTS_VDATE is
        select 'Y'
          from hts
         where hts               = I_hts
           and import_country_id = I_import_country_id
           and effect_from <= L_vdate
           and effect_to >= L_vdate;

BEGIN
   O_return_value := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_HTS_VDATE', 'HTS', NULL);
   open C_HTS_VDATE;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_VDATE','HTS', NULL);
   fetch C_HTS_VDATE into L_exists;
   if C_HTS_VDATE%FOUND then
      O_return_value := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS_VDATE','HTS', NULL);
   close C_HTS_VDATE;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.HTS_VDATE',
                                             to_char(SQLCODE));
   return FALSE;
END HTS_VDATE;
-----------------------------------------
FUNCTION IMPORT_COUNTRY_EXISTS
	(O_error_message        IN OUT   VARCHAR2,
	 O_exists               IN OUT   BOOLEAN,
	 I_import_country_id	IN       COUNTRY.COUNTRY_ID%TYPE)

   return BOOLEAN is
      L_exists      VARCHAR2(1) := NULL;

      cursor C_COUNTRY is
         select 'Y'
           from hts
          where import_country_id = I_import_country_id;

BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_COUNTRY', 'HTS', 'import country id: '||I_import_country_id);
   open C_COUNTRY;
   SQL_LIB.SET_MARK('FETCH', 'C_COUNTRY', 'HTS', 'import country id: '||I_import_country_id);
   fetch C_COUNTRY into L_exists;
   if C_COUNTRY%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_COUNTRY', 'HTS', 'import country id: '||I_import_country_id);
   close C_COUNTRY;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.IMPORT_COUNTRY_EXISTS',
                                             to_char(SQLCODE));
   return FALSE;
END IMPORT_COUNTRY_EXISTS;

---------------------------------------------------------------------------------------------
FUNCTION VALIDATE_HTS_DATE_RANGE  (O_error_message	  IN OUT VARCHAR2,
                                   O_exists             IN OUT BOOLEAN,
                                   I_hts                IN     hts.hts%TYPE,
                                   I_import_country_id  IN     hts.import_country_id%TYPE,
                                   I_effect_from        IN     hts.effect_from%TYPE,
                                   I_effect_to          IN     hts.effect_to%TYPE)

   return BOOLEAN is
      L_exists      VARCHAR2(1) := NULL;

      cursor C_DATE_RANGE is
         select 'Y'
           from hts
          where import_country_id      = I_import_country_id
            and hts                    = I_hts
            and (I_effect_from between effect_from
                                   and effect_to
                 or I_effect_to between effect_from
                                    and effect_to
                 or (effect_from > I_effect_from
                     and I_effect_to > effect_to));
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_DATE_RANGE','HTS', NULL);
   open C_DATE_RANGE;
   SQL_LIB.SET_MARK('FETCH', 'C_DATE_RANGE','HTS',  NULL);
   fetch C_DATE_RANGE into L_exists;
   if C_DATE_RANGE%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_DATE_RANGE', 'HTS', NULL);
   close C_DATE_RANGE;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.VALIDATE_HTS_DATE_RANGE',
                                             to_char(SQLCODE));
   return FALSE;
END VALIDATE_HTS_DATE_RANGE;
----------------------------------------------------------------
FUNCTION VALIDATE_HTS_CVD  (O_error_message	IN OUT VARCHAR2,
                            O_exists            IN OUT BOOLEAN,
                            I_hts			IN     hts.hts%TYPE,
                            I_import_country_id	IN     hts.import_country_id%TYPE,
                            I_effect_from		IN     hts.effect_from%TYPE,
                            I_effect_to		IN     hts.effect_to%TYPE,
                            I_origin_country_id IN     hts_cvd.origin_country_id%TYPE)
   RETURN BOOLEAN is

   L_exists	VARCHAR2(1) := NULL;

      cursor C_HTS_CVD is
         select 'Y'
           from hts_cvd
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            and origin_country_id = I_origin_country_id;
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_HTS_CVD', 'HTS_CVD', NULL);
   open C_HTS_CVD;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_CVD', 'HTS_CVD', NULL);
   fetch C_HTS_CVD into L_exists;
   if C_HTS_CVD%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS_CVD', 'HTS_CVD', NULL);
   close C_HTS_CVD;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.VALIDATE_HTS_CVD',
                                             to_char(SQLCODE));
   return FALSE;
END VALIDATE_HTS_CVD;
----------------------------------------------------------------
FUNCTION VALIDATE_HTS_AD  (O_error_message     IN OUT VARCHAR2,
                           O_exists            IN OUT BOOLEAN,
                           I_hts		     IN     hts.hts%TYPE,
                           I_import_country_id IN     hts.import_country_id%TYPE,
                           I_effect_from	     IN     hts.effect_from%TYPE,
                           I_effect_to	     IN     hts.effect_to%TYPE,
                           I_origin_country_id IN     hts_ad.origin_country_id%TYPE,
                           I_mfg_id            IN     hts_ad.mfg_id%TYPE)
   RETURN BOOLEAN is

   L_exists	VARCHAR2(1) := NULL;

      cursor C_HTS_AD is
         select 'Y'
           from hts_ad
          where hts               = I_hts
            and import_country_id = I_import_country_id
            and effect_from       = I_effect_from
            and effect_to         = I_effect_to
            and origin_country_id = I_origin_country_id
            and mfg_id            = I_mfg_id;
BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_HTS_AD', 'HTS_AD', NULL);
   open C_HTS_AD;
   SQL_LIB.SET_MARK('FETCH', 'C_HTS_AD', 'HTS_AD', NULL);
   fetch C_HTS_AD into L_exists;
   if C_HTS_AD%FOUND then
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_HTS_AD', 'HTS_AD', NULL);
   close C_HTS_AD;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'HTS_SQL.VALIDATE_HTS_AD',
                                             to_char(SQLCODE));
   return FALSE;
END VALIDATE_HTS_AD;
----------------------------------------------------------------
FUNCTION QUOTA_CAT_EXISTS (O_error_message      IN OUT VARCHAR2,
                           O_exists             IN OUT BOOLEAN,
                           I_quota_cat          IN     QUOTA_CATEGORY.QUOTA_CAT%TYPE,
                           I_import_country_id  IN     QUOTA_CATEGORY.IMPORT_COUNTRY_ID%TYPE)

   return BOOLEAN is

      L_exists      VARCHAR2(1);
      ---
      cursor C_QUOTA_CAT_RESTRAINTS is
         select 'Y'
           from hts_chapter_restraints
          where quota_cat         = I_quota_cat
            and import_country_id = I_import_country_id;
      ---
      cursor C_QUOTA_CAT_HTS is
         select 'Y'
           from hts
          where quota_cat         = I_quota_cat
            and import_country_id = I_import_country_id;

BEGIN
   O_exists := FALSE;
   SQL_LIB.SET_MARK('OPEN', 'C_QUOTA_CAT_RESTRAINTS', 'HTS_CHAPTER_RESTRAINTS',
                    'import country id: '||I_import_country_id||':'||'quota_cat: '||I_quota_cat);
   open C_QUOTA_CAT_RESTRAINTS;
   SQL_LIB.SET_MARK('FETCH', 'C_QUOTA_CAT_RESTRAINTS', 'HTS_CHAPTER_RESTRAINTS',
                    'import country id: '||I_import_country_id||':'||'quota_cat: '||I_quota_cat);
   fetch C_QUOTA_CAT_RESTRAINTS into L_exists;
   if C_QUOTA_CAT_RESTRAINTS%FOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_QUOTA_CAT_RESTRAINTS', 'HTS_CHAPTER_RESTRAINTS',
                       'import country id: '||I_import_country_id||':'||'quota_cat: '||I_quota_cat);
      close C_QUOTA_CAT_RESTRAINTS;
      O_exists := TRUE;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_QUOTA_CAT_RESTRAINTS', 'HTS_CHAPTER_RESTRAINTS',
                    'import country id: '||I_import_country_id||':'||'quota_cat: '||I_quota_cat);
   close C_QUOTA_CAT_RESTRAINTS;

   ---

   SQL_LIB.SET_MARK('OPEN', 'C_QUOTA_CAT_HTS', 'HTS',
                    'import country id: '||I_import_country_id||':'||'quota_cat: '||I_quota_cat);
   open C_QUOTA_CAT_HTS;
   SQL_LIB.SET_MARK('FETCH', 'C_QUOTA_CAT_HTS', 'HTS',
                    'import country id: '||I_import_country_id||':'||'quota_cat: '||I_quota_cat);
   fetch C_QUOTA_CAT_HTS into L_exists;
   if C_QUOTA_CAT_HTS%FOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_QUOTA_CAT_HTS', 'HTS',
                       'import country id: '||I_import_country_id||':'||'quota_cat: '||I_quota_cat);
      close C_QUOTA_CAT_HTS;
      O_exists := TRUE;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_QUOTA_CAT_HTS', 'HTS',
                    'import country id: '||I_import_country_id||':'||'quota_cat: '||I_quota_cat);
   close C_QUOTA_CAT_HTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'HTS_SQL.QUOTA_CAT_EXISTS',
                                            to_char(SQLCODE));
   return FALSE;
END QUOTA_CAT_EXISTS;

----------------------------------------------------------------
FUNCTION GET_QUOTA_CAT(O_error_message   IN OUT  VARCHAR2,
                       O_quota_cat       IN OUT  HTS.QUOTA_CAT%TYPE,
                       I_hts             IN      HTS.HTS%TYPE,
                       I_effect_from     IN      HTS.EFFECT_FROM%TYPE,
                       I_effect_to       IN      HTS.EFFECT_TO%TYPE,
                       I_import_country  IN      HTS.IMPORT_COUNTRY_ID%TYPE)

   RETURN BOOLEAN IS
   ---
   cursor C_GET_CATEGORY is
      select quota_cat
        from hts
       where hts               = I_hts
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and import_country_id = I_import_country;

BEGIN

   SQL_LIB.SET_MARK ('OPEN', 'C_GET_CATEGORY', 'HTS', NULL);
   open C_GET_CATEGORY;
   SQL_LIB.SET_MARK('FETCH', 'C_GET_CATEGORY', 'HTS', NULL);
   fetch C_GET_CATEGORY into O_quota_cat;
   if C_GET_CATEGORY%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_HTS',NULL, NULL, NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_CATEGORY', 'HTS', NULL);
      close C_GET_CATEGORY;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE' , 'C_GET_CATEGORY', 'HTS', NULL);
   close C_GET_CATEGORY;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
	                                      SQLERRM,
	 				              'HTS_SQL.GET_QUOTA_CAT',
					               to_char(SQLCODE));
      return FALSE;

END GET_QUOTA_CAT;
----------------------------------------------------------------
END;
/

