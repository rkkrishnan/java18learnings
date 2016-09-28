CREATE OR REPLACE PACKAGE BODY CUSTOMER_SQL AS
--------------------------------------------------------------------------------------------
FUNCTION EXIST(O_error_message IN OUT VARCHAR2,
               O_exist         IN OUT BOOLEAN,
               I_cust_id       IN customer.cust_id%TYPE)
               RETURN BOOLEAN IS

   L_found      VARCHAR2(1);

   cursor C_CUST_ID is
      select 'x'
        from customer
       where cust_id = I_cust_id;

BEGIN
   if I_cust_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_cust_id',
                                            'NULL',
                                            'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_CUST_ID', 'customer', 'cust id: '||I_cust_id);
   open C_CUST_ID;
   SQL_LIB.SET_MARK('FETCH', 'C_CUST_ID', 'customer', 'cust id: '||I_cust_id);
   fetch C_CUST_ID into L_found;
   if C_CUST_ID%FOUND then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_CUST_ID', 'customer', 'cust id: '||I_cust_id);
   close C_CUST_ID;

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'CUSTOMER_SQL.EXIST',
                                             to_char(SQLCODE));
   RETURN FALSE;

END EXIST;
--------------------------------------------------------------------------------------------
FUNCTION GET_NAME(O_error_message IN OUT VARCHAR2,
                  O_cust_name     IN OUT customer.cust_name%TYPE,
                  I_cust_id       IN     customer.cust_id%TYPE)
                  RETURN BOOLEAN IS

    cursor C_CUST_NAME is
      select cust_name
        from customer
       where cust_id = I_cust_id;

BEGIN
   if I_cust_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_cust_id',
                                            'NULL',
                                            'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_CUST_NAME', 'customer', 'cust id: '||I_cust_id);
   open C_CUST_NAME;
   SQL_LIB.SET_MARK('FETCH', 'C_CUST_NAME', 'customer', 'cust id: '||I_cust_id);
   fetch C_CUST_NAME into O_cust_name;
   if C_CUST_NAME%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_CUST',
                                             NULL,
                                             NULL,
                                             NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_CUST_NAME', 'customer', 'cust id: '||I_cust_id);
      close C_CUST_NAME;
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_CUST_NAME', 'customer', 'cust id: '||I_cust_id);
   close C_CUST_NAME;

   RETURN TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                             'CUSTOMER_SQL.GET_NAME',
                                              to_char(SQLCODE));
   RETURN FALSE;

END GET_NAME;
--------------------------------------------------------------------------------------------
FUNCTION GET_DETAILS(O_error_message   IN OUT VARCHAR2,
                     O_cust_name       IN OUT customer.cust_name%TYPE,
                     O_contact_name    IN OUT customer.contact_name%TYPE,
                     O_cust_title      IN OUT customer.cust_title%TYPE,
                     O_cust_add1       IN OUT customer.cust_add1%TYPE,
                     O_cust_add2       IN OUT customer.cust_add2%TYPE,
                     O_cust_city       IN OUT customer.cust_city%TYPE,
                     O_cust_state      IN OUT customer.cust_state%TYPE,
                     O_cust_country_id IN OUT customer.cust_country_id%TYPE,
                     O_cust_post       IN OUT customer.cust_post%TYPE,
                     O_day_phone       IN OUT customer.day_phone%TYPE,
                     O_eve_phone       IN OUT customer.eve_phone%TYPE,
                     I_cust_id         IN     customer.cust_id%TYPE)
                     RETURN BOOLEAN IS

    cursor C_CUST_DETAILS is
      select cust_name,
             contact_name,
             cust_title,
             cust_add1,
             cust_add2,
             cust_city,
             cust_state,
             cust_country_id,
             cust_post,
             day_phone,
             eve_phone
        from customer
       where cust_id = I_cust_id;

BEGIN
   if I_cust_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_cust_id',
                                            'NULL',
                                            'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_CUST_DETAILS', 'customer', 'cust id: '||I_cust_id);
   open C_CUST_DETAILS;

   SQL_LIB.SET_MARK('FETCH', 'C_CUST_DETAILS', 'customer', 'cust id: '||I_cust_id);
   fetch C_CUST_DETAILS into O_cust_name,
                             O_contact_name,
                             O_cust_title,
                             O_cust_add1,
                             O_cust_add2,
                             O_cust_city,
                             O_cust_state,
                             O_cust_country_id,
                             O_cust_post,
                             O_day_phone,
                             O_eve_phone;

   if C_CUST_DETAILS%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_CUST',
                                             NULL,
                                             NULL,
                                             NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_CUST_DETAILS', 'customer', 'cust id: '||I_cust_id);
      close C_CUST_DETAILS;
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_CUST_DETAILS', 'customer', 'cust id: '||I_cust_id);
   close C_CUST_DETAILS;
   RETURN TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                             'CUSTOMER_SQL.GET_DETAILS',
                                              to_char(SQLCODE));
   RETURN FALSE;

