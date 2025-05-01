{{
    config(
        materialized='table',
        schema='silver',
        transient=true
    )
}}

WITH cleaned_data AS (
    SELECT
        TRIM(transaction_sk)::VARCHAR(12) AS transaction_sk,
        CASE
            WHEN NULLIF(TRIM(currency), '') IN ('KSH', 'KS') THEN 'KES'
            WHEN NULLIF(TRIM(currency), '') IN ('UGSH', 'USH') THEN 'UGX'
            WHEN NULLIF(TRIM(currency), '') IN ('TZSH', 'TSH') THEN 'TZS'
            WHEN NULLIF(TRIM(currency), '') = 'RF' THEN 'RWF'
            ELSE NULLIF(TRIM(currency), '')
        END::VARCHAR(3) AS currency,
        CASE
            WHEN LOWER(NULLIF(TRIM(transaction_type), '')) IN ('withdrawal', 'w') THEN 'Withdrawal'
            WHEN LOWER(NULLIF(TRIM(transaction_type), '')) IN ('deposit', 'd') THEN 'Deposit'
            ELSE NULLIF(TRIM(transaction_type), '')
        END::VARCHAR(10) AS transaction_type,
        CASE
            WHEN LOWER(NULLIF(TRIM(transaction_status), '')) IN ('pending', 'p') THEN 'Pending'
            WHEN LOWER(NULLIF(TRIM(transaction_status), '')) IN ('c', 'completed') THEN 'Completed'
            WHEN LOWER(NULLIF(TRIM(transaction_status), '')) IN ('f', 'failed') THEN 'Failed'
            ELSE NULLIF(TRIM(transaction_status),'')
        END::VARCHAR(9) AS transaction_status,
        CASE
            WHEN LOWER(NULLIF(TRIM(topup_method), '')) = 'paypal' THEN 'PayPal'
            ELSE NULLIF(TRIM(topup_method), '')
        END::VARCHAR(20) AS topup_method,
        TRY_TO_TIMESTAMP(transaction_date)::TIMESTAMP_LTZ(3) AS transaction_date,
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
    FROM {{ source('bronze_source', 'tps_transaction_details') }}
),
deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_sk
            ORDER BY CURRENT_TIMESTAMP() DESC
        )::NUMBER(18,0) AS row_number
    FROM cleaned_data
)
SELECT
    transaction_sk,
    currency,
    transaction_type,
    transaction_status,
    topup_method,
    transaction_date,
    dwh_creation_date
FROM deduplicated
WHERE transaction_sk IS NOT NULL
  AND LENGTH(transaction_sk) = 12
--   AND (transaction_date IS NULL OR (transaction_date >= '2024-01-01' AND transaction_date <= CURRENT_DATE()))
  AND row_number = 1
