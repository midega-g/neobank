# Documentation for Files in the Folder

## `cost_optimization.sql`

- **Purpose**: This script is designed to optimize costs by analyzing and managing resource usage in the Snowflake environment. It may include queries to identify unused or underutilized resources, optimize query performance, and reduce storage costs.
- **Where to Run**: Execute this script in the Snowflake SQL editor or any SQL client connected to your Snowflake instance.
- **Additional Information**: Ensure you have the necessary permissions to access system views and perform any updates or changes suggested by the script.

## `load_csv_to_snowflake.py`

- **Purpose**: A Python script to automate the process of loading CSV files into Snowflake tables. It likely uses the Snowflake Python Connector or a library like `snowflake-connector-python` to interact with Snowflake.
- **Where to Run**: Run this script in a Python environment with the required dependencies installed. Ensure the environment has network access to Snowflake and the CSV files.
- **Additional Information**: Configure the script with the appropriate Snowflake credentials, database, schema, and table details. Verify that the CSV files are formatted correctly and accessible.

## `load_raw_data.sql`

- **Purpose**: This script is used to load raw data into staging or raw tables in Snowflake.
- **Where to Run**: Execute this script in the Snowflake SQL editor or any SQL client connected to your Snowflake instance.
- **Additional Information**: Ensure the external stage or file location is properly configured, and you have the necessary permissions to load data into the target tables.

## `mart.sql`

- **Purpose**: This script is used to create or update data marts in Snowflake. It likely includes SQL statements to transform raw or processed data into a format suitable for reporting and analytics.
- **Where to Run**: Execute this script in the Snowflake SQL editor or any SQL client connected to your Snowflake instance.
- **Additional Information**: Ensure the source tables and data are available and up-to-date before running this script. Verify that the target schema and tables exist or will be created as part of the script.

## `role_and_permissions.sql`

- **Purpose**: This script is used to manage roles and permissions in Snowflake. It likely includes SQL statements to create roles, grant privileges, and manage access control for users and objects.
- **Where to Run**: Execute this script in the Snowflake SQL editor or any SQL client connected to your Snowflake instance.
- **Additional Information**: Ensure you have the necessary administrative privileges to manage roles and permissions. Review the script carefully to avoid granting excessive or unintended access.

## Execution Order

- In the Snowflake SQL editor, run the scripts in the following order:

    `role_and_permissions.sql` $\rightarrow$ `cost_optimization.sql` $\rightarrow$ `load_raw_data.sql`

- In the terminal, run:

    `load_csv_to_snowflake.py`
