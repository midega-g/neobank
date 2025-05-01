{{
    config(
        materialized='table',
        schema='silver',
        transient=true
    )
}}

WITH cleaned_data AS (
    SELECT
        TRIM(contact_id)::VARCHAR(12) AS contact_id,
        NULLIF(TRIM(email), '')::VARCHAR(255) AS email,
        NULLIF(REGEXP_REPLACE(TRIM(phone_number), '\\s+', '')::VARCHAR(13), '') AS phone_number,
        CASE
            WHEN LOWER(TRIM(notification_channel)) = 'sms' THEN 'SMS'
            WHEN LOWER(TRIM(notification_channel)) IN ('e-mail', 'email') THEN 'Email'
            WHEN LOWER(TRIM(notification_channel)) = 'push' THEN 'Push Notification'
            WHEN LOWER(TRIM(notification_channel)) IN ('in app', 'in-app') THEN 'In-App'
            ELSE TRIM(notification_channel)
        END:: VARCHAR(20) AS notification_channel,
        TRY_TO_TIMESTAMP(account_creation_date)::TIMESTAMP_LTZ(3) AS account_creation_date,
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ(3) AS dwh_creation_date
    FROM {{ source('bronze_source', 'crm_customer_contact') }}
),
deduplicated as (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY contact_id, email, phone_number, notification_channel
            ORDER BY CURRENT_TIMESTAMP() DESC
        )::NUMBER(18,0) AS row_number
    FROM cleaned_data
)
SELECT
    contact_id,
    email,
    phone_number,
    notification_channel,
    account_creation_date,
    dwh_creation_date
FROM deduplicated
WHERE contact_id IS NOT NULL
  AND LENGTH(contact_id) = 12
  AND account_creation_date >= '2024-01-01'
  AND account_creation_date <= CURRENT_DATE()
  AND row_number = 1
