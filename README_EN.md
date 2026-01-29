<p align="left">
  <strong>Language:</strong>
  <a href="./README.md">
    <img src="https://img.shields.io/badge/T%C3%BCrk%C3%A7e-lightgrey">
  </a>
  <img src="https://img.shields.io/badge/English-red">
</p>
<p align="left">
  <!-- Core Tech -->
  <img src="https://img.shields.io/badge/dbt-Analytics-orange">
  <img src="https://img.shields.io/badge/Microsoft%20Azure-Cloud-blue">

  <!-- Architecture -->
  <img src="https://img.shields.io/badge/Architecture-Medallion-success">

  <!-- REAL CI BADGE -->
  <img src="https://github.com/SadettinKilic/dev-training-dataops/actions/workflows/dbt_ci.yml/badge.svg">

  <!-- DataOps -->
  <img src="https://img.shields.io/badge/DataOps-Automated-informational">
</p>


* * *

# 🏅 Paris 2024 Olympics DataOps & Analytics Project

This project aims to create an **end-to-end** Data Engineering pipeline using data from the Paris 2024 Summer Olympic Games. Designed in accordance with **Medallion Architecture** principles on the Azure ecosystem, it is a modern, containerized data platform that brings together Docker, ADF, Databricks, and dbt technologies.
* * *
## 🏗️ Architecture and Scope
The project covers all processes that data undergoes from its raw state (CSV/Parquet) to becoming reportable Gold tables.
### **Technology Stack**
-   **Containerization:** Docker (Portable dbt Runtime)
-   **Orchestration:** Azure Data Factory (ADF)
-   **Data Warehouse & Processing:** Azure Databricks (Spark & Serverless SQL Warehouse)
-   **Transformation:** dbt (data build tool)
-   **Data Lake:** Azure Data Lake Storage Gen2 (ADLS Gen2)
-   **Security:** Azure Key Vault & Managed Identity (RBAC)
-   **Version Control:** GitHub (ADF & dbt integration)
### 📂 Project Repositories

In accordance with DataOps principles, the project is managed in two separate repositories: transformation code and orchestration configuration:

