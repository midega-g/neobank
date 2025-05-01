{{
    config(
        materialized='table',
        schema='silver',
        transient=true
    )
}}

WITH cleaned_data AS (
    SELECT
        TRIM(biometric_id)::VARCHAR(16) AS biometric_id,
        NULLIF(TRIM(uses_biometric), '')::BOOLEAN AS uses_biometric,
        TRY_TO_TIMESTAMP(biometric_verified_at)::TIMESTAMP_LTZ(3) AS biometric_verified_at,
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
    FROM {{ source('bronze_source', 'ams_biometric_details') }}
),
deduplicated as (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY biometric_id, uses_biometric
            ORDER BY CURRENT_TIMESTAMP() DESC
        )::NUMBER(18,0) AS row_number
    FROM cleaned_data
)
SELECT
    biometric_id,
    uses_biometric,
    biometric_verified_at,
    dwh_creation_date
FROM deduplicated
WHERE biometric_id IS NOT NULL
  AND LENGTH(biometric_id) = 16
  AND biometric_verified_at >= '2024-01-01'
  AND biometric_verified_at <= CURRENT_DATE()
  AND row_number = 1
