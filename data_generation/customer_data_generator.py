#!/usr/bin/env python
# coding: utf-8

import os
import time
import random
from hashlib import blake2b
from datetime import datetime, timedelta

import pandas as pd
from faker import Faker
from pandas import json_normalize

# creating folder to store data in tables
os.makedirs('data/source_crm', exist_ok=True)
os.makedirs('data/source_ams', exist_ok=True)
os.makedirs('data/source_tps', exist_ok=True)


fake = Faker()
Faker.seed(42)  # Ensures consistent results on every run


def generate_customer_data(country, cities, phone_code, language, currency):
    """
    Generate a dictionary representing a customer with profile, address, and transaction info.
    Includes features like:
    - Demographics (name, gender, DOB)
    - Contact info (email, phone)
    - Location-based data (city, country)
    - Transaction metadata (amount, type, date)
    - Security & verification features (KYC, biometrics, 2FA)
    """
    dob = fake.date_of_birth(minimum_age=18, maximum_age=90).strftime('%Y-%m-%d')
    transaction_date = fake.date_time_between(
        start_date='-86d', end_date='now'
    ).strftime('%Y-%m-%dT%H:%M:%S.%f%z')
    created_at = fake.date_time_between(start_date='-1y', end_date='now').strftime(
        '%Y-%m-%dT%H:%M:%S.%f%z'
    )

    # Simulate probabilities of security completions
    kyc_completed = random.choices([True, False], weights=[95, 5])[0]
    kyc_timestamp = created_at if kyc_completed else None
    uses_biometric = random.choices([True, False], weights=[90, 10])[0]
    biometric_verified_at = created_at if uses_biometric else None
    uses_2fa = random.choices([True, False], weights=[80, 20])[0]
    verified_2fa_at = created_at if uses_2fa else None

    customer = {
        "customer_id": str(fake.uuid4())[9:-13],
        "username": fake.user_name(),
        "first_name": fake.first_name(),
        "last_name": fake.last_name(),
        "gender": random.choice(
            ['Male', 'Female', 'F', 'M', ' m ', 'Prefer Not to Say', ' Female ', 'f ']
        ),
        "email": fake.email(),
        "phone_number": f"{phone_code}{random.randint(700000000, 799999999)}",
        "date_of_birth": dob,
        "preferred_language": random.choice(language),
        "notification_channel": random.choice(
            [
                " SMS ",
                'e-Mail',
                "sms",
                "Email",
                "In-app ",
                " In App ",
                "Push Notification",
                " Push ",
            ]
        ),
        "address": {
            "street_address": fake.street_address(),
            "city": random.choice(cities),
            "country": country,
        },
        'transaction_id': str(fake.uuid4()).split('-')[-1],
        'account_id': str(fake.uuid4()).split('-')[0],
        'transaction_amount': round(random.uniform(3, 4000), 2),
        'account_balance': round(random.uniform(-4000, 9000), 2),
        'currency': random.choice(currency),
        'transaction_type': random.choice(
            ['deposit', 'withdrawal', 'D', 'W', "Deposit ", " Withdrawal "]
        ),
        'transaction_status': random.choice(
            [
                'completed',
                'Completed ',
                'C ',
                ' pending',
                'Pending ',
                'P',
                'F',
                'failed',
            ]
        ),
        "account_creation_date": created_at,
        "transaction_date": transaction_date,
        "kyc_completed": kyc_completed,
        "kyc_verified_at": kyc_timestamp,
        "uses_biometric": uses_biometric,
        "biometric_verified_at": biometric_verified_at,
        "uses_2fa": uses_2fa,
        "two_fa_verified_at": verified_2fa_at,
    }

    # introducing errors for 5-10% of the data
    if random.random() < 0.05:
        error_type = random.choice(
            [
                'missing_value',
                'inconsistent_format',
                'invalid_data',
                'logical_inconsistency',
                'outlier',
            ]
        )

        if error_type == 'missing_value':
            # randomly set a field to None or empty
            field = random.choice(
                [
                    'email',
                    'phone_number',
                    'username',
                    'firstname',
                    'gender',
                    'kyc_verified_at',
                    'date_of_birth',
                ]
            )
            customer[field] = None if field != 'username' else ''

        elif error_type == 'inconsistent_format':
            # wrong phone number format (no country code)
            customer['phone_number'] = str(random.randint(700000000, 799999999))
            # wrong date of birth format and outliers < 18
            customer['date_of_birth'] = fake.date_of_birth(
                minimum_age=5, maximum_age=17
            ).strftime('%m/%d/%Y')

        elif error_type == 'invalid_data':
            # negative deposit
            if customer['transaction_type'] in ['deposit', 'D', 'Deposit ']:
                customer['transaction_amount'] = -customer['transaction_amount']
            # outlier age > 100
            else:
                customer['date_of_birth'] = fake.date_of_birth(
                    minimum_age=100, maximum_age=160
                ).strftime('Y%-%m-%d')

        elif error_type == 'logical_inconsistency':
            # kyc and 2fa completed but no timestamp
            if customer['kyc_completed']:
                customer['kyc_verified_at'] = None
    return customer