| **Repository** | **Content** | **Link** |
| --- | --- | --- |
| **dbt Repository** | dbt Models, SQL logic, CI/CD (SQLFluff, Freshness) | [🔗 dev-training-dataops](https://github.com/SadettinKilic/dev-training-dataops) |
| **ADF Repository** | Azure Data Factory Pipelines, JSON definitions, Linked Services, Triggers | [🔗 dev-training-dataops-adf](https://github.com/SadettinKilic/dev-training-dataops-adf) |
* * *
## 📂 Azure Resource Structure (Resource Group: `rg-training-dataops`)

| **Resource Name** | **Type** | **Purpose** |
| --- | --- | --- |
| `sttrainingdataops` | Storage Account | Data lake hosting Bronze, Silver, and Gold tiers. |
| `kv-training-dataops` | Key Vault | Secure storage of tokens and connection information. |
| `dev-training-dataops-adf` | Data Factory | Management and scheduling of pipelines. |
| `dbx-training-dataops-dev` | Databricks | Primary processing engine where dbt models are run. |
| `dbx-connector-training-dataops-dev` | Access Connector | Managed identity for Databricks access to Storage. |

* * *

## 🚀 Setup and Implementation Steps

Follow these steps to get this project up and running from scratch:

### 1\. Preparing the Infrastructure and Data Layers

Create the following container structure on the Storage Account:
-   `source/raw_data`: Raw CSV files downloaded from Kaggle.
-   `bronze`, `silver`, `gold`: Processed data layers.
-   `dbx-managed`: Space reserved for the Databricks Managed Catalog.
-   `monitoring`: Contains monitoring tables. Will be used for the dashboard.

### 2\. IAM and Security Configuration (Important)

Define the following permissions on Azure so that services can communicate with each other:
-   **Storage Account:** Grant the `Storage Blob Data Contributor` permission to the Databricks Access Connector.
-   **Key Vault:** Grant the `Key Vault Secrets User` permission to ADF so it can read passwords. Define the `Key Vault Administrator` permission for your own user.
-   **RBAC:** Centralize access management by gathering all resources under a single Resource Group.
    

### 3\. Databricks Catalog and Schema Setup

Set up the Unity Catalog structure via the Databricks SQL Editor (you will need to create external locations beforehand):
```sql
    CREATE CATALOG IF NOT EXISTS dataops MANAGED LOCATION ‘abfss://dbx-managed@sttrainingdataops.dfs.core.windows.net/’;
    USE CATALOG dataops; 
    
    CREATE SCHEMA IF NOT EXISTS bronze MANAGED LOCATION ‘abfss://bronze@sttrainingdataops.dfs.core.windows.net/’;
    CREATE SCHEMA IF NOT EXISTS silver MANAGED LOCATION ‘abfss://silver@sttrainingdataops.dfs.core.windows.net/’;
    CREATE SCHEMA IF NOT EXISTS gold MANAGED LOCATION ‘abfss://gold@sttrainingdataops.dfs.core.windows.net/’;
    CREATE SCHEMA IF NOT EXISTS monitoring MANAGED LOCATION ‘abfss://monitoring@sttrainingdataops.dfs.core.windows.net/’;
```
### 4. Data Definition and Bronze Table Structures

###   
Tables in the Bronze layer are defined under Unity Catalog as follows, preserving the schemas of raw data (CSV/Parquet):

### 
```sql
    /* Set Catalog and Schema Context */
    USE CATALOG dataops;
    USE SCHEMA bronze;
    
    /* Athlete Table (Parquet Format) */
    CREATE TABLE IF NOT EXISTS bronze.raw_athletes
    USING PARQUET
    LOCATION ‘abfss://bronze@sttrainingdataops.dfs.core.windows.net/athletes/’;
    
    /* Coach Table (Parquet Format) */
    CREATE TABLE IF NOT EXISTS bronze.raw_coaches
    USING PARQUET
    LOCATION ‘abfss://bronze@sttrainingdataops.dfs.core.windows.net/coaches/’;
    
    /* Event Table (Parquet Format) */
    CREATE TABLE IF NOT EXISTS bronze.raw_events
    USING PARQUET
    LOCATION ‘abfss://bronze@sttrainingdataops.dfs.core.windows.net/events/’;

    /* NOC (National Olympic Committees) Table (CSV Format) */
    CREATE TABLE IF NOT EXISTS bronze.raw_nocs
    USING CSV
    OPTIONS (header=‘true’, inferSchema=‘true’)
    LOCATION ‘abfss://bronze@sttrainingdataops.dfs.core.windows.net/nocs/’;

    CREATE TABLE IF NOT EXISTS dataops.monitoring.audit_logs (
      model_name STRING,
      execution_time TIMESTAMP,
      row_count LONG,
      status STRING
    ) USING DELTA;
```
### 5\. ADF Pipeline Configuration
Two main processes are managed on ADF:
-   **Ingestion:** The `raw_to_bronze` pipeline dynamically moves raw data to the Bronze layer by reading the metadata in the `bronze/param.json` file.
-   **Transformation:** The `dbt_dataops_gold_daily` pipeline triggers the Databricks API with a token obtained from Key Vault and runs dbt models.  

### 6\. dbt (Data Build Tool) Integration
Clone this repository to your computer.
Update the `.env.example` file in the project directory with your Databricks connection details and run the following command:
```bash
    mv .env.example .env
```
You can run all dbt models on Databricks using Docker Compose:
```bash
    docker-compose up
```
### 3\. CI/CD Process (GitHub Actions)
###
The project has an advanced pipeline structure that automatically triggers with every code change:
-   **Static Analysis:** SQL code standards are checked and automatically corrected using `sqlfluff`.
-   **Containerized Execution:** dbt commands are run inside a custom `dataops-dbt-runner` Docker image on GitHub Actions. This optimizes setup times by 70%.
-   **Automated Docs:** After each successful run, dbt documentation is automatically generated and published on **GitHub Pages**.
* * *

### 📊 Monitoring and Observability (DataOps Dashboard)
###
The health, performance, and data quality of the project are monitored in real-time via the **Databricks SQL Dashboard**.
-   **Pipeline Reliability:** Daily successful/failed model runs.
-   **Model Performance (Wall of Shame):** Identification of models consuming the most resources and requiring optimization.
-   **Data Flow Speed (Throughput):** SQL efficiency analysis based on the number of rows processed per second.
-   **Data Volume Drift Analysis:** Tracking sudden changes in the amount of data coming from source systems.

### 📖 Live Documentation and Data Lineage
###
The technical details of the project and the relationships between tables are automatically documented with **dbt Docs**.
-   **[dbt Docs Page](https://sadettinkilic.github.io/dev-training-dataops/)** You can view the flow diagram by clicking the ‘Lineage’ button at the bottom right.
-   **Interactive Lineage:** You can visually examine the data flow between the Bronze -> Silver -> Gold layers.
-   **Data Catalog:** Table schemas, column descriptions, and applied dbt tests.

* * *

## ⚙️ Extra Configuration Notes

Those who want to run the project in their own environment need to make the following settings:

-   **GitHub Secrets:** You must add the following variables to your GitHub repository's `Settings > Secrets and variables > Actions` section:
    -   `DATABRICKS_HOST`: Your Databricks instance URL.
    -   `DATABRICKS_HTTP_PATH`: The SQL Warehouse HTTP path.
    -   `DATABRICKS_TOKEN`: The access token you also stored in Key Vault.
        
-   **Environment Variables:** To allow dbt to access these secrets, env_var usage is configured in the `profiles.yml` file (e.g., `{{ env_var(‘DBT_HOST’) }}`).


* * *

## 🛠️ Project Highlights
-   **Portable Runtime (Docker):** Container structure that minimizes differences between the development and production environments.
-   **Dynamic Ingestion:** No need to write code to add a new table; simply update the `param.json` file.
-   **Secure Secrets:** No passwords or tokens are hardcoded in the code; they are dynamically retrieved entirely through Azure Key Vault.
-   **Medallion Architecture:** Data quality is enhanced at each layer (Raw -> Bronze -> Silver -> Gold) to create a reliable “Single Source of Truth.”
-   **Zero-Install CI:** GitHub Actions speeds up by using ready-made Docker images instead of installing libraries on empty machines.
-   **Automated DataOps:** Error margin is minimized by automatically checking code quality (SQLFluff) and data freshness (dbt Freshness) with GitHub Actions.
-   **Separation of Concerns:** Data transformation logic (dbt) and data transport/orchestration logic (ADF) are managed in separate repositories, providing a modular and easy-to-maintain structure.

* * *

## 📈 About the Dataset

The dataset used in the project is the [Paris 2024 Olympic Summer Games](https://www.kaggle.com/datasets/piterfm/paris-2024-olympic-summer-games) set from Kaggle. It contains detailed information about athletes, coaches, medals, and events.

* * *

_This document has been prepared in accordance with modern DataOps principles._

