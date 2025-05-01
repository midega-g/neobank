{{
    config(
        materialized='table',
        schema='silver',
        transient=true
    )
}}

WITH cleaned_data AS (
    SELECT
        TRIM(REPLACE(customer_id, '-', ''))::VARCHAR(12) AS customer_id,
        REGEXP_REPLACE(TRIM(username), '\\s+', '')::VARCHAR(30) AS username,
        TRIM(address_id)::VARCHAR(12) AS address_id,
        TRIM(contact_id)::VARCHAR(12) AS contact_id,
        TRIM(first_name)::VARCHAR(50) AS first_name,
        TRIM(last_name)::VARCHAR(50) AS last_name,
        CASE
            WHEN UPPER(TRIM(gender)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gender)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'Unknown'
        END::VARCHAR(9) AS gender,
        CASE
            WHEN DATEDIFF(YEAR, TRY_TO_DATE(date_of_birth), CURRENT_DATE()) < 18
                 OR DATEDIFF(YEAR, TRY_TO_DATE(date_of_birth), CURRENT_DATE()) > 120
                 OR TRY_TO_DATE(date_of_birth) IS NULL
                 OR date_of_birth >= CURRENT_DATE()
            THEN NULL
            ELSE TRY_TO_TIMESTAMP(date_of_birth)::TIMESTAMP_LTZ(3)
        END AS date_of_birth,
        TRIM(preferred_language)::VARCHAR(30) AS preferred_language,
        TRY_TO_TIMESTAMP(account_creation_date)::TIMESTAMP_LTZ(3) AS account_creation_date,
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
    FROM {{ source('bronze_source', 'crm_customer_general_info') }}
),
deduplicated as (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, username, address_id, contact_id, first_name, last_name, gender
            ORDER BY CURRENT_TIMESTAMP() DESC
        )::NUMBER(18,0) AS row_number
    FROM cleaned_data
)
SELECT
    customer_id,
    username,
    address_id,
    contact_id,
    first_name,
    last_name,
    gender,
    date_of_birth,
    preferred_language,
    account_creation_date,
    dwh_creation_date
FROM deduplicated
WHERE customer_id IS NOT NULL
  AND LENGTH(customer_id) = 12
  AND row_number = 1
