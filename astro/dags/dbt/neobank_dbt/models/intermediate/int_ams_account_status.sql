{{
    config(
        materialized='table',
        schema='silver',
        transient=true
    )
}}

WITH cleaned_data AS (
    SELECT
        REGEXP_REPLACE(TRIM(account_status_id), '\\s+', '')::VARCHAR(16) AS account_status_id,
        TRIM(account_status)::VARCHAR(10) AS account_status,
        TRY_TO_TIMESTAMP(account_creation_date)::TIMESTAMP_LTZ(3) AS account_creation_date,
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
    FROM {{ source('bronze_source', 'ams_account_status') }}
),
deduplicated as (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY account_status_id, account_status, account_creation_date
            ORDER BY CURRENT_TIMESTAMP() DESC
        )::NUMBER(18,0) AS row_number
    FROM cleaned_data
)
SELECT
    account_status_id,
    account_status,
    account_creation_date,
    dwh_creation_date
FROM deduplicated
WHERE account_status_id IS NOT NULL
  AND LENGTH(account_status_id) = 16
  AND account_creation_date >= '2024-01-01'
  AND account_creation_date <= CURRENT_DATE()
  AND row_number = 1