END GET_DETAILS;
--------------------------------------------------------------------------------------------
FUNCTION INSERT_ORDCUST(O_error_message   IN OUT VARCHAR2,
                        I_cust_id         IN     ordcust.cust_id%TYPE,
                        I_order_no        IN     ordcust.order_no%TYPE,
                        I_tsf_no          IN     ordcust.tsf_no%TYPE,
                        I_deliver_add1    IN     ordcust.deliver_add1%TYPE,
                        I_deliver_add2    IN     ordcust.deliver_add2%TYPE,
                        I_deliver_city    IN     ordcust.deliver_city%TYPE,
                        I_deliver_state   IN     ordcust.deliver_state%TYPE,
                        I_deliver_country IN     ordcust.deliver_country_id%TYPE,
                        I_deliver_post    IN     ordcust.deliver_post%TYPE,
                        I_deliver_date    IN     ordcust.deliver_date%TYPE,
                        I_deliver_type    IN     ordcust.deliver_type%TYPE,
                        I_salesperson     IN     ordcust.salesperson%TYPE)
                        RETURN BOOLEAN IS

   L_max_seq_no       ordcust.ordcust_seq_no%TYPE;
   L_today_date       DATE := GET_VDATE;

   cursor C_GET_SEQ_NO is
      select max(ordcust_seq_no)
        from ordcust
       where cust_id = I_cust_id;

BEGIN
   if I_cust_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_cust_id',
                                            'NULL',
                                            'NOT NULL');
      RETURN FALSE;
   end if;

   if I_order_no is NULL
      and I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'both I_order_no and I_tsf_no',
                                            'NULL',
                                            'one NOT NULL');
      RETURN FALSE;
   end if;

   if I_order_no is NOT NULL
      and I_tsf_no is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'both I_order_no and I_tsf_no',
                                            'NOT NULL',
                                            'one NULL');
      RETURN FALSE;
   end if;

   if I_deliver_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_deliver_date',
                                            'NULL',
                                            'NOT NULL');
      RETURN FALSE;
   end if;

   if I_deliver_date < L_today_date then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_deliver_date',
                                             to_char(I_deliver_date, 'DD-MON-RR'),
                                            'I_deliver_date >= '||to_char(L_today_date, 'DD-MON-RR'));
      RETURN FALSE;
   end if;

   if I_deliver_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_deliver_type',
                                            'NULL',
                                            'NOT NULL');
      RETURN FALSE;
   end if;

   if I_deliver_type not in ('S', 'C') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_deliver_type',
                                             I_deliver_type,
                                            'S or C');
      RETURN FALSE;
   end if;

   if I_deliver_type = 'S' then
      if (I_deliver_add1 is NULL
         or I_deliver_city is NULL
         or I_deliver_country is NULL
         or I_deliver_post is NULL) then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                               'delivery details',
                                               'NULL',
                                               'NOT NULL');
         RETURN FALSE;
      end if;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_GET_SEQ_NO', 'ordcust', 'cust id: '||I_cust_id);
   open C_GET_SEQ_NO;
   SQL_LIB.SET_MARK('FETCH', 'C_GET_SEQ_NO', 'ordcust', 'cust id: '||I_cust_id);
   fetch C_GET_SEQ_NO into L_max_seq_no;
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_SEQ_NO', 'ordcust', 'cust id: '||I_cust_id);
   close C_GET_SEQ_NO;

   SQL_LIB.SET_MARK('INSERT', NULL, 'ordcust', 'cust id: '||I_cust_id||
                    ', ordcust sequence no: '||to_char(L_max_seq_no));

   insert into ordcust(cust_id,
                       ordcust_seq_no,
                       order_no,
                       tsf_no,
                       deliver_add1,
                       deliver_add2,
                       deliver_city,
                       deliver_state,
                       deliver_country_id,
                       deliver_post,
                       deliver_type,
                       deliver_date,
                       salesperson,
                       comments)
      VALUES(I_cust_id,
             NVL(L_max_seq_no,0) + 1,
             I_order_no,
             I_tsf_no,
             I_deliver_add1,
             I_deliver_add2,
             I_deliver_city,
             I_deliver_state,
             I_deliver_country,
             I_deliver_post,
             I_deliver_type,
             I_deliver_date,
             I_salesperson,
             NULL);

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'CUSTOMER_SQL.INSERT_ORDCUST',
                                             to_char(SQLCODE));
      RETURN FALSE;

END INSERT_ORDCUST;
--------------------------------------------------------------------------------------------
END CUSTOMER_SQL;
/

