import os
from datetime import datetime

from cosmos import DbtDag, ProfileConfig, ProjectConfig, ExecutionConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping

profile_config = ProfileConfig(
    profile_name="default",
    target_name="dev",
    profile_mapping=SnowflakeUserPasswordProfileMapping(
        conn_id="snowflake_conn",
        profile_args={"database": "neobank_db"},
    ),
)

execution_config = ExecutionConfig(
    dbt_executable_path=f"{os.environ['AIRFLOW_HOME']}/dbt_venv/bin/dbt",
)

dbt_snowflake_dag = DbtDag(
    project_config=ProjectConfig(
        "/usr/local/airflow/dags/dbt/neobank_dbt",
    ),
    profile_config=profile_config,
    execution_config=execution_config,
    operator_args={"install_deps": True},
    # normal dag parameters
    schedule_interval="@daily",  # "*/5 * * * *",
    start_date=datetime(2025, 4, 1),
    catchup=False,
    dag_id="neobank_dag",
    default_args={"retries": 2},
)
