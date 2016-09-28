CREATE OR REPLACE PACKAGE BODY ARI_INTERFACE_SQL as
----------------------------------------------------------------------------------------------
function get_is_ari_user(iov_error_message   in out   varchar2,
                         iob_is_ari_user     in out   boolean,
                         iv_username         in       varchar2)
return boolean
is

   cursor c_test is
   select is_user_ind
     from ari_interface_test;

   L_ind   ari_interface_test.is_user_ind%type := 'N';

begin

   open c_test;
   fetch c_test into L_ind;
   if L_ind = 'Y' then
      iob_is_ari_user := true;
   else
      iob_is_ari_user := false;
   end if;
   close c_test;

   return true;

exception
   when others then
      iov_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                              'ari_interface_sql.get_is_ari_user',
                                               to_char(SQLCODE));
      return false;

end get_is_ari_user;
----------------------------------------------------------------------------------------------
function get_button_and_icon_name(iov_error_message   in out   varchar2,
                                  iov_icon_name       in out   varchar2,
                                  iov_button_name     in out   varchar2,
                                  iv_username         in       varchar2)
return boolean
is

   cursor c_test is
   select new_alert_ind
     from ari_interface_test;

   L_ind   ari_interface_test.new_alert_ind%type := 'N';

begin

   open c_test;
   fetch c_test into L_ind;
   if L_ind = 'Y' then
      iov_icon_name := 'ari6';
   else
      iov_icon_name := 'ari0';
   end if;
   close c_test;

   iov_button_name := 'B_TOOLBAR.PB_ARI';

   return true;

exception
   when others then
      iov_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                              'ari_interface_sql.get_button_and_icon_name',
                                               to_char(SQLCODE));
      return false;

end get_button_and_icon_name;
----------------------------------------------------------------------------------------------
end;
/

