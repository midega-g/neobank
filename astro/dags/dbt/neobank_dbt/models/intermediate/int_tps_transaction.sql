{{
    config(
        materialized='table',
        schema='silver',
        transient=true
    )
}}

WITH cleaned_data AS (
    SELECT
        NULLIF(TRIM(transaction_id), '')::VARCHAR(12) AS transaction_id,
        NULLIF(REPLACE(TRIM(customer_id), '-', ''), '')::VARCHAR(12) AS customer_id,
        NULLIF(TRIM(account_id), '')::VARCHAR(8) AS account_id,
        NULLIF(TRIM(transaction_sk), '')::VARCHAR(12) AS transaction_sk,
        NULLIF(TRIM(account_status_id), '')::VARCHAR(16) AS account_status_id,
        NULLIF(TRIM(biometric_id), '')::VARCHAR(16) AS biometric_id,
        NULLIF(TRIM(two_fa_id), '')::VARCHAR(16) AS two_fa_id,
        NULLIF(TRIM(kyc_id), '')::VARCHAR(16) AS kyc_id,
        NULLIF(TRY_TO_DECIMAL(transaction_amount, 18, 2), 0)::DECIMAL(18,2) AS transaction_amount,
        NULLIF(TRY_TO_DECIMAL(account_balance, 18, 2), 0)::DECIMAL(18,2) AS account_balance,
        TRY_TO_TIMESTAMP(transaction_date)::TIMESTAMP_LTZ(3) AS transaction_date,
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
    FROM {{ source('bronze_source', 'tps_transaction') }}
),
deduplicated as (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id, customer_id, account_id, account_status_id, two_fa_id
            ORDER BY CURRENT_TIMESTAMP() DESC
        )::NUMBER(18,0) AS row_number
    FROM cleaned_data
)
SELECT
    transaction_id,
    customer_id,
    account_id,
    transaction_sk,
    account_status_id,
    biometric_id,
    two_fa_id,
    kyc_id,
    transaction_amount,
    account_balance,
    transaction_date,
    dwh_creation_date
FROM deduplicated
WHERE transaction_id IS NOT NULL
  AND LENGTH(transaction_id) = 12
--   AND (transaction_date IS NULL OR (transaction_date >= '2024-01-01' AND transaction_date <= CURRENT_DATE()))
  AND row_number = 1
