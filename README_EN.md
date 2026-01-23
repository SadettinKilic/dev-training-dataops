<p align="center">
  <a href="./README.md"><img src="https://img.shields.io/badge/Language-Türkçe-white"></a>
  <a href="./README_EN.md"><img src="https://img.shields.io/badge/Language-English-red"></a>
</p>

* * *

# 🏅 Paris 2024 Olympics DataOps & Analytics Project
[**[🇹🇷 Türkçe versiyon için tıklayın](README.md)**] | [🇺🇸 English]

This project aims to create an **End-to-End** Data Engineering pipeline using Paris 2024 Summer Olympic Games data. Designed in accordance with **Medallion Architecture** principles on the Azure ecosystem, it is a modern data platform that brings together ADF, Databricks, and dbt technologies.
* * *
## 🏗️  Architecture and Scope
The project covers all processes that data undergoes from its raw state (CSV/Parquet) to becoming reportable Gold tables.
### **Technology Stack**
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
| `kv-training-dataops` | Key Vault | Secure storage of tokens and connection details. |
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

### 2\. IAM and Security Configuration (Important)

Define the following permissions so that services can communicate with each other on Azure:
-   **Storage Account:** Grant the `Storage Blob Data Contributor` permission to the Databricks Access Connector.
-   **Key Vault:** Grant the `Key Vault Secrets User` permission to ADF to read passwords. Grant your own user the `Key Vault Administrator` permission.
-   **RBAC:** Centralize access management by gathering all resources under a single Resource Group.


### 3\. Databricks Catalog and Schema Setup

Set up the Unity Catalog structure via the Databricks SQL Editor:
```sql
    CREATE CATALOG IF NOT EXISTS dataops MANAGED LOCATION 'abfss://dbx-managed@sttrainingdataops.dfs.core.windows.net/';
    USE CATALOG dataops;

    CREATE SCHEMA IF NOT EXISTS bronze MANAGED LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/';
    CREATE SCHEMA IF NOT EXISTS silver MANAGED LOCATION 'abfss://silver@sttrainingdataops.dfs.core.windows.net/';
    CREATE SCHEMA IF NOT EXISTS gold MANAGED LOCATION 'abfss://gold@sttrainingdataops.dfs.core.windows.net/';
```
### 4. Data Definition and Bronze Table Structures

###
Tables in the Bronze layer are defined under Unity Catalog as follows, preserving the schemas of the raw data (CSV/Parquet):

###
```sql
    /* Set Catalog and Schema Context */
    USE CATALOG dataops;
    USE SCHEMA bronze;

    /* Athlete Table (Parquet Format) */
    CREATE TABLE IF NOT EXISTS bronze.raw_athletes
    USING PARQUET
    LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/athletes/';

    /* Coach Table (Parquet Format) */
    CREATE TABLE IF NOT EXISTS bronze.raw_coaches
    USING PARQUET
    LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/coaches/';

    /* Event Table (Parquet Format) */
    CREATE TABLE IF NOT EXISTS bronze.raw_events
    USING PARQUET
    LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/events/';

    /* NOC (National Olympic Committees) Table (CSV Format) */
    CREATE TABLE IF NOT EXISTS bronze.raw_nocs
    USING CSV
    OPTIONS (header=‘true’, inferSchema=‘true’)
    LOCATION 'abfss://bronze@sttrainingdataops.dfs.core.windows.net/nocs/';
```
### 5. ADF Pipeline Configuration
Two main processes are managed on ADF:
-   **Ingestion:** The `raw_to_bronze` pipeline dynamically moves raw data to the Bronze layer by reading metadata from the `bronze/param.json` file.
-   **Transformation:** The `dbt_dataops_gold_daily` pipeline triggers the Databricks API with a token obtained from Key Vault and runs dbt models.
### 6\. dbt (Data Build Tool) Integration
Connect the dbt project in the `dev-training-dataops` repository to Databricks:
-   Define the Databricks host and http\_path information in the `profiles.yml` file.
-   Organize the models by layer in `dbt_project.yml`.
-   `CI/CD:` Use GitHub Actions to run dbt tests every time code is pushed.

### 7. CI/CD Process (GitHub Actions)

The dbt side of the project is integrated with GitHub Actions to ensure code quality and continuity. This prevents manual errors and keeps the code “ready to run” at all times.

**1. Automated Checks and Data Quality**
-   **SQLFluff (Linting):** All SQL code included in the project is automatically scanned. Code that does not comply with defined coding standards (indentation, capitalization, etc.) is detected and corrected. Github Actions has write/read permissions on the repository. It automatically formats the code and logs any lines it cannot format.
-   **dbt Freshness:** By reading the freshness configuration in the `sources.yml` file located under `models/silver`, it checks whether the Raw (Bronze) data is up to date. If there is data older than the specified time, the pipeline issues a warning.

**2\. Deployment Pipeline**


Our workflow file on GitHub automatically performs the following steps:

-   **Environment Setup:** The necessary Python libraries and the `dbt-databricks` adapter are installed.
-   **Connection Test:** The Databricks SQL Warehouse connection is verified.
-   **Code Testing:** Basic tests are run on dbt models to check for logic errors.

**3\. Version Control and Integration**


-   **ADF & dbt Sync:** The Web Activity on ADF always triggers the latest dbt code found in the “Production” branch on GitHub. This ensures that tests performed in the development (dev) environment do not go live without approval.


* * *
## ⚙️ Additional Configuration Notes

Those who wish to run the project in their own environment must make the following settings:

-   **GitHub Secrets:** You must add the following variables to your GitHub repository's `Settings > Secrets and variables > Actions` section:
    -   `DATABRICKS_HOST`: Your Databricks instance URL.
    -   `DATABRICKS_HTTP_PATH`: SQL Warehouse HTTP path.
    -   `DATABRICKS_TOKEN`: The access token you also stored in Key Vault.

-   **Environment Variables:** To allow dbt to access these secrets, env_var usage is configured in the `profiles.yml` file (e.g., `{{ env_var(‘DBT_HOST’) }}`).


* * *

## 🛠️  Project Highlights

-   **Dynamic Ingestion:** No need to write code to add a new table; simply update the `param.json` file.

-   **Secure Secrets:** No passwords or tokens are hardcoded in the code; they are dynamically retrieved entirely from Azure Key Vault.

-   **Medallion Architecture:** Data quality is enhanced at each layer (Raw -> Bronze -> Silver -> Gold) to create a reliable “Single Source of Truth.”

-   **Serverless Efficiency:** Using Databricks Serverless SQL Warehouse, costs are incurred only while queries are running, and vCPU quota limits are exceeded.

-   **Automated DataOps:** Code quality (SQLFluff) and data freshness (dbt Freshness) are automatically monitored using GitHub Actions, minimizing the margin of error.

-   **Separation of Concerns:** Data transformation logic (dbt) and data movement/orchestration logic (ADF) are managed in separate repositories, providing a modular and easy-to-maintain structure.


* * *

## 📈 About the Dataset

The dataset used in the project is the [Paris 2024 Olympic Summer Games](https://www.kaggle.com/datasets/piterfm/paris-2024-olympic-summer-games) set from Kaggle. It contains detailed information about athletes, coaches, medals, and events.

* * *

_This document has been prepared in accordance with modern DataOps principles._
