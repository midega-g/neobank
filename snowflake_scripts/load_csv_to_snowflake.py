import os
import glob
from uuid import uuid4

import snowflake.connector
from dotenv import load_dotenv

# Load .env file if present
load_dotenv()

# Mapping of CSV file names (without .csv) to Snowflake table names
CSV_TABLE_MAPPING = {
    # source_ams
    "AMS_accountStatus": "AMS_ACCOUNT_STATUS",
    "AMS_biometricDetails": "AMS_BIOMETRIC_DETAILS",
    "AMS_kycDetails": "AMS_KYC_DETAILS",
    "AMS_twofaDetails": "AMS_TWOFA_DETAILS",
    # source_crm
    "CRM_customerAddress": "CRM_CUSTOMER_ADDRESS",
    "CRM_customerContact": "CRM_CUSTOMER_CONTACT",
    "CRM_customerGeneralInfo": "CRM_CUSTOMER_GENERAL_INFO",
    # source_tps
    "TPS_transaction": "TPS_TRANSACTION",
    "TPS_transactionDetails": "TPS_TRANSACTION_DETAILS",
}


def load_csv_to_snowflake(
    data_folder, database, schema, account, user, password, warehouse, role=None
):
    """
    Load multiple CSV files from a folder into corresponding Snowflake tables.

    Parameters:
    - data_folder: Relative or absolute path to folder containing CSV files or subdirectories
    - database: Snowflake database name
    - schema: Snowflake schema name
    - account: Snowflake account identifier (e.g., 'xy12345.us-east-1')
    - user: Snowflake username
    - password: Snowflake password
    - warehouse: Snowflake warehouse name
    - role: Optional Snowflake role (defaults to user's default role)
    """
    # Resolve relative data_folder to absolute path based on script's parent directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # One level up from script's directory
    parent_dir = os.path.dirname(script_dir)
    absolute_data_folder = os.path.abspath(os.path.join(parent_dir, data_folder))

    # Validate directory
    if not os.path.isdir(absolute_data_folder):
        print(f"Error: Directory {absolute_data_folder} does not exist.")
        return

    try:
        # Connect to Snowflake
        conn = snowflake.connector.connect(
            user=user,
            password=password,
            account=account,
            warehouse=warehouse,
            database=database,
            schema=schema,
            role=role,
        )
        cursor = conn.cursor()

        # Create a unique temporary stage
        stage_name = f"temp_stage_{uuid4().hex}"
        cursor.execute(f"CREATE TEMPORARY STAGE {stage_name}")

        # Find all CSV files in the folder (recursive)
        csv_files = glob.glob(
            os.path.join(absolute_data_folder, "**", "*.csv"), recursive=True
        )
        if not csv_files:
            print(f"Error: No CSV files found in {absolute_data_folder}")
            return

        # Upload all CSV files to stage root
        for csv_file in csv_files:
            file_name = os.path.basename(csv_file)
            stage_path = f"@{stage_name}/{file_name}"
            cursor.execute(f"PUT file://{csv_file} {stage_path} AUTO_COMPRESS=TRUE")
            print(f"Uploaded {csv_file} to {stage_path}")

        # Debug: List files in stage to verify
        cursor.execute(f"LIST @{stage_name}")
        stage_files = cursor.fetchall()
        print("Files in stage:", [row[0] for row in stage_files])

        # Load each CSV into its corresponding table
        for csv_file in csv_files:
            # Extract file name without extension
            file_name = os.path.splitext(os.path.basename(csv_file))[0]
            # Get target table from mapping
            table_name = CSV_TABLE_MAPPING.get(file_name)
            if not table_name:
                print(f"Warning: No table mapping found for {file_name}.csv, skipping.")
                continue

            # Construct stage path (root of stage)
            stage_file_path = f"@{stage_name}/{file_name}.csv"

            # Load data into table with headers and error handling
            copy_query = f"""
            COPY INTO {schema}.{table_name}
            FROM {stage_file_path}
            FILE_FORMAT = (
                TYPE = CSV,
                FIELD_DELIMITER = ',',
                SKIP_HEADER = 1,
                FIELD_OPTIONALLY_ENCLOSED_BY = '"',
                NULL_IF = ('NULL', ''),
                TRIM_SPACE = TRUE,
                ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
            )
            ON_ERROR = 'CONTINUE'
            """
            print(f"Executing COPY INTO for {file_name}.csv to {stage_file_path}")
            cursor.execute(copy_query)
            results = cursor.fetchall()
            print(f"Load Results for {file_name}.csv into {table_name}: {results}")

        print(
            f"Successfully processed {len(csv_files)} CSV files from {absolute_data_folder}"
        )

        # Clean up: Remove temporary stage
        cursor.execute(f"REMOVE @{stage_name}")

    except snowflake.connector.errors.ProgrammingError as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals():
            conn.close()


if __name__ == "__main__":
    config = {
        "data_folder": os.getenv("DATA_FOLDER"),
        "database": os.getenv("SNOWFLAKE_DATABASE"),
        "schema": os.getenv("SNOWFLAKE_SCHEMA"),
        "account": os.getenv("SNOWFLAKE_ACCOUNT"),
        "user": os.getenv("SNOWFLAKE_USER"),
        "password": os.getenv("SNOWFLAKE_PASSWORD"),
        "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE"),
        "role": os.getenv("SNOWFLAKE_ROLE") or None,
    }

    # Validate environment variables
    missing = [key for key, value in config.items() if value is None and key != "role"]
    if missing:
        print(f"Error: Missing environment variable(s): {', '.join(missing)}")
    else:
        load_csv_to_snowflake(**config)
