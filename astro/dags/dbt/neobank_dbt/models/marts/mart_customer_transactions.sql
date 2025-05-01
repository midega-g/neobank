{{
    config(
        materialized='incremental',
        schema='gold',
        unique_key=['customer_id', 'transaction_id'],
        incremental_strategy='merge',
        merge_update_columns=['first_name', 'email', 'phone_number', 'city', 'country', 'preferred_language',
                            'account_status', 'transaction_type', 'transaction_status', 'account_balance',
                            'transaction_amount', 'transaction_date', 'dwh_creation_date']
    )
}}

SELECT
    cgi.customer_id,
    cgi.first_name,
    ccd.email,
    ccd.phone_number,
    cca.city,
    cca.country,
    cgi.preferred_language,
    aas.account_status,
    tt.transaction_id,
    ttd.transaction_type,
    ttd.transaction_status,
    tt.account_balance,
    tt.transaction_amount,
    tt.transaction_date,
    CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
FROM {{ ref('int_crm_customer_general_info') }} cgi
LEFT JOIN {{ ref('int_crm_customer_contact') }} ccd
    ON cgi.contact_id = ccd.contact_id
LEFT JOIN {{ ref('int_crm_customer_address') }} cca
    ON cgi.address_id = cca.address_id
RIGHT JOIN {{ ref('int_tps_transaction') }} tt
    ON cgi.customer_id = tt.customer_id
LEFT JOIN {{ ref('int_tps_transaction_details') }} ttd
    ON ttd.transaction_sk = tt.transaction_sk
LEFT JOIN {{ ref('int_ams_account_status') }} aas
    ON tt.account_status_id = aas.account_status_id

{% if is_incremental() %}
WHERE tt.transaction_date >= (SELECT COALESCE(MAX(transaction_date), '1900-01-01') FROM {{ this }})
{% endif %}
