# Neobank Data Pipeline Documentation

The Neobank project is a modern data pipeline designed to process, transform, and analyze data for a neobank platform. It integrates data from account management systems (AMS), customer relationship management (CRM), and transaction processing systems (TPS) into a Snowflake data warehouse. The pipeline leverages **dbt (data build tool)** for data transformation, **Apache Airflow** with **Astronomer Cosmos** for orchestration, and **Snowflake** for storage and processing. This documentation provides a comprehensive guide to the project’s setup, structure, and execution.

## Project Overview

The Neobank data pipeline aims to:

- **Ingest raw data**: Load CSV files from AMS, CRM, and TPS into Snowflake’s `bronze` schema.
- **Transform data**: Use dbt to create structured intermediate tables (`silver` schema) and analytics-ready marts (`gold` schema).
- **Orchestrate workflows**: Schedule and monitor transformations using Airflow and Astronomer Cosmos.
- **Ensure data quality**: Implement tests and documentation with dbt.
- **Optimize costs**: Use Snowflake’s features for efficient data processing.

The pipeline supports analytics use cases, such as customer transaction reporting, by providing clean, reliable data in the `gold` schema.

## Architecture

The architecture follows a layered data warehouse approach:

1. **Bronze Schema**: Stores raw data from CSV files (e.g., `AMS_accountStatus.csv`, `CRM_customerGeneralInfo.csv`) as `VARCHAR` to avoid load failures.
2. **Silver Schema**: Contains intermediate dbt models that clean and structure raw data (e.g., `int_ams_account_status`).
3. **Gold Schema**: Hosts final data marts for analytics (e.g., `mart_customer_transactions`).

**Tools**:

- **Snowflake**: Cloud data warehouse for storage and compute.
- **dbt**: Handles data modeling, testing, and documentation.
- **Airflow with Astronomer Cosmos**: Orchestrates dbt workflows.
- **Python Scripts**: Generate and load raw data into Snowflake.
- **Docker**: Ensures consistent Airflow environments.

**Data Flow**:

1. Raw CSV data is generated or provided in the `data/` directory.
2. Python scripts load CSV data into Snowflake’s `bronze` schema.
3. dbt models transform data into `silver` and `gold` schemas.
4. Airflow schedules and monitors the dbt workflow daily.

## Repository Structure

The project is organized to separate data, scripts, transformations, and orchestration:

```plain
.
├── astro/                          # Airflow project directory
│   ├── dags/                       # Airflow DAGs and dbt project
│   │   ├── dbt/                    # dbt project directory
│   │   │   └── neobank_dbt/        # dbt project for Neobank
│   │   │       ├── dbt_project.yml # dbt project configuration
│   │   │       ├── macros/         # Reusable SQL macros
│   │   │       │   ├── generate_custom_schema.sql  # Custom schema macro
│   │   │       │   ├── macros_.sql # Additional macros
│   │   │       │   └── tests_.sql  # Custom test definitions
│   │   │       ├── models/         # dbt models for data transformation
│   │   │       │   ├── intermediate/  # Intermediate models
│   │   │       │   │   ├── int_*.sql  # SQL models (e.g., int_ams_account_status.sql)
│   │   │       │   │   ├── int_*.yml  # Model metadata and tests
│   │   │       │   │   └── schema.yml  # Schema definitions
│   │   │       │   ├── marts/      # Final data marts
│   │   │       │   │   ├── mart_customer_transactions.sql  # Customer transaction mart
│   │   │       │   │   └── mart_customer_transactions.yml  # Mart metadata
│   │   │       │   └── staging/    # Staging models
│   │   │       ├── package-lock.yml  # dbt dependency lock file
│   │   │       ├── packages.yml     # dbt package dependencies
│   │   │       └── README.md       # dbt project documentation
│   │   └── neobank_dag.py          # Airflow DAG for dbt execution
│   ├── Dockerfile                  # Docker configuration for Airflow
│   ├── README.md                   # Airflow project README
│   └── requirements.txt            # Airflow dependencies
├── data/                           # Raw data files
│   ├── source_ams/                 # AMS data (e.g., AMS_accountStatus.csv)
│   ├── source_crm/                 # CRM data (e.g., CRM_customerGeneralInfo.csv)
│   └── source_tps/                 # TPS data (e.g., TPS_transaction.csv)
├── data_generation/                # Data generation scripts
│   ├── customer_data_generator.py  # Generates sample data
│   └── README.md                   # Data generation documentation
├── snowflake_scripts/              # Snowflake setup and load scripts
│   ├── cost_optimization.sql       # Snowflake cost optimization queries
│   ├── load_csv_to_snowflake.py    # Loads CSV data into Snowflake
│   ├── load_raw_data.sql           # Creates bronze schema tables
│   ├── mart.sql                    # Mart-related SQL (optional)
│   ├── role_and_permissions.sql    # Snowflake role and permission setup
│   └── README.md                   # Snowflake scripts documentation
├── README.md                       # This file
├── requirements_dev.txt            # Development dependencies
└── requirements.txt                # Production dependencies
```

## Setup Instructions

### 1. Create and Activate Virtual Environment

Set up a Python virtual environment for development:

```sh
python3.11 -m venv .venv
source .venv/bin/activate  # For Linux/macOS
# .venv\Scripts\activate    # For Windows
```

### 2. Install Dependencies

For development (includes testing and linting tools):

```sh
pip install -r requirements_dev.txt
```

For production (Airflow and dbt dependencies):

```sh
pip install -r requirements.txt
```

### 3. Install Git Hooks

Install pre-commit hooks to enforce code quality:

```sh
pre-commit install
```

Test hooks on all files:

```sh
pre-commit run --all-files
```

### 4. Snowflake Setup

