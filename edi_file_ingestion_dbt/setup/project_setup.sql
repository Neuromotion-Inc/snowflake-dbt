-- =============================================================================
-- EDI File Ingestion dbt Project: Environment Setup
--
-- PURPOSE
--   Builds a development Snowflake account that mimics the parts of our
--   production HIPAA account which the edi_file_ingestion dbt project depends on,
--   so the project can be developed and tested without touching real data.
--
--   Do NOT run this in the production HIPAA account. Those objects already
--   exist there (or are managed separately), and this script is only for a
--   dev/sandbox account where you have ACCOUNTADMIN.
--
-- WHAT IT CREATES
--   1. Stand-ins for existing production objects:
--        - ETL_WH warehouse used to run dbt
--        - FIVETRAN_DB.AVAILITY."ALL" stage, where the Fivetran SFTP connector
--          lands the EDI files that dbt reads as its source data
--   2. The dbt project's own database (edi_file_ingestion_db) with a `dev`
--      schema (local development and Snowsight runs) and a `prod` schema
--      (production-style runs)
--   3. Logging, tracing, and metrics settings on the dev and prod schemas, so
--      dbt project runs are observable in Snowsight
--   4. EFI_DBT_ROLE, the role dbt runs as, with only the grants it needs
--      (warehouse, read access to the Fivetran stage, write access to the dbt
--      schemas), granted to user ALEX
--
-- USAGE
--   Run once, top to bottom, as ACCOUNTADMIN (e.g. in a Snowsight worksheet or
--   with `snow sql -f`). It is safe to re-run: every statement is idempotent
--   (CREATE ... IF NOT EXISTS, CREATE OR ALTER, or ALTER ... SET), and it never
--   drops or replaces objects, so staged files and dbt output are preserved.
--
-- NOT INCLUDED
--   - Sample EDI files: the stage is created empty, so load some mock files
--     into it before running dbt.
--   - GitHub integration, network rules, and CI/CD users. See
--     tasty_bytes_setup.sql and ci_cd_setup.sql for reference examples.
--
-- Adapted from:
--   https://docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-getting-started-tutorial
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
