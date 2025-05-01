{{
    config(
        materialized='table',
        schema='silver',
        transient=true
    )
}}

WITH cleaned_data AS (
    SELECT
        TRIM(two_fa_id)::VARCHAR(16) AS two_fa_id,
        NULLIF(TRIM(uses_2fa), '')::BOOLEAN AS uses_2fa,
        TRY_TO_TIMESTAMP(two_fa_verified_at)::TIMESTAMP_LTZ(3) AS two_fa_verified_at,
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
    FROM {{ source('bronze_source', 'ams_twofa_details') }}
),
deduplicated as (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY two_fa_id, uses_2fa, two_fa_verified_at
            ORDER BY CURRENT_TIMESTAMP() DESC
        )::NUMBER(18,0) AS row_number
    FROM cleaned_data
)
SELECT
    two_fa_id,
    uses_2fa,
    two_fa_verified_at,
    dwh_creation_date
FROM deduplicated
WHERE two_fa_id IS NOT NULL
  AND LENGTH(two_fa_id) = 16
  AND row_number = 1