Configure Snowflake with a warehouse, database, role, and schemas:

```sql
-- Warehouse, Database, & Role Setup
CREATE WAREHOUSE IF NOT EXISTS neobank_wh
  WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;
CREATE DATABASE IF NOT EXISTS neobank_db;
CREATE ROLE IF NOT EXISTS neobank_role;

-- Permission Grant
GRANT USAGE ON WAREHOUSE neobank_wh TO ROLE neobank_role;
GRANT ALL ON DATABASE neobank_db TO ROLE neobank_role;
GRANT ROLE neobank_role TO USER <your_user>;

-- Switch to new role and database and create schemas
USE ROLE neobank_role;
USE DATABASE neobank_db;
CREATE OR REPLACE SCHEMA bronze;
CREATE OR REPLACE SCHEMA silver;
CREATE OR REPLACE SCHEMA gold;
```

### 5. Load Raw Data into Snowflake

#### Create Bronze Tables

Run the `load_raw_data.sql` script to create tables in the `bronze` schema. Example table creation:

```sql
CREATE OR REPLACE TABLE neobank_db.bronze.ams_account_status (
    account_id VARCHAR,
    status VARCHAR,
    updated_at VARCHAR
);
```

Refer to `snowflake_scripts/load_raw_data.sql` for all table definitions.

#### Generate and Load Data

Use the `customer_data_generator.py` script to generate sample data (if needed) and `load_csv_to_snowflake.py` to load CSV files from `data/` into Snowflake.

Create an `.env` file in the root directory:

```plain
DATA_FOLDER=data
SNOWFLAKE_ACCOUNT=<Account Identifier>
SNOWFLAKE_USER=<Username>
SNOWFLAKE_PASSWORD=<Password>
SNOWFLAKE_WAREHOUSE=neobank_wh
SNOWFLAKE_ROLE=neobank_role
SNOWFLAKE_DATABASE=neobank_db
SNOWFLAKE_SCHEMA=BRONZE
```

Run the load script:

```sh
python snowflake_scripts/load_csv_to_snowflake.py
```

For more information on how to configure Snowflake and load data into it, check the documentation [here](./snowflake_scripts/README.md).

### 6. Set Up dbt Project

The dbt project resides in `astro/dags/dbt/neobank_dbt/`. If initializing a new dbt project:

```sh
cd astro/dags/dbt
dbt init neobank_dbt
cd neobank_dbt
```

Remove the default `example` model and create model directories:

```sh
rm -rf models/example
mkdir -p models/staging models/intermediate models/marts
```

#### Configure dbt

Edit `~/.dbt/profiles.yml` to connect to Snowflake:

```yaml
neobank_dbt:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <account_identifier>
      user: <username>
      password: <password>
      role: neobank_role
      warehouse: neobank_wh
      database: neobank_db
      schema: bronze
      threads: 3
```

Update `dbt_project.yml` in `astro/dags/dbt/neobank_dbt/` to define model paths and schemas:

```yaml
name: 'neobank_dbt'
version: '1.0.0'
config-version: 2

profile: 'neobank_dbt'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]

models:
  neobank_dbt:
    staging:
      +schema: STAGING
      materialized: view
    intermediate:
      +schema: silver
      materialized: table
    marts:
      +schema: gold
      materialized: table
```

Create a macro to avoid schema prefixing in `macros/generate_custom_schema.sql`:

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

#### Example dbt Model

The simplest model, `int_ams_account_status.sql` in `models/intermediate/`, transforms raw data from the `bronze` schema:

```sql
WITH source AS (
    SELECT * FROM {{ source('bronze', 'ams_account_status') }}
)
SELECT
    account_id,
    status,
    CAST(updated_at AS TIMESTAMP) AS updated_at
FROM source
```

The corresponding `int_ams_account_status.yml` defines tests:

```yaml
version: 2
models:
  - name: int_ams_account_status
    columns:
      - name: account_id
        tests:
          - not_null
          - unique
      - name: status
        tests:
          - not_null
      - name: updated_at
        tests:
          - not_null
```

Other models (e.g., `int_crm_customer_general_info.sql`, `mart_customer_transactions.sql`) follow a similar pattern, joining and transforming data as needed.

### 7. Set Up Astronomer and Airflow

Install the Astronomer CLI:

```sh
curl -sSL install.astronomer.io | sudo bash -s
```

Initialize the Airflow project (if not already done):

```sh
mkdir -p astro
cd astro
astro dev init
```

The `astro/` directory contains the Airflow setup, including `Dockerfile`, `requirements.txt`, and `dags/`. For more information on how to set up this, check the documentation [here](./astro/README.md).

### 8. Run the Pipeline

1. Start Airflow:

    ```sh
    cd astro
    astro dev start
    ```

2. Configure the Snowflake connection (`snowflake_conn`) in the Airflow UI.
3. The `neobank_dag` DAG runs daily, executing dbt models in sequence (`staging` → `intermediate` → `marts`).
4. Monitor via the Airflow UI or run dbt commands manually for testing:

    ```sh
    cd astro/dags/dbt/neobank_dbt
    dbt debug  # Test connection
    dbt run    # Run models
    dbt test   # Run tests
    dbt docs generate && dbt docs serve  # Generate and view documentation
    ```

### 9. Clean Up Snowflake (Optional)

Remove Snowflake resources if no longer needed:

```sql
USE ROLE ACCOUNTADMIN;
DROP WAREHOUSE IF EXISTS neobank_wh;
DROP DATABASE IF NOT EXISTS neobank_db;
DROP ROLE IF EXISTS neobank_role;
```

For additional details, refer to the following documentation in this project:

- [Astro & dbt](./astro/README.md)
- [Data generation](./data_generation/README.md)
- [Snowflake Setup](./snowflake_scripts/README.md)
