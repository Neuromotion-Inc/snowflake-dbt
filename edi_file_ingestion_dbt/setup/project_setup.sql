-- =============================================================================
-- EDI File Ingestion dbt Project: Environment Setup
--
-- Sets up a dev/sandbox Snowflake account that mimics the production HIPAA
-- account, so the edi_file_ingestion dbt project can be developed and tested
-- without touching real data. Do NOT run this in the production HIPAA account.
--
-- Run as ACCOUNTADMIN. Safe to re-run: it never drops or replaces objects.
-- Sample EDI files are not included; load some into the stage before running dbt.
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- The role dbt runs as (granted its privileges in STEP 4 below).
CREATE ROLE IF NOT EXISTS EFI_DBT_ROLE;

-- step1: create substitutes for what's in the HIPAA snowflake account.
-- In that account, a WH already exists along w/ a DB/SCHEMA/STAGE which FIVETRAN writes to.
CREATE OR ALTER WAREHOUSE ETL_WH WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 30;
CREATE DATABASE IF NOT EXISTS FIVETRAN_DB;
CREATE SCHEMA IF NOT EXISTS FIVETRAN_DB.AVAILITY;
-- Fivetran SFTP connector syncs SFTP files here
CREATE STAGE IF NOT EXISTS FIVETRAN_DB.AVAILITY."ALL"
  DIRECTORY = (
    ENABLE = true
    AUTO_REFRESH = true
  );

-- =============================================================================
-- STEP 2: Create a database and schemas for integrations and model materializations
-- The DEV and PROD schemas store materialized objects that your dbt project creates.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS edi_file_ingestion_db;
-- "dev" env (local developers + running tests in snowflake UI)
CREATE SCHEMA IF NOT EXISTS edi_file_ingestion_db.dev;
-- "prod" env
CREATE SCHEMA IF NOT EXISTS edi_file_ingestion_db.prod;

-- =============================================================================
-- STEP 3: Enable logging, tracing, and metrics
-- You can capture logging and tracing events for a dbt project object and for
-- the task that runs it on a schedule. These settings must be applied to the
-- schemas where the dbt project object and task are deployed.
-- See: https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-monitoring-observability
-- =============================================================================

ALTER SCHEMA edi_file_ingestion_db.dev SET LOG_LEVEL = 'INFO';
ALTER SCHEMA edi_file_ingestion_db.dev SET TRACE_LEVEL = 'ALWAYS';
ALTER SCHEMA edi_file_ingestion_db.dev SET METRIC_LEVEL = 'ALL';

ALTER SCHEMA edi_file_ingestion_db.prod SET LOG_LEVEL = 'INFO';
ALTER SCHEMA edi_file_ingestion_db.prod SET TRACE_LEVEL = 'ALWAYS';
ALTER SCHEMA edi_file_ingestion_db.prod SET METRIC_LEVEL = 'ALL';

-- =============================================================================
-- STEP 4: Grant EFI_DBT_ROLE the access dbt needs, and let ALEX use it
-- GRANT statements are idempotent: re-granting an existing privilege is a no-op.
-- =============================================================================

-- Compute: run queries on the ETL warehouse
GRANT USAGE ON WAREHOUSE ETL_WH TO ROLE EFI_DBT_ROLE;

-- Source data: read-only access to the files Fivetran syncs from SFTP
GRANT USAGE ON DATABASE FIVETRAN_DB TO ROLE EFI_DBT_ROLE;
GRANT USAGE ON SCHEMA FIVETRAN_DB.AVAILITY TO ROLE EFI_DBT_ROLE;
GRANT READ ON STAGE FIVETRAN_DB.AVAILITY."ALL" TO ROLE EFI_DBT_ROLE;

-- Output: dbt creates and replaces models in the dev and prod schemas.
-- CREATE SCHEMA lets dbt create extra schemas if a model sets a custom schema.
GRANT USAGE, CREATE SCHEMA ON DATABASE edi_file_ingestion_db TO ROLE EFI_DBT_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA edi_file_ingestion_db.dev TO ROLE EFI_DBT_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA edi_file_ingestion_db.prod TO ROLE EFI_DBT_ROLE;

-- Let ALEX switch to the role (e.g. `role: EFI_DBT_ROLE` in profiles.yml)
GRANT ROLE EFI_DBT_ROLE TO USER ALEX;