# Country-specific configuration (metadata for contextual generation)
country_config = {
    "Kenya": {
        "cities": ["Nairobi", "Mombasa", "Kisumu", "Eldoret"],
        "phone_code": "+254",
        "currency": ["USD", "KES", "KSH", "KS"],
        "language": ["English", "Swahili"],
    },
    "Uganda": {
        "cities": ["Kampala", "Entebe", "Jinja", "Gulu"],
        "phone_code": "+256",
        "currency": ["USD", "UGX", "UGSH", "USH"],
        "language": ["English", "Luganda"],
    },
    "Tanzania": {
        "cities": ["Dar es Salaam", "Dodoma", "Arusha", "Mwanza"],
        "phone_code": "+255",
        "currency": ["USD", "TZS", "TSH", "TZSH"],
        "language": ["Swahili", "English"],
    },
    "Rwanda": {
        "cities": ["Kigali", "Butare", "Gisenyi", "Musanze"],
        "phone_code": "+250",
        "currency": ["USD", "RWF", "RF"],
        "language": ["Kinyarwanda", "French", "English"],
    },
}

if __name__ == "__main__":

    start_time = time.time()

    unique_customers = []
    repeated_customers = []
    customer_data_list = []

    total_records = int(input("Enter the size of data to generate: "))
    unique_count = int(0.4 * total_records)  # 40% unique profiles
    repeat_count = total_records - unique_count  # 60% repeat clients

    # unchanged values
    unchanged_values = [
        "customer_id",
        "username",
        "first_name",
        "last_name",
        "gender",
        "email",
        "phone_number",
        "date_of_birth",
        "address",
        "notification_channel",
        "kyc_completed",
        "kyc_verified_at",
        "uses_2fa",
        "two_fa_verified_at",
        "uses_biometric",
        "biometric_verified_at",
    ]

    print("Data Generation started...")
    # Create unique base customer profiles
    for _ in range(unique_count):
        for ctry, config in country_config.items():
            base_data = generate_customer_data(
                country=ctry,
                cities=config["cities"],
                phone_code=config["phone_code"],
                currency=config["currency"],
                language=config["language"],
            )
            # Store immutable identity information
            static_fields = {key: base_data[key] for key in unchanged_values}
            unique_customers.append(static_fields)
            customer_data_list.append(base_data)

    interval_1 = time.time()
    print(
        f"Finished Generating Unique Base Customer Profiles in {interval_1 - start_time:.2f} seconds"
    )
    # Introduce duplicate customer_ids and emails (1% of unique customers)
    duplicate_count = int(0.01 * unique_count)

    for _ in range(duplicate_count):
        base = random.choice(unique_customers)
        new_data = generate_customer_data(
            country=base['address']['country'],
            phone_code=country_config[base['address']['country']]['phone_code'],
            cities=country_config[base['address']['country']]['cities'],
            currency=country_config[base['address']['country']]['currency'],
            language=country_config[base['address']['country']]['language'],
        )

        # Reuse unchanged values
        for field_ in unchanged_values:
            new_data[field_] = base[field_]

        customer_data_list.append(new_data)
    interval_2 = time.time()
    print(
        f"Finished Generating Duplicate Customer Profiles in {interval_2 - interval_1:.2f} seconds"
    )

    # # Reuse base profiles and generate dynamic transaction fields
    # for _ in range(repeat_count):
    #     base = random.choice(unique_customers)
    #     ctry = base['address']['country']
    #     config = country_config[ctry]

    #     new_data = generate_customer_data(
    #         country=ctry,
    #         phone_code=config["phone_code"],
    #         cities=config["cities"],
    #         currency=config["currency"],
    #         language=config['language']
    #     )

    #     for key in base:
    #         # Override dynamic record with static profile fields
    #         new_data[key] = base[key]

    #     customer_data_list.append(new_data)

    # STEP 3: Build and enrich DataFrame
    interval_3 = time.time()

    df = json_normalize(customer_data_list)

    # hash  column to get ids using blake2b
    def generate_ids(digest_size=6, **kwargs):
        h = blake2b(digest_size=digest_size)
        combined = "|".join(str(v) for v in kwargs.values())
        h.update(combined.encode('utf-8'))
        return h.hexdigest()

    # add address_id
    # , created_at=x['account_creation_date']
    df['address_id'] = df.apply(
        lambda x: generate_ids(
            street=x['address.street_address'],
            city=x['address.city'],
            country=x['address.country'],
        ),
        axis=1,
    )

    # add contact_id
    # , created_at=x['account_creation_date']
    df['contact_id'] = df.apply(
        lambda x: generate_ids(
            email=x['email'],
            phone_number=x['phone_number'],
            notification_channel=x['notification_channel'],
        ),
        axis=1,
    )

    df['transaction_date'] = pd.to_datetime(df['transaction_date'])

    # transactions older than 14 days are assumed to have failed
    df['transaction_status'] = df["transaction_date"].apply(
        lambda x: (
            'Failed'
            if x < datetime.now() - timedelta(days=14)
            else random.choice(['Completed', 'Pending'])
        )
    )

    # randomly assign account statuses
    df['account_status'] = random.choices(
        ['Active', 'Suspended', 'Closed'], weights=[97, 2, 1], k=len(df)
    )

    # map deposit/withdrawal to valid topup methods
    df['topup_method'] = df['transaction_type'].apply(
        lambda x: (
            random.choice(
                ['Mpesa', 'PayPal', 'Bank Transfer', 'Cash Desk', 'Card Payment']
            )
            if x == 'deposit'
            else random.choice(['Mpesa', 'Paypal', 'Cash Desk', 'Bank Transfer'])
        )
    )

    df['transaction_sk'] = df.apply(
        lambda x: generate_ids(
            currency=x['currency'],
            transaction_type=x['transaction_type'],
            transaction_status=x['transaction_status'],
            topup_method=x['topup_method'],
        ),
        axis=1,
    )

    df['account_status_id'] = df.apply(
        lambda x: generate_ids(
            digest_size=8,
            account_status=x['account_status'],
            account_creation_date=x['account_creation_date'],
        ),
        axis=1,
    )

    df['kyc_id'] = df.apply(
        lambda x: generate_ids(
            digest_size=8,
            kyc_completed=x['kyc_completed'],
            kyc_verified_at=x['kyc_verified_at'],
        ),
        axis=1,
    )

    df['biometric_id'] = df.apply(
        lambda x: generate_ids(
            digest_size=8,
            uses_biometric=x['uses_biometric'],
            biometric_verified_at=x['biometric_verified_at'],
        ),
        axis=1,
    )

    df['two_fa_id'] = df.apply(
        lambda x: generate_ids(
            digest_size=8,
            uses_2fa=x['uses_2fa'],
            verified_2fa_at=x['two_fa_verified_at'],
        ),
        axis=1,
    )

    # print(df['customer_id'].unique())  # Preview unique IDs
    # Save output
    df.to_csv(f'data_generation/customer_data_{total_records}.csv', index=False)

    # Timing after customer data generation
    interval_4 = time.time()
    print(
        f"Finished Generating Customer Data to CSV in {interval_4 - interval_3:.2f} seconds"
    )
    print(
        f"Total time taken to generate {total_records} records was {interval_4 - start_time:.2f} seconds"
    )
    print("Transferring the data to respective tables...\n")

    # Start timing the table transfer
    interval_5 = time.time()

    # Read the generated customer data
    df = pd.read_csv(
        f'data_generation/customer_data_{total_records}.csv',
        dtype={'phone_number': str},
    )

    # --------- Save each table individually with timings ---------

    # customerAddress
    start = time.time()
    df[
        [
            'address_id',
            'address.street_address',
            'address.city',
            'address.country',
            'account_creation_date',
        ]
    ].to_csv('data/source_crm/CRM_customerAddress.csv', index=False)
    print(f"Saved CRM_customerAddress.csv in {time.time() - start:.2f} seconds")

    # customerGeneralInfo
    start = time.time()
    df[
        [
            'customer_id',
            'username',
            'address_id',
            'contact_id',
            'first_name',
            'last_name',
            'gender',
            'date_of_birth',
            'preferred_language',
            'account_creation_date',
        ]
    ].to_csv('data/source_crm/CRM_customerGeneralInfo.csv', index=False)
    print(f"Saved CRM_customerGeneralInfo.csv in {time.time() - start:.2f} seconds")

    # customerContact
    start = time.time()
    df[
        [
            'contact_id',
            'email',
            'phone_number',
            'notification_channel',
            'account_creation_date',
        ]
    ].to_csv('data/source_crm/CRM_customerContact.csv', index=False)
    print(f"Saved CRM_customerContact.csv in {time.time() - start:.2f} seconds")

    # AccountDetails
    start = time.time()
    df[['account_status_id', 'account_status', 'account_creation_date']].to_csv(
        'data/source_ams/AMS_accountStatus.csv', index=False
    )
    print(f"Saved AMS_accountStatus.csv in {time.time() - start:.2f} seconds")

    # KYCDetails
    start = time.time()
    df[['kyc_id', 'kyc_completed', 'kyc_verified_at']].to_csv(
        'data/source_ams/AMS_kycDetails.csv', index=False
    )
    print(f"Saved AMS_kycDetails.csv in {time.time() - start:.2f} seconds")

    # BiometricDetails
    start = time.time()
    df[['biometric_id', 'uses_biometric', 'biometric_verified_at']].to_csv(
        'data/source_ams/AMS_biometricDetails.csv', index=False
    )
    print(f"Saved AMS_biometricDetails.csv in {time.time() - start:.2f} seconds")

    # 2faDetails
    start = time.time()
    df[['two_fa_id', 'uses_2fa', 'two_fa_verified_at']].to_csv(
        'data/source_ams/AMS_twofaDetails.csv', index=False
    )
    print(f"Saved AMS_twofaDetails.csv in {time.time() - start:.2f} seconds")

    # transactionDetails
    start = time.time()
    df[
        [
            'transaction_sk',
            'currency',
            'transaction_type',
            'transaction_status',
            'topup_method',
            'transaction_date',
        ]
    ].to_csv('data/source_tps/TPS_transactionDetails.csv', index=False)
    print(f"Saved TPS_transactionDetails.csv in {time.time() - start:.2f} seconds")

    # transaction
    start = time.time()
    df[
        [
            'transaction_id',
            'customer_id',
            'account_id',
            'transaction_sk',
            'account_status_id',
            'biometric_id',
            'two_fa_id',
            'kyc_id',
            'transaction_amount',
            'account_balance',
            'transaction_date',
        ]
    ].to_csv('data/source_tps/TPS_transaction.csv', index=False)
    print(f"Saved TPS_transaction.csv in {time.time() - start:.2f} seconds")

    # --------- Final timing after all tables ---------

    interval_6 = time.time()
    print(
        f"\nFinished transferring all tables in {interval_6 - interval_5:.2f} seconds"
    )
    print(f"Total script execution time: {interval_6 - start_time:.2f} seconds")
