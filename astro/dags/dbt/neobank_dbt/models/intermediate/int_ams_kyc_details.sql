{{
    config(
        materialized='table',
        schema='silver',
        transient=true
    )
}}

WITH cleaned_data AS (
    SELECT
        TRIM(kyc_id)::VARCHAR(16) AS kyc_id,
        NULLIF(TRIM(kyc_completed), '')::BOOLEAN AS kyc_completed,
        TRY_TO_TIMESTAMP(kyc_verified_at)::TIMESTAMP_LTZ(3) AS kyc_verified_at,
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
    FROM {{ source('bronze_source', 'ams_kyc_details') }}
),
deduplicated as (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY kyc_id, kyc_completed, kyc_verified_at
            ORDER BY CURRENT_TIMESTAMP() DESC
        )::NUMBER(18,0) AS row_number
    FROM cleaned_data
)
SELECT
    kyc_id,
    kyc_completed,
    kyc_verified_at,
    dwh_creation_date
FROM deduplicated
WHERE kyc_id IS NOT NULL
  AND LENGTH(kyc_id) = 16
  AND (kyc_verified_at IS NULL OR (kyc_verified_at >= '2024-01-01' AND kyc_verified_at <= CURRENT_DATE()))
  AND row_number = 1
