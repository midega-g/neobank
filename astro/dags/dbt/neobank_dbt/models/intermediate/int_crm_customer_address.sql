{{
    config(
        materialized='table',
        schema='silver',
        transient=true
    )
}}

WITH cleaned_data AS (
    SELECT
        TRIM(address_id)::VARCHAR(12) AS address_id,
        TRIM(street_address)::VARCHAR(50) AS street_address,
        TRIM(city)::VARCHAR(20) AS city,
        TRIM(country)::VARCHAR(10) AS country,
        TRY_TO_TIMESTAMP(account_creation_date)::TIMESTAMP_LTZ(3) AS account_creation_date,
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
    FROM {{ source('bronze_source', 'crm_customer_address') }}
),
deduplicated as (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY address_id, street_address, city, country
            ORDER BY CURRENT_TIMESTAMP() DESC
        )::NUMBER(18,0) AS row_number
    FROM cleaned_data
)
SELECT
    address_id,
    street_address,
    city,
    country,
    account_creation_date,
    dwh_creation_date
FROM deduplicated
WHERE address_id IS NOT NULL
  AND LENGTH(address_id) = 12
  AND row_number = 1
