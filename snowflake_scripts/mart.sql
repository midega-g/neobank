use role neobank_role;
use warehouse neobank_wh;
use schema neobank_db.silver;

select * from tps_transaction limit 100;

select * from tps_transaction_details limit 100;

-- Are there high-risk customers based on transaction patterns or account status
-- account status: active, closed, & suspended accounts
-- customers with 'active' accounts where 'total withdrawal' are more than 'total deposits'
--  - customer account balance cannot offset the deficit (100 USD as threshold)
--  - and no 'any form of transaction' for the 'last 45 days'
--  - the transactions have to be completed

--  - customer_id from customer_details table
--  - account_status from account_status table
--  - transaction_amount, account_balance, transaction_date from transaction table
--  - account_status from account_status table
--  - transaction_type, transaction_status from transaction_details table



select distinct account_status from int_ams_account_status;

select account_creation_date from int_crm_customer_contact limit 100;

select * from int_ams_account_status limit 100;

select * from int_ams_account_status limit 100;

select * from int_tps_transaction limit 100;

select * from int_tps_transaction_details limit 100;


SELECT
        cgi.customer_id,
        sum(tt.transaction_amount) as total_deposit
    FROM int_crm_customer_general_info cgi
    LEFT JOIN int_tps_transaction tt USING (customer_id)
    LEFT JOIN int_tps_transaction_details ttd
        ON ttd.transaction_sk = tt.transaction_sk
    WHERE ttd.transaction_type = 'Deposit'
        -- AND tt.transaction_amount > 0
        AND ttd.transaction_status = 'Failed'
    GROUP BY customer_id; -- 9,025, 697 C, 7,522 F


SELECT
        cgi.customer_id,
        sum(tt.transaction_amount) as total_withdrawal
    FROM int_crm_customer_general_info cgi
    LEFT JOIN int_tps_transaction tt USING (customer_id)
    LEFT JOIN int_tps_transaction_details ttd
        ON ttd.transaction_sk = tt.transaction_sk
    WHERE ttd.transaction_type = 'Withdrawal'
        AND tt.transaction_amount > 0
        AND ttd.transaction_status = 'Failed'
    GROUP BY customer_id; -- 9,087 all, 785 completed,


 SELECT
        cgi.customer_id,
        sum(tt.account_balance) as total_acnt_balance,
        aas.account_status
    FROM int_crm_customer_general_info cgi
    LEFT JOIN int_tps_transaction tt USING (customer_id)
    LEFT JOIN int_ams_account_status aas
        ON tt.account_status_id = aas.account_status_id
    WHERE aas.account_status = 'Active'
    GROUP BY cgi.customer_id, aas.account_status; -- 17,518
