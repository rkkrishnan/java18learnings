CREATE OR REPLACE PACKAGE BODY IMAGE_SQL AS
--------------------------------------------------------------------------------

FUNCTION DEFAULT_DOWN(O_error_message   IN OUT VARCHAR2,
                      I_item            IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(60) := 'IMAGE_SQL.DEFAULT_DOWN';
   L_table       VARCHAR2(30);
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_IMAGE is
      select 'x'
        from item_image
       where item in (select im.item
                        from item_master im
                       where (im.item_parent = I_item
                          or im.item_grandparent = I_item)
                         and im.item_level <= im.tran_level)
         for update nowait;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                            NULL,
                                            NULL,
                                            NULL);

      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_IMAGE','ITEM_IMAGE',NULL);
   open C_LOCK_ITEM_IMAGE;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_IMAGE','ITEM_IMAGE',NULL);
   close C_LOCK_ITEM_IMAGE;
   ---
   delete from item_image
    where item in (select im.item
                     from item_master im
                    where (im.item_parent = I_item
                       or im.item_grandparent = I_item)
                      and im.item_level <= im.tran_level);
   ---
   SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_IMAGE',NULL);
   insert into item_image(item,
                          image_name,
                          image_addr,
                          image_desc,
                          create_datetime,
                          last_update_datetime,
                          last_update_id)
                   select im.item,
                          i.image_name,
                          i.image_addr,
                          i.image_desc,
                          sysdate,
                          sysdate,
                          user
                     from item_image i,
                          item_master im
                    where i.item = I_item
                      and (im.item_parent = I_item
                       or im.item_grandparent = I_item)
                      and im.item_level <= im.tran_level;
   ---
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
END DEFAULT_DOWN;
---------------------------------------------------------------------------------------------
END IMAGE_SQL;
/

