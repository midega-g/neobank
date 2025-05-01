# Neobank Data Pipeline Documentation

This repository contains the data pipeline for the Neobank project, built using Apache Airflow with Astronomer Cosmos and dbt (data build tool) to orchestrate and transform data. The pipeline is designed to process and transform data stored in Snowflake, enabling analytics and reporting for the Neobank platform.

## Purpose

The Neobank data pipeline integrates data from various sources (e.g., account management systems, customer relationship management, and transaction processing systems) into a unified data warehouse in Snowflake. It uses dbt to model and transform raw data into structured, analytics-ready datasets, orchestrated via Airflow DAGs using Astronomer Cosmos.

## Tools and Technologies

**Apache Airflow:** Workflow orchestration for scheduling and managing data pipelines.
**Astronomer Cosmos:** A library that integrates dbt with Airflow, enabling dbt workflows to run as Airflow DAGs.
**dbt (data build tool):** Handles data transformation, modeling, and testing within Snowflake.
**Snowflake:** Cloud data warehouse for storing and processing data.
**Docker:** Containerizes the Airflow environment for consistent deployment.

## Repository Structure

The repository is organized to separate concerns between orchestration (Airflow DAGs), data transformation (dbt models), and environment setup (Docker and dependencies).

```plain
.
├── dags/                           # Airflow DAGs and dbt project
│   ├── dbt/                        # dbt project directory
│   │   └── neobank_dbt/            # dbt project for Neobank
│   │       ├── dbt_project.yml     # dbt project configuration
│   │       ├── macros/             # Reusable SQL macros
│   │       │   ├── macros_.sql     # Custom macros for transformations
│   │       │   └── tests_.sql      # Custom test definitions
│   │       ├── models/             # dbt models for data transformation
│   │       │   ├── intermediate/   # Intermediate models for raw data processing
│   │       │   │   ├── int_*.sql   # SQL models for intermediate transformations
│   │       │   │   ├── int_*.yml   # YAML files for model metadata and tests
│   │       │   │   └── schema.yml  # Schema definitions for intermediate models
│   │       │   ├── marts/          # Final data marts for analytics
│   │       │   │   ├── mart_customer_transactions.sql  # Final customer transaction mart
│   │       │   │   └── mart_customer_transactions.yml  # Mart metadata and tests
│   │       │   └── staging/        # Staging models (optional, for raw data)
│   │       ├── package-lock.yml    # dbt dependency lock file
│   │       ├── packages.yml        # dbt package dependencies
│   │       └── README.md           # dbt project-specific documentation
│   └── neobank_dag.py              # Airflow DAG for dbt execution
├── Dockerfile                      # Docker configuration for Airflow runtime
├── README.md                       # This file
└── requirements.txt                # Python dependencies for Airflow
```

## Directory and File Explanations

