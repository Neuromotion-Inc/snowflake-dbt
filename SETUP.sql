-- =============================================================================
-- SETUP.sql: one-time bootstrap for DCM, run ONCE PER SNOWFLAKE ACCOUNT
--
-- DCM can't create the project objects it deploys into, so an admin runs this
-- manually as ACCOUNTADMIN in each account. Everything else is defined by the
-- DCM project and deployed through it.
--
-- Run it in each account:
--   MIGHTIER_STAGING  dev/test sandbox, mocked data  -> project: *_DEV
--   MIGHTIER_HIPAA    production account             -> projects: *_PREPROD, *_PROD
--
-- Safe to re-run: it never drops or replaces anything. (CREATE OR REPLACE on a
-- DCM project would delete its deployment history.)
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Role that owns the DCM projects. PLAN/DEPLOY require OWNERSHIP on the project,
-- and objects are deployed with this role's privileges.
CREATE ROLE IF NOT EXISTS dcm_developer;
SET user_name = (SELECT CURRENT_USER());
GRANT ROLE dcm_developer TO USER IDENTIFIER($user_name);
--
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE dcm_developer;
GRANT CREATE ROLE ON ACCOUNT TO ROLE dcm_developer;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE dcm_developer;
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE dcm_developer;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE dcm_developer;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE dcm_developer;
--
GRANT APPLICATION ROLE SNOWFLAKE.DATA_QUALITY_MONITORING_VIEWER TO ROLE dcm_developer;
GRANT APPLICATION ROLE SNOWFLAKE.DATA_QUALITY_MONITORING_ADMIN TO ROLE dcm_developer;
GRANT DATABASE ROLE SNOWFLAKE.DATA_METRIC_USER TO ROLE dcm_developer;
GRANT EXECUTE DATA METRIC FUNCTION ON ACCOUNT TO ROLE dcm_developer;
-- 
-- work done as dcm_developer
-- 
USE ROLE dcm_developer;

CREATE DATABASE IF NOT EXISTS dcm_db;
CREATE SCHEMA IF NOT EXISTS dcm_db.projects;

CREATE DCM PROJECT IF NOT EXISTS dcm_db.projects.edi_file_ingestion
    COMMENT = 'Availity EDI file ingestion';

--
-- ACCOUNT PARITY: objects that exist in MIGHTIER_HIPAA (Fivetran etc.) but are
-- external to the DCM project. CREATEs only matter in MIGHTIER_STAGING; the
-- GRANTs are needed in every account.
--
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS FIVETRAN_DATABASE;
CREATE SCHEMA IF NOT EXISTS FIVETRAN_DATABASE.AVAILITY;

CREATE STAGE IF NOT EXISTS FIVETRAN_DATABASE.AVAILITY."ALL"
    DIRECTORY = (ENABLE = TRUE);

CREATE WAREHOUSE IF NOT EXISTS ETL_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 30
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

GRANT USAGE ON DATABASE FIVETRAN_DATABASE TO ROLE dcm_developer;
GRANT USAGE ON SCHEMA FIVETRAN_DATABASE.AVAILITY TO ROLE dcm_developer;
GRANT READ ON STAGE FIVETRAN_DATABASE.AVAILITY."ALL" TO ROLE dcm_developer;
GRANT USAGE ON WAREHOUSE ETL_WH TO ROLE dcm_developer;
