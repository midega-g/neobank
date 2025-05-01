USE ROLE neobank_role;
USE SCHEMA neobank_db.bronze;

CREATE OR REPLACE TRANSIENT TABLE crm_customer_address (
    address_id VARCHAR,
    street_address VARCHAR,
    city VARCHAR,
    country VARCHAR,
    account_creation_date VARCHAR
) COMMENT = 'CRM - customer address information';

CREATE OR REPLACE TRANSIENT TABLE crm_customer_general_info (
    customer_id VARCHAR,
    username VARCHAR,
    address_id VARCHAR,
    contact_id VARCHAR,
    first_name VARCHAR,
    last_name VARCHAR,
    gender VARCHAR,
    date_of_birth VARCHAR,
    preferred_language VARCHAR,
    account_creation_date VARCHAR
) COMMENT = 'CRM - general customer profile information';

CREATE OR REPLACE TRANSIENT TABLE crm_customer_contact (
    contact_id VARCHAR,
    email VARCHAR,
    phone_number VARCHAR,
    notification_channel VARCHAR,
    account_creation_date VARCHAR
) COMMENT = 'CRM - customer contact details';

CREATE OR REPLACE TRANSIENT TABLE ams_account_status (
    account_status_id VARCHAR,
    account_status VARCHAR,
    account_creation_date VARCHAR
) COMMENT = 'AMS - account status details';

CREATE OR REPLACE TRANSIENT TABLE ams_kyc_details (
    kyc_id VARCHAR,
    kyc_completed VARCHAR,
    kyc_verified_at VARCHAR
) COMMENT = 'AMS - KYC verification information';

CREATE OR REPLACE TRANSIENT TABLE ams_biometric_details (
    biometric_id VARCHAR,
    uses_biometric VARCHAR,
    biometric_verified_at VARCHAR
) COMMENT = 'AMS - biometric authentication data';

CREATE OR REPLACE TRANSIENT TABLE ams_twofa_details (
    two_fa_id VARCHAR,
    uses_2fa VARCHAR,
    two_fa_verified_at VARCHAR
) COMMENT = 'AMS - two-factor authentication settings';

CREATE OR REPLACE TRANSIENT TABLE tps_transaction_details (
    transaction_sk VARCHAR,
    currency VARCHAR,
    transaction_type VARCHAR,
    transaction_status VARCHAR,
    topup_method VARCHAR
) COMMENT = 'TPS - transaction-level metadata and status';

CREATE OR REPLACE TRANSIENT TABLE tps_transaction (
    transaction_id VARCHAR,
    customer_id VARCHAR,
    account_id VARCHAR,
    transaction_sk VARCHAR,
    account_status_id VARCHAR,
    biometric_id VARCHAR,
    two_fa_id VARCHAR,
    kyc_id VARCHAR,
    transaction_amount VARCHAR,
    account_balance VARCHAR,
    transaction_date VARCHAR
) COMMENT = 'TPS - transactional records and linkage to customer & security context';