`dags/`: Contains all Airflow DAGs and the dbt project.
`dbt/neobank_dbt/`: The dbt project directory, following dbt best practices.
`dbt_project.yml`: Configures the dbt project, including model paths and profiles.
`macros/`: Stores reusable SQL macros and custom tests for transformations and data quality.
`models/`: Contains SQL models organized by layers:
`intermediate/`: Processes raw data into structured intermediate tables (e.g., account status, KYC, transactions).
`marts/: Final analytics-ready tables (e.g., customer transactions mart).
`staging/`: (Optional) For raw data staging, if needed.

`*.yml`: YAML files define model metadata, tests, and documentation.
package-lock.yml, packages.yml: Manage dbt dependencies.

`neobank_dag.py`: Defines the Airflow DAG that runs the dbt project using Astronomer Cosmos.

`Dockerfile:` Configures the Airflow runtime environment, installing dbt-snowflake in a virtual environment.
`requirements.txt`: Lists Python dependencies, including astronomer-cosmos and apache-airflow-providers-snowflake.
`README.md`: This documentation file.

## Why dbt and Astro?

### dbt

- **Modular Data Transformation:** dbt allows modular SQL-based transformations, making it easy to build, test, and maintain data models.
- **Testing and Documentation:** Built-in testing (e.g., uniqueness, not-null checks) and auto-generated documentation ensure data quality and clarity.
- **Snowflake Integration:** dbt-snowflake optimizes transformations for Snowflake's architecture.

### Astronomer Cosmos

- **Seamless dbt-Airflow Integration:** Cosmos translates dbt projects into Airflow DAGs, leveraging Airflow's scheduling and monitoring.
- **Scalability:** Airflow handles complex workflows, while Cosmos simplifies dbt execution within Airflow.

### Combined Benefits

- The pipeline combines Airflow's orchestration with dbt's transformation capabilities, enabling a robust, scalable, and maintainable data pipeline.
- Docker ensures consistent environments across development and production.

## Setup and Creation Process

### Initialize the Airflow Environment

- Use Astronomer’s Astro Runtime `quay.io/astronomer/astro-runtime:11.3.0` as the base Docker image.
- Install `dbt-snowflake` in a virtual environment (`dbt_venv`) to avoid conflicts with Airflow dependencies (see Dockerfile).
- Specify dependencies in `requirements.txt`:
  - `astronomer-cosmos`: For dbt-Airflow integration.
  - `apache-airflow-providers-snowflake`: For Snowflake connectivity.

### Set Up the dbt Project

- Create the `neobank_dbt` project under `dags/dbt/`.
- Configure `dbt_project.yml` to define model paths (`models/`, `macros/`) and profiles.
- Organize models into staging, intermediate, and marts layers:
- Staging: (Optional) For raw data extraction.
- Intermediate: Processes raw data into structured tables (e.g., `int_ams_account_status.sql` for account status).
- Marts: Final tables for analytics (e.g., `mart_customer_transactions.sql` for customer transaction insights).

- Write macros (`macros_.sql`) for reusable logic and tests (tests_.sql) for data quality.
- Define model metadata and tests in `.yml` files.

### Create the Airflow DAG

- Define `neobank_dag.py` using Astronomer Cosmos to run the dbt project.
- Configure:
  - `ProjectConfig`: Points to the dbt project directory (`/usr/local/airflow/dags/dbt/neobank_dbt`).
  - `ProfileConfig`: Uses `SnowflakeUserPasswordProfileMapping` for Snowflake authentication via Airflow’s `snowflake_conn` connection.
  - `ExecutionConfig`: Specifies the dbt executable path (`dbt_venv/bin/dbt`).
DAG Parameters: Runs daily (`@daily`), starts from April 1, 2025, with 2 retries and no catchup.

- Enable dependency installation (`install_deps=True`) for dbt packages.

### Docker and Deployment

- Build the Docker image using the Dockerfile to include the Airflow runtime and dbt.
- Deploy the Airflow instance (e.g., via Astronomer or a custom setup).
- Ensure Snowflake credentials including your password are stored in Airflow’s connections (`snowflake_conn`) as follows:

```json
{
  "account": "<account_locator>-<account_name>",
  "warehouse": "neobank_wh",
  "database": "neobank_db",
  "role": "neobank_role",
  "insecure_mode": false
}
```

### Running the Pipeline

- Start the Airflow instance (e.g., via docker-compose or Astronomer CLI) on your local machine by running `astro dev start`.
- This command will spin up five Docker containers on your machine, each for a different Airflow component:

  - Postgres: Airflow's Metadata Database
  - Scheduler: The Airflow component responsible for monitoring and triggering tasks
  - DAG Processor: The Airflow component responsible for parsing DAGs
  - API Server: The Airflow component responsible for serving the Airflow UI and API
  - Triggerer: The Airflow component responsible for triggering deferred tasks

When all five containers are ready the command will open the browser to the Airflow UI at <http://localhost:8080/>. You should also be able to access your Postgres Database at `localhost:5432/postgres` with username `postgres` and password `postgres`.

Note: If you already have either of the above ports allocated, you can either [stop your existing Docker containers or change the port](https://www.astronomer.io/docs/astro/cli/troubleshoot-locally#ports-are-not-available-for-my-local-airflow-webserver).

## More Details

- Ensure the Snowflake connection (`snowflake_conn`) is configured in Airflow.
- The neobank_dag DAG runs daily, executing the dbt project:
- dbt installs dependencies (from `packages.yml`).
- dbt runs models in sequence (`staging` → `intermediate` → `marts`).
- dbt applies tests defined in `.yml` files.

Monitor the pipeline via the Airflow UI or dbt logs.

### Deploy Your Project to Astronomer

If you have an Astronomer account, pushing code to a Deployment on Astronomer is simple. For deploying instructions, refer to Astronomer documentation: <https://www.astronomer.io/docs/astro/deploy-code/>
